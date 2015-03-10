-- Table definitions for the tournament project.
--
-- Put your SQL 'create table' statements in this file; also 'create view'
-- statements if you choose to use it.
--
-- You can write comments in this file by starting them with two dashes, like
-- these lines here.

CREATE TABLE Player
(
  id serial PRIMARY KEY,
  name text
);

--
-- ************* Remove constraint from losingPlayer to enable byes.
-- ************* Add result flas to indicate if match had result!:
-- *************     If true - match won , if false - match drawn.
--
CREATE TABLE Match
(
  winningPlayer integer REFERENCES Player(id),
  losingPlayer integer,
  resultFlag boolean
);

--
-- The 'Winners' view stores a query which returns the player id and the number of wins they have from the Match table
-- 		A winner is only a winner if the result flag is true, otherwise result is a draw and there is no winner.
--
CREATE VIEW Winners AS SELECT winningplayer, count(winningplayer) AS wins FROM match WHERE resultFlag = True GROUP BY winningplayer;
--
-- The 'Losers' view stores a query which returns the player id and the number of losses they have from the Match table
--
CREATE VIEW Losers AS SELECT losingplayer, count(losingplayer) AS losses FROM match GROUP BY losingplayer;
--
-- The 'Draws' view stores a query which returns the player id of players who had a draw while in the first position of a match
-- and the number of draws they have from the Match table. We don't need to count the players in the second postion who had draws
-- because they will be counted as losers.
--
CREATE VIEW Player1Draws AS SELECT winningplayer AS player1, count(winningplayer) AS draws FROM match WHERE resultFlag = False GROUP BY winningplayer;
--
--
-- The standings view creates a table listing each player in descending order of the number of wins they have had.
--      id, name, number of wins, number of matches
--
-- 		The number of wins is counted by querying the Match table - using the Winners view.
--      The number of matches is counted by adding the number of wins with the number of losses from the Losses table.
--      A left join is used in each case to ensure a player's inclusion even if they have no wins or losses (no matches).
--
CREATE VIEW Standings AS SELECT Player.id, Player.name, coalesce(Winners.wins, 0) AS wins, coalesce(Losers.losses , 0) + coalesce(Winners.wins, 0) + coalesce(Player1Draws.draws, 0) AS matches FROM Player LEFT JOIN Winners ON Player.id = Winners.winningplayer LEFT JOIN Losers ON Player.id = Losers.losingplayer LEFT JOIN Player1Draws ON Player.id = Player1Draws.player1;
--
--
-- The ranked view creates a table listing each player in descending order of the number of wins they have had followed
-- by the number of wins their opponents have had.
--      id, name, number of wins, number of opponent match wins.
--
-- 		This is a re-ranking of the Standings view.
--      The number of matches that each player's opponents have won are counted using 2 sub-queries and a union.
--      The Standings view itself is used to look up the number of wins, accessed via the alias of 'baseStandings'.
--
CREATE VIEW Rankings AS SELECT baseStandings.id, name, wins, (SELECT sum(wins) AS oppWins FROM(select winningPlayer AS opponent, wins FROM Match LEFT JOIN Standings ON id = winningPlayer WHERE losingPlayer = bASeStandings.id UNION select losingPlayer AS opponent, wins FROM Match LEFT JOIN Standings ON id = losingPlayer WHERE winningPlayer = baseStandings.id) AS foo) FROM Standings AS baseStandings ORDER BY wins DESC, oppWins DESC;

--
-- The Matches view creates a view over the Rankings view that shows the potential match ups for the next round.
--		id1, name1, id2, name2
--
-- 		This view uses PostgreSQL's function 'lead' to match each pair of players in the Standings view in descending order
--      of their numbers of wins. ie, the first ranked players is matched with the 2nd, the 2nd with 3rd, the 3rd with the 4th and so on...
--      This list of matches is then filtered by every 2nd match, leaving each player with only 1 match. ie. 1st matched with 2nd, 3rd with 4th...
--
--      Note: this view will need to be iterated in code to remove and re-match those players who may have already played each
--      other.
CREATE VIEW Matches AS SELECT id1, name1, id2, name2 FROM (SELECT *, row_number() over(ORDER BY NULL) FROM (SELECT id AS id1, name AS name1, lead(id, 1) over (ORDER BY wins desc, oppWins desc, id) AS id2, lead(name, 1) over (ORDER BY wins desc, oppWins desc, id) AS name2 FROM Rankings) AS foo) AS foo WHERE row_number % 2 != 0;

