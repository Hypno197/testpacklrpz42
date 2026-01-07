JaxeRevival.Incapacitation = {}

local CLIENT_COMMAND_INTERVAL_MINUTES = 2

local lastClientCommandUpdate

local conclude = function(player)
  if JaxeRevival.Incapacitation.canRecoveryUnassisted(player) then
    JaxeRevival.Incapacitation.revive(player, true)
  else
    JaxeRevival.Incapacitation.kill(player)
  end
end

local stabilize = function(player)
  local body = player:getBodyDamage()

  if SandboxVars.JaxeRevival.RecoveryRemovesInjuries then
    body:RestoreToFullHealth()
    return
  end

  local visibleHealth = JaxeRevival.UI.getActualHealth(1)

  player:getBodyDamage():AddGeneralHealth(999)
  player:getBodyDamage():ReduceGeneralHealth(100 - visibleHealth)
  JaxeRevival.UI.setActualHealth(player, visibleHealth)

  body:setCatchACold(0)
  body:setHasACold(false)
  body:setColdStrength(0)
  body:setSneezeCoughActive(0)
  body:setSneezeCoughTime(0)
  body:setPoisonLevel(0)
  body:setFoodSicknessLevel(0)
  body:setBoredomLevel(0)
  body:setUnhappynessLevel(0)

  local parts = body:getBodyParts()
  for i = 0, BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
    local part = parts:get(i)

    part:setAdditionalPain(0)
    part:setInfectedWound(false)
    part:setWoundInfectionLevel(0)
    part:setNeedBurnWash(false)
    part:setLastTimeBurnWash(0)

    if not JaxeRevival.Sync.isMultiplayer() then
      part:setBleeding(false)
      part:setBleedingTime(0)
    end
  end
end

local setPerkLevel = function(player, perk, level)
  local world = getWorld()
  local mode = world:getGameMode()
  world:setGameMode("Tutorial")

  player:getXp():AddXP(perk, -999999)
  player:setPerkLevelDebug(perk, 0)

  player:getXp():AddXP(perk, PerkFactory.getPerk(perk):getTotalXpForLevel(level))
  xpUpdate.levelPerk(player, perk, level)

  world:setGameMode(mode)
end

local reducePerkLevel = function(player, perk, modifier) setPerkLevel(player, perk, math.floor(player:getPerkLevel(perk) * (1 - (modifier / 100)))) end

local applyConsequences = function(player)
  if SandboxVars.JaxeRevival.PassiveSkillLoss > 0 then
    reducePerkLevel(player, Perks.Fitness, SandboxVars.JaxeRevival.PassiveSkillLoss)
    reducePerkLevel(player, Perks.Strength, SandboxVars.JaxeRevival.PassiveSkillLoss)
  end

  if SandboxVars.JaxeRevival.AgilitySkillLoss > 0 then
    reducePerkLevel(player, Perks.Sprinting, SandboxVars.JaxeRevival.AgilitySkillLoss)
    reducePerkLevel(player, Perks.Lightfoot, SandboxVars.JaxeRevival.AgilitySkillLoss)
    reducePerkLevel(player, Perks.Nimble, SandboxVars.JaxeRevival.AgilitySkillLoss)
    reducePerkLevel(player, Perks.Sneak, SandboxVars.JaxeRevival.AgilitySkillLoss)
  end

  if SandboxVars.JaxeRevival.WeaponSkillLoss > 0 then
    reducePerkLevel(player, Perks.Aiming, SandboxVars.JaxeRevival.WeaponSkillLoss)
    reducePerkLevel(player, Perks.Reloading, SandboxVars.JaxeRevival.WeaponSkillLoss)
    reducePerkLevel(player, Perks.Axe, SandboxVars.JaxeRevival.WeaponSkillLoss)
    reducePerkLevel(player, Perks.Blunt, SandboxVars.JaxeRevival.WeaponSkillLoss)
    reducePerkLevel(player, Perks.SmallBlunt, SandboxVars.JaxeRevival.WeaponSkillLoss)
    reducePerkLevel(player, Perks.LongBlade, SandboxVars.JaxeRevival.WeaponSkillLoss)
    reducePerkLevel(player, Perks.SmallBlade, SandboxVars.JaxeRevival.WeaponSkillLoss)
    reducePerkLevel(player, Perks.Spear, SandboxVars.JaxeRevival.WeaponSkillLoss)
    reducePerkLevel(player, Perks.Maintenance, SandboxVars.JaxeRevival.WeaponSkillLoss)
  end

  if SandboxVars.JaxeRevival.OtherSkillLoss > 0 then
    reducePerkLevel(player, Perks.Woodwork, SandboxVars.JaxeRevival.OtherSkillLoss)
    reducePerkLevel(player, Perks.Cooking, SandboxVars.JaxeRevival.OtherSkillLoss)
    reducePerkLevel(player, Perks.Farming, SandboxVars.JaxeRevival.OtherSkillLoss)
    reducePerkLevel(player, Perks.Doctor, SandboxVars.JaxeRevival.OtherSkillLoss)
    reducePerkLevel(player, Perks.Electricity, SandboxVars.JaxeRevival.OtherSkillLoss)
    reducePerkLevel(player, Perks.MetalWelding, SandboxVars.JaxeRevival.OtherSkillLoss)
    reducePerkLevel(player, Perks.Mechanics, SandboxVars.JaxeRevival.OtherSkillLoss)
    reducePerkLevel(player, Perks.Tailoring, SandboxVars.JaxeRevival.OtherSkillLoss)
    reducePerkLevel(player, Perks.Fishing, SandboxVars.JaxeRevival.OtherSkillLoss)
    reducePerkLevel(player, Perks.Trapping, SandboxVars.JaxeRevival.OtherSkillLoss)
    reducePerkLevel(player, Perks.PlantScavenging, SandboxVars.JaxeRevival.OtherSkillLoss)
  end
