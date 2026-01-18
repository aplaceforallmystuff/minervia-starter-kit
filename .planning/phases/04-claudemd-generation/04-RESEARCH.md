# Phase 4: CLAUDE.md Generation - Research

**Researched:** 2026-01-18
**Domain:** Bash template processing, file generation, diff display
**Confidence:** HIGH

## Summary

Phase 4 transforms questionnaire answers into a personalized CLAUDE.md file. The current implementation uses an embedded heredoc that ignores user answers entirely. This phase will introduce:

1. An external template file at `templates/CLAUDE.md.template`
2. Placeholder substitution using sed (avoiding envsubst dependency)
3. New vs existing vault detection based on folder emptiness
4. Diff display and user prompts before overwriting existing files

The key architectural insight: Claude Code's CLAUDE.md works best when kept concise (under 150-200 instructions) with universally applicable context. The template should focus on WHO the user is, not HOW Minervia works (that's static documentation).

**Primary recommendation:** Use `{{PLACEHOLDER}}` syntax with sed substitution, pure bash directory detection, and simple unified diff output with manual ANSI coloring.

## Standard Stack

### Core
| Tool | Purpose | Why Standard |
|------|---------|--------------|
| sed | Placeholder substitution | POSIX standard, no dependencies |
| diff -u | Unified diff format | Universal, readable output |
| bash arrays | Directory content checking | Already required (Bash 4.0+) |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| portable_sed_inplace | In-place file editing | Already in install.sh |
| ANSI escape codes | Colorized diff output | Already used for status messages |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| sed | envsubst | Not installed by default on macOS; requires gettext |
| sed | Perl | Not POSIX guaranteed; overkill for simple substitution |
| sed | pure bash ${var//pattern/replacement} | More complex escaping, harder to maintain |

**Installation:**
No additional dependencies required.

## Architecture Patterns

### Recommended Code Structure

The Phase 4 code should be inserted into install.sh at the current CLAUDE.md creation block (lines 786-878).

```
install.sh flow:
├── ... prerequisites, questionnaire ...
├── VAULT_DIR set from ANSWERS[vault_path]
├── cd "$VAULT_DIR"
├── detect_vault_type()        # NEW: Is this new or existing vault?
├── generate_claudemd()        # NEW: Template processing
│   ├── load template
│   ├── substitute placeholders
│   └── handle existing file (diff, prompt, backup)
└── ... skills installation, git setup ...
```

### Pattern 1: Placeholder Syntax with `{{PLACEHOLDER}}`

**What:** Use double-brace syntax like `{{NAME}}` for template variables
**When to use:** All user-provided values from questionnaire
**Why:** Avoids conflicts with shell variables, markdown, YAML, and Obsidian syntax

**Example:**
```bash
# Template content
This is {{NAME}}'s personal knowledge management vault.

# Substitution
sed "s/{{NAME}}/${ANSWERS[name]}/g" "$template"
```

**Available placeholders from ANSWERS array:**
| Key | Content | Usage in CLAUDE.md |
|-----|---------|-------------------|
| `name` | User's name | "This is Jane's vault..." |
| `vault_path` | Full path | Not needed in CLAUDE.md (implicit) |
| `role` | Role/profession | "Business/Role" section |
| `areas` | Comma-separated areas | "Key Contexts" section |
| `preferences` | Comma-separated prefs | "Working Preferences" section |

### Pattern 2: Multi-value Formatting

**What:** Convert comma-separated values to bullet lists
**When to use:** areas and preferences fields

**Example:**
```bash
# Input: "Content Creation,Research,Consulting"
# Output:
# - Content Creation
# - Research
# - Consulting

format_as_bullets() {
    local csv="$1"
    if [[ -z "$csv" ]]; then
        echo "[Not specified]"
        return
    fi
    echo "$csv" | tr ',' '\n' | sed 's/^/- /'
}
```

### Pattern 3: New vs Existing Vault Detection

**What:** Determine if vault is empty (new) or has content (existing)
**When to use:** Before CLAUDE.md generation to customize messaging

**Example:**
```bash
# Check for non-hidden files only (hidden files like .git, .obsidian are okay)
detect_vault_type() {
    local dir="$1"
    shopt -s nullglob
    local files=("$dir"/*)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        IS_NEW_VAULT=true
        echo -e "${GREEN}Detected:${NC} New vault (empty directory)"
    else
        IS_NEW_VAULT=false
        echo -e "${YELLOW}Detected:${NC} Existing vault (${#files[@]} items)"
    fi
}
```

### Pattern 4: Diff Display with Manual Coloring

**What:** Show unified diff with ANSI colors (macOS diff lacks --color)
**When to use:** When CLAUDE.md already exists

**Example:**
```bash
# macOS diff doesn't support --color, so we colorize manually
show_colored_diff() {
    local existing="$1"
    local proposed="$2"

    diff -u "$existing" "$proposed" | while IFS= read -r line; do
        case "$line" in
            ---*) echo -e "${RED}$line${NC}" ;;
            +++*) echo -e "${GREEN}$line${NC}" ;;
            @@*) echo -e "${YELLOW}$line${NC}" ;;
            -*) echo -e "${RED}$line${NC}" ;;
            +*) echo -e "${GREEN}$line${NC}" ;;
            *) echo "$line" ;;
        esac
    done
}
```

### Anti-Patterns to Avoid

- **Using envsubst:** Not installed by default on macOS; creates new dependency
- **Embedded heredoc with 'CLAUDEMD':** Single-quoted heredoc prevents all variable expansion
- **diff --color:** Not supported on macOS BSD diff
- **Including .git/.obsidian in "empty" check:** These are infrastructure, not user content

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sed escaping | Manual escaping | Quote properly | `${var//\//\\/}` escapes slashes |
| Date formatting | Custom format code | `date +%Y%m%d-%H%M` | portable_date already exists |
| File backup | Complex logic | Simple timestamped copy | `cp file file.backup-$(date +...)` |
| Color output | New color vars | Existing GREEN/RED/NC | Already defined in install.sh |

**Key insight:** The install.sh already has error_exit, portable_sed_inplace, color codes, and ask_confirm. Reuse these.

## Common Pitfalls

### Pitfall 1: Sed Delimiter Conflicts

**What goes wrong:** User enters value containing `/` (like a file path), breaking sed
**Why it happens:** sed uses `/` as default delimiter
**How to avoid:** Use `#` as delimiter, or escape slashes in values
**Warning signs:** "sed: -e expression" errors

```bash
# WRONG: breaks if ANSWERS[name] contains /
sed "s/{{NAME}}/${ANSWERS[name]}/g"

# RIGHT: use # delimiter
sed "s#{{NAME}}#${ANSWERS[name]}#g"

# ALSO RIGHT: escape the value
escaped_name="${ANSWERS[name]//\//\\/}"
sed "s/{{NAME}}/$escaped_name/g"
```

### Pitfall 2: Empty Value Display

**What goes wrong:** Blank sections in CLAUDE.md look broken
**Why it happens:** User skipped optional questions
**How to avoid:** Check for empty and provide helpful placeholder
**Warning signs:** Lines like "Key Areas: " with nothing after

```bash
# Handle empty gracefully
areas="${ANSWERS[areas]:-[Add your key focus areas here]}"
```

### Pitfall 3: Quote Handling in sed

**What goes wrong:** User enters quotes in their name/role, breaks sed
**Why it happens:** Unescaped quotes in sed replacement
**How to avoid:** Escape special characters in all user input
**Warning signs:** "unterminated `s' command" errors

```bash
# Escape sed special characters in user input
escape_for_sed() {
    local input="$1"
    # Escape: & \ /
    printf '%s' "$input" | sed -e 's/[&/\]/\\&/g'
}
```

### Pitfall 4: Lost Newlines in Multi-value Fields

**What goes wrong:** Bullet list appears on single line
**Why it happens:** Newlines lost during variable expansion
**How to avoid:** Use process substitution or temp file for multi-line content
**Warning signs:** "- Item1- Item2- Item3" on one line

### Pitfall 5: Overwriting User Customizations

**What goes wrong:** User ran installer again and lost their carefully edited CLAUDE.md
**Why it happens:** No protection for existing files
**How to avoid:** Always show diff first, require explicit confirmation, offer backup
**Warning signs:** User complaints about lost work

## Code Examples

### Complete Template Substitution Function

```bash
# Source: Derived from sed best practices and existing install.sh patterns

# Escape special sed characters in a value
escape_for_sed() {
    printf '%s' "$1" | sed -e 's/[&/\]/\\&/g'
}

# Format comma-separated values as markdown bullets
format_as_bullets() {
    local csv="$1"
    local default="${2:-[Not specified]}"

    if [[ -z "$csv" ]]; then
        echo "$default"
        return
    fi

    # Convert CSV to bullet list
    echo "$csv" | tr ',' '\n' | while read -r item; do
        # Trim whitespace
        item=$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -n "$item" ]] && echo "- $item"
    done
}

# Process template file with user answers
process_template() {
    local template_file="$1"
    local output_file="$2"

    # Read template
    local content
    content=$(<"$template_file")

    # Substitute simple values (use # delimiter to avoid path conflicts)
    content="${content//\{\{NAME\}\}/$(escape_for_sed "${ANSWERS[name]}")}"
    content="${content//\{\{ROLE\}\}/$(escape_for_sed "${ANSWERS[role]:-[Your role]}")}"

    # Handle multi-value fields specially
    local areas_formatted
    areas_formatted=$(format_as_bullets "${ANSWERS[areas]}" "[Add your key areas]")

    local prefs_formatted
    prefs_formatted=$(format_as_bullets "${ANSWERS[preferences]}" "[Add your preferences]")

    # Write to temp file, then substitute multi-line content
    echo "$content" > "$output_file.tmp"

    # Use awk for multi-line substitution
    awk -v areas="$areas_formatted" -v prefs="$prefs_formatted" '
        /\{\{AREAS\}\}/ { print areas; next }
        /\{\{PREFERENCES\}\}/ { print prefs; next }
        { print }
    ' "$output_file.tmp" > "$output_file"

    rm -f "$output_file.tmp"
}
```

### Existing File Handling with Diff and Prompt

```bash
# Source: Derived from existing ask_confirm pattern and diff best practices

handle_existing_claudemd() {
    local existing="CLAUDE.md"
    local proposed="$1"  # Path to newly generated file

    echo ""
    echo "CLAUDE.md already exists in this vault."
    echo ""
    echo "Differences between existing and new:"
    echo "────────────────────────────────────"

    # Show colored diff
    diff -u "$existing" "$proposed" | while IFS= read -r line; do
        case "$line" in
            ---*) echo -e "${RED}$line${NC}" ;;
            +++*) echo -e "${GREEN}$line${NC}" ;;
            @@*) echo -e "${YELLOW}$line${NC}" ;;
            -*) echo -e "${RED}$line${NC}" ;;
            +*) echo -e "${GREEN}$line${NC}" ;;
            *) echo "$line" ;;
        esac
    done

    echo "────────────────────────────────────"
    echo ""

    # Prompt for action
    local action
    if $HAS_GUM; then
        action=$(gum choose "Keep existing" "Backup and replace" "Replace (no backup)")
    else
        echo "What would you like to do?"
        echo "  1) Keep existing CLAUDE.md"
        echo "  2) Backup existing and replace"
        echo "  3) Replace without backup"
        read -p "Choice (1-3): " choice
        case "$choice" in
            1) action="Keep existing" ;;
            2) action="Backup and replace" ;;
            3) action="Replace (no backup)" ;;
            *) action="Keep existing" ;;
        esac
    fi

    case "$action" in
        "Keep existing")
            echo -e "${GREEN}✓${NC} Keeping existing CLAUDE.md"
            rm -f "$proposed"
            ;;
        "Backup and replace")
            local backup_name="CLAUDE.md.backup-$(date +%Y%m%d-%H%M)"
            cp "$existing" "$backup_name"
            mv "$proposed" "$existing"
            echo -e "${GREEN}✓${NC} Backed up to $backup_name"
            echo -e "${GREEN}✓${NC} CLAUDE.md updated"
            ;;
        "Replace (no backup)")
            mv "$proposed" "$existing"
            echo -e "${GREEN}✓${NC} CLAUDE.md replaced"
            ;;
    esac
}
```

### Vault Type Detection

```bash
# Source: Based on bash nullglob best practices

detect_vault_type() {
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
}
```

## Template Structure Recommendation

Based on Claude Code best practices research, the CLAUDE.md template should prioritize:

1. **WHO** - User context (name, role, areas) - personalized from questionnaire
2. **WHAT** - Vault structure - partially personalized, mostly guidance
3. **HOW** - Working preferences - personalized from questionnaire
4. **Static sections** - Minervia skills, workflow - NOT personalized (reference only)

**Recommended template structure:**

```markdown
# CLAUDE.md

This file provides context to Claude Code when working in this vault.

## Vault Overview

This is {{NAME}}'s personal knowledge management vault. I work as a {{ROLE}}.

## Folder Structure

<!-- Update these paths to match your vault structure -->

- **00 Daily/** - Daily notes
- **01 Inbox/** - Quick capture
- **02 Projects/** - Active work
- **03 Areas/** - Ongoing responsibilities
- **04 Resources/** - Reference materials
- **05 Archive/** - Completed items

## Current Focus

<!-- Update this section when your priorities change -->

**This Week:**
- [Primary focus for the week]
- [Secondary priority]

## Working Preferences

{{PREFERENCES}}

## Key Contexts

**Areas I focus on:**
{{AREAS}}

**Tools I Use:**
- [Tool 1]
- [Tool 2]

---

*Last updated: {{DATE}}*
```

**Key insight:** Keep personalized content to ~60 lines. Static Minervia documentation (skills list, workflow guidelines) should be in a separate reference file or README, not in CLAUDE.md.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Embedded heredoc | External template file | This phase | Easier to maintain, version control |
| No personalization | User answers injected | This phase | Immediately useful context for Claude |
| Silent overwrite | Diff-first with prompt | This phase | Protects user customizations |

**Current install.sh issues (lines 786-878):**
- Uses single-quoted heredoc `<< 'CLAUDEMD'` preventing all substitution
- VAULT_NAME variable is set but never used
- Content is Minervia documentation, not user context
- Ignores all questionnaire answers

## Open Questions

Things that couldn't be fully resolved:

1. **Should IS_NEW_VAULT persist for Phase 5?**
   - What we know: Phase 5 (folder scaffolding) may want this info
   - What's unclear: Whether export or a file marker is better
   - Recommendation: Export variable; Phase 5 can re-detect if needed

2. **How to handle .obsidian in empty detection?**
   - What we know: .obsidian is infrastructure, not user content
   - What's unclear: User may open in Obsidian before running installer
   - Recommendation: Exclude hidden files (use `*` not `.*`) - already handled by nullglob approach

3. **Template file location in distribution**
   - What we know: User decided `templates/CLAUDE.md.template`
   - What's unclear: How installer finds this relative to itself
   - Recommendation: Use `$(dirname "$0")/templates/` pattern (like SKILLS_SOURCE)

## Sources

### Primary (HIGH confidence)
- install.sh (lines 1-945) - Current implementation patterns
- 04-CONTEXT.md - User decisions constraining this phase
- [Greg's Wiki - TemplateFiles](https://mywiki.wooledge.org/TemplateFiles) - Bash template processing approaches

### Secondary (MEDIUM confidence)
- [HumanLayer - Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) - Best practices for CLAUDE.md content
- [envsubst guide](https://karandeepsingh.ca/posts/leveraging-envsubst-in-bash-scripts-for-automation/) - Confirmed envsubst patterns (not recommended due to dependency)

### Tertiary (LOW confidence)
- [diff --color examples](https://medium.com/@redswitches/how-to-use-diff-color-7-practical-examples-46de448e46a6) - Linux-specific, not applicable to macOS BSD diff

## Metadata

**Confidence breakdown:**
- Template syntax: HIGH - sed with `#` delimiter is well-documented POSIX
- Diff handling: HIGH - manual coloring is portable, tested on this macOS
- Empty detection: HIGH - nullglob pattern is standard bash
- CLAUDE.md best practices: MEDIUM - based on authoritative blog post, not official docs

**Research date:** 2026-01-18
**Valid until:** 2026-02-18 (30 days - stable bash patterns)
