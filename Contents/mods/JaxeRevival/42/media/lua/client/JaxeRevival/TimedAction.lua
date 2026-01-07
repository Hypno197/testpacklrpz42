require "TimedActions/ISBaseTimedAction"

JaxeRevival.TimedAction = ISBaseTimedAction:derive("JaxeRevival.ReviveTimedAction")

function JaxeRevival.TimedAction:isValid() return true end

local function canFaceTarget(self)
  if not self or not self.character or not self.target then return false end
  local okCx, cx = pcall(self.character.getX, self.character)
  local okCy, cy = pcall(self.character.getY, self.character)
  local okTx, tx = pcall(self.target.getX, self.target)
  local okTy, ty = pcall(self.target.getY, self.target)
  if not (okCx and okCy and okTx and okTy) then return false end
  if cx == tx and cy == ty then return false end
  return true
end

function JaxeRevival.TimedAction:update()
  if canFaceTarget(self) then
    self.character:faceThisObject(self.target)
  end
end

function JaxeRevival.TimedAction:waitToStart()
  if canFaceTarget(self) then
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
  end
  return false
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
