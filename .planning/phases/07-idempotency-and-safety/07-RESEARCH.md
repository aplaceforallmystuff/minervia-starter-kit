# Phase 7: Idempotency and Safety - Research

**Researched:** 2026-01-18
**Domain:** Bash idempotency patterns, CLI progress feedback, destructive action safety
**Confidence:** HIGH

## Summary

Phase 7 makes the Minervia installer safe to re-run by implementing skip detection for completed steps, progress feedback during execution, and confirmation prompts before destructive actions. The technical challenge is extending the existing state.json infrastructure to track not just files but also major installation steps.

The installer already has core patterns for this phase:
- `~/.minervia/state.json` tracks installed files with checksums
- `.minervia-initialized` marker file detects first run
- `ask_confirm()` and `ask_choice()` provide confirmation UI with Gum/fallback
- `show_colored_diff()` and `handle_file_conflict()` handle destructive file operations

The main work is:
1. Add step-level completion tracking to state.json
2. Wrap major operations with skip detection
3. Add spinner/progress indicators with Gum fallback
4. Add -v/--verbose flag for detailed output
5. Ensure all file overwrites have backup + confirmation

**Primary recommendation:** Extend state.json with a `completed_steps` array tracking step IDs and timestamps. Wrap each major step with a check-then-execute pattern. Use `gum spin` for progress with plain text fallback.

## Standard Stack

The established tools for this domain:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Gum spin | 0.14+ | Spinner during operations | Already used in project, elegant fallback pattern |
| state.json | - | Step completion tracking | Already exists, just needs extension |
| marker files | - | Simple completion flags | POSIX pattern, used for .minervia-initialized |
| Bash conditionals | - | Skip detection | Pure Bash, no dependencies |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `date +%Y%m%d-%H%M%S` | Backup timestamps | Unique backup names |
| `diff -u` | File comparison | Show what will change |
| `printf` | Progress messages | Fallback when no Gum |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| state.json steps | Separate marker files | More files to manage; state.json is cleaner |
| Gum spin | Pure Bash spinner | Less elegant, but works without dependencies |
| .bak extension | Timestamped backups | .bak simpler but overwrites previous backups |

**No additional installation required** - all tools already in the codebase.

## Architecture Patterns

### Recommended State File Extension

```json
{
  "version": "1.0.0",
  "installed_at": "2026-01-18T10:30:00Z",
  "files": [
    {"path": "skills/log-to-daily/SKILL.md", "md5": "abc123..."}
  ],
  "completed_steps": [
    {"step": "questionnaire", "completed_at": "2026-01-18T10:30:00Z"},
    {"step": "claudemd", "completed_at": "2026-01-18T10:30:05Z"},
    {"step": "scaffold", "completed_at": "2026-01-18T10:30:10Z"},
    {"step": "skills", "completed_at": "2026-01-18T10:30:15Z"},
    {"step": "agents", "completed_at": "2026-01-18T10:30:20Z"}
  ],
  "questionnaire_answers": {
    "name": "Jane",
    "vault_path": "/Users/jane/vault",
    "role": "Developer",
    "areas": "Software Development,Research",
    "preferences": "Concise responses,Direct communication"
  }
}
```

### Pattern 1: Step Skip Detection

**What:** Check state.json before running each major step, skip if already done
**When to use:** Every major installer operation

```bash
# Check if step is already completed
# Args: step_id
# Returns: 0 if complete, 1 if not
is_step_complete() {
    local step_id="$1"

    # Check state file exists
    [[ ! -f "$MINERVIA_STATE_FILE" ]] && return 1

    # Check for step in completed_steps array
    grep -q "\"step\": \"$step_id\"" "$MINERVIA_STATE_FILE"
}

# Mark step as complete
# Args: step_id
mark_step_complete() {
    local step_id="$1"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Add to completed_steps array in state.json
    # (Use existing awk pattern from record_installed_file)
}

# Skip-aware step wrapper
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
```

### Pattern 2: Gum Spinner with Fallback

