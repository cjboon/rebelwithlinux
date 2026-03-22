#!/usr/bin/env python3
import re
from pathlib import Path

FLASH_PREVENTION = '''    <script>
        (function() {
            var saved = localStorage.getItem('theme');
            var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            var theme = saved || (prefersDark ? 'dark' : 'light');
            document.documentElement.setAttribute('data-theme', theme);
        })();
    </script>
'''

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Remove existing flash prevention + theme.js (to handle re-runs)
    existing_pattern = re.compile(
        r'\n    <script>\s*\(function\(\)\s*\{\s*var saved = localStorage\.getItem\([\'"]theme[\'"]\);\s*'
        r'var prefersDark = window\.matchMedia\([\'"]\(prefers-color-scheme: dark\)[\'"]\)\.matches;\s*'
        r'var theme = saved \|\| \(prefersDark \? [\'"]dark[\']: [\'"]light[\']\);\s*'
        r'document\.documentElement\.setAttribute\([\'"]data-theme[\'"], theme\);\s*'
        r'\}\)\(\);\s*</script>\s*<script src="\.\./theme\.js"></script>\s*'
    )
    content = existing_pattern.sub('', content)
    
    # Find </head>
    head_match = re.search(r'</head>', content)
    if not head_match:
        print(f"  WARNING: No </head> found in {filepath.name}")
        return False
    
    head_end = head_match.start()
    before_head = content[:head_end]
    after_head = content[head_match.end():]
    
    # Check if terminal-select.js exists in before_head
    has_terminal_select = '../terminal-select.js' in before_head
    
    # Remove various theme script patterns using a more flexible approach
    # We'll match and remove content between <script> tags that contain theme-related code
    
    # Pattern 1: Theme persistence with checkbox sync in one script
    p1 = re.compile(
        r'<script>\s*// Theme persistence - check and apply immediately in head.*?'
        r'</script>\s*',
        re.DOTALL
    )
    before_head = p1.sub('', before_head)
    
    # Pattern 2: Sync checkbox after DOM loads
    p2 = re.compile(
        r'<script>\s*// Sync checkbox after DOM loads.*?'
        r'</script>\s*',
        re.DOTALL
    )
    before_head = p2.sub('', before_head)
    
    # Pattern 3: Theme toggle functionality
    p3 = re.compile(
        r'<script>\s*// Theme toggle functionality.*?'
        r'</script>\s*',
        re.DOTALL
    )
    before_head = p3.sub('', before_head)
    
    # Pattern 4: Simple theme persistence scripts (const savedTheme = localStorage pattern)
    p4 = re.compile(
        r'<script>\s*const savedTheme = localStorage\.getItem\([\'"]theme[\'"]\);.*?'
        r'</script>\s*',
        re.DOTALL
    )
    before_head = p4.sub('', before_head)
    
    # Clean up multiple blank lines
    before_head = re.sub(r'\n{3,}', '\n\n', before_head)
    
    # Ensure terminal-select.js is present if it was in original
    if has_terminal_select and '../terminal-select.js' not in before_head:
        # Find position after style.css link and insert terminal-select.js
        match = re.search(r'(<link rel="stylesheet" href="\.\./style\.css">)\s*', before_head)
        if match:
            insert_pos = match.end()
            before_head = before_head[:insert_pos] + '\n    <script src="../terminal-select.js"></script>' + before_head[insert_pos:]
    
    # Insert flash prevention and theme.js before </head>
    new_content = before_head + '\n' + FLASH_PREVENTION + '    <script src="../theme.js"></script>\n</head>' + after_head
    
    if new_content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

def main():
    guides_dir = Path('/var/www/rebelwithlinux.com/guides')
    html_files = sorted(guides_dir.glob('*.html'))
    
    print(f"Found {len(html_files)} HTML files")
    
    modified = 0
    for filepath in html_files:
        try:
            if process_file(filepath):
                print(f"Modified: {filepath.name}")
                modified += 1
            else:
                print(f"No changes: {filepath.name}")
        except Exception as e:
            print(f"ERROR in {filepath.name}: {e}")
            import traceback
            traceback.print_exc()
    
    print(f"\nTotal modified: {modified}/{len(html_files)}")

if __name__ == '__main__':
    main()
