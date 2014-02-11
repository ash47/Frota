--[[
    EVENTS:

    - onPickingStart(frota): When the picking stage is loaded
    - onGameStart(frota): When the game actually starts
    - assignHero(frota, ply): A player needs a hero to be assigned
    - onHeroKilled(frota, killedUnit, killerEntity): A player was killed by something (note: killerEntity could be null)
    - onThink(frota, dt): Runs ~every 0.1 seconds, dt is the time since the last think, should be around 0.1 of a second
    - onGameEnd(frota): Runs when the game mode finishes, you can do cleanup here
    - CleanupPlayer(frota, leavingPly): A player is about to leave and be cleaned up
    - NewPlayer(frota, ply): A new player has connected, and been assigned their hero
    - onHeroSpawned(frota, hero): When a player spawns (This fires on respawn as well as initial spawn)
    - onHeroRespawn(frota, hero): When a hero is respawned (doesnt include initial spawn!)

    MOD EVENTS -- Mod events are all in the form of (frota, keys), you can find the arguments below via keys: keys.PlayerID

    - dota_player_used_ability
        - "player"          "short"
        - "abilityname"     "string"
    - dota_player_learned_ability
        - "player"          "short"
        - "abilityname"     "string"
    - dota_player_gained_level
        - "player"          "short"
        - "level"           "short"
    - dota_item_purchased
        - "PlayerID"        "short"
        - "itemname"        "string"
        - "itemcost"        "short"
    - dota_item_used
        - "PlayerID"        "short"
        - "itemname"        "string"
    - last_hit
        - "PlayerID"        "short"
        - "EntKilled"       "short"
        - "FirstBlood"      "bool"
        - "HeroKill"        "bool"
        - "TowerKill"       "bool"
    - dota_item_picked_up
        - "itemname"        	"string"
        - "PlayerID"        	"short"
        - "ItemEntityIndex" 	"long"
        - "HeroEntityIndex" 	"long"
    - dota_glyph_used
        - "teamnumber"      "short"
    - dota_courier_respawned
        - "teamnumber"      "short"
    - dota_courier_lost
        - "teamnumber"      "short"
    - entity_killed
        - "entindex_killed"         "long"
        - "entindex_attacker"       "long"
        - "entindex_inflictor"      "long"
        - "damagebits"              "long"
    - entity_hurt
        - "entindex_killed"   "long"
        - "entindex_attacker" "long"
        - "entindex_inflictor"    "long"
        - "damagebits"        "long"

    GAMEMODE FIRED EVENT - Events that are fired from certain gamemodes
     - dmNewHero(frota, hero): DM Mode has allocated a new hero (hero being the new hero)
]]

-- Table to store all the diffrent gamemodes
gamemodes = gamemodes or {}

-- Table to store acutal gamemodes
gamemodes.g = gamemodes.g or {}

function RegisterGamemode(name, args)
    -- Store the gamemode name
    args.__name = name

    -- Store the gamemode
    gamemodes.g[name] = args
end

local function checkWhiteList(mode)
    -- Grab current map
    local currentMap = GetMapName():lower()

    if (not mode.whiteList or mode.whiteList[currentMap]) and (not mode.blackList or not mode.blackList[currentMap]) and (not mode.smjsNeeded or SMJS_LOADED) then
        return true
    end

    return false
end

-- Gets all the gamemodes that have a picking state
function GetPickingGamemodes()
    local modes = {}

    -- Build a list of picking gamemodes
    for k,v in pairs(gamemodes.g) do
        if v.sort == GAMEMODE_PICK or v.sort == GAMEMODE_BOTH then
            if checkWhiteList(v) then
                table.insert(modes, k)
            end
        end
    end

    return modes
end

-- Gets all the gamemodes that have a playing state (unless they also have a picking state)
function GetPlayingGamemodes()
    local modes = {}

    for k,v in pairs(gamemodes.g) do
        if v.sort == GAMEMODE_PLAY then
            if checkWhiteList(v) then
                table.insert(modes, k)
            end
        end
    end

    return modes
end

-- Gets all the addons
function GetAddonGamemodes()
    local modes = {}

    -- Build a list of picking gamemodes
    for k,v in pairs(gamemodes.g) do
        if v.sort == GAMEMODE_ADDON then
            if checkWhiteList(v) then
                table.insert(modes, k)
            end
        end
    end

    return modes
