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

function FrotaGameMode:ResetBuilds()
    -- Store the default axe build for each player
    self.selectedBuilds = {}
    for i = 0,MAX_PLAYERS-1 do
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
    self._scriptBind:BeginThink('FrotaThink', Dynamic_Wrap(FrotaGameMode, 'Think'), 0.25)

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

    -- Load initital Values
    self:_SetInitialValues()

    Convars:SetBool('dota_suppress_invalid_orders', true)

    -- userID map
    self.vUserIDMap = {}

    -- Start processing timers
    self._scriptBind:BeginThink('FrotaTimers', Dynamic_Wrap(FrotaGameMode, 'ThinkTimers'), 0.1)
end

function FrotaGameMode:RegisterCommands()
    -- When a user tries to put a skill into a slot
    Convars:RegisterCommand('afs_skill', function(name, skillName, slotNumber)
        -- Verify we are in picking mode
        if self.currentState ~= STATE_PICKING then return end
        if not self.pickMode.pickSkills then return end

        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            local hero = cmdPlayer:GetAssignedHero()
            if hero then
                self:SkillIntoSlot(hero, skillName, tonumber(slotNumber))
                return
            end
        end
    end, 'A user tried to put a skill into a slot', 0 )

    -- When a user tries to change heroes
    Convars:RegisterCommand('afs_hero', function(name, heroName)
        -- Verify we are in picking mode
        if self.currentState ~= STATE_PICKING then return end
        if not self.pickMode.pickHero then return end

        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            self:SelectHero(cmdPlayer, heroName)
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
            if playerID >= 0 and playerID < MAX_PLAYERS then
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

        -- Load this client's version
        if version ~= self.frotaVersion then
            local cmdPlayer = Convars:GetCommandClient()
            if cmdPlayer then
                local playerID = cmdPlayer:GetPlayerID()
                if playerID ~= nil and playerID ~= -1 then
                    Say(cmdPlayer, 'I have frota version '..version..' and the server has version '..self.frotaVersion, false)
                end
            end
        end

        local data = {}

        for i=0, MAX_PLAYERS-1 do
            local steamID = Players:GetSteamAccountID(i)

            if steamID > 0 then
                data[i] = steamID
            end
        end

        -- Fire steamids
        FireGameEvent('afs_steam_ids', {
            d = JSON:encode(data)
        })

        -- Send out state info
        FireGameEvent('afs_initial_state', {
            nState = self.currentState,
            d = self:GetStateData()
        })
    end, 'Client requested the current state', 0)

    -- When a user toggles ready state
    --[[Convars:RegisterCommand( "afs_force_start", function(name, skillName, slotNumber)
        -- Start the game
        self:StartGame()
    end, "Start the game", 0 )]]
end

function FrotaGameMode:CreateTimer(name, args)
    --[[
        args: {
            endTime = Time you want this timer to end: Time() + 30 (for 30 seconds from now),
            callback = function(frota, args) to run when this timer expires,
            text = text to display to clients,
            send = set this to true if you want clients to get this
        }
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

    for i=0,MAX_PLAYERS-1 do
        if Players:GetPlayer(i) then
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

    local playerID = ply:GetPlayerID()
    local hero = Players:GetSelectedHeroEntity(playerID)
    if hero then
        hero:Remove()
    end

    -- Store into our map
    self.vUserIDMap[keys.userid] = ply

    -- Autoassign player
    self:CreateTimer('assign_player_'..entIndex, {
        endTime = Time(),
        callback = function(frota, args)
            CreateHeroForPlayer('npc_dota_hero_axe', ply)

            -- Check if we are in a game
            if self.currentState == STATE_PLAYING then
                -- Check if we need to assign a hero
                self:FireEvent('assignHero', ply)
            end
        end
    })
end

-- Cleanup a player when they leave
function FrotaGameMode:CleanupPlayer(keys)
    -- Grab and validate the leaver
    local leavingPly = self.vUserIDMap[keys.userid];
    if not leavingPly then return end

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
            -- Check if there are any players connected
            for i=0, MAX_PLAYERS-1 do
                local ply = Players:GetPlayer(i)
                if ply then
                    return
                end
            end

            -- No players are in, reset to initial vote
            self:_SetInitialValues()
        end
    })
