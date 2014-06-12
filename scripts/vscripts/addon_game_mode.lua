print("Frota is starting to init...")

local frota = FrotaGameMode:new()
frota:InitGameMode()

-- Error checking
local an = Convars:GetStr('dota_local_addon_game')
local ae = Convars:GetBool('dota_local_addon_enable')

local warnings = ''
if an ~= 'Frota' then
    warnings = warnings..'\nWARNING: dota_local_addon_game is incorrectly set!\nYour server WILL likely split:\n"CreateEvent: event \'afs_timer_update\' not registered."\nThis may cause the vote screen to never appear.'
end
if not ae then
    warnings = warnings..'\n\nWARNING: dota_local_addon_enable appears to be disabled!\nThis could cause issues with your server!'
end

if warnings ~= '' then
    print('@@@@@@@@@@@@@@@@@@@@\n@@@@@@@@@@@@@@@@@@@@\n@@@@@@@@@@@@@@@@@@@@\n\\/ \\/ \\/ \\/ \\/ \\/ \\/\n'..warnings..'\n\n/\\ /\\ /\\ /\\ /\\ /\\ /\\ \n@@@@@@@@@@@@@@@@@@@@\n@@@@@@@@@@@@@@@@@@@@\n@@@@@@@@@@@@@@@@@@@@')
end