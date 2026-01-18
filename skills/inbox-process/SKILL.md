---
name: inbox-process
description: Process inbox items - triage captured notes into appropriate PARA folders. Quick focused inbox maintenance.
use_when: User wants to process inbox, triage captured items, clean up quick captures, or move notes to proper locations.
---

# Inbox Process

Quick triage of inbox items into appropriate PARA locations.

## Why This Matters

The inbox is for fast capture without friction. But items that stay there lose value:
- Quick ideas get forgotten
- Reference materials stay unfindable
- Action items never get acted on

Regular inbox processing keeps the capture system trustworthy.

## Quick Start

1. List items in 01 Inbox/
2. For each item: analyze, suggest destination, get confirmation
3. Move or delete based on user choice
4. Summarize what was processed

## Process

### Step 1: List Inbox Contents

Read all files in the inbox folder (typically `01 Inbox/`).

If inbox is empty, report success and exit.

### Step 2: For Each Item

**Analyze the content:**
- What is this? (idea, reference, task, project seed, etc.)
- Is it actionable?
- Does it relate to existing notes?

**Suggest destination:**

| Content Type | Suggested Location |
|--------------|-------------------|
| Active project or has deadline | 02 Projects/ |
| Ongoing responsibility | 03 Areas/ |
| Reference material | 04 Resources/ |
| Completed or outdated | 05 Archive/ |
| Trash or duplicate | Delete |
| Not ready to decide | Keep in Inbox |

**Present options to user:**

```
Item: [filename]
Content: [brief summary]

Suggestion: Move to 02 Projects/
Reason: Has clear outcome and deadline mentioned

Options:
1. Move to Projects
2. Move to Areas
3. Move to Resources
4. Archive
5. Delete
6. Keep in Inbox
```

### Step 3: Execute User Choice

- Move file to chosen destination
- Add basic frontmatter if missing:
  ```yaml
  ---
  created: YYYY-MM-DD
  processed: YYYY-MM-DD
  tags: []
  ---
  ```
- Log the action

### Step 4: Summary

After processing all items:

```markdown
## Inbox Processing Complete

**Processed:** X items
**Inbox remaining:** Y items

| Item | Action | Destination |
|------|--------|-------------|
| Note.md | Moved | 02 Projects/ |
| Idea.md | Deleted | - |
| Link.md | Kept | 01 Inbox/ |
```

## Configuration

Define your vault structure in CLAUDE.md:

```markdown
## Vault Structure

Folders:
  inbox: 01 Inbox/
  projects: 02 Projects/
  areas: 03 Areas/
  resources: 04 Resources/
  archive: 05 Archive/
```

## Parameters

Optional modifiers:
- `quick` - Show suggestion, assume yes unless user objects
- `dry run` - Preview without moving files
- `oldest first` - Process by file age instead of name

## Success Criteria

- [ ] All inbox items reviewed
- [ ] User confirmed each action before execution
- [ ] Files moved to appropriate locations
- [ ] Summary logged
