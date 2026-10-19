#!/usr/bin/env node
// Verifica que el build web siga siendo una PWA instalable y que funcione
// sin conexión. Se ejecuta en CI después de `flutter build web` y de
// generar sw.js; si alguna comprobación falla, el workflow se detiene y no
// se despliega.
//
// Uso:
//   node tool/pwa/verify_pwa.mjs build/web [--base-href /repo/] [--runtime]
//
// Comprobaciones estáticas (siempre):
//   - manifest.json válido: name, short_name, start_url, display, colores,
//     iconos de 192 y 512 px (y que los PNG existan y midan eso).
//   - index.html enlaza el manifest, tiene viewport, theme-color e icono iOS.
//   - sw.js existe, maneja `fetch` y precachea todos los recursos críticos.
//   - flutter_bootstrap.js registra sw.js y CanvasKit se sirve localmente
//     (sin CDN), condición necesaria para funcionar offline.
//
// Comprobación en navegador (--runtime, usa Playwright + Chromium):
//   - Sirve el build bajo el mismo base href que GitHub Pages.
//   - Carga la app, espera a que el service worker controle la página.
//   - Corta la red, recarga y comprueba que Flutter vuelve a arrancar.

import { createServer } from 'node:http';
import { existsSync, readFileSync, statSync } from 'node:fs';
import { extname, join, normalize } from 'node:path';

const args = process.argv.slice(2);
const buildDir = args.find((arg) => !arg.startsWith('--')) ?? 'build/web';
const baseHrefIndex = args.indexOf('--base-href');
const baseHref = baseHrefIndex >= 0 ? args[baseHrefIndex + 1] : '/';
const runRuntimeCheck = args.includes('--runtime');

const failures = [];
const check = (condition, message) => {
  if (condition) {
    console.log(`  ✔ ${message}`);
  } else {
    console.log(`  ✖ ${message}`);
    failures.push(message);
  }
};
const read = (file) => readFileSync(join(buildDir, file), 'utf8');
const exists = (file) => existsSync(join(buildDir, file));

function pngSize(file) {
  const buffer = readFileSync(join(buildDir, file));
  const isPng = buffer.subarray(1, 4).toString('ascii') === 'PNG';
  if (!isPng) return null;
  return `${buffer.readUInt32BE(16)}x${buffer.readUInt32BE(20)}`;
}

// ---------------------------------------------------------------------------
console.log('\nManifest');
let manifest = {};
try {
  manifest = JSON.parse(read('manifest.json'));
  check(true, 'manifest.json es JSON válido');
} catch (error) {
  check(false, `manifest.json es JSON válido (${error.message})`);
}
check(Boolean(manifest.name), 'tiene "name"');
check(Boolean(manifest.short_name), 'tiene "short_name"');
check(Boolean(manifest.start_url), 'tiene "start_url"');
check(
  ['standalone', 'fullscreen', 'minimal-ui'].includes(manifest.display),
  `"display" permite instalar la app (${manifest.display})`,
);
check(Boolean(manifest.theme_color && manifest.background_color), 'define theme_color y background_color');
const icons = Array.isArray(manifest.icons) ? manifest.icons : [];
for (const required of ['192x192', '512x512']) {
  const icon = icons.find((item) => item.sizes === required && (item.purpose ?? 'any').includes('any'));
  check(Boolean(icon), `tiene icono ${required}`);
  if (icon) {
    check(exists(icon.src) && pngSize(icon.src) === required, `el archivo ${icon.src} existe y mide ${required}`);
  }
}
check(icons.some((item) => item.purpose === 'maskable'), 'tiene icono maskable (Android)');

// ---------------------------------------------------------------------------
console.log('\nindex.html');
const html = exists('index.html') ? read('index.html') : '';
check(/<link[^>]+rel="manifest"[^>]+href="manifest\.json"/.test(html), 'enlaza manifest.json');
check(/<meta[^>]+name="viewport"/.test(html), 'tiene meta viewport (responsive)');
check(/<meta[^>]+name="theme-color"/.test(html), 'tiene meta theme-color');
check(/<link[^>]+rel="apple-touch-icon"/.test(html), 'tiene apple-touch-icon (iOS)');
check(html.includes(`<base href="${baseHref}">`), `base href es ${baseHref}`);

