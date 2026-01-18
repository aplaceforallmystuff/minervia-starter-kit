# Phase 6: Skills Installation - Research

**Researched:** 2026-01-18
**Domain:** Bash file installation, checksums, JSON state management
**Confidence:** HIGH

## Summary

Phase 6 implements a file installation system that copies skills and agents from the repository to the user's global `~/.claude/` directory, with state tracking in `~/.minervia/state.json`. The core technical challenges are:

1. **Cross-platform MD5 checksums** - macOS uses `md5` while Linux uses `md5sum`, with different output formats
2. **JSON state file generation** - Creating well-formed JSON in pure Bash without external dependencies
3. **File conflict resolution** - Interactive prompts when existing files are found

The existing install.sh already has patterns for platform detection, colored output, and interactive prompts that this phase will extend.

**Primary recommendation:** Use pure Bash for JSON generation via heredocs and `printf`, with a portable MD5 wrapper function that handles macOS/Linux differences. Leverage existing `ask_choice` for conflict resolution UI.

## Standard Stack

The established tools for this domain:

### Core
| Tool | Purpose | Why Standard |
|------|---------|--------------|
| `md5` / `md5sum` | Checksums | Built into macOS/Linux respectively, fast, sufficient for change detection |
| Heredocs + printf | JSON generation | Zero dependencies, portable, already used in existing codebase |
| `mkdir -p` | Directory creation | POSIX standard, idempotent, handles nested paths |
| `cp -r` | File copying | POSIX standard, already used for skill installation |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `date -u +%Y-%m-%dT%H:%M:%SZ` | ISO timestamps | Recording installed_at time |
| `stat` | File metadata | Getting file sizes for manifest (optional) |
| `diff` | Change detection | Showing user what differs in existing files |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| MD5 | SHA256 | SHA256 is more secure but slower; MD5 is fine for change detection (not security) |
| Pure Bash JSON | jq | jq requires external dependency; now ships with macOS Sequoia but not older versions |
| File-per-state | SQLite | SQLite adds complexity for simple key-value storage |

**No additional installation required** - this phase uses only POSIX tools and Bash builtins.

## Architecture Patterns

### Recommended Project Structure

The existing install.sh is monolithic. Extend it with new functions in logical sections:

```
install.sh
├── [existing] Color/utility functions
├── [existing] Input functions (ask_text, ask_choice, etc.)
├── [existing] Questionnaire flow
├── [existing] Template processing
├── [existing] CLAUDEMD handling
├── [NEW] MD5 checksum wrapper
├── [NEW] State file management
├── [NEW] Skills installation with conflicts
├── [NEW] Agents installation
└── [existing] Main installation flow (extended)
```

### Pattern 1: Cross-Platform MD5 Wrapper

**What:** Portable function that returns just the hash, regardless of platform
**When to use:** Every time a checksum is needed for state tracking

```bash
# Returns only the MD5 hash (32 hex characters)
# Works on both macOS (md5) and Linux (md5sum)
get_md5() {
    local file="$1"
    if [[ "$PLATFORM" == "macos" ]]; then
        # macOS: md5 -q returns just the hash
        md5 -q "$file"
    else
        # Linux: md5sum outputs "hash  filename", cut to get hash only
        md5sum "$file" | cut -d' ' -f1
    fi
}
```

**Why this pattern:**
- `md5 -q` on macOS outputs just the hash (no filename)
- `md5sum` on Linux outputs `hash  filename`, requiring `cut`
- Using existing `$PLATFORM` variable from `detect_platform()`

### Pattern 2: JSON Generation Without jq

**What:** Generate valid JSON using heredocs with careful escaping
**When to use:** Creating/updating state.json

```bash
# Generate state.json with file manifest
# Uses heredoc for structure, printf for escaping
generate_state_json() {
    local version="$1"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    cat << EOF
{
  "version": "$version",
  "installed_at": "$timestamp",
  "files": [
$(generate_files_array)
  ]
}
EOF
}

# Generate the files array portion
generate_files_array() {
    local first=true
    local checksum path

    for file in "${INSTALLED_FILES[@]}"; do
        [[ "$first" == "true" ]] || printf ',\n'
        first=false

        path="${file#$HOME/}"  # Store relative to $HOME
        checksum=$(get_md5 "$file")

        printf '    {"path": "~/%s", "md5": "%s"}' "$path" "$checksum"
    done
}
```

