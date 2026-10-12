module Page.Map exposing (view)

{-| Interactive map view page with location markers, filters, and detail drawer.
-}

import Component.Button as Button exposing (Size(..), Variant(..))
import Component.Form as Form
import Component.LoadState as LoadState
import DateUtils
import FeatherIcons
import Html exposing (Html, a, button, div, input, label, p, span, text)
import Html.Attributes exposing (attribute, checked, class, for, href, id, property, rel, target, title, type_)
import Html.Events exposing (onClick)
import I18n exposing (MsgKey(..), eventFilterLabel, t)
import Json.Encode as Encode
import OpeningHours.I18n as OHI18n
import OpeningHours.Parser as OHParser
import OpeningHours.Viewer as OHViewer
import QRCode
import RemoteData exposing (RemoteData(..))
import Route
import Set
import Svg.Attributes as SvgA
import Types exposing (Location, Model, Msg(..))
import View.Icons exposing (featherIcon)
import View.MapOverlay as MapOverlay


view : Model -> Html Msg
view model =
    div
        [ class "flex-1 w-full relative overflow-hidden flex flex-col" ]
        [ div
            [ id "map"
            , class "flex-1 w-full"
            ]
            []
        , viewStatusBadge model
        , viewToggles model
        , viewPanel model
        ]


viewStatusBadge : Model -> Html Msg
viewStatusBadge model =
    LoadState.badge
        { loadingLabel = t MapLoading
        , errorMessage = \_ -> t MapLoadError
        }
        (Types.fromRemoteData model.locations)


viewToggles : Model -> Html Msg
viewToggles model =
    let
        allTags =
            case model.locations of
                Success locations ->
                    locations
                        |> List.concatMap .tags
                        |> Set.fromList
                        |> Set.toList
                        |> List.sort

                _ ->
                    []

        localizeTag tag =
            case tag of
                "exhibition" ->
                    t TagExhibition

                "store" ->
                    t TagStore

                "fleamarket" ->
                    t TagFleamarket

                "museum" ->
                    t TagMuseum

                "other" ->
                    t TagOther

                _ ->
                    tag
    in
    if List.isEmpty allTags && (model.events == NotAsked || model.events == RemoteData.Loading) then
        text ""

    else
        MapOverlay.panel
            { position = MapOverlay.BottomLeft
            , label = Just (t FilterPanelTitle)
            }
            [ MapOverlay.filterGroup
                { legend = t FilterGroupLegend }
                ((allTags
                    |> List.map
                        (\tag ->
                            let
                                isVisible =
                                    not (List.member tag model.hiddenTags)
                            in
                            Form.checkbox
                                (Form.defaultField ("tag-filter-" ++ tag) (localizeTag tag))
                                { checked = isVisible
                                , onCheck = \chk -> ToggleTagVisibility tag (not chk)
                                }
                        )
                 )
                    ++ [ viewEventFilterToggle model ]
                )
            ]


{-| Tri-state events filter: checked (all) → indeterminate (no cancelled) → unchecked
(none). `indeterminate` is a DOM property rather than an attribute, and the visible label
always names the current state so the meaning never rests on the glyph alone.
-}
viewEventFilterToggle : Model -> Html Msg
viewEventFilterToggle model =
    let
        ariaChecked =
            case model.eventFilter of
                Types.AllEvents ->
                    "true"

                Types.HideCancelled ->
                    "mixed"

                Types.NoEvents ->
                    "false"
    in
    div [ class "flex items-center gap-2 cursor-pointer type-body-small" ]
        [ label
            [ for "event-filter-toggle"
            , class "flex items-center gap-2 cursor-pointer type-body-small"
            , title (t FilterEvents ++ ": " ++ eventFilterLabel model.eventFilter)
            ]
            [ input
                [ type_ "checkbox"
                , id "event-filter-toggle"
                , checked (model.eventFilter == Types.AllEvents)
                , property "indeterminate" (Encode.bool (model.eventFilter == Types.HideCancelled))
                , attribute "aria-checked" ariaChecked
                , onClick CycleEventFilter
                , class "rounded border border-border-default text-brand focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
                ]
                []
            , span [ class "text-brand flex-shrink-0" ] [ featherIcon FeatherIcons.calendar 14 ]
            , text (t FilterEvents)
            , span [ class "sr-only" ] [ text (": " ++ eventFilterLabel model.eventFilter) ]
            ]
        ]


viewPanel : Model -> Html Msg
viewPanel model =
    case model.selectedMarker of
        Nothing ->
            text ""

        Just (Types.SelectedLocation loc) ->
            viewLocationPanel model loc

        Just (Types.SelectedEvent ev) ->
            viewEventPanel model ev


