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
Installs skills to ~/.claude/skills/ and agents to ~/.claude/agents/

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
  2. Delete agent directories: rm -rf ~/.claude/agents/pkm-*
  3. Optionally remove vault files:
     - CLAUDE.md (contains your customizations)
     - .minervia-initialized
     - .minervia-first-run
     - .claude/settings.json (if you want to remove hooks)
  4. Remove state directory: rm -rf ~/.minervia

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

# ============================================================================
# State Tracking
# ============================================================================

MINERVIA_STATE_DIR="$HOME/.minervia"
MINERVIA_STATE_FILE="$MINERVIA_STATE_DIR/state.json"
LOCK_FILE="$MINERVIA_STATE_DIR/.lock"

# Step IDs for completion tracking
STEP_QUESTIONNAIRE="questionnaire"
STEP_CLAUDEMD="claudemd"
STEP_SCAFFOLD="scaffold"
STEP_SKILLS="skills"
STEP_AGENTS="agents"

# Cross-platform MD5 computation
# Args: file_path
# Returns: 32-character MD5 hash (no filename)
compute_md5() {
    local file="$1"
    if [[ "$PLATFORM" == "macos" ]]; then
        md5 -q "$file"
    else
        md5sum "$file" | cut -d' ' -f1
    fi
}

# Initialize ~/.minervia/state.json
# Creates directory and state file if they don't exist
# Updates version if state file already exists
init_state_file() {
    # Create directory if needed
    if ! mkdir -p "$MINERVIA_STATE_DIR" 2>/dev/null; then
        echo -e "${YELLOW}!${NC} Could not create $MINERVIA_STATE_DIR" >&2
        return 1
    fi

    if [[ ! -f "$MINERVIA_STATE_FILE" ]]; then
        # Create new state file
        cat > "$MINERVIA_STATE_FILE" << EOF
{
  "version": "$VERSION",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "files": [],
  "completed_steps": []
}
EOF
    else
        # Update version in existing state file
        # Use portable_sed_inplace for cross-platform compatibility
        local temp_file
        temp_file=$(mktemp)
        TEMP_FILES+=("$temp_file")

        # Update version using awk (more portable than sed for in-place JSON)
        awk -v ver="$VERSION" '
            /"version":/ { gsub(/"version": *"[^"]*"/, "\"version\": \"" ver "\""); }
            { print }
        ' "$MINERVIA_STATE_FILE" > "$temp_file"

        mv "$temp_file" "$MINERVIA_STATE_FILE"
    fi
}

# Record an installed file in state.json manifest
# Args: relative_path (e.g., "skills/log-to-daily/SKILL.md"), absolute_path
record_installed_file() {
    local rel_path="$1"
    local abs_path="$2"

    # Compute MD5 of the installed file
    local checksum
    checksum=$(compute_md5 "$abs_path")

    # Create JSON entry
    local entry="{\"path\": \"$rel_path\", \"md5\": \"$checksum\"}"

    # Read current state file
    local temp_file
    temp_file=$(mktemp)
    TEMP_FILES+=("$temp_file")

    # Use awk to insert the new entry before the closing ] of files array
    awk -v entry="$entry" '
        BEGIN { found_files = 0; empty_array = 0 }
        /\"files\": *\[\]/ {
            # Empty array case - replace with array containing entry
            gsub(/\[\]/, "[" entry "]")
            print
            next
        }
        /\"files\": *\[/ { found_files = 1 }
        found_files && /\]/ {
            # Found closing bracket of files array
            # Check if we need a comma (array not empty)
            if (prev_line !~ /\[[ \t]*$/) {
                gsub(/\]/, ", " entry "]")
            } else {
                gsub(/\]/, entry "]")
            }
            found_files = 0
        }
        { prev_line = $0; print }
    ' "$MINERVIA_STATE_FILE" > "$temp_file"

    mv "$temp_file" "$MINERVIA_STATE_FILE"
}

# Check if a step is already completed
# Args: step_id
# Returns: 0 if complete, 1 if not
is_step_complete() {
    local step_id="$1"

    # Check state file exists
    [[ ! -f "$MINERVIA_STATE_FILE" ]] && return 1

    # Check for step in completed_steps array
    grep -q "\"step\": \"$step_id\"" "$MINERVIA_STATE_FILE" 2>/dev/null
}

