module Main (main) where

import qualified FeedGen
import qualified GeoJsonGen
import qualified ImageFetcher
import qualified PocketBase

import Control.Exception (SomeException, try)
import qualified Data.Map.Strict as Map
import Data.Maybe (fromMaybe)
import Data.Time (Day, UTCTime (..), getCurrentTime, utctDay, zonedTimeToLocalTime, localDay)
import qualified DateUtils as DU
import GHC.IO.Encoding (setLocaleEncoding, utf8)
import System.Directory (createDirectoryIfMissing)
import System.Exit (ExitCode (..), exitWith)

isUpcoming :: Day -> UTCTime -> PocketBase.Event -> Bool
isUpcoming todayHki todayUtc ev =
    let effective = fromMaybe (PocketBase.eventStartDate ev) (PocketBase.eventEndDate ev)
     in if PocketBase.eventAllDay ev
            then localDay (zonedTimeToLocalTime (DU.toHelsinki effective)) >= todayHki
            else effective >= todayUtc

main :: IO ()
main = do
    setLocaleEncoding utf8
    result <- try run :: IO (Either SomeException ())
    case result of
        Left err -> do
            putStrLn $ "Error: " ++ show err
            exitWith (ExitFailure 1)
        Right () -> putStrLn "Done."

run :: IO ()
run = do
    putStrLn "Fetching locations from PocketBase..."
    locs <- PocketBase.fetchPublishedLocations
    putStrLn $ "Fetched " ++ show (length locs) ++ " locations."

    putStrLn "Fetching events from PocketBase..."
    events <- PocketBase.fetchPublishedEvents
    putStrLn $ "Fetched " ++ show (length events) ++ " events."

    now <- getCurrentTime
    let todayUtc = UTCTime (utctDay now) 0
        todayHki = localDay (zonedTimeToLocalTime (DU.toHelsinki now))
        upcomingEvents = filter (isUpcoming todayHki todayUtc) events

    createDirectoryIfMissing True "static"
    createDirectoryIfMissing True "static/images"

    putStrLn "Downloading images..."
    imageMap <- ImageFetcher.downloadAllImages locs

    let genCtx =
            FeedGen.GeneratorContext
                { FeedGen.imageMap = Map.fromList imageMap
                }

    putStrLn "Generating feeds..."
    rss <- FeedGen.generateRss genCtx locs
    atom <- FeedGen.generateAtom genCtx locs
    json <- FeedGen.generateJsonFeed locs
    writeStaticFile "static/kartta.rss" rss
    writeStaticFile "static/kartta.atom" atom
    writeStaticFile "static/kartta.json" json

    putStrLn "Generating GeoJSON..."
    geo <- GeoJsonGen.generateGeoJson locs upcomingEvents
    writeStaticFile "static/kartta.geo.json" geo

writeStaticFile :: FilePath -> String -> IO ()
writeStaticFile path content = do
    writeFile path content
    putStrLn $ "Wrote " ++ path
