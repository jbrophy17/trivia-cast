// error constants
SENT_BLANK_NAME        = 1;
ALREADY_HAVE_RESPONSES = 2;
WAITING_ON_RESPONSES   = 3;
NOT_ENOUGH_PLAYERS     = 4;
ROUND_IN_PROGRESS      = 5;

function Player(name, ID, channel) {
    this.name    = name;
    // this.picture = picture;
    this.ID      = ID;
    this.channel = channel;

    this.isOut   = false;
    this.isGone  = false;

    this.score = 0;

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
        this.isOut = true;
    }

    this.didLeave = function(){
        this.isGone = true;
    }

    this.clientSafeVersion = function(){
        var thisObj   = new Object();
        thisObj.name  = this.name;
        thisObj.ID    = this.ID;
        thisObj.score = this.score;
        return thisObj;
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
}

function Game() {
    var that= this;

    this.players     = new Array();
    this.playerQueue = new Array();
    this.responses   = new Array();
    this.cues        = prompts;
    this.cues        = shuffle(this.cues); // randomize each playthrough

    this.reader  = -1;
    this.guesser = 0;

    this.isBetweenRounds = true;
    this.firstGuesser    = true;
    this.currentCue      = '';

    this.errors = new Object();
    this.errors[NOT_ENOUGH_PLAYERS] = 'You can start the game once there are at least three players.';

    this.addPlayer = function(player){
        var i = 0;
        while(typeof this.players[i] != 'undefined'){
            i++;
        }
        player.ID = i;
        this.players[i] = player;
        player.channel.send({ type : 'didJoin', number : player.ID });
        console.log("Added player " + player.name + " in ID " + player.ID);
        updatePlayerList();
    }

    this.queuePlayer = function(player){
        this.playerQueue.push(player);
        player.channel.send({ type: 'didQueue' });
        console.log("Queued player " + player.name);
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
        console.log("Deleted player " + this.players[id].name);
        this.players.splice(id, 1);
        updatePlayerList();
    }

    this.getNextCue = function(){
        var lastIndex = this.cues.length - 1;
        this.currentCue = this.cues[lastIndex];
        this.cues.splice(lastIndex, 1);
        return this.currentCue;
    }
}

function getPlayerIndexByChannel(channel){
    for(var i = 0; i < game.players.length; i++){
        if(game.players[i].channel == channel){
            return i;
        }
    }

    console.error('Failed to find player index by channel');
    return -1;
}

