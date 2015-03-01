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
CREATE TABLE Match
(
  winningPlayer integer REFERENCES Player(id),
  losingPlayer integer REFERENCES Player(id)
);

-- The standings view creates a table listing each player in descending order of the number of wins they have had.
--      id, name, number of wins, number of matches
--
-- 		The number of wins is counted by querying the Match table - using the players id as foreign key.
--      The number of matches is counted by adding the number of wins already counted with the number of losses
--      calculated the same way as wins except using the losses field of the Match table.
--      A left join is used in each case to ensure a player's incusion even if they have no wins or losses (no matches).
CREATE VIEW Standings AS SELECT players.id, players.name, count(wins.winningplayer) as wins, count(losses.losingplayer) + count(wins.winningplayer) as matches from player players LEFT JOIN match wins on wins.winningplayer = players.id LEFT JOIN match losses on losses.losingplayer = players.id GROUP by players.id;  --ORDER BY wins desc;

-- The Matches view creates a view over the standings view that shows the potential match ups for the next round.
--		id1, name1, id2, name2
--
-- 		This view uses PostgreSQL's function 'lead' to match each pair of players in the Standings view in descending order
--      of their numbers of wins. ie, the first ranked players is matched with the 2nd, the 3rd with the 4th and so on...
--      This list of matches is then filtered by every 2nd match, leaving each player with only 1 match.
--
--      Note: this view needs to be iterated in code to remove and re-match those players who may have already played each
--      other.
CREATE VIEW Matches AS SELECT id1, name1, id2, name2 from (SELECT *, row_number() over(ORDER BY NULL) FROM (SELECT id as id1, name as name1, lead(id, 1) over (ORDER BY wins desc) as id2, lead(name, 1) over (ORDER BY wins desc) as name2 from Standings) as foo) as foo WHERE row_number % 2 != 0;
