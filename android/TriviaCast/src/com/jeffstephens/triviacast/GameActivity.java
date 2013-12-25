package com.jeffstephens.triviacast;

import com.jeffstephens.triviacast.TVCComposer.ComposerListener;
import com.jeffstephens.triviacast.TVCResponseReader.ReaderListener;

import android.app.AlertDialog;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentTransaction;
import android.support.v4.content.LocalBroadcastManager;
import android.support.v4.view.MenuItemCompat;
import android.support.v7.app.ActionBarActivity;
import android.support.v7.app.MediaRouteActionProvider;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.TextView;
import android.widget.Toast;

public class GameActivity extends ActionBarActivity implements ComposerListener, ReaderListener {

	// Debug toggle
	public static final boolean IS_DEBUG = false;
	private static final String TAG = GameActivity.class.getSimpleName();
	private TVCService mBoundService;

	// string constants for broadcasts
	public static final String CMD_SHOW_SUBMITTING_RESPONSE_UI = "showSubmittingResponseUI";
	public static final String CMD_SHOW_IN_ROUND_WAITING_UI = "showInRoundWaitingUI";
	public static final String CMD_SHOW_PLAYER_QUEUED_UI = "showPlayerQueuedUI";
	public static final String CMD_SHOW_OUT_FOR_ROUND_UI = "showOutForRoundUI";
	public static final String CMD_SHOW_READING_UI = "showReadingUI";
	public static final String CMD_SHOW_GUESSING_UI = "showGuessingUI";
	public static final String CMD_SHOW_WAITING_FOR_READING_UI = "showWaitingForReadingUI";
	public static final String CMD_SHOW_COMPOSE_UI = "showComposeUI";
	public static final String CMD_SHOW_LOBBY_UI = "showLobbyUI";
	public static final String CMD_SHOW_PRE_JOIN_UI = "showPreJoinUI";

	// UI elements
	private Button nextRoundButton;
	private TextView instructionsTextView;

	private static final String TAG_COMPOSE_FRAGMENT = "COMPOSE_FRAGMENT";
	private static final String TAG_READ_FRAGMENT = "READ_FRAGMENT";

	private BroadcastReceiver mMessageReceiver = new BroadcastReceiver(){
		@Override
		public void onReceive(Context context, Intent intent){
			String command = intent.getStringExtra("command");

			if(command == null){
				String errorText = intent.getStringExtra("errorText");

				if(errorText == null){
					String title = intent.getStringExtra("title");
					String body = intent.getStringExtra("body");
					String dismissButton = intent.getStringExtra("dismissButton");

					if(title != null && body != null && dismissButton != null){
						showInfoMessage(title, body, dismissButton);
					}
					else{
						Log.e(TAG, "Received invalid broadcast");
					}
				}
				else{
					showErrorMessage(errorText);
				}
			}

			else{
				Log.d(TAG, "got command: " + command);

				if(CMD_SHOW_SUBMITTING_RESPONSE_UI.equals(command)){
					showSubmittingResponseUI();
				}

				else if(CMD_SHOW_IN_ROUND_WAITING_UI.equals(command)){
					showInRoundWaitingUI();
				}

				else if(CMD_SHOW_PLAYER_QUEUED_UI.equals(command)){
					showPlayerQueuedUI();
				}

				else if(CMD_SHOW_OUT_FOR_ROUND_UI.equals(command)){
					showOutForRoundUI();
				}

				else if(CMD_SHOW_READING_UI.equals(command)){
					showReadingUI();
				}

				else if(CMD_SHOW_GUESSING_UI.equals(command)){
					showGuessingUI();
				}

				else if(CMD_SHOW_WAITING_FOR_READING_UI.equals(command)){
					showWaitingForReadingUI();
				}

				else if(CMD_SHOW_COMPOSE_UI.equals(command)){
					showComposeUI();
				}

				else if(CMD_SHOW_LOBBY_UI.equals(command)){
					showLobbyUI();
				}

				else if(CMD_SHOW_PRE_JOIN_UI.equals(command)){
					showPreJoinUI();
				}

				else{
					Log.e(TAG, "Received bad command from LocalBroadcast: " + command);
				}
			}
		}
	};

	/**
	 * Called when the activity is first created. Initializes the game with necessary listeners
	 * for player interaction, and creates a new message stream.
	 */
	@Override
	public void onCreate(Bundle bundle) {
		Log.i(TAG, "GameActivity onCreate");
		
		super.onCreate(bundle);
		setContentView(R.layout.activity_game);

		// Get UI elements
		nextRoundButton = (Button) findViewById(R.id.button_next_round);
		instructionsTextView = (TextView) findViewById(R.id.instructions);

		// add listeners
		nextRoundButton.setOnClickListener(new Button.OnClickListener(){
			public void onClick(View v){
				mBoundService.mGameMessageStream.startNextRound();
			}
		});

		// register to receive messages (will be sent from the service)
		LocalBroadcastManager.getInstance(this).registerReceiver(mMessageReceiver, new IntentFilter(getResources().getString(R.string.local_broadcast_action)));

		// start game service
		Log.d(TAG, "about to startService()");
		Intent serviceIntent = new Intent(this, TVCService.class);
		startService(serviceIntent);
		Log.d(TAG, "about to bindService()");	
		bindService(new Intent(this, TVCService.class), mConnection, Context.BIND_AUTO_CREATE);
	}

