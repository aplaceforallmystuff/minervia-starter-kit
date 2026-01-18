# Requirements: Minervia Installer

**Defined:** 2026-01-18
**Core Value:** After running installer, Claude understands your vault and you're immediately productive

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Core Installation

- [ ] **CORE-01**: Installer checks prerequisites before proceeding (Claude Code CLI, Bash version, write permissions)
- [ ] **CORE-02**: Installer displays progress indication for each step (spinner or status messages)
- [ ] **CORE-03**: Errors are human-readable with actionable recovery steps (not stack traces)
- [ ] **CORE-04**: Installer supports --help flag showing usage, flags, and examples
- [ ] **CORE-05**: Installer is idempotent (safe to re-run, skips what's already done)
- [ ] **CORE-06**: Installer never deletes user content without explicit confirmation
- [ ] **CORE-07**: Installer uses proper exit codes (0=success, non-zero=failure)
- [ ] **CORE-08**: Installer confirms before destructive actions
- [ ] **CORE-09**: Installer supports --version flag showing current version
- [ ] **CORE-10**: Installer documents uninstall process (in help or docs)

### Onboarding

- [ ] **ONBD-01**: Installer presents interactive questionnaire to capture user context
- [ ] **ONBD-02**: Questionnaire captures: name, vault location, role/business, key areas, working preferences
- [ ] **ONBD-03**: Installer generates personalized CLAUDE.md from questionnaire answers
- [ ] **ONBD-04**: Installer detects new vs existing vault and adapts behavior
- [ ] **ONBD-05**: For existing vaults, installer preserves existing structure and content

### Vault Setup

- [ ] **VAULT-01**: For new vaults, installer creates PARA folder structure (00 Daily, 01 Inbox, 02 Projects, 03 Areas, 04 Resources, 05 Archive)
- [ ] **VAULT-02**: Installer creates templates for daily notes, projects, and areas
- [ ] **VAULT-03**: Installer creates example notes demonstrating how to use each PARA section
- [ ] **VAULT-04**: Templates include proper frontmatter (YAML) for Obsidian compatibility

### Skills Installation

- [ ] **SKIL-01**: Installer copies skills to ~/.claude/skills/
- [ ] **SKIL-02**: Installer copies agents to ~/.claude/agents/
- [ ] **SKIL-03**: Installer records installed version in state file
- [ ] **SKIL-04**: Installer records file manifest with checksums for update tracking

### Update System

- [ ] **UPDT-01**: /minervia:update command fetches latest version from git
- [ ] **UPDT-02**: Update detects which files user has customized (via checksum comparison)
- [ ] **UPDT-03**: Update preserves user-customized files, only updates unchanged files
- [ ] **UPDT-04**: Update offers merge options for customized files (keep mine, take theirs, backup + overwrite)
- [ ] **UPDT-05**: Update creates backup before modifying any files
- [ ] **UPDT-06**: Update reports what changed after completion

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Onboarding Enhancements

- **ONBD-06**: Guided first session walks user through /log-to-daily and /vault-stats
- **ONBD-07**: Summary/review step shows what will be created before writing files
- **ONBD-08**: MCP server recommendations displayed with links to docs

### Developer Experience

- **DEVX-01**: Dry-run mode (--dry-run) previews changes without executing
- **DEVX-02**: Verbose mode (--verbose) shows detailed execution info
- **DEVX-03**: Color-coded output (green/yellow/red) for visual hierarchy
- **DEVX-04**: Graceful degradation for non-TTY environments (scripts, CI)

### Advanced Features

- **ADVN-01**: Multi-vault support (manage multiple vaults from one installation)
- **ADVN-02**: Plugin system for community-contributed skills
- **ADVN-03**: Automatic backup scheduling

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Auto-install dependencies | Adds complexity, users should control their integrations |
| GUI installer | Terminal is the feature, not a limitation |
| Windows support | macOS + Linux first, Windows adds significant complexity |
| Auto-updates without user action | Users should control when they update |
| Complex rollback system | Idempotent install + backups are simpler and sufficient |
| Asking for sensitive info during install | Reference env vars or config files instead |
| Multiple verbosity levels (-vvv) | Single --verbose flag is sufficient for installer |
| Forced interactivity | Must support --yes flag for automation |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CORE-01 | Phase 2 | Complete |
| CORE-02 | Phase 7 | Pending |
| CORE-03 | Phase 1 | Complete |
| CORE-04 | Phase 2 | Complete |
| CORE-05 | Phase 7 | Pending |
| CORE-06 | Phase 7 | Pending |
| CORE-07 | Phase 1 | Complete |
| CORE-08 | Phase 7 | Pending |
| CORE-09 | Phase 2 | Complete |
| CORE-10 | Phase 2 | Complete |
| ONBD-01 | Phase 3 | Complete |
| ONBD-02 | Phase 3 | Complete |
| ONBD-03 | Phase 4 | Complete |
| ONBD-04 | Phase 4 | Complete |
| ONBD-05 | Phase 4 | Complete |
| VAULT-01 | Phase 5 | Complete |
| VAULT-02 | Phase 5 | Complete |
| VAULT-03 | Phase 5 | Complete |
| VAULT-04 | Phase 5 | Complete |
| SKIL-01 | Phase 6 | Pending |
| SKIL-02 | Phase 6 | Pending |
| SKIL-03 | Phase 6 | Pending |
| SKIL-04 | Phase 6 | Pending |
| UPDT-01 | Phase 8 | Pending |
| UPDT-02 | Phase 8 | Pending |
| UPDT-03 | Phase 8 | Pending |
| UPDT-04 | Phase 8 | Pending |
| UPDT-05 | Phase 8 | Pending |
| UPDT-06 | Phase 8 | Pending |

**Coverage:**
- v1 requirements: 29 total
- Mapped to phases: 29
- Unmapped: 0

---
*Requirements defined: 2026-01-18*
*Last updated: 2026-01-18 after roadmap creation*
