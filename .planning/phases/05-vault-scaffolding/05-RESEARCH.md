# Phase 5: Vault Scaffolding - Research

**Researched:** 2026-01-18
**Domain:** Obsidian vault structure, PARA methodology, templates, YAML frontmatter
**Confidence:** HIGH

## Summary

Phase 5 creates PARA folder structure, templates, and example notes for NEW vaults only. The `IS_NEW_VAULT` variable is already set and exported from Phase 4, making this phase straightforward gating logic.

The implementation requires:
1. Conditional execution based on `IS_NEW_VAULT=true`
2. PARA folder creation with numbered prefixes (00-05)
3. Obsidian-compatible templates with YAML frontmatter
4. Example notes demonstrating each PARA section's purpose

The key insight: Templates should use Obsidian's **core Templates plugin** variables (`{{date}}`, `{{title}}`) rather than Templater syntax, since we cannot assume users have Templater installed. However, templates are static files - they will need manual activation by the user in Obsidian's Templates settings.

**Primary recommendation:** Create template files in a `Templates/` subfolder within the vault, using Obsidian's core template variable syntax. Example notes should be minimal, demonstrating structure rather than overwhelming new users.

## Standard Stack

### Core
| Tool | Purpose | Why Standard |
|------|---------|--------------|
| mkdir -p | Create PARA folder hierarchy | POSIX standard, -p creates parents |
| cat > file | Write template/example files | Universal, no dependencies |
| IS_NEW_VAULT | Gate all Phase 5 logic | Already exported from Phase 4 |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| heredoc (cat <<'EOF') | Multi-line file content | Template and example note content |
| brace expansion | Create multiple folders | `mkdir -p {00,01,02,...}` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Individual mkdir calls | mkdir with brace expansion | Expansion is cleaner, single command |
| echo for file content | heredoc | Heredoc preserves formatting, handles special chars |
| External template files | Inline heredocs | Inline is simpler for few files, but external is more maintainable |

**Installation:**
No additional dependencies required. All operations use standard bash and existing install.sh patterns.

## Architecture Patterns

### Recommended Code Structure

Phase 5 code should be inserted into install.sh AFTER vault detection and BEFORE skills installation:

```
install.sh flow:
├── ... prerequisites, questionnaire ...
├── VAULT_DIR set from ANSWERS[vault_path]
├── cd "$VAULT_DIR"
├── detect_vault_type()              # Phase 4: Sets IS_NEW_VAULT
├── generate_claudemd()              # Phase 4: CLAUDE.md creation
├── scaffold_new_vault()             # NEW: Phase 5 - conditional on IS_NEW_VAULT
│   ├── create_para_folders()
│   ├── create_templates()
│   └── create_example_notes()
└── ... skills installation, git setup ...
```

### Pattern 1: Conditional Execution Gate

**What:** All scaffolding wrapped in IS_NEW_VAULT check
**When to use:** Entry point for all Phase 5 operations
**Why:** Existing vaults must never be modified

**Example:**
```bash
# Phase 5: Vault scaffolding (new vaults only)
scaffold_new_vault() {
    if [[ "$IS_NEW_VAULT" != "true" ]]; then
        echo -e "${YELLOW}Skipping:${NC} Vault scaffolding (existing vault)"
        return 0
    fi

    echo ""
    echo "Creating vault structure..."
    create_para_folders
    create_templates
    create_example_notes
}
```

### Pattern 2: PARA Folder Creation with Brace Expansion

**What:** Create all PARA folders in single command
**When to use:** Initial folder structure creation

**Example:**
```bash
create_para_folders() {
    local folders=(
        "00 Daily/$(date +%Y)"
        "01 Inbox"
        "02 Projects"
        "03 Areas"
        "04 Resources"
        "04 Resources/Templates"
        "05 Archive"
    )

    for folder in "${folders[@]}"; do
        mkdir -p "$folder"
        echo -e "${GREEN}+${NC} $folder/"
    done
}
```

### Pattern 3: Template Files with Core Plugin Syntax

**What:** Use Obsidian's built-in template variables
**When to use:** All template files
**Why:** No dependency on community plugins

**Core Template Variables (Obsidian built-in):**
| Variable | Output | Format Customization |
|----------|--------|---------------------|
| `{{date}}` | Current date | `{{date:YYYY-MM-DD}}` |
| `{{time}}` | Current time | `{{time:HH:mm}}` |
| `{{title}}` | Note title | N/A |

**Example Template:**
```markdown
---
created: {{date:YYYY-MM-DD}}
tags: []
---

# {{title}}

## Notes

```

