// error constants
SENT_BLANK_NAME  = 1;
ALREADY_HAVE_RESPONSES = 2;

function Player(name, ID, channel) {
    var that = this;
    this.name    = name;
    // this.picture = picture;
    this.ID      = ID;
    this.channel = channel;

    this.isOut   = false;
    this.isGone  = false;

    this.score = 0;

    this.getScore = function() {
        return that.score;
    };

    this.incrementScore = function() {
        that.score++;
    };

    this.getID = function() {
        return that.ID;
    };

    this.didGetOut = function(){
        this.isOut = true;
    }

    this.didLeave = function(){
        this.isGone = true;
    }

}

function Response(response, responseID, userID, channel){
    this.response   = response;
    this.responseID = responseID;
    this.userID     = userID;
    this.channel    = channel;
    this.isActive   = true;

    this.getJSON = function(){
        var thisObj = new Object();
        thisObj.response   = this.response;
        thisObj.responseID = this.responseID;
        return JSON.stringify(thisObj);
    }
}

function Game() {
    var that= this;

    this.players     = new Array();
    this.playerQueue = new Array();
    this.responses   = new Array();
    this.cues        = new Array("Things that hang", "Things that are poor", "Things that nobody wants");
    this.cues        = shuffle(this.cues); // randomize each playthrough

    this.reader  = 0;
    this.guesser = 0;

    this.isBetweenRounds = true;

    this.addPlayer = function(player){
        while(typeof this.players[player.ID] != 'undefined'){
            player.ID++;
        }
        this.players[player.ID] = player;
        player.channel.send({ type : 'didJoin', number : player.ID });
        console.log("Added player " + player.name);
    }

    this.queuePlayer = function(player){
        this.playerQueue.push(player);
        player.channel.send({ type: 'didQueue' });
        console.log("Queued player " + player.name);
    }

    this.deletePlayer = function(id){
        console.log("Deleted player " + this.players[i].name);
        this.players.splice(id, 1);
    }

    this.getNextCue = function(){
        var lastIndex = this.cues.length - 1;
        this.currentCue = this.cues[lastIndex];
        this.cues.splice(lastIndex, 1);
        return this.currentCue;
    }
}

function getPlayerIdByChannel(channel){
    for(var i = 0; i < game.players.length; i++){
        if(game.players[i].channel == channel){
            return i;
        }
    }
}

// update the list of players on screen
function updatePlayerList(){
    $('#playerlist').empty();
    console.debug('updatePlayerList()');
    console.debug(game.players);
    for(var i = 0; i < game.players.length; i++){
        console.debug(game.players[i]);
        var playerHTML = '<li><em>' + game.players[i].score + '</em> ' + game.players[i].name + '</li>';
        $('#playerlist').append(playerHTML);
    }

    $('#notification').slideUp();
    $('#notification').empty();

    if(game.playerQueue.length > 0){
        var notificationHTML;
        if(game.playerQueue.length == 1){
            notificationHTML = '<strong>' + game.playerQueue[0].name + '</strong>';
        }
        else{
            for(var i = 0; i < game.playerQueue.length; i++){
                notificationHTML += '<strong>' + game.playerQueue[i].name + '</strong>';

                // if there's one more player left, put oxford comma + 'and'
                if((i + 2) == game.playerQueue.length){
                    notificationHTML += ', and ';
                }

                // if there's more than one player left, just put a comma
                else if((i + 2) < game.playerQueue.length){
                    notificationHTML += ', ';
                }
            }
        }

        notificationHTML += ' will join the game after this round.';
        showNotification(notificationHTML);
    }
}

function showNotification(text){
    $('#notification').html(text);
    $('#notification').slideDown();
}

function hideNotification(){
    $('#notification').slideUp();
}

// display start screen
function startScreen(){
    hideNotification();
    $('#content h1').html('TriviaCast');
    $('#responses').fadeOut();
    updatePlayerList();
    $('#scoreboard').fadeIn();
}

// display screen for a round of the game
function roundScreen(){
    hideNotification();
    $('#content h1').html(game.currentCue);
    $('#responses').show();
    $('#scoreboard').fadeOut();
}

function joinPlayer(channel, name){
    if(name === ""){
        channel.send({ type : 'error', value : SENT_BLANK_NAME });
        return;
    }

    var newID = game.players.length;
    var newPlayer = new Player(name, newID, channel);

    if(game.isBetweenRounds){
        game.addPlayer(newPlayer);
    }
    else{
        game.queuePlayer(newPlayer);
    }

    updatePlayerList();
}

