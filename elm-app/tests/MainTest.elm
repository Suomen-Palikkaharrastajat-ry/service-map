module MainTest exposing (suite)

import Expect
import Http
import Main exposing (applyFormDate, applyFormField, refreshLocationsOnMutationResult)
import RemoteData exposing (RemoteData(..))
import Test exposing (Test, describe, test)
import Types exposing (LocationState(..), emptyLocationFormData)


testLocation : Types.Location
testLocation =
    { id = "abc123"
    , title = "Testikohde"
    , description = Nothing
    , startDate = Nothing
    , endDate = Nothing
    , location = Nothing
    , url = Nothing
    , image = Nothing
    , imageDescription = Nothing
    , point = { lat = 60.1699, lon = 24.9384 }
    , tags = []
    , openingHours = Nothing
    , state = Published
    }


suite : Test
suite =
    describe "Main"
        [ describe "applyFormField"
            [ test "title field updates title" <|
                \_ ->
                    applyFormField "title" "Kesäjuhla" emptyLocationFormData
                        |> .title
                        |> Expect.equal "Kesäjuhla"
            , test "description field updates description" <|
                \_ ->
                    applyFormField "description" "Kuvaus" emptyLocationFormData
                        |> .description
                        |> Expect.equal "Kuvaus"
            , test "location field updates location" <|
                \_ ->
                    applyFormField "location" "Helsinki" emptyLocationFormData
                        |> .location
                        |> Expect.equal "Helsinki"
            , test "url field updates url" <|
                \_ ->
                    applyFormField "url" "https://example.fi" emptyLocationFormData
                        |> .url
                        |> Expect.equal "https://example.fi"
            , test "imageDescription field updates imageDescription" <|
                \_ ->
                    applyFormField "imageDescription" "Alt-teksti" emptyLocationFormData
                        |> .imageDescription
                        |> Expect.equal "Alt-teksti"
            , test "lat field updates lat" <|
                \_ ->
                    applyFormField "lat" "60.1699" emptyLocationFormData
                        |> .lat
                        |> Expect.equal "60.1699"
            , test "lon field updates lon" <|
                \_ ->
                    applyFormField "lon" "24.9384" emptyLocationFormData
                        |> .lon
                        |> Expect.equal "24.9384"
            , test "state field with 'published' sets state to Published" <|
                \_ ->
                    applyFormField "state" "published" emptyLocationFormData
                        |> .state
                        |> Expect.equal Published
            , test "state field with 'pending' sets state to Pending" <|
                \_ ->
                    applyFormField "state" "pending" emptyLocationFormData
                        |> .state
                        |> Expect.equal Pending
            , test "state field with 'draft' sets state to Draft" <|
                \_ ->
                    applyFormField "state" "draft" emptyLocationFormData
                        |> .state
                        |> Expect.equal Draft
            , test "state field with unrecognised value leaves state unchanged" <|
                \_ ->
                    applyFormField "state" "bogus" emptyLocationFormData
                        |> .state
                        |> Expect.equal Published
            , test "tag field updates tag" <|
                \_ ->
                    applyFormField "tag" "museum" emptyLocationFormData
                        |> .tag
                        |> Expect.equal "museum"
            , test "unknown field leaves form unchanged" <|
                \_ ->
                    applyFormField "nonexistent" "value" emptyLocationFormData
                        |> Expect.equal emptyLocationFormData
            , test "updating one field leaves other fields unchanged" <|
                \_ ->
                    let
                        form =
                            applyFormField "title" "Uusi nimi" emptyLocationFormData
                    in
                    ( form.description, form.location, form.url )
                        |> Expect.equal ( "", "", "" )
            ]
        , describe "applyFormDate"
            [ test "startDate field updates startDate" <|
                \_ ->
                    applyFormDate "startDate" "2026-06-01" emptyLocationFormData
                        |> .startDate
                        |> Expect.equal "2026-06-01"
            , test "endDate field updates endDate" <|
                \_ ->
                    applyFormDate "endDate" "2026-06-02" emptyLocationFormData
                        |> .endDate
                        |> Expect.equal "2026-06-02"
            , test "unknown field leaves form unchanged" <|
                \_ ->
                    applyFormDate "nonexistent" "2026-06-01" emptyLocationFormData
                        |> Expect.equal emptyLocationFormData
            , test "updating startDate leaves other date fields unchanged" <|
                \_ ->
                    let
                        form =
                            applyFormDate "startDate" "2026-06-01" emptyLocationFormData
                    in
                    form.endDate
                        |> Expect.equal ""
            ]
        , describe "refreshLocationsOnMutationResult"
            [ test "successful save purges a cached list, marking it Loading" <|
                \_ ->
                    refreshLocationsOnMutationResult (Ok testLocation) (Success [ testLocation ])
                        |> Expect.equal Loading
            , test "successful save marks NotAsked cache Loading" <|
                \_ ->
                    refreshLocationsOnMutationResult (Ok testLocation) NotAsked
                        |> Expect.equal Loading
            , test "successful save marks a Failure cache Loading" <|
                \_ ->
                    refreshLocationsOnMutationResult (Ok testLocation) (Failure Http.NetworkError)
                        |> Expect.equal Loading
            , test "failed save leaves a cached list unchanged" <|
                \_ ->
                    refreshLocationsOnMutationResult (Err Http.NetworkError) (Success [ testLocation ])
                        |> Expect.equal (Success [ testLocation ])
            ]
        ]
