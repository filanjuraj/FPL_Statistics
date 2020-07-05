# FPL_Statistics

# Introduction

Statistic webapp for Fantasy Premier League (FPL) managers coded in elm as a semestral work in course Applied Function Programming at FIT CTU. This application will be supported and updated throughout every FPL season I will be playing.

### Fantasy Premier League
[FPL](https://fantasy.premierleague.com/) is a game in which participants assemble an imaginary team of real life Premier League footballers and score points based on those players' actual statistical performance or their perceived contribution on the field of play.

### Functionality and Usability
Because of long coronavirus break, players went out of game tempo and lost physical and mental game sense, which often leads to injuries. Since injuries are now big issue, I decided to dedicate this application to gather injury information about players from [PL injuries](https://www.premierinjuries.com/injury-table.php) and join the gathered data with data from [Official fantasy API](https://fantasy.premierleague.com/api/bootstrap-static/).

More functionalities including current player form will be added later.

### Similiar projects
Since millions of players are playing this game in the whole world, there are already many websites with similiar goal. Most famous is http://www.fplstatistics.co.uk/ and many others. Lot of websites force you to make an account or pay for their service. This project will be free, but for my friends only (so we will be in an advantage against other players :)).

# Getting Started

After downloading this project, go to root file of the project and type these commands.

Start the server:

`npm start`

Run the application:

`elm-app start`

# Implementation

### Server

It's main goal is to handle [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS).
It fetches data from [PL injuries](https://www.premierinjuries.com/injury-table.php) and [Official fantasy API](https://fantasy.premierleague.com/api/bootstrap-static/) and creates an API for getting these data.
The source code of the server written in JavaScript is located in `.\server\server.js`.

### Web Application

It communicates with the server and gets injuries and players data from the server. It's main functionality is to join these two data (by name of the player) and show them in the table. The source code of the web application written in Elm is located in `.\src\Main.elm`.

Player consists of these attributes:
```
type alias Player =
    { firstName : String
    , secondName : String
    , team : Int
    , webName : String
    , selectedBy : Float
    , transfersIn : Int
    , transfersOut : Int
    , position : String -- attributes of this and above are gathered from official FPL Api
    , reason : String -- attributes of this and below are gathered from PL injuries website
    , detail : String
    , return : String
    , status : String
    }
```



### Used packages, libraries and tools

* [billstclair/elm-sortable-table](https://package.elm-lang.org/packages/billstclair/elm-sortable-table/latest/) - table view
* [hecrj/html-parser](https://package.elm-lang.org/packages/hecrj/html-parser/latest/) - parsing injuries from [PL injuries](https://www.premierinjuries.com/injury-table.php)
* [kuon/elm-string-normalize](https://package.elm-lang.org/packages/kuon/elm-string-normalize/latest/String-Normalize) - ignoring diacritis when searching in the table
* [krisajenkins/remotedata](https://package.elm-lang.org/packages/krisajenkins/remotedata/latest/) - tools for fetching data from HTTP
* [Create Elm App](https://github.com/halfzebra/create-elm-app) - creates Elm project

### Testing



To run tests, type this command in the root of the project:

`elm-test`

The source code of tests written in Elm is located in `.\tests\Tests.elm`.
