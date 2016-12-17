#=
Legal_moves helper function
=#

#Movement helpers
function moveForwards(legal::Array{Move}, board::Board, piece::Piece, sourcex::Int, sourcey::Int, canPromote::Bool)
  if piece.color == WHITE
    moveN(legal, board, piece, sourcex, sourcey, canPromote)
  elseif piece.color == BLACK
    moveS(legal, board, piece, sourcex, sourcey, canPromote)
  else
    assert(false)
  end
end

function moveBackwards(legal::Array{Move}, board::Board, piece::Piece, sourcex::Int, sourcey::Int, canPromote::Bool)
  if piece.color == WHITE
    return moveS(legal, board, piece, sourcex, sourcey, canPromote)
  elseif piece.color == BLACK
    return moveN(legal, board, piece, sourcex, sourcey, canPromote)
  else
    assert(false)
  end
end

function moveN(legal::Array{Move}, board::Board, piece::Piece, sourcex::Int, sourcey::Int, canPromote::Bool)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex, sourcey+1, canPromote)
end

function moveNE(legal::Array{Move}, board::Board, piece::Piece, sourcex::Int, sourcey::Int, canPromote::Bool)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex+1, sourcey+1, canPromote)
end

function moveE(legal::Array{Move}, board::Board, piece::Piece, sourcex::Int, sourcey::Int, canPromote::Bool)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex+1, sourcey, canPromote)
end

function moveSE(legal::Array{Move}, board::Board, piece::Piece, sourcex::Int, sourcey::Int, canPromote::Bool)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex+1, sourcey-1, canPromote)
end

function moveS(legal::Array{Move}, board::Board, piece::Piece, sourcex::Int, sourcey::Int, canPromote::Bool)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex, sourcey-1, canPromote)
end

function moveSW(legal::Array{Move}, board::Board, piece::Piece, sourcex::Int, sourcey::Int, canPromote::Bool)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex-1, sourcey-1, canPromote)
end

function moveW(legal::Array{Move}, board::Board, piece::Piece, sourcex::Int, sourcey::Int, canPromote::Bool)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex-1, sourcey, canPromote)
end

function moveNW(legal::Array{Move}, board::Board, piece::Piece, sourcex::Int, sourcey::Int, canPromote::Bool)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex-1, sourcey+1, canPromote)
end

function chainMovement(legal::Array{Move}, board::Board, piece::Piece, movement::Function, sourcex::Int, sourcey::Int, canPromote::Bool)
  newLegal = Array{Move}(0)

  movement(newLegal, board, piece, sourcex, sourcey, canPromote)
  if length(newLegal) != 0
    append!(legal, newLegal)
  end
  while length(newLegal) != 0  && isNullPiece(getPiece(board, newLegal[end].targetx, newLegal[end].targety)) #stop when the movement hits an obstruction, or when it moves onto an enemy
    newX::Int = newLegal[end].targetx
    newY::Int = newLegal[end].targety

    newLegal = Array{Move}(0)
    movement(newLegal, board, piece, newX, newY, canPromote)
    if length(newLegal) != 0
      newLegal[1].sourcex = sourcex
      newLegal[1].sourcey = sourcey #CHANGE THE sourcex AND sourcey TO CORRECT START LOCATION
      append!(legal, newLegal)
    end
  end
end

#for Tenjiku Shogi
#noJump is an array of the names of pieces that can't be jumped past
function rangeJump(legal::Array{Move}, board::Board, piece::Piece, movement::Function, sourcex::Int, sourcey::Int, noJump::Array{ASCIIString}, canPromote::Bool)
  newLegal = Array{Move}(0)
  chainMovement(newLegal, board, piece, movement, sourcex, sourcey, canPromote) #legal list of regular chain movement, ending on obstruction

  if movement == moveN
    xMod = 0
    yMod = 1
  elseif movement == moveNE
    xMod = 1
    yMod = 1
  elseif movement == moveE
    xMod = 1
    yMod = 0
  elseif movement == moveSE
    xMod = 1
    yMod = -1
  elseif movement == moveS
    xMod = 0
    yMod = -1
  elseif movement == moveSW
    xMod = -1
    yMod = -1
  elseif movement == moveW
    xMod = -1
    yMod = 0
  elseif movement == moveNW
    xMod = -1
    yMod = 1
  end

  if length(newLegal) > 0
    newX = newLegal[end].targetx
    newY = newLegal[end].targety
  else
    newX = sourcex+xMod
    newY = sourcey+yMod
  end


  while newX+xMod >= 1 && newY+yMod >= 1 && newX+xMod <= BOARD_DIMENSIONS && newY+yMod <= BOARD_DIMENSIONS && !(getPiece(board, newX, newY).name in noJump)
                                    #stop when the movement hits a piece with equal or higher rank, or when the movement hits the edge of the board

    newX = newX+xMod
    newY = newY+yMod

    #Can't land on a King, Prince, or empty space when range jumping
    if getPiece(board, newX, newY).name != King && getPiece(board, newX, newY).name != PDrunkenElephant && !isNullPiece(getPiece(board, newX, newY))
      tryToEnter(newLegal, board, piece, sourcex, sourcey, newX, newY, canPromote)
    end
  end
  append!(legal, newLegal)
end

#for Chu Shogi
function doubleMove(legal::Array{Move}, board::Board, piece::Piece, sourcex::Int, sourcey::Int,  move1::Function, move2::Function, canPromote::Bool)
  firstLegal = Array{Move}(0)
  secondLegal = Array{Move}(0)
  move1(firstLegal, board, piece, sourcex, sourcey, canPromote)
  if length(firstLegal) != 0
    if isNullPiece(getPiece(board, firstLegal[end].targetx, firstLegal[end].targety)) || piece.name == Lion || piece.name == HornedFalcon || piece.name == SoaringEagle || piece.name == PDragonHorse #=Horned Falcon=# || piece.name == PDragonKing #=Soaring Eagle=# || piece.name == PLion #=Lion Hawk=#
                                 #cannot make the second move after capturing, unless the moving piece is a lion, horned falcon, soaring eagle, free eagle, or lion hawk

      #create a deep copy of the board, simulating the first move so that igui is possible
      tempBoard = deepcopy(board)
      updateBoard(tempBoard, firstLegal[1])
      move2(secondLegal, tempBoard, piece, firstLegal[end].targetx, firstLegal[end].targety, canPromote)
      #= firstLegal and secondLegal will either have 0, 1 or 2 elements; 0 if there is no legal space to move in, 1 if there is, and 2 if that space is
      a promotion zone (one for moving and promoting, and one for just moving. The move with a promote will be the 2nd element) =#

      if length(secondLegal) != 0 #first and second moves are legal
        lastMove = secondLegal[end]

        newMove = initMoveDoubleMovement(sourcex, sourcey, lastMove.sourcex, lastMove.sourcey, nothing, lastMove.targetx, lastMove.targety) #legal to move in
        push!(legal, newMove) #Legal to double move

        if (piece.color == WHITE && lastMove.targety >= PROMOTION_TOP) || (piece.color == BLACK && lastMove.targety <= PROMOTION_BOTTOM)#if target square is in the promotionzone for the piece moving in
          if canPromote
            newMove = initMoveDoubleMovement(sourcex, sourcey, lastMove.sourcex, lastMove.sourcey, "!", lastMove.targetx, lastMove.targety)
            push!(legal, newMove) #legal to double move and promote
          end
        end
      end
    end
  end
