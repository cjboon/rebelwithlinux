# Rebel With Linux - Specification Document

## 1. Project Overview

**Project Name:** Rebel With Linux
**Project Type:** Educational Website
**Core Functionality:** A comprehensive Linux and FOSS learning platform with multiple content formats: guides, interactive games (builder, hangman), quizzes, blog posts, term references, and project tutorials.
**Target Users:** Beginners to advanced users learning Linux, DevOps, web development, and privacy-focused computing

---

## 2. Technology Stack

- **Frontend:** Vanilla HTML, CSS, JavaScript
- **Styling:** Custom CSS with CSS variables for theming
- **Fonts:** IBM Plex Mono, IBM Plex Sans (self-hosted)
- **Storage:** localStorage for user progress/preferences
- **No backend required**

---

## 3. UI/UX Specification

### Layout Structure

**Navigation:**
- Fixed top navigation bar with site title "REBEL WITH LINUX"
- Theme toggle (dark/light mode)
- Hamburger menu for mobile with links: Search, Login, Account
- Section links: Manifesto, Distros, Games, Guides, Resources, Blog, About, Contact, Tests, Stats, Rebels, Footer

**Main Sections:**
- Manifesto/Hero section with call-to-action
- Distros section with distribution cards
- Games section with learning games
- Guides section with lesson cards in grid layout
- Resources section with privacy tool recommendations
- Blog section with categorized posts
- About section
- Contact section
- Tests section with quizzes
- Stats section
- Rebels section

**Footer:**
- Links to FOSS resources
- Copyleft notice
- "Free software is freedom, not just free beer"
- Hidden Tor service link

### Color Palette (Dark Mode - Default)
- `--ivory: #1a1a1a` (dark background)
- `--white: #1a1a1a` (card backgrounds)
- `--black: #e0e0e0` (text)
- `--charcoal: #c0c0c0` (secondary text)
- `--beige: #3a3a3a` (borders/highlights)
- `--nav-color: #FFFFFF` (navigation)

**Light Mode:**
- `--ivory: #FFFFFF`
- `--white: #FFFFFF`
- `--black: #000000`
- `--charcoal: #666666`
- `--beige: #FFFFFF`

### Typography
- **Headings:** IBM Plex Mono, monospace
- **Body:** IBM Plex Sans, sans-serif
- **Code/Terminal:** IBM Plex Mono, monospace

### Responsive Breakpoints
- Mobile: < 768px
- Tablet: 768px - 1024px
- Desktop: > 1024px

---

## 4. Content Categories

### Programming & Scripting
| Subject | Guide | Hangman | Builder | Test | Blog |
|---------|-------|---------|---------|------|------|
| Linux | ✓ | ✓ | ✓ | ✓ | ✓ |
| Bash | ✓ | ✓ | ✓ | ✓ | ✓ |
| Python | ✓ | ✓ | ✓ | ✓ | ✓ |
| JavaScript | ✓ | ✓ | ✓ | ✓ | ✓ |
| TypeScript | ✓ | ✓ | ✓ | - | ✓ |
| Go | ✓ | ✓ | ✓ | ✓ | ✓ |
| PHP | ✓ | ✓ | ✓ | ✓ | ✓ |
| SQL | - | ✓ | ✓ | ✓ | ✓ |

### Web Development
| Subject | Guide | Hangman | Builder | Test | Blog |
|---------|-------|---------|---------|------|------|
| HTML | ✓ | ✓ | ✓ | ✓ | ✓ |
| CSS | ✓ | ✓ | ✓ | ✓ | ✓ |
| Nginx | ✓ | ✓ | - | ✓ | ✓ |
| Apache | ✓ | - | - | ✓ | ✓ |

### DevOps & Cloud
| Subject | Guide | Hangman | Builder | Test | Blog |
|---------|-------|---------|---------|------|------|
| Docker | ✓ | ✓ | ✓ | ✓ | ✓ |
| Kubernetes | ✓ | ✓ | - | ✓ | ✓ |
| Jenkins | ✓ | ✓ | - | ✓ | ✓ |
| CI/CD | ✓ | ✓ | - | ✓ | ✓ |
| Ansible | - | ✓ | - | ✓ | ✓ |
| Terraform | - | ✓ | - | ✓ | ✓ |
| AWS | ✓ | ✓ | - | ✓ | ✓ |

### Networking & Security
| Subject | Guide | Hangman | Builder | Test | Blog |
|---------|-------|---------|---------|------|------|
| Networking | ✓ | ✓ | ✓ | ✓ | ✓ |
| DNS | ✓ | - | ✓ | - | ✓ |
| VPS | ✓ | ✓ | ✓ | ✓ | ✓ |
| Hardening | ✓ | ✓ | ✓ | ✓ | ✓ |
| GPG | ✓ | ✓ | ✓ | ✓ | ✓ |
| WireGuard | ✓ | ✓ | - | ✓ | ✓ |

