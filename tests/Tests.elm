module Tests exposing (..)

import Expect
import Html.Parser
import Json.Decode
import Main exposing (..)
import Test exposing (..)



-- Check out https://package.elm-lang.org/packages/elm-explorations/test/latest to learn more about testing in Elm!


htmlTestingPlayer =
    """<tr class='player-row team_119'>
\t\t\t\t\t\t\t<td><div class='mob-title'>Player</div>Callum Wilson</td>
\t\t\t\t\t\t\t<td><div class='mob-title'>Reason</div>Suspended</td>
\t\t\t\t\t\t\t<td><div class='mob-title'>Further Detail</div>10 Yellow Cards</td>
\t\t\t\t\t\t\t<td><div class='mob-title'>Potential Return</div>09/07/2020</td>
\t\t\t\t\t\t\t<td><div class='mob-title'>Condition</div>None</td>
\t\t\t\t\t\t\t<td><div class='mob-title'>Status</div>Ruled Out</td>
\t\t\t\t\t\t\t<td><a href='javascript:;'  data-id='1145' data-type='player' data-name="Callum Wilson" class='track'>Track <i class="fa fa-bell-o" aria-hidden="true"></i></a></td>
\t\t\t\t\t\t</tr>"""


jsonTestingPlayer =
    """
    {
    "chance_of_playing_next_round": 100,
    "chance_of_playing_this_round": 0,
    "code": 75115,
    "cost_change_event": 0,
    "cost_change_event_fall": 0,
    "cost_change_start": -6,
    "cost_change_start_fall": 6,
    "dreamteam_count": 1,
    "element_type": 4,
    "ep_next": "-0.2",
    "ep_this": "0.0",
    "event_points": 0,
    "first_name": "Callum",
    "form": "0.8",
    "id": 67,
    "in_dreamteam": false,
    "news": "",
    "news_added": "2020-06-24T19:00:18.390083Z",
    "now_cost": 74,
    "photo": "75115.jpg",
    "points_per_game": "3.3",
    "second_name": "Wilson",
    "selected_by_percent": "4.2",
    "special": false,
    "squad_number": null,
    "status": "a",
    "team": 3,
    "team_code": 91,
    "total_points": 98,
    "transfers_in": 903840,
    "transfers_in_event": 97,
    "transfers_out": 1783764,
    "transfers_out_event": 895,
    "value_form": "0.1",
    "value_season": "13.2",
    "web_name": "Callum Wilson",
    "minutes": 2526,
    "goals_scored": 8,
    "assists": 3,
    "clean_sheets": 3,
    "goals_conceded": 49,
    "own_goals": 0,
    "penalties_saved": 0,
    "penalties_missed": 0,
    "yellow_cards": 9,
    "red_cards": 0,
    "saves": 0,
    "bonus": 8,
    "bps": 295,
    "influence": "377.2",
    "creativity": "347.8",
    "threat": "701.0",
    "ict_index": "141.8",
    "influence_rank": 169,
    "influence_rank_type": 21,
    "creativity_rank": 91,
    "creativity_rank_type": 11,
    "threat_rank": 36,
    "threat_rank_type": 21,
    "ict_index_rank": 60,
    "ict_index_rank_type": 20
    }
"""


decodedPlayer =
    { firstName = "Callum"
    , secondName = "Wilson"
    , team = 3
    , webName = "Callum Wilson"
    , selectedBy = 4.2
    , transfersIn = 97
    , transfersOut = 895
    , position = "FWD"
    }


player =
    { firstName = decodedPlayer.firstName
    , secondName = decodedPlayer.secondName
    , team = decodedPlayer.team
    , webName = decodedPlayer.webName
    , selectedBy = decodedPlayer.selectedBy
    , transfersIn = decodedPlayer.transfersIn
    , transfersOut = decodedPlayer.transfersOut
    , position = decodedPlayer.position
    , reason = "Suspended"
    , detail = "10 Yellow Cards"
    , return = "09/07/2020"
    , status = "Ruled Out"
    }


parseHtmlTestingPlayer : List Html.Parser.Node
parseHtmlTestingPlayer =
    Maybe.withDefault [] (Result.toMaybe (Html.Parser.run htmlTestingPlayer))


all : Test
all =
    describe "A Test Suite"
        [ test "Json player decoder" <|
            \_ ->
                let
                    decodedPlayerFromJson =
                        Json.Decode.decodeString Main.decodePlayer jsonTestingPlayer
                in
                case decodedPlayerFromJson of
                    Ok result ->
                        Expect.equal result decodedPlayer

                    Err e ->
                        Expect.fail (Json.Decode.errorToString e)
        , test "Html parsing of injury" <|
            \_ ->
                Expect.equal (List.length parseHtmlTestingPlayer) 1
        , test "Is same name" <|
            \_ ->
                Expect.equal
                    (Main.isSameName (Maybe.withDefault (Html.Parser.Text "fail") (List.head parseHtmlTestingPlayer))
                        decodedPlayer
                    )
                    True
        , test "Parse text with index" <|
            \_ ->
                let
                    node =
                        Maybe.withDefault (Html.Parser.Text "fail") (List.head parseHtmlTestingPlayer)
                in
                case node of
                    Html.Parser.Element _ _ innerNodes ->
                        Expect.equal (Main.parseTextWithIndex innerNodes 2) player.detail

                    _ ->
                        Expect.fail "Problem with parsing!"
        , test "Injury and player join" <|
            \_ ->
                let
                    playerFromParsing =
                        joinPlayersInjuries (decodedPlayer :: []) htmlTestingPlayer
                in
                case playerFromParsing of
                    Just list ->
                        case List.head list of
                            Just parsedPlayer ->
                                Expect.equal player parsedPlayer

                            Nothing ->
                                Expect.fail "Empty list!"

                    Nothing ->
                        Expect.fail "Not a list!"
        ]