end


#for Tenjiku Shogi
function tripleMove(legal::Array{Move}, board::Board, piece::Piece, sourcex::Int, sourcey::Int,  move1::Function, move2::Function, move3::Function, canPromote::Bool)
  firstLegal = Array{Move}(0)
  secondLegal = Array{Move}(0)
  thirdLegal = Array{Move}(0)
  move1(firstLegal, board, piece, sourcex, sourcey, canPromote)
  if length(firstLegal) != 0
    firstMove = firstLegal[end]
    if isNullPiece(getPiece(board, firstMove.targetx, firstMove.targety)) #Piece must stop moving if it captures, only continue if the target square is empty
      ##simulating the first move, so that the board is updated for the second move
      tempBoard = deepcopy(board)
      updateBoard(tempBoard, firstLegal[1])
      move2(secondLegal, tempBoard, piece, firstMove.targetx, firstMove.targety, canPromote)
      #= firstLegal and secondLegal will either have 0, 1 or 2 elements; 0 if there is no legal space to move in, 1 if there is, and 2 if that space is
      a promotion zone (one for moving and promoting, and one for just moving. The move with a promote will be the 2nd element) =#

      if length(secondLegal) != 0 #first and second moves are legal
        secondMove = secondLegal[end]
        if isNullPiece(getPiece(board, secondMove.targetx, secondMove.targety)) #Piece must stop moving if it captures, only continue if the target square is empty

          updateBoard(tempBoard, secondLegal[1])
          move3(thirdLegal, tempBoard, piece, secondLegal[end].targetx, secondLegal[end].targety, canPromote)

          if length(thirdLegal) != 0
            lastMove = thirdLegal[end]

            newMove = initMoveTripleMovement(sourcex, sourcey, secondMove.sourcex, secondMove.sourcey, nothing, lastMove.sourcex, lastMove.sourcey, lastMove.targetx, lastMove.targety) #legal to move in
            push!(legal, newMove)
            #Pieces that triple move can't promote - Vice General, Fire Demon
          end
        end
      end
    end
  end
end

#covers movement entrance, not drops
function tryToEnter(legal::Array{Move}, board::Board, piece::Piece, sourcex::Int, sourcey::Int, targetx::Int, targety::Int, canPromote::Bool)
  if targetx >= 1 && targety >= 1 && targetx <= BOARD_DIMENSIONS && targety <= BOARD_DIMENSIONS #if target in bounds
    occupyingPiece = getPiece(board, targetx, targety)

    if isNullPiece(occupyingPiece) || occupyingPiece.color != piece.color #target square is empty, or enemy colored piece
      newMove = initMoveMovement(sourcex, sourcey, targetx, targety, nothing)
      push!(legal, newMove) #legal to just move in

      if (piece.color == WHITE && targety >= PROMOTION_TOP) || (piece.color == BLACK && targety <= PROMOTION_BOTTOM)#if target square is in the promotionzone for the piece moving in
        if canPromote
          newMove = initMoveMovement(sourcex, sourcey, targetx, targety, "!")
          push!(legal, newMove) #legal to move in and promote
        end
      end
    end
  end
end


#Goes through all squares on the board and compiles the legal moves possible from that space. Includes resign as the last item
function allLegalMoves(board::Board)
  legal = Array{Move}(0)
  #TODO, this should use allLegalMovementMoves
  for x in 1:BOARD_DIMENSIONS
    for y in 1:BOARD_DIMENSIONS
      append!(legal, legalMovesForSpace(board, x, y))
    end
  end
  currentHand = handForPlayer(board, getCurrentPlayer(board))
  #chu shogi and ten shogi dont have drops
  if gameType != "chu" && gameType != "ten"
    for piece in currentHand
      legalDrops(legal, board, piece)
    end
  end

  push!(legal, initMoveResign() )

  return legal
end


function allLegalMovementMoves(board::Board)
  legal = Array{Move}(0)
  for x in 1:BOARD_DIMENSIONS
    for y in 1:BOARD_DIMENSIONS
      append!(legal, legalMovesForSpace(board, x, y))
    end
  end
  return legal
end


#Legal drops for a single piece
function legalDrops(legal::Array{Move}, board::Board, piece::Piece)
  for x in 1:BOARD_DIMENSIONS
    for y in 1:BOARD_DIMENSIONS
      if isNullPiece(getPiece(board, x, y)) #target square is empty
        newMove = initMoveDrop(x, y, piece)
        push!(legal, newMove)  #legal to drop the piece there
      end
    end
  end
end


#Returns a list of legal moves that don't put in check. Includes resign as the last item.
function allLegalNotStupidMoves(board::Board)
  allMoves = allLegalMoves(board)
  notStupidMoves = Array{Move}(0)

  tempKingPiece = Piece( getCurrentPlayer(board), King )
  defaultKingX, defaultKingY = findPiece(board, tempKingPiece)

  for i in 1:length(allMoves)-1 #all but resign
    if allMoves[i].move_type == MOVETYPE_MOVEMENT
      ####Check that you aren't moving into check, you stupid ai
      #Make a simulation of the board after moving
      tempBoard = deepcopy(board)
      updateBoard(tempBoard, allMoves[i])

      #find the king's coordinates
      if getPiece(tempBoard, allMoves[i].sourcex, allMoves[i].sourcey).name != King #If the king moved, get its new location
        kingX, kingY = findPiece(tempBoard, tempKingPiece)
      else #King hasn't moved, use default location.
        kingX = defaultKingX
        kingY = defaultKingY
      end
      if !isPieceInCheck(tempBoard, kingX, kingY)
        push!(notStupidMoves, allMoves[i])
      end

    else #It's not a move so it can't be bad
      push!(notStupidMoves, allMoves[i])
    end
  end

  push!(notStupidMoves, allMoves[end]) #add resign too. Gotta have that even when its in check.

  return notStupidMoves
end


function popResignIfOtherOptions(movesList)
  if length(movesList) > 1
    pop!(movesList)
  end
end





#=
  Loops through all figures and calls the function which passes
  figureType, current Location, and a boolean which is set to true if
  it is our turn to make a move or false if it is the oppontents turn
  return set of legal moves for that figure
=#
###Legal moves
function legalMovesForSpace(board::Board, sourcex::Int, sourcey::Int)
  piece = getPiece(board, sourcex, sourcey)
  if piece.color == getCurrentPlayer(board)
    if gameType == "standard" || gameType == "minishogi"
      legalMovesStandard(board, piece, sourcex, sourcey)
    elseif gameType == "chu"
      legalMovesChu(board, piece, sourcex, sourcey)
    elseif gameType == "ten"
      legalMovesTen(board, piece, sourcex, sourcey)
    end
  else
    return []
  end
end

