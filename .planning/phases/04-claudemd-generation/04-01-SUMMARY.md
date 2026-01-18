---
phase: 04-claudemd-generation
plan: 01
subsystem: installer
tags: [bash, template, sed, awk]

# Dependency graph
requires:
  - phase: 03-questionnaire-engine
    provides: ANSWERS array with user input
provides:
  - CLAUDE.md template file with {{PLACEHOLDER}} syntax
  - detect_vault_type() function for new vs existing vault detection
  - escape_for_sed() function for safe user input handling
  - format_as_bullets() function for multi-value formatting
  - process_template() function for placeholder substitution
affects: [04-02-claudemd-generation, 05-folder-scaffolding]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "{{PLACEHOLDER}} syntax for bash templates"
    - "sed with # delimiter to avoid path conflicts"
    - "awk for multi-line placeholder substitution"
    - "nullglob for safe directory content checking"

key-files:
  created:
    - templates/CLAUDE.md.template
  modified:
    - install.sh

key-decisions:
  - "Use {{PLACEHOLDER}} syntax - avoids conflicts with shell, markdown, YAML, Obsidian"
  - "Template focuses on personal context, not Minervia documentation"
  - "Hidden files (.git, .obsidian) excluded from empty vault check"
  - "Export IS_NEW_VAULT for potential Phase 5 use"
  - "Default preferences provided when user skips question"

patterns-established:
  - "escape_for_sed pattern for user input sanitization"
  - "format_as_bullets pattern for multi-select values"
  - "Template + process_template separation for maintainability"

# Metrics
duration: 3min
completed: 2026-01-18
---

# Phase 4 Plan 1: Template System Infrastructure Summary

**CLAUDE.md template with {{PLACEHOLDER}} syntax and four processing functions (detect_vault_type, escape_for_sed, format_as_bullets, process_template)**

## Performance

- **Duration:** 3 min
- **Started:** 2026-01-18T15:30:00Z
- **Completed:** 2026-01-18T15:33:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created CLAUDE.md template file (80 lines) with 5 placeholders for personalization
- Added vault detection to distinguish new vs existing vaults based on non-hidden file count
- Implemented safe sed substitution with character escaping to prevent injection
- Built multi-value formatting to convert comma-separated answers to markdown bullets
- Established TEMPLATE_DIR variable for template location resolution

## Task Commits

Each task was committed atomically:

1. **Task 1: Create CLAUDE.md template file** - `9fb918a` (feat)
2. **Task 2: Add vault detection and template processing functions** - `b650894` (feat)

## Files Created/Modified
- `templates/CLAUDE.md.template` - Template file with {{NAME}}, {{ROLE}}, {{AREAS}}, {{PREFERENCES}}, {{DATE}} placeholders
- `install.sh` - Added 4 functions (detect_vault_type, escape_for_sed, format_as_bullets, process_template) and TEMPLATE_DIR variable

## Decisions Made
- **{{PLACEHOLDER}} syntax:** Chosen over $VAR or %VAR% to avoid conflicts with shell variables, markdown, YAML frontmatter, and Obsidian syntax
- **Template content focus:** Personal context (name, role, areas, preferences) rather than Minervia documentation - Claude Code works better with concise, personalized CLAUDE.md files
- **Hidden file exclusion:** .git and .obsidian not counted in "empty vault" detection - these are infrastructure, not user content
- **sed # delimiter:** Prevents breakage when user values contain / characters
- **Default preferences:** Sensible defaults provided (concise communication, PARA locations, wiki links) when user skips the preferences question

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Template and processing functions ready for 04-02 (CLAUDE.md generation)
- detect_vault_type available for Phase 5 (folder scaffolding) via IS_NEW_VAULT export
- process_template ready to be called from main installation flow

---
*Phase: 04-claudemd-generation*
*Completed: 2026-01-18*
