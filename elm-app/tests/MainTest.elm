module MainTest exposing (suite)

import Expect
import Http
import Main exposing (applyFormDate, applyFormField, nextEventFilter, refreshLocationsOnMutationResult, visibleEvents)
import RemoteData exposing (RemoteData(..))
import Test exposing (Test, describe, test)
import Types exposing (EventFilter(..), LocationState(..), emptyLocationFormData)


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


testEvent : String -> Bool -> Types.Event
testEvent id cancelled =
    { id = id
    , title = "Tapahtuma " ++ id
    , description = Nothing
    , startDate = "2026-08-01T09:00:00.000Z"
    , endDate = "2026-08-01T15:00:00.000Z"
    , location = Nothing
    , url = Nothing
    , image = Nothing
    , point = { lat = 60.1699, lon = 24.9384 }
    , allDay = False
    , cancelled = cancelled
    }


liveEvent : Types.Event
liveEvent =
    testEvent "live" False


cancelledEvent : Types.Event
cancelledEvent =
    testEvent "cancelled" True


unlocatedEvent : Types.Event
unlocatedEvent =
    { liveEvent | id = "unlocated", point = { lat = 0, lon = 0 } }


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
        , describe "nextEventFilter"
            [ test "AllEvents cycles to HideCancelled" <|
                \_ -> nextEventFilter AllEvents |> Expect.equal HideCancelled
            , test "HideCancelled cycles to NoEvents" <|
                \_ -> nextEventFilter HideCancelled |> Expect.equal NoEvents
            , test "NoEvents cycles back to AllEvents" <|
                \_ -> nextEventFilter NoEvents |> Expect.equal AllEvents
            , test "three cycles return to the starting state" <|
                \_ ->
                    nextEventFilter (nextEventFilter (nextEventFilter HideCancelled))
                        |> Expect.equal HideCancelled
            ]
        , describe "visibleEvents"
            [ test "AllEvents keeps cancelled events" <|
                \_ ->
                    visibleEvents { eventFilter = AllEvents, events = Success [ liveEvent, cancelledEvent ] }
                        |> List.map .id
                        |> Expect.equal [ "live", "cancelled" ]
            , test "HideCancelled drops cancelled events" <|
                \_ ->
                    visibleEvents { eventFilter = HideCancelled, events = Success [ liveEvent, cancelledEvent ] }
                        |> List.map .id
                        |> Expect.equal [ "live" ]
            , test "NoEvents drops everything" <|
                \_ ->
                    visibleEvents { eventFilter = NoEvents, events = Success [ liveEvent, cancelledEvent ] }
                        |> Expect.equal []
            , test "events at (0,0) are always dropped" <|
                \_ ->
                    visibleEvents { eventFilter = AllEvents, events = Success [ unlocatedEvent ] }
                        |> Expect.equal []
            , test "unloaded events give an empty list" <|
                \_ ->
                    visibleEvents { eventFilter = AllEvents, events = NotAsked }
                        |> Expect.equal []
            ]
        ]
