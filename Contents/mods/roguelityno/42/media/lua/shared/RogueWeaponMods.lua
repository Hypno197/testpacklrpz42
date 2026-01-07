Rogue = Rogue or {}
Rogue.WeaponMods = Rogue.WeaponMods or {}

local WeaponMods = Rogue.WeaponMods

if not Rogue.Config then
    require "RogueConfig"
end

local Config = Rogue.Config

Config.WEAPON_MOD_ACTION_TIME = Config.WEAPON_MOD_ACTION_TIME or 120
Config.WEAPON_SCRAP_ACTION_TIME = Config.WEAPON_SCRAP_ACTION_TIME or 90
Config.WEAPON_MOD_SKILL_MAX = Config.WEAPON_MOD_SKILL_MAX or 10

Config.WEAPON_MOD_WORKBENCH_SPRITES = Config.WEAPON_MOD_WORKBENCH_SPRITES or {
    "location_military_generic_01_1",
}
Config.WEAPON_MOD_WORKBENCH_NAMES = Config.WEAPON_MOD_WORKBENCH_NAMES or {
}
Config.WEAPON_MOD_DEBUG = true

local function debugLog(msg)
    if Config.WEAPON_MOD_DEBUG then
        print("[Roguelityno][WeaponMods] " .. tostring(msg))
    end
end

Config.WEAPON_MOD_KITS = Config.WEAPON_MOD_KITS or {
    improvised = {
        id = "Rogue.ModKit_Improvised",
        labelKey = "UI_rogue_modkit_improv",
        skills = { "Axe", "Blunt", "SmallBlunt", "SmallBlade", "LongBlade", "Spear" }, --inserisci aiming per fare anche su pistole
        bias = { bad = -5, blessing = 5, curse = 0 },
    },
    rare = {
        id = "Rogue.ModKit_Special",
        labelKey = "UI_rogue_modkit_special",
        skills = { "Axe", "Blunt", "SmallBlunt", "SmallBlade", "LongBlade", "Spear" },
        bias = { bad = -10, blessing = 10, curse = 5 },
    },
}

Config.WEAPON_MOD_DEFS = Config.WEAPON_MOD_DEFS or {
    balanced = {
        kind = "blessing",
        labelPrefix = "(Bilanciata)",
        descKey = "UI_rogue_mod_balanced",
        dmgMult = 1,
        speedMult = 1.15,
        staminaMult = 0.9,
        durabMult = 0.9,
    },
    carbon = {
        kind = "blessing",
        labelPrefix = "(Carbonio)",
        descKey = "UI_rogue_mod_carbon",
        dmgMult = 1.08,
        speedMult = 1.02,
        staminaMult = 0.95,
        durabMult = 1.05,
    },
    brutal = {
        kind = "curse",
        labelPrefix = "(Brutale)",
        descKey = "UI_rogue_mod_brutal",
        dmgMult = 1.18,
        speedMult = 0.92,
        staminaMult = 1.20,
        durabMult = 0.90,
    },
    vicious = {
        kind = "curse",
        labelPrefix = "(Tagliente)",
        descKey = "UI_rogue_mod_vicious",
        dmgMult = 1.16,
        speedMult = 0.98,
        staminaMult = 1.15,
        durabMult = 0.85,
    },
    neglected = {
        kind = "bad",
        labelPrefix = "(Trascurata)",
        descKey = "UI_rogue_mod_neglected",
        dmgMult = 0.95,
        speedMult = 0.95,
        staminaMult = 1.08,
        durabMult = 0.80,
    },
    warped = {
        kind = "bad",
        labelPrefix = "(Storta)",
        descKey = "UI_rogue_mod_warped",
        dmgMult = 0.92,
        speedMult = 0.90,
        staminaMult = 1.12,
        durabMult = 0.85,
    },
}

Config.WEAPON_MOD_POOL = Config.WEAPON_MOD_POOL or {
    blessing = { "balanced", "carbon" },
    curse = { "brutal", "vicious" },
    bad = { "neglected", "warped" },
}

Config.WEAPON_MOD_WEIGHTS = Config.WEAPON_MOD_WEIGHTS or {
    low = { bad = 60, blessing = 35, curse = 5 },
    high = { bad = 15, blessing = 55, curse = 30 },
}

Config.WEAPON_MOD_MR_RUMBLE_BONUS = Config.WEAPON_MOD_MR_RUMBLE_BONUS or {
    bad = -10,
    blessing = 8,
    curse = 4,
}

