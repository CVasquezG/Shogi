#=
win.jl <filename> will replay the game from
start to finish, at every step checking if the game
is won. If the game is won, print ”B” for Black
winning, and ”W” for white winning. If black resigned,
print ”R”. If white resigned, print ”r”. If the
game is on, print ”?”. If the game is a draw, print ”D”.
The game does not check if the moves are legal or not.
=#
include("dependencies.jl")

using SQLite


function runWinJl()
  db = SQLite.DB(ARGS[1])
  res = SQLite.query(db, "SELECT COUNT(*) FROM moves;")
  tim = SQLite.query(db, "SELECT value FROM meta WHERE key ='timed';")
  sen = SQLite.query(db, "SELECT value FROM meta WHERE key ='sente_time';")
  got = SQLite.query(db, "SELECT value FROM meta WHERE key ='gote_time';")



  # get the total number of moves
  totalMoves = get(res[1][1])
  hasTimeLimit = get(tim[1][1])
  blackTime = parse(Int, getSQLValue(sen))
  whiteTime = parse(Int, getSQLValue(got))

  # initialize the board
  board::Board = initBoard()
  newBoard = deepcopy(board)

  allBoardStates = []
  push!(allBoardStates, newBoard.boardArray) #add starting boardstate to allBoardstates
  moveNum = 1

  if hasTimeLimit == "yes"
    result = checkTimeOut(blackTime, whiteTime)
    if result != "?"
      return result
    end
  end

  while moveNum <= totalMoves
    newBoard = deepcopy(generateNextBoard(board, db, moveNum))
    push!(allBoardStates, newBoard.boardArray) #starting boardstate is index i, current boardstate is index moveNum+1

    win = winState(newBoard) #will either be "B", "W", "?", "R", "r"

    if win != "?" #if game is not in progress
      return win
    end

    #check for draws
    drawFlag = 0
    for i = 1:moveNum #go through each boardstate starting from the first move, to the one right before the current
      #tracePrint("moveNum")
      #tracePrint(moveNum)
      # tracePrint(allBoardStates[i])
      if allBoardStates[i] == allBoardStates[moveNum+1] #Same board position has occured
        drawFlag += 1
        #tracePrint("drawFlag")
        #tracePrint(drawFlag)
      end
    end


    if drawFlag >= 3
      return "D"
    end
    moveNum = moveNum + 1
  end
  return "?"
end



global resultWin = runWinJl()
println(resultWin)
