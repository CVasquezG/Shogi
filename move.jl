#=
  move.jl <filename>
  will update the game file with a move
=#
include("dependencies.jl")

const TIME_LIMIT = 7*60 #MAKE THIS WHATEVER LUDICROUS NUMBER YOU WANT. IT'S ALL LEGAL.
# const MOVE_LIMIT = 1000#20_000  #2200 seems about right for 4.5 minute turns
const EXPLORATION_RATE = 1.4 #how much the ai looks at new options, as opposed to what has worked before.
const MAX_TREE_DEPTH = 100  #helps stop the tree from crashing from memory use, and enforces more exploration after some point.



function getMove(board::Board)
  # moveTree = initMonteCarloRoot(board)
  # return moveTree.children[moveTree.bestChildIndex].move
  timeLeft = 0
  db=SQLite.DB(ARGS[1])

  res = SQLite.query(db, "SELECT value FROM meta WHERE key ='time_add';")
  timeAdd = parse(Int, getSQLValue(res))

  if getCurrentPlayer(currentBoard) == BLACK
    res = SQLite.query(db, "SELECT value FROM meta WHERE key ='sente_time';")
    timeLeft = parse(Int, get(res[1][1]))

  elseif getCurrentPlayer(currentBoard) == WHITE
    res = SQLite.query(db, "SELECT value FROM meta WHERE key ='gote_time';")
    timeLeft = parse(Int, get(res[1][1]))
  else
    assert(false)
  end

  return initMonteCarloRoot(board, timeLeft, timeAdd) #Returns the best move and the time taken
end

function justResign(root)
  return "Resign", 0, root
end

# #CHILD
type MonteCarloNode
  parent
  move::Move
  board::Board
  depth::Int
  plays::Float64
  score::Float64
	allMoves::Array{Move}
  remainingMoves::Array{Move}
	children::Array
	bestChildIndex::Int
end


# #ROOT
type MonteCarloRoot
  board::Board
  depth::Int
  allMoves::Array{Move}
  remainingMoves::Array{Move}
  children::Array{MonteCarloNode}
  bestChildIndex::Int
  plays::Float64
  score::Float64
end


function initMonteCarloRoot(board::Board, timeLeft::Int, timeAdd::Int)
  startTime = Int(now())

  self = MonteCarloRoot(
    deepcopy(board),            #board
    0,                          #depth
    allLegalNotStupidMoves(board),       #allMoves
    [],                         #remainingMoves #empty becaues all children are produced immediately.
		Array{MonteCarloNode}(0),   #children
    0,                          #bestChildIndex (uninitialized invalid value)
    0,                          #plays
		0											   		#score
  )

  db=SQLite.DB(ARGS[1])

  tracePrint(difficulty)

  if timeLeft == 0 #INFINITE TIME
    timeToTake = TIME_LIMIT

  else  #FINITE TIME
    if gameType == GAMETYPE_MINI
      AVERAGE_GAME_LENGTH = 80
    else
      AVERAGE_GAME_LENGTH = 125
    end

    if difficulty == DIFFICULTY_NORMAL
      AVERAGE_GAME_LENGTH = AVERAGE_GAME_LENGTH * 3
    end

    currentTurn = Int(floor(self.board.turnNumber/2)) #number of moves you've taken before
    expectedTurnsRemaining = max(AVERAGE_GAME_LENGTH - currentTurn, 10)
    timeToTake = timeLeft / expectedTurnsRemaining

    timeToTake = timeToTake + timeAdd

    if timeToTake < 1.5
      return self.allMoves[1], Int(now()) - startTime, self #return best child and used time
    end
  end


  #Resigning is always the best way to minimize score assuming its tested against other suicide ai
  if difficulty == DIFFICULTY_SUICIDE
    return self.allMoves[end], Int(now()) - startTime, self
  elseif difficulty == DIFFICULTY_RANDOM
    randIndex::Int = rand(ourRand, 1:length(self.allMoves) )
    return self.allMoves[randIndex], Int(now()) - startTime, self
  end

	#Populate with all depth 1 children
	for i in 1:length(self.allMoves) -1 #Skip resign for now
		createChild( self, self.allMoves[i] )
	end


	iterations = 0
	while ( Int(now()) -  startTime) < timeToTake*1000
		grow(self) #Runs selection, expansion, simulation and backpropogation
		iterations = iterations + 1
	end
	tracePrint( ("iterations is", iterations) )
	tracePrint( ("Current time is", Int(now()) - startTime) )
	tracePrint( "Grow finished" )


  createChild( self, self.allMoves[end] ) #Create resign, finally
  self.bestChildIndex = length(self.children)

  #Make resigning suck, so it only does it if there is no other option. Note that losing should not be an option in the below code.
  self.children[end].plays = 1
  self.children[end].score = -Inf

  # recursivePrintNode(self)

	for i in length(self.children):-1:1 #starts at resign, moves back
    tracePrint( ("child", i, self.children[i].move, self.children[i].score/self.children[i].plays, self.children[i].score, self.children[i].plays) )

    #Check that the move is better than whatever we currently have
    if (self.children[i].score > self.children[self.bestChildIndex].score) #can also use plays, but I find results not as good.
      self.bestChildIndex = i
	  end
	end #End forloop, bestChildIndex is now equal to the highest scoring move which does not enter check.

  tracePrint( ("Best child index", self.bestChildIndex))

  return self.children[self.bestChildIndex].move, Int(now()) - startTime, self #return best child and used time
