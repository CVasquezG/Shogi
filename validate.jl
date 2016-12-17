#=
  validate.jl <filename> will replay the game
  from start to the current move, at every step making
  sure that the rules were kept. Print 0 is the
  game was played cleanly so far and the move ID
  of the violating move if it wasn’t.
=#

include("dependencies.jl")


function checkLegal(board::Board, move)
  legal = allLegalMoves(board)
  #tracePrint("BLAH")

  if move in legal
    return true
  else
    return false
  end

end

function replay()
  db = SQLite.DB(ARGS[1])
  res = SQLite.query(db, "SELECT COUNT(*) FROM moves;")
  # get the total number of moves
  totalMoves = get(res[1][1])

  # initialize the board
  board::Board = initBoard()
  #newBoard = deepcopy(board)

  validate = true #gamestate starts legal
  moveNum = 1

  while moveNum <= totalMoves #while there are more moves to check
  ######################################

  # legalArr = []
  # legalArr = allLegalMoves(board)

      #This line just gets table rows. println(x) to display the table.
    #tracePrint("MOVE NUMBER: $moveNum")
    y = SQLite.query(db, "SELECT move_type FROM moves WHERE move_number=$moveNum")
    moveType = get(y[1][1])
    SX= SQLite.query(db, "SELECT sourcex FROM moves WHERE move_number=$moveNum")
    sourcex=get(SX[1][1])
    SY= SQLite.query(db, "SELECT sourcey FROM moves WHERE move_number=$moveNum")
    sourcey=get(SY[1][1])
    TX= SQLite.query(db, "SELECT targetx FROM moves WHERE move_number=$moveNum")
    targetx=get(TX[1][1])
    TY= SQLite.query(db, "SELECT targety FROM moves WHERE move_number=$moveNum")
    targety=get(TY[1][1])
    OP = SQLite.query(db, "SELECT option FROM moves WHERE move_number = $moveNum")
    TX2= SQLite.query(db, "SELECT targetx2 FROM moves WHERE move_number=$moveNum")
    TY2= SQLite.query(db, "SELECT targety2 FROM moves WHERE move_number=$moveNum")

    option = getSQLValue(OP)
    targetx2 = getSQLValue(TX2)
    targety2 = getSQLValue(TY2)


    #println("TYPE OF MOVE: $moveType")
    #tracePrint("$moveType, $sourcex, $sourcey")


    if moveType == "resign"
      move = initMoveResign()
    elseif moveType == "move"
      if targetx2 != nothing && targety2 != nothing
        move = initMoveDoubleMovement(sourcex, sourcey, targetx, targety, option, targetx2, targety2)
      else
        move = initMoveMovement(sourcex, sourcey, targetx, targety, option)
      end
    elseif moveType == "drop"
      newPiece = Piece(getCurrentPlayer(board), option)
      if newPiece.color == WHITE
        newPiece.color = BLACK
      elseif newPiece.color == BLACK
        newPiece.color = WHITE
     end

       move = initMoveDrop(targetx, targety, newPiece)
    end

    validate = checkLegal(board, move)
    if validate == false
      return moveNum
    end

    generateNextBoard(board, db, moveNum)
    moveNum += 1
  end
  return 0
end

#printMoves()
global resultValidate = replay() #results in 0 if all moves are valid, or the move_number of an invalid move
println(resultValidate)

if !isdefined(ARGS, 1)
  usage("File Name is mandatory")
end
