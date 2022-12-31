{
  # This is a template created by `hix init`
  inputs.haskell-nix.url = "github:input-output-hk/haskell.nix";
  inputs.nixpkgs.follows = "haskell-nix/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils, haskell-nix }@inputs: let
    supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

    ifExists = p: if builtins.pathExists p then p else null;

    flake = { self, nixpkgs, flake-utils, haskell-nix }: flake-utils.lib.eachSystem supportedSystems (evalSystem: let
      packagesBySystem = builtins.listToAttrs (map (system: {
        name = system;

        value = let
          materializedRelative = "/nix/materialized/${system}";

          materializedFor = component: ifExists (./. + materializedRelative + "/${component}");

          pkgs = import nixpkgs {
            inherit system;
            overlays = [ haskell-nix.overlay ];
            inherit (haskell-nix) config;
          };

          tools = {
            cabal = {
              inherit (project) index-state evalSystem;
              version = "3.8.1.0";
              materialized = materializedFor "cabal";
            };
          };

          project = pkgs.haskell-nix.cabalProject' {
            inherit evalSystem;
            src = ./.;
            compiler-nix-name = "ghc943";
            shell.tools = tools;
            materialized = materializedFor "project";
          };

          tools-built = project.tools tools;
        in {
          inherit pkgs project;

          update-all-materialized = evalPkgs.writeShellScript "update-all-materialized-${system}" ''
            set -eEuo pipefail
            mkdir -p .${materializedRelative}
            cd .${materializedRelative}
            echo "Updating project materialization" >&2
            ${project.plan-nix.passthru.generateMaterialized} project
            echo "Updating cabal materialization" >&2
            ${tools-built.cabal.project.plan-nix.passthru.generateMaterialized} cabal
          '';
        };
      }) supportedSystems);

      inherit (packagesBySystem.${evalSystem}) project pkgs;

      evalPkgs = pkgs;

      flake = project.flake {};
    in flake // rec {
      defaultPackage = packages.default;

      packages = flake.packages // {
        default = flake.packages."hello:exe:hello";
      };

      defaultApp = apps.default;

      apps = flake.apps // {
        default = flake.apps."hello:exe:hello";

        update-all-materialized = {
          type = "app";

          program = (pkgs.writeShellScript "update-all-materialized" ''
            set -eEuo pipefail
            cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
            ${pkgs.lib.concatStringsSep "\n" (map (system: ''
              echo "Updating materialization for ${system}" >&2
              ${packagesBySystem.${system}.update-all-materialized}
            '') supportedSystems)}
          '').outPath;
        };
      };
      hydraJobs = self.packages.${evalSystem};
    });
  in flake inputs // {
    hydraJobs = { nixpkgs ? inputs.nixpkgs, flake-utils ? inputs.flake-utils, haskell-nix ? inputs.haskell-nix }@overrides: let
      flake' = flake (inputs // overrides // { self = flake'; });
      evalSystem = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${evalSystem};
    in flake'.hydraJobs // {
      forceNewEval = pkgs.writeText "forceNewEval" (self.rev or self.lastModified);
      required = pkgs.releaseTools.aggregate {
        name = "cicero-pipe";
        constituents = builtins.concatMap (system:
          map (x: "${x}.${system}") (builtins.attrNames flake'.hydraJobs)
        ) supportedSystems;
      };
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
