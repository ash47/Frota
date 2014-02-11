-- A list of each player's scale
local scale = {}

RegisterGamemode('fatometer', {
    -- This is an addon
    sort = GAMEMODE_ADDON,

    -- Reset the scale when the game restarts
    onGameStart = function(frota)
        -- Reset scale list
        scale = {}
    end,

    -- When something is killed, update the scale
    entity_killed = function(frota, keys)
        -- Grab the unit that was killed
        local killedUnit = EntIndexToHScript(keys.entindex_killed)

        -- Grab the dude that died
        if killedUnit then
            -- Check if it was a hero
            if IsValidEntity(killedUnit) and killedUnit:IsRealHero() then
                -- Grab the playerID
                local playerID = killedUnit:GetPlayerID()

                -- Lose 1/3 of the size
                scale[playerID] = (scale[playerID] or frota:GetDefaultHeroScale(killedUnit:GetClassname())) * 2/3

				-- Limit scale
             	local upperLimit = frota:GetDefaultHeroScale(killedUnit:GetClassname()) * 3
             	local lowerLimit = frota:GetDefaultHeroScale(killedUnit:GetClassname()) / 3

             	if scale[playerID] > upperLimit then
                 	scale[playerID] = upperLimit
             	elseif scale[playerID] < lowerLimit then
                 	scale[playerID] = lowerLimit
             	end

                -- Scale the hero
                killedUnit:SetModelScale(scale[playerID], 0)
            end
        end

        --- Check if there was a killer
        if keys.entindex_attacker ~= nil then
            -- Check if a hero did the killing
            local hero = EntIndexToHScript(keys.entindex_attacker)
            if IsValidEntity(hero) and hero:IsRealHero() then
                -- Grab the playerID
                local playerID = hero:GetPlayerID()

                -- Increase the scale of the killer
                scale[playerID] = (scale[playerID] or frota:GetDefaultHeroScale(hero:GetClassname())) + 0.01

                -- Limit scale to 3
                local limit = frota:GetDefaultHeroScale(hero:GetClassname()) * 3
                if scale[playerID] > limit then
                    scale[playerID] = limit
                end

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
