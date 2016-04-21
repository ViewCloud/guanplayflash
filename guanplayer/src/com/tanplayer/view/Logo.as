package com.tanplayer.view {
	import com.tanplayer.events.PlayerStateEvent;
	import com.tanplayer.player.IPlayer;
	import com.tanplayer.player.PlayerState;
	import com.tanplayer.utils.Animations;
	import com.tanplayer.utils.Draw;
	import com.tanplayer.utils.Logger;
	import com.tanplayer.utils.RootReference;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.LoaderContext;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	
	public class Logo extends MovieClip 
	{
		/** Configuration defaults **/
		protected var defaults:Object = {
			prefix: "http://l.longtailvideo.com/", 
			file: "",//去掉LOGO 
			link: "http://www.longtailvideo.com/players/jw-flv-player/", 
			margin: 8, 
			out: 0.5, 
			over: 1, 
			timeout: 3,
			hide: "true",
			position: "bottom-left"
		}
		/** Reference to the player **/
		protected var _player:IPlayer;
		/** Reference to the current fade timer **/
		protected var timeout:uint;
		/** Reference to the loader **/
		protected var loader:Loader;
		/** Animations handler **/
		protected var animations:Animations;
		
		/** Dimensions **/
		protected var _width:Number;
		protected var _height:Number;
		
		/** Constructor **/
		public function Logo(player:IPlayer) {
			super();
			animations = new Animations(this);
			_player = player;
			player.addEventListener(PlayerStateEvent.JWPLAYER_PLAYER_STATE, stateHandler);
			setupDefaults();
			setupMouseEvents();
			loadFile();
		}
		
		/**
		 * This method can be overridden to set alternate default values. 
		 */
		protected function setupDefaults():void {
			return;
		}

		protected function setupMouseEvents():void {
			this.mouseChildren = false;
			this.buttonMode = true;
			if (getConfigParam('link')) {
				addEventListener(MouseEvent.MOUSE_OVER, overHandler);
				addEventListener(MouseEvent.MOUSE_OUT, outHandler);
				addEventListener(MouseEvent.CLICK, clickHandler);
			} else {
				this.mouseEnabled = false;
			}
		}
		
		protected function loadFile():void {
			var versionRE:RegExp = /(\d+)\.(\d+)\./;
			var versionInfo:Array = versionRE.exec(_player.version);
			if (getConfigParam('file') && getConfigParam('prefix')) {
				defaults['file'] = getConfigParam('prefix') + versionInfo[1] + "/" + versionInfo[2] + "/" + getConfigParam('file');
			}
			
			if (getConfigParam('file') && RootReference.root.loaderInfo.url.indexOf("http")==0) {
				loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderHandler);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
				loader.load(new URLRequest(getConfigParam('file')));
			}
		}
		
		/** Logo loaded - add to display **/
		protected function loaderHandler(evt:Event):void {
			if (getConfigParam('hide').toString() == "true") visible = false;
			addChild(loader);
			resize(_width, _height);
			outHandler();
		}
		
		/** Logo failed to load - die **/
		protected function errorHandler(evt:ErrorEvent):void {
			Logger.log("Failed to load logo: " + evt.text);
		}
		
		
		/** Handles mouse clicks **/
		protected function clickHandler(evt:MouseEvent):void {
			_player.pause();
			if (getConfigParam('link')) {
				navigateToURL(new URLRequest(getConfigParam('link')));
			}
		}
		
		/** Handles mouse outs **/
		protected function outHandler(evt:MouseEvent=null):void {
			alpha = getConfigParam('out');
		}
		
		
		/** Handles mouse overs **/
		protected function overHandler(evt:MouseEvent):void {
			if (getConfigParam('link')) {
				alpha = getConfigParam('over');
			}
		}
		
		
		/** Handles state changes **/
		protected function stateHandler(evt:PlayerStateEvent):void {
			if (_player.state == PlayerState.BUFFERING) {
				clearTimeout(timeout);
				show();
			}
		}
		
		
		/** Fade in **/
		protected function show():void {
			if (getConfigParam('hide').toString() == "true") {
				visible = true;
				alpha = 0;
				animations.fade(getConfigParam('out'), 0.1);
				timeout = setTimeout(hide, getConfigParam('timeout') * 1000);
				mouseEnabled = true;
			}
		}
		
		
		/** Fade out **/
		protected function hide():void {
			if (getConfigParam('hide').toString() == "true") {
				mouseEnabled = false;
				animations.fade(0, 0.1);
			}
		}
		
		
		/** Resizes the logo **/
		public function resize(width:Number, height:Number):void {
			_width = width;
			_height = height;
			var image:DisplayObject = loader ? loader : null;
			var margin:Number = getConfigParam('margin');
			var position:String = (getConfigParam('position') as String).toLowerCase(); 
			if (image) {
				if (position.indexOf('right') >= 0) {
					image.x = _width - image.width - margin;
				} else {
					image.x = margin;
				}
				
				if (position.indexOf('bottom') >= 0) {
					image.y = _height - image.height - margin;
				} else {
					image.y = margin;
				}
			}
		}
		
		
		/** Gets a configuration parameter **/
		protected function getConfigParam(param:String):* {
			return defaults[param];
		}
	}
}