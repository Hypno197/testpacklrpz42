if not isClient() then return end

pcall(require, "ISUI/ISModalDialog")
pcall(require, "ISUI/ISPanel")
pcall(require, "ISUI/ISLabel")
pcall(require, "ISUI/ISRichTextPanel")

Rogue = Rogue or {}
Rogue.CharCreationLock = Rogue.CharCreationLock or {}
if not Rogue.Config then pcall(require, "RogueConfig") end

local Lock = Rogue.CharCreationLock
Lock._patched = Lock._patched or false
Lock._profPatched = Lock._profPatched or false
Lock._outfitPatched = Lock._outfitPatched or false

local function getUIColor(key, fallback)
    if Rogue.Config and Rogue.Config[key] then
        return Rogue.Config[key]
    end
    return fallback
end

local function getUIFont(size)
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

local function filterProfessions(self, list)
    list:clear()
    if not CharacterProfession then return end
    local profs = nil
    if ProfessionFactory and ProfessionFactory.getProfessions then
        profs = ProfessionFactory.getProfessions()
    end
    if not profs and CharacterProfessionDefinition and CharacterProfessionDefinition.getProfessions then
        profs = CharacterProfessionDefinition.getProfessions()
    end
    if not profs then return end
    if type(profs) == "table" and not profs.size then
        for _, prof in pairs(profs) do
            local ptype = prof and prof:getType()
            if prof and ptype == CharacterProfession.UNEMPLOYED then
                local item = list:addItem(prof:getUIName(), prof)
                item.tooltip = prof:getDescription()
            end
        end
    elseif profs and profs.size and profs.get then
        for i = 0, profs:size() - 1 do
            local prof = profs:get(i)
            local ptype = prof and prof:getType()
            if prof and ptype == CharacterProfession.UNEMPLOYED then
                local item = list:addItem(prof:getUIName(), prof)
                item.tooltip = prof:getDescription()
            end
        end
    end
    list.selected = 1
end

local function collectAllOutfitNames()
    local names = {}
    local function addName(name)
        if name and name ~= "" then
            names[name] = true
        end
    end
    local function countList(list)
        local count = 0
        if not list then return count end
        if type(list) == "table" and not list.size then
            for _, _ in pairs(list) do
                count = count + 1
            end
        elseif list.size and list.get then
            count = list:size()
        end
        return count
    end
    local function addList(list)
        if not list then return end
        if type(list) == "table" and not list.size then
            for _, outfit in pairs(list) do
                if type(outfit) == "string" then
                    addName(outfit)
                elseif outfit and outfit.getName then
                    addName(outfit:getName())
                elseif outfit and outfit.name then
                    addName(outfit.name)
                end
            end
        elseif list.size and list.get then
            for i = 0, list:size() - 1 do
                local outfit = list:get(i)
                if type(outfit) == "string" then
                    addName(outfit)
                elseif outfit and outfit.getName then
                    addName(outfit:getName())
                elseif outfit and outfit.name then
                    addName(outfit.name)
                end
            end
        end
    end
    local maleCount, femaleCount = 0, 0
    if getAllOutfits then
        local maleList = getAllOutfits(false)
        local femaleList = getAllOutfits(true)
        maleCount = countList(maleList)
        femaleCount = countList(femaleList)
        addList(maleList)
        addList(femaleList)
    end
    local out = {}
    for name, _ in pairs(names) do
        table.insert(out, name)
    end
    table.sort(out)
    return out, maleCount, femaleCount
end

