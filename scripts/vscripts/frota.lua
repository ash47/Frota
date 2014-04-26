-- Syntax copied mostly from frostivus example

-- Constants
MAX_PLAYERS = 10
STARTING_GOLD = 625

-- State control
STATE_INIT = 0      -- Waiting for Players
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

-- Reload support apparently
if FrotaGameMode == nil then
    FrotaGameMode = {}
    FrotaGameMode.szEntityClassName = "Frota"
    FrotaGameMode.szNativeClassName = "dota_base_game_mode"
    FrotaGameMode.__index = FrotaGameMode
end

function GetFrota()
    return FROTA_REFERENCE
end

function FrotaGameMode:new (o)
    o = o or {}
    setmetatable(o, self)
    FROTA_REFERENCE = o
    return o
end

function FrotaGameMode:InitGameMode()
    print('\n\nStarting to load Frota gamemode...')
    -- Load version
    self.frotaVersion = LoadKeyValues("scripts/version.txt").version

    -- Register console commands
    self:RegisterCommands()

    -- Create map of buildings
    self:CreateMapBuildingList()

    -- Setup rules
    GameRules:SetHeroRespawnEnabled( false )
    GameRules:SetUseUniversalShopMode( true )
    GameRules:SetSameHeroSelectionEnabled( true )
    GameRules:SetHeroSelectionTime( 0.0 )
    GameRules:SetPreGameTime( 60.0 )
    GameRules:SetPostGameTime( 60.0 )
    GameRules:SetTreeRegrowTime( 60.0 )
    --GameRules:SetHeroMinimapIconSize( 400 )
    --GameRules:SetCreepMinimapIconScale( 0.7 )
    --GameRules:SetRuneMinimapIconScale( 0.7 )

    -- Hooks
    ListenToGameEvent('entity_killed', Dynamic_Wrap(FrotaGameMode, 'OnEntityKilled'), self)
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(FrotaGameMode, 'AutoAssignPlayer'), self)
    ListenToGameEvent('player_disconnect', Dynamic_Wrap(FrotaGameMode, 'CleanupPlayer'), self)
    ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(FrotaGameMode, 'ShopReplacement'), self)

    -- Mod Events
    self:ListenToEvent('dota_player_used_ability')
    self:ListenToEvent('dota_player_learned_ability')
    self:ListenToEvent('dota_player_gained_level')
    self:ListenToEvent('dota_item_used')
    self:ListenToEvent('last_hit')
    self:ListenToEvent('dota_item_picked_up')
    self:ListenToEvent('dota_glyph_used')
    self:ListenToEvent('dota_courier_respawned')
    self:ListenToEvent('dota_courier_lost')
    self:ListenToEvent('entity_hurt')

    -- userID map
    self.vUserIDMap = {}
    self.nLowestUserID = 2

    -- Active Hero Map
    self.vActiveHeroMap = {}

    -- Load initital Values
    self:_SetInitialValues()

    --Convars:SetFloat('dota_suppress_invalid_orders', 1)

    -- Stores the playerIDs that are taken
    --self.takenPlayerIDs = {}

    -- Start thinkers
    --self._scriptBind:BeginThink('FrotaThink', Dynamic_Wrap(FrotaGameMode, 'Think'), 0.1)

    -- This is a hack, fix this
    local thinker = Entities:FindAllByClassname('dota_base_game_mode')[1]
    local fr = self
    local n = 1
    local function thinkFix()
        -- Requeue this think
        thinker:SetContextThink("Think"..n, thinkFix, 0.1)
        n = n+1

        -- Run normal think
        fr:Think()
    end

    thinker:SetContextThink("Think", thinkFix, 0.1)

    -- Precache everything -- Having issues with the arguments changing
    print('Precaching stuff...')
    if not pcall(function()
        PrecacheUnit('npc_precache_everything')
    end) then
        pcall(function()
            PrecacheUnit('npc_precache_everything', {})
        end)
    end
    --PrecacheResource('test', 'test')
    print('Done precaching!')
    print('Done loading Frota gamemode!\n\n')
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
    -- A server command to attempt to reload stuff -- doesnt work 11/02/2014
    Convars:RegisterCommand('reloadtest', function(name, skillName, slotNumber)
        -- Check if the server ran it
        if not Convars:GetCommandClient() then
            GameRules:Playtesting_UpdateCustomKeyValues()
        end
    end, 'Reload shit test', 0)

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

    --[[-- Popup test
    Convars:RegisterCommand('popup', function(name, skillName, slotNumber)
        local cmdPlayer = Convars:GetCommandClient()

        ShowGenericPopupToPlayer(cmdPlayer, "a", "b", "c", "d", 1)
    end, 'A user tried to put a skill into a slot', 0)]]

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
            -- Create fake Players
            SendToServerConsole('dota_create_fake_clients')

            -- Assign the fakers
            self:CreateTimer('assign_fakes', {
                endTime = Time(),
                callback = function(frota, args)
                    for i=0, 9 do
                        -- Check if this player is a fake one
                        if PlayerResource:IsFakeClient(i) then
                            -- Grab player instance
                            local ply = PlayerResource:GetPlayer(i)

                            -- Make sure we actually found a player instance
                            if ply then
                                self:AutoAssignPlayer({
                                    userid = self.nLowestUserID,
                                    index = ply:entindex()-1
                                })
                            end
                        end
                    end
                end,
                persist = true
            })
        end
    end, 'Connects and assigns fake Players.', 0)

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
                    local steamID = PlayerResource:GetSteamAccountID(playerID)

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
            send = set this to true if you want clients to get this,
            persist = bool: Should we keep this timer even if the match ends?
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
        -- Grab the players team
        local team = ply:GetTeam()

        -- Increase the number of players on this player's team
        teamSize[team] = (teamSize[team] or 0) + 1
    end)

    --[[if SMJS_LOADED then
        local newPlayerID = -1

        -- SM.JS playerID override
        for i=0,9 do
            if not self.takenPlayerIDs[i] then
                self.takenPlayerIDs[i] = true
                newPlayerID = i
                break;
            end
        end

        newPlayerID = 5

        if newPlayerID == -1 then
            print('FAILED TO FIND SPARE PLAYERID!')
        else
            -- Allocate playerID
            smjsSetNetprop(ply, 'm_iPlayerID', newPlayerID)
        end

        --local playerManager = Entities:FindAllByClassname('dota_player_manager')[1]
        --smjsSetNetprop(ply, 'm_iTeamNum', 2)
        --smjsSetNetprop(playerManager, 'm_iPlayerTeams', 2, ply:GetPlayerID())
    end]]

    if teamSize[DOTA_TEAM_GOODGUYS] > teamSize[DOTA_TEAM_BADGUYS] then
        ply:SetTeam(DOTA_TEAM_BADGUYS)
        ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_BADGUYS)
    else
        ply:SetTeam(DOTA_TEAM_GOODGUYS)
        ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_GOODGUYS)
    end

    --ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_BADGUYS)

    --for i=0,4 do
    --    PlayerResource:UpdateTeamSlot(ply:GetPlayerID(), i)
    --end

    local playerID = ply:GetPlayerID()
    local hero = self:GetActiveHero(playerID)
    if IsValidEntity(hero) then
        hero:Remove()
    end

    -- Store into our map
    self.vUserIDMap[keys.userid] = ply
    self.nLowestUserID = self.nLowestUserID + 1

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
        end,
        persist = true
    })