Config.WEAPON_MOD_REWARD_CHANCE = Config.WEAPON_MOD_REWARD_CHANCE or {
    common = 0.05,
    uncommon = 0.15,
    rare = 0.25,
    epic = 0.40,
    legendary = 0.5,
    -- common = 1,
    -- uncommon = 1,
    -- rare = 1,
    -- epic = 1,
    -- legendary = 1,
}

Config.WEAPON_SCRAP_TABLE = Config.WEAPON_SCRAP_TABLE or {
    { id = "Base.ZipTie", min = 1, max = 2, weight = 25 },
    { id = "Base.Scotch", min = 1, max = 1, weight = 20 },
    { id = "Base.ScrapMetal", min = 1, max = 1, weight = 15 },
    { id = "Base.MetalPipe_Broken", min = 1, max = 2, weight = 15 },
    { id = "Base.DuctTape", min = 1, max = 1, weight = 10 },
    { id = "Base.FiberglassTape", min = 1, max = 1, weight =  10},
    { id = "Base.Epoxy", min = 1, max = 1, weight = 5 },
}

Config.WEAPON_SCRAP_KIT_IMPROVISED_CHANCE = Config.WEAPON_SCRAP_KIT_IMPROVISED_CHANCE or 0.08
Config.WEAPON_SCRAP_KIT_RARE_CHANCE = Config.WEAPON_SCRAP_KIT_RARE_CHANCE or 0.01
Config.WEAPON_SCRAP_MIN_CONDITION_PCT = Config.WEAPON_SCRAP_MIN_CONDITION_PCT or 0.20
Config.BUILD_ID_MR_RUMBLE = Config.BUILD_ID_MR_RUMBLE or "roguelityno:mr_rumble"

local function clamp01(v)
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function pickWeighted(map)
    local total = 0
    for _, v in pairs(map) do
        total = total + (tonumber(v) or 0)
    end
    if total <= 0 then return nil end
    local roll = ZombRand(total) + 1
    local acc = 0
    for k, v in pairs(map) do
        acc = acc + (tonumber(v) or 0)
        if roll <= acc then
            return k
        end
    end
    return nil
end

function WeaponMods.getWeaponSkillId(weapon, player)
    if not weapon then return nil end
    local perk
    if weapon.getPerk then
        local ok, res = pcall(weapon.getPerk, weapon)
        if ok then perk = res end
    end
    if not perk and weapon.getWeaponSkill then
        local ok, res = pcall(weapon.getWeaponSkill, weapon, player)
        if ok then perk = res end
    end
    debugLog("getWeaponSkillId weapon=" .. tostring(weapon.getFullType and weapon:getFullType() or weapon)
        .. " perkType=" .. tostring(type(perk)) .. " perkVal=" .. tostring(perk))
    if not perk then return nil end
    if type(perk) == "string" then
        return perk
    end
    if type(perk) == "number" and PerkFactory and PerkFactory.PerkList and PerkFactory.PerkList.get then
        local okPerk, perkObj = pcall(PerkFactory.PerkList.get, PerkFactory.PerkList, perk)
        if not okPerk or not perkObj then
            local okPerkAlt, perkObjAlt = pcall(PerkFactory.PerkList.get, PerkFactory.PerkList, perk - 1)
            if okPerkAlt and perkObjAlt then
                perkObj = perkObjAlt
            end
        end
        if perkObj then
            perk = perkObj
        end
    end
    if perk.getId then
        local okId, id = pcall(perk.getId, perk)
        if okId and id then
            debugLog("getWeaponSkillId perkId=" .. tostring(id))
            return tostring(id)
        end
    end
    if type(perk) == "number" and Perks and Perks[perk] and Perks[perk].getId then
        local okId, id = pcall(Perks[perk].getId, Perks[perk])
        if okId and id then
            debugLog("getWeaponSkillId perkIdFromIndex=" .. tostring(id))
            return tostring(id)
        end
    end
    return nil
end

function WeaponMods.isEligibleWeapon(weapon)
    if not weapon or not instanceof(weapon, "HandWeapon") then return false end
    if weapon.getCondition and weapon.getConditionMax then
        if weapon:getCondition() <= 0 then return false end
    end
    return true
end

