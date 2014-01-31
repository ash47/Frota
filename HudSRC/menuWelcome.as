package  {
	import flash.display.MovieClip;
	import fl.containers.ScrollPane;

	public class menuWelcome extends MovieClip {
		public var welcomeContent:MovieClip;
		public var scrollPane:ScrollPane;

		public function menuWelcome() {
			scrollPane.source = welcomeContent;
		}
	}

}
