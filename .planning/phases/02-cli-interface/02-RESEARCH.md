# Phase 2: CLI Interface - Research

**Researched:** 2026-01-18
**Domain:** Bash CLI argument parsing, help/version conventions, prerequisite checks
**Confidence:** HIGH

## Summary

This phase implements standard CLI conventions for the installer: `--help`, `--version`, prerequisite validation, and uninstall documentation. The research focused on established bash patterns for argument parsing and GNU conventions for help/version output.

**Key findings:**
1. For simple flag-only scripts (no complex arguments), a while/case/shift loop is the recommended pattern over getopts, because it natively supports long options like `--help` and `--version`
2. GNU conventions specify that `--help` and `--version` should work when they are the sole argument, print to stdout, and exit with code 0
3. Bash version checking should use `BASH_VERSINFO` array (built-in, portable) rather than string parsing
4. Claude Code CLI detection uses `command -v claude` (already implemented in install.sh)

**Primary recommendation:** Use a while/case/shift loop for argument parsing. Keep the structure simple since this installer only needs flags (no arguments with values yet). Exit codes: 0=success, 1=error, 2=invalid usage.

## Standard Stack

This phase doesn't introduce new libraries - it uses built-in bash functionality.

### Core Patterns
| Pattern | Purpose | Why Standard |
|---------|---------|--------------|
| while/case/shift loop | Parse --help, --version flags | Supports long options, portable, no dependencies |
| BASH_VERSINFO array | Check bash version | Built-in, reliable, no string parsing needed |
| command -v | Check for executable | POSIX-compliant, preferred over `which` |
| heredoc for help text | Multi-line help output | Clean formatting, easy to maintain |

### Supporting Patterns
| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| getopts | Short option parsing | Only when you need -abc style combined short opts |
| getopt (GNU) | Complex argument parsing | Only when you need --option=value syntax |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| while/case/shift | getopts | getopts can't handle long options natively |
| while/case/shift | getopt (GNU) | getopt has portability issues on macOS |
| BASH_VERSINFO | bash --version parsing | String parsing is fragile and error-prone |

## Architecture Patterns

### Recommended Script Structure

Add these elements to install.sh near the top (after strict mode, before main logic):

```
install.sh
├── Shebang + strict mode (existing)
├── VERSION constant (new)
├── Color definitions (existing)
├── Helper functions
│   ├── cleanup() (existing)
│   ├── error_exit() (existing)
│   ├── show_help() (new)
│   └── show_version() (new)
├── Argument parsing loop (new)
├── Prerequisite checks (new - refactored)
│   ├── check_bash_version()
│   ├── check_claude_cli()
│   └── check_write_permissions()
├── Platform detection (existing)
└── Main installation logic (existing)
```

### Pattern 1: Argument Parsing with while/case/shift

**What:** Parse command-line flags using a loop that handles both short and long options
**When to use:** Any script that needs --help, --version, or other flags

```bash
# Source: Greg's Wiki BashFAQ/035, Better Dev template
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
            --)
                shift
                break
                ;;
            -*)
                error_exit "Unknown option: $1" "Run '$0 --help' for usage"
                ;;
            *)
                break
                ;;
        esac
        shift
    done
}
```

### Pattern 2: Help Message with Heredoc

**What:** Multi-line help text using cat and heredoc
**When to use:** Any script with --help flag

```bash
# Source: GNU conventions, Better Dev template
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Minervia installer - sets up your Obsidian vault for AI-assisted knowledge work.

Options:
  -h, --help      Show this help message and exit
  -V, --version   Show version number and exit

Examples:
  $(basename "$0")              Run the installer
  $(basename "$0") --help       Show this help

Uninstall:
  To remove Minervia:
  1. Delete ~/.claude/skills/minervia-* directories
  2. Remove CLAUDE.md from your vault (optional - contains your customizations)
  3. Remove .minervia-* files from your vault

More info: https://github.com/aplaceforallmystuff/minervia-starter-kit
EOF
}
```

