// GLOBAL VARS
var boardJS = new Array();
var item = new Array();
var whiteHandJS = new Array();
var blackHandJS = new Array();
var statusJS; //changed at every function so julia know whats going on.
var currentPlayer
var cheat;
var allowPromotion;
var promCoords; //coords to check for promotion
var movesArrayJS = new Array();
var validArrJS = new Array();


function setAIcomments(comment){
    var element = document.getElementById("aiComments");
    element.innerHTML = comment;
}


function setCheating(cheatJulia){
    cheat =(cheatJulia)=="legal"?false:true; //legal or cheating
    if(cheat){
        $(".promotePiece").css("visibility","visible");
    }
}
function setAllowPromotion(allowProm){
    allowPromotion = allowProm;
    if(!cheat){
    if (allowProm == false){
        document.getElementById("promoteCheckBox").checked = false;
         $(".promotePiece").css("visibility","hidden");
    }
    else{
         $(".promotePiece").css("visibility","visible");
    }
    }
}

function startLoadingAnimation(){
    $(".loader").css("visibility","visible");
}
function stopLoadingAnimation(){
    $(".loader").css("visibility","hidden");
}

function alertNoMoves(){
        
    alert("No valid moves, hit refresh to select other piece");
}


function setPlayer(player) {
    currentPlayer = player
    document.getElementById("currentPlayer").innerHTML = player
}

