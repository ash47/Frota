local team_runner = 2
local team_striker = 3

local isStriker = {}

local function makeInvoker(frota, ply)
    -- Grab playerID
    local playerID = ply:GetPlayerID()

    -- Store that we are invoker
    isStriker[playerID] = true

    -- Grab the player's original team
    local oTeam = ply:GetTeam()

    -- Become a striker
    ply:__KeyValueFromInt('teamnumber', team_striker)

    -- New Hero
    local hero = ply:ReplaceHeroWith('npc_dota_hero_invoker', 0, 0)
    frota:SetActiveHero(hero)

    -- Change skills
    frota:ApplyBuild(hero, {
        -- We have empty slots so the hot key will match up
        [1] = 'doom_bringer_empty1',
        [2] = 'doom_bringer_empty2',
        [3] = 'rubick_empty1',
        [4] = 'rubick_empty2',
        [5] = 'wisp_empty1',
        [6] = 'ssw_sun_strike'
    })

    -- Level sunstrike
    local ab = hero:FindAbilityByName('ssw_sun_strike')
    if ab then
        ab:SetLevel(1)
    end

    -- Make invulnerable
    hero:AddNewModifier(hero, nil, "modifier_invulnerable", {})

    -- Reset player's team
    ply:__KeyValueFromInt('teamnumber', oTeam)
end

local function makeRunner(frota, ply)
    -- Grab playerID
    local playerID = ply:GetPlayerID()

    -- Store that we are a runner
    isStriker[playerID] = false

    -- Grab the player's original team
    local oTeam = ply:GetTeam()

    -- Set to runner team
    ply:__KeyValueFromInt('teamnumber', team_runner)

    local hero = ply:ReplaceHeroWith(frota:ChooseRandomHero(), 0, 0)
    frota:SetActiveHero(hero)

    -- Reset player team
    ply:__KeyValueFromInt('teamnumber', oTeam)
end

-- Standard Arena PvP
RegisterGamemode('sunstrikewars', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_BOTH,

    assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()

        -- Grab the player's original team
        local oTeam = ply:GetTeam()

        -- Check if they are a striker, or player
        if isStriker[playerID] then
            -- Make them an invoker
            makeInvoker(frota, ply)
        else
            -- Make them a runner
            makeRunner(frota, ply)
        end
    end,

    onHeroKilled = function(frota, killedUnit, killerEntity)
        -- Validate data
        if not killedUnit then return end

        -- Grab player
        local ply = Players:GetPlayer(killedUnit:GetPlayerID())
        if not ply then return end

        -- Make them into an invoker
        makeInvoker(frota, ply)

        -- Check if there is anyone not on the new team
        local allDone = true
        frota:LoopOverPlayers(function(lPly, playerID)
            -- Check team of this hero
            local h = frota:GetActiveHero(playerID)
            if IsValidEntity(h) then
                if h:GetTeam() ~= team_striker then
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
    end,

    -- A list of options for fast gameplay stuff
    options = {
        -- Never respawn
        respawnDelay = -1
    },

    onPickingStart = function(frota)
        -- Reset who is a striker
        isStriker = {}

        -- Enable all vision
        Convars:SetBool('dota_all_vision', true)
    end,

    -- When the game starts
    onGameStart = function(frota)
        -- Pick a random player
        local ply = frota:GetRandomPlayer()

        -- Set them to invoker
        makeInvoker(frota, ply)
    end,

    -- When the game ends
    onGameEnd = function(frota)
        -- Disable WTF
        Convars:SetBool('dota_all_vision', false)
    end
})
