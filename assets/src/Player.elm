port module Player exposing (..)

import Platform.Cmd exposing (..)
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
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


type alias Embed =
    { hashtags : List String
    , id : Int
    , handle_name : String
    }


decodeEmbed : Decode.Decoder Embed
decodeEmbed =
    Pipeline.decode Embed
        |> Pipeline.required "hashtags" (Decode.list Decode.string)
        |> Pipeline.required "id" (Decode.int)
        |> Pipeline.required "handle_name" (Decode.string)


embedListDecoder : Decode.Decoder (List Embed)
embedListDecoder =
    Decode.list decodeEmbed


type alias Model =
    { hashtags : List String
    , phxSocket : Phoenix.Socket.Socket Msg
    , embeds : Array Embed
    , currentEmbed : Int
    , wingedness : Wingedness
    , wantedHashtags : List String
    , wantedInProgress : String
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
            , embeds = Array.fromList []
            , currentEmbed = 0
            , wingedness = NoWing
            , wantedHashtags = []
            , wantedInProgress = ""
            }
    in
        ( model, joinChannel )



---- UPDATE ----


type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | JoinChannel
    | PopulateHashtags Encode.Value
    | PopulateEmbeds Encode.Value
    | TouchLeft
    | TouchRight
    | StartHashtag String
    | KeyDown Int
    | DeleteHashtag String


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

        PopulateEmbeds raw ->
            let
                msg =
                    Decode.decodeValue (Decode.field "embeds" embedListDecoder) raw
            in
                case msg of
                    Ok message ->
                        ( { model | embeds = Array.fromList message }, Cmd.none )

                    Err error ->
                        ( model, Cmd.none )

        TouchLeft ->
            let
                newWingedness =
                    case model.wingedness of
                        BothWing ->
                            RightWing

                        RightWing ->
                            BothWing

                        LeftWing ->
                            NoWing

                        NoWing ->
                            LeftWing
            in
                lean model newWingedness

        TouchRight ->
            let
                newWingedness =
                    case model.wingedness of
                        BothWing ->
                            LeftWing

                        LeftWing ->
                            BothWing

                        RightWing ->
                            NoWing

                        NoWing ->
                            RightWing
            in
                lean model newWingedness

        StartHashtag str ->
            ( { model | wantedInProgress = str }, Cmd.none )

        KeyDown keyCode ->
            {- TODO should make a req for new embeds -}
            if keyCode == 13 then
                ( { model | wantedHashtags = model.wantedInProgress :: model.wantedHashtags, wantedInProgress = "" }
                , Cmd.none
                )
            else
                ( model, Cmd.none )

        DeleteHashtag hashtag ->
            {- TODO should make a req for new embeds -}
            ( { model | wantedHashtags = List.filter (\h -> h /= hashtag) model.wantedHashtags }
            , Cmd.none
            )


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


wingString : Wingedness -> String
wingString wingedness =
    case wingedness of
        BothWing ->
            "both"

        RightWing ->
            "right"

        LeftWing ->
            "left"

        NoWing ->
            "none"


lean : Model -> Wingedness -> ( Model, Cmd Msg )
lean model wingedness =
    case wingedness of
        NoWing ->
            ( { model
                | wingedness = wingedness
                , embeds = Array.fromList []
                , currentEmbed = 0
              }
            , Cmd.none
            )

        _ ->
            let
                wingStr =
                    wingString wingedness

                payload =
                    Encode.object
                        [ ( "wingedness", Encode.string wingStr )
                        , ( "hashtags", Encode.list (List.map Encode.string model.hashtags) )
                        ]

                phxPush =
                    Phoenix.Push.init "embeds" "player:lobby"
                        |> Phoenix.Push.withPayload payload
                        |> Phoenix.Push.onOk PopulateEmbeds

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push phxPush model.phxSocket
            in
                ( { model
                    | wingedness = wingedness
                    , phxSocket = phxSocket
                  }
                , Cmd.map PhoenixMsg phxCmd
                )



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
                    []
    in
        div
            [ id "jumbotron"
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
        div
            [ id "left"
            , onClick TouchLeft
            , classList (( "text-white py-4 px-10 text-center flex flex-col", True ) :: classes)
            ]
            [ span
                [ class "smaller"
                ]
                [ text (txt ++ " the ")
                ]
            , span
                [ class "bigger uppercase"
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
        div
            [ id "right"
            , onClick TouchRight
            , classList (( "text-white py-4 px-10 text-center flex flex-col", True ) :: classes)
            ]
            [ span
                [ class "smaller"
                ]
                [ text (txt ++ " the ")
                ]
            , span
                [ class "bigger uppercase"
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
                    , span
                        [ id "and-separator"
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
        div
            [ id "left-right"
            , class "my-20 flex justify-between items-start"
            ]
            layout


drawHashtag : String -> Html Msg
drawHashtag hashtag =
    div
        [ class "flex-none px-2"
        ]
        [ div
            [ class "bg-red text-white py-4 px-3 my-1 shadow text-sm font-bold text-center"
            ]
            [ span
                [ class "px-1"
                ]
                [ text ("#" ++ hashtag)
                ]
            , i
                [ class "fas fa-times text-white px-1 cursor-pointer"
                , onClick (DeleteHashtag hashtag)
                ]
                []
            ]
        ]


drawAvailableHashtag : String -> Html Msg
drawAvailableHashtag hashtag =
    option [ value hashtag ] []


drawControlPanel : Model -> Html Msg
drawControlPanel model =
    let
        hashtags =
            model.wantedHashtags
                |> List.sort
                |> List.map drawHashtag

        availableHashtags =
            model.hashtags
                |> List.sort
                |> List.map drawAvailableHashtag
    in
        div
            [ id "control-panel"
            , class "bg-grey px-5 pt-5"
            ]
            [ p
                [ class "text-center text-grey-darker pb-5"
                ]
                [ text "Tune your broadcast"
                ]
            , div
                [ class "flex"
                ]
                [ label
                    [ class "text-black flex-none mr-3 pt-1"
                    ]
                    [ text "Filter hashtags:" ]
                , input
                    [ class "appearance-none border-none text-grey-darker mr-3 py-1 w-full px-2 leading-tight focus:outline-none"
                    , onInput StartHashtag
                    , onKeyDown KeyDown
                    , value model.wantedInProgress
                    , attribute "list" "available-hashtags"
                    ]
                    []
                , datalist
                    [ id "available-hashtags"
                    ]
                    availableHashtags
                ]
            , div
                [ class "flex flex-wrap -mx-2 pr-2 py-5"
                ]
                hashtags
            ]


view : Model -> Html Msg
view model =
    div
        [ id "player-container"
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
