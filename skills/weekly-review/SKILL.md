---
name: weekly-review
description: Weekly vault maintenance - process inbox, clean up daily notes, review project status. Keeps the system healthy.
use_when: User wants to run weekly review, process inbox, clean up the vault, or perform maintenance.
---

# Weekly Review

Weekly maintenance that keeps your vault healthy and your system working.

## Why This Matters

Without maintenance, entropy wins:
- Inbox items pile up, never processed
- Daily notes become inconsistent
- Projects drift without status updates
- The system stops being useful

With weekly review:
- Everything gets filed properly
- Daily notes stay searchable
- Projects stay on track
- The compound effect continues

## Configuration

Define your vault structure in CLAUDE.md:

```markdown
## Vault Structure

Layout: numbered-para  # Options: para, numbered-para, zettelkasten, johnny-decimal, custom

Folders:
  daily: 00 Daily/YYYY/          # Daily notes pattern
  inbox: 01 Inbox/               # Capture location
  projects: 02 Projects/         # Active projects
  areas: 03 Areas/               # Ongoing responsibilities
  resources: 04 Resources/       # Reference materials
  archive: 05 Archive/           # Completed/inactive

Areas:  # Your responsibility areas (customize)
  - Work
  - Personal
  - Learning
```

## Quick Start

1. Start the review, log to daily note
2. Process inbox items (tag, add frontmatter, file)
3. Clean up recent daily notes (fix frontmatter, add links)
4. Generate summary report

## Part A: Inbox Processing

### Process

For each file in inbox:

**Step 1: Analyze content**
- Read the file
- Understand purpose and topic

**Step 2: Determine destination**

| Signal | Destination |
|--------|-------------|
| Has deadline, specific outcome | Projects |
| Ongoing responsibility | Areas |
| Reference material | Resources |
| Completed, outdated | Archive |
| Early idea, not ready | Projects/_Incubation (or equivalent) |

**Step 3: Add frontmatter**

```yaml
---
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [appropriate, tags]
status: active | draft | complete
---
```

**Step 4: Move file**

Move to appropriate location based on vault structure.

**Step 5: Log action**

Record what was moved where.

## Part B: Daily Notes Cleanup

### Process

For each daily note from past 7 days:

**Step 1: Verify frontmatter**

Required:
```yaml
---
date: YYYY-MM-DDTHH:MM
tags: [Daily]
---
```

**Step 2: Fix issues**
- Add missing date field
- Add missing tags
- Correct any formatting issues

**Step 3: Add links**

Scan for mentions that could become wiki links:
- Project names → `[[Project Name]]`
- Tool references → `[[Tool]]` if doc exists
- Concept mentions → `[[Concept]]` if doc exists

**Only link to targets that exist in vault.**

**Step 4: Standardize structure**
- Ensure consistent section headers
- Add "Files Created" section if files were created

## Confirmation Protocol

Before making changes, show the plan:

```
Inbox Processing Plan:

1. Move "Product Spec.md"
   → 02 Projects/_Incubation/
   Tags: idea, product

2. Move "Research Notes.md"
   → 04 Resources/
   Tags: research, reference

Apply all? (Y/n/review each)
```

```
Daily Notes Cleanup Plan:

1. 20260101.md
   - Add frontmatter
   - Add link: [[Project Name]]

2. 20260102.md
   - Fix date format

Apply all? (Y/n/review each)
```

## Output Format

```markdown
## Weekly Review Summary

**Date:** [Today]
**Duration:** [X] minutes

### Inbox Processing

**Files Processed:** X
**Files Moved:** X

| File | Destination | Tags |
|------|-------------|------|
| [Name] | [Location] | [tags] |

### Daily Notes Cleanup

**Notes Scanned:** X
**Notes Updated:** X

| Date | Changes |
|------|---------|
| [Date] | [What changed] |

### Statistics

- Total files touched: X
- Links added: X
- Frontmatter fixes: X
```

## Workflow

```
1. Start review
   └── Log to daily note

2. Process Inbox
   ├── List all files
   ├── Classify each file
   ├── Propose destinations
   ├── Get confirmation
   └── Execute moves

3. Clean Daily Notes
   ├── List recent notes
   ├── Check frontmatter
   ├── Find link opportunities
   ├── Get confirmation
   └── Execute fixes

4. Complete
   ├── Generate summary
   └── Log to daily note
```

## Parameters

Optional modifiers:
- `inbox only` - Skip daily notes cleanup
- `daily notes only` - Skip inbox processing
- `dry run` - Preview without applying
- `this month` - Extend daily notes range

## Success Criteria

- [ ] All inbox items processed or explicitly deferred
- [ ] Recent daily notes have valid frontmatter
- [ ] Links added where appropriate
- [ ] Summary logged to daily note
- [ ] User confirmed all changes before execution
