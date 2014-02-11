-- Which hero has the gem (nil if none)
local heroWithGem

local function spawnOddBall(frota)
    -- Spawn the creep in the middle of no where
    local vector = Vec3( 0, 0, 0 )
    local unit = CreateUnitByName("npc_dota_neutral_satyr_trickster2", vector, false, nil, nil, DOTA_TEAM_NEUTRALS)

    -- Give the creep the oddball
    unit:AddItem(CreateItem('item_oddball', nil, nil))

    -- Change the unit's HP based on the number of players
    local cply = frota:GetPlayerList()
    unit:SetMaxHealth(#cply * 500)
    unit:SetHealth(5000)
end

RegisterGamemode('oddball', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PLAY,

    -- A list of options for fast gameplay stuff
    options = {
        killsScore = false,
        useScores = true,
        respawnDelay = 15
    },

    -- List of maps this plugin wont work with
    blackList = dotaMapList,

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
        -- Set the score limit
        local options = frota:GetOptions()
        frota:SetScoreLimit(options.scoreLimit)

        -- No one has the gem
        heroWithGem = nil

        -- Create a timer to spawn the creep that holds the oddball
        frota:CreateTimer('oddball_create_timer', {
            -- It will run after 1 second
            endTime = Time() + 1,

            -- Spawn the oddball
            callback = spawnOddBall
        })
    end,

    -- When an item is picked up
    dota_item_picked_up = function(frota, keys)
        -- Grab the hero that picked the item up
        local hero = frota:GetActiveHero(keys.PlayerID)
        if hero then
            -- Default them to not having the oddball
            local hasOddBall = false

            -- Check their inventory for the oddball
            for i=0, 5 do
                -- Grab the item in slot i
                local item = hero:GetItemInSlot(i)

                -- Ensure there is an item in slot i
                if item then
                    -- Check if this item is the oddball
                    if item:GetAbilityName() == 'item_oddball' then
                        -- They have the oddball
                        hasOddBall = true

                        -- Store which hero has the gem
                        heroWithGem = hero

                        -- Make this player revealed
                        hero:AddNewModifier(hero, nil, 'modifier_bloodseeker_thirst_vision' ,nil)

                        break
                    end
                end
            end

            -- If they don't have the oddball
            if not hasOddBall then
                -- If they are revealed, remove that effect
                if hero:HasModifier('modifier_bloodseeker_thirst_vision') == true then
                    hero:RemoveModifierByName('modifier_bloodseeker_thirst_vision')
                end
            end
        end
    end,

    onThink = function(frota, dt)
        -- Check if someone has the gem
        if heroWithGem and IsValidEntity(heroWithGem) then
            -- Check their inventory for the gem
            for i=0,5 do
                -- Check if this item is the oddball
                local item = heroWithGem:GetItemInSlot(i)
                if item and item:GetAbilityName() == 'item_oddball' then
                    -- Give points to this player's team
                    if  heroWithGem:GetTeam() == DOTA_TEAM_GOODGUYS then
                        frota.scoreRadiant = frota.scoreRadiant + 1
                        frota:UpdateScoreData()
                    end
                    if  heroWithGem:GetTeam() == DOTA_TEAM_BADGUYS then
                        frota.scoreDire = frota.scoreDire + 1
                        frota:UpdateScoreData()
                    end

                    -- There can only be one gem -- no need to keep going
                    break
                end
            end
        end
    end,

    -- Make sure the player leaving doesn't have the oddball
    CleanupPlayer = function(frota, leavingPly)
        -- Grab this player's Hero
        local hero = frota:GetActiveHero(leavingPly:GetPlayerID())

        -- Check if they have the gem
        if hero and heroWithGem == hero then
            -- Spawn a new oddball
            spawnOddBall(frota)

            -- No one has the gem anymore
            heroWithGem = nil
        end
    end
})