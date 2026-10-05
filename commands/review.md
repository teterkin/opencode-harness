---
description: Review the current diff against the engineering rules before committing.
agent: implementer
template: |
  Review my current changes against the engineering rules. Use the `reviewer`
  subagent on the working tree diff, then summarize the findings for me.

  Focus on: correctness, whether every new behavior has a test that would fail
  without the change, weakened or skipped assertions, scope creep, security, and
  the real lint/typecheck/test commands for this repo. Do not commit anything.