### Pattern 3: Version Output

**What:** Simple version string following GNU conventions
**When to use:** Any script with --version flag

```bash
# Source: GNU Coding Standards
readonly VERSION="1.0.0"

show_version() {
    echo "minervia-installer $VERSION"
}
```

### Pattern 4: Prerequisite Checks

**What:** Validate environment before proceeding with installation
**When to use:** Beginning of script, after argument parsing

```bash
# Source: Best practices for bash installers
check_prerequisites() {
    check_bash_version
    check_claude_cli
    check_write_permissions
}

check_bash_version() {
    local min_major=4
    local min_minor=0

    if [[ -z "${BASH_VERSINFO:-}" ]]; then
        error_exit "Cannot determine Bash version" "Ensure you are running this script with Bash"
    fi

    if [[ ${BASH_VERSINFO[0]} -lt $min_major ]] || \
       [[ ${BASH_VERSINFO[0]} -eq $min_major && ${BASH_VERSINFO[1]} -lt $min_minor ]]; then
        error_exit "Bash ${min_major}.${min_minor}+ required (found ${BASH_VERSION})" \
            "Upgrade Bash or use a newer terminal"
    fi
}

check_claude_cli() {
    if ! command -v claude &> /dev/null; then
        error_exit "Claude Code CLI not found" "Install from https://claude.ai/download"
    fi
}

check_write_permissions() {
    local target_dir="${1:-$(pwd)}"
    if [[ ! -w "$target_dir" ]]; then
        error_exit "Cannot write to directory: $target_dir" \
            "Check permissions or run from a different location"
    fi
}
```

### Anti-Patterns to Avoid

- **Using `-v` for version:** Convention reserves `-v` for verbose mode. Use `-V` for version instead.
- **Mixing getopts and manual parsing:** Pick one approach and stick with it.
- **Printing help to stderr:** Help output should go to stdout (exit 0). Error messages go to stderr (exit non-zero).
- **Version parsing with regex:** Use `BASH_VERSINFO` array, not `bash --version | grep`.
- **Using `which` for command detection:** Use `command -v` instead (POSIX-compliant, handles aliases properly).

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bash version comparison | String parsing with regex | BASH_VERSINFO array | Built-in, handles edge cases, no parsing needed |
| Command existence check | `which` or `type` | `command -v` | POSIX standard, handles aliases, no external dependency |
| Long option parsing | Complex getopts workarounds | while/case/shift loop | Simpler, more readable, handles long options naturally |

**Key insight:** Bash provides built-in mechanisms for version checking (`BASH_VERSINFO`) and command detection (`command -v`). Don't parse output strings when structured data is available.

## Common Pitfalls

### Pitfall 1: Forgetting to shift after processing arguments
**What goes wrong:** Infinite loop or wrong argument processed
**Why it happens:** Each case branch processes $1 but forgets to shift
**How to avoid:** Put `shift` at the end of the while loop, after the case statement
**Warning signs:** Script hangs or processes same argument repeatedly

### Pitfall 2: Using -v for --version
**What goes wrong:** Conflicts with common -v/--verbose convention
**Why it happens:** Seems natural to use first letter
**How to avoid:** Use -V (capital) for version, reserve -v for verbose
**Warning signs:** User confusion, "why isn't verbose working?"

### Pitfall 3: Help/version not working as sole argument
**What goes wrong:** `script.sh --help` shows help then errors on missing required args
**Why it happens:** Argument parsing happens after validation
**How to avoid:** Parse --help and --version FIRST, before any other checks
**Warning signs:** Script requires other args even when asking for help

### Pitfall 4: Not handling unknown options gracefully
**What goes wrong:** Script silently ignores typos like `--hepl`
**Why it happens:** Missing default case in argument parsing
**How to avoid:** Add catch-all case for `-*` that shows error and usage hint
**Warning signs:** Users get confused why their flag "isn't working"

