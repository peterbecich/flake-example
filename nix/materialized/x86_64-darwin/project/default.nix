{
  pkgs = hackage:
    {
      packages = {
        "ghc-prim".revision = (((hackage."ghc-prim")."0.8.0").revisions).default;
        "base".revision = (((hackage."base")."4.16.4.0").revisions).default;
        "ghc-bignum".revision = (((hackage."ghc-bignum")."1.2").revisions).default;
        "rts".revision = (((hackage."rts")."1.0.2").revisions).default;
        };
      compiler = {
        version = "9.2.5";
        nix-name = "ghc925";
        packages = {
          "ghc-prim" = "0.8.0";
          "base" = "4.16.4.0";
          "ghc-bignum" = "1.2";
          "rts" = "1.0.2";
          };
        };
      };
  extras = hackage:
    { packages = { hello = ./.plan.nix/hello.nix; }; };
  modules = [
    ({ lib, ... }:
      {
        packages = {
          "hello" = { flags = { "threaded" = lib.mkOverride 900 false; }; };
          };
        })
    ({ lib, ... }:
      {
        packages = {
          "ghc-prim".components.library.planned = lib.mkOverride 900 true;
          "rts".components.library.planned = lib.mkOverride 900 true;
          "ghc-bignum".components.library.planned = lib.mkOverride 900 true;
          "hello".components.exes."hello".planned = lib.mkOverride 900 true;
          "base".components.library.planned = lib.mkOverride 900 true;
          };
        })
    ];
  }