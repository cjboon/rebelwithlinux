const CACHE_NAME = 'rebel-linux-v11';
const STATIC_CACHE = 'rebel-static-v11';
const DYNAMIC_CACHE = 'rebel-dynamic-v11';

const urlsToCache = [
    '/',
    '/index.html',
    '/offline.html',
    '/404.html',
    '/style.css',
    '/fonts.css',
    '/favicon.ico',
    '/site-map.html',
    '/account.html',
    '/theme.js',
    '/nav.js',
    '/achievements.js',
    '/terms/term-main.html',
    '/hangman/hangman-main.html',
    '/builders/builder-main.html',
    '/guides/guide-linux.html',
    '/guides/guide-bash.html',
    '/guides/guide-git.html',
    '/guides/guide-docker.html',
    '/guides/guide-vps.html',
    '/guides/guide-python.html',
    '/guides/guide-javascript.html',
    '/guides/guide-html.html',
    '/guides/guide-css.html',
    '/guides/guide-php.html',
    '/guides/guide-nginx.html',
    '/guides/guide-apache2.html',
    '/guides/guide-mariadb.html',
    '/guides/guide-networking.html',
    '/guides/guide-dns.html',
    '/guides/guide-hardening.html',
    '/guides/guide-kubernetes.html',
    '/guides/guide-monitoring.html',
    '/guides/guide-vim.html',
    '/blog/blog-editing.html',
    '/blog/blog-foss.html',
    '/blog/blog-gpg.html',
    '/blog/blog-monero.html',
    '/blog/blog-pwa.html',
    '/blog/blog-email.html',
    '/blog/blog-ssh-keys.html',
    '/blog/blog-docker.html',
    '/blog/blog-homelab.html',
    '/blog/blog-degoogle.html',
    '/blog/blog-fullstack-linux.html',
    '/blog/blog-network-privacy.html',
    '/blog/blog-secure-messaging.html',
    '/blog/blog-metadata-privacy.html',
    '/blog/blog-device-security.html',
    '/blog/blog-backups.html',
    '/blog/blog-math-for-cs.html',
    '/blog/blog-linux-commands.html',
    '/blog/blog-server-software.html',
    '/blog/blog-vps.html',
    '/blog/blog-linux-for-everyone.html',
    '/blog/blog-terraform.html',
    '/blog/blog-ansible.html',
    '/blog/blog-cicd.html',
    '/blog/blog-kubernetes.html',
    '/blog/blog-nginx.html',
    '/blog/blog-prometheus.html',
    '/blog/blog-vault.html',
    '/tests/test-linux.html',
    '/projects/project-blog.html',
    '/projects/project-fileshare.html',
    '/projects/project-homelab.html',
    '/projects/project-i3.html',
    '/projects/project-mail.html',
    '/projects/project-onion.html',
    '/projects/project-paste.html',
    '/projects/project-wireguard.html',
    '/projects/project-matrix.html',
    '/terms/term-bash.html',
    '/terms/term-git.html',
    '/terms/term-sql.html',
    '/terms/term-py.html',
    '/terms/term-regex.html',
    '/terms/term-sed.html',
    '/terms/term-awk.html',
    '/terms/term-jq.html',
    '/terms/term-curl.html',
    '/terms/term-ssh.html',
    '/terms/term-vim.html',
    '/terms/term-nix.html',
    '/hangman/hangman-linux.html',
    '/hangman/hangman-git.html',
    '/hangman/hangman-bash.html',
    '/hangman/hangman-python.html',
    '/hangman/hangman-sql.html',
    '/hangman/hangman-network.html',
    '/hangman/hangman-html.html',
    '/hangman/hangman-css.html',
    '/hangman/hangman-javascript.html',
    '/hangman/hangman-terraform.html',
    '/hangman/hangman-ansible.html',
    '/hangman/hangman-cicd.html',
    '/hangman/hangman-docker.html',
    '/hangman/hangman-kubernetes.html',
    '/hangman/hangman-nginx.html',
    '/hangman/hangman-prometheus.html',
    '/hangman/hangman-helm.html',
    '/hangman/hangman-vault.html',
    '/hangman/hangman-aws.html',
    '/hangman/hangman-github.html',
    '/games/game-debian.html',
    '/games/game-debian-2.html',
    '/games/game-debian-3.html',
    '/games/game-quiz.html',
    '/games/game-speed.html',
    '/games/game-turing.html',
    '/builders/builder-html.html',
    '/builders/builder-html-2.html',
    '/builders/builder-html-3.html',
    '/builders/builder-css.html',
    '/builders/builder-css-2.html',
    '/builders/builder-css-3.html',
    '/builders/builder-javascript.html',
    '/builders/builder-javascript-2.html',
    '/builders/builder-javascript-3.html',
    '/builders/builder-python.html',
    '/builders/builder-python-2.html',
    '/builders/builder-python-3.html',
    '/builders/builder-sql.html',
    '/builders/builder-sql-2.html',
    '/builders/builder-sql-3.html',
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
