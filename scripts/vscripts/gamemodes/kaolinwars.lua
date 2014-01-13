-- Earth Spirit Wars
RegisterGamemode('kaolinwars', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PICK,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        -- Change heroes
        local hero = ply:ReplaceHeroWith('npc_dota_hero_earth_spirit', 2500, 2600)
        frota:SetActiveHero(hero)

        -- Apply the build
        frota:ApplyBuild(hero, {
            [1] = 'pure_skill_earth_spirit_boulder_smash',
            [2] = 'pure_skill_earth_spirit_rolling_boulder',
            [3] = 'pure_skill_earth_spirit_geomagnetic_grip',
            [4] = 'pure_skill_earth_spirit_stone_caller',
            [5] = 'pure_skill_earth_spirit_magnetize'
        })
        hero:FindAbilityByName('pure_skill_earth_spirit_stone_caller'):SetLevel(1)
    end,

    -- DM Mode changed our hero
    dmNewHero = function(frota, hero)
        -- Change skills	
        frota:ApplyBuild(hero, {
            [1] = 'pure_skill_earth_spirit_boulder_smash',
            [2] = 'pure_skill_earth_spirit_rolling_boulder',
            [3] = 'pure_skill_earth_spirit_geomagnetic_grip',
            [4] = 'pure_skill_earth_spirit_stone_caller',
            [5] = 'pure_skill_earth_spirit_magnetize'
        })
    end
})