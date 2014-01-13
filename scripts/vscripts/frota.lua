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
VOTE_SORT_OPTIONS = 1   -- A person votes yes or no for many options

VOTE_SORT_YESNO = 11    -- A yes/no option
VOTE_SORT_RANGE = 12    -- A range option

-- Amount of time to pick skills
PICKING_TIME = 60 * 2   -- 2 minutes tops

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

function FrotaGameMode:InitGameMode()
    -- Load version
    self.frotaVersion = LoadKeyValues("scripts/version.txt").version

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
    ListenToGameEvent('entity_killed', Dynamic_Wrap(FrotaGameMode, 'OnEntityKilled'), self)
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(FrotaGameMode, 'AutoAssignPlayer'), self)
    ListenToGameEvent('player_disconnect', Dynamic_Wrap(FrotaGameMode, 'CleanupPlayer'), self)

    -- Mod Events
    self:ListenToEvent('dota_player_used_ability')
    self:ListenToEvent('dota_player_learned_ability')
    self:ListenToEvent('dota_player_gained_level')
    self:ListenToEvent('dota_item_purchased')
    self:ListenToEvent('dota_item_used')
    self:ListenToEvent('last_hit')
    self:ListenToEvent('dota_item_picked_up')
    self:ListenToEvent('dota_super_creep')
    self:ListenToEvent('dota_glyph_used')
    self:ListenToEvent('dota_courier_respawned')
    self:ListenToEvent('dota_courier_lost')

    -- userID map
    self.vUserIDMap = {}

    -- Active Hero Map
    self.vActiveHeroMap = {}

    -- Load initital Values
    self:_SetInitialValues()

    Convars:SetBool('dota_suppress_invalid_orders', true)

    -- Start thinkers
    self._scriptBind:BeginThink('FrotaThink', Dynamic_Wrap(FrotaGameMode, 'Think'), 0.1)

    -- Precache everything
    print('\n\nprecaching:')
    PrecacheUnit('npc_precache_everything')
    print('done precaching!\n\n')
end

function FrotaGameMode:_SetInitialValues()
    -- Change random seed
    local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
    math.randomseed(tonumber(timeTxt))

    -- Load ability List
    self:LoadAbilityList()

    -- Timers
    self.timers = {}

    -- Voting thinking
    self.startedInitialVote = false
    self.thinkState = Dynamic_Wrap( FrotaGameMode, '_thinkState_Voting' )

    -- Stores the current skill list for each hero
    self.currentSkillList = {}

    -- Reset Builds
    self:ResetBuilds()

    -- Options
    self.gamemodeOptions = {}

    -- Scores
    self.scoreDire = 0
    self.scoreRadiant = 0

    -- The state of the gane
    self.currentState = STATE_INIT;
    self:ChangeStateData({});
end

function FrotaGameMode:RegisterCommands()
    Convars:RegisterCommand('testa', function(name)
        -- Check if the server ran it
        if not Convars:GetCommandClient() then
            FireGameEvent("afs_testa", {})
        end
    end, '', 0)

    Convars:RegisterCommand('testb', function(name)
        -- Check if the server ran it
        if not Convars:GetCommandClient() then
            FireGameEvent("afs_testb", {})
        end
    end, '', 0)

    -- When a user tries to put a skill into a slot
    --[[Convars:RegisterCommand('teamNumber', function(name, teamNumber)
        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            local hero = cmdPlayer:GetAssignedHero()
            if hero then
                hero:__KeyValueFromInt('teamnumber', tonumber(teamNumber))
                return
            end
        end
    end, 'A user tried to put a skill into a slot', 0)]]

    -- When a user tries to put a skill into a slot
    Convars:RegisterCommand('afs_skill', function(name, skillName, slotNumber)
        -- Verify we are in picking mode
        if self.currentState ~= STATE_PICKING then return end
        if not self.pickMode.pickSkills then return end

        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            local hero = cmdPlayer:GetAssignedHero()
            if hero then
                self:SkillIntoSlot(hero, skillName, tonumber(slotNumber), true)
                return
            end
        end
    end, 'A user tried to put a skill into a slot', 0)

    -- End Gamemode
    Convars:RegisterCommand('endgamemode', function(name, skillName, slotNumber)
        -- Check if the server ran it
        if not Convars:GetCommandClient() then
            -- End the current gamemode
            self:EndGamemode()
        end
    end, 'Ends the current game.', 0)

    -- Fill server with fake clients
    Convars:RegisterCommand('fake', function(name, skillName, slotNumber)
        -- Check if the server ran it
        if not Convars:GetCommandClient() then
            -- Create fake players
            SendToServerConsole('dota_create_fake_clients')

            -- Assign the fakers
            self:CreateTimer('assign_fakes', {
                endTime = Time(),
                callback = function(frota, args)
                    for i=0, 9 do
                        local ply = Players:GetPlayer(i)
                        if Players:IsFakeClient(i) then
                            local ply = Players:GetPlayer(i)

                            self:AutoAssignPlayer({
                                userid = -(i+1),
                                index = ply:entindex()-1
                            })
                        end
                    end
                end
            })
        end
    end, 'Connects and assigns fake players.', 0)

    -- When a user tries to change heroes
    Convars:RegisterCommand('afs_hero', function(name, heroName)
        -- Verify we are in picking mode
        if self.currentState ~= STATE_PICKING then return end
        if not self.pickMode.pickHero then return end

        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            self:SelectHero(cmdPlayer, heroName, true)
            return
        end
    end, 'A user tried to change heroes', 0 )

    -- When a user toggles ready state
    Convars:RegisterCommand('afs_ready_pressed', function(name, skillName, slotNumber)
        -- Verify we are in a state that needs ready
        if self.currentState ~= STATE_PICKING then return end

        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            local playerID = cmdPlayer:GetPlayerID()
            if self:IsValidPlayerID(playerID) then
                self:ToggleReadyState(playerID)
                return
            end
        end
    end, 'Used tried to toggle their ready state', 0 )

    -- When a user tries to vote on something
    Convars:RegisterCommand('afs_vote', function(name, vote, multi)
        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            local playerID = cmdPlayer:GetPlayerID()
            if playerID ~= nil and playerID ~= -1 then
                self:CastVote(playerID, vote, multi)
                return
            end
        end
    end, 'User trying to vote', 0 )

    -- State handeling
    Convars:RegisterCommand('afs_request_state', function(name, version)
        -- Make sure a version was parsed
        version = version or 'Unknown'

        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            local playerID = cmdPlayer:GetPlayerID()
            if playerID ~= nil and playerID ~= -1 then
                -- Make sure we have a request table
                self.stateRequestData = self.stateRequestData or {}

                -- Check if we recently fired this
                if (self.stateRequestData['all'] or Time()) > Time() then return end
                self.stateRequestData['all'] = Time() + 2

                -- Check if we recently fired this
                if (self.stateRequestData[playerID] or Time()) > Time() then return end
                self.stateRequestData[playerID] = Time() + 5

                local data = {}

                self:LoopOverPlayers(function(ply, playerID)
                    local steamID = Players:GetSteamAccountID(playerID)

                    if steamID > 0 then
                        data[playerID] = steamID
                    end
                end)

                -- Fire steamids
                FireGameEvent('afs_steam_ids', {
                    d = JSON:encode(data)
                })

                -- Send out state info
                FireGameEvent('afs_initial_state', {
                    nState = self.currentState,
                    d = self:GetStateData()
                })

                -- Validate version
                if version ~= self.frotaVersion and (Time() > self.stateRequestData['v'..playerID] or 0) then
                    self.stateRequestData[v..playerID] = Time() + 60
                    Say(cmdPlayer, 'I have frota version '..version..' and the server has version '..self.frotaVersion, false)
                end
            end
        end
    end, 'Client requested the current state', 0)
