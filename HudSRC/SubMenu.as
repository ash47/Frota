package  {

	import flash.display.MovieClip;


	public class SubMenu extends MovieClip {
		// Movieclips on the stage
		public var subMenuContent:MovieClip;

		// Menu State Tracking
		public var menuState = SideMenu.STATE_FULLY_CLOSED;

		public function SubMenu() {
			// Hook frame events
            frotaHud.addFrameBehaviour(this, "fullyClosed", this.fullyClosed);
            frotaHud.addFrameBehaviour(this, "fullyOpen", this.fullyOpen);

            // Default to fully closed
            this.gotoAndStop("fullyClosed");
		}

		function fullyClosed() : void {
			menuState = SideMenu.STATE_FULLY_CLOSED;
			this.visible = false;
            stop();
        }

        function fullyOpen() : void {
        	menuState = SideMenu.STATE_FULLY_OPEN;
            stop();
        }

        // Closes the menu
        public function close() {
            this.gotoAndPlay("close");
        }

        // Opens the menu
        public function open() {
            this.gotoAndPlay("open");
            this.visible = true;
        }

        // Toggles the menu
        public function toggle() {
            // Check if we are open, or closed
            if(menuState == SideMenu.STATE_FULLY_OPEN) {
                this.close();
            } else if(menuState == SideMenu.STATE_FULLY_CLOSED) {
                this.open();
            }
        }
	}

}
