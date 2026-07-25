# Map & Geocoding

Locations frequently require precise location data. The application integrates mapping and geocoding services to allow administrators to visualize and accurately set location coordinates.

## Features
- **Map Visualization**: Renders interactive maps using Leaflet.js to display location locations.
- **Geocoding**: Converts human-readable addresses into geographic coordinates (latitude and longitude) using the Nominatim API.
- **Elm-JS Interop**: Since Leaflet is a JavaScript library, the Elm application communicates with it securely via ports.

## Related Code Locations
- **`elm-app/src/Geocoding.elm`**: Handles HTTP requests to the Nominatim geocoding service and parses the resulting coordinate data.
- **`elm-app/src/Ports.elm`**: Defines the Elm ports used to send commands to Leaflet (e.g., initializing a map, adding markers, or listening for map clicks).
- **`elm-app/src/View/MapWidget.elm`**: The Elm view module that renders the container for the Leaflet map and manages its local state.
- **`elm-app/public/`**: Stores the static Leaflet marker icons needed for rendering.


## Basemap Generation (PMTiles)
Unlike standard web maps that rely on external tile providers, Palikkakartta generates its own self-hosted vector tiles (PMTiles) from open MML (Maanmittauslaitos) data.

- **`scripts/generate-basemap.sh`**: Downloads shapefiles, filters features (water, roads, buildings, labels), and converts them using `tippecanoe`.
- **`style.json`**: The custom MapLibre style definition to render the self-hosted basemap.
- **Caching**: CI caches the `.pmtiles` archive to avoid re-generating large shapefiles unnecessarily.
