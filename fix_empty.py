import re
import os

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove empty lines inside terminal-block pre
    pattern = re.compile(r'(<div class="terminal-block">\s*<pre>)\n\n+', re.DOTALL)
    content = pattern.sub(r'\1\n', content)
    
    pattern = re.compile(r'\n\n+(</pre>)', re.DOTALL)
    content = pattern.sub(r'\n\1', content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f'Fixed {filepath}')

projects_dir = '/var/www/rebelwithlinux.com/projects'
for filename in os.listdir(projects_dir):
    if filename.endswith('.html'):
        filepath = os.path.join(projects_dir, filename)
        try:
            process_file(filepath)
        except Exception as e:
            print(f'Error: {filename}: {e}')

print('Done!')
