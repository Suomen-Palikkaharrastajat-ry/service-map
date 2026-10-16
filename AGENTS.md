# AGENTS.md

This file provides instructions for AI coding agents working on this project.

## Project Overview

**Palikkakartta**: Built with an **Elm 0.19 SPA** (frontend) and a **Haskell static generator** (feeds + GeoJSON), backed by **PocketBase**.

The backend is hosted at `https://data.palikkaharrastajat.fi`. The `locations` collection backend is shared with `event-calendar`.

There is **no TypeScript, no Svelte, no ESLint, no Prettier, and no pnpm** in the current codebase.

## Repository Layout

```
elm-app/          Elm 0.19 SPA (Vite + vite-plugin-elm + Tailwind CSS 4)
  src/            Elm source modules (Page/*, View/*, etc.; sign-in lives in the hub's `PocketBaseAuth`)
  tests/          Elm unit tests
  public/         Static assets
  packages/       Symlink to shared Elm packages in vendor/master-builder
statics/          Haskell static generator
  src/            Library modules
  app/            Executable entry point
  tests/          Haskell tests
review/           elm-review config (shared LlmAgent rules via vendor/master-builder)
assets/           Files copied verbatim into dist/
fixtures/         Test data fixtures
pkgs/             Nix-managed npm packages (npm-tools.nix wraps vendor/master-builder/pkgs/mk-npm-tools.nix)
scripts/          Scripts
vendor/master-builder  Submodule for shared Elm + Haskell packages
dist/             Generated production output (not committed)
.github/workflows CI/CD
```

Shared code is consumed through the pinned `vendor/master-builder` submodule: Elm
plumbing from `packages/app-toolkit` (`Geocoding`, `View.MapWidget`, `View.Icons`)
and Haskell modules from `packages-hs/statics-common` (`DescriptionHtml`,
`ImageFetcher`). Edit these in master-builder and bump the pin — do not re-add local copies.

## Development Environment

The project uses **devenv** (Nix). Always run commands inside the devenv shell, either with `make shell` (interactive) or prefixed with `devenv shell --`. Run `make vendor` first so the `vendor/master-builder` submodule (shared packages + npm-tools builder) is present before `devenv shell`.

**Enter the shell interactively:**
```sh
make shell
```

### npm / node_modules

All npm packages are managed by the Nix derivation in `pkgs/npm-tools.nix`. There is no `package.json` in the project root or in `elm-app/`.
When `devenv shell` starts, `enterShell` creates a single symlink `elm-app/node_modules → <nix-store>/…/node_modules` (and one at the repo root) so `vite`/`elm-test` resolve packages from either directory.

Shared package layout:
```
elm-app/packages -> ../vendor/master-builder/packages
```

**To update npm dependencies:**
1. Edit `pkgs/package.json`
2. Generate a new lockfile: `npm install --package-lock-only --ignore-scripts`
3. Set `hash = pkgs.lib.fakeHash;` in `pkgs/npm-tools.nix`
4. Run `devenv shell` — it fails with `got: sha256-…` in the error
5. Paste that sha256 into `pkgs/npm-tools.nix`

## Build and Test Commands

All commands are defined in the `Makefile`. Run them from the repo root:

| Command | Description |
|---------|-------------|
| `make elm-dev` | Start Elm + Vite dev server (hot reload) at http://localhost:5173 |
| `make elm-build` | Production build of Elm SPA → `dist/` |
| `make elm-test` | Run Elm unit tests |
| `make elm-check` | Validate Elm formatting (elm-format --validate) + elm-review |
| `make elm-review` | Run elm-review with the shared LlmAgent rules from `vendor/master-builder` |
| `make elm-format` | Auto-format Elm source files |
| `make statics-build` | Build Haskell static generator |
| `make statics` | Run generator (writes static files to `assets/`; `make dist` copies them to `dist/`) |
| `make statics-test` | Run Haskell unit tests |
| `make statics-check` | Lint Haskell source (hlint) |
| `make statics-format` | Auto-format Haskell source (fourmolu) |
| `make test` | Run all tests (Elm + Haskell) |
| `make dist` | Full production build: Elm SPA + static files |
| `make format` | Auto-format all source files |
| `make check` | Validate all formatting without changes |
| `make clean` | Remove `dist/` |
| `make elm-tailwind-gen` | Run Tailwind generation for Elm |
| `make watch` | Run watch mode for development |

