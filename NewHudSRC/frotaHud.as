package  {
	// Flash stuff
	import flash.display.MovieClip;

	// Valve stuff
	import ValveLib.Globals;
    import ValveLib.ResizeManager;

    // Timers
    import flash.utils.Timer;
    import flash.events.TimerEvent;

	public class frotaHud extends MovieClip {
		// Game API related stuff
        public var gameAPI:Object;
        public var globals:Object;
        public var elementName:String;

        // These vars determain how much of the stage we can use
        // They are updated as the stage size changes
        public var maxStageWidth:Number = 1366;
        public var maxStageHeight:Number = 768;

		public function frotaHud() {}

		public function onLoaded() : void {
			trace('\n\n-- Frota Test Hud Loading --\n\n');

			// Debug message
			var testTimer:Timer = new Timer(1000);
            testTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent) {
            	trace('Hello there!')
            });
            testTimer.start();

            // Remove from parent
            this.parent.removeChild(this);

            this.gameAPI.SubscribeToGameEvent("afs_testb", this.testB);
		}

		public function testB(args:Object) {
            trace('Test b fired!');
        }
	}

}
