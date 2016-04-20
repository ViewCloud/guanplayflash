package away3d.materials.utils
{
	import flash.display.Sprite;
	import flash.media.SoundTransform;
	
	public interface IVideoPlayer
	{
		
		
		
		/**
		 * Indicates whether the player should loop when video finishes
		 */
		function get loop():Boolean;
		
		function set loop(val:Boolean):void;
		
		
		
		
		
		/**
		 * Get/Set access to the with of the video object
		 */
		
		
		/**
		 * Get/Set access to the height of the video object
		 */
		
		
		/**
		 * Provides access to the Video Object
		 */
		function get container():Sprite;
		
		/**
		 * Indicates whether the video is playing
		 */
		function get playing():Boolean;
		
		/**
		 * Indicates whether the video is paused
		 */
		function get paused():Boolean;
		
		/**
		 * Returns the actual time of the netStream
		 */
		
		
		/**
		 * Start playing (or resume if paused) the video.
		 */
		function play():void;
		
		/**
		 * Temporarily pause playback. Resume using play().
		 */
		function pause():void;
		
		/**
		 *  Seeks to a given time in the video, specified in seconds, with a precision of three decimal places (milliseconds).
		 */
		function seek(val:Number):void;
		
		/**
		 * Stop playback and reset playhead.
		 */
		function stop():void;
		
		/**
		 * Called if the player is no longer needed
		 */
		function dispose():void;
	
	}
}
