-- Syntax copied mostly from frostivus example

-- Constants
MAX_PLAYERS = 10
STARTING_GOLD = 625

-- State control
STATE_INIT = 0
STATE_VOTING = 1
STATE_PICKING = 2
STATE_BANNING = 3
STATE_PLAYING = 4

-- Vote types
VOTE_SORT_SINGLE = 0    -- A person can vote for only one option
VOTE_SORT_MULTI = 1     -- A person votes yes or no for many options

-- Default settings for regular Dota
local minimapHeroScale = 600
local minimapCreepScale = 1

-- Reload support apparently
if FrotaGameMode == nil then
    FrotaGameMode = {}
    FrotaGameMode.szEntityClassName = "Frota"
    FrotaGameMode.szNativeClassName = "dota_base_game_mode"
    FrotaGameMode.__index = FrotaGameMode
end

function FrotaGameMode:new (o)
    o = o or {}
    setmetatable(o, self)
    return o
end

function FrotaGameMode:_SetInitialValues()
    -- Load ability List
    self:LoadAbilityList()

    -- Voting thinking
    self.thinkState = Dynamic_Wrap( FrotaGameMode, '_thinkState_Voting' )
    self._scriptBind:BeginThink( "FrotaThink", Dynamic_Wrap( FrotaGameMode, 'Think' ), 0.25 )

    -- Stores the current skill list for each hero
    self.currentSkillList = {}

    -- The state of the gane
    self.currentState = STATE_INIT;
    self.currentStateData = "";

    -- Store the default axe build for each player
    self.selectedBuilds = {}
    for i = 0, 9 do
        self.selectedBuilds[i] = {
            hero = 'npc_dota_hero_axe',
            skills = {
                [1] = 'axe_berserkers_call',
                [2] = 'axe_battle_hunger',
                [3] = 'axe_counter_helix',
                [4] = 'axe_culling_blade'
            }
        }
    end
end

function FrotaGameMode:InitGameMode()
    -- Register console commands
    self:RegisterCommands()

    -- Setup rules
    GameRules:SetHeroRespawnEnabled( false )
    GameRules:SetUseUniversalShopMode( true )
    GameRules:SetSameHeroSelectionEnabled(true)
    GameRules:SetHeroSelectionTime( 5.0 )
    GameRules:SetPreGameTime( 60.0 )
    GameRules:SetPostGameTime( 60.0 )
    GameRules:SetTreeRegrowTime( 60.0 )
    GameRules:SetHeroMinimapIconSize( 400 )
    GameRules:SetCreepMinimapIconScale( 0.7 )
    GameRules:SetRuneMinimapIconScale( 0.7 )

    -- Load initital Values
    self:_SetInitialValues()

    Convars:SetBool( "dota_suppress_invalid_orders", true )
end

function FrotaGameMode:RegisterCommands()
    -- When a user tries to put a skill into a slot
    Convars:RegisterCommand( "afs_skill", function(name, skillName, slotNumber)
        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            local hero = cmdPlayer:GetAssignedHero()
            if hero then
                self:SkillIntoSlot(hero, skillName, tonumber(slotNumber))
                return
            end
        end
    end, "Print a message to the server console", 0 )

    -- When a user tries to vote on something
    Convars:RegisterCommand( "afs_vote", function(name, vote, multi)
        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            local playerID = cmdPlayer:GetPlayerID()
            if playerID ~= nil and playerID ~= -1 then
                self:CastVote(playerID, vote, multi)
                return
            end
        end
    end, "User trying to vote", 0 )

    -- State handeling
    Convars:RegisterCommand( "afs_request_state", function(name, args)
        print("\nState Was Requested\n")

        -- Send out state info
        FireGameEvent("afs_initial_state", {
            nState = self.currentState,
            d = self.currentStateData
        })
    end, "Client requested the current state", 0 )

    -- Swap heroes
    Convars:RegisterCommand( "afs_swap_hero", function(name, msg)
        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            local playerID = cmdPlayer:GetPlayerID()
            if playerID ~= nil and playerID ~= -1 then
                cmdPlayer:ReplaceHeroWith('npc_dota_hero_bane', 0, 0)
                return
            end
        end
    end, "Swaps a given players hero to bane.", 0 )
end

function FrotaGameMode:LoadAbilityList()
    local abs = LoadKeyValues( "scripts/kv/abilities.kv" )
    self.heroList = LoadKeyValues( "scripts/npc/npc_heroes.txt" )
    --local englishPack = LoadKeyValues( "resource/dota_english.txt" )

    -- Table containing every skill
    self.vAbList = {}

    -- Build skill list
    for k,v in pairs(abs) do
        for kk, vv in pairs(v) do
            -- This comparison is really dodgy for some reason
            if tonumber(vv) == 1 then
                -- Attempt to find the owning hero of this ability
                local heroOwner = ""
                for heroName, values in pairs(self.heroList) do
                    if type(values) == "table" then
                        for i = 1, 16 do
                            if values["Ability"..i] == kk then
                                heroOwner = heroName
                                goto foundHeroName
                            end
                        end
                    end
                end

                ::foundHeroName::

                -- Store this skill
                table.insert(self.vAbList, {
                    name = kk,
                    sort = k,
                    hero = heroOwner
                })
            end
        end
    end

    --PrintTable(self.vAbList)
