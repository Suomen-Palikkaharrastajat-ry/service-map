# Map & Geocoding

Locations frequently require precise location data. The application integrates mapping and geocoding services to allow administrators to visualize and accurately set location coordinates.

## Features
- **Map Visualization**: Renders interactive maps using MapLibre GL to display location locations.
- **Geocoding**: Converts human-readable addresses into geographic coordinates (latitude and longitude) using the Nominatim API.
- **Elm-JS Interop**: Since MapLibre GL is a JavaScript library, the Elm application communicates with it securely via ports.

## Related Code Locations
- **`elm-app/src/Geocoding.elm`**: Handles HTTP requests to the Nominatim geocoding service and parses the resulting coordinate data.
- **`elm-app/src/Ports.elm`**: Defines the Elm ports used to send commands to MapLibre GL (e.g., initializing a map, adding markers, or listening for map clicks).
- **`elm-app/src/View/MapWidget.elm`**: The Elm view module that renders the container for the MapLibre map and manages its local state.
- **`elm-app/main.js`**: The JavaScript side of those ports — creates the maps, and builds the marker icons as inline SVG in `getMarkerIconHtml`.


## Basemap (external tiles service)
The vector basemap is built and hosted by the separate
[`service-map-tiles`](https://github.com/Suomen-Palikkaharrastajat-ry/service-map-tiles)
project, which publishes regional PMTiles archives (world borders, Nordic +
Baltic OSM detail, Finland from MML) and a matching MapLibre `style.json` at
<https://tiles.palikkaharrastajat.fi/>. This repository no longer generates or
hosts any tiles, glyphs, or GeoJSON — it just points MapLibre at that style.

- **`VITE_BASEMAP_STYLE_URL`** (in `elm-app/main.js`): the style URL loaded for
  the `basemap` map style. Defaults to the production tiles service
  (`https://tiles.palikkaharrastajat.fi/style.json`); override it to point at a
  staging tiles deployment or a locally served copy.
- The style references its PMTiles archives and glyphs with absolute URLs, so
  the app only registers the `pmtiles://` protocol (see `ensureMapLibs` in
  `main.js`) and loads the style — nothing else is needed.
- The `finland-hd` archive adds detailed data up to z13 within Finland, allowing `main.js` to cap the basemap at `maxZoom = 17`. Outside Finland, `nordic-baltic` (z11) is overzoomed.
- The precise location-picker in the create/edit forms still uses an inline
  OpenStreetMap **raster** style (`osm`) for street-level zoom; that is
  unrelated to the vector basemap above.

### Attribution
Data credits are displayed by maplibre-gl's built-in `AttributionControl`,
configured `{ compact: true }` in `main.js` so it collapses to an ⓘ button on
small viewports. The credits themselves are not hard-coded here — they come from
each style source's `attribution` field: the vector basemap's baked-in
`© Maanmittauslaitos`, `© OpenMapTiles © OpenStreetMap contributors` and
`Natural Earth` (from the remote `style.json`), and the raster `osm` picker
style's own `© OpenStreetMap Contributors`. Licenses for the underlying data and
glyph fonts live in the `service-map-tiles` repo (`NOTICE.md` + `licenses/`).