local function populateOutfitList(list)
    if not list or not list.clear or not list.addItem then return end
    list:clear()
    list:addItem(getText and getText("UI_characreation_clothing_none") or "None", nil)
    local names, maleCount, femaleCount = collectAllOutfitNames()
    local now = getTimestampMs and getTimestampMs() or 0
    if now - (Lock._outfitCountLoggedAtMs or 0) > 2000 then
        Lock._outfitCountLoggedAtMs = now
        print(string.format("[Roguelityno][Outfits] total=%d male=%d female=%d", #names, maleCount or 0, femaleCount or 0))
    end
    for i = 1, #names do
        list:addItem(names[i], names[i])
    end
    list.selected = 1
end

local function patchOutfitSelection()
    local patched = false
    if CharacterCreationMain and CharacterCreationMain.create then
        local origCreate = CharacterCreationMain.create
        CharacterCreationMain.create = function(self)
            origCreate(self)
            if self.listboxOutfit then
                populateOutfitList(self.listboxOutfit)
            end
            if self.outfitCombo then
                populateOutfitList(self.outfitCombo)
                self._rogueOutfitAll = true
            end
        end
        patched = true
    end
    if CharacterCreationMain and CharacterCreationMain.update then
        local origUpdate = CharacterCreationMain.update
        CharacterCreationMain.update = function(self)
            origUpdate(self)
            if self.outfitCombo and not self._rogueOutfitAll then
                populateOutfitList(self.outfitCombo)
                self._rogueOutfitAll = true
            end
        end
        patched = true
    end
    if patched then
        print("[Roguelityno][Outfits] patchOutfitSelection applied")
    end
    return patched
end

local function hideTraitsUI(self)
    if self.listboxTrait then self.listboxTrait:setVisible(false) end
    if self.listboxBadTrait then self.listboxBadTrait:setVisible(false) end
    if self.listboxTraitSelected then self.listboxTraitSelected:setVisible(false) end
    if self.listboxXpBoost then self.listboxXpBoost:setVisible(false) end
    if self.tooltipRichText then self.tooltipRichText:setVisible(false) end
    if self.titleLabel then self.titleLabel:setVisible(false) end
    if self.title then self.title:setVisible(false) end
    if self.titleLbl then self.titleLbl:setVisible(false) end
    if self.addTraitBtn then self.addTraitBtn:setVisible(false) end
    if self.addBadTraitBtn then self.addBadTraitBtn:setVisible(false) end
    if self.removeTraitBtn then self.removeTraitBtn:setVisible(false) end
    if self.resetButton then self.resetButton:setVisible(false) end
    if self.randomButton then self.randomButton:setVisible(false) end
    if self.infoBtn then self.infoBtn:setVisible(false) end
    if self.presetPanel then self.presetPanel:setVisible(false) end
    if self.savedBuilds then self.savedBuilds:setVisible(false) end
    if self.saveBuildButton then self.saveBuildButton:setVisible(false) end
    if self.deleteBuildButton then self.deleteBuildButton:setVisible(false) end
end

local function hideProfessionUI(self)
    if self.listboxProf then self.listboxProf:setVisible(false) end
    if self.professionLbl then self.professionLbl:setVisible(false) end
    if self.professionLabel then self.professionLabel:setVisible(false) end
    if self.professionTitle then self.professionTitle:setVisible(false) end
end

local function forceHideUI(self)
    hideTraitsUI(self)
    hideProfessionUI(self)
end

local function addInfoText(panel, text, x, y, w, h, textColor)
    if not ISRichTextPanel then return nil end
    local rich = ISRichTextPanel:new(x, y, w, h)
    rich:initialise()
    rich.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    rich.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    if textColor then
        rich.textColor = { r = textColor.r, g = textColor.g, b = textColor.b, a = textColor.a }
    end
    rich:setText(text)
    rich:paginate()
    panel:addChild(rich)
    return rich
end

local function addRespawnStatsPanel(self)
    if Lock._statsPanel and Lock._statsPanel.parent ~= self then
        Lock._statsPanel = nil
    end
    if Lock._statsPanel then return end
    if not ISPanel or not ISLabel then return end

    local w = math.floor((self.width or 800) - 40)
    local h = 220
    local x = 20
    local y = math.floor((self.height or 600) - h - 90)
    local panel = ISPanel:new(x, y, w, h)
    panel:initialise()
    panel.backgroundColor = getUIColor("UI_COLOR_BG", { r = 0, g = 0, b = 0, a = 0.4 })
    panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    panel:setCapture(false)
    if panel.javaObject then
        panel.javaObject:setConsumeMouseEvents(false)
    end
    self:addChild(panel)

    local textColor = getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })

    local function getDifficultyLabel(id)
        local key = nil
        if id == 1 then key = "UI_rogue_difficulty_easy"
        elseif id == 2 then key = "UI_rogue_difficulty_balanced"
        elseif id == 3 then key = "UI_rogue_difficulty_hard"
        elseif id == 4 then key = "UI_rogue_difficulty_extreme"
        elseif id == 5 then key = "UI_rogue_difficulty_executioner"
        end
        return key and getText and getText(key) or tostring(id)
    end

    local function fmtInt(val)
        return tostring(math.floor(tonumber(val) or 0))
    end

    local function fmtFloat(val)
        return string.format("%.2f", tonumber(val) or 0)
    end

    local function addShadowLine(parent, x, y, width, text, value, font, keyColor, keyShadow, valColor, valShadow)
        local keyShadowLbl = ISLabel:new(x + 1, y + 1, 16, text, keyShadow.r, keyShadow.g, keyShadow.b, keyShadow.a, font, true)
        keyShadowLbl:initialise()
        parent:addChild(keyShadowLbl)
        local keyMain = ISLabel:new(x, y, 16, text, keyColor.r, keyColor.g, keyColor.b, keyColor.a, font, true)
        keyMain:initialise()
        parent:addChild(keyMain)

        local tm = getTextManager()
        local valueW = tm and tm.MeasureStringX and tm:MeasureStringX(font, value) or 0
        local valX = math.max(x + 120, (x + width) - valueW - 6)
        local valShadowLbl = ISLabel:new(valX + 1, y + 1, 16, value, valShadow.r, valShadow.g, valShadow.b, valShadow.a, font, true)
        valShadowLbl:initialise()
        parent:addChild(valShadowLbl)
        local valMain = ISLabel:new(valX, y, 16, value, valColor.r, valColor.g, valColor.b, valColor.a, font, true)
        valMain:initialise()
        parent:addChild(valMain)
        return {
            key = keyMain,
            keyShadow = keyShadowLbl,
            val = valMain,
            valShadow = valShadowLbl,
        }
    end

    local function buildStatValues(stats)
        return {
            fmtInt(stats.wins),
            fmtInt(stats.maxRunKills),
            fmtFloat(stats.maxRunDamage),
            fmtFloat(stats.maxRunCurrency),
            fmtInt(stats.maxRoundReached),
            fmtInt(stats.maxRoundKills),
            fmtInt(stats.totalKills),
            fmtInt(stats.totalDeaths),
            fmtFloat(stats.totalDamage),
            fmtFloat(stats.totalCurrency),
        }
    end

    local function addStatsBox(parent, bx, by, bw, bh, title, stats, diffId)
        local box = ISPanel:new(bx, by, bw, bh)
        box:initialise()
        box.backgroundColor = getUIColor("UI_COLOR_BG", { r = 0, g = 0, b = 0, a = 0.25 })
        box.borderColor = { r = 0, g = 0, b = 0, a = 0.1 }
        box:setCapture(false)
        if box.javaObject then
            box.javaObject:setConsumeMouseEvents(false)
        end
        parent:addChild(box)

        local titleFont = getUIFont("medium")
        local tm = getTextManager()
        local titleW = tm and tm.MeasureStringX and tm:MeasureStringX(titleFont, title) or 0
        local titleX = math.max(8, math.floor((bw - titleW) / 2))
        local titleLbl = ISLabel:new(titleX, 6, 18, title, textColor.r, textColor.g, textColor.b, textColor.a, titleFont, true)
        titleLbl:initialise()
        box:addChild(titleLbl)

        local lineFont = getUIFont("small")
        local startY = 30
        local lineH = 16
        local keyColor = getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
        local keyShadow = { r = 0, g = 0, b = 0, a = 1 }
        local valColor = getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
        local valShadow = { r = 0.85, g = 0.1, b = 0.1, a = 1 }
        local lines = {
            { key = getText("UI_rogue_stats_wins") },
            { key = getText("UI_rogue_stats_max_run_kills") },
            { key = getText("UI_rogue_stats_max_run_damage") },
            { key = getText("UI_rogue_stats_max_run_currency") },
            { key = getText("UI_rogue_stats_max_round") },
            { key = getText("UI_rogue_stats_max_round_kills") },
            { key = getText("UI_rogue_stats_total_kills") },
            { key = getText("UI_rogue_stats_total_deaths") },
            { key = getText("UI_rogue_stats_total_damage") },
            { key = getText("UI_rogue_stats_total_currency") },
        }
        local values = buildStatValues(stats)
        for i = 1, #lines do
            local line = addShadowLine(
                box,
                8,
                startY + lineH * (i - 1),
                bw - 16,
                lines[i].key,
                values[i],
                lineFont,
                keyColor,
                keyShadow,
                valColor,
                valShadow
            )
            lines[i].line = line
        end
        if Lock._statsView then
            Lock._statsView.boxes[diffId] = { lines = lines, bw = bw, lineFont = lineFont }
        end
    end

    if ModData and ModData.request then
        ModData.request("RoguelitynoPlayerStats")
    end
    local statsStore = ModData and ModData.getOrCreate and ModData.getOrCreate("RoguelitynoPlayerStats") or {}
    local player = getPlayer()
    local key = "unknown"
    if player then
        local name = player:getUsername()
        if name and name ~= "" then
            key = tostring(name)
        else
            local id = player.getOnlineID and player:getOnlineID() or nil
            if id and id >= 0 then
                key = "id:" .. tostring(id)
            end
        end
    end
    local byDiff = (statsStore[key] and statsStore[key].byDifficulty) or {}

    local cols = 5
    local gap = 12
    local boxW = math.floor((w - gap * (cols + 1)) / cols)
    local boxH = 176
    local startX = gap
    local startY = gap
    Lock._statsView = { panel = panel, boxes = {} }
    Lock._statsOwner = self
    for i = 1, 5 do
        local dx = startX + (i - 1) * (boxW + gap)
        local dy = startY
        local stats = byDiff[i] or {}
        addStatsBox(panel, dx, dy, boxW, boxH, getDifficultyLabel(i), stats, i)
    end

    Lock._statsPanel = panel