end

function FrotaGameMode:SetActiveHero(hero, playerID)
    if hero then
        self.vActiveHeroMap[playerID or hero:GetPlayerID()] = hero
    end
end

function FrotaGameMode:GetActiveHero(playerID)
    return self.vActiveHeroMap[playerID]
end

-- Replaces some of the shop buying mechanics
function FrotaGameMode:ShopReplacement(keys)
    -- Check if it is an illegal item
    if(self.customItemKV[keys.itemname]) then
        -- Check if this hero exists
        local hero = self:GetActiveHero(keys.PlayerID)
        if hero then
            -- Loop over their items
            for i=0, 11 do
                -- See if there is an item in this slot
                local item = hero:GetItemInSlot(i)
                if item and item:GetOwner() == hero then
                    -- See if it was the item that was just bought
                    if item:GetAbilityName() == keys.itemname then
                        -- Refund the gold
                        PlayerResource:SetGold(keys.PlayerID, PlayerResource:GetUnreliableGold(keys.PlayerID)+keys.itemcost, false)

                        -- Remove the item
                        item:Remove()
                        return
                    end
                end
            end

            local team = hero:GetTeam()

            -- Search couriers
            local n = PlayerResource:GetNumCouriersForTeam(team)
            if n > 0 then
                for i=0,n-1 do
                    local courier = PlayerResource:GetNthCourierForTeam(i, team)

                    for j=0, 5 do
                        local item = courier:GetItemInSlot(j)
                        if item and item:GetOwner() == courier then
                            -- See if it was the item that was just bought
                            if item:GetAbilityName() == keys.itemname then
                                -- Refund the gold
                                PlayerResource:SetGold(keys.PlayerID, PlayerResource:GetUnreliableGold(keys.PlayerID)+keys.itemcost, false)

                                -- Remove the item
                                item:Remove()
                                return
                            end
                        end
                    end
                end
            end
        end

        -- Failed to find the old fasion way, check the ground
        local n = GameRules:NumDroppedItems()
        if n > 0 then
            -- Grab the newest item
            local itemCon = GameRules:GetDroppedItem(n-1)
            if itemCon then
                local item = itemCon:GetContainedItem()
                if item and item:GetOwner() == hero then
                    if item:GetAbilityName() == keys.itemname then
                        -- Refund the gold
                        PlayerResource:SetGold(keys.PlayerID, PlayerResource:GetUnreliableGold(keys.PlayerID)+keys.itemcost, false)

                        -- Remove the item
                        item:Remove()
                        itemCon:Remove()
                        return
                    end
                end
            end

        end
    end