### Pattern 4: Heredoc for Multi-line File Content

**What:** Use quoted heredoc to preserve content exactly
**When to use:** Writing template and example files
**Why:** Handles special characters, preserves indentation

**Example:**
```bash
cat > "04 Resources/Templates/Daily Note.md" << 'TEMPLATE'
---
created: {{date:YYYY-MM-DD}}
tags: [daily]
---

# {{date:dddd, MMMM D, YYYY}}

## Today's Focus

-

## Notes

## End of Day

**What went well:**

**What to improve:**
TEMPLATE
```

### Anti-Patterns to Avoid

- **Creating folders in existing vaults:** Gate ALL operations on IS_NEW_VAULT
- **Using Templater syntax:** `<% tp.date.now() %>` requires community plugin
- **Overly complex templates:** Start minimal, users can customize
- **Nested YAML in frontmatter:** Obsidian Properties don't support nested YAML well
- **Creating .obsidian folder:** Let Obsidian create this on first open

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Date formatting | Custom date logic | `date +%Y` or template vars | portable_date exists; template vars are standard |
| Template syntax | Custom placeholders | Obsidian `{{date}}` syntax | Users expect Obsidian-compatible templates |
| Folder existence check | if/then/else | mkdir -p | -p is idempotent, handles existing folders |
| Multi-line file writes | echo with \n | heredoc (cat <<'EOF') | Cleaner, preserves formatting |

**Key insight:** The scaffolding should create plain files that Obsidian recognizes immediately. No custom preprocessing needed - Obsidian handles template variable substitution when users apply templates.

## Common Pitfalls

### Pitfall 1: Modifying Existing Vaults

**What goes wrong:** User runs installer again, gets duplicate folders or overwrites
**Why it happens:** Missing or incorrect IS_NEW_VAULT check
**How to avoid:** Gate ALL Phase 5 operations on `IS_NEW_VAULT == true`
**Warning signs:** User complaints about structure changes

```bash
# WRONG: No gate
create_para_folders

# RIGHT: Gated
if [[ "$IS_NEW_VAULT" == "true" ]]; then
    create_para_folders
fi
```

### Pitfall 2: Template Syntax Confusion

**What goes wrong:** Templates don't work because wrong plugin syntax used
**Why it happens:** Templater syntax (`<% tp.date.now() %>`) vs core Templates (`{{date}}`)
**How to avoid:** Use ONLY core Templates plugin variables
**Warning signs:** Variables appear literally instead of being substituted

```markdown
# WRONG: Templater syntax (requires plugin)
<% tp.date.now("YYYY-MM-DD") %>

# RIGHT: Core Templates syntax (built-in)
{{date:YYYY-MM-DD}}
```

### Pitfall 3: Invalid YAML Frontmatter

**What goes wrong:** Obsidian shows "Invalid properties" error
**Why it happens:** Incorrect YAML formatting or unsupported types
**How to avoid:** Use simple key-value pairs, avoid nested structures
**Warning signs:** Properties panel shows errors

```yaml
# WRONG: Complex nested structure
metadata:
  created:
    date: 2025-01-18
    by: user

# RIGHT: Flat structure
created: 2025-01-18
author: user
```

### Pitfall 4: Spaces in Folder Names

**What goes wrong:** mkdir fails or creates wrong folder
**Why it happens:** Unquoted variables with spaces
**How to avoid:** Always quote folder paths
**Warning signs:** Folders like "00" and "Daily" created separately

```bash
# WRONG: Unquoted
mkdir -p $folder

# RIGHT: Quoted
mkdir -p "$folder"
```

### Pitfall 5: Template Location Not Discoverable

**What goes wrong:** Users can't find or use templates
**Why it happens:** Templates in unexpected location
**How to avoid:** Use conventional `Templates/` subfolder, add guidance
**Warning signs:** "How do I use these templates?" questions

## Code Examples

### Complete PARA Folder Creation

```bash
# Source: Derived from install.sh patterns and PARA methodology

create_para_folders() {
    local current_year
    current_year=$(date +%Y)

    local folders=(
        "00 Daily/$current_year"
        "01 Inbox"
        "02 Projects"
        "03 Areas"
        "04 Resources"
        "04 Resources/Templates"
        "05 Archive"
    )

    for folder in "${folders[@]}"; do
        if mkdir -p "$folder" 2>/dev/null; then
            echo -e "${GREEN}+${NC} $folder/"
        else
            echo -e "${RED}!${NC} Failed to create: $folder"
        fi
    done
}
```

### Daily Note Template

