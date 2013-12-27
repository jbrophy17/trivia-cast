# TriviaCast
#### A Game for Friends

TriviaCast is a party game designed to be played with friends using a [Google Chromecast](http://www.google.com/intl/en/chrome/devices/chromecast/).

## Rules of the Game

* You need at least 3 people (the more the merrier)
* Once everyone has joined the game via the app, you can start the round from the lobby
* At this point, a prompt will appear on the TV and on everybody's phone
* Everybody writes a response to the given prompt and submits it
* Once everyone has submitted a response, **The Reader** will receive all the responses, in random order, on his/her phone
* **The Reader** should then read each of the responses aloud
* After reading all the responses, **The Reader** becomes **The Guesser**
* **The Guesser** looks at the responses and attempts to guess who said each response, using his/her phone
* If **The Guesser** makes a correct guess, s/he receives 1 point and the guessed player is now **Out**
* If **The Guesser** makes an incorrect guess, his/her turn is over and the next player (who is not **Out**) becomes **The Guesser**
* **The Guesser** continues to guess until s/he makes an incorrect guess or everybody else is **Out**.
* Once everyone except **The Guesser** is **Out**, the round ends
* Any players who joined mid game will be added at the start of the next round
* Play as many rounds as you like

## Key Terms
###The Reader
* Reads all the responses aloud
* Only exists at the begining of each new round

###The Guesser
* Guesses a response for a player
* Changes after each incorrect guess

###Out
* If your response is guessed, you are **Out**
* You are done for this round and cannot become **The Guesser**

## Setup Instructions

While the Chromecast SDK is in a limited preview, this app can't publically used without some configuration. Follow these steps to get it set up:

1. [Buy a Chromecast](https://play.google.com/store/devices/details?id=chromecast)
2. [Whitelist your Chromecast for development](https://docs.google.com/a/google.com/forms/d/1dwWBstwCRL1mdEbSxSVFkxyo4R-2iQczl1ttgeqSeRw/viewform).
 * If you'd like to host your own version of the game, upload `/receiver/*` to a web server and use that web address in the whitelisting form.
 * If you just want to try it out, you can use `http://trivia-cast.com/receiver.html` as the web address, make a pull request with your app key filled in in `TVCConstants.m`, `TVCConstants.java`, and `TVCConstants.js`, or email [jefftheman45@gmail.com](mailto:jefftheman45@gmail.com) with your app key, and we'll keep that key in the apps and the server for a few days.
3. If you're using your own server, you'll have to enter the application key in both the iOS and Android apps (`TVCConstants.m` and `TVCConstants.java`, respectively) and build the apps, and enter your key in `TVCConstants.js`.
