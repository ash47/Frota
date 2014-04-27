-- Initial Delay to refresh first spell
local initialDelay = 0

-- Delay to rfresh each spell after that
local repeatDelay = 0

-- Register the addon
RegisterGamemode('wtf', {
    -- This is an addon
    sort = GAMEMODE_ADDON,

    onGameStart = function(frota)
        -- Create item timer
        frota:CreateTimer('skillRefresh', {
            endTime = Time()+initialDelay,
            callback = function(frota, args)
                -- Refresh Skills
                frota:LoopOverPlayers(function(ply, playerID) 
                    local hero = frota:GetActiveHero(playerID)
                    local playerID = ply:GetPlayerID()
                    frota:RefreshAllSkills(hero)
                end)
                -- Run again after a delay
                return Time() + repeatDelay
            end
        })
    end,
})
