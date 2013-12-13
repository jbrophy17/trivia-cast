/*
 * Copyright (C) 2013 Google Inc. All Rights Reserved. 
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at 
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software 
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and 
 * limitations under the License.
 */

package com.jeffstephens.triviacast;

import com.google.cast.MessageStream;

import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;

/**
 * An abstract class which encapsulates control and game logic for sending and receiving messages 
 * during a Cast Against Humanity game.
 */
public abstract class GameMessageStream extends MessageStream {
	private static final String TAG = GameMessageStream.class.getSimpleName();

	private static final String GAME_NAMESPACE = "com.bears.triviaCast";

	// What the JSON is made of
	private static final String KEY_TYPE = "type";
	private static final String KEY_NAME = "name";
	private static final String KEY_PICTURE_URL = "pictureURL";
	private static final String KEY_NUMBER = "number";
	private static final String KEY_RESPONSES = "responses";
	private static final String KEY_VALUE = "value";
	private static final String KEY_PLAYERS = "players";
	private static final String KEY_READER = "reader"; // deprecated
	private static final String KEY_GUESSER = "guesser";
	private static final String KEY_CUE = "cue";
	private static final String KEY_RESPONSE = "response";
	private static final String KEY_GUESS_RESPONSE_ID = "guessResponseId";
	private static final String KEY_GUESS_PLAYER_NUMBER = "guessPlayerNumber";

	// Commands to send to server
	private static final String KEY_JOIN = "join";
	private static final String KEY_LEAVE = "leave";
	private static final String KEY_SUBMIT_RESPONSE = "submitResponse";
	private static final String KEY_SUBMIT_GUESS = "submitGuess";
	private static final String KEY_NEXT_ROUND = "nextRound";
	private static final String KEY_READER_IS_DONE = "readerIsDone";
	private static final String KEY_UPDATE_SETTINGS = "updateSettings";
	private static final String KEY_INITIALIZE_ORDER = "initializeOrder";
	private static final String KEY_JOIN_ORDER = "order";
	private static final String KEY_CANCEL_ORDER = "cancelOrder";

	// Events to receive from server
	private static final String KEY_USER_QUEUED = "didQueue";
	private static final String KEY_USER_JOINED = "didJoin";
	private static final String KEY_YOU_ARE_READER = "reader";
	private static final String KEY_RECEIVE_RESPONSES = "receiveResponses";
	private static final String KEY_RESPONSE_RECEIVED = "responseReceived"; 
	private static final String KEY_YOU_ARE_GUESSER = "guesser";
	private static final String KEY_GUESS_RESPONSE = "guessResponse";
	private static final String KEY_GAMESYNC = "gameSync";
	private static final String KEY_ROUND_STARTED = "roundStarted";
	private static final String KEY_ROUND_OVER = "roundOver";
	private static final String KEY_ERROR = "error";
	private static final String KEY_ORDER_INITIALIZED = "orderInitialized";
	private static final String KEY_ORDER_CANCELED = "orderCanceled";
	private static final String KEY_ORDER_COMPLETE = "orderComplete";

	// Error codes
	protected static final int ERROR_RECEIVED_INVALID_MESSAGE_TYPE = 0;
	protected static final int ERROR_SENT_BLANK_NAME = 1;
	protected static final int ERROR_TOO_MANY_RESPONSES = 2;
	protected static final int ERROR_CANT_GUESS_YET = 3;
	protected static final int ERROR_NOT_ENOUGH_PLAYERS_TO_START_ROUND = 4;
	protected static final int ERROR_ROUND_IN_PROGRESS = 5;
	protected static final int ERROR_GUESSED_THE_READER = 6;
	protected static final int ERROR_GUESSED_SELF = 7;
	protected static final int ERROR_INVALID_MESSAGE_TYPE = 8;
	protected static final int ERROR_ORDERING_WRONG_PHASE = 9;
	protected static final int ERROR_ORDERING_NOT_HAPPENING = 10;
	protected static final int ERROR_NOT_ENOUGH_PLAYERS_TO_ORDER = 11;

