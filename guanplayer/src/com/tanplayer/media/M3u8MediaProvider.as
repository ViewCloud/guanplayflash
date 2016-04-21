package com.tanplayer.media
{
	import com.tanplayer.components.DisplayComponent;
	import com.tanplayer.events.MediaEvent;
	import com.tanplayer.events.PlayerEvent;
	import com.tanplayer.model.Model;
	import com.tanplayer.model.PlayerConfig;
	import com.tanplayer.model.PlaylistItem;
	import com.tanplayer.model.PlaylistItemLevel;
	import com.tanplayer.player.JavascriptAPI;
	import com.tanplayer.player.Player;
	import com.tanplayer.player.PlayerState;
	import com.tanplayer.utils.AssetLoader;
	import com.tanplayer.utils.Configger;
	import com.tanplayer.utils.Logger;
	import com.tanplayer.utils.NetClient;
	import com.tanplayer.utils.RootReference;
	import com.tanplayer.utils.TEA;
	
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.*;
	import flash.events.ErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.media.*;
	import flash.net.*;
	import flash.net.NetStream;
	import flash.utils.*;
	
	import org.denivip.osmf.plugins.HLSPluginInfo;
	import org.osmf.containers.MediaContainer;
	import org.osmf.events.AlternativeAudioEvent;
	import org.osmf.events.HTTPStreamingEvent;
	import org.osmf.events.LoadEvent;
	import org.osmf.events.MediaErrorEvent;
	import org.osmf.events.MediaFactoryEvent;
	import org.osmf.events.MediaPlayerCapabilityChangeEvent;
	import org.osmf.events.MediaPlayerStateChangeEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.layout.HorizontalAlign;
	import org.osmf.layout.LayoutMetadata;
	import org.osmf.layout.LayoutMode;
	import org.osmf.layout.ScaleMode;
	import org.osmf.layout.VerticalAlign;
	import org.osmf.logging.Log;
	import org.osmf.media.DefaultMediaFactory;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaFactory;
	import org.osmf.media.MediaPlayer;
	import org.osmf.media.MediaPlayerState;
	import org.osmf.media.MediaResourceBase;
	import org.osmf.media.PluginInfoResource;
	import org.osmf.media.URLResource;
	import org.osmf.net.NetStreamLoadTrait;
	import org.osmf.net.StreamingItem;
	import org.osmf.net.StreamingURLResource;
	import org.osmf.traits.LoadState;
	import org.osmf.traits.MediaTraitBase;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.utils.OSMFSettings;
	
	
	public class M3u8MediaProvider extends MediaProvider
	{
		/**
		 * @private
		 **/
		private var player:MediaPlayer = null;
		private var factory:MediaFactory = null;
		private var container:MediaContainer = null;
		private var stream:NetStream = null;
		
		private var alternativeLanguage:int = -1;
		private var dynamicStream:int = -1;
		
		private var seekedToLive:Boolean = false;
		
		private var latestSeekTarget:Number;
		
		
		
		
		
		
		private function onPluginLoaded(event:MediaFactoryEvent):void
		{
			trace("Plugin successed to load.");
		}
		
		private function onPluginLoadError(event:MediaFactoryEvent):void
		{
			trace("Plugin failed to load.");
			
		}
		
		private function onPlayPauseClick(event:MouseEvent):void
		{
			if (!player.playing)
			{
				if (player.canPlay)
				{
					player.play();
					sendMediaEvent(MediaEvent.M3U8_PLAY,null);
					setState(PlayerState.PLAYING);
				}
					
			}
			else
			{
				if (player.canPause)
					player.pause();
			}
		}
		
		private static const HIGH_PRIORITY:int = int.MAX_VALUE;
		
		private function onLoadStateChange(e:LoadEvent):void
		{
			trace("OnLoadStateChange - " + e.loadState);
			
			if (e.loadState == LoadState.READY)
			{
//				if(	_autoPlay)
//				{
				onPlayPauseClick(null);
//				}
				
				var nsLoadTrait:NetStreamLoadTrait = player.media.getTrait(MediaTraitType.LOAD) as NetStreamLoadTrait;
				stream = nsLoadTrait.netStream;
				trace("* add download error listener");
				//stream.addEventListener(HTTPStreamingEvent.DOWNLOAD_ERROR, onDownloadError);
				stream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus, false, HIGH_PRIORITY, true);
				//stream.addEventListener(IOErrorEvent.IO_ERROR, onError, false, HIGH_PRIORITY, true);
				trace( "NetStream Type: " + flash.utils.getQualifiedClassName( stream ) );
				
				//stream.receiveVideo(false);
			}
		}
		
		
		
		private function onNetStatus(event:NetStatusEvent):void
		{
			var currentTime:Date = new Date();
			trace("NetStatus event:" + event.info.code + "[" + currentTime + "]");
			
			if(event.info.code == "NetStream.Seek.Notify"){
				var timeDiff:Number = Math.abs(player.currentTime - latestSeekTarget);
				if(timeDiff > 0.1)
					player.seek(latestSeekTarget);
			}
			
		}
		
		/**
		 * @private
		 * Clears existing resource.
		 **/			
		private function unloadResource():void
		{
			if (player.canPlay && player.state == MediaPlayerState.PLAYING)
				player.stop();
			
			player.media = null;
		}
		
		/**
		 * @private
		 * Create a resource from the specified url.
		 **/
		private function createResource(url:String):void
		{
			
		}
		
		//获取总时间
		private function onDurationChange(event:TimeEvent):void
		{
			if (player.temporal)
			{
				trace("dsf"+player.duration);
				
				//RootReference._player.playlist.currentItem.duration=player.duration;
				
			}
		}
		
		/**
		 * @private
		 * Track when the player is capable to play in order to enable UI.
		 */
		private function onPlayerCanPlayChange(event:MediaPlayerCapabilityChangeEvent):void
		{
			//updateUI();
		}
		
		/**
		 * @private
		 * Called when the player current time has changed. We update the slider position.
		 **/
		private function onPlayerCurrentTimeChange(event:TimeEvent):void
		{
			//每
			
//			if (event.time >= sldSeek.minimum && event.time <= sldSeek.maximum) 
//			{
//				sldSeek.value = event.time;
//				lblTime.text = Number(event.time).toFixed(3);
//				
//				
//				if (stream != null)
//				{
//					if (player.state != MediaPlayerState.BUFFERING)
//						stream.bufferTime = player.bufferTime;
//					else
//						stream.bufferTime = 2;
//				}
//			}
			//item.duration
			
//			if(item!=null)
//			{
//				sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_TIME, {position: event.time, duration:player.duration , offset: _timeoffset});
//				
//			}
			
		}
		
		/**
		 * @private
		 * When the player is ready for playback, iterate through alternate
		 * audio tracks and update the UI.
		 **/
		private function onPlayerStateChange(event:MediaPlayerStateChangeEvent):void
		{
			
			
		}
		
		/**
		 * @private
		 * Executed when player encounters an error.
		 **/
		private function onPlayerError(event:MediaErrorEvent):void
		{
			//updateUI();
		}
		
		
		
		
		
		private function onSeekRequest():void
		{
			//			var seekTarget:Number = sldSeek.value;
			//			latestSeekTarget = seekTarget;
			//			
			//			if (player.canSeek)
			//				player.seek(seekTarget);
		}
		
		private function onAutoRewindChange(event:Event):void
		{
			//player.autoRewind = chkAutoRewind.selected;
		}
		
		private function onAutoSwitchChange(event:Event):void
		{
			//player.autoDynamicStreamSwitch = chkAutoSwitch.selected;
		}
		
		/**
		 * @private
		 * Listen for audio stream events.
		 **/
		private function onPlayerAudioStreamChange(event:AlternativeAudioEvent):void
		{
			if (event.switching)
				trace("[LBA - Sample] Alternative audio stream is switching.");
			else
				trace("[LBA - Sample] Alternative audio switch is complete.");
		}
		
		/**
		 * Returns the highest level Resource of a Specific type by traversing the proxiedElement parent chain.
		 */ 		
		public static function getResourceFromParentOfType(media:MediaElement, type:Class):MediaResourceBase
		{
			// If the current element is a proxy element, go up
			var result:MediaResourceBase = null;
			if (media.hasOwnProperty("proxiedElement") && (media["proxiedElement"] != null))
			{
				result = getResourceFromParentOfType(media["proxiedElement"], type);
			}			
			
			// If we didn't get any result from a higher level proxy
			// and the current media is of the needed type, return it.
			if (result == null && media.resource is type)
			{
				result = media.resource;
			}
			
			return result;
		}
		
		public static function getStreamType1(media:MediaElement):String
		{
			if (media == null)
			{
				return null;
			}
			
			var streamingURLResource:StreamingURLResource = getResourceFromParentOfType(media, StreamingURLResource) as StreamingURLResource;			
			
			if (streamingURLResource != null)
			{
				return streamingURLResource.streamType;						
			}
			return null;			
		}
		
		public function getStreamType():String
		{
			return getStreamType1(player.media);
		}
		
		//trace( "---> " + getStreamType() );
		//trace( "---> " + flash.utils.getQualifiedClassName( element ) );
		
		private function onCheckClick(event:MouseEvent):void
		{
			trace("----------");
			trace("* BufferTime: " + player.bufferTime);
			trace("* bufferLength: " + player.bufferLength);
			trace("* NS BufferTime: " + stream.bufferTime);
			trace("* NS bufferLength: " + stream.bufferLength);
			//trace("* Current State? " + player.state + ", " + listResources.selectedItem["data"]);
			//stream.maxPauseBufferTime = 1000;
			//b.bufferTime = 350;
			
			/*
			var d:MediaTraitBase = player.media.getTrait("dynamicStream");
			trace( "dynamicStream TraitType: " + flash.utils.getQualifiedClassName( d ) );
			
			var l:MediaTraitBase = player.media.getTrait("load");
			trace( "load TraitType: " + flash.utils.getQualifiedClassName( l ) );
			*/
		}
		
		private function onSetupClick(event:MouseEvent):void
		{
			var element:MediaElement = player.media;
			for (var i:uint; i < element.traitTypes.length; i++) {
				trace(element.traitTypes[i]);
			}
			
			var d:MediaTraitBase = player.media.getTrait("displayObject");
			trace( "displayObject TraitType: " + flash.utils.getQualifiedClassName( d ) );
		}
		
		
		
		
		
		//protected var _video:Video;
		
		/** Sound control object. **/
		protected var _transformer:SoundTransform;
		/** ID for the position interval. **/
		protected var _positionInterval:Number;
		/** Currently playing file. **/
		protected var _currentFile:String;
		/** Whether the buffer has filled **/
		private var _bufferFull:Boolean;
		/** Whether the enitre video has been buffered **/
		private var _bufferingComplete:Boolean;
		/** Whether we have checked the bandwidth. **/
		private var _bandwidthChecked:Boolean;
		/** Whether to switch on bandwidth detection **/
		private var _bandwidthSwitch:Boolean = true;
		/** Bandwidth check interval **/
		private var _bandwidthTimeout:Number = 2000;
		
		
		/** Constructor; sets up the connection and display. **/
		public function M3u8MediaProvider() 
		{
			super('m3u8');
		}
		
			
		/** Interval for bw checking - with dynamic streaming. **/
		private var _bandwidthInterval:Number;
		/** Whether to connect to a stream when bandwidth is detected. **/
		
		/** Is dynamic streaming possible. **/
		private var _dynamic:Boolean;
		/** The currently playing RTMP stream. **/
		
		/** Loaders for loading SMIL files. **/
		private var _xmlLoaders:Dictionary;
		
		/** Interval ID for subscription pings. **/
		private var _subscribeInterval:Number;
		/** Offset in seconds of the last seek. **/
		private var _timeoffset:Number = -1;
		/** Sound control object. **/
		
		/** Save that a stream is streaming. **/
		private var _isStreaming:Boolean;
		/** Level to which we're transitioning. **/
		private var _transitionLevel:Number = -1;
		/** Video object to be instantiated. **/
		
		/** Duration of the DVR stream (grows with a timer). **/
		private var _dvrDuration:Number = 0;
		/** Total duration of the DVR stream (set by configuration). **/
		private var _dvrTotalDuration:Number = 0;
		/** If the item's duration should be set back to 0 on load. **/
		private var _dvrResetDuration:Boolean = false;
		/** How long to wait between updates to DVR duration **/
		private var _dvrCheckDelay:Number = 1000;
		/** Interval ID for growing the DVR duration. **/
		private var _dvrInterval:Number;
		/** Whether we should pause the stream when we first connect to it **/
		private var	_lockOnStream:Boolean = false;
		
		public function M3u8MediaInit():void
		{
			Log.loggerFactory = new SimpleLoggerFactory(); 
			
			OSMFSettings.enableStageVideo = false;
			trace("* Maxium Retries: " + OSMFSettings.hdsMaximumRetries);
			//OSMFSettings.hdsMaximumRetries = 10;
			
			// factory
			factory = new DefaultMediaFactory();
			
			factory.addEventListener(MediaFactoryEvent.PLUGIN_LOAD, onPluginLoaded);
			factory.addEventListener(MediaFactoryEvent.PLUGIN_LOAD_ERROR, onPluginLoadError);
			factory.loadPlugin(new PluginInfoResource(new HLSPluginInfo()));
			
			
			// player
			player = new MediaPlayer();
			player.autoPlay = false;
			player.autoRewind = true;
			player.addEventListener(MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE, onPlayerStateChange);
			player.addEventListener(MediaPlayerCapabilityChangeEvent.CAN_PLAY_CHANGE, onPlayerCanPlayChange);
			player.addEventListener(TimeEvent.DURATION_CHANGE, onDurationChange);
			player.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, onPlayerCurrentTimeChange);
			player.addEventListener(AlternativeAudioEvent.AUDIO_SWITCHING_CHANGE, onPlayerAudioStreamChange);
			player.addEventListener(MediaErrorEvent.MEDIA_ERROR, onPlayerError);
			player.addEventListener(LoadEvent.LOAD_STATE_CHANGE, onLoadStateChange);
			
			// container
			container = new MediaContainer();
		}
		
		
		/** Constructor; sets up the connection and display. **/
		public override function initializeMediaProvider(cfg:PlayerConfig):void 
		{
			super.initializeMediaProvider(cfg);
			
			
			
		}
		
		/** Get metadata information from netstream class. **/
		public function onClientData(dat:Object=null):void 
		{
			//resize(_width, _height);
			//colowap
			
            
			
			
			if (!dat) return;
			if (dat.width) 
			{
				_video.width = dat.width;
				_video.height = dat.height;
				
				resize(_width, _height);
			}
			
			if (dat['duration'] && item.duration <= 0) 
			{
				item.duration = dat['duration'];
				//trace(item.duration);
			}
			
			
			if (dat['type'] == 'metadata' && !_meta) 
			{
				_meta = true;
				if (dat['seekpoints'])
				{
					_mp4 = true;
					_keyframes = convertSeekpoints(dat['seekpoints']);
				} else {
					_mp4 = false;
					_keyframes = dat['keyframes'];
				}
				if (item.start > 0) {
					seek(item.start);
				}
			}
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, {metadata: dat});
		}
		

		
		
		/** Video object to be instantiated. **/
		protected var _video:Video;
		/** Sound control object. **/
		
		/** Save whether metadata has already been sent. **/
		protected var _meta:Boolean;
		/** Object with keyframe times and positions. **/
		protected var _keyframes:Object;
		/** Offset in bytes of the last seek. **/
		protected var _byteoffset:Number = 0;
	
		/** Boolean for mp4 / flv streaming. **/
		protected var _mp4:Boolean;
		/** Variable that takes reloading into account. **/
		protected var _iterator:Number;
		/** Start parameter. **/
		private var _startparam:String = 'start';
		/** Whether the buffer has filled **/
		
		/** Bandwidth check delay **/
		private var _bandwidthDelay:Number = 2000;
		
		
		
		
		
		
		
		
		
		
		
		
		
		public function onMetaData(info:Object):void 
		{
			trace("metadata: duration=" + info.duration + " width=" + info.width + "height=" + info.height + " framerate=" + info.framerate);
		}
		private var m:Number =1.5;
		
		private var nx:Number =3000;
		private var seekint:int =10;
		
		private function FastPlayHandler(e:TimerEvent):void
		{
			//trace(_stream.time+6);
			///_stream.seek(_stream.time+seekint);
		}
		
		/** Convert seekpoints to keyframes. **/
		protected function convertSeekpoints(dat:Object):Object {
			var kfr:Object = new Object();
			kfr.times = new Array();
			kfr.filepositions = new Array();
			for (var j:String in dat) {
				kfr.times[j] = Number(dat[j]['time']);
				kfr.filepositions[j] = Number(dat[j]['offset']);
			}
			return kfr;
		}
		
		/** Catch security errors. **/
		protected function errorHandler(evt:ErrorEvent):void {
			error(evt.text);
		}
		
		/** Bandwidth is checked as long the stream hasn't completed loading. **/
		private function checkBandwidth(lastLoaded:Number):void 
		{
//			var currentLoaded:Number = _stream.bytesLoaded;
//			var bandwidth:Number = Math.ceil((currentLoaded - lastLoaded) / 1024) * 8 / (_bandwidthDelay / 1000);
//			
//			if (currentLoaded < _stream.bytesTotal) {
//				if (bandwidth > 0) {
//					config.bandwidth = bandwidth;
//					var obj:Object = {bandwidth:bandwidth};
//					if (item.duration > 0) {
//						obj.bitrate = Math.ceil(_stream.bytesTotal / 1024 * 8 / item.duration);
//					}
//					sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, {metadata: obj});
//				}
//				if (_bandwidthSwitch) {
//					_bandwidthSwitch = false;
//					_bandwidthChecked = false;
//					if (item.currentLevel != item.getLevel(config.bandwidth, config.width)) {
//						load(item);
//						return;
//					}
//				}
//				clearTimeout(_bandwidthTimeout);
//				_bandwidthTimeout = setTimeout(checkBandwidth, _bandwidthDelay, currentLoaded);
//			}
		}
		
		/** Return a keyframe byteoffset or timeoffset. **/
		protected function getOffset(pos:Number, tme:Boolean=false):Number {
			if (!_keyframes) {
				return 0;
			}
			for (var i:Number = 0; i < _keyframes.times.length - 1; i++) {
				if (_keyframes.times[i] <= pos && _keyframes.times[i + 1] >= pos) {
					break;
				}
			}
			if (tme == true) {
				return _keyframes.times[i];
			} else {
				return _keyframes.filepositions[i];
			}
		}
		
		
		/** Create the video request URL. **/
		protected function getURL():String 
		{
			var url:String = item.file;
			var off:Number = _byteoffset;
			if (getConfigProperty('startparam') as String) 
			{
				_startparam = getConfigProperty('startparam');
			}
			if (item.streamer)
			{
				if (item.streamer.indexOf('/') > 0) {
					url = item.streamer;
					url = getURLConcat(url, 'file', item.file);
				} else {
					_startparam = item.streamer;
				}
			}
			if (_mp4 || _startparam == 'starttime') {
				off = _timeoffset;
			}
			if (!_mp4 || off > 0) {
				url = getURLConcat(url, _startparam, off);
			}
			if (config['token'] || item['token']) {
				url = getURLConcat(url, 'token', item['token'] ? item['token'] : config['token']);
			}
			return url;
		}
		
		
		/** Concatenate a parameter to the url. **/
		private function getURLConcat(url:String, prm:String, val:*):String {
			if (url.indexOf('?') > -1) {
				return url + '&' + prm + '=' + val;
			} else {
				return url + '?' + prm + '=' + val;
			}
		}
		
		
		/** Load content. **/
		override public function load(itm:PlaylistItem):void 
		{
			//colowap联播问题bug
			var res:URLResource = new URLResource(itm.file);
			var element:MediaElement = factory.createMediaElement(res);
			
			var elementLayout:LayoutMetadata = new LayoutMetadata();
			elementLayout.percentHeight = 100;
			elementLayout.percentWidth = 100;
			elementLayout.scaleMode = ScaleMode.LETTERBOX;
			elementLayout.layoutMode = LayoutMode.NONE;
			elementLayout.verticalAlign = VerticalAlign.MIDDLE;
			elementLayout.horizontalAlign = HorizontalAlign.CENTER;
			
			elementLayout.width=RootReference._player.config.width;
			elementLayout.height=RootReference._player.config.height;
			element.addMetadata(LayoutMetadata.LAYOUT_NAMESPACE, elementLayout);
			
			container.addMediaElement(element);
			
			player.autoDynamicStreamSwitch=true;
			player.media = element;
			
			
			
			
			
			_item = itm;
			_position = _timeoffset;
			_bufferFull = false;
			_bufferingComplete = false;
			_bandwidthSwitch = true;
			
			if (item.levels.length > 0) 
			{ 
				item.setLevel(item.getLevel(config.bandwidth, config.width)); 
			}
			
			
			
			media = container;
			
			
			
			
			
			//_stream.play(getURL());
			//play();
			
			
			clearInterval(_positionInterval);
			_positionInterval = setInterval(positionInterval, 100);
			
			sendMediaEvent(MediaEvent.LOADEDJWPLAYER_MEDIA);
			setState(PlayerState.BUFFERING);
			sendBufferEvent(0, 0);
			streamVolume(config.mute ? 0 : config.volume);
			
			onClientData();
		}
		
		//		public function SettateIdle():void
		//		{
		//			setState(PlayerState.IDLE);
		//		}
		
		
		
		
		/** Pause playback. **/
		override public function pause():void 
		{
			
			if (player.canPause)
			{
				player.pause();
				super.pause();
			}
		}
		
		
		/** Resume playing. **/
		override public function play():void 
		{
			//fastSlowTimer.stop();
			//_stream.resume();
			if (!_positionInterval) 
			{
				_positionInterval = setInterval(positionInterval, 100);
			}
			
			
			if (!player.playing)
			{
				if (player.canPlay)
				{
					player.play();
					super.play();
				}
					
			}
			
		}
		
		
		/** Interval for the position progress **/
		protected function positionInterval():void 
		{
			
/*			//_position = Math.round(_stream.time * 10) / 10;
			var percentoffset:Number;
			if (_mp4) 
			{
				_position += _timeoffset;
			}
			
			var bufferPercent:Number;
			var bufferFill:Number;
			if (item.duration > 0) {
				//percentoffset =  Math.round(_timeoffset /  item.duration * 100);
				//bufferPercent = (_stream.bytesLoaded / _stream.bytesTotal) * (1 - _timeoffset / item.duration) * 100;
				//var bufferTime:Number = _stream.bufferTime < (item.duration - position) ? _stream.bufferTime : Math.round(item.duration - position);
				//bufferFill = _stream.bufferTime == 0 ? 0 : Math.ceil(_stream.bufferLength / bufferTime * 100);
			} else {
				percentoffset = 0;
				bufferPercent = 0;
				//bufferFill = _stream.bufferLength/_stream.bufferTime * 100;
			}
			
//			if (!_bandwidthChecked && _stream.bytesLoaded > 0 && _stream.bytesLoaded < _stream.bytesTotal) {
//				_bandwidthChecked = true;
//				clearTimeout(_bandwidthTimeout);
//				//_bandwidthTimeout = setTimeout(checkBandwidth, _bandwidthDelay, _stream.bytesLoaded);
//			}
			
			if (bufferFill < 25 && state == PlayerState.PLAYING) {
				_bufferFull = false;
				//_stream.pause();
				setState(PlayerState.BUFFERING);
			} else if (bufferFill > 95 && state == PlayerState.BUFFERING && _bufferFull == false) {
				_bufferFull = true;
				sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_BUFFER_FULL);
			}
			
			if (!_bufferingComplete) {
				if ((bufferPercent + percentoffset) == 100 && _bufferingComplete == false) {
					_bufferingComplete = true;
				}
				sendBufferEvent(bufferPercent, _timeoffset);
			}
			
			if (state != PlayerState.PLAYING) {
				return;
			}
			
			if (_position < item.duration) 
			{
				if (_position >= 0) 
				{
					//每
					//trace("item._position:::"+_position);
					sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_TIME, {position: _position, duration: item.duration, offset: _timeoffset});
				}
			} 
			else if (item.duration > 0) 
			{
				// Playback completed
				complete();
			}*/
		}
		
		/** Handle a resize event **/
		override public function resize(width:Number, height:Number):void 
		{
			super.resize(width, height);
			
			if (item.levels.length > 0 && item.getLevel(config.bandwidth, config.width) != item.currentLevel) 
			{
				_byteoffset = getOffset(position);
				_timeoffset = _position = getOffset(position,true);
				load(item);
			}
		}
		
		/** Seek to a specific second. **/
		override public function seek(pos:Number):void 
		{
			trace("httpseek"+pos);
			
			var seekTarget:Number = pos;
			latestSeekTarget = seekTarget;
			
			if (player.canSeek)
			{
				player.seek(seekTarget);
			}
				
			
			
//			var off:Number = getOffset(pos);
//			super.seek(pos);
//			clearInterval(_positionInterval);
//			_positionInterval = undefined;
//			
//			if (off < _byteoffset || off >= _byteoffset + _stream.bytesLoaded) 
//			{
//				_timeoffset = _position = getOffset(pos, true);
//				_byteoffset = off;
//				load(item);//mp4http码流切换会走这里 然后seek走下面
//			} 
//			else 
//			{
//				if (state == PlayerState.PAUSED) 
//				{
//					_stream.resume();
//				}
//				if (_mp4) 
//				{
//					_stream.seek(getOffset(_position - _timeoffset, true));
//				}
//				else 
//				{
//					_stream.seek(getOffset(_position, true));
//				}
//				play();
//			}
		}
		
		
		/** Receive NetStream status updates. **/
		protected function statusHandler(evt:NetStatusEvent):void 
		{
			trace("流状态：：："+evt.info.code);
			switch (evt.info.code)
			{
				case "NetStream.Unpause.Notify":
				{
					/*		if(AssetURL.kbpschangingzhong==true)
					{
					AssetURL.kbpschangingzhong=false;//http码流切换完毕
					
					this.seek(AssetURL.changekbpsStartTime);
					
					
					}*/
				}
					break;
				case "NetStream.Play.Stop":
					if (state != PlayerState.BUFFERING)
					{
						complete();
					}
					break;
				case "NetStream.Play.StreamNotFound":
					stop();
					error('Video not found: ' + item.file);
					break;
				case 'NetStream.Buffer.Full':
					if (!_bufferFull) {
						_bufferFull = true;
						sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_BUFFER_FULL);
					}
					break;
			}
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, {metadata: {status: evt.info.code}});
		}
		
		
		/** Destroy the HTTP stream. **/
		override public function stop():void 
		{
//			if (_stream.bytesLoaded + _byteoffset < _stream.bytesTotal) 
//			{
//				_stream.close();
//			} 
//			else 
//			{
//				_stream.pause();
//			}
			clearInterval(_positionInterval);
			_positionInterval = undefined;
			_position = _byteoffset = _timeoffset = 0;
			_keyframes = undefined;
			_bandwidthChecked = false;
			_meta = false;
			super.stop();
		}
		
		
		/** Set the volume level. **/
		override public function setVolume(vol:Number):void {
			streamVolume(vol);
			super.setVolume(vol);
		}
		
		/** Set the stream's volume, without sending a volume event **/
		protected function streamVolume(level:Number):void 
		{
//			_transformer.volume = level / 100;
//			if (_stream) {
//				_stream.soundTransform = _transformer;
//			}
			
			player.volume=(level/100);
		}
		
		}
}