module Api exposing (createLocation, decodeLocation, fetchEvents, fetchGeoJson, fetchLocation, fetchLocations, httpErrorToString, imageUrl, updateLocation, updateLocationState)

import DateUtils exposing (formDateTimeToUtc)
import File
import Http
import Json.Decode as Json exposing (Decoder)
import Json.Encode as Encode
import OpeningHours.Editor
import Types exposing (Event, GeoPoint, Location, LocationFormData, LocationState, Msg(..), locationStateToString)
import Url


imageUrl : String -> String -> String -> String
imageUrl pbBaseUrl id filename =
    pbBaseUrl ++ "/api/collections/locations/records/" ++ id ++ "/" ++ filename


fetchLocations : String -> Maybe String -> Cmd Msg
fetchLocations pbBaseUrl maybeToken =
    let
        baseUrl =
            pbBaseUrl
                ++ "/api/collections/locations/records"
                ++ "?sort=-created&perPage=500"

        url =
            case maybeToken of
                Just _ ->
                    baseUrl

                Nothing ->
                    baseUrl
                        ++ "&filter="
                        ++ Url.percentEncode "(state=\"published\")"

        headers =
            case maybeToken of
                Just token ->
                    [ Http.header "Authorization" token ]

                Nothing ->
                    []
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect =
            Http.expectJson
                LocationsLoaded
                (Json.field "items" (Json.list decodeLocation))
        , timeout = Nothing
        , tracker = Nothing
        }


fetchGeoJson : Cmd Msg
fetchGeoJson =
    Http.get
        { url = "kartta.geo.json"
        , expect = Http.expectJson Types.GeoJsonLoaded decodeGeoJson
        }


fetchEvents : String -> Maybe String -> Cmd Msg
fetchEvents pbBaseUrl maybeToken =
    let
        baseUrl =
            pbBaseUrl
                ++ "/api/collections/events/records"
                ++ "?sort=-start_date&perPage=500"

        url =
            baseUrl
                ++ "&filter="
                ++ Url.percentEncode "(state=\"published\" && end_date >= @now)"

        headers =
            case maybeToken of
                Just token ->
                    [ Http.header "Authorization" token ]

                Nothing ->
                    []
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect =
            Http.expectJson
                EventsLoaded
                (Json.field "items" (Json.list decodeEvent))
        , timeout = Nothing
        , tracker = Nothing
        }


fetchLocation : String -> Maybe String -> String -> (Result Http.Error Location -> Msg) -> Cmd Msg
fetchLocation pbBaseUrl maybeToken id toMsg =
    let
        headers =
            case maybeToken of
                Just token ->
                    [ Http.header "Authorization" token ]

                Nothing ->
                    []
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = pbBaseUrl ++ "/api/collections/locations/records/" ++ id
        , body = Http.emptyBody
        , expect = Http.expectJson toMsg decodeLocation
        , timeout = Nothing
        , tracker = Nothing
        }


createLocation : String -> String -> LocationFormData -> (Result Http.Error Location -> Msg) -> Cmd Msg
createLocation pbBaseUrl token formData toMsg =
    Http.request
        { method = "POST"
        , headers = [ Http.header "Authorization" token ]
        , url = pbBaseUrl ++ "/api/collections/locations/records"
        , body =
            case formData.imageFile of
                Just _ ->
                    locationFormToMultipart formData

                Nothing ->
                    Http.jsonBody (locationFormToJson formData)
        , expect = Http.expectJson toMsg decodeLocation
        , timeout = Nothing
        , tracker = Nothing
        }


updateLocation : String -> String -> String -> LocationFormData -> (Result Http.Error Location -> Msg) -> Cmd Msg
updateLocation pbBaseUrl token id formData toMsg =
    Http.request
        { method = "PATCH"
        , headers = [ Http.header "Authorization" token ]
        , url = pbBaseUrl ++ "/api/collections/locations/records/" ++ id
        , body =
            case formData.imageFile of
                Just _ ->
                    locationFormToMultipart formData

                Nothing ->
                    Http.jsonBody (locationFormToJson formData)
        , expect = Http.expectJson toMsg decodeLocation
        , timeout = Nothing
        , tracker = Nothing
        }


decodeGeoPoint : Decoder GeoPoint
decodeGeoPoint =
    Json.map2 GeoPoint
        (Json.field "lat" Json.float)
        (Json.field "lon" Json.float)


