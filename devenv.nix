let
  mkTools = pkgs: pkgs.callPackage ./pkgs/npm-tools.nix { };

  # Haskell package set: the shared statics-common package from master-builder,
  # composed with this repo's local overrides (see overrides.nix).
  #
  # Keep the `ci` profile free of ./overlays.nix — an overlay re-instantiates the
  # whole package set, so every derivation hash changes and CI can no longer pull
  # from the shared cachix cache. The overlay is a dev-shell concern only.
  hpkgsFor =
    pkgs:
    pkgs.haskell.packages.ghc96.override {
      overrides = import ./overrides.nix { inherit pkgs; };
    };

  ci =
    { pkgs, ... }:
    let
      npmTools = mkTools pkgs;
      hpkgs = hpkgsFor pkgs;
      staticsPackage = hpkgs.callCabal2nix "statics" ./statics { };
    in
    {
      languages.elm.enable = true;
      languages.haskell.enable = true;
      languages.haskell.package = pkgs.haskell.packages.ghc96.ghc;

      env.NODE_PATH = "${npmTools}/lib/node_modules";

      packages = [
        pkgs.cabal-install
        staticsPackage
        npmTools
        pkgs.nodejs_22
        hpkgs.hlint
        hpkgs.fourmolu
        pkgs.elmPackages.elm-review
        pkgs.elmPackages.elm-json
        pkgs.tippecanoe
        pkgs.gdal
      ];

      enterShell = ''
        ln -sfn "${npmTools}/lib/node_modules" node_modules
        ln -sfn "${npmTools}/lib/node_modules" elm-app/node_modules
      '';
    };

  shell =
    { pkgs, ... }:
    let
      npmTools = mkTools pkgs;
    in
    {
      overlays = [ (import ./overlays.nix) ];

      languages.elm.enable = true;
      languages.haskell.enable = true;
      languages.haskell.package = pkgs.haskell.packages.ghc96.ghc;

      dotenv.enable = true;

      env.NODE_PATH = "${npmTools}/lib/node_modules";

      packages = with pkgs; [
        entr
        git
        nodejs_22
        treefmt
        elmPackages.elm-review
        elmPackages.elm-json
        npmTools
        tippecanoe
        gdal
        cabal-install
        haskell.packages.ghc96.hlint
        haskell.packages.ghc96.fourmolu
        pocketbase
        python3
      ];

      enterShell = ''
        ln -sfn "${npmTools}/lib/node_modules" node_modules
        ln -sfn "${npmTools}/lib/node_modules" elm-app/node_modules

        echo ""
        echo "── service-map dev environment ──────────────────────"
        echo "  GHC:    $(ghc --numeric-version)"
        echo "  Cabal:  $(cabal --numeric-version)"
        echo "  Elm:    $(elm --version)"
        echo "  Node:   $(node --version)"
        echo "  Vite:   $(vite --version)"
        echo ""
        echo "  make elm-dev    — start Vite dev server"
        echo "  make dist-ci    — production build → build/"
        echo "  make elm-dev-local / elm-build-local — run against local PocketBase"
        echo ""
        echo "  PocketBase: http://127.0.0.1:8090/_/"
        echo "  Keycloak:   http://localhost:8080"
        echo ""
      '';

      # ── PocketBase URL (statics + Elm frontend) ──────────────────────────────────
      # Both the statics generator and the Elm frontend default to the production
      # database. Use the *-local Makefile targets to target the local devenv
      # PocketBase instance instead (requires: devenv up):
      #
      #   make statics-local      # Haskell generator → local PocketBase
      #   make elm-dev-local      # Vite dev server   → local PocketBase
      #   make elm-build-local    # Production build  → local PocketBase
      #   make dist-local         # Both of the above combined
      #
      # Env vars used internally by those targets:
      #   POCKETBASE_URL          → statics generator (Haskell, runtime)
      #   VITE_POCKETBASE_URL     → Elm SPA (Vite, build-time)
      #
      # To always use the local instance in your devenv shell, add to devenv.local.nix:
      #   { env.POCKETBASE_URL = "http://127.0.0.1:8090";
      #     env.VITE_POCKETBASE_URL = "http://127.0.0.1:8090"; }
      # Or set both in a .env file (dotenv.enable = true above handles loading it).
      
      processes.pocketbase = {
        exec = ''
          pocketbase serve \
            --dir="$DEVENV_ROOT/.devenv/state/pocketbase/data" \
            --migrationsDir="$DEVENV_ROOT/fixtures/pb_migrations" \
            --http=127.0.0.1:8090
        '';
      };

      services.keycloak = {
        enable = true;
        initialAdminPassword = "admin";
        settings = { hostname = "localhost"; http-port = 8080; http-enabled = true; http-relative-path = "/"; };
        realms.pocketbase = { path = "./fixtures/keycloak-pocketbase-realm.json"; import = true; };
      };
    };
in
{
  profiles.shell.module = {
    imports = [ shell ];
  };

  profiles.ci.module = {
    imports = [ ci ];
  };
}
