module View.Layout exposing (menuButtonId, viewBrandFooter, viewFooter, viewHeader, viewMobileDrawer, viewMobileOverlay)

{-| Main layout components: application header, footers, mobile navigation drawer and overlay.
-}

import Component.Button as Button
import Component.FeedLinks as FeedLinks
import Component.Footer as Footer
import Component.Footer.Family as FooterFamily
import Component.MobileDrawer as MobileDrawer
import Component.Navbar as Navbar
import FeatherIcons
import Html exposing (Html, button, div, nav, span, text, ul)
import Html.Attributes exposing (attribute, class, id, style)
import Html.Events exposing (onClick)
import I18n exposing (MsgKey(..), t)
import Route exposing (Route(..), toHref)
import Types exposing (AuthState(..), AuthUser, Msg(..), Page(..))
import View.Icons exposing (featherIcon)


{-| Id of the hamburger button. `CloseMenu` returns focus here so keyboard users
land back where they opened the drawer instead of at the top of the document.
-}
menuButtonId : String
menuButtonId =
    "mobile-menu-button"


viewHeader : AuthState -> Bool -> Bool -> Page -> Html Msg
viewHeader authState menuOpen presentationMode activePage =
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

        presentationButton =
            button
                [ onClick TogglePresentationMode
                , class "p-2 rounded-lg text-white hover:bg-white/10"
                , style "cursor" "pointer"
                , attribute "aria-label"
                    (if presentationMode then
                        t A11yPresentationStop

                     else
                        t A11yPresentationStart
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

        links =
            if presentationMode then
                []

            else
                [ { label = t NavHome
                  , href = toHref RouteMap
                  , mobileOnly = False
                  , isActive = isMapActive
                  }
                , { label = t NavLocations
                  , href = toHref RouteLocations
                  , mobileOnly = False
                  , isActive = isLocationsActive
                  }
                ]

        trailing =
            presentationButton
                :: (if presentationMode then
                        []

                    else
                        [ viewDesktopAuthControls authState ]
                   )

        menuToggle =
            if presentationMode then
                Nothing

            else
                Just
                    (span [ id menuButtonId ]
                        [ Navbar.viewMenuToggle
                            { isOpen = menuOpen
                            , onToggle = ToggleMenu
                            , controls = "mobile-nav"
                            , openLabel = t A11yMenuOpen
                            , closeLabel = t A11yMenuClose
                            }
                        ]
                    )
    in
    Navbar.viewAppHeader
        { brand =
            Navbar.viewBrand
                { href = toHref RouteMap
                , iconSrc = "/logo/square/square-smile.svg"
                , title = t NavbarTitle
                , onClick = Nothing
                }
        , navLabel = t A11yNavPrimary
        , links = links
        , trailing = trailing
        , menuToggle = menuToggle
        , sticky = True
        }


viewDesktopAuthControls : AuthState -> Html Msg
viewDesktopAuthControls authState =
    case authState of
        NotAuthenticated ->
            div [ class "hidden md:flex gap-2 items-center" ]
                [ authButton LoginClicked (t NavLogin) ]

        Authenticated user ->
            div [ class "hidden md:flex gap-2 items-center" ]
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
    Button.new { label = label, onClick = msg }
        |> Button.withVariant Button.Primary
        |> Button.withSize Button.Small
        |> Button.toHtml


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
        , label = t A11yNavMobile
        , onClose = CloseMenu
        , breakpoint = MobileDrawer.Md
        , content =
            [ nav [ class "p-4", attribute "aria-label" (t A11yNavMobile) ]
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
    FeedLinks.view
        { label = "Syötteet ja vienti"
        , cards = []
        , feeds =
            Just
                { icon = FeatherIcons.rss
                , title = "Syötteet"
                , description = "Syötteet integroivat kohteet muihin palveluihin."
                , links =
                    [ { label = t FeedAtom, href = siteUrl ++ "/kartta.atom" }
                    , { label = t FeedRss, href = siteUrl ++ "/kartta.rss" }
                    , { label = t FeedJson, href = siteUrl ++ "/kartta.json" }
                    , { label = t FeedGeoJson, href = siteUrl ++ "/kartta.geo.json" }
                    ]
                }
        , newTabHint = "(avautuu uuteen välilehteen)"
        }


viewBrandFooter : Html Msg
viewBrandFooter =
    Footer.viewWith
        { topMargin = False
        , extra = []
        }
        { logo = Just FooterFamily.logo
        , siteLabel = Just "Palikkaharrastajat"
        , links = List.filter (\l -> l.href /= "https://kartta.palikkaharrastajat.fi") FooterFamily.links
        , groups = []
        , copyright = FooterFamily.copyright 2026
        , disclaimer = Just FooterFamily.disclaimer
        }
