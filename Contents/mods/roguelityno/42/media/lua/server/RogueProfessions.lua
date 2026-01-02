if not isServer() then return end

Rogue = Rogue or {}
Rogue.Professions = Rogue.Professions or {}

local Professions = Rogue.Professions
if not Rogue.Config then require "RogueConfig" end
local Config = Rogue.Config

Professions.list = Config.BUILDS or Config.PROFESSIONS or {}

local function debugLog(msg)
    if Rogue.Server and Rogue.Server.state and Rogue.Server.state.debug then
        print("[Roguelityno] " .. tostring(msg))
    end
end

local function rateLog(player, msg, intervalMs)
    if not player or not msg then return end
    local now = getTimestampMs()
    local md = player.getModData and player:getModData() or nil
    if not md then return end
    local last = md.RogueTraitLogAt or 0
    local interval = intervalMs or 3000
    if now - last < interval then return end
    md.RogueTraitLogAt = now
    print("[Roguelityno] " .. tostring(msg))
end

local function findBuild(professionId)
    for i = 1, #Professions.list do
        if Professions.list[i].id == professionId then
            return Professions.list[i]
        end
    end
    return nil
end

function Professions.getAllowedIds()
    local ids = {}
    for i = 1, #Professions.list do
        ids[i] = Professions.list[i].id
    end
    return ids
end

function Professions.getDefaultId()
    if #Professions.list > 0 then
        return Professions.list[1].id
    end
    return nil
end

function Professions.isAllowed(professionId)
    if not professionId then return false end
    for i = 1, #Professions.list do
        if Professions.list[i].id == professionId then
            return true
        end
    end
    return false
end

function Professions.applyLoadout(player, professionId)
    if not player then return end
    local prof = findBuild(professionId)
    if not prof or not prof.loadout then return end
    local inv = player:getInventory()
    if not inv then return end
    for i = 1, #prof.loadout do
        local entry = prof.loadout[i]
        local itemId = entry.id
        local qty = math.max(1, math.floor(tonumber(entry.qty) or 1))
        for j = 1, qty do
            local item = inv:AddItem(itemId)
            if item and sendAddItemToContainer then
                sendAddItemToContainer(inv, item)
            end
        end
    end
end

local function resolveTrait(traitId)
    if not traitId then return nil end
    if not CharacterTrait or not ResourceLocation or not CharacterTrait.get then
        debugLog("Traits: CharacterTrait API missing, cannot resolve " .. tostring(traitId))
        return nil
    end
    local id = tostring(traitId)
    local ok, trait = pcall(function() return CharacterTrait.get(ResourceLocation.of(id)) end)
    if ok and trait then return trait end
    local baseId = "base:" .. id
    ok, trait = pcall(function() return CharacterTrait.get(ResourceLocation.of(baseId)) end)
    if ok and trait then return trait end
    return nil
end

local function hasTrait(player, trait)
    if not player or not trait then return false end
    if player.hasTrait then
        local ok, res = pcall(player.hasTrait, player, trait)
        if ok then return res end
    end
    return false
end

local function addTraitToPlayer(player, trait)
    if not player or not trait then return false end
    if player.getCharacterTraits then
        local traits = player:getCharacterTraits()
        if traits and traits.add then
            pcall(traits.add, traits, trait)
            return true
        end
    end
    return false
end

local function getTraitCollection(player)
    if not player then return nil end
    if player.getCharacterTraits then
        local traits = player:getCharacterTraits()
        if traits then return traits end
    end
    if player.getTraits then
        local ok, traits = pcall(player.getTraits, player)
        if ok then return traits end
    end
    return nil
end

local function applyTraitXpBoost(player, trait)
    if not player or not trait then return false end
    if player.modifyTraitXPBoost then
        local ok = pcall(player.modifyTraitXPBoost, player, trait, false)
        if ok then return true end
        return false
    end
    return false
end

