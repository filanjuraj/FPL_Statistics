module Main exposing (..)

import Browser
import Html exposing (Html, div, h1, img, input, text)
import Html.Attributes exposing (height, placeholder, src, width)
import Html.Events exposing (onInput)
import Html.Parser exposing (Node(..))
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import RemoteData
import String.Normalize
import Table



---- MODEL ----


type alias Model =
    { playersParsing : RemoteData.RemoteData String (List Player)
    , tableState : Table.State
    , query : String
    }


type alias PlayersResponse =
    { decodedPlayers : List DecodedPlayer }


type alias Player =
    { firstName : String
    , secondName : String
    , team : Int
    , webName : String
    , selectedBy : Float
    , transfersIn : Int
    , transfersOut : Int
    , reason : String
    , detail : String
    , return : String
    , status : String
    }


type alias DecodedPlayer =
    { firstName : String
    , secondName : String
    , team : Int
    , webName : String
    , selectedBy : Float
    , transfersIn : Int
    , transfersOut : Int
    }


type alias Injury =
    { name : String
    , reason : String
    , detail : String
    , return : String
    , status : String
    }


dataEndpointUrl : String
dataEndpointUrl =
    "http://localhost:3001/api/players"


injuriesEndpointUrl : String
injuriesEndpointUrl =
    "http://localhost:3001/api/injuries"


init : ( Model, Cmd Msg )
init =
    ( { playersParsing = RemoteData.Loading
      , tableState = Table.initialSort "Name"
      , query = ""
      }
    , getPlayers
    )


getPlayers : Cmd Msg
getPlayers =
    Http.get
        { url = dataEndpointUrl
        , expect = Http.expectJson (RemoteData.fromResult >> DataResponse) decodeDataResponse
        }


getInjuries : List DecodedPlayer -> Cmd Msg
getInjuries decodedPlayers =
    Http.get
        { url = injuriesEndpointUrl
        , expect = Http.expectString (RemoteData.fromResult >> PLInjuriesResponse decodedPlayers)
        }


decodePlayer : Decode.Decoder DecodedPlayer
decodePlayer =
    Decode.succeed DecodedPlayer
        |> Pipeline.required "first_name" Decode.string
        |> Pipeline.required "second_name" Decode.string
        |> Pipeline.required "team" Decode.int
        |> Pipeline.required "web_name" Decode.string
        |> Pipeline.required "selected_by_percent" stringFloatDecoder
        |> Pipeline.required "transfers_in_event" Decode.int
        |> Pipeline.required "transfers_out_event" Decode.int


stringFloatDecoder : Decode.Decoder Float
stringFloatDecoder =
    Decode.string
        |> Decode.andThen
            (\val ->
                case String.toFloat val of
                    Just f ->
                        Decode.succeed f

                    Nothing ->
                        Decode.fail "Not a float!"
            )


decodeDataResponse : Decode.Decoder PlayersResponse
decodeDataResponse =
    Decode.succeed PlayersResponse
        |> Pipeline.required "elements" (Decode.list decodePlayer)


joinPlayersInjuries : List DecodedPlayer -> String -> Maybe (List Player)
joinPlayersInjuries decodedPlayers =
    Html.Parser.run
        >> Result.toMaybe
        >> Maybe.map
            (\parsedNodes ->
                decodedPlayers
                    |> List.map (\player -> createPlayer parsedNodes player)
            )


