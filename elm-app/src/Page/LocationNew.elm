module Page.LocationNew exposing (init, view)

import Date
import DatePicker
import DateUtils
import Html exposing (Html, div, h2, text)
import Html.Attributes exposing (class)
import I18n exposing (MsgKey(..), t)
import Time exposing (Posix)
import Types exposing (FormStatus(..), LocationNewPage, Msg(..), emptyLocationFormData)
import View.LocationForm


init : Posix -> ( LocationNewPage, Cmd Msg )
init now =
    let
        currentDate =
            Date.fromPosix (DateUtils.helsinkiZone now) now

        startDatePicker =
            DatePicker.initFromDate currentDate

        endDatePicker =
            DatePicker.initFromDate currentDate
    in
    ( { form = emptyLocationFormData
      , startDatePicker = startDatePicker
      , endDatePicker = endDatePicker
      , formStatus = FormIdle
      , mapStyle = Types.OsmStyle
      }
    , Cmd.none
    )


view : LocationNewPage -> Html Msg
view page =
    div [ class "max-w-2xl mx-auto p-4 w-full" ]
        [ h2 [ class "type-h3 mb-4" ] [ text (t LocationListNew) ]
        , div [ class "mb-6 p-4 border rounded bg-bg-subtle" ]
            [ View.LocationForm.view page.form page.startDatePicker page.endDatePicker page.formStatus page.mapStyle ]
        ]
