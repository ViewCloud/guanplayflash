package
{
	import com.tanplayer.player.CallJSFunction;
	import com.tanplayer.player.Player;
	import com.tanplayer.utils.Configger;
	import com.tanplayer.utils.RootReference;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.text.*;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	import org.danmu.event.EventBus;
	import org.danmu.event.MukioEvent;
	
	
	public class TanVodPlayer extends Player
	{
		public function TanVodPlayer()
		{
			
			super();
			
//			if(loaderInfo.hasOwnProperty("uncaughtErrorEvents"))
//			{
//				IEventDispatcher(loaderInfo["uncaughtErrorEvents"]).addEventListener("uncaughtError", GlobalUncaughtErrorHandler);
//			}
			
			//view.as中的root是所有播放器内元素的最底层,会把他加在最底层RootReference.stage.addChildAt(_root, 0);。
			
			//var swfurl:String =this.loaderInfo.url;//获取url网址
			//swfurl=swfurl.replace("TanPlayer.swf","GgPlugin.swf");
			//trace(swfurl);
			
			
			//var ddf:Timer=new Timer(1000);
			//ddf.addEventListener(TimerEvent.TIMER,TimsfsfHandler);
			//ddf.start();
			
			//stage.quality=StageQuality.LOW;
			//stage.frameRate=60;
		}
		
		
		
//		private var adSwfLoad:Loader;
//		public var currentPlugin:Object;
//		
//		private var pluginLoader:URLLoader = new URLLoader();
//		
//		public function LoadPlugin(url:String):void
//		{
//			adSwfLoad=new Loader();
//			adSwfLoad.contentLoaderInfo.addEventListener(Event.COMPLETE,PluginCompleteHandler);
//			
//			adSwfLoad.load(new URLRequest(url));
//			
//			
//		}
		
//		private function PluginCompleteHandler(e:Event):void
//		{
//			this.stage.addChildAt(adSwfLoad,stage.numChildren);
//			//trace(e.target.content);
//			currentPlugin=e.target.content;
//			
//			var ob:Object=loaderInfo.parameters;
//			
//			
//			
//			currentPlugin.InitPlugin("https://uapi.guancloud.com/1.2/videos/"+loaderInfo.parameters["videoid"]+"/annotations");
//		}
		
		//=======swf壳调用这个接口传变量进来start=======================
		public function GetSwfParam(ob:Object=null):void
		{
			RootReference.flashvarObject=ob;
			
			setupPlayer();
		}
		
		private function TimsfsfHandler(e:TimerEvent):void
		{
			SendTanMu();
		}
		
		public function SendTanMu(txt:String=""):void
		{
			var data:Object={};
			data.type = 'normal';
			data.text = "xsdfsdf";
			data.color = 0x00ff00;
			data.size = 20;
			data.mode="1";
			
			EventBus.getInstance().sendMukioEvent(MukioEvent.DISPLAY,data);
		}
		
		//捕获全局错误（初始化的可能捕捉不到，后面的可以）
//		private function GlobalUncaughtErrorHandler(e:Event):void 
//		{
//			ExternalInterface.call(CallJSFunction.CRASHCALLBACKFUNCTIONNAME,CallJSFunction.CRASHCALLBACKFUNCTIONNAME_PARAMETER);
//		}
		
	}
}