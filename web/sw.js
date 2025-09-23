// Service Worker personalizado para HarchaMAq PWA
const CACHE_NAME = 'harchamaq-v1';
const urlsToCache = [
  '/',
  '/main.dart.js',
  '/flutter.js',
  '/manifest.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/favicon.png'
];

// Instalar Service Worker
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        console.log('Cache abierto');
        return cache.addAll(urlsToCache);
      })
  );
});

// Interceptar peticiones
self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.match(event.request)
      .then(function(response) {
        // Cache hit - retornar respuesta
        if (response) {
          return response;
        }

        return fetch(event.request).then(
          function(response) {
            // Verificar si recibimos una respuesta válida
            if(!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }

            // IMPORTANTE: Clonar la respuesta
            var responseToCache = response.clone();

            caches.open(CACHE_NAME)
              .then(function(cache) {
                cache.put(event.request, responseToCache);
              });

            return response;
          }
        );
      })
    );
});

// Limpiar caches antiguos
self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(cacheName) {
          if (cacheName !== CACHE_NAME) {
            console.log('Eliminando cache antiguo:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});