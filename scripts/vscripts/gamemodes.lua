--[[
    EVENTS:

    - onPickingStart(frota): When the picking stage is loaded
    - onGameStart(frota): When the game actually starts
    - assignHero(frota, ply): A player needs a hero to be assigned
    - onHeroKilled(frota, killedUnit, killerEntity): A player was killed by something (note: killerEntity could be null)
    - onThink(frota, dt): Runs ~every 0.1 seconds, dt is the time since the last think, should be around 0.1 of a second
    - onGameEnd(frota): Runs when the game mode finishes, you can do cleanup here

    MOD EVENTS -- Mod events are all in the form of (frota, keys), you can find the arguments below via keys: keys.PlayerID

    - dota_player_used_ability
        - "PlayerID"        "short"
        - "abilityname"     "string"
    - dota_player_learned_ability
        - "PlayerID"        "short"
        - "abilityname"     "string"
    - dota_player_gained_level
        - "PlayerID"        "short"
        - "level"           "short"
    - dota_item_purchased
        - "PlayerID"        "short"
        - "itemname"        "string"
        - "itemcost"        "short"
    - dota_item_used
        - "PlayerID"        "short"
        - "itemname"        "string"
    - last_hit
        - PlayerID"         "short"
        - "EntKilled"       "short"
        - "FirstBlood"      "bool"
        - "HeroKill"        "bool"
        - "TowerKill"       "bool"
    - dota_item_picked_up
        - "itemname"        "string"
        - "PlayerID"        "short"
     - dota_super_creep
        - "teamnumber"      "short"
    - dota_glyph_used
        - "teamnumber"      "short"
    - dota_courier_respawned
        - "teamnumber"      "short"
    - "dota_courier_lost"
        - "teamnumber"      "short"
]]

-- Table to store all the diffrent gamemodes
gamemodes = gamemodes or {}

-- Table to store acutal gamemodes
gamemodes.g = gamemodes.g or {}

local function RegisterGamemode(name, args)
    -- Store the gamemode
    gamemodes.g[name] = args
end

-- Gets all the gamemodes that have a picking state
function GetPickingGamemodes()
    local modes = {}

    -- Build a list of picking gamemodes
    for k,v in pairs(gamemodes.g) do
        if v.sort == GAMEMODE_PICK or v.sort == GAMEMODE_BOTH then
            table.insert(modes, k)
        end
    end

    return modes
end

-- Gets all the gamemodes that have a playing state (unless they also have a picking state)
function GetPlayingGamemodes()
    local modes = {}

    -- Build a list of picking gamemodes
    for k,v in pairs(gamemodes.g) do
        if v.sort == GAMEMODE_PLAY then
            table.insert(modes, k)
        end
    end

    return modes
end

-- Gets the table with info on a gamemode
function GetGamemode(name)
    return gamemodes.g[name]
end

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
        ply:ReplaceHeroWith(build.hero, 100000, 32400)
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
        ply:ReplaceHeroWith(build.hero, 100000, 32400)

        local hero = Players:GetSelectedHeroEntity(playerID)

        -- Change skills
        frota:ApplyBuild(hero)
    end,
})

-- Random OMG
RegisterGamemode('romg', {
    -- This gamemode is only for picking
    sort = GAMEMODE_PICK,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()
        local build = frota.selectedBuilds[playerID]

        -- Change hero
        ply:ReplaceHeroWith(frota:ChooseRandomHero(), 100000, 32400)

        local hero = Players:GetSelectedHeroEntity(playerID)

        -- Make a random build
        frota:SetBuildSkills(playerID, {
            [1] = frota:GetRandomAbility(),
            [2] = frota:GetRandomAbility(),
            [3] = frota:GetRandomAbility(),
            [4] = frota:GetRandomAbility('Ults')
        })

        -- Change skills
        frota:ApplyBuild(hero)
    end,
})