local function removeTraitFromPlayer(player, trait)
    if not player or not trait then return false end
    local traits = getTraitCollection(player)
    local removed = false
    if traits and traits.remove then
        removed = pcall(traits.remove, traits, trait) or false
    end
    if player.modifyTraitXPBoost then
        pcall(player.modifyTraitXPBoost, player, trait, true)
    end
    return removed
end

local function resetPerkLevel(xp, player, perk)
    if not perk then return end
    if xp and xp.setXPToLevel then
        pcall(xp.setXPToLevel, xp, perk, 0)
    end
    if player and player.setPerkLevelDebug then
        pcall(player.setPerkLevelDebug, player, perk, 0)
    end
    if xp and xp.setPerkBoost then
        pcall(xp.setPerkBoost, xp, perk, 0)
    end
end

local function getTraitDefinition(trait)
    if not trait then return nil end
    if CharacterTraitDefinition and CharacterTraitDefinition.getCharacterTraitDefinition then
        local ok, def = pcall(CharacterTraitDefinition.getCharacterTraitDefinition, trait)
        if ok and def then return def end
    end
    return nil
end

local function addTraitRuntime(player, trait, visited, context)
    if not player or not trait then return false end
    visited = visited or {}
    if visited[trait] then return false end
    visited[trait] = true
    context = context or {}
    local traits = getTraitCollection(player)
    if traits and traits.get then
        local ok, has = pcall(traits.get, traits, trait)
        if ok and has then return false end
    end
    if traits and traits.add then
        pcall(traits.add, traits, trait)
    else
        addTraitToPlayer(player, trait)
    end
    if not applyTraitXpBoost(player, trait) then
        context.xpBoostFailed = true
    end
    context.addedAny = true
    context.addedCount = (context.addedCount or 0) + 1

    local def = getTraitDefinition(trait)
    if def and def.getGrantedTraits then
        local ok, granted = pcall(def.getGrantedTraits, def)
        if ok and granted and granted.size then
            for i = 0, granted:size() - 1 do
                local t = granted:get(i)
                if t then
                    addTraitRuntime(player, t, visited, context)
                end
            end
        end
    end
    if def and def.hasGrantedRecipes and def.getGrantedRecipes then
        local ok, hasRecipes = pcall(def.hasGrantedRecipes, def)
        if ok and hasRecipes then
            local ok2, recipes = pcall(def.getGrantedRecipes, def)
            if ok2 and recipes and recipes.size then
                local known = player.getKnownRecipes and player:getKnownRecipes() or nil
                if known and known.add and known.contains then
                    for i = 0, recipes:size() - 1 do
                        local r = recipes:get(i)
                        if r and not known:contains(r) then
                            known:add(r)
                            context.recipesAdded = true
                            context.recipesCount = (context.recipesCount or 0) + 1
                        end
                    end
                end
            end
        end
    end
    if player.getNutrition then
        local ok, nutrition = pcall(player.getNutrition, player)
        if ok and nutrition and nutrition.applyWeightFromTraits then
            pcall(nutrition.applyWeightFromTraits, nutrition)
        end
    end
    return true
end

