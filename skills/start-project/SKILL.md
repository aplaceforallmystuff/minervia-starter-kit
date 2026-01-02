---
name: start-project
description: Create a new project with proper PARA structure. Ensures consistent project setup with completion criteria and status tracking.
use_when: User wants to start a new project, create a project folder, or set up project structure.
---

# Start Project

Create new projects with standardized structure, clear completion criteria, and proper PARA organization.

## Why This Matters

Projects without structure become zombies—never quite done, never quite abandoned. With proper setup:
- Every project has clear "done" criteria
- Status is trackable via frontmatter
- Other skills (log-to-project, weekly-review) work correctly
- Nothing falls through the cracks

## Configuration

Add to your CLAUDE.md:

```markdown
## Vault Configuration
Projects location: 02 Projects/
Incubation folder: 02 Projects/_Incubation/

## Project Areas (customize for your work)
Areas:
  - work: Work projects
  - personal: Personal projects
  - learning: Learning/skill projects
```

## Project Types

| Type | Description | Default Subfolders |
|------|-------------|-------------------|
| `general` | Standard project | None |
| `software` | Code/development | Sessions/, Decisions/ |
| `content` | Writing/creation | Drafts/, Research/ |
| `learning` | Skill acquisition | Resources/, Notes/ |

## Quick Start

1. Get project name and type
2. Ask for completion criteria (what defines "done"?)
3. Create project folder with PROJECT.md
4. Create type-specific subfolders
5. Confirm creation

## PROJECT.md Template

This is the canonical project file. Every project must have this.

```markdown
---
project: "[PROJECT_NAME]"
type: "[TYPE]"
status: "planning"
priority: "medium"
area: "[AREA]"
start_date: "[TODAY]"
target_completion: "[DEADLINE_OR_EMPTY]"
tags:
  - project
created: "[TODAY]"
updated: "[TODAY]"
---

# [PROJECT_NAME]

## Overview

**Goal:** [One sentence goal]

**Why this matters:** [Brief context]

## Completion Criteria

What defines "done" for this project:

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Status

| Field | Value |
|-------|-------|
| Status | planning |
| Priority | medium |
| Started | [TODAY] |
| Target | [DEADLINE] |
| Progress | 0% |

## Next Actions

- [ ] First action

## Progress Log

### [TODAY]
- Project created

---

## Reference

**Status values:** planning, active, on-hold, blocked, review, completed
**Priority values:** critical, high, medium, low
```

## Process

**Step 1: Gather Information**

Ask the user:
1. **Project name** - What should this be called?
2. **Type** - general, software, content, learning
3. **Area** - Which area of work? (user-defined)
4. **Priority** - critical, high, medium, low
5. **Target completion** - Specific date or leave blank
6. **One-sentence goal** - What's the outcome?
7. **Completion criteria** - What defines "done"? (minimum 2-3 items)

**Step 2: Validate**

- Check if folder already exists
- Ensure completion criteria are defined (projects without "done" criteria become zombies)
- Validate status and priority values

**Step 3: Create Structure**

1. Create folder: `02 Projects/[Project Name]/`
2. Create PROJECT.md with template
3. Create subfolders based on type
4. For software projects, suggest creating CLAUDE.md

**Step 4: Confirm**

- Show what was created
- Remind user to fill in any placeholders
- Suggest next steps

## Validation Rules

1. **Project name** - Not empty, doesn't already exist
2. **Status** - Must be: planning, active, on-hold, blocked, review, completed
3. **Priority** - Must be: critical, high, medium, low
4. **Completion criteria** - At least one item (non-negotiable)

## Subfolders by Type

**Software projects:**
- `Sessions/` - Development session logs
- `Decisions/` - Architectural decision records

**Content projects:**
- `Drafts/` - Work in progress
- `Research/` - Background materials

**Learning projects:**
- `Resources/` - Learning materials
- `Notes/` - Study notes

## Tips

- If completion criteria are vague, help user think through what "done" looks like
- For software projects, link to code repo
- If deadline is "ASAP" or vague, push for specific date or "no deadline"
- Projects without clear completion criteria tend to linger—enforce this

## Success Criteria

- [ ] Project folder exists
- [ ] PROJECT.md has valid frontmatter
- [ ] All frontmatter fields populated (no placeholders)
- [ ] At least one completion criterion defined
- [ ] Appropriate subfolders created
- [ ] User shown the created structure