function leavePlayer(channel){
    // find player, set them as out for the round and set didLeave = true so they're removed before next round
    var playerID = getPlayerIdByChannel(channel);
    game.players[playerID].didGetOut();
    game.players[playerID].didLeave();

    // if they haven't submitted a response yet, leave immediately
    var responseReceived = false;

    for(var i = 0; i < responses.length; i++){
        if(responses[i].userID == playerID){
            responseReceived = true;
        }
    }

    if(!responseReceived){
        game.deletePlayer(playerID);
    }

    // if they're currently reader or currently guessing, advance to the first or next guesser
    if(game.reader == playerID || game.guesser == playerID){
        nextGuesser();
    }

    // if this is the last player, go to start screen and schedule exit
    newGrind();

    return; // only one player per channel
}

function submitResponse(channel, response){
    var userID      = getPlayerIdByChannel(channel);
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

    // if all responses are in, move to reading phase
    if(responseID == game.players.length){
        startReading();
    }
}

function getAllResponsesJSON(){
    var response = new Object();
    for(var i = 0; i < game.responses.length; i++){
        if(game.responses[i].isActive){
            response[i] = game.responses[i].getJSON();
        }
    }
    var responseJSON = JSON.stringify(response);
    return responseJSON;
}

function startReading(){
    // randomize order of responses
    game.responses = shuffle(game.responses);

    // send all responses to the reader.
    game.players[game.reader].channel.send(getAllResponsesJSON());
}

function startGuessing(){
    // send guesser all responses
    game.players[game.guesser].channel.send(getAllResponsesJSON());
}

function submitGuess(channel, guess){
    var responseGuessed = guess.guessResponseId;
    var playerGuessed   = guess.guessPlayerNumber;
    var guesserID       = getPlayerIdByChannel(channel);

    // if you're right, you get a point, a response is pulled, and you can keep guessing.
    if(game.responses[responseGuessed].userID == playerGuessed){
        channel.send({ type : 'guessResponse', value : true });
        game.players[guesserID].incrementScore();
        game.players[playerGuessed].didGetOut();
        game.responses[responseGuessed].isActive = false;
    }
    else{
        // if the person is out, you're dumb and your turn is over.
        if(game.players[playerGuessed].isOut){
            showNotification(game.players[guesserID].name + " guessed someone who was out. Time for a break?");
        }
        channel.send({ type : 'guessResponse', value : false });

        // next guesser's turn
        nextGuesser();
    }
}

function nextGuesser(){
    // round is over when only reader's and your own responses are left
    if(game.responses.length == 2){
        newGrind();
    }
    else{
        var nextGuesser = game.guesser++;
        nextGuesser = nextGuesser % game.players.length;
        game.guesser = nextGuesser;

        // notify next guesser
        game.players[nextGuesser].channel.send({ type : 'guesser' });

        startGuessing();
    }
}

function startNextRound(){
    game.isBetweenRounds = false;

    // show next question
    roundScreen();

    // let everyone know the round has started
    for(var i = 0; i < game.players.length; i++){
        game.players[i].channel.send({ type : 'roundStarted', cue: game.cues[currentCue] });
    }
}

// prepare for next question
function newGrind(){
    game.isBetweenRounds = true;

    startScreen();

    // delete players who left
    for(var i = 0; i < game.players.length; i++){
        if(game.players[i].isGone){
            game.deletePlayer(i);
        }
    }

    // add players who are queued
    for(player in game.playerQueue){
        game.addPlayer(player);
    }

    // clear player queue
    game.playerQueue = [];

    // update player list
    updatePlayerList();

    // clear responses
    game.responses = [];

    // notify next reader
    game.reader++;
    game.reader = game.reader % game.players.length;

    // update all clients' user list and scores
    for(var i = 0; i < game.players.length; i++){
        game.players[i].channel.send({type : 'gameSync', players : playerJSON, reader : game.reader });
    }
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
                storeResponse(event.target, event.message.response);
                break;
            case "submitGuess": // user submits a guess
                tryGuess(event.target, event.message.guess);
                break;
            case "nextRound":
                startNextRound();
                break;
            case "readerIsDone":
                nextGuesser();
                break;
            default:
                console.warn("Invalid type: " + event.message.type);
        }
    }

    function onError(event){
        console.warn('error received');
        console.log(event);
        $.post('debug.php', { msg : event.message.type }, function(data){ console.log('error logged at debug.php')});
        $messages.html(event.message.type);
    }
}

function initGame(){
    game = new Game();
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
