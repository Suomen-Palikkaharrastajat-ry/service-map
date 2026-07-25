module ApiTest exposing (suite)

import Api exposing (decodeLocation, httpErrorToString, imageUrl)
import Expect
import Http
import Json.Decode as Json
import Test exposing (Test, describe, test)
import Types exposing (LocationState(..))


{-| Decode a JSON string using the given decoder.
Returns a Result so tests can pattern-match on Ok/Err.
-}
decodeJson : Json.Decoder a -> String -> Result Json.Error a
decodeJson decoder json =
    Json.decodeString decoder json


{-| A full valid location JSON from PocketBase (all fields present).
-}
fullLocationJson : String
fullLocationJson =
    """{"id":"abc123",
        "title":"Parkour Jam",
        "description":"Fun event",
        "start_date":"2026-05-05T11:00:00.000Z",
        "end_date":"2026-05-05T14:00:00.000Z",
        "url":"https://example.com",
        "location":"Helsinki, Rautatientori",
        "state":"published",
        "image":"photo.jpg",
        "image_description":"Kuva tapahtumasta",
        "point":{"lat":60.1699,"lon":24.9384},
        "tags":["tag1", "tag2"],
        "opening_hours":"Mo-Fr 10:00-18:00",
        "created":"2026-01-01T00:00:00.000Z",
        "updated":"2026-01-02T00:00:00.000Z"}"""


{-| Minimal location JSON with empty/null optional fields and missing tags.
-}
minimalLocationJson : String
minimalLocationJson =
    """{"id":"def456",
        "title":"Kaupunkifestivaal",
        "description":"",
        "start_date":"",
        "end_date":null,
        "url":"",
        "location":"",
        "state":"draft",
        "image":"",
        "image_description":"",
        "point":null,
        "opening_hours":"",
        "created":"2026-01-01T00:00:00.000Z",
        "updated":"2026-01-02T00:00:00.000Z"}"""


