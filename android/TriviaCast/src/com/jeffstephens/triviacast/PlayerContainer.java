package com.jeffstephens.triviacast;

import java.util.ArrayList;

class PlayerNotFoundException extends Exception{
	private static final long serialVersionUID = 7533201933222707417L;
}

class PlayerContainer{
	ArrayList<Player> players;
	
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
}