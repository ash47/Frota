-- D2Ware passing settings command
Convars:RegisterCommand('d2wareSettings', function(command, picking, gameplay, freeBlinkDagger, bonusGoldPerSecond, noBuying, fatMeter, unlimitedMana, spawnProtection, luckyItems, wtf)
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
                wtf = tonumber(wtf) == 1,

                -- Settings
                goldPerSecond = tonumber(bonusGoldPerSecond)
            }
        end

        -- Store that we loaded smjs
        SMJS_LOADED = true
    end
end, 'D2Ware is sending us stuff', 0)

-- Command to register sm.js
Convars:RegisterCommand('registersmjs', function()
    -- Check if the server ran it
    if not Convars:GetCommandClient() then
        -- Store that we loaded smjs
        SMJS_LOADED = true
    end
end, 'sm.js was register', 0)

function smjsSetBool(name, bool)
    if SMJS_LOADED then
        -- Convert to useable form
        local ans = 'true'
        if not bool then
            ans = 'false'
        end

        -- Send to SMJS
        SendToServerConsole('smjsconvarbool '..name..' '..ans)

        -- It worked
        return true
    end

    -- Failure
    return false
end

function smjsSetInt(name, int)
    if SMJS_LOADED then
        -- Send to SMJS
        SendToServerConsole('smjsconvarint '..name..' '..int)

        -- It worked
        return true
    end

    -- Failure
    return false
end

function smjsSetString(name, str)
    if SMJS_LOADED then
        -- Send to SMJS
        SendToServerConsole('smjsconvarint '..name..' '..str)

        -- It worked
        return true
    end

    -- Failure
    return false
end

function smjsSetNetprop(ent, prop, index, value)
    -- Validate entity
    if not IsValidEntity(ent) then
        return false
    end

    if SMJS_LOADED then
        if value then
            -- Send to SMJS
            SendToServerConsole('smjsnetprop '..ent:entindex()..' '..prop..' '..index..' '..value)
        else
            -- Send to SMJS
            SendToServerConsole('smjsnetprop '..ent:entindex()..' '..prop..' '..index)
        end

        -- It worked
        return true
    end

    -- Failure
    return false
end