-- Standard Arena PvP
RegisterGamemode('arena', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PLAY,

    -- A list of options for fast gameplay stuff
    options = {
        -- Kills give team points
        killsScore = true,

        -- Score Limit
        scoreLimit = 10,

        -- Enable scores
        useScores = true,

        -- Respawn delay
        respawnDelay = 3
    }
})

-- A Pudge Wars Type Gamemode
RegisterGamemode('pudgewars', {
    -- Gamemode covers picking and playing
    sort = GAMEMODE_BOTH,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        local hookSkill = 'pudge_meat_hook'

        -- Change heroes
        ply:ReplaceHeroWith('npc_dota_hero_pudge', 100000, 32400)

        local playerID = ply:GetPlayerID()
        local hero = Players:GetSelectedHeroEntity(playerID)

        -- Apply the build
        frota:ApplyBuild(hero, {
            [1] = hookSkill,
            [2] = 'mirana_arrow',
            [3] = 'magnataur_skewer',
            [4] = 'tusk_ice_shards'
        })

        hero:__KeyValueFromInt('AbilityLayout', 6)
    end,

    -- A list of options for fast gameplay stuff
    options = {
        -- Kills give team points
        killsScore = true,

        -- Score Limit
        scoreLimit = 10,

        -- Enable scores
        useScores = true,

        -- Respawn delay
        respawnDelay = 3
    }
})

-- Tiny Wars
RegisterGamemode('tinywars', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_BOTH,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        ply:ReplaceHeroWith('npc_dota_hero_tiny', 100000, 32400)
    end,

    -- A list of options for fast gameplay stuff
    options = {
        -- Kills give team points
        killsScore = true,

        -- Score Limit
        scoreLimit = 10,

        -- Enable scores
        useScores = true,

        -- Respawn delay
        respawnDelay = 3
    }
})

--Mirana Wars or something like that
RegisterGamemode('pureskill', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_BOTH,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        -- Change heroes
        ply:ReplaceHeroWith('npc_dota_hero_pudge', 100000, 32400)

        local playerID = ply:GetPlayerID()
        local hero = Players:GetSelectedHeroEntity(playerID)

        -- Apply the build
        frota:ApplyBuild(hero, {
            [1] = 'magnataur_skewer',
            [2] = 'mirana_arrow',
            [3] = 'pudge_meat_hook',
            [4] = 'tusk_ice_shards'
        })
    end,

    -- A list of options for fast gameplay stuff
    options = {
        -- Kills give team points
        killsScore = true,

        -- Score Limit
        scoreLimit = 10,

        -- Enable scores
        useScores = true,

        -- Respawn delay
        respawnDelay = 3
    }
})

-- Not done yet
--[[RegisterGamemode('sunstrikewars', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_BOTH,

    -- Players can pick their hero
    pickHero = true,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()
        local build = frota.selectedBuilds[playerID]

        -- Change hero
        ply:ReplaceHeroWith(build.hero, 100000, 32400)
    end,

    -- A list of options for fast gameplay stuff
    options = {
        -- Kills give team points
        killsScore = true,

        -- Score Limit
        scoreLimit = 10,

        -- Enable scores
        useScores = true,

        -- Respawn delay
        respawnDelay = 3
    }
})]]

--[[RegisterGamemode('oddball', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_BOTH,
        --gemisgive=0
    -- Function to give out heroes
    assignHero = function(frota, ply)
        -- Grab hero
        local playerID = ply:GetPlayerID()
        local hero = Players:GetSelectedHeroEntity(playerID)

        -- Give boots
        hero:AddItem(CreateItem('item_power_treads', hero, hero))
    end,

    -- A list of options for fast gameplay stuff
    options = {
        -- Kills give team points
        killsScore = true,

        -- Score Limit
        scoreLimit = 1020,

        -- Enable scores
        useScores = true,

        -- Respawn delay
        respawnDelay = 3
    },

--onThink(frota, dt)=function(ply, frota)

        onGameStart = function(frota)
            frota:CreateTimer('oddball_create_timer', {
                endTime = Time() + 10,  -- Run 10 seconds from now
                callback = function(frota, args)
                    print('code was run!')
                end
            })
        end


})]]