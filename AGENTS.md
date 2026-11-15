<!-- harness:begin -->
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
   open questions, risks, and the sources you actually read.
2. Stop and let the user confirm it before writing code.
3. Do not silently implement a requirement the user never agreed to.
4. Save the confirmed PRD to `docs/prd/<slug>.md` and check the result against
   its acceptance criteria one by one.

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

- Run the project's real checks (lint, typecheck, tests), found in package
  scripts, Makefile or CI config. Never invent a command.
- If the repository has `tests/doctor.sh`, run it first. Exit code 2 means the
  running tool version differs from the tested one: the harness is unverified
  and the self-tests must run.
- Then report: what changed, what you ran, the actual output, and what remains
  unverified. A check that could not run is stated, not implied as green.

## 6. Git discipline

- At the start of any task, check the repository:
  `git rev-parse --is-inside-work-tree`.
- If the working directory is not a git repository, initialize it without
  asking: `git init`, and say so in one line. Do not initialize `$HOME` or `/`,
  and do not create commits there.
- Never run `git commit`, `git push`, `git checkout`, `git reset`, `git rebase`,
  `git merge`, or history-rewriting commands unless the user explicitly asks.
  `/release` counts as asking.
- Trunk is `main`; work lives in `feat/<slug>`, `fix/<slug>`, `docs/<slug>` or
  `chore/<slug>`.
- Never commit secrets, credentials, or `.env`-style files.
- Keep the working tree changes reviewable; do not stage everything blindly.

## 7. Pin every dependency

- Never install a dependency without an exact version (`pkg==1.2.3`).
  Floating specs (`^`, `~`, `>=`, `latest`) break at the worst possible
  moment, in someone else's session, with no obvious cause.
- Pins live in a committed file (`requirements*.txt`, `pyproject.toml`,
  `package.json` lockfile, `Dockerfile` `ARG`), never only in a shell
  history or a chat message.
- Anything baked into a shared/base image gets a full transitive freeze
  (`pip freeze`), not just top-level pins — a fresh resolve is a fresh
  chance to break.
- Upgrading a pin is a deliberate, isolated change: one commit, tests run,
  output reported. A rebuild must never silently pick up new versions.
- Base images and external sources are pinned too: image tag (or digest),
  and `git clone` by commit SHA with an explicit ref.

## 8. Releases use SemVer

- A version is `MAJOR.MINOR.PATCH` and lives in exactly three places that must
  agree: `VERSION`, the top entry of `CHANGELOG.md`, and the `vX.Y.Z` tag.
- MAJOR: rules, permissions, agent/command/skill names or the minimum tool
  version change incompatibly. MINOR: a new agent, command, skill or rule that
  stays compatible. PATCH: wording, docs, bug fixes without behavior change.
- Release order: bump `VERSION`, write the `CHANGELOG.md` entry, run the real
  checks, tag. Never tag with red checks.

## 9. Docs travel with the work

- A project with a PRD also has: `LICENSE`, `README.md`, `CHANGELOG.md`,
  `TODO.md`, `AGENTS.md`, and confirmed PRDs in `docs/prd/`.
- README order: description, install, usage with examples, architecture,
  versions and releases. Ask which license to use; MIT is the default.
- Docs change in the same diff as the behavior. A stale README is a bug, not a
  backlog item.

## 10. Project AGENTS.md has a required core

Every project's `AGENTS.md` states, exactly and only if true:

- commands: test, lint, typecheck, build, run;
- branching and commit conventions;
- project map, and the quirks of each unusual object or module;
- domain invariants that are not visible in the code;
- secrets policy.

If the file is missing or a section is absent, say so once and offer to fill it
in.

## 11. Language

- Reply in the language the user writes in: Russian for this user.
- Keep rules, skills and agent prompts in English.
- User-facing docs follow the language of the project's README.

## 12. MCP servers default to off, enable per project

- Keep a heavyweight MCP server in the global
  `~/.config/opencode/opencode.json` with `"disabled": true`. It stays
  configured but never connects on its own.
- Enable it where it is actually used by adding `opencode.jsonc` to that project
  with the full server object and `"disabled": false`.
- A project config replaces the whole server object, so repeat every required
  field (`type`, `command` / `url`, `environment`). A partial object silently
  leaves the server unconfigured.
- Never use `policies` with `mcp.use` for this: broad configuration outranks
  narrow, so a global `deny` cannot be lifted by a project.
- `/mcps` connects or disconnects for the current session only; it does not
  persist. Only the config files decide the default.
- Which servers are configured is per machine and per project: never write your
  own setup into these rules. Keep personal notes outside the harness markers in
  your own `AGENTS.md`, and project servers in that project's `opencode.jsonc`.
- Right after writing an `opencode.jsonc`, the first `opencode mcp list` can race
  the config reload and print `No MCP servers configured`. Re-run it, or
  `/reload`, before believing the result.

## 13. Stay inside the session's working directory

- Treat the directory the session started in as the only project. Do not walk up
  to a parent directory or sideways into a sibling repository, even if it is a
  checkout of the same project.
- An empty or non-git working directory is not a reason to look for a better
  repository: initialize it there, or stop and ask the user.
- Everything outside the project — reads and writes — needs the user's approval.
  The harness encodes this as `external_directory: ask`; do not work around it
  by moving files with shell commands.
- If a task looks like it belongs to another project, say so and wait for an
  explicit instruction before touching anything there.
<!-- harness:end -->