```bash
# Source: Obsidian core Templates plugin syntax

create_daily_template() {
    cat > "04 Resources/Templates/Daily Note.md" << 'TEMPLATE'
---
created: {{date:YYYY-MM-DD}}
tags: [daily]
---

# {{date:dddd, MMMM D, YYYY}}

## Focus

What's the main thing to accomplish today?

-

## Notes

## Reflection

**What went well:**

**What to improve:**

TEMPLATE
    echo -e "${GREEN}+${NC} Templates/Daily Note.md"
}
```

### Project Template

```bash
# Source: PARA methodology and Obsidian frontmatter best practices

create_project_template() {
    cat > "04 Resources/Templates/Project.md" << 'TEMPLATE'
---
created: {{date:YYYY-MM-DD}}
status: active
tags: [project]
due:
---

# {{title}}

## Overview

What is this project and why does it matter?

## Success Criteria

How will you know when this project is complete?

- [ ]

## Next Actions

- [ ]

## Notes

## Related

-

TEMPLATE
    echo -e "${GREEN}+${NC} Templates/Project.md"
}
```

### Area Template

```bash
# Source: PARA methodology

create_area_template() {
    cat > "04 Resources/Templates/Area.md" << 'TEMPLATE'
---
created: {{date:YYYY-MM-DD}}
tags: [area]
---

# {{title}}

## Purpose

Why is this area important? What responsibility does it represent?

## Standards

What does success look like in this area?

-

## Current Focus

What aspects need attention right now?

## Resources

Related projects, notes, and references.

-

TEMPLATE
    echo -e "${GREEN}+${NC} Templates/Area.md"
}
```

### Example Notes

```bash
# Source: Best practices from Obsidian community starter vaults

create_example_notes() {
    # Inbox example
    cat > "01 Inbox/Welcome to your Inbox.md" << 'EXAMPLE'
# Welcome to your Inbox

This folder is for quick capture - ideas, links, notes that haven't been organized yet.

**How to use:**
1. Capture anything here without worrying about organization
2. During your weekly review, process items:
   - Move to appropriate PARA folder
   - Delete if no longer relevant
   - Add to a project or area

**Tip:** Keep the inbox small. If it grows too large, it becomes overwhelming.
EXAMPLE
    echo -e "${GREEN}+${NC} 01 Inbox/Welcome to your Inbox.md"

    # Projects example
    cat > "02 Projects/Example Project.md" << 'EXAMPLE'
---
created: 2025-01-01
status: example
tags: [project, example]
due: 2025-03-01
---

# Example Project

> Delete this file once you understand the structure.

## Overview

Projects have a **deadline** and a clear **definition of done**. When complete, move them to Archive.

## Success Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] All criteria met = project complete

## Next Actions

- [ ] First actionable step
- [ ] Second step (add as you go)

## Notes

Add meeting notes, research, decisions here.

## Related

- [[Example Area]] - The area this project supports
EXAMPLE
    echo -e "${GREEN}+${NC} 02 Projects/Example Project.md"

    # Areas example
    cat > "03 Areas/Example Area.md" << 'EXAMPLE'
---
created: 2025-01-01
tags: [area, example]
---

# Example Area

> Delete this file once you understand the structure.

## Purpose

Areas are **ongoing responsibilities** without end dates. Examples:
- Health
- Finances
- Career
- Relationships
- Home

## Standards

What does "good enough" look like for this area?

- Standard 1
- Standard 2

## Current Focus

What aspects need attention right now?

## Related Projects

- [[Example Project]]
EXAMPLE
    echo -e "${GREEN}+${NC} 03 Areas/Example Area.md"

    # Archive explanation
    cat > "05 Archive/About the Archive.md" << 'EXAMPLE'
# About the Archive

This folder holds **completed projects** and **inactive items**.

**When to archive:**
- Project is complete (all success criteria met)
- Area is no longer relevant
- Reference material is outdated but worth keeping

**Archive structure:**
Some people organize by year (Archive/2025/), others keep it flat. Do what works for you.

**Remember:** Archived doesn't mean deleted. You can always search or move things back.
EXAMPLE
    echo -e "${GREEN}+${NC} 05 Archive/About the Archive.md"
}
```

### Main Scaffolding Function

