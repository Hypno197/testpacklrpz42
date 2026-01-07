if not JaxeRevival then JaxeRevival = {} end
JaxeRevival.Sync = {}

JaxeRevival.Sync.INCAPACITATE = "incapacitate"
JaxeRevival.Sync.REVIVE = "revive"

local ANIMATION_VARIABLE = "JaxeRevival_Incapacitated"

JaxeRevival.Sync.isMultiplayer = function() return isClient() or isServer() end

JaxeRevival.Sync.getArgsFromTarget = function(target) return { username = target:getUsername() } end

JaxeRevival.Sync.getTargetFromArgs = function(args)
  if not args or not args.username then return end
  return getPlayerFromUsername(args.username)
end

JaxeRevival.Sync.sendClient = function(player, command, args) sendClientCommand(player, JaxeRevival.id, command, args) end

JaxeRevival.Sync.sendServer = function(command, args) sendServerCommand(JaxeRevival.id, command, args) end

JaxeRevival.Sync.applyEffects = function(player, value)
  if value and not JaxeRevival.Incapacitation.isActive(player) then player:playDeadSound() end

  player:getModData().JaxeRevival_Incapacitated = value or nil

  if value then
    player:StopAllActionQueue()
    player:setVariable(ANIMATION_VARIABLE, true)
    player:clearVariable("ExerciseStarted")
    player:clearVariable("ExerciseEnded")
  else
    player:clearVariable(ANIMATION_VARIABLE)
    player:setGhostMode(false)
  end

  player:setOnFloor(value)
end