end



function initMonteCarloNode(parent, move)
  assertIsMonteCarlo( parent )
	#tracePrint( ("starting monteCarloNode with move", move))
  self = MonteCarloNode(
    parent,                     #parent
    move,                       #move
    deepcopy(parent.board),     #board
    parent.depth + 1,           #depth
    0,                          #plays
    0,                          #score
    [],     									  #allMoves
    [],     									  #remainingMoves
		Array{MonteCarloNode}(0),   #children
    1,                          #bestChildIndex
  )

	updateBoard(self.board, self.move)
  if false #gameType == GAMETYPE_MINI
	  self.allMoves = allLegalNotStupidMoves( self.board )
  else
    self.allMoves = allLegalMoves( self.board )
  end

  popResignIfOtherOptions(self.allMoves) #Kill resign if you can keep playing

  self.remainingMoves = deepcopy(self.allMoves)
	return self
end


function grow(root::MonteCarloRoot)
	#Selection - picks which child to expand
	node = selectNode(root, 0)

	#Expansion
  child::MonteCarloNode
  if myExpand(node) #If expand makes a new node, use it
    child = node.children[end]
  else #else pick one at random
   randIndex::Int = rand(ourRand, 1:length(node.children) )
   child = node.children[randIndex]
  end

	simulate(child)
end


function selectNode(node, depth::Int)
  assertIsMonteCarlo(node)
	#return node if its unvisited
	if (length(node.children) == 0 || node.depth == MAX_TREE_DEPTH)
		return node
	end

	#return first unvisited child
	for i in 1:length(node.children)
		if (node.children[i].plays == 0)
			return node.children[i]
		end
	end

	#search down the most interesting visited node
	#score::Float64 = -Inf
  score::Float64
	lastI::Int = 0
	result = node
  #if depth%2 == 0 #Original player's turn POSSIBLE FIXME
  score = selectionEval(node.children[1])
  for i in 2:length(node.children)
    newScore::Float64 = selectionEval(node.children[i])
      if (newScore > score)
        score = newScore
        result = node.children[i] #There is a better looking kid to try
		    lastI = i
      end
  end


	if (result == node)
		return node
	else
		if (depth < MAX_TREE_DEPTH)
			return selectNode(result, depth+1) #Selects from the next node down
		else
			return node
		end
	end
end


#returns float
function selectionEval(node)
	#Upper confidence bound on given node
	nodeWorth::Float64 = Float64(node.score) / node.plays
	random::Float64 = 0.01 * rand(ourRand)

  value = nodeWorth + random + EXPLORATION_RATE*sqrt(log(Float64(node.parent.plays)) / node.plays)

 return value
end


