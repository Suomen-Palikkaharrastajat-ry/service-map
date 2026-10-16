module Main exposing (applyFormDate, applyFormField, main, nextEventFilter, refreshLocationsOnMutationResult, visibleEvents)

{-| Main application module: routing, state management, and top-level view.
-}

import Api
import Browser
import Browser.Events
import Browser.Navigation as Nav
import Component.Layout
import Component.SkipLink
import Component.Spinner
import Component.Toast
import Date
import DatePicker
import DateUtils
import FeatherIcons
import File
import FinnishDatePicker
import Geocoding
import Html exposing (Html, div, main_)
import Html.Attributes exposing (class, id, style)
import Html.Keyed
import Http
import I18n exposing (MsgKey(..), t)
import Json.Decode as Decode
import Lang exposing (Lang)
import OpeningHours.Editor
import OpeningHours.I18n as OHI18n
import OpeningHours.Parser as OHParser
import OpeningHours.Viewer as OHViewer
import Page.LocationDetail
import Page.LocationEdit
import Page.LocationNew
import Page.Locations
import Page.Map
import PocketBaseAuth exposing (AuthState(..), getToken)
import Ports exposing (MarkerData)
import RemoteData exposing (RemoteData(..))
import Route exposing (Route(..), parseUrl)
import SiteSettings
import Task
import Time
import Types
    exposing
        ( Event
        , EventFilter(..)
        , Flags
        , FormStatus(..)
        , Location
        , LocationFormData
        , Model
        , Msg(..)
        , Page(..)
        , emptyLocationFormData
        )
import Url exposing (Url)
import View.Layout


helsinkiLat : Float
helsinkiLat =
    60.1699


helsinkiLon : Float
helsinkiLon =
    24.9384


defaultMapZoom : Int
defaultMapZoom =
    10


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        initialRoute =
            parseUrl url

        authState =
            PocketBaseAuth.restoreAuthFromFlags flags.authToken flags.authModel

        now =
            Time.millisToPosix flags.now

        settings =
            SiteSettings.fromFlags flags.requestedLang flags.siteConfig

        lang =
            settings.lang

        site =
            settings.site

        reportConfigError =
            case settings.error of
                Just problem ->
                    Ports.reportError problem

                Nothing ->
                    Cmd.none

        ( page, cmd ) =
            initPage lang flags.pbBaseUrl key initialRoute authState url now

        calendarUrl =
            flags.siteConfig
                |> Decode.decodeValue (SiteSettings.appDecoder lang (Decode.field "calendar_url" Decode.string))

        reportCalendarUrl =
            case ( settings.error, calendarUrl ) of
                ( Nothing, Err problem ) ->
                    Ports.reportError ("[app] calendar_url is missing from config.toml: " ++ Decode.errorToString problem)

                _ ->
                    Cmd.none
    in
    ( { pbBaseUrl = flags.pbBaseUrl
      , key = key
      , url = url
      , page = page
      , authState = authState
      , menuOpen = False
      , locations = RemoteData.Loading
      , events = RemoteData.Loading
      , selectedMarker = Nothing
      , hiddenTags = flags.hiddenTags
      , eventFilter = Maybe.withDefault HideCancelled (Types.eventFilterFromString flags.eventsFilter)
      , isEmbed = flags.isEmbed
      , platform = flags.platform
      , presentationMode = False
      , now = now
      , toasts = []
      , nextToastId = 0
      , site = site
      , lang = lang
      , calendarUrl = Result.withDefault "" calendarUrl
      }
    , Cmd.batch
        [ Ports.setDocumentLang (Lang.toString lang)
        , reportConfigError
        , reportCalendarUrl
        , case authState of
            Authenticated _ ->
                Cmd.batch
                    [ Api.fetchLocations flags.pbBaseUrl (getToken authState)
                    , Api.fetchEvents flags.pbBaseUrl (getToken authState)
                    , cmd
                    ]

            NotAuthenticated ->
                Cmd.batch
                    [ Api.fetchGeoJson
                    , cmd
                    ]
        ]
    )


