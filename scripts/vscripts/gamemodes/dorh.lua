-- Defense of Rune Hill
-- Tower Denfese Addon for Frota
-- By Xavier@2014.02

-- Preparation time (in seconds)
local prepTime = 10

-- Time between waves (in seconds)
local timeBetweenWaves = 5

-- How fast units spawn
local spawnInterval = 0.5

-- How many lives the players start with
local startingLives = 20

-- These are the waypoints units will follow
local wayPointPositions = {
    [1] = Vec3(-1120,-1120,0),
    [2] = Vec3(490,-1360,0),
    [3] = Vec3(2450,-1400,0),
    [4] = Vec3(2400,630,0),
    [5] = Vec3(2190,2030,0),
    [6] = Vec3(40,940,0),
    [7] = Vec3(690,260,0),
    [8] = Vec3(1450,500,0),
    [9] = Vec3(1550,-500,0)
}

-- The actual way points
local wayPoints = {}

-- These are the skills everyone in dorh will get
local dorhSkills = {
    [1] = 'dorh_wisp_blink',
    [2] = 'dorh_build_general',
    [3] = 'dorh_wisp_slow',
    [4] = 'dorh_wisp_passive',
    [5] = 'dorh_wisp_destroy',
    [6] = 'dorh_wisp_stun'
}

-- Wave data is defined at the very bottom
local waveData

-- The current wave we're in
local currentWave = -1

-- Is a wave active?
local waveActive = false

-- A list of all the units spawned during a wave
local waveUnits = {}

-- Spawns the waypoints
local function spawnWaypointMarkers()
    -- Loop over each wavepoint
    for k,v in ipairs(wayPointPositions) do
        -- Spawn the marker
        local unit = CreateUnitByName("npc_dorh_waypoint_marker", v, false, nil, nil, DOTA_TEAM_NOTEAM)

        -- Make invulnerable
        unit:AddNewModifier(unit, nil, "modifier_invulnerable", {})

        -- Spawn a waypoint
        local wayPoint = Entities:CreateByClassname('path_corner')
        wayPoint:SetOrigin(v)
        wayPoint:__KeyValueFromString('targetname', 'dorh_target_'..k)
        wayPoints[k] = wayPoint
    end

    for i=1, #wayPoints-1 do
        local wayPoint = wayPoints[i]
        wayPoint:__KeyValueFromString('target', 'dorh_target_'..i+1)
    end
end

-- Spawns a unit, and makes it march towards the end
local function spawnUnit(unitName, points)
    -- Spawn the unit at the first waypoint
    local unit = CreateUnitByName(unitName, wayPointPositions[1]+RandomVector(150), true, nil, nil, 1)

    -- Store how many points this unit is worth
    unit.points = points

    -- Phase the unit -- it shouldn't collide with anything
    --unit:AddNewModifier(unit, nil, "modifier_phased", {})

    unit:SetMustReachEachGoalEntity(true)
    unit:SetInitialGoalEntity(wayPoints[2])

    -- Make it march towards the checkpoints
    --[[for i = 2, #wayPointPositions do
        -- Grab this waypoint
        local pos = wayPointPositions[i]

        -- Queue a march towards the next position
        ExecuteOrderFromTable({
            UnitIndex = unit:entindex(),
            OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            Position = pos,
            Queue = true
        })
    end]]



    -- Store this as an active unit
    table.insert(waveUnits, unit)
end

-- Sets the correct levels for all the skills
local function setAbilityLevels(hero)
    -- Loop over every skill they should have
    for k,v in pairs(dorhSkills) do
        -- Check if they have the skill
        local ab = hero:FindAbilityByName(v)
        if ab then
            -- Set it to level 1
            ab:SetLevel(1)
        end
    end
end

-- Cleanup any lose wave units
local function clearWaveUnits()
    -- While there are still units alive
    while #waveUnits > 0 do
        -- Grab and remove the first unit
        local unit = table.remove(waveUnits, 1)

        -- Check if it is alive
        if IsValidEntity(unit) then
            -- Remove the unit
            unit:Remove()
        end
    end
