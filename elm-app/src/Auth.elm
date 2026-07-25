module Auth exposing (decodeAuthUser, fetchOAuthToken, restoreAuthFromFlags)

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Types exposing (AuthState(..), AuthUser)


decodeAuthUser : Decoder AuthUser
decodeAuthUser =
    Decode.map4 AuthUser
        (Decode.field "id" Decode.string)
        (Decode.maybe (Decode.field "name" Decode.string) |> Decode.map (Maybe.withDefault ""))
        (Decode.maybe (Decode.field "email" Decode.string) |> Decode.map (Maybe.withDefault ""))
        (Decode.succeed "")


restoreAuthFromFlags : Maybe String -> Maybe String -> AuthState
restoreAuthFromFlags maybeToken maybeModel =
    case maybeToken of
        Just token ->
            case maybeModel of
                Just modelStr ->
                    case Decode.decodeString decodeAuthUser modelStr of
                        Ok user ->
                            Authenticated { user | token = token }

                        Err _ ->
                            NotAuthenticated

                Nothing ->
                    NotAuthenticated

        Nothing ->
            NotAuthenticated


fetchOAuthToken : String -> String -> String -> String -> String -> (Result Http.Error AuthState -> msg) -> Cmd msg
fetchOAuthToken pbBaseUrl code codeVerifier redirectUrl state toMsg =
    let
        body =
            Encode.object
                [ ( "provider", Encode.string "oidc" )
                , ( "code", Encode.string code )
                , ( "codeVerifier", Encode.string codeVerifier )
                , ( "redirectUrl", Encode.string redirectUrl )
                , ( "state", Encode.string state )
                ]

        decoder =
            Decode.map2 (\token user -> Authenticated { user | token = token })
                (Decode.field "token" Decode.string)
                (Decode.field "record" decodeAuthUser)
    in
    Http.post
        { url = pbBaseUrl ++ "/api/collections/users/auth-with-oauth2"
        , body = Http.jsonBody body
        , expect = Http.expectJson toMsg decoder
        }
