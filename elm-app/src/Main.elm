module Main exposing (applyFormDate, applyFormField, main)

import Api
import Auth
import Browser
import Browser.Events
import Browser.Navigation as Nav
import Component.Spinner
import Component.Toast
import Date
import DatePicker
import DateUtils
import FeatherIcons
import File
import Geocoding
import Html exposing (Html, div, main_)
import Html.Attributes exposing (class, style)
import I18n exposing (MsgKey(..), t)
import Json.Decode as Decode
import Json.Encode as Encode
import OpeningHours.Editor
import OpeningHours.I18n as OHI18n
import OpeningHours.Parser as OHParser
import OpeningHours.Viewer as OHViewer
import Page.LocationDetail
import Page.LocationEdit
import Page.LocationNew
import Page.Locations
import Page.Map
import Ports exposing (MarkerData)
import RemoteData exposing (RemoteData(..))
import Route exposing (Route(..), parseUrl)
import Task
import Time
import Types
    exposing
        ( AuthState(..)
        , AuthUser
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
import View.FinnishDatePicker as FinnishDatePicker
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
            Auth.restoreAuthFromFlags flags.authToken flags.authModel

        now =
            Time.millisToPosix flags.now

        ( page, cmd ) =
            initPage flags.pbBaseUrl key initialRoute authState url now
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
      , eventsHidden = flags.eventsHidden
      , isEmbed = flags.isEmbed
      , now = now
      , toasts = []
      , nextToastId = 0
      }
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
    )


