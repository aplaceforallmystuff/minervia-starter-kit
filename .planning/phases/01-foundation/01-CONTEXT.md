# Phase 1: Foundation - Context

**Gathered:** 2026-01-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Reliable error handling and platform detection that prevents silent failures. This phase establishes the foundation that all subsequent phases build on: strict mode, trap handlers, error messaging, and cross-platform compatibility.

</domain>

<decisions>
## Implementation Decisions

### Error handling approach
- Use `set -euo pipefail` strict mode throughout
- Trap handlers for cleanup on exit (normal and error)
- Exit codes follow standard conventions (0 = success, non-zero = failure)

### Error message style
- Human-readable messages, not stack traces or cryptic codes
- Include actionable recovery steps ("Try running with sudo" not just "Permission denied")
- Consistent format across all error types

### Platform detection
- Detect macOS (BSD) vs Linux (GNU) differences at startup
- Handle differences silently where possible (adapter pattern)
- Fail clearly if running on unsupported platform

### Claude's Discretion
- Specific error message wording and formatting
- Which platform differences need handling (discover during implementation)
- Trap handler implementation details
- Color/formatting choices for terminal output

</decisions>

<specifics>
## Specific Ideas

No specific requirements — roadmap success criteria are sufficiently detailed for this infrastructure phase.

</specifics>

<deferred>
## Deferred Ideas

None — discussion confirmed phase scope is clear.

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-01-18*
