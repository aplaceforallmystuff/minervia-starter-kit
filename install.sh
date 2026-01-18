#!/bin/bash
set -euo pipefail

# ============================================================================
# Minervia Installer
# ============================================================================
# Human-led knowledge work with AI assistance
# https://github.com/aplaceforallmystuff/minervia-starter-kit
# ============================================================================

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Version - single source of truth
readonly VERSION="1.0.0"

# Display help message
show_help() {
    cat << 'EOF'
Usage: install.sh [OPTIONS]

Minervia installer - sets up your Obsidian vault for AI-assisted knowledge work.

Options:
  -h, --help      Show this help message and exit
  -V, --version   Show version number and exit

Examples:
  ./install.sh              Run the installer
  ./install.sh --help       Show this help

Prerequisites:
  - Claude Code CLI (https://claude.ai/download)
  - Bash 4.0 or later
  - Write permissions to current directory

Uninstall:
  To remove Minervia from your system:
  1. Delete skill directories: rm -rf ~/.claude/skills/minervia-*
  2. Optionally remove vault files:
     - CLAUDE.md (contains your customizations)
     - .minervia-initialized
     - .minervia-first-run
     - .claude/settings.json (if you want to remove hooks)

More info: https://github.com/aplaceforallmystuff/minervia-starter-kit
EOF
}

# Display version
show_version() {
    echo "minervia-installer $VERSION"
}

# Track temporary files for cleanup
TEMP_FILES=()

# Cleanup function - runs on exit (success or failure)
cleanup() {
    local exit_code=$?
    # Remove any temporary files created during installation
    for temp_file in "${TEMP_FILES[@]:-}"; do
        if [[ -f "$temp_file" ]]; then
            rm -f "$temp_file"
        fi
    done
    exit $exit_code
}
trap cleanup EXIT

# Error exit with actionable recovery message
error_exit() {
    local message="$1"
    local recovery="${2:-}"
    echo -e "${RED}ERROR:${NC} $message" >&2
    if [[ -n "$recovery" ]]; then
        echo -e "  ${YELLOW}Try:${NC} $recovery" >&2
    fi
    exit 1
}

# ============================================================================
# Platform Detection
# ============================================================================

# Detect operating system and set platform-specific behaviors
detect_platform() {
    case "$(uname -s)" in
        Darwin)
            PLATFORM="macos"
            ;;
        Linux)
            PLATFORM="linux"
            ;;
        *)
            error_exit "Unsupported platform: $(uname -s)" "Minervia supports macOS and Linux only"
            ;;
    esac
}
detect_platform
export PLATFORM

# Platform-specific command wrappers
# These handle differences between BSD (macOS) and GNU (Linux) tools