function Professions.applyTraits(player, professionId)
    if not player or not professionId then return end
    local prof = findBuild(professionId)
    if not prof or not prof.traits then return end
    local context = { addedAny = false, xpBoostFailed = false, recipesAdded = false, addedCount = 0, recipesCount = 0 }
    local beforeKnown = nil
    if player.getCharacterTraits then
        local traits = player:getCharacterTraits()
        if traits and traits.getKnownTraits then
            beforeKnown = traits:getKnownTraits()
        end
    end
    for i = 1, #prof.traits do
        local raw = prof.traits[i]
        local trait = resolveTrait(raw)
        if not trait then
            rateLog(player, "Traits: resolve failed for " .. tostring(raw) .. " (build=" .. tostring(professionId) .. ")", 3000)
        else
            if hasTrait(player, trait) then
                -- skip
            else
                local ok = addTraitRuntime(player, trait, nil, context)
                if Rogue.Server and Rogue.Server.state and Rogue.Server.state.debug then
                    debugLog("Traits: add " .. tostring(raw) .. " ok=" .. tostring(ok) .. " (build=" .. tostring(professionId) .. ")")
                end
            end
        end
    end
    local afterKnown = nil
    if player.getCharacterTraits then
        local traits = player:getCharacterTraits()
        if traits and traits.getKnownTraits then
            afterKnown = traits:getKnownTraits()
        end
    end
    if beforeKnown and afterKnown and beforeKnown.size and afterKnown.size then
        debugLog("Traits: known before=" .. tostring(beforeKnown:size()) .. " after=" .. tostring(afterKnown:size()) .. " (build=" .. tostring(professionId) .. ")")
    elseif afterKnown and afterKnown.size then
        debugLog("Traits: known after=" .. tostring(afterKnown:size()) .. " (build=" .. tostring(professionId) .. ")")
    end
    if (context.addedAny or context.recipesAdded) and sendSyncPlayerFields then
        pcall(sendSyncPlayerFields, player, 0x00000003)
    end
    if context.xpBoostFailed then
        rateLog(player, "Traits: modifyTraitXPBoost failed at least once (build=" .. tostring(professionId) .. ")", 3000)
    end
    rateLog(player, string.format("Traits summary build=%s added=%d recipes=%d", tostring(professionId), context.addedCount or 0, context.recipesCount or 0), 1000)
end

local function resolvePerk(perkId)
    if not perkId then return nil end
    if Perks and Perks[perkId] then
        return Perks[perkId]
    end
    if PerkFactory and PerkFactory.getPerkFromName then
        return PerkFactory.getPerkFromName(perkId)
    end
    return nil
end

local function addXpBoostForPerk(xp, perk, mult)
    if not xp or not perk or not mult then return end
    if xp.addXpMultiplier then
        local ok = pcall(function() xp:addXpMultiplier(perk, mult, 0, 0) end)
        if ok then return end
        ok = pcall(function() xp:addXpMultiplier(perk, mult, 0) end)
        if ok then return end
        pcall(function() xp:addXpMultiplier(perk, mult) end)
        return
    end
    if xp.AddXPBoost then
        local ok = pcall(function() xp:AddXPBoost(perk, mult) end)
        if ok then return end
        pcall(function() xp:AddXPBoost(perk, mult, 0) end)
        return
    end
    if xp.addXPBoost then
        local ok = pcall(function() xp:addXPBoost(perk, mult) end)
        if ok then return end
        pcall(function() xp:addXPBoost(perk, mult, 0) end)
        return
    end
    if xp.setXPBoost then
        pcall(function() xp:setXPBoost(perk, mult) end)
    end
end

local function getAllPerks()
    local set = {}
    if PerkFactory and PerkFactory.PerkList then
        local list = PerkFactory.PerkList
        if list and list.size then
            for i = 0, list:size() - 1 do
                local perk = list:get(i)
                if perk then
                    set[perk] = true
                end
            end
            return set
        end
    end
    if not Perks then return set end
    for _, perk in pairs(Perks) do
        if type(perk) == "userdata" then
            set[perk] = true
        end
    end
    return set
end

local function setPerkLevel(xp, perk, level)
    if not xp or not perk then return false end
    if xp.setPerkLevel then
        local ok = pcall(function() xp:setPerkLevel(perk, level) end)
        if ok then return true end
        ok = pcall(function() xp:setPerkLevel(perk, level, true) end)
        if ok then return true end
    end
    if xp.getPlayer and xp:getPlayer() then
        local player = xp:getPlayer()
        if player and player.setPerkLevel then
            local ok = pcall(function() player:setPerkLevel(perk, level) end)
            if ok then return true end
        end
    end
    if xp.AddXP and xp.getXP and perk.getTotalXpForLevel then
        local targetXp = perk:getTotalXpForLevel(level)
        local current = xp:getXP(perk)
        local delta = math.max(0, targetXp - current)
        if delta > 0 then
            xp:AddXP(perk, delta, false, false, true)
        end
        return true
    end
    return false
