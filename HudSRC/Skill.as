package {
    import flash.display.*;
    import flash.events.*;
    import flash.net.URLRequest;

    import ValveLib.Globals;

	public class Skill extends MovieClip {
        public var skillNameText;

        public var skillName:String;
        public var skillSort:String
        public var skillHero:String

        private var imageHolder:MovieClip;

        public function Skill(skillName:String, skillSort:String, skillHero:String) {
            // Store the info
            this.skillName = skillName;
            this.skillSort = skillSort;
            this.skillHero = skillHero;

            // Create somewhere to place the image
            imageHolder = new MovieClip();
            imageHolder.scaleX = 0.5;
            imageHolder.scaleY = 0.5;
            this.addChild(imageHolder);

            // Load the image
            Globals.instance.LoadAbilityImage(this.skillName, imageHolder);

            // Adjust text
            skillNameText.text = "#DOTA_Tooltip_ability_"+this.skillName;
        }
	}
}