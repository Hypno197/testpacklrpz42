if not isClient() and isServer() then return end

Rogue = Rogue or {}
Rogue.Client = Rogue.Client or {}

local Client = Rogue.Client

if not Rogue.Config then require "RogueConfig" end
require "RogueCharCreationLock"
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"
require "ISUI/ISImage"
require "TimedActions/ISTimedActionQueue"
require "RogueFullRestoreAction"
require "RogueBogdanoDrinkAction"
require "RogueWeaponModsClient"
pcall(require, "ISUI/ISInventoryPane")
require "ISUI/ISScrollingListBox"
require "ISUI/ISComboBox"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISMiniMap"

Client._banner = Client._banner or nil
Client._hud = Client._hud or nil
Client._score = Client._score or nil
Client._wallet = Client._wallet or nil
Client._scoreVisible = Client._scoreVisible ~= false
Client._walletVisible = Client._walletVisible ~= false
Client._scoreEscTemp = Client._scoreEscTemp or false
Client._scoreEscPrevVisible = Client._scoreEscPrevVisible or nil
Client._shopMarkers = Client._shopMarkers or {}
Client._shopWorldMarkers = Client._shopWorldMarkers or {}
Client._shopMarkerNextAtMs = Client._shopMarkerNextAtMs or 0
Client._shopMarkerActive = Client._shopMarkerActive or false
Client._shopMarkerStatus = Client._shopMarkerStatus or nil
Client._shopMarkerLogAtMs = Client._shopMarkerLogAtMs or 0
Client._buildId = Client._buildId or nil
Client._panelPos = Client._panelPos or {}
Client.SHOP_MARKER_TICK_MS = 1000
Client.SHOP_MARKER_SIZE = 0.80
Client.SHOP_MARKER_TEX = nil
Client._outsideSoundActive = Client._outsideSoundActive or false
Client._outsideSoundNextAtMs = Client._outsideSoundNextAtMs or 0
Client.UI_PAD_X = 20
Client.UI_PAD_Y = 20
Client.BANNER_PAD_Y = 0
Client.SCORE_EXTRA_BOTTOM = 40

local function T(key, ...)
    if getText then
        return getText(key, ...)
    end
    if select("#", ...) > 0 then
        return string.format(key, ...)
    end
    return key
end

function Client.requestScore()
    sendClientCommand(getPlayer(), "Rogue", "scoreRequest", {})
end
function Client.requestMapList()
    sendClientCommand(getPlayer(), "Rogue", "mapList", {})
end
Client._lastScore = Client._lastScore or nil
Client._lastStatus = Client._lastStatus or "IDLE"
Client._shopPanel = Client._shopPanel or nil
Client._shopObjects = Client._shopObjects or nil
Client._shopStock = Client._shopStock or {}
Client._buildSelectorShown = Client._buildSelectorShown or false
Client._panelPos = Client._panelPos or {}
Client._hudZeroLogAtMs = Client._hudZeroLogAtMs or 0
Client._overtimeLoopActive = Client._overtimeLoopActive or false
Client._overtimeNextAtMs = Client._overtimeNextAtMs or 0
Client._prepCountdownRound = Client._prepCountdownRound or nil
Client._prepReadyActive = Client._prepReadyActive or false
Client._prepReadyRound = Client._prepReadyRound or nil
Client._miniMapPatched = Client._miniMapPatched or false
Client._miniMapOpenedForRun = Client._miniMapOpenedForRun or false
Client._arenaBorderMarkers = Client._arenaBorderMarkers or {}
Client._arenaBorderMarkerNextAtMs = Client._arenaBorderMarkerNextAtMs or 0
Client._arenaBorderMarkerSide = Client._arenaBorderMarkerSide or nil
Client._arenaBorderMarkerCenter = Client._arenaBorderMarkerCenter or nil
Client.ARENA_BORDER_MARKER_TICK_MS = 500
Client.ARENA_BORDER_MARKER_DISTANCE = 4
Client.ARENA_BORDER_MARKER_COUNT = 12
Client.ARENA_BORDER_MARKER_SPACING = 1
Client.ARENA_BORDER_MARKER_ALPHA = 0.4
Client.ARENA_BORDER_MARKER_SIZE = 0.15
Client._mapList = Client._mapList or {}

function Client.getUIColor(key, fallback)
    if Rogue.Config and Rogue.Config[key] then
        return Rogue.Config[key]
    end
    return fallback
end

function Client.getUIFont(size)
    local cfg = Rogue.Config or {}
    local name = nil
    if size == "small" then
        name = cfg.UI_FONT_SMALL
    elseif size == "medium" then
        name = cfg.UI_FONT_MEDIUM
    elseif size == "large" then
        name = cfg.UI_FONT_LARGE
    else
        name = cfg.UI_FONT_SMALL
    end
    if UIFont and name and UIFont[name] then
        return UIFont[name]
    end
    if getTextManager then
        local tm = getTextManager()
        if tm and tm.getFontFromName and name then
            local ok, font = pcall(tm.getFontFromName, tm, name)
            if ok and font then
                return font
            end
        end
    end
    return UIFont.Small
end

function Client.addPanelBackground(panel, texturePath, alpha)
    if not panel or not texturePath or texturePath == "" then return nil end
    local tex = getTexture(texturePath)
    if not tex then return nil end
    local img = ISImage:new(0, 0, panel.width, panel.height, tex)
    img:initialise()
    img.autoScale = true
    img.noAspect = true
    img.backgroundColor = { r = 1, g = 1, b = 1, a = alpha or 0.85 }
    panel:addChild(img)
    panel._bgImage = img
    return img
end

function Client.getItemIconTexture(itemId)
    if not itemId or itemId == "" then return nil end
    local function tryTexture(iconName)
        if not iconName or iconName == "" then return nil end
        local tex = getTexture(iconName)
        if tex then return tex end
        tex = getTexture("media/ui/" .. iconName .. ".png")
        if tex then return tex end
        tex = getTexture("media/textures/" .. iconName .. ".png")
        if tex then return tex end
        tex = getTexture("media/textures/ui/" .. iconName .. ".png")
        if tex then return tex end
        return nil
    end
    local function resolveIcon(icon)
        if not icon or icon == "" then return nil end
        local itemName = icon
        if not string.find(icon, "^Item_") then
            itemName = "Item_" .. icon
        end
        return tryTexture(itemName) or tryTexture(icon)
    end
    local function resolveIconList(iconsForTexture)
        if not iconsForTexture then return nil end
        if type(iconsForTexture) == "string" then
            local first = string.match(iconsForTexture, "([^;,%s]+)")
            if first and first ~= "" then
                return resolveIcon(first)
            end
            return nil
        end
        if type(iconsForTexture) == "table" then
            local first = iconsForTexture[1]
            if first and first ~= "" then
                return resolveIcon(tostring(first))
            end
            return nil
        end
        if iconsForTexture.size and iconsForTexture.get then
            local okSize, size = pcall(iconsForTexture.size, iconsForTexture)
            if okSize and size and size > 0 then
                local okGet, first = pcall(iconsForTexture.get, iconsForTexture, 0)
                if okGet and first then
                    return resolveIcon(tostring(first))
                end
            end
        end
        return nil
    end
    if not InventoryItemFactory or not InventoryItemFactory.CreateItem then
        local sm = getScriptManager()
        if sm and sm.FindItem then
            local scriptItem = sm:FindItem(itemId)
            if scriptItem and scriptItem.getIcon then
                local icon = scriptItem:getIcon()
                local tex = resolveIcon(icon)
                if tex then return tex end
            end
            if scriptItem and scriptItem.getIconsForTexture then
                local okIcons, icons = pcall(scriptItem.getIconsForTexture, scriptItem)
                if okIcons then
                    local tex = resolveIconList(icons)
                    if tex then return tex end
                end
            end
        end
        return nil
    end
    local ok, item = pcall(InventoryItemFactory.CreateItem, itemId)
    if ok and item then
        if item.getTexture then
            local tex = item:getTexture()
            if tex then return tex end
        end
        if item.getIcon then
            local icon = item:getIcon()
            local tex = resolveIcon(icon)
            if tex then return tex end
        end
        if item.getIconsForTexture then
            local okIcons, icons = pcall(item.getIconsForTexture, item)
            if okIcons then
                local tex = resolveIconList(icons)
                if tex then return tex end
            end
        end
    end
    return nil
end

function Client.getItemDisplayName(itemId)
    if not itemId or itemId == "" then return nil end
    if InventoryItemFactory and InventoryItemFactory.CreateItem then
        local ok, item = pcall(InventoryItemFactory.CreateItem, itemId)
        if ok and item and item.getDisplayName then
            local okName, name = pcall(item.getDisplayName, item)
            if okName and name and name ~= "" then return name end
        end
    end
    local sm = getScriptManager()
    if sm and sm.FindItem then
        local scriptItem = sm:FindItem(itemId)
        if scriptItem then
            if scriptItem.getDisplayName then
                local okName, name = pcall(scriptItem.getDisplayName, scriptItem)
                if okName and name and name ~= "" then return name end
            end
            if scriptItem.getName then
                local okName, name = pcall(scriptItem.getName, scriptItem)
                if okName and name and name ~= "" then return name end
            end
        end
    end
    return nil
end

