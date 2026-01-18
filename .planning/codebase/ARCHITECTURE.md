# Architecture

**Analysis Date:** 2026-01-18

## Pattern Overview

**Overall:** Configuration-driven AI Skill System

**Key Characteristics:**
- No runtime code execution - pure Markdown configuration files parsed by Claude Code
- Skills and agents are declarative instruction sets, not imperative programs
- Claude Code reads these files and follows instructions at runtime
- User's Obsidian vault serves as persistent memory/storage layer
- Terminal (CLI) is the sole interface - no GUI components

## Layers

**Skill Layer:**
- Purpose: Reusable single-purpose procedures for Claude to follow
- Location: `skills/*/SKILL.md`
- Contains: YAML frontmatter (name, description, use_when) + Markdown instructions
- Depends on: User's vault structure, CLAUDE.md configuration
- Used by: Claude Code at runtime when skill is invoked

**Agent Layer:**
- Purpose: Multi-step orchestrators that coordinate skills and delegate work
- Location: `.claude/agents/*.md`
- Contains: YAML frontmatter (name, description, tools, model) + role/workflow definitions
- Depends on: Skills, Task tool for delegation, other agents
- Used by: Claude Code when complex multi-domain work is requested

**Command Layer:**
- Purpose: Quick vault setup/initialization helpers
- Location: `.claude/commands/*.md`
- Contains: Simple Markdown task descriptions
- Depends on: Nothing external
- Used by: Claude Code when `/command-name` invoked

**Installation Layer:**
- Purpose: One-time setup of skills into user's environment
- Location: `install.sh` (root)
- Contains: Bash script that copies skills to `~/.claude/skills/`
- Depends on: Claude Code CLI being installed
- Used by: User during initial setup

**Documentation Layer:**
- Purpose: Project documentation, contributing guidelines, user guides
- Location: `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `docs/`
- Contains: Markdown documentation, SVG/PNG diagrams
- Depends on: Nothing
- Used by: Humans reading the project

## Data Flow

**Skill Invocation Flow:**

1. User types `/skill-name` or describes task matching `use_when` trigger
2. Claude Code reads `~/.claude/skills/skill-name/SKILL.md`
3. Claude parses frontmatter for metadata
4. Claude follows Process/Workflow steps in skill body
5. Skill may read/write to user's Obsidian vault
6. Skill completes, Claude reports back to user

**Agent Orchestration Flow:**

1. User requests complex multi-domain work
2. Claude loads agent from `.claude/agents/agent-name.md`
3. Agent analyzes request, decomposes into tasks
4. Agent uses Task tool to delegate work to specialized agents/skills
5. Agent collects results from delegated work
6. Agent synthesizes and reports cohesive response

**Installation Flow:**

1. User clones repository
2. User runs `install.sh` from their Obsidian vault directory
3. Script copies `skills/*/` to `~/.claude/skills/`
4. Script creates `CLAUDE.md` template in vault root
5. Script optionally creates `.claude/settings.json` with SessionStart hook
6. User edits `CLAUDE.md` to match their vault structure

**State Management:**
- No application state - stateless skill execution
- Persistent context stored in user's Obsidian vault (daily notes, project logs)
- Session continuity achieved through vault content Claude can read
- First-run state tracked via `.minervia-first-run` marker file

## Key Abstractions

**Skill (SKILL.md):**
- Purpose: Encapsulate a repeatable workflow Claude should follow
- Examples: `skills/log-to-daily/SKILL.md`, `skills/weekly-review/SKILL.md`
- Pattern: Frontmatter metadata + "Why This Matters" + "Process" steps + "Success Criteria"

**Agent (*.md in .claude/agents/):**
- Purpose: Coordinate multiple skills/agents for complex workflows
- Examples: `.claude/agents/workflow-coordinator.md`, `.claude/agents/vault-analyst.md`
- Pattern: Frontmatter (tools, model) + role + constraints + workflow phases + output format

**CLAUDE.md:**
- Purpose: Project-level context and configuration for Claude Code
- Examples: `CLAUDE.md` (template in repo root)
- Pattern: Vault paths, folder structure, working preferences, current focus

**Mental Model (within think-first skill):**
- Purpose: Structured thinking framework for decisions
- Examples: First Principles, Inversion, Pareto, 5 Whys, Opportunity Cost
- Pattern: When to use + Process steps + Output template

## Entry Points

**User Entry Point:**
- Location: `install.sh`
- Triggers: User runs manually during setup
- Responsibilities: Copy skills, create CLAUDE.md, set up first-run experience

**Runtime Entry Point:**
- Location: `~/.claude/skills/*/SKILL.md` (after installation)
- Triggers: User invokes skill name or describes matching task
- Responsibilities: Provide instructions Claude follows

**Initialization Command:**
- Location: `.claude/commands/init.md`
- Triggers: User runs `/init` command
- Responsibilities: Detect vault structure, personalize CLAUDE.md

**Session Hook:**
- Location: `.claude/settings.json` (created by install.sh)
- Triggers: SessionStart event on first Claude session
- Responsibilities: Display welcome message, remove first-run marker

## Error Handling

**Strategy:** Defensive guidance with graceful fallbacks

**Patterns:**
- Skills include "Configuration" sections explaining required CLAUDE.md settings
- Skills check for expected paths before operating
- Weekly-review skill shows confirmation before making changes
- Agents include error_handling sections for edge cases (no daily notes, non-standard format)
- Vault-analyst provides alternative paths if standard structure not found

## Cross-Cutting Concerns

**Logging:** Via log-to-daily and log-to-project skills - captures session activity to vault
**Validation:** Skills define "Success Criteria" checklists Claude verifies before completing
**Authentication:** None - relies on Claude Code's existing auth with Anthropic API

---

*Architecture analysis: 2026-01-18*
