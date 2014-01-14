package  {

	import flash.display.MovieClip;


	public class VoteButton extends MovieClip {
		public var Button;
		public var Text;
		public var Tally;

		public var optionName:String;
		public var optionDes:String;
		public var optionCount:String;

		public function VoteButton(optionName, optionDes, optionCount) {
			// Just update it
			update(optionName, optionDes, optionCount)
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
	}

}
