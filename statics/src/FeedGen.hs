module FeedGen (
    GeneratorContext (..),
    generateRss,
    generateAtom,
    generateJsonFeed,
) where

import qualified Config
import Control.Exception (SomeException, try)
import Data.Aeson (Value, encode, object, (.=))
import Data.Either (fromRight)
import qualified Data.Map.Strict as Map
import Data.Maybe (maybeToList)
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TLE
import Data.Time (UTCTime, getCurrentTime)
import Data.Time.Format (defaultTimeLocale, formatTime)
import qualified DescriptionHtml as DH
import qualified PocketBase as PB
import System.Directory (getFileSize)

feedTitle :: String
feedTitle = "Palikkakartta"

feedLink :: String
feedLink = Config.siteBaseUrl ++ "/"

feedSelf :: String
feedSelf = Config.siteBaseUrl ++ "/"

feedDescription :: String
feedDescription = "Suomen Palikkaharrastajat ry:n palvelukartta"

feedId :: String
feedId = Config.siteBaseUrl ++ "/"

feedLogoUrl :: String
feedLogoUrl = Config.siteBaseUrl ++ "/logo/square/png/square-smile.png"

newtype GeneratorContext = GeneratorContext
    { imageMap :: Map.Map String FilePath
    }

locationImageUrl :: PB.Location -> Maybe String
locationImageUrl loc = case PB.locationImage loc of
    Nothing -> Nothing
    Just fname -> Just $ Config.siteBaseUrl ++ "/images/" ++ PB.locationId loc ++ "_" ++ T.unpack fname

feedItemTitle :: PB.Location -> String
feedItemTitle loc = T.unpack (PB.locationTitle loc)

xmlEscape :: String -> String
xmlEscape = concatMap esc
  where
    esc '<' = "&lt;"
    esc '>' = "&gt;"
    esc '&' = "&amp;"
    esc '"' = "&quot;"
    esc '\'' = "&apos;"
    esc c = [c]

xmlEl :: String -> String -> String
xmlEl tag content = "<" ++ tag ++ ">" ++ content ++ "</" ++ tag ++ ">"

xmlText :: String -> String -> String
xmlText tag txt = xmlEl tag (xmlEscape txt)

xmlCdata :: String -> String -> String
xmlCdata tag content = "<" ++ tag ++ "><![CDATA[" ++ content ++ "]]></" ++ tag ++ ">"

formatRfc822 :: UTCTime -> String
formatRfc822 = formatTime defaultTimeLocale "%a, %d %b %Y %H:%M:%S GMT"

formatRfc3339 :: UTCTime -> String
formatRfc3339 = formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%SZ"

formatRfc3339Ms :: UTCTime -> String
formatRfc3339Ms = formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S.000Z"

rssItemTitle :: PB.Location -> String
rssItemTitle = feedItemTitle

rssItemDescription :: PB.Location -> String
rssItemDescription loc =
    DH.descriptionWithDateHtml (PB.locationDescription loc) ""

buildRssItem :: GeneratorContext -> PB.Location -> IO String
buildRssItem ctx loc = do
    imgEncl <- case locationImageUrl loc of
        Nothing -> return Nothing
        Just imgUrl -> do
            let maybeLocalPath = Map.lookup (PB.locationId loc) (imageMap ctx)
            fileSize <- case maybeLocalPath of
                Nothing -> return (0 :: Integer)
                Just fp -> do
                    result <- try (getFileSize fp) :: IO (Either SomeException Integer)
                    return (fromRight 0 result)
            return $
                Just $
                    "      <enclosure url=\""
                        ++ xmlEscape imgUrl
                        ++ "\" length=\""
                        ++ show fileSize
                        ++ "\" type=\"image/jpeg\"/>"
    return $
        unlines $
            [ "    <item>"
            , "      " ++ xmlCdata "title" (rssItemTitle loc)
            , "      " ++ xmlCdata "description" (rssItemDescription loc)
            , "      <guid isPermaLink=\"false\">"
                ++ Config.siteBaseUrl
                ++ "/#/locations/"
                ++ PB.locationId loc
                ++ "</guid>"
            , "      " ++ xmlText "pubDate" (formatRfc822 (PB.locationUpdated loc))
            , "      "
                ++ xmlEl
                    "link"
                    ( maybe
                        (Config.siteBaseUrl ++ "/#/locations/" ++ PB.locationId loc)
                        (xmlEscape . T.unpack)
                        (PB.locationUrl loc)
                    )
            ]
                ++ maybeToList imgEncl
                ++ ["    </item>"]

generateRss :: GeneratorContext -> [PB.Location] -> IO String
generateRss ctx locs = do
    now <- getCurrentTime
    items <- mapM (buildRssItem ctx) locs
    return $
        unlines
            [ "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            , "<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">"
            , "  <channel>"
            , "    " ++ xmlText "title" feedTitle
            , "    " ++ xmlEl "link" feedLink
            , "    " ++ xmlText "description" feedDescription
            , "    " ++ xmlText "lastBuildDate" (formatRfc822 now)
            , "    " ++ xmlEl "docs" "https://validator.w3.org/feed/docs/rss2.html"
            , "    " ++ xmlText "generator" "Emmet"
            , "    " ++ xmlText "language" "fi"
            , "    <image>"
            , "      " ++ xmlText "title" feedTitle
            , "      " ++ xmlEl "url" feedLogoUrl
            , "      " ++ xmlEl "link" feedLink
            , "    </image>"
            , "    " ++ xmlText "copyright" "Suomen Palikkaharrastajat ry"
            , "    <atom:link href=\""
                ++ feedSelf
                ++ "kartta.rss\" rel=\"self\" type=\"application/rss+xml\"/>"
            , concat items
            , "  </channel>"
            , "</rss>"
            ]