function generateTable() {
    statusJS = "generateTable";
    movesArrayJS.splice(0)
        //Create a HTML Table element.
    var table = document.createElement('TABLE');
    var tableBlack = document.createElement('TABLE');
    var tableWhite = document.createElement('TABLE');
    table.id = "Board"
    tableBlack.id = "BHand"
    tableWhite.id = "WHand"
        //Get the count of columns.
    var columnCount = boardJS[0].length;
    var colBlackCount = blackHandJS.length;
    var colWhiteCount = whiteHandJS.length;
    //Add the data rows.
    for (var i = 0; i < boardJS.length; i++) {
        var row = table.insertRow(-1);
        for (var j = 0; j < columnCount; j++) {

            var cell = row.insertCell(-1);
            var dragDiv = document.createElement('div');
            var pieceDiv = document.createElement('div');

            cell.className = "element"
            cell.id = (j + 1) + ',' + Math.abs(i - boardJS.length);
            dragDiv.className = "cell"
            dragDiv.id = boardJS[i][j].color + ':' + boardJS[i][j].name + ':' + (j + 1) + ',' + Math.abs(i - boardJS.length);
            cell.onclick = function() {
                moveFunction(this);
            };
            pieceDiv.className = boardJS[i][j].color + 'Piece';

            if (boardJS[i][j].color == "Black") {
                var shogiDiv = document.createElement('div');
                shogiDiv.innerHTML = '☗'
                shogiDiv.className = 'Bshogi'
                pieceDiv.innerHTML = boardJS[i][j].name;
                dragDiv.draggable = true;
                dragDiv.appendChild(shogiDiv);
                dragDiv.appendChild(pieceDiv);
            } else if (boardJS[i][j].color == "White") {
                var shogiDiv = document.createElement('div');
                shogiDiv.innerHTML = '☖'
                shogiDiv.className = 'Wshogi'
                pieceDiv.innerHTML = boardJS[i][j].name;
                dragDiv.draggable = true;
                dragDiv.appendChild(shogiDiv);
                dragDiv.appendChild(pieceDiv);
            } else {
                var shogiDiv = document.createElement('div');
                shogiDiv.innerHTML = '.'
                shogiDiv.className = 'emptyPiece'
                pieceDiv.innerHTML = '.';
                dragDiv.draggable = false;
                dragDiv.appendChild(shogiDiv);
                dragDiv.appendChild(pieceDiv);
            }
            if (boardJS[i][j].name == "k") {
                pieceDiv.id = "King"
            }

            cell.appendChild(dragDiv);
        }
    }
    //add data to player hands tables
    var rowB = tableBlack.insertRow(-1);
    for (var i = 0; i < blackHandJS.length; i++) {
        var cell = rowB.insertCell(-1);
        var pieceDiv = document.createElement('div');
        var dragDiv = document.createElement('div');
        cell.className = "element"
        cell.id = blackHandJS[i].color + ':' + blackHandJS[i].name + ':hand';
        dragDiv.className = "cell"
        cell.onclick = function() {
            dropFunction(this);
        };
        pieceDiv.className = blackHandJS[i].color + 'Piece';
        dragDiv.id = blackHandJS[i].color + ':' + blackHandJS[i].name + ':hand';
        if (blackHandJS[i].color == "Black") {
            var shogiDiv = document.createElement('div');
            shogiDiv.innerHTML = '☗'
            shogiDiv.className = 'Bshogi'
            pieceDiv.innerHTML = blackHandJS[i].name;
            dragDiv.draggable = true;
            dragDiv.appendChild(shogiDiv);
        } else if (blackHandJS[i].color == "White") {
            var shogiDiv = document.createElement('div');
            shogiDiv.innerHTML = '☖'
            shogiDiv.className = 'Wshogi'
            pieceDiv.innerHTML = blackHandJS[i].name;
            dragDiv.draggable = true;
            dragDiv.appendChild(shogiDiv);

        }
        if (blackHandJS[i].name == "k") {
            pieceDiv.id = "King"
        }
        dragDiv.appendChild(pieceDiv);
        cell.appendChild(dragDiv);
    }
    //add data to player hands tables
    var rowW = tableWhite.insertRow(-1);
    for (var i = 0; i < whiteHandJS.length; i++) {
        var cell = rowW.insertCell(-1);
        var pieceDiv = document.createElement('div');
        var dragDiv = document.createElement('div');
        dragDiv.className = "cell"
        cell.className = "element"
        cell.onclick = function() {
            dropFunction(this);
        };
        cell.id = whiteHandJS[i].color + ':' + whiteHandJS[i].name + ':hand';
        pieceDiv.className = whiteHandJS[i].color + 'Piece';
        dragDiv.id = whiteHandJS[i].color + ':' + whiteHandJS[i].name + ':hand';
        if (whiteHandJS[i].color == "Black") {
            var shogiDiv = document.createElement('div');
            shogiDiv.innerHTML = '☗'
            shogiDiv.className = 'Bshogi'
            pieceDiv.innerHTML = whiteHandJS[i].name;
            dragDiv.draggable = true;
            dragDiv.appendChild(shogiDiv);
        } else if (whiteHandJS[i].color == "White") {
            var shogiDiv = document.createElement('div');
            shogiDiv.innerHTML = '☖'
            shogiDiv.className = 'Wshogi'
            pieceDiv.innerHTML = whiteHandJS[i].name;
            dragDiv.draggable = true;
            dragDiv.appendChild(shogiDiv);
        }
        if (whiteHandJS[i].name == "k") {
            pieceDiv.id = "King"
        }
        dragDiv.appendChild(pieceDiv);
        cell.appendChild(dragDiv);
    }

    var dvTable = document.getElementById('dvTable');
    dvTable.innerHTML = '';
    dvTable.appendChild(table);

    var dvBHand = document.getElementById('dvBHand');
    dvBHand.innerHTML = '';
    dvBHand.appendChild(tableBlack);

    var dvWHand = document.getElementById('dvWHand');
    dvWHand.innerHTML = '';
    dvWHand.appendChild(tableWhite);
}

function deleteTables() {
    console.log("updating")
    document.getElementById("dvBHand").removeChild(document.getElementById("BHand"))
    document.getElementById("dvTable").removeChild(document.getElementById("Board"))
    document.getElementById("dvWHand").removeChild(document.getElementById("WHand"))
    boardJS.splice(0)
    item.splice(0)
    whiteHandJS.splice(0)
    blackHandJS.splice(0)

}

