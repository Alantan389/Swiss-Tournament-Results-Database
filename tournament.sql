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
--
CREATE TABLE Match
(
  winningPlayer integer REFERENCES Player(id),
  losingPlayer integer
);

--
-- The 'Winners' view stores a query which returns the player id and the number of wins they have from the Match table
--
CREATE VIEW Winners as select winningplayer, count(winningplayer) as wins from match group by winningplayer;
--
-- The 'Losers' view stores a query which returns the player id and the number of losses they have from the Match table
--
CREATE VIEW Losers as select losingplayer, count(losingplayer) as losses from match group by losingplayer;
--
-- The standings view creates a table listing each player in descending order of the number of wins they have had.
--      id, name, number of wins, number of matches
--
-- 		The number of wins is counted by querying the Match table - using the Winners view.
--      The number of matches is counted by adding the number of wins with the number of losses from the Losses table.
--      A left join is used in each case to ensure a player's inclusion even if they have no wins or losses (no matches).
--
CREATE VIEW Standings AS SELECT Player.id, Player.name, coalesce(Winners.wins, 0) AS wins, coalesce(Losers.losses , 0) + coalesce(Winners.wins, 0) AS losses FROM Player LEFT JOIN Winners ON Player.id = Winners.winningplayer LEFT JOIN Losers ON Player.id = Losers.losingplayer;

-- The Matches view creates a view over the standings view that shows the potential match ups for the next round.
--		id1, name1, id2, name2
--
-- 		This view uses PostgreSQL's function 'lead' to match each pair of players in the Standings view in descending order
--      of their numbers of wins. ie, the first ranked players is matched with the 2nd, the 2nd with 3rd, the 3rd with the 4th and so on...
--      This list of matches is then filtered by every 2nd match, leaving each player with only 1 match. ie. 1st matched with 2nd, 3rd with 4th...
--
--      Note: this view will need to be iterated in code to remove and re-match those players who may have already played each
--      other.
CREATE VIEW Matches AS SELECT id1, name1, id2, name2 from (SELECT *, row_number() over(ORDER BY NULL) FROM (SELECT id as id1, name as name1, lead(id, 1) over (ORDER BY wins desc, id) as id2, lead(name, 1) over (ORDER BY wins desc, id) as name2 from Standings) as foo) as foo WHERE row_number % 2 != 0;