decodeEvent : Decoder Event
decodeEvent =
    Json.map8
        (\id title description startDate endDate loc url img ->
            { id = id
            , title = title
            , description = description
            , startDate = startDate
            , endDate = endDate
            , location = loc
            , url = url
            , image = img
            , point = { lat = 0, lon = 0 }
            , allDay = False
            }
        )
        (Json.field "id" Json.string)
        (Json.field "title" Json.string)
        (Json.maybe (Json.field "description" Json.string) |> Json.map emptyToNothing)
        (Json.field "start_date" Json.string)
        (Json.field "end_date" Json.string)
        (Json.maybe (Json.field "location" Json.string) |> Json.map emptyToNothing)
        (Json.maybe (Json.field "url" Json.string) |> Json.map emptyToNothing)
        (Json.maybe (Json.field "image" Json.string) |> Json.map emptyToNothing)
        |> Json.andThen
            (\partial ->
                Json.map2
                    (\pt ad ->
                        { partial | point = pt, allDay = ad }
                    )
                    (Json.maybe (Json.field "point" decodeGeoPoint) |> Json.map (Maybe.withDefault { lat = 0, lon = 0 }))
                    (Json.maybe (Json.field "all_day" Json.bool) |> Json.map (Maybe.withDefault False))
            )


decodeLocation : Decoder Location
decodeLocation =
    Json.map8
        (\id title description startDate endDate loc url img ->
            { id = id
            , title = title
            , description = description
            , startDate = startDate
            , endDate = endDate
            , location = loc
            , url = url
            , image = img
            , imageDescription = Nothing
            , point = { lat = 0, lon = 0 }
            , tags = []
            , openingHours = Nothing
            , state = Types.Draft
            }
        )
        (Json.field "id" Json.string)
        (Json.field "title" Json.string)
        (Json.maybe (Json.field "description" Json.string) |> Json.map emptyToNothing)
        (Json.maybe (Json.field "start_date" Json.string) |> Json.map emptyToNothing)
        (Json.maybe (Json.field "end_date" Json.string) |> Json.map emptyToNothing)
        (Json.maybe (Json.field "location" Json.string) |> Json.map emptyToNothing)
        (Json.maybe (Json.field "url" Json.string) |> Json.map emptyToNothing)
        (Json.maybe (Json.field "image" Json.string) |> Json.map emptyToNothing)
        |> Json.andThen
            (\partial ->
                Json.map5
                    (\imgDesc pt tags oh stateStr ->
                        { partial
                            | imageDescription = imgDesc
                            , point = pt
                            , tags = tags
                            , openingHours = oh
                            , state = Maybe.withDefault Types.Draft (Types.locationStateFromString stateStr)
                        }
                    )
                    (Json.maybe (Json.field "image_description" Json.string) |> Json.map emptyToNothing)
                    (Json.maybe (Json.field "point" decodeGeoPoint) |> Json.map (Maybe.withDefault { lat = 0, lon = 0 }))
                    (Json.maybe (Json.field "tags" (Json.list Json.string)) |> Json.map (Maybe.withDefault []))
                    (Json.maybe (Json.field "opening_hours" Json.string) |> Json.map emptyToNothing)
                    (Json.maybe (Json.field "state" Json.string) |> Json.map (Maybe.withDefault "draft"))
            )


type FeatureProperty
    = LocProperty Location
    | EvtProperty Event


decodeFeatureProperty : Decoder FeatureProperty
decodeFeatureProperty =
    Json.field "type" Json.string
        |> Json.maybe
        |> Json.andThen
            (\maybeType ->
                case maybeType of
                    Just "event" ->
                        Json.map EvtProperty decodeEvent

                    _ ->
                        Json.map LocProperty decodeLocation
            )


splitFeatures : List FeatureProperty -> { locations : List Location, events : List Event }
splitFeatures features =
    List.foldl
        (\feat acc ->
            case feat of
                LocProperty loc ->
                    { acc | locations = loc :: acc.locations }

                EvtProperty evt ->
                    { acc | events = evt :: acc.events }
        )
        { locations = [], events = [] }
        features


decodeGeoJson : Decoder { locations : List Location, events : List Event }
decodeGeoJson =
    Json.field "features"
        (Json.list (Json.field "properties" decodeFeatureProperty))
        |> Json.map splitFeatures


emptyToNothing : Maybe String -> Maybe String
emptyToNothing m =
    case m of
        Just "" ->
            Nothing

        v ->
            v


