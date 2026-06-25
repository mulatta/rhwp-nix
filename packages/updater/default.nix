{
  lib,
  python3,
  makeWrapper,
  nix-update,
  nix,
  git,
}:
python3.pkgs.buildPythonApplication {
  pname = "updater";
  version = "0.1.0";
  pyproject = false;

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/updater $out/bin
    cp ./*.py $out/lib/updater/

    makeWrapper ${python3}/bin/python3 $out/bin/updater \
      --add-flags "-m updater" \
      --prefix PATH : ${
        lib.makeBinPath [
          nix-update
          nix
          git
        ]
      } \
      --set PYTHONPATH $out/lib

    runHook postInstall
  '';

  nativeInstallCheckInputs = [ python3.pkgs.pytest ];
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    PYTHONPATH=$out/lib pytest test_updater.py
    runHook postInstallCheck
  '';

  meta = {
    description = "Refreshes the Nix hashes rhwp-nix derives from rhwp-src";
    mainProgram = "updater";
  };
}