end

-- Starts a wave
local function startWave(waveNumber)
    -- Grab the data for this wave
    local data = waveData[waveNumber]

    -- Validate the wave number
    if not data then
        print('You tried to start an invalid wave '..waveNumber)
        return
    end

    -- Store the current wave
    currentWave = waveNumber

    -- Cleanup any old wave units
    clearWaveUnits()

    -- A list of things to spawn
    local toSpawn = {}

    -- Build the list of things to spawn
    for k,v in pairs(data.units) do
        for i=1,v.count do
            table.insert(toSpawn, {
                sort = v.sort,
                points = v.points
            })
        end
    end

    -- Grab a reference to frota
    local frota = GetFrota()

    -- Set dire's score to the number of units remaining
    frota.scoreDire = #toSpawn
    frota:UpdateScoreData()

    -- Create a timer to spawn stuff
    frota:CreateTimer('dorhSpawnTimer', {
        endTime = Time() + spawnInterval,
        callback = function(frota, args)
            -- Check if there is anything left to spawn
            if #toSpawn > 0 then
                -- Grab the next unit to spawn
                local unitData = table.remove(toSpawn, 1)

                -- Spawn it
                spawnUnit(unitData.sort, unitData.points)

                -- Check if there is still something left to spawn
                if #toSpawn > 0 then
                    -- Run this again after a delay
                    return Time() + spawnInterval
                end
            end
        end
    })

    -- Cleanup timers
    frota:RemoveTimer('dorhPreTimer')
    frota:RemoveTimer('dorhWaveTimer')

    -- Tell everyone which wave was started
    Say(nil, COLOR_LGREEN..'Wave '..COLOR_RED..waveNumber..COLOR_LGREEN..' Started!', false)

    -- Store that there is a wave active
    waveActive = true
end

function endWave(startNextWave)
    -- There is no longer a wave active
    waveActive = false

    -- Cleanup any lose wave units
    clearWaveUnits()

    -- Tell users this wave is over
    Say(nil, COLOR_LGREEN..'Wave complete!', false)

    -- Should we start the next wave?
    if startNextWave then
        -- Grab a reference to frota
        local frota = GetFrota()

        -- Grab the data for the next wave
        local data = waveData[currentWave+1]

        -- Check if the next wave exists
        if data then
            -- Tell users when the next wave will start
            Say(nil, COLOR_LGREEN..'Wave '..COLOR_RED..tostring(currentWave+1)..COLOR_LGREEN..' starts in '..tostring(timeBetweenWaves)..' seconds!', false)

            -- Check if this wave has a hint
            if data.waveHint then
                -- Say the hint
                Say(nil, data.waveHint, false)
            end

            -- Create the timer to start the next wave
            frota:CreateTimer('dorhWaveTimer', {
                endTime = Time() + timeBetweenWaves + (data.bonusTime or 0),
                callback = function(frota, args)
                    -- Start next wave
                    startWave(currentWave+1)
                end,
                text = "#dorh_next_wave_timer",
                send = true
            })
        else
            -- No valid wave found -- they must have won
            frota:EndGamemode()
        end
    end
end

-- Checks if a wave should end
local function checkWaveStatus()
    -- Make sure there is a wave active
    if waveActive then
        -- Check score
        local frota = GetFrota()
        if frota.scoreRadiant <= 0 then
            -- Tell them they lost
            Say(nil, COLOR_LGREEN..'You lose, loser!', false)

            -- Game over
            frota:EndGamemode()
            return
        end

        -- Check if no units remain
        if #waveUnits == 0 then
            -- End the current wave
            endWave(true)
        end
    end
end

-- Returns the distance between two points
local function distance(a, b)
    -- Pythagorian distance
    local xx = (a.x-b.x)
    local yy = (a.y-b.y)

    return math.sqrt(xx*xx + yy*yy)
end

local function attemptToBuy(playerID, cost, callback)
    -- Grab how much gold this user has
    local gold = PlayerResource:GetGold(playerID)

    -- Make sure they have enough to buy this building
    if gold >= cost then
        -- Take the gold
        PlayerResource:SpendGold(playerID, cost, 0)

        -- Run the callback
        callback()

        return true
    end

    return false