**Key considerations:**
- Use `cat << EOF` for structure readability
- Handle JSON comma placement carefully (no trailing comma)
- Store paths relative to `$HOME` with `~` prefix for portability
- Escape any user-provided strings that might contain JSON special characters

### Pattern 3: File Conflict Resolution

**What:** Interactive prompt when target file exists, with checksum comparison
**When to use:** Before overwriting any existing skill or agent

```bash
# Handle file conflict with user choice
# Returns: 0=proceed with overwrite, 1=skip, 2=backup+overwrite
handle_file_conflict() {
    local source_file="$1"
    local target_file="$2"
    local file_name
    file_name=$(basename "$target_file")

    # First check if files are identical
    local source_md5 target_md5
    source_md5=$(get_md5 "$source_file")
    target_md5=$(get_md5 "$target_file")

    if [[ "$source_md5" == "$target_md5" ]]; then
        echo -e "${GREEN}=${NC} $file_name (unchanged)"
        return 1  # Skip, no action needed
    fi

    # Files differ - prompt user
    echo ""
    echo -e "${YELLOW}Conflict:${NC} $file_name already exists and differs"

    local action
    action=$(ask_choice "What would you like to do?" \
        "Keep existing" \
        "Overwrite" \
        "Backup and overwrite")

    case "$action" in
        "Keep existing")
            return 1
            ;;
        "Overwrite")
            return 0
            ;;
        "Backup and overwrite")
            return 2
            ;;
    esac
}
```

### Pattern 4: State File Location

**What:** Use `~/.minervia/state.json` as single source of truth
**When to use:** Always for tracking installation state

```bash
STATE_DIR="$HOME/.minervia"
STATE_FILE="$STATE_DIR/state.json"

ensure_state_dir() {
    if ! mkdir -p "$STATE_DIR" 2>/dev/null; then
        error_exit "Cannot create state directory: $STATE_DIR" \
            "Check permissions for $HOME"
    fi
}
```

### Anti-Patterns to Avoid

- **Don't use jq for JSON generation** - Adds external dependency; not available on all systems
- **Don't store absolute paths in state.json** - Use `~` notation for portability across systems
- **Don't skip unchanged files silently** - Always report what was skipped and why
- **Don't create backup with static name** - Use timestamp to avoid overwriting previous backups
- **Don't trust existing state.json blindly** - Validate structure before parsing

## Don't Hand-Roll

Problems with existing solutions to use:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Platform detection | Custom uname parsing | Existing `detect_platform()` | Already implemented in install.sh |
| User prompts | Raw read commands | Existing `ask_choice()`, `ask_confirm()` | Gum integration, consistent UI |
| Colored output | Custom ANSI codes | Existing `$GREEN`, `$YELLOW`, etc. | Already defined |
| Error handling | Random exits | Existing `error_exit()` | Consistent recovery messages |
| File backup naming | Static names | `$(date +%Y%m%d-%H%M%S)` pattern | Already used for CLAUDE.md backups |

**Key insight:** The existing install.sh has robust patterns for all UI interactions. Phase 6 should extend, not replace.

## Common Pitfalls

### Pitfall 1: JSON Comma Placement

**What goes wrong:** Generated JSON has trailing comma in arrays, making it invalid
**Why it happens:** Looping through items and adding comma after each one
**How to avoid:** Use "first item" flag or build array, join with commas
**Warning signs:** `jq` or JSON parsers fail on state.json

```bash
# WRONG: Always adds comma
for file in "${files[@]}"; do
    printf '{"path": "%s"},\n' "$file"
done

# RIGHT: Track first item
local first=true
for file in "${files[@]}"; do
    [[ "$first" == "true" ]] || printf ',\n'
    first=false
    printf '{"path": "%s"}' "$file"
done
```

### Pitfall 2: Unescaped Strings in JSON

**What goes wrong:** User paths with quotes or backslashes break JSON
**Why it happens:** Direct interpolation without escaping
**How to avoid:** Escape JSON special characters or avoid problematic paths
**Warning signs:** Paths like `My "Documents"` cause parse errors

```bash
# Escape string for JSON (minimal - handles common cases)
json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"  # Backslash
    str="${str//\"/\\\"}"  # Double quote
    str="${str//$'\n'/\\n}"  # Newline
    printf '%s' "$str"
}
```

### Pitfall 3: Partial Installation State

**What goes wrong:** Installer fails mid-way, state.json reflects incomplete install
**Why it happens:** Writing state before all operations complete
**How to avoid:** Collect manifest in memory, write state.json only after success
**Warning signs:** state.json lists files that don't exist