suite : Test
suite =
    describe "Api"
        [ describe "decodeLocation"
            [ test "decodes id" <|
                \_ ->
                    decodeJson decodeLocation fullLocationJson
                        |> Result.map .id
                        |> Expect.equal (Ok "abc123")
            , test "decodes title" <|
                \_ ->
                    decodeJson decodeLocation fullLocationJson
                        |> Result.map .title
                        |> Expect.equal (Ok "Parkour Jam")
            , test "decodes description (non-empty → Just)" <|
                \_ ->
                    decodeJson decodeLocation fullLocationJson
                        |> Result.map .description
                        |> Expect.equal (Ok (Just "Fun event"))
            , test "decodes description (empty string → Nothing)" <|
                \_ ->
                    decodeJson decodeLocation minimalLocationJson
                        |> Result.map .description
                        |> Expect.equal (Ok Nothing)
            , test "decodes start_date (non-empty -> Just)" <|
                \_ ->
                    decodeJson decodeLocation fullLocationJson
                        |> Result.map .startDate
                        |> Expect.equal (Ok (Just "2026-05-05T11:00:00.000Z"))
            , test "decodes start_date (empty -> Nothing)" <|
                \_ ->
                    decodeJson decodeLocation minimalLocationJson
                        |> Result.map .startDate
                        |> Expect.equal (Ok Nothing)
            , test "decodes end_date (present → Just)" <|
                \_ ->
                    decodeJson decodeLocation fullLocationJson
                        |> Result.map .endDate
                        |> Expect.equal (Ok (Just "2026-05-05T14:00:00.000Z"))
            , test "decodes end_date (null → Nothing)" <|
                \_ ->
                    decodeJson decodeLocation minimalLocationJson
                        |> Result.map .endDate
                        |> Expect.equal (Ok Nothing)
            , test "decodes url (non-empty → Just)" <|
                \_ ->
                    decodeJson decodeLocation fullLocationJson
                        |> Result.map .url
                        |> Expect.equal (Ok (Just "https://example.com"))
            , test "decodes url (empty string → Nothing)" <|
                \_ ->
                    decodeJson decodeLocation minimalLocationJson
                        |> Result.map .url
                        |> Expect.equal (Ok Nothing)
            , test "decodes location (non-empty → Just)" <|
                \_ ->
                    decodeJson decodeLocation fullLocationJson
                        |> Result.map .location
                        |> Expect.equal (Ok (Just "Helsinki, Rautatientori"))
            , test "decodes location (empty string → Nothing)" <|
                \_ ->
                    decodeJson decodeLocation minimalLocationJson
                        |> Result.map .location
                        |> Expect.equal (Ok Nothing)
            , test "decodes image (non-empty → Just)" <|
                \_ ->
                    decodeJson decodeLocation fullLocationJson
                        |> Result.map .image
                        |> Expect.equal (Ok (Just "photo.jpg"))
            , test "decodes image (empty string → Nothing)" <|
                \_ ->
                    decodeJson decodeLocation minimalLocationJson
                        |> Result.map .image
                        |> Expect.equal (Ok Nothing)
            , test "decodes point lat" <|
                \_ ->
                    decodeJson decodeLocation fullLocationJson
                        |> Result.map (.point >> .lat)
                        |> Expect.equal (Ok 60.1699)
            , test "decodes point lon" <|
                \_ ->
                    decodeJson decodeLocation fullLocationJson
                        |> Result.map (.point >> .lon)
                        |> Expect.equal (Ok 24.9384)
            , test "decodes point null → (0, 0)" <|
                \_ ->
                    decodeJson decodeLocation minimalLocationJson
                        |> Result.map .point
                        |> Expect.equal (Ok { lat = 0, lon = 0 })
            , test "decodes tags (present)" <|
                \_ ->
                    decodeJson decodeLocation fullLocationJson
                        |> Result.map .tags
                        |> Expect.equal (Ok [ "tag1", "tag2" ])
            , test "decodes tags (missing -> [])" <|
                \_ ->
                    decodeJson decodeLocation minimalLocationJson
                        |> Result.map .tags
                        |> Expect.equal (Ok [])
            , test "decodes opening_hours (non-empty -> Just)" <|
                \_ ->
                    decodeJson decodeLocation fullLocationJson
                        |> Result.map .openingHours
                        |> Expect.equal (Ok (Just "Mo-Fr 10:00-18:00"))
            , test "decodes opening_hours (empty -> Nothing)" <|
                \_ ->
                    decodeJson decodeLocation minimalLocationJson
                        |> Result.map .openingHours
                        |> Expect.equal (Ok Nothing)
            ]
        , describe "imageUrl"
            [ test "builds correct URL" <|
                \_ ->
                    imageUrl "https://data.palikkaharrastajat.fi" "abc123" "photo.jpg"
                        |> Expect.equal
                            "https://data.palikkaharrastajat.fi/api/collections/locations/records/abc123/photo.jpg"
            , test "builds correct URL for local instance" <|
                \_ ->
                    imageUrl "http://127.0.0.1:8090" "abc123" "photo.jpg"
                        |> Expect.equal
                            "http://127.0.0.1:8090/api/collections/locations/records/abc123/photo.jpg"
            ]
        , describe "httpErrorToString"
            [ test "BadUrl returns Finnish message" <|
                \_ ->
                    httpErrorToString (Http.BadUrl "http://bad")
                        |> String.startsWith "Virheellinen URL"
                        |> Expect.equal True
            , test "Timeout returns Finnish message" <|
                \_ ->
                    httpErrorToString Http.Timeout
                        |> Expect.equal "Pyyntö aikakatkaistiin. Tarkista verkkoyhteytesi."
            , test "NetworkError returns Finnish message" <|
                \_ ->
                    httpErrorToString Http.NetworkError
                        |> Expect.equal "Verkkovirhe. Tarkista verkkoyhteytesi."
            , test "BadStatus returns code in message" <|
                \_ ->
                    httpErrorToString (Http.BadStatus 500)
                        |> String.contains "500"
                        |> Expect.equal True
            ]
        ]
