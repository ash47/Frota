package {
    import flash.display.MovieClip;
    import ValveLib.Globals;

	public class HeroDisplayMini extends MovieClip {
        public var heroName:String;

        private var imageHolder:MovieClip;

        public var dragSort = frota.DRAG_SORT_HERO;

        public function HeroDisplayMini(heroName:String) {
            // Store the info
            this.heroName = heroName;

            // Create somewhere to place the image
            imageHolder = new MovieClip();
            imageHolder.scaleX = 1/4.5;
            imageHolder.scaleY = 1/4.5;
            this.addChild(imageHolder);

            // Make sure a skill name was parsed
            if(heroName != '') {
                // Load the image
                Globals.instance.LoadHeroImage(this.heroName.replace('npc_dota_hero_', ''), imageHolder);
            }
        }

        public function UpdateHero(heroName:String) {
            // Store the info
            this.heroName = heroName;

            // Load the image
            Globals.instance.LoadHeroImage(this.heroName.replace('npc_dota_hero_', ''), imageHolder);
        }
	}
}