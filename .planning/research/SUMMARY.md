# Project Research Summary

**Project:** Minervia Installer Enhancement
**Domain:** CLI installer for Claude Code + Obsidian PARA vault
**Researched:** 2026-01-18
**Confidence:** HIGH

## Executive Summary

Building a CLI installer for semi-technical users (comfortable with terminal, not developers) requires a zero-dependency approach with graceful degradation. The research strongly recommends pure Bash 3.2+ as the runtime (ships with macOS, universal on Linux) with optional Charmbracelet Gum for modern interactive prompts. This combination maximizes reach while delivering excellent UX when dependencies are available. The installer's core value proposition is transforming a questionnaire into a personalized CLAUDE.md file that captures user context for their Claude Code sessions.

The recommended architecture separates concerns into a questionnaire engine, template renderer, file writer, and state manager. A file-based manifest system tracks installed versions and checksums, enabling intelligent updates that preserve user customizations. The conf.d pattern (00-defaults, 50-user, 90-local) prevents update conflicts by keeping vendor files separate from user overrides. Git tags serve as the single source of truth for versioning, with GitHub API checks for update availability.

The critical risks are: (1) silent failures that leave users stuck without understanding what went wrong, (2) update mechanisms that corrupt user customizations, and (3) cross-platform differences between macOS BSD and Linux GNU coreutils. These are mitigated through strict mode (`set -euo pipefail`), atomic file operations with backups, and platform detection at script startup. The research is clear: never overwrite user files without checking checksums first, always backup before modification, and provide clear rollback paths.

## Key Findings

### Recommended Stack

The stack prioritizes portability and zero-friction installation. Users should not need to install npm, Python, or any runtime to use the installer.

**Core technologies:**
- **Bash 3.2+**: Installer runtime — macOS default, universal on Linux, lowest common denominator
- **Charmbracelet Gum**: Interactive prompts (optional) — modern UX with graceful fallback to `read -p`
- **ANSI escape codes**: Colored output — 50+ years of terminal standardization, simpler than tput
- **File-based manifest**: Version tracking — `~/.minervia/state.json` with checksums enables update intelligence
- **Git tags + GitHub API**: Self-update mechanism — no auth needed for public repos, well-established pattern

**Critical version requirements:**
- Bash 3.2 minimum (macOS ships this; targeting higher breaks compatibility)
- No jq required at runtime (parse JSON with bash/sed or include minimal parser)

### Expected Features

**Must have (table stakes):**
- Prerequisites check — fail fast with clear instructions if Claude Code CLI missing
- Progress indication — print something within 100ms or users assume broken
- Human-readable errors — "ENOENT" loses users; actionable messages retain them
- Idempotent execution — safe to re-run without duplication or errors
- Non-destructive defaults — never overwrite without asking, backup before modifying
- Help flag (`--help`) — universal CLI convention
- Exit codes — 0=success, non-zero=failure for automation

**Should have (differentiators):**
- Interactive questionnaire generating personalized CLAUDE.md — core value proposition
- New vs existing vault detection — adapts behavior automatically
- Guided first session — builds confidence, demonstrates value immediately
- Dry-run mode (`--dry-run`) — power users preview changes
- Summary/review step before writing files
- Verbose mode (`--verbose`) for troubleshooting

**Defer to v2+:**
- Customization preservation on update — high complexity, add after core works
- Color-coded output — nice polish, easy to add later
- MCP server recommendations — can add after core installer works
- Multi-vault support — add vault-id to state if requested

### Architecture Approach

The architecture follows a linear flow: prerequisites check, questionnaire, validation, template rendering, file installation, state recording. A separate update system uses version detection, customization scanning (checksum comparison), and merge strategy selection before applying updates with backups.

**Major components:**
1. **Questionnaire Engine** — collects user context through interactive prompts, outputs variables for templating
2. **Template Renderer** — simple `{{VARIABLE}}` substitution with sed/envsubst, no complex templating
3. **File Writer** — atomic operations (write to temp, then mv), creates directories, records to manifest
4. **State Manager** — `~/.minervia/state.json` tracks version, answers, file checksums
5. **Version Detector** — compares git tags against state, shows changelog between versions
6. **Customization Detector** — compares current checksums vs manifest to identify user modifications
7. **Update Executor** — orchestrates backup, merge strategy, and atomic updates

**Key patterns:**
- Idempotent installation (check before acting, skip what exists)
- Atomic file operations (temp file + mv)
- Two-checksum system (source vs current) for modification detection
- Backup before modify (always)

### Critical Pitfalls

1. **Silent failures** — Use `set -euo pipefail`, explicit error handlers with trap, progress indication for operations >100ms. Without this, users abandon immediately.

2. **Update corrupts customizations** — Separate installer files from user files, use conf.d pattern, always backup before update, track checksums to detect modifications. Data loss destroys all trust.

3. **Cross-platform differences** — macOS uses BSD coreutils, Linux uses GNU. `sed -i` syntax differs, `date -d` is GNU-only, `cp` behavior varies. Detect platform at startup, use POSIX-compliant alternatives, or provide shims.

4. **PATH modification errors** — Wrong shell config file (bash vs zsh), duplicates on re-run, read-only symlinks (NixOS). Detect current shell, check for existing entries, warn if symlinked config.

