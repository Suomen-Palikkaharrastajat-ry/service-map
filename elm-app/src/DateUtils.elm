module DateUtils exposing (formatEventDateDisplay, formatLocationDateDisplay)

{-| Location- and event-specific date display formatting. General Helsinki time helpers
live in the shared `FinnishTime` module.
-}

import FinnishTime
    exposing
        ( finnishWeekdayAbbr
        , formatShortDate
        , formatTime
        , parseUtcString
        , toHelsinkiParts
        )


{-| Format a location date for display.
Handles start date, end date, and same-day logic.
-}
formatLocationDateDisplay : { startDate : Maybe String, endDate : Maybe String } -> Maybe String
formatLocationDateDisplay { startDate, endDate } =
    case startDate |> Maybe.andThen parseUtcString of
        Nothing ->
            Nothing

        Just startPosix ->
            let
                startDay =
                    formatShortDate startPosix

                startTime =
                    formatTime startPosix

                startParts =
                    toHelsinkiParts startPosix

                startStr =
                    finnishWeekdayAbbr startParts.weekday
                        ++ " "
                        ++ startDay
                        ++ " klo "
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
                        Just (startStr ++ "–" ++ formatTime endPosix)

                    else
                        Just (startStr ++ " – " ++ finnishWeekdayAbbr endParts.weekday ++ " " ++ formatShortDate endPosix ++ " klo " ++ formatTime endPosix)


formatEventDateDisplay : { a | startDate : String, endDate : String, allDay : Bool } -> Maybe String
formatEventDateDisplay ev =
    case parseUtcString ev.startDate of
        Nothing ->
            Nothing

        Just startPosix ->
            let
                startDay =
                    formatShortDate startPosix

                startParts =
                    toHelsinkiParts startPosix

                startStr =
                    if ev.allDay then
                        finnishWeekdayAbbr startParts.weekday ++ " " ++ startDay

                    else
                        finnishWeekdayAbbr startParts.weekday ++ " " ++ startDay ++ " klo " ++ formatTime startPosix
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
                            Just (startStr ++ "–" ++ formatTime endPosix)

                    else if ev.allDay then
                        Just (startStr ++ " – " ++ finnishWeekdayAbbr endParts.weekday ++ " " ++ formatShortDate endPosix)

                    else
                        Just (startStr ++ " – " ++ finnishWeekdayAbbr endParts.weekday ++ " " ++ formatShortDate endPosix ++ " klo " ++ formatTime endPosix)
