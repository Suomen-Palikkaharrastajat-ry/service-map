module I18n exposing (MsgKey(..), eventFilterLabel, importedCount, locale, stateLabel, t)

{-| UI strings per language, keyed by MsgKey, plus state and filter labels.
-}

import Lang exposing (Lang(..))
import Locale exposing (Locale)
import Types exposing (EventFilter(..), LocationState(..))


type MsgKey
    = NavHome
    | NavLocations
    | NavLogin
    | NavLogout
    | StateDraft
    | StatePending
    | StatePublished
    | StateDeleted
    | FormTitle
    | FormLocation
    | FormDescription
    | FormUrl
    | FormImage
    | FormImageAlt
    | FormImagePreview
    | FormImageCurrent
    | FormStartDate
    | FormEndDate
    | FormStatus
    | FormOpeningHours
    | FormTag
    | TagNone
    | TagExhibition
    | TagStore
    | TagFleamarket
    | TagMuseum
    | TagOther
    | FormSave
    | FormCancel
    | FormGeocode
    | FormManualCoords
    | FormLat
    | FormLon
    | DetailEdit
    | DetailDelete
    | DetailDeleteConfirm
    | DetailDeleteCancel
    | DetailBack
    | DetailLocation
    | DetailMoreInfo
    | LocationListTitle
    | LocationListEmpty
    | LocationListNew
    | LocationListEdit
    | LocationListPage
    | LocationListOf
    | KmlImport
    | KmlImporting
    | KmlDone
    | KmlError
    | LoginPrompt
    | LoginButton
    | LogoutButton
    | AuthFailed
    | FeedRss
    | FeedAtom
    | FeedJson
    | FeedGeoJson
    | ErrorNetwork
    | ErrorNotFound
    | ErrorUnknown
    | Loading
    | Saving
    | GeocodingSearching
    | GeocodingNotFound
    | GeocodingError
    | SaveSuccess
    | DeleteSuccess
    | SubmitByEmailText
    | SubmitByEmailLinkText
    | MapLoading
    | MapLoadError
    | MapLocationsOnMap
    | FilterEvents
    | FilterEventsAll
    | FilterEventsNoCancelled
    | FilterEventsNone
    | FilterPanelTitle
    | FilterGroupLegend
    | EventCancelled
    | PanelMoreInfo
    | PanelClose
      -- Accessible names for icon-only controls
    | A11yPanelClose
    | A11yPanelEdit
    | A11yPrevMarker
    | A11yNextMarker
    | A11yOpenInOsm
    | A11yOpenExternal
    | A11yPresentationStart
    | A11yPresentationStop
    | LoggedInAs
    | FeedsLabel
    | FeedsTitle
    | FeedsDescription
    | DetailDeleteQuestion
    | FormUsePreciseMap
    | ErrBadUrl
    | ErrTimeout
    | ErrNetwork
    | ErrBadRequest
    | ErrUnauthorized
    | ErrForbidden
    | ErrNotFound
    | ErrServerPrefix
    | ErrServerSuffix
    | ErrBadBody
    | LoginRequired
    | LoginSuccess
    | LoginFailed
    | LocationSaved
    | LocationDeleted
    | KmlParseFailed
    | KmlParseError
    | PageNotFoundText
    | DateAtTime


{-| The text of a key in a language.
-}
t : Lang -> MsgKey -> String
t lang key =
    case lang of
        Fi ->
            fi key

        En ->
            en key


