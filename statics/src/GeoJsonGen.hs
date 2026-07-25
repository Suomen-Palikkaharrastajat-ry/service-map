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
                            ]
                    ]

generateGeoJson :: [PB.Location] -> IO String
generateGeoJson locs = do
    let features = [f | loc <- locs, Just f <- [locationToFeature loc]]
    return $
        TL.unpack $
            TLE.decodeUtf8 $
                encode $
                    object
                        [ "type" .= ("FeatureCollection" :: String)
                        , "features" .= features
                        ]
