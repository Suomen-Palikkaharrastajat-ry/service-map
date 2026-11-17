module Route exposing (MapSelection(..), Route(..), parseUrl, toHref)

{-| Application hash-based routing definitions and URL parser/generator.
-}

import Url exposing (Url)
import Url.Parser exposing ((</>), (<?>), Parser)
import Url.Parser.Query as Query


type MapSelection
    = SelectLocation String
    | SelectEvent String


type Route
    = RouteMap (Maybe MapSelection)
    | RouteLocations
    | RouteLocationNew
    | RouteLocationDetail String
    | RouteLocationEdit String
    | RouteNotFound


mapQueryParser : Query.Parser (Maybe MapSelection)
mapQueryParser =
    Query.map2
        (\loc ev ->
            case ( loc, ev ) of
                ( Just l, _ ) ->
                    Just (SelectLocation l)

                ( Nothing, Just e ) ->
                    Just (SelectEvent e)

                ( Nothing, Nothing ) ->
                    Nothing
        )
        (Query.string "location")
        (Query.string "event")


routeParser : Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map RouteMap
            (Url.Parser.top <?> mapQueryParser)
        , Url.Parser.map (\id -> RouteMap (Just (SelectEvent id)))
            (Url.Parser.s "events" </> Url.Parser.string)
        , Url.Parser.map RouteLocationNew
            (Url.Parser.s "locations" </> Url.Parser.s "new")
        , Url.Parser.map RouteLocationEdit
            (Url.Parser.s "locations" </> Url.Parser.string </> Url.Parser.s "edit")
        , Url.Parser.map RouteLocationDetail
            (Url.Parser.s "locations" </> Url.Parser.string)
        , Url.Parser.map RouteLocations
            (Url.Parser.s "locations")
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

        ( rawPath, query ) =
            case String.split "?" fragment of
                p :: q :: _ ->
                    ( p, Just q )

                p :: _ ->
                    ( p, Nothing )

                [] ->
                    ( "/", Nothing )

        path =
            if rawPath == "" then
                "/"

            else
                rawPath

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
                RouteMap maybeSelection ->
                    case maybeSelection of
                        Just (SelectLocation id) ->
                            "/?location=" ++ id

                        Just (SelectEvent id) ->
                            "/?event=" ++ id

                        Nothing ->
                            "/"

                RouteLocations ->
                    "/locations"

                RouteLocationNew ->
                    "/locations/new"

                RouteLocationEdit id ->
                    "/locations/" ++ id ++ "/edit"

                RouteLocationDetail id ->
                    "/locations/" ++ id

                RouteNotFound ->
                    "/404"
           )
