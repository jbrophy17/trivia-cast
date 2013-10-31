
function Player(name, ID) {
    var that = this;
    this.name = name;
    //this.picture = picture;
    this.ID = ID;

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

}
function Game() {
    var that= this;

    this.players = new Array();
    this.responses = new Array();
    this.cues = new Array("Things that hang", "Things that are poor", "Things that nobody wants");

    this.reader = 0;
    this.guesser = 1;

    this.attemptToAddPlayer = function(event) {
        if(event.name != "") {
            var newPlayer = new Player(event.name,that.players.length);
            that.players.push(newPlayer);
            return newPlayer.getNumber();
        }
        else {
            return -1; 
        }
    };
}

// initialize game
$(function() {
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

        if(event.type == "join"){

        }
    }

    function onError(event){
        console.warn('error received');
        console.log(event);
        $.post('debug.php', { msg : event.message.type }, function(data){ console.log('error logged at debug.php')});
        $messages.html(event.message.type);
    }
});
