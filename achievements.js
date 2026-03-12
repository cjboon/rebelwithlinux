const ACHIEVEMENTS = {
    first_lesson: {
        id: 'first_lesson',
        name: 'First Steps',
        description: 'Complete your first guide',
        icon: '🎯',
        requirement: 1,
        xp: 50
    },
    linux_novice: {
        id: 'linux_novice',
        name: 'Linux Novice',
        description: 'Complete Linux Fundamentals',
        icon: '🐧',
        requirement: 1,
        xp: 100
    },
    bash_beginner: {
        id: 'bash_beginner',
        name: 'Shell Scripting Rookie',
        description: 'Complete Bash Scripting guide',
        icon: '💻',
        requirement: 1,
        xp: 100
    },
    git_user: {
        id: 'git_user',
        name: 'Version Control User',
        description: 'Complete Git guide',
        icon: '🔀',
        requirement: 1,
        xp: 100
    },
    web_dev: {
        id: 'web_dev',
        name: 'Web Developer',
        description: 'Complete HTML, CSS, and JavaScript',
        icon: '🌐',
        requirement: 3,
        xp: 200
    },
    python_coder: {
        id: 'python_coder',
        name: 'Python Coder',
        description: 'Complete Python guide',
        icon: '🐍',
        requirement: 1,
        xp: 100
    },
    server_admin: {
        id: 'server_admin',
        name: 'Server Admin',
        description: 'Complete 3 server guides',
        icon: '🖥️',
        requirement: 3,
        xp: 250
    },
    docker_master: {
        id: 'docker_master',
        name: 'Container Master',
        description: 'Complete Docker guide',
        icon: '📦',
        requirement: 1,
        xp: 150
    },
    project_builder: {
        id: 'project_builder',
        name: 'Project Builder',
        description: 'Complete your first project',
        icon: '🔨',
        requirement: 1,
        xp: 200
    },
    homelabber: {
        id: 'homelabber',
        name: 'Homelabber',
        description: 'Complete a homelab project',
        icon: '🏠',
        requirement: 1,
        xp: 300
    },
    privacy_advocate: {
        id: 'privacy_advocate',
        name: 'Privacy Advocate',
        description: 'Complete all security guides',
        icon: '🛡️',
        requirement: 3,
        xp: 350
    },
    full_stack: {
        id: 'full_stack',
        name: 'Full Stack Rebel',
        description: 'Complete 10 guides',
        icon: '⭐',
        requirement: 10,
        xp: 500
    },
    k8s_ninja: {
        id: 'k8s_ninja',
        name: 'Kubernetes Ninja',
        description: 'Complete Kubernetes guide',
        icon: '☸️',
        requirement: 1,
        xp: 400
    },
    hard_way: {
        id: 'hard_way',
        name: 'Learned It The Hard Way',
        description: 'Complete Arch Linux or build from scratch guides',
        icon: '🔥',
        requirement: 1,
        xp: 300
    },
    vpn_warrior: {
        id: 'vpn_warrior',
        name: 'VPN Warrior',
        description: 'Set up WireGuard VPN',
        icon: '🔒',
        requirement: 1,
        xp: 200
    },
    terminal_master: {
        id: 'terminal_master',
        name: 'Terminal Master',
        description: 'Complete any terminal game',
        icon: '🖥️',
        requirement: 1,
        xp: 100
    },
    bash_champion: {
        id: 'bash_champion',
        name: 'Bash Champion',
        description: 'Complete Bash terminal game',
        icon: '💻',
        requirement: 1,
        xp: 150
    },
    python_dev: {
        id: 'python_dev',
        name: 'Python Developer',
        description: 'Complete Python terminal game',
        icon: '🐍',
        requirement: 1,
        xp: 150
    },
    linux_expert: {
        id: 'linux_expert',
        name: 'Linux Expert',
        description: 'Complete Linux terminal game',
        icon: '🐧',
        requirement: 1,
        xp: 150
    },
    vim_ninja: {
        id: 'vim_ninja',
        name: 'Vim Ninja',
        description: 'Complete Vim terminal game',
        icon: '✏️',
        requirement: 1,
        xp: 150
    },
    sql_wizard: {
        id: 'sql_wizard',
        name: 'SQL Wizard',
        description: 'Complete SQL terminal game',
        icon: '🗄️',
        requirement: 1,
        xp: 150
    },
    regex_master: {
        id: 'regex_master',
        name: 'Regex Master',
        description: 'Complete Regex terminal game',
        icon: '🔍',
        requirement: 1,
        xp: 150
    },
    git_guru: {
        id: 'git_guru',
        name: 'Git Guru',
        description: 'Complete Git terminal game',
        icon: '🔀',
        requirement: 1,
        xp: 150
    },
    tool_collector: {
        id: 'tool_collector',
        name: 'Tool Collector',
        description: 'Complete 5 terminal games',
        icon: '🛠️',
        requirement: 5,
        xp: 300
    },
    sed_wizard: {
        id: 'sed_wizard',
        name: 'Sed Wizard',
        description: 'Complete Sed terminal game',
        icon: '✨',
        requirement: 1,
        xp: 150
    },
    ssh_specialist: {
        id: 'ssh_specialist',
        name: 'SSH Specialist',
        description: 'Complete SSH terminal game',
        icon: '🔑',
        requirement: 1,
        xp: 150
    },
    jq_genius: {
        id: 'jq_genius',
        name: 'jq Genius',
        description: 'Complete jq terminal game',
        icon: '📋',
        requirement: 1,
        xp: 150
    },
    awk_master: {
        id: 'awk_master',
        name: 'AWK Master',
        description: 'Complete AWK terminal game',
        icon: '📊',
        requirement: 1,
        xp: 150
    },
    curl_expert: {
        id: 'curl_expert',
        name: 'cURL Expert',
        description: 'Complete cURL terminal game',
        icon: '🌐',
        requirement: 1,
        xp: 150
    }
};

