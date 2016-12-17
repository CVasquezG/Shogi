#=
move_user_drop.jl <filename> <piece>
<xtarget> <ytarget> drops the piece at the coordinates
given. Do not attempt to validate the move,
enter it into the game state regardless of the drop’s
validity. =#
include("dependencies.jl")
#Initializing database
using SQLite

function usage(message)
  println("move_user_drop.jl <filename> <piece> <xtarget> <ytarget>") #<piece> is the piece abbreviation
  println(message)
  exit(1)
end

#=
  This populates the Database
=#
function populateDBDrop()
  db=SQLite.DB(ARGS[1])

  SQLite.query(db, "INSERT INTO moves (move_number, move_type, sourcex, sourcey, targetx, targety, option) VALUES ($(numberOfMoved()+1), 'drop', 0, 0, $(ARGS[3]), $(ARGS[4]), '$(ARGS[2])')")
end

  #Returns the number of Moves in the game
  #which is just the number of lines in the moves table
function numberOfMoved()
  db = SQLite.DB(ARGS[1])
  res = SQLite.query(db, "SELECT COUNT(*) FROM moves;")
  x = get(res[1][1])
  return x
end

function printMoves()
  db = SQLite.DB(ARGS[1])

  res = SQLite.query(db, "SELECT COUNT(*) FROM moves;")
  i = get(res[1][1])

  moveNum = 1
  while moveNum <= i

    res = SQLite.query(db, "SELECT move_number FROM moves WHERE move_number = $moveNum;")
    number = get(res[1][1])

    res = SQLite.query(db, "SELECT move_type FROM moves WHERE move_number = $moveNum;")
    typeOfMove = get(res[1][1])

    res = SQLite.query(db, "SELECT sourcex FROM moves WHERE move_number = $moveNum;")
    sourcex = get(res[1][1])

    res = SQLite.query(db, "SELECT sourcey FROM moves WHERE move_number = $moveNum;")
    sourcey = get(res[1][1])

    res = SQLite.query(db, "SELECT targetx FROM moves WHERE move_number = $moveNum;")
    targetx = get(res[1][1])

    res = SQLite.query(db, "SELECT targety FROM moves WHERE move_number = $moveNum;")
    targety = get(res[1][1])

    res = SQLite.query(db, "SELECT option FROM moves WHERE move_number = $moveNum;")
    option = get(res[1][1])

  #  res = SQLite.query(db, "SELECT i_am_cheating FROM moves WHERE move_number = $moveNum;")
  #  cheating = get(res[1][1])

    println("$number $typeOfMove $sourcex $sourcey $targetx $targety $option")
    moveNum = moveNum + 1
  end
end

#Checks for filename
if !isdefined(ARGS, 1)
  usage("File Name is mandatory")
end

#Checks for piece
if !isdefined(ARGS, 2)
  usage("Initial piece is mandatory")
end

#Checks for xtarget
if !isdefined(ARGS, 3)
  usage("Final x-position is mandatory")
end

#Checks for ytarget
if !isdefined(ARGS, 4)
  usage("Final y-position is mandatory")
end


populateDBDrop()
#println(numberOfMoved())
#printMoves()
