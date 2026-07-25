module OpeningHoursParserTest exposing (suite)

import Expect
import OpeningHours exposing (..)
import OpeningHours.Parser exposing (parse)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Comprehensive OSM Opening Hours Parser"
        [ test "Parses 24/7" <|
            \_ ->
                parse "24/7" |> Expect.equal (Ok Open247)
        , describe "Time Spans"
            [ test "Parses simple time range" <|
                \_ -> parse "10:00-18:00" |> Expect.equal (Ok (Rules [ { months = Nothing, days = Nothing, status = Open [ TimeRange { hour = 10, minute = 0 } { hour = 18, minute = 0 } ] } ]))
            , test "Parses comma-separated times (e.g. lunch breaks)" <|
                \_ -> parse "09:00-12:00,13:00-17:00" |> Expect.equal (Ok (Rules [ { months = Nothing, days = Nothing, status = Open [ TimeRange { hour = 9, minute = 0 } { hour = 12, minute = 0 }, TimeRange { hour = 13, minute = 0 } { hour = 17, minute = 0 } ] } ]))
            , test "Parses open-ended times" <|
                \_ -> parse "10:00+" |> Expect.equal (Ok (Rules [ { months = Nothing, days = Nothing, status = Open [ OpenEnded { hour = 10, minute = 0 } ] } ]))
            ]
        , describe "Day Selectors"
            [ test "Parses day range" <|
                \_ -> parse "Mo-Fr 10:00-18:00" |> Expect.equal (Ok (Rules [ { months = Nothing, days = Just [ DayRange Mo Fr ], status = Open [ TimeRange { hour = 10, minute = 0 } { hour = 18, minute = 0 } ] } ]))
            , test "Parses comma-separated days" <|
                \_ -> parse "Mo,We,Fr 10:00-18:00" |> Expect.equal (Ok (Rules [ { months = Nothing, days = Just [ SingleDay Mo, SingleDay We, SingleDay Fr ], status = Open [ TimeRange { hour = 10, minute = 0 } { hour = 18, minute = 0 } ] } ]))
            , test "Parses Public Holidays (PH)" <|
                \_ -> parse "PH 10:00-12:00" |> Expect.equal (Ok (Rules [ { months = Nothing, days = Just [ PublicHoliday ], status = Open [ TimeRange { hour = 10, minute = 0 } { hour = 12, minute = 0 } ] } ]))
            ]
        , describe "Rule States (Off / Closed)"
            [ test "Parses explicit off days" <|
                \_ -> parse "Su off" |> Expect.equal (Ok (Rules [ { months = Nothing, days = Just [ SingleDay Su ], status = Off } ]))
            ]
        , describe "Multiple Rules (Semicolon separated)"
            [ test "Parses multiple standard rules" <|
                \_ -> parse "Mo-Fr 09:00-18:00; Sa-Su 10:00-15:00" |> Expect.equal (Ok (Rules [ { months = Nothing, days = Just [ DayRange Mo Fr ], status = Open [ TimeRange { hour = 9, minute = 0 } { hour = 18, minute = 0 } ] }, { months = Nothing, days = Just [ DayRange Sa Su ], status = Open [ TimeRange { hour = 10, minute = 0 } { hour = 15, minute = 0 } ] } ]))
            , test "Parses rule with off override" <|
                \_ -> parse "Mo-Su 10:00-18:00; We off" |> Expect.equal (Ok (Rules [ { months = Nothing, days = Just [ DayRange Mo Su ], status = Open [ TimeRange { hour = 10, minute = 0 } { hour = 18, minute = 0 } ] }, { months = Nothing, days = Just [ SingleDay We ], status = Off } ]))
            ]
        , describe "Seasonality (Months)"
            [ test "Parses month range with colon separator" <|
                \_ -> parse "Jan-Apr: Tu-Su 10:00-16:00" |> Expect.equal (Ok (Rules [ { months = Just [ MonthRange Jan Apr ], days = Just [ DayRange Tu Su ], status = Open [ TimeRange { hour = 10, minute = 0 } { hour = 16, minute = 0 } ] } ]))
            , test "Parses multiple seasonal rules" <|
                \_ -> parse "Jan-Apr: Tu-Su 10:00-16:00; May-Dec: Tu-Su 10:00-18:00" |> Expect.equal (Ok (Rules [ { months = Just [ MonthRange Jan Apr ], days = Just [ DayRange Tu Su ], status = Open [ TimeRange { hour = 10, minute = 0 } { hour = 16, minute = 0 } ] }, { months = Just [ MonthRange May Dec ], days = Just [ DayRange Tu Su ], status = Open [ TimeRange { hour = 10, minute = 0 } { hour = 18, minute = 0 } ] } ]))
            ]
        ]
