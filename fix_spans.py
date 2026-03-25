import re
import os

# Pattern to match terminal-block content
pattern = re.compile(r'(<div class="terminal-block">\s*<pre>)(.*?)(</pre>\s*</div>)', re.DOTALL)

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    def add_spans(match):
        pre_open = match.group(1)
        inner = match.group(2)
        pre_close = match.group(3)
        
        lines = inner.split('\n')
        new_lines = []
        for line in lines:
            # Skip empty lines
            if not line.strip():
                new_lines.append('')
                continue
            
            # Check if line starts with # (comment) or $ (prompt)
            stripped = line.lstrip()
            if stripped.startswith('#'):
                # Comment line
                leading = len(line) - len(line.lstrip())
                indent = line[:leading]
                new_lines.append(f'{indent}<span class="comment">{stripped}</span>')
            elif '$' in line:
                # Command line with prompt
                parts = line.split('$', 1)
                if len(parts) == 2:
                    leading = parts[0]
                    rest = parts[1].strip()
                    if rest.startswith('<'):
                        # HTML tag, keep as is
                        new_lines.append(line)
                    else:
                        new_lines.append(f'{leading}$ <span class="command">{rest}</span>')
                else:
                    new_lines.append(line)
            else:
                # Output or other content
                new_lines.append(f'<span class="output">{line}</span>')
        
        new_inner = '\n'.join(new_lines)
        return f'{pre_open}\n{new_inner}\n{pre_close}'
    
    new_content = pattern.sub(add_spans, content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f'Processed {filepath}')

# Process all project files
projects_dir = '/var/www/rebelwithlinux.com/projects'
for filename in os.listdir(projects_dir):
    if filename.endswith('.html'):
        filepath = os.path.join(projects_dir, filename)
        try:
            process_file(filepath)
        except Exception as e:
            print(f'Error processing {filename}: {e}')

print('Done!')
