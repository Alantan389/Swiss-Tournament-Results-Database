#!/usr/bin/env python
# 
# tournament.py -- implementation of a Swiss-system tournament
#

import psycopg2


def connect():
    """Connect to the PostgreSQL database.  Returns a database connection."""
    return psycopg2.connect("dbname=tournament")

def deleteMatches():
    """Remove all the match records from the database."""
    dB = connect()
    cursor = dB.cursor()
    cursor.execute("DELETE FROM match;")    
    dB.commit()
    dB.close()

def deletePlayers():
    """Remove all the player records from the database."""
    dB = connect()
    cursor = dB.cursor()
    cursor.execute("DELETE FROM player;")
    dB.commit()
    dB.close()

def countPlayers():
    """Returns the number of players currently registered."""
    dB = connect()
    cursor = dB.cursor()
    cursor.execute("SELECT count(*) FROM player;")
    numPlayers = cursor.fetchall()[0][0]
    dB.close()
    return numPlayers

def countWinners():
    """Returns the number of players that have scored a win."""
    dB = connect()
    cursor = dB.cursor()
    cursor.execute("SELECT count(*) FROM Winners;")
    numWinners = cursor.fetchall()[0][0]
    dB.close()
    return numWinners
 
def registerPlayer(name):
    """Adds a player to the tournament database.
  
    The database assigns a unique serial id number for the player.  (This
    should be handled by your SQL database schema, not in your Python code.)
  
    Args:
      name: the player's full name (need not be unique).
    """
    dB = connect()
    cursor = dB.cursor()
    cursor.execute("INSERT INTO player (name) VALUES (%s);", (name,))
    dB.commit()
    dB.close()


def playerStandings():
    """Returns a list of the players and their win records, sorted by wins.

    The first entry in the list should be the player in first place, or a player
    tied for first place if there is currently a tie.

    Returns:       A list of tuples, each of which contains (id, name, wins,matches):
                   id: the player's unique id (assigned by the database)
                   name: the player's full name (as registered)         
                   wins: the number of matches the player has won         
                   matches: the number of matches the player has played     """

    dB = connect()
    cursor = dB.cursor()
    cursor.execute('SELECT * from Standings order by wins desc, id;')
    standings = cursor.fetchall()
    dB.close()
    return standings

def reportMatch(winner, loser = 0, result = True):
    """Records the outcome of a single match between two players.

    Args:
      winner:  the id number of the player who won
      loser:  the id number of the player who lost
      Note: if loser omitted the winner was a bye (gets credited a win for the bye).
      True: the result flag, if false the match was a draw.

    """
    dB = connect()
    cursor = dB.cursor()
    cursor.execute("INSERT INTO match VALUES (%s, %s, %s);", (winner, loser, result))
    dB.commit()
    dB.close()
 
 
def swissPairings():
    """Returns a list of pairs of players for the next round of a match.
  
    Assuming that there are an even number of players registered, each player
    appears exactly once in the pairings.  Each player is paired with another
    player with an equal or nearly-equal win record, that is, a player adjacent
    to him or her in the standings.

    If there is an odd number of players, one player each round will have a 
    bye. Each player can only have 1 bye, so for each roundl the player with
    the bye must be checked to see if they have already had one. The player 
    with the bye will be credited with win.

    ** This code does not currently check that players have not previously 
    played each other so rematches are possible
  
    Returns:
      A list of tuples, each of which contains (id1, name1, id2, name2)
        id1: the first player's unique id
        name1: the first player's name
        id2: the second player's unique id - this will be blank if bye
        name2: the second player's name - this will be blank if bye
    """
    dB = connect()
    cursor = dB.cursor()
    cursor.execute("SELECT * from Matches;")
    matches = cursor.fetchall()

    # If odd number of players - there will be a bye
    cursor.execute("SELECT count(*) from Player;")
    numPlayers = cursor.fetchall()[0][0]
    if (numPlayers % 2) != 0:
        # Check that player with bye had not already had a bye.
        byeOk = False   # This flag will be set to true when bye player is found to have not had a previous bye.
        swapNumber = 1  # This variable controls which previous player to try swapping with bye player.

        while byeOk == False:
            # Last match in list is bye, get that players id; ie. the first player on the last row of matches
            numMatches = len(matches)
            (byeId, byeName, byeId2, byeName2) = matches[numMatches - 1]
            # Select from database any record that shows this player has already had a bye
            cursor.execute("SELECT * FROM Match WHERE winningPlayer = %s and losingPlayer = %s;", (byeId, 0))
            prevBye = cursor.fetchone()
            # If previous bye is found, swap this player with next player up the ranking
            if prevBye != None:
                # First store previous match to bye - 
                prevMatch = numMatches - ((swapNumber - 1) / 2) - 2
                (pid1, pname1, pid2, pname2) = matches[prevMatch]
                # This code determines if swapping the bye player with the 1st or 2nd player of the previous match
                if (swapNumber % 2) == 1: 
                    matches[prevMatch] = (pid1, pname1, byeId, byeName)
                    matches[numMatches - 1] = (pid2, pname2, byeId2, byeName2)
                if (swapNumber % 2) == 0:
                    matches[prevMatch] = (byeId, byeName, pid2, pname2)
                    matches[numMatches - 1] = (pid1, pname1, byeId2, byeName2)

                # Increment swap number so that if another bye swap is needed, the next player up is swapped!
                swapNumber += 1
            else:
                # Player with bye was not found to have a previous bye, so this is ok; we can exit loop
                byeOk = True

    dB.close()
    return matches
