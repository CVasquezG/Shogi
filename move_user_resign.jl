#=
move_user_resign.jl <filename>
makes the current player resign the game
=#

include("dependencies.jl")

using SQLite


#Write into moves table, a move of type = Resign

function populateDBResign()
  db = SQLite.DB(ARGS[1])
  temp = SQLite.query(db, "SELECT COUNT(*) FROM moves;")
  nM = get(temp[1][1])
  nM += 1
  res = SQLite.query(db, "INSERT INTO moves (move_number, move_type, sourcex, sourcey, targetx, targety) VALUES ($nM, 'resign', 0, 0, 0, 0)")
  #println(res)
end

if !isdefined(ARGS, 1)
  usage("File Name is Mandatory")
end

populateDBResign()
