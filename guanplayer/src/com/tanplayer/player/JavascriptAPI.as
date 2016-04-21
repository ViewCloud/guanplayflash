package com.tanplayer.player 
{

	import com.events.ControllerEvent;
	import com.events.ModelEvent;
	import com.events.ViewEvent;
	import com.tanplayer.controller.Controller;
	import com.tanplayer.events.PlayerEvent;
	import com.tanplayer.media.HTTPMediaProvider;
	import com.tanplayer.media.RTMPMediaProvider;
	import com.tanplayer.model.PlaylistItem;
	import com.tanplayer.utils.Logger;
	import com.tanplayer.utils.RootReference;
	import com.tanplayer.utils.Strings;
	import com.tanplayer.components.ControlbarComponentV4;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.text.TextField;

	public class JavascriptAPI 
	{
		private static var _player:IPlayer;
		private var _emu:PlayerV4Emulation;

		private var controllerCallbacks:Object;		
		private var modelCallbacks:Object;		
		private var viewCallbacks:Object;		
        private var _skin:Sprite;
		
		public function JavascriptAPI(player:IPlayer,skin:Sprite) 
		{
			_player = player;
			_player.addEventListener(PlayerEvent.JWPLAYER_READY, playerReady);
			_emu = PlayerV4Emulation.getInstance(_player);
			_skin = skin;
			controllerCallbacks = {};
			modelCallbacks = {};
			viewCallbacks = {};
			setupListeners();
		}
		
	    private function playerReady(evt:PlayerEvent):void 
		{
			var callbacks:String = _player.config.playerready ? _player.config.playerready + "," + "playerReady" : "playerReady";  

			if (ExternalInterface.available) 
			{
				for each (var callback:String in callbacks.replace(/\s/,"").split(",")) 
				{
					try 
					{
						ExternalInterface.call(callback,{
							id:evt.id,
							client:evt.client,
							version:evt.version
						});
					} 
					catch (e:Error) 
					{
					
					}
				}
			}			
		}
		
		
		
		private function setupListeners():void 
		{
			try 
			{
				ExternalInterface.addCallback("addControllerListener",addJSControllerListener);
				ExternalInterface.addCallback("addModelListener",addJSModelListener);
				ExternalInterface.addCallback("addViewListener",addJSViewListener);
				ExternalInterface.addCallback("removeControllerListener",removeJSControllerListener);
				ExternalInterface.addCallback("removeModelListener",removeJSModelListener);
				ExternalInterface.addCallback("removeViewListener",removeJSViewListener);
				ExternalInterface.addCallback("getConfig",getConfig);
				ExternalInterface.addCallback("getPlaylist",getPlaylist);
				ExternalInterface.addCallback("getPluginConfig",getJSPluginConfig);
				ExternalInterface.addCallback("loadPlugin",loadPlugin);
				ExternalInterface.addCallback("sendEvent",sendEvent);
				//图片广告
				ExternalInterface.addCallback("jwplayer_insertAD",InsertImageAD);
				//切换码流
				ExternalInterface.addCallback("jwplayer_ChangeKbps",ChangeKbpsHandler);
				//视频广告
				ExternalInterface.addCallback("jwplayer_insertClip",JwplayerinsertClipHandler);
				//查询播放状态
				ExternalInterface.addCallback("jwplayer_queryPlayStatus",Jwplayer_queryPlayStatusHandler);
				//自动播放
				ExternalInterface.addCallback("jwplayer_autoPlay",Jwplayer_autoPlayHandler);
				//播放
				ExternalInterface.addCallback("jwplayer_Play",JwplayerPlayHandler);
				//暂停
				ExternalInterface.addCallback("jwplayer_Pause",JwplayerPauseHandler);
				//快进
				ExternalInterface.addCallback("jwplayer_FastPlayer",JwplayerFastPlayerHandler);
				//快退
				ExternalInterface.addCallback("jwplayer_SlowPlayer",JwplayerSlowPlayerHandler);
				//切换下一集
				ExternalInterface.addCallback("jwplayer_NextPlayer",JwplayerChangeNextPlayerHandler);
				//JS舞台大小更改通知Flash
				ExternalInterface.addCallback("layoutChange",Jwplayer_stageResizeHandler);
				
				//rtmp直播流换成red5服务器
				ExternalInterface.addCallback("red5Services",Red5ServicesHandler);
				ExternalInterface.addCallback("p2pServices",P2pServicesHandler);

			} 
			catch(e:Error) 
			{
				Logger.log("Could not start up JavasScript API: " + e.message);
			}
		}
		
		private function Red5ServicesHandler():void
		{
			trace("red5");
			//((_player as Player).model.media as RTMPMediaProvider).ChangeRed5Services();
			
		}
		
		private function P2pServicesHandler():void
		{
			trace("p2p");
		//((_player as Player).model.media as RTMPMediaProvider).ChangeP2pServices();
			
		}
		
		
		
		
		
		
		
		private function JwplayerChangeNextPlayerHandler(videoId:String):void
		{
			(_player as Player).controller.initJsonEnd=false;
			(_player as Player).controller.MovieReset(videoId);
			(_player as Player).controller.stop();
			(_player as Player).controller.GetVideoJsonhandler();
		}
		
		
		private function JwplayerFastPlayerHandler():void
		{
			((_player as Player).model.media as HTTPMediaProvider).StartFastPlay();
		}
		
		private function JwplayerSlowPlayerHandler():void
		{
			((_player as Player).model.media as HTTPMediaProvider).StartSlowPlay();
			
		}
		
		private function JwplayerPauseHandler():void
		{
			
			(_player as Player).controller.pause();
		}
		
		private function JwplayerPlayHandler():void
		{
			//if(RootReference.flashvarObject['adShowing']=="true") return;
			(_player as Player).controller.play();
		}
		
		private function Jwplayer_stageResizeHandler(type:String):void
		{
			
			
			if(type=="small")
			{
				CallJSFunction.PLAYMODE = "small";
				//((_player.controls.controlbar as ControlbarComponentV4).getSkinComponent("resizeBtn") as MovieClip).gotoAndStop(1);
				
			}
			else
			{
				CallJSFunction.PLAYMODE = "big";
				//((_player.controls.controlbar as ControlbarComponentV4).getSkinComponent("resizeBtn") as MovieClip).gotoAndStop(3);
					
			}
			
			CallJSFunction.JS_CHANGE_TO=CallJSFunction.PLAYMODE;
		}
		
	    private function Jwplayer_autoPlayHandler():void
		{
			(_player as Player).controller.playHandler();
		}
		
		private function InsertImageAD(str:String):void
		{
			
			(_player as Player).view.imageLayer.visible = true;
			(_player as Player).view.mediaLayer.visible = false;
			(_player as Player).controller.pauseHandler();
			//trace(str);
			(_player as Player).view.loadImage(str);
		}
		
		
	/*	private function JwplayerinsertClipHandler(url:String, startTime:int, 
													endTime:String, callback:String):void
		{
			(_player as Player).view._adType="VideoAd";
			(_player as Player).controller.pauseHandler();
			
			var num:int = url.lastIndexOf("*");
			var file:String = "http://pseudo01.hddn.com/vod/demo.flowplayervod/Extremists.flv";
			var streamer:String = url.slice(0,num);
			
			(_player as Player).view.imageLayer.visible = false;
			(_player as Player).view.InsertADVideo(file,streamer,startTime);
			(_player as Player).view.addEventListener(com.longtailvideo.jwplayer.events.ViewEvent.INSERT_CLIP_END,InsertEndHandler(callback));
		}*/
		
		
		//视频广告
		private function JwplayerinsertClipHandler(url:String="http://119.147.159.81/youku/677317E27CC47829F4EE953E77/030002070051202BECCC9B035FA458368CC60E-3C0A-B3FA-7706-2D90B89E30CD.flv", startTime:Number=0, 
												   endTime:Number=0, callback:String=""):void
		{
			
			(_player as Player).controller.pauseHandler();
			
			var num:int = url.lastIndexOf("*");
			var file:String =url;
				
			var streamer:String = url.slice(0,num);
			
			(_player as Player).view.imageLayer.visible = false;
			(_player as Player).view.InsertADVideo(file,streamer,startTime);
			(_player as Player).view.addEventListener(com.tanplayer.events.ViewEvent.INSERT_CLIP_END,InsertEndHandler(callback));
		}
		
		
		private function InsertEndHandler(str:String):Function
		{
			var _fun:Function = function (e:Event):void
			{
				(_player as Player).view.removeEventListener(com.tanplayer.events.ViewEvent.INSERT_CLIP_END,InsertEndHandler);
				
				var ob:Object = new Object();
				ob.orgurl=(_player as Player).model._currentPlayURL;
				//控制按钮层
				ob.orgplayTime=ControlbarComponentV4((_player as Player).view._componentsLayer.getChildAt(3)).currentImdTime;
				
				ExternalInterface.call(str,ob);
			}
			return _fun;
		}
		
		//拼装播放地址
		public static function ChangeKbpsHandler(url:String, startTime:Number=0):void
		{
			var _PlaylistItem:PlaylistItem = new PlaylistItem();
			_PlaylistItem.file = url;	
			
			//执行切码流
			(_player as Player).controller.URLPlay(_PlaylistItem,startTime);
			
		}
		
		private function Jwplayer_queryPlayStatusHandler(callback:String):void
		{
			var ob:Object = new Object();
			ob.playUrl = _emu.config.streamer+_emu.config.file;
			ob.playTime = (_skin.getChildByName('elapsedText') as TextField).text;
			ob.status = "good";
			ExternalInterface.call(callback,ob);
		}
		
		private function addJSControllerListener(type:String,callback:String):Boolean 
		{
			type = type.toUpperCase();
			if (!controllerCallbacks.hasOwnProperty(type)) { controllerCallbacks[type] = []; }
			if ( (controllerCallbacks[type] as Array).indexOf(callback) < 0) {
				(controllerCallbacks[type] as Array).push(callback);
				_emu.addControllerListener(type, forwardControllerEvents);
			}
			return true;
		}
		
		private function removeJSControllerListener(type:String,callback:String):Boolean 
		{
			type = type.toUpperCase();
			var listeners:Array = (controllerCallbacks[type] as Array);
			var idx:Number = listeners ? listeners.indexOf(callback) : -1; 
			if (idx >= 0) {
				listeners.splice(idx, 1);
				_emu.removeControllerListener(type.toUpperCase(), forwardControllerEvents);
				return true;
			} 
			return false;
		}


		private function addJSModelListener(type:String,callback:String):Boolean {
			type = type.toUpperCase();
			if (!modelCallbacks.hasOwnProperty(type)) { modelCallbacks[type] = []; }
			if ( (modelCallbacks[type] as Array).indexOf(callback) < 0) {
				(modelCallbacks[type] as Array).push(callback);
				_emu.addModelListener(type, forwardModelEvents);
			}
			return true;
		}
		
		private function removeJSModelListener(type:String,callback:String):Boolean 
		{
			type = type.toUpperCase();
			var listeners:Array = (modelCallbacks[type] as Array);
			var idx:Number = listeners ? listeners.indexOf(callback) : -1; 
			if (idx >= 0) {
				listeners.splice(idx, 1);
				_emu.removeModelListener(type.toUpperCase(), forwardModelEvents);
				return true;
			} 
			return false;
		}


		private function addJSViewListener(type:String,callback:String):Boolean {
			type = type.toUpperCase();
			if (!viewCallbacks.hasOwnProperty(type)) { viewCallbacks[type] = []; }
			if ( (viewCallbacks[type] as Array).indexOf(callback) < 0) {
				(viewCallbacks[type] as Array).push(callback);
				_emu.addViewListener(type.toUpperCase(), forwardViewEvents);
			}
			return true;
		}
		
		private function removeJSViewListener(type:String,callback:String):Boolean {
			type = type.toUpperCase();
			var listeners:Array = (viewCallbacks[type] as Array);
			var idx:Number = listeners ? listeners.indexOf(callback) : -1; 
			if (idx >= 0) {
				listeners.splice(idx, 1);
				_emu.removeViewListener(type.toUpperCase(), forwardViewEvents);
				return true;
			} 
			return false;
		}

		private function getConfig():Object {
			return stripDots(_emu.config);
		}
		
		private function stripDots(obj:Object):Object {
			var newObj:Object = (obj is Array) ? new Array() : new Object();
			for (var i:String in obj) {
				if (i.indexOf(".") < 0) {
					if (typeof(obj[i]) == "object") {
						newObj[i] = stripDots(obj[i]);
					} else {
						newObj[i] = obj[i];
					}
				}
			}
			return newObj;
		}
		
		private function getPlaylist():Object {
			var arry:Array = [];
			for each (var obj:Object in _emu.playlist) {
				arry.push(stripDots(obj));
			}
			return arry;
		}
		
		private function getJSPluginConfig(pluginId:String):Object {
			return _player.config.pluginConfig(pluginId);
		}
		
		private function loadPlugin(plugin:String):Object {
			return {error:'This function is no longer supported.'}
		}
		
		private function sendEvent(type:String, data:Object = null):void {
			_emu.sendEvent(type.toUpperCase(), data);
		}
		
		private function forwardControllerEvents(evt:ControllerEvent):void 
		{
			if (controllerCallbacks.hasOwnProperty(evt.type)) 
			{
				for each (var callback:String in controllerCallbacks[evt.type]) 
				{
					if (ExternalInterface.available) 
					{
						ExternalInterface.call(callback, stripDots(evt.data));
					}
				}
			}
		}

		private function forwardModelEvents(evt:ModelEvent):void 
		{
			if (modelCallbacks.hasOwnProperty(evt.type)) 
			{
				for each (var callback:String in modelCallbacks[evt.type]) 
				{
					if (ExternalInterface.available) 
					{
						ExternalInterface.call(callback, stripDots(evt.data));
					}
				}
			}
		}

		private function forwardViewEvents(evt:ViewEvent):void 
		{
			if (viewCallbacks.hasOwnProperty(evt.type)) 
			{
				for each (var callback:String in viewCallbacks[evt.type]) 
				{
					if (ExternalInterface.available) 
					{
						ExternalInterface.call(callback, stripDots(evt.data));
					}
				}
			}
		}

	}

}