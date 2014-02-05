-- Grants Bonus Gold Per Second
RegisterGamemode('goldpersecond', {
    -- This is an addon
    sort = GAMEMODE_ADDON,

    voteOptions = {
        -- Score limit vote
        goldPerSecond = {
            -- Range based
            s = VOTE_SORT_RANGE,

            -- Minimal possible value
            min = 1,

            -- Maximal possible value
            max = 25,

            -- Default vaule (if no one votes)
            def = 1,

            -- Slider tick interval
            tick = 1,

            -- Slider step interval
            step = 1
        }
    },

    onGameStart = function(frota)
        local options = frota:GetOptions()
        local gps = options.goldPerSecond

        frota:CreateTimer('goldPerSecondTimer', {
            endTime = Time()+1,
            callback = function(frota, args)
                -- Loop over every player
                frota:LoopOverPlayers(function(ply, playerID)
                    -- Give this player their gold
                    PlayerResource:SpendGold(playerID, -gps, 0)
                end)

                -- Do it again in a second
                return Time()+1
            end
        })
    end
})
