module Page.LocationEdit exposing (init, view)

import Api
import Date
import DatePicker
import DateUtils
import Html exposing (Html)
import RemoteData
import Time exposing (Posix)
import Types exposing (FormStatus(..), LocationEditPage, Msg(..), emptyLocationFormData)
import View.LocationForm


init : Time.Posix -> String -> Maybe String -> String -> ( LocationEditPage, Cmd Msg )
init now pbBaseUrl maybeToken id =
    let
        currentDate =
            Date.fromPosix (DateUtils.helsinkiZone now) now

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


view : LocationEditPage -> Html Msg
view =
    View.LocationForm.viewEdit
