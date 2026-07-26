module PocketBase (
    Location (..),
    GeoPoint (..),
    PbList (..),
    fetchPublishedLocations,
    imageUrl,
) where

import qualified Config
import Data.Aeson (
    FromJSON (..),
    Value (Null, String),
    eitherDecode,
    withObject,
    (.!=),
    (.:),
    (.:?),
 )
import Data.Aeson.Types (Parser)
import Data.Char (isAsciiLower, isAsciiUpper, isDigit)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (UTCTime)
import Network.HTTP.Simple (getResponseBody, getResponseStatusCode, httpLBS, parseRequest)
import System.Environment (lookupEnv)

getPbBaseUrl :: IO String
getPbBaseUrl = do
    mUrl <- lookupEnv "POCKETBASE_URL"
    return $ case mUrl of
        Just url | not (null url) -> url
        _ -> Config.pbDefaultUrl

data GeoPoint = GeoPoint
    { geoLat :: Double
    , geoLon :: Double
    }
    deriving (Show, Eq)

instance FromJSON GeoPoint where
    parseJSON = withObject "GeoPoint" $ \o ->
        GeoPoint
            <$> o .: "lat"
            <*> o .: "lon"

data Location = Location
    { locationId :: String
    , locationTitle :: Text
    , locationDescription :: Maybe Text
    , locationStartDate :: Maybe UTCTime
    , locationEndDate :: Maybe UTCTime
    , locationUrl :: Maybe Text
    , locationLocation :: Maybe Text
    , locationState :: Text
    , locationImage :: Maybe Text
    , locationImageDesc :: Maybe Text
    , locationPoint :: Maybe GeoPoint
    , locationTags :: [Text]
    , locationOpeningHours :: Maybe Text
    , locationCreated :: UTCTime
    , locationUpdated :: UTCTime
    }
    deriving (Show)

instance FromJSON Location where
    parseJSON = withObject "Location" $ \o ->
        Location
            <$> o .: "id"
            <*> o .: "title"
            <*> (nullableText <$> o .:? "description")
            <*> (o .:? "start_date" >>= parsePbDate)
            <*> (o .:? "end_date" >>= parsePbDate)
            <*> (nullableText <$> o .:? "url")
            <*> (nullableText <$> o .:? "location")
            <*> o .: "state"
            <*> (nullableText <$> o .:? "image")
            <*> (nullableText <$> o .:? "image_description")
            <*> o .:? "point"
            <*> o .:? "tags" .!= []
            <*> (nullableText <$> o .:? "opening_hours")
            <*> o .: "created"
            <*> o .: "updated"

parsePbDate :: Maybe Value -> Parser (Maybe UTCTime)
parsePbDate Nothing = return Nothing
parsePbDate (Just Null) = return Nothing
parsePbDate (Just (String t)) | T.null t = return Nothing
parsePbDate (Just v) = Just <$> parseJSON v

nullableText :: Maybe Text -> Maybe Text
nullableText (Just t)
    | T.null t = Nothing
    | otherwise = Just t
nullableText Nothing = Nothing

data PbList a = PbList
    { pbItems :: [a]
    , pbTotalItems :: Int
    , pbPage :: Int
    , pbPerPage :: Int
    }
    deriving (Show)

instance (FromJSON a) => FromJSON (PbList a) where
    parseJSON = withObject "PbList" $ \o ->
        PbList
            <$> o .: "items"
            <*> o .: "totalItems"
            <*> o .: "page"
            <*> o .: "perPage"

fetchPublishedLocations :: IO [Location]
fetchPublishedLocations = do
    baseUrl <- getPbBaseUrl
    putStrLn $ "Using PocketBase URL: " ++ baseUrl
    fetchPage baseUrl (1 :: Int) []
  where
    fetchPage baseUrl page acc = do
        let url =
                baseUrl
                    ++ "/api/collections/locations/records"
                    ++ "?filter="
                    ++ urlEncode "(state=\"published\")"
                    ++ "&sort=-created"
                    ++ "&perPage=500"
                    ++ "&page="
                    ++ show page
        req <- parseRequest ("GET " ++ url)
        resp <- httpLBS req
        let status = getResponseStatusCode resp
        if status /= 200
            then do
                putStrLn $ "Warning: PocketBase returned status " ++ show status
                return acc
            else do
                let body = getResponseBody resp
                case eitherDecode body :: Either String (PbList Location) of
                    Left err -> do
                        putStrLn $ "Warning: Failed to decode locations: " ++ err
                        return acc
                    Right pbList -> do
                        let locs = acc ++ pbItems pbList
                        let total = pbTotalItems pbList
                        let fetched = length locs
                        if fetched < total
                            then fetchPage baseUrl (page + 1) locs
                            else return locs

imageUrl :: Location -> Text -> String
imageUrl loc filename =
    Config.pbDefaultUrl
        ++ "/api/files/locations/"
        ++ locationId loc
        ++ "/"
        ++ T.unpack filename

urlEncode :: String -> String
urlEncode = concatMap encodeChar
  where
    encodeChar c
        | c `elem` ("-_.~" :: String) || isAlphaNum c = [c]
        | otherwise = '%' : hexByte (fromEnum c)
    hexByte n =
        let (q, r) = n `divMod` 16
         in [hexDigit q, hexDigit r]
    hexDigit n
        | n < 10 = toEnum (fromEnum '0' + n)
        | otherwise = toEnum (fromEnum 'A' + n - 10)
    isAlphaNum c =
        isAsciiLower c
            || isAsciiUpper c
            || isDigit c
