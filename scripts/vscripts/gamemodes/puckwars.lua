-- Invoker Wars
RegisterGamemode('puckwars', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_BOTH,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        -- Change heroes
        ply:ReplaceHeroWith('npc_dota_hero_puck', 2500, 2600)

        local playerID = ply:GetPlayerID()
        local hero = Players:GetSelectedHeroEntity(playerID)

        -- Apply custom invoker skills
        frota:ApplyBuild(hero, {
            [1] = 'puck_illusory_orb',
            [2] = 'puckwars_waning_rift',
            [3] = 'puckwars_phase_shift',
            [4] = 'puck_ethereal_jaunt',
            [5] = 'puckwars_dream_coil'
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