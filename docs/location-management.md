# Location Management (CRUD)

The application provides a comprehensive suite of tools for location administrators to create, read, update, and delete (CRUD) locations. The location data is securely stored and managed using PocketBase as the backend REST API.

## Features
- **Location Creation**: A detailed form for entering location metadata (title, description, dates, location, coordinates).
- **Location Updates**: Modifying existing location details, including support for multipart form submissions when uploading new location images. 
- **Location Deletion**: Removing locations from the system with confirmation dialogues.
- **Data Synchronization**: Asynchronous API communication handling loading states via the `RemoteData` pattern.

## Related Code Locations
- **`elm-app/src/Api.elm`**: Handles all HTTP requests to the PocketBase backend, including fetching location lists, single locations, and submitting mutations.
- **`elm-app/src/Page/LocationEdit.elm`**: The primary Elm module handling the logic for both creating new locations and editing existing ones.
- **`elm-app/src/Page/LocationDetail.elm`**: The view for reading the details of an individual location.
- **`elm-app/src/View/LocationForm.elm`**: The shared form view component used for data entry.
- **`statics/src/PocketBase.hs`**: The backend Haskell equivalent for fetching live location records to be used in static generation.
