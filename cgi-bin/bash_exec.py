#!/usr/bin/env python3
import os
import re
import subprocess
import json
import html
import sys
import urllib.parse

ALLOWED_COMMANDS = {
    'echo', 'printf', 'pwd', 'ls', 'cd', 'cat', 'head', 'tail',
    'grep', 'awk', 'sed', 'sort', 'uniq', 'wc', 'find', 'date',
    'whoami', 'hostname', 'uname', 'id', 'which', 'type',
    'true', 'false', 'test', 'expr', 'bc', 'seq',
    'mkdir', 'rmdir', 'touch', 'rm', 'cp', 'mv', 'ln',
    'ps', 'pidof', 'kill', 'top', 'free', 'df', 'netstat', 'lsof',
    'chmod', 'chown',
}

ALLOWED_BUILTINS = {
    'echo', 'printf', 'read', 'cd', 'pwd', 'ls', 'type',
    'alias', 'unalias', 'set', 'shopt', 'trap',
    'source', '.', ':',
}

ALLOWED_KEYWORDS = {
    'for', 'while', 'until', 'do', 'done', 'if', 'then', 'else',
    'elif', 'fi', 'case', 'esac', 'function', 'return', 'exit',
    'break', 'continue', 'select', 'time', 'coproc',
}

SAFE_PATTERNS = [
    r'^echo\s+["\'].*["\']$',
    r'^echo\s+["\'].*["\']\s*>\s*[\w./-]+$',
    r'^echo\s+["\'].*["\']\s*>>\s*[\w./-]+$',
    r'^echo\s+[$\w_]+$',
    r'^printf\s+',
    r'^pwd$',
    r'^ls\s+-?[a-zA-Z]*~?[\w./~-]*$',
    r'^ls\s+-?[a-zA-Z]*\s+[\w./~-]+$',
    r'^cd\s+[~\w./-]*$',
    r'^cat\s+[\w./-]+$',
    r'^head\s+',
    r'^tail\s+',
    r'^grep\s+',
    r'^grep\s+-r\s+',
    r'^awk\s+',
    r'^sed\s+',
    r'^sort\s+',
    r'^uniq\s+',
    r'^wc\s+',
    r'^find\s+',
    r'^date$',
    r'^whoami$',
    r'^hostname$',
    r'^uname\s*(-[a-zA-Z]*)*$',
    r'^id$',
    r'^which\s+',
    r'^type\s+',
    r'^ps\s*',
    r'^pidof\s+',
    r'^kill\s+',
    r'^top$',
    r'^free\s*',
    r'^df\s*',
    r'^netstat\s*',
    r'^lsof\s*',
    r'^chmod\s+',
    r'^chown\s+',
    r'^rmdir\s+[\w./-]+$',
    r'^touch\s+[\w./-]+$',
    r'^rm\s+-?[rfw]*\s*[\w./-]+$',
    r'^cp\s+',
    r'^mv\s+',
    r'^ln\s+',
    r'^\$[\w_]+=',
    r'^\w+=',
    r'^["\'].*["\']$',
]

DANGEROUS_PATTERNS = [
    r'[;&|`$]',
    r'\$\(',
    r'`.*`',
    r'&&\s*\w+',
    r'\|\|\s*\w+',
    r'\$\{',
    r'\$\w+',
    r'\$\$',
    r'>\s*/',
    r'<\s*/',
]

def is_command_allowed(cmd):
    """Check if command is allowed using allowlist approach"""
    cmd = cmd.strip()
    if not cmd:
        return False
    
    if cmd.startswith('#'):
        return False
    
    words = cmd.split()
    first_word = words[0]
    
    if first_word in ['"', "'"]:
        return True
    
    if '=' in first_word and not first_word.startswith('='):
        return True
    
    if first_word.startswith('$'):
        return False
    
    if first_word in ALLOWED_BUILTINS or first_word in ALLOWED_KEYWORDS:
        pass
    elif first_word not in ALLOWED_COMMANDS:
        return False
    
    for pattern in DANGEROUS_PATTERNS:
        if re.search(pattern, cmd):
            return False
    
    for pattern in SAFE_PATTERNS:
        if re.match(pattern, cmd):
            return True
    
    return False

def sanitize_output(output):
    """Sanitize output for web display"""
    if len(output) > 5000:
        output = output[:5000] + "\n... (output truncated)"
    return html.escape(output)

