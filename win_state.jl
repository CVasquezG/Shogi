

## WIN DEPENDENCIES
function winState(board::Board)

  blackKing = Piece( BLACK, King )
  blackPrince = Piece( BLACK, PDrunkenElephant)
  whiteKing = Piece( WHITE, King ) #"k"
  whitePrince = Piece( WHITE, PDrunkenElephant )

  #tracePrint( ("white hand", handForPlayer(board, WHITE)) )
  blackX, blackY = findPiece(board, blackKing)
  if blackX == nothing #Black king not on the board
    if gameType == "chu"
      blackX, blackY = findPiece(board, blackPrince) #Black prince also not on board
      if blackX == nothing
        return "W"
      end
    else
      return "W"
    end
  end
  # if blackKing in handForPlayer(board, WHITE)
  #   return "W" #White won
  # end

  whiteX, whiteY = findPiece(board, whiteKing)
  if whiteX == nothing #White king not on the board
    if gameType == "chu"
      whiteX, whiteY = findPiece(board, whitePrince) #White prince also not on board
      if whiteX == nothing
        return "B"
      end
    else
      return "B"
    end
  end
  # if whiteKing in handForPlayer(board, BLACK)
  #   return "B" #Black won
  # end

  if board.playerResign == BLACK
    return "R" #Black resigned
  elseif board.playerResign == WHITE
    return "r" #White resigned
  end

  #if no one resigned, and no one took a king
  return "?"
end

function checkTimeOut(blackTime, whiteTime)
  if blackTime <= 0 && whiteTime > 0
    println("Black player timeout")
    return "W"
  elseif whiteTime <= 0 && blackTime > 0
    println("White player timeout")
    return "B"
  elseif whiteTime > 0 && blackTime > 0
    return "?"
  end
end
