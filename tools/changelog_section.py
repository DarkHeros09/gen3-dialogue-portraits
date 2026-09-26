"""Print one version's section from CHANGELOG.md, for a GitHub Release body.

The launcher's "What's New?" renders the **release body** and never reads a file
in the repo (`src/mods/ModUpdate.lua`, `cleanBody`), so the only way a release's
changelog reaches the player is to publish it AS the body.  This is the one
implementation of "which part of CHANGELOG.md is this release", so the workflow
and any local check cannot disagree about it.

  * the section is the block headed `## <version>` and runs to the next line that
    starts with `## ` (or to the end of the file);
  * a missing section is an ERROR, not an empty release -- shipping generated
    commit notes instead is exactly the failure this exists to prevent;
  * the heading is kept, because the launcher strips a leading `#` run itself and
    the heading then becomes the first line of the release preview.

Usage:  python changelog_section.py <version> [CHANGELOG.md]
"""

import os
import re
import sys


def section(text, version):
    """The `## <version>` block of `text`, heading included, or None."""
    pattern = re.compile(
        r"^##[ \t]+" + re.escape(version) + r"\b.*?(?=^##[ \t]|\Z)",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(text)
    if not match:
        return None
    return match.group(0).strip() + "\n"


def main(argv):
    if not argv:
        print(__doc__, file=sys.stderr)
        return 2
    version = argv[0]
    path = argv[1] if len(argv) > 1 else "CHANGELOG.md"
    if not os.path.isfile(path):
        print("error: no such changelog: " + path, file=sys.stderr)
        return 1
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    body = section(text, version)
    if body is None:
        print(
            "error: {} has no '## {}' section".format(path, version),
            file=sys.stderr,
        )
        return 1
    if not body.strip():
        print(
            "error: the '## {}' section of {} is empty".format(version, path),
            file=sys.stderr,
        )
        return 1
    sys.stdout.write(body)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
