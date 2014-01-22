package  {
    import flash.display.MovieClip;

    public class frotaOverlay extends MovieClip {
        // Game API related stuff
        public var gameAPI:Object;
        public var globals:Object;
        public var elementName:String;

        // Containers
        public var upper:MovieClip;
        public var lower:MovieClip;

        // This function is required
        public function onLoaded() : void {}
    }
}
