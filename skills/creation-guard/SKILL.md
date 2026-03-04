---
name: creation-guard
description: Analyze existing skills, agents, commands before creating new ones. Prevents duplicates and suggests alternatives.
use_when: Claude is about to create any new skill, agent, slash command, or CLI tool. MUST be invoked before writing any new artifact definition.
---

# Creation Guard

Prevents duplicate functionality and enforces analysis before creating new Claude Code artifacts.

## Purpose

Before creating ANY new:
- Skill (`~/.claude/skills/*/SKILL.md`)
- Agent (`~/.claude/agents/*.md`)
- Slash command (`~/.claude/commands/*.md`)

This skill MUST be invoked to:
1. Search for existing artifacts with similar functionality
2. Identify potential overlap or extension opportunities
3. Present findings with recommendation
4. Get explicit user approval before proceeding

## Trigger Phrases

Invoke this skill when you detect:
- "Create a skill for..."
- "I want a new command that..."
- "Let's add an agent for..."
- "Build a tool to..."
- Any intent to create new automation/tooling
- "Should we build/make/create..."
- "What if we had a tool that..."

---

## Analysis Process

### Step 1: Identify the Proposal

Extract from the request:
- **Name**: Proposed name for the artifact
- **Type**: skill | agent | command
- **Purpose**: What it does (one sentence)
- **Key Functions**: 3-5 main capabilities
- **Keywords**: Searchable terms related to functionality

### Step 2: Search Existing Artifacts

Run these searches:

```bash
# Skills - search names and descriptions
for skill in ~/.claude/skills/*/SKILL.md; do
  echo "=== $(basename $(dirname $skill)) ==="
  head -20 "$skill"
done

# Agents - search all agent definitions
for agent in ~/.claude/agents/*.md; do
  echo "=== $(basename $agent) ==="
  head -20 "$agent"
done

# Commands - search all command definitions
for cmd in ~/.claude/commands/*.md; do
  echo "=== $(basename $cmd) ==="
  head -10 "$cmd"
done
```

Also search by keywords:
```bash
grep -ril "[keyword]" ~/.claude/skills/ ~/.claude/agents/ ~/.claude/commands/
```

### Step 3: Analyze Overlap

For each potentially related artifact, assess:

| Criterion | Question |
|-----------|----------|
| Functional overlap | Does it do the same thing? (0-100%) |
| Naming confusion | Could names be confused? |
| Extension potential | Could the proposal extend this instead? |

### Step 4: Generate Recommendation

Based on analysis, recommend ONE of:

| Recommendation | Criteria | Action |
|----------------|----------|--------|
| **PROCEED** | <20% overlap, genuinely new capability | Create new artifact |
| **EXTEND** | 50%+ overlap with single existing artifact | Modify existing instead |
| **BLOCK** | Would create problematic duplication | Do not create |

---

## Output Format

```
════════════════════════════════════════════════════════
CREATION GUARD ANALYSIS
════════════════════════════════════════════════════════

PROPOSAL:
  Type: [skill|agent|command]
  Name: [proposed-name]
  Purpose: [one sentence]

EXISTING ARTIFACTS ANALYZED: [count]

RELATED ARTIFACTS FOUND:

1. [artifact-name] ([type])
   Purpose: [what it does]
   Overlap: [X]% - [explanation]

RECOMMENDATION: [PROCEED|EXTEND|BLOCK]

RATIONALE:
[2-3 sentences explaining the recommendation]

SUGGESTED ACTION:
[Specific next step based on recommendation]
════════════════════════════════════════════════════════
Proceed with creation? (y/n)
════════════════════════════════════════════════════════
```

---

## Self-Check Questions

Before creating ANY new artifact, ask:

1. Does something similar already exist?
2. Could this be added to an existing artifact?
3. Would a user know to look for this vs the existing one?
4. Am I creating this because it's needed or because it's easier than finding what exists?

---

## Examples

### Example: Duplicate Detection

User: "Create a skill for detecting AI-generated writing patterns"

Analysis finds: `antislop` skill already exists with 95% functional overlap.

**Recommendation: BLOCK**
- antislop already detects AI writing patterns
- User should use existing skill

### Example: Extension Opportunity

User: "Create a command for logging work to projects"

Analysis finds: `log-to-daily` skill exists (70% overlap)

**Recommendation: EXTEND**
- log-to-daily logs to daily notes
- Suggest: Add project targeting to existing skill

### Example: Genuine New Need

User: "Create a skill for managing analytics"

Analysis finds: No existing analytics skills.

**Recommendation: PROCEED**
- New capability not covered by existing artifacts
- Proceed with creation
