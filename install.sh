#!/bin/bash

echo "🦉 Minervia Setup"
echo "================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
if check_command "claude"; then
    CLAUDE_OK=0
else
    CLAUDE_OK=1
    echo ""
    echo -e "${RED}Claude Code CLI is required.${NC}"
    echo "Install from: https://claude.ai/download"
    echo ""
    exit 1
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

mkdir -p "$SKILLS_TARGET"

for skill_dir in "$SKILLS_SOURCE"/*/; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        target_dir="$SKILLS_TARGET/$skill_name"

        if [ -d "$target_dir" ]; then
            echo -e "${YELLOW}→${NC} $skill_name (already exists, skipping)"
        else
            cp -r "$skill_dir" "$target_dir"
            echo -e "${GREEN}✓${NC} $skill_name"
        fi
    fi
done

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
echo "Learn more at: https://minervia.co"
echo ""
