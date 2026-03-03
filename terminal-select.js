document.addEventListener("DOMContentLoaded", function() {
    document.querySelectorAll(".terminal-block").forEach(function(el) {
        el.addEventListener("dblclick", function(e) {
            var cmd = e.target.closest(".command");
            if (cmd) {
                var range = document.createRange();
                range.selectNodeContents(cmd);
                var selection = window.getSelection();
                selection.removeAllRanges();
                selection.addRange(range);
                e.preventDefault();
            }
        });
    });
});
