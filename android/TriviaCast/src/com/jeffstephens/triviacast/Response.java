package com.jeffstephens.triviacast;

public class Response{
	public int ID;
	public String responseText;
	
	public Response(int ID, String responseText){
		this.ID = ID;
		this.responseText = responseText;
	}
	
	public String toString(){
		return this.responseText;
	}
}