```bash
# Source: Consolidation of all Phase 5 patterns

scaffold_new_vault() {
    if [[ "$IS_NEW_VAULT" != "true" ]]; then
        echo -e "${YELLOW}Skipping:${NC} Vault scaffolding (existing vault detected)"
        return 0
    fi

    echo ""
    echo "Creating PARA folder structure..."
    create_para_folders

    echo ""
    echo "Creating templates..."
    create_daily_template
    create_project_template
    create_area_template

    echo ""
    echo "Creating example notes..."
    create_example_notes

    echo ""
    echo -e "${GREEN}✓${NC} Vault scaffolding complete"
    echo ""
    echo -e "${YELLOW}Tip:${NC} Configure Obsidian to use Templates folder:"
    echo "     Settings → Core plugins → Templates → Template folder: 04 Resources/Templates"
}
```

## Template Structure Recommendation

Based on research of popular Obsidian starter vaults and PARA methodology:

### Minimal Template Approach

Start with three core templates:
1. **Daily Note** - For journal/daily capture
2. **Project** - For active work with deadlines
3. **Area** - For ongoing responsibilities

**Rationale:** Most users only need these three. Resource notes are usually too varied to template effectively. Users can add more templates as their workflow evolves.

### Frontmatter Properties

| Property | Type | Purpose | Example |
|----------|------|---------|---------|
| `created` | date | When note was created | `{{date:YYYY-MM-DD}}` |
| `tags` | list | Categorization | `[project, work]` |
| `status` | text | Current state | `active`, `complete`, `on-hold` |
| `due` | date | Deadline (projects) | `2025-03-01` |

**Note:** Keep frontmatter simple. Users with Dataview can add more properties later.

### Example Notes Philosophy

Example notes should:
- **Explain the folder's purpose** - What goes here?
- **Show the structure** - What does a typical note look like?
- **Be deletable** - Marked as examples, not permanent fixtures
- **Link to each other** - Demonstrate Obsidian's linking power

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Templater-dependent templates | Core plugin syntax | N/A (design choice) | Works without community plugins |
| Complex example vault | Minimal scaffolding | N/A (design choice) | Less overwhelming for new users |
| No example notes | Simple examples in each folder | N/A (design choice) | Users understand purpose immediately |

**Current ecosystem trends:**
- Starter vaults are moving toward minimal scaffolding
- Templates focus on frontmatter + basic structure
- Example notes are brief, marked as deletable
- Complex automation left to user customization

## Open Questions

Things that couldn't be fully resolved:

1. **Should templates go in Resources or a dedicated Templates folder?**
   - What we know: Obsidian expects templates in a configurable folder
   - Options: `Templates/`, `04 Resources/Templates/`, root `_templates/`
   - Recommendation: `04 Resources/Templates/` - keeps PARA consistent, clearly part of Resources

2. **Should we create a .obsidian folder with template settings?**
   - What we know: This would pre-configure template location
   - Risk: Obsidian may overwrite or conflict with user's existing settings
   - Recommendation: Don't create .obsidian. Let Obsidian initialize it. Add setup guidance in output message.

3. **How many example notes?**
   - What we know: Too many is overwhelming, too few leaves users confused
   - Recommendation: One example per PARA folder (5 total), all marked as deletable

## Sources

### Primary (HIGH confidence)
- install.sh (lines 620-644) - IS_NEW_VAULT detection pattern already implemented
- [Obsidian Templates documentation](https://help.obsidian.md/Plugins/Templates) - Core template variables
- [PARA Starter Kit](https://publish.obsidian.md/hub/03+-+Showcases+%26+Templates/Vaults/PARA+Starter+Kit) - Community example

### Secondary (MEDIUM confidence)
- [Obsidian Forum - YAML frontmatter formatting](https://forum.obsidian.md/t/yaml-frontmatter-formatting/43673) - Property best practices
- [Obsidian Forum - PARA folder structure](https://forum.obsidian.md/t/the-ultimate-folder-system-a-quixotic-journey-to-ace/63483) - Community patterns
- [SoRobby/ObsidianStarterVault](https://github.com/SoRobby/ObsidianStarterVault) - Project template structure
- [Dann Berg - Daily Note Template](https://dannb.org/blog/2022/obsidian-daily-note-template/) - Minimal template philosophy

### Tertiary (LOW confidence)
- WebSearch results for starter vaults - Used for pattern validation, not authoritative

## Metadata

**Confidence breakdown:**
- PARA folder structure: HIGH - Well-documented methodology, install.sh already has patterns
- Template syntax: HIGH - Obsidian's core Templates plugin is stable and documented
- YAML frontmatter: HIGH - Obsidian Properties feature is well-established
- Example note content: MEDIUM - Based on community patterns, subjective best practices

**Research date:** 2026-01-18
**Valid until:** 2026-02-18 (30 days - Obsidian core features are stable)
