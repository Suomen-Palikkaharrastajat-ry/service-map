module View.LocationForm exposing (view, viewEdit)

import Component.Alert as Alert
import Component.Button as Button
import Component.Spinner as Spinner
import Component.Toggle as Toggle
import DatePicker
import FeatherIcons
import File exposing (File)
import Html exposing (Html, button, div, h2, img, input, label, p, text, textarea)
import Html.Attributes exposing (accept, alt, checked, class, disabled, for, id, name, placeholder, src, step, type_, value)
import Html.Events exposing (on, onCheck, onClick, onInput)
import I18n exposing (MsgKey(..), stateLabel, t)
import Json.Decode as Json
import OpeningHours.Editor
import OpeningHours.I18n
import RemoteData
import Route exposing (Route(..), toHref)
import Types
    exposing
        ( AuthState
        , FormStatus(..)
        , LocationEditPage
        , LocationFormData
        , LocationState(..)
        , Msg(..)
        , locationStateToString
        )
import View.FinnishDatePicker as FinnishDatePicker
import View.Icons exposing (featherIcon)
import View.MapWidget


type alias FormMsgs =
    { onFieldChanged : String -> String -> Msg
    , onDateChanged : String -> String -> Msg
    , onStartDatePickerChanged : DatePicker.Msg -> Msg
    , onEndDatePickerChanged : DatePicker.Msg -> Msg
    , onOpeningHoursMsg : OpeningHours.Editor.Msg -> Msg
    , onFileSelected : File -> Msg
    , onToggleGeocode : Msg
    , onToggleMapStyle : Msg
    , onGeocode : Msg
    , startDateInputId : String
    , endDateInputId : String
    , mapContainerId : String
    , onSubmit : Msg
    }


createFormMsgs : FormMsgs
createFormMsgs =
    { onFieldChanged = NewFormFieldChanged
    , onDateChanged = NewFormDateChanged
    , onStartDatePickerChanged = NewStartDatePickerChanged
    , onEndDatePickerChanged = NewEndDatePickerChanged
    , onOpeningHoursMsg = NewFormOpeningHoursMsg
    , onFileSelected = NewFormFileSelected
    , onToggleGeocode = NewFormToggleGeocode
    , onToggleMapStyle = NewFormToggleMapStyle
    , onGeocode = NewFormGeocode
    , startDateInputId = "start-date-create"
    , endDateInputId = "end-date-create"
    , mapContainerId = "create-map"
    , onSubmit = NewFormSubmit
    }


editFormMsgs : FormMsgs
editFormMsgs =
    { onFieldChanged = EditFormFieldChanged
    , onDateChanged = EditFormDateChanged
    , onStartDatePickerChanged = EditStartDatePickerChanged
    , onEndDatePickerChanged = EditEndDatePickerChanged
    , onOpeningHoursMsg = EditFormOpeningHoursMsg
    , onFileSelected = EditFormFileSelected
    , onToggleGeocode = EditFormToggleGeocode
    , onToggleMapStyle = EditFormToggleMapStyle
    , onGeocode = EditFormGeocode
    , startDateInputId = "start-date-edit"
    , endDateInputId = "end-date-edit"
    , mapContainerId = "edit-map"
    , onSubmit = EditFormSubmit
    }


view : LocationFormData -> DatePicker.DatePicker -> DatePicker.DatePicker -> FormStatus -> Types.MapStyle -> Html Msg
view formData startDatePicker endDatePicker formStatus mapStyle =
    viewSharedFields createFormMsgs formData (Types.isValidForm formData) startDatePicker endDatePicker formStatus False mapStyle


viewEdit : LocationEditPage -> Html Msg
viewEdit editPage =
    let
        isValid =
            case editPage.location of
                RemoteData.Success location ->
                    Types.isValidForm editPage.form

                _ ->
                    False
    in
    div [ class "max-w-2xl mx-auto p-4 w-full" ]
        [ h2 [ class "type-h3 mb-4" ] [ text (t LocationListEdit) ]
        , case editPage.location of
            RemoteData.Loading ->
                div [ class "flex justify-center py-8" ]
                    [ Spinner.view { size = Spinner.Medium, label = t Loading } ]

            RemoteData.Failure _ ->
                Alert.view
                    { alertType = Alert.Error
                    , title = Nothing
                    , body = [ text (t ErrorUnknown) ]
                    , customIcon = Nothing
                    , onDismiss = Nothing
                    }

            RemoteData.Success _ ->
                viewSharedFields editFormMsgs editPage.form isValid editPage.startDatePicker editPage.endDatePicker editPage.formStatus True editPage.mapStyle

            RemoteData.NotAsked ->
                text ""
        ]


