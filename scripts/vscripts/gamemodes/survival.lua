-- How often we should check if we need to spawn new zombies
local spawnCheckTime = 1

-- Max number of zombies per person
local ZOMBIES_PER_HERO = 20

-- How far should zombies spawn from the players
local SPAWN_DISTANCE = 1800

local zombieInfo = {}   -- Stores info on each user's zombies

-- The time the match started (for scaling)
local startTime = 0.0

local teamBased = false

local function applyDefaultStats(unit, factor, sfactor)
    unit:SetMaxHealth(30 * factor)
    unit:SetHealth(unit:GetMaxHealth())
    unit:__KeyValueFromFloat('StatusHealthRegen', sfactor/2)
    unit:__KeyValueFromInt('BountyGoldMin', 30 * sfactor)
    unit:__KeyValueFromInt('BountyGoldMax', 30 * sfactor)
    unit:__KeyValueFromInt('BountyXP', 75 * sfactor)
    unit:__KeyValueFromInt('MovementSpeed', 375)
    unit:__KeyValueFromInt('AttackDamageMin', 37 * factor)
    unit:__KeyValueFromInt('AttackDamageMax', 45 * factor)
    unit:__KeyValueFromInt('AttackRange', 128)
    unit:__KeyValueFromFloat('AttackRate', 1.6)
    unit:__KeyValueFromInt('VisionDaytimeRange', 400)
    unit:__KeyValueFromInt('VisionNighttimeRange', 400)
    unit:__KeyValueFromInt('ArmorPhysical', factor-1)
    unit:__KeyValueFromInt('MagicalResistance', 33)
end

-- List of zombies that can spawn
local skins = {
    [1] = {
        -- How long before it can spawn?
        minTime = 0,

        -- What unit to base it off?
        unit = 'npc_dota_unit_undying_zombie',

        -- What stats should it get?
        stats = applyDefaultStats
    },

    [2] = {
        minTime = 60,
        unit = 'npc_dota_dark_troll_warlord_skeleton_warrior',
        stats = function(unit, factor, sfactor)
            -- Apply default stuff
            applyDefaultStats(unit, factor, sfactor)

            -- Give magic resist
            unit:__KeyValueFromInt('MagicalResistance', 90)
        end
    },

    [3] = {
        minTime = 120,
        unit = 'npc_dota_visage_familiar1',
        stats = function(unit, factor, sfactor)
            -- Apply default stuff
            applyDefaultStats(unit, factor, sfactor)

            -- Apply new stuff
            unit:__KeyValueFromFloat('AttackRate', 1.2)
            unit:__KeyValueFromInt('AttackRange', 200)
            unit:__KeyValueFromInt('MovementSpeed', 500)
        end
    }
}

local function resetPlayerID(playerID)
    -- Reset info on this player
    zombieInfo[playerID] = {
        zombieList = {}
    }

    return zombieInfo[playerID]
end

local function checkForVictory(frota)
    -- Default to everyone being dead
    local allDeadDire = true
    local allDeadRadiant = true

    -- Loop over all players
    frota:LoopOverPlayers(function(ply, playerID)
        local hero = frota:GetActiveHero(playerID)
        if hero and hero:IsAlive() then
            -- Check if they were on either major team
            if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
                allDeadRadiant = false
            elseif hero:GetTeamNumber() == DOTA_TEAM_BADGUYS then
                allDeadDire = false
            end
        end
    end)

    -- Game ends differently, depending on wether it is team based or not
    if teamBased then
        -- Team based, everyone needs to die
        if allDeadDire and allDeadRadiant then
            -- Print total survival time
            Say(nil, "Total Survival Time: "..math.floor(Time()-startTime).." seconds!", false)

            -- End the gamemode
            frota:EndGamemode()
        end
    else
        if allDeadDire then
            Say(nil, "Dire Loses!", false)
        end

        if allDeadRadiant then
            Say(nil, "Radiant Loses!", false)
        end

        -- If either team has everyone dead
        if allDeadRadiant or allDeadDire then
            -- Print total survival time
            Say(nil, "Total Survival Time: "..math.floor(Time()-startTime).." seconds!", false)

            -- End the gamemode
            frota:EndGamemode()
        end
    end
end

local function reveal(hero)
    hero:AddNewModifier(hero, nil, 'modifier_truesight', {})
end

local function unreveal(hero)
    if hero:HasModifier('modifier_truesight') then
        hero:RemoveModifierByName('modifier_truesight')
    end
end

