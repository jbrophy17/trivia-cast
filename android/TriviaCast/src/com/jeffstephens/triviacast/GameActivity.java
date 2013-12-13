package com.jeffstephens.triviacast;

import java.io.IOException;
import java.util.ArrayList;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.v4.view.MenuItemCompat;
import android.support.v7.app.ActionBarActivity;
import android.support.v7.app.MediaRouteActionProvider;
import android.support.v7.media.MediaRouteSelector;
import android.support.v7.media.MediaRouter;
import android.support.v7.media.MediaRouter.RouteInfo;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;
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


public class GameActivity extends ActionBarActivity implements MediaRouteAdapter {

	// Debug toggle
	public static final boolean IS_DEBUG = false;

	private static final String TAG = GameActivity.class.getSimpleName();
	private static final Logger sLog = new Logger(TAG, true);
	private static final String APP_NAME = "1f96e9a0-9cf0-4e61-910e-c76f33bd42a2";

	private ApplicationSession mSession;
	private SessionListener mSessionListener;
	private TVCStream mGameMessageStream;

	private CastContext mCastContext;
	private CastDevice mSelectedDevice;
	private MediaRouter mMediaRouter;
	private MediaRouteSelector mMediaRouteSelector;
	private MediaRouter.Callback mMediaRouterCallback;

	// UI elements

	// Colors
	private static final int BACKGROUND_ERROR         = 0xFF800000;
	private static final int BACKGROUND_SUCCESS       = 0xFF006600;
	private static final int BACKGROUND_SELECTED_CARD = 0xFFFFFFCC;

	// Game state
	private int playerID = -1;
	private String playerName = null;
	private String currentPrompt = null;
	private PlayerContainer players;
	private ResponseContainer responses;
	private int readerID = -1;
	private int guesserID = -1;
	private boolean doneReading = false;

	// Constants
	private static final String PREF_FILE = "myPreferences";

	/**
	 * Called when the activity is first created. Initializes the game with necessary listeners
	 * for player interaction, and creates a new message stream.
	 */
	@Override
	public void onCreate(Bundle bundle) {
		super.onCreate(bundle);
		setContentView(R.layout.activity_game);

		mSessionListener = new SessionListener();
		mGameMessageStream = new TVCStream();

		mCastContext = new CastContext(getApplicationContext());
		MediaRouteHelper.registerMinimalMediaRouteProvider(mCastContext, this);
		mMediaRouter = MediaRouter.getInstance(getApplicationContext());
		mMediaRouteSelector = MediaRouteHelper.buildMediaRouteSelector(
				MediaRouteHelper.CATEGORY_CAST, APP_NAME, null);
		mMediaRouterCallback = new MediaRouterCallback();

		// Get UI elements

		// add listeners

		// load saved stuff
		loadPlayerName();

		// initialize UI
	}