end

function FrotaGameMode:SkillIntoSlot(hero, skillName, skillSlot)
    -- Validate Data here (never trust client)

    -- Grab playerID
    local playerID = hero:GetPlayerID()
    if(playerID < 0 or playerID > 9) then
        return
    end

    -- Check if we've touched this hero before
    if not self.currentSkillList[hero] then
        -- Grab the name of this hero
        local heroClass = hero:GetUnitName()

        local skills = {}

        -- Build list of abilities
        for heroName, values in pairs(self.heroList) do
            if heroName == heroClass then
                for i = 1, 16 do
                    local ab = values["Ability"..i]
                    if ab then
                        table.insert(skills, ab)
                    end
                end
            end
        end

        -- Store it
        self.currentSkillList[hero] = skills
    end

    -- Remove all old skills
    for k,v in pairs(self.currentSkillList[hero]) do
        if hero:HasAbility(v) then
            hero:RemoveAbility(v)
        end
    end

    -- Update build
    self.selectedBuilds[playerID].skills[skillSlot] = skillName

    -- Change the skills on this hero
    self.currentSkillList[hero] = self.selectedBuilds[playerID].skills

    -- Re-give all abilities
    for k,v in ipairs(self.currentSkillList[hero]) do
        hero:AddAbility(v)
        print("Added: "..v)
    end

    -- Send out the updated builds
    FireGameEvent("afs_update_builds", {
        d = self:BuildBuildsData()
    })

    -- Update the state data
    self.currentStateData = self:BuildAbilityListData()
end

function FrotaGameMode:ChangeState(newState, newData)
    print("\nState Was Updated\n")

    -- Update local state
    self.currentState = newState;
    self.currentStateData = newData;

    -- Send out state info
    FireGameEvent("afs_update_state", {
        nState = self.currentState,
        d = self.currentStateData
    })
end

function FrotaGameMode:_InitCVars()
    if self.bHasSetCVars then
        return
    end
    self.bHasSetCVars = true
    Convars:SetBool( "dota_winter_ambientfx", true )
end

function FrotaGameMode:_RestartGame()
    -- Clean up everything on the ground; gold, tombstones, items, everything.
    while GameRules:NumDroppedItems() > 0 do
        local item = GameRules:GetDroppedItem(0)
        UTIL_RemoveImmediate( item )
    end

    -- Reset Players
    for playerID = 0, MAX_PLAYERS-1 do
        Players:SetGold( playerID, STARTING_GOLD, false )
        Players:SetGold( playerID, 0, true )
        Players:SetBuybackCooldownTime( playerID, 0 )
        Players:SetBuybackGoldLimitTime( playerID, 0 )
        Players:ResetBuybackCostTime( playerID )
    end

    -- Set initial Values again
    self:_SetInitialValues()


end

function FrotaGameMode:Think()
    -- If the game's over, it's over.
    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
        self._scriptBind:EndThink( "GameThink" )
        return
    end

    -- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
    local now = GameRules:GetGameTime()
    if self.t0 == nil then
        self.t0 = now
    end
    local dt = now - self.t0
    self.t0 = now

    self:thinkState( dt )
end

function FrotaGameMode:CreateVote(args)
    -- Create new vote
    self.currentVote = {
        options = {},
        endTime = Time()+args.duration,
        sort = args.sort,
        duration = args.duration,
        onFinish = args.onFinish
    }

    -- Store vote choices, register handles
    for k, v in pairs(args.options) do
        self.currentVote.options[k] = {
            votes = {},
            des = v,
            count = 0
        }
    end

    -- Build data, and send
    self:ChangeState(STATE_VOTING, self:BuildVoteData())
end

function FrotaGameMode:CastVote(playerID, vote, mutli)
    -- Make sure there is a vote active
    if (not self.currentVote) or (self.currentState ~= STATE_VOTING) then return end

    -- Validate vote option
    local usersChoice = self.currentVote.options[vote]
    if not usersChoice then return end

    if self.currentVote.sort == VOTE_SORT_SINGLE then
        -- Single vote, remove their old vote
        for k, v in pairs(self.currentVote.options) do
            if v.votes[playerID] then
                v.votes[playerID] = false
                v.count = v.count - 1
            end
        end

        -- Add their new vote
        usersChoice.votes[playerID] = true
        usersChoice.count = usersChoice.count + 1
    else
        -- Adjust this user's vote
        if mutli then
            if not usersChoice.votes[playerID] then
                usersChoice.votes[playerID] = true
                usersChoice.count = usersChoice.count + 1
            end
        else
            if usersChoice.votes[playerID] then
                usersChoice.votes[playerID] = false
                usersChoice.count = usersChoice.count - 1
            end
        end
    end

    -- Update data on this vote
    self.currentStateData = self:BuildVoteData()

    -- Send the updated columns to everyone
    self:SendVoteStatus()