def execute_bash(code):
    import resource
    import signal
    """Execute bash code and return output"""
    # Split by newlines but preserve multiline structures
    lines = code.split('\n')
    
    # Validate each line
    for line in lines:
        line = line.strip()
        if line and not line.startswith('#'):  # Skip empty and comments
            # Check for command substitution that might be dangerous
            if '$(' in line or '`' in line:
                # Allow simple $VAR but block command substitution
                if re.search(r'\$\([^)]+\)', line) or re.search(r'`[^`]+`', line):
                    return "Error: Command substitution not allowed in this safe learning environment"
    
    import uuid
    import shutil
    import time
    
    SESSION_TIMEOUT = 1800  # 30 minutes
    
    def get_session_dir(session_id):
        """Get or create session directory"""
        import hashlib
        random_suffix = hashlib.sha256(session_id.encode()).hexdigest()[:16]
        return f'/tmp/linux_demo_{random_suffix}'
    
    def cleanup_old_sessions():
        """Clean up sessions older than SESSION_TIMEOUT"""
        base_dir = '/tmp'
        try:
            for item in os.listdir(base_dir):
                if item.startswith('linux_demo_'):
                    item_path = os.path.join(base_dir, item)
                    if os.path.isdir(item_path):
                        # Check modification time
                        mtime = os.path.getmtime(item_path)
                        if time.time() - mtime > SESSION_TIMEOUT:
                            shutil.rmtree(item_path)
        except:
            pass
    
    def setup_demo_files(work_dir):
        """Create demo files for learning if they don't exist"""
        if os.path.exists(work_dir) and os.listdir(work_dir):
            return  # Already has files
        
        # Create some sample files
        sample_files = {
            'welcome.txt': 'Welcome to Linux Larry\'s Tutorial!\n\nThis is a safe learning environment.\nFeel free to practice commands here.',
            'notes.txt': 'My Linux Notes\n================\n- ls: list files\n- cd: change directory\n- mkdir: make directory\n- cat: view file contents',
            'shopping.txt': 'milk\neggs\nbread\ncheese\napples',
            'numbers.txt': '1\n2\n3\n4\n5\n6\n7\n8\n9\n10',
            'secret.txt': 'This file contains secrets... just kidding! :)',
        }
        
        for filename, content in sample_files.items():
            with open(os.path.join(work_dir, filename), 'w') as f:
                f.write(content)
        
        # Create a subdirectory
        os.makedirs(os.path.join(work_dir, 'projects'), exist_ok=True)
        with open(os.path.join(work_dir, 'projects', 'readme.txt'), 'w') as f:
            f.write('This is your projects folder!\nCreate your own directories here.')
    
    # Wrap in bash -c with timeout
    try:
        # Clean up old sessions occasionally
        cleanup_old_sessions()
        
        # Get session ID from request
        parsed = urllib.parse.parse_qs(post_data)
        session_id = parsed.get('session', [''])[0]
        
        # Use provided session or generate new one
        if not session_id:
            session_id = 'anon_' + str(uuid.uuid4())[:8]
        
        work_dir = get_session_dir(session_id)
        
        if not os.path.exists(work_dir):
            os.makedirs(work_dir)
        
        setup_demo_files(work_dir)
        
        cwd_file = work_dir + '/.cwd'
        if os.path.exists(cwd_file):
            with open(cwd_file, 'r') as f:
                current_cwd = f.read().strip()
            if not current_cwd.startswith(work_dir) or not os.path.isdir(current_cwd):
                current_cwd = work_dir
        else:
            current_cwd = work_dir
        
        cmd = code.strip()
        is_cd_only = cmd == 'cd' or cmd.startswith('cd ')
        
        if is_cd_only:
            target = ''
            target_dir = work_dir
            if cmd == 'cd':
                target_dir = work_dir
            else:
                target = cmd[3:].strip()
                if target == '~' or target == '':
                    target_dir = work_dir
                elif target == '..':
                    current_cwd = os.path.dirname(current_cwd)
                    target_dir = current_cwd if current_cwd.startswith(work_dir) else work_dir
                elif target.startswith('/'):
                    target_dir = target if target.startswith(work_dir) else work_dir
                else:
                    target_dir = os.path.normpath(os.path.join(current_cwd, target))
            
            if target_dir.startswith(work_dir) and os.path.isdir(target_dir):
                current_cwd = target_dir
                with open(cwd_file, 'w') as f:
                    f.write(current_cwd)
                return ""
            else:
                return f"cd: no such directory: {target}"
        
        with open(cwd_file, 'w') as f:
            f.write(current_cwd)
        
        fake_log_dir = os.path.join(work_dir, 'var', 'log')
        os.makedirs(fake_log_dir, exist_ok=True)
        with open(os.path.join(fake_log_dir, 'syslog'), 'w') as f:
            f.write('Mar 11 10:30:01 server CRON[1234]: User root started task\n')
            f.write('Mar 11 10:31:22 server sshd[5678]: Failed password for invalid user admin\n')
            f.write('Mar 11 10:32:45 server kernel: error: disk read failure\n')
            f.write('Mar 11 10:33:10 server nginx[999]: Connection from 192.168.1.1\n')
        with open(os.path.join(fake_log_dir, 'auth.log'), 'w') as f:
            f.write('Mar 11 09:00:00 server sudo: user : TTY=pts/0 ; PWD=/home ; USER=root ; COMMAND=/bin/ls\n')
        
        code = code.replace('/var/log', os.path.join(work_dir, 'var', 'log'))
        
        try:
            restricted_env = {
                'HOME': work_dir,
                'PATH': '/usr/bin:/bin',
                'SHELL': '/bin/bash',
                'PWD': work_dir,
                'USER': 'guest',
                'LOGNAME': 'guest',
                'TERM': 'dumb',
                'LANG': 'C.UTF-8',
            }
            
            def timeout_handler(signum, frame):
                raise TimeoutError("Command timed out")
            
            old_sig = signal.signal(signal.SIGALRM, timeout_handler)
            signal.alarm(5)
            
            try:
                resource.setrlimit(resource.RLIMIT_NPROC, (5, 5))
                resource.setrlimit(resource.RLIMIT_NOFILE, (10, 10))
                resource.setrlimit(resource.RLIMIT_FSIZE, (1024*1024, 1024*1024))
                resource.setrlimit(resource.RLIMIT_CPU, (5, 5))
                resource.setrlimit(resource.RLIMIT_AS, (64*1024*1024, 64*1024*1024))
            except (ValueError, resource.error):
                pass
            
            result = subprocess.run(
                ['bash', '--norc', '--noprofile', '-c', code],
                capture_output=True,
                text=True,
                timeout=5,
                cwd=current_cwd,
                env=restricted_env,
                preexec_fn=os.setpgrp
            )
            
            signal.alarm(0)
            
            output = result.stdout
            if result.stderr:
                output += result.stderr
            
            return output if output else "(no output)"
        except TimeoutError:
            return "Error: Command timed out (possible infinite loop)"
        except:
            return "Error executing command. Please try again."
        
    except subprocess.TimeoutExpired:
        return "Error: Command timed out (possible infinite loop)"
    except Exception as e:
        return f"Error: {str(e)}"

# Get the code from POST request
print("Content-Type: application/json")
print()

# Check content type
content_type = os.environ.get('CONTENT_TYPE', '')

# Read POST data
content_length = int(os.environ.get('CONTENT_LENGTH', 0))
post_data = sys.stdin.read(content_length) if content_length > 0 else ''

# Parse the form data
code = ''
if post_data:
    try:
        if 'application/x-www-form-urlencoded' in content_type:
            parsed = urllib.parse.parse_qs(post_data)
            code = parsed.get('code', [''])[0]
        elif 'multipart/form-data' in content_type:
            # Handle multipart form data
            import re
            match = re.search(r'name="code"\r\n\r\n(.+?)(?=\r\n--|$)', post_data, re.DOTALL)
            if match:
                code = match.group(1).strip()
        else:
            # Try as raw
            code = post_data.strip()
    except Exception as e:
        code = ''

if not code:
    print(json.dumps({'output': 'No code provided', 'error': True}))
else:
    # Validate the code
    if not is_command_allowed(code):
        print(json.dumps({'output': 'Command not allowed in safe learning mode', 'error': True}))
    else:
        output = execute_bash(code)
        print(json.dumps({'output': sanitize_output(output), 'error': False}))
