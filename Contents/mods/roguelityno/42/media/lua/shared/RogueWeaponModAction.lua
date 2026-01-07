if not Rogue then Rogue = {} end
if not Rogue.WeaponMods then require "RogueWeaponMods" end
require "TimedActions/ISBaseTimedAction"

Rogue.WeaponModAction = Rogue.WeaponModAction or {}

local Action = ISBaseTimedAction:derive("RogueWeaponModAction")
Rogue.WeaponModAction = Action
RogueWeaponModAction = Action
local WeaponMods = Rogue.WeaponMods
local Config = Rogue.Config or {}

Action.Type = "RogueWeaponModAction"

function Action:new(character, weapon, kitItem)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.weapon = weapon
    o.kitItem = kitItem
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = true
    o.useProgressBar = true
    o.maxTime = o:getDuration()
    return o
end

function Action:getDuration()
    return Config.WEAPON_MOD_ACTION_TIME or 120
end

function Action:isValid()
    if not self.character or not self.weapon or not self.kitItem then return false end
    if not self.character:getInventory():contains(self.weapon) then return false end
    if not self.character:getInventory():contains(self.kitItem) then return false end
    return WeaponMods.isEligibleWeapon(self.weapon)
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
    local ok, defOrErr = WeaponMods.applyModServer(self.character, self.weapon, self.kitItem)
    if sendServerCommand then
        sendServerCommand(self.character, "Rogue", "weaponModResult", {
            ok = ok,
            reason = ok and nil or defOrErr,
            modId = ok and defOrErr.id or nil,
        })
    end
    return true
end
