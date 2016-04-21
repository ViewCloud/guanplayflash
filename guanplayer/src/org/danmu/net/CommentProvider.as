package org.danmu.net
{
    import flash.events.*;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    

    
    import org.danmu.event.CommentDataEvent;
    import org.danmu.event.EventBus;
    import org.danmu.event.MukioEvent;
    import org.danmu.utils.CommentDataParser;
    import org.danmu.utils.CommentFormat;
    
    /**
    * 弹幕的加载类,用于从外部加载弹幕文件到播放器
    * @author aristotle9
    **/
    public class CommentProvider extends EventDispatcher
    {
        /** 用于网络连接的loader **/
        private var xmlLoader:URLLoader;
        /** 弹幕库 **/
        private var _repo:Array;
        
        public function CommentProvider()
        {
            _repo = new Array();
            this.xmlLoader = new URLLoader();
            xmlLoader.addEventListener(Event.COMPLETE,completeHandler);
            xmlLoader.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
            xmlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
            
            EventBus.getInstance().addEventListener(MukioEvent.DISPLAY,displayeHandler);
            EventBus.getInstance().addEventListener("displayRtmp",displayeHandler);
        }
        /** 接收内部发送的显示消息 **/
        private function displayeHandler(event:MukioEvent):void
        {
            dispatchCommentData(event.data.msg,event.data);
        }
        /** 加载成功 **/
        private function completeHandler(event:Event):void
        {
            try
            {
                var xml:XML = XML(xmlLoader.data);
                parseXML(xml);
            } catch(error:Error){
                msg("弹幕文件格式有误,无法正确解析.");
            }
        }
        /** 错误处理 **/
        private function errorHandler(event:Event):void
        {
            msg(event.toString());
        }
        /** 错误输出 **/
        private function msg(massage:String):void
        {
            EventBus.getInstance().log(massage);
        }
        /** 加载指定地址和格式的弹幕
        * @param url 弹幕文件地址,通常是一个xml文件
        * @param type 弹幕文件格式
        **/
        public function load(url:String,type:String = "",server:CommentServer=null):void
        {
            /** 加载前清理弹幕 **/
            this.dispatchEvent(new CommentDataEvent(CommentDataEvent.CLEAR));
            this._repo.removeAll();
            if(type == "")
            {
                type = CommentFormat.OLDACFUN;
            }
            if(type == CommentFormat.AMFCMT)
            {
                server.getCmts(dispatchCommentData);
            }
            else
            {
                var request:URLRequest = new URLRequest(url);
                xmlLoader.load(request);
            }
        }
        /**
        * 解析xml
        * 把xml解析成一条条弹幕数据,并分发出去
        * 弹幕数据说明 ...
        **/
        private function parseXML(xml:XML):void
        {
            if(xml.data.length())
            {
                CommentDataParser.acfun_parse(xml,dispatchCommentData);
            }
            else if(xml.l.length())
            {
                CommentDataParser.acfun_new_parse(xml,dispatchCommentData);
            }
            else if(xml.d.length())
            {
                CommentDataParser.bili_parse(xml,dispatchCommentData);
            }
            else
            {
                msg("格式未识别.");
            }
        }
        /**
        * 分发函数,处理单个弹幕数据
        **/
        private function dispatchCommentData(msg:String,data:Object):void
        {
            this.dispatchEvent(new CommentDataEvent("1",data));
            //带有preview属性的不插入弹幕库
            if(data.preview)
            {
                return;
            }
           // this._repo.addItem(data);
        }
        public function get commentResource():Array
        {
            return _repo;
        }
    }
}