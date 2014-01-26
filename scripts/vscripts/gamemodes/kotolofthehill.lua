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

    onGameStart = function(frota)
    print('running onGameStart')
    print('finished onGameStart')
    end,

    onThink = function(frota, dt)
    print('thinking')
        local controlPointVec = Vec3(0,0,0)
          --  local controlPoint = Entities:FindByName(nil, 'hill_marker_01')
            -- local controlPointVec = controlPoint:GetOrigin()
            local goodUnitsOnPoint = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, controlPointVec, null, 300, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
            local badUnitsOnPoint = FindUnitsInRadius(DOTA_TEAM_BADGUYS, controlPointVec, null, 300, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
            local unitsOnPoint = {}
            for k,v in ipairs(goodUnitsOnPoint) do unitsOnPoint[#unitsOnPoint+1] = v end
            for k,v in ipairs(badUnitsOnPoint) do unitsOnPoint[#unitsOnPoint+1] = v end
            local goodGuysCount = 0
            local badGuysCount = 0
            local tableSize = 0
           
            for k,v in pairs(unitsOnPoint) do
                tableSize = tableSize + 1
            end
     
            for i=1,tableSize do
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
        print('finish thinking')
    end,

    })