end

local function applyPerkLevels(player, perkTable)
    if not player or not perkTable then return end
    local xp = player.getXp and player:getXp() or nil
    if not xp then return end
    for perkId, level in pairs(perkTable) do
        local lvl = tonumber(level)
        if lvl and lvl > 0 then
            local perk = resolvePerk(perkId)
            if perk then
                setPerkLevel(xp, perk, math.floor(lvl))
            end
        end
    end
end

local function applyXpBoosts(player, boostTable)
    if not player or not boostTable then return end
    local xp = player.getXp and player:getXp() or nil
    if not xp then return end
    for perkId, mult in pairs(boostTable) do
        local m = tonumber(mult)
        if m and m ~= 0 then
            local perk = resolvePerk(perkId)
            if perk then
                addXpBoostForPerk(xp, perk, m)
            end
        end
    end
end

local function hasTableEntries(t)
    if type(t) ~= "table" then return false end
    for _ in pairs(t) do
        return true
    end
    return false
end

local function applyGlobalXpBoosts(player)
    if not player then return end
    if not Config then return end
    local mult = tonumber(Config.GLOBAL_XP_BOOST_MULT) or 0
    local hasGlobals = (mult ~= 0) or hasTableEntries(Config.GLOBAL_XP_BOOSTS)
    if not hasGlobals then return end
    local xp = player.getXp and player:getXp() or nil
    if not xp then return end
    if mult ~= 0 then
        local perks = getAllPerks()
        for perk in pairs(perks) do
            addXpBoostForPerk(xp, perk, mult)
        end
    end
    if hasTableEntries(Config.GLOBAL_XP_BOOSTS) then
        applyXpBoosts(player, Config.GLOBAL_XP_BOOSTS)
    end
end

function Professions.applyBuild(player, professionId)
    if not player or not professionId then return end
    local prof = findBuild(professionId)
    if not prof then return end
    Professions.applyTraits(player, professionId)
    Professions.applyLoadout(player, professionId)
    applyPerkLevels(player, prof.startingStats)
    applyPerkLevels(player, prof.skills)
    pcall(applyGlobalXpBoosts, player)
    applyXpBoosts(player, prof.xpBoosts)
end

function Professions.resetBuildEffects(player)
    if not player then return end
    local traits = getTraitCollection(player)
    local removedTraits = 0
    if traits and traits.getKnownTraits then
        local ok, known = pcall(traits.getKnownTraits, traits)
        if ok and known and known.size then
            for i = known:size() - 1, 0, -1 do
                local trait = known:get(i)
                if trait and removeTraitFromPlayer(player, trait) then
                    removedTraits = removedTraits + 1
                end
            end
        end
    end

    local xp = player.getXp and player:getXp() or nil
    local perks = getAllPerks()
    for perk in pairs(perks) do
        resetPerkLevel(xp, player, perk)
    end
    if xp and xp.getMultiplierMap then
        local ok, map = pcall(xp.getMultiplierMap, xp)
        if ok and map and map.clear then
            pcall(map.clear, map)
        end
    end

    if player.getNutrition then
        local ok, nutrition = pcall(player.getNutrition, player)
        if ok and nutrition and nutrition.applyWeightFromTraits then
            pcall(nutrition.applyWeightFromTraits, nutrition)
        end
    end

    if sendSyncPlayerFields then
        pcall(sendSyncPlayerFields, player, 0x00000003)
    end
    debugLog(string.format("ResetBuildEffects traitsRemoved=%d", removedTraits))
end