locationFormToJson : LocationFormData -> Encode.Value
locationFormToJson formData =
    let
        startDatePart =
            Maybe.withDefault formData.startDate (formDateTimeToUtc formData.startDate "" True)

        endDatePart =
            if String.isEmpty formData.endDate then
                ""

            else
                Maybe.withDefault formData.endDate (formDateTimeToUtc formData.endDate "23:59" False)

        pointJson =
            if formData.geocodingEnabled then
                case ( String.toFloat formData.lat, String.toFloat formData.lon ) of
                    ( Just lat, Just lon ) ->
                        Encode.object [ ( "lat", Encode.float lat ), ( "lon", Encode.float lon ) ]

                    _ ->
                        Encode.null

            else
                Encode.null
    in
    Encode.object
        [ ( "title", Encode.string formData.title )
        , ( "description", Encode.string formData.description )
        , ( "location", Encode.string formData.location )
        , ( "url", Encode.string formData.url )
        , ( "start_date", Encode.string startDatePart )
        , ( "end_date", Encode.string endDatePart )
        , ( "state", Encode.string (locationStateToString formData.state) )
        , ( "image_description", Encode.string formData.imageDescription )
        , ( "point", pointJson )
        , ( "opening_hours", Encode.string (OpeningHours.Editor.getRawString formData.openingHours) )
        , ( "tags"
          , if String.isEmpty formData.tag then
                Encode.list Encode.string []

            else
                Encode.list Encode.string [ formData.tag ]
          )
        ]


locationFormToMultipart : LocationFormData -> Http.Body
locationFormToMultipart formData =
    let
        startDatePart =
            case formDateTimeToUtc formData.startDate "" True of
                Just s ->
                    s

                Nothing ->
                    formData.startDate

        endDatePart =
            if String.isEmpty formData.endDate then
                ""

            else
                case formDateTimeToUtc formData.endDate "23:59" False of
                    Just s ->
                        s

                    Nothing ->
                        formData.endDate

        textParts =
            [ Http.stringPart "title" formData.title
            , Http.stringPart "description" formData.description
            , Http.stringPart "location" formData.location
            , Http.stringPart "url" formData.url
            , Http.stringPart "start_date" startDatePart
            , Http.stringPart "end_date" endDatePart
            , Http.stringPart "state" (locationStateToString formData.state)
            , Http.stringPart "image_description" formData.imageDescription
            , Http.stringPart "opening_hours" (OpeningHours.Editor.getRawString formData.openingHours)
            , Http.stringPart "point" (encodePointForPb formData)
            , Http.stringPart "tags"
                (if String.isEmpty formData.tag then
                    "[]"

                 else
                    "[\"" ++ formData.tag ++ "\"]"
                )
            ]

        fileParts =
            case formData.imageFile of
                Nothing ->
                    []

                Just file ->
                    [ Http.filePart "image" file ]
    in
    Http.multipartBody (textParts ++ fileParts)


encodePointForPb : LocationFormData -> String
encodePointForPb formData =
    if formData.geocodingEnabled then
        case ( String.toFloat formData.lat, String.toFloat formData.lon ) of
            ( Just lat, Just lon ) ->
                "{\"lat\":" ++ String.fromFloat lat ++ ",\"lon\":" ++ String.fromFloat lon ++ "}"

            _ ->
                ""

    else
        ""


updateLocationState : String -> String -> String -> Types.LocationState -> (Result Http.Error Location -> Msg) -> Cmd Msg
updateLocationState pbBaseUrl token id state toMsg =
    Http.request
        { method = "PATCH"
        , headers = [ Http.header "Authorization" token ]
        , url = pbBaseUrl ++ "/api/collections/locations/records/" ++ id
        , body = Http.jsonBody (Encode.object [ ( "state", Encode.string (locationStateToString state) ) ])
        , expect = Http.expectJson toMsg decodeLocation
        , timeout = Nothing
        , tracker = Nothing
        }


httpErrorToString : Http.Error -> String
httpErrorToString err =
    case err of
        Http.BadUrl url ->
            "Virheellinen URL: " ++ url

        Http.Timeout ->
            "Pyyntö aikakatkaistiin. Tarkista verkkoyhteytesi."

        Http.NetworkError ->
            "Verkkovirhe. Tarkista verkkoyhteytesi."

        Http.BadStatus statusCode ->
            case statusCode of
                400 ->
                    "Virheellinen pyyntö."

                401 ->
                    "Ei oikeuksia. Kirjaudu sisään uudelleen."

                403 ->
                    "Ei oikeuksia toimintoon."

                404 ->
                    "Kohdetta ei löytynyt."

                _ ->
                    "Palvelinvirhe (" ++ String.fromInt statusCode ++ ")."

        Http.BadBody message ->
            "Virhe datan käsittelyssä: " ++ message
