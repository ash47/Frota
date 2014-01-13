local warlockHero = 'npc_dota_hero_warlock'
local unstableSkill = 'warlocks_unstable_spell'
local jauntSkill = 'warlocks_novice_jaunt'
local hexSkill = 'warlocks_novice_hex'
local etherealSkill = 'warlocks_novice_ethereal'
local etherealModifier = 'modifier_item_ethereal_blade_ethereal'

--local playerList = {}
local currentHolder = nil
local previousHolder = nil

local currentTime = 15.0
local particleCountdown = nil

RegisterGamemode('warlocks', {
    -- Gamemode covers picking and playing
    sort = GAMEMODE_BOTH,

    -- List of addons to ignore
    ignoreAddons = {
        dmMode = true,
        wtf = true
    },

    -- Function to give out heroes
    assignHero = function(frota, ply)
        local playerID = ply:GetPlayerID()

        -- Change heroes
        local hero = ply:ReplaceHeroWith(warlockHero, 0, 0)
        frota:SetActiveHero(hero)

		--playerList[playerID] = hero
		--print("Warlocks: Adding player, ("..playerID..") to playerList.")

        -- Give blinkdagger
        --hero:AddItem(CreateItem('item_blink', hero, hero))

        -- Apply the build
        frota:ApplyBuild(hero, {
            [1] = unstableSkill,
            [2] = jauntSkill,
            [3] = hexSkill,
            [4] = etherealSkill
        })

		hero:AddNewModifier(hero, nil, 'modifier_disarmed', {})

        hero:__KeyValueFromInt('AbilityLayout', 4)
    end,

	onGameStart = function(frota)
		print("onGameStart has fired!")
		frota:CreateTimer('warlocks_countdown_timer', {
			endTime = Time() + 5,  -- Run 5 seconds from now
			callback = function(frota, args)
				__selectRandomWarlock()
			end
		})
		Convars:SetFloat("dota_all_vision", 1.0)
		--playerList = {}
	end,

	--[[
	dota_player_used_ability = function(frota, keys)
		PrintTable(keys)
	end,
	]]--

	CleanupPlayer = function(frota, leavingPly)
        local playerID = leavingPly:GetPlayerID()
		--print("Warlocks: Removing disconnected player, ("..playerID..") from playerList.")
		--table.remove(playerList, playerID)
		-- If the jerk with the spell leavers we pick a new warlock.
		if leavingPly == currentHolder then
			frota:CreateTimer('warlocks_countdown_timer', {
				endTime = Time() + 5,  -- Run 5 seconds from now
				callback = function(frota, args)
					__selectRandomWarlock()
				end
			})
		end
	end,

	onThink = function(frota, dt)
		--print("onThink has fired!", dt)
		counterThink()
	end,

	onGameEnd = function(frota)
		print("Warlocks: onGameEnd has fired!")
		frota._scriptBind:EndThink('WarlockCounterThink')
		Convars:SetFloat("dota_all_vision", 0.0)
	end,

	onHeroKilled = function(frota, killedUnit, killerEntity)
		local killedPlayerID = killedUnit:GetPlayerID()
		print("Warlocks: onHeroKilled has fired!")
		--print("Warlocks: Removing killed player, ("..killedPlayerID..") from playerList.")
		--table.remove(playerList, killedPlayerID)


		local livingPlayers = getLivingPlayerList()
		if(#livingPlayers <= 1) then
			frota:EndGamemode()
			return
		end --You are the one and only.


		frota:CreateTimer('warlocks_countdown_timer', {
			endTime = Time() + 5,  -- Run 5 seconds from now
			callback = function(frota, args)
				__selectRandomWarlock()
			end
		})

	end,

    -- A list of options for fast gameplay stuff
    options = {
        -- Kills give team points
        killsScore = false,

        -- Score Limit
        scoreLimit = 10,

        -- Enable scores
        useScores = false,

        -- Respawn delay
        respawnDelay = false
    }
})

function __selectRandomWarlock()
	local warlocks = getLivingPlayerList()
	luckyMofo = warlocks[ math.random( #warlocks ) ]
	setHolder(luckyMofo)
	currentTime = 8.0 + #warlocks
end

function unstableSpellOnSpellStart(keys)
	--PrintTable(keys)
	-- Pass the rock
	local caster = keys.caster
	if caster == nil then
		return
	end

	-- Get the snack and determine what "color" it is
	local target = keys.target_entities[1]
	if target == nil then
		return
	end
	
	-- If the target is ethereal at the time of cast we halve the time left on the count down.
	-- But if they have less than 2 seconds left on the countdown we set the time to 2 seconds.
	if target:HasModifier(etherealModifier) then
		local newTime = currentTime - ( currentTime / 2 )
		if newTime <= 2 then
			newTime = 2
		end
		currentTime = newTime
	end

	removeHolder(caster)
	setHolder(target)
end

function setHolder(hero)
	if hero == nil then
		__selectRandomWarlock()
		return
	end
	hero:FindAbilityByName(unstableSkill):SetLevel(1)
	previousHolder = currentHolder
	currentHolder = hero

	createCounter()
end

function removeHolder(hero)
	hero:FindAbilityByName(unstableSkill):SetLevel(0)
end

function createCounter()
	if particleCountdown ~= nil then
		ParticleManager:ReleaseParticleIndex( particleCountdown )
		particleCountdown = nil
		return
	end
	local normTime = currentTime - math.floor(currentTime)
	local normTime = math.floor(normTime * 10)/10
	if normTime == 0.5 then
		particleCountdown = ParticleManager:CreateParticle( "alchemist_unstable_concoction_timer", PATTACH_OVERHEAD_FOLLOW, currentHolder )
		ParticleManager:SetParticleControl( particleCountdown, 1, Vec3( 0.0, currentTime, 8.0 ) )	-- Shows .5
		ParticleManager:SetParticleControl( particleCountdown, 2, Vec3( 3.0, 0, 0.0 ) )
	elseif normTime == 0.0 then
		particleCountdown = ParticleManager:CreateParticle( "alchemist_unstable_concoction_timer", PATTACH_OVERHEAD_FOLLOW, currentHolder )
		ParticleManager:SetParticleControl( particleCountdown, 1, Vec3( 0.0, currentTime, 1.0 ) )	-- Shows .0
		ParticleManager:SetParticleControl( particleCountdown, 2, Vec3( 3.0, 0, 0.0 ) )
	end
end

function destroyCounter()
	if particleCountdown ~= nil then return end
	ParticleManager:ReleaseParticleIndex( particleCountdown )
	particleCountdown = nil
end

function getPlayerList()
	return Entities:FindAllByClassname( 'npc_dota_hero*' )
end

function getLivingPlayerList()
	local livePlayers = getPlayerList()
	for k,v in pairs(livePlayers) do
		if not v:IsAlive() then
			table.remove(livePlayers, k)
		end
	end
	return livePlayers
end

function killHolder()
	currentHolder:ForceKill(false)
	--destroyCounter()
end

function counterThink()
	--if particleCountdown == nil then return end
	if currentTime == 0 then return end
	if currentHolder == nil then return end
	--print("counterThink",currentTime)
	if currentTime <= 0 then
		killHolder()
		if currentTime ~= 0 then
			currentTime = 0
		end
	else
		currentTime = currentTime - 0.1
		createCounter()
	end
end