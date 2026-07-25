let
  ci =
    { pkgs, ... }:
    let
      npmTools = pkgs.callPackage ./pkgs/npm-tools.nix { };
      hpkgs = pkgs.haskell.packages.ghc96;
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
        pkgs.tippecanoe
        pkgs.gdal
      ];

      enterShell = ''
        ln -sfn "${npmTools}/lib/node_modules" node_modules
        mkdir -p elm-app/node_modules
        for pkg in "${npmTools}/lib/node_modules"/.*; do
          if [ "$(basename "$pkg")" != "." ] && [ "$(basename "$pkg")" != ".." ]; then
            ln -sfn "$pkg" "elm-app/node_modules/$(basename "$pkg")"
          fi
        done
        for pkg in "${npmTools}/lib/node_modules"/*; do
          ln -sfn "$pkg" "elm-app/node_modules/$(basename "$pkg")"
        done
      '';
    };

  shell =
    { pkgs, ... }:
    let
      npmTools = pkgs.callPackage ./pkgs/npm-tools.nix { };
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
      ];

      enterShell = ''
        ln -sfn "${npmTools}/lib/node_modules" node_modules
        mkdir -p elm-app/node_modules
        for pkg in "${npmTools}/lib/node_modules"/.*; do
          if [ "$(basename "$pkg")" != "." ] && [ "$(basename "$pkg")" != ".." ]; then
            ln -sfn "$pkg" "elm-app/node_modules/$(basename "$pkg")"
          fi
        done
        for pkg in "${npmTools}/lib/node_modules"/*; do
          ln -sfn "$pkg" "elm-app/node_modules/$(basename "$pkg")"
        done

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
