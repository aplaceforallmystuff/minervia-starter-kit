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

# ============================================================================
# Gum Detection
# ============================================================================

# Gum provides enhanced interactive prompts when available
HAS_GUM=false

# Check if Gum CLI is installed
check_gum() {
    if command -v gum &> /dev/null; then
        HAS_GUM=true
        return 0
    fi
    return 1
}

# Offer to install Gum for better experience
offer_gum_install() {
    if check_gum; then
        return 0
    fi

    echo ""
    echo "Gum provides a better installation experience with styled prompts."
    echo ""

    local install_gum
    read -p "Install Gum for a better experience? (y/N) " install_gum

    if [[ "$install_gum" =~ ^[Yy] ]]; then
        if command -v brew &> /dev/null; then
            echo "Installing Gum via Homebrew..."
            if brew install gum; then
                HAS_GUM=true
                echo -e "${GREEN}✓${NC} Gum installed"
            else
                echo -e "${YELLOW}!${NC} Gum installation failed, continuing with basic prompts"
            fi
        else
            echo -e "${YELLOW}!${NC} Homebrew not found. Install Gum manually: https://github.com/charmbracelet/gum"
            echo "   Continuing with basic prompts..."
        fi
    else
        echo "Continuing with basic prompts..."
    fi
}

# ============================================================================
# Input Functions (Dual-Mode: Gum with read fallback)
# ============================================================================

MAX_RETRIES=3

# ask_text - Single-line text input with optional validation
# Usage: result=$(ask_text "Prompt:" "placeholder" required)
# Args: prompt, placeholder, required (true/false)
ask_text() {
    local prompt="$1"
    local placeholder="${2:-}"
    local required="${3:-false}"
    local result=""
    local retries=0

    while true; do
        if $HAS_GUM; then
            result=$(gum input --placeholder "$placeholder" --prompt "$prompt ")
        else
            read -p "$prompt " result
        fi

        # Validation for required fields
        if [[ "$required" == "true" && -z "$result" ]]; then
            ((retries++))
            if [[ $retries -ge $MAX_RETRIES ]]; then
                echo -e "${RED}Maximum retries exceeded.${NC}" >&2
                return 1
            fi
            echo -e "${RED}This field is required.${NC} ($((MAX_RETRIES - retries)) attempts remaining)" >&2
            continue
        fi

        break
    done

    echo "$result"
}

# ask_choice - Single selection from options
# Usage: result=$(ask_choice "Prompt:" "Option A" "Option B" "Option C")
# Returns: Selected option text
ask_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local result=""

    if $HAS_GUM; then
        result=$(gum choose --header "$prompt" "${options[@]}")
    else
        echo "$prompt"
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt"
            ((i++))
        done

        while true; do
            read -p "Enter number (1-${#options[@]}): " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#options[@]} ]]; then
                result="${options[$((choice-1))]}"
                break
            fi
            echo -e "${RED}Invalid selection. Enter a number 1-${#options[@]}.${NC}"
        done
    fi

    echo "$result"
}

# ask_multi - Multi-select from options (Tab to select with Gum)
# Usage: result=$(ask_multi "Prompt:" "Opt A" "Opt B" "Opt C")
# Returns: Newline-separated selected options (convert to comma in caller if needed)
ask_multi() {
    local prompt="$1"
    shift
    local options=("$@")
    local result=""

    if $HAS_GUM; then
        # Tab to select, Enter to confirm
        result=$(printf '%s\n' "${options[@]}" | gum filter --no-limit --header "$prompt (Tab to select, Enter to confirm)")
    else
        echo "$prompt"
        echo "(Enter comma-separated numbers, e.g., 1,3,4. Press Enter for none.)"
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt"
            ((i++))
        done

        while true; do
            read -p "Select: " choices
            if [[ -z "$choices" ]]; then
                break  # Allow empty selection
            fi

            # Parse comma-separated numbers
            local selected=()
            IFS=',' read -ra nums <<< "$choices"
            local valid=true

            for num in "${nums[@]}"; do
                num=$(echo "$num" | tr -d ' ')  # Trim whitespace
                if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#options[@]} ]]; then
                    selected+=("${options[$((num-1))]}")
                else
                    valid=false
                    break
                fi
            done

            if $valid; then
                result=$(printf '%s\n' "${selected[@]}")
                break
            fi
            echo -e "${RED}Invalid selection. Use numbers 1-${#options[@]}, comma-separated.${NC}"
        done
    fi

    echo "$result"
}

