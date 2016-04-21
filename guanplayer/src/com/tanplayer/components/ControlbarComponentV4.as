/*
*控制面板类 
*场景调整音量元件位置调整 都在fla里调
*fla文件中元件属性中的名字获取注意元件一定是MC
*还有些老的元件隐藏了 以后删掉
这里不要再修正了位置都在fla里改 fla元件分左右两边拉神
*/
package com.tanplayer.components 
{
	import com.adobe.serialization.json.JSON;
	import com.events.AbstractView;
	import com.greensock.TweenLite;
	import com.greensock.easing.Back;
	import com.greensock.easing.Circ;
	import com.greensock.easing.Cubic;
	import com.greensock.easing.Expo;
	import com.tanplayer.events.MediaEvent;
	import com.tanplayer.events.PlayerEvent;
	import com.tanplayer.events.PlayerStateEvent;
	import com.tanplayer.events.PlaylistEvent;
	import com.tanplayer.events.ViewEvent;
	import com.tanplayer.interfaces.IControlbarComponent;
	import com.tanplayer.media.RTMPMediaProvider;
	import com.tanplayer.model.Model;
	import com.tanplayer.player.CallJSFunction;
	import com.tanplayer.player.IPlayer;
	import com.tanplayer.player.JavascriptAPI;
	import com.tanplayer.player.Player;
	import com.tanplayer.player.PlayerState;
	import com.tanplayer.plugins.PluginConfig;
	import com.tanplayer.utils.Animations;
	import com.tanplayer.utils.Draw;
	import com.tanplayer.utils.Logger;
	import com.tanplayer.utils.RootReference;
	import com.tanplayer.utils.Stacker;
	import com.tanplayer.utils.Strings;
	import com.tanplayer.view.PlayerLayoutManager;
	
	import flash.accessibility.AccessibilityProperties;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	//import plugins.CommentView;
	public class ControlbarComponentV4 extends CoreComponent implements IControlbarComponent 
	{
		/** Reference to the original skin **/
		private var skin:Sprite;
		/** A list with all controls. **/
		private var stacker:Stacker;
		/** Timeout for hiding the  **/
		private var hiding:Number;
		/** When scrubbing, icon shouldn't be set. **/
		private var scrubber:MovieClip;
		/** Color object for frontcolor. **/
		private var front:ColorTransform;
		/** Color object for lightcolor. **/
		private var light:ColorTransform;
		/** The actions for all controlbar buttons. **/
		private var BUTTONS:Object;
		/** The actions for all sliders **/
		private var SLIDERS:Object = {timeSlider: ViewEvent.JWPLAYER_VIEW_SEEK};
		/** The button to clone for all custom buttons. **/
		private var clonee:MovieClip;
		/** Saving the block state of the controlbar. **/
		private var blocking:Boolean;
		/** Controlbar config **/
		private var controlbarConfig:PluginConfig;
		/** Animations handler **/
		private var animations:Animations;
		/** Last inserted button **/
		private var lastInsert:MovieClip;
		
		public function ControlbarComponentV4(player:IPlayer) 
		{
			super(player, "controlbar");
			
			
			animations = new Animations(this);
			controlbarConfig = _player.config.pluginConfig("controlbar");
			if (!controlbarConfig['margin']) controlbarConfig['margin'] = 0;	
			
			_player = player;
			// 按钮名称和相对应的事件
			BUTTONS = 
				{playButton: ViewEvent.JWPLAYER_VIEW_PLAY,
					pauseButton: ViewEvent.JWPLAYER_VIEW_PAUSE,
					fullscreenButton: ViewEvent.JWPLAYER_VIEW_FULLSCREEN,
					normalscreenButton: ViewEvent.JWPLAYER_VIEW_FULLSCREEN,
					muteButton: ViewEvent.JWPLAYER_VIEW_MUTE,
					unmuteButton: ViewEvent.JWPLAYER_VIEW_MUTE
					
				};
			
			skin = _player.skin.getSWFSkin().getChildByName('controlbar') as Sprite;
			//初始化宽度
			
			//trace("skin.width"+skin.width);
			
			if(_player.config.showtanmu==true)
			{
//				getSkinComponent('tanmuclosemc').addEventListener(MouseEvent.CLICK,TumanCloseHandler);
//				getSkinComponent('opentanmumc').addEventListener(MouseEvent.CLICK,TumanOpenHandler);
//				
//				getSkinComponent('tanmuclosemc').visible = true;
//				getSkinComponent('opentanmumc').visible = false;
//				
//				//弹幕开关
//				(getSkinComponent('tanmuclosemc') as MovieClip).buttonMode = true;
//				(getSkinComponent('opentanmumc') as MovieClip).buttonMode = true;
				
				getSkinComponent('tanmuclosemc').visible = false;
				getSkinComponent('opentanmumc').visible = false;
			}
			else
			{
				getSkinComponent('tanmuclosemc').visible = false;
				getSkinComponent('opentanmumc').visible = false;
				
				
			}
			
			
			var jsAPI:JavascriptAPI= new JavascriptAPI(_player,skin);
			
			skin.x = 0;
			skin.y = 0;
			addChild(skin);
			
			
			_player.addEventListener(PlayerStateEvent.JWPLAYER_PLAYER_STATE, stateHandler);
			_player.addEventListener(MediaEvent.JWPLAYER_MEDIA_TIME, timeHandler);
			_player.addEventListener(MediaEvent.JWPLAYER_MEDIA_MUTE, muteHandler);
			_player.addEventListener(MediaEvent.JWPLAYER_MEDIA_VOLUME, volumeHandler);
			_player.addEventListener(MediaEvent.JWPLAYER_MEDIA_BUFFER, timeHandler);
			_player.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_LOADED, itemHandler);
			_player.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_UPDATED, itemHandler);
			_player.addEventListener(PlaylistEvent.JWPLAYER_PLAYLIST_ITEM, itemHandler);
			_player.addEventListener(MediaEvent.M3U8_PLAY, M3u8PlayHandler);
			
			getSkinComponent('controlbarback').addEventListener(MouseEvent.MOUSE_MOVE,ControlBarMovHandler);
	

		    this.addEventListener(MouseEvent.ROLL_OVER,OverControlBarHandler);
			addEventListener(MouseEvent.ROLL_OUT,ControlBarOutHandler);
			RootReference.stage.addEventListener(Event.MOUSE_LEAVE,LeaveSWFHandler);
			
			stacker = new Stacker(skin as MovieClip);
			//初始化
			RootReference.stage.addEventListener(MouseEvent.MOUSE_MOVE,StageMoveHandler);
			
			setButtons();
			setColors();
			itemHandler();
			muteHandler();
			stateHandler();
			timeHandler();
			volumeHandler();
			
			//initDelay=setTimeout(ControlbarDelay,500);
			//(getSkinElementChild('timeSlider', 'icon') as MovieClip).mouseChildren=false;
			(getSkinComponent('timeSlider') as MovieClip).addChild(TanImageLoader.getInstance());
			
			(getSkinComponent('timeSlider') as MovieClip).addEventListener(MouseEvent.MOUSE_MOVE,TimeSliderMoveHandler);
			TanImageLoader.getInstance().y=-85;//缩略图位置
			TanImageLoader.getInstance().visible=false;
			
			
			urlLoaderKandian.addEventListener(Event.COMPLETE, DecodeJSONKandianHandler);
			
		}
		
		private function M3u8PlayHandler(val:*):void
		{
			((_player as Player).view.components.display as DisplayComponent).clearDisplay();

		}
		
		private function TimeSliderMoveHandler(e:MouseEvent):void
		{
			//trace("sdfffffff"+e.stageX);
			
			var timeArea:Number=((e.stageX/(getSkinElementChild('timeSlider', 'rail') as MovieClip).width)*_totalTime);
			var snapShotArr:Array=(_player as Player).controller.snapShotArr;
			var len:Number=snapShotArr.length;
			var imageUrl:String;
			
			for(var d:int=0;d<len;d++)
			{
				if(timeArea<snapShotArr[d].time)
				{
					imageUrl=snapShotArr[d].urls[1];
					break;
				}
			}
			
			if(imageUrl==null || imageUrl=="") return;
			
			TanImageLoader.getInstance().visible=true;
			trace(imageUrl);
			TanImageLoader.getInstance().LoaderImage(imageUrl);
			TanImageLoader.getInstance().x=e.stageX-TanImageLoader.getInstance().width/2;
        }
		
        public function AddKanPoint(val:Object):void
		{
			var kanpo:Kanpiont=new Kanpiont();
			
			
			(getSkinElementChild('timeSlider', 'kandian') as MovieClip).addChild(kanpo);
			
			kanpo.x=val.time/_totalTime*(getSkinElementChild('timeSlider', 'rail') as MovieClip).width;
			//trace("kanpo.x::::"+kanpo.x);
			kanpo.y=7;
			kanpo.name=val.txt;
			kanpo.addEventListener(MouseEvent.MOUSE_OVER,KandianOverHandler);
			
			kanpo.addEventListener(MouseEvent.MOUSE_OUT,KandianOutHandler);
			
		}
		
		
		
		
		public function DisposeKanPoint():void
		{
			var len:int=(getSkinElementChild('timeSlider', 'kandian') as MovieClip).numChildren;
			
			for(var d:int=0;d<len;d++)
			{
				(getSkinElementChild('timeSlider', 'kandian') as MovieClip).getChildAt(d).removeEventListener(MouseEvent.MOUSE_OVER,KandianOverHandler);
				(getSkinElementChild('timeSlider', 'kandian') as MovieClip).getChildAt(d).removeEventListener(MouseEvent.MOUSE_OUT,KandianOutHandler);
				
			}
			
			(getSkinElementChild('timeSlider', 'kandian') as MovieClip).removeChildren();
		}
		
		
		private function KandianOutHandler(e:MouseEvent):void
		{
			TanImageLoader.getInstance().ShowTxt("");
		}
		
		private function KandianOverHandler(e:MouseEvent):void
		{
			TanImageLoader.getInstance().ShowTxt(e.target.name);
		}
		
		private function TumanCloseHandler(e:MouseEvent):void
		{
			getSkinComponent('tanmuclosemc').visible = false;
			getSkinComponent('opentanmumc').visible = true;
			
			//CommentView.getInstance().ShowOrHideTanmu(false);
		}
		
		private function TumanOpenHandler(e:MouseEvent):void
		{
			getSkinComponent('tanmuclosemc').visible = true;
			getSkinComponent('opentanmumc').visible = false;
			
			//CommentView.getInstance().ShowOrHideTanmu(true);
		}
		
		private function OverControlBarHandler(e:MouseEvent):void
		{
			_controlBarOut = false;
		}
		
		
		
		private var _currentClickBtn:String="init";//当前点击的按钮名字
		
	
	    
		private function TimeSliderOverHandler(e:MouseEvent):void
		{
			
			ChangeBtnState();
		}
		
		
		private function ChangeBtnState():void
		{
			//var btnshade:MovieClip =getSkinComponent('btnshade') as MovieClip;

			Mouse.cursor = MouseCursor.AUTO;
			
			(getSkinComponent("pauseButton") as MovieClip).gotoAndStop(1);
			(getSkinComponent("playButton") as MovieClip).gotoAndStop(1);
			
			
			if(CallJSFunction.PLAYMODE=="small")
			{
				//(getSkinComponent("resizeBtn") as MovieClip).gotoAndStop(1);
			}
			else
			{
				//(getSkinComponent("resizeBtn") as MovieClip).gotoAndStop(3);
				//trace("122ee");
			}
			
			
			(getSkinComponent('fullscreenButton') as MovieClip).gotoAndStop(1);
			(getSkinComponent('normalscreenButton') as MovieClip).gotoAndStop(1);
			
			
			
			(getSkinComponent('tanmuclosemc') as MovieClip).gotoAndStop(1);
			(getSkinComponent('opentanmumc') as MovieClip).gotoAndStop(1);
			(getSkinComponent('normalscreenButton') as MovieClip).gotoAndStop(1);
			
		}
		
	   
	
		
		private var _timeHide:int;
		
		private function FineTimeSlider():void
		{
			//trace("outtt");
			flash.utils.clearTimeout(_timeHide);
			
			if(RootReference.stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				this.visible = false;
				((_player as Player).view.components.display as DisplayComponent).HideScaleBtn();
				//全屏控制面板隐藏
				Mouse.hide();
				
			}
			
			if(_overControlbar)return;
			//变细
			TimeSliderOutHandler();
		}
		
		private var _overControlbar:Boolean= false;
		//场景晃动 全屏显示
		private function StageMoveHandler(e:MouseEvent):void//动画
		{
			//if(!_controlBarOut)return;
			flash.utils.clearTimeout(_timeHide);
			_timeHide = setTimeout(FineTimeSlider,5000);
			
			if(RootReference.stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				this.visible = true;
				
				
				((_player as Player).view.components.display as DisplayComponent).ShowScaleBtn();
				Mouse.show();
			}
			
			
			if(e.stageY<=this.stage.stageHeight-this.height)
			{
				_overControlbar = false;
			}
			else
			{
				_overControlbar = true;
			}
			
			if(_player.state ==PlayerState.PAUSED)
			{
				return;
			}
			//变粗
			//if((getSkinElementChild('timeSlider', 'rail') as MovieClip).currentFrame>=12) return;//已经在变粗
			
			//(getSkinElementChild('timeSlider', 'icon') as MovieClip).gotoAndPlay(11);
			//(getSkinElementChild('timeSlider', 'done') as MovieClip).gotoAndPlay(11);
			//(getSkinElementChild('timeSlider', 'rail') as MovieClip).gotoAndPlay(11);
		}
		//鼠标离开flash
		public function LeaveSWFHandler(e:Event=null):void
		{
			//按钮skin
			//getSkinComponent('btnshade').visible = false;
			ChangeBtnState();
			//时间条
			TimeSliderOutHandler();	
			//音量条收缩
			_isVolumeSliderShow = false;
			HideVolume();
			
			//离开隐藏控制面板
			if(_player.config.playtype=="live")//直播
			{
				visible =false;
			}
			
			
			//SocketController.getInstance().lineNumTxt.visible=false;
		}
		
		//音量条收缩范围
		private function ControlBarMovHandler(e:MouseEvent):void
		{
			    //trace("this.mouseX::"+this.mouseX);
				//横向收缩
				if(this.mouseX<50 || this.mouseX>188)
				{
					_isVolumeSliderShow=false;
					HideVolume();
				}
				else
				{
					_isVolumeSliderShow=false;
				}
			
		}
		
		
		private var _controlBarOut:Boolean=false;
		
		private function ControlBarOutHandler(e:MouseEvent):void
		{
			_controlBarOut = true;
			this.ChangeBtnState();
			
			if(this.mouseY<=2)//
			{
				if(!_isVolumeSliderShow)
				{
					
				}
				else
				{
					_isVolumeSliderShow=false;
					HideVolume();
				}
			}
			
			_timeSliderOver = false;
		}
		
		private function TimeSliderOutHandler():void
		{
			if(_player.state ==PlayerState.PAUSED)
			{
				return;
			}
			
			if((getSkinElementChild('timeSlider', 'rail') as MovieClip).currentFrame==10) return;//鼠标移出FLASH是判断已经是细的了
			
			(getSkinElementChild('timeSlider', 'icon') as MovieClip).gotoAndPlay(1);
			(getSkinElementChild('timeSlider', 'done') as MovieClip).gotoAndPlay(1);
			(getSkinElementChild('timeSlider', 'rail') as MovieClip).gotoAndPlay(1);
		}
		
		/**
		 * Add a new button to the control
		 *
		 * @param icn	A graphic to show as icon
		 * @param nam	Name of the button
		 getSkinComponent('* @param hdl	The function to call when clicking the Button').
		 **/
		public function addButton(icon:DisplayObject, name:String, handler:Function=null):MovieClip 
		{
			var btn:MovieClip;
			
			if (getSkinComponent('linkButton') && getSkinElementChild('linkButton', 'back')) 
			{
				btn = Draw.clone(getSkinComponent('linkButton') as MovieClip) as MovieClip;
				btn.name = name + 'Button';
				btn.visible = true;
				btn.tabEnabled = true;
				btn.tabIndex = 6;
				var acs:AccessibilityProperties = new AccessibilityProperties();
				acs.name = name + 'Button';
				btn.accessibilityProperties = acs;
				skin.addChild(btn);
				var off:Number = Math.round((btn.height - icon.height) / 2);
				Draw.clear(btn['icon']);
				btn['icon'].addChild(icon);
				icon.x = icon.y = 0;
				btn['icon'].x = btn['icon'].y = off;
				btn['back'].width = icon.width + 2 * off;
				btn.buttonMode = true;
				btn.mouseChildren = false;
				btn.addEventListener(MouseEvent.CLICK, handler);
				if (front) {
					btn['icon'].transform.colorTransform = front;
					btn.addEventListener(MouseEvent.MOUSE_OVER, overHandler);
					btn.addEventListener(MouseEvent.MOUSE_OUT, outHandler);
				}
				if (lastInsert) {
					stacker.insert(btn, lastInsert);
				} else {
					stacker.insert(btn, getSkinComponent('linkButton') as MovieClip);
				}
				lastInsert = btn;
			}
			return btn;
		}
		
		
		public function removeButton(name:String):void 
		{
			skin.removeChild(getSkinComponent(name));
		}
		
		public function resize(width:Number, height:Number):void 
		{
			if (!(PlayerLayoutManager.testPosition(controlbarConfig['position']) || controlbarConfig['position'] == "over")) {
				skin.visible = false;
				return;
			}
			
			var wid:Number = width;
			var margin:Number = controlbarConfig['margin'];
			
			alpha=1;
			this.visible = true;
			
			if (controlbarConfig['position'] == 'over' || _player.fullscreen == true) 
			{
				x = margin;
				y = this.stage.stageHeight - RootReference._controlBarHeight;//31是控制面板背景图片高全屏露底
				//height - skin.height - margin;
				wid = width - 2 * margin;
				trace("全屏设置控制面板位置")
			}
			
			try 
			{
				getSkinComponent('fullscreenButton').visible = false;
				getSkinComponent('normalscreenButton').visible = false;
				if (stage['displayState'] && _player.config.height > 40) 
				{
					if (_player.fullscreen) 
					{
						getSkinComponent('fullscreenButton').visible = false;
						getSkinComponent('normalscreenButton').visible = true;
					} 
					else 
					{
						getSkinComponent('fullscreenButton').visible = true;
						getSkinComponent('normalscreenButton').visible = false;
					}
				}
			} 
			catch (err:Error) 
			{
				
			}
			//任意状态 控制面板 按钮 
			//布局
			
			stacker.rearrange(wid);
			
//			if(CallJSFunction.PLAYMODE=="small")
//			{
//				stacker.ImdRearrange();
//				//初始化位置修正
//				TweenLite.to(getSkinComponent("split3"),0.1,{x:wid-90-8-4});
//				TweenLite.to(getSkinComponent("streamVideoBtn"),0.1,{x:(wid-100+5)});
//				TweenLite.to(getSkinComponent("streamBtn"),0.1,{x:(wid-100+5)});
//				TweenLite.to(getSkinComponent("split4"),0.1,{x:(wid-100+5+25)});
//				
//				if (!_player.fullscreen) 
//				{
//				    TweenLite.to(getSkinComponent("playButton"),0.1,{x:(wid-260)});
//				}
//				
//				TweenLite.to(getSkinComponent("resizeBtn"),0.1,{x:(wid-100+5+35)});
//				TweenLite.to(getSkinComponent("split5"),0.1,{x:(wid-100+12+50)});
//				
//				TweenLite.to(getSkinComponent("fullscreenButton"),0.1,{x:(wid-100+5+66)});
//				TweenLite.to(getSkinComponent("normalscreenButton"),0.1,{x:(wid-100+5+66)});
//				
//				
//				TweenLite.to((getSkinComponent('slidermask') as MovieClip),0.1,{width:100});
//			}
//			else//大图模式
//			{
				//此处调整遮罩位置 不在fla里调
			//TweenLite.to((getSkinComponent('slidermask') as MovieClip),0.1,{x:((getSkinComponent('slidermask') as MovieClip).x+20)});
				
		   
			if(!CallJSFunction.NOPPT)
		   {
					
					
		   }
			//}
			
			stopFader();
			stateHandler();
			
			fixTime();
			
			//场景调整音量元件位置调整 都在fla里调
		    var vsl1imdVolumeslideIcon:MovieClip = getSkinComponent('imdVolumeslideIcon') as MovieClip;
			//var split2:MovieClip = getSkinComponent('split2') as MovieClip;
			//在fla里调整时间三个原件位置
			var vsl3elapsedText:TextField = getSkinComponent('elapsedText') as TextField;
			var vsl4timeline:TextField = getSkinComponent('timeline') as TextField;
			var vsl5totalText:TextField = getSkinComponent('totalText') as TextField;
			//杀掉所有缓动
			TweenLite.killTweensOf(vsl1imdVolumeslideIcon);
			//TweenLite.killTweensOf(split2);
			TweenLite.killTweensOf(vsl3elapsedText);
			TweenLite.killTweensOf(vsl4timeline);
			TweenLite.killTweensOf(vsl5totalText);
			
	
			
			_vsl1Original=(vsl1imdVolumeslideIcon.x);
			//_split2Original=(split2.x+7);
			_vsl3Original=(vsl3elapsedText.x);
			_vsl4Original=(vsl4timeline.x);
			_vsl5Original=(vsl5totalText.x);
			
			this.ChangeBtnState();
		}
		//原始位置
		private var _vsl1Original:Number;
		private var _split2Original:Number;
		private var _vsl3Original:Number;
		private var _vsl4Original:Number;
		private var _vsl5Original:Number;
		
		
		
		public var delayControlBar:Boolean=false;//控制面板客户延时结束
		private var _model:Model;
		//控制面板按钮位置调整(貌似与fla无关，好像已timeSlider为基准)
	
		
		//得到当前进度条播放时间
		public function GetSliderPlayertime():Number
		{
			var mpl:Number = 0;
			
			mpl = _player.playlist.currentItem.duration;
			
			//			//计算出当前播放时间
			var pct:Number = (getSkinElementChild('timeSlider', 'icon').x - getSkinElementChild('timeSlider', 'rail').x) / (getSkinElementChild('timeSlider', 'rail').width - getSkinElementChild('timeSlider', 'icon').width) * mpl;
			
			//trace("pct"+pct);
			return pct;
		}
		
		
		public function getButton(buttonName:String):DisplayObject 
		{
			return null;
		}
		
		
		/** Hide the controlbar **/
		public function block(stt:Boolean):void 
		{
			blocking = stt;
			timeHandler();
		}
		
		//控制面板按钮点击
		/** Handle clicks from all buttons. **/
		private function clickHandler(evt:MouseEvent):void 
		{
			var act:String = BUTTONS[evt.target.name];
			var data:Object = null;
			
			if (blocking != true || act == ViewEvent.JWPLAYER_VIEW_FULLSCREEN || act == ViewEvent.JWPLAYER_VIEW_MUTE) 
			{
				
				trace("act"+act);
				switch (act) 
				{
					case ViewEvent.JWPLAYER_VIEW_FULLSCREEN:
						data = Boolean(!_player.fullscreen);
						
						break;
					case ViewEvent.JWPLAYER_VIEW_PAUSE:
						data = Boolean(_player.state == PlayerState.IDLE || _player.state == PlayerState.PAUSED);
						//return;
						break;
					
					case ViewEvent.JWPLAYER_VIEW_PLAY:
						data = Boolean(_player.state == PlayerState.IDLE || _player.state == PlayerState.PAUSED);
						//return;
						break;
					case ViewEvent.JWPLAYER_VIEW_MUTE:
						data = Boolean(!_player.mute);
						break;
					
					case ViewEvent.JWPLAYER_RESIZE:
						
						if(RootReference.stage.displayState == StageDisplayState.FULL_SCREEN)
						{
							return;
						}
						
						if(CallJSFunction.PLAYMODE=="big")
						{
							data =false;
							//CallJSFunction.PLAYMODE ="small";
						}
						else
						{
							data =true;
							//CallJSFunction.PLAYMODE ="big";
						}
						
						break;
					
					case ViewEvent.JWPLAYER_STREAM_CHANGE_UI:

						if(RootReference._error)return;
						data =CallJSFunction.NOPPT;
						//点击显示码流切换面板
						//StreamChangeUiHandler();
						break;
				}
				
				var event:ViewEvent = new ViewEvent(act, data);
				dispatchEvent(event);
			}
		}
		
		
		
		private function StreamChangeUiHandler():void//点击码流按钮
		{
			//((_player as Player).view.components.display as DisplayComponent).SetStreamPanelToControlbar(this);
		}
		
		/** Handle mouse presses on sliders. **/
		private function downHandler(evt:MouseEvent):void 
		{
			if((evt.target is Loader) || (evt.target is flash.text.TextField) || (evt.target is TanImageLoader)) return;
			
			
			if (!_player.locked) 
			{
				scrubber = MovieClip(evt.target);
				
				if (blocking != true || scrubber.name == 'volumeSlider') 
				{
					var rct:Rectangle = new Rectangle(getSkinElementChild('timeSlider', 'rail').x, getSkinElementChild('timeSlider', 'icon').y, getSkinElementChild('timeSlider', 'rail').width - getSkinElementChild('timeSlider', 'icon').width, 0);
					(getSkinElementChild('timeSlider', 'icon') as MovieClip).startDrag(false, rct);
					stage.addEventListener(MouseEvent.MOUSE_UP, TimeSliderUpHandler);
				} 
				else 
				{
					scrubber = null;
				}
			}
		}
		
		
		/** Handle a change in the current item **/
		private function itemHandler(evt:PlaylistEvent=null):void 
		{
			try 
			{
				if (_player.playlist && _player.playlist.length > 1) 
				{
					getSkinComponent('prevButton').visible = getSkinComponent('nextButton').visible = true;
				} 
				else 
				{
					getSkinComponent('prevButton').visible = getSkinComponent('nextButton').visible = false;
				}
			} 
			catch (err:Error) 
			{
				
			}
			
			timeHandler();
			stacker.rearrange();
			fixTime();
		}
		//静音是否可见
		/** Show a mute icon if playing. **/
		private function muteHandler(evt:MediaEvent=null):void 
		{
			if (_player.mute == true) 
			{
				try 
				{
					getSkinComponent('muteButton').visible = true;
					getSkinComponent('unmuteButton').visible = false;
				} 
				catch (err:Error) 
				{
					
				}
				try 
				{
					getSkinElementChild('volumeSlider', 'mark').visible = false;
					getSkinElementChild('volumeSlider', 'icon').x = getSkinElementChild('volumeSlider', 'rail').x;
				} 
				catch (err:Error) 
				{
				}
			} 
			else 
			{
				try 
				{
					getSkinComponent('muteButton').visible = false;
					getSkinComponent('unmuteButton').visible = true;
				} 
				catch (err:Error) 
				{
				}
				try 
				{
					getSkinElementChild('volumeSlider', 'mark').visible = true;
					volumeHandler();
				} 
				catch (err:Error) 
				{
				}
			}
		}
		
		//private var _iconOut:Boolean= false;
		/** Handle mouseouts from all buttons **/
		private function outHandler(evt:MouseEvent):void 
		{
			TanImageLoader.getInstance().visible=false;
			
			if((evt.target is Loader) || (evt.target is flash.text.TextField) || (evt.target is TanImageLoader)) return;
			
			//音量按钮
			//if(evt.target.name=="unmuteButton" || evt.target.name=="muteButton")
			//{
				evt.target.gotoAndStop(1);
				
			//}
			
			
			//			//音量SLIDER不能加否则没法拖
			//			if(evt.target.name=="imdVolumeslideIcon")
			//			{
			//				
			//			}
		}
		
		//收缩
		private function HideVolume():void
		{
			if(_isVolumeSliderShow) return;
			
			var vsl1:MovieClip = getSkinComponent('imdVolumeslideIcon') as MovieClip;
			//var split2:MovieClip = getSkinComponent('split2') as MovieClip;
			var vsl3:TextField = getSkinComponent('elapsedText') as TextField;
			var vsl4:TextField = getSkinComponent('timeline') as TextField;
			var vsl5:TextField = getSkinComponent('totalText') as TextField;
			
			
			//杀掉所有缓动
			TweenLite.killTweensOf(vsl1);
			//TweenLite.killTweensOf(split2);
			TweenLite.killTweensOf(vsl3);
			TweenLite.killTweensOf(vsl4);
			TweenLite.killTweensOf(vsl5);
			
			
			vsl3.visible=true;
			vsl4.visible=true;
			vsl5.visible=true;
			
			TweenLite.to(vsl1,_tweenTime,{x:_vsl1Original,ease:Expo.easeIn});
			//TweenLite.to(split2,_tweenTime,{x:_split2Original,ease:Expo.easeIn});
			TweenLite.to(vsl3,_tweenTime,{x:_vsl3Original,ease:Expo.easeIn});
			TweenLite.to(vsl4,_tweenTime,{x:_vsl4Original,ease:Expo.easeIn});
			TweenLite.to(vsl5,_tweenTime,{x:_vsl5Original,ease:Expo.easeIn,onComplete:VolumeTweenEnd,onCompleteParams:[false]});
		
		}
		
		//private var _tweenEnd:Boolean= true;//tween是否结束
		public var _isVolumeSliderShow:Boolean = false;//音量SLIDER是否在显示
		
		
		private function VolumeTweenEnd(par:Boolean):void
		{
//			TweenLite.killTweensOf(getSkinComponent('imdVolumeslideIcon'));
//			TweenLite.killTweensOf(getSkinComponent('split2'));
//			TweenLite.killTweensOf(getSkinComponent('elapsedText'));
//			TweenLite.killTweensOf(getSkinComponent('timeline'));
//			TweenLite.killTweensOf(getSkinComponent('totalText'));
		}
		
		//private var _originalVolume:Boolean= true;//音量条是否原始位置
		private var _muteBoo:Boolean = false;
		
		private var _timeSliderOver:Boolean = false;
		/** Handle clicks from all buttons **/
		private function overHandler(evt:MouseEvent):void 
		{
			if((evt.target is Loader) || (evt.target is flash.text.TextField) || (evt.target is TanImageLoader)) return;
			
			if(evt.target.name=="timeSlider")
			{
				_timeSliderOver = true;
			}
			
			//var btnshade:MovieClip = getSkinComponent('btnshade') as MovieClip;
			
            if(evt.target.name=="intervalButton")
			{
				
			}
			
			if(evt.target.totalFrames>=2)
			{
				evt.target.gotoAndStop(2);
			}
			
			if (front && evt.target['icon']) 
			{
				evt.target['icon'].transform.colorTransform = light;
			} 
			else 
			{
				
			}
			
			//音量按钮
			
			if(evt.target.name=="unmuteButton" || evt.target.name=="muteButton")
			{
				
				//音量条时间缓动位移的距离
				_tweenX = 73;//tween距离设置
				
				//展开音量条
				var vsl1:MovieClip = getSkinComponent('imdVolumeslideIcon') as MovieClip;
				//var split2:MovieClip = getSkinComponent('split2') as MovieClip;
				var vsl3:TextField = getSkinComponent('elapsedText') as TextField;
				var vsl4:TextField = getSkinComponent('timeline') as TextField;
				var vsl5:TextField = getSkinComponent('totalText') as TextField;
				
				//杀掉所有缓动
				TweenLite.killTweensOf(vsl1);
				//TweenLite.killTweensOf(split2);
				TweenLite.killTweensOf(vsl3);
				TweenLite.killTweensOf(vsl4);
				TweenLite.killTweensOf(vsl5);
				
				vsl1.visible=true;
				//split2.visible=true;
				vsl3.visible=true;
				vsl4.visible=true;
				vsl5.visible=true;
				
				if(CallJSFunction.PLAYMODE=="small")
				{
					vsl3.visible=false;
					vsl4.visible=false;
					vsl5.visible=false;
				}
				
				TweenLite.to(vsl1,_tweenTime,{x:(_vsl1Original+_tweenX)});
				TweenLite.to(vsl3,_tweenTime,{x:(_vsl3Original+_tweenX)});
				TweenLite.to(vsl4,_tweenTime,{x:(_vsl4Original+_tweenX)});
				TweenLite.to(vsl5,_tweenTime,{x:(_vsl5Original+_tweenX),onComplete:VolumeTweenEnd,onCompleteParams:[true]});
			}
			
			

			//			//音量SLIDER这里不能加否则没法拖
			//			if(evt.target.name=="imdVolumeslideIcon")
			//			{
			//				
			//			}
		}
		
		private var _tweenX:Number =0;
		private var _tweenTime:Number =0.4;
		
		/** Clickhandler for all buttons. **/
		private function setButtons():void 
		{
			//fla文件中元件属性中的名字获取注意元件一定是MC
			for (var btn:String in BUTTONS) 
			{
				//trace("btn::"+btn);
				//trace("skincomponent"+getSkinComponent(btn));
				if (getSkinComponent(btn)) 
				{
					(getSkinComponent(btn) as MovieClip).mouseChildren = false;
					(getSkinComponent(btn) as MovieClip).buttonMode = true;
					//按钮点击
					(getSkinComponent(btn) as MovieClip).gotoAndStop(1); 
					getSkinComponent(btn).addEventListener(MouseEvent.CLICK, clickHandler);
					getSkinComponent(btn).addEventListener(MouseEvent.MOUSE_OVER, overHandler);
					getSkinComponent(btn).addEventListener(MouseEvent.MOUSE_OUT, outHandler);
					
				}
			}
			
			for (var sld:String in SLIDERS) 
			{
				if (getSkinComponent(sld)) 
				{
					//(getSkinComponent(sld) as MovieClip).mouseChildren = false;
					(getSkinComponent(sld) as MovieClip).buttonMode = true;
					//按钮Over out 状态
					getSkinComponent(sld).addEventListener(MouseEvent.MOUSE_DOWN, downHandler);
					getSkinComponent(sld).addEventListener(MouseEvent.MOUSE_OVER, overHandler);
					getSkinComponent(sld).addEventListener(MouseEvent.MOUSE_OUT, outHandler);
				}
			}
		}
		
		private function SplitHandler(e:MouseEvent):void
		{
			trace("SplitHandler");
			ChangeBtnState();
		}
		
		/** Init the colors. **/
		private function setColors():void 
		{
			if (_player.config.backcolor && getSkinElementChild('playButton', 'icon')) 
			{
				var clr:ColorTransform = new ColorTransform();
				clr.color = _player.config.backcolor.color;
				getSkinComponent('back').transform.colorTransform = clr;
			}
			if (_player.config.frontcolor) 
			{
				try 
				{
					front = new ColorTransform();
					
					front.color = _player.config.frontcolor.color;
					for (var btn:String in BUTTONS) 
					{
						if (getSkinComponent(btn)) 
						{
							getSkinElementChild(btn, 'icon').transform.colorTransform = front;
						}
					}
					for (var sld:String in SLIDERS) 
					{
						if (getSkinComponent(sld)) 
						{
							getSkinElementChild(sld, 'icon').transform.colorTransform = front;
							getSkinElementChild(sld, 'mark').transform.colorTransform = front;
							getSkinElementChild(sld, 'rail').transform.colorTransform = front;
						}
					}
					(getSkinComponent('elapsedText') as TextField).textColor = front.color;
					(getSkinComponent('totalText') as TextField).textColor = front.color;
				} 
				catch (err:Error)
				{
				}
			}
			
			if (_player.config.lightcolor) 
			{
				light = new ColorTransform();
				light.color = _player.config.lightcolor.color;
			} 
			else 
			{
				light = front;
			}
			if (light) 
			{
				try 
				{
					getSkinElementChild('timeSlider', 'done').transform.colorTransform = light;
					getSkinElementChild('volumeSlider', 'mark').transform.colorTransform = light;
				} 
				catch (err:Error) 
				{
				}
			}
		}
		
		
		private function startFader():void 
		{
			if (controlbarConfig['position'] == 'over' || (_player.fullscreen && controlbarConfig['position'] != 'none')) 
			{
				if (!isNaN(hiding)) 
				{
					clearTimeout(hiding);
				}
				
				//hiding = setTimeout(moveTimeout, 2000);
				//全屏时有效
				//addEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
			}
		}
		
		private function stopFader():void 
		{
			if (!isNaN(hiding)) 
			{
				clearTimeout(hiding);
				try 
				{
					_player.controls.display.removeEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
					//removeEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
				} 
				catch (e:Error) 
				{
				}
			}
			
			Mouse.show();
			
			animations.fade(1);
		}
		
		/** Show above controlbar on mousemove. **/
		public function moveHandler(evt:MouseEvent=null):void 
		{
			//trace("sdfsdf");
			if (alpha == 0) //全屏自动显示
			{
				animations.fade(1);
			}
			
			clearTimeout(hiding);
			
			hiding = setTimeout(moveTimeout, 2000);//全屏自动隐藏
			
			Mouse.show();
		}
		
		
		/** Hide above controlbar again when move has timed out. **/
		private function moveTimeout():void 
		{
			//animations.fade(0);
			this.alpha =0;
			Mouse.hide();
			clearTimeout(hiding);//为了防止全屏时最后一次的Timeout;
		}
		
		
		public var kandianArr:Array=[];
		
		private var _kandianShow:Boolean=false;
		
		public function get kandianShow():Boolean
		{
			return _kandianShow;
		}
		
		
		public function set kandianShow(val:Boolean):void
		{
			_kandianShow=val;
		}
		
		private var urlLoaderKandian:URLLoader = new URLLoader();
		
		public function ShowKandian():void
		{
			urlLoaderKandian.load(new URLRequest("https://api.guancloud.com/1.0/video/"+RootReference.currentID+"/markers"));//这里是你要获取JSON的路径
			kandianShow=true;
		}
		
		private function DecodeJSONKandianHandler(event:Event):void
		{
		    DisposeKanPoint();
			
			var urlsArr:Array=com.adobe.serialization.json.JSON.decode(URLLoader(event.target).data);
			
			var len:int=urlsArr.length;
			
			trace("wdidd::"+this.width);
			
			for(var d:int=0;d<len;d++)
			{
				var ob:Object={};
				ob.time=urlsArr[d].time;
				ob.txt=urlsArr[d].text;
				kandianArr.push(ob);
				AddKanPoint(ob);
			}
		}
		
		//播放暂停切换
		/** Process state changes **/
		private function stateHandler(evt:PlayerEvent=null):void 
		{
			// TODO: Fix non-working fading
			clearTimeout(hiding);
			try 
			{
				switch (_player.state) 
				{
					case PlayerState.PLAYING:
						
						getSkinComponent('playButton').visible = false;
						getSkinComponent('pauseButton').visible = true;
						startFader();
						
						if(kandianShow==false)
						{
							ShowKandian();
						}
						
						TimeSliderOutHandler();
						break;
					
					case PlayerState.PAUSED:
						
						getSkinComponent('playButton').visible = true;
						getSkinComponent('pauseButton').visible = false;
						stopFader();
						
						//变粗
						if((getSkinElementChild('timeSlider', 'rail') as MovieClip).currentFrame>=12) return;//已经在变粗
						
						(getSkinElementChild('timeSlider', 'icon') as MovieClip).gotoAndPlay(11);
						(getSkinElementChild('timeSlider', 'done') as MovieClip).gotoAndPlay(11);
						(getSkinElementChild('timeSlider', 'rail') as MovieClip).gotoAndPlay(11);
						
						
						break;
					
					case PlayerState.BUFFERING:
						
						getSkinComponent('playButton').visible = false;
						getSkinComponent('pauseButton').visible = true;
						stopFader();
						
						
						
						
						break;
					
					case PlayerState.IDLE:
						getSkinComponent('playButton').visible = true;
						getSkinComponent('pauseButton').visible = false;
						timeHandler();
						stopFader();
						
						//变粗
						if((getSkinElementChild('timeSlider', 'rail') as MovieClip).currentFrame>=12) return;//已经在变粗
						
						(getSkinElementChild('timeSlider', 'icon') as MovieClip).gotoAndPlay(11);
						(getSkinElementChild('timeSlider', 'done') as MovieClip).gotoAndPlay(11);
						(getSkinElementChild('timeSlider', 'rail') as MovieClip).gotoAndPlay(11);
						
						break;
					
				}
			} 
			catch (e:Error) 
			{
				
			}
		}
		
		//实时的播放位置
		/** Process time updates given by the model. **/
		
		
		
		public var pct:Number;
		public var pos:Number = 0;
		
		private var _totalTime:Number;
		
		//每时每刻更新
		private function timeHandler(evt:MediaEvent=null):void 
		{
			var dur:Number = 0;
			
			if (evt) 
			{
				if (evt.duration >= 0) 
				{
					dur = evt.duration;
				}
				if (evt.position >= 0)
				{
					pos = evt.position;
				}
			} 
			else if (_player.playlist.length > 0 && _player.playlist.currentItem) 
			{
				if (_player.playlist.currentItem.duration >= 0)
				{
					dur = _player.playlist.currentItem.duration;
				}
			}
			
			pct = pos / dur;
			
			_totalTime=dur;
			
			//trace("_totalTime:::"+_totalTime);
			
			if (isNaN(pct)) 
			{
				pct = 1;
			}
			//实时播放时间
			//trace("pos"+pos)
			//trace("posss"+Strings.digits(pos));
			
			Model._playingTime = pos;
			
			
			try 
			{
				(getSkinComponent('elapsedText') as TextField).text = Strings.digits(pos);
				(getSkinComponent('totalText') as TextField).text = Strings.digits(dur);
			} 
			catch (err:Error) 
			{
				Logger.log(err);
			}
			
			try 
			{
				var xps:Number = Math.round(pct * (this.stage.stageWidth - getSkinElementChild('timeSlider', 'icon').width));
				
				bufferHandler(evt);
				
				if (dur > 0) 
				{
					getSkinElementChild('timeSlider', 'icon').visible = _player.state != PlayerState.IDLE;
					getSkinElementChild('timeSlider', 'mark').visible = _player.state != PlayerState.IDLE;
					
					if (!scrubber || scrubber.name != 'timeSlider') 
					{
						//done的宽度只要能与icon一样就行，因为它会被遮住
						if(RootReference.stage.displayState == StageDisplayState.FULL_SCREEN)
						{
							getSkinElementChild('timeSlider', 'icon').x = xps-2.4;//2.4是为了进度条x-2.4修正
							getSkinElementChild('timeSlider', 'done').width = xps+getSkinElementChild('timeSlider', 'icon').width/2;
						}
						else
						{
							getSkinElementChild('timeSlider', 'icon').x = xps-0.8;
							getSkinElementChild('timeSlider', 'done').width = xps+getSkinElementChild('timeSlider', 'icon').width/2;
						}
					}
					
					getSkinElementChild('timeSlider', 'done').visible = _player.state != PlayerState.IDLE;
				} 
				else 
				{
					if (_player.state != PlayerState.PLAYING) 
					{
						getSkinElementChild('timeSlider', 'icon').visible = false;
						getSkinElementChild('timeSlider', 'mark').visible = false;
						getSkinElementChild('timeSlider', 'done').visible = false;
					}
				}
			} 
			catch (err:Error) 
			{
				
			}
			
			
			
			//trace("widthh;;;;;;;;;"+_player.config.width);
			trace("heihhhh;;;;;;;;;"+Model._playingTime);
			
			if((_player as TanVodPlayer).currentPlugin!=null)
			{
			   ((_player as TanVodPlayer).currentPlugin as Object).PlayTimeStateUpdate(Model._playingTime,_player.state,_player.config.width,_player.config.height);
			}
			
		}
		
		
		private function bufferHandler(evt:MediaEvent):void 
		{
			if (!evt || evt.bufferPercent < 0)
				return;
			
			var mark:DisplayObject = getSkinElementChild('timeSlider', 'mark');
			var railWidth:Number = getSkinElementChild('timeSlider', 'rail').width;
			var markWidth:Number = _player.state == PlayerState.IDLE ? 0 : Math.round(evt.bufferPercent / 100 * railWidth);
			var offset:Number = evt.offset / evt.duration;
			
			try 
			{
				mark.x = evt.duration > 0 ? Math.round(railWidth * offset) : 0;
				//trace("正在下载::"+markWidth);
				mark.width = markWidth;
				mark.visible = _player.state != PlayerState.IDLE;
			} 
			catch (e:Error) 
			{
				Logger.log(e);
			}
		}
		
		//布局 位置 进度条宽度位置修正 全屏 
		/** Fix the timeline display. **/
		private function fixTime():void 
		{
			try 
			{
				//================
				if(RootReference.stage.displayState == StageDisplayState.FULL_SCREEN)//全屏已经下载的
				{
					//全屏初始化时间游标（2.4是为了修正0点）这里不要再修正了位置都在fla里改
					
					//getSkinElementChild('timeSlider', 'icon').x = -2.4;//scp * getSkinElementChild('timeSlider', 'icon').x-1;
					//getSkinElementChild('timeSlider', 'mark').x =-2.4; //scp * getSkinElementChild('timeSlider', 'mark').x-2;
					//getSkinElementChild('timeSlider', 'done').x =-2.4;//scp * getSkinElementChild('timeSlider', 'done').x-2;
					
					//getSkinElementChild('timeSlider', 'rail').x =-2.4;//scp * getSkinElementChild('timeSlider', 'rail').x-2;
					
					//var distance:Number =getSkinComponent('normalscreenButton').x-getSkinComponent('timeSlider').x+getSkinComponent('normalscreenButton').width;
					
					
					getSkinElementChild('timeSlider', 'rail').width =this.stage.stageWidth;
					getSkinElementChild('timeSlider', 'done').width =getSkinElementChild('timeSlider', 'icon').width/2;
					
				}
				else
				{
					//初始化时间游标（0.8是为了修正0点）；
					//getSkinElementChild('timeSlider', 'icon').x =-0.8; //scp * getSkinElementChild('timeSlider', 'icon').x+0.3;
					//getSkinElementChild('timeSlider', 'mark').x =-0.8; //scp * getSkinElementChild('timeSlider', 'mark').x;
					//getSkinElementChild('timeSlider', 'done').x =-0.8;//scp * getSkinElementChild('timeSlider', 'done').x;
					
					
					//==imd=====
					//getSkinElementChild('timeSlider', 'rail').x =-0.8;//scp * getSkinElementChild('timeSlider', 'rail').x;
					
					//var distanceNormal:Number =getSkinComponent('normalscreenButton').x-getSkinComponent('timeSlider').x+getSkinComponent('normalscreenButton').width;
					
					getSkinElementChild('timeSlider', 'rail').width =this.stage.stageWidth;
					getSkinElementChild('timeSlider', 'done').width =getSkinElementChild('timeSlider', 'icon').width/2;
				}
			} 
			
			catch (err:Error) 
			{
				
			}
		}
		
		public function get currentImdTime():Number
		{
			//			var mpl:Number = 0;
			//			
			//			mpl = _player.playlist.currentItem.duration;
			//			
			//			//			//计算出当前播放时间
			//			var pct:Number = (getSkinElementChild('timeSlider', 'icon').x - getSkinElementChild('timeSlider', 'rail').x) / (getSkinElementChild('timeSlider', 'rail').width - getSkinElementChild('timeSlider', 'icon').width) * mpl;
			//			
			//			trace("pct"+pct);
			return pct;
		}
		
		
		
		/** Handle mouse releases on sliders. **/
		private function TimeSliderUpHandler(evt:MouseEvent):void 
		{
			var mpl:Number = 0;
			var sliderType:String = getSkinComponent('timeSlider').name;
			
			stage.removeEventListener(MouseEvent.MOUSE_UP, TimeSliderUpHandler);
			(getSkinElementChild('timeSlider', 'icon') as MovieClip).stopDrag();
			
			if (sliderType == 'timeSlider' && _player.playlist && _player.playlist.currentItem) 
			{
				mpl = _player.playlist.currentItem.duration;
			} 
			else if (sliderType == 'volumeSlider') 
			{
				mpl = 100;
			}
			//快进计算出当前播放时间
			getSkinElementChild('timeSlider', 'icon').x=getSkinComponent('timeSlider').mouseX;
			//trace("scrubber.icon.x"+scrubber.icon.x);
			var pct:Number = (getSkinElementChild('timeSlider', 'icon').x - getSkinElementChild('timeSlider', 'rail').x) / (getSkinElementChild('timeSlider', 'rail').width - getSkinElementChild('timeSlider', 'icon').width) * mpl;
			
			trace("mpl:::"+mpl);
			trace("pct:::"+pct);
			scrubber = null;
			
			if (sliderType == 'volumeSlider') 
			{
				var volumeEvent:MediaEvent = new MediaEvent(MediaEvent.JWPLAYER_MEDIA_VOLUME);
				volumeEvent.volume = Math.round(pct);
				volumeHandler(volumeEvent);
			}
			
			dispatchEvent(new ViewEvent(SLIDERS[sliderType], Math.round(pct)));
		}
		
		/** Reflect the new volume in the controlbar **/
		private function volumeHandler(evt:MediaEvent=null):void 
		{
			try 
			{
				var vsl:MovieClip = getSkinComponent('volumeSlider') as MovieClip;
				vsl.mark.width = _player.config.volume * (vsl.rail.width - vsl.icon.width / 2) / 100;
				vsl.icon.x = vsl.mark.x + _player.config.volume * (vsl.rail.width - vsl.icon.width) / 100;
			} 
			catch (err:Error) 
			{
				
			}
		}
		
		
		public function getSkinComponent(element:String):DisplayObject 
		{
			return skin.getChildByName(element) as DisplayObject;
		}
		
		
		public function getSkinElementChild(element:String, child:String):DisplayObject 
		{
			return (skin.getChildByName(element) as MovieClip).getChildByName(child);
		}
	}
}