end

function FrotaGameMode:OnEntityKilled(keys)
    local killedUnit = EntIndexToHScript( keys.entindex_killed )
    local killerEntity = nil

    if keys.entindex_attacker ~= nil then
        killerEntity = EntIndexToHScript( keys.entindex_attacker )
    end

    if killedUnit and killedUnit:IsRealHero() then
        -- Make sure we are playing
        if self.currentState ~= STATE_PLAYING then return end

        -- Fire onHeroKilled event
        self:FireEvent('onHeroKilled', killedUnit, killerEntity)

        -- Respawn the dead guy after a delay
        self:CreateTimer('respawn_hero_'..killedUnit:GetPlayerID(), {
            endTime = Time() + (self.gamemodeOptions.respawnDelay or 1),
            callback = function(frota, args)
                -- Make sure we are still playing
                if frota.currentState == STATE_PLAYING then
                    -- Validate the unit
                    if killedUnit then
                        -- Respawn the dead guy
                        killedUnit:RespawnHero(false, false, false)
                    end
                end
            end
        })

        -- Check if point score
        if not self.gamemodeOptions.killsScore then return end

        local winner = -1

        -- Decide who to give a point to
        local team = killedUnit:GetTeam()
        if team == DOTA_TEAM_GOODGUYS then
            -- Add to the points
            self.scoreDire = self.scoreDire + 1

            -- Check if the game was won
            if self.scoreDire == (self.gamemodeOptions.scoreLimit or -1) then
                winner = DOTA_TEAM_BADGUYS
            end
        else
            -- Add to the points
            self.scoreRadiant = self.scoreRadiant + 1

            -- Check if the game was won
            if self.scoreRadiant == (self.gamemodeOptions.scoreLimit or -1) then
                winner = DOTA_TEAM_GOODGUYS
            end
        end

        -- Update the scores
        self:UpdateScoreData()

        -- Check if there was a winner
        if winner ~= -1 then
            -- Reset back to gamemode voting
            self:EndGamemode()
        end
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

                -- Store into the sort container
                if not self.vAbListSort[k] then
                    self.vAbListSort[k] = {}
                end

                -- Store the sort reference
                table.insert(self.vAbListSort[k], kk)
            end
        end
    end

    --PrintTable(self.vAbList)
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
    if(playerID < 0 or playerID > MAX_PLAYERS-1) then
        return
    end

    -- Make sure the build was parsed
    build = build or self.selectedBuilds[playerID].skills

    -- Remove all the skills from our hero
    self:RemoveAllSkills(hero)

    -- Give all the abilities in this build
    for k,v in ipairs(build) do
        -- Preache ability
        self:PrecacheSkill(v)

        -- Add to build
        hero:AddAbility(v)
        self.currentSkillList[hero][k] = v
    end
end

function FrotaGameMode:LoadBuildFromHero(hero)
    -- Grab playerID
    local playerID = hero:GetPlayerID()
    if(playerID < 0 or playerID > MAX_PLAYERS-1) then
        return
    end

    -- Stick this hero's skills in
    local skills = self:GetHeroSkills(hero:GetUnitName())
    for i=1,4 do
        self.selectedBuilds[playerID].skills[i] = skills[i]
    end
end

function FrotaGameMode:SkillIntoSlot(hero, skillName, skillSlot)
    -- Validate Data here (never trust client)

    -- Grab playerID
    local playerID = hero:GetPlayerID()
    if(playerID < 0 or playerID > MAX_PLAYERS-1) then
        return
    end

    -- Preache the new skill
    self:PrecacheSkill(skillName)

    -- Update build
    self.selectedBuilds[playerID].skills[skillSlot] = skillName

    -- Apply the new build
    self:ApplyBuild(hero)

    -- Send out the updated builds
    FireGameEvent("afs_update_builds", {
        d = JSON:encode(self:BuildBuildsData())
    })

    -- Update the state data
    self:ChangeStateData(self:BuildAbilityListData())
