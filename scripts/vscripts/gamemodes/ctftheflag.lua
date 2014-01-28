RegisterGamemode('ctftheflag', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_PLAY,
 
        options = {killsScore = false,useScores = true,respawnDelay = 10 },
               
                voteOptions = {
        -- Score limit vote
        scoreLimit = {
            -- Range based
            s = VOTE_SORT_RANGE,
 
            -- Minimal possible value
            min = 5,
 
            -- Maximal possible value
            max = 15,
 
            -- Default vaule (if no one votes)
            def = 10,
 
            -- Slider tick interval
            tick = 5,
 
            -- Slider step interval
            step = 1
        }
    },
 
    onGameStart = function(frota)
    print('running onGameStart')
    local heroWithFlag = nil
    local heroWithDireFlag = nil
    spawnDireFlag()
    spawnRadiantFlag()
    local options = frota:GetOptions()
    frota:SetScoreLimit(options.scoreLimit)
    print('finished onGameStart')
    end,
 
    onThink = function(frota, dt)
            local goodGuysBase = Entities:FindByName(nil, 'base_goodguys')
            local goodGuysBaseVec = goodGuysBase:GetOrigin()
            local badGuysBase = Entities:FindByName(nil, 'base_badguys')
            local badGuysBaseVec = badGuysBase:GetOrigin()
            local goodUnitsOnPoint = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, goodGuysBaseVec, null, 150, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
            local badUnitsOnPoint = FindUnitsInRadius(DOTA_TEAM_BADGUYS, badGuysBaseVec, null, 150, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, 0, false)      
            local tableSize = 0
           
            for k,v in pairs(goodUnitsOnPoint) do
                tableSize = tableSize + 1
            end
     
            for i=1,tableSize do
                local hero = goodUnitsOnPoint[i]
                if hero then
                    for i=0,5 do
                        local item = hero:GetItemInSlot(i)
                        if item then
                            if item:GetAbilityName() == 'item_capture_flag_dire' then
                               UTIL_RemoveImmediate(item)
                               hero:RemoveModifierByName('modifier_creep_slow')
                               hero:RemoveModifierByName('modifier_silence')
                               hero:RemoveModifierByName('modifier_bounty_hunter_track')
                               heroWithDireFlag = nil
                               frota.scoreRadiant = frota.scoreRadiant + 1
                               frota:UpdateScoreData()
                               local particleFlag = ParticleManager:CreateParticle( 'legion_commander_duel_victory', PATTACH_OVERHEAD_FOLLOW, hero)
                               local particlePlus = ParticleManager:CreateParticle( 'pudge_fleshheap_count', PATTACH_OVERHEAD_FOLLOW, hero)
                               spawnDireFlag()
                            end
                        end
                    end
                end
            end
 
            tableSize = 0
 
            for k,v in pairs(badUnitsOnPoint) do
                tableSize = tableSize + 1
            end
     
            for i=1,tableSize do
                local hero = badUnitsOnPoint[i]
                if hero then
                    for i=0,5 do
                        local item = hero:GetItemInSlot(i)
                        if item then
                            if item:GetAbilityName() == 'item_capture_flag' then
                               UTIL_RemoveImmediate(item)
                               hero:RemoveModifierByName('modifier_creep_slow')
                               hero:RemoveModifierByName('modifier_silence')
                               hero:RemoveModifierByName('modifier_bounty_hunter_track')
                               heroWithFlag = nil
                               frota.scoreDire = frota.scoreDire + 1
                               frota:UpdateScoreData()
                               local particleFlag = ParticleManager:CreateParticle( 'legion_commander_duel_victory', PATTACH_OVERHEAD_FOLLOW, hero)
                               local particlePlus = ParticleManager:CreateParticle( 'pudge_fleshheap_count', PATTACH_OVERHEAD_FOLLOW, hero)
                               spawnRadiantFlag()
                            end
                        end
                    end
                end
            end

            if heroWithFlag then
                local hero = heroWithFlag
                if hero then
                    for i=0, 5 do
                        local item = hero:GetItemInSlot(i)
                        if item then
                            if item:GetAbilityName() == 'item_capture_flag' or item:GetAbilityName() == 'item_capture_flag_dire' then
                                hero:AddNewModifier(hero, nil, 'modifier_creep_slow' ,nil)
                                hero:AddNewModifier(hero, nil, 'modifier_silence' ,nil)
                                hero:AddNewModifier(hero, nil, 'modifier_bounty_hunter_track' ,nil)
                                heroWithFlag = hero
                                break
                            else
                                hero:RemoveModifierByName('modifier_creep_slow')
                                hero:RemoveModifierByName('modifier_silence')
                                hero:RemoveModifierByName('modifier_bounty_hunter_track')
                                heroWithFlag = nil
                            end
                        else
                            hero:RemoveModifierByName('modifier_creep_slow')
                            hero:RemoveModifierByName('modifier_silence')
                            hero:RemoveModifierByName('modifier_bounty_hunter_track')
                            heroWithFlag = nil
                        end
                    end
                end                
            end

            if heroWithDireFlag then
                local hero = heroWithDireFlag
                if hero then
                    for i=0, 5 do
                        local item = hero:GetItemInSlot(i)
                        if item then
                            if  item:GetAbilityName() == 'item_capture_flag_dire' then
                                hero:AddNewModifier(hero, nil, 'modifier_creep_slow' ,nil)
                                hero:AddNewModifier(hero, nil, 'modifier_silence' ,nil)
                                hero:AddNewModifier(hero, nil, 'modifier_bounty_hunter_track' ,nil)
                                heroWithDireFlag = hero
                                break
                            else
                                hero:RemoveModifierByName('modifier_creep_slow')
                                hero:RemoveModifierByName('modifier_silence')
                                hero:RemoveModifierByName('modifier_bounty_hunter_track')
                                heroWithDireFlag = nil
                            end
                        else
                            hero:RemoveModifierByName('modifier_creep_slow')
                            hero:RemoveModifierByName('modifier_silence')
                            hero:RemoveModifierByName('modifier_bounty_hunter_track')
                            heroWithDireFlag = nil
                        end
                    end
                end                
            end

    end,
 
    dota_item_picked_up = function(frota, keys)
        local hero = Players:GetSelectedHeroEntity(keys.PlayerID)
        if hero then
            for i=0, 5 do
                local item = hero:GetItemInSlot(i)
                if item then
                    if item:GetAbilityName() == 'item_capture_flag' then
                        if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
                            UTIL_RemoveImmediate(item)
                            heroWithFlag = nil
                            spawnRadiantFlag()
                            break
                        else
                            hero:AddNewModifier(hero, nil, 'modifier_creep_slow' ,nil)
                            hero:AddNewModifier(hero, nil, 'modifier_silence' ,nil)
                            hero:AddNewModifier(hero, nil, 'modifier_bounty_hunter_track' ,nil)
                            heroWithFlag = hero
                            break  
                        end
                    elseif item:GetAbilityName() == 'item_capture_flag_dire' then
                        if hero:GetTeam() == DOTA_TEAM_BADGUYS then
                            UTIL_RemoveImmediate(item)
                            heroWithDireFlag = nil
                            spawnDireFlag()
                            break
                        else
                            hero:AddNewModifier(hero, nil, 'modifier_creep_slow' ,nil)
                            hero:AddNewModifier(hero, nil, 'modifier_silence' ,nil)
                            hero:AddNewModifier(hero, nil, 'modifier_bounty_hunter_track' ,nil)
                            heroWithDireFlag = hero
                            break  
                        end
                    end
                end
            end
        end
    end,

    })

    
    function spawnRadiantFlag( )
        local goodGuysBase = Entities:FindByName(nil, 'base_goodguys')
        local goodGuysBaseVec = goodGuysBase:GetOrigin()
        local flag = CreateItem('item_capture_flag', nil, nil)
        local flag_drop = CreateItemOnPosition(goodGuysBaseVec)
        if flag_drop then
            flag_drop:SetContainedItem( flag )
        end
    end

    function spawnDireFlag( )
        local badGuysBase = Entities:FindByName(nil, 'base_badguys')
        local badGuysBaseVec = badGuysBase:GetOrigin()
        local flag = CreateItem('item_capture_flag_dire', nil, nil)
        local flag_drop = CreateItemOnPosition(badGuysBaseVec)
        if flag_drop then
            flag_drop:SetContainedItem( flag )
        end
    end