**What:** Show spinner during operations with plain text fallback
**When to use:** Any operation that takes more than 1 second

```bash
# Run command with spinner (Gum or fallback)
# Args: title, command...
with_spinner() {
    local title="$1"
    shift
    local cmd=("$@")

    if $HAS_GUM; then
        gum spin --spinner dot --title "$title" -- "${cmd[@]}"
    else
        echo -n "$title... "
        if "${cmd[@]}" >/dev/null 2>&1; then
            echo "[OK]"
        else
            echo "[FAIL]"
            return 1
        fi
    fi
}

# Usage
with_spinner "Installing skills" install_skills_internal "$SKILLS_SOURCE" "$SKILLS_TARGET"
```

### Pattern 3: Progress Feedback (ASCII Fallback)

**What:** Clear status indicators when Gum not available
**When to use:** Status messages, step completion

```bash
# Status indicators (work in any terminal)
# GREEN check for success
# YELLOW arrow for skipped
# RED X for failed

show_status() {
    local status="$1"
    local message="$2"

    case "$status" in
        ok|success)
            echo -e "${GREEN}[OK]${NC} $message"
            ;;
        skip|skipped)
            echo -e "${YELLOW}[SKIP]${NC} $message"
            ;;
        fail|failed)
            echo -e "${RED}[FAIL]${NC} $message"
            ;;
        info)
            echo -e "[INFO] $message"
            ;;
    esac
}
```

### Pattern 4: Verbose Flag Implementation

**What:** Add -v/--verbose for detailed sub-step output
**When to use:** When user wants to see what's happening

```bash
# Global verbose flag (default: false)
VERBOSE=false

# Verbose output helper
verbose() {
    if $VERBOSE; then
        echo "  $*"
    fi
}

# In parse_args():
-v|--verbose)
    VERBOSE=true
    ;;

# Usage in install functions:
install_single_file() {
    # ...
    verbose "Checking checksum for $display_name"
    # ...
    verbose "Source MD5: $source_md5"
    verbose "Target MD5: $target_md5"
}
```

### Pattern 5: Re-run Questionnaire Detection

**What:** Detect saved answers and offer edit vs full re-run
**When to use:** When installer is run again with existing state

```bash
# Check for saved questionnaire answers
has_saved_answers() {
    [[ -f "$MINERVIA_STATE_FILE" ]] && \
    grep -q '"questionnaire_answers"' "$MINERVIA_STATE_FILE"
}

# Load answers from state file
load_saved_answers() {
    # Parse JSON and populate ANSWERS array
    # Using existing awk patterns
}

# Main questionnaire logic
if has_saved_answers; then
    load_saved_answers
    show_summary

    local action
    action=$(ask_choice "Use these settings?" "Continue with saved" "Edit answers" "Start fresh")

    case "$action" in
        "Continue with saved")
            # Proceed with loaded answers
            ;;
        "Edit answers")
            # Show summary, allow field edits (existing pattern)
            ;;
        "Start fresh")
            run_questionnaire
            ;;
    esac
else
    run_questionnaire
fi
```

### Pattern 6: Backup Before Overwrite

**What:** Always create timestamped backup before destructive operations
**When to use:** Any file overwrite

```bash
# Create backup with timestamp
# Args: file_path
# Returns: backup path on stdout
create_backup() {
    local file="$1"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local backup="${file}.backup-${timestamp}"

    if cp "$file" "$backup" 2>/dev/null; then
        echo "$backup"
        return 0
    else
        return 1
    fi
}

# Usage in handle_file_conflict:
"Backup and replace")
    local backup_path
    backup_path=$(create_backup "$target_path")
    echo -e "${GREEN}^${NC} Backup: $backup_path"
    cp "$source_path" "$target_path"
    ;;
```

### Anti-Patterns to Avoid

