module Main exposing (..)

import Browser
import Html exposing (Html, div, h1, img, input, text)
import Html.Attributes exposing (placeholder, src)
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
    { firstName : String
    , secondName : String
    , webName : String
    --, selectedBy: Float
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
        |> Pipeline.required "first_name" Decode.string
        |> Pipeline.required "second_name" Decode.string
        |> Pipeline.required "web_name" Decode.string
        --|> Pipeline.required "selected_by_percent" Decode.float
        |> Pipeline.required "transfers_in_event" Decode.int
        |> Pipeline.required "transfers_out_event" Decode.int


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
            [ Table.stringColumn "Name" .webName
            , Table.intColumn "Transfers in" .transfersIn
            , Table.intColumn "Transfers out" .transfersOut
            ]
        }

teamColumn : String -> (data -> Int) -> Table.Column data msg
teamColumn name teamId =
    let
        teamPic = "a.jpg"
    in
        Table.veryCustomColumn
            { name = name
            , viewData = \data -> viewTeam data
            , sorter = Table.unsortable
            }

viewTeam : data -> Table.HtmlDetails msg
viewTeam teamId =
    Table.HtmlDetails []
    [

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
