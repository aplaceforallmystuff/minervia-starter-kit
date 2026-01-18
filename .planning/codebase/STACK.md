# Technology Stack

**Analysis Date:** 2026-01-18

## Languages

**Primary:**
- Markdown - Core content format for all skills, agents, commands, and documentation
- Bash - Installation script (`install.sh`) and vault operations

**Secondary:**
- YAML - Frontmatter metadata in Markdown files
- JSON - Configuration files (`.claude/settings.json`)

## Runtime

**Environment:**
- Claude Code CLI (Anthropic) - Required runtime for skill execution
- Claude Pro ($20/month) or Claude Max ($200/month) subscription required
- Terminal/Shell environment

**Package Manager:**
- Not applicable - This is not a Node.js/Python package
- Skills install via bash script to `~/.claude/skills/`

## Frameworks

**Core:**
- Claude Code Skills Framework - Markdown-based skill definitions with YAML frontmatter
- Claude Code Agents Framework - More sophisticated orchestration agents in `.claude/agents/`
- PARA Methodology - Projects, Areas, Resources, Archive organization system

**No Traditional Frameworks:**
- This project does not use React, Express, Django, etc.
- It is a collection of Markdown-based Claude Code configurations

## Key Dependencies

**Critical:**
- Claude Code CLI - The entire system depends on this being installed
- Obsidian - Target note-taking application (free, files stay local)

**Optional:**
- Git - Version control for vault
- jq - JSON processing for advanced operations

## Configuration

**Environment:**
- No environment variables required
- Configuration via `CLAUDE.md` in vault root
- Skill-specific config embedded in skill files

**Settings Files:**
- `.claude/settings.json` - Permissions and hooks configuration
- `CLAUDE.md` - Vault-specific configuration (user customizes)

**Example CLAUDE.md configuration:**
```yaml
vault:
  name: "My Vault"
  daily_notes: "00 Daily/YYYY/"
  inbox: "01 Inbox/"
  projects: "02 Projects/"
  areas: "03 Areas/"
  resources: "04 Resources/"
  archive: "05 Archive/"
```

## Platform Requirements

**Development:**
- macOS (fully supported)
- Linux (fully supported)
- Windows via WSL (supported)
- Node.js v18+ (for Claude Code CLI installation via npm)

**Production:**
- Runs locally on user's machine
- No server deployment
- No cloud hosting required

## Project Structure

**Key Directories:**
- `skills/` - Reusable Claude Code skills
- `.claude/agents/` - Multi-step orchestration agents
- `.claude/commands/` - User-invokable commands
- `docs/images/` - Documentation assets

**File Types:**
| Extension | Purpose | Count |
|-----------|---------|-------|
| `.md` | Skills, agents, docs | Primary content |
| `.sh` | Installation | 1 file |
| `.json` | Configuration | 1 file |
| `.svg/.png` | Documentation images | 4 files |

## Claude Code Integration

**Skills Format:**
```markdown
---
name: skill-name
description: One sentence description
use_when: Trigger conditions
---

# Skill content
```

**Agents Format:**
```markdown
---
name: agent-name
description: What agent does
tools: Read, Write, Grep, Glob, Bash, Task
model: sonnet | opus | haiku
---

<role>...</role>
<workflow>...</workflow>
```

**Hooks Configuration (`.claude/settings.json`):**
```json
{
  "hooks": {
    "SessionStart": [...]
  },
  "permissions": {
    "allow": ["Bash(git status:*)"]
  }
}
```

---

*Stack analysis: 2026-01-18*
