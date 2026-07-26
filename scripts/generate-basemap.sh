#!/usr/bin/env bash
set -e

mkdir -p .cache/basemap/mml_shape_250k

echo "Fetching MML Maastokartta 1:250k (ETRS89) from kapsi.fi..."
GRIDS="K2 K3 K4 L2 L3 L4 L5 M3 M4 M5 N3 N4 N5 N6 P3 P4 P5 P6 Q3 Q4 Q5 R3 R4 R5 S4 S5 T4 T5 U4 U5 V3 V4 V5 W3 W4 W5 X4 X5"

for grid in $GRIDS; do
  zipnames=$(curl -s "https://kartat.kapsi.fi/files/maastokartta_250k/kaikki/etrs89/shp/${grid}/" | grep -oE '"[A-Z0-9]+\.zip"' | tr -d '"' | sort -u)
  for zipname in $zipnames; do
    zipfile=".cache/basemap/${zipname}"
    if [ ! -f "$zipfile" ]; then
      echo "Downloading ${zipname}..."
      curl -sL "https://kartat.kapsi.fi/files/maastokartta_250k/kaikki/etrs89/shp/${grid}/${zipname}" > "$zipfile"
    fi
    unzip -o -q "$zipfile" -d .cache/basemap/mml_shape_250k
  done
done

echo "Merging shapefiles and reprojecting EPSG:3067 to EPSG:4326 (WGS84)..."