function myExpand(node)
	if length(node.remainingMoves) > 0
    randIndex::Int = rand(ourRand, 1:length(node.remainingMoves))
    createChild( node, node.remainingMoves[randIndex] )
    deleteat!(node.remainingMoves, randIndex)
    return true
  end

  return false
end


function simulate(node)
	origNode = node
  #childrenToKill = Array(MonteCarloNode, 0)

	while ( winState(node.board) == "?")
		#allMoves = allLegalNotStupidMoves(node.board)
    #popResignIfOtherOptions(allMoves) #Kill resign if you can keep playing
		randIndex::Int = rand(ourRand, 1:length(node.allMoves))

		#append!(childrenToKill, node.children)
		createChild(node, node.allMoves[randIndex])

		node = node.children[end]
	end

	theWinState = winState(node.board)

	if (theWinState == "B" && getCurrentPlayer(node.board) == BLACK) || (theWinState == "W" && getCurrentPlayer(node.board) == WHITE)
    if difficulty == DIFFICULTY_PROTRACTED
      backPropogateWin(node)
    else
      backPropogateLoss(node)
    end
    #backPropogateLoss(node)
    #backPropogateWin(node)
	elseif (theWinState == "B" && getCurrentPlayer(node.board) == WHITE) || (theWinState == "W" && getCurrentPlayer(node.board) == BLACK)
    if difficulty == DIFFICULTY_PROTRACTED
      backPropogateLoss(node)
    else
      backPropogateWin(node)
    end
    #backPropogateWin(node)
    #backPropogateLoss(node)
	elseif  (theWinState == "R" && getCurrentPlayer(node.board) == BLACK) || (theWinState == "r" && getCurrentPlayer(node.board) == WHITE)
    if difficulty == DIFFICULTY_PROTRACTED
      backPropogateResignLoss(node)
    else
      backPropogateResignWin(node)
    end
		#backPropogateResignWin(node)
    #backPropogateResignLoss(node)
	elseif (theWinState == "R" && getCurrentPlayer(node.board) == WHITE) || (theWinState == "r" && getCurrentPlayer(node.board) == BLACK)
    if difficulty == DIFFICULTY_PROTRACTED
      backPropogateResignWin(node)
    else
      backPropogateResignLoss(node)
    end
    #backPropogateResignLoss(node)
    #backPropogateResignWin(node)
	elseif theWinState == "D"
    backPropogateDraw(node.parent)
	else
		tracePrint(theWinState)
		assert(false)
	end


  #deletes the simulation children
	while (node != origNode)  #CHECK THIS WORKS ALSO
		nextNode = node.parent
		pop!(node.parent.children)
		node = nextNode
	end
end

function createChild(parent, move)
	newChild::MonteCarloNode = initMonteCarloNode(parent, move)
	push!(parent.children, newChild)
end

function backPropogateWin(node)
	node.score = node.score + 1
	node.plays = node.plays + 1
  if isa(node, MonteCarloNode)
   backPropogateLoss(node.parent)
 end
end

function backPropogateLoss(node)
	node.score = node.score - 1      #THIS SHOULD BE -10K, BUT WITH HARDCODING RESIGN INTO CHECKMATE, IT SHOULD ALWAYS RESIGN INSTEAD OF LOSS, MAKING THE SCORE EFFECTIVELY -1
	node.plays = node.plays + 1
  if isa(node, MonteCarloNode)
   backPropogateWin(node.parent)
  end
end

function backPropogateResignWin(node)
	node.score = node.score + 1
	node.plays = node.plays + 1
  if isa(node, MonteCarloNode)
   backPropogateResignLoss(node.parent)
 end
end

function backPropogateResignLoss(node)
	node.score = node.score - 1
	node.plays = node.plays + 1
  if isa(node, MonteCarloNode)
   backPropogateResignWin(node.parent)
  end
end

function backPropogateDraw(node)
	#node.score is unchanged in a draw
	node.plays = node.plays + 1
  if isa(node, MonteCarloNode)
   backPropogateDraw(node.parent)
  end
end

function assertIsMonteCarlo(thing)
  assert( isa(thing, MonteCarloNode) || isa(thing, MonteCarloRoot) )
