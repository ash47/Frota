-- Invoker Wars
RegisterGamemode('INVOKERWARZ', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PICK,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        -- Change heroes
        local hero = ply:ReplaceHeroWith('npc_dota_hero_invoker', 2500, 2600)
        frota:SetActiveHero(hero)

        -- Apply custom invoker skills
        frota:ApplyBuild(hero, {
            [1] = 'invoker_wars_sun_strike',
            [2] = 'invoker_wars_deafening_blast',
            [3] = 'invoker_wars_chaos_meteor',
            [4] = 'invoker_wars_leap',
            [5] = 'attribute_bonus'
        })
    end,

    -- DM Mode changed our hero
    dmNewHero = function(frota, hero)
        -- Change skills
        frota:ApplyBuild(hero, {
            [1] = 'invoker_wars_sun_strike',
            [2] = 'invoker_wars_deafening_blast',
            [3] = 'invoker_wars_chaos_meteor',
            [4] = 'invoker_wars_leap',
            [5] = 'attribute_bonus'
        })
    end
})