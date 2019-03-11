module SuggestForm exposing (..)

import Platform.Cmd exposing (..)
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline
import Task
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push

---- MODEL ----

type alias Model =
    { name : String
    , rightWing : Maybe Bool
    }

init : Model
    Model "" None

---- UPDATE ----

---- VIEW ----

view : Model -> Html Msg
view model =
    div []
        [ p [] [text "Suggest a user"]
        ]

---- PROGRAM ----

main : Program Flags Model Msg
main =
    programWithFlags
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
