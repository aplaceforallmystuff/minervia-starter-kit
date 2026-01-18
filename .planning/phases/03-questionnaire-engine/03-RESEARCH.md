# Phase 3: Questionnaire Engine - Research

**Researched:** 2026-01-18
**Domain:** Bash interactive prompts, Gum CLI, answer storage, conditional logic
**Confidence:** HIGH

## Summary

This phase implements an interactive CLI questionnaire that captures user context during installation. The research focused on Gum's interactive prompt components, fallback patterns using native bash `read`, answer storage using associative arrays, and the conditional flow/summary/edit patterns needed for a quality UX.

**Key findings:**
1. Gum provides four key commands for questionnaires: `input` (text), `choose`/`filter` (selection), `confirm` (yes/no). Multi-select uses `--no-limit` flag with Tab to select items.
2. Fallback to `read -p` is straightforward for text and yes/no, but multi-select requires comma-separated input parsing.
3. Associative arrays (`declare -A`) are the recommended way to store answers for later use - this matches our Bash 4.0+ requirement.
4. Non-interactive detection uses `[ -t 0 ]` to check if stdin is a TTY. Flags like `--name "John"` enable CI/automation use.
5. Progress can be shown as "Question X of Y" using simple echo with carriage return for updates.

**Primary recommendation:** Build a dual-mode questionnaire with Gum as the enhanced experience and `read -p` as the fallback. Store all answers in a `declare -A ANSWERS` associative array. Offer to install Gum if missing. Support `--name`, `--vault-path`, `--role` flags for non-interactive mode.

## Standard Stack

### Core Tools
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Gum | Latest (0.14+) | Interactive prompts | Charmbracelet's standard CLI UX tool |
| Bash `read` | Built-in | Fallback prompts | POSIX-compliant, always available |
| Bash associative arrays | 4.0+ | Answer storage | Native, no dependencies |

### Gum Commands for Questionnaires
| Command | Purpose | Key Flags |
|---------|---------|-----------|
| `gum input` | Single-line text input | `--placeholder`, `--value`, `--password`, `--width` |
| `gum choose` | Select from list | `--height`, `--limit`, `--no-limit`, `--header` |
| `gum filter` | Fuzzy search + select | `--limit`, `--no-limit`, `--placeholder` |
| `gum confirm` | Yes/no question | Returns exit code 0 (yes) or 1 (no) |
| `gum style` | Format headers/text | `--foreground`, `--border`, `--bold` |
| `gum spin` | Loading indicator | `--spinner`, `--title` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Gum | dialog/whiptail | Gum is modern, better UX, but dialog is more common on Linux servers |
| Gum | fzf | fzf is fuzzy-find only, not a full prompt toolkit |
| Associative array | Separate variables | Variables work but harder to iterate/pass to functions |

**Installation:**
```bash
# macOS
brew install gum

# Linux (Debian/Ubuntu)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum

# Arch Linux
pacman -S gum
```

## Architecture Patterns

### Recommended Script Structure
```
install.sh
├── Existing code (Phases 1-2)
├── Gum detection and install offer (new)
├── Answer storage initialization (new)
│   └── declare -A ANSWERS
├── Question functions (new)
│   ├── ask_text()      # Single-line input
│   ├── ask_choice()    # Single selection
│   ├── ask_multi()     # Multi-select
│   └── ask_confirm()   # Yes/no
├── Questionnaire flow (new)
│   ├── show_progress()
│   ├── ask_name()
│   ├── ask_vault_path()
│   ├── ask_role()
│   ├── ask_areas()
│   └── ask_preferences()
├── Summary and edit (new)
│   ├── show_summary()
│   └── edit_answer()
└── Main installation (existing, uses ANSWERS)
```

### Pattern 1: Gum Detection with Install Offer

**What:** Check for Gum, offer to install if missing
**When to use:** Start of questionnaire, after argument parsing

```bash
# Source: Homebrew documentation, Gum installation docs
HAS_GUM=false

check_gum() {
    if command -v gum &> /dev/null; then
        HAS_GUM=true
        return 0
    fi
    return 1
}

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
                echo -e "${GREEN}ok${NC} Gum installed"
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
```

### Pattern 2: Dual-Mode Input Functions

**What:** Functions that use Gum when available, fall back to read
**When to use:** All questionnaire prompts

