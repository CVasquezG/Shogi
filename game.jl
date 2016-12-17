using Blink

#=
  Initializes connection between client and server.
=#
function initialization(ip, port, cheating, timelimit, limitadd, game)
  global authString

  moveNumber = 1

  port = parse(Int, port)
  global clientside = connect("$ip", port) #connects client to server
  message = "0:$game:$cheating:$timelimit:$limitadd"
  println("-----------------------------------------------------SIX")
  println(clientside, message)          # Sends message to server
  reply = readline(clientside)          # Reply from server

  println("Connected - Server message: $reply")
  payload = split(reply,":")
  authString = payload[2]

  println("My auth string: $authString")
end

#=
  Makes the gameWindow fullScreen
=#
function fullScreen(window)
  position(window, 0, 0)
  size(window, 1366, 768)
end

#=
  This updates what we get from the server to the board.
  Parser message from server and does what we need to do with
  it based on the message.
=#
function parserOfMessage(reply)

  someMove = split(reply,":")

  sourcex = "$(parse(Int, someMove[5]))"
  sourcey = "$(parse(Int, someMove[6]))"
  targetx = "$(parse(Int, someMove[7]))"
  targety = "$(parse(Int, someMove[8]))"

  promotion = someMove[9]
  cheating = someMove[10]

  targetx2 = "$(parse(Int, someMove[11]))"
  targety2 = "$(parse(Int, someMove[12]))"

  targetx3 = "$(parse(Int, someMove[13]))"
  targety3 = "$(parse(Int, someMove[14]))"

  resetArgs()

  push!(ARGS, sourcex)
  push!(ARGS, sourcey)
  push!(ARGS, targetx)
  push!(ARGS, targety)
  push!(ARGS, promotion)

  if targetx2 != 0 && targetx2 != nothing
    push!(ARGS, targetx2)
    push!(ARGS, targety2)
  end
  if targetx3 != 0 && targetx3 != nothing
    push!(ARGS, targetx3)
    push!(ARGS, targety3)
  end

  #  @js w alert("in parserOfMessage!") # STACEY TODO - REMOVE THIS?

  println("--------------------------------------------------------------------EIGHT")
  println("SOME MOVE[4] = $(someMove[4])")


# TODO - should updateTable go in all these? Does update Table do what it is supposed to here? Am I doing this correctly?
  if someMove[4] == "2"
    include("move_user_move.jl")
      println("--------------------------------------------------------------------NINE")
    updateTable()
      println("--------------------------------------------------------------------TEN")
  elseif someMove[4] == "3"
    include("move_user_drop.jl")
    updateTable()
      println("--------------------------------------------------------------------SEVENTEEN")
  else
    include("move_user_resign.jl")
    updateTable()
      println("--------------------------------------------------------------------EIGHTEEN")
  end

  @js w alert("boardShould be updated.")  #TODO - Remove this once the board gets updated each turn STACEY
end

#=
  Creates a packet which will be sent to the Server and other client.
=#
function setNetPacket(moveNum, as, sourcex, sourcey, moveType, targetx, targety, option, cheating, targetx2, targety2, targetx3, targety3)

  wincode = 2
  authString = as
  mn = moveNum
  typeOfMove = moveType
  x = sourcex
  y = sourcey
  x1 = targetx
  y1 = targety
  promoted = option
  cheat = cheating
  x2 = targetx2
  y2 = targety2
  x3 = targetx3
  y3 = targety3

  payload = "$wincode:$authString:$mn:$typeOfMove:$x:$y:$x1:$y1:$promoted:$cheat:$x2:$y2:$x3:$y3\n"
  return payload
end

#=
  Getting info for netPacket from database.
  AI moves get written to database, so if AI
  is playing remotely, the info needs to be
  retrieved from database and put in a packet
  to be sent to the server.
=#
function setNetPacketDB(moveNum, as, filename)
  db = SQLite.DB(filename)
  #Always making a move
  wincode = 2
  authString = as
  mn = moveNum
  tOM = SQLite.query(db, "SELECT move_type FROM moves WHERE move_number = $moveNum;")
  typeOfMove=get(tOM[1][1])
  if typeOfMove =="move"
    typeOfMove = 1
  elseif typeOfMove =="drop"
    typeOfMove = 2
  elseif typeOfMove == "resign"
    typeOfMove = 3
  end
  sourcex = SQLite.query(db, "SELECT sourcex FROM moves WHERE move_number = $moveNum;")
  x = get(sourcex[1][1])
  sourcey = SQLite.query(db, "SELECT sourcey FROM moves WHERE move_number = $moveNum;")
  y = get(sourcey[1][1])
  targetx = SQLite.query(db, "SELECT targetx FROM moves WHERE move_number = $moveNum;")
  x1 = get(targetx[1][1])
  targety = SQLite.query(db, "SELECT targety FROM moves WHERE move_number = $moveNum;")
  y1 = get(targety[1][1])
  option = SQLite.query(db, "SELECT option FROM moves WHERE move_number = $moveNum;")
  if typeof(option[1][1])!= Nullable{Any}
    # ! or abrv of piece dropped
      promoted = get(option[1][1])
  else
    promoted= 0
  end
  #AI never cheats
  cheat = 0
  #these might not exits
  targetx2 = SQLite.query(db, "SELECT targetx2 FROM moves WHERE move_number = $moveNum;")
  if typeof(targetx2[1][1])!= Nullable{Any}
    # ! or abrv of piece dropped
    x2 = get(option[1][1])
  else
    x2 = 0
  end
  targety2 = SQLite.query(db, "SELECT targety2 FROM moves WHERE move_number = $moveNum;")
  if typeof(targety2[1][1])!= Nullable{Any}
    # ! or abrv of piece dropped
    y2 = get(option[1][1])
  else
    y2 = 0
  end
  targetx3 = SQLite.query(db, "SELECT targetx3 FROM moves WHERE move_number = $moveNum;")
  if typeof(targetx3[1][1])!= Nullable{Any}
    # ! or abrv of piece dropped
    x3 = get(targetx3[1][1])
  else
    x3 = 0
  end
  targety3 = SQLite.query(db, "SELECT targety3 FROM moves WHERE move_number = $moveNum;")
  if typeof(targety3[1][1])!= Nullable{Any}
    # ! or abrv of piece dropped
    y3 = get(targety3[1][1])
  else
    y3 = 0
  end

  payload = ("$wincode:$authString:$mn:$typeOfMove:$x:$y:$x1:$y1:$promoted:$cheat:$x2:$y2:$x3:$y3")
  println(payload)

  return payload