end

##END TOREN


#Initializing database
function usage(message)
  println("move.jl <file_name>")
  println(message)
end

function recursivePrintNode(node)
  if isa(node, MonteCarloNode)
    println( repeat("   ", node.depth), node.move,"  ", node.score/node.plays, "  ", node.plays, "     sel-> ", selectionEval(node) )
  else
    println( repeat("   ", node.depth), "  ", node.plays, "  ", length(node.remainingMoves) )
  end

  for i in 1:length(node.children)
    recursivePrintNode(node.children[i])
  end
end

function getNodeAverageScore(node)
  return node.score/node.plays
end

function getMoveScore(board::Board, move::Move)
  trash, garb, node = initMonteCarloRoot(board, 1000, 0)

  score = 0
  highest = 1
  lowest = 1
  sum = 1
  average = 1


  if length(node.children) > 1
    highest = getNodeAverageScore(node.children[1])
    lowest = getNodeAverageScore(node.children[1])
    sum = 0



    score = -9999999
    for i in 1:length(node.children)-1 #skip resign, the last index
      currScore = getNodeAverageScore(node.children[i])
      if move.sourcex == node.children[i].move.sourcex && move.sourcey == node.children[i].move.sourcey && move.targetx == node.children[i].move.targetx && move.targety == node.children[i].move.targety
        score = currScore
      end
      if currScore > highest
        highest = currScore
      end
      if currScore < lowest
        lowest = currScore
      end
      sum = sum + currScore
    end
    average = sum / length(node.children)-1
  else
    tracePrint("NO MOVES")
  end


  tracePrint(("score", score))

  return score, lowest, highest, average
end

function getMoveWorth(board::Board, move::Move)
  score, lowest, highest, average = getMoveScore(board, move)
  deviation = (highest-lowest)/6
  descriptor = ""
  tracePrint(("score is ", score))
  if score <= -9999
    descriptor = ""
  elseif score <= lowest
    descriptor = rand(["You have dishonored your family."
                        , "You shall writhe in the depths of your shame until the end of your days"
                        , "You clearly do not even begin to grasp the simplest of the fundamentals of this game, or of any other aspect of your life."])
  elseif score <= lowest+deviation*1
    descriptor = "So bad! Terrible!"
  elseif score <= lowest+deviation*2
    descriptor = "You goofed."
  elseif score <= lowest+deviation*3
    descriptor = "Not what I would have done."
  elseif score <= lowest+deviation*4
    descriptor = "Adequate."
  elseif score <= lowest+deviation*5
    descriptor = "You done did good, kid."
  elseif score < lowest+deviation*6
    descriptor = "Epic stuntz, way to shogi."
  elseif score == highest
    descriptor = "Best move! You are my god!"
  else
    descriptor = "Adequate."
  end

  if length(descriptor) > 0
    descriptor = string("The AI says: ", descriptor)
  end

  return descriptor

end


 #Checks to see if a filename has been entred.
if !isdefined(ARGS, 1)
  usage("File Name is mandatory")
end


currentBoard = generateCurrentBoard()
newMove, usedTime = getMove(currentBoard)
usedTime = Int(floor(usedTime/1000))

tracePrint( ("NEWMOVE IS ", newMove) )
tracePrint( ("USEDTIME IS ", usedTime) )


db=SQLite.DB(ARGS[1])
res = SQLite.query(db, "SELECT COUNT(*) FROM moves;")
numberOfMoves = get(res[1][1])

res = SQLite.query(db, "SELECT value FROM meta WHERE key ='time_add';")
timeAdd = parse(Int, getSQLValue(res))

res = SQLite.query(db, "SELECT value FROM meta WHERE key ='gote_time';")
goteTime = parse(Int, get(res[1][1]))

res = SQLite.query(db, "SELECT value FROM meta WHERE key ='sente_time';")
senteTime = parse(Int, get(res[1][1]))

