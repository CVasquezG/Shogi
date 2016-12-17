Base.eval(:(have_color=true))
include("dependencies.jl")

  db = SQLite.DB(ARGS[1])
  res = SQLite.query(db, "SELECT COUNT(*) FROM moves;")
  i = get(res[1][1]) #Total moves taken

  board = initBoard()
  printBoard(board, false)
  moveNum = 0
  while true    # moveNum <= i
    println("Enter n for next move or p for previous move or q to quit")
    step = chomp( readline(STDIN))

    if step == "n"
      if moveNum+1 <= i && moveNum+1 >= 1
        moveNum = moveNum + 1
      else
        println("No board to display")
        continue
      end

    elseif step == "p"
    if moveNum-1 <= i && moveNum-1 >= 0
      moveNum = moveNum - 1
    else
      println("No board to display")
      continue
    end

    elseif step == "q"
      break

    else
      println("invalid input")
      continue
    end

    println("move number $moveNum")

    if moveNum == 0
      println("Start")
      board = initBoard()
      printBoard(board, false)
    else
      board = initBoard()
      for move in 1:moveNum
        generateNextBoard(board, db, move)
      end
      printBoard(board, false)
    end
  end
