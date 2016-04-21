package com.tanplayer.view {
	import com.tanplayer.player.IPlayer;
	import com.tanplayer.interfaces.IControlbarComponent;
	import com.tanplayer.interfaces.IDisplayComponent;
	import com.tanplayer.interfaces.IDockComponent;
	import com.tanplayer.interfaces.IPlaylistComponent;
	
	
	/**
	 * Interface for JW Flash Media Player visual components
	 *
	 * @author Zachary Ozer
	 */
	public interface IPlayerComponents {
		function get controlbar():IControlbarComponent;
		function get display():IDisplayComponent;
		function get dock():IDockComponent;
		function get playlist():IPlaylistComponent;
		function resize(width:Number, height:Number):void;
	}
}