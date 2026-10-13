# Service Map (Palikkakartta)

Palikkakartta (Service Map) for Suomen Palikkaharrastajat ry, built with Elm 0.19, Haskell, and PocketBase.


## Overview

The project combines:

- an Elm frontend in [`elm-app/`](elm-app) for the public map, locations views, and authenticated editing
- a Haskell static generator in [`statics/`](statics) for feeds, GeoJSON, and exported assets

Features include an interactive MapLibre map, location lists, authenticated CRUD, KML import, and static exports such as RSS, Atom, JSON Feed, and GeoJSON. The vector basemap is built and hosted by the separate [`service-map-tiles`](https://github.com/Suomen-Palikkaharrastajat-ry/service-map-tiles) project and served from <https://tiles.palikkaharrastajat.fi/>; this app loads its published MapLibre style (configurable via `VITE_BASEMAP_STYLE_URL`).

## Development Environment

This project uses `devenv` for local development and CI.

```sh
make develop
make shell
```

On a fresh environment, run `cabal update` before the first `cabal build statics`.

The default PocketBase URL is `https://data.palikkaharrastajat.fi`. For local development, set `VITE_POCKETBASE_URL` and `POCKETBASE_URL` via `.env` or use the `*-local` Makefile targets. The basemap style defaults to `https://tiles.palikkaharrastajat.fi/style.json`; override it with `VITE_BASEMAP_STYLE_URL` (see [`.env.example`](.env.example)). Local PocketBase and Keycloak services are available through `devenv up`.

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
| `make site-config` | Regenerate the files derived from `config.toml` |
| `make format` | Auto-format Elm and Haskell code |
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
scripts/          Deployment helper scripts (e.g. smoke-test.sh)
vendor/master-builder  Shared Elm design tokens and UI components
.github/workflows CI/CD workflows
```

## Configuration and Translations

The site describes itself in [`config.toml`](config.toml): URL, title,
description, languages, and the app's own settings under `[app]`. It is layered
on the family defaults of the hub; the format is documented in
[`vendor/master-builder/docs/site-config.md`](vendor/master-builder/docs/site-config.md).

- Text in the default language (Finnish) sits directly in a section; English
  goes in a sub-table such as `[site.en]` or `[app.en]`.
- Vite generates the document head and `site.webmanifest` from it, so
  `elm-app/index.html` carries no title, description or icon tags.
- Two committed files are derived from it: `elm-app/tests/SiteFixture.elm`
  and `statics/src/SiteConfig.hs` (used by the feeds). After editing
  `config.toml`, run `make site-config`; `make site-config-check` (part of
  `make elm-check` and of CI) fails when they are stale.
- Interface text lives in `elm-app/src/I18n.elm`, per language. Views take a
  `Lang` and contain no text of their own; the same check fails on Finnish
  text outside translations. To add a string, add a key (or a function, when
  the wording depends on a number) with its Finnish and English text.
- A visitor switches language with the footer link or `?lang=en`.

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
