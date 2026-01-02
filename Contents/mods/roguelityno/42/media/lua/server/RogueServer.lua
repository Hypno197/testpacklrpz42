if not isServer() then return end

Rogue = Rogue or {}
Rogue.Server = Rogue.Server or {}

local Server = Rogue.Server

if not Rogue.Config then require "RogueConfig" end
require "RogueZones"
require "RogueSpawns"
require "RogueEconomy"
require "RogueShop"
require "RogueProfessions"
require "RogueFullRestoreAction"

local Config = Rogue.Config
local Zones = Rogue.Zones
local Spawns = Rogue.Spawns
local Economy = Rogue.Economy
local FullRestore = Rogue.FullRestore

Server.STATE_IDLE = "IDLE"
Server.STATE_LOBBY = "LOBBY"
Server.STATE_PREP = "PREP"
Server.STATE_WAVE = "WAVE"
Server.STATE_POST = "POST"

Server.state = Server.state or {
    status = Server.STATE_IDLE,
    roundIndex = 0,
    maxRounds = 0,
    difficultyId = 1,
    targetPlayers = 0,
    debug = false,
    startedAtMs = 0,
    lastTickMs = 0,
    stateStartedAtMs = 0,
    waveStartedAtMs = 0,
    killsThisWave = 0,
    killTarget = 0,
    spawnBudgetRemaining = 0,
    currentTier = 1,
    spawnNextAtMs = 0,
    spawnIntervalMs = 0,
    lastCounterLogMs = 0,
    deathCheckNextAtMs = 0,
    noLiveArenaSinceMs = 0,
    readyStartAtMs = 0,
    arenaZoneName = "",
    safeZoneName = "",
    spawnZoneName = "",
    startSpawnPoint = nil,
    baseTier = 1,
    lastTierApplied = nil,
    originalArenaTier = nil,
    originalArenaSprinter = nil,
    overtimeAnnounced = false,
    hudNextAtMs = 0,
    scoreNextAtMs = 0,
    gatherNextAtMs = 0,
    sprinterAdjustNextAtMs = 0,
    beaconNextAtMs = 0,
    hudZeroLogAtMs = 0,
    overtimeSoonSent = false,
    statsSnapshotNextAtMs = 0,
}

Server.roundStats = Server.roundStats or {}

local REWARD_RARITIES = { "common", "uncommon", "rare", "epic", "legendary" }
local REWARD_RARITY_INDEX = { common = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5 }

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function getRarityRuleForSlot(slot)
    local rules = Config.REWARD_CATEGORY_RULES or {}
    for i = 1, #rules do
        local rule = rules[i]
        if rule and tonumber(rule.slot) == slot then
            return rule
        end
    end
    return nil
end

local function isRarityAllowed(rarity, rule)
    if not rule then return true end
    if rule.allowedRarities then
        for i = 1, #rule.allowedRarities do
            if rule.allowedRarities[i] == rarity then return true end
        end
        return false
    end
    local idx = REWARD_RARITY_INDEX[rarity] or 0
    if rule.minRarity then
        local minIdx = REWARD_RARITY_INDEX[rule.minRarity] or 0
        if idx < minIdx then return false end
    end
    if rule.maxRarity then
        local maxIdx = REWARD_RARITY_INDEX[rule.maxRarity] or 0
        if idx > maxIdx then return false end
    end
    return true
end

local function isTypeAllowed(entryType, rule)
    if not rule or not rule.types then return true end
    for i = 1, #rule.types do
        if rule.types[i] == entryType then return true end
    end
    return false
end

local function getRewardWeights(roundIndex, maxRounds, tier)
    local cfg = Config.REWARD_RARITY_WEIGHTS or {}
    local early = cfg.early or {}
    local late = cfg.late or {}
    local weights = {}
    local p = 0
    if maxRounds and maxRounds > 0 then
        p = clamp((roundIndex or 0) / maxRounds, 0, 1)
    end
    for i = 1, #REWARD_RARITIES do
        local rarity = REWARD_RARITIES[i]
        local e = tonumber(early[rarity] or 0) or 0
        local l = tonumber(late[rarity] or 0) or 0
        weights[rarity] = e + (l - e) * p
    end
    local shift = (tonumber(Config.DIFFICULTY_LEVEL) or 2) - 2
    if shift ~= 0 then
        weights.rare = (weights.rare or 0) + 2 * shift
        weights.epic = (weights.epic or 0) + 1.5 * shift
        weights.legendary = (weights.legendary or 0) + 0.5 * shift
        weights.common = (weights.common or 0) - 3 * shift
        weights.uncommon = (weights.uncommon or 0) - 1 * shift
    end
    local tierBump = cfg.tierBump or {}
    if tier and tier >= 6 and tierBump.tier6 then
        for key, value in pairs(tierBump.tier6) do
            weights[key] = (weights[key] or 0) + value
        end
    elseif tier and tier >= 5 and tierBump.tier5 then
        for key, value in pairs(tierBump.tier5) do
            weights[key] = (weights[key] or 0) + value
        end
    end
    local clampCfg = cfg.clamp or {}
    if clampCfg.legendaryMax then
        weights.legendary = math.min(weights.legendary or 0, clampCfg.legendaryMax)
    end
    if clampCfg.epicMax then
        weights.epic = math.min(weights.epic or 0, clampCfg.epicMax)
    end
    if clampCfg.commonMin then
        weights.common = math.max(weights.common or 0, clampCfg.commonMin)
    end
    local total = 0
    for i = 1, #REWARD_RARITIES do
        local rarity = REWARD_RARITIES[i]
        weights[rarity] = math.max(0, tonumber(weights[rarity] or 0) or 0)
        total = total + weights[rarity]
    end
    if total <= 0 then
        return { common = 100, uncommon = 0, rare = 0, epic = 0, legendary = 0 }
    end
    for i = 1, #REWARD_RARITIES do
        local rarity = REWARD_RARITIES[i]
        weights[rarity] = (weights[rarity] / total) * 100
    end
    return weights
end

local function pickWeightedRarity(weights, rule)
    local total = 0
    for i = 1, #REWARD_RARITIES do
        local rarity = REWARD_RARITIES[i]
        if isRarityAllowed(rarity, rule) then
            total = total + (weights[rarity] or 0)
        end
    end
    if total <= 0 then
        return "common"
    end
    local roll = ZombRand(0, 100000) / 1000
    local acc = 0
    for i = 1, #REWARD_RARITIES do
        local rarity = REWARD_RARITIES[i]
        if isRarityAllowed(rarity, rule) then
            acc = acc + (weights[rarity] or 0)
            if roll <= acc then
                return rarity
            end
        end
    end
    return "common"
end

