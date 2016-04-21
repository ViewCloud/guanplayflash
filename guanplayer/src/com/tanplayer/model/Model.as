package com.tanplayer.model {
	import com.tanplayer.events.GlobalEventDispatcher;
	import com.tanplayer.events.MediaEvent;
	import com.tanplayer.events.PlayerEvent;
	import com.tanplayer.events.PlayerStateEvent;
	import com.tanplayer.media.AdHttpVideoMediaProvider;
	import com.tanplayer.media.AdRtmpMediaProvider;
	import com.tanplayer.media.AppleHttpMediaProvider;
	import com.tanplayer.media.HTTPFenDuanMediaProvider;
	import com.tanplayer.media.HTTPMediaProvider;
	import com.tanplayer.media.ImageMediaProvider;
	import com.tanplayer.media.M3u8MediaProvider;
	import com.tanplayer.media.MediaProvider;
	import com.tanplayer.media.RTMPMediaProvider;
	import com.tanplayer.media.SoundMediaProvider;
	import com.tanplayer.media.VideoMediaProvider;
	import com.tanplayer.media.YouTubeMediaProvider;
	import com.tanplayer.player.PlayerState;
	import com.tanplayer.utils.RootReference;
	
	import flash.events.Event;

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
	 * Fired after the MediaProvider has loaded an item into memory.
	 *
	 * @eventType com.longtailvideo.jwplayer.events.MediaEvent.JWPLAYER_MEDIA_LOADED
	 */
	[Event(name="jwplayerMediaLoaded", type="com.tanplayer.events.MediaEvent")]
	/**
	 * Sent after a load() command has completed
	 * 
	 * @eventType com.longtailvideo.jwplayer.events.MediaEvent.JWPLAYER_MEDIA_TIME
	 */
	[Event(name="jwplayerMediaTime", type="com.tanplayer.events.MediaEvent")]
	/**
	 * Sends the position and duration of the currently playing media
	 * 
	 * @eventType com.longtailvideo.jwplayer.events.MediaEvent.JWPLAYER_MEDIA_VOLUME
	 */
	[Event(name="jwplayerMediaVolume", type="com.tanplayer.events.MediaEvent")]
	/**
	 * Fired when the currently playing media has completed its playback
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
	/**
	 * Fired if an error has occurred in the model.
	 * 
	 * @eventType com.longtailvideo.jwplayer.events.PlayerEvent.JWPLAYER_ERROR
	 */
	[Event(name="jwplayerError", type = "com.tanplayer.events.PlayerEvent")]

	/**
	 * @author Pablo Schklowsky
	 */
	public class Model extends GlobalEventDispatcher 
	{
		protected var _config:PlayerConfig;
		protected var _playlist:IPlaylist;

		protected var _fullscreen:Boolean = false;

	    protected var _currentMedia:MediaProvider;
		
		protected var _adMedia:MediaProvider;

		protected var _mediaSources:Object;
		
		public var _currentPlayURL:String;
		
		public static var _playingTime:Number//当前播放时间
		public static var currentMaxPlayTime:Number=0;//当前最大播放时间
		
		/** Constructor **/
		public function Model() 
		{
			_playlist = new Playlist();
			_playlist.addGlobalListener(forwardEvents);
			_config = new PlayerConfig();
			_mediaSources = {};
			//TODO: Set initial mute state based on user configuration
		}

		/** The player config object **/
		public function get config():PlayerConfig 
		{
			return _config;
		}

		public function set config(conf:PlayerConfig):void 
		{
			_config = conf;
		}

		/** The currently loaded MediaProvider **/
		public function get media():MediaProvider 
		{
			return _currentMedia;
		}
		
		public function get adMedia():MediaProvider
		{
			return _adMedia;
		}

		/**
		 * The current player state
		 */
		public function get state():String 
		{
			//trace("get state(1)");
			return _currentMedia ? _currentMedia.state : PlayerState.IDLE;
		}

		/**
		 * The loaded playlist
		 */
		public function get playlist():IPlaylist {
			return _playlist;
		}

		/** The current fullscreen state of the player **/
		public function get fullscreen():Boolean {
			return _fullscreen;
		}

		public function set fullscreen(b:Boolean):void 
		{
			_fullscreen = b;
			_config.fullscreen = b;
		}

		/** The current mute state of the player **/
		public function get mute():Boolean {
			return _config.mute;
		}

		public function set mute(b:Boolean):void 
		{
			_config.mute = b;
			_currentMedia.mute(b);
		}
        //初始化各种流
		public function setupMediaProviders():void 
		{
//			if(RootReference.flashvarObject['isSection']==false)
//			{
				setMediaProvider('http',new HTTPMediaProvider());
				setMediaProvider('m3u8', new M3u8MediaProvider());
//			}
//			else
//			{
//				//分段注释setMediaProvider('http', new HTTPFenDuanMediaProvider());
//			}
			
			//setMediaProvider('default', new MediaProvider('default'));
			//setMediaProvider('video', new VideoMediaProvider());
			
			setMediaProvider('rtmp', new RTMPMediaProvider());
			//苹果HTTP
			//setMediaProvider('applehttp', new AppleHttpMediaProvider());
			//setMediaProvider('sound', new SoundMediaProvider());
			//setMediaProvider('image', new ImageMediaProvider());
			//setMediaProvider('youtube', new YouTubeMediaProvider());
			//广告视频
			//setMediaProvider('advideo', new AdHttpVideoMediaProvider());

			setActiveMediaProvider('m3u8');
			
			
		}

		/**
		 * Whether the Model has a MediaProvider handler for a given type.
		 */
		public function hasMediaProvider(type:String):Boolean {
			return (_mediaSources[url2type(type)] is MediaProvider);
		}

		/**
		 * Add a MediaProvider to the list of available sources.
		 */
		public function setMediaProvider(type:String, provider:MediaProvider):void 
		{
			if (!hasMediaProvider(type)) 
			{
				_mediaSources[url2type(type)] = provider;
				provider.initializeMediaProvider(config);
			}
		}
        //设置激活哪种类型的流
		public function setActiveMediaProvider(type:String):Boolean 
		{
			if (!hasMediaProvider(type))
				type = "video";

			var newMedia:MediaProvider = _mediaSources[url2type(type)] as MediaProvider;

			if (_currentMedia != newMedia) {
				if (_currentMedia) {
					_currentMedia.stop();
					_currentMedia.removeGlobalListener(forwardEvents);
				}
				newMedia.addGlobalListener(forwardEvents);
				_currentMedia = newMedia;
			}

			return true;
		}
		
		public function setADMediaProvider(type:String):Boolean 
		{
			if (!hasMediaProvider(type))
				type = "advideo";
			
			var newMedia:MediaProvider = _mediaSources[url2type(type)] as MediaProvider;
			
			if (_adMedia != newMedia) {
				if (_adMedia) {
					_adMedia.stop();
					_adMedia.removeGlobalListener(forwardEvents);
				}
				newMedia.addGlobalListener(forwardEvents);
				_adMedia = newMedia;
			}
			
			return true;
		}

		
		protected function forwardEvents(evt:Event):void {
			if (evt is PlayerEvent) {
				if (evt.type == MediaEvent.JWPLAYER_MEDIA_ERROR) {
					// Translate media error into player error.
					dispatchEvent(new PlayerEvent(PlayerEvent.JWPLAYER_ERROR, (evt as MediaEvent).message));
				} 
				dispatchEvent(evt);
			}
		}

		/** e.g. http://providers.longtailvideo.com/5/myProvider.swf --> myprovider **/
		protected function url2type(type:String):String {
			return type.substring(type.lastIndexOf("/") + 1, type.length).replace(".swf", "").toLowerCase();
		}

	}
}