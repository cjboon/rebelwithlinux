#!/usr/bin/env python3
import os
import re

script = '''
    <script>
        (function() {
            var theme = localStorage.getItem('theme') || 'dark';
            document.documentElement.setAttribute('data-theme', theme);
            document.getElementById('themeBtn').style.display = 'inline-block';
            document.getElementById('themeBtn').textContent = theme === 'dark' ? 'Light' : 'Dark';
            if (theme === 'dark') {
                document.getElementById('themeBtn').style.color = '#e0e0e0';
            }
            
            document.getElementById('themeBtn').addEventListener('click', function() {
                var current = document.documentElement.getAttribute('data-theme');
                var next = current === 'dark' ? 'light' : 'dark';
                document.documentElement.setAttribute('data-theme', next);
                localStorage.setItem('theme', next);
                this.textContent = next === 'dark' ? 'Light' : 'Dark';
                this.style.color = next === 'dark' ? '#e0e0e0' : '#000000';
            });

            var isLoggedIn = localStorage.getItem('auth') === 'true';
            if (isLoggedIn) {
                document.getElementById('accountBtn').style.display = 'inline-block';
                document.getElementById('logoutBtn').style.display = 'inline-block';
                document.getElementById('logoutBtn').addEventListener('click', async function() {
                    try {
                        const formData = new FormData();
                        formData.append('action', 'logout');
                        await fetch('../api/auth.php', { method: 'POST', body: formData, credentials: 'include' });
                        localStorage.removeItem('auth');
                        window.location.href = '../index.html';
                    } catch (e) {
                        console.error('Logout error');
                    }
                });
            } else {
                document.getElementById('loginBtn').style.display = 'inline-block';
            }
        })();
    </script>
'''

files_to_fix = [
    'projects/project-blog.html',
    'projects/project-homelab.html',
    'projects/project-i3.html',
    'projects/project-mail.html',
    'projects/project-matrix.html',
    'projects/project-onion.html',
    'projects/project-paste.html',
    'projects/project-wireguard.html',
]

for filepath in files_to_fix:
    with open(filepath, 'r') as f:
        content = f.read()
    
    if "var isLoggedIn = localStorage.getItem('auth')" in content:
        print(f'Already has script: {filepath}')
        continue
    
    nav_close = '</div>\n    <div class="project-nav">'
    if nav_close in content:
        new_content = '</div>\n' + script + '\n    <div class="project-nav">'
        content = content.replace(nav_close, new_content)
        with open(filepath, 'w') as f:
            f.write(content)
        print(f'Added script to: {filepath}')
    else:
        print(f'Pattern not found: {filepath}')

print('Done')
