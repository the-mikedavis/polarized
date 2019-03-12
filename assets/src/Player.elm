port module Player exposing (..)

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
import Array exposing (Array)

---- MODEL ----

type Wingedness
    = LeftWing
    | RightWing
    | BothWing
    | NoWing


type alias Model =
    { hashtags : List String
    , phxSocket : Phoenix.Socket.Socket Msg
    , embedId : Maybe Int
    , wingedness : Wingedness
    }


type alias Flags =
    { uri : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        channel =
            Phoenix.Channel.init "player:lobby"

        initSocket =
            Phoenix.Socket.init flags.uri

        model =
            { hashtags = []
            , phxSocket = initSocket
            , embedId = Nothing
            , wingedness = NoWing
            }
    in
        ( model, joinChannel )



---- UPDATE ----

type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | JoinChannel
    | PopulateHashtags Encode.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = phxSocket }, Cmd.map PhoenixMsg phxCmd )

        JoinChannel ->
            let
                channel =
                    Phoenix.Channel.init "player:lobby"
                        |> Phoenix.Channel.onJoin PopulateHashtags

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.join channel model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        PopulateHashtags raw ->
            let
                msg =
                    Decode.decodeValue (Decode.field "hashtags" (Decode.list (Decode.string))) raw
            in
                case msg of
                    Ok message ->
                        ( { model | hashtags = message }, Cmd.none )
                    Err error ->
                        ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.phxSocket PhoenixMsg


joinChannel : Cmd Msg
joinChannel =
    Task.succeed JoinChannel
        |> Task.perform identity


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Decode.map tagger keyCode)

---- VIEW ----

view : Model -> Html Msg
view model =
    div [] []


---- PROGRAM ----

main : Program Flags Model Msg
main =
    programWithFlags
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
