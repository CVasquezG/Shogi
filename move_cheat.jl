#=
  move.jl <filename>
  will update the game file with a move
=#
include("dependencies.jl")

# const TIME_LIMIT = 30 #MAKE THIS WHATEVER LUDICROUS NUMBER YOU WANT. IT'S ALL LEGAL.
# const MOVE_LIMIT = 1000#20_000  #2200 seems about right for 4.5 minute turns
const EXPLORATION_RATE = 1.4 #how much the ai looks at new options, as opposed to what has worked before.
const MAX_TREE_DEPTH = 100  #helps stop the tree from crashing from memory use, and enforces more exploration after some point.

ourSeed = ARGS[1]

ourRand = MersenneTwister(ourSeed)

function getMove(board::Board)
  # moveTree = initMonteCarloRoot(board)
  # return moveTree.children[moveTree.bestChildIndex].move
  return initMonteCarloRoot(board) #Returns the best move and the time taken
end

function justResign()
  return "Resign"
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


function initMonteCarloRoot(board::Board)
  startTime = Int(now())

	#tracePrint("initializing root")
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

	#Populate with all depth 1 children
	for i in 1:length(self.allMoves)
		createChild( self, self.allMoves[i] )
	end


  timeLeft::Int = 0
  db=SQLite.DB(ARGS[1])
  if getCurrentPlayer(currentBoard) == BLACK
    res = SQLite.query(db, "SELECT value FROM meta WHERE key ='sente_time';")
    timeLeft = parse(Int, get(res[1][1]))

  elseif getCurrentPlayer(currentBoard) == WHITE
    res = SQLite.query(db, "SELECT value FROM meta WHERE key ='gote_time';")
    timeLeft = parse(Int, get(res[1][1]))
  end


  if timeLeft == 0 #INFINITE TIME
    timeToTake == TIME_LIMIT

  else  #FINITE TIME
    if gameType == GAMETYPE_MINI
      const AVERAGE_GAME_LENGTH = 80
    else
      const AVERAGE_GAME_LENGTH::Int = 125
    end
    currentTurn = Int(floor(self.board.turnNumber/2)) #number of moves you've taken before
    expectedTurnsRemaining = min(AVERAGE_GAME_LENGTH - currentTurn, 10)
    timeToTake = timeLeft / expectedTurnsRemaining

    if timeToTake < 1.5
      return self.children[1].move, Int(now()) - startTime #return best child and used time
    end
  end


	iterations = 0
	while ( Int(now()) -  startTime) < timeToTake*1000
		grow(self) #Runs selection, expansion, simulation and backpropogation
		iterations = iterations + 1
	end
	tracePrint( ("iterations is", iterations) )
	tracePrint( ("Current time is", Int(now()) - startTime) )
	tracePrint( "Grow finished" )


  self.bestChildIndex = length(self.children)

  #Make resigning suck, so it only does it if there is no other option. Note that losing should not be an option in the below code.
  self.children[end].plays = -Inf
  self.children[end].score = -Inf

	for i in length(self.children):-1:1 #starts at resign, moves back
    tracePrint( ("child", i, self.children[i].move, self.children[i].score/self.children[i].plays, self.children[i].score, self.children[i].plays) )

    #Check that the move is better than whatever we currently have
    if (self.children[i].score > self.children[self.bestChildIndex].score) #can also use plays, but I find results not as good.
      self.bestChildIndex = i
	  end
	end #End forloop, bestChildIndex is now equal to the highest scoring move which does not enter check.

	tracePrint( ("Best child index", self.bestChildIndex))
  if self.bestChildIndex == length(self.children)
    tracePrint( "THIS SHOULD BE CHECKMATE - press a key" )
    readline(STDIN)
  end

  return self.children[self.bestChildIndex].move, Int(now()) - startTime #return best child and used time
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
  if gameType == GAMETYPE_MINI
	  self.allMoves = allLegalNotStupidMoves( self.board )
  else
    self.allMoves = allLegalMoves( self.board )
  end

  popResignIfOtherOptions(self.allMoves) #Kill resign if you can keep playing

  self.remainingMoves = deepcopy(self.allMoves)
	#tracePrint("monteCarloNode creation success")
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
	score::Float64 = -Inf
	lastI::Int = 0
	result = node
  if depth%2 == 1 #Original player's turn POSSIBLE FIXME
   for i in 1:length(node.children)
     newScore::Float64 = selectionEval(node.children[i])
    	if (newScore > score)
  			score = newScore
  			result = node.children[i] #There is a better looking kid to try
  			lastI = i
      end
    end
	else #Opponent's turn, look for the worst child
   for i in 1:length(node.children)
     newScore::Float64 = selectionEval(node.children[i])
    	if (newScore < score)
  			score = newScore
  			result = node.children[i] #There is a better looking kid to try
  			lastI = i
      end
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
	return nodeWorth + random + EXPLORATION_RATE*sqrt(log(Float64(node.plays)) / node.parent.plays)
