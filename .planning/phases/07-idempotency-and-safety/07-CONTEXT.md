# Phase 7: Idempotency and Safety - Context

**Gathered:** 2026-01-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the installer safe to re-run and protect user content from unintended destruction. Encompasses skip detection for completed steps, progress feedback during execution, confirmation prompts, and backup creation before destructive actions.

</domain>

<decisions>
## Implementation Decisions

### Skip Detection
- Use existing ~/.minervia/state.json for tracking completed steps (already has file checksums)
- When step was previously completed, show brief notice: "✓ Skills already installed"
- If state file is corrupted or outdated format, backup to .bak and recreate fresh

### Progress Feedback
- Primary style: Gum spinners when available
- Fallback (no Gum): Plain text with ASCII indicators like [OK] [FAIL] [SKIP]
- Always show final summary after installation (installed/skipped/failed counts)
- Default to minimal output (one line per major step)
- Add -v/--verbose flag for detailed sub-step output

### Confirmation Behavior
- Questionnaire summary always requires confirmation before proceeding
- File conflicts (existing CLAUDE.md, etc.) always prompt — no batch/remember option
- No unattended mode (no --yes flag) — installer requires human interaction
- On re-run with saved answers: show summary and offer edit option rather than re-running full questionnaire

### Destructive Action Handling
- "Destructive" = file overwrites AND deletions (not just adding new files)
- Always create backup before any overwrite
- Backup location: same directory as original file with .bak extension
- Warning communication: both color-coded warning text AND diff preview for file changes

### Claude's Discretion
- Whether to add --force flag for re-running completed steps (or rely on manual state file deletion)
- Exact spinner styles and timing
- Wording of confirmation prompts

</decisions>

<specifics>
## Specific Ideas

- Re-use existing conflict handling from Phase 6 (show_colored_diff, ask_choice)
- State file already tracks version and file checksums — extend rather than replace
- Questionnaire answers could be stored in state.json for re-run detection

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-idempotency-and-safety*
*Context gathered: 2026-01-18*
