{
  lib,
  buildNpmPackage,
  rhwp-wasm,
  rhwpSrc,
}:
buildNpmPackage {
  pname = "rhwp-studio";
  version = "0.7.11";
  src = rhwpSrc;
  sourceRoot = "source/rhwp-studio";

  npmDepsHash = "sha256-BPN8CP4VuqzteWw96pivnbmadSMsTScx8Bvkf94/om0=";

  # rhwp-studio's vite.config.ts aliases `@wasm` to ../pkg, so the wasm bundle
  # must live next to the studio dir at build time. The unpacked source dir is
  # cp'd from the store with read-only mode; chmod the parent before mkdir.
  preBuild = ''
    chmod -R u+w ..
    mkdir -p ../pkg
    cp -r ${rhwp-wasm}/* ../pkg/
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist/* $out/
    runHook postInstall
  '';

  meta = {
    description = "rhwp-studio static bundle (Vite build)";
    license = lib.licenses.mit;
  };
}