	/**
	 * Constructs a new GameMessageStream with GAME_NAMESPACE as the namespace used by 
	 * the superclass.
	 */
	protected GameMessageStream() {
		super(GAME_NAMESPACE);
	}

	public final void joinGame(String name){
		try {
			Log.d(TAG, "join: " + name);
			JSONObject payload = new JSONObject();
			payload.put(KEY_TYPE, KEY_JOIN);
			payload.put(KEY_NAME, name);
			sendMessage(payload);
		}
		catch (JSONException e) {
			Log.e(TAG, "Cannot create object to join a game", e);
		}
		catch (IOException e) {
			Log.e(TAG, "Unable to send a join message", e);
		}
		catch (IllegalStateException e) {
			Log.e(TAG, "Message Stream is not attached", e);
		}
	}

	public final void leaveGame(){
		try {
			Log.d(TAG, "leaving");
			JSONObject payload = new JSONObject();
			payload.put(KEY_TYPE, KEY_LEAVE);
			sendMessage(payload);
		}
		catch (JSONException e) {
			Log.e(TAG, "Cannot create object to leave a game", e);
		}
		catch (IOException e) {
			Log.e(TAG, "Unable to send a leave message", e);
		}
		catch (IllegalStateException e) {
			Log.e(TAG, "Message Stream is not attached", e);
		}
	}

	public final void updateSettings(String name){
		try {
			Log.d(TAG, "updateSettings: " + name);
			JSONObject payload = new JSONObject();
			payload.put(KEY_TYPE, KEY_UPDATE_SETTINGS);
			payload.put(KEY_NAME, name);
			sendMessage(payload);
		}
		catch (JSONException e) {
			Log.e(TAG, "Cannot create object to update settings", e);
		}
		catch (IOException e) {
			Log.e(TAG, "Unable to send a(n) " + KEY_UPDATE_SETTINGS + " message", e);
		}
		catch (IllegalStateException e) {
			Log.e(TAG, "Message Stream is not attached", e);
		}
	}

	public final void startNextRound(){
		Log.d(TAG, "trying to start next round");
		try{
			JSONObject payload = new JSONObject();
			payload.put(KEY_TYPE, KEY_NEXT_ROUND);
			sendMessage(payload);
		}
		catch (JSONException e) {
			Log.e(TAG, "Cannot create object to start next round", e);
		}
		catch (IOException e) {
			Log.e(TAG, "Unable to send a(n) " + KEY_NEXT_ROUND + " message", e);
		}
		catch (IllegalStateException e) {
			Log.e(TAG, "Message Stream is not attached", e);
		}
	}

	protected abstract void onPlayerQueued();
	protected abstract void onPlayerJoined(int newID);
	protected abstract void onGameSync(JSONObject player, int newReader, int newGuesser);
	protected abstract void onReceiveResponses(JSONObject responses);
	protected abstract void onResponseReceived();
	protected abstract void onGuesser();
	protected abstract void onGuessResponse(boolean response);
	protected abstract void onRoundStarted(String newPrompt);
	protected abstract void onRoundEnded();
	protected abstract void onServerError(int errorCode);
	protected abstract void onOrderInitialized();
	protected abstract void onOrderCanceled();
	protected abstract void onOrderComplete();

