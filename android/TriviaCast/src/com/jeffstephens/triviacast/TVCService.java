package com.jeffstephens.triviacast;

import java.io.IOException;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Binder;
import android.os.IBinder;
import android.support.v4.app.NotificationCompat;
import android.support.v4.content.LocalBroadcastManager;
import android.support.v7.media.MediaRouteSelector;
import android.support.v7.media.MediaRouter;
import android.support.v7.media.MediaRouter.RouteInfo;
import android.util.Log;
import android.widget.Toast;

import com.google.cast.ApplicationChannel;
import com.google.cast.ApplicationMetadata;
import com.google.cast.ApplicationSession;
import com.google.cast.CastContext;
import com.google.cast.CastDevice;
import com.google.cast.Logger;
import com.google.cast.MediaRouteAdapter;
import com.google.cast.MediaRouteHelper;
import com.google.cast.MediaRouteStateChangeListener;
import com.google.cast.SessionError;

public class TVCService extends Service implements MediaRouteAdapter {

	private static final String TAG = GameMessageStream.class.getSimpleName();
	private static final Logger sLog = new Logger(TAG, true);
	private static final String APP_NAME = "1f96e9a0-9cf0-4e61-910e-c76f33bd42a2";

	private ApplicationSession mSession;
	private SessionListener mSessionListener;
	public TVCStream mGameMessageStream;

	private CastContext mCastContext;
	private CastDevice mSelectedDevice;

	private MediaRouter.Callback mMediaRouterCallback;
	private MediaRouter mMediaRouter;
	public MediaRouteSelector mMediaRouteSelector;

	private NotificationManager mNM;
	private int NOTIFICATION = R.string.tvc_service_notification;

	// Game phase constants
	private static final int PHASE_READING        = 100;
	private static final int PHASE_GUESSING       = 101;
	private static final int PHASE_ORDERING       = 102;
	private static final int PHASE_BETWEEN_ROUNDS = 103;
	private static final int PHASE_SUBMITTING     = 104;

	// Game state
	private int playerID = -1;
	private String playerName = null;
	private String currentPrompt = null;
	public PlayerContainer players;
	public ResponseContainer responses;
	private int readerID = -1;
	private int guesserID = -1;
	private boolean currentlyQueued = false;
	private boolean doneReading = false;
	private boolean doneSubmitting = false;
	private boolean outForRound = false;
	private int phase = -1;
	private boolean connected = false;

	private int lastResponseGuessed = -1;

	// Constants
	private static final String PREF_FILE = "myPreferences";
	private static final int EXTRA_QUIT = 1;

	public class TVCBinder extends Binder{
		TVCService getService(){
			return TVCService.this;
		}
	}

	/*
	 *  communication with activity
	 */

	private void sendErrorMessage(String errorText){
		Log.d(TAG, "sending error: " + errorText);

		Intent intent = new Intent(getResources().getString(R.string.local_broadcast_action));
		intent.putExtra("errorText", errorText);
		LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
	}

	private void sendInfoMessage(String title, String body, String dismissButton){
		Log.d(TAG, "sending info message: " + title + ", " + body + ", " + dismissButton);

		Intent intent = new Intent(getResources().getString(R.string.local_broadcast_action));
		intent.putExtra("title", title);
		intent.putExtra("body", body);
		intent.putExtra("dismissButton", dismissButton);
		LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
	}

	private void sendCommand(String command){
		Log.d(TAG, "sending command: " + command);

		updateNotification();

		Intent intent = new Intent(getResources().getString(R.string.local_broadcast_action));
		intent.putExtra("command", command);
		LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
	}

	private void showSubmittingResponseUI(){
		sendCommand(GameActivity.CMD_SHOW_SUBMITTING_RESPONSE_UI);
	}

	private void showInRoundWaitingUI(){
		sendCommand(GameActivity.CMD_SHOW_IN_ROUND_WAITING_UI);
	}

