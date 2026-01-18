# Phase 4: CLAUDE.md Generation - Context

**Gathered:** 2026-01-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Generate a personalized CLAUDE.md file from questionnaire answers. The file lives in the vault root and tells Claude Code about the user's context, focus, and preferences. This phase handles template processing and existing file detection — vault folder scaffolding is Phase 5.

</domain>

<decisions>
## Implementation Decisions

### Template structure
- External template file at `templates/CLAUDE.md.template` (not embedded heredoc)
- Include guidance comments like `<!-- Update when priorities change -->` to help users maintain the file
- Sections determined by Claude based on what provides most value to Claude Code

### Answer injection
- Placeholder syntax: Claude's discretion (pick most robust for bash)
- Empty/skipped answers: Claude's discretion (helpful defaults vs removal)
- Multi-select formatting: Claude's discretion (bullets vs commas based on context)
- Validation: Claude's discretion (balance UX vs data quality)

### Existing vault handling
- Show diff first when CLAUDE.md already exists, then prompt for action
- Post-diff options: Claude's discretion (likely Overwrite / Backup + Overwrite / Keep)
- Backup naming: timestamped format (e.g., `CLAUDE.md.backup-20260118-1530`)
- No --force flag — always prompt, never silent overwrites

### New vs existing detection
- Primary signal: folder emptiness (empty directory = new vault)
- Hidden files (.git, .obsidian): Claude's discretion on whether to count
- Flag storage for later phases: Claude's discretion on whether to persist IS_NEW_VAULT
- User feedback: always tell user what was detected ("Detected: new vault" or "Detected: existing vault with X files")

### Claude's Discretion
- Template sections and content structure
- Placeholder syntax choice
- Empty value handling strategy
- Multi-select formatting approach
- Validation strictness
- Post-diff menu options
- Hidden file treatment in detection
- Whether to persist IS_NEW_VAULT flag for Phase 5

</decisions>

<specifics>
## Specific Ideas

- Backups should be timestamped to preserve history (not overwrite previous backups)
- User explicitly wants visibility into detection: show "new vault" or "existing vault" status
- No silent operations — diff before overwrite, no --force flag
- Template file should be easy to preview and version in the repo

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-claudemd-generation*
*Context gathered: 2026-01-18*