	/**
	 * Called when the options menu is first created.
	 */
	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		super.onCreateOptionsMenu(menu);
		getMenuInflater().inflate(R.menu.main, menu);
		MenuItem mediaRouteMenuItem = menu.findItem(R.id.media_route_menu_item);
		MediaRouteActionProvider mediaRouteActionProvider =
				(MediaRouteActionProvider) MenuItemCompat.getActionProvider(mediaRouteMenuItem);
		mediaRouteActionProvider.setRouteSelector(mMediaRouteSelector);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item){
		switch(item.getItemId()){
		case R.id.set_name_media_item:
			updatePlayerName();
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}

	/**
	 * Called on application start. Using the previously selected Cast device, attempts to begin a
	 * session using the application name TicTacToe.
	 */
	@Override
	protected void onStart() {
		super.onStart();
		mMediaRouter.addCallback(mMediaRouteSelector, mMediaRouterCallback,
				MediaRouter.CALLBACK_FLAG_PERFORM_ACTIVE_SCAN);
	}

	/**
	 * Removes the activity from memory when the activity is paused.
	 */
	@Override
	protected void onPause() {
		super.onPause();
		finish();
	}

	/**
	 * Attempts to end the current game session when the activity stops.
	 */
	@Override
	protected void onStop() {
		endSession();
		mMediaRouter.removeCallback(mMediaRouterCallback);
		super.onStop();
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
	 * Unregisters the media route provider and disposes the CastContext.
	 */
	@Override
	public void onDestroy() {
		MediaRouteHelper.unregisterMediaRouteProvider(mCastContext);
		mCastContext.dispose();
		mCastContext = null;
		super.onDestroy();
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
	 * Called when a user selects a route.
	 */
	private void onRouteSelected(RouteInfo route) {
		sLog.d("onRouteSelected: %s", route.getName());
		MediaRouteHelper.requestCastDeviceForRoute(route);
	}

	/**
	 * Called when a user unselects a route.
	 */
	private void onRouteUnselected(RouteInfo route) {
		sLog.d("onRouteUnselected: %s", route.getName());
		setSelectedDevice(null);
	}

	/**
	 * An extension of the MediaRoute.Callback specifically for the Cast Against Humanity game.
	 */
	private class MediaRouterCallback extends MediaRouter.Callback {
		@Override
		public void onRouteSelected(MediaRouter router, RouteInfo route) {
			sLog.d("onRouteSelected: %s", route);
			GameActivity.this.onRouteSelected(route);
		}

		@Override
		public void onRouteUnselected(MediaRouter router, RouteInfo route) {
			sLog.d("onRouteUnselected: %s", route);
			GameActivity.this.onRouteUnselected(route);
		}
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

	public void showErrorMessage(String messageText){
		new AlertDialog.Builder(this)
		.setTitle("Uh oh!")
		.setMessage(messageText)
		.setPositiveButton("Dismiss", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int which) { 
				// do nothing for now
			}
		})
		.show();
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

			requestPlayerNameThenJoinGame();
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

	private void savePlayerName(String name){
		SharedPreferences settings = getSharedPreferences(PREF_FILE, 0);
		SharedPreferences.Editor editor = settings.edit();
		playerName = name;
		editor.putString("name", name);
		editor.commit();
	}

	private void loadPlayerName(){
		SharedPreferences settings = getSharedPreferences(PREF_FILE, 0);
		playerName = settings.getString("name", null);
	}

	private void requestPlayerNameThenJoinGame(){
		Log.i(TAG, "Requesting player name");

		// only request name if not set
		if(playerName != null){
			mGameMessageStream.joinGame(playerName);
			return;
		}

		AlertDialog.Builder alert = new AlertDialog.Builder(this);

		alert.setTitle("Enter Player Name");
		alert.setMessage("Set your player name to be displayed on the Chromecast.");
		final EditText input = new EditText(this);

		alert.setView(input);

		alert.setPositiveButton("Set Name", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int whichButton) {
				// check for blank name
				String newName = input.getText().toString();

				// keep asking until a name is supplied
				if(newName.length() == 0){
					showErrorMessage("You've got to supply a name!");
					requestPlayerNameThenJoinGame();
					return;
				}

				savePlayerName(newName);
				Toast.makeText(getApplicationContext(), "Name set to " + playerName, Toast.LENGTH_LONG).show();
				mGameMessageStream.joinGame(playerName);
			}
		});

		alert.create();
		alert.show();
	}

	private void updatePlayerName(){
		Log.i(TAG, "updatePlayerName");

		AlertDialog.Builder alert = new AlertDialog.Builder(this);

		alert.setTitle("Update Player Name");
		alert.setMessage("Set your player name to be displayed on the Chromecast.");
		final EditText input = new EditText(this);

		alert.setView(input);
		if(playerName != null){
			input.setText(playerName);
		}

		alert.setPositiveButton("Change Name", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int whichButton) {
				// check for blank name
				String newName = input.getText().toString();

				if(newName.length() == 0){
					Toast.makeText(getApplicationContext(), "Didn't update player name.", Toast.LENGTH_LONG).show();
					return;
				}

				if(newName == playerName){
					return;
				}

				savePlayerName(newName);
				Toast.makeText(getApplicationContext(), "Name updated to " + playerName, Toast.LENGTH_LONG).show();
				mGameMessageStream.updateSettings(playerName);
			}
		});

		alert.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int whichButton) {
				; // do nothing
			}
		});

		alert.create();
		alert.show();
	}

	private void showInfoMessage(String title, String body, String dismissButton){
		new AlertDialog.Builder(this)
		.setTitle(title)
		.setMessage(body)
		.setPositiveButton(dismissButton, new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int which) { 
				// do nothing for now
			}
		})
		.show();
	}

	/**
	 * An extension of the GameMessageStream specifically for the TriviaCast game.
	 */
	private class TVCStream extends GameMessageStream {

		protected void onPlayerQueued(){
			showInfoMessage("You've Been Queued",
					"You're in the player queue.\nYou'll join the game when the next round starts.",
					"Cool");
		}

		protected void onPlayerJoined(int newID){
			playerID = newID;
		}

		protected void onGameSync(JSONObject players, int newReader, int newGuesser){
			readerID = newReader;
			guesserID = newGuesser;

			// TODO: parse players
		}

		protected void onReceiveResponses(JSONObject responses){
			if(readerID == playerID && !doneReading){
				// TODO: display reader interface
			}

			// TODO: parse responses
		}

		protected void onResponseReceived(){
			// TODO: update UI
		}

		protected void onGuesser(){
			// TODO: display guesser interface
		}

		protected void onGuessResponse(boolean response){
			if(response){
				showInfoMessage("Correct!",
						"You guessed right.",
						"Awesome!");
				
				// TODO: update guesser interface removing guessed response
			}
			else{
				showInfoMessage("Incorrect!",
						"Sorry, your guess was wrong...",
						"Bummer.");
			
				// TODO: hide guesser interface
			}
		}
		
		protected void onRoundStarted(String newPrompt){
			currentPrompt = newPrompt;
			
			// TODO: show composing interface
		}
		
		protected void onRoundEnded(){
			// TODO: show lobby interface
		}
		
		protected void onOrderInitialized(){
			// TODO: show ordering interface
		}
		
		protected void onOrderCanceled(){
			showInfoMessage("Reordering Canceled",
					"The reordering process has been canceled.",
					"OK");
			// TODO: back to lobby interface
		}
		
		protected void onOrderComplete(){
			showInfoMessage("Reordering Complete!",
					"Players are now in a new order - hopefully one that makes more sense.",
					"OK");
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
				messageText = "You guessed the reader!";
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

			showErrorMessage(messageText);
		}

	}
}