end

#only for making moves
function setNetPacketResign(moveNum, as, sourcex, sourcey, moveType, targetx, targety, option, cheating, targetx2, targety2, targetx3, targety3)

  wincode = 1
  authString = as
  mn = moveNum
  typeOfMove = moveType
  x = sourcex
  y = sourcey
  x1 = targetx
  y1 = targety
  promoted = option
  cheat = cheating
  x2 = targetx2
  y2 = targety2
  x3 = targetx3
  y3 = targety3

  payload = ("$wincode:$authString:$mn:$typeOfMove:$x:$y:$x1:$y1:$promoted:$cheat:$x2:$y2:$x3:$y3")

  println(payload)
  return payload
end


ARGS =fill("",6) #create ARGS array to pass parameters to the other julia files.
filename =""
game =""
gameTypeN=""
cheating =""
timelimit=""
limitadd=""
gameDifficulty = ""
filp = ""
goFirst =""
gameChosen = ""
ip = ""
port = ""
reply =""
startWindow = Window()
sleep(3)
load!(startWindow,"GUI/js/jquery-1.10.1.min.js")
load!(startWindow,"GUI/js/json3.min.js")
load!(startWindow,"GUI/js/generateBoard.js")
load!(startWindow,"GUI/css/startWindow.css")

sleep(3)
# tools(startWindow)
fullScreen(startWindow)

# PUN GRABBING
f = open("puns.txt")
lines = readlines(f)
i = rand(1:length(lines))
pun = lines[i]
close(f)
# END PUN GRABBING

