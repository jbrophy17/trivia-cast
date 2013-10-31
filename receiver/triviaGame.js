// error constants
SENT_BLANK_NAME  = 1;
ALREADY_SENT_RESPONSE = 2;
ALREADY_HAVE_RESPONSES = 3;

function Player(name, ID, channel) {
    var that = this;
    this.name      = name;
    //this.picture = picture;
    this.ID        = ID;
    this.channel   = channel;

    this.isOut     = false;
    this.isGone    = false;

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

    this.players = new Array();
    this.responses = new Array();
    this.cues = new Array("Things that hang", "Things that are poor", "Things that nobody wants");

    this.reader = 0;
    this.guesser = 0;
}

function getPlayerIdByChannel(channel){
    for(var i = 0; i < game.players.length; i++){
        if(game.players[i].channel == channel){
            return i;
        }
    }
}

function joinPlayer(channel, name){
    if(name === ""){
        channel.send({ type : 'error', value : SENT_BLANK_NAME });
        return;
    }

    var newID = game.players.length;
    var newPlayer = new Player(name, newID, channel);
    game.players[newID] = newPlayer;
    channel.send({ number : newID });
}

function leavePlayer(channel){
    // find player, set them as out for the round and set didLeave = true so they're removed before next round
    var i = getPlayerIdByChannel(channel);
    game.players[i].didGetOut();
    game.players[i].didLeave();

    // if they haven't submitted a response yet, leave immediately
    // TODO

    // if they're currently reader, display all responses on screen with a message
    // TODO

    // if they're currently guessing, advance to the next player
    // TODO

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
            channel.send({ type: 'error', value : ALREADY_SENT_RESPONSE });
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
        game.players[guesserID}.incrementScore();
        game.players[playerGuessed].didGetOut();
        game.responses[responseGuessed].isActive = false;
    }
    else{
        // if the person is out, you're dumb and your turn is over.
        if(game.players[playerGuessed].isOut){
            // TODO shame notification
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
    // let everyone know the round has started
    
}

// prepare for next question
function newGrind(){
    // clean up the game state

    // update all clients' user list and scores
    channel.send({type : 'gameSync', players : playerJSON}); // TODO

    // notify next reader


    // show next question and get ready for responses
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
        console.log('message received: ' + event);

        switch(event.type){
            case "join":
                joinPlayer(event.target, event.name);
                break;
            case "leave":
                leavePlayer(event.target);
                break;
            case "submitResponse": // user submits a response
                storeResponse(event.target, event.response);
                break;
            case "submitGuess": // user submits a guess
                tryGuess(event.target, event.guess);
                break;
            case "nextRound":
                startNextRound();
                break;
            case "readerIsDone":
                nextGuesser();
                break;
            default:
                console.warn("Invalid type: " + event.type);
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
