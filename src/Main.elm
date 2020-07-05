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


{-| Representation of player with injury data which is used in table
-}
type alias Player =
    { firstName : String
    , secondName : String
    , team : Int
    , webName : String
    , selectedBy : Float
    , transfersIn : Int
    , transfersOut : Int
    , position : String
    , reason : String
    , detail : String
    , return : String
    , status : String
    }


{-| Player decoded from JSON
-}
type alias DecodedPlayer =
    { firstName : String
    , secondName : String
    , team : Int
    , webName : String
    , selectedBy : Float
    , transfersIn : Int
    , transfersOut : Int
    , position : String
    }


{-| Injury parsed from HTML
-}
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
        |> Pipeline.required "element_type" positionDecoder


{-| Converts String from JSON to Float
-}
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


{-| Converts Int from JSON representing position of player to String
-}
positionDecoder : Decode.Decoder String
positionDecoder =
    Decode.int
        |> Decode.andThen
            (\val ->
                case val of
                    1 ->
                        Decode.succeed "GKP"

                    2 ->
                        Decode.succeed "DEF"

                    3 ->
                        Decode.succeed "MID"

                    4 ->
                        Decode.succeed "FWD"

                    _ ->
                        Decode.fail "What is this position?!"
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


{-| This function iterates parsed HTML and joins injury (if found) with player
-}
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
            , position = decodedPlayer.position
            , reason = reason
            , detail = detail
            , return = return
            , status = status
            }

        foundNode =
            List.filter
                (\node_ ->
                    isSameName node_ decodedPlayer
                )
                nodes
    in
    case List.head foundNode of
        Just (Element _ _ innerNodes) ->
            let
                nameNode =
                    List.head
                        (innerNodes
                            |> getElementNodes
                        )
            in
            case nameNode of
                Just (Element _ _ innerNodes2) ->
                    -- the right element should always contain 2 nodes
                    case List.length innerNodes2 == 2 of
                        True ->
                            let
                                reason =
                                    parseTextWithIndex innerNodes 1

                                detail =
                                    parseTextWithIndex innerNodes 2

                                return =
                                    parseTextWithIndex innerNodes 3

                                status =
                                    parseTextWithIndex innerNodes 5
                            in
                            playerConstructor reason detail return status

                        False ->
                            playerConstructor "" "" "" ""

                _ ->
                    playerConstructor "" "" "" ""

        _ ->
            playerConstructor "" "" "" ""


{-| Function which determines if injury corresponds to given player
-}
isSameName : Node -> DecodedPlayer -> Bool
isSameName node decodedPlayer =
    case node of
        Element _ _ innerNodes ->
            let
                nameNode =
                    List.head
                        (innerNodes
                            |> getElementNodes
                        )
            in
            case nameNode of
                Just (Element _ _ innerNodes2) ->
                    case List.length innerNodes2 == 2 of
                        True ->
                            let
                                name =
                                    List.head
                                        (innerNodes2
                                            |> getTextNodes
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


getElementNodes : List Node -> List Node
getElementNodes =
    List.filter
        (\node ->
            case node of
                Element _ _ _ ->
                    True

                _ ->
                    False
        )


getTextNodes : List Node -> List Node
getTextNodes =
    List.filter
        (\node2 ->
            case node2 of
                Text _ ->
                    True

                _ ->
                    False
        )


getTextFromNode : Maybe Node -> Maybe String
getTextFromNode =
    Maybe.map
        (\node ->
            case node of
                Element _ _ innerNodes3 ->
                    innerNodes3
                        |> getTextNodes
                        |> List.head
                        |> Maybe.map
                            (\node3 ->
                                case node3 of
                                    Text text ->
                                        text

                                    _ ->
                                        ""
                            )
                        |> Maybe.withDefault ""

                _ ->
                    ""
        )


parseTextWithIndex : List Node -> Int -> String
parseTextWithIndex list index =
    list
        |> List.tail
        |> Maybe.withDefault []
        |> getElementNodes
        |> List.drop index
        |> List.head
        |> getTextFromNode
        |> Maybe.withDefault ""



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
            , Table.stringColumn "Position" .position
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
