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
        - "PlayerID"         "short"
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
    - dota_courier_lost
        - "teamnumber"      "short"
    - entity_killed
        - "entindex_killed"         "long"
        - "entindex_attacker"       "long"
        - "entindex_inflictor"      "long"
        - "damagebits"              "long"
]]

-- Table to store all the diffrent gamemodes
gamemodes = gamemodes or {}

-- Table to store acutal gamemodes
gamemodes.g = gamemodes.g or {}

function RegisterGamemode(name, args)
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

-- Gets all the addons
function GetAddonGamemodes()
    local modes = {}

    -- Build a list of picking gamemodes
    for k,v in pairs(gamemodes.g) do
        if v.sort == GAMEMODE_ADDON then
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
        ply:ReplaceHeroWith(build.hero, 2500, 2600)
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
        ply:ReplaceHeroWith(build.hero, 2500, 2600)

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
        ply:ReplaceHeroWith(frota:ChooseRandomHero(), 2500, 2600)

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

        -- Enable scores
        useScores = true,

        -- Respawn delay
        respawnDelay = 3
    },

    voteOptions = {
        -- Score limit vote
        scoreLimit = {
            -- Range based
            s = VOTE_SORT_RANGE,

            -- Minimal possible value
            min = 1,

            -- Maximal possible value
            max = 50,

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

-- Mirana Wars or something like that
RegisterGamemode('pureskill', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_BOTH,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        -- Change heroes
        ply:ReplaceHeroWith('npc_dota_hero_pudge', 2500, 2600)

        local playerID = ply:GetPlayerID()
        local hero = Players:GetSelectedHeroEntity(playerID)

        -- Apply the build
        frota:ApplyBuild(hero, {
            [1] = 'pure_skill_meat_hook',
            [2] = 'pure_skill_mirana_arrow',
            [3] = 'pure_skill_magnataur_skewer',
            [4] = 'pure_skill_tusk_ice_shards'
        })
    end,

    -- A list of options for fast gameplay stuff
    options = {
        -- Kills give team points
        killsScore = true,

        -- Enable scores
        useScores = true,

        -- Respawn delay
        respawnDelay = 3
    },

    voteOptions = {
        -- Score limit vote
        scoreLimit = {
            -- Range based
            s = VOTE_SORT_RANGE,

            -- Minimal possible value
            min = 1,

            -- Maximal possible value
            max = 50,

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

<<<<<<< HEAD
-- Addon plugins
=======
--[[ Addon plugins ]]--
>>>>>>> upstream/master

-- WTF Mode
RegisterGamemode('wtf', {
    -- This gamemode is only for picking
    sort = GAMEMODE_ADDON,

    -- When the game starts
    onGameStart = function(frota)
        -- Enable WTF
        Convars:SetBool('dota_ability_debug', true)
    end,

    -- When the game ends
    onGameEnd = function(frota)
        -- Disable WTF
        Convars:SetBool('dota_ability_debug', false)
    end
})

-- Free Blink Dagger
RegisterGamemode('freeBlinkDagger', {
    -- This gamemode is only for picking
    sort = GAMEMODE_ADDON,

    -- When players are given a new hero
    assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()
        local hero = Players:GetSelectedHeroEntity(playerID)

        -- Make sure they have a hero
        if hero then
            -- Give them a blink dagger
            hero:AddItem(CreateItem('item_blink', hero, hero))
        end
    end
})

<<<<<<< HEAD
=======
-- No Buying
RegisterGamemode('noBuying', {
    -- This gamemode is only for picking
    sort = GAMEMODE_ADDON,

    -- When players are given a new hero
    dota_item_purchased = function(frota, keys)
        -- Check if this hero exists
        local hero = Players:GetSelectedHeroEntity(keys.PlayerID)
        if hero then
            -- Loop over their items
            for i=0, 11 do
                -- See if there is an item in this slot
                local item = hero:GetItemInSlot(i)
                if item then
                    -- See if it was the item that was just bought
                    if item:GetAbilityName() == keys.itemname then
                        -- Refund the gold
                        Players:SetGold(keys.PlayerID, Players:GetUnreliableGold(keys.PlayerID)+keys.itemcost, false)

                        -- Remove the item
                        item:Remove()
                        break
                    end
                end
            end
        end
    end
})

>>>>>>> upstream/master
--[[RegisterGamemode('unlimitedMana', {
    -- This gamemode is only for picking
    sort = GAMEMODE_ADDON,

    onHeroSpawned = function(frota, hero)
        -- Remove old ability if it exsists
        if hero:HasAbility('forest_troll_high_priest_mana_aura') then
            hero:RemoveAbility('forest_troll_high_priest_mana_aura')
        end

        -- Add mana regen
        hero:AddAbility('forest_troll_high_priest_mana_aura')

        -- Set it to level 1
        local ab = hero:FindAbilityByName('forest_troll_high_priest_mana_aura')
        ab:SetLevel(1)
    end
})]]

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
        ply:ReplaceHeroWith(build.hero, 2500, 2600)
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
