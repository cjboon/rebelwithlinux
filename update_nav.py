#!/usr/bin/env python3
import os
import re

base_dir = '/var/www/rebelwithlinux.com'
dirs = ['guides', 'tests', 'games', 'blog', 'builders', 'hangman', 'terms']

for d in dirs:
    dir_path = os.path.join(base_dir, d)
    if not os.path.isdir(dir_path):
        continue
    for filename in os.listdir(dir_path):
        if not filename.endswith('.html'):
            continue
        filepath = os.path.join(dir_path, filename)
        with open(filepath, 'r') as f:
            content = f.read()
        if 'href="search.html"' in content:
            new_content = content.replace('href="search.html"', 'href="../pathway.html"')
            with open(filepath, 'w') as f:
                f.write(new_content)
            print(f"Updated: {filepath}")

print("Done!")