end

local function openInfoPanel(self)
    if Lock._infoPanel and Lock._infoPanel.parent ~= self then
        Lock._infoPanel = nil
    end
    if Lock._infoPanel then return end
    if not self then return end
    if not ISPanel or not ISLabel then return end
    local w = self.width or 800
    local h = self.height or 600
    -- Leave space for Back/Next buttons at the bottom.
    local panel = ISPanel:new(10, 10, w - 20, h - 90)
    panel:initialise()
    panel.backgroundColor = getUIColor("UI_COLOR_BG", { r = 0, g = 0, b = 0, a = 0.6 })
    panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    panel:setCapture(false)
    if panel.javaObject then
        panel.javaObject:setConsumeMouseEvents(false)
    end
    self:addChild(panel)

    local title = getText("UI_rogue_info_title") or "La Resistenza Stagione 0: Spinoff"
    local rules = getText("UI_rogue_info_rules") or "Regole:\nLorem ipsum dolor sit amet."
    local mode = getText("UI_rogue_info_mode") or "Modalita':\nLorem ipsum dolor sit amet."
    local howto = getText("UI_rogue_info_howto") or "Come si gioca:\nLorem ipsum dolor sit amet."

    local titleColor = getUIColor("UI_COLOR_ACCENT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
    local bodyColor = getUIColor("UI_COLOR_TEXT", { r = 0.95, g = 0.83, b = 0.15, a = 1 })
    local titleLabel = ISLabel:new(0 + 10, 0 + 10, 24, title, titleColor.r, titleColor.g, titleColor.b, titleColor.a, getUIFont("large"), true)
    titleLabel:initialise()
    panel:addChild(titleLabel)

    local blockW = (panel.width or w) - 20
    addInfoText(panel, rules, 0 + 10, 36 + 10, blockW, 120, bodyColor)
    addInfoText(panel, mode, 0 + 10, 166 + 10, blockW, 120, bodyColor)
    addInfoText(panel, howto, 0 + 10, 296 + 10, blockW, 120, bodyColor)

    Lock._infoPanel = panel
end

local function patchCharacterCreation()
    if Lock._patched then return true end

    if CharacterCreationProfession and not Lock._profPatched then
        local origPopulateProf = CharacterCreationProfession.populateProfessionList
        CharacterCreationProfession.populateProfessionList = function(self, list)
            filterProfessions(self, list)
        end

        local origPopulateTrait = CharacterCreationProfession.populateTraitList
        CharacterCreationProfession.populateTraitList = function(self, list)
            list:clear()
        end

        local origPopulateBadTrait = CharacterCreationProfession.populateBadTraitList
        CharacterCreationProfession.populateBadTraitList = function(self, list)
            list:clear()
        end

        if CharacterCreationProfession.create then
            local origCreate = CharacterCreationProfession.create
            CharacterCreationProfession.create = function(self)
                origCreate(self)
                Lock._infoPanel = nil
                Lock._statsPanel = nil
                forceHideUI(self)
                if self.listboxProf then
                    filterProfessions(self, self.listboxProf)
                    if self.listboxProf.getItem and self.listboxProf:getItem() then
                        self:onSelectProf(self.listboxProf:getItem().item)
                    end
                end
                openInfoPanel(self)
                addRespawnStatsPanel(self)
            end
        end

        if not CharacterCreationProfession._rogueRenderPatched then
            CharacterCreationProfession._rogueRenderPatched = true
            CharacterCreationProfession.render = function(self)
                ISPanelJoypad.render(self)
            end
            local origPre = CharacterCreationProfession.prerender
            CharacterCreationProfession.prerender = function(self)
                if origPre then origPre(self) end
                forceHideUI(self)
            end
        end
        Lock._profPatched = true
    end

    if not Lock._outfitPatched then
        Lock._outfitPatched = patchOutfitSelection()
    end

    if Lock._profPatched and Lock._outfitPatched then
        Lock._patched = true
        return true
    end
    return false
end

local function tryPatch()
    if patchCharacterCreation() then
        if Events and Events.OnTick then
            Events.OnTick.Remove(tryPatch)
        end
    end
end

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(tryPatch)
end
if Events and Events.OnInitWorld then
    Events.OnInitWorld.Add(tryPatch)
end
if Events and Events.OnTick then
    Events.OnTick.Add(tryPatch)
end
if Events and Events.OnReceiveGlobalModData then
    Events.OnReceiveGlobalModData.Add(function(key, modData)
        if key ~= "RoguelitynoPlayerStats" then return end
        if not Lock._statsView or not Lock._statsOwner then return end
        local player = getPlayer()
        local pkey = "unknown"
        if player then
            local name = player:getUsername()
            if name and name ~= "" then
                pkey = tostring(name)
            else
                local id = player.getOnlineID and player:getOnlineID() or nil
                if id and id >= 0 then
                    pkey = "id:" .. tostring(id)
                end
            end
        end
        local data = modData and modData[pkey] and modData[pkey].byDifficulty or {}
        for i = 1, 5 do
            local box = Lock._statsView.boxes[i]
            local stats = data[i] or {}
            if box and box.lines then
                local values = {
                    tostring(math.floor(tonumber(stats.wins) or 0)),
                    tostring(math.floor(tonumber(stats.maxRunKills) or 0)),
                    string.format("%.2f", tonumber(stats.maxRunDamage) or 0),
                    string.format("%.2f", tonumber(stats.maxRunCurrency) or 0),
                    tostring(math.floor(tonumber(stats.maxRoundReached) or 0)),
                    tostring(math.floor(tonumber(stats.maxRoundKills) or 0)),
                    tostring(math.floor(tonumber(stats.totalKills) or 0)),
                    tostring(math.floor(tonumber(stats.totalDeaths) or 0)),
                    string.format("%.2f", tonumber(stats.totalDamage) or 0),
                    string.format("%.2f", tonumber(stats.totalCurrency) or 0),
                }
                for idx = 1, #box.lines do
                    local line = box.lines[idx].line
                    if line and line.val and line.val.setName then
                        line.val:setName(values[idx] or "0")
                    end
                    if line and line.valShadow and line.valShadow.setName then
                        line.valShadow:setName(values[idx] or "0")
                    end
                end
            end
        end
    end)
end
