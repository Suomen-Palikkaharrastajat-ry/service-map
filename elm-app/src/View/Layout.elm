module View.Layout exposing (viewBrandFooter, viewFooter, viewHeader, viewMobileDrawer, viewMobileOverlay)

import Component.Button as Button
import Component.MobileDrawer as MobileDrawer
import FeatherIcons
import Html exposing (Html, a, button, div, footer, h3, header, img, li, nav, p, span, text, ul)
import Html.Attributes exposing (alt, attribute, class, href, src, style)
import Html.Events exposing (onClick)
import I18n exposing (MsgKey(..), t)
import Route exposing (Route(..), toHref)
import Types exposing (AuthState(..), AuthUser, Msg(..), Page(..))
import View.Icons exposing (featherIcon)


viewHeader : AuthState -> Bool -> Bool -> Html Msg
viewHeader authState menuOpen presentationMode =
    header [ class "bg-brand border-b border-brand sticky md:static top-0 z-50" ]
        [ div [ class "flex items-center justify-between px-4 h-14" ]
            [ -- Square logo + site name
              a [ href (toHref RouteMap), class "flex items-center gap-2" ]
                [ img
                    [ src "/logo/square/square-smile.svg"
                    , alt ""
                    , attribute "aria-hidden" "true"
                    , class "h-8 w-8"
                    ]
                    []
                , span [ class "type-h4 text-white" ] [ text (t NavbarTitle) ]
                ]
            , div [ class "flex items-center gap-4" ]
                [ button
                    [ onClick TogglePresentationMode
                    , class "p-2 rounded-lg text-white hover:bg-white/10"
                    , style "cursor" "pointer"
                    , attribute "aria-label"
                        (if presentationMode then
                            "Stop presentation"

                         else
                            "Start presentation"
                        )
                    ]
                    [ featherIcon
                        (if presentationMode then
                            FeatherIcons.pause

                         else
                            FeatherIcons.play
                        )
                        24
                    ]
                , if presentationMode then
                    text ""

                  else
                    -- Desktop nav + auth (hidden on mobile)
                    div [ class "hidden md:flex items-center gap-6" ]
                        [ nav [ class "flex gap-4" ]
                            [ a [ href (toHref RouteMap), class "type-caption text-white/80 hover:text-white hover:underline" ]
                                [ text (t NavHome) ]
                            , a [ href (toHref RouteLocations), class "type-caption text-white/80 hover:text-white hover:underline" ]
                                [ text (t NavLocations) ]
                            ]
                        , viewDesktopAuthControls authState
                        ]
                , if presentationMode then
                    text ""

                  else
                    -- Hamburger button (mobile only)
                    button
                        [ onClick ToggleMenu
                        , class "md:hidden p-2 rounded-lg text-white"
                        , style "cursor" "pointer"
                        , attribute "aria-label"
                            (if menuOpen then
                                "Sulje valikko"

                             else
                                "Avaa valikko"
                            )
                        , attribute "aria-expanded"
                            (if menuOpen then
                                "true"

                             else
                                "false"
                            )
                        ]
                        [ featherIcon
                            (if menuOpen then
                                FeatherIcons.x

                             else
                                FeatherIcons.menu
                            )
                            24
                        ]
                ]
            ]
        ]


viewDesktopAuthControls : AuthState -> Html Msg
viewDesktopAuthControls authState =
    case authState of
        NotAuthenticated ->
            div [ class "flex gap-2 items-center" ]
                [ authButton LoginClicked (t NavLogin) ]

        Authenticated user ->
            div [ class "flex gap-2 items-center" ]
                [ span [ class "type-caption text-white/80" ] [ text user.name ]
                , span [ attribute "title" (userTooltip user), class "inline-flex" ]
                    [ authButton LogOut (t NavLogout) ]
                ]


viewMobileAuthControls : AuthState -> Html Msg
viewMobileAuthControls authState =
    case authState of
        NotAuthenticated ->
            div [ class "flex" ]
                [ authButton LoginClicked (t NavLogin) ]

        Authenticated user ->
            div [ class "flex flex-col items-start gap-3" ]
                [ span [ class "type-caption text-text-muted" ] [ text user.name ]
                , span [ attribute "title" (userTooltip user), class "inline-flex" ]
                    [ authButton LogOut (t NavLogout) ]
                ]


authButton : Msg -> String -> Html Msg
authButton msg label =
    Button.view
        { label = label
        , variant = Button.Primary
        , size = Button.Small
        , onClick = msg
        , disabled = False
        , loading = False
        , ariaPressedState = Nothing
        }


userTooltip : AuthUser -> String
userTooltip user =
    let
        namePart =
            String.trim user.name

        emailPart =
            String.trim user.email
    in
    if String.isEmpty namePart then
        "Kirjautunut: " ++ emailPart

    else if String.isEmpty emailPart then
        "Kirjautunut: " ++ namePart

    else
        "Kirjautunut: " ++ namePart ++ " (" ++ emailPart ++ ")"


