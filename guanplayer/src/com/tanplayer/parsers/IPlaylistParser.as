package com.tanplayer.parsers {
	
	public interface IPlaylistParser {
		
		/** Parse a correctly-formatted playlist XML, returning an array of PlaylistItems **/
		function parse(list:XML):Array;
		
	}
	
}