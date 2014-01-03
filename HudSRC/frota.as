package {
    import flash.display.*;
    import flash.events.*;
    import fl.containers.ScrollPane;
    import fl.controls.ScrollPolicy;
    import fl.controls.Button;
    import flash.utils.Timer;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.geom.Point;

    import com.adobe.serialization.json.*;

    import scaleform.clik.controls.TextInput;
    import scaleform.clik.events.FocusHandlerEvent;

    import ValveLib.Globals;

    public class frota extends MovieClip {
        // Game API related stuff
        public var gameAPI:Object;
        public var globals:Object;
        public var elementName:String;

        // These vars determain how much of the stage we can use
        // They are updated as the stage size changes
        public var maxStageWidth:Number = 1366;
        public var maxStageHeight:Number = 768;

        // Amount of space to leave under the bottom
        public var bottomMargin:Number = 90;

        // Sizing
        public var iconWidth:Number = 64;
        public var iconHeight:Number = 80;
        public var voteHeight:Number = 31;
        public var iconMiniSize:Number = 16;

        // Limits
        public var maxSkills = 4;

        // Main panel stuff
        private var contentPanelHolder:ScrollPane;
        private var contentPanel:MovieClip;

        // This contains the currently selected skill (will probably be removed)
        private var selectedSkill:MovieClip;

        // This is the red mask thingo (for lining stuff up)
        public var hudMask:MovieClip;

        // Hides the game
        public var hideGame:MovieClip;

        // This holds vote panels (so we can update them)
        private var voteHolder:Object;

        // Contains picking data
        private var pickingData:Object = {};

        // State control
        private var currentState:Number = 0;
        private var gottenInitialState = false;
        private var STATE_INIT = 0;
        private var STATE_VOTING = 1;
        private var STATE_PICKING = 2;
        private var STATE_BANNING = 3;
        private var STATE_PLAYING = 4;

        // This is for toggling input on text fields
        private var bGotInput = false;

        // This will contain movieclips and stuff that needs to be cleaned up
        private var stateCleanup = new Array(); // Generic stuff that can be removed
        private var stateCleanupSpecial = {};   // Specific things that can be removed

        // Shortcut functions
        public var Translate;  // Translates a #tag into something readable

        // Contains the movieclip we are dragging
        public var dragClip;
        public var dragClickedClip;
        public var dragTarget;

        public function frota() {}

        public function onLoaded() : void {
            // Store shortcut functions
            Translate = Globals.instance.GameInterface.Translate;

            trace("\n\n-- Frota hud starting to load! --\n\n");

            //trace('globals:');
            //PrintTable(globals, 1);

            this.gameAPI.SubscribeToGameEvent("hero_picker_hidden", this.requestCurrentState);
            this.gameAPI.SubscribeToGameEvent("afs_initial_state", this.receiveInitialState);
            this.gameAPI.SubscribeToGameEvent("afs_update_state", this.processState);
            this.gameAPI.SubscribeToGameEvent("afs_vote_status", this.updateVoteStatus);
            this.gameAPI.SubscribeToGameEvent("afs_update_builds", this.updateBuildDataHook);

            // Hide the Hud Mask
            hudMask.visible = false;

            // Make the hud visible
            visible = true

            // Request the current state
            requestCurrentState();

            // Hook stuff
            Globals.instance.resizeManager.AddListener(this);
            this.gameAPI.OnReady();
            Globals.instance.GameInterface.AddMouseInputConsumer();

            // Text input
            /*var a = new DefaultTextInput();
            addChild(a);
            a.x = 4;
            a.y = 537;

            a.text = "";

            a.addEventListener(FocusHandlerEvent.FOCUS_IN, inputBoxGainFocus);
            a.addEventListener(FocusHandlerEvent.FOCUS_OUT, inputBoxLoseFocus);*/
        }

        public function requestCurrentState() {
            // Reset initial state received
            this.gottenInitialState = false;

            // Request the current game state (after a delay)
            var timer:Timer = new Timer(1000, 1);
            timer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent) {
                gameAPI.SendServerCommand("afs_request_state");
            });
            timer.start();
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
            var key;

            // Remove all items from the hud
            for(key in stateCleanup) {
                removeChild(stateCleanup[key]);
            }

            for(key in stateCleanupSpecial) {
                removeChild(stateCleanupSpecial[key]);
            }

            // Create new store
            stateCleanup = new Array();
            stateCleanupSpecial = {};

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

        public function autoCleanupSpecial(mc, name) {
            // Add to the main area
            addChild(mc);

            // Set it for cleanup
            stateCleanupSpecial[name] = mc;
        }

        public function getSpecial(name) {
            return stateCleanupSpecial[name];
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
            // If we already have the initial state, ignore
            if(this.gottenInitialState) return;
            this.gottenInitialState = true;

            // Process the state
            processState(args);
        }

        public function processState(args:Object) {
            // Cleanup anything from old states
            cleanHud();

            // Parse data
            var data = decode(args.d);

            switch(args.nState) {
                case STATE_INIT:
                    // Nothing has even happened yet
                break;

                case STATE_PICKING:
                    this.ProcessPickingData(data);
                    this.BuildPickingScreen();
                    hideGame.visible = true;
                break;

                case STATE_VOTING:
                    this.BuildVoteScreen(data);
                    hideGame.visible = true;
                break;

                case STATE_PLAYING:
                    hideGame.visible = false;
                break;

                default:
                    trace("Dont know how to process: "+args.nState);
                break;
            }
        }

        public function ProcessPickingData(data) {
            var s:String;

            // Reset the picking data
            pickingData = {};
            pickingData.skills = [];
            pickingData.builds = data.b;

            // Build skill list
            for(var name in data.s) {
                // Grab info on this skill
                var info = data.s[name];

                // Check if it's banned
                var banned = false;
                if(info.b) banned = true;

                // Push the skill
                pickingData.skills.push({
                    skillName: name,
                    skillSort: info.c,
                    skillHero: info.h,
                    banned: banned
                })
            }

            // Sort it
            pickingData.skills.sort(function(a, b) {
                // Grab translated heroes
                var ha = Translate("#"+a.skillHero);
                var hb = Translate("#"+b.skillHero);

                // Sort by hero, then type, then skill name
                if(ha < hb) {
                    return -1;
                } else if(ha > hb) {
                    return 1;
                } else {
                    // Grab ability types
                    var ta = a.skillSort;
                    var tb = b.skillSort;

                    if(ta < tb) {
                        return -1;
                    } else if(ta > tb) {
                        return 1;
                    } else {
                        // Grab translated skill names
                        var na = Translate("#DOTA_Tooltip_ability_"+a.skillName);
                        var nb = Translate("#DOTA_Tooltip_ability_"+b.skillName);

                        if(na < nb) {
                            return -1;
                        } else if(na > nb) {
                            return 1;
                        } else {
                            // Compare based on their raw skill name
                            if(a.skillName < b.skillName) {
                                return -1;
                            } else if(a.skillName > b.skillName) {
                                return 1;
                            } else {
                                return 0;
                            }
                        }
                    }
                }
            });

            // Store hero builds
            this.updateBuildData(data.b);
        }

        public function updateBuildData(data) {
            var skill, i:Number, j:Number, skillName:String;

            // Clear out current builds
            pickingData.builds = data;

            // Find icons for local hero
            var localSkills = [];

            // Grab playerID to build skill list
            var playerID = globals.Players.GetLocalPlayer();

            if(playerID >= 0 && playerID <= 9) {
                // Update our local skill list
                localSkills = pickingData.builds[playerID].s;
            }

            // Update icons for your local hero
            for(i=0; i<maxSkills; i++) {
                // Attempt to grab this skill
                skill = getSpecial('skill_'+i);
                if(skill) {
                    // Grab name of this skill
                    skillName = localSkills[i];
                    if(!skillName) skillName = 'doom_bringer_empty1';

                    // Found it, update it
                    skill.UpdateSkill(skillName);
                }
            }

            // The last set that is visible
            var lastVisible = 0;

            // Side icons
            for(i=0; i<10; i++) {
                var build = pickingData.builds[i];
                if(build) {
                    var shouldDisplay = (globals.Players.GetPlayerHeroEntityIndex(i) != -1);

                    if(shouldDisplay) lastVisible = i;

                    // Update Hero Image
                    skill = getSpecial('hero_'+i);
                    if(skill) {
                        skill.UpdateHero(build.h);
                        skill.visible = shouldDisplay;
                    }

                    // Update ready state
                    skill = getSpecial('ready_'+i);
                    if(skill) skill.visible = shouldDisplay && build.r;

                    for(j=0; j<maxSkills; j++) {
                        skill = getSpecial('skill_'+i+'_'+j);
                        if(skill) {
                            // Grab name of this skill
                            skillName = build.s[j];
                            if(!skillName) skillName = 'doom_bringer_empty1';

                            // Found it, update it
                            skill.UpdateSkill(skillName);
                            skill.visible = shouldDisplay;
                        }
                    }
                }
            }
        }

        public function updateBuildDataHook(args:Object) {
            this.updateBuildData(decode(args.d));
        }

        public function updateVoteStatus(args:Object) {
            // Make sure we have the vote info
            if(voteHolder == null) return;

            // Grab the data
            var data = decode(args.d);

            for (var name:String in data) {
                var voteInfo = data[name];

                // Create vote panel
                var vote = voteHolder[name];

                // Check if we found it
                if(vote != null) {
                    // Update the count
                    vote.updateCount(voteInfo.count);
                } else {
                    trace("Failed to find "+name);
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
            contentPanelHolder.setSize(maxStageWidth-368, maxStageHeight - iconHeight - bottomMargin - 120);
            addChild(contentPanelHolder)
            contentPanelHolder.x = 208;
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

        public function skillIntoSlot(skillName, slotNumber) {
            this.gameAPI.SendServerCommand("afs_skill \""+skillName+"\" "+slotNumber);
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
            selectedSkill = new Skill(s.skillName, s.skillSort, s.skillHero);
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

                    if(v.gameAPI) {
                        trace(strRep("\t", indent+1)+"gameAPI:")
                        PrintTable(v.gameAPI, indent+2);
                    }
                } else {
                    trace(strRep("\t", indent)+key.toString()+": "+v.toString());
                }
            }
        }

        public function onScreenSizeChanged() : void {
            x = 0;
            y = 0;
            trace("Screen size changed: "+stage.stageWidth+" "+stage.stageHeight+" "+this.globals.resizeManager.ScreenWidth+" "+this.globals.resizeManager.ScreenHeight);

            // Lets assume the height never changes:
            maxStageWidth = stage.stageWidth / stage.stageHeight * 768;
        }

        // Displays the skill info thing about a given skill (requires rollOver event)
        public function onSkillRollOver(e:MouseEvent) {
            // Grab what we rolled over
            var s = e.target;

            // Workout where to put it
            var lp = s.localToGlobal(new Point(0, 0));

            // Display the info
            globals.Loader_heroselection.gameAPI.OnSkillRollOver(lp.x, lp.y, s.skillName);
        }

        // Hides the skill info thing (Requires rollOut event)
        public function onSkillRollOut(e:MouseEvent) {
            globals.Loader_heroselection.gameAPI.OnSkillRollOut();
        }

        public function BuildPickingScreen() {
            var skill:MovieClip, i:Number, j:Number, xpadding:Number, ypadding:Number, totalWidth:Number, skillName:String, sx:Number, sy:Number;

            // Create a new panel for the skills
            newPanel();

            // Setting for skill picking panel
            var padding:Number = 4;
            var xo = 16;//(getContentWidth() - Math.floor(getContentWidth()/(iconWidth+padding))*iconWidth)/4;
            var xx:Number = xo;
            var yy:Number = 0;

            // Put all the icons in
            for each (var skillInfo in pickingData.skills) {
                skill = new Skill(skillInfo.skillName, skillInfo.skillSort, skillInfo.skillHero);
                addPanelChild(skill);
                skill.x = xx;
                skill.y = yy;

                // Allow dragging from this
                dragMakeValidFrom(skill);

                //skill.addEventListener(MouseEvent.CLICK, this.skillClicked);
                skill.addEventListener(MouseEvent.ROLL_OVER, this.onSkillRollOver);
                skill.addEventListener(MouseEvent.ROLL_OUT, this.onSkillRollOut);

                xx = xx + iconWidth + padding;
                if(xx+iconWidth > getContentWidth()) {
                    xx = xo;
                    yy = yy + iconHeight + padding;
                }
            }

            // Update the scrollbar
            updatePanel();

            // Find icons for local hero
            var localSkills = [];

            // Grab playerID to build skill list
            var playerID = globals.Players.GetLocalPlayer();

            if(playerID >= 0 && playerID <= 9) {
                // Update our local skill list
                localSkills = pickingData.builds[playerID].s;
            }

            // Put icons for your local hero

            xpadding = 16;
            totalWidth = (iconWidth+xpadding) * maxSkills - xpadding;

            xx = (maxStageWidth - totalWidth) / 2;
            yy = maxStageHeight - iconHeight - bottomMargin - 32;

            for(i=0; i<maxSkills; i++) {
                // Grab name of this skill
                skillName = localSkills[i];
                if(!skillName) skillName = 'doom_bringer_empty1';

                // Create a skill
                skill = new Skill(skillName, '', '');
                autoCleanupSpecial(skill, 'skill_'+i);
                skill.x = xx;
                skill.y = yy;

                // Store slot number as name
                skill.name = String(i+1);

                // Allow dragging to this slot
                dragMakeValidTarget(skill)

                // Hook the skill
                skill.addEventListener(MouseEvent.ROLL_OVER, this.onSkillRollOver);
                skill.addEventListener(MouseEvent.ROLL_OUT, this.onSkillRollOut);

                // Move it into position
                xx += iconWidth + xpadding;
            }

            // Side icons (Other people's builds)

            // Settings
            xpadding = 4;
            ypadding = 4;
            totalWidth = (iconMiniSize+xpadding) * (maxSkills+1) + 128/4.5 + xpadding;

            // Workout where to place them
            sx = maxStageWidth - totalWidth;
            sy = 64;
            xx = sx;
            yy = sy;

            // Grab total players
            var totalPlayers = globals.Players.GetMaxPlayers();

            var lastVisible = 0;

            // Loop over all 10 builds
            for(i=0; i<10; i++) {
                // Grab and validate the build
                var build = pickingData.builds[i];
                if(build) {
                    // Check if we should show these stats
                    var shouldDisplay = (globals.Players.GetPlayerHeroEntityIndex(i) != -1);

                    // If so, store this as the last visible
                    if(shouldDisplay) lastVisible = i;

                    // Ready state
                    skill = new MovieClip();
                    autoCleanupSpecial(skill, 'ready_'+i);
                    skill.x = xx;
                    skill.y = yy;
                    skill.visible = shouldDisplay && build.r;
                    Globals.instance.LoadImage('images/hud/tick.png', skill, false);
                    skill.scaleX = 0.5;
                    skill.scaleY = 0.5;

                    xx += iconMiniSize + xpadding;

                    // Create hero image thingo
                    var heroIcon = new HeroDisplayMini(build.h);
                    autoCleanupSpecial(heroIcon, 'hero_'+i);
                    heroIcon.x = xx;
                    heroIcon.y = yy;
                    heroIcon.visible = shouldDisplay;

                    xx += 128/4.5 + xpadding;

                    // Loop over all the skills in the build
                    for(j=0; j<maxSkills; j++) {
                        // Grab name of this skill
                        skillName = build.s[j];
                        if(!skillName) skillName = 'doom_bringer_empty1';

                        // Create a mini skill icon for it
                        skill = new SkillMini(skillName);
                        autoCleanupSpecial(skill, 'skill_'+i+'_'+j);
                        skill.x = xx;
                        skill.y = yy;
                        skill.visible = shouldDisplay;

                        // Allow dragging from this
                        dragMakeValidFrom(skill);

                        // Make it display info
                        skill.addEventListener(MouseEvent.ROLL_OVER, this.onSkillRollOver);
                        skill.addEventListener(MouseEvent.ROLL_OUT, this.onSkillRollOut);

                        xx += iconMiniSize + xpadding;
                    }
                }

                xx = sx;
                yy += iconMiniSize + ypadding;
            }

            // Add ready button
            var readyButton = new Button();
            readyButton.x = sx + (totalWidth-readyButton.width)/2;
            readyButton.y = sy + getContentHeight();
            readyButton.label = "#afs_toggle_ready";
            readyButton.addEventListener(MouseEvent.CLICK, this.readyPressed);
            autoCleanup(readyButton);
        }

        public function readyPressed() {
            gameAPI.SendServerCommand("afs_ready_pressed");
        }

        public function BuildVoteScreen(data) {
            // Create a new panel for the skills
            newPanel();

            // Setting for skill picking panel
            var padding:Number = 8;
            var xo = padding;
            var xx:Number = xo;
            var yy:Number = padding;

            var timeLeft = Math.floor(data.endTime - this.globals.Game.Time());

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
                    timeLeft = Math.floor(data.endTime - globals.Game.Time());

                    // Update timer, with a nice display
                    if(timeLeft > 0 && timeLeft != 1) {
                        txt.text = timeLeft+" "+Translate("#afs_seconds_remaining");
                    } else if(timeLeft == 1) {
                        txt.text = 1+Translate("#afs_second_remaining");
                    } else {
                        txt.text = "#afs_vote_waiting_to_end";
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
            for(var name:String in data.options) {
                var voteInfo = data.options[name];

                // Create vote panel
                var vote = new VoteButton(name, voteInfo.des, voteInfo.count);
                addPanelChild(vote);
                vote.x = xx;
                vote.y = yy;

                // Listen to button press
                vote.Button.addEventListener(MouseEvent.CLICK, this.votePressed);

                // Store this panel
                voteHolder[name] = vote;

                // Move the next panel down
                yy = yy + voteHeight + padding;
            }

            // Update the scrollbar
            updatePanel();
        }

        // Makes this movieclip draggable
        public function dragMakeValidFrom(mc) {
            mc.addEventListener(MouseEvent.MOUSE_DOWN, dragMousePressed);
            mc.addEventListener(MouseEvent.MOUSE_UP, dragMouseReleased);
            mc.addEventListener(MouseEvent.ROLL_OUT, dragFromRollOut);
        }
        // Makes this movieclip into a valid target
        public function dragMakeValidTarget(mc) {
            mc.addEventListener(MouseEvent.ROLL_OVER, dragTargetRollOver);
            mc.addEventListener(MouseEvent.ROLL_OUT, dragTargetRollOut);
        }
        public function dragListener(e:MouseEvent) {
            dragClip.x = mouseX;
            dragClip.y = mouseY;
        }
        public function dragTargetRollOver(e:MouseEvent) {
            dragTarget = e.target;
        }
        public function dragMouseUp(e:MouseEvent) {
            dragClickedClip = null;
            if(dragClip) {
                if(dragTarget) {
                    skillIntoSlot(dragClip.name, dragTarget.name);
                }

                // Remove drag object
                removeChild(dragClip);
                dragClip = null;

                // Remove move event
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragListener);
            }

            stage.removeEventListener(MouseEvent.MOUSE_UP, dragMouseUp)
        }
        public function dragMousePressed(e:MouseEvent) {
            dragClickedClip = e.currentTarget;
            dragTarget = null;
        }
        public function dragMouseReleased(e:MouseEvent) {
            dragClickedClip = null;
        }
        public function dragFromRollOut(e:MouseEvent) {
            // Check if this is the clip we tried to drag
            if(dragClickedClip == e.target) {
                dragClip = new MovieClip();
                dragClip.mouseEnabled = false;
                addChild(dragClip);

                // Make it look nice / give it a name
                dragClip.name = dragClickedClip.skillName;
                Globals.instance.LoadAbilityImage(dragClickedClip.skillName, dragClip);
                dragClip.scaleX = 0.5;
                dragClip.scaleY = 0.5;

                // Add listeners
                stage.addEventListener(MouseEvent.MOUSE_MOVE, dragListener);
                stage.addEventListener(MouseEvent.MOUSE_UP, dragMouseUp);

                // Stop it from procing again
                dragClickedClip = null;
            }
        }
        public function dragTargetRollOut(e:MouseEvent) {
            // Validate target
            if(e.target == dragTarget) {
                // Remove drag target
                dragTarget = null;
            }
        }

        // JSON decoder
        public static function decode( s:String, strict:Boolean = true ):* {
            return new JSONDecoder( s, strict ).getValue();
        }

        // JSON encoder
        public static function encode( o:Object ):String {
            return new JSONEncoder( o ).getString();
        }
    }
}
