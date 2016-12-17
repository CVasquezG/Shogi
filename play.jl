###INTERACTIVE PART###
#asks user to input game settings to set up the game and start playing.
#calls all the other julia files
Base.eval(:(have_color = true))
ARGS =fill("",6) #create ARGS array to pass parameters to the other julia files.
filename =""
game =""
gameTypeN=""
cheating =""
timelimit=""
limitadd=""
println("\tSHOGI")
  print("Create new game (y/n): ")
  createGame = chomp(readline(STDIN))
if createGame != "n"
  while true
      print("Enter name of the game: ")
      filename = chomp(readline(STDIN))
      print("Enter game type S(Shogi) or M(minishogi) or C(Chushogi): ")
      game = chomp(readline(STDIN))
      print("Type T or F to enable cheating. ")
      cheating =chomp( readline(STDIN))
      print("What is the timelimit for the game? ")
      timelimit =chomp( readline(STDIN))
      while !isnumber(timelimit)
        print("Please enter an Integer")
        timelimit =chomp( readline(STDIN))
      end
      print("How much would you like to add to limitadd? ")
      limitadd =chomp( readline(STDIN))
      while !isnumber(limitadd)
        print("Please enter an Integer")
        limitadd =chomp( readline(STDIN))
      end
      println("\nCONFIRM SETTINGS:")

      if game=="S" || game=="s"
        gameTypeN="Shogi"
      elseif game== "M" || game=="m"
        gameTypeN="minishogi"
      elseif game=="C" || game=="c"
        gameTypeN="Chushogi"
      end

      @printf("Filename: %s\nType: %s\nCheating: %s\nTimelimit: %s\nLimitadd: %s\n",filename,gameTypeN,cheating=="T"?"on":"off", timelimit, limitadd)
      print("continue (y/n): ")
      cont = chomp(readline(STDIN))
      if(cont!="n")
        break
      end
    end

  ARGS[1] = filename
  ARGS[2] = game
  ARGS[3] = cheating
  ARGS[4] = timelimit
  ARGS[5] = limitadd
  include("start.jl")
else
  print("Enter file name to open: ")
  filename = chomp(readline(STDIN))
  ARGS[1]= filename
end
include("dependencies.jl")

@printf("Choose player setting\n1)Player vs Player\n2)Player(Black) vs AI(White)\n3)AI(Black) vs Player(White)\n4)AI vs AI\nenter(1/2/3/4): ")
playerSettings= chomp(readline(STDIN))

board = generateCurrentBoard() #only needed to check for currentPlayer
cheat = getCheating(ARGS[1])
#####MAIN LOOP AFTER THIS####
while true
  ARGS = ARGS[1:6]

  include("display.jl")
  print("run validate (y/n): ")
  val = chomp(readline(STDIN))
  if val!="n"
  include("validate.jl")
  end
  print("run win (y/n): ")
  win = chomp(readline(STDIN))
  if win!="n"
  include("win.jl")
  end
  print("continue (y/n): ")
  cont = chomp(readline(STDIN))
  if cont=="n"
    break
  end

#include("move.jl")

if playerSettings =="1" || (playerSettings =="2" && getCurrentPlayer(board)=="Black") || (playerSettings =="3" && getCurrentPlayer(board)=="White")
  @printf("%s player make a move:\n", getCurrentPlayer(board))
  print("Select move type m(Movement), d(Drop), r(Resign):")
  moveType = chomp(readline(STDIN))
  if moveType == "m"
    print("X source: ")
    xsource =chomp(readline(STDIN))
    while !isnumber(xsource)
      print("Please enter an Integer")
      xsource =chomp( readline(STDIN))
    end
    print("Y source: ")
    ysource = chomp(readline(STDIN))
    while !isnumber(ysource)
      print("Please enter an Integer")
      ysource =chomp( readline(STDIN))
    end
    print("X target: ")
    xtarget = chomp(readline(STDIN))
    while !isnumber(xtarget)
      print("Please enter an Integer")
      xtarget =chomp( readline(STDIN))
    end
    print("Y target: ")
    ytarget = chomp(readline(STDIN))
    while !isnumber(ytarget)
      print("Please enter an Integer")
      ytarget =chomp( readline(STDIN))
    end
    print("Promote the piece?(T/F): ")
    promPiece = chomp(readline(STDIN))
    print("X target 2: (Press Enter if not wanted)")
    xtarget2 = chomp(readline(STDIN))
    print("Y target 2 (Press Enter if not wanted): ")
    ytarget2 = chomp(readline(STDIN))
    ARGS[2] = xsource
    ARGS[3] = ysource
    ARGS[4] = xtarget
    ARGS[5] = ytarget
    ARGS[6] = promPiece
    if isnumber(xtarget2) && isnumber(ytarget2)  && xtarget2 !="" && ytarget2 !=""
      push!(ARGS, xtarget2)
      push!(ARGS, ytarget2)
    end

    include("move_user_move.jl")
  elseif moveType == "d"
    print("Enter piece to drop: ")
    pieceName = chomp(readline(STDIN))
    print("X target: ")
    xtarget = chomp(readline(STDIN))
    print("Y target: ")
    ytarget = chomp(readline(STDIN))
    ARGS[2] = pieceName
    ARGS[3] = xtarget
    ARGS[4] = ytarget
    include("move_user_drop.jl")
  elseif moveType == "r"
      include("move_user_resign.jl")
  end
  else #ai making move
    ##ADD move_cheat.jl
    @printf("%s AI making a move:\n", getCurrentPlayer(board))
    if cheat == "legal"
    include("move.jl")
    else
    include("move_cheat.jl")
    end
 end
end
