# Coding Conventions

**Analysis Date:** 2026-01-18

## Overview

Minervia is a **documentation-first project** consisting of Markdown files (skills, agents, commands) and a single Bash installer script. There is no application code in traditional programming languages. The codebase defines behavior through structured Markdown that Claude Code interprets at runtime.

## File Types

**Primary Content:**
- `.md` files - Skills, agents, commands, and documentation
- `.sh` files - Installer script only

**No compiled code.** This is a configuration/instruction repository, not a software application.

---

## Naming Patterns

**Skill Directories:**
- Lowercase with hyphens: `log-to-daily/`, `weekly-review/`, `start-project/`
- Each directory contains a single `SKILL.md` file

**Agent Files:**
- Lowercase with hyphens: `workflow-coordinator.md`, `vault-analyst.md`, `aesthetic-definer.md`
- Location: `.claude/agents/`

**Command Files:**
- Lowercase with hyphens: `init.md`
- Location: `.claude/commands/`

**Documentation Files:**
- UPPERCASE for project-level: `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `LICENSE`
- Title case with hyphens for issue templates: `bug_report.md`, `feature_request.md`

---

## Markdown Structure

### Skill Files (`skills/*/SKILL.md`)

**Required YAML Frontmatter:**
```yaml
---
name: skill-name
description: One sentence description
use_when: When this skill should be invoked
---
```

**Alternative Frontmatter (newer style):**
```yaml
---
description: One sentence description
user-invocable: true
---
```

**Required Sections (in order):**
1. `# Skill Name` - Title
2. `## Why This Matters` - Motivation/problem statement
3. `## Configuration` - What users need to configure
4. `## Quick Start` - Shortest path to using the skill
5. `## Process` - Step-by-step instructions
6. `## Success Criteria` - Checkbox list of completion indicators

**Example structure from `skills/log-to-daily/SKILL.md`:**
```markdown
---
name: log-to-daily
description: Capture conversation activity to today's daily note...
use_when: User asks to log activity, update the daily note...
---

# Log to Daily

Capture session activity to your daily note...

## Why This Matters
...

## Configuration
...

## Quick Start
...

## Process
**Step 1: Locate the daily note**
...

## Success Criteria
- [ ] Daily note exists at correct path
- [ ] Valid frontmatter with date and tags
...
```

### Agent Files (`.claude/agents/*.md`)

**Required YAML Frontmatter:**
```yaml
---
name: agent-name
description: What the agent does and when to invoke it
tools: Read, Write, Grep, Glob, Bash, Task
model: sonnet  # or opus, haiku
---
```

**Required XML Sections:**
- `<role>` - Agent's identity and primary responsibility
- `<constraints>` - What the agent MUST/NEVER do
- `<workflow>` - Step-by-step process

**Optional XML Sections:**
- `<capabilities>` - What the agent can analyze/produce
- `<available_agents>` - For coordinators: other agents it can dispatch
- `<output_format>` - Expected output structure
- `<error_handling>` - Edge case handling
- `<quality_checklist>` - Validation before completion

**Constraint Format:**
```markdown
<constraints>
**NEVER** do X
**ALWAYS** do Y
**MUST** do Z
</constraints>
```

### Command Files (`.claude/commands/*.md`)

**No frontmatter required.** Commands are simple instruction documents.

**Typical sections:**
- `# Command Name`
- `## Task`
- `## Process`
- `## Output`

---

## Code Style (Bash)

**Single script:** `install.sh`

**Style patterns observed:**

**Color Codes:**
```bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
```

**Function definitions:**
```bash
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}ok${NC} $1"
        return 0
    else
        echo -e "${RED}x${NC} $1 not found"
        return 1
    fi
}
```

**Quoting:** Always double-quote variables: `"$VAULT_DIR"`, `"$SKILLS_SOURCE"`

**Conditionals:** Use `[[ ]]` for tests, not `[ ]`:
```bash
if [[ "$init_git" =~ ^[Yy] ]]; then
```

**Here-documents for multi-line strings:**
```bash
cat > CLAUDE.md << 'CLAUDEMD'
Content here...
CLAUDEMD
```

**Error suppression:** Use `2>/dev/null` for optional checks:
```bash
if [ -d ".obsidian" ]; then
```

---

## Documentation Style

### Tone
- Direct and prescriptive: "Use X" not "You might want to use X"
- Action-oriented: Start sections with verbs
- Problem-first: Explain why before how

### Formatting

**Tables for options:**
```markdown
| Type | Description | Default Subfolders |
|------|-------------|-------------------|
| `general` | Standard project | None |
| `software` | Code/development | Sessions/, Decisions/ |
```

**Code blocks with context:**
```markdown
**Example invocation:**
```
You: "/log-to-daily"
Claude: [Response]
```
```

**Bold for emphasis:**
- `**What gets created:**`
- `**Key point:**`
- `**Success criteria:**`

**Checkbox lists for success criteria:**
```markdown
## Success Criteria
- [ ] Project folder exists
- [ ] PROJECT.md has valid frontmatter
- [ ] All frontmatter fields populated
```

---

## Import Organization

Not applicable - no imports in Markdown/Bash project.

---

## Error Handling

### In Shell Scripts

**Check for required commands:**
```bash
if check_command "claude"; then
    CLAUDE_OK=0
else
    CLAUDE_OK=1
    echo -e "${RED}Claude Code CLI is required.${NC}"
    exit 1
fi
```

**Silent failures for optional features:**
```bash
check_command "git" || echo "   -> Version control for your vault"
check_command "jq" || echo "   -> Install with: brew install jq"
```

### In Skills/Agents

**Agents define error handling in `<error_handling>` sections:**
```markdown
<error_handling>
**No daily notes found:**
```
I couldn't locate daily notes in the expected locations...
Where do you keep your daily notes?
```

**Very few notes (< 7 days):**
...
</error_handling>
```

**Skills use process steps with validation:**
```markdown
**Step 1: Validate**
- Check if folder already exists
- Ensure completion criteria are defined
- Validate status and priority values
```

---

## Logging

### In Shell Scripts

**Echo progress to console:**
```bash
echo "Installing Minervia skills..."
echo -e "${GREEN}ok${NC} $skill_name"
```

**No file logging in install script.** Output is ephemeral, shown during installation only.

### In Skills

**Skills document their actions through vault updates:**
- Log to daily notes (`/log-to-daily`)
- Log to project files (`/log-to-project`)
- Create session logs, decision records

---

## Comments

### Shell Scripts

**Inline comments for sections:**
```bash
# Colors for output
# Check for required tools
# Detect the vault directory
# Optional checks
```

**No JSDoc/inline documentation** - script is readable without extensive comments.

### Markdown Files

**No code comments.** Documentation is the content itself.

**Inline explanations in parentheses:**
```markdown
daily_notes: "00 Daily/YYYY/"    # Where daily notes live
```

---

## Module Design

### Skills

**One skill = one directory = one SKILL.md file**
- Location: `skills/{skill-name}/SKILL.md`
- Self-contained: No cross-references to other skills (except suggestions)
- Global installation: Skills install to `~/.claude/skills/`

### Agents

**One agent = one .md file**
- Location: `.claude/agents/{agent-name}.md`
- Can reference other agents via Task tool
- Coordinators list available agents in `<available_agents>` section

### Commands

**One command = one .md file**
- Location: `.claude/commands/{command-name}.md`
- Simpler than skills: No frontmatter, fewer sections

---

## Vault Path Conventions

**Skills use configuration from CLAUDE.md:**
```markdown
## Vault Configuration
Obsidian vault path: /path/to/your/vault
Daily notes location: 00 Daily/YYYY/YYYYMMDD.md
```

**Path patterns:**
- Daily notes: `{vault}/00 Daily/YYYY/YYYYMMDD.md`
- Projects: `{vault}/02 Projects/{Project Name}/`
- Inbox: `{vault}/01 Inbox/`

**Flexible numbering:** Skills handle both `00-04` and `01-05` prefixes:
```markdown
### Note Counts by PARA Location
- **Inbox** (00 Daily/ or 01 Inbox/)
- **Projects** (01 Projects/ or 02 Projects/)
```

---

## Frontmatter Conventions

### Skill Frontmatter

```yaml
---
name: kebab-case-name
description: Single sentence, no period at end
use_when: Describes trigger conditions
---
```

### Agent Frontmatter

```yaml
---
name: kebab-case-name
description: Multi-sentence with invocation phrases
tools: Comma-separated tool list
model: sonnet | opus | haiku
---
```

### Vault Note Frontmatter (in skill templates)

```yaml
---
date: YYYY-MM-DDTHH:MM
tags: [Tag1, Tag2]
status: active | draft | complete
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

---

*Convention analysis: 2026-01-18*