local function pickRewardFromPool(rarity, rule, usedKeys)
    local pool = Config.REWARD_POOLS and Config.REWARD_POOLS[rarity] or {}
    if not pool or #pool == 0 then return nil end
    local filtered = {}
    for i = 1, #pool do
        local entry = pool[i]
        if entry and isTypeAllowed(entry.type, rule) then
            local key = tostring(entry.type) .. ":" .. tostring(entry.id or entry.skill or entry.amount or entry.qty or entry.levels or i)
            if not usedKeys or not usedKeys[key] then
                filtered[#filtered + 1] = entry
            end
        end
    end
    local source = filtered
    if #source == 0 then
        source = pool
    end
    if #source == 0 then return nil end
    return source[ZombRand(1, #source + 1)]
end

local function resolvePerk(perkId)
    if not perkId then return nil end
    if Perks and Perks[perkId] then
        return Perks[perkId]
    end
    if PerkFactory and PerkFactory.getPerkFromName then
        local ok, perk = pcall(PerkFactory.getPerkFromName, perkId)
        if ok and perk then return perk end
    end
    return nil
end

local function addXpBoostForPerk(xp, perk, mult)
    if not xp or not perk or not mult then return false end
    local ok = false
    if xp.addXpMultiplier then
        ok = pcall(function() xp:addXpMultiplier(perk, mult, 0, 0) end)
        ok = ok or pcall(function() xp:addXpMultiplier(perk, mult, 0) end)
        ok = ok or pcall(function() xp:addXpMultiplier(perk, mult) end)
        if ok then return true end
    end
    if xp.AddXPBoost then
        ok = pcall(function() xp:AddXPBoost(perk, mult) end)
        ok = ok or pcall(function() xp:AddXPBoost(perk, mult, 0) end)
        if ok then return true end
    end
    if xp.addXPBoost then
        ok = pcall(function() xp:addXPBoost(perk, mult) end)
        ok = ok or pcall(function() xp:addXPBoost(perk, mult, 0) end)
        if ok then return true end
    end
    if xp.setXPBoost then
        ok = pcall(function() xp:setXPBoost(perk, mult) end)
        if ok then return true end
    end
    if xp.setPerkBoost then
        ok = pcall(function() xp:setPerkBoost(perk, mult) end)
        if ok then return true end
    end
    return false
end

local function clearXpBoostForPerk(xp, perk)
    if not xp or not perk then return end
    if xp.setPerkBoost then pcall(xp.setPerkBoost, xp, perk, 0) end
    if xp.setXPBoost then pcall(xp.setXPBoost, xp, perk, 0) end
    if xp.AddXPBoost then pcall(xp.AddXPBoost, xp, perk, 0) end
    if xp.addXPBoost then pcall(xp.addXPBoost, xp, perk, 0) end
end

local function setPerkLevel(player, perk, level)
    local xp = player and player.getXp and player:getXp() or nil
    local target = math.floor(level or 0)
    if xp and xp.setPerkLevel then
        local ok = pcall(function() xp:setPerkLevel(perk, target) end)
        if not ok then
            pcall(function() xp:setPerkLevel(perk, target, true) end)
        end
    elseif xp and xp.setXPToLevel then
        pcall(function() xp:setXPToLevel(perk, target) end)
    end
    if player and player.setPerkLevel then
        pcall(function() player:setPerkLevel(perk, target) end)
    end
end

local function getPerkLevel(player, perk)
    if player and player.getPerkLevel then
        local ok, level = pcall(player.getPerkLevel, player, perk)
        if ok and level then return level end
    end
    local xp = player and player.getXp and player:getXp() or nil
    if xp and xp.getLevel then
        local ok, level = pcall(xp.getLevel, xp, perk)
        if ok and level then return level end
    end
    return 0
end

local function cleanupRewardBoosts(player, roundIndex)
    if not player or not player.getModData then return end
    local md = player:getModData()
    if not md or not md.RogueRewardBoosts then return end
    local xp = player.getXp and player:getXp() or nil
    local kept = {}
    for i = 1, #md.RogueRewardBoosts do
        local entry = md.RogueRewardBoosts[i]
        if entry and entry.expiresRound and roundIndex and roundIndex >= entry.expiresRound then
            local perk = resolvePerk(entry.perkId)
            if perk then
                clearXpBoostForPerk(xp, perk)
            end
        else
            kept[#kept + 1] = entry
        end
    end
    md.RogueRewardBoosts = kept
end

local function applyRewardChoice(player, choice, roundIndex)
    if not player or not choice then return false, "Invalid reward." end
    local entry = choice.entry or choice
    local rewardType = tostring(entry.type or "item")
    local md = player:getModData()
    if rewardType == "currency" then
        local amount = tonumber(entry.amount or entry.qty or 0) or 0
        if amount > 0 and Economy and Economy.addCurrency then
            Economy.addCurrency(player, amount)
            return true, { type = rewardType, amount = amount }
        end
    elseif rewardType == "item" or rewardType == "armor" or rewardType == "drug" or rewardType == "heal" then
        local id = entry.id
        local qty = math.max(1, tonumber(entry.qty or entry.amount or 1) or 1)
        if id and id ~= "" then
            local inv = player:getInventory()
            if inv and inv.AddItem then
                for i = 1, qty do
                    local item = inv:AddItem(id)
                    if item and sendAddItemToContainer then
                        sendAddItemToContainer(inv, item)
                    end
                end
                return true, { type = rewardType, id = id, qty = qty }
            end
        end
    elseif rewardType == "skill" then
        local perkId = entry.skill or entry.id
        local levels = tonumber(entry.levels or 1) or 1
        local perk = resolvePerk(perkId)
        if perk and levels > 0 then
            local current = getPerkLevel(player, perk)
            local target = math.min(10, math.max(0, current + levels))
            setPerkLevel(player, perk, target)
            return true, { type = rewardType, skill = perkId, levels = levels }
        end
    elseif rewardType == "xpBoost" then
        local perkId = entry.skill or entry.perk or entry.id
        local mult = tonumber(entry.amount or entry.mult or 0) or 0
        local duration = tonumber(entry.durationRounds or 0) or 0
        local perk = resolvePerk(perkId)
        if perk and mult > 0 then
            local xp = player.getXp and player:getXp() or nil
            addXpBoostForPerk(xp, perk, mult)
            md.RogueRewardBoosts = md.RogueRewardBoosts or {}
            md.RogueRewardBoosts[#md.RogueRewardBoosts + 1] = {
                perkId = perkId,
                mult = mult,
                expiresRound = duration > 0 and (roundIndex + duration) or nil,
            }
            return true, { type = rewardType, skill = perkId, amount = mult, durationRounds = duration }
        end
    elseif rewardType == "blessing" or rewardType == "trait" then
        local id = entry.id
        if id and id ~= "" then
            md.RogueBlessings = md.RogueBlessings or {}
            local list = md.RogueBlessings
            local cap = tonumber(entry.cap or 3) or 3
            if #list < cap then
                list[#list + 1] = id
                return true, { type = rewardType, id = id }
            end
        end
    end
    return false, "Reward could not be applied."
end

local function buildRewardChoices(player)
    local roundIndex = tonumber(Server.state.roundIndex or 0) or 0
    local maxRounds = tonumber(Server.state.maxRounds or 0) or 0
    local tier = tonumber(Server.state.currentTier or 1) or 1
    local weights = getRewardWeights(roundIndex, maxRounds, tier)
    local choices = {}
    local used = {}
    local count = math.max(1, tonumber(Config.REWARD_CHOICE_COUNT or 3) or 3)
    for slot = 1, count do
        local rule = getRarityRuleForSlot(slot)
        local rarity = pickWeightedRarity(weights, rule)
        local entry = pickRewardFromPool(rarity, rule, used)
        if entry then
            local key = tostring(entry.type) .. ":" .. tostring(entry.id or entry.skill or entry.amount or entry.qty or entry.levels or slot)
            used[key] = true
            choices[#choices + 1] = { rarity = rarity, entry = entry }
        end
    end
    return choices
end

local function log(msg)
    print("[Roguelityno] " .. tostring(msg))
end

local function debugLog(msg)
    if Server.state.debug then
        log(msg)
    end
end

local function isRunActive()
    return Server.state.status == Server.STATE_PREP
        or Server.state.status == Server.STATE_WAVE
        or Server.state.status == Server.STATE_POST
end

local function isArenaSquare(x, y, z)
    if not Config or not Config.isRectValid or not Config.isRectValid(Config.ZONES.ARENA) then return false end
    local rect = Config.ZONES.ARENA
    local rz = rect.z or 0
    if (z or 0) ~= rz then return false end
    return x >= rect.x1 and x <= rect.x2 and y >= rect.y1 and y <= rect.y2
end

local function trackPlacedObject(obj)
    if not obj or not obj.getSquare then return end
    if not isRunActive() then return end
    if not Server.state.runId then return end
    if instanceof(obj, "IsoWorldInventoryObject") then return end
    local sq = obj:getSquare()
    if not sq then return end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    if not isArenaSquare(x, y, z) then return end
    local md = obj.getModData and obj:getModData() or nil
    if md and md.RoguePlacedRun == Server.state.runId then return end
    if md then
        md.RoguePlacedRun = Server.state.runId
    end
    Server.state.placedObjects = Server.state.placedObjects or {}
    table.insert(Server.state.placedObjects, obj)
end

function Server.cleanupPlacedObjects()
    local list = Server.state.placedObjects
    if not list or #list == 0 then
        Server.state.placedObjects = {}
        return
    end
    for i = #list, 1, -1 do
        local obj = list[i]
        if obj and obj.getSquare then
            local sq = obj:getSquare()
            if sq then
                pcall(sq.transmitRemoveItemFromSquare, sq, obj)
            end
        end
        list[i] = nil
    end
    Server.state.placedObjects = {}
end

local function sendBuildIdToPlayer(player, buildId)
    if not player then return end
    debugLog(string.format("SendBuildId %s id=%s",
        tostring(player and player:getUsername() or "unknown"),
        tostring(buildId)
    ))
    sendServerCommand(player, "Rogue", "buildId", { id = buildId })
end

local function collectOutfitFromWorn(worn)
    if not worn or not worn.getItemByIndex then return nil end
    local list = {}
    for i = 0, worn:size() - 1 do
        local item = worn:getItemByIndex(i)
        if item and item.getFullType then
            list[#list + 1] = { id = item:getFullType() }
        end
    end
    return #list > 0 and list or nil
end

local function captureOutfitItems(player, desc)
    if player and player.getWornItems then
        local worn = player:getWornItems()
        local list = collectOutfitFromWorn(worn)
        if list then return list end
    end
    if desc and desc.getWornItems then
        local dworn = desc:getWornItems()
        local list = collectOutfitFromWorn(dworn)
        if list then return list end
    end
    return nil
end

local function restoreOutfitItems(player, items, desc)
    if not player then return end
    local inv = player.getInventory and player:getInventory() or nil
    if not inv then return end
    local debugOutfit = true
    if not items or #items == 0 then
        local worn = desc and desc.getWornItems and desc:getWornItems() or nil
        if debugOutfit then
            local wcount = worn and worn.size and worn:size() or -1
            print(string.format("[Roguelityno][OutfitDebug] descWorn=%s invItems=%s",
                tostring(wcount),
                tostring(inv.getItems and inv:getItems() and inv:getItems():size() or -1)
            ))
        end
        if worn and worn.addItemsToItemContainer then
            pcall(worn.addItemsToItemContainer, worn, inv)
            if player.setWornItems then
                pcall(player.setWornItems, player, worn)
            end
            if sendAddItemToContainer and worn.getItemByIndex then
                for i = 0, worn:size() - 1 do
                    local item = worn:getItemByIndex(i)
                    if item then
                        sendAddItemToContainer(inv, item)
                        if debugOutfit and inv.contains then
                            local ok, has = pcall(inv.contains, inv, item)
                            print(string.format("[Roguelityno][OutfitDebug] add %s inInv=%s",
                                tostring(item.getFullType and item:getFullType() or "?"),
                                tostring(ok and has or false)
                            ))
                        end
                    end
                end
            end
            if player.resetModel then
                pcall(player.resetModel, player)
            end
            return
        end
        items = captureOutfitItems(nil, desc) or {}
        if #items == 0 then return end
    end
    for i = 1, #items do
        local entry = items[i]
        local item = entry and entry.id and inv:AddItem(entry.id) or nil
        if item and sendAddItemToContainer then
            sendAddItemToContainer(inv, item)
        end
        if debugOutfit and item and inv.contains then
            local ok, has = pcall(inv.contains, inv, item)
            print(string.format("[Roguelityno][OutfitDebug] add %s inInv=%s",
                tostring(item.getFullType and item:getFullType() or "?"),
                tostring(ok and has or false)
            ))
        end
        if item and inv.contains then
            local ok, has = pcall(inv.contains, inv, item)
            if ok and not has and inv.AddItem then
                local ok2, added = pcall(inv.AddItem, inv, item)
                if ok2 and added and sendAddItemToContainer then
                    sendAddItemToContainer(inv, added)
                end
            end
        end
        if item and player.setWornItem and item.getBodyLocation then
            local bodyLoc = item:getBodyLocation()
            if bodyLoc then
                pcall(player.setWornItem, player, bodyLoc, item)
            end
        elseif item and entry and entry.bodyLocation and player.getWornItems then
            local worn = player:getWornItems()
            if worn and worn.setItem then
                pcall(worn.setItem, worn, entry.bodyLocation, item)
            end
        end
    end
    if player.resetModel then
        pcall(player.resetModel, player)
    end
end

local function logOutfitList(list, tag)
    local count = (type(list) == "table") and #list or 0
    local parts = {}
    for i = 1, count do
        local entry = list[i]
        if entry and entry.id then
            parts[#parts + 1] = tostring(entry.id)
        end
    end
    print(string.format("[Roguelityno][OutfitDebug] %s count=%d items=%s",
        tostring(tag or "unknown"),
        count,
        table.concat(parts, ",")
    ))
end

local function tryCaptureOutfit(player)
    if not player then return false end
    local md = player.getModData and player:getModData() or nil
    if not md then return false end
    if md.RogueOutfitItems and #md.RogueOutfitItems > 0 then
        return true
    end
    local desc = player.getDescriptor and player:getDescriptor() or nil
    local list = captureOutfitItems(player, desc)
    if (not list or #list == 0) and desc and desc.dressInNamedOutfit and md.RogueOutfitName and md.RogueOutfitName ~= "" then
        pcall(desc.dressInNamedOutfit, desc, md.RogueOutfitName)
        list = captureOutfitItems(player, desc)
    end
    if list and #list > 0 then
        md.RogueOutfitItems = list
        md.RogueOutfitPending = nil
        md.RogueOutfitNextAt = nil
        logOutfitList(list, "captured")
        return true
    end
    md.RogueOutfitPending = true
    if not md.RogueOutfitNextAt then
        md.RogueOutfitNextAt = 0
    end
    return false
end

local function safeCall(obj, fn, ...)
    if not obj then return end
    local f = obj[fn]
    if not f then return end
    pcall(f, obj, ...)
end

local function resyncWornItems(player)
    if not player or not player.getWornItems then return false end
    local worn = player:getWornItems()
    if not worn then return false end
    local inv = player.getInventory and player:getInventory() or nil
    for i = 0, worn:size() - 1 do
        local item = worn:getItemByIndex(i)
        if item then
            local loc = nil
            if item.getBodyLocation then
                loc = item:getBodyLocation()
            elseif item.canBeEquipped then
                loc = item:canBeEquipped()
            end
            if loc and player.setWornItem then
                if inv and inv.contains then
                    local ok, has = pcall(inv.contains, inv, item)
                    if ok and not has then
                        -- Skip items no longer in inventory.
                        loc = nil
                    end
                end
                if loc then
                    local ok = pcall(player.setWornItem, player, loc, nil, false)
                    if not ok then
                        pcall(player.setWornItem, player, loc, nil)
                    end
                    ok = pcall(player.setWornItem, player, loc, item, false)
                    if not ok then
                        pcall(player.setWornItem, player, loc, item)
                    end
                end
            end
        end
    end
    return true
end

function Server.resetPlayerForRun(player, reason)
    if not player then return end
    local md = player:getModData()
    if md then
        md.RogueBuildId = nil
        md.RogueBuildApplied = nil
        md.RogueLoadoutApplied = nil
        md.RogueTraitsApplied = nil
        md.RogueSkillsApplied = nil
        md.RogueBuildChosenLife = nil
        md.RogueOutsideSince = nil
        md.RogueOutsideWarned = nil
        md.RogueOutsideDamageStart = nil
        md.RogueOutsideLastDamageAt = nil
    end
    sendBuildIdToPlayer(player, nil)

    if Rogue.Professions and Rogue.Professions.resetBuildEffects then
        Rogue.Professions.resetBuildEffects(player)
    end

    local spawnPoint = Zones.getSpawnPoint and Zones.getSpawnPoint() or nil
    local safePoint = Zones.getSafePoint and Zones.getSafePoint() or nil
    local target = spawnPoint or safePoint
        or Config.PRISON_SPAWN_POINT
        or Config.teleportInPoint
        or (Config.ZONES.SPAWN and Config.getRectCenter(Config.ZONES.SPAWN))
        or (Config.ZONES.SAFE and Config.getRectCenter(Config.ZONES.SAFE))
    if target and Zones.teleportPlayer then
        Zones.teleportPlayer(player, target, getTimestampMs(), reason or "reset")
    end

    local inv = player.getInventory and player:getInventory() or nil
    if inv and inv.getItems then
        safeCall(player, "clearWornItems")
        local items = inv:getItems()
        if items then
            for i = items:size() - 1, 0, -1 do
                local item = items:get(i)
                inv:Remove(item)
                if sendRemoveItemFromContainer then
                    sendRemoveItemFromContainer(inv, item)
                end
            end
        end
    end
    safeCall(player, "setPrimaryHandItem", nil)
    safeCall(player, "setSecondaryHandItem", nil)

    local desc = player.getDescriptor and player:getDescriptor() or nil
    logOutfitList(md and md.RogueOutfitItems or nil, "md")
    restoreOutfitItems(player, md and md.RogueOutfitItems or nil, desc)
    sendServerCommand(player, "Rogue", "invRefresh", {
        delayMs = 500,
        tries = 5,
        intervalMs = 500,
    })
    if md then
        md.RogueWornResyncAt = getTimestampMs() + 500
        md.RogueWornResyncTries = 3
    end

    if FullRestore and FullRestore.apply then
        FullRestore.apply(player)
    end
    if Server.state and Server.state.debug then
        local bd = player.getBodyDamage and player:getBodyDamage() or nil
        local health = nil
        if bd then
            local ok, val = pcall(bd.getHealth, bd)
            if ok then health = val end
            if health == nil then
                ok, val = pcall(bd.getOverallBodyHealth, bd)
                if ok then health = val end
            end
        end
        log(string.format("ResetHealth %s health=%s",
            tostring(player and player:getUsername() or "unknown"),
            tostring(health)
        ))
        sendServerCommand(player, "Rogue", "debugHealth", { health = health })
    end
end

function Server.isAdmin(player)
    if not player then return false end
    local level = string.lower(player:getAccessLevel() or "none")
    return level == "admin"
end

function Server.notify(player, msg)
    if not msg then return end
    if player then
        sendServerCommand(player, "Rogue", "notify", { text = msg })
    else
        sendServerCommand("Rogue", "notify", { text = msg })
    end
end

function Server.broadcast(msg)
    Server.notify(nil, msg)
end

function Server.announce(player, msg)
    if not msg then return end
    if player then
        sendServerCommand(player, "Rogue", "announce", { text = msg })
    else
        sendServerCommand("Rogue", "announce", { text = msg })
    end
end

function Server.broadcastAnnounce(msg)
    Server.announce(nil, msg)
end

local function countSpawnReady()
    if not Config.isRectValid(Config.ZONES.SPAWN) then
        return 0, 0
    end
    local players = getOnlinePlayers()
    if not players then return 0, 0 end
    local liveInSpawn = 0
    local buildChosen = 0
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player and not player:isDead() and not player:isInvisible() then
            if Zones.isPlayerInRect(player, Config.ZONES.SPAWN) then
                liveInSpawn = liveInSpawn + 1
                local md = player:getModData()
                if md and md.RogueBuildId then
                    buildChosen = buildChosen + 1
                end
            end
        end
    end
    return liveInSpawn, buildChosen
end

function Server.sendHud(status, elapsedSec)
    if status ~= Server.STATE_IDLE and tonumber(elapsedSec) == 0 then
        local now = getTimestampMs()
        if now - (Server.state.hudZeroLogAtMs or 0) > 3000 then
            Server.state.hudZeroLogAtMs = now
            log(string.format("HUD elapsed=0 status=%s round=%s stateStarted=%s waveStarted=%s",
                tostring(status),
                tostring(Server.state.roundIndex),
                tostring(Server.state.stateStartedAtMs),
                tostring(Server.state.waveStartedAtMs)))
        end
    end
    local spawnLive, buildChosen = 0, 0
    if status == Server.STATE_LOBBY then
        spawnLive, buildChosen = countSpawnReady()
    end
    sendServerCommand("Rogue", "hud", {
        status = status,
        elapsedSec = elapsedSec,
        kills = Server.state.killsThisWave or 0,
        killTarget = Server.state.killTarget or 0,
        tier = Server.state.currentTier or 1,
        roundIndex = Server.state.roundIndex or 0,
        maxRounds = Server.state.maxRounds or 0,
        spawnLive = spawnLive,
        buildChosen = buildChosen,
    })
end

function Server.getPlayerKey(player)
    if not player then return "unknown" end
    local name = player:getUsername()
    if name and name ~= "" then
        return tostring(name)
    end
    local id = player.getOnlineID and player:getOnlineID() or nil
    if id and id >= 0 then
        return "id:" .. tostring(id)
    end
    return "unknown"
end

function Server.getRoundStats(player)
    local key = Server.getPlayerKey(player)
    local stats = Server.roundStats[key]
    if not stats then
        stats = { kills = 0, deaths = 0, streak = 0, gameDamage = 0, gameCurrency = 0 }
        Server.roundStats[key] = stats
    end
    return stats
end

function Server.getTotalStats(player)
    local key = Server.getPlayerKey(player)
    local all = ModData.getOrCreate("RoguelitynoStats")
    all[key] = all[key] or {}
    local s = all[key]
    s.totalKills = s.totalKills or 0
    s.totalDeaths = s.totalDeaths or 0
    s.totalDamage = s.totalDamage or 0
    s.totalCurrency = s.totalCurrency or 0
    return s
end

function Server.getDifficultyStatsStore()
    local all = ModData.getOrCreate("RoguelitynoPlayerStats")
    return all
end

function Server.getDifficultyStatsFor(player, diffId)
    local key = Server.getPlayerKey(player)
    local all = Server.getDifficultyStatsStore()
    all[key] = all[key] or { byDifficulty = {} }
    local byDiff = all[key].byDifficulty
    local did = tonumber(diffId) or 1
    byDiff[did] = byDiff[did] or {
        wins = 0,
        maxRunKills = 0,
        maxRunDamage = 0,
        maxRunCurrency = 0,
        maxRoundKills = 0,
        maxRoundReached = 0,
        totalKills = 0,
        totalDeaths = 0,
        totalDamage = 0,
        totalCurrency = 0,
    }
    return byDiff[did], all
end

function Server.resetRunRecordedFlags()
    local players = getOnlinePlayers()
    if not players then return end
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            local md = player:getModData()
            md.RogueRunRecorded = nil
            md.RogueMaxRoundKillsRun = 0
            md.RogueWaveKills = 0
        end
    end
end

function Server.recordRunStats(player, outcome)
    if not player then return end
    local md = player:getModData()
    if md and md.RogueRunRecorded then
        return
    end
    local diffId = Server.state.difficultyId or (Rogue.Config and Rogue.Config.DIFFICULTY_LEVEL) or 1
    local stats, all = Server.getDifficultyStatsFor(player, diffId)
    local round = Server.getRoundStats(player)
    local runKills = tonumber(round.kills or 0) or 0
    local runDamage = tonumber(round.gameDamage or 0) or 0
    local runCurrency = tonumber(round.gameCurrency or 0) or 0
    local maxRoundKillsRun = (md and tonumber(md.RogueMaxRoundKillsRun)) or 0
    stats.maxRunKills = math.max(stats.maxRunKills or 0, runKills)
    stats.maxRunDamage = math.max(stats.maxRunDamage or 0, runDamage)
    stats.maxRunCurrency = math.max(stats.maxRunCurrency or 0, runCurrency)
    stats.maxRoundKills = math.max(stats.maxRoundKills or 0, maxRoundKillsRun)
    stats.maxRoundReached = math.max(stats.maxRoundReached or 0, tonumber(Server.state.roundIndex or 0) or 0)
    stats.totalKills = (stats.totalKills or 0) + runKills
    stats.totalDamage = (stats.totalDamage or 0) + runDamage
    stats.totalCurrency = (stats.totalCurrency or 0) + runCurrency
    if outcome == "death" then
        stats.totalDeaths = (stats.totalDeaths or 0) + 1
    elseif outcome == "win" then
        stats.wins = (stats.wins or 0) + 1
    end
    if md then
        md.RogueRunRecorded = true
    end
    ModData.add("RoguelitynoPlayerStats", all)
    ModData.transmit("RoguelitynoPlayerStats")
end

function Server.snapshotRunStats()
    local data = ModData.getOrCreate("RoguelitynoPlayerStats")
    ModData.add("RoguelitynoPlayerStats", data)
    ModData.transmit("RoguelitynoPlayerStats")
end

function Server.resetRoundStats()
    Server.roundStats = {}
    if Economy and Economy.resetWallets then
        Economy.resetWallets()
    end
    local players = getOnlinePlayers()
    if not players then return end
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            local key = Server.getPlayerKey(player)
            Server.roundStats[key] = { kills = 0, deaths = 0, streak = 0, gameDamage = 0, gameCurrency = 0 }
            if Economy and Economy.setWallet then
                Economy.setWallet(player, Config.STARTING_CURRENCY or 0)
            end
        end
    end
end

function Server.resetTotalStats()
    ModData.add("RoguelitynoStats", {})
    ModData.transmit("RoguelitynoStats")
end

function Server.hardResetPlayers(nowMs)
    local players = getOnlinePlayers()
    if not players then return end
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            local md = player:getModData()
            md.RogueBuildApplied = nil
            md.RogueLoadoutApplied = nil
            md.RogueTraitsApplied = nil
            md.RogueSkillsApplied = nil
            md.RogueBuildId = nil
            if not player:isDead() then
                local body = player:getBodyDamage()
                if body then
                    body:ReduceGeneralHealth(1000)
                end
            end
        end
    end
    if nowMs then
        Server.state.lastTickMs = nowMs
    end
end

function Server.resetBuildSelections()
    local players = getOnlinePlayers()
    if not players then return end
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            local md = player:getModData()
            md.RogueBuildId = nil
            md.RogueBuildApplied = nil
            md.RogueLoadoutApplied = nil
            md.RogueTraitsApplied = nil
            md.RogueSkillsApplied = nil
        end
    end
end

function Server.sendScoreboard()
    local players = getOnlinePlayers()
    if not players then return end
    local topRound = Server.buildTop5Round()
    local topAll = Server.buildTop5AllTime()
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        Server.sendScoreToPlayer(player, topRound, topAll)
    end
end

function Server.buildTop5Round()
    local top = {}
    for name, stats in pairs(Server.roundStats) do
        table.insert(top, {
            name = name,
            kills = stats.kills or 0,
            deaths = stats.deaths or 0,
            streak = stats.streak or 0,
        })
    end
    table.sort(top, function(a, b)
        if a.kills == b.kills then
            return a.deaths < b.deaths
        end
        return a.kills > b.kills
    end)
    local top5 = {}
    for i = 1, math.min(5, #top) do
        top5[i] = top[i]
    end
    return top5
end

function Server.buildTop5AllTime()
    local top = {}
    local all = ModData.getOrCreate("RoguelitynoStats")
    for name, stats in pairs(all) do
        table.insert(top, {
            name = name,
            kills = stats.totalKills or 0,
            deaths = stats.totalDeaths or 0,
        })
    end
    table.sort(top, function(a, b)
        if a.kills == b.kills then
            return a.deaths < b.deaths
        end
        return a.kills > b.kills
    end)
    local top5 = {}
    for i = 1, math.min(5, #top) do
        top5[i] = top[i]
    end
    return top5
end

function Server.sendScoreToPlayer(player, topRound, topAll)
    if not player then return end
    local round = Server.getRoundStats(player)
    local total = Server.getTotalStats(player)
    local wallet = Economy and Economy.getWallet and Economy.getWallet(player) or 0
    sendServerCommand(player, "Rogue", "score", {
        status = Server.state.status,
        roundKills = round.kills or 0,
        roundDeaths = round.deaths or 0,
        roundStreak = round.streak or 0,
        roundDamage = round.gameDamage or 0,
        roundCurrency = round.gameCurrency or 0,
        waveKills = round.waveKills or 0,
        waveDamage = round.waveDamage or 0,
        wallet = wallet,
        totalKills = total.totalKills or 0,
        totalDeaths = total.totalDeaths or 0,
        totalDamage = total.totalDamage or 0,
        totalCurrency = total.totalCurrency or 0,
        topRound = topRound or Server.buildTop5Round(),
        topAll = topAll or Server.buildTop5AllTime(),
    })
end

function Server.setTierZonyneTier(zoneName, tier)
    if not zoneName or zoneName == "" then return end
    local md = ModData.getOrCreate("TierZonyne")
    local zone = md[zoneName]
    if not zone then
        debugLog("TierZonyne zone missing: " .. tostring(zoneName))
        return
    end
    local newTier = math.max(1, math.min(6, math.floor(tonumber(tier) or 1)))
    local runnerMap = Config.TIER_RUNNER_PCT or {}
    local runnerPct = runnerMap[newTier]
    local curTier = tonumber(zone[5]) or 1
    if curTier == newTier and runnerPct == nil then return end
    zone[5] = newTier
    if runnerPct ~= nil then
        zone[8] = runnerPct
    end
    md[zoneName] = zone
    if Zone and Zone.list and Zone.list[zoneName] then
        Zone.list[zoneName][5] = newTier
        if runnerPct ~= nil then
            Zone.list[zoneName][8] = runnerPct
        end
    end
    if NestedZone and NestedZone.list and NestedZone.list[zoneName] then
        NestedZone.list[zoneName][5] = newTier
        if runnerPct ~= nil then
            NestedZone.list[zoneName][8] = runnerPct
        end
    end
    if populateZoneNames then
        populateZoneNames()
    end
    ModData.transmit("TierZonyne")
end

function Server.applyArenaTier(tier)
    local arenaName = Server.state.arenaZoneName
    if not arenaName or arenaName == "" then return end
    local newTier = math.max(1, math.min(6, math.floor(tonumber(tier) or 1)))
    if Server.state.lastTierApplied == newTier then return end
    Server.state.lastTierApplied = newTier
    Server.setTierZonyneTier(arenaName, newTier)
end

function Server.resetState()
    Server.state.status = Server.STATE_IDLE
    Server.state.roundIndex = 0
    Server.state.maxRounds = 0
    Server.state.difficultyId = 1
    Server.state.targetPlayers = 0
    Server.state.startedAtMs = 0
    Server.state.stateStartedAtMs = 0
    Server.state.waveStartedAtMs = 0
    Server.state.killsThisWave = 0
    Server.state.killTarget = 0
    Server.state.spawnBudgetRemaining = 0
    Server.state.currentTier = 1
    Server.state.spawnNextAtMs = 0
    Server.state.spawnIntervalMs = 0
    Server.state.lastCounterLogMs = 0
    Server.state.deathCheckNextAtMs = 0
    Server.state.noLiveArenaSinceMs = 0
    Server.state.readyStartAtMs = 0
    Server.state.arenaZoneName = ""
    Server.state.safeZoneName = ""
    Server.state.spawnZoneName = ""
    Server.state.startSpawnPoint = nil
    Server.state.baseTier = 1
    Server.state.lastTierApplied = nil
    Server.state.originalArenaTier = nil
    Server.state.originalArenaSprinter = nil
    Server.state.overtimeAnnounced = false
    Server.state.overtimeSoonSent = false
    Server.state.statsSnapshotNextAtMs = 0
    Server.state.hudNextAtMs = 0
    Server.state.scoreNextAtMs = 0
    Server.state.gatherNextAtMs = 0
    Server.state.sprinterAdjustNextAtMs = 0
    Server.state.beaconNextAtMs = 0
    Server.roundStats = {}
end

local function getArenaBounds()
    if not Config.isRectValid(Config.ZONES.ARENA) then
        return nil
    end
    local rect = Config.ZONES.ARENA
    local x1 = math.min(rect.x1, rect.x2)
    local x2 = math.max(rect.x1, rect.x2)
    local y1 = math.min(rect.y1, rect.y2)
    local y2 = math.max(rect.y1, rect.y2)
    return x1, y1, x2, y2, rect.z or 0
end

local function emitArenaBeacon()
    if not Config.BEACON_ENABLED then return end
    if not addSound then return end
    local x1, y1, x2, y2, z = getArenaBounds()
    if not x1 then return end
    local cx = (x1 + x2) / 2
    local cy = (y1 + y2) / 2
    local dx = (x2 - x1) / 2
    local dy = (y2 - y1) / 2
    local base = math.sqrt(dx * dx + dy * dy)
    local buffer = Config.SPAWN_ARENA_BUFFER or 0
    local extra = Config.BEACON_EXTRA_RADIUS or 0
    local tierStep = Config.BEACON_TIER_STEP or 0
    local tier = Server.state.currentTier or 1
    local radius = base + buffer + extra + math.max(0, tier - 1) * tierStep
    local volume = Config.BEACON_VOLUME or 50
    pcall(addSound, nil, cx, cy, z, radius, volume)
end

function Server.tokenize(str)
    local tokens = {}
    if not str then return tokens end
    for token in string.gmatch(str, "%S+") do
        table.insert(tokens, token)
    end
    return tokens
end

function Server.sendUsage(player)
    Server.notify(player, "Usage: /rogue start <targetPlayers> <maxRounds> | stop | status | debug on|off | refreshzones")
end

function Server.sendStatus(player)
    log("Status requested by " .. tostring(player and player:getUsername() or "server"))
    if Server.state.status == Server.STATE_WAVE then
        Server.notify(player, string.format(
            "ROGUELITYNO %s | round %d/%d | kills %d/%d | tier T%d",
            Server.state.status,
            Server.state.roundIndex,
            Server.state.maxRounds,
            Server.state.killsThisWave or 0,
            Server.state.killTarget or 0,
            Server.state.currentTier or 1
        ))
    else
        Server.notify(player, string.format(
            "ROGUELITYNO %s | round %d/%d | targetPlayers %d",
            Server.state.status,
            Server.state.roundIndex,
            Server.state.maxRounds,
            Server.state.targetPlayers
        ))
    end
end

function Server.setDebugFlag(player, flag)
    log("Debug flag request by " .. tostring(player and player:getUsername() or "server") .. " -> " .. tostring(flag))
    if not Server.isAdmin(player) then
        Server.notify(player, "Admin only.")
        return
    end
    if flag ~= "on" and flag ~= "off" then
        Server.sendUsage(player)
        return
    end
    Server.state.debug = (flag == "on")
    Server.notify(player, "Debug: " .. (Server.state.debug and "on" or "off"))
end

function Server.refreshZonesFromTierZonyne(player)
    if not Server.isAdmin(player) then
        Server.notify(player, "Admin only.")
        return
    end
    if Server.state.status ~= Server.STATE_IDLE and Server.state.status ~= Server.STATE_LOBBY then
        Server.notify(player, "refreshzones only allowed in IDLE or LOBBY.")
        return
    end
    local md = ModData.getOrCreate("TierZonyne")
    local arenaName = Server.state.arenaZoneName
    local safeName = Server.state.safeZoneName
    local lobbyName = Server.state.spawnZoneName
    if not lobbyName or lobbyName == "" then
        lobbyName = Config.LOBBY_TIERZONE_NAME or "ROGUESPAWN"
    end
    if not arenaName or arenaName == "" or not md[arenaName] then
        Server.notify(player, "Arena zone missing in TierZonyne: " .. tostring(arenaName))
        return
    end
    if not safeName or safeName == "" or not md[safeName] then
        Server.notify(player, "Safe zone missing in TierZonyne: " .. tostring(safeName))
        return
    end
    if not lobbyName or lobbyName == "" or not md[lobbyName] then
        Server.notify(player, "Spawn lobby zone missing in TierZonyne: " .. tostring(lobbyName))
        return
    end
    local a = md[arenaName]
    local s = md[safeName]
    local l = md[lobbyName]
    Config.ZONES.ARENA = { x1 = a[1], y1 = a[2], x2 = a[3], y2 = a[4], z = 0 }
    Config.ZONES.SAFE = { x1 = s[1], y1 = s[2], x2 = s[3], y2 = s[4], z = 0 }
    Config.ZONES.SPAWN = { x1 = l[1], y1 = l[2], x2 = l[3], y2 = l[4], z = 0 }
    Server.state.originalArenaTier = tonumber(a[5]) or 1
    Server.state.originalArenaSprinter = tonumber(a[8]) or 0
    Server.transmitZones()
    Server.notify(player, "Zones refreshed from TierZonyne.")
    log("Zones refreshed from TierZonyne.")
end

function Server.startFromParams(player, targetPlayers, maxRounds, args)
    log(string.format("Start request by %s targetPlayers=%s maxRounds=%s",
        tostring(player and player:getUsername() or "server"),
        tostring(targetPlayers),
        tostring(maxRounds)
    ))
    if not Server.isAdmin(player) then
        Server.notify(player, "Admin only.")
        return
    end
    if Server.state.status ~= Server.STATE_IDLE then
        Server.notify(player, "Roguelityno already running.")
        return
    end
    local tPlayers = tonumber(targetPlayers)
    local mRounds = tonumber(maxRounds)
    if not tPlayers or not mRounds then
        Server.sendUsage(player)
        return
    end

    local arenaName = args and args.arenaZoneName or nil
    local safeName = args and args.safeZoneName or nil
    if arenaName ~= nil then arenaName = tostring(arenaName):gsub("^%s+", ""):gsub("%s+$", "") end
    if safeName ~= nil then safeName = tostring(safeName):gsub("^%s+", ""):gsub("%s+$", "") end
    if arenaName == "" then arenaName = nil end
    if safeName == "" then safeName = nil end

    local md = ModData.getOrCreate("TierZonyne")
    if safeName == nil and arenaName then
        local fallbackSafe = tostring(arenaName) .. "SAFE"
        if md[fallbackSafe] then
            safeName = fallbackSafe
        end
    end

    if not arenaName or not safeName then
        Server.notify(player, "Arena and Safe zone names are required.")
        return
    end
    if not md[arenaName] then
        Server.notify(player, "Arena zone not found in TierZonyne: " .. tostring(arenaName))
        return
    end
    if not md[safeName] then
        Server.notify(player, "Safe zone not found in TierZonyne: " .. tostring(safeName))
        return
    end
    local lobbyName = Config.LOBBY_TIERZONE_NAME or "ROGUESPAWN"
    if not md[lobbyName] then
        Server.notify(player, "Spawn lobby zone not found in TierZonyne: " .. tostring(lobbyName))
        return
    end
    Server.state.arenaZoneName = arenaName
    Server.state.safeZoneName = safeName
    Server.state.spawnZoneName = lobbyName
    local a = md[arenaName]
    local s = md[safeName]
    local l = md[lobbyName]
    Config.ZONES.ARENA = { x1 = a[1], y1 = a[2], x2 = a[3], y2 = a[4], z = 0 }
    Config.ZONES.SAFE = { x1 = s[1], y1 = s[2], x2 = s[3], y2 = s[4], z = 0 }
    Config.ZONES.SPAWN = { x1 = l[1], y1 = l[2], x2 = l[3], y2 = l[4], z = 0 }
    Server.state.originalArenaTier = tonumber(a[5]) or 1
    Server.state.originalArenaSprinter = tonumber(a[8]) or 0
    Server.transmitZones()
    Server.refreshZonesFromTierZonyne(player)

    local spawnCoord = args and args.spawnCoord or nil
    if spawnCoord and tostring(spawnCoord):gsub("%s+", "") ~= "" then
        local nums = {}
        for n in tostring(spawnCoord):gmatch("[-%d%.]+") do
            table.insert(nums, tonumber(n))
        end
        if #nums < 2 then
            Server.notify(player, "Spawn coord invalid. Use x,y,z")
            return
        end
        Server.state.startSpawnPoint = { x = nums[1], y = nums[2], z = nums[3] or 0 }
    else
        Server.state.startSpawnPoint = nil
    end

    local diff = args and args.difficulty or nil
    if diff ~= nil and Rogue.Config and Rogue.Config.applyDifficulty then
        Rogue.Config.applyDifficulty(diff)
    end
    Server.state.difficultyId = tonumber(Rogue.Config and Rogue.Config.DIFFICULTY_LEVEL) or 1

    if not Config.hasValidSetup() then
        Server.notify(player, "Set zone coords and set ZONE_SETUP_REQUIRED=false in RogueConfig.lua")
        return
    end

    Server.resetBuildSelections()
    Server.resetRoundStats()
    Server.resetRunRecordedFlags()
    if Rogue.Shop and Rogue.Shop.resetStock then
        Rogue.Shop.resetStock()
    end
    Server.state.targetPlayers = math.max(1, math.floor(tPlayers))
    Server.state.maxRounds = math.max(1, math.floor(mRounds))
    Server.state.roundIndex = 1
    Server.state.startedAtMs = getTimestampMs()
    local interval = (tonumber(Config.STATS_SNAPSHOT_MINUTES) or 0) * 60000
    Server.state.statsSnapshotNextAtMs = interval > 0 and (Server.state.startedAtMs + interval) or 0
    Server.cleanupArena("start")
    Server.startLobby(Server.state.startedAtMs)

    local live = Server.countLivePlayers()
    Server.broadcastAnnounce(string.format(
        "ROGUELITYNO run started: difficulty=%d livePlayers=%d maxRounds=%d",
        tonumber(Rogue.Config and Rogue.Config.DIFFICULTY_LEVEL or 1) or 1,
        tonumber(live or 0) or 0,
        tonumber(Server.state.maxRounds or 0) or 0
    ))
end

function Server.startLobby(nowMs)
    Server.state.status = Server.STATE_LOBBY
    Server.state.stateStartedAtMs = nowMs
    Server.state.gatherNextAtMs = nowMs
    local players = getOnlinePlayers()
    if players then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player then
                local md = player:getModData()
                md.RogueBuildId = nil
                md.RogueBuildChosenLife = nil
                md.RogueOutsideSince = nil
                md.RogueOutsideWarned = nil
                md.RogueOutsideDamageStart = nil
                md.RogueOutsideLastDamageAt = nil
            end
            sendBuildIdToPlayer(player, nil)
        end
    end
    log("State -> LOBBY")
    Server.gatherPlayersOutsideSpawn(nowMs, "lobby-gather")
end

function Server.stopFromCommand(player)
    log("Stop request by " .. tostring(player and player:getUsername() or "server"))
    if not Server.isAdmin(player) then
        Server.notify(player, "Admin only.")
        return
    end
    if Server.state.status ~= Server.STATE_IDLE then
        Server.finishRun(getTimestampMs(), false)
    end
    Server.cleanupArena("stop")
    Server.cleanupPlacedObjects()
    if Server.state.arenaZoneName ~= "" and Server.state.originalArenaTier then
        Server.setTierZonyneTier(Server.state.arenaZoneName, Server.state.originalArenaTier)
    end
    if Server.state.arenaZoneName ~= "" and Server.state.originalArenaSprinter ~= nil then
        local md = ModData.getOrCreate("TierZonyne")
        local zone = md[Server.state.arenaZoneName]
        if zone then
            zone[8] = Server.state.originalArenaSprinter
            md[Server.state.arenaZoneName] = zone
            if Zone and Zone.list and Zone.list[Server.state.arenaZoneName] then
                Zone.list[Server.state.arenaZoneName][8] = Server.state.originalArenaSprinter
            end
            if NestedZone and NestedZone.list and NestedZone.list[Server.state.arenaZoneName] then
                NestedZone.list[Server.state.arenaZoneName][8] = Server.state.originalArenaSprinter
            end
            if populateZoneNames then
                populateZoneNames()
            end
            ModData.transmit("TierZonyne")
        end
    end
    local players = getOnlinePlayers()
    if players then
        for i = 0, players:size() - 1 do
            local p = players:get(i)
            if p then
                Server.resetPlayerForRun(p, "stop-reset")
            end
        end
    end
    Server.resetState()
    Server.sendHud(Server.STATE_IDLE, 0)
    Server.broadcastAnnounce("ROGUELITYNO stopped.")
end

function Server.countLivePlayers()
    local players = getOnlinePlayers()
    if not players then
        players = IsoPlayer.getPlayers()
    end
    if not players then return 0 end

    local count = 0
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player and not player:isDead() and not player:isInvisible() then
            count = count + 1
        end
    end
    return count
end

function Server.cleanupArena(reason)
    if not Config.isRectValid(Config.ZONES.ARENA) then return end
    local rect = Config.ZONES.ARENA
    local buffer = math.max(0, math.floor(tonumber(Config.OUTSIDE_ARENA_MAX_BUFFER or 0) or 0))
    local x1 = math.floor(math.min(rect.x1, rect.x2) - buffer)
    local x2 = math.floor(math.max(rect.x1, rect.x2) + buffer)
    local y1 = math.floor(math.min(rect.y1, rect.y2) - buffer)
    local y2 = math.floor(math.max(rect.y1, rect.y2) + buffer)
    local ax1 = math.floor(math.min(rect.x1, rect.x2))
    local ax2 = math.floor(math.max(rect.x1, rect.x2))
    local ay1 = math.floor(math.min(rect.y1, rect.y2))
    local ay2 = math.floor(math.max(rect.y1, rect.y2))
    local z = rect.z or 0
    local cell = getCell()
    if not cell then return end

    for x = x1, x2 do
        for y = y1, y2 do
            local square = cell:getGridSquare(x, y, z)
            if square then
                local moving = square:getMovingObjects()
                if moving then
                    for i = moving:size() - 1, 0, -1 do
                        local obj = moving:get(i)
                        if instanceof(obj, "IsoZombie") then
                            obj:removeFromWorld()
                            obj:removeFromSquare()
                        elseif instanceof(obj, "IsoDeadBody") then
                            obj:removeFromWorld()
                            obj:removeFromSquare()
                        end
                    end
                end

                local dead = square:getDeadBodys()
                if dead then
                    for i = dead:size() - 1, 0, -1 do
                        local body = dead:get(i)
                        body:removeFromWorld()
                        body:removeFromSquare()
                    end
                end
                local statics = square:getStaticMovingObjects()
                if statics then
                    for i = statics:size() - 1, 0, -1 do
                        local obj = statics:get(i)
                        if instanceof(obj, "IsoDeadBody") then
                            obj:removeFromWorld()
                            obj:removeFromSquare()
                        end
                    end
                end
                local objects = square:getObjects()
                if objects then
                    for i = objects:size() - 1, 0, -1 do
                        local obj = objects:get(i)
                        if instanceof(obj, "IsoDeadBody") then
                            obj:removeFromWorld()
                            obj:removeFromSquare()
                        end
                    end
                end

                if reason == "start" then
                    local worldItems = square:getWorldObjects()
                    if worldItems then
                        for i = worldItems:size() - 1, 0, -1 do
                            local obj = worldItems:get(i)
                            if instanceof(obj, "IsoWorldInventoryObject") then
                                obj:removeFromWorld()
                                obj:removeFromSquare()
                            end
                        end
                    end

                    if x >= ax1 and x <= ax2 and y >= ay1 and y <= ay2 then
                        local objects = square:getObjects()
                        if objects then
                            for i = 0, objects:size() - 1 do
                                local obj = objects:get(i)
                                if obj and obj.getContainerCount then
                                    local cnt = obj:getContainerCount()
                                    for c = 0, cnt - 1 do
                                        local container = obj:getContainerByIndex(c)
                                        if container then
                                            container:clear()
                                        end
                                    end
                                elseif obj and obj.getContainer then
                                    local container = obj:getContainer()
                                    if container then
                                        container:clear()
                                    end
                                end
                            end
                        end
                    end
                end

                square:removeBlood(false, false)
            end
        end
    end
end

function Server.transmitZones()
    local data = ModData.getOrCreate("RoguelitynoZones")
    data.ARENA = Config.ZONES.ARENA
    data.SAFE = Config.ZONES.SAFE
    data.SPAWN = Config.ZONES.SPAWN
    ModData.add("RoguelitynoZones", data)
    ModData.transmit("RoguelitynoZones")
end

function Server.sendMapList(player)
    if not Server.isAdmin(player) then
        Server.notify(player, "Admin only.")
        return
    end
    local md = ModData.getOrCreate("TierZonyne")
    local maps = {}
    for name, _ in pairs(md) do
        if type(name) == "string" and name:sub(1, 3) == "RA_" then
            if name:sub(-4) ~= "SAFE" then
                local trimmed = name:sub(4)
                table.insert(maps, trimmed)
            end
        end
    end
    table.sort(maps)
    local list = table.concat(maps, ", ")
    log("Roguelityno mapList: " .. (list ~= "" and list or "<none>"))
    if player then
        Server.notify(player, "mapList: " .. (list ~= "" and list or "<none>"))
        sendServerCommand(player, "Rogue", "mapList", { items = maps })
    end
end

function Server.onPlayerDisconnect(player)
    if not player then return end
    if Server.state.status == Server.STATE_IDLE then return end
    Server.recordRunStats(player, "end")
end

function Server.countLivePlayersInArena()
    if not Config.isRectValid(Config.ZONES.ARENA) then
        return Server.countLivePlayers()
    end
    local rect = Config.ZONES.ARENA
    local buffer = math.max(
        Config.ARENA_ALIVE_BUFFER or 0,
        Config.OUTSIDE_ARENA_BUFFER or 0,
        Config.SPAWN_ARENA_BUFFER or 0
    )
    local padded = {
        x1 = math.min(rect.x1, rect.x2) - buffer,
        y1 = math.min(rect.y1, rect.y2) - buffer,
        x2 = math.max(rect.x1, rect.x2) + buffer,
        y2 = math.max(rect.y1, rect.y2) + buffer,
        z = rect.z or 0,
    }
    local players = getOnlinePlayers()
    if not players then
        players = IsoPlayer.getPlayers()
    end
    if not players then return 0 end

    local count = 0
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player and not player:isDead() and not player:isInvisible() then
            if Zones.isPlayerInRect(player, padded) then
                count = count + 1
            end
        end
    end
    return count
end

function Server.trackDeaths()
    local players = getOnlinePlayers()
    if not players then
        players = IsoPlayer.getPlayers()
    end
    if not players then return end

    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player and not player:isInvisible() then
            local md = player:getModData()
            local dead = player:isDead()
            if dead then
                if not md.RogueDeathRecorded then
                    Server.onPlayerDeath(player)
                end
            elseif md.RogueDeathRecorded then
                md.RogueDeathRecorded = nil
            end
        end
    end
end

function Server.startPrep(nowMs, isInitial)
    Server.state.status = Server.STATE_PREP
    Server.state.stateStartedAtMs = nowMs
    Server.state.killsThisWave = 0
    Server.state.killTarget = 0
    Server.state.spawnBudgetRemaining = 0
    Server.state.currentTier = 1
    Server.state.waveStartedAtMs = 0
    Server.state.spawnNextAtMs = 0
    Server.applyArenaTier(1)
    Server.state.gatherNextAtMs = nowMs
    if isInitial then
        Server.state.runId = nowMs
        Server.state.placedObjects = {}
    end

    if not isInitial then
        Server.broadcastAnnounce(string.format("PREP started for round %d.", Server.state.roundIndex))
    end
    log("State -> PREP round=" .. tostring(Server.state.roundIndex))

    Server.gatherPlayersOutsideArena(nowMs, "prep-gather")
    local players = getOnlinePlayers()
    if players then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player and not player:isDead() and not player:isInvisible() then
                cleanupRewardBoosts(player, Server.state.roundIndex)
            end
        end
    end
    if Rogue.Shop and Rogue.Shop.applyRoundStock then
        local playersLive = Server.countLivePlayers()
        Rogue.Shop.applyRoundStock(Server.state.roundIndex, playersLive, isInitial)
    end

    if isInitial and Server.state.startSpawnPoint and Server.state.spawnZoneName == "" then
        if players then
            for i = 0, players:size() - 1 do
                local player = players:get(i)
                if player and not player:isDead() and not player:isInvisible() then
                    Zones.teleportPlayer(player, Server.state.startSpawnPoint, nowMs, "start-spawn")
                end
            end
        end
    end
end

function Server.gatherPlayersOutsideArena(nowMs, reason)
    if not Config.isRectValid(Config.ZONES.ARENA) then return end
    local players = getOnlinePlayers()
    if not players then return end
    local safePoint = Zones.getSafePoint()
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player and not player:isDead() and not player:isInvisible() then
            if not Zones.isPlayerInRect(player, Config.ZONES.ARENA) then
                Zones.teleportPlayer(player, safePoint, nowMs, reason or "gather")
            end
        end
    end
end

function Server.allPlayersInSpawnZone()
    if not Config.isRectValid(Config.ZONES.SPAWN) then return false end
    local players = getOnlinePlayers()
    if not players then return false end
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player and not player:isDead() and not player:isInvisible() then
            if not Zones.isPlayerInRect(player, Config.ZONES.SPAWN) then
                return false
            end
        end
    end
    return true
end

function Server.allPlayersReadyInSpawn()
    if not Config.isRectValid(Config.ZONES.SPAWN) then return false end
    local players = getOnlinePlayers()
    if not players then return false end
    local live = 0
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player and not player:isDead() and not player:isInvisible() then
            live = live + 1
            if not Zones.isPlayerInRect(player, Config.ZONES.SPAWN) then
                return false
            end
            local md = player:getModData()
            if not md.RogueBuildId then
                return false
            end
        end
    end
    return live > 0
end

function Server.gatherPlayersOutsideSpawn(nowMs, reason)
    if not Config.isRectValid(Config.ZONES.SPAWN) then return end
    local players = getOnlinePlayers()
    if not players then return end
    local spawnPoint = Zones.getSpawnPoint()
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player and not player:isDead() and not player:isInvisible() then
            if not Zones.isPlayerInRect(player, Config.ZONES.SPAWN) then
                Zones.teleportPlayer(player, spawnPoint, nowMs, reason or "spawn-gather")
            end
        end
    end
end

function Server.startWave(nowMs)
    local playersLive = Server.countLivePlayers()
    Server.state.status = Server.STATE_WAVE
    Server.state.stateStartedAtMs = nowMs
    Server.state.waveStartedAtMs = nowMs
    Server.state.killsThisWave = 0
    Server.state.noLiveArenaSinceMs = 0
    Server.state.killTarget = Config.getKillTarget(playersLive, Server.state.roundIndex)
    Server.state.spawnBudgetRemaining = Config.getSpawnBudget(Server.state.killTarget)
    Server.state.baseTier = Config.getBaseTier(Server.state.roundIndex, Server.state.maxRounds)
    Server.state.currentTier = Server.state.baseTier
    Server.state.overtimeAnnounced = false
    Server.state.overtimeSoonSent = false
    Server.state.lastTierApplied = nil
    Server.state.beaconNextAtMs = nowMs

    Spawns.init(Server.state, nowMs)
    Server.applyArenaTier(Server.state.currentTier)
    local players = getOnlinePlayers()
    if players then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player and not player:isInvisible() then
                local round = Server.getRoundStats(player)
                round.waveKills = 0
                round.waveDamage = 0
            end
        end
    end
    local players = getOnlinePlayers()
    if players then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player and not player:isInvisible() then
                local md = player:getModData()
                md.RogueWaveKills = 0
            end
        end
    end

    Server.broadcastAnnounce(string.format(
        "ROUND %d/%d - Tier base T%d - Target: %d kills",
        Server.state.roundIndex,
        Server.state.maxRounds,
        Server.state.currentTier,
        Server.state.killTarget
    ))
    log(string.format("State -> WAVE round=%d killTarget=%d budget=%d tier=%d players=%d",
        Server.state.roundIndex,
        Server.state.killTarget or 0,
        Server.state.spawnBudgetRemaining or 0,
        Server.state.currentTier or 1,
        playersLive
    ))
end

function Server.startPost(nowMs, isFailed)
    Server.state.status = Server.STATE_POST
    Server.state.stateStartedAtMs = nowMs
    Server.state.gatherNextAtMs = nowMs
    Server.state.postFailed = isFailed == true

    local durationSec = 0
    if Server.state.waveStartedAtMs and Server.state.waveStartedAtMs > 0 then
        durationSec = math.floor((nowMs - Server.state.waveStartedAtMs) / 1000)
    end

    local players = getOnlinePlayers()
    if not Server.state.postFailed then
        if players then
            for i = 0, players:size() - 1 do
                local player = players:get(i)
                if player and not player:isDead() then
                    local round = Server.getRoundStats(player)
                    round.streak = (round.streak or 0) + 1
                end
            end
        end

        if players and Economy then
            for i = 0, players:size() - 1 do
                local player = players:get(i)
                if player and not player:isInvisible() then
                    local alive = not player:isDead()
                    local soft = Config.getWaveSoftSeconds and Config.getWaveSoftSeconds(Server.state.killTarget) or (Config.WAVE_SOFT_SECONDS or 180)
                    local reward = Economy.getWaveClearReward(Server.state.currentTier or 1, durationSec, alive, Server.state.roundIndex, soft)
                    if reward > 0 then
                        Economy.addCurrency(player, reward)
                        local round = Server.getRoundStats(player)
                        round.gameCurrency = (round.gameCurrency or 0) + reward
                        local total = Server.getTotalStats(player)
                        total.totalCurrency = (total.totalCurrency or 0) + reward
                    end
                end
            end
        end
        if players then
            for i = 0, players:size() - 1 do
                local player = players:get(i)
                if player and not player:isDead() and not player:isInvisible() then
                    local choices = buildRewardChoices(player)
                    local md = player:getModData()
                    md.RogueRewardRoundId = tonumber(Server.state.roundIndex or 0) or 0
                    md.RogueRewardRunId = tonumber(Server.state.runId or 0) or 0
                    md.RogueRewardChoices = choices
                    sendServerCommand(player, "Rogue", "roundRewardChoices", {
                        roundId = md.RogueRewardRoundId,
                        runId = md.RogueRewardRunId,
                        choices = choices,
                    })
                end
            end
        end
    end
    if players then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player and not player:isInvisible() then
                local md = player:getModData()
                local wk = tonumber(md.RogueWaveKills or 0) or 0
                md.RogueMaxRoundKillsRun = math.max(tonumber(md.RogueMaxRoundKillsRun or 0) or 0, wk)
                md.RogueWaveKills = 0
            end
        end
    end

    if Server.state.postFailed then
        Server.broadcastAnnounce("FAILED! All players down.")
        log(string.format("State -> POST FAILED round=%d time=%ds", Server.state.roundIndex, durationSec))
    else
        Server.broadcastAnnounce(string.format(
            "CLEARED! Time: %ds, TierEnd: T%d, Target: %d",
            durationSec,
            Server.state.currentTier or 1,
            Server.state.killTarget or 0
        ))
        log(string.format("State -> POST round=%d time=%ds",
            Server.state.roundIndex,
            durationSec
        ))
    end
end

function Server.finishRun(nowMs, isVictory)
    local players = getOnlinePlayers()
    if players then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player and not player:isDead() then
                Server.recordRunStats(player, isVictory and "win" or "end")
            end
        end
    end
    Server.state.status = Server.STATE_LOBBY
    Server.state.stateStartedAtMs = nowMs
    Server.state.gatherNextAtMs = nowMs
    Server.state.waveStartedAtMs = 0
    Server.state.killsThisWave = 0
    Server.state.killTarget = 0
    Server.state.noLiveArenaSinceMs = 0
    Server.state.readyStartAtMs = 0
    Server.startLobby(nowMs)
    Server.cleanupPlacedObjects()
    if isVictory then
        Server.broadcastAnnounce("RUN COMPLETE!")
        log(string.format("State -> LOBBY (VICTORY) round=%d", Server.state.roundIndex))
    end
end

function Server.failWave(nowMs)
    local players = getOnlinePlayers()
    if players then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player and not player:isDead() then
                local md = player:getModData()
                local wk = tonumber(md.RogueWaveKills or 0) or 0
                md.RogueMaxRoundKillsRun = math.max(tonumber(md.RogueMaxRoundKillsRun or 0) or 0, wk)
                md.RogueWaveKills = 0
                Server.recordRunStats(player, "end")
            end
        end
    end
    Server.state.status = Server.STATE_LOBBY
    Server.state.stateStartedAtMs = nowMs
    Server.state.gatherNextAtMs = nowMs
    Server.state.waveStartedAtMs = 0
    Server.state.killsThisWave = 0
    Server.state.killTarget = 0
    Server.state.noLiveArenaSinceMs = 0

    local players = getOnlinePlayers()
    if players then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player then
                Server.resetPlayerForRun(player, "lobby-gather")
                if Economy and Economy.setWallet then
                    Economy.setWallet(player, Config.STARTING_CURRENCY or 0)
                end
                local key = Server.getPlayerKey(player)
                if Server.roundStats and key and Server.roundStats[key] then
                    Server.roundStats[key].gameCurrency = 0
                end
            end
        end
    end

    local target = Config.PRISON_SPAWN_POINT
        or Config.teleportInPoint
        or (Config.ZONES.SPAWN and Config.getRectCenter(Config.ZONES.SPAWN))
    if players and target then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player then
                Zones.teleportPlayer(player, target, nowMs, "fail-prison")
            end
        end
    end

    Server.cleanupArena("failed")
    Server.cleanupPlacedObjects()
    Server.broadcastAnnounce("FAILED! All players down.")
    log(string.format("State -> LOBBY (FAILED) round=%d", Server.state.roundIndex))
end

function Server.handleChatCommand(player, text)
    if type(text) ~= "string" then return end
    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then return end

    local lower = string.lower(trimmed)
    if lower:sub(1, 6) ~= "/rogue" then return end

    local rest = trimmed:sub(7)
    local tokens = Server.tokenize(rest)
    local cmd = string.lower(tokens[1] or "")

    if cmd == "" then
        Server.sendUsage(player)
        return
    end

    if cmd == "status" then
        Server.sendStatus(player)
        return
    end

    if cmd == "debug" then
        local flag = string.lower(tokens[2] or "")
        Server.setDebugFlag(player, flag)
        return
    end

    if cmd == "start" then
        Server.startFromParams(player, tokens[2], tokens[3])
        return
    end

    if cmd == "stop" then
        Server.stopFromCommand(player)
        return
    end

    if cmd == "refreshzones" then
        Server.refreshZonesFromTierZonyne(player)
        return
    end

    if cmd == "maplist" then
        Server.sendMapList(player)
        return
    end

    Server.sendUsage(player)
end

function Server.onClientCommand(module, command, player, args)
    if module ~= "Rogue" then return end
    log(string.format("OnClientCommand from %s command=%s",
        tostring(player and player:getUsername() or "server"),
        tostring(command)
    ))
    if command == "chatCommand" then
        Server.handleChatCommand(player, args and args.text)
    elseif command == "start" then
        Server.startFromParams(player, args and args.targetPlayers, args and args.maxRounds, args)
    elseif command == "stop" then
        Server.stopFromCommand(player)
    elseif command == "status" then
        Server.sendStatus(player)
    elseif command == "debug" then
        local flag = args and args.flag and string.lower(tostring(args.flag)) or ""
        Server.setDebugFlag(player, flag)
    elseif command == "refreshzones" then
        Server.refreshZonesFromTierZonyne(player)
    elseif command == "mapList" then
        Server.sendMapList(player)
    elseif command == "scoreRequest" then
        Server.sendScoreToPlayer(player)
    elseif command == "shopBuy" then
        local ok, msg = Rogue.Shop.buy(player, args and args.category, args and args.itemId, args and args.qty)
        if ok then
            Server.notify(player, msg)
            Server.sendScoreToPlayer(player)
            if Rogue.Shop and Rogue.Shop.getStockSnapshot then
                local category = args and args.category
                local stock = Rogue.Shop.getStockSnapshot(category)
                sendServerCommand(player, "Rogue", "shopStock", { category = category, stock = stock })
            end
            sendServerCommand(player, "Rogue", "shopBuyResult", { ok = true, category = args and args.category })
        else
            Server.notify(player, msg or "Shop error.")
            sendServerCommand(player, "Rogue", "shopBuyResult", { ok = false, category = args and args.category })
        end
    elseif command == "roundRewardPick" then
        if not player or player:isDead() then return end
        local md = player:getModData()
        local roundId = tonumber(args and args.roundId or -1) or -1
        local runId = tonumber(args and args.runId or -1) or -1
        if not md or not md.RogueRewardChoices then return end
        if md.RogueRewardRoundId ~= roundId or md.RogueRewardRunId ~= runId then
            sendServerCommand(player, "Rogue", "roundRewardApplied", { ok = false, error = "stale" })
            return
        end
        local index = tonumber(args and args.pickIndex or 0) or 0
        local choice = md.RogueRewardChoices[index]
        if not choice then
            sendServerCommand(player, "Rogue", "roundRewardApplied", { ok = false, error = "invalid" })
            return
        end
        local ok, applied = applyRewardChoice(player, choice, roundId)
        if ok then
            md.RogueRewardChoices = nil
            sendServerCommand(player, "Rogue", "roundRewardApplied", { ok = true, applied = applied })
        else
            sendServerCommand(player, "Rogue", "roundRewardApplied", { ok = false, error = applied })
        end
    elseif command == "setShop" then
        if not Server.isAdmin(player) then
            Server.notify(player, "Admin only.")
            return
        end
        local category = args and args.category
        local sprite = args and args.sprite
        local key = args and args.key
        local name = args and args.name
        if not category or not sprite or not key then
            Server.notify(player, "Missing shop data.")
            return
        end
        local data = ModData.getOrCreate("RoguelitynoShopObjects")
        data.entries = data.entries or {}
        data.nextId = tonumber(data.nextId) or 1
        local keyStr = tostring(key)
        local spriteStr = tostring(sprite)
        local catStr = tostring(category)
        local nameStr = name and tostring(name) or ""
        if nameStr == "" then
            nameStr = string.format("%s@%s", catStr, keyStr)
        end
        local updated = false
        for i = 1, #data.entries do
            local entry = data.entries[i]
            if entry and entry.key == keyStr then
                entry.category = catStr
                entry.sprite = spriteStr
                entry.name = nameStr
                updated = true
                break
            end
        end
        if not updated then
            local entry = {
                id = data.nextId,
                name = nameStr,
                category = catStr,
                sprite = spriteStr,
                key = keyStr,
            }
            data.nextId = data.nextId + 1
            table.insert(data.entries, entry)
        end
        ModData.add("RoguelitynoShopObjects", data)
        ModData.transmit("RoguelitynoShopObjects")
        Server.notify(player, "Shop set: " .. tostring(nameStr))
    elseif command == "removeShop" then
        if not Server.isAdmin(player) then
            Server.notify(player, "Admin only.")
            return
        end
        local shopId = args and args.id
        if shopId == nil then
            Server.notify(player, "Missing shop id.")
            return
        end
        local data = ModData.getOrCreate("RoguelitynoShopObjects")
        data.entries = data.entries or {}
        local idNum = tonumber(shopId)
        local removed = false
        for i = #data.entries, 1, -1 do
            local entry = data.entries[i]
            if entry and tonumber(entry.id) == idNum then
                table.remove(data.entries, i)
                removed = true
                break
            end
        end
        if removed then
            ModData.add("RoguelitynoShopObjects", data)
            ModData.transmit("RoguelitynoShopObjects")
            Server.notify(player, "Shop removed.")
        else
            Server.notify(player, "Shop id not found.")
        end
    elseif command == "buildBuy" then
        if Server.state.status ~= Server.STATE_LOBBY and Server.state.status ~= Server.STATE_PREP then
            Server.notify(player, "Build shop only in lobby or prep.")
            return
        end
        local inSpawn = Config.isRectValid(Config.ZONES.SPAWN) and Zones.isPlayerInRect(player, Config.ZONES.SPAWN)
        local inSafe = Config.isRectValid(Config.ZONES.SAFE) and Zones.isPlayerInRect(player, Config.ZONES.SAFE)
        if not inSpawn and not inSafe then
            Server.notify(player, "Build shop only in spawn or safe zone.")
            return
        end
        local buildId = args and args.buildId
        if not buildId or buildId == "" then
            Server.notify(player, "Missing buildId.")
            return
        end
        if not Rogue.Professions or not Rogue.Professions.isAllowed(buildId) then
            Server.notify(player, "Invalid build: " .. tostring(buildId))
            return
        end
        local md = player and player:getModData()
        if not md then return end
        if md.RogueBuildChosenLife then
            Server.notify(player, "Build already selected for this life.")
            return
        end
        local price = 0
        local shop = Config.BUILD_SHOP or {}
        for i = 1, #shop do
            if shop[i].id == buildId then
                price = tonumber(shop[i].price) or 0
                break
            end
        end
        if price > 0 then
            if not Economy.canAfford(player, price) then
                Server.notify(player, "Not enough currency.")
                return
            end
            Economy.spendCurrency(player, price)
        end
        md.RogueBuildId = buildId
        md.RogueBuildChosenLife = true
        Rogue.Professions.applyBuild(player, buildId)
        md.RogueBuildApplied = true
        md.RogueLoadoutApplied = true
        md.RogueTraitsApplied = true
        md.RogueSkillsApplied = true
        debugLog(string.format("Build selected %s id=%s",
            tostring(player and player:getUsername() or "unknown"),
            tostring(buildId)
        ))
        sendBuildIdToPlayer(player, buildId)
        Server.notify(player, "Build selected: " .. tostring(buildId))
        Server.sendScoreToPlayer(player)
        sendServerCommand(player, "Rogue", "buildBuyResult", { ok = true })
    elseif command == "shopStockRequest" then
        if Rogue.Shop and Rogue.Shop.getStockSnapshot then
            local category = args and args.category
            local stock = Rogue.Shop.getStockSnapshot(category)
            sendServerCommand(player, "Rogue", "shopStock", { category = category, stock = stock })
        end
    end
end

function Server.onCreatePlayer(playerIndex)
    local player = playerIndex
    if type(playerIndex) == "number" then
        player = getSpecificPlayer(playerIndex)
    end
    if not player then return end
    local md = player:getModData()
    if md then
        local desc = player.getDescriptor and player:getDescriptor() or nil
        local outfitName = desc and desc.getOutfitName and desc:getOutfitName() or nil
        if outfitName and outfitName ~= "" then
            md.RogueOutfitName = outfitName
        end
        if not md.RogueOutfitItems then
            tryCaptureOutfit(player)
        end
    end
    local status = Server.state and Server.state.status or Server.STATE_IDLE
    if status == Server.STATE_IDLE or status == Server.STATE_LOBBY then
        if Rogue.Professions and Rogue.Professions.resetBuildEffects then
            Rogue.Professions.resetBuildEffects(player)
            if md then
                md.RogueBuildApplied = nil
                md.RogueLoadoutApplied = nil
                md.RogueTraitsApplied = nil
                md.RogueSkillsApplied = nil
            end
        end
    end
    if Rogue.Professions then
        local md2 = player:getModData()
        local chosen = md2 and md2.RogueBuildId or nil
        if chosen and Rogue.Professions.isAllowed(chosen) and not md.RogueBuildApplied then
            Rogue.Professions.applyBuild(player, chosen)
            md2.RogueBuildApplied = true
            md2.RogueLoadoutApplied = true
            md2.RogueTraitsApplied = true
            md2.RogueSkillsApplied = true
        end
        sendBuildIdToPlayer(player, chosen)
    end
    if Server.state.status == Server.STATE_LOBBY then
        local target = Zones.getSpawnPoint()
        Zones.teleportPlayer(player, target, getTimestampMs(), "lobby-spawn")
    elseif Server.state.status == Server.STATE_WAVE then
        local md = player:getModData()
        md.RogueRespawnLock = true
        local target = Config.PRISON_SPAWN_POINT or Config.teleportInPoint
        Zones.teleportPlayer(player, target, getTimestampMs(), "respawn")
    end
end

function Server.onCreateLivingCharacter(player, desc)
    if not isServer() then return end
    if not player or not player.getModData then return end
    if player.isZombie and player:isZombie() then return end
    local md = player:getModData()
    if not md then return end
    if desc and desc.getOutfitName and (not md.RogueOutfitName or md.RogueOutfitName == "") then
        local ok, name = pcall(desc.getOutfitName, desc)
        if ok and name and name ~= "" then
            md.RogueOutfitName = name
        end
    end
    tryCaptureOutfit(player)
end

function Server.adjustArenaSprinters(maxUpdates)
    maxUpdates = math.max(1, tonumber(maxUpdates) or 1)
    if not Config.isRectValid(Config.ZONES.ARENA) then return end
    local rect = Config.ZONES.ARENA
    local x1 = math.min(rect.x1, rect.x2)
    local x2 = math.max(rect.x1, rect.x2)
    local y1 = math.min(rect.y1, rect.y2)
    local y2 = math.max(rect.y1, rect.y2)
    local zs = getCell():getZombieList()
    if not zs then return end

    local updated = 0
    for i = 0, zs:size() - 1 do
        if updated >= maxUpdates then break end
        local z = zs:get(i)
        if z and z:getZ() == (rect.z or 0) then
            local zx = z:getX()
            local zy = z:getY()
            if zx >= x1 and zx <= x2 and zy >= y1 and zy <= y2 then
                local ok = false
                if z.setSpeedType then
                    ok = pcall(z.setSpeedType, z, 1)
                elseif z.setSpeed then
                    ok = pcall(z.setSpeed, z, 1)
                end
                if ok then
                    updated = updated + 1
                end
            end
        end
    end
    debugLog("Adjusted sprinters in arena: " .. tostring(updated))
end

function Server.handleOutsideArena(now)
    if Server.state.status ~= Server.STATE_WAVE then return end
    if not Config.isRectValid(Config.ZONES.ARENA) then return end
    local players = getOnlinePlayers()
    if not players then return end

    local warnAfter = Config.OUTSIDE_WARN_SECONDS or 0
    local damageAfter = Config.OUTSIDE_DAMAGE_AFTER_SECONDS or 5
    local killAfter = Config.OUTSIDE_KILL_AFTER_SECONDS or 10
    local buffer = Config.OUTSIDE_ARENA_BUFFER or 0
    local maxBuffer = tonumber(Config.OUTSIDE_ARENA_MAX_BUFFER) or 0
    local rect = Config.ZONES.ARENA
    local x1 = math.min(rect.x1, rect.x2) - buffer
    local x2 = math.max(rect.x1, rect.x2) + buffer
    local y1 = math.min(rect.y1, rect.y2) - buffer
    local y2 = math.max(rect.y1, rect.y2) + buffer
    local outerX1 = x1
    local outerX2 = x2
    local outerY1 = y1
    local outerY2 = y2
    if maxBuffer > 0 then
        outerX1 = math.min(rect.x1, rect.x2) - (buffer + maxBuffer)
        outerX2 = math.max(rect.x1, rect.x2) + (buffer + maxBuffer)
        outerY1 = math.min(rect.y1, rect.y2) - (buffer + maxBuffer)
        outerY2 = math.max(rect.y1, rect.y2) + (buffer + maxBuffer)
    end
    local z = rect.z or 0
    local ignoreZone = Config.OUTSIDE_IGNORE_TIERZONE

    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player and not player:isDead() and not player:isInvisible() then
            local px = player:getX()
            local py = player:getY()
            local pz = player:getZ()
            local md = player:getModData()
            local ignored = false
            if ignoreZone and checkZoneAtXY then
                local _, zoneName = checkZoneAtXY(px, py)
                if zoneName == ignoreZone then
                    md.RogueOutsideSince = nil
                    md.RogueOutsideWarned = nil
                    md.RogueOutsideDamageStart = nil
                    md.RogueOutsideLastDamageAt = nil
                    ignored = true
                end
            end
            if not ignored then
                local inArena = (pz == z and px >= x1 and px <= x2 and py >= y1 and py <= y2)
                local inOuter = (pz == z and px >= outerX1 and px <= outerX2 and py >= outerY1 and py <= outerY2)
                if not inOuter then
                    md.RogueOutsideSince = nil
                    md.RogueOutsideWarned = nil
                    md.RogueOutsideDamageStart = nil
                    md.RogueOutsideLastDamageAt = nil
                elseif inArena then
                    md.RogueOutsideSince = nil
                    md.RogueOutsideWarned = nil
                    md.RogueOutsideDamageStart = nil
                    md.RogueOutsideLastDamageAt = nil
                else
                    if not md.RogueOutsideSince then
                        md.RogueOutsideSince = now
                    end
                    local elapsed = math.floor((now - md.RogueOutsideSince) / 1000)
                    if elapsed >= warnAfter and not md.RogueOutsideWarned then
                        md.RogueOutsideWarned = true
                        Server.announce(player, "Return to the arena!")
                    end
                    if elapsed >= damageAfter then
                        if not md.RogueOutsideDamageStart then
                            md.RogueOutsideDamageStart = now
                            Server.announce(player, "You are bleeding out outside the arena!")
                        end
                        if now - (md.RogueOutsideLastDamageAt or 0) >= 1000 then
                            md.RogueOutsideLastDamageAt = now
                            local body = player:getBodyDamage()
                            if body then
                                if elapsed >= killAfter then
                                    body:ReduceGeneralHealth(1000)
                                else
                                    local remaining = body:getHealth()
                                    local remainingSec = math.max(1, killAfter - elapsed)
                                    local dmg = remaining / remainingSec
                                    body:ReduceGeneralHealth(dmg)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function Server.onTick()
    local now = getTimestampMs()
    if now - (Server.state.lastTickMs or 0) < 1000 then return end
    Server.state.lastTickMs = now

    local players = getOnlinePlayers()
    if players then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            local md = player and player:getModData() or nil
            if md and md.RogueOutfitPending and now >= (md.RogueOutfitNextAt or 0) then
                md.RogueOutfitNextAt = now + 1000
                tryCaptureOutfit(player)
            end
            if md and md.RogueBogdanoUntilMs and now >= md.RogueBogdanoUntilMs then
                local stats = player and player.getStats and player:getStats() or nil
                if stats and stats.reset then
                    pcall(stats.reset, stats, CharacterStat.INTOXICATION)
                elseif stats and stats.set then
                    pcall(stats.set, stats, CharacterStat.INTOXICATION, 0)
                end
                md.RogueBogdanoUntilMs = nil
                md.RogueBogdanoTarget = nil
            end
            if md and md.RogueWornResyncAt and now >= md.RogueWornResyncAt then
                local ok = resyncWornItems(player)
                local tries = tonumber(md.RogueWornResyncTries) or 0
                tries = tries - 1
                if ok and tries <= 0 then
                    md.RogueWornResyncAt = nil
                    md.RogueWornResyncTries = nil
                else
                    md.RogueWornResyncTries = tries
                    md.RogueWornResyncAt = now + 1000
                end
            end
        end
    end

    if Server.state.status ~= Server.STATE_IDLE then
        Zones.enforceForState(Server.state, now)
        if Server.state.status == Server.STATE_WAVE then
            Server.handleOutsideArena(now)
        end
        if now >= (Server.state.deathCheckNextAtMs or 0) then
            Server.state.deathCheckNextAtMs = now + 1000
            Server.trackDeaths()
        end
        if Server.state.status == Server.STATE_LOBBY then
            if now >= (Server.state.gatherNextAtMs or 0) then
                Server.state.gatherNextAtMs = now + 1000
                Server.gatherPlayersOutsideSpawn(now, "lobby-gather")
            end
            if Server.allPlayersReadyInSpawn() then
                if (Server.state.readyStartAtMs or 0) == 0 then
                    Server.state.readyStartAtMs = now
                end
                local delayMs = tonumber(Config.READY_TO_PREP_DELAY_MS) or 0
                if delayMs <= 0 or now - Server.state.readyStartAtMs >= delayMs then
                    Server.startPrep(now, true)
                    Server.state.readyStartAtMs = 0
                end
            else
                Server.state.readyStartAtMs = 0
            end
        elseif Server.state.status == Server.STATE_PREP then
            local elapsed = math.floor((now - (Server.state.stateStartedAtMs or now)) / 1000)
            if now >= (Server.state.gatherNextAtMs or 0) then
                Server.state.gatherNextAtMs = now + 5000
                Server.gatherPlayersOutsideArena(now, "prep-gather")
            end
            if elapsed >= (Config.PREP_SECONDS or 45) then
                Server.startWave(now)
            end
            if now - (Server.state.lastCounterLogMs or 0) >= 5000 then
                Server.state.lastCounterLogMs = now
                log(string.format("PREP tick round=%d elapsed=%ds",
                    Server.state.roundIndex,
                    elapsed
                ))
            end
        elseif Server.state.status == Server.STATE_WAVE then
            local playersLive = Server.countLivePlayers()
            local playersLiveArena = Server.countLivePlayersInArena()
            if playersLiveArena <= 0 then
                if (Server.state.noLiveArenaSinceMs or 0) == 0 then
                    Server.state.noLiveArenaSinceMs = now
                end
                local graceMs = (tonumber(Config.ARENA_FAIL_GRACE_SECONDS) or 3) * 1000
                if now - (Server.state.noLiveArenaSinceMs or now) >= graceMs then
                    Server.failWave(now)
                    return
                end
            else
                Server.state.noLiveArenaSinceMs = 0
            end
            Spawns.tick(Server.state, now, playersLive)
            if now >= (Server.state.sprinterAdjustNextAtMs or 0) then
                local interval = (Config.SPRINTER_ADJUST_INTERVAL_SECONDS or 10) * 1000
                Server.state.sprinterAdjustNextAtMs = now + interval
                local divisor = Config.SPRINTER_ADJUST_DIVISOR or 3
                local maxUpdates = math.max(1, math.floor(playersLive / divisor))
                Server.adjustArenaSprinters(maxUpdates)
            end
            if now >= (Server.state.beaconNextAtMs or 0) then
                local interval = (Config.BEACON_INTERVAL_SECONDS or 10) * 1000
                Server.state.beaconNextAtMs = now + interval
                emitArenaBeacon()
            end
            local elapsed = math.floor((now - (Server.state.waveStartedAtMs or now)) / 1000)
            local soft = Config.getWaveSoftSeconds and Config.getWaveSoftSeconds(Server.state.killTarget) or (Config.WAVE_SOFT_SECONDS or 180)
            local step = Config.TIER_ESCALATE_EVERY_SECONDS or 30
            local warnBefore = tonumber(Config.ROUND_OVERTIME_SOON_SECONDS) or 0
            if warnBefore > 0 and soft > warnBefore and not Server.state.overtimeSoonSent then
                if elapsed >= (soft - warnBefore) then
                    Server.state.overtimeSoonSent = true
                    sendServerCommand("Rogue", "roundOvertimeSoon", {})
                end
            end
            if elapsed >= soft then
                if not Server.state.overtimeAnnounced then
                    Server.state.overtimeAnnounced = true
                    Server.broadcastAnnounce("OVERTIME! Tier escalation every 30s.")
                end
                local steps = math.floor((elapsed - soft) / step)
                local newTier = math.min(6, (Server.state.baseTier or 1) + steps)
                if newTier > (Server.state.currentTier or 1) then
                    Server.state.currentTier = newTier
                    local runnerMap = Config.TIER_RUNNER_PCT or {}
                    local runnerPct = tonumber(runnerMap[newTier]) or 0
                    local pct = math.floor((runnerPct * 100) + 0.5)
                    Server.broadcastAnnounce(string.format("Sprinter: %d%%", pct))
                end
            end
            Server.applyArenaTier(Server.state.currentTier)
            if (Server.state.killsThisWave or 0) >= (Server.state.killTarget or 0) and (Server.state.killTarget or 0) > 0 then
                Server.startPost(now)
            end
            if now - (Server.state.lastCounterLogMs or 0) >= 5000 then
                Server.state.lastCounterLogMs = now
                log(string.format("WAVE tick round=%d elapsed=%ds kills=%d/%d budget=%d tier=%d",
                    Server.state.roundIndex,
                    elapsed,
                    Server.state.killsThisWave or 0,
                    Server.state.killTarget or 0,
                    Server.state.spawnBudgetRemaining or 0,
                    Server.state.currentTier or 1
                ))
            end
        elseif Server.state.status == Server.STATE_POST then
            local elapsed = math.floor((now - (Server.state.stateStartedAtMs or now)) / 1000)
            if now >= (Server.state.gatherNextAtMs or 0) then
                Server.state.gatherNextAtMs = now + 5000
                Server.gatherPlayersOutsideArena(now, "post-gather")
            end
            if elapsed >= (Config.POST_SECONDS or 12) then
                if (Server.state.roundIndex or 0) >= (Server.state.maxRounds or 0) and not Server.state.postFailed then
                    Server.finishRun(now, true)
                    return
                end
                Server.state.roundIndex = Server.state.roundIndex + 1
                Server.startPrep(now, false)
            end
            if now - (Server.state.lastCounterLogMs or 0) >= 5000 then
                Server.state.lastCounterLogMs = now
                log(string.format("POST tick round=%d elapsed=%ds",
                    Server.state.roundIndex,
                    elapsed
                ))
            end
        end
        if now >= (Server.state.hudNextAtMs or 0) then
            Server.state.hudNextAtMs = now + 1000
            local elapsed = 0
            if Server.state.status == Server.STATE_WAVE then
                elapsed = math.floor((now - (Server.state.waveStartedAtMs or now)) / 1000)
            else
                elapsed = math.floor((now - (Server.state.stateStartedAtMs or now)) / 1000)
            end
            Server.sendHud(Server.state.status, elapsed)
        end
        if now >= (Server.state.scoreNextAtMs or 0) then
            Server.state.scoreNextAtMs = now + 2000
            Server.sendScoreboard()
        end
        local interval = (tonumber(Config.STATS_SNAPSHOT_MINUTES) or 0) * 60000
        if interval > 0 and now >= (Server.state.statsSnapshotNextAtMs or 0) then
            Server.snapshotRunStats()
            Server.state.statsSnapshotNextAtMs = now + interval
        end
        debugLog("tick status=" .. Server.state.status)
    end
end

function Server.onWeaponHitCharacter(attacker, target, weapon, damage)
    if Server.state.status == Server.STATE_IDLE then return end
    if not attacker or not target then return end
    if not instanceof(attacker, "IsoPlayer") then return end
    if not instanceof(target, "IsoZombie") then return end
    local amount = tonumber(damage)
    if not amount then return end
    local round = Server.getRoundStats(attacker)
    round.gameDamage = (round.gameDamage or 0) + amount
    if Server.state.status == Server.STATE_WAVE then
        round.waveDamage = (round.waveDamage or 0) + amount
    end
    local total = Server.getTotalStats(attacker)
    total.totalDamage = (total.totalDamage or 0) + amount
end

function Server.onPlayerDeath(player)
    if not player then return end
    log("PlayerDeath: " .. tostring(player:getUsername() or "unknown"))
    local md = player:getModData()
    if md then
        if md.RogueDeathRecorded then
            return
        end
        md.RogueDeathRecorded = true
        md.RogueBuildId = nil
        md.RogueBuildApplied = nil
        md.RogueLoadoutApplied = nil
        md.RogueTraitsApplied = nil
        md.RogueSkillsApplied = nil
        md.RogueBuildChosenLife = nil
    end
    local round = Server.getRoundStats(player)
    round.deaths = (round.deaths or 0) + 1
    round.streak = 0
    local total = Server.getTotalStats(player)
    total.totalDeaths = (total.totalDeaths or 0) + 1
    if Economy and Economy.applyDeathPenalty then
        Economy.applyDeathPenalty(player)
    end
    Server.recordRunStats(player, "death")
end


local function isFireKill(zombie)
    if not zombie then return false end
    if zombie.isOnFire then
        local ok, onFire = pcall(zombie.isOnFire, zombie)
        if ok and onFire then return true end
    end
    return false
end

function Server.onZombieDead(zombie)
    if Server.state.status ~= Server.STATE_WAVE then return end
    if not zombie then return end
    if Config.isRectValid(Config.ZONES.ARENA) then
        local rect = Config.ZONES.ARENA
        local buffer = math.max(Config.ARENA_KILL_BUFFER or 0, Config.SPAWN_ARENA_BUFFER or 0)
        local x1 = math.min(rect.x1, rect.x2) - buffer
        local x2 = math.max(rect.x1, rect.x2) + buffer
        local y1 = math.min(rect.y1, rect.y2) - buffer
        local y2 = math.max(rect.y1, rect.y2) + buffer
        local z = rect.z or 0
        local zx = zombie:getX()
        local zy = zombie:getY()
        local zz = zombie:getZ()
        if zz ~= z or zx < x1 or zx > x2 or zy < y1 or zy > y2 then
            return
        end
    end

    local killer = zombie:getAttackedBy()
    if isFireKill(zombie) and not (instanceof(killer, "IsoPlayer")) then
        Server.state.spawnBudgetRemaining = (Server.state.spawnBudgetRemaining or 0) + 1
        debugLog("Fire kill ignored; refunding spawn budget.")
        return
    end

    Server.state.killsThisWave = (Server.state.killsThisWave or 0) + 1

    if instanceof(killer, "IsoPlayer") then
        local round = Server.getRoundStats(killer)
        round.kills = (round.kills or 0) + 1
        round.waveKills = (round.waveKills or 0) + 1
        local md = killer:getModData()
        md.RogueWaveKills = (md.RogueWaveKills or 0) + 1

        local total = Server.getTotalStats(killer)
        total.totalKills = (total.totalKills or 0) + 1

        if Economy then
            local reward = Economy.getKillReward(Server.state.currentTier or 1)
            Economy.addCurrency(killer, reward)
            round.gameCurrency = (round.gameCurrency or 0) + reward
            total.totalCurrency = (total.totalCurrency or 0) + reward
        end
    end
end

Events.OnClientCommand.Add(Server.onClientCommand)
Events.OnCreatePlayer.Add(Server.onCreatePlayer)
Events.OnCreateLivingCharacter.Add(Server.onCreateLivingCharacter)
Events.OnTick.Add(Server.onTick)
Events.OnZombieDead.Add(Server.onZombieDead)
Events.OnWeaponHitCharacter.Add(Server.onWeaponHitCharacter)
Events.OnPlayerDeath.Add(Server.onPlayerDeath)
Events.OnObjectAdded.Add(function(obj) trackPlacedObject(obj) end)
if Events.OnPlayerDisconnect then
    Events.OnPlayerDisconnect.Add(Server.onPlayerDisconnect)
end
