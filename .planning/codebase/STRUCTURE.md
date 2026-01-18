# Codebase Structure

**Analysis Date:** 2026-01-18

## Directory Layout

```
minervia-starter-kit/
├── .claude/                    # Claude Code configuration
│   ├── agents/                 # Multi-step orchestration agents
│   └── commands/               # Quick commands (/command-name)
├── .github/                    # GitHub templates
│   └── ISSUE_TEMPLATE/         # Issue templates (bug, feature, skill request)
├── .planning/                  # GSD planning documents
│   └── codebase/               # Codebase analysis (this file)
├── docs/                       # Documentation assets
│   └── images/                 # Diagrams (SVG, PNG)
├── skills/                     # Reusable Claude Code skills
│   ├── lessons-learned/        # Structured retrospectives
│   ├── log-to-daily/           # Daily note logging
│   ├── log-to-project/         # Project documentation
│   ├── start-project/          # Project initialization
│   ├── think-first/            # Mental model application
│   ├── vault-stats/            # Vault health statistics
│   └── weekly-review/          # Weekly maintenance
├── CHANGELOG.md                # Version history
├── CLAUDE.md                   # Template for user vaults
├── CONTRIBUTING.md             # Contribution guidelines
├── install.sh                  # Setup script
├── LICENSE                     # MIT license
└── README.md                   # Main documentation
```

## Directory Purposes

**`.claude/`:**
- Purpose: Claude Code configuration for this repository
- Contains: Agents and commands specific to Minervia development
- Key files: `agents/workflow-coordinator.md`, `agents/vault-analyst.md`, `agents/aesthetic-definer.md`, `commands/init.md`

**`.claude/agents/`:**
- Purpose: Multi-agent orchestration definitions
- Contains: Agent files with YAML frontmatter + workflow instructions
- Key files: `workflow-coordinator.md` (orchestrator), `vault-analyst.md` (pattern detection), `aesthetic-definer.md` (brand definition)

**`.claude/commands/`:**
- Purpose: Simple invocable commands for Claude Code
- Contains: Markdown command definitions
- Key files: `init.md` (vault setup helper)

**`.github/ISSUE_TEMPLATE/`:**
- Purpose: Standardized GitHub issue templates
- Contains: Bug reports, feature requests, skill requests
- Key files: `bug_report.md`, `feature_request.md`, `skill_request.md`

**`docs/`:**
- Purpose: Documentation assets and visuals
- Contains: Images, diagrams
- Key files: `images/architecture-flow.svg`, `images/skills-overview.svg`, `images/architecture-diagram.png`

**`skills/`:**
- Purpose: Reusable skill definitions that install to `~/.claude/skills/`
- Contains: Subdirectories, each with a `SKILL.md`
- Key files: Each `skills/*/SKILL.md` is a standalone skill

## Key File Locations

**Entry Points:**
- `install.sh`: Primary user entry point for setup
- `CLAUDE.md`: Template copied to user's vault during install
- `.claude/commands/init.md`: Post-install vault configuration

**Configuration:**
- `CLAUDE.md`: Vault structure configuration template
- `.claude/settings.json`: Created by install.sh for session hooks (not in repo)

**Core Logic:**
- `skills/*/SKILL.md`: All skill definitions
- `.claude/agents/*.md`: All agent definitions
- `install.sh`: Installation logic

**Testing:**
- No automated tests - skills are declarative Markdown, not executable code
- Manual testing by invoking skills in a test vault

**Documentation:**
- `README.md`: Main documentation (extensive - 1099 lines)
- `CONTRIBUTING.md`: How to contribute skills
- `CHANGELOG.md`: Version history
- `docs/images/`: Visual documentation (diagrams)

## Naming Conventions

**Files:**
- Skills: `SKILL.md` (always uppercase)
- Agents: `kebab-case.md` (e.g., `workflow-coordinator.md`)
- Commands: `kebab-case.md` (e.g., `init.md`)
- Documentation: `UPPERCASE.md` for project files (README, CONTRIBUTING, CHANGELOG)

**Directories:**
- Skills: `kebab-case/` (e.g., `log-to-daily/`, `weekly-review/`)
- Standard directories: lowercase (e.g., `docs/`, `skills/`)
- Hidden directories: `.prefix/` (e.g., `.claude/`, `.github/`, `.planning/`)

**Skill Names (in frontmatter):**
- Use `kebab-case` matching directory name
- Example: `name: log-to-daily` in `skills/log-to-daily/SKILL.md`

**Agent Names (in frontmatter):**
- Use `kebab-case` matching filename without extension
- Example: `name: vault-analyst` in `.claude/agents/vault-analyst.md`

## Where to Add New Code

**New Skill:**
- Create directory: `skills/your-skill-name/`
- Add skill file: `skills/your-skill-name/SKILL.md`
- Follow template from `CONTRIBUTING.md` (frontmatter + sections)
- Required sections: Why This Matters, Configuration, Quick Start, Process, Success Criteria

**New Agent:**
- Add agent file: `.claude/agents/your-agent-name.md`
- Include frontmatter: name, description, tools, model
- Include sections: role, constraints, workflow, output_format
- Reference existing agents as templates

**New Command:**
- Add command file: `.claude/commands/your-command.md`
- Keep simple - commands are lightweight helpers
- Include Task description and Process steps

**New Documentation:**
- Add images to: `docs/images/`
- Update README.md for user-facing documentation
- Update CHANGELOG.md for release notes

**New Issue Template:**
- Add template: `.github/ISSUE_TEMPLATE/your-template.md`
- Follow GitHub issue template format

## Special Directories

**`.planning/`:**
- Purpose: GSD (Get Stuff Done) planning documents for codebase analysis
- Generated: By GSD commands (map-codebase, plan-phase)
- Committed: Yes - provides persistent context for development

**`~/.claude/skills/` (external, post-install):**
- Purpose: Global Claude Code skills directory where skills are installed
- Generated: By install.sh during setup
- Committed: No - exists in user's home directory, not this repo

**`.minervia-first-run` (external, in user vault):**
- Purpose: Marker file for first-run welcome experience
- Generated: By install.sh
- Committed: No - created in user's vault, removed after first session

---

*Structure analysis: 2026-01-18*
