package  {

	import flash.display.MovieClip;
	import flash.events.Event;

	public class VoteButtonSlider extends MovieClip {
		public var Slider;
		public var Stepper;
		public var Text;
		public var Tally;

		public var optionName:String;
		public var optionDes:String;
		public var optionCount:String;

		public var lastValue:Number = -1;

		public function VoteButtonSlider(optionName, optionDes, optionCount, min, max, tick, step, def) {
			// Just update it
			update(optionName, optionDes, optionCount);

			// Adjust slider
			Slider.minimum = min;
			Slider.maximum = max;
			Slider.value = def;
			Slider.tickInterval = tick;
			Slider.snapInterval = step;
			Slider.liveDragging = true;
			Slider.addEventListener(Event.CHANGE, sliderValueChange);

			// Adjust stepper
			Stepper.minimum = min;
			Stepper.maximum = max;
			Stepper.value = def;
			Stepper.stepSize = step;
			Stepper.addEventListener(Event.CHANGE, stepperValueChange);
		}

		public function update(optionName, optionDes, optionCount) {
			// Update local vars
			this.optionName = optionName;
			this.optionDes = optionDes;
			this.optionCount = optionCount;

			// Update displays
			Text.text = optionName;
			Tally.text = optionCount;
		}

		public function updateCount(optionCount) {
			this.optionCount = optionCount;
			Tally.text = optionCount;
		}

		public function stepperValueChange(e:Event) {
			this.Slider.value = this.Stepper.value;
		}

		public function sliderValueChange(e:Event) {
			this.Stepper.value = this.Slider.value;
		}
	}

}