# Mark a step as complete in state.json
# Args: step_id
mark_step_complete() {
    local step_id="$1"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local entry="{\"step\": \"$step_id\", \"completed_at\": \"$timestamp\"}"

    local temp_file
    temp_file=$(mktemp)
    TEMP_FILES+=("$temp_file")

    # Add entry to completed_steps array (similar to record_installed_file)
    awk -v entry="$entry" '
        /\"completed_steps\": *\[\]/ {
            gsub(/\[\]/, "[" entry "]")
            print
            next
        }
        /\"completed_steps\": *\[/ { found = 1 }
        found && /\]/ {
            if (prev !~ /\[[ \t]*$/) {
                gsub(/\]/, ", " entry "]")
            } else {
                gsub(/\]/, entry "]")
            }
            found = 0
        }
        { prev = $0; print }
    ' "$MINERVIA_STATE_FILE" > "$temp_file"

    mv "$temp_file" "$MINERVIA_STATE_FILE"
}

# Run a step if not already complete
# Args: step_id, step_name (display), step_function (to call)
# Returns: 0 if step completed (now or previously), non-zero on failure
run_step() {
    local step_id="$1"
    local step_name="$2"
    local step_function="$3"

    if is_step_complete "$step_id"; then
        echo -e "${GREEN}^${NC} $step_name (already completed)"
        return 0
    fi

    # Run the step
    "$step_function"
    local result=$?

    if [[ $result -eq 0 ]]; then
        mark_step_complete "$step_id"
    fi

    return $result
}

# ============================================================================
# Skills/Agents Installation Functions
# ============================================================================

# Handle file conflict when MD5 differs
# Args: source_path, target_path, display_name
# Returns: 0 if replaced, 1 if kept existing
handle_file_conflict() {
    local source_path="$1"
    local target_path="$2"
    local display_name="$3"

    echo ""
    echo "========================================"
    echo -e "${YELLOW}$display_name already exists and differs.${NC}"
    echo "========================================"
    echo ""
    echo "Differences between existing and new:"
    echo ""
    show_colored_diff "$target_path" "$source_path"
    echo ""
    echo "========================================"
    echo ""

    local action
    action=$(ask_choice "What would you like to do?" "Keep existing" "Backup and replace" "Replace (no backup)")

    case "$action" in
        "Keep existing")
            echo -e "${YELLOW}→${NC} $display_name (keeping existing)"
            return 1
            ;;
        "Backup and replace")
            local backup_name="${target_path}.backup-$(date +%Y%m%d-%H%M%S)"
            mv "$target_path" "$backup_name"
            echo -e "${GREEN}✓${NC} Backup created: $(basename "$backup_name")"
            cp "$source_path" "$target_path"
            echo -e "${GREEN}✓${NC} $display_name replaced"
            return 0
            ;;
        "Replace (no backup)")
            cp "$source_path" "$target_path"
            echo -e "${GREEN}✓${NC} $display_name replaced"
            return 0
            ;;
    esac
}

# Install a single file with conflict detection
# Args: source_path, target_path, display_name, relative_path (for state tracking)
# Returns: 0 if installed, 1 if skipped
install_single_file() {
    local source_path="$1"
    local target_path="$2"
    local display_name="$3"
    local rel_path="$4"

    # Ensure target directory exists
    local target_dir
    target_dir=$(dirname "$target_path")
    mkdir -p "$target_dir" 2>/dev/null || true

    if [[ ! -f "$target_path" ]]; then
        # Target doesn't exist - simple install
        if cp "$source_path" "$target_path" 2>/dev/null; then
            record_installed_file "$rel_path" "$target_path"
            echo -e "${GREEN}✓${NC} $display_name"
            return 0
        else
            echo -e "${RED}!${NC} Failed to install: $display_name" >&2
            return 2
        fi
    fi

    # Target exists - compare checksums
    local source_md5 target_md5
    source_md5=$(compute_md5 "$source_path")
    target_md5=$(compute_md5 "$target_path")

    if [[ "$source_md5" == "$target_md5" ]]; then
        # Files are identical - skip
        echo -e "${YELLOW}→${NC} $display_name (unchanged)"
        return 1
    fi

    # Files differ - handle conflict
    if handle_file_conflict "$source_path" "$target_path" "$display_name"; then
        record_installed_file "$rel_path" "$target_path"
        return 0
    else
        return 1
    fi
}

