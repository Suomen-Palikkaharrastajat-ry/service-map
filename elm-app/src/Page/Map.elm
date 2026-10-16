module Page.Map exposing (view)

{-| Interactive map view page with location markers, filters, and detail drawer.
-}

import Component.Button as Button exposing (Size(..), Variant(..))
import Component.Form as Form
import Component.LoadState as LoadState
import DateUtils
import FeatherIcons
import Html exposing (Html, a, button, div, h2, input, label, p, span, text)
import Html.Attributes exposing (attribute, checked, class, for, href, id, property, rel, target, title, type_)
import Html.Events exposing (onCheck, onClick)
import I18n exposing (MsgKey(..), eventFilterLabel, t, translateTag)
import Json.Encode as Encode
import Lang exposing (Lang)
import OpeningHours.I18n as OHI18n
import OpeningHours.Parser as OHParser
import OpeningHours.Viewer as OHViewer
import PocketBaseAuth
import QRCode
import RemoteData exposing (RemoteData(..))
import Route
import Set
import Svg.Attributes as SvgA
import Types exposing (Location, Model, Msg(..))
import View.Icons exposing (featherIcon)
import View.MapOverlay as MapOverlay


view : Lang -> Model -> Html Msg
view lang model =
    div
        [ class "flex-1 w-full relative overflow-hidden flex flex-col" ]
        [ div
            [ id "map"
            , class "flex-1 w-full"
            ]
            []
        , viewStatusBadge lang model
        , viewToggles lang model
        , viewFilterModal lang model
        , viewPanel lang model
        ]


viewStatusBadge : Lang -> Model -> Html Msg
viewStatusBadge lang model =
    LoadState.badge
        { loadingLabel = t lang MapLoading
        , errorMessage = \_ -> t lang MapLoadError
        }
        (Types.fromRemoteData model.locations)


viewToggles : Lang -> Model -> Html Msg
viewToggles lang model =
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
    in
    if List.isEmpty allTags && (model.events == NotAsked || model.events == RemoteData.Loading) then
        text ""

    else
        MapOverlay.panel
            { position = MapOverlay.BottomLeft
            , label = Just (t lang FilterPanelTitle)
            }
            [ MapOverlay.filterGroup
                { legend = t lang FilterGroupLegend }
                ((allTags
                    |> List.map
                        (\tag ->
                            let
                                isVisible =
                                    not (List.member tag model.hiddenTags)

                                tagLocations =
                                    Types.visibleLocationsForTag tag model

                                tagCount =
                                    List.length tagLocations

                                tagLabel =
                                    translateTag lang tag

                                tagTitle =
                                    tagLabel ++ " (" ++ String.fromInt tagCount ++ ")"
                            in
                            div [ class "flex items-center justify-between gap-2 type-body-small w-full" ]
                                [ label
                                    [ for ("tag-filter-" ++ tag)
                                    , class "flex items-center gap-2 cursor-pointer type-body-small flex-1 min-w-0"
                                    , title tagTitle
                                    ]
                                    [ input
                                        [ type_ "checkbox"
                                        , id ("tag-filter-" ++ tag)
                                        , checked isVisible
                                        , onCheck (\chk -> ToggleTagVisibility tag (not chk))
                                        , class filterCheckboxClass
                                        ]
                                        []
                                    , span [ class "text-brand flex-shrink-0" ] [ featherIcon (iconForTag tag) 14 ]
                                    , text tagLabel
                                    , span [ class "sr-only" ] [ text (" (" ++ String.fromInt tagCount ++ ")") ]
                                    ]
                                , if tagCount > 0 then
                                    button
                                        [ type_ "button"
                                        , id ("tag-modal-open-" ++ tag)
                                        , onClick (ToggleTagModal tag)
                                        , title (t lang LocationsModalOpen)
                                        , attribute "aria-label" (t lang LocationsModalOpen ++ ": " ++ tagLabel)
                                        , class "text-text-subtle hover:text-brand p-1 cursor-pointer flex-shrink-0 rounded focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-brand"
                                        ]
                                        [ featherIcon FeatherIcons.list 14 ]

                                  else
                                    text ""
                                ]
                        )
                 )
                    ++ [ viewEventFilterToggle lang model ]
                )
            ]


