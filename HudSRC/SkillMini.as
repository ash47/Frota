package {
    import flash.display.MovieClip;
    import ValveLib.Globals;

	public class SkillMini extends MovieClip {
        public var skillName:String;
        private var imageHolder:MovieClip;
        public var dragSort = frota.DRAG_SORT_SKILL;

        public function SkillMini(skillName:String) {
            // Create somewhere to place the image
            imageHolder = new MovieClip();
            imageHolder.scaleX = 1/8;
            imageHolder.scaleY = 1/8;
            this.addChild(imageHolder);

            // Update the icon
            UpdateSkill(skillName);
        }

        public function UpdateSkill(skillName:String) {
            // Store the info
            this.skillName = skillName;

            // Load the image
            Globals.instance.LoadAbilityImage(this.skillName, imageHolder);
        }
	}
}