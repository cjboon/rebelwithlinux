(() => {
    const initNav = () => {
        const menu = document.querySelector('.menu-details');
        if (!menu) return;

        const toggle = menu.querySelector('.menu-toggle');
        const links = menu.querySelector('.nav-links');
        if (!toggle || !links) return;

        document.documentElement.classList.add('js-nav');
        toggle.setAttribute('aria-expanded', 'false');

        const overlay = document.createElement('div');
        overlay.className = 'nav-overlay';
        overlay.hidden = true;
        document.body.appendChild(overlay);

        let isOpen = false;
        let closeTimeout = null;

        const clearCloseTimeout = () => {
            if (closeTimeout) {
                window.clearTimeout(closeTimeout);
                closeTimeout = null;
            }
        };

        const clearHash = () => {
            if (window.location.hash === '#nav-menu') {
                const url = window.location.pathname + window.location.search;
                window.history.replaceState(null, '', url);
            }
        };

        const openNav = () => {
            if (isOpen) return;
            isOpen = true;
            menu.classList.add('is-open');
            toggle.setAttribute('aria-expanded', 'true');
            document.body.classList.add('nav-open');
            overlay.hidden = false;
            requestAnimationFrame(() => overlay.classList.add('visible'));
            const firstLink = links.querySelector('a');
            if (firstLink) firstLink.focus({ preventScroll: true });
            document.addEventListener('keydown', onKeydown);
        };

        const closeNav = () => {
            if (!isOpen) return;
            isOpen = false;
            menu.classList.remove('is-open');
            toggle.setAttribute('aria-expanded', 'false');
            document.body.classList.remove('nav-open');
            overlay.classList.remove('visible');
            clearCloseTimeout();
            closeTimeout = window.setTimeout(() => {
                overlay.hidden = true;
                closeTimeout = null;
            }, 220);
            toggle.focus({ preventScroll: true });
            clearHash();
            document.removeEventListener('keydown', onKeydown);
        };

        const toggleNav = (event) => {
            if (event) event.preventDefault();
            if (isOpen) {
                closeNav();
            } else {
                openNav();
            }
        };

        const onKeydown = (event) => {
            if (event.key === 'Escape') {
                closeNav();
            }
        };

        toggle.addEventListener('click', toggleNav);
        overlay.addEventListener('click', closeNav);
        links.querySelectorAll('a').forEach((link) => {
            link.addEventListener('click', closeNav);
        });

        if (window.location.hash === '#nav-menu') {
            openNav();
            clearHash();
        }
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initNav);
    } else {
        initNav();
    }
})();