end

local function setUpgradeLevel(unit, name, level)
    local ab = unit:FindAbilityByName(name)
    if ab then
        ab:SetLevel(level)
        return true
    end

    return false
end

-- Register the gamemode itself
RegisterGamemode('dorh', {
    -- Gamemode controls both picking and playing
    sort = GAMEMODE_BOTH,

    -- A list of options for fast gameplay stuff
    options = {
        killsScore = false, -- Kills don't do anything
        useScores = true,   -- This gamemode does use scores
        respawnDelay = 1    -- Pretty instant respawn (players shouldnt die anyways)
    },

    -- List of addons that are compatible
    compatibleAddons = {
        -- Don't load any addons
    },

    -- List of maps this plugin works with
    whiteList = {
        runehill = true
    },

    assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()

        -- Change heroes
        local hero = PlayerResource:ReplaceHeroWith(playerID, 'npc_dota_hero_wisp', 1000, 0)
        frota:SetActiveHero(hero)

        -- Make invulnerable
        hero:AddNewModifier(hero, nil, "modifier_invulnerable", {})

        -- Give building skills
        frota:ApplyBuild(hero, dorhSkills)

        -- Level it's skills
        setAbilityLevels(hero)
    end,

    onGameStart = function(frota)
        -- Spawn way point markers on the ground
        spawnWaypointMarkers()

        -- Reset vars
        currentWave = 1
        waveActive = false

        -- Cleanup any lose wave units
        clearWaveUnits()

        -- Store the amount of lives and units
        frota.scoreRadiant = startingLives
        frota.scoreDire = 0
        frota:UpdateScoreData()

        --tell how to play
        Say(nil,COLOR_LGREEN..'********************************************************', false)
        Say(nil,COLOR_LGREEN..'*******************'..COLOR_RED..'Defense of RuneHill'..COLOR_LGREEN..'*******************', false)
        Say(nil,COLOR_LGREEN..'*********Defend rune hill from '..#waveData..' waves of enemies********', false)
        Say(nil,COLOR_LGREEN..'******You can summon 30 minions to help you to defend*******', false)
        Say(nil,COLOR_LGREEN..'****The first wave comes in '..COLOR_RED..prepTime..COLOR_LGREEN..' seconds, GET PREPARED !*****', false)
        Say(nil,COLOR_LGREEN..'********************************************************', false)

        -- Create the preparation timer
        frota:CreateTimer('dorhPreTimer', {
            endTime = Time() + prepTime,
            callback = function(frota, args)
                -- Start the first wave
                startWave(1)
            end,
            text = "#dorh_prep_time",
            send = true
        })
    end,

    -- When the game ends
    onGameEnd = function(frota)
        -- Cleanup any leftovers
        clearWaveUnits()
    end,

    -- Checking for units 'escaping'
    onThink = function(frota, dt)
        -- Allow units to 'escape'
        local endPoint = wayPointPositions[#wayPointPositions]
        for k,v in pairs(waveUnits) do
            -- Validate the unit
            if IsValidEntity(v) then
                -- Check how close this unit is to the end
                if distance(v:GetOrigin(), endPoint) < 200 then
                    -- Close enough, kill it
                    local points = v.points or 1

                    -- Update the scores
                    frota.scoreDire = frota.scoreDire - 1
                    frota.scoreRadiant = frota.scoreRadiant - points
                    frota:UpdateScoreData()

                    -- Remove this unit
                    table.remove(waveUnits, k)
                    v:ForceKill(false)

                    -- Check if we've won the round
                    checkWaveStatus()
                end
            end
        end
    end,

    -- Check if the round should end
    entity_killed = function(frota, keys)
        -- Grab the unit that was killed
        local killedUnit = EntIndexToHScript(keys.entindex_killed)

        -- Make sure something was killed
        if killedUnit then
            -- See if this was one of our wave units
            for k,v in pairs(waveUnits) do
                if killedUnit == v then
                    -- Yep, remove it from the list
                    table.remove(waveUnits, k)

                    -- Lower dire's score (the amount of units left to kill)
                    frota.scoreDire = frota.scoreDire - 1
                    frota:UpdateScoreData()

                    -- Check if we've won the round
                    checkWaveStatus()

                    -- Done
                    return
                end
            end
        end
    end,

    -- Buying of towers
    onDataDrivenSpellStart = function(frota, keys)
        local hero = keys.caster
        local ability = keys.ability
        local name = ability:GetAbilityName()

        if name == 'dorh_build_general' or name:find('dorh_upgrade_') then
            local cost = ability:GetSpecialValueFor('cost')
            local owner = hero:GetOwner()
            local playerID = (owner.GetPlayerID and owner:GetPlayerID()) or -1

            -- Grab how much gold this user has
            local gold = PlayerResource:GetGold(playerID)

            -- Make sure they have enough to buy this building
            if gold < cost then
                -- Nope, stop the channel
                hero:Stop()
            end
        end
    end,

    onDataDrivenChannelSucceeded = function(frota, keys)
        local point = keys.target_points[1]
        local hero = keys.caster
        local ability = keys.ability
        local heroName = hero:GetClassname()
        local name = ability:GetAbilityName()

        local cost = ability:GetSpecialValueFor('cost')
        local owner = hero:GetOwner()

        local playerID = (owner.GetPlayerID and owner:GetPlayerID()) or -1
        local ply = PlayerResource:GetPlayer(playerID)

        if name == 'dorh_build_general' then
            -- Build a general building
            attemptToBuy(playerID, cost, function()
                -- Build the building
                local unit = CreateUnitByName("npc_dorh_tower_general", point, true, hero, hero, hero:GetTeam())
                unit:SetOwner(hero)
                setUpgradeLevel(unit, 'dorh_upgrade_tower_base', 1)
            end)
        elseif name == 'dorh_upgrade_tower_base' then
            -- General Upgrade
            attemptToBuy(playerID, cost, function()
                if heroName == 'npc_dorh_tower_general' then
                    local unit = CreateUnitByName("npc_dorh_tower_base_lvl1", hero:GetOrigin(), false, hero, hero, hero:GetTeam())
                    unit:SetOwner(owner)
                    setUpgradeLevel(unit, 'dorh_upgrade_tower_base', 2)
                    hero:Remove()
                end
            end)
        end
    end
})

-- This should be moved into a KV file
waveData = {
    -- Wave 1
    [1] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_gycrophter',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 2
    [2] = {
        waveHint = COLOR_LGREEN..'2nd Wave Hint',
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_legion',
                count = 500,
                points = 1
            }
        }
    },

    -- Wave 3
    [3] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_tinker',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 4
    [4] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_bounty_hunter',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 5
    [5] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_alchemist',
                count = 1,
                points = 5
            }
        }
    },

    -- Wave 6
    [6] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_alchemist',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 7
    [7] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_furion',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 8
    [8] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_enchant',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 9
    [9] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_brood_mother',
                count = 1,
                points = 1
            }
        }
    },

    -- Wave 10
    [10] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_slardar',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 11
    [11] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_tide_hunter',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 12
    [12] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_nage_siren',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 13
    [13] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_slark',
                count = 1,
                points = 1
            }
        }
    },

    -- Wave 14
    [14] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_ember_spirit',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 15
    [15] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_lina',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 16
    [16] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_batridder',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 17
    [17] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_doom',
                count = 1,
                points = 1
            }
        }
    },

    -- Wave 18
    [18] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_tiny',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 19
    [19] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_sandking',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 20
    [20] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_eldertitan',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 21
    [21] = {
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_earth_spirit',
                count = 20,
                points = 1
            }
        }
    },

    -- Wave 22
    [22] = {
        waveHint = 'Final Boss, THE ROSHAN is comming! You have a bonus of 60 seconds to get well prepared!',
        bonusTime = 60,
        units = {
            [1] = {
                sort = 'npc_dorh_enemy_roshan',
                count = 1,
                points = 20
            }
        }
    }
}
