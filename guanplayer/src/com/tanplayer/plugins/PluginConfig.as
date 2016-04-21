package com.tanplayer.plugins {
	

	public dynamic class PluginConfig {
		private var _id:String;

		public function PluginConfig(pluginId:String) 
		{
			this._id = pluginId.toLowerCase();
		}
		
		public function get id():String 
		{
			return _id;
		}
		
	}
}