// update the list of players on screen
function updatePlayerList(){
    // if we're in the middle of a round and the player count drops below three, kick back to the homepage with a message
    if(!game.isBetweenRounds && game.players.length < 3){
        betweenRounds();
        $('#instructions').html(game.errors[NOT_ENOUGH_PLAYERS]);
    }

    $('#playerlist').empty();
    for(var i = 0; i < game.players.length; i++){
        var playerHTML = '<li><em>' + game.players[i].score + '</em> ' + game.players[i].name + '</li><br>';
        $('#playerlist').append(playerHTML);
    }

    if(game.players.length == 0){
        var infoHTML = '<p>There aren\'t any players in this game.<br />Queued players will be added when the round starts.</p>';
        $('#playerlist').append(infoHTML);
    }

    hideNotification();

    if(game.playerQueue.length > 0){
        var notificationHTML = '';
        if(game.playerQueue.length == 1){
            notificationHTML += '<strong>' + game.playerQueue[0].name + '</strong>';
        }
        else{
            for(var i = 0; i < game.playerQueue.length; i++){
                notificationHTML += '<strong>' + game.playerQueue[i].name + '</strong>';

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

        notificationHTML += ' will join the game at the start of the next round.';

        console.debug('notificationHTML = ' + notificationHTML);
        showNotification(notificationHTML);
    }
}

function showNotification(text){
    $('#notification').html('<marquee>' + text + '</marquee>');
    $('#notificationcontainer').slideDown();
}

function hideNotification(){
    $('#notificationcontainer').slideUp();
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

function joinPlayer(channel, name){
    if(name === ""){
        channel.send({ type : 'error', value : SENT_BLANK_NAME });
        return;
    }

    var newID = game.players.length;
    var newPlayer = new Player(name, newID, channel);

    game.queuePlayer(newPlayer);
}

function leavePlayer(channel){
    // if this player is queued, just dequeue them
    for(var i = 0; i < game.playerQueue.length; i++){
        if(game.playerQueue[i].channel == channel){
            game.deQueuePlayerByChannel(channel);
            return;
        }
    }

    // find player, set them as out for the round and set didLeave = true so they're removed before next round
    var playerID = getPlayerIndexByChannel(channel);
    if(playerID == -1){
        // player is already gone
        return;
    }
    game.players[playerID].didGetOut();
    game.players[playerID].didLeave();

    var isLastPlayer = false;
    // is this the last player?
    if(game.players.length == 1){
        isLastPlayer = true;
    }

    // if they're currently reader or currently guessing, advance to the first or next guesser
    if(game.reader == playerID){
        nextGuesser();
    }
    if(game.guesser == playerID){
        nextGuesser(true);
    }

    if(isLastPlayer){
        betweenRounds();
    }

    game.deletePlayer(playerID);

    return;
}

function submitResponse(channel, response){
    var userID      = getPlayerIndexByChannel(channel);
    var responseID  = game.responses.length;
    var newResponse = new Response(response, responseID, userID, channel);

    // check if there are already max number of responses
    if(game.responses.length >= game.players.length){
        channel.send({ type : 'error', value : ALREADY_HAVE_RESPONSES });
        return;
    }

    // check if there's already a response from this channel
    for(var i = 0; i < game.responses.length; i++){
        if(game.responses[i].channel == channel){
            // update the response
            game.responses[i].response = response;
            return;
        }
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
    var response = new Object();
    for(var i = 0; i < game.responses.length; i++){
        if(game.responses[i].isActive){
            response[i] = game.responses[i].clientSafeVersion();
        }
    }
    // var responseJSON = JSON.stringify(response);
    var responseJSON = response;
    return responseJSON;
}

function startReading(){
    $('#status').html('The reader is reading.');

    // randomize order of responses
    game.responses = shuffle(game.responses);

    // send all responses to the reader.
    var responseJSON = getAllResponsesJSON();
    console.debug('sending responses to reader');
    console.debug(responseJSON);
    game.players[game.reader].channel.send({ type : 'receiveResponses', responses : responseJSON });
}

function startGuessing(){
    // send guesser all responses
    var responseJSON = getAllResponsesJSON();
    console.debug('sending responses to guesser ' + game.players[game.guesser].name);
    console.debug(responseJSON);
    game.players[game.guesser].channel.send({ type : 'receiveResponses', responses : responseJSON });
}

function checkRoundOver(){
    // round is over when only reader's and your own responses are left
    var responsesLeft = 0;
    for(var i = 0; i < game.responses.length; i++){
        if(game.responses[i].isActive){
            responsesLeft++;
        }
    }

    if(responsesLeft <= 2){
        betweenRounds();
    }
}

function submitGuess(channel, guess){
    // only allowed if all responses are in
    if(game.responses.length < game.players.length){
        channel.send({ error : WAITING_ON_RESPONSES });
        return;
    }

    var responseGuessed = guess.guessResponseId;
    var playerGuessed   = guess.guessPlayerNumber;
    var guesserID       = getPlayerIndexByChannel(channel);
    var rgIndex         = -1;

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

    // if you're right, you get a point, a response is pulled, and you can keep guessing.
    if(game.responses[rgIndex].userID == playerGuessed){
        channel.send({ type : 'guessResponse', 'value' : true });
        game.players[guesserID].incrementScore();
        game.players[playerGuessed].didGetOut();
        game.responses[rgIndex].isActive = false;
        $('#response' + guesserID).animate({ 'opacity' : '0.5', 'margin-left' : '-40px' });
        console.log(game.players[guesserID].name + ' correctly guessed that ' + game.players[playerGuessed].name + ' submitted ' + game.responses[rgIndex].response);
        checkRoundOver();
    }
    else{
        // if the person is out, you're dumb and your turn is over.
        if(typeof game.players[playerGuessed] != "undefined" && game.players[playerGuessed].isOut){
            showNotification(game.players[guesserID].name + " guessed someone who was out. Time for a break?");
        }
        channel.send({ type : 'guessResponse', 'value' : false });

        console.log(game.players[guesserID].name + ' incorrectly guessed that ' + game.players[playerGuessed].name + ' submitted ' + game.responses[rgIndex].response);

        // next guesser's turn
        nextGuesser();
    }
}

function showResponses(){
    $('#responses ul').empty();
    for(var i = 0; i < game.responses.length; i++){
        var responseHTML = '<li id="response' + i + '">' + game.responses[i].response + '</li><br />';
        $('#responses ul').append(responseHTML);
    }
}

function advanceGuesser(){
    do{
        var nextGuesser = game.guesser + 1;
        nextGuesser = nextGuesser % game.players.length;
        game.guesser = nextGuesser;
    }while(typeof game.players[game.guesser] == "undefined" || game.players[game.guesser].isOut || game.guesser == game.reader);
}

function nextGuesser(force){
    if(!game.firstGuesser || force){
        advanceGuesser();

        console.debug('guesser is now ' + game.guesser);

        // notify next guesser
        game.players[game.guesser].channel.send({ type : 'guesser' });
    }
    else{
        game.firstGuesser = false;
    }

    // update UI
    $('#status').html('<strong>' + game.players[game.guesser].name + '</strong> is guessing.');

    startGuessing();
}

function startNextRound(){
    // only can start if we're in between rounds
    if(!game.isBetweenRounds){
        console.warn('Tried to start a new round during a round.');
        for(var i = 0; i < game.players.length; i++){
            game.players[i].channel.send({ type : 'error', value : ROUND_IN_PROGRESS });
        }
    }

    // only can start if we have > 2 players
    if((game.players.length + game.playerQueue.length) < 3){
        console.warn("Tried to start new round with not enough players.");
        for(var i = 0; i < game.players.length; i++){
            game.players[i].channel.send({ type : 'error', value : NOT_ENOUGH_PLAYERS });
        }

        $('#instructions').html(game.errors[NOT_ENOUGH_PLAYERS]);

        return;
    }

    newGrind();

    game.isBetweenRounds = false;

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
    // notify everyone that we're in between rounds
    for(var i = 0; i < game.players.length; i++){
        game.players[i].channel.send({ 'type' : 'roundOver' });
    }

    game.isBetweenRounds = true;
    startScreen('Round Over!');
}

// prepare for next question
function newGrind(){
    // delete players who left
    for(var i = 0; i < game.players.length; i++){
        if(game.players[i].isGone){
            game.deletePlayer(i);
        }
    }

    console.debug('processing player queue');
    // add players who are queued
    for(var i = 0; i < game.playerQueue.length; i++){
        console.debug('enqueuing player ' + i);
        game.addPlayer(game.playerQueue[i]);
        console.debug('enqueued player ' + i);
    }

    console.debug('player queue processed');

    // clear player queue
    game.playerQueue = [];

    updatePlayerList();

    // clear responses
    game.responses = [];
    $('#responses ul').empty();

    if(game.players.length > 0){
        // pick next reader
        game.reader++;
        game.reader = game.reader % game.players.length;

        // pick next guesser
        advanceGuesser();
    }
    game.firstGuesser = true;

    console.debug('Next reader is ' + game.reader);
    console.debug('Next guesser is ' + game.guesser);

    // build array of players
    var playerList = new Object();
    for(var i = 0; i < game.players.length; i++){
        playerList[i] = game.players[i].clientSafeVersion();
    }

    // update all clients' user list and scores
    for(var i = 0; i < game.players.length; i++){
        console.debug('sending gameSync to ' + game.players[i].name);
        game.players[i].channel.send({type : 'gameSync', players : playerList, reader : game.players[game.reader].ID, guesser : game.players[game.guesser].ID });
    }

    console.debug('newGrind finished');
}

function updatePlayer(channel, info){
    var playerID = getPlayerIndexByChannel(channel);
    game.players[playerID].name = info.name;
    channel.send({ type : 'settingsUpdated' });
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

        switch(event.message.type){
            case "join":
                joinPlayer(event.target, event.message.name);
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
                startNextRound();
                break;
            case "readerIsDone":
                showResponses();
                nextGuesser();
                break;
            case "updateSettings":
                updatePlayer(event.target, event.message);
                break;
            default:
                console.warn("Invalid type: " + event.message.type);
        }
    }

    function onError(event){
        console.error('error received');
        console.debug(event);
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
}

// initialize
$(function(){
    initGame();
    initReceiver();
});

//+ Jonas Raoni Soares Silva
//@ http://jsfromhell.com/array/shuffle [v1.0]
function shuffle(o){
    for(var j, x, i = o.length; i; j = Math.floor(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
    return o;
};
