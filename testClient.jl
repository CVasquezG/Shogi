
#include("packets.jl")

ip = ARGS[1]
port = parse(Int, ARGS[2])
order = parse(Int, ARGS[3])

function runclient()
  moveNumber = 1
  println("Connecting to the server")

  clientside = connect("$ip", port)
  message = "0:S:0:100:10"
  println(clientside,message)
  reply = readline(clientside)
  # get the auth string

  payload=split(reply,":")
  authString=payload[2]
  println("My auth string: $authString")

  println("Connected")
  println("Server message: $reply")

  if order == 1

    # wait for yser trigger
    println("Can I start?")
    readline(STDIN)
    #send the first move
    println("sending the first move")
    message = "2:$authString:$moveNumber:2:5:3:5:4:F:0:0:0:0:0"
    moveNumber = moveNumber + 1
    println(message)
    println(clientside,message)
  end

  for i=1:10
    # listen
    println("Waiting for move")
    reply = readline(clientside)
    println("Move received")
    println("Server message: $reply")
    if order == 1 && moveNumber == 7
      # send a terminate message
      println("sending the termination move")
      message = "1:$authString"
      println(message)
      println(clientside,message)
      println("Waiting for response")
      reply = readline(clientside)

      println("Response received")
      println("Server message: $reply")
      # exit the loop
      break
    end
    if order != 1 && moveNumber == 9
      # exit the loop
      break
    end
    println("sending the next move")
    message = "2:$authString:$moveNumber:2:5:3:5:4:F:0:0:0:0:0"
    moveNumber = moveNumber + 1
    println(message)
    println(clientside,message)
  end

  println("End of the test")

end

runclient()