//May be changed to something that can be annimated
function updateMoveJS(source, destination) {
    var dragDiv = document.createElement('div');
    var pieceDiv = document.createElement('div');
    dragDiv.className = "cell"
    pieceDiv.className = 'Piece';
    var shogiDiv = document.createElement('div');
    shogiDiv.innerHTML = '.'
    shogiDiv.className = 'emptyPiece'
    pieceDiv.innerHTML = '.';
    dragDiv.draggable = false;
    dragDiv.appendChild(shogiDiv);
    dragDiv.appendChild(pieceDiv);


    var shog = document.getElementById(source).removeChild(document.getElementById(source).firstChild);
    document.getElementById(source).appendChild(dragDiv)

    var dead = document.getElementById(destination).removeChild(document.getElementById(destination).firstChild);
    document.getElementById(destination).appendChild(shog)

    /*
    if(document.getElementById("currentPlayer").innerHTML == "Black"){
        document.getElementById("dvBHand").appendChild(dead);
    }else{
        document.getElementById("dvWHand").appendChild(dead);
    }*/

}



function movejl() {
    statusJS = "movejl";
}



//FOR START WINDOW
function startNewGame() {
    statusJS = "newGame"

}

// function contGame() {
//     statusJS = "contGame"
//     return;
// }


function contGame() {
    var conTextValue = document.getElementById("fileText").value;
    if (conTextValue != "") {
        statusJS = "contGame"
        return conTextValue;
    } else {
        alert("Enter filename!!!")
    }
    return;
}

function email() {
    statusJS = "email"

}

function replayGame() {
    var replayTextValue = document.getElementById("fileText").value;
    if (replayTextValue != "") {
        statusJS = "replayGame"
        return replayTextValue;
    } else {
        alert("Enter filename!!!")
    }

    return;

}



//FOR NEW GAME WINDOW

//make stuff visible or not depending on what the new game
var gameChosenJS = "localP";

function clearForm() {
    // document.getElementById("fileText").value = "";
    // document.getElementById("gameType").value = "Shogi";
    document.getElementById("cheatcheckbox").checked = false;
    document.getElementById("timeLimit").value = "";
    document.getElementById("timeInc").value = "";
    document.getElementById("gameDifficulty").value = "Normal";
    document.getElementById("flipcheckbox").checked = false;
    document.getElementById("goFirstcheckbox").checked = false;
    document.getElementById("ipText").value = "";
    document.getElementById("portText").value = "";
}



function remoteGameAI() {
    gameChosenJS = "remoteGameAI";
    clearForm()
    document.getElementsByClassName("ip_addr")[0].style.visibility = 'visible';
    document.getElementsByClassName("port_num")[0].style.visibility = 'visible';
    document.getElementsByClassName("goFirst")[0].style.visibility = "hidden";
}

function remoteGameP() {
    gameChosenJS = "remoteGameP"
    clearForm()
    document.getElementsByClassName("ip_addr")[0].style.visibility = 'visible';
    document.getElementsByClassName("port_num")[0].style.visibility = 'visible';
    document.getElementsByClassName("goFirst")[0].style.visibility = "hidden";

}

function localP() {
    gameChosenJS = "localP"
    clearForm()
    document.getElementsByClassName("ip_addr")[0].style.visibility = 'hidden';
    document.getElementsByClassName("port_num")[0].style.visibility = 'hidden';
    document.getElementsByClassName("goFirst")[0].style.visibility = "visible";

}

function localAI() {
    gameChosenJS = "localAI"
    clearForm()
    document.getElementsByClassName("ip_addr")[0].style.visibility = 'hidden';
    document.getElementsByClassName("port_num")[0].style.visibility = 'hidden';
    document.getElementsByClassName("goFirst")[0].style.visibility = "visible";

}

function HostP() {
    gameChosenJS = "HostP"
    clearForm()
    document.getElementsByClassName("ip_addr")[0].style.visibility = 'hidden';
    document.getElementsByClassName("port_num")[0].style.visibility = 'visible';
    document.getElementsByClassName("goFirst")[0].style.visibility = "hidden";
}

