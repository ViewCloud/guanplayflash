/////////////////////////////////////////////////////
//布局管理器
/////////////////////////////////////////////////////
package com.tanplayer.view {
	import com.tanplayer.player.IPlayer;
	import com.tanplayer.plugins.PluginConfig;
	import com.tanplayer.utils.RootReference;
	
	import flash.geom.Rectangle;


	public class PlayerLayoutManager {

		public static var LEFT:String = "left";  
		public static var RIGHT:String = "right";  
		public static var TOP:String = "top";  
		public static var BOTTOM:String = "bottom";  
		public static var NONE:String = "none";  
	
		private var _player:IPlayer;
	
		private var toLayout:Array;
		private var noLayout:Array;
		
		private var remainingSpace:Rectangle;
		
		
	
		public function PlayerLayoutManager(player:IPlayer) 
		{
			_player = player;
		}
		
		public function resize(width:Number, height:Number):void 
		{
			toLayout = [];
			noLayout = [];
			
			for each (var plugin:String in _player.config.pluginIds) 
			{
				addLayout(plugin);
			}
			
			addLayout('playlist');			
			addLayout('controlbar');
			addLayout('display');			
			addLayout('dock');	
			//舞台视频大小
			remainingSpace = new Rectangle(0, 0, width, height);
			generateLayout();
		} 


		private function addLayout(plugin:String):void 
		{
			var cfg:PluginConfig = _player.config.pluginConfig(plugin); 
			if (!_player.fullscreen && testPosition(cfg['position']) && Number(cfg['size']) > 0 ) 
			{
				toLayout.push(cfg);
			} 
			else 
			{
				noLayout.push(cfg);
			}
		}
		
		

		public static function testPosition(pos:String):String 
		{
			if (!pos) 
			{ 
				return ""; 
			}
		
			switch (pos.toLowerCase()) 
			{
				case LEFT:
				case RIGHT:
				case TOP:
				case BOTTOM:
					return pos.toLowerCase();
					break;
				default:
					return "";
					break;
			}
		}
        
		//布局
		protected function generateLayout():void 
		{
			if (toLayout.length == 0) 
			{
				for each(var item:PluginConfig in noLayout) 
				{
					item['visible'] = !(_player.fullscreen && testPosition(item['position']));
					assignSpace(item, remainingSpace);
				}
				//舞台视频大小 配置大小
				_player.config.width = remainingSpace.width;
				_player.config.height = remainingSpace.height;
				
				return;
			}
			
			var config:PluginConfig = toLayout.shift() as PluginConfig;
			var pluginSpace:Rectangle = new Rectangle();
			var position:String = testPosition(config['position']);
			var size:Number = config['size'];
			
			switch (position) {
				case LEFT:
					pluginSpace.x = remainingSpace.x;
					pluginSpace.y = remainingSpace.y;
					pluginSpace.width = size;
					pluginSpace.height = remainingSpace.height;
					remainingSpace.width -= size;
					remainingSpace.x += size;
					break;
				case RIGHT:
					pluginSpace.x = remainingSpace.x + remainingSpace.width - size;
					pluginSpace.y = remainingSpace.y;
					pluginSpace.width = size;
					pluginSpace.height = remainingSpace.height;
					remainingSpace.width -= size;
					break;
				case TOP:
					pluginSpace.x = remainingSpace.x;
					pluginSpace.y = remainingSpace.y;
					pluginSpace.width = remainingSpace.width;
					pluginSpace.height = size;
					remainingSpace.height -= size;
					remainingSpace.y += size;
					break;
				
				case BOTTOM:

					
					//----------控制面板controlbar位置=======
					pluginSpace.x = remainingSpace.x;//控制面板x坐标
					pluginSpace.y = remainingSpace.y + remainingSpace.height - size;//控制面板y坐标 size实际是控制面板高
					
					//----------控制面板controlbar位置=======
					//=====控制面板宽貌似必须得赋个值==============
					pluginSpace.width = remainingSpace.width;
					
					//remainingSpace这个不要管他 调了也没有用不知道为什么，总之微调就是对的
					if(_player.config.playtype=="live")
					{
						remainingSpace.height -= -7;//7是微调调节视频和上下边的距离
					}
					else
					{
						remainingSpace.height -= (size-7);//7是微调调节视频和上下边的距离
					}
					
					
					break;
			}

			
			
			
			config['visible'] = true;
			assignSpace(config, pluginSpace);
			
			generateLayout();
		}
		
		//布局
		protected function assignSpace(cfg:PluginConfig, space:Rectangle):void 
		{
			
			cfg['width'] 	= space.width;
			cfg['height'] 	= space.height;
			cfg['x'] 		= space.x;
			cfg['y'] 		= space.y;
		}
		
		
	}
}