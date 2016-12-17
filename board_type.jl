

##Board
type Board
  boardArray::Array
  turnNumber::Int
  playerResign::AbstractString #black or white
  whiteHand::Array
  blackHand::Array
end

#Get tthe piece from the given location
function getPiece(board::Board, inX::Int, inY::Int)
  return board.boardArray[inX, inY]
end
#Identical. The original function appeared undefined once, and this is the workaround.
# function getPiece2(board::Board, inX::Int, inY::Int) #for a reason I can't find, getPiece becomes undefined later. This is a short workaround. Note that undefined functions is not possible, according to julia docs.
#     return board.boardArray[inX, inY]
# end


#Sets the piece at a location to the given piece. This should be protected, and only called by updateBoard.
function setPiece(board::Board, inX::Int, inY::Int, piece::Piece) #DON'T USE THIS TO MOVE PIECES. USE UPDATEBOARD
  board.boardArray[inX, inY] = piece
end


#Returns the coordinates of the first instance of the piece it finds. Probably only useful for the king. Returns nothing if not found.
function findPiece(board::Board, piece::Piece)
  for x in 1:BOARD_DIMENSIONS
    for y in 1:BOARD_DIMENSIONS
      if board.boardArray[x,y] == piece
        return x, y
      end
    end
  end
  return nothing, nothing
end



#Determines and returns the board's current player.
function getCurrentPlayer(board::Board)
  if board.turnNumber % 2 == 1
    return BLACK
  else
    return WHITE
  end
end

function getNextPlayer(board::Board)
  current = getCurrentPlayer(board)
  if current == BLACK
    return WHITE
  elseif current == WHITE
    return BLACK
  else
    assert(false)
  end
end



##INITIALIZING BOARD
#whiteHand = initHand() #to add a new Piece to hand do: push!(whiteHand, Piece(WHITE,Pawn,false,[0,0],""))
#blackHand = initHand()

#Fills the boardArray with empty pieces
function emptyBoardArray(boardArray)
    for i = 1:BOARD_DIMENSIONS
        for j= 1:BOARD_DIMENSIONS
           boardArray[i,j] = Piece("","-")
        end
    end
    return boardArray
end


