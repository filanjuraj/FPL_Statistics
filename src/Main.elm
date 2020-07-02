module Main exposing (..)

import Browser
import Html exposing (Html, div, h1, img, input, text)
import Html.Attributes exposing (height, placeholder, src, width)
import Html.Events exposing (onInput)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import RemoteData
import Table



---- MODEL ----


type alias Model =
    { response : RemoteData.WebData Response
    , tableState : Table.State
    , query : String
    }


type alias Response =
    { players : List Player }


type alias Player =
    { team : Int
    , webName : String
    , selectedBy: Float
    , transfersIn: Int
    , transfersOut: Int
    }


dataEndpointUrl : String
dataEndpointUrl =
    "http://localhost:3001/api/players"


init : ( Model, Cmd Msg )
init =
    ( { response = RemoteData.Loading
      , tableState = Table.initialSort "Name"
      , query = ""
      }
    , getPlayers
    )

getPlayers : Cmd Msg
getPlayers = Http.get { url = dataEndpointUrl
                      , expect = Http.expectJson (RemoteData.fromResult >> DataResponse) decodeDataResponse
                      }

decodePlayer : Decode.Decoder Player
decodePlayer =
    Decode.succeed Player
        |> Pipeline.required "team" Decode.int
        |> Pipeline.required "web_name" Decode.string
        |> Pipeline.required "selected_by_percent" stringFloatDecoder
        |> Pipeline.required "transfers_in_event" Decode.int
        |> Pipeline.required "transfers_out_event" Decode.int

stringFloatDecoder : Decode.Decoder Float
stringFloatDecoder =
  (Decode.string)
    |> Decode.andThen
        (\val ->
            case String.toFloat val of
              Just f -> Decode.succeed f
              Nothing -> Decode.fail "not a float"
        )

decodeDataResponse : Decode.Decoder Response
decodeDataResponse =
    Decode.succeed Response
        |> Pipeline.required "elements" (Decode.list decodePlayer)



---- UPDATE ----


type Msg
    = DataResponse (RemoteData.WebData Response)
    | SetQuery String
    | SetTableState Table.State


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DataResponse webDataResponse ->
            ( {model | response = webDataResponse}
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



---- VIEW ----


view : Model -> Html Msg
view model =
    case model.response of
        RemoteData.NotAsked ->
            text "Not asked to fetch data"

        RemoteData.Loading ->
            text "Loading ..."

        RemoteData.Failure error ->
            text "Error"

        RemoteData.Success { players } ->
            let
                lowerQuery =
                    String.toLower model.query

                acceptablePlayers =
                    List.filter (String.contains lowerQuery << String.toLower << .webName) players
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
        teamPic = "images/" ++ (String.fromInt data) ++ ".png"
    in
        Table.HtmlDetails []
        [
            img [src (teamPic)] []
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
