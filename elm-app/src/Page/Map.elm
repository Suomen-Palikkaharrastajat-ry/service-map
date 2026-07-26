module Page.Map exposing (view)

import DateUtils
import FeatherIcons
import Html exposing (Html, a, button, div, h2, input, label, p, span, text)
import Html.Attributes exposing (checked, class, href, id, style, target, type_)
import Html.Events exposing (onCheck, onClick)
import I18n exposing (MsgKey(..), t)
import OpeningHours.I18n as OHI18n
import OpeningHours.Parser as OHParser
import OpeningHours.Viewer as OHViewer
import RemoteData exposing (RemoteData(..))
import Route
import Set
import Types exposing (Location, Model, Msg(..))
import View.Icons exposing (featherIcon)


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
    case model.locations of
        RemoteData.Loading ->
            div
                [ style "position" "absolute"
                , style "top" "1rem"
                , style "left" "50%"
                , style "transform" "translateX(-50%)"
                , style "z-index" "1000"
                , class "bg-white rounded shadow px-4 py-2 type-caption text-text-muted"
                ]
                [ text (t MapLoading) ]

        Failure _ ->
            div
                [ style "position" "absolute"
                , style "top" "1rem"
                , style "left" "50%"
                , style "transform" "translateX(-50%)"
                , style "z-index" "1000"
                , class "bg-brand-red/10 text-brand-red rounded shadow px-4 py-2 type-caption"
                ]
                [ text (t MapLoadError) ]

        Success _ ->
            text ""

        NotAsked ->
            text ""


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
        div
            [ style "position" "absolute"
            , style "bottom" "2rem"
            , style "left" "1rem"
            , style "z-index" "1000"
            , class "bg-white/90 backdrop-blur rounded shadow p-4 flex flex-col gap-2"
            ]
            ((allTags
                |> List.map
                    (\tag ->
                        let
                            isVisible =
                                not (List.member tag model.hiddenTags)
                        in
                        label [ class "flex items-center gap-2 cursor-pointer type-body-small" ]
                            [ input
                                [ type_ "checkbox"
                                , checked isVisible
                                , onCheck (\chk -> ToggleTagVisibility tag (not chk))
                                ]
                                []
                            , text (localizeTag tag)
                            ]
                    )
             )
                ++ [ label [ class "flex items-center gap-2 cursor-pointer type-body-small" ]
                        [ input
                            [ type_ "checkbox"
                            , checked (not model.eventsHidden)
                            , onCheck (\chk -> ToggleEventVisibility (not chk))
                            ]
                            []
                        , text "Tapahtuma"
                        ]
                   ]
            )


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
    div
        [ style "position" "absolute"
        , style "top" "0"
        , style "right" "0"
        , style "height" "100%"
        , style "width" "22rem"
        , style "z-index" "1000"
        , class "bg-white shadow-xl overflow-y-auto flex flex-col"
        ]
        [ -- Header
          div [ class "flex items-start justify-between gap-2 p-4 border-b border-border-default" ]
            [ h2 [ class "type-h4 text-text-primary flex-1" ]
                [ text loc.title ]
            , if Types.isAuthenticated model.authState then
                a
                    [ href (Route.toHref (Route.RouteLocationEdit loc.id))
                    , class "text-text-subtle hover:text-brand mt-0.5 flex-shrink-0"
                    , style "cursor" "pointer"
                    ]
                    [ featherIcon FeatherIcons.edit2 20 ]

              else
                text ""
            , button
                [ onClick ClosePanel
                , class "text-text-subtle hover:text-text-primary mt-0.5 flex-shrink-0"
                , style "cursor" "pointer"
                ]
                [ featherIcon FeatherIcons.x 24 ]
            ]

        -- Body
        , div [ class "p-4 flex-1 space-y-3" ]
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
                        osmUrl =
                            "https://www.openstreetmap.org/?mlat=" ++ String.fromFloat loc.point.lat ++ "&mlon=" ++ String.fromFloat loc.point.lon ++ "#map=17/" ++ String.fromFloat loc.point.lat ++ "/" ++ String.fromFloat loc.point.lon
                    in
                    div [ class "flex items-start gap-2 type-caption text-text-muted" ]
                        [ span [ class "flex-shrink-0 mt-0.5 text-brand" ] [ featherIcon FeatherIcons.mapPin 16 ]
                        , a [ href osmUrl, target "_blank", class "hover:underline text-text-primary inline-flex items-center gap-1" ] 
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
                    p [ class "type-caption text-text-primary leading-relaxed mt-4" ] [ text desc ]

                Nothing ->
                    text ""
            , case loc.url of
                Just url ->
                    a
                        [ href url
                        , target "_blank"
                        , class "btn-primary mt-2 block text-center"
                        ]
                        [ text (t PanelMoreInfo) ]

                Nothing ->
                    text ""
            ]
        ]


viewEventPanel : Model -> Types.Event -> Html Msg
viewEventPanel model ev =
    div
        [ style "position" "absolute"
        , style "top" "0"
        , style "right" "0"
        , style "height" "100%"
        , style "width" "22rem"
        , style "z-index" "1000"
        , class "bg-white shadow-xl overflow-y-auto flex flex-col"
        ]
        [ -- Header
          div [ class "flex items-start justify-between gap-2 p-4 border-b border-border-default" ]
            [ h2 [ class "type-h4 text-text-primary flex-1" ]
                [ text ev.title ]
            , button
                [ onClick ClosePanel
                , class "text-text-subtle hover:text-text-primary mt-0.5 flex-shrink-0"
                , style "cursor" "pointer"
                ]
                [ featherIcon FeatherIcons.x 24 ]
            ]

        -- Body
        , div [ class "p-4 flex-1 space-y-3" ]
            [ case DateUtils.formatEventDateDisplay ev of
                Just dateStr ->
                    viewField FeatherIcons.calendar dateStr

                Nothing ->
                    text ""
            , case ev.location of
                Just address ->
                    let
                        osmUrl =
                            "https://www.openstreetmap.org/?mlat=" ++ String.fromFloat ev.point.lat ++ "&mlon=" ++ String.fromFloat ev.point.lon ++ "#map=17/" ++ String.fromFloat ev.point.lat ++ "/" ++ String.fromFloat ev.point.lon
                    in
                    div [ class "flex items-start gap-2 type-caption text-text-muted" ]
                        [ span [ class "flex-shrink-0 mt-0.5 text-brand" ] [ featherIcon FeatherIcons.mapPin 16 ]
                        , a [ href osmUrl, target "_blank", class "hover:underline text-text-primary inline-flex items-center gap-1" ] 
                            [ text address 
                            , featherIcon FeatherIcons.externalLink 12
                            ]
                        ]

                Nothing ->
                    text ""
            , case ev.description of
                Just desc ->
                    p [ class "type-caption text-text-primary leading-relaxed mt-4" ] [ text desc ]

                Nothing ->
                    text ""
            , case ev.url of
                Just url ->
                    a
                        [ href url
                        , target "_blank"
                        , class "btn-primary mt-2 block text-center"
                        ]
                        [ text (t PanelMoreInfo) ]

                Nothing ->
                    text ""
            ]
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
