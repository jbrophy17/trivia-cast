
function Player(name, number) {
  var that = this;
  this.name = name;
  //this.picture = picture;
  this.number = number;

  this.score = 0;
  
  this.getScore= function() {
    return that.score;
  };

  this.incrementScore = function() {
    that.score++;
  };

  this.getNumber = function() {
    return that.number;
  };

}
function Game() {
    var that= this;

    this.players= new Array();
    this.responses = new Array();
    this.cues = new Array("Things that hang", "Things that are poor", "Things that nobody wants");

    this.reader = 0;
    this.guesser = 1;

    this.attemptToAddPlayer= function(event) {

      if(event.name != "") {
        var newPlayer = new Player(event.name,that.players.length);
        that.players.push(newPlayer);
        return newPlayer.getNumber();
      } else {
        return -1; 
      }
    };

    this.

}