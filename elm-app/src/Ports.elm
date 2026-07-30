port module Ports exposing
    ( InitMapOptions
    , MarkerData
    , addMarkers
    , callbackParams
    , clearAuthToken
    , destroyMap
    , focusElement
    , focusMapOnMarker
    , focusMobileNav
    , getCallbackParams
    , initMap
    , initiateOAuth
    , kmlParsed
    , mapMarkerMoved
    , markerClicked
    , oauthPopupResult
    , parseKml
    , restoreMapView
    , saveAuthToken
    , saveFilterState
    , setMapMarker
    , setMapStyle
    )

import Json.Decode as Json


type alias InitMapOptions =
    { containerId : String
    , lat : Float
    , lon : Float
    , zoom : Int
    , markerLat : Maybe Float
    , markerLon : Maybe Float
    , draggable : Bool
    , mapStyle : String
    }


type alias MarkerData =
    { id : String
    , lat : Float
    , lon : Float
    , title : String
    , date : String
    , isEvent : Bool
    , tags : List String
    , cancelled : Bool
    }


port initMap : InitMapOptions -> Cmd msg


port setMapStyle : { containerId : String, mapStyle : String } -> Cmd msg


port addMarkers : List MarkerData -> Cmd msg


port markerClicked : (String -> msg) -> Sub msg


port focusMobileNav : () -> Cmd msg


{-| Move focus to an element by id. Used to return focus to the control that
opened a dismissed overlay, which the browser otherwise drops to `<body>`.
-}
port focusElement : String -> Cmd msg


port initiateOAuth : String -> Cmd msg


port oauthPopupResult : ({ token : String, model : String } -> msg) -> Sub msg


port saveAuthToken : { token : String, model : String } -> Cmd msg


port clearAuthToken : () -> Cmd msg


port saveFilterState : { hiddenTags : List String, eventsFilter : String } -> Cmd msg


port setMapMarker : { lat : Float, lon : Float } -> Cmd msg


port destroyMap : String -> Cmd msg


port mapMarkerMoved : ({ lat : Float, lon : Float } -> msg) -> Sub msg


port getCallbackParams : () -> Cmd msg


port callbackParams : ({ codeVerifier : String, state : String } -> msg) -> Sub msg


port parseKml : String -> Cmd msg


port kmlParsed : (Json.Value -> msg) -> Sub msg


port focusMapOnMarker : { lat : Float, lon : Float, id : String, title : String, date : String, cancelled : Bool } -> Cmd msg


port restoreMapView : () -> Cmd msg
