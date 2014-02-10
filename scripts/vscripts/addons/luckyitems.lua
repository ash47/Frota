-- Initial Delay to get first item
local initialDelay = 0

-- Delay to get each item after that
local repeatDelay = 60

-- Sound to play when players get an item
local getItemSound = 'ui/npe_objective_given.wav'

-- List of valid items to give
local possibleItems = {
    [1] = 'item_blink',
    [2] = 'item_blades_of_attack',
    [3] = 'item_broadsword',
    [4] = 'item_chainmail',
    [5] = 'item_claymore',
    [6] = 'item_helm_of_iron_will',
    [7] = 'item_javelin',
    [8] = 'item_mithril_hammer',
    [9] = 'item_platemail',
    [10] = 'item_quarterstaff',
    [11] = 'item_quelling_blade',
    [12] = 'item_ring_of_protection',
    [13] = 'item_stout_shield',
    [14] = 'item_gauntlets',
    [15] = 'item_slippers',
    [16] = 'item_mantle',
    [17] = 'item_branches',
    [18] = 'item_belt_of_strength',
    [19] = 'item_boots_of_elves',
    [20] = 'item_robe',
    [21] = 'item_circlet',
    [22] = 'item_ogre_axe',
    [23] = 'item_blade_of_alacrity',
    [24] = 'item_staff_of_wizardry',
    [25] = 'item_ultimate_orb',
    [26] = 'item_gloves',
    [27] = 'item_lifesteal',
    [28] = 'item_ring_of_regen',
    [29] = 'item_sobi_mask',
    [30] = 'item_boots',
    [31] = 'item_gem',
    [32] = 'item_cloak',
    [33] = 'item_talisman_of_evasion',
    [34] = 'item_magic_stick',
    [35] = 'item_magic_wand',
    [36] = 'item_ghost',
    [37] = 'item_bottle',
    [38] = 'item_travel_boots',
    [39] = 'item_phase_boots',
    [40] = 'item_demon_edge',
    [41] = 'item_eagle',
    [42] = 'item_reaver',
    [43] = 'item_relic',
    [44] = 'item_hyperstone',
    [45] = 'item_ring_of_health',
    [46] = 'item_void_stone',
    [47] = 'item_mystic_staff',
    [48] = 'item_energy_booster',
    [49] = 'item_point_booster',
    [50] = 'item_vitality_booster',
    [51] = 'item_power_treads',
    [52] = 'item_hand_of_midas',
    [53] = 'item_oblivion_staff',
    [54] = 'item_pers',
    [55] = 'item_poor_mans_shield',
    [56] = 'item_bracer',
    [57] = 'item_wraith_band',
    [58] = 'item_null_talisman',
    [59] = 'item_mekansm',
    [60] = 'item_vladmir',
    [61] = 'item_buckler',
    [62] = 'item_ring_of_basilius',
    [63] = 'item_pipe',
    [64] = 'item_urn_of_shadows',
    [65] = 'item_headdress',
    [66] = 'item_sheepstick',
    [67] = 'item_orchid',
    [68] = 'item_cyclone',
    [69] = 'item_force_staff',
    [70] = 'item_dagon',
    [71] = 'item_dagon_2',
    [72] = 'item_dagon_3',
    [73] = 'item_dagon_4',
    [74] = 'item_dagon_5',
    [75] = 'item_necronomicon',
    [76] = 'item_necronomicon_2',
    [77] = 'item_necronomicon_3',
    [78] = 'item_ultimate_scepter',
    [79] = 'item_refresher',
    [80] = 'item_assault',
    [81] = 'item_heart',
    [82] = 'item_black_king_bar',
    [83] = 'item_shivas_guard',
    [84] = 'item_bloodstone',
    [85] = 'item_sphere',
    [86] = 'item_vanguard',
    [87] = 'item_blade_mail',
    [88] = 'item_soul_booster',
    [89] = 'item_hood_of_defiance',
    [90] = 'item_rapier',
    [91] = 'item_monkey_king_bar',
    [92] = 'item_radiance',
    [93] = 'item_butterfly',
    [93] = 'item_greater_crit',
    [94] = 'item_basher',
    [95] = 'item_bfury',
    [96] = 'item_manta',
    [97] = 'item_lesser_crit',
    [98] = 'item_armlet',
    [99] = 'item_invis_sword',
    [100] = 'item_sange_and_yasha',
    [101] = 'item_satanic',
    [102] = 'item_mjollnir',
    [103] = 'item_skadi',
    [104] = 'item_sange',
    [105] = 'item_helm_of_the_dominator',
    [106] = 'item_maelstrom',
    [107] = 'item_desolator',
    [108] = 'item_yasha',
    [109] = 'item_mask_of_madness',
    [110] = 'item_diffusal_blade',
    [111] = 'item_diffusal_blade_2',
    [112] = 'item_ethereal_blade',
    [113] = 'item_soul_ring',
    [114] = 'item_arcane_boots',
    [115] = 'item_orb_of_venom',
    [116] = 'item_ancient_janggo',
    [117] = 'item_medallion_of_courage',
    [118] = 'item_veil_of_discord',
    [119] = 'item_rod_of_atos',
    [120] = 'item_abyssal_blade',
    [121] = 'item_heavens_halberd',
    [122] = 'item_ring_of_aquila',
    [123] = 'item_tranquil_boots',
    [124] = 'item_shadow_amulet'

}

