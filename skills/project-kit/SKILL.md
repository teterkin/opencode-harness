---
name: project-kit
description: Use when starting a new project or filling in the documentation and project context for an existing one - checks the documentation baseline, the project AGENTS.md core, branch conventions and the version file. Trigger words - new project, scaffold, project setup, documentation, README, CHANGELOG, TODO, project AGENTS.md.
---

# Project kit

A project is not started until its documentation and project context exist.
This skill checks and fills them; it does not invent behavior.

## Documentation baseline

Every project with a confirmed PRD has, in this order of importance:

- `LICENSE` — ask which license; MIT is the default.
- `README.md` — description, install, usage with examples, architecture,
  versions and releases. Written for someone who has never seen the repo.
- `CHANGELOG.md` — Keep a Changelog format, newest version on top.
- `TODO.md` — what is being worked on now. Everything else is an issue, not a
  line in TODO.
- `AGENTS.md` — the project rules, see below.
- `docs/prd/<slug>.md` — one confirmed PRD per non-trivial change.

If a file is missing, say so once and offer to create it. Do not create a
README full of guesses: read the code and the commands first.

## Repository metadata

Set the repository metadata before calling the project started. Empty fields are
a defect, not a default.

- `description` — one line, no emoji, no quotes: what it is and who it is for.
  Not a slogan, not the name repeated.
- `homepage` — a real documentation URL, or empty. A placeholder is worse than
  nothing.
- `topics` — 5 to 10, lowercase kebab-case, no duplicates: language, domain,
  tool. `opencode`, `ai-agents`, `tdd`.
- `visibility` — chosen on purpose at creation. A private project that becomes
  public by accident leaks its whole history.

Read the current state with
`gh repo view --json description,homepageUrl,repositoryTopics,visibility` and
write it with `gh repo edit --description "..." --add-topic <topic>`.

## Project AGENTS.md core

The project `AGENTS.md` states, exactly and only if true:

- commands: test, lint, typecheck, build, run;
- branching and commit conventions;
- the project map, and the quirks of each unusual object or module;
- domain invariants that are not visible in the code;
- the secrets policy.

Never copy another project's AGENTS.md. A command that does not run is worse
than a missing line. The harness repo ships skeletons: `templates/AGENTS.md`
and `templates/PRD.md`.

## Versions and branches

- Version lives in `VERSION`, the top entry of `CHANGELOG.md`, and the
  `vX.Y.Z` tag — all three agree.
- Trunk is `main`; work lives in `feat/<slug>`, `fix/<slug>`, `docs/<slug>` or
  `chore/<slug>`.
- `TODO.md` is for the current work; the rest is issues.

## Checks

Run the real test, lint and typecheck commands from the project before
reporting the kit complete. A green install with a stale README is not done.
