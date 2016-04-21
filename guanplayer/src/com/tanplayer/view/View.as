///////////////////////////////////////////////////////////
///view视图类视频，广告，层级  新加的按钮一定要是MC或按钮
//////////////////////////////////////////////////////////
package com.tanplayer.view 
{
	import com.events.AbstractView;
	import com.tanplayer.components.ControlbarComponentV4;
	import com.tanplayer.components.DisplayComponent;
	import com.tanplayer.events.GlobalEventDispatcher;
	import com.tanplayer.events.IGlobalEventDispatcher;
	import com.tanplayer.events.MediaEvent;
	import com.tanplayer.events.PlayerEvent;
	import com.tanplayer.events.PlayerStateEvent;
	import com.tanplayer.events.PlaylistEvent;
	import com.tanplayer.events.ViewEvent;
	import com.tanplayer.interfaces.IControlbarComponent;
	import com.tanplayer.interfaces.IDisplayComponent;
	import com.tanplayer.interfaces.IDockComponent;
	import com.tanplayer.interfaces.IPlayerComponent;
	import com.tanplayer.interfaces.IPlaylistComponent;
	import com.tanplayer.interfaces.ISkin;
	import com.tanplayer.media.ADhttpHantang;
	import com.tanplayer.media.HTTPFenDuanMediaProvider;
	import com.tanplayer.media.M3u8MediaProvider;
	import com.tanplayer.model.Model;
	import com.tanplayer.model.PlaylistItem;
	import com.tanplayer.player.CallJSFunction;
	import com.tanplayer.player.IPlayer;
	import com.tanplayer.player.Player;
	import com.tanplayer.player.PlayerState;
	import com.tanplayer.player.PlayerV4Emulation;
	import com.tanplayer.plugins.IPlugin;
	import com.tanplayer.plugins.PluginConfig;
	import com.tanplayer.utils.Draw;
	import com.tanplayer.utils.Logger;
	import com.tanplayer.utils.RootReference;
	import com.tanplayer.utils.Stretcher;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.media.Video;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import org.osmf.events.TimeEvent;
	
	import visuall.ovp.PanoVideoNav;
	

	
	
	public class View extends GlobalEventDispatcher 
	{
		protected var _player:IPlayer;
		protected var _model:Model;
		protected var _skin:ISkin;
		protected var _components:IPlayerComponents;
		protected var _fullscreen:Boolean = false;
		protected var stage:Stage;
		
		protected var _root:MovieClip;
		protected var _backgroundLayer:MovieClip;
		protected var _mediaLayer:MovieClip;//视频层
		
		protected var _imageLayer:MovieClip;//图片广告层(预览图片也在这一层)
		public var _componentsLayer:MovieClip;
		protected var _pluginsLayer:MovieClip;
		protected var _plugins:Object;
		
		protected var _displayMasker:MovieClip;
		
		protected var _imageLoader:Loader;
		public var _logo:Logo;
		
		protected var layoutManager:PlayerLayoutManager;
		
		[Embed(source="../assets/flash/loader/loader.swf")]
		protected var LoadingScreen:Class;
		
		[Embed(source="../assets/flash/loader/error.swf")]
		protected var ErrorScreen:Class;
		
		protected var loaderScreen:Sprite;
		protected var loaderAnim:DisplayObject;
		
		protected var currentLayer:Number = 0;
		
		
		public function get viewStage():Stage
		{
			return stage;
		}
		
		public function View(player:IPlayer, model:Model) 
		{
			_player = player;
			_model = model;
			
			RootReference.stage.scaleMode = StageScaleMode.NO_SCALE;
			RootReference.stage.stage.align = StageAlign.TOP_LEFT;
			
			loaderScreen = new Sprite();
			loaderScreen.name = 'loaderScreen';
			
			loaderAnim = new LoadingScreen() as DisplayObject;
			loaderScreen.addChild(loaderAnim);
			
			RootReference.stage.addChildAt(loaderScreen, 0);
			
			if (RootReference.stage.stageWidth > 0) 
			{
				resizeStage();
			} 
			else 
			{
				RootReference.stage.addEventListener(Event.RESIZE, resizeStage);
				RootReference.stage.addEventListener(Event.ADDED_TO_STAGE, resizeStage);
			}
			
			_root = new MovieClip();
		}
		
		public var lineNumTxt:TextField;
		//当前在线人数
		public function ChangeCurrentOnLineNum(str:String):void
		{
			//lineNumTxt.text=str;
		}
		
		private var prewImageLoader:Loader;
		
		public function get imageLayer():MovieClip
		{
			return _imageLayer;
		}
		
		public function get mediaLayer():MovieClip
		{
			return _mediaLayer;
		}
		
		public function get imdADVideoLayer():MovieClip
		{
			return _imdADVideoLayer;
		}
		
		protected function resizeStage(evt:Event=null):void 
		{
			RootReference.stage.removeEventListener(Event.RESIZE, resizeStage);
			RootReference.stage.removeEventListener(Event.ADDED_TO_STAGE, resizeStage);
			//加载屏幕大小
			loaderScreen.graphics.clear();
			loaderScreen.graphics.beginFill(0, 1);
			loaderScreen.graphics.drawRect(0, 0, RootReference.stage.stageWidth, RootReference.stage.stageHeight);
			loaderScreen.graphics.endFill();
			
			loaderAnim.x = (RootReference.stage.stageWidth - loaderAnim.width) / 2;
			loaderAnim.y = (RootReference.stage.stageHeight - loaderAnim.height) / 2;
			
		}
		
		
		public function get skin():ISkin 
		{
			return _skin;
		}
		
		
		public function set skin(skn:ISkin):void 
		{
			_skin = skn;
		}
		
		
		public function setupView():void 
		{
			RootReference.stage.addChildAt(_root, 0);
			_root.visible = false;
			
			setupLayers();
			setupComponents();
			
			
			RootReference.stage.addEventListener(Event.RESIZE, resizeHandler);
			_model.addEventListener(MediaEvent.LOADEDJWPLAYER_MEDIA, mediaLoaded);
			_model.playlist.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_ITEM, itemHandler);
			//_model.playlist.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_LOADED, itemHandler);
			_model.playlist.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_UPDATED, itemHandler);
			_model.addEventListener(PlayerStateEvent.JWPLAYER_PLAYER_STATE, stateHandler);
			
			layoutManager = new PlayerLayoutManager(_player);
			setupRightClick();
			
			redraw();
			
		}
		
		protected function setupRightClick():void 
		{
			var menu:RightclickMenu = new RightclickMenu(_player, _root);
			menu.addGlobalListener(forward);
		}
		
		public function completeView(isError:Boolean=false, errorMsg:String=""):void 
		{
			if (!isError) 
			{
				_root.visible = true;
				loaderScreen.parent.removeChild(loaderScreen);
			} 
			else 
			{
				loaderScreen.removeChild(loaderAnim);
				var errorScreen:DisplayObject = new ErrorScreen() as DisplayObject;
				errorScreen.x = (loaderScreen.width - errorScreen.width) / 2;
				errorScreen.y = (loaderScreen.height - errorScreen.height) / 2;
				loaderScreen.addChild(errorScreen);
			}
		}
		
		//设置层级
		protected function setupLayers():void 
		{
			_backgroundLayer = setupLayer("background", currentLayer++);
			setupBackground();
			
			
			_mediaLayer = setupLayer("media", currentLayer++);
			_mediaLayer.visible = false;
			
			//广告层
			_imageLayer = setupLayer("image", currentLayer++);
			_imageLoader = new Loader();
			

			
			_imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageComplete);
			_imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, imageError);
			
			
			setupLogo();
			
			_componentsLayer = setupLayer("components", currentLayer++);
			
			_pluginsLayer = setupLayer("plugins", currentLayer++);
			
			_plugins = {};
			
			_root.addChild(_imdADVideoLayer);//视频广告层
			
		    
		}
		
		protected function setupLogo():void 
		{
			_logo = new Logo(_player);
		}
		
		protected function setupLayer(name:String, index:Number):MovieClip 
		{
			var layer:MovieClip = new MovieClip();
			_root.addChildAt(layer, index);
			layer.name = name;
			layer.x = 0;
			layer.y = 0;
			return layer;
		}
		
		//绘制背景
		protected function setupBackground():void 
		{
			var background:MovieClip = new MovieClip();
			background.name = "background";
			_backgroundLayer.addChild(background);
			background.graphics.beginFill(_player.config.screencolor ? _player.config.screencolor.color : 0x000000, 1);//播放器背景色
			background.graphics.drawRect(0, 0, 1, 1);
			background.graphics.endFill();
		}
		
		
		protected function setupDisplayMask():void 
		{
			_displayMasker = new MovieClip();
			_displayMasker.graphics.beginFill(0x00FF00, 1);
			_displayMasker.graphics.drawRect(0, 0, _player.config.width, _player.config.height);
			_displayMasker.graphics.endFill();
			
			_backgroundLayer.mask = _displayMasker;
			_imageLayer.mask = _displayMasker;
			_mediaLayer.mask = _displayMasker;
		}
		
		
		protected function setupComponents():void 
		{
			_components = new PlayerComponents(_player);
			setupComponent(_components.display, 0);
			setupComponent(_components.playlist, 1);
			setupComponent(_logo, 2);
			setupComponent(_components.controlbar, 3);
			setupComponent(_components.dock, 4);
			
			//加载预览广告
			loadImage(_player.config.image);
		}
		
		protected function setupComponent(component:*, index:Number):void 
		{
			if (component is IGlobalEventDispatcher) { (component as IGlobalEventDispatcher).addGlobalListener(forward); }
			if (component is DisplayObject) { _componentsLayer.addChildAt(component as DisplayObject, index); }
		}
		
		private var df:uint;
		//响应舞台大小更改
		protected function resizeHandler(event:Event):void 
		{
			var currentFSMode:Boolean = (RootReference.stage.displayState == StageDisplayState.FULL_SCREEN);
			
			if(_model.fullscreen != currentFSMode) 
			{
				dispatchEvent(new ViewEvent(ViewEvent.JWPLAYER_VIEW_FULLSCREEN, currentFSMode));
			}
			
			redraw();
			
			googleadplayer.x=(RootReference.stage.stageWidth-googleadplayer.width)/2;
			googleadplayer.y=(RootReference.stage.stageHeight-googleadplayer.height)/2;
			//全屏处理一般都写在着
			//舞台大小更改最后重绘结束调用响应
			if(RootReference.stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				 //全屏控制面板等同于缩放隐藏
				(components.controlbar as MovieClip).visible=false;
				df = flash.utils.setTimeout(Ddedff,2000);

				//全屏缩放广告
				if(adhttphantang!=null)
				{
					_imdADVideoLayer.x = (RootReference.stage.stageWidth-_imdADVideoLayer.width)/2;
					_imdADVideoLayer.y = ((RootReference.stage.stageHeight-RootReference._controlBarHeight)-_imdADVideoLayer.height)/2;
					adtxt.x= RootReference.stage.stageWidth-adtxt.textWidth-5;//5是位置微调
				}
				
				(_components.display as DisplayComponent).HideScaleBtn();
				//这里为什么要调用原始尺寸？暂时
				//(_components.display as DisplayComponent).ScaleClickYuanShiHandler();
			}
			else
			{
//				(components.controlbar as MovieClip).visible=true;
//				
//				if(bdddLfull==true)//从全屏复原
//				{
//					(components.controlbar as ControlbarComponentV4).FixButton();
//					bdddLfull = false;
//				}
				(components.controlbar as ControlbarComponentV4).delayControlBar= false;

				(components.controlbar as MovieClip).visible=true;
				
				//缩放广告
				if(adhttphantang!=null)
				{
					adhttphantang.width=oradAdVideowidth;
					adhttphantang.height=oradAdVideoheight;
					
					ScaleFunction(adhttphantang);
				}
				
				(_components.display as DisplayComponent).HideScaleBtn();
			}
			
			(components.controlbar as ControlbarComponentV4).ShowKandian();
			
			
			if(_panoVideoNav)
			{
				_panoVideoNav.setSize(_player.config.width, _player.config.height);
			}
		}
		
		public var yuanshiVideoWidth:Number;
		public var yuanshiVideoHeight:Number;
		
		public function Ddedff():void
		{
			flash.utils.clearTimeout(df);
			(components.controlbar as ControlbarComponentV4).delayControlBar= true;
		}
		
		//响应全屏
		public function fullscreen(mode:Boolean=true):void 
		{
			RootReference.stage.displayState = mode ? StageDisplayState.FULL_SCREEN : StageDisplayState.NORMAL;
		}
		
		//全屏重绘
		/** Redraws the plugins and player components **/
		public function redraw():void 
		{
		    //舞台视频大小
			layoutManager.resize(RootReference.stage.stageWidth, RootReference.stage.stageHeight);
			//控制面板上按钮位置
			_components.resize(_player.config.width, _player.config.height);
			
			resizeBackground();
			resizeMasker();
			
			if (_imageLayer.numChildren) 
			{
				_imageLayer.x = _components.display.x;
				_imageLayer.y = _components.display.y;
				
				Stretcher.stretch(_imageLoader, _player.config.width, _player.config.height, _player.config.stretching);
			}
			//流上显示的可视对象
			if(_mediaLayer.numChildren && _model.media.display) 
			{
				//全屏
				if(RootReference.stage.displayState == StageDisplayState.FULL_SCREEN)
				{
					_mediaLayer.x = _components.display.x;
					_mediaLayer.y = _components.display.y;
					_model.media.resize(_player.config.width, _player.config.height);
				}
				else
				{
					_mediaLayer.x = _components.display.x;
					_mediaLayer.y = _components.display.y;
					_model.media.resize(_player.config.width, _player.config.height);
				}
		    }
			
			if (_logo) 
			{
				_logo.x = _components.display.x;
				_logo.y = _components.display.y;
				_logo.resize(_player.config.width, _player.config.height);
			}
			
			for (var i:Number = 0; i < _pluginsLayer.numChildren; i++) 
			{
				var plug:IPlugin = _pluginsLayer.getChildAt(i) as IPlugin;
				var plugDisplay:DisplayObject = plug as DisplayObject;
				
				if (plug && plugDisplay) 
				{
					var cfg:PluginConfig = _player.config.pluginConfig(plug.id);
					
					if (cfg['visible']) 
					{
						plugDisplay.visible = true;
						plugDisplay.x = cfg['x'];
						plugDisplay.y = cfg['y'];
						
						try 
						{
							plug.resize(cfg.width, cfg.height);
						} 
						catch (e:Error) 
						{
							Logger.log("There was an error resizing plugin '" + plug.id + "': " + e.message);
						}
					} 
					else 
					{
						plugDisplay.visible = false;
					}
				}
			}
			//获取控制面板的位置Y
			//trace(components.controlbar.y);
			_controlBarY = components.controlbar.y;
			
			PlayerV4Emulation.getInstance(_player).resize(_player.config.width, _player.config.height);
		}
		
		public var _controlBarY:Number;
		
		protected function resizeBackground():void 
		{
			var bg:DisplayObject = _backgroundLayer.getChildByName("background");
			bg.width = RootReference.stage.stageWidth;
			bg.height = RootReference.stage.stageHeight;
			bg.x = 0;
			bg.y = 0;
		}
		
		
		protected function resizeMasker():void 
		{
			if (_displayMasker == null)
				setupDisplayMask();
			
			_displayMasker.graphics.clear();
			_displayMasker.graphics.beginFill(0, 1);
			_displayMasker.graphics.drawRect(_components.display.x, _components.display.y, _player.config.width, _player.config.height);
			_displayMasker.graphics.endFill();
		}
		
		
		public function get components():IPlayerComponents 
		{
			return _components;
		}
		
		/** This feature, while not yet implemented, will allow the API to replace the built-in components with any class that implements the control interfaces. **/
		public function overrideComponent(newComponent:IPlayerComponent):void 
		{
			if (newComponent is IControlbarComponent) 
			{
				// Replace controlbar
			} else if (newComponent is IDisplayComponent) {
				// Replace display
			} else if (newComponent is IDockComponent) {
				// Replace dock
			} else if (newComponent is IPlaylistComponent) {
				// Replace playlist
			} else {
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "Component must implement a component interface"));
			}
		}
		
		
		public function addPlugin(id:String, plugin:*):void 
		{
			try 
			{
				var plugDO:DisplayObject = plugin as DisplayObject;
				if (!_plugins[id] && plugDO != null) {
					_plugins[id] = plugDO;
					_pluginsLayer.addChild(plugDO);
				}
			} 
			catch (e:Error) 
			{
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
			}
		}
		
		
		public function removePlugin(plugin:IPlugin):void 
		{
			var id:String = plugin.id.toLowerCase();
			if (id && _plugins[id] is IPlugin) {
				_pluginsLayer.removeChild(_plugins[id]);
				delete _plugins[id];
			}
		}
		
		
		public function loadedPlugins():Array 
		{
			var list:Array = [];
			for (var pluginId:String in _plugins) 
			{
				if (_plugins[pluginId] is IPlugin) 
				{
					list.push(pluginId);
				}
			}
			return list;
		}
		
		
		public function getPlugin(id:String):IPlugin 
		{
			return _plugins[id] as IPlugin;
		}
		
		
		public function bringPluginToFront(id:String):void 
		{
			var plugin:IPlugin = getPlugin(id);
			_pluginsLayer.setChildIndex(plugin as DisplayObject, _pluginsLayer.numChildren - 1);
		}
		
		private var _videoObject:Object= new Object();
		
		private var _imdADVideoLayer:MovieClip=new MovieClip();
		
		private var _panoVideoNav:PanoVideoNav;
		
		//将媒体层添加到视频层  层级colowap
		protected function mediaLoaded(evt:MediaEvent):void 
		{
			if(!evt.metadata.hasOwnProperty("videoType"))//如果非rtmp流
			{
				var disp:DisplayObject = _model.media.display;
				if (disp && disp.parent != _mediaLayer) 
				{
					while (_mediaLayer.numChildren) 
					{
						_mediaLayer.removeChildAt(0);
					}
					
					if(_player.config.isvr)
					{
						if(_panoVideoNav==null)
						{
							_panoVideoNav=new PanoVideoNav(2048, 1024);
							_imageLayer.visible=false;
							_mediaLayer.visible=false;
							_backgroundLayer.visible=false;
							
						}
						
						
						_panoVideoNav.videoInfo.container=_model.media.display;
						_mediaLayer.addChild(_panoVideoNav);
						
					}
					else
					{
						_mediaLayer.addChild(_model.media.display);
					}
					
					_model.media.VideoResize(_player.config.width, _player.config.height,"video");
				}
				
				return;
			}
			
			if(evt.metadata.videoType=="video" && !_videoAdd)
			{
				_mediaLayer.x = _components.display.x;
				_mediaLayer.y = _components.display.y;
				
				if(_model.media.display) 
				{
					_model.media.VideoResize(_player.config.width,_player.config.height,"video");
					_mediaLayer.addChild(_model.media.display);
					_videoAdd=true;
				}
			}
			else if(evt.metadata.videoType=="ad")//视频广告
			{
				if(!_videoADAdd)
				{
					_videoADAdd = true;
					
					_imdADVideoLayer.x = _components.display.x;
					_imdADVideoLayer.y = _components.display.y;
					
					_model.adMedia.VideoResize(_player.config.width,_player.config.height);
					
					_imdADVideoLayer.addChild(_model.adMedia.adDisplay);
				}
				else
				{
					_imdADVideoLayer.visible = true;
				}
			}
			
			//			//添加视频广告层
			//			_imdADVideoLayer.x = _components.display.x;
			//			_imdADVideoLayer.y = _components.display.y;
			//			
			//			_model.adMedia.AdVideoResize(_player.config.width,_player.config.height);
			//			
			//			_imdADVideoLayer.addChild(_model.adMedia.adDisplay);
		}
		
		
		public function Vr360start():void
		{
			_panoVideoNav.StartInitDraw();
		}
		
		private var _videoAdd:Boolean = false;
		private var _videoADAdd:Boolean = false;
		private var _addControlPanel:Boolean = false;//是否添加控制面板
		
		
		/*protected function itemHandler(evt:PlaylistEvent):void 
		{
		while (_mediaLayer.numChildren) 
		{
		_mediaLayer.removeChildAt(0);
		}
		
		if (_model.playlist.currentItem && _model.playlist.currentItem.image) 
		{
		
		loadImage(_model.playlist.currentItem.image);
		}
		
		InitCompleteHandler();
		}*/
		
		
		protected function itemHandler(evt:PlaylistEvent):void 
		{
			while (_mediaLayer.numChildren) 
			{
				_mediaLayer.removeChildAt(0);
			}
			
			
			InitCompleteHandler();
		}
		
		
		private var adDownConterTimer:Timer = new Timer(1000);
		
		
		//private var adtimelen:int=3;//倒计时时间
		
		private function AdTimeHandler(e:TimerEvent):void
		{
//暂时			if(adtimelen==0)
//			{
//				adDownConterTimer.stop();
//				
//				_player.play();//player中也有控制
//				trace("谷歌广告倒计时结束");
//				googleadplayer.visible =false;
//				_mediaLayer.visible =true;//视频层
//			}
//			else
//			{
//				adtimelen--;
//				downAdtxt.text="广告倒计时"+adtimelen+"秒";
//			}
		}
		
		private var adloader:Loader=new Loader();
		
		private function RequestGoogleAD():void
		{
			Security.allowDomain("pagead2.googlesyndication.com");
			////加载广告资源文件
			var request:URLRequest=new URLRequest("http://pagead2.googlesyndication.com/pagead/scache/googlevideoadslibraryas3.swf");
			
			adloader.contentLoaderInfo.addEventListener(Event.COMPLETE, sendVideoAdRequest);
			adloader.load(request);
			//加载广告资源文件SWF
			googleadplayer.addChild(adloader);
			googleadplayer.addChild(downAdtxt);
			RootReference.stage.addChildAt(googleadplayer,RootReference.stage.numChildren);
			
			var tefor:TextFormat = new TextFormat();
			tefor.size =20;
			tefor.color =0x00ff00;
			downAdtxt.text ="广告loading";
			downAdtxt.defaultTextFormat = tefor;
			
			downAdtxt.width =640;
			//初始化广告定位
			googleadplayer.x=(RootReference.stage.stageWidth-640)/2;
			googleadplayer.y=(RootReference.stage.stageHeight-480)/2;
		}
		
		
		
		private var googleadplayer:MovieClip = new MovieClip();
		private var miniadplayer:MovieClip = new MovieClip();
		
		private var downAdtxt:TextField = new TextField();
		
		private var swfTime:uint=100;//播放广告时间
		private var pcTime:uint=0;//播放时间
		private var intervalId:uint;
		
		
		
		private var adWidth:Number=640;
		private var adHeight:Number=480;
		private var _googleAds:Object;
		private var request:Object;
		//发送广告请求
		private function sendVideoAdRequest(event:Event):void 
		{
			// 创建请求参数对象
			_googleAds=event.target.content;
			request=new Object();
			
			// [必需的]每个游戏独有的标识符，即游戏名称。
			request.contentId="4455765996";
			//[必需的]发布者ID，固定的值为：ca-games-pub-9606551472994074
			request.publisherId="ca-video-pub-1538602478919967";
			// [必需的]广告显示区域的宽度
			request.pubWidth=adWidth;
			// [必需的]广告显示区域的高度
			request.pubHeight =this.adHeight;
			// [必需的]广告展示的类型，默认设置“fullscreen”，“fullscreen”为文本和图片形式,“video”为视频模式
			request.adType="fullscreen";
			// [必需的]游戏描述页,广告会自动对descriptionUrl进行内容匹配，用于游戏定位使用。
			//request.descriptionUrl="http://www.4399.com/flash/6847.htm";
			// [必需的]发布渠道数组，值为开发者申请的渠道号
			request.channels=["1963948595"];
			
			request.maxTotalAdDuration = 10000; //视频
			//请求广告
			downAdtxt.text="广告loading";
			_googleAds.requestAds(request, onVideoAdsRequestResult);
		}
		
		private var player:MovieClip;
		
		private function onVideoAdsRequestResult(callbackObj:Object):void 
		{
			//请求成功则显示广告 
			//  * callbackObj.success 请求广告成功返回true
			//  * callbackObj.errorMsg 广告请求可能发生的错误消息
			if (callbackObj.success) 
			{
				// [必须的] 提取广告影片剪辑
				if(player!=null)
				{
					
					player.destroy();
					//downAdtxt.text="播放destroy"
				}
				
				player=callbackObj.ads[0].getAdPlayerMovieClip();
				// [必须的] 设置广告影片剪辑的尺寸
				player.setSize(adWidth,this.adHeight);
				// [必须的] 设置广告影片剪辑显示的X位置
				player.setX(0);
				// [必须的] 设置广告影片剪辑显示的Y位置
				player.setY(0);
				// [必须的] 加载广告
				player.load();
				player.onAdEvent=doOnAdEvent;
				//player.disableContentControls=toggleControls;
				//player.enableContentControls=toggleControls;
				
				// [必须的] 播放广告
				//prerollPlayer.playAds();
				
				// [必须的] 播放广告
				player.playAds();
				
				//downAdtxt.text="播放广告";
				
				if(adloader.name=="pause")
				{
					//downAdtxt.text="播放pause";
					var aadpl:* = googleadplayer;
					var uidr:uint = setTimeout(function Delydf():void
					{
						aadpl.visible = true;
						flash.utils.clearTimeout(uidr);
					},500);
					
					
				}
				else
				{
					//广告倒计时
//	暂时				adDownConterTimer.addEventListener(TimerEvent.TIMER,AdTimeHandler);
//					downAdtxt.text="广告倒计时"+adtimelen+"秒";
//					adDownConterTimer.start();
					
				}
			} 
			else 
			{
				// 打印错误信息
				loadImage("01.jpg");
				trace("Error: " + callbackObj.errorMsg);
			}
		}
		
		private function timerHandler():void
		{
			pcTime++;
			trace("播放时间:" + swfTime + "\n");
			trace("pctime:" + pcTime + "\n");
			if (pcTime >= swfTime)
			{
				
				//removeChild(bar);
			}
		}
		
		private function doOnAdEvent(e:String):void 
		{
			trace("EVENT: " + e);
			//downAdtxt.text="暂停事件EVENT: " + e;
			
		}
		
		private function InsertVideoAD():void
		{
			imageLayer.visible = false;
			//清除大播放图标
			var disComponent:DisplayComponent = components.display as DisplayComponent;
			disComponent.clearDisplay();
			
			//广告时间隐藏控制面板
			
			//广告地址
			//InsertHttpADVideo("http://movie.ks.js.cn/flv/2012/02/6-1.flv",0);
			//"http://115.236.102.164/sohu/4//131/4/yIOocTzyLfhywIdPuHykD5.mp4?key=Laa42Bnl3Pn2_GvsdCczloiZO0F7_nfpmDZlpp-Fipo."
			InsertHttpADVideo(_player.config.frontadurl,0);
		}
		
		
        private var lastLocalTime:Number=0;//用户本机保存的上次看的时间
		private function InitCompleteHandler():void
		{
			//初始化完毕
			trace("初始化完毕");
			//控制面板按钮位置调整(貌似与fla无关，好像已timeSlider为基准)

			
			//视频前请求加载图片广告
			//loadImage(_model.playlist.currentItem.image);
			//loadImage("557.jpg");
			//视频前请求加载谷歌广告
			//RequestGoogleAD();
			//_player.play();//自动播放
			RootReference._player = this._player as Player;
			
			mySo = SharedObject.getLocal("saveData");
//暂时			
//			if(mySo.data[RootReference.flashvarObject['flvid']]==undefined)//不存在
//			{
//				//trace(lastLocalTime);
//			}
//			else//上次有保存
//			{
//				lastLocalTime =Number(mySo.data[RootReference.flashvarObject['flvid']]);
//				//trace(lastLocalTime);
//			}
			
			//保存记忆播放开始
			//saveTimeTimer.addEventListener(TimerEvent.TIMER,SaveTimeHandler);
			//saveTimeTimer.start();
			
			//加载自定义视频广告

			
			
			
			
			
			if(_player.config.havead==true)
			{
				adTime= _player.config.adtime;
				InsertVideoAD();//插入广告
			}
			else//无广告开始播放
			{
		
				//开始播放
				_imdADVideoLayer.visible = false;
//				if(this.lastLocalTime>0)
//				{
//					seekuint = flash.utils.setTimeout(DelayMp4Seek,1000);
//				}
				
				//_player.play();
				
			}
			
			//vdtztxt.visible = false;
			RootReference._player = this._player as Player;
			
			if(!_addControlPanel)
			{
			    _addControlPanel=true;
				//加了切码流按钮
				(_player as Player).controller._bufferBeforeURL = _model.playlist.currentItem.file;
				//初始化隐藏控制面板
				//(components.controlbar as ControlbarComponentV4).visible =false;
				//保存上次播放时间
				//StartPlayVideo();
				
				//ExternalInterface.call(CallJSFunction.VIDEOLOAD,CallJSFunction.VIDEOLOAD_PARAMETER);
			}
			
			//ExternalInterface.call("swf_init");
			
			lineNumTxt= new TextField();
			
			var txtFormat:TextFormat= new TextFormat();
			
			lineNumTxt.selectable=false;
			lineNumTxt.width=500;
			txtFormat.font="微软雅黑";
			txtFormat.color=0xffffff;
			txtFormat.size=15;
			lineNumTxt.defaultTextFormat =txtFormat;
			
			RootReference.stage.addChild(lineNumTxt);
		}
		
		private var saveTimeTimer:Timer = new Timer(2000);
		//private var savelastname:String; 
		//保存上次播放时间
		private function StartPlayVideo():void
		{
			//自动播放
			_player.play();//player中也有控制
			initpause = true;
			_player.pause();
			
			_mediaLayer.visible =false;//视频层
			
		}
		
		private var savePlayTime:Number=0;
		
		private function SaveTimeHandler(e:TimerEvent):void
		{
			savePlayTime = (components.controlbar as ControlbarComponentV4).GetSliderPlayertime();
			mySo.data[RootReference.flashvarObject['flvid']] = savePlayTime+2;
			trace("savePlayTime:::"+savePlayTime);
            mySo.flush();
		}
		
		
		private function DelaySeek():void
		{
			//trace(savePlayTime);
			(_player as Player).controller.seek(savePlayTime);
			flash.utils.clearTimeout(uidf);
		}
		
		private var uidf:uint;
		private var mySo:SharedObject;
		//加载广告
		public function loadImage(url:String):void 
		{
			while (_imageLayer.numChildren) 
			{
				_imageLayer.removeChildAt(0);
			}
			_imageLoader.unload();
			//图片广告层(预览图片也在这一层)
			_imageLoader.load(new URLRequest(url), new LoaderContext(true));
		}
		
		
		
		
		protected function imageComplete(evt:Event):void 
		{
			if (_imageLoader) 
			{
				_imageLayer.addChild(_imageLoader);
				//trace(_imageLoader.content.height);
				//trace(_imageLoader.height);
				//_imageLayer.x = _components.display.x;//和视频一样的位置
				//_imageLayer.y = _components.display.y;
//				_imageLoader.width =RootReference.stage.stageWidth;
//				_imageLoader.height =500;
				
				//缩放
				//Stretcher.stretch(_imageLoader, _player.config.width, _player.config.height, _player.config.stretching);
				//Stretcher.stretch(_imageLoader,_imageLoader.width,_imageLoader.height, _player.config.stretching);
				//trace(RootReference.stage.stageWidth);
				//trace(_imageLoader.width);
				//trace(RootReference.stage.stageHeight-AssetURL._controlBarHeight);
				
				var widthper:Number=RootReference.stage.stageWidth/_imageLoader.width;//外层容器宽/原始图像与的比
				var heightper:Number = (RootReference.stage.stageHeight-RootReference._controlBarHeight)/_imageLoader.height;//外层容器高原始图像与的比
				//trace(widthper);
				//trace(heightper);
				if(widthper>heightper)//如果宽的比大于高的比
				{
					_imageLoader.width =_imageLoader.width*heightper;
					_imageLoader.height =_imageLoader.height*heightper;
				}
				else
				{
					
					_imageLoader.width =_imageLoader.width*widthper;
					_imageLoader.height =_imageLoader.height*widthper;
					
				}
				
				//trace(_imageLoader.width);
				//trace(_imageLoader.height);
				_imageLayer.x = (RootReference.stage.stageWidth-_imageLoader.width)/2;
				_imageLayer.y =((RootReference.stage.stageHeight-RootReference._controlBarHeight)-_imageLoader.height)/2;
				
				try 
				{
					Draw.smooth(_imageLoader.content as Bitmap);
				} 
				catch (e:Error) 
				{
					Logger.log('Could not smooth preview image: ' + e.message);
				}
				
				
				//trace((components.controlbar as MovieClip).height);
			}
		}
		
		
		
		protected function imageError(evt:ErrorEvent):void 
		{
			Logger.log('Error loading preview image: '+evt.text);
		}
		
		
		//层级显示
		protected function stateHandler(evt:PlayerStateEvent):void 
		{
			switch (evt.newstate) 
			{
				case PlayerState.IDLE:
					
					if(_mediaLayer.visible==false)//播放插播的视频
					{
						trace("插播视频播放完毕");
						//_imdADVideoLayer.visible = false;
						_mediaLayer.visible = true;
						_componentsLayer.visible =true;//控制按钮
						
						dispatchEvent(new ViewEvent(ViewEvent.INSERT_CLIP_END));
						return;
					}
					else
					{
						trace("节目播放完毕");
						//trace(this._model.media);
						//分段注释(this._model.media as HTTPFenDuanMediaProvider).StopMediaNetStream();
						//ExternalInterface.call("jwplayer_getNextUrl");
						
					}
					
					_componentsLayer.visible =true;
					if (_logo) _logo.visible = false;
					
					break;
				
				case PlayerState.BUFFERING:
					
				case PlayerState.PLAYING://播放
				//判断是否为空
					if (_model.media.display) 
					{
						_mediaLayer.visible = true;
						_imageLayer.visible = false;
					}
					
					//if (_logo) _logo.visible = true;
					
					this.googleadplayer.visible = false;
					_imageLayer.visible = false;
					_mediaLayer.visible =true;//视频层
					(components.controlbar as MovieClip).visible = true;//恢复控制面板
					
					break;
				
				case PlayerState.PAUSED://暂停 显示广告
					
					
					if(_player.config.havead==true)//自定义视频广告
					{
						//隐藏视频层
						//_mediaLayer.visible =false;//视频层
						if (_logo) _logo.visible = false;
						
						//暂停加载图片广告
						loadImage(_model.playlist.currentItem.image);
						
						_imageLayer.visible = true;
					}
					else//使用谷歌广告
					{
						//=======谷歌==============
						if(initpause==true)//谷歌初始暂停
						{
							initpause = false;//初始暂停后播放广告
							
							this.googleadplayer.visible = true;
						}
						else//用户暂停
						{
							//adWidth=640;
							//adHeight=480;
							
							//RequestGoogleADmini();//请求暂停广告
							//谷歌广告注释
							/*	adloader.name="pause";
							_googleAds.requestAds(request, onVideoAdsRequestResult);
							
							downAdtxt.text ="";
							this.googleadplayer.scaleX=0.8;
							this.googleadplayer.scaleY =0.8;
							
							googleadplayer.x=(RootReference.stage.stageWidth-googleadplayer.width)/2;
							googleadplayer.y=(RootReference.stage.stageHeight-googleadplayer.height)/2;
							*/
							
							trace("newState搜索这个找到响应的:::");
							_mediaLayer.visible =false;//视频层
						}
						//=======谷歌==============
					}
						
					
					
					
					
			}
		}
		private var initpause:Boolean = false;
		private var adVideoIDLE:Boolean = false;//是否有插播视频
		
		public function InsertADVideo(file:String,streamer:String,startTime:int):void
		{
			//加载广告视频内容
			var _PlaylistItem:PlaylistItem= new PlaylistItem();
			_PlaylistItem.file = file;	//http流只要文件就行
			
			_model.adMedia.load(_PlaylistItem);
			
			_componentsLayer.visible =false;
			_mediaLayer.visible = false;
			
			_model.adMedia.addEventListener("ImdVideo",ImdVideoHandler(startTime));
			
		}
		
		
		public function InsertHttpADVideo(file:String,startTime:Number=0):void
		{
			//加载广告视频内容
			/*	var _PlaylistItem:PlaylistItem= new PlaylistItem();
			_PlaylistItem.file = file;	
			RootReference.videoadBo = true//是视频广告不是视频 时间轴不动
			_model.adMedia.load(_PlaylistItem);
			
			_componentsLayer.visible =false;
			_mediaLayer.visible = false;
			//指定播放时间侦听
			//_model.adMedia.addEventListener("ImdVideo",ImdVideoHandler(startTime));
			*/
			//trace(file);
			adhttphantang = new ADhttpHantang();
			adhttphantang.initApp(file);
			this._imdADVideoLayer.addChild(adhttphantang);
			adhttphantang.addEventListener("meta",VideoHandle);
			adhttphantang.addEventListener("adstart",AdStartHandler);
		}
		
		private var adTime:int;//广告时长
		private var videoADTimer:Timer= new Timer(1000);
		private var adtxt:TextField = new TextField();
		
		private function AdStartHandler(e:Event):void
		{
			videoADTimer.addEventListener(TimerEvent.TIMER,TimerVideohandler);
			videoADTimer.start();
			_mediaLayer.visible =false;//因为记忆播放视频层隐藏
			RootReference.stage.addChildAt(adtxt,RootReference.stage.numChildren);
			
			var tefor:TextFormat = new TextFormat();
			tefor.size =20;
			tefor.color =0x00ff00;
			adtxt.defaultTextFormat = tefor;
			adtxt.width =300;
			adtxt.text ="广告还有"+adTime+"秒";
			adtxt.x= RootReference.stage.stageWidth-adtxt.textWidth-5;//5是位置微调
			showADing = true;
		}
		
		private var seekuint:uint;
		public var showADing:Boolean=false;//广告是否正在播放中
		
		private function TimerVideohandler(e:TimerEvent):void
		{
			adTime--;
			
			if(adTime<=0)
			{
				adtxt.visible = false;
				//广告结束视频开始播放
				_imdADVideoLayer.visible = false;
				if(this.lastLocalTime>0)
				{
					seekuint = flash.utils.setTimeout(DelayMp4Seek,1000);
				}
				//自定义广告开始播放
				//RootReference.flashvarObject['adtimeplay']="false";//广告或者片头正在播放完毕结束
				
				(_player as Player).controller.play();
				
				yuanshiVideoWidth=adhttphantang.width;
				yuanshiVideoHeight =adhttphantang.height;
				
				videoADTimer.stop();
				adhttphantang.StopAd();
				
				showADing=false;
			}
			else
			{
				adtxt.text ="广告还有"+adTime+"秒";
			}
		}
		
		
		
		private function DelayMp4Seek():void
		{
			flash.utils.clearTimeout(seekuint);
			_mediaLayer.visible =true;//因为记忆播放视频层
			_model.media.seek(lastLocalTime);
			
		}
		
		public var adhttphantang:ADhttpHantang;
		
		public function VideoHandle(e:Event):void
		{
				
			adhttphantang.removeEventListener("meta",VideoHandle);
			oradAdVideowidth = adhttphantang.width;
			oradAdVideoheight =adhttphantang.height;
			
			ScaleFunction(adhttphantang);
			
		}
		
		private var oradAdVideowidth:Number;
		private var oradAdVideoheight:Number;
		
		public function ScaleFunction(SwfMC:*):void
		{
			//trace(RootReference.stage);
			trace("swfffffffffff"+SwfMC);
			var widthper:Number=RootReference.stage.stageWidth/SwfMC.width;//外层容器宽/原始图像与的比
			var heightper:Number =(RootReference.stage.stageHeight-RootReference._controlBarHeight)/SwfMC.height;//外层容器高原始图像与的比
			
			if(widthper>heightper)//如果宽的比大于高的比
			{
				SwfMC.scaleX =heightper;
				SwfMC.scaleY =heightper;
			}
			else
			{
				SwfMC.scaleX =widthper;
				SwfMC.scaleY =widthper;
			}
			
			_imdADVideoLayer.x = (RootReference.stage.stageWidth-_imdADVideoLayer.width)/2;
			_imdADVideoLayer.y = ((RootReference.stage.stageHeight-RootReference._controlBarHeight)-_imdADVideoLayer.height)/2;
		
		
		}
		
		private function ImdVideoHandler(startTime:int):Function
		{
			var _fun:Function = function (e:Event):void
			{
				_model.adMedia.seek(startTime);
				e.target.removeEventListener("ImdVideo",ImdVideoHandler);
			}
			
			return _fun;
		}
		
		
		protected function forward(evt:Event):void 
		{
			if (evt is PlayerEvent)
				dispatchEvent(evt);
		}
		
		
		
	}
}