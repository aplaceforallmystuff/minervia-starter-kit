# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-03-04

### Added

- **Safety hooks** — PreToolUse hooks installed to `~/.claude/hooks/`:
  - `block-dangerous-commands.js` — Blocks catastrophic bash commands (rm ~, dd to disk, fork bombs) and high-risk patterns (curl|bash, force push main, inline credentials)
  - `protect-secrets.js` — Prevents reading/writing .env files, SSH keys, cloud credentials
- **antislop skill** — AI writing pattern detection with 20-pattern taxonomy and scoring system
- **extract-wisdom skill** — Dynamic content insight extraction with 5 depth levels (Instant through Comprehensive)
- **creation-guard skill** — Duplicate prevention analysis before creating new skills, agents, or commands
- **systematic-debugging skill** — Four-phase root cause investigation methodology
- **verification-before-completion skill** — Evidence-before-claims gate for completion assertions
- **Skill filtering** — New installer questions let users skip writing skills or defensive development skills
- **Pre-installation summary** — Review all choices before installation begins
- **`--dry-run` flag** — Preview installation choices without making changes
- Hooks support in update system — `minervia-update.sh` now detects and updates hook files

### Changed

- CLAUDE.md template enhanced with 5 new standing instructions:
  - Security note (permissions array credential leakage)
  - Verification rule (evidence before claims)
  - Date validation (system clock as source of truth)
  - Review principle (apply fixes directly)
  - Enhanced uncertainty protocol (verify numbers/statistics)
- Installer questionnaire expanded from 5 to 7 questions
- Welcome message updated to reflect new skills and hooks

## [1.1.0] - 2026-01-12

### Added

- **vault-stats** skill - Quick visibility into vault health: note counts by PARA location, recent activity, inbox status, daily note streaks
- First-run welcome experience via SessionStart hook - New users see a helpful onboarding guide on their first Claude session
- `.minervia-initialized` marker file to track setup completion

### Changed

- **weekly-review** skill enhanced with:
  - Energy Audit section - track what energized vs drained you during the week
  - Connections Discovered section - document unexpected links between notes
  - New `energy only` parameter to run just the energy audit
  - Updated workflow from 4 steps to 5 steps

### Improved

- Install script now creates `.claude/settings.json` with welcome hook for first-time users
- Better onboarding experience for new Minervia users

## [1.0.0] - 2026-01-02

### Added

- Initial release of Minervia Starter Kit
- `install.sh` - Setup script that installs skills to `~/.claude/skills/`
- `CLAUDE.md` - Bootstrap template for vault configuration
- `.claude/commands/init.md` - Simple vault personalization command

### Skills Included

- **log-to-daily** - Capture session activity to daily notes
- **log-to-project** - Document work to project folders
- **lessons-learned** - Structured retrospective for incidents
- **start-project** - Create projects with PARA structure
- **think-first** - Apply mental models before decisions (5 models)
- **weekly-review** - Inbox processing and vault maintenance

### Documentation

- README with installation instructions
- Quick start guide
- Workflow examples
- MIT License