end

-- Cleanup a player when they leave
function FrotaGameMode:CleanupPlayer(keys)
    -- Grab and validate the leaver
    local leavingPly = self.vUserIDMap[keys.userid]
    self.vUserIDMap[keys.userid] = nil

    if not leavingPly then
        print('Failed to cleanup player #'..keys.userid)
        return
    end

    -- Attempt to remove them
    local playerID = leavingPly:GetPlayerID()
    SendToServerConsole('clear_playerid '..playerID)

    -- Fire event
    self:FireEvent('CleanupPlayer', leavingPly)

    -- Remove all Heroes owned by this player
    for k,v in pairs(Entities:FindAllByClassname('npc_dota_hero_*')) do
        if v:IsRealHero() then
            -- Grab the owning player
            local ply = PlayerResource:GetPlayer(v:GetPlayerID())

            -- Check if this is our leaver
            if ply and ply == leavingPly then
                -- Remove this hero
                v:Remove()
            end
        end
    end

    self:CreateTimer('cleanup_player_'..keys.userid, {
        endTime = Time()+3,
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
            --self:_SetInitialValues()

            -- Close server
            self:CloseServer()
        end,
        persist = true
    })
end

function FrotaGameMode:CloseServer()
    -- Just exit
    SendToServerConsole('exit')
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

function FrotaGameMode:RespawnHero(hero, buyback, unknown1, unknown2)
    -- Respawn the hero
    hero:RespawnHero(buyback, unknown1, unknown2)

    -- Fire the respawn event
    self:FireEvent('onHeroSpawned', hero)
    self:FireEvent('onHeroRespawn', hero)
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
                            frota:RespawnHero(killedUnit, false, false, false, false)
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
    local abs = LoadKeyValues("scripts/kv/abilities.kv")
    self.heroListKV = LoadKeyValues("scripts/npc/npc_heroes.txt")
    self.customItemKV = LoadKeyValues("scripts/npc/npc_items_custom.txt")
    self.subAbilities = LoadKeyValues("scripts/kv/abilityDeps.kv")

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
    self.vAbListLookup = {}

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

                -- Store the reverse lookup
                self.vAbListLookup[kk] = k
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