function Client.getRewardLabel(choice)
    local entry = choice and (choice.entry or choice) or {}
    local rewardType = tostring(entry.type or "item")
    if rewardType == "currency" then
        local name = T("UI_rogue_reward_currency")
        if name == "UI_rogue_reward_currency" then
            name = "Currency"
        end
        return string.format("%s +%s", name, tostring(entry.amount or entry.qty or 0))
    elseif rewardType == "item" or rewardType == "armor" or rewardType == "drug" or rewardType == "heal" then
        local name = Client.getItemDisplayName(entry.id) or tostring(entry.id or "Item")
        local qty = tonumber(entry.qty or entry.amount or 1) or 1
        if qty > 1 then
            return string.format("%s x%d", name, qty)
        end
        return name
    elseif rewardType == "skill" then
        local perkId = entry.skill or entry.id
        local label = Client.getPerkLabel(perkId) or tostring(perkId or "Skill")
        return string.format("%s +%d", label, tonumber(entry.levels or 1) or 1)
    elseif rewardType == "skills" then
        local list = entry.skills
        if type(list) == "table" and #list > 0 then
            local parts = {}
            for i = 1, #list do
                local s = list[i]
                local perkId = s and (s.skill or s.id) or nil
                local levels = tonumber(s and s.levels or 0) or 0
                if perkId and levels > 0 then
                    local label = Client.getPerkLabel(perkId) or tostring(perkId or "Skill")
                    parts[#parts + 1] = string.format("%s +%d", label, levels)
                end
            end
            if #parts > 0 then
                return table.concat(parts, ", ")
            end
        end
        return "Skills"
    elseif rewardType == "xpBoost" then
        local perkId = entry.skill or entry.id
        local label = Client.getPerkLabel(perkId) or tostring(perkId or "Skill")
        local mult = tonumber(entry.amount or entry.mult or 0) or 0
        local rounds = tonumber(entry.durationRounds or 0) or 0
        if rounds > 0 then
            return string.format("%s XP x%.2f (%dr)", label, mult, rounds)
        end
        return string.format("%s XP x%.2f", label, mult)
    elseif rewardType == "trait" then
        local traitId = entry.id
        local label = Client.getTraitLabel(traitId)
        return label or tostring(traitId or "Trait")
    elseif rewardType == "blessing" then
        return tostring(entry.id or "Blessing")
    end
    return tostring(entry.id or rewardType)
end

function Client.getRewardTypeLabel(choice)
    local entry = choice and (choice.entry or choice) or {}
    local rewardType = tostring(entry.type or "item")
    local map = {
        currency = "UI_rogue_reward_type_currency",
        item = "UI_rogue_reward_type_item",
        armor = "UI_rogue_reward_type_item",
        drug = "UI_rogue_reward_type_drug",
        heal = "UI_rogue_reward_type_heal",
        skill = "UI_rogue_reward_type_skill",
        skills = "UI_rogue_reward_type_skills",
        xpBoost = "UI_rogue_reward_type_xpboost",
        trait = "UI_rogue_reward_type_trait",
        blessing = "UI_rogue_reward_type_blessing",
    }
    local key = map[rewardType] or "UI_rogue_reward_type_item"
    local label = T(key)
    if label == key then
        return string.upper(rewardType)
    end
    return label
end

local function setOptionIcon(option, texturePath)
    if not option or not texturePath then return end
    local tex = getTexture(texturePath)
    if tex then
        option.iconTexture = tex
    end
end

local function getScriptItem(itemId)
    if not itemId or itemId == "" then return nil end
    local sm = getScriptManager and getScriptManager() or nil
    if sm and sm.FindItem then
        local ok, item = pcall(sm.FindItem, sm, itemId)
        if ok then return item end
    end
    return nil
end

local function resolveWeaponSkillId(itemId)
    local scriptItem = getScriptItem(itemId)
    if not scriptItem or not scriptItem.getWeaponSkill then return nil end
    local okSkill, perk = pcall(scriptItem.getWeaponSkill, scriptItem)
    if not okSkill or not perk then return nil end
    if type(perk) == "string" then
        return perk
    end
    if perk.getId then
        local okId, id = pcall(perk.getId, perk)
        if okId and id then return tostring(id) end
    end
    if perk.getName then
        local okName, name = pcall(perk.getName, perk)
        if okName and name then return tostring(name) end
    end
    return nil
end

function Client.getRewardTypeCategory(choice)
    local entry = choice and (choice.entry or choice) or {}
    local rewardType = tostring(entry.type or "item")
    if rewardType == "currency" or rewardType == "drug" or rewardType == "heal"
        or rewardType == "skill" or rewardType == "skills" or rewardType == "xpBoost"
        or rewardType == "trait" or rewardType == "blessing" or rewardType == "armor" then
        return rewardType
    end
    if rewardType ~= "item" then
        return "misc"
    end

    local itemId = entry.id
    local scriptItem = getScriptItem(itemId)
    if scriptItem then
        if scriptItem.getBodyLocation then
            local okLoc, loc = pcall(scriptItem.getBodyLocation, scriptItem)
            if okLoc and loc and tostring(loc) ~= "" then
                return "armor"
            end
        end
        if scriptItem.getAmmoType then
            local okAmmo, ammo = pcall(scriptItem.getAmmoType, scriptItem)
            if okAmmo and ammo and tostring(ammo) ~= "" then
                return "ammo"
            end
        end
        if scriptItem.isRanged then
            local okRange, ranged = pcall(scriptItem.isRanged, scriptItem)
            if okRange and ranged == true then
                return "firearm"
            end
        end
    end

    local skillId = resolveWeaponSkillId(itemId)
    if skillId then
        local map = {
            LongBlade = "weapon_longblade",
            Blunt = "weapon_blunt",
            SmallBlade = "weapon_smallblade",
            SmallBlunt = "weapon_smallblunt",
            Axe = "weapon_axe",
            Spear = "weapon_spear",
            Aiming = "firearm",
        }
        return map[skillId] or "misc"
    end
    return "misc"
end

function Client.getRewardRarityIconTexture(rarity)
    local cfg = Rogue.Config or {}
    local map = cfg.REWARD_RARITY_ICON_TEX or {}
    local path = map[rarity]
    if not path then return nil end
    return getTexture(path)
end

function Client.getRewardTypeIconTexture(choice)
    local cfg = Rogue.Config or {}
    local map = cfg.REWARD_TYPE_ICON_TEX or {}
    local key = Client.getRewardTypeCategory(choice)
    local path = map[key]
    if not path then return nil end
    return getTexture(path)
end

function Client.getRewardLines(choice)
    local entry = choice and (choice.entry or choice) or {}
    local rewardType = tostring(entry.type or "item")
    if rewardType == "currency" then
        local name = T("UI_rogue_reward_currency")
        if name == "UI_rogue_reward_currency" then
            name = "Currency"
        end
        local amt = tostring(entry.amount or entry.qty or 0)
        return name, string.format("+%s", amt)
    elseif rewardType == "item" or rewardType == "armor" or rewardType == "drug" or rewardType == "heal" then
        local name = Client.getItemDisplayName(entry.id) or tostring(entry.id or "Item")
        local qty = tonumber(entry.qty or entry.amount or 1) or 1
        local qtyFmt = T("UI_rogue_reward_qty_fmt", qty)
        if qtyFmt == "UI_rogue_reward_qty_fmt" then
            qtyFmt = string.format("x%d", qty)
        end
        return name, qtyFmt
    elseif rewardType == "skill" then
        local perkId = entry.skill or entry.id
        local label = Client.getPerkLabel(perkId) or tostring(perkId or "Skill")
        local lv = tonumber(entry.levels or 1) or 1
        local lvFmt = T("UI_rogue_reward_levels_fmt", lv)
        if lvFmt == "UI_rogue_reward_levels_fmt" then
            lvFmt = string.format("+%d", lv)
        end
        return label, lvFmt
    elseif rewardType == "skills" then
        local list = entry.skills
        if type(list) == "table" and #list > 0 then
            local parts = {}
            for i = 1, #list do
                local s = list[i]
                local perkId = s and (s.skill or s.id) or nil
                local levels = tonumber(s and s.levels or 0) or 0
                if perkId and levels > 0 then
                    local label = Client.getPerkLabel(perkId) or tostring(perkId or "Skill")
                    parts[#parts + 1] = string.format("%s +%d", label, levels)
                end
            end
            if #parts > 0 then
                local name = T("UI_rogue_reward_skills")
                if name == "UI_rogue_reward_skills" then
                    name = "Skills"
                end
                return name, table.concat(parts, ", ")
            end
        end
        return "Skills", nil
    elseif rewardType == "xpBoost" then
        local perkId = entry.skill or entry.id
        local label = Client.getPerkLabel(perkId) or tostring(perkId or "Skill")
        local mult = tonumber(entry.amount or entry.mult or 0) or 0
        local rounds = tonumber(entry.durationRounds or 0) or 0
        if rounds > 0 then
            local fmt = T("UI_rogue_reward_xpboost_fmt", mult, rounds)
            if fmt == "UI_rogue_reward_xpboost_fmt" then
                fmt = string.format("EXP x%.2f per %dr", mult, rounds)
            end
            return label, fmt
        end
        return label, string.format("x%.2f", mult)
    elseif rewardType == "trait" then
        local traitId = entry.id
        local label = Client.getTraitLabel(traitId) or tostring(traitId or "Trait")
        local toggle = T("UI_rogue_reward_trait_toggle")
        if toggle == "UI_rogue_reward_trait_toggle" then
            toggle = "Toggle"
        end
        return label, toggle
    elseif rewardType == "blessing" then
        return tostring(entry.id or "Blessing"), nil
    end
    return tostring(entry.id or rewardType), nil
end

function Client.getRewardDesc(choice)
    local entry = choice and (choice.entry or choice) or {}
    local desc = entry.desc or entry.short or ""
    if not desc or desc == "" then return nil end
    return tostring(desc)
end

function Client.getTraitIconPath(traitId)
    if not traitId then return nil end
    if Rogue.Config and Rogue.Config.TRAIT_ICON_MAP and Rogue.Config.TRAIT_ICON_MAP[traitId] then
        return Rogue.Config.TRAIT_ICON_MAP[traitId]
    end
    local id = tostring(traitId)
    local name = id:gsub("^base:", "")
    local lower = name:lower()
    local candidate = "media/textures/ui/Trait_" .. lower .. ".png"
    if getTexture(candidate) then return candidate end
    candidate = "media/textures/ui/Trait_" .. name .. ".png"
    if getTexture(candidate) then return candidate end
    return nil
end

function Client.getSkillIconPath(skillId)
    if not skillId then return nil end
    if Rogue.Config and Rogue.Config.SKILL_ICON_MAP and Rogue.Config.SKILL_ICON_MAP[skillId] then
        return Rogue.Config.SKILL_ICON_MAP[skillId]
    end
    local name = tostring(skillId)
    local lower = name:lower()
    local candidate = "media/textures/ui/skills/" .. lower .. ".png"
    if getTexture(candidate) then return candidate end
    candidate = "media/textures/ui/skills/" .. name .. ".png"
    if getTexture(candidate) then return candidate end
    return nil
end

function Client.getRewardIcon(choice)
    local entry = choice and (choice.entry or choice) or {}
    local rewardType = tostring(entry.type or "item")
    if entry.customIcon and entry.customIcon ~= "" then
        return getTexture(entry.customIcon)
    end
    if entry.iconItem and entry.iconItem ~= "" then
        return Client.getItemIconTexture(entry.iconItem)
    end
    if rewardType == "skill" or rewardType == "skills" or rewardType == "xpBoost" then
        local perkId = entry.skill or entry.id
        if rewardType == "skills" then
            local list = entry.skills
            if type(list) == "table" and #list > 0 then
                local s = list[1]
                perkId = s and (s.skill or s.id) or perkId
            end
        end
        local path = Client.getSkillIconPath(perkId)
        if path and path ~= "" then
            local tex = getTexture(path)
            if tex then return tex end
        end
    elseif rewardType == "trait" or rewardType == "blessing" then
        local perkId = entry.id
        local path = Client.getTraitIconPath(perkId) or Client.getSkillIconPath(perkId)
        if path and path ~= "" then
            local tex = getTexture(path)
            if tex then return tex end
        end
    end
    if rewardType == "item" or rewardType == "armor" or rewardType == "drug" or rewardType == "heal" then
        if entry.id then
            return Client.getItemIconTexture(entry.id)
        end
    elseif rewardType == "currency" then
        if Rogue.Config and Rogue.Config.UI_WALLET_ICON_TEX then
            local tex = getTexture(Rogue.Config.UI_WALLET_ICON_TEX)
            if tex then return tex end
        end
        if Rogue.Config and Rogue.Config.WALLET_ICON_ITEM then
            return Client.getItemIconTexture(Rogue.Config.WALLET_ICON_ITEM)
        end
    else
        if Rogue.Config and Rogue.Config.SHOP_CATEGORY_ICON_ITEM and Rogue.Config.SHOP_CATEGORY_ICON_ITEM.perks then
            return Client.getItemIconTexture(Rogue.Config.SHOP_CATEGORY_ICON_ITEM.perks)
        end
    end
    return nil
end

function Client.openRewardPanel(args)
    if Client._rewardPanel then
        Client._rewardPanel:setVisible(false)
        Client._rewardPanel:removeFromUIManager()
        Client._rewardPanel = nil
    end
    if not args or not args.choices then return end
    Client._rewardChoices = args.choices
    Client._rewardRoundId = args.roundId
    Client._rewardRunId = args.runId
    Client._rewardRerollCost = tonumber(args.rerollCost or 0) or 0
    Client._rewardRerollCount = tonumber(args.rerollCount or 0) or 0

    local w, h = 720, 310
    local x = (getCore():getScreenWidth() / 2) - (w / 2)
    local y = (getCore():getScreenHeight() / 2) - (h / 2)
    local panel = ISPanel:new(x, y, w, h)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    panel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }

    local tm = getTextManager()
    local textColor = Client.getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
    local buttonShadowColor = { r = 0, g = 0, b = 0, a = 1 }
    local function measureText(font, text)
        if tm and tm.MeasureStringX then
            return tm:MeasureStringX(font, text)
        end
        return 0
    end
    local function addCenteredShadowText(parent, centerX, y, h, text, font, mainColor, shadowColor)
        local width = measureText(font, text)
        local x = centerX - (width / 2)
        if width <= 0 then
            x = centerX - 40
        end
        return Client.addShadowLabel(parent, x, y, h, text, font, mainColor, shadowColor, 1, 1)
    end
    local function styleRewardButton(btn, label)
        if not btn then return end
        btn.title = ""
        btn._rogueLabel = label
        local safeText = textColor or { r = 0.95, g = 0.83, b = 0.15, a = 1 }
        btn.textColor = safeText
        btn.textColor2 = safeText
        function btn:render()
            ISButton.render(self)
            if not self._rogueLabel and not self._rogueLabelLeft then return end
            if self._rogueBgTex then
                self:drawTextureScaled(self._rogueBgTex, 0, 0, self.width, self.height, 1)
            end
            local font = self.font or UIFont.Small
            local tc = textColor or { r = 0.95, g = 0.83, b = 0.15, a = 1 }
            local sc = buttonShadowColor or { r = 0, g = 0, b = 0, a = 1 }
            local tr = (tc and tc.r) or 0.95
            local tg = (tc and tc.g) or 0.83
            local tb = (tc and tc.b) or 0.15
            local ta = (tc and tc.a) or 1
            local sr = (sc and sc.r) or 0
            local sg = (sc and sc.g) or 0
            local sb = (sc and sc.b) or 0
            local sa = (sc and sc.a) or 1
            local h = tm and tm:getFontHeight(font) or 12
            local padBottom = tonumber(self._roguePadBottom or 0) or 0
            local gap = 6
            if self._rogueLabelLeft and self._rogueLabelRight and self._rogueIconTex then
                local wl = tm and tm:MeasureStringX(font, self._rogueLabelLeft) or 0
                local wr = tm and tm:MeasureStringX(font, self._rogueLabelRight) or 0
                local iw = self._rogueIconSize or 16
                local total = wl + gap + iw + gap + wr
                local x = math.floor((self.width - total) / 2)
                local y = math.floor((self.height - h - padBottom) / 2)
                self:drawText(self._rogueLabelLeft, x + 1, y + 1, sr, sg, sb, sa)
                self:drawText(self._rogueLabelLeft, x, y, tr, tg, tb, ta)
                local ix = x + wl + gap
                local iy = math.floor((self.height - iw) / 2)
                self:drawTextureScaled(self._rogueIconTex, ix, iy, iw, iw, 1)
                local rx = ix + iw + gap
                self:drawText(self._rogueLabelRight, rx + 1, y + 1, sr, sg, sb, sa)
                self:drawText(self._rogueLabelRight, rx, y, tr, tg, tb, ta)
            else
                local w = tm and tm:MeasureStringX(font, self._rogueLabel) or 0
                local x = math.floor((self.width - w) / 2)
                local y = math.floor((self.height - h - padBottom) / 2)
                self:drawText(self._rogueLabel, x + 1, y + 1, sr, sg, sb, sa)
                self:drawText(self._rogueLabel, x, y, tr, tg, tb, ta)
            end
        end
    end

    local titleText = T("UI_rogue_reward_title")
    addCenteredShadowText(
        panel,
        w / 2,
        8 + Client.UI_PAD_Y,
        20,
        titleText,
        Client.getUIFont("large"),
        textColor,
        { r = 0, g = 0, b = 0, a = 1 }
    )

    local padding = 12
    local slotY = 44 + 10
    local rerollRowH = 20
    local rerollRowY = h - rerollRowH - 10
    local slotH = math.max(60, rerollRowY - slotY - 6)
    local slotW = math.floor((w - padding * 4) / 3)
    for i = 1, #args.choices do
        local choice = args.choices[i]
        local rarity = tostring(choice.rarity or "common")
        local slotX = padding + (i - 1) * (slotW + padding)
        local slot = ISPanel:new(slotX, slotY, slotW, slotH)
        slot:initialise()
        slot:instantiate()
        slot.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
        slot.borderColor = { r = 0, g = 0, b = 0, a = 0 }
        panel:addChild(slot)
        local texPath = Rogue.Config and Rogue.Config.REWARD_PANEL_TEX and Rogue.Config.REWARD_PANEL_TEX[rarity] or nil
        Client.addPanelBackground(slot, texPath, 0.95)

        local shadowColor = { r = 0, g = 0, b = 0, a = 1 }
        if rarity == "epic" or rarity == "legendary" then
            shadowColor = { r = 0.85, g = 0.1, b = 0.1, a = 1 }
        end
        local iconSize = 24
        local iconInset = 25
        local rarityTex = Client.getRewardRarityIconTexture(rarity)
        if rarityTex then
            local img = ISImage:new(6 + iconInset, 26, iconSize, iconSize, rarityTex)
            img:initialise()
            slot:addChild(img)
        else
            addCenteredShadowText(
                slot,
                slotW / 2,
                24,
                18,
                string.upper(rarity),
                Client.getUIFont("small"),
                textColor,
                shadowColor
            )
        end

        local typeTex = Client.getRewardTypeIconTexture(choice)
        if typeTex then
            local img = ISImage:new(slotW - iconSize - 6 - iconInset, 26, iconSize, iconSize, typeTex)
            img:initialise()
            slot:addChild(img)
        else
            local typeLabel = Client.getRewardTypeLabel(choice)
            addCenteredShadowText(
                slot,
                slotW / 2,
                42,
                16,
                typeLabel,
                Client.getUIFont("small"),
                textColor,
                shadowColor
            )
        end

        local icon = Client.getRewardIcon(choice)
        if icon then
            local iconBoxW, iconBoxH = 64, 64
            local texW = icon.getWidth and icon:getWidth() or iconBoxW
            local texH = icon.getHeight and icon:getHeight() or iconBoxH
            local iconW = math.min(iconBoxW, texW)
            local iconH = math.min(iconBoxH, texH)
            local iconX = math.floor((slotW - iconW) / 2)
            local iconY = 60 + math.floor((iconBoxH - iconH) / 2)
            local img = ISImage:new(iconX, iconY, iconW, iconH, icon)
            img:initialise()
            slot:addChild(img)
        end

        local nameText, valueText = Client.getRewardLines(choice)
        if nameText and nameText ~= "" then
            addCenteredShadowText(
                slot,
                slotW / 2,
                136,
                18,
                nameText,
                Client.getUIFont("medium"),
                textColor,
                shadowColor
            )
        end
        if valueText and valueText ~= "" then
            addCenteredShadowText(
                slot,
                slotW / 2,
                156,
                18,
                valueText,
                Client.getUIFont("small"),
                textColor,
                shadowColor
            )
        end

        local short = Client.getRewardDesc(choice)
        if short and short ~= "" then
            addCenteredShadowText(
                slot,
                slotW / 2,
                176,
                18,
                short,
                Client.getUIFont("small"),
                textColor,
                shadowColor
            )
        end

        local function pick()
            sendClientCommand("Rogue", "roundRewardPick", {
                roundId = Client._rewardRoundId,
                runId = Client._rewardRunId,
                pickIndex = i,
            })
            if panel then
                panel:setVisible(false)
                panel:removeFromUIManager()
            end
            Client._rewardPanel = nil
        end
        local baseBtnY = slotH - 40
        if rarity == "legendary" then
            baseBtnY = baseBtnY - 8
        end
        local btn = ISButton:new(10, baseBtnY, slotW - 20, 28, T("UI_rogue_reward_pick"), slot, pick)
        btn:initialise()
        btn.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
        btn.borderColor = { r = 0, g = 0, b = 0, a = 0 }
        if btn.setDisplayBackground then
            pcall(btn.setDisplayBackground, btn, false)
        end
        if btn.setDisplayBorder then
            pcall(btn.setDisplayBorder, btn, false)
        end
        if rarity == "legendary" then
            btn._roguePadBottom = 15
        end
        styleRewardButton(btn, T("UI_rogue_reward_pick"))
        slot:addChild(btn)
    end

    local rerollCost = Client._rewardRerollCost or 0
    if rerollCost ~= nil and rerollCost >= 0 then
        local labelLeft = "RITENTA"
        local labelRight = tostring(rerollCost)
        for i = 1, #args.choices do
            local slotX = padding + (i - 1) * (slotW + padding)
            local wl = tm and tm:MeasureStringX(UIFont.Small, labelLeft) or 0
            local wr = tm and tm:MeasureStringX(UIFont.Small, labelRight) or 0
            local iw = 16
            local gap = 6
            local btnW = math.min(slotW, wl + gap + iw + gap + wr + 20)
            local btnX = slotX + math.floor((slotW - btnW) / 2)
            local function reroll()
                sendClientCommand("Rogue", "roundRewardReroll", {
                    roundId = Client._rewardRoundId,
                    runId = Client._rewardRunId,
                    pickIndex = i,
                })
            end
            local btn = ISButton:new(btnX, rerollRowY, btnW, rerollRowH, "", panel, reroll)
            btn:initialise()
            btn.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
            btn.borderColor = { r = 0, g = 0, b = 0, a = 0 }
            if btn.setDisplayBackground then
                pcall(btn.setDisplayBackground, btn, false)
            end
            if btn.setDisplayBorder then
                pcall(btn.setDisplayBorder, btn, false)
            end
            btn._rogueLabelLeft = labelLeft
            btn._rogueLabelRight = labelRight
            btn._rogueIconTex = getTexture("media/textures/ui/wallet_icon.png")
            btn._rogueIconSize = 16
            btn._rogueBgTex = getTexture("media/textures/ui/rogue_reroll_bg.png")
            styleRewardButton(btn, labelLeft)
            panel:addChild(btn)
        end
    end

    Client._rewardPanel = panel
end

function Client.pickSoundId(list)
    if not list then return nil end
    if type(list) == "string" then return list end
    if type(list) ~= "table" then return nil end
    local count = #list
    if count < 1 then return nil end
    local idx = ZombRand(count) + 1
    return list[idx]
end

Client._soundRefs = Client._soundRefs or {}
Client._bogdanoLocalUntilMs = Client._bogdanoLocalUntilMs or nil
Client._invRefreshAtMs = Client._invRefreshAtMs or nil
Client._invRefreshReason = Client._invRefreshReason or nil
Client._invRefreshLeft = Client._invRefreshLeft or nil
Client._invRefreshIntervalMs = Client._invRefreshIntervalMs or nil

function Client.queueInventoryRefresh(reason, delayMs, tries, intervalMs)
    local now = getTimestampMs()
    local delay = tonumber(delayMs) or 250
    Client._invRefreshAtMs = now + math.max(0, delay)
    Client._invRefreshReason = reason
    Client._invRefreshLeft = tonumber(tries) or 1
    Client._invRefreshIntervalMs = tonumber(intervalMs) or 250
end

function Client.refreshInventoryUI()
    local pdata = getPlayerData and getPlayerData(0) or nil
    if pdata then
        if pdata.playerInventory and pdata.playerInventory.refreshBackpacks then
            pdata.playerInventory:refreshBackpacks()
            if pdata.playerInventory.inventoryPane and pdata.playerInventory.inventoryPane.refreshContainer then
                pdata.playerInventory.inventoryPane:refreshContainer()
            end
        end
        if pdata.lootInventory and pdata.lootInventory.refreshBackpacks then
            pdata.lootInventory:refreshBackpacks()
            if pdata.lootInventory.inventoryPane and pdata.lootInventory.inventoryPane.refreshContainer then
                pdata.lootInventory.inventoryPane:refreshContainer()
            end
        end
    end
    if getPlayerInventory then
        local inv = getPlayerInventory(0)
        if inv and inv.refreshBackpacks then
            inv:refreshBackpacks()
            if inv.inventoryPane and inv.inventoryPane.refreshContainer then
                inv.inventoryPane:refreshContainer()
            end
        end
    end
    if getPlayerLoot then
        local loot = getPlayerLoot(0)
        if loot and loot.refreshBackpacks then
            loot:refreshBackpacks()
            if loot.inventoryPane and loot.inventoryPane.refreshContainer then
                loot.inventoryPane:refreshContainer()
            end
        end
    end
end

function Client.playUISound(eventId, category)
    if not eventId then return end
    local sm = getSoundManager and getSoundManager() or nil
    local cfg = Rogue.Config or {}
    if not sm or not sm.playUISound then
        return
    end
    local byCat = cfg.SOUNDS_BY_CATEGORY or {}
    local catEntry = category and byCat[category] or nil
    local list = catEntry and catEntry[eventId] or (cfg.SOUNDS and cfg.SOUNDS[eventId]) or nil
    local soundId = Client.pickSoundId(list)
    if soundId and soundId ~= "" then
        local follow = cfg.SOUNDS_FOLLOW_PLAYER and cfg.SOUNDS_FOLLOW_PLAYER[eventId]
        if follow then
            local player = getPlayer()
            if player and player.playSoundLocal then
                local ok, ref = pcall(player.playSoundLocal, player, soundId)
                if ok and ref then
                    Client._soundRefs[eventId] = { ref = ref, follow = true }
                end
                return soundId
            elseif player and player.playSound then
                local ok, ref = pcall(player.playSound, player, soundId)
                if ok and ref then
                    Client._soundRefs[eventId] = { ref = ref, follow = true }
                end
                return soundId
            end
        end
        local ok, ref = pcall(sm.playUISound, sm, soundId)
        if ok and ref then
            Client._soundRefs[eventId] = { soundId = soundId, ref = ref, follow = false }
        else
            Client._soundRefs[eventId] = { soundId = soundId, follow = false }
        end
    end
    return soundId
end

function Client.stopUISound(eventId)
    if not eventId then return end
    local entry = Client._soundRefs and Client._soundRefs[eventId] or nil
    if not entry then return end
    if entry.follow then
        local player = getPlayer()
        if player and player.getEmitter and entry.ref then
            local emitter = player:getEmitter()
            if emitter and emitter.stopSound then
                pcall(emitter.stopSound, emitter, entry.ref)
            end
        end
    else
        local sm = getSoundManager and getSoundManager() or nil
        if sm and sm.stopUISound then
            if entry.ref then
                pcall(sm.stopUISound, sm, entry.ref)
            elseif entry.soundId and type(entry.soundId) == "number" then
                pcall(sm.stopUISound, sm, entry.soundId)
            end
        end
    end
    Client._soundRefs[eventId] = nil
end

function Client.applyIconScale(img, w, h)
    if not img then return end
    img.scaledWidth = w
    img.scaledHeight = h
    img.noAspect = true
end

function Client.addShadowLabel(panel, x, y, h, text, font, mainColor, shadowColor, offsetX, offsetY)
    if not panel then return nil end
    local ox = offsetX or 1
    local oy = offsetY or 1
    local shadow = ISLabel:new(x + ox, y + oy, h, text, shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a, font, true)
    shadow:initialise()
    panel:addChild(shadow)
    local label = ISLabel:new(x, y, h, text, mainColor.r, mainColor.g, mainColor.b, mainColor.a, font, true)
    label:initialise()
    panel:addChild(label)
    return { label = label, shadow = shadow }
end

function Client.setShadowLabelText(entry, text)
    if not entry then return end
    if entry.label and entry.label.setName then
        entry.label:setName(text)
    end
    if entry.shadow and entry.shadow.setName then
        entry.shadow:setName(text)
    end
end

function Client.setShadowLabelVisible(entry, visible)
    if not entry then return end
    local show = visible and true or false
    if entry.label and entry.label.setVisible then
        entry.label:setVisible(show)
    end
    if entry.shadow and entry.shadow.setVisible then
        entry.shadow:setVisible(show)
    end
end

local function clampValue(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function Client.getArenaBounds()
    local cfg = Rogue.Config
    if not cfg or not cfg.ZONES or not cfg.isRectValid then return nil end
    if not cfg.isRectValid(cfg.ZONES.ARENA) then return nil end
    local rect = cfg.ZONES.ARENA
    return { x1 = rect.x1, y1 = rect.y1, x2 = rect.x2, y2 = rect.y2 }
end

function Client.getArenaRect()
    local cfg = Rogue.Config
    if not cfg or not cfg.ZONES or not cfg.isRectValid then return nil end
    if not cfg.isRectValid(cfg.ZONES.ARENA) then return nil end
    return cfg.ZONES.ARENA
end

function Client.findLastZombieInArena()
    local rect = Client.getArenaRect()
    if not rect then return nil end
    local cell = getCell()
    if not cell or not cell.getZombieList then return nil end
    local list = cell:getZombieList()
    if not list then return nil end
    local player = getPlayer()
    local px = player and player.getX and player:getX() or nil
    local py = player and player.getY and player:getY() or nil
    local pz = player and player.getZ and player:getZ() or nil
    local count = 0
    local nearest = nil
    local nearestDist = nil
    local rz = rect.z or 0
    for i = 0, list:size() - 1 do
        local z = list:get(i)
        if z and not z:isDead() then
            local zx, zy, zz = z:getX(), z:getY(), z:getZ()
            if zz == rz and zx >= rect.x1 and zx <= rect.x2 and zy >= rect.y1 and zy <= rect.y2 then
                count = count + 1
                if px and py and pz and pz == rz then
                    local dx = zx - px
                    local dy = zy - py
                    local dist = (dx * dx) + (dy * dy)
                    if not nearestDist or dist < nearestDist then
                        nearestDist = dist
                        nearest = z
                    end
                elseif not nearest then
                    nearest = z
                end
            end
        end
    end
    return count, nearest
end

function Client.updateLastZombieMinimap()
    local now = getTimestampMs()
    if now < (Client._lastZombieScanNextAtMs or 0) then return end
    local cfg = Rogue.Config or {}
    local interval = tonumber(cfg.MINIMAP_LAST_ZOMBIE_INTERVAL_MS) or 1000
    Client._lastZombieScanNextAtMs = now + math.max(200, interval)
    if Client._lastStatus ~= "WAVE" then
        Client._lastZombieMarker = nil
        Client._lastZombieCount = nil
        return
    end
    local threshold = tonumber(cfg.MINIMAP_LAST_ZOMBIE_THRESHOLD) or 10
    local count, nearest = Client.findLastZombieInArena()
    if not count or count > threshold or not nearest then
        Client._lastZombieMarker = nil
        Client._lastZombieCount = nil
        return
    end
    Client._lastZombieMarker = { x = nearest:getX(), y = nearest:getY(), z = nearest:getZ() }
    Client._lastZombieCount = count
end

function Client.drawArenaMinimapOverlay(mm)
    if not mm or not mm.inner then return end
    local map = mm.inner
    local api = map.mapAPI
    if not api then return end
    local bounds = Client.getArenaBounds()
    if not bounds then return end
    local x1 = api:worldToUIX(bounds.x1, bounds.y1)
    local y1 = api:worldToUIY(bounds.x1, bounds.y1)
    local x2 = api:worldToUIX(bounds.x2, bounds.y1)
    local y2 = api:worldToUIY(bounds.x2, bounds.y1)
    local x3 = api:worldToUIX(bounds.x2, bounds.y2)
    local y3 = api:worldToUIY(bounds.x2, bounds.y2)
    local x4 = api:worldToUIX(bounds.x1, bounds.y2)
    local y4 = api:worldToUIY(bounds.x1, bounds.y2)
    if map.setStencilRect then
        map:setStencilRect(0, 0, map.width, map.height)
    end
    if map.javaObject and map.javaObject.DrawLine then
        local r, g, b, a = 0.6, 0, 0, 1
        map.javaObject:DrawLine(nil, x1, y1, x2, y2, 1, r, g, b, a)
        map.javaObject:DrawLine(nil, x2, y2, x3, y3, 1, r, g, b, a)
        map.javaObject:DrawLine(nil, x3, y3, x4, y4, 1, r, g, b, a)
        map.javaObject:DrawLine(nil, x4, y4, x1, y1, 1, r, g, b, a)
    end
    local marker = Client._lastZombieMarker
    if marker then
        local mx = api:worldToUIX(marker.x, marker.y)
        local my = api:worldToUIY(marker.x, marker.y)
        if map.drawRect then
            map:drawRect(mx - 2, my - 2, 4, 4, 1, 1, 0.1, 0.1)
        elseif map.javaObject and map.javaObject.DrawRect then
            map.javaObject:DrawRect(nil, mx - 2, my - 2, 4, 4, 1, 1, 0.1, 0.1)
        end
    end
    if map.clearStencilRect then
        map:clearStencilRect()
    end
end

function Client.clearArenaBorderMarkers()
    if not WorldMarkers or not WorldMarkers.instance then return end
    local wm = WorldMarkers.instance
    for i = 1, #Client._arenaBorderMarkers do
        local marker = Client._arenaBorderMarkers[i]
        if marker then
            pcall(wm.removeGridSquareMarker, wm, marker)
        end
    end
    Client._arenaBorderMarkers = {}
    Client._arenaBorderMarkerSide = nil
    Client._arenaBorderMarkerCenter = nil
end

function Client.createArenaBorderMarkers(rect, side, centerX, centerY)
    if not WorldMarkers or not WorldMarkers.instance then return end
    local wm = WorldMarkers.instance
    Client._arenaBorderMarkers = {}
    Client._arenaBorderMarkerSide = side
    Client._arenaBorderMarkerCenter = { x = centerX, y = centerY }

    local cfg = Rogue.Config or {}
    local count = tonumber(cfg.ARENA_BORDER_MARKER_COUNT) or Client.ARENA_BORDER_MARKER_COUNT or 8
    local spacing = tonumber(cfg.ARENA_BORDER_MARKER_SPACING) or Client.ARENA_BORDER_MARKER_SPACING or 1
    local spacingTiles = math.max(1, math.floor(spacing))
    local alpha = tonumber(cfg.ARENA_BORDER_MARKER_ALPHA) or Client.ARENA_BORDER_MARKER_ALPHA or 0.5
    local size = tonumber(cfg.ARENA_BORDER_MARKER_SIZE) or Client.ARENA_BORDER_MARKER_SIZE or Client.SHOP_MARKER_SIZE or 0.65
    local color = cfg.ARENA_BORDER_MARKER_COLOR or {}
    local r = tonumber(color.r) or 0.6
    local g = tonumber(color.g) or 0
    local b = tonumber(color.b) or 0

    local halfSpan = (count - 1) * spacingTiles * 0.5
    local used = {}
    for i = 0, count - 1 do
        local offset = -halfSpan + (i * spacingTiles)
        local x = centerX
        local y = centerY
        if side == "left" or side == "right" then
            y = centerY + offset
            y = clampValue(y, rect.y1, rect.y2)
            x = side == "left" and rect.x1 or rect.x2
        else
            x = centerX + offset
            x = clampValue(x, rect.x1, rect.x2)
            y = side == "top" and rect.y1 or rect.y2
        end
        local sx = math.floor(x + 0.5)
        local sy = math.floor(y + 0.5)
        local key = tostring(sx) .. "," .. tostring(sy)
        if used[key] then
            -- skip duplicates when spacing < 1 tile
        else
            used[key] = true
            local square = getCell():getGridSquare(sx, sy, rect.z or 0)
            if square then
                local marker = wm:addGridSquareMarker(square, r, g, b, true, size)
                if marker and marker.setAlpha then
                    pcall(marker.setAlpha, marker, alpha)
                end
                if marker then
                    table.insert(Client._arenaBorderMarkers, marker)
                end
            end
        end
    end
end

function Client.updateArenaBorderMarkers()
    local now = getTimestampMs()
    if now < (Client._arenaBorderMarkerNextAtMs or 0) then return end
    Client._arenaBorderMarkerNextAtMs = now + (Client.ARENA_BORDER_MARKER_TICK_MS or 500)

    local rect = Client.getArenaRect()
    local status = (Client._lastScore and Client._lastScore.status) or Client._lastStatus
    if not rect or not status or status == "IDLE" then
        if #Client._arenaBorderMarkers > 0 then
            Client.clearArenaBorderMarkers()
        end
        return
    end
    local player = getPlayer()
    if not player then return end

    local cfg = Rogue.Config or {}
    local threshold = tonumber(cfg.ARENA_BORDER_MARKER_DISTANCE) or Client.ARENA_BORDER_MARKER_DISTANCE or 12
    local px = player:getX()
    local py = player:getY()

    local inside = px >= rect.x1 and px <= rect.x2 and py >= rect.y1 and py <= rect.y2
    local near = false
    local side = nil
    local centerX, centerY = px, py

    if inside then
        local dLeft = px - rect.x1
        local dRight = rect.x2 - px
        local dTop = py - rect.y1
        local dBottom = rect.y2 - py
        local minDist = math.min(dLeft, dRight, dTop, dBottom)
        near = minDist <= threshold
        if near then
            if minDist == dLeft then
                side = "left"
            elseif minDist == dRight then
                side = "right"
            elseif minDist == dTop then
                side = "top"
            else
                side = "bottom"
            end
        end
    else
        local nx = clampValue(px, rect.x1, rect.x2)
        local ny = clampValue(py, rect.y1, rect.y2)
        local dx = px - nx
        local dy = py - ny
        near = (math.sqrt(dx * dx + dy * dy) <= threshold)
        if near then
            if px < rect.x1 then
                side = "left"
            elseif px > rect.x2 then
                side = "right"
            elseif py < rect.y1 then
                side = "top"
            else
                side = "bottom"
            end
        end
    end

    if not near or not side then
        if #Client._arenaBorderMarkers > 0 then
            Client.clearArenaBorderMarkers()
        end
        return
    end

    centerX = clampValue(centerX, rect.x1, rect.x2)
    centerY = clampValue(centerY, rect.y1, rect.y2)
    local roundedCenterX = math.floor(centerX + 0.5)
    local roundedCenterY = math.floor(centerY + 0.5)

    local lastSide = Client._arenaBorderMarkerSide
    local lastCenter = Client._arenaBorderMarkerCenter
    if lastSide == side and lastCenter
        and lastCenter.x == roundedCenterX and lastCenter.y == roundedCenterY then
        return
    end

    Client.clearArenaBorderMarkers()
    Client.createArenaBorderMarkers(rect, side, roundedCenterX, roundedCenterY)
end

function Client.patchMiniMapOverlay()
    if Client._miniMapPatched then return end
    if not ISMiniMapOuter or not ISMiniMapOuter.render then return end
    Client._miniMapPatched = true
    local baseRender = ISMiniMapOuter.render
    ISMiniMapOuter.render = function(self)
        baseRender(self)
        Client.drawArenaMinimapOverlay(self)
    end
end

function Client.openMiniMapInLobby()
    if Client._miniMapOpenedForRun then return end
    local player = getPlayer()
    if not player then return end
    if not getPlayerMiniMap then return end
    local mm = getPlayerMiniMap(player:getPlayerNum())
    if not mm then return end
    if mm.isReallyVisible and mm:isReallyVisible() then
        Client._miniMapOpenedForRun = true
        return
    end
    if mm.addToUIManager then
        mm:addToUIManager()
    end
    Client._miniMapOpenedForRun = true
end

function Client.getBuildIconTexture(buildId, build)
    if build and build.iconItem then
        local tex = Client.getItemIconTexture(build.iconItem)
        if tex then return tex end
    end
    local icon = build and build.icon or nil
    if not icon or icon == "" then return nil end
    local tex = getTexture(icon)
    if tex then return tex end
    tex = getTexture("media/ui/" .. icon .. ".png")
    if tex then return tex end
    return nil
end

function Client.ensureBanner()
    if Client._banner and Client._banner.panel then
        return Client._banner
    end
    local w, h = 640, 70
    local x = (getCore():getScreenWidth() / 2) - (w / 2)
    local y = 60

    local panel = ISPanel:new(x, y, w, h)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    Client.enablePanelDrag(panel, "banner")
    if panel.setMovable then panel:setMovable(true) end
    if panel.setMoveWithMouse then panel:setMoveWithMouse(true) end
    panel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    panel:setVisible(false)
    Client.addPanelBackground(panel, Rogue.Config and Rogue.Config.UI_BANNER_BG_TEX or nil, 0.85)

    local textColor = Client.getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
    local shadowColor = { r = 0, g = 0, b = 0, a = 1 }
    local entry = Client.addShadowLabel(
        panel,
        12 + Client.UI_PAD_X,
        20 + (Client.BANNER_PAD_Y or 0),
        30,
        "",
        Client.getUIFont("large"),
        textColor,
        shadowColor,
        1,
        1
    )

    Client._banner = { panel = panel, label = entry, endTimeMs = 0 }
    return Client._banner
end

function Client.ensureHud()
    if Client._hud and Client._hud.panel then
        return Client._hud
    end
    local w, h = 420, 60
    local margin = 14
    local x = getCore():getScreenWidth() - w - margin
    local y = 36

    local panel = ISPanel:new(x, y, w, h)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    panel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    panel:setVisible(false)
    Client.addPanelBackground(panel, Rogue.Config and Rogue.Config.UI_HUD_BG_TEX or nil, 0.85)

    local textColor = Client.getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
    local shadowColor = { r = 0, g = 0, b = 0, a = 1 }
    local entry = Client.addShadowLabel(
        panel,
        8 + Client.UI_PAD_X,
        8 + Client.UI_PAD_Y - 20,
        20,
        "",
        Client.getUIFont("medium"),
        textColor,
        shadowColor,
        1,
        1
    )

    local readyLabel = Client.addShadowLabel(
        panel,
        8 + Client.UI_PAD_X,
        24 + Client.UI_PAD_Y - 20,
        16,
        "",
        Client.getUIFont("small"),
        textColor,
        shadowColor,
        1,
        1
    )
    local btnW, btnH = 90, 20
    local btnX = w - btnW - 10
    local btnY = 22 + Client.UI_PAD_Y - 20
    local btnReady = ISButton:new(btnX, btnY, btnW, btnH, T("UI_rogue_prep_ready"), panel, function()
        Client.togglePrepReady()
    end)
    btnReady:initialise()
    panel:addChild(btnReady)
    btnReady:setVisible(false)
    if readyLabel and readyLabel.label then
        readyLabel.label:setVisible(false)
    end
    if readyLabel and readyLabel.shadow then
        readyLabel.shadow:setVisible(false)
    end

    Client._hud = { panel = panel, label = entry, readyLabel = readyLabel, readyBtn = btnReady, text = "" }
    do
        local drag = ISPanel:new(0, 0, panel.width, 18)
        drag:initialise()
        drag.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
        drag.borderColor = { r = 0, g = 0, b = 0, a = 0 }
        panel:addChild(drag)
        if drag.bringToTop then
            drag:bringToTop()
        end
        Client.enablePanelDrag(panel, "hud", drag)
        panel._dragOverlay = drag
    end
    return Client._hud
end

function Client.ensureScorePanel()
    if Client._score and Client._score.panel then
        return Client._score
    end
    local w, h = 240, 260 + (Client.SCORE_EXTRA_BOTTOM or 0)
    local margin = 14
    local x = getCore():getScreenWidth() - w - margin
    local y = 100

    local panel = ISPanel:new(x, y, w, h)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    panel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    panel:setVisible(false)
    Client.addPanelBackground(panel, Rogue.Config and Rogue.Config.UI_SCORE_BG_TEX or nil, 0.75)

    local labels = {}
    local values = {}
    local lines = {
        { label = T("UI_rogue_score_wave_kills") },
        { label = T("UI_rogue_score_wave_damage") },
        { label = T("UI_rogue_score_run_kills") },
        { label = T("UI_rogue_score_run_deaths") },
        { label = T("UI_rogue_score_run_damage") },
        { label = T("UI_rogue_score_run_currency") },
        { label = T("UI_rogue_score_waves_streak") },
        { label = T("UI_rogue_score_alltime_kills") },
        { label = T("UI_rogue_score_alltime_deaths") },
        { label = T("UI_rogue_score_alltime_damage") },
        { label = T("UI_rogue_top5"), isHeader = true },
        { label = "1)" },
        { label = "2)" },
        { label = "3)" },
        { label = "4)" },
        { label = "5)" },
    }
    local labelColor = Client.getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
    local labelShadow = { r = 0, g = 0, b = 0, a = 1 }
    local valueColor = Client.getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
    local valueShadow = { r = 0.85, g = 0.1, b = 0.1, a = 1 }
    local xLabel = 8 + Client.UI_PAD_X
    local xValue = 136 + Client.UI_PAD_X
    local xValueTop = xLabel + 26
    for i = 1, #lines do
        local y = 6 + Client.UI_PAD_Y + (i - 1) * 14
        local entry = Client.addShadowLabel(
            panel,
            xLabel,
            y,
            16,
            lines[i].label,
            Client.getUIFont("small"),
            labelColor,
            labelShadow,
            1,
            1
        )
        labels[i] = entry
        local valueText = lines[i].isHeader and "" or "-"
        local valueX = (i >= 11) and xValueTop or xValue
        local valueEntry = Client.addShadowLabel(
            panel,
            valueX,
            y,
            16,
            valueText,
            Client.getUIFont("small"),
            valueColor,
            valueShadow,
            1,
            1
        )
        values[i] = valueEntry
    end

    Client._score = { panel = panel, labels = labels, values = values, data = nil }
    Client.addDragOverlay(panel, "score")
    return Client._score
end

function Client.ensureWalletPanel()
    if Client._wallet and Client._wallet.panel then
        return Client._wallet
    end
    local w, h = 168, 48
    local margin = 14
    local x = getCore():getScreenWidth() - w - margin
    local y = 70

    local panel = ISPanel:new(x, y, w, h)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    panel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    panel:setVisible(false)
    Client.addPanelBackground(panel, Rogue.Config and Rogue.Config.UI_WALLET_BG_TEX or nil, 0.85)

    local labelX = 8 + Client.UI_PAD_X
    local iconTex = nil
    if Rogue.Config and Rogue.Config.UI_WALLET_ICON_TEX then
        iconTex = getTexture(Rogue.Config.UI_WALLET_ICON_TEX)
    end
    if not iconTex then
        iconTex = Client.getItemIconTexture(Rogue.Config and Rogue.Config.WALLET_ICON_ITEM or nil)
    end
    if iconTex then
        local icon = ISImage:new(8 + Client.UI_PAD_X, 6 + Client.UI_PAD_Y - 10, 16, 16, iconTex)
        icon:initialise()
        Client.applyIconScale(icon, 16, 16)
        panel:addChild(icon)
        panel._icon = icon
        labelX = 28 + Client.UI_PAD_X
    end

    local textColor = Client.getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
    local shadowColor = { r = 0.85, g = 0.1, b = 0.1, a = 1 }
    local entry = Client.addShadowLabel(
        panel,
        labelX,
        6 + Client.UI_PAD_Y - 10,
        16,
        "0.00",
        Client.getUIFont("large"),
        textColor,
        shadowColor,
        1,
        1
    )

    Client._wallet = { panel = panel, label = entry }
    Client.addDragOverlay(panel, "wallet")
    return Client._wallet
end

function Client.updateWalletPanel(amount)
    local wallet = Client.ensureWalletPanel()
    local text = string.format("%.2f", tonumber(amount or 0))
    if wallet.label and wallet.label.label then
        Client.setShadowLabelText(wallet.label, text)
    elseif wallet.label and wallet.label.setName then
        wallet.label:setName(text)
    end
    wallet.panel:setVisible(Client._walletVisible)
end

function Client.enablePanelDrag(panel, key, handle)
    if not panel then return end
    local drag = handle or panel
    if key and Client._panelPos and Client._panelPos[key] then
        local pos = Client._panelPos[key]
        if pos.x and pos.y then
            panel:setX(pos.x)
            panel:setY(pos.y)
        end
    end
    drag.onMouseDown = function(self, x, y)
        panel._dragging = true
        panel._dragOffX = x
        panel._dragOffY = y
        panel._dragStartMouseX = getMouseX and getMouseX() or nil
        panel._dragStartMouseY = getMouseY and getMouseY() or nil
        panel._dragStartPanelX = panel:getX()
        panel._dragStartPanelY = panel:getY()
        if panel.bringToTop then
            panel:bringToTop()
        end
        if panel.setCapture then
            panel:setCapture(true)
        end
        return true
    end
    drag.onMouseMove = function(self, dx, dy)
        if not panel._dragging then return end
        local mx = getMouseX and getMouseX() or nil
        local my = getMouseY and getMouseY() or nil
        if mx and my and panel._dragStartMouseX and panel._dragStartMouseY then
            panel:setX(panel._dragStartPanelX + (mx - panel._dragStartMouseX))
            panel:setY(panel._dragStartPanelY + (my - panel._dragStartMouseY))
        else
            panel:setX(panel:getX() + dx)
            panel:setY(panel:getY() + dy)
        end
        if key then
            Client._panelPos[key] = { x = panel:getX(), y = panel:getY() }
        end
    end
    drag.onMouseUp = function(self, x, y)
        panel._dragging = false
        if panel.setCapture then
            panel:setCapture(false)
        end
        if key then
            Client._panelPos[key] = { x = panel:getX(), y = panel:getY() }
            if Client.savePanelPositions then
                Client.savePanelPositions()
            end
        end
        return true
    end
    drag.onMouseMoveOutside = drag.onMouseMove
    drag.onMouseUpOutside = drag.onMouseUp
end

function Client.addDragOverlay(panel, key)
    if not panel then return end
    local drag = ISPanel:new(0, 0, panel.width, panel.height)
    drag:initialise()
    drag.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    drag.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    panel:addChild(drag)
    if drag.bringToTop then
        drag:bringToTop()
    end
    Client.enablePanelDrag(panel, key, drag)
    panel._dragOverlay = drag
end

function Client.loadPanelPositions()
    if not getFileReader then return end
    local reader = getFileReader("roguelityno_ui_positions.txt", true)
    if not reader then return end
    local pos = {}
    local line = reader:readLine()
    while line do
        local key, x, y = line:match("^([%w_]+)%s*=%s*(-?%d+)%s*,%s*(-?%d+)%s*$")
        if key and x and y then
            pos[key] = { x = tonumber(x), y = tonumber(y) }
        end
        line = reader:readLine()
    end
    reader:close()
    Client._panelPos = pos
end

function Client.savePanelPositions()
    if not getFileWriter then return end
    local writer = getFileWriter("roguelityno_ui_positions.txt", false, false)
    if not writer then return end
    for key, pos in pairs(Client._panelPos or {}) do
        if pos and pos.x and pos.y then
            writer:write(string.format("%s=%d,%d\n", tostring(key), math.floor(pos.x), math.floor(pos.y)))
        end
    end
    writer:close()
end

if not Client._panelPosLoaded then
    Client._panelPosLoaded = true
    Client.loadPanelPositions()
end

function Client.applyScorePanel(args)
    if not Client._scoreVisible then
        return
    end
    local score = Client.ensureScorePanel()
    score.data = args
    local l = score.labels
    local v = score.values
    if not l or not v then return end
    Client.setShadowLabelText(v[1], tostring(args.waveKills or 0))
    Client.setShadowLabelText(v[2], string.format("%.2f", tonumber(args.waveDamage or 0)))
    Client.setShadowLabelText(v[3], tostring(args.roundKills or 0))
    Client.setShadowLabelText(v[4], tostring(args.roundDeaths or 0))
    Client.setShadowLabelText(v[5], string.format("%.2f", tonumber(args.roundDamage or 0)))
    Client.setShadowLabelText(v[6], string.format("%.2f", tonumber(args.roundCurrency or 0)))
    Client.setShadowLabelText(v[7], tostring(args.roundStreak or 0))
    Client.setShadowLabelText(v[8], tostring(args.totalKills or 0))
    Client.setShadowLabelText(v[9], tostring(args.totalDeaths or 0))
    Client.setShadowLabelText(v[10], string.format("%.2f", tonumber(args.totalDamage or 0)))
    Client.setShadowLabelText(v[11], "")
    local topList = args.topRound or args.top or {}
    for i = 1, 5 do
        local idx = 11 + i
        local entry = topList[i] or nil
        if entry then
            Client.setShadowLabelText(v[idx], string.format("%s - %d", tostring(entry.name or "?"), tonumber(entry.kills or 0)))
        else
            Client.setShadowLabelText(v[idx], "-")
        end
    end
    score.panel:setVisible(true)
    Client.updateWalletPanel(args.wallet)
    if Client._shopPanel and Client._shopPanel._walletLabel then
        local text = string.format("%.2f", tonumber(args.wallet or 0))
        local wl = Client._shopPanel._walletLabel
        if wl.label then
            Client.setShadowLabelText(wl, text)
        elseif wl.setName then
            wl:setName(text)
        end
    end
end

function Client.getSpriteName(obj)
    if not obj or not obj.getSprite then return nil end
    local spr = obj:getSprite()
    if not spr or not spr.getName then return nil end
    return spr:getName()
end

function Client.getObjectSquare(obj)
    if not obj or not obj.getSquare then return nil end
    return obj:getSquare()
end

function Client.getSquareKey(square)
    if not square then return nil end
    return tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
end

function Client.normalizeShopObjects(data)
    if type(data) ~= "table" then
        return { entries = {} }
    end
    if data.entries and type(data.entries) == "table" then
        return data
    end
    local entries = {}
    for category, entry in pairs(data) do
        if type(entry) == "table" and entry.key then
            table.insert(entries, {
                id = entry.id or (#entries + 1),
                name = entry.name or tostring(category),
                category = tostring(category),
                sprite = entry.sprite,
                key = entry.key,
            })
        end
    end
    return { entries = entries }
end

function Client.findShopCategory(worldobjects)
    if not worldobjects then return nil end
    if Client._shopObjects then
        local entries = Client._shopObjects.entries or {}
        local baseSquare = nil
        for i = 1, #worldobjects do
            local obj = worldobjects[i]
            local spr = Client.getSpriteName(obj)
            local square = Client.getObjectSquare(obj)
            if square and not baseSquare then
                baseSquare = square
            end
            local key = Client.getSquareKey(square)
            if spr and key then
                for j = 1, #entries do
                    local data = entries[j]
                    if data and data.key == key and (not data.sprite or data.sprite == spr) then
                        return data.category, data
                    end
                end
            end
        end
        if baseSquare and #entries > 0 then
            local radius = 1
            if Rogue and Rogue.Config and Rogue.Config.SHOP_INTERACT_RADIUS then
                radius = math.max(0, math.floor(tonumber(Rogue.Config.SHOP_INTERACT_RADIUS) or radius))
            end
            if radius > 0 then
                local cell = getCell()
                local bx, by, bz = baseSquare:getX(), baseSquare:getY(), baseSquare:getZ()
                for dx = -radius, radius do
                    for dy = -radius, radius do
                        local sq = cell and cell:getGridSquare(bx + dx, by + dy, bz) or nil
                        local key = Client.getSquareKey(sq)
                        if key then
                            for j = 1, #entries do
                                local data = entries[j]
                                if data and data.key == key then
                                    return data.category, data
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    local map = Rogue.Config and Rogue.Config.SHOP_SPRITES or {}
    for i = 1, #worldobjects do
        local obj = worldobjects[i]
        local spr = Client.getSpriteName(obj)
        if spr then
            for category, list in pairs(map) do
                for j = 1, #list do
                    if list[j] == spr then
                        return category, spr
                    end
                end
            end
        end
    end
    return nil
end

function Client.getCategoryLabel(category)
    local labels = Rogue.Config and Rogue.Config.SHOP_CATEGORY_LABELS or {}
    local label = labels[category]
    if type(label) == "string" and label:sub(1, 3) == "UI_" then
        return T(label)
    end
    return label or tostring(category)
end

function Client.getShopSubcategories(category)
    local map = Rogue.Config and Rogue.Config.SHOP_SUBCATEGORIES or nil
    local list = map and map[category] or nil
    if list and #list > 0 then
        return list
    end
    return nil
end

function Client.getShopSubcatLabel(entry)
    if not entry then return "" end
    if entry.labelKey and entry.labelKey ~= "" then
        return T(entry.labelKey)
    end
    return entry.label or entry.id or ""
end

function Client.getShopSubcatState()
    local player = getPlayer and getPlayer() or (getSpecificPlayer and getSpecificPlayer(0) or nil)
    if not player or not player.getModData then return nil end
    local md = player:getModData()
    md.RogueShopSubcat = md.RogueShopSubcat or {}
    return md.RogueShopSubcat
end

function Client.getSelectedShopSubcat(category, subcats)
    if not subcats or #subcats == 0 then return nil end
    local md = Client.getShopSubcatState()
    local saved = md and md[category] or nil
    if saved then
        for i = 1, #subcats do
            local entry = subcats[i]
            if entry and entry.id == saved then
                return saved
            end
        end
    end
    return subcats[1].id
end

function Client.setSelectedShopSubcat(category, subcatId)
    local md = Client.getShopSubcatState()
    if not md then return end
    md[category] = subcatId
end

function Client.filterShopItems(items, subcatId)
    if not items then return {} end
    if not subcatId or subcatId == "all" then
        return items
    end
    local filtered = {}
    for i = 1, #items do
        local entry = items[i]
        if entry and entry.subcat == subcatId then
            table.insert(filtered, entry)
        end
    end
    return filtered
end

function Client.populateShopList(list, category, items, subcatId, minRows)
    if not list then return end
    if list.clear then
        list:clear()
    else
        list.items = {}
    end
    list.selected = 0
    local filtered = Client.filterShopItems(items, subcatId)
    for i = 1, #filtered do
        local entry = filtered[i]
        local id = entry.id or "unknown"
        local qty = entry.qty or 1
        local price = tonumber(entry.price) or 0
        local displayName = Client.getItemDisplayName(id) or id
        local line = displayName
        if (tonumber(qty) or 0) > 1 then
            line = string.format("%s x%d", displayName, qty)
        end
        local icon = Client.getItemIconTexture(id)
        local priceText = string.format("%.2f", tonumber(price) or 0)
        local tooltip = Client.getStockTooltip(category, id)
        list:addItem(line, {
            id = id,
            qty = qty,
            price = price,
            priceText = priceText,
            line = line,
            icon = icon,
            isPlaceholder = false,
        }, tooltip)
    end
end

function Client.getTraitLabel(traitId)
    if not traitId then return nil end
    local raw = tostring(traitId)
    local id = raw:gsub("^%w+:", "")
    local customKey = "UI_rogue_trait_" .. id
    if getText then
        local t = getText(customKey)
        if t and t ~= customKey then
            return t
        end
    end
    if TraitFactory and TraitFactory.getTrait then
        local trait = TraitFactory.getTrait(raw) or TraitFactory.getTrait(id)
        if trait and trait.getLabel then
            return trait:getLabel()
        end
    end
    local pretty = id:gsub("^%l", string.upper)
    return pretty ~= "" and pretty or raw
end

function Client.getPerkLabel(perkId)
    if not perkId then return nil end
    local customKey = "UI_rogue_perk_" .. tostring(perkId)
    if getText then
        local t = getText(customKey)
        if t and t ~= customKey then
            return t
        end
    end
    local key = "IGUI_Perk_" .. tostring(perkId)
    if getText then
        local t = getText(key)
        if t and t ~= key then
            return t
        end
    end
    return tostring(perkId)
end

function Client.getIconTag(iconPath)
    if not iconPath or iconPath == "" then return nil end
    return "<IMAGE:" .. tostring(iconPath) .. ">"
end

function Client.getTraitIconTag(traitId)
    local path = Client.getTraitIconPath(traitId)
    if path and getTexture(path) then
        return Client.getIconTag(path)
    end
    return nil
end

function Client.getSkillIconTag(skillId)
    local path = Client.getSkillIconPath(skillId)
    if path and getTexture(path) then
        return Client.getIconTag(path)
    end
    return nil
end

function Client.getItemIconTag(itemId)
    return nil
end

function Client.buildTooltip(build)
    if not build then return nil end
    local parts = {}
    if build.desc and build.desc ~= "" then
        table.insert(parts, tostring(build.desc))
    end
    if build.traits and #build.traits > 0 then
        local list = {}
        for i = 1, #build.traits do
            local icon = Client.getTraitIconTag(build.traits[i])
            if icon and icon ~= "" then
                table.insert(list, icon)
            else
                local label = Client.getTraitLabel(build.traits[i])
                if label and label ~= "" then
                    table.insert(list, label)
                end
            end
        end
        if #list > 0 then
            table.insert(parts, T("UI_rogue_build_traits") .. ": " .. table.concat(list, " "))
        end
    end
    if build.skills then
        local list = {}
        for perkId, level in pairs(build.skills) do
            local icon = Client.getSkillIconTag(perkId)
            if icon and level then
                table.insert(list, string.format("%s +%d", icon, tonumber(level) or 0))
            else
                local label = Client.getPerkLabel(perkId)
                if label and level then
                    table.insert(list, string.format("%s +%d", label, tonumber(level) or 0))
                end
            end
        end
        if #list > 0 then
            table.sort(list)
            table.insert(parts, T("UI_rogue_build_skills") .. ": " .. table.concat(list, ", "))
        end
    end
    if build.startingStats then
        local list = {}
        for perkId, level in pairs(build.startingStats) do
            local icon = Client.getSkillIconTag(perkId)
            if icon and level then
                table.insert(list, string.format("%s %d", icon, tonumber(level) or 0))
            else
                local label = Client.getPerkLabel(perkId)
                if label and level then
                    table.insert(list, string.format("%s %d", label, tonumber(level) or 0))
                end
            end
        end
        if #list > 0 then
            table.sort(list)
            table.insert(parts, T("UI_rogue_build_stats") .. ": " .. table.concat(list, ", "))
        end
    end
    if build.xpBoosts then
        local function formatMult(value)
            local n = tonumber(value) or 0
            if math.floor(n) == n then
                return string.format("x%d", n)
            end
            return string.format("x%.2f", n)
        end
        local list = {}
        for perkId, level in pairs(build.xpBoosts) do
            local icon = Client.getSkillIconTag(perkId)
            if icon and level then
                table.insert(list, string.format("%s %s", icon, formatMult(level)))
            else
                local label = Client.getPerkLabel(perkId)
                if label and level then
                    table.insert(list, string.format("%s %s", label, formatMult(level)))
                end
            end
        end
        if #list > 0 then
            table.sort(list)
            table.insert(parts, T("UI_rogue_build_xp_boosts") .. ": " .. table.concat(list, " "))
        end
    end
    if build.loadout and #build.loadout > 0 then
        local list = {}
        for i = 1, #build.loadout do
            local entry = build.loadout[i]
            local id = entry and entry.id or nil
            local qty = entry and entry.qty or 1
            if id then
                local name = Client.getItemDisplayName(id) or tostring(id)
                local count = tonumber(qty) or 1
                if count > 1 then
                    table.insert(list, string.format("%s x%d", name, count))
                else
                    table.insert(list, name)
                end
            end
        end
        if #list > 0 then
            table.insert(parts, T("UI_rogue_build_loadout") .. ": " .. table.concat(list, ", "))
        end
    end
    return #parts > 0 and table.concat(parts, "\n") or nil
end

function Client.closeShopPanel()
    if Client._shopPanel and Client._shopPanel:getIsVisible() then
        Client._shopPanel:setVisible(false)
        Client._shopPanel:removeFromUIManager()
        Client._shopPanel = nil
    end
end

function Client.getStockTooltip(category, itemId)
    if not category or not itemId then return nil end
    local stockMap = Client._shopStock and Client._shopStock[category] or nil
    if not stockMap then
        return T("UI_rogue_stock_tooltip_unknown")
    end
    local stock = stockMap[itemId]
    if stock == nil then
        return T("UI_rogue_stock_tooltip_unlimited")
    end
    return T("UI_rogue_stock_tooltip_fmt", tostring(stock))
end

function Client.updateShopTooltips(panel)
    if not panel or not panel._itemList or not panel._category then return end
    local list = panel._itemList
    local category = panel._category
    for i = 1, #list.items do
        local item = list.items[i]
        local data = item and item.item or nil
        if data and data.id then
            item.tooltip = Client.getStockTooltip(category, data.id)
        end
    end
end

function Client.openShopPanel(player, category)
    Client.closeShopPanel()
    Client.requestScore()
    if category == "builds" then
        Client.openBuildShopPanel(player)
        return
    end
    Client.playUISound("shop_open", category)
    sendClientCommand("Rogue", "shopStockRequest", { category = category })
    local items = Rogue.Config and Rogue.Config.SHOP_ITEMS and Rogue.Config.SHOP_ITEMS[category] or nil
    if not items then
        Client.showMessage(T("UI_rogue_shop_empty", Client.getCategoryLabel(category)))
        return
    end

    local pad = (Rogue.Config and Rogue.Config.UI_SHOP_PAD) or 12
    local subcats = Client.getShopSubcategories(category)
    local selectedSubcatId = Client.getSelectedShopSubcat(category, subcats)
    local subcatRowH = (subcats and 28) or 0
    local extraLeft = 60
    local extraTop = 20
    local extraRight = 84
    if category == "drugs" then
        extraLeft = extraLeft + 20
        extraTop = 0
        extraRight = extraRight + 16
    elseif category == "perks" then
        extraLeft = extraLeft + 20
        extraTop = 0
        extraRight = extraRight + 16
    end
    local rowH = 40
    local headerH = 30
    local topPad = 60
    local footerH = 30
    local buttonW = 80
    local buttonH = 26
    local w, h = 576, 512
    local x = (getCore():getScreenWidth() / 2) - (w / 2)
    local y = (getCore():getScreenHeight() / 2) - (h / 2)

    local panel = ISPanel:new(x, y, w, h)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    if panel.setMovable then panel:setMovable(true) end
    if panel.setMoveWithMouse then panel:setMoveWithMouse(true) end
    Client.enablePanelDrag(panel, "shop")
    panel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    local bgByCat = Rogue.Config and Rogue.Config.UI_SHOP_BG_TEX_BY_CATEGORY or nil
    local shopBg = (bgByCat and bgByCat[category]) or (Rogue.Config and Rogue.Config.UI_SHOP_BG_TEX or nil)
    Client.addPanelBackground(panel, shopBg, 0.9)

    local categoryIconItem = Rogue.Config and Rogue.Config.SHOP_CATEGORY_ICON_ITEM and Rogue.Config.SHOP_CATEGORY_ICON_ITEM[category] or nil
    local categoryIcon = Client.getItemIconTexture(categoryIconItem)
    local contentLeft = pad + Client.UI_PAD_X + extraLeft
    local contentTop = pad + topPad + Client.UI_PAD_Y + extraTop
    if categoryIcon then
        local img = ISImage:new(contentLeft, contentTop - 2, 20, 20, categoryIcon)
        img:initialise()
        Client.applyIconScale(img, 20, 20)
        panel:addChild(img)
    end

    local textColor = Client.getUIColor("UI_COLOR_TEXT", { r = 1, g = 1, b = 1, a = 1 })
    local shadowColor = { r = 0, g = 0, b = 0, a = 1 }
    local titleText = T("UI_rogue_shop_title", Client.getCategoryLabel(category))
    local titleFont = Client.getUIFont("large")
    local tw = getTextManager() and getTextManager():MeasureStringX(titleFont, titleText) or 0
    local tx = math.max(pad, (w - tw) / 2)
    Client.addShadowLabel(
        panel,
        tx,
        contentTop - 4,
        24,
        titleText,
        titleFont,
        Client.getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 }),
        { r = 0, g = 0, b = 0, a = 1 },
        1,
        1
    )

    local wallet = Client._lastScore and Client._lastScore.wallet or 0
    local walletLabelX = w - pad - 130
    local walletIcon = nil
    if Rogue.Config and Rogue.Config.UI_WALLET_ICON_TEX then
        walletIcon = getTexture(Rogue.Config.UI_WALLET_ICON_TEX)
    end
    if not walletIcon then
        walletIcon = Client.getItemIconTexture(Rogue.Config and Rogue.Config.WALLET_ICON_ITEM or nil)
    end
    if walletIcon then
        local wimg = ISImage:new(walletLabelX - 22, contentTop - 2, 20, 20, walletIcon)
        wimg:initialise()
        Client.applyIconScale(wimg, 20, 20)
        panel:addChild(wimg)
        walletLabelX = walletLabelX + 2
    end
    local walletEntry = Client.addShadowLabel(
        panel,
        walletLabelX,
        contentTop - 2,
        20,
        string.format("%.2f", tonumber(wallet or 0)),
        Client.getUIFont("small"),
        Client.getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 }),
        { r = 0, g = 0, b = 0, a = 1 },
        1,
        1
    )
    panel._walletLabel = walletEntry

    local listX = pad + extraLeft + Client.UI_PAD_X - 6
    local listY = contentTop + headerH + subcatRowH
    local listW = w - (pad * 2) - extraLeft - extraRight
    local listH = h - listY - (pad + footerH)
    local list = ISScrollingListBox:new(listX, listY, listW, listH)
    list:initialise()
    list:instantiate()
    list.itemheight = rowH
    list.font = Client.getUIFont("large")
    list.itemPadY = 4
    list.drawBorder = false
    list.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    list.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    list._category = category
    list._buttonW = buttonW
    list._buttonH = buttonH
    list._textColor = textColor
    list._shadowColor = shadowColor
    list._walletTex = walletIcon or Client.getItemIconTexture(Rogue.Config and Rogue.Config.WALLET_ICON_ITEM or nil)

    local function drawShadowText(self, text, x, y, font, color, shadow)
        self:drawText(text, x + 1, y + 1, shadow.r, shadow.g, shadow.b, shadow.a, font)
        self:drawText(text, x, y, color.r, color.g, color.b, color.a, font)
    end

    list.doDrawItem = function(self, y, item, alt)
        if not item then return y + rowH end
        local data = item.item or {}
        local isPlaceholder = data.isPlaceholder
        local rowHgt = item.height or rowH
        local now = getTimestampMs()
        local flashUntil = item._flashUntilMs or 0
        local stockMap = Client._shopStock and Client._shopStock[self._category] or nil
        local stock = (not isPlaceholder and stockMap and data.id) and stockMap[data.id] or nil
        local isSoldOut = (stock ~= nil and stock <= 0)
        local lineX = 6
        if not isPlaceholder then
            local tex = data.icon
            if tex then
                self:drawTextureScaled(tex, lineX, y + 6, 20, 20, 1, 1, 1, 1)
                lineX = lineX + 26
            end
        end

        local line = data.line or ""
        if not isPlaceholder then
            if stock == nil then
                line = line .. T("UI_rogue_stock_unlimited")
            else
                line = line .. T("UI_rogue_stock_fmt", tostring(stock))
            end
        end
        if isSoldOut then
            line = line .. "  " .. T("UI_rogue_sold_out")
        end
        if flashUntil > now then
            self:drawRect(0, y, self.width, rowHgt - 1, 0.15, 1, 0.95, 0.2)
        end
        local lineH = getTextManager() and getTextManager():getFontHeight(self.font) or 16
        local lineY = y + math.floor((rowHgt - lineH) / 2)
        drawShadowText(self, line, lineX, lineY, self.font, self._textColor, self._shadowColor)

        local btnW = self._buttonW or 90
        local btnH = self._buttonH or 26
        local btnX = self.width - btnW - 6
        local btnY = y + math.floor((rowHgt - btnH) / 2)
        local hover = false
        if getMouseX and getMouseY then
            local mx = getMouseX()
            local my = getMouseY()
            if mx and my then
                local ax = (self.getAbsoluteX and self:getAbsoluteX()) or (self.parent and self.parent:getAbsoluteX() or 0) + (self.x or 0)
                local ay = (self.getAbsoluteY and self:getAbsoluteY()) or (self.parent and self.parent:getAbsoluteY() or 0) + (self.y or 0)
                local rx = mx - ax
                local ry = my - ay
                if rx >= btnX and rx <= (btnX + btnW) and ry >= btnY and ry <= (btnY + btnH) then
                    hover = true
                end
            end
        end
        local fill = hover and 0.35 or 0.2
        local br = hover and 1.0 or 1.0
        local bg = hover and 0.95 or 0.9
        local bb = hover and 0.35 or 0.2
        self:drawRect(btnX, btnY, btnW, btnH, fill, 0, 0, 0)
        self:drawRectBorder(btnX, btnY, btnW, btnH, 0.7, br, bg, bb)

        local priceText = data.priceText or ""
        local textX = btnX + 24
        local textH = getTextManager() and getTextManager():getFontHeight(self.font) or 16
        local textY = btnY + math.floor((btnH - textH) / 2)
        if self._walletTex then
            local iconSize = 18
            local iconY = btnY + math.floor((btnH - iconSize) / 2)
            self:drawTextureScaled(self._walletTex, btnX + 4, iconY, iconSize, iconSize, 1, 1, 1, 1)
        else
            textX = btnX + 6
        end
        drawShadowText(self, priceText, textX, textY, self.font, self._textColor, self._shadowColor)

        return y + rowHgt
    end

    list.onMouseDown = function(self, x, y)
        if self:isMouseOverScrollBar() then
            return ISScrollingListBox.onMouseDown(self, x, y)
        end
        local row = self:rowAt(x, y)
        if row < 1 then return end
        local item = self.items[row]
        if not item then return end
        local data = item.item or {}
        if data.isPlaceholder then return end
        local stockMap = Client._shopStock and Client._shopStock[self._category] or nil
        local stock = (stockMap and data.id) and stockMap[data.id] or nil
        if stock ~= nil and stock <= 0 then
            return
        end

        local rowTop = self:topOfItem(row)
        local btnW = self._buttonW or 90
        local btnH = self._buttonH or 26
        local btnX = self.width - btnW - 6
        local btnY = rowTop + math.floor((rowH - btnH) / 2)
        if x >= btnX and x <= (btnX + btnW) and y >= btnY and y <= (btnY + btnH) then
            item._flashUntilMs = getTimestampMs() + 150
            sendClientCommand("Rogue", "shopBuy", {
                category = self._category,
                itemId = data.id,
                qty = data.qty,
            })
            return
        end
        ISScrollingListBox.onMouseDown(self, x, y)
    end

    if subcats then
        local subcatY = contentTop + headerH - 2
        local subcatX = listX
        local subcatPad = 6
        local btnH = 22
        local font = Client.getUIFont("small")
        local accent = Client.getUIColor("UI_COLOR_BORDER", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
        local function applySubcatStyle(btn, active)
            if active then
                btn.backgroundColor = { r = 0.08, g = 0.06, b = 0.02, a = 0.7 }
                btn.borderColor = { r = accent.r, g = accent.g, b = accent.b, a = 0.9 }
                btn.textColor = Client.getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
            else
                btn.backgroundColor = { r = 0, g = 0, b = 0, a = 0.3 }
                btn.borderColor = { r = 0.4, g = 0.35, b = 0.1, a = 0.5 }
                btn.textColor = Client.getUIColor("UI_COLOR_TEXT", { r = 0.85, g = 0.75, b = 0.25, a = 0.9 })
            end
        end

        panel._subcatButtons = {}
        for i = 1, #subcats do
            local entry = subcats[i]
            local label = Client.getShopSubcatLabel(entry)
            local tw = getTextManager() and getTextManager():MeasureStringX(font, label) or (string.len(label) * 6)
            local bw = math.max(40, tw + 16)
            local btn = ISButton:new(subcatX, subcatY, bw, btnH, label, panel, function()
                selectedSubcatId = entry.id
                Client.setSelectedShopSubcat(category, selectedSubcatId)
        Client.populateShopList(list, category, items, selectedSubcatId, 0)
                for j = 1, #panel._subcatButtons do
                    local b = panel._subcatButtons[j]
                    applySubcatStyle(b, b._subcatId == selectedSubcatId)
                end
                Client.updateShopTooltips(panel)
            end)
            btn:initialise()
            btn._subcatId = entry.id
            applySubcatStyle(btn, entry.id == selectedSubcatId)
            panel:addChild(btn)
            table.insert(panel._subcatButtons, btn)
            subcatX = subcatX + bw + subcatPad
        end
    end

    Client.populateShopList(list, category, items, selectedSubcatId, 0)
    panel:addChild(list)
    panel._itemList = list
    panel._category = category

    local function onClose()
        Client.closeShopPanel()
    end
    local closeBtn = ISButton:new(pad, h - pad - 22, 70, 22, T("UI_rogue_close"), panel, onClose)
    closeBtn:initialise()
    panel:addChild(closeBtn)

    Client._shopPanel = panel
end

function Client.openBuildShopPanel(player)
    Client.closeShopPanel()
    Client.requestScore()
    Client.playUISound("build_open", "builds")
    local builds = Rogue.Config and Rogue.Config.BUILD_SHOP or {}
    if not builds or #builds == 0 then
        Client.showMessage(T("UI_rogue_build_shop_empty"))
        return
    end

    local pad = (Rogue.Config and Rogue.Config.UI_SHOP_PAD) or 12
    local extraLeft = 20
    local rowH = 46
    local headerH = 30
    local topPad = 30
    local footerH = 30
    local buttonW = 90
    local buttonH = 26
    local rows = #builds
    local w, h = 576, 512
    local x = (getCore():getScreenWidth() / 2) - (w / 2)
    local y = (getCore():getScreenHeight() / 2) - (h / 2)

    local panel = ISPanel:new(x, y, w, h)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    if panel.setMovable then panel:setMovable(true) end
    if panel.setMoveWithMouse then panel:setMoveWithMouse(true) end
    Client.enablePanelDrag(panel, "buildshop")
    panel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    local bgByCat = Rogue.Config and Rogue.Config.UI_SHOP_BG_TEX_BY_CATEGORY or nil
    local shopBg = (bgByCat and bgByCat.builds) or (Rogue.Config and Rogue.Config.UI_SHOP_BG_TEX or nil)
    Client.addPanelBackground(panel, shopBg, 0.75)

    local textColor = Client.getUIColor("UI_COLOR_TEXT", { r = 1, g = 1, b = 1, a = 1 })
    local shadowColor = { r = 0, g = 0, b = 0, a = 1 }
    local buildShadowById = Rogue.Config and Rogue.Config.BUILD_TEXT_SHADOW_BY_ID or {}
    if type(buildShadowById) ~= "table" then
        buildShadowById = {}
    end
    local function clearRowHover()
        local hover = panel._hoverRowBg
        if hover then
            hover.backgroundColor.a = 0
            hover.borderColor.a = 0
            panel._hoverRowBg = nil
        end
    end
    panel.onMouseMoveOutside = function()
        clearRowHover()
    end
    panel.onMouseOut = function()
        clearRowHover()
    end
    local titleText = T("UI_rogue_build_shop")
    local titleFont = Client.getUIFont("large")
    local tw = getTextManager() and getTextManager():MeasureStringX(titleFont, titleText) or 0
    local tx = math.max(pad, (w - tw) / 2)
    Client.addShadowLabel(
        panel,
        tx,
        pad + topPad + Client.UI_PAD_Y - 4,
        24,
        titleText,
        titleFont,
        Client.getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 }),
        { r = 0, g = 0, b = 0, a = 1 },
        1,
        1
    )
    local wallet = Client._lastScore and Client._lastScore.wallet or 0
    local walletLabelX = w - pad - 130
    local walletIcon = nil
    if Rogue.Config and Rogue.Config.UI_WALLET_ICON_TEX then
        walletIcon = getTexture(Rogue.Config.UI_WALLET_ICON_TEX)
    end
    if not walletIcon then
        walletIcon = Client.getItemIconTexture(Rogue.Config and Rogue.Config.WALLET_ICON_ITEM or nil)
    end
    if walletIcon then
        local wimg = ISImage:new(walletLabelX - 18, pad + topPad + Client.UI_PAD_Y - 2, 16, 16, walletIcon)
        wimg:initialise()
        Client.applyIconScale(wimg, 16, 16)
        panel:addChild(wimg)
        walletLabelX = walletLabelX + 2
    end
    local walletEntry = Client.addShadowLabel(
        panel,
        walletLabelX,
        pad + topPad + Client.UI_PAD_Y - 2,
        20,
        string.format("%.2f", tonumber(wallet or 0)),
        Client.getUIFont("small"),
        Client.getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 }),
        { r = 0, g = 0, b = 0, a = 1 },
        1,
        1
    )
    panel._walletLabel = walletEntry

    local buildMap = Rogue.Config and (Rogue.Config.BUILDS or Rogue.Config.PROFESSIONS) or {}
    local buildById = {}
    for i = 1, #buildMap do
        buildById[buildMap[i].id] = buildMap[i]
    end

    local contentLeft = pad + Client.UI_PAD_X + extraLeft
    for i = 1, rows do
        local entry = builds[i]
        local id = entry.id
        local price = tonumber(entry.price) or 0
        local build = buildById[id]
        local label = build and build.name or id
        local line = tostring(label)
        local lineX = contentLeft
        local rowY = pad + topPad + headerH + Client.UI_PAD_Y + (i - 1) * rowH
        local rowBgX = pad + extraLeft + Client.UI_PAD_X - 6
        local rowBgRight = w - pad - Client.UI_PAD_X - 12
        local rowBgW = math.max(10, rowBgRight - rowBgX)
        local rowBg = ISPanel:new(rowBgX, rowY - 2, rowBgW, rowH)
        rowBg:initialise()
        rowBg.backgroundColor = { r = 1, g = 0.9, b = 0.2, a = 0 }
        rowBg.borderColor = { r = 1, g = 0.9, b = 0.2, a = 0 }
        panel:addChild(rowBg)
        local function setRowHighlight(on)
            rowBg.backgroundColor.a = on and 0.18 or 0
            rowBg.borderColor.a = on and 0.45 or 0
            if on then
                panel._hoverRowBg = rowBg
            elseif panel._hoverRowBg == rowBg then
                panel._hoverRowBg = nil
            end
        end
        local function wireHover(ui)
            if not ui then return end
            ui.onMouseMove = function()
                clearRowHover()
                setRowHighlight(true)
                return true
            end
            ui.onMouseOut = function()
                setRowHighlight(false)
            end
        end
        local buildIcon = Client.getBuildIconTexture(id, build)
        if buildIcon then
            local iconSize = 24
            local img = ISImage:new(contentLeft, rowY + 1, iconSize, iconSize, buildIcon)
            img:initialise()
            Client.applyIconScale(img, iconSize, iconSize)
            panel:addChild(img)
            lineX = contentLeft + 30
            wireHover(img)
        end
        local buildShadow = buildShadowById[id] or shadowColor
        local entryLabel = Client.addShadowLabel(
            panel,
            lineX,
            rowY + 4,
            20,
            line,
            Client.getUIFont("large"),
            textColor,
            buildShadow,
            1,
            1
        )
        local lbl = entryLabel and entryLabel.label or nil
        local buildTip = Client.buildTooltip(build)
        if lbl and buildTip then
            lbl.tooltip = buildTip
        end
        if entryLabel and entryLabel.shadow then
            wireHover(entryLabel.shadow)
        end
        if lbl then
            wireHover(lbl)
        end

        local function onBuy()
            sendClientCommand("Rogue", "buildBuy", {
                buildId = id,
                price = price,
            })
            Client.closeShopPanel()
        end
        local priceText = string.format("%.2f", tonumber(price) or 0)
        local buttonText = " " .. priceText
        local btnY = rowY + 18
        local btn = ISButton:new(w - pad - buttonW - 72, btnY, buttonW, buttonH, buttonText, panel, onBuy)
        btn:initialise()
        if buildTip then
            btn.tooltip = buildTip
        else
            btn.tooltip = line
        end
        panel:addChild(btn)
        wireHover(btn)
        btn.textColor = textColor
        btn.textColor2 = textColor
        local walletTex = walletIcon or Client.getItemIconTexture(Rogue.Config and Rogue.Config.WALLET_ICON_ITEM or nil)
        if walletTex then
            local iconSize = 16
            local icon = ISImage:new(btn.x + 4, btn.y + math.floor((buttonH - iconSize) / 2), iconSize, iconSize, walletTex)
            icon:initialise()
            Client.applyIconScale(icon, iconSize, iconSize)
            panel:addChild(icon)
        end
    end

    local function onClose()
        Client.closeShopPanel()
    end
    local closeBtn = ISButton:new(pad, h - pad - 22, 70, 22, T("UI_rogue_close"), panel, onClose)
    closeBtn:initialise()
    panel:addChild(closeBtn)

    Client._shopPanel = panel