# Install all skills from source directory
# Uses install_single_file for each file in each skill directory
install_skills() {
    local source_dir="$1"
    local target_dir="$2"

    local installed=0
    local skipped=0
    local failed=0

    # Loop through skill directories
    for skill_dir in "$source_dir"/*/; do
        if [[ ! -d "$skill_dir" ]]; then
            continue
        fi

        local skill_name
        skill_name=$(basename "$skill_dir")

        # Loop through files in skill directory
        for file in "$skill_dir"*; do
            if [[ ! -f "$file" ]]; then
                continue
            fi

            local filename
            filename=$(basename "$file")
            local target_path="$target_dir/$skill_name/$filename"
            local rel_path="skills/$skill_name/$filename"
            local display_name="$skill_name/$filename"

            local result
            install_single_file "$file" "$target_path" "$display_name" "$rel_path"
            result=$?

            case $result in
                0) ((installed++)) || true ;;
                1) ((skipped++)) || true ;;
                2) ((failed++)) || true ;;
            esac
        done
    done

    echo ""
    echo -e "Skills: ${GREEN}$installed installed${NC}, ${YELLOW}$skipped unchanged${NC}"
    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}$failed failed${NC}"
    fi
}

# Install all agents from source directory
# Uses install_single_file for each file in each agent directory
install_agents() {
    local source_dir="$1"
    local target_dir="$2"

    # Gracefully handle missing agents directory
    if [[ ! -d "$source_dir" ]]; then
        echo "No agents directory found (skipping)"
        return 0
    fi

    local installed=0
    local skipped=0
    local failed=0

    # Loop through agent directories
    for agent_dir in "$source_dir"/*/; do
        if [[ ! -d "$agent_dir" ]]; then
            continue
        fi

        local agent_name
        agent_name=$(basename "$agent_dir")

        # Loop through files in agent directory
        for file in "$agent_dir"*; do
            if [[ ! -f "$file" ]]; then
                continue
            fi

            local filename
            filename=$(basename "$file")
            local target_path="$target_dir/$agent_name/$filename"
            local rel_path="agents/$agent_name/$filename"
            local display_name="$agent_name/$filename"

            local result
            install_single_file "$file" "$target_path" "$display_name" "$rel_path"
            result=$?

            case $result in
                0) ((installed++)) || true ;;
                1) ((skipped++)) || true ;;
                2) ((failed++)) || true ;;
            esac
        done
    done

    echo ""
    echo -e "Agents: ${GREEN}$installed installed${NC}, ${YELLOW}$skipped unchanged${NC}"
    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}$failed failed${NC}"
    fi
}

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

# Create PARA folder structure for new vaults
# Folders: 00 Daily/YYYY, 01 Inbox, 02 Projects, 03 Areas, 04 Resources, 04 Resources/Templates, 05 Archive
create_para_folders() {
    local folders=(
        "00 Daily/$(date +%Y)"
        "01 Inbox"
        "02 Projects"
        "03 Areas"
        "04 Resources"
        "04 Resources/Templates"
        "05 Archive"
    )

    for folder in "${folders[@]}"; do
        if mkdir -p "$folder" 2>/dev/null; then
            echo -e "${GREEN}+${NC} $folder"
        else
            echo -e "${RED}!${NC} Failed to create: $folder" >&2
        fi
    done
}

# Create starter templates for new vaults
# Templates use Obsidian core template syntax ({{date:...}}, {{title}})
create_templates() {
    local template_dir="04 Resources/Templates"

    # Daily Note template
    cat > "$template_dir/Daily Note.md" << 'TEMPLATE'
---
created: {{date:YYYY-MM-DD}}
tags: [daily]
---

# {{date:dddd, MMMM D, YYYY}}

## Focus

What's the main thing to accomplish today?

-

## Notes

## Reflection

**What went well:**

**What to improve:**
TEMPLATE
    echo -e "${GREEN}+${NC} Daily Note.md template"

    # Project template
    cat > "$template_dir/Project.md" << 'TEMPLATE'
---
created: {{date:YYYY-MM-DD}}
status: active
tags: [project]
due:
---

# {{title}}

## Overview

What is this project and why does it matter?

## Success Criteria

How will you know when this project is complete?

- [ ]

## Next Actions

- [ ]

## Notes

## Related

-
TEMPLATE
    echo -e "${GREEN}+${NC} Project.md template"

    # Area template
    cat > "$template_dir/Area.md" << 'TEMPLATE'
---
created: {{date:YYYY-MM-DD}}
tags: [area]
---

# {{title}}

## Purpose

Why is this area important? What responsibility does it represent?

## Standards

What does success look like in this area?

-

## Current Focus

What aspects need attention right now?

## Resources

Related projects, notes, and references.

-
TEMPLATE
    echo -e "${GREEN}+${NC} Area.md template"
}