function FrotaGameMode:RefreshAllSkills(hero)
    -- Check if we've touched this hero before
    if not self.currentSkillList[hero] then
        -- Grab the name of this hero
        local heroClass = hero:GetUnitName()

        local skills = self:GetHeroSkills(heroClass)

        -- Store it
        self.currentSkillList[hero] = skills
    end

    -- Refresh all skills
    for k,v in pairs(self.currentSkillList[hero]) do
        if hero:HasAbility(v) then
            hero:FindAbilityByName(v):EndCooldown()
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

    -- Table to store all the extra skills we need to give
    local extraSkills = {}

    -- Give all the abilities in this build
    for k,v in ipairs(build) do
        -- Check if this skill has sub abilities
        if self.subAbilities[v] then
            -- Store that we need this skill
            extraSkills[self.subAbilities[v]] = true
        end

        -- Add to build
        hero:AddAbility(v)
        self.currentSkillList[hero][k] = v
    end

    -- Add missing abilities
    local i = #build+1
    for k,v in pairs(extraSkills) do
        -- Add the ability
        hero:AddAbility(k)

        -- Store that we have it
        self.currentSkillList[hero][i] = k

        -- Move onto the next slot
        i = i + 1
    end
end

function FrotaGameMode:ChangeHero(hero, newHeroName)
    local playerID = hero:GetPlayerID()
    local ply = PlayerResource:GetPlayer(playerID)
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
        local newHero = PlayerResource:ReplaceHeroWith(playerID, newHeroName, gold, exp)
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
    -- Grab playerID
    local playerID = hero:GetPlayerID()
    if not self:IsValidPlayerID(playerID) then
        return
    end

    -- Check for limits
    local totalUlts = 0
    local totalSkills = 0

    -- Count all old skills
    for k,v in pairs(self.selectedBuilds[playerID].skills) do
        if k ~= skillSlot then
            -- Grab the sort
            local sort =  self.vAbListLookup[v]

            -- Check it
            if sort == 'Ults' then
                -- It's an ult
                totalUlts = totalUlts + 1
            elseif sort == 'Abs' then
                -- It's a normal skill
                totalSkills = totalSkills + 1
            end
        end
    end

    -- Grab the sort
    local sort =  self.vAbListLookup[skillName]

    -- Check it
    if sort == 'Ults' then
        -- It's an ult
        totalUlts = totalUlts + 1
    elseif sort == 'Abs' then
        -- It's a normal skill
        totalSkills = totalSkills + 1
    else
        -- Unknown skill -- Ignore
        return
    end

    -- If we've hit the ult limit
    if totalUlts > 1 then
        -- Don't slot this skill
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
        local hero = PlayerResource:ReplaceHeroWith(playerID, heroName, 0, 0)
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
        if PlayerResource:GetPlayer(playerID) and (not self.selectedBuilds[playerID].ready) then
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

function FrotaGameMode:GetDefaultHeroScale(heroName)
    if self.heroListKV[heroName] then
        return tonumber(self.heroListKV[heroName].ModelScale) or 1
    end

    return 1
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
            -- Reset back to gamemode voting after a short delay
            self:CreateTimer('scoreLimitReached', {
                endTime = Time(),
                callback = function(frota, args)
                    -- End the gamemode
                    self:EndGamemode()
                end
            })
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
    --Convars:SetBool( "dota_winter_ambientfx", true )
end