createPlayer : List Html.Parser.Node -> DecodedPlayer -> Player
createPlayer nodes decodedPlayer =
    let
        playerConstructor reason detail return status =
            { firstName = decodedPlayer.firstName
            , secondName = decodedPlayer.secondName
            , team = decodedPlayer.team
            , webName = decodedPlayer.webName
            , selectedBy = decodedPlayer.selectedBy
            , transfersIn = decodedPlayer.transfersIn
            , transfersOut = decodedPlayer.transfersOut
            , reason = reason
            , detail = detail
            , return = return
            , status = status
            }

        foundNode =
            List.filter
                (\node_ ->
                    case node_ of
                        Element _ _ innerNodes ->
                            let
                                nameNode =
                                    List.head
                                        (List.filter
                                            (\node ->
                                                case node of
                                                    Element _ _ _ ->
                                                        True

                                                    _ ->
                                                        False
                                            )
                                            innerNodes
                                        )
                            in
                            case nameNode of
                                Just (Element _ _ innerNodes2) ->
                                    case List.length innerNodes2 == 2 of
                                        True ->
                                            let
                                                name =
                                                    List.head
                                                        (List.filter
                                                            (\node ->
                                                                case node of
                                                                    Text _ ->
                                                                        True

                                                                    _ ->
                                                                        False
                                                            )
                                                            innerNodes2
                                                        )
                                            in
                                            case name of
                                                Just (Text text) ->
                                                    String.contains decodedPlayer.firstName text
                                                        && String.contains decodedPlayer.secondName text

                                                _ ->
                                                    False

                                        False ->
                                            False

                                _ ->
                                    False

                        _ ->
                            False
                )
                nodes
    in
    case List.head foundNode of
        Just (Element _ _ innerNodes) ->
            let
                nameNode =
                    List.head
                        (List.filter
                            (\node ->
                                case node of
                                    Element _ _ _ ->
                                        True

                                    _ ->
                                        False
                            )
                            innerNodes
                        )
            in
            case nameNode of
                Just (Element _ _ innerNodes2) ->
                    case List.length innerNodes2 == 2 of
                        True ->
                            let
                                name =
                                    List.head
                                        (List.filter
                                            (\node ->
                                                case node of
                                                    Text _ ->
                                                        True

                                                    _ ->
                                                        False
                                            )
                                            innerNodes2
                                        )
                            in
                            case name of
                                Just (Text text) ->
                                    case
                                        String.contains decodedPlayer.firstName text
                                            && String.contains decodedPlayer.secondName text
                                    of
                                        True ->
                                            let
                                                reason =
                                                    innerNodes
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.filter
                                                           (\node ->
                                                               case node of
                                                                   Element _ _ _ ->
                                                                       True

                                                                   _ ->
                                                                       False
                                                           )
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.head

                                                        |> Maybe.map
                                                            (\node ->
                                                                case node of
                                                                    Element _ _ innerNodes3 ->
                                                                        innerNodes3
                                                                            |> List.filter
                                                                                (\node2 ->
                                                                                    case node2 of
                                                                                        Text _ -> True

                                                                                        _ -> False
                                                                                )
                                                                            |> List.head
                                                                            |> Maybe.map
                                                                                (\node3 ->
                                                                                    case node3 of
                                                                                        Text reasonText ->
                                                                                            reasonText

                                                                                        _ ->
                                                                                            ""
                                                                                )
                                                                            |> Maybe.withDefault ""

                                                                    _ -> ""
                                                            )
                                                        |> Maybe.withDefault ""

                                                detail =
                                                    innerNodes
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.filter
                                                           (\node ->
                                                               case node of
                                                                   Element _ _ _ ->
                                                                       True

                                                                   _ ->
                                                                       False
                                                           )
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.head

                                                        |> Maybe.map
                                                            (\node ->
                                                                case node of
                                                                    Element _ _ innerNodes3 ->
                                                                        innerNodes3
                                                                            |> List.filter
                                                                                (\node2 ->
                                                                                    case node2 of
                                                                                        Text _ -> True

                                                                                        _ -> False
                                                                                )
                                                                            |> List.head
                                                                            |> Maybe.map
                                                                                (\node3 ->
                                                                                    case node3 of
                                                                                        Text reasonText ->
                                                                                            reasonText

                                                                                        _ ->
                                                                                            ""
                                                                                )
                                                                            |> Maybe.withDefault ""

                                                                    _ -> ""
                                                            )
                                                        |> Maybe.withDefault ""

                                                return =
                                                    innerNodes
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.filter
                                                           (\node ->
                                                               case node of
                                                                   Element _ _ _ ->
                                                                       True

                                                                   _ ->
                                                                       False
                                                           )
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.head

                                                        |> Maybe.map
                                                            (\node ->
                                                                case node of
                                                                    Element _ _ innerNodes3 ->
                                                                        innerNodes3
                                                                            |> List.filter
                                                                                (\node2 ->
                                                                                    case node2 of
                                                                                        Text _ -> True

                                                                                        _ -> False
                                                                                )
                                                                            |> List.head
                                                                            |> Maybe.map
                                                                                (\node3 ->
                                                                                    case node3 of
                                                                                        Text reasonText ->
                                                                                            reasonText

                                                                                        _ ->
                                                                                            ""
                                                                                )
                                                                            |> Maybe.withDefault ""

                                                                    _ -> ""
                                                            )
                                                        |> Maybe.withDefault ""


                                                status =
                                                    innerNodes
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.filter
                                                           (\node ->
                                                               case node of
                                                                   Element _ _ _ ->
                                                                       True

                                                                   _ ->
                                                                       False
                                                           )
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.tail
                                                        |> Maybe.withDefault []
                                                        |> List.head

                                                        |> Maybe.map
                                                            (\node ->
                                                                case node of
                                                                    Element _ _ innerNodes3 ->
                                                                        innerNodes3
                                                                            |> List.filter
                                                                                (\node2 ->
                                                                                    case node2 of
                                                                                        Text _ -> True

                                                                                        _ -> False
                                                                                )
                                                                            |> List.head
                                                                            |> Maybe.map
                                                                                (\node3 ->
                                                                                    case node3 of
                                                                                        Text reasonText ->
                                                                                            reasonText

                                                                                        _ ->
                                                                                            ""
                                                                                )
                                                                            |> Maybe.withDefault ""

                                                                    _ -> ""
                                                            )
                                                        |> Maybe.withDefault ""
                                            in
                                            playerConstructor reason detail return status

                                        False ->
                                            playerConstructor "" "" "" ""

                                _ ->
                                    playerConstructor "" "" "" ""

                        False ->
                            playerConstructor "" "" "" ""

                _ ->
                    playerConstructor "" "" "" ""

        _ ->
            playerConstructor "" "" "" ""



