require "TimedActions/ISBaseTimedAction"

Resus = Resus or {}
Resus.TimedAction = Resus.TimedAction or {}

ResusReviveAction = ISBaseTimedAction:derive("ResusReviveAction")

function ResusReviveAction:isValid()
  if not self.character or not self.target then return false end
  if self.target:isDead() then return false end
  if not self.target:isOnFloor() then return false end
  return true
end

function ResusReviveAction:start()
  self:setActionAnim("Loot")
end

function ResusReviveAction:stop()
  ISBaseTimedAction.stop(self)
end

function ResusReviveAction:perform()
  ISBaseTimedAction.perform(self)
end

function ResusReviveAction:complete()
  if isServer() and Resus and Resus.Server and Resus.Server.revivePlayer then
    Resus.Server.revivePlayer(self.character, self.target)
  elseif isClient() and sendClientCommand then
    sendClientCommand(self.character, "resuscityno", "revive", { username = self.target:getUsername() })
  end
  return true
end

function ResusReviveAction:getDuration()
  if self.character and self.character:isTimedActionInstant() then return 1 end
  local seconds = Resus and Resus.Config and Resus.Config.REVIVE_SECONDS or 6
  return math.max(1, seconds * 50)
end

function ResusReviveAction:new(character, target)
  local o = ISBaseTimedAction.new(self, character)
  o.character = character
  o.target = target
  o.maxTime = o:getDuration()
  o.stopOnWalk = true
  o.stopOnRun = true
  o.stopOnAim = true
  return o
end