viewMobileOverlay : Bool -> Html Msg
viewMobileOverlay menuOpen =
    MobileDrawer.viewOverlay { isOpen = menuOpen, onClose = CloseMenu, breakpoint = MobileDrawer.Md }


viewMobileDrawer : Bool -> Page -> AuthState -> Html Msg
viewMobileDrawer menuOpen activePage authState =
    let
        isMapActive =
            case activePage of
                PageMap ->
                    True

                _ ->
                    False

        isLocationsActive =
            case activePage of
                PageLocations _ ->
                    True

                _ ->
                    False
    in
    MobileDrawer.view
        { isOpen = menuOpen
        , id = "mobile-nav"
        , onClose = CloseMenu
        , breakpoint = MobileDrawer.Md
        , content =
            [ nav [ class "p-4" ]
                [ ul [ class "flex flex-col gap-1 list-none m-0 p-0" ]
                    [ MobileDrawer.viewNavLink { href = toHref RouteMap, label = t NavHome, isActive = isMapActive, onClose = CloseMenu }
                    , MobileDrawer.viewNavLink { href = toHref RouteLocations, label = t NavLocations, isActive = isLocationsActive, onClose = CloseMenu }
                    ]
                ]
            , div [ class "p-4 border-t border-border-default" ]
                [ viewMobileAuthControls authState ]
            ]
        }


viewFooter : Html Msg
viewFooter =
    let
        siteUrl =
            "https://kartta.palikkaharrastajat.fi"
    in
    footer [ class "border-t border-border-default bg-bg-subtle p-4 relative z-[400]" ]
        [ div [ class "mx-auto max-w-5xl" ]
            [ div [ class "p-4 text-center md:text-left" ]
                [ div [ class "mb-3 flex items-center justify-center md:justify-start" ]
                    [ div [ class "mr-2 text-brand" ]
                        [ featherIcon FeatherIcons.rss 32 ]
                    , h3 [ class "type-h3" ] [ text "Syötteet" ]
                    ]
                , p [ class "mb-3 type-caption text-text-muted" ]
                    [ text "Syötteet integroivat kohteet muihin palveluihin." ]
                , div [ class "type-caption" ]
                    [ feedLink (siteUrl ++ "/kartta.atom") (t FeedAtom)
                    , text " | "
                    , feedLink (siteUrl ++ "/kartta.rss") (t FeedRss)
                    , text " | "
                    , feedLink (siteUrl ++ "/kartta.json") (t FeedJson)
                    , text " | "
                    , feedLink (siteUrl ++ "/kartta.geo.json") (t FeedGeoJson)
                    ]
                ]
            ]
        ]


feedLink : String -> String -> Html Msg
feedLink url label =
    a
        [ href url
        , attribute "target" "_blank"
        , class "mx-1 text-brand no-underline hover:underline"
        ]
        [ text label ]


viewBrandFooter : Html Msg
viewBrandFooter =
    footer
        [ class "bg-brand text-white py-12 px-4 relative z-[400]" ]
        [ div [ class "max-w-5xl mx-auto" ]
            [ div
                [ class "grid grid-cols-1 sm:grid-cols-[auto_1fr] gap-8 sm:items-end" ]
                [ -- Col 1: service links + logo
                  div [ class "flex items-start gap-4" ]
                    [ img
                        [ src "/logo/square/square-smile-full-dark-bold.svg"
                        , alt ""
                        , attribute "aria-hidden" "true"
                        , class "h-35 w-35 flex-shrink-0"
                        ]
                        []
                    , div [ class "space-y-3" ]
                        [ p [ class "text-xs font-semibold text-white/50 uppercase tracking-wider" ]
                            [ text "Palikkaharrastajat" ]
                        , ul [ class "space-y-2 list-none m-0 p-0" ]
                            [ li []
                                [ a
                                    [ href "https://palikkaharrastajat.fi"
                                    , class "text-sm text-white/80 hover:text-white underline transition-colors"
                                    ]
                                    [ text "Kotisivut" ]
                                ]
                            , li []
                                [ a
                                    [ href "https://kalenteri.palikkaharrastajat.fi"
                                    , class "text-sm text-white/80 hover:text-white underline transition-colors"
                                    ]
                                    [ text "Palikkakalenteri" ]
                                ]
                            , li []
                                [ a
                                    [ href "https://linkit.palikkaharrastajat.fi"
                                    , class "text-sm text-white/80 hover:text-white underline transition-colors"
                                    ]
                                    [ text "Palikkalinkit" ]
                                ]
                            ]
                        ]
                    ]
                , -- Col 2: org name & legal
                  div [ class "space-y-1 sm:text-right" ]
                    [ div [ class "space-y-1 text-xs text-white/50" ]
                        [ p [] [ text "© 2026 Suomen Palikkaharrastajat ry" ]
                        , p [] [ text "LEGO® on LEGO Groupin rekisteröity tavaramerkki." ]
                        , p [] [ text "LEGO Group ei ylläpidä tai tue tätä itsenäistä sivustoa." ]
                        ]
                    ]
                ]
            ]
        ]
