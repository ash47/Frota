RegisterGamemode('kotolofthehill', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PLAY,

        options = {killsScore = false,useScores = true,respawnDelay = 10 }, 
                
                voteOptions = {
        -- Score limit vote
        scoreLimit = {
            -- Range based
            s = VOTE_SORT_RANGE,

            -- Minimal possible value
            min = 3000,

            -- Maximal possible value
            max = 10000,

            -- Default vaule (if no one votes)
            def = 6000,

            -- Slider tick interval
            tick = 1000,

            -- Slider step interval
            step = 500
        }
    },

    onGameStart = function(frota)
    print('running onGameStart')
    print('finished onGameStart')
    end,

    onThink = function(frota, dt)
    print('thinking')
        local controlPointVec = Vec3(0,0,0)
      --  local controlPoint = Entities:FindByName(nil, 'hill_marker_01')
        -- local controlPointVec = controlPoint:GetOrigin()
        local unitsOnPoint = FindUnitsInRadius(DOTA_TEAM_GOODGUYS + DOTA_TEAM_BADGUYS, controlPointVec, null, 300, DOTA_UNIT_TARGET_TEAM_FRIENDLY + DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
        local goodGuysCount = 0
        local badGuysCount = 0
        local tableSize = 0
        
        for k,v in pairs(unitsOnPoint) do
            print(k, v)
            tableSize = tableSize + 1
        end

        for i=1,tableSize do
            print(i)
            local hero = unitsOnPoint[i]
            if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
                goodGuysCount = goodGuysCount + 1
            else
                badGuysCount = badGuysCount + 1
            end
        end

        if goodGuysCount > badGuysCount then
            frota.scoreRadiant = frota.scoreRadiant + 1
            frota:UpdateScoreData()
        elseif goodGuysCount == badGuysCount then
        elseif badGuysCount > goodGuysCount then
            frota.scoreDire = frota.scoreDire + 1
            frota:UpdateScoreData()
        end
        print(goodGuysCount)
        print('finish thinking')
    end,

    })
