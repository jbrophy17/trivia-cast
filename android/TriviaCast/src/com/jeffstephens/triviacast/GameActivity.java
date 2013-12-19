package com.jeffstephens.triviacast;

import java.io.IOException;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentTransaction;
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
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
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
import com.jeffstephens.triviacast.TVCComposer.ComposerListener;
import com.jeffstephens.triviacast.TVCResponseReader.ReaderListener;

public class GameActivity extends ActionBarActivity implements MediaRouteAdapter, ComposerListener, ReaderListener {

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
	private Button nextRoundButton;
	private TextView instructionsTextView;

	// Game state
	private int playerID = -1;
	private String playerName = null;
	private String currentPrompt = null;
	private PlayerContainer players;
	private ResponseContainer responses;
	private int readerID = -1;
	private int guesserID = -1;
	private boolean doneReading = false;

	private int lastResponseGuessed = -1;

	// Constants
	private static final String PREF_FILE = "myPreferences";
	private static final String TAG_COMPOSE_FRAGMENT = "COMPOSE_FRAGMENT";
	private static final String TAG_READ_FRAGMENT = "READ_FRAGMENT";

	/**
	 * Interface so fragment can access prompt text
	 */
	@Override
	public String getPromptText() {
		return currentPrompt;
	}

	@Override
	public void submitResponseText(String response){
		mGameMessageStream.submitResponse(response);
		showSubmittingResponseUI();
	}

	/**
	 * Interface so reader can say they're done
	 * and guesses can be submitted
	 */
	@Override
	public void readerIsDone(){
		doneReading = true;
		mGameMessageStream.readerIsDone();

		if(playerID != readerID){
			showInRoundWaitingUI();
		}
	}

	@Override
	public PlayerContainer getPlayers(){
		return players;
	}

	@Override
	public ResponseContainer getResponseContainer(){
		return responses;
	}

	@Override
	public void submitGuess(int responseID, int playerID){
		lastResponseGuessed = responseID;
		mGameMessageStream.submitGuess(responseID, playerID);
		showInRoundWaitingUI();
	}

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

		responses = new ResponseContainer();
		players = new PlayerContainer();

		// Get UI elements
		nextRoundButton = (Button) findViewById(R.id.button_next_round);
		instructionsTextView = (TextView) findViewById(R.id.instructions);

		// add listeners
		nextRoundButton.setOnClickListener(new Button.OnClickListener(){
			public void onClick(View v){
				mGameMessageStream.startNextRound();
			}
		});

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

	private void clearFragments(){
		Log.d(TAG, "clearing fragments");

		FrameLayout fragmentContainer = (FrameLayout) findViewById(R.id.fragment_container);
		fragmentContainer.setVisibility(View.GONE);

		//		FragmentManager fragmentManager = getSupportFragmentManager();
		//		FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
		//		TVCComposer fragmentComposer = (TVCComposer) fragmentManager.findFragmentByTag(TAG_COMPOSE_FRAGMENT);
		//		TVCResponseReader fragmentReader = (TVCResponseReader) fragmentManager.findFragmentByTag(TAG_READ_FRAGMENT);
		//
		//		try{
		//			fragmentTransaction.remove(fragmentComposer);
		//			fragmentTransaction.remove(fragmentReader);
		//		}
		//		catch (IllegalStateException ex){
		//			Log.w(TAG, "Got an exception in clearFragments");
		//			Log.w(TAG, ex.toString());
		//			; // no problem here
		//		}
		//
		//		fragmentTransaction.commit();

		Log.d(TAG, "fragments cleared");
	}

	private void showFragments(){
		FrameLayout fragmentContainer = (FrameLayout) findViewById(R.id.fragment_container);
		fragmentContainer.setVisibility(View.VISIBLE);
	}

	private void showLobbyUI(){
		clearFragments();
		instructionsTextView.setText(R.string.between_rounds);
		instructionsTextView.setVisibility(View.VISIBLE);
		nextRoundButton.setVisibility(View.VISIBLE);
	}

