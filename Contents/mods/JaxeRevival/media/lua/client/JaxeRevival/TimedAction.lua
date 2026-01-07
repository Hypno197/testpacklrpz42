require "TimedActions/ISBaseTimedAction"

JaxeRevival.TimedAction = ISBaseTimedAction:derive("JaxeRevival.ReviveTimedAction")

function JaxeRevival.TimedAction:isValid() return true end

function JaxeRevival.TimedAction:update() self.character:faceThisObject(self.target) end

function JaxeRevival.TimedAction:waitToStart()
  self.character:faceThisObject(self.target)
  return self.character:shouldBeTurning()
end

local start

function JaxeRevival.TimedAction:start()
  self:setActionAnim("Loot")
  self.character:SetVariable("LootPosition", "Low")
  start = getGameTime():getWorldAgeHours()
end

function JaxeRevival.TimedAction:stop() ISBaseTimedAction.stop(self) end

function JaxeRevival.TimedAction:perform()
  ISBaseTimedAction.perform(self)

  print("@@@@@@@@ " .. tostring(getGameTime():getWorldAgeHours() - start))

  if isClient() then JaxeRevival.Sync.sendClient(self.character, JaxeRevival.Sync.REVIVE, JaxeRevival.Sync.getArgsFromTarget(self.target)) end
end

function JaxeRevival.TimedAction:new(character, target)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.maxTime = SandboxVars.JaxeRevival.AssistedRecoveryTicks - ((SandboxVars.JaxeRevival.AssistedRecoveryTicks * character:getPerkLevel(Perks.Doctor)) / 20)
  o.stopOnWalk = true
  o.stopOnRun = true

  o.character = character
  o.target = target

  if o.character:isTimedActionInstant() then o.maxTime = 1 end

  luautils.walkAdj(character, target:getSquare())

  return o
end