end

-- Loops over all players, return true to stop the loop
function FrotaGameMode:LoopOverPlayers(callback)
    for k, v in pairs(self.vUserIDMap) do
        -- Validate the player
        if IsValidEntity(v) then
            -- Run the callback
            if callback(v, v:GetPlayerID()) then
                break
            end
        end
    end
end

function FrotaGameMode:IsValidPlayerID(checkPlayerID)
    local isValid = false
    self:LoopOverPlayers(function(ply, playerID)
        if playerID == checkPlayerID then
            isValid = true
            return true
        end
    end)

    return isValid
end

function FrotaGameMode:GetPlayerList()
    local plyList = {}

    self:LoopOverPlayers(function(ply, playerID)
        table.insert(plyList, ply)
    end)

    return plyList
end

function FrotaGameMode:ShuffleTeams()
    local teamID = DOTA_GC_TEAM_GOOD_GUYS

    -- Shuffle
    self:LoopOverPlayers(function(ply, playerID)
        ply:__KeyValueFromInt('teamnumber', teamID)

        if teamID == DOTA_GC_TEAM_GOOD_GUYS then
            teamID = DOTA_GC_TEAM_BAD_GUYS
        else
            teamID = DOTA_GC_TEAM_GOOD_GUYS
        end
    end)
end

function FrotaGameMode:GetRandomPlayer()
    local plyList = self:GetPlayerList()

    if #plyList == 0 then
        return nil
    else
        return plyList[math.random(1, #plyList)]
    end
end

function FrotaGameMode:ResetBuilds()
    -- Store the default axe build for each player
    self.selectedBuilds = {}

    self:LoopOverPlayers(function(ply, playerID)
        self.selectedBuilds[playerID] = self:GetDefaultBuild()
    end)
end

function FrotaGameMode:GetDefaultBuild()
    return {
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

function FrotaGameMode:CreateTimer(name, args)
    --[[
        args: {
            endTime = Time you want this timer to end: Time() + 30 (for 30 seconds from now),
            callback = function(frota, args) to run when this timer expires,
            text = text to display to clients,
            send = set this to true if you want clients to get this
        }

        If you want your timer to loop, simply return the time of the next callback inside of your callback, for example:

        callback = function()
            return Time() + 30 -- Will fire again in 30 seconds
        end
    ]]

    if not args.endTime or not args.callback then
        print("Invalid timer created: "..name)
        return
    end

    -- Store the timer
    self.timers[name] = args

    -- Update the timer
    self:UpdateTimerData()
end

function FrotaGameMode:RemoveTimer(name)
    -- Remove this timer
    self.timers[name] = nil

    -- Update the timers
    self:UpdateTimerData()
end

-- Auto assigns a player when they connect
function FrotaGameMode:AutoAssignPlayer(keys)
    -- Grab the entity index of this player
    local entIndex = keys.index+1
    local ply = EntIndexToHScript(entIndex)

    -- Find the team with the least players
    local teamSize = {
        [DOTA_TEAM_GOODGUYS] = 0,
        [DOTA_TEAM_BADGUYS] = 0
    }

    self:LoopOverPlayers(function(ply, playerID)
        if Players:GetPlayer(playerID) then
            local ply = Players:GetPlayer(playerID)
            if ply then
                -- Grab the players team
                local team = ply:GetTeam()

                -- Increase the number of players on this players team
                teamSize[team] = (teamSize[team] or 0) + 1
            end
        end
    end)

    if teamSize[DOTA_TEAM_GOODGUYS] > teamSize[DOTA_TEAM_BADGUYS] then
        ply:SetTeam(DOTA_TEAM_BADGUYS)
        ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_BADGUYS)
    else
        ply:SetTeam(DOTA_TEAM_GOODGUYS)
        ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_GOODGUYS)
    end

    --ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_BADGUYS)

    --for i=0,4 do
    --    Players:UpdateTeamSlot(ply:GetPlayerID(), i)
    --end

    local playerID = ply:GetPlayerID()
    local hero = self:GetActiveHero(playerID)
    if IsValidEntity(hero) then
        hero:Remove()
    end

    -- Store into our map
    self.vUserIDMap[keys.userid] = ply

    self.selectedBuilds[playerID] = self:GetDefaultBuild()

    -- Autoassign player
    self:CreateTimer('assign_player_'..entIndex, {
        endTime = Time(),
        callback = function(frota, args)
            frota:SetActiveHero(CreateHeroForPlayer('npc_dota_hero_axe', ply))

            -- Check if we are in a game
            if self.currentState == STATE_PLAYING then
                -- Check if we need to assign a hero
                if IsValidEntity(self:GetActiveHero(playerID)) then
                    self:FireEvent('assignHero', ply)
                    self:FireEvent('onHeroSpawned', self:GetActiveHero(playerID))
                end
            end

            -- Fire new player event
            self:FireEvent('NewPlayer', ply)
        end
    })