viewLocationPanel : Model -> Location -> Html Msg
viewLocationPanel model loc =
    let
        headerActions =
            if Types.isAuthenticated model.authState then
                [ a
                    [ href (Route.toHref (Route.RouteLocationEdit loc.id))
                    , attribute "aria-label" (t A11yPanelEdit)
                    , class "text-text-subtle hover:text-brand mt-0.5 flex-shrink-0 cursor-pointer"
                    ]
                    [ featherIcon FeatherIcons.edit2 20 ]
                ]

            else
                []
    in
    MapOverlay.detailPanelWithHeaderActions
        { isOpen = True
        , onClose = ClosePanel
        , closeLabel = t A11yPanelClose
        , title = loc.title
        , headerActions = headerActions
        }
        [ case loc.startDate of
            Just _ ->
                case DateUtils.formatLocationDateDisplay { startDate = loc.startDate, endDate = loc.endDate } of
                    Just dateStr ->
                        viewField FeatherIcons.calendar dateStr

                    Nothing ->
                        text ""

            Nothing ->
                text ""
        , case loc.openingHours of
            Just oh ->
                if String.trim oh == "" then
                    text ""

                else
                    case OHParser.parse oh of
                        Ok parsed ->
                            div [ class "flex items-start gap-2 type-caption text-text-muted" ]
                                [ span [ class "flex-shrink-0 mt-0.5 text-brand" ] [ featherIcon FeatherIcons.clock 16 ]
                                , OHViewer.view OHI18n.finnish parsed
                                ]

                        Err _ ->
                            viewField FeatherIcons.clock oh

            Nothing ->
                text ""
        , case loc.location of
            Just address ->
                let
                    mapUrl =
                        Types.mapLink model.platform loc.point loc.title
                in
                div [ class "flex items-start gap-2 type-caption text-text-muted" ]
                    [ span [ class "flex-shrink-0 mt-0.5 text-brand" ] [ featherIcon FeatherIcons.mapPin 16 ]
                    , a [ href mapUrl, target (Types.mapLinkTarget model.platform "_blank"), rel "noopener noreferrer", class "hover:underline text-text-primary inline-flex items-center gap-1" ]
                        [ text address
                        , featherIcon FeatherIcons.externalLink 12
                        ]
                    ]

            Nothing ->
                text ""
        , if List.isEmpty loc.tags then
            text ""

          else
            viewField FeatherIcons.tag (String.join ", " (List.map translateTag loc.tags))
        , case loc.description of
            Just desc ->
                p [ class "type-caption text-text-primary leading-relaxed mt-4 whitespace-pre-line" ] [ text desc ]

            Nothing ->
                text ""
        , div [ class "flex items-center mt-4 gap-2 w-full justify-between" ]
            [ div [ class "flex items-center gap-2" ]
                [ button [ onClick SelectPrevMarker, attribute "aria-label" (t A11yPrevMarker), class "text-text-subtle hover:text-brand p-1 cursor-pointer flex-shrink-0" ] [ featherIcon FeatherIcons.chevronLeft 20 ]
                , case loc.url of
                    Just url ->
                        Button.link { label = t PanelMoreInfo, href = url }
                            |> Button.withVariant Button.Primary
                            |> Button.withSize Button.Small
                            |> Button.withTarget
                                (if model.isEmbed then
                                    "_top"

                                 else
                                    "_blank"
                                )
                            |> Button.toHtml

                    Nothing ->
                        text ""
                ]
            , div [ class "ml-auto flex items-center gap-2" ]
                [ Button.new { label = t PanelClose, onClick = ClosePanel }
                    |> Button.withVariant Button.Secondary
                    |> Button.withSize Button.Small
                    |> Button.toHtml
                , button [ onClick SelectNextMarker, attribute "aria-label" (t A11yNextMarker), class "text-text-subtle hover:text-brand p-1 cursor-pointer flex-shrink-0" ] [ featherIcon FeatherIcons.chevronRight 20 ]
                ]
            ]
        , if model.presentationMode then
            case loc.url of
                Just url ->
                    case QRCode.fromString url of
                        Ok qrCode ->
                            div [ class "mt-6 flex justify-center pb-4" ]
                                [ QRCode.toSvg [ SvgA.width "150px", SvgA.height "150px" ] qrCode ]

                        Err _ ->
                            text ""

                Nothing ->
                    text ""

          else
            text ""
        ]


{-| Where an event is edited.

Events live in the calendar service, not here, so unlike a location — which
routes to an in-app edit page — this leaves the app entirely. Opened in a new
tab so the map and the pane the user came from stay put.

-}
eventEditUrl : String -> String
eventEditUrl id =
    "https://kalenteri.palikkaharrastajat.fi/#/events/" ++ id ++ "/edit"


