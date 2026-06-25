{
  lib,
  rhwpSrc,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "rhwp-cli";
  version = "0.7.17";
  src = rhwpSrc;

  cargoLock.lockFile = rhwpSrc + "/Cargo.lock";

  # Skip the cdylib (wasm32 lib) and the optional font-metric-gen dev tool;
  # only the `rhwp` binary is consumer-facing. `--locked` makes cargo refuse
  # to rewrite Cargo.lock, surfacing any drift between the committed Cargo.lock
  # and the rhwp-src Cargo.toml as a build error instead of a silent update.
  cargoBuildFlags = [
    "--locked"
    "--bin"
    "rhwp"
  ];

  doCheck = false;

  meta = {
    description = "rhwp native CLI: HWP/HWPX → SVG/PDF";
    license = lib.licenses.mit;
    mainProgram = "rhwp";
  };
}