# Create example notes in each PARA folder to explain purpose
# These are clearly marked as deletable examples
create_example_notes() {
    # Inbox example
    cat > "01 Inbox/Welcome to your Inbox.md" << 'EXAMPLE'
# Welcome to your Inbox

This folder is for quick capture - ideas, links, notes that haven't been organized yet.

**How to use:**
1. Capture anything here without worrying about organization
2. During your weekly review, process items:
   - Move to appropriate PARA folder
   - Delete if no longer relevant
   - Add to a project or area

**Tip:** Keep the inbox small. If it grows too large, it becomes overwhelming.
EXAMPLE
    echo -e "${GREEN}+${NC} Inbox example note"

    # Projects example
    cat > "02 Projects/Example Project.md" << 'EXAMPLE'
---
created: 2025-01-01
status: example
tags: [project, example]
due: 2025-03-01
---

# Example Project

> Delete this file once you understand the structure.

## Overview

Projects have a **deadline** and a clear **definition of done**. When complete, move them to Archive.

## Success Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] All criteria met = project complete

## Next Actions

- [ ] First actionable step
- [ ] Second step (add as you go)

## Notes

Add meeting notes, research, decisions here.

## Related

- [[Example Area]] - The area this project supports
EXAMPLE
    echo -e "${GREEN}+${NC} Projects example note"

    # Areas example
    cat > "03 Areas/Example Area.md" << 'EXAMPLE'
---
created: 2025-01-01
tags: [area, example]
---

# Example Area

> Delete this file once you understand the structure.

## Purpose

Areas are **ongoing responsibilities** without end dates. Examples:
- Health
- Finances
- Career
- Relationships
- Home

## Standards

What does "good enough" look like for this area?

- Standard 1
- Standard 2

## Current Focus

What aspects need attention right now?

## Related Projects

- [[Example Project]]
EXAMPLE
    echo -e "${GREEN}+${NC} Areas example note"

    # Archive example
    cat > "05 Archive/About the Archive.md" << 'EXAMPLE'
# About the Archive

This folder holds **completed projects** and **inactive items**.

**When to archive:**
- Project is complete (all success criteria met)
- Area is no longer relevant
- Reference material is outdated but worth keeping

**Archive structure:**
Some people organize by year (Archive/2025/), others keep it flat. Do what works for you.

**Remember:** Archived doesn't mean deleted. You can always search or move things back.
EXAMPLE
    echo -e "${GREEN}+${NC} Archive example note"
}

# Orchestrate PARA folder structure creation for new vaults
# Skips entirely for existing vaults (IS_NEW_VAULT check)
scaffold_new_vault() {
    if [[ "$IS_NEW_VAULT" != "true" ]]; then
        echo -e "${YELLOW}Skipping:${NC} Vault scaffolding (existing vault detected)"
        return 0
    fi

    echo ""
    echo "Creating PARA folder structure..."
    create_para_folders

    echo ""
    echo "Creating templates..."
    create_templates

    echo ""
    echo "Creating example notes..."
    create_example_notes

    echo ""
    echo -e "${GREEN}✓${NC} Vault scaffolding complete"
    echo ""
    echo -e "${YELLOW}Tip:${NC} Configure Obsidian to use templates:"
    echo "     Settings > Core plugins > Templates > Template folder: 04 Resources/Templates"
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
# Existing File Handling
# ============================================================================

# Display colored unified diff (macOS compatible - no --color flag)
# Args: existing_file, proposed_file
show_colored_diff() {
    local existing="$1"
    local proposed="$2"

    # Generate unified diff and colorize manually
    diff -u "$existing" "$proposed" | while IFS= read -r line; do
        case "$line" in
            ---*)
                echo -e "${RED}$line${NC}"
                ;;
            +++*)
                echo -e "${GREEN}$line${NC}"
                ;;
            @@*)
                echo -e "${YELLOW}$line${NC}"
                ;;
            -*)
                echo -e "${RED}$line${NC}"
                ;;
            +*)
                echo -e "${GREEN}$line${NC}"
                ;;
            *)
                echo "$line"
                ;;
        esac
    done
}

