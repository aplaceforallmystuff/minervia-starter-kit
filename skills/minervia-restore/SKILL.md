---
name: minervia-restore
description: List and restore from Minervia backups. Shows available backup timestamps and lets you restore files to previous versions. Use when you need to undo an update or recover customizations.
use_when: User wants to restore from backup, undo an update, recover previous file versions, or list available backups.
allowed_tools: Bash, Read
---

# Restore from Backup

List available backups and restore files to previous versions.

## Why This Matters

Updates create backups automatically. If something goes wrong or you prefer your previous configuration, you can restore:
- All files from a specific backup
- Recover customizations that were overwritten
- Undo an update completely

## Quick Start

List available backups:

```bash
bash ~/.minervia/bin/minervia-update.sh --list-backups
```

Restore from a specific backup:

```bash
bash ~/.minervia/bin/minervia-update.sh --restore 2026-01-18T10-30-00
```

## What You'll See

```
Available backups:

  2026-01-18T10-30-00 (15 files)
  2026-01-15T14-22-33 (12 files)

To restore: ./minervia-update.sh --restore TIMESTAMP
```

## Restore Process

1. **Select backup** - Choose a timestamp from the list
2. **Preview files** - See which files will be restored
3. **Confirm** - Approve the restoration
4. **Restore** - Files copied back to original locations

## Important Notes

- Restoring overwrites current files with backup versions
- Consider creating a backup before restoring (run update first)
- Backups are stored in `~/.minervia/backups/`
- Backups are kept forever (no auto-pruning)

## Process for Claude

1. List backups: `bash ~/.minervia/bin/minervia-update.sh --list-backups`
2. If user specifies a timestamp, restore: `bash ~/.minervia/bin/minervia-update.sh --restore TIMESTAMP`
3. If no backups exist, inform user that backups are created during updates

## Success Criteria

- [ ] Backups listed or restored as requested
- [ ] User informed of restoration results
- [ ] Files restored to correct locations
