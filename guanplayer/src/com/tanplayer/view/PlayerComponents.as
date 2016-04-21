package com.tanplayer.view 
{
	import com.tanplayer.model.PlayerConfig;
	import com.tanplayer.player.IPlayer;
	import com.tanplayer.player.JavascriptAPI;
	import com.tanplayer.plugins.PluginConfig;
	import com.tanplayer.components.ControlbarComponent;
	import com.tanplayer.components.ControlbarComponentV4;
	import com.tanplayer.components.DisplayComponent;
	import com.tanplayer.components.DockComponent;
	import com.tanplayer.components.PlaylistComponent;
	import com.tanplayer.interfaces.IControlbarComponent;
	import com.tanplayer.interfaces.IDisplayComponent;
	import com.tanplayer.interfaces.IDockComponent;
	import com.tanplayer.interfaces.IPlayerComponent;
	import com.tanplayer.interfaces.IPlaylistComponent;
	import com.tanplayer.interfaces.ISkin;
	import com.tanplayer.skins.SWFSkin;
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	
	public class PlayerComponents implements IPlayerComponents 
	{
		private var _controlbar:IControlbarComponent;
		private var _display:IDisplayComponent;
		private var _dock:IDockComponent;
		private var _playlist:IPlaylistComponent;
		private var _config:PlayerConfig;
		private var _skin:ISkin;
		private var _player:IPlayer;
		
		
		/**
		 * @inheritDoc
		 */
		public function PlayerComponents(player:IPlayer) 
		{
			_player = player;
			
			_skin = player.skin;
			_config = player.config;
			if (_skin is SWFSkin) 
			{
				_controlbar = new ControlbarComponentV4(_player);
			} 
			else 
			{
				_controlbar = new ControlbarComponent(_player);
			}
			
			_display = new DisplayComponent(_player);
			_playlist = new PlaylistComponent(_player);
			_dock = new DockComponent(_player);
			
			
		}
		
		/**
		 * @inheritDoc
		 */
		public function get controlbar():IControlbarComponent 
		{
			return _controlbar;
		}
		
		
		/**
		 * @获取大播放按钮等图标父级
		 */
		public function get display():IDisplayComponent 
		{
			return _display;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function get dock():IDockComponent {
			return _dock;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function get playlist():IPlaylistComponent {
			return _playlist;
		}
		
	    //调整控制面板组件位置
		/**
		 * @inheritDoc
		 */
		public function resize(width:Number, height:Number):void 
		{
			resizeComponent(_display, _config.pluginConfig('display'));
			resizeComponent(_controlbar, _config.pluginConfig('controlbar'));
			resizeComponent(_playlist, _config.pluginConfig('playlist'));
			resizeComponent(_dock, _config.pluginConfig('dock'));
		}
		
		//布局
		private function resizeComponent(comp:IPlayerComponent, config:PluginConfig):void 
		{
			trace("comp"+comp);
			
			comp.x = config['x'];
			comp.y = config['y'];
			
			trace("comp.y"+comp.y);
			trace("config:::"+config);
			trace("config['width']:::"+config['width']);
			trace("config['height']:::"+config['height']);
			//布局
			comp.resize(config['width'], config['height']);
		}
	}
}