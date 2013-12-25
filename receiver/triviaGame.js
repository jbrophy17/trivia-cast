// error constants
SENT_BLANK_NAME        = 1;
ALREADY_HAVE_RESPONSES = 2;
WAITING_ON_RESPONSES   = 3;
NOT_ENOUGH_PLAYERS     = 4;
ROUND_IN_PROGRESS      = 5;
GUESSED_READER         = 6;
GUESSED_SELF           = 7;
INVALID_TYPE           = 8;
ORDER_UNAVAILABLE      = 9;
NOT_ORDERING           = 10;
TOO_FEW_TO_ORDER       = 11;

// phase constants
PHASE_READING        = 100;
PHASE_GUESSING       = 101;
PHASE_ORDERING       = 102;
PHASE_BETWEEN_ROUNDS = 103;
PHASE_SUBMITTING     = 104;

// string constants
GET_READY = "Join using your mobile device, and get ready to t-t-t-t-t-t-t-triviacast.";
BETWEEN_ROUNDS = "We're waiting for someone to start the next round!";
NEED_MORE_PLAYERS = "This game can only be played with three or more players.";

MIN_PLAYER_NUMBER = 3;

// when debug mode is on, all Response and Player objects are printed with
// all human-useful member variables. Not great for competitive play.
DEBUG = false;

// used to exit the game after inactivity
idleTime = 0;
IDLE_MAX = 15;

// time show display splash screen in seconds
splashDuration = 5;

function Player(name, channel, pictureURL) {
    this.name    = name;
    this.ID      = -1;
    this.channel = channel;
    this.isOut   = false;
    this.isGone  = false;
    this.score   = 0;

    if(typeof pictureURL != "undefined"){
        this.pictureURL = pictureURL;
    }
    else{
        this.pictureURL = '';
    }

    this.setPictureURL = function(url){
        this.pictureURL = url;
    }

    this.getScore = function() {
        return this.score;
    };

    this.incrementScore = function() {
        this.score++;
    };

    this.getID = function() {
        return this.ID;
    };

    this.didGetOut = function(){
        console.debug(this.toString() + " just got out.");
        this.isOut = true;
    }

    this.clientSafeVersion = function(){
        var thisObj        = new Object();
        thisObj.name       = this.name;
        thisObj.pictureURL = this.pictureURL;
        thisObj.ID         = this.ID;
        thisObj.score      = this.score;
        thisObj.isOut      = this.isOut;
        return thisObj;
    }

    this.toString = function(noImage){
        var string = '';

        if(this.pictureURL.length > 0 && typeof noImage == "undefined"){
            //string += '<img src="' + this.pictureURL + '" class="prof-pic"> ';
        }
        string += this.name;

        if(DEBUG){
            string += ' [ID ' + this.ID + ', score ' + this.score + ', pictureURL ' + this.pictureURL + ']';
        }

        return string;
    }
}