{-| Tri-state events filter: checked (all) → indeterminate (no cancelled) → unchecked
(none). `indeterminate` is a DOM property rather than an attribute, and the visible label
always names the current state so the meaning never rests on the glyph alone.
-}
viewEventFilterToggle : Lang -> Model -> Html Msg
viewEventFilterToggle lang model =
    let
        ariaChecked =
            case model.eventFilter of
                Types.AllEvents ->
                    "true"

                Types.HideCancelled ->
                    "mixed"

                Types.NoEvents ->
                    "false"

        eventCount =
            List.length (Types.visibleEvents model)

        eventTitle =
            t lang FilterEvents ++ " (" ++ String.fromInt eventCount ++ "): " ++ eventFilterLabel lang model.eventFilter
    in
    div [ class "flex items-center justify-between gap-2 type-body-small w-full" ]
        [ label
            [ for "event-filter-toggle"
            , class "flex items-center gap-2 cursor-pointer type-body-small flex-1 min-w-0"
            , title eventTitle
            ]
            [ input
                [ type_ "checkbox"
                , id "event-filter-toggle"
                , checked (model.eventFilter == Types.AllEvents)
                , property "indeterminate" (Encode.bool (model.eventFilter == Types.HideCancelled))
                , attribute "aria-checked" ariaChecked
                , onClick CycleEventFilter
                , class filterCheckboxClass
                ]
                []
            , span [ class "text-brand flex-shrink-0" ] [ featherIcon FeatherIcons.calendar 14 ]
            , text (t lang FilterEvents)
            , span [ class "sr-only" ] [ text (" (" ++ String.fromInt eventCount ++ "): " ++ eventFilterLabel lang model.eventFilter) ]
            ]
        , if eventCount > 0 then
            button
                [ type_ "button"
                , id "events-modal-open"
                , onClick ToggleEventsModal
                , title (t lang EventsModalOpen)
                , attribute "aria-label" (t lang EventsModalOpen)
                , class "text-text-subtle hover:text-brand p-1 cursor-pointer flex-shrink-0 rounded focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-brand"
                ]
                [ featherIcon FeatherIcons.list 14 ]

          else
            text ""
        ]


viewFilterModal : Lang -> Model -> Html Msg
viewFilterModal lang model =
    case model.filterModal of
        Nothing ->
            text ""

        Just Types.EventsModal ->
            let
                evts =
                    Types.upcomingEvents model
            in
            renderModalFrame
                { title = t lang EventsModalTitle
                , icon = FeatherIcons.calendar
                , closeAriaLabel = t lang A11yEventsModalClose
                , content =
                    if List.isEmpty evts then
                        [ div [ class "type-body-small text-text-muted py-6 text-center" ]
                            [ text (t lang EventsModalEmpty) ]
                        ]

                    else
                        List.map (viewModalEventItem lang) evts
                }

        Just (Types.TagModal tag) ->
            let
                locs =
                    Types.locationsForTag tag model
            in
            renderModalFrame
                { title = translateTag lang tag
                , icon = iconForTag tag
                , closeAriaLabel = t lang A11yLocationsModalClose
                , content =
                    if List.isEmpty locs then
                        [ div [ class "type-body-small text-text-muted py-6 text-center" ]
                            [ text (t lang LocationsModalEmpty) ]
                        ]

                    else
                        List.map (viewModalLocationItem lang) locs
                }


renderModalFrame : { title : String, icon : FeatherIcons.Icon, closeAriaLabel : String, content : List (Html Msg) } -> Html Msg
renderModalFrame config =
    div []
        [ -- Backdrop
          div
            [ class "fixed inset-0 z-[1049] bg-black/40"
            , onClick CloseFilterModal
            ]
            []
        , -- Dialog container
          div
            [ class "fixed inset-0 z-[1050] pointer-events-none flex items-center justify-center p-4" ]
            [ div
                [ class "pointer-events-auto bg-bg-page text-text-primary rounded shadow-xl max-w-md w-full max-h-[80vh] flex flex-col overflow-hidden border border-border-default"
                , attribute "role" "dialog"
                , attribute "aria-modal" "true"
                , attribute "aria-labelledby" "filter-modal-title"
                ]
                [ -- Header
                  div
                    [ class "flex items-center justify-between p-4 border-b border-border-default bg-bg-surface" ]
                    [ div [ class "flex items-center gap-2" ]
                        [ span [ class "text-brand" ] [ featherIcon config.icon 18 ]
                        , h2 [ id "filter-modal-title", class "type-h3" ] [ text config.title ]
                        ]
                    , button
                        [ type_ "button"
                        , id "filter-modal-close"
                        , onClick CloseFilterModal
                        , attribute "aria-label" config.closeAriaLabel
                        , class "text-text-subtle hover:text-brand p-1 cursor-pointer rounded focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-brand"
                        ]
                        [ featherIcon FeatherIcons.x 20 ]
                    ]
                , -- Body
                  div [ class "p-4 overflow-y-auto flex flex-col gap-3" ]
                    config.content
                ]
            ]
        ]


