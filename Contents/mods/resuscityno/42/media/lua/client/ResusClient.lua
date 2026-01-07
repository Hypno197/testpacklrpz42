Resus = Resus or {}
Resus.Client = Resus.Client or {}

if not Resus.Config then pcall(require, "ResusConfig") end
if not ResusReviveAction then pcall(require, "TimedActions/ResusReviveAction") end

local function isAdminPlayer(player)
  if not player then return false end
  local ok, isAdmin = pcall(player.isAdmin, player)
  if ok and isAdmin then return true end
  local ok2, level = pcall(player.getAccessLevel, player)
  return ok2 and level and level ~= "None"
end

local function canRevive(player)
  if isAdminPlayer(player) then return true end
  if not Resus or not Resus.Config then return false end
  local reqLevel = Resus.Config.REQUIRE_FIRST_AID_LEVEL or 0
  if reqLevel > 0 then
    local perk = Perks and Perks.Doctor or nil
    local okLvl, lvl = pcall(player.getPerkLevel, player, perk)
    if okLvl and lvl and lvl >= reqLevel then return true end
  end
  if Resus.Config.REQUIRE_DEFIB then
    local okInv, inv = pcall(player.getInventory, player)
    local defib = Resus.Config.DEFIB_ITEM
    if okInv and inv and defib and inv.getItemFromType then
      local okItem, item = pcall(inv.getItemFromType, inv, defib)
      if okItem and item then return true end
    end
  end
  return false
end

local function inRange(a, b)
  local dx = a:getX() - b:getX()
  local dy = a:getY() - b:getY()
  return (dx * dx + dy * dy) <= (Resus.Config.REVIVE_RANGE_SQ or 9)
end

local function getNowSeconds()
  local ok, ts = pcall(getTimestamp)
  if ok and ts then return math.floor(ts / 1000) end
  local gt = getGameTime()
  if not gt or not gt.getWorldAgeHours then return 0 end
  return (gt:getWorldAgeHours() or 0) * 3600
end

local function getDownedRemaining(player)
  if not player then return 0 end
  local md = player:getModData()
  local endTime = md and md.Resus_DownedEnd or nil
  if not endTime then return 0 end
  local remaining = math.floor(endTime - getNowSeconds())
  if remaining < 0 then remaining = 0 end
  return remaining
end

local function formatTime(seconds)
  local s = math.max(0, tonumber(seconds) or 0)
  local m = math.floor(s / 60)
  local r = s % 60
  return string.format("%02d:%02d", m, r)
end

local function isIncapacitated(p)
  if not p then return false end
  local md = p:getModData()
  if md and md.Resus_Incapacitated then return true end
  local okFloor, onFloor = pcall(p.isOnFloor, p)
  return okFloor and onFloor
end

local function onServerCommand(module, command, args)
  if module ~= "resuscityno" then return end
  if command ~= "incap" or not args or not args.username then return end
  local p = getPlayerFromUsername(args.username)
  if not p then return end
  local value = args.value and true or false
  local md = p:getModData()
  md.Resus_Incapacitated = value or nil
  md.Resus_DownedEnd = args.endTime
  pcall(p.setOnFloor, p, value)
end
Events.OnServerCommand.Add(onServerCommand)

local function startReviveAction(source, target)
  if not source or not target then return end
  if not ISTimedActionQueue or not ResusReviveAction then return end
  ISTimedActionQueue.add(ResusReviveAction:new(source, target))
end

local function sendGiveUp(player)
  if not player then return end
  if not sendClientCommand then return end
  sendClientCommand(player, "resuscityno", "giveUp", {})
end

local function collectPlayers()
  local list = {}
  local ok, players = pcall(getOnlinePlayers)
  if ok and players then
    if players.size and players.get then
      for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p then list[#list + 1] = p end
      end
    elseif type(players) == "table" then
      for _, p in pairs(players) do
        if p then list[#list + 1] = p end
      end
    end
  end
  return list
end

local function onFillWorldObjectContextMenu(player, context, worldobjects, test)
  if test then return true end
  if not player or not context then return end

  if isIncapacitated(player) then
    local remaining = getDownedRemaining(player)
    local label = getText("UI_Resus_GiveUp") .. " (" .. formatTime(remaining) .. ")"
    context:addOption(label, player, sendGiveUp)
  end

  if not canRevive(player) then return end

  local list = collectPlayers()
  local sub = nil
  local subMenu = nil
  for i = 1, #list do
    local p = list[i]
    if p and p ~= player and isIncapacitated(p) and inRange(player, p) then
      if not subMenu then
        sub = context:addOption(getText("UI_Resus_RevivePlayer"))
        subMenu = ISContextMenu:getNew(context)
        context:addSubMenu(sub, subMenu)
      end
      subMenu:addOption(p:getUsername(), player, startReviveAction, p)
    end
  end
end
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
