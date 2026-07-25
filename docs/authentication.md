# Authentication

Authentication in the Service Map is handled via OAuth2/OIDC, delegating identity management to PocketBase. This ensures that only authorized administrators can access the location management features.

## Features
- **OAuth2 Login Flow**: Users authenticate through a popup flow that redirects them securely.
- **Protected Routes**: Certain Elm SPA routes (like `/#/locations/new` or `/#/locations/:id/edit`) require a valid authentication token. If unauthenticated, the user is redirected to the map view with an info toast.
- **Session Persistence**: Authentication state is stored and restored upon app initialization.

## Related Code Locations
- **`elm-app/src/Auth.elm`**: Core module containing OAuth initialization, token management, and authentication state logic.
- **`elm-app/src/Main.elm`**: Initializes authentication from flags and manages top-level auth state transitions.
- **`elm-app/src/Route.elm`**: Identifies which routes require authentication.
- **`elm-app/src/Ports.elm`**: Used to potentially interact with browser APIs for OAuth popup management or localStorage session persistence.
