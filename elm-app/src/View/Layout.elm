module View.Layout exposing (view)

{-| Page chrome: the shared family shell with this app's navigation, account
controls, presentation mode, feed links and toasts.
-}

import Component.Account as Account
import Component.FeedLinks as FeedLinks
import Component.Layout as Layout
import Component.Toast as Toast
import FeatherIcons
import Html exposing (Html, button, div, nav, span, text)
import Html.Attributes exposing (attribute, class, style)
import Html.Events exposing (onClick)
import I18n exposing (MsgKey(..), t)
import Lang exposing (Lang)
import PocketBaseAuth exposing (AuthState(..), AuthUser)
import Route exposing (Route(..), toHref)
import SiteSettings exposing (SiteSettings)
import Types exposing (Msg(..), Page(..), Toast, ToastKind(..))
import UiStrings exposing (UiStrings)
import View.Icons exposing (featherIcon)


{-| The whole page.

  - `isEmbed` — an embedded map has no header, drawer or footer.
  - `presentationMode` — the header keeps only the brand and the stop button.
  - `main` is the app's `<main id="main-content">`; `overlays` are rendered
    over the page.

-}
view :
    { site : SiteSettings
    , lang : Lang
    , authState : AuthState
    , menuOpen : Bool
    , presentationMode : Bool
    , isEmbed : Bool
    , activePage : Page
    , toasts : List Toast
    , attributes : List (Html.Attribute Msg)
    , main : Html Msg
    , overlays : List (Html Msg)
    }
    -> List (Html Msg)
view config =
    let
        lang =
            config.lang

        strings =
            UiStrings.forLang lang

        isMapPage =
            case config.activePage of
                PageMap ->
                    True

                _ ->
                    False

        isLocationsPage =
            case config.activePage of
                PageLocations _ ->
                    True

                _ ->
                    False

        showNavigation =
            not config.isEmbed && not config.presentationMode
    in
    Layout.view
        { site = config.site
        , strings = strings
        , attributes = config.attributes
        , home = { href = toHref RouteMap, onClick = Nothing }
        , links =
            if showNavigation then
                [ { label = t lang NavHome
                  , href = toHref RouteMap
                  , mobileOnly = False
                  , isActive = isMapPage
                  }
                , { label = t lang NavLocations
                  , href = toHref RouteLocations
                  , mobileOnly = False
                  , isActive = isLocationsPage
                  }
                ]

            else
                []
        , headerActions =
            viewPresentationButton lang config.presentationMode
                :: (if showNavigation then
                        [ Account.viewHeader (account strings config.authState) ]

                    else
                        []
                   )
        , showHeader = not config.isEmbed
        , menu =
            if showNavigation then
                Just
                    { isOpen = config.menuOpen
                    , onToggle = ToggleMenu
                    , onClose = CloseMenu
                    , content =
                        \links ->
                            [ nav [ class "p-4", attribute "aria-label" strings.mainNav ] [ links ]
                            , div [ class "p-4 border-t border-border-default" ]
                                [ Account.viewDrawer (account strings config.authState) ]
                            ]
                    }

            else
                Nothing
        , main = config.main
        , aboveFooter =
            if isMapPage then
                []

            else
                [ viewFeedLinks lang strings config.site ]
        , footer =
            if isMapPage then
                Nothing

            else
                Just { topMargin = False, extra = [] }
        , scrollToTop = Nothing
        , toasts = Just (List.map toSharedToast config.toasts)
        , overlays = config.overlays
        }


viewPresentationButton : Lang -> Bool -> Html Msg
viewPresentationButton lang presentationMode =
    button
        [ onClick TogglePresentationMode
        , class "p-2 rounded-lg text-white hover:bg-white/10"
        , style "cursor" "pointer"
        , attribute "aria-label"
            (if presentationMode then
                t lang A11yPresentationStop

             else
                t lang A11yPresentationStart
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


{-| What the shared account controls need: the signed-in user, if any.
-}
account : UiStrings -> AuthState -> { strings : UiStrings, user : Maybe AuthUser, onSignIn : Msg, onSignOut : Msg }
account strings authState =
    { strings = strings
    , user =
        case authState of
            Authenticated user ->
                Just user

            NotAuthenticated ->
                Nothing
    , onSignIn = LoginClicked
    , onSignOut = LogOut
    }


viewFeedLinks : Lang -> UiStrings -> SiteSettings -> Html Msg
viewFeedLinks lang strings site =
    let
        siteUrl =
            site.site.url
    in
    FeedLinks.view
        { label = t lang FeedsLabel
        , cards = []
        , feeds =
            Just
                { icon = FeatherIcons.rss
                , title = t lang FeedsTitle
                , description = t lang FeedsDescription
                , links =
                    [ { label = t lang FeedAtom, href = siteUrl ++ "/kartta.atom" }
                    , { label = t lang FeedRss, href = siteUrl ++ "/kartta.rss" }
                    , { label = t lang FeedJson, href = siteUrl ++ "/kartta.json" }
                    , { label = t lang FeedGeoJson, href = siteUrl ++ "/kartta.geo.json" }
                    ]
                }
        , newTabHint = strings.newTabHint
        }


toSharedToast : Toast -> Toast.Toast Msg
toSharedToast toast =
    { id = String.fromInt toast.id
    , title = Nothing
    , body = toast.message
    , variant =
        case toast.kind of
            ToastInfo ->
                Toast.Default

            ToastSuccess ->
                Toast.Success

            ToastError ->
                Toast.Danger
    , onClose = Just (DismissToast toast.id)
    }
