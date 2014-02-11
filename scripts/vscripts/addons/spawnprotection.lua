local function giveInvuln(hero)
    -- Give invuln
    hero:AddNewModifier(hero, nil, 'modifier_invulnerable', {
        duration = 3
    })
end


RegisterGamemode('spawnprotection', {
    -- This is an addon
    sort = GAMEMODE_ADDON,

    -- When a player spawns
    onHeroSpawned = function(frota, hero)
        if hero then
            -- Give this hero invuln
            giveInvuln(hero)
        end
    end
})
