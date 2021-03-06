#=
server.jl <port> will start an interactive game
session, facilitating a connection between two
players. The server should listen on the port
given. The server makes no moves, only makes
sure that two players connecting to it can play the
game. This should mean passing messages from
one player to another, and declaring the winner.
You need to handle disconnects gracefully. A disconnect
terminates the game. You only need to
handle one game at a time.

"<wincode>:<authString>:<movenum>:<movetype>:<sourcex>:<sourcey>
:<targetx>:<targety>:<option>:<cheating>:<targetx2>:<targety2>:<targetx3>:<targety3>"
The authstring is a secret code generated by the server that only the individual player knows.
The client/player must send this code with every move
=#

##IF sending from CLIENT

wcc_requestGame = "0"
wcc_quitGame = "1"
wcc_playMove = "2"
wcc_opponentCheating = "3"
wcc_badPayload = "10"
wcc_message = "M"

##IF sending from SERVER

# WINCODES
wcs_playerOne = "0"
wcs_playerTwo = "1"
wcs_serverQuits = "2"
wcs_draw = "3"
wcs_notYourTurn = "8"
wcs_yourTurn = "9"
wcs_badPayload = "10"
wcs_error = "e"

# LEGALITY
legal_cheating = "0"
legal_true = "1"

# GAME TYPE

game_standard = "S"
game_mini = "M"
game_chu = "C"
game_tenjiku = "T"

# MOVE TYPE
move_move = "1"
move_drop = "2"
move_resign = "3"

# OPTION
option_null = "0"
option_promote = "!"

# I_AM_CHEATING
cheating_null = "0"
cheating_true = "1"

# STATES
state_wait_first = "0"
state_wait_second = "1"
state_message_first = "2"
state_message_second = "3"
number_of_states = "4"
turn = "first"

portInitialized = false

function initialize()
  global portInitialized
  # global variables
  global state = state_wait_first
  # defaults to a standard game that is untimed and cheating not allowed.
  # default game parameters
  global game_type = game_standard
  global game_legality = legal_true
  # we will use value 0 for "unlimited"
  global game_total_time = "0"
  global game_turn_time = "0"
  global client_one_auth = ""
  global client_two_auth = ""

  global port = parse(Int, ARGS[1])
  if portInitialized == false
    global server = listen(port)
  end
  # first call to listen() will create a server waiting
  # for incoming connections on the specified port (2000)
  global socket1 = accept(server)
  # do not go on untill you receive a valid game request
  while state != state_wait_second
    global message = readline(socket1) # Check that this is an initialization message
    runStateMachine("first", message)
  end

  global socket2 = accept(server)
  # do not go on untill you receive a valid game request
  while state != state_message_first
    global message = readline(socket2)
    runStateMachine("second", message)
  end

  global turn = "first"
  portInitialized = true
end

function main()

  global port
  global server
  global socket1
  global message
  global socket2
  global turn

  while true
    println("in beginning of while true loop")
    if turn == "first"
      println("is first infinate??")
      try
        message = readline(socket1)
        runStateMachine(turn, message)
      catch
        close(socket1)
        close(socket2)
        initialize()
      end
      turn = "second"
    else
      println("is second infinate??")
      try
        message = readline(socket2)
        runStateMachine(turn, message)
      catch
        close(socket1)
        close(socket2)
        initialize()
      end
      turn = "first"
    end

  end
end

