# CLI Installer Architecture

**Domain:** CLI installer with self-updating capability
**Researched:** 2026-01-18
**Confidence:** HIGH (patterns verified through multiple sources)

## Recommended Architecture

```
                              INSTALLER SYSTEM
    ============================================================

    [User Input]                          [Template System]
         |                                       |
         v                                       v
    +------------+                        +-------------+
    | Questionnaire |---> answers.json ---> | Renderer    |
    | Engine     |                        | Engine      |
    +------------+                        +-------------+
         |                                       |
         v                                       v
    +------------+                        +-------------+
    | Validator  |                        | File Writer |
    +------------+                        +-------------+
                \                         /
                 \                       /
                  v                     v
              +-------------------------+
              |    Installation State   |
              |    (~/.minervia/)       |
              +-------------------------+
                         |
                         v
    +--------------------------------------------------+
    |                 OUTPUT TARGETS                    |
    |  ~/.claude/skills/    |    /path/to/vault/        |
    |  (global skills)      |    (CLAUDE.md, PARA)      |
    +--------------------------------------------------+


                         UPDATE SYSTEM
    ============================================================

    [git fetch --tags]
         |
         v
    +------------------+     +-------------------+
    | Version Detector | --> | Changelog Parser  |
    | (compare tags)   |     | (show what's new) |
    +------------------+     +-------------------+
         |
         v
    +------------------+     +-------------------+
    | Customization    | --> | Merge Strategy    |
    | Detector         |     | Selector          |
    +------------------+     +-------------------+
         |
         v
    +------------------+
    | Safe Updater     |
    | (backup + apply) |
    +------------------+
```

## Component Boundaries

| Component | Responsibility | Input | Output |
|-----------|---------------|-------|--------|
| **Questionnaire Engine** | Collect user context through interactive prompts | User terminal input | `answers.json` or variables |
| **Validator** | Verify paths exist, required fields provided | User answers | Validated answers or errors |
| **Template Renderer** | Apply answers to template files | Templates + answers | Rendered content |
| **File Writer** | Create directories and write files atomically | Rendered content + paths | Files on disk |
| **State Manager** | Track installation metadata and versions | Install actions | `~/.minervia/state.json` |
| **Version Detector** | Compare installed vs available versions | Git tags + state file | Update availability |
| **Customization Detector** | Identify user modifications vs defaults | Installed files + checksums | Modification flags |
| **Merge Strategy** | Decide how to handle conflicts | Modifications + updates | Merge plan |
| **Update Executor** | Apply updates safely with backups | Merge plan | Updated installation |

## Data Flow

### Installation Flow

```
1. ENTRY: User runs `./install.sh` or `curl | bash`
   |
   v
2. PREREQUISITES: Check for claude CLI, git, create dirs
   |
   v
3. QUESTIONNAIRE: Interactive prompts collect context
   |  - Name, role, business type
   |  - Working preferences
   |  - Vault location (existing or new)
   |  - PARA folder preferences
   |
   v
4. VALIDATION: Verify inputs before proceeding
   |  - Vault path exists (if existing)
   |  - Required fields populated
   |  - No conflicts with existing files
   |
   v
5. TEMPLATE RENDERING: Generate personalized files
   |  - CLAUDE.md from user answers
   |  - PARA folders with example content
   |  - .claude/settings.json with hooks
   |
   v
6. FILE INSTALLATION: Write to destinations
   |  - Skills -> ~/.claude/skills/
   |  - Vault files -> /path/to/vault/
   |  - State -> ~/.minervia/state.json
   |
   v
7. STATE RECORDING: Track what was installed
   |  - Version (git tag)
   |  - File manifest with checksums
   |  - Installation timestamp
   |  - User answers (for re-templating)
   |
   v
8. POST-INSTALL: First-run setup
   - Create .minervia-first-run marker
   - Display next steps
   - Offer to start guided session
```

### Update Flow

