module LayoutTest exposing (suite)

{-| Unit tests for page layout components (Layout.elm).
-}

import Component.Footer.Family as Family
import Expect
import Html.Attributes
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import View.Layout as Layout


suite : Test
suite =
    describe "View.Layout"
        [ describe "viewBrandFooter"
            [ test "is the shared family footer, unmodified" <|
                \_ ->
                    Layout.viewBrandFooter
                        |> Expect.equal
                            (Family.view
                                { currentSite = "https://kartta.palikkaharrastajat.fi"
                                , year = 2026
                                , topMargin = False
                                , extra = []
                                }
                            )
            , test "links to every other family site and not to itself" <|
                \_ ->
                    Layout.viewBrandFooter
                        |> Query.fromHtml
                        |> Query.find [ Selector.tag "ul" ]
                        |> Expect.all
                            [ Query.findAll [ Selector.tag "a" ]
                                >> Query.count (Expect.equal (List.length Family.links - 1))
                            , Query.hasNot
                                [ Selector.attribute (Html.Attributes.href "https://kartta.palikkaharrastajat.fi") ]
                            ]
            ]
        ]
