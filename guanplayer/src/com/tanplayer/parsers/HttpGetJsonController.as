package com.tanplayer.parsers
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;
	
	
	

	
	public class HttpGetJsonController extends EventDispatcher
	{
		public function HttpGetJsonController(target:IEventDispatcher=null)
		{
			if(!_key)
			{
				super(target);
			}else
			{
				throw new Error("这是一个单例");
			}
				
		}
		
		private static var _instance:HttpGetJsonController;
		private static var _key:Boolean = false;
		
		public static function getInstance():HttpGetJsonController
		{
			if(_instance==null)
			{
				_instance = new HttpGetJsonController();
				_key = true;
			}
			return _instance;
		}
		
		private  var _urlLoader:URLLoader = new URLLoader();
		private  var _urlRequest:URLRequest;
		
		/**
		 * 发出一个http请求
		 * @param 请求类型 get/post
		 * @param 请求的url
		 * @param 参数
		 */
		public function SendQuest(type:String,url:String,params:URLVariables):void
		{
			_urlRequest=new URLRequest(url);
			_urlRequest.data = params;//要传的参数
			_urlRequest.method = type;
			//SetHeaders(_urlRequest);
			_urlLoader.addEventListener(Event.COMPLETE,HttpCompleteHandler);
			_urlLoader.addEventListener(IOErrorEvent.IO_ERROR,IOErrorHandler);
			_urlLoader.load(_urlRequest);
		}
		public var _data:Object;
		private function HttpCompleteHandler(e:Event):void
		{
			try
			{
				_data=e.currentTarget.data;
				this.dispatchEvent(new Event("httpComplete"));
				
			}
			catch (err:Error)
			{
				trace("error"+err.getStackTrace());
			}
			
		}
		
		private function IOErrorHandler(e:IOErrorEvent):void
		{
			
		}
		/**
		 * 设置头信息(这一块很重要，有的不设置头信息就无法正确请求)
		 */
		private function SetHeaders(request:URLRequest):void
		{
			var acceptHeader:URLRequestHeader = new URLRequestHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
			var acceptLanguage:URLRequestHeader = new URLRequestHeader("Accept-Language", "zh-cn,zh;q=0.5");
			var contentType:URLRequestHeader = new URLRequestHeader("Content-Type", "application/x-www-form-urlencoded");
			request.requestHeaders.push(acceptHeader, acceptLanguage, contentType);
		}
	}
}