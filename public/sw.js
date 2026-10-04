/* Sparklehoof's Meadow — service worker (offline + app-like install).
   Bump CACHE on every deploy so a new build replaces the old cache. */
const CACHE = 'sparklehoof-b25';
const CORE = [
  './fairyland.html',
  './manifest.webmanifest',
  './sparkle-icon-180.png',
  './sparkle-icon-192.png',
  './sparkle-icon-512.png'
];

self.addEventListener('install', e => {
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE).catch(() => {}))); // tolerate a missing file
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))) // drop old builds
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  const isCDN = url.host.endsWith('unpkg.com');                                  // Three.js + addons
  const isFairy = url.origin === location.origin &&
    (url.pathname.endsWith('/fairyland.html') ||
     url.pathname.endsWith('/manifest.webmanifest') ||
     url.pathname.includes('sparkle-icon'));

  // The game page itself: network-first (fresh when online — respects ?v= cache-busting — cached copy when offline)
  if (isFairy && req.mode === 'navigate') {
    e.respondWith(
      fetch(req)
        .then(r => { const cp = r.clone(); caches.open(CACHE).then(c => c.put('./fairyland.html', cp)); return r; })
        .catch(() => caches.match('./fairyland.html'))
    );
    return;
  }

  // The CDN libraries + icons/manifest: cache-first (rarely change; this is what makes the game play offline)
  if (isCDN || isFairy) {
    e.respondWith(
      caches.match(req).then(cached => cached || fetch(req).then(r => {
        if (r && r.ok) { const cp = r.clone(); caches.open(CACHE).then(c => c.put(req, cp)); }
        return r;
      }).catch(() => caches.match(req)))
    );
    return;
  }
  // Everything else (the other games on this bucket, etc.): stay out of the way — default network.
});
