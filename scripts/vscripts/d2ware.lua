-- When a user tries to put a skill into a slot
Convars:RegisterCommand('d2wareSettings', function(command, picking, gameplay, freeBlinkDagger, bonusGoldPerSecond, noBuying, fatMeter, unlimitedMana, spawnProtection, luckyItems)
    -- Check if the server ran it
    if not Convars:GetCommandClient() then
        -- Check if we should force gamemodes
        if picking and picking ~= '-' and picking ~= '' then
            -- Store settings from D2Ware
            d2wareSettings = {
                -- Picking mode
                picking = picking,

                -- Gameplay mode
                gameplay = gameplay,

                -- Addons
                freeBlinkDagger = tonumber(freeBlinkDagger) == 1,
                goldpersecond = tonumber(bonusGoldPerSecond) > 0,
                noBuying = tonumber(noBuying) == 1,
                fatometer = tonumber(fatMeter) == 1,
                unlimitedMana = tonumber(unlimitedMana) == 1,
                spawnprotection = tonumber(spawnProtection) == 1,
                luckyitems = tonumber(luckyItems) == 1,

                -- Settings
                goldPerSecond = tonumber(bonusGoldPerSecond)
            }
        end

        -- Store that we loaded smjs
        SMJS_LOADED = true
    end
end, 'D2Ware is sending us stuff', 0)
