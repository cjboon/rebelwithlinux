#!/usr/bin/env python3
import os
import re

base_dir = '/var/www/rebelwithlinux.com'
extensions = ['.html']

new_footer = '''<footer id="site-footer" style="text-align: center; padding: 0 24px 24px;">
        <div style="font-size: 1.2rem; margin-bottom: 20px;">www.rebelwithlinux.com</div>
        <div style="margin-bottom: 23px;">
            <a href="site-map.html" style="color: var(--black);">Site Map</a>
            <span style="color: var(--charcoal);"> | </span>
            <a href="http://2wziokw2zpmrawplzbkowhrr6plc7wfebsdgrrnerbpebvhyhmqnxgad.onion" style="color: var(--black);">Onion Site</a>
            <span style="color: var(--charcoal);"> | </span>
            <a href="https://github.com/cjboon/rebelwithlinux" style="color: var(--black);">GitHub</a>
        </div>
        <div>
            <a href="about.html" style="color: var(--black);">About</a>
            <span style="color: var(--charcoal);"> | </span>
            <a href="contact.html" style="color: var(--black);">Contact</a>
            <span style="color: var(--charcoal);"> | </span>
            <a href="stats.html" style="color: var(--black);">Stats</a>
        </div>
    </footer>'''

count = 0
for root, dirs, files in os.walk(base_dir):
    for file in files:
        if any(file.endswith(ext) for ext in extensions):
            full_path = os.path.join(root, file)
            with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            
            old_pattern = r'<footer id="site-footer"[^>]*>.*?</footer>'
            if re.search(old_pattern, content, re.DOTALL):
                new_content = re.sub(old_pattern, new_footer, content, flags=re.DOTALL)
                with open(full_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated: {full_path}")
                count += 1

print(f"Done! Updated {count} files.")
