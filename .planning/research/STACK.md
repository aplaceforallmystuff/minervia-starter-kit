# Technology Stack: CLI Installer

**Project:** Minervia Installer Enhancement
**Researched:** 2026-01-18
**Overall Confidence:** HIGH

## Executive Summary

For a CLI installer targeting semi-technical users (comfortable with terminal, not developers), the 2025 standard stack combines:

1. **Pure Bash** for maximum portability (no npm/Python dependencies)
2. **Charmbracelet Gum** for modern interactive prompts (optional dependency with fallback)
3. **Semantic versioning** with simple file-based manifest tracking
4. **conf.d pattern** for preserving user customizations during updates

This stack prioritizes: zero friction installation, graceful degradation, and "it just works" behavior.

## Recommended Stack

### Core: Bash 3.2+

| Technology | Version | Purpose | Rationale |
|------------|---------|---------|-----------|
| Bash | 3.2+ | Installer runtime | Ships with macOS, universal on Linux. Bash 3.2 is the macOS default; targeting this ensures maximum compatibility. |

**Confidence:** HIGH (verified: macOS ships bash 3.2, Linux typically has 4.x+)

**Why not Zsh/Fish/etc?**
- Bash is the lowest common denominator
- Users may have different default shells
- `#!/bin/bash` is universally available

### Interactive Prompts: Gum (with fallback)