const LEVELS = [
    { level: 1, title: 'Newbie', xpRequired: 0 },
    { level: 2, title: 'Apprentice', xpRequired: 100 },
    { level: 3, title: 'Learner', xpRequired: 300 },
    { level: 4, title: 'Contributor', xpRequired: 600 },
    { level: 5, title: 'Practitioner', xpRequired: 1000 },
    { level: 6, title: 'Specialist', xpRequired: 1500 },
    { level: 7, title: 'Expert', xpRequired: 2200 },
    { level: 8, title: 'Master', xpRequired: 3000 },
    { level: 9, title: 'Guru', xpRequired: 4000 },
    { level: 10, title: 'Legend', xpRequired: 5500 }
];

let userAchievements = {
    completed: [],
    xp: 0
};

function loadAchievements() {
    const saved = localStorage.getItem('rebel_achievements');
    if (saved) {
        userAchievements = JSON.parse(saved);
    }
}

function saveAchievements() {
    localStorage.setItem('rebel_achievements', JSON.stringify(userAchievements));
}

function addXP(amount) {
    userAchievements.xp += amount;
    checkLevelUp();
    saveAchievements();
    updateAchievementUI();
}

function unlockAchievement(achievementId) {
    if (!userAchievements.completed.includes(achievementId)) {
        userAchievements.completed.push(achievementId);
        const achievement = ACHIEVEMENTS[achievementId];
        addXP(achievement.xp);
        showAchievementPopup(achievement);
        return true;
    }
    return false;
}

function getCurrentLevel() {
    let currentLevel = LEVELS[0];
    for (const level of LEVELS) {
        if (userAchievements.xp >= level.xpRequired) {
            currentLevel = level;
        }
    }
    return currentLevel;
}

function getNextLevel() {
    const currentLevel = getCurrentLevel();
    const currentIndex = LEVELS.indexOf(currentLevel);
    return currentIndex < LEVELS.length - 1 ? LEVELS[currentIndex + 1] : null;
}

function getProgressToNextLevel() {
    const currentLevel = getCurrentLevel();
    const nextLevel = getNextLevel();
    if (!nextLevel) return 100;
    
    const xpInCurrentLevel = userAchievements.xp - currentLevel.xpRequired;
    const xpNeeded = nextLevel.xpRequired - currentLevel.xpRequired;
    return Math.floor((xpInCurrentLevel / xpNeeded) * 100);
}

function checkLevelUp() {
    const newLevel = getCurrentLevel();
    const savedLevel = localStorage.getItem('rebel_level');
    if (savedLevel && parseInt(savedLevel) < newLevel.level) {
        showLevelUpPopup(newLevel);
    }
    localStorage.setItem('rebel_level', newLevel.level);
}

