package {

	import flash.display.MovieClip;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import frota;

	public class ServerTimer extends MovieClip {
		public var timer:Timer;
		public var timeLeft:Number;
		public var text:String;
		public var removed = false;

		public var textField;

		public function ServerTimer(text, timeLeft) {
			// Store vars
			this.timeLeft = timeLeft;
			this.text = text;

			// Create a timer
			timer = new Timer(1000, timeLeft);
			timer.addEventListener(TimerEvent.TIMER, this.UpdateTextField);
			timer.start();

			// Update the text field
			this.UpdateTextField(0);
		}

		public function UpdateTextField(e) {
			// Check if this timer has been removed
			if(this.removed) {
				// Stop it
				timer.stop();
			} else {
				// Update timer, with a nice display
                if(this.timeLeft > 0 && this.timeLeft != 1) {
                    textField.text = frota.Translate(this.text)+"\n"+this.timeLeft+" "+frota.Translate("#afs_seconds_remaining");
                } else if(timeLeft == 1) {
                    textField.text = frota.Translate(this.text)+"\n1 "+frota.Translate("#afs_second_remaining");
                } else {
                	// Remove self
                    this.parent.removeChild(this);
                }

                // Lower the amout left
                this.timeLeft--;
			}
		}
	}

}
