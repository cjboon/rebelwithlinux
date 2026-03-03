const CACHE_NAME = 'rebel-linux-v8';
const STATIC_CACHE = 'rebel-static-v8';
const DYNAMIC_CACHE = 'rebel-dynamic-v8';

const urlsToCache = [
    '/',
    '/index.html',
    '/offline.html',
    '/style.css',
    '/fonts.css',
    '/favicon.ico',
    '/achievements.js',
    '/linux.html',
    '/bash.html',
    '/git.html',
    '/docker.html',
    '/vps.html',
    '/python.html',
    '/javascript.html',
    '/php.html',
    '/css.html',
    '/hyper.html',
    '/nginx.html',
    '/apache2.html',
    '/mariadb.html',
    '/networking.html',
    '/dns.html',
    '/hardening.html',
    '/kubernetes.html',
    '/monitoring.html',
    '/project-blog.html',
    '/project-fileshare.html',
    '/project-homelab.html',
    '/project-i3.html',
    '/project-mail.html',
    '/project-onion.html',
    '/project-paste.html',
    '/project-wireguard.html',
    '/blog.html',
    '/blog-editing.html',
    '/blog-foss.html',
    '/blog-gpg.html',
    '/blog-monero.html',
    '/blog-pwa.html'
];

self.addEventListener("install", e => {
    e.waitUntil(
        caches.open(STATIC_CACHE).then(cache => {
            return cache.addAll(urlsToCache);
        })
    );
    self.skipWaiting();
});

self.addEventListener("activate", e => {
    e.waitUntil(
        caches.keys().then(cacheNames => Promise.all(
            cacheNames.map(cacheName => {
                if (cacheName !== CACHE_NAME && cacheName !== STATIC_CACHE && cacheName !== DYNAMIC_CACHE) {
                    return caches.delete(cacheName);
                }
            })
        ))
    );
    self.clients.claim();
});

self.addEventListener("fetch", e => {
    const url = new URL(e.request.url);

    if (url.origin !== location.origin) {
        return;
    }

    if (e.request.method !== 'GET') {
        return;
    }

    if (url.pathname.endsWith('.php') || url.pathname.includes('api/')) {
        return;
    }

    if (url.pathname === '/' || url.pathname === '/index.html') {
        e.respondWith(
            networkFirst(e.request, '/index.html')
        );
        return;
    }

    const staticExtensions = ['.html', '.css', '.js', '.woff2', '.ico'];
    const isStatic = staticExtensions.some(ext => url.pathname.endsWith(ext));

    if (isStatic) {
        e.respondWith(cacheFirst(e.request));
    } else {
        e.respondWith(networkFirst(e.request, '/offline.html'));
    }
});

async function cacheFirst(request) {
    const cached = await caches.match(request);
    if (cached) {
        return cached;
    }
    try {
        const response = await fetch(request);
        if (response.ok) {
            const cache = await caches.open(DYNAMIC_CACHE);
            cache.put(request, response.clone());
        }
        return response;
    } catch (error) {
        return caches.match('/offline.html');
    }
}

async function networkFirst(request, fallback) {
    try {
        const response = await fetch(request);
        if (response.ok) {
            const cache = await caches.open(DYNAMIC_CACHE);
            cache.put(request, response.clone());
        }
        return response;
    } catch (error) {
        const cached = await caches.match(request);
        if (cached) {
            return cached;
        }
        return caches.match(fallback);
    }
}

self.addEventListener('message', e => {
    if (e.data && e.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
});
