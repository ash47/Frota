package  {
    import flash.display.MovieClip;

    public class SideMenu extends MovieClip {
        // Movieclips on the stage
        public var Content:MovieClip;
        public var subMenu:MovieClip;


        // Constants
        public static var STATE_FULLY_CLOSED = 1;
        public static var STATE_MENU_MOVING = 2;
        public static var STATE_FULLY_OPEN = 3;

        // Menu State Tracking
        public var menuState = STATE_MENU_MOVING;
        public var reopen = false;

        // When the menu is created
        public function SideMenu() {
            // Grab the sub menu
            subMenu = Content.subMenu;

            // Hook frame events
            frotaHud.addFrameBehaviour(this, "fullyClosed", this.fullyClosed);
            frotaHud.addFrameBehaviour(this, "fullyOpen", this.fullyOpen);

            // Default to fully closed
            this.gotoAndStop("fullyClosed");
        }

        function fullyClosed() : void {
            this.menuState = STATE_FULLY_CLOSED;
            stop();
            this.visible = false;
        }

        function fullyOpen() : void {
            this.menuState = STATE_FULLY_OPEN;
            stop();
        }

        // Closes the menu
        public function close() {
            this.gotoAndPlay("close");

            // Change menu state
            this.menuState = STATE_MENU_MOVING;

            // Check if we should reopen the sub menu
            if(subMenu.menuState == STATE_FULLY_OPEN) {
                // We should reopen
                reopen = true;
            } else {
                // No need to reopen
                reopen = false;
            }

            // Check if the menu needs to close
            if(subMenu.menuState != STATE_FULLY_CLOSED) {
                subMenu.close();
            }
        }

        // Opens the menu
        public function open() {
            // Make sure the menu isn't already open
            if(this.menuState != STATE_FULLY_OPEN) {
                this.gotoAndPlay("open");
                this.visible = true;

                // Change menu state
                this.menuState = STATE_MENU_MOVING;

                // Check if we need to reopen the sub menu
                if(reopen) {
                    subMenu.open();
                }
            }
        }

        // Opens the menu and the sub menu
        public function openFull() {
            // Make sure the menu isn't already open
            if(this.menuState != STATE_FULLY_OPEN) {
                this.gotoAndPlay("open");
                this.visible = true;

                // Change menu state
                this.menuState = STATE_MENU_MOVING;

                // Check if we need to reopen the sub menu
                if(reopen) {
                    subMenu.open();
                }
            }

            // Open the submenu
            subMenu.open();
        }

        // Toggles the menu
        public function toggle() {
            // Check if we are open, or closed
            if(this.menuState == STATE_FULLY_OPEN) {
                this.close();
            } else if(this.menuState == STATE_FULLY_CLOSED) {
                this.open();
            }
        }

        // Toggles the 2ndary menu
        public function toggleExtend() {


            subMenu.toggle();
        }
    }
}
