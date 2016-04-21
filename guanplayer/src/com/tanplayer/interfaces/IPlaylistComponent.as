package com.tanplayer.interfaces {
	import com.tanplayer.events.IGlobalEventDispatcher;
	

	/**
	 * Sent when the user requests the player skip to the given playlist index
	 *
	 * @eventType com.longtailvideo.jwplayer.events.ViewEvent.JWPLAYER_VIEW_ITEM
	 */
	[Event(name="jwPlayerViewItem", type = "com.tanplayer.events.ViewEvent")]

	public interface IPlaylistComponent extends IPlayerComponent {
		function show():void;
		function hide():void;
	}
}