function HostAI() {
    gameChosenJS = "HostAI"
    clearForm()
    document.getElementsByClassName("ip_addr")[0].style.visibility = 'hidden';
    document.getElementsByClassName("port_num")[0].style.visibility = 'visible';
    document.getElementsByClassName("goFirst")[0].style.visibility = "hidden";
}

var filenameJS = ""
var gameTypeJS = ""
var cheatingJS = ""
var timelimitJS = ""
var limitaddJS = ""
var difficultyJS = ""
var flipJS = ""
var goFirstJS = ""
var ipJS = ""
var portJS = ""

function getValues() {
    filenameJS = document.getElementById("fileText").value;
    gameTypeJS = document.getElementById("gameType").value
    gameTypeJS = gameTypeJS.charAt(0)
    cheatingJS = (document.getElementById("cheatcheckbox").checked == true) ? "T" : "F";
    timelimitJS = document.getElementById("timeLimit").value
    limitaddJS = document.getElementById("timeInc").value
    difficultyJS = document.getElementById("gameDifficulty").value
    flipJS = (document.getElementById("flipcheckbox").checked == true) ? "true" : "false";
    goFirstJS = (document.getElementById("goFirstcheckbox").checked == true) ? "Black" : "White";
    portJS = document.getElementById("portText").value
    ipJS = document.getElementById("ipText").value
    if (filenameJS == "" || gameTypeJS == "") {
        alert("Enter filename and game type")
    } else {
        if (timelimitJS == ""){
            timelimitJS = "0"
        }
        if (limitaddJS == ""){
            limitaddJS = "0"
        }

        statusJS = "continue"
    }
}



//FOR MOVING PIECES

var userMoves = 0
    /*
        0 for source
        1 for 1st destination
        2 for 2nd destination
        3 for 3rd destination
    */

var promotePieceJS = "F"

function moveFunction(element) {

    var callPromotion = true;
    console.log("moving element")
    // console.log(movesArrayJS)
    var len = movesArrayJS.length;
    //check for drop
    if (len > 0) { //you didnt click on target
        // $(element).css("border","3px solid red");

        // movesArrayJS.push(element.id)
        // updateMoveJS(movesArrayJS[len - 2], movesArrayJS[len - 1])

        //ONLY FOR CHEAT OFF
        //CHECK IF YOU ARE ALLOWED TO DO THE MOVE
        var allowMove = false;
        if(len ==1){
        validArrJS.forEach(function(item) {
            var coord = item[len - 1][0] + "," + item[len - 1][1];
                 if (coord == element.id) {
                     allowMove = true;
                 }
        }, this);

        //FOR DROPS
        
        var checkDrop = movesArrayJS[0].indexOf("Black") !== -1 || movesArrayJS[0].indexOf("White") !== -1; //contains   
        if(checkDrop){
            callPromotion = false;
            var cellElement = $(element).find(".cell");
            var pie = $(cellElement).find("div")[0];
            if(pie.className == "emptyPiece"){
            allowMove = true;
            }
        }
        }
        else if(len ==2){
            validArrJS.forEach(function(item) {
                var prevCoord = item[0][0] + "," + item[0][1];
                var coord = item[1][0] + "," + item[1][1];
                if (prevCoord == movesArrayJS[1]) {
                    if (coord == element.id) {
                     allowMove = true;
                 }
                }
        }, this);
        }
        else if(len ==3){
        validArrJS.forEach(function(item) {
                var firstCoord = item[0][0] + "," + item[0][1];
                var prevCoord = item[1][0] + "," + item[1][1];
                var coord = item[2][0] + "," + item[2][1];
                if (prevCoord == movesArrayJS[2]) {
                    if (coord == element.id) {
                     allowMove = true;
                 }
                }
        }, this);
        }

        if(cheat){
            allowMove = true;
        }

        if(allowMove){
        var cellElement = $(element).find(".cell");
        var pie = $(cellElement).find("div")[0];
        console.log(pie)
        $(pie).css("color","green")
        movesArrayJS.push(element.id)
        updateMoveJS(movesArrayJS[len - 1], movesArrayJS[len])
        getValidArr(validArrJS, len+1);
        }

        //FOR CHECKING ALLOWED PROMOTION
        if(callPromotion){
        statusJS = "checkPromotionJS"
        promCoords = element.id;
        }

    } else { //lenght is 0
        
        //CHECK IF PIECE IS THE COLOR THAT YOU CAN MOVE
        var child = element.childNodes[0];
        
        var allowMove = child.id.indexOf(currentPlayer) !== -1;
        if(cheat){
            allowMove = true;
        }
        if(allowMove){
        var cellElement = $(element).find(".cell");
        var pie = $(cellElement).find("div")[0];
        // console.log(pie)
        $(pie).css("color","green")
        movesArrayJS.push(element.id)
        statusJS = "getvalidJS" //since we need to fill validArr
  
            //  $(element).css("border","3px solid green");
        }else{
            console.log("Illegal Move")
        }

    }

}