5. **Questionnaire abandonment** — Show progress (3 of 5), validate immediately, provide sensible defaults, allow review before commit. Users give up when confused.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Foundation
**Rationale:** Error handling, platform detection, and dependency checking must be established before any user-facing features. Research shows silent failures cause immediate abandonment.
**Delivers:** Core scaffold with strict mode, error handlers, platform detection, dependency checks, and basic file utilities
**Addresses:** Prerequisites check, exit codes, help flag (table stakes)
**Avoids:** Silent failures (Pitfall 1), platform differences (Pitfall 4), dependency bootstrap (Pitfall 7)

### Phase 2: Questionnaire and CLAUDE.md Generation
**Rationale:** The questionnaire generating personalized CLAUDE.md is the core value proposition. Must come before vault creation since answers determine vault configuration.
**Delivers:** Interactive prompts with gum fallback, template system, CLAUDE.md generation, summary/review step
**Addresses:** Interactive questionnaire, new vs existing vault detection, summary step (differentiators)
**Avoids:** Questionnaire UX abandonment (Pitfall 6), existing file overwrite (Pitfall 3), permission issues (Pitfall 8)
**Uses:** Gum with fallback, envsubst or bash templating

### Phase 3: Vault Scaffolding and Skills Installation
**Rationale:** Depends on questionnaire answers for paths and preferences. PARA creation is conditional on new vs existing vault detection.
**Delivers:** PARA folder structure for new vaults, skill installation to `~/.claude/skills/`, state.json manifest creation
**Addresses:** Idempotent execution, non-destructive defaults (table stakes)
**Avoids:** Permission issues (Pitfall 8), symlink failures (Pitfall 11)
**Implements:** File Writer, State Manager components

### Phase 4: Self-Update Mechanism
**Rationale:** Update system is architecturally complex and research identifies it as the highest-risk area for data corruption. Build separately after core installer works.
**Delivers:** Version checking via git tags, changelog display, customization detection, merge strategies, atomic updates with rollback
**Addresses:** Not table stakes, but critical for long-term maintenance
**Avoids:** Update corruption (Pitfall 2), no rollback (Pitfall 10), config migration (Pitfall 12)
**Uses:** Git tags as version truth, two-checksum system, conf.d pattern

### Phase 5: Polish and First-Run Experience
**Rationale:** Once core works, polish UX and add guided onboarding to demonstrate value immediately.
**Delivers:** Guided first session, verbose mode, dry-run mode, color-coded output, uninstall manifest
**Addresses:** Guided first session, verbose/dry-run modes (differentiators)
**Avoids:** Inconsistent uninstall (Pitfall 13)

### Phase Ordering Rationale

- **Foundation first** because every other phase depends on reliable error handling and platform detection
- **Questionnaire before vault** because vault structure depends on user answers (existing vs new, paths)
- **Skills installation grouped with vault** because both are file operations following same patterns
- **Update mechanism deferred** because it is complex, high-risk, and not needed for initial launch — users can reinstall for v1
- **Polish last** because it adds value but is not blocking for a working installer

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (Self-Update):** Complex merge strategies and rollback mechanisms. Research provided patterns but implementation requires careful testing.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation):** Well-documented bash best practices, error handling patterns established
- **Phase 2 (Questionnaire):** Gum library well-documented, fallback patterns provided
- **Phase 3 (Vault/Skills):** Standard file operations, idempotency patterns established

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Bash 3.2, Gum verified via official repos; patterns from authoritative sources |
| Features | HIGH | Multiple CLI design guidelines cross-referenced (clig.dev, NN Group, Node.js best practices) |
| Architecture | HIGH | Patterns verified through chezmoi, homebrew, dotfiles managers; well-established |
| Pitfalls | HIGH | Real issues documented in GitHub issues (gemini-cli, claude-code), authoritative bash guides |

**Overall confidence:** HIGH

### Gaps to Address

- **Multi-vault support:** Research focused on single vault. If users want multiple vaults, state.json needs vault-id concept. Defer to v2.
- **Windows support:** Explicitly excluded from v1. Would require PowerShell rewrite or WSL instructions.
- **envsubst availability:** May need installation on minimal systems. Pure bash fallback exists but is more complex.
- **jq dependency:** Used in examples but not universally available. Either include minimal JSON parser or avoid JSON entirely for state file.

## Sources

### Primary (HIGH confidence)
- [Charmbracelet Gum](https://github.com/charmbracelet/gum) — official repository, MIT license, last published Sep 2025
- [clig.dev](https://clig.dev/) — comprehensive CLI design guidelines
- [Red Hat Bash Error Handling](https://www.redhat.com/en/blog/bash-error-handling) — error handling best practices
- [Nielsen Norman Group Wizards](https://www.nngroup.com/articles/wizards/) — wizard UX research
- [chezmoi documentation](https://www.chezmoi.io/user-guide/daily-operations/) — dotfiles management patterns

### Secondary (MEDIUM confidence)
- [Node.js CLI Apps Best Practices](https://github.com/lirantal/nodejs-cli-apps-best-practices) — extensive CLI guidance
- [Atlassian Dotfiles Tutorial](https://www.atlassian.com/git/tutorials/dotfiles) — bare git repo patterns
- [Greg's Wiki BashFAQ](https://mywiki.wooledge.org/BashFAQ) — bash patterns reference
- [semver-tool](https://github.com/fsaintjacques/semver-tool) — pure bash semver implementation

### Tertiary (LOW confidence)
- Various Stack Overflow and GitHub gists for specific patterns (cited in individual research files)

---
*Research completed: 2026-01-18*
*Ready for roadmap: yes*
