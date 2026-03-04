---
name: extract-wisdom
description: Dynamic wisdom extraction that adapts sections to content. Use when analyzing YouTube videos, podcasts, interviews, articles, or any content where you want to capture the best insights.
use_when: User wants insights extracted from content - YouTube videos, podcasts, articles, interviews, transcripts. User says "extract wisdom", "key takeaways", "what did I miss", "what's interesting in this".
user-invocable: true
---

# ExtractWisdom — Dynamic Content Extraction

Instead of static sections (IDEAS, QUOTES, HABITS...), this skill detects what wisdom domains actually exist in the content and builds custom sections around them.

A programming interview gets "Programming Philosophy" and "Developer Workflow Tips." A business podcast gets "Contrarian Business Takes" and "Money Philosophy." The sections adapt because the content dictates them.

## Input Sources

| Source | Method |
|--------|--------|
| YouTube URL | Use WebFetch on transcript services, or paste transcript directly |
| Article URL | WebFetch to get content |
| File path | Read the file directly |
| Pasted text | Use directly |

## Depth Levels

Default is **Full** if no level is specified.

| Level | Sections | Bullets/Section | Closing Sections | When |
|-------|----------|----------------|-----------------|------|
| **Instant** | 1 | 8 | None | Quick hit. One killer section. |
| **Fast** | 3 | 3 | None | Skim in 30 seconds. |
| **Basic** | 3 | 5 | One-Sentence Takeaway only | Solid overview without the deep cuts. |
| **Full** | 5-12 | 3-15 | All three | The default. Complete extraction. |
| **Comprehensive** | 10-15 | 8-15 | All three + Themes & Connections | Maximum depth. Nothing left behind. |

**Invoke:** "extract wisdom (fast)" or "extract wisdom at comprehensive level" or just "extract wisdom" for Full.

## Tone Rules

The output should feel like your smartest friend watched/read the thing and is telling you about it over coffee. Not a book report. Not documentation.

**THREE LEVELS — we aim for Level 3:**

**Level 1 (BAD — documentation):**
- The speaker discussed the importance of self-modifying software in the context of agentic AI development
- It was noted that financial success has diminishing returns beyond a certain threshold

**Level 2 (BETTER — but still "smart bullet points"):**
- He built self-modifying software basically by accident — just made the agent aware of its own source code
- Money has diminishing returns. A cheeseburger is a cheeseburger no matter how rich you are.

**Level 3 (YES — conversational, opinionated):**
- He wasn't trying to build self-modifying software. He just let the agent see its own source code and it started fixing itself.
- Past a certain point, money stops mattering. A cheeseburger is a cheeseburger no matter how rich you are.

**The difference:** Level 2 is compressed info with em-dashes. Level 3 is how you'd actually SAY it. Varied sentence lengths. Letting a thought breathe. Not trying to be clever — just clear, direct, and a little personal.

**Key signals of Level 3:**
- Reads naturally when spoken aloud
- Varied sentence lengths — some short, some longer
- Understated — lets the content carry the weight
- Uses periods, not em-dashes, to let ideas land
- Feels opinionated, not just informational

## Rules for Extracted Points

1. **Write like you'd say it.** Read each bullet aloud. If it sounds like a press release, rewrite it.
2. **8-16 words per sentence.** Mix short with medium and longer. Don't make them all the same length.
3. **Let ideas breathe.** Use periods between thoughts, not em-dashes. Short sentences. Then a slightly longer one to explain.
4. **Include the actual detail.** Not "he talked about money" but "a cheeseburger is a cheeseburger no matter how rich you are."
5. **Use the speaker's words when they're good.** If they said something perfectly, use it.
6. **No hedging language.** Not "it was suggested that" or "the speaker noted." Just say the thing.
7. **Capture what made you stop.** Every bullet should be something worth telling someone about.
8. **Vary your openers.** Don't start three bullets the same way.
9. **Capture the human moments.** Burnout stories, moments of doubt, something that moved them.
10. **Insight over inventory.** "He uses Go for CLIs" is inventory. "He picked a language he doesn't even like because the ecosystem fits agents perfectly" is insight.
11. **Specificity is everything.** Details make wisdom memorable.
12. **Tension and surprise.** The best bullets have a contradiction or reversal.
13. **Understated, not clever.** Let the content carry the weight.

## Process

### Phase 1: Content Scan

Read the full content. Notice what DOMAINS of wisdom are present. These aren't the topics discussed — they're the TYPES of insight being delivered.

Examples of wisdom domains (illustrative, not exhaustive):
- Programming Philosophy
- Developer Workflow
- Business/Money Philosophy
- Human Psychology
- Technology Predictions
- Life Philosophy
- Contrarian Takes
- First-Time Revelations
- Technical Architecture
- Leadership & Team Dynamics
- Creative Process

### Phase 2: Section Selection

Pick sections based on depth level. Requirements:
- Each section must have at least 3 STRONG bullets to justify existing
- Always include "Quotes That Hit Different" if the content has good ones
- Section names should be conversational, not academic
- Sections should be SPECIFIC to this content

### Phase 3: Extraction

For each section, extract 3-15 bullets depending on density. Apply all tone rules.

**The "Would I Tweet This?" Test:** If fewer than half your bullets would make a good standalone post, they're too generic.

### Phase 4: Closing Sections

| Level | Closing Sections |
|-------|-----------------|
| **Instant** | None |
| **Fast** | None |
| **Basic** | One-Sentence Takeaway only |
| **Full** | One-Sentence Takeaway + If You Only Have 2 Minutes + References & Rabbit Holes |
| **Comprehensive** | All above + Themes & Connections |

## Output Format

```markdown
# EXTRACT WISDOM: {Content Title}
> {One-line description of what this is and who's talking}

---

## {Dynamic Section 1 Name}

- {bullet}
- {bullet}

## {Dynamic Section 2 Name}

- {bullet}
- {bullet}

[... more dynamic sections ...]

---

## One-Sentence Takeaway

{15-20 word sentence}

## If You Only Have 2 Minutes

- {essential point 1}
- {essential point 2}
- {essential point 3}
- {essential point 4}
- {essential point 5}

## References & Rabbit Holes

- **{Name/Project}** — {one-line context of why it's worth looking into}
```

## Quality Check

Before delivering output, verify:
- [ ] Sections are specific to THIS content, not generic
- [ ] No bullet sounds like it was written by a committee
- [ ] Every bullet has a specific detail, quote, or insight
- [ ] Section names are conversational and headline-worthy
- [ ] No bullet starts with "The speaker" or "It was noted that"
- [ ] Reading the output makes you want to consume the original content

## Attribution

Adapted from Daniel Miessler's ExtractWisdom (PAI v3.0.0), itself the successor to fabric's extract_wisdom pattern.
