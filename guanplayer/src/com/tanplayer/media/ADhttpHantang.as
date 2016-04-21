package com.tanplayer.media
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;

	public class ADhttpHantang extends Sprite
	{
		public function ADhttpHantang()
		{
		
		}
		
		
		
		private var nc:NetConnection;
		private var ns:NetStream;
		private var video:Video;
		private var meta:Object;
		private var paretnmc:*;
		public function initApp(url:String):void 
		{
			var nsClient:Object = {};
			nsClient.onMetaData = ns_onMetaData;
			nsClient.onCuePoint = ns_onCuePoint;  
			
			nc = new NetConnection();
			nc.connect(null);
			
			ns = new NetStream(nc);
			ns.play(url);
			ns.client = nsClient;
			
			video = new Video();
			video.attachNetStream(ns);
			this.addChild(video);
			
			ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler11);
		}
		
		private function netStatusHandler11(event:NetStatusEvent):void 
		{
			trace("event.info.code:::"+event.info.code);
			
			switch (event.info.code) 
			{
				case "NetStream.Play.Start" :
				//开始广告倒计时
				this.dispatchEvent(new Event("adstart"));
				break;
			}
		}
		
		private function ns_onMetaData(item:Object):void {
			trace("meta");
			meta = item;
			// Resize Video object to same size as meta data.
			video.width =item.width;
			video.height =item.height;
			//trace(video.width);
			// Resize UIComponent to same size as Video object.
			this.dispatchEvent(new Event("meta"));
		}
		
		public function StopAd():void
		{
			ns.close();
		}
		
		
		
		private function ns_onCuePoint(item:Object):void 
		{
			trace("cue");
		}
	}
}