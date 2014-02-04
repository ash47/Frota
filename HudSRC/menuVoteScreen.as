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
		private var voteWidth = 250;
		private var voteHeight = 62;

		public function menuVoteScreen() {
			// Put the source in place
			scrollPane.source = voteContent;

			var vote:voteText = addVoteChoice("asd", "aaa");
			vote.flash(true);

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

		public function addVoteChoice(name:String, text:String) : voteText {
			var vote:voteText = new voteText();
			voteContent.addChild(vote);
			vote.x = xx;
			vote.y = yy;

			xx += voteWidth;
			if(xx+voteWidth > maxWidth) {
				xx = 0;
				yy += voteHeight;
			}

			// Update the scrollpane
			scrollPane.update();

			return vote;
		}
	}

}
