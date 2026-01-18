#!/bin/bash
set -euo pipefail

# ============================================================================
# Minervia Update Utility
# ============================================================================
# Installed to: ~/.minervia/bin/minervia-update.sh
# Invoked via: /minervia:update skill or directly
# https://github.com/aplaceforallmystuff/minervia-starter-kit
# ============================================================================

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Constants
REPO_URL="https://github.com/aplaceforallmystuff/minervia-starter-kit.git"
MINERVIA_STATE_DIR="$HOME/.minervia"
MINERVIA_STATE_FILE="$MINERVIA_STATE_DIR/state.json"
BACKUP_DIR="$MINERVIA_STATE_DIR/backups"
TEMP_DIR=""

# Detect script location (works whether invoked from repo or ~/.minervia/bin)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Flags
DRY_RUN=false
VERBOSE=false

# Arrays for tracking file status
declare -a CUSTOMIZED_FILES=()
declare -a PRISTINE_FILES=()
declare -a NEW_FILES=()

# ============================================================================
# Cleanup
# ============================================================================

cleanup() {
    [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
    return 0
}
trap cleanup EXIT INT TERM

# ============================================================================
# Helper Functions
# ============================================================================

# Verbose output - only prints if VERBOSE is true
verbose() {
    if $VERBOSE; then
        echo "  $*"
    fi
}

# Cross-platform MD5 computation
compute_md5() {
    local file="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        md5 -q "$file"
    else
        md5sum "$file" | cut -d' ' -f1
    fi
}

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

# Display usage information
show_help() {
    cat << 'EOF'
Usage: minervia-update.sh [OPTIONS]

Check for and apply Minervia updates while preserving customizations.

Options:
  --dry-run         Preview changes without applying them
  -v, --verbose     Show detailed progress for each step
  --list-backups    List available backup timestamps
  --restore TS      Restore from backup with timestamp TS
  -h, --help        Show this help message

Examples:
  minervia-update.sh                  Check and apply updates
  minervia-update.sh --dry-run        Preview what would change
  minervia-update.sh --list-backups   Show available backups
  minervia-update.sh --restore 2026-01-18T10-30-00

The update process:
  1. Fetches latest version from GitHub
  2. Compares with installed version
  3. Creates backup before any changes
  4. Detects customized files (via checksum comparison)
  5. For conflicts, prompts for resolution
  6. Applies updates to pristine files

Backups are stored in: ~/.minervia/backups/
EOF
}

# ============================================================================
# Version Functions
# ============================================================================

# Get installed version from state.json
get_installed_version() {
    if [[ ! -f "$MINERVIA_STATE_FILE" ]]; then
        echo "0.0.0"
        return
    fi
    grep -o '"version": *"[^"]*"' "$MINERVIA_STATE_FILE" | cut -d'"' -f4
}

# Get version from fetched install.sh
get_remote_version() {
    if [[ -z "$TEMP_DIR" || ! -f "$TEMP_DIR/install.sh" ]]; then
        echo "0.0.0"
        return
    fi
    local version
    version=$(grep -m1 '^readonly VERSION=' "$TEMP_DIR/install.sh" 2>/dev/null | cut -d'"' -f2)
    if [[ -z "$version" ]]; then
        # Fallback: try without readonly keyword
        version=$(grep -m1 '^VERSION=' "$TEMP_DIR/install.sh" 2>/dev/null | cut -d'"' -f2)
    fi
    echo "${version:-0.0.0}"
}

# Fetch latest version to temp directory
fetch_latest() {
    TEMP_DIR=$(mktemp -d)
    verbose "Temp directory: $TEMP_DIR"

    echo "Fetching latest version..."

    # Capture git output for error reporting
    local git_output
    if git_output=$(git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>&1); then
        verbose "Clone complete"
        return 0
    else
        verbose "Git clone failed: $git_output"
        echo -e "${RED}Failed to fetch updates${NC}"
        return 1
    fi
}

# Compare two version strings
# Returns 0 if remote is newer, 1 otherwise
is_newer_version() {
    local installed="$1"
    local remote="$2"

    # Same version is not newer
    [[ "$installed" == "$remote" ]] && return 1

    # Try sort -V for version sorting (works on both GNU and modern BSD/macOS)
    if printf '1.0\n2.0\n' | sort -V 2>/dev/null | head -1 | grep -q '1.0'; then
        local newest
        newest=$(printf '%s\n%s\n' "$installed" "$remote" | sort -V | tail -1)
        [[ "$newest" == "$remote" ]]
    else
        # Fallback: basic numeric comparison for x.y.z versions
        local inst_parts remote_parts
        IFS='.' read -ra inst_parts <<< "$installed"
        IFS='.' read -ra remote_parts <<< "$remote"

        for i in 0 1 2; do
            local inst_val="${inst_parts[$i]:-0}"
            local remote_val="${remote_parts[$i]:-0}"
            if [[ "$remote_val" -gt "$inst_val" ]]; then
                return 0
            elif [[ "$remote_val" -lt "$inst_val" ]]; then
                return 1
            fi
        done
        return 1  # Equal
    fi
}

# ============================================================================
# Path Resolution
# ============================================================================

# Resolve relative path from manifest to absolute path
resolve_path() {
    local rel_path="$1"

    if [[ "$rel_path" == skills/* ]] || [[ "$rel_path" == agents/* ]]; then
        echo "$HOME/.claude/$rel_path"
    else
        # Vault files - get vault path from state.json
        local vault_path
        vault_path=$(grep -o '"vault_path": "[^"]*"' "$MINERVIA_STATE_FILE" 2>/dev/null | cut -d'"' -f4 | head -1)
        if [[ -n "$vault_path" ]]; then
            echo "$vault_path/$rel_path"
        else
            # Fallback to current directory
            echo "$PWD/$rel_path"
        fi
    fi
}

# ============================================================================
# Backup Functions
# ============================================================================

# Create timestamped backup of all tracked files
create_backup() {
    local timestamp
    timestamp=$(date +%Y-%m-%dT%H-%M-%S)
    local backup_path="$BACKUP_DIR/$timestamp"

    # Create backup directory
    if ! mkdir -p "$backup_path"; then
        error_exit "Failed to create backup directory" "Check write permissions for $BACKUP_DIR"
    fi

    verbose "Backup directory: $backup_path"

    # Read files from state.json manifest
    if [[ ! -f "$MINERVIA_STATE_FILE" ]]; then
        echo "No state file found - nothing to backup"
        echo "$backup_path"
        return 0
    fi

    local backed_up=0

    # Parse files array from state.json
    while IFS= read -r rel_path; do
        [[ -z "$rel_path" ]] && continue

        local abs_path
        abs_path=$(resolve_path "$rel_path")

        [[ ! -f "$abs_path" ]] && continue

        # Create directory structure in backup
        local dest="$backup_path/$rel_path"
        mkdir -p "$(dirname "$dest")"

        if cp "$abs_path" "$dest" 2>/dev/null; then
            verbose "  Backed up: $rel_path"
            ((backed_up++))
        fi
    done < <(grep -o '"path": "[^"]*"' "$MINERVIA_STATE_FILE" | cut -d'"' -f4)

    echo "Backed up $backed_up files to $backup_path"
    echo "$backup_path"
}

# List available backups with file counts
list_backups() {
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        echo "No backups found"
        echo ""
        echo "Backups are created automatically before updates."
        echo "Location: $BACKUP_DIR"
        return 0
    fi

    echo "Available backups:"
    echo ""

    for dir in "$BACKUP_DIR"/*/; do
        [[ ! -d "$dir" ]] && continue

        local timestamp
        timestamp=$(basename "$dir")

        local count
        count=$(find "$dir" -type f 2>/dev/null | wc -l | tr -d ' ')

        echo "  $timestamp ($count files)"
    done

    echo ""
    echo "To restore: ./minervia-update.sh --restore TIMESTAMP"
}

# Restore files from a specific backup
# Args: backup_timestamp
restore_backup() {
    local backup_timestamp="$1"
    local backup_path="$BACKUP_DIR/$backup_timestamp"

    if [[ ! -d "$backup_path" ]]; then
        echo -e "${RED}Backup not found: $backup_timestamp${NC}"
        echo ""
        echo "Available backups:"
        list_backups
        return 1
    fi

    echo "Restore from backup: $backup_timestamp"
    echo ""

    # Count files to restore
    local file_count
    file_count=$(find "$backup_path" -type f | wc -l | tr -d ' ')
    echo "Files to restore: $file_count"
    echo ""

    # Preview files
    echo "Files:"
    find "$backup_path" -type f | while read -r file; do
        local rel_path="${file#$backup_path/}"
        echo "  - $rel_path"
    done

    echo ""
    read -p "Restore these files? (y/N) " confirm
    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        echo "Restore cancelled"
        return 0
    fi

    echo ""
    echo "Restoring..."

    local restored=0
    local failed=0

    # Restore each file
    while IFS= read -r file; do
        local rel_path="${file#$backup_path/}"
        local target
        target=$(resolve_path "$rel_path")

        mkdir -p "$(dirname "$target")"

        if cp "$file" "$target" 2>/dev/null; then
            echo -e "${GREEN}+${NC} Restored: $rel_path"
            ((restored++))
        else
            echo -e "${RED}!${NC} Failed: $rel_path"
            ((failed++))
        fi
    done < <(find "$backup_path" -type f)

    echo ""
    echo -e "${GREEN}Restore complete${NC}"
    echo "Restored: $restored files"
    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}Failed: $failed files${NC}"
    fi
}

# ============================================================================
# Customization Detection Functions
# ============================================================================

# Display colored unified diff (macOS compatible)
show_colored_diff() {
    local existing="$1"
    local proposed="$2"

    diff -u "$existing" "$proposed" 2>/dev/null | while IFS= read -r line; do
        case "$line" in
            ---*) echo -e "${RED}$line${NC}" ;;
            +++*) echo -e "${GREEN}$line${NC}" ;;
            @@*)  echo -e "${YELLOW}$line${NC}" ;;
            -*)   echo -e "${RED}$line${NC}" ;;
            +*)   echo -e "${GREEN}$line${NC}" ;;
            *)    echo "$line" ;;
        esac
    done
}

