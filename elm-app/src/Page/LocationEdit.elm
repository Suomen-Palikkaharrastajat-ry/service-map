module Page.LocationEdit exposing (init, view)

{-| Location edit page model initialization and view delegation.
-}

import Api
import Date
import DatePicker
import FinnishTime
import Html exposing (Html)
import Lang exposing (Lang)
import RemoteData
import Time exposing (Posix)
import Types exposing (FormStatus(..), LocationEditPage, Msg(..), emptyLocationFormData)
import View.LocationForm


init : Time.Posix -> String -> Maybe String -> String -> ( LocationEditPage, Cmd Msg )
init now pbBaseUrl maybeToken id =
    let
        currentDate =
            Date.fromPosix (FinnishTime.helsinkiZone now) now

        startDatePicker =
            DatePicker.initFromDate currentDate

        endDatePicker =
            DatePicker.initFromDate currentDate
    in
    ( { location = RemoteData.Loading
      , form = emptyLocationFormData
      , startDatePicker = startDatePicker
      , endDatePicker = endDatePicker
      , formStatus = FormIdle
      , mapStyle = Types.OsmStyle
      }
    , Api.fetchLocation pbBaseUrl maybeToken id EditGotLocation
    )


view : Lang -> LocationEditPage -> Html Msg
view lang =
    View.LocationForm.viewEdit lang