# ask_confirm - Yes/No confirmation
# Usage: if ask_confirm "Continue?" "y"; then ... fi
# Args: prompt, default (y/n)
# Returns: Exit code 0 for yes, 1 for no
ask_confirm() {
    local prompt="$1"
    local default="${2:-n}"  # n or y

    if $HAS_GUM; then
        if [[ "$default" == "y" ]]; then
            gum confirm --default=yes "$prompt"
        else
            gum confirm "$prompt"
        fi
        return $?
    else
        local yn_prompt="(y/N)"
        [[ "$default" == "y" ]] && yn_prompt="(Y/n)"

        read -p "$prompt $yn_prompt " response
        response=${response:-$default}

        [[ "$response" =~ ^[Yy] ]]
        return $?
    fi
}

# ============================================================================
# Questionnaire Flow
# ============================================================================

# Options for choice questions
ROLE_OPTIONS=("Developer" "Designer" "Product Manager" "Consultant" "Writer" "Researcher" "Other")
AREA_OPTIONS=("Software Development" "Content Creation" "Research" "Consulting" "Project Management" "Learning" "Personal")
PREF_OPTIONS=("Concise responses" "Detailed explanations" "Step-by-step guidance" "Direct communication" "Socratic questioning")

# Progress tracking
CURRENT_QUESTION=0
TOTAL_QUESTIONS=5

# Show progress indicator
show_progress() {
    ((CURRENT_QUESTION++))
    echo ""
    if $HAS_GUM; then
        gum style --foreground 99 "Question $CURRENT_QUESTION of $TOTAL_QUESTIONS"
    else
        echo -e "${YELLOW}--- Question $CURRENT_QUESTION of $TOTAL_QUESTIONS ---${NC}"
    fi
}

# Run the interactive questionnaire
run_questionnaire() {
    CURRENT_QUESTION=0

    echo ""
    if $HAS_GUM; then
        gum style --bold "Let's personalize your Minervia installation"
    else
        echo "Let's personalize your Minervia installation"
    fi
    echo ""

    # Question 1: Name
    show_progress
    echo "What should Claude call you?"
    ANSWERS[name]=$(ask_text "Your name:" "e.g., Jane" true)

    # Question 2: Vault Path
    show_progress
    echo "Where is your Obsidian vault?"
    echo "(Enter the full path to your vault folder)"
    while true; do
        ANSWERS[vault_path]=$(ask_text "Vault path:" "e.g., /Users/jane/Documents/MyVault" true)

        if [[ -d "${ANSWERS[vault_path]}" ]]; then
            break
        else
            if ask_confirm "Directory doesn't exist. Create it?" "n"; then
                if mkdir -p "${ANSWERS[vault_path]}" 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} Created ${ANSWERS[vault_path]}"
                    break
                else
                    echo -e "${RED}Failed to create directory.${NC} Check permissions."
                fi
            fi
        fi
    done

    # Question 3: Role
    show_progress
    echo "What best describes your role?"
    ANSWERS[role]=$(ask_choice "Select your role:" "${ROLE_OPTIONS[@]}")

    # Conditional: If "Other", ask for custom role
    if [[ "${ANSWERS[role]}" == "Other" ]]; then
        ANSWERS[role]=$(ask_text "Describe your role:" "e.g., Freelance editor" true)
    fi

    # Question 4: Key Areas
    show_progress
    echo "What areas do you focus on?"
    echo "(You can select multiple)"
    local areas_raw
    areas_raw=$(ask_multi "Select your key areas:" "${AREA_OPTIONS[@]}")
    ANSWERS[areas]=$(echo "$areas_raw" | tr '\n' ',' | sed 's/,$//')

    # Question 5: Working Preferences
    show_progress
    echo "How do you prefer Claude to communicate?"
    local prefs_raw
    prefs_raw=$(ask_multi "Select preferences:" "${PREF_OPTIONS[@]}")
    ANSWERS[preferences]=$(echo "$prefs_raw" | tr '\n' ',' | sed 's/,$//')

    # Summary and confirmation handled by confirm_summary
    if ! confirm_summary; then
        # User chose "Start over"
        run_questionnaire
        return
    fi
}

# Display summary of all answers
show_summary() {
    echo ""
    if $HAS_GUM; then
        gum style --border double --padding "1 2" --border-foreground 99 "Summary"
    else
        echo "========================================"
        echo "             Summary"
        echo "========================================"
    fi
    echo ""
    echo "1) Name:        ${ANSWERS[name]}"
    echo "2) Vault path:  ${ANSWERS[vault_path]}"
    echo "3) Role:        ${ANSWERS[role]}"
    echo "4) Key areas:   ${ANSWERS[areas]:-None selected}"
    echo "5) Preferences: ${ANSWERS[preferences]:-None selected}"
    echo ""
}

