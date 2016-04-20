package visuall.ovp
{
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.materials.utils.SimpleVideoPlayer;
	import away3d.materials.utils.VideoInfo;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import jonrowe.views.Canvas3D;
	
	/**
	 * PanoVideoNav allows to navigate in the panoramic video of a PanoSphere by changing properties of its associated camera. 
	 * 
	 * - Moving the mouse while pushing the click button changes the orientation of the camera (pan and tilt angles) which allows navigation within the panoramic image;
	 * - Pressing the "up"/"down" keys changes the field of view of the lens of the camera.
	 * The video can be paused/played by pressing the space bar.
	 * A debug window can be displayed for showing navigation information.
	 * 
	 * @author Louis Dorard (louis@dorard.me), Visu'all Interactive / Concept Immo Global
	 * 
	 */
	public class PanoVideoNav extends Canvas3D
	{
		private var pSphere:PanoSphere;
		
		// video handling variables
		private var isPlaying:Boolean = true; // indicates whether video is playing
		
		// camera handling variables
		private var isInteracting:Boolean = false; // indicates whether user is maintaining click button pushed
		private var onPointerDownMouseX:Number = 0; // x coordinate when click occurred 
		private var onPointerDownMouseY:Number = 0; // y...
		private var onPointerDownPanAngle:Number = 0; // longitude when click occurred
		private var onPointerDownTiltAngle:Number = 0; // latitude...
		private var keyIsDown:Boolean = false; // indicates whether a key is being pressed
		private var lastKey:uint;
		
		// constants
		private var minFov:int = 50; // minimal field of view
		private var maxFov:int = 100; // maximal...
		private var zoomStep:int = 2;
		private var lookStep:int = 2;
		private var cameraSpeed:Number = 0.3;
		
		// debug
		//private var stats:AwayStats;
		//private var dPanel:DebugPanel;
		
		public function PanoVideoNav(assetWidth:int, assetHeight:int)
		{
			_videoInfo=new VideoInfo();
		  
			super(_videoInfo, assetWidth, assetHeight);
		}
		
		private var _videoInfo:VideoInfo;
		public function get videoInfo():VideoInfo
		{
			return _videoInfo;
		}
		/**
		 * Displays debug information on the Away scene and the navigation within the video. 
		 * 
		 */
		override protected function initDebug():void {
			//stats = new AwayStats(pSphere.view);
			//stats.x = 5;
			//stats.y = 5;
			//addChild(stats);
			
			//dPanel = new DebugPanel(pSphere);
			//addChild(dPanel);
		}
		
		/**
		 * Creates a PanoSphere instance with specified asset properties and returns the associated view for use in the Canvas3D.  
		 * @param args
		 * @return 
		 * 
		 */
		override protected function initView(...args):View3D
		{
			var videoPlayer:*=args[0][0];
			var assetWidth:int=args[0][1];
			var assetHeight:int=args[0][2];
			pSphere = new PanoSphere(videoPlayer, assetWidth, assetHeight);
			return pSphere.view;
		}
		
		/**
		 * Adds listeners for pressing keys and moving the mouse while pushing click button. 
		 * 
		 */
		override protected function initEventListeners():void
		{
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onPointerDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onPointerUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		}
		
		public function StartInitDraw():void
		{
			pSphere.InitUpdate();
		}
		
		/**
		 * Render loop called every frame. Before we render the scene, we look for any interactions from the user that may affect the camera. 
		 * @param event
		 * 
		 */
		override protected function onEnterFrame(event: Event):void
		{
			// keyboard controls
			if(keyIsDown)
			{
				switch(lastKey)
				{
					case Keyboard.DOWN	: pSphere.lens.fieldOfView -= zoomStep; break;
					case Keyboard.UP	: pSphere.lens.fieldOfView += zoomStep; break;
				}
			}
			
			// mouse movement when button is pressed causes camera to move
			if (isInteracting) {
				pSphere.cameraController.panAngle = cameraSpeed*(stage.mouseX - onPointerDownMouseX) + onPointerDownPanAngle;
				pSphere.cameraController.tiltAngle = cameraSpeed*(stage.mouseY - onPointerDownMouseY) + onPointerDownTiltAngle;
			}
			
			// make sure we don't go past the extremal values
			if (pSphere.lens.fieldOfView < minFov) { pSphere.lens.fieldOfView = minFov; }
			if (pSphere.lens.fieldOfView > maxFov) { pSphere.lens.fieldOfView = maxFov; }
			
			pSphere.cameraController.update();
			//trace("正在渲染：：");
			pSphere.view.render();
			
			
		}
		
		/**
		 * Indicate that the user is interacting when mouse click button is pressed, and record the mouse's position and the camera pan and tilt angles at that moment.
		 * @param event
		 * 
		 */
		private function onPointerDown(event:MouseEvent):void
		{
			onPointerDownMouseX = stage.mouseX;
			onPointerDownMouseY = stage.mouseY;
			onPointerDownPanAngle = pSphere.cameraController.panAngle;
			onPointerDownTiltAngle = pSphere.cameraController.tiltAngle;
			isInteracting = true;
		}
		
		/**
		 * Indicate that the user has finished interacting when mouse click button is released 
		 * @param event
		 * 
		 */
		private function onPointerUp(event:MouseEvent):void
		{
			isInteracting = false;
		}

		/**
		 * Indicate that the user is pressing a key and record which. 
		 * @param e
		 * 
		 */
		private function onKeyDown(e:KeyboardEvent):void
		{
			lastKey = e.keyCode;
			keyIsDown = true;
		}
		/**
		 * Indicate that the user has released the key being pressed. 
		 * @param e
		 * 
		 */
		private function onKeyUp(e:KeyboardEvent):void
		{
			keyIsDown = false;
		}
	}
}