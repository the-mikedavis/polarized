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
    | TouchLeft
    | TouchRight


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

        TouchLeft ->
            let
                newWingedness =
                    case model.wingedness of
                        BothWing -> RightWing
                        RightWing -> BothWing
                        LeftWing -> NoWing
                        NoWing -> LeftWing
            in
                ( { model | wingedness = newWingedness }, Cmd.none )

        TouchRight ->
            let
                newWingedness =
                    case model.wingedness of
                        BothWing -> LeftWing
                        LeftWing -> BothWing
                        RightWing -> NoWing
                        NoWing -> RightWing
            in
                ( { model | wingedness = newWingedness }, Cmd.none )


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

drawJumbotron : Model -> Html Msg
drawJumbotron model =
    let
        internals =
            case model.wingedness of
                NoWing ->
                    [ p []
                        [ text "Polarized TV generates daily broadcasts from"
                        ]
                    , p []
                        [ text "video content collected from"
                        ]
                    , p []
                        [ text "right or left leaning Twitter users"
                        ]
                    ]
                _ ->
                    [ ]
    in
        div [ id "jumbotron"
            , class "text-center"
            ]
            internals


drawLeft : Model -> Html Msg
drawLeft model =
    let
        txt =
            case model.wingedness of
                LeftWing ->
                    "Watching"
                BothWing ->
                    "Watching"
                _ ->
                    "Watch"
        classes =
            case model.wingedness of
                LeftWing ->
                    [ ( "bg-red", True )
                    , ( "raised", True )
                    ]
                BothWing ->
                    [ ( "bg-red", True )
                    , ( "raised", True )
                    ]
                _ ->
                    [ ( "bg-blue", True )
                    ]
    in
        div [ id "left"
            , onClick TouchLeft
            , classList ( classes ++ [ ( "text-white", True )
                                     , ( "py-8", True )
                                     , ( "px-6", True )
                                     , ( "text-center", True )
                                     ] )
            ]
            [ text (txt ++ " the ")
            , span [ class "bigger uppercase"
                   ]
                   [ text "LEFT"
                   ]
            ]


drawRight : Model -> Html Msg
drawRight model =
    let
        txt =
            case model.wingedness of
                RightWing ->
                    "Watching"
                BothWing ->
                    "Watching"
                _ ->
                    "Watch"
        classes =
            case model.wingedness of
                RightWing ->
                    [ ( "bg-red", True )
                    , ( "raised", True )
                    ]
                BothWing ->
                    [ ( "bg-red", True )
                    , ( "raised", True )
                    ]
                _ ->
                    [ ( "bg-blue", True )
                    ]
    in
        div [ id "right"
            , onClick TouchRight
            , classList ( classes ++ [ ( "text-white", True )
                                     , ( "py-8", True )
                                     , ( "px-6", True )
                                     , ( "text-center", True )
                                     ] )
            ]
            [ text (txt ++ " the ")
            , span [ class "bigger uppercase"
                   ]
                   [ text "RIGHT"
                   ]
            ]


drawLeftRight : Model -> Html Msg
drawLeftRight model =
    let
        layout =
            case model.wingedness of
                BothWing ->
                    [ drawLeft model
                    , span [ id "and-separator"
                           , class "py-4"
                           ]
                           [ text "&" ]
                    , drawRight model
                    ]

                _ ->
                    [ drawLeft model
                    , drawRight model
                    ]
    in
        div [ id "left-right"
            , class "my-20 flex justify-around items-start"
            ]
            layout


drawControlPanel : Model -> Html Msg
drawControlPanel model =
    div [ id "control-panel"
        ]
        []


view : Model -> Html Msg
view model =
    div [ id "player-container"
        ]
        [ drawJumbotron model
        , drawLeftRight model
        , drawControlPanel model
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