end

function Client.openBuildSelectorPanel()
    if Client._buildSelectorShown then return end
    Client._buildSelectorShown = true
    Client.openBuildShopPanel(getPlayer())
end


function Client.getFirstSpriteObject(worldobjects)
    if not worldobjects then return nil end
    for i = 1, #worldobjects do
        local obj = worldobjects[i]
        local spr = Client.getSpriteName(obj)
        if spr then
            return obj, spr
        end
    end
    return nil
end

function Client.getShopCategorySprite(category)
    local map = Rogue.Config and Rogue.Config.SHOP_SPRITES or {}
    local list = map[category] or nil
    if not list or #list == 0 then return nil end
    for i = 1, #list do
        local spr = list[i]
        if spr and spr ~= "" then
            if not getSprite or getSprite(spr) then
                return spr
            end
        end
    end
    return nil
end

function Client.setShopForCategory(worldobjects, category)
    local desiredSprite = Client.getShopCategorySprite(category)
    local obj, spr = Client.getFirstSpriteObject(worldobjects)
    local sprite = desiredSprite or spr
    if not sprite then
        Client.showMessage("No sprite object found on this tile.")
        return
    end
    local square = obj and Client.getObjectSquare(obj) or nil
    local key = Client.getSquareKey(square)
    sendClientCommand("Rogue", "setShop", {
        category = category,
        sprite = sprite,
        key = key,
    })
