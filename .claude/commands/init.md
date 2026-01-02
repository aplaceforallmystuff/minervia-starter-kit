# Minervia Init

Configure your vault for Minervia.

## Task

Help the user set up their CLAUDE.md configuration by detecting their vault structure.

## Process

1. **Detect vault structure**
   - Look for common folder patterns (PARA, Zettelkasten, date-based)
   - Find daily notes location by searching for date-formatted files
   - Identify inbox/capture folder
   - Find project-like folders

2. **Ask brief questions**
   - "What's your name?" (for personalization)
   - Confirm detected folder structure or ask for corrections
   - "What's your primary use case?" (writing, research, project management)

3. **Update CLAUDE.md**
   - Fill in the vault configuration section with detected/confirmed paths
   - Add any user preferences

4. **Verify skills are installed**
   - Check ~/.claude/skills/ for Minervia skills
   - If missing, remind user to run install.sh first

5. **Quick test**
   - Suggest running `/log-to-daily` to verify configuration works

## Output

A personalized CLAUDE.md that matches the user's actual vault structure.

Keep it simple. Minervia works with any organization system — the point is to detect and adapt, not impose structure.
