// Comments system for blog posts
function loadComments(postSlug) {
    fetch(`/api/comments.php?slug=${encodeURIComponent(postSlug)}`)
        .then(r => r.json())
        .then(comments => {
            const container = document.getElementById('comments-list');
            if (!container) return;
            
            if (comments.length === 0) {
                container.innerHTML = '<p style="color: var(--charcoal); font-style: italic;">No comments yet. Be the first to comment!</p>';
                return;
            }
            
            container.innerHTML = comments.map(c => `
                <div style="padding: 16px; margin-bottom: 16px; background: var(--light-gray); border-left: 3px solid var(--black);">
                    <div style="font-weight: bold; margin-bottom: 8px;">${escapeHtml(c.author)}</div>
                    <div style="color: var(--charcoal); font-size: 0.9rem; margin-bottom: 8px;">${escapeHtml(c.content)}</div>
                    <div style="font-size: 0.75rem; color: var(--charcoal);">${c.created_at}</div>
                </div>
            `).join('');
        })
        .catch(err => {
            console.error('Failed to load comments:', err);
        });
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function submitComment(postSlug) {
    const author = document.getElementById('comment-author')?.value.trim();
    const email = document.getElementById('comment-email')?.value.trim();
    const content = document.getElementById('comment-content')?.value.trim();
    const errorEl = document.getElementById('comment-error');
    const successEl = document.getElementById('comment-success');
    
    if (errorEl) errorEl.textContent = '';
    if (successEl) successEl.textContent = '';
    
    if (!author || !email || !content) {
        if (errorEl) errorEl.textContent = 'All fields are required';
        return;
    }
    
    fetch('/api/comments.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ slug: postSlug, author, email, content })
    })
    .then(r => r.json())
    .then(data => {
        if (data.success) {
            if (successEl) successEl.textContent = 'Comment posted!';
            if (document.getElementById('comment-author')) document.getElementById('comment-author').value = '';
            if (document.getElementById('comment-email')) document.getElementById('comment-email').value = '';
            if (document.getElementById('comment-content')) document.getElementById('comment-content').value = '';
            loadComments(postSlug);
        } else {
            if (errorEl) errorEl.textContent = data.error || 'Failed to post comment';
        }
    })
    .catch(err => {
        if (errorEl) errorEl.textContent = 'Failed to post comment';
    });
}

function initComments(postSlug) {
    if (postSlug) {
        loadComments(postSlug);
    }
}
