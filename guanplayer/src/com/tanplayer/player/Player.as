//播放器启动的根文件
package com.tanplayer.player 
{
	import com.tanplayer.controller.Controller;
	import com.tanplayer.events.PlayerEvent;
	import com.tanplayer.interfaces.IPlayerComponent;
	import com.tanplayer.interfaces.ISkin;
	import com.tanplayer.model.IPlaylist;
	import com.tanplayer.model.Model;
	import com.tanplayer.model.PlayerConfig;
	import com.tanplayer.plugins.IPlugin;
	import com.tanplayer.utils.Logger;
	import com.tanplayer.utils.RootReference;
	import com.tanplayer.utils.TanBandwidthCheck;
	import com.tanplayer.view.IPlayerComponents;
	import com.tanplayer.view.View;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	
	
	[Event(name="jwplayerReady", type="com.tanplayer.events.PlayerEvent")]
	
	
	public class Player extends Sprite implements IPlayer 
	{
		public var model:Model;
		public var view:View;
		public var controller:Controller;
		

		
		public function Player() //调试模式
		{
			try 
			{
				this.addEventListener(Event.ADDED_TO_STAGE, setupPlayer);
			} 
			catch (err:Error) 
			{
				setupPlayer();
			}
		}
		
		
		protected function setupPlayer(event:Event=null):void 
		{
			try 
			{
				this.removeEventListener(Event.ADDED_TO_STAGE, setupPlayer);
			}
			catch (err:Error) 
			{
				
			}
			//设置外部根交互的对象
			new RootReference(this);
			
			RootReference._player = this;
			//设置好mvc 控制器开始安装
			model = newModel();
			view = newView(model);
			controller = newController(model, view);
			controller.addEventListener(PlayerEvent.JWPLAYER_READY, playerReady, false, -1);
			
			controller.setupPlayer();
		}
		
		
		protected function newModel():Model 
		{
			return new Model();
		}
		
		protected function newView(mod:Model):View 
		{
			
			return new View(this, mod);
		}
		
		protected function newController(mod:Model, vw:View):Controller 
		{
			return new Controller(this, mod, vw);
		} 
		
		protected function playerReady(evt:PlayerEvent):void 
		{
			// Only handle JWPLAYER_READY once
			controller.removeEventListener(PlayerEvent.JWPLAYER_READY, playerReady);
			
			model.addGlobalListener(forward);
			view.addGlobalListener(forward);
			controller.addGlobalListener(forward);
			forward(evt);
			
			
			LoadPlugin("GgPlugin.swf");//插件层
		}
		
		
		public function LoadPlugin(url:String):void
		{
			adSwfLoad=new Loader();
			adSwfLoad.contentLoaderInfo.addEventListener(Event.COMPLETE,PluginCompleteHandler);
			
			adSwfLoad.load(new URLRequest(url));
		}
		
		
		private var adSwfLoad:Loader;
		public var currentPlugin:Object;
		
		private var pluginLoader:URLLoader = new URLLoader();
		
		private function PluginCompleteHandler(e:Event):void
		{
			this.stage.addChildAt(adSwfLoad,stage.numChildren);
			//trace(e.target.content);
			currentPlugin=e.target.content;
			
			var ob:Object=loaderInfo.parameters;
			
			
			
			currentPlugin.InitPlugin("https://uapi.guancloud.com/1.2/videos/"+loaderInfo.parameters["videoid"]+"/annotations");
		}
		
		
		/**
		 * Forwards all MVC events to interested listeners.
		 * @param evt
		 */
		protected function forward(evt:PlayerEvent):void 
		{
			Logger.log(evt.toString(), evt.type);
			dispatchEvent(evt);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function get config():PlayerConfig 
		{
			return model.config;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function get version():String 
		{
			return PlayerVersion.version;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function get skin():ISkin 
		{
			return view.skin;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function get state():String 
		{
			//trace("get state(3)"+model.state);
			return model.state;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function get playlist():IPlaylist 
		{
			return model.playlist;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function get locked():Boolean {
			return controller.locking;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function lock(target:IPlugin, callback:Function):void {
			controller.lockPlayback(target, callback);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function unlock(target:IPlugin):Boolean 
		{
			return controller.unlockPlayback(target);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function volume(volume:Number):Boolean 
		{
			return controller.setVolume(volume);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function get mute():Boolean {
			return model.mute;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function set mute(state:Boolean):void 
		{
			controller.mute(state);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function play():Boolean 
		{
			return controller.play();
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function pause():Boolean {
			return controller.pause();
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function stop():Boolean {
			return controller.stop();
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function seek(position:Number):Boolean {
			return controller.seek(position);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function load(item:*):Boolean {
			return controller.load(item);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function playlistItem(index:Number):Boolean {
			return controller.setPlaylistIndex(index);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function playlistNext():Boolean {
			return controller.next();
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function playlistPrev():Boolean {
			return controller.previous();
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function redraw():Boolean {
			return controller.redraw();
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function get fullscreen():Boolean {
			return model.fullscreen;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function set fullscreen(on:Boolean):void 
		{
			controller.fullscreen(on);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function link(index:Number = NaN):Boolean {
			return controller.link(index);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function get controls():IPlayerComponents {
			return view.components;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function overrideComponent(plugin:IPlayerComponent):void {
			view.overrideComponent(plugin);
		}
		
		/** 
		 * @private
		 * 
		 * This method is deprecated, and is used for backwards compatibility only.
		 */
		public function getPlugin(id:String):Object {
			return view.getPlugin(id);
		} 
		
		/** The player should not accept any calls referencing its display stack **/
		public override function addChild(child:DisplayObject):DisplayObject {
			return null;
		}

		/** The player should not accept any calls referencing its display stack **/
		public override function addChildAt(child:DisplayObject, index:int):DisplayObject {
			return null;
		}

		/** The player should not accept any calls referencing its display stack **/
		public override function removeChild(child:DisplayObject):DisplayObject {
			return null;
		}

		/** The player should not accept any calls referencing its display stack **/
		public override function removeChildAt(index:int):DisplayObject {
			return null;
		}
		
	}
}