merge_layer() {
  local layer_suffix=$1
  local output=$2
  echo "Merging $layer_suffix into $output..."
  rm -f "$output"
  # Use ogrmerge.py to combine all regional files for this layer
  ogrmerge.py -single -f GeoJSON -t_srs EPSG:4326 -o "$output" .cache/basemap/mml_shape_250k/*_${layer_suffix}.shp || true
}

merge_layer "HallintoAlue" ".cache/basemap/hallinto.geojson"
merge_layer "VesiAlue" ".cache/basemap/vesi.geojson"
merge_layer "TieViiva" ".cache/basemap/tie.geojson"
merge_layer "TaajamaAlue" ".cache/basemap/taajama.geojson"
merge_layer "HallintoalueRaja" ".cache/basemap/raja.geojson"
merge_layer "KarttanimiPiste" ".cache/basemap/nimisto_unsorted.geojson"

echo "Sorting KarttanimiPiste by scalerelev..."
if [ -f .cache/basemap/nimisto_unsorted.geojson ]; then
  rm -f .cache/basemap/nimisto.geojson
  ogr2ogr -f GeoJSON -sql "SELECT * FROM merged ORDER BY scalerelev DESC" .cache/basemap/nimisto.geojson .cache/basemap/nimisto_unsorted.geojson
fi

echo "Adding per-feature minzoom from scalerelev..."
if [ -f .cache/basemap/nimisto.geojson ]; then
  python3 -c "
import json

def scalerelev_to_minzoom(sr):
    if not sr: return 11
    if sr >= 8000000: return 3
    if sr >= 4500000: return 5
    if sr >= 2000000: return 6
    if sr >= 1000000: return 7
    if sr >= 500000: return 9
    return 11

with open('.cache/basemap/nimisto.geojson') as f:
    data = json.load(f)
for feat in data['features']:
    sr = feat['properties'].get('scalerelev') or 0
    feat['tippecanoe'] = {'minzoom': scalerelev_to_minzoom(sr)}
with open('.cache/basemap/nimisto.geojson', 'w') as f:
    json.dump(data, f, ensure_ascii=False)
print(f'Added minzoom to {len(data[\"features\"])} features')
"
fi

echo "Fetching Natural Earth Admin 0 for world countries..."
mkdir -p .cache/basemap/ne
if [ ! -f .cache/basemap/ne/ne_50m_admin_0_countries.shp ]; then
  curl -sL "https://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_countries.zip" > .cache/basemap/ne/ne_50m_admin_0_countries.zip
  unzip -o -q .cache/basemap/ne/ne_50m_admin_0_countries.zip -d .cache/basemap/ne/
fi
rm -f .cache/basemap/world_countries.geojson
ogr2ogr -f GeoJSON .cache/basemap/world_countries.geojson .cache/basemap/ne/ne_50m_admin_0_countries.shp

echo "Generating PMTiles with tippecanoe..."
# Find which files successfully generated (some layers might be empty or missing)
GEOJSONS=""
for f in hallinto vesi tie taajama raja nimisto world_countries; do
  if [ -f ".cache/basemap/${f}.geojson" ]; then
    GEOJSONS="$GEOJSONS .cache/basemap/${f}.geojson"
  fi
done

tippecanoe -z11 -o .cache/basemap/basemap.mbtiles --force -r1 --order-descending-by=scalerelev --drop-densest-as-needed --maximum-tile-bytes=2000000 $GEOJSONS

echo "Installing PMTiles CLI..."
if [ ! -f .cache/basemap/pmtiles ]; then
  curl -sL -o .cache/basemap/pmtiles.tar.gz https://github.com/protomaps/go-pmtiles/releases/download/v1.31.2/go-pmtiles_1.31.2_Linux_x86_64.tar.gz
  tar -xzf .cache/basemap/pmtiles.tar.gz -C .cache/basemap
  chmod +x .cache/basemap/pmtiles
fi

echo "Converting to PMTiles format..."
.cache/basemap/pmtiles convert .cache/basemap/basemap.mbtiles elm-app/public/basemap.pmtiles --force

echo "Generating style.json..."
cat << 'EOF' > elm-app/public/style.json
{
  "version": 8,
  "sources": {
    "basemap": {
      "type": "vector",
      "url": "pmtiles:///basemap.pmtiles",
      "attribution": "&copy; Maanmittauslaitos"
    }
  },
  "glyphs": "https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf",
  "layers": [
    {
      "id": "background",
      "type": "background",
      "paint": {
        "background-color": "#a0c8f0"
      }
    },
    {
      "id": "world_countries_fill",
      "type": "fill",
      "source": "basemap",
      "source-layer": "world_countries",
      "paint": {
        "fill-color": "#f0f0f0"
      }
    },
    {
      "id": "world_countries_borders",
      "type": "line",
      "source": "basemap",
      "source-layer": "world_countries",
      "paint": {
        "line-color": "#c0c0c0",
        "line-width": 1.5
      }
    },
    {
      "id": "hallinto",
      "type": "fill",
      "source": "basemap",
      "source-layer": "hallinto",
      "paint": {
        "fill-color": "#d0d0d0"
      }
    },
    {
      "id": "taajama",
      "type": "fill",
      "source": "basemap",
      "source-layer": "taajama",
      "paint": {
        "fill-color": "#e0d8d0"
      }
    },
    {
      "id": "vesi",
      "type": "fill",
      "source": "basemap",
      "source-layer": "vesi",
      "paint": {
        "fill-color": "#a0c8f0"
      }
    },
    {
      "id": "raja",
      "type": "line",
      "source": "basemap",
      "source-layer": "raja",
      "paint": {
        "line-color": "#a0a0a0",
        "line-dasharray": [4, 4],
        "line-width": 1
      }
    },
    {
      "id": "tie",
      "type": "line",
      "source": "basemap",
      "source-layer": "tie",
      "paint": {
        "line-color": "#ffffff",
        "line-width": 1.5
      }
    },
    {
      "id": "place-city",
      "type": "symbol",
      "source": "basemap",
      "source-layer": "nimisto",
      "minzoom": 3,
      "filter": [">=", ["get", "scalerelev"], 4500000],
      "layout": {
        "text-field": ["get", "text"],
        "text-font": ["Open Sans Semibold"],
        "text-size": ["interpolate", ["exponential", 1.2], ["zoom"],
          3, 11,
          11, 18
        ],
        "symbol-sort-key": ["*", -1, ["get", "scalerelev"]]
      },
      "paint": {
        "text-color": "#333333",
        "text-halo-color": "#ffffff",
        "text-halo-width": 1
      }
    },
    {
      "id": "place-town",
      "type": "symbol",
      "source": "basemap",
      "source-layer": "nimisto",
      "minzoom": 6,
      "filter": ["all", [">=", ["get", "scalerelev"], 1000000], ["<", ["get", "scalerelev"], 4500000]],
      "layout": {
        "text-field": ["get", "text"],
        "text-font": ["Open Sans Regular, Arial Unicode MS Regular"],
        "text-size": ["interpolate", ["exponential", 1.2], ["zoom"],
          6, 10,
          11, 14
        ],
        "symbol-sort-key": ["*", -1, ["get", "scalerelev"]]
      },
      "paint": {
        "text-color": "#333333",
        "text-halo-color": "#ffffff",
        "text-halo-width": 1
      }
    },
    {
      "id": "place-village",
      "type": "symbol",
      "source": "basemap",
      "source-layer": "nimisto",
      "minzoom": 9,
      "filter": ["<", ["get", "scalerelev"], 1000000],
      "layout": {
        "text-field": ["get", "text"],
        "text-font": ["Open Sans Regular, Arial Unicode MS Regular"],
        "text-size": ["interpolate", ["exponential", 1.2], ["zoom"],
          9, 10,
          11, 12
        ],
        "symbol-sort-key": ["*", -1, ["get", "scalerelev"]]
      },
      "paint": {
        "text-color": "#666666",
        "text-halo-color": "#ffffff",
        "text-halo-width": 1
      }
    }
  ]
}
EOF

echo "Basemap generated."

