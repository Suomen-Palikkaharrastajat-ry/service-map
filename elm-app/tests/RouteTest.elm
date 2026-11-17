module RouteTest exposing (suite)

{-| Test suite for application routing and URL parsing.
-}

import Expect
import Route exposing (MapSelection(..), Route(..), parseUrl, toHref)
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
            [ test "root → RouteMap Nothing" <|
                \_ ->
                    parse "#/"
                        |> Expect.equal (RouteMap Nothing)
            , test "with querystring → RouteMap Nothing" <|
                \_ ->
                    parse "#/?foo=bar"
                        |> Expect.equal (RouteMap Nothing)
            , test "/#/?event=123 → RouteMap (Just (SelectEvent 123))" <|
                \_ ->
                    parse "#/?event=123"
                        |> Expect.equal (RouteMap (Just (SelectEvent "123")))
            , test "/#/?location=456 → RouteMap (Just (SelectLocation 456))" <|
                \_ ->
                    parse "#/?location=456"
                        |> Expect.equal (RouteMap (Just (SelectLocation "456")))
            , test "/events/123 → RouteMap (Just (SelectEvent 123))" <|
                \_ ->
                    parse "#/events/123"
                        |> Expect.equal (RouteMap (Just (SelectEvent "123")))
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
            , test "/callback → RouteNotFound (legacy OAuth redirect)" <|
                \_ ->
                    parse "#/callback"
                        |> Expect.equal RouteNotFound
            , test "/nonexistent → RouteNotFound" <|
                \_ ->
                    parse "#/nonexistent/path"
                        |> Expect.equal RouteNotFound
            ]
        , describe "toHref"
            [ test "RouteMap Nothing" <|
                \_ -> toHref (RouteMap Nothing) |> Expect.equal "#/"
            , test "RouteMap (SelectEvent)" <|
                \_ -> toHref (RouteMap (Just (SelectEvent "123"))) |> Expect.equal "#/?event=123"
            , test "RouteMap (SelectLocation)" <|
                \_ -> toHref (RouteMap (Just (SelectLocation "456"))) |> Expect.equal "#/?location=456"
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
