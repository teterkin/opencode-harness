---
name: tdd-workflow
description: Use when implementing any feature, fixing any bug, or changing existing behavior in a codebase - enforces strict red-green-refactor TDD with one failing test observed before any production code is written. Trigger words - implement, add feature, fix bug, refactor, TDD, test first, write code.
---

# TDD workflow

Non-negotiable unless the user explicitly says to skip tests for a change.

## The loop

One behavior per cycle. A cycle ends only when it is green and refactored.

### 1. RED

Write exactly one test for one behavior. Run the test suite and paste the
actual failure output. Do not continue while the new test passes for the wrong
reason (e.g. typo in the test, missing import) — a test that errors is not a
valid red.

State plainly which assertion failed and why it is expected to fail.

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
- Find the real test and lint commands from the repo (package scripts, Makefile,
  pyproject, CI config). Never guess a command that does not exist.
- If the project has no test infrastructure, ask before introducing one.

## Reporting

Report the actual observed output for red and green. Never claim a result that
was not observed, and never say a suite passes without running it.