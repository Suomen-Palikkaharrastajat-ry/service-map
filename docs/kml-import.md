# KML Import

To facilitate bulk location creation, administrators can upload Keyhole Markup Language (KML) files containing multiple placemarks. The application parses this geographic data and translates it into discrete location records.

## Features
- **File Upload**: A drag-and-drop or file selection interface for importing `.kml` files.
- **XML Parsing**: Extracts title, description, and coordinate data from KML placemarks.
- **Batch Processing**: Iterates through the parsed data and automatically provisions new locations in the backend.

## Related Code Locations
- **`elm-app/src/Page/Locations.elm`**: Handles the primary interface and logic for triggering KML file uploads from the location management list.
- **`elm-app/src/Ports.elm`**: Manages the JavaScript interop required to read the uploaded file contents and parse the XML structure before passing it back to Elm.