end

function FrotaGameMode:BuildVoteData()
    if not self.currentVote then return "" end

    local str = self.currentVote.endTime.."::"..self.currentVote.sort.."::"..self.currentVote.duration.."||"

    for k,v in pairs(self.currentVote.options) do
        str = str..k.."::"..v.des.."::"..v.count..":::"
    end

    -- Remove ending :::
    str = string.sub(str, 1, -4)

    return str
end

function FrotaGameMode:SendVoteStatus()
    local cv = self.currentVote
    if not cv then return end

    local str = ""

    if cv.sort == VOTE_SORT_SINGLE then
        -- Workout how many people voted
        local totalVotes = 0
        for k,v in pairs(cv.options) do
            totalVotes = totalVotes + v.count
        end

        -- Fix divide by 0 error
        if totalVotes == 0 then
            totalVotes = 1
        end

        -- Print percentages
        for k,v in pairs(cv.options) do
            str = str..k.."::"..math.floor(v.count/totalVotes*100).."%:::"
        end
    else
        -- This needs fixing
        for k,v in pairs(cv.options) do
            str = str..k.."::"..v.count.."%:::"
        end
    end

    -- Remove ending :::
    str = string.sub(str, 1, -4)

    FireGameEvent("afs_vote_status", {
        d = str
    })
end

local startedInitialVote = false
function FrotaGameMode:_thinkState_Voting(dt)
    if GameRules:State_Get() < DOTA_GAMERULES_STATE_PRE_GAME then
        -- Waiting on the game to start...
        return
    end

    -- Check if there is a vote active
    local cv = self.currentVote
    if cv then
        -- Check if the vote should finish
        if Time() > cv.endTime then
            -- Table to store which option(s) won
            local winners = {}

            if cv.sort == VOTE_SORT_SINGLE then
                local highestVotes = 0

                for k,v in pairs(cv.options) do
                    if v.count > highestVotes then
                        -- New leader, reset list of winners
                        highestVotes = v.count
                        winners = {k}
                    elseif v.count == highestVotes then
                        -- A draw, add to list of winners
                        table.insert(winners, k)
                    end
                end
            else

            end

            -- Remove the active vote
            self.currentVote = nil

            -- Call the callback for vote ending
            cv.onFinish(winners)
        end
    end

    -- Change to picking phase if it isn't already active
    if (not startedInitialVote) and self.currentState ~= STATE_VOTING then
        -- This only ever runs once
        startedInitialVote = true

        -- Begin gamemode voting
        self:VoteForGamemode()
    end
end

function FrotaGameMode:VoteForGamemode()
    -- Create a vote for the game mode
    self:CreateVote({
        sort = VOTE_SORT_SINGLE,
        options = {
            ["Legends of Dota"] = "Pick your skills / hero",
            ["Random OMG x5"] = "Choose between 5 random builds"
        },
        duration = 30,
        onFinish = function(winners)
            self:CreateVote({
                sort = VOTE_SORT_SINGLE,
                options = {
                    ["King of the Shop"] = "Defend the shop, yo"
                },
                duration = 5,
                onFinish = function(winners)
                    print("Made it!")

                    -- Load up LoD
                    self:ChangeState(STATE_PICKING, self:BuildAbilityListData())
                end
            })
        end
    })
end

function FrotaGameMode:BuildBuildsData()
    -- Build list of builds
    local sBuildList = '';
    for i = 0,9 do
        local v = self.selectedBuilds[i]

        local sBuild = v.hero

        for kk, vv in pairs(v.skills) do
            sBuild = sBuild..'::'..vv
        end

        sBuildList = sBuildList..sBuild..'||'
    end

    -- Remove the last ||
    sBuildList = string.sub(sBuildList, 1, -3)

    return sBuildList
end

function FrotaGameMode:BuildAbilityListData()
    local sSkillList = ""
    for k,v in pairs(self.vAbList) do
        local sSkill = v.name.."::"..v.sort.."::"..v.hero

        sSkillList = sSkillList..sSkill.."||"
    end

    -- Remove the last ||
    sSkillList = string.sub(sSkillList, 1, -3)

    -- Return the data
    return sSkillList..'|||'..self:BuildBuildsData()..'|||'..'Bans will go here';
end

EntityFramework:RegisterScriptClass( FrotaGameMode )