fi : MsgKey -> String
fi key =
    case key of
        NavHome ->
            "Kartta"

        NavLocations ->
            "Kohteet"

        NavLogin ->
            "Kirjaudu sisään"

        NavLogout ->
            "Kirjaudu ulos"

        StateDraft ->
            "Luonnos"

        StatePending ->
            "Odottaa"

        StatePublished ->
            "Julkaistu"

        StateDeleted ->
            "Poistettu"

        FormTitle ->
            "Kohteen nimi"

        FormLocation ->
            "Sijainti"

        FormDescription ->
            "Kuvaus"

        FormUrl ->
            "Verkkosivu"

        FormImage ->
            "Kuva"

        FormImageAlt ->
            "Kuvan vaihtoehtoinen teksti"

        FormImagePreview ->
            "Esikatselu"

        FormImageCurrent ->
            "Nykyinen kuva"

        FormStartDate ->
            "Alkamispäivä"

        FormEndDate ->
            "Päättymispäivä"

        FormStatus ->
            "Tila"

        FormOpeningHours ->
            "Aukioloajat"

        FormTag ->
            "Tyyppi"

        TagNone ->
            "Ei mikään"

        TagExhibition ->
            "Näyttely"

        TagStore ->
            "Kauppa"

        TagFleamarket ->
            "Kirpputori"

        TagMuseum ->
            "Museo"

        TagOther ->
            "Muu"

        FormSave ->
            "Tallenna"

        FormCancel ->
            "Peruuta"

        FormGeocode ->
            "Hae koordinaatit"

        FormManualCoords ->
            "Syötä koordinaatit käsin"

        FormLat ->
            "Leveysaste"

        FormLon ->
            "Pituusaste"

        DetailEdit ->
            "Muokkaa"

        DetailDelete ->
            "Poista"

        DetailDeleteConfirm ->
            "Vahvista poisto"

        DetailDeleteCancel ->
            "Peruuta"

        DetailBack ->
            "Takaisin"

        DetailLocation ->
            "Sijainti"

        DetailMoreInfo ->
            "Lisätietoja"

        LocationListTitle ->
            "Kohteet"

        LocationListEmpty ->
            "Ei kohteita"

        LocationListNew ->
            "Luo uusi kohde"

        LocationListEdit ->
            "Muokkaa"

        LocationListPage ->
            "Sivu"

        LocationListOf ->
            "/"

        KmlImport ->
            "Tuo KML-tiedosto"

        KmlImporting ->
            "Tuodaan..."

        KmlDone ->
            "Tuonti valmis"

        KmlError ->
            "Tuontivirhe"

        LoginPrompt ->
            "Etkö ole jäsen? Lähetä kohde sähköpostilla."

        LoginButton ->
            "Kirjaudu sisään"

        LogoutButton ->
            "Kirjaudu ulos"

        AuthFailed ->
            "Kirjautuminen epäonnistui"

        FeedRss ->
            "RSS-syöte"

        FeedAtom ->
            "Atom-syöte"

        FeedJson ->
            "JSON-syöte"

        FeedGeoJson ->
            "GeoJSON"

        ErrorNetwork ->
            "Verkkovirhe"

        ErrorNotFound ->
            "Kohdetta ei löydy"

        ErrorUnknown ->
            "Tuntematon virhe"

        Loading ->
            "Ladataan..."

        Saving ->
            "Tallennetaan..."

        GeocodingSearching ->
            "Haetaan sijaintia..."

        GeocodingNotFound ->
            "Sijaintia ei löydy"

        GeocodingError ->
            "Geokoodausvirhe"

        SaveSuccess ->
            "Kohde tallennettu"

        DeleteSuccess ->
            "Kohde poistettu"

        SubmitByEmailText ->
            "Jos et ole Suomen Palikkaharrastajat ry:n jäsen,"

        SubmitByEmailLinkText ->
            "lähetä kohde meille sähköpostilla."

        MapLoading ->
            "Ladataan kohteita..."

        MapLoadError ->
            "Kohteiden lataus epäonnistui"

        MapLocationsOnMap ->
            "kohdetta kartalla"

        FilterEvents ->
            "Tapahtumat"

        FilterEventsAll ->
            "kaikki"

        FilterEventsNoCancelled ->
            "ei peruttuja"

        FilterEventsNone ->
            "piilotettu"

        FilterPanelTitle ->
            "Suodattimet"

        FilterGroupLegend ->
            "Kohteiden ja tapahtumien suodatus"

        EventCancelled ->
            "PERUTTU"

        PanelMoreInfo ->
            "Lisätietoja"

        PanelClose ->
            "Sulje"

        A11yPanelClose ->
            "Sulje tiedot"

        A11yPanelEdit ->
            "Muokkaa kohdetta"

        A11yPrevMarker ->
            "Edellinen kohde"

        A11yNextMarker ->
            "Seuraava kohde"

        A11yOpenInOsm ->
            "Näytä OpenStreetMap-kartalla (avautuu uuteen välilehteen)"

        A11yOpenExternal ->
            "Avaa kohteen verkkosivu (avautuu uuteen välilehteen)"

        A11yPresentationStart ->
            "Käynnistä esitystila"

        A11yPresentationStop ->
            "Pysäytä esitystila"

        LoggedInAs ->
            "Kirjautunut: "

        FeedsLabel ->
            "Syötteet ja vienti"

        FeedsTitle ->
            "Syötteet"

        FeedsDescription ->
            "Syötteet integroivat kohteet muihin palveluihin."

        DetailDeleteQuestion ->
            "Oletko varma, että haluat poistaa tämän kohteen?"

        FormUsePreciseMap ->
            "Käytä tarkkaa karttaa (OSM)"

        ErrBadUrl ->
            "Virheellinen URL: "

        ErrTimeout ->
            "Pyyntö aikakatkaistiin. Tarkista verkkoyhteytesi."

        ErrNetwork ->
            "Verkkovirhe. Tarkista verkkoyhteytesi."

        ErrBadRequest ->
            "Virheellinen pyyntö."

        ErrUnauthorized ->
            "Ei oikeuksia. Kirjaudu sisään uudelleen."

        ErrForbidden ->
            "Ei oikeuksia toimintoon."

        ErrNotFound ->
            "Kohdetta ei löytynyt."

        ErrServerPrefix ->
            "Palvelinvirhe ("

        ErrServerSuffix ->
            ")."

        ErrBadBody ->
            "Virhe datan käsittelyssä: "

        LoginRequired ->
            "Kirjaudu sisään päästäksesi hallintanäkymään"

        LoginSuccess ->
            "Kirjautuminen onnistui"

        LoginFailed ->
            "Kirjautuminen epäonnistui"

        LocationSaved ->
            "Kohde tallennettu"

        LocationDeleted ->
            "Kohde poistettu"

        KmlParseFailed ->
            "KML jäsentäminen epäonnistui"

        KmlParseError ->
            "Jäsennysvirhe"

        PageNotFoundText ->
            "404 - Sivua ei löytynyt"

        DateAtTime ->
            " klo "


