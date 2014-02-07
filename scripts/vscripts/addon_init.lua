function Dynamic_Wrap( mt, name )
    if Convars:GetFloat( 'developer' ) == 1 then
        local function w(...) return mt[name](...) end
        return w
    else
        return mt[name]
    end
end

-- Server side setting of a preset game mode
Convars:RegisterConvar('frota_mode_preset', nil, 'Set to the game mode you want to start exclusively.', FCVAR_PROTECTED)
Convars:RegisterConvar('frota_ban_modes', nil, 'Set to modes banned on this server', FCVAR_PROTECTED)

-- Load Frota
require('json')         -- Json Library
require('util')         -- Utilitiy functions
require('frota')        -- Main frota framework
require('gamemodes')    -- Gamemode framework and small gamemodes/addons

-- Include gamemodes
require('gamemodes/ctftheflag')
require('gamemodes/invokerwars')
require('gamemodes/kaolinwars')
require('gamemodes/kotolofthehill')
require('gamemodes/kunkkawars')
require('gamemodes/oddball')
--require('gamemodes/plage')
require('gamemodes/puckwars')
require('gamemodes/rvs')
--require('gamemodes/sunstrikewars')
--require('gamemodes/survival')
require('gamemodes/tinywars')
--require('gamemodes/warlocks')
require('gamemodes/towerdefence')

-- Include addons
require('addons/fatometer')
require('addons/goldpersecond')
require('addons/spawnprotection')

print("\n\nDone Loading!\n\n")
