package {
    import flash.display.*;
    import flash.events.*;
    import flash.net.URLRequest;

	public class Skill extends MovieClip {
        public var skillNameText;

        public var skillName:String;
        public var skillSort:String
        public var skillHero:String
        public var skillNiceName:String
        public var skillDes:String


        public function Skill(skillName:String, skillSort:String, skillHero:String, skillNiceName:String, skillDes:String) {
            // Store the info
            this.skillName = skillName;
            this.skillSort = skillSort;
            this.skillHero = skillHero;
            this.skillNiceName = skillNiceName;
            this.skillDes = skillDes;

            // Load the image
            var myImageLoader:Loader = new Loader();
            var myImageLocation:URLRequest = new URLRequest("images/spellicons/"+this.skillName+".png");
            myImageLoader.load(myImageLocation);
            addChild(myImageLoader);

            // Scale it correctly
            myImageLoader.scaleX = 0.5;
            myImageLoader.scaleY = 0.5;

            // Adjust text
            skillNameText.text = "#DOTA_Tooltip_ability_"+this.skillName;
        }
	}
}