viewEventPanel : Model -> Types.Event -> Html Msg
viewEventPanel model ev =
    let
        headerActions =
            if Types.isAuthenticated model.authState then
                [ a
                    [ href (eventEditUrl ev.id)
                    , target "_blank"
                    , rel "noopener noreferrer"
                    , attribute "aria-label" (t A11yPanelEdit)
                    , class "text-text-subtle hover:text-brand mt-0.5 flex-shrink-0 cursor-pointer"
                    ]
                    [ featherIcon FeatherIcons.edit2 20 ]
                ]

            else
                []

        cancelledBadge =
            if ev.cancelled then
                div [ class "event-cancelled-indicator mb-2" ]
                    [ span [ class "type-overline text-text-on-dark bg-brand rounded px-2 py-0.5" ]
                        [ text (t EventCancelled) ]
                    ]

            else
                text ""
    in
    MapOverlay.detailPanelWithHeaderActions
        { isOpen = True
        , onClose = ClosePanel
        , closeLabel = t A11yPanelClose
        , title = ev.title
        , headerActions = headerActions
        }
        [ cancelledBadge
        , case DateUtils.formatEventDateDisplay ev of
            Just dateStr ->
                viewField FeatherIcons.calendar dateStr

            Nothing ->
                text ""
        , case ev.location of
            Just address ->
                let
                    mapUrl =
                        Types.mapLink model.platform ev.point ev.title
                in
                div [ class "flex items-start gap-2 type-caption text-text-muted" ]
                    [ span [ class "flex-shrink-0 mt-0.5 text-brand" ] [ featherIcon FeatherIcons.mapPin 16 ]
                    , a [ href mapUrl, target (Types.mapLinkTarget model.platform "_blank"), rel "noopener noreferrer", class "hover:underline text-text-primary inline-flex items-center gap-1" ]
                        [ text address
                        , featherIcon FeatherIcons.externalLink 12
                        ]
                    ]

            Nothing ->
                text ""
        , case ev.description of
            Just desc ->
                p [ class "type-caption text-text-primary leading-relaxed mt-4 whitespace-pre-line" ] [ text desc ]

            Nothing ->
                text ""
        , div [ class "flex items-center mt-4 gap-2 w-full justify-between" ]
            [ div [ class "flex items-center gap-2" ]
                [ button [ onClick SelectPrevMarker, attribute "aria-label" (t A11yPrevMarker), class "text-text-subtle hover:text-brand p-1 cursor-pointer flex-shrink-0" ] [ featherIcon FeatherIcons.chevronLeft 20 ]
                , case ev.url of
                    Just url ->
                        Button.link { label = t PanelMoreInfo, href = url }
                            |> Button.withVariant Button.Primary
                            |> Button.withSize Button.Small
                            |> Button.withTarget
                                (if model.isEmbed then
                                    "_top"

                                 else
                                    "_blank"
                                )
                            |> Button.toHtml

                    Nothing ->
                        text ""
                ]
            , div [ class "ml-auto flex items-center gap-2" ]
                [ Button.new { label = t PanelClose, onClick = ClosePanel }
                    |> Button.withVariant Button.Secondary
                    |> Button.withSize Button.Small
                    |> Button.toHtml
                , button [ onClick SelectNextMarker, attribute "aria-label" (t A11yNextMarker), class "text-text-subtle hover:text-brand p-1 cursor-pointer flex-shrink-0" ] [ featherIcon FeatherIcons.chevronRight 20 ]
                ]
            ]
        , if model.presentationMode then
            case ev.url of
                Just url ->
                    case QRCode.fromString url of
                        Ok qrCode ->
                            div [ class "mt-6 flex justify-center pb-4" ]
                                [ QRCode.toSvg [ SvgA.width "150px", SvgA.height "150px" ] qrCode ]

                        Err _ ->
                            text ""

                Nothing ->
                    text ""

          else
            text ""
        ]


viewField : FeatherIcons.Icon -> String -> Html Msg
viewField icon value =
    div [ class "flex items-start gap-2 type-caption text-text-muted" ]
        [ span [ class "flex-shrink-0 mt-0.5 text-brand" ] [ featherIcon icon 16 ]
        , span [] [ text value ]
        ]


translateTag : String -> String
translateTag tagStr =
    case tagStr of
        "exhibition" ->
            t TagExhibition

        "store" ->
            t TagStore

        "fleamarket" ->
            t TagFleamarket

        "museum" ->
            t TagMuseum

        "other" ->
            t TagOther

        _ ->
            tagStr