### Pitfall 5: Hardcoding version in multiple places
**What goes wrong:** Version mismatch between --version output and docs
**Why it happens:** Version defined in script and separately in README
**How to avoid:** Define VERSION once as constant, reference it everywhere
**Warning signs:** `--version` shows different version than README

## Code Examples

Verified patterns for this phase:

### Complete Argument Parsing Block

```bash
# Source: Synthesized from Greg's Wiki BashFAQ/035, Better Dev template, GNU conventions

# Version constant - single source of truth
readonly VERSION="1.0.0"

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

show_version() {
    echo "minervia-installer $VERSION"
}

# Parse command-line arguments
# Must happen BEFORE any other checks to allow --help without prerequisites
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
```

### Bash Version Check

```bash
# Source: Greg's Wiki, BASH_VERSINFO documentation

check_bash_version() {
    local min_major=4
    local min_minor=0

    # BASH_VERSINFO is an array: [0]=major, [1]=minor, [2]=patch
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
```

### Prerequisite Orchestration

```bash
# Source: Best practice synthesis

check_prerequisites() {
    # Note: These run AFTER argument parsing
    # so --help works even without prerequisites met

    check_bash_version
    check_claude_cli
    check_write_permissions "$(pwd)"
}

# Call order in script:
# 1. parse_args "$@"      <- Allows --help/--version to work immediately
# 2. detect_platform      <- Platform detection (existing)
# 3. check_prerequisites  <- Validate environment before proceeding
# 4. main installation    <- Only if all checks pass
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `which` for command detection | `command -v` | POSIX standardization | More reliable, handles aliases |
| `bash --version` parsing | `BASH_VERSINFO` array | Available since Bash 2.0 | Simpler, more robust |
| `getopt` for long options | while/case/shift | Always preferred for bash | Better portability |

**Deprecated/outdated:**
- `which`: Not POSIX, behavior varies across systems. Use `command -v`.
- External version parsing tools: BASH_VERSINFO is built-in and reliable.

## Open Questions

Things that couldn't be fully resolved:

1. **Minimum Bash version requirement**
   - What we know: macOS ships with Bash 3.2 (due to GPLv3 licensing), Linux typically has 4.x+
   - What's unclear: Should we require Bash 4.0+ (breaking macOS default) or support 3.2?
   - Recommendation: Require Bash 4.0+ since most macOS users have upgraded via Homebrew, and the features we use (associative arrays in later phases) need it. Document the upgrade path clearly.

2. **Claude Code CLI detection edge cases**
   - What we know: `command -v claude` works for PATH-installed versions
   - What's unclear: Users might have claude aliased or installed via npm globally
   - Recommendation: Current approach is sufficient. If `command -v claude` fails, the error message already points to installation docs.

## Sources

### Primary (HIGH confidence)
- [Greg's Wiki BashFAQ/035](http://mywiki.wooledge.org/BashFAQ/035) - Authoritative bash argument parsing guide
- [Better Dev: Minimal Safe Bash Script Template](https://betterdev.blog/minimal-safe-bash-script-template/) - Modern bash best practices
- [GNU Coreutils Manual](https://www.gnu.org/software/coreutils/manual/coreutils.html) - --help/--version conventions

### Secondary (MEDIUM confidence)
- [Baeldung: Standard Exit Codes](https://www.baeldung.com/linux/status-codes) - Exit code conventions verified against GNU standards
- [TLDP: Exit Codes with Special Meanings](https://tldp.org/LDP/abs/html/exitcodes.html) - Reserved exit codes reference
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) - Error handling patterns

### Tertiary (LOW confidence)
- Various Medium articles on getopts vs getopt - Used for context, verified against primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Based on GNU standards and authoritative bash documentation
- Architecture patterns: HIGH - Patterns from Greg's Wiki (de facto bash authority)
- Pitfalls: MEDIUM - Synthesized from multiple sources and experience

**Research date:** 2026-01-18
**Valid until:** 90 days (bash conventions are stable)