end


function myExpand(node)
	if length(node.remainingMoves) > 0
    randIndex::Int = rand(ourRand, 1:length(node.remainingMoves))
    createChild( node, node.allMoves[randIndex] )
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
		backPropogateLoss(node)#backPropogateWin(node)
	elseif (theWinState == "B" && getCurrentPlayer(node.board) == WHITE) || (theWinState == "W" && getCurrentPlayer(node.board) == BLACK)
		backPropogateWin(node)#backPropogateLoss(node)
	elseif  (theWinState == "R" && getCurrentPlayer(node.board) == BLACK) || (theWinState == "r" && getCurrentPlayer(node.board) == WHITE)
		backPropogateResignWin(node) #backPropogateResignLoss(node)
	elseif (theWinState == "R" && getCurrentPlayer(node.board) == WHITE) || (theWinState == "r" && getCurrentPlayer(node.board) == BLACK)
		backPropogateResignLoss(node) #backPropogateResignWin(node)
	elseif theWinState == "D"
		backPropogateDraw(node)
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


 #Checks to see if a filename has been entred.
if !isdefined(ARGS, 1)
  usage("File Name is mandatory")
end

#newMove = justResign()
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


#Adding the move to the moves table
if isMoveMovement(newMove) #((sx,sy),(tx,ty), promotion)
	#promote
	if newMove.option == "!"
		SQLite.query(db, "INSERT INTO moves (move_number, move_type, sourcex, sourcey, targetx, targety, option) VALUES ($(numberOfMoves+1), 'move', $(newMove.sourcex), $(newMove.sourcey), $(newMove.targetx), $(newMove.targety) ,\'!\')")
	else
		SQLite.query(db, "INSERT INTO moves (move_number, move_type, sourcex, sourcey, targetx, targety) VALUES ($(numberOfMoves+1), 'move', $(newMove.sourcex), $(newMove.sourcey), $(newMove.targetx), $(newMove.targety))")
	end
elseif isMoveDrop(newMove) #option contains piece.
	SQLite.query(db, "INSERT INTO moves (move_number, move_type, sourcex, sourcey, targetx, targety, option) VALUES ($(numberOfMoves+1), 'drop', 0, 0, $(newMove.targetx), $(newMove.targety) ,'$(newMove.option.name)')")
elseif isMoveResign(newMove)
	SQLite.query(db, "INSERT INTO moves (move_number, move_type,sourcex, sourcey, targetx, targety) VALUES ($(numberOfMoves+1), 'resign', 0, 0, 0, 0)")
end

if getCurrentPlayer(currentBoard) == BLACK
  res = SQLite.query(db, "SELECT value FROM meta WHERE key ='sente_time';")
  senteTime = parse(Int, get(res[1][1]))
#  SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('sente_time', $(senteTime - usedTime + timeAdd))") #TO CAMILLE, INSERT IS PROBABLY WRONG BECAUSE IT MAKES A NEW ROW. WE JUST WANT TO SET THE VALUES.
  SQLite.query(db, "UPDATE meta SET value = $(senteTime - usedTime + timeAdd) WHERE key='sente_time'")



elseif getCurrentPlayer(currentBoard) == WHITE
  res = SQLite.query(db, "SELECT value FROM meta WHERE key ='gote_time';")
  goteTime = parse(Int, get(res[1][1]))
  #SQLite.query(db, "INSERT INTO meta (key, value) VALUES ('gote_time', $(goteTime - usedTime + timeAdd))")
  SQLite.query(db, "UPDATE meta SET value = $(goteTime - usedTime + timeAdd) WHERE key='gote_time'")
end

#TRACING
board = generateCurrentBoard()
Base.eval(:(have_color=true))
#TRACEPRINT
#printBoard(board, false) #Removed the print hands because they were in wrong positions, and I already put them in print board.
