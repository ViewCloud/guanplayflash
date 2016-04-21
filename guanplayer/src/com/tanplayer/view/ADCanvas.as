package com.tanplayer.view
{
	public class ADCanvas extends Sprite
	{
		public function ADCanvas()
		{
		
		}
		
		private var load:Loader = new Loader();
		
		protected function application1_creationCompleteHandler(event:FlexEvent):void
		{
			//加广告
			load.load(new URLRequest(""));
			load.contentLoaderInfo.addEventListener(Event.COMPLETE,Compelte);
		}
		
		private function Compelte(e:Event):void
		{
			addChild(load);
		}
	}
}