if not Rogue then Rogue = {} end
if not Rogue.WeaponMods then require "RogueWeaponMods" end
if not Rogue.WeaponModAction then require "RogueWeaponModAction" end
if not Rogue.WeaponScrapAction then require "RogueWeaponScrapAction" end
require "ISUI/ISContextMenu"

local WeaponMods = Rogue.WeaponMods
local Config = Rogue.Config or {}

if Config and Config.WEAPON_MOD_DEBUG then
    print("[Roguelityno][WeaponMod][Debug] RogueWeaponModsClient loaded")
end

local function setOptionIcon(option, texturePath)
    if not option or not texturePath then return end
    local tex = getTexture(texturePath)
    if tex then
        option.iconTexture = tex
    end
end

local function matchesSprite(obj)
    if not obj or not obj.getSprite then return false end
    local okSprite, sprite = pcall(obj.getSprite, obj)
    if not okSprite or not sprite or not sprite.getName then return false end
    local okName, name = pcall(sprite.getName, sprite)
    if not okName or not name then return false end
    local list = Config.WEAPON_MOD_WORKBENCH_SPRITES or {}
    for i = 1, #list do
        if list[i] == name then return true end
    end
    return false
end

local function matchesObjectName(obj)
    if not obj or not obj.getObjectName then return false end
    local okName, name = pcall(obj.getObjectName, obj)
    if not okName or not name then return false end
    local list = Config.WEAPON_MOD_WORKBENCH_NAMES or {}
    for i = 1, #list do
        if list[i] == name then return true end
    end
    return false
end

local function isWorkbench(objects)
    for _, obj in ipairs(objects) do
        if matchesSprite(obj) or matchesObjectName(obj) then
            return true
        end
    end
    return false
end

local function debugObjects(objects)
    if not (Config and Config.WEAPON_MOD_DEBUG) then return end
    for _, obj in ipairs(objects) do
        local spriteName = nil
        if obj and obj.getSprite then
            local okSprite, sprite = pcall(obj.getSprite, obj)
            if okSprite and sprite and sprite.getName then
                local okName, name = pcall(sprite.getName, sprite)
                if okName then spriteName = name end
            end
        end
        local objName = nil
        if obj and obj.getObjectName then
            local okName, name = pcall(obj.getObjectName, obj)
            if okName then objName = name end
        end
        print(string.format("[Roguelityno][WeaponMod][Debug] obj=%s sprite=%s name=%s",
            tostring(obj),
            tostring(spriteName),
            tostring(objName)
        ))
    end
end

local function getEligibleWeapons(inv)
    local list = {}
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if WeaponMods.isEligibleWeapon(item) and not WeaponMods.hasMod(item) then
            table.insert(list, item)
        end
    end
    return list
end

local function getCompatibleKits(inv, weapon, player)
    local list = {}
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local def = WeaponMods.getKitDefByItem(item)
        if def and WeaponMods.isKitCompatible(def, weapon, player) then
            table.insert(list, { item = item, def = def })
        end
    end
    return list
end

local function getWeaponLabel(weapon)
    if weapon and weapon.getName then
        return weapon:getName()
    end
    return "Weapon"
end

local function getKitLabel(def)
    local key = def and def.labelKey or nil
    if key and getText then
        local label = getText(key)
        if label ~= key then
            return label
        end
    end
    return def and def.id or "Kit"
end

local function onWorkbenchMenu(player, context, worldObjects)
    debugObjects(worldObjects)
    if not isWorkbench(worldObjects) then return end
    local inv = player:getInventory()
    local weapons = getEligibleWeapons(inv)
    if #weapons == 0 then
        context:addOption(getText("UI_rogue_weaponmod_no_weapon"))
        return
    end

    local mainOpt = context:addOptionOnTop(getText("UI_rogue_weaponmod_action"))
    setOptionIcon(mainOpt, "media/textures/Item_modkit_rare.png")
    local mainMenu = ISContextMenu:getNew(context)
    context:addSubMenu(mainOpt, mainMenu)

    for i = 1, #weapons do
        local weapon = weapons[i]
        local kits = getCompatibleKits(inv, weapon, player)
        if Config and Config.WEAPON_MOD_DEBUG then
            print(string.format("[Roguelityno][WeaponMod][Debug] weapon=%s kits=%d",
                tostring(getWeaponLabel(weapon)),
                #kits
            ))
        end
        local wOpt = mainMenu:addOption(getWeaponLabel(weapon))
        local wMenu = ISContextMenu:getNew(mainMenu)
        mainMenu:addSubMenu(wOpt, wMenu)
        if #kits == 0 then
            wMenu:addOption(getText("UI_rogue_weaponmod_no_kit"))
        else
            for k = 1, #kits do
                local entry = kits[k]
                local kitLabel = getKitLabel(entry.def)
                wMenu:addOption(kitLabel, nil, function()
                    ISTimedActionQueue.add(Rogue.WeaponModAction:new(player, weapon, entry.item))
                end)
            end
        end
    end
end

