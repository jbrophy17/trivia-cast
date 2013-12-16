package com.jeffstephens.triviacast;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

public class ScreenSlidePageFragment extends Fragment {
	private String thisText;

	private static final String TAG = ScreenSlidePageFragment.class.getSimpleName();

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		Bundle argBundle = getArguments();
		thisText = argBundle.getString("text");

		Log.d(TAG, "thisText = " + thisText);

		ViewGroup rootView = (ViewGroup) inflater.inflate(
				R.layout.fragment_screen_slide_page, container, false);

		TextView thisTV = (TextView) rootView.findViewById(R.id.screen_slide_response);
		thisTV.setText(thisText);

		return rootView;
	}
}