```bash
# Track installed files in array during installation
INSTALLED_FILES=()

# After each successful install
INSTALLED_FILES+=("$target_path")

# Only write state.json after all operations succeed
if [[ ${#INSTALLED_FILES[@]} -gt 0 ]]; then
    write_state_file
fi
```

### Pitfall 4: Forgetting Agents Directory

**What goes wrong:** Skills installed but agents are not
**Why it happens:** Agents live in `.claude/agents/` not `.claude/skills/`
**How to avoid:** Treat agents as separate install step with own loop
**Warning signs:** Agents not available in Claude Code

```bash
# Skills target
SKILLS_TARGET="$HOME/.claude/skills"

# Agents target (different directory!)
AGENTS_TARGET="$HOME/.claude/agents"
```

### Pitfall 5: Hardcoded VERSION

**What goes wrong:** state.json version doesn't match actual release
**Why it happens:** Forgetting to update VERSION constant
**How to avoid:** VERSION is already defined at top of install.sh - reuse it
**Warning signs:** State shows "1.0.0" even after updates

```bash
# Use existing VERSION constant (already defined)
readonly VERSION="1.0.0"

# In state generation
generate_state_json "$VERSION"
```

## Code Examples

Verified patterns from the existing codebase and research.

### Complete Skills Installation Function

```bash
# Source: Based on existing install.sh patterns
install_skills() {
    local skills_source="$1"
    local skills_target="$HOME/.claude/skills"

    echo ""
    echo "Installing skills..."

    # Create target directory
    if ! mkdir -p "$skills_target" 2>/dev/null; then
        error_exit "Failed to create skills directory: $skills_target" \
            "Check write permissions for $HOME/.claude/"
    fi

    local installed=0
    local skipped=0

    for skill_dir in "$skills_source"/*/; do
        [[ -d "$skill_dir" ]] || continue

        local skill_name
        skill_name=$(basename "$skill_dir")
        local target_dir="$skills_target/$skill_name"

        if [[ -d "$target_dir" ]]; then
            # Check if contents differ
            local source_md5 target_md5
            source_md5=$(get_md5 "$skill_dir/SKILL.md" 2>/dev/null || echo "")
            target_md5=$(get_md5 "$target_dir/SKILL.md" 2>/dev/null || echo "")

            if [[ "$source_md5" == "$target_md5" && -n "$source_md5" ]]; then
                echo -e "${GREEN}=${NC} $skill_name (unchanged)"
                ((skipped++))
                continue
            fi

            # Files differ - prompt user
            local action
            action=$(handle_file_conflict "$skill_dir/SKILL.md" "$target_dir/SKILL.md")

            case $action in
                1)  # Skip
                    echo -e "${YELLOW}-${NC} $skill_name (kept existing)"
                    ((skipped++))
                    continue
                    ;;
                2)  # Backup
                    local backup="$target_dir.backup-$(date +%Y%m%d-%H%M%S)"
                    mv "$target_dir" "$backup"
                    echo -e "${GREEN}+${NC} Backup: $backup"
                    ;;
                # 0 = proceed with overwrite (fall through)
            esac

            rm -rf "$target_dir"
        fi

        # Copy skill
        if cp -r "$skill_dir" "$target_dir" 2>/dev/null; then
            echo -e "${GREEN}+${NC} $skill_name"
            INSTALLED_FILES+=("$target_dir/SKILL.md")
            ((installed++))
        else
            echo -e "${RED}!${NC} Failed to install: $skill_name" >&2
        fi
    done

    echo ""
    echo "Skills: $installed installed, $skipped skipped"
}
```

### State File Writer

```bash
# Source: Pattern from .planning/research/ARCHITECTURE.md
write_state_file() {
    ensure_state_dir

    local temp_file
    temp_file=$(mktemp)
    TEMP_FILES+=("$temp_file")

    generate_state_json "$VERSION" > "$temp_file"

    # Atomic write
    mv "$temp_file" "$STATE_FILE"
    echo -e "${GREEN}+${NC} State saved to $STATE_FILE"
}
```

### Complete Agents Installation Function

