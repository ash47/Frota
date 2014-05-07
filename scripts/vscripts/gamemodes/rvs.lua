-- Settings
local NUM_STARTING_CREEPS = 3   -- Number of creeps to spawn when the game starts

local CREEPS_PER_KILL = 2       -- Number of creeps to spawn each time a creep is killed

-- This spawns a creep for the enemy team
local function spawnCreepForEnemyTeam(team)
    -- Check which team they were on
    if team == DOTA_TEAM_GOODGUYS then
        -- Spawn a creep for the bad guys
        CreateUnitByName('npc_dota_creep_badguys_melee',Vector(math.random(-1665,-705),math.random(-1215,1345),0) , true, nil, nil, DOTA_TEAM_BADGUYS)
    elseif team == DOTA_TEAM_BADGUYS then
        -- Spawn a creep for the good guys
        CreateUnitByName('npc_dota_creep_goodguys_melee', Vector(math.random(575,1600),math.random(-1215,1345),0) , true, nil, nil, DOTA_TEAM_GOODGUYS)
    end
end

-- This returns true if the entity parsed is a RVS creep
local function isRVSCreep(ent)
    -- Make sure something was parsed
    if ent then
        -- Grab the name of this entity
        local name = ent:GetUnitName()

        -- Check if it is a creep
        if name == 'npc_dota_creep_badguys_melee' or name == 'npc_dota_creep_goodguys_melee' then
            -- Yes, it's safe to assume this is a RVS creep
            return true
        end
    end

    return false
end

-- Regigster Rabbits VS Sheep
RegisterGamemode('rvs', {
    -- This gamemode is for both picking and playing
    sort = GAMEMODE_PLAY,

	-- A list of options for fast gameplay stuff
    options = {
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
            min = 50,

            -- Maximal possible value
            max = 500,

            -- Default vaule (if no one votes)
            def = 200,

            -- Slider tick interval
            tick = 50,

            -- Slider step interval
            step = 50
        }
    },

	--Stuff that happens when the game starts
	onGameStart = function(frota, keys)
		--- Grab options
        local options = frota:GetOptions()

        -- Set the score limit
        frota:SetScoreLimit(options.scoreLimit)

		-- Spawn the starting creeps
		for i=1,NUM_STARTING_CREEPS do
            spawnCreepForEnemyTeam(DOTA_TEAM_GOODGUYS)
            spawnCreepForEnemyTeam(DOTA_TEAM_BADGUYS)
        end

		-- Set the scores to 3 -- there are three creeps on each side
		frota.scoreDire = NUM_STARTING_CREEPS
		frota.scoreRadiant = NUM_STARTING_CREEPS

		--Update score
		frota:UpdateScoreData()
	end,

	--Function that handles dying
	entity_killed = function(frota, keys)
		-- Grab the unit that was killed
		local killedUnit = EntIndexToHScript( keys.entindex_killed )

        -- Make sure something was killed
		if killedUnit then
            -- There is no winner yet
            local winner = -1

            -- Make sure this is a RVS creep
            if isRVSCreep(killedUnit) then
                -- Grab the team the killed unit was on
                local team = killedUnit:GetTeam()

                -- Check which team they were on
                if team == DOTA_TEAM_GOODGUYS then
                    -- The creep that died was on Radiant

                    -- Decrease the number of creeps left for dire to kill
                    frota.scoreDire = frota.scoreDire - 1

                    -- Increase the number of creeps for radiant to kill
                    frota.scoreRadiant = frota.scoreRadiant + CREEPS_PER_KILL

                    -- Check if Radiant has too many creeps
                    if frota.scoreRadiant >= (frota.gamemodeOptions.scoreLimit or -1) then
                        -- Dire Victory
                        winner = DOTA_TEAM_BADGUYS
                    end
                elseif team == DOTA_TEAM_BADGUYS then
                    -- The creep that died was on Dire

                    -- Decrease the number of creeps left for radiant to kill
                    frota.scoreRadiant = frota.scoreRadiant - 1

                    -- Increase the number of creeps for dire to kill
                    frota.scoreDire = frota.scoreDire + CREEPS_PER_KILL

                    -- Check if Dire has too many creeps
                    if frota.scoreDire >= (frota.gamemodeOptions.scoreLimit or -1) then
                        -- Radiant Victory
                        winner = DOTA_TEAM_GOODGUYS
                    end
                else
                    -- WTF did we kill?!?
                    return
                end

                -- Spawn the extra creeps
                for i=1,CREEPS_PER_KILL do
                    spawnCreepForEnemyTeam(team)
                    spawnCreepForEnemyTeam(team)
                end

                -- Update the scores
                frota:UpdateScoreData()

                -- Check if someone won
                if winner ~= -1 then
                    -- Simply end the gamemode
                    frota:EndGamemode()
                end
            end
		end
	end
})
