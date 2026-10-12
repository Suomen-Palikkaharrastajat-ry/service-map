module I18n exposing (MsgKey(..), eventFilterLabel, locale, stateLabel, t)

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
    | ContactEmail
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
    | ImportSuccess
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
    | ImportedPrefix
    | ImportedSuffix
    | PageNotFoundText
    | DateAtTime


{-| The text of a key in a language.

English is not translated yet: the site declares only Finnish in its
`config.toml`, so English falls back to Finnish until it is.

-}
t : Lang -> MsgKey -> String
t lang key =
    case lang of
        Fi ->
            fi key

        En ->
            fi key


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

        ContactEmail ->
            "palikkaharrastajatry@outlook.com"

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

        ImportSuccess ->
            "kohteet tuotu"

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

        ImportedPrefix ->
            "Tuotiin "

        ImportedSuffix ->
            " kohdetta"

        PageNotFoundText ->
            "404 - Sivua ei löytynyt"

        DateAtTime ->
            " klo "


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
