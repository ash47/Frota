local rubickHero = 'npc_dota_hero_rubick'
local anteSkill = 'gambler_ante_up'
local chipSkill = 'gambler_chip_stack'
local luckySkill = 'gambler_lucky_stars'
local allInSkill = 'gambler_all_in'

RegisterGamemode('gambler', {
    -- Gamemode only has a pick component
    sort = GAMEMODE_PICK,

    -- Function to give out heroes
    assignHero = function(frota, ply)
        -- Change heroes
        ply:ReplaceHeroWith(rubickHero, 2500, 2600)

        local playerID = ply:GetPlayerID()
        local hero = Players:GetSelectedHeroEntity(playerID)

        -- Apply the build
		
		frota:ApplyBuild(hero, {
            [1] = anteSkill,
            [2] = chipSkill,
            [3] = luckySkill,
            [4] = allInSkill
        })
		
    end,

    -- A list of options for fast gameplay stuff
    options = {
        -- Kills give team points
        killsScore = true,

        -- Enable scores
        useScores = true,

        -- Respawn delay
        respawnDelay = 3
    },

    voteOptions = {
        -- Score limit vote
        scoreLimit = {
            -- Range based
            s = VOTE_SORT_RANGE,

            -- Minimal possible value
            min = 1,

            -- Maximal possible value
            max = 50,

            -- Default vaule (if no one votes)
            def = 10,

            -- Slider tick interval
            tick = 10,

            -- Slider step interval
            step = 1
        }
    },

    onGameStart = function(frota)
        -- Grab options
        local options = frota:GetOptions()

        -- Set the score limit
        frota:SetScoreLimit(options.scoreLimit)
    end
})

local gama = {}

function anteUpRegister(keys)

end	

function anteUpKill(keys)
	
	--local caster = keys.caster
	--if caster == nil then
	--	return
	--end
	--sendAMsg('you dead')

	local caster = keys.caster
	if caster == nil then
		sendAMsg('no caster')
		return
	end
	caster:ModifyGold(600,false,0)

end

function anteUpDeath(keys)
	
	--caster:ForceKill(false)
	--local caster = keys.caster
	--if caster == nil then
	--	return
	--end
	sendAMsg('i ded')
	--local playerId = caster:GetPlayerOwnerID()
	--target:ModifyGold(3000,false,0)
	--SetGold
	--local target = keys.target_entities[1]
	--if target == nil then
	--	return
	--end
			
	--end
end

--Will need a rework with correct damaging
chipStackAmount = {}
chipStackAmount[1] = 0.15
chipStackAmount[2] = 0.2
chipStackAmount[3] = 0.25
chipStackAmount[4] = 0.3 

function chipStack(keys)

	local caster = keys.caster
	if caster == nil then
		return
	end
	
	local target = keys.target_entities[1]
	if target == nil then
		return
	end
	
	local dmg = target:GetGold()*chipStackAmount[1]
	local hp = target:GetHealth()
	if hp <= dmg then
		target:ForceKill(false)
	else
		target:SetHealth(hp-dmg)
	end
	
	
	

end

function allInSuccess(keys)	
	
	local caster = keys.caster
	if caster == nil then
		sendAMsg('no caster')
		return
	end
	
	sendAMsg('I won!?!?!?')
	
end

function allInFail(keys)	
	
	local caster = keys.caster
	if caster == nil then
		sendAMsg('no caster')
		return
	end
	
	--sendAMsg('time to lose money')
	local startingGold = caster:GetGold()
	local lostAmount = RandomInt(0, startingGold)
	sendAMsg(lostAmount)
	--caster:ModifyGold(lostAmount,false,0)
	--caster:SetGold(startingGold-lostAmount, false,0)
	
end

function sendAMsg(msg)
	local centerMessage = {
		message = msg,
		duration = 1.0
	}
	FireGameEvent( "show_center_message", centerMessage)
end


	
	
	