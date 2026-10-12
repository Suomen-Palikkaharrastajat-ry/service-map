module I18nTest exposing (suite)

{-| Test suite for I18n translation keys and localized labels.
-}

import Expect
import I18n exposing (MsgKey(..), eventFilterLabel, stateLabel, t)
import Lang
import Test exposing (Test, describe, test)
import Types exposing (EventFilter(..), LocationState(..))


suite : Test
suite =
    describe "I18n"
        [ describe "stateLabel"
            [ test "Draft → Luonnos" <|
                \_ -> stateLabel Lang.Fi Draft |> Expect.equal "Luonnos"
            , test "Published → Julkaistu" <|
                \_ -> stateLabel Lang.Fi Published |> Expect.equal "Julkaistu"
            , test "Pending → Odottaa" <|
                \_ -> stateLabel Lang.Fi Pending |> Expect.equal "Odottaa"
            , test "Deleted → Poistettu" <|
                \_ -> stateLabel Lang.Fi Deleted |> Expect.equal "Poistettu"
            ]
        , describe "translate"
            [ test "NavHome is non-empty" <|
                \_ -> t Lang.Fi NavHome |> String.isEmpty |> Expect.equal False
            , test "NavLocations is non-empty" <|
                \_ -> t Lang.Fi NavLocations |> String.isEmpty |> Expect.equal False
            , test "NavLogin is non-empty" <|
                \_ -> t Lang.Fi NavLogin |> String.isEmpty |> Expect.equal False
            , test "NavLogout is non-empty" <|
                \_ -> t Lang.Fi NavLogout |> String.isEmpty |> Expect.equal False
            , test "StateDraft is non-empty" <|
                \_ -> t Lang.Fi StateDraft |> String.isEmpty |> Expect.equal False
            , test "StatePending is non-empty" <|
                \_ -> t Lang.Fi StatePending |> String.isEmpty |> Expect.equal False
            , test "StatePublished is non-empty" <|
                \_ -> t Lang.Fi StatePublished |> String.isEmpty |> Expect.equal False
            , test "StateDeleted is non-empty" <|
                \_ -> t Lang.Fi StateDeleted |> String.isEmpty |> Expect.equal False
            , test "FormTitle is non-empty" <|
                \_ -> t Lang.Fi FormTitle |> String.isEmpty |> Expect.equal False
            , test "FormLocation is non-empty" <|
                \_ -> t Lang.Fi FormLocation |> String.isEmpty |> Expect.equal False
            , test "FormDescription is non-empty" <|
                \_ -> t Lang.Fi FormDescription |> String.isEmpty |> Expect.equal False
            , test "FormUrl is non-empty" <|
                \_ -> t Lang.Fi FormUrl |> String.isEmpty |> Expect.equal False
            , test "FormImage is non-empty" <|
                \_ -> t Lang.Fi FormImage |> String.isEmpty |> Expect.equal False
            , test "FormImageAlt is non-empty" <|
                \_ -> t Lang.Fi FormImageAlt |> String.isEmpty |> Expect.equal False
            , test "FormImagePreview is non-empty" <|
                \_ -> t Lang.Fi FormImagePreview |> String.isEmpty |> Expect.equal False
            , test "FormImageCurrent is non-empty" <|
                \_ -> t Lang.Fi FormImageCurrent |> String.isEmpty |> Expect.equal False
            , test "FormStartDate is non-empty" <|
                \_ -> t Lang.Fi FormStartDate |> String.isEmpty |> Expect.equal False
            , test "FormEndDate is non-empty" <|
                \_ -> t Lang.Fi FormEndDate |> String.isEmpty |> Expect.equal False
            , test "FormStatus is non-empty" <|
                \_ -> t Lang.Fi FormStatus |> String.isEmpty |> Expect.equal False
            , test "FormOpeningHours is non-empty" <|
                \_ -> t Lang.Fi FormOpeningHours |> String.isEmpty |> Expect.equal False
            , test "FormTag is non-empty" <|
                \_ -> t Lang.Fi FormTag |> String.isEmpty |> Expect.equal False
            , test "TagNone is non-empty" <|
                \_ -> t Lang.Fi TagNone |> String.isEmpty |> Expect.equal False
            , test "TagExhibition is non-empty" <|
                \_ -> t Lang.Fi TagExhibition |> String.isEmpty |> Expect.equal False
            , test "TagStore is non-empty" <|
                \_ -> t Lang.Fi TagStore |> String.isEmpty |> Expect.equal False
            , test "TagFleamarket is non-empty" <|
                \_ -> t Lang.Fi TagFleamarket |> String.isEmpty |> Expect.equal False
            , test "TagMuseum is non-empty" <|
                \_ -> t Lang.Fi TagMuseum |> String.isEmpty |> Expect.equal False
            , test "TagOther is non-empty" <|
                \_ -> t Lang.Fi TagOther |> String.isEmpty |> Expect.equal False
            , test "FormSave is non-empty" <|
                \_ -> t Lang.Fi FormSave |> String.isEmpty |> Expect.equal False
            , test "FormCancel is non-empty" <|
                \_ -> t Lang.Fi FormCancel |> String.isEmpty |> Expect.equal False
            , test "FormGeocode is non-empty" <|
                \_ -> t Lang.Fi FormGeocode |> String.isEmpty |> Expect.equal False
            , test "FormManualCoords is non-empty" <|
                \_ -> t Lang.Fi FormManualCoords |> String.isEmpty |> Expect.equal False
            , test "FormLat is non-empty" <|
                \_ -> t Lang.Fi FormLat |> String.isEmpty |> Expect.equal False
            , test "FormLon is non-empty" <|
                \_ -> t Lang.Fi FormLon |> String.isEmpty |> Expect.equal False
            , test "DetailEdit is non-empty" <|
                \_ -> t Lang.Fi DetailEdit |> String.isEmpty |> Expect.equal False
            , test "DetailDelete is non-empty" <|
                \_ -> t Lang.Fi DetailDelete |> String.isEmpty |> Expect.equal False
            , test "DetailDeleteConfirm is non-empty" <|
                \_ -> t Lang.Fi DetailDeleteConfirm |> String.isEmpty |> Expect.equal False
            , test "DetailDeleteCancel is non-empty" <|
                \_ -> t Lang.Fi DetailDeleteCancel |> String.isEmpty |> Expect.equal False
            , test "DetailBack is non-empty" <|
                \_ -> t Lang.Fi DetailBack |> String.isEmpty |> Expect.equal False
            , test "DetailLocation is non-empty" <|
                \_ -> t Lang.Fi DetailLocation |> String.isEmpty |> Expect.equal False
            , test "DetailMoreInfo is non-empty" <|
                \_ -> t Lang.Fi DetailMoreInfo |> String.isEmpty |> Expect.equal False
            , test "LocationListTitle is non-empty" <|
                \_ -> t Lang.Fi LocationListTitle |> String.isEmpty |> Expect.equal False
            , test "LocationListEmpty is non-empty" <|
                \_ -> t Lang.Fi LocationListEmpty |> String.isEmpty |> Expect.equal False
            , test "LocationListNew is non-empty" <|
                \_ -> t Lang.Fi LocationListNew |> String.isEmpty |> Expect.equal False
            , test "LocationListEdit is non-empty" <|
                \_ -> t Lang.Fi LocationListEdit |> String.isEmpty |> Expect.equal False
            , test "LocationListPage is non-empty" <|
                \_ -> t Lang.Fi LocationListPage |> String.isEmpty |> Expect.equal False
            , test "LocationListOf is non-empty" <|
                \_ -> t Lang.Fi LocationListOf |> String.isEmpty |> Expect.equal False
            , test "KmlImport is non-empty" <|
                \_ -> t Lang.Fi KmlImport |> String.isEmpty |> Expect.equal False
            , test "KmlImporting is non-empty" <|
                \_ -> t Lang.Fi KmlImporting |> String.isEmpty |> Expect.equal False
            , test "KmlDone is non-empty" <|
                \_ -> t Lang.Fi KmlDone |> String.isEmpty |> Expect.equal False
            , test "KmlError is non-empty" <|
                \_ -> t Lang.Fi KmlError |> String.isEmpty |> Expect.equal False
            , test "LoginPrompt is non-empty" <|
                \_ -> t Lang.Fi LoginPrompt |> String.isEmpty |> Expect.equal False
            , test "LoginButton is non-empty" <|
                \_ -> t Lang.Fi LoginButton |> String.isEmpty |> Expect.equal False
            , test "LogoutButton is non-empty" <|
                \_ -> t Lang.Fi LogoutButton |> String.isEmpty |> Expect.equal False
            , test "AuthFailed is non-empty" <|
                \_ -> t Lang.Fi AuthFailed |> String.isEmpty |> Expect.equal False
            , test "ContactEmail is non-empty" <|
                \_ -> t Lang.Fi ContactEmail |> String.isEmpty |> Expect.equal False
            , test "FeedRss is non-empty" <|
                \_ -> t Lang.Fi FeedRss |> String.isEmpty |> Expect.equal False
            , test "FeedAtom is non-empty" <|
                \_ -> t Lang.Fi FeedAtom |> String.isEmpty |> Expect.equal False
            , test "FeedJson is non-empty" <|
                \_ -> t Lang.Fi FeedJson |> String.isEmpty |> Expect.equal False
            , test "FeedGeoJson is non-empty" <|
                \_ -> t Lang.Fi FeedGeoJson |> String.isEmpty |> Expect.equal False
            , test "ErrorNetwork is non-empty" <|
                \_ -> t Lang.Fi ErrorNetwork |> String.isEmpty |> Expect.equal False
            , test "ErrorNotFound is non-empty" <|
                \_ -> t Lang.Fi ErrorNotFound |> String.isEmpty |> Expect.equal False
            , test "ErrorUnknown is non-empty" <|
                \_ -> t Lang.Fi ErrorUnknown |> String.isEmpty |> Expect.equal False
            , test "Loading is non-empty" <|
                \_ -> t Lang.Fi Loading |> String.isEmpty |> Expect.equal False
            , test "Saving is non-empty" <|
                \_ -> t Lang.Fi Saving |> String.isEmpty |> Expect.equal False
            , test "GeocodingSearching is non-empty" <|
                \_ -> t Lang.Fi GeocodingSearching |> String.isEmpty |> Expect.equal False
            , test "GeocodingNotFound is non-empty" <|
                \_ -> t Lang.Fi GeocodingNotFound |> String.isEmpty |> Expect.equal False
            , test "GeocodingError is non-empty" <|
                \_ -> t Lang.Fi GeocodingError |> String.isEmpty |> Expect.equal False
            , test "SaveSuccess is non-empty" <|
                \_ -> t Lang.Fi SaveSuccess |> String.isEmpty |> Expect.equal False
            , test "DeleteSuccess is non-empty" <|
                \_ -> t Lang.Fi DeleteSuccess |> String.isEmpty |> Expect.equal False
            , test "ImportSuccess is non-empty" <|
                \_ -> t Lang.Fi ImportSuccess |> String.isEmpty |> Expect.equal False
            , test "SubmitByEmailText is non-empty" <|
                \_ -> t Lang.Fi SubmitByEmailText |> String.isEmpty |> Expect.equal False
            , test "SubmitByEmailLinkText is non-empty" <|
                \_ -> t Lang.Fi SubmitByEmailLinkText |> String.isEmpty |> Expect.equal False
            , test "MapLoading is non-empty" <|
                \_ -> t Lang.Fi MapLoading |> String.isEmpty |> Expect.equal False
            , test "MapLoadError is non-empty" <|
                \_ -> t Lang.Fi MapLoadError |> String.isEmpty |> Expect.equal False
            , test "MapLocationsOnMap is non-empty" <|
                \_ -> t Lang.Fi MapLocationsOnMap |> String.isEmpty |> Expect.equal False
            , test "PanelMoreInfo is non-empty" <|
                \_ -> t Lang.Fi PanelMoreInfo |> String.isEmpty |> Expect.equal False
            , test "FilterEvents is non-empty" <|
                \_ -> t Lang.Fi FilterEvents |> String.isEmpty |> Expect.equal False
            , test "FilterEventsAll is non-empty" <|
                \_ -> t Lang.Fi FilterEventsAll |> String.isEmpty |> Expect.equal False
            , test "FilterEventsNoCancelled is non-empty" <|
                \_ -> t Lang.Fi FilterEventsNoCancelled |> String.isEmpty |> Expect.equal False
            , test "FilterEventsNone is non-empty" <|
                \_ -> t Lang.Fi FilterEventsNone |> String.isEmpty |> Expect.equal False
            , test "FilterPanelTitle is non-empty" <|
                \_ -> t Lang.Fi FilterPanelTitle |> String.isEmpty |> Expect.equal False
            , test "FilterGroupLegend is non-empty" <|
                \_ -> t Lang.Fi FilterGroupLegend |> String.isEmpty |> Expect.equal False
            , test "EventCancelled is non-empty" <|
                \_ -> t Lang.Fi EventCancelled |> String.isEmpty |> Expect.equal False
            ]
        , describe "eventFilterLabel"
            [ test "AllEvents label is non-empty" <|
                \_ -> eventFilterLabel Lang.Fi AllEvents |> String.isEmpty |> Expect.equal False
            , test "HideCancelled label differs from AllEvents" <|
                \_ ->
                    eventFilterLabel Lang.Fi HideCancelled
                        |> Expect.notEqual (eventFilterLabel Lang.Fi AllEvents)
            , test "NoEvents label differs from HideCancelled" <|
                \_ ->
                    eventFilterLabel Lang.Fi NoEvents
                        |> Expect.notEqual (eventFilterLabel Lang.Fi HideCancelled)
            ]
        , describe "languages"
            [ test "Finnish and English have their own text" <|
                \_ ->
                    ( t Lang.Fi NavLocations, t Lang.En NavLocations )
                        |> Expect.equal ( "Kohteet", "Places" )
            , test "state labels follow the language" <|
                \_ ->
                    ( stateLabel Lang.Fi Draft, stateLabel Lang.En Draft )
                        |> Expect.equal ( "Luonnos", "Draft" )
            ]
        ]
