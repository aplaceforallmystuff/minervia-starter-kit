---
name: log-to-daily
description: Capture conversation activity to today's daily note. Creates a continuous record of your work that Claude can reference in future sessions.
use_when: User asks to log activity, update the daily note, record what was done, or wants session work captured in the vault.
---

# Log to Daily

Capture session activity to your daily note, building a searchable record of your work over time.

## Why This Matters

Without logging, each Claude session is ephemeral. With logging:
- Future sessions can reference past work
- You have a complete record of decisions and progress
- Daily notes become genuinely useful for review

## Configuration

This skill requires your vault path. Add to your CLAUDE.md:

```markdown
## Vault Configuration
Obsidian vault path: /path/to/your/vault
Daily notes location: 00 Daily/YYYY/YYYYMMDD.md
```

## Quick Start

1. Determine today's date
2. Find or create daily note at `{vault}/00 Daily/YYYY/YYYYMMDD.md`
3. Summarize session activity
4. Append to daily note

## Daily Note Structure

```markdown
---
date: YYYY-MM-DDTHH:MM
tags: [Daily]
---
# DAILY NOTE
### *Weekday, Month DDth, YYYY*

## Journal
[Summary of activities]

---

## [Topic/Project Sections]
[Detailed notes organized by topic]

---

## Files Created Today
[Wiki links to any files created during this session]
```

## Process

**Step 1: Locate the daily note**
- Get current date from system
- Build path: `{vault}/00 Daily/YYYY/YYYYMMDD.md`
- If file doesn't exist, create with frontmatter

**Step 2: Analyze session for loggable content**

Identify:
- Decisions made
- Tasks completed or created
- Projects progressed
- Strategic insights
- Next steps identified
- Files created during this session

**Step 3: Structure the update**
- Add new sections for distinct topics
- Update existing sections if adding to prior content
- Include wiki links to related files
- Add "Files Created Today" section at the end

**Step 4: Append to daily note**
- Preserve all existing content
- Add new sections in logical order
- Use consistent markdown formatting

## Formatting Guidelines

**Section headers:** Use `## Section Name` for main topics

**Project sections:**
```markdown
## Project Name - Brief Description

**Key details in bold**
- Bullet points for details
- Use checkboxes for action items: `- [ ]`

**Status:** Current status
**Next steps:** What happens next
```

**Wiki links:**
- Reference files with: `[[File Name]]`
- Add brief description after link

**Files Created Today:**
```markdown
## Files Created Today

- [[New Document]] - Brief description
- [[Another File]] - What it contains
```

## Success Criteria

- [ ] Daily note exists at correct path
- [ ] Valid frontmatter with date and tags
- [ ] All significant session activity captured
- [ ] Content organized into logical sections
- [ ] Related files linked with wiki syntax
- [ ] "Files Created Today" section includes any new files
