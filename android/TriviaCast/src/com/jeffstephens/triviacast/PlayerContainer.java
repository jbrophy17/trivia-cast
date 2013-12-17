package com.jeffstephens.triviacast;

import java.util.ArrayList;

class PlayerNotFoundException extends Exception{
	private static final long serialVersionUID = 7533201933222707417L;
}

public class PlayerContainer{
	private ArrayList<Player> players;
	
	public PlayerContainer(){
		this.players = new ArrayList<Player>();
	}
	
	public void addPlayer(Player p){
		players.add(p);
	}
	
	public Player getPlayerById(int id) throws PlayerNotFoundException{
		for(Player p : players){
			if(p.ID == id){
				return p;
			}
		}
		
		throw new PlayerNotFoundException();
	}
	
	public void clear(){
		players.clear();
	}
	
	public int size(){
		return players.size();
	}
	
	public ArrayList<Player> toArrayList(){
		ArrayList<Player> result = new ArrayList<Player>();
		for(int i = 0; i < players.size(); ++i){
			result.add(players.get(i));
		}
		return result;
	}
	
	public ArrayList<String> getStringArrayList(){
		ArrayList<String> result = new ArrayList<String>();
		for(int i = 0; i < players.size(); ++i){
			result.add(players.get(i).toString());
		}
		return result;
	}
	
	public Player[] toStringArray(){
		return (Player[]) this.getStringArrayList().toArray();
	}
}