#"<request game>: <standard shogi>: <no cheating>: <100 seconds>: <10 seconds per turn>"
function runStateMachine(from, message)
  global state
  global game_type
  global game_legality
  global game_total_time
  global game_turn_time
  global client_one_auth
  global client_two_auth
  global socket1
  global socket2

  fields = split(message, ':')
  for i in 1 : length(fields)
    fields[i] = chomp(fields[i])
  end
  #TBR
  println("Entering state machine")
  println("State: $state")
  println("Message: $message")
  len = length(message)
  println("Message length: $len")
  #=
  println("Fields")
  for (index, value) in enumerate(fields)
    println("$index $value")
  end
  =#

  if state == state_wait_first
    println("state = state_wait_first")
    # the only valid message is "game initialization"
    if fields[1] != wcc_requestGame
      #send error message
      if from == "first"
        write(socket1, "e:You didn't register a game\n")
      else
        write(socket2, "e:You didn't register a game\n")
      end
      return
    end
    # go throug requested game parameters
    # if any of them is not valid, do not send back an error message
    # just leave a default value that is already pre-set
    if length(fields) > 1
      if fields[2] == game_standard || fields[2] == game_mini || fields[2] == game_chu || fields[2] == game_tenjiku
        game_type = fields[2]
      end
    end

    if length(fields) > 2
      if fields[3] == legal_cheating || fields[3] == legal_true
        game_legality = fields[3]
      end
    end

    if length(fields) > 3
      game_total_time = fields[4] # parse(Int64, fields[4])
    end

    if length(fields) > 4
      game_turn_time = fields[5] #parse(Int64, fields[5])
    end

    # generate authentication code for the client
    client_one_auth = randstring()
    # send back confirmation message with game parameters
    reply = string(wcs_playerOne, ":", client_one_auth, ":", game_type, ":", game_legality, ":", game_total_time, ":", game_turn_time, "\n")
    println("HERE IS THE NEXT MOVE/MESSAGE!!!!! : $reply")
    write(socket1, reply)

    # change state
    state = state_wait_second
  elseif state == state_wait_second
    println("state = state_wait_second")
    if fields[1] == wcc_requestGame
      client_two_auth = randstring()
    else
      write(socket2, "e:You didn't register a game\n")
      return
    end

    reply = string(wcs_playerTwo, ":", client_two_auth, ":", game_type, ":", game_legality, ":", game_total_time, ":", game_turn_time, "\n")
    println("HERE IS THE NEXT MOVE/MESSAGE!!!!! : $reply")
    write(socket2, reply)

    state = state_message_first
  elseif state == state_message_first || state == state_message_second
     println("state is message first OR message second")
    # once connected to the server,
    # clients can send each other custom messages at any time
    if fields[1] == wcc_message
      # if sent by client one, pass it to client two
      if fields[2] == client_one_auth
        reply = string(fields[1], ":", client_two_auth, ":", fields[3], "\n")
        println("HERE IS THE NEXT MOVE/MESSAGE!!!!! : $reply")
        write(socket2, reply) ################################################################################TODO
      elseif fields[2] == client_two_auth
        reply = string(fields[1], ":", client_one_auth, ":", fields[3], "\n")
        println("HERE IS THE NEXT MOVE/MESSAGE!!!!! : $reply")
        write(socket1, reply) ################################################################################TODO
      end
      return
    end

    if fields[1] == wcc_requestGame
      if from == "first"
        write(socket1, "e:Invalid wincode\n")
      elseif from == "second"
        write(socket2, "e:Invalid wincode\n")
      end
      return
    end

    if fields[1] == wcc_quitGame || fields[1] == wcc_opponentCheating

      close(socket1)
      close(socket2)
      initialize()
      main()
      return
    end

    if fields[1] == wcc_badPayload
      if from == "first"
        write(socket2, "e:Bad payload\n")
      elseif from == "second"
        write(socket1, "e:Bad payload\n")
      end
      return
    end

    if fields[1] != wcc_playMove
      if from == "first"
        write(socket1, "e:Bad payload\n")
      elseif from == "second"
        write(socket2, "e:Bad payload\n")
      end
      return
    end

    # wincode is correct
    if state == state_message_first
      # make sure that we received a move message from player one

      if fields[2] == client_two_auth
        reply = string(wcs_notYourTurn, ":", fields[2], "\n")
        println("HERE IS THE NEXT MOVE/MESSAGE!!!!! (socket2) : $reply")
        write(socket2, reply)
        return
      end


      if fields[2] == client_one_auth
        # we have a valid "move" message sent from client one
        # pass it to client two
        reply = replace(message, client_one_auth, client_two_auth)
        println("HERE IS THE NEXT MOVE/MESSAGE, send from client 1 to 2 (288)!!!!! (socket2) : $reply")
        write(socket2, reply)
        # and wait for a message from client two
        state = state_message_second
      end
      return
    end

    if state == state_message_second
      # make sure that we received a move message from player two
#      -------------------------------------------------------------------------------THIS IS WRONG
      if fields[2] == client_one_auth
        reply = string(wcs_notYourTurn, ":", fields[2], "\n")
        println("HERE IS THE NEXT MOVE/MESSAGE!!!!! (socket1) : $reply")
        write(socket1, reply)
        return
      end


      if fields[2] == client_two_auth
        # we have a valid "move" message sent from client two
        # pass it to client one
        reply = replace(message, client_two_auth, client_one_auth)
        println("HERE IS THE NEXT MOVE/MESSAGE!!!!! send from client 2 to 1 (308) (socket1) : $reply")
        write(socket1, reply)
        # and wait for a message from client two
        state = state_message_first
      end
    end
  else
    println("Wrong state!")
  end
end

initialize()
main()
