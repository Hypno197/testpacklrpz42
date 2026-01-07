require "TimedActions/ISBaseTimedAction"

Rogue = Rogue or {}
Rogue.FullRestore = Rogue.FullRestore or {}

local function safeCall(obj, fn, ...)
    if not obj then return end
    local f = obj[fn]
    if not f then return end
    pcall(f, obj, ...)
end

local function cureZombieInfection(player)
    if not isServer() or not player then return end
    local bd = player.getBodyDamage and player:getBodyDamage() or nil
    if not bd then return end
    local parts = bd.getBodyParts and bd:getBodyParts() or nil
    if parts and parts.size then
        for i = 0, parts:size() - 1 do
            local bp = parts:get(i)
            if bp then
                safeCall(bp, "SetBitten", false, false)
                safeCall(bp, "SetInfected", false)
                safeCall(bp, "SetFakeInfected", false)
                safeCall(bp, "setInfectedWound", false)
                safeCall(bp, "setWoundInfectionLevel", 0)
            end
        end
    end
    safeCall(bd, "setInfected", false)
    safeCall(bd, "setIsFakeInfected", false)
    safeCall(bd, "setReduceFakeInfection", false)
    safeCall(bd, "setInfectionTime", -1)
    safeCall(bd, "setInfectionMortalityDuration", -1)
    local stats = player.getStats and player:getStats() or nil
    if stats and CharacterStat then
        safeCall(stats, "reset", CharacterStat.ZOMBIE_INFECTION)
        safeCall(stats, "reset", CharacterStat.ZOMBIE_FEVER)
    end
    if sendSyncPlayerFields then
        pcall(sendSyncPlayerFields, player, 0x08)
    end
end

function Rogue.FullRestore.apply(player)
    if not player then return end
    local bd = player.getBodyDamage and player:getBodyDamage() or nil
    if bd then
        local ok, before = pcall(bd.getHealth, bd)
        if not ok then before = nil end
        safeCall(bd, "RestoreToFullHealth")
        local ok2, after = pcall(bd.getHealth, bd)
        if not ok2 then after = nil end
        safeCall(bd, "setFoodSicknessLevel", 0)
        safeCall(bd, "setHealthFromFoodTimer", 0)
        safeCall(bd, "setTemperature", 37)
    end

    cureZombieInfection(player)

    local stats = player.getStats and player:getStats() or nil
    if stats then
        safeCall(stats, "setStress", 0)
        safeCall(stats, "setPanic", 0)
        safeCall(stats, "setFear", 0)
        safeCall(stats, "setFatigue", 0)
        safeCall(stats, "setEndurance", 1)
        safeCall(stats, "setPain", 0)
    end

    local nutrition = player.getNutrition and player:getNutrition() or nil
    if nutrition then
        safeCall(nutrition, "setHunger", 0)
        safeCall(nutrition, "setThirst", 0)
    end
end

RogueFullRestoreAction = ISBaseTimedAction:derive("RogueFullRestoreAction")

function RogueFullRestoreAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.stopOnWalk = false
    o.stopOnRun = false
    o.maxTime = o:getDuration()
    o.useProgressBar = true
    return o
end

function RogueFullRestoreAction:isValid()
    if not self.character or not self.item then return false end
    local container = self.item.getContainer and self.item:getContainer() or nil
    return container ~= nil
end

function RogueFullRestoreAction:getDuration()
    return 2.5 * 50
end

function RogueFullRestoreAction:start()
    if isServer() then return end
    if self.setOverrideHandModels then
        self:setOverrideHandModels(self.item, nil)
    end
    if self.character and self.character.playEmote then
        pcall(self.character.playEmote, self.character, "insult")
    end
    print("[Roguelityno][Serum] start sound=FullRestoreSerumSound")
    if Rogue and Rogue.Client and Rogue.Client.playUISound then
        Rogue.Client.playUISound("serum_use")
    else
        local sm = getSoundManager()
        if sm and sm.playUISound then
            sm:playUISound("FullRestoreSerumSound")
        end
    end
end

function RogueFullRestoreAction:perform()
    ISBaseTimedAction.perform(self)
end

function RogueFullRestoreAction:complete()
    if not isServer() then return true end
    local item = self.item
    local inv = item and item.getContainer and item:getContainer() or nil
    if inv then
        inv:Remove(item)
        if sendRemoveItemFromContainer then
            sendRemoveItemFromContainer(inv, item)
        end
    end
    Rogue.FullRestore.apply(self.character)
    return true
end
