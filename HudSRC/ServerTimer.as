package {

	import flash.display.MovieClip;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import frota;

	public class ServerTimer extends MovieClip {
		public var timeLeft:Number;
		public var text:String;
		public var removed = false;

		public var textField;

		public function ServerTimer(text, timeLeft) {
			// Store vars
			this.timeLeft = timeLeft;
			this.text = text;

			// Create a timer
			var timer:Timer = new Timer(1000, timeLeft);
			timer.addEventListener(TimerEvent.TIMER, this.UpdateTextField, false, 0, true);
			timer.start();

			// Update the text field
            textField.text = frota.Translate(this.text)+"\n"+this.timeLeft+" "+frota.Translate("#afs_seconds_remaining");
		}

		public function UpdateTextField(e:TimerEvent) {
            if(!stage) {
                // Stop timer
                e.target.stop();
                return;
            }

			// Check if this timer has been removed
			if(this.removed) {
				// Stop it
				e.target.stop();
			} else {
                if(!this.textField) {
                    this.removed = true;
                    e.target.stop();
                    return;
                }

				// Update timer, with a nice display
                if(this.timeLeft > 0 && this.timeLeft != 1) {
                    textField.text = frota.Translate(this.text)+"\n"+this.timeLeft+" "+frota.Translate("#afs_seconds_remaining");
                } else if(timeLeft == 1) {
                    textField.text = frota.Translate(this.text)+"\n1 "+frota.Translate("#afs_second_remaining");
                } else {
                	// Remove self
                    if(this.parent) {
                        this.parent.removeChild(this);
                    } else {
                        // Stop timer
                        e.target.stop();
                    }
                }

                // Lower the amout left
                this.timeLeft--;
			}
		}
	}

}
