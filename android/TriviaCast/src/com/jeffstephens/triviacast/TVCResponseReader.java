package com.jeffstephens.triviacast;

import java.util.ArrayList;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentStatePagerAdapter;
import android.support.v4.view.PagerAdapter;
import android.support.v4.view.ViewPager;
import android.support.v4.view.ViewPager.OnPageChangeListener;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

public class TVCResponseReader extends Fragment {

	private int NUM_PAGES = 0;
	private ArrayList<String> responses = new ArrayList<String>();
	private ViewPager mPager;
	private PagerAdapter mPagerAdapter;
	private String prompt;
	private Button doneButton;

	private static final String TAG = TVCResponseReader.class.getSimpleName();


	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		Bundle args = getArguments();
		responses = args.getStringArrayList("responses");
		NUM_PAGES = responses.size();
		prompt = args.getString("prompt");

		Log.d(TAG, "Got " + NUM_PAGES + " responses");

		ViewGroup rootView = (ViewGroup) inflater.inflate(
				R.layout.responsereader, container, false);

		doneButton = (Button) rootView.findViewById(R.id.button_done_reading);

		// Instantiate a ViewPager and PagerAdapter
		mPager = (ViewPager) rootView.findViewById(R.id.pager);
		mPagerAdapter = new ScreenSlidePagerAdapter(getFragmentManager());
		mPager.setAdapter(mPagerAdapter);

		// Set listeners
		mPager.setOnPageChangeListener(new OnPageChangeListener() {
			public void onPageScrollStateChanged(int state) {}
			public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {}

			public void onPageSelected(int position) {
				// if the last one, display button to indicate we're done reading
				if(position == (NUM_PAGES - 1)){
					doneButton.setVisibility(View.VISIBLE);
				}
			}
		});

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
			args.putString("text", responses.get(position));
			ScreenSlidePageFragment frag = new ScreenSlidePageFragment();
			frag.setArguments(args);
			return frag;
		}

		@Override
		public int getCount() {
			return NUM_PAGES;
		}
	}
}