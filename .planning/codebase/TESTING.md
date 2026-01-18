# Testing Patterns

**Analysis Date:** 2026-01-18

## Test Framework

**Status:** No automated test framework detected

This is a documentation/configuration repository, not a software application. There are:
- No test directories (`tests/`, `__tests__/`, `spec/`)
- No test configuration files (`jest.config.*`, `vitest.config.*`, `pytest.ini`)
- No test scripts in package.json (no package.json exists)
- No test files (`*.test.*`, `*.spec.*`)

---

## Testing Approach

### Manual Testing

The project relies on **manual verification** during development:

**Shell Script Testing:**
```bash
# Make script executable and run
chmod +x install.sh
./install.sh

# Verify skills installed
ls ~/.claude/skills/

# Verify in target vault
ls /path/to/vault/CLAUDE.md
ls /path/to/vault/.claude/settings.json
```

**Skill Testing:**
1. Install skills to `~/.claude/skills/`
2. Open Claude Code in a test vault
3. Invoke the skill: `/skill-name`
4. Verify behavior matches documentation

### Validation Embedded in Skills

Skills define their own **Success Criteria** as validation checklists:

**From `skills/log-to-daily/SKILL.md`:**
```markdown
## Success Criteria
- [ ] Daily note exists at correct path
- [ ] Valid frontmatter with date and tags
- [ ] All significant session activity captured
- [ ] Content organized into logical sections
- [ ] Related files linked with wiki syntax
- [ ] "Files Created Today" section includes any new files
```

**From `skills/start-project/SKILL.md`:**
```markdown
## Success Criteria
- [ ] Project folder exists
- [ ] PROJECT.md has valid frontmatter
- [ ] All frontmatter fields populated (no placeholders)
- [ ] At least one completion criterion defined
- [ ] Appropriate subfolders created
- [ ] User shown the created structure
```

### Agent Quality Checklists

Agents include `<quality_checklist>` sections as self-validation:

**From `.claude/agents/vault-analyst.md`:**
```markdown
<quality_checklist>
Before delivering analysis:
- [ ] Date range clearly stated
- [ ] All patterns cite specific evidence
- [ ] Recommendations are specific, not generic
- [ ] Effort estimates are realistic
- [ ] No sensitive content quoted verbatim
- [ ] Top 3 recommendations highlighted
- [ ] Data quality limitations noted
- [ ] Next steps are actionable
</quality_checklist>
```

**From `.claude/agents/aesthetic-definer.md`:**
```markdown
<quality_checklist>
Before delivering aesthetic.md:
- [ ] All colors have hex codes
- [ ] Usage percentages specified (70-20-10 or similar)
- [ ] "What to AVOID" section is substantive
- [ ] Prompt integration phrases are specific and usable
- [ ] Quick reference table is complete
- [ ] Philosophy statement captures brand personality
- [ ] Color choices align with stated brand personality
- [ ] Line style matches desired formality level
</quality_checklist>
```

---

## Shell Script Validation

### Recommended Pre-Commit Checks

**From `CONTRIBUTING.md`:**
```markdown
### Code Style
- Shell scripts should pass `shellcheck`
```

**Manual shellcheck validation:**
```bash
# Install shellcheck (if not installed)
brew install shellcheck

# Validate install.sh
shellcheck install.sh
```

### Install Script Self-Checks

The installer performs runtime validation:

**Prerequisite checks:**
```bash
# Check for required tools
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}ok${NC} $1"
        return 0
    else
        echo -e "${RED}x${NC} $1 not found"
        return 1
    fi
}

# Required
if check_command "claude"; then
    CLAUDE_OK=0
else
    CLAUDE_OK=1
    echo -e "${RED}Claude Code CLI is required.${NC}"
    exit 1
fi

# Optional
check_command "git" || echo "   -> Version control for your vault"
check_command "jq" || echo "   -> Install with: brew install jq"
```

**Vault detection:**
```bash
if [ -d ".obsidian" ]; then
    echo -e "${GREEN}ok${NC} Obsidian vault detected"
else
    echo -e "${YELLOW}!${NC} No .obsidian folder found"
fi
```

**Skip existing files:**
```bash
if [ -d "$target_dir" ]; then
    echo -e "${YELLOW}->${NC} $skill_name (already exists, skipping)"
else
    cp -r "$skill_dir" "$target_dir"
    echo -e "${GREEN}ok${NC} $skill_name"
fi
```

---

## Documentation Testing

### README Verification Checklist

From project patterns, documentation should be verified for:

1. **Installation instructions work:**
   - Clone command succeeds
   - Install script runs without errors
   - Skills appear in `~/.claude/skills/`

2. **Skill list matches actual skills:**
   ```bash
   # Compare README list to actual skills
   ls skills/
   # Should match: lessons-learned, log-to-daily, log-to-project,
   #               start-project, think-first, vault-stats, weekly-review
   ```

