package {
    import flash.display.*;
    import flash.events.*;
    import fl.containers.ScrollPane;
    import fl.controls.ScrollPolicy;
    import flash.utils.Timer;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    import scaleform.clik.controls.TextInput;
    import scaleform.clik.events.FocusHandlerEvent;

    import ValveLib.Globals;

    public class frota extends MovieClip {
        public var gameAPI:Object;
        public var globals:Object;
        public var elementName:String;

        //public var Button1;
        //public var Button2;

        //public var SelectSlot1;
        //public var SelectSlot2;
        //public var SelectSlot3;
        //public var SelectSlot4;

        public var maxStageWidth:Number = 1366;
        public var maxStageHeight:Number = 768;

        public var iconWidth:Number = 64;
        public var iconHeight:Number = 80;
        public var voteHeight:Number = 31;

        // Main panel stuff
        public var contentPanelHolder:ScrollPane;
        public var contentPanel:MovieClip;

        public var selectedSkill:MovieClip;

        public var hudMask:MovieClip;

        public var voteHolder:Object;

        // State control
        public var currentState:Number = 0;
        public var gottenInitialState = false;
        public var STATE_INIT = 0;
        public var STATE_VOTING = 1;
        public var STATE_PICKING = 2;
        public var STATE_BANNING = 3;
        public var STATE_PLAYING = 4;

        private var bGotInput = false;

        // This will contain movieclips and stuff that needs to be cleaned up
        public var stateCleanup = new Array();

        public function frota() {
            var a = new DefaultTextInput();
            addChild(a);
            a.x = 4;
            a.y = 537;

            //onLoaded();

            /*newPanel();

            var padding:Number = 8;

            var btn = new VoteButton();
            addPanelChild(btn);
            btn.x = padding;
            btn.y = padding;*/



            /*var skill = new Skill("asd", "", "", "", "");
            addChild(skill);
            skill.x = 480;
            skill.y = 554;*/

            /*var vote = new VoteButton("test vote", "some desc", 5);
            addChild(vote);
            vote.x = 0;
            vote.y = 0;

            vote.Button.addEventListener(MouseEvent.CLICK, this.votePressed);*/

            /*newPanel();

            var padding:Number = 8;

            var btn = new VoteButton("aaa", "", "");
            autoCleanup(btn);
            btn.x = padding;
            btn.y = padding;

            //cleanHud();

            //removeChild(btn);*/
        }

        public function onLoaded() : void {
            printToServer("Hud init");
            trace("\n\n-- HELLO JOEa! --\n\n");

            this.gameAPI.SubscribeToGameEvent("hero_picker_hidden", this.onHeroPickerHidden);
            this.gameAPI.SubscribeToGameEvent("afs_initial_state", this.receiveInitialState);
            this.gameAPI.SubscribeToGameEvent("afs_update_state", this.processState);
            this.gameAPI.SubscribeToGameEvent("afs_vote_status", this.updateVoteStatus);
            //this.gameAPI.SubscribeToGameEvent("afs_herolist", this.heroListTest);

            // Register Buttons
            //this.Button1.addEventListener(MouseEvent.CLICK, this.testClick);
            //this.Button2.addEventListener(MouseEvent.CLICK, this.testClick2);

            // Register Select Buttons
            //this.SelectSlot1.addEventListener(MouseEvent.CLICK, this.skillIntoSlot);
            //this.SelectSlot2.addEventListener(MouseEvent.CLICK, this.skillIntoSlot);
            //this.SelectSlot3.addEventListener(MouseEvent.CLICK, this.skillIntoSlot);
            //this.SelectSlot4.addEventListener(MouseEvent.CLICK, this.skillIntoSlot);

            // Hide the Hud Mask
            hudMask.visible = false;

            // Always visible
            visible = true

            // Request the current game state (after a delay)
            var timer:Timer = new Timer(1000, 1);
            timer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent) {
                printToServer("Timer fired")
                gameAPI.SendServerCommand("afs_request_state");
            });
            timer.start();

            // Text input
            var a = new DefaultTextInput();
            addChild(a);
            a.x = 4;
            a.y = 537;

            a.text = "#npc_dota_hero_abyssal_underlord";

            /*a.actAsButton = false;
            a.displayAsPassword = false;
            a.editable = true;
            a.enabled = true;
            a.focusable = true;
            a.maxChars = 32;
            a.text = "";
            a.visible = true;
            a.constraintsDisabled = true;*/

            a.addEventListener(FocusHandlerEvent.FOCUS_IN, inputBoxGainFocus);
            a.addEventListener(FocusHandlerEvent.FOCUS_OUT, inputBoxLoseFocus);

            // Hook stuff
            Globals.instance.resizeManager.AddListener(this);
            this.gameAPI.OnReady();
            Globals.instance.GameInterface.AddMouseInputConsumer();

            //printToServer("Game API:")
            //PrintTable(this.gameAPI, 1);

            /*trace("\nGlobals")
            PrintTable(Globals.instance.GameInterface, 1);

            var playerID = globals.Players.GetLocalPlayer();
            printToServer("PlayerID: "+playerID);
            var heroID = globals.Players.GetPlayerHeroEntityIndex(playerID);
            printToServer("HeroID: "+heroID);
            var count = globals.Entities.GetAbilityCount(heroID);
            printToServer("Count: "+count);

            for(var i=0; i<count; i++) {
                var ab = globals.Entities.GetAbility(heroID, i);
                if(ab != -1) {
                    var abName = globals.Abilities.GetAbilityName(ab);
                    printToServer("Found "+abName);
                }
            }



            printToServer(globals.Entities.IsHero(heroID));
            printToServer("Done debugging!");*/
        }

        public function inputBoxGainFocus() {
            if(!bGotInput) {
                bGotInput = true;
                Globals.instance.GameInterface.AddKeyInputConsumer();
            }
        }

        public function inputBoxLoseFocus() {
            if(bGotInput) {
                bGotInput = false;
                Globals.instance.GameInterface.RemoveKeyInputConsumer();
            }
        }

        public function cleanHud() {
            // Remove all items from the hud
            for(var key in stateCleanup) {
                removeChild(stateCleanup[key]);
            }

            // Create new store
            stateCleanup = new Array();

            // Cleanup content panel
            if(contentPanelHolder != null) {
                removeChild(contentPanelHolder)
                contentPanelHolder = null;
            }
        }

        public function autoCleanup(mc) {
            // Add to the main area
            addChild(mc);

            // Set it for cleanup
            stateCleanup.push(mc);
        }

        public function makeTextField(txtSize:Number):TextField {
            var txt:TextField = new TextField();
            var textFormat:TextFormat = new TextFormat();
            textFormat.size = txtSize;
            textFormat.align = TextFormatAlign.LEFT;
            txt.defaultTextFormat = textFormat;

            txt.text = "change this";
            txt.textColor = 0xFFFFFF;
            txt.selectable = false;

            return txt;
        }

        public function receiveInitialState(args:Object) {
            printToServer("Got an Initial State")

            // If we already have the initial state, ignore
            if(this.gottenInitialState) return;
            this.gottenInitialState = true;

            // Process the state
            processState(args);
        }

        public function processState(args:Object) {
            printToServer("Got a state commands: "+args.nState);

            // Cleanup anything from old states
            cleanHud();


            switch(args.nState) {
                case STATE_INIT:
                    // Nothing has even happened yet
                break;

                case STATE_PICKING:
                    this.BuildPickingScreen(args.d);
                break;

                case STATE_VOTING:
                    this.BuildVoteScreen(args.d);
                break;

                default:
                    printToServer("Dont know how to process: "+args.nState);
                break;
            }
        }

        public function updateVoteStatus(args:Object) {
            printToServer("Got an updated vote status");

            // Make sure we have the vote info
            if(voteHolder == null) return;

            for each (var s:String in args.d.split(":::")) {
                var voteInfo = s.split("::")

                // Create vote panel
                var vote = voteHolder[voteInfo[0]];

                // Check if we found it
                if(vote != null) {
                    // Update the count
                    vote.updateCount(voteInfo[1]);

                    printToServer("Updated "+voteInfo[0]);
                } else {
                    printToServer("Failed to find "+voteInfo[0]);
                }
            }
        }

        public function newPanel() : void {
            // Cleanup old skill picker
            if(contentPanelHolder != null) {
                removeChild(contentPanelHolder)
                contentPanelHolder = null;
            }

            // Build Skill Picking panel
            contentPanelHolder = new ScrollPane();
            contentPanelHolder.setSize(maxStageWidth-128, 448);
            addChild(contentPanelHolder)
            contentPanelHolder.x = 64;
            contentPanelHolder.y = 64;

            // Setup the panel where the icons will go
            contentPanel = new MovieClip();
            contentPanelHolder.source = contentPanel;
        }

        public function addPanelChild(clip:MovieClip) {
            contentPanel.addChild(clip);
        }

        public function updatePanel() {
            contentPanelHolder.update();
        }

        public function getContentWidth() {
            return contentPanelHolder.width;
        }

        public function getContentHeight() {
            return contentPanelHolder.height;
        }

        public function skillIntoSlot(e:Event) {
            var slotNumber:Number = Number(e.currentTarget.name.replace("SelectSlot", ""));

            if(selectedSkill != null) {
                this.gameAPI.SendServerCommand("afs_skill \""+selectedSkill.skillName+"\" "+slotNumber);
            }
        }

        public function votePressed(e:Event) {
            var vote = e.currentTarget.parent;
            this.gameAPI.SendServerCommand("afs_vote \""+vote.optionName+"\"");
        }

        public function skillClicked(e:Event) {
            if(selectedSkill != null) {
                removeChild(selectedSkill);
            }

            var s = e.currentTarget;
            selectedSkill = new Skill(s.skillName, s.skillSort, s.skillHero, s.skillNiceName, s.skillDes);
            addChild(selectedSkill);
            selectedSkill.x = 480;
            selectedSkill.y = 554;
        }

        public function strRep(str, count) {
            var output = "";
            for(var i=0; i<count; i++) {
                output = output + str;
            }

            return output;
        }

        public function PrintTable(t, indent) {
            for(var key in t) {
                var v = t[key];

                if(typeof(v) == "object") {
                    trace(strRep("\t", indent)+key+":")
                    PrintTable(v, indent+1);
                } else {
                    trace(strRep("\t", indent)+key.toString()+": "+v.toString());
                }
            }
        }

        public function onScreenSizeChanged() : void {
            x = 0;
            y = 0;
            printToServer("Screen size changed: "+stage.stageWidth+" "+stage.stageHeight+" "+this.globals.resizeManager.ScreenWidth+" "+this.globals.resizeManager.ScreenHeight);

            // Lets assume the height never changes:
            maxStageWidth = stage.stageWidth / stage.stageHeight * 768;
        }

        public function skillClick(e:Event) : void {
            trace("clicked! "+e.currentTarget.icon);
        }

        public function testClick(e:Event) {
            visible = false;
            printToServer("Clicked button 1")
        }

        public function testClick2(e:Event){
            printToServer("Clicked button 2");
        }

        public function onHeroPickerHidden(args:Object) {
            printToServer("Hero Picked Event fired")
            visible = true;
        }

        public function BuildPickingScreen(data:String) {
            // Create a new panel for the skills
            newPanel();

            // Setting for skill picking panel
            var padding:Number = 4;
            var xo = (getContentWidth() - Math.floor(getContentWidth()/(iconWidth+padding))*iconWidth)/2;
            var xx:Number = xo;
            var yy:Number = 0;

            // Put all the icons in
            for each (var s:String in data.split("||")) {
                var skillInfo = s.split("::")

                var skill = new Skill(skillInfo[0], skillInfo[1], skillInfo[2], skillInfo[3], skillInfo[4]);
                addPanelChild(skill);
                skill.x = xx;
                skill.y = yy;

                skill.addEventListener(MouseEvent.CLICK, this.skillClicked);

                xx = xx + iconWidth + padding;
                if(xx+iconWidth > getContentWidth()) {
                    xx = xo;
                    yy = yy + iconHeight + padding;
                }
            }

            // Update the scrollbar
            updatePanel();
        }

        public function BuildVoteScreen(data:String) {
            printToServer("Building Voting Screen");

            // Create a new panel for the skills
            newPanel();

            // Setting for skill picking panel
            var padding:Number = 8;
            var xo = padding;
            var xx:Number = xo;
            var yy:Number = padding;

            // Calculate useful shit
            var d = data.split("||")
            var dd = d[0].split("::")
            var endingTime = dd[0];
            var voteSort = dd[1];
            var voteDuration = dd[2];

            var timeLeft = Math.floor(endingTime - this.globals.Game.Time());

            // Create text field to display how long left
            var txt = makeTextField(18);
            autoCleanup(txt);
            txt.x = 4;
            txt.y = 32;
            txt.width = 240;
            txt.text = timeLeft+" Seconds Remaining";

            // Make the time left change
            var timer:Timer = new Timer(1000, timeLeft);
            timer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent) {
                // Ensure timer still exists
                if(txt) {
                    // Workout how long is left
                    timeLeft = Math.floor(endingTime - globals.Game.Time());

                    // Update timer, with a nice display
                    if(timeLeft > 0 && timeLeft != 1) {
                        txt.text = timeLeft+" Seconds Remaining";
                    } else if(timeLeft == 1) {
                        txt.text = "1 Second Remaining";
                    } else {
                        txt.text = "Waiting for vote to end...";
                    }
                } else {
                    // Stop the timer
                    timer.stop();
                }
            });
            timer.start();

            // This will store all the vote panels
            voteHolder = {};

            // Fill it with vote options
            for each (var s:String in d[1].split(":::")) {
                var voteInfo = s.split("::")

                // Create vote panel
                var vote = new VoteButton(voteInfo[0], voteInfo[1], voteInfo[2]);
                addPanelChild(vote);
                vote.x = xx;
                vote.y = yy;

                // Listen to button press
                vote.Button.addEventListener(MouseEvent.CLICK, this.votePressed);

                // Store this panel
                voteHolder[voteInfo[0]] = vote;

                // Move the next panel down
                yy = yy + voteHeight + padding;
            }

            // Update the scrollbar
            updatePanel();
        }

        public function printToServer(msg:String) {
            this.gameAPI.SendServerCommand("afs_print \""+msg+"\"");
        }
    }
}