function fillInitialBoardArray(boardArray)

    if gameType == "standard"
      # pieceNames = [
      # "lance" "-" "pawn" "-" "-" "-" "pawn" "-" "lance";
      # "knight" "bishop" "pawn" "-" "-" "-" "pawn" "rook" "knight";
      # "silver_general" "-" "pawn" "-" "-" "-" "pawn" "-" "silver_general";
      # "gold_general" "-" "pawn" "-" "-" "-" "pawn" "-" "gold_general";
      # "king" "-" "pawn" "-" "-" "-" "pawn" "-" "king";
      # "gold_general" "-" "pawn" "-" "-" "-" "pawn" "-" "gold_general";
      # "silver_general" "-" "pawn" "-" "-" "-" "pawn" "-" "silver_general";
      # "knight" "rook" "pawn" "-" "-" "-" "pawn" "bishop" "knight";
      # "lance" "-" "pawn" "-" "-" "-" "pawn" "-" "lance";
      # ]

      pieceNames = [
      "l" "-" "p" "-" "-" "-" "p" "-" "l"; #[1,1] - [1,9]
      "n" "b" "p" "-" "-" "-" "p" "r" "n"; #[2,1] - [2,9]
      "s" "-" "p" "-" "-" "-" "p" "-" "s"; #[3,1] - [3,9]
      "g" "-" "p" "-" "-" "-" "p" "-" "g"; #so on
      "k" "-" "p" "-" "-" "-" "p" "-" "k";
      "g" "-" "p" "-" "-" "-" "p" "-" "g";
      "s" "-" "p" "-" "-" "-" "p" "-" "s";
      "n" "r" "p" "-" "-" "-" "p" "b" "n";
      "l" "-" "p" "-" "-" "-" "p" "-" "l";
      ]
      for i = 1:BOARD_DIMENSIONS
        for j = 1:BOARD_DIMENSIONS
          boardArray[i,j].name = pieceNames[i,j]

          #color every piece
          if j<=3 && !isNullPiece(boardArray[i,j])
            boardArray[i,j].color = WHITE
          elseif j>=7 && !isNullPiece(boardArray[i,j])
            boardArray[i,j].color = BLACK
          end
        end
      end

    elseif gameType == "minishogi" #minishogi
      # pieceNames = [
      # "king" "pawn" "-" "-" "rook"; #[1,1] - [1,5]
      # "gold_general" "-" "-" "-" "bishop"; #[2,1] - [2,5]
      # "silver_general" "-" "-" "-" "silver_general"; #[3,1] - [3,5]
      # "bishop" "-" "-" "-" "gold_general"; #so on
      # "rook" "-" "-" "pawn" "king";
      # ]
      pieceNames = [
      "k" "p" "-" "-" "r"; #[1,1] - [1,5]
      "g" "-" "-" "-" "b"; #[2,1] - [2,5]
      "s" "-" "-" "-" "s"; #[3,1] - [3,5]
      "b" "-" "-" "-" "g"; #so on
      "r" "-" "-" "p" "k";
      ]
      for i = 1:BOARD_DIMENSIONS
        for j = 1:BOARD_DIMENSIONS
          boardArray[i,j].name = pieceNames[i,j]

          #color every piece
          if j<=2 && !isNullPiece(boardArray[i,j])
            boardArray[i,j].color = WHITE
          elseif j>=4 && !isNullPiece(boardArray[i,j])
            boardArray[i,j].color = BLACK
          end
        end
      end

    elseif gameType == "chu"
      # pieceNames = [
      # "lance" "reverse_chariot" "side_mover" "pawn" "-" "-" "-" "-" "pawn" "side_mover" "reverse_chariot" "lance"; #[1,1] - [1,9]
      # "ferocious_leopard" "-" "vertical_mover" "pawn" "-" "-" "-" "-" "pawn" "vertical_mover" "-" "ferocious_leopard"; #[2,1] - [2,9]
      # "copper_general" "bishop" "rook" "pawn" "-" "-" "-" "-" "pawn" "rook" "bishop" "copper_general"; #[3,1] - [3,9]
      # "silver_general" "-" "dragon_horse" "pawn" "o" "-" "-" "o" "pawn" "dragon_horse" "-" "silver_general"; #so on
      # "gold_general" "blind_tiger" "dragon_king" "pawn" "-" "-" "-" "-" "pawn" "dragon_king" "blind_tiger" "gold_general";
      # "king" "kirin" "lion" "pawn" "-" "-" "-" "-" "pawn" "lion" "kirin" "king";
      # "drunken_elephant" "phoenix" "queen" "pawn" "-" "-" "-" "-" "pawn" "queen" "phoenix" "drunken_elephant";
      # "gold_general" "blind_tiger" "dragon_king" "pawn" "-" "-" "-" "-" "pawn" "dragon_king" "blind_tiger" "gold_general";
      # "silver_general" "-" "dragon_horse" "pawn" "o" "-" "-" "o" "pawn" "dragon_horse" "-" "silver_general";
      # "copper_general" "bishop" "rook" "pawn" "-" "-" "-" "-" "pawn" "rook" "bishop" "copper_general";
      # "ferocious_leopard" "-" "vertical_mover" "pawn" "-" "-" "-" "-" "pawn" "vertical_mover" "-" "ferocious_leopard";
      # "lance" "reverse_chariot" "sm" "pawn" "-" "-" "-" "-" "pawn" "sm" "reverse_chariot" "lance";
      # ]

      pieceNames = [
      "l"  "rc" "sm" "p" "-" "-" "-" "-" "p" "sm" "rc" "l"; #[1,1] - [1,9]
      "fl" "-"  "vm" "p" "-" "-" "-" "-" "p" "vm" "-"  "fl"; #[2,1] - [2,9]
      "c"  "b"  "r"  "p" "-" "-" "-" "-" "p" "r"  "b"  "c"; #[3,1] - [3,9]
      "s"  "-"  "dh" "p" "o" "-" "-" "o" "p" "dh" "-"  "s"; #so on
      "g"  "bt" "dk" "p" "-" "-" "-" "-" "p" "dk" "bt" "g";
      "k"  "kr" "ln" "p" "-" "-" "-" "-" "p" "q"  "ph" "de";
      "de" "ph" "q"  "p" "-" "-" "-" "-" "p" "ln" "kr" "k";
      "g"  "bt" "dk" "p" "-" "-" "-" "-" "p" "dk" "bt" "g";
      "s"  "-"  "dh" "p" "o" "-" "-" "o" "p" "dh" "-"  "s";
      "c"  "b"  "r"  "p" "-" "-" "-" "-" "p" "r"  "b"  "c";
      "fl" "-"  "vm" "p" "-" "-" "-" "-" "p" "vm" "-"  "fl";
      "l"  "rc" "sm" "p" "-" "-" "-" "-" "p" "sm" "rc" "l";
      ]
      for i = 1:BOARD_DIMENSIONS
        for j = 1:BOARD_DIMENSIONS
          boardArray[i,j].name = pieceNames[i,j]

          #color every piece
          if j<=5 && !isNullPiece(boardArray[i,j])
            boardArray[i,j].color = WHITE
          elseif j>=8 && !isNullPiece(boardArray[i,j])
            boardArray[i,j].color = BLACK
          end
        end
      end
    elseif gameType == "ten"
      # pieceNames = [
      # "lance" "reverse_chariot" "side_soldier" "side_mover" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "side_mover" "side_soldier" "reverse_chariot" "lance";
      # "knight" "-" "vertical_soldier" "vertical_mover" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "vertical_mover" "vertical_soldier" "-" "knight";
      # "ferocious_leopard" "chariot_soldier" "bishop" "rook" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "rook" "bishop" "chariot_soldier" "ferocious_leopard";
      # "iron_general" "chariot_soldier" "dragon_horse" "horned_falcon" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "horned_falcon" "dragon_horse" "chariot_soldier" "iron_general";
      # "copper_general" "-" "dragon_king" "soaring_eagle" "pawn" "dog" "-" "-" "-" "-" "dog" "pawn" "soaring_eagle" "dragon_king" "-" "copper_general";
      # "silver_general" "blind_tiger" "WB" "bishop_general" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "bishop_general" "WB" "blind_tiger" "silver_general";
      # "gold_general" "kirin" "fire_demon" "rook_general" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "rook_general" "fire_demon" "phoenix" "gold_general";
      # "king" "lion" "lion_hawk" "great_general" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "vice_general" "free_eagle" "queen" "drunken_elephant";
      # "drunken_elephant" "queen" "free_eagle" "vice_general" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "great_general" "lion_hawk" "lion" "king";
      # "gold_general" "phoenix" "fire_demon" "rook_general" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "rook_general" "fire_demon" "kirin" "gold_general";
      # "silver_general" "blind_tiger" "water_buffalo" "bishop_general" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "bishop_general" "water_buffalo" "blind_tiger" "silver_general";
      # "copper_general" "-" "dragon_king" "soaring_eagle" "pawn" "dog" "-" "-" "-" "-" "dog" "pawn" "soaring_eagle" "dragon_king" "-" "copper_general";
      # "iron_general" "chariot_soldier" "dragon_horse" "horned_falcon" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "horned_falcon" "dragon_horse" "chariot_soldier" "iron_general";
      # "ferocious_leopard" "chariot_soldier" "bishop" "rook" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "rook" "bishop" "chariot_soldier" "ferocious_leopard";
      # "knight" "-" "vertical_soldier" "vertical_mover" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "vertical_mover" "vertical_soldier" "-" "knight";
      # "lance" "reverse_chariot" "side_soldier" "side_mover" "pawn" "-" "-" "-" "-" "-" "-" "pawn" "side_mover" "side_soldier" "reverse_chariot" "lance";
      # ]

      pieceNames = [
      "l"  "rc" "ss" "sm" "p" "-" "-" "-" "-" "-" "-" "p" "sm" "ss" "rc" "l";
      "n"  "-"  "vs" "vm" "p" "-" "-" "-" "-" "-" "-" "p" "vm" "vs" "-"  "n";
      "fl" "cs" "b"  "r"  "p" "-" "-" "-" "-" "-" "-" "p" "r"  "b"  "cs" "fl";
      "i"  "cs" "dh" "hf" "p" "-" "-" "-" "-" "-" "-" "p" "hf" "dh" "cs" "i";
      "c"  "-"  "dk" "se" "p" "d" "-" "-" "-" "-" "d" "p" "se" "dk" "-"  "c";
      "s"  "bt" "wb" "bg" "p" "-" "-" "-" "-" "-" "-" "p" "bg" "wb" "bt" "s";
      "g"  "kr" "fd" "rg" "p" "-" "-" "-" "-" "-" "-" "p" "rg" "fd" "ph" "g";
      "k"  "ln" "lh" "gg" "p" "-" "-" "-" "-" "-" "-" "p" "vg" "fe" "q"  "de";
      "de" "q"  "fe" "vg" "p" "-" "-" "-" "-" "-" "-" "p" "gg" "lh" "ln" "k";
      "g"  "ph" "fd" "rg" "p" "-" "-" "-" "-" "-" "-" "p" "rg" "fd" "kr" "g";
      "s"  "bt" "wb" "bg" "p" "-" "-" "-" "-" "-" "-" "p" "bg" "wb" "bt" "s";
      "c"  "-"  "dk" "se" "p" "d" "-" "-" "-" "-" "d" "p" "se" "dk" "-"  "c";
      "i"  "cs" "dh" "hf" "p" "-" "-" "-" "-" "-" "-" "p" "hf" "dh" "cs" "i";
      "fl" "cs" "b"  "r"  "p" "-" "-" "-" "-" "-" "-" "p" "r"  "b"  "cs" "fl";
      "n"  "-"  "vs" "vm" "p" "-" "-" "-" "-" "-" "-" "p" "vm" "vs" "-"  "n";
      "l"  "rc" "ss" "sm" "p" "-" "-" "-" "-" "-" "-" "p" "sm" "ss" "rc" "l";
      ]
      for i = 1:BOARD_DIMENSIONS
        for j = 1:BOARD_DIMENSIONS
          boardArray[i,j].name = pieceNames[i,j]

          #color every piece
          if j<=6 && !isNullPiece(boardArray[i,j])
            boardArray[i,j].color = WHITE
          elseif j>=11 && !isNullPiece(boardArray[i,j])
            boardArray[i,j].color = BLACK
          end
        end
      end
    else
      assert(false)
    end
  return boardArray
end

function initBoard()
  return Board(initBoardArray(), 1, "",  initHand(), initHand())
end

function initBoardArray()
  initialBoardArray = Array{Piece}(BOARD_DIMENSIONS, BOARD_DIMENSIONS) #EMPTY
  initialBoardArray = emptyBoardArray(initialBoardArray)
  return fillInitialBoardArray(initialBoardArray)
end

function initHand()
  return Array{Piece}(0)
end

function addToHand(board, player::AbstractString, piece::Piece)
  if player == WHITE || player == BLACK
    push!( handForPlayer(board, player), piece )
  else
    assert(false)
  end
end

function handForPlayer(board::Board, color::AbstractString)
  if color == WHITE
    return board.whiteHand
  elseif  color == BLACK
    return board.blackHand
  else
    assert(false)
  end
end