# Handle existing CLAUDE.md conflict
# Args: proposed_file (path to newly generated temp file)
handle_existing_claudemd() {
    local proposed_file="$1"

    echo ""
    echo "========================================"
    echo -e "${YELLOW}CLAUDE.md already exists in this vault.${NC}"
    echo "========================================"
    echo ""
    echo "Differences between existing and new:"
    echo ""
    show_colored_diff "CLAUDE.md" "$proposed_file"
    echo ""
    echo "========================================"
    echo ""

    local action
    if $HAS_GUM; then
        action=$(gum choose "Keep existing" "Backup and replace" "Replace (no backup)")
    else
        echo "What would you like to do?"
        echo "  1) Keep existing"
        echo "  2) Backup and replace"
        echo "  3) Replace (no backup)"
        while true; do
            read -p "Enter choice (1-3): " choice
            case "$choice" in
                1) action="Keep existing"; break ;;
                2) action="Backup and replace"; break ;;
                3) action="Replace (no backup)"; break ;;
                *) echo -e "${RED}Invalid selection. Enter 1, 2, or 3.${NC}" ;;
            esac
        done
    fi

    case "$action" in
        "Keep existing")
            echo -e "${GREEN}✓${NC} Keeping existing CLAUDE.md"
            rm -f "$proposed_file"
            ;;
        "Backup and replace")
            local backup_name="CLAUDE.md.backup-$(date +%Y%m%d-%H%M)"
            mv "CLAUDE.md" "$backup_name"
            echo -e "${GREEN}✓${NC} Backup created: $backup_name"
            mv "$proposed_file" "CLAUDE.md"
            echo -e "${GREEN}✓${NC} CLAUDE.md replaced with new version"
            ;;
        "Replace (no backup)")
            mv "$proposed_file" "CLAUDE.md"
            echo -e "${GREEN}✓${NC} CLAUDE.md replaced"
            ;;
    esac
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
AGENTS_SOURCE="$(dirname "$0")/agents"
TEMPLATE_DIR="$(dirname "$0")/templates"

# Validate write permissions to vault directory
check_write_permissions "$VAULT_DIR"

# Validate skills source directory exists
if [[ ! -d "$SKILLS_SOURCE" ]]; then
    error_exit "Skills directory not found: $SKILLS_SOURCE" "Ensure you are running install.sh from the minervia-starter-kit directory"
fi

# Change to vault directory for installation operations
cd "$VAULT_DIR" || error_exit "Cannot access vault directory: $VAULT_DIR"

# Detect vault type (new vs existing)
detect_vault_type

# Create PARA structure for new vaults
scaffold_new_vault

# Check if this is an Obsidian vault
if [ -d ".obsidian" ]; then
    echo -e "${GREEN}✓${NC} Obsidian vault detected"
else
    echo -e "${YELLOW}!${NC} No .obsidian folder found in ${VAULT_DIR}"
    echo "   Open this folder in Obsidian first to initialize it as a vault"
    echo ""
fi

# Initialize state tracking before any installation
echo "Initializing state tracking..."
init_state_file
echo -e "${GREEN}✓${NC} State tracking initialized (~/.minervia/state.json)"

# Install skills and agents to user's Claude Code directory
SKILLS_TARGET="$HOME/.claude/skills"
AGENTS_TARGET="$HOME/.claude/agents"

echo ""
echo "Installing Minervia skills..."
install_skills "$SKILLS_SOURCE" "$SKILLS_TARGET"

echo ""
echo "Installing Minervia agents..."
install_agents "$AGENTS_SOURCE" "$AGENTS_TARGET"

# Generate CLAUDE.md from template
echo ""
echo "Generating personalized CLAUDE.md..."

# Check template exists
if [[ ! -f "$TEMPLATE_DIR/CLAUDE.md.template" ]]; then
    error_exit "Template not found: $TEMPLATE_DIR/CLAUDE.md.template" \
        "Ensure you are running install.sh from the minervia-starter-kit directory"
fi

# Generate to temp file first
TEMP_CLAUDEMD=$(mktemp)
TEMP_FILES+=("$TEMP_CLAUDEMD")
process_template "$TEMPLATE_DIR/CLAUDE.md.template" "$TEMP_CLAUDEMD"

if [[ -f "CLAUDE.md" ]]; then
    # Existing file - show diff and prompt
    handle_existing_claudemd "$TEMP_CLAUDEMD"
else
    # New file - just move into place
    mv "$TEMP_CLAUDEMD" "CLAUDE.md"
    echo -e "${GREEN}✓${NC} CLAUDE.md created"
    echo ""
    echo -e "${YELLOW}!${NC} Edit CLAUDE.md to add your tools and update weekly focus"
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
echo "Agents installed to: $AGENTS_TARGET"
echo ""
if [ "$FIRST_RUN" = true ]; then
    echo -e "${GREEN}Tip:${NC} Your first Claude session will show a welcome guide!"
    echo ""
fi
echo "Learn more at: https://github.com/aplaceforallmystuff/minervia-starter-kit"
echo ""
