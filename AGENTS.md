# AGENTS.md

This file provides instructions for AI coding agents working on this project.

## Project Overview

**Palikkakartta**: Built with an **Elm 0.19 SPA** (frontend) and a **Haskell static generator** (feeds + GeoJSON), backed by **PocketBase**.

The backend is hosted at `https://data.palikkaharrastajat.fi`. The `locations` collection backend is shared with `event-calendar`.

There is **no TypeScript, no Svelte, no ESLint, no Prettier, and no pnpm** in the current codebase.

## Repository Layout

```
elm-app/          Elm 0.19 SPA (Vite + vite-plugin-elm + Tailwind CSS 4)
  src/            Elm source modules (Auth, Page/*, View/*, etc.)
  tests/          Elm unit tests
  public/         Static assets
  packages/       Symlink to shared Elm packages in vendor/master-builder
statics/          Haskell static generator
  src/            Library modules
  app/            Executable entry point
  tests/          Haskell tests
static/           Files copied verbatim into build/
fixtures/         Test data fixtures
pkgs/             Nix-managed npm packages
scripts/          Scripts (e.g., generate-basemap.sh)
vendor/master-builder  Submodule for shared Elm packages
build/            Generated production output (not committed)
.github/workflows CI/CD
```

## Development Environment

The project uses **devenv** (Nix). Always run commands inside the devenv shell, either with `make shell` (interactive) or prefixed with `devenv shell --`.

**Bootstrap (first time):**
```sh
make develop   # creates devenv.local.nix + devenv.local.yaml, opens VS Code
```

**Enter the shell interactively:**
```sh
make shell
```

### npm / node_modules

All npm packages are managed by the Nix derivation in `pkgs/npm-tools.nix`. There is no `package.json` in the project root or in `elm-app/`.
When `devenv shell` starts, `enterShell` symlinks each package into `elm-app/node_modules/*`.

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
| `make elm-build` | Production build of Elm SPA → `build/` |
| `make elm-test` | Run Elm unit tests |
| `make elm-check` | Validate Elm formatting (elm-format --validate) |
| `make elm-format` | Auto-format Elm source files |
| `make statics-build` | Build Haskell static generator |
| `make statics` | Run generator (writes static files to `static/`; `make dist` copies them to `build/`) |
| `make statics-test` | Run Haskell unit tests |
| `make statics-check` | Lint Haskell source (hlint) |
| `make statics-format` | Auto-format Haskell source (fourmolu) |
| `make test` | Run all tests (Elm + Haskell) |
| `make dist` | Full production build: Elm SPA + static files |
| `make format` | Auto-format all source files |
| `make check` | Validate all formatting without changes |
| `make clean` | Remove `build/` |
| `make basemap` | Run MapLibre/PMTiles basemap generator |
| `make elm-tailwind-gen` | Run Tailwind generation for Elm |
| `make watch` | Run watch mode for development |

**First-time Haskell setup** — run `cabal update` before the first `cabal build statics` in a fresh environment.

## Architecture Notes

### Elm SPA
- `Browser.application` with hash routing: `/#/`, `/#/locations`, `/#/locations/new`, `/#/locations/:id`, `/#/locations/:id/edit`, `/#/callback`
- MapLibre GL + PMTiles basemap generated from MML open data (`scripts/generate-basemap.sh`, cached artifacts, `elm-app/public/style.json`).
- Ports surface: `initMap`, `addMarkers`, `markerClicked`, `setMapMarker`, `mapMarkerMoved`, `destroyMap`, OAuth ports, `parseKml`/`kmlParsed`, `getCallbackParams`/`callbackParams`.
- OAuth popup + redirect-callback flow.
- Uses `RemoteData` for async state.
- Uses the opening-hours editor from the vendored `osm-opening-hours` package.

### Haskell Static Generator
- Fetches data and outputs feeds: `kartta.rss`, `kartta.atom`, `kartta.json`, `kartta.geo.json`, plus `images/`.
- Uses `POCKETBASE_URL` env variable.

## Known Gotchas

- **Submodule gitlink required** (refer to TODO-01 history).
- **`mapMarkerMoved` must stay subscribed**.
- **(0,0) coordinates must be filtered** out.
- **Basemap caching in CI** is important for build performance.
- **node_modules symlinks are read-only Nix store** — never `npm install` inside `elm-app/`.
- **GHC pinned to 9.6**.
- Run `cabal update` before the first `cabal build`.

## Manual E2E Test Checklist

- [ ] Map renders markers (published only, signed-out)
- [ ] Detail panel shows correctly when clicking a marker
- [ ] Locations list view renders correctly
- [ ] CRUD flow works (create, edit, delete) with appropriate toasts
- [ ] Delete flow redirects appropriately
- [ ] KML import parses correctly
- [ ] Mobile responsive layout works on 375 px viewport
- [ ] Keyboard navigation is usable
- [ ] `build/kartta.rss` and `build/kartta.atom` validate
- [ ] `build/kartta.geo.json` is a valid GeoJSON

## Style Guide

The association's official design guide lives at **<https://logo.palikkaharrastajat.fi/>**.

**Agent CSS reference:** Fetch `https://logo.palikkaharrastajat.fi/brand.css` for the canonical `@theme`, `@utility type-*`, `@font-face`, reduced-motion rule, and shared component classes. Copy into `elm-app/main.css`.

### Key design tokens

