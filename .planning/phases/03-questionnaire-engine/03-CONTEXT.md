# Phase 3: Questionnaire Engine - Context

**Gathered:** 2026-01-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Interactive CLI questionnaire that captures user context during installation. Collects name, vault location, role/business, key areas, and working preferences. Uses Gum when available, falls back to basic prompts. This phase handles the prompting and answer collection — CLAUDE.md generation is Phase 4.

</domain>

<decisions>
## Implementation Decisions

### Question Flow
- Questions have **conditional logic** — later questions adapt based on earlier answers
- Vault path is **always manual** — user types/pastes the full path (no auto-detection)
- Role/business input: **Claude's discretion** — free text or options+other, whichever works best
- Key areas and working preferences use **multi-select** — user picks multiple items from lists

### Input Validation
- **Required fields:** name, vault path, role (installer won't proceed without these)
- Vault path validation: **Claude's discretion** — determine safest approach for exists vs create
- Invalid input behavior: **re-prompt with hint** — show error message plus helpful example, then ask again
- Retry limits: **Claude's discretion** — pick appropriate limit based on UX best practices

### Progress Experience
- Progress indicator style: **Claude's discretion** — step counter, bar, or sections based on what works with Gum/fallback
- Back navigation: **Claude's discretion** — based on implementation complexity
- End confirmation: **summary + edit option** — show all answers with option to edit specific ones before proceeding
- Skip questionnaire: **Claude's discretion** — determine if --no-questionnaire or similar makes sense

### Fallback Behavior
- Fallback experience level: **minimal viable** — basic read -p prompts are acceptable when Gum isn't available
- Gum installation: **offer to install** — prompt user "Gum not found. Install for better experience? (y/n)"
- Multi-select fallback: **comma-separated input** — user types "content, consulting, research"
- Non-interactive detection: **detect and use flags** — allow all answers via command-line flags for CI/automation use

### Claude's Discretion
- Role/business prompt format (free text vs options)
- Vault path validation approach (exists check vs offer create)
- Retry limit for invalid input
- Progress indicator implementation
- Back navigation support
- Whether questionnaire can be skipped

</decisions>

<specifics>
## Specific Ideas

- End-of-questionnaire summary should allow editing specific answers — not just "looks good?" confirmation
- Non-interactive mode via flags enables CI/automated testing
- Gum install offer is friendly but not pushy — user can decline and proceed with basic prompts

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-questionnaire-engine*
*Context gathered: 2026-01-18*