viewSharedFields : FormMsgs -> LocationFormData -> Bool -> DatePicker.DatePicker -> DatePicker.DatePicker -> FormStatus -> Bool -> Types.MapStyle -> Html Msg
viewSharedFields msgs form isValid startDatePicker endDatePicker formStatus isEdit mapStyle =
    div [ class "flex flex-col gap-4" ]
        [ fieldText "title" (t FormTitle) form.title True msgs.onFieldChanged
        , viewTagSelect form.tag (\v -> msgs.onFieldChanged "tag" v)
        , fieldText "location" (t FormLocation) form.location False msgs.onFieldChanged
        , viewGeocodeSection msgs form mapStyle
        , fieldTextarea "description" (t FormDescription) form.description msgs.onFieldChanged
        , Html.map msgs.onOpeningHoursMsg (OpeningHours.Editor.view OpeningHours.I18n.finnish form.openingHours)
        , fieldText "url" (t FormUrl) form.url False msgs.onFieldChanged
        , viewImageSection msgs isEdit form
        , viewDateSection msgs form startDatePicker endDatePicker
        , viewStateSelect form.state (\v -> msgs.onFieldChanged "state" v)
        , viewFormButtons msgs formStatus isValid
        ]


viewGeocodeSection : FormMsgs -> LocationFormData -> Types.MapStyle -> Html Msg
viewGeocodeSection msgs form mapStyle =
    div [ class "flex flex-col gap-2" ]
        [ div [ class "flex items-center gap-2 justify-between" ]
            [ button
                [ onClick msgs.onGeocode
                , class "type-caption inline-flex items-center gap-1 whitespace-nowrap px-2 py-1 bg-brand-yellow text-brand rounded hover:opacity-90 disabled:opacity-60"
                , disabled (String.isEmpty (String.trim form.location))
                ]
                [ featherIcon FeatherIcons.mapPin 14, text (t FormGeocode) ]
            , Toggle.view
                { id = "map-style-toggle"
                , label = "Käytä tarkkaa karttaa (OSM)"
                , checked = mapStyle == Types.OsmStyle
                , onToggle = \_ -> msgs.onToggleMapStyle
                , disabled = False
                }
            ]
        , div [ class "flex gap-2" ]
            [ div [ class "flex-1" ]
                [ label [ class "type-caption text-text-muted block mb-1" ] [ text (t FormLat) ]
                , input
                    [ type_ "number"
                    , value form.lat
                    , step "0.000001"
                    , onInput (msgs.onFieldChanged "lat")
                    , class "w-full border rounded px-2 py-1 type-caption"
                    ]
                    []
                ]
            , div [ class "flex-1" ]
                [ label [ class "type-caption text-text-muted block mb-1" ] [ text (t FormLon) ]
                , input
                    [ type_ "number"
                    , value form.lon
                    , step "0.000001"
                    , onInput (msgs.onFieldChanged "lon")
                    , class "w-full border rounded px-2 py-1 type-caption"
                    ]
                    []
                ]
            ]
        , View.MapWidget.view { containerId = msgs.mapContainerId }
        ]


viewImageSection : FormMsgs -> Bool -> LocationFormData -> Html Msg
viewImageSection msgs showExistingIfPresent form =
    div [ class "flex flex-col gap-1" ]
        [ label [ class "type-body-small" ] [ text (t FormImage) ]
        , case form.imagePreviewUrl of
            Just previewUrl ->
                div [ class "mb-2" ]
                    [ img [ src previewUrl, alt "Esikatselu", class "max-h-32 rounded" ] [] ]

            Nothing ->
                if showExistingIfPresent && form.hasExistingImage then
                    case form.existingImageUrl of
                        Just url ->
                            div [ class "mb-2" ]
                                [ img [ src url, alt "Nykyinen kuva", class "max-h-32 rounded" ] [] ]

                        Nothing ->
                            text ""

                else
                    text ""
        , input
            [ type_ "file"
            , accept "image/*"
            , on "change" (Json.map msgs.onFileSelected fileDecoder)
            , class "type-caption file:mr-3 file:px-3 file:py-2 file:rounded file:border file:border-border-default file:bg-bg-subtle file:text-text-primary file:font-medium hover:file:bg-brand-yellow hover:file:text-brand focus-visible:ring-2 focus-visible:ring-brand"
            ]
            []
        , input
            [ type_ "text"
            , value form.imageDescription
            , onInput (msgs.onFieldChanged "imageDescription")
            , placeholder (t FormImageAlt)
            , class "border rounded px-2 py-1 type-caption"
            ]
            []
        ]


viewDateSection : FormMsgs -> LocationFormData -> DatePicker.DatePicker -> DatePicker.DatePicker -> Html Msg
viewDateSection msgs form startDatePicker endDatePicker =
    div [ class "flex flex-col gap-2" ]
        [ div [ class "flex gap-2 flex-wrap" ]
            [ div []
                [ label [ class "type-caption text-text-muted block mb-1", for msgs.startDateInputId ] [ text (t FormStartDate) ]
                , FinnishDatePicker.view
                    { picker = startDatePicker
                    , selectedIsoDate = form.startDate
                    , inputId = msgs.startDateInputId
                    }
                    |> Html.map msgs.onStartDatePickerChanged
                ]
            , div []
                [ label [ class "type-caption text-text-muted block mb-1", for msgs.endDateInputId ] [ text (t FormEndDate) ]
                , FinnishDatePicker.view
                    { picker = endDatePicker
                    , selectedIsoDate = form.endDate
                    , inputId = msgs.endDateInputId
                    }
                    |> Html.map msgs.onEndDatePickerChanged
                ]
            ]
        ]