buildAtomEntry :: GeneratorContext -> PB.Location -> IO String
buildAtomEntry ctx loc = do
    imgLink <- case locationImageUrl loc of
        Nothing -> return Nothing
        Just imgUrl -> do
            let maybeLocalPath = Map.lookup (PB.locationId loc) (imageMap ctx)
            fileSize <- case maybeLocalPath of
                Nothing -> return (0 :: Integer)
                Just fp -> do
                    result <- try (getFileSize fp) :: IO (Either SomeException Integer)
                    return (fromRight 0 result)
            return $
                Just $
                    "    <link rel=\"enclosure\" type=\"image/jpeg\" href=\""
                        ++ xmlEscape imgUrl
                        ++ "\" length=\""
                        ++ show fileSize
                        ++ "\"/>"
    let summaryContent = DH.descriptionWithDateHtml (PB.locationDescription loc) ""
    return $
        unlines $
            [ "  <entry>"
            , "    " ++ xmlText "id" (Config.siteBaseUrl ++ "/#/locations/" ++ PB.locationId loc)
            , "    <title type=\"html\">" ++ xmlEscape (feedItemTitle loc) ++ "</title>"
            , "    " ++ xmlText "published" (formatRfc3339 (PB.locationCreated loc))
            , "    " ++ xmlText "updated" (formatRfc3339 (PB.locationUpdated loc))
            , "    <author><name>Suomen Palikkaharrastajat ry</name></author>"
            , "    <link rel=\"alternate\" href=\""
                ++ maybe
                    (Config.siteBaseUrl ++ "/#/locations/" ++ PB.locationId loc)
                    (xmlEscape . T.unpack)
                    (PB.locationUrl loc)
                ++ "\"/>"
            ]
                ++ maybeToList imgLink
                ++ [ "    <summary type=\"html\"><![CDATA[" ++ summaryContent ++ "]]></summary>"
                   , "  </entry>"
                   ]

generateAtom :: GeneratorContext -> [PB.Location] -> IO String
generateAtom ctx locs = do
    now <- getCurrentTime
    entries <- mapM (buildAtomEntry ctx) locs
    return $
        unlines
            [ "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            , "<feed xmlns=\"http://www.w3.org/2005/Atom\">"
            , "  " ++ xmlText "title" feedTitle
            , "  <link href=\"" ++ feedLink ++ "\" rel=\"alternate\"/>"
            , "  <link href=\"" ++ feedSelf ++ "kartta.atom\" rel=\"self\"/>"
            , "  " ++ xmlText "id" feedId
            , "  " ++ xmlText "subtitle" feedDescription
            , "  " ++ xmlText "updated" (formatRfc3339 now)
            , "  " ++ xmlText "rights" "Suomen Palikkaharrastajat ry"
            , "  " ++ xmlEl "logo" feedLogoUrl
            , "  " ++ xmlEl "icon" (Config.siteBaseUrl ++ "/favicon.ico")
            , "  " ++ xmlText "generator" "Emmet"
            , "  <author><name>Suomen Palikkaharrastajat ry</name><email>palikkaharrastajatry@outlook.com</email><uri>https://palikkaharrastajat.fi/</uri></author>"
            , concat entries
            , "</feed>"
            ]

jsonFeedItem :: PB.Location -> Value
jsonFeedItem loc =
    let contentHtml =
            DH.descriptionWithDateHtml (PB.locationDescription loc) ""
        baseFields =
            [ "id" .= (Config.siteBaseUrl ++ "/#/locations/" ++ PB.locationId loc)
            , "title" .= feedItemTitle loc
            , "content_html" .= contentHtml
            , "date_published" .= formatRfc3339Ms (PB.locationCreated loc)
            , "date_modified" .= formatRfc3339Ms (PB.locationUpdated loc)
            , "author" .= object ["name" .= ("Suomen Palikkaharrastajat ry" :: String)]
            ]
        urlField = case PB.locationUrl loc of
            Just u -> ["url" .= T.unpack u]
            Nothing -> ["url" .= (Config.siteBaseUrl ++ "/#/locations/" ++ PB.locationId loc)]
        imgField = case locationImageUrl loc of
            Just img -> ["image" .= img]
            Nothing -> []
     in object (baseFields ++ urlField ++ imgField)

generateJsonFeed :: [PB.Location] -> IO String
generateJsonFeed locs =
    return $
        TL.unpack $
            TLE.decodeUtf8 $
                encode $
                    object
                        [ "version" .= ("https://jsonfeed.org/version/1" :: String)
                        , "title" .= feedTitle
                        , "home_page_url" .= feedLink
                        , "description" .= feedDescription
                        , "icon" .= feedLogoUrl
                        , "author"
                            .= object
                                [ "name" .= ("Suomen Palikkaharrastajat ry" :: String)
                                , "url" .= ("https://palikkaharrastajat.fi/" :: String)
                                ]
                        , "items" .= map jsonFeedItem locs
                        ]
