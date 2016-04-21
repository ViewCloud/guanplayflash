/**
 * Manages playback of http streaming flv.
 **/
package com.tanplayer.media 
{
	import com.tanplayer.events.MediaEvent;
	import com.tanplayer.model.PlayerConfig;
	import com.tanplayer.model.PlaylistItem;
	import com.tanplayer.player.PlayerState;
	import com.tanplayer.utils.NetClient;
	import com.tanplayer.utils.RootReference;
	
	import flash.display.*;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.geom.Rectangle;
	import flash.media.*;
	import flash.media.SoundTransform;
	import flash.media.StageVideo;
	import flash.media.StageVideoAvailability;
	import flash.media.Video;
	import flash.net.*;
	import flash.net.URLLoader;
	import flash.net.URLStream;
	import flash.system.Security;
	import flash.utils.*;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import org.mangui.hls.HLS;
	import org.mangui.hls.HLSSettings;
	import org.mangui.hls.event.HLSError;
	import org.mangui.hls.event.HLSEvent;
	import org.mangui.hls.model.AudioTrack;
	import org.mangui.hls.model.Level;
	import org.mangui.hls.utils.JSURLLoader;
	import org.mangui.hls.utils.JSURLStream;
	import org.mangui.hls.utils.Log;
	import org.mangui.hls.utils.ScaleVideo;
	import org.osmf.events.TimeEvent;
	
	
	public class M3u8MediaProvider extends MediaProvider 
	{
		/** NetConnection object for setup of the video stream. **/
		
		/** Video object to be instantiated. **/
		protected var _video:Video;
		/** Sound control object. **/
		protected var _transformer:SoundTransform;
		/** ID for the _position interval. **/
		
		/** Save whether metadata has already been sent. **/
		protected var _meta:Boolean;
		/** Object with keyframe times and positions. **/
		protected var _keyframes:Object;
		/** Offset in bytes of the last seek. **/
		protected var _byteoffset:Number = 0;
		/** Offset in seconds of the last seek. **/
		protected var _timeoffset:Number = 0;
		/** Boolean for mp4 / flv streaming. **/
		protected var _mp4:Boolean;
		/** Variable that takes reloading into account. **/
		protected var _iterator:Number;
		/** Start parameter. **/
		private var _startparam:String = 'start';
		/** Whether the buffer has filled **/
		private var _bufferFull:Boolean;
		/** Whether the enitre video has been buffered **/
		private var _bufferingComplete:Boolean;
		/** Whether we have checked the bandwidth. **/
		private var _bandwidthSwitch:Boolean = true;
		/** Whether we have checked bandwidth **/
		private var _bandwidthChecked:Boolean;
		/** Bandwidth check delay **/
		private var _bandwidthDelay:Number = 2000;
		/** Bandwidth timeout id **/
		private var _bandwidthTimeout:uint;
		
		/** Constructor; sets up the connection and display. **/
		public function M3u8MediaProvider() 
		{
			super('m3u8');
		}
		
		
		public var fastSlowTimer:Timer= new Timer(nx);
		
		
		
		
		public function StartFastPlay():void
		{
			seekint=10;
			fastSlowTimer.start();
		}
		
		public function StartSlowPlay():void
		{
			seekint=-10;
			fastSlowTimer.start();
		}
		
//==================m3u8==========================================		
		public override function initializeMediaProvider(cfg:PlayerConfig):void 
		{
			RootReference.stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, _onStageVideoState);
			
			super.initializeMediaProvider(cfg);
			_tanhls = new HLS();
			fastSlowTimer.addEventListener(TimerEvent.TIMER,FastPlayHandler);
		}
		
		protected var _tanhls : HLS;
		/** Sheet to place on top of the video. **/
		protected var _sheet : Sprite;
		/** Reference to the stage video element. **/
		protected var _stageVideo : StageVideo = null;
		/** Reference to the video element. **/
		
		/** Video size **/
		protected var _videoWidth : int = 0;
		protected var _videoHeight : int = 0;
		/** current media position */
		protected var _mediaPosition : Number;
		protected var _duration : Number;
		/** URL autoload feature */
		
		/* JS callback name */
		protected var _callbackName : String;
		/* stats handler */
		private var _statsHandler :M3u8StatsHandler;
		
		
		
		
		
		
		
		
		
		
		
	
		
		protected function _trigger(event : String, ...args) : void 
		{
			//trace("args:::::::"+args);
		}
		
		/** Notify javascript the framework is ready. **/
		protected function _pingJavascript() : void {
			trace("ready", getTimer());
		};
		
		/** Forward events from the framework. **/
		protected function _completeHandler(event : HLSEvent) : void {
			trace("complete");
		};
		
		protected function _errorHandler(event : HLSEvent) : void 
		{
			var hlsError : HLSError = event.error;
			trace("error", hlsError.code, hlsError.url, hlsError.msg);
		};
		
		protected function _levelLoadedHandler(event : HLSEvent) : void {
			trace("levelLoaded", event.loadMetrics);
		};
		
		protected function _audioLevelLoadedHandler(event : HLSEvent) : void {
			trace("audioLevelLoaded", event.loadMetrics);
		};
		
		protected function _fragmentLoadedHandler(event : HLSEvent) : void {
			trace("fragmentLoaded", event.loadMetrics);
		};
		
		protected function _fragmentPlayingHandler(event : HLSEvent) : void {
			trace("fragmentPlaying", event.playMetrics);
		};
		
		protected function _manifestLoadedHandler(event : HLSEvent) : void 
		{
			item.duration = event.levels[_tanhls.startLevel].duration;
			
			_tanhls.stream.play(null, -1);
			
			
			trace("manifest", _duration, event.levels, event.loadMetrics);
		};
		
		protected function _mediaTimeHandler(event : HLSEvent) : void 
		{
			//trace("每");
			_duration = event.mediatime.duration;
			_mediaPosition = event.mediatime.position;
			//trace("position", event.mediatime);
			
			
			
			
			//			//_position = Math.round(_stream.time * 10) / 10;
			//			var percentoffset:Number;
			//			if (_mp4) 
			//			{
			//				_position += _timeoffset;
			//			}
			//			
			//			var bufferPercent:Number;
			//			var bufferFill:Number;
			//			if (item.duration > 0) {
			//				percentoffset =  Math.round(_timeoffset /  item.duration * 100);
			//				bufferPercent = (_stream.bytesLoaded / _stream.bytesTotal) * (1 - _timeoffset / item.duration) * 100;
			//				var bufferTime:Number = _stream.bufferTime < (item.duration - position) ? _stream.bufferTime : Math.round(item.duration - position);
			//				bufferFill = _stream.bufferTime == 0 ? 0 : Math.ceil(_stream.bufferLength / bufferTime * 100);
			//			} else {
			//				percentoffset = 0;
			//				bufferPercent = 0;
			//				bufferFill = _stream.bufferLength/_stream.bufferTime * 100;
			//			}
			//			
			//			if (!_bandwidthChecked && _stream.bytesLoaded > 0 && _stream.bytesLoaded < _stream.bytesTotal) {
			//				_bandwidthChecked = true;
			//				clearTimeout(_bandwidthTimeout);
			//				_bandwidthTimeout = setTimeout(checkBandwidth, _bandwidthDelay, _stream.bytesLoaded);
			//			}
			//			
			//			if (bufferFill < 25 && state == PlayerState.PLAYING) {
			//				_bufferFull = false;
			//				_stream.pause();
			//				setState(PlayerState.BUFFERING);
			//			} else if (bufferFill > 95 && state == PlayerState.BUFFERING && _bufferFull == false) {
			//				_bufferFull = true;
			//				sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_BUFFER_FULL);
			//			}
			//			
			//			if (!_bufferingComplete) {
			//				if ((bufferPercent + percentoffset) == 100 && _bufferingComplete == false) {
			//					_bufferingComplete = true;
			//				}
			//				sendBufferEvent(bufferPercent, _timeoffset);
			//			}
			//			
			//			if (state != PlayerState.PLAYING) {
			//				return;
			//			}
			//			
			//			if (_position < item.duration) 
			//			{
			//				if (_position >= 0) 
			//				{
			//					//每
			//					//trace("item._position:::"+_position);
		//	sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_TIME, {position: _mediaPosition, duration: _duration, offset: _timeoffset});
			//				}
			//			} 
			//			else if (item.duration > 0) 
			//			{
			//				// Playback completed
			//				complete();
			//			}
			
			
			
			
			
			
			
			
			var videoWidth : int = _video ? _video.videoWidth : _stageVideo.videoWidth;
			var videoHeight : int = _video ? _video.videoHeight : _stageVideo.videoHeight;
			
			if (videoWidth && videoHeight) {
				var changed : Boolean = _videoWidth != videoWidth || _videoHeight != videoHeight;
				if (changed) {
					_videoHeight = videoHeight;
					_videoWidth = videoWidth;
					//_resize();
					_trigger("videoSize", _videoWidth, _videoHeight);
				}
			}
		}
		
		protected function _playbackStateHandler(event : HLSEvent) : void 
		{
			trace("state;;;;;;", event.state);
			if(event.state=="PLAYING_BUFFERING")
			{
				setState(PlayerState.BUFFERING);
			}
			else if(event.state=="PLAYING")
			{
				setState(PlayerState.PLAYING);
			}
		}
		
		protected function _seekStateHandler(event : HLSEvent) : void 
		{
			trace("seekState", event.state);
			if(event.state=="IDLE")
			{
				stop();
			}
		}
		
		protected function _levelSwitchHandler(event : HLSEvent) : void {
			trace("当前切换到的码率级别", event.level);
		};
		
		protected function _fpsDropHandler(event : HLSEvent) : void {
			trace("fpsDrop", event.level);
		};
		
		protected function _fpsDropLevelCappingHandler(event : HLSEvent) : void {
			trace("fpsDropLevelCapping", event.level);
		};
		
		protected function _fpsDropSmoothLevelSwitchHandler(event : HLSEvent) : void {
			trace("fpsDropSmoothLevelSwitch");
		};
		
		protected function _audioTracksListChange(event : HLSEvent) : void {
			trace("audioTracksListChange", _getAudioTrackList());
		}
		
		protected function _audioTrackChange(event : HLSEvent) : void {
			trace("audioTrackChange", event.audioTrack);
		}
		
		protected function _id3Updated(event : HLSEvent) : void {
			trace("id3Updated", event.ID3Data);
		}
		
		/** Javascript getters. **/
		protected function _getCurrentLevel() : int {
			return _tanhls.currentLevel;
		};
		
		protected function _getNextLevel() : int {
			return _tanhls.nextLevel;
		};
		
		protected function _getLoadLevel() : int {
			return _tanhls.loadLevel;
		};
		
		protected function _getLevels() : Vector.<Level> {
			return _tanhls.levels;
		};
		
		protected function _getAutoLevel() : Boolean {
			return _tanhls.autoLevel;
		};
		
		protected function _getDuration() : Number {
			return _duration;
		};
		
		protected function _getPosition() : Number {
			return _tanhls.position;
		};
		
		protected function _getPlaybackState() : String {
			return _tanhls.playbackState;
		};
		
		protected function _getSeekState() : String {
			return _tanhls.seekState;
		};
		
		
		
		protected function _getminBufferLength() : Number {
			return HLSSettings.minBufferLength;
		};
		
		protected function _getlowBufferLength() : Number {
			return HLSSettings.lowBufferLength;
		};
		
		protected function _getmaxBackBufferLength() : Number {
			return HLSSettings.maxBackBufferLength;
		};
		
		protected function _getflushLiveURLCache() : Boolean {
			return HLSSettings.flushLiveURLCache;
		};
		
		protected function _getstartFromLevel() : int {
			return HLSSettings.startFromLevel;
		};
		
		protected function _getseekFromLevel() : int {
			return HLSSettings.seekFromLevel;
		};
		
		protected function _getLogDebug() : Boolean {
			return HLSSettings.logDebug;
		};
		
		protected function _getLogDebug2() : Boolean {
			return HLSSettings.logDebug2;
		};
		
		protected function _getUseHardwareVideoDecoder() : Boolean {
			return HLSSettings.useHardwareVideoDecoder;
		};
		
		protected function _getCapLeveltoStage() : Boolean {
			return HLSSettings.capLevelToStage;
		};
		
		protected function _getAutoLevelCapping() : int {
			return _tanhls.autoLevelCapping;
		};
		
		protected function _getJSURLStream() : Boolean {
			return (_tanhls.URLstream is JSURLStream);
		};
		
		protected function _getPlayerVersion() : Number {
			return 3;
		};
		
		protected function _getAudioTrackList() : Array {
			var list : Array = [];
			var vec : Vector.<AudioTrack> = _tanhls.audioTracks;
			for (var i : Object in vec) {
				list.push(vec[i]);
			}
			return list;
		};
		
		protected function _getAudioTrackId() : int {
			return _tanhls.audioTrack;
		};
		
		protected function _getStats() : Object {
			return _statsHandler.stats;
		};
		
		
		
		
		
		
		
		
		
		
		
		
		
		protected function _setCurrentLevel(level : int) : void {
			_tanhls.currentLevel = level;
		};
		
		protected function _setNextLevel(level : int) : void {
			_tanhls.nextLevel = level;
		};
		
		protected function _setLoadLevel(level : int) : void {
			_tanhls.loadLevel = level;
		};
		
		protected function _setmaxBufferLength(newLen : Number) : void {
			HLSSettings.maxBufferLength = newLen;
		};
		
		protected function _setminBufferLength(newLen : Number) : void {
			HLSSettings.minBufferLength = newLen;
		};
		
		protected function _setlowBufferLength(newLen : Number) : void {
			HLSSettings.lowBufferLength = newLen;
		};
		
		protected function _setbackBufferLength(newLen : Number) : void {
			HLSSettings.maxBackBufferLength = newLen;
		};
		
		protected function _setflushLiveURLCache(flushLiveURLCache : Boolean) : void {
			HLSSettings.flushLiveURLCache = flushLiveURLCache;
		};
		
		protected function _setstartFromLevel(startFromLevel : int) : void 
		{
			HLSSettings.startFromLevel = startFromLevel;
		};
		
		protected function _setseekFromLevel(seekFromLevel : int) : void 
		{
			HLSSettings.seekFromLevel = seekFromLevel;
		};
		
		protected function _setLogDebug(debug : Boolean) : void 
		{
			HLSSettings.logDebug = debug;
		}
		
		protected function _setLogDebug2(debug2 : Boolean) : void 
		{
			HLSSettings.logDebug2 = debug2;
		}
		
		protected function _setUseHardwareVideoDecoder(value : Boolean) : void
		{
			HLSSettings.useHardwareVideoDecoder = value;
		}
		
		protected function _setCapLeveltoStage(value : Boolean) : void{
			HLSSettings.capLevelToStage = value;
		}
		
		protected function _setAutoLevelCapping(value : int) : void{
			_tanhls.autoLevelCapping = value;
		}
		
		protected function _setJSURLStream(jsURLstream : Boolean) : void 
		{
			if (jsURLstream) {
				_tanhls.URLstream = JSURLStream as Class;
				_tanhls.URLloader = JSURLLoader as Class;
				if (_callbackName) {
					_tanhls.URLstream.externalCallback = _callbackName;
					_tanhls.URLloader.externalCallback = _callbackName;
				}
			} else {
				_tanhls.URLstream = URLStream as Class;
				_tanhls.URLloader = URLLoader as Class;
			}
		};
		
		protected function _setAudioTrack(val : int) : void 
		{
			if (val == _tanhls.audioTrack) return;
			_tanhls.audioTrack = val;
			if (!isNaN(_mediaPosition)) {
				_tanhls.stream.seek(_mediaPosition);
			}
		};
		
	
		
		/** StageVideo detector. **/
		protected function _onStageVideoState(event : StageVideoAvailabilityEvent) : void 
		{
			var available : Boolean = (event.availability == StageVideoAvailability.AVAILABLE);
			
			_tanhls.stage = RootReference.stage;
			// set framerate to 60 fps
			//stage.frameRate = 60;
			// set up stats handler
			_statsHandler = new M3u8StatsHandler(_tanhls);
			_tanhls.addEventListener(HLSEvent.PLAYBACK_COMPLETE, _completeHandler);
			_tanhls.addEventListener(HLSEvent.ERROR, _errorHandler);
			_tanhls.addEventListener(HLSEvent.FRAGMENT_LOADED, _fragmentLoadedHandler);
			_tanhls.addEventListener(HLSEvent.AUDIO_LEVEL_LOADED, _audioLevelLoadedHandler);
			_tanhls.addEventListener(HLSEvent.LEVEL_LOADED, _levelLoadedHandler);
			_tanhls.addEventListener(HLSEvent.FRAGMENT_PLAYING, _fragmentPlayingHandler);
			_tanhls.addEventListener(HLSEvent.MANIFEST_LOADED, _manifestLoadedHandler);
			_tanhls.addEventListener(HLSEvent.MEDIA_TIME, _mediaTimeHandler);
			_tanhls.addEventListener(HLSEvent.PLAYBACK_STATE, _playbackStateHandler);
			_tanhls.addEventListener(HLSEvent.SEEK_STATE, _seekStateHandler);
			_tanhls.addEventListener(HLSEvent.LEVEL_SWITCH, _levelSwitchHandler);
			_tanhls.addEventListener(HLSEvent.AUDIO_TRACKS_LIST_CHANGE, _audioTracksListChange);
			_tanhls.addEventListener(HLSEvent.AUDIO_TRACK_SWITCH, _audioTrackChange);
			_tanhls.addEventListener(HLSEvent.ID3_UPDATED, _id3Updated);
			_tanhls.addEventListener(HLSEvent.FPS_DROP, _fpsDropHandler);
			_tanhls.addEventListener(HLSEvent.FPS_DROP_LEVEL_CAPPING, _fpsDropLevelCappingHandler);
			_tanhls.addEventListener(HLSEvent.FPS_DROP_SMOOTH_LEVEL_SWITCH, _fpsDropSmoothLevelSwitchHandler);
			
			HLSSettings.flushLiveURLCache=true;
			
			if (available && RootReference.stage.stageVideos.length > 0)
			{
				_stageVideo = RootReference.stage.stageVideos[0];
				_stageVideo.addEventListener(StageVideoEvent.RENDER_STATE, _onStageVideoStateChange)
				_stageVideo.viewPort = new Rectangle(0, 0, RootReference.stage.stageWidth, RootReference.stage.stageHeight);
				_stageVideo.attachNetStream(_tanhls.stream);
			} 
			else 
			{
				_video = new Video(RootReference.stage.stageWidth, RootReference.stage.stageHeight);
				_video.addEventListener(VideoEvent.RENDER_STATE, _onVideoStateChange);
			
				_video.smoothing = true;
				_video.attachNetStream(_tanhls.stream);
			}
			
			RootReference.stage.removeEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, _onStageVideoState);
		}
		
		private function _onStageVideoStateChange(event : StageVideoEvent) : void 
		{
			Log.info("Video decoding:" + event.status);
		}
		
		private function _onVideoStateChange(event : VideoEvent) : void
		{
			Log.info("Video decoding:" + event.status);
		}
		
