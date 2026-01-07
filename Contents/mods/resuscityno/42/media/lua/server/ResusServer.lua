Resus = Resus or {}
Resus.Server = Resus.Server or {}

if not Resus.Config then pcall(require, "ResusConfig") end

local function log(...)
  if getDebug() or isServer() then
    local args = { ... }
    for i = 1, #args do args[i] = tostring(args[i]) end
    print("[Resuscityno] " .. table.concat(args, " | "))
  end
end

Resus.Server.log = log

local function getNowSeconds()
  local ok, ts = pcall(getTimestamp)
  if ok and ts then return math.floor(ts / 1000) end
  local gt = getGameTime()
  if not gt or not gt.getWorldAgeHours then return 0 end
  return (gt:getWorldAgeHours() or 0) * 3600
end

local function clampHealth(player, target)
  if not player or not target then return end
  local body = player:getBodyDamage()
  local cur = body:getHealth()
  if cur < target then
    body:AddGeneralHealth(target - cur)
  elseif cur > target then
    body:ReduceGeneralHealth(cur - target)
  end
end

local function sendState(player, value, reason)
  if not player then return end
  local md = player:getModData()
  local endTime = md and md.Resus_DownedEnd or nil
  sendServerCommand("resuscityno", "incap", {
    username = player:getUsername(),
    value = value and true or false,
    reason = reason or "",
    endTime = endTime,
  })
end

local function setIncapState(player, value, reason)
  if not player then return end
  local md = player:getModData()
  if md.Resus_Incapacitated == value then return end

  md.Resus_Incapacitated = value or nil

  if value then
    clampHealth(player, Resus.Config.INCAP_HEALTH)
    local startTime = getNowSeconds()
    local downedSeconds = Resus.Config.DOWNED_SECONDS or 0
    if downedSeconds > 0 then
      md.Resus_DownedStart = startTime
      md.Resus_DownedEnd = startTime + downedSeconds
    else
      md.Resus_DownedStart = nil
      md.Resus_DownedEnd = nil
    end
    pcall(player.setOnFloor, player, true)
    pcall(player.setBlockMovement, player, true)
    pcall(player.setIgnoreAimingInput, player, true)
  else
    md.Resus_DownedStart = nil
    md.Resus_DownedEnd = nil
    pcall(player.setOnFloor, player, false)
    pcall(player.setBlockMovement, player, false)
    pcall(player.setIgnoreAimingInput, player, false)
  end

  sendState(player, value, reason)
  log("incapState", player:getUsername(), "value=" .. tostring(value), "reason=" .. tostring(reason))
end

local function canRevive(sourcePlayer)
  if not sourcePlayer then return false end
  local okAdmin, isAdmin = pcall(sourcePlayer.isAdmin, sourcePlayer)
  if okAdmin and isAdmin then return true end

  local reqLevel = Resus.Config.REQUIRE_FIRST_AID_LEVEL or 0
  if reqLevel > 0 then
    local okLvl, lvl = pcall(sourcePlayer.getPerkLevel, sourcePlayer, Perks.Doctor)
    if okLvl and lvl and lvl >= reqLevel then return true end
  end

  if Resus.Config.REQUIRE_DEFIB then
    local inv = sourcePlayer:getInventory()
    local defib = Resus.Config.DEFIB_ITEM
    if inv and defib and inv:getItemFromType(defib) then return true end
  end

  return false end

local function inRange(a, b)
  if not a or not b then return false end
  local dx = a:getX() - b:getX()
  local dy = a:getY() - b:getY()
  return (dx * dx + dy * dy) <= (Resus.Config.REVIVE_RANGE_SQ or 9)
end

Resus.Server.revivePlayer = function(sourcePlayer, targetPlayer)
  if not sourcePlayer or not targetPlayer then return end
  if targetPlayer:isDead() then return end
  if not (targetPlayer:getModData().Resus_Incapacitated or targetPlayer:isOnFloor()) then return end
  if not canRevive(sourcePlayer) then
    log("reviveDenied", sourcePlayer:getUsername(), "reason=requirements")
    return
  end
  if not inRange(sourcePlayer, targetPlayer) then
    log("reviveDenied", sourcePlayer:getUsername(), "reason=range")
    return
  end

  clampHealth(targetPlayer, Resus.Config.REVIVE_HEALTH)
  setIncapState(targetPlayer, false, "revive")
  log("revived", sourcePlayer:getUsername(), "target=" .. targetPlayer:getUsername())
end

local function forceDeath(player, reason)
  if not player then return end
  local body = player:getBodyDamage()
  local cur = body:getHealth()
  body:ReduceGeneralHealth(cur + 5)
  log("forceDeath", player:getUsername(), "reason=" .. tostring(reason))
end

local function onWeaponHitCharacter(attacker, target, weapon, damage)
  if not target then return end
  local okIsPlayer, isPlayer = pcall(target.isPlayer, target)
  if not okIsPlayer or not isPlayer then return end

  local md = target:getModData()
  local hitType = "melee"
  local okZombie, isZombie = pcall(attacker.isZombie, attacker)
  if okZombie and isZombie then
    hitType = "zombie"
  else
    local okRanged, isRanged = pcall(weapon.isRanged, weapon)
    if okRanged and isRanged then
      hitType = "gun"
    end
  end

  md.Resus_LastHitType = hitType
  md.Resus_LastHitTime = getWorldSeconds()
end

local function onPlayerUpdate(player)
  if not player or player:isDead() then return end
  local md = player:getModData()
  if md.Resus_Incapacitated then
    local downedSeconds = Resus.Config.DOWNED_SECONDS or 0
    if downedSeconds > 0 and md.Resus_DownedEnd and getNowSeconds() >= md.Resus_DownedEnd then
      forceDeath(player, "downed-timeout")
    end
    return
  end

  local health = player:getBodyDamage():getHealth()
  if health <= 0 then
    local hitType = md.Resus_LastHitType
    md.Resus_LastHitType = nil
    md.Resus_LastHitTime = nil
    if Resus.Config.OVERKILL_MELEE_OK and hitType == "melee" then
      return
    end
    setIncapState(player, true, "fatal")
    return
  end
  if health <= (Resus.Config.INCAP_HEALTH or 10) then
    setIncapState(player, true, "threshold")
  end
end

local function onPlayerDeath(player)
  if not player then return end
  setIncapState(player, false, "death")
end

local function onClientCommand(module, command, player, args)
  if module ~= "resuscityno" then return end
  if command == "revive" and args and args.username then
    local target = getPlayerFromUsername(args.username)
    Resus.Server.revivePlayer(player, target)
  elseif command == "giveUp" then
    if player and player:getModData().Resus_Incapacitated then
      forceDeath(player, "give-up")
    end
  end
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)
Events.OnPlayerDeath.Add(onPlayerDeath)
Events.OnClientCommand.Add(onClientCommand)
Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)