### Databases
| Subject | Guide | Hangman | Builder | Test | Blog |
|---------|-------|---------|---------|------|------|
| MariaDB | ✓ | ✓ | ✓ | ✓ | ✓ |
| PostgreSQL | ✓ | ✓ | ✓ | - | ✓ |

### Observability
| Subject | Guide | Hangman | Builder | Test | Blog |
|---------|-------|---------|---------|------|------|
| Monitoring | ✓ | ✓ | - | ✓ | ✓ |
| Grafana | ✓ | ✓ | - | ✓ | ✓ |
| Prometheus | - | ✓ | - | ✓ | ✓ |
| Logging | ✓ | ✓ | ✓ | ✓ | ✓ |
| Vault | - | ✓ | - | - | ✓ |

### Privacy & Self-Hosting
| Subject | Guide | Hangman | Builder | Test | Blog |
|---------|-------|---------|---------|------|------|
| FOSS | ✓ | ✓ | ✓ | ✓ | ✓ |
| Monero | ✓ | ✓ | ✓ | ✓ | ✓ |
| Homelab | ✓ | ✓ | - | ✓ | ✓ |
| Pi-hole | ✓ | ✓ | - | ✓ | ✓ |

### Version Control & Automation
| Subject | Guide | Hangman | Builder | Test | Blog |
|---------|-------|---------|---------|------|------|
| Git | ✓ | ✓ | ✓ | ✓ | ✓ |
| GitHub | - | ✓ | - | - | ✓ |
| Helm | - | ✓ | - | - | - |

---

## 5. Content Type Specifications

### Guides (37 total)
Comprehensive written tutorials covering theory and practical examples.

### Builders (56 files)
Multi-part drag-and-drop code building games. Some subjects have 3 parts (e.g., builder-bash.html, builder-bash-2.html, builder-bash-3.html).

### Hangman (45 total)
Word-guessing games for learning commands and terms. Includes a main hub (hangman-main.html).

### Tests (39 total)
Interactive fill-in-the-blank quizzes with hints and scoring.

### Blog (55 total)
Quick guides and tips organized by category:
- Foundations (Linux, Bash, Vim)
- Web Basics (HTML, CSS, JavaScript, PHP)
- Programming (Python, Go, TypeScript)
- Version Control (Git)
- Networking & DNS
- Web Servers (Nginx, Apache2)
- Databases (SQL, MariaDB, PostgreSQL)
- Containers (Docker, Kubernetes)
- Automation & IaC (Ansible, Jenkins)

### Terms (13 total)
Command reference pages: awk, bash, curl, git, jq, nix, py, regex, sed, sql, ssh, vim

### Projects (9 total)
Step-by-step project tutorials: blog, fileshare, homelab, i3, mail, matrix, onion, paste, wireguard

### Games (6 total)
Interactive learning games: debian, debian-2, debian-3, quiz, speed, turing

---

## 6. Page Templates

### Guide Page
- Title and category badge
- Comprehensive content with code blocks
- Related links

### Builder Game Page
- Drag-and-drop interface
- Code building challenges
- Multi-part format for advanced topics

### Hangman Game Page
- Word guessing interface
- Category-based vocabulary

### Test/Quiz Page
- Fill-in-the-blank questions
- Hint system
- Score tracking

### Blog Post Page
- Article content
- Related posts

---

## 7. Features

- **Dark/Light Theme Toggle:** Persisted via localStorage
- **Responsive Design:** Mobile-first approach
- **Local Progress Tracking:** localStorage for quiz scores and completion
- **Accessibility:** Skip links, ARIA labels
- **SEO:** Meta tags, Open Graph, JSON-LD structured data
- **Offline Support:** Service worker (sw.js)
- **User Authentication:** Login/account system (account.html)
- **Search:** Search functionality (search.html)
- **Achievement System:** achievements.js

---

## 8. File Structure

```
/
├── index.html          # Main landing page
├── account.html        # User account page
├── search.html         # Search functionality
├── offline.html        # Offline page
├── site-map.html       # Sitemap
├── subject-chart.html  # Content coverage chart
├── style.css           # Main stylesheet
├── achievements.js     # Achievement system
├── nav.js              # Navigation logic
├── sw.js               # Service worker
├── fonts.css           # Font definitions
├── fonts/              # Self-hosted fonts
├── guides/             # 37 comprehensive guides
├── builders/           # 56 builder game files
├── hangman/            # 45 hangman game files
├── tests/              # 39 quiz files
├── blog/               # 55 blog posts
├── terms/              # 13 term reference pages
├── projects/           # 9 project tutorials
├── games/              # 6 learning games
└── cgi-bin/            # CGI scripts
```
