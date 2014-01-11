-- Invoker Wars
RegisterGamemode('puckwars', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PICK,

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

    -- DM Mode changed our hero
    dmNewHero = function(frota, hero)
        -- Change skills
        frota:ApplyBuild(hero, {
            [1] = 'puck_illusory_orb',
            [2] = 'puckwars_waning_rift',
            [3] = 'puckwars_phase_shift',
            [4] = 'puck_ethereal_jaunt',
            [5] = 'puckwars_dream_coil'
        })
    end
})