module View.LocationDetail exposing (view)

import Api
import Component.Alert as Alert
import Component.Button as Button
import Component.Spinner as Spinner
import DateUtils
import FeatherIcons
import Html exposing (Html, a, div, h1, img, p, span, text)
import Html.Attributes exposing (alt, class, href, src, target)
import Html.Events exposing (onClick)
import I18n exposing (t)
import RemoteData exposing (RemoteData)
import Route exposing (Route(..), toHref)
import Types exposing (AuthState(..), LocationDetailPage, Msg(..), isAuthenticated)
import View.Icons exposing (featherIcon)


view : String -> AuthState -> String -> LocationDetailPage -> Html Msg
view pbBaseUrl authState _ detPage =
    div [ class "max-w-2xl mx-auto p-4 w-full" ]
        [ case detPage.location of
            RemoteData.NotAsked ->
                div []
                    [ backButton RouteLocations
                    , text ""
                    ]

            RemoteData.Loading ->
                div []
                    [ backButton RouteLocations
                    , div [ class "flex justify-center py-8" ]
                        [ Spinner.view { size = Spinner.Medium, label = t I18n.Loading } ]
                    ]

            RemoteData.Failure _ ->
                div []
                    [ backButton RouteLocations
                    , div [ class "py-4" ]
                        [ Alert.view
                            { alertType = Alert.Error
                            , title = Nothing
                            , body = [ text (t I18n.ErrorUnknown) ]
                            , customIcon = Nothing
                            , onDismiss = Nothing
                            }
                        ]
                    ]

            RemoteData.Success loc ->
                div []
                    [ backButton RouteLocations
                    , div [ class "flex justify-between items-start mb-2" ]
                        [ h1 [ class "type-h1 flex items-center gap-2" ]
                            [ span [ class "text-brand shrink-0" ] [ featherIcon (getMarkerIcon loc) 24 ]
                            , text loc.title
                            ]
                        , if isAuthenticated authState then
                            div [ class "flex gap-2 ml-4 shrink-0" ]
                                [ Button.view
                                    { label = t I18n.DetailEdit
                                    , variant = Button.Secondary
                                    , size = Button.Small
                                    , onClick = NavigateTo (RouteLocationEdit loc.id)
                                    , disabled = False
                                    , loading = False
                                    , ariaPressedState = Nothing
                                    }
                                , Button.view
                                    { label = t I18n.DetailDelete
                                    , variant = Button.Danger
                                    , size = Button.Small
                                    , onClick = DetailDelete
                                    , disabled = detPage.deleteConfirm
                                    , loading = False
                                    , ariaPressedState = Nothing
                                    }
                                ]

                          else
                            text ""
                        ]
                    , if detPage.deleteConfirm then
                        div [ class "mb-4 p-4 bg-bg-surface border-2 border-danger rounded-md shadow-sm" ]
                            [ p [ class "type-body text-danger font-medium mb-3" ] [ text "Oletko varma, että haluat poistaa tämän kohteen?" ]
                            , div [ class "flex gap-3" ]
                                [ Button.view
                                    { label = t I18n.DetailDeleteConfirm
                                    , variant = Button.Danger
                                    , size = Button.Medium
                                    , onClick = DetailDeleteConfirm
                                    , disabled = False
                                    , loading = False
                                    , ariaPressedState = Nothing
                                    }
                                , Button.view
                                    { label = t I18n.DetailDeleteCancel
                                    , variant = Button.Secondary
                                    , size = Button.Medium
                                    , onClick = DetailDeleteCancel
                                    , disabled = False
                                    , loading = False
                                    , ariaPressedState = Nothing
                                    }
                                ]
                            ]

                      else
                        text ""
                    , case DateUtils.formatLocationDateDisplay { startDate = loc.startDate, endDate = loc.endDate } of
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
                                        [ href
                                            ("https://www.openstreetmap.org/?mlat="
                                                ++ String.fromFloat loc.point.lat
                                                ++ "&mlon="
                                                ++ String.fromFloat loc.point.lon
                                                ++ "&zoom=15"
                                            )
                                        , target "_blank"
                                        , class "text-brand hover:underline inline-flex items-center gap-1"
                                        ]
                                        [ text address
                                        ]
                                ]
                    , case loc.description of
                        Nothing ->
                            text ""

                        Just desc ->
                            div [ class "mb-4 whitespace-pre-line text-text-primary type-body" ] [ text desc ]
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
                                    , target "_blank"
                                    , class "text-brand hover:underline inline-flex items-center gap-1 type-caption"
                                    ]
                                    [ text (t I18n.DetailMoreInfo)
                                    , featherIcon FeatherIcons.externalLink 14
                                    ]
                                ]
                    ]
        ]


backButton : Route -> Html Msg
backButton route =
    a
        [ href (toHref route)
        , onClick (NavigateTo route)
        , class "flex items-center gap-1 type-caption text-brand hover:underline mb-4"
        ]
        [ featherIcon FeatherIcons.arrowLeft 14, text (t I18n.DetailBack) ]


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
