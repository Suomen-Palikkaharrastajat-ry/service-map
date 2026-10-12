module View.LocationForm exposing (view, viewEdit)

{-| View module for creating and editing locations.
-}

import Component.Button as Button
import Component.Form as Form
import Component.LoadState as LoadState
import Component.Toggle as Toggle
import DatePicker
import FeatherIcons
import File exposing (File)
import FinnishDatePicker
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import I18n exposing (MsgKey(..), stateLabel, t)
import Lang exposing (Lang)
import OpeningHours.Editor
import OpeningHours.I18n
import RemoteData
import Route exposing (Route(..))
import Types
    exposing
        ( FormStatus(..)
        , LocationEditPage
        , LocationFormData
        , LocationState(..)
        , Msg(..)
        , locationStateToString
        )
import View.MapWidget


type alias FormMsgs =
    { onFieldChanged : String -> String -> Msg
    , onStartDatePickerChanged : DatePicker.Msg -> Msg
    , onEndDatePickerChanged : DatePicker.Msg -> Msg
    , onOpeningHoursMsg : OpeningHours.Editor.Msg -> Msg
    , onFileSelected : File -> Msg
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
    , onStartDatePickerChanged = NewStartDatePickerChanged
    , onEndDatePickerChanged = NewEndDatePickerChanged
    , onOpeningHoursMsg = NewFormOpeningHoursMsg
    , onFileSelected = NewFormFileSelected
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
    , onStartDatePickerChanged = EditStartDatePickerChanged
    , onEndDatePickerChanged = EditEndDatePickerChanged
    , onOpeningHoursMsg = EditFormOpeningHoursMsg
    , onFileSelected = EditFormFileSelected
    , onToggleMapStyle = EditFormToggleMapStyle
    , onGeocode = EditFormGeocode
    , startDateInputId = "start-date-edit"
    , endDateInputId = "end-date-edit"
    , mapContainerId = "edit-map"
    , onSubmit = EditFormSubmit
    }


view : Lang -> LocationFormData -> DatePicker.DatePicker -> DatePicker.DatePicker -> FormStatus -> Types.MapStyle -> Html Msg
view lang formData startDatePicker endDatePicker formStatus mapStyle =
    viewSharedFields lang createFormMsgs formData (Types.isValidForm formData) startDatePicker endDatePicker formStatus False mapStyle


viewEdit : Lang -> LocationEditPage -> Html Msg
viewEdit lang editPage =
    let
        isValid =
            case editPage.location of
                RemoteData.Success _ ->
                    Types.isValidForm editPage.form

                _ ->
                    False
    in
    Html.div [ Attr.class "max-w-2xl mx-auto p-4 w-full" ]
        [ Html.h2 [ Attr.class "type-h3 mb-4" ] [ Html.text (t lang LocationListEdit) ]
        , LoadState.view
            { loadingLabel = t lang Loading
            , errorMessage = \_ -> t lang ErrorUnknown
            , onRetry = Nothing
            , retryLabel = ""
            }
            (Types.fromRemoteData editPage.location)
            (\_ ->
                viewSharedFields lang editFormMsgs editPage.form isValid editPage.startDatePicker editPage.endDatePicker editPage.formStatus True editPage.mapStyle
            )
        ]


viewSharedFields : Lang -> FormMsgs -> LocationFormData -> Bool -> DatePicker.DatePicker -> DatePicker.DatePicker -> FormStatus -> Bool -> Types.MapStyle -> Html Msg
viewSharedFields lang msgs form isValid startDatePicker endDatePicker formStatus isEdit mapStyle =
    let
        titleField =
            Form.defaultField "title" (t lang FormTitle)
    in
    Html.form
        [ Events.onSubmit msgs.onSubmit
        , Attr.class "flex flex-col gap-4"
        ]
        [ Form.textInput
            { titleField | required = True }
            { value = form.title
            , onInput = msgs.onFieldChanged "title"
            , inputType = Form.Text
            , placeholder = Nothing
            }
        , viewTagSelect lang form.tag (\v -> msgs.onFieldChanged "tag" v)
        , Form.textInput
            (Form.defaultField "location" (t lang FormLocation))
            { value = form.location
            , onInput = msgs.onFieldChanged "location"
            , inputType = Form.Text
            , placeholder = Nothing
            }
        , viewGeocodeSection lang msgs form mapStyle
        , Form.textarea
            (Form.defaultField "description" (t lang FormDescription))
            { value = form.description
            , onInput = msgs.onFieldChanged "description"
            , rows = 4
            }
        , Html.map msgs.onOpeningHoursMsg (OpeningHours.Editor.view (OpeningHours.I18n.forCode (Lang.toString lang)) form.openingHours)
        , Form.textInput
            (Form.defaultField "url" (t lang FormUrl))
            { value = form.url
            , onInput = msgs.onFieldChanged "url"
            , inputType = Form.Url
            , placeholder = Nothing
            }
        , viewImageSection lang msgs isEdit form
        , viewDateSection lang msgs form startDatePicker endDatePicker
        , viewStateSelect lang form.state (\v -> msgs.onFieldChanged "state" v)
        , viewFormButtons lang formStatus isValid
        ]