body!(startWindow, string("


<h1>ShogiXTreme-o-Rama</h1>


<div id='holder'>

<div class='button' onclick='startNewGame()'>
    <p class='btnText'>NEW GAME</p>
    <div class='btnTwo'>
      <p class='btnText2'>GO!</p>
    </div>
 </div>
            <form>
                <div class='group'>
         <input type='text' id='fileText' placeholder='File Name'><span class='highlight'></span><span class='bar'></span>
        <!--   <label>File Name</label> -->
       </div>

</form>
    <div class='button' onclick='contGame()'>
    <p class='btnText'>Continue Game</p>
    <div class='btnTwo'>
      <p class='btnText2'>GO!</p>
    </div>
 </div>

    <div class='button' onclick='replayGame()'>
    <p class='btnText'>Replay Game</p>
    <div class='btnTwo'>
      <p class='btnText2'>GO!</p>
    </div>
 </div>


<div class='button' onclick='exit()'>
    <p class='btnText'>QUIT</p>
    <div class='btnTwo'>
      <p class='btnText2'>X</p>
    </div>
 </div>

</div>

<div class='tilt'>
    <div  id='puns' class='pop'> ", pun, "</div>
</div>

"))

status =""
while status != "exit"
    sleep(0.01)
    status = @js startWindow statusJS
    if status == "newGame"
        println("new Game clicked")
        break
        #status = @js startWindow resetStatus()
    end
    if status == "contGame"
        println("continue game clicked")
        filename = @js startWindow contGame()
        break
        #status = @js startWindow resetStatus()
    end

    if status == "replayGame"
      println("replay game clicked")
      filename = @js startWindow replayGame()
      break
      #status = @js startWindow resetStatus()
    end
end

if status == "exit"
  quit()
end

close(startWindow)

ARGS[1] = filename

if status == "newGame"
  newGameWindow = Window()

  sleep(3)
  load!(newGameWindow,"GUI/js/jquery-1.10.1.min.js")
  load!(newGameWindow,"GUI/js/json3.min.js")
  load!(newGameWindow,"GUI/js/generateBoard.js")
  load!(newGameWindow,"GUI/css/newGame.css")

  sleep(3)
  # tools(newGameWindow)
  fullScreen(newGameWindow)
  body!(newGameWindow, "

    <h1>Create New Game</h1>

    <div class='container'>
        <h2>Select type of Game:</h2>
<!--
        <input type='button' onclick='remoteGameAI()' value='Remote(AI)'>
        <input type='button' onclick='remoteGameP()' value='Remote(Player)'>
        <input type='button' onclick='localP()' value='Local(Player)'>
        <input type='button' onclick='localAI()' value='Local(AI)'>
        <input type='button' onclick='HostP()' value='Host(Player)'>
        <input type='button' onclick='HostAI()' value='Host(AI)'>
-->
        <input  type='radio' name='rb' id='rb1'  onclick='remoteGameAI()' />
        <label class ='radLabel' for='rb1'>Remote(AI)</label>
        <input  type='radio' name='rb' id='rb2' onclick='remoteGameP()' />
        <label class ='radLabel' for='rb2'>Remote(Player)</label>
        <input type='radio' name='rb' id='rb3' onclick='localP()' />
        <label class ='radLabel' for='rb3'>Local(Player)</label>
        <input type='radio' name='rb' id='rb4'  onclick='localAI()'/>
        <label class ='radLabel' for='rb4'>Local(AI)</label>
        <input  type='radio' name='rb' id='rb5' onclick='HostP()'/>
        <label class ='radLabel' for='rb5'>Host(Player)</label>
        <input  type='radio' name='rb' id='rb6' onclick='HostAI()'/>
        <label class ='radLabel' for='rb6'>Host(AI)</label>
    </div>

<div class='choicesGame'>
<!--
    <div class='nameGame'>
        <label for='fileText'>File Name:</label>
        <input type='text' id='fileText' placeholder='Enter file name'>
    </div>
-->

    <div id='inputholder'>
        <div class='group'>
         <input class='ripInput' type='text' id='fileText' placeholder='File Name'><span class='highlight'></span><span class='bar'></span>
<!--        <label class='ripLabel'>File Name</label>-->
       </div>
    </div>


<!--    SELECT  OPTIONS-->

<div class='typeGame'>
  <div class='sel sel--black-panther'>
  <select name='select-profession' id='gameType'>
    <option value='' >Type of Shogi</option>
    <option value='Mini'>Mini</option>
    <option value='Shogi'>Shogi</option>
    <option value='Chu'>Chu</option>
    <option value='Tenjiku'>Tenjiku</option>
  </select>
</div>
</div>


<div class='difficultyGame'>
  <div class='sel sel--black-panther'>
  <select name='select-profession' id='gameDifficulty'>
    <option value='' disabled>Difficulty</option>
    <option value='Normal'>Normal</option>
    <option value='Hard'>Hard</option>
    <option value='Suicidal'>Suicidal</option>
    <option value='Protracted_Death'>Protracted death</option>
    <option value='Random_AI'>Random AI</option>
  </select>
</div>
    </div>


<!--    CHECK BOXES -->
<div class= 'checkB'>
    <div class='cheatGame'>
        <input type='checkbox' name='cb' id='cheatcheckbox' />
        <label class='ckLabel' for='cheatcheckbox'>Cheating</label>

    </div>

    <div class='flipGame'>
        <input type='checkbox' name='cb' id='flipcheckbox' />
        <label class='ckLabel' for='flipcheckbox'>Japanese roulette mode</label>
    </div>
    <div class='goFirst'>
         <input type='checkbox' name='cb' id='goFirstcheckbox' />
        <label class='ckLabel' for='goFirstcheckbox'>Go first</label>

    </div>

</div>


<!--TEXT INPUTS-->

<!--
    <div class='timeLimGame'>
        <label for='timeLimit'>Time Limit:</label>
        <input type='number' min='0' id='timeLimit' placeholder='Optional' value='0'>
    </div>
-->


    <div id='inputholder'>
        <div class='group'>
         <input class='ripInput' type='number'  min='0' id='timeLimit' placeholder='Time Limit'><span class='highlight'></span><span class='bar'></span>
<!--        <label class='ripLabel'>Time Limit</label>-->
       </div>
    </div>



<!--
    <div class='timeIncGame'>
        <label for='timeInc'>Time Increment:</label>
        <input type='number' min='0' id='timeInc' placeholder='Optional' value='0'>
    </div>
-->

        <div id='inputholder'>
        <div class='group'>
         <input class='ripInput' type='number'  min='0' id='timeInc' placeholder='Time Increment'><span class='highlight'></span><span class='bar'></span>
<!--        <label class='ripLabel'>Time Limit</label>-->
       </div>
    </div>



<!--
    <div class='ip_addr'>
        <label for='fileText'>IP Address:</label>
        <input type='text' id='ipText' placeholder='Enter IP Address'>
    </div>

-->

    <div id='inputholder' class='ip_addr'>
        <div class='group'>
         <input class='ripInput' type='text' id='ipText' placeholder='Enter IP Address'><span class='highlight'></span><span class='bar'></span>
<!--        <label class='ripLabel'>Time Limit</label>-->
       </div>
    </div>

<!--
    <div class='port_num'>
        <label for='fileText'>Port Number:</label>
        <input type='text' id='portText' placeholder='Enter Port Number'>
    </div>
-->

       <div id='inputholder' class='port_num'>
        <div class='group'>
         <input class='ripInput' type='text' id='portText' placeholder='Enter Port Number'><span class='highlight'></span><span class='bar'></span>
<!--        <label class='ripLabel'>Time Limit</label>-->
       </div>
    </div>


<!--    CONTINUE BUTTON-->
  <div class='button' onclick='getValues()'>
    <p class='btnText'>create game</p>
    <div class='btnTwo'>
      <p class='btnText2'>GO!</p>
    </div>
 </div>

  </div>
<!--    STUFF FROM NEW WINDOW-->




<script>

    /* ===== Logic for creating fake Select Boxes ===== */
\$('.sel').each(function() {
  \$(this).children('select').css('display', 'none');

  var \$current = \$(this);

  \$(this).find('option').each(function(i) {
    if (i == 0) {
      \$current.prepend(\$('<div>', {
        class: \$current.attr('class').replace(/sel/g, 'sel__box')
      }));

      var placeholder = \$(this).text();
      \$current.prepend(\$('<span>', {
        class: \$current.attr('class').replace(/sel/g, 'sel__placeholder'),
        text: placeholder,
        'data-placeholder': placeholder
      }));

      return;
    }

    \$current.children('div').append(\$('<span>', {
      class: \$current.attr('class').replace(/sel/g, 'sel__box__options'),
      text: \$(this).text()
    }));
  });
});

// Toggling the `.active` state on the `.sel`.
\$('.sel').click(function() {
  \$(this).toggleClass('active');
});

// Toggling the `.selected` state on the options.
\$('.sel__box__options').click(function() {
  var txt = \$(this).text();
  var index = \$(this).index();

  \$(this).siblings('.sel__box__options').removeClass('selected');
  \$(this).addClass('selected');

  var \$currentSel = \$(this).closest('.sel');
  \$currentSel.children('.sel__placeholder').text(txt);
  \$currentSel.children('select').prop('selectedIndex', index + 1);
});


</script>


        ")

  # What is being selected : Host, Remote, no connection
  status =""
  while status != "exit"
    sleep(0.01)
    status = @js newGameWindow statusJS

    if status == "continue"
      println("continue game clicked")
      @js newGameWindow getValues()
      filename = @js newGameWindow filenameJS
      game =@js newGameWindow gameTypeJS
      cheating =@js newGameWindow cheatingJS
      timelimit=@js newGameWindow timelimitJS
      limitadd=@js newGameWindow limitaddJS
      gameDifficulty = @js newGameWindow difficultyJS
      flip = @js newGameWindow flipJS
      goFirst = @js newGameWindow goFirstJS
      gameChosen = @js newGameWindow gameChosenJS
      ip = @js newGameWindow ipJS
      port = @js newGameWindow portJS
      break
    end
  end

  @printf("Filename: %s\nType: %s\nCheating: %s\nTimelimit: %s\nLimitadd: %s\n",filename,game,cheating=="T"?"on":"off", timelimit, limitadd)

  ARGS[1] = filename
  ARGS[2] = game #get first char of string
  ARGS[3] = cheating
  ARGS[4] = timelimit
  ARGS[5] = limitadd
  include("start.jl")


  # What kind of game chosen by user and initializingGame
  if gameChosen == "localP"
    println("localP")
  elseif gameChosen == "localAI"
    println("localAI")
  elseif gameChosen == "HostP"
    ARGS[1]=port
    @async include("server.jl")
    ip = "127.0.0.1"
    reply = initialization(ip, port, cheating, timelimit, limitadd, game)
    println("HostP")
  elseif gameChosen == "HostAI"
    ARGS[1]=port
    @async include("server.jl")
    ip = "127.0.0.1"
    reply = initialization(ip, port, cheating, timelimit, limitadd, game)
    println("HostAI")
  elseif gameChosen == "remoteGameAI"
    reply = initialization(ip, port, cheating, timelimit, limitadd, game)
    println("remoteGameAI")
  elseif gameChosen == "remoteGameP"
    reply = initialization(ip, port, cheating, timelimit, limitadd, game)
    println("remoteGameP")
  end

#Send each move to other player -- loop until resign

  close(newGameWindow)
elseif status == "replayGame"
  sleep(3)
  replayWindow = Window()
  include("dependencies.jl")
  load!(replayWindow,"GUI/js/json3.min.js")
  load!(replayWindow,"GUI/js/jquery-1.10.1.min.js")
  load!(replayWindow,"GUI/js/generateBoard.js")
  load!(replayWindow,"GUI/css/board.css")
  sleep(3)

  body!(replayWindow, "


   <div class='moveItems'>


   <div class='paper'  onclick='nextMove()'>
      <p id='num'>Next Move</p>
      <div class='ripple'></div>
   </div>

   <div class='paper'  onclick='prevMove()'>
      <p id='num'>Prev Move</p>
      <div class='ripple'></div>
   </div>


    </div>



<div class='mainGame'>
  <div id='currentPlayer'></div>
  <div id='dvBHand'> </div>
  <div id='dvTable'> </div>
  <div id='dvWHand'> </div>
</div>


    <div class='button' onclick='exit()'>
    <p class='btnText'>EXIT</p>
    <div class='btnTwo'>
      <p class='btnText2'>X</p>
    </div>
 </div>




<!--    SCRIPT FOR BUTTONS -->
    <script>

    \$(document).ready(function() {
   \$('.paper').mousedown(function(e) {
      var ripple = \$(this).find('.ripple');
      ripple.removeClass('animate');
      var x = parseInt(e.pageX - \$(this).offset().left) - (ripple.width() / 2);
      var y = parseInt(e.pageY - \$(this).offset().top) - (ripple.height() / 2);
      ripple.css({
         top: y,
         left: x
      }).addClass('animate');
   });
});

</script>


  ")

  board_step=initBoard()
  moveNum_step=0

  db = SQLite.DB(ARGS[1])
  res = SQLite.query(db, "SELECT COUNT(*) FROM moves;")
  i = get(res[1][1])

function fillJSBoard_replay(board::Board)
  boardArray = board.boardArray
 # println("current player", getCurrentPlayer(board))
 # printHand(board, BLACK)
 @js replayWindow setPlayer($(getCurrentPlayer(board)))
  for j = BOARD_DIMENSIONS:-1:1
      for i= 1:BOARD_DIMENSIONS
      # add piece to item array in js
      @js replayWindow item.push($(boardArray[i,j]))
      end
      # add row to boardJS
      @js replayWindow boardJS.push(item.slice())
      @js replayWindow item.splice(0)
  end
end

function fillJSPlayerHand_replay(board::Board, player::AbstractString)
  handB = board.blackHand
  handW = board.whiteHand
  if player =="Black"
    for i= 1:length(handB)
      @js replayWindow blackHandJS.push($(handB[i]))
    end
  elseif player == "White"
    for i= 1:length(handW)
      @js replayWindow whiteHandJS.push($(handW[i]))
    end
  end
end

fillJSBoard_replay(board_step)
fillJSPlayerHand_replay(board_step,"Black")
fillJSPlayerHand_replay(board_step,"White")
@js replayWindow generateTable()

# tools(replayWindow)
fullScreen(replayWindow)
  status =""
  while status != "exit"
      sleep(0.01)
      status = @js replayWindow statusJS

      if status == "nextMove"
        println("next move clicked")
        if moveNum_step + 1 <=i && moveNum_step + 1 >=1
        moveNum_step = moveNum_step + 1
        else
        @js replayWindow alert("No board to display")
        status = @js replayWindow resetStatus()
        continue
        end
        board_step = generateNextBoard(board_step, db, moveNum_step)
        @js replayWindow deleteTables()
        fillJSBoard_replay(board_step)
        fillJSPlayerHand_replay(board_step,"White")
        fillJSPlayerHand_replay(board_step,"Black")
        status = @js replayWindow resetStatus()
        @js replayWindow generateTable()
      end
      if status == "prevMove"
        println("previous move clicked")
        if moveNum_step - 1 <=i && moveNum_step - 1 >=0
          moveNum_step = moveNum_step - 1
        else
          @js replayWindow alert("No board to display")
          status = @js replayWindow resetStatus()
          continue
        end
        println(moveNum_step)
        if moveNum_step != 0
           board_step = initBoard()
          for move in 1:moveNum_step
            board_step = generateNextBoard(board_step, db, move)
          end
        else
          board_step = initBoard()
        end

        @js replayWindow deleteTables()
        fillJSBoard_replay(board_step)
        fillJSPlayerHand_replay(board_step,"White")
        fillJSPlayerHand_replay(board_step,"Black")

        status = @js replayWindow resetStatus()
        @js replayWindow generateTable()

      end

        # println(moveNum_step)


        #         board_step = generateNextBoard(board_step, db, moveNum_step)
        # @js replayWindow deleteTables()
        # fillJSBoard_replay(board_step)
        # fillJSPlayerHand_replay(board_step,"White")
        # fillJSPlayerHand_replay(board_step,"Black")
        # status = @js replayWindow resetStatus()
        # @js replayWindow generateTable()

  end
  close(replayWindow)
  quit()

end

ARGS[1] = filename


#DISPLAYING BOARD
w = Window()
sleep(3)
include("dependencies.jl")
load!(w,"GUI/js/jquery-1.10.1.min.js")
load!(w,"GUI/js/json3.min.js")
load!(w,"GUI/js/generateBoard.js")
#load!(w,"GUI/js/drag.js")
load!(w,"GUI/css/board.css")

include("constants.jl")
difficulty = gameDifficulty

sleep(3)

body!(w, "




 <div class='moveItems'>
   <div class='paper'id='btnRefresh' onclick='generateTable()'>
      <p id='num'>Refresh</p>
      <div class='ripple'></div>
   </div>

   <div class='paper' id='btnMove' onclick='makeMove()'>
      <p id='num'>Make Move</p>
      <div class='ripple'></div>
   </div>

      <div class='promotePiece' id='promChk'>
        <input type='checkbox' name='cb' id='promoteCheckBox' />
        <label class='ckLabel' for='promoteCheckBox'>Promote</label>
    </div>
    </div>

    <div class='optItems'>
   <div class='paper' onclick='resign()'>
      <p id='num'>Resign</p>
      <div class='ripple'></div>
   </div>

   <div class='paper' onclick='winCheck()'>
      <p id='num'>Check Win</p>
      <div class='ripple'></div>
   </div>

   <div class='paper'  onclick='email()'>
      <p id='num'>Send Game by Email</p>
      <div class='ripple'></div>
   </div>

   <div class='paper'  onclick='tips()'>
      <p id='num'>Tips</p>
      <div class='ripple'></div>
   </div>

    </div>

<!--    LOADING THING -->
<div class='loader'>
    <h1>Making a move</h1>
    <span></span>
    <span></span>
    <span></span>
</div>




<!--    SCRIPT FOR BUTTONS -->
    <script>

    \$(document).ready(function() {
   \$('.paper').mousedown(function(e) {
      var ripple = \$(this).find('.ripple');
      ripple.removeClass('animate');
      var x = parseInt(e.pageX - \$(this).offset().left) - (ripple.width() / 2);
      var y = parseInt(e.pageY - \$(this).offset().top) - (ripple.height() / 2);
      ripple.css({
         top: y,
         left: x
      }).addClass('animate');
   });
});

</script>



<div class='mainGame'>
  <div id='currentPlayer'></div>
  <div id='aiComments'></div>
  <div id='dvBHand'> </div>
  <div id='dvTable'> </div>
  <div id='dvWHand'> </div>
</div>


  <div class='button' onclick='exit()'>
    <p class='btnText'>EXIT</p>
    <div class='btnTwo'>
      <p class='btnText2'>X</p>
    </div>
 </div>


")

#☖☗
board = generateCurrentBoard()

###################################################################################
########FUNCTION FOR FINDING LEGAL MOVE SQUARES############
#=It returns an array of tuples, containing the coordinates=#
function findLegalTarget(board::Board, x::Int, y::Int)
  legal = legalMovesForSpace(board, x, y)
  locations = Array{Any}(0)
  for move in legal
    if move.targetx3 != nothing
      push!(locations, [(move.targetx, move.targety), (move.targetx2, move.targety2), (move.targetx3, move.targety3)] )
    elseif move.targetx2 != nothing
      push!(locations, [(move.targetx, move.targety), (move.targetx2, move.targety2), (nothing, nothing)] )
    else
      push!(locations, [(move.targetx, move.targety), (nothing, nothing), (nothing, nothing)] )
    end
  end
  return locations
end

function canPromote(player::AbstractString, y::Int)
  if player == WHITE
    if y >= PROMOTION_TOP
      return true
    else
      return false
    end
  elseif player == BLACK
    if y <= PROMOTION_BOTTOM
      return true
    else
      return false
    end
  end
end

function canPromote(board::Board, player::AbstractString, sourcex::Int, sourcey::Int, targety::Int)
  piece = getPiece(board, sourcex, sourcey)
  promPiece = isPromoteablePiece(piece)###returns true if piece has the option to promote

  if player == WHITE
    if targety >= PROMOTION_TOP && promPiece ##if piece is within the promotionzone as well as able to promote
      return true
    else
      return false
    end
  elseif player == BLACK
    if targety <= PROMOTION_BOTTOM && promPiece
      return true
    else
      return false
    end
  end

end


##################################################################################
##################################################################################

function assignArgIfDefined(argsIndex)
  if isdefined(ARGS, argsIndex)
    try
      return ARGS[argsIndex]
    catch
      return ARGS[argsIndex]
    end
  else
    return nothing
  end
end

function argsToMovementMove()
  moveType = MOVETYPE_MOVEMENT
  sourcex = parse(Int, ARGS[2])
  sourcey = parse(Int, ARGS[3])
  targetx = parse(Int, ARGS[4])
  targety = parse(Int, ARGS[5])
  option = assignArgIfDefined(6)
  targetx2 = assignArgIfDefined(7)
  if targetx2 != nothing
    targetx2 = parse(Int, targetx2)
  end
  targety2 = assignArgIfDefined(8)
  if targety2 != nothing
    targety2 = parse(Int, targety2)
  end
  targetx3 = assignArgIfDefined(9)
  if targetx3 != nothing
    targetx3 = parse(Int, targetx3)
  end
  targety3 = assignArgIfDefined(10)
  if targety3 != nothing
    targety3 = parse(Int, targety3)
  end

  return Move(moveType, sourcex, sourcey, targetx, targety, option, targetx2, targety2, targetx3, targety3)
end


function argsToDropMove()
  function numberOfMove()
    db = SQLite.DB(ARGS[1])
    res = SQLite.query(db, "SELECT COUNT(*) FROM moves;")
    x = get(res[1][1])
    return x
  end
  turnNum = numberOfMove()
  turnNum = turnNum%2
  color = ""
  if turnNum == 0
    color = BLACK
  else
    color = WHITE
  end

  moveType = MOVETYPE_DROP
  sourcex = nothing
  sourcey = nothing
  targetx = parse(Int, ARGS[3])
  targety = parse(Int, ARGS[4])
  option = Piece(color, ARGS[2])
  targetx2 = nothing
  targety2 = nothing
  targetx3 = nothing
  targety3 = nothing

  return Move(moveType, sourcex, sourcey, targetx, targety, option, targetx2, targety2, targetx3, targety3)
end





function fillJSBoard(board::Board)
  boardArray = board.boardArray
   # println("current player", getCurrentPlayer(board))
   # printHand(board, BLACK)
   @js w setPlayer($(getCurrentPlayer(board)))
    for j = BOARD_DIMENSIONS:-1:1
        for i= 1:BOARD_DIMENSIONS
        # add piece to item array in js
        @js w item.push($(boardArray[i,j]))
        end
        # add row to boardJS
        @js w boardJS.push(item.slice())
        @js w item.splice(0)
       # @printf("\n")
    end
  #  printHand(board, WHITE)
end

function fillJSPlayerHand(board::Board, player::AbstractString)
  handB = board.blackHand
  handW = board.whiteHand
  if player =="Black"
  for i= 1:length(handB)
    @js w blackHandJS.push($(handB[i]))
  end
elseif player == "White"
    for i= 1:length(handW)
     @js w whiteHandJS.push($(handW[i]))
  end
end
end

#@js w blackHandJS.push($(board.boardArray[1,1]));
#@js w blackHandJS.push($(board.boardArray[1,3]));
fillJSPlayerHand(board,"White")
fillJSPlayerHand(board,"Black")
fillJSBoard(board)
#opentools(w)
title(w,ARGS[1])
# tools(w)
fullScreen(w)

@js w generateTable();

#keep filename
function resetArgs()
  for i in 2:length(ARGS)
       pop!(ARGS)
  end
end

@js w setCheating($(getCheating(ARGS[1])))  # legal or cheating

moveType = 1  #mov 1   drpo 2 resig 3
moveNum  = board.turnNumber
cheating =  0 #0 not cheating 1 not cheating
currPlayer = getCurrentPlayer(board)

function updateTable()
  board = generateCurrentBoard()
  @js w deleteTables()
  fillJSBoard(board)
  fillJSPlayerHand(board,"White")
  fillJSPlayerHand(board,"Black")
  @js w movesArrayJS.splice(0)
  status = @js w resetStatus()
  @js w generateTable()
end

as = reply

if goFirst == "White"
  if gameChosen == "localAI" || gameChosen == "HostAI" || gameChosen=="remoteGameAI"
    @js w startLoadingAnimation()
    # AI MAKES MOVE
    include("move.jl")

    # GET THE MOVE THAT THE AI MADE(FROM THE DATABASE) AND SEND THE PACKET IF ITS A NETWORKING GAME
    filename=ARGS[1]
    if gameChosen == "HostAI" || gameChosen == "remoteGameAI"
      message = setNetPacketDB(moveNum, as, filename)
      updateTable()
      println("--------------------------------------------------------------FOURTEEN")
      println(clientside, message)
      println("Waiting for move")
      reply = readline(clientside)
      println("Move received")
      println("Server message: $reply")
      parserOfMessage(reply)
    end

    updateTable()
    @js w stopLoadingAnimation()
  end
end

#LOOP TO COMMUNICATE WITH WINDOW

status =""

while status != "exit"
  sleep(0.01)
  status = @js w statusJS

  currPlayer = @js w currentPlayer

  if status == "generateTable"
    println("Generate Table clicked")
    status = @js w resetStatus()
  end

  if status == "resign"
    println("Resign made")
    status = @js w resetStatus()
    include("move_user_resign.jl")
    @js w alert("You Resigned")
    if gameChosen == "HostP" || gameChosen=="HostAI"
      #disconnect
      close(clientside)
      #send resign packet
      message = setNetPacketResign(moveNum, as, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0)
      println("--------------------------------------------------------------FIFTEEN")
      println(clientside, message)
      println("Waiting for move")
      reply = readline(clientside)
      println("Move received")
      println("Server message: $reply")
      parserOfMessage(reply)
    end
    if gameChosen == "remoteGameAI" || gameChosen== "remoteGameP"
      #send resign packet
      message = setNetPacketResign(moveNum, as, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0)
      println("--------------------------------------------------------------SIXTEEN")
      println(clientside, message)
      println("Waiting for move")
      reply = readline(clientside)
      println("Move received")
      println("Server message: $reply")
      parserOfMessage(reply)
    end
    break
  end

  if status == "movejl"
    println("movejl clicked")
    include("move.jl")
    updateTable()
    status = @js w resetStatus()
  end

if status == "email"
  println("Email clicked")
  msg= string(pwd())
  message=("This is the path to the gamefile: $msg")
  @js w alert($message)
  status = @js w resetStatus()
end

if currPlayer != goFirst && (gameChosen == "localAI" || gameChosen == "HostAI" || gameChosen=="remoteGameAI")

 @js w startLoadingAnimation()
  #AI MAKES MOVE
  include("move.jl")
  #GET THE MOVE THAT THE AI MADE(FROM THE DATABASE) AND SEND THE PACKET IF ITS A NETWORKING GAME
  filename=ARGS[1]
  if gameChosen == "HostAI" || gameChosen == "remoteGameAI"
    message = setNetPacketDB(moveNum, as, filname)
    updateTable()
    println(message)
    println("--------------------------------------------------------------NINETEEN")
    println(clientside, message)

    println("Waiting for move")
    reply = readline(clientside)
    println("Move received")
    println("Server message: $reply")
    parserOfMessage(reply)
  end

  updateTable()
  status = @js w resetStatus()
  @js w stopLoadingAnimation()
  elseif status == "makeMove"
    #USER MAKING MOVE
    resetArgs()
    println("make move clicked")
    arr = @js w movesArrayJS #array with moves user wants to do.
    promotion = @js w promotePieceJS #either T or F
    board = generateCurrentBoard()
    moveNum = board.turnNumber

    println(arr)

    if length(arr) == 2
      push!(ARGS,split(arr[1],",")[1])
      push!(ARGS,split(arr[1],",")[2])
      push!(ARGS,split(arr[2],",")[1])
      push!(ARGS,split(arr[2],",")[2])
      push!(ARGS,promotion)

      if gameChosen == "HostP" || gameChosen == "remoteGameP"
          updateTable()
          println("sending the next move")
          message = setNetPacket(moveNum, authString, ARGS[2], ARGS[3], 2, ARGS[4], ARGS[5], ARGS[6], cheating, 0, 0, 0, 0)
          println(message)
          updateTable()
          println("--------------------------------------------------------------FIVE")
          println(clientside, message)

          println("Waiting for move")
          reply = readline(clientside)
          println("Move received")
          println("Server message: $reply")
          parserOfMessage(reply)
      end

    elseif length(arr) == 3
      push!(ARGS,split(arr[1],",")[1])
      push!(ARGS,split(arr[1],",")[2])
      push!(ARGS,split(arr[2],",")[1])
      push!(ARGS,split(arr[2],",")[2])
      push!(ARGS,promotion)
      push!(ARGS,split(arr[3],",")[1])
      push!(ARGS,split(arr[3],",")[2])

    if gameChosen == "HostP" || gameChosen == "remoteGameP"
      message = setNetPacket(moveNum, as, ARGS[2], ARGS[3], 1, ARGS[4], ARGS[5], ARGS[6], cheating, ARGS[7], ARGS[8], 0, 0)
      updateTable()
      println("--------------------------------------------------------------ELEVEN")
      println(clientside, message)

      println("Waiting for move")
      reply = readline(clientside)
      println("Move received")
      println("Server message: $reply")
      parserOfMessage(reply)
    end

    elseif length(arr) == 4
      push!(ARGS,split(arr[1],",")[1])
      push!(ARGS,split(arr[1],",")[2])
      push!(ARGS,split(arr[2],",")[1])
      push!(ARGS,split(arr[2],",")[2])
      push!(ARGS,promotion)
      push!(ARGS,split(arr[3],",")[1])
      push!(ARGS,split(arr[3],",")[2])
      push!(ARGS,split(arr[4],",")[1])
      push!(ARGS,split(arr[4],",")[2])

      if gameChosen == "HostP" || gameChosen == "remoteGameP"
        message = setNetPacket(moveNum, as, ARGS[2], ARGS[3], 1, ARGS[4], ARGS[5], ARGS[6], cheating, ARGS[7], ARGS[8], ARGS[9], ARGS[10])
        println("--------------------------------------------------------------TWELVE")
        updateTable()
        println(clientside, message)
        println("Waiting for move")
        reply = readline(clientside)
        println("Move received")
        println("Server message: $reply")
        parserOfMessage(reply)
      end

    else
      @js w alert("INVALID MOVE. REJECTED!")
      @js w movesArrayJS.splice(0)
      status = @js w resetStatus()
      continue
    end

    if gameChosen == "remoteGameAI" || gameChosen == "HostAI"

      message = setNetPacketDB(moveNum, as, filwname)
      println("--------------------------------------------------------------THIRTEEN")
      println(clientside, message)
      updateTable()


      reply = readline(clientside)
      println("Move received")
      println("Server message: $reply")
      parserOfMessage(reply)

    end

    if gameChosen == "remoteGameAI" || gameChosen == "HostAI" || gameChosen =="localAI" && moveNum >1
      #Toren - Alert with AI's opinion of the move
      move = argsToMovementMove()
      moveWorth = getMoveWorth(board, move)
      @js w setAIcomments( $moveWorth )
    end

    println(ARGS)
    include("move_user_move.jl")
    # include("validate.jl")
    # @js w alert("Valid result: " + $resultValidate)
    updateTable()
    status = @js w resetStatus()
  end

  if status == "makeDrop"
    #where drops are made
    resetArgs()
    arr = @js w movesArrayJS #Color:piece:hand , x1,y1
    # @js w alert($arr)

    board = generateCurrentBoard()
    moveNum = board.turnNumber

    if length(arr) == 2
      push!(ARGS,getDatabaseName(split(arr[1],":")[2]))
      push!(ARGS,split(arr[2],",")[1])
      push!(ARGS,split(arr[2],",")[2])
    else
      @js w alert("INVALID DROP. REJECTED!")
      @js w movesArrayJS.splice(0)
      status = @js w resetStatus()
      continue
    end

    #################################################################################################UPDATE THIS##########################################################################
    if gameChosen == "HostP" || gameChosen == "remoteGameP"
      message = setNetPacket(moveNum, as, ARGS[2], ARGS[3], 1, ARGS[4], ARGS[5], ARGS[6], cheating, ARGS[7], ARGS[8], ARGS[9], ARGS[10])
      println("--------------------------------------------------------------THIRTEEN")
      updateTable()
      println(clientside, message)


      reply = readline(clientside)
      println("Move received")
      println("Server message: $reply")
      parserOfMessage(reply)
    end

    if gameChosen == "remoteGameAI" || gameChosen == "HostAI"
      message = setNetPacketDB(moveNum, as, filename)
      println("--------------------------------------------------------------THIRTEEN")
      println(clientside, message)
      updateTable()



      reply = readline(clientside)
      println("Move received")
      println("Server message: $reply")
      parserOfMessage(reply)
    end

    if gameChosen == "remoteGameAI" || gameChosen == "HostAI" || gameChosen =="localAI" && moveNum >1
      #Toren - Alert with AI's opinion of the move
      move = argsToDropMove()
      moveWorth = getMoveWorth(board, move)
      @js w setAIcomments( $moveWorth )
    end


    println(ARGS)
    include("move_user_drop.jl")
    # include("validate.jl")
    # @js w alert("Valid result: " + $resultValidate)
    updateTable()

    status = @js w resetStatus()
  end

  if status == "getvalidJS"
    arr = @js w movesArrayJS
    board = generateCurrentBoard();
    legalArr = findLegalTarget(board,parse(Int,split(arr[1],",")[1]),parse(Int,split(arr[1],",")[2]))

    if length(legalArr) == 0
    @js w alertNoMoves()
    end
    @js w getValidArr($legalArr,1)

    status = @js w resetStatus()
  end

  if status == "tips"
	  f = open("tips.txt")
	  lines = readlines(f)
	  i = rand(1:length(lines))
	  tip = lines[i]
	  close(f)
	  @js w alert($tip)
    status = @js w resetStatus()
  end

  if status == "checkWin"
    include("win.jl")
    @js w alert("Win result: " + $resultWin)
    status = @js w resetStatus()
  end

  if status == "checkPromotionJS"
    newBoard = generateCurrentBoard()
    arr = @js w movesArrayJS
    xsource =  parse(Int,split(arr[1],",")[1])
    ysource = parse(Int,split(arr[1],",")[2])
    lastCoord = @js w promCoords
    yCoord = parse(Int,split(lastCoord,",")[2])
    cPlayer = @js w currentPlayer

    @js w setAllowPromotion($(canPromote(newBoard,cPlayer,xsource,ysource,yCoord)))
    # @js w setAllowPromotion($(canPromote(cPlayer, yCoord)))

    status = @js w resetStatus()
  end

end #end  loop

println("Exit clicked")
