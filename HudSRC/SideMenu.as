package  {
	import flash.display.MovieClip;

	public class SideMenu extends MovieClip {
        // Movieclips on the stage
        public var Content:MovieClip;

        // Constants
        public var STATE_FULLY_CLOSED = 1;
        public var STATE_MENU_MOVING = 2;
        public var STATE_FULLY_OPEN = 3;

        public var menuState = STATE_MENU_MOVING;

        // When the menu is created
		public function SideMenu() {
            // Hook frame events
            frotaHud.addFrameBehaviour(this, "fullyClosed", this.fullyClosed);
            frotaHud.addFrameBehaviour(this, "fullyOpen", this.fullyOpen);

            // Default to fully closed
            this.gotoAndStop("fullyClosed");
		}

        function fullyClosed() : void {
            menuState = STATE_FULLY_CLOSED;
            stop();
        }

        function fullyOpen() : void {
            menuState = STATE_FULLY_OPEN;
            stop();
        }

        // Closes the menu
        public function close() {
            this.gotoAndPlay("close");
        }

        // Opens the menu
        public function open() {
            this.gotoAndPlay("open");
        }

        // Toggles the menu
        public function toggle() {
            // Check if we are open, or closed
            if(menuState == STATE_FULLY_OPEN) {
                this.close();
            } else if(menuState == STATE_FULLY_CLOSED) {
                this.open();
            }
        }
	}

}
