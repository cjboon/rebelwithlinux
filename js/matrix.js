!function() {
    var canvas = document.createElement('canvas');
    canvas.id = 'matrix-canvas';
    canvas.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;z-index:-1;pointer-events:none;';
    document.body.insertBefore(canvas, document.body.firstChild);

    var ctx = canvas.getContext('2d');
    var cols, drops, fontSize = 14;
    var chars = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF';

    function getThemeColors() {
        var isDark = document.documentElement.getAttribute('data-theme') === 'dark';
        return {
            text: isDark ? '#00ff41' : '#006600',
            bg: isDark ? 'rgba(0, 0, 0, 0.05)' : 'rgba(0, 0, 0, 0.1)'
        };
    }

    function resize() {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
        cols = Math.floor(canvas.width / fontSize);
        drops = [];
        for (var i = 0; i < cols; i++) {
            drops[i] = Math.random() * -100;
        }
    }

    function draw() {
        var colors = getThemeColors();
        ctx.fillStyle = colors.bg;
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = colors.text;
        ctx.font = fontSize + 'px monospace';

        for (var i = 0; i < drops.length; i++) {
            var char = chars[Math.floor(Math.random() * chars.length)];
            ctx.fillText(char, i * fontSize, drops[i] * fontSize);
            if (drops[i] * fontSize > canvas.height && Math.random() > 0.975) {
                drops[i] = 0;
            }
            drops[i]++;
        }
    }

    resize();
    window.addEventListener('resize', resize);
    setInterval(draw, 50);

    var observer = new MutationObserver(function() {
        resize();
    });
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
}();