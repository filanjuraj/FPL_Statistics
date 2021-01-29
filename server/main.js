const express = require('express')
const cors = require('cors')
const fetch = require('node-fetch')
const htmlParser = require('node-html-parser')
const app = express()

app.use(cors())

app.get('/api/players', async (req, res) => {

     fetch('https://fantasy.premierleague.com/api/bootstrap-static/',{
        headers: {
            'User-Agent': 'ANYTHING_WILL_WORK_HERE'
        }
    })
                        .then(response => response.json())
                        .then(data => {
                            res.send(data);
                        });
  });

app.get('/api/injuries', async (req, res) => {

    fetch('https://www.premierinjuries.com/injury-table.php')
        .then(function (response) {
            switch (response.status) {
                // status "OK"
                case 200:
                    return response.text();
                // status "Not Found"
                case 404:
                    throw response;
            }
        })
        .then(function (templateString) {
            const html = htmlParser.parse(templateString);

            const parsedHtmlTable = html.querySelector(".injury-table");

            const parsedPlayers = parsedHtmlTable.querySelectorAll(".player-row");

            res.send(parsedPlayers.toString());
        })
        .catch(function (response) {
            // "Not Found"
            res.send(response.statusText);
        });

  });

// 404 - not found handling
app.use((req, res, next) => {
  res.status(404).json({ error: '404: Not found' });
});

// launch of server
app.listen(3001);

