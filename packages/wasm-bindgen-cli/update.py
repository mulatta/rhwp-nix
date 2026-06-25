#!/usr/bin/env python3
"""Refresh wasm-bindgen-cli's src + cargoVendor hashes.

The cli version is derived from rhwp's Cargo.lock, so an rhwp-src bump only
moves the two FOD hashes. The cli is exposed through rhwp-wasm's passthru, not a
public package, and buildWasmBindgenCli's attr positions point into nixpkgs, so
nix-update is aimed at the passthru attr and told which file to edit. A
nix-update-args recipe cannot do this: it is locked to packages.<system>.<dir>.
"""

import subprocess

subprocess.run(
    [
        "nix-update",
        "--flake",
        "--version",
        "skip",
        "--override-filename",
        "packages/wasm-bindgen-cli/default.nix",
        "rhwp-wasm.wasm-bindgen-cli",
    ],
    check=True,
)
