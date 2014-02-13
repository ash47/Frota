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

--[[
ent - an entity to set a netprop of
prop - the string name of the prop to set
value - the value (only accepts int/float) you want to set
index - OPTIONAL: This is the array index of the netprop you want to access
]]
function smjsSetNetprop(ent, prop, value, index)
    if SMJS_LOADED then
        -- Validate entity
        if not IsValidEntity(ent) then
            print('CAN NOT SET NETPROP: INVALID ENTITY!')
            return false
        end

        if index then
            -- Send to SMJS
            SendToServerConsole('smjsnetprop '..ent:entindex()..' '..prop..' '..value..' '..index)
        else
            -- Send to SMJS
            SendToServerConsole('smjsnetprop '..ent:entindex()..' '..prop..' '..value)
        end

        -- It worked
        return true
    end

    -- Failure
    return false
end

function smjsPrintNetprop(ent, prop, index)
    if SMJS_LOADED then
        -- Validate entity
        if not IsValidEntity(ent) then
            print('CAN NOT SET NETPROP: INVALID ENTITY!')
            return false
        end

        if index then
            -- Send to SMJS
            SendToServerConsole('smjsprintnetprop '..ent:entindex()..' '..prop..' '..index)
        else
            -- Send to SMJS
            SendToServerConsole('smjsprintnetprop '..ent:entindex()..' '..prop)
        end

        -- It worked
        return true
    end

    -- Failure
    return false
end

--[[ Function to get netprops
ent - the entity you want to get a netprop from
prop - the name of the prop
index - OPTIONAL: the array index to reference (don't parse nil, just use 3 args if you don't need this!)
callback - function(value) to call once the netprop is found

NOTE: This function is asynchronous -- it wont run your code as soon as it is called!
]]
local netpropCallBacks = {}
local netpropCallBackID = 1
function smjsGetNetprop(ent, prop, index, callback)
    if SMJS_LOADED then
        -- Validate entity
        if not IsValidEntity(ent) then
            print('CAN NOT SET NETPROP: INVALID ENTITY!')
            return false
        end

        -- Grab callback ID
        local callbackID = netpropCallBackID
        netpropCallBackID = netpropCallBackID + 1

        -- Grab callback
        if not callback then
            callback = index
            index = nil
        end

        -- Store callback
        netpropCallBacks[callbackID] = callback

        if index then
            -- Send to SMJS
            SendToServerConsole('smjsgetnetprop '..callbackID..' '..ent:entindex()..' '..prop..' '..index)
        else
            -- Send to SMJS
            SendToServerConsole('smjsgetnetprop '..callbackID..' '..ent:entindex()..' '..prop)
        end

        -- It worked
        return true
    end

    -- Failure
    return false
end

-- sm.js sent us a netprop
Convars:RegisterCommand('frota_pass_netprop', function(command, callbackID, netprop)
    -- Check if the server ran it
    if not Convars:GetCommandClient() then
        -- We use numbers for callbackIDs
        callbackID = tonumber(callbackID)

        -- See if we can find the callback
        local callback = netpropCallBacks[callbackID]
        if callback then
            -- Run callback
            callback(netprop)

            -- Remove reference
            netpropCallBacks[callbackID] = nil
        else
            print('Failed to find callback for ID '..callbackID)
            PrintTable(netpropCallBacks)
            print('\n\n\n')
        end
    end
end, 'sm.js sent us a netprop', 0)
