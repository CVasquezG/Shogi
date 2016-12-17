#=
  display.jl <filename>
=#
Base.eval(:(have_color=true))
include("dependencies.jl")

board = generateCurrentBoard()
#printMoves()

printBoard(board, false) #Removed the print hands because they were in wrong positions, and I already put them in print board.
