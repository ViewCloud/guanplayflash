package com.tanplayer.player {
	import com.events.AbstractView;
	import com.events.ControllerEvent;
	import com.events.ModelEvent;
	import com.events.ModelStates;
	import com.tanplayer.controller.Controller;
	import com.tanplayer.events.MediaEvent;
	import com.tanplayer.events.PlayerEvent;
	import com.tanplayer.events.PlayerStateEvent;
	import com.tanplayer.events.PlaylistEvent;
	import com.tanplayer.events.ViewEvent;
	import com.tanplayer.model.IPlaylist;
	import com.tanplayer.model.Model;
	import com.tanplayer.model.PlaylistItem;
	import com.tanplayer.model.PlaylistItemLevel;
	import com.tanplayer.plugins.IPlugin;
	import com.tanplayer.plugins.PluginConfig;
	import com.tanplayer.plugins.V4Plugin;
	import com.tanplayer.utils.Logger;
	import com.tanplayer.utils.Strings;
	import com.tanplayer.interfaces.IControlbarComponent;
	import com.tanplayer.interfaces.IDisplayComponent;
	import com.tanplayer.interfaces.IDockComponent;
	import com.tanplayer.interfaces.IPlaylistComponent;
	
	import flash.display.DisplayObject;
	import flash.events.EventDispatcher;
	import flash.utils.describeType;
	import flash.utils.getTimer;

	/**
	 * This singleton class acts as a wrapper between the Player and plugins or javascripts that were
	 * written for version 4 of the player.  It extends version 4's AbstractView class, and translates
	 * Player 5 event dispatches into their version 4 counterparts.
	 * 
	 * @see com.longtailvideo.jwplayer.plugins.V4Plugin  
	 */
	public class PlayerV4Emulation extends AbstractView {
		private static var instance:PlayerV4Emulation;
		
		private var _player:IPlayer;
		
		private var viewEventDispatcher:EventDispatcher;
		private var modelEventDispatcher:EventDispatcher;
		private var controllerEventDispatcher:EventDispatcher;
		
		private var id:String;
		private var client:String;
		private var version:String;
		
		public function PlayerV4Emulation(player:IPlayer) {
			viewEventDispatcher = new EventDispatcher();
			modelEventDispatcher = new EventDispatcher();
			controllerEventDispatcher = new EventDispatcher();
				
			_player = player;
			_player.addEventListener(PlayerEvent.JWPLAYER_READY, playerReady);
		}
		
		public static function getInstance(player:IPlayer):PlayerV4Emulation {
			if (!instance) {
				instance = new PlayerV4Emulation(player);
			}
			return instance;
		}
		
		private function playerReady(evt:PlayerEvent):void {
			id = evt.id;
			client = evt.client;
			version = evt.version;
			 
			dispatchEvent(new com.events.PlayerEvent(com.events.PlayerEvent.READY));
			setupListeners();
		}
		
		private function setupListeners():void {
			
			var m:Model;
			var v:IControlbarComponent;
			var c:Controller
			
			_player.addEventListener(PlayerEvent.JWPLAYER_ERROR, errorHandler);
			
			_player.addEventListener(MediaEvent.JWPLAYER_MEDIA_BUFFER, mediaBuffer);
			_player.addEventListener(MediaEvent.JWPLAYER_MEDIA_ERROR, mediaError);
			_player.addEventListener(MediaEvent.LOADEDJWPLAYER_MEDIA, mediaLoaded);
			_player.addEventListener(MediaEvent.JWPLAYER_MEDIA_TIME, mediaTime);
			_player.addEventListener(MediaEvent.JWPLAYER_MEDIA_VOLUME, mediaVolume);
			_player.addEventListener(MediaEvent.JWPLAYER_MEDIA_MUTE, mediaMute);
			_player.addEventListener(MediaEvent.JWPLAYER_MEDIA_META, mediaMeta);
			_player.addEventListener(MediaEvent.JWPLAYER_MEDIA_COMPLETE, mediaComplete);
			_player.addEventListener(PlayerStateEvent.JWPLAYER_PLAYER_STATE, stateHandler);

			_player.addEventListener(ViewEvent.JWPLAYER_VIEW_FULLSCREEN, viewFullscreen);
			_player.addEventListener(ViewEvent.JWPLAYER_VIEW_ITEM, viewItem);
			_player.addEventListener(ViewEvent.JWPLAYER_VIEW_LOAD, viewLoad);
			_player.addEventListener(ViewEvent.JWPLAYER_VIEW_MUTE, viewMute);
			_player.addEventListener(ViewEvent.JWPLAYER_VIEW_NEXT, viewNext);
			_player.addEventListener(ViewEvent.JWPLAYER_VIEW_PAUSE, viewPause);
			_player.addEventListener(ViewEvent.JWPLAYER_VIEW_PLAY, viewPlay);
			_player.addEventListener(ViewEvent.JWPLAYER_VIEW_PREV, viewPrev);
			_player.addEventListener(ViewEvent.JWPLAYER_VIEW_SEEK, viewSeek);
			_player.addEventListener(ViewEvent.JWPLAYER_VIEW_STOP, viewStop);
			_player.addEventListener(ViewEvent.JWPLAYER_VIEW_VOLUME, viewVolume);
			
			_player.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_ITEM, playlistItem);
			_player.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_LOADED, playlistLoad);
		}
		
		// Player Event Handlers
		
		private function errorHandler(evt:PlayerEvent):void {
			controllerEventDispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.ERROR, {message:evt.message, id:id, client:client, version:version}));
		}
		
	
		// Media Event Handlers
		//刚开始播放时候的缓冲事件
		private function mediaBuffer(evt:MediaEvent):void 
		{
			modelEventDispatcher.dispatchEvent(new ModelEvent(ModelEvent.BUFFER, {percentage:evt.bufferPercent, id:id, client:client, version:version}));
		}
		
		private function mediaError(evt:MediaEvent):void 
		{
			modelEventDispatcher.dispatchEvent(new ModelEvent(ModelEvent.ERROR, {message:evt.message, id:id, client:client, version:version}));
		}
		
		private function mediaLoaded(evt:MediaEvent):void {
			modelEventDispatcher.dispatchEvent(new ModelEvent(ModelEvent.LOADED, {loaded:0, total:0, offset:0, id:id, client:client, version:version}));
		}
		
		private function mediaTime(evt:MediaEvent):void {
			modelEventDispatcher.dispatchEvent(new ModelEvent(ModelEvent.TIME, {duration:evt.duration, position:evt.position, id:id, client:client, version:version}));
		}
		
		private function mediaVolume(evt:MediaEvent):void 
		{
			controllerEventDispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.VOLUME, {percentage:evt.volume, id:id, client:client, version:version}));
		}
		
		private function mediaMute(evt:MediaEvent):void {
			controllerEventDispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.MUTE, {state:evt.mute, id:id, client:client, version:version}));
		}
		

		private function mediaMeta(evt:MediaEvent):void {
			evt.metadata['id'] = id;
			evt.metadata['client'] = client;
			evt.metadata['version'] = version;
			modelEventDispatcher.dispatchEvent(new ModelEvent(ModelEvent.META, evt.metadata));
		}
		
		private function mediaComplete(evt:MediaEvent):void {
			modelEventDispatcher.dispatchEvent(new ModelEvent(ModelEvent.STATE, {id:id, oldstate:_player.state, newstate:ModelStates.COMPLETED}));
		}
		
		private function stateHandler(evt:PlayerStateEvent):void 
		{
			if (evt.newstate == PlayerState.IDLE && (evt.oldstate == PlayerState.BUFFERING || evt.oldstate == PlayerState.PLAYING)) 
			{
				controllerEventDispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.STOP, {id:id, client:client, version:version}));
			}
			
			modelEventDispatcher.dispatchEvent(new ModelEvent(ModelEvent.STATE, {id:id, oldstate:evt.oldstate, newstate:evt.newstate}));
		}
		
		// View Event Handlers

		private function viewFullscreen(evt:ViewEvent):void {
			viewEventDispatcher.dispatchEvent(new com.events.ViewEvent(com.events.ViewEvent.FULLSCREEN, {state:evt.data, id:id, client:client, version:version}));
		}
		
		private function viewItem(evt:ViewEvent):void {
			viewEventDispatcher.dispatchEvent(new com.events.ViewEvent(com.events.ViewEvent.ITEM, {index:evt.data, id:id, client:client, version:version}));
		}

		private function viewLoad(evt:ViewEvent):void {
			viewEventDispatcher.dispatchEvent(new com.events.ViewEvent(com.events.ViewEvent.LOAD, {object:evt.data, id:id, client:client, version:version}));
		}
		
		private function viewMute(evt:ViewEvent):void 
		{
			viewEventDispatcher.dispatchEvent(new com.events.ViewEvent(com.events.ViewEvent.MUTE, {state:evt.data, id:id, client:client, version:version}));
			controllerEventDispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.MUTE, {state:evt.data, id:id, client:client, version:version}));
		}
		
		private function viewNext(evt:ViewEvent):void {
			viewEventDispatcher.dispatchEvent(new com.events.ViewEvent(com.events.ViewEvent.NEXT, {id:id, client:client, version:version}));
		}
		
		private function viewPause(evt:ViewEvent):void {
			viewEventDispatcher.dispatchEvent(new com.events.ViewEvent(com.events.ViewEvent.PLAY, {state:false, id:id, client:client, version:version}));
			controllerEventDispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.PLAY, {state:false, id:id, client:client, version:version}));
		}

		private function viewPlay(evt:ViewEvent):void {
			viewEventDispatcher.dispatchEvent(new com.events.ViewEvent(com.events.ViewEvent.PLAY, {state:true, id:id, client:client, version:version}));
			controllerEventDispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.PLAY, {state:true, id:id, client:client, version:version}));
		}
		
		private function viewPrev(evt:ViewEvent):void {
			viewEventDispatcher.dispatchEvent(new com.events.ViewEvent(com.events.ViewEvent.PREV, {id:id, client:client, version:version}));
		}
		
		private function viewRedraw(width:Number, height:Number):void 
		{
			viewEventDispatcher.dispatchEvent(new com.events.ViewEvent(com.events.ViewEvent.REDRAW, {id:id, client:client, version:version}));
			controllerEventDispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.RESIZE, {width:width, height:height, fullscreen:_player.fullscreen, client:client, version:version}));
		}

		private function viewSeek(evt:ViewEvent):void 
		{
			viewEventDispatcher.dispatchEvent(new com.events.ViewEvent(com.events.ViewEvent.SEEK, {position:evt.data, id:id, client:client, version:version}));
			controllerEventDispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.SEEK, {position:evt.data, id:id, client:client, version:version}));
		}
		
		private function viewStop(evt:ViewEvent):void 
		{
			viewEventDispatcher.dispatchEvent(new com.events.ViewEvent(com.events.ViewEvent.STOP, {id:id, client:client, version:version}));
		}
		
		private function viewVolume(evt:ViewEvent):void {
			viewEventDispatcher.dispatchEvent(new com.events.ViewEvent(com.events.ViewEvent.VOLUME, {state:evt.data, id:id, client:client, version:version}));
			controllerEventDispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.VOLUME, {percentage:evt.data, id:id, client:client, version:version}));
		}
		
		// Playlist Event Handlers
		
		private function playlistItem(evt:PlaylistEvent):void {
			controllerEventDispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.ITEM, {index:_player.playlist.currentIndex, id:id, client:client, version:version}));
		}

		private function playlistLoad(evt:PlaylistEvent):void {
			controllerEventDispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.PLAYLIST, {playlist:playlistToArray(_player.playlist), id:id, client:client, version:version}));
		}
		
		
		// Listeners

		public override function addModelListener(type:String, listener:Function):void {
			modelEventDispatcher.addEventListener(type, listener);
		} 
		public override function removeModelListener(type:String, listener:Function):void {
			modelEventDispatcher.removeEventListener(type, listener);
		} 

		public override function addViewListener(type:String, listener:Function):void {
			viewEventDispatcher.addEventListener(type, listener);
		} 
		public override function removeViewListener(type:String, listener:Function):void {
			viewEventDispatcher.removeEventListener(type, listener);
		} 

		public override function addControllerListener(type:String, listener:Function):void {
			controllerEventDispatcher.addEventListener(type, listener);
		} 
		public override function removeControllerListener(type:String, listener:Function):void {
			controllerEventDispatcher.removeEventListener(type, listener);
		}
		
		// Event "dispatcher"
		
		public override function sendEvent(typ:String, prm:Object=undefined) : void {
			Logger.log("V4 emulator sending event: " + typ + " " + Strings.print_r(prm));
			switch (typ) {
				case com.events.ViewEvent.FULLSCREEN:
					_player.fullscreen = prm;
					break;
				case com.events.ViewEvent.ITEM:
					_player.playlistItem(Number(prm));
					break;
				case com.events.ViewEvent.LINK:
					_player.link(Number(prm));
					break;
				case com.events.ViewEvent.LOAD:
					_player.load(prm);
					break;
				case com.events.ViewEvent.MUTE:
					if (prm != null && prm != "") {
						_player.mute = (prm != "false" && prm != 0);
					} else {
						_player.mute = !_player.mute;
					}
					break;
				case com.events.ViewEvent.NEXT:
					_player.playlistNext();
					break;
				case com.events.ViewEvent.PLAY:
					if (prm == null || prm == "") {
						if (_player.state == PlayerState.PAUSED || _player.state == PlayerState.IDLE) {
							prm = "true";
						} else {
							prm = "false";
						}
					} 
					if (prm != null && Strings.serialize(prm.toString()) == false) {
						_player.pause();
					} else {
						_player.play();
					}
					break;
				case com.events.ViewEvent.PREV:
					_player.playlistPrev();
					break;
				case com.events.ViewEvent.REDRAW:
					_player.redraw();
					break;
				case com.events.ViewEvent.SEEK:
					_player.seek(Number(prm));
					break;
				case com.events.ViewEvent.STOP:
					_player.stop();
					break;
				case com.events.ViewEvent.TRACE:
					Logger.log(prm);
					break;
				case com.events.ViewEvent.VOLUME:
					_player.volume(Number(prm));
					break;
			}
		} 

		public override function get config():Object {
			var cfg:Object = {};
			var descType:XML = describeType(_player.config)
			for each (var i:String in descType.accessor.@name) {
				if (_player.config[i] != null) {
					cfg[i] = Strings.serialize(_player.config[i].toString());
				}
			}
			
			for each (var j:String in _player.config.pluginIds) {
				var pluginConfig:PluginConfig = _player.config.pluginConfig(j);
				for (var k:String in pluginConfig){
					cfg[j+"."+k] = pluginConfig[k];
				}
			}

			switch(_player.state) {
				case PlayerState.BUFFERING:
					cfg['state'] = ModelStates.BUFFERING;
					break;
				case PlayerState.PLAYING:
					cfg['state'] = ModelStates.PLAYING;
					break;
				case PlayerState.PAUSED:
					cfg['state'] = ModelStates.PAUSED;
					break;
				case PlayerState.IDLE:
					if (_player.playlist.currentIndex > 0 && _player.playlist.currentIndex == (_player.playlist.length-1)) {
						cfg['state'] = ModelStates.COMPLETED;
					} else {
						cfg['state'] = ModelStates.IDLE;
					}
					break;
			}

			cfg['fullscreen'] = _player.fullscreen;
			cfg['version'] = _player.version;
			cfg['item'] = _player.playlist.currentIndex;
			cfg['level'] = _player.playlist.currentItem ? _player.playlist.currentItem.currentLevel : 0;
			
			return cfg;
		} 

		public override function get playlist():Array {
			return playlistToArray(_player.playlist);
		}
		
		private function playlistToArray(list:IPlaylist):Array {
			var arry:Array = [];
			
			for (var i:Number=0; i < list.length; i++) {
				arry.push(playlistItemToObject(list.getItemAt(i)));
			}
			
			return arry;
		}
		
		private function playlistItemToObject(item:PlaylistItem):Object 
		{
			
			var obj:Object = {
				'author':		item.author,
				'date':			item.date,
				'description':	item.description,
				'duration':		item.duration,
				'file':			item.file,
				'image':		item.image,
				'link':			item.link,
				'mediaid':		item.mediaid,
				'start':		item.start,
				'streamer':		item.streamer,
				'tags':			item.tags,
				'title':		item.title,
				'type':			item.provider
			};
			
			for (var i:String in item) {
				obj[i] = item[i];
			}
			
			if (item.levels.length > 0) {
				obj['levels'] = [];
				for each (var level:PlaylistItemLevel in item.levels) {
					obj['levels'].push({url:level.file, bitrate:level.bitrate, width:level.width});
				}
			}
			
			return obj;
		}
		
		public override function getPluginConfig(plugin:Object):Object {
			if (plugin is IPlugin) {
				return _player.config.pluginConfig((plugin as IPlugin).id)
			} else if (plugin is V4Plugin) {
				return _player.config.pluginConfig((plugin as V4Plugin).pluginId);
			} else if ((plugin as DisplayObject).parent is V4Plugin) {
				return _player.config.pluginConfig((plugin.parent as V4Plugin).pluginId);
			} else if (plugin is IDockComponent) {
				return _player.config.pluginConfig('dock');
			} else if (plugin is IDisplayComponent) {
				return _player.config.pluginConfig('display');
			} else if (plugin is IControlbarComponent) {
				return _player.config.pluginConfig('controlbar');
			} else if (plugin is IPlaylistComponent) {
				return _player.config.pluginConfig('playlist');
			} else {
				return new PluginConfig('');
			}
		}
		
		public function resize(width:Number, height:Number):void 
		{
			viewRedraw(width, height);
		} 
		
		public override function getPlugin(plugin:String):Object {
			var result:Object;
			switch (plugin){
				case 'dock':
					result = _player.controls.dock as Object;
					break;
				case 'controlbar':
					result = _player.controls.controlbar as Object;
					break;
				case 'display':
					result = _player.controls.display as Object;
					break;
				case 'playlist':
					result = _player.controls.playlist as Object;
					break;
				default:
					// Backwards compatibility for 4.x plugins
					try {
						result = (_player as Object).getPlugin(plugin);
					} catch (e:Error) {}
			}
			return result;
		}
	}
}