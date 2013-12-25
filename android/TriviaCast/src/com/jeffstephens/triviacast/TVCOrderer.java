package com.jeffstephens.triviacast;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.os.Vibrator;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

public class TVCOrderer extends Fragment{
	OrdererListener mListener;
	Button joinOrderButton;

	@Override
	public void onCreate(Bundle savedInstanceState){
		super.onCreate(savedInstanceState);
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState){
		return inflater.inflate(R.layout.orderer, container, false);
	}

	@Override
	public void onPause(){
		super.onPause();
	}

	@Override
	public void onStart(){
		super.onStart();

		// instantiate UI
		joinOrderButton = (Button) getView().findViewById(R.id.button_submit_response);

		// set listeners
		joinOrderButton.setOnClickListener(new Button.OnClickListener(){
			public void onClick(View v){
				mListener.joinOrder();
			}
		});
	}

	@Override
	public void onAttach(Activity activity){
		super.onAttach(activity);
		try{
			mListener = (OrdererListener) activity;
		}
		catch(ClassCastException e){
			throw new ClassCastException(activity.toString() + " must implement OrdererListener");
		}
	}

	public interface OrdererListener{
		// Container Activity must implement this
		public void joinOrder();
	}

	public void setPromptText(String newPrompt){
		TextView prompt = (TextView) getView().findViewById(R.id.prompt_display);
		prompt.setText(newPrompt);
	}

	public String getResponse(){
		EditText response = (EditText) getView().findViewById(R.id.response);
		return response.getText().toString();
	}
}