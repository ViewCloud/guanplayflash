/**
 * Model for playback of GIF/JPG/PNG images.
 **/
package com.tanplayer.media {
	import com.events.*;
	import com.tanplayer.events.MediaEvent;
	import com.tanplayer.model.PlayerConfig;
	import com.tanplayer.model.PlaylistItem;
	import com.tanplayer.player.PlayerState;
	import com.tanplayer.utils.Draw;
	import com.tanplayer.utils.Logger;
	
	import flash.display.*;
	import flash.events.*;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.*;


	public class ImageMediaProvider extends MediaProvider {
		/** Loader that loads the image. **/
		private var _loader:Loader;
		/** ID for the position _postitionInterval. **/
		private var _postitionInterval:Number;


		/** Constructor; sets up listeners **/
		public function ImageMediaProvider() 
		{
			super('image');
		}


		public override function initializeMediaProvider(cfg:PlayerConfig):void 
		{
			super.initializeMediaProvider(cfg);
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderHandler);
			_loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
		}


		/** load image into screen **/
		override public function load(itm:PlaylistItem):void {
			_item = itm;
			_position = 0;
			_loader.load(new URLRequest(item.file), new LoaderContext(true));
			setState(PlayerState.BUFFERING);
			sendBufferEvent(0);
		}


		/** Catch errors. **/
		private function errorHandler(evt:ErrorEvent):void {
			stop();
			error(evt.text);
		}


		/** Load and place the image on stage. **/
		private function loaderHandler(evt:Event):void 
		{
			media = _loader;
			sendMediaEvent(MediaEvent.LOADEDJWPLAYER_MEDIA);
			try {
				Draw.smooth(_loader.content as Bitmap);
			} catch (e:Error) {
				Logger.log("Could not smooth image file: " + e.message);
			}
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, {metadata: {height: evt.target.height, width: evt.target.width}});
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_BUFFER_FULL);
		}


		/** Pause playback of the_item. **/
		override public function pause():void {
			clearInterval(_postitionInterval);
			super.pause();
		}


		/** Resume playback of the_item. **/
		override public function play():void {
			_postitionInterval = setInterval(positionInterval, 100);
			super.play();
		}


		/** Interval function that pings the _position. **/
		protected function positionInterval():void {
			if (state != PlayerState.PLAYING) { return; }

			_position = Math.round(position * 10 + 1) / 10;
			if (position < _item.duration) {
				sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_TIME, {position: position, duration: item.duration});
			} else if (_item.duration > 0) {
				complete();
			}
		}


		/** Send load progress to player. **/
		private function progressHandler(evt:ProgressEvent):void {
			var pct:Number = Math.round(evt.bytesLoaded / evt.bytesTotal * 100);
			sendBufferEvent(pct);
		}


		/** Seek to a certain _position in the_item. **/
		override public function seek(pos:Number):void {
			clearInterval(_postitionInterval);
			_position = pos;
			play();
		}


		/** Stop the image _postitionInterval. **/
		override public function stop():void {
			if (_loader.contentLoaderInfo.bytesLoaded != _loader.contentLoaderInfo.bytesTotal) {
				_loader.close();
			} else {
				_loader.unload();
			}
			clearInterval(_postitionInterval);
			super.stop();
		}
	}
}