function WeaponMods.isFirearm(weapon)
    if not weapon or not instanceof(weapon, "HandWeapon") then return false end
    if weapon.isAimedFirearm then
        local ok, res = pcall(weapon.isAimedFirearm, weapon)
        if ok and res then return true end
    end
    if weapon.isRanged then
        local ok, res = pcall(weapon.isRanged, weapon)
        if ok and res then return true end
    end
    if weapon.getAmmoType then
        local ok, ammo = pcall(weapon.getAmmoType, weapon)
        if ok and ammo and tostring(ammo) ~= "" then return true end
    end
    return false
end

function WeaponMods.hasMod(weapon)
    if not weapon or not weapon.getModData then return false end
    local md = weapon:getModData()
    return md and md.RogueWeaponMod ~= nil
end

function WeaponMods.getKitDefByItem(item)
    if not item or not item.getFullType then return nil end
    local id = item:getFullType()
    for _, def in pairs(Config.WEAPON_MOD_KITS or {}) do
        if def and def.id == id then
            return def
        end
    end
    return nil
end

function WeaponMods.isKitCompatible(kitDef, weapon, player)
    if not kitDef or not weapon then return false end
    local skillId = WeaponMods.getWeaponSkillId(weapon, player)
    debugLog("isKitCompatible kit=" .. tostring(kitDef.id) .. " skillId=" .. tostring(skillId))
    if not skillId then return false end
    local list = kitDef.skills or {}
    for i = 1, #list do
        if list[i] == skillId then
            return true
        end
    end
    debugLog("isKitCompatible no match skillList=" .. tostring(table.concat(list, ",")))
    return false
end

function WeaponMods.rollOutcome(skillLevel, isMrRumble, kitDef)
    local weights = Config.WEAPON_MOD_WEIGHTS or {}
    local low = weights.low or {}
    local high = weights.high or {}
    local maxSkill = tonumber(Config.WEAPON_MOD_SKILL_MAX or 10) or 10
    local t = clamp01((tonumber(skillLevel) or 0) / maxSkill)
    local w = {
        bad = lerp(tonumber(low.bad or 0), tonumber(high.bad or 0), t),
        blessing = lerp(tonumber(low.blessing or 0), tonumber(high.blessing or 0), t),
        curse = lerp(tonumber(low.curse or 0), tonumber(high.curse or 0), t),
    }
    local kitBias = kitDef and kitDef.bias or nil
    if kitBias then
        for k, v in pairs(kitBias) do
            w[k] = (w[k] or 0) + (tonumber(v) or 0)
        end
    end
    if isMrRumble then
        local bonus = Config.WEAPON_MOD_MR_RUMBLE_BONUS or {}
        for k, v in pairs(bonus) do
            w[k] = (w[k] or 0) + (tonumber(v) or 0)
        end
    end
    if w.bad < 0 then w.bad = 0 end
    if w.blessing < 0 then w.blessing = 0 end
    if w.curse < 0 then w.curse = 0 end
    return pickWeighted(w) or "bad"
end