Use semantic token classes from `elm-app/main.css` — never hard-code hex values.

| Token | Value | Tailwind class |
|---|---|---|
| `--color-brand` | `#05131D` | `bg-brand` / `text-brand` / `border-brand` |
| `--color-brand-yellow` | `#FAC80A` | `bg-brand-yellow` / `bg-bg-accent` |
| `--color-brand-red` | `#C91A09` | `bg-brand-red` / `text-brand-red` (danger/error only) |
| `--color-text-primary` | `#05131D` | `text-text-primary` |
| `--color-text-on-dark` | `#FFFFFF` | `text-text-on-dark` |
| `--color-text-muted` | `#6B7280` | `text-text-muted` |
| `--color-text-subtle` | `#9CA3AF` | `text-text-subtle` |
| `--color-bg-page` | `#FFFFFF` | `bg-bg-page` |
| `--color-bg-subtle` | `#F9FAFB` | `bg-bg-subtle` |
| `--color-bg-dark` | `#05131D` | `bg-bg-dark` |
| `--color-border-default` | `#E5E7EB` | `border-border-default` |
| `--color-border-brand` | `#05131D` | `border-border-brand` |

> **Note:** The canonical yellow value is `#FAC80A`. Do not use `#F2CD37`.

### Typography

- **Font**: Outfit variable font (wght axis 100–900), `font-family: 'Outfit', system-ui, sans-serif`. Self-hosted from `elm-app/public/fonts/`.
- **Named type scale** (use CSS classes, never raw sizes in components):

| Class | Size | Weight | Notes |
|---|---|---|---|
| `.type-display` | 3rem | 700 | Hero headlines only |
| `.type-h1` | 1.875rem | 700 | One per page |
| `.type-h2` | 1.5rem | 700 | Section headings |
| `.type-h3` | 1.25rem | 600 | Sub-section headings |
| `.type-h4` | 1.125rem | 600 | Card / widget headings |
| `.type-body` | 1rem | 400 | Default body copy |
| `.type-body-small` | 0.875rem | 500 | UI controls, labels |
| `.type-caption` | 0.875rem | 400 | Metadata, footnotes |
| `.type-mono` | 0.875rem | 400 | Code snippets (monospace) |
| `.type-overline` | 0.75rem | 600 uppercase | Category labels |

### Logos & favicons

- Always use SVG first; provide WebP `<source>` with PNG `<img>` fallback via `<picture>`.
  - Correct `<picture>` source order: **SVG `<source>` first**, then WebP `<source>`, then `<img>` PNG fallback.
- Variants: **square** (avatars, app icons), **horizontal** (header — `horizontal-full.svg` light, `horizontal-full-dark.svg` dark).
- Minimum clear space: 25% of logo width on all sides. Minimum digital width: 80 px (square), 200 px (horizontal).
- Favicon set lives at `https://logo.palikkaharrastajat.fi/favicon/` — download all sizes to `elm-app/public/`.
- **Never** stretch, recolour, shadow, or outline the logo.
- **Never** display animated logo variants (`*-animated.webp/gif`) when `prefers-reduced-motion: reduce` is active.

### WCAG / accessibility rules

- All colour pairings must pass WCAG 2.1 AA (≥ 4.5:1 normal text, ≥ 3:1 large text / UI).
- `bg-brand-yellow` (`#FAC80A`) **fails on white** (1.58:1). Always pair it with `text-brand` (`#05131D`) which passes AAA (10.83:1).
- `text-brand` (`#05131D`) on white passes AAA (18.79:1). `text-white` on `bg-brand` also passes AAA.
- Brand red (`#C91A09`) on white passes AA (5.78:1); do not use on dark backgrounds without re-checking.
- Avoid `text-gray-400` for body or label text — its contrast on white (~2.85:1) fails AA. Use `text-gray-500` (4.6:1) as the minimum for muted text.
- Max content width is **1024 px** (`max-w-5xl` in Tailwind). Do not use `max-w-4xl` (896 px) for full-page containers.

### Rules for AI agents

1. **Never hard-code hex colours** in Elm views or Haskell HTML generators. Use the Tailwind semantic class names (`bg-brand`, `text-brand`, `bg-brand-yellow`, `border-border-default`, etc.) or the `@theme` CSS variables.
2. **Use named type classes** (`.type-h1`, `.type-h2`, `.type-h3`, `.type-h4`, `.type-body`, `.type-body-small`, `.type-caption`, `.type-mono`, `.type-overline`) rather than ad-hoc `text-xl font-bold` combinations.
3. When adding logos to any page, use the `<picture>` pattern with sources in this exact order: **SVG `<source>` first**, then WebP `<source>`, then `<img>` PNG fallback.
4. Always embed `@font-face` for Outfit pointing to the **self-hosted** TTF (`/fonts/Outfit-VariableFont_wght.ttf`).
5. Check contrast before picking any colour pair. Refer to the `wcag` fields in `colors.jsonld` or the table above.
6. The canonical brand yellow is **`#FAC80A`** — do not use `#F2CD37`.

## Security Considerations

- The backend is PocketBase at `https://data.palikkaharrastajat.fi`. Ensure PocketBase collection rules are correctly configured to prevent unauthorized reads/writes.
- Authentication is OAuth2/OIDC via PocketBase.
- When modifying auth or data-access logic, run `make test` and manually verify the E2E checklist above.
