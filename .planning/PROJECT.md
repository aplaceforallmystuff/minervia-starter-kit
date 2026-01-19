# Minervia Installer

## What This Is

A complete end-to-end installer that transforms Claude Code + Obsidian into a "co-operating system." Users run a single command, answer onboarding questions, and emerge with a fully configured PARA vault, personalized CLAUDE.md, and Minervia skills installed globally — ready to work, not ready to configure.

## Core Value

After running the installer, Claude actually understands your vault and you're immediately productive — not staring at a blank terminal wondering what to do.

## Current State (v1.0.0)

**Shipped:** 2026-01-19
**Codebase:** 2,797 lines bash (install.sh + minervia-update.sh), 93 files

### What v1.0 Delivers

- **Interactive onboarding** — 5-question questionnaire with Gum-enhanced UI
- **Personalized CLAUDE.md** — Template-based generation from user answers
- **PARA scaffolding** — Complete folder structure with templates and examples
- **Smart installation** — Checksum-based conflict detection, state.json tracking
- **Idempotent re-runs** — Step tracking, saved answers, verbose mode
- **Self-update system** — /minervia:update with customization preservation

## Requirements

### Validated (v1.0)

- ✓ Installer detects new vs existing vault and adapts — v1.0 (IS_NEW_VAULT flag)
- ✓ Full onboarding questionnaire captures user context — v1.0 (5 questions with Gum)
- ✓ PARA folder structure created for new vaults — v1.0 (7 folders)
- ✓ Templates created for daily notes, projects, areas — v1.0 (Obsidian core syntax)
- ✓ Example notes demonstrate how to use each PARA section — v1.0 (4 examples)
- ✓ CLAUDE.md generated from questionnaire answers — v1.0 (template system)
- ✓ Skills installed to ~/.claude/skills/ with version tracking — v1.0 (state.json)
- ✓ Customization detection prevents overwriting user changes — v1.0 (MD5 checksums)
- ✓ /minervia:update command pulls changes and merges carefully — v1.0 (3 strategies)
- ✓ Semantic versioning via git tags — v1.0

### Active (v1.1 Candidates)

- [ ] Guided first session walks through /log-to-daily, /vault-stats
- [ ] MCP server recommendations shown with links to docs
- [ ] Summary/review step shows what will be created before writing files
- [ ] Dry-run mode (--dry-run) previews changes without executing

### Out of Scope

- Automatic MCP server installation — adds complexity, users should control their integrations
- GUI installer — terminal is the feature, not a limitation
- Support for non-technical users — semi-technical is the floor
- Auto-updates without user action — users should control when they update
- Obsidian plugin format — Claude Code is the interface, not Obsidian plugins
- Windows support — macOS + Linux first

## Context

**Target user profile:**
Semi-technical users comfortable following terminal instructions but who don't want to troubleshoot. They've heard Claude Code is powerful but need hand-holding through setup.

**Packaging inspiration:**
get-shit-done repo — self-contained workflow system with update mechanisms and clear versioning.

**PARA methodology:**
- 00 Daily/ — Chronological record
- 01 Inbox/ — Quick capture
- 02 Projects/ — Active work with deadlines
- 03 Areas/ — Ongoing responsibilities
- 04 Resources/ — Reference materials
- 05 Archive/ — Completed/inactive items

## Constraints

- **Tech stack**: Bash for installer (portable), Markdown for skills/agents
- **Installation target**: ~/.claude/ for skills/agents, ~/.minervia/ for state, vault for CLAUDE.md
- **Versioning**: Git tags (v1.0.0 format) — no package.json needed
- **Compatibility**: macOS and Linux (no Windows support)
- **Dependencies**: Claude Code CLI must be installed first, Bash 4.0+

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Skills to ~/.claude/, not vault | Global installation simplifies updates, vault stays clean | ✓ Good — works well |
| State tracking in ~/.minervia/state.json | Enables idempotent re-runs and update tracking | ✓ Good — enables re-run and update |
| Preserve customizations on update | Users invest time tweaking skills to their workflow | ✓ Good — checksum comparison works |
| Template-based CLAUDE.md generation | Easier to maintain than heredoc, enables customization | ✓ Good — clean separation |
| Gum with fallback | Enhanced UX when available, basic prompts always work | ✓ Good — graceful degradation |
| Update script in ~/.minervia/bin/ | Self-contained, no PATH requirements | ✓ Good — portable |
| Git tags for versioning | Simple, no npm dependency, works with update command | ✓ Good — clean workflow |

---
*Last updated: 2026-01-19 after v1.0.0 milestone*
