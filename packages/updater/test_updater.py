"""Regression tests for the updater orchestrator."""

from __future__ import annotations

import sys
from pathlib import Path

from updater.__main__ import build_command


def test_nix_update_args_builds_flake_attr(tmp_path: Path) -> None:
    pkg = tmp_path / "rhwp-studio"
    pkg.mkdir()
    (pkg / "nix-update-args").write_text("--version skip\n")

    cmd = build_command(pkg, "x86_64-linux")

    assert cmd == [
        "nix-update",
        "--flake",
        "packages.x86_64-linux.rhwp-studio",
        "--version",
        "skip",
    ]
    # nix-update >=1.14 rejects a leading '.#' on the attribute argument.
    attr = cmd[cmd.index("--flake") + 1]
    assert not attr.startswith(".")


def test_update_py_runs_script(tmp_path: Path) -> None:
    pkg = tmp_path / "wasm-bindgen-cli"
    pkg.mkdir()
    script = pkg / "update.py"
    script.write_text("")

    assert build_command(pkg, "x86_64-linux") == [sys.executable, str(script)]


def test_nix_update_args_takes_precedence_over_update_py(tmp_path: Path) -> None:
    pkg = tmp_path / "both"
    pkg.mkdir()
    (pkg / "nix-update-args").write_text("--version skip")
    (pkg / "update.py").write_text("")

    cmd = build_command(pkg, "x86_64-linux")
    assert cmd is not None
    assert cmd[0] == "nix-update"


def test_no_recipe_is_skipped(tmp_path: Path) -> None:
    pkg = tmp_path / "rhwp-cli"
    pkg.mkdir()
    assert build_command(pkg, "x86_64-linux") is None
