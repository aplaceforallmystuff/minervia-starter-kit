# Feature Landscape: CLI Installers with Guided Onboarding

**Domain:** CLI installer for Claude Code + Obsidian PARA vault
**Target users:** Semi-technical (can follow instructions, don't want to troubleshoot)
**Researched:** 2026-01-18
**Confidence:** HIGH (multiple authoritative sources cross-referenced)

## Table Stakes

Features users expect. Missing = users fail, get frustrated, or abandon the tool.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Prerequisites check** | Users need to know upfront if their system is ready; failing mid-install is frustrating | Low | Check for Claude Code CLI, Bash version, required directories |
| **Clear progress indication** | Users assume broken if nothing happens for >100ms | Low | Spinner or status messages for each step |
| **Human-readable error messages** | Technical errors cause abandonment in semi-technical users | Medium | Translate errors into actionable steps, not stack traces |
| **Help flag (--help / -h)** | Universal CLI convention; users will try it instinctively | Low | Must show usage, key flags, and example invocations |
| **Idempotent execution** | Safe to run again if interrupted or uncertain if it worked | Medium | Check before acting, skip what's already done |
| **Non-destructive defaults** | Users fear data loss; installer must never delete user content | Low | Never overwrite without asking, back up before modifying |
| **Exit codes** | Scripts and users rely on 0=success, non-zero=failure | Low | Essential for automation and troubleshooting |
| **Confirmation before destructive actions** | Users want control over what changes | Low | "This will create X, proceed? [Y/n]" |
| **Version display (--version / -v)** | Users need to know what they have installed for troubleshooting | Low | Show version from git tag or embedded constant |
| **Uninstall instructions** | Users need a way out; confidence they can reverse | Low | Document in help or provide --uninstall flag |

### Table Stakes Rationale

These are not "nice to have" — they're the baseline that prevents user failure:

1. **Prerequisites check**: A user without Claude Code CLI installed will hit cryptic errors. Check first, fail fast with clear instructions.

2. **Progress indication**: The [clig.dev guidelines](https://clig.dev/) state "print something to the user in <100ms." Silence feels like breakage.

3. **Human-readable errors**: Semi-technical users can follow instructions but can't debug. "Error: ENOENT" loses them; "Error: Daily notes folder not found at 00 Daily/. Create it or run with --skip-daily" keeps them.

4. **Idempotent execution**: Users re-run installers when unsure. If the second run creates duplicates or errors, trust is lost. [This is a core principle](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/) for reliable CLI tools.

---

## Differentiators

Features that set the product apart. Not expected, but make users recommend the tool.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Interactive questionnaire** | Personalizes setup, captures user context for CLAUDE.md | Medium | Use prompts library (enquirer/prompts) for rich UX |
| **New vs existing vault detection** | Adapts behavior to user's situation automatically | Medium | Detect PARA structure presence, offer appropriate path |
| **Guided first session** | Builds user confidence, demonstrates value immediately | Medium | Walk through /log-to-daily, show vault-stats |
| **Dry-run mode (--dry-run)** | Power users can preview changes before committing | Low | Show what would happen without executing |
| **Customization preservation on update** | Respects user investment in tweaking | High | Detect user modifications, merge carefully |
| **Summary/review step** | Users see what was configured before finalizing | Low | "Here's what we'll create: [list]. Proceed?" |
| **Smart defaults with overrides** | Works out of the box, power users can customize | Medium | Auto-detect common patterns, allow flags to override |
| **Verbose mode (-v, --verbose)** | Debug visibility when needed, clean output by default | Low | Essential for troubleshooting without cluttering default |
| **MCP server recommendations** | Points users toward value-add integrations | Low | Curated list with links, not auto-install |
| **Color-coded output** | Visual hierarchy makes output scannable | Low | Green for success, yellow for warnings, red for errors |
| **Graceful degradation for non-TTY** | Works in scripts and redirected output | Low | Detect TTY, disable colors/spinners when appropriate |

### Differentiator Rationale

These features transform "it works" into "I love this and recommend it":

1. **Interactive questionnaire**: Most installers are one-size-fits-all. Capturing user context (what they do, their areas of responsibility, working preferences) to generate personalized CLAUDE.md is the core value proposition. This is where [wizard-style onboarding](https://www.nngroup.com/articles/wizards/) shines.

2. **Guided first session**: The [wizard anti-pattern article](http://stef.thewalter.net/installer-anti-pattern.html) warns that "the worst time for a user to make choices about a system is before they've used it." A guided first session solves this by letting users experience value immediately after setup.

3. **Customization preservation**: Update mechanisms that blow away customizations are the #1 complaint in CLI tools. [Version your config files](https://bettercli.org/design/cli-application-lifecycle/) and handle upgrades thoughtfully.

4. **Dry-run mode**: [Many CLI tools](https://nickjanetakis.com/blog/cli-tools-that-support-previews-dry-runs-or-non-destructive-actions) (rsync, kubectl, apt) support this. It builds trust and helps users understand what the installer does.

---

## Anti-Features

Features to deliberately NOT build. Common mistakes in this domain.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Too many configuration choices during install** | Per the [wizard anti-pattern](http://stef.thewalter.net/installer-anti-pattern.html): "The worst time for a user to make choices is before they've used it" | Ask minimal questions; let users configure post-install |
| **Silent failures** | Users assume success when nothing happens; they discover failure later | Always output result status; use exit codes |
| **Auto-install dependencies** | Adds complexity, failure modes, permission issues | Document prerequisites, check for them, guide users to install themselves |
| **Forced interactivity (no --yes flag)** | Breaks scripting, CI/CD, power users who know what they want | Support --yes or --no-interactive for automation |
| **Over-explaining during install** | Walls of text go unread; slow down the user | Be concise; put details in --verbose or docs |
| **Assuming directory structure** | Users have different conventions; assuming breaks their setup | Detect actual structure, ask when uncertain |
| **Auto-updates** | Users lose control, updates can break workflows | Provide update command, let users choose when |
| **Complex rollback system** | Adds significant complexity for edge case | Make install idempotent instead; user can just re-run |
| **GUI wrapper** | Terminal is the feature, not a limitation for this audience | Invest in excellent CLI UX instead |
| **Asking for sensitive info** | Users hesitate to type passwords/keys in installers | Reference environment variables or config files |
| **Multiple verbosity levels (-vvv)** | Overkill for installer; adds complexity | Single --verbose flag is sufficient |
| **Platform detection magic** | Heuristics fail; explicit is better | Ask macOS/Linux if behavior differs, or use portable code |

### Anti-Feature Rationale

1. **Too many configuration choices**: [Research shows](https://blog.logrocket.com/ux-design/creating-setup-wizard-when-you-shouldnt/) wizards that ask too many questions during setup frustrate users. Capture essentials (name, vault location, key areas) and defer everything else to post-install configuration.

2. **Auto-install dependencies**: The PROJECT.md explicitly notes MCP servers are out of scope because it "adds complexity, users should control their integrations." Same logic applies to any dependency. Check, don't install.

3. **Complex rollback**: [Windows Installer rollback](https://www.revenera.com/blog/software-installation/i-take-it-all-back-using-windows-installer-msi-rollback-actions/) is notoriously complex. Instead, make the installer idempotent — users can safely re-run to fix partial installs.

4. **Forced interactivity**: The [Node.js CLI best practices](https://github.com/lirantal/nodejs-cli-apps-best-practices) emphasize supporting both interactive and non-interactive modes. Power users and scripts need --yes flags.

---

## Feature Dependencies

```
Prerequisites Check
       │
       ▼
Interactive Questionnaire ─────────► CLAUDE.md Generation
       │                                    │
       ▼                                    │
Vault Detection (new/existing)              │
       │                                    │
       ├── [New Vault] ──► PARA Creation    │
       │                                    │
       └── [Existing Vault] ──► Skip PARA   │
                                            │
Skills Installation ◄──────────────────────┘
       │
       ▼
Summary/Review Step
       │
       ▼
Guided First Session (optional)
       │
       ▼
MCP Recommendations (display only)
```

### Dependency Notes

- **Prerequisites must complete before anything else** — no point prompting users if Claude Code isn't installed
- **Questionnaire feeds CLAUDE.md** — must complete questionnaire before generating config
- **Vault detection determines PARA path** — new vaults get structure, existing vaults skip it
- **Skills installation depends on questionnaire** — some skills may be conditional on user answers
- **Guided first session is opt-in** — user can skip if they know what they're doing

---

## MVP Recommendation

For MVP, prioritize these table stakes and one differentiator:

### Must Have (Table Stakes)
1. Prerequisites check (fail fast)
2. Progress indication (don't seem broken)
3. Human-readable errors (recoverable failures)
4. Help flag (--help)
5. Idempotent execution (safe to re-run)
6. Non-destructive defaults (never lose user data)
7. Exit codes (automation-friendly)

### Must Have (Core Differentiator)
8. Interactive questionnaire → CLAUDE.md generation (the value proposition)
9. New vs existing vault detection (adapts to user situation)

### Should Have (High Value)
10. Summary/review step (transparency)
11. Guided first session (confidence building)
12. --verbose flag (debuggability)
13. --dry-run flag (trust building)

### Defer to Post-MVP
- Customization preservation on update (High complexity, can add in v1.1)
- Color-coded output (Nice to have, easy to add later)
- MCP recommendations (Can add after core installer works)
- Graceful degradation for non-TTY (Edge case)

---

## Questionnaire Design Principles

Based on [wizard UX research](https://www.nngroup.com/articles/wizards/), the interactive questionnaire should:

1. **Progressive disclosure**: One question per screen, not a wall of fields
2. **Show progress**: "Step 2 of 5" or progress bar
3. **Allow going back**: Let users revise previous answers
4. **Smart defaults**: Pre-fill when we can detect (e.g., git user.name)
5. **Skip optional questions**: Don't force users through irrelevant prompts
6. **Summary before commit**: Show what will be generated before writing files

### Recommended Questions (Minimal Set)

| Question | Purpose | Required? |
|----------|---------|-----------|
| Your name | Personalize CLAUDE.md | Yes |
| Vault location | Where to create/detect vault | Yes |
| What do you do? (role/business) | Context for Claude | Yes |
| Key areas of responsibility | Populate Areas section | Optional |
| Working preferences | Communication style in CLAUDE.md | Optional |

Defer to post-install: Tools you use, writing style preferences, custom skill configuration.

---

## Sources

### Authoritative CLI Design Guidelines
- [Command Line Interface Guidelines (clig.dev)](https://clig.dev/) — comprehensive CLI design reference
- [Node.js CLI Apps Best Practices](https://github.com/lirantal/nodejs-cli-apps-best-practices) — extensive Node.js-specific guidance

### Wizard and Onboarding UX
- [Nielsen Norman Group: Wizards Definition and Recommendations](https://www.nngroup.com/articles/wizards/) — when and how to use wizards
- [LogRocket: Creating a Setup Wizard (and When You Shouldn't)](https://blog.logrocket.com/ux-design/creating-setup-wizard-when-you-shouldnt/) — wizard anti-patterns

### Anti-Patterns
- [The Wizard Anti-Pattern](http://stef.thewalter.net/installer-anti-pattern.html) — why too many choices during install is bad
- [How to Write Idempotent Bash Scripts](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/) — making scripts safe to re-run

### Progress and Feedback
- [Evil Martians: CLI UX Best Practices for Progress Displays](https://evilmartians.com/chronicles/cli-ux-best-practices-3-patterns-for-improving-progress-displays) — spinners, progress bars, X of Y patterns
- [CLI Tools That Support Dry Runs](https://nickjanetakis.com/blog/cli-tools-that-support-previews-dry-runs-or-non-destructive-actions) — preview mode patterns

### Error Handling
- [Nielsen Norman Group: Error Message Guidelines](https://www.nngroup.com/articles/error-message-guidelines/) — human-centered error design
- [Smashing Magazine: Designing Better Error Messages](https://www.smashingmagazine.com/2022/08/error-messages-ux-design/) — actionable error guidance

### Configuration and Updates
- [BetterCLI: CLI Application Lifecycle](https://bettercli.org/design/cli-application-lifecycle/) — version handling, config preservation