end

function FrotaGameMode:SetActiveHero(hero)
    self.vActiveHeroMap[hero:GetPlayerID()] = hero
end

function FrotaGameMode:GetActiveHero(playerID)
    return self.vActiveHeroMap[playerID]
end

-- Cleanup a player when they leave
function FrotaGameMode:CleanupPlayer(keys)
    -- Grab and validate the leaver
    local leavingPly = self.vUserIDMap[keys.userid];
    if not leavingPly then return end

    -- Fire event
    self:FireEvent('CleanupPlayer', leavingPly)

    -- Remove all Heroes owned by this player
    for k,v in pairs(Entities:FindAllByClassname('npc_dota_hero_*')) do
        if v:IsRealHero() then
            -- Grab the owning player
            local ply = Players:GetPlayer(v:GetPlayerID())

            -- Check if this is our leaver
            if ply and ply == leavingPly then
                -- Remove this hero
                v:Remove()
            end
        end
    end

    self:CreateTimer('cleanup_player_'..keys.userid, {
        endTime = Time() + 1,
        callback = function(frota, args)
            local foundSomeone = false

            -- Check if there are any players connected
            self:LoopOverPlayers(function(ply, playerID)
                foundSomeone = true
            end)

            if foundSomeone then
                return
            end

            -- No players are in, reset to initial vote
            self:_SetInitialValues()
        end
    })
end

function FrotaGameMode:ListenToEvent(eventName)
    ListenToGameEvent(eventName, Dynamic_Wrap(FrotaGameMode, 'AutoFireEvent'), {
        self = self,
        ev = eventName
    })
end

function FrotaGameMode:AutoFireEvent(keys)
    self.self:FireEvent(self.ev, keys)
end

function FrotaGameMode:OnEntityKilled(keys)
    -- Fire entity killed event
    self:FireEvent('entity_killed', keys)

    -- Proceed to do stuff
    local killedUnit = EntIndexToHScript( keys.entindex_killed )
    local killerEntity = nil

    if keys.entindex_attacker ~= nil then
        killerEntity = EntIndexToHScript( keys.entindex_attacker )
    end

    if killedUnit and killedUnit:IsRealHero() then
        -- Make sure we are playing
        if self.currentState ~= STATE_PLAYING then return end

        -- Only respawn if delay > 0
        if (self.gamemodeOptions.respawnDelay or 0) > 0 then
            -- Respawn the dead guy after a delay
            self:CreateTimer('respawn_hero_'..killedUnit:GetPlayerID(), {
                endTime = Time() + (self.gamemodeOptions.respawnDelay),
                callback = function(frota, args)
                    -- Make sure we are still playing
                    if frota.currentState == STATE_PLAYING then
                        -- Validate the unit
                        if killedUnit and IsValidEntity(killedUnit) then
                            -- Respawn the dead guy
                            killedUnit:RespawnHero(false, false, false)
                        end
                    end
                end
            })
        end

        -- Fire onHeroKilled event
        self:FireEvent('onHeroKilled', killedUnit, killerEntity)

        -- Check if point score
        if not self.gamemodeOptions.killsScore then return end

        -- Add points
        local team = killedUnit:GetTeam()
        if team == DOTA_TEAM_GOODGUYS then
            -- Add to the points
            self.scoreDire = self.scoreDire + 1
        else
            -- Add to the points
            self.scoreRadiant = self.scoreRadiant + 1
        end

        -- Update the scores
        self:UpdateScoreData()
    end
end

