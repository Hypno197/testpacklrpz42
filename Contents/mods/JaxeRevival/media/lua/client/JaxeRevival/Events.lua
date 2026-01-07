local onGameTimeLoaded = function()
  JaxeRevival.Compatibility.initialize()

  if JaxeRevival.Sync.isMultiplayer() then return end

  local player = getPlayer()
  if player and JaxeRevival.Incapacitation.isActive(player) then player:setAsleep(false) end
end
Events.OnGameTimeLoaded.Add(onGameTimeLoaded)

local onPlayerUpdate = function(player)
  if player:isDead() or (not JaxeRevival.Incapacitation.isActive(player) and player:getBodyDamage():getHealth() >= SandboxVars.JaxeRevival.IncapacitatedHealth) then return end

  if JaxeRevival.Compatibility.banditsActive and player:getVariableBoolean("Bandit") then return end

  JaxeRevival.Incapacitation.applyMechanics(player, true)
end
Events.OnPlayerUpdate.Add(onPlayerUpdate)

local onPlayerDeath = function(player) JaxeRevival.Panel.destroy(player) end
Events.OnPlayerDeath.Add(onPlayerDeath)

local onWeaponHitCharacter = function(attacker, defender, _, damage)
  if not JaxeRevival.Incapacitation.isActive(defender) or not instanceof(attacker, "IsoPlayer") or damage <= 0 then return end
  JaxeRevival.Incapacitation.kill(defender)
end
Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)

local onPreUIDraw = function()
  if not getPlayer() then return end
  JaxeRevival.UI.applyEffectiveHealth(true)
end
Events.OnPreUIDraw.Add(onPreUIDraw)

local onPostUIDraw = function()
  if not getPlayer() then return end
  JaxeRevival.UI.applyEffectiveHealth(false)
end
Events.OnPostUIDraw.Add(onPostUIDraw)

local onServerCommand = function(module, command, args)
  if module ~= JaxeRevival.id then return end

  if command == JaxeRevival.Sync.INCAPACITATE then
    local player = JaxeRevival.Sync.getTargetFromArgs(args)
    if not player then return end

    JaxeRevival.Sync.applyEffects(player, true)
  elseif command == JaxeRevival.Sync.REVIVE then
    local player = JaxeRevival.Sync.getTargetFromArgs(args)
    if not player then JaxeRevival.log("Invalid player for Revive command") end

    JaxeRevival.Incapacitation.revive(player, false)
  end
end
Events.OnServerCommand.Add(onServerCommand)
