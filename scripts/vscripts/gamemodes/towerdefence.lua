local buildSkills = {
    [1] = 'td_build_general'
}

-- Tiny Wars
RegisterGamemode('towerdefence', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_BOTH,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()

        -- Change heroes
        local hero = PlayerResource:ReplaceHeroWith(playerID, 'npc_dota_hero_wisp', 1000, 0)
        frota:SetActiveHero(hero)

		-- Apply the build
        frota:ApplyBuild(hero, buildSkills)

        -- Level up skills
        for k,v in pairs(buildSkills) do
            local ab = hero:FindAbilityByName(v)
            if ab then
                ab:SetLevel(1)
            end
        end

        -- Make invulnerable
        hero:AddNewModifier(hero, nil, "modifier_invulnerable", {})
    end,

    onGameStart = function(frota)

    end,

    onDataDrivenSpellStart = function(frota, keys)
        local cost = 50

        local point = keys.target_points[1]
        local hero = keys.caster
        local ability = keys.ability

        local playerID = hero:GetPlayerID()



        -- Grab how much gold this user has
        local gold = PlayerResource:GetGold(playerID)

        -- Make sure they have enough to buy this building
        if gold >= cost then
            -- Take the gold
            PlayerResource:SpendGold(playerID, cost, 0)

            -- Build the building
            local unit = CreateUnitByName("npc_dota_td_", point, false, nil, nil, hero:GetTeam())
        end
    end
})
