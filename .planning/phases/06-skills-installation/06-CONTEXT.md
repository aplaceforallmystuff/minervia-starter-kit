# Phase 6: Skills Installation - Context

**Gathered:** 2026-01-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Install skills and agents to the user's global Claude Code configuration (`~/.claude/`) with version tracking. Record installed files and checksums in `~/.minervia/state.json` to support future updates. This phase does NOT implement the update mechanism itself (that's Phase 8).

</domain>

<decisions>
## Implementation Decisions

### Installation Target
- Direct installation to `~/.claude/skills/` and `~/.claude/agents/`
- Create directories automatically if they don't exist (mkdir -p)
- No vault-local fallback — global install only

### Source Structure
- Include starter skills for personal knowledge management:
  - vault-stats (vault statistics/overview)
  - weekly-review (weekly review workflow)
  - inbox-process (inbox triage helper)
  - daily-note helpers
- Claude decides folder organization within repo (skills/ vs assets/skills/ etc.)

### Conflict Handling
- Prompt user each time a file with the same name already exists
- Options: keep existing, overwrite, or backup + overwrite
- Skip unchanged files on re-run (compare MD5 checksums)

### Installation Sequence
- Skills and agents installed as separate steps (not bundled)
- Order: skills first, then agents

### File Validation
- Basic validation before copying: check file exists and isn't empty
- No syntax/parsing validation

### State Tracking
- Create `~/.minervia/state.json` with:
  - `version`: Semver format (e.g., "1.0.0")
  - `installed_at`: ISO timestamp
  - `files`: Array of installed files with paths and MD5 checksums
- MD5 chosen for speed and simplicity (not security-critical)

### Claude's Discretion
- Exact folder structure for skills/agents in the repo
- Progress display verbosity (per-file vs summary)
- Whether to track configured vault paths in state.json
- Specific starter skill implementations

</decisions>

<specifics>
## Specific Ideas

- Core PKM skills should help with common Obsidian workflows: viewing vault stats, running weekly reviews, processing inbox items, working with daily notes
- The state.json file needs to support the Phase 8 update system — checksums let us detect user modifications

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-skills-installation*
*Context gathered: 2026-01-18*