function WeaponMods.pickModId(kind)
    local pool = Config.WEAPON_MOD_POOL and Config.WEAPON_MOD_POOL[kind] or nil
    if not pool or #pool == 0 then return nil end
    local idx = ZombRand(#pool) + 1
    return pool[idx]
end

function WeaponMods.buildDisplayName(baseName, labelPrefix)
    local base = tostring(baseName or "")
    local prefix = tostring(labelPrefix or "")
    if prefix == "" then return base end
    if base == "" then return prefix end
    if base:find(prefix, 1, true) then
        return base
    end
    return prefix .. " " .. base
end

function WeaponMods.applyStatsOnce(weapon, context)
    if not weapon or not weapon.getModData then return false end
    local md = weapon:getModData()
    local mod = md and md.RogueWeaponMod or nil
    if not mod then return false end
    local token = tostring(context and context.token or "")
    if mod._appliedToken == token then
        return false
    end
    mod._appliedToken = token

    local dmgMult = tonumber(mod.dmgMult or 1) or 1
    local speedMult = tonumber(mod.speedMult or 1) or 1
    local staminaMult = tonumber(mod.staminaMult or 1) or 1
    local durabMult = tonumber(mod.durabMult or 1) or 1

    if weapon.getMinDamage and weapon.setMinDamage then
        weapon:setMinDamage(weapon:getMinDamage() * dmgMult)
    end
    if weapon.getMaxDamage and weapon.setMaxDamage then
        weapon:setMaxDamage(weapon:getMaxDamage() * dmgMult)
    end
    if weapon.getSwingTime and weapon.setSwingTime and speedMult > 0 then
        weapon:setSwingTime(weapon:getSwingTime() / speedMult)
    end
    if weapon.getEnduranceMod and weapon.setEnduranceMod then
        weapon:setEnduranceMod(weapon:getEnduranceMod() * staminaMult)
    end
    if weapon.getConditionLowerChance and weapon.setConditionLowerChance and durabMult > 0 then
        local baseChance = weapon:getConditionLowerChance()
        if baseChance and baseChance > 0 then
            local newChance = math.max(1, math.floor(baseChance / durabMult + 0.5))
            weapon:setConditionLowerChance(newChance)
        end
    end
    return true
end

function WeaponMods.applyAfterTier(weapon, tierToken)
    return WeaponMods.applyStatsOnce(weapon, { token = tostring(tierToken or "") })
end

function WeaponMods.isScrapEligible(weapon)
    if not weapon or not weapon.getCondition or not weapon.getConditionMax then return false end
    local max = weapon:getConditionMax()
    if not max or max <= 0 then return true end
    local pct = weapon:getCondition() / max
    return pct <= (Config.WEAPON_SCRAP_MIN_CONDITION_PCT or 0.2)
end

function WeaponMods.rollScrapLoot(isMrRumble)
    local drops = {}
    local tableDef = Config.WEAPON_SCRAP_TABLE or {}
    if #tableDef == 0 then return drops end
    local pick = pickWeighted((function()
        local map = {}
        for i = 1, #tableDef do
            local row = tableDef[i]
            map[i] = row.weight or 1
        end
        return map
    end)())
    local row = pick and tableDef[pick] or nil
    if row and row.id then
        local min = tonumber(row.min or 1) or 1
        local max = tonumber(row.max or min) or min
        local qty = min
        if max > min then
            qty = ZombRand(max - min + 1) + min
        end
        table.insert(drops, { id = row.id, qty = qty })
    end

    local improvChance = tonumber(Config.WEAPON_SCRAP_KIT_IMPROVISED_CHANCE or 0) or 0
    local rareChance = tonumber(Config.WEAPON_SCRAP_KIT_RARE_CHANCE or 0) or 0
    if isMrRumble then
        improvChance = improvChance + 0.05
        rareChance = rareChance + 0.01
    end
    if rareChance > 0 and ZombRandFloat(0, 1) < rareChance then
        local kit = Config.WEAPON_MOD_KITS and Config.WEAPON_MOD_KITS.rare
        if kit and kit.id then
            table.insert(drops, { id = kit.id, qty = 1 })
        end
    elseif improvChance > 0 and ZombRandFloat(0, 1) < improvChance then
        local kit = Config.WEAPON_MOD_KITS and Config.WEAPON_MOD_KITS.improvised
        if kit and kit.id then
            table.insert(drops, { id = kit.id, qty = 1 })
        end
    end
    return drops
end

function WeaponMods.applyModDefinition(player, weapon, def, sourceId)
    if not weapon or not def then return false, "missing_def" end
    if WeaponMods.hasMod(weapon) then return false, "slot_full" end
    local wmd = weapon:getModData()
    local baseName = weapon.getName and weapon:getName() or nil
    wmd.RogueWeaponMod = {
        kind = def.kind,
        id = def.id or nil,
        labelPrefix = def.labelPrefix,
        descKey = def.descKey,
        appliedBy = sourceId,
        seed = ZombRand(1000000),
        dmgMult = def.dmgMult,
        speedMult = def.speedMult,
        staminaMult = def.staminaMult,
        durabMult = def.durabMult,
        baseName = baseName,
    }

    local newName = WeaponMods.buildDisplayName(baseName, def.labelPrefix)
    if weapon.setName then
        weapon:setName(newName)
    end

    local runId = Rogue.Server and Rogue.Server.state and Rogue.Server.state.runId or 0
    local tier = Rogue.Server and Rogue.Server.state and Rogue.Server.state.currentTier or 0
    WeaponMods.applyStatsOnce(weapon, { token = tostring(runId) .. ":" .. tostring(tier) })
    return true, def
end

function WeaponMods.rollRewardMod(player, weapon, rarity)
    if WeaponMods.isFirearm(weapon) then
        debugLog("rollRewardMod skip firearm=" .. tostring(weapon and weapon.getFullType and weapon:getFullType() or "nil"))
        return nil
    end
    local chance = Config.WEAPON_MOD_REWARD_CHANCE or {}
    local roll = tonumber(chance[rarity] or 0) or 0
    if roll <= 0 then return nil end
    if ZombRandFloat(0, 1) >= roll then return nil end
    local skillId = WeaponMods.getWeaponSkillId(weapon, player)
    debugLog("rollRewardMod rarity=" .. tostring(rarity) .. " roll=" .. tostring(roll) .. " skillId=" .. tostring(skillId))
    local skillLevel = 0
    if player and skillId and player.getPerkLevel and Perks and Perks[skillId] then
        skillLevel = player:getPerkLevel(Perks[skillId])
    end
    local outcome = WeaponMods.rollOutcome(skillLevel, false, nil)
    local modId = WeaponMods.pickModId(outcome)
    local def = modId and Config.WEAPON_MOD_DEFS and Config.WEAPON_MOD_DEFS[modId] or nil
    if def and not def.id then
        def = { id = modId, kind = def.kind, labelPrefix = def.labelPrefix, descKey = def.descKey,
                dmgMult = def.dmgMult, speedMult = def.speedMult, staminaMult = def.staminaMult, durabMult = def.durabMult }
    end
    return def
end

function WeaponMods.applyModDirect(player, weapon, def, sourceId)
    if not def then return false, "missing_def" end
    return WeaponMods.applyModDefinition(player, weapon, def, sourceId or "reward")
end

function WeaponMods.applyModServer(player, weapon, kitItem)
    if not isServer() then return false, "client_only" end
    if not player or not weapon or not kitItem then return false, "missing" end
    local inv = player.getInventory and player:getInventory() or nil
    if not inv or not inv:contains(weapon) or not inv:contains(kitItem) then
        return false, "missing"
    end
    if not WeaponMods.isEligibleWeapon(weapon) then return false, "bad_weapon" end
    if WeaponMods.hasMod(weapon) then return false, "slot_full" end

    local kitDef = WeaponMods.getKitDefByItem(kitItem)
    if not kitDef then return false, "bad_kit" end
    if not WeaponMods.isKitCompatible(kitDef, weapon, player) then return false, "kit_incompatible" end

    local skillId = WeaponMods.getWeaponSkillId(weapon, player)
    local skillLevel = 0
    if skillId and player.getPerkLevel and Perks and Perks[skillId] then
        skillLevel = player:getPerkLevel(Perks[skillId])
    end
    local mdPlayer = player:getModData()
    local isMrRumble = mdPlayer and mdPlayer.RogueBuildId == Config.BUILD_ID_MR_RUMBLE
    local outcome = WeaponMods.rollOutcome(skillLevel, isMrRumble, kitDef)
    local modId = WeaponMods.pickModId(outcome)
    local def = modId and Config.WEAPON_MOD_DEFS and Config.WEAPON_MOD_DEFS[modId] or nil
    if def and not def.id then
        def = { id = modId, kind = def.kind, labelPrefix = def.labelPrefix, descKey = def.descKey,
                dmgMult = def.dmgMult, speedMult = def.speedMult, staminaMult = def.staminaMult, durabMult = def.durabMult }
    end
    if not def then return false, "missing_def" end
    local okDef, res = WeaponMods.applyModDefinition(player, weapon, def, kitDef.id)
    if not okDef then return false, res end
    if weapon.syncItemFields then
        weapon:syncItemFields()
    end
    local weaponContainer = weapon.getContainer and weapon:getContainer() or inv
    if weaponContainer then
        if sendRemoveItemFromContainer then
            sendRemoveItemFromContainer(weaponContainer, weapon)
        end
        weaponContainer:Remove(weapon)
        if weaponContainer.AddItem then
            weaponContainer:AddItem(weapon)
        elseif weaponContainer.addItem then
            weaponContainer:addItem(weapon)
        end
        if sendAddItemToContainer then
            sendAddItemToContainer(weaponContainer, weapon)
        end
    end

    local container = kitItem.getContainer and kitItem:getContainer() or nil
    if container then
        if sendRemoveItemFromContainer then
            sendRemoveItemFromContainer(container, kitItem)
        end
        container:Remove(kitItem)
    end

    return true, def
end
