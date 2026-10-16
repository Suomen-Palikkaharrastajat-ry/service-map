module DateUtils exposing (formatEventDateDisplay, formatLocationDateDisplay)

{-| Location- and event-specific date display formatting. General Helsinki time helpers
live in the shared `FinnishTime` module.
-}

import FinnishTime
    exposing
        ( formatShortDate
        , formatTime
        , parseUtcString
        , toHelsinkiParts
        )
import I18n exposing (MsgKey(..), t)
import Lang exposing (Lang)


{-| Format a location date for display.
Handles start date, end date, and same-day logic.
-}
formatLocationDateDisplay : Lang -> { a | startDate : Maybe String, endDate : Maybe String } -> Maybe String
formatLocationDateDisplay lang { startDate, endDate } =
    case startDate |> Maybe.andThen parseUtcString of
        Nothing ->
            Nothing

        Just startPosix ->
            let
                startDay =
                    formatShortDate (I18n.locale lang) startPosix

                startTime =
                    formatTime (I18n.locale lang) startPosix

                startParts =
                    toHelsinkiParts startPosix

                startStr =
                    (I18n.locale lang).weekdayAbbr startParts.weekday
                        ++ " "
                        ++ startDay
                        ++ t lang DateAtTime
                        ++ startTime
            in
            case endDate |> Maybe.andThen parseUtcString of
                Nothing ->
                    Just startStr

                Just endPosix ->
                    let
                        endParts =
                            toHelsinkiParts endPosix

                        sameDay =
                            (startParts.year == endParts.year)
                                && (startParts.month == endParts.month)
                                && (startParts.day == endParts.day)
                    in
                    if sameDay then
                        Just (startStr ++ "–" ++ formatTime (I18n.locale lang) endPosix)

                    else
                        Just (startStr ++ " – " ++ (I18n.locale lang).weekdayAbbr endParts.weekday ++ " " ++ formatShortDate (I18n.locale lang) endPosix ++ t lang DateAtTime ++ formatTime (I18n.locale lang) endPosix)


formatEventDateDisplay : Lang -> { a | startDate : String, endDate : String, allDay : Bool } -> Maybe String
formatEventDateDisplay lang ev =
    case parseUtcString ev.startDate of
        Nothing ->
            Nothing

        Just startPosix ->
            let
                startDay =
                    formatShortDate (I18n.locale lang) startPosix

                startParts =
                    toHelsinkiParts startPosix

                startStr =
                    if ev.allDay then
                        (I18n.locale lang).weekdayAbbr startParts.weekday ++ " " ++ startDay

                    else
                        (I18n.locale lang).weekdayAbbr startParts.weekday ++ " " ++ startDay ++ t lang DateAtTime ++ formatTime (I18n.locale lang) startPosix
            in
            case parseUtcString ev.endDate of
                Nothing ->
                    Just startStr

                Just endPosix ->
                    let
                        endParts =
                            toHelsinkiParts endPosix

                        sameDay =
                            (startParts.year == endParts.year)
                                && (startParts.month == endParts.month)
                                && (startParts.day == endParts.day)
                    in
                    if sameDay then
                        if ev.allDay then
                            Just startStr

                        else
                            Just (startStr ++ "–" ++ formatTime (I18n.locale lang) endPosix)

                    else if ev.allDay then
                        Just (startStr ++ " – " ++ (I18n.locale lang).weekdayAbbr endParts.weekday ++ " " ++ formatShortDate (I18n.locale lang) endPosix)

                    else
                        Just (startStr ++ " – " ++ (I18n.locale lang).weekdayAbbr endParts.weekday ++ " " ++ formatShortDate (I18n.locale lang) endPosix ++ t lang DateAtTime ++ formatTime (I18n.locale lang) endPosix)
