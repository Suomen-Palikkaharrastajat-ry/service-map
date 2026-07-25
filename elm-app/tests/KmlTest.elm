module KmlTest exposing (suite)

import Expect
import Json.Decode as Decode
import Test exposing (Test, describe, test)
import Types exposing (KmlPlacemark, decodeKmlPlacemark)


{-| Decode a JSON string using the given decoder.
-}
decodeJson : Decode.Decoder a -> String -> Result Decode.Error a
decodeJson decoder json =
    Decode.decodeString decoder json


suite : Test
suite =
    describe "Kml"
        [ describe "decodeKmlPlacemark"
            [ test "decodes placemark with coordinates" <|
                \_ ->
                    let
                        json =
                            """{"name":"Prikka","description":"Joku kuvaus","lat":60.123,"lon":24.456,"dateStr":"2026-05-05"}"""

                        expected : KmlPlacemark
                        expected =
                            { name = "Prikka", description = "Joku kuvaus", lat = Just 60.123, lon = Just 24.456, dateStr = Just "2026-05-05" }
                    in
                    decodeJson decodeKmlPlacemark json
                        |> Expect.equal (Ok expected)
            , test "decodes placemark without coordinates" <|
                \_ ->
                    let
                        json =
                            """{"name":"Vain nimi","description":"","dateStr":null}"""

                        expected : KmlPlacemark
                        expected =
                            { name = "Vain nimi", description = "", lat = Nothing, lon = Nothing, dateStr = Nothing }
                    in
                    decodeJson decodeKmlPlacemark json
                        |> Expect.equal (Ok expected)
            , test "decodes placemark with extra fields" <|
                \_ ->
                    let
                        json =
                            """{"name":"A","description":"B","lat":1.0,"lon":2.0,"extra":"ignore me"}"""

                        expected : KmlPlacemark
                        expected =
                            { name = "A", description = "B", lat = Just 1.0, lon = Just 2.0, dateStr = Nothing }
                    in
                    decodeJson decodeKmlPlacemark json
                        |> Expect.equal (Ok expected)
            ]
        ]
