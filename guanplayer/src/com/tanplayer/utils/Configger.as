package com.tanplayer.utils 
{
	import com.adobe.serialization.json.JSON;

	import com.tanplayer.player.CallJSFunction;
	
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Security;
	
	/**
	 * Sent when the configuration block has been successfully retrieved
	 *
	 * @eventType flash.events.Event.COMPLETE
	 */
	[Event(name="complete", type = "flash.events.Event")]
	
	/**
	 * Sent when an error in the config has
	 *
	 * @eventType flash.events.ErrorEvent.ERROR
	 */
	[Event(name="error", type = "flash.events.ErrorEvent")]
	
	public class Configger extends EventDispatcher 
	{
		private var _config:Object = {};
		
		/** The loaded config object; can an XML object or a hash map. **/
		public function get configflashvar():Object 
		{
			return _config;
		}
		
		/**
		 * @return
		 * @throws Error if something bad happens.
		 */
		
		
		//加载HTMLflash变量 变量加载模式
		public function loadConfig():void 
		{
			
			loadCookies();
			/** Whether the "config" flashvar is set **/
			if (this.xmlConfig) 
			{
				loadXML(this.xmlConfig);
			} 
			else 
			{
				//loadFlashvars(RootReference.flashvarObject);//从壳
				//trace(RootReference.root.loaderInfo.url);
				loadFlashvars(RootReference.root.loaderInfo.parameters);//本地调试模式
				//loadExternal();//var dfef:String='[[JSON]][{"image":"sd.png","title":"Html5 Mode","sources":[{"file":"http://www.dali-group.com/lvcha/flv.flv","type":"mp4"}]}]';
			}
		}
		
		
		private function loadExternal():void 
		{
			//if (ExternalInterface.available)
			//{
		     var flashvars:Object = ExternalInterface.call("jwplayer.embed.flash.getVars", ExternalInterface.objectID);
		     //var flashvars:Object = '[[JSON]][{"image":"sd.png","title":"Html5 Mode","sources":[{"file":"http://www.dali-group.com/lvcha/flv.flv","type":"mp4"}]}]';
		
			 //trace(flashvars.toString());	
			 if(flashvars != null) 
			 {
				 //var dfef:String='[[JSON]][{"image":"sd.png","title":"Html5 Mode","sources":[{"file":"http://www.dali-group.com/lvcha/flv.flv","type":"mp4"}]}]';
				
				 for (var param:String in flashvars) 
				 {
					 setConfigParam(param, flashvars[param]);
				 }
				
				 return;
			 }
			//}
		}
		
		/** Whether the "config" flashvar is set **/
		public function get xmlConfig():String 
		{
			return RootReference.root.loaderInfo.parameters['config'];
		}
		
		/**
		 * Loads a config block from an XML file
		 * @param url The location of the config file.  Can be absolute URL or path relative to the player SWF.
		 */
		public function loadXML(url:String):void 
		{
			var xmlLoader:URLLoader = new URLLoader();
			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, xmlFail);
			xmlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, xmlFail);
			xmlLoader.addEventListener(Event.COMPLETE, loadComplete);
			xmlLoader.load(new URLRequest(url));
		}
		
		/**
		 * Loads configuration flashvars
		 * @param params Hash map containing key/value pairs
		 */
		public function loadFlashvars(params:Object):void 
		{
			
			try 
			{
				for (var param:String in params) 
				{
					
					setConfigSwfParam(param, params[param]);
				}
				
			
				
				//接收是这个事件setupComplete参数读取完毕
				dispatchEvent(new Event(Event.COMPLETE));
			} 
			catch (e:Error) 
			{
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
			}
		}
		//缓存
		public static function saveCookie(param:String, value:*):void 
		{
			//			try 
			//			{
			//				var cookie:SharedObject = SharedObject.getLocal('com.jeroenwijering','/');
			//				cookie.data[param] = value;
			//				cookie.flush();
			//			} 
			//			catch (err:Error) 
			//			{
			//			}
		}
		//缓存
		private function loadCookies():void 
		{
			//			try 
			//			{
			//				var cookie:SharedObject = SharedObject.getLocal('com.jeroenwijering','/');
			//				writeCookieData(cookie.data);
			//			} 
			//			catch (err:Error) 
			//			{
			//			}
		}
		
		/** Overwrite cookie data. **/ 
		private function writeCookieData(obj:Object):void {
			for (var cfv:String in obj) {
				setConfigParam(cfv.toLowerCase(), obj[cfv]); 
			}
		}
		
		private function loadComplete(evt:Event):void {
			var loadedXML:XML = XML((evt.target as URLLoader).data);
			if (loadedXML.name().toString().toLowerCase() == "config" && loadedXML.children().length() > 0) {
				parseXML(loadedXML);
				loadFlashvars(RootReference.root.loaderInfo.parameters);
			} else {
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "Config was empty"));
			}
		}
		
		private function xmlFail(evt:ErrorEvent):void {
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, evt.text));
		}
		
		private function parseXML(xml:XML):void {
			for each(var item:XML in xml.children()) {
				if (item.name() == "pluginconfig") {
					parsePluginConfig(item);
				} else {
					setConfigParam(item.name().toString(), item.toString());
				}
			}
		}
		
		private function parsePluginConfig(pluginconfig:XML):void {
			for each(var plugin:XML in pluginconfig.plugin) {
				for each(var pluginParam:XML in plugin.children()) {
					setConfigParam(plugin.@name + "." + pluginParam.name(), pluginParam.toString()); 
				}  
			}
		}
		
		public function setConfigSwfParam(name:String, value:String):void 
		{
			trace("flashvar变量名"+name+":"+value);
			
			//这里一定要加 原版的file 等属性都在这里
			_config[name.toLowerCase()] = Strings.serialize(Strings.trim(Strings.decode(value)));
		}
		//处理变量
		public function setConfigParam(name:String, value:String):void 
		{
			//flashvar变量名
			trace("flashvar变量名"+name+":"+value);
			if(name=="playlist")
			{
				value=value.replace('[[JSON]]','');
				//trace(value);
				var arrjson:Array=com.adobe.serialization.json.JSON.decode(value);
				
				var flashvarObject:Object=arrjson[0];
				//trace(flashvarObject["sources"][0]);
				flashvarObject["file"]=flashvarObject["sources"][0]["file"];
				//trace(flashvarObject["file"]);
				//trace(flashvarObject["image"])
				loadFlashvars(flashvarObject);
				
                return;
				
			}
			
		
		}
	}
}