function FrotaGameMode:_RestartGame()
    -- Clean up everything on the ground; gold, tombstones, items, everything.
    while GameRules:NumDroppedItems() > 0 do
        local item = GameRules:GetDroppedItem(0)
        UTIL_RemoveImmediate( item )
    end

    -- Reset PlayerResource
    self:LoopOverPlayers(function(ply, playerID)
        PlayerResource:SetGold( playerID, STARTING_GOLD, false )
        PlayerResource:SetGold( playerID, 0, true )
        PlayerResource:SetBuybackCooldownTime( playerID, 0 )
        PlayerResource:SetBuybackGoldLimitTime( playerID, 0 )
        PlayerResource:ResetBuybackCostTime( playerID )
    end)

    -- Set initial Values again
    self:_SetInitialValues()
end

function FrotaGameMode:Think()
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
            local status, nextCall = pcall(v.callback, self, v)

            -- Make sure it worked
            if status then
                -- Check if it needs to loop
                if nextCall then
                    -- Change it's end time
                    v.endTime = nextCall
                    self.timers[k] = v
                end

                -- Update timer data
                self:UpdateTimerData()
            else
                -- Nope, handle the error
                self:HandleEventError('Timer', k, nextCall)
                return
            end
        end
    end

    -- Ensure a game is active
    if self.currentState == STATE_PLAYING then
        -- Fire gamemode thinks
        self:FireEvent('onThink', dt)
    end
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
        self:SetActiveHero(PlayerResource:ReplaceHeroWith(playerID, 'npc_dota_hero_axe', 0, 0))
    end)
end

-- Ends the current game, resetting to the voting stage
function FrotaGameMode:EndGamemode()
    -- Fire start event
    self:FireEvent('onGameEnd')

    -- Cleanup
    self:CleanupEverything(true)

    -- Vote to play again
    self:VoteToPlayAgain()

    -- Start game mode vote
    --self:VoteForGamemode()
end