# Portable in-place sed edit (BSD vs GNU sed)
portable_sed_inplace() {
    if [[ "$PLATFORM" == "macos" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Portable date formatting (BSD vs GNU date)
# Usage: portable_date "+%Y-%m-%d"
portable_date() {
    date "$@"
}

# Portable stat for file modification time
# Returns modification time as Unix timestamp
portable_stat_mtime() {
    local file="$1"
    if [[ "$PLATFORM" == "macos" ]]; then
        stat -f %m "$file"
    else
        stat -c %Y "$file"
    fi
}

# ============================================================================
# Main Installation
# ============================================================================

echo "🦉 Minervia Setup"
echo "================"
echo ""

# Check for required tools
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 not found"
        return 1
    fi
}

echo "Checking requirements..."
echo ""

# Check for Claude Code CLI
if ! check_command "claude"; then
    echo ""
    error_exit "Claude Code CLI not found" "Install from https://claude.ai/download"
fi

# Optional checks
echo ""
echo "Optional tools (for full functionality):"
check_command "git" || echo "   → Version control for your vault"
check_command "jq" || echo "   → Install with: brew install jq"

echo ""

# Detect the vault directory (where install.sh was run from)
VAULT_DIR="$(pwd)"
SKILLS_SOURCE="$(dirname "$0")/skills"

# Validate that current directory is writable
if [[ ! -w "$VAULT_DIR" ]]; then
    error_exit "Cannot write to current directory: $VAULT_DIR" "Check directory permissions or run from a different location"
fi

# Validate skills source directory exists
if [[ ! -d "$SKILLS_SOURCE" ]]; then
    error_exit "Skills directory not found: $SKILLS_SOURCE" "Ensure you are running install.sh from the minervia-starter-kit directory"
fi

# Check if this is an Obsidian vault
if [ -d ".obsidian" ]; then
    echo -e "${GREEN}✓${NC} Obsidian vault detected"
else
    echo -e "${YELLOW}!${NC} No .obsidian folder found"
    echo "   Run this script from your Obsidian vault root"
    echo "   Or open this folder in Obsidian first"
    echo ""
fi

# Install skills to user's Claude Code skills directory
SKILLS_TARGET="$HOME/.claude/skills"
echo ""
echo "Installing Minervia skills..."

# Create skills directory with error handling
if ! mkdir -p "$SKILLS_TARGET" 2>/dev/null; then
    error_exit "Failed to create skills directory: $SKILLS_TARGET" "Check write permissions for $HOME/.claude/"
fi

# Track skills installed for summary
skills_installed=0
skills_skipped=0

for skill_dir in "$SKILLS_SOURCE"/*/; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        target_dir="$SKILLS_TARGET/$skill_name"

        if [ -d "$target_dir" ]; then
            echo -e "${YELLOW}→${NC} $skill_name (already exists, skipping)"
            ((skills_skipped++)) || true
        else
            if ! cp -r "$skill_dir" "$target_dir" 2>/dev/null; then
                error_exit "Failed to install skill: $skill_name" "Check disk space and permissions for $SKILLS_TARGET/"
            fi
            echo -e "${GREEN}✓${NC} $skill_name"
            ((skills_installed++)) || true
        fi
    fi
done

# Verify at least some skills exist (either installed now or previously)
if [[ $skills_installed -eq 0 && $skills_skipped -eq 0 ]]; then
    error_exit "No skills found in $SKILLS_SOURCE" "Ensure the minervia-starter-kit is complete"
fi

# Create CLAUDE.md if it doesn't exist
if [ ! -f "CLAUDE.md" ]; then
    echo ""
    echo "Creating CLAUDE.md template..."

    # Get vault name from directory
    VAULT_NAME=$(basename "$VAULT_DIR")

    cat > CLAUDE.md << 'CLAUDEMD'
# CLAUDE.md

This vault is configured with Minervia — a co-operating system for human-led knowledge work.

## Vault Configuration

<!-- Update these paths to match your vault structure -->

```yaml
vault:
  name: "My Vault"
  daily_notes: "Daily/"           # Where daily notes live (e.g., "00 Daily/YYYY/")
  inbox: "Inbox/"                 # Quick capture location
  projects: "Projects/"           # Active projects
  areas: "Areas/"                 # Ongoing responsibilities
  resources: "Resources/"         # Reference materials
  archive: "Archive/"             # Completed/inactive items
```

## How Minervia Works

You lead. AI assists. Your vault remembers.

The terminal is your interface. Skills extend what's possible. Context compounds over time.

### Available Skills

After installation, these skills are available in any vault:

| Skill | Purpose |
|-------|---------|
| `/log-to-daily` | Log session activity to today's daily note |
| `/log-to-project` | Document work to a project folder |
| `/lessons-learned` | Run a structured retrospective |
| `/start-project` | Initialize a new project with proper structure |
| `/weekly-review` | Process inbox and maintain vault health |
| `/think-first` | Apply mental models before major decisions |

### Starting a Session

```bash
cd /path/to/your/vault
claude
```

Then: describe what you're working on. Claude reads your vault, understands your context, and helps you think.

### Ending a Session

Before ending, run `/log-to-daily` to capture what happened. This creates the compound effect — tomorrow's Claude knows what you did today.

## Workflow Guidelines

### The Compound Loop

Work → Conversation → Skill invocation → Vault update → Informed future work

Every session that updates your vault makes the next session smarter.

### When to Use Each Skill

- **Starting work**: Describe the task, let Claude search relevant context
- **Making decisions**: `/think-first` with a mental model
- **Ending session**: `/log-to-daily` for continuity
- **Completing milestones**: `/log-to-project` for documentation
- **After failures or wins**: `/lessons-learned` for structured reflection
- **Weekly**: `/weekly-review` to maintain vault health

## Customization

Edit the vault configuration above to match your folder structure. Minervia skills are vault-agnostic — they work with PARA, Zettelkasten, or any organization system.

---

*Minervia: Terminal-native AI for knowledge workers.*
CLAUDEMD

    echo -e "${GREEN}✓${NC} CLAUDE.md created"
    echo ""
    echo -e "${YELLOW}!${NC} Edit CLAUDE.md to match your vault structure"
else
    echo ""
    echo -e "${YELLOW}→${NC} CLAUDE.md already exists (not overwritten)"
fi

# Git setup (optional)
echo ""
if [ ! -d ".git" ] && command -v git &> /dev/null; then
    read -p "Initialize git repository? (y/N) " init_git
    if [[ "$init_git" =~ ^[Yy] ]]; then
        git init
        echo -e "${GREEN}✓${NC} Git repository initialized"
    fi
fi

# Create FIRST_RUN marker for welcome message
if [ ! -f ".minervia-initialized" ]; then
    touch ".minervia-initialized"
    FIRST_RUN=true
else
    FIRST_RUN=false
fi

# Create .claude directory if needed
if ! mkdir -p ".claude" 2>/dev/null; then
    error_exit "Failed to create .claude directory" "Check write permissions for $VAULT_DIR"
fi

# Add welcome hook for first-time users (only if .claude/settings.json doesn't exist)
if [ ! -f ".claude/settings.json" ]; then
    cat > ".claude/settings.json" << 'SETTINGS'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "[ -f .minervia-first-run ] && echo '{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"\\n🦉 Welcome to Minervia!\\n\\nThis vault is configured for human-led knowledge work with AI assistance.\\n\\n**Quick Start:**\\n- Describe what you are working on\\n- Use /log-to-daily before ending your session\\n- Run /weekly-review to maintain vault health\\n\\n**Available Skills:** /log-to-daily, /log-to-project, /start-project, /weekly-review, /think-first, /lessons-learned, /vault-stats\\n\\nEdit CLAUDE.md to customize your vault configuration.\\n\"}}' && rm .minervia-first-run || true"
          }
        ]
      }
    ]
  }
}
SETTINGS
    # Create the first-run marker that gets removed after first session
    touch ".minervia-first-run"
    echo -e "${GREEN}✓${NC} First-run welcome configured"
fi

echo ""
echo "======================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "======================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Edit CLAUDE.md to match your vault structure"
echo "2. Start Claude Code: claude"
echo "3. Try: /log-to-daily after your first session"
echo ""
echo "Skills installed to: $SKILLS_TARGET"
echo ""
if [ "$FIRST_RUN" = true ]; then
    echo -e "${GREEN}Tip:${NC} Your first Claude session will show a welcome guide!"
    echo ""
fi
echo "Learn more at: https://github.com/aplaceforallmystuff/minervia-starter-kit"
echo ""
