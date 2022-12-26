{
  description = "A very basic flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
      flake-utils.lib.eachSystem supportedSystems (system: {

        packages.default = nixpkgs.legacyPackages.${system}.hello;

      });
}
