JaxeRevival.UI = {}

local playersHealth = {}
JaxeRevival.UI.setActualHealth = function(player, value)
  if playersHealth[player:getPlayerNum()] then playersHealth[player:getPlayerNum()] = value end
end

JaxeRevival.UI.getEffectiveHealth = function(actual) return ((actual - SandboxVars.JaxeRevival.IncapacitatedHealth) / (100 - SandboxVars.JaxeRevival.IncapacitatedHealth)) * 100 end
JaxeRevival.UI.getActualHealth = function(effective) return ((effective / 100) * (100 - SandboxVars.JaxeRevival.IncapacitatedHealth)) + SandboxVars.JaxeRevival.IncapacitatedHealth end

JaxeRevival.UI.applyEffectiveHealth = function(value)
  if value then playersHealth = {} end

  local players = isClient() and getOnlinePlayers() or IsoPlayer.getPlayers()
  if not players then return end

  for i = 0, players:size() - 1 do
    local player = players:get(i)
    if player then
      local body = player:isLocalPlayer() and player:getBodyDamage() or player:getBodyDamageRemote()

      if value then
        playersHealth[i] = body:getHealth()
        if JaxeRevival.Incapacitation.isActive(player) then
          body:setOverallBodyHealth(0.5)
        elseif not player:isDead() then
          body:setOverallBodyHealth(JaxeRevival.UI.getEffectiveHealth(playersHealth[i]))
        end
      else
        body:setOverallBodyHealth(playersHealth[i])
      end
    end
  end
end

local onReviveAction = function(player, target) ISTimedActionQueue.add(JaxeRevival.TimedAction:new(player, target)) end

local onFillWorldObjectContextMenu = function(playerNum, context)
  local player = getSpecificPlayer(playerNum)
  if JaxeRevival.Incapacitation.isActive(player) then
    context:clear()
    return
  end

  if not clickedPlayer or not JaxeRevival.Incapacitation.isActive(clickedPlayer) then return end

  if SandboxVars.JaxeRevival.FirstAidRequired > 0 and SandboxVars.JaxeRevival.FirstAidRequired > player:getPerkLevel(Perks.Doctor) then
    local option = context:addOptionOnTop(string.format(getText("ContextMenu_JaxeRevival_ActionFirstAidRequired"), clickedPlayer:getDisplayName(), SandboxVars.JaxeRevival.FirstAidRequired))
    option.notAvailable = true
  elseif SandboxVars.JaxeRevival.DoctorProfessionRequired and player:getDescriptor():getProfession() ~= "doctor" then
    local option = context:addOptionOnTop(string.format(getText("ContextMenu_JaxeRevival_ActionDoctorProfessionRequired"), clickedPlayer:getDisplayName(), SandboxVars.JaxeRevival.FirstAidRequired))
    option.notAvailable = true
  else
    context:addOptionOnTop(string.format(getText("ContextMenu_JaxeRevival_Action"), clickedPlayer:getDisplayName()), player, onReviveAction, clickedPlayer)
  end
end
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

local onFillInventoryObjectContextMenu = function(playerNum, context)
  local player = getSpecificPlayer(playerNum)
  if JaxeRevival.Incapacitation.isActive(player) then
    context:clear()
    return
  end
end
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)

local original_ISFitnessUI_onClick = ISFitnessUI.onClick
ISFitnessUI.onClick = function(self, button)
  if button.internal == "OK" and JaxeRevival.Incapacitation.isActive(self.player) then return end
  original_ISFitnessUI_onClick(self, button)
end

local original_ISEmoteRadialMenu_checkKey = ISEmoteRadialMenu.checkKey
ISEmoteRadialMenu.checkKey = function(key)
  local player = getSpecificPlayer(0)
  if not player or JaxeRevival.Incapacitation.isActive(player) then return false end
  return original_ISEmoteRadialMenu_checkKey(key)
end

local original_ISSearchManager_toggleSearchMode = ISSearchManager.toggleSearchMode
ISSearchManager.toggleSearchMode = function(self, _isSearchMode)
  if JaxeRevival.Incapacitation.isActive(self.character) then
    self.updateTick = 0
    return
  end
  original_ISSearchManager_toggleSearchMode(self, _isSearchMode)
end