	private void showPlayerQueuedUI(){
		sendCommand(GameActivity.CMD_SHOW_PLAYER_QUEUED_UI);
	}

	private void showOutForRoundUI(){
		sendCommand(GameActivity.CMD_SHOW_OUT_FOR_ROUND_UI);
	}

	private void showReadingUI(){
		sendCommand(GameActivity.CMD_SHOW_READING_UI);
	}

	private void showGuessingUI(){
		sendCommand(GameActivity.CMD_SHOW_GUESSING_UI);
	}

	private void showWaitingForReadingUI(){
		sendCommand(GameActivity.CMD_SHOW_WAITING_FOR_READING_UI);
	}

	private void showComposeUI(){
		sendCommand(GameActivity.CMD_SHOW_COMPOSE_UI);
	}

	private void showLobbyUI(){
		sendCommand(GameActivity.CMD_SHOW_LOBBY_UI);
	}

	private void showPreJoinUI(){
		sendCommand(GameActivity.CMD_SHOW_PRE_JOIN_UI);
	}

	public void updateView(){
		if(!connected){
			showPreJoinUI();
			return;
		}
		
		if(currentlyQueued){
			showPlayerQueuedUI();
			return;
		}

		Log.d(TAG, "updating view. phase = " + phase);

		switch(phase){
		case PHASE_READING:
			if(playerID == readerID && !doneReading){
				showReadingUI();
			}
			else{
				showWaitingForReadingUI();
			}
			break;
		case PHASE_GUESSING:
			Log.d(TAG, "Guessing phase. I'm guesser if my ID (" + playerID + ") = guesser (" + guesserID + ")");
			if(playerID == guesserID){
				showGuessingUI();
			}
			else if(outForRound){
				showOutForRoundUI();
			}
			else{
				showInRoundWaitingUI();
			}
			break;
		case PHASE_ORDERING:
			// TODO
			Log.w(TAG, "Ordering phase, what do");
			break;
		case PHASE_BETWEEN_ROUNDS:
			showLobbyUI();
			break;
		case PHASE_SUBMITTING:
			if(!doneSubmitting){
				showComposeUI();
			}
			else{
				showWaitingForReadingUI();
			}
			break;
		case -1:
			// already checked for queued at top of method
			if(playerID > -1){
				showLobbyUI();
			}
			else{
				showPreJoinUI();
			}
			break;
		default:
			Log.w(TAG, "Invalid phase found: " + phase);
		}
	}

	/*
	 * Lifecycle stuff
	 */

	@Override
	public void onCreate(){
		Log.d(TAG, "TVCService onCreate");
		mSessionListener = new SessionListener();
		mGameMessageStream = new TVCStream();

		mCastContext = new CastContext(getApplicationContext());
		MediaRouteHelper.registerMinimalMediaRouteProvider(mCastContext, this);
		mMediaRouter = MediaRouter.getInstance(getApplicationContext());
		mMediaRouteSelector = MediaRouteHelper.buildMediaRouteSelector(
				MediaRouteHelper.CATEGORY_CAST, APP_NAME, null);

		mMediaRouterCallback = new MediaRouterCallback();

		responses = new ResponseContainer();
		players = new PlayerContainer();

		// load settings
		loadPlayerName();

		// show notification
		initNotification();
	}