# Edit a specific answer field
edit_answer() {
    local field="$1"
    case "$field" in
        1|name)
            echo "What should Claude call you?"
            ANSWERS[name]=$(ask_text "Your name:" "${ANSWERS[name]}" true)
            ;;
        2|vault_path|vault-path)
            echo "Where is your Obsidian vault?"
            while true; do
                ANSWERS[vault_path]=$(ask_text "Vault path:" "${ANSWERS[vault_path]}" true)
                if [[ -d "${ANSWERS[vault_path]}" ]]; then
                    break
                else
                    if ask_confirm "Directory doesn't exist. Create it?" "n"; then
                        if mkdir -p "${ANSWERS[vault_path]}" 2>/dev/null; then
                            echo -e "${GREEN}✓${NC} Created ${ANSWERS[vault_path]}"
                            break
                        else
                            echo -e "${RED}Failed to create directory.${NC} Check permissions."
                        fi
                    fi
                fi
            done
            ;;
        3|role)
            echo "What best describes your role?"
            ANSWERS[role]=$(ask_choice "Select your role:" "${ROLE_OPTIONS[@]}")
            if [[ "${ANSWERS[role]}" == "Other" ]]; then
                ANSWERS[role]=$(ask_text "Describe your role:" "e.g., Freelance editor" true)
            fi
            ;;
        4|areas)
            echo "What areas do you focus on?"
            local areas_raw
            areas_raw=$(ask_multi "Select your key areas:" "${AREA_OPTIONS[@]}")
            ANSWERS[areas]=$(echo "$areas_raw" | tr '\n' ',' | sed 's/,$//')
            ;;
        5|preferences)
            echo "How do you prefer Claude to communicate?"
            local prefs_raw
            prefs_raw=$(ask_multi "Select preferences:" "${PREF_OPTIONS[@]}")
            ANSWERS[preferences]=$(echo "$prefs_raw" | tr '\n' ',' | sed 's/,$//')
            ;;
    esac
}

# Confirm summary with edit/restart options
confirm_summary() {
    while true; do
        show_summary

        local action
        if $HAS_GUM; then
            action=$(gum choose "Continue" "Edit answer" "Start over")
        else
            echo "c) Continue"
            echo "e) Edit an answer"
            echo "r) Start over"
            read -p "Choice: " action
            case "$action" in
                c|C) action="Continue" ;;
                e|E) action="Edit answer" ;;
                r|R) action="Start over" ;;
            esac
        fi

        case "$action" in
            "Continue")
                return 0
                ;;
            "Edit answer")
                local field
                if $HAS_GUM; then
                    field=$(gum choose "1) Name" "2) Vault path" "3) Role" "4) Key areas" "5) Preferences")
                    field="${field%%)*}"  # Extract number
                else
                    read -p "Which field to edit (1-5)? " field
                fi
                edit_answer "$field"
                ;;
            "Start over")
                return 1  # Signal to restart questionnaire
                ;;
        esac
    done
}

# Display help message
show_help() {
    cat << 'EOF'
Usage: install.sh [OPTIONS]

Minervia installer - sets up your Obsidian vault for AI-assisted knowledge work.

Options:
  -h, --help      Show this help message and exit
  -V, --version   Show version number and exit

Non-Interactive Mode:
  For CI/automation, provide answers via flags:

  --name NAME           Your name for Claude to use
  --vault-path PATH     Full path to your Obsidian vault
  --role ROLE           Your role (Developer, Designer, etc.)
  --areas AREAS         Comma-separated key areas
  --preferences PREFS   Comma-separated preferences
  --no-questionnaire    Skip questionnaire (requires --name, --vault-path)

Examples:
  ./install.sh              Run the installer
  ./install.sh --help       Show this help
  ./install.sh --name "Jane Doe" --vault-path "/Users/jane/vault" --role "Developer"
  ./install.sh --no-questionnaire --name "CI User" --vault-path "./test-vault"

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

# Check if running interactively (stdin is a TTY)
is_interactive() {
    [ -t 0 ]
}

# CLI flag storage (used before ANSWERS array is available)
# These get copied to ANSWERS after check_prerequisites runs
CLI_NAME=""
CLI_VAULT_PATH=""
CLI_ROLE=""
CLI_AREAS=""
CLI_PREFERENCES=""
SKIP_QUESTIONNAIRE=false

# Parse command-line arguments
# Runs BEFORE any other checks to allow --help/--version without prerequisites
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -V|--version)
                show_version
                exit 0
                ;;
            --name)
                CLI_NAME="$2"
                shift
                ;;
            --vault-path)
                CLI_VAULT_PATH="$2"
                shift
                ;;
            --role)
                CLI_ROLE="$2"
                shift
                ;;
            --areas)
                CLI_AREAS="$2"
                shift
                ;;
            --preferences)
                CLI_PREFERENCES="$2"
                shift
                ;;
            --no-questionnaire)
                SKIP_QUESTIONNAIRE=true
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "Run '$(basename "$0") --help' for usage" >&2
                exit 2
                ;;
            *)
                # Non-option argument, stop parsing
                break
                ;;
        esac
        shift
    done
}

