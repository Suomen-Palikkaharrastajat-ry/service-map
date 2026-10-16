module MainTest exposing (suite)

{-| Test suite for Main helper functions and update logic.
-}

import Expect
import Http
import Main exposing (applyFormDate, applyFormField, filterActiveModal, filterSelectedMarker, isMarkerVisible, nextEventFilter, refreshLocationsOnMutationResult)
import RemoteData exposing (RemoteData(..))
import Test exposing (Test, describe, test)
import Types exposing (EventFilter(..), FilterModal(..), LocationState(..), SelectedMarker(..), emptyLocationFormData, locationsForTag, upcomingEvents, visibleEvents, visibleLocations, visibleLocationsForTag)


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
        , describe "upcomingEvents"
            [ test "sorts the visible events by start date" <|
                \_ ->
                    upcomingEvents
                        { eventFilter = AllEvents
                        , events = Success [ { liveEvent | id = "late", startDate = "2026-12-01" }, { liveEvent | id = "early", startDate = "2026-11-01" } ]
                        }
                        |> List.map .id
                        |> Expect.equal [ "early", "late" ]
            , test "respects HideCancelled" <|
                \_ ->
                    upcomingEvents { eventFilter = HideCancelled, events = Success [ liveEvent, cancelledEvent ] }
                        |> List.map .id
                        |> Expect.equal [ "live" ]
            , test "is empty when events are hidden" <|
                \_ ->
                    upcomingEvents { eventFilter = NoEvents, events = Success [ liveEvent, cancelledEvent ] }
                        |> Expect.equal []
            , test "drops events at (0,0)" <|
                \_ ->
                    upcomingEvents { eventFilter = AllEvents, events = Success [ unlocatedEvent ] }
                        |> Expect.equal []
            ]
        , describe "filterSelectedMarker"
            [ test "keeps selected location when tags are visible" <|
                \_ ->
                    let
                        loc =
                            { testLocation | tags = [ "museum" ] }
                    in
                    filterSelectedMarker
                        { hiddenTags = []
                        , eventFilter = AllEvents
                        , events = NotAsked
                        , selectedMarker = Just (SelectedLocation loc)
                        }
                        |> Expect.equal (Just (SelectedLocation loc))
            , test "drops selected location when tag is hidden" <|
                \_ ->
                    let
                        loc =
                            { testLocation | tags = [ "museum" ] }
                    in
                    filterSelectedMarker
                        { hiddenTags = [ "museum" ]
                        , eventFilter = AllEvents
                        , events = NotAsked
                        , selectedMarker = Just (SelectedLocation loc)
                        }
                        |> Expect.equal Nothing
            , test "keeps selected live event when HideCancelled is active" <|
                \_ ->
                    filterSelectedMarker
                        { hiddenTags = []
                        , eventFilter = HideCancelled
                        , events = Success [ liveEvent, cancelledEvent ]
                        , selectedMarker = Just (SelectedEvent liveEvent)
                        }
                        |> Expect.equal (Just (SelectedEvent liveEvent))
            , test "drops selected cancelled event when HideCancelled is active" <|
                \_ ->
                    filterSelectedMarker
                        { hiddenTags = []
                        , eventFilter = HideCancelled
                        , events = Success [ liveEvent, cancelledEvent ]
                        , selectedMarker = Just (SelectedEvent cancelledEvent)
                        }
                        |> Expect.equal Nothing
            , test "drops selected event when NoEvents is active" <|
                \_ ->
                    filterSelectedMarker
                        { hiddenTags = []
                        , eventFilter = NoEvents
                        , events = Success [ liveEvent ]
                        , selectedMarker = Just (SelectedEvent liveEvent)
                        }
                        |> Expect.equal Nothing
            , test "remains Nothing when no marker is selected" <|
                \_ ->
                    filterSelectedMarker
                        { hiddenTags = []
                        , eventFilter = AllEvents
                        , events = Success [ liveEvent ]
                        , selectedMarker = Nothing
                        }
                        |> Expect.equal Nothing
            ]
        , describe "visibleLocations"
            [ test "drops locations at (0,0)" <|
                \_ ->
                    let
                        unlocatedLoc =
                            { testLocation | id = "unlocated", point = { lat = 0, lon = 0 } }
                    in
                    visibleLocations { hiddenTags = [], locations = Success [ unlocatedLoc, testLocation ] }
                        |> List.map .id
                        |> Expect.equal [ "abc123" ]
            , test "drops locations hidden by any of their tags" <|
                \_ ->
                    let
                        museumStore =
                            { testLocation | id = "museumStore", tags = [ "museum", "store" ] }
                    in
                    visibleLocations { hiddenTags = [ "museum" ], locations = Success [ museumStore ] }
                        |> Expect.equal []
            , test "keeps locations whose tags are all visible" <|
                \_ ->
                    let
                        storeLoc =
                            { testLocation | id = "storeLoc", tags = [ "store" ] }
                    in
                    visibleLocations { hiddenTags = [ "museum" ], locations = Success [ storeLoc ] }
                        |> List.map .id
                        |> Expect.equal [ "storeLoc" ]
            , test "returns empty when not loaded" <|
                \_ ->
                    visibleLocations { hiddenTags = [], locations = NotAsked }
                        |> Expect.equal []
            ]
        , describe "visibleLocationsForTag"
            [ test "returns only locations containing the tag" <|
                \_ ->
                    let
                        storeLoc =
                            { testLocation | id = "store1", tags = [ "store" ] }

                        museumLoc =
                            { testLocation | id = "museum1", tags = [ "museum" ] }
                    in
                    visibleLocationsForTag "store" { hiddenTags = [], locations = Success [ storeLoc, museumLoc ] }
                        |> List.map .id
                        |> Expect.equal [ "store1" ]
            , test "returns empty when tag itself is hidden" <|
                \_ ->
                    let
                        storeLoc =
                            { testLocation | id = "store1", tags = [ "store" ] }
                    in
                    visibleLocationsForTag "store" { hiddenTags = [ "store" ], locations = Success [ storeLoc ] }
                        |> Expect.equal []
            , test "returns empty when location has another tag that is hidden" <|
                \_ ->
                    let
                        storeMuseumLoc =
                            { testLocation | id = "combo", tags = [ "store", "museum" ] }
                    in
                    visibleLocationsForTag "store" { hiddenTags = [ "museum" ], locations = Success [ storeMuseumLoc ] }
                        |> Expect.equal []
            ]
        , describe "locationsForTag"
            [ test "sorts locations by title case-insensitively" <|
                \_ ->
                    let
                        locA =
                            { testLocation | id = "a", title = "zebra", tags = [ "store" ] }

                        locB =
                            { testLocation | id = "b", title = "Alpha", tags = [ "store" ] }

                        locC =
                            { testLocation | id = "c", title = "beta", tags = [ "store" ] }
                    in
                    locationsForTag "store" { hiddenTags = [], locations = Success [ locA, locB, locC ] }
                        |> List.map .id
                        |> Expect.equal [ "b", "c", "a" ]
            ]
        , describe "filterActiveModal"
            [ test "keeps EventsModal when events are visible" <|
                \_ ->
                    filterActiveModal
                        { hiddenTags = []
                        , eventFilter = AllEvents
                        , filterModal = Just EventsModal
                        }
                        |> Expect.equal (Just EventsModal)
            , test "keeps EventsModal when eventFilter is HideCancelled" <|
                \_ ->
                    filterActiveModal
                        { hiddenTags = []
                        , eventFilter = HideCancelled
                        , filterModal = Just EventsModal
                        }
                        |> Expect.equal (Just EventsModal)
            , test "drops EventsModal when eventFilter is NoEvents" <|
                \_ ->
                    filterActiveModal
                        { hiddenTags = []
                        , eventFilter = NoEvents
                        , filterModal = Just EventsModal
                        }
                        |> Expect.equal Nothing
            , test "keeps TagModal when tag is visible" <|
                \_ ->
                    filterActiveModal
                        { hiddenTags = []
                        , eventFilter = AllEvents
                        , filterModal = Just (TagModal "store")
                        }
                        |> Expect.equal (Just (TagModal "store"))
            , test "keeps TagModal when hiddenTags contains unrelated tags" <|
                \_ ->
                    filterActiveModal
                        { hiddenTags = [ "museum" ]
                        , eventFilter = AllEvents
                        , filterModal = Just (TagModal "store")
                        }
                        |> Expect.equal (Just (TagModal "store"))
            , test "drops TagModal when tag is hidden" <|
                \_ ->
                    filterActiveModal
                        { hiddenTags = [ "store" ]
                        , eventFilter = AllEvents
                        , filterModal = Just (TagModal "store")
                        }
                        |> Expect.equal Nothing
            , test "remains Nothing when no modal was open" <|
                \_ ->
                    filterActiveModal
                        { hiddenTags = []
                        , eventFilter = AllEvents
                        , filterModal = Nothing
                        }
                        |> Expect.equal Nothing
            ]
        ]
