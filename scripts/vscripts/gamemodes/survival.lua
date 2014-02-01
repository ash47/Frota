-- How often we should check if we need to spawn new zombies
local spawnCheckTime = 1

-- Max number of zombies per person
local ZOMBIES_PER_HERO = 20

-- How far should zombies spawn from the players
local SPAWN_DISTANCE = 1800

local zombieInfo = {}   -- Stores info on each user's zombies

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
            if hero:Team() == DOTA_TEAM_GOODGUYS then
                allDeadRadiant = false
            elseif hero:Team() == DOTA_TEAM_BADGUYS then
                allDeadDire = false
            end
        end
    end)

    if allDeadDire then
        Say(nil, "Dire Loses!", false)
    end

    if allDeadRadiant then
        Say(nil, "Radiant Loses!", false)
    end

    -- If either team has everyone dead
    if allDeadRadiant or allDeadDire then
        -- End the gamemode
        frota:EndGamemode()
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

    onGameStart = function(frota)
        -- Reset zombie info
        zombieInfo = {}

        -- Create a clock to spawn zombies
        frota:CreateTimer('survival_clock', {
            endTime = Time()+spawnCheckTime,
            callback = function(frota, args)
                -- Loop over all the players
                frota:LoopOverPlayers(function(ply, playerID)
                    -- Ensure this player has some info
                    local info = zombieInfo[playerID] or resetPlayerID(playerID)

                    local totalZombies = 0
                    -- Make sure each zombie is following their respective player
                    for k,v in pairs(info.zombieList) do
                        -- Increase total zombies
                        totalZombies = totalZombies+1

                        -- Make it attack it's hero
                        v:MoveToTargetToAttack(hero)
                    end

                    -- Check if they don't have enough zombies
                    if totalZombies < ZOMBIES_PER_HERO then
                        -- Grab their hero, make sure it exists, and is alive
                        local hero = frota:GetActiveHero(playerID)
                        if hero and hero:IsAlive() then
                            -- Workout where to spawn it
                            local pos = hero:GetOrigin()
                            local ang = math.random() * 2 * math.pi;
                            pos.x = pos.x + math.cos(ang) * SPAWN_DISTANCE
                            pos.y = pos.y + math.sin(ang) * SPAWN_DISTANCE

                            -- Put it on the opposite team
                            local team = ((hero:GetTeam() == DOTA_TEAM_GOODGUYS) and DOTA_TEAM_BADGUYS) or DOTA_TEAM_GOODGUYS

                            -- Spawn it
                            local unit = CreateUnitByName('npc_dota_unit_undying_zombie', pos, true, nil, nil, team)

                            -- Make it attack
                            unit:MoveToTargetToAttack(hero)

                            table.insert(info.zombieList, unit)
                        end
                    end
                end)

                -- Run again after a short delay
                return Time()+spawnCheckTime
            end
        })


    end,

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

    -- When someone dies, check for victory
    onHeroKilled = function(frota, killedUnit, killerEntity)
        -- Check for victory
        checkForVictory(frota)
    end
})