package  {
    // Flash Libraries
	import flash.display.MovieClip;

    // Valve Libaries
    import ValveLib.Globals;
    import ValveLib.ResizeManager;


	public class frotaHud extends MovieClip {
		// Game API related stuff
        public var gameAPI:Object;
        public var globals:Object;
        public var elementName:String;

        // These vars determain how much of the stage we can use
        // They are updated as the stage size changes
        public var maxStageWidth:Number = 1366;
        public var maxStageHeight:Number = 768;

        // Stores the overlay panel
        public static var overlay:MovieClip;

        // Shortcut functions
        public static var Translate:Function;

        // When the hud is loaded
        public function onLoaded() : void {
            // Store shortcut functions
            Translate = Globals.instance.GameInterface.Translate;

            // Get a reference to the overlay panel
            overlay = globals.Loader_frotaOverlay.movieClip;

            // Hook game events

            // Hook Game API Related Stuff
            Globals.instance.resizeManager.AddListener(this);

            // Make the hud visible
            visible = true;
            overlay.visible = true;
        }

        public function onResize(re:ResizeManager) : * {
            // Align to top of screen
            x = 0;
            y = 0;
            overlay.x = 0;
            overlay.y = 0;

            // Update the stage width
            maxStageWidth = re.ScreenWidth / re.ScreenHeight * 768;

            // Scale hud up
            this.scaleX = re.ScreenWidth/maxStageWidth;
            this.scaleY = re.ScreenHeight/maxStageHeight;
            overlay.scaleX = re.ScreenWidth/maxStageWidth;
            overlay.scaleY = re.ScreenHeight/maxStageHeight;
        }
	}

}
