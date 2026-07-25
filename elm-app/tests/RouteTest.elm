module RouteTest exposing (suite)

import Expect
import Route exposing (Route(..), parseUrl, toHref)
import Test exposing (Test, describe, test)
import Url


{-| Helper to parse a full URL string via parseUrl.
-}
parse : String -> Route
parse urlStr =
    case Url.fromString ("http://localhost" ++ urlStr) of
        Just url ->
            parseUrl url

        Nothing ->
            RouteNotFound


suite : Test
suite =
    describe "Route"
        [ describe "parseUrl"
            [ test "root → RouteMap" <|
                \_ ->
                    parse "#/"
                        |> Expect.equal RouteMap
            , test "with querystring → RouteMap" <|
                \_ ->
                    parse "#/?foo=bar"
                        |> Expect.equal RouteMap
            , test "/locations → RouteLocations" <|
                \_ ->
                    parse "#/locations"
                        |> Expect.equal RouteLocations
            , test "/locations/new → RouteLocationNew" <|
                \_ ->
                    parse "#/locations/new"
                        |> Expect.equal RouteLocationNew
            , test "/locations/abc123 → RouteLocationDetail" <|
                \_ ->
                    parse "#/locations/abc123"
                        |> Expect.equal (RouteLocationDetail "abc123")
            , test "/locations/abc123/edit → RouteLocationEdit" <|
                \_ ->
                    parse "#/locations/abc123/edit"
                        |> Expect.equal (RouteLocationEdit "abc123")
            , test "/callback → RouteAuthCallback" <|
                \_ ->
                    parse "#/callback"
                        |> Expect.equal RouteAuthCallback
            , test "/nonexistent → RouteNotFound" <|
                \_ ->
                    parse "#/nonexistent/path"
                        |> Expect.equal RouteNotFound
            ]
        , describe "toHref"
            [ test "RouteMap" <|
                \_ -> toHref RouteMap |> Expect.equal "#/"
            , test "RouteLocations" <|
                \_ -> toHref RouteLocations |> Expect.equal "#/locations"
            , test "RouteLocationNew" <|
                \_ -> toHref RouteLocationNew |> Expect.equal "#/locations/new"
            , test "RouteLocationDetail" <|
                \_ -> toHref (RouteLocationDetail "abc") |> Expect.equal "#/locations/abc"
            , test "RouteLocationEdit" <|
                \_ -> toHref (RouteLocationEdit "abc") |> Expect.equal "#/locations/abc/edit"
            ]
        ]