#Adding the move to the moves table
if isMoveMovement(newMove) #((sx,sy),(tx,ty), promotion)
	#promote
	if newMove.option == "!"
    if newMove.targetx2 != nothing && newMove.targex3 != nothing
		  SQLite.query(db, "INSERT INTO moves (move_number, move_type, sourcex, sourcey, targetx, targety, option, targetx2, targety2, targetx3, targety3) VALUES ($(numberOfMoves+1), 'move', $(newMove.sourcex), $(newMove.sourcey), $(newMove.targetx), $(newMove.targety), \'!\' , $(newMove.targetx2), $(newMove.targety2), $(newMove.targetx3), $(newMove.targety3))")
    elseif newMove.targetx2 != nothing
      SQLite.query(db, "INSERT INTO moves (move_number, move_type, sourcex, sourcey, targetx, targety, option, targetx2, targety2) VALUES ($(numberOfMoves+1), 'move', $(newMove.sourcex), $(newMove.sourcey), $(newMove.targetx), $(newMove.targety),\'!\', $(newMove.targetx2), $(newMove.targety2))")
    else
      SQLite.query(db, "INSERT INTO moves (move_number, move_type, sourcex, sourcey, targetx, targety, option) VALUES ($(numberOfMoves+1), 'move', $(newMove.sourcex), $(newMove.sourcey), $(newMove.targetx), $(newMove.targety),\'!\')")
    end
	else
    if newMove.targetx2 != nothing && newMove.targex3 != nothing
      SQLite.query(db, "INSERT INTO moves (move_number, move_type, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3) VALUES ($(numberOfMoves+1), 'move', $(newMove.sourcex), $(newMove.sourcey), $(newMove.targetx), $(newMove.targety), $(newMove.targetx2), $(newMove.targety2), $(newMove.targetx3), $(newMove.targety3))")
    elseif newMove.targetx2 != nothing
      SQLite.query(db, "INSERT INTO moves (move_number, move_type, sourcex, sourcey, targetx, targety, targetx2, targety2) VALUES ($(numberOfMoves+1), 'move', $(newMove.sourcex), $(newMove.sourcey), $(newMove.targetx), $(newMove.targety), $(newMove.targetx2), $(newMove.targety2))")
    else
      SQLite.query(db, "INSERT INTO moves (move_number, move_type, sourcex, sourcey, targetx, targety) VALUES ($(numberOfMoves+1), 'move', $(newMove.sourcex), $(newMove.sourcey), $(newMove.targetx), $(newMove.targety))")
    end
	end
elseif isMoveDrop(newMove) #option contains piece.
	SQLite.query(db, "INSERT INTO moves (move_number, move_type, sourcex, sourcey, targetx, targety, option) VALUES ($(numberOfMoves+1), 'drop', 0, 0, $(newMove.targetx), $(newMove.targety) ,'$( getDatabaseName(newMove.option.name) )')")
elseif isMoveResign(newMove)
	SQLite.query(db, "INSERT INTO moves (move_number, move_type,sourcex, sourcey, targetx, targety) VALUES ($(numberOfMoves+1), 'resign', 0, 0, 0, 0)")
end


if getCurrentPlayer(currentBoard) == BLACK
  senteTime =  senteTime-usedTime+timeAdd
  tracePrint( ("SENTE TIME LEFT IS NOW ", senteTime) )
#  SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('sente_time', $(senteTime - usedTime + timeAdd))") #TO CAMILLE, INSERT IS PROBABLY WRONG BECAUSE IT MAKES A NEW ROW. WE JUST WANT TO SET THE VALUES.
  SQLite.query(db, "UPDATE meta SET value = $(senteTime) WHERE key='sente_time'")


elseif getCurrentPlayer(currentBoard) == WHITE
  goteTime = goteTime-usedTime+timeAdd
  tracePrint( ("GOTE TIME LEFT IS NOW ", goteTime ) )
  #SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('gote_time', $(goteTime - usedTime + timeAdd))")
  SQLite.query(db, "UPDATE meta SET value = $(goteTime) WHERE key='gote_time'")
end

#TRACING
board = generateCurrentBoard()
Base.eval(:(have_color=true))
#TRACEPRINT
printBoard(board, false)

tracePrint(checkTimeOut(senteTime, goteTime))
