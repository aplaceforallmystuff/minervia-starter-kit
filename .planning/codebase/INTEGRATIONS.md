# External Integrations

**Analysis Date:** 2026-01-18

## APIs & External Services

**Claude Code (Anthropic):**
- SDK/Client: Claude Code CLI (`@anthropic-ai/claude-code`)
- Auth: Anthropic account with Pro/Max subscription
- Purpose: Runtime for skill execution, agent orchestration
- Install: `npm install -g @anthropic-ai/claude-code` or direct download

**No Other External APIs:**
- This project does not integrate with third-party APIs directly
- All external integrations happen through MCP servers (user-configured, not included)

## Data Storage

**Databases:**
- None - This project stores no data itself
- User's Obsidian vault (Markdown files) serves as the data layer

**File Storage:**
- Local filesystem only
- Skills read/write to user's Obsidian vault
- Skills installed to `~/.claude/skills/`
- Configuration in `.claude/` directory

**Caching:**
- None

## Authentication & Identity

**Auth Provider:**
- Anthropic (for Claude Code)
- No custom auth in this project

**Implementation:**
- User authenticates with Anthropic via Claude Code CLI
- No API keys required in project configuration
- No secrets management needed

## Monitoring & Observability

**Error Tracking:**
- None integrated
- Errors surface in Claude Code terminal output

**Logs:**
- No centralized logging
- Skills log activity to user's daily notes (via `/log-to-daily`)
- Session logs written to project folders (via `/log-to-project`)

## CI/CD & Deployment

**Hosting:**
- GitHub repository: `github.com/aplaceforallmystuff/minervia-starter-kit`
- No deployment pipeline (runs locally)

**CI Pipeline:**
- None configured
- Manual release process via git tags

**Distribution:**
- Users clone repository
- Run `install.sh` to copy skills to `~/.claude/skills/`

## Environment Configuration

**Required env vars:**
- None - all configuration is file-based

**Configuration Files:**
| File | Location | Purpose |
|------|----------|---------|
| `CLAUDE.md` | Vault root | Vault-specific settings |
| `.claude/settings.json` | Vault root | Hooks and permissions |
| `~/.claude/skills/*/SKILL.md` | User home | Global skill definitions |

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## MCP Server Integration Points

**Designed For (User Configures):**
- Calendar MCP servers (events, scheduling)
- Email MCP servers (read, send, search)
- Database MCP servers (SQLite, PostgreSQL queries)
- Custom API MCP servers

**How Integration Works:**
- User adds MCP servers via `claude mcp add <server>`
- Skills can then query MCP-connected services
- No MCP servers ship with this starter kit

**Example MCP Integration Patterns (from README):**
```markdown
## MCP Servers (The Bridges)

MCP servers run locally on your machine. Claude talks to your calendar,
email, databases, and APIs through these servers. No cloud processing
of your data. Everything stays on your laptop.
```

## Obsidian Integration

**Integration Type:** File-based (not API)

**How It Works:**
- Obsidian stores notes as plain Markdown files
- Claude Code skills read/write these files directly
- No Obsidian plugin required
- No Obsidian API calls

**File Patterns:**
- Daily notes: `{vault}/00 Daily/YYYY/YYYYMMDD.md`
- Projects: `{vault}/02 Projects/{name}/PROJECT.md`
- Inbox: `{vault}/01 Inbox/`

**Wiki Link Support:**
- Skills create Obsidian-compatible `[[wiki links]]`
- Files linked become navigable in Obsidian graph view

## GitHub Integration

**Repository Features Used:**
- Issue templates (`.github/ISSUE_TEMPLATE/`)
- MIT License
- Contributing guidelines

**GitHub Actions:**
- Not configured

## Future Integration Considerations

**From README - Suggested Extensions:**

| Integration | Purpose | Via |
|-------------|---------|-----|
| Calendar | Events, scheduling, reminders | MCP server |
| Email | Read, send, search, organize | MCP server |
| Task Management | Todo systems | MCP server |
| Databases | SQLite, PostgreSQL queries | MCP server |

**Integration Philosophy:**
> "Start simple. Add complexity when you hit friction."

---

*Integration audit: 2026-01-18*
