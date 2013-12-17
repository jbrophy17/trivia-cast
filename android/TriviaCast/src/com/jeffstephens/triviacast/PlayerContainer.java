package com.jeffstephens.triviacast;

import java.util.ArrayList;

class PlayerNotFoundException extends Exception{
	private static final long serialVersionUID = 7533201933222707417L;
}

public class PlayerContainer{
	public ArrayList<Player> players;

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

	public ArrayList<Player> toArrayList(int filterID){
		ArrayList<Player> result = new ArrayList<Player>();
		for(int i = 0; i < players.size(); ++i){
			if(!players.get(i).isOut && players.get(i).ID != filterID){
				result.add(players.get(i));
			}
		}
		return result;
	}

	public ArrayList<String> getStringArrayList(int filterID){
		ArrayList<String> result = new ArrayList<String>();
		for(int i = 0; i < players.size(); ++i){
			if(!players.get(i).isOut && players.get(i).ID != filterID){
				result.add(players.get(i).toString());
			}
		}
		return result;
	}

	public Player[] toStringArray(int filterID){
		return (Player[]) this.getStringArrayList(filterID).toArray();
	}
}