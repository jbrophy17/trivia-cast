package com.jeffstephens.triviacast;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

public class TVCComposer extends Fragment{
	ComposerListener mListener;
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
				final String responseText = getResponse();

				// if an empty response, confirm first
				if(responseText.length() == 0){
					AlertDialog.Builder alert = new AlertDialog.Builder(getView().getContext());

					alert.setTitle("Empty Response!");
					alert.setMessage("Are you sure you want to submit an empty response?");

					alert.setPositiveButton("Yes", new DialogInterface.OnClickListener() {
						public void onClick(DialogInterface dialog, int whichButton) {
							mListener.submitResponseText(responseText);
						}
					});

					alert.setNegativeButton("No",  new DialogInterface.OnClickListener() {
						public void onClick(DialogInterface dialog, int whichButton) {
							; // do nothing
						}
					});
				}
				else{
					mListener.submitResponseText(responseText);
				}
			}
		});

		setPromptText(mListener.getPromptText());
	}

	@Override
	public void onAttach(Activity activity){
		super.onAttach(activity);
		try{
			mListener = (ComposerListener) activity;
		}
		catch(ClassCastException e){
			throw new ClassCastException(activity.toString() + " must implement ComposerListener");
		}
	}

	public interface ComposerListener{
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