//========================m3u8==================================		
		
		
		
		
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
		protected function convertSeekpoints(dat:Object):Object 
		{
			var kfr:Object = new Object();
			kfr.times = new Array();
			kfr.filepositions = new Array();
			for (var j:String in dat) 
			{
				kfr.times[j] = Number(dat[j]['time']);
				kfr.filepositions[j] = Number(dat[j]['offset']);
			}
			return kfr;
		}
		
		/** Catch security errors. **/
		protected function errorHandler(evt:ErrorEvent):void {
			error(evt.text);
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
				if (item.streamer.indexOf('/') > 0) 
				{
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
			_video.clear();
			
			_item = itm;
			_position = _timeoffset;
			_bufferFull = false;
			_bufferingComplete = false;
			_bandwidthSwitch = true;
			
			if (item.levels.length > 0) 
			{ 
				item.setLevel(item.getLevel(config.bandwidth, config.width)); 
			}
			
			media = _video;
			
			_tanhls.load(itm.file);
			
			sendMediaEvent(MediaEvent.LOADEDJWPLAYER_MEDIA);
			setState(PlayerState.BUFFERING);
			sendBufferEvent(0, 0);
			setVolume(config.mute ? 0 : config.volume);
		}
		
		//		public function SettateIdle():void
		//		{
		//			setState(PlayerState.IDLE);
		//		}
		
		/** Get metadata information from netstream class. **/
		public function onClientData(dat:Object):void 
		{
//			if (!dat) return;
//			if (dat.width) 
//			{
//				_video.width = dat.width;
//				_video.height = dat.height;
//				
//				resize(_width, _height);
//			}
//			
//			if (dat['duration'] && item.duration <= 0) 
//			{
//				
//				//trace(item.duration);
//			}
//			
//			
//			if (dat['type'] == 'metadata' && !_meta) 
//			{
//				_meta = true;
//				if (dat['seekpoints'])
//				{
//					_mp4 = true;
//					_keyframes = convertSeekpoints(dat['seekpoints']);
//				} else {
//					_mp4 = false;
//					_keyframes = dat['keyframes'];
//				}
//				if (item.start > 0) {
//					seek(item.start);
//				}
//			}
//			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, {metadata: dat});
		}
		
		
		/** Pause playback. **/
		override public function pause():void 
		{
			//fastSlowTimer.stop();
			_tanhls.stream.pause();
			super.pause();
		}
		
		
		/** Resume playing. **/
		override public function play():void 
		{
			_tanhls.stream.resume();
			super.play();
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
			//var off:Number = getOffset(pos);
			_tanhls.stream.seek(pos);
			super.seek(pos);
			
			
//			if (off < _byteoffset || off >= _byteoffset + _stream.bytesLoaded) 
//			{
//				_timeoffset = _position = getOffset(pos, true);
//				_byteoffset = off;
//				load(item);//mp4http码流切换会走这里 然后seek走下面
//			} 
//			else 
//			{
//				
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
			_tanhls.stream.close();
			
			_position = _byteoffset = _timeoffset = 0;
			_keyframes = undefined;
			_bandwidthChecked = false;
			_meta = false;
			super.stop();
		}
		
		
		/** Set the volume level. **/
		override public function setVolume(vol:Number):void 
		{
			_tanhls.stream.soundTransform = new SoundTransform(vol/100);
			super.setVolume(vol);
		}
	}
}