end

function FrotaGameMode:SelectHero(ply, heroName)
    -- Validate Data Hero (never trust the client)
    if not heroName then return end
    if not self.heroListEnabled[heroName] then return end

    -- Grab playerID
    local playerID = ply:GetPlayerID()
    if(playerID < 0 or playerID > MAX_PLAYERS-1) then
        return
    end

    -- Update build
    self.selectedBuilds[playerID].hero = heroName

    -- Change hero
    ply:ReplaceHeroWith(heroName, 0, 0)

    -- Make sure we have a hero
    local hero = Players:GetSelectedHeroEntity(playerID)
    if hero then
        -- Check if the user is allowed to pick skills
        if not self.pickMode.pickSkills then
            -- Update build with our hero's skills
            self:LoadBuildFromHero(hero)
        else
            -- Apply build
            self:ApplyBuild(hero)
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
    if(playerID < 0 or playerID > MAX_PLAYERS-1) then
        return
    end

    -- Toggle ready state
    self.selectedBuilds[playerID].ready = not self.selectedBuilds[playerID].ready

    -- Check if everyone is ready
    local allReady = true
    for i=0,MAX_PLAYERS-1 do
        if Players:GetPlayer(i) and (not self.selectedBuilds[i].ready) then
            allReady = false
            break
        end
    end

    if allReady then
        -- Change to game time
        print('GAME START NOW!')

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
    -- Change the state data
    self:ChangeStateData(self.currentStateDataRaw)

    -- Check if this gamemode uses scores
    if self.gamemodeOptions.useScores then
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

-- Deals with timers
function FrotaGameMode:ThinkTimers()
    -- Process timers
    for k,v in pairs(self.timers) do
        -- Check if the timer has finished
        if Time() > v.endTime then
            -- Remove from timers list
            self.timers[k] = nil

            -- Run the callback
            v.callback(self, v)

            -- Update timer data
            self:UpdateTimerData()
        end
    end
end

function FrotaGameMode:Think()
    -- If the game's over, it's over.
    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
        self._scriptBind:EndThink( "GameThink" )
        return
    end

    -- Hero Selection Screen Bypass
    --[[if GameRules:State_Get() >= DOTA_GAMERULES_STATE_HERO_SELECTION then
        for i=0,MAX_PLAYERS-1 do
            if Players:IsValidPlayer(i) and not Players:GetSelectedHeroEntity(i) then
                -- Grab the player and create them a default hero
                local ply = Players:GetPlayer(i)
                if ply then
                    CreateHeroForPlayer('npc_dota_hero_axe', ply)

                    -- Check if we are in a game
                    if self.currentState == STATE_PLAYING then
                        -- Check if we need to assign a hero
                        self:FireEvent('heroAssign', ply)
                    end
                end
            end
        end
    end]]

    -- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
    local now = GameRules:GetGameTime()
    if self.t0 == nil then
        self.t0 = now
    end
    local dt = now - self.t0
    self.t0 = now

    self:thinkState( dt )
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

    -- Store vote choices, register handles
    for k, v in pairs(args.options) do
        self.currentVote.options[k] = {
            votes = {},
            des = v,
            count = 0
        }
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
                else
                    -- implement this

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
        --endTime = self.currentVote.endTime,
        sort = self.currentVote.sort,
        --duration = self.currentVote.duration,
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

