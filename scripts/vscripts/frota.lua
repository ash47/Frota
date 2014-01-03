-- Syntax copied mostly from frostivus example

-- Constants
MAX_PLAYERS = 10
STARTING_GOLD = 625

-- State control
STATE_INIT = 0      -- Waiting for players
STATE_VOTING = 1    -- Voting on what to play
STATE_PICKING = 2   -- Players are selecting builds / skills / heroes
STATE_BANNING = 3   -- Players are banning stuff
STATE_PLAYING = 4   -- Players are playing
STATE_FINISHED = 5  -- A round is finished, display stats + Vote to restart?

-- Gamemode Sorts
GAMEMODE_PICK = 1   -- A gamemode which only has a picking stage
GAMEMODE_PLAY = 2   -- A gamemode which only has a playing park
GAMEMODE_BOTH = 3   -- A gamemode which needs both to work
GAMEMODE_ADDON = 4  -- An addon such as Lucky Items or CSP

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
    self:ChangeStateData({});

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
            },
            ready = false
        }
    end
end

function FrotaGameMode:InitGameMode()
    -- Register console commands
    self:RegisterCommands()

    -- Setup rules
    GameRules:SetHeroRespawnEnabled( false )
    GameRules:SetUseUniversalShopMode( true )
    GameRules:SetSameHeroSelectionEnabled( true )
    GameRules:SetHeroSelectionTime( 0.0 )
    GameRules:SetPreGameTime( 60.0 )
    GameRules:SetPostGameTime( 60.0 )
    GameRules:SetTreeRegrowTime( 60.0 )
    GameRules:SetHeroMinimapIconSize( 400 )
    GameRules:SetCreepMinimapIconScale( 0.7 )
    GameRules:SetRuneMinimapIconScale( 0.7 )

    -- Hooks
    ListenToGameEvent('player_connect_full', function(self, keys)
        -- Grab the entity index of this player
        local entIndex = keys.index+1
        local ply = EntIndexToHScript(entIndex)

        -- Find the team with the least players
        local teamSize = {
            [DOTA_TEAM_GOODGUYS] = 0,
            [DOTA_TEAM_BADGUYS] = 0
        }

        for i=0, 9 do
            if Players:IsValidPlayer(i) then
                print('valid player '..i)
                local ply = Players:GetPlayer(i)
                if ply then
                    -- Grab the players team
                    local team = ply:GetTeam()

                    -- Increase the number of players on this players team
                    teamSize[team] = (teamSize[team] or 0) + 1
                end
            end
        end

        if teamSize[DOTA_TEAM_GOODGUYS] > teamSize[DOTA_TEAM_BADGUYS] then
            ply:SetTeam(DOTA_TEAM_BADGUYS)
        else
            ply:SetTeam(DOTA_TEAM_GOODGUYS)
        end
    end, self)

    -- Load initital Values
    self:_SetInitialValues()

    Convars:SetBool('dota_suppress_invalid_orders', true)
end

