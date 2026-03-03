# Rebel With Linux - Specification Document

## 1. Project Overview

**Project Name:** Rebel With Linux  
**Project Type:** Educational Website (Single-page application with lesson navigation)  
**Core Functionality:** A comprehensive Linux learning platform with interactive lessons and fill-in-the-blank quizzes, promoting FOSS and privacy-consciousness  
**Target Users:** Beginners to intermediate users transitioning from proprietary software to Linux

---

## 2. UI/UX Specification

### Layout Structure

**Header:**
- Fixed navigation bar with site title "REBEL WITH LINUX"
- Navigation links: Lessons, About, Resources
- Tagline: "Free your mind. Own your data."

**Hero Section:**
- Large bold typography
- Manifesto-style introduction about FOSS and privacy
- Call-to-action button to start learning

**Content Areas:**
- Lesson cards in a grid layout (3 columns desktop, 1 column mobile)
- Each lesson has: title, description, difficulty badge, lesson content area
- Quiz section below each lesson

**Footer:**
- Links to FOSS resources
- Copyleft notice
- "Free software is freedom, not just free beer"

### Responsive Breakpoints
- Mobile: < 768px (single column)
- Tablet: 768px - 1024px (2 columns)
- Desktop: > 1024px (3 columns)

### Visual Design

**Color Palette:**
- Primary Background: `#FFFFF0` (Ivory)
- Secondary Background: `#FFFFFF` (White)
- Primary Text: `#0A0A0A` (Near Black)
- Accent: `#1A1A1A` (Dark Black)
- Border/Lines: `#2A2A2A` (Charcoal)
- Highlight: `#F5F5DC` (Beige)
- Error/Wrong: `#8B0000` (Dark Red)
- Success: `#006400` (Dark Green)

**Typography:**
- Headings: "IBM Plex Mono", monospace - Bold
- Body: "IBM Plex Sans", sans-serif
- Code/Terminal: "IBM Plex Mono", monospace
- H1: 3rem, H2: 2rem, H3: 1.5rem
- Body: 1rem, Small: 0.875rem

**Spacing System:**
- Base unit: 8px
- Section padding: 64px vertical, 32px horizontal
- Card padding: 24px
- Element gaps: 16px

**Visual Effects:**
- Sharp corners (no border-radius) - brutalist aesthetic
- Heavy black borders (3px solid)
- Hover: invert colors (black bg, white text)
- Box shadows: offset black shadows (8px 8px 0 #0A0A0A)
- Transitions: none or very fast (0.1s)

### Components

**Navigation Bar:**
- Black background, white text
- Heavy bottom border
- Links with underline on hover

**Lesson Cards:**
- White background with black border
- Title, description, difficulty indicator
- Click to expand/open lesson modal

**Lesson Modal/Content:**
- Full-width content area
- Terminal-style code blocks
- Clear headings and structured content

**Quiz Component:**
- Question with blank underlined
- Input field for answer
- Submit button
- Feedback (correct/incorrect with explanation)

**Buttons:**
- Black background, white text
- Heavy border
- Offset shadow on hover

**Badges:**
- Beginner: Ivory background, black border
- Intermediate: Black background, white text
- Advanced: Inverted (white bg, black text, black border)

---

## 3. Functionality Specification

### Core Features

**Lesson System:**
1. Lesson 1: Introduction to Linux & FOSS Philosophy
2. Lesson 2: The Terminal - Your Command Center
3. Lesson 3: File System Navigation
4. Lesson 4: File Permissions & Ownership
5. Lesson 5: Process Management
6. Lesson 6: Text Manipulation & Pipelines
7. Lesson 7: User & Group Management
8. Lesson 8: Package Management
9. Lesson 9: Networking Basics
10. Lesson 10: Shell Scripting Basics
11. Lesson 11: Security & Encryption Fundamentals
12. Lesson 12: Systemd & Services

**Quiz System:**
- 5-8 fill-in-the-blank questions per lesson
- Case-insensitive matching
- Hint system (reveal after 2 wrong attempts)
- Score tracking per lesson
- Progress indicator

**Navigation:**
- Smooth scroll to sections
- Lesson completion tracking (localStorage)
- Progress bar in header

### User Interactions
- Click lesson card → Open lesson content
- Read lesson → Scroll to quiz section
- Type answer in blank → Submit → Get feedback
- Complete lesson → Mark as done → Show next lesson

### Data Handling
- localStorage for progress tracking
- Quiz answers validated client-side
- No backend required

### Edge Cases
- Empty input on quiz → Show "Please enter an answer"
- Wrong answer → Show correct answer with explanation
- All questions correct → Show completion message

---

## 4. Acceptance Criteria

### Visual Checkpoints
- [ ] Black, white, ivory color scheme strictly followed
- [ ] Brutalist aesthetic with heavy borders and offset shadows
- [ ] Monospace fonts for headings and code
- [ ] Responsive layout works on all breakpoints
- [ ] Hover states invert colors properly

### Functional Checkpoints
- [ ] All 12 lessons are accessible
- [ ] Each lesson has 5+ fill-in-the-blank questions
- [ ] Quiz input accepts answers and provides feedback
- [ ] Progress is saved in localStorage
- [ ] Navigation works smoothly

### Content Checkpoints
- [ ] Each lesson covers its topic comprehensively
- [ ] FOSS/privacy theme is woven throughout
- [ ] Code examples are accurate and copyable
- [ ] Quiz questions test understanding of lesson content
