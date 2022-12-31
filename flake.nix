{
  description = "flake example";
  # This is a template created by `hix init`
  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-flake.url = "github:srid/treefmt-flake";
  };


  outputs = inputs@{ self, flake-parts, nixpkgs, haskellNix, treefmt-flake, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule

      ];
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          projectName = "flake-example";
          overlays = [
            haskellNix.overlay
            (final: prev: {
              ${projectName} = final.haskell-nix.cabalProject {
                src = ./.;
                compiler-nix-name = "ghc943";
                shell.tools = {
                  cabal = { };
                  hlint = { };
                  ghcid = { };
                  # haskell-language-server = {};
                };
                modules = [
                ];
              };
            })
          ];
          pkgs = import nixpkgs { inherit system overlays; };
          haskellNixFlake = pkgs.${projectName}.flake { };
        in
          pkgs.lib.recursiveUpdate
            (builtins.removeAttrs haskellNixFlake [ "devShell" ])
            {
              # treefmt.formatters = {
              #   inherit (pkgs) nixpkgs-fmt;
              #   inherit (pkgs.haskellPackages)
              #     cabal-fmt
              #     fourmolu;
              # };
              packages.default = haskellNixFlake.packages."${projectName}:exe:hello";
              devShells.default = haskellNixFlake.devShell;
            };
    };

  # --- Flake Local Nix Configuration ----------------------------
  nixConfig = {
    # This sets the flake to use the IOG nix cache.
    # Nix should ask for permission before using it,
    # but remove it here if you do not want it to.
    extra-substituters = ["https://cache.iog.io"];
    extra-trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    allow-import-from-derivation = "true";
  };
}
