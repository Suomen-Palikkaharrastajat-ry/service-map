module LayoutTest exposing (suite)

{-| Unit tests for the page chrome (View.Layout).

The shell is rendered from this app's own `config.toml` (SiteFixture), so the
tests cover what a visitor gets: brand, navigation, feed links and the family
footer, and how embedding and presentation mode strip them down.

-}

import Expect
import Html exposing (Html, div, main_, text)
import Html.Attributes as Attr
import Json.Decode as Decode
import Lang exposing (Lang(..))
import SiteFixture
import SiteSettings exposing (SiteSettings)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Types exposing (AuthState(..), Msg, Page(..))
import View.Layout as Layout


site : SiteSettings
site =
    Decode.decodeString SiteSettings.localizedDecoder SiteFixture.json
        |> Result.toMaybe
        |> Maybe.andThen (SiteSettings.forLang Fi)
        |> Maybe.withDefault (SiteSettings.placeholder Fi)


type alias Options =
    { activePage : Page
    , isEmbed : Bool
    , presentationMode : Bool
    }


shell : Options -> Html Msg
shell options =
    div []
        (Layout.view
            { site = site
            , lang = Fi
            , authState = NotAuthenticated
            , menuOpen = True
            , presentationMode = options.presentationMode
            , isEmbed = options.isEmbed
            , activePage = options.activePage
            , toasts = []
            , attributes = []
            , main = main_ [ Attr.id "main-content" ] [ text "Sisältö" ]
            , overlays = []
            }
        )


listPage : Html Msg
listPage =
    shell { activePage = PageNotFound, isEmbed = False, presentationMode = False }


mapPage : Html Msg
mapPage =
    shell { activePage = PageMap, isEmbed = False, presentationMode = False }


suite : Test
suite =
    describe "View.Layout"
        [ test "config.toml resolves and decodes" <|
            \_ ->
                site.site.title
                    |> Expect.equal "Palikkakartta"
        , describe "header"
            [ test "renders the brand title from config.toml and the navigation" <|
                \_ ->
                    listPage
                        |> Query.fromHtml
                        |> Query.find [ Selector.tag "header" ]
                        |> Query.has [ Selector.text "Palikkakartta", Selector.text "Kartta", Selector.text "Kohteet" ]
            , test "presentation mode keeps the brand but drops navigation and menu" <|
                \_ ->
                    shell { activePage = PageMap, isEmbed = False, presentationMode = True }
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.has [ Selector.tag "header", Selector.containing [ Selector.text "Palikkakartta" ] ]
                            , Query.hasNot [ Selector.attribute (Attr.attribute "role" "dialog") ]
                            , Query.hasNot [ Selector.attribute (Attr.attribute "aria-controls" "mobile-nav") ]
                            ]
            , test "an embedded map has no header, drawer or footer" <|
                \_ ->
                    shell { activePage = PageMap, isEmbed = True, presentationMode = False }
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.hasNot [ Selector.tag "header" ]
                            , Query.hasNot [ Selector.attribute (Attr.attribute "role" "dialog") ]
                            , Query.hasNot [ Selector.tag "footer" ]
                            , Query.has [ Selector.id "main-content" ]
                            ]
            ]
        , describe "footer"
            [ test "the map page has no footer and no feed links" <|
                \_ ->
                    mapPage
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.hasNot [ Selector.tag "footer" ]
                            , Query.hasNot [ Selector.attribute (Attr.href "https://kartta.palikkaharrastajat.fi/kartta.atom") ]
                            ]
            , test "other pages have exactly one footer landmark" <|
                \_ ->
                    listPage
                        |> Query.fromHtml
                        |> Query.findAll [ Selector.tag "footer" ]
                        |> Query.count (Expect.equal 1)
            , test "feed links are built from the configured site URL" <|
                \_ ->
                    listPage
                        |> Query.fromHtml
                        |> Query.has
                            [ Selector.attribute (Attr.href "https://kartta.palikkaharrastajat.fi/kartta.atom")
                            , Selector.attribute (Attr.href "https://kartta.palikkaharrastajat.fi/kartta.geo.json")
                            ]
            , test "links to every other family site and not to itself" <|
                \_ ->
                    listPage
                        |> Query.fromHtml
                        |> Query.find [ Selector.tag "footer" ]
                        |> Query.find [ Selector.tag "ul" ]
                        |> Expect.all
                            [ Query.findAll [ Selector.tag "a" ] >> Query.count (Expect.equal 8)
                            , Query.has [ Selector.attribute (Attr.href "https://kalenteri.palikkaharrastajat.fi") ]
                            , Query.hasNot [ Selector.attribute (Attr.href "https://kartta.palikkaharrastajat.fi") ]
                            ]
            ]
        ]