function  legalMovesStandard(board::Board, piece::Piece, sourcex::Int, sourcey::Int)
  if piece.name == King                             #King
    return legalKing(board, sourcex, sourcey, false)
  elseif piece.name == Pawn                         #Pawn
    return legalPawn(board, sourcex, sourcey, true)
  elseif piece.name == PPawn                        #Promoted Pawn
    return legalGold(board, sourcex, sourcey, false)
  elseif piece.name == GoldGeneral                  #Gold General
    return legalGold(board, sourcex, sourcey, false)
  elseif piece.name == SilverGeneral                #Silver General
    return legalSilver(board, sourcex, sourcey, true)
  elseif piece.name == PSilverGeneral               #Promoted Silver General
    return legalGold(board, sourcex, sourcey, false)
  elseif piece.name == Bishop                       #Bishop
    return legalBishop(board, sourcex, sourcey, true)
  elseif piece.name == PBishop                      #Promoted Bishop
    return legalDragonHorse(board, sourcex, sourcey, false)
  elseif piece.name == Rook                         #Rook
    return legalRook(board, sourcex, sourcey, true)
  elseif piece.name == PRook                        #Promoted Rook
    return legalDragonKing(board, sourcex, sourcey, false)
  elseif piece.name == Lance                        #Lance
    return legalLance(board, sourcex, sourcey, true)
  elseif piece.name == PLance                       #Promoted Lance
    return legalGold(board, sourcex, sourcey, false)
  elseif piece.name == Knight                       #Knight
    return legalKnight(board, sourcex, sourcey, true)
  elseif piece.name == PKnight                      #Promoted Knight
    return legalGold(board, sourcex, sourcey, false)
  else
    tracePrint(piece.name)
    assert( isNullPiece(piece) )
  end
end

function  legalMovesChu(board::Board, piece::Piece, sourcex::Int, sourcey::Int)
  if piece.name == King                             #King
    return legalKing(board, sourcex, sourcey, false)
  elseif piece.name == Pawn                         #Pawn
    return legalPawn(board, sourcex, sourcey, true)
  elseif piece.name == PPawn                        #Promoted Pawn
    return legalGold(board, sourcex, sourcey, false)
  elseif piece.name == GoldGeneral                  #Gold General
    return legalGold(board, sourcex, sourcey, true)
  elseif piece.name == PGoldGeneral                 #Promoted Gold General
    return legalRook(board, sourcex, sourcey, false)
  elseif piece.name == SilverGeneral                #Silver General
    return legalSilver(board, sourcex, sourcey, true)
  elseif piece.name == PSilverGeneral               #Promoted Silver General
    return legalVerticalMover(board, sourcex, sourcey, false)
  elseif piece.name == Bishop                       #Bishop
    return legalBishop(board, sourcex, sourcey, true)
  elseif piece.name == PBishop                      #Promoted Bishop
    return legalDragonHorse(board, sourcex, sourcey, false)
  elseif piece.name == Rook                         #Rook
    return legalRook(board, sourcex, sourcey, true)
  elseif piece.name == PRook                        #Promoted Rook
    return legalDragonKing(board, sourcex, sourcey, false)
  elseif piece.name == Lance                        #Lance
    return legalLance(board, sourcex, sourcey, true)
  elseif piece.name == PLance                       #Promoted Lance
    return legalWhiteHorse(board, sourcex, sourcey, false)
  elseif piece.name == ReverseChariot               #Reverse Chariot
    return legalChariot(board, sourcex, sourcey, true)
  elseif piece.name == PReverseChariot              #Promoted Reverse Chariot
    return legalWhale(board, sourcex, sourcey, false)
  elseif piece.name == CopperGeneral                #Copper General
    return legalCopper(board, sourcex, sourcey, true)
  elseif piece.name == PCopperGeneral               #Promoted Copper General
    return legalSideMover(board, sourcex, sourcey, false)
  elseif piece.name == DragonKing                   #Dragon King
    return legalDragonKing(board, sourcex, sourcey, true)
  elseif piece.name == PDragonKing                  #Promoted Dragon King
    return legalSoaringEagle(board, sourcex, sourcey, false)
  elseif piece.name == DrunkenElephant              #Drunken Elephant
    return legalElephant(board, sourcex, sourcey, true)
  elseif piece.name == PDrunkenElephant             #Promoted Drunken Elephant
    return legalKing(board, sourcex, sourcey, false)
  elseif piece.name == FerociousLeopard             #Ferocious Leopard
    return legalLeopard(board, sourcex, sourcey, true)
  elseif piece.name == PFerociousLeopard            #Promoted Ferocious Leopard
    return legalBishop(board, sourcex, sourcey, false)
  elseif piece.name == DragonHorse                  #Dragon Horse
    return legalDragonHorse(board, sourcex, sourcey, true)
  elseif piece.name == PDragonHorse                 #Promoted Dragon Horse
    return legalFalcon(board, sourcex, sourcey, false)
  elseif piece.name == Lion                         #Lion
    return legalLion(board, sourcex, sourcey, false)
  elseif piece.name == SideMover                    #Side Mover
    return legalSideMover(board, sourcex, sourcey, true)
  elseif piece.name == PSideMover                   #Promoted Side Mover
    return legalBoar(board, sourcex, sourcey, false)
  elseif piece.name == Kirin                        #Kirin
    return legalKirin(board, sourcex, sourcey, true)
  elseif piece.name == PKirin                       #Promoted Kirin
    return legalLion(board, sourcex, sourcey, false)
  elseif piece.name == GoBetween                    #Go-Between
    return legalGoBetween(board, sourcex, sourcey, true)
  elseif piece.name == PGoBetween                   #Promoted Go-Between
    return legalElephant(board, sourcex, sourcey, false)
  elseif piece.name == BlindTiger                   #Blind Tiger
    return legalTiger(board, sourcex, sourcey, true)
  elseif piece.name == PBlindTiger                  #Promoted Blind Tiger
    return legalStag(board, sourcex, sourcey, false)
  elseif piece.name == Queen                        #Queen
    return legalQueen(board, sourcex, sourcey, false)
  elseif piece.name == VerticalMover                #Vertical Mover
    return legalVerticalMover(board, sourcex, sourcey, true)
  elseif piece.name == PVerticalMover               #Promoted Vertical Mover
    return legalOx(board, sourcex, sourcey, false)
  elseif piece.name == Phoenix                      #Phoenix
    return legalPhoenix(board, sourcex, sourcey, true)
  elseif piece.name == PPhoenix                     #Promoted Phoenix
    return legalQueen(board, sourcex, sourcey, false)
  else
    tracePrint(piece.name)
    assert( isNullPiece(piece) )
  end
end

