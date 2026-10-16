module I18n exposing (MsgKey(..), contentAttrs, eventFilterLabel, importedCount, locale, stateLabel, t, translateTag)

{-| UI strings per language, keyed by MsgKey, plus state and filter labels.
-}

import Html
import Lang exposing (Lang(..))
import Locale exposing (Locale)
import Types exposing (EventFilter(..), LocationState(..))


type MsgKey
    = NavHome
    | NavLocations
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
    | FormTag
    | TagExhibition
    | TagStore
    | TagFleamarket
    | TagMuseum
    | TagOther
    | FormSave
    | FormCancel
    | FormGeocode
    | FormLat
    | FormLon
    | DetailEdit
    | DetailDelete
    | DetailDeleteConfirm
    | DetailDeleteCancel
    | DetailBack
    | DetailMoreInfo
    | LocationListTitle
    | LocationListEmpty
    | LocationListNew
    | LocationListEdit
    | KmlImport
    | KmlImporting
    | KmlDone
    | KmlError
    | FeedRss
    | FeedAtom
    | FeedJson
    | FeedGeoJson
    | ErrorNetwork
    | ErrorUnknown
    | Loading
    | Saving
    | MapLoading
    | MapLoadError
    | FilterEvents
    | FilterEventsAll
    | FilterEventsNoCancelled
    | FilterEventsNone
    | EventsModalTitle
    | EventsModalEmpty
    | EventsModalOpen
    | EventsModalShowOnMap
    | A11yEventsModalClose
    | LocationsModalEmpty
    | LocationsModalOpen
    | A11yLocationsModalClose
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

        FormTag ->
            "Tyyppi"

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

        KmlImport ->
            "Tuo KML-tiedosto"

        KmlImporting ->
            "Tuodaan..."

        KmlDone ->
            "Tuonti valmis"

        KmlError ->
            "Tuontivirhe"

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

        ErrorUnknown ->
            "Tuntematon virhe"

        Loading ->
            "Ladataan..."

        Saving ->
            "Tallennetaan..."

        MapLoading ->
            "Ladataan kohteita..."

        MapLoadError ->
            "Kohteiden lataus epäonnistui"

        FilterEvents ->
            "Tapahtumat"

        FilterEventsAll ->
            "kaikki"

        FilterEventsNoCancelled ->
            "ei peruttuja"

        FilterEventsNone ->
            "piilotettu"

        EventsModalTitle ->
            "Tulevat tapahtumat"

        EventsModalEmpty ->
            "Ei tulevia tapahtumia"

        EventsModalOpen ->
            "Näytä tapahtumalista"

        EventsModalShowOnMap ->
            "Näytä kartalla"

        A11yEventsModalClose ->
            "Sulje tapahtumalista"

        LocationsModalEmpty ->
            "Ei kohteita"

        LocationsModalOpen ->
            "Näytä kohdelista"

        A11yLocationsModalClose ->
            "Sulje kohdelista"

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

        FormTag ->
            "Type"

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

        KmlImport ->
            "Import a KML file"

        KmlImporting ->
            "Importing..."

        KmlDone ->
            "Import finished"

        KmlError ->
            "Import error"

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

        ErrorUnknown ->
            "Unknown error"

        Loading ->
            "Loading..."

        Saving ->
            "Saving..."

        MapLoading ->
            "Loading places..."

        MapLoadError ->
            "Loading the places failed"

        FilterEvents ->
            "Events"

        FilterEventsAll ->
            "all"

        FilterEventsNoCancelled ->
            "no cancelled"

        FilterEventsNone ->
            "hidden"

        EventsModalTitle ->
            "Upcoming events"

        EventsModalEmpty ->
            "No upcoming events"

        EventsModalOpen ->
            "View event list"

        EventsModalShowOnMap ->
            "Show on map"

        A11yEventsModalClose ->
            "Close event list"

        LocationsModalEmpty ->
            "No places"

        LocationsModalOpen ->
            "View place list"

        A11yLocationsModalClose ->
            "Close place list"

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


{-| Attributes for content the organisers wrote. Events and places are entered
in Finnish, so inside another interface language they are marked as Finnish for
screen readers.
-}
contentAttrs : Lang -> List (Html.Attribute msg)
contentAttrs lang =
    Lang.attributeFor { interface = lang, content = Fi }


{-| Localized tag name for display.
-}
translateTag : Lang -> String -> String
translateTag lang tag =
    case tag of
        "exhibition" ->
            t lang TagExhibition

        "store" ->
            t lang TagStore

        "fleamarket" ->
            t lang TagFleamarket

        "museum" ->
            t lang TagMuseum

        "other" ->
            t lang TagOther

        _ ->
            tag