function FrotaGameMode:_thinkState_Voting(dt)
    if GameRules:State_Get() < DOTA_GAMERULES_STATE_PRE_GAME then
        -- Waiting on the game to start...
        return
    end

    -- Change to picking phase if it isn't already active
    if (not self.startedInitialVote) and self.currentState ~= STATE_VOTING then
        local totalPlayers = 0

        -- Check how many players are in
        for i=0, MAX_PLAYERS-1 do
            if Players:GetPlayer(i) then
                totalPlayers = totalPlayers + 1
            end
        end

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
    -- Check if picking has gone on for too long
    --[[if Time() > self.pickingOverTime then
        self:StartGame()
    end]]
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
    for i=0, MAX_PLAYERS-1 do
        local ply = Players:GetPlayer(i)
        if ply then
            -- Give default hero
            ply:ReplaceHeroWith('npc_dota_hero_axe', 0, 0)
        end
    end
end

-- Ends the current game, resetting to the voting stage
function FrotaGameMode:EndGamemode()
    -- Remove all timers
    self.timers = {}

    -- Fire start event
    self:FireEvent('onGameEnd')

    -- Start game mode vote
    self:VoteForGamemode()
end

function FrotaGameMode:VoteForGamemode()
    -- Freeze everyone
    self:ResetAllHeroes()

    -- Reset ready status
    for i = 0,MAX_PLAYERS-1 do
        self.selectedBuilds[i].ready = false
    end

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
        duration = 10,
        onFinish = function(winners)
            -- Grab the winning option, we need to remove the #afs_name_ from the start
            local mode = string.sub(winners[math.random(1, #winners)], 11)

            -- Grab the mode
            local pickMode = GetGamemode(mode)

            -- Check if it was a picking gamemode
            if pickMode.sort == GAMEMODE_PICK then
                -- We need a gameplay gamemode now

                -- Grab all the gamemodes the require picking
                local modes = GetPlayingGamemodes()

                local options = {}
                for k, v in pairs(modes) do
                    options['#afs_name_'..v] = '#afs_des_'..v
                end

                -- Vote for the gameplau section
                self:CreateVote({
                    sort = VOTE_SORT_SINGLE,
                    options = options,
                    duration = 10,
                    onFinish = function(winners)
                        -- Grab the winning option, we need to remove the #afs_name_ from the start
                        local mode = string.sub(winners[math.random(1, #winners)], 11)

                        -- Grab the mode
                        local playMode = GetGamemode(mode)

                        -- Load this gamemode up
                        self:LoadGamemode(pickMode, playMode)
                    end
                })
            else
                -- We must have gotten someone we can just run
                self:LoadGamemode(pickMode)
            end
        end
    })
end

function FrotaGameMode:FireEvent(name, ...)
    local e = (self.pickMode and self.pickMode[name])
    if e then
        e(self, ...)
    end

    local e = (self.playMode and self.playMode[name])
    if e then
        e(self, ...)
    end
end

function FrotaGameMode:LoadGamemode(pickMode, playMode)
    -- Store the modes
    self.pickMode = pickMode
    self.playMode = playMode

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

function FrotaGameMode:StartGame()
    -- Cleanup time

    -- Remove picking timer
    self:RemoveTimer('pickTimer')

    -- Remove all NPCs
    for k,v in pairs(Entities:FindAllByClassname('npc_dota_*')) do
        v:Remove()
    end

    -- Clean up everything on the ground;
    while GameRules:NumDroppedItems() > 0 do
        local item = GameRules:GetDroppedItem(0)
        UTIL_RemoveImmediate( item )
    end

    -- Reset everyone's hero to Axe
    for i=0,MAX_PLAYERS-1 do
        -- Check if this player exists
        if Players:IsValidPlayer(i) then
            ply = Players:GetPlayer(i)
            CreateHeroForPlayer('npc_dota_hero_axe', ply)
        end
    end

    -- Loop over every player
    for i=0,MAX_PLAYERS-1 do
        local ply = Players:GetPlayer(i)

        -- Check if they are in
        if ply then
            -- Assign them a hero
            self:FireEvent('assignHero', ply)
        end
    end

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

    -- Build list of builds
    for i = 0,MAX_PLAYERS-1 do
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
        for kk, vv in ipairs(v.skills) do
            data[i].s[j] = vv
            j = j + 1
        end
    end

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
        print('b')
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