end

function Client.promptShopForCategory(worldobjects, category)
    if Client._shopNamePanel and Client._shopNamePanel:getIsVisible() then
        return
    end
    local w, h = 320, 140
    local x = (getCore():getScreenWidth() / 2) - (w / 2)
    local y = (getCore():getScreenHeight() / 2) - (h / 2)
    local panel = ISPanel:new(x, y, w, h)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    panel.backgroundColor = Client.getUIColor("UI_COLOR_BG", { r = 0, g = 0, b = 0, a = 0.75 })
    panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }

    local textColor = Client.getUIColor("UI_COLOR_TEXT", { r = 1, g = 1, b = 1, a = 1 })
    local title = ISLabel:new(12 + Client.UI_PAD_X, 8 + Client.UI_PAD_Y, 20, T("UI_rogue_shop_name_title"), textColor.r, textColor.g, textColor.b, textColor.a, Client.getUIFont("small"), true)
    title:initialise()
    panel:addChild(title)

    local entry = ISTextEntryBox:new("", 12 + Client.UI_PAD_X, 40 + Client.UI_PAD_Y, w - 24 - Client.UI_PAD_X * 2, 22)
    entry:initialise()
    entry:instantiate()
    panel:addChild(entry)
    entry:focus()

    local function closePanel()
        panel:setVisible(false)
        panel:removeFromUIManager()
        Client._shopNamePanel = nil
    end

    local function onOk()
        local name = entry:getText() or ""
        local desiredSprite = Client.getShopCategorySprite(category)
        local obj, spr = Client.getFirstSpriteObject(worldobjects)
        local sprite = desiredSprite or spr
        if not sprite then
            Client.showMessage("No sprite object found on this tile.")
            closePanel()
            return
        end
        local square = obj and Client.getObjectSquare(obj) or nil
        local key = Client.getSquareKey(square)
        sendClientCommand("Rogue", "setShop", {
            category = category,
            sprite = sprite,
            key = key,
            name = name,
        })
        closePanel()
    end

    local btnOk = ISButton:new(40, h - 40, 100, 24, T("UI_rogue_ok"), panel, onOk)
    btnOk:initialise()
    panel:addChild(btnOk)
    local btnCancel = ISButton:new(180, h - 40, 100, 24, T("UI_rogue_cancel"), panel, closePanel)
    btnCancel:initialise()
    panel:addChild(btnCancel)

    Client._shopNamePanel = panel