	private void initNotification(){
		NotificationCompat.Builder mBuilder = new NotificationCompat.Builder(this);
		Intent notificationIntent = new Intent(this, GameActivity.class);
		PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, 0);
		mBuilder.setContentTitle(getResources().getString(R.string.app_name));
		mBuilder.setContentText(getResources().getString(R.string.app_name));
		mBuilder.setContentIntent(pendingIntent);
		startForeground(NOTIFICATION, mBuilder.build());
	}

	// update the notification text based on the state of the game
	private void updateNotification(){
		String nTitle = new String();
		String nBody = new String();
		String nTicker = new String();

		NotificationCompat.Builder mBuilder = new NotificationCompat.Builder(this);

		boolean showQuitButton = false;
		
		if(!connected){
			nTitle = "Join the Game!";
			nBody = "Choose a Chromecast to start playing.";
			nTicker = "Ready to join the game!";
			showQuitButton = true;
		}

		else if(currentlyQueued){
			nTitle = "Queued";
			nBody = "You'll join the game when the next round starts.";
			nTicker = "Joined the queue.";
			showQuitButton = true;
		}
		else{
			switch(phase){
			case PHASE_READING:
				if(playerID == readerID && !doneReading){
					nTitle = "You're Reader!";
					nBody = "Everyone's waiting on you to read responses.";
					nTicker = "Time to read!";
					mBuilder.setDefaults(Notification.DEFAULT_VIBRATE);
				}
				else{
					nTitle = "Waiting for Reader";
					nBody = "Wait while someone else reads responses.";
					nTicker = "Waiting for reader.";
				}
				break;
			case PHASE_GUESSING:
				if(playerID == guesserID){
					nTitle = "You're Guesser!";
					nBody = "Everyone's waiting on you to make a guess.";
					nTicker = "Time to guess!";
					mBuilder.setDefaults(Notification.DEFAULT_VIBRATE);
				}
				else if(outForRound){
					nTitle = "Out for the Round";
					nBody = "Someone guessed your response.";
					nTicker = "You were guessed!";
				}
				else{
					nTitle = "Someone Else's Turn";
					nBody = "Wait for it to be your turn again.";
					nTicker = "Someone else's turn.";
				}
				break;
			case PHASE_ORDERING:
				// TODO
				Log.w(TAG, "Ordering phase, what do");
				break;
			case PHASE_BETWEEN_ROUNDS:
				nTitle = "Between Rounds";
				nBody = "We're waiting for someone to start the next round.";
				nTicker = "Between rounds.";
				showQuitButton = true;
				break;
			case PHASE_SUBMITTING:
				if(!doneSubmitting){
					nTitle = "Write a Response!";
					nBody = currentPrompt;
					nTicker = "Time to write a response!";
				}
				else{
					nTitle = "Waiting for Responses";
					nBody = "We're waiting on everyone's response.";
					nTicker = "Waiting for responses.";
				}
				break;
			case -1:
				// already checked for queued at top of method
				if(playerID > -1){
					nTitle = "Between Rounds";
					nBody = "We're waiting for someone to start the next round.";
					nTicker = "Between rounds.";
					showQuitButton = true;
				}
				else{
					nTitle = "Join the Game!";
					nBody = "Choose a Chromecast to start playing.";
					nTicker = "Ready to join the game!";
					showQuitButton = true;
				}
				break; 
			}
		}

		// prepend app name
		nTitle = getResources().getString(R.string.app_name) + ": " + nTitle;
		nTicker = getResources().getString(R.string.app_name) + ": " +nTicker;

		// update notification
		PendingIntent contentIntent = PendingIntent.getActivity(this, 0,
				new Intent(this, GameActivity.class), 0);
		mBuilder.setContentTitle(nTitle);
		mBuilder.setContentText(nBody);
		mBuilder.setTicker(nTicker);
		mBuilder.setSmallIcon(R.drawable.ic_launcher);
		mBuilder.setContentIntent(contentIntent);

		// show quit button if appropriate
		if(showQuitButton){
			Intent quitIntent = new Intent(this, TVCService.class);
			quitIntent.putExtra("code", EXTRA_QUIT);
			PendingIntent pi = PendingIntent.getService(this, 0, quitIntent, 0);
			mBuilder.addAction(R.drawable.dialog_ic_close_normal_holo_dark, "Quit TriviaCast", pi);
		}

		mNM.notify(NOTIFICATION, mBuilder.build());
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId){
		Log.i("TVCService", "Received start ID " + startId + ": " + intent);

		int extraCode = intent.getIntExtra("code", 0);

		Log.i(TAG, "extraCode = " + extraCode);

		mMediaRouter.addCallback(mMediaRouteSelector, mMediaRouterCallback,
				MediaRouter.CALLBACK_FLAG_PERFORM_ACTIVE_SCAN);

		mNM = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

		if(extraCode == EXTRA_QUIT){
			sendCommand("quit");
			stopSelf();
		}

		return START_STICKY;
	}

	@Override
	public void onDestroy(){
		Log.i(TAG, "TVCService onDestroy");

		if(connected){
			mGameMessageStream.leaveGame();
		}

		mMediaRouter.removeCallback(mMediaRouterCallback);

		MediaRouteHelper.unregisterMediaRouteProvider(mCastContext);
		mCastContext.dispose();
		mCastContext = null;
	}

	/**
	 * Called when a user selects a route.
	 */
	private void onRouteSelected(RouteInfo route) {
		connected = true;
		sLog.d("onRouteSelected: %s", route.getName());
		MediaRouteHelper.requestCastDeviceForRoute(route);
	}

	/**
	 * Called when a user unselects a route.
	 */
	private void onRouteUnselected(RouteInfo route) {
		connected = false;
		updateNotification();
		updateView();
		sLog.d("onRouteUnselected: %s", route.getName());
		setSelectedDevice(null);
	}


	/**
	 * An extension of the MediaRoute.Callback specifically for TriviaCast.
	 */
	private class MediaRouterCallback extends MediaRouter.Callback {
		@Override
		public void onRouteSelected(MediaRouter router, RouteInfo route) {
			sLog.d("onRouteSelected: %s", route);
			TVCService.this.onRouteSelected(route);
		}

		@Override
		public void onRouteUnselected(MediaRouter router, RouteInfo route) {
			sLog.d("onRouteUnselected: %s", route);
			TVCService.this.onRouteUnselected(route);
		}
	}

	@Override
	public IBinder onBind(Intent intent){
		return mBinder;
	}

	private final IBinder mBinder = new TVCBinder();


	/*
	 * Methods for UI activity to update model
	 */

	public boolean playerHasName(){
		return playerName != null;
	}

	public String getPlayerName(){
		return playerName;
	}

	public void setPlayerName(String newName){
		savePlayerName(newName);
	}

	public String getCurrentPrompt(){
		return currentPrompt;
	}

	public int getPlayerID(){
		return playerID;
	}

	public int getReaderID(){
		return readerID;
	}

	public ResponseContainer getResponses(){
		return responses;
	}

	public void readerIsDone(){
		doneReading = true;
		mGameMessageStream.readerIsDone();

		if(playerID != readerID){
			showInRoundWaitingUI();
		}
	}

	public void submitResponse(String response){
		mGameMessageStream.submitResponse(response);
		doneSubmitting = true;
	}

	public void submitGuess(int responseID, int playerID){
		lastResponseGuessed = responseID;
		mGameMessageStream.submitGuess(responseID, playerID);
	}


	/*
	 * Settings
	 */

	private void savePlayerName(String name){
		Log.d(TAG, "saving player name: " + name);
		SharedPreferences settings = getSharedPreferences(PREF_FILE, 0);
		SharedPreferences.Editor editor = settings.edit();
		playerName = name;
		editor.putString("name", name);
		editor.commit();
	}

	private void loadPlayerName(){
		Log.d(TAG, "loading player name");
		SharedPreferences settings = getSharedPreferences(PREF_FILE, 0);
		playerName = settings.getString("name", null);
	}


	/* MediaRouteAdapter implementation */

	@Override
	public void onDeviceAvailable(CastDevice device, String routeId,
			MediaRouteStateChangeListener listener) {
		sLog.d("onDeviceAvailable: %s (route %s)", device, routeId);
		setSelectedDevice(device);
	}

	@Override
	public void onSetVolume(double volume) {
	}

	@Override
	public void onUpdateVolume(double delta) {
	}

	private void setSelectedDevice(CastDevice device) {
		mSelectedDevice = device;
		Log.i(TAG, "setSelectedDevice()");

		if (mSelectedDevice != null) {
			mSession = new ApplicationSession(mCastContext, mSelectedDevice);
			mSession.setListener(mSessionListener);

			try {
				mSession.startSession(APP_NAME);
			} catch (IOException e) {
				Log.e(TAG, "Failed to open a session", e);
			}
		} else {
			endSession();
			Log.e(TAG, "Failed to set selected device.");
		}
	}



	/**
	 * Ends any existing application session with a Chromecast device.
	 */
	private void endSession() {
		if ((mSession != null) && (mSession.hasStarted())) {
			try {
				if (mSession.hasChannel()) {
					mGameMessageStream.leaveGame();
				}
				mSession.endSession();
			} catch (IOException e) {
				Log.e(TAG, "Failed to end the session.", e);
			} catch (IllegalStateException e) {
				Log.e(TAG, "Unable to end session.", e);
			} finally {
				mSession = null;
			}
		}
	}


	/**
	 * A class which listens to session start events. On detection, it attaches the game's message
	 * stream and joins a player to the game.
	 */
	private class SessionListener implements ApplicationSession.Listener {
		@Override
		public void onSessionStarted(ApplicationMetadata appMetadata) {
			sLog.d("SessionListener.onStarted");

			ApplicationChannel channel = mSession.getChannel();
			if (channel == null) {
				Log.w(TAG, "onStarted: channel is null");
				return;
			}
			channel.attachMessageStream(mGameMessageStream);

			mGameMessageStream.joinGame(playerName);
		}

		@Override
		public void onSessionStartFailed(SessionError error) {
			sLog.d("SessionListener.onStartFailed: %s", error);
		}

		@Override
		public void onSessionEnded(SessionError error) {
			sLog.d("SessionListener.onEnded: %s", error);
		}
	}

	/**
	 * An extension of the GameMessageStream specifically for the TriviaCast game.
	 */
	public class TVCStream extends GameMessageStream {

		protected void onPlayerQueued(){
			currentlyQueued = true;
			showPlayerQueuedUI();
		}

		protected void onPlayerJoined(int newID){
			currentlyQueued = false;
			playerID = newID;
		}

		protected void onSettingsUpdated(){
			Toast.makeText(getApplicationContext(), "Name updated to " + playerName, Toast.LENGTH_LONG).show();
		}

		protected void onGameSync(JSONArray newPlayers, int newReader, int newGuesser){
			if(newReader >= 0){
				readerID = newReader;
			}

			Log.d(TAG, "updating guesser from " + guesserID + " to " + newGuesser);
			guesserID = newGuesser;

			players.clear();

			try{
				for(int i = 0; i < newPlayers.length(); ++i){
					JSONObject thisPlayerJSON = newPlayers.getJSONObject(i);
					int thisID = thisPlayerJSON.getInt("ID");
					int thisScore = thisPlayerJSON.getInt("score");
					String thisName = thisPlayerJSON.getString("name");
					String thisPictureURL = thisPlayerJSON.getString("pictureURL");
					boolean thisIsOut = thisPlayerJSON.getBoolean("isOut");
					Player thisPlayer = new Player(thisID, thisScore, thisName, thisPictureURL, thisIsOut);

					players.addPlayer(thisPlayer);
				}

				try{
					if(players.getPlayerById(playerID).isOut){
						outForRound = true;
						showOutForRoundUI();
					}
				}
				catch(PlayerNotFoundException ex){
					;
				}
			}
			catch (JSONException e){
				e.printStackTrace();
			}
		}

		protected void onReceiveResponses(JSONArray newResponses){			
			Log.d(TAG, "Got " + newResponses.length() + " responses");

			responses.clear();

			try{
				for(int i = 0; i < newResponses.length(); ++i){
					JSONObject thisSet = newResponses.getJSONObject(i);
					Response thisResponse = new Response(thisSet.getInt("responseID"), thisSet.getString("response"));
					responses.addResponse(thisResponse);
				}
			}
			catch (JSONException e) {
				e.printStackTrace();
			}

			Log.i(TAG, "populated responses with " + responses.size());

			if(readerID == playerID && !doneReading){
				showReadingUI();
			}
			else{
				showGuessingUI();
			}

		}

		protected void onResponseReceived(){
			// only show waiting for reading when you're not the reader
			showWaitingForReadingUI();
		}

		protected void onGuessResponse(boolean response){
			if(response){
				Toast.makeText(getApplicationContext(), "You guessed correctly!", Toast.LENGTH_LONG).show();
				responses.removeResponseById(lastResponseGuessed); // remove from selectable responses

				if(responses.size() == 0){
					showInRoundWaitingUI();
				}
				else{
					showGuessingUI();
				}
			}
			else{
				Toast.makeText(getApplicationContext(), "You guessed incorrectly.", Toast.LENGTH_LONG).show();
				showInRoundWaitingUI();
			}
		}

		protected void onRoundStarted(String newPrompt){
			doneReading = false; 
			doneSubmitting = false;
			outForRound = false;
			currentPrompt = newPrompt;
			showComposeUI();
		}

		protected void onRoundEnded(){
			updateNotification();
			showLobbyUI();
		}

		protected void onOrderInitialized(){
			// TODO: show ordering interface
		}

		protected void onOrderCanceled(){
			sendInfoMessage("Reordering Canceled",
					"The reordering process has been canceled.",
					"OK");
			showLobbyUI();
		}

		protected void onOrderComplete(){
			sendInfoMessage("Reordering Complete!",
					"Players are now in a new order - hopefully one that makes more sense.",
					"OK"); 
			showLobbyUI();
		}

		protected void onCurrentPhase(int newPhase){
			phase = newPhase;
		}

		// Some error code has been received. Let the user know.
		protected void onServerError(int errorCode){
			String messageText;
			switch(errorCode){
			case ERROR_RECEIVED_INVALID_MESSAGE_TYPE:
				messageText = "Received invalid data from server.";
				break;
			case ERROR_SENT_BLANK_NAME:
				messageText = "Your name can't be blank.";
				break;
			case ERROR_TOO_MANY_RESPONSES:
				messageText = "There are already the maximum number of responses.";
				break;
			case ERROR_CANT_GUESS_YET:
				messageText = "You can't submit a guess until all responses are in and have been read.";
				break;
			case ERROR_NOT_ENOUGH_PLAYERS_TO_START_ROUND:
				messageText = "There aren't enough players to start a new round yet.";
				break;
			case ERROR_ROUND_IN_PROGRESS:
				messageText = "A round is already in progress!";
				break;
			case ERROR_GUESSED_THE_READER:
				messageText = "You guessed the reader!"; // deprecated
				break;
			case ERROR_GUESSED_SELF:
				messageText = "You guessed yourself.";
				break;
			case ERROR_INVALID_MESSAGE_TYPE:
				messageText = "The server received invalid data.";
				break;
			case ERROR_ORDERING_WRONG_PHASE:
				messageText = "You can only start the reordering process between rounds.";
				break;
			case ERROR_ORDERING_NOT_HAPPENING:
				messageText = "The reordering process isn't going on, so you can't cancel it.";
				break;
			case ERROR_NOT_ENOUGH_PLAYERS_TO_ORDER:
				messageText = "There aren't enough players to change their order yet.";
				break;
			default:
				messageText = "An unknown error occurred.";
			}

			sendErrorMessage(messageText);
		}

	}

}