---
name: tdd-workflow
description: Use when implementing any feature, fixing any bug, or changing existing behavior in a codebase - enforces strict red-green-refactor TDD with one failing test observed before any production code is written. Trigger words - implement, add feature, fix bug, refactor, TDD, test first, write code.
---

# TDD workflow

Non-negotiable unless the user explicitly says to skip tests for a change.

## Precondition: a known starting point

Before the first test, establish the baseline:

1. Run the real suite and confirm it is green. If it is already red, stop and
   report which tests fail: you cannot tell your change from a pre-existing
   failure.
2. Check the working tree. Uncommitted changes from someone else change what
   "green" means; name them or ask.
3. State the exact command you will use for red, green and lint. It must exist
   in this repo, not in your head.

Write the baseline result down. Every later claim is relative to it.

## The loop

One behavior per cycle. A cycle ends only when it is green and refactored.

### 1. RED

Write exactly one test for one behavior. Run the test suite and paste the
actual failure output. Do not continue while the new test passes for the wrong
reason (e.g. typo in the test, missing import) — a test that errors is not a
valid red.

State plainly which assertion failed and why it is expected to fail.

### Sensitivity check

A red test is only useful if it would notice the behavior disappearing. Before
GREEN, confirm the test is sensitive:

- The assertion compares the actual behavior to the expected one, not to itself
  or to a constant the test also sets.
- Removing or stubbing the behavior makes this exact test fail, and the failure
  message names the behavior, not a missing import or a typo.
- The test does not pass for an unrelated reason (wrong fixture, empty loop,
  mocked-out subject).

If the test cannot fail, fix the test before writing production code.

### 2. GREEN

Write the smallest production change that makes the test pass. No speculative
generics, no "future-proofing", no extra methods, no second feature.

Run the test again and show the real output, including the suite totals.

### 3. REFACTOR

Remove duplication and improve naming only while the suite stays green. Run
the suite after every refactor step and show the output.

Repeat until the requested behavior is covered.

## Rules

- No production code before an observed failing test.
- Never weaken, skip, delete, comment out, or loosen an existing assertion to
  get a green suite. Fix the code.
- No snapshot-test gold-plating and no assertion-free tests.
- Bugs: write a test that reproduces the failure, watch it fail, then fix.
- Known defect you cannot fix now: a strict `xfail` only — the marker names the
  reason and a tracking issue, the test still asserts the desired behavior, and
  the suite fails if the defect is fixed and the marker is left behind. Never
  use a skip, a commented assertion, or a permanently red test.
- Find the real test and lint commands from the repo (package scripts, Makefile,
  pyproject, CI config). Never guess a command that does not exist.
- If the project has no test infrastructure, ask before introducing one.

## Reporting

Report the actual observed output for red and green. Never claim a result that
was not observed, and never say a suite passes without running it.