	/**
	 * Processes all JSON messages received from the receiver device and performs the appropriate 
	 * action for the message.
	 */
	@Override
	public void onMessageReceived(JSONObject message) {
		try {
			Log.d(TAG, "onMessageReceived: " + message);
			if (message.has(KEY_TYPE)) {
				String event = message.getString(KEY_TYPE);

				// if we're getting confirmation that we're queued
				if (KEY_USER_QUEUED.equals(event)) {
					Log.d(TAG, "Confirmed enqueued");
					onPlayerQueued();
				}

				// if we're getting confirmation that we've joined
				else if (KEY_USER_JOINED.equals(event)) {
					Log.d(TAG, "Confirmed joined");
					try {
						int newID = message.getInt(KEY_NUMBER);
						onPlayerJoined(newID);
					}
					catch (JSONException e) {
						e.printStackTrace();
					}
				}

				// if we're now the reader (deprecated, warn)
				else if (KEY_YOU_ARE_READER.equals(event)){
					Log.w(TAG, "Received reader (deprecated)");
					return;
				}

				// upon receiving all responses
				else if (KEY_RECEIVE_RESPONSES.equals(event)) {
					Log.d(TAG, "Received responses");
					try {
						JSONObject responses = message.getJSONObject(KEY_RESPONSES);
						onReceiveResponses(responses);
					}
					catch (JSONException e) {
						e.printStackTrace();
					}
				}

				// submitted response has been received
				else if (KEY_RESPONSE_RECEIVED.equals(event)) {
					Log.d(TAG, "Submitted response was received.");
					onResponseReceived();
				}

				// time to guess
				else if (KEY_YOU_ARE_GUESSER.equals(event)) {
					Log.d(TAG, "Time to guess");
					onGuesser();
				}

				// got a response to our guess
				else if (KEY_GUESS_RESPONSE.equals(event)) {
					Log.d(TAG, "Received guess response");
					try {
						boolean response = message.getBoolean(KEY_VALUE);
						onGuessResponse(response);
					}
					catch (JSONException e) {
						e.printStackTrace();
					}
				}

				// if we're receiving a game state update (gameSync)
				else if (KEY_GAMESYNC.equals(event)) {
					Log.d(TAG, "GameSync");
					try {
						JSONObject thisPlayer = message.getJSONObject(KEY_PLAYERS);
						int newReader = message.getInt(KEY_READER);
						int newGuesser = message.getInt(KEY_GUESSER);
						onGameSync(thisPlayer, newReader, newGuesser);
					}
					catch (JSONException e) {
						e.printStackTrace();
					}
				}

				// if we're receiving a new prompt for a new round
				else if (KEY_ROUND_STARTED.equals(event)) {
					Log.d(TAG, "Round started");
					try {
						String newPrompt = message.getString(KEY_CUE);
						onRoundStarted(newPrompt);
					}
					catch (JSONException e) {
						e.printStackTrace();
					}
				}

				// if we're receiving notice that a round has ended
				else if (KEY_ROUND_OVER.equals(event)) {
					Log.d(TAG, "Round ended");
					onRoundEnded();
				}

				// error received
				else if (KEY_ERROR.equals(event)) {
					Log.d(TAG, "Error received");
					try {
						int responseCode = message.getInt(KEY_VALUE);
						onServerError(responseCode);
					}
					catch (JSONException e) {
						e.printStackTrace();
					}
				}

				// order process started
				else if (KEY_ORDER_INITIALIZED.equals(event)) {
					Log.d(TAG, "Ordering initialized");
					onOrderInitialized();
				}

				// order process canceled
				else if (KEY_ORDER_CANCELED.equals(event)) {
					Log.d(TAG, "Ordering canceled");
					onOrderCanceled();
				}

				// order process complete
				else if (KEY_ORDER_COMPLETE.equals(event)) {
					Log.d(TAG, "Ordering complete");
					onOrderComplete();
				}

				else{
					Log.e(TAG, "Unknown message type: " + message.getString(KEY_TYPE));
					onServerError(ERROR_RECEIVED_INVALID_MESSAGE_TYPE);
				}
			}
			else {
				Log.w(TAG, "Unknown message (no type): " + message);
			}
		}
		catch (JSONException e) {
			Log.w(TAG, "Message doesn't contain an expected key.", e);
		}
	}

}
