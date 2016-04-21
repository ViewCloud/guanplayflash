package  com.tanplayer.utils 
{
	import com.tanplayer.utils.RootReference;
	
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.getTimer;
	
	
	public class TanBandwidthCheck extends EventDispatcher
	{
		public var _url:String;
		public var debug:Boolean = false;
		
		private var _speed:Number;
		private var _startTime:Number;
		private var _loader:Loader;
		public static const SUCCESS:String = 'success';
		
		public function TanBandwidthCheck() 
		{
			
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, DownloadCompleteHandler);
			_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, IOErrorEventHandler);
			//_loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			
		
		}
		
		public function get speed():Number 
		{
			return _speed;
		}
		
		public var isTested:Boolean=false;
		
		public function start():void 
		{
			dispatchEvent(new Event(TanBandwidthCheck.SUCCESS));//临时这样改
		
			
//			_url = "http://plutotest.tan14.net/speedtest/random350x350.jpg";
//			 
//			_url += "?id="+(Math.random()).toString();
//			
//			//trace(_url);
//			_startTime = getTimer();
//			
//			_loader.unload();
//			_loader.load(new URLRequest(_url));
//			
			isTested=true;
		}
		
		private function progressHandler(evt:ProgressEvent):void 
		{
			
			//var loadProcess:Number = evt.bytesLoaded / evt.bytesTotal;
			
			//dispatchEvent(evt);
		}
		
		private var totalint:Number=0;
		private var aArr:Array=[];
		
		private function DownloadCompleteHandler(evt:Event):void 
		{
			var endTime:Number = getTimer();
			var totalTime:Number = (endTime - _startTime)/1000;
			var totalKb:Number =evt.currentTarget.bytesTotal*8/1024;
			
			_speed = totalKb/totalTime;
			
			aArr.push(_speed);
			trace("total time：" + totalTime + " totalKb：" + totalKb + " speed：" + _speed);
			totalint++;
			trace("跑了:::"+totalint+"次");
			
			if(totalint>=2)
			{
				FinallyBandWidth(evt);
			}
			else
			{
				start();
			}
			
			
		}
		
		private function AvgBandWidth():Number
		{
			var total:Number = 0;
			var len:Number = aArr.length;
			
			while(len--)
			{
				total+=aArr[len];
			}
			
			return Math.round(total/aArr.length);
		}
		
		private function IOErrorEventHandler(evt:IOErrorEvent):void 
		{
			trace("error");
			FinallyBandWidth();
		}
		
		private function FinallyBandWidth(evt:Event=null):void
		{
			var num:Number=AvgBandWidth();
			trace("Na：：："+num);
			RootReference._bandWidth=num;
			
			if (num<1024)
			{
				trace("最终带宽：：："+num.toFixed(0) + "kbp/s");
			}
			else
			{
				trace("最终带宽：：："+(num/1024).toFixed(1) + "Mbp/s");
			}
			
			
			dispatchEvent(new Event(TanBandwidthCheck.SUCCESS));
			
		}
	}

}