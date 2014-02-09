local minTeam = 1
local maxTeam = 3
local teamID = minTeam

local heroMap = {}

-- Standard Arena PvP
RegisterGamemode('plage', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_BOTH,

    assignHero = function(frota, ply)
        local heroName = heroMap[teamID]

        -- New Hero
        local playerID = ply:GetPlayerID()
        local hero = PlayerResource:ReplaceHeroWith(playerID, heroName, 2500, 2600)
        frota:SetActiveHero(hero)
        hero:__KeyValueFromInt('teamnumber', teamID)

        -- Give vision
        hero:AddNewModifier(hero, nil, "modifier_bloodseeker_thirst_vision", {})

        -- Change team for the next dude
        teamID = teamID+1
        if teamID > maxTeam then
            teamID = minTeam
        end
    end,

    onHeroKilled = function(frota, killedUnit, killerEntity)
        -- Make sure the arguments parsed correctly
        if not killerEntity or not killedUnit or not killerEntity:IsRealHero() then
            return
        end

        -- Workout the new team to stick this player onto
        local newTeam = killerEntity:GetTeam()
        local newHeroName = heroMap[newTeam]

        -- Make sure we have their original team
        local ply = PlayerResource:GetPlayer(killedUnit:GetPlayerID())
        if not ply then return end

        -- Check if there is anyone not on the new team
        local allDone = true
        frota:LoopOverPlayers(function(lPly, playerID)
            -- Ignore this player
            if lPly == ply then return end

            -- Check team of this hero
            local h = frota:GetActiveHero(playerID)
            if IsValidEntity(h) then
                if h:GetTeam() ~= newTeam then
                    allDone = false
                    return true
                end
            end
        end)

        -- Are we all done?
        if allDone then
            frota:EndGamemode()
            return
        end

        local hero = frota:ChangeHero(killedUnit, newHeroName)
        hero:__KeyValueFromInt('teamnumber', newTeam)

        -- Give vision
        hero:AddNewModifier(hero, nil, "modifier_bloodseeker_thirst_vision", {})

        -- Give gold to killer
        killerEntity:SetGold(killerEntity:GetGold()+250, true)
    end,

    -- A list of options for fast gameplay stuff
    options = {
        -- Never respawn
        respawnDelay = -1
    },

    onPickingStart = function(frota)
        -- Randomise the hero map
        for i = minTeam,maxTeam do
            -- Pick a non meepo hero
            repeat
                heroMap[i] = frota:ChooseRandomHero()
            until heroMap[i] ~= 'npc_dota_hero_meepo'
        end

        -- Enable all vision
        --Convars:SetBool('dota_all_vision', true)
    end,

    -- When the game ends
    onGameEnd = function(frota)
        -- Disable All Vision
        --Convars:SetBool('dota_all_vision', false)
    end
})
