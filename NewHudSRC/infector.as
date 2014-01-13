package  {
	// Flash stuff
	import flash.display.MovieClip;

	// Loader stuff
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.events.ProgressEvent;
   	import flash.events.Event;
   	import flash.events.IOErrorEvent;

   	// Valve stuff
	import ValveLib.Globals;
    import ValveLib.ResizeManager;


	public class infector extends MovieClip {
		// Game API related stuff
        public var gameAPI:Object;
        public var globals:Object;
        public var elementName:String;

        // These vars determain how much of the stage we can use
        // They are updated as the stage size changes
        public var maxStageWidth:Number = 1366;
        public var maxStageHeight:Number = 768;

        // The loader
        public var loader;

		public function infector() {}

		public function onLoaded() : void {
			trace('\n\n-- Frota Hud Injector Loading --\n\n');

			// Hook stuff
            Globals.instance.resizeManager.AddListener(this);
            this.gameAPI.OnReady();

            // Find the top level parent
            var topRarent = this;
            while(topRarent.parent != null) {
            	topRarent = topRarent.parent;
            	trace("Up one level!")
            }

            // Load the hud
            this.loader = new Loader();
            this.loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,this.OnLoadProgress);
            this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE,this.onLoadingComplete);
            this.loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,this.onIOError);
            globals.Loader_overlay.movieClip.addChild(this.loader);
            this.loader.visible = false;
            this.loader.load(new URLRequest("frotaHud.swf"));

            // Null out our loader
            globals.Loader_injector = null;
		}

		public function onLoadingComplete(param1:Event) : * {
			trace("onLoadingComplete");
			this.loader.visible = true;

			var movieClip = this.loader.content as MovieClip;
			movieClip["gameAPI"] = this.gameAPI;
			movieClip["elementName"] = "frotaHud";
			movieClip.onLoaded();
	    }

		public function OnLoadProgress(param1:ProgressEvent) {
			trace("OnLoadProgress " + param1.bytesLoaded + " / " + param1.bytesTotal);
		}

		public function onIOError(param1:IOErrorEvent) : * {
         trace("onIOError :(");
      }

		public function onResize(re:ResizeManager) : * {
            // Align to top of screen
            x = 0;
            y = 0;

            // Update the stage width
            maxStageWidth = re.ScreenWidth / re.ScreenHeight * 768;

            // Scale hud up
            this.scaleX = re.ScreenWidth/maxStageWidth;
            this.scaleY = re.ScreenHeight/maxStageHeight;
        }
	}

}
