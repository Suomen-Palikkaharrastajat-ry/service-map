module Route exposing (Route(..), parseUrl, toHref)

import Url exposing (Url)
import Url.Parser exposing ((</>), (<?>), Parser)
import Url.Parser.Query as Query


type Route
    = RouteMap
    | RouteLocations
    | RouteLocationNew
    | RouteLocationDetail String
    | RouteLocationEdit String
    | RouteAuthCallback
    | RouteNotFound


routeParser : Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map RouteMap
            Url.Parser.top
        , Url.Parser.map RouteLocationNew
            (Url.Parser.s "locations" </> Url.Parser.s "new")
        , Url.Parser.map RouteLocationEdit
            (Url.Parser.s "locations" </> Url.Parser.string </> Url.Parser.s "edit")
        , Url.Parser.map RouteLocationDetail
            (Url.Parser.s "locations" </> Url.Parser.string)
        , Url.Parser.map RouteLocations
            (Url.Parser.s "locations")
        , Url.Parser.map RouteAuthCallback
            (Url.Parser.s "callback")
        ]


{-| Parse an Elm Browser.application URL into a Route.

The app uses hash routing: the URL fragment is the "path" the app cares about.
Example: <https://example.com/#/locations>

-}
parseUrl : Url -> Route
parseUrl url =
    let
        fragment =
            Maybe.withDefault "/" url.fragment

        ( path, query ) =
            case String.split "?" fragment of
                p :: q :: _ ->
                    ( p, Just q )

                p :: _ ->
                    ( p, Nothing )

                [] ->
                    ( "/", Nothing )

        pseudoUrl =
            { url | path = path, fragment = Nothing, query = query }
    in
    pseudoUrl
        |> Url.Parser.parse routeParser
        |> Maybe.withDefault RouteNotFound


{-| Convert a Route to a hash-based href string (e.g. "#/locations").
-}
toHref : Route -> String
toHref route =
    "#"
        ++ (case route of
                RouteMap ->
                    "/"

                RouteLocations ->
                    "/locations"

                RouteLocationNew ->
                    "/locations/new"

                RouteLocationEdit id ->
                    "/locations/" ++ id ++ "/edit"

                RouteLocationDetail id ->
                    "/locations/" ++ id

                RouteAuthCallback ->
                    "/callback"

                RouteNotFound ->
                    "/404"
           )
