#!/usr/bin/env python3
import re
import os

# New horizontal nav template for ROOT level pages (index, about, contact, search, stats, guides, distros, games, blog, tests, account)
ROOT_NAV = '''    <div class="section-links" style="background: var(--ivory); padding: 16px; text-align: center;">
        <a href="index.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Home</a>
        <a href="guides.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Guides</a>
        <a href="distros.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Distros</a>
        <a href="tests.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Tests</a>
        <a href="games.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Games</a>
        <a href="blog.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Blog</a>
        <a href="about.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">About</a>
        <a href="contact.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Contact</a>
        <a href="search.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Search</a>
        <a href="stats.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Stats</a>
        <button id="themeBtn" style="background: transparent; border: 1px solid var(--charcoal); color: var(--black); cursor: pointer; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border-radius: 4px; margin: 4px; display: none;">Light</button>
        <button id="loginBtn" style="background: transparent; border: 1px solid var(--charcoal); color: var(--black); cursor: pointer; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border-radius: 4px; margin: 4px; display: none;">Login</button>
        <a href="account.html" id="accountBtn" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: none;">Account</a>
    </div>
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
            } else {
                document.getElementById('loginBtn').style.display = 'inline-block';
            }
        })();
    </script>

'''

# Nav for ONE level deep (blog posts, guides, tests, projects, terms, builders, hangman) - uses ../
ONE_LEVEL_NAV = '''    <div class="section-links" style="background: var(--ivory); padding: 16px; text-align: center;">
        <a href="../index.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Home</a>
        <a href="../guides.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Guides</a>
        <a href="../distros.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Distros</a>
        <a href="../tests.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Tests</a>
        <a href="../games.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Games</a>
        <a href="../blog.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Blog</a>
        <a href="../about.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">About</a>
        <a href="../contact.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Contact</a>
        <a href="../search.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Search</a>
        <a href="../stats.html" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: inline-block;">Stats</a>
        <button id="themeBtn" style="background: transparent; border: 1px solid var(--charcoal); color: var(--black); cursor: pointer; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border-radius: 4px; margin: 4px; display: none;">Light</button>
        <button id="loginBtn" style="background: transparent; border: 1px solid var(--charcoal); color: var(--black); cursor: pointer; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border-radius: 4px; margin: 4px; display: none;">Login</button>
        <a href="../account.html" id="accountBtn" style="color: var(--black); text-decoration: none; font-family: 'IBM Plex Mono', monospace; font-size: 0.85rem; padding: 8px 16px; border: 1px solid var(--charcoal); border-radius: 4px; margin: 4px; display: none;">Account</a>
    </div>
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
            } else {
                document.getElementById('loginBtn').style.display = 'inline-block';
            }
        })();
    </script>

'''

def get_nav_template(filepath):
    """Determine which nav template to use based on file path"""
    if '/blog/' in filepath or '/guides/' in filepath or '/tests/' in filepath or '/projects/' in filepath or '/terms/' in filepath or '/builders/' in filepath or '/hangman/' in filepath:
        return ONE_LEVEL_NAV
    return ROOT_NAV

def remove_old_nav(content, filepath):
    """Remove the old hamburger nav and return modified content"""
    
    # Pattern to match <nav> block until </nav>
    # This handles various formats with newlines and indentation
    nav_pattern = r'\s*<nav>.*?</nav>\s*'
    
    # Try to find and remove the nav block
    match = re.search(nav_pattern, content, re.DOTALL)
    if match:
        old_nav = match.group(0)
        print(f"  Found nav block ({len(old_nav)} chars) in {filepath}")
        new_nav = get_nav_template(filepath)
        content = content[:match.start()] + '\n' + new_nav + content[match.end():]
        return content
    
    # Alternative: try to find noscript + nav combination
    noscript_nav_pattern = r'<noscript>.*?</noscript>\s*<nav>.*?</nav>\s*'
    match = re.search(noscript_nav_pattern, content, re.DOTALL)
    if match:
        old_block = match.group(0)
        print(f"  Found noscript+nav block ({len(old_block)} chars) in {filepath}")
        new_nav = get_nav_template(filepath)
        content = content[:match.start()] + '\n' + new_nav + content[match.end():]
        return content
    
    print(f"  WARNING: Could not find nav block in {filepath}")
    return content

def process_file(filepath):
    """Process a single HTML file"""
    print(f"Processing: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check if file has the old nav
    if 'menu-toggle' not in content and 'hamburger-line' not in content:
        print(f"  Skipping {filepath} - no hamburger nav found")
        return
    
    content = remove_old_nav(content, filepath)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"  Updated: {filepath}")

def main():
    base_dir = '/var/www/rebelwithlinux.com'
    
    # Files at root level
    root_files = [
        '404.html',
        'site-map.html',
    ]
    
    # Files one level deep
    subdirs = ['blog', 'guides', 'tests', 'projects', 'terms', 'builders', 'hangman']
    
    all_files = []
    
    for root_file in root_files:
        filepath = os.path.join(base_dir, root_file)
        if os.path.exists(filepath):
            all_files.append(filepath)
    
    for subdir in subdirs:
        dirpath = os.path.join(base_dir, subdir)
        if os.path.exists(dirpath):
            for filename in os.listdir(dirpath):
                if filename.endswith('.html'):
                    filepath = os.path.join(dirpath, filename)
                    all_files.append(filepath)
    
    print(f"Found {len(all_files)} files to process")
    
    for filepath in all_files:
        process_file(filepath)

if __name__ == '__main__':
    main()