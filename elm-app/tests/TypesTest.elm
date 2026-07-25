module TypesTest exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Types exposing (GeoPoint, hasValidCoordinates)


suite : Test
suite =
    describe "Types"
        [ describe "hasValidCoordinates"
            [ test "valid coordinates return True" <|
                \_ ->
                    hasValidCoordinates { lat = 60.1699, lon = 24.9384 }
                        |> Expect.equal True
            , test "zero coordinates return False" <|
                \_ ->
                    hasValidCoordinates { lat = 0, lon = 0 }
                        |> Expect.equal False
            ]
        , describe "locationStateToString and locationStateFromString"
            [ test "Draft round-trip" <|
                \_ ->
                    Types.Draft |> Types.locationStateToString |> Types.locationStateFromString |> Expect.equal (Just Types.Draft)
            , test "Pending round-trip" <|
                \_ ->
                    Types.Pending |> Types.locationStateToString |> Types.locationStateFromString |> Expect.equal (Just Types.Pending)
            , test "Published round-trip" <|
                \_ ->
                    Types.Published |> Types.locationStateToString |> Types.locationStateFromString |> Expect.equal (Just Types.Published)
            , test "Deleted round-trip" <|
                \_ ->
                    Types.Deleted |> Types.locationStateToString |> Types.locationStateFromString |> Expect.equal (Just Types.Deleted)
            , test "unknown string falls back to Draft" <|
                \_ ->
                    Types.locationStateFromString "nonsense" |> Expect.equal Nothing
            ]
        ]