function dropFunction(element) {
    if(movesArrayJS.length <1){

    var child = element.childNodes[0];
    var otherPlayer = (currentPlayer=="Black"?"White":"Black")
    var allowMove = child.id.indexOf(otherPlayer) !== -1;
    if(cheat){
    movesArrayJS.push(element.id)//Color:piece:hand
            var cellElement = $(element).find(".cell");
        var pie = $(cellElement).find("div")[0];
        // console.log(pie)
        $(pie).css("color","green")
    // console.log("dropingElement")
    }
    else if(allowMove){
                var cellElement = $(element).find(".cell");
        var pie = $(cellElement).find("div")[0];
        // console.log(pie)
        $(pie).css("color","green")
    movesArrayJS.push(element.id)//Color:piece:hand
    console.log("dropingElement")
    }else{
        console.log("illegal drop")
    }
    }else{
        console.log("cant select two drops")
    }


    // $(element).css("background-color", "green");
}


function makeMove() {
    if (movesArrayJS[0].split(":")[2] == "hand") {
        statusJS = "makeDrop";
    } else {
        statusJS = "makeMove";
    }

    promotePieceJS = (document.getElementById("promoteCheckBox").checked == true) ? "T" : "F";

    //reset checkbox
}

function getValidArr(validArr, numberOfMove) {
    validArrJS = validArr;
 	$(".element").css("opacity", "");
      $(".element").css("color", "");
    if (numberOfMove == 1) {
        validArr.forEach(function(element) {
            var coord = element[0][0] + "," + element[0][1];
            console.log(coord)
            var el = document.getElementById(coord);
             $(el).css("opacity", "0.6");
              $(el).css("color", "black");
        }, this);
    } else if (numberOfMove == 2) {
        validArr.forEach(function(element) {
            var prevCoord = element[0][0] + "," + element[0][1];
            var coord = element[1][0] + "," + element[1][1];
            console.log("COORD FOR NEW THING")
            console.log(coord);
            if (prevCoord == movesArrayJS[1]) {
                 console.log("COORD MATCH")
                 console.log(coord);
                var el = document.getElementById(coord);
                 $(el).css("opacity", "0.6");
                  $(el).css("color", "black");
            }
        }, this);
    } else if (numberOfMove == 3) {
        validArr.forEach(function(element) {
            var prevCoord = element[1][0] + "," + element[1][1];
            var coord = element[2][0] + "," + element[2][1];
            console.log(coord)
            if (prevCoord == movesArrayJS[2]) {
                var el = document.getElementById(coord);
                $(el).css("opacity", "0.6");
                $(el).css("color", "black");
            }
        }, this);
    }

}




function resign() {
    statusJS = "resign"

}

function winCheck() {
    statusJS = "checkWin"
}
function tips(){
    statusJS = "tips";
}	



//FOR GAME STEP
function nextMove() {
    statusJS = "nextMove";
}

function prevMove() {
    statusJS = "prevMove";
}


//FOR ALL WINDOWS
function exit() {
    statusJS = "exit";
}

function resetStatus() {
    statusJS = "";
    return statusJS;
}


   

