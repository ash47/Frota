-- Kunkka Wars
RegisterGamemode('kunkkawars', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PICK,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        -- Change heroes
        local hero = ply:ReplaceHeroWith('npc_dota_hero_kunkka', 2500, 2600)
        frota:SetActiveHero(hero)

		-- Apply the build
        frota:ApplyBuild(hero, {
            [1] = 'kunkka_wars_torrent',
            [2] = 'kunkka_wars_kunkka_rum',
            [3] = 'kunkka_wars_x_marks_the_spot',
			[4] = 'kunkka_wars_ghost_ship'
        })
    end,

    -- DM Mode changed our hero
    dmNewHero = function(frota, hero)
        -- Change skills
        frota:ApplyBuild(hero, {
            [1] = 'kunkka_wars_torrent',
            [2] = 'kunkka_wars_kunkka_rum',
            [3] = 'kunkka_wars_x_marks_the_spot',
			[4] = 'kunkka_wars_ghost_ship'
        })
    end
})
