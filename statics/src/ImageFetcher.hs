module ImageFetcher (
    downloadAllImages,
    downloadImage,
) where

import Control.Concurrent.Async (mapConcurrently)
import Control.Exception (SomeException, try)
import qualified Data.ByteString.Lazy as BL
import Data.Maybe (catMaybes)
import qualified Data.Text as T
import Network.HTTP.Simple (getResponseBody, getResponseStatusCode, httpLBS, parseRequest)
import qualified PocketBase as PB

downloadAllImages :: [PB.Location] -> IO [(String, FilePath)]
downloadAllImages locs = do
    let locsWithImages = [(loc, T.unpack img) | loc <- locs, Just img <- [PB.locationImage loc]]
    results <- mapConcurrently (uncurry downloadImage) locsWithImages
    return (catMaybes results)

downloadImage :: PB.Location -> String -> IO (Maybe (String, FilePath))
downloadImage loc filename = do
    let url = PB.imageUrl loc (T.pack filename)
        dest = "static/images/" ++ PB.locationId loc ++ "_" ++ filename
    result <- try (fetchAndWrite url dest) :: IO (Either SomeException ())
    case result of
        Left err -> do
            putStrLn $ "Warning: Failed to download image for " ++ PB.locationId loc ++ ": " ++ show err
            return Nothing
        Right () ->
            return (Just (PB.locationId loc, dest))

fetchAndWrite :: String -> FilePath -> IO ()
fetchAndWrite url dest = do
    req <- parseRequest ("GET " ++ url)
    resp <- httpLBS req
    let status = getResponseStatusCode resp
    if status == 200
        then BL.writeFile dest (getResponseBody resp)
        else putStrLn $ "Warning: HTTP " ++ show status ++ " for " ++ url
