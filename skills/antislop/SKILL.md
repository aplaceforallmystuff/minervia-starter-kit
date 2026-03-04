---
name: antislop
description: Detect AI-generated writing patterns (slop). Scans for banned phrases, structural tells, and scoring.
use_when: User wants to detect AI slop in content, audit a draft for AI patterns, check writing authenticity, or review AI-generated output before publishing.
user-invocable: true
tools: [Read]
---

# AntiSlop — AI Writing Pattern Detector

Detects AI-generated writing patterns so you can fix them. Based on research from Wikipedia's Signs of AI Writing, Finnish academic studies, and Georgia Tech analysis of 168M+ articles.

## The 30-Second Test

**The Horoscope Test:**

> "Could anyone have written this, for anyone?"

If yes, it's slop. Like a horoscope — technically applicable to everyone, resonant with no one.

**What fails:**
- Vague claims without specific examples
- Advice that applies universally without context
- Content missing the author's distinct perspective
- Writing that could have any byline

**What passes:**
- Specific tools, dates, outcomes mentioned
- Personal observations grounded in experience
- Opinions that not everyone would agree with
- Details only this author would know

---

## Usage

```
/antislop

[paste your text here]
```

Or: "check this for AI slop", "run antislop on this draft"

---

## Detection Patterns

### Tier 1: Almost Always AI (Remove Immediately)

These phrases are so strongly associated with AI that their presence alone suggests unedited output.

| Pattern | Example | Fix |
|---------|---------|-----|
| Delve | "Let's delve into..." | Remove or replace with direct statement |
| Game-changer | "This game-changing approach..." | Describe the actual impact |
| Revolutionary | "A revolutionary new method..." | State what it actually does |
| Unlock potential | "Unlock your potential..." | Remove entirely |
| Leverage (as verb) | "Leverage these insights..." | "Use" |
| It's worth noting | "It's worth noting that..." | Just state the thing |
| Moreover/Furthermore | "Moreover, this approach..." | Remove or use "Also" |
| Today's digital landscape | "In today's digital landscape..." | Remove |
| Cutting-edge | "Cutting-edge solutions..." | Remove |
| Pivotal moment | "Marking a pivotal moment in..." | State what happened |
| Tapestry (abstract) | "A rich tapestry of influences..." | Remove or be specific |
| Intricate/intricacies | "The intricacies of..." | "Details of" or remove |
| Showcase (as verb) | "Showcasing their commitment..." | "Shows" or describe what happened |
| Vibrant | "A vibrant community of..." | Remove or use specific detail |
| Interplay | "The interplay between X and Y..." | "How X and Y affect each other" |
| Garner | "Garnering attention from..." | "Got attention from" or be specific |
| Align with | "Aligning with broader trends..." | State the actual relationship |
| Paradigm shift | "A paradigm shift in..." | Describe the actual change |
| Seamlessly | "Seamlessly integrates..." | Remove or describe how it works |
| Navigate (abstract) | "Navigate the complexities..." | Remove or be specific |

**Research evidence:**
- Finnish study (56,878 essays): "delve" usage increased 10.45x post-ChatGPT
- Georgia Tech (168.3M articles): "delve" went from 0.31 to 7.9 per 1,000 papers in Q1 2024

### Tier 2: Suspicious When Repeated

| Pattern | Example | Fix |
|---------|---------|-----|
| Here's the thing | Used repeatedly | Keep first, vary subsequent |
| At the end of the day | "At the end of the day..." | Remove |
| The bottom line | "The bottom line is..." | Just state it |
| Let's dive in | "Without further ado, let's dive in" | Remove |
| Comprehensive and thorough | Paired adjectives | Pick one |
| In this post, we'll cover | Template opening | Remove |

---

## Structural Patterns

### Staccato Fragment Spam

Three or more consecutive short declarative sentences in parallel structure. AI's version of bullets pretending to be prose.

**Before:**
> The model is impressive. Complex code ships fast. Documentation writes itself.

**After:**
> The model is impressive — complex code ships in a single session, and documentation practically writes itself.

### Comparator Sentences

**Before:**
> This isn't theoretical. It's practical.
> It's not about X. It's about Y.

**After:**
> Here's how it works in practice: [just state what it is]

### Sentence Uniformity

Every sentence 10-15 words. Short. Punchy. Exhausting. Real writing has rhythm — mix short sentences for impact with longer ones that explore implications.

### Emoji Headers

> "🎯 Goal / 💡 Key Insight / ✅ Action Item"

Remove emojis from headers. They signal AI-generated structure.

---

## Content Patterns

| Pattern | Before | After |
|---------|--------|-------|
| Significance inflation | "marking a pivotal moment in the evolution of..." | "was established in 1989" |
| Promotional language | "nestled within the breathtaking region" | "is a town in the Gonder region" |
| Vague attributions | "Experts believe it plays a crucial role" | "according to a 2019 survey by..." |
| Chatbot artifacts | "I hope this helps! Let me know if..." | Remove entirely |
| Sycophantic tone | "Great question!" | Respond directly |

---

## Scoring System

| Pattern Type | Points |
|--------------|--------|
| Each Tier 1 phrase | +3 |
| Each Tier 2 phrase (repeated) | +2 |
| Failed horoscope test | +5 |
| Staccato fragment spam (per instance) | +4 |
| Sentence uniformity detected | +3 |
| Comparator sentences (per instance) | +2 |
| Emoji headers | +2 |

**Score interpretation:**
- **0-5:** Low risk (minor edits needed)
- **6-12:** Medium risk (significant editing required)
- **13+:** High risk (likely unedited AI output)

---

## Output Format

```markdown
## AntiSlop Report

**Horoscope Test:** [PASS/FAIL] - [reason]
**Slop Score:** [X] - [Risk Level]

### Issues Found

| Location | Pattern | Suggestion |
|----------|---------|------------|
| Line 3 | Tier 1: "delve" | Remove or replace with direct statement |
| Lines 8-11 | Staccato fragments | Combine into flowing prose |

### Summary
- [Total Tier 1 phrases]
- [Total structural issues]
- [Overall assessment]

### The Core Principle
Your voice is in the specificity, the opinions, the rough edges, and the rhythm. Protect those.
```

---

## References

- [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)
- [WikiProject AI Cleanup](https://en.wikipedia.org/wiki/Wikipedia:WikiProject_AI_Cleanup)
- Finnish study on "delve" usage (56,878 essays)
- Georgia Tech analysis (168.3M articles)

---

## Core Principle

**AI slop isn't about individual words — it's about patterns.**

One "moreover" doesn't make content AI-generated. But "moreover" + "it's worth noting" + "delve into" + uniform sentences + emoji headers = obvious slop.

The goal is writing that sounds like a specific human with specific opinions, not a very polite committee trying not to offend anyone.
