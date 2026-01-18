#!/bin/bash
set -euo pipefail

# ============================================================================
# Minervia Update Utility
# ============================================================================
# Self-update mechanism for Minervia installations
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

# Flags
DRY_RUN=false
VERBOSE=false

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

# List available backups
list_backups() {
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        echo "No backups found"
        return 0
    fi

    echo "Available backups:"
    for dir in "$BACKUP_DIR"/*/; do
        [[ ! -d "$dir" ]] && continue
        local timestamp
        timestamp=$(basename "$dir")
        local count
        count=$(find "$dir" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo "  $timestamp ($count files)"
    done
}

# Restore from a specific backup (stub for Plan 02)
restore_backup() {
    local backup_timestamp="$1"
    echo "Restore not implemented yet"
    echo "Will restore from: $BACKUP_DIR/$backup_timestamp"
    return 1
}

# ============================================================================
# Stub Functions (to be implemented in Plan 02)
# ============================================================================

scan_for_customizations() {
    verbose "Scanning for customized files..."
    echo "TODO: Scan for customizations"
    return 0
}

handle_customized_files() {
    verbose "Handling customized files..."
    echo "TODO: Handle customized files"
    return 0
}

apply_updates() {
    verbose "Applying updates..."
    echo "TODO: Apply updates"
    return 0
}

show_changelog_highlights() {
    local from_version="$1"
    local to_version="$2"
    verbose "Showing changelog from $from_version to $to_version"
    echo "TODO: Show changelog highlights"
    return 0
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
                error_exit "Missing timestamp for --restore" "Usage: --restore TIMESTAMP"
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

    # Show changelog highlights (stub)
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

    # Handle customized files (prompt for each - stub)
    handle_customized_files

    # Apply updates (stub)
    apply_updates

    # Update version in state.json
    # (Will be implemented in Plan 02)

    echo ""
    echo -e "${GREEN}Update complete${NC}"
    echo "Backup saved to: $backup_path"
}

# Run main
main
