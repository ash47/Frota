-- Tiny Wars
RegisterGamemode('tinywars', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_BOTH,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        ply:ReplaceHeroWith('npc_dota_hero_tiny', 2500, 2600)
		
		local playerID = ply:GetPlayerID()
        local hero = Players:GetSelectedHeroEntity(playerID)
		
		-- Apply the build
        frota:ApplyBuild(hero, {
            [1] = 'tiny_wars_avalanche',
            [2] = 'tiny_wars_toss',
            [3] = 'tiny_craggy_exterior',
            [4] = 'tiny_grow'
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
