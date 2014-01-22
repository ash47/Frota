local any_gem_active = 0
local hero_has_gem = 0
RegisterGamemode('oddball', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_BOTH,
    -- Function to give out heroes
    assignHero = function(frota, ply)
        -- Change heroes
        local hero = ply:ReplaceHeroWith(frota:ChooseRandomHero(), 5000, 2600)
        frota:SetActiveHero(hero)
	end,
	
	options = {killsScore = false,useScores = true,respawnDelay = 15 }, 
		
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
        local options = frota:GetOptions()
        frota:SetScoreLimit(options.scoreLimit)    
		frota:CreateTimer('oddball_create_timer', {        
			endTime = Time() + 1,    
			callback = function(frota, args)    
				local vector = Vec3( 0, 0, 0 )
				local unit = CreateUnitByName("npc_dota_neutral_satyr_trickster2", vector, false, nil, nil, DOTA_TEAM_NEUTRALS)
				unit:AddItem(CreateItem('item_oddball', nil, nil))    			
				cply = frota:GetPlayerList()
				unit:SetMaxHealth(#cply * 500)
				unit:SetHealth(5000)
			end   
		})
	end,
	
	dota_item_picked_up = function(frota, keys)
        local hero = Players:GetSelectedHeroEntity(keys.PlayerID)
        if hero then
            for i=0, 5 do
                local item = hero:GetItemInSlot(i)
                if item then
                    if item:GetAbilityName() == 'item_oddball' then
						hero_has_gem=hero
						any_gem_active = 1
						hero:AddNewModifier(hero, nil, 'modifier_bloodseeker_thirst_vision' ,nil)
						break
					else
						if hero:HasModifier('modifier_bloodseeker_thirst_vision') == true then
							hero:RemoveModifierByName('modifier_bloodseeker_thirst_vision')
						end
					end
                end
            end
        end
    end,
		
	onThink = function(frota, dt)
			--[[if frota.scoreRadiant % 500 == 0 then
		local playerID = frota:ply:GetPlayerID()
		local hero = frota:GetActiveHero(playerID)
			if  hero:GetTeam() == DOTA_TEAM_BADGUYS then
				local cgold = GetGold()
				hero:SetGold(cgold+250, true)
				frota.scoreRadiant = frota.scoreRadiant + 1
				frota:UpdateScoreData()
			end
		end
		if frota.scoreDire % 500 == 0 then
	    local playerID = frota.ply:GetPlayerID()
		local hero = frota:GetActiveHero(playerID)
			if  hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				local cgold = GetGold()
				hero:SetGold(cgold+250, true)
				frota.scoreDire = frota.scoreDire + 1
				frota:UpdateScoreData()
			end
		end]]
		if any_gem_active == 1 then
		hero = hero_has_gem
			for i=0,5 do
				local item = hero:GetItemInSlot(i)
				if item then
					if item:GetAbilityName() == 'item_oddball' then
						if  hero:GetTeam() == DOTA_TEAM_GOODGUYS then
							frota.scoreRadiant = frota.scoreRadiant + 1
							frota:UpdateScoreData()
						end
						if  hero:GetTeam() == DOTA_TEAM_BADGUYS then
							frota.scoreDire = frota.scoreDire + 1
							frota:UpdateScoreData()
						end
					end
				end
			end
		end
	end,

	

})