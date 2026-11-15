---
description: Release a SemVer version, keeping VERSION, CHANGELOG and the git tag in agreement.
agent: implementer
template: |
  Release the next SemVer version. Ask me for the bump (MAJOR/MINOR/PATCH) if
  it is not obvious from the diff; do not guess silently.

  Steps, in this order:
  1. Bump `VERSION` to the new `MAJOR.MINOR.PATCH`.
  2. Write the `CHANGELOG.md` entry for that version, newest on top.
  3. Update the README versions and compatibility section if behavior changed.
  4. Run the project's real checks and paste the output. Never tag with red
     checks.
  5. Only then create the annotated tag `vX.Y.Z`.

  Confirm the bump and the changelog text with me before the tag. Use the
  `project-kit` skill for the documentation baseline.
