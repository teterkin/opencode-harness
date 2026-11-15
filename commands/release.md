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
     checks. Run `bash tests/repo-meta.sh` as well when the project has it.
  5. Confirm the bump and the changelog text with me before the tag.
  6. Create the annotated tag `vX.Y.Z`.
  7. Ask separately before pushing the tag and before publishing the GitHub
     Release.

  A release covers the version, the changelog, the tag, the tag push and the
  published release. It does not cover pushing pending commits: those need their
  own request, and one push may carry several commits.

  Use the `project-kit` skill for the documentation baseline.