// ---------------------------------------------------------------------------
console.log('\nService worker y modo offline');
const bootstrap = exists('flutter_bootstrap.js') ? read('flutter_bootstrap.js') : '';
check(/serviceWorker\.register\(\s*['"]sw\.js['"]/.test(bootstrap), 'flutter_bootstrap.js registra sw.js');
check(/"useLocalCanvasKit"\s*:\s*true/.test(bootstrap), 'CanvasKit local (build con --no-web-resources-cdn)');
check(exists('sw.js'), 'sw.js existe');
const sw = exists('sw.js') ? read('sw.js') : '';
check(sw.includes("addEventListener('fetch'"), 'sw.js responde peticiones (fetch)');
const precacheMatch = sw.match(/const PRECACHE_URLS = (\[[\s\S]*?\]);/);
const precache = precacheMatch ? JSON.parse(precacheMatch[1]) : [];
const critical = [
  'index.html',
  'main.dart.js',
  'flutter_bootstrap.js',
  'manifest.json',
  'assets/FontManifest.json',
  'assets/AssetManifest.bin.json',
  'assets/fonts/MaterialIcons-Regular.otf',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
];
for (const file of critical) {
  if (exists(file)) {
    check(precache.includes(encodeURI(file)), `precachea ${file}`);
  } else if (file === 'assets/AssetManifest.bin.json') {
    console.log(`  · ${file} no existe en esta versión de Flutter (se omite)`);
  } else {
    check(false, `${file} existe en el build`);
  }
}
const missing = precache.filter((url) => url !== './' && !exists(decodeURI(url)));
check(missing.length === 0, `todos los recursos precacheados existen${missing.length ? ` (faltan: ${missing.join(', ')})` : ''}`);
const fontManifest = exists('assets/FontManifest.json') ? read('assets/FontManifest.json') : '';
check(fontManifest.includes('Nunito') && fontManifest.includes('Fredoka'), 'las fuentes van empaquetadas (sin Google Fonts en tiempo de ejecución)');

// ---------------------------------------------------------------------------
if (runRuntimeCheck && failures.length === 0) {
  console.log('\nPrueba en navegador (instalación + offline)');
  await runtimeCheck();
}

if (failures.length > 0) {
  console.error(`\n✖ La app NO cumple los requisitos de PWA (${failures.length} fallos).`);
  process.exit(1);
}
console.log('\n✔ La app es una PWA instalable y funciona sin conexión.');

// ---------------------------------------------------------------------------
async function runtimeCheck() {
  const { chromium } = await import('playwright');
  const mime = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'text/javascript; charset=utf-8',
    '.mjs': 'text/javascript; charset=utf-8',
    '.json': 'application/json',
    '.wasm': 'application/wasm',
    '.png': 'image/png',
    '.otf': 'font/otf',
    '.ttf': 'font/ttf',
    '.bin': 'application/octet-stream',
    '.frag': 'application/octet-stream',
  };
  const server = createServer((req, res) => {
    const url = new URL(req.url, 'http://localhost');
    let path = decodeURIComponent(url.pathname);
    if (!path.startsWith(baseHref)) {
      res.writeHead(404).end();
      return;
    }
    path = path.slice(baseHref.length) || 'index.html';
    let file = normalize(join(buildDir, path));
    if (!file.startsWith(normalize(buildDir))) {
      res.writeHead(403).end();
      return;
    }
    if (!existsSync(file) || statSync(file).isDirectory()) {
      file = join(buildDir, 'index.html'); // como el 404.html de GitHub Pages
    }
    res.writeHead(200, {
      'Content-Type': mime[extname(file)] ?? 'application/octet-stream',
      'Cache-Control': 'no-cache',
    });
    res.end(readFileSync(file));
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const appUrl = `http://127.0.0.1:${server.address().port}${baseHref}`;

  // CHROMIUM_PATH / CHROMIUM_ARGS permiten usar un Chromium propio (local).
  const launchOptions = {};
  if (process.env.CHROMIUM_PATH) launchOptions.executablePath = process.env.CHROMIUM_PATH;
  if (process.env.CHROMIUM_ARGS) launchOptions.args = JSON.parse(process.env.CHROMIUM_ARGS);
  const browser = await chromium.launch(launchOptions);
  const context = await browser.newContext();
  const page = await context.newPage();
  const flutterReady = () =>
    page.waitForFunction(
      () => Boolean(document.querySelector('flutter-view, flt-glass-pane')) && !document.getElementById('app-loader'),
      null,
      { timeout: 60_000 },
    );

  try {
    await page.goto(appUrl);
    await flutterReady();
    check(true, 'la app carga en línea');

    const controlled = await page.evaluate(async () => {
      await navigator.serviceWorker.ready;
      if (!navigator.serviceWorker.controller) {
        await new Promise((resolve) => {
          navigator.serviceWorker.addEventListener('controllerchange', resolve, { once: true });
          setTimeout(resolve, 15_000);
        });
      }
      return Boolean(navigator.serviceWorker.controller);
    });
    check(controlled, 'el service worker se instala y controla la página');

    const cached = await page.evaluate(async () => {
      const keys = await caches.keys();
      let count = 0;
      for (const key of keys) count += (await (await caches.open(key)).keys()).length;
      return count;
    });
    check(cached > 0, `recursos guardados en caché: ${cached}`);

    await context.setOffline(true);
    await page.reload();
    await flutterReady();
    check(true, 'la app vuelve a cargar SIN conexión');
  } catch (error) {
    check(false, `prueba en navegador: ${error.message.split('\n')[0]}`);
  } finally {
    await browser.close();
    server.close();
  }
}
