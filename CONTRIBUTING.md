# Contributing to Minervia Starter Kit

Thank you for your interest in contributing to Minervia!

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or suggest features
- Include your OS and Claude Code version
- Describe expected vs actual behavior
- Include relevant error messages

### Submitting Skills

New skills are welcome! A good skill:

1. **Solves a real problem** - Something you actually use
2. **Is self-contained** - Works without external dependencies
3. **Has clear documentation** - Includes Why/How/Success Criteria
4. **Follows the format** - See existing skills for structure

### Skill Format

Every skill needs a `SKILL.md` with:

```markdown
---
name: skill-name
description: One sentence description
use_when: When this skill should be invoked
---

# Skill Name

## Why This Matters
[Why this skill exists]

## Configuration
[What users need to set up]

## Quick Start
[Shortest path to using this]

## Process
[Step-by-step instructions]

## Success Criteria
- [ ] What "done" looks like
```

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-skill`)
3. Make your changes
4. Test the install script
5. Submit a PR with a clear description

### Code Style

- Skills use Markdown with YAML frontmatter
- Shell scripts should pass `shellcheck`
- Keep things simple — Minervia is about clarity

## Questions?

Open an issue or reach out at [minervia.co](https://minervia.co).
