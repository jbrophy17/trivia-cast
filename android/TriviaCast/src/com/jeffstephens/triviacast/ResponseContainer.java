package com.jeffstephens.triviacast;

import java.util.ArrayList;

class ResponseNotFoundException extends Exception{
	private static final long serialVersionUID = 2429488813786902904L;	
}

public class ResponseContainer{
	public ArrayList<Response> responses;
	
	public ResponseContainer(){
		this.responses = new ArrayList<Response>();
	}

	public void addResponse(Response r){
		responses.add(r);
	}
	
	public void removeResponseById(int id){
		for(int i = 0; i < responses.size(); ++i){
			if(responses.get(i).ID == id){
				responses.remove(i);
				return;
			}
		}
	}

	public void clear(){
		responses.clear();
	}
	
	public int size(){
		return responses.size();
	}

	public Response getResponseById(int id) throws ResponseNotFoundException{
		for(int i = 0; i < responses.size(); ++i){
			if(responses.get(i).ID == id){
				return responses.get(i);
			}
		}

		throw new ResponseNotFoundException();
	}
	
	public ArrayList<String> getStringArrayList(){
		ArrayList<String> result = new ArrayList<String>();
		for(int i = 0; i < responses.size(); ++i){
			result.add(responses.get(i).toString());
		}
		return result;
	}
}