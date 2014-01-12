package  {

	import flash.display.MovieClip;

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

		public function infector() {}

		public function onLoaded() : void {
			trace('--\n\nFrota Test Hud\n\n--');

			// Hook stuff
            Globals.instance.resizeManager.AddListener(this);
            this.gameAPI.OnReady();
            Globals.instance.GameInterface.AddMouseInputConsumer();


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
