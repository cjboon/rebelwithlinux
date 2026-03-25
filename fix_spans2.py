import re
import os

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all terminal-block sections
    pattern = re.compile(r'<div class="terminal-block">\s*<pre>(.*?)</pre>\s*</div>', re.DOTALL)
    
    def process_match(match):
        inner = match.group(1)
        lines = inner.split('\n')
        new_lines = []
        
        for line in lines:
            stripped = line.strip()
            
            if not stripped:
                new_lines.append('')
                continue
            
            # Get leading whitespace
            lead_match = re.match(r'^(\s*)', line)
            indent = lead_match.group(1) if lead_match else ''
            
            # Remove existing spans
            line = re.sub(r'</?span[^>]*>', '', line)
            stripped = line.strip()
            
            if stripped.startswith('#'):
                new_lines.append(f'{indent}<span class="comment">{stripped}</span>')
            elif stripped.startswith('$'):
                # Split on $ to get prompt and command
                parts = stripped.split('$', 1)
                if len(parts) == 2 and parts[1].strip():
                    cmd = parts[1].strip()
                    new_lines.append(f'{indent}<span class="prompt">$</span> <span class="command">{cmd}</span>')
                else:
                    new_lines.append(f'{indent}<span class="prompt">$</span>')
            elif stripped.startswith('+') or stripped.startswith('|') or stripped.startswith('[') or stripped.startswith('---') or stripped.startswith('webservers') or stripped.startswith('roles') or stripped.startswith('tasks') or stripped.startswith('name') or stripped.startswith('hosts') or stripped.startswith('become') or stripped.startswith('apt') or stripped.startswith('service') or stripped.startswith('template') or stripped.startswith('notify') or stripped.startswith('handlers'):
                new_lines.append(f'{indent}<span class="output">{stripped}</span>')
            else:
                # Check if it looks like command output
                if re.match(r'^[a-zA-Z0-9\.\-\/\:]+', stripped) or re.match(r'^d?[rwx\-]{10}', stripped):
                    new_lines.append(f'{indent}<span class="output">{stripped}</span>')
                else:
                    new_lines.append(f'{indent}{stripped}')
        
        new_inner = '\n'.join(new_lines)
        return f'<div class="terminal-block">\n<pre>\n{new_inner}\n</pre>\n</div>'
    
    new_content = pattern.sub(process_match, content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f'Processed {filepath}')

projects_dir = '/var/www/rebelwithlinux.com/projects'
for filename in os.listdir(projects_dir):
    if filename.endswith('.html'):
        filepath = os.path.join(projects_dir, filename)
        try:
            process_file(filepath)
        except Exception as e:
            print(f'Error processing {filename}: {e}')

print('Done!')
