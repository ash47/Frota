print('\n\nLoading Frota modules...')

function Dynamic_Wrap( mt, name )
    if Convars:GetFloat( 'developer' ) == 1 then
        local function w(...) return mt[name](...) end
        return w
    else
        return mt[name]
    end
end

-- Module loading system (it reports errors)
local totalErrors = 0
local function loadModule(name)
    local status, err = pcall(function()
        -- Load the module
        require(name)
    end)

    if not status then
        -- Add to the total errors
        totalErrors = totalErrors+1

        -- Tell the user about it
        print('WARNING: '..name..' failed to load!')
        print(err)
    end
end

-- Server side setting of a preset game mode
Convars:RegisterConvar('frota_mode_preset', nil, 'Set to the game mode you want to start exclusively.', FCVAR_PROTECTED)
Convars:RegisterConvar('frota_ban_modes', nil, 'Set to modes banned on this server', FCVAR_PROTECTED)

-- Load Frota
loadModule('util')         -- Utilitiy functions
loadModule('json')         -- Json Library
loadModule('smjs')       -- Interface to D2Ware / sm.js
loadModule('frota')        -- Main frota framework
loadModule('gamemodes')    -- Gamemode framework and small gamemodes/addons

-- Include gamemodes
loadModule('gamemodes/ctftheflag')
loadModule('gamemodes/dorh')
loadModule('gamemodes/invokerwars')
loadModule('gamemodes/kaolinwars')
loadModule('gamemodes/kotolofthehill')
loadModule('gamemodes/kunkkawars')
loadModule('gamemodes/oddball')
loadModule('gamemodes/plage')
loadModule('gamemodes/puckwars')
loadModule('gamemodes/rvs')
--loadModule('gamemodes/sunstrikewars')
loadModule('gamemodes/survival')
loadModule('gamemodes/tinywars')
--loadModule('gamemodes/warlocks')
--loadModule('gamemodes/towerdefence')

-- Include addons
loadModule('addons/fatometer')
loadModule('addons/goldpersecond')
loadModule('addons/luckyitems')
loadModule('addons/spawnprotection')

if totalErrors == 0 then
    -- No loading issues
    print('Loaded Frota modules successfully!\n')
elseif totalErrors == 1 then
    -- One loading error
    print('1 Frota module failed to load!\n')
else
    -- More than one loading error
    print(totalErrors..' Frota modules failed to load!\n')
end


--[[local file = io.open ('dota/addons/Frota/maps/'..GetMapName()..'.gnv', 'r')
local a = file:read('*all')
io.close (file)]]
