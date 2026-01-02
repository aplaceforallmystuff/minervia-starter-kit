---
name: think-first
description: Apply mental models before major decisions. Enforces structured thinking before implementation.
use_when: User faces a significant decision, architectural choice, prioritization question, or trade-off that requires structured thinking.
---

# Think First

Stop and think before implementing. Apply mental models to significant decisions.

## Why This Matters

Rushing into implementation causes regret:
- "We should have thought about that first"
- "Why didn't we consider the alternative?"
- "This is harder to change now"

With structured thinking:
- Assumptions surface before they bite
- Trade-offs are explicit
- Better decisions, fewer reversals

## Quick Start

When you detect a decision moment:

1. **Stop** — Don't proceed to implementation
2. **Identify** — What type of decision is this?
3. **Select** — Which mental model fits?
4. **Apply** — Run the model
5. **Proceed** — Continue with analysis informing the decision

## Decision Detection

Decision moments include:
- Architectural choices ("should we use X or Y?")
- Prioritization ("what to build first?")
- Trade-offs ("speed vs quality")
- Direction changes ("should we pivot?")
- Resource allocation ("where to focus?")

**Test:** Is this a significant choice with trade-offs that will be hard to reverse?

If YES → Apply a mental model before proceeding.

## Mental Models

### Model 1: First Principles

**Use when:** Building something new, challenging assumptions, or stuck in conventional thinking.

**Process:**
1. State the problem or belief being examined
2. List all current assumptions (even "obvious" ones)
3. Challenge each: "Is this actually true? Why do we believe this?"
4. Identify base truths that cannot be reduced further
5. Rebuild solution from only these fundamentals

**Output format:**
```markdown
## First Principles Analysis: [Topic]

**Current Assumptions:**
- Assumption 1: [Challenged: true/false/uncertain]
- Assumption 2: [Challenged: true/false/uncertain]

**Fundamental Truths:**
- Truth 1: [Why irreducible]
- Truth 2: [Why irreducible]

**Rebuilt Understanding:**
Starting from fundamentals...

**New Possibilities:**
Without legacy assumptions, these options emerge...
```

---

### Model 2: Inversion

**Use when:** Planning a project, avoiding failure, or stress-testing a plan.

**Process:**
1. State the goal
2. Ask: "What would guarantee failure?"
3. List every way this could fail spectacularly
4. Invert each failure into a preventive action
5. Build the plan around avoiding failure modes

**Output format:**
```markdown
## Inversion Analysis: [Goal]

**Goal:** [What we're trying to achieve]

**Guaranteed Failure Modes:**
1. [Failure 1] - How to avoid: [Prevention]
2. [Failure 2] - How to avoid: [Prevention]
3. [Failure 3] - How to avoid: [Prevention]

**Inverted Plan:**
To succeed, we must NOT do these things...

**Safeguards:**
Built-in protections against each failure mode...
```

---

### Model 3: Opportunity Cost

**Use when:** Choosing between options, allocating time, or deciding what to build.

**Process:**
1. List the options being considered
2. For each option, identify what you're giving up by choosing it
3. Quantify where possible (time, money, opportunities)
4. Compare not just what you gain, but what you sacrifice
5. Choose the option with acceptable trade-offs

**Output format:**
```markdown
## Opportunity Cost Analysis: [Decision]

| Option | What You Gain | What You Sacrifice |
|--------|---------------|-------------------|
| Option A | [Benefits] | [Costs/foregone alternatives] |
| Option B | [Benefits] | [Costs/foregone alternatives] |

**Hidden Costs:**
- [Cost not immediately obvious]

**The Real Question:**
Not "is A good?" but "is A better than everything else I could do with this time/resource?"

**Recommendation:**
[Option] because [trade-off reasoning]
```

---

### Model 4: Pareto (80/20)

**Use when:** Prioritizing work, finding leverage, or cutting scope.

**Process:**
1. List all possible actions/features/tasks
2. Estimate impact of each (even rough)
3. Estimate effort of each
4. Calculate leverage: impact/effort
5. Identify the 20% that drives 80% of value
6. Focus there first

**Output format:**
```markdown
## Pareto Analysis: [Domain]

| Item | Impact (1-10) | Effort (1-10) | Leverage |
|------|---------------|---------------|----------|
| Item A | 9 | 3 | 3.0 |
| Item B | 5 | 7 | 0.7 |

**High Leverage (Do First):**
1. [Item] - [Why high leverage]
2. [Item] - [Why high leverage]

**Low Leverage (Defer/Cut):**
- [Items that seem important but aren't]

**The 20% Focus:**
These few things drive most of the value...
```

---

### Model 5: 5 Whys

**Use when:** Diagnosing problems, understanding failures, or finding root causes.

**Process:**
1. State the problem
2. Ask "Why did this happen?"
3. Take the answer and ask "Why?" again
4. Repeat until you reach a root cause (usually 5 levels)
5. Address the root, not the symptoms

**Output format:**
```markdown
## 5 Whys Analysis: [Problem]

**Problem:** [Statement of what went wrong]

1. Why? → [First-level cause]
2. Why? → [Second-level cause]
3. Why? → [Third-level cause]
4. Why? → [Fourth-level cause]
5. Why? → [Root cause]

**Root Cause:** [The fundamental issue]

**Fix at Root:**
[How to address the root cause, not symptoms]

**Symptom fixes (temporary):**
[What addresses symptoms if root fix takes time]
```

---

## Model Selection Guide

| Decision Type | Best Models |
|---------------|-------------|
| "What should we build?" | First Principles, Inversion |
| "How should we prioritize?" | Pareto, Opportunity Cost |
| "Is this the right direction?" | Inversion, Opportunity Cost |
| "What went wrong?" | 5 Whys |
| "Which option is best?" | Opportunity Cost, Pareto |

## Integration

Add to any project's CLAUDE.md:

```markdown
## Decision Protocol

Before implementing significant decisions, apply think-first:
- Architectural choices
- Prioritization decisions
- Trade-off analysis

Ensures structured thinking before implementation.
```

## Success Criteria

- [ ] Decision moments detected before implementation
- [ ] At least one mental model applied per significant decision
- [ ] Model output informs the recommendation
- [ ] Implementation only proceeds after analysis
- [ ] No "we should have thought about that first" moments
