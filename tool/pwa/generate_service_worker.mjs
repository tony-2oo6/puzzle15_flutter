#!/usr/bin/env node
// Genera build/web/sw.js: un service worker que precachea todo el build de
// Flutter Web para que el juego se pueda instalar y jugar sin conexión.
//
// Uso: node tool/pwa/generate_service_worker.mjs build/web
//
// La versión de la caché es un hash del contenido del build, así que cada
// despliegue con cambios produce un sw.js distinto y el navegador actualiza
// la caché automáticamente; los despliegues sin cambios no invalidan nada.

import { createHash } from 'node:crypto';
import { readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { join, relative, sep } from 'node:path';

const buildDir = process.argv[2] ?? 'build/web';

// Archivos que no deben precachearse.
const EXCLUDED = [
  /^sw\.js$/,
  /^flutter_service_worker\.js$/, // el de Flutter solo se desregistra
  /^\.last_build_id$/,
  /^404\.html$/,
  /^\.nojekyll$/,
  /\.map$/,
  /\.symbols$/,
  // Solo se compila a JavaScript; las variantes Wasm (skwasm) no se cargan.
  /^canvaskit\/(.*\/)?skwasm[^/]*$/,
];

function walk(dir) {
  const files = [];
  for (const entry of readdirSync(dir)) {
    const fullPath = join(dir, entry);
    if (statSync(fullPath).isDirectory()) {
      files.push(...walk(fullPath));
    } else {
      files.push(fullPath);
    }
  }
  return files;
}

const files = walk(buildDir)
  .map((file) => relative(buildDir, file).split(sep).join('/'))
  .filter((file) => !EXCLUDED.some((pattern) => pattern.test(file)))
  .sort();

if (!files.includes('index.html') || !files.includes('main.dart.js')) {
  console.error(`✖ ${buildDir} no parece un build de Flutter Web (falta index.html o main.dart.js).`);
  process.exit(1);
}

const hash = createHash('sha256');
let totalBytes = 0;
for (const file of files) {
  const content = readFileSync(join(buildDir, file));
  totalBytes += content.length;
  hash.update(file).update('\0').update(content);
}
const version = hash.digest('hex').slice(0, 16);

// './' representa la raíz de la app (start_url del manifest).
const precache = ['./', ...files.filter((file) => file !== 'index.html'), 'index.html'].map(encodeURI);

const serviceWorker = `// Generado automáticamente por tool/pwa/generate_service_worker.mjs. No editar.
'use strict';

const CACHE_PREFIX = 'puzzle15-';
const CACHE_NAME = CACHE_PREFIX + '${version}';
const PRECACHE_URLS = ${JSON.stringify(precache, null, 2)};

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(CACHE_NAME)
      .then((cache) => cache.addAll(PRECACHE_URLS.map((url) => new Request(url, { cache: 'reload' }))))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys
            .filter((key) => key.startsWith(CACHE_PREFIX) && key !== CACHE_NAME)
            .map((key) => caches.delete(key)),
        ),
      )
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  // Navegación: red primero (para recibir actualizaciones) y, sin conexión,
  // la página principal guardada en caché.
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request).catch(async () => {
        const cache = await caches.open(CACHE_NAME);
        return (await cache.match('index.html')) || (await cache.match('./')) || Response.error();
      }),
    );
    return;
  }

  // Recursos estáticos: caché primero; si no está, red y se guarda.
  event.respondWith(
    caches.open(CACHE_NAME).then(async (cache) => {
      const cached = await cache.match(request, { ignoreSearch: true });
      if (cached) return cached;
      const response = await fetch(request);
      if (response.ok && response.type === 'basic') {
        cache.put(request, response.clone());
      }
      return response;
    }),
  );
});
`;

writeFileSync(join(buildDir, 'sw.js'), serviceWorker);
console.log(
  `✔ sw.js generado: ${precache.length} recursos precacheados ` +
    `(${(totalBytes / 1024 / 1024).toFixed(1)} MB), versión ${version}`,
);
