function printBoard(board::Board)
  printBoard(board, false)
end

function printBoard(board::Board, printCoords::Bool)
  boardArray = board.boardArray
    println("current player", getCurrentPlayer(board))
    printHand(board, BLACK)
    for j = BOARD_DIMENSIONS:-1:1
        for i= 1:BOARD_DIMENSIONS #print from 9,9 to 9,1
            if printCoords
              @printf("(%d,%d)", i, j) #boardArray[i,j].location[1], boardArray[i,j].location[2]) WE DON'T NEED LOCATION AS A PARAMETER, SINCE PIECES ARE REFERENCED BY THEIR LOCTIONS
            end
            if ( boardArray[i,j].name == King)
                print_with_color(:yellow,boardArray[i,j].name)
                print(" ")
            elseif (boardArray[i,j].color==BLACK)
                print_with_color(:black,boardArray[i,j].name)
                print(" ")
            elseif (boardArray[i,j].color==WHITE)
                print_with_color(:white,boardArray[i,j].name)
                print(" ")
            elseif (j >= PROMOTION_TOP || j <= PROMOTION_BOTTOM) #Pieces is in promotion zone
                print_with_color(:blue,boardArray[i,j].name)
                print(" ")
            else
              @printf("%s ", boardArray[i,j].name)
            end
        end
        @printf("\n")
    end
    printHand(board, WHITE)
end



function printHand(board::Board, player::AbstractString) #white or black
  if player == WHITE
    print("White Hand: ")
    for item in board.whiteHand
      @printf("%s ", item.name)
    end
    println("")
  elseif player == BLACK
    print("Black Hand: ")
    for item in board.blackHand
      @printf("%s ", item.name)
    end
    println("")
  end
end
