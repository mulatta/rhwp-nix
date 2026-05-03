{
  lib,
  binaryen,
  buildWasmBindgenCli,
  fetchCrate,
  rhwpCargoLock,
  rhwpSrc,
  rust-bin,
  rustPlatform,
}:
let
  rustToolchain = rust-bin.stable.latest.default.override {
    targets = [ "wasm32-unknown-unknown" ];
  };

  # rhwp Cargo.lock pins wasm-bindgen 0.2.120; nixpkgs only ships up to
  # 0.2.118, and the bindgen/cli versions must match exactly. Build the
  # matching cli locally.
  wasmBindgenCliSrc = fetchCrate {
    pname = "wasm-bindgen-cli";
    version = "0.2.120";
    hash = "sha256-Dkkx8Bhfk+y/jEz9Fzwytmv2N3Gj/7ST+5MlPRzzetU=";
  };
  wasmBindgenCli = buildWasmBindgenCli {
    src = wasmBindgenCliSrc;
    cargoDeps = rustPlatform.fetchCargoVendor {
      src = wasmBindgenCliSrc;
      inherit (wasmBindgenCliSrc) pname version;
      hash = "sha256-5Zu/Sh9aBMxB+KGC1MHWJAQ8PuE40M6lsenkpFEwJ6A=";
    };
  };
in
rustPlatform.buildRustPackage {
  pname = "rhwp-wasm";
  version = "0.7.8";
  src = rhwpSrc;

  cargoLock.lockFile = rhwpCargoLock;
  postPatch = ''
    cp ${rhwpCargoLock} Cargo.lock
  '';

  nativeBuildInputs = [
    rustToolchain
    wasmBindgenCli
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

  meta = {
    description = "rhwp WASM bundle (rhwp.js + rhwp_bg.wasm)";
    license = lib.licenses.mit;
  };
}
