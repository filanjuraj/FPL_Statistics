module Main exposing (..)

import Browser
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import RemoteData



---- MODEL ----


type alias Model =
    RemoteData.WebData Response


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
    ( RemoteData.Loading
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DataResponse webDataResponse ->
            ( webDataResponse, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    case model of
        RemoteData.NotAsked ->
            text "Not asked to fetch data"

        RemoteData.Loading ->
            text "Loading ..."

        RemoteData.Failure error ->
            text "Error"

        RemoteData.Success { players } ->
            div [] <| List.map (\{ firstName } -> text firstName) players



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = always init
        , update = update
        , subscriptions = always Sub.none
        }