	private ServiceConnection mConnection = new ServiceConnection(){
		public void onServiceConnected(ComponentName className, IBinder service) {
			mBoundService = ((TVCService.TVCBinder)service).getService();

			// check if player name is set; if not, make the player enter one
			if(!mBoundService.playerHasName()){
				updatePlayerName(true);
			}

			// display UI for appropriate part of game
			mBoundService.updateView();
		}

		public void onServiceDisconnected(ComponentName className) {
			// should never happen
			mBoundService = null;
		}
	};

	@Override
	public void onBackPressed() {
		Toast.makeText(getApplicationContext(), R.string.back_button_does_nothing, Toast.LENGTH_LONG).show();
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
		mediaRouteActionProvider.setRouteSelector(mBoundService.mMediaRouteSelector);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item){
		switch(item.getItemId()){
		case R.id.set_name_menu_item:
			updatePlayerName(false);
			return true;
		case R.id.quit_game_menu_item:
			// kill service
			Intent serviceIntent = new Intent(this, TVCService.class);
			stopService(serviceIntent);
			
			// go to home
			Intent intent = new Intent(Intent.ACTION_MAIN);
			intent.addCategory(Intent.CATEGORY_HOME);
			intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			startActivity(intent);
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
	}

	/**
	 * Removes the activity from memory when the activity is paused.
	 */
	@Override
	protected void onPause() {
		Log.i(TAG, "GameActivity onPause");
		super.onPause();
		finish();
	}

	/**
	 * Attempts to end the current game session when the activity stops.
	 */
	@Override
	protected void onStop() {
		Log.i(TAG, "GameActivity onStop");
		super.onStop();
	}

	/**
	 * Unregisters the media route provider and disposes the CastContext.
	 */
	@Override
	public void onDestroy() {
		Log.i(TAG, "GameActivity onDestroy");
		LocalBroadcastManager.getInstance(this).unregisterReceiver(mMessageReceiver);
		unbindService(mConnection);
		super.onDestroy();
	}

	/**
	 * Interface so fragment can access prompt text
	 */
	@Override
	public String getPromptText() {
		return mBoundService.getCurrentPrompt();
	}

	@Override
	public void submitResponseText(String response){
		mBoundService.submitResponse(response);
		showSubmittingResponseUI();
	}

	/**
	 * Interface so reader can say they're done
	 * and guesses can be submitted
	 */
	@Override
	public void readerIsDone(){
		mBoundService.readerIsDone();
	}

	@Override
	public PlayerContainer getPlayers(){
		return mBoundService.players;
	}

	@Override
	public ResponseContainer getResponseContainer(){
		return mBoundService.responses;
	}

	@Override
	public void submitGuess(int responseID, int playerID){
		mBoundService.submitGuess(responseID, playerID);
		showInRoundWaitingUI();
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

	private void updatePlayerName(final boolean required){
		Log.i(TAG, "updatePlayerName");

		AlertDialog.Builder alert = new AlertDialog.Builder(this);

		alert.setTitle("Update Player Name");
		alert.setMessage("Set your player name to be displayed on the Chromecast.");
		final EditText input = new EditText(this);

		final String playerName = mBoundService.getPlayerName();
		Log.d(TAG, "updatePlayerName(): old name is " + playerName);

		alert.setView(input);
		if(mBoundService.playerHasName()){
			input.setText(playerName);
		}

		alert.setPositiveButton("Change Name", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int whichButton) {
				// check for blank name
				String newName = input.getText().toString().trim();

				if(newName.length() == 0){
					if(required){
						updatePlayerName(true);
						Toast.makeText(getApplicationContext(), "You must enter a name.", Toast.LENGTH_LONG).show();
						return;
					}
					else{
						Toast.makeText(getApplicationContext(), "Canceled name update.", Toast.LENGTH_LONG).show();
						return;
					}
				}

				if(newName == playerName){
					return;
				}

				mBoundService.setPlayerName(newName);
			}
		});

		if(!required){
			alert.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
				public void onClick(DialogInterface dialog, int whichButton) {
					Toast.makeText(getApplicationContext(), "Canceled name update.", Toast.LENGTH_LONG).show();
					return;
				}
			});
		}
		else{
			alert.setCancelable(false);
		}

		alert.create();
		alert.show();
	}

	public void showInfoMessage(String title, String body, String dismissButton){
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

		Log.d(TAG, "fragments cleared");
	}

	private void showFragments(){
		FrameLayout fragmentContainer = (FrameLayout) findViewById(R.id.fragment_container);
		fragmentContainer.setVisibility(View.VISIBLE);
	}

	private void showPreJoinUI(){
		clearFragments();
		instructionsTextView.setText(R.string.choose_chromecast);
		nextRoundButton.setVisibility(View.GONE);
	}

	private void showLobbyUI(){
		clearFragments();
		instructionsTextView.setText(R.string.between_rounds);
		instructionsTextView.setVisibility(View.VISIBLE);
		nextRoundButton.setVisibility(View.VISIBLE);
	}

	private void showPlayerQueuedUI(){
		nextRoundButton.setVisibility(View.VISIBLE);
		instructionsTextView.setText(R.string.in_queue_message);
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
		String currentPrompt = mBoundService.getCurrentPrompt();
		int playerID = mBoundService.getPlayerID();

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

	private void showOutForRoundUI(){
		instructionsTextView.setText(R.string.youre_out_for_round);
	}

	private void hideInstructions(){
		instructionsTextView.setVisibility(View.GONE);
	}

	private void showGuessingUI(){
		// hide in round waiting UI
		hideInstructions();

		goGoTVCResponseReader(true);
	}

}
