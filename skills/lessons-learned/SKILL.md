---
name: lessons-learned
description: Structured retrospective for incidents and mistakes. Transforms problems into systematic improvements.
use_when: After incidents, mistakes, rollbacks, or when analyzing what went wrong. Triggers on "lessons learned", "post-mortem", "what went wrong", "how do we prevent this".
---

# Lessons Learned

Transform problems into systematic improvements through structured retrospective analysis.

## Why This Matters

Mistakes repeat when we only fix symptoms. With structured retrospectives:
- Root causes get addressed, not just symptoms
- Fixes are encoded into the system (skills, guards, docs)
- Each problem makes the system stronger
- You never hear "we should have thought about that first"

## Quick Start

1. Define the incident factually
2. Build a timeline
3. Find root cause with 5 Whys
4. Identify contributing factors
5. Implement fixes (don't just recommend them)
6. Define verification criteria

## Process

### Phase 1: Incident Definition

**Capture facts first, analysis later.**

```markdown
## Incident Summary

**What happened:** [Factual description]
**When:** [Date/time]
**Impact:** [What was affected]
**Resolution:** [How it was fixed]
**Time to resolution:** [How long to fix]
```

### Phase 2: Timeline Reconstruction

| Time | Action | Actor | Outcome |
|------|--------|-------|---------|
| HH:MM | [What was done] | [Who] | [Result] |

**Key questions:**
- What was the trigger?
- Where did things diverge from expected?
- What was the point of no return?

### Phase 3: Root Cause Analysis (5 Whys)

1. Why did [incident] happen?
   → Because [immediate cause]

2. Why did [immediate cause] happen?
   → Because [deeper cause]

3. Why did [deeper cause] happen?
   → Because [systemic issue]

4. Why did [systemic issue] exist?
   → Because [process gap]

5. Why did [process gap] exist?
   → Because [root cause]

**Root Cause:** [The fundamental issue to address]

### Phase 4: Contributing Factors

| Category | Factor | Contribution |
|----------|--------|--------------|
| **Process** | Missing checkpoint | [How it contributed] |
| **Communication** | Unclear instructions | [How it contributed] |
| **Technical** | No validation | [How it contributed] |
| **Context** | Prior assumptions | [How it contributed] |

### Phase 5: Fix Classification

| Fix Type | When to Use | How to Encode |
|----------|-------------|---------------|
| **Skill** | Recurring workflow needs structure | Create new skill |
| **Guard** | Action requires checkpoint | Add approval gate |
| **Documentation** | Knowledge gap | Update CLAUDE.md |
| **Automation** | Manual step forgotten | Create script/hook |
| **Checklist** | Multiple steps need verification | Add to skill |

### Phase 6: Fix Implementation

**Don't just recommend fixes—implement them.**

| Fix | Type | Location | Status |
|-----|------|----------|--------|
| [Description] | Skill | [Path] | Created |
| [Description] | Doc | [Path] | Updated |

### Phase 7: Verification

```markdown
**Test scenario:** [How to test the fix]
**Success criteria:** [What "fixed" looks like]
**Review date:** [When to check if working]
```

## Output Template

```markdown
# Lessons Learned: [Incident Title]

**Date:** YYYY-MM-DD
**Severity:** Low | Medium | High | Critical
**Status:** Resolved | Monitoring | Open

## Incident Summary
[Brief description]

## Timeline
| Time | Action | Outcome |

## Root Cause
[The fundamental issue]

## Contributing Factors
- Factor 1
- Factor 2

## Fixes Implemented
| Fix | Type | Location | Status |

## Prevention
[How this prevents recurrence]

## Lessons
1. Key takeaway 1
2. Key takeaway 2
```

## Common Patterns

### Premature Action
**Symptom:** Action taken before approval
**Fix:** Add explicit approval gate

### Sequence Error
**Symptom:** Steps in wrong order
**Fix:** Encode sequence with numbered steps

### Missing Validation
**Symptom:** Bad data passed through
**Fix:** Add validation checkpoint

### Context Carryover
**Symptom:** Assumptions from prior session caused issue
**Fix:** Add explicit context verification

### Scope Creep
**Symptom:** Did more than requested
**Fix:** Ask clarifying questions before expanding

## Anti-Patterns

| Anti-Pattern | Problem | Instead |
|--------------|---------|---------|
| Blame assignment | Misses systemic issues | Focus on process |
| Single-cause thinking | Oversimplifies | Use 5 Whys |
| Recommendation without action | Lessons forgotten | Implement during retrospective |
| Vague fixes | "Be more careful" doesn't work | Encode specific changes |

## Success Criteria

- [ ] Incident clearly defined with timeline
- [ ] Root cause identified (not just symptoms)
- [ ] Contributing factors documented
- [ ] At least one fix implemented (not just recommended)
- [ ] Fix encoded in appropriate location
- [ ] Verification criteria defined
