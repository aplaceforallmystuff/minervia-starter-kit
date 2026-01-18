# Domain Pitfalls: CLI Installer for Claude Code + Obsidian PARA Vault

**Domain:** CLI installer / bootstrap tool
**Target users:** Semi-technical (can follow instructions but don't want to debug)
**Platforms:** macOS, Linux (no Windows v1)
**Researched:** 2026-01-18
**Confidence:** HIGH (multiple sources verified)

---

## Critical Pitfalls

Mistakes that cause users to abandon installation or corrupt their data.

---

### Pitfall 1: Silent Failures with No Feedback

**What goes wrong:** User runs installer, it fails silently or with cryptic output, user has no idea what happened or how to fix it. They give up.

**Why it happens:**
- Commands fail but script continues (no `set -e`)
- Error messages go to stderr but user only sees stdout
- Failures deep in pipeline return success from last command
- No visual indication that anything is happening during long operations

**Consequences:**
- Partial installation leaves system in unknown state
- User cannot troubleshoot without technical knowledge
- Trust destroyed immediately - they won't try again

**Warning signs:**
- Script runs without `set -euo pipefail`
- No explicit error checking after critical commands
- Long-running operations (downloads, git clone) have no progress indication
- Exit codes ignored

**Prevention:**
```bash
# Always start scripts with strict mode
set -euo pipefail

# Create explicit error handler
error_exit() {
    echo "ERROR: $1" >&2
    echo "Installation failed at line $2" >&2
    # Cleanup and rollback here
    exit 1
}
trap 'error_exit "Unexpected error" $LINENO' ERR

# Show progress for long operations
echo "Downloading Claude Code... (this may take 30 seconds)"
curl --progress-bar -o file.tar.gz "$URL" || error_exit "Download failed"
echo "Download complete."
```

**Phase to address:** Phase 1 (Core installer scaffold) - Build error handling framework from day one

**Sources:** [Writing Robust Bash Shell Scripts](https://www.davidpashley.com/articles/writing-robust-shell-scripts/), [9 Tips For Writing Safer Shell Scripts](https://belief-driven-design.com/9-tips-safer-shell-scripts-5b8d6afd618/)

---

### Pitfall 2: Update Mechanism Corrupts User Configuration

**What goes wrong:** Self-update overwrites user's customized CLAUDE.md, questionnaire answers, or PARA folder modifications. User loses hours of personalization.

**Why it happens:**
- No differentiation between "installer files" vs "user files"
- Naive `git pull` or replacement strategy
- No backup before update
- Atomic operations not used (partial write on interruption corrupts file)

**Consequences:**
- Data loss erodes all trust
- User must manually restore from backup (if they have one)
- User disables auto-update entirely, missing important fixes

**Warning signs:**
- Update code uses `cp -f` or `mv` without backup
- No distinction between template files and user-modified files
- Interruption during update leaves files in partial state
- No rollback capability

**Prevention:**
1. **Separate concerns:** Keep installer/framework files distinct from user content
   - `.minervia/` for installer internals (can be replaced)
   - User's CLAUDE.md, vault folders = never touched by update
2. **Atomic updates:** Write to temp file, then move
   ```bash
   curl -o "$temp_file" "$url" || exit 1
   mv "$temp_file" "$target_file"  # Atomic on same filesystem
   ```
3. **Backup before any modification:**
   ```bash
   backup_dir="$HOME/.minervia/backups/$(date +%Y%m%d-%H%M%S)"
   cp -r "$target" "$backup_dir/"
   ```
4. **Rollback on failure:** If update fails, restore from backup automatically

**Phase to address:** Phase 3 (Self-update mechanism) - Core architectural decision

**Sources:** [gemini-cli file corruption issue](https://github.com/google-gemini/gemini-cli/issues/12464), [Claude Code file corruption issue](https://github.com/anthropics/claude-code/issues/15326), [ML4W Dotfiles Protection](https://github.com/mylinuxforwork/dotfiles/wiki/Protect-your-configuration-and-customize-the-installation)

---

### Pitfall 3: Customization Overwritten Without Warning

**What goes wrong:** User has existing `.zshrc`, `.bashrc`, Obsidian plugins, or PARA folders. Installer blindly overwrites them.

**Why it happens:**
- Installer assumes fresh system
- No check for existing files before write
- `ln -sf` (force symlink) used without backup
- No merge strategy for config files

**Consequences:**
- User's shell breaks (PATH gone, aliases lost)
- Obsidian vault loses plugin settings
- Trust destroyed - "it broke my system"

**Warning signs:**
- Using `-f` flags without checking first
- No prompts before modifying existing files
- Assuming directories don't exist

**Prevention:**
```bash
# Always check before overwriting
if [[ -f "$HOME/.zshrc" ]]; then
    echo "Existing .zshrc found."
    echo "1) Backup existing and continue"
    echo "2) Append to existing"
    echo "3) Skip shell configuration"
    read -p "Choose [1/2/3]: " choice
    case $choice in
        1) cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)" ;;
        2) APPEND_MODE=true ;;
        3) SKIP_SHELL=true ;;
    esac
fi
```

**Phase to address:** Phase 2 (Questionnaire + config generation) - Must detect existing state

**Sources:** [Dotfiles Arch Wiki](https://wiki.archlinux.org/title/Dotfiles), [Atlassian Dotfiles Tutorial](https://www.atlassian.com/git/tutorials/dotfiles)

---

### Pitfall 4: macOS vs Linux Command Differences Break Script

**What goes wrong:** Script works on developer's Mac, fails on user's Linux (or vice versa). Common culprits: `sed`, `grep`, `date`, `cp`, `xargs`.

**Why it happens:**
- macOS uses BSD coreutils, Linux uses GNU coreutils
- Flags differ (`sed -i ''` vs `sed -i`, `ls -G` vs `ls --color`)
- Regex behavior differs between GNU grep and BSD grep
- `date` command syntax incompatible

**Consequences:**
- Installation fails for entire platform segment
- Error messages are confusing ("invalid option --")
- Developer can't reproduce because it works on their machine

**Warning signs:**
- Script uses `sed -i` without platform check
- Using extended regex without `-E` flag (BSD) vs `-r` (GNU)
- `date -d` usage (GNU only, BSD uses `-v`)
- `cp` behavior with trailing slashes

**Prevention:**
```bash
# Detect platform once at start
if [[ "$(uname)" == "Darwin" ]]; then
    SED_INPLACE="sed -i ''"
    DATE_CMD="gdate"  # Require GNU date via Homebrew
else
    SED_INPLACE="sed -i"
    DATE_CMD="date"
fi

# Or use POSIX-compliant commands only
# Instead of sed -i, use: sed 'pattern' file > tmp && mv tmp file

# Check for GNU tools on macOS
if [[ "$(uname)" == "Darwin" ]] && ! command -v gdate &>/dev/null; then
    echo "This installer requires GNU coreutils on macOS."
    echo "Install with: brew install coreutils"
    exit 1
fi
```

**Phase to address:** Phase 1 (Core scaffold) - Platform detection must be foundational

**Sources:** [Linux GNU vs Mac BSD CLI](https://www.dev-diaries.com/social-posts/linux-gnu-vs-mac-bsd-cli/), [Differences Between MacOS and Linux Scripting](https://dev.to/aghost7/differences-between-macos-and-linux-scripting-74d), [MacOS vs Linux cp command](https://dev.to/ackshaey/macos-vs-linux-the-cp-command-will-trip-you-up-2p00)

---

### Pitfall 5: PATH Modification Done Wrong

**What goes wrong:** Installer modifies wrong shell config file, uses wrong syntax, or creates duplicate entries. User's terminal breaks or changes don't persist.

**Why it happens:**
- Assuming bash when user has zsh (or vice versa)
- Modifying `.bashrc` when `.bash_profile` is needed (or `.zshrc` vs `.zprofile`)
- Not checking if PATH entry already exists
- macOS `path_helper` reorders PATH unexpectedly
- Read-only symlinks (NixOS, home-manager users)

**Consequences:**
- Commands not found after "successful" install
- Shell startup slow due to duplicate PATH entries
- User's carefully crafted PATH order destroyed
- NixOS users have broken home-manager

**Warning signs:**
- Hardcoding `.bashrc` without checking shell
- Appending to PATH without checking for duplicates
- Not testing on both bash and zsh
- Ignoring `$SHELL` environment variable

**Prevention:**
```bash
# Detect current shell AND default shell
CURRENT_SHELL="$(basename "$SHELL")"

# Pick correct config file
case "$CURRENT_SHELL" in
    zsh)
        SHELL_CONFIG="$HOME/.zshrc"
        ;;
    bash)
        # macOS: .bash_profile, Linux: .bashrc
        if [[ "$(uname)" == "Darwin" ]]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        else
            SHELL_CONFIG="$HOME/.bashrc"
        fi
        ;;
esac

# Check for read-only (NixOS home-manager)
if [[ -L "$SHELL_CONFIG" ]] && [[ ! -w "$SHELL_CONFIG" ]]; then
    echo "Shell config is a read-only symlink (NixOS/home-manager detected)."
    echo "Please add manually: export PATH=\"\$HOME/.minervia/bin:\$PATH\""
    SKIP_PATH_MOD=true
fi

# Check if already in PATH
if ! grep -q "minervia/bin" "$SHELL_CONFIG" 2>/dev/null; then
    echo 'export PATH="$HOME/.minervia/bin:$PATH"' >> "$SHELL_CONFIG"
fi
```

**Phase to address:** Phase 1 (Core scaffold) - PATH is critical infrastructure

**Sources:** [PATH for zsh on macOS with path_helper](https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2), [NVM zshrc issue](https://github.com/nvm-sh/nvm/issues/1879), [How to add a directory to your PATH](https://jvns.ca/blog/2025/02/13/how-to-add-a-directory-to-your-path/)

---

## Moderate Pitfalls

Mistakes that cause delays, confusion, or technical debt.

---

### Pitfall 6: Questionnaire UX That Frustrates Users

**What goes wrong:** User abandons installation during questionnaire due to poor experience: unclear questions, no ability to go back, validation errors at the end instead of inline.

**Why it happens:**
- No progress indication (how many questions left?)
- Can't see previous answers or go back
- Validation only at final submit
- Questions require information user doesn't have ready
- No defaults for common choices

**Consequences:**
- User gives up mid-questionnaire (abandonment)
- Incorrect answers due to confusion
- User has to restart from beginning to fix one answer

**Warning signs:**
- No question numbering ("Question 3 of 8")
- Validation waits until all questions answered
- No back/edit capability
- Required questions with no default
- Technical jargon in user-facing questions

**Prevention:**
```bash
# Show progress
echo "=== Question 3 of 5: Vault Location ==="
echo ""

# Provide sensible defaults
read -p "Where should we create your vault? [$HOME/Documents/obsidian-vault]: " vault_path
vault_path="${vault_path:-$HOME/Documents/obsidian-vault}"

# Validate immediately
if [[ -d "$vault_path" ]]; then
    echo "Directory exists. Contents will be preserved."
elif [[ -f "$vault_path" ]]; then
    echo "ERROR: A file (not directory) exists at this path."
    # Re-ask question
fi

# Allow review before proceeding
echo ""
echo "=== Configuration Summary ==="
echo "Vault location: $vault_path"
echo "Shell: $CURRENT_SHELL"
echo ""
read -p "Proceed with these settings? [Y/n]: " confirm
```

**Phase to address:** Phase 2 (Questionnaire system)

**Sources:** [Creating a setup wizard (and when you shouldn't)](https://blog.logrocket.com/ux-design/creating-setup-wizard-when-you-shouldnt/), [Wizard UI Pattern](https://www.eleken.co/blog-posts/wizard-ui-pattern-explained), [Inline Validation UX](https://smart-interface-design-patterns.com/articles/inline-validation-ux/)

---

### Pitfall 7: Dependency Hell at Bootstrap Time

**What goes wrong:** Installer requires tool X to check for dependencies, but tool X itself might not be installed. Chicken-and-egg problem leaves user stuck.

**Why it happens:**
- Using `jq` to parse JSON when jq might not exist
- Requiring Node.js to run the installer that installs Node.js
- Git needed to clone repo but git check happens after clone attempt

**Consequences:**
- Installer fails immediately on fresh systems
- Error message assumes user knows how to install missing dep
- Different failure on different systems based on what's pre-installed

**Warning signs:**
- Installer written in language that might not be present (Python, Node)
- Using tools like `jq`, `curl`, `git` without checking first
- Check for dependencies happens after attempting to use them

**Prevention:**
```bash
# Check dependencies FIRST, before any real work
check_dependencies() {
    local missing=()

    # Essential tools (should exist on any Unix-like system)
    command -v bash &>/dev/null || missing+=("bash")
    command -v curl &>/dev/null || missing+=("curl")

    # Tools we need
    command -v git &>/dev/null || missing+=("git")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing required tools: ${missing[*]}"
        echo ""
        echo "Install them with:"
        if [[ "$(uname)" == "Darwin" ]]; then
            echo "  brew install ${missing[*]}"
        else
            echo "  sudo apt install ${missing[*]}  # Debian/Ubuntu"
            echo "  sudo dnf install ${missing[*]}  # Fedora"
        fi
        exit 1
    fi
}

# Call before anything else
check_dependencies
```

**Phase to address:** Phase 1 (Core scaffold) - First lines of installer

**Sources:** [Bootstrap chicken or egg problem](https://asrp.github.io/blog/bootstrap_chicken_or_egg), [MIT Fantom Bootstrap](https://web.mit.edu/fantom_v1.0.66/doc/docTools/Bootstrap.html)

---

### Pitfall 8: Obsidian Vault Permission Issues

**What goes wrong:** Installer creates vault or `.obsidian` folder with wrong permissions. Obsidian fails to open vault, or sync tools (Syncthing) can't access files.

**Why it happens:**
- Running installer with sudo creates root-owned files
- umask settings create restrictive permissions
- Flatpak/sandbox can't access user directories
- iCloud/Dropbox paths have special permission requirements

**Consequences:**
- "No permission to access folder" error in Obsidian
- Sync conflicts or failures
- User must manually fix permissions (technical knowledge required)

**Warning signs:**
- Any use of `sudo` during vault creation
- Creating files without explicit permission setting
- Not testing with cloud sync locations
- Assuming home directory is always accessible

**Prevention:**
```bash
# Never use sudo for user files
if [[ $EUID -eq 0 ]]; then
    echo "ERROR: Do not run this installer as root or with sudo."
    echo "Run as your normal user: ./install.sh"
    exit 1
fi

# Create vault with explicit permissions
mkdir -p "$vault_path"
chmod 755 "$vault_path"

# Verify we can write
if ! touch "$vault_path/.minervia-test" 2>/dev/null; then
    echo "ERROR: Cannot write to $vault_path"
    echo "Check permissions or choose a different location."
    rm -f "$vault_path/.minervia-test"
    exit 1
fi
rm -f "$vault_path/.minervia-test"

# Warn about cloud sync locations
if [[ "$vault_path" == *"iCloud"* ]] || [[ "$vault_path" == *"Dropbox"* ]]; then
    echo "WARNING: You've chosen a cloud-synced location."
    echo "This should work, but if you see permission errors in Obsidian,"
    echo "try creating the vault locally first, then moving it."
fi
```

**Phase to address:** Phase 2 (PARA folder creation)

**Sources:** [Obsidian permission denied error](https://forum.obsidian.md/t/solved-eaccess-permission-denied-error-arch-syncthing/91635), [Obsidian failed to open no permission](https://forum.obsidian.md/t/failed-to-open-no-permission-to-access-folder/9760)

---

### Pitfall 9: API Key Handling Security Failures

**What goes wrong:** Installer prompts for API key, then stores it insecurely (plain text, logged to file, visible in ps output).

**Why it happens:**
- Echoing key to screen during input
- Storing in plain text config file with world-readable permissions
- Logging installer output includes the key
- Passing key as command-line argument (visible in process list)

**Consequences:**
- API key leaked, unexpected charges
- Security-conscious users won't use the tool
- GitHub secret scanning triggers alerts

**Warning signs:**
- Using `echo` with API key variable
- Storing key outside protected location
- Not using `read -s` for silent input
- Key visible in installer logs

**Prevention:**
```bash
# Silent input for API keys
read -s -p "Enter your Anthropic API key: " api_key
echo ""  # Newline after silent input

# Never echo the key
# BAD: echo "Using key: $api_key"
# GOOD: echo "API key configured."

# Store securely (environment variable, not file)
# If file storage needed:
key_file="$HOME/.config/minervia/api_key"
mkdir -p "$(dirname "$key_file")"
echo "$api_key" > "$key_file"
chmod 600 "$key_file"  # Owner read/write only

# Clear variable when done
unset api_key

# Never pass as command-line argument
# BAD: claude --api-key "$api_key" init
# GOOD: ANTHROPIC_API_KEY="$api_key" claude init
```

**Phase to address:** Phase 2 (Questionnaire + config generation)

**Sources:** [Claude API Key Best Practices](https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure), [Managing API Key Environment Variables in Claude Code](https://support.claude.com/en/articles/12304248-managing-api-key-environment-variables-in-claude-code), [Claude Code loads secrets without permission](https://www.knostic.ai/blog/claude-loads-secrets-without-permission)

---

### Pitfall 10: No Rollback After Failed Update

**What goes wrong:** Update process fails midway, leaving installation in broken state. User can't use current version or roll back to previous working version.

**Why it happens:**
- Update modifies files in-place without backup
- No concept of "versions" to roll back to
- Failed download leaves partial files
- Database/state corruption from interrupted migration

**Consequences:**
- Complete reinstall required
- User loses trust in auto-update
- Support burden increases dramatically

**Warning signs:**
- Update process modifies files directly
- No backup step before update
- No success verification after update
- No stored "last known good" version

**Prevention:**
```bash
# Keep last working version
INSTALL_DIR="$HOME/.minervia"
VERSIONS_DIR="$INSTALL_DIR/versions"
CURRENT_LINK="$INSTALL_DIR/current"

update() {
    new_version="$1"
    new_dir="$VERSIONS_DIR/$new_version"

    # Download to new directory
    mkdir -p "$new_dir"
    download_release "$new_version" "$new_dir" || {
        rm -rf "$new_dir"
        echo "Update failed. Keeping current version."
        return 1
    }

    # Verify new version works
    "$new_dir/bin/minervia" --version || {
        rm -rf "$new_dir"
        echo "New version failed verification. Keeping current version."
        return 1
    }

    # Atomic switch
    old_version=$(readlink "$CURRENT_LINK" | xargs basename)
    ln -sfn "$new_dir" "$CURRENT_LINK"

    echo "Updated from $old_version to $new_version"
    echo "To rollback: minervia rollback $old_version"
}

rollback() {
    version="$1"
    if [[ -d "$VERSIONS_DIR/$version" ]]; then
        ln -sfn "$VERSIONS_DIR/$version" "$CURRENT_LINK"
        echo "Rolled back to $version"
    else
        echo "Version $version not found"
    fi
}
```

**Phase to address:** Phase 3 (Self-update mechanism)

**Sources:** [go-github-selfupdate with rollback](https://pkg.go.dev/github.com/rhysd/go-github-selfupdate/selfupdate), [Salesforce CLI rollback announcement](https://github.com/forcedotcom/cli/issues/811)

---

## Minor Pitfalls

Mistakes that cause annoyance but are fixable without major effort.

---

### Pitfall 11: Symlink Creation Failures

**What goes wrong:** Script tries to create symlink, fails because target already exists, leaves system in inconsistent state.

**Why it happens:**
- Using `ln -s` without checking if link exists
- Using `ln -sf` without considering if existing file is important
- Race conditions between check and create
- Dangling symlinks from previous failed installs

**Prevention:**
```bash
create_symlink() {
    local target="$1"
    local link="$2"

    # Check if link already exists and points correctly
    if [[ -L "$link" ]]; then
        if [[ "$(readlink "$link")" == "$target" ]]; then
            echo "Symlink already correct: $link -> $target"
            return 0
        else
            echo "Updating existing symlink: $link"
            rm "$link"
        fi
    elif [[ -e "$link" ]]; then
        echo "WARNING: $link exists and is not a symlink"
        echo "Backing up to ${link}.bak"
        mv "$link" "${link}.bak"
    fi

    ln -s "$target" "$link"
}
```

**Phase to address:** Phase 1 (Core scaffold)

**Sources:** [Beware of symlinks when testing file existence](https://tanguy.ortolo.eu/blog/article113/test-symlink), [Check if a file is a symlink with Bash](https://koenwoortman.com/bash-script-check-if-file-is-symlink/)

---

### Pitfall 12: Config File Version Migration Failures

**What goes wrong:** v2 of installer changes config file format. Users on v1 format hit errors, or worse, their settings silently disappear.

**Why it happens:**
- No version marker in config file
- No migration path between versions
- Breaking changes without deprecation warnings
- Assuming all config files are latest version

**Prevention:**
```bash
# Always version your config files
# config.json: { "version": 1, "vault_path": "...", ... }

migrate_config() {
    config_file="$1"

    version=$(jq -r '.version // 0' "$config_file")

    case $version in
        0)
            echo "Migrating config from v0 to v1..."
            # Add version field, transform old format
            jq '. + {version: 1}' "$config_file" > "${config_file}.new"
            mv "${config_file}.new" "$config_file"
            version=1
            ;&  # Fall through to next migration
        1)
            echo "Migrating config from v1 to v2..."
            # v2 changes: vault_path -> vaults (array)
            jq '{version: 2, vaults: [.vault_path]}' "$config_file" > "${config_file}.new"
            mv "${config_file}.new" "$config_file"
            ;;
        2)
            echo "Config already at latest version."
            ;;
        *)
            echo "Unknown config version: $version"
            echo "Your config may be from a newer version of Minervia."
            exit 1
            ;;
    esac
}
```

**Phase to address:** Phase 3 (Self-update, config handling)

**Sources:** [AWS CLI v1 to v2 migration guide](https://docs.aws.amazon.com/cli/latest/userguide/cliv2-migration.html), [Ember CLI upgrade guide](https://cli.emberjs.com/release/basic-use/upgrading/), [Buf v2 config migration](https://buf.build/docs/migration-guides/migrate-v2-config-files/)

---

### Pitfall 13: Inconsistent Uninstall Experience

**What goes wrong:** User wants to remove the tool. No uninstaller exists, or it leaves artifacts everywhere, or it removes too much (user's data).

**Why it happens:**
- Uninstall not implemented at all
- No tracking of what was installed where
- Removing user-generated content along with tool
- Forgetting about PATH modifications, symlinks, shell integrations

**Prevention:**
```bash
# Track everything during install
MANIFEST_FILE="$HOME/.minervia/install_manifest.txt"

track_install() {
    echo "$1" >> "$MANIFEST_FILE"
}

# During install:
# track_install "dir:$HOME/.minervia"
# track_install "symlink:$HOME/.local/bin/minervia"
# track_install "shell_line:.zshrc:export PATH=..."

uninstall() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        echo "No installation manifest found. Manual uninstall required."
        exit 1
    fi

    echo "This will remove:"
    cat "$MANIFEST_FILE"
    echo ""
    echo "Your vault and user files will NOT be removed."
    read -p "Continue? [y/N]: " confirm

    if [[ "$confirm" == "y" ]]; then
        while IFS= read -r item; do
            type="${item%%:*}"
            path="${item#*:}"
            case $type in
                dir) rm -rf "$path" ;;
                symlink) rm -f "$path" ;;
                shell_line)
                    file="${path%%:*}"
                    line="${path#*:}"
                    sed -i.bak "/${line//\//\\/}/d" "$HOME/$file"
                    ;;
            esac
        done < "$MANIFEST_FILE"
        rm "$MANIFEST_FILE"
        echo "Uninstall complete."
    fi
}
```

**Phase to address:** Phase 4 (Polish and maintenance commands)

---

## Phase-Specific Warnings Summary

| Phase | Topic | Likely Pitfall | Priority |
|-------|-------|----------------|----------|
| 1 | Core scaffold | Silent failures, platform differences | CRITICAL |
| 1 | Core scaffold | Dependency bootstrap, PATH modification | HIGH |
| 2 | Questionnaire | UX abandonment, validation timing | MODERATE |
| 2 | Config generation | API key security, existing file overwrite | HIGH |
| 2 | PARA creation | Permission issues, symlink failures | MODERATE |
| 3 | Self-update | Data corruption, no rollback | CRITICAL |
| 3 | Config migration | Breaking changes without migration | MODERATE |
| 4 | Maintenance | No uninstaller | LOW |

---

## Pre-Flight Checklist

Before each phase, verify these items to avoid pitfalls:

### Phase 1 Checklist
- [ ] Script starts with `set -euo pipefail`
- [ ] Error handler with trap defined
- [ ] Dependency check is first action
- [ ] Platform detection (macOS/Linux) implemented
- [ ] Both bash and zsh shell configs handled
- [ ] PATH modification idempotent (won't duplicate)
- [ ] Tested on both macOS and Linux

### Phase 2 Checklist
- [ ] Questionnaire shows progress (N of M)
- [ ] Each question validated immediately
- [ ] Sensible defaults provided
- [ ] API key input uses `read -s` (silent)
- [ ] API key stored with 600 permissions
- [ ] Existing files detected and handled (backup/append/skip)
- [ ] No sudo required for any operation

### Phase 3 Checklist
- [ ] Update creates backup before any modification
- [ ] User files clearly separated from installer files
- [ ] Atomic file operations (write to temp, then move)
- [ ] Verification step after update completes
- [ ] Rollback mechanism implemented and tested
- [ ] Config version migration path exists

### Phase 4 Checklist
- [ ] Install manifest tracks all created files
- [ ] Uninstall command implemented
- [ ] Uninstall never removes user content (vaults)
- [ ] All shell modifications reversible

---

## Sources Summary

### Error Handling & Robustness
- [Writing Robust Bash Shell Scripts](https://www.davidpashley.com/articles/writing-robust-shell-scripts/)
- [9 Tips For Writing Safer Shell Scripts](https://belief-driven-design.com/9-tips-safer-shell-scripts-5b8d6afd618/)
- [Error handling in Bash scripts - Red Hat](https://www.redhat.com/sysadmin/error-handling-bash-scripting)

### Cross-Platform Compatibility
- [Linux GNU vs Mac BSD CLI](https://www.dev-diaries.com/social-posts/linux-gnu-vs-mac-bsd-cli/)
- [Differences Between MacOS and Linux Scripting](https://dev.to/aghost7/differences-between-macos-and-linux-scripting-74d)
- [MacOS vs Linux cp command](https://dev.to/ackshaey/macos-vs-linux-the-cp-command-will-trip-you-up-2p00)
- [Shopify CLI cross-OS compatibility](https://shopify.github.io/cli/cli/cross-os-compatibility.html)

### Customization & Dotfiles
- [Dotfiles Arch Wiki](https://wiki.archlinux.org/title/Dotfiles)
- [Atlassian Dotfiles Tutorial](https://www.atlassian.com/git/tutorials/dotfiles)
- [ML4W Dotfiles Protection](https://github.com/mylinuxforwork/dotfiles/wiki/Protect-your-configuration-and-customize-the-installation)

### Questionnaire & Validation UX
- [Creating a setup wizard (and when you shouldn't)](https://blog.logrocket.com/ux-design/creating-setup-wizard-when-you-shouldnt/)
- [Wizard UI Pattern](https://www.eleken.co/blog-posts/wizard-ui-pattern-explained)
- [Inline Validation UX](https://smart-interface-design-patterns.com/articles/inline-validation-ux/)

### Update & Rollback
- [go-github-selfupdate with rollback](https://pkg.go.dev/github.com/rhysd/go-github-selfupdate/selfupdate)
- [AWS CLI upgrade debug mode](https://docs.aws.amazon.com/cli/latest/userguide/cli-upgrade-debug-mode.html)

### Security
- [Claude API Key Best Practices](https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure)
- [Friends don't let friends curl | bash](https://www.sysdig.com/blog/friends-dont-let-friends-curl-bash)

### Obsidian-Specific
- [Obsidian permission issues](https://forum.obsidian.md/t/solved-eaccess-permission-denied-error-arch-syncthing/91635)
- [Obsidian Manage vaults documentation](https://help.obsidian.md/manage-vaults)
