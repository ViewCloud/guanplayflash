package com.tanplayer.components 
{
	import com.tanplayer.events.MediaEvent;
	import com.tanplayer.events.PlayerEvent;
	import com.tanplayer.events.PlayerStateEvent;
	import com.tanplayer.events.ViewEvent;
	import com.tanplayer.interfaces.IDisplayComponent;
	import com.tanplayer.media.HTTPFenDuanMediaProvider;
	import com.tanplayer.model.Model;
	import com.tanplayer.player.CallJSFunction;
	import com.tanplayer.player.IPlayer;
	import com.tanplayer.player.JavascriptAPI;
	import com.tanplayer.player.Player;
	import com.tanplayer.player.PlayerState;
	import com.tanplayer.skins.PNGSkin;
	import com.tanplayer.utils.Draw;
	import com.tanplayer.utils.RootReference;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.system.Capabilities;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.Timer;
	import flash.utils.clearInterval;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	
	public class DisplayComponent extends CoreComponent implements IDisplayComponent 
	{
		protected var _icon:DisplayObject;
	
		protected var _background:MovieClip;
		protected var _text:TextField;
		protected var _icons:Object;
		protected var _rotateInterval:Number;
		protected var _bufferIcon:Sprite;
		protected var _rotate:Boolean = true;
		
		
		
		public function DisplayComponent(player:IPlayer) 
		{
			super(player, "display");
			addListeners();
			setupDisplayObjects();
			setupIcons();
		}
		
		
		
		
		
		public function SetStreamChangeNotice():void
		{
			try 
			{
				removeChild(icon);
			}
			catch (err:Error) 
			{
			}
			if (_icons['streamBtns'] && _player.config.icons) 
			{
				_icon = _icons['streamBtns'];
				
				
				var led:int=(icon as MovieClip).numChildren;
				
				for(var i:int=led-1; i>=0; i--)
				{ 
					if(i!=0)
					{
						(icon as MovieClip).removeChild((icon as MovieClip).getChildAt(i));
					}
				} 
				
				icon.y=0;
				addChild(_icon);
				var mediaArr:Array=(_player as Player).controller.mediaArr;
				var len:int=mediaArr.length;
				
				var tf:TextFormat=new TextFormat();
				
				tf.font="Microsoft yahei";
				var wid:Number=(icon as MovieClip).width;
				
				for(var dx:int=0;dx<len;dx++)
				{
					var txt:TextField=new TextField();
					
					txt.selectable=false;
					
					if(RootReference.currentStream==mediaArr[dx].quality)
					{
						tf.color=0x00ff00;
					}
					else
					{
						tf.color=0xffffff;
					}
					
					txt.htmlText="<a href='event:#'>"+(_player as Player).controller.mediaArr[dx].quality+"</a>";
					(icon as MovieClip).addChild(txt);
					txt.y=10+dx*30;
					txt.setTextFormat(tf);
					
					txt.x=(wid-txt.textWidth)/2-2;
				}
				
				(icon as MovieClip).getChildAt(0).height=(icon as MovieClip).height-65;
				
				(icon as MovieClip).addEventListener(MouseEvent.CLICK,StreamBtnsClickHandler);
				icon.x=RootReference.stage.stageWidth-90;//right
				
				if(RootReference.stage.displayState == StageDisplayState.FULL_SCREEN)
				{
					icon.y =(this.height-54)-(icon as MovieClip).getChildAt(0).height;//54是底部控制面板的高
				}
				else
				{
					icon.y =this.height-(icon as MovieClip).getChildAt(0).height;//-icon.height+300;//-(icon as MovieClip).getChildAt(0).height;//bottom
				}
				
			}
		}
		//码流切换
		private function StreamBtnsClickHandler(e:MouseEvent):void
		{
			//this.name = "swicthBtn";
			if(e.target is TextField)
			{
				clearDisplay();
					
				_changeStreamBuffer = true;
				e.stopPropagation();
				//发送切换码流事件
				dispatchEvent(new ViewEvent(ViewEvent.IMD_CHANGE_STREAM,(e.target as TextField).text));
			}
		}
		
		private function addListeners():void 
		{
			player.addEventListener(MediaEvent.JWPLAYER_MEDIA_MUTE, stateHandler);
			player.addEventListener(PlayerStateEvent.JWPLAYER_PLAYER_STATE, stateHandler);
			player.addEventListener(PlayerEvent.JWPLAYER_ERROR, errorHandler);
			
			player.addEventListener(MediaEvent.JWPLAYER_Seek_Ukd,SeekHandler);
			
			player.addEventListener(MediaEvent.JWPLAYER_DataWidthHeight,DataWidthHeightHandler);
			
		
			addEventListener(MouseEvent.CLICK, clickHandler);//播放视频屏幕点击
			_clickDelayTime.addEventListener(TimerEvent.TIMER_COMPLETE,DelayClickHandler);
			this.buttonMode = true;
			
			//this.mouseChildren = false;
		}
		
		private function DataWidthHeightHandler(e:MediaEvent):void
		{
			//trace(Capabilities.screenResolutionX);
			if(e.metadata.width>Capabilities.screenResolutionX || e.metadata.height>Capabilities.screenResolutionY)
			{
				
			}
			else
			{
				(_player as Player).view.yuanshiVideoWidth =e.metadata.width;
				(_player as Player).view.yuanshiVideoHeight =e.metadata.height;
			}
			
			//获得完正确的原始尺寸开始缩放这个时候display scalex归1 
			//flash.utils.setTimeout(Dexdg,3000);
			if(_state=="yuanshi")
			{
				ScaleClickYuanShiHandler();
			}
			
		}
		

		
		private function SeekHandler(event:PlayerEvent = null):void
		{
			SeekFunction();
		}
		
		private var _clickDelayTime:Timer = new Timer(250,1);
		
		
		protected function clickHandler(event:MouseEvent):void 
		{
			if(event.target is SimpleButton)//码流切换按钮点击事件
			{
				this.name ="swicthBtn";
			}
			else
			{
				this.name = "screen";
			}
			
			if(_clickDelayTime.running)
			{
				_clickDelayTime.stop();//双击
				trace("双击");
				dispatchEvent(new ViewEvent(ViewEvent.DOUBLE_CLICK,Boolean(!_player.fullscreen)));
			}
			else//单击
			{
				
				_clickDelayTime.start();
				_clickName =event.target.name;
			}
		}
		
		private var _clickName:String;//单击名称
		//音频
		private function DelayClickHandler(e:TimerEvent):void
		{
			trace("单击");
			
			if(this.name =="swicthBtn") return;
			_clickDelayTime.stop();
			
			
			
			
			//屏幕单击
			if(_player.config.isvr) return //vr全景模式不允许屏幕单击
			
			dispatchEvent(new ViewEvent(ViewEvent.JWPLAYER_VIEW_CLICK));
			
			if (player.state == PlayerState.PLAYING || player.state == PlayerState.BUFFERING) 
			{
				dispatchEvent(new ViewEvent(ViewEvent.JWPLAYER_VIEW_PAUSE));
				//player.pause();
			} 
			else 
			{
				dispatchEvent(new ViewEvent(ViewEvent.JWPLAYER_VIEW_PLAY));
				//player.play();
			}
		}
		
		
		private function setupDisplayObjects():void 
		{
			_background = new MovieClip();
			background.name = "background";
			addChildAt(background, 0);
			
			background.graphics.beginFill(0, 0);
			background.graphics.drawRect(0, 0, 1, 1);
			background.graphics.endFill();
			if (player.config.screencolor) {
				var colorTransform:ColorTransform = new ColorTransform();
				colorTransform.color = player.config.screencolor.color;
				background.transform.colorTransform = colorTransform;
			}
			_icon = new MovieClip();
			addChildAt(icon, 1);

			_text = new TextField();
			var textColorTransform:ColorTransform = new ColorTransform();
			textColorTransform.color = player.config.frontcolor ? player.config.frontcolor.color : 0x999999;
			text.transform.colorTransform = textColorTransform;
			text.gridFitType = GridFitType.NONE;
			addChildAt(text, 2);
		}
		
		//安装大播放 缓冲 播放 静音 错误提示
		protected function setupIcons():void 
		{
			_icons = {};
			
			setupIcon('buffer');
			setupIcon('play');//大播放按钮
			setupIcon('mute');
			setupIcon('error');
			setupIcon('replay');//重播按钮
			
			
			setupIcon('manpin');//全屏缩放1
			setupIcon('yuanshi');//全屏缩放1
			setupIcon('fangda');//全屏缩放1
			setupIcon('suoxiao');//全屏缩放1
			setupIcon('topbgx');//topBg
			
			setupIcon('streamBtns');//码流切换面板
		
			
			//安装全屏放大缩小按钮
			
			this.addChild(_icons['topbgx']);
//			
			_icons['topbgx'].x=0;
			_icons['topbgx'].y=0;
			_icons['manpin'].y=_icons['topbgx'].y;
			_icons['yuanshi'].y=_icons['topbgx'].y;
			_icons['suoxiao'].y=_icons['topbgx'].y;
			_icons['fangda'].y=_icons['topbgx'].y;
			
			
			addChild(_icons['manpin']);
			//addChild(_icons['yuanshi']);//原始暂时
			addChild(_icons['fangda']);
			addChild(_icons['suoxiao']);
			
			
			_icons['topbgx'].visible =false;
//			//全屏
			_icons['manpin'].addEventListener(MouseEvent.CLICK,ScaleClickManPinHandler);
			//_icons['yuanshi'].addEventListener(MouseEvent.CLICK,ScaleClickYuanShiHandler);
			_icons['fangda'].addEventListener(MouseEvent.CLICK,ScaleClick33Handler);//满屏
			_icons['suoxiao'].addEventListener(MouseEvent.CLICK,ScaleClickSuoxiaoHandler);
			
			_icons['manpin'].addEventListener(MouseEvent.MOUSE_OVER,OverScaleHandler);
			_icons['manpin'].addEventListener(MouseEvent.MOUSE_OUT,OutScaleHandler);
			
			_icons['yuanshi'].addEventListener(MouseEvent.MOUSE_OVER,OverScaleHandler);
			_icons['yuanshi'].addEventListener(MouseEvent.MOUSE_OUT,OutScaleHandler);
			
			_icons['fangda'].addEventListener(MouseEvent.MOUSE_OVER,OverScaleHandler);
			_icons['fangda'].addEventListener(MouseEvent.MOUSE_OUT,OutScaleHandler);
			
			
			_icons['suoxiao'].addEventListener(MouseEvent.MOUSE_OVER,OverScaleHandler);
			_icons['suoxiao'].addEventListener(MouseEvent.MOUSE_OUT,OutScaleHandler);
			
			
			HideScaleBtn();
		}
		
		public function get streamBtnsIcon():Object
		{
			return _icons['streamBtns'];
		}
		
		private function OverScaleHandler(e:MouseEvent):void
		{
		    e.target.gotoAndStop(2);
		}
		
		private function OutScaleHandler(e:MouseEvent):void
		{
			e.target.gotoAndStop(1);
		}
		
		public function ShowScaleBtn():void
		{
			_icons['topbgx'].width=RootReference.stage.stageWidth;
			
			_icons['manpin'].x=(RootReference.stage.stageWidth-(2*50+73*2+30))/2;
			//_icons['yuanshi'].x=_icons['manpin'].x+_icons['manpin'].width+10;
			_icons['fangda'].x=_icons['manpin'].x+_icons['manpin'].width+10;
			_icons['suoxiao'].x=_icons['fangda'].x+_icons['fangda'].width+10;
			
			
			_icons['topbgx'].visible =true;
			_icons['manpin'].visible =true;
			_icons['yuanshi'].visible =true;
			_icons['suoxiao'].visible =true;
			_icons['fangda'].visible =true;
		}
		
		public function HideScaleBtn():void
		{
			_icons['topbgx'].visible =false;
			_icons['manpin'].visible =false;
			_icons['yuanshi'].visible =false;
			_icons['suoxiao'].visible =false;
			_icons['fangda'].visible =false;
		}
		
		private var _state:String="yuanshi";
		
		private function ScaleClickManPinHandler(e:MouseEvent):void
		{
			(_player as Player).model.media.resize(_player.config.width, _player.config.height);
			
			_state = "manping";
			
			var display:* =(_player as Player).model.media.display;
			
			display.x= (this.width-display.width)/2;
			display.y= (this.height-display.height)/2;
			
			e.stopPropagation();
			
			disx = display.x;
			disy = display.y;
			
			disWidth =display.width;
			disHeight =display.height;
		}
		
		
		public function ScaleSWF(SwfMC:*,parent:*):void
		{
			//trace(parent.width);
			//trace(SwfMC.width);
			var widthper:Number=parent.width/SwfMC.width;//外层容器宽/原始图像与的比
			var heightper:Number = parent.height/SwfMC.height;//外层容器高原始图像与的比
			
			if(widthper>heightper)//如果宽的比大于高的比
			{
				SwfMC.width =SwfMC.width*heightper;
				SwfMC.height =SwfMC.height*heightper;
			}
			else
			{
				SwfMC.width =SwfMC.width*widthper;
				SwfMC.height =SwfMC.height*widthper;
			}
		}
		
		private var disx:Number;
		private var disy:Number;
		private var disWidth:Number;
		private var disHeight:Number;
		
		public function SeekFunction():void
		{
			var display:* =(_player as Player).model.media.display;
			//trace(disx);
			display.x=disx;
			display.y=disy;
			
			display.width=disWidth;
			display.height=disHeight;
		}
		
		public function ScaleClickYuanShiHandler(e:MouseEvent=null):void
		{
			var display:* =(_player as Player).model.media.display;
			//trace((_player as Player).view.yuanshiVideoWidth);
			if(display==null)
			{
				return;
			}
			
			_state = "yuanshi";
			
			display.width=(_player as Player).view.yuanshiVideoWidth;
			display.height=(_player as Player).view.yuanshiVideoHeight;
			//trace(display.width);
			//trace(display.height);
			display.x= (this.width-display.width)/2;
			display.y= (this.height-display.height)/2;
			
			if(e!=null)
			{
				e.stopPropagation();
			}
			
			disx = display.x;
			disy = display.y;
			
			disWidth =display.width;
			disHeight =display.height;
		}
		
		private function ScaleClick33Handler(e:MouseEvent):void
		{
			var display:* =(_player as Player).model.media.display;
			ZoomMc(display,this,1.1);
			e.stopPropagation();
			
			_state = "fangda";
			
			disx = display.x;
			disy = display.y;
			
			disWidth =display.width;
			disHeight =display.height;
		}
		
		public function SaveD(display:*):void
		{
			disx = display.x;
			disy = display.y;
			
			disWidth =display.width;
			disHeight =display.height;
		}
		
		
		//缩放
		public function ZoomMc(currentSwfMC:*,parent:*,factor:Number):void
		{
			//缩小先居中
			currentSwfMC.x =(parent.width-currentSwfMC.width)/2;
			currentSwfMC.y = (parent.height-currentSwfMC.height)/2;
			
			var per:Number =currentSwfMC.width/currentSwfMC.height;
			var qianWidth:Number = currentSwfMC.width;
			var qianHeight:Number = currentSwfMC.height;
			var Twidth:Number=currentSwfMC.width*factor;
			var THeight:Number = Twidth/per;
			
			currentSwfMC.width = Twidth;
			currentSwfMC.height = THeight;
			
			currentSwfMC.x-=(Twidth-qianWidth)/2;
			currentSwfMC.y-=(THeight-qianHeight)/2;
		}
		
		private function ScaleClickSuoxiaoHandler(e:MouseEvent):void
		{
			var display:* =(_player as Player).model.media.display;
			ZoomMc(display,this,0.9);
			e.stopPropagation();
			
			_state = "suoxiao";
			disx = display.x;
			disy = display.y;
			
			disWidth =display.width;
			disHeight =display.height;
		}
		
		//private var _streamIcon:MovieClip;
		
//		public function get streamBtnsIcon():Object
//		{
//			return _icons['streamBtns'];
//		}
		
		
		
		
		/**
		 * Takes in an icon from a PNG skin and rearranges its children so that it's centered around 0, 0 
		 */
		protected function centerIcon(icon:Sprite):void 
		{
			if (icon && icon.getChildAt(0) is Bitmap) 
			{
				icon.getChildAt(0).x = -Math.round(icon.getChildAt(0).width)/2;
				icon.getChildAt(0).y = -Math.round(icon.getChildAt(0).height)/2;
			}
		}
		
		protected function setupIcon(name:String):void 
		{
			var icon:Sprite = getSkinElement(name + 'Icon') as Sprite;
			
			if(_player.skin is PNGSkin) centerIcon(icon);
			
			if(name=="buffer") 
			{
				icon.alpha=1;//隐藏缓冲图标
				
				if(icon is MovieClip && (icon as MovieClip).totalFrames > 1) 
				{
					// Buffer is already animated; no need to rotate.
					_rotate = false;
				} 
				else 
				{
					try 
					{
						_bufferIcon = icon;
						var bufferBitmap:Bitmap = _bufferIcon.getChildByName('bitmap') as Bitmap;
						if(bufferBitmap)
						{
							Draw.smooth(bufferBitmap);
						}
					} 
					catch (e:Error) 
					{
						_rotate = false;
					}
				}
				
				
			}
			
			if(name =='streamBtns')
			{
				icon.tabIndex=0;
			}
			
			var back:Sprite = getSkinElement('background') as Sprite;

			if (back) 
			{
				if (_player.skin is PNGSkin) centerIcon(back);
				back.addChild(icon);
				back.x = back.y = icon.x = icon.y = 0;
 				_icons[name] = back;
			} 
			else 
			{
				_icons[name] = icon;
			}
			
			if(name=="play" || name=="replay")//out状态
			{
				(icon as MovieClip).gotoAndStop(1);
				icon.addEventListener(MouseEvent.MOUSE_OVER,BigPlayeIconOver);
				icon.addEventListener(MouseEvent.MOUSE_OUT,BigPlayeIconOut);
			}

		}
		
		private function BigPlayeIconOut(e:MouseEvent):void
		{
			e.target.gotoAndStop(1);
		}
		
		private function BigPlayeIconOver(e:MouseEvent):void
		{
			e.target.gotoAndStop(2);
		}
		
		
		public function resize(width:Number, height:Number):void 
		{
			background.width = width;
			background.height = height;
			positionIcon();
			positionText();
			stateHandler();
		}
		
		
		public function setIcon(displayIcon:DisplayObject):void 
		{
			try 
			{
				removeChild(icon);
				
				if(icon as MovieClip==null)
				{
					
				}
				else
				{
					if((icon as MovieClip).hasEventListener(MouseEvent.CLICK))
					{
						(icon as MovieClip).removeEventListener(MouseEvent.CLICK,StreamBtnsClickHandler);
					}
				}
			}
			catch (err:Error) 
			{
				//trace(""); 
			}
			
			if (displayIcon && _player.config.icons) 
			{
				_icon = displayIcon;
				addChild(icon);
				positionIcon();
			}
		}
		//各种显示图标位置调整（不包括码流panel)
		private function positionIcon():void 
		{
			icon.x = background.scaleX / 2;
			icon.y = background.scaleY / 2;
			
			//RootReference.ResizeAlertPosition();
		}
		
		
		public function setText(displayText:String,displayIcon:DisplayObject=null):void 
		{
//			if (_icon is Sprite && (_icon as Sprite).getChildByName('txt') is TLFTextField) 
//			{
//				((_icon as Sprite).getChildByName('txt') as TLFTextField).text = displayText ? displayText : '';
//				text.text = '';
//			} 
//			else 
//			{
//				text.text = displayText ? displayText : '';
//			}
//			
//			
//			
//			positionText();
		}
		
		
		private function positionText():void 
		{
			if (text.text) 
			{
				text.visible = true;
				if (text.width>background.scaleX * .75) 
				{
					text.width = background.scaleX * .75;
					text.wordWrap = true;
				} 
				else 
				{
					text.autoSize = TextFormatAlign.CENTER;
				}
				text.x = (background.scaleX - text.textWidth) / 2;
				if (contains(icon)) 
				{
					text.y = icon.y + (icon.height/2) + 10;
				} 
				else 
				{
					text.y = (background.scaleY - text.textHeight) / 2;
				}
			} 
			else 
			{
				text.visible = false;
			}
		}
		
		
		public function setDisplay(displayIcon:DisplayObject, displayText:String = null):void 
		{
			setIcon(displayIcon);
			setText(displayText != null ? displayText : text.text,displayIcon);
		}
		
		public function clearDisplay():void //清除消失清空图标大播放大图标中间图标
		{
			setDisplay(null, '');//清空图标
			
			RootReference.ClearShowInfo();
			
			if((_player as Player).controller._streamBtnsVisible)
			{
				(_player as Player).controller._streamBtnsVisible = false;
			}
		}
		
		
		private var _bufferNum:int=0;//缓冲次数
		private var _lastBufferStartTime:Number=0;//上次缓冲开始时间
		private var _bufferInterval:Number;//缓冲间隔时间
		
/*		private var _bufferEnd:Boolean = false;//是否缓冲完毕
		//缓冲超时执行函数
		private function BufferDelayHandler(e:TimerEvent):void
		{
			_bufferTimer.stop();
			_bufferTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,BufferDelayHandler);
			
			if(!_bufferEnd)//连接超时，未缓冲完毕，强制STOP
			{
				player.stop();
				setDisplay(_icons['error'],"连接超时，请切换服务器");
			}
	    }*/
		
		
		//private var _bufferTimer:Timer = new Timer(5000,1);//缓冲超时计时器
		//监视播放状态 缓冲
		protected function stateHandler(event:PlayerEvent = null):void 
		{
			clearRotation();
			//trace(player.state);
			switch (player.state) 
			{
				case PlayerState.BUFFERING:
					
					if(_changeStreamBuffer)
					{
						var txt:String;
						//txt= "正在切换"+"【"+_changeStreamName+"】"+"模式";
						setDisplay(_icons['error'],txt);
					}
					else
				    {
						setDisplay(_icons['buffer'], '');//显示缓冲图标
					}
/*					//检测连接超时计时器
					
					_bufferTimer.addEventListener(TimerEvent.TIMER_COMPLETE,BufferDelayHandler);
					_bufferTimer.start();*/
					
					
					
					//暂时不做自动码流切换					
/*					if(_lastBufferStartTime==0)
					{
						_lastBufferStartTime =getTimer();
					}
					else
					{
						_bufferInterval =getTimer() - _lastBufferStartTime;
						trace("_bufferInterval--"+_bufferInterval);
					
						if(_bufferInterval>500)
						{
							if((_player as Player).model.media is HTTPMediaProvider)
							{
								
							}
							else if((_player as Player).controller._bufferBeforeURL!=(_player as Player).playlist.currentItem.file)
							{
								(_player as Player).controller._bufferBeforeURL = (_player as Player).playlist.currentItem.file;
							}
							else if((_player as Player).controller._bufferBeforeURL==(_player as Player).playlist.currentItem.file)
							{
								
								_bufferNum++;
								trace("_bufferNum"+_bufferNum);
								if(_bufferNum==3)
								{
									_bufferNum=0;
									RootReference.AlertShow();
									RootReference.imdAlert._alertText.text = "网络卡，切换码流";
									
									trace("网络卡，切换码流");
									(_player as Player).controller.stop();
									
									AssetURL.urlNum--;
									
									if(AssetURL.urlNum<0)
									{
										AssetURL.urlNum=0;
									}
									
									JavascriptAPI.ChangeKbpsHandler(AssetURL.urlArr[AssetURL.urlNum],Model._playingTime);
								}
							}
						}
						_lastBufferStartTime = getTimer();
					}*/
					
					
					if (_rotate)
					{
						startRotation();
					}
					break;
				case PlayerState.PAUSED://暂停不显示播放加了广告
					//显示大播放按钮
					setDisplay(_icons['play']);
					
					break;
				case PlayerState.PLAYING:
					
					clearDisplay();
					
					break;
				
				
				case PlayerState.IDLE:
					
					//播放完毕结束显示大播放重播图标
					if(Model._playingTime>=2)
					{
					    if(RootReference._lianboType)
						{
							
						}
						else
						{
							setDisplay(_icons['replay']);
						}
						
					}
					else//开始的时候调用
				    {
						if((_player as Player).model.config.autostart)//自动播放
						{
							setDisplay(_icons['buffer']);
							RootReference.ShowCover();
						}
						else
						{
							setDisplay(_icons['play']);
						}
						
				    }
					
					//trace("Model._playingTime:::"+Model._playingTime);
					break;
				
				default:
					
					if (player.mute) 
					{
						setDisplay(_icons['mute']);
					} 
					else 
					{
						if(!_changeStreamBuffer)
						{
							clearDisplay();
							
							//_bufferEnd = true;
						}
					}
			}
		}
		
		
		
		protected function startRotation():void 
		{
			if (!_rotateInterval) 
			{
				_rotateInterval = setInterval(updateRotation, 100);
			}
		}
		
		
		protected function updateRotation():void 
		{
			if (_bufferIcon) _bufferIcon.rotation += 15;
		}
		
		
		protected function clearRotation():void 
		{
			if (_bufferIcon) _bufferIcon.rotation = 0;
			if (_rotateInterval) 
			{
				clearInterval(_rotateInterval);
				_rotateInterval = undefined;
			}
		}
		
		
		protected function errorHandler(event:PlayerEvent):void 
		{
			setDisplay(_icons['error'], event.message);
		}
		public var _streamBtnsVisible:Boolean = false;//标示码流切换用户操作面板是否显示
		
		
		
		
	    private function AudioBtnHandler(e:MouseEvent):void
		{
			e.target.overState=e.target.downState;
			
		}
		
		public var _changeStreamBuffer:Boolean = false;//是否切换码流缓冲完毕
		
		
		
		
		public function get icon():DisplayObject 
		{
			return _icon;
		}
		
		public function HideBufferIcon():void//隐藏缓冲图标
		{
			_icons['buffer'].visible=false;
		}
		
	    protected function get text():TextField 
		{
			return _text;
		}
		
		
		protected function get background():MovieClip 
		{
			return _background;
		}
		
	}
}