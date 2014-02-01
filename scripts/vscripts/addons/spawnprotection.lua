local function giveInvuln(hero)
    -- Give invuln
    hero:AddNewModifier(hero, nil, 'modifier_invulnerable', {
        duration = 3
    })
end


RegisterGamemode('spawnprotection', {
    -- This is an addon
    sort = GAMEMODE_ADDON,

    -- When a player respawns
    onHeroRespawn = function(frota, hero)
        -- Give this hero invuln
        giveInvuln(hero)
    end,

    -- When they get a new hero
    -- Function to give out heroes
    assignHero = function(frota, ply)
        -- Grab this player's Hero
        local hero = frota:GetActiveHero(ply:GetPlayerID())

        if hero then
            -- Give this hero invuln
            giveInvuln(hero)
        end
    end,
})