function FrotaGameMode:FindHeroOwner(skillName)
    local heroOwner = ""
    for heroName, values in pairs(self.heroListKV) do
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
    self.heroListKV = LoadKeyValues( "scripts/npc/npc_heroes.txt" )
    --local englishPack = LoadKeyValues( "resource/dota_english.txt" )

    -- Build list of heroes
    self.heroList = {}
    self.heroListEnabled = {}
    for heroName, values in pairs(self.heroListKV) do
        -- Validate hero name
        if heroName ~= 'Version' and heroName ~= 'npc_dota_hero_base' and heroName ~= 'npc_dota_hero_abyssal_underlord' then
            -- Make sure the hero is enabled
            if values.Enabled == 1 then
                -- Store this unit
                table.insert(self.heroList, heroName)
                self.heroListEnabled[heroName] = 1
            end
        end
    end

    -- Table containing every skill
    self.vAbList = {}
    self.vAbListSort = {}

    -- Build skill list
    for k,v in pairs(abs) do
        for kk, vv in pairs(v) do
            -- This comparison is really dodgy for some reason
            if tonumber(vv) == 1 then
                -- Attempt to find the owning hero of this ability
                local heroOwner = self:FindHeroOwner(kk)

                -- Store this skill
                table.insert(self.vAbList, {
                    name = kk,
                    sort = k,
                    hero = heroOwner
                })

                -- Store into the sort container
                if not self.vAbListSort[k] then
                    self.vAbListSort[k] = {}
                end

                -- Store the sort reference
                table.insert(self.vAbListSort[k], kk)
            end
        end
    end
end