---- UPDATE ----


type Msg
    = DataResponse (RemoteData.WebData PlayersResponse)
    | PLInjuriesResponse (List DecodedPlayer) (RemoteData.WebData String)
    | SetQuery String
    | SetTableState Table.State


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DataResponse webDataResponse ->
            case webDataResponse of
                RemoteData.Success { decodedPlayers } ->
                    ( model
                    , getInjuries decodedPlayers
                    )

                RemoteData.Failure _ ->
                    ( { model | playersParsing = RemoteData.Failure "Data response failure" }
                    , Cmd.none
                    )

                RemoteData.NotAsked ->
                    ( { model | playersParsing = RemoteData.NotAsked }
                    , Cmd.none
                    )

                RemoteData.Loading ->
                    ( { model | playersParsing = RemoteData.Loading }
                    , Cmd.none
                    )

        SetQuery newQuery ->
            ( { model | query = newQuery }
            , Cmd.none
            )

        SetTableState newState ->
            ( { model | tableState = newState }
            , Cmd.none
            )

        PLInjuriesResponse decodedPlayers webDataResponse ->
            case webDataResponse of
                RemoteData.Success data ->
                    ( { model | playersParsing = joinPlayersInjuries decodedPlayers data |> RemoteData.fromMaybe "Could not parse." }
                    , Cmd.none
                    )

                RemoteData.Failure _ ->
                    ( { model | playersParsing = RemoteData.Failure "Injuries failure error" }
                    , Cmd.none
                    )

                RemoteData.NotAsked ->
                    ( { model | playersParsing = RemoteData.NotAsked }
                    , Cmd.none
                    )

                RemoteData.Loading ->
                    ( { model | playersParsing = RemoteData.Loading }
                    , Cmd.none
                    )



---- VIEW ----


view : Model -> Html Msg
view model =
    case model.playersParsing of
        RemoteData.NotAsked ->
            text "Not asked to fetch data"

        RemoteData.Loading ->
            text "Loading ..."

        RemoteData.Failure error ->
            text "Error"

        RemoteData.Success players ->
            let
                lowerQuery =
                    String.Normalize.removeDiacritics <| String.toLower model.query

                acceptablePlayers =
                    List.filter (String.contains lowerQuery << String.Normalize.removeDiacritics << String.toLower << .webName) players
            in
            div []
                [ h1 [] [ text "Fantasy Premier League Statistics" ]
                , input [ placeholder "Search by Name", onInput SetQuery ] []
                , Table.view config model.tableState acceptablePlayers
                ]


config : Table.Config Player Msg
config =
    Table.config
        { toId = .webName
        , toMsg = SetTableState
        , columns =
            [ teamColumn "Team" .team
            , Table.stringColumn "Name" .webName
            , Table.floatColumn "Selected by [%]" .selectedBy
            , Table.intColumn "Transfers in" .transfersIn
            , Table.intColumn "Transfers out" .transfersOut
            , Table.stringColumn "Reason" .reason
            , Table.stringColumn "Further detail" .detail
            , Table.stringColumn "Potential return" .return
            , Table.stringColumn "Status" .status
            ]
        }


teamColumn : String -> (data -> Int) -> Table.Column data msg
teamColumn name toPic =
    Table.veryCustomColumn
        { name = name
        , viewData = \data -> viewTeam (toPic data)
        , sorter = Table.increasingOrDecreasingBy toPic
        }


viewTeam : Int -> Table.HtmlDetails msg
viewTeam data =
    let
        teamPic =
            "images/" ++ String.fromInt data ++ ".png"
    in
    Table.HtmlDetails []
        [ img [ src teamPic, width 40, height 40 ] []
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = always init
        , update = update
        , subscriptions = always Sub.none
        }
