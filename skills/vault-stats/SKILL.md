---
description: Show vault statistics - note counts by PARA location, recent activity, inbox status
user-invocable: true
---

# Vault Statistics

Quick visibility into your vault's health and activity.

## What to Show

### Note Counts by PARA Location

Count markdown files in each location:
- **Inbox** (00 Daily/ or 01 Inbox/)
- **Projects** (01 Projects/ or 02 Projects/)
- **Areas** (02 Areas/ or 03 Areas/)
- **Resources** (03 Resources/ or 04 Resources/)
- **Archive** (04 Archive/ or 05 Archive/)

Handle both numbering conventions (00-04 or 01-05 prefixes).

### Recent Activity

Show files modified in the last 7 days:
- Count of recently modified notes
- List up to 5 most recent

### Inbox Health

- Current inbox count
- Flag if inbox > 20 items (needs processing)

### Daily Notes

- Count of daily notes this month
- Streak: consecutive days with notes

## Output Format

```
📊 Vault Statistics
═══════════════════════════════════════

📁 Notes by Location
───────────────────────────────────────
  Inbox:      12 items ⚠️ (needs processing)
  Projects:   34 notes
  Areas:      89 notes
  Resources:  156 notes
  Archive:    203 notes
  ─────────────────────
  Total:      494 notes

📅 Daily Notes
───────────────────────────────────────
  This month: 8 notes
  Streak:     3 days

🔄 Recent Activity (7 days)
───────────────────────────────────────
  Modified:   23 notes

  Most recent:
  - Project Planning.md
  - Weekly Review 2026-01-12.md
  - Client Notes - Acme.md
  - Newsletter Draft.md
  - Meeting Notes.md

═══════════════════════════════════════
```

## Implementation

Use Bash to count files efficiently:

```bash
# Count notes in a directory
find "01 Inbox" -name "*.md" 2>/dev/null | wc -l

# Recent files
find . -name "*.md" -mtime -7 -type f 2>/dev/null | wc -l

# Most recent 5
find . -name "*.md" -mtime -7 -type f -exec ls -t {} + 2>/dev/null | head -5
```

## When to Use

- Start of day: Quick vault health check
- Before weekly review: See what needs attention
- After organizing: Verify inbox is processed
- Monthly: Track vault growth
