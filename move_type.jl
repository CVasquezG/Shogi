type Move
  move_type::AbstractString
  sourcex::Union{Int,Void}
  sourcey::Union{Int,Void}
  targetx::Union{Int,Void}
  targety::Union{Int,Void}
  option::Union{AbstractString,Piece,Void}
  targetx2::Union{Int,Void}
  targety2::Union{Int,Void}
  targetx3::Union{Int,Void}
  targety3::Union{Int,Void}
end
#DOES NOT HOLD MOVENUMBER AND I_AM_CHEATING

#Are two pieces functionally identical? (Same colour and name)
function ==(a::Move, b::Move)
  return (a.move_type == b.move_type
          && a.sourcex == b.sourcex
          && a.sourcey == b.sourcey
          && a.targetx == b.targetx
          && a.targety == b.targety
          && a.option == b.option
          && a.targetx2 == b.targetx2
          && a.targety2 == b.targety2
          && a.targetx3 == b.targetx3
          && a.targety3 == b.targety3)
end


function initMoveMovement(sourcex::Int, sourcey::Int, targetx::Int, targety::Int, option::Union{AbstractString,Void})
  return Move(MOVETYPE_MOVEMENT,
              sourcex,
              sourcey,
              targetx,
              targety,
              option,
              nothing, #targetx2
              nothing, #targety2
              nothing, #targetx3
              nothing  #targety3
              )
end

function initMoveDoubleMovement(sourcex::Int, sourcey::Int, targetx::Int, targety::Int, option::Union{AbstractString,Void}, targetx2::Int, targety2::Int)
  return Move(MOVETYPE_MOVEMENT,
              sourcex,
              sourcey,
              targetx,
              targety,
              option,
              targetx2,
              targety2,
              nothing, #targetx3
              nothing  #targety3
              )
end

function initMoveTripleMovement(sourcex::Int, sourcey::Int, targetx::Int, targety::Int, option::Union{AbstractString,Void}, targetx2::Int, targety2::Int, targetx3::Int, targety3::Int)
  return Move(MOVETYPE_MOVEMENT,
              sourcex,
              sourcey,
              targetx,
              targety,
              option,
              targetx2,
              targety2,
              targetx3,
              targety3
              )
end

function initMoveDrop(targetx::Int, targety::Int, option::Piece)
  return Move(MOVETYPE_DROP,
              nothing, #sourcex
              nothing, #sourcey
              targetx,
              targety,
              option,
              nothing,#targetx2
              nothing, #targety2
              nothing, #targetx3
              nothing  #targety3
              )
end

function initMoveResign()
  return Move(MOVETYPE_RESIGN,
              nothing, #sourcex
              nothing, #sourcey
              nothing,
              nothing,
              nothing,
              nothing,#targetx2
              nothing,#targety2
              nothing, #targetx3
              nothing  #targety3
              )
end

function isMoveMovement(move::Move)
  return move.move_type == MOVETYPE_MOVEMENT
end

function isMoveDrop(move::Move)
  return move.move_type == MOVETYPE_DROP
end

function isMoveResign(move::Move)
  return move.move_type == MOVETYPE_RESIGN
end

function isMoveAny(move::Move)
  return isMoveMovement(move) || isMoveDrop(move) || isMoveResign(move)
end
