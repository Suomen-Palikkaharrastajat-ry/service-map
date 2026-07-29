module Types exposing (..)

import Browser
import Browser.Navigation as Nav
import DatePicker
import File exposing (File)
import Html exposing (Html)
import Http
import Json.Decode
import OpeningHours.Editor
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import Time
import Url exposing (Url)


type alias GeoPoint =
    { lat : Float
    , lon : Float
    }


hasValidCoordinates : GeoPoint -> Bool
hasValidCoordinates point =
    not (point.lat == 0 && point.lon == 0)


type LocationState
    = Draft
    | Pending
    | Published
    | Deleted


locationStateFromString : String -> Maybe LocationState
locationStateFromString s =
    case s of
        "draft" ->
            Just Draft

        "pending" ->
            Just Pending

        "published" ->
            Just Published

        "deleted" ->
            Just Deleted

        _ ->
            Nothing


locationStateToString : LocationState -> String
locationStateToString state =
    case state of
        Draft ->
            "draft"

        Pending ->
            "pending"

        Published ->
            "published"

        Deleted ->
            "deleted"


type alias Location =
    { id : String
    , title : String
    , description : Maybe String
    , startDate : Maybe String
    , endDate : Maybe String
    , location : Maybe String
    , url : Maybe String
    , image : Maybe String
    , imageDescription : Maybe String
    , point : GeoPoint
    , tags : List String
    , openingHours : Maybe String
    , state : LocationState
    }


type alias Event =
    { id : String
    , title : String
    , description : Maybe String
    , startDate : String
    , endDate : String
    , location : Maybe String
    , url : Maybe String
    , image : Maybe String
    , point : GeoPoint
    , allDay : Bool
    }


type alias AuthUser =
    { id : String
    , name : String
    , email : String
    , token : String
    }


type AuthState
    = NotAuthenticated
    | Authenticated AuthUser


isAuthenticated : AuthState -> Bool
isAuthenticated authState =
    case authState of
        Authenticated _ ->
            True

        NotAuthenticated ->
            False


getToken : AuthState -> Maybe String
getToken authState =
    case authState of
        Authenticated user ->
            Just user.token

        NotAuthenticated ->
            Nothing


type alias Flags =
    { pbBaseUrl : String
    , authToken : Maybe String
    , authModel : Maybe String
    , now : Int
    , hiddenTags : List String
    , eventsHidden : Bool
    , isEmbed : Bool
    }


type FormStatus
    = FormIdle
    | FormSubmitting
    | FormSuccess
    | FormError String


type alias LocationFormData =
    { title : String
    , description : String
    , location : String
    , lat : String
    , lon : String
    , geocodingEnabled : Bool
    , url : String
    , startDate : String
    , endDate : String
    , state : LocationState
    , imageFile : Maybe File
    , imageDescription : String
    , hasExistingImage : Bool
    , existingImageUrl : Maybe String
    , imagePreviewUrl : Maybe String
    , tag : String
    , openingHours : OpeningHours.Editor.Model
    }


emptyLocationFormData : LocationFormData
emptyLocationFormData =
    { title = ""
    , description = ""
    , location = ""
    , lat = ""
    , lon = ""
    , geocodingEnabled = True
    , url = ""
    , startDate = ""
    , endDate = ""
    , state = Published
    , imageFile = Nothing
    , imageDescription = ""
    , hasExistingImage = False
    , existingImageUrl = Nothing
    , imagePreviewUrl = Nothing
    , tag = "store"
    , openingHours = OpeningHours.Editor.init ""
    }


isValidForm : LocationFormData -> Bool
isValidForm form =
    not (String.isEmpty (String.trim form.title))
        && not (String.isEmpty form.tag)
        && not (String.isEmpty (String.trim form.lat))
        && not (String.isEmpty (String.trim form.lon))


type MapStyle
    = OsmStyle
    | BasemapStyle


type alias LocationNewPage =
    { form : LocationFormData
    , startDatePicker : DatePicker.DatePicker
    , endDatePicker : DatePicker.DatePicker
    , formStatus : FormStatus
    , mapStyle : MapStyle
    }


type alias LocationEditPage =
    { location : RemoteData Http.Error Location
    , form : LocationFormData
    , startDatePicker : DatePicker.DatePicker
    , endDatePicker : DatePicker.DatePicker
    , formStatus : FormStatus
    , mapStyle : MapStyle
    }


type alias LocationDetailPage =
    { location : RemoteData Http.Error Location
    , deleteConfirm : Bool
    }


