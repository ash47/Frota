RegisterGamemode('kotolofthehill', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PLAY,

    options = {
        killsScore = false,
        useScores = true,
        respawnDelay = 10
    },

    voteOptions = {
        -- Score limit vote
        scoreLimit = {
            -- Range based
            s = VOTE_SORT_RANGE,

            -- Minimal possible value
            min = 1000,

            -- Maximal possible value
            max = 3000,

            -- Default vaule (if no one votes)
            def = 1500,

            -- Slider tick interval
            tick = 500,

            -- Slider step interval
            step = 250
        }
    },

    -- List of maps this plugin works with
    whiteList = {
        arenaotdr = true
    },

    -- List of maps this plugin wont work with
    blackList = dotaMapList,

    onGameStart = function(frota)
        -- Set the score limit
        local options = frota:GetOptions()
        frota:SetScoreLimit(options.scoreLimit)
    end,

    onThink = function(frota, dt)
        -- The position where the hill is
        local controlPointVec = Vector(0,0,0)

        -- The number of good/bad guys on the point
        local goodGuysCount = #FindUnitsInRadius(DOTA_TEAM_GOODGUYS, controlPointVec, null, 300, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
        local badGuysCount = #FindUnitsInRadius(DOTA_TEAM_BADGUYS, controlPointVec, null, 300, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, 0, false)

        -- Check who has more units on the point
        if goodGuysCount > badGuysCount then
            -- More radiant units, increase radiant score
            frota.scoreRadiant = frota.scoreRadiant + 1
            frota:UpdateScoreData()
        elseif goodGuysCount < badGuysCount then
            -- More dire units, increase dire score
            frota.scoreDire = frota.scoreDire + 1
            frota:UpdateScoreData()
        end
    end,

    })