function  legalMovesTen(board::Board, piece::Piece, sourcex::Int, sourcey::Int)
  if piece.name == King                             #King
    return legalKing(board, sourcex, sourcey, false)
  elseif piece.name == Pawn                         #Pawn
    return legalPawn(board, sourcex, sourcey, true)
  elseif piece.name == PPawn                        #Promoted Pawn
    return legalGold(board, sourcex, sourcey, false)
  elseif piece.name == Knight                       #Knight
    return legalKnight(board, sourcex, sourcey, true)
  elseif piece.name == PKnight                      #Promoted Knight
    return legalSideSoldier(board, sourcex, sourcey, false)
  elseif piece.name == GoldGeneral                  #Gold General
    return legalGold(board, sourcex, sourcey, true)
  elseif piece.name == PGoldGeneral                 #Promoted Gold General
    return legalRook(board, sourcex, sourcey, false)
  elseif piece.name == SilverGeneral                #Silver General
    return legalSilver(board, sourcex, sourcey, true)
  elseif piece.name == PSilverGeneral               #Promoted Silver General
    return legalVerticalMover(board, sourcex, sourcey, false)
  elseif piece.name == Bishop                       #Bishop
    return legalBishop(board, sourcex, sourcey, true)
  elseif piece.name == PBishop                      #Promoted Bishop
    return legalDragonHorse(board, sourcex, sourcey, false)
  elseif piece.name == Rook                         #Rook
    return legalRook(board, sourcex, sourcey, true)
  elseif piece.name == PRook                        #Promoted Rook
    return legalDragonKing(board, sourcex, sourcey, false)
  elseif piece.name == Lance                        #Lance
    return legalLance(board, sourcex, sourcey, true)
  elseif piece.name == PLance                       #Promoted Lance
    return legalWhiteHorse(board, sourcex, sourcey, false)
  elseif piece.name == ReverseChariot               #Reverse Chariot
    return legalChariot(board, sourcex, sourcey, true)
  elseif piece.name == PReverseChariot              #Promoted Reverse Chariot
    return legalWhale(board, sourcex, sourcey, false)
  elseif piece.name == CopperGeneral                #Copper General
    return legalCopper(board, sourcex, sourcey, true)
  elseif piece.name == PCopperGeneral               #Promoted Copper General
    return legalSideMover(board, sourcex, sourcey, false)
  elseif piece.name == DragonKing                   #Dragon King
    return legalDragonKing(board, sourcex, sourcey, true)
  elseif piece.name == PDragonKing                  #Promoted Dragon King
    return legalSoaringEagle(board, sourcex, sourcey, false)
  elseif piece.name == DrunkenElephant              #Drunken Elephant
    return legalElephant(board, sourcex, sourcey, true)
  elseif piece.name == PDrunkenElephant             #Promoted Drunken Elephant
    return legalKing(board, sourcex, sourcey, false)
  elseif piece.name == FerociousLeopard             #Ferocious Leopard
    return legalLeopard(board, sourcex, sourcey, true)
  elseif piece.name == PFerociousLeopard            #Promoted Ferocious Leopard
    return legalBishop(board, sourcex, sourcey, false)
  elseif piece.name == DragonHorse                  #Dragon Horse
    return legalDragonHorse(board, sourcex, sourcey, true)
  elseif piece.name == PDragonHorse                 #Promoted Dragon Horse
    return legalFalcon(board, sourcex, sourcey, false)
  elseif piece.name == Lion                         #Lion
    return legalLion(board, sourcex, sourcey, true)
  elseif piece.name == PLion                        #Promoted Lion
    return legalLionHawk(board, sourcex, sourcey, false)
  elseif piece.name == SideMover                    #Side Mover
    return legalSideMover(board, sourcex, sourcey, true)
  elseif piece.name == PSideMover                   #Promoted Side Mover
    return legalBoar(board, sourcex, sourcey, false)
  elseif piece.name == Kirin                        #Kirin
    return legalKirin(board, sourcex, sourcey, true)
  elseif piece.name == PKirin                       #Promoted Kirin
    return legalLion(board, sourcex, sourcey, false)
  elseif piece.name == BlindTiger                   #Blind Tiger
    return legalTiger(board, sourcex, sourcey, true)
  elseif piece.name == PBlindTiger                  #Promoted Blind Tiger
    return legalStag(board, sourcex, sourcey, false)
  elseif piece.name == Queen                        #Queen
    return legalQueen(board, sourcex, sourcey, true)
  elseif piece.name == PQueen                       #Promoted Queen
    return legalFreeEagle(board, sourcex, sourcey, false)
  elseif piece.name == VerticalMover                #Vertical Mover
    return legalVerticalMover(board, sourcex, sourcey, true)
  elseif piece.name == PVerticalMover               #Promoted Vertical Mover
    return legalOx(board, sourcex, sourcey, false)
  elseif piece.name == Phoenix                      #Phoenix
    return legalPhoenix(board, sourcex, sourcey, true)
  elseif piece.name == PPhoenix                     #Promoted Phoenix
    return legalQueen(board, sourcex, sourcey, false)
  elseif piece.name == BishopGeneral                #Bishop General
    return legalBishopGeneral(board, sourcex, sourcey, true)
  elseif piece.name == PBishopGeneral               #Promoted Bishop General
    return legalViceGeneral(board, sourcex, sourcey, false)
  elseif piece.name == ChariotSoldier               #Chariot Soldier
    return legalChariotSoldier(board, sourcex, sourcey, true)
  elseif piece.name == PChariotSoldier              #Promoted Chariot Soldier
    return legalHeavenlyTetrarch(board, sourcex, sourcey, false)
  elseif piece.name == Dog                          #Dog
    return legalDog(board, sourcex, sourcey, true)
  elseif piece.name == PDog                         #Promoted Dog
    return legalMultiGeneral(board, sourcex, sourcey, false)
  elseif piece.name == FireDemon                    #Fire Demon
    return legalFireDemon(board, sourcex, sourcey, false)
  elseif piece.name == FreeEagle                    #Free Eagle
    return legalFreeEagle(board, sourcex, sourcey, false)
  elseif piece.name == GreatGeneral                 #Great General
    return legalGreatGeneral(board, sourcex, sourcey, false)
  elseif piece.name == HornedFalcon                 #Horned Falcon
    return legalFalcon(board, sourcex, sourcey, false)
  elseif piece.name == PHornedFalcon                #Promoted Horned Falcon
    return legalBishop(board, sourcex, sourcey, false)
  elseif piece.name == IronGeneral                  #Iron General
    return legalIronGeneral(board, sourcex, sourcey, true)
  elseif piece.name == PIronGeneral                 #Promoted Iron General
    return legalVerticalSoldier(board, sourcex, sourcey, false)
  elseif piece.name == LionHawk                     #Lion Hawk
    return legalLionHawk(board, sourcex, sourcey, false)
  elseif piece.name == RookGeneral                  #Rook General
    return legalRookGeneral(board, sourcex, sourcey, true)
  elseif piece.name == PRookGeneral                 #Promoted Rook General
    return legalGreatGeneral(board, sourcex, sourcey, false)
  elseif piece.name == SideSoldier                  #Side Soldier
    return legalSideSoldier(board, sourcex, sourcey, true)
  elseif piece.name == PSideSoldier                 #Promoted Side Soldier
    return legalWaterBuffalo(board, sourcex, sourcey, false)
  elseif piece.name == SoaringEagle                 #Soaring Eagle
    return legalSoaringEagle(board, sourcex, sourcey, true)
  elseif piece.name == PSoaringEagle                #Promoted Soaring Eagle
    return legalRookGeneral(board, sourcex, sourcey, false)
  elseif piece.name == VerticalSoldier              #Vertical Soldier
    return legalVerticalSoldier(board, sourcex, sourcey, true)
  elseif piece.name == PVerticalSoldier             #Promoted Vertical SOldier
    return legalChariotSoldier(board, sourcex, sourcey, false)
  elseif piece.name == ViceGeneral                  #Vice General
    return legalViceGeneral(board, sourcex, sourcey, false)
  elseif piece.name == WaterBuffalo                 #Water Buffalo
    return legalWaterBuffalo(board, sourcex, sourcey, true)
  elseif piece.name == PWaterBuffalo                #Promoted Water Buffalo
    return legalFireDemon(board, sourcex, sourcey, false)
  else
    tracePrint(piece.name)
    assert( isNullPiece(piece) )
  end