**First-time Haskell setup** — run `cabal update` before the first `cabal build statics` in a fresh environment.

## Architecture Notes

### Elm SPA
- `Browser.application` with hash routing: `/#/`, `/#/locations`, `/#/locations/new`, `/#/locations/:id`, `/#/locations/:id/edit`
- MapLibre GL vector basemap loaded from the external [`service-map-tiles`](https://github.com/Suomen-Palikkaharrastajat-ry/service-map-tiles) service, served from `https://tiles.palikkaharrastajat.fi/`. `main.js` registers the `pmtiles://` protocol and points MapLibre at the published `style.json` (override via `VITE_BASEMAP_STYLE_URL`); no tiles, glyphs, or GeoJSON are hosted here. The form location-picker uses an inline OSM raster style for street-level zoom.
- Ports surface: `initMap`, `addMarkers`, `markerClicked`, `setMapMarker`, `mapMarkerMoved`, `destroyMap`, OAuth ports, `parseKml`/`kmlParsed`.
- Map filters are persisted to `localStorage.mapFilters` via `saveFilterState`, whose
  payload is `{ hiddenTags : List String, eventsFilter : String }`. The events filter is
  three-state (`Types.EventFilter`: `"all"` / `"no-cancelled"` / `"none"`), defaulting to
  `no-cancelled` for a new visitor; `main.js` migrates the legacy `eventsHidden` boolean.
  Cancelled events (`Event.cancelled`, read-only from the `events` collection) are dimmed
  via the `marker-cancelled` class and badged in the detail panel. `addMarkers`
  (`MarkerData`) and `focusMapOnMarker` both carry `cancelled`.
- OAuth is the PocketBase popup flow (`authWithOAuth2`, returning to `/api/oauth2-redirect`), opened synchronously in the click by the hub's `pocketbase-auth.js`, which `main.js` wires with the lazy SDK. The app has no `#/callback` route: such a URL is treated as not found.
- Uses `RemoteData` for async state.
- Uses the opening-hours editor from the vendored `osm-opening-hours` package.

### Haskell Static Generator
- Fetches data and outputs feeds: `kartta.rss`, `kartta.atom`, `kartta.json`, `kartta.geo.json`, plus `images/`.
- Uses `POCKETBASE_URL` env variable.

## Known Gotchas

- **Submodule gitlink required** (refer to TODO-01 history).
- **`mapMarkerMoved` must stay subscribed**.
- **(0,0) coordinates must be filtered** out.
- **Basemap is external** — served by the `service-map-tiles` project, not built here. If the map is blank, check `VITE_BASEMAP_STYLE_URL` and that `https://tiles.palikkaharrastajat.fi/style.json` is reachable.
- **node_modules symlinks are read-only Nix store** — never `npm install` inside `elm-app/`.
- **GHC pinned to 9.6**.
- Run `cabal update` before the first `cabal build`.

## Manual E2E Test Checklist

- [ ] Map renders markers (published only, signed-out)
- [ ] Detail panel shows correctly when clicking a marker
- [ ] Events filter cycles all → no-cancelled → none (middle state renders indeterminate) and survives a reload
- [ ] Cancelled events show a `PERUTTU` badge with a struck title and a dimmed marker
- [ ] Locations list view renders correctly
- [ ] CRUD flow works (create, edit, delete) with appropriate toasts
- [ ] Delete flow redirects appropriately
- [ ] KML import parses correctly
- [ ] Mobile responsive layout works on 375 px viewport
- [ ] Keyboard navigation is usable
- [ ] `dist/kartta.rss` and `dist/kartta.atom` validate
- [ ] `dist/kartta.geo.json` is a valid GeoJSON

## Style Guide

The association's official design guide lives at **<https://logo.palikkaharrastajat.fi/>**.

**Agent CSS reference:** Fetch `https://logo.palikkaharrastajat.fi/brand.css` for the canonical `@theme`, `@utility type-*`, reduced-motion rule, and shared component classes (the Outfit `@font-face` is not there: `main.css` imports `vendor/master-builder/public/fonts/outfit.css`, the only font declaration). Copy into `elm-app/main.css`.

### Design tokens, typography, logos, WCAG

**Single source of truth:** the design-system reference lives in
[`vendor/master-builder/AGENTS.md`](vendor/master-builder/AGENTS.md) (section
"Design system": color tokens, typography type scale, layout, focus rings,
logos, WCAG rules). The machine-readable token definitions live in the
`design-guide` repo's `content/*.toml`. Do not duplicate the token tables here —
read them from master-builder so this app cannot drift from the others.

Quick rules that always apply in this repo:

- Use semantic token classes from `elm-app/main.css` (`bg-brand`, `text-brand`,
  `bg-brand-yellow`, …) — never hard-code hex values.
- Canonical brand yellow is **`#FAC80A`**. Do not use `#F2CD37` (legacy incorrect value).
- Use named type classes (`.type-h1`, `.type-body`, …), never ad-hoc `text-xl font-bold`.
- Logos: `<picture>` with **SVG `<source>` first**, then WebP, then `<img>` PNG fallback.
- service-map generates no static HTML (`statics/` writes only feeds and GeoJSON);
  the SPA gets the Outfit font through `elm-app/main.css`, which imports
  `vendor/master-builder/public/fonts/outfit.css`, and the site-config Vite plugin
  serves `/fonts/*` from `vendor/master-builder/public/fonts/`. Use the self-hosted
  logo paths (`/logo/horizontal-full.png`, etc.). Never add font files or an
  `@font-face` to this repo — **never** load assets from
  `logo.palikkaharrastajat.fi` at runtime.

### Rules for AI agents

1. **Never hard-code hex colours** in Elm views or Haskell HTML generators. Use the Tailwind semantic class names (`bg-brand`, `text-brand`, `bg-brand-yellow`, `border-border-default`, etc.) or the `@theme` CSS variables.
2. **Use named type classes** (`.type-h1`, `.type-h2`, `.type-h3`, `.type-h4`, `.type-body`, `.type-body-small`, `.type-caption`, `.type-mono`, `.type-overline`) rather than ad-hoc `text-xl font-bold` combinations.
3. When adding logos to any page, use the `<picture>` pattern with sources in this exact order: **SVG `<source>` first**, then WebP `<source>`, then `<img>` PNG fallback.
4. The Outfit font comes from the hub (`vendor/master-builder/public/fonts/`, imported by `elm-app/main.css` and served as `/fonts/*` by the site-config Vite plugin). Generated static HTML links `/fonts/outfit.css`; never add font files or an `@font-face` to this repo, and do not load the font from `logo.palikkaharrastajat.fi`.
5. Check contrast before picking any colour pair against the WCAG rules in [`vendor/master-builder/AGENTS.md`](vendor/master-builder/AGENTS.md).
6. The canonical brand yellow is **`#FAC80A`** — do not use `#F2CD37`.

## Security Considerations

- The backend is PocketBase at `https://data.palikkaharrastajat.fi`. Ensure PocketBase collection rules are correctly configured to prevent unauthorized reads/writes.
- Authentication is OAuth2/OIDC via PocketBase popup sign-in.
- When modifying auth or data-access logic, run `make test` and manually verify the E2E checklist above.

## Configuration and translations

- `config.toml` is the single source of the site URL, title, description, languages and `[app]` settings (see `vendor/master-builder/docs/site-config.md`). After editing it run `make site-config` and commit the regenerated `elm-app/tests/SiteFixture.elm` and `statics/src/SiteConfig.hs`; `make site-config-check` fails in CI otherwise.
- No display text in views, `main.js` or the Haskell generators: put it in `elm-app/src/I18n.elm` (Finnish and English) or in `config.toml`. `make site-config-check` flags Finnish text elsewhere.
- English is a hidden language (`[i18n] hidden = ["en"]`): it is not offered to visitors, but keep the `[*.en]` tables in `config.toml` and the English text in `I18n.elm` up to date, because they are still generated and tested.
- Page chrome comes from the hub's `Component.Layout`; do not assemble header, drawer or footer here.