viewStateSelect : LocationState -> (String -> Msg) -> Html Msg
viewStateSelect currentState toMsg =
    div [ class "flex flex-col gap-2" ]
        [ label [ class "type-body-small" ] [ text (t FormStatus) ]
        , div [ class "flex flex-wrap gap-3" ]
            [ viewStateRadio "loc-state-draft" "loc-state" Draft currentState toMsg
            , viewStateRadio "loc-state-pending" "loc-state" Pending currentState toMsg
            , viewStateRadio "loc-state-published" "loc-state" Published currentState toMsg
            ]
        ]


viewStateRadio : String -> String -> LocationState -> LocationState -> (String -> Msg) -> Html Msg
viewStateRadio inputId groupName radioState currentState toMsg =
    label
        [ for inputId
        , class "inline-flex items-center gap-2 border border-border-default rounded px-3 py-2 type-caption"
        ]
        [ input
            [ type_ "radio"
            , id inputId
            , name groupName
            , checked (currentState == radioState)
            , onClick (toMsg (locationStateToString radioState))
            ]
            []
        , text (stateLabel radioState)
        ]


viewFormButtons : FormMsgs -> FormStatus -> Bool -> Html Msg
viewFormButtons msgs formStatus isValid =
    div [ class "flex gap-2 pt-2" ]
        [ Button.view
            { label =
                if formStatus == FormSubmitting then
                    t Saving

                else
                    t FormSave
            , variant = Button.Primary
            , size = Button.Medium
            , onClick = msgs.onSubmit
            , disabled = formStatus == FormSubmitting || not isValid
            , loading = formStatus == FormSubmitting
            , ariaPressedState = Nothing
            }
        , Button.view
            { label = t FormCancel
            , variant = Button.Secondary
            , size = Button.Medium
            , onClick = NavigateTo RouteLocations
            , disabled = False
            , loading = False
            , ariaPressedState = Nothing
            }
        ]


fieldText : String -> String -> String -> Bool -> (String -> String -> Msg) -> Html Msg
fieldText fieldId labelText val required toMsg =
    div []
        [ label [ for fieldId, class "type-body-small block mb-1" ]
            [ text
                (if required then
                    labelText ++ " *"

                 else
                    labelText
                )
            ]
        , input
            [ type_ "text"
            , id fieldId
            , value val
            , onInput (toMsg fieldId)
            , class "w-full border rounded px-2 py-1"
            ]
            []
        ]


fieldTextarea : String -> String -> String -> (String -> String -> Msg) -> Html Msg
fieldTextarea fieldId labelText val toMsg =
    div []
        [ label [ for fieldId, class "type-body-small block mb-1" ] [ text labelText ]
        , textarea
            [ id fieldId
            , value val
            , onInput (toMsg fieldId)
            , Html.Attributes.rows 4
            , class "w-full border rounded px-2 py-1"
            ]
            []
        ]


fileDecoder : Json.Decoder File
fileDecoder =
    Json.at [ "target", "files" ] (Json.index 0 File.decoder)


viewTagSelect : String -> (String -> Msg) -> Html Msg
viewTagSelect currentTag toMsg =
    div [ class "flex flex-col gap-2" ]
        [ label [ class "type-body-small" ] [ text (t FormTag) ]
        , div [ class "flex flex-wrap gap-3" ]
            [ viewTagRadio "loc-tag-exhibition" "loc-tag" "exhibition" (t TagExhibition) currentTag toMsg
            , viewTagRadio "loc-tag-store" "loc-tag" "store" (t TagStore) currentTag toMsg
            , viewTagRadio "loc-tag-fleamarket" "loc-tag" "fleamarket" (t TagFleamarket) currentTag toMsg
            , viewTagRadio "loc-tag-museum" "loc-tag" "museum" (t TagMuseum) currentTag toMsg
            , viewTagRadio "loc-tag-other" "loc-tag" "other" (t TagOther) currentTag toMsg
            ]
        ]


viewTagRadio : String -> String -> String -> String -> String -> (String -> Msg) -> Html Msg
viewTagRadio inputId groupName radioValue labelText currentValue toMsg =
    label
        [ for inputId
        , class "inline-flex items-center gap-2 border border-border-default rounded px-3 py-2 type-caption cursor-pointer"
        ]
        [ input
            [ type_ "radio"
            , id inputId
            , name groupName
            , value radioValue
            , checked (currentValue == radioValue)
            , onClick (toMsg radioValue)
            ]
            []
        , text labelText
        ]