end

function Client.openShopListPanel()
    if Client._shopListPanel and Client._shopListPanel:getIsVisible() then return end
    local w, h = 420, 320
    local x = (getCore():getScreenWidth() / 2) - (w / 2)
    local y = (getCore():getScreenHeight() / 2) - (h / 2)
    local panel = ISPanel:new(x, y, w, h)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    panel.backgroundColor = Client.getUIColor("UI_COLOR_BG", { r = 0, g = 0, b = 0, a = 0.75 })
    panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }

    local textColor = Client.getUIColor("UI_COLOR_TEXT", { r = 1, g = 1, b = 1, a = 1 })
    local title = ISLabel:new(12 + Client.UI_PAD_X, 8 + Client.UI_PAD_Y, 20, T("UI_rogue_shop_list_title"), textColor.r, textColor.g, textColor.b, textColor.a, Client.getUIFont("small"), true)
    title:initialise()
    panel:addChild(title)

    local list = ISScrollingListBox:new(12 + Client.UI_PAD_X, 34 + Client.UI_PAD_Y, w - 24 - Client.UI_PAD_X * 2, h - 90)
    list:initialise()
    list:instantiate()
    list.itemheight = 20
    list.font = Client.getUIFont("small")
    list.drawBorder = false
    panel:addChild(list)

    local entries = (Client._shopObjects and Client._shopObjects.entries) or {}
    for i = 1, #entries do
        local e = entries[i]
        if e then
            local catLabel = Client.getCategoryLabel(e.category)
            local name = e.name or ""
            local line = string.format("[%d] %s - %s", tonumber(e.id) or i, tostring(name), tostring(catLabel))
            list:addItem(line, e)
        end
    end

    local function closePanel()
        panel:setVisible(false)
        panel:removeFromUIManager()
        Client._shopListPanel = nil
    end

    local function onRemove()
        local item = list:getItem() and list:getItem().item
        if not item then return end
        sendClientCommand("Rogue", "removeShop", { id = item.id })
        closePanel()
    end

    local btnRemove = ISButton:new(40, h - 44, 120, 24, T("UI_rogue_shop_remove"), panel, onRemove)
    btnRemove:initialise()
    panel:addChild(btnRemove)
    local btnClose = ISButton:new(220, h - 44, 120, 24, T("UI_rogue_close"), panel, closePanel)
    btnClose:initialise()
    panel:addChild(btnClose)

    Client._shopListPanel = panel
