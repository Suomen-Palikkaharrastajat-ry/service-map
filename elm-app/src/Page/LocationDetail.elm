module Page.LocationDetail exposing (init, view)

{-| Location detail page model initialization and view delegation.
-}

import Api
import Html exposing (Html)
import Lang exposing (Lang)
import PocketBaseAuth exposing (AuthState)
import RemoteData
import Types exposing (LocationDetailPage, Msg(..))
import View.LocationDetail


init : String -> Maybe String -> String -> ( LocationDetailPage, Cmd Msg )
init pbBaseUrl maybeToken id =
    ( { location = RemoteData.Loading
      , deleteConfirm = False
      }
    , Api.fetchLocation pbBaseUrl maybeToken id DetailGotLocation
    )


view : Lang -> String -> Bool -> String -> AuthState -> String -> LocationDetailPage -> Html Msg
view lang =
    View.LocationDetail.view lang
