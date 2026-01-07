if not Rogue then Rogue = {} end
if not Rogue.WeaponMods then require "RogueWeaponMods" end
require "TimedActions/ISBaseTimedAction"

Rogue.WeaponScrapAction = Rogue.WeaponScrapAction or {}

local Action = ISBaseTimedAction:derive("RogueWeaponScrapAction")
Rogue.WeaponScrapAction = Action
RogueWeaponScrapAction = Action
local WeaponMods = Rogue.WeaponMods
local Config = Rogue.Config or {}

function Action:new(character, weapon)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.weapon = weapon
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = true
    o.useProgressBar = true
    o.maxTime = o:getDuration()
    return o
end

function Action:getDuration()
    return Config.WEAPON_SCRAP_ACTION_TIME or 90
end

function Action:isValid()
    if not self.character or not self.weapon then return false end
    if not self.character:getInventory():contains(self.weapon) then return false end
    return WeaponMods.isScrapEligible(self.weapon)
end

function Action:perform()
    ISBaseTimedAction.perform(self)
end

function Action:start()
    if not isServer() then
        if self.setActionAnim then
            self:setActionAnim("Hammering")
        end
        if self.character and self.character.playSound then
            self.character:playSound("Hammering")
        elseif self.character and self.character.getEmitter then
            self.character:getEmitter():playSound("Hammering")
        end
    end
end

function Action:complete()
    if not isServer() then return true end
    local player = self.character
    local weapon = self.weapon
    local md = player and player.getModData and player:getModData() or nil
    local isMrRumble = md and md.RogueBuildId == (Config.BUILD_ID_MR_RUMBLE or "roguelityno:mr_rumble")
    if not isMrRumble then
        if sendServerCommand then
            sendServerCommand(player, "Rogue", "weaponScrapResult", { ok = false, reason = "not_mr_rumble" })
        end
        return true
    end
    if not WeaponMods.isScrapEligible(weapon) then
        if sendServerCommand then
            sendServerCommand(player, "Rogue", "weaponScrapResult", { ok = false, reason = "not_eligible" })
        end
        return true
    end

    local inv = player:getInventory()
    local container = weapon.getContainer and weapon:getContainer() or inv
    if container then
        if sendRemoveItemFromContainer then
            sendRemoveItemFromContainer(container, weapon)
        end
        container:Remove(weapon)
    end

    local drops = WeaponMods.rollScrapLoot(isMrRumble)
    for i = 1, #drops do
        local entry = drops[i]
        local qty = tonumber(entry and entry.qty or 1) or 1
        for n = 1, qty do
            local item = entry and entry.id and inv:AddItem(entry.id) or nil
            if item and item.setCondition and item.getConditionMax then
                item:setCondition(item:getConditionMax())
            end
            if item and sendAddItemToContainer then
                sendAddItemToContainer(inv, item)
            end
        end
    end
    if sendServerCommand then
        sendServerCommand(player, "Rogue", "weaponScrapResult", { ok = true })
    end
    return true
end