end

-- Gets the table with info on a gamemode
function GetGamemode(name)
    return gamemodes.g[name]
end

-- List of dota type maps
dotaMapList = {
    dota = true,
    dota_autumn = true,
    dota_newyear = true,
    dota_winter = true
}

-- All Pick
RegisterGamemode('allpick', {
    -- This gamemode is only for picking
    sort = GAMEMODE_PICK,

    -- Allow certain picking things
    pickHero = true,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()
        local build = frota.selectedBuilds[playerID]

        -- Change hero
        local hero = PlayerResource:ReplaceHeroWith(playerID, build.hero, 2500, 2600)
        frota:SetActiveHero(hero)
    end,
})

-- Legends of Dota
RegisterGamemode('lod', {
    -- This gamemode is only for picking
    sort = GAMEMODE_PICK,

    -- Allow certain picking things
    pickHero = true,
    pickSkills = true,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()
        local build = frota.selectedBuilds[playerID]

        -- Change hero
        local hero = PlayerResource:ReplaceHeroWith(playerID, build.hero, 2500, 2600)
        frota:SetActiveHero(hero)

        -- Change skills
        frota:ApplyBuild(hero)
    end,

    -- DM Mode changed our hero
    dmNewHero = function(frota, hero)
        -- Change skills
        frota:ApplyBuild(hero)
    end
})

-- Random OMG
RegisterGamemode('romg', {
    -- This gamemode is only for picking
    sort = GAMEMODE_PICK,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()

        -- Change hero
        local hero = PlayerResource:ReplaceHeroWith(playerID, frota:ChooseRandomHero(), 2500, 2600)
        frota:SetActiveHero(hero)

        -- Change skills
        frota:ApplyBuild(hero, {
            [1] = frota:GetRandomAbility(),
            [2] = frota:GetRandomAbility(),
            [3] = frota:GetRandomAbility(),
            [4] = frota:GetRandomAbility('Ults')
        })
    end,

    -- DM Mode changed our hero
    dmNewHero = function(frota, hero)
        -- Change skills
        frota:ApplyBuild(hero, {
            [1] = frota:GetRandomAbility(),
            [2] = frota:GetRandomAbility(),
            [3] = frota:GetRandomAbility(),
            [4] = frota:GetRandomAbility('Ults')
        })
    end
})

-- Standard Arena PvP
RegisterGamemode('arena', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PLAY,

    -- A list of options for fast gameplay stuff
    options = {
        -- Kills give team points
        killsScore = true,

        -- Enable scores
        useScores = true,

        -- Respawn delay
        respawnDelay = 3
    },

    -- List of maps this plugin wont work with
    blackList = dotaMapList,

    voteOptions = {
        -- Score limit vote
        scoreLimit = {
            -- Range based
            s = VOTE_SORT_RANGE,

            -- Minimal possible value
            min = 1,

            -- Maximal possible value
            max = 100,

            -- Default vaule (if no one votes)
            def = 10,

            -- Slider tick interval
            tick = 10,

            -- Slider step interval
            step = 1
        }
    },

    onGameStart = function(frota)
        -- Grab options
        local options = frota:GetOptions()

        -- Set the score limit
        frota:SetScoreLimit(options.scoreLimit)
    end
})

-- "Classic" Dota
RegisterGamemode('dota', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PLAY,

    -- A list of options for fast gameplay stuff
    options = {
        -- Kills give team points
        killsScore = true,

        -- Enable scores
        useScores = true
    },

    -- This is ONLY for the dota map
    whiteList = dotaMapList,

    onGameStart = function(frota)
        -- Apply Dota specific Options
        GameRules:SetHeroRespawnEnabled(true)
    end,

    onGameEnd = function(frota)
        -- Reset to normal gamemode options
        GameRules:SetHeroRespawnEnabled(false)
    end
})

