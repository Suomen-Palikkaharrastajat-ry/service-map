module I18n exposing (MsgKey(..), eventFilterLabel, stateLabel, t)

import Types exposing (EventFilter(..), LocationState(..))


type MsgKey
    = AppTitle
    | NavbarTitle
    | NavHome
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
    | A11yMenuOpen
    | A11yMenuClose
    | A11yNavPrimary
    | A11yNavMobile


t : MsgKey -> String
t key =
    case key of
        AppTitle ->
            "Palikkakartta | Suomen Palikkaharrastajat ry"

        NavbarTitle ->
            "Palikkakartta"

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

        A11yMenuOpen ->
            "Avaa valikko"

        A11yMenuClose ->
            "Sulje valikko"

        A11yNavPrimary ->
            "Päävalikko"

        A11yNavMobile ->
            "Mobiilivalikko"


eventFilterLabel : EventFilter -> String
eventFilterLabel filter =
    case filter of
        AllEvents ->
            t FilterEventsAll

        HideCancelled ->
            t FilterEventsNoCancelled

        NoEvents ->
            t FilterEventsNone


stateLabel : LocationState -> String
stateLabel state =
    case state of
        Draft ->
            t StateDraft

        Pending ->
            t StatePending

        Published ->
            t StatePublished

        Deleted ->
            t StateDeleted
