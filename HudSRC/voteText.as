package  {

	import flash.display.MovieClip;


	public class voteText extends MovieClip {
		public var flashAnim:MovieClip;

		public function voteText() {
			// Hide the flashing animation
			flashAnim.visible = false;
		}

		public function flash(enable:Boolean) {
			// Enable or disable the flashing
			flashAnim.visible = enable;
		}
	}

}
