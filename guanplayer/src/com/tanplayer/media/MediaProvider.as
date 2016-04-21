package com.tanplayer.media
{
	import com.hurlant.crypto.symmetric.NullPad;
	import com.tanplayer.events.GlobalEventDispatcher;
	import com.tanplayer.events.IGlobalEventDispatcher;
	import com.tanplayer.events.MediaEvent;
	import com.tanplayer.events.PlayerStateEvent;
	import com.tanplayer.model.PlayerConfig;
	import com.tanplayer.model.PlaylistItem;
	import com.tanplayer.player.PlayerState;
	import com.tanplayer.utils.RootReference;
	import com.tanplayer.utils.Stretcher;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Video;
	
	
	/**
	 * Fired when a portion of the current media has been loaded into the buffer.
	 *
	 * @eventType com.longtailvideo.jwplayer.events.MediaEvent.JWPLAYER_MEDIA_BUFFER
	 */
	[Event(name="jwplayerMediaBuffer", type="com.tanplayer.events.MediaEvent")]
	/**
	 * Fired when the buffer is full.
	 *
	 * @eventType com.longtailvideo.jwplayer.events.MediaEvent.JWPLAYER_MEDIA_BUFFER_FULL
	 */
	[Event(name="jwplayerMediaBufferFull", type="com.tanplayer.events.MediaEvent")]
	/**
	 * Fired if an error occurs in the course of media playback.
	 *
	 * @eventType com.longtailvideo.jwplayer.events.MediaEvent.JWPLAYER_MEDIA_ERROR
	 */
	[Event(name="jwplayerMediaError", type="com.tanplayer.events.MediaEvent")]
	/**
	 * Fired after the MediaProvider has successfully set up a connection to the media.
	 *
	 * @eventType com.longtailvideo.jwplayer.events.MediaEvent.JWPLAYER_MEDIA_LOADED
	 */
	[Event(name="jwplayerMediaLoaded", type="com.tanplayer.events.MediaEvent")]
	/**
	 * Sends the position and duration of the currently playing media.
	 * 
	 * @eventType com.longtailvideo.jwplayer.events.MediaEvent.JWPLAYER_MEDIA_TIME
	 */
	[Event(name="jwplayerMediaTime", type="com.tanplayer.events.MediaEvent")]
	/**
	 * Fired after a volume change.
	 * 
	 * @eventType com.longtailvideo.jwplayer.events.MediaEvent.JWPLAYER_MEDIA_VOLUME
	 */
	[Event(name="jwplayerMediaVolume", type="com.tanplayer.events.MediaEvent")]
	/**
	 * Fired when the currently playing media has completed its playback.
	 * 
	 * @eventType com.longtailvideo.jwplayer.events.MediaEvent.JWPLAYER_MEDIA_COMPLETE
	 */
	[Event(name="jwplayerMediaComplete", type="com.tanplayer.events.MediaEvent")]
	/**
	 * Sent when the playback state has changed.
	 * 
	 * @eventType com.longtailvideo.jwplayer.events.PlayerStateEvent.JWPLAYER_PLAYER_STATE
	 */
	[Event(name="jwplayerPlayerState", type="com.tanplayer.events.PlayerStateEvent")]
	
	public class MediaProvider extends Sprite implements IGlobalEventDispatcher 
	{
		/** Reference to the player configuration. **/
		private var _config:PlayerConfig;
		/** Name of the MediaProvider **/
		private var _provider:String;
		/** Reference to the currently active playlistitem. **/
		protected var _item:PlaylistItem;
		/** The current position inside the file. **/
		public var _position:Number = 0;
		/** The current volume of the audio output stream **/
		private var _volume:Number;
		/** The playback state for the currently loaded media.  @see com.longtailvideo.jwplayer.model.ModelStates **/
		private var _state:String;
		/** Clip containing graphical representation of the currently playing media **/
		private var _media:MovieClip;
		
		private var _adMedia:MovieClip;
		/** Most recent buffer data **/
		private var _bufferPercent:Number;
		/** Handles event dispatching **/
		private var _dispatcher:GlobalEventDispatcher;
		
		protected var _width:Number;
		protected var _height:Number;
		
		
		
		
		public function MediaProvider(provider:String) 
		{
			_provider = provider;
			_dispatcher = new GlobalEventDispatcher();
		}
		
		
		public function initializeMediaProvider(cfg:PlayerConfig):void 
		{
			_config = cfg;
			_state = PlayerState.IDLE;
		}
		
		
		/**
		 * Load a new playlist item
		 * @param itm The playlistItem to load
		 **/
		public function load(itm:PlaylistItem):void 
		{
			_item = itm;
			dispatchEvent(new MediaEvent(MediaEvent.LOADEDJWPLAYER_MEDIA));
		}
		
		
		/** Resume playback of the item. **/
		public function play():void 
		{
			if (_media) 
			{
				_media.visible = true;
			}
			
			setState(PlayerState.PLAYING);
		}
		
		
		/** Pause playback of the item. **/
		public function pause():void 
		{
			setState(PlayerState.PAUSED);
		}
		
		
		/**
		 * Seek to a certain position in the item.
		 *
		 * @param pos	The position in seconds.
		 **/
		//被重写
		public function seek(pos:Number):void 
		{
			_position = pos;
		}
		
		//视频停止
		/** Stop playing and loading the item. **/
		public function stop():void 
		{
			setState(PlayerState.IDLE);
			_position = 0;
			
			if (_media) 
			{
				_media.visible = false;
			}
		}
		
		
		/**
		 * Change the playback volume of the item.
		 *
		 * @param vol	The new volume (0 to 100).
		 **/
		public function setVolume(vol:Number):void 
		{
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_VOLUME, {'volume': vol});
		}
		
		
		/**
		 * Changes the mute state of the item.
		 *
		 * @param mute	The new mute state.
		 **/
		public function mute(mute:Boolean):void 
		{
			mute == true ? setVolume(0) : setVolume(_config.volume);
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_MUTE, {'mute': mute});
		}
		
		
		/**
		 * Resizes the display.
		 *
		 * @param width		The new width of the display.
		 * @param height	The new height of the display.
		 **/
		//视频缩放
		public function resize(width:Number, height:Number):void 
		{
			trace("widthwidthwidth:::"+width);
			_width = width;
			_height = height;
			
			if (_media) 
			{
				Stretcher.stretch(_media, width, height, _config.stretching);
			}
		}
		
		//视频裁剪自适应居中 缩放 设置视频宽高
		public function VideoResize(width:Number, height:Number,type:String=""):void 
		{
			_width = width;
			_height = height;
			
			
			
			if(type=="video")
			{
				if (_media) 
				{
					
					
					//[object MovieClip] 640 447.95 uniformtrace(_media,width, height, _config.stretching)
					Stretcher.stretch(_media,width, height, _config.stretching);
				}
			}
			else
			{
				if (_adMedia) 
				{
					//trace(_media,width, height, _config.stretching)
					Stretcher.stretch(_adMedia,width,height, _config.stretching);
				}
			}
			
		}
		
		public function  AdVideoResize(wid:Number, hei:Number):void
		{
			_width = width;
			_height = height;
			//trace(_adMedia);
			Stretcher.stretch(_adMedia,wid,hei, _config.stretching);
		}
		
		
		/** Graphical representation of media **/
		public function get display():DisplayObject 
		{
			return _media;
		}
		
		public function get adDisplay():DisplayObject
		{
			return _adMedia;
		}
		
		
		/** Name of the MediaProvider. */
		public function get provider():String {
			return _provider;
		}
		
		
		/**
		 * Current state of the MediaProvider.
		 * @see PlayerStates
		 */
		public function get state():String 
		{
			//trace("get state(2)"+_state);
			return _state;
		}
		
		
		/** Currently playing PlaylistItem **/
		public function get item():PlaylistItem {
			return _item;
		}
		
		
		/** Current position, in seconds **/
		//播放时间
		public function get position():Number {
			return _position;
		}
		
		
		/**
		 * The current volume of the playing media
		 * <p>Range: 0-100</p>
		 */
		public function get volume():Number {
			return _volume;
		}
		
		
		/** Puts the video into a buffer state **/
		protected function buffer():void {
			
		}
		
		
		/** Completes video playback **/
		protected function complete():void 
		{
			stop();
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_COMPLETE);
		}
		
		
		/** Dispatches error notifications **/
		protected function error(message:String):void 
		{
			stop();
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_ERROR, {message: message});
		}
		
		
		/**
		 * Sets the current state to a new state and sends a PlayerStateEvent
		 * @param newState A state from ModelStates.
		 */
		protected function setState(newState:String):void 
		{
			trace("newState:::"+newState);
			if (state != newState) 
			{
				var evt:PlayerStateEvent = new PlayerStateEvent(PlayerStateEvent.JWPLAYER_PLAYER_STATE, newState, state);
				_state = newState;
				trace("目前播放状态:::"+newState);
				dispatchEvent(evt);
			}
		}
		
		
		/**
		 * Sends a MediaEvent, simultaneously setting a property
		 * @param type
		 * @param property
		 * @param value
		 */
		protected function sendMediaEvent(type:String,properties:Object=null):void 
		{
			var newEvent:MediaEvent = new MediaEvent(type);
			
			for (var property:String in properties) 
			{
				if (newEvent.hasOwnProperty(property)) 
				{
					//trace("property"+property);
					newEvent[property] = properties[property];
				}
			}
			
			dispatchEvent(newEvent);
		}
		
		
		protected function sendVideoLoadMediaEvent(type:String,properties:Object=null,videoType:String=""):void 
		{
			var newEvent:MediaEvent = new MediaEvent(type);
			newEvent.metadata.videoType = videoType;
			dispatchEvent(newEvent);
		}
		
		
		/** Dispatches buffer change notifications **/
		protected function sendBufferEvent(bufferPercent:Number, offset:Number=0):void {
			if ((_bufferPercent != bufferPercent || bufferPercent == 0) && 0 <= bufferPercent < 100) {
				_bufferPercent = bufferPercent;
				var obj:Object = {
					'bufferPercent':	_bufferPercent, 
					'offset': 			offset, 
					'duration': 		_item.duration,
						'position': 		Math.max(0, _position)
				};
				sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_BUFFER, obj);
			}
		}
		
		
		/**
		 * The current config
		 */
		protected function get config():PlayerConfig {
			return _config;
		}
		
		
		/**
		 * Gets a property from the player configuration
		 *
		 * @param property The property to be retrieved.
		 * **/
		protected function getConfigProperty(property:String):* {
			if (item && item.hasOwnProperty(_provider + "." + property)) {
				return item[_provider + "." + property];
			} else {
				return _config.pluginConfig(provider)[property];
			}
		}
		
		/**
		 * Gets the graphical representation of the media.
		 * 
		 */
		protected function get media():DisplayObject 
		{
			return _media;
		}
		
		
		/**
		 * Sets the graphical representation of the media.
		 * 
		 */
		//视频添加到媒体层
		protected function set media(m:DisplayObject):void 
		{
			if(m) 
			{
				_media = new MovieClip();
				
				_media.addChild(m);
				
				if(_width*_height>0) 
				{
					Stretcher.stretch(_media, _width, _height, _config.stretching);
				}
			} 
			else 
			{
				_media = null;
			}
		}
		protected function get admedia():DisplayObject 
		{
			return _adMedia;
		}
		
		//广告视频添加到媒体层
		protected function set admedia(m:DisplayObject):void 
		{
			if (m) 
			{
				_adMedia = new MovieClip();
				_adMedia.addChild(m);
				if (_width * _height > 0) 
				{
					Stretcher.stretch(_adMedia, _width, _height, _config.stretching);
				}
			} 
			else 
			{
				_adMedia = null;
			}
		}
		
		
		
		
		
		///////////////////////////////////////////		
		/// IGlobalEventDispatcher implementation
		///////////////////////////////////////////		
		/**
		 * @inheritDoc
		 */
		public function addGlobalListener(listener:Function):void {
			_dispatcher.addGlobalListener(listener);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function removeGlobalListener(listener:Function):void {
			_dispatcher.removeGlobalListener(listener);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public override function dispatchEvent(event:Event):Boolean {
			_dispatcher.dispatchEvent(event);
			return super.dispatchEvent(event);
		}
	}
}