local function onScrapMenu(player, context, items)
    local md = player and player.getModData and player:getModData() or nil
    if Config and Config.WEAPON_MOD_DEBUG then
        print(string.format("[Roguelityno][WeaponMod][Debug] scrapMenu player=%s buildId=%s items=%d",
            tostring(player and player.getUsername and player:getUsername() or "nil"),
            tostring(md and md.RogueBuildId or "nil"),
            tonumber(items and #items or 0)
        ))
    end
    if not (md and md.RogueBuildId == (Config.BUILD_ID_MR_RUMBLE or "roguelityno:mr_rumble")) then
        return
    end
    local target = nil
    for i = 1, #items do
        local entry = items[i]
        local item = entry.items and entry.items[1] or entry
        if Config and Config.WEAPON_MOD_DEBUG then
            print(string.format("[Roguelityno][WeaponMod][Debug] scrapItem type=%s isWeapon=%s eligible=%s cond=%s/%s",
                tostring(item and item.getFullType and item:getFullType() or item),
                tostring(item and instanceof(item, "HandWeapon")),
                tostring(item and WeaponMods.isScrapEligible(item)),
                tostring(item and item.getCondition and item:getCondition() or "nil"),
                tostring(item and item.getConditionMax and item:getConditionMax() or "nil")
            ))
        end
        if item and instanceof(item, "HandWeapon") and WeaponMods.isScrapEligible(item) then
            target = item
            break
        end
    end
    if not target then return end
    local label = getText("UI_rogue_weaponmod_scrap")
    local opt = context:addOptionOnTop(label, nil, function()
        ISTimedActionQueue.add(Rogue.WeaponScrapAction:new(player, target))
    end)
    setOptionIcon(opt, "media/textures/Item_modkit_improv.png")
    if Config and Config.WEAPON_MOD_DEBUG then
        local optCount = context and context.options and #context.options or 0
        print(string.format("[Roguelityno][WeaponMod][Debug] scrapMenu addOption label=%s optCount=%d opt=%s",
            tostring(label),
            tonumber(optCount),
            tostring(opt)
        ))
    end
end

Events.OnFillWorldObjectContextMenu.Add(function(playerIndex, context, worldObjects)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end
    if Config and Config.WEAPON_MOD_DEBUG then
        print(string.format("[Roguelityno][WeaponMod][Debug] OnFillWorldObjectContextMenu objs=%d",
            tonumber(worldObjects and #worldObjects or 0)
        ))
    end
    onWorkbenchMenu(player, context, worldObjects)
end)

Events.OnFillInventoryObjectContextMenu.Add(function(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end
    if Config and Config.WEAPON_MOD_DEBUG then
        print(string.format("[Roguelityno][WeaponMod][Debug] OnFillInventoryObjectContextMenu items=%d",
            tonumber(items and #items or 0)
        ))
    end
    onScrapMenu(player, context, items)
end)

Events.OnRefreshInventoryWindowContainers.Add(function()
    local player = getPlayer()
    if not player or not player.getInventory then return end
    local inv = player:getInventory()
    if not inv or not inv.getItems then return end
    local cfg = Rogue.Config or {}
    local yellow = cfg.UI_COLOR_TEXT or { r = 0.95, g = 0.83, b = 0.15 }
    local red = cfg.ARENA_BORDER_MARKER_COLOR or { r = 0.9, g = 0.05, b = 0.05 }
    local green = (cfg.SHOP_MARKER_COLOR_BY_CATEGORY and cfg.SHOP_MARKER_COLOR_BY_CATEGORY.medical)
        or { r = 0.2, g = 1.0, b = 0.6 }
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item.getModData and item.getName and item.setName then
            local md = item:getModData()
            local mod = md and md.RogueWeaponMod or nil
            if mod and mod.labelPrefix then
                local base = mod.baseName or item:getName()
                local newName = WeaponMods.buildDisplayName(base, mod.labelPrefix)
                if item:getName() ~= newName then
                    item:setName(newName)
                end
                local kind = tostring(mod.kind or "")
                local color = yellow
                if kind == "blessing" then
                    color = green
                elseif kind == "bad" then
                    color = red
                end
                if item.setColorRed and item.setColorGreen and item.setColorBlue then
                    item:setColorRed(color.r or 1)
                    item:setColorGreen(color.g or 1)
                    item:setColorBlue(color.b or 1)
                    if item.setCustomColor then
                        item:setCustomColor(true)
                    end
                end
                if item.setTooltip and getText then
                    local label = mod.descKey and getText(mod.descKey) or mod.labelPrefix
                    local kindKey = "UI_rogue_weaponmod_kind_" .. kind
                    local kindLabel = getText(kindKey)
                    if kindLabel == kindKey then
                        kindLabel = kind
                    end
                    local line1 = getText("UI_rogue_weaponmod_tooltip", label)
                    local line2 = getText("UI_rogue_weaponmod_tooltip_kind", kindLabel)
                    item:setTooltip(tostring(line1) .. "\n" .. tostring(line2))
                end
            end
        end
    end
end)
