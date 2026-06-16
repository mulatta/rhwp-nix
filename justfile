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
    # Seed the existing lock so the resolve keeps every still-valid pin. This
    # matters for wasm-bindgen: it must match the separately-pinned
    # wasm-bindgen-cli in packages/rhwp-wasm, and `cargo generate-lockfile`
    # would re-resolve it to latest and silently break that coupling. With the
    # lock seeded, `cargo metadata` only bumps requirements the seed cannot
    # satisfy (e.g. a quick-xml major bump) and leaves the rest untouched.
    cp lockfiles/rhwp-Cargo.lock "$tmp/Cargo.lock"
    (cd "$tmp" && cargo metadata --format-version 1 >/dev/null)
    install -m 0644 "$tmp/Cargo.lock" lockfiles/rhwp-Cargo.lock
    echo "lockfiles/rhwp-Cargo.lock updated"

# Recompute rhwp-studio's npmDepsHash against the flake-pinned rhwp-src
bump-studio-hash:
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{ justfile_directory() }}
    src=$(nix eval --raw --impure --expr \
      "(builtins.getFlake (toString ./.)).inputs.rhwp-src.outPath")
    hash=$(nix run nixpkgs#prefetch-npm-deps -- "$src/rhwp-studio/package-lock.json")
    sed -i "s|npmDepsHash = \"sha256-[^\"]*\"|npmDepsHash = \"$hash\"|" \
      packages/rhwp-studio/default.nix
    echo "rhwp-studio npmDepsHash updated to $hash"

# Refresh every vendored artifact derived from rhwp-src (Rust lock + npm hash)
refresh-vendored: bump-cargo-lock bump-studio-hash

# Bump rhwp-src then refresh the vendored artifacts to match the new rev
bump: bump-rhwp-src refresh-vendored