```
1. ENTRY: User runs `/minervia:update` command
   |
   v
2. VERSION CHECK: Compare installed vs available
   |  - git fetch --tags origin
   |  - Compare state.json version to latest tag
   |  - If current == latest: "Already up to date"
   |
   v
3. CHANGELOG DISPLAY: Show what's new
   |  - Parse CHANGELOG.md between versions
   |  - Display new features, fixes, breaking changes
   |  - Prompt: "Update to vX.Y.Z? (y/N)"
   |
   v
4. CUSTOMIZATION SCAN: Detect user modifications
   |  - For each installed file:
   |    - Compare current checksum vs manifest checksum
   |    - If different: flag as "customized"
   |  - Build list of customized vs pristine files
   |
   v
5. MERGE STRATEGY SELECTION: Per-file decisions
   |  - Pristine files: overwrite directly
   |  - Customized files: offer choices
   |    - Keep mine (skip update for this file)
   |    - Take theirs (overwrite, lose customizations)
   |    - Manual merge (show diff, user edits)
   |    - Create .orig backup + update
   |
   v
6. BACKUP: Safety net before changes
   |  - Copy ~/.minervia/ to ~/.minervia.backup-TIMESTAMP/
   |  - Copy customized files to .orig versions
   |
   v
7. APPLY UPDATES: Execute merge plan
   |  - Update pristine files
   |  - Handle customized files per strategy
   |  - Update state.json with new version/checksums
   |
   v
8. VERIFY: Confirm success
   - Re-check file integrity
   - Display summary of changes
   - Offer rollback if issues detected
```

## Key Abstractions

### State File (`~/.minervia/state.json`)

Tracks everything needed for updates and reinstallation.

```json
{
  "version": "1.2.0",
  "installed_at": "2026-01-18T15:30:00Z",
  "updated_at": "2026-01-25T10:00:00Z",
  "vault_path": "/Users/jim/Documents/Vault",
  "answers": {
    "name": "Jim",
    "role": "Consultant",
    "business_type": "Solo consulting practice",
    "daily_notes_path": "00 Daily/YYYY/",
    "projects_path": "02 Projects/"
  },
  "manifest": {
    "skills": {
      "log-to-daily": {
        "path": "~/.claude/skills/log-to-daily/SKILL.md",
        "checksum": "sha256:abc123...",
        "source_checksum": "sha256:abc123..."
      }
    },
    "vault_files": {
      "CLAUDE.md": {
        "path": "/Users/jim/Documents/Vault/CLAUDE.md",
        "checksum": "sha256:def456...",
        "source_template": "templates/CLAUDE.md.tmpl"
      }
    }
  }
}
```

**Key fields:**
- `version`: Git tag of installed version
- `answers`: User responses from questionnaire (enables re-templating on update)
- `manifest`: File inventory with checksums for modification detection

### Template System

Templates use simple variable substitution for Bash compatibility.

**Template file:** `templates/CLAUDE.md.tmpl`
```markdown
# CLAUDE.md

This is {{NAME}}'s personal knowledge management vault.

## Vault Configuration

```yaml
vault:
  name: "{{VAULT_NAME}}"
  daily_notes: "{{DAILY_NOTES_PATH}}"
  inbox: "{{INBOX_PATH}}"
  projects: "{{PROJECTS_PATH}}"
  areas: "{{AREAS_PATH}}"
  resources: "{{RESOURCES_PATH}}"
  archive: "{{ARCHIVE_PATH}}"
```

## Current Focus

{{#IF_PROVIDED:CURRENT_FOCUS}}
{{CURRENT_FOCUS}}
{{/IF_PROVIDED}}
{{#IF_NOT_PROVIDED:CURRENT_FOCUS}}
<!-- Update this section when your priorities change -->
{{/IF_NOT_PROVIDED}}
```

**Renderer approach:** Use `sed` or `envsubst` for simple substitution. Avoid complex templating engines (stay portable).

### Customization Detection

Two-checksum system enables precise modification tracking:

1. **Source checksum:** Hash of file as shipped in release
2. **Current checksum:** Hash of file as currently installed

**Logic:**
- `current == source`: File is pristine, safe to overwrite
- `current != source`: File was modified by user, needs merge strategy

**Implementation:**
```bash
# Generate checksum
sha256sum "$file" | cut -d' ' -f1

# Store in manifest during install
# Compare during update
```

## Patterns to Follow

### Pattern 1: Idempotent Installation

**What:** Running installer multiple times produces same result without duplication.

**When:** Always. Users may re-run installer accidentally or intentionally.

