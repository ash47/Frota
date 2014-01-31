package  {
	import flash.display.MovieClip;
	import fl.containers.ScrollPane;


	public class menuVoteScreen extends MovieClip {
		// Contained movieclips
		public var voteContent:MovieClip;
		public var scrollPane:ScrollPane;

		// Positional Data
		private static var maxWidth:Number = 753;
		private var xx = 0;
		private var yy = 0;

		public function menuVoteScreen() {
			// Put the source in place
			scrollPane.source = voteContent;

			for(var i=0; i<30; i++) {
				addVoteChoice("asd", "aaa");
			}
		}

		public function newVote() {
			// Cleanup the content panel
			frotaHud.cleanupClip(voteContent);

			// Reset positional data
			xx = 0;
			yy = 0;

			// Update the scrollpane
			scrollPane.update();
		}

		public function addVoteChoice(name:String, text:String) {
			var vote = new voteText();
			voteContent.addChild(vote);
			vote.x = xx;
			vote.y = yy;

			xx += vote.width;
			if(xx+vote.width > maxWidth) {
				xx = 0;
				yy += vote.height;
			}

			// Update the scrollpane
			scrollPane.update();
		}
	}

}