```bash
# Source: Gum documentation, bash read man page

# Text input with validation
ask_text() {
    local prompt="$1"
    local placeholder="${2:-}"
    local required="${3:-false}"
    local result=""

    while true; do
        if $HAS_GUM; then
            result=$(gum input --placeholder "$placeholder" --prompt "$prompt ")
        else
            read -p "$prompt " result
        fi

        # Validation
        if [[ "$required" == "true" && -z "$result" ]]; then
            echo -e "${RED}This field is required.${NC}"
            continue
        fi

        break
    done

    echo "$result"
}

# Single choice from options
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

# Multi-select from options
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
        echo "(Enter comma-separated numbers, e.g., 1,3,4)"
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

# Yes/No confirmation
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
```

### Pattern 3: Answer Storage with Associative Array

**What:** Store all answers in a single associative array
**When to use:** Initialize before questionnaire, use throughout

```bash
# Source: Bash associative array documentation

# Initialize at script start (after Bash 4+ check)
declare -A ANSWERS

# Store answers
ANSWERS[name]="John Doe"
ANSWERS[vault_path]="/Users/john/Documents/vault"
ANSWERS[role]="consultant"
ANSWERS[areas]="content,consulting,research"  # Comma-separated for multi
ANSWERS[preferences]="concise,direct"

# Access single answer
echo "${ANSWERS[name]}"

# Iterate all answers
for key in "${!ANSWERS[@]}"; do
    echo "$key: ${ANSWERS[$key]}"
done

# Check if answer exists
if [[ -n "${ANSWERS[name]:-}" ]]; then
    echo "Name is set"
fi
```

### Pattern 4: Progress Indicator

**What:** Show "Question X of Y" during questionnaire
**When to use:** Before each question

```bash
# Source: Bash echo conventions

CURRENT_QUESTION=0
TOTAL_QUESTIONS=5

show_progress() {
    ((CURRENT_QUESTION++))
    echo ""
    if $HAS_GUM; then
        gum style --foreground 99 "Question $CURRENT_QUESTION of $TOTAL_QUESTIONS"
    else
        echo -e "${YELLOW}--- Question $CURRENT_QUESTION of $TOTAL_QUESTIONS ---${NC}"
    fi
}
```

### Pattern 5: Non-Interactive Mode Detection

**What:** Detect when script runs without TTY, accept flags instead
**When to use:** Before questionnaire starts

```bash
# Source: TLDP Interactive Shell documentation

is_interactive() {
    # Check if stdin is a terminal
    [ -t 0 ]
}

# Extended parse_args for questionnaire flags
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            # Existing flags...
            -h|--help)
                show_help
                exit 0
                ;;
            # New questionnaire flags
            --name)
                ANSWERS[name]="$2"
                shift
                ;;
            --vault-path)
                ANSWERS[vault_path]="$2"
                shift
                ;;
            --role)
                ANSWERS[role]="$2"
                shift
                ;;
            --areas)
                ANSWERS[areas]="$2"
                shift
                ;;
            --preferences)
                ANSWERS[preferences]="$2"
                shift
                ;;
            --no-questionnaire)
                SKIP_QUESTIONNAIRE=true
                ;;
            *)
                break
                ;;
        esac
        shift
    done
}

# In main flow
run_questionnaire() {
    if [[ "${SKIP_QUESTIONNAIRE:-false}" == "true" ]]; then
        echo "Skipping questionnaire (--no-questionnaire)"
        return 0
    fi

    if ! is_interactive; then
        echo "Non-interactive mode detected."
        if [[ -z "${ANSWERS[name]:-}" ]] || [[ -z "${ANSWERS[vault_path]:-}" ]]; then
            error_exit "Non-interactive mode requires --name and --vault-path" \
                "Run with: ./install.sh --name \"Your Name\" --vault-path \"/path/to/vault\""
        fi
        return 0
    fi

    # Run interactive questionnaire...
}
```

### Pattern 6: Summary with Edit Capability

**What:** Show all answers, allow editing specific ones
**When to use:** End of questionnaire, before proceeding

```bash
# Source: Best practices synthesis

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

edit_answer() {
    local field="$1"
    case "$field" in
        1|name)
            ANSWERS[name]=$(ask_text "Your name:" "${ANSWERS[name]}" true)
            ;;
        2|vault_path|vault-path)
            ANSWERS[vault_path]=$(ask_text "Vault path:" "${ANSWERS[vault_path]}" true)
            ;;
        3|role)
            ANSWERS[role]=$(ask_choice "Your role:" "${ROLE_OPTIONS[@]}")
            ;;
        4|areas)
            ANSWERS[areas]=$(ask_multi "Key areas:" "${AREA_OPTIONS[@]}")
            ;;
        5|preferences)
            ANSWERS[preferences]=$(ask_multi "Working preferences:" "${PREF_OPTIONS[@]}")
            ;;
    esac
}

confirm_summary() {
    while true; do
        show_summary

        if $HAS_GUM; then
            local action=$(gum choose "Continue" "Edit answer" "Start over")
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
                if $HAS_GUM; then
                    local field=$(gum choose "1) Name" "2) Vault path" "3) Role" "4) Key areas" "5) Preferences")
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
```