initPage : String -> Nav.Key -> Route -> AuthState -> Url -> Time.Posix -> ( Page, Cmd Msg )
initPage pbBaseUrl key route authState url now =
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
                        , Task.perform identity (Task.succeed (Types.AddToast Types.ToastInfo "Kirjaudu sisään päästäksesi hallintanäkymään"))
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
                        , Task.perform identity (Task.succeed (Types.AddToast Types.ToastInfo "Kirjaudu sisään päästäksesi hallintanäkymään"))
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
                    initPage model.pbBaseUrl model.key newRoute model.authState url model.now

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
            , Cmd.batch [ mapCleanupCmd, cmd, extraCmd ]
            )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

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
            in
            ( { model | selectedMarker = selected }, Cmd.none )

        ClosePanel ->
            ( { model | selectedMarker = Nothing }, Cmd.none )

        ToggleMenu ->
            if model.menuOpen then
                ( { model | menuOpen = False }, Cmd.none )

            else
                ( { model | menuOpen = True }, Ports.focusMobileNav () )

        CloseMenu ->
            ( { model | menuOpen = False }, Cmd.none )

        LoginClicked ->
            ( model, Ports.initiateOAuth model.pbBaseUrl )

        LogOut ->
            ( { model | authState = NotAuthenticated, menuOpen = False }
            , Cmd.batch
                [ Ports.clearAuthToken ()
                , Nav.pushUrl model.key (Route.toHref RouteMap)
                , Api.fetchGeoJson
                ]
            )

        OAuthPopupResult data ->
            if String.isEmpty data.token then
                let
                    ( m, c ) =
                        addToast model Types.ToastError "Kirjautuminen epäonnistui"
                in
                ( m, c )

            else
                case Decode.decodeString Auth.decodeAuthUser data.model of
                    Ok user ->
                        let
                            authedUser =
                                { user | token = data.token }

                            ( m, c ) =
                                addToast { model | authState = Authenticated authedUser } Types.ToastSuccess "Kirjautuminen onnistui"
                        in
                        ( m
                        , Cmd.batch
                            [ c
                            , Ports.saveAuthToken { token = data.token, model = data.model }
                            , Api.fetchLocations model.pbBaseUrl (Just data.token)
                            ]
                        )

                    Err _ ->
                        let
                            ( m, c ) =
                                addToast model Types.ToastError "Kirjautuminen epäonnistui"
                        in
                        ( m, c )

        AuthCallbackReceived codeVerifier providerState ->
            let
                queryStr =
                    model.url.fragment
                        |> Maybe.withDefault ""
                        |> String.split "?"
                        |> List.drop 1
                        |> List.head
                        |> Maybe.withDefault ""

                parseParam key =
                    queryStr
                        |> String.split "&"
                        |> List.filterMap
                            (\pair ->
                                case String.split "=" pair of
                                    [ k, v ] ->
                                        if k == key then
                                            Just v

                                        else
                                            Nothing

                                    _ ->
                                        Nothing
                            )
                        |> List.head

                maybeCode =
                    parseParam "code"

                maybeState =
                    parseParam "state"
            in
            case ( maybeCode, maybeState ) of
                ( Just code, Just stateParam ) ->
                    if stateParam /= providerState then
                        let
                            ( m, c ) =
                                addToast model Types.ToastError "Kirjautuminen epäonnistui"
                        in
                        ( m, Cmd.batch [ c, Nav.pushUrl model.key (Route.toHref RouteMap) ] )

                    else
                        ( model
                        , Auth.fetchOAuthToken
                            model.pbBaseUrl
                            code
                            codeVerifier
                            (urlBase model.url ++ "#/callback")
                            providerState
                            GotOAuthToken
                        )

                _ ->
                    let
                        ( m, c ) =
                            addToast model Types.ToastError "Kirjautuminen epäonnistui"
                    in
                    ( m, Cmd.batch [ c, Nav.pushUrl model.key (Route.toHref RouteMap) ] )

        GotOAuthToken (Ok (Authenticated user)) ->
            let
                modelStr =
                    Encode.encode 0
                        (Encode.object
                            [ ( "id", Encode.string user.id )
                            , ( "name", Encode.string user.name )
                            , ( "email", Encode.string user.email )
                            ]
                        )

                ( m, c ) =
                    addToast { model | authState = Authenticated user } Types.ToastSuccess "Kirjautuminen onnistui"
            in
            ( m
            , Cmd.batch
                [ c
                , Ports.saveAuthToken { token = user.token, model = modelStr }
                , Nav.pushUrl model.key (Route.toHref RouteMap)
                , Api.fetchLocations model.pbBaseUrl (Just user.token)
                ]
            )

        GotOAuthToken (Ok NotAuthenticated) ->
            ( model, Cmd.none )

        GotOAuthToken (Err err) ->
            let
                ( m, c ) =
                    addToast model Types.ToastError (Api.httpErrorToString err)
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
                            FinnishDatePicker.update datePickerMsg newPage.startDatePicker

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
                            FinnishDatePicker.update datePickerMsg newPage.endDatePicker

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
                                    addToast model Types.ToastSuccess "Kohde tallennettu"
                            in
                            ( m
                            , Cmd.batch
                                [ c
                                , Nav.pushUrl model.key (Route.toHref RouteLocations)
                                ]
                            )

                        Err err ->
                            let
                                errorStr =
                                    Api.httpErrorToString err

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
                            FinnishDatePicker.update datePickerMsg editPage.startDatePicker

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
                            FinnishDatePicker.update datePickerMsg editPage.endDatePicker

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
                                    addToast model Types.ToastSuccess "Kohde tallennettu"
                            in
                            ( m
                            , Cmd.batch
                                [ c
                                , Nav.pushUrl model.key (Route.toHref RouteLocations)
                                ]
                            )

                        Err err ->
                            let
                                errorStr =
                                    Api.httpErrorToString err

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
                            addToast model Types.ToastSuccess "Kohde poistettu"
                    in
                    ( m
                    , Cmd.batch
                        [ c
                        , Nav.pushUrl model.key (Route.toHref RouteLocations)
                        ]
                    )

                Err err ->
                    addToast model Types.ToastError (Api.httpErrorToString err)

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
                                    addToast model Types.ToastError "KML jäsentäminen epäonnistui"
                            in
                            ( { m | page = PageLocations { locPage | kmlImportStatus = Types.KmlError "Jäsennysvirhe" } }, c )

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
                                    addToast model Types.ToastSuccess ("Tuotiin " ++ String.fromInt locPage.importCount ++ " kohdetta")
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
            ( newModel, Cmd.batch [ updateMarkers newModel, Ports.saveFilterState { hiddenTags = newModel.hiddenTags, eventsHidden = newModel.eventsHidden } ] )

        ToggleEventVisibility isHidden ->
            let
                newModel =
                    { model | eventsHidden = isHidden }
            in
            ( newModel, Cmd.batch [ updateMarkers newModel, Ports.saveFilterState { hiddenTags = newModel.hiddenTags, eventsHidden = newModel.eventsHidden } ] )


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


getToken : AuthState -> Maybe String
getToken authState =
    case authState of
        Authenticated user ->
            Just user.token

        NotAuthenticated ->
            Nothing


urlBase : Url -> String
urlBase url =
    Url.toString { url | query = Nothing, fragment = Nothing }


