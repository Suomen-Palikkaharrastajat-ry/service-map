module Page.LocationDetail exposing (init, view)

import Api
import Html exposing (Html)
import RemoteData
import Types exposing (AuthState, LocationDetailPage, Msg(..))
import View.LocationDetail


init : String -> Maybe String -> String -> ( LocationDetailPage, Cmd Msg )
init pbBaseUrl maybeToken id =
    ( { location = RemoteData.Loading
      , deleteConfirm = False
      }
    , Api.fetchLocation pbBaseUrl maybeToken id DetailGotLocation
    )


view : String -> AuthState -> String -> LocationDetailPage -> Html Msg
view =
    View.LocationDetail.view
