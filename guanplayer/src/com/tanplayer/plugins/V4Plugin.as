package com.tanplayer.plugins 
{
	import com.events.PluginInterface;
	import com.tanplayer.player.IPlayer;
	import com.tanplayer.player.PlayerV4Emulation;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	public class V4Plugin extends Sprite implements IPlugin 
	{
		private var plug:PluginInterface;
		public var pluginId:String;

		public function V4Plugin(plugin:PluginInterface, pluginId:String) 
		{
			plug = plugin;
			this.pluginId = pluginId;
			addChild(plug as DisplayObject);
		}

		public function initPlugin(player:IPlayer, config:PluginConfig):void {
			if ((plug as Object).hasOwnProperty('config')) {
				(plug as Object).config = config;
			}
			var emu:PlayerV4Emulation = PlayerV4Emulation.getInstance(player); 
			plug.initializePlugin(emu);
		}
		
		public function resize(width:Number, height:Number):void {
			this.x = 0;
			this.y = 0;
		}
		
		public function get id():String {
			return pluginId;
		}

	}

}