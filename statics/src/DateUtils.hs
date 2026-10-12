module DateUtils (
    toHelsinki,
    helsinkiOffset,
    isDst,
    formatDay,
    formatDate,
    formatTime,
    finnishWeekdayAbbr,
    finnishMonthName,
) where

import Data.Time (
    DayOfWeek (..),
    LocalTime (..),
    TimeOfDay (..),
    TimeZone (..),
    UTCTime (..),
    ZonedTime (..),
    addDays,
    dayOfWeek,
    fromGregorian,
    toGregorian,
    utcToZonedTime,
 )
import Data.Time.Calendar (Day)
import qualified SiteConfig as SC

helsinkiOffset :: UTCTime -> Int
helsinkiOffset t = if isDst t then 180 else 120

isDst :: UTCTime -> Bool
isDst t =
    let (year, _, _) = toGregorian (utctDay t)
        dstStart = UTCTime (lastSundayOf year 3) (fromIntegral (1 * 3600 :: Int))
        dstEnd = UTCTime (lastSundayOf year 10) (fromIntegral (1 * 3600 :: Int))
     in t >= dstStart && t < dstEnd

lastSundayOf :: Integer -> Int -> Day
lastSundayOf year month =
    let lastDay = fromGregorian year month (daysInMonth year month)
        offset = case dayOfWeek lastDay of
            Sunday -> 0 :: Int
            Monday -> 1
            Tuesday -> 2
            Wednesday -> 3
            Thursday -> 4
            Friday -> 5
            Saturday -> 6
     in addDays (negate (toInteger offset)) lastDay

daysInMonth :: Integer -> Int -> Int
daysInMonth year month
    | month == 2 = if isLeap year then 29 else 28
    | month `elem` [4, 6, 9, 11] = 30
    | otherwise = 31
  where
    isLeap y = y `mod` 4 == 0 && y `mod` 100 /= 0 || y `mod` 400 == 0

toHelsinki :: UTCTime -> ZonedTime
toHelsinki t =
    let offsetMins = helsinkiOffset t
        tzName = if offsetMins == 180 then "EEST" else "EET"
        tz = TimeZone offsetMins True tzName
     in utcToZonedTime tz t

-- | Weekday abbreviation in the site's language (Mon=ma … Sun=su).
finnishWeekdayAbbr :: DayOfWeek -> String
finnishWeekdayAbbr day = SC.staticsWeekdays SC.defaultLang !! (fromEnum day - 1)

-- | Month name in the site's language (1-indexed, January=1).
finnishMonthName :: Int -> String
finnishMonthName m = SC.staticsMonths SC.defaultLang !! (m - 1)

formatDay :: ZonedTime -> String
formatDay zt = finnishWeekdayAbbr (dayOfWeek (localDay (zonedTimeToLocalTime zt)))

formatDate :: ZonedTime -> String
formatDate zt =
    let (_, m, d) = toGregorian (localDay (zonedTimeToLocalTime zt))
     in show d ++ "." ++ show m ++ "."

formatTime :: ZonedTime -> String
formatTime zt =
    let tod = localTimeOfDay (zonedTimeToLocalTime zt)
     in show (todHour tod) ++ "." ++ pad2 (todMin tod)

pad2 :: Int -> String
pad2 n = if n < 10 then "0" ++ show n else show n