function checkAchievements(completedCourses) {
    const completed = new Set(completedCourses);
    
    if (completed.size >= 1) unlockAchievement('first_lesson');
    if (completed.has('linux.html')) unlockAchievement('linux_novice');
    if (completed.has('bash.html')) unlockAchievement('bash_beginner');
    if (completed.has('git.html')) unlockAchievement('git_user');
    if (completed.has('python.html')) unlockAchievement('python_coder');
    if (completed.has('docker.html')) unlockAchievement('docker_master');
    if (completed.has('kubernetes.html')) unlockAchievement('k8s_ninja');
    
    const webDevCount = ['hyper.html', 'css.html', 'javascript.html'].filter(c => completed.has(c)).length;
    if (webDevCount >= 3) unlockAchievement('web_dev');
    
    const serverCount = ['nginx.html', 'apache2.html', 'vps.html'].filter(c => completed.has(c)).length;
    if (serverCount >= 3) unlockAchievement('server_admin');
    
    const securityCount = ['hardening.html', 'networking.html', 'dns.html'].filter(c => completed.has(c)).length;
    if (securityCount >= 3) unlockAchievement('privacy_advocate');
    
    if (completed.size >= 10) unlockAchievement('full_stack');
    
    const projects = ['project-homelab.html', 'project-wireguard.html', 'project-blog.html', 'project-paste.html', 'project-fileshare.html'];
    const completedProjects = projects.filter(c => completed.has(c));
    if (completedProjects.length >= 1) unlockAchievement('project_builder');
    if (completed.has('project-homelab.html')) unlockAchievement('homelabber');
    if (completed.has('project-wireguard.html')) unlockAchievement('vpn_warrior');
    
    // Terminal games achievements
    const terminalGames = ['bash', 'python', 'linux', 'vim', 'sql', 'sed', 'regex', 'ssh', 'jq', 'awk', 'curl', 'git'];
    const completedTerminals = terminalGames.filter(g => completed.has(g + 'term.html'));
    if (completedTerminals.length >= 1) unlockAchievement('terminal_master');
    if (completedTerminals.length >= 5) unlockAchievement('tool_collector');
    if (completed.has('bashterm.html')) unlockAchievement('bash_champion');
    if (completed.has('pyterm.html')) unlockAchievement('python_dev');
    if (completed.has('nixterm.html')) unlockAchievement('linux_expert');
    if (completed.has('vimterm.html')) unlockAchievement('vim_ninja');
    if (completed.has('sqlterm.html')) unlockAchievement('sql_wizard');
    if (completed.has('regexterm.html')) unlockAchievement('regex_master');
    if (completed.has('gitterm.html')) unlockAchievement('git_guru');
    if (completed.has('sedterm.html')) unlockAchievement('sed_wizard');
    if (completed.has('sshterm.html')) unlockAchievement('ssh_specialist');
    if (completed.has('jqterm.html')) unlockAchievement('jq_genius');
    if (completed.has('awkterm.html')) unlockAchievement('awk_master');
    if (completed.has('curlterm.html')) unlockAchievement('curl_expert');
}

function showAchievementPopup(achievement) {
    const popup = document.createElement('div');
    popup.className = 'achievement-popup';
    popup.innerHTML = `
        <div class="achievement-icon">${achievement.icon}</div>
        <div class="achievement-info">
            <div class="achievement-title">Achievement Unlocked!</div>
            <div class="achievement-name">${achievement.name}</div>
            <div class="achievement-desc">${achievement.description}</div>
            <div class="achievement-xp">+${achievement.xp} XP</div>
        </div>
    `;
    document.body.appendChild(popup);
    setTimeout(() => popup.classList.add('show'), 10);
    setTimeout(() => {
        popup.classList.remove('show');
        setTimeout(() => popup.remove(), 300);
    }, 4000);
}

function showLevelUpPopup(level) {
    const popup = document.createElement('div');
    popup.className = 'achievement-popup level-popup';
    popup.innerHTML = `
        <div class="achievement-icon level-icon">⬆️</div>
        <div class="achievement-info">
            <div class="achievement-title">Level Up!</div>
            <div class="achievement-name">${level.title}</div>
            <div class="achievement-desc">You are now level ${level.level}</div>
        </div>
    `;
    document.body.appendChild(popup);
    setTimeout(() => popup.classList.add('show'), 10);
    setTimeout(() => {
        popup.classList.remove('show');
        setTimeout(() => popup.remove(), 4000);
    }, 4000);
}

function updateAchievementUI() {
    if (!currentUser) return;
    
    const level = getCurrentLevel();
    const nextLevel = getNextLevel();
    const progress = getProgressToNextLevel();
    
    const container = document.querySelector('.user-avatar-container');
    if (!container) return;
    
    const existingPanel = container.querySelector('.achievement-panel');
    if (existingPanel) {
        existingPanel.innerHTML = generateAchievementPanelHTML(level, nextLevel, progress);
        return;
    }
}

function generateAchievementPanelHTML(level, nextLevel, progress) {
    const unlockedCount = userAchievements.completed.length;
    const totalCount = Object.keys(ACHIEVEMENTS).length;
    
    return `
        <div class="level-info">
            <div class="level-badge">${level.level}</div>
            <div class="level-details">
                <span class="level-title">${level.title}</span>
                <span class="xp-text">${userAchievements.xp} XP</span>
                ${nextLevel ? `<div class="progress-bar"><div class="progress-fill" style="width: ${progress}%"></div></div>` : '<span class="max-level">MAX LEVEL</span>'}
            </div>
        </div>
        <div class="achievements-summary" onclick="toggleAchievementsList()">
            <span>🏆 ${unlockedCount}/${totalCount} Achievements</span>
        </div>
        <div class="achievements-list" id="achievementsList">
            ${Object.values(ACHIEVEMENTS).map(a => `
                <div class="achievement-item ${userAchievements.completed.includes(a.id) ? 'unlocked' : 'locked'}">
                    <span class="achievement-item-icon">${a.icon}</span>
                    <div class="achievement-item-info">
                        <span class="achievement-item-name">${a.name}</span>
                        <span class="achievement-item-desc">${a.description}</span>
                    </div>
                    <span class="achievement-item-xp">+${a.xp}</span>
                </div>
            `).join('')}
        </div>
    `;
}

function toggleAchievementsList() {
    const list = document.getElementById('achievementsList');
    list.classList.toggle('expanded');
}

loadAchievements();
