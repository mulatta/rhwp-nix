{
  description = "rhwp-nix";

  inputs = {
    # keep-sorted start
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rhwp-src.flake = false;
    rhwp-src.url = "github:edwardkim/rhwp";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    # keep-sorted end
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [ inputs.treefmt-nix.flakeModule ];

      perSystem =
        {
          pkgs,
          system,
          ...
        }:
        let
          callPackage = pkgs.newScope {
            rhwpSrc = inputs.rhwp-src;
            rhwpCargoLock = ./lockfiles/rhwp-Cargo.lock;
          };
          rhwp-wasm = callPackage ./packages/rhwp-wasm { };
          rhwp-cli = callPackage ./packages/rhwp-cli { };
          rhwp-studio = callPackage ./packages/rhwp-studio { inherit rhwp-wasm; };
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ inputs.rust-overlay.overlays.default ];
          };

          packages = {
            inherit rhwp-wasm rhwp-studio rhwp-cli;
            default = rhwp-cli;
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              cargo
              just
            ];
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              # keep-sorted start
              deadnix.enable = true;
              keep-sorted.enable = true;
              nixfmt.enable = true;
              statix.enable = true;
              # keep-sorted end
            };
          };
        };
    };
}
