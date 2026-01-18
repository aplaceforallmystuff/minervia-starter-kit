# Roadmap: Minervia Installer

## Overview

This roadmap transforms the existing Minervia starter kit into a complete end-to-end installer. The journey progresses from foundational error handling and CLI conventions through the core value proposition (questionnaire-driven CLAUDE.md generation), vault scaffolding, skills installation, and finally a self-update mechanism. Each phase delivers a coherent, testable capability that builds toward the goal: after running the installer, Claude understands your vault and you're immediately productive.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Error handling, strict mode, platform detection
- [ ] **Phase 2: CLI Interface** - Help, version, prerequisites checking
- [ ] **Phase 3: Questionnaire Engine** - Interactive prompts for user context
- [ ] **Phase 4: CLAUDE.md Generation** - Template system and personalization
- [ ] **Phase 5: Vault Scaffolding** - PARA structure, templates, examples
- [ ] **Phase 6: Skills Installation** - Copy skills/agents with version tracking
- [ ] **Phase 7: Idempotency and Safety** - Safe re-runs, confirmations, progress
- [ ] **Phase 8: Update System** - Self-update with customization preservation

## Phase Details

### Phase 1: Foundation
**Goal**: Installer has reliable error handling and platform detection that prevents silent failures
**Depends on**: Nothing (first phase)
**Requirements**: CORE-03, CORE-07
**Success Criteria** (what must be TRUE):
  1. Installer exits with non-zero code when any operation fails
  2. Error messages are human-readable with actionable recovery steps (not stack traces or cryptic codes)
  3. Platform differences (macOS BSD vs Linux GNU) are detected and handled
  4. Script uses strict mode (set -euo pipefail) with proper trap handlers
**Plans**: 1 plan

Plans:
- [x] 01-01-PLAN.md — Strict mode, trap handlers, platform detection, error handling infrastructure

### Phase 2: CLI Interface
**Goal**: Installer follows CLI conventions and validates environment before proceeding
**Depends on**: Phase 1
**Requirements**: CORE-01, CORE-04, CORE-09, CORE-10
**Success Criteria** (what must be TRUE):
  1. User can run `install.sh --help` and see usage, flags, and examples
  2. User can run `install.sh --version` and see current version number
  3. Installer checks for Claude Code CLI and fails with clear instructions if missing
  4. Installer checks Bash version and write permissions before proceeding
  5. Help output documents uninstall process
**Plans**: 2 plans

Plans:
- [ ] 02-01-PLAN.md — Add VERSION constant, --help and --version flags with argument parsing
- [ ] 02-02-PLAN.md — Refactor prerequisite checks (Bash version, Claude CLI, write permissions)

### Phase 3: Questionnaire Engine
**Goal**: Installer captures user context through interactive prompts
**Depends on**: Phase 2
**Requirements**: ONBD-01, ONBD-02
**Success Criteria** (what must be TRUE):
  1. User is presented with interactive questionnaire during installation
  2. Questionnaire captures name, vault location, role/business, key areas, and working preferences
  3. Prompts use Gum if available, fall back to read -p gracefully
  4. User can see progress through questionnaire (e.g., "Question 3 of 5")
**Plans**: TBD

Plans:
- [ ] 03-01: TBD

### Phase 4: CLAUDE.md Generation
**Goal**: Installer generates personalized CLAUDE.md from questionnaire answers
**Depends on**: Phase 3
**Requirements**: ONBD-03, ONBD-04, ONBD-05
**Success Criteria** (what must be TRUE):
  1. CLAUDE.md is generated in vault root with user's answers populated
  2. Installer correctly detects new vs existing vault
  3. For existing vaults, installer preserves existing CLAUDE.md (prompts before overwrite)
  4. Generated CLAUDE.md includes vault overview, current focus, working preferences, and key contexts
**Plans**: TBD

Plans:
- [ ] 04-01: TBD

### Phase 5: Vault Scaffolding
**Goal**: New vaults have complete PARA structure with templates and examples
**Depends on**: Phase 4
**Requirements**: VAULT-01, VAULT-02, VAULT-03, VAULT-04
**Success Criteria** (what must be TRUE):
  1. For new vaults, PARA folder structure is created (00 Daily, 01 Inbox, 02 Projects, 03 Areas, 04 Resources, 05 Archive)
  2. Templates exist for daily notes, projects, and areas with proper YAML frontmatter
  3. Example notes demonstrate how to use each PARA section
  4. For existing vaults, no folders or files are created (structure preserved)
**Plans**: TBD

Plans:
- [ ] 05-01: TBD

### Phase 6: Skills Installation
**Goal**: Skills and agents are installed globally with version tracking
**Depends on**: Phase 5
**Requirements**: SKIL-01, SKIL-02, SKIL-03, SKIL-04
**Success Criteria** (what must be TRUE):
  1. Skills are copied to ~/.claude/skills/ directory
  2. Agents are copied to ~/.claude/agents/ directory
  3. Installed version is recorded in ~/.minervia/state.json
  4. File manifest with checksums is recorded for update tracking
**Plans**: TBD

Plans:
- [ ] 06-01: TBD

### Phase 7: Idempotency and Safety
**Goal**: Installer is safe to re-run and never destroys user content without confirmation
**Depends on**: Phase 6
**Requirements**: CORE-02, CORE-05, CORE-06, CORE-08
**Success Criteria** (what must be TRUE):
  1. Re-running installer skips already-completed steps without errors or duplicates
  2. Progress indication shows status for each step (spinner or status messages)
  3. User content is never deleted without explicit confirmation
  4. Destructive actions prompt for confirmation before proceeding
**Plans**: TBD

Plans:
- [ ] 07-01: TBD

### Phase 8: Update System
**Goal**: Users can update Minervia while preserving their customizations
**Depends on**: Phase 7
**Requirements**: UPDT-01, UPDT-02, UPDT-03, UPDT-04, UPDT-05, UPDT-06
**Success Criteria** (what must be TRUE):
  1. /minervia:update command fetches latest version from git
  2. Update detects which files user has customized via checksum comparison
  3. User-customized files are preserved; only unchanged files are updated
  4. User can choose merge strategy for customized files (keep mine, take theirs, backup + overwrite)
  5. Backup is created before any files are modified
  6. Update reports what changed after completion
**Plans**: TBD

Plans:
- [ ] 08-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 1/1 | Complete | 2026-01-18 |
| 2. CLI Interface | 0/2 | Not started | - |
| 3. Questionnaire Engine | 0/? | Not started | - |
| 4. CLAUDE.md Generation | 0/? | Not started | - |
| 5. Vault Scaffolding | 0/? | Not started | - |
| 6. Skills Installation | 0/? | Not started | - |
| 7. Idempotency and Safety | 0/? | Not started | - |
| 8. Update System | 0/? | Not started | - |

---
*Roadmap created: 2026-01-18*
*Depth: Comprehensive (8 phases)*
*Coverage: 29/29 v1 requirements mapped*
