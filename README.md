# Minervia Starter Kit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blueviolet)](https://claude.ai/download)
[![Obsidian](https://img.shields.io/badge/Obsidian-Compatible-7c3aed)](https://obsidian.md)

A co-operating system for human-led knowledge work. Terminal-native AI that treats your Obsidian vault as persistent memory.

**You lead. AI assists. Your vault remembers.**

## What Is Minervia?

Minervia configures Claude Code for knowledge work, not just programming. The terminal is the point — no cluttered interfaces, no context-switching between apps, just you and a conversation that can actually *do things*.

### ✨ Features

- 📝 **Activity Logging** — Capture session work to daily notes automatically
- 🎯 **Project Documentation** — Log progress to specific project folders
- 🔄 **Weekly Reviews** — Process inbox and maintain vault health
- 🧠 **Decision Frameworks** — Apply mental models before big decisions
- 🏗️ **Project Templates** — Initialize new projects with proper structure
- 📖 **Retrospectives** — Learn from wins and failures systematically

### The Four Pillars

| Component | Role |
|-----------|------|
| **Obsidian** | Your memory — structured, searchable, yours |
| **MCP Servers** | Bridges to calendars, email, APIs, services |
| **Claude Code** | The brain — reasoning with full vault context |
| **Terminal** | Your hands — direct, efficient, distraction-free |

## Quick Start

### 1. Prerequisites

| Requirement | Cost | Notes |
|-------------|------|-------|
| [Obsidian](https://obsidian.md/download) | **Free** | Download for macOS, Windows, or Linux. Personal use is free forever. |
| [Claude Code](https://claude.ai/download) | **Paid** | Requires a Claude subscription ($20/month Pro or $200/month Max). Install via `npm install -g @anthropic-ai/claude-code` or download directly. |

> **💡 Already have Claude Pro/Max?** Claude Code is included with your subscription — no additional cost.

### 2. Install

```bash
# Clone the starter kit
git clone https://github.com/aplaceforallmystuff/minervia-starter-kit.git

# Navigate to your Obsidian vault
cd /path/to/your/obsidian/vault

# Run the installer from the starter kit
/path/to/minervia-starter-kit/install.sh
```

Or copy manually:
```bash
# Copy skills to your Claude Code skills directory
cp -r minervia-starter-kit/skills/* ~/.claude/skills/

# Copy CLAUDE.md template to your vault
cp minervia-starter-kit/CLAUDE.md /path/to/your/vault/
```

### 3. Configure

Edit `CLAUDE.md` in your vault to match your folder structure:

```yaml
vault:
  daily_notes: "00 Daily/YYYY/"    # Where daily notes live
  inbox: "01 Inbox/"               # Quick capture location
  projects: "02 Projects/"         # Active projects
  # ... adjust to your structure
```

### 4. Use

```bash
cd /path/to/your/vault
claude
```

Then: describe what you're working on. Claude reads your vault, understands your context, and helps you think.

## Included Skills

Skills install to `~/.claude/skills/` and work in any vault:

| Skill | What It Does |
|-------|--------------|
| `/log-to-daily` | Logs session activity to today's daily note |
| `/log-to-project` | Documents work to a specific project folder |
| `/lessons-learned` | Runs a structured retrospective after wins or failures |
| `/start-project` | Initializes a new project with proper structure |
| `/weekly-review` | Processes inbox and maintains vault health |
| `/think-first` | Applies mental models before major decisions |

## The Compound Loop

```
Work → Conversation → Skill invocation → Vault update → Informed future work
```

Every session that updates your vault makes the next session smarter. This is continuous context — the thing standard AI loses between conversations.

## Workflow Examples

### Starting Your Day

```bash
cd ~/vault && claude
> "What was I working on yesterday? What's on my calendar today?"
```

Claude searches your daily notes, checks your calendar (if configured), and helps you plan.

### Making a Decision

```
> /think-first first-principles
> "Should I build this feature myself or use a third-party service?"
```

The skill walks you through structured thinking before you commit.

### Ending a Session

```
> /log-to-daily
```

Captures what happened — tomorrow's Claude knows what you did today.

### Weekly Maintenance

```
> /weekly-review
```

Processes inbox, updates project statuses, maintains vault health.

## Vault Agnostic

Minervia works with any Obsidian organization system:

- **PARA** (Projects, Areas, Resources, Archive)
- **Zettelkasten** (atomic notes with links)
- **Date-based** (daily notes as primary structure)
- **Custom** (whatever works for you)

Just configure the paths in CLAUDE.md.

## Extending Minervia

### Add MCP Servers

Connect Claude to external services:

```bash
# Example: Add calendar integration
claude mcp add fantastical
```

### Create Custom Skills

Add skills to `~/.claude/skills/your-skill/SKILL.md`:

```markdown
# Your Skill

Instructions for Claude when this skill is invoked.

## use_when
User asks to do [specific task]

## process
1. Step one
2. Step two
3. Step three
```

## Philosophy

- **Terminal is clarity** — fewer distractions, more focus
- **You lead** — Claude assists, you decide
- **Context compounds** — every session makes the next better
- **Integration over capability** — connecting tools beats isolated features

## Requirements

| Platform | Status |
|----------|--------|
| macOS | ✅ Fully supported |
| Linux | ✅ Fully supported |
| Windows (WSL) | ✅ Supported via WSL |

**Software:**
- [Obsidian](https://obsidian.md/download) — Free, open-source note-taking app
- [Claude Code](https://claude.ai/download) — Requires Claude Pro ($20/mo) or Max ($200/mo) subscription

## License

MIT

---

*Start with a vault and a conversation. Add complexity when you need it — not before.*

Learn more at [minervia.co](https://minervia.co)
