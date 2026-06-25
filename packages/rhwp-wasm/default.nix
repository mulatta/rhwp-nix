{
  lib,
  binaryen,
  rhwpSrc,
  rust-bin,
  rustPlatform,
  wasm-bindgen-cli,
}:
let
  rustToolchain = rust-bin.stable.latest.default.override {
    targets = [ "wasm32-unknown-unknown" ];
  };
in
rustPlatform.buildRustPackage {
  pname = "rhwp-wasm";
  version = "0.7.17";
  src = rhwpSrc;

  cargoLock.lockFile = rhwpSrc + "/Cargo.lock";

  nativeBuildInputs = [
    rustToolchain
    wasm-bindgen-cli
    binaryen
  ];

  doCheck = false;

  # Skip wasm-pack: it fetches its own wasm-bindgen and version-checks
  # against it. Calling cargo + wasm-bindgen directly does the same job.
  buildPhase = ''
    runHook preBuild
    cargo build \
      --release \
      --lib \
      --target wasm32-unknown-unknown \
      --offline \
      --locked
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    wasm-bindgen \
      target/wasm32-unknown-unknown/release/rhwp.wasm \
      --out-dir $out \
      --target web \
      --typescript
    wasm-opt -Oz -o $out/rhwp_bg.wasm $out/rhwp_bg.wasm
    runHook postInstall
  '';

  # Exposed for the refresh-vendored-hashes workflow to target with nix-update
  # without adding a build tool to the public packages output.
  passthru.wasm-bindgen-cli = wasm-bindgen-cli;

  meta = {
    description = "rhwp WASM bundle (rhwp.js + rhwp_bg.wasm)";
    license = lib.licenses.mit;
  };
}
