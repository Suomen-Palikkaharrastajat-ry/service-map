module KmlImportTest exposing (suite)

import Expect
import Json.Decode as Decode
import Test exposing (..)
import Types exposing (KmlPlacemark)


suite : Test
suite =
    describe "KML decoder"
        [ test "decodes full placemark" <|
            \_ ->
                let
                    json =
                        """
                        {
                            "name": "Test Location",
                            "description": "A description",
                            "lat": 60.1699,
                            "lon": 24.9384,
                            "dateStr": null
                        }
                        """
                in
                Decode.decodeString Types.decodeKmlPlacemark json
                    |> Expect.equal
                        (Ok
                            { name = "Test Location"
                            , description = "A description"
                            , lat = Just 60.1699
                            , lon = Just 24.9384
                            , dateStr = Nothing
                            }
                        )
        , test "decodes placemark without coords" <|
            \_ ->
                let
                    json =
                        """
                        {
                            "name": "No Coords",
                            "description": "",
                            "lat": null,
                            "lon": null,
                            "dateStr": null
                        }
                        """
                in
                Decode.decodeString Types.decodeKmlPlacemark json
                    |> Expect.equal
                        (Ok
                            { name = "No Coords"
                            , description = ""
                            , lat = Nothing
                            , lon = Nothing
                            , dateStr = Nothing
                            }
                        )
        ]
