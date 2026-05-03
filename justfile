# Justfile for rhwp-nix maintenance.

# List recipes
_default:
    @just --list --unsorted

# Bump flake.lock entry for rhwp-src to latest upstream HEAD
bump-rhwp-src:
    nix flake update rhwp-src

# Regenerate lockfiles/rhwp-Cargo.lock against the flake-pinned rhwp-src
bump-cargo-lock:
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{ justfile_directory() }}
    src=$(nix eval --raw --impure --expr \
      "(builtins.getFlake (toString ./.)).inputs.rhwp-src.outPath")
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    cp -r "$src/." "$tmp/"
    chmod -R u+w "$tmp"
    (cd "$tmp" && cargo generate-lockfile)
    install -m 0644 "$tmp/Cargo.lock" lockfiles/rhwp-Cargo.lock
    echo "lockfiles/rhwp-Cargo.lock updated"

# Bump rhwp-src then refresh Cargo.lock to match the new rev
bump: bump-rhwp-src bump-cargo-lock