### Pattern 7: Input Validation with Retry

**What:** Re-prompt on invalid input with helpful hints
**When to use:** Required fields, path validation

```bash
# Source: Bash retry patterns, UX best practices

MAX_RETRIES=3

ask_with_validation() {
    local prompt="$1"
    local validate_fn="$2"  # Function that returns 0 if valid
    local hint="$3"
    local attempts=0

    while [[ $attempts -lt $MAX_RETRIES ]]; do
        local value
        value=$(ask_text "$prompt" "" false)

        if $validate_fn "$value"; then
            echo "$value"
            return 0
        fi

        ((attempts++))
        echo -e "${RED}Invalid input.${NC} $hint"
        if [[ $attempts -lt $MAX_RETRIES ]]; then
            echo "($((MAX_RETRIES - attempts)) attempts remaining)"
        fi
    done

    error_exit "Maximum retries exceeded" "Please restart the installer"
}

# Validation functions
validate_not_empty() {
    [[ -n "$1" ]]
}

validate_path_exists() {
    [[ -d "$1" ]]
}

validate_path_writable() {
    local path="$1"
    if [[ -d "$path" ]]; then
        [[ -w "$path" ]]
    else
        # Check parent directory is writable (for creation)
        local parent="${path%/*}"
        [[ -w "$parent" ]]
    fi
}
```

### Anti-Patterns to Avoid

- **Storing answers in separate variables:** Use associative array for clean iteration and function passing
- **Hardcoding question count:** Define `TOTAL_QUESTIONS` as a constant, update when adding questions
- **Forgetting TTY check:** Non-interactive mode will hang waiting for input without detection
- **Not offering edit at end:** Users frustrated when they can't fix typos without restarting
- **Silent Gum failures:** Always check Gum exit codes and fall back gracefully

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Styled prompts | ANSI escape sequences | Gum style | Consistent, handles terminal differences |
| Multi-select UI | Complex bash arrays | Gum choose --no-limit | Tab selection is intuitive |
| Fuzzy search | grep + manual matching | Gum filter | Built-in, handles edge cases |
| Spinner animation | while + sleep + echo | Gum spin | Non-blocking, clean |
| Yes/No prompts | Complex read parsing | Gum confirm | Returns exit codes correctly |

**Key insight:** Gum handles terminal compatibility, Unicode rendering, and edge cases. The fallback should be minimal, not a recreation of Gum's features.

## Common Pitfalls

### Pitfall 1: Gum Output Capture Issues
**What goes wrong:** Variable assignment fails when Gum uses TTY
**Why it happens:** Gum writes to stderr for UI, stdout for results
**How to avoid:** Always use `result=$(gum ...)` for capture, Gum handles this correctly
**Warning signs:** Empty variables despite user input

### Pitfall 2: Multi-Select Newline Handling
**What goes wrong:** Storing multi-select as newline-separated breaks string operations
**Why it happens:** Gum outputs one item per line
**How to avoid:** Convert to comma-separated: `result=$(gum filter --no-limit | tr '\n' ',')`
**Warning signs:** Answers appear on multiple lines in summary

### Pitfall 3: Empty Input vs Cancel
**What goes wrong:** Can't distinguish "user entered nothing" from "user cancelled"
**Why it happens:** Both return empty string
**How to avoid:** Use `gum confirm` for opt-out questions, check exit codes
**Warning signs:** Required fields accepted as empty

### Pitfall 4: Path With Spaces
**What goes wrong:** Vault path breaks when passed around
**Why it happens:** Unquoted variable expansion
**How to avoid:** Always quote: `"${ANSWERS[vault_path]}"`, never `${ANSWERS[vault_path]}`
**Warning signs:** "command not found" errors with path fragments

### Pitfall 5: Non-Interactive Without Required Flags
**What goes wrong:** Script hangs or errors in CI/automation
**Why it happens:** No TTY for interactive prompts
**How to avoid:** Check `is_interactive`, require flags, provide clear error message
**Warning signs:** CI jobs timeout

## Code Examples

Verified patterns for this phase:

### Complete Questionnaire Flow
```bash
# Source: Synthesized from Gum docs, bash best practices

# Options for choice questions
ROLE_OPTIONS=("Developer" "Designer" "Product Manager" "Consultant" "Writer" "Researcher" "Other")
AREA_OPTIONS=("Software Development" "Content Creation" "Research" "Consulting" "Project Management" "Learning" "Personal")
PREF_OPTIONS=("Concise responses" "Detailed explanations" "Step-by-step guidance" "Direct communication" "Socratic questioning")

run_questionnaire() {
    CURRENT_QUESTION=0
    TOTAL_QUESTIONS=5

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
                    echo -e "${GREEN}ok${NC} Created ${ANSWERS[vault_path]}"
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
    ANSWERS[areas]=$(ask_multi "Select your key areas:" "${AREA_OPTIONS[@]}" | tr '\n' ',')
    # Remove trailing comma
    ANSWERS[areas]="${ANSWERS[areas]%,}"

    # Question 5: Working Preferences
    show_progress
    echo "How do you prefer Claude to communicate?"
    ANSWERS[preferences]=$(ask_multi "Select preferences:" "${PREF_OPTIONS[@]}" | tr '\n' ',')
    ANSWERS[preferences]="${ANSWERS[preferences]%,}"

    # Confirm
    if ! confirm_summary; then
        # User chose "Start over"
        run_questionnaire
    fi
}
```

### Help Text Update for Questionnaire Flags
```bash
# Add to show_help() heredoc:

cat << 'EOF'
...

Non-Interactive Mode:
  For CI/automation, provide answers via flags:

  --name NAME           Your name for Claude to use
  --vault-path PATH     Full path to your Obsidian vault
  --role ROLE           Your role (Developer, Designer, etc.)
  --areas AREAS         Comma-separated key areas
  --preferences PREFS   Comma-separated preferences
  --no-questionnaire    Skip questionnaire (requires --name, --vault-path)

Examples:
  ./install.sh --name "Jane Doe" --vault-path "/Users/jane/vault" --role "Developer"
  ./install.sh --no-questionnaire --name "CI User" --vault-path "./test-vault"

EOF
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| dialog/whiptail | Gum | 2022 | Modern UX, easier to use |
| read -p only | Gum with fallback | 2022 | Better experience when available |
| Separate variables | Associative arrays | Bash 4.0 (2009) | Cleaner code organization |
| Complex getopt | Simple flags | Best practice | Easier to maintain |

**Deprecated/outdated:**
- `dialog`/`whiptail`: Still work but dated appearance, Gum is the modern choice
- `select` builtin: Works but limited compared to Gum choose/filter

## Open Questions

Things that couldn't be fully resolved:

1. **Gum installation method on Linux without Homebrew**
   - What we know: Charm provides apt repository
   - What's unclear: Whether snap/flatpak versions exist and work correctly
   - Recommendation: Offer Homebrew install, show manual URL for others

2. **Vault path validation depth**
   - What we know: Can check if directory exists, is writable
   - What's unclear: Whether to validate it's an Obsidian vault (.obsidian exists)
   - Recommendation: Check exists/writable, warn if no .obsidian but don't block

3. **Default preferences based on role**
   - What we know: Could pre-select preferences based on role choice
   - What's unclear: Whether this is helpful or presumptuous
   - Recommendation: Keep questions independent, let user choose

## Sources

### Primary (HIGH confidence)
- [Charmbracelet Gum GitHub](https://github.com/charmbracelet/gum) - Official documentation, examples
- [Gum Man Page](https://linuxcommandlibrary.com/man/gum) - Command reference
- [GNU Bash Manual - Arrays](https://www.gnu.org/software/bash/manual/html_node/Arrays.html) - Associative array syntax

### Secondary (MEDIUM confidence)
- [TLDP - Interactive vs Non-interactive](https://tldp.org/LDP/abs/html/intandnonint.html) - Shell detection methods
- [Bash Associative Arrays Tutorial](https://phoenixnap.com/kb/bash-associative-array) - Usage patterns
- [Baeldung - Read Command](https://www.baeldung.com/linux/bash-interactive-prompts) - Input handling
- [Homebrew Documentation](https://docs.brew.sh/) - Package installation

### Tertiary (LOW confidence)
- Various Medium articles on Gum usage - Pattern examples, verified against official docs
- Stack Overflow bash validation patterns - Synthesis, not authoritative

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Gum is authoritative, bash built-ins are documented
- Architecture patterns: HIGH - Patterns from official docs and verified examples
- Pitfalls: MEDIUM - Synthesized from multiple sources and known edge cases

**Research date:** 2026-01-18
**Valid until:** 60 days (Gum actively developed, may have new features)
