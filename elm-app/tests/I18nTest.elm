module I18nTest exposing (suite)

import Expect
import I18n exposing (MsgKey(..), stateLabel, t)
import Test exposing (Test, describe, test)
import Types exposing (LocationState(..))


suite : Test
suite =
    describe "I18n"
        [ describe "stateLabel"
            [ test "Draft → Luonnos" <|
                \_ -> stateLabel Draft |> Expect.equal "Luonnos"
            , test "Published → Julkaistu" <|
                \_ -> stateLabel Published |> Expect.equal "Julkaistu"
            , test "Pending → Odottaa" <|
                \_ -> stateLabel Pending |> Expect.equal "Odottaa"
            , test "Deleted → Poistettu" <|
                \_ -> stateLabel Deleted |> Expect.equal "Poistettu"
            ]
        , describe "translate"
            [ test "AppTitle is non-empty" <|
                \_ -> t AppTitle |> String.isEmpty |> Expect.equal False
            , test "NavbarTitle is non-empty" <|
                \_ -> t NavbarTitle |> String.isEmpty |> Expect.equal False
            , test "NavHome is non-empty" <|
                \_ -> t NavHome |> String.isEmpty |> Expect.equal False
            , test "NavLocations is non-empty" <|
                \_ -> t NavLocations |> String.isEmpty |> Expect.equal False
            , test "NavLogin is non-empty" <|
                \_ -> t NavLogin |> String.isEmpty |> Expect.equal False
            , test "NavLogout is non-empty" <|
                \_ -> t NavLogout |> String.isEmpty |> Expect.equal False
            , test "StateDraft is non-empty" <|
                \_ -> t StateDraft |> String.isEmpty |> Expect.equal False
            , test "StatePending is non-empty" <|
                \_ -> t StatePending |> String.isEmpty |> Expect.equal False
            , test "StatePublished is non-empty" <|
                \_ -> t StatePublished |> String.isEmpty |> Expect.equal False
            , test "StateDeleted is non-empty" <|
                \_ -> t StateDeleted |> String.isEmpty |> Expect.equal False
            , test "FormTitle is non-empty" <|
                \_ -> t FormTitle |> String.isEmpty |> Expect.equal False
            , test "FormLocation is non-empty" <|
                \_ -> t FormLocation |> String.isEmpty |> Expect.equal False
            , test "FormDescription is non-empty" <|
                \_ -> t FormDescription |> String.isEmpty |> Expect.equal False
            , test "FormUrl is non-empty" <|
                \_ -> t FormUrl |> String.isEmpty |> Expect.equal False
            , test "FormImage is non-empty" <|
                \_ -> t FormImage |> String.isEmpty |> Expect.equal False
            , test "FormImageAlt is non-empty" <|
                \_ -> t FormImageAlt |> String.isEmpty |> Expect.equal False
            , test "FormStartDate is non-empty" <|
                \_ -> t FormStartDate |> String.isEmpty |> Expect.equal False
            , test "FormEndDate is non-empty" <|
                \_ -> t FormEndDate |> String.isEmpty |> Expect.equal False
            , test "FormStatus is non-empty" <|
                \_ -> t FormStatus |> String.isEmpty |> Expect.equal False
            , test "FormOpeningHours is non-empty" <|
                \_ -> t FormOpeningHours |> String.isEmpty |> Expect.equal False
            , test "FormTag is non-empty" <|
                \_ -> t FormTag |> String.isEmpty |> Expect.equal False
            , test "TagNone is non-empty" <|
                \_ -> t TagNone |> String.isEmpty |> Expect.equal False
            , test "TagExhibition is non-empty" <|
                \_ -> t TagExhibition |> String.isEmpty |> Expect.equal False
            , test "TagStore is non-empty" <|
                \_ -> t TagStore |> String.isEmpty |> Expect.equal False
            , test "TagFleamarket is non-empty" <|
                \_ -> t TagFleamarket |> String.isEmpty |> Expect.equal False
            , test "TagMuseum is non-empty" <|
                \_ -> t TagMuseum |> String.isEmpty |> Expect.equal False
            , test "TagOther is non-empty" <|
                \_ -> t TagOther |> String.isEmpty |> Expect.equal False
            , test "FormSave is non-empty" <|
                \_ -> t FormSave |> String.isEmpty |> Expect.equal False
            , test "FormCancel is non-empty" <|
                \_ -> t FormCancel |> String.isEmpty |> Expect.equal False
            , test "FormGeocode is non-empty" <|
                \_ -> t FormGeocode |> String.isEmpty |> Expect.equal False
            , test "FormManualCoords is non-empty" <|
                \_ -> t FormManualCoords |> String.isEmpty |> Expect.equal False
            , test "FormLat is non-empty" <|
                \_ -> t FormLat |> String.isEmpty |> Expect.equal False
            , test "FormLon is non-empty" <|
                \_ -> t FormLon |> String.isEmpty |> Expect.equal False
            , test "DetailEdit is non-empty" <|
                \_ -> t DetailEdit |> String.isEmpty |> Expect.equal False
            , test "DetailDelete is non-empty" <|
                \_ -> t DetailDelete |> String.isEmpty |> Expect.equal False
            , test "DetailDeleteConfirm is non-empty" <|
                \_ -> t DetailDeleteConfirm |> String.isEmpty |> Expect.equal False
            , test "DetailDeleteCancel is non-empty" <|
                \_ -> t DetailDeleteCancel |> String.isEmpty |> Expect.equal False
            , test "DetailBack is non-empty" <|
                \_ -> t DetailBack |> String.isEmpty |> Expect.equal False
            , test "DetailLocation is non-empty" <|
                \_ -> t DetailLocation |> String.isEmpty |> Expect.equal False
            , test "DetailMoreInfo is non-empty" <|
                \_ -> t DetailMoreInfo |> String.isEmpty |> Expect.equal False
            , test "LocationListTitle is non-empty" <|
                \_ -> t LocationListTitle |> String.isEmpty |> Expect.equal False
            , test "LocationListEmpty is non-empty" <|
                \_ -> t LocationListEmpty |> String.isEmpty |> Expect.equal False
            , test "LocationListNew is non-empty" <|
                \_ -> t LocationListNew |> String.isEmpty |> Expect.equal False
            , test "LocationListEdit is non-empty" <|
                \_ -> t LocationListEdit |> String.isEmpty |> Expect.equal False
            , test "LocationListPage is non-empty" <|
                \_ -> t LocationListPage |> String.isEmpty |> Expect.equal False
            , test "LocationListOf is non-empty" <|
                \_ -> t LocationListOf |> String.isEmpty |> Expect.equal False
            , test "KmlImport is non-empty" <|
                \_ -> t KmlImport |> String.isEmpty |> Expect.equal False
            , test "KmlImporting is non-empty" <|
                \_ -> t KmlImporting |> String.isEmpty |> Expect.equal False
            , test "KmlDone is non-empty" <|
                \_ -> t KmlDone |> String.isEmpty |> Expect.equal False
            , test "KmlError is non-empty" <|
                \_ -> t KmlError |> String.isEmpty |> Expect.equal False
            , test "LoginPrompt is non-empty" <|
                \_ -> t LoginPrompt |> String.isEmpty |> Expect.equal False
            , test "LoginButton is non-empty" <|
                \_ -> t LoginButton |> String.isEmpty |> Expect.equal False
            , test "LogoutButton is non-empty" <|
                \_ -> t LogoutButton |> String.isEmpty |> Expect.equal False
            , test "AuthFailed is non-empty" <|
                \_ -> t AuthFailed |> String.isEmpty |> Expect.equal False
            , test "ContactEmail is non-empty" <|
                \_ -> t ContactEmail |> String.isEmpty |> Expect.equal False
            , test "FeedRss is non-empty" <|
                \_ -> t FeedRss |> String.isEmpty |> Expect.equal False
            , test "FeedAtom is non-empty" <|
                \_ -> t FeedAtom |> String.isEmpty |> Expect.equal False
            , test "FeedJson is non-empty" <|
                \_ -> t FeedJson |> String.isEmpty |> Expect.equal False
            , test "FeedGeoJson is non-empty" <|
                \_ -> t FeedGeoJson |> String.isEmpty |> Expect.equal False
            , test "ErrorNetwork is non-empty" <|
                \_ -> t ErrorNetwork |> String.isEmpty |> Expect.equal False
            , test "ErrorNotFound is non-empty" <|
                \_ -> t ErrorNotFound |> String.isEmpty |> Expect.equal False
            , test "ErrorUnknown is non-empty" <|
                \_ -> t ErrorUnknown |> String.isEmpty |> Expect.equal False
            , test "Loading is non-empty" <|
                \_ -> t Loading |> String.isEmpty |> Expect.equal False
            , test "Saving is non-empty" <|
                \_ -> t Saving |> String.isEmpty |> Expect.equal False
            , test "GeocodingSearching is non-empty" <|
                \_ -> t GeocodingSearching |> String.isEmpty |> Expect.equal False
            , test "GeocodingNotFound is non-empty" <|
                \_ -> t GeocodingNotFound |> String.isEmpty |> Expect.equal False
            , test "GeocodingError is non-empty" <|
                \_ -> t GeocodingError |> String.isEmpty |> Expect.equal False
            , test "SaveSuccess is non-empty" <|
                \_ -> t SaveSuccess |> String.isEmpty |> Expect.equal False
            , test "DeleteSuccess is non-empty" <|
                \_ -> t DeleteSuccess |> String.isEmpty |> Expect.equal False
            , test "ImportSuccess is non-empty" <|
                \_ -> t ImportSuccess |> String.isEmpty |> Expect.equal False
            , test "SubmitByEmailText is non-empty" <|
                \_ -> t SubmitByEmailText |> String.isEmpty |> Expect.equal False
            , test "SubmitByEmailLinkText is non-empty" <|
                \_ -> t SubmitByEmailLinkText |> String.isEmpty |> Expect.equal False
            , test "MapLoading is non-empty" <|
                \_ -> t MapLoading |> String.isEmpty |> Expect.equal False
            , test "MapLoadError is non-empty" <|
                \_ -> t MapLoadError |> String.isEmpty |> Expect.equal False
            , test "MapLocationsOnMap is non-empty" <|
                \_ -> t MapLocationsOnMap |> String.isEmpty |> Expect.equal False
            , test "PanelMoreInfo is non-empty" <|
                \_ -> t PanelMoreInfo |> String.isEmpty |> Expect.equal False
            ]
        ]
