﻿package com.tanplayer.media {
	import com.tanplayer.events.MediaEvent;
	import com.tanplayer.model.PlayerConfig;
	import com.tanplayer.model.PlaylistItem;
	import com.tanplayer.player.PlayerState;
	import com.tanplayer.utils.NetClient;
	
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.utils.*;


	/**
	 * Wrapper for playback of progressively downloaded _video.
	 **/
	public class VideoMediaProvider extends MediaProvider 
	{
		/** Video object to be instantiated. **/
		protected var _video:Video;
		/** NetConnection object for setup of the video _stream. **/
		protected var _connection:NetConnection;
		/** NetStream instance that handles the stream IO. **/
		protected var _stream:NetStream;
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
		public function VideoMediaProvider() 
		{
			super('video');
		}


		public override function initializeMediaProvider(cfg:PlayerConfig):void {
			super.initializeMediaProvider(cfg);
			_connection = new NetConnection();
			_connection.connect(null);
			_stream = new NetStream(_connection);
			_stream.addEventListener(NetStatusEvent.NET_STATUS, statusHandler);
			_stream.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			_stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler);
			_stream.bufferTime = config.bufferlength;
			_stream.client = new NetClient(this);
			_transformer = new SoundTransform();
			_video = new Video(320, 240);
			_video.smoothing = config.smoothing;
			_video.attachNetStream(_stream);
		}


		/** Catch security errors. **/
		protected function errorHandler(evt:ErrorEvent):void {
			error(evt.text);
		}


		/** Load content. **/
		override public function load(itm:PlaylistItem):void 
		{
			var replay:Boolean;
			_bufferFull = false;
			_bufferingComplete = false;
			if (itm.levels.length > 0) {
				itm.setLevel(itm.getLevel(config.bandwidth, config.width));
				_bandwidthChecked = false;
			} else {
				_bandwidthChecked = true;
			}
			
			if (!item 
					|| _currentFile != itm.file 
					|| _stream.bytesLoaded == 0 
					|| (_stream.bytesLoaded < _stream.bytesTotal > 0)) 
			{
				media = _video;
				_currentFile = itm.file;
				_stream.checkPolicyFile = true;
				_stream.play(itm.file);
				_stream.pause();
			} else {
				if (itm.duration <= 0) { itm.duration = item.duration; }
				seekStream(itm.start, false);
			}

			_item = itm;

			super.load(itm);
			
			setState(PlayerState.BUFFERING);
			sendBufferEvent(0);
			
			streamVolume(config.mute ? 0 : config.volume);
			
			clearInterval(_positionInterval);
			_positionInterval = setInterval(positionHandler, 200);

		}

		/** Get metadata information from netstream class. **/
		public function onClientData(dat:Object):void {
			if (!dat) return;
			if (dat.width) {
				_video.width = dat.width;
				_video.height = dat.height;
				resize(_width, _height);
			}
			if (dat.duration && item.duration < 0) {
				item.duration = dat.duration;
			}
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, {metadata: dat});
		}


		/** Pause playback. **/
		override public function pause():void {
			_stream.pause();
			super.pause();
		}


		/** Resume playing. **/
		override public function play():void {
			if (!_positionInterval) {
				_positionInterval = setInterval(positionHandler, 100);
			}
			_stream.resume();
			super.play();
		}


		/** Interval for the position progress **/
		protected function positionHandler():void {
			if (!_bandwidthChecked && _stream.bytesLoaded > 0) {
				_bandwidthChecked = true;
				setTimeout(checkBandwidth, _bandwidthTimeout, _stream.bytesLoaded);
			}
			
			var _streamTime:Number = Math.min(_stream.time, item.duration);
			var bufferPercent:Number = _stream.bytesLoaded / _stream.bytesTotal * 100;
			var bufferTime:Number = _stream.bufferTime < (item.duration - _streamTime) ? _stream.bufferTime : Math.floor(Math.abs(item.duration - _streamTime));
			var bufferFill:Number = bufferTime == 0 ? 100 : Math.floor(_stream.bufferLength / bufferTime * 100);

			
			if (bufferFill < 25 && state == PlayerState.PLAYING) {
				_bufferFull = false;
				_stream.pause();
				setState(PlayerState.BUFFERING);
			} else if (bufferFill > 95 && state == PlayerState.BUFFERING && _bufferFull == false && bufferTime > 0) {
				_bufferFull = true;
				sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_BUFFER_FULL);
			}

			if (!_bufferingComplete) {
				if (bufferPercent == 100 && _bufferingComplete == false) {
					_bufferingComplete = true;
				}
				sendBufferEvent(bufferPercent);
			}

			if (state != PlayerState.PLAYING) {
				return;
			}

			_position = Math.round(_streamTime * 10) / 10;
			
			if (position < item.duration) 
			{
				if (position >= 0) 
				{
					sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_TIME, {position: position, duration: item.duration});
				}
			} 
			else if (item.duration > 0) 
			{
				complete();
			}
		}

		private function checkBandwidth(lastLoaded:Number):void {
			var currentLoaded:Number = _stream.bytesLoaded;
			var bandwidth:Number = Math.ceil((currentLoaded - lastLoaded) / 1024) * 8 / (_bandwidthTimeout / 1000);
			if (currentLoaded < _stream.bytesTotal) {
				if (bandwidth > 0) {
					config.bandwidth = bandwidth;
					var obj:Object = {bandwidth:bandwidth};
					if (item.duration > 0) {
						obj.bitrate = Math.ceil(_stream.bytesTotal / 1024 * 8 / item.duration);
					}
					sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, {metadata: obj});
				}
				if (_bandwidthSwitch) {
					_bandwidthSwitch = false;
					if (item.currentLevel != item.getLevel(config.bandwidth, config.width)) {
						load(item);
						return;
					}
				}
			}
			setTimeout(checkBandwidth, _bandwidthTimeout, currentLoaded);
		}

		/** Seek to a new position. **/
		override public function seek(pos:Number):void 
		{
			trace("VideoSeek不能拖");
			seekStream(pos);
		}
		
		private function seekStream(pos:Number, ply:Boolean=true):void 
		{
			var bufferLength:Number = _stream.bytesLoaded / _stream.bytesTotal * item.duration;
			if (pos <= bufferLength) 
			{
				super.seek(pos);
				clearInterval(_positionInterval);
				_positionInterval = undefined;
				_stream.seek(position);
				if (ply)
				{
					play();
				}
			}
		}


		/** Receive NetStream status updates. **/
		protected function statusHandler(evt:NetStatusEvent):void {
			switch (evt.info.code) {
				case "NetStream.Play.Stop":
					complete();
					break;
				case "NetStream.Play.StreamNotFound":
					error('Video not found or access denied: ' + item.file);
					break;
			}
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, {metadata: {status: evt.info.code}});
		}


		/** Destroy the video. **/
		override public function stop():void {
			if (_stream.bytesLoaded < _stream.bytesTotal) {
				_stream.close();
			} else {
				_stream.pause();
				_stream.seek(0);
			}
			clearInterval(_positionInterval);
			_positionInterval = undefined;
			super.stop();
		}


		/** Set the volume level. **/
		override public function setVolume(vol:Number):void {
			streamVolume(vol);			
			super.setVolume(vol);
		}
		
		/** Set the stream's volume, without sending a volume event **/
		protected function streamVolume(level:Number):void {
			_transformer.volume = level / 100;
			if (_stream) {
				_stream.soundTransform = _transformer;
			}
		}
	}
}
