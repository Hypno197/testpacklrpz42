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

local function isAdminPlayer(player)
  if not player then return false end
  local ok, isAdmin = pcall(player.isAdmin, player)
  if ok and isAdmin then return true end
  local ok2, level = pcall(player.getAccessLevel, player)
  return ok2 and level and level ~= "None"
end

local function startReviveAction(sourcePlayer, targetPlayer)
  if not sourcePlayer or not targetPlayer then return end
  if not JaxeRevival or not JaxeRevival.TimedAction then return end
  if not ISTimedActionQueue or not ISTimedActionQueue.add then return end
  ISTimedActionQueue.add(JaxeRevival.TimedAction:new(sourcePlayer, targetPlayer))
end

local function collectOnlinePlayers()
  local list = {}
  local ok, players = pcall(getOnlinePlayers)
  if ok and players then
    if players.size and players.get then
      for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p then table.insert(list, p) end
      end
    elseif type(players) == "table" then
      for _, p in pairs(players) do
        if p then table.insert(list, p) end
      end
    end
  end
  return list
end

local function isIncapacitatedTarget(player)
  if not player then return false end
  local okActive, active = pcall(JaxeRevival.Incapacitation.isActive, player)
  if okActive and active then return true end
  local okMd, md = pcall(player.getModData, player)
  if okMd and md and md.JaxeRevival_Incapacitated then return true end
  local okFloor, onFloor = pcall(player.isOnFloor, player)
  if okFloor and onFloor then return true end
  return false
end

local function onFillWorldObjectContextMenu(player, context, worldobjects, test)
  if test then return true end
  if not player or not context then return end
  if not isAdminPlayer(player) then return end
  local players = collectOnlinePlayers()
  if not players or #players == 0 then return end
  local sub = nil
  local subMenu = nil
  local added = 0
  for i = 1, #players do
    local p = players[i]
    local name = p and p.getUsername and p:getUsername() or nil
    if name and name ~= "" and isIncapacitatedTarget(p) then
      if not subMenu then
        sub = context:addOption("JaxeRevival: Revive Player")
        subMenu = ISContextMenu:getNew(context)
        context:addSubMenu(sub, subMenu)
      end
      subMenu:addOption(name, player, startReviveAction, p)
      added = added + 1
    end
  end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
