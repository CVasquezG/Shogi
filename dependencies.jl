#=
Helper funtions for all files
=#

include("helpers.jl")
import Base.==
using SQLite
include("piece_type.jl")
include("board_type.jl")
include("move_type.jl")

ourSeed = ARGS[1]

ourRand = MersenneTwister(ourSeed)

function getType(filename)
  db = SQLite.DB(filename)
  res = SQLite.query(db, "SELECT value FROM meta WHERE key ='type';")
  x = get(res[1][1])
  return x
end

function getCheating(filename)
  db = SQLite.DB(filename)
  res = SQLite.query(db, "SELECT value FROM meta WHERE key ='legality';")
  x = get(res[1][1])
  return x
end

#TODO get time info now stored in meta

include("constants.jl")
include("legal_moves.jl")
include("update_board.jl")

#Reads from DataBase
function readDB()
  db=SQLite.DB(ARGS[1])

	res = SQLite.query(db, "SELECT COUNT(*) FROM moves;")
	final = get(res[1][1])
  #tracePrint(final)

  moveNum = 1
  while moveNum <= final
    x = SQLite.query(db, "SELECT * FROM moves WHERE move_number=$moveNum")
    #tracePrint(x)
    moveNum = moveNum + 1
  end
end

function usage(message)
  println(message)
  exit(1)
end

function movesFromDB(filename)
  db = SQLite.DB(filename)
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
    if typeof(res[1][1])!= Nullable{Any}
        option = get(res[1][1])
    else
      option="Null"
    end
    tracePrint(res)
    tracePrint( ("TYPE OF", typeof(res) ))

    res = SQLite.query(db, "SELECT i_am_cheating FROM moves WHERE move_number = $moveNum;")
    if typeof(res[1][1])!= Nullable{Any}
        cheating = get(res[1][1])
    else
      cheating="Null"
    end

#= Get these only if they exist!! =#

    res = SQLite.query(db, "SELECT targetx2 FROM moves WHERE move_number = $moveNum;")
    if typeof(res[1][1])!= Nullable{Any}
      targetx2 = get(res[1][1])
    else
      targetx2="Null"
    end

    res = SQLite.query(db, "SELECT targety2 FROM moves WHERE move_number = $moveNum")
#    if !isdefined(res)
#      continue
#    else
    if typeof(res[1][1])!= Nullable{Any}
      targety2 = get(res[1][1])
    else
      targety2="Null"
    end
    println("SUCCESS!!!!")
#    end

#    if isdefined(targetx2)
#      println("$number $typeOfMove $sourcex $sourcey $targetx $targety $targetx2 $targety2")
#    else

    println("$number $typeOfMove $sourcex $sourcey $targetx $targety $option $cheating $targetx2 $targety2 ")
    moveNum = moveNum + 1
  end
end

function generateNextBoard(board, db, index)
  x = SQLite.query(db, "SELECT move_type FROM moves WHERE move_number=$index")
  moveType = get(x[1][1])

  #if SQL move_type is "move", get the source and target coordinates, as well as option for promotion
  if moveType == "move"
    SX = SQLite.query(db, "SELECT sourcex FROM moves WHERE move_number = $index;")
    sourcex = get(SX[1][1])
    SY = SQLite.query(db, "SELECT sourcey FROM moves WHERE move_number = $index;")
    sourcey = get(SY[1][1])
    TX = SQLite.query(db, "SELECT targetx FROM moves WHERE move_number = $index;")
    targetx = get(TX[1][1])
    TY = SQLite.query(db, "SELECT targety FROM moves WHERE move_number = $index;")
    targety = get(TY[1][1])
    OP = SQLite.query(db, "SELECT option FROM moves WHERE move_number = $index;")
    #println(OP)
    option = getSQLValue(OP)

    res = SQLite.query(db, "SELECT targetx2 FROM moves WHERE move_number = $index;")
    targetx2 = getSQLValue(res)
    res = SQLite.query(db, "SELECT targety2 FROM moves WHERE move_number = $index;")
    targety2 = getSQLValue(res)

    res = SQLite.query(db, "SELECT targetx3 FROM moves WHERE move_number = $index;")
    targetx3 = getSQLValue(res)
    res = SQLite.query(db, "SELECT targety3 FROM moves WHERE move_number = $index;")
    targety3 = getSQLValue(res)



    #update the board with a regular move or double move, or a triple move
    if targetx2 != nothing && targety2 != nothing
      if targetx3 != nothing && targety3 != nothing
        newMove = initMoveTripleMovement(sourcex, sourcey, targetx, targety, option, targetx2, targety2, targetx3, targety3)
      else
        newMove = initMoveDoubleMovement(sourcex, sourcey, targetx, targety, option, targetx2, targety2)
      end
    else
      newMove = initMoveMovement(sourcex, sourcey, targetx, targety, option)
    end
    updateBoard(board, newMove)

  #if SQL move_type is "drop", get the target coordinates
  elseif moveType == "drop"
    TX = SQLite.query(db, "SELECT targetx FROM moves WHERE move_number = $index;")
    targetx = get(TX[1][1])
    TY = SQLite.query(db, "SELECT targety FROM moves WHERE move_number = $index;")
    targety = get(TY[1][1])
    p= SQLite.query(db, "SELECT option FROM moves WHERE move_number = $index;")
    piece = get(p[1][1])

    #= TODO - STACEY - if x2 y2 exist and are needed here? =#
    # res = SQLite.query(db, "SELECT targetx2 FROM moves WHERE move_number = $index;")
    # targetx2 = getSQLValue(res) #get(res[1][1])
    # res = SQLite.query(db, "SELECT targety2 FROM moves WHERE move_number = $index;")
    # targety2 = getSQLValue(res) #get(res[1][1])

    pieceName = getAbbName(lowercase(piece))
    newPiece = Piece(getCurrentPlayer(board), pieceName)
    newMove = initMoveDrop(targetx, targety, newPiece)
    updateBoard(board, newMove)

  elseif moveType == "resign"
    newMove = initMoveResign()
    updateBoard(board, newMove)
  end
  return board
end

function generateCurrentBoard()
  db = SQLite.DB(ARGS[1])
  res = SQLite.query(db, "SELECT COUNT(*) FROM moves;")
  i = get(res[1][1])

  board::Board = initBoard()

  moveNum = 1
  while moveNum <= i
    generateNextBoard(board, db, moveNum)
    moveNum = moveNum + 1
  end
  return board
end


function getSQLValue(SQLThing)
  if typeof(SQLThing[1][1]) == Nullable{Any}
    return nothing
  else
    return get(SQLThing[1][1])
  end
end


function randChar()
  return Char( rand(ourRand, 48:122) )
end

function randString(length::Int)
  stringArray = []
  for i in 1:length
    push!(stringArray, "$(randChar())" )
  end
  string = join( stringArray, "")
  return string
end



include("win_state.jl")
include("display_functions.jl")




function usage(message)
  println(message)
end


if !isdefined(ARGS, 1)
  usage("File name is Mandatory.")
end