-- Surval, from D2Ware
RegisterGamemode('survival', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PLAY,

    -- A list of options for fast gameplay stuff
    options = {
        -- Respawn delay
        respawnDelay = 10
    },

    -- A team based game -- doesn't work
    --[[voteOptions = {
        -- Score limit vote
        survivalTeamMode = {
            -- Range based
            s = VOTE_SORT_YESNO,

            -- Default vaule (if no one votes)
            def = false
        }
    },]]

    -- List of maps this plugin wont work with
    blackList = dotaMapList,

    onGameStart = function(frota)
        local options = frota:GetOptions()
        teamBased = options.survivalTeamMode

        -- Reset zombie info
        zombieInfo = {}

        -- Store when we started
        startTime = Time()

        -- Create a clock to spawn zombies
        frota:CreateTimer('survival_clock', {
            endTime = Time()+spawnCheckTime,
            callback = function(frota, args)
                local timePassed = (Time() - startTime)
                local factor = 1 + timePassed/60
                local sfactor = math.sqrt(factor)
                local maxZombies = math.min(ZOMBIES_PER_HERO, 3*factor)

                -- Loop over all the players
                frota:LoopOverPlayers(function(ply, playerID)
                    -- Ensure this player has some info
                    local info = zombieInfo[playerID] or resetPlayerID(playerID)

                    -- Grab their hero, make sure it exists, and is alive
                    local hero = frota:GetActiveHero(playerID)
                    if hero and hero:IsAlive() then
                        local totalZombies = 0
                        -- Make sure each zombie is following their respective player
                        for k,v in pairs(info.zombieList) do
                            if not IsValidEntity(v) then
                                -- Remove it
                                table.remove(info.zombieList, k)
                            elseif Time() > v.expireTime or not v:IsAlive() or v:GetHealth() <= 0 then
                                -- Remove it
                                table.remove(info.zombieList, k)
                                v:ForceKill(false)
                                v:Remove()
                            else
                                -- Increase total zombies
                                totalZombies = totalZombies+1

                                -- Make it attack it's hero
                                v:MoveToTargetToAttack(hero)
                            end
                        end

                        -- Check if they don't have enough zombies
                        while totalZombies < maxZombies do
                            -- Pick a random, valid skin
                            local skin = {}
                            repeat
                                skin = skins[math.random(1, #skins)]
                            until timePassed > skin.minTime

                            -- There is one mroe zombie
                            totalZombies = totalZombies + 1

                            -- Workout where to spawn it (ensure it is within the map bounds)
                            local pos

                            repeat
                                pos = hero:GetOrigin()
                                local ang = math.random() * 2 * math.pi;
                                pos.x = pos.x + math.cos(ang) * SPAWN_DISTANCE
                                pos.y = pos.y + math.sin(ang) * SPAWN_DISTANCE
                            until frota:IsValidPosition(pos)

                            -- Put it on the opposite team
                            local team = ((hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS) and DOTA_TEAM_BADGUYS) or DOTA_TEAM_GOODGUYS

                            -- Spawn it
                            local unit = CreateUnitByName(skin.unit, pos, true, nil, nil, team)

                            -- Stat it up
                            skin.stats(unit, factor, sfactor)

                            -- Make it attack
                            unit:MoveToTargetToAttack(hero)

                            -- Make it expire after 30 seconds
                            unit.expireTime = Time()+30

                            table.insert(info.zombieList, unit)
                        end
                    end
                end)

                -- Run again after a short delay
                return Time()+spawnCheckTime
            end
        })
    end,

    -- Team based stuff
    --[[onHeroSpawned = function(frota, hero)
        -- Note: At this stage, `teamBased` isn't always set!

        -- Grab options
        local options = frota:GetOptions()

        -- Check if it is a team based game
        if options.survivalTeamMode then
            -- Prevent it from attacking enemy heroes
            hero:AddNewModifier(hero, nil, 'modifier_halloween_truce', {})
        end
    end,]]

    -- Cleanup a player
    CleanupPlayer = function(frota, leavingPly)
        -- Cleanup a leaving player
        local playerID = leavingPly:GetPlayerID()

        -- Check if this player had any info
        local info = zombieInfo[playerID]
        if info then
            for k,v in pairs(info.zombieList) do
                -- Check if the entity is still valid
                if IsValidEntity(v) then
                    -- Cleanup
                    v:Remove()
                end
            end

            -- Remove info on this player
            zombieInfo[playerID] = nil
        end

        -- Check for victory
        checkForVictory(frota)
    end,

    -- When a player respawns
    onHeroRespawn = function(frota, hero)
        -- Make this hero revealed
        reveal(hero)
    end,

    -- When they get a new hero
    -- Function to give out heroes
    assignHero = function(frota, ply)
        -- Grab this player's Hero
        local hero = frota:GetActiveHero(ply:GetPlayerID())

        if hero then
            -- Make this hero revealed
            reveal(hero)
        end
    end,

    -- When someone dies, check for victory
    onHeroKilled = function(frota, killedUnit, killerEntity)
        -- Check for victory
        checkForVictory(frota)
    end,

    -- Remove truesight when the game ends
    onGameEnd = function(frota)
        -- Loop over all the players
        frota:LoopOverPlayers(function(ply, playerID)
            -- Grab a hero
            local hero = frota:GetActiveHero(playerID)
            if hero then
                -- Remove it's truesight
                unreveal(hero)
            end
        end)
    end
})