#!/usr/bin/env python3
"""Run each ./packages entry's self-declared update recipe, in place.

Dependabot bumps rhwp-src in flake.lock; the hashes derived from that source go
stale and must be regenerated. Each package that needs it declares how, and
this discovers and runs them; the workflow commits whatever changed.

Two recipe kinds (matching the dots updater, minus its PR/worktree machinery):
  - nix-update-args : run nix-update on packages.<system>.<dir> with these args
  - update.py       : run the script (custom logic, e.g. a passthru attr that
                      packages.<system>.<dir> cannot name)
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

# FOD hashes are system-independent, so any configured system resolves them.
SYSTEM = "x86_64-linux"


def flake_root() -> Path:
    # Installed via Nix, __file__ lives in /nix/store, so derive the repo from
    # git rather than the script location.
    out = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=True,
    )
    return Path(out.stdout.strip())


def build_command(pkg: Path, system: str) -> list[str] | None:
    """The command that refreshes pkg, or None if it declares no recipe."""
    args_file = pkg / "nix-update-args"
    if args_file.exists():
        return [
            "nix-update",
            "--flake",
            f"packages.{system}.{pkg.name}",
            *args_file.read_text().split(),
        ]
    script = pkg / "update.py"
    if script.exists():
        return [sys.executable, str(script)]
    return None


def main() -> int:
    root = flake_root()
    failures = 0
    for pkg in sorted((root / "packages").iterdir()):
        if not pkg.is_dir():
            continue
        cmd = build_command(pkg, SYSTEM)
        if cmd is None:
            continue
        print(f"+ {' '.join(cmd)}", file=sys.stderr)
        try:
            # Isolate per-package failures so one stale recipe does not abort
            # the rest of the run.
            subprocess.run(cmd, cwd=root, check=True)
        except subprocess.CalledProcessError as e:
            print(f"  {pkg.name}: {e}", file=sys.stderr)
            failures += 1
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
