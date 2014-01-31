package  {
    // Flash Libraries
	import flash.display.MovieClip;

    // Valve Libaries
    import ValveLib.Globals;
    import ValveLib.ResizeManager;

    // Events
    import flash.events.MouseEvent;

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

        // Movieclips on the stage
        public var hudMask:MovieClip;
        public var SideMenu:MovieClip;
        public var btnToggleSideMenu:MovieClip;

        // Shortcut functions
        public static var Translate:Function;

        // Shortcuts to movieclips
        public var actualContent:MovieClip;

        // Menus
        public var menuList:Object;

        // For testing purposes
        public function frotaHud() : void {
            // Hook the menu
            hookMenu();

            // Remove the hud mask
            this.removeChild(hudMask);
        }

        // When the hud is loaded
        public function onLoaded() : void {
            // Store shortcut functions
            Translate = Globals.instance.GameInterface.Translate;

            // Get a reference to the overlay panel
            overlay = globals.Loader_frotaOverlay.movieClip;

            // Hook game events

            // Hook Game API Related Stuff
            Globals.instance.resizeManager.AddListener(this);

            // Remove the hud mask
            this.removeChild(hudMask);

            // Hook the side menu
            hookMenu();

            // Move the side button into place
            removeChild(btnToggleSideMenu);
            overlay.addChild(btnToggleSideMenu);

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

        public function hookMenu() {
            // Open the side menu
            SideMenu.openFull();

            // Hook Buttons
            btnToggleSideMenu.addEventListener(MouseEvent.CLICK, SideMenuToggleClicked, false, 0, true);
            SideMenu.Content.btnToggle.addEventListener(MouseEvent.CLICK, SideMenuToggleClicked, false, 0, true);
            SideMenu.Content.btnTest.addEventListener(MouseEvent.CLICK, TestButtonClicked, false, 0, true);

            // Create shortcuts
            actualContent = SideMenu.Content.subMenu.subMenuContent.actualContent;

            // Create menus
            menuList = {};
            menuList.welcome = new menuWelcome();
            menuList.voteScreen = new menuVoteScreen();

            // Apply welcome screen
            showScreen(menuList.welcome);

            // Apply vote screen
            showScreen(menuList.voteScreen);
        }

        public static function addFrameBehaviour(mc:MovieClip, frame:String, behaviour:Function) {
            // Loop over all labels
            for(var i:int=0;i<mc.currentLabels.length;i++){
                // Check if this is the frame we wanted
                if(mc.currentLabels[i].name == frame){
                    // Add event
                    mc.addFrameScript(mc.currentLabels[i].frame-1,behaviour);
                }
            }
        }

        public function SideMenuToggleClicked(e:MouseEvent) {
            // Toggle the side menu
            SideMenu.toggle();
        }

        public function TestButtonClicked(e:MouseEvent) {
            SideMenu.toggleExtend();
        }

        public static function cleanupClip(mc:MovieClip) {
            var children = mc.numChildren-1;
            while(children >= 0) {
                mc.removeChildAt(children);
                children--;
            }
        }

        public function showScreen(screen:MovieClip) {
            // Cleanup the old screen
            cleanupClip(actualContent);

            // Show new screen
            actualContent.addChild(screen);
        }
	}

}
