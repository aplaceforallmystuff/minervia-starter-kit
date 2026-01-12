# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
