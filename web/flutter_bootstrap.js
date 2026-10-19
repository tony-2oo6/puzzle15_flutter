{{flutter_js}}
{{flutter_build_config}}

// Arranque personalizado de Flutter Web.
//
// Desde Flutter 3.27 el service worker que genera Flutter
// (flutter_service_worker.js) ya no guarda la app en caché: solo se
// desregistra. Para que el juego siga siendo una PWA que funciona sin
// conexión registramos nuestro propio service worker (sw.js), que se genera
// después del build con tool/pwa/generate_service_worker.mjs.

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    const loader = document.getElementById('app-loader');
    if (loader) {
      loader.classList.add('hidden');
      setTimeout(function () { loader.remove(); }, 400);
    }
  },
});

(function registerServiceWorker() {
  if (!('serviceWorker' in navigator)) return;
  const register = function () {
    navigator.serviceWorker.register('sw.js').catch(function (error) {
      console.warn('No se pudo registrar el service worker:', error);
    });
  };
  if (document.readyState === 'complete') {
    register();
  } else {
    window.addEventListener('load', register);
  }
})();
