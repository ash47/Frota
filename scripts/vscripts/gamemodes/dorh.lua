-- Defense of Rune Hill
-- Tower Denfese Addon for Frota
-- By Xavier@2014.02

-- change this to multiple starting gold
local testmodeGoldRate = 1

-- Preparation time (in seconds)
local prepTime = 30

-- Time between waves (in seconds)
local timeBetweenWaves = 20

-- How fast units spawn
local spawnInterval = 1

-- How many lives the players start with
local startingLives = 20

-- To store the unit's lastest position and current position
local timePassed = 0
local unitCurrentPosition = {}
local unitLatestPosition = {}
local angryState = {}
local unitCurrentMileStone = {}

-- These are the waypoints units will follow
local wayPointPositions = {
    [1] = Vector(-1120,-1120,0),
    [2] = Vector(490,-1360,0),
    [3] = Vector(2450,-1400,0),
    [4] = Vector(2400,630,0),
    [5] = Vector(2190,2030,0),
    [6] = Vector(40,940,0),
    [7] = Vector(690,260,0),
    [8] = Vector(1450,500,0),
    [9] = Vector(1550,-500,0)
}

-- The actual way points
local wayPoints = {}

-- This store every state of hero wisp will evolute to
local dorhHeroList = {
	[1] = {
		name = 'npc_dota_hero_wisp',
		skills = {
			[1] = {
			name = 'dorh_wisp_blink',
			maxlevel = 1 },
			[2] = {
			name = 'dorh_build_general',
			maxlevel = 1 },
			[3] = {
			name = 'dorh_wisp_slow',
			maxlevel = 4 },
			[4] = {
			name = 'dorh_wisp_evolution',
			maxlevel = 4 },
			[5] = {
			name = 'dorh_wisp_destroy',
			maxlevel = 1 },
			[6] = {
			name = 'dorh_wisp_stun',
			maxlevel = 1 }
		}
	},
	[2] = {
		name = 'npc_dota_hero_keeper_of_the_light',
		skills = {
			[1] = {
			name = 'dorh_wisp_blink',
			maxlevel = 1 },
			[2] = {
			name = 'dorh_build_general',
			maxlevel = 1 },
			[3] = {
			name = 'ogre_magi_bloodlust',
			maxlevel = 4 },
			[4] = {
			name = 'dorh_wisp_evolution',
			maxlevel = 4 },
			[5] = {
			name = 'dorh_wisp_destroy',
			maxlevel = 1 },
			[6] = {
			name = 'beastmaster_inner_beast',
			maxlevel = 4 }
		}
	},
	[3] = {
		name = 'npc_dota_hero_invoker',
		skills = {
			[1] = {
			name = 'dorh_wisp_blink',
			maxlevel = 1 },
			[2] = {
			name = 'dorh_build_general',
			maxlevel = 1 },
			[3] = {
			name = 'ancient_apparition_ice_vortex',
			maxlevel = 4 },
			[4] = {
			name = 'dorh_wisp_evolution',
			maxlevel = 4 },
			[5] = {
			name = 'dorh_wisp_destroy',
			maxlevel = 1 },
			[6] = {
			name = 'troll_warlord_battle_trance',
			maxlevel = 4 }
		}
	},
	[4] = {
		name = 'npc_dota_hero_doom_bringer',
		skills = {
			[1] = {
			name = 'dorh_wisp_blink',
			maxlevel = 1 },
			[2] = {
			name = 'dorh_build_general',
			maxlevel = 1 },
			[3] = {
			name = 'sven_great_cleave',
			maxlevel = 4 },
			[4] = {
			name = 'dorh_wisp_evolution',
			maxlevel = 4 },
			[5] = {
			name = 'dorh_wisp_destroy',
			maxlevel = 1 },
			[6] = {
			name = 'faceless_void_chronosphere',
			maxlevel = 3 }
		}
	}
}

-- Wave data is defined at the very bottom
local waveData

-- Tower data is defined at the very bottom
local towerData