function FrotaGameMode:VoteToPlayAgain()
    -- Reset ready status
    self:LoopOverPlayers(function(ply, playerID)
        self.selectedBuilds[playerID].ready = false
    end)

    -- Create a vote for the game mode
    self:CreateVote({
        sort = VOTE_SORT_SINGLE,
        options = {
            ["#afs_play_again"] = "#afs_play_again_des",
            ["#afs_play_something_else"] = "#afs_play_something_else_des",
            ["#afs_close_server"] = "afs_close_server_des"
        },
        duration = 10,
        onFinish = function(winners)
            -- Grab the winning option, we need to remove the #afs_name_ from the start
            local choice = winners[math.random(1, #winners)]

            if choice == '#afs_play_again' then
                -- Play again -- just load the gamemode
                self:LoadGamemode()
            elseif choice == '#afs_play_something_else' then
                -- Create a vote to play something else
                self:VoteForGamemode()
            else
                -- Close the server
                self:CloseServer()
            end
        end
    })
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

    -- Reset current modes
    self.pickMode = {}
    self.playMode = {}
    self.loadedAddons = {}

    -- Check if we have d2ware settings
    if d2wareSettings then
        -- Should we force a gamemode?
        if d2wareSettings.picking and d2wareSettings.picking ~= '-' then
            -- Check if the gamemode exists
            for k, v in pairs(modes) do
                -- Did we find it?
                if v == d2wareSettings.picking then
                    -- Create new set of choices
                    options = {
                        ['#afs_name_'..v] = '#afs_des_'..v
                    }
                    break
                end
            end
        end
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
            self.toLoadPickMode = GetGamemode(mode)

            -- Tell everyone
            Say(nil, COLOR_LGREEN..tostring(mode)..COLOR_NONE..' was loaded!', false)

            -- Check if it was a picking gamemode
            if self.toLoadPickMode.sort == GAMEMODE_PICK then
                -- We need a gameplay gamemode now

                -- Grab all the gamemodes the require picking
                local modes = GetPlayingGamemodes()

                local options = {}
                for k, v in pairs(modes) do
                    options['#afs_name_'..v] = '#afs_des_'..v
                end

                -- Check if we have d2ware settings
                if d2wareSettings then
                    -- Should we force a gamemode?
                    if d2wareSettings.gameplay and d2wareSettings.gameplay ~= '-' then
                        -- Check if the gamemode exists
                        for k, v in pairs(modes) do
                            -- Did we find it?
                            if v == d2wareSettings.gameplay then
                                -- Create new set of choices
                                options = {
                                    ['#afs_name_'..v] = '#afs_des_'..v
                                }
                                break
                            end
                        end
                    end
                end

                -- Vote for the gameplay section
                self:CreateVote({
                    sort = VOTE_SORT_SINGLE,
                    options = options,
                    duration = 10,
                    onFinish = function(winners)
                        -- Grab the winning option, we need to remove the #afs_name_ from the start
                        local mode = string.sub(winners[math.random(1, #winners)], 11)

                        -- Tell everyone
                        Say(nil, COLOR_LGREEN..tostring(mode)..COLOR_NONE..' was loaded!', false)

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

    local whiteList = {}
    local useWhiteList = false

    if self.toLoadPickMode then
        -- Blacklist plugins
        for k,v in pairs(self.toLoadPickMode.ignoreAddons or {}) do
            if v then
                incom[k] = true
            end
        end

        -- Whitelist plugins
        if self.toLoadPickMode.compatibleAddons then
            useWhiteList = true

            for k,v in pairs(self.toLoadPickMode.compatibleAddons or {}) do
                if v then
                    whiteList[k] = true
                end
            end
        end
    end

    if self.toLoadPlayMode then
        -- Blacklist plugins
        for k,v in pairs(self.toLoadPlayMode.ignoreAddons or {}) do
            if v then
                incom[k] = true
            end
        end

        -- Whitelist plugins
        if self.toLoadPlayMode.compatibleAddons then
            useWhiteList = true

            for k,v in pairs(self.toLoadPlayMode.compatibleAddons or {}) do
                if v then
                    whiteList[k] = true
                end
            end
        end
    end

    -- Grab all the addon gamemodes
    local modes = GetAddonGamemodes()

    local options = {}
    for k, v in pairs(modes) do
        if (not incom[v]) and ((not useWhiteList) or whiteList[v]) then
            options['#afs_name_'..v] = {
                d = '#afs_des_'..v,
                s = VOTE_SORT_YESNO,
                def = false
            }
        end
    end

    local d2wareWinners = {}
    if d2wareSettings then
        for k,v in pairs(modes) do
            -- Check if d2ware should take control of this plugin
            if d2wareSettings[v] ~= nil then
                -- Check if this is even allowed
                if (not incom[v]) and ((not useWhiteList) or whiteList[v]) then
                    -- Remove the choice to vote for this plugin
                    options['#afs_name_'..v] = nil

                    -- Store if we should load this plugin
                    d2wareWinners['#afs_name_'..v] = d2wareSettings[v]
                end
            end
        end
    end

    -- Vote for the gameplay section
    self:CreateVote({
        sort = VOTE_SORT_OPTIONS,
        options = options,
        duration = 10,
        onFinish = function(winners)
            self.loadedAddons = {}

            -- Merge d2ware stuff
            for k,v in pairs(d2wareWinners) do
                winners[k] = v
            end

            -- Check which plugins to load
            for k,v in pairs(winners) do
                -- Check if a plugin was meant to be loaded
                if v then
                    -- Grab the mode
                    local mode = string.sub(k, 11)

                    -- Tell everyone
                    Say(nil, COLOR_LGREEN..tostring(mode)..COLOR_NONE..' was loaded!', false)

                    -- Load it
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

    local d2wareWinners = {}

    local function buildOptions(t)
        -- Check if the table exists, and if it has vote options
        if t and t.voteOptions then
            for k, v in pairs(t.voteOptions) do
                -- Check if this setting is controlled by d2ware
                if d2wareSettings and d2wareSettings[k] then
                    -- Store the d2ware winner
                    d2wareWinners['#afs_o_'..k] = d2wareSettings[k]
                else
                    -- Store the option
                    options['#afs_o_'..k] = v

                    -- Add a description if there is none
                    options['#afs_o_'..k].d = options['#afs_o_'..k].d or '#afs_od_'..k
                end
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
            -- Add d2ware results
            for k,v in pairs(d2wareWinners) do
                winners[k] = v
            end

            local realWinners = {}
            for k, v in pairs(winners) do
                local txt = string.sub(k, 8)
                realWinners[txt] = v

                -- Tell everyone
                Say(nil, COLOR_LGREEN..tostring(txt)..COLOR_NONE..' was set to '..COLOR_LGREEN..tostring(v), false)
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

function FrotaGameMode:HandleEventError(name, event, err)
    -- This gets fired when an event throws an error

    -- Log to console
    print(err)

    -- Ensure we have data
    name = tostring(name or 'unknown')
    event = tostring(event or 'unknown')
    err = tostring(err or 'unknown')

    -- Tell everyone there was an error
    Say(nil, COLOR_RED..name..COLOR_NONE..' threw an error on event '..COLOR_RED..event, false)
    Say(nil, COLOR_RED..err, false)

    -- Prevent loop arounds
    if not self.errorHandled then
        -- Store that we handled an error
        self.errorHandled = true

        -- End the gamemode
        self:EndGamemode()
    end
end

function FrotaGameMode:FireEvent(name, ...)
    local e

    -- Pick mode events
    e = (self.pickMode and self.pickMode[name])
    if e then
        local status, err = pcall(e, self, ...)
        if not status then
            self:HandleEventError(self.pickMode.__name, name, err)
            return
        end
    end

    -- Play mode events
    e = (self.playMode and self.playMode[name])
    if e then
        local status, err = pcall(e, self, ...)
        if not status then
            self:HandleEventError(self.playMode.__name, name, err)
            return
        end
    end

    -- Addon events
    for k, v in pairs(self.loadedAddons or {}) do
        e = v[name]
        if e then
            local status, err = pcall(e, self, ...)
            if not status then
                self:HandleEventError(v.__name, name, err)
                return
            end
        end
    end
end

function FrotaGameMode:LoadGamemode()
    -- Remove D2Ware settings container
    d2wareSettings = nil

    -- Store the modes
    self.pickMode = self.toLoadPickMode
    self.playMode = self.toLoadPlayMode

    -- Reset the error handling state
    self.errorHandled = false

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

function FrotaGameMode:RemoveTimers(killAll)
    local timers = {}

    -- If we shouldn't kill all timers
    if not killAll then
        -- Loop over all timers
        for k,v in pairs(self.timers) do
            -- Check if it is persistant
            if v.persist then
                -- Add it to our new timer list
                timers[k] = v
            end
        end
    end

    -- Store the new batch of timers
    self.timers = timers
end

function FrotaGameMode:RespawnBuildings()
    for k,v in pairs(self.MapBuildingList) do
        -- Validate entity
        if IsValidEntity(v) then
            if v:IsAlive() then
                v:Heal(v:GetMaxHealth(), v)
            else
                v:RespawnUnit()
            end
        end
    end
end

function FrotaGameMode:IsValidPosition(pos)
    -- Check if the position is outside the valid playing area
    if pos.x < GetWorldMinX() or pos.x > GetWorldMaxX() or pos.y < GetWorldMinY() or pos.y > GetWorldMaxY() then
        -- Outside
        return false
    end

    -- Must be inside
    return true
end

function FrotaGameMode:CleanupEverything(leaveHeroes)
    -- Remove all timers
    self:RemoveTimers()

    -- Cleanup Heroes
    for k,v in pairs(Entities:FindAllByClassname('npc_dota_hero_*')) do
        -- Validate entity
        if IsValidEntity(v) then
            -- Check if it's a h ero
            if v.IsRealHero and v:IsRealHero() then
                -- Check if it has a player
                local playerID = v:GetPlayerID()
                local ply = PlayerResource:GetPlayer(playerID)
                if ply then
                    -- Yes, replace this player's hero for axe
                    self:SetActiveHero(PlayerResource:ReplaceHeroWith(playerID, 'npc_dota_hero_axe', 0, 0))
                else
                    -- Nope, remove it
                    v:Remove()
                end
            end
        end
    end

    -- Cleanup Units
    for k,v in pairs(Entities:FindAllByClassname('npc_dota_*')) do
        -- Validate entity
        if IsValidEntity(v) then
            if v.IsHero and not(v:IsHero() or v:IsTower()) then
                local name = v:GetClassname():lower()
                if not (name:find('tower') or name:find('rax') or name:find('barracks') or name:find('filler') or name:find('fort') or name:find('announcer') or name:find('building') or name:find('roshan')) then
                    --print(name)
                    v:Remove()
                end
            end
        end
    end

    -- Fully heal / respawn buildings
    self:RespawnBuildings()

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
        PlayerResource:SetBuybackCooldownTime(playerID, 0)
        PlayerResource:SetBuybackGoldLimitTime(playerID, 0)
        PlayerResource:ResetBuybackCostTime(playerID)
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

function FrotaGameMode:CreateMapBuildingList()
    -- Create new tower list
    self.MapBuildingList = {}

    for k,v in pairs(Entities:FindAllByClassname('npc_dota_*')) do
        -- Validate entity
        if IsValidEntity(v) then
            if v.IsTower then
                -- Store the building
                table.insert(self.MapBuildingList, v)
            end
        end
    end
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

--[[
Use            : function to search an item in hero's invent and return if present otherwise nil
               : For multiple instances of same item, first one is returned
Arguments:
hscript hero   : the player's hero
string itemname: Item name for e.g. "item_blink"
bool stash     : whether to search stash slots also
bool dropped   : whether to search dropped items also

Returns Values :
Returns a table with key,
    Item: if found in slots
    PhysicalItem: if dropped item
Otherwise nil
]]
function FrotaGameMode:GetHeroItemByName(hero,itemName,stash,dropped)
    local item=nil
    local physicalItem=nil
    local found={}
    -- 6 hero slots
    local nslots=6
    -- additional 6 stash slots
    if stash then
        nslots=nslots + 6
    end
    for i=0,nslots-1 do
        item = hero:GetItemInSlot(i)
        -- check slot has valid item or nothing
        if IsValidEntity(item) then
            -- check item is the required one
            if item:GetName() == itemName then
                found["Item"] = item
                return found
            end
        end
    end
    -- Check Dropped Items for hero item
    if dropped then
        local num = GameRules:NumDroppedItems()
        for i=0,num-1 do
            -- get Physical item
            physicalItem = GameRules:GetDroppedItem(i)
            -- get Actual item in it
            item = physicalItem:GetContainedItem()
            -- check item is the required one
            if item:GetName() == itemName then
                -- Check owner of item is given hero
                if item:GetPurchaser() == hero then
                    found["PhysicalItem"] = physicalItem
                    return found
                end
            end
        end
    end
    return nil
end

--[[
Use            : function to remove an item in hero's invent if present
               : For multiple instances of same item, first one is removed only
Arguments:
hscript hero   : the player's hero
string itemname: Item name for e.g. "item_blink"
bool stash     : whether to search stash slots also
bool dropped   : whether to search dropped items also

Returns Values : true on Success otherwise false
]]
function FrotaGameMode:RemoveHeroItemByName(hero,itemName,stash,dropped)
    local found = self:GetHeroItemByName(hero,itemName,stash,dropped)
    if found.Item then
        found.Item:Remove()
    elseif found.PhysicalItem then
        found.PhysicalItem:Remove()
    else
        return false
    end
    return true
end

--EntityFramework:RegisterScriptClass( FrotaGameMode )
