-- A list of each player's scale
local scale = {}

RegisterGamemode('fatometer', {
    -- Gamemode covers picking and playing
    sort = GAMEMODE_ADDON,

    -- Reset the scale when the game restarts
    onGameStart = function(frota)
        -- Reset scale list
        scale = {}
    end,

    -- When something is killed, update the scale
    entity_killed = function(frota, keys)
        --- Check if there was a killer
        if keys.entindex_attacker ~= nil then
            -- Check if a hero did the killing
            local hero = EntIndexToHScript(keys.entindex_attacker)
            if IsValidEntity(hero) and hero:IsRealHero() then
                -- Grab the playerID
                local playerID = hero:GetPlayerID()

                -- Increase the scale of the killer
                scale[playerID] = (scale[playerID] or 1) + 0.1

                -- Scale the hero
                hero:SetModelScale(scale[playerID], 0)
            end
        end
    end,

    -- DM Mode gave a new hero
    dmNewHero = function(frota, hero)
        -- Grab the playerID
        local playerID = hero:GetPlayerID()

        -- Check if this player has scale info
        if scale[playerID] then
            -- Set the scale of the hero
            hero:SetModelScale(scale[playerID], 0)
        end
    end
})
