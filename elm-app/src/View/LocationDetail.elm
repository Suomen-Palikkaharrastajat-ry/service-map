module View.LocationDetail exposing (view)

{-| View module for the location detail page.
-}

import Api
import Component.Button as Button
import Component.LoadState as LoadState
import DateUtils
import FeatherIcons
import Html exposing (Html, a, div, h1, img, p, span, text)
import Html.Attributes exposing (alt, class, href, src, target)
import Html.Events exposing (onClick)
import I18n exposing (t)
import Lang exposing (Lang)
import Route exposing (Route(..), toHref)
import Types exposing (AuthState(..), LocationDetailPage, Msg(..), isAuthenticated)
import View.Icons exposing (featherIcon)


view : Lang -> String -> Bool -> String -> AuthState -> String -> LocationDetailPage -> Html Msg
view lang pbBaseUrl isEmbed platform authState _ detPage =
    div [ class "max-w-2xl mx-auto p-4 w-full" ]
        [ backButton lang RouteLocations
        , LoadState.view
            { loadingLabel = t lang I18n.Loading
            , errorMessage = \_ -> t lang I18n.ErrorUnknown
            , onRetry = Nothing
            , retryLabel = ""
            }
            (Types.fromRemoteData detPage.location)
            (viewLocationContent lang pbBaseUrl isEmbed platform authState detPage)
        ]


viewLocationContent : Lang -> String -> Bool -> String -> AuthState -> LocationDetailPage -> Types.Location -> Html Msg
viewLocationContent lang pbBaseUrl isEmbed platform authState detPage loc =
    div []
        [ div [ class "flex justify-between items-start mb-2" ]
            [ h1 [ class "type-h1 flex items-center gap-2" ]
                [ span [ class "text-brand shrink-0" ] [ featherIcon (getMarkerIcon loc) 24 ]
                , span (I18n.contentAttrs lang) [ text loc.title ]
                ]
            , if isAuthenticated authState then
                div [ class "flex gap-2 ml-4 shrink-0" ]
                    [ Button.new { label = t lang I18n.DetailEdit, onClick = NavigateTo (RouteLocationEdit loc.id) }
                        |> Button.withVariant Button.Secondary
                        |> Button.withSize Button.Small
                        |> Button.toHtml
                    , Button.new { label = t lang I18n.DetailDelete, onClick = DetailDelete }
                        |> Button.withVariant Button.Danger
                        |> Button.withSize Button.Small
                        |> Button.withDisabled detPage.deleteConfirm
                        |> Button.toHtml
                    ]

              else
                text ""
            ]
        , if detPage.deleteConfirm then
            div [ class "mb-4 p-4 bg-bg-subtle border-2 border-brand-red rounded-md shadow-sm" ]
                [ p [ class "type-body text-brand-red font-medium mb-3" ] [ text (t lang I18n.DetailDeleteQuestion) ]
                , div [ class "flex gap-3" ]
                    [ Button.new { label = t lang I18n.DetailDeleteConfirm, onClick = DetailDeleteConfirm }
                        |> Button.withVariant Button.Danger
                        |> Button.withSize Button.Medium
                        |> Button.toHtml
                    , Button.new { label = t lang I18n.DetailDeleteCancel, onClick = DetailDeleteCancel }
                        |> Button.withVariant Button.Secondary
                        |> Button.withSize Button.Medium
                        |> Button.toHtml
                    ]
                ]

          else
            text ""
        , case DateUtils.formatLocationDateDisplay lang { startDate = loc.startDate, endDate = loc.endDate } of
            Nothing ->
                text ""

            Just dateStr ->
                p [ class "text-text-muted mb-3 flex items-center gap-2 type-caption" ]
                    [ featherIcon FeatherIcons.calendar 14
                    , text dateStr
                    ]
        , case loc.openingHours of
            Nothing ->
                text ""

            Just oh ->
                p [ class "text-text-muted mb-3 flex items-center gap-2 type-caption" ]
                    [ featherIcon FeatherIcons.clock 14
                    , text oh
                    ]
        , case loc.location of
            Nothing ->
                text ""

            Just address ->
                div [ class "mb-3 flex items-center gap-2 type-caption" ]
                    [ span [ class "text-brand" ] [ featherIcon FeatherIcons.mapPin 14 ]
                    , if not (Types.hasValidCoordinates loc.point) then
                        span [] [ text address ]

                      else
                        a
                            [ href (Types.mapLink platform loc.point loc.title)
                            , target
                                (Types.mapLinkTarget platform
                                    (if isEmbed then
                                        "_top"

                                     else
                                        "_blank"
                                    )
                                )
                            , class "text-brand hover:underline inline-flex items-center gap-1"
                            ]
                            [ text address
                            ]
                    ]
        , case loc.description of
            Nothing ->
                text ""

            Just desc ->
                div [ class "mb-4 whitespace-pre-line text-text-primary type-body" ] [ span (I18n.contentAttrs lang) [ text desc ] ]
        , case loc.image of
            Nothing ->
                text ""

            Just filename ->
                div [ class "mb-4" ]
                    [ img
                        [ src (Api.imageUrl pbBaseUrl loc.id filename)
                        , alt (Maybe.withDefault "" loc.imageDescription)
                        , class "max-w-full rounded shadow"
                        ]
                        []
                    ]
        , case loc.url of
            Nothing ->
                text ""

            Just url ->
                div [ class "mb-4" ]
                    [ a
                        [ href url
                        , target
                            (if isEmbed then
                                "_top"

                             else
                                "_blank"
                            )
                        , class "text-brand hover:underline inline-flex items-center gap-1 type-caption"
                        ]
                        [ text (t lang I18n.DetailMoreInfo)
                        , featherIcon FeatherIcons.externalLink 14
                        ]
                    ]
        ]


backButton : Lang -> Route -> Html Msg
backButton lang route =
    a
        [ href (toHref route)
        , onClick (NavigateTo route)
        , class "flex items-center gap-1 type-caption text-brand hover:underline mb-4"
        ]
        [ featherIcon FeatherIcons.arrowLeft 14, text (t lang I18n.DetailBack) ]


getMarkerIcon : Types.Location -> FeatherIcons.Icon
getMarkerIcon loc =
    case ( loc.startDate, loc.endDate ) of
        ( Just _, Just _ ) ->
            FeatherIcons.calendar

        _ ->
            let
                firstTag =
                    List.head loc.tags |> Maybe.withDefault "other"
            in
            case firstTag of
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