**Implementation:**
```bash
install_skill() {
    local skill_name="$1"
    local target="$SKILLS_DIR/$skill_name"

    if [ -d "$target" ]; then
        # Already exists - check if update needed
        local current_hash=$(get_checksum "$target/SKILL.md")
        local source_hash=$(get_checksum "$SOURCE_DIR/skills/$skill_name/SKILL.md")

        if [ "$current_hash" = "$source_hash" ]; then
            echo "  $skill_name (current)"
            return 0
        fi

        # Different - flag for update decision
        echo "  $skill_name (modified, skipping)"
        return 1
    fi

    # Fresh install
    cp -r "$SOURCE_DIR/skills/$skill_name" "$target"
    echo "  $skill_name (installed)"
}
```

### Pattern 2: Questionnaire with Defaults

**What:** Every question has a sensible default; advanced users can accept all defaults.

**When:** Interactive installation.

**Implementation:**
```bash
ask() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"

    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " response
        response="${response:-$default}"
    else
        read -p "$prompt: " response
    fi

    eval "$var_name='$response'"
}

# Usage
ask "Your name" "$(whoami)" NAME
ask "Daily notes folder" "00 Daily/YYYY/" DAILY_NOTES_PATH
```

### Pattern 3: Atomic File Operations

**What:** Write to temp file, then move. Prevents partial writes on failure.

**When:** Writing any file that matters.

**Implementation:**
```bash
write_file() {
    local content="$1"
    local target="$2"
    local temp="${target}.tmp.$$"

    echo "$content" > "$temp"
    mv "$temp" "$target"
}
```

### Pattern 4: Git-Based Versioning

**What:** Use git tags as single source of truth for versions.

**When:** Checking for updates, recording installed version.

**Implementation:**
```bash
get_installed_version() {
    jq -r '.version' ~/.minervia/state.json
}

get_latest_version() {
    git fetch --tags --quiet
    git describe --tags $(git rev-list --tags --max-count=1)
}

check_for_updates() {
    local installed=$(get_installed_version)
    local latest=$(get_latest_version)

    if [ "$installed" = "$latest" ]; then
        echo "Already up to date ($installed)"
        return 1
    fi

    echo "Update available: $installed -> $latest"
    return 0
}
```

### Pattern 5: Backup Before Modify

**What:** Create backup of any file before overwriting during updates.

**When:** Update operations on files that may have customizations.

**Implementation:**
```bash
backup_before_update() {
    local file="$1"
    local backup_dir="$HOME/.minervia/backups/$(date +%Y%m%d-%H%M%S)"

    mkdir -p "$backup_dir"
    cp "$file" "$backup_dir/$(basename $file)"

    echo "Backed up to: $backup_dir"
}
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Silent Overwrites

**What:** Updating files without checking for user modifications.

**Why bad:** Destroys user customizations without warning. Breaks trust.

**Instead:** Always check checksums, offer merge strategies, create backups.

### Anti-Pattern 2: Global State Without Tracking

**What:** Installing files without recording what was installed.

**Why bad:** Makes updates impossible, leaves orphaned files on uninstall.

**Instead:** Maintain manifest with every installed file path and checksum.

### Anti-Pattern 3: Hardcoded Paths in Templates

**What:** Embedding absolute paths in generated files.

**Why bad:** Breaks portability, fails when vault moves.

**Instead:** Use relative paths or user-provided variables.

### Anti-Pattern 4: Complex Templating in Bash

**What:** Trying to implement Jinja-style templating in pure Bash.

**Why bad:** Fragile, hard to debug, edge cases everywhere.

**Instead:** Simple `{{VARIABLE}}` substitution with `sed`. For complex logic, generate files in installer script directly.

### Anti-Pattern 5: Version Strings in Multiple Places

**What:** Storing version in package.json, install.sh, and state.json separately.

**Why bad:** They drift apart, cause confusion about actual version.

**Instead:** Git tags are single source of truth. Everything else reads from git or state.json.

## Directory Structure

### Source Repository (what ships)

```
minervia-starter-kit/
  install.sh              # Main installer entry point
  update.sh               # Update logic (or embedded in install.sh)
  lib/
    questionnaire.sh      # Interactive prompt functions
    templates.sh          # Template rendering functions
    state.sh              # State file management
    version.sh            # Version comparison utilities
  templates/
    CLAUDE.md.tmpl        # CLAUDE.md template
    para/                 # PARA folder templates
      00-daily-example.md
      01-inbox-readme.md
      02-projects-example.md
      03-areas-example.md
      04-resources-example.md
      05-archive-readme.md
  skills/
    log-to-daily/SKILL.md
    weekly-review/SKILL.md
    ...
