# AGENTS.md

This file provides instructions for AI coding agents working on this
project.

## Project Overview

This repository generates a self-hosted PMTiles vector basemap from open
Finnish (MML / Maanmittauslaitos) and world (Natural Earth) geodata, for use
by [Palikkakartta (service-map)](https://github.com/Suomen-Palikkaharrastajat-ry/service-map)
and any other project that wants a self-hosted basemap instead of an
external tile provider.

There is no application code here — just the generation script, its
supporting Nix dev environment, and the CI automation that validates and
publishes the output.

## Repository Layout

```
scripts/generate-basemap.sh   Downloads MML/Natural Earth data and builds the basemap
dist/                         Generated output (gitignored, not committed)
.cache/                       Downloaded/merged source data cache (gitignored)
docs/basemap.md               How generation and publishing works
.github/workflows/basemap.yml CI: shellcheck, generation, artifact upload, release publish
```

## Development Environment

The project uses **devenv** (Nix). Always run commands inside the devenv
shell:

```sh
make shell
```

## Build and Test Commands

| Command | Description |
|---|---|
| `make basemap` | Generate `dist/basemap.pmtiles`, `dist/style.json`, `dist/world_countries.geojson` |
| `make clean` | Remove `dist/` |
| `make clean-cache` | Remove `.cache/` (forces a full re-download on next `make basemap`) |

## Architecture Notes

- `scripts/generate-basemap.sh` downloads MML Maastokartta 1:250k shapefiles
  grid-by-grid, merges each layer (administrative areas, water, roads, urban
  areas, borders, place names) with `ogrmerge.py`, reprojects EPSG:3067 →
  EPSG:4326, and adds a per-feature `minzoom` to place names based on
  `scalerelev`. It then fetches Natural Earth Admin 0 world countries,
  builds an `.mbtiles` archive with `tippecanoe`, converts it to PMTiles,
  and writes a matching MapLibre `style.json`.
- Intermediate downloads/merges are cached under `.cache/basemap/` so
  re-runs are incremental.
- CI (`.github/workflows/basemap.yml`) caches `.cache/basemap` keyed by the
  hash of `generate-basemap.sh`, so it only re-downloads/re-merges source
  data when the script itself changes.

## Known Gotchas

- MML's `kartat.kapsi.fi` mirror and Natural Earth's CDN are both external
  and can be slow or rate-limit; the `.cache/basemap/` cache exists
  specifically to avoid re-hitting them on every run.
- `ogrmerge.py`/`ogr2ogr` come from `gdal`; `tippecanoe` and the `pmtiles`
  CLI binary (downloaded by the script itself) do the tile conversion.
- Keep `dist/` and `.cache/` out of version control — they are large,
  regenerable, gitignored, and published as release assets instead.

## Security Considerations

No secrets or authenticated services are involved. The `basemap` workflow
needs `contents: write` permission (already granted) to publish the
`latest` GitHub release.