3. **Example conversations are realistic:**
   - Invocation syntax matches skill names
   - Claude responses match skill behavior

---

## Integration Testing Approach

### Recommended Manual Test Workflow

**Test new skill installation:**
```bash
# 1. Create test vault
mkdir -p ~/test-vault/.obsidian
cd ~/test-vault

# 2. Run installer
/path/to/minervia-starter-kit/install.sh

# 3. Verify files created
ls -la ~/.claude/skills/
ls -la CLAUDE.md
ls -la .claude/

# 4. Start Claude and test
claude
> "List available skills"
> "/vault-stats"
```

**Test skill behavior:**
```bash
# In a vault with daily notes
cd ~/real-vault
claude
> "/log-to-daily"
# Verify: Daily note updated with session content

> "/start-project"
# Verify: Project folder and PROJECT.md created
```

---

## Mocking

Not applicable - no mocking framework needed for Markdown/Bash project.

**For skill testing:**
- Use a dedicated test vault with known structure
- Create predictable daily notes for testing
- Verify file system changes after skill execution

---

## Fixtures and Factories

### Test Vault Structure

For testing skills, create a vault with this structure:

```
test-vault/
  .obsidian/          # Required for vault detection
  CLAUDE.md           # Vault configuration
  00 Daily/
    2026/
      20260118.md     # Sample daily note
  01 Inbox/
    test-note.md      # Inbox item for weekly-review testing
  02 Projects/
    Test Project/
      PROJECT.md      # Sample project
```

### Sample Daily Note Fixture

```markdown
---
date: 2026-01-18T10:00
tags: [Daily]
---
# DAILY NOTE
### *Saturday, January 18th, 2026*

## Journal
Testing Minervia skills today.

---

## Files Created Today
- [[Test Note]]
```

### Sample PROJECT.md Fixture

```markdown
---
project: "Test Project"
type: "general"
status: "active"
priority: "medium"
area: "testing"
start_date: "2026-01-18"
target_completion: ""
tags:
  - project
created: "2026-01-18"
updated: "2026-01-18"
---

# Test Project

## Overview
**Goal:** Test skill behavior

## Completion Criteria
- [ ] Skills run without errors
- [ ] Files created in correct locations
```

---

## Coverage

**Status:** Not applicable

No code coverage tools or requirements. This is a documentation project.

**What would coverage mean here:**
- All skills have documented success criteria
- All agents have quality checklists
- All edge cases in `<error_handling>` sections
- All configuration options documented

---

## Test Types

### Unit Tests
Not applicable - no units to test.

### Integration Tests
Manual verification that skills work with Claude Code and vault structure.

### E2E Tests
**Not implemented.** Could theoretically automate with:
- Claude Code in headless/scripted mode (if available)
- File system assertions after skill execution

---

## Recommended Testing Improvements

### 1. Add Shell Script Tests

Create `tests/install.sh.bats` using [Bats](https://github.com/bats-core/bats-core):

```bash
#!/usr/bin/env bats

@test "check_command returns 0 for existing command" {
  source ./install.sh
  run check_command "ls"
  [ "$status" -eq 0 ]
}

@test "check_command returns 1 for missing command" {
  source ./install.sh
  run check_command "nonexistent_command_xyz"
  [ "$status" -eq 1 ]
}
```

### 2. Add Markdown Linting

```bash
# Install markdownlint-cli
npm install -g markdownlint-cli

# Lint all markdown files
markdownlint "**/*.md"
```

### 3. Add Link Checking

```bash
# Check for broken links in documentation
npx markdown-link-check README.md
```

### 4. CI/CD Validation

Create `.github/workflows/validate.yml`:

```yaml
name: Validate
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint shell scripts
        run: shellcheck install.sh
      - name: Lint markdown
        run: npx markdownlint "**/*.md"
```

---

## Common Testing Patterns

### Verifying Skill Creates Expected Files

```bash
# Before
ls ~/test-vault/02\ Projects/

# Run skill
# (in Claude) /start-project "Test Project"

# After - verify
ls ~/test-vault/02\ Projects/Test\ Project/
cat ~/test-vault/02\ Projects/Test\ Project/PROJECT.md
```

### Verifying Daily Note Updates

```bash
# Before
cat ~/test-vault/00\ Daily/2026/20260118.md

# Run skill
# (in Claude) /log-to-daily

# After - verify content appended
cat ~/test-vault/00\ Daily/2026/20260118.md
```

### Verifying Inbox Processing

```bash
# Before
ls ~/test-vault/01\ Inbox/

# Run skill
# (in Claude) /weekly-review

# After - verify files moved
ls ~/test-vault/01\ Inbox/       # Should be empty or reduced
ls ~/test-vault/02\ Projects/    # Should have new items
ls ~/test-vault/04\ Resources/   # Should have new items
```

---

*Testing analysis: 2026-01-18*
