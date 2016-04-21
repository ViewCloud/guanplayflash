
package com.tanplayer.utils {

	
	import com.tanplayer.player.Player;
	import com.tanplayer.view.Logo;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.text.TextFormat;

	/**
	 * Maintains a static reference to the stage and root of the application.
	 *
	 * @author Pablo Schklowsky
	 */
	public class RootReference 
	{
        /** The root DisplayObject of the application.  **/ 
		public static var root:DisplayObject;
		/** A reference to the stage. **/ 
		public static var stage:Stage;
		public static var _seekuser:Boolean;
		public static var videoadBo:Boolean;
		public static var _lianboType:Boolean=false;//联播模式
		
		public static var _bandWidth:Number;
		public static var _currentBpsid:Number=0;//当前码流
		
		public static var _controlBarHeight:Number=54;//从fla里取得
		public static var _player:Player;
        public static var _error:Boolean;//如果为true不能切换码流和暂停
		//public static var _connectSucess:Boolean;//重连成功
		private static var _flashvarObject:Object//从外部获取到的flashvar
		
		public static function  get flashvarObject():Object
		{
			return _flashvarObject;
		}
		
		public static function  set flashvarObject(obvar:Object):void
		{
			_flashvarObject=obvar;
		}
		
		[Embed(source='assets/logo.png')]
		private var Logopng:Class;
		
		private static var logec:DisplayObject;
		
		public function RootReference(displayObj:DisplayObject) 
		{
			if (!RootReference.root) 
			{
				RootReference.root = displayObj.root;
				RootReference.stage = displayObj.stage;
				
				try 
				{
					Security.allowDomain("*");
				} 
				catch(e:Error) 
				{
					// This may not work in the AIR testing suite
				}
				
				
				logec=new Logopng();
				
				
				promptShape.addChild(logec);
				promptShape.addChild(txt);
				txt.text="正在为您切换码流，请稍候";
				
				var txtf:TextFormat=new TextFormat();
				txtf.color=0xffffff;
				txtf.font="Microsoft yahei";
				txtf.size=20;
				
				
				logec.visible=false;
				txt.visible=false;
				txt.setTextFormat(txtf);
			}
		}
		
		private static var txt:TextField=new TextField();
		private static var promptShape:Sprite=new Sprite();
		
		public static var currentStream:String;
		
		public static function ShowStreamsChange():void
		{
			promptShape.alpha=1;
			promptShape.graphics.clear();
			promptShape.graphics.beginFill(0x666666,0);
			promptShape.graphics.drawRect(0,0,RootReference.stage.stageWidth,RootReference.stage.stageHeight);
			promptShape.graphics.endFill();
			txt.width=txt.textWidth+10;
			txt.height=txt.textHeight+6;
			//txt.opaqueBackground=0x00ff00;
			txt.x=(RootReference.stage.stageWidth-txt.width)/2;
			txt.y=(RootReference.stage.stageHeight-txt.height)/2;
			
			logec.x=(RootReference.stage.stageWidth-logec.width)/2;
			logec.y=(RootReference.stage.stageHeight-logec.height)/2;
			
			logec.visible=true;
			txt.visible=true;
			
			promptShape.name="add";
			RootReference.stage.addChildAt(promptShape,RootReference.stage.numChildren);
		}
		
		public static function ShowCover():void
		{
			if(txt.visible==true) return;
			promptShape.graphics.clear();
			promptShape.graphics.beginFill(0x666666,0);
			promptShape.graphics.drawRect(0,0,RootReference.stage.stageWidth,RootReference.stage.stageHeight);
			promptShape.graphics.endFill();
			
			promptShape.name="add";
			RootReference.stage.addChildAt(promptShape,RootReference.stage.numChildren);
		}
		
		public static function ClearShowInfo():void
		{
			if(promptShape.name=="add")
			{
				RootReference.stage.removeChild(promptShape);
				promptShape.name="";
			}
			
		}
		
		public static var currentID:String;
		
		
		
		
		public static function ResizeAlertPosition():void
		{
			//RootReference.imdAlert.y =RootReference.imdAlert.height/2;
			//RootReference.imdAlert.x =(RootReference.stage.stageWidth- RootReference.imdAlert.width)/2+RootReference.imdAlert.width/2;
		}
		
		public static function ResizeAlertCenterPosition():void
		{
			//RootReference.imdAlert.y =(RootReference.stage.stageHeight- RootReference.imdAlert.height)/2+RootReference.imdAlert.height/2;
			//RootReference.imdAlert.x =(RootReference.stage.stageWidth- RootReference.imdAlert.width)/2+RootReference.imdAlert.width/2;
		}
		
		public static function AlertHide():void
		{
		    //if(RootReference.imdAlert.name == "currentAudio") return;
			//RootReference.stage.removeChild(RootReference.imdAlert);
			//RootReference.imdAlert.name="removed";
		}
	}
}