en : MsgKey -> String
en key =
    case key of
        NavHome ->
            "Map"

        NavLocations ->
            "Places"

        NavLogin ->
            "Sign in"

        NavLogout ->
            "Sign out"

        StateDraft ->
            "Draft"

        StatePending ->
            "Pending"

        StatePublished ->
            "Published"

        StateDeleted ->
            "Deleted"

        FormTitle ->
            "Place name"

        FormLocation ->
            "Location"

        FormDescription ->
            "Description"

        FormUrl ->
            "Website"

        FormImage ->
            "Image"

        FormImageAlt ->
            "Alternative text for the image"

        FormImagePreview ->
            "Preview"

        FormImageCurrent ->
            "Current image"

        FormStartDate ->
            "Start date"

        FormEndDate ->
            "End date"

        FormStatus ->
            "Status"

        FormOpeningHours ->
            "Opening hours"

        FormTag ->
            "Type"

        TagNone ->
            "None"

        TagExhibition ->
            "Exhibition"

        TagStore ->
            "Shop"

        TagFleamarket ->
            "Flea market"

        TagMuseum ->
            "Museum"

        TagOther ->
            "Other"

        FormSave ->
            "Save"

        FormCancel ->
            "Cancel"

        FormGeocode ->
            "Look up coordinates"

        FormManualCoords ->
            "Enter coordinates manually"

        FormLat ->
            "Latitude"

        FormLon ->
            "Longitude"

        DetailEdit ->
            "Edit"

        DetailDelete ->
            "Delete"

        DetailDeleteConfirm ->
            "Confirm deletion"

        DetailDeleteCancel ->
            "Cancel"

        DetailBack ->
            "Back"

        DetailLocation ->
            "Location"

        DetailMoreInfo ->
            "More information"

        LocationListTitle ->
            "Places"

        LocationListEmpty ->
            "No places"

        LocationListNew ->
            "Create a new place"

        LocationListEdit ->
            "Edit"

        LocationListPage ->
            "Page"

        LocationListOf ->
            "/"

        KmlImport ->
            "Import a KML file"

        KmlImporting ->
            "Importing..."

        KmlDone ->
            "Import finished"

        KmlError ->
            "Import error"

        LoginPrompt ->
            "Not a member? Send the place by email."

        LoginButton ->
            "Sign in"

        LogoutButton ->
            "Sign out"

        AuthFailed ->
            "Sign-in failed"

        FeedRss ->
            "RSS feed"

        FeedAtom ->
            "Atom feed"

        FeedJson ->
            "JSON feed"

        FeedGeoJson ->
            "GeoJSON"

        ErrorNetwork ->
            "Network error"

        ErrorNotFound ->
            "Place not found"

        ErrorUnknown ->
            "Unknown error"

        Loading ->
            "Loading..."

        Saving ->
            "Saving..."

        GeocodingSearching ->
            "Looking up the location..."

        GeocodingNotFound ->
            "Location not found"

        GeocodingError ->
            "Geocoding error"

        SaveSuccess ->
            "Place saved"

        DeleteSuccess ->
            "Place deleted"

        SubmitByEmailText ->
            "If you are not a member of Suomen Palikkaharrastajat ry,"

        SubmitByEmailLinkText ->
            "send us the place by email."

        MapLoading ->
            "Loading places..."

        MapLoadError ->
            "Loading the places failed"

        MapLocationsOnMap ->
            "places on the map"

        FilterEvents ->
            "Events"

        FilterEventsAll ->
            "all"

        FilterEventsNoCancelled ->
            "no cancelled"

        FilterEventsNone ->
            "hidden"

        FilterPanelTitle ->
            "Filters"

        FilterGroupLegend ->
            "Filter places and events"

        EventCancelled ->
            "CANCELLED"

        PanelMoreInfo ->
            "More information"

        PanelClose ->
            "Close"

        A11yPanelClose ->
            "Close details"

        A11yPanelEdit ->
            "Edit place"

        A11yPrevMarker ->
            "Previous place"

        A11yNextMarker ->
            "Next place"

        A11yOpenInOsm ->
            "Show on OpenStreetMap (opens in a new tab)"

        A11yOpenExternal ->
            "Open the place's website (opens in a new tab)"

        A11yPresentationStart ->
            "Start presentation mode"

        A11yPresentationStop ->
            "Stop presentation mode"

        LoggedInAs ->
            "Signed in: "

        FeedsLabel ->
            "Feeds and export"

        FeedsTitle ->
            "Feeds"

        FeedsDescription ->
            "Feeds bring the places to other services."

        DetailDeleteQuestion ->
            "Are you sure you want to delete this place?"

        FormUsePreciseMap ->
            "Use the detailed map (OSM)"

        ErrBadUrl ->
            "Invalid URL: "

        ErrTimeout ->
            "The request timed out. Check your network connection."

        ErrNetwork ->
            "Network error. Check your network connection."

        ErrBadRequest ->
            "Invalid request."

        ErrUnauthorized ->
            "Not authorised. Sign in again."

        ErrForbidden ->
            "You are not allowed to do that."

        ErrNotFound ->
            "The place was not found."

        ErrServerPrefix ->
            "Server error ("

        ErrServerSuffix ->
            ")."

        ErrBadBody ->
            "Error processing the data: "

        LoginRequired ->
            "Sign in to manage places"

        LoginSuccess ->
            "Signed in"

        LoginFailed ->
            "Sign-in failed"

        LocationSaved ->
            "Place saved"

        LocationDeleted ->
            "Place deleted"

        KmlParseFailed ->
            "Parsing the KML failed"

        KmlParseError ->
            "Parse error"

        PageNotFoundText ->
            "404 - Page not found"

        DateAtTime ->
            " at "


eventFilterLabel : Lang -> EventFilter -> String
eventFilterLabel lang filter =
    case filter of
        AllEvents ->
            t lang FilterEventsAll

        HideCancelled ->
            t lang FilterEventsNoCancelled

        NoEvents ->
            t lang FilterEventsNone


stateLabel : Lang -> LocationState -> String
stateLabel lang state =
    case state of
        Draft ->
            t lang StateDraft

        Pending ->
            t lang StatePending

        Published ->
            t lang StatePublished

        Deleted ->
            t lang StateDeleted


{-| The date and time conventions of a language.
-}
locale : Lang -> Locale
locale lang =
    Locale.forCode (Lang.toString lang)


{-| Message after a KML import of `count` places.
-}
importedCount : Lang -> Int -> String
importedCount lang count =
    case lang of
        Fi ->
            "Tuotiin " ++ String.fromInt count ++ " kohdetta"

        En ->
            "Imported "
                ++ String.fromInt count
                ++ (if count == 1 then
                        " place"

                    else
                        " places"
                   )
