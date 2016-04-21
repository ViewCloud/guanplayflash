package com.tanplayer.controller {
	import com.events.PluginInterface;
	import com.tanplayer.events.PlayerEvent;
	import com.tanplayer.events.PlaylistEvent;
	import com.tanplayer.interfaces.ISkin;
	import com.tanplayer.model.Model;
	import com.tanplayer.player.IPlayer;
	import com.tanplayer.plugins.IPlugin;
	import com.tanplayer.plugins.PluginConfig;
	import com.tanplayer.plugins.V4Plugin;
	import com.tanplayer.skins.DefaultSkin;
	import com.tanplayer.skins.PNGSkin;
	import com.tanplayer.skins.SWFSkin;
	import com.tanplayer.skins.SkinProperties;
	import com.tanplayer.skins.ZIPSkin;
	import com.tanplayer.utils.Configger;
	import com.tanplayer.utils.Logger;
	import com.tanplayer.utils.RootReference;
	import com.tanplayer.utils.Strings;
	import com.tanplayer.view.View;
	
	import flash.display.DisplayObject;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import org.danmu.plugins.CommentView;
	
	//import plugins.CommentView;
	
	
	


	/**
	 * Sent when the all of the setup steps have successfully completed.
	 *
	 * @eventType flash.events.Event.COMPLETE
	 */
	[Event(name="complete", type = "flash.events.Event")]

	/**
	 * Sent when an error occurred during player setup
	 *
	 * @eventType flash.events.ErrorEvent.ERROR
	 */
	[Event(name="error", type = "flash.events.ErrorEvent")]


	/**
	 * PlayerSetup is a helper class to Controller.  It manages the initial player startup process, firing an 
	 * Event.COMPLETE event when finished, or an ErrorEvent.ERROR if a problem occurred during setup.
	 * 
	 * @see Controller
 	 * @author Pablo Schklowsky
	 */
	public class PlayerSetup extends EventDispatcher {

		/** MVC references **/
		protected var _player:IPlayer;
		protected var _model:Model;
		protected var _view:View;
		
		/** TaskQueue **/
		protected var tasker:TaskQueue;
		
		/** User-defined configuration **/
		protected var confHash:Object;
		
		public function PlayerSetup(player:IPlayer, model:Model, view:View) {
			_player = player;
			_model = model;
			_view = view;
		}
		//程序启动
		public function setupPlayer():void 
		{
			tasker = new TaskQueue(false);
			tasker.addEventListener(Event.COMPLETE, setupTasksComplete);
			tasker.addEventListener(ErrorEvent.ERROR, setupTasksFailed);
			
			tasker.queueTask(insertDelay);
			//加载HTML配置变量
			//回调函数
			tasker.queueTask(loadConfig, loadConfigComplete);
			tasker.queueTask(loadSkin, loadSkinComplete);
			tasker.queueTask(setupMediaProviders);
			tasker.queueTask(setupView);
			tasker.queueTask(loadPlugins, loadPluginsComplete);
			tasker.queueTask(loadPlaylist, loadPlaylistComplete);
			tasker.queueTask(initPlugins);
			
			tasker.runTasks();
		}
		
		protected function setupTasksComplete(evt:Event):void {
			complete();
		}
		
		protected function setupTasksFailed(evt:ErrorEvent):void {
			error(evt.text);
		}

		protected function complete():void {
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		protected function error(message:String):void {
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, message));
		}
		
		///////////////////////
		// Tasks
		///////////////////////
		
		protected function insertDelay():void {
			var timer:Timer = new Timer(100, 1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, tasker.success);
			timer.start();
		}
		//加载HTML配置变量
		protected function loadConfig():void 
		{
			var configger:Configger = new Configger();
			configger.addEventListener(Event.COMPLETE, tasker.success);
			configger.addEventListener(ErrorEvent.ERROR, tasker.failure);

		
			configger.loadConfig();
			
		}

		protected function loadConfigComplete(evt:Event):void 
		{
			confHash = (evt.target as Configger).configflashvar;//flash变量传进来
		}

		protected function loadSkin(evt:ErrorEvent=null):void 
		{
			var skin:ISkin;
			if (confHash && confHash['skin'] && evt == null) {
				if (Strings.extension(confHash['skin']) == "swf") {
					skin = new SWFSkin();
				} else if (Strings.extension(confHash['skin']) == "zip") {
					skin = new ZIPSkin();
				} else if (Strings.extension(confHash['skin']) == "xml") {
					skin = new PNGSkin();
				} else {
					Logger.log("Could not load skin " + confHash['skin']);
				}
			}
			if (skin) {
				// If this step fails, load the default skin instead
				skin.addEventListener(ErrorEvent.ERROR, loadSkin);
			} else {
				if (evt) { 
					Logger.log("Error loading skin: " + evt.text);
					(evt.target as EventDispatcher).removeEventListener(ErrorEvent.ERROR, loadSkin);
				}
				skin = new DefaultSkin();
				skin.addEventListener(ErrorEvent.ERROR, tasker.failure);
			}
			skin.addEventListener(Event.COMPLETE, tasker.success);
			skin.load(confHash['skin']);
		}
		
		protected function loadSkinComplete(event:Event=null):void 
		{
			if (event) 
			{
				var skin:ISkin = event.target as ISkin;
				skin.removeEventListener(Event.COMPLETE, tasker.success);
				skin.removeEventListener(ErrorEvent.ERROR, tasker.failure);
				skin.removeEventListener(ErrorEvent.ERROR, loadSkin);

				var props:SkinProperties = skin.getSkinProperties();
				
				
				_model.config.setConfig(props);
				//皮肤加载完毕开始把外部flash变量传进来
				_model.config.setConfig(confHash);//
				
				_view.skin = skin;
			} 
			else 
			{
				_model.config.setConfig(confHash);
			}
			
			Logger.setConfig(_model.config);
		}

		protected function setupMediaProviders():void 
		{
			_model.setupMediaProviders();
			tasker.success();
		}

		protected function setupView():void 
		{
			_view.setupView();
			tasker.success();
		}

		protected function loadPlugins():void 
		{
			if (_model.config.plugins) 
			{
				var loader:PluginLoader = new PluginLoader();
				loader.addEventListener(Event.COMPLETE, tasker.success);
				loader.addEventListener(ErrorEvent.ERROR, tasker.failure);
				loader.loadPlugins(_model.config.plugins);
			} 
			else 
			{
				tasker.success();
			}
		}
		
		protected function loadPluginsComplete(event:Event=null):void 
		{
			if (event) 
			{
				var loader:PluginLoader = event.target as PluginLoader;

				for (var pluginId:String in loader.plugins) 
				{
					var plugin:DisplayObject = loader.plugins[pluginId] as DisplayObject;
					if (plugin is IPlugin) {
						_view.addPlugin(pluginId, plugin as IPlugin);
					} else if (plugin is PluginInterface) {
						if ( (plugin as Object).hasOwnProperty('config') ) {
							var loadedConf:Object = (plugin as Object).config;
							var pluginConf:PluginConfig = _model.config.pluginConfig(pluginId);
							for (var i:String in loadedConf) {
								if (!pluginConf.hasOwnProperty(i)) pluginConf[i] = loadedConf[i];
							}
							pluginConf['width'] = _player.controls.display.width;
							pluginConf['height'] = _player.controls.display.height;
							pluginConf['visible'] = true;
						}
						_view.addPlugin(pluginId, new V4Plugin(plugin as PluginInterface, pluginId));
					}
				}
			}
			//添加弹幕插件
			if(_model.config.showtanmu==true)
			{
				_view.addPlugin("commentview", CommentView.getInstance());
			}
		}
        //加载播放URL load
		protected function loadPlaylist():void 
		{
			_model.playlist.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_LOADED, tasker.success);
			_model.playlist.addEventListener(PlayerEvent.JWPLAYER_ERROR, tasker.failure);

			
			if (_model.config.playlistfile) 
			{
				_model.playlist.load(_model.config.playlistfile);
			} 
			else if (_model.config.singleItem.file) //单个URL
			{
				_model.playlist.load(_model.config.singleItem);
			} 
			else if(_model.config.singleItem.applehttp!="")
			{
				_model.playlist.load(_model.config.singleItem);
			}
			else 
			{
				tasker.success();
			}
		}

		protected function loadPlaylistComplete(event:Event=null):void {
			_model.playlist.removeEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_LOADED, tasker.success);
			_model.playlist.removeEventListener(PlayerEvent.JWPLAYER_ERROR, tasker.failure);
		}

		protected function initPlugins():void {
			for each (var pluginId:String in _view.loadedPlugins()) {
				try {
					var plugin:IPlugin = _view.getPlugin(pluginId);
					plugin.initPlugin(_player, _model.config.pluginConfig(pluginId));
				} catch (e:Error) {
					Logger.log("Error initializing plugin: " + e.message);
					if (plugin) {
						_view.removePlugin(plugin);
					}
				}
			}
			tasker.success();
		}

	}
}