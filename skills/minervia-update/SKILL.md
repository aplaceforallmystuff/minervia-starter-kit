---
name: minervia-update
description: Update Minervia to the latest version while preserving your customizations. Creates backups, shows what's new, lets you choose how to handle conflicts. Use when you want the latest skills and improvements.
use_when: User wants to update Minervia, get latest skills, check for updates, or upgrade their installation.
allowed_tools: Bash, Read
---

# Update Minervia

Check for updates and apply them safely while preserving your customizations.

## Why This Matters

Minervia evolves with new skills, bug fixes, and improvements. The update system:
- Detects files you've customized (via checksum comparison)
- Preserves your changes unless you choose to overwrite
- Creates backups before any modifications
- Shows what's new between versions

## Quick Start

Run the update:

```bash
bash ~/.minervia/bin/minervia-update.sh
```

Or preview changes first:

```bash
bash ~/.minervia/bin/minervia-update.sh --dry-run
```

## What Happens During Update

1. **Version check** - Compares installed version to latest on GitHub
2. **Changelog** - Shows what's new since your version
3. **Customization scan** - Identifies files you've modified
4. **Conflict resolution** - For each customized file, you choose:
   - Keep mine (skip this file)
   - Take theirs (use new version)
   - Backup + overwrite (save yours, use new)
5. **Backup** - Creates timestamped backup of all tracked files
6. **Update** - Applies changes to non-customized files
7. **Report** - Shows what was updated

## Options

| Flag | Effect |
|------|--------|
| `--dry-run` | Show what would change without applying |
| `-v, --verbose` | Show detailed file-by-file actions |
| `--list-backups` | Show available backups |
| `--restore TIMESTAMP` | Restore from a specific backup |

## Backups

Backups are stored in `~/.minervia/backups/` with timestamped folders:
- `2026-01-18T10-30-00/` contains all tracked files as of that update
- Backups are kept forever (no auto-pruning)

To restore from a backup:
```bash
bash ~/.minervia/bin/minervia-update.sh --restore 2026-01-18T10-30-00
```

## Process for Claude

1. Check if update script exists: `ls ~/.minervia/bin/minervia-update.sh`
2. If missing, inform user to reinstall Minervia
3. Run update with appropriate flags based on user request
4. Report results to user

## Success Criteria

- [ ] Update script executed successfully
- [ ] User informed of version changes
- [ ] Customized files handled per user preference
- [ ] Backup created before modifications
