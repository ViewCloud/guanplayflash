
package com.tanplayer.media 
{
	import com.tanplayer.model.PlayerConfig;
	import com.tanplayer.model.PlaylistItem;
	import com.tanplayer.utils.RootReference;
	
	import flash.net.NetConnection;
	import flash.system.Security;
	import flash.utils.setTimeout;
	
//	import org.osmf.containers.MediaContainer;
//	import org.osmf.media.DefaultMediaFactory;
//	import org.osmf.media.MediaElement;
//	import org.osmf.media.MediaPlayer;
//	import org.osmf.media.URLResource;
//	import org.osmf.net.DynamicStreamingItem;
//	import org.osmf.net.DynamicStreamingResource;
//	import org.osmf.samples.MediaContainerSprite;
	
	
	public class AppleHttpMediaProvider extends MediaProvider 
	{
		
//		public var videoContainer:MediaContainerSprite;
//		
//	    Security.LOCAL_TRUSTED;
//	    private var mediaElement:MediaElement;
//        private var factory:DefaultMediaFactory = new DefaultMediaFactory();
//		private var player:MediaPlayer = new MediaPlayer();
//		private var isScrubbing:Boolean = false;
//		private var fullscreenCapable:Boolean = false;
//		private var hardwareScaleCapable:Boolean = false;
//		private var saveVideoObjX:Number;
//		private var saveVideoObjY:Number;
//		private var saveVideoObjW:Number;
//		private var saveVideoObjH:Number;
//		private var saveStageW:Number;
//		private var saveStageH:Number;
//		private var adjVideoObjW:Number;
//		private var adjVideoObjH:Number;
//		private var streamName:String;
//		private var netconnection:NetConnection;		
//		private var PlayVersionMin:Boolean;
//		private var streamNames:XML;
//		private var streamsVector:Vector.<DynamicStreamingItem> = new Vector.<DynamicStreamingItem>();			
//		private var dynResource:DynamicStreamingResource = null;
//		
		public function AppleHttpMediaProvider() 
		{
			super('applehttp');
			//videoContainer = new MediaContainerSprite();
		}
//		
//		
//		public override function initializeMediaProvider(cfg:PlayerConfig):void 
//		{
//			super.initializeMediaProvider(cfg);
//		    videoContainer.container = new MediaContainer();
//		}
//		
//		/** play **/
//		override public function load(itm:PlaylistItem):void 
//		{
//			LoadStream(itm.applehttp);
//		}
//		
//		private function LoadStream(url:String):void
//		{	
//		    mediaElement = factory.createMediaElement(new URLResource(url));
//			
//			if (dynResource != null)
//				mediaElement.resource=dynResource;
//			
//			player.media = mediaElement;	
//			videoContainer.container.addMediaElement(mediaElement);	
//			player.autoPlay = true;
//	        
//			setTimeout(Txdf,3000);
//			
//			
//			RootReference.stage.addChildAt(videoContainer,(RootReference.stage.numChildren-1));
//		}
//		
//		private function Txdf():void
//		{
//			player.switchDynamicStreamIndex(0);
//		}
	}
}