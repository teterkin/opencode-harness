---
name: prd-authoring
description: Use before implementing any non-trivial feature, behavior change, or unclear requirement - produces a short PRD (goal, non-goals, user story, acceptance criteria, open questions, risks) and waits for user confirmation. Trigger words - feature, requirement, design, spec, PRD, implement, add, change behavior.
---

# PRD first

Applies to anything touching more than a couple of files, changing behavior, or
built on a requirement that is not already precise.

Skip for small, obvious, low-risk edits — but say so in one line so the user
knows the PRD was intentionally skipped.

## Template

```markdown
## PRD: <short title>

**Goal** — one sentence, in the user's language.

**Non-goals** — what this change deliberately does not do.

**User story** — As a <role>, I want <capability>, so that <benefit>.

**Acceptance criteria** — numbered, each objectively verifiable:
1. ...
2. ...

**Open questions** — anything that blocks or forks the implementation.

**Sources and assumptions** — the files, docs and commands you actually read,
and every assumption you had to make. An assumption you cannot verify goes
under Open questions, not here.

**Risks** — what could break, and the rollback plan.
```

## Rules

- Keep it short. One screen, not a document.
- Acceptance criteria are testable statements, not aspirations.
- Real unknowns go under Open questions instead of being guessed.
- Sources and assumptions are filled from what you read, never invented. If you
  did not open the file, do not list it.
- Stop after writing it and wait for confirmation. Do not start implementing.
- Do not silently add a requirement the user never agreed to.
- Once confirmed, save it to `docs/prd/<slug>.md` in the project and check the
  result against its acceptance criteria one by one before reporting done.