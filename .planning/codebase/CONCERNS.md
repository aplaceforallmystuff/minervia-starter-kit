# Codebase Concerns

**Analysis Date:** 2026-01-18

## Tech Debt

**Inconsistent Skill Frontmatter:**
- Issue: `skills/vault-stats/SKILL.md` uses different frontmatter format than other skills - missing `name` and `use_when` fields
- Files: `skills/vault-stats/SKILL.md`
- Impact: Skill discovery and auto-invocation may behave inconsistently; Claude may not recognize when to invoke this skill
- Fix approach: Add standard frontmatter fields (`name: vault-stats`, `use_when: ...`) matching the pattern in other SKILL.md files

**Placeholder Content in Workflow Coordinator:**
- Issue: Template agent references non-existent agents with placeholder names (`[your-agent-1]`, `[your-agent-2]`, `[your-research-agent]`)
- Files: `.claude/agents/workflow-coordinator.md` (lines 19-21, 79, 172)
- Impact: New users may be confused about how to configure; the agent cannot actually orchestrate until customized
- Fix approach: Either remove placeholder references or provide concrete examples using the existing agents (vault-analyst, aesthetic-definer)

**Unconfigured CLAUDE.md Template:**
- Issue: The template CLAUDE.md in repo root contains placeholder text (`[Your Name]`, `[describe your main activities]`)
- Files: `CLAUDE.md` (lines 7, 32)
- Impact: For users who test the repo directly rather than copying to their vault, Claude receives unclear context
- Fix approach: Either make template explicitly a template file (`CLAUDE.md.template`) or add clearer "edit this section" markers

## Known Bugs

**Missing Image Reference:**
- Symptoms: README references `docs/images/architecture-diagram.png` but an unused `minervia-architecture-diagram.png` exists (git status shows untracked)
- Files: `README.md` (line 9), `docs/images/minervia-architecture-diagram.png`
- Trigger: Image may not render correctly if wrong file is committed
- Workaround: Ensure correct PNG is committed and referenced consistently

## Security Considerations

**Install Script Executes in User Directory:**
- Risk: `install.sh` creates files in user's home directory (`~/.claude/skills/`) and current working directory without explicit permission prompting
- Files: `install.sh` (lines 61-80, 82-174, 196-218)
- Current mitigation: Script only creates/copies files, does not delete or modify existing content
- Recommendations: Add explicit confirmation before creating `~/.claude/settings.json` if it would override existing config; consider dry-run mode

**SessionStart Hook Command Injection Risk:**
- Risk: The JSON settings template embeds a bash command that gets executed on session start
- Files: `install.sh` (lines 199-214)
- Current mitigation: Command is static, not user-generated
- Recommendations: Document this behavior clearly for security-conscious users; consider moving welcome message to a different mechanism

## Performance Bottlenecks

**No Performance Concerns Detected:**
- This is a documentation/template repository with shell scripts and markdown files
- No runtime code that would have performance implications
- Skills execute via Claude Code, which handles performance internally

## Fragile Areas

**Daily Notes Path Assumptions:**
- Files: `skills/log-to-daily/SKILL.md`, `skills/vault-stats/SKILL.md`, `skills/weekly-review/SKILL.md`
- Why fragile: Multiple skills assume specific path patterns (`00 Daily/YYYY/YYYYMMDD.md`, `01 Inbox/`) without robust path validation
- Safe modification: Always test with vaults that have different structures (numbered prefixes vs non-numbered, different date formats)
- Test coverage: No automated tests exist; manual testing required

**Install Script Path Handling:**
- Files: `install.sh` (lines 47-49, 68-80)
- Why fragile: Assumes specific directory structure exists; uses `$(dirname "$0")` which can behave unexpectedly if script is sourced vs executed
- Safe modification: Test with spaces in paths, symlinked directories, and from different working directories
- Test coverage: None - documented in CONTRIBUTING.md that shell scripts should pass shellcheck, but no CI enforcement

**Hook JSON Structure:**
- Files: `install.sh` (lines 199-214)
- Why fragile: The heredoc embeds complex JSON with nested quotes and escape sequences; easy to break with edits
- Safe modification: Use a JSON validator after any changes; consider external JSON file instead of inline heredoc
- Test coverage: None

## Scaling Limits

**Not Applicable:**
- This is a starter kit/template repository
- No server components, databases, or services that would have scaling limits
- Individual vaults scale based on Obsidian/filesystem capabilities, not Minervia code

## Dependencies at Risk

**Claude Code CLI Dependency:**
- Risk: Entire system depends on Claude Code CLI (`claude` command) which is under active development by Anthropic
- Impact: Breaking changes in Claude Code could break skills
- Migration plan: Skills are markdown-based and portable; would need to update invocation patterns if Claude Code changes

**Obsidian Dependency:**
- Risk: Assumes Obsidian's markdown file structure
- Impact: Low - standard markdown files, not Obsidian-specific features
- Migration plan: Skills work with any markdown-based vault; Obsidian is recommended but not required

## Missing Critical Features

**No Skill Validation:**
- Problem: No mechanism to validate that SKILL.md files have correct frontmatter structure
- Blocks: Users cannot easily verify their custom skills are correctly formatted
- Suggested approach: Add a `/validate-skill` skill or shell script that checks frontmatter structure

**No Automated Testing:**
- Problem: CONTRIBUTING.md mentions shellcheck requirement but no CI/CD pipeline exists
- Blocks: Contributors cannot verify their changes don't break existing functionality
- Suggested approach: Add GitHub Actions workflow for shellcheck on install.sh

**No Version Check in Install Script:**
- Problem: `install.sh` doesn't check Claude Code version for compatibility
- Blocks: Users on older Claude Code versions may get confusing errors
- Suggested approach: Add version detection and minimum version requirement

## Test Coverage Gaps

**No Test Files Exist:**
- What's not tested: Everything - this is a pure documentation/template repository
- Files: Entire repository
- Risk: Changes to install.sh or skill templates could break functionality undetected
- Priority: Medium - the codebase is small and changes are infrequent

**Skill Behavior Not Verifiable:**
- What's not tested: Whether skills produce expected outputs when invoked
- Files: `skills/*/SKILL.md`
- Risk: Skill instructions could be unclear or produce incorrect results
- Priority: Low - skills are natural language instructions, not executable code; testing would require Claude interaction

**Cross-Platform Behavior:**
- What's not tested: Windows/WSL compatibility documented in README but not verified
- Files: `install.sh`, all skills
- Risk: WSL users may encounter undocumented issues (line endings, paths)
- Priority: Medium - WSL is explicitly supported in documentation

---

*Concerns audit: 2026-01-18*
