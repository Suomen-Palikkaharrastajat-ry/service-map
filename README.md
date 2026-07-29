# Service Map (Palikkakartta)

Palikkakartta (Service Map) for Suomen Palikkaharrastajat ry, built with Elm 0.19, Haskell, and PocketBase.

## Overview

The project combines:

- an Elm frontend in [`elm-app/`](elm-app) for the public map, locations views, and authenticated editing
- a Haskell static generator in [`statics/`](statics) for feeds, GeoJSON, and exported assets

Features include an interactive MapLibre map with a PMTiles basemap, location lists, authenticated CRUD, KML import, and static exports such as RSS, Atom, JSON Feed, and GeoJSON.

## Development Environment

This project uses `devenv` for local development and CI.

```sh
make develop
make shell
```

On a fresh environment, run `cabal update` before the first `cabal build statics`.

The default PocketBase URL is `https://data.palikkaharrastajat.fi`. For local development, set `VITE_POCKETBASE_URL` and `POCKETBASE_URL` via `.env` or use the `*-local` Makefile targets. Local PocketBase and Keycloak services are available through `devenv up`.

## Common Commands

| Command | What it does |
|---|---|
| `make shell` | Open the development shell |
| `make elm-dev` | Start the Elm + Vite dev server |
| `make elm-build` | Build the Elm frontend into `dist/` |
| `make statics-build` | Build the Haskell static generator |
| `make statics` | Generate static files from live locations |
| `make dist` | Build the statics and Elm app together |
| `make test` | Run Elm and Haskell tests |
| `make check` | Run formatting and lint checks |
| `make format` | Auto-format Elm and Haskell code |
| `make basemap` | Generate the PMTiles basemap via scripts |
| `make elm-tailwind-gen` | Run Tailwind generation for Elm |
| `make watch` | Run watch mode |
| `make clean` | Remove build output |

## Project Structure

```text
elm-app/          Elm 0.19 SPA frontend
  src/            Elm source modules
  tests/          Elm unit tests
  public/         Static frontend assets
  packages/       Symlink to shared Elm packages in vendor/master-builder
statics/          Haskell static generator
  src/            Haskell library modules
  app/            Haskell executable entry point
assets/           Files copied verbatim into dist/
pkgs/             Nix-managed Node/Vite/Elm tooling manifest + lockfile
scripts/          Scripts like generate-basemap.sh
vendor/master-builder  Shared Elm design tokens and UI components
.github/workflows CI/CD workflows
```

## Shared Frontend Conventions

The frontend follows the Suomen Palikkaharrastajat design guide:

- https://logo.palikkaharrastajat.fi/
- https://logo.palikkaharrastajat.fi/brand.css

Shared Elm design tokens and UI components are exposed through [`elm-app/packages`](elm-app/packages), which points to [`vendor/master-builder/packages`](vendor/master-builder/packages).

Frontend tooling is managed through Nix, not `pnpm`:

- [`pkgs/package.json`](pkgs/package.json)
- [`pkgs/package-lock.json`](pkgs/package-lock.json)
- [`pkgs/npm-tools.nix`](pkgs/npm-tools.nix)

## CI and Deployment

GitHub Actions builds and deploys the site to GitHub Pages.

Human-facing usage lives here in `README.md`. Agent-specific development instructions live in [`AGENTS.md`](AGENTS.md).
