package com.jeffstephens.triviacast;

import android.app.Activity;
import android.app.Fragment;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

public class TVCComposer extends Fragment{
	OnUIReadyListener mListener;
	Button submitResponseButton;
	
	@Override
	public void onCreate(Bundle savedInstanceState){
		super.onCreate(savedInstanceState);
	}
	
	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState){
		return inflater.inflate(R.layout.composer, container, false);
	}
	
	@Override
	public void onPause(){
		super.onPause();
	}
	
	@Override
	public void onStart(){
		super.onStart();

		// instantiate UI
		submitResponseButton = (Button) getView().findViewById(R.id.button_submit_response);
				
		// set listeners
		submitResponseButton.setOnClickListener(new Button.OnClickListener(){
			public void onClick(View v){
				mListener.submitResponseText(getResponse());
			}
		});
		
		setPromptText(mListener.getPromptText());
	}
	
	@Override
	public void onAttach(Activity activity){
		super.onAttach(activity);
		try{
			mListener = (OnUIReadyListener) activity;
		}
		catch(ClassCastException e){
			throw new ClassCastException(activity.toString() + " must implement OnUIReadyListener");
		}
	}
	
	public interface OnUIReadyListener{
		// Container Activity must implement this
		public String getPromptText();
		public void submitResponseText(String response);
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