{
  lib,
  buildWasmBindgenCli,
  fetchCrate,
  rhwpSrc,
  rustPlatform,
}:
let
  # The wasm-bindgen cli and crate versions must match exactly, and nixpkgs
  # lags rhwp's pin, so build the matching cli here instead of using
  # pkgs.wasm-bindgen-cli. Derive the version from rhwp's Cargo.lock so an
  # rhwp-src bump carries it automatically; only the two FOD hashes below need
  # refreshing, which the refresh-vendored-hashes workflow does via nix-update.
  inherit
    (
      (lib.findFirst (p: p.name == "wasm-bindgen") (throw "wasm-bindgen not found in rhwp Cargo.lock")
        (lib.importTOML (rhwpSrc + "/Cargo.lock")).package
      )
    )
    version
    ;

  src = fetchCrate {
    pname = "wasm-bindgen-cli";
    inherit version;
    hash = "sha256-zRawtjxMOdTMX+mZaiNR3YYfTiZJhf9qj7kXSSeMxrc=";
  };
in
buildWasmBindgenCli {
  inherit src;
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    inherit (src) pname version;
    hash = "sha256-aZCfgR23Qb0Pn4Mm4ToMtuuRQqSJjXCR9li/VvP5CTM=";
  };
}
