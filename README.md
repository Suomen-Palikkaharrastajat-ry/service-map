# Basemap (Palikkakartta tiles)

Self-hosted PMTiles vector basemap generator for Suomen Palikkaharrastajat
ry's [Palikkakartta (Service Map)](https://github.com/Suomen-Palikkaharrastajat-ry/service-map),
extracted from that repository.

Rather than depending on an external tile provider, this generates its own
vector basemap from open Finnish (MML / Maanmittauslaitos) and world
(Natural Earth) geodata.

## Development Environment

This project uses `devenv` (Nix) to provide `tippecanoe`, `gdal`, and
`python3`.

```sh
make shell
```

## Common Commands

| Command | What it does |
|---|---|
| `make shell` | Open the development shell |
| `make basemap` | Generate the PMTiles basemap into `dist/` |
| `make clean` | Remove generated output (`dist/`) |
| `make clean-cache` | Remove the downloaded source data cache (`.cache/`) |

## Project Structure

```text
scripts/generate-basemap.sh   Downloads MML/Natural Earth data and builds the basemap
dist/                         Generated output (gitignored): basemap.pmtiles, style.json, world_countries.geojson
.cache/                       Downloaded/merged source data cache (gitignored)
.github/workflows             CI: validation + publishing generated tiles
docs/basemap.md               How the basemap is generated and consumed
```

See [`docs/basemap.md`](docs/basemap.md) for details.

## CI and Publishing

GitHub Actions ([`.github/workflows/basemap.yml`](.github/workflows/basemap.yml))
validates `scripts/generate-basemap.sh` (shellcheck + a full generation run)
on every push and pull request, and on `main` publishes the generated
`dist/basemap.pmtiles`, `dist/style.json`, and `dist/world_countries.geojson`
as assets on a rolling `latest` GitHub release, so downstream projects can
fetch pre-built tiles instead of regenerating them.

Human-facing usage lives here in `README.md`. Agent-specific development
instructions live in [`AGENTS.md`](AGENTS.md).