# Parse arguments first (--help/--version work without prerequisites)
parse_args "$@"

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
# Vault Detection and Template Processing
# ============================================================================

# Global flag for vault type (set by detect_vault_type)
IS_NEW_VAULT=false

# Detect if vault is new (empty) or existing (has content)
# Sets IS_NEW_VAULT global and prints detection result
detect_vault_type() {
    # Check for non-hidden files only (hidden files like .git, .obsidian are infrastructure)
    shopt -s nullglob
    local files=("$VAULT_DIR"/*)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        IS_NEW_VAULT=true
        echo -e "${GREEN}Detected:${NC} New vault (empty directory)"
    else
        IS_NEW_VAULT=false
        local count=${#files[@]}
        echo -e "${YELLOW}Detected:${NC} Existing vault ($count visible items)"
    fi
    export IS_NEW_VAULT
}

# Escape special sed characters in user input
# Prevents sed injection from user-provided values
escape_for_sed() {
    printf '%s' "$1" | sed -e 's/[&/\]/\\&/g'
}

# Format comma-separated values as markdown bullet list
# Args: csv_string, default_placeholder
# Returns: Multi-line bullet list or default if empty
format_as_bullets() {
    local csv="$1"
    local default="${2:-[Not specified]}"

    if [[ -z "$csv" ]]; then
        echo "$default"
        return
    fi

    # Convert CSV to bullet list, trimming whitespace
    echo "$csv" | tr ',' '\n' | while read -r item; do
        item=$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -n "$item" ]] && echo "- $item"
    done
}

# Process template file with user answers
# Args: template_file, output_file
# Substitutes placeholders with values from ANSWERS array
process_template() {
    local template_file="$1"
    local output_file="$2"

    # Read template content
    local content
    content=$(<"$template_file")

    # Escape user input for safe sed substitution
    local escaped_name escaped_role
    escaped_name=$(escape_for_sed "${ANSWERS[name]:-}")
    escaped_role=$(escape_for_sed "${ANSWERS[role]:-[Your role]}")

    # Substitute simple placeholders using # delimiter to avoid path conflicts
    content=$(echo "$content" | sed "s#{{NAME}}#$escaped_name#g")
    content=$(echo "$content" | sed "s#{{ROLE}}#$escaped_role#g")
    content=$(echo "$content" | sed "s#{{DATE}}#$(date +%Y-%m-%d)#g")

    # Format multi-value fields as bullet lists
    local areas_formatted prefs_formatted
    areas_formatted=$(format_as_bullets "${ANSWERS[areas]:-}" "[Add your key focus areas here]")
    prefs_formatted=$(format_as_bullets "${ANSWERS[preferences]:-}" "- I prefer concise, direct communication\n- Create files in appropriate PARA locations based on content type\n- Document work sessions in daily notes\n- Use [[wiki links]] to connect related content\n- When creating project notes, include clear next actions")

    # Write to temp file for multi-line substitution with awk
    echo "$content" > "$output_file.tmp"
    TEMP_FILES+=("$output_file.tmp")

    # Use awk for multi-line placeholder substitution
    awk -v areas="$areas_formatted" -v prefs="$prefs_formatted" '
        /\{\{AREAS\}\}/ { print areas; next }
        /\{\{PREFERENCES\}\}/ { print prefs; next }
        { print }
    ' "$output_file.tmp" > "$output_file"

    rm -f "$output_file.tmp"
}

# ============================================================================
# Prerequisite Checks
# ============================================================================

# Check Bash version (4.0+ required for associative arrays and other features)
check_bash_version() {
    local min_major=4
    local min_minor=0

    # BASH_VERSINFO is a built-in array: [0]=major, [1]=minor, [2]=patch
    if [[ -z "${BASH_VERSINFO[0]:-}" ]]; then
        error_exit "Cannot determine Bash version" \
            "Ensure you are running this script with Bash"
    fi

    local current_major="${BASH_VERSINFO[0]}"
    local current_minor="${BASH_VERSINFO[1]}"

    if [[ $current_major -lt $min_major ]] || \
       [[ $current_major -eq $min_major && $current_minor -lt $min_minor ]]; then
        error_exit "Bash ${min_major}.${min_minor}+ required (found ${BASH_VERSION})" \
            "Upgrade Bash: brew install bash (macOS) or apt install bash (Linux)"
    fi
}

# Check for Claude Code CLI
check_claude_cli() {
    if ! command -v claude &> /dev/null; then
        error_exit "Claude Code CLI not found" \
            "Install from https://claude.ai/download"
    fi
}

# Check write permissions for a directory
check_write_permissions() {
    local target_dir="$1"
    if [[ ! -w "$target_dir" ]]; then
        error_exit "Cannot write to directory: $target_dir" \
            "Check permissions or run from a different location"
    fi
}

# Run all prerequisite checks
# Called AFTER argument parsing so --help works without prerequisites
check_prerequisites() {
    check_bash_version
    check_claude_cli
    # Write permissions checked later when we know VAULT_DIR
}

# Check for optional tools (used for informational display)
check_optional_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${YELLOW}○${NC} $1 not found"
        return 1
    fi
}

# ============================================================================
# Main Installation
# ============================================================================

check_prerequisites

# Initialize ANSWERS array (after Bash 4.0+ verified by check_prerequisites)
declare -A ANSWERS

# Copy CLI flags to ANSWERS array (for non-interactive mode)
[[ -n "${CLI_NAME:-}" ]] && ANSWERS[name]="$CLI_NAME"
[[ -n "${CLI_VAULT_PATH:-}" ]] && ANSWERS[vault_path]="$CLI_VAULT_PATH"
[[ -n "${CLI_ROLE:-}" ]] && ANSWERS[role]="$CLI_ROLE"
[[ -n "${CLI_AREAS:-}" ]] && ANSWERS[areas]="$CLI_AREAS"
[[ -n "${CLI_PREFERENCES:-}" ]] && ANSWERS[preferences]="$CLI_PREFERENCES"

echo -e "${GREEN}✓${NC} Prerequisites validated"
echo ""

# Gum detection and install offer
offer_gum_install

# Run questionnaire (interactive or skip if flags provided)
if [[ "${SKIP_QUESTIONNAIRE:-false}" == "true" ]]; then
    echo "Skipping questionnaire (--no-questionnaire)"
    # Validate required fields
    if [[ -z "${ANSWERS[name]:-}" ]] || [[ -z "${ANSWERS[vault_path]:-}" ]]; then
        error_exit "Non-interactive mode requires --name and --vault-path" \
            "Run with: ./install.sh --name \"Your Name\" --vault-path \"/path/to/vault\""
    fi
elif ! is_interactive; then
    echo "Non-interactive mode detected."
    if [[ -z "${ANSWERS[name]:-}" ]] || [[ -z "${ANSWERS[vault_path]:-}" ]]; then
        error_exit "Non-interactive mode requires --name and --vault-path" \
            "Run with: ./install.sh --name \"Your Name\" --vault-path \"/path/to/vault\""
    fi
else
    run_questionnaire
fi

echo ""
echo "Installing Minervia..."
echo ""

# Use vault path from questionnaire, or fall back to current directory
VAULT_DIR="${ANSWERS[vault_path]:-$(pwd)}"
SKILLS_SOURCE="$(dirname "$0")/skills"
TEMPLATE_DIR="$(dirname "$0")/templates"

# Validate write permissions to vault directory
check_write_permissions "$VAULT_DIR"

# Validate skills source directory exists
if [[ ! -d "$SKILLS_SOURCE" ]]; then
    error_exit "Skills directory not found: $SKILLS_SOURCE" "Ensure you are running install.sh from the minervia-starter-kit directory"
fi

# Change to vault directory for installation operations
cd "$VAULT_DIR" || error_exit "Cannot access vault directory: $VAULT_DIR"

# Check if this is an Obsidian vault
if [ -d ".obsidian" ]; then
    echo -e "${GREEN}✓${NC} Obsidian vault detected"
else
    echo -e "${YELLOW}!${NC} No .obsidian folder found in ${VAULT_DIR}"
    echo "   Open this folder in Obsidian first to initialize it as a vault"
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
