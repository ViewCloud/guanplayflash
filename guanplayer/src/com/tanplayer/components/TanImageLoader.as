package com.tanplayer.components
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class TanImageLoader extends Sprite
	{
		
		private static var singleton:TanImageLoader;
		private static var key:Boolean=false;
		
		private var loader:Loader;
		
		
		public static function getInstance():TanImageLoader
		{
			if(singleton==null)
			{
				key=true;
				singleton = new TanImageLoader();
			}
			
			return singleton;
		}
		
		private var wi:Number=100;
		private var he:Number=80;
		
		public function TanImageLoader()
		{      
			if(!key)
			{
				throw new Error ("单例,请用 getInstance() 取实例。");
			}
			
			this.graphics.beginFill(0x000000,1);
			this.graphics.drawRect(0,0,wi,he);
			this.graphics.endFill();
			
			loader = new Loader();
			
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ErrorHandler);
			this.addChild(loader);
			
			var tf:TextFormat=new TextFormat();
			tf.color=0xffffff;
			tf.font="Microsoft yahei";
			txt=new TextField();
			
			txt.selectable=false;
			txt.defaultTextFormat=tf;
			
			this.addChild(txt);
			
			txt.width=txt.textWidth+3;
			txt.height=txt.textHeight+3;
			
			key=false;
		}
		
		private function ErrorHandler(e:ErrorEvent):void
		{
			trace("地址错误了"+loader.contentLoaderInfo.url);
			
		}
		
		private var txt:TextField;
		
		private var bitmap:Bitmap=new Bitmap(); 
		
		public function LoaderImage(url:String):void
		{
			loader.unload();
			loader.unloadAndStop(true);
			
			loader.load(new URLRequest(url));
		}
		
		
		public function ShowTxt(str:String):void
		{
			txt.text=str;
			
			
			txt.width=txt.textWidth+3;
			txt.height=txt.textHeight+3;
			
			
			txt.x=(wi-txt.textWidth)/2;
			txt.y=-txt.height;
		}
		
		private function progressHandler(e:ProgressEvent):void 
		{
			var num:uint = (e.bytesLoaded / e.bytesTotal) * 100;
			//trace('已加载--' + num + "%");
		}
		
		private function completeHandler(e:Event):void 
		{
			ScaleSWF(loader,this);
		}
		
		
		public function ScaleSWF(SwfMC:*,parent:*):void
		{
			
			var widthper:Number=wi/SwfMC.width;//外层容器宽/原始图像与的比
			var heightper:Number = he/SwfMC.height;//外层容器高原始图像与的比
			
			if(widthper>heightper)//如果宽的比大于高的比
			{
				SwfMC.width =SwfMC.width*heightper;
				SwfMC.height =SwfMC.height*heightper;
			}
			else
			{
				SwfMC.width =SwfMC.width*widthper;
				SwfMC.height =SwfMC.height*widthper;
			}
			
			SwfMC.x=(wi-SwfMC.width)/2;
			SwfMC.y=(he-SwfMC.height)/2;
		}
	}
}