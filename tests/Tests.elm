module Tests exposing (..)

import Expect
import Html.Parser
import Main exposing (..)
import Test exposing (..)



-- Check out https://package.elm-lang.org/packages/elm-explorations/test/latest to learn more about testing in Elm!


testingPlayer =
    """<tr class='player-row team_119'>
\t\t\t\t\t\t\t<td><div class='mob-title'>Player</div>Callum Wilson</td>
\t\t\t\t\t\t\t<td><div class='mob-title'>Reason</div>Suspended</td>
\t\t\t\t\t\t\t<td><div class='mob-title'>Further Detail</div>10 Yellow Cards</td>
\t\t\t\t\t\t\t<td><div class='mob-title'>Potential Return</div>09/07/2020</td>
\t\t\t\t\t\t\t<td><div class='mob-title'>Condition</div>None</td>
\t\t\t\t\t\t\t<td><div class='mob-title'>Status</div>Ruled Out</td>
\t\t\t\t\t\t\t<td><a href='javascript:;'  data-id='1145' data-type='player' data-name="Callum Wilson" class='track'>Track <i class="fa fa-bell-o" aria-hidden="true"></i></a></td>
\t\t\t\t\t\t</tr>"""


decodedPlayer =
    { firstName = "Callum"
    , secondName = "Wilson"
    , team = 0
    , webName = ""
    , selectedBy = 0
    , transfersIn = 0
    , transfersOut = 0
    , position = ""
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


parseTestingPlayer : List Html.Parser.Node
parseTestingPlayer =
    Maybe.withDefault [] (Result.toMaybe (Html.Parser.run testingPlayer))


all : Test
all =
    describe "A Test Suite"
        [ test "Parsing of injuries from html" <|
            \_ ->
                Expect.equal (List.length parseTestingPlayer) 1
        , test "Is same name" <|
            \_ ->
                Expect.equal
                    (Main.isSameName (Maybe.withDefault (Html.Parser.Text "fail") (List.head parseTestingPlayer))
                        decodedPlayer
                    )
                    True
        , test "Parse text with index" <|
            \_ ->
                let
                    node =
                        Maybe.withDefault (Html.Parser.Text "fail") (List.head parseTestingPlayer)
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
                        joinPlayersInjuries (decodedPlayer :: []) testingPlayer
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