-- Mirana Wars or something like that
RegisterGamemode('pureskill', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PICK,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()

        -- Change heroes
        local hero = PlayerResource:ReplaceHeroWith(playerID, 'npc_dota_hero_pudge', 2500, 2600)
        frota:SetActiveHero(hero)

        -- Apply the build
        frota:ApplyBuild(hero, {
            [1] = 'pure_skill_meat_hook',
            [2] = 'pure_skill_mirana_arrow',
            [3] = 'pure_skill_magnataur_skewer',
            [4] = 'pure_skill_tusk_ice_shards'
        })
    end,

    -- DM Mode changed our hero
    dmNewHero = function(frota, hero)
        -- Change skills
        frota:ApplyBuild(hero, {
            [1] = 'pure_skill_meat_hook',
            [2] = 'pure_skill_mirana_arrow',
            [3] = 'pure_skill_magnataur_skewer',
            [4] = 'pure_skill_tusk_ice_shards'
        })
    end
})

-- Riki Wars
RegisterGamemode('rikiwars', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PICK,

    -- List of maps this plugin wont work with
    blackList = dotaMapList,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()

        -- Change heroes
        local hero = PlayerResource:ReplaceHeroWith(playerID, 'npc_dota_hero_riki', 2500, 2600)
        frota:SetActiveHero(hero)

        -- Change skills
        frota:ApplyBuild(hero, {
            [1] = 'rikiwars_smoke_screen',
            [2] = 'rikiwars_blink_strike',
            [3] = 'riki_backstab',
            [4] = 'riki_permanent_invisibility'
        })

        -- Give dust
        hero:AddItem(CreateItem('item_dust_spamable', hero, hero))
    end,

    -- List of addons to ignore
    ignoreAddons = {
        dmMode = true
    },
})

--[[ Addon plugins ]]--

-- WTF Mode
RegisterGamemode('wtf', {
    -- This gamemode is only for picking
    sort = GAMEMODE_ADDON,

    -- We need sm.js to use this plugin
    smjsNeeded = true,

    -- When the game starts
    onGameStart = function(frota)
        -- Enable WTF
        smjsSetInt('dota_ability_debug', 1)
    end,

    -- When the game ends
    onGameEnd = function(frota)
        -- Disable WTF
        smjsSetInt('dota_ability_debug', 0)
    end
})

-- Free Blink Dagger
RegisterGamemode('freeBlinkDagger', {
    -- This gamemode is only for picking
    sort = GAMEMODE_ADDON,

    -- When players are given a new hero
    assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()
        local hero = frota:GetActiveHero(playerID)

        -- Make sure they have a hero
        if hero then
            -- Give them a blink dagger
            hero:AddItem(CreateItem('item_blink', hero, hero))
        end
    end
})

-- No Buying
RegisterGamemode('noBuying', {
    -- This gamemode is only for picking
    sort = GAMEMODE_ADDON,

    -- List of maps this plugin wont work with
    blackList = dotaMapList,

    -- When players are given a new hero
    dota_item_purchased = function(frota, keys)
        -- Check if this hero exists
        local hero = frota:GetActiveHero(keys.PlayerID)
        if hero then
            -- Loop over their items
            for i=0, 11 do
                -- See if there is an item in this slot
                local item = hero:GetItemInSlot(i)
                if item then
                    -- See if it was the item that was just bought
                    if item:GetAbilityName() == keys.itemname then
                        -- Refund the gold
                        PlayerResource:SetGold(keys.PlayerID, PlayerResource:GetUnreliableGold(keys.PlayerID)+keys.itemcost, false)

                        -- Remove the item
                        item:Remove()
                        break
                    end
                end
            end
        end
    end
})

-- DM Mode
--[[RegisterGamemode('dmMode', {
    -- This gamemode is only for picking
    sort = GAMEMODE_ADDON,

    -- When players are given a new hero
    onHeroKilled = function(frota, killedUnit, killerEntity)
        if IsValidEntity(killedUnit) then
            -- Change their hero
            local newHero = frota:ChangeHero(killedUnit, frota:ChooseRandomHero())

            -- Make sure the hero change worked
            if IsValidEntity(newHero) then
                -- Fire the new hero event
                frota:FireEvent('dmNewHero', newHero)
            end
        end
    end
})]]

RegisterGamemode('unlimitedMana', {
    -- This gamemode is only for picking
    sort = GAMEMODE_ADDON,

    onHeroSpawned = function(frota, hero)
        hero:__KeyValueFromInt('StatusManaRegen', 500)
    end
})
