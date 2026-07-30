module GeoJsonGen (
    generateGeoJson,
) where

import Data.Aeson (Value (..), encode, object, toJSON, (.=))
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TLE
import Data.Time (UTCTime)
import Data.Time.Format (defaultTimeLocale, formatTime)
import qualified PocketBase as PB

toRfc3339 :: Maybe UTCTime -> Value
toRfc3339 Nothing = Null
toRfc3339 (Just t) = toJSON (formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%SZ" t)

locationToFeature :: PB.Location -> Maybe Value
locationToFeature loc = case PB.locationPoint loc of
    Nothing -> Nothing
    Just pt
        | PB.geoLat pt == 0 && PB.geoLon pt == 0 -> Nothing
        | otherwise ->
            Just $
                object
                    [ "type" .= ("Feature" :: String)
                    , "geometry"
                        .= object
                            [ "type" .= ("Point" :: String)
                            , "coordinates" .= toJSON [PB.geoLon pt, PB.geoLat pt]
                            ]
                    , "properties"
                        .= object
                            [ "id" .= PB.locationId loc
                            , "title" .= T.unpack (PB.locationTitle loc)
                            , "description" .= maybe Null (toJSON . T.unpack) (PB.locationDescription loc)
                            , "start_date" .= toRfc3339 (PB.locationStartDate loc)
                            , "end_date" .= toRfc3339 (PB.locationEndDate loc)
                            , "location" .= maybe Null (toJSON . T.unpack) (PB.locationLocation loc)
                            , "url" .= maybe Null (toJSON . T.unpack) (PB.locationUrl loc)
                            , "tags" .= map T.unpack (PB.locationTags loc)
                            , "opening_hours" .= maybe Null (toJSON . T.unpack) (PB.locationOpeningHours loc)
                            , "image" .= maybe Null (toJSON . T.unpack) (PB.locationImage loc)
                            , "image_description" .= maybe Null (toJSON . T.unpack) (PB.locationImageDesc loc)
                            , "state" .= T.unpack (PB.locationState loc)
                            , "point" .= object ["lat" .= PB.geoLat pt, "lon" .= PB.geoLon pt]
                            ]
                    ]

eventToFeature :: PB.Event -> Maybe Value
eventToFeature ev = case PB.eventPoint ev of
    Nothing -> Nothing
    Just pt
        | PB.geoLat pt == 0 && PB.geoLon pt == 0 -> Nothing
        | otherwise ->
            Just $
                object
                    [ "type" .= ("Feature" :: String)
                    , "geometry"
                        .= object
                            [ "type" .= ("Point" :: String)
                            , "coordinates" .= toJSON [PB.geoLon pt, PB.geoLat pt]
                            ]
                    , "properties"
                        .= object
                            [ "id" .= PB.eventId ev
                            , "title" .= T.unpack (PB.eventTitle ev)
                            , "description" .= maybe Null (toJSON . T.unpack) (PB.eventDescription ev)
                            , "start_date" .= toRfc3339 (Just (PB.eventStartDate ev))
                            , "end_date" .= toRfc3339 (PB.eventEndDate ev)
                            , "location" .= maybe Null (toJSON . T.unpack) (PB.eventLocation ev)
                            , "url" .= maybe Null (toJSON . T.unpack) (PB.eventUrl ev)
                            , "tags" .= map T.unpack (PB.eventTags ev)
                            , "type" .= ("event" :: String)
                            , "all_day" .= PB.eventAllDay ev
                            , "image" .= maybe Null (toJSON . T.unpack) (PB.eventImage ev)
                            , "image_description" .= maybe Null (toJSON . T.unpack) (PB.eventImageDesc ev)
                            , "state" .= T.unpack (PB.eventState ev)
                            , "cancelled" .= PB.eventCancelled ev
                            , "point" .= object ["lat" .= PB.geoLat pt, "lon" .= PB.geoLon pt]
                            ]
                    ]

generateGeoJson :: [PB.Location] -> [PB.Event] -> IO String
generateGeoJson locs evs = do
    let locFeatures = [f | loc <- locs, Just f <- [locationToFeature loc]]
    let evFeatures = [f | ev <- evs, Just f <- [eventToFeature ev]]
    let features = locFeatures ++ evFeatures
    return $
        TL.unpack $
            TLE.decodeUtf8 $
                encode $
                    object
                        [ "type" .= ("FeatureCollection" :: String)
                        , "features" .= features
                        ]