| Technology | Version | Purpose | Rationale |
|------------|---------|---------|-----------|
| [Gum](https://github.com/charmbracelet/gum) | 0.14+ | Beautiful interactive prompts | Modern, glamorous CLI UX. Single binary, MIT license, actively maintained (last published Sep 2025). |

**Confidence:** HIGH (verified via [official repository](https://github.com/charmbracelet/gum))

**Installation:**
```bash
# macOS
brew install gum

# Linux (various)
# Debian/Ubuntu: available in repos
# Arch: pacman -S gum
# Or: go install github.com/charmbracelet/gum@latest
```

**Why Gum over alternatives:**

| Tool | Pros | Cons | Verdict |
|------|------|------|---------|
| **Gum** | Modern aesthetics, single binary, customizable, MIT license | Requires installation | **Recommended** - best UX |
| **dialog** | Pre-installed on some systems, feature-rich | 1994 aesthetics, ncurses dependency, complex | Legacy |
| **whiptail** | Pre-installed on Debian, lightweight | Limited features, basic aesthetics | Fallback option |
| **read -p** | Zero dependencies, always works | Poor UX, no validation, no styling | Last resort fallback |

**Graceful degradation strategy:**
```bash
if command -v gum &> /dev/null; then
    # Use gum for beautiful prompts
    name=$(gum input --placeholder "Your name")
else
    # Fallback to basic read
    read -p "Your name: " name
fi
```

### Version Management: File-Based Manifest

| Technology | Version | Purpose | Rationale |
|------------|---------|---------|-----------|
| [semver-tool](https://github.com/fsaintjacques/semver-tool) | Latest | Version comparison | Pure bash implementation, MIT license. Use for comparing versions during updates. |

**Confidence:** MEDIUM (verified pattern exists, specific tool choice is recommendation)

**Manifest file pattern:**
```bash
# .minervia/manifest.json
{
  "version": "1.2.3",
  "installed_at": "2026-01-18T10:30:00Z",
  "components": {
    "skills": {
      "log-to-daily": "1.2.3",
      "start-project": "1.2.3"
    }
  },
  "user_modified": [
    "CLAUDE.md"
  ]
}
```

**Why file-based over git tags:**
- Works without git installed
- Tracks individual component versions
- Can flag user-modified files
- Simple to implement and debug

**Version comparison (pure bash, no dependency):**
```bash
version_gt() {
    # Returns 0 if $1 > $2
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$1" ]
}

if version_gt "$NEW_VERSION" "$CURRENT_VERSION"; then
    echo "Update available"
fi
```

### Self-Update: Git-Based with GitHub API

| Technology | Version | Purpose | Rationale |
|------------|---------|---------|-----------|
| Git | Any | Clone/pull updates | Universal, already likely installed for vault version control |
| GitHub API | v3 | Version checking | No auth needed for public repos, rate-limited but sufficient |

**Confidence:** HIGH (well-established pattern)

**Update flow:**
```bash
# 1. Check for updates (GitHub API, no auth needed)
LATEST=$(curl -s https://api.github.com/repos/org/repo/releases/latest | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')

# 2. Compare versions
if version_gt "$LATEST" "$CURRENT"; then
    # 3. Prompt user
    if gum confirm "Update available ($CURRENT -> $LATEST). Update now?"; then
        # 4. Pull updates
        git -C "$INSTALLER_DIR" pull origin main
        # 5. Re-run installer
        exec "$INSTALLER_DIR/install.sh" --upgrade
    fi
fi
```

**Reference:** [bsupdate](https://github.com/alexanderepstein/bsupdate) - drop-in bash update utility

### Configuration Preservation: conf.d Pattern

| Technology | Pattern | Purpose | Rationale |
|------------|---------|---------|-----------|
| conf.d directories | Linux standard | User customization preservation | Separates vendor config from user overrides. Updates never clobber user files. |

**Confidence:** HIGH (industry standard pattern)

**Implementation:**
```
.minervia/
  config.d/
    00-defaults.conf      # Vendor defaults (overwritten on update)
    50-user.conf          # User customizations (NEVER touched by installer)
    90-local.conf         # Machine-specific (NEVER touched)
```

**Merge order:** Files processed alphabetically. Later files override earlier ones.

**Why this pattern:**
- User files are NEVER modified by updates
- Clear separation: "what vendor provides" vs "what user changed"
- No complex merge algorithms needed
- Standard pattern users may already understand

### Colored Output: ANSI Escape Codes

| Technology | Pattern | Purpose | Rationale |
|------------|---------|---------|-----------|
| ANSI escapes | \033[...m | Colored terminal output | Universal support (50+ years of standardization). tput is more "correct" but ANSI is simpler and equally portable in practice. |

**Confidence:** HIGH (verified: ANSI/ECMA escape sequences standard since 1976)

**Recommended pattern:**
```bash
# Color definitions (fail gracefully if terminal doesn't support)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'  # No Color / Reset
else
    # Non-interactive (piped/redirected) - no colors
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# Usage
echo -e "${GREEN}Success${NC}"
echo -e "${RED}Error${NC}"
echo -e "${YELLOW}Warning${NC}"
```

**Why ANSI over tput:**
- Simpler, no subprocess spawning
- Equally portable in practice (all modern terminals support ANSI)
- tput requires terminfo database, adds complexity
- References: [Greg's Wiki BashFAQ/037](https://mywiki.wooledge.org/BashFAQ/037)

### Error Handling: Strict Mode + Traps

| Technology | Pattern | Purpose | Rationale |
|------------|---------|---------|-----------|
| set -euo pipefail | Bash strict mode | Catch errors early | Prevents cascading failures, catches undefined variables |
| trap | Cleanup on exit/error | Resource management | Ensures temp files cleaned up, provides helpful error messages |

**Confidence:** HIGH (verified best practice via [Red Hat](https://www.redhat.com/en/blog/bash-error-handling))

**Recommended script header:**
```bash
#!/bin/bash
set -Eeuo pipefail

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}

# Error handler with line number
error_handler() {
    local line_no=$1
    local error_code=$2
    echo -e "${RED}Error on line $line_no (exit code $error_code)${NC}" >&2
    cleanup
    exit "$error_code"
}

# Set traps
trap cleanup EXIT
trap 'error_handler $LINENO $?' ERR

# Create temp directory
TEMP_DIR=$(mktemp -d)
```

**Key options explained:**
- `-e` (errexit): Exit on error
- `-E` (errtrace): ERR trap inherited by functions
- `-u` (nounset): Error on undefined variables
- `-o pipefail`: Pipeline fails if any command fails

### Directory Scaffolding: Template Copying with Variable Substitution

| Technology | Pattern | Purpose | Rationale |
|------------|---------|---------|-----------|
| envsubst | Variable substitution | Template processing | Available in GNU gettext, handles ${VAR} substitution |
| cp -r | Directory copying | Scaffolding | Simple, reliable, no dependencies |

**Confidence:** MEDIUM (envsubst may need installation on minimal systems)

**Pattern:**
```bash
# Template in templates/CLAUDE.md.template
# Contains: ${VAULT_NAME}, ${DAILY_PATH}, etc.

scaffold_vault() {
    local vault_dir="$1"
    local vault_name="$2"

    export VAULT_NAME="$vault_name"
    export DAILY_PATH="${vault_dir}/Daily"

    # Create directories
    mkdir -p "$vault_dir"/{Daily,Inbox,Projects,Areas,Resources,Archive}

    # Process template
    envsubst < templates/CLAUDE.md.template > "$vault_dir/CLAUDE.md"
}
```

**Fallback for systems without envsubst:**
```bash
# Pure bash variable substitution
template_substitute() {
    local template="$1"
    local output="$2"

    # Read template, substitute variables
    while IFS= read -r line; do
        eval echo "\"$line\""
    done < "$template" > "$output"
}
```

## Alternatives Considered

### NOT Recommended

| Technology | Why Rejected |
|------------|--------------|
| **Node.js (npm)** | Adds heavy dependency. Users shouldn't need npm to install a bash-based skill kit. |
| **Python** | Not universally available at correct version. Python 2/3 split still causes issues. |
| **Yeoman/Plop** | Overkill for this use case, requires npm ecosystem. |
| **Ansible** | Server automation tool, wrong abstraction level. |
| **Docker** | Massive overhead for simple file operations. |

### Edge Cases

| Scenario | Solution |
|----------|----------|
| No gum installed | Fallback to `read -p` with clear prompts |
| No git installed | Download tarball from GitHub releases |
| No curl installed | Try wget, then fail with helpful message |
| Non-interactive mode | Support `--yes` flag for CI/scripted usage |

## Installation Commands

### User Installation

```bash
# Install gum (optional, enhances UX)
brew install gum  # macOS
# or: sudo apt install gum  # Debian/Ubuntu
# or: skip it (installer will use fallback prompts)

# Run installer
curl -fsSL https://minervia.co/install.sh | bash
# or
git clone https://github.com/org/minervia-starter-kit.git
./minervia-starter-kit/install.sh
```

### No Additional Dependencies Required

The installer should work with just:
- bash (pre-installed)
- curl OR wget (one of these is always present)
- git (optional, for updates)

## Bash Patterns Reference

### Interactive Prompt with Gum Fallback

```bash
prompt_input() {
    local prompt="$1"
    local default="$2"
    local result

    if command -v gum &> /dev/null; then
        result=$(gum input --placeholder "$prompt" --value "$default")
    else
        read -p "$prompt [$default]: " result
        result="${result:-$default}"
    fi

    echo "$result"
}
```

### Confirm Dialog with Gum Fallback

```bash
confirm() {
    local prompt="$1"

    if command -v gum &> /dev/null; then
        gum confirm "$prompt"
        return $?
    else
        read -p "$prompt (y/N): " response
        [[ "$response" =~ ^[Yy] ]]
        return $?
    fi
}
```

### Multi-Select with Gum Fallback

```bash
multiselect() {
    local prompt="$1"
    shift
    local options=("$@")

    if command -v gum &> /dev/null; then
        gum choose --no-limit --header "$prompt" "${options[@]}"
    else
        # Basic fallback: list options with numbers
        echo "$prompt"
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt"
            ((i++))
        done
        read -p "Enter numbers (comma-separated): " selections
        # Parse and return selected items
        # (implementation left as exercise)
    fi
}
```

### Spinner for Long Operations

```bash
with_spinner() {
    local title="$1"
    shift

    if command -v gum &> /dev/null; then
        gum spin --spinner dot --title "$title" -- "$@"
    else
        echo -n "$title..."
        "$@"
        echo " done"
    fi
}

# Usage
with_spinner "Installing skills" cp -r skills/ ~/.claude/skills/
```

## Version Update Strategy

### Update Check Flow

```bash
check_for_updates() {
    local current_version
    current_version=$(cat .minervia/version 2>/dev/null || echo "0.0.0")

    local latest_version
    latest_version=$(curl -sf "https://api.github.com/repos/org/repo/releases/latest" \
        | grep '"tag_name"' \
        | sed -E 's/.*"v?([^"]+)".*/\1/' \
        || echo "$current_version")

    if version_gt "$latest_version" "$current_version"; then
        echo "$latest_version"
        return 0
    fi
    return 1
}
```

### User Customization Preservation

```bash
preserve_user_files() {
    local backup_dir="$1"

    # Files that should never be overwritten
    local user_files=(
        "CLAUDE.md"
        ".claude/settings.json"
    )

    mkdir -p "$backup_dir"

    for file in "${user_files[@]}"; do
        if [[ -f "$file" ]]; then
            cp "$file" "$backup_dir/"
        fi
    done
}

restore_user_files() {
    local backup_dir="$1"

    for file in "$backup_dir"/*; do
        local basename
        basename=$(basename "$file")
        # Restore if user had customizations
        if [[ -f "$file" ]]; then
            cp "$file" "./$basename"
        fi
    done
}
```

## Sources

### Primary (HIGH confidence)

- [Charmbracelet Gum](https://github.com/charmbracelet/gum) - Official repository, MIT license
- [Red Hat: Bash Error Handling](https://www.redhat.com/en/blog/bash-error-handling) - Best practices for error handling
- [semver-tool](https://github.com/fsaintjacques/semver-tool) - Pure bash semver implementation
- [bsupdate](https://github.com/alexanderepstein/bsupdate) - Drop-in bash update utility pattern

### Secondary (MEDIUM confidence)

- [Greg's Wiki BashFAQ/037](https://mywiki.wooledge.org/BashFAQ/037) - Color codes in bash
- [Baeldung: Bash Interactive Prompts](https://www.baeldung.com/linux/bash-interactive-prompts) - Prompt patterns
- [FLOZz: Bash Colors and Formatting](https://misc.flogisoft.com/bash/tip_colors_and_formatting) - ANSI escape codes reference
- [Systemd conf.d pattern](https://www.freedesktop.org/software/systemd/man/latest/systemd-system.conf.html) - Override patterns

### Pattern References

- [bash-installer-framework](https://github.com/projectivetech/bash-installer-framework) - Generic installer framework
- [gist: Self-updating bash script](https://gist.github.com/cubedtear/54434fc66439fc4e04e28bd658189701) - Update patterns

---

*Stack research: 2026-01-18*
