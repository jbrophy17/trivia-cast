package com.jeffstephens.triviacast;

public class Player{
	public int ID;
	public int score;
	public String name;
	public String pictureURL;
	public boolean isOut;
	
	public Player(int ID, int score, String name, String pictureURL, boolean isOut){
		this.ID = ID;
		this.score = score;
		this.name = name;
		this.pictureURL = pictureURL;
		this.isOut = isOut;
		
		if(pictureURL.length() == 0){
			this.pictureURL = null;
		}
	}
	
	public Player(int ID, String name){
		this.ID = ID;
		this.name = name;
		
		this.score = 0;
		this.pictureURL = null;
		this.isOut = false;
	}
	
	public String toString(){
		return this.name;
	}
}