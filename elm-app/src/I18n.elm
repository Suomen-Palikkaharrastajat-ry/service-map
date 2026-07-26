module I18n exposing (MsgKey(..), stateLabel, t)

import Types exposing (LocationState(..))


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
    | PanelMoreInfo
    | PanelClose


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

        PanelMoreInfo ->
            "Lisätietoja"

        PanelClose ->
            "Sulje"


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