function FrotaGameMode:GetRandomAbility(sort)
    if not sort or not self.vAbListSort[sort] then
        sort = 'Abs'
    end

    return self.vAbListSort[sort][math.random(1, #self.vAbListSort[sort])]
end

function FrotaGameMode:GetHeroSkills(heroClass)
    local skills = {}

    -- Build list of abilities
    for heroName, values in pairs(self.heroListKV) do
        if heroName == heroClass then
            for i = 1, 16 do
                local ab = values["Ability"..i]
                if ab and ab ~= 'attribute_bonus' then
                    table.insert(skills, ab)
                end
            end
        end
    end

    return skills
end

function FrotaGameMode:RemoveAllSkills(hero)
    -- Check if we've touched this hero before
    if not self.currentSkillList[hero] then
        -- Grab the name of this hero
        local heroClass = hero:GetUnitName()

        local skills = self:GetHeroSkills(heroClass)

        -- Store it
        self.currentSkillList[hero] = skills
    end

    -- Remove all old skills
    for k,v in pairs(self.currentSkillList[hero]) do
        if hero:HasAbility(v) then
            hero:RemoveAbility(v)
        end
    end
end

function FrotaGameMode:ApplyBuild(hero, build)
    -- Grab playerID
    local playerID = hero:GetPlayerID()
    if not self:IsValidPlayerID(playerID) then
        return
    end

    -- Make sure the build was parsed
    build = build or self.selectedBuilds[playerID].skills

    -- Remove all the skills from our hero
    self:RemoveAllSkills(hero)

    -- Give all the abilities in this build
    for k,v in ipairs(build) do
        -- Add to build
        hero:AddAbility(v)
        self.currentSkillList[hero][k] = v
    end
end

function FrotaGameMode:ChangeHero(hero, newHeroName)
    local playerID = hero:GetPlayerID()
    local ply = Players:GetPlayer(playerID)
    if ply then
        -- Grab info
        local exp = hero:GetCurrentXP()
        local gold = hero:GetGold()

        local slots = {}
        for i=0, 11 do
            local item = hero:GetItemInSlot(i)
            if item then
                -- Workout purchaser
                local purchaser = -1
                if item:GetPurchaser() ~= hero then
                    purchaser = item:GetPurchaser()
                end

                -- Store the item
                slots[i] = {
                    purchaser = purchaser,
                    purchaseTime = item:GetPurchaseTime(),
                    currentCharges = item:GetCurrentCharges(),
                    StacksWithOtherOwners = item:StacksWithOtherOwners(),
                    sort = item:GetAbilityName()
                }

                -- Remove the item
                item:Remove()
            end
        end

        -- Replace the hero
        local newHero = ply:ReplaceHeroWith(newHeroName, gold, exp)
        self:SetActiveHero(newHero)

        -- Validate new hero
        if newHero then
            local blockers = {}

            -- Give items
            for i=0, 11 do
                local item = slots[i]
                if item then
                    local p = (item.purchaser == -1 and newHero) or item.purchaser
                    local it = CreateItem(item.sort, p, p)
                    it:SetPurchaseTime(item.purchaseTime)
                    it:SetCurrentCharges(item.currentCharges)
                    it:SetStacksWithOtherOwners(item.StacksWithOtherOwners)
                    newHero:AddItem(it)
                else
                    local it = CreateItem('item_blink', newHero, newHero)
                    newHero:AddItem(it)
                    table.insert(blockers, it)
                end
            end

            -- Remove blocks
            for k,v in pairs(blockers) do
                -- Remove this blocker
                v:Remove()
            end

            -- Return their new hero
            return newHero
        end
    end
end

function FrotaGameMode:LoadBuildFromHero(hero)
    -- Grab playerID
    local playerID = hero:GetPlayerID()
    if not self:IsValidPlayerID(playerID) then
        return
    end

    -- Stick this hero's skills in
    local skills = self:GetHeroSkills(hero:GetUnitName())
    for i=1,4 do
        self.selectedBuilds[playerID].skills[i] = skills[i]
    end
end

function FrotaGameMode:SkillIntoSlot(hero, skillName, skillSlot, dontSlotIt)
    -- Validate Data here (never trust client)

    -- Grab playerID
    local playerID = hero:GetPlayerID()
    if not self:IsValidPlayerID(playerID) then
        return
    end

    if not dontSlotIt then
        -- Update build
        self.selectedBuilds[playerID].skills[skillSlot] = skillName

        -- Apply the new build
        self:ApplyBuild(hero)
    else
        -- Update build
        self.selectedBuilds[playerID].skills[skillSlot] = skillName
    end

    -- Send out the updated builds
    FireGameEvent("afs_update_builds", {
        d = JSON:encode(self:BuildBuildsData())
    })

    -- Update the state data
    self:ChangeStateData(self:BuildAbilityListData())
end

function FrotaGameMode:SelectHero(ply, heroName, dontChangeNow)
    -- Validate Data Hero (never trust the client)
    if not heroName then return end
    if not self.heroListEnabled[heroName] then return end

    -- Grab playerID
    local playerID = ply:GetPlayerID()
    if not self:IsValidPlayerID(playerID) then
        return
    end

    -- Update build
    self.selectedBuilds[playerID].hero = heroName

    if not dontChangeNow then
        -- Change hero
        local hero = ply:ReplaceHeroWith(heroName, 0, 0)
        self:SetActiveHero(hero)

        -- Make sure we have a hero
        if IsValidEntity(hero) then
            -- Check if the user is allowed to pick skills
            if not self.pickMode.pickSkills then
                -- Update build with our hero's skills
                self:LoadBuildFromHero(hero)
            else
                -- Apply build
                self:ApplyBuild(hero)
            end
        end
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
    if not self:IsValidPlayerID(playerID) then
        return
    end

    -- Toggle ready state
    self.selectedBuilds[playerID].ready = not self.selectedBuilds[playerID].ready

    -- Check if everyone is ready
    local allReady = true
    self:LoopOverPlayers(function(ply, playerID)
        if Players:GetPlayer(playerID) and (not self.selectedBuilds[playerID].ready) then
            allReady = false
            return true
        end
    end)

    if allReady then
        -- Start the game
        self:StartGame()
    else
        -- Send out the updated data
        FireGameEvent("afs_update_builds", {
            d = JSON:encode(self:BuildBuildsData())
        })

        -- Update the state data
        self:ChangeStateData(self:BuildAbilityListData())
    end
end

function FrotaGameMode:BuildTimerData()
    local timers = {}

    -- Store timers
    for k, v in pairs(self.timers) do
        -- Make sure we need to send it
        if v.send then
            timers[k] = {
                e = v.endTime,
                t = v.text
            }
        end
    end

    return timers
end

function FrotaGameMode:UpdateTimerData()
    -- Change the state data
    self:ChangeStateData(self.currentStateDataRaw)

    -- Update clients
    FireGameEvent("afs_timer_update", {
        d = JSON:encode(self:BuildTimerData())
    })
end

function FrotaGameMode:UpdateScoreData()
    -- Check if this gamemode uses scores
    if self.gamemodeOptions.useScores then
        local winner = -1

        -- Check if the game was won
        if self.scoreDire == (self.gamemodeOptions.scoreLimit or -1) then
            winner = DOTA_TEAM_BADGUYS
        elseif self.scoreRadiant == (self.gamemodeOptions.scoreLimit or -1) then
            winner = DOTA_TEAM_GOODGUYS
        end

        -- Check if there was a winner
        if winner ~= -1 then
            -- Reset back to gamemode voting
            self:EndGamemode()
        end

        -- Update clients
        FireGameEvent("afs_score_update", {
            d = JSON:encode({
                scoreDire = self.scoreDire,
                scoreRadiant = self.scoreRadiant
            })
        })
    end
end

function FrotaGameMode:ChangeStateData(data)
    -- Make sure there is some data
    data = data or {}

    -- Store timers
    data.timers = self:BuildTimerData()

    -- Store scores
    if self.gamemodeOptions.useScores then
        data.scoreDire = self.scoreDire
        data.scoreRadiant = self.scoreRadiant
    end

    -- Set the current data
    self.currentStateData = JSON:encode(data)
    self.currentStateDataRaw = data
end

function FrotaGameMode:GetStateData()
    return self.currentStateData
end

function FrotaGameMode:ChangeState(newState, newData)
    -- Update local state
    self.currentState = newState
    self:ChangeStateData(newData)

    -- Hook stuff
    if newState == STATE_PICKING then
        -- Picking Phase

        self:CreateTimer('pickTimer', {
            endTime = Time() + PICKING_TIME,
            callback = function(frota, args)
                -- Make sure we are still in the picking phase
                if frota.currentState == STATE_PICKING then
                    -- Start the game
                    frota:StartGame()
                end
            end,
            text = "#afs_picking_timer",
            send = true
        })

        -- When the picking phase will end
        --self.pickingOverTime = Time() + PICKING_TIME

        -- Set the correct think state
        self.thinkState = Dynamic_Wrap(FrotaGameMode, '_thinkState_Picking')
    elseif newState == STATE_VOTING then
        -- Voting Think
        self.thinkState = Dynamic_Wrap(FrotaGameMode, '_thinkState_Voting')
    else
        self.thinkState = Dynamic_Wrap(FrotaGameMode, '_thinkState_None')
    end

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
    self:LoopOverPlayers(function(ply, playerID)
        Players:SetGold( playerID, STARTING_GOLD, false )
        Players:SetGold( playerID, 0, true )
        Players:SetBuybackCooldownTime( playerID, 0 )
        Players:SetBuybackGoldLimitTime( playerID, 0 )
        Players:ResetBuybackCostTime( playerID )
    end)

    -- Set initial Values again
    self:_SetInitialValues()
end

function FrotaGameMode:Think()
    -- If the game's over, it's over.
    --[[if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
        self._scriptBind:EndThink( "GameThink" )
        return
    end]]

    -- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
    local now = GameRules:GetGameTime()
    if self.t0 == nil then
        self.t0 = now
    end
    local dt = now - self.t0
    self.t0 = now

    -- Run the current think state
    self:thinkState( dt )

    -- Process timers
    for k,v in pairs(self.timers) do
        -- Check if the timer has finished
        if Time() > v.endTime then
            -- Remove from timers list
            self.timers[k] = nil

            -- Run the callback
            local nextCall = v.callback(self, v)

            -- Check if it needs to loop
            if nextCall then
                -- Change it's end time
                v.endTime = nextCall
                self.timers[k] = v
            end

            -- Update timer data
            self:UpdateTimerData()
        end
    end

    -- Fire gamemode thinks
    self:FireEvent('onThink', dt)
end

function FrotaGameMode:SetBuildSkills(playerID, skills)
    if not self.selectedBuilds[playerID] then return end

    -- Change the skills
    self.selectedBuilds[playerID].skills = skills
end

function FrotaGameMode:CreateVote(args)
    -- Create new vote
    self.currentVote = {
        options = {},
        sort = args.sort,
        onFinish = args.onFinish
    }

    if args.sort == VOTE_SORT_SINGLE then
        local totalChoices = 0

        -- Store vote choices, register handles
        for k, v in pairs(args.options) do
            -- Increase the total number of choices
            totalChoices = totalChoices + 1

            -- Store this vote
            self.currentVote.options[k] = {
                votes = {},
                des = v,
                count = 0
            }
        end

        -- Check if there is only one choice (or none)
        if totalChoices <= 1 then
            local winners = {}
            for k,v in pairs(self.currentVote.options) do
                table.insert(winners, k)
            end

            -- Remove the current vote
            self.currentVote = nil

            -- Run the callback
            args.onFinish(winners)

            -- Done
            return
        end
    elseif args.sort == VOTE_SORT_OPTIONS then
        local totalChoices = 0

        -- Store vote choices, register handles
        for k, v in pairs(args.options) do
            -- Increase the number of choices
            totalChoices = totalChoices+1

            -- Store this vote
            self.currentVote.options[k] = {
                votes = {},
                o = v,
                count = 0
            }

            -- Change count if this is a ranged based vote
            if v.s == VOTE_SORT_RANGE then
                -- Set the count to be the default value
                self.currentVote.options[k].count = v.def
            end
        end

        -- Check if there is no options
        if totalChoices <= 0 then
            -- Remove the current vote
            self.currentVote = nil

            -- Run the callback
            args.onFinish({})

            -- Done
            return
        end
    else
        print('\nINVALID VOTE CREATED!\n')
        return
    end

    -- Create a timer
    self:CreateTimer('voteTimer', {
        endTime = Time() + args.duration,
        callback = function(frota, args)
            -- Check if there is a vote active
            local cv = frota.currentVote
            if cv then
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
                elseif cv.sort == VOTE_SORT_OPTIONS then
                    for k,v in pairs(cv.options) do
                        -- Check what sort this vote option is
                        if v.o.s == VOTE_SORT_YESNO then
                            -- Check the vote count
                            if v.count == 0 then
                                -- Draw, give the default
                                winners[k] = v.o.def
                            elseif v.count > 0 then
                                -- Majority votes yes
                                winners[k] = true
                            else
                                -- Majority votes no
                                winners[k] = false
                            end
                        elseif v.o.s == VOTE_SORT_RANGE then
                            -- The median is stored as the count
                            winners[k] = v.count
                        end
                    end
                else
                    print('INVALID VOTE ENDED!')
                    frota.currentVote = nil
                    return
                end

                -- Remove the active vote
                frota.currentVote = nil

                -- Call the callback for vote ending
                cv.onFinish(winners)
            end
        end,
        text = "#afs_vote_ends_in",
        send = true
    })

    -- Build data, and send
    self:ChangeState(STATE_VOTING, self:BuildVoteData())
end

function FrotaGameMode:CastVote(playerID, vote, mutli)
    -- Make sure there is a vote active
    if (not self.currentVote) or (self.currentState ~= STATE_VOTING) then return end

    -- Make sure multi is a number
    mutli = tonumber(mutli or 0)

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
    elseif self.currentVote.sort == VOTE_SORT_OPTIONS then
        if usersChoice.o.s == VOTE_SORT_YESNO then
            -- Yes/No votes
            if usersChoice.votes[playerID] == nil then
                if mutli == 1 then
                    usersChoice.votes[playerID] = 1
                    usersChoice.count = usersChoice.count + 1
                else
                    usersChoice.votes[playerID] = 0
                    usersChoice.count = usersChoice.count - 1
                end
            else
                -- Adjust this user's vote
                if mutli == 1 then
                    if usersChoice.votes[playerID] == 0 then
                        usersChoice.votes[playerID] = 1
                        usersChoice.count = usersChoice.count + 2
                    end
                else
                    if usersChoice.votes[playerID] == 1 then
                        usersChoice.votes[playerID] = 0
                        usersChoice.count = usersChoice.count - 2
                    end
                end
            end
        elseif usersChoice.o.s == VOTE_SORT_RANGE then
            -- Range based votes
            usersChoice.votes[playerID] = mutli

            local votes = {}
            for k, v in pairs(usersChoice.votes) do
                table.insert(votes, v)
            end

            -- Sort it
            table.sort(votes)

            -- Change the current count
            if math.mod(#votes, 2) == 0 then
                usersChoice.count = math.floor(((votes[#votes/2]+votes[#votes/2+1])/2+0.5))
            else
                usersChoice.count = votes[math.ceil(#votes/2)]
            end
        end
    else
        print('USER TRIED TO VOTE IN AN INVALID VOTE!!!')
        return
    end

    -- Update data on this vote
    self:ChangeStateData(self:BuildVoteData())

    -- Send the updated columns to everyone
    self:SendVoteStatus()
end

function FrotaGameMode:BuildVoteData()
    local data = {
        --endTime = self.currentVote.endTime,
        sort = self.currentVote.sort,
        --duration = self.currentVote.duration,
        options = self.currentVote.options
    }

    return data
end

function FrotaGameMode:SendVoteStatus()
    local cv = self.currentVote
    if not cv then return end

    FireGameEvent("afs_vote_status", {
        d = JSON:encode(cv.options)
    })
end

function FrotaGameMode:_thinkState_Voting(dt)
    if GameRules:State_Get() < DOTA_GAMERULES_STATE_PRE_GAME then
        -- Waiting on the game to start...
        return
    end

    -- Change to picking phase if it isn't already active
    if (not self.startedInitialVote) and self.currentState ~= STATE_VOTING then
        local totalPlayers = 0

        -- Check how many players are in
        self:LoopOverPlayers(function(ply, playerID)
            totalPlayers = totalPlayers + 1
        end)

        -- Ensure we have at least one player
        if totalPlayers <= 0 then
            return
        end

        -- This only ever runs once
        self.startedInitialVote = true

        -- Begin gamemode voting
        self:VoteForGamemode()
    end
end

function FrotaGameMode:_thinkState_Picking(dt)
end

-- Nothing is happening
function FrotaGameMode:_thinkState_None(dt)
end

function FrotaGameMode:ChooseRandomHero()
    return self.heroList[math.random(1, #self.heroList)]
end

-- Resets everyone's hero to axe
function FrotaGameMode:ResetAllHeroes()
    -- Replace all player's heroes, and then stun them
    self:LoopOverPlayers(function(ply, playerID)
        self:SetActiveHero(ply:ReplaceHeroWith('npc_dota_hero_axe', 0, 0))
    end)
end

-- Ends the current game, resetting to the voting stage
function FrotaGameMode:EndGamemode()
    -- Fire start event
    self:FireEvent('onGameEnd')

    -- Cleanup
    self:CleanupEverything(true)

    -- Start game mode vote
    self:VoteForGamemode()
end

function FrotaGameMode:VoteForGamemode()
    -- Reset ready status
    self:LoopOverPlayers(function(ply, playerID)
        self.selectedBuilds[playerID].ready = false
    end)

    -- Grab all the gamemodes the require picking
    local modes = GetPickingGamemodes()
	
	local preset = Convars:GetStr("frota_mode_preset")
	
	local options = {}
	
	if preset and preset ~= "" then
		options['#afs_name_'..preset] = '#afs_des_'..preset
	else 
		local bans = Convars:GetStr("frota_ban_modes")
		
		for k, v in pairs(modes) do
			local banned = false
			if bans and bans ~= "" then
				for ban in string.gmatch(bans, '([^,]+)') do
					if ban == v then
						banned = true
						break
					end
				end
			end
			if not banned then 
				options['#afs_name_'..v] = '#afs_des_'..v
			end
		end
	end

    -- Reset the loaders
    self.toLoadPickMode = {}
    self.toLoadPlayMode = {}

    -- Create a vote for the game mode
    self:CreateVote({
        sort = VOTE_SORT_SINGLE,
        options = options,
        duration = 10,
        onFinish = function(winners)
            -- Grab the winning option, we need to remove the #afs_name_ from the start
            local mode = string.sub(winners[math.random(1, #winners)], 11)

            -- Grab the mode
            self.toLoadPickMode = GetGamemode(mode)

            -- Check if it was a picking gamemode
            if self.toLoadPickMode.sort == GAMEMODE_PICK then
                -- We need a gameplay gamemode now

                -- Grab all the gamemodes the require picking
                local modes = GetPlayingGamemodes()

                local options = {}
                for k, v in pairs(modes) do
                    options['#afs_name_'..v] = '#afs_des_'..v
                end

                -- Vote for the gameplay section
                self:CreateVote({
                    sort = VOTE_SORT_SINGLE,
                    options = options,
                    duration = 10,
                    onFinish = function(winners)
                        -- Grab the winning option, we need to remove the #afs_name_ from the start
                        local mode = string.sub(winners[math.random(1, #winners)], 11)

                        -- Grab the mode
                        self.toLoadPlayMode = GetGamemode(mode)

                        -- Vote for addons
                        self:VoteForAddons()
                    end
                })
            else
                -- Vote for addons
                self:VoteForAddons()
            end
        end
    })
end

function FrotaGameMode:VoteForAddons()
    -- Build list of incompatble addons
    local incom = {}

    if self.toLoadPickMode then
        for k,v in pairs(self.toLoadPickMode.ignoreAddons or {}) do
            if v then
                incom[k] = true
            end
        end
    end

    if self.toLoadPlayMode then
        for k,v in pairs(self.toLoadPlayMode.ignoreAddons or {}) do
            if v then
                incom[k] = true
            end
        end
    end

    -- Grab all the addon gamemodes
    local modes = GetAddonGamemodes()

    local options = {}
    for k, v in pairs(modes) do
        if not incom[v] then
            options['#afs_name_'..v] = {
                d = '#afs_des_'..v,
                s = VOTE_SORT_YESNO,
                def = false
            }
        end
    end

    -- Vote for the gameplay section
    self:CreateVote({
        sort = VOTE_SORT_OPTIONS,
        options = options,
        duration = 10,
        onFinish = function(winners)
            self.loadedAddons = {}

            for k,v in pairs(winners) do
                -- Check if a plugin was meant to be loaded
                if v then
                    local mode = string.sub(k, 11)
                    table.insert(self.loadedAddons, GetGamemode(mode))
                end
            end

            -- Vote for options
            self:VoteForOptions()
        end
    })
end

function FrotaGameMode:VoteForOptions()
    local options = {}

    local function buildOptions(t)
        -- Check if the table exists, and if it has vote options
        if t and t.voteOptions then
            for k, v in pairs(t.voteOptions) do
                -- Store the option
                options['#afs_o_'..k] = v

                -- Add a description if there is none
                options['#afs_o_'..k].d = options['#afs_o_'..k].d or '#afs_od_'..k
            end
        end
    end

    -- Build options
    buildOptions(self.toLoadPickMode)
    buildOptions(self.toLoadPlayMode)

    -- Build all the options for each addon
    for k, v in pairs(self.loadedAddons or {}) do
        buildOptions(v)
    end

    -- Vote for options
    self:CreateVote({
        sort = VOTE_SORT_OPTIONS,
        options = options,
        duration = 10,
        onFinish = function(winners)
            local realWinners = {}
            for k, v in pairs(winners) do
                realWinners[string.sub(k, 8)] = v
            end

            -- Store the options
            self.gamemodeVoteOptions = realWinners

            -- Load up the gamemode
            self:LoadGamemode()
        end
    })
end

-- Returns a table with all the options in it
function FrotaGameMode:GetOptions()
    return self.gamemodeVoteOptions or {}
end

-- Sets the score limit
function FrotaGameMode:SetScoreLimit(limit)
    -- Make sure we have gamemode options
    self.gamemodeOptions = self.gamemodeOptions or {}

    -- Set the score limit
    self.gamemodeOptions.scoreLimit = limit
end

function FrotaGameMode:FireEvent(name, ...)
    local e

    -- Pick mode events
    e = (self.pickMode and self.pickMode[name])
    if e then
        e(self, ...)
    end

    -- Play mode events
    e = (self.playMode and self.playMode[name])
    if e then
        e(self, ...)
    end

    -- Addon events
    for k, v in pairs(self.loadedAddons or {}) do
        e = v[name]
        if e then
            e(self, ...)
        end
    end
end

function FrotaGameMode:LoadGamemode()
    -- Store the modes
    self.pickMode = self.toLoadPickMode
    self.playMode = self.toLoadPlayMode

    -- Fire event
    self:FireEvent('onPickingStart')

    -- Check if there is any sort of picking
    if self.pickMode.pickHero or self.pickMode.pickSkills then
        -- Start picking
        self:ChangeState(STATE_PICKING, self:BuildAbilityListData())
    else
        -- Start the game
        self:StartGame()
    end
end

function FrotaGameMode:CleanupEverything(leaveHeroes)
    -- Remove all timers
    self.timers = {}

    -- Remove all NPCs
    for k,v in pairs(Entities:FindAllByClassname('npc_dota_*')) do
        -- Validate entity
        if IsValidEntity(v) then
            -- Check if it's a h ero
            if v.IsRealHero and v:IsRealHero() then
                -- Check if it has a player
                local playerID = v:GetPlayerID()
                local ply = Players:GetPlayer(playerID)
                if ply then
                    -- Yes, replace this player's hero for axe
                    self:SetActiveHero(ply:ReplaceHeroWith('npc_dota_hero_axe', 0, 0))
                else
                    -- Nope, remove it
                    v:Remove()
                end
            else
                v:Remove()
            end
        end
    end

    -- Clean up everything on the ground;
    while GameRules:NumDroppedItems() > 0 do
        local item = GameRules:GetDroppedItem(0)
        UTIL_RemoveImmediate( item )
    end

    -- Loop over every player
    self:LoopOverPlayers(function(ply, playerID)
        -- Check if we should touch heroes
        if not leaveHeroes then
            if IsValidEntity(self:GetActiveHero(playerID)) then
                -- Assign them a hero
                self:FireEvent('assignHero', ply)
                self:FireEvent('onHeroSpawned', self:GetActiveHero(playerID))
            end
        end

        -- Set buyback state
        Players:SetBuybackCooldownTime(playerID, 0)
        Players:SetBuybackGoldLimitTime(playerID, 0)
        Players:ResetBuybackCostTime(playerID)
    end)
end

function FrotaGameMode:StartGame()
    -- Cleanup time
    self:CleanupEverything()

    -- Store options
    self.gamemodeOptions = (self.playMode and self.playMode.options) or (self.pickMode and self.pickMode.options) or {}

    -- Reset scores
    self.scoreDire = 0
    self.scoreRadiant = 0

    -- Change to playing
    self:ChangeState(STATE_PLAYING, {})

    -- Fire start event
    self:FireEvent('onGameStart')
end

function FrotaGameMode:BuildBuildsData()
    local data = {}

    self:LoopOverPlayers(function(ply, playerID)
        local v = self.selectedBuilds[playerID]
        if v then
            -- Convert ready bool into a number
            local ready = 0
            if v.ready then
                ready = 1
            end

            data[playerID] = {
                r = ready,
                h = v.hero,
                s = {}
            }

            -- Add hero and ready state
            local sBuild = v.hero..'::'..ready

            -- Add all skills
            local j = 0
            for kk, vv in ipairs(v.skills) do
                data[playerID].s[j] = vv
                j = j + 1
            end
        end
    end)

    return data
end

function FrotaGameMode:BuildAbilityListData()
    local data = {
        b = self:BuildBuildsData()
    }

    -- Should we add hero picker?
    if self.pickMode.pickHero then
        data.h = self.heroListEnabled
    end

    -- Should we add skill picker?
    if self.pickMode.pickSkills then
        data.s = {};
        for k,v in pairs(self.vAbList) do
            data.s[v.name] = {
                c = v.sort,
                h = v.hero
            }
        end
    end

    -- Return the data
    return data;
end

function FrotaGameMode:PrecacheSkill(skillName)
    return
end

EntityFramework:RegisterScriptClass( FrotaGameMode )
