module Main (main) where

import Test.Tasty (TestTree, defaultMain, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Data.Aeson (eitherDecode)
import qualified Data.ByteString.Lazy.Char8 as BLC
import Data.List (isInfixOf)
import Data.Time (UTCTime (..), ZonedTime, fromGregorian, secondsToDiffTime)

import qualified Data.Map.Strict as Map
import qualified DateUtils as DU
import qualified FeedGen
import qualified GeoJsonGen
import qualified PocketBase as PB

-- ---------------------------------------------------------------------------
-- Test fixtures
-- ---------------------------------------------------------------------------

timedLocationJson :: BLC.ByteString
timedLocationJson =
    BLC.pack $
        concat
            [ "{\"id\":\"abc123\","
            , "\"title\":\"Brick Shop Helsinki\","
            , "\"description\":\"Well stocked\","
            , "\"start_date\":\"2026-05-05T11:00:00.000Z\","
            , "\"end_date\":\"2026-05-05T14:00:00.000Z\","
            , "\"url\":\"https://example.com\","
            , "\"location\":\"Helsinki, Kamppi\","
            , "\"state\":\"published\","
            , "\"image\":\"shop.jpg\","
            , "\"image_description\":\"Storefront\","
            , "\"point\":{\"lat\":60.1699,\"lon\":24.9384},"
            , "\"tags\":[\"store\",\"helsinki\"],"
            , "\"opening_hours\":\"Mo-Fr 10:00-18:00\","
            , "\"created\":\"2026-01-01T00:00:00.000Z\","
            , "\"updated\":\"2026-01-02T00:00:00.000Z\"}"
            ]

allDayLocationJson :: BLC.ByteString
allDayLocationJson =
    BLC.pack $
        concat
            [ "{\"id\":\"def456\","
            , "\"title\":\"Kaupunkifestivaal\","
            , "\"description\":\"\","
            , "\"start_date\":\"2026-06-15T21:00:00.000Z\","
            , "\"end_date\":null,"
            , "\"url\":\"\","
            , "\"location\":\"\","
            , "\"state\":\"published\","
            , "\"image\":\"\","
            , "\"image_description\":\"\","
            , "\"point\":null,"
            , "\"tags\":[],"
            , "\"opening_hours\":\"\","
            , "\"created\":\"2026-01-01T00:00:00.000Z\","
            , "\"updated\":\"2026-01-02T00:00:00.000Z\"}"
            ]

decodeLocation :: BLC.ByteString -> PB.Location
decodeLocation bs = case eitherDecode bs of
    Left err -> error ("Test fixture decode failed: " ++ err)
    Right ev -> ev

timedLocation :: PB.Location
timedLocation = decodeLocation timedLocationJson

allDayLocation :: PB.Location
allDayLocation = decodeLocation allDayLocationJson

zeroPointLocationJson :: BLC.ByteString
zeroPointLocationJson =
    BLC.pack $
        concat
            [ "{\"id\":\"zero001\","
            , "\"title\":\"Null Island Event\","
            , "\"description\":\"Should be excluded from geo output\","
            , "\"start_date\":\"2026-05-05T11:00:00.000Z\","
            , "\"end_date\":null,"
            , "\"url\":\"\","
            , "\"location\":\"Null Island\","
            , "\"state\":\"published\","
            , "\"image\":\"\","
            , "\"image_description\":\"\","
            , "\"point\":{\"lat\":0,\"lon\":0},"
            , "\"tags\":[],"
            , "\"opening_hours\":\"\","
            , "\"created\":\"2026-01-01T00:00:00.000Z\","
            , "\"updated\":\"2026-01-02T00:00:00.000Z\"}"
            ]

zeroPointLocation :: PB.Location
zeroPointLocation = decodeLocation zeroPointLocationJson

winterTime :: UTCTime
winterTime = UTCTime (fromGregorian 2026 1 15) (secondsToDiffTime (10 * 3600))

timedZoned :: ZonedTime
timedZoned = case PB.locationStartDate timedLocation of
    Just start -> DU.toHelsinki start
    Nothing -> error "no start"

-- ---------------------------------------------------------------------------
-- Main
-- ---------------------------------------------------------------------------

main :: IO ()
main =
    defaultMain $
        testGroup
            "statics tests"
            [ testGroup "PocketBase decoder" pocketBaseTests
            , testGroup "DateUtils" dateUtilsTests
            , testGroup "GeoJsonGen" geoJsonTests
            , testGroup "FeedGen" feedGenTests
            ]

-- ---------------------------------------------------------------------------
-- PocketBase decoder tests
-- ---------------------------------------------------------------------------

pocketBaseTests :: [TestTree]
pocketBaseTests =
    [ testCase "decodes id" $
        PB.locationId timedLocation @?= "abc123"
    , testCase "decodes title" $
        PB.locationTitle timedLocation @?= "Brick Shop Helsinki"
    , testCase "decodes description present" $
        PB.locationDescription timedLocation @?= Just "Well stocked"
    , testCase "decodes tags" $
        PB.locationTags timedLocation @?= ["store", "helsinki"]
    , testCase "missing tags defaults to []" $
        PB.locationTags allDayLocation @?= []
    , testCase "decodes opening_hours" $
        PB.locationOpeningHours timedLocation @?= Just "Mo-Fr 10:00-18:00"
    , testCase "decodes url" $
        PB.locationUrl timedLocation @?= Just "https://example.com"
    , testCase "decodes location" $
        PB.locationLocation timedLocation @?= Just "Helsinki, Kamppi"
    , testCase "decodes GeoPoint lat" $
        fmap PB.geoLat (PB.locationPoint timedLocation) @?= Just 60.1699
    , testCase "decodes GeoPoint lon" $
        fmap PB.geoLon (PB.locationPoint timedLocation) @?= Just 24.9384
    , testCase "decodes image" $
        PB.locationImage timedLocation @?= Just "shop.jpg"
    , testCase "empty string description becomes Nothing" $
        PB.locationDescription allDayLocation @?= Nothing
    , testCase "empty string url becomes Nothing" $
        PB.locationUrl allDayLocation @?= Nothing
    , testCase "null point becomes Nothing" $
        PB.locationPoint allDayLocation @?= Nothing
    , testCase "null end_date becomes Nothing" $
        PB.locationEndDate allDayLocation @?= Nothing
    , testCase "imageUrl helper" $
        PB.imageUrl timedLocation "photo.jpg"
            @?= "https://data.palikkaharrastajat.fi/api/files/locations/abc123/photo.jpg"
    ]

-- ---------------------------------------------------------------------------
-- DateUtils tests
-- ---------------------------------------------------------------------------

getStart :: PB.Location -> UTCTime
getStart loc = case PB.locationStartDate loc of
    Just s -> s
    Nothing -> error "no start"

dateUtilsTests :: [TestTree]
dateUtilsTests =
    [ testCase "EEST offset is 180 min (summer)" $
        DU.helsinkiOffset (getStart timedLocation) @?= 180
    , testCase "EET offset is 120 min (winter)" $
        DU.helsinkiOffset winterTime @?= 120
    , testCase "isDst true in May 2026" $
        DU.isDst (getStart timedLocation) @?= True
    , testCase "isDst false in January 2026" $
        DU.isDst winterTime @?= False
    , testCase "isDst false just before 2026 DST start" $
        let t = UTCTime (fromGregorian 2026 3 29) (secondsToDiffTime (3599))
         in DU.isDst t @?= False
    , testCase "isDst true at 2026 DST start (01:00 UTC)" $
        let t = UTCTime (fromGregorian 2026 3 29) (secondsToDiffTime (3600))
         in DU.isDst t @?= True
    , testCase "isDst true just before 2026 DST end" $
        let t = UTCTime (fromGregorian 2026 10 25) (secondsToDiffTime (3599))
         in DU.isDst t @?= True
    , testCase "isDst false at 2026 DST end (01:00 UTC)" $
        let t = UTCTime (fromGregorian 2026 10 25) (secondsToDiffTime (3600))
         in DU.isDst t @?= False
    , testCase "formatDate gives D.M." $
        DU.formatDate timedZoned @?= "5.5."
    , testCase "formatTime gives H.MM" $
        DU.formatTime timedZoned @?= "14.00"
    , testCase "finnishWeekdayAbbr gives ti for Tuesday" $
        DU.formatDay timedZoned @?= "ti"
    , testCase "finnishMonthName gives Toukokuu for 5" $
        DU.finnishMonthName 5 @?= "Toukokuu"
    ]

-- ---------------------------------------------------------------------------
-- GeoJsonGen tests
-- ---------------------------------------------------------------------------

geoJsonTests :: [TestTree]
geoJsonTests =
    [ testCase "location with coordinates included" $ do
        geo <- GeoJsonGen.generateGeoJson [timedLocation]
        assertBool "abc123 in output" ("abc123" `isInfixOf` geo)
    , testCase "location without coordinates excluded" $ do
        geo <- GeoJsonGen.generateGeoJson [allDayLocation]
        assertBool
            "no def456 in output"
            (not ("def456" `isInfixOf` geo))
    , testCase "type is FeatureCollection" $ do
        geo <- GeoJsonGen.generateGeoJson [timedLocation]
        assertBool "FeatureCollection" ("FeatureCollection" `isInfixOf` geo)
    , testCase "feature has type Feature" $ do
        geo <- GeoJsonGen.generateGeoJson [timedLocation]
        assertBool "Feature" ("Feature" `isInfixOf` geo)
    , testCase "coordinates in [lon, lat] order (GeoJSON spec)" $ do
        geo <- GeoJsonGen.generateGeoJson [timedLocation]
        let lonIdx =
                length $
                    takeWhile
                        (\c -> not ("24.9384" `isInfixOf` c))
                        [take i geo | i <- [0 .. length geo]]
            latIdx =
                length $
                    takeWhile
                        (\c -> not ("60.1699" `isInfixOf` c))
                        [take i geo | i <- [0 .. length geo]]
        assertBool "lon before lat" (lonIdx < latIdx)
    , testCase "title property present" $ do
        geo <- GeoJsonGen.generateGeoJson [timedLocation]
        assertBool "Brick Shop Helsinki" ("Brick Shop Helsinki" `isInfixOf` geo)
    , testCase "properties contain opening_hours and tags" $ do
        geo <- GeoJsonGen.generateGeoJson [timedLocation]
        assertBool "opening_hours" ("\"opening_hours\":\"Mo-Fr 10:00-18:00\"" `isInfixOf` geo)
        assertBool "tags" ("\"tags\":[\"store\",\"helsinki\"]" `isInfixOf` geo)
    , testCase "empty features when no geolocated locations" $ do
        geo <- GeoJsonGen.generateGeoJson [allDayLocation]
        assertBool "empty features" ("\"features\":[]" `isInfixOf` geo)
    , testCase "location with zero coordinates excluded" $ do
        geo <- GeoJsonGen.generateGeoJson [zeroPointLocation]
        assertBool
            "no zero001 in output"
            (not ("zero001" `isInfixOf` geo))
    ]

-- ---------------------------------------------------------------------------
-- FeedGen tests
-- ---------------------------------------------------------------------------

emptyCtx :: FeedGen.GeneratorContext
emptyCtx =
    FeedGen.GeneratorContext
        { FeedGen.imageMap = Map.empty
        }

feedGenTests :: [TestTree]
feedGenTests =
    [ testCase "RSS has <?xml declaration" $ do
        rss <- FeedGen.generateRss emptyCtx [timedLocation]
        assertBool "<?xml" ("<?xml" `isInfixOf` rss)
    , testCase "RSS has <rss version=\"2.0\"" $ do
        rss <- FeedGen.generateRss emptyCtx [timedLocation]
        assertBool "<rss version" ("<rss version=\"2.0\"" `isInfixOf` rss)
    , testCase "RSS has <channel>" $ do
        rss <- FeedGen.generateRss emptyCtx [timedLocation]
        assertBool "<channel>" ("<channel>" `isInfixOf` rss)
    , testCase "RSS has <item>" $ do
        rss <- FeedGen.generateRss emptyCtx [timedLocation]
        assertBool "<item>" ("<item>" `isInfixOf` rss)
    , testCase "RSS item title contains location title" $ do
        rss <- FeedGen.generateRss emptyCtx [timedLocation]
        assertBool "Brick Shop Helsinki in RSS" ("Brick Shop Helsinki" `isInfixOf` rss)
    , testCase "RSS item has guid element" $ do
        rss <- FeedGen.generateRss emptyCtx [timedLocation]
        assertBool
            "guid isPermaLink"
            ( "<guid isPermaLink=\"false\">https://kartta.palikkaharrastajat.fi/#/locations/abc123</guid>"
                `isInfixOf` rss
            )
    , testCase "RSS item has image enclosure" $ do
        rss <- FeedGen.generateRss emptyCtx [timedLocation]
        assertBool
            "enclosure"
            ( "<enclosure url=\"https://kartta.palikkaharrastajat.fi/images/abc123_shop.jpg\" length=\"0\" type=\"image/jpeg\"/>"
                `isInfixOf` rss
            )
    , testCase "RSS guid contains location id" $ do
        rss <- FeedGen.generateRss emptyCtx [timedLocation]
        assertBool "abc123 in guid" ("abc123" `isInfixOf` rss)
    , testCase "RSS empty locations produces no <item>" $ do
        rss <- FeedGen.generateRss emptyCtx []
        assertBool "no <item>" (not ("<item>" `isInfixOf` rss))
    , testCase "RSS has no kalenteri / data.palikkaharrastajat.fi strings" $ do
        rss <- FeedGen.generateRss emptyCtx [timedLocation]
        assertBool "no kalenteri" (not ("kalenteri" `isInfixOf` rss))
        assertBool "no data.palikkaharrastajat.fi" (not ("data.palikkaharrastajat.fi" `isInfixOf` rss))
    , testCase "Atom has <?xml declaration" $ do
        atom <- FeedGen.generateAtom emptyCtx [timedLocation]
        assertBool "<?xml" ("<?xml" `isInfixOf` atom)
    , testCase "Atom has Atom namespace" $ do
        atom <- FeedGen.generateAtom emptyCtx [timedLocation]
        assertBool "Atom xmlns" ("xmlns=\"http://www.w3.org/2005/Atom\"" `isInfixOf` atom)
    , testCase "Atom has <entry>" $ do
        atom <- FeedGen.generateAtom emptyCtx [timedLocation]
        assertBool "<entry>" ("<entry>" `isInfixOf` atom)
    , testCase "Atom output contains <link rel=\"self\" ... kartta.atom>" $ do
        atom <- FeedGen.generateAtom emptyCtx [timedLocation]
        assertBool
            "self link"
            ("<link href=\"https://kartta.palikkaharrastajat.fi/kartta.atom\" rel=\"self\"/>" `isInfixOf` atom)
    , testCase "Atom entry title contains location title" $ do
        atom <- FeedGen.generateAtom emptyCtx [timedLocation]
        assertBool "Brick Shop Helsinki" ("Brick Shop Helsinki" `isInfixOf` atom)
    , testCase "Atom entry id contains location id" $ do
        atom <- FeedGen.generateAtom emptyCtx [timedLocation]
        assertBool "abc123 in atom entry" ("abc123" `isInfixOf` atom)
    , testCase "JSON Feed has version field" $ do
        jf <- FeedGen.generateJsonFeed [timedLocation]
        assertBool "jsonfeed version" ("jsonfeed.org/version/1" `isInfixOf` jf)
    , testCase "JSON Feed has items array" $ do
        jf <- FeedGen.generateJsonFeed [timedLocation]
        assertBool "items" ("\"items\"" `isInfixOf` jf)
    , testCase "JSON Feed item has location id" $ do
        jf <- FeedGen.generateJsonFeed [timedLocation]
        assertBool "abc123" ("abc123" `isInfixOf` jf)
    ]