viewGeocodeSection : Lang -> FormMsgs -> LocationFormData -> Types.MapStyle -> Html Msg
viewGeocodeSection lang msgs form mapStyle =
    Html.div [ Attr.class "flex flex-col gap-2" ]
        [ Html.div [ Attr.class "flex items-center gap-2 justify-between" ]
            [ Button.new { label = t lang FormGeocode, onClick = msgs.onGeocode }
                |> Button.withVariant Button.Accent
                |> Button.withSize Button.Small
                |> Button.withIcon FeatherIcons.mapPin
                |> Button.withDisabled (String.isEmpty (String.trim form.location))
                |> Button.toHtml
            , Toggle.view
                { id = "map-style-toggle"
                , label = t lang FormUsePreciseMap
                , checked = mapStyle == Types.OsmStyle
                , onToggle = \_ -> msgs.onToggleMapStyle
                , disabled = False
                }
            ]
        , Html.div [ Attr.class "flex gap-2" ]
            [ Html.div [ Attr.class "flex-1" ]
                [ let
                    latField =
                        Form.defaultField "lat" (t lang FormLat)
                  in
                  Form.textInput
                    { latField | required = True }
                    { value = form.lat
                    , onInput = msgs.onFieldChanged "lat"
                    , inputType = Form.Number { step = "0.000001" }
                    , placeholder = Nothing
                    }
                ]
            , Html.div [ Attr.class "flex-1" ]
                [ let
                    lonField =
                        Form.defaultField "lon" (t lang FormLon)
                  in
                  Form.textInput
                    { lonField | required = True }
                    { value = form.lon
                    , onInput = msgs.onFieldChanged "lon"
                    , inputType = Form.Number { step = "0.000001" }
                    , placeholder = Nothing
                    }
                ]
            ]
        , View.MapWidget.view { containerId = msgs.mapContainerId }
        ]


viewImageSection : Lang -> FormMsgs -> Bool -> LocationFormData -> Html Msg
viewImageSection lang msgs showExistingIfPresent form =
    let
        preview =
            case form.imagePreviewUrl of
                Just previewUrl ->
                    Just { src = previewUrl, alt = t lang FormImagePreview }

                Nothing ->
                    if showExistingIfPresent && form.hasExistingImage then
                        case form.existingImageUrl of
                            Just url ->
                                Just { src = url, alt = t lang FormImageCurrent }

                            Nothing ->
                                Nothing

                    else
                        Nothing
    in
    Html.div [ Attr.class "flex flex-col gap-1" ]
        [ Form.fileInput
            (Form.defaultField "loc-image" (t lang FormImage))
            { accept = "image/*"
            , onFile = msgs.onFileSelected
            , preview = preview
            }
        , Form.textInput
            (Form.defaultField "loc-image-desc" (t lang FormImageAlt))
            { value = form.imageDescription
            , onInput = msgs.onFieldChanged "imageDescription"
            , inputType = Form.Text
            , placeholder = Just (t lang FormImageAlt)
            }
        ]


viewDateSection : Lang -> FormMsgs -> LocationFormData -> DatePicker.DatePicker -> DatePicker.DatePicker -> Html Msg
viewDateSection lang msgs form startDatePicker endDatePicker =
    Form.fieldRow
        [ FinnishDatePicker.field (I18n.locale lang)
            (FinnishDatePicker.defaultField msgs.startDateInputId (t lang FormStartDate))
            { picker = startDatePicker
            , selectedIsoDate = form.startDate
            , onMsg = msgs.onStartDatePickerChanged
            }
        , FinnishDatePicker.field (I18n.locale lang)
            (FinnishDatePicker.defaultField msgs.endDateInputId (t lang FormEndDate))
            { picker = endDatePicker
            , selectedIsoDate = form.endDate
            , onMsg = msgs.onEndDatePickerChanged
            }
        ]


viewStateSelect : Lang -> LocationState -> (String -> Msg) -> Html Msg
viewStateSelect lang currentState toMsg =
    Form.radioGroup
        { legend = t lang FormStatus
        , name = "loc-state"
        , required = False
        , error = Nothing
        }
        { options =
            [ { value = locationStateToString Draft, label = stateLabel lang Draft }
            , { value = locationStateToString Pending, label = stateLabel lang Pending }
            , { value = locationStateToString Published, label = stateLabel lang Published }
            ]
        , selected = locationStateToString currentState
        , onSelect = toMsg
        , layout = Form.Chips
        }


viewFormButtons : Lang -> FormStatus -> Bool -> Html Msg
viewFormButtons lang formStatus isValid =
    Html.div [ Attr.class "flex gap-2 pt-2" ]
        [ Button.submit
            { label =
                if formStatus == FormSubmitting then
                    t lang Saving

                else
                    t lang FormSave
            }
            |> Button.withVariant Button.Primary
            |> Button.withSize Button.Medium
            |> Button.withDisabled (formStatus == FormSubmitting || not isValid)
            |> Button.withLoading (formStatus == FormSubmitting)
            |> Button.toHtml
        , Button.new
            { label = t lang FormCancel
            , onClick = NavigateTo RouteLocations
            }
            |> Button.withVariant Button.Secondary
            |> Button.withSize Button.Medium
            |> Button.toHtml
        ]


viewTagSelect : Lang -> String -> (String -> Msg) -> Html Msg
viewTagSelect lang currentTag toMsg =
    Form.radioGroup
        { legend = t lang FormTag
        , name = "loc-tag"
        , required = True
        , error = Nothing
        }
        { options =
            [ { value = "exhibition", label = t lang TagExhibition }
            , { value = "store", label = t lang TagStore }
            , { value = "fleamarket", label = t lang TagFleamarket }
            , { value = "museum", label = t lang TagMuseum }
            , { value = "other", label = t lang TagOther }
            ]
        , selected = currentTag
        , onSelect = toMsg
        , layout = Form.Chips
        }