end

function Client.removeShopAtTile(worldobjects)
    local _, entry = Client.findShopCategory(worldobjects)
    if not entry or not entry.id then
        Client.showMessage(T("UI_rogue_shop_remove_none"))
        return
    end
    sendClientCommand("Rogue", "removeShop", { id = entry.id })
end

function Client.toggleScorePanel()
    Client._scoreVisible = not Client._scoreVisible
    if not Client._scoreVisible then
        if Client._score and Client._score.panel then
            Client._score.panel:setVisible(false)
        end
    else
        if Client._lastScore then
            Client.applyScorePanel(Client._lastScore)
        end
    end
end

function Client.toggleScorePanelEsc()
    if Client._scoreEscTemp then
        Client._scoreEscTemp = false
        if Client._scoreEscPrevVisible == nil then
            Client._scoreEscPrevVisible = false
        end
        Client._scoreVisible = Client._scoreEscPrevVisible
        Client._scoreEscPrevVisible = nil
        if not Client._scoreVisible then
            if Client._score and Client._score.panel then
                Client._score.panel:setVisible(false)
            end
        end
        return
    end
    Client._scoreEscPrevVisible = Client._scoreVisible
    Client._scoreEscTemp = true
    Client._scoreVisible = true
    local score = Client.ensureScorePanel()
    if score and score.panel then
        score.panel:setVisible(true)
        if score.panel.bringToTop then
            score.panel:bringToTop()
        end
    end
    if Client._lastScore then
        Client.applyScorePanel(Client._lastScore)
    else
        Client.requestScore()
    end
end

function Client.toggleWalletPanel()
    Client._walletVisible = not Client._walletVisible
    if not Client._walletVisible then
        if Client._wallet and Client._wallet.panel then
            Client._wallet.panel:setVisible(false)
        end
    else
        if Client._lastScore then
            Client.updateWalletPanel(Client._lastScore.wallet or 0)
        end
    end
end

function Client.formatTime(seconds)
    local s = math.max(0, math.floor(tonumber(seconds) or 0))
    local m = math.floor(s / 60)
    local r = s % 60
    return string.format("%02d:%02d", m, r)
end

function Client.updateHud(state, args)
    local hud = Client.ensureHud()
    local status = state or "IDLE"
    local prevStatus = Client._lastStatus
    local roundIndex = args and args.roundIndex or 0
    local elapsedSec = args and args.elapsedSec or 0
    local newElapsed = tonumber(elapsedSec) or 0
    if status == (Client._lastHudStatus or "") and roundIndex == (Client._lastHudRound or 0) then
        local lastElapsed = Client._lastHudElapsed or 0
        if lastElapsed > 0 and (newElapsed == 0 or newElapsed < lastElapsed) then
            return
        end
    end
    if status ~= "IDLE" and newElapsed == 0 then
        local now = getTimestampMs()
        if now - (Client._hudZeroLogAtMs or 0) > 3000 then
            Client._hudZeroLogAtMs = now
            print(string.format("[Roguelityno][Client] hud elapsed=0 status=%s round=%s",
                tostring(status), tostring(roundIndex)))
        end
    end
    Client._lastHudStatus = status
    Client._lastHudRound = roundIndex
    Client._lastHudElapsed = newElapsed
    Client._lastStatus = status
    if prevStatus and prevStatus ~= status and status == "PREP" then
        if Client._prepReadyActive then
            Client.setPrepReady(false)
        end
    end
    if status == "IDLE" then
        hud.panel:setVisible(false)
        Client._miniMapOpenedForRun = false
        return
    end
    if status ~= "PREP" and status ~= "LOBBY" then
        Client._prepReadyActive = false
        Client._prepReadyRound = nil
    elseif Client._prepReadyRound ~= roundIndex then
        Client._prepReadyRound = roundIndex
        Client._prepReadyActive = false
    end
    if status ~= "PREP" then
        Client._prepCountdownRound = nil
    else
        local cfg = Rogue.Config or {}
        local prepSeconds = tonumber(cfg.PREP_SECONDS) or 0
        local threshold = tonumber(cfg.PREP_COUNTDOWN_SECONDS) or 20.6
        if prepSeconds > 0 then
            local remaining = prepSeconds - newElapsed
            if remaining <= threshold and remaining > 0 then
                if Client._prepCountdownRound ~= roundIndex then
                    Client._prepCountdownRound = roundIndex
                    Client.playUISound("prep_countdown")
                end
            end
        end
    end
    local overtimeHud = status == "WAVE" and Client._overtimeLoopActive
    if hud.label and hud.label.label then
        if overtimeHud then
            hud.label.label.r, hud.label.label.g, hud.label.label.b, hud.label.label.a = 1, 0, 0, 1
        else
            local textColor = Client.getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
            hud.label.label.r, hud.label.label.g, hud.label.label.b, hud.label.label.a =
                textColor.r, textColor.g, textColor.b, textColor.a
        end
    end
    if hud.label and hud.label.shadow then
        if overtimeHud then
            hud.label.shadow.r, hud.label.shadow.g, hud.label.shadow.b, hud.label.shadow.a = 0.95, 0.83, 0.15, 1
        else
            local sr, sg, sb = 0, 0, 0
            if status == "WAVE" then
                sr, sg, sb = 0.85, 0.1, 0.1
            end
            hud.label.shadow.r = sr
            hud.label.shadow.g = sg
            hud.label.shadow.b = sb
            hud.label.shadow.a = 1
        end
    end
    local elapsed = Client.formatTime(elapsedSec)
    local diffLabel = Client.getDifficultyLabel(Rogue.Config and Rogue.Config.DIFFICULTY_LEVEL or 1)
    local statusLabel = Client.getStatusLabel(status)
    local text = ""
    if status == "WAVE" and overtimeHud then
        text = string.format("%s | %s %d | %s: %d/%d",
            T("UI_rogue_hud_overtime_death"),
            T("UI_rogue_hud_round"),
            tonumber(args.roundIndex or 0),
            T("UI_rogue_hud_kills"),
            tonumber(args.kills or 0),
            tonumber(args.killTarget or 0)
        )
    elseif status == "WAVE" then
        text = string.format("%s | %s | %s %d | %s | %s: %d/%d",
            tostring(diffLabel),
            statusLabel,
            T("UI_rogue_hud_round"),
            tonumber(args.roundIndex or 0),
            elapsed,
            T("UI_rogue_hud_kills"),
            tonumber(args.kills or 0),
            tonumber(args.killTarget or 0)
        )
    elseif status == "LOBBY" then
        local arenaName = tostring(args.arenaZoneName or "")
        if arenaName:sub(1, 3) == "RA_" then
            arenaName = arenaName:sub(4)
        end
        if arenaName == "" then
            arenaName = "?"
        end
        local mapLabel = T("UI_rogue_hud_map")
        if mapLabel == "UI_rogue_hud_map" then
            mapLabel = "Map"
        end
        text = string.format("%s | %s | %s",
            tostring(diffLabel),
            statusLabel,
            string.format("%s: %s", mapLabel, arenaName)
        )
    else
        text = string.format("%s | %s | %s %d | %s",
            tostring(diffLabel),
            statusLabel,
            T("UI_rogue_hud_round"),
            tonumber(args.roundIndex or 0),
            elapsed
        )
    end
    Client.setShadowLabelText(hud.label, text)
    if hud.readyBtn then
        local showReady = status == "PREP" or status == "LOBBY"
        hud.readyBtn:setVisible(showReady)
        Client.setShadowLabelVisible(hud.readyLabel, showReady)
        if showReady then
            local readyCount = tonumber(args and args.prepReady or 0) or 0
            local readyTotal = tonumber(args and args.prepEligible or 0) or 0
            local readyText = string.format("%s: %d/%d", T("UI_rogue_hud_ready"), readyCount, readyTotal)
            Client.setShadowLabelText(hud.readyLabel, readyText)
            local btnText = Client._prepReadyActive and T("UI_rogue_prep_ready_on") or T("UI_rogue_prep_ready")
            if hud.readyBtn.setTitle then
                hud.readyBtn:setTitle(btnText)
            end
        end
    end
    hud.panel:setVisible(true)
    if status == "LOBBY" then
        Client.openMiniMapInLobby()
    end
end

function Client.showBanner(text, color, durationMs)
    if not text or text == "" then return end
    local banner = Client.ensureBanner()
    local label = banner.label
    Client.setShadowLabelText(label, text)
    local font = Client.getUIFont("large")
    if getTextManager and getTextManager().MeasureStringX then
        local tm = getTextManager()
        local maxW = banner.panel.width - 40
        local w = tm:MeasureStringX(font, text)
        if w > maxW then
            font = Client.getUIFont("medium")
            w = tm:MeasureStringX(font, text)
        end
        if w > maxW then
            font = Client.getUIFont("small")
            w = tm:MeasureStringX(font, text)
        end
        if label.label and label.label.setFont then
            label.label:setFont(font)
        end
        if label.shadow and label.shadow.setFont then
            label.shadow:setFont(font)
        end
        local x = math.max(10, math.floor((banner.panel.width - w) / 2))
        local y = 20 + (Client.BANNER_PAD_Y or 0)
        if label.label then
            label.label:setX(x)
            label.label:setY(y)
        end
        if label.shadow then
            label.shadow:setX(x + 1)
            label.shadow:setY(y + 1)
        end
    end
    if color then
        if label.label then
            label.label.r = color.r or 1
            label.label.g = color.g or 1
            label.label.b = color.b or 1
            label.label.a = color.a or 1
        end
    else
        local textColor = Client.getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
        if label.label then
            label.label.r, label.label.g, label.label.b, label.label.a =
                textColor.r, textColor.g, textColor.b, textColor.a
        end
    end
    local cfg = Rogue.Config or {}
    banner.endTimeMs = getTimestampMs() + (durationMs or cfg.UI_BANNER_DURATION_MS or 4000)
    banner.panel:setVisible(true)