initPage : Lang -> String -> Nav.Key -> Route -> AuthState -> Url -> Time.Posix -> ( Page, Cmd Msg )
initPage lang pbBaseUrl key route authState url now =
    case route of
        RouteMap ->
            ( PageMap
            , Ports.initMap
                { containerId = "map"
                , lat = 65.0
                , lon = 26.0
                , zoom = 5
                , markerLat = Nothing
                , markerLon = Nothing
                , draggable = False
                , mapStyle = "basemap"
                }
            )

        RouteLocations ->
            ( PageLocations { kmlImportStatus = Types.KmlIdle, kmlQueue = [], importCount = 0 }, Cmd.none )

        RouteLocationNew ->
            case authState of
                Authenticated _ ->
                    let
                        ( newPage, newCmd ) =
                            Page.LocationNew.init now
                    in
                    ( PageLocationNew newPage
                    , Cmd.batch
                        [ newCmd
                        , Ports.initMap
                            { containerId = "create-map"
                            , lat = helsinkiLat
                            , lon = helsinkiLon
                            , zoom = defaultMapZoom
                            , markerLat = Nothing
                            , markerLon = Nothing
                            , draggable = True
                            , mapStyle = "osm"
                            }
                        ]
                    )

                NotAuthenticated ->
                    ( PageLocations { kmlImportStatus = Types.KmlIdle, kmlQueue = [], importCount = 0 }
                    , Cmd.batch
                        [ Nav.pushUrl key (Route.toHref RouteLocations)
                        , Task.perform identity (Task.succeed (Types.AddToast Types.ToastInfo (t lang LoginRequired)))
                        ]
                    )

        RouteLocationDetail id ->
            let
                ( detailPage, detailCmd ) =
                    Page.LocationDetail.init pbBaseUrl (getToken authState) id
            in
            ( PageLocationDetail id detailPage, detailCmd )

        RouteLocationEdit id ->
            case authState of
                Authenticated _ ->
                    let
                        ( editPage, editCmd ) =
                            Page.LocationEdit.init now pbBaseUrl (getToken authState) id
                    in
                    ( PageLocationEdit id editPage, editCmd )

                NotAuthenticated ->
                    ( PageLocations { kmlImportStatus = Types.KmlIdle, kmlQueue = [], importCount = 0 }
                    , Cmd.batch
                        [ Nav.pushUrl key (Route.toHref RouteLocations)
                        , Task.perform identity (Task.succeed (Types.AddToast Types.ToastInfo (t lang LoginRequired)))
                        ]
                    )

        RouteAuthCallback ->
            ( PageAuthCallback, Ports.getCallbackParams () )

        RouteNotFound ->
            ( PageNotFound, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            let
                newRoute =
                    parseUrl url

                mapCleanupCmd =
                    case model.page of
                        PageLocationNew _ ->
                            Ports.destroyMap "create-map"

                        PageLocationEdit _ _ ->
                            Ports.destroyMap "edit-map"

                        PageMap ->
                            Ports.destroyMap "map"

                        _ ->
                            Cmd.none

                ( page, cmd ) =
                    initPage model.lang model.pbBaseUrl model.key newRoute model.authState url model.now

                newModel =
                    { model | url = url, page = page, menuOpen = False }

                extraCmd =
                    case page of
                        PageMap ->
                            updateMarkers newModel

                        _ ->
                            Cmd.none
            in
            ( newModel
            , Cmd.batch [ mapCleanupCmd, cmd, extraCmd, menuClosedCmd model ]
            )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    if Lang.isSwitch model.lang url.query then
                        -- The language is read at startup, so switching it loads the
                        -- page; the current route (the fragment) is kept.
                        ( model, Nav.load (Url.toString { url | fragment = model.url.fragment }) )

                    else
                        ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        NoOp ->
            ( model, Cmd.none )

        NavigateTo route ->
            ( model, Nav.pushUrl model.key (Route.toHref route) )

        GeoJsonLoaded (Ok data) ->
            let
                newModel =
                    { model | locations = Success data.locations, events = Success data.events }
            in
            ( newModel, updateMarkers newModel )

        GeoJsonLoaded (Err err) ->
            ( { model | locations = Failure err, events = Failure err }, Cmd.none )

        LocationsLoaded (Ok locations) ->
            let
                newModel =
                    { model | locations = Success locations }
            in
            ( newModel, updateMarkers newModel )

        LocationsLoaded (Err err) ->
            ( { model | locations = Failure err }, Cmd.none )

        EventsLoaded (Ok events) ->
            let
                newModel =
                    { model | events = Success events }
            in
            ( newModel, updateMarkers newModel )

        EventsLoaded (Err err) ->
            ( { model | events = Failure err }, Cmd.none )

        MarkerClicked locationId ->
            let
                loc =
                    case model.locations of
                        Success locs ->
                            List.filter (\l -> l.id == locationId) locs |> List.head

                        _ ->
                            Nothing

                evt =
                    case model.events of
                        Success evts ->
                            List.filter (\e -> e.id == locationId) evts |> List.head

                        _ ->
                            Nothing

                selected =
                    case loc of
                        Just l ->
                            Just (Types.SelectedLocation l)

                        Nothing ->
                            case evt of
                                Just e ->
                                    Just (Types.SelectedEvent e)

                                Nothing ->
                                    Nothing

                cmd =
                    case selected of
                        Just (Types.SelectedLocation l) ->
                            Cmd.batch
                                [ Ports.focusMapOnMarker { lat = l.point.lat, lon = l.point.lon, id = l.id, title = l.title, date = locationTooltipSubtitle model.lang l, cancelled = False }
                                , Ports.focusElement "map-detail-close"
                                ]

                        Just (Types.SelectedEvent e) ->
                            let
                                dateStr =
                                    Maybe.withDefault "" (DateUtils.formatEventDateDisplay model.lang e)
                            in
                            Cmd.batch
                                [ Ports.focusMapOnMarker { lat = e.point.lat, lon = e.point.lon, id = e.id, title = e.title, date = dateStr, cancelled = e.cancelled }
                                , Ports.focusElement "map-detail-close"
                                ]

                        Nothing ->
                            Cmd.none
            in
            ( { model | selectedMarker = selected }, cmd )

        SelectPrevMarker ->
            let
                allItems =
                    (case model.locations of
                        Success locs ->
                            List.filter (\l -> Types.hasValidCoordinates l.point) locs
                                |> List.filter (\l -> not (List.any (\tag -> List.member tag model.hiddenTags) l.tags))
                                |> List.map (\l -> ( l.point.lat, l.point.lon, l.id ))

                        _ ->
                            []
                    )
                        ++ (visibleEvents model
                                |> List.map (\e -> ( e.point.lat, e.point.lon, e.id ))
                           )

                allIds =
                    allItems
                        |> List.sortWith
                            (\( latA, lonA, _ ) ( latB, lonB, _ ) ->
                                case compare latB latA of
                                    EQ ->
                                        compare lonB lonA

                                    other ->
                                        other
                            )
                        |> List.map (\( _, _, id ) -> id)

                currId =
                    case model.selectedMarker of
                        Just (Types.SelectedLocation l) ->
                            l.id

                        Just (Types.SelectedEvent e) ->
                            e.id

                        Nothing ->
                            ""

                prevId =
                    let
                        findNext curr lst =
                            case lst of
                                [] ->
                                    ""

                                [ x ] ->
                                    ""

                                x :: y :: rest ->
                                    if x == curr then
                                        y

                                    else
                                        findNext curr (y :: rest)

                        reversed =
                            List.reverse allIds

                        found =
                            findNext currId reversed
                    in
                    if found == "" then
                        Maybe.withDefault "" (List.head reversed)

                    else
                        found
            in
            if prevId /= "" then
                let
                    ( m, c ) =
                        update (MarkerClicked prevId) model
                in
                ( m, c )

            else
                ( model, Cmd.none )

        SelectNextMarker ->
            let
                allItems =
                    (case model.locations of
                        Success locs ->
                            List.filter (\l -> Types.hasValidCoordinates l.point) locs
                                |> List.filter (\l -> not (List.any (\tag -> List.member tag model.hiddenTags) l.tags))
                                |> List.map (\l -> ( l.point.lat, l.point.lon, l.id ))

                        _ ->
                            []
                    )
                        ++ (visibleEvents model
                                |> List.map (\e -> ( e.point.lat, e.point.lon, e.id ))
                           )

                allIds =
                    allItems
                        |> List.sortWith
                            (\( latA, lonA, _ ) ( latB, lonB, _ ) ->
                                case compare latB latA of
                                    EQ ->
                                        compare lonB lonA

                                    other ->
                                        other
                            )
                        |> List.map (\( _, _, id ) -> id)

                currId =
                    case model.selectedMarker of
                        Just (Types.SelectedLocation l) ->
                            l.id

                        Just (Types.SelectedEvent e) ->
                            e.id

                        Nothing ->
                            ""

                nextId =
                    let
                        findNext curr lst =
                            case lst of
                                [] ->
                                    ""

                                [ x ] ->
                                    ""

                                x :: y :: rest ->
                                    if x == curr then
                                        y

                                    else
                                        findNext curr (y :: rest)

                        found =
                            findNext currId allIds
                    in
                    if found == "" then
                        Maybe.withDefault "" (List.head allIds)

                    else
                        found
            in
            if nextId /= "" then
                let
                    ( m, c ) =
                        update (MarkerClicked nextId) model
                in
                ( m, c )

            else
                ( model, Cmd.none )

        TogglePresentationMode ->
            let
                newMode =
                    not model.presentationMode

                ( m1, c1 ) =
                    if newMode && model.selectedMarker == Nothing then
                        update SelectNextMarker model

                    else
                        ( model, Cmd.none )
            in
            ( { m1 | presentationMode = newMode }, c1 )

        PresentationTick _ ->
            if model.presentationMode then
                let
                    ( m, c ) =
                        update SelectNextMarker model
                in
                ( m, c )

            else
                ( model, Cmd.none )

        KeyDown key ->
            if key == "ArrowLeft" then
                let
                    ( m, c ) =
                        update SelectPrevMarker model
                in
                ( m, c )

            else if key == "ArrowRight" then
                let
                    ( m, c ) =
                        update SelectNextMarker model
                in
                ( m, c )

            else
                ( model, Cmd.none )

        ClosePanel ->
            ( { model | selectedMarker = Nothing }, Ports.restoreMapView () )

        ToggleMenu ->
            if model.menuOpen then
                ( { model | menuOpen = False }, Component.Layout.onMenuClosed NoOp )

            else
                ( { model | menuOpen = True }, Component.Layout.onMenuOpened NoOp )

        CloseMenu ->
            -- The drawer becomes `inert` when it closes, so the browser drops
            -- focus to <body>. Put it back on the button that opened it.
            if model.menuOpen then
                ( { model | menuOpen = False }, Component.Layout.onMenuClosed NoOp )

            else
                ( model, Cmd.none )

        LoginClicked ->
            ( model, Ports.initiateOAuth model.pbBaseUrl )

        LogOut ->
            ( { model | authState = NotAuthenticated, menuOpen = False }
            , Cmd.batch
                [ menuClosedCmd model
                , Ports.clearAuthToken ()
                , Nav.pushUrl model.key (Route.toHref RouteMap)
                , Api.fetchGeoJson
                ]
            )

        OAuthPopupResult data ->
            case PocketBaseAuth.userFromPopupResult data of
                Just user ->
                    let
                        ( m, c ) =
                            addToast { model | authState = Authenticated user } Types.ToastSuccess (t model.lang LoginSuccess)
                    in
                    ( m
                    , Cmd.batch
                        [ c
                        , Ports.saveAuthToken { token = data.token, model = data.model }
                        , Api.fetchLocations model.pbBaseUrl (Just data.token)
                        ]
                    )

                Nothing ->
                    addToast model Types.ToastError (t model.lang LoginFailed)

        AuthCallbackReceived codeVerifier providerState ->
            let
                query =
                    PocketBaseAuth.callbackQuery model.url

                maybeCode =
                    query.code

                maybeState =
                    query.state
            in
            case ( maybeCode, maybeState ) of
                ( Just code, Just stateParam ) ->
                    if stateParam /= providerState then
                        let
                            ( m, c ) =
                                addToast model Types.ToastError (t model.lang LoginFailed)
                        in
                        ( m, Cmd.batch [ c, Nav.pushUrl model.key (Route.toHref RouteMap) ] )

                    else
                        ( model
                        , PocketBaseAuth.fetchOAuthToken
                            model.pbBaseUrl
                            code
                            codeVerifier
                            (PocketBaseAuth.callbackRedirectUrl model.url)
                            providerState
                            GotOAuthToken
                        )

                _ ->
                    let
                        ( m, c ) =
                            addToast model Types.ToastError (t model.lang LoginFailed)
                    in
                    ( m, Cmd.batch [ c, Nav.pushUrl model.key (Route.toHref RouteMap) ] )

        GotOAuthToken (Ok (Authenticated user)) ->
            let
                ( m, c ) =
                    addToast { model | authState = Authenticated user } Types.ToastSuccess (t model.lang LoginSuccess)
            in
            ( m
            , Cmd.batch
                [ c
                , Ports.saveAuthToken { token = user.token, model = PocketBaseAuth.authUserModelJson user }
                , Nav.pushUrl model.key (Route.toHref RouteMap)
                , Api.fetchLocations model.pbBaseUrl (Just user.token)
                ]
            )

        GotOAuthToken (Ok NotAuthenticated) ->
            ( model, Cmd.none )

        GotOAuthToken (Err err) ->
            let
                ( m, c ) =
                    addToast model Types.ToastError (Api.httpErrorToString model.lang err)
            in
            ( m, Cmd.batch [ c, Nav.pushUrl model.key (Route.toHref RouteMap) ] )

        -- Forms Shared Messages
        NewFormFieldChanged field val ->
            updateNewForm model (applyFormField field val)

        NewFormDateChanged field val ->
            updateNewForm model (applyFormDate field val)

        NewStartDatePickerChanged datePickerMsg ->
            case model.page of
                PageLocationNew newPage ->
                    let
                        ( nextPicker, maybeIso ) =
                            FinnishDatePicker.update (I18n.locale model.lang) datePickerMsg newPage.startDatePicker

                        nextForm =
                            case maybeIso of
                                Just iso ->
                                    applyFormDate "startDate" iso newPage.form

                                Nothing ->
                                    newPage.form
                    in
                    ( { model | page = PageLocationNew { newPage | startDatePicker = nextPicker, form = nextForm } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        NewEndDatePickerChanged datePickerMsg ->
            case model.page of
                PageLocationNew newPage ->
                    let
                        ( nextPicker, maybeIso ) =
                            FinnishDatePicker.update (I18n.locale model.lang) datePickerMsg newPage.endDatePicker

                        nextForm =
                            case maybeIso of
                                Just iso ->
                                    applyFormDate "endDate" iso newPage.form

                                Nothing ->
                                    newPage.form
                    in
                    ( { model | page = PageLocationNew { newPage | endDatePicker = nextPicker, form = nextForm } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        NewFormFileSelected file ->
            let
                ( m, cmd ) =
                    updateNewForm model (\form -> { form | imageFile = Just file })
            in
            ( m, Cmd.batch [ cmd, Task.perform GotImagePreview (File.toUrl file) ] )

        NewFormToggleGeocode ->
            updateNewForm model (\form -> { form | geocodingEnabled = not form.geocodingEnabled })

        NewFormToggleMapStyle ->
            case model.page of
                PageLocationNew newPage ->
                    let
                        nextStyle =
                            if newPage.mapStyle == Types.OsmStyle then
                                Types.BasemapStyle

                            else
                                Types.OsmStyle

                        styleStr =
                            if nextStyle == Types.OsmStyle then
                                "osm"

                            else
                                "basemap"
                    in
                    ( { model | page = PageLocationNew { newPage | mapStyle = nextStyle } }
                    , Ports.setMapStyle { containerId = "create-map", mapStyle = styleStr }
                    )

                _ ->
                    ( model, Cmd.none )

        NewFormOpeningHoursMsg editorMsg ->
            updateNewForm model (\form -> { form | openingHours = OpeningHours.Editor.update editorMsg form.openingHours })

        NewFormGeocode ->
            case model.page of
                PageLocationNew newPage ->
                    ( model, Geocoding.geocode newPage.form.location NewFormGotGeocode )

                _ ->
                    ( model, Cmd.none )

        NewFormGotGeocode result ->
            case result of
                Ok (Just pt) ->
                    let
                        ( model1, _ ) =
                            updateNewForm model (\form -> { form | lat = String.fromFloat pt.lat, lon = String.fromFloat pt.lon })
                    in
                    ( model1, Ports.setMapMarker { lat = pt.lat, lon = pt.lon } )

                _ ->
                    ( model, Cmd.none )

        NewFormSubmit ->
            case ( model.page, getToken model.authState ) of
                ( PageLocationNew newPage, Just token ) ->
                    if not (Types.isValidForm newPage.form) then
                        ( model, Cmd.none )

                    else
                        ( { model | page = PageLocationNew { newPage | formStatus = FormSubmitting } }
                        , Api.createLocation model.pbBaseUrl token (prepareFormForSubmit newPage.form) NewFormGotSave
                        )

                _ ->
                    ( model, Cmd.none )

        NewFormGotSave result ->
            case model.page of
                PageLocationNew newPage ->
                    case result of
                        Ok _ ->
                            let
                                ( m, c ) =
                                    addToast model Types.ToastSuccess (t model.lang LocationSaved)
                            in
                            ( { m | locations = refreshLocationsOnMutationResult result m.locations }
                            , Cmd.batch
                                [ c
                                , Nav.pushUrl model.key (Route.toHref RouteLocations)
                                , Api.fetchLocations model.pbBaseUrl (getToken model.authState)
                                ]
                            )

                        Err err ->
                            let
                                errorStr =
                                    Api.httpErrorToString model.lang err

                                ( m, c ) =
                                    addToast model Types.ToastError errorStr
                            in
                            ( { m | page = PageLocationNew { newPage | formStatus = FormError errorStr } }
                            , c
                            )

                _ ->
                    ( model, Cmd.none )

        -- Edit Form Messages
        EditGotLocation result ->
            case model.page of
                PageLocationEdit id editPage ->
                    case result of
                        Ok location ->
                            let
                                form =
                                    { emptyLocationFormData
                                        | title = location.title
                                        , description = Maybe.withDefault "" location.description
                                        , location = Maybe.withDefault "" location.location
                                        , url = Maybe.withDefault "" location.url
                                        , startDate = Maybe.withDefault "" location.startDate
                                        , endDate = Maybe.withDefault "" location.endDate
                                        , openingHours = OpeningHours.Editor.init (Maybe.withDefault "" location.openingHours)
                                        , lat = String.fromFloat location.point.lat
                                        , lon = String.fromFloat location.point.lon
                                        , existingImageUrl = Maybe.map (\img -> Api.imageUrl model.pbBaseUrl location.id img) location.image
                                        , hasExistingImage = location.image /= Nothing
                                        , state = location.state
                                        , tag = Maybe.withDefault "store" (List.head location.tags)
                                        , imageDescription = Maybe.withDefault "" location.imageDescription
                                    }
                            in
                            ( { model | page = PageLocationEdit id { editPage | location = Success location, form = form } }
                            , Ports.initMap
                                { containerId = "edit-map"
                                , lat =
                                    if location.point.lat /= 0 then
                                        location.point.lat

                                    else
                                        helsinkiLat
                                , lon =
                                    if location.point.lon /= 0 then
                                        location.point.lon

                                    else
                                        helsinkiLon
                                , zoom =
                                    if location.point.lat /= 0 then
                                        15

                                    else
                                        defaultMapZoom
                                , markerLat =
                                    if location.point.lat /= 0 then
                                        Just location.point.lat

                                    else
                                        Nothing
                                , markerLon =
                                    if location.point.lon /= 0 then
                                        Just location.point.lon

                                    else
                                        Nothing
                                , draggable = True
                                , mapStyle = "osm"
                                }
                            )

                        Err err ->
                            ( { model | page = PageLocationEdit id { editPage | location = Failure err } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        EditFormFieldChanged field val ->
            updateEditForm model (applyFormField field val)

        EditFormDateChanged field val ->
            updateEditForm model (applyFormDate field val)

        EditStartDatePickerChanged datePickerMsg ->
            case model.page of
                PageLocationEdit id editPage ->
                    let
                        ( nextPicker, maybeIso ) =
                            FinnishDatePicker.update (I18n.locale model.lang) datePickerMsg editPage.startDatePicker

                        nextForm =
                            case maybeIso of
                                Just iso ->
                                    applyFormDate "startDate" iso editPage.form

                                Nothing ->
                                    editPage.form
                    in
                    ( { model | page = PageLocationEdit id { editPage | startDatePicker = nextPicker, form = nextForm } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        EditEndDatePickerChanged datePickerMsg ->
            case model.page of
                PageLocationEdit id editPage ->
                    let
                        ( nextPicker, maybeIso ) =
                            FinnishDatePicker.update (I18n.locale model.lang) datePickerMsg editPage.endDatePicker

                        nextForm =
                            case maybeIso of
                                Just iso ->
                                    applyFormDate "endDate" iso editPage.form

                                Nothing ->
                                    editPage.form
                    in
                    ( { model | page = PageLocationEdit id { editPage | endDatePicker = nextPicker, form = nextForm } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        EditFormFileSelected file ->
            let
                ( m, cmd ) =
                    updateEditForm model (\form -> { form | imageFile = Just file })
            in
            ( m, Cmd.batch [ cmd, Task.perform GotImagePreview (File.toUrl file) ] )

        EditFormToggleGeocode ->
            updateEditForm model (\form -> { form | geocodingEnabled = not form.geocodingEnabled })

        EditFormToggleMapStyle ->
            case model.page of
                PageLocationEdit id editPage ->
                    let
                        nextStyle =
                            if editPage.mapStyle == Types.OsmStyle then
                                Types.BasemapStyle

                            else
                                Types.OsmStyle

                        styleStr =
                            if nextStyle == Types.OsmStyle then
                                "osm"

                            else
                                "basemap"
                    in
                    ( { model | page = PageLocationEdit id { editPage | mapStyle = nextStyle } }
                    , Ports.setMapStyle { containerId = "edit-map", mapStyle = styleStr }
                    )

                _ ->
                    ( model, Cmd.none )

        EditFormOpeningHoursMsg editorMsg ->
            updateEditForm model (\form -> { form | openingHours = OpeningHours.Editor.update editorMsg form.openingHours })

        EditFormGeocode ->
            case model.page of
                PageLocationEdit _ editPage ->
                    ( model, Geocoding.geocode editPage.form.location EditFormGotGeocode )

                _ ->
                    ( model, Cmd.none )

        EditFormGotGeocode result ->
            case result of
                Ok (Just pt) ->
                    let
                        ( model1, _ ) =
                            updateEditForm model (\form -> { form | lat = String.fromFloat pt.lat, lon = String.fromFloat pt.lon })
                    in
                    ( model1, Ports.setMapMarker { lat = pt.lat, lon = pt.lon } )

                _ ->
                    ( model, Cmd.none )

        EditFormSubmit ->
            case ( model.page, getToken model.authState ) of
                ( PageLocationEdit id editPage, Just token ) ->
                    if not (Types.isValidForm editPage.form) then
                        ( model, Cmd.none )

                    else
                        ( { model | page = PageLocationEdit id { editPage | formStatus = FormSubmitting } }
                        , Api.updateLocation model.pbBaseUrl token id (prepareFormForSubmit editPage.form) EditFormGotSave
                        )

                _ ->
                    ( model, Cmd.none )

        EditFormGotSave result ->
            case model.page of
                PageLocationEdit id editPage ->
                    case result of
                        Ok _ ->
                            let
                                ( m, c ) =
                                    addToast model Types.ToastSuccess (t model.lang LocationSaved)
                            in
                            ( { m | locations = refreshLocationsOnMutationResult result m.locations }
                            , Cmd.batch
                                [ c
                                , Nav.pushUrl model.key (Route.toHref RouteLocations)
                                , Api.fetchLocations model.pbBaseUrl (getToken model.authState)
                                ]
                            )

                        Err err ->
                            let
                                errorStr =
                                    Api.httpErrorToString model.lang err

                                ( m, c ) =
                                    addToast model Types.ToastError errorStr
                            in
                            ( { m | page = PageLocationEdit id { editPage | formStatus = FormError errorStr } }
                            , c
                            )

                _ ->
                    ( model, Cmd.none )

        DetailGotLocation result ->
            case model.page of
                PageLocationDetail id detPage ->
                    ( { model | page = PageLocationDetail id { detPage | location = RemoteData.fromResult result } }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        AddToast kind msgStr ->
            addToast model kind msgStr

        DismissToast id ->
            ( { model | toasts = List.filter (\t -> t.id /= id) model.toasts }, Cmd.none )

        Types.DetailDelete ->
            case model.page of
                PageLocationDetail id detPage ->
                    ( { model | page = PageLocationDetail id { detPage | deleteConfirm = True } }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        Types.DetailDeleteCancel ->
            case model.page of
                PageLocationDetail id detPage ->
                    ( { model | page = PageLocationDetail id { detPage | deleteConfirm = False } }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        Types.DetailDeleteConfirm ->
            case ( model.page, getToken model.authState ) of
                ( PageLocationDetail id _, Just token ) ->
                    ( model
                    , Api.updateLocationState model.pbBaseUrl token id Types.Deleted DetailGotDelete
                    )

                _ ->
                    ( model, Cmd.none )

        DetailGotDelete result ->
            case result of
                Ok _ ->
                    let
                        ( m, c ) =
                            addToast model Types.ToastSuccess (t model.lang LocationDeleted)
                    in
                    ( { m | locations = refreshLocationsOnMutationResult result m.locations }
                    , Cmd.batch
                        [ c
                        , Nav.pushUrl model.key (Route.toHref RouteLocations)
                        , Api.fetchLocations model.pbBaseUrl (getToken model.authState)
                        ]
                    )

                Err err ->
                    addToast model Types.ToastError (Api.httpErrorToString model.lang err)

        LocationKmlFileSelected file ->
            case model.page of
                PageLocations locPage ->
                    ( { model | page = PageLocations { locPage | kmlImportStatus = Types.KmlParsing } }
                    , Task.perform LocationKmlGotContent (File.toString file)
                    )

                _ ->
                    ( model, Cmd.none )

        LocationKmlGotContent content ->
            ( model, Ports.parseKml content )

        LocationKmlParsed value ->
            case model.page of
                PageLocations locPage ->
                    case Decode.decodeValue (Decode.list Types.decodeKmlPlacemark) value of
                        Ok placemarks ->
                            let
                                newLocPage =
                                    { locPage
                                        | kmlQueue = placemarks
                                        , importCount = 0
                                        , kmlImportStatus = Types.KmlImporting 0 (List.length placemarks)
                                    }
                            in
                            ( { model | page = PageLocations newLocPage }
                            , Task.perform (\_ -> LocationKmlImportNext (Ok { id = "", title = "", description = Nothing, startDate = Nothing, endDate = Nothing, location = Nothing, url = Nothing, image = Nothing, imageDescription = Nothing, point = { lat = 0, lon = 0 }, tags = [], openingHours = Nothing, state = Types.Draft })) (Task.succeed ())
                            )

                        Err err ->
                            let
                                ( m, c ) =
                                    addToast model Types.ToastError (t model.lang KmlParseFailed)
                            in
                            ( { m | page = PageLocations { locPage | kmlImportStatus = Types.KmlError (t model.lang KmlParseError) } }, c )

                _ ->
                    ( model, Cmd.none )

        LocationKmlImportNext _ ->
            case ( model.page, getToken model.authState ) of
                ( PageLocations locPage, Just token ) ->
                    case locPage.kmlQueue of
                        [] ->
                            let
                                newLocPage =
                                    { locPage | kmlImportStatus = Types.KmlDone locPage.importCount }

                                ( m, c ) =
                                    addToast model Types.ToastSuccess (I18n.importedCount model.lang locPage.importCount)
                            in
                            ( { m | page = PageLocations newLocPage }
                            , Cmd.batch [ c, Api.fetchLocations model.pbBaseUrl (Just token) ]
                            )

                        pm :: rest ->
                            let
                                newLocPage =
                                    { locPage
                                        | kmlQueue = rest
                                        , importCount = locPage.importCount + 1
                                        , kmlImportStatus = Types.KmlImporting (locPage.importCount + 1) (locPage.importCount + 1 + List.length rest)
                                    }

                                latLonStr =
                                    case ( pm.lat, pm.lon ) of
                                        ( Just lat, Just lon ) ->
                                            { lat = String.fromFloat lat, lon = String.fromFloat lon }

                                        _ ->
                                            { lat = "", lon = "" }

                                formData =
                                    { emptyLocationFormData
                                        | title = pm.name
                                        , description = pm.description
                                        , state = Types.Draft
                                        , tag = "other"
                                        , lat = latLonStr.lat
                                        , lon = latLonStr.lon
                                        , geocodingEnabled = True
                                    }
                            in
                            ( { model | page = PageLocations newLocPage }
                            , Api.createLocation model.pbBaseUrl token (prepareFormForSubmit formData) LocationKmlImportNext
                            )

                _ ->
                    ( model, Cmd.none )

        MapMarkerMoved lat lon ->
            let
                latStr =
                    String.fromFloat lat

                lonStr =
                    String.fromFloat lon
            in
            case model.page of
                PageLocationNew _ ->
                    let
                        ( model1, _ ) =
                            updateNewForm model (\form -> { form | lat = latStr, lon = lonStr })
                    in
                    ( model1, Geocoding.reverseGeocode lat lon GotReverseGeocode )

                PageLocationEdit _ _ ->
                    let
                        ( model1, _ ) =
                            updateEditForm model (\form -> { form | lat = latStr, lon = lonStr })
                    in
                    ( model1, Geocoding.reverseGeocode lat lon GotReverseGeocode )

                _ ->
                    ( model, Cmd.none )

        GotReverseGeocode result ->
            case result of
                Ok address ->
                    case model.page of
                        PageLocationNew _ ->
                            updateNewForm model (\form -> { form | location = address })

                        PageLocationEdit _ _ ->
                            updateEditForm model (\form -> { form | location = address })

                        _ ->
                            ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        GotImagePreview url ->
            case model.page of
                PageLocationNew _ ->
                    updateNewForm model (\form -> { form | imagePreviewUrl = Just url })

                PageLocationEdit _ _ ->
                    updateEditForm model (\form -> { form | imagePreviewUrl = Just url })

                _ ->
                    ( model, Cmd.none )

        ToggleTagVisibility tag isHidden ->
            let
                newHiddenTags =
                    if isHidden then
                        tag :: List.filter (\t -> t /= tag) model.hiddenTags

                    else
                        List.filter (\t -> t /= tag) model.hiddenTags

                newModel =
                    { model | hiddenTags = newHiddenTags }
            in
            ( newModel, Cmd.batch [ updateMarkers newModel, saveFilters newModel ] )

        CycleEventFilter ->
            let
                newModel =
                    { model | eventFilter = nextEventFilter model.eventFilter }
            in
            ( newModel, Cmd.batch [ updateMarkers newModel, saveFilters newModel ] )


saveFilters : Model -> Cmd Msg
saveFilters model =
    Ports.saveFilterState
        { hiddenTags = model.hiddenTags
        , eventsFilter = Types.eventFilterToString model.eventFilter
        }


updateNewForm : Model -> (LocationFormData -> LocationFormData) -> ( Model, Cmd Msg )
updateNewForm model transform =
    case model.page of
        PageLocationNew newPage ->
            ( { model | page = PageLocationNew { newPage | form = transform newPage.form } }, Cmd.none )

        _ ->
            ( model, Cmd.none )


updateEditForm : Model -> (LocationFormData -> LocationFormData) -> ( Model, Cmd Msg )
updateEditForm model transform =
    case model.page of
        PageLocationEdit id editPage ->
            ( { model | page = PageLocationEdit id { editPage | form = transform editPage.form } }, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| Currently an identity function. Kept for future pre-submission processing like trimming or validation.
-}
prepareFormForSubmit : LocationFormData -> LocationFormData
prepareFormForSubmit form =
    form


applyFormField : String -> String -> LocationFormData -> LocationFormData
applyFormField field val form =
    case field of
        "title" ->
            { form | title = val }

        "location" ->
            { form | location = val }

        "description" ->
            { form | description = val }

        "url" ->
            { form | url = val }

        "imageDescription" ->
            { form | imageDescription = val }

        "lat" ->
            { form | lat = val }

        "lon" ->
            { form | lon = val }

        "state" ->
            case Types.locationStateFromString val of
                Just stateVal ->
                    { form | state = stateVal }

                Nothing ->
                    form

        "tag" ->
            { form | tag = val }

        _ ->
            form


applyFormDate : String -> String -> LocationFormData -> LocationFormData
applyFormDate field val form =
    case field of
        "startDate" ->
            { form | startDate = val }

        "endDate" ->
            { form | endDate = val }

        _ ->
            form


refreshLocationsOnMutationResult : Result Http.Error Location -> RemoteData Http.Error (List Location) -> RemoteData Http.Error (List Location)
refreshLocationsOnMutationResult result locations =
    case result of
        Ok _ ->
            RemoteData.Loading

        Err _ ->
            locations


addToast : Model -> Types.ToastKind -> String -> ( Model, Cmd Msg )
addToast model kind message =
    let
        newToast =
            { id = model.nextToastId
            , kind = kind
            , message = message
            }
    in
    ( { model
        | toasts = model.toasts ++ [ newToast ]
        , nextToastId = model.nextToastId + 1
      }
    , Cmd.none
    )


{-| Second line of a location's map tooltip: its opening hours, formatted.

Shared by `locationToMarker` and the `focusMapOnMarker` command so that hovering
a marker, zooming past the auto-open level and opening the info pane all produce
the same tooltip. They used to disagree — the pane's tooltip showed the
start/end date here instead — which read as two different tooltips for one
marker.

Unparseable opening hours yield "", matching the marker tooltip's existing
behaviour of showing a bare title rather than raw OSM syntax.

-}
locationTooltipSubtitle : Lang -> Location -> String
locationTooltipSubtitle lang loc =
    case loc.openingHours of
        Just oh ->
            if String.trim oh == "" then
                ""

            else
                case OHParser.parse oh of
                    Ok parsed ->
                        OHViewer.formatToString (OHI18n.forCode (Lang.toString lang)) parsed

                    Err _ ->
                        ""

        Nothing ->
            ""


locationToMarker : Lang -> Location -> MarkerData
locationToMarker lang loc =
    { id = loc.id
    , lat = loc.point.lat
    , lon = loc.point.lon
    , title = loc.title
    , date = locationTooltipSubtitle lang loc
    , isEvent = False
    , tags = loc.tags
    , cancelled = False
    }


eventToMarker : Lang -> Types.Event -> MarkerData
eventToMarker lang ev =
    { id = ev.id
    , lat = ev.point.lat
    , lon = ev.point.lon
    , title = ev.title
    , date = Maybe.withDefault "" (DateUtils.formatEventDateDisplay lang ev)
    , isEvent = True
    , tags = []
    , cancelled = ev.cancelled
    }


{-| Events the current filter lets through, with unlocated ones dropped. Shared by
marker rendering and keyboard marker navigation so all three stay in agreement. Takes an
extensible record rather than the `Model` so it is reachable from tests, which cannot
construct a `Nav.Key`.
-}
visibleEvents : { a | eventFilter : EventFilter, events : RemoteData Http.Error (List Event) } -> List Event
visibleEvents model =
    case ( model.eventFilter, model.events ) of
        ( NoEvents, _ ) ->
            []

        ( filter, Success evts ) ->
            evts
                |> List.filter
                    (\e ->
                        Types.hasValidCoordinates e.point
                            && (filter == AllEvents || not e.cancelled)
                    )

        _ ->
            []


{-| Cycle order of the tri-state events filter control.
-}
nextEventFilter : EventFilter -> EventFilter
nextEventFilter filter =
    case filter of
        AllEvents ->
            HideCancelled

        HideCancelled ->
            NoEvents

        NoEvents ->
            AllEvents


updateMarkers : Model -> Cmd Msg
updateMarkers model =
    let
        locMarkers =
            case model.locations of
                Success locations ->
                    locations
                        |> List.filter (\l -> Types.hasValidCoordinates l.point)
                        |> List.filter (\l -> not (List.any (\tag -> List.member tag model.hiddenTags) l.tags))
                        |> List.map (locationToMarker model.lang)

                _ ->
                    []

        evtMarkers =
            visibleEvents model
                |> List.map (eventToMarker model.lang)
    in
    Ports.addMarkers (locMarkers ++ evtMarkers)


escapeDecoder : Decode.Decoder Msg
escapeDecoder =
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\key ->
                if key == "Escape" then
                    Decode.succeed ClosePanel

                else
                    Decode.fail "Not Escape"
            )


escapeToLocationsDecoder : Decode.Decoder Msg
escapeToLocationsDecoder =
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\key ->
                if key == "Escape" then
                    Decode.succeed (NavigateTo RouteLocations)

                else
                    Decode.fail "Not Escape"
            )


ctrlEnterDecoder : Msg -> Decode.Decoder Msg
ctrlEnterDecoder msg =
    Decode.map2 (\key ctrl -> { key = key, ctrl = ctrl })
        (Decode.field "key" Decode.string)
        (Decode.field "ctrlKey" Decode.bool)
        |> Decode.andThen
            (\event ->
                if (event.key == "Enter") && event.ctrl then
                    Decode.succeed msg

                else
                    Decode.fail "Not Ctrl+Enter"
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        baseSubs =
            [ Ports.markerClicked MarkerClicked
            , Ports.oauthPopupResult OAuthPopupResult
            , Ports.mapMarkerMoved (\pos -> MapMarkerMoved pos.lat pos.lon)
            , Ports.callbackParams (\params -> AuthCallbackReceived params.codeVerifier params.state)
            , Ports.kmlParsed LocationKmlParsed
            ]

        -- While the menu is open, Escape belongs to the menu alone: the page's
        -- own shortcuts (close panel, leave the form) stay off.
        escSub =
            if model.menuOpen then
                []

            else
                pageKeySubs

        pageKeySubs =
            case ( model.page, model.selectedMarker ) of
                ( Types.PageMap, Just _ ) ->
                    [ Browser.Events.onKeyDown escapeDecoder
                    , Browser.Events.onKeyDown (Decode.map KeyDown (Decode.field "key" Decode.string))
                    ]

                ( Types.PageLocationNew _, _ ) ->
                    [ Browser.Events.onKeyDown escapeToLocationsDecoder
                    , Browser.Events.onKeyDown (ctrlEnterDecoder NewFormSubmit)
                    ]

                ( Types.PageLocationEdit _ _, _ ) ->
                    [ Browser.Events.onKeyDown escapeToLocationsDecoder
                    , Browser.Events.onKeyDown (ctrlEnterDecoder EditFormSubmit)
                    ]

                _ ->
                    []

        menuEscSub =
            [ Component.Layout.subscriptions { isOpen = model.menuOpen, onClose = CloseMenu } ]

        presentationSub =
            if model.presentationMode then
                [ Time.every 30000 PresentationTick ]

            else
                []
    in
    Sub.batch (baseSubs ++ escSub ++ menuEscSub ++ presentationSub)


view : Model -> Browser.Document Msg
view model =
    let
        isMapPage =
            case model.page of
                PageMap ->
                    True

                _ ->
                    False

        containerClass =
            if isMapPage then
                "flex flex-col h-[100dvh] font-sans overflow-hidden"

            else
                "flex flex-col min-h-[100dvh] font-sans"
    in
    { title = model.site.site.title ++ " | " ++ Maybe.withDefault "" model.site.metadata.author
    , body =
        View.Layout.view
            { site = model.site
            , lang = model.lang
            , authState = model.authState
            , menuOpen = model.menuOpen
            , presentationMode = model.presentationMode
            , isEmbed = model.isEmbed
            , activePage = model.page
            , toasts = model.toasts
            , attributes = [ class containerClass ]
            , main =
                Html.main_
                    [ id "main-content"
                    , class "flex-1 flex flex-col items-stretch relative w-full overflow-hidden"
                    ]
                    [ case model.page of
                        PageMap ->
                            Page.Map.view model.lang model

                        PageLocations locPage ->
                            div [ class "flex-1 overflow-y-auto w-full" ]
                                [ Page.Locations.view model.lang model locPage ]

                        PageLocationNew newPage ->
                            div [ class "flex-1 overflow-y-auto w-full" ]
                                [ Page.LocationNew.view model.lang newPage ]

                        PageLocationDetail id detPage ->
                            div [ class "flex-1 overflow-y-auto w-full" ]
                                [ Page.LocationDetail.view model.lang model.pbBaseUrl model.isEmbed model.platform model.authState id detPage ]

                        PageLocationEdit id editPage ->
                            div [ class "flex-1 overflow-y-auto w-full" ]
                                [ Page.LocationEdit.view model.lang editPage ]

                        PageAuthCallback ->
                            div [ class "flex items-center justify-center flex-1 h-full w-full" ]
                                [ Component.Spinner.view { size = Component.Spinner.Medium, label = t model.lang I18n.Loading } ]

                        PageNotFound ->
                            div [ class "p-8 text-center" ] [ Html.text (t model.lang PageNotFoundText) ]

                        _ ->
                            div [] []
                    ]
            , overlays =
                [ if model.presentationMode then
                    let
                        markerId =
                            case model.selectedMarker of
                                Just (Types.SelectedLocation l) ->
                                    l.id

                                Just (Types.SelectedEvent e) ->
                                    e.id

                                Nothing ->
                                    "none"
                    in
                    Html.Keyed.node "div"
                        [ class "fixed bottom-0 left-0 right-0 h-2 z-[9999]" ]
                        [ ( markerId
                          , div
                                [ class "h-full bg-brand opacity-50"
                                , style "animation" "progress-reverse 30s linear"
                                ]
                                []
                          )
                        ]

                  else
                    Html.text ""
                ]
            }
    }


{-| Returns focus to the menu button when a message closes an open menu as a
side effect (navigation, signing out). Otherwise focus is left inside the
closed, inert drawer and drops to the top of the page.
-}
menuClosedCmd : Model -> Cmd Msg
menuClosedCmd model =
    if model.menuOpen then
        Component.Layout.onMenuClosed NoOp

    else
        Cmd.none


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
