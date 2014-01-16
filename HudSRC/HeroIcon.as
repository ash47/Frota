package {
	import flash.display.MovieClip;
	import ValveLib.Globals;

	public class HeroIcon extends MovieClip {
		public var heroName;

		private var imageHolder:MovieClip;
		public var heroNameText;

		public var dragSort = frota.DRAG_SORT_HERO;

		public function HeroIcon(heroName) {
			// Create somewhere to place the image
            imageHolder = new MovieClip();
            imageHolder.scaleX = 0.5;
            imageHolder.scaleY = 0.5;
            this.addChild(imageHolder);

            // Update the icon
            UpdateHero(heroName);
		}

		public function UpdateHero(heroName:String) {
            // Store the info
            this.heroName = heroName;

            // Load the image
            Globals.instance.LoadHeroImage(this.heroName.replace('npc_dota_hero_', ''), imageHolder);

            // Adjust text
            heroNameText.text = "#"+this.heroName;
        }
	}

}