end

function Client.isPlayerInSafe(player)
    if not Rogue or not Rogue.Config then return true end
    local cfg = Rogue.Config
    if not cfg.isRectValid or not cfg.isRectValid(cfg.ZONES.SAFE) then
        return true
    end
    local rect = cfg.ZONES.SAFE
    local x1 = math.min(rect.x1, rect.x2)
    local x2 = math.max(rect.x1, rect.x2)
    local y1 = math.min(rect.y1, rect.y2)
    local y2 = math.max(rect.y1, rect.y2)
    local z = rect.z
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    if z ~= nil and pz ~= z then return false end
    return px >= x1 and px <= x2 and py >= y1 and py <= y2
end

function Client.isPlayerInSpawn(player)
    if not Rogue or not Rogue.Config then return true end
    local cfg = Rogue.Config
    if not cfg.isRectValid or not cfg.isRectValid(cfg.ZONES.SPAWN) then
        return true
    end
    local rect = cfg.ZONES.SPAWN
    local x1 = math.min(rect.x1, rect.x2)
    local x2 = math.max(rect.x1, rect.x2)
    local y1 = math.min(rect.y1, rect.y2)
    local y2 = math.max(rect.y1, rect.y2)
    local z = rect.z
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    if z ~= nil and pz ~= z then return false end
    return px >= x1 and px <= x2 and py >= y1 and py <= y2
end