-- Load item settings
local itemKV = LoadKeyValues("scripts/npc/items.txt")

-- Build the item list
local itemList = {}
for k,itemName in pairs(possibleItems) do
    -- Check if this item exists
    local item = itemKV[itemName]
    if item then
        -- Make sure it has a cost
        local cost = item.ItemCost
        if cost then
            -- Store this item
            table.insert(itemList, {
                name = itemName,
                cost = cost
            })
        end
    end
end

-- Register the addon
RegisterGamemode('luckyitems', {
    -- This is an addon
    sort = GAMEMODE_ADDON,

    onGameStart = function(frota)
        -- Create item timer
        frota:CreateTimer('luckyItems', {
            endTime = Time()+initialDelay,
            callback = function(frota, args)
                -- Pick items to give
                local item = itemList[math.random(1, #itemList)]
                table.sort(itemList, function(a, b)
                    -- Workout distance to this item
                    local aa = math.abs(a.cost - item.cost)
                    local bb = math.abs(b.cost - item.cost)

                    -- Sort
                    return aa < bb
                end)

                local takenItems = {}

                -- Give items
                frota:LoopOverPlayers(function(ply, playerID)
                    local hero = frota:GetActiveHero(playerID)
                    if hero then
                        -- Default to not having room
                        local hasRoom = false

                        -- Make sure this hero has space
                        for i=0,11 do
                            local sItem = hero:GetItemInSlot(i)
                            if not sItem then
                                hasRoom = true
                                break
                            end
                        end

                        -- Only give an item if we have room
                        if hasRoom then
                            -- Select item to give
                            local item = ''

                            for i=1, #itemList do
                                -- Grab an item
                                item = itemList[i]

                                -- Check if it's been taken
                                if not takenItems[item] then
                                    -- Default to not taken
                                    local taken = false

                                    -- Make sure we don't have it
                                    for j = 0, 11 do
                                        local sItem = hero:GetItemInSlot(j)
                                        if sItem then
                                            -- TODO: Check if this item conflicts with other items (etc: Two pairs of shoes)

                                            -- Check if this is the item
                                            if sItem:GetAbilityName() == item.name then
                                                taken = true
                                                break
                                            end
                                        end
                                    end

                                    -- If it's not taken, give this item
                                    if not taken then
                                        takenItems[item] = true
                                        break
                                    end
                                end
                            end

                            -- Give the item
                            hero:AddItem(CreateItem(item.name, hero, hero))
                        end

                        -- TODO: Add item queue if user has no room
                    end
                end)

                -- Play sound to notify clients
                EmitGlobalSound(getItemSound)

                -- Run again after a delay
                return Time() + repeatDelay
            end
        })
    end,
})