function FrotaGameMode:RegisterCommands()
    -- When a user tries to put a skill into a slot
    Convars:RegisterCommand( "afs_skill", function(name, skillName, slotNumber)
        -- Verify we are in picking mode


        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            local hero = cmdPlayer:GetAssignedHero()
            if hero then
                self:SkillIntoSlot(hero, skillName, tonumber(slotNumber))
                return
            end
        end
    end, "A user tried to put a skill into a slot", 0 )

    -- When a user toggles ready state
    Convars:RegisterCommand( "afs_ready_pressed", function(name, skillName, slotNumber)
        -- Verify we are in a state that needs ready


        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            local playerID = cmdPlayer:GetPlayerID()
            if playerID >= 0 and playerID <= 9 then
                self:ToggleReadyState(playerID)
                return
            end
        end
    end, "Used tried to toggle their ready state", 0 )

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
        -- Send out state info
        FireGameEvent("afs_initial_state", {
            nState = self.currentState,
            d = self:GetStateData()
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

function FrotaGameMode:FindHeroOwner(skillName)
    local heroOwner = ""
    for heroName, values in pairs(self.heroList) do
        if type(values) == "table" then
            for i = 1, 16 do
                if values["Ability"..i] == skillName then
                    heroOwner = heroName
                    goto foundHeroName
                end
            end
        end
    end

    ::foundHeroName::
    return heroOwner
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

                -- Check if the owner was found
                if heroOwner ~= '' then
                    --print('precache: '..heroOwner)
                    --local heroOwner = FindHeroOwner()
                    --local unit = CreateUnitByName(heroOwner, Vec3(0,0,0), true, nil, nil, DOTA_TEAM_BADGUYS)
                    --UTIL_RemoveImmediate(unit)
                end

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

    -- Preache the new skill
    self:PrecacheSkill(skillName)

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
    end

    -- Send out the updated builds
    FireGameEvent("afs_update_builds", {
        d = JSON:encode(self:BuildBuildsData())
    })

    -- Update the state data
    self:ChangeStateData(self:BuildAbilityListData())
end

function FrotaGameMode:ToggleReadyState(playerID)
    -- Validate playerID
    if(playerID < 0 or playerID > 9) then
        return
    end

    -- Toggle ready state
    self.selectedBuilds[playerID].ready = not self.selectedBuilds[playerID].ready

    -- Check if everyone is ready
    local allReady = true
    for i=0,9 do
        if Players:IsValidPlayer(i) and (not self.selectedBuilds[i].ready) then
            allReady = false
            break
        end
    end

    if allReady then
        -- Change to game time
        print('GAME START NOW!')



        -- Begin gameplay
        self:ChangeState(STATE_PLAYING, '')
    else
        -- Send out the updated data
        FireGameEvent("afs_update_builds", {
            d = self:BuildBuildsData()
        })

        -- Update the state data
        self:ChangeStateData(self:BuildAbilityListData())
    end
end

function FrotaGameMode:ChangeStateData(data)
    self.currentStateData = JSON:encode(data)
end

function FrotaGameMode:GetStateData()
    return self.currentStateData
end

function FrotaGameMode:ChangeState(newState, newData)
    -- Update local state
    self.currentState = newState;
    self:ChangeStateData(newData);

    -- Send out state info
    FireGameEvent("afs_update_state", {
        nState = self.currentState,
        d = self:GetStateData()
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

    -- Hero Selection Screen Bypass
    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_HERO_SELECTION then
        for i=0, 9 do
            if Players:IsValidPlayer(i) and not Players:GetSelectedHeroEntity(i) then
                -- Grab the player and create them a default hero
                local ply = Players:GetPlayer(i)
                CreateHeroForPlayer('npc_dota_hero_axe', ply)

                -- Check if we are in a game
                if self.currentState == STATE_PLAYING then
                    -- Check if we need to assign a hero
                    local assignHero = self:GetAssignHero()
                    if assignHero then
                        assignHero(ply)
                    end
                end
            end
        end
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

-- Finds a function that assigns heroes
function FrotaGameMode:GetAssignHero()
    return (self.pickMode and self.pickMode.assignHero) or (self.playMode and self.playMode.assignHero)
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
            if v.votes[playerID] == 1 then
                v.votes[playerID] = 0
                v.count = v.count - 1
            end
        end

        -- Add their new vote
        usersChoice.votes[playerID] = 1
        usersChoice.count = usersChoice.count + 1
    else
        -- Adjust this user's vote
        if mutli then
            if usersChoice.votes[playerID] == 0 then
                usersChoice.votes[playerID] = 1
                usersChoice.count = usersChoice.count + 1
            end
        else
            if usersChoice.votes[playerID] == 1 then
                usersChoice.votes[playerID] = 0
                usersChoice.count = usersChoice.count - 1
            end
        end
    end

    -- Update data on this vote
    self:ChangeStateData(self:BuildVoteData())

    -- Send the updated columns to everyone
    self:SendVoteStatus()
end

function FrotaGameMode:BuildVoteData()
    local data = {
        endTime = self.currentVote.endTime,
        sort = self.currentVote.sort,
        duration = self.currentVote.duration,
        options = self.currentVote.options
    }

    return data
end

--[[function FrotaGameMode:BuildVoteData()
    if not self.currentVote then return "" end

    local str = self.currentVote.endTime.."::"..self.currentVote.sort.."::"..self.currentVote.duration.."||"

    for k,v in pairs(self.currentVote.options) do
        str = str..k.."::"..v.des.."::"..v.count..":::"
    end

    -- Remove ending :::
    str = string.sub(str, 1, -4)

    return str
end]]

function FrotaGameMode:SendVoteStatus()
    local cv = self.currentVote
    if not cv then return end

    FireGameEvent("afs_vote_status", {
        d = JSON:encode(cv.options)
    })
end
--[[function FrotaGameMode:SendVoteStatus()
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
end]]

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
    -- Grab all the gamemodes the require picking
    local modes = GetPickingGamemodes()

    local options = {}
    for k, v in pairs(modes) do
        options['#afs_name_'..v] = '#afs_des_'..v
    end

    -- Create a vote for the game mode
    self:CreateVote({
        sort = VOTE_SORT_SINGLE,
        options = options,
        duration = 30,
        onFinish = function(winners)
            -- Grab the winning option, we need to remove the #afs_name_ from the start
            local mode = string.sub(winners[math.random(1, #winners)], 11)

            print(mode)

            -- Grab the mode
            local gamemode = GetGamemode(mode)

            -- Check if it was a picking gamemode
            if gamemode.sort == GAMEMODE_PICK then
                -- We need a gameplay gamemode now

                -- Instead, just change to LoD
                self:ChangeState(STATE_PICKING, self:BuildAbilityListData())
            else
                -- We must have gotten someone we can just run
                self:LoadGamemode(gamemode)
            end



            --[[self:CreateVote({
                sort = VOTE_SORT_SINGLE,
                options = {
                    ["King of the Shop"] = "Defend the shop, yo"
                },
                duration = 5,
                onFinish = function(winners)
                    -- Load up LoD
                    self:ChangeState(STATE_PICKING, self:BuildAbilityListData())
                end
            })]]
        end
    })
end

function FrotaGameMode:LoadGamemode(pickMode, playMode)
    -- Store the modes
    self.pickMode = pickMode
    self.playMode = playMode

    -- Depending on the type, it will be loaded differently
    if pickMode.sort == GAMEMODE_PICK then
        -- Load picking stuff

    else
        -- Load the game

        -- Attempt to assign heroes
        local assignHero = pickMode.assignHero
        if assignHero then
            -- Loop over every player
            for i=0, 9 do
                -- Check if they are in
                if Players:IsValidPlayer(i) then
                    -- Assign them a hero
                    assignHero(Players:GetPlayer(i))
                end
            end
        end

        -- Fire game start event
        self:ChangeState(STATE_PLAYING, '')
    end
end

function FrotaGameMode:BuildBuildsData()
    local data = {}

    -- Build list of builds
    for i = 0,9 do
        local v = self.selectedBuilds[i]

        -- Convert ready bool into a number
        local ready = 0
        if v.ready then
            ready = 1
        end

        data[i] = {
            r = ready,
            h = v.hero,
            s = {}
        }

        -- Add hero and ready state
        local sBuild = v.hero..'::'..ready

        -- Add all skills
        local j = 0
        for kk, vv in pairs(v.skills) do
            data[i].s[j] = vv
            j = j + 1
        end
    end

    return data
end

function FrotaGameMode:BuildAbilityListData()
    local data = {
        s = {},
        b = self:BuildBuildsData()
    }

    for k,v in pairs(self.vAbList) do
        data.s[v.name] = {
            c = v.sort,
            h = v.hero
        }
    end

    -- Return the data
    return data;
end

function FrotaGameMode:PrecacheSkill(skillName)
    --[[PrecacheEntityFromTable({
        classname = skillName
    })]]

    local heroOwner = self:FindHeroOwner(skillName)
    --local unit = CreateUnitByName(heroOwner, Vec3(0,0,0), true, nil, nil, DOTA_TEAM_BADGUYS)
    --UTIL_RemoveImmediate(unit)
    --print("created a "..heroOwner)
    if heroOwner then
        PrecacheUnit(heroOwner)
        print('precached '..skillName)
    else
        print('FAILED TO PRECACHE '..skillName)
    end
end

EntityFramework:RegisterScriptClass( FrotaGameMode )