type alias LocationsPage =
    { kmlImportStatus : KmlImportStatus
    , kmlQueue : List KmlPlacemark
    , importCount : Int
    }


type Page
    = PageMap
    | PageLocations LocationsPage
    | PageLocationNew LocationNewPage
    | PageLocationEdit String LocationEditPage
    | PageLocationDetail String LocationDetailPage
    | PageAuthCallback
    | PageNotFound
    | PageLoading


type SelectedMarker
    = SelectedLocation Location
    | SelectedEvent Event


type alias Model =
    { pbBaseUrl : String
    , key : Nav.Key
    , url : Url
    , page : Page
    , authState : AuthState
    , menuOpen : Bool
    , locations : RemoteData Http.Error (List Location)
    , events : RemoteData Http.Error (List Event)
    , selectedMarker : Maybe SelectedMarker
    , hiddenTags : List String
    , eventsHidden : Bool
    , isEmbed : Bool
    , now : Time.Posix
    , toasts : List Toast
    , nextToastId : Int
    }


type ToastKind
    = ToastInfo
    | ToastSuccess
    | ToastError


type alias Toast =
    { id : Int
    , kind : ToastKind
    , message : String
    }


type KmlImportStatus
    = KmlIdle
    | KmlParsing
    | KmlImporting Int Int
    | KmlDone Int
    | KmlError String


type alias KmlPlacemark =
    { name : String
    , description : String
    , lat : Maybe Float
    , lon : Maybe Float
    , dateStr : Maybe String
    }


decodeKmlPlacemark : Json.Decode.Decoder KmlPlacemark
decodeKmlPlacemark =
    Json.Decode.map5 KmlPlacemark
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "description" Json.Decode.string)
        (Json.Decode.maybe (Json.Decode.field "lat" Json.Decode.float))
        (Json.Decode.maybe (Json.Decode.field "lon" Json.Decode.float))
        (Json.Decode.maybe (Json.Decode.field "dateStr" Json.Decode.string))


type Msg
    = UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | NavigateTo Route
    | LocationsLoaded (Result Http.Error (List Location))
    | EventsLoaded (Result Http.Error (List Event))
    | GeoJsonLoaded (Result Http.Error { locations : List Location, events : List Event })
    | MarkerClicked String
    | SelectPrevMarker
    | SelectNextMarker
    | KeyDown String
    | ClosePanel
      -- Auth
    | LoginClicked
    | LogOut
    | OAuthPopupResult { token : String, model : String }
    | AuthCallbackReceived String String
    | GotOAuthToken (Result Http.Error AuthState)
      -- Menu
    | ToggleMenu
    | CloseMenu
      -- Form New
    | NewFormFieldChanged String String
    | NewFormDateChanged String String
    | NewStartDatePickerChanged DatePicker.Msg
    | NewEndDatePickerChanged DatePicker.Msg
    | NewFormFileSelected File
    | NewFormToggleGeocode
    | NewFormOpeningHoursMsg OpeningHours.Editor.Msg
    | NewFormGeocode
    | NewFormGotGeocode (Result Http.Error (Maybe GeoPoint))
    | NewFormSubmit
    | NewFormGotSave (Result Http.Error Location)
    | NewFormToggleMapStyle
      -- Form Edit
    | EditGotLocation (Result Http.Error Location)
    | EditFormFieldChanged String String
    | EditFormDateChanged String String
    | EditStartDatePickerChanged DatePicker.Msg
    | EditEndDatePickerChanged DatePicker.Msg
    | EditFormFileSelected File
    | EditFormToggleGeocode
    | EditFormOpeningHoursMsg OpeningHours.Editor.Msg
    | EditFormGeocode
    | EditFormGotGeocode (Result Http.Error (Maybe GeoPoint))
    | EditFormSubmit
    | EditFormGotSave (Result Http.Error Location)
    | EditFormToggleMapStyle
      -- Form Detail
    | DetailDelete
    | DetailDeleteConfirm
    | DetailDeleteCancel
    | DetailGotDelete (Result Http.Error Location)
      -- Toasts
    | AddToast ToastKind String
    | DismissToast Int
      -- Detail View
    | DetailGotLocation (Result Http.Error Location)
      -- Maps (via ports)
    | MapMarkerMoved Float Float
    | ToggleTagVisibility String Bool
    | ToggleEventVisibility Bool
      -- KML Import
    | LocationKmlFileSelected File
    | LocationKmlGotContent String
    | LocationKmlParsed Json.Decode.Value
    | LocationKmlImportNext (Result Http.Error Location)
    | GotReverseGeocode (Result Http.Error String)
      -- Image preview
    | GotImagePreview String