- **Don't check only marker files** - Use state.json for unified tracking
- **Don't skip silently** - Always report what was skipped and why
- **Don't assume previous state is valid** - Validate state.json structure
- **Don't overwrite without backup** - Every destructive action needs recovery path
- **Don't use blocking prompts for non-destructive actions** - Only prompt when necessary
- **Don't batch confirmations** - Per CONTEXT.md, always prompt individually for conflicts

## Don't Hand-Roll

Problems with existing solutions to use:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON parsing | Custom regex | Existing awk patterns | Already proven in state.json code |
| User prompts | Raw read | Existing ask_choice, ask_confirm | Gum integration, consistent UI |
| Diff display | Custom diff | Existing show_colored_diff | Already handles macOS quirks |
| File conflict UI | Custom prompts | Existing handle_file_conflict | Established pattern |
| Backup naming | Static .bak | `$(date +%Y%m%d-%H%M%S)` pattern | Already used for CLAUDE.md |
| Platform detection | New checks | Existing $PLATFORM | Set at startup |

**Key insight:** Phase 6 established all the patterns. Phase 7 wraps them with skip detection and progress feedback.

## Common Pitfalls

### Pitfall 1: State File Corruption Handling

**What goes wrong:** Corrupted state.json breaks installer on re-run
**Why it happens:** Power loss, disk issues, manual editing errors
**How to avoid:** Validate JSON structure, backup and recreate if invalid
**Warning signs:** `grep` or `awk` fail on state.json

```bash
# Validate state file structure
validate_state_file() {
    local file="$1"

    # Check file exists and has content
    [[ ! -s "$file" ]] && return 1

    # Check for required fields
    grep -q '"version"' "$file" || return 1
    grep -q '"files"' "$file" || return 1

    # Check JSON is well-formed (basic bracket matching)
    local open_braces close_braces
    open_braces=$(grep -o '{' "$file" | wc -l)
    close_braces=$(grep -o '}' "$file" | wc -l)
    [[ "$open_braces" -eq "$close_braces" ]] || return 1

    return 0
}

# Handle corrupted state
if ! validate_state_file "$MINERVIA_STATE_FILE"; then
    echo -e "${YELLOW}!${NC} State file corrupted, backing up and recreating"
    mv "$MINERVIA_STATE_FILE" "${MINERVIA_STATE_FILE}.corrupted-$(date +%Y%m%d)"
    init_state_file
fi
```

### Pitfall 2: Race Condition on Re-run

**What goes wrong:** Two installer instances run simultaneously
**Why it happens:** User double-clicks, script in loop
**How to avoid:** Use lock file or check for running process
**Warning signs:** Duplicate files, corrupted state

```bash
# Simple lock file approach
LOCK_FILE="$MINERVIA_STATE_DIR/.lock"

acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid
        pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            error_exit "Another installer is running (PID $pid)" \
                "Wait for it to complete or remove $LOCK_FILE"
        fi
        # Stale lock file, remove it
        rm -f "$LOCK_FILE"
    fi
    echo $$ > "$LOCK_FILE"
}

release_lock() {
    rm -f "$LOCK_FILE"
}

# Add to cleanup trap
trap 'release_lock; cleanup' EXIT
```

### Pitfall 3: Spinner Blocking Output

**What goes wrong:** Gum spin hides command output, errors invisible
**Why it happens:** Default gum spin captures stdout/stderr
**How to avoid:** Use --show-error or capture output appropriately
**Warning signs:** Silent failures during spinner operations

```bash
# For operations that might fail
if $HAS_GUM; then
    output=$(gum spin --show-error --title "$title" -- "${cmd[@]}" 2>&1)
    result=$?
    if [[ $result -ne 0 ]]; then
        echo -e "${RED}!${NC} $title failed"
        echo "$output"
    fi
else
    # Fallback shows output naturally
    "${cmd[@]}"
fi
```

### Pitfall 4: Partial Step Completion

**What goes wrong:** Step marked complete but only partially succeeded
**Why it happens:** Error in middle of step, state updated before completion
**How to avoid:** Mark complete only after full success, use atomic operations
**Warning signs:** Re-run skips step but files are missing

