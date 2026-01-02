---
name: log-to-project
description: Log work activity to a specific project folder. Maintains changelogs, session notes, and decision records for projects.
use_when: User asks to log activity to a project, update project documentation, capture session outcomes, or record changes to a project.
---

# Log to Project

Capture project-specific activity to the project folder, maintaining history and context for ongoing work.

## Why This Matters

Projects without documentation become black boxes. With project logging:
- You can resume work after weeks away
- Decisions have recorded rationale
- Progress is visible and trackable
- Future sessions have full context

## Configuration

Add to your CLAUDE.md:

```markdown
## Vault Configuration
Projects location: 02 Projects/
Code repositories: ~/Dev/
```

## Project Folder Structure

```
02 Projects/[Project Name]/
├── PROJECT.md                    # Canonical status file
├── CHANGELOG.md                  # Version history
├── Sessions/                     # Session logs
│   └── session-YYYYMMDD.md
└── Decisions/                    # Decision records
    └── decision-YYYYMMDD-topic.md
```

## Quick Start

1. Identify project(s) worked on
2. Find or create project folder in `02 Projects/`
3. Update CHANGELOG.md with changes
4. Create session log if substantial work
5. Create decision record if architectural choices made

## File Templates

### CHANGELOG.md

```markdown
# Changelog

All notable changes documented here.

## [Unreleased]

### Added
- New features

### Changed
- Modifications

### Fixed
- Bug fixes

### Removed
- Removed features

## [X.X.X] - YYYY-MM-DD

### Added
- Initial features
```

### Session Log (Sessions/session-YYYYMMDD.md)

```markdown
# [Project Name] - Session YYYY-MM-DD

## Summary
[Brief summary of what was accomplished]

## Changes Made

### [Category]
- Change 1
- Change 2

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| Decision 1 | Why |

## Next Steps
- [ ] Task 1
- [ ] Task 2
```

### Decision Record (Decisions/decision-YYYYMMDD-topic.md)

```markdown
# Decision: [Title]

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated

## Context
[What issue motivated this decision?]

## Decision
[What change are we making?]

## Consequences
[What becomes easier or harder?]

## Alternatives Considered
- Alternative 1: Why rejected
```

## Process

**Step 1: Identify the project**
- Match work to existing project in `02 Projects/`
- Or identify code repo in development folder
- If new project, use `/start-project` first

**Step 2: Ensure structure exists**
- Create `Sessions/` and `Decisions/` folders if needed
- Verify PROJECT.md exists

**Step 3: Analyze session content**

Identify:
- Features added or modified
- Bugs fixed
- Architectural decisions
- Configuration changes
- Files modified
- Next steps

**Step 4: Update CHANGELOG.md**
- Add entries under `[Unreleased]`
- Categorize as Added, Changed, Fixed, or Removed
- Be specific: "Add user authentication" not "Updates"

**Step 5: Create session log (for substantial work)**
- Create `Sessions/session-YYYYMMDD.md`
- Include summary, changes, decisions, next steps

**Step 6: Create decision record (for significant decisions)**
- Create `Decisions/decision-YYYYMMDD-topic.md`
- Document context, decision, and consequences

## Changelog Entry Guidelines

**Good entries:**
- "Add password reset flow with email verification"
- "Fix calculation error in monthly totals"
- "Change database from SQLite to PostgreSQL"

**Bad entries:**
- "Fixed stuff"
- "Updates"
- "Bug fix"

## Success Criteria

- [ ] Project folder exists
- [ ] PROJECT.md exists and is current
- [ ] CHANGELOG.md updated with session changes
- [ ] Session log created (if substantial work)
- [ ] Decision records created (if decisions made)
- [ ] Next steps documented
