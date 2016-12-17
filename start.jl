#=
start.jl <filename> <type> <cheating> <limit> <limit_add>

type: S - standard ; M - minishogi; C - chushogi; T - tenjiku shogi
cheating: T - true ; F - false

 CREATEs a database for a new game. Creates new database for each game.
 Creates EMPTY moves table.

 start.jl <filename> <type> <cheating> <limit>
<limit_add> will set up a game file. The file will be
created, including all tables and key-value pairs.
start.jl will make no moves. Make sure that the
board is ready and black is set to move. If type is
”S” then start a game of standard shogi. If type is
”M” then start a game of minishogi. If type is ”C”
then start a game of chu shogi. If cheating is ”T”
then your move_cheat.jl program is permitted to
try to play cheating moves, if it thinks it would be
of benefit. move.jl never cheats, even in a game
with cheating enabled. Limit will be set to an integer
if there is to be a time limit. If limit is absent or
0, there is no time limit. This limit is the time allowance
for the entire game’s worth of moves for
a single player. If limit_add is present and nonzero
then this is how much time should be added
to a player’s clock, using the Fischer timing system.
=#

using SQLite

function usage(message)
  println(message)
  exit(1)
end

#Creating the meta table
function createMeta()
  #if starting a new game, create new database
  # filename created through args, <filename>, <type>, <cheating> <limit> <limit_add>
  db=SQLite.DB(ARGS[1])
  SQLite.query(db, "CREATE TABLE meta (key CHAR(10) PRIMARY KEY, value CHAR(10))")

  if ARGS[2]=="S"
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('type', 'standard')")
  elseif ARGS[2]=="M"
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('type', 'minishogi')")
  elseif ARGS[2]=="C"
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('type', 'chu')")
  elseif ARGS[2]=="T"
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('type', 'ten')")
  end

  if ARGS[3]=="T"
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('legality', 'cheating')")
  else
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('legality', 'legal')")
  end

  if !isdefined(ARGS, 4) || ARGS[4] == "0"
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('timed', 'no')")
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('sente_time', '0')")
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('gote_time', '0')")
  elseif ARGS[4] != 0
    #println(typeof(ARGS[4]))
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('timed', 'yes')")
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('sente_time', $(ARGS[4]))")
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('gote_time', $(ARGS[4]))")
  end
  if !isdefined(ARGS, 5) || ARGS[5] == "0"
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('time_add', '0')")
  elseif ARGS[5] != 0
    SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('time_add', $(ARGS[5]))")
  end

  t=string(time())
  timeUnix= round(Int,parse(Float64,t))
  SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('seed', $timeUnix)")
end

function createMoves()
  db=SQLite.DB(ARGS[1])
  SQLite.query(db, "CREATE TABLE moves (move_number INTEGER PRIMARY KEY, move_type CHAR(10), sourcex INTEGER, sourcey INTEGER,targetx INTEGER, targety INTEGER, option CHAR(10), i_am_cheating CHAR(10), targetx2 INTEGER, targety2 INTEGER, targetx3 INTEGER, targety3 INTEGER)")
end

#Checks to see that filename has been entered.
if !isdefined(ARGS, 1)
  usage("File Name is mandatory")
end

#Checks to see if type of game has been specified
#=
if !isdefined(ARGS, 2)
  usage("Type of Game is mandatory")
elseif ARGS[2] != "S" && ARGS[2] != "s" && ARGS[2] != "M" && ARGS[2] != "m" && ARGS[2] != "c" && ARGS[2] != "C"
  usage("Enter either S, M or C please.")
end
=#

#Checks to see if Cheating has been set to T or F
if !isdefined(ARGS, 3)
  usage("Must indicate whether or not cheating is allowed!")
elseif ARGS[3] != "T" && ARGS[3] != "F"
  usage("Cheating can only be T or F!")
end

#Checks to see if file already exists.
if isfile(ARGS[1])
  usage("$(ARGS[1]) already exists. Use another name.")
end

createMeta()
createMoves()