end

function legalKing(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  moveN(legal, board, piece, sourcex, sourcey, canPromote)
  moveNE(legal, board, piece, sourcex, sourcey, canPromote)
  moveE(legal, board, piece, sourcex, sourcey, canPromote)
  moveSE(legal, board, piece, sourcex, sourcey, canPromote)
  moveS(legal, board, piece, sourcex, sourcey, canPromote)
  moveSW(legal, board, piece, sourcex, sourcey, canPromote)
  moveW(legal, board, piece, sourcex, sourcey, canPromote)
  moveNW(legal, board, piece, sourcex, sourcey, canPromote)
  tracePrint( ("King", legal), "legal")
  return legal
end

function legalKnight(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  if piece.color == WHITE
    tryToEnter(legal, board, piece, sourcex, sourcey, sourcex-1, sourcey+2, canPromote)
    tryToEnter(legal, board, piece, sourcex, sourcey, sourcex+1, sourcey+2, canPromote)
  elseif piece.color == BLACK
    tryToEnter(legal, board, piece, sourcex, sourcey, sourcex-1, sourcey-2, canPromote)
    tryToEnter(legal, board, piece, sourcex, sourcey, sourcex+1, sourcey-2, canPromote)
  end
  tracePrint( ("Knight", legal), "legal")
  return legal
end

function legalPawn(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  moveForwards(legal, board, piece, sourcex, sourcey, canPromote)
  tracePrint( ("Pawn", legal), "legal")
  return legal
end

function legalGold(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  moveN(legal, board, piece, sourcex, sourcey, canPromote)
  moveS(legal, board, piece, sourcex, sourcey, canPromote)
  moveW(legal, board, piece, sourcex, sourcey, canPromote)
  moveE(legal, board, piece, sourcex, sourcey, canPromote)
  if piece.color == WHITE
    moveNW(legal, board, piece, sourcex, sourcey, canPromote)
    moveNE(legal, board, piece, sourcex, sourcey, canPromote)
  elseif piece.color == BLACK
    moveSW(legal, board, piece, sourcex, sourcey, canPromote)
    moveSE(legal, board, piece, sourcex, sourcey, canPromote)
  else
    assert(false)
  end
  tracePrint( ("Gold", legal), "legal")
  return legal
end

function legalSilver(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  moveForwards(legal, board, piece, sourcex, sourcey, canPromote)
  moveNW(legal, board, piece, sourcex, sourcey, canPromote)
  moveNE(legal, board, piece, sourcex, sourcey, canPromote)
  moveSW(legal, board, piece, sourcex, sourcey, canPromote)
  moveSE(legal, board, piece, sourcex, sourcey, canPromote)
  tracePrint( ("Silver", legal), "legal")
  return legal
end

function legalLance(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  chainMovement(legal, board, piece, moveForwards, sourcex, sourcey, canPromote)
  tracePrint( ("Lance", legal), "legal")
  return legal
end

function legalBishop(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)
  tracePrint( ("Bishop", legal), "legal")
  return legal
end

function legalDragonHorse(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)

  moveN(legal, board, piece, sourcex, sourcey, canPromote)
  moveW(legal, board, piece, sourcex, sourcey, canPromote)
  moveE(legal, board, piece, sourcex, sourcey, canPromote)
  moveS(legal, board, piece, sourcex, sourcey, canPromote)
  tracePrint( ("PBishop", legal), "legal")
  return legal
end

function legalRook(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  chainMovement(legal, board, piece, moveN, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveS, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveW, sourcex, sourcey, canPromote)
  tracePrint( ("Rook", legal), "legal")
  return legal
end

function legalDragonKing(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  chainMovement(legal, board, piece, moveN, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveS, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveW, sourcex, sourcey, canPromote)

  moveNE(legal, board, piece, sourcex, sourcey, canPromote)
  moveSE(legal, board, piece, sourcex, sourcey, canPromote)
  moveSW(legal, board, piece, sourcex, sourcey, canPromote)
  moveNW(legal, board, piece, sourcex, sourcey, canPromote)
  tracePrint( ("PRook", legal), "legal")
  return legal
end

######CHU SHOGI MOVES
function legalGoBetween(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  moveForwards(legal, board, piece, sourcex, sourcey, canPromote)
  moveBackwards(legal, board, piece, sourcex, sourcey, canPromote)
  tracePrint( ("Go-Between", legal), "legal")
  return legal
end

function legalSideMover(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  moveForwards(legal, board, piece, sourcex, sourcey, canPromote)
  moveBackwards(legal, board, piece, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveW, sourcex, sourcey, canPromote)
  tracePrint( ("Side Mover", legal), "legal")
  return legal
end

function legalVerticalMover(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  moveE(legal, board, piece, sourcex, sourcey, canPromote)
  moveW(legal, board, piece, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveN, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveS, sourcex, sourcey, canPromote)
  tracePrint( ("Vertical Mover", legal), "legal")
  return legal
end

function legalChariot(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  chainMovement(legal, board, piece, moveForwards, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveBackwards, sourcex, sourcey, canPromote)
  tracePrint( ("Reverse Chariot", legal), "legal")
  return legal
end

function legalTiger(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  moveNW(legal, board, piece, sourcex, sourcey, canPromote)
  moveSW(legal, board, piece, sourcex, sourcey, canPromote)
  moveNE(legal, board, piece, sourcex, sourcey, canPromote)
  moveSE(legal, board, piece, sourcex, sourcey, canPromote)
  moveW(legal, board, piece, sourcex, sourcey, canPromote)
  moveE(legal, board, piece, sourcex, sourcey, canPromote)
  moveBackwards(legal, board, piece, sourcex, sourcey, canPromote)
  tracePrint( ("Blind Tiger", legal), "legal")
  return legal
end

function legalLeopard(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  moveNW(legal, board, piece, sourcex, sourcey, canPromote)
  moveSW(legal, board, piece, sourcex, sourcey, canPromote)
  moveNE(legal, board, piece, sourcex, sourcey, canPromote)
  moveSE(legal, board, piece, sourcex, sourcey, canPromote)
  moveForwards(legal, board, piece, sourcex, sourcey, canPromote)
  moveBackwards(legal, board, piece, sourcex, sourcey, canPromote)
  tracePrint( ("Ferocious Leopard", legal), "legal")
  return legal
end

function legalCopper(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  moveForwards(legal, board, piece, sourcex, sourcey, canPromote)
  moveBackwards(legal, board, piece, sourcex, sourcey, canPromote)
  if piece.color == WHITE
    moveNW(legal, board, piece, sourcex, sourcey, canPromote)
    moveNE(legal, board, piece, sourcex, sourcey, canPromote)
  elseif piece.color == BLACK
    moveSW(legal, board, piece, sourcex, sourcey, canPromote)
    moveSE(legal, board, piece, sourcex, sourcey, canPromote)
  else
    assert(false)
  end
  tracePrint( ("Copper General", legal), "legal")
  return legal
end

function legalElephant(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  moveNW(legal, board, piece, sourcex, sourcey, canPromote)
  moveSW(legal, board, piece, sourcex, sourcey, canPromote)
  moveNE(legal, board, piece, sourcex, sourcey, canPromote)
  moveSE(legal, board, piece, sourcex, sourcey, canPromote)
  moveW(legal, board, piece, sourcex, sourcey, canPromote)
  moveE(legal, board, piece, sourcex, sourcey, canPromote)
  moveForwards(legal, board, piece, sourcex, sourcey, canPromote)
  tracePrint( ("Drunken Elephant", legal), "legal")
  return legal
end

function legalKirin(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  moveNW(legal, board, piece, sourcex, sourcey, canPromote)
  moveSW(legal, board, piece, sourcex, sourcey, canPromote)
  moveNE(legal, board, piece, sourcex, sourcey, canPromote)
  moveSE(legal, board, piece, sourcex, sourcey, canPromote)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex, sourcey+2, canPromote)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex, sourcey-2, canPromote)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex+2, sourcey, canPromote)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex-2, sourcey, canPromote)
  tracePrint( ("Kirin", legal), "legal")
  return legal
end

function legalPhoenix(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  moveN(legal, board, piece, sourcex, sourcey, canPromote)
  moveS(legal, board, piece, sourcex, sourcey, canPromote)
  moveE(legal, board, piece, sourcex, sourcey, canPromote)
  moveW(legal, board, piece, sourcex, sourcey, canPromote)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex+2, sourcey+2, canPromote)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex+2, sourcey-2, canPromote)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex-2, sourcey+2, canPromote)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex-2, sourcey-2, canPromote)
  tracePrint( ("Phoenix", legal), "legal")
  return legal
end

function legalQueen(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  chainMovement(legal, board, piece, moveN, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveS, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)

  tracePrint( ("Queen", legal), "legal")
  return legal
end

function legalStag(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  moveE(legal, board, piece, sourcex, sourcey, canPromote)
  moveW(legal, board, piece, sourcex, sourcey, canPromote)
  moveSE(legal, board, piece, sourcex, sourcey, canPromote)
  moveSW(legal, board, piece, sourcex, sourcey, canPromote)
  moveNE(legal, board, piece, sourcex, sourcey, canPromote)
  moveNW(legal, board, piece, sourcex, sourcey, canPromote)

  chainMovement(legal, board, piece, moveForwards, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveBackwards, sourcex, sourcey, canPromote)
  tracePrint( ("Flying Stag", legal), "legal")
  return legal
end

function legalOx(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  chainMovement(legal, board, piece, moveN, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveS, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)
  tracePrint( ("Flying Ox", legal), "legal")
  return legal
end

function legalBoar(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  chainMovement(legal, board, piece, moveE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)
  tracePrint( ("Free Boar", legal), "legal")
  return legal
end

function legalWhale(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  chainMovement(legal, board, piece, moveN, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveS, sourcex, sourcey, canPromote)
  if piece.color == WHITE
    chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)
    chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)
  elseif piece.color == BLACK
    chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
    chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
  else
    assert(false)
  end
  tracePrint( ("Whale", legal), "legal")
  return legal
end

function legalWhiteHorse(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  chainMovement(legal, board, piece, moveN, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveS, sourcex, sourcey, canPromote)

  if piece.color == WHITE
    chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
    chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
  elseif piece.color == BLACK
    chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)
    chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)
  else
    assert(false)
  end
  tracePrint( ("White Horse", legal), "legal")
  return legal
end

function legalFalcon(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  chainMovement(legal, board, piece, moveE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveBackwards, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)


  moveForwards(legal, board, piece, sourcex, sourcey, canPromote)
  tryToEnter(legal, board, piece, sourcex, sourcey, sourcex, sourcey+2, canPromote)

  doubleMove(legal, board, piece, sourcex, sourcey, moveForwards, moveForwards, canPromote)
  doubleMove(legal, board, piece, sourcex, sourcey, moveForwards, moveBackwards, canPromote)
  tracePrint( ("Horned Falcon", legal), "legal")
  return legal
end

function legalSoaringEagle(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  chainMovement(legal, board, piece, moveE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveBackwards, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveForwards, sourcex, sourcey, canPromote)

  if piece.color == WHITE
    chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)
    chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)
    moveNE(legal, board, piece, sourcex, sourcey, canPromote)
    moveNW(legal, board, piece, sourcex, sourcey, canPromote)
    tryToEnter(legal, board, piece, sourcex, sourcey, sourcex+2, sourcey+2, canPromote)
    tryToEnter(legal, board, piece, sourcex, sourcey, sourcex-2, sourcey+2, canPromote)
    doubleMove(legal, board, piece, sourcex, sourcey, moveNE, moveNE, canPromote)
    doubleMove(legal, board, piece, sourcex, sourcey, moveNW, moveNW, canPromote)
    doubleMove(legal, board, piece, sourcex, sourcey, moveNE, moveSW, canPromote)
    doubleMove(legal, board, piece, sourcex, sourcey, moveNW, moveSE, canPromote)
  elseif piece.color == BLACK
    chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
    chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
    moveSE(legal, board, piece, sourcex, sourcey, canPromote)
    moveSW(legal, board, piece, sourcex, sourcey, canPromote)
    tryToEnter(legal, board, piece, sourcex, sourcey, sourcex+2, sourcey-2, canPromote)
    tryToEnter(legal, board, piece, sourcex, sourcey, sourcex-2, sourcey-2, canPromote)
    doubleMove(legal, board, piece, sourcex, sourcey, moveSE, moveSE, canPromote)
    doubleMove(legal, board, piece, sourcex, sourcey, moveSW, moveSW, canPromote)
    doubleMove(legal, board, piece, sourcex, sourcey, moveSE, moveNW, canPromote)
    doubleMove(legal, board, piece, sourcex, sourcey, moveSW, moveNE, canPromote)
  else
    assert(false)
  end
  tracePrint( ("Soaring Eagle", legal), "legal")
  return legal
end

function legalLion(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  #one step, or Jump
  for x = -2:2
    for y = -2:2
      targetx = sourcex + x
      targety = sourcey + y
      #lion immunity (only in chu shogi)
      if targetx >= 1 && targety >= 1 && targetx <= BOARD_DIMENSIONS && targety <= BOARD_DIMENSIONS #if target in bounds
        # if getPiece(board, targetx, targety).name == Lion && gameType == "chu"
        #   newBoard = deepcopy(board)
        #   #simulates a board where the lion moved by stepping and killed an opposing lion
        #   updateBoard(newBoard, initMoveMovement(sourcex, sourcey, targetx, targety, nothing))
        #   #if the lion is not in danger of being killed, it's legal to move in
        #   if !isPieceInCheck(newBoard, targetx, targety)
        #     tryToEnter(legal, board, piece, sourcex, sourcey, targetx, targety, canPromote)
        #   end
        # #if the lion isnt killing a lion, its legal to move in
        # else
          tryToEnter(legal, board, piece, sourcex, sourcey, targetx, targety, canPromote)
        # end
      end
    end
  end
  #double moves
  moves = [moveNW, moveN, moveNE, moveE, moveSE, moveS, moveSW, moveW]

  doubleLegal = Array{Move}(0)
  for i in moves
    for j in moves
      doubleMove(doubleLegal, board, piece, sourcex, sourcey, i, j, canPromote)
    end
  end

  for i = 1:length(doubleLegal)
    # if getPiece(board, doubleLegal[i].targetx2, doubleLegal[i].targety2).name == Lion && gameType == "chu"
    #   newBoard = deepcopy(board)
    #   #simulates a board where the lion moved by stepping and killed an opposing lion
    #   updateBoard(newBoard, initMoveDoubleMovement(doubleLegal[i].sourcex, doubleLegal[i].sourcey, doubleLegal[i].targetx, doubleLegal[i].targety, nothing, doubleLegal[i].targetx2, doubleLegal[i].targety2))
    #   #if the lion is not in danger of being killed, it's legal to move in
    #   if !isPieceInCheck(newBoard, doubleLegal[i].targetx2, doubleLegal[i].targety2)
    #     push!(legal, doubleLegal[i])
    #   end
    # #if the lion isnt killing a lion, its legal to move in
    # else
      push!(legal, doubleLegal[i])
    # end
  end

  tracePrint( ("Lion", legal), "legal")
  return legal
end

function legalViceGeneral(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  noJump = [King, PDrunkenElephant, GreatGeneral, PRookGeneral, ViceGeneral, PBishopGeneral]

  #range jumps
  rangeJump(legal, board, piece, moveNW, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveNE, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveSW, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveSE, sourcex, sourcey, noJump, canPromote)

  #Move once, same as king
  append!(legal, legalKing(board, sourcex, sourcey, true))

  #double & triple moves
  moves = [moveNW, moveN, moveNE, moveE, moveSE, moveS, moveSW, moveW]
  tripleLegal = Array{Move}(0)
  doubleLegal = Array{Move}(0)

  for i in moves
    for j in moves
      doubleMove(doubleLegal, board, piece, sourcex, sourcey, i, j, canPromote)
      for k in moves
        tripleMove(tripleLegal, board, piece, sourcex, sourcey, i, j, k, canPromote)
      end
    end
  end

  if length(doubleLegal) != 0
    append!(legal, doubleLegal)
  end

  if length(tripleLegal) != 0
    append!(legal, tripleLegal)
  end

  tracePrint( ("Vice General", legal), "legal")
  return legal
end

function legalGreatGeneral(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  noJump = [King, PDrunkenElephant, GreatGeneral, PRookGeneral]

  #range jumps
  rangeJump(legal, board, piece, moveNW, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveNE, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveSW, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveSE, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveN, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveE, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveS, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveW, sourcex, sourcey, noJump, canPromote)

  tracePrint( ("Great General", legal), "legal")
  return legal
end

function legalBishopGeneral(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  noJump = [King, PDrunkenElephant, GreatGeneral, PRookGeneral, ViceGeneral, PBishopGeneral, RookGeneral, BishopGeneral]

  #range jumps
  rangeJump(legal, board, piece, moveNW, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveNE, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveSW, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveSE, sourcex, sourcey, noJump, canPromote)

  tracePrint( ("Bishop General", legal), "legal")
  return legal
end

function legalRookGeneral(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)
  noJump = [King, PDrunkenElephant, GreatGeneral, PRookGeneral, ViceGeneral, PBishopGeneral, RookGeneral, BishopGeneral]

  #range jumps
  rangeJump(legal, board, piece, moveN, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveE, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveS, sourcex, sourcey, noJump, canPromote)
  rangeJump(legal, board, piece, moveW, sourcex, sourcey, noJump, canPromote)

  tracePrint( ("Rook General", legal), "legal")
  return legal
end

function legalFireDemon(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  #range
  chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveE, sourcex, sourcey, canPromote)

  #Move once, same as king
  append!(legal, legalKing(board, sourcex, sourcey, canPromote))

  #double & triple moves
  moves = [moveNW, moveN, moveNE, moveE, moveSE, moveS, moveSW, moveW]
  tripleLegal = Array{Move}(0)
  doubleLegal = Array{Move}(0)

  for i in moves
    for j in moves
      doubleMove(doubleLegal, board, piece, sourcex, sourcey, i, j, canPromote)
      for k in moves
        tripleMove(tripleLegal, board, piece, sourcex, sourcey, i, j, k, canPromote)
      end
    end
  end

  if length(doubleLegal) != 0
    append!(legal, doubleLegal)
  end

  if length(tripleLegal) != 0
    append!(legal, tripleLegal)
  end

  tracePrint( ("Fire Demon", legal), "legal")
  return legal
end

function legalHeavenlyTetrarch(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  legalRange = Array{Move}(0)
  legalSide = Array{Move}(0)

  #range, cannot move onto adjacent spaces
  chainMovement(legalRange, board, piece, moveNW, sourcex-1, sourcey+1, canPromote)
  chainMovement(legalRange, board, piece, moveNE, sourcex+1, sourcey+1, canPromote)
  chainMovement(legalRange, board, piece, moveSW, sourcex-1, sourcey-1, canPromote)
  chainMovement(legalRange, board, piece, moveSE, sourcex+1, sourcey-1, canPromote)
  chainMovement(legalRange, board, piece, moveN, sourcex, sourcey+1, canPromote)
  chainMovement(legalRange, board, piece, moveS, sourcex, sourcey+1, canPromote)
  for i = 1:length(legalRange) #make sourcex and sourcey correct (after starting chainmovement from adjacent squares)
    legalRange[i].sourcex = sourcex
    legalRange[i].sourcey = sourcey
  end


  #igui, double move that ends in the same square
  doubleMove(legal, board, piece, sourcex, sourcey, moveN, moveS, canPromote)
  doubleMove(legal, board, piece, sourcex, sourcey, moveNE, moveSW, canPromote)
  doubleMove(legal, board, piece, sourcex, sourcey, moveE, moveW, canPromote)
  doubleMove(legal, board, piece, sourcex, sourcey, moveSE, moveNW, canPromote)
  doubleMove(legal, board, piece, sourcex, sourcey, moveS, moveN, canPromote)
  doubleMove(legal, board, piece, sourcex, sourcey, moveSW, moveNE, canPromote)
  doubleMove(legal, board, piece, sourcex, sourcey, moveW, moveE, canPromote)
  doubleMove(legal, board, piece, sourcex, sourcey, moveNW, moveSE, canPromote)



  #Orthog -- sides
  tryToEnter(legalSide, board, piece, sourcex, sourcey, sourcex+2, sourcey, canPromote)
  tryToEnter(legalSide, board, piece, sourcex, sourcey, sourcex-2, sourcey, canPromote)
  doubleMove(legalSide, board, piece, sourcex+1, sourcey, moveE, moveE, canPromote)
  doubleMove(legalSide, board, piece, sourcex-1, sourcey, moveW, moveW, canPromote)
  for i = 1:length(legalSide)
    legalSide[i].sourcex = sourcex
    legalSide[i].sourcey = sourcey
  end

  append!(legal, legalRange)
  append!(legal, legalSide)

  tracePrint( ("Heavenly Tetrarch", legal), "legal")
  return legal
end

function legalWaterBuffalo(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  #range
  chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveW, sourcex, sourcey, canPromote)

  #single move
  moveN(legal, board, piece, sourcex, sourcey, canPromote)
  moveS(legal, board, piece, sourcex, sourcey, canPromote)

  #double move
  doubleMove(legal, board, piece, sourcex, sourcey, moveN, moveN, canPromote)
  doubleMove(legal, board, piece, sourcex, sourcey, moveS, moveS, canPromote)

  tracePrint( ("Water Buffalo", legal), "legal")
  return legal
end

function legalChariotSoldier(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  #range
  chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveN, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveS, sourcex, sourcey, canPromote)

  #single move
  moveE(legal, board, piece, sourcex, sourcey, canPromote)
  moveW(legal, board, piece, sourcex, sourcey, canPromote)

  #double move
  doubleMove(legal, board, piece, sourcex, sourcey, moveE, moveE, canPromote)
  doubleMove(legal, board, piece, sourcex, sourcey, moveW, moveW, canPromote)

  tracePrint( ("Chariot Soldier", legal), "legal")
  return legal
end

function legalSideSoldier(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  #range
  chainMovement(legal, board, piece, moveE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveW, sourcex, sourcey, canPromote)

  #single move
  moveN(legal, board, piece, sourcex, sourcey, canPromote)
  moveS(legal, board, piece, sourcex, sourcey, canPromote)

  #double move
  doubleMove(legal, board, piece, sourcex, sourcey, moveForwards, moveForwards, canPromote)

  tracePrint( ("Side Soldier", legal), "legal")
  return legal
end

function legalVerticalSoldier(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  #range
  chainMovement(legal, board, piece, moveForwards, sourcex, sourcey, canPromote)

  #single move
  moveBackwards(legal, board, piece, sourcex, sourcey, canPromote)
  moveW(legal, board, piece, sourcex, sourcey, canPromote)
  moveE(legal, board, piece, sourcex, sourcey, canPromote)

  #double move
  doubleMove(legal, board, piece, sourcex, sourcey, moveW, moveW, canPromote)
  doubleMove(legal, board, piece, sourcex, sourcey, moveE, moveE, canPromote)

  tracePrint( ("Vertical Soldier", legal), "legal")
  return legal
end

function legalIronGeneral(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  moveForwards(legal, board, piece, sourcex, sourcey, canPromote)
  if piece.color == WHITE
    moveNW(legal, board, piece, sourcex, sourcey, canPromote)
    moveNE(legal, board, piece, sourcex, sourcey, canPromote)
  elseif piece.color == BLACK
    moveSW(legal, board, piece, sourcex, sourcey, canPromote)
    moveSE(legal, board, piece, sourcex, sourcey, canPromote)
  else
    assert(false)
  end

  tracePrint( ("Iron General", legal), "legal")
  return legal
end

function legalFreeEagle(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  #Moves like a queen, ranging in all directions
  append!(legal, legalQueen(board, sourcex, sourcey, canPromote))

  moves = [moveNW, moveNE, moveSE, moveSW]

  #moves twice as a cat-sword (diagonal step)
  for i in moves
    for j in moves
      doubleMove(legal, board, piece, sourcex, sourcey, i, j, canPromote)
    end
  end

  #Can also jump 2 squares, on the orthogonal or diagonal
  for x = -2:2:2
    for y = -2:2:2
      targetx = sourcex + x
      targety = sourcey + y
      #lion immunity (only in chu shogi)
      if targetx >= 1 && targety >= 1 && targetx <= BOARD_DIMENSIONS && targety <= BOARD_DIMENSIONS #if target in bounds
        tryToEnter(legal, board, piece, sourcex, sourcey, targetx, targety, canPromote)
      end
    end
  end

  tracePrint( ("Free Eagle", legal), "legal")
  return legal
end

function legalLionHawk(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  #Moves like a Lion, and a bishop
  append!(legal, legalLion(board, sourcex, sourcey, canPromote))
  chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)
  chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)

  tracePrint( ("Lion Hawk", legal), "legal")
  return legal
end

function legalMultiGeneral(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  #Ranges forward, or diagonally backwards
  chainMovement(legal, board, piece, moveForwards, sourcex, sourcey, canPromote)
  if piece.color == WHITE
    chainMovement(legal, board, piece, moveSE, sourcex, sourcey, canPromote)
    chainMovement(legal, board, piece, moveSW, sourcex, sourcey, canPromote)
  elseif piece.color == BLACK
    chainMovement(legal, board, piece, moveNE, sourcex, sourcey, canPromote)
    chainMovement(legal, board, piece, moveNW, sourcex, sourcey, canPromote)
  else
    assert(false)
  end

  tracePrint( ("Multi General", legal), "legal")
  return legal
end

function legalDog(board::Board, sourcex::Int, sourcey::Int, canPromote::Bool)
  legal = Array{Move}(0)
  piece = getPiece(board, sourcex, sourcey)

  #Steps forward, or diagonally backwards
  moveForwards(legal, board, piece, sourcex, sourcey, canPromote)
  if piece.color == WHITE
    moveSE(legal, board, piece, sourcex, sourcey, canPromote)
    moveSW(legal, board, piece, sourcex, sourcey, canPromote)
  elseif piece.color == BLACK
    moveNE(legal, board, piece, sourcex, sourcey, canPromote)
    moveNW(legal, board, piece, sourcex, sourcey, canPromote)
  else
    assert(false)
  end

  tracePrint( ("Dog", legal), "legal")
  return legal
end





#Returns if the piece can be taken in the opponent's next move
function isPieceInCheck(board::Board, pieceLocX::Int, pieceLocY::Int)
  inCheck = false

  newBoard = board
  piece = getPiece(board, pieceLocX, pieceLocY)

  #set player to the opponent
  if getCurrentPlayer(newBoard) == piece.color
    newBoard = deepcopy(board)
    nextPlayer(newBoard)
  end

  enemyMoves = allLegalMovementMoves(newBoard)
  for i in 1:length(enemyMoves)
    if (enemyMoves[i].targetx == pieceLocX) && (enemyMoves[i].targety == pieceLocY)
      inCheck = true
      break
    end
  end

  return inCheck
end

function isPieceInCheck(board::Board, pieceLocX::Void, pieceLoxY::Void)
  return true #the piece does not exist. Let's pretend that makes it in check, to cut down on exploration of games with lost kings.
end

#Returns if the piece cannot make a move that will take it out of check #NOT OPTIMIZED BECAUSE NEVER USED
function isPieceInCheckMate(board::Board, pieceLocX::Int, pieceLocY::Int)
  inCheckMate = true

  newBoard = deepcopy(board)
  piece = getPiece(board, pieceLocX, pieceLocY)

  #set player to the piece's owner
  if getCurrentPlayer(newBoard) != piece.color
    nextPlayer(newBoard)
  end

  friendlyMoves = allLegalMoves(newBoard)
  for i in 1:length(friendlyMoves)
    #Make a board copy and do the move there
    newerBoard = deepcopy(newBoard)
    updateBoard(newerBoard, friendlyMoves[i])

    #For all enemy moves on that space, see if piece is still in check
    if !isPieceInCheck(newerBoard, pieceLocX, pieceLocY)
      inCheckMate = false
      break
    end
  end

  return inCheck
end
