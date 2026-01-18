# Minervia Installer

## What This Is

A complete end-to-end installer that transforms Claude Code + Obsidian into a "co-operating system." Users run a single command, answer onboarding questions, and emerge with a fully configured PARA vault, personalized CLAUDE.md, and Minervia skills installed globally — ready to work, not ready to configure.

## Core Value

After running the installer, Claude actually understands your vault and you're immediately productive — not staring at a blank terminal wondering what to do.

## Requirements

### Validated

*Inferred from existing codebase:*

- Skills exist for log-to-daily, weekly-review, think-first, start-project, log-to-project, lessons-learned — existing
- Agents exist for workflow-coordinator, vault-analyst, aesthetic-definer — existing
- Basic install.sh copies skills to ~/.claude/skills/ — existing
- CLAUDE.md template provides vault context — existing
- /init command detects vault structure — existing
- First-run experience via SessionStart hook — existing

### Active

- [ ] Installer detects new vs existing vault and adapts
- [ ] Full onboarding questionnaire captures user context
- [ ] PARA folder structure created for new vaults
- [ ] Templates created for daily notes, projects, areas, resources
- [ ] Example notes demonstrate how to use each PARA section
- [ ] CLAUDE.md generated from questionnaire answers
- [ ] Skills installed to ~/.claude/skills/ with version tracking
- [ ] Customization detection prevents overwriting user changes
- [ ] /minervia:update command pulls changes and merges carefully
- [ ] Guided first session walks through /log-to-daily, /weekly-review
- [ ] MCP server recommendations shown with links to docs
- [ ] Semantic versioning via git tags

### Out of Scope

- Automatic MCP server installation — adds complexity, users should control their integrations
- GUI installer — terminal is the feature, not a limitation
- Support for non-technical users — semi-technical is the floor
- Auto-updates without user action — users should control when they update
- Obsidian plugin format — Claude Code is the interface, not Obsidian plugins

## Context

**Existing codebase:**
- Configuration-driven skill system — Markdown files Claude reads at runtime
- Skills: log-to-daily, weekly-review, think-first, start-project, log-to-project, lessons-learned, vault-stats
- Agents: workflow-coordinator, vault-analyst, aesthetic-definer
- Basic install.sh exists but lacks questionnaire, version tracking, update support
- /init command exists for vault structure detection

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
- **Installation target**: ~/.claude/ for skills/agents, vault for CLAUDE.md and structure
- **Versioning**: Git tags (v1.0.0 format) — no package.json needed
- **Compatibility**: macOS and Linux (no Windows support for v1)
- **Dependencies**: Claude Code CLI must be installed first

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Skills to ~/.claude/, not vault | Global installation simplifies updates, vault stays clean | — Pending |
| Preserve customizations on update | Users invest time tweaking skills to their workflow | — Pending |
| Guided first session, not just "done" | Semi-technical users need confidence-building | — Pending |
| Recommend MCP, don't install | User controls their integrations, reduces failure modes | — Pending |
| Git tags for versioning | Simple, no npm dependency, works with update command | — Pending |

---
*Last updated: 2026-01-18 after initialization*