```

### Installation Target

```
~/.minervia/                    # Minervia state directory
  state.json                    # Installation state and manifest
  backups/                      # Backup directory for updates
    20260118-153000/            # Timestamped backup folders

~/.claude/                      # Claude Code directory (shared)
  skills/                       # Global skills
    log-to-daily/SKILL.md       # Installed skills
    weekly-review/SKILL.md
    ...

/path/to/vault/                 # User's Obsidian vault
  CLAUDE.md                     # Generated from template
  .claude/
    settings.json               # Session hooks
  00 Daily/                     # PARA structure (if new vault)
  01 Inbox/
  02 Projects/
  03 Areas/
  04 Resources/
  05 Archive/
```

## Suggested Build Order

Based on dependencies between components, build in this order:

### Phase 1: Foundation (no dependencies)

1. **State file schema and utilities** (`lib/state.sh`)
   - Define JSON structure for state.json
   - Functions: read_state, write_state, get_version, set_version
   - Required by: everything else

2. **Template system** (`lib/templates.sh`)
   - Simple variable substitution with sed
   - Functions: render_template, render_file
   - Required by: file installation

### Phase 2: Core Installation

3. **Questionnaire engine** (`lib/questionnaire.sh`)
   - Interactive prompts with defaults
   - Validation of user inputs
   - Functions: ask, ask_path, ask_yesno, validate_inputs
   - Depends on: nothing
   - Required by: main installer

4. **File installation** (part of `install.sh`)
   - Skill copying with idempotency
   - Template rendering to vault
   - Manifest recording
   - Depends on: templates, state

### Phase 3: Update System

5. **Version utilities** (`lib/version.sh`)
   - Git tag comparison
   - Semantic version parsing
   - Functions: get_latest_tag, compare_versions, fetch_tags
   - Depends on: git availability

6. **Customization detection**
   - Checksum comparison against manifest
   - File modification flags
   - Depends on: state file, manifest

7. **Merge strategies**
   - User choice prompts
   - Backup creation
   - Conflict resolution
   - Depends on: customization detection

8. **Update executor** (`update.sh` or `/minervia:update`)
   - Orchestrates update flow
   - Applies merge plan
   - Updates state
   - Depends on: all above

### Phase 4: Polish

9. **Guided first session**
   - Post-install walkthrough
   - Skill demonstrations
   - MCP recommendations

10. **Error handling and rollback**
    - Transaction-like updates
    - Rollback on failure
    - User-friendly error messages

## Scalability Considerations

| Concern | Current Scale | Growth Path |
|---------|---------------|-------------|
| Number of skills | 7 skills | Manifest scales linearly; no issue up to 100+ |
| File size of state.json | ~2KB | Grows with manifest entries; compress if >100KB |
| Update check frequency | On-demand | Add auto-check with 24h cache if requested |
| Multi-vault support | Single vault | Add vault-id to state; support multiple installations |

## Sources

- [Better CLI - Self-Executing Installation Scripts](https://bettercli.org/design/distribution/self-executing-installer/)
- [CLI Design Guidelines](https://clig.dev/)
- [chezmoi - Template System and Update Handling](https://www.chezmoi.io/user-guide/daily-operations/)
- [chezmoi - Design Decisions](https://www.chezmoi.io/user-guide/frequently-asked-questions/design/)
- [Tuck - Modern Dotfiles Manager with Smart Merging](https://tuck.sh/)
- [Homebrew Update Architecture](https://docs.brew.sh/Updating-Software-in-Homebrew)
- [Atlassian - Dotfiles with Bare Git Repository](https://www.atlassian.com/git/tutorials/dotfiles)
- [Manifest Files - Wikipedia](https://en.wikipedia.org/wiki/Manifest_file)
- [Greg's Wiki - Bash Practices](https://mywiki.wooledge.org/BashGuide/Practices)
- [GitHub Gist - Getting Latest Git Tag](https://gist.github.com/rponte/fdc0724dd984088606b0)

---

*Architecture research: 2026-01-18*
