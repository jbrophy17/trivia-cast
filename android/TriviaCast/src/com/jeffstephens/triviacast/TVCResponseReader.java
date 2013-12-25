package com.jeffstephens.triviacast;

import java.util.ArrayList;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.os.Vibrator;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentStatePagerAdapter;
import android.support.v4.view.PagerAdapter;
import android.support.v4.view.ViewPager;
import android.support.v4.view.ViewPager.OnPageChangeListener;
import android.text.Html;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

public class TVCResponseReader extends Fragment {

	private int NUM_PAGES = 0;
	private ResponseContainer responses = new ResponseContainer();
	private Response[] responseArray;
	private PlayerContainer players = new PlayerContainer();
	private String[] playerNames;
	private int[] playerIDs;
	private int myPlayerID;
	private ViewPager mPager;
	private PagerAdapter mPagerAdapter;
	private String prompt;
	private Button guessButton;
	private ReaderListener mListener;
	private boolean guessingMode;
	private int selectedPrompt;

	private static final String TAG = TVCResponseReader.class.getSimpleName();

	public interface ReaderListener{
		// Container Activity must implement this
		public void readerIsDone();
		public PlayerContainer getPlayers();
		public ResponseContainer getResponseContainer();
		public void submitGuess(int responseID, int playerID);
	}

	@Override
	public void onAttach(Activity activity){
		super.onAttach(activity);
		try{
			mListener = (ReaderListener) activity;
		}
		catch(ClassCastException e){
			throw new ClassCastException(activity.toString() + " must implement ReaderListener");
		}
	}

	public void initReadingMode(){
		Log.d(TAG, "init reading mode");
	}
	
	public void updateResponses(ResponseContainer newResponses){
		responses = newResponses;
	}

	public void initGuessingMode(){
		Log.d(TAG, "init guessing mode");

		guessingMode = true;
		players = mListener.getPlayers();
		guessButton.setVisibility(View.VISIBLE);

		guessButton.setOnClickListener(new Button.OnClickListener(){
			public void onClick(View v){
				// build string array for display with same indices as playerList
				ArrayList<String> tempPlayerNames = new ArrayList<String>();
				ArrayList<Integer> tempPlayerIDs = new ArrayList<Integer>();
				for(int i = 0; i < players.size(); ++i){
					if(!players.players.get(i).isOut && players.players.get(i).ID != myPlayerID){
						tempPlayerNames.add(players.players.get(i).toString());
						tempPlayerIDs.add(players.players.get(i).ID);
					}
					else{
						Log.d(TAG, "Excluding " + players.players.get(i).toString());
					}
				}

				playerNames = new String[tempPlayerNames.size()];
				playerIDs = new int[tempPlayerIDs.size()];
				for(int i = 0; i < tempPlayerIDs.size(); ++i){
					playerNames[i] = tempPlayerNames.get(i).toString();
					playerIDs[i] = tempPlayerIDs.get(i).intValue();
				}

				// build dialog
				AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
				builder.setTitle(R.string.title_who_said_it);
				builder.setItems(playerNames, new DialogInterface.OnClickListener() {
					public void onClick(DialogInterface dialog, int which) {
						confirmChoice(which);
					}
				});
				builder.create();
				builder.show();
			}
		});
	}

	private void confirmChoice(final int playerIndex){
		String confirmText = "You're guessing that <b>" + playerNames[playerIndex] + "</b> submitted ";
		confirmText += "<b>" + responseArray[selectedPrompt].toString() + "</b>";

		String lastCharacter = confirmText.substring(confirmText.length());
		if(lastCharacter != "." && lastCharacter != "!" && lastCharacter != "?"){
			confirmText += ".";
		}

		AlertDialog.Builder alert = new AlertDialog.Builder(getActivity());

		alert.setTitle("Confirm Guess");
		alert.setMessage(Html.fromHtml(confirmText));

		alert.setPositiveButton("Submit Guess", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int whichButton) {
				// submit guess
				mListener.submitGuess(responseArray[selectedPrompt].ID, playerIDs[playerIndex]);
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

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		Bundle args = getArguments();
		responses = mListener.getResponseContainer();

		// populate array
		responseArray = new Response[responses.size()];
		for(int i = 0; i < responses.responses.size(); ++i){
			responseArray[i] = responses.responses.get(i);
		}

		NUM_PAGES = responses.size();
		prompt = args.getString("prompt");
		guessingMode = args.getBoolean("guessingMode");
		myPlayerID = args.getInt("playerID");

		Log.d(TAG, "Got " + NUM_PAGES + " responses");

		ViewGroup rootView = (ViewGroup) inflater.inflate(
				R.layout.responsereader, container, false);

		guessButton = (Button) rootView.findViewById(R.id.button_start_guess);

		// Instantiate a ViewPager and PagerAdapter
		mPager = (ViewPager) rootView.findViewById(R.id.pager);
		mPagerAdapter = new ScreenSlidePagerAdapter(getFragmentManager());
		mPager.setAdapter(mPagerAdapter);

		// Set listeners		
		mPager.setOnPageChangeListener(new OnPageChangeListener() {
			public void onPageScrollStateChanged(int state) {}
			public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {}

			public void onPageSelected(int position) {
				if(!guessingMode){
					// if the last one, tell the server we're done reading
					if(position == (NUM_PAGES - 1)){
						mListener.readerIsDone();
					}
				}
				else{
					selectedPrompt = position;
				}
			}
		});

		if(guessingMode){
			initGuessingMode();
		}
		else{
			initReadingMode();
		}

		// Set prompt text
		TextView tv = (TextView) rootView.findViewById(R.id.reader_prompt_display);
		tv.setText(prompt);

		return rootView;
	}

	/**
	 * A simple pager adapter that represents ScreenSlidePageFragment objects, in
	 * sequence.
	 */
	private class ScreenSlidePagerAdapter extends FragmentStatePagerAdapter {
		public ScreenSlidePagerAdapter(FragmentManager fm) {
			super(fm);
		}

		@Override
		public Fragment getItem(int position) {
			if(position > responses.size() || position < 0){
				Log.e(TAG, "ScreenSlidePagerAdapter requested out of bounds item");
			}

			Bundle args = new Bundle();
			ScreenSlidePageFragment frag = new ScreenSlidePageFragment();
			frag.setArguments(args);

			args.putString("text", responseArray[position].toString());

			return frag;
		}

		@Override
		public int getCount() {
			return NUM_PAGES;
		}
	}
}