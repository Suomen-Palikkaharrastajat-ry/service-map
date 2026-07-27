# Basemap Generation (PMTiles)

This repository generates a self-hosted vector basemap (PMTiles) from open
Finnish (MML / Maanmittauslaitos) and world (Natural Earth) geodata, instead
of relying on external tile providers.

## How it works

- **`scripts/generate-basemap.sh`**: Downloads MML Maastokartta 1:250k
  shapefiles (administrative areas, water, roads, urban areas, borders,
  place names) and Natural Earth Admin 0 world countries, merges and
  reprojects them to EPSG:4326, and converts them with `tippecanoe` into a
  single `.mbtiles` archive, then to PMTiles format via the `pmtiles` CLI.
  It also generates a matching MapLibre `style.json`.
- **Output** (`dist/`, gitignored, produced by `make basemap`):
  - `basemap.pmtiles` — the vector tile archive
  - `style.json` — the MapLibre style definition referencing it
  - `world_countries.geojson` — world country outlines used as a
    background layer
- **Caching**: intermediate downloads and merged GeoJSON live under
  `.cache/basemap/` so re-runs don't re-download or re-merge unchanged
  source data.

## Consuming the output

Downstream projects (e.g. `service-map`) either run `make basemap`
themselves during their build, or fetch the pre-built files published by
this repository's `basemap` GitHub Actions workflow (see
[`.github/workflows/basemap.yml`](../.github/workflows/basemap.yml)),
which publishes `dist/*` as assets on a rolling `latest` release whenever
`scripts/generate-basemap.sh` changes on `main`.