locationToMarker : Location -> MarkerData
locationToMarker loc =
    let
        formattedOh =
            case loc.openingHours of
                Just oh ->
                    if String.trim oh == "" then
                        ""

                    else
                        case OHParser.parse oh of
                            Ok parsed ->
                                OHViewer.formatToString OHI18n.finnish parsed

                            Err _ ->
                                ""

                Nothing ->
                    ""
    in
    { id = loc.id
    , lat = loc.point.lat
    , lon = loc.point.lon
    , title = loc.title
    , date = formattedOh
    , isEvent = False
    , tags = loc.tags
    }


eventToMarker : Types.Event -> MarkerData
eventToMarker ev =
    { id = ev.id
    , lat = ev.point.lat
    , lon = ev.point.lon
    , title = ev.title
    , date = Maybe.withDefault "" (DateUtils.formatEventDateDisplay ev)
    , isEvent = True
    , tags = []
    }


updateMarkers : Model -> Cmd Msg
updateMarkers model =
    let
        locMarkers =
            case model.locations of
                Success locations ->
                    locations
                        |> List.filter (\l -> Types.hasValidCoordinates l.point)
                        |> List.filter (\l -> not (List.any (\tag -> List.member tag model.hiddenTags) l.tags))
                        |> List.map locationToMarker

                _ ->
                    []

        evtMarkers =
            if model.eventsHidden then
                []

            else
                case model.events of
                    Success events ->
                        events
                            |> List.filter (\e -> Types.hasValidCoordinates e.point)
                            |> List.map eventToMarker

                    _ ->
                        []
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

        escSub =
            case ( model.page, model.selectedMarker ) of
                ( Types.PageMap, Just _ ) ->
                    [ Browser.Events.onKeyDown escapeDecoder ]

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
    in
    Sub.batch (baseSubs ++ escSub)


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
    { title = t AppTitle
    , body =
        [ div [ class containerClass ]
            [ if model.isEmbed then
                Html.text ""

              else
                View.Layout.viewHeader model.authState model.menuOpen
            , if model.isEmbed then
                Html.text ""

              else
                View.Layout.viewMobileOverlay model.menuOpen
            , if model.isEmbed then
                Html.text ""

              else
                View.Layout.viewMobileDrawer model.menuOpen model.page model.authState
            , Html.main_ [ class "flex-1 flex flex-col items-stretch relative w-full overflow-hidden" ]
                [ case model.page of
                    PageMap ->
                        Page.Map.view model

                    PageLocations locPage ->
                        div [ class "flex-1 overflow-y-auto w-full" ]
                            [ Page.Locations.view model locPage ]

                    PageLocationNew newPage ->
                        div [ class "flex-1 overflow-y-auto w-full" ]
                            [ Page.LocationNew.view newPage ]

                    PageLocationDetail id detPage ->
                        div [ class "flex-1 overflow-y-auto w-full" ]
                            [ Page.LocationDetail.view model.pbBaseUrl model.authState id detPage ]

                    PageLocationEdit id editPage ->
                        div [ class "flex-1 overflow-y-auto w-full" ]
                            [ Page.LocationEdit.view editPage ]

                    PageAuthCallback ->
                        div [ class "flex items-center justify-center flex-1 h-full w-full" ]
                            [ Component.Spinner.view { size = Component.Spinner.Medium, label = t I18n.Loading } ]

                    PageNotFound ->
                        div [ class "p-8 text-center" ] [ Html.text "404 - Sivua ei löytynyt" ]

                    _ ->
                        div [] []
                ]
            , if isMapPage then
                Html.text ""

              else
                View.Layout.viewFooter
            , if isMapPage then
                Html.text ""

              else
                View.Layout.viewBrandFooter
            , viewToasts model
            ]
        ]
    }


viewToasts : Model -> Html Msg
viewToasts model =
    div [ class "fixed bottom-0 right-0 z-50 p-4 space-y-4 pointer-events-none w-full max-w-sm" ]
        (List.map viewToast model.toasts)


viewToast : Types.Toast -> Html Msg
viewToast toast =
    div [ class "pointer-events-auto" ]
        [ Component.Toast.view
            { title = ""
            , body = toast.message
            , variant =
                case toast.kind of
                    Types.ToastInfo ->
                        Component.Toast.Default

                    Types.ToastSuccess ->
                        Component.Toast.Success

                    Types.ToastError ->
                        Component.Toast.Danger
            , onClose = Just (DismissToast toast.id)
            }
        ]


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
