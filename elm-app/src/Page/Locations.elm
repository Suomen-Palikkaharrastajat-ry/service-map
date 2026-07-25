module Page.Locations exposing (view)

import Component.Button as Button
import FeatherIcons
import File
import Html exposing (Html, a, div, h1, h3, p, span, text)
import Html.Attributes exposing (class, href, target)
import Html.Events as Events
import I18n exposing (t)
import Json.Decode as Decode
import RemoteData exposing (RemoteData(..))
import Route exposing (Route(..), toHref)
import Types exposing (AuthState(..), Location, Model, Msg)
import View.Icons exposing (featherIcon)


view : Model -> Types.LocationsPage -> Html Msg
view model locPage =
    div [ class "p-4 max-w-5xl mx-auto w-full" ]
        [ div [ class "flex items-center justify-between mb-4 flex-wrap gap-4" ]
            [ h1 [ class "type-h1" ] [ text (t I18n.LocationListTitle) ]
            , case model.authState of
                Authenticated _ ->
                    div [ class "flex items-center gap-4" ]
                        [ case locPage.kmlImportStatus of
                            Types.KmlIdle ->
                                Html.label [ class "cursor-pointer type-caption text-brand hover:underline flex items-center gap-1" ]
                                    [ featherIcon FeatherIcons.upload 14
                                    , text (t I18n.KmlImport)
                                    , Html.input
                                        [ Html.Attributes.type_ "file"
                                        , Html.Attributes.accept ".kml"
                                        , Html.Attributes.class "hidden"
                                        , Events.on "change" (Decode.at [ "target", "files", "0" ] File.decoder |> Decode.map Types.LocationKmlFileSelected)
                                        ]
                                        []
                                    ]

                            Types.KmlParsing ->
                                span [ class "type-caption text-text-muted flex items-center gap-1" ]
                                    [ featherIcon FeatherIcons.loader 14, text (t I18n.KmlImporting) ]

                            Types.KmlImporting i total ->
                                span [ class "type-caption text-text-muted flex items-center gap-1" ]
                                    [ featherIcon FeatherIcons.loader 14, text (t I18n.KmlImporting ++ " " ++ String.fromInt i ++ "/" ++ String.fromInt total) ]

                            Types.KmlDone total ->
                                span [ class "type-caption text-brand-green flex items-center gap-1" ]
                                    [ featherIcon FeatherIcons.check 14, text (String.fromInt total ++ " " ++ t I18n.ImportSuccess) ]

                            Types.KmlError err ->
                                span [ class "type-caption text-brand-red flex items-center gap-1" ]
                                    [ featherIcon FeatherIcons.alertCircle 14, text (t I18n.KmlError) ]
                        , Button.viewLink
                            { label = t I18n.LocationListNew
                            , variant = Button.Primary
                            , size = Button.Small
                            , href = toHref RouteLocationNew
                            }
                        ]

                NotAuthenticated ->
                    text ""
            ]
        , case model.locations of
            NotAsked ->
                text ""

            Loading ->
                p [ class "type-body text-text-muted" ] [ text (t I18n.Loading) ]

            Failure _ ->
                p [ class "type-body text-brand-red" ] [ text (t I18n.ErrorNetwork) ]

            Success locations ->
                if List.isEmpty locations then
                    p [ class "type-body text-text-muted text-center py-8" ] [ text (t I18n.LocationListEmpty) ]

                else
                    div [ class "flex flex-col gap-4" ]
                        (List.map (viewLocationCard model.authState) locations)
        ]


viewLocationCard : AuthState -> Location -> Html Msg
viewLocationCard authState loc =
    div [ class "border rounded p-3 hover:bg-bg-subtle" ]
        [ div [ class "flex items-start justify-between gap-4" ]
            [ div []
                [ h3 [ class "type-h4" ]
                    [ a
                        [ href (toHref (RouteLocationDetail loc.id))
                        , class "hover:underline"
                        ]
                        [ text loc.title ]
                    ]
                , case loc.location of
                    Just addr ->
                        p [ class "type-caption text-text-muted" ] [ text addr ]

                    Nothing ->
                        text ""
                , case loc.description of
                    Just desc ->
                        p [ class "type-body text-text-primary line-clamp-2 mt-2" ] [ text desc ]

                    Nothing ->
                        text ""
                ]
            , div [ class "flex items-center gap-2 shrink-0" ]
                [ if not (Types.hasValidCoordinates loc.point) then
                    text ""

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
                        , class "text-brand hover:text-brand-yellow transition-colors"
                        ]
                        [ featherIcon FeatherIcons.mapPin 16 ]
                , case loc.url of
                    Nothing ->
                        text ""

                    Just url ->
                        a
                            [ href url
                            , target "_blank"
                            , class "text-brand hover:text-brand-yellow transition-colors"
                            ]
                            [ featherIcon FeatherIcons.externalLink 16 ]
                , case authState of
                    Authenticated _ ->
                        a
                            [ href (toHref (RouteLocationEdit loc.id))
                            , class "type-caption text-primary hover:underline"
                            ]
                            [ text (t I18n.LocationListEdit) ]

                    NotAuthenticated ->
                        text ""
                ]
            ]
        ]