	private void showComposeUI(){
		// hide lobby UI
		instructionsTextView.setVisibility(View.GONE);
		nextRoundButton.setVisibility(View.GONE);

		// show compose UI
		FragmentManager fragmentManager = getSupportFragmentManager();
		FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
		TVCComposer fragment = new TVCComposer();
		fragmentTransaction.replace(R.id.fragment_container, fragment, TAG_COMPOSE_FRAGMENT);
		fragmentTransaction.commit();
		showFragments();
	}

	private void showSubmittingResponseUI(){
		Log.d(TAG, "showSubmittingResponseUI()");
		// hide compose UI
		clearFragments();

		// show submitting UI
		instructionsTextView.setText(R.string.submitting_response);
		instructionsTextView.setVisibility(View.VISIBLE);
		Log.d(TAG, "finished showSubmittingResponseUI()");
	}

	private void showWaitingForReadingUI(){
		// hide compose UI
		clearFragments();

		// show waiting UI
		instructionsTextView.setText(R.string.waiting_for_other_responses_message);
		instructionsTextView.setVisibility(View.VISIBLE);
	}

	private void goGoTVCResponseReader(boolean guessingMode){
		Bundle args = new Bundle();
		args.putString("prompt", currentPrompt);
		args.putBoolean("guessingMode", guessingMode);
		args.putInt("playerID", playerID);

		FragmentManager fragmentManager = getSupportFragmentManager();
		FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
		TVCResponseReader fragment = new TVCResponseReader();
		fragment.setArguments(args);
		fragmentTransaction.replace(R.id.fragment_container, fragment, TAG_READ_FRAGMENT);
		fragmentTransaction.commit();
		showFragments();
	}

	private void showReadingUI(){
		Log.d(TAG, "Showing reading UI");

		// hide waiting UI
		hideInstructions();

		// show reading UI
		goGoTVCResponseReader(false);
	}

	private void showInRoundWaitingUI(){
		Log.d(TAG, "showInRoundWaitingUI()");

		// hide reader or guessing UI
		clearFragments();

		instructionsTextView.setVisibility(View.VISIBLE);
		instructionsTextView.setText(R.string.someone_elses_turn);

		Log.d(TAG, "finished showInRoundWaitingUI()");
	}

	private void hideInstructions(){
		instructionsTextView.setVisibility(View.GONE);
	}

	private void showGuessingUI(){
		// hide in round waiting UI
		hideInstructions();

		// show guessing UI
		if(playerID != readerID){
			goGoTVCResponseReader(true);
		}
		else{
			TVCResponseReader reader = (TVCResponseReader) getSupportFragmentManager().findFragmentByTag(TAG_READ_FRAGMENT);
			showFragments();
			reader.updateResponses(responses);
			reader.initGuessingMode();
		}
	}

	/**
	 * An extension of the GameMessageStream specifically for the TriviaCast game.
	 */
	private class TVCStream extends GameMessageStream {

		protected void onPlayerQueued(){
			nextRoundButton.setVisibility(View.VISIBLE);
			instructionsTextView.setText(R.string.in_queue_message);
		}

		protected void onPlayerJoined(int newID){
			playerID = newID;
		}

		protected void onSettingsUpdated(){
			Toast.makeText(getApplicationContext(), "Name updated to " + playerName, Toast.LENGTH_LONG).show();
		}

		protected void onGameSync(JSONArray newPlayers, int newReader, int newGuesser){
			if(newReader >= 0){
				readerID = newReader;
			}

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
						instructionsTextView.setText(R.string.youre_out_for_round);
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
			currentPrompt = newPrompt;
			showComposeUI();
		}

		protected void onRoundEnded(){
			showLobbyUI();
		}

		protected void onOrderInitialized(){
			// TODO: show ordering interface
		}

		protected void onOrderCanceled(){
			showInfoMessage("Reordering Canceled",
					"The reordering process has been canceled.",
					"OK");
			showLobbyUI();
		}

		protected void onOrderComplete(){
			showInfoMessage("Reordering Complete!",
					"Players are now in a new order - hopefully one that makes more sense.",
					"OK"); 
			showLobbyUI();
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

			showErrorMessage(messageText);
		}

	}
}
