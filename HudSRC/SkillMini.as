package {
    import flash.display.*;
    import flash.events.*;
    import flash.net.URLRequest;

    import ValveLib.Globals;

	public class SkillMini extends MovieClip {
        public var skillName:String;

        private var imageHolder:MovieClip;

        public function SkillMini(skillName:String) {
            // Store the info
            this.skillName = skillName;

            // Create somewhere to place the image
            imageHolder = new MovieClip();
            imageHolder.scaleX = 0.125;
            imageHolder.scaleY = 0.125;
            this.addChild(imageHolder);

            // Make sure a skill name was parsed
            if(skillName != '') {
                // Load the image
                Globals.instance.LoadAbilityImage(this.skillName, imageHolder);
            }
        }

        public function UpdateSkill(skillName:String) {
            // Store the info
            this.skillName = skillName;

            // Load the image
            Globals.instance.LoadAbilityImage(this.skillName, imageHolder);
        }
	}
}