---
description: Implement using strict red-green-refactor TDD, one failing test at a time.
agent: implementer
template: |
  Implement this with strict TDD, one behavior per cycle: $ARGUMENTS

  For each cycle: write ONE failing test, run it and show me the real failure
  output, then make the smallest change that passes, run it and show the real
  output, then refactor while staying green. Use the `tdd-workflow` skill.

  Before the first edit, tell me which real test/lint commands you found in this
  repo and what your plan is. If the request is non-trivial or unclear, write a
  short PRD first and wait for my confirmation.