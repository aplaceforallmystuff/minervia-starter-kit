# Phase 8: Update System - Context

**Gathered:** 2026-01-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can update Minervia while preserving their customizations. The `/minervia:update` skill fetches the latest version, detects user-modified files via checksum comparison, preserves customizations, and reports what changed. A `/minervia:restore` command allows restoring from backups.

</domain>

<decisions>
## Implementation Decisions

### Conflict Resolution UX
- Side-by-side diff display for conflicts (show local vs upstream changes with colors)
- Three merge strategy choices: Keep mine / Take theirs / Backup + overwrite
- Preview all conflicts first (list all, then resolve each)
- Plain text prompts fallback when Gum unavailable (show diff with cat, use read -p)

### Update Invocation
- Invoked via skill command: `/minervia:update`
- `--dry-run` shows summary only ("5 files to update, 2 conflicts")
- Verbosity matches installer behavior (VERBOSE flag from Phase 7)
- Fetch via git clone/pull to temp directory, then compare files

### Backup Strategy
- Backups stored in `~/.minervia/backups/`
- Timestamped folders: `backups/2026-01-18T22-55-00/` preserving original structure
- Keep all backups (no auto-pruning)
- Dedicated `/minervia:restore` command to list and restore from backups

### Change Reporting
- Summary shows counts only: "Updated 5 files, kept 2 customized, backed up 2"
- Version display: before and after ("Updated from v1.2.0 to v1.3.0")
- Show brief "What's new in v1.3.0" highlights inline after update
- Verbose mode (-v) shows full file list with action taken

### Claude's Discretion
- Temp directory management for git clone
- Checksum algorithm choice for file comparison
- Changelog format and highlight extraction
- Restore command interaction flow

</decisions>

<specifics>
## Specific Ideas

- Conflict resolution should feel deliberate—preview all conflicts first so user knows the scope before making decisions
- Keep backups forever—disk is cheap, user trust is expensive
- Changelog highlights should be brief (2-3 bullets max), not the full changelog

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-update-system*
*Context gathered: 2026-01-18*
