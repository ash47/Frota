-- Syntax copied mostly from frostivus example

-- Constants
MAX_PLAYERS = 10
STARTING_GOLD = 625

if FrotaGameMode == nil then
    FrotaGameMode = {}
    FrotaGameMode.szEntityClassName = "Frota"
    FrotaGameMode.szNativeClassName = "dota_base_game_mode"
    FrotaGameMode.__index = FrotaGameMode
end

function FrotaGameMode:new (o)
    o = o or {}
    setmetatable(o, self)
    return o
end

-- Default settings for regular Dota
local minimapHeroScale = 600
local minimapCreepScale = 1

function FrotaGameMode:LoadAbilityList()
    local abs = LoadKeyValues( "scripts/kv/abilities.kv" )
    self.heroList = LoadKeyValues( "scripts/npc/npc_heroes.txt" )
    --local englishPack = LoadKeyValues( "resource/dota_english.txt" )

    -- Table containing every skill
    self.vAbList = {}

    -- Build skill list
    for k,v in pairs(abs) do
        for kk, vv in pairs(v) do
            if vv then
                -- Attempt to find the owning hero of this ability
                local heroOwner = ""
                for heroName, values in pairs(self.heroList) do
                    if type(values) == "table" then
                        for i = 1, 16 do
                            if values["Ability"..i] == kk then
                                heroOwner = heroName
                                goto foundHeroName
                            end
                        end
                    end
                end

                ::foundHeroName::

                -- Find the nice name of this ability
                local niceName = ""
                local des = ""
                --[[for textField, value in pairs(englishPack.Tokens) do
                    if textField == "DOTA_Tooltip_ability_"..kk then
                        niceName = value
                    end

                    if textField == "DOTA_Tooltip_ability_"..kk.._Description then
                        des = value
                    end
                end]]

                -- Store this skill
                table.insert(self.vAbList, {
                    name = kk,
                    sort = k,
                    hero = heroOwner,
                    niceName = niceName,
                    des = des
                })
            end
        end
    end

    --PrintTable(self.vAbList)
end

function FrotaGameMode:SkillIntoSlot(hero, skillName, skillSlot)
    -- Validate Data here (never trust client)

    -- Check if we've touched this hero before
    if not self.currentSkillList[hero] then
        -- Grab the name of this hero
        local heroClass = hero:GetUnitName()
        print(heroClass)

        local skills = {}

        -- Build list of abilities
        for heroName, values in pairs(self.heroList) do
            if heroName == heroClass then
                for i = 1, 16 do
                    local ab = values["Ability"..i]
                    if ab then
                        table.insert(skills, ab)
                    end
                end
            end
        end

        -- Store it
        self.currentSkillList[hero] = skills
    end

    -- Remove all old skills
    for k,v in pairs(self.currentSkillList[hero]) do
        if hero:HasAbility(v) then
            hero:RemoveAbility(v)
        end
    end

    -- Change required ability
    self.currentSkillList[hero][skillSlot] = skillName

    -- Regive all abilities
    for k,v in ipairs(self.currentSkillList[hero]) do
        hero:AddAbility(v)
        print("Added: "..v)
    end
end

function FrotaGameMode:_SetInitialValues()
    -- Load ability List
    self:LoadAbilityList()

    -- Voting thinking
    self.thinkState = Dynamic_Wrap( FrotaGameMode, '_thinkState_Voting' )
    self._scriptBind:BeginThink( "FrotaThink", Dynamic_Wrap( FrotaGameMode, 'Think' ), 0.25 )

    -- Stores the current skill list for each hero
    self.currentSkillList = {}
end

function FrotaGameMode:InitGameMode()
    Convars:RegisterCommand( "afs_print", function(name, msg)
        print("Client Message: "..msg)
    end, "Print a message to the server console", 0 )

    Convars:RegisterCommand( "send_shit", function(name, msg)
        self:SendAbilityList()
    end, "Print a message to the server console", 0 )

    Convars:RegisterCommand( "afs_skill", function(name, skillName, slotNumber)
        local cmdPlayer = Convars:GetCommandClient()
        if cmdPlayer then
            local hero = cmdPlayer:GetAssignedHero()
            if hero then
                self:SkillIntoSlot(hero, skillName, tonumber(slotNumber))
                return
            end
        end

        print(skillName.." into slot "..slotNumber);
        --SkillIntoSlot()
    end, "Print a message to the server console", 0 )

    -- Setup rules
    GameRules:SetHeroRespawnEnabled( false )
    GameRules:SetUseUniversalShopMode( true )
    GameRules:SetSameHeroSelectionEnabled(true)
    GameRules:SetHeroSelectionTime( 5.0 )
    GameRules:SetPreGameTime( 60.0 )
    GameRules:SetPostGameTime( 60.0 )
    GameRules:SetTreeRegrowTime( 60.0 )
    GameRules:SetHeroMinimapIconSize( 400 )
    GameRules:SetCreepMinimapIconScale( 0.7 )
    GameRules:SetRuneMinimapIconScale( 0.7 )

    -- Load initital Values
    self:_SetInitialValues()

    Convars:SetBool( "dota_suppress_invalid_orders", true )
end

function FrotaGameMode:_InitCVars()
    if self.bHasSetCVars then
        return
    end
    self.bHasSetCVars = true
    Convars:SetBool( "dota_winter_ambientfx", true )
end

function FrotaGameMode:_RestartGame()
    -- Clean up everything on the ground; gold, tombstones, items, everything.
    while GameRules:NumDroppedItems() > 0 do
        local item = GameRules:GetDroppedItem(0)
        UTIL_RemoveImmediate( item )
    end

    -- Reset Players
    for playerID = 0, MAX_PLAYERS-1 do
        Players:SetGold( playerID, STARTING_GOLD, false )
        Players:SetGold( playerID, 0, true )
        Players:SetBuybackCooldownTime( playerID, 0 )
        Players:SetBuybackGoldLimitTime( playerID, 0 )
        Players:ResetBuybackCostTime( playerID )
    end

    -- Set initial Values again
    self:_SetInitialValues()


end

function FrotaGameMode:Think()
    -- If the game's over, it's over.
    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
        self._scriptBind:EndThink( "GameThink" )
        return
    end

    -- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
    local now = GameRules:GetGameTime()
    if self.t0 == nil then
        self.t0 = now
    end
    local dt = now - self.t0
    self.t0 = now

    self:thinkState( dt )
end

function FrotaGameMode:_thinkState_Voting(dt)
    if GameRules:State_Get() < DOTA_GAMERULES_STATE_PRE_GAME then
        -- Waiting on the game to start...
        return
    end

    if not self.sentShit then
        self.sentShit = true
        self:SendAbilityList()
    end
end

function FrotaGameMode:SendAbilityList()
    local sSkillList = ""
    for k,v in pairs(self.vAbList) do
        local sSkill = v.name.."::"..v.sort.."::"..v.hero.."::"..v.niceName.."::"..v.des

        sSkillList = sSkillList..sSkill.."||"
    end

    -- Remove the last |
    sSkillList = string.sub(sSkillList, 1, -3)

    print("\n\nJust fired server side: \n")
    FireGameEvent("afs_herolist", {
        skills = sSkillList
    })
end

EntityFramework:RegisterScriptClass( FrotaGameMode )