-- Store current Hero state
local evolution_state = {}

-- The current wave we're in
local currentWave = -1

-- Is a wave active?
local waveActive = false

-- A list of all the units spawned during a wave
local waveUnits = {}

-- Function to send message to player via sonsole
local function sendMsg(args)
	if args then
		say(Say(nil, args , false))
	end
end

-- Spawns the waypoints
local function spawnWaypointMarkers()
    -- Loop over each wavepoint
    for k,v in ipairs(wayPointPositions) do
        -- Spawn the marker for radiant to provide the vision of all map
        local unit = CreateUnitByName("npc_dorh_waypoint_marker", v, false, nil, nil, DOTA_TEAM_GOODGUYS)
		-- Make invulnerable
		unit:AddNewModifier(unit, nil, "modifier_invulnerable", {})
        local unit = CreateUnitByName("npc_dorh_waypoint_marker", v, false, nil, nil, DOTA_TEAM_BADGUYS)
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
local function spawnUnit(unitName, points, playerCount)
    -- Spawn the unit at the first waypoint
    local unit = CreateUnitByName(unitName, wayPointPositions[1]+RandomVector(150), true, nil, nil, 1)

    -- Store how many points this unit is worth
    unit.points = points

    --multiple the health
    local multiRate = (( playerCount - 1 ) * 0.8 + 1 )
    unit:SetMaxHealth( multiRate * unit:GetHealth())
    unit:SetHealth( unit:GetMaxHealth() )

    -- Phase the unit -- it shouldn't collide with anything
    --unit:AddNewModifier(unit, nil, "modifier_phased", {})
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
local function setAbilityLevels(hero , _playerID)
    -- Loop over every skill they should have
	currentEvoLevel = evolution_state[_playerID]
    for k,v in pairs(dorhHeroList[currentEvoLevel].skills) do
        -- Check if they have the skill
        local ab = hero:FindAbilityByName(v.name)

        if ab then
			ab:SetLevel(v.maxlevel)
			if v.name == "dorh_wisp_evolution" then
				ab:SetLevel(currentEvoLevel)
			end
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
                local cply = frota:GetPlayerList()

                -- Spawn it
                spawnUnit(unitData.sort, unitData.points, #cply)

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

		-- Restore evolution state of wisp
		for i = 0 , 10 do
			evolution_state[i] = 1
		end
        -- Change heroes
        local hero = PlayerResource:ReplaceHeroWith(playerID, dorhHeroList[evolution_state[playerID]].name, 1000 * testmodeGoldRate, 0)
        frota:SetActiveHero(hero)

        -- Make invulnerable
        hero:AddNewModifier(hero, nil, "modifier_invulnerable", {})

        -- Give building skills
		local abTemp = {}
			for k,v in pairs(dorhHeroList[evolution_state[playerID]].skills) do
				abTemp[k]= v.name
			end
		frota:ApplyBuild(hero, abTemp )

        -- Level it's skills
        setAbilityLevels(hero , playerID)
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

		--[[ Disabled while test
		--PreCache tower data, this will take quite a long time, looking for better way to do this
		for i = 1 , 16 do
			PrecacheUnitByName( towerData[i] )
			if towerData[i] then
				print("SUCCESSFULL PRECACHE")
			end
		end
		Say(nil,COLOR_LGREEN..'Done Loading', false)]]

        --tell how to play
        Say(nil,COLOR_LGREEN..'********************************************************', false)
        Say(nil,COLOR_LGREEN..'*******************'..COLOR_RED..'Defense of RuneHill'..COLOR_LGREEN..'*******************', false)
        Say(nil,COLOR_LGREEN..'*********Defend rune hill from '..#waveData..' waves of enemies********', false)
        Say(nil,COLOR_LGREEN..'******You can summon 30 minions to help you to defend******', false)
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

      -- seconds that unit will begin to be angry when blocked
      local angryTreshold = 1
      timePassed = timePassed + dt
      if timePassed >= 1 then
        for k,v in pairs(waveUnits) do
          -- Validate the unit
          if IsValidEntity(v) then

            -- catch the unit index
            local uIndex = v:entindex()
            unitCurrentPosition[uIndex] = v:GetOrigin()

            -- if angrystate and latest position nil then init it
            if angryState[uIndex] == nil then angryState[uIndex] = 0 end
            if unitLatestPosition[uIndex] == nil then unitLatestPosition[uIndex] = unitCurrentPosition[uIndex] end
            if unitCurrentMileStone[uIndex] ==nil then unitCurrentMileStone[uIndex] = 1 end

            -- if it didnt move
            -- print('distance '..tostring(distance( unitCurrentPosition[uIndex] , unitLatestPosition[uIndex] )))
            if distance( unitCurrentPosition[uIndex] , unitLatestPosition[uIndex] ) <= 1 then
                    -- then becoming angry
                    angryState[uIndex] = angryState[uIndex] + 1

                    if angryState[uIndex] >= angryTreshold then
                      -- when didnt move for 3 secs, then begin to attack
                      ExecuteOrderFromTable({
                        UnitIndex = uIndex,
                        OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
                        -- order to move to next way point
                        Position = wayPointPositions[ unitCurrentMileStone[uIndex]+1 ],
                        Queue = false
                      })
                    end
                  else
                    -- if it begin to move, then its angry begin to vanish, but that will take angryTreshold time
                    angryState[uIndex] = angryState[uIndex] - 1
                    if angryState[uIndex] < 0 then angryState[uIndex] = 0 end
                  end


            -- Store Position 1 sec ago
            unitLatestPosition[uIndex] = unitCurrentPosition[uIndex]
          end
        end

        -- Reset timer
        timePassed =0

      end

      -- order to move through every way points
      for k,v in pairs(waveUnits) do
        -- Validate the unit
        if IsValidEntity(v) then
          for i = 1,#wayPointPositions - 1 do
            -- check every waypoint
            local uIndex = v:entindex()
            unitCurrentPosition[uIndex] = v:GetOrigin()
            if distance(unitCurrentPosition[uIndex], wayPointPositions[i]) < 200 then
              -- close enough to the waypoint,order to move to next way point
              unitCurrentMileStone[uIndex] = i
              ExecuteOrderFromTable({
                UnitIndex = uIndex,
                OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                -- order to move to next way point
                Position = wayPointPositions[ unitCurrentMileStone[uIndex]+1 ],
                Queue = false
              })
            end
          end

          -- allow unit to 'escape'
          local endPoint = wayPointPositions[#wayPointPositions]
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
		local unit = keys.caster
		local ability = keys.ability
		local name = ability:GetAbilityName()
		local cost = ability:GetSpecialValueFor('cost')
		local owner = unit:GetOwner()
		local playerID = (owner.GetPlayerID and owner:GetPlayerID()) or -1

      -- Build a general building
			local gold = PlayerResource:GetGold(playerID)
            if gold < cost then
				Say(nil, COLOR_RED..'NOT ENOUGH GOLD!!!', false)
                unit:Stop()
            end
			-- Make sure they have enough to buy this building
			if gold >= cost then
			end

			if name == 'dorh_wisp_evolution' and evolution_state[playerID] >= 4 then
				Say(nil, COLOR_RED..'ULTIMATE STATE!!!!', false)
                unit:Stop()
			end
			--it's ok to take the gold even there's not enough gold, cost will take and set gold to a -value, then return to player when hero/unit stopped
			PlayerResource:SpendGold(playerID, cost, 0)

    end,

	onDataDrivenChannelInterrupted = function(frota, keys)
        local hero = keys.caster
        local ability = keys.ability
        local name = ability:GetAbilityName()

        if name == 'dorh_build_general' or name:find('dorh_upgrade_') or name == 'dorh_wisp_evolution' then
            local cost = ability:GetSpecialValueFor('cost')
            local owner = hero:GetOwner()
            local playerID = (owner.GetPlayerID and owner:GetPlayerID()) or -1

            -- return the gold
			PlayerResource:SpendGold(playerID, -cost, 0)
        end
	end,

    onDataDrivenChannelSucceeded = function(frota, keys)
		local point = keys.target_points[1]
        local hero = keys.caster
        local ability = keys.ability
        local heroName = hero:GetClassname()
        local name = ability:GetAbilityName()
        local owner = hero:GetOwner()
        local playerID = (owner.GetPlayerID and owner:GetPlayerID()) or -1
        if name ~= 'dorh_build_general' then
          point = hero:GetOrigin()
        end

		local unitOnPoint = FindUnitsInRadius( hero:GetTeam(), point , nil, 1 , DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_OTHER, 0, FIND_ANY_ORDER, false )
		if name == 'dorh_build_general' then
			for _,unit in ipairs(unitOnPoint) do
				unit:SetOwner( hero )
        print('Applying modifier')
        unit:AddNewModifier(unit, nil, "modifier_halloween_truce", {})
			end
		elseif name:find('dorh_upgrade_') then
			for _,unit in ipairs(unitOnPoint) do
				unit:SetOwner( owner )
        unit:AddNewModifier(unit, nil, "modifier_halloween_truce", {})
				if hero then
        -- lol we should spawn the unit , then run script, and remove unit in ability_custom them we should not need this
				UTIL_RemoveImmediate( hero )
				end
			end
		-- evolutionofwisp
		elseif name == 'dorh_wisp_evolution' then
			evolution_state[playerID] = evolution_state[playerID] + 1
			local currentLevel = evolution_state[playerID]
			-- Change heroes
			local gold = PlayerResource:GetGold( playerID )
			local XP = PlayerResource:GetTotalEarnedXP( playerID )
			local hero = PlayerResource:ReplaceHeroWith(playerID, dorhHeroList[currentLevel].name, gold, XP)
			frota:SetActiveHero(hero)

			-- Make invulnerable
			hero:AddNewModifier(hero, nil, "modifier_invulnerable", {})

			-- Make it stronger
			hero:__KeyValueFromInt("AttackDamageMin" , currentLevel * 200 )
			hero:__KeyValueFromInt("AttackDamageMax" , currentLevel * 200 +10 )
			hero:__KeyValueFromFloat("AttackRate" , 1.7-0.5-currentLevel * 0.2)
			hero:__KeyValueFromFloat("AttackAnimationPoint" , 0.3-currentLevel * 0.05)

			-- Give building skills
			local abTemp = {}
			for k,v in pairs(dorhHeroList[currentLevel].skills) do
				abTemp[k]= v.name
			end
			frota:ApplyBuild(hero, abTemp )

			-- Level it's skills
			setAbilityLevels(hero, playerID)
		end
    end,
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
                count = 20,
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
                sort = 'npc_dorh_enemy_beast_master',
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
towerData = {
	[1] = "npc_dorh_tower_base_lvl1",
	[2] = "npc_dorh_tower_base_lvl2",
	[3] = "npc_dorh_tower_base_lvl3",
	[4] = "npc_dorh_tower_base_lvl4",
	[5] = "npc_dorh_tower_aoe_lvl1",
	[6] = "npc_dorh_tower_aoe_lvl2",
	[7] = "npc_dorh_tower_aoe_lvl3",
	[8] = "npc_dorh_tower_aoe_lvl4",
	[9] = "npc_dorh_tower_slow_lvl1",
	[10] = "npc_dorh_tower_slow_lvl2",
	[11] = "npc_dorh_tower_slow_lvl3",
	[12] = "npc_dorh_tower_slow_lvl4",
	[13] = "npc_dorh_tower_dps_lvl1",
	[14] = "npc_dorh_tower_dps_lvl2",
	[15] = "npc_dorh_tower_dps_lvl3",
	[16] = "npc_dorh_tower_dps_lvl4"
}

