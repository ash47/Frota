-- Tiny Wars
RegisterGamemode('tinywars', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PICK,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        -- Change heroes
        local hero = ply:ReplaceHeroWith('npc_dota_hero_tiny', 2500, 2600)
        frota:SetActiveHero(hero)

		-- Apply the build
        frota:ApplyBuild(hero, {
            [1] = 'tiny_wars_avalanche',
            [2] = 'tiny_wars_toss',
            [3] = 'tiny_craggy_exterior',
            [4] = 'tiny_grow'
        })
    end,

    -- DM Mode changed our hero
    dmNewHero = function(frota, hero)
        -- Change skills
        frota:ApplyBuild(hero, {
            [1] = 'tiny_wars_avalanche',
            [2] = 'tiny_wars_toss',
            [3] = 'tiny_craggy_exterior',
            [4] = 'tiny_grow'
        })
    end
})
