RegisterGamemode('oddball', {
    -- Gamemode only has a gameplay component
    sort = GAMEMODE_BOTH,
	i = 0,
    -- Function to give out heroes
    assignHero = function(frota, ply)
        -- Change heroes
        ply:ReplaceHeroWith(frota:ChooseRandomHero(), 4000, 2600)
		
        local playerID = ply:GetPlayerID()
		local build = frota.selectedBuilds[playerID]
        local hero = Players:GetSelectedHeroEntity(playerID)
		
	end,
	
	options = {
		killsScore = false,
		useScores = true,
		teamholdinggem = 0,
		any_gem_active = 0,
		hero_has_gem = 0,
		respawnDelay = 15
		}, 
		
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
				print("code was run!")     
				local playerID = frota:GetRandomPlayer():GetPlayerID() 				       
				local hero = Players:GetSelectedHeroEntity(playerID)        
				hero:AddItem(CreateItem('item_gem', hero, hero))    
				hero_has_gem = hero
				any_gem_active = 1
			end   
		})
	end,
	
	dota_item_picked_up = function(frota, keys)
        local hero = Players:GetSelectedHeroEntity(keys.PlayerID)
        if hero then
            for i=0, 5 do
                local item = hero:GetItemInSlot(i)
                if item then
                    if item:GetAbilityName() == 'item_gem' then
						print('item gem picked up, in slot' .. i)
						hero_has_gem=hero
						print(hero_has_gem)
						any_gem_active = 1
                    end
                end
            end
        end
    end,
		
	onThink = function(frota, dt)
		if any_gem_active == 1 then
		print('any gem active = 1')
		local hero = hero_has_gem
			for i=0,5 do
				local item = hero:GetItemInSlot(i)
				if item then
					if item:GetAbilityName() == 'item_gem' then
						print('item gem is in slot' .. i)
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