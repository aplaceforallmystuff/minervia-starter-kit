---
phase: 08-update-system
plan: 01
subsystem: update
tags: [bash, git, backup, version-comparison]

# Dependency graph
requires:
  - phase: 07-idempotency-and-safety
    provides: state.json manifest with file checksums
provides:
  - minervia-update.sh core infrastructure
  - Version comparison (installed vs remote)
  - Backup creation with path resolution
  - Dry-run preview mode
  - CLI argument parsing (--help, --dry-run, --verbose, --list-backups, --restore)
affects: [08-02 (customization detection and update application)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Git shallow clone for version fetch (--depth 1)"
    - "Cross-platform sort -V with numeric fallback"
    - "Timestamped backup directories (YYYY-MM-DDThh-mm-ss)"
    - "Path resolution for skills/agents vs vault files"

key-files:
  created:
    - minervia-update.sh
  modified: []

key-decisions:
  - "Standalone script vs --update flag: Created separate minervia-update.sh for cleaner testing"
  - "Version detection: Check sort -V capability directly rather than checking for GNU"
  - "Backup location: ~/.minervia/backups/ with timestamped directories"
  - "Path resolution: skills/* and agents/* map to ~/.claude/, other paths use vault_path from state"

patterns-established:
  - "Update script mirrors install.sh patterns (colors, error_exit, verbose helper)"
  - "Stub functions for Plan 02 implementation (scan_for_customizations, apply_updates)"
  - "Network error handling with friendly recovery suggestions"

# Metrics
duration: 13min
completed: 2026-01-18
---

# Phase 8 Plan 01: Update Core Infrastructure Summary

**Self-update script with git fetch, version comparison, timestamped backups, and dry-run preview mode**

## Performance

- **Duration:** 13 min
- **Started:** 2026-01-18T22:19:42Z
- **Completed:** 2026-01-18T22:33:29Z
- **Tasks:** 3
- **Files modified:** 1 (created)

## Accomplishments
- Created minervia-update.sh with full CLI interface (--help, --dry-run, --verbose, --list-backups, --restore)
- Implemented version comparison using sort -V with numeric fallback for cross-platform compatibility
- Built backup system that preserves directory structure and reads from state.json manifest
- Established update flow skeleton with stubs ready for Plan 02 implementation

## Task Commits

Each task was committed atomically:

1. **Task 1-3: Create core infrastructure** - `dfee6f7` (feat)
   - All three tasks were implemented together as they form a cohesive unit
   - Argument parsing, version functions, backup creation, and main flow

**Plan metadata:** (to be committed)

## Files Created/Modified
- `minervia-update.sh` - Self-update utility script (432 lines)
  - Argument parsing with --dry-run, --verbose, --list-backups, --restore, --help
  - Version functions: get_installed_version, get_remote_version, is_newer_version
  - Fetch mechanism: fetch_latest with git clone --depth 1
  - Backup: create_backup, resolve_path, list_backups
  - Helpers: verbose, compute_md5, error_exit, cleanup trap
  - Stubs: scan_for_customizations, handle_customized_files, apply_updates, show_changelog_highlights, restore_backup

## Decisions Made

1. **Standalone script pattern**: Created minervia-update.sh rather than adding --update to install.sh for cleaner separation and easier testing

2. **Cross-platform version comparison**: Instead of checking for GNU sort, we test if `sort -V` works by comparing known versions. Falls back to numeric comparison for x.y.z versions

3. **Backup structure**: Backups preserve the relative path structure from state.json manifest (e.g., skills/log-to-daily/SKILL.md stays as skills/log-to-daily/SKILL.md in backup)

4. **Path resolution strategy**: skills/* and agents/* paths are resolved to ~/.claude/, while other paths use vault_path from state.json questionnaire_answers

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

1. **Cleanup trap exit code**: Initial implementation had cleanup function returning non-zero when TEMP_DIR was empty due to `[[ ... ]] && ...` pattern. Fixed by adding explicit `return 0`

2. **GNU sort detection**: Original approach checked for "GNU" in sort --version output, but macOS sort supports -V without being GNU. Changed to functional test instead

3. **Network timeout during testing**: Git clone operations took longer than expected during verification. The script handles network failures gracefully with helpful error messages

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Ready for Plan 02:**
- Stub functions in place for customization detection and update application
- State.json manifest provides file checksums for change detection
- Backup infrastructure ready to use before applying updates
- show_colored_diff and ask_choice patterns available in install.sh for reference

**Blockers/Concerns:**
- Remote repository (GitHub) has older install.sh without VERSION constant - will need to push updates for version comparison to work properly

---
*Phase: 08-update-system*
*Completed: 2026-01-18*