function Client.rebuildShopMarkers()
    Client._shopMarkers = {}
    if not Client._shopObjects then return end
    local entries = Client._shopObjects.entries or {}
    for i = 1, #entries do
        local data = entries[i]
        if data and data.key then
            local x, y, z = string.match(tostring(data.key), "([^,]+),([^,]+),([^,]+)")
            x = tonumber(x)
            y = tonumber(y)
            z = tonumber(z)
            if x and y and z then
                local label = Client.getCategoryLabel(data.category)
                if data.category == "builds" then
                    label = T("UI_rogue_build_shop")
                end
                if data.name and data.name ~= "" then
                    label = string.format("%s - %s", label, data.name)
                end
                table.insert(Client._shopMarkers, {
                    category = data.category,
                    label = label,
                    x = x,
                    y = y,
                    z = z,
                    nextAtMs = 0,
                })
            end
        end
    end
    local now = getTimestampMs()
    if now - (Client._shopMarkerLogAtMs or 0) > 3000 then
        Client._shopMarkerLogAtMs = now
        print(string.format("[Roguelityno][ShopMarkers] rebuild entries=%d markers=%d",
            tonumber(#entries), tonumber(#Client._shopMarkers)))
    end
end

function Client.clearShopWorldMarkers()
    if not WorldMarkers or not WorldMarkers.instance then return end
    local wm = WorldMarkers.instance
    for i = 1, #Client._shopWorldMarkers do
        local marker = Client._shopWorldMarkers[i]
        if marker then
            pcall(wm.removeGridSquareMarker, wm, marker)
        end
    end
    Client._shopWorldMarkers = {}
    if Client._shopLights and #Client._shopLights > 0 then
        local cell = getCell()
        if cell and cell.removeLamppost then
            for i = 1, #Client._shopLights do
                pcall(cell.removeLamppost, cell, Client._shopLights[i])
            end
        end
    end
    Client._shopLights = {}
    Client._shopMarkerActive = false
    Client._shopMarkerStatus = nil
end

function Client.createShopWorldMarkers(status)
    if not WorldMarkers or not WorldMarkers.instance then return end
    local wm = WorldMarkers.instance
    Client._shopWorldMarkers = {}
    Client._shopLights = {}
    local size = (Rogue.Config and Rogue.Config.SHOP_MARKER_SIZE) or Client.SHOP_MARKER_SIZE or 0.65
    local texByCat = Rogue.Config and Rogue.Config.SHOP_MARKER_TEX_BY_CATEGORY or {}
    local colorByCat = Rogue.Config and Rogue.Config.SHOP_MARKER_COLOR_BY_CATEGORY or {}
    local glowCfg = Rogue.Config and Rogue.Config.SHOP_TILE_GLOW or {}
    local glowEnabled = glowCfg.enabled ~= false
    local glowRadius = tonumber(glowCfg.radius) or 6
    local glowBoost = tonumber(glowCfg.colorBoost) or 0.0
    for i = 1, #Client._shopMarkers do
        local m = Client._shopMarkers[i]
        if status == "LOBBY" and m.category ~= "builds" then
            -- only build shop in lobby
        else
            local square = getCell():getGridSquare(m.x, m.y, m.z)
            if square then
                local color = colorByCat[m.category] or {}
                local r = tonumber(color.r) or 0.0
                local g = tonumber(color.g) or 1.0
                local b = tonumber(color.b) or 0.4
                local tex = texByCat[m.category] or Client.SHOP_MARKER_TEX or (Rogue.Config and Rogue.Config.SHOP_MARKER_TEX) or nil
                local texOk = false
                if tex and getTexture then
                    texOk = getTexture(tex) ~= nil
                end
                local function addMarkerAt(sq)
                    if not sq then return end
                    local marker = nil
                    if tex and texOk then
                        marker = wm:addGridSquareMarker(tex, nil, sq, r, g, b, true, size)
                    else
                        marker = wm:addGridSquareMarker(sq, r, g, b, true, size)
                    end
                    if marker then
                        table.insert(Client._shopWorldMarkers, marker)
                    end
                end
                addMarkerAt(square)
                if glowEnabled and getCell and glowRadius > 0 then
                    local cell = getCell()
                    if cell and cell.addLamppost then
                        local rr = math.min(1.0, r + glowBoost)
                        local gg = math.min(1.0, g + glowBoost)
                        local bb = math.min(1.0, b + glowBoost)
                        local ok, light = pcall(cell.addLamppost, cell, m.x, m.y, m.z, rr, gg, bb, glowRadius)
                        if ok and light then
                            table.insert(Client._shopLights, light)
                        end
                    end
                end
            end
        end
    end
    Client._shopMarkerActive = true
    Client._shopMarkerStatus = status
end

function Client.updateShopWorldMarkers()
    local now = getTimestampMs()
    if now < (Client._shopMarkerNextAtMs or 0) then return end
    Client._shopMarkerNextAtMs = now + (Client.SHOP_MARKER_TICK_MS or 1000)

    if not Client._shopMarkers or #Client._shopMarkers == 0 then
        if Client._shopMarkerActive then
            Client.clearShopWorldMarkers()
        end
        if now - (Client._shopMarkerLogAtMs or 0) > 3000 then
            Client._shopMarkerLogAtMs = now
            print("[Roguelityno][ShopMarkers] none to draw (no markers)")
        end
        return
    end
    local status = (Client._lastScore and Client._lastScore.status) or Client._lastStatus
    if not status or (status ~= "PREP" and status ~= "LOBBY") then
        if Client._shopMarkerActive then
            Client.clearShopWorldMarkers()
        end
        if now - (Client._shopMarkerLogAtMs or 0) > 3000 then
            Client._shopMarkerLogAtMs = now
            print(string.format("[Roguelityno][ShopMarkers] hidden status=%s", tostring(status)))
        end
        return
    end
    if (not Client._shopMarkerActive) or (Client._shopMarkerStatus ~= status) then
        Client.clearShopWorldMarkers()
        Client.createShopWorldMarkers(status)
    end
end

function Client.onTick()
    if Client._invRefreshAtMs and getTimestampMs() >= Client._invRefreshAtMs then
        Client.refreshInventoryUI()
        local left = tonumber(Client._invRefreshLeft) or 1
        left = left - 1
        if left > 0 then
            Client._invRefreshLeft = left
            Client._invRefreshAtMs = getTimestampMs() + (Client._invRefreshIntervalMs or 250)
        else
            Client._invRefreshAtMs = nil
            Client._invRefreshLeft = nil
            Client._invRefreshIntervalMs = nil
        end
    end
    if Client._banner and Client._banner.panel and Client._banner.panel:getIsVisible() then
        if getTimestampMs() >= (Client._banner.endTimeMs or 0) then
            Client._banner.panel:setVisible(false)
        end
    end
    if Client._bogdanoLocalUntilMs then
        if getTimestampMs() >= Client._bogdanoLocalUntilMs then
            local player = getPlayer()
            if player and player.getStats then
                local stats = player:getStats()
                if stats and stats.reset then
                    pcall(stats.reset, stats, CharacterStat.INTOXICATION)
                end
            end
            Client._bogdanoLocalUntilMs = nil
        end
    end
    if Client._overtimeLoopActive then
        local now = getTimestampMs()
        if now >= (Client._overtimeNextAtMs or 0) then
            Client.playUISound("round_overtime")
            local cfg = Rogue.Config or {}
            local loopMs = tonumber(cfg.ROUND_OVERTIME_LOOP_MS) or 15000
            Client._overtimeNextAtMs = now + math.max(1000, loopMs)
        end
    end
    do
        local now = getTimestampMs()
        local status = Client._lastStatus
        local rect = Client.getArenaRect()
        local player = getPlayer()
        local outside = false
        if status == "WAVE" and rect and player then
            local px, py, pz = player:getX(), player:getY(), player:getZ()
            local rz = rect.z or 0
            outside = (pz ~= rz or px < rect.x1 or px > rect.x2 or py < rect.y1 or py > rect.y2)
        end
        if outside and player and Rogue and Rogue.Config then
            local ignoreName = Rogue.Config.OUTSIDE_IGNORE_TIERZONE
            if ignoreName and ignoreName ~= "" and Rogue.Config.ZONES and Rogue.Config.ZONES.SPAWN then
                local s = Rogue.Config.ZONES.SPAWN
                local sz = s.z or 0
                local px, py, pz = player:getX(), player:getY(), player:getZ()
                if pz == sz and px >= s.x1 and px <= s.x2 and py >= s.y1 and py <= s.y2 then
                    outside = false
                end
            end
        end
        if outside then
            if now >= (Client._outsideSoundNextAtMs or 0) then
                Client.playUISound("out_of_bounds")
                local loopMs = tonumber(Rogue.Config and Rogue.Config.OUTSIDE_SOUND_LOOP_MS) or 3000
                Client._outsideSoundNextAtMs = now + math.max(500, loopMs)
            end
            Client._outsideSoundActive = true
        else
            if Client._outsideSoundActive then
                Client.stopUISound("out_of_bounds")
            end
            Client._outsideSoundActive = false
            Client._outsideSoundNextAtMs = 0
        end
    end
    Client.updateArenaBorderMarkers()
    Client.updateShopWorldMarkers()
    Client.updateLastZombieMinimap()
end

function Client.showMessage(text)
    if not text then return end
    local msg = tostring(text)
    local shown = false

    if getChatManager then
        local cm = getChatManager()
        if cm and cm.showServerChatMessage then
            cm:showServerChatMessage(msg)
            shown = true
        end
    end

    -- HaloTextHelper disabled (head halo).
    -- if HaloTextHelper then
    --     local player = getPlayer()
    --     if player then
    --         local ok = false
    --         if HaloTextHelper.addBadText then
    --             ok = pcall(HaloTextHelper.addBadText, player, msg)
    --         elseif HaloTextHelper.addText then
    --             ok = pcall(HaloTextHelper.addText, player, msg, " ", 255, 0, 0)
    --         end
    --         if ok then
    --             shown = true
    --         end
    --     end
    -- end

    if not shown then
        print("[Roguelityno] " .. msg)
    end
end

function Client.getDifficultyLabel(diffId)
    local list = Rogue.Config and Rogue.Config.DIFFICULTY_PRESETS or {}
    local id = tonumber(diffId) or 1
    for i = 1, #list do
        local entry = list[i]
        if entry and entry.id == id then
            return entry.labelKey and T(entry.labelKey) or tostring(id)
        end
    end
    return tostring(id)
end

function Client.getStatusLabel(status)
    if status == "LOBBY" then
        return T("UI_rogue_status_lobby")
    end
    if status == "PREP" then
        return T("UI_rogue_status_prep")
    end
    if status == "POST" then
        return T("UI_rogue_status_post")
    end
    if status == "WAVE" then
        return T("UI_rogue_status_wave")
    end
    if status == "IDLE" then
        return T("UI_rogue_status_idle")
    end
    return tostring(status)
end

function Client.localizeAnnouncement(text)
    local msg = tostring(text or "")
    local diff, live, mr = msg:match("^ROGUELITYNO run started: difficulty=(%d+) livePlayers=(%d+) maxRounds=(%d+)")
    if diff and live and mr then
        local diffLabel = Client.getDifficultyLabel(diff)
        return T("UI_rogue_announce_run_started", diffLabel, live, mr)
    end
    if msg == "ROGUELITYNO stopped." then
        return T("UI_rogue_announce_stopped")
    end
    local round = msg:match("^PREP started for round%s+(%d+)")
    if round then
        return T("UI_rogue_announce_prep_started", round)
    end
    local time, tier, target = msg:match("^CLEARED!%s+Time:%s*(%d+)s,%s*TierEnd:%s*T(%d+),%s*Target:%s*(%d+)")
    if time and tier and target then
        return T("UI_rogue_announce_cleared", time, tier, target)
    end
    if msg == "FAILED! All players down." then
        return T("UI_rogue_announce_failed")
    end
    if msg == "RUN COMPLETE!" then
        return T("UI_rogue_announce_complete")
    end
    if msg:find("^OVERTIME!") then
        return T("UI_rogue_announce_overtime")
    end
    local tierUp = msg:match("^Tier%s*%-%>%s*T(%d+)")
    if tierUp then
        return T("UI_rogue_announce_tier", tierUp)
    end
    if msg == "Return to the arena!" then
        return T("UI_rogue_announce_return_arena")
    end
    if msg == "You are bleeding out outside the arena!" then
        return T("UI_rogue_announce_bleeding_out")
    end
    return msg
end

function Client.showAnnouncement(text)
    local msg = Client.localizeAnnouncement(text)
    Client.showMessage(msg)
    Client.showBanner(msg, nil, 4500)
end

function Client.onServerCommand(module, command, args)
    if module ~= "Rogue" then return end
    if command == "notify" and args and args.text then
        Client.showMessage(args.text)
    elseif command == "announce" and args and args.text then
        Client.showAnnouncement(args.text)
        local text = tostring(args.text or "")
        if text:find("PREP started") then
            Client.playUISound("round_prep")
        elseif text:find("ROUND ") then
            Client.playUISound("round_start")
        elseif text:find("CLEARED!") then
            Client.playUISound("round_clear")
            Client._overtimeLoopActive = false
            Client._overtimeNextAtMs = 0
            Client.stopUISound("round_overtime")
            Client.stopUISound("round_overtime_announce")
            Client.stopUISound("round_overtime_soon")
        elseif text:find("OVERTIME!") then
            Client.playUISound("round_overtime")
            Client.playUISound("round_overtime_announce")
            Client._overtimeLoopActive = true
            Client._overtimeNextAtMs = getTimestampMs() + 1
        end
    elseif command == "roundOvertimeSoon" then
        Client.playUISound("round_overtime_soon")
    elseif command == "prepReady" and args then
        Client._prepReadyActive = args.ready and true or false
        local hud = Client._hud
        if hud and hud.panel and hud.panel:isVisible() and Client._lastHudArgs then
            Client.updateHud(Client._lastStatus, Client._lastHudArgs)
        end
    elseif command == "hud" and args then
        Client._lastHudArgs = args
        Client.updateHud(args.status, args)
        if args.status ~= "WAVE" then
            Client._overtimeLoopActive = false
            Client._overtimeNextAtMs = 0
            Client.stopUISound("round_overtime")
            Client.stopUISound("round_overtime_announce")
            Client.stopUISound("round_overtime_soon")
        end
        Client._buildSelectorShown = false
    elseif command == "clientTeleport" and args then
        local player = getPlayer()
        local x = tonumber(args.x) or 0
        local y = tonumber(args.y) or 0
        local z = tonumber(args.z) or 0
        if WL_Utils and WL_Utils.teleportPlayerToCoords then
            WL_Utils.teleportPlayerToCoords(player, x, y, z)
        else
            if player then
                player:setX(x)
                player:setY(y)
                if player.setLx then player:setLx(x) end
                if player.setLy then player:setLy(y) end
                if player.setLastX then player:setLastX(x) end
                if player.setLastY then player:setLastY(y) end
                player:setZ(z)
                if player.setLastZ then player:setLastZ(z) end
            end
        end
        Client.queueInventoryRefresh("teleport", 500, 5, 500)
    elseif command == "score" and args then
        Client._lastScore = args
        if args.status ~= "IDLE" then
            Client.applyScorePanel(args)
        else
            if Client._score and Client._score.panel then
                Client._score.panel:setVisible(false)
            end
        end
    elseif command == "shopStock" and args then
        local category = args.category
        if category then
            Client._shopStock[category] = args.stock or {}
            if Client._shopPanel and Client._shopPanel._category == category then
                Client.updateShopTooltips(Client._shopPanel)
            end
        end
    elseif command == "mapList" and args then
        Client._mapList = args.items or {}
    elseif command == "buildId" and args then
        Client._buildId = args.id
        local player = getPlayer()
        if player and player.getModData then
            local md = player:getModData()
            md.RogueBuildId = args.id
        end
        print(string.format("[Roguelityno][BuildId] recv=%s",
            tostring(args.id)
        ))
    elseif command == "debugHealth" and args then
        print(string.format("[Roguelityno][DebugHealth] server=%s",
            tostring(args.health)
        ))
    elseif command == "invRefresh" and args then
        local delayMs = args and args.delayMs or 250
        local tries = args and args.tries or 3
        local intervalMs = args and args.intervalMs or 250
        Client.queueInventoryRefresh("server", delayMs, tries, intervalMs)
    elseif command == "shopBuyResult" and args then
        if args.ok then
            Client.playUISound("shop_buy_ok", args.category)
        else
            Client.playUISound("shop_buy_fail", args.category)
        end
    elseif command == "bogdanoEffect" and args then
        local player = getPlayer()
        local target = tonumber(args.target) or 35.0
        local seconds = tonumber(args.seconds) or 30
        local alcohol = tonumber(args.alcohol)
        print(string.format("[Roguelityno][BogdanoDrink] client cmd target=%s seconds=%s alcohol=%s",
            tostring(target),
            tostring(seconds),
            tostring(alcohol)
        ))
        if player and player.getStats then
            local stats = player:getStats()
            if stats and stats.set then
                pcall(stats.set, stats, CharacterStat.INTOXICATION, target)
                local okV, val = pcall(stats.get, stats, CharacterStat.INTOXICATION)
                print(string.format("[Roguelityno][BogdanoDrink] client cmd set intox=%s",
                    tostring(okV and val or "nil")
                ))
            end
        end
        if player and player.getBodyDamage then
            local bd = player:getBodyDamage()
            if bd and bd.JustDrankBoozeFluid then
                local booze = alcohol or tonumber((Rogue.Config and Rogue.Config.BOGDANO_ALCOHOL) or 0.08) or 0.08
                pcall(bd.JustDrankBoozeFluid, bd, booze)
            end
        end
        Client._bogdanoLocalUntilMs = getTimestampMs() + (math.max(1, seconds) * 1000)
    elseif command == "roundRewardChoices" and args then
        Client.openRewardPanel(args)
    elseif command == "roundRewardApplied" and args then
        if args.ok then
            Client.showMessage(T("UI_rogue_reward_applied"))
        else
            Client.showMessage(T("UI_rogue_reward_failed"))
        end
    elseif command == "roundRewardRerollResult" and args then
        if args.ok then
            Client.playUISound("reward_reroll")
            Client.showMessage(T("UI_rogue_reward_reroll_ok"))
        else
            local key = "UI_rogue_reward_reroll_failed"
            if args.error == "funds" then
                key = "UI_rogue_reward_reroll_fail_funds"
                Client.playUISound("shop_buy_fail")
            elseif args.error == "limit" then
                key = "UI_rogue_reward_reroll_fail_limit"
            elseif args.error == "disabled" then
                key = "UI_rogue_reward_reroll_fail_disabled"
            elseif args.error == "stale" then
                key = "UI_rogue_reward_reroll_fail_stale"
            end
            Client.showMessage(T(key))
        end
    elseif command == "buildBuyResult" and args then
        if args.ok then
            Client.playUISound("build_buy_ok", "builds")
        else
            Client.playUISound("build_buy_fail", "builds")
        end
    elseif command == "weaponModResult" and args then
        if args.ok then
            Client.showMessage(T("UI_rogue_weaponmod_ok"))
        else
            local key = "UI_rogue_weaponmod_failed"
            if args.reason == "slot_full" then
                key = "UI_rogue_weaponmod_slot_full"
            elseif args.reason == "kit_incompatible" then
                key = "UI_rogue_weaponmod_kit_incompatible"
            elseif args.reason == "bad_weapon" then
                key = "UI_rogue_weaponmod_bad_weapon"
            end
            Client.showMessage(T(key))
        end
    elseif command == "weaponScrapResult" and args then
        if args.ok then
            Client.showMessage(T("UI_rogue_weaponscrap_ok"))
        else
            local key = "UI_rogue_weaponscrap_failed"
            if args.reason == "not_mr_rumble" then
                key = "UI_rogue_weaponscrap_not_rumble"
            elseif args.reason == "not_eligible" then
                key = "UI_rogue_weaponscrap_not_eligible"
            end
            Client.showMessage(T(key))
        end
    end
end

function Client.openStartPanel(player)
    if Client._startPanel and Client._startPanel:getIsVisible() then return end

    local w, h = 360, 296
    local x = (getCore():getScreenWidth() / 2) - (w / 2)
    local y = (getCore():getScreenHeight() / 2) - (h / 2)

    local panel = ISPanel:new(x, y, w, h)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    panel:setAlwaysOnTop(true)
    if panel.setMovable then panel:setMovable(true) end
    if panel.setMoveWithMouse then panel:setMoveWithMouse(true) end
    Client.enablePanelDrag(panel, "start")
    panel.backgroundColor = Client.getUIColor("UI_COLOR_BG", { r = 0, g = 0, b = 0, a = 0.7 })
    panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }

    local textColor = Client.getUIColor("UI_COLOR_TEXT", { r = 1, g = 1, b = 1, a = 1 })
    local title = ISLabel:new(12 + Client.UI_PAD_X, 8 + Client.UI_PAD_Y, 20, T("UI_rogue_start_title"), textColor.r, textColor.g, textColor.b, textColor.a, Client.getUIFont("medium"), true)
    title:initialise()
    panel:addChild(title)

    local lblPlayers = ISLabel:new(12 + Client.UI_PAD_X, 42 + Client.UI_PAD_Y, 18, T("UI_rogue_target_players"), textColor.r, textColor.g, textColor.b, textColor.a, Client.getUIFont("small"), true)
    lblPlayers:initialise()
    panel:addChild(lblPlayers)

    local entryPlayers = ISTextEntryBox:new("2", 160 + Client.UI_PAD_X, 40 + Client.UI_PAD_Y, 180, 22)
    entryPlayers:initialise()
    entryPlayers:instantiate()
    panel:addChild(entryPlayers)

    local lblRounds = ISLabel:new(12 + Client.UI_PAD_X, 76 + Client.UI_PAD_Y, 18, T("UI_rogue_max_rounds"), textColor.r, textColor.g, textColor.b, textColor.a, Client.getUIFont("small"), true)
    lblRounds:initialise()
    panel:addChild(lblRounds)

    local entryRounds = ISTextEntryBox:new("5", 160 + Client.UI_PAD_X, 74 + Client.UI_PAD_Y, 180, 22)
    entryRounds:initialise()
    entryRounds:instantiate()
    panel:addChild(entryRounds)

    local lblDiff = ISLabel:new(12 + Client.UI_PAD_X, 110 + Client.UI_PAD_Y, 18, T("UI_rogue_difficulty"), textColor.r, textColor.g, textColor.b, textColor.a, Client.getUIFont("small"), true)
    lblDiff:initialise()
    panel:addChild(lblDiff)

    local diffCombo = ISComboBox:new(160 + Client.UI_PAD_X, 108 + Client.UI_PAD_Y, 180, 22)
    diffCombo:initialise()
    panel:addChild(diffCombo)
    local diffList = Rogue.Config and Rogue.Config.DIFFICULTY_PRESETS or {}
    local diffIdxById = {}
    local selectedIndex = 1
    local currentId = Rogue.Config and Rogue.Config.DIFFICULTY_LEVEL or 1
    for i = 1, #diffList do
        local entry = diffList[i]
        local label = entry.labelKey and T(entry.labelKey) or tostring(entry.id)
        diffCombo:addOption(label)
        diffIdxById[entry.id] = i
        if entry.id == currentId then
            selectedIndex = i
        end
    end
    diffCombo.selected = selectedIndex

    local lblArena = ISLabel:new(12 + Client.UI_PAD_X, 144 + Client.UI_PAD_Y, 18, T("UI_rogue_arena_zone"), textColor.r, textColor.g, textColor.b, textColor.a, Client.getUIFont("small"), true)
    lblArena:initialise()
    panel:addChild(lblArena)

    local entryArena = ISTextEntryBox:new("ARENA", 160 + Client.UI_PAD_X, 142 + Client.UI_PAD_Y, 180, 22)
    entryArena:initialise()
    entryArena:instantiate()
    panel:addChild(entryArena)

    local lblSafe = ISLabel:new(12 + Client.UI_PAD_X, 178 + Client.UI_PAD_Y, 18, T("UI_rogue_safe_zone"), textColor.r, textColor.g, textColor.b, textColor.a, Client.getUIFont("small"), true)
    lblSafe:initialise()
    panel:addChild(lblSafe)

    local entrySafe = ISTextEntryBox:new("SAFE", 160 + Client.UI_PAD_X, 176 + Client.UI_PAD_Y, 180, 22)
    entrySafe:initialise()
    entrySafe:instantiate()
    panel:addChild(entrySafe)

    local lblSpawn = ISLabel:new(12 + Client.UI_PAD_X, 212 + Client.UI_PAD_Y, 18, T("UI_rogue_spawn_coord"), textColor.r, textColor.g, textColor.b, textColor.a, Client.getUIFont("small"), true)
    lblSpawn:initialise()
    panel:addChild(lblSpawn)

    local entrySpawn = ISTextEntryBox:new("", 160 + Client.UI_PAD_X, 210 + Client.UI_PAD_Y, 180, 22)
    entrySpawn:initialise()
    entrySpawn:instantiate()
    panel:addChild(entrySpawn)
    entryPlayers:focus()

    local function closePanel()
        panel:setVisible(false)
        panel:removeFromUIManager()
        Client._startPanel = nil
    end

    local function onConfirm()
        local targetPlayers = tonumber(entryPlayers:getText() or "")
        local maxRounds = tonumber(entryRounds:getText() or "")
        if not targetPlayers or not maxRounds then
            Client.showMessage(T("UI_rogue_invalid_numbers", 2, 5))
            return
        end
        local arenaName = entryArena:getText() or ""
        local safeName = entrySafe:getText() or ""
        local spawnCoord = entrySpawn:getText() or ""
        local diffId = diffList[diffCombo.selected] and diffList[diffCombo.selected].id or (Rogue.Config and Rogue.Config.DIFFICULTY_LEVEL or 1)
        sendClientCommand("Rogue", "start", {
            targetPlayers = math.floor(targetPlayers),
            maxRounds = math.floor(maxRounds),
            arenaZoneName = arenaName,
            safeZoneName = safeName,
            spawnCoord = spawnCoord,
            difficulty = diffId,
        })
        closePanel()
    end

    local btnStart = ISButton:new(60 + Client.UI_PAD_X, 244 + Client.UI_PAD_Y, 110, 30, T("UI_rogue_start"), panel, onConfirm)
    btnStart:initialise()
    panel:addChild(btnStart)

    local btnCancel = ISButton:new(190 + Client.UI_PAD_X, 244 + Client.UI_PAD_Y, 110, 30, T("UI_rogue_cancel"), panel, closePanel)
    btnCancel:initialise()
    panel:addChild(btnCancel)

    Client._startPanel = panel
end

function Client.startQuick(player)
    sendClientCommand("Rogue", "start", {
        targetPlayers = 2,
        maxRounds = 5,
        arenaZoneName = "ARENA",
        safeZoneName = "SAFE",
        difficulty = Rogue.Config and Rogue.Config.DIFFICULTY_LEVEL or 1,
    })
end

function Client.stopCommand(player)
    sendClientCommand("Rogue", "stop", {})
end

function Client.statusCommand(player)
    sendClientCommand("Rogue", "status", {})
end

function Client.readyToggle(player)
    sendClientCommand("Rogue", "ready", {})
end

function Client.setPrepReady(ready)
    Client._prepReadyActive = ready and true or false
    sendClientCommand("Rogue", "prepReady", { ready = Client._prepReadyActive })
end

function Client.togglePrepReady()
    Client.setPrepReady(not Client._prepReadyActive)
end

function Client.onWorldContextMenu(player, context, worldobjects)
    if not context then return end
    local now = getTimestampMs()
    if Client._lastContextMenuAt and (now - Client._lastContextMenuAt) < 200 then
        return
    end
    Client._lastContextMenuAt = now
    local p = player
    if type(p) == "number" then
        p = getSpecificPlayer(p)
    end
    if not p then return end

    local category, entry = Client.findShopCategory(worldobjects)
    if category then
        local label = Client.getCategoryLabel(category)
        if entry and entry.name and entry.name ~= "" then
            label = string.format("%s - %s", label, entry.name)
        end
        context:addOption(T("UI_rogue_open_shop", label), p, Client.openShopPanel, category)
    end

    local submenu = context:addOption("Roguelityno")
    if setOptionIcon then
        setOptionIcon(submenu, "media/textures/ui/legendary_symbol.png")
    end
    if not submenu then
        return
    end
    local sub = context:getNew(context)
    context:addSubMenu(submenu, sub)

    local level = p:getAccessLevel() or "none"
    local isAdmin = level and string.lower(level) == "admin"

    if isAdmin then
        sub:addOption(T("UI_rogue_start_quick", 2, 5), p, Client.startQuick)
        sub:addOption(T("UI_rogue_start_custom"), p, Client.openStartPanel)
        sub:addOption(T("UI_rogue_stop"), p, Client.stopCommand)
        sub:addOption(T("UI_rogue_status"), p, Client.statusCommand)
    end
    if Client._lastStatus == "LOBBY" then
        -- Build shop is tied to a tile like other shops.
    end
    sub:addOption(T("UI_rogue_toggle_score"), p, Client.toggleScorePanel)
    sub:addOption(T("UI_rogue_toggle_wallet"), p, Client.toggleWalletPanel)

    if isAdmin then
        local setOpt = sub:addOption(T("UI_rogue_set_shops"))
        local setSub = context:getNew(context)
        context:addSubMenu(setOpt, setSub)
        local labels = Rogue.Config and Rogue.Config.SHOP_CATEGORY_LABELS or {}
        for categoryName, label in pairs(labels) do
            setSub:addOption(label, worldobjects, Client.promptShopForCategory, categoryName)
        end
        sub:addOption(T("UI_rogue_shop_manage"), p, Client.openShopListPanel)
        sub:addOption(T("UI_rogue_shop_remove_here"), worldobjects, Client.removeShopAtTile)
    end
end

Client.patchMiniMapOverlay()

Events.OnServerCommand.Add(Client.onServerCommand)
Events.OnFillWorldObjectContextMenu.Add(Client.onWorldContextMenu)
if Events.OnPreFillWorldObjectContextMenu then
    Events.OnPreFillWorldObjectContextMenu.Add(Client.onWorldContextMenu)
end
Events.OnTick.Add(Client.onTick)
if Events.OnKeyPressed then
    Events.OnKeyPressed.Add(function(key)
        if Keyboard and key == Keyboard.KEY_ESCAPE then
            Client.toggleScorePanelEsc()
        end
    end)
end

local function onReceiveGlobalModData(key, modData)
    if key == "RoguelitynoShopObjects" and type(modData) == "table" then
        Client._shopObjects = Client.normalizeShopObjects(modData)
        Client.rebuildShopMarkers()
        Client.clearShopWorldMarkers()
    elseif key == "RoguelitynoZones" and type(modData) == "table" then
        Rogue.Config = Rogue.Config or {}
        Rogue.Config.ZONES = Rogue.Config.ZONES or {}
        if modData.ARENA then Rogue.Config.ZONES.ARENA = modData.ARENA end
        if modData.SAFE then Rogue.Config.ZONES.SAFE = modData.SAFE end
        if modData.SPAWN then Rogue.Config.ZONES.SPAWN = modData.SPAWN end
    end
end

local function requestShopObjects()
    if ModData and ModData.request then
        ModData.request("RoguelitynoShopObjects")
        ModData.request("RoguelitynoZones")
    end
end

Events.OnReceiveGlobalModData.Add(onReceiveGlobalModData)
Events.OnInitGlobalModData.Add(requestShopObjects)

local function resolveInventoryItem(entry)
    if not entry then return nil end
    if instanceof(entry, "InventoryItem") then
        return entry
    end
    if type(entry) == "table" and entry.items then
        return resolveInventoryItem(entry.items[1])
    end
    return nil
end

local function onSerumContextMenu(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end
    for i = 1, #items do
        local item = resolveInventoryItem(items[i])
        if item and item.getFullType and item:getFullType() == "Rogue.FullRestoreSerum" then
            local opt = context:addOption(T("UI_rogue_use_serum"), player, Client.useFullRestoreSerum, item)
            if setOptionIcon then
                setOptionIcon(opt, "media/textures/Item_FullRestoreSerum_icon.png")
            end
            if context.options and opt then
                table.remove(context.options, #context.options)
                table.insert(context.options, 1, opt)
            end
            return
        end
    end
end

function Client.useFullRestoreSerum(player, item)
    if not player or not item then return end
    print("[Roguelityno][Serum] use by " .. tostring(player and player:getUsername() or "unknown"))
    ISTimedActionQueue.add(RogueFullRestoreAction:new(player, item))
end

Events.OnFillInventoryObjectContextMenu.Add(onSerumContextMenu)

local function onBogdanoContextMenu(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end
    local md = player.getModData and player:getModData() or nil
    local buildId = Client._buildId or (md and md.RogueBuildId or nil)
    print(string.format("[Roguelityno][BogdanoDrink] buildId=%s md=%s",
        tostring(buildId),
        tostring(md and md.RogueBuildId)
    ))
    if buildId ~= "roguelityno:igor" then
        return
    end
    for i = 1, #items do
        local item = resolveInventoryItem(items[i])
        if item and Rogue and Rogue.Bogdano and Rogue.Bogdano.isBottle and Rogue.Bogdano.isBottle(item)
            and Rogue.Bogdano.isBottleFull and Rogue.Bogdano.isBottleFull(item) then
            local opt = context:addOption(T("UI_rogue_bogdano_drink"), player, Client.useBogdanoDrink, item)
            if setOptionIcon then
                setOptionIcon(opt, "media/textures/weapons/1handed/SmashedBottle.png")
            end
            if context.options and opt then
                table.remove(context.options, #context.options)
                table.insert(context.options, 1, opt)
            end
            return
        end
        if item and Rogue and Rogue.Bogdano and Rogue.Bogdano.isBottle and Rogue.Bogdano.isBottle(item) then
            local okW, w = pcall(item.getWeight, item)
            local okA, aw = pcall(item.getActualWeight, item)
            local fullType = item.getFullType and item:getFullType() or "?"
            local container = item.getContainer and item:getContainer() or nil
            local full = Rogue.Bogdano.isBottleFull and Rogue.Bogdano.isBottleFull(item) or false
            print(string.format("[Roguelityno][BogdanoDrink] item=%s weight=%s actual=%s container=%s full=%s",
                tostring(fullType),
                tostring(okW and w or "nil"),
                tostring(okA and aw or "nil"),
                tostring(container ~= nil),
                tostring(full)
            ))
        end
    end
end

function Client.useBogdanoDrink(player, item)
    if not player or not item then return end
    print("[Roguelityno][BogdanoDrink] use by " .. tostring(player and player:getUsername() or "unknown"))
    ISTimedActionQueue.add(RogueBogdanoDrinkAction:new(player, item))
end

Events.OnFillInventoryObjectContextMenu.Add(onBogdanoContextMenu)

if ISInventoryPane and ISInventoryPane.onMouseDoubleClick then
    local _rogue_oldInvDoubleClick = ISInventoryPane.onMouseDoubleClick
    function ISInventoryPane:onMouseDoubleClick(item)
        if item and item.getFullType and item:getFullType() == "Rogue.FullRestoreSerum" then
            local player = self.player or getSpecificPlayer(self.playerNum) or getPlayer()
            if player then
                Client.useFullRestoreSerum(player, item)
                return
            end
        end
        return _rogue_oldInvDoubleClick(self, item)
    end
end