```bash
# Source: Based on existing patterns, adapted for agents
install_agents() {
    local agents_source="$1"
    local agents_target="$HOME/.claude/agents"

    # Check if source exists
    if [[ ! -d "$agents_source" ]]; then
        echo -e "${YELLOW}!${NC} No agents to install"
        return 0
    fi

    echo ""
    echo "Installing agents..."

    # Create target directory
    if ! mkdir -p "$agents_target" 2>/dev/null; then
        error_exit "Failed to create agents directory: $agents_target" \
            "Check write permissions for $HOME/.claude/"
    fi

    local installed=0
    local skipped=0

    for agent_file in "$agents_source"/*.md; do
        [[ -f "$agent_file" ]] || continue

        local agent_name
        agent_name=$(basename "$agent_file")
        local target_file="$agents_target/$agent_name"

        if [[ -f "$target_file" ]]; then
            # Check if contents differ
            local source_md5 target_md5
            source_md5=$(get_md5 "$agent_file")
            target_md5=$(get_md5 "$target_file")

            if [[ "$source_md5" == "$target_md5" ]]; then
                echo -e "${GREEN}=${NC} $agent_name (unchanged)"
                ((skipped++))
                continue
            fi

            # Prompt for conflict
            local result
            handle_file_conflict "$agent_file" "$target_file"
            result=$?

            case $result in
                1)  # Skip
                    echo -e "${YELLOW}-${NC} $agent_name (kept existing)"
                    ((skipped++))
                    continue
                    ;;
                2)  # Backup
                    local backup="${target_file%.md}.backup-$(date +%Y%m%d-%H%M%S).md"
                    mv "$target_file" "$backup"
                    echo -e "${GREEN}+${NC} Backup: $(basename "$backup")"
                    ;;
            esac
        fi

        # Copy agent
        if cp "$agent_file" "$target_file" 2>/dev/null; then
            echo -e "${GREEN}+${NC} $agent_name"
            INSTALLED_FILES+=("$target_file")
            ((installed++))
        else
            echo -e "${RED}!${NC} Failed to install: $agent_name" >&2
        fi
    done

    echo ""
    echo "Agents: $installed installed, $skipped skipped"
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SHA256 everywhere | MD5 for change detection | Ongoing | MD5 is faster and sufficient when not security-critical |
| jq required | Pure Bash JSON generation | jq now in macOS Sequoia | Still prefer pure Bash for broader compatibility |
| Single VERSION file | state.json manifest | Current best practice | Enables component-level tracking and user modification detection |

**Current best practice:**
- Use MD5 for file change detection (fast, sufficient)
- Use SHA256 only when cryptographic security matters (not this use case)
- jq ships with macOS Sequoia but pure Bash is more portable
- Store paths with `~` prefix for cross-system portability

## Open Questions

Things that couldn't be fully resolved:

1. **Should we track file sizes in manifest?**
   - What we know: MD5 alone detects changes
   - What's unclear: Whether file size helps with debugging or reporting
   - Recommendation: Skip for now, can add in Phase 8 if needed

2. **What if ~/.minervia/ already exists with different format?**
   - What we know: Phase 6 creates new state.json
   - What's unclear: How to handle legacy or corrupted state files
   - Recommendation: Back up existing state.json before overwriting, log warning

3. **Should agents source be .claude/agents/ or a dedicated folder?**
   - What we know: Agents currently live in `.claude/agents/` in the repo
   - What's unclear: Whether to mirror repo structure or use flat `agents/` folder
   - Recommendation: Keep current structure (`.claude/agents/`), copy to `~/.claude/agents/`

## Sources

### Primary (HIGH confidence)
- Existing install.sh patterns (file operations, UI, platform detection)
- .planning/research/ARCHITECTURE.md (state file structure)
- .planning/research/STACK.md (version comparison patterns)

### Secondary (MEDIUM confidence)
- [phoenixNAP MD5 Guide](https://phoenixnap.com/kb/md5sum-linux) - Linux md5sum usage
- [Raam Dev macOS MD5](https://raamdev.com/2010/mac-os-x-replicating-md5sum-output-format/) - macOS md5 format differences
- [Baeldung JSON in Bash](https://www.baeldung.com/linux/bash-variables-create-json-string) - Pure Bash JSON generation
- [jq Download Page](https://jqlang.org/download/) - jq availability by platform
- [Cloudflare semver_bash](https://github.com/cloudflare/semver_bash) - Bash semver patterns

### Tertiary (LOW confidence)
- None - all findings verified with authoritative sources or existing codebase

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Uses only POSIX/Bash tools already in install.sh
- Architecture: HIGH - Patterns derived from existing codebase structure
- Pitfalls: HIGH - Based on real-world JSON/checksum issues in documentation

**Research date:** 2026-01-18
**Valid until:** 60 days (stable domain, no fast-moving dependencies)
