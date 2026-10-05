# Global engineering rules

These rules apply to every session. They are non-negotiable unless the user
explicitly overrides them in the current message.

## 1. TDD is mandatory

- No production code is written before a failing test exists for it.
- Loop: RED (write one failing test, run it, show the failure) -> GREEN
  (smallest change that makes it pass) -> REFACTOR (clean up with tests green).
- Never write a test and the implementation in the same step without running
  the test in between.
- Never weaken, skip, delete, or loosen an existing assertion to make a suite
  green. Fix the code instead.
- A bug fix starts with a test that reproduces the bug.
- Report the actual command output for red and green. Never claim a result you
  did not observe.

## 2. PRD before implementation

For any non-trivial feature or behavior change (more than a couple of files, or
anything with unclear requirements):

1. Write a short PRD first: goal, non-goals, user story, acceptance criteria,
   open questions, risks.
2. Stop and let the user confirm it before writing code.
3. Do not silently implement a requirement the user never agreed to.

For small, obvious, low-risk changes, skip the PRD and say so in one line.

## 3. Plan before editing

- Use todowrite for any task with more than one step. Keep exactly one item
  `in_progress`.
- For anything larger than a mechanical edit, state the plan and get
  confirmation before the first edit.
- Prefer exploring/reading first, editing second.

## 4. Small, atomic changes

- One task, one focused diff. No unrelated refactors, renames, or drive-by
  cleanups bundled in.
- Match the surrounding code style. Do not restructure what was not asked for.
- Do not add comments unless asked.

## 5. Verify and self-review

After every non-trivial change, run the project's real checks (lint, typecheck,
tests) — find the actual commands, do not invent them. Then report:
what was changed, what was run, what the output was, what remains unverified.
If a check cannot be run, say so explicitly instead of implying success.

## 6. Git discipline

- Never run `git commit`, `git push`, `git checkout`, `git reset`, `git rebase`,
  `git merge`, or history-rewriting commands unless the user explicitly asks.
- Never commit secrets, credentials, or `.env`-style files.
- Keep the working tree changes reviewable; do not stage everything blindly.