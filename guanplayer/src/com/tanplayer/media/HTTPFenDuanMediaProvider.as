/**
 * Manages playback of http streaming flv.
 **/
package com.tanplayer.media 
{
	import com.tanplayer.events.MediaEvent;
	import com.longtailvideo.jwplayer.model.PlayerParameter;
	import com.tanplayer.model.Model;
	import com.tanplayer.model.PlayerConfig;
	import com.tanplayer.model.PlaylistItem;
	import com.tanplayer.player.Player;
	import com.tanplayer.player.PlayerState;
	import com.tanplayer.utils.NetClient;
	import com.tanplayer.utils.RootReference;
	
	import flash.display.StageDisplayState;
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.utils.*;
	
	
	public class HTTPFenDuanMediaProvider extends MediaProvider 
	{
		/** NetConnection object for setup of the video stream. **/
		protected var _connection:NetConnection;
		/** NetStream instance that handles the stream IO. **/
		protected var currentPlayNetStream:NetStream;
		protected var stream2:NetStream;
		/** Video object to be instantiated. **/
		protected var _video:Video;
		/** Sound control object. **/
		protected var _transformer:SoundTransform;
		/** ID for the _position interval. **/
		protected var _positionInterval:uint;
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
		public function HTTPFenDuanMediaProvider() 
		{
			super('http');
		}
		
		private var urlarr:Array=[];
		
		private var stream1:NetStream;
		
		public override function initializeMediaProvider(cfg:PlayerConfig):void 
		{
			super.initializeMediaProvider(cfg);
			
			_connection = new NetConnection();
			_connection.connect(null);
			
			stream1 = new NetStream(_connection);
			stream1.checkPolicyFile = true;
			stream1.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler11);
			stream1.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			stream1.addEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler);
			stream1.bufferTime = config.bufferlength;
			stream1.client = new NetClient(this);
			stream1.client.name ="111";
			
			stream2 = new NetStream(_connection);
			stream2.checkPolicyFile = true;
			stream2.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler22);
			stream2.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			stream2.addEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler);
			stream2.bufferTime = config.bufferlength;
			stream2.client = new NetClient(this);
			stream2.client.name ="222";
			
			
			_transformer = new SoundTransform();
			_video = new Video(320, 240);
			_video.smoothing = config.smoothing;
			_video.attachNetStream(stream1);
			//初始化currentPlayNetStream
			currentPlayNetStream=stream1;
			trace("时间数组"+PlayerParameter.fileArr);
			urlarr=PlayerParameter.fileArr;
			//组装时间数组
		}
		
		private var playtimeArr:Array=[];
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
		protected function errorHandler(evt:ErrorEvent):void 
		{
			error(evt.text);
		}
		
		/** Bandwidth is checked as long the stream hasn't completed loading. **/
		private function checkBandwidth(lastLoaded:Number):void 
		{
			var currentLoaded:Number = currentPlayNetStream.bytesLoaded;
			var bandwidth:Number = Math.ceil((currentLoaded - lastLoaded) / 1024) * 8 / (_bandwidthDelay / 1000);
			
			if (currentLoaded < currentPlayNetStream.bytesTotal) 
			{
				if (bandwidth > 0) 
				{
					config.bandwidth = bandwidth;
					var obj:Object = {bandwidth:bandwidth};
					if (item.duration > 0) 
					{
						obj.bitrate = Math.ceil(currentPlayNetStream.bytesTotal / 1024 * 8 / item.duration);
					}
					sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, {metadata: obj});
				}
				if (_bandwidthSwitch) 
				{
					_bandwidthSwitch = false;
					_bandwidthChecked = false;
					if (item.currentLevel != item.getLevel(config.bandwidth, config.width)) 
					{
						load(item);
						return;
					}
				}
				clearTimeout(_bandwidthTimeout);
				_bandwidthTimeout = setTimeout(checkBandwidth, _bandwidthDelay, currentLoaded);
			}
		}
		
		
		/*	protected function getOffset2(pos:Number, tme:Boolean=false):Number 
		{
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
		}*/
		/** Return a keyframe byteoffset or timeoffset. **/
		protected function getOffset(pos:Number, tme:Boolean=false):Number 
		{
			if (!_keyframes) 
			{
				return 0;
			}
			for (var i:Number = 0; i < _keyframes.times.length - 1; i++) 
			{
				if (_keyframes.times[i] <= pos && _keyframes.times[i + 1] >= pos) 
				{
					break;
				}
			}
			if (tme == true)
			{
				return _keyframes.times[i];
			} 
			else 
			{
				return _keyframes.filepositions[i];
			}
		}
		
		
		/** Create the video request URL. **/
		protected function getURL():String 
		{
			var url:String = item.file;
			
			var off:Number = _byteoffset;
			if (getConfigProperty('startparam') as String) {
				_startparam = getConfigProperty('startparam');
			}
			if (item.streamer) {
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
		
		public var flvcont:int=0;
		/** Load content. 
		 *
		 *
		 **/
		//开始播放
		override public function load(itm:PlaylistItem):void 
		{
			_item = itm;
			_position = _timeoffset;
			_bufferFull = false;
			_bufferingComplete = false;
			
			_bandwidthSwitch = true;
			
			if(item.levels.length > 0) 
			{ 
				item.setLevel(item.getLevel(config.bandwidth, config.width));
			}
			
			if (currentPlayNetStream.bytesLoaded + _byteoffset < currentPlayNetStream.bytesTotal) 
			{
				currentPlayNetStream.close();
			}
			
			media = _video;
			//=====================开始播放第一段正常模式========================
			flvcont = PlayerParameter.fileArr.length-1;
			
		  var playUrl:String = urlarr[flvcont];//+"?"+Math.round(Math.random()*1000); 
			
			
			if(playUrl.lastIndexOf("mp4")!=-1)
			{
				_mp4 = true;
			}
			else
			{
				_mp4 = false;
			}
			
			trace("currentPlayNetStream is stream1"+playUrl);
			currentLoadNetStream = currentPlayNetStream;
			currentPlayNetStream.play(playUrl);
			
			//本段起始时间
			NetStreamStartTime = PlayerParameter.filetimeArr[flvcont];
			//开始帧听预加载
			addEventListener(Event.ENTER_FRAME,NetStreamTimeEnterFrameHandler);
			
			//================================================
			clearInterval(_positionInterval);
			_positionInterval = setInterval(positionInterval, 100);
			
			sendMediaEvent(MediaEvent.LOADEDJWPLAYER_MEDIA);
			setState(PlayerState.BUFFERING);
			sendBufferEvent(0, 0);
			streamVolume(300);//初始化音量
		}
		
		/** Get metadata information from netstream class. **/
		public function onClientData(dat:Object):void 
		{
			if (!dat) return;
			//trace("uidfef::"+dat['seekpoints']);
			if (dat.width) 
			{
				//trace(dat.width);
				
				_video.width = dat.width;
				_video.height = dat.height;
				//sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, );
				sendMediaEvent(MediaEvent.JWPLAYER_DataWidthHeight,{metadata: dat});
				
				if(RootReference.stage.displayState == StageDisplayState.FULL_SCREEN)
				{
					sendMediaEvent(MediaEvent.JWPLAYER_Seek_Ukd);
				}
				else
				{
					if(RootReference.stage.displayState == StageDisplayState.FULL_SCREEN)
					{
						
					}
					else
					{
						resize(_width, _height);
					}
					
				}
			}
			
			if (dat['duration'] && item.duration <= 0)
			{
				//不是每一段都会触发这个 。
				item.duration = dat['duration'];
			}
			
			//trace("item.duration:::"+item.duration);
			//trace("dat['type']:::"+dat['type']);
			//trace("_meta::"+_meta);
			if (dat['type'] == 'metadata' && !_meta)
			{
				_meta = true;
				if (dat['seekpoints']) 
				{
					_mp4 = true;
					_keyframes = convertSeekpoints(dat['seekpoints']);
				} 
				else
				{
					_mp4 = false;
					_keyframes = dat['keyframes'];
					//trace("_keyframes.filepositions:::"+_keyframes.filepositions);
				}
				if (item.start > 0)
				{
					seek(item.start);
				}
			}
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, {metadata: dat});
			
			if(getClientData=="seek")
			{
				
				getClientData = "end";
			}
		}
		
		private var getClientData:String ="";
		/** Pause playback. **/
		override public function pause():void 
		{
			currentPlayNetStream.pause();
			
			super.pause();//这个暂停改变显示
		}
		
		
		/** Resume playing. **/
		override public function play():void 
		{
			currentPlayNetStream.resume();
			trace("resumeresumepuasdfff");
			if (!_positionInterval) 
			{
				_positionInterval = setInterval(positionInterval, 100);
			}
			
			super.play();//这个改变画面
		}
		
		public function StopMediaNetStream():void
		{
			try
			{
				currentPlayNetStream.close();
			}
			catch (e:Error)
			{
				
			}
		}
		
		//每隔1秒刷新时间
		/** Interval for the position progress **/
		protected function positionInterval():void 
		{
			_position = Math.round(currentPlayNetStream.time * 10) / 10;
			var percentoffset:Number;
			//trace("1秒刷新时间");
			
			if (_mp4) 
			{
				_position+=mp4off;
				//trace("NetStreamStartTime:::"+NetStreamStartTime);
				//trace(_position);
				//_position+=NetStreamStartTime+_position;
				//trace("_positionmp4"+_position);
			}
			
			var bufferPercent:Number;
			var bufferFill:Number;
			
			if (item.duration>0) 
			{
				percentoffset =  Math.round(_timeoffset /  item.duration * 100);
				
				bufferPercent = (currentLoadNetStream.bytesLoaded / currentLoadNetStream.bytesTotal) * (1 - _timeoffset / item.duration) * 100;
				//trace("bufferPercentxxxxxxxxxxxx"+bufferPercent);
				
				var bufferTime:Number = currentPlayNetStream.bufferTime < (item.duration - position) ? currentPlayNetStream.bufferTime : Math.round(item.duration - position);
				bufferFill = currentPlayNetStream.bufferTime == 0 ? 0 : Math.ceil(currentPlayNetStream.bufferLength / bufferTime * 100);
			} 
			else 
			{
				percentoffset = 0;
				bufferPercent = 0;
				bufferFill = currentPlayNetStream.bufferLength/currentPlayNetStream.bufferTime * 100;
			}
			
			if (!_bandwidthChecked && currentPlayNetStream.bytesLoaded > 0 && currentPlayNetStream.bytesLoaded < currentPlayNetStream.bytesTotal) {
				_bandwidthChecked = true;
				clearTimeout(_bandwidthTimeout);
				_bandwidthTimeout = setTimeout(checkBandwidth, _bandwidthDelay, currentPlayNetStream.bytesLoaded);
			}
			
			if (bufferFill < 25 && state == PlayerState.PLAYING) {
				_bufferFull = false;
				currentPlayNetStream.pause();
				setState(PlayerState.BUFFERING);
			} else if (bufferFill > 95 && state == PlayerState.BUFFERING && _bufferFull == false) {
				_bufferFull = true;
				sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_BUFFER_FULL);
			}
			
			if (!_bufferingComplete) 
			{
				//				if ((bufferPercent + percentoffset) == 100 && _bufferingComplete == false) {
				//					_bufferingComplete = true;
				//				}
				//trace("bufferPercent:::"+bufferPercent);
				if(bufferPercent>=100)
				{
					PlayerParameter.duanLoadEnd = true;
				}
				else
				{
					PlayerParameter.duanLoadEnd = false;
				}
				sendBufferEvent(bufferPercent, _timeoffset);
			}
			
			if(state != PlayerState.PLAYING) 
			{
				return;
			}
			//trace("_position"+_position);
			//trace("item.duration"+item.duration);
			if (_position < item.duration) 
			{
				if (_position >= 0) 
				{
					//每时每刻发送
					if(this.seeking==true)
					{
						_position=seekPos;
					}
					else
					{
						sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_TIME, {position: _position, duration: item.duration, offset: _timeoffset});
						//trace(Model._playingTime);
						if(Model._playingTime>=PlayerParameter.videoTotaldur)
						{
							trace("播放结束");
							complete();
						}
					}
				}
			}
			
			//已经下载
			var loadnum:Number=(currentLoadNetStream.bytesLoaded/currentLoadNetStream.bytesTotal);
			//trace("loadnum::"+loadnum);
			sendMediaEvent(MediaEvent.LOADEDJWPLAYER_MEDIA,{duration:loadnum});
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
		public var NetStreamStartTime:Number=0;//当前播放的视频开始时间由外部传入
		
		private function CheckDuan(posx:Number):int
		{
			var len:int = PlayerParameter.filetimeArr.length;
			
			for(var i:int=0;i<len;i++)
			{
				if(posx>=PlayerParameter.filetimeArr[i])
				{
					NetStreamStartTime = PlayerParameter.filetimeArr[i];
					trace("NetStreamStartTime:::"+NetStreamStartTime);
					flvcont= i;
					return i;
				}
			}
			
			return 0;
		}
		
		private var seekpoint:Number;
		private var playflvduan:int;//要播放的分段flv
		
		public var seekPos:Number;
		public var seeking:Boolean = false;
		
		/** Seek to a specific second. **/
		//快进
		override public function seek(pos:Number):void //搜索
		{
			PlayerParameter._userPause=true;//用户seek
			seeking = true;
			seekPos = pos;
			//========用户主动seek不管他是怎么样分段播，给currentPlayNetStream跳转就行=====================
			this.removeEventListener(Event.ENTER_FRAME,NetStreamTimeEnterFrameHandler);
			//trace("要到达的时间点pos:::"+pos);
			playflvduan = CheckDuan(pos);
			trace("本段视频起始时间点NetStreamStartTime:::"+NetStreamStartTime);
			seekpoint=pos-NetStreamStartTime;
		    trace("本段视频seek时间:::"+seekpoint);
			var off:Number = getOffset(seekpoint);
			//trace("off:::"+off);
			//trace("currentPlayNetStream.bytesLoaded:::"+currentPlayNetStream.bytesLoaded);
			
			seekPlayUrl =urlarr[playflvduan];
			
			if(seekPlayUrl.lastIndexOf("mp4")!=-1)
			{
				_mp4 = true;
			}
			else
			{
				_mp4 = false;
			}
			
			_meta = false;
			
			currentLoadNetStream =currentPlayNetStream;
			//seek分段模式先尝试搜索已经下载的，如果没有搜到在notfind中处理
		    
		
			
			currentPlayNetStream.play(seekPlayUrl);
			currentPlayNetStream.seek(getOffset(seekpoint, true));
			
			
			sendMediaEvent(MediaEvent.LOADEDJWPLAYER_seekkkkkkkk);
			
			
			loadBaifenbi =0.1;
			//搜索开始帧听预加载
			this.addEventListener(Event.ENTER_FRAME,NetStreamTimeEnterFrameHandler);
		}
		
		private var seekPlayUrl:String;
		
		/** Seek to a specific second. **/
		/*		override public function seek(pos:Number):void 
		{
		var off:Number = getOffset(pos);
		super.seek(pos);
		clearInterval(_positionInterval);
		_positionInterval = undefined;
		if (off < _byteoffset || off >= _byteoffset + _stream.bytesLoaded) {
		_timeoffset = _position = getOffset(pos, true);
		_byteoffset = off;
		load(item);
		} else {
		if (state == PlayerState.PAUSED) {
		_stream.resume();
		}
		if (_mp4) {
		_stream.seek(getOffset(_position - _timeoffset, true));
		} else {
		_stream.seek(getOffset(_position, true));
		}
		play();
		}
		}*/
		
		public var mp4off:Number=0;
		//private var _seekCount:int=0;//搜索计数器
		private var recordLastTime:Number;
		
		private function SeekPlayNetstream():void
		{
			if(isNaN(recordLastTime))
			{
				recordLastTime = getTimer();
			}
			else if((getTimer()-recordLastTime)<3)
			{
				this.stop();
			}
			else
			{
				recordLastTime = getTimer();
			}
			
			var off:Number = getOffset(this.seekpoint,_mp4);
			trace("搜索的关键帧"+off);
			var playurl:String=urlarr[playflvduan]+"?start="+off;//+"?"+Math.round(Math.random()*1000);
			
			if(_mp4)
			{
				mp4off = off;
			}
			trace("playurl:::"+playurl);
			currentPlayNetStream.play(playurl);
			
			
			PlayerParameter.FenduanCurrentNetStream=currentPlayNetStream; 
			PlayerParameter._userPause=true;//用户seek
			
			super.play();//播放更新画面
			
			loadBaifenbi =0.1;
			//搜索开始帧听预加载
			this.addEventListener(Event.ENTER_FRAME,NetStreamTimeEnterFrameHandler);
		}
		
		private var currentLoadNetStream:NetStream;
		
		private var loadBaifenbi:Number=0.1;
		private function NetStreamTimeEnterFrameHandler(e:Event):void
		{
			if (_mp4) 
			{
				/*	if(_position>currentPlayNetStream.client.flvduration*0.6)
				{
				if(flvcont==1)
				{
				
				return;
				}
				
				var dnetstream:NetStream;
				if(currentPlayNetStream.client.name=="111")
				{
				dnetstream =stream2; 
				}
				else if(currentPlayNetStream.client.name=="222")
				{
				dnetstream =stream1; 
				}
				
				var plyurl:String = urlarr[(flvcont-1)];
				
				if(plyurl.lastIndexOf("mp4")!=-1)
				{
				dnetstream.client.videoType="mp4";
				}
				else
				{
				dnetstream.client.videoType="flv";
				}
				
				
				dnetstream.play(urlarr[(flvcont-1)]);
				dnetstream.pause();
				trace("nextNetStream已经开始预加载下一段mp4");
				//trace("_position:::"+_position);
				this.removeEventListener(Event.ENTER_FRAME,NetStreamTimeEnterFrameHandler);
				}*/
				
			}
			else//flv
			{
				//60%开始加载
				//trace("flvduration:::"+currentPlayNetStream.client.flvduration);
				if(currentPlayNetStream.time>currentPlayNetStream.client.flvduration*loadBaifenbi)
				{
					_bufferingComplete = false;
					if(flvcont<=0)
					{
						trace("flv最后一段视频");
						this.removeEventListener(Event.ENTER_FRAME,NetStreamTimeEnterFrameHandler);
						
						return;
					}
					
					var dnetstream2:NetStream;
					
					if(currentPlayNetStream.client.name=="111")
					{
						dnetstream2 =stream2; 
					}
					else if(currentPlayNetStream.client.name=="222")
					{
						dnetstream2 =stream1; 
					}
					
					trace("flvcont;;"+flvcont);
					var plyurl2:String;
					
					if(flvcont<=0)//已经是最后一段
					{
						plyurl2= urlarr[flvcont];
					}
					else
					{
						plyurl2= urlarr[(flvcont-1)];
					}
					
					
					if(plyurl2.lastIndexOf("mp4")!=-1)
					{
						dnetstream2.client.videoType="mp4";
					}
					else
					{
						dnetstream2.client.videoType="flv";
					}
					
					currentLoadNetStream = dnetstream2;
					//trace("urldddxxxxxxxx::"+urlarr[(flvcont-1)]);
					var pld:String =plyurl2;//+"?"+Math.round(Math.random()*1000);
					dnetstream2.play(pld);
					dnetstream2.seek(0);
					dnetstream2.pause();
					
					if(flvcont<=0)//已经是最后一段
					{
						flvcont=0;
					}
					else
					{
						flvcont--;
					}
					
					trace("nextNetStream已经开始预加载"+flvcont+"下一段flv");
					this.removeEventListener(Event.ENTER_FRAME,NetStreamTimeEnterFrameHandler);
				}
			}
			
		}
		
		public var volumecur:Number=300;
		
		private function StopFlush11():void
		{
			trace("AssetURL._userPause：：； "+PlayerParameter._userPause);
			this.removeEventListener(Event.ENTER_FRAME,NetStreamTimeEnterFrameHandler);
			
			//stream1.dispose();
			//stream1.close();
			
			if(PlayerParameter.filetimeArr.length==1)
			{
				(RootReference._player as Player).view._componentsLayer.visible =true;
				if((RootReference._player as Player).view._logo) (RootReference._player as Player).view._logo.visible = false;
			}
			trace("flvcont----------"+flvcont);
			if(flvcont==0)
			{
				NetStreamStartTime = PlayerParameter.filetimeArr[0];
			}
			else
			{
				NetStreamStartTime = PlayerParameter.filetimeArr[flvcont];
			}
			
			//trace("flvcondt:::"+flvcont-1);
			trace("NetStreamStartTime111"+NetStreamStartTime);
			mp4off =0;
			_position=NetStreamStartTime+_position;
			
			_video.attachNetStream(null);
			_video.attachNetStream(stream2);
			
			trace("流1关闭 流2恢复");
			stream2.resume();
			var stran:SoundTransform = new SoundTransform();
			stran.volume =volumecur/100;
			trace("stran.volume:::"+stran.volume);
			stream2.soundTransform =stran;
			trace("currentPlayNetStream is stream2");
			
			if(stream2.client.videoType=="mp4")
			{
				this._mp4 = true;
			}
			trace("stream2预加载的开始播放");
			currentPlayNetStream = stream2;
			this.addEventListener(Event.ENTER_FRAME,NetStreamTimeEnterFrameHandler);
			
		}
		
		private function StopFlush22():void
		{
		    this.removeEventListener(Event.ENTER_FRAME,NetStreamTimeEnterFrameHandler);
			trace("22222222222");
		//	stream2.dispose();
		//	stream2.close();
			
			if(flvcont==0)
			{
				NetStreamStartTime = PlayerParameter.filetimeArr[0];
			}
			else
			{
				NetStreamStartTime = PlayerParameter.filetimeArr[flvcont];
			}
			trace("NetStreamStartTime:::"+NetStreamStartTime);
			
			mp4off =0;
			_position=NetStreamStartTime+_position;
			_video.attachNetStream(null);
			_video.attachNetStream(stream1);
			
			trace("流2关闭 流1恢复");
			stream1.resume();
			
			var stran:SoundTransform = new SoundTransform();
			stran.volume =volumecur/100;
			
			trace("stran.volume222:::"+stran.volume);
			stream1.soundTransform =stran;
			
			trace("currentPlayNetStream is stream11");
			if(stream1.client.videoType=="mp4")
			{
				this._mp4 = true;
			}
			
			currentPlayNetStream = stream1;
			this.addEventListener(Event.ENTER_FRAME,NetStreamTimeEnterFrameHandler);
		
		}
		
		
		
		private function netStatusHandler11(event:NetStatusEvent):void 
		{
			trace("event.info.code111:::"+event.info.code);
			
			switch (event.info.code) 
			{
				case "NetStream.Play.Stop" :
					
					StopFlush11();
					
					break;
				
				case "NetStream.Pause.Notify" :
					
					trace("buffertime11"+(event.target as NetStream).bufferTime);
					trace("bufferTimeMax11"+(event.target as NetStream).bufferTimeMax);
					
					
					if((event.target as NetStream).bytesLoaded==(event.target as NetStream).bytesTotal)
					{
						trace("StopFlush11StopFlush11v");
						if(PlayerParameter._userPause ==false)//不是用户主动暂停 这里目前不明原因收不到stop
						{                              //事件日后处理
							StopFlush11();
						}
						
					}
					
					break;
				
				case "NetStream.Seek.InvalidTime":
					
					stream1.seek(event.info.details); 
					trace("NetStream.Seek.InvalidTime111");
					break;
				
				
				case "NetStream.Unpause.Notify":
					this.seeking = false;
					RootReference._seekuser = false;
					trace("seek完了");
					PlayerParameter._userPause =false;
					break;
				
				case "NetStream.Seek.Notify":
					this.seeking = false;
					RootReference._seekuser = false;
					trace("用户主动seek完了");
					PlayerParameter._userPause =false;
					break;
				case "NetStream.Seek.Complete":
					this.seeking = false;
					RootReference._seekuser = false;
					PlayerParameter._userPause =false;
					break;
				
				case "NetStream.Video.DimensionChange":
					//seekend = true;
					trace("搜索完了");
					this.seeking = false;
					RootReference._seekuser = false;
					PlayerParameter._userPause =false;
					break;
				
				case "NetStream.Play.StreamNotFound":
					
				    trace("seek的是未加载的");
					
					SeekPlayNetstream();
					
					break;
			}
		}
		
		private function netStatusHandler22(event:NetStatusEvent):void 
		{
			trace("event.info.code222"+event.info.code)
			switch (event.info.code) 
			{
				case "NetStream.Play.Stop" :
					
					StopFlush22();
					
					break;
				
				case "NetStream.Pause.Notify" :
					
					if((event.target as NetStream).bytesLoaded==(event.target as NetStream).bytesTotal)
					{
						if(PlayerParameter._userPause ==false)//不是用户主动暂停 这里目前不明原因收不到stop
						{//事件日后处理
							StopFlush22();
						}
					}
					
					break;
				
				case "NetStream.Seek.InvalidTime":
				{ 
					stream2.seek(event.info.details); 
					trace("NetStream.Seek.InvalidTime222");
				} 
					
				case "NetStream.Seek.Notify":
					this.seeking = false;
					RootReference._seekuser = false;
					trace("用户主动seek完了");
					PlayerParameter._userPause =false;
					break;
				
				case "NetStream.Seek.Complete":
					trace("搜索完了");
					this.seeking = false;
					RootReference._seekuser = false;
					PlayerParameter._userPause =false;
					break;
				case "NetStream.Video.DimensionChange":
					//seekend = true;
					trace("搜索完了");
					seeking = false;
					RootReference._seekuser = false;
					PlayerParameter._userPause =false;
					break;
				
				case "NetStream.Unpause.Notify":
					this.seeking = false;
					RootReference._seekuser = false;
					trace("seek完了");
					PlayerParameter._userPause =false;
					break;
				case "NetStream.Play.StreamNotFound":
					
					trace("seek的是未加载的");
					SeekPlayNetstream();
					break;
			}
		}
		
		/** Receive NetStream status updates. **/
		/*		protected function statusHandler(evt:NetStatusEvent):void {
		switch (evt.info.code) {
		case "NetStream.Play.Stop":
		if (state != PlayerState.BUFFERING) {
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
		}*/
		
		
		/** Destroy the HTTP stream. **/
		override public function stop():void 
		{
			if (currentPlayNetStream.bytesLoaded + _byteoffset < currentPlayNetStream.bytesTotal) 
			{
				currentPlayNetStream.close();
			} 
			else 
			{
				currentPlayNetStream.pause();
			}
			clearInterval(_positionInterval);
			_positionInterval = undefined;
			_position = _byteoffset = _timeoffset = 0;
			_keyframes = undefined;
			_bandwidthChecked = false;
			_meta = false;
			super.stop();
		}
		
		
		/** Set the volume level. **/
		override public function setVolume(vol:Number):void 
		{
			streamVolume(vol);
			super.setVolume(vol);
		}
		
		/** Set the stream's volume, without sending a volume event **/
		protected function streamVolume(level:Number):void 
		{
			_transformer.volume = level / 100;
			
			trace("levellevellevellevel:::"+level);
			
			if (currentPlayNetStream) 
			{
				currentPlayNetStream.soundTransform = _transformer;
			}
		}
		
	}
}