function Response(response, responseID, userID, channel){
    this.response   = response;
    this.responseID = responseID;
    this.userID     = userID;
    this.channel    = channel;
    this.isActive   = true;

    this.clientSafeVersion = function(){
        var thisObj = new Object();
        thisObj.response   = this.response;
        thisObj.responseID = this.responseID;
        return thisObj;
    }

    this.toString = function(){
        var string = '';
        string = this.response;

        if(DEBUG){
            string += ' [responseID ' + this.responseID + ', userID ' + this.userID + ', active ' + this.isActive + ']';
        }

        return string;
    }

    // compare two responses ignoring punctuation and capitalization
    this.isTheSameAs = function(otherResponse){
        var thisTemp = this.response.toLowerCase();
        var thatTemp = otherResponse.response.toLowerCase();

        thisTemp = thisTemp.replace(/[\.,-\/#!$%\^&\*;:{}=\-_`~()]/g,"");
        thatTemp = thatTemp.replace(/[\.,-\/#!$%\^&\*;:{}=\-_`~()]/g,"");

        console.debug("comparing '" + thisTemp + "' to '" + thatTemp + "'");

        return thisTemp === thatTemp;
    }
}

function Game() {
    this.players     = new Array();
    this.playerQueue = new Array();
    this.orderQueue  = new Array();
    this.responses   = new Array();
    this.cues        = prompts;
    this.cues        = shuffle(this.cues); // randomize each playthrough

    this.reader  = -1;
    this.guesser = -1;

    this.phase        = PHASE_BETWEEN_ROUNDS;
    this.firstGuesser = true;
    this.currentCue   = '';

    this.errors = new Object();
    this.errors[NOT_ENOUGH_PLAYERS] = 'You can start the game once there are at least three players.';

    this.notificationIsShown = false;

    this.addPlayer = function(player, noUpdate){
        var i = 0;
        while(typeof this.players[i] != 'undefined'){
            i++;
        }
        player.ID = i;
        this.players[i] = player;
        player.channel.send({ type : 'didJoin', number : player.ID });
        console.log("Added player " + player.toString() + " in ID " + player.ID);

        if(typeof noUpdate != "undefined" && noUpdate){
            return;
        }
        updatePlayerList();
    }

    this.queuePlayer = function(player){
        this.playerQueue.push(player);
        player.channel.send({ type: 'didQueue' });
        console.log("Queued player " + player.toString());
        updatePlayerList();
    }

    this.deQueuePlayerByChannel = function(channel){
        for(var i = 0; i < this.playerQueue.length; i++){
            if(this.playerQueue[i].channel == channel){
                this.playerQueue.splice(i, 1);
                updatePlayerList();
                return;
            }
        }

        console.error('Failed to dequeue player by channel');
    }

    this.deletePlayer = function(id){
        console.log("Deleting player " + this.players[id].toString());
        this.players.splice(id, 1);

        // if deleting reader or guesser, fix
        if(id == this.guesser || id == this.reader){
            advanceGuesser();
        }

        // rebuild players' IDs to match their new indices
        for(var i = 0; i < this.players.length; i++){
            if(this.players[i].ID != i){
                // fix and notify
                if(this.players[i].ID == this.guesser){
                    console.debug("Updating guesser from " + this.guesser + " to " + this.guesser);
                    this.guesser = i;
                }
                if(this.players[i].ID == this.reader){
                    console.debug("Updating reader from " + this.reader + " to " + this.reader);
                    this.reader = i;
                }

                console.debug("Updating ID from " + this.players[i].ID + " to " + i);
                this.players[i].ID = i;

                if(!this.players[i].isGone){
                    this.players[i].channel.send({ "type" : "didJoin", "number" : i });
                }
            }
        }

        console.log("Finished player deletion");

        // update all clients with new IDs
        this.sendGameSync();
        updatePlayerList();
    }

    this.getNextCue = function(){
        var lastIndex = this.cues.length - 1;
        this.currentCue = this.cues[lastIndex];
        this.cues.splice(lastIndex, 1);
        return this.currentCue;
    }

    this.sendGameSync = function(noReader){
        if(this.phase == PHASE_GUESSING){
            noReader = true;
        }

        // update all clients' user list and scores
        var playerList = new Array();
        for(var i = 0; i < this.players.length; i++){
            playerList.push(this.players[i].clientSafeVersion());
        }
        for(var i = 0; i < this.players.length; i++){
            if(!this.players[i].isGone){
                if(typeof noReader != "undefined" || this.reader == -1){
                    thisReader = -1;
                }
                else{
                    var thisReader = this.players[this.reader].ID;
                }
                this.players[i].channel.send({type : 'gameSync', players : playerList, reader : thisReader, guesser : this.players[this.guesser].ID });
            }
            else{
                console.debug("not sending gameSync to gone player: " + this.players[i].toString());
            }
        }
    }

    this.setPhase = function(newPhase){
        this.phase = newPhase;

        // notify everyone
        for(var i = 0; i < this.players.length; i++){
            if(!this.players[i].isGone){
                getPhase(this.players[i].channel);
            }
        }
    }

    // make sure guesser is still here, and if reader left, show responses immediately
    this.verifyKeyPlayers = function(){
        // check if guesser is gone
        var guesserIsHere = false;

        for(var i = 0; i < this.players.length; i++){
            if(!this.players[i].isGone){
                if(this.players[i].ID == this.guesser){
                    guesserIsHere = true;
                }
            }
        }

        if(!guesserIsHere){
            console.debug("verifyKeyPlayers found missing guesser; advancing");

            // show responses if reader left during reading
            if(this.phase == PHASE_READING && this.reader == this.guesser){
                console.debug("verifyKeyPlayers found reader gone during reading; showing responses");
                showResponses();
            }

            nextGuesser(true);
        }
    }

    this.responseExistsForPlayerID = function(playerID){
        for(var i = 0; i < this.responses.length; i++){
            if(this.responses[i].userID == playerID){
                return true;
            }
        }
        return false;
    }
}

function getPlayerIndexByChannel(channel){
    // first check players
    for(var i = 0; i < game.players.length; i++){
        if(game.players[i].channel == channel){
            return i;
        }
    }

    // now check queue
    for(var i = 0; i < game.playerQueue.length; i++){
        if(game.playerQueue[i].channel == channel){
            return i;
        }
    }

    console.error('Failed to find player index by channel');
    return -1;
}

// update the list of players on screen
function updatePlayerList(){
    // if we're in the middle of a round and the player count drops below three, kick back to the homepage with a message
    if(!game.phase == PHASE_BETWEEN_ROUNDS && game.players.length < 3){
        betweenRounds();
        $('#instructions').html(game.errors[NOT_ENOUGH_PLAYERS]);
    }

    $('#playerlist').empty();
    for(var i = 0; i < game.players.length; i++){
        var playerHTML = '<li><em>' + game.players[i].score + '</em> ' + game.players[i].toString() + '</li><br>';
        $('#playerlist').append(playerHTML);
    }

    if(game.players.length == 0){
        var infoHTML = "<li><p><strong>There aren't any players in this game";

        if(game.playerQueue.length > 0){
            if(game.playerQueue.length == 1){
                infoHTML += ', but there is one queued to join';
            }
            else{
                infoHTML += ', but there are ' + game.playerQueue.length + ' queued to join';
            }
        }

        infoHTML += '.</strong><br />Queued players will be added when the next round starts.</p></li>';
        $('#playerlist').append(infoHTML);
    }

    if(game.playerQueue.length > 0){
        var notificationHTML = '';
        if(game.playerQueue.length == 1){
            notificationHTML += '<strong>' + game.playerQueue[0].toString(true) + '</strong>';
        }
        else{
            for(var i = 0; i < game.playerQueue.length; i++){
                notificationHTML += '<strong>' + game.playerQueue[i].toString(true) + '</strong>';

                // if there's more than one player left, put a comma
                if((i + 2) < game.playerQueue.length){
                    notificationHTML += ', ';
                }

                // if there's one more player left, put 'and'
                if((i + 2) == game.playerQueue.length){
                    // if there's one more player but more than 2 total, add oxford comma
                    if(game.playerQueue.length > 2){
                        notificationHTML += ',';
                    }
                    notificationHTML += ' and ';
                }
            }
        }

        notificationHTML += ' will join the game when the next round starts.';

        console.debug('notificationHTML = ' + notificationHTML);
        showNotification(notificationHTML);
    }
    else{
        hideNotification();
    }
}

function showNotification(text){
    $('#notification').html('<marquee>' + text + '</marquee>');

    if(!game.notificationIsShown){
        $('#notificationcontainer').slideDown();
    }
    game.notificationIsShown = true;
}

function hideNotification(){
    if(game.notificationIsShown){
        $('#notificationcontainer').slideUp();
    }
    game.notificationIsShown = false;
    $('#notification').empty();
}

// display start screen
function startScreen(headerText){
    if(typeof headerText != "undefined"){
        $('#content h1').html(headerText);
    }
    else{
        $('#content h1').html('TriviaCast');
    }
    $('#instructions').empty();
    $('#instructions').show();
    $('#responses').fadeOut();
    $('#status').fadeOut();
    $('#scoreboard').fadeIn();

    updatePlayerList();
}

// display screen for a round of the game
function roundScreen(){
    $('#content h1').html(game.currentCue);
    $('#instructions').fadeOut();
    $('#responses').show();
    $('#scoreboard').fadeOut();

    $('#status').html('Waiting for responses... 0/' + game.players.length);
    $('#status').fadeIn();
}

function joinPlayer(channel, response){
    if(response.name === ""){
        channel.send({ type : 'error', value : SENT_BLANK_NAME });
        console.warn('Received blank name');
        return;
    }

    if("pictureURL" in response){
        console.debug('making newPlayer with picture');
        var newPlayer = new Player(response.name, channel, response.pictureURL);
        console.debug('made newPlayer');
    }
    else{
        console.debug('making newPlayer with no picture');
        var newPlayer = new Player(response.name, channel);
        console.debug('made newPlayer');
    }

    game.queuePlayer(newPlayer);
}

function checkMinPlayers(){
    var playersNotGone = 0;
    var playersGone = 0;
    for(var i = 0; i < game.players.length; i++){
        if(!game.players[i].isGone){
            playersNotGone++;
        }
        else{
            playersGone++;
        }
    }

    var activePlayerCount = playersNotGone + game.playerQueue.length;
    var totalPlayerCount = activePlayerCount + playersGone;

    if(totalPlayerCount < MIN_PLAYER_NUMBER){
        if(activePlayerCount == 0){
            console.debug("Found 0 players left, reinitializing game");
            $('#instructions').html(GET_READY).show();
            initGame();
        }
        else{
            $('#instructions').html(NEED_MORE_PLAYERS).show();

            if(game.phase != PHASE_BETWEEN_ROUNDS){
                console.debug("Found not enough players left, going to between rounds");
                betweenRounds();
            }
        }
    }
}

function leavePlayer(channel){
    // if this player is queued, just dequeue them
    for(var i = 0; i < game.playerQueue.length; i++){
        if(game.playerQueue[i].channel == channel){
            game.deQueuePlayerByChannel(channel);
            checkMinPlayers();
            return;
        }
    }

    console.debug("leavePlayer: about to find player");

    // find player, set them as gone
    var playerID = getPlayerIndexByChannel(channel);
    if(playerID == -1){
        // player is already gone
        console.debug("Player's already gone, returning");
        return;
    }

    // if they've submitted a response, mark them as gone but keep them in the game.
    // if not, they leave immediately.
    if(game.responseExistsForPlayerID(playerID)){
        console.debug("leavePlayer: already submitted response, about to mark as gone");
        game.players[playerID].isGone = true;
    }
    else{
        console.debug("leavePlayer: hasn't yet submitted response, about to kick");
        game.deletePlayer(playerID);
    }

    game.verifyKeyPlayers();
    checkMinPlayers();
    game.sendGameSync();

    console.debug("leavePlayer: about to return");

    return;
}

function submitResponse(channel, response){
    var userID       = getPlayerIndexByChannel(channel);
    var responseID   = game.responses.length;
    var responseText = trim(response);
    var newResponse  = new Response(responseText, responseID, userID, channel);

    // check if there's already a response from this channel
    for(var i = 0; i < game.responses.length; i++){
        if(game.responses[i].channel == channel){
            // update the response
            game.responses[i].response = responseText;
            return;
        }
    }

    // check if there are already max number of responses
    if(game.responses.length >= game.players.length){
        channel.send({ type : 'error', value : ALREADY_HAVE_RESPONSES });
        return;
    }

    game.responses.push(newResponse);

    channel.send({ 'type' : 'responseReceived' });

    $('#status').html('Waiting for responses... ' + game.responses.length + '/' + game.players.length);

    // if all responses are in, move to reading phase
    if(responseID == (game.players.length - 1)){
        startReading();
    }
}

function getAllResponsesJSON(){
    var response = new Array();
    for(var i = 0; i < game.responses.length; i++){
        if(game.responses[i].isActive){
            response.push(game.responses[i].clientSafeVersion());
        }
    }
    // var responseJSON = JSON.stringify(response);
    var responseJSON = response;
    return responseJSON;
}

function startReading(){
    game.setPhase(PHASE_READING);
    $('#status').html('Sit tight while <strong>' + game.players[game.reader].toString() + '</strong> is reading.');

    // randomize order of responses
    game.responses = shuffle(game.responses);

    // send all responses to the reader.
    var responseJSON = getAllResponsesJSON();
    console.debug('sending responses to reader');
    console.debug(responseJSON);
    game.players[game.reader].channel.send({ type : 'receiveResponses', responses : responseJSON, responseCount : game.responses.length });
}

function startGuessing(){
    game.setPhase(PHASE_GUESSING);

    // send guesser all responses
    var responseJSON = getAllResponsesJSON();
    console.debug('sending responses to guesser ' + game.players[game.guesser].toString());
    console.debug(responseJSON);
    // game.players[game.guesser].channel.send({ type : 'guesser' });
    game.players[game.guesser].channel.send({ type : 'receiveResponses', responses : responseJSON, responseCount : game.responses.length });
}

function checkRoundOver(){
    checkMinPlayers();

    // round is over when only reader's and your own responses are left
    var responsesLeft = 0;
    for(var i = 0; i < game.responses.length; i++){
        if(game.responses[i].isActive){
            responsesLeft++;
        }
    }

    if(responsesLeft <= 1){
        console.debug("No more responses, ending round");
        betweenRounds();
    }
    else{
        console.debug("Enough responses left, guessing may continue");
    }
}

// whatTheyGuessed is normally "correctly" or "incorrectly", but creativity can be applied
function prependStatus(playerIndex, whatTheyGuessed){
    $('#status').prepend('<strong>' + game.players[playerIndex].toString(true) + '</strong> guessed ' + whatTheyGuessed + '.<br />');
}

function submitGuess(channel, guess){
    // only allowed if all responses are in
    if(game.responses.length < game.players.length){
        channel.send({ type : 'error', value : WAITING_ON_RESPONSES });
        return;
    }

    var responseGuessed = guess.guessResponseId;
    var playerGuessed   = guess.guessPlayerNumber;
    var guesserID       = game.players[getPlayerIndexByChannel(channel)].ID;
    var rgIndex         = -1;

    // only allowed if not the current player
    if(playerGuessed == guesserID){
        channel.send({ "type" : "error", "value" : GUESSED_SELF });
        channel.send({ "type" : "guessResponse", "value" : false });
        console.warn("Invalid guess: tried to guess themself");
        nextGuesser();
        prependStatus(guesserID, "themselves..");
        return;
    }

    for(var i = 0; i < game.responses.length; i++){
        if(game.responses[i].responseID == responseGuessed){
            rgIndex = i;
        }
    }

    if(rgIndex == -1){
        console.error("Failed to find the index for response ID " + responseGuessed);
    }

    console.debug('responseGuessed = ' + responseGuessed + ', playerGuessed = ' + playerGuessed + ', guesserID = ' + guesserID);
    console.debug(guess);

    var correctAnswers = new Array();

    // check for other identical responses
    for(var i = 0; i < game.responses.length; i++){
        if(game.responses[rgIndex].isTheSameAs(game.responses[i])){
            console.debug("found that " + game.responses[rgIndex].toString() + " is the same as " + game.responses[i].toString());
            correctAnswers.push(game.responses[i].userID);
        }
    }

    console.debug("correctAnswers contents:");
    for(var i = 0; i < correctAnswers.length; i++){
        console.debug(correctAnswers[i]);
    }

    // if you're right, you get a point, a response is pulled, and you can keep guessing.
    if(correctAnswers.indexOf(playerGuessed) != -1){
        channel.send({ type : 'guessResponse', 'value' : true });
        game.players[guesserID].incrementScore();
        game.players[playerGuessed].didGetOut();

        game.sendGameSync(true);

        // need to use guesser to find which response to delete if there are multiple
        var deleteIndex = rgIndex;
        if(correctAnswers.length > 1){
            for(var i = 0; i < game.responses.length; i++){
                if(game.responses[i].userID == playerGuessed){
                    deleteIndex = i;
                    break;
                }
            }
        }

        game.responses[deleteIndex].isActive = false;

        // update ui
        console.debug("Fading resopnse ID " + '#response' + game.responses[deleteIndex].responseID);
        $('#response' + game.responses[deleteIndex].responseID).animate({ 'opacity' : '0.5', 'margin-left' : '-40px' });

        var statusText = "correctly that ";
        statusText += game.players[playerGuessed].toString() + " submitted " + game.responses[deleteIndex].toString();
        prependStatus(guesserID, statusText);

        console.log(game.players[guesserID].toString() + ' correctly guessed that ' + game.players[playerGuessed].toString() + ' submitted ' + game.responses[deleteIndex].toString());
        checkRoundOver();
    }
    else{
        // if player doesn't exist
        if(typeof game.players[playerGuessed] != "undefined"){
            prependStatus(guesserID, "a player that doesn't exist (or maybe left)");
        }
        // if the person is out, you're dumb and your turn is over.
        else if(game.players[playerGuessed].isOut){
            prependStatus(guesserID, "someone who was already out");
        }
        channel.send({ type : 'guessResponse', 'value' : false });

        console.log(game.players[guesserID].toString() + ' incorrectly guessed that ' + game.players[playerGuessed].toString() + ' submitted ' + game.responses[rgIndex].toString());

        // next guesser's turn
        var statusText = "incorrectly that ";
        if(typeof game.players[playerGuessed] == "undefined"){
            statusText += "someone who left";
        }
        else{
            statusText += game.players[playerGuessed].toString();
        }
        statusText += " submitted " + game.responses[rgIndex].toString() + ".";
        prependStatus(guesserID, statusText);
        nextGuesser(true);
    }
}

function showResponses(){
    $('#responses ul').empty();
    for(var i = 0; i < game.responses.length; i++){
        var responseHTML = '<li id="response' + game.responses[i].responseID + '">' + game.responses[i].toString() + '</li><br />';
        if(i % 2 == 0){
            $('#responses #leftcol ul').append(responseHTML);
        }
        else{
            $('#responses #rightcol ul').append(responseHTML);
        }
    }
}

function advanceGuesser(){
    var loopCount = 0;

    do{
        if(loopCount >= game.players.length){
            console.warn("Couldn't find new guesser. Ending round.");
            betweenRounds();
            return false;
        }
        loopCount++;

        var nextGuesser = game.guesser + 1;
        if(nextGuesser >= game.players.length){
            nextGuesser = 0;
        }
        game.guesser = nextGuesser;

        console.debug("advancing guesser (loopCount = " + loopCount + "), about to check " + game.guesser);

        if(typeof game.players[game.guesser] == "undefined"){
            console.debug("looking for guesser, found undefined player. trying again.")
        }
        if(game.players[game.guesser].isOut){
            console.debug("looking for guesser but found someone who is out: " + game.players[game.guesser].toString());
        }
        if(game.players[game.guesser].isGone){
            console.debug("looking for guesser but found someone who is gone: " + game.players[game.guesser].toString());
        }
    }while(typeof game.players[game.guesser] == "undefined" || game.players[game.guesser].isOut || game.players[game.guesser].isGone);
    console.debug("new guesser set to " + game.guesser);

    game.sendGameSync(true);

    return true;
}

function nextGuesser(force){
    if(!game.firstGuesser || force){
        var advanceAttempt = advanceGuesser();
        if(!advanceAttempt){
            return;
        }

        console.debug('guesser is now ' + game.guesser);
    }
    else{
        game.firstGuesser = false;
    }

    // update UI
    $('#status').html('<strong>' + game.players[game.guesser].toString() + '</strong> is guessing.');

    startGuessing();
}

function startNextRound(channel){
    // only can start if we're in between rounds
    if(game.phase != PHASE_BETWEEN_ROUNDS){
        console.warn(game.players[getPlayerIndexByChannel(channel)].toString() + " to start a new round during a round.");
        channel.send({ type : 'error', value : ROUND_IN_PROGRESS });
        return;
    }

    // only can start if we have > 2 players
    if((game.players.length + game.playerQueue.length) < MIN_PLAYER_NUMBER){
        console.warn("Tried to start new round with not enough players.");
        channel.send({ type : 'error', value : NOT_ENOUGH_PLAYERS });
        $('#instructions').html(game.errors[NOT_ENOUGH_PLAYERS]);
        return;
    }

    $("#instructions").hide();
    newGrind();

    game.setPhase(PHASE_SUBMITTING);

    // show next question
    game.getNextCue();
    roundScreen();

    console.debug('starting next round');
    console.debug(game);

    // let everyone know the round has started
    for(var i = 0; i < game.players.length; i++){
        game.players[i].channel.send({ type : 'roundStarted', cue: game.currentCue });
    }
}

function betweenRounds(){
    console.debug("betweenRounds()");

    clearDeleteQueue();

    // notify everyone that we're in between rounds
    for(var i = 0; i < game.players.length; i++){
        if(!game.players[i].isGone){
            game.players[i].channel.send({ 'type' : 'roundOver' });
        }
    }

    game.setPhase(PHASE_BETWEEN_ROUNDS);
    $('#instructions').show();

    if(game.players.length > 0){
        startScreen('TriviaCast Round Over!');
        $('#instructions').html(BETWEEN_ROUNDS);
    }
    else{
        startScreen('TriviaCast');
        $('#instructions').html(GET_READY);
    }
}

function clearPlayerQueue(){
    console.debug('processing player queue');
    // add players who are queued
    for(var i = 0; i < game.playerQueue.length; i++){
        game.addPlayer(game.playerQueue[i], true);
    }

    console.debug('player queue processed');

    // clear player queue
    game.playerQueue = [];
}

// delete all players for whom isGone === true
function clearDeleteQueue(){
    console.debug("Processing delete queue");
    for(var i = 0; i < game.players.length; i++){
        if(typeof game.players[i] != undefined && game.players[i].isGone){
            game.deletePlayer(game.players[i].ID);
        }
    }
    console.debug("Finished processing delete queue");
}

// prepare for next question
function newGrind(){
    clearPlayerQueue();
    clearDeleteQueue();
    updatePlayerList();

    // clear responses
    game.responses = [];
    $('#responses ul').empty();

    // build array of players and set their isOut to false
    var playerList = new Object();
    for(var i = 0; i < game.players.length; i++){
        game.players[i].isOut = false;
        playerList[i] = game.players[i].clientSafeVersion();
    }

    if(game.players.length > 1){
        // pick next guesser/reader
        if(game.reader >= 0){
            game.guesser = game.reader; // set guesser to previous starting position
        }
        advanceGuesser();
        game.reader = game.guesser;
        game.sendGameSync();
    }
    else{
        console.warn("Didn't pick new reader/guesser, newGrind() called with not enough players");
    }
    game.firstGuesser = true;

    console.debug('Next reader is ' + game.reader);
    console.debug('Next guesser is ' + game.guesser);

    console.debug('newGrind finished');
}

function updatePlayer(channel, info){
    var playerID = getPlayerIndexByChannel(channel);

    if(!("name" in info) || trim(info.name).length == 0){
        console.warn("Recieved a player update request with no name. Ignoring.");
        channel.send({ "type" : "error", "value" : SENT_BLANK_NAME });
        return;
    }

    var thisName = trim(info.name);

    var url = '';
    if("pictureURL" in info){
        var url = info.pictureURL;
    }

    // find out if we're queued
    var isQueued = false;
    for(var i = 0; i < game.playerQueue.length; i++){
        if(game.playerQueue[i].channel == channel){
            isQueued = true;
        }
    }

    if(isQueued){
        game.playerQueue[playerID].name = thisName;
        game.playerQueue[playerID].pictureURL = url;
    }
    else{
        game.players[playerID].name = thisName;
        game.players[playerID].pictureURL = url;
    }

    channel.send({ type : 'settingsUpdated' });
    updatePlayerList();
}

// start ordering players and tell everyone
function initializeOrdering(channel){
    // only can order once there are enough people (no point to ordering with ≤2 players)
    if(game.players.length < MIN_PLAYER_NUMBER){
        console.warn("Tried to start ordering with not enough players.");
        channel.send({ "type" : "error", "value" : TOO_FEW_TO_ORDER });
        return;
    }

    if(game.phase == PHASE_BETWEEN_ROUNDS){
        console.debug("Starting ordering phase");

        // process player queue
        clearPlayerQueue();
        updatePlayerList();
        game.orderQueue = new Array();
        game.setPhase(PHASE_ORDERING);

        for(var i = 0; i < game.players.length; i++){
            game.players[i].channel.send({ "type" : "orderInitialized" });
        }

        // update UI
        startScreen("TriviaCast: Set Player Order");
        $("#instructions").html("Each player should press the join button in the order they're sitting.").show();
        $("#scoreboard").hide();
        $("#orderscreen").empty().show();
    }
    else{
        console.debug("Tried to start ordering during wrong phase");
        channel.send({ "type" : "error", "value" : ORDER_UNAVAILABLE });
    }
}

function setPlayerOrder(channel){
    if(game.phase != PHASE_ORDERING){
        console.warn("Client tried to set player order while not in the ordering phase.");
        channel.send({ "type" : "error", "value" : NOT_ORDERING });
        return;
    }

    game.orderQueue.push(game.players[getPlayerIndexByChannel(channel)]);
    console.debug("Setting order for " + game.players[getPlayerIndexByChannel(channel)].toString());

    $("#orderscreen").append(game.players[getPlayerIndexByChannel(channel)].toString() + "<br />");

    // if this is the last player, rebuild players and notify everyone
    if(game.orderQueue.length == game.players.length){
        console.debug("Rebuilding players with new order")
        game.players = game.orderQueue;

        for(var i = 0; i < game.players.length; i++){
            game.players[i].ID = i;
            game.players[i].channel.send({ "type" : "didJoin", "number" : i });
        }

        game.sendGameSync();

        for(var i = 0; i < game.players.length; i++){
            game.players[i].channel.send({ "type" : "orderComplete" });
        }

        updatePlayerList();
        game.setPhase(PHASE_BETWEEN_ROUNDS);
    }
}

function cancelOrdering(channel){
    if(game.phase == PHASE_ORDERING){
        console.debug("Canceling ordering process");
        game.setPhase(PHASE_BETWEEN_ROUNDS);
        for(var i = 0; i < game.players.length; i++){
            game.players[i].channel.send({ "type" : "orderCanceled" });
        }
    }
    else{
        console.warn("Client tried to cancel ordering in the wrong phase");
        channel.send({ "type" : "error", "value" : NOT_ORDERING });
    }
}

function getPhase(channel){
    channel.send({ "type" : "currentPhase", "phase" : game.phase });
}

function initReceiver(){
    var receiver = new cast.receiver.Receiver('1f96e9a0-9cf0-4e61-910e-c76f33bd42a2', ['com.bears.triviaCast'], "", 5),
        channelHandler = new cast.receiver.ChannelHandler('com.bears.triviaCast'),
        $messages = $('.messages');

    channelHandler.addChannelFactory(
        receiver.createChannelFactory('com.bears.triviaCast'));

    receiver.start();
    console.log('receiver started');

    channelHandler.addEventListener(cast.receiver.Channel.EventType.MESSAGE, onMessage.bind(this));
    channelHandler.addEventListener(cast.receiver.Channel.EventType.ERROR, onError.bind(this));
    channelHandler.addEventListener(cast.receiver.Channel.EventType.CLOSED, onClose.bind(this));

    function onMessage(event) {
        console.log('type = ' + event.message.type);
        console.log(event);

        touch();

        switch(event.message.type){
            case "join":
                joinPlayer(event.target, event.message);
                break;
            case "leave":
                leavePlayer(event.target);
                break;
            case "submitResponse": // user submits a response
                submitResponse(event.target, event.message.response);
                break;
            case "submitGuess": // user submits a guess
                submitGuess(event.target, event.message);
                break;
            case "nextRound":
                startNextRound(event.target);
                break;
            case "readerIsDone":
                showResponses();
                nextGuesser();
                break;
            case "updateSettings":
                updatePlayer(event.target, event.message);
                break;
            case "initializeOrder":
                initializeOrdering(event.target);
                break;
            case "order":
                setPlayerOrder(event.target);
                break;
            case "cancelOrder":
                cancelOrdering(event.target);
                break;
            case "getPhase":
                getPhase(event.target);
                break;
            case "pong":
                game.players[game.getPlayerIndexByChannel(event.target)].health.checkPassed();
                break;
            default:
                event.target.send({ type: 'error', value : INVALID_TYPE });
                console.warn("Invalid type: " + event.message.type);
        }
    }

    function onError(event){
        console.error('error received');
        console.debug(event);

        leavePlayer(event.target);
    }

    function onClose(event){
        console.log('Channel disconnected for player');
        console.debug(event);

        leavePlayer(event.target);
    }
}

function initGame(){
    game = new Game();
    newGrind();
    betweenRounds();

    // set timeout to hide splash screen
    splashTimeout = window.setTimeout(hideSplash, (splashDuration * 1000));

    if(DEBUG){
        hideSplash();
    }
}

function hideSplash(){
    $('#splashscreen').fadeOut('slow');
    window.clearTimeout(splashTimeout);
}

function touch(){
    idleTime = 0;
    $('#idlewarning').fadeOut();
}

function checkIdle(){
    // only exit if nobody's in the game (queued doesn't count)
    if(game.players.length > 0){
        return;
    }

    idleTime++;

    if(idleTime > IDLE_MAX){
        window.close();
    }
    else if(idleTime > (IDLE_MAX * .75)){
        // warn if 75% of the way to exit
        $('#idlewarning').fadeIn();
    }
}

// initialize
$(function(){
    initGame();
    initReceiver();

    // exit game after inactivity
    var idleInterval = setInterval(checkIdle, 60000); // 1 minute
});

//+ Jonas Raoni Soares Silva
//@ http://jsfromhell.com/array/shuffle [v1.0]
function shuffle(o){
    for(var j, x, i = o.length; i; j = Math.floor(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
    return o;
};

// Steven Levithan
// http://stackoverflow.com/questions/3000649/trim-spaces-from-start-and-end-of-string
function trim(str) {
    return str.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
}
