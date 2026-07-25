port module Ports exposing
    ( InitMapOptions
    , MarkerData
    , addMarkers
    , callbackParams
    , clearAuthToken
    , destroyMap
    , focusMobileNav
    , getCallbackParams
    , initMap
    , initiateOAuth
    , kmlParsed
    , mapMarkerMoved
    , markerClicked
    , oauthPopupResult
    , parseKml
    , saveAuthToken
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
    }


port initMap : InitMapOptions -> Cmd msg


port setMapStyle : { containerId : String, mapStyle : String } -> Cmd msg


port addMarkers : List MarkerData -> Cmd msg


port markerClicked : (String -> msg) -> Sub msg


port focusMobileNav : () -> Cmd msg


port initiateOAuth : String -> Cmd msg


port oauthPopupResult : ({ token : String, model : String } -> msg) -> Sub msg


port saveAuthToken : { token : String, model : String } -> Cmd msg


port clearAuthToken : () -> Cmd msg


port setMapMarker : { lat : Float, lon : Float } -> Cmd msg


port destroyMap : String -> Cmd msg


port mapMarkerMoved : ({ lat : Float, lon : Float } -> msg) -> Sub msg


port getCallbackParams : () -> Cmd msg


port callbackParams : ({ codeVerifier : String, state : String } -> msg) -> Sub msg


port parseKml : String -> Cmd msg


port kmlParsed : (Json.Value -> msg) -> Sub msg
