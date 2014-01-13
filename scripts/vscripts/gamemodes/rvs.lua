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

	--Rabbits vs Sheep
	
local function spawn_radiant_creep ()
	CreateUnitByName('npc_dota_creep_goodguys_melee', Vec3(math.random(575,1600),math.random(-1215,1345),0) , true, nil, nil, DOTA_TEAM_GOODGUYS)
end

local function spawn_dire_creep ()
	CreateUnitByName('npc_dota_creep_badguys_melee',Vec3(math.random(-1665,-705),math.random(-1215,1345),0) , true, nil, nil, DOTA_TEAM_BADGUYS)
end


RegisterGamemode('rvs', {
    -- This gamemode is for both picking and playing
    sort = GAMEMODE_BOTH,
	
	-- List of addons to ignore
--[[
	ignoreAddons = {
	
		wtf = true
		dmMode = true
	
	},
	]]
	
    -- Allow certain picking things
    pickHero = true,
    pickSkills = false,
	

	
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
            max = 100,

            -- Default vaule (if no one votes)
            def = 10,

            -- Slider tick interval
            tick = 10,

            -- Slider step interval
            step = 1
        }
    },
	
	--Stuff that happens when the game starts
	onGameStart = function(frota, keys)
			
		--- Grab options
        local options = frota:GetOptions()

        -- Set the score limit
        frota:SetScoreLimit(options.scoreLimit)
		--Spawn the starting creeps
		spawn_radiant_creep()
		spawn_radiant_creep()
		spawn_radiant_creep()
		
		spawn_dire_creep()
		spawn_dire_creep()
		spawn_dire_creep()
		
		--Add the number of creeps
		frota.scoreDire = frota.scoreDire + 3
		frota.scoreRadiant = frota.scoreRadiant + 3
		
		--Update score
		frota:UpdateScoreData()
	end,
	
	--Function that handles dying
	entity_killed = function(frota, keys)
		-- Proceed to do stuff
		local killedUnit = EntIndexToHScript( keys.entindex_killed )
		local killerEntity = nil
		
		if keys.entindex_attacker ~= nil then
			killerEntity = EntIndexToHScript( keys.entindex_attacker )
		end
		
		local winner = -1
		
		if killedUnit then
			local unitName = killedUnit:GetUnitName()
			if unitName == 'npc_dota_creep_goodguys_melee' then
				spawn_dire_creep()
				spawn_dire_creep()
				
				if frota.scoreDire > 0 then
					frota.scoreDire = frota.scoreDire + - 1
				end
				frota.scoreRadiant = frota.scoreRadiant + 2
				if frota.scoreRadiant >= (frota.gamemodeOptions.scoreLimit or -1) then
					winner = DOTA_TEAM_BADGUYS
				end
				
			elseif unitName == 'npc_dota_creep_badguys_melee' then
				spawn_radiant_creep()
				spawn_radiant_creep()
				spawn_dire_creep()
				
				if frota.scoreRadiant > 0 then
					frota.scoreRadiant = frota.scoreRadiant - 1
				end
				frota.scoreDire = frota.scoreDire + 2
				if frota.scoreDire >= (frota.gamemodeOptions.scoreLimit or -1) then
					winner = DOTA_TEAM_GOODGUYS
				end
				
			end
		end
		
		
		--Finally update score
		frota:UpdateScoreData()
		
		-- Check if there was a winner
		
		if winner ~= -1 then
            -- Reset back to gamemode voting

            frota:EndGamemode()
        end
	end,
	
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

