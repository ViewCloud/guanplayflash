package com.tanplayer.controller 
{
	
	import com.adobe.serialization.json.JSON;
	import com.events.ModelStates;
	import com.tanplayer.components.ControlbarComponentV4;
	import com.tanplayer.components.DisplayComponent;
	import com.tanplayer.events.GlobalEventDispatcher;
	import com.tanplayer.events.MediaEvent;
	import com.tanplayer.events.PlayerEvent;
	import com.tanplayer.events.PlaylistEvent;
	import com.tanplayer.events.ViewEvent;
	import com.tanplayer.media.HTTPMediaProvider;
	import com.tanplayer.model.Model;
	import com.tanplayer.model.PlaylistItem;
	import com.tanplayer.parsers.HttpGetJsonController;
	import com.tanplayer.parsers.JWParser;
	import com.tanplayer.player.IPlayer;
	import com.tanplayer.player.JavascriptAPI;
	import com.tanplayer.player.PlayerState;
	import com.tanplayer.plugins.IPlugin;
	import com.tanplayer.utils.Configger;
	import com.tanplayer.utils.Logger;
	import com.tanplayer.utils.RootReference;
	import com.tanplayer.utils.TanBandwidthCheck;
	import com.tanplayer.view.View;
	
	import flash.display.MovieClip;
	import flash.display3D.IndexBuffer3D;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import org.flowplayer.util.Arrange;
	
	/**
	 * Sent when the player has been initialized and skins and plugins have been successfully loaded.
	 *
	 * @eventType com.longtailvideo.jwplayer.events.PlayerEvent.JWPLAYER_READY
	 */
	[Event(name="jwplayerReady", type = "com.tanplayer.events.PlayerEvent")]
	
	/**
	 * Sent when the player has entered the ERROR state
	 *
	 * @eventType com.longtailvideo.jwplayer.events.PlayerEvent.JWPLAYER_ERROR
	 */
	[Event(name="jwplayerError", type = "com.tanplayer.events.PlayerEvent")]
	
	/**
	 * The Controller is responsible for handling Model / View events and calling the appropriate responders
	 *
	 * @author Pablo Schklowsky
	 */
	public class Controller extends GlobalEventDispatcher 
	{
		
		/** MVC References **/
		protected var _player:IPlayer;
		protected var _model:Model;
		protected var _view:View;
		
		/** Setup completed **/
		protected var _setupComplete:Boolean = false;
		/** Setup finalized **/
		protected var _setupFinalized:Boolean = false;
		/** Whether to autostart on unlock **/
		protected var _unlockAutostart:Boolean = false;
		/** Whether to resume on unlock **/
		protected var _lockingResume:Boolean = false;
		/** Lock manager **/
		protected var _lockManager:LockManager;
		/** Load after unlock - My favorite variable ever **/
		protected var _unlockAndLoad:Boolean;
		
		
		/** A list with legacy CDN classes that are now redirected to buit-in ones. **/
		protected var cdns:Object = 
			{
				bitgravity:{'http.startparam':'starttime', provider:'http'},
				edgecast:{'http.startparam':'ec_seek', provider:'http'},
				flvseek:{'http.startparam':'fs', provider:'http'},
				highwinds:{'rtmp.loadbalance':true, provider:'rtmp'},
				lighttpd:{'http.startparam':'start', provider:'http'},
				vdox:{'rtmp.loadbalance':true, provider:'rtmp'}
			};
		
		/** Reference to a PlaylistItem which has triggered an external MediaProvider load **/
		protected var _delayedItem:PlaylistItem;
		/** Loader for external MediaProviders **/
		protected var _mediaLoader:MediaProviderLoader;
		
		public function get model():Model
		{
			return _model;
		}
		
		public function Controller(player:IPlayer, model:Model, view:View) 
		{
			_player = player;
			_model = model;
			_view = view;
			_lockManager = new LockManager();
			
			ReportPlayerAction(1);
			
		}
		
		public function get imdView():View
		{
			return _view;
		}
		
		/**
		 * Begin player setup
		 * @param readyConfig If a PlayerConfig object is already available, use it to configure the player.
		 * Otherwise, load the config from XML / flashvars.
		 */
		public function setupPlayer():void 
		{
			var setup:PlayerSetup = new PlayerSetup(_player, _model, _view);
			
			setup.addEventListener(Event.COMPLETE, setupComplete);
			setup.addEventListener(ErrorEvent.ERROR, setupError);
			
			setup.setupPlayer();
			
			tbwt=new TanBandwidthCheck();
			
		}
		
		private var _recDrag:Rectangle;//57=volumetrack.width-_volumeSlide.audioThumb.width
		
		public function ChangeCurrentOnLineNum(str:String):void
		{
			_view.ChangeCurrentOnLineNum(str);
		}
		
		protected function addViewListeners():void 
		{
			//_view.addEventListener(ViewEvent.JWPLAYER_INTERVAL, IntervalHandler);
			_view.addEventListener(ViewEvent.JWPLAYER_VIEW_PLAY, playHandler);
			_view.addEventListener(ViewEvent.JWPLAYER_VIEW_PAUSE, pauseHandler);
			_view.addEventListener(ViewEvent.JWPLAYER_VIEW_STOP, stopHandler);
			_view.addEventListener(ViewEvent.JWPLAYER_VIEW_NEXT, nextHandler);
			_view.addEventListener(ViewEvent.JWPLAYER_VIEW_PREV, prevHandler);
			_view.addEventListener(ViewEvent.JWPLAYER_VIEW_SEEK, seekHandler);
			_view.addEventListener(ViewEvent.JWPLAYER_VIEW_MUTE, muteHandler);
			//_view.addEventListener(ViewEvent.JWPLAYER_VIEW_VOLUME, volumeHandler);
			
			_view.addEventListener(ViewEvent.JWPLAYER_VIEW_FULLSCREEN, fullscreenHandler);
			_view.addEventListener(ViewEvent.JWPLAYER_VIEW_LOAD, loadHandler);
			_view.addEventListener(ViewEvent.JWPLAYER_VIEW_REDRAW, redrawHandler);
			
			_view.addEventListener(ViewEvent.IMD_CHANGE_STREAM,ChangeStreamHandler);
			
			_view.addEventListener(ViewEvent.DOUBLE_CLICK,DoubleClickHandler);
			
			_view.addEventListener(ViewEvent.JWPLAYER_RESIZE,JSResizeHandler);
		
			
			
			RootReference.stage.addEventListener(Event.MOUSE_LEAVE,LeaveSWFHandler);
			//控制显示面板
			RootReference.stage.addEventListener(MouseEvent.ROLL_OVER,SWFOverHandler,true);
			var thumby:Number=6;
			var _volumeSlide:MovieClip =(_view.components.controlbar as ControlbarComponentV4).getSkinComponent('imdVolumeslideIcon') as MovieClip;
			
			//拖动的矩形
			_recDrag= new Rectangle(0,thumby,_volumeSlide.volumetrack.width-_volumeSlide.audioThumb.width,0);//57=
			
			//拖动声音
			_volumeSlide.audioThumb.addEventListener(MouseEvent.MOUSE_DOWN,ThumbDown);
			_volumeSlide.addEventListener(MouseEvent.CLICK,VolumeClickHandler);
			_volumeSlide.buttonMode= true;
			//游标位置初始化
			_volumeSlide.audioThumb.x=_recDrag.width;//初始化音量为1_volumeSlide.audioThumb.width/2;//5是X偏移量 
			_volumeSlide.audioThumb.y=thumby;//5是Y偏移量 
			
			_volumeSlide.audioThumb.buttonMode= true;
			
			_volumeSlide.volumedone.width =_recDrag.width;//初始化音量为1
			
			//trace(int((1-(rec.width-(_volumeSlide.audioThumb.x-_volumeSlide.audioThumb.width/2))/rec.width)*100));
			
			setVolume(100); //初始化音量大小
			
			//码流切换面板
			_streamChangeBtn = ((_view.components.controlbar as ControlbarComponentV4).getSkinComponent("streamtxt") as MovieClip)
			
			_streamChangeBtn.addEventListener(MouseEvent.CLICK,AlertStreamBtnsHandler);
			_streamChangeBtn.buttonMode=true;
			
			tbwt.addEventListener(TanBandwidthCheck.SUCCESS, GetVideoJsonhandler);
			
		}
		
		private var tbwt:TanBandwidthCheck;
		
		public var _streamBtnsVisible:Boolean = false;
		
		public function LeaveSWFHandler(e:Event=null):void
		{
			
			if(_streamBtnsVisible)
			{
				(_view.components.display as DisplayComponent).clearDisplay();
				_streamBtnsVisible = false;
			}
			
			//TweenLite.to(_view.components.controlbar,1.5,{y:(_view._controlBarY+100)});
			
		}
		//显示码流切换
		private function AlertStreamBtnsHandler(e:MouseEvent):void
		{
			if(mediaArr.length==0) return;
			
			var displayComponent:DisplayComponent = _view.components.display as DisplayComponent;
			
			if(!_streamBtnsVisible)
			{
				displayComponent.SetStreamChangeNotice();
				_streamBtnsVisible = true;
			}
			else
			{
				displayComponent.clearDisplay();
				_streamBtnsVisible = false;
				
			}
		}
		
		public var _streamChangeBtn:MovieClip;
		//音量点击
		private function VolumeClickHandler(e:MouseEvent):void
		{
			if(e.target.name=="audioThumb")
			{
				return;
			}
			
			var _volumeSlide:MovieClip =(_view.components.controlbar as ControlbarComponentV4).getSkinComponent('imdVolumeslideIcon') as MovieClip;
			
			_volumeSlide.audioThumb.x=_volumeSlide.volumetrack.mouseX-5;//5是准确度微调
			
			SetMoveVolume();
		}
		
		private var _rectangle:Rectangle;//57=volumetrack.width-_volumeSlide.audioThumb.width
		
		private function JSResizeHandler(e:ViewEvent):void//JS控制场景大小发生更改
		{
			//ExternalInterface.call(CallJSFunction.SWITCHLAYOUTCALLBACKFUNCTIONNAME,CallJSFunction.SWITCHLAYOUTCALLBACKFUNCTIONNAME_PARAMETER,e.data);
		}
		
	
		private var retPortTimer:Timer;
		
		
		public var _swapTimeBack:Number=0;//万一服务器出错记录之前切换时间
		
		private function ChangeStreamHandler(e:ViewEvent):void
		{
			RootReference.ShowStreamsChange();
			stop();
			//var centerString:String = "/"+AssetURL._centerString+"/";
			//trace("Model._playingTime"+Model._playingTime);
			RootReference.currentStream=e.data;
			
			if(Model._playingTime==0)
			{
				Model._playingTime = _swapTimeBack;
			}
			else
			{
				_swapTimeBack = Model._playingTime;
			}
			
			var len:int=mediaArr.length;
			
			if(e.data =="高清")
			{
				//if(_streamChangeBtn.currentFrame==2)return;
			    for(var j:int=0;j<len;j++)
				{
					if(mediaArr[j].quality==e.data)
					{
						var videoUrl:String=mediaArr[j].urls[0];
						JavascriptAPI.ChangeKbpsHandler(videoUrl,Model._playingTime);
						return;
					}
				}
			}
			else if(e.data =="超清")
			{
				//if(_streamChangeBtn.currentFrame==2)return;
				
				_streamChangeBtn.gotoAndStop(2);
				
				for(var j1:int=0;j1<len;j1++)
				{
					if(mediaArr[j1].quality==e.data)
					{
						var videoUrl1:String=mediaArr[j1].urls[0];
						JavascriptAPI.ChangeKbpsHandler(videoUrl1,Model._playingTime);
						return;
					}
				}
			}
			else if(e.data =="标清")
			{
				///if(_streamChangeBtn.currentFrame==3)return;
				//_streamChangeBtn.gotoAndStop(3);
				
				for(var j2:int=0;j2<len;j2++)
				{
					if(mediaArr[j2].quality==e.data)
					{
						var videoUrl2:String=mediaArr[j2].urls[0];
						JavascriptAPI.ChangeKbpsHandler(videoUrl2,Model._playingTime);
						return;
					}
				}
			}
			
			else if(e.data =="流畅")
			{
				//if(_streamChangeBtn.currentFrame==3)return;
				//_streamChangeBtn.gotoAndStop(3);
				
				for(var j5:int=0;j5<len;j5++)
				{
					if(mediaArr[j5].quality==e.data)
					{
						var videoUrl5:String=mediaArr[j5].urls[0];
						JavascriptAPI.ChangeKbpsHandler(videoUrl5,Model._playingTime);
						return;
					}
				}
			}
			
			
			
			//trace("Model._playingTime"+Model._playingTime);
			//切换服务器
//			if(e.data =="shdianxinInitBtn")//初始化切换
//			{
//				JavascriptAPI.ChangeKbpsHandler((AssetURL._shaghaiDianxin+centerString+AssetURL._curentFile),Model._playingTime);
//				//this.pause();
//				AssetURL._currentService = AssetURL._shaghaiDianxin;
//			}
//			else if(e.data =="shdianxinBtn")
//			{
//				JavascriptAPI.ChangeKbpsHandler((AssetURL._shaghaiDianxin+centerString+AssetURL._curentFile),Model._playingTime);
//				AssetURL._currentService = AssetURL._shaghaiDianxin;
//			}
//			else if(e.data =="shliantongBtn")
//			{
//				JavascriptAPI.ChangeKbpsHandler((AssetURL._shaghaiLiantong+centerString+AssetURL._curentFile),Model._playingTime);
//				
//				AssetURL._currentService = AssetURL._shaghaiLiantong;
//			}
//			else if(e.data =="beijingliantongBtn")
//			{
//				JavascriptAPI.ChangeKbpsHandler((AssetURL._beijingLiantong+centerString+AssetURL._curentFile),Model._playingTime);
//				
//				AssetURL._currentService = AssetURL._beijingLiantong;
//			}
//			else if(e.data =="guangdongdianxinBtn")
//			{
//				JavascriptAPI.ChangeKbpsHandler((AssetURL._guangdongDianxin+centerString+AssetURL._curentFile),Model._playingTime);
//				
//				AssetURL._currentService = AssetURL._guangdongDianxin;
//			}
		}
		
		
		
		
		
		
		public function SWFOverHandler(e:MouseEvent=null):void
		{
			if(!(_view.components.controlbar as MovieClip).visible)
			{
				_view.components.controlbar.y = _view._controlBarY;
				(_view.components.controlbar as MovieClip).visible =true;//显示控制面板true show
			}
			else
			{
				//youtube声音TweenLite.to(_view.components.controlbar,0.5,{y:_view._controlBarY});
			}
			
			
		}
		
		private function OverTweenLiteEnd():void
		{
			
		}
		
		
		
		//private var _currentService:String ="rtmp://www.i-md.com/vod/";
		private var _gaoQin:String = "SP_HQ.flv";
		private var _biaoQin:String = "SP_MQ.flv";
		private var _liuChange:String = "SP_LQ.flv";
		private var _voiceAO:String = "SP_AO.flv";
		
		
		private function ServiecHandlerOne(e:MouseEvent):void//联通一
		{
			//			stop();
			//			_currentService ="rtmp://www.i-md.com/vod/";
			//			JavascriptAPI.ChangeKbpsHandler((_currentService+_gaoQin));
			//			_view._btnIMD.currentTxt.text = "当前联通一";
			//			_view._btnIMD.curretMode.text= "高清模式";
		}
		
		private function ServiecHandlerTwo(e:MouseEvent):void//联通二
		{
			//			stop();
			//			_currentService ="rtmp://211.95.121.252/vod/";
			//			JavascriptAPI.ChangeKbpsHandler((_currentService+_gaoQin));
			//			_view._btnIMD.currentTxt.text = "当前联通二";
			//			_view._btnIMD.curretMode.text= "高清模式";
		}
		
		private function ServiecHandlerThree(e:MouseEvent):void//电信
		{
			//			stop();
			//			_currentService ="rtmp://202.122.116.234/vod/";
			//			JavascriptAPI.ChangeKbpsHandler((_currentService+_gaoQin));
			//			_view._btnIMD.currentTxt.text = "当前电信";
			//			_view._btnIMD.curretMode.text= "高清模式";
		}
		
		private function GaoQinHandler(e:MouseEvent):void
		{
			//			stop();
			//			JavascriptAPI.ChangeKbpsHandler((_currentService+_gaoQin),Model._playingTime);
			//			_view._btnIMD.curretMode.text= "高清模式";
		}
		
		private function LiuChangeHandler(e:MouseEvent):void
		{
			//			stop();
			//			JavascriptAPI.ChangeKbpsHandler((_currentService+_liuChange),Model._playingTime);
			//			_view._btnIMD.curretMode.text= "流畅模式";
		}
		
		private function BiaoqinHandler(e:MouseEvent):void
		{
			//			stop();
			//			JavascriptAPI.ChangeKbpsHandler((_currentService+_biaoQin),Model._playingTime);
			//			_view._btnIMD.curretMode.text= "标清模式";
		}
		
		private function VoiceHandler(e:MouseEvent):void
		{
			//			stop();
			//			JavascriptAPI.ChangeKbpsHandler((_currentService+_voiceAO),Model._playingTime);
			//			_view._btnIMD.curretMode.text= "声音模式";
		}
		
		private function DoubleClickHandler(e:ViewEvent):void
		{
			//ExternalInterface.call(CallJSFunction.TRACK,CallJSFunction.TRACK_PARAMETER,("max|"+e.data));
			fullscreen(e.data); 
		}
		
		//播放控制colo 响应按钮点击播放
		public function playHandler(evt:ViewEvent=null):void 
		{ 
			if(_view.showADing==true) return;//广告或者片头正在播放中
			
			//分段RootReference.flashvarObject['_userPause'] = "false";
			//ExternalInterface.call(CallJSFunction.TRACK,CallJSFunction.TRACK_PARAMETER,"play|true");
			play(); 
		}
		
		protected function stopHandler(evt:ViewEvent):void 
		{ 
			//ExternalInterface.call(CallJSFunction.TRACK,CallJSFunction.TRACK_PARAMETER,"用户点击了停止");
			stop(); 
		}
		//暂停
		public function pauseHandler(evt:ViewEvent=null):void 
		{ 
			if(_view.showADing==true) return;//广告或者片头正在播放中/广告或者片头正在播放中
			//ExternalInterface.call(CallJSFunction.TRACK,CallJSFunction.TRACK_PARAMETER,"pause|true");
			pause(); 
		}
		
		protected function nextHandler(evt:ViewEvent):void 
		{ 
			//ExternalInterface.call(CallJSFunction.TRACK,CallJSFunction.TRACK_PARAMETER,"用户点击了下一个");
			next(); 
		}
		protected function prevHandler(evt:ViewEvent):void 
		{ 
			//ExternalInterface.call(CallJSFunction.TRACK,CallJSFunction.TRACK_PARAMETER,"用户点击了上一个");
			previous(); 
		}
		protected function seekHandler(evt:ViewEvent):void 
		{ 
			//ExternalInterface.call(CallJSFunction.TRACK,CallJSFunction.TRACK_PARAMETER,("progress|"+evt.data));
			seek(evt.data); 
		}
		
		
		//public var _addVolumeSlide:Boolean=false;//标志声音SLIDE是否在舞台视频上
		//private var _normalScreenBtn:MovieClip;
		//静音
		protected function muteHandler(evt:ViewEvent):void 
		{
			//ExternalInterface.call(CallJSFunction.TRACK,CallJSFunction.TRACK_PARAMETER,"mute|"+evt.data);
			mute(evt.data); 
		}
		
		
		
		private function ThumbDown(e:MouseEvent):void
		{
			(_view.components.controlbar as ControlbarComponentV4)._isVolumeSliderShow= true;
			var _volumeSlide:MovieClip =(_view.components.controlbar as ControlbarComponentV4).getSkinComponent('imdVolumeslideIcon') as MovieClip;
			
			_volumeSlide.audioThumb.startDrag(true,_recDrag);
			_volumeSlide.stage.addEventListener(MouseEvent.MOUSE_MOVE,VolumeMoveHandler);
			_view._componentsLayer.stage.addEventListener(MouseEvent.MOUSE_UP,ThumbUp);
		}
		
		private function VolumeMoveHandler(e:MouseEvent):void
		{
			SetMoveVolume();
		}
		
		private function SetMoveVolume():void
		{
			var _volumeSlide:MovieClip =(_view.components.controlbar as ControlbarComponentV4).getSkinComponent('imdVolumeslideIcon') as MovieClip;
			
			
			if(_volumeSlide.audioThumb.x<0)
			{
				_volumeSlide.audioThumb.x=0;
			}
			
			_volumeSlide.volumedone.width =_volumeSlide.audioThumb.x;
			//trace("音量游标位置："+_volumeSlide.audioThumb.x);
			var volume:int = int(100-(_recDrag.width-_volumeSlide.audioThumb.x)/_recDrag.width*100);
			trace("volume："+volume);
			setVolume(volume); 
			
			if(volume==0)
			{
				mute(true);
			}
			else
			{
				_model.mute = false;
			}
			
			//分段注释(_model.media as HTTPFenDuanMediaProvider).volumecur=volume;
			
			
		}
		
		private function ThumbUp(e:MouseEvent):void
		{
			(_view.components.controlbar as ControlbarComponentV4)._isVolumeSliderShow= false;
			var _volumeSlide:MovieClip =(_view.components.controlbar as ControlbarComponentV4).getSkinComponent('imdVolumeslideIcon') as MovieClip;
			
			
			SetMoveVolume();
			_volumeSlide.audioThumb.stopDrag();
			_volumeSlide.stage.removeEventListener(MouseEvent.MOUSE_MOVE,VolumeMoveHandler);
			_view._componentsLayer.stage.removeEventListener(MouseEvent.MOUSE_UP,ThumbUp);
		}
		
		//全屏
		protected function fullscreenHandler(evt:ViewEvent):void 
		{ 
			//ExternalInterface.call(CallJSFunction.TRACK,CallJSFunction.TRACK_PARAMETER,("max|"+evt.data));
			fullscreen(evt.data); 
		}
		
		protected function loadHandler(evt:ViewEvent):void 
		{ 
			load(evt.data); 
		}
		
		protected function redrawHandler(evt:ViewEvent):void 
		{ 
			redraw(); 
		}
		
		//安装完毕
		protected function setupComplete(evt:Event):void 
		{
			_setupComplete = true;
			//处理视图
			_view.completeView();
			
			
			addViewListeners();
			
			retPortTimer=new Timer(Number(_player.config.reportplaytime));
			retPortTimer.addEventListener(TimerEvent.TIMER,ReportTimerHandler);
			urlLoader.addEventListener(Event.COMPLETE, DecodeJSONHandler);
			//最终加载完毕
			finalizeSetup();
			//colowap这里发事件何用估计没啥用处 不影响Http流
			//tbwt.start();
		}
		
		
		
		private var _playedReal:Number=0;
		
		private function ReportTimerHandler(e:TimerEvent):void
		{
			if((_model.media as HTTPMediaProvider)==null) return;
			var variables:URLVariables = new URLVariables();
			//businfo，arcinfo，pageinfo
			variables.buffered = (_model.media as HTTPMediaProvider).stream.bufferLength;
			variables.played = int((_model.media as HTTPMediaProvider).position);
			variables.played_real =int((getTimer()-_playedReal)/1000);
			
			
			//trace("variables.played::::"+variables.played);
			//trace("variables.played_real::::"+variables.played_real);
			
			var url:String="https://api.guancloud.com/1.0/video/"+_model.playlist.currentItem.videoid+"/track-play?";
			
			HttpGetJsonController.getInstance().SendQuest(URLRequestMethod.GET,url,variables);
		}
		
		//播放器操作
		public function ReportPlayerAction(val:int):void
		{
			if((_model.media as HTTPMediaProvider)==null) return;
			
			var variables:URLVariables = new URLVariables();
			//businfo，arcinfo，pageinfo
			variables.action =val;
			variables.arguments =null;// int((_model.media as HTTPMediaProvider).position);
			variables.played =int((_model.media as HTTPMediaProvider).position);
			
			
			var url:String="https://api.guancloud.com/1.0/video/"+_model.playlist.currentItem.videoid+"/track-action?";
			
			HttpGetJsonController.getInstance().SendQuest(URLRequestMethod.GET,url,variables);
		}
		
		protected function setupError(evt:ErrorEvent):void 
		{
			Logger.log("STARTUP: Error occurred during player startup: " + evt.text);
			_view.completeView(true, evt.text);
			dispatchEvent(evt.clone());
		}
		
		
		protected function finalizeSetup():void 
		{
			if (!locking && _setupComplete && !_setupFinalized) 
			{
				_setupFinalized = true;
				
				dispatchEvent(new PlayerEvent(PlayerEvent.JWPLAYER_READY));
				//初始化完毕开始播放
				_player.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_LOADED, playlistLoadHandler);
				_player.addEventListener(ErrorEvent.ERROR, errorHandler);
				_player.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_ITEM, playlistItemHandler);
				
				_model.addEventListener(MediaEvent.JWPLAYER_MEDIA_COMPLETE, completeHandler);
				
				// Broadcast playlist loaded (which was swallowed during player setup);
				if (_model.playlist.length > 0) 
				{
					dispatchEvent(new PlaylistEvent(PlaylistEvent.JWPLAYER_PLAYLIST_LOADED, _model.playlist));
				}
				
			}
		}
		
		
		protected function playlistLoadHandler(evt:PlaylistEvent=null):void 
		{
			if (_model.config.shuffle) 
			{
				shuffleItem();
			} 
			else 
			{
				if (_model.config.item >= _model.playlist.length) 
				{
					_model.config.item = _model.playlist.length - 1;
				}
				_model.playlist.currentIndex = _model.config.item;
			}
			
			if(_model.config.autostart) //开启自动播放
			{
				if (locking) 
				{
					_unlockAutostart = true;
				} 
				else 
				{
					tbwt.start();//初始化完毕开始测网速
					
					//play();
				}
			}
			
			
			
			
		}
		
		
		protected function shuffleItem():void 
		{
			_model.playlist.currentIndex = Math.floor(Math.random() * _model.playlist.length);
		}
		
		
		protected function playlistItemHandler(evt:PlaylistEvent):void {
			_model.config.item = _model.playlist.currentIndex;
		}
		
		
		protected function errorHandler(evt:ErrorEvent):void 
		{
			_delayedItem = null;
			_mediaLoader = null;
			errorState(evt.text);
		}
		
		
		protected function errorState(message:String=""):void {
			dispatchEvent(new PlayerEvent(PlayerEvent.JWPLAYER_ERROR, message));
		}
		
		
		protected function completeHandler(evt:MediaEvent):void 
		{
			switch (_model.config.repeat)
			{
				case RepeatOptions.SINGLE:
					play();
					break;
				case RepeatOptions.ALWAYS:
					
					if (_model.playlist.currentIndex == _model.playlist.length - 1 && !_model.config.shuffle)
					{
						_model.playlist.currentIndex = 0;
						play();
					} 
					else 
					{
						next();
					}
					break;
				case RepeatOptions.LIST:
					if (_model.playlist.currentIndex == _model.playlist.length - 1 && !_model.config.shuffle)
					{
						_lockingResume = false;
						_model.playlist.currentIndex = 0;
					} 
					else
					{
						next();
					}
					break;
			}
		}
		
		
		////////////////////
		// Public methods //
		////////////////////
		
		public function get locking():Boolean 
		{
			return _lockManager.locked();
		}
		
		
		/**
		 * @private
		 * @copy com.longtailvideo.jwplayer.player.Player#lockPlayback
		 */
		public function lockPlayback(plugin:IPlugin, callback:Function):void 
		{
			var wasLocked:Boolean = locking;
			if (_lockManager.lock(plugin, callback)) 
			{
				// If it was playing, pause playback and plan to resume when you're done
				if (_player.state == PlayerState.PLAYING || _player.state == PlayerState.BUFFERING) {
					_model.media.pause();
					_lockingResume = true;
				}
				
				// Tell everyone you're locked
				if (!wasLocked) {
					Logger.log(plugin.id + " locking playback", "LOCK");
					dispatchEvent(new PlayerEvent(PlayerEvent.JWPLAYER_LOCKED));
					_lockManager.executeCallback();
				}
			}
		}
		
		
		/**
		 * @private
		 * @copy com.longtailvideo.jwplayer.player.Player#unlockPlayback
		 */
		public function unlockPlayback(target:IPlugin):Boolean 
		{
			if (_lockManager.unlock(target)) 
			{
				if (!locking) {
					dispatchEvent(new PlayerEvent(PlayerEvent.JWPLAYER_UNLOCKED));
				}
				if (_setupComplete && !_setupFinalized) {
					finalizeSetup();
				}
				if (!locking && (_lockingResume || _unlockAutostart)) {
					_lockingResume = false;
					play();
					if (_unlockAutostart) {
						_unlockAutostart = false;
					} else if (_unlockAndLoad) {
						_unlockAndLoad = false;
					}
				}
				return true;
			}
			return false;
		}
		
		
		public function setVolume(vol:Number):Boolean 
		{
			if (locking) 
			{
				return false;
			}
			if (_model.media) 
			{
				_model.config.volume = vol;
				trace("vol:::"+vol);
				if(vol<=0)
				{
					vol=0;
				}
				//trace("音量初始化当前的流http：："+_model.media is HTTPMediaProvider);
				
				//trace("音量初始化当前的流：："+_model.media is RTMPMediaProvider);
				_model.media.setVolume(vol);
				//setCookie('volume', vol);
				return true;
			}
			return false;
		}
		
		private var _recordVolumeThumbX:Number;
		
		public function mute(muted:Boolean):Boolean 
		{
			var _volumeSlide:MovieClip =(_view.components.controlbar as ControlbarComponentV4).getSkinComponent('imdVolumeslideIcon') as MovieClip;
			
			
			if (locking) 
			{
				return false;
			}
			
			if (muted && !_model.mute) 
			{
				_model.mute = true;//设置状态发改变图标事件
				//setCookie('mute', true);
				
				_recordVolumeThumbX = _volumeSlide.audioThumb.x;
				
				_volumeSlide.audioThumb.x=0;
				_volumeSlide.volumedone.width =_volumeSlide.audioThumb.x;//设置音量0
				
				setVolume(0);//设置音量0
				
				return true;
			} 
			else if (!muted && _model.mute) 
			{
				_model.mute = false;
				//setCookie('mute', false);
				
				
				_volumeSlide.audioThumb.x=_recordVolumeThumbX;
				_volumeSlide.volumedone.width =_volumeSlide.audioThumb.x;
				
				var volume:int = int(100-(_recDrag.width-_volumeSlide.audioThumb.x)/_recDrag.width*100);
				setVolume(volume);
				 
				
				return true;
			}
			
			return false;
		}
		
		public var _bufferBeforeURL:String;//缓冲前的URL主要是为了区分人为切换码流
		//和网络卡两种原因引起的缓冲
		private var _seekStartTime:Number;
		
		//每个影片初始化调用播放
		public function MovieReset(videoId:String):void
		{
			RootReference._lianboType=true;
			_model.playlist.currentItem.videoid=videoId;
			_model.playlist.currentItem.duration=-1;
			(_view.components.controlbar as ControlbarComponentV4).kandianShow=false;
		}
		
		
		public function GetVideoJsonhandler(e:Event=null):void
		{
			GetVideoJson(_model.playlist.currentItem.videoid);
		}
		
		//播放
		public function play(startTime:Number=0):Boolean 
		{
			ReportPlayerAction(2);
			
			if(initJsonEnd==false)
			{
				if(_model.config.autostart==false) //未开启自动播放
				{
					if(tbwt.isTested==false)
					{
						tbwt.start();//初始化完毕开始测网速
						return false;
					}
				}
			}
			
			
			_seekStartTime = startTime;
			
			if (_mediaLoader) 
			{
				_delayedItem = _model.playlist.currentItem;
				return false;
			}
			
			if (locking) 
			{
				return false;
			}
			
			if (_model.playlist.currentItem) 
			{
				switch (_player.state) 
				{
					case PlayerState.IDLE:
						
						if(initJsonEnd==false)
						{
							FirstPlay();
							//trace("_model.playlist.currentItem.videoid::::"+_model.playlist.currentItem.videoid);
						}
						else
						{
							_model._currentPlayURL = _model.playlist.currentItem.streamer+"*"+_model.playlist.currentItem.file;
							
							//trace("file"+_model.playlist.currentItem.file);
							//trace("streamer"+_model.playlist.currentItem.streamer);
							load(_model.playlist.currentItem);//分析播放列表判断流的类型
							//开始加载视频准备播放
							//trace("sdf"+_model.playlist.currentItem.file);
							trace("当前流类型：："+_model.media);
							_model.media.load(_model.playlist.currentItem);//加载视频内容
							
							_model.media.addEventListener(MediaEvent.JWPLAYER_MEDIA_START_PLAY, StartPlayHandler);
							_model.media.addEventListener(MediaEvent.JWPLAYER_MEDIA_BUFFER_FULL, bufferFullHandler);
							
							
							if(startTime>0)//如果startTime>0播放后块进
							{
								pause();
								seekuint = flash.utils.setTimeout(DelayMp4Seek,1000);
							}
						}
						
						break;
					case PlayerState.PAUSED:
						_model.media.play();
						break;
					
					case PlayerState.PLAYING:
						
						
						if(_isurlPlay)
						{
							//再次点击JS播放正在播放的状态
							//trace(_model.playlist.currentItem.file);
							//trace(_model.playlist.currentItem.streamer);
							
							load(_model.playlist.currentItem);//分析视频源
							_model.media.load(_model.playlist.currentItem);//加载视频内容
							
							
							if(startTime>0)//如果startTime>0播放后块进
							{
								pause();
								seekuint = flash.utils.setTimeout(DelayMp4Seek,1000);
						    }
							_isurlPlay = false;
						}
				}
			}
			return true;
		}
		
		public var initJsonEnd:Boolean=false;//初始化获取Json已经完毕
		
		private var urlLoader:URLLoader = new URLLoader(); 
		
		private function GetVideoJson(val:String):void
		{
			RootReference.currentID=val;
			urlLoader.load(new URLRequest("http://uapi.guancloud.com/1.0/video/"+val));//这里是你要获取JSON的路径
		}
		
		public var snapShotArr:Array=[];
		public var mediaArr:Array=[];
		private var streamType:String="MP4";
		
		private function DecodeJSONHandler(event:Event):void
		{
			var ob:Object=com.adobe.serialization.json.JSON.decode(URLLoader(event.target).data);
			
			var dlen:int=mediaArr.length;
			
			for(var x:int=0;x<dlen;x++)
			{
				mediaArr.pop();
			}
			
			var dlen2:int=snapShotArr.length;
			
			for(var x2:int=0;x2<dlen2;x2++)
			{
				snapShotArr.pop();
			}
			
			mediaArr=ob.media;
			
			
		    mediaArr.sortOn("bitrate",Array.NUMERIC|Array.DESCENDING);
			
			var dlen3:Number=mediaArr.length;
			
			
			for(var x3:int=0;x3<dlen3;x3++)
			{
				var bitr:Number=Number(mediaArr[x3].bitrate);
				
				if(bitr<RootReference._bandWidth)
				{
					RootReference._currentBpsid=x3;
					break;
				}
				else
				{
					RootReference._currentBpsid=0;
				}
			}
			
			
			
			
		//	trace(RootReference._currentBps);
			
			snapShotArr=ob.snapshot;
			
			//这个时候网速已经测完了
			play();
		}
		
		private function FirstPlay():void
		{
			
			//vodType=mediaArr[0].format;
			
			if(streamType=="M3U8")
			{
				_model.playlist.currentItem.file="http://admin.ea372.m3u8";//换成https
				//_model.playlist.currentItem.file="http://www.streambox.fr/playlists/test_001/stream.m3u8";
				//
				//_model.playlist.currentItem.file="http://playertest.longtailvideo.com/adaptive/captions/playlist.m3u8";
				//_model.playlist.currentItem.file=mediaArr[0].urls[0];
				_model.playlist.currentItem.type="m3u8";
				
				_model._currentPlayURL = _model.playlist.currentItem.streamer+"*"+_model.playlist.currentItem.file;
				load(_model.playlist.currentItem);//分析播放列表判断流的类型
				//开始加载视频准备播放
				trace("当前流类型：："+_model.media);
				
				
				_model.media.load(_model.playlist.currentItem);//加载视频内容
				
				if(_model.media.hasEventListener(MediaEvent.JWPLAYER_MEDIA_START_PLAY)==false)
				{
					_model.media.addEventListener(MediaEvent.JWPLAYER_MEDIA_START_PLAY, StartPlayHandler);
					_model.media.addEventListener(MediaEvent.JWPLAYER_MEDIA_BUFFER_FULL, bufferFullHandler);
				}
			}
			else if(streamType=="MP4")
			{
				trace(_model.playlist.currentItem.file);
				_model.playlist.currentItem.file=_model.playlist.currentItem.file;//mediaArr[RootReference._currentBpsid].urls[0];
				RootReference.currentStream=mediaArr[RootReference._currentBpsid].quality;
				
				_model._currentPlayURL = _model.playlist.currentItem.streamer+"*"+_model.playlist.currentItem.file;
				load(_model.playlist.currentItem);//分析播放列表判断流的类型
				//开始加载视频准备播放
				trace("当前流类型：："+_model.media);
				
				_model.media.load(_model.playlist.currentItem);//加载视频内容
				
				
				if(_player.config.isvr)
				{
					_view.Vr360start();
				}
				
				if(_model.media.hasEventListener(MediaEvent.JWPLAYER_MEDIA_START_PLAY)==false)
				{
					_model.media.addEventListener(MediaEvent.JWPLAYER_MEDIA_START_PLAY, StartPlayHandler);
					_model.media.addEventListener(MediaEvent.JWPLAYER_MEDIA_BUFFER_FULL, bufferFullHandler);
				}
				
				//retPortTimer.start();
				//_playedReal=getTimer();
			}
			else
			{
				///live/hks
				_model.playlist.currentItem.streamer="rtmp://115.182.75.8/live";
				_model.playlist.currentItem.file="gee";
				
				//mediaArr[0].urls[1];//换成https
				
				_model._currentPlayURL = _model.playlist.currentItem.streamer+"*"+_model.playlist.currentItem.file;
				load(_model.playlist.currentItem);//分析播放列表判断流的类型
				//开始加载视频准备播放
				trace("当前流类型：："+_model.media);
				
				
				_model.media.load(_model.playlist.currentItem);//加载视频内容
				
				if(_model.media.hasEventListener(MediaEvent.JWPLAYER_MEDIA_START_PLAY)==false)
				{
					_model.media.addEventListener(MediaEvent.JWPLAYER_MEDIA_START_PLAY, StartPlayHandler);
					_model.media.addEventListener(MediaEvent.JWPLAYER_MEDIA_BUFFER_FULL, bufferFullHandler);
				}
				
				
			}
			
			initJsonEnd=true;
		}
		
		
		private var seekuint:uint;
		
		private function DelayMp4Seek():void
		{
			flash.utils.clearTimeout(seekuint);
			//RootReference.flashvarObject['kbpschangingzhong'] = "false";//http码流切换完毕
			
			_model.media.seek(_seekStartTime);
		}
		
		private function ImdVideoHandler(e:Event):void
		{
			_model.media.seek(_seekStartTime);
			_model.media.removeEventListener("ImdVideo",ImdVideoHandler);
		}
		
		//		private function ImdVideoHandler2(startTime:int):Function
		//		{
		//			
		//			var _fun:Function = function (e:Event):void
		//			{
		//				_model.media.seek(startTime);
		//				trace("startTime"+startTime);
		//				e.target.removeEventListener("ImdVideo",ImdVideoHandler);
		//			}
		//			
		//			return _fun;
		//		}
		
		
		private var _isurlPlay:Boolean = false;
		//http码流切换
		public function URLPlay(pli:PlaylistItem,startTime:Number):Boolean
		{
			_isurlPlay = true;
			//先重置播放列表，然后开始播放
			_model.playlist.currentItem.file = pli.file;
			
			
		//	RootReference.flashvarObject['changekbpsStartTime'] = startTime;
			
			stop();
			play(startTime);
			
			return true;
		}
		
		//暂停
		public function pause():Boolean 
		{
			ReportPlayerAction(4);
			//分段RootReference.flashvarObject['_userPause'] = true;
			
			if (locking) 
			{
				return false;
			}
			if (!_model.media)
				return false;
			
			switch (_model.media.state) 
			{
				case PlayerState.PLAYING:
				case PlayerState.BUFFERING:
					_model.media.pause();
					return true;
					break;
			}
			
			return false;
		}
		
		
		public function stop():Boolean 
		{
			
			
			if (locking) {
				return false;
			}
			if (!_model.media)
				return false;
			
			switch (_model.media.state) {
				case PlayerState.PLAYING:
				case PlayerState.BUFFERING:
				case PlayerState.PAUSED:
					_model.media.stop();
					return true;
					break;
			}
			
			return false;
		}
		
		
		public function next():Boolean 
		{
			if (locking) 
			{
				_unlockAndLoad = true;
				return false;
			}
			
			_lockingResume = true;
			stop();
			if (_model.config.shuffle) 
			{
				shuffleItem();
			} else if (_model.playlist.currentIndex == _model.playlist.length - 1) {
				_player.playlist.currentIndex = 0;
			} else {
				_player.playlist.currentIndex = _player.playlist.currentIndex + 1;
			}
			play();
			
			return true;
		}
		
		
		public function previous():Boolean
		{
			if (locking) 
			{
				_unlockAndLoad = true;
				
				return false;
			}
			
			_lockingResume = true;
			stop();
			if (_model.config.shuffle) {
				shuffleItem();
			} else if (_model.playlist.currentIndex <= 0) {
				_model.playlist.currentIndex = _model.playlist.length - 1;
			} else {
				_player.playlist.currentIndex = _player.playlist.currentIndex - 1;
			}
			play();
			
			return true;
		}
		
		
		public function setPlaylistIndex(index:Number):Boolean 
		{
			if (locking) 
			{
				_unlockAndLoad = true;
				return false;
			}
			
			_lockingResume = true;
			if (0 <= index && index < _player.playlist.length) 
			{
				stop();
				_player.playlist.currentIndex = index;
				play();
				return true;
			}
			return false;
		}
		
		//接收搜索
		public function seek(pos:Number):Boolean 
		{
			ReportPlayerAction(47);
			
			
			if (locking) {
				return false;
			}
			if (!_model.media)
				return false;
			
			switch (_model.media.state) 
			{
				case PlayerState.PLAYING:
				case PlayerState.BUFFERING:
				case PlayerState.PAUSED:
					_model.media.seek(pos);
					return true;
					break;
			}
			
			return false;
		}
		
		
		public function load(item:*):Boolean 
		{
			if (locking)
			{
				_unlockAndLoad = true;
				return false;
			}
			
			if (_model.state != ModelStates.IDLE)
			{
				_model.media.stop();
			}
			if (item is PlaylistItem) 
			{
				return loadPlaylistItem(item as PlaylistItem);
			} 
			else if (item is String) 
			{
				return loadString(item as String);
			} 
			else if (item is Number) 
			{
				return loadNumber(item as Number);
			} 
			else if (item is Array) 
			{
				return loadArray(item as Array);
			} 
			else if (item is Object) 
			{
				return loadObject(item as Object);
			}
			
			return false;
		}
		
		//加载播放列表
		protected function loadPlaylistItem(item:PlaylistItem):Boolean 
		{
			if (locking) 
			{
				_lockingResume = true;
				return false;
			}
			
			if (!_model.playlist.contains(item)) 
			{
				_model.playlist.load(item);
				return false;
			}
			
			try 
			{
				if (!item.streamer && _model.config.streamer) 
				{ 
					item.streamer = _model.config.streamer; 
				}
				
				//if (!item.provider) //判断流类型
				//{ 
					item.provider = JWParser.getProvider(item); 
				//}
				//trace(item);
				if (!setProvider(item) && item.file) 
				{ 
					_model.playlist.load(item.file);
				}
			} 
			catch (err:Error) 
			{
				Logger.log(err.message, "ERROR");
				return false;
			}
			
			Logger.log("Loading PlaylistItem: " + item.toString(), "LOAD");
			
			return true;
		}
		
		
		protected function loadString(item:String):Boolean 
		{
			_model.playlist.load(new PlaylistItem({file: item}));
			return true;
		}
		
		
		protected function loadArray(item:Array):Boolean 
		{
			if (item.length > 0) 
			{
				_model.playlist.load(item);
				return true;
			}
			return false;
		}
		
		protected function loadNumber(item:Number):Boolean 
		{
			if (item >= 0 && item < _model.playlist.length) 
			{
				_model.playlist.currentIndex = item;
				return loadPlaylistItem(_model.playlist.currentItem);
			}
			return false;
		}
		
		
		protected function loadObject(item:Object):Boolean 
		{
			if ((item as Object).hasOwnProperty('file')) 
			{
				_model.playlist.load(new PlaylistItem(item));
				return true;
			}
			return false;
		}
		
		//设置流类型
		protected function setProvider(item:PlaylistItem):Boolean 
		{
			var provider:String = item.provider;
			
			if (provider) 
			{
				
				// Backwards compatibility for CDNs in the 'type' flashvar.
				if (cdns.hasOwnProperty(provider)) {
					_model.config.setConfig(cdns[provider]);
					provider = cdns[provider]['provider'];
				}
				
				// If the model doesn't have an instance of the provider, load & instantiate it
				if (!_model.hasMediaProvider(provider)) {
					_mediaLoader = new MediaProviderLoader();
					_mediaLoader.addEventListener(Event.COMPLETE, mediaSourceLoaded);
					_mediaLoader.addEventListener(ErrorEvent.ERROR, errorHandler);
					_mediaLoader.loadSource(provider);
					return true;
				}
				//设置活动的流
				_model.setActiveMediaProvider(provider);
				return true;
			}
			
			return false;
		}
		
		
		protected function mediaSourceLoaded(evt:Event):void 
		{
			var loader:MediaProviderLoader = _mediaLoader;
			_delayedItem = null;
			_mediaLoader = null;
			if (_delayedItem) 
			{
				_model.setMediaProvider(_delayedItem.provider, loader.loadedSource);
				play();
			} else {
				_model.setMediaProvider(_model.playlist.currentItem.provider, loader.loadedSource);				
			}
		}
		
		private function StartPlayHandler(evt:MediaEvent):void//与服务器取得联系视频开始播放了
		{
			deuint=flash.utils.setTimeout(Timeout,3000);
			
		}
		
		private var deuint:uint;
		
		private function Timeout():void
		{
			flash.utils.clearTimeout(deuint);
			(_view.components.display as DisplayComponent).HideBufferIcon();
		}
		
		//缓冲完毕
		private function bufferFullHandler(evt:MediaEvent):void 
		{
			if (!locking) 
			{
				trace("事先buffer");
				_model.media.play();
			} 
			else 
			{
				_lockingResume = true;
			}
			
			if((_view.components.display as DisplayComponent)._changeStreamBuffer)//如果是切换码流引起的缓冲延时消失
			{
				var disComponent:DisplayComponent = imdView.components.display as DisplayComponent;
				
				//if(disComponent._changeStreamName=="音频")
				//{
					//音频模式让它一直显示
					//RootReference.AlertShow();
					//RootReference.imdAlert.alertTxt = "当前为音频模式";
					//RootReference.imdAlert.name = "live";
				//}
				
				intervalId=flash.utils.setTimeout(DelayCleareDisplay,500);
			}
			
		}
		
		private var intervalId:uint;
		
		//删除码流提示
		private function DelayCleareDisplay():void
		{
			var disComponent:DisplayComponent = _view.components.display as DisplayComponent;
			disComponent._changeStreamBuffer = false;
			disComponent.clearDisplay();
			flash.utils.clearTimeout(intervalId);
		}
		
		
		public function redraw():Boolean 
		{
			if (locking) 
			{
				return false;
			}
			_view.redraw();
			return true;
		}
		
		//响应全屏
		public function fullscreen(mode:Boolean):Boolean 
		{
			
			_model.fullscreen = mode;
			_view.fullscreen(mode);
			return true;
		}
		
		
		public function link(playlistIndex:Number=NaN):Boolean 
		{
			if (locking) 
			{
				return false;
			}
			if (isNaN(playlistIndex))
				playlistIndex = _model.playlist.currentIndex;
			
			if (playlistIndex >= 0 && playlistIndex < _model.playlist.length) 
			{
				navigateToURL(new URLRequest(_model.playlist.getItemAt(playlistIndex).link), _model.config.linktarget);
				return true;
			}
			
			return false;
		}
		
		
		protected function setCookie(name:String, value:*):void 
		{
			Configger.saveCookie(name, value);
		}
		
	}
}