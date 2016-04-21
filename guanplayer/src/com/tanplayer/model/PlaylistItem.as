/////////////////////////////////////////////////////////////////
//flash变量名 播放
///////////////////////////
package com.tanplayer.model 
{
	import com.tanplayer.utils.Strings;

	/**
	 * Playlist item data.  The class is dynamic; any items parsed from the jwplayer XML namespace are added to the item.
	 *  
	 * @author Pablo Schklowsky
	 */
	public dynamic class PlaylistItem 
	{
		public var author:String		= "";
		public var date:String			= "";
		public var description:String	= "";
		public var image:String			= "";
		public var link:String			= "";
		public var mediaid:String		= "";
		public var tags:String			= "";
		public var title:String			= "";
		public var provider:String		= "http";
		public var applehttp:String     ="";
		
		protected var _file:String			= "tanflv";
		
		protected var _videoid:String      ="";
		protected var _streamer:String		= "";
		protected var _duration:Number		= -1;
		protected var _start:Number			= 0;
		
		protected var _currentLevel:Number 	= -1;
		protected var _levels:Array			= [];
		
		
		public function PlaylistItem(obj:Object = null) 
		{
			for (var itm:String in obj) 
			{
				if (itm == "levels" && obj[itm] is Array) 
				{
					var levels:Array = obj[itm] as Array;
					for each (var level:Object in levels) {
						if (level['file'] && level['bitrate'] && level['width']) {
							addLevel(new PlaylistItemLevel(level['file'], level['bitrate'], level['width'], level['streamer']));
						}
					}
				} else {
					this[itm] = obj[itm];
				}
			}
		}
		
		public function get videoid():String
		{
			return _videoid;
		}
		
		public function set videoid(val:String):void
		{
			_videoid=val;
			
		}
		

		/** File property is now a getter, to take levels into account **/
		public function get file():String 
		{
			if (_levels.length > 0 && _currentLevel > -1 && _currentLevel < _levels.length) {
				var level:PlaylistItemLevel = _levels[_currentLevel] as PlaylistItemLevel; 
				return level.file ? level.file : _file;
			} else 
			{
				//trace("file"+_file);
				return _file;
			}
		}
		
		/** File setter.  Note, if levels are defined, this will be ignored. **/
		public function set file(f:String):void 
		{
			_file = f;
		}
		
		
		
		/** Streamer property is now a getter, to take levels into account **/
		public function get streamer():String 
		{
			if (_levels.length > 0 && _currentLevel > -1 && _currentLevel < _levels.length) 
			{
				var level:PlaylistItemLevel = _levels[_currentLevel] as PlaylistItemLevel; 
				return level.streamer ? level.streamer : _streamer;
			} 
			else 
			{
				return _streamer;
			}
		}
		
		/** Streamer setter.  Note, if levels are defined, this will be ignored. **/
		public function set streamer(s:String):void 
		{
			_streamer = s;
		}
		
		/** The quality levels associated with this playlist item **/
		public function get levels():Array 
		{
			return _levels;
		}
		
		/** Insert an additional bitrate level, keeping the array sorted from highest to lowest. **/
		public function addLevel(newLevel:PlaylistItemLevel):void {
			if (_currentLevel < 0) _currentLevel = 0;
			for (var i:Number = 0; i < _levels.length; i++) {
				var level:PlaylistItemLevel = _levels[i] as PlaylistItemLevel;
				if (newLevel.bitrate > level.bitrate) {
					_levels.splice(i, 0, newLevel);
					return;
				} else if (newLevel.bitrate == level.bitrate && newLevel.width > level.width) {
					_levels.splice(i, 0, newLevel);
					return;
				}
			}
			
			_levels.push(newLevel);
		}

		public function get currentLevel():Number {
			return _currentLevel;
		}
		
		public function getLevel(bitrate:Number, width:Number):Number {
			for (var i:Number=0; i < _levels.length; i++) {
				var level:PlaylistItemLevel = _levels[i] as PlaylistItemLevel;
				if (bitrate >= level.bitrate && width >= level.width * 0.9) {
					return i;
				}
			}
			return _levels.length - 1;
		}
		
		/** Set this PlaylistItem's level to match the given bitrate and height. **/
		public function setLevel(newLevel:Number):void {
			if (newLevel >= 0 && newLevel < _levels.length) {
				_currentLevel = newLevel;
			} else {
				throw(new Error("Level index out of bounds"));
			}
		}
		//播放URL
		public function toString():String 
		{
			
			//trace(this.provider);
			return "[PlaylistItem" +
				(this.file ? " file=" + this.file : "") +
				(this.streamer ? " streamer=" + this.streamer : "") +
				(this.provider ? " provider=" + this.provider : "") +
				(this.levels.length ? " level=" + this.currentLevel.toString() : "") +
				"]";
			
		}
		
		
		public function get start():Number { return _start; }
		public function set start(s:*):void { _start = Strings.seconds(String(s)); }
        
		public function get duration():Number 
		{ 
			return _duration; 
		}
		//设置总时间
		public function set duration(d:*):void 
		{ 
			trace(d);
			_duration = Strings.seconds(String(d));
			if (_duration == 0) { _duration = -1; }
		}
		
		// For backwards compatibility
		public function get type():String 
		{ 
			return provider; 
		}
		
		public function set type(t:String):void 
		{ 
			provider = t; 
		}
		
	}
}