end

local checkPassives = function(player) return not SandboxVars.JaxeRevival.RecoveryRequiresPassive or player:getPerkLevel(Perks.Fitness) > 0 and player:getPerkLevel(Perks.Strength) > 0 end

JaxeRevival.Incapacitation.applyMechanics = function(player, value)
  local modData = player:getModData()
  local firstTime = value and not modData.JaxeRevival_Incapacitated

  JaxeRevival.Sync.applyEffects(player, value)

  player:setGhostMode(value)
  player:setBlockMovement(value)
  player:setIgnoreAimingInput(value)

  local playerNum = player:getPlayerNum()

  if value then
    if firstTime then
      player:dropHandItems()

      if not checkPassives(player) then
        JaxeRevival.Incapacitation.kill(player)
        return
      end

      applyConsequences(player)
    end

    player:nullifyAiming()
    player:setPerformingAnAction(false)

    local cursor = getCell():getDrag(playerNum)
    if cursor then cursor:exitCursor() end

    local currentTime = getGameTime():getWorldAgeHours()

    if isClient() then
      if not lastClientCommandUpdate or currentTime - lastClientCommandUpdate > (CLIENT_COMMAND_INTERVAL_MINUTES / 60) then
        JaxeRevival.Sync.sendClient(player, JaxeRevival.Sync.INCAPACITATE, JaxeRevival.Sync.getArgsFromTarget(player))

        if lastClientCommandUpdate then
          lastClientCommandUpdate = currentTime
        else
          lastClientCommandUpdate = 0
        end
      end
    end

    player:setAsleep(JaxeRevival.Panel.isFastForwarding(player))

    stabilize(player)

    JaxeRevival.Panel.show(player)

    local limit = SandboxVars.JaxeRevival.IncapacitatedTime <= 0 and (JaxeRevival.Sync.isMultiplayer() and nil or 1) or SandboxVars.JaxeRevival.IncapacitatedTime
    if limit then
      if not modData.JaxeRevival_IncapacitatedEnd then
        local variance = (ZombRand(SandboxVars.JaxeRevival.IncapacitatedTimeVariance + 1) - (SandboxVars.JaxeRevival.IncapacitatedTimeVariance / 2)) / 60

        if limit + variance <= 0.5 then
          modData.JaxeRevival_IncapacitatedEnd = 0.5
        else
          modData.JaxeRevival_IncapacitatedEnd = currentTime + limit + variance
        end
      end

      local remaining = modData.JaxeRevival_IncapacitatedEnd - currentTime
      JaxeRevival.Panel.setTimeRemaining(player, remaining)
      if remaining <= 0 then conclude(player) end
    end
  else
    JaxeRevival.Panel.destroy(player)

    modData.JaxeRevival_IncapacitatedEnd = nil

    player:setAsleep(false)
  end

  if UIManager.getFadeAlpha(playerNum) == 1 then UIManager.FadeIn(playerNum, 0) end
end

JaxeRevival.Incapacitation.isActive = function(player) return player:getModData().JaxeRevival_Incapacitated end

JaxeRevival.Incapacitation.canRecoveryUnassisted = function(player)
  if (SandboxVars.JaxeRevival.UnassistedRecovery or isClient()) and not SandboxVars.JaxeRevival.UnassistedRecovery then return false end
  return checkPassives(player)
end

JaxeRevival.Incapacitation.kill = function(player)
  JaxeRevival.Incapacitation.applyMechanics(player, false)
  player:getBodyDamage():ReduceGeneralHealth(999)
  JaxeRevival.UI.setActualHealth(player, 0)
end

JaxeRevival.Incapacitation.revive = function(player, original)
  JaxeRevival.Incapacitation.applyMechanics(player, false)

  local recoveryHealth
  if SandboxVars.JaxeRevival.RecoveryHealth >= 100 then
    recoveryHealth = 100
    player:getBodyDamage():RestoreToFullHealth()
  else
    recoveryHealth = JaxeRevival.UI.getActualHealth(SandboxVars.JaxeRevival.RecoveryHealth)

    player:getBodyDamage():AddGeneralHealth(999)
    player:getBodyDamage():ReduceGeneralHealth(100 - recoveryHealth)
  end
  JaxeRevival.UI.setActualHealth(player, recoveryHealth)

  if original then JaxeRevival.Sync.sendClient(player, JaxeRevival.Sync.REVIVE, JaxeRevival.Sync.getArgsFromTarget(player)) end
end