```bash
# Mark complete AFTER all operations succeed
install_skills() {
    local installed=0
    local failed=0

    for skill_dir in "$source_dir"/*/; do
        if ! install_skill "$skill_dir"; then
            ((failed++))
        else
            ((installed++))
        fi
    done

    # Only mark complete if no failures
    if [[ $failed -eq 0 ]]; then
        mark_step_complete "skills"
        return 0
    else
        echo -e "${YELLOW}!${NC} $failed skills failed to install"
        return 1
    fi
}
```

### Pitfall 5: Verbose Output Overwhelming

**What goes wrong:** Verbose mode produces so much output it's unusable
**Why it happens:** Every single operation logged
**How to avoid:** Structure verbose output, use indentation
**Warning signs:** Scrolling pages of output

```bash
# Structured verbose output
verbose_step() {
    if $VERBOSE; then
        echo "  $*"
    fi
}

verbose_detail() {
    if $VERBOSE; then
        echo "    $*"
    fi
}

# Usage
echo "Installing skills..."
verbose_step "Scanning $SKILLS_SOURCE"
for skill_dir in "$source_dir"/*/; do
    verbose_detail "Found: $(basename "$skill_dir")"
done
```

## Code Examples

Verified patterns from the existing codebase and research.

### Complete Step Wrapper Implementation

```bash
# Source: Based on existing install.sh patterns + idempotency research

# Step IDs (canonical names for state tracking)
STEP_QUESTIONNAIRE="questionnaire"
STEP_CLAUDEMD="claudemd"
STEP_SCAFFOLD="scaffold"
STEP_SKILLS="skills"
STEP_AGENTS="agents"
STEP_HOOKS="hooks"

# Check if step is already completed
is_step_complete() {
    local step_id="$1"

    [[ ! -f "$MINERVIA_STATE_FILE" ]] && return 1

    # Use grep to check for step in completed_steps
    grep -q "\"step\": \"$step_id\"" "$MINERVIA_STATE_FILE" 2>/dev/null
}

# Mark step as complete in state.json
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

# Main wrapper - runs step if not complete
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
```

### Progress Spinner Implementation

```bash
# Source: Based on Gum documentation + existing HAS_GUM pattern

# Run operation with visual feedback
# Args: title, description (for verbose), command...
run_with_progress() {
    local title="$1"
    local description="$2"
    shift 2

    verbose "$description"

    if $HAS_GUM; then
        # Use gum spin with error capture
        local output
        output=$(gum spin --spinner dot --title "$title" --show-error -- "$@" 2>&1)
        local result=$?

        if [[ $result -eq 0 ]]; then
            echo -e "${GREEN}[OK]${NC} $title"
        else
            echo -e "${RED}[FAIL]${NC} $title"
            [[ -n "$output" ]] && echo "  $output" >&2
        fi
        return $result
    else
        # Plain text fallback
        echo -n "$title... "
        if "$@" >/dev/null 2>&1; then
            echo -e "${GREEN}[OK]${NC}"
            return 0
        else
            echo -e "${RED}[FAIL]${NC}"
            return 1
        fi
    fi
}
```

### Final Summary Display

```bash
# Source: Based on CONTEXT.md requirement for final summary

# Display installation summary
show_final_summary() {
    local installed="$1"
    local skipped="$2"
    local failed="$3"

    echo ""
    echo "======================================="
    echo "Installation Summary"
    echo "======================================="
    echo ""

    if $HAS_GUM; then
        gum style --border normal --padding "0 2" \
            "Installed: $installed" \
            "Skipped:   $skipped" \
            "Failed:    $failed"
    else
        echo -e "  ${GREEN}Installed:${NC} $installed"
        echo -e "  ${YELLOW}Skipped:${NC}   $skipped"
        [[ $failed -gt 0 ]] && echo -e "  ${RED}Failed:${NC}    $failed"
    fi

    echo ""
}
```

### Saved Answers Detection

