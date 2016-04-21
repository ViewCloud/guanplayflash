package com.tanplayer.components {
	import com.tanplayer.events.GlobalEventDispatcher;
	import com.tanplayer.events.IGlobalEventDispatcher;
	import com.tanplayer.player.IPlayer;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;

	
	
	
	
	
	public class CoreComponent extends MovieClip implements IGlobalEventDispatcher {

		private var _dispatcher:IGlobalEventDispatcher;
		protected var _player:IPlayer;
		protected var _name:String;

		public function CoreComponent(player:IPlayer, name:String) 
		{
			_dispatcher = new GlobalEventDispatcher();
			_player = player;
			_name = name;
			super();
		}
		
		public function get imdPlayer():IPlayer
		{
			return _player;
		}
		
		public function hide():void 
		{
			this.visible = false;
		}
		
		public function show():void {
			this.visible = true;
		}
		
		protected function get player():IPlayer {
			return _player;
		}

		protected function getSkinElement(element:String):DisplayObject 
		{
			return player.skin.getSkinElement(_name,element);
		}
		
		protected function getConfigParam(param:String):* 
		{
			return player.config.pluginConfig(_name)[param];
		}
		
		protected function setConfigParam(param:String, value:*):void {
			player.config.pluginConfig(_name)[param] = value;
		}
		
		///////////////////////////////////////////		
		/// IGlobalEventDispatcher implementation
		///////////////////////////////////////////		
		/**
		 * @inheritDoc
		 */
		public function addGlobalListener(listener:Function):void {
			_dispatcher.addGlobalListener(listener);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function removeGlobalListener(listener:Function):void {
			_dispatcher.removeGlobalListener(listener);
		}
		
		
		/**
		 * @inheritDoc
		 */
		public override function dispatchEvent(event:Event):Boolean {
			_dispatcher.dispatchEvent(event);
			return super.dispatchEvent(event);
		}
	}
}