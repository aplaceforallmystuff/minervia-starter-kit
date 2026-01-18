---
phase: 08-update-system
plan: 02
subsystem: update
tags: [bash, checksum, merge, backup, restore]

# Dependency graph
requires:
  - phase: 08-01
    provides: minervia-update.sh core infrastructure (version compare, backup, fetch)
provides:
  - Customization detection via MD5 checksum comparison
  - Three-way merge strategy selection (keep mine, take theirs, backup + overwrite)
  - Changelog highlights extraction between versions
  - Backup listing with file counts
  - Restore functionality with confirmation
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Checksum comparison for change detection (current vs manifest)"
    - "Colored diff output for conflict visualization"
    - "File array tracking (CUSTOMIZED_FILES, PRISTINE_FILES, NEW_FILES)"
    - "Backup restoration with path resolution"

key-files:
  created: []
  modified:
    - minervia-update.sh

key-decisions:
  - "Conflict preview: Show all conflicts upfront before prompting for resolution"
  - "Merge options: Three choices mirror install.sh pattern (keep/backup+replace/replace)"
  - "Changelog parsing: AWK extraction between version headers for highlights"
  - "Restore confirmation: Require explicit y/N before restoring files"

patterns-established:
  - "ask_choice helper for Gum-with-fallback selection (mirrors install.sh)"
  - "Inline backup on conflict: filename.backup-YYYYMMDD-HHMMSS format"
  - "Version update in state.json after successful update completion"

# Metrics
duration: 5min
completed: 2026-01-18
---

# Phase 8 Plan 02: Update Conflict Detection and Restore Summary

**Checksum-based customization detection with three-way merge strategies and backup restore functionality**

## Performance

- **Duration:** 5 min
- **Started:** 2026-01-18T22:48:00Z
- **Completed:** 2026-01-18T22:53:00Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments
- Implemented customization detection by comparing current file MD5 with manifest-stored checksum
- Added three merge strategies for customized files with colored diff preview
- Built changelog extraction between installed and remote versions
- Completed backup listing with file counts and restore with confirmation

## Task Commits

All tasks were implemented together as cohesive update functionality:

1. **Task 1-3: Complete update system** - `5296d4e` (feat)
   - Customization detection (is_file_customized, scan_for_customizations)
   - Merge strategies (handle_customized_file, handle_customized_files)
   - Changelog highlights (show_changelog_highlights)
   - Update application (apply_updates, update_state_version)
   - Backup management (list_backups, restore_backup)

**Plan metadata:** (to be committed)

## Files Created/Modified
- `minervia-update.sh` - Complete update system with conflict detection and restore (+387 lines)
  - `is_file_customized()` - Compare current MD5 to manifest stored MD5
  - `scan_for_customizations()` - Populate CUSTOMIZED/PRISTINE/NEW arrays
  - `handle_customized_file()` - Single file conflict with diff and choice
  - `handle_customized_files()` - Orchestrate all conflicts
  - `show_changelog_highlights()` - Extract changelog between versions
  - `apply_updates()` - Copy pristine and new files
  - `update_state_version()` - Update version in state.json
  - `list_backups()` - Show available backups with counts
  - `restore_backup()` - Restore files with confirmation

## Decisions Made

1. **Conflict preview first**: Before prompting for individual conflict resolution, list all conflicting files upfront so user knows scope

2. **Three merge options**: Consistent with install.sh pattern - "Keep mine (skip update)", "Take theirs (overwrite)", "Backup + overwrite"

3. **Inline backup naming**: Uses `filename.backup-YYYYMMDD-HHMMSS` format for per-file backups during conflict resolution (separate from pre-update backup directory)

4. **Restore confirmation**: Requires explicit y/N confirmation before restoring to prevent accidental overwrites

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - implementation followed plan specifications.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Update System Complete:**
- Full update workflow: fetch -> version compare -> backup -> detect customizations -> resolve conflicts -> apply updates -> update state
- Backup and restore functionality operational
- All Phase 8 plans complete

**Project Complete:**
- All 8 phases implemented
- 15 plans executed successfully
- Minervia installer ready for use

---
*Phase: 08-update-system*
*Completed: 2026-01-18*