# Single selection from options (Gum with fallback)
ask_choice() {
    local prompt="$1"
    shift
    local options=("$@")

    if command -v gum &>/dev/null; then
        gum choose --header "$prompt" "${options[@]}"
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
                echo "${options[$((choice-1))]}"
                return 0
            fi
            echo "Invalid selection."
        done
    fi
}

# Check if installed file differs from manifest checksum
# Args: relative_path, absolute_path
# Returns: 0 if customized (differs), 1 if pristine (matches) or missing
is_file_customized() {
    local rel_path="$1"
    local abs_path="$2"

    [[ ! -f "$abs_path" ]] && return 1

    local current_md5
    current_md5=$(compute_md5 "$abs_path")

    # Get stored MD5 from state.json
    local stored_md5
    stored_md5=$(grep -A1 "\"path\": \"$rel_path\"" "$MINERVIA_STATE_FILE" 2>/dev/null | \
                 grep '"md5"' | cut -d'"' -f4)

    [[ -z "$stored_md5" ]] && return 1  # Not in manifest = not customized

    [[ "$current_md5" != "$stored_md5" ]]
}

# Scan all installed files for customizations
# Populates CUSTOMIZED_FILES, PRISTINE_FILES, NEW_FILES arrays
scan_for_customizations() {
    CUSTOMIZED_FILES=()
    PRISTINE_FILES=()
    NEW_FILES=()

    # Scan files in state.json manifest
    while IFS= read -r rel_path; do
        [[ -z "$rel_path" ]] && continue

        local abs_path
        abs_path=$(resolve_path "$rel_path")

        if is_file_customized "$rel_path" "$abs_path"; then
            CUSTOMIZED_FILES+=("$rel_path")
            verbose "  Customized: $rel_path"
        else
            PRISTINE_FILES+=("$rel_path")
            verbose "  Pristine: $rel_path"
        fi
    done < <(grep -o '"path": "[^"]*"' "$MINERVIA_STATE_FILE" | cut -d'"' -f4)

    # Check for new files in remote that aren't in manifest
    if [[ -d "$TEMP_DIR/skills" ]]; then
        for skill_dir in "$TEMP_DIR/skills"/*/; do
            [[ ! -d "$skill_dir" ]] && continue
            local skill_name
            skill_name=$(basename "$skill_dir")
            for file in "$skill_dir"*; do
                [[ ! -f "$file" ]] && continue
                local filename rel_path="skills/$skill_name/$(basename "$file")"
                if ! grep -q "\"path\": \"$rel_path\"" "$MINERVIA_STATE_FILE" 2>/dev/null; then
                    NEW_FILES+=("$rel_path")
                    verbose "  New: $rel_path"
                fi
            done
        done
    fi

    echo "  Customized: ${#CUSTOMIZED_FILES[@]} files"
    echo "  Unchanged:  ${#PRISTINE_FILES[@]} files"
    echo "  New:        ${#NEW_FILES[@]} files"
}

# Handle a single customized file conflict
# Args: relative_path
# Returns: 0 if updated, 1 if kept existing
handle_customized_file() {
    local rel_path="$1"
    local current_file new_file

    current_file=$(resolve_path "$rel_path")
    new_file="$TEMP_DIR/$rel_path"

    [[ ! -f "$new_file" ]] && return 1  # No new version

    echo ""
    echo "========================================"
    echo -e "${YELLOW}Conflict: $rel_path${NC}"
    echo "========================================"
    echo ""

    show_colored_diff "$current_file" "$new_file"

    echo ""

    local action
    action=$(ask_choice "How to resolve?" \
        "Keep mine (skip update)" \
        "Take theirs (overwrite)" \
        "Backup + overwrite")

    case "$action" in
        "Keep mine"*)
            echo -e "${YELLOW}Keeping your version${NC}"
            return 1
            ;;
        "Take theirs"*)
            cp "$new_file" "$current_file"
            echo -e "${GREEN}Updated to new version${NC}"
            return 0
            ;;
        "Backup + overwrite"*)
            local backup="${current_file}.backup-$(date +%Y%m%d-%H%M%S)"
            cp "$current_file" "$backup"
            echo "Backed up to: $backup"
            cp "$new_file" "$current_file"
            echo -e "${GREEN}Updated to new version${NC}"
            return 0
            ;;
    esac
}

# Handle all customized files with merge strategies
handle_customized_files() {
    if [[ ${#CUSTOMIZED_FILES[@]} -eq 0 ]]; then
        echo "No customized files to handle"
        return 0
    fi

    # Preview all conflicts first (per CONTEXT.md)
    echo ""
    echo "Conflicts detected:"
    for file in "${CUSTOMIZED_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""

    read -p "Press Enter to resolve each conflict..."

    local updated=0
    local kept=0

    for file in "${CUSTOMIZED_FILES[@]}"; do
        if handle_customized_file "$file"; then
            ((updated++))
        else
            ((kept++))
        fi
    done

    echo ""
    echo "Conflicts resolved: $updated updated, $kept kept"
}

# ============================================================================
# Update Application Functions
# ============================================================================

# Extract and show changelog highlights between versions
# Args: from_version, to_version
show_changelog_highlights() {
    local from_version="$1"
    local to_version="$2"
    local changelog_file="$TEMP_DIR/CHANGELOG.md"

    if [[ ! -f "$changelog_file" ]]; then
        verbose "No CHANGELOG.md found"
        return 0
    fi

    echo "What's new in v$to_version:"
    echo ""

    # Extract relevant section using awk
    # Look for entries between to_version and from_version
    awk -v from="$from_version" -v to="$to_version" '
        BEGIN { printing = 0; found = 0 }
        /^## \[/ {
            # Extract version from header like "## [1.2.0]"
            gsub(/^## \[|\].*$/, "")
            current = $0
            if (current == to) { printing = 1; found = 1; next }
            if (current == from) { printing = 0 }
        }
        printing && /^### / { print $0 }
        printing && /^- / { print "  " $0 }
    ' "$changelog_file" | head -15

    echo ""
}

# Apply updates to pristine files and new files
apply_updates() {
    local updated=0
    local installed=0
    local failed=0

    echo ""
    echo "Applying updates..."

    # Update pristine files (no conflict)
    for rel_path in "${PRISTINE_FILES[@]}"; do
        local current_file new_file
        current_file=$(resolve_path "$rel_path")
        new_file="$TEMP_DIR/$rel_path"

        [[ ! -f "$new_file" ]] && continue

        # Check if file actually changed in remote
        local current_md5 new_md5
        current_md5=$(compute_md5 "$current_file" 2>/dev/null || echo "")
        new_md5=$(compute_md5 "$new_file")

        if [[ "$current_md5" == "$new_md5" ]]; then
            verbose "  Unchanged: $rel_path"
            continue
        fi

        # Create directory if needed
        mkdir -p "$(dirname "$current_file")"

        if cp "$new_file" "$current_file" 2>/dev/null; then
            echo -e "${GREEN}+${NC} Updated: $rel_path"
            ((updated++))
        else
            echo -e "${RED}!${NC} Failed: $rel_path"
            ((failed++))
        fi
    done

    # Install new files
    for rel_path in "${NEW_FILES[@]}"; do
        local target_file new_file
        target_file=$(resolve_path "$rel_path")
        new_file="$TEMP_DIR/$rel_path"

        [[ ! -f "$new_file" ]] && continue

        mkdir -p "$(dirname "$target_file")"

        if cp "$new_file" "$target_file" 2>/dev/null; then
            echo -e "${GREEN}+${NC} Installed: $rel_path"
            ((installed++))
        else
            echo -e "${RED}!${NC} Failed: $rel_path"
            ((failed++))
        fi
    done

    echo ""
    echo "Updated: $updated files"
    echo "Installed: $installed new files"
    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}Failed: $failed files${NC}"
    fi
}

# Update version in state.json after successful update
update_state_version() {
    local new_version="$1"
    local temp_file
    temp_file=$(mktemp)

    awk -v ver="$new_version" '
        /"version":/ { gsub(/"version": *"[^"]*"/, "\"version\": \"" ver "\"") }
        { print }
    ' "$MINERVIA_STATE_FILE" > "$temp_file"

    mv "$temp_file" "$MINERVIA_STATE_FILE"
    verbose "Updated state.json version to $new_version"
}

# ============================================================================
# Argument Parsing
# ============================================================================

# Parse before main to allow --help without prerequisites
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            ;;
        -v|--verbose)
            VERBOSE=true
            ;;
        --list-backups)
            list_backups
            exit 0
            ;;
        --restore)
            if [[ -z "${2:-}" ]]; then
                echo "Usage: --restore TIMESTAMP"
                list_backups
                exit 1
            fi
            restore_backup "$2"
            exit $?
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "Run 'minervia-update.sh --help' for usage" >&2
            exit 2
            ;;
        *)
            echo "Unexpected argument: $1" >&2
            exit 2
            ;;
    esac
    shift
done

# ============================================================================
# Main
# ============================================================================

main() {
    echo "Minervia Update"
    echo "==============="
    echo ""

    # Check state file exists
    if [[ ! -f "$MINERVIA_STATE_FILE" ]]; then
        error_exit "No Minervia installation found" "Run install.sh first"
    fi

    # Fetch latest version
    if ! fetch_latest; then
        error_exit "Failed to fetch updates" "Check your internet connection"
    fi

    # Compare versions
    local installed_version remote_version
    installed_version=$(get_installed_version)
    remote_version=$(get_remote_version)

    echo ""
    echo "Installed: v$installed_version"
    echo "Latest:    v$remote_version"
    echo ""

    if [[ "$installed_version" == "$remote_version" ]]; then
        echo -e "${GREEN}Already up to date${NC}"
        return 0
    fi

    if ! is_newer_version "$installed_version" "$remote_version"; then
        echo -e "${YELLOW}Installed version is newer than remote${NC}"
        return 0
    fi

    echo -e "${GREEN}Update available: v$installed_version -> v$remote_version${NC}"
    echo ""

    # Show changelog highlights
    show_changelog_highlights "$installed_version" "$remote_version"

    # Dry run stops here
    if $DRY_RUN; then
        echo ""
        echo "[Dry run - no changes made]"
        echo ""
        # Preview what would be updated
        scan_for_customizations
        return 0
    fi

    # Scan for customizations
    echo ""
    echo "Scanning for customized files..."
    scan_for_customizations

    # Create backup
    echo ""
    echo "Creating backup..."
    local backup_path
    backup_path=$(create_backup)

    # Handle customized files (prompt for each)
    handle_customized_files

    # Apply updates
    apply_updates

    # Update version in state.json
    update_state_version "$remote_version"

    echo ""
    echo -e "${GREEN}Update complete${NC}"
    echo "Backup saved to: $backup_path"
}

# Run main
main
