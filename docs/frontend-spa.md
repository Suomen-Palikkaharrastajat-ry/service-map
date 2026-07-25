# Frontend SPA

The Service Map frontend is built as a Single Page Application (SPA) using Elm 0.19. It provides an interactive interface for viewing, managing, and browsing locations. 

## Features
- **Routing**: Utilizes hash-based routing to navigate between views such as the main map view, the locations list view, and individual location detail/edit views.
- **Styling**: Styled using Tailwind CSS 4, integrated via Vite and a custom Elm Vite plugin. 
- **Shared Components**: Leverages a vendored component library for consistent UI elements (buttons, modals, forms).

## Related Code Locations
- **`elm-app/src/Main.elm`**: The main entry point of the Elm application, initializing state and handling top-level routing/messages.
- **`elm-app/src/Route.elm`**: Defines the hash-based routes (`/#/map`, `/#/locations`, `/#/locations/:id`, etc.) and the URL parsing logic.
- **`elm-app/src/Types.elm`**: Core Elm types and application state models.
- **`elm-app/src/Page/`**: Contains page-level modules (`Map`, `Locations`, `LocationDetail`, `LocationEdit`).
- **`elm-app/src/View/`**: Reusable view functions and layout wrappers.
- **`elm-app/packages/`**: Symlink to the shared component library containing `Component.*` and `DesignTokens.*`.