viewModalEventItem : Lang -> Types.Event -> Html Msg
viewModalEventItem lang ev =
    let
        dateStr =
            DateUtils.formatEventDateDisplay lang ev
                |> Maybe.withDefault ""

        cancelledBadge =
            if ev.cancelled then
                span [ class "type-overline text-text-on-dark bg-brand rounded px-1.5 py-0.5" ]
                    [ text (t lang EventCancelled) ]

            else
                text ""
    in
    button
        [ type_ "button"
        , class "text-left w-full p-3 rounded border border-border-default hover:border-border-brand hover:bg-bg-surface/50 transition-colors flex flex-col gap-1 cursor-pointer group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
        , onClick (ModalMarkerClicked ev.id)
        ]
        [ span [ class "flex items-center justify-between gap-2" ]
            [ span
                [ class
                    (if ev.cancelled then
                        "type-body font-bold group-hover:text-brand line-through"

                     else
                        "type-body font-bold group-hover:text-brand"
                    )
                ]
                [ text ev.title ]
            , cancelledBadge
            ]
        , if String.isEmpty dateStr then
            text ""

          else
            span [ class "flex items-center gap-1.5 type-caption text-text-muted" ]
                [ span [ class "text-brand flex-shrink-0" ] [ featherIcon FeatherIcons.calendar 14 ]
                , text dateStr
                ]
        , case ev.location of
            Just loc ->
                span [ class "flex items-center gap-1.5 type-caption text-text-muted" ]
                    [ span [ class "text-brand flex-shrink-0" ] [ featherIcon FeatherIcons.mapPin 14 ]
                    , text loc
                    ]

            Nothing ->
                text ""
        , span [ class "mt-1 flex items-center gap-1 type-caption text-brand font-medium" ]
            [ text (t lang EventsModalShowOnMap)
            , featherIcon FeatherIcons.arrowRight 12
            ]
        ]


viewModalLocationItem : Lang -> Types.Location -> Html Msg
viewModalLocationItem lang loc =
    let
        dateStr =
            DateUtils.formatLocationDateDisplay lang loc
                |> Maybe.withDefault ""
    in
    button
        [ type_ "button"
        , class "text-left w-full p-3 rounded border border-border-default hover:border-border-brand hover:bg-bg-surface/50 transition-colors flex flex-col gap-1 cursor-pointer group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"
        , onClick (ModalMarkerClicked loc.id)
        ]
        [ span [ class "flex items-center justify-between gap-2" ]
            [ span [ class "type-body font-bold group-hover:text-brand" ]
                [ text loc.title ]
            ]
        , if String.isEmpty dateStr then
            text ""

          else
            span [ class "flex items-center gap-1.5 type-caption text-text-muted" ]
                [ span [ class "text-brand flex-shrink-0" ] [ featherIcon FeatherIcons.calendar 14 ]
                , text dateStr
                ]
        , case loc.location of
            Just place ->
                if String.isEmpty (String.trim place) then
                    text ""

                else
                    span [ class "flex items-center gap-1.5 type-caption text-text-muted" ]
                        [ span [ class "text-brand flex-shrink-0" ] [ featherIcon FeatherIcons.mapPin 14 ]
                        , text place
                        ]

            Nothing ->
                text ""
        , span [ class "mt-1 flex items-center gap-1 type-caption text-brand font-medium" ]
            [ text (t lang EventsModalShowOnMap)
            , featherIcon FeatherIcons.arrowRight 12
            ]
        ]


iconForTag : String -> FeatherIcons.Icon
iconForTag tag =
    case tag of
        "exhibition" ->
            FeatherIcons.image

        "store" ->
            FeatherIcons.shoppingBag

        "fleamarket" ->
            FeatherIcons.tag

        "museum" ->
            FeatherIcons.bookOpen

        _ ->
            FeatherIcons.mapPin


{-| Compact checkbox styling shared by the filter rows. `Component.Form.checkbox` is a
full form field (bottom margin, hint and error slots, no icon), which is too tall here.
-}
filterCheckboxClass : String
filterCheckboxClass =
    "rounded border border-border-brand text-brand focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand"