```bash
# Source: Based on CONTEXT.md re-run behavior

# Store questionnaire answers in state.json
save_questionnaire_answers() {
    # Read current state
    local temp_file
    temp_file=$(mktemp)
    TEMP_FILES+=("$temp_file")

    # Build answers JSON
    local answers_json
    answers_json=$(cat << EOF
"questionnaire_answers": {
    "name": "${ANSWERS[name]:-}",
    "vault_path": "${ANSWERS[vault_path]:-}",
    "role": "${ANSWERS[role]:-}",
    "areas": "${ANSWERS[areas]:-}",
    "preferences": "${ANSWERS[preferences]:-}"
  }
EOF
)

    # Insert into state.json before closing brace
    awk -v answers="$answers_json" '
        /^}$/ {
            print "  ," answers
        }
        { print }
    ' "$MINERVIA_STATE_FILE" > "$temp_file"

    mv "$temp_file" "$MINERVIA_STATE_FILE"
}

# Check for and load saved answers
handle_saved_answers() {
    if ! has_saved_answers; then
        return 1  # No saved answers
    fi

    load_saved_answers
    echo ""
    echo "Found saved configuration:"
    show_summary

    local action
    action=$(ask_choice "What would you like to do?" \
        "Use saved settings" \
        "Edit settings" \
        "Start fresh")

    case "$action" in
        "Use saved settings")
            return 0
            ;;
        "Edit settings")
            if ! confirm_summary; then
                run_questionnaire
            fi
            return 0
            ;;
        "Start fresh")
            run_questionnaire
            return 0
            ;;
    esac
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Marker files per step | Unified state.json | Phase 6 | Single source of truth |
| Silent skip | Visible skip messages | Best practice | User knows what happened |
| No backup | Timestamped backups | Always | Recovery possible |
| Pure text progress | Gum spinners w/fallback | Gum adoption | Better UX where available |

**Deprecated/outdated:**
- Single `.done` marker file for entire install (too coarse-grained)
- Asking user every time about all options (save and reuse answers)
- Static .bak files (can overwrite previous backups)

## Open Questions

Things that couldn't be fully resolved:

1. **Should --force flag re-run completed steps?**
   - What we know: CONTEXT.md says Claude's discretion
   - What's unclear: Whether to add flag or just document state file deletion
   - Recommendation: Add --force for convenience, simpler than manual state editing

2. **How to handle state.json format upgrades?**
   - What we know: v1 has files array only, v2 adds completed_steps
   - What's unclear: Migration path for existing users
   - Recommendation: Check for `completed_steps` key, add if missing (backward compatible)

3. **Should verbose show spinner internals?**
   - What we know: Verbose means more output
   - What's unclear: Does verbose override spinner to show underlying commands?
   - Recommendation: In verbose mode, skip spinners and show actual command output

## Sources

### Primary (HIGH confidence)
- Existing install.sh patterns (state.json, ask_choice, show_colored_diff)
- .planning/phases/07-idempotency-and-safety/07-CONTEXT.md (user decisions)
- [Charmbracelet Gum](https://github.com/charmbracelet/gum) - gum spin documentation
- [How to Write Idempotent Bash Scripts](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/) - Idempotency patterns

### Secondary (MEDIUM confidence)
- [Baeldung - Ensure Only One Instance](https://www.baeldung.com/linux/bash-ensure-instance-running) - Lock file patterns
- [ShellHacks - Yes/No Prompt](https://www.shellhacks.com/yes-no-bash-script-prompt-confirmation/) - Confirmation patterns
- [LinuxVox - Timestamp Backup Names](https://linuxvox.com/blog/append-the-time-stamp-to-a-file-name-in-ubuntu/) - Backup naming

### Tertiary (LOW confidence)
- None - all findings verified against existing codebase or authoritative sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using only existing tools from codebase
- Architecture: HIGH - Extending proven patterns from Phase 6
- Pitfalls: HIGH - Based on real issues in idempotency literature and codebase constraints

**Research date:** 2026-01-18
**Valid until:** 60 days (stable domain, patterns well-established)
