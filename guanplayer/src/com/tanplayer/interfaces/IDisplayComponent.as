package com.tanplayer.interfaces {
	import com.tanplayer.events.IGlobalEventDispatcher;
	
	import flash.display.DisplayObject;
	

	/**
	 * Sent when the user interface requests that the player play the currently loaded media
	 *
	 * @eventType com.longtailvideo.jwplayer.events.ViewEvent.JWPLAYER_VIEW_PLAY
	 */
	[Event(name="jwPlayerViewPlay", type = "com.tanplayer.events.ViewEvent")]
	
	/**
	 * Sent when the user interface requests that the player pause the currently playing media
	 *
	 * @eventType com.longtailvideo.jwplayer.events.ViewEvent.JWPLAYER_VIEW_PAUSE
	 */
	[Event(name="jwPlayerViewPause", type = "com.tanplayer.events.ViewEvent")]

	/**
	 * Sent when the user clicks on the display
	 *
	 * @eventType com.longtailvideo.jwplayer.events.ViewEvent.JWPLAYER_VIEW_CLICK
	 */
	[Event(name="jwPlayerViewClick", type = "com.tanplayer.events.ViewEvent")]

	public interface IDisplayComponent extends IPlayerComponent {
		function setIcon(displayIcon:DisplayObject):void;
		function setText(displayText:String,displayIcon:DisplayObject=null):void;
	}
}