package away3d.materials.utils
{
	import flash.display.Sprite;
	import flash.events.AsyncErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	public class VideoInfo implements IVideoPlayer
	{
		
		
		private var _loop:Boolean;
		private var _playing:Boolean;
		private var _paused:Boolean;
		
		private var _container:*;
		
		public function VideoInfo()
		{
			_loop = false;
			_playing = false;
			_paused = false;
			
		}
	
		
	
		//////////////////////////////////////////////////////
		// public methods
		//////////////////////////////////////////////////////
		
		public function play():void
		{
			if (_paused) 
			{
				
				_paused = false;
				_playing = true;
			} 
			else if (!_playing) 
			{
				
				_playing = true;
				_paused = false;
			}
		}
		
		public function pause():void
		{
			if (!_paused)
			{
				
				_paused = true;
			}
		}
		
		public function seek(val:Number):void
		{
			pause();
			
		}
		
		public function stop():void
		{
		
			_playing = false;
			_paused = false;
		}
		
		public function dispose():void
		{
			
			
			_playing = false;
			_paused = false;
		
		}
		
		//////////////////////////////////////////////////////
		// event handlers
		//////////////////////////////////////////////////////
		
		private function asyncErrorHandler(event:AsyncErrorEvent):void
		{
			// Must be present to prevent errors, but won't do anything
		}
		
		private function metaDataHandler(oData:Object = null):void
		{
			// Offers info such as oData.duration, oData.width, oData.height, oData.framerate and more (if encoded into the FLV)
			//this.dispatchEvent( new VideoEvent(VideoEvent.METADATA,_netStream,file,oData) );
		}
		
		private function ioErrorHandler(e:IOErrorEvent):void
		{
			trace("An IOerror occured: " + e.text);
		}
		
		private function securityErrorHandler(e:SecurityErrorEvent):void
		{
			trace("A security error occured: " + e.text + " Remember that the FLV must be in the same security sandbox as your SWF.");
		}
		
		private function onBWDone():void
		{
			// Must be present to prevent errors for RTMP, but won't do anything
		}
		
		private function streamClose():void
		{
			trace("The stream was closed. Incorrect URL?");
		}
		
		
		
		
		public function get loop():Boolean
		{
			return _loop;
		}
		
		public function set loop(val:Boolean):void
		{
			_loop = val;
		}
		
		
		
		
		
	
		
		
		
		
		
		
		
		//////////////////////////////////////////////////////
		// read-only vars
		//////////////////////////////////////////////////////
		
		public function get container():Sprite
		{
			return _container;
		}
		
		public function set container(val:*):void
		{
			_container=val;
		}
		
		
		
		public function get playing():Boolean
		{
			return _playing;
		}
		
		public function get paused():Boolean
		{
			return _paused;
		}
	
	}
}