viewPanel : Lang -> Model -> Html Msg
viewPanel lang model =
    case model.selectedMarker of
        Nothing ->
            text ""

        Just (Types.SelectedLocation loc) ->
            viewLocationPanel lang model loc

        Just (Types.SelectedEvent ev) ->
            viewEventPanel lang model ev


viewLocationPanel : Lang -> Model -> Location -> Html Msg
viewLocationPanel lang model loc =
    let
        headerActions =
            if PocketBaseAuth.isAuthenticated model.authState then
                [ a
                    [ href (Route.toHref (Route.RouteLocationEdit loc.id))
                    , attribute "aria-label" (t lang A11yPanelEdit)
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
        , closeLabel = t lang A11yPanelClose
        , title = loc.title
        , headerActions = headerActions
        }
        [ case loc.startDate of
            Just _ ->
                case DateUtils.formatLocationDateDisplay lang { startDate = loc.startDate, endDate = loc.endDate } of
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
                                , OHViewer.view (OHI18n.forCode (Lang.toString lang)) parsed
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
            viewField FeatherIcons.tag (String.join ", " (List.map (translateTag lang) loc.tags))
        , case loc.description of
            Just desc ->
                p [ class "type-caption text-text-primary leading-relaxed mt-4 whitespace-pre-line" ] [ span (I18n.contentAttrs lang) [ text desc ] ]

            Nothing ->
                text ""
        , div [ class "flex items-center mt-4 gap-2 w-full justify-between" ]
            [ div [ class "flex items-center gap-2" ]
                [ button [ onClick SelectPrevMarker, attribute "aria-label" (t lang A11yPrevMarker), class "text-text-subtle hover:text-brand p-1 cursor-pointer flex-shrink-0" ] [ featherIcon FeatherIcons.chevronLeft 20 ]
                , case loc.url of
                    Just url ->
                        Button.link { label = t lang PanelMoreInfo, href = url }
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
                [ Button.new { label = t lang PanelClose, onClick = ClosePanel }
                    |> Button.withVariant Button.Secondary
                    |> Button.withSize Button.Small
                    |> Button.toHtml
                , button [ onClick SelectNextMarker, attribute "aria-label" (t lang A11yNextMarker), class "text-text-subtle hover:text-brand p-1 cursor-pointer flex-shrink-0" ] [ featherIcon FeatherIcons.chevronRight 20 ]
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
eventEditUrl : String -> String -> String
eventEditUrl calendarUrl id =
    calendarUrl ++ "/#/events/" ++ id ++ "/edit"


viewEventPanel : Lang -> Model -> Types.Event -> Html Msg
viewEventPanel lang model ev =
    let
        headerActions =
            if PocketBaseAuth.isAuthenticated model.authState then
                [ a
                    [ href (eventEditUrl model.calendarUrl ev.id)
                    , target "_blank"
                    , rel "noopener noreferrer"
                    , attribute "aria-label" (t lang A11yPanelEdit)
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
                        [ text (t lang EventCancelled) ]
                    ]

            else
                text ""
    in
    MapOverlay.detailPanelWithHeaderActions
        { isOpen = True
        , onClose = ClosePanel
        , closeLabel = t lang A11yPanelClose
        , title = ev.title
        , headerActions = headerActions
        }
        [ cancelledBadge
        , case DateUtils.formatEventDateDisplay lang ev of
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
                p [ class "type-caption text-text-primary leading-relaxed mt-4 whitespace-pre-line" ] [ span (I18n.contentAttrs lang) [ text desc ] ]

            Nothing ->
                text ""
        , div [ class "flex items-center mt-4 gap-2 w-full justify-between" ]
            [ div [ class "flex items-center gap-2" ]
                [ button [ onClick SelectPrevMarker, attribute "aria-label" (t lang A11yPrevMarker), class "text-text-subtle hover:text-brand p-1 cursor-pointer flex-shrink-0" ] [ featherIcon FeatherIcons.chevronLeft 20 ]
                , case ev.url of
                    Just url ->
                        Button.link { label = t lang PanelMoreInfo, href = url }
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
                [ Button.new { label = t lang PanelClose, onClick = ClosePanel }
                    |> Button.withVariant Button.Secondary
                    |> Button.withSize Button.Small
                    |> Button.toHtml
                , button [ onClick SelectNextMarker, attribute "aria-label" (t lang A11yNextMarker), class "text-text-subtle hover:text-brand p-1 cursor-pointer flex-shrink-0" ] [ featherIcon FeatherIcons.chevronRight 20 ]
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
