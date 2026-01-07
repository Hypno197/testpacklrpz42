if not isServer() then return end

require "TimedActions/ISEatFoodAction"
require "TimedActions/ISTakePillAction"

local function itemHasTag(item, tagName)
    if not item or not tagName then return false end
    local target = tostring(tagName):lower()
    local targetBase = "base:" .. target
    local function matches(value)
        local val = tostring(value or ""):lower()
        return val == target or val == targetBase
    end
    if item.getTags then
        local ok, tags = pcall(item.getTags, item)
        if ok and tags then
            if tags.size and tags.get then
                local okSize, size = pcall(tags.size, tags)
                if okSize and size then
                    for i = 0, size - 1 do
                        local okGet, value = pcall(tags.get, tags, i)
                        if okGet and matches(value) then
                            return true
                        end
                    end
                end
            elseif type(tags) == "table" then
                for _, value in ipairs(tags) do
                    if matches(value) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function restoreEnduranceIfBogdano(action)
    local player = action and action.character or nil
    if not player or not player.getModData then return end
    local md = player:getModData()
    if not md then return end
    if md.RogueBuildId ~= (Rogue and Rogue.Config and Rogue.Config.BUILD_ID_BOGDANO or "roguelityno:igor") then
        return
    end
    local item = action and action.item or nil
    local function isSmokable(it)
        if itemHasTag(it, "smokable") then return true end
        if it and it.getEatType then
            local okEat, eatType = pcall(it.getEatType, it)
            if okEat and eatType == "Cigarettes" then
                return true
            end
        end
        if it and it.getCustomMenuOption then
            local okMenu, menu = pcall(it.getCustomMenuOption, it)
            if okMenu and menu == "Smoke" then
                return true
            end
        end
        return false
    end
    if not isSmokable(item) then
        local fullType = item and item.getFullType and item:getFullType() or "nil"
        local eatType = "nil"
        if item and item.getEatType then
            local okEat, value = pcall(item.getEatType, item)
            if okEat then eatType = tostring(value) end
        end
        local tagsDump = {}
        if item and item.getTags then
            local okTags, tags = pcall(item.getTags, item)
            if okTags and tags then
                if tags.size and tags.get then
                    local okSize, size = pcall(tags.size, tags)
                    if okSize and size then
                        for i = 0, size - 1 do
                            local okGet, value = pcall(tags.get, tags, i)
                            if okGet then
                                tagsDump[#tagsDump + 1] = tostring(value)
                            end
                        end
                    end
                elseif type(tags) == "table" then
                    for _, value in ipairs(tags) do
                        tagsDump[#tagsDump + 1] = tostring(value)
                    end
                end
            end
        end
        print(string.format("[Roguelityno][BogdanoSmoke] not smokable item=%s eatType=%s tags=%s",
            tostring(fullType),
            tostring(eatType),
            table.concat(tagsDump, ",")
        ))
        return
    end
    local stats = player.getStats and player:getStats() or nil
    if stats and stats.add then
        local range = Rogue and Rogue.Config and Rogue.Config.BOGDANO_ENDURANCE_CHANGE_RANGE or nil
        local minVal = range and tonumber(range.min) or 0.5
        local maxVal = range and tonumber(range.max) or 1.0
        if maxVal < minVal then
            minVal, maxVal = maxVal, minVal
        end
        local change = (minVal == maxVal) and minVal or (minVal + (ZombRandFloat(0.0, 1.0) * (maxVal - minVal)))
        pcall(stats.add, stats, CharacterStat.ENDURANCE, change)
        print(string.format("[Roguelityno][BogdanoSmoke] addEndurance item=%s change=%.3f",
            tostring(item and item.getFullType and item:getFullType() or "nil"),
            change
        ))
    end
end

local function isVitamins(item)
    if not item then return false end
    local ft = item.getFullType and item:getFullType() or nil
    return ft == "Base.PillsVitamins"
end

local function restoreEnduranceForVitamins(action)
    local player = action and action.character or nil
    if not player then return end
    local item = action and action.item or nil
    if not isVitamins(item) then return end
    local stats = player.getStats and player:getStats() or nil
    if not stats or not stats.add then return end
    local range = Rogue and Rogue.Config and Rogue.Config.VITAMINS_ENDURANCE_CHANGE_RANGE or nil
    local minVal = range and tonumber(range.min) or 0.05
    local maxVal = range and tonumber(range.max) or 0.1
    if maxVal < minVal then
        minVal, maxVal = maxVal, minVal
    end
    local change = (minVal == maxVal) and minVal or (minVal + (ZombRandFloat(0.0, 1.0) * (maxVal - minVal)))
    pcall(stats.add, stats, CharacterStat.ENDURANCE, change)
    print(string.format("[Roguelityno][Vitamins] addEndurance action=%s item=%s change=%.3f",
        tostring(action and action.__class or "nil"),
        tostring(item and item.getFullType and item:getFullType() or "nil"),
        change
    ))
end

if type(ISEatFoodAction) == "table" then
    local _rogue_old_eat_complete = (type(ISEatFoodAction.complete) == "function")
        and ISEatFoodAction.complete or nil
    function ISEatFoodAction:complete()
        local ok = true
        if type(_rogue_old_eat_complete) == "function" then
            ok = _rogue_old_eat_complete(self)
        end
        restoreEnduranceIfBogdano(self)
        restoreEnduranceForVitamins(self)
        return ok == true
    end
end

if type(ISTakePillAction) == "table" then
    local _rogue_old_take_pill_complete = (type(ISTakePillAction.complete) == "function")
        and ISTakePillAction.complete or nil
    function ISTakePillAction:complete()
        local ok = true
        if type(_rogue_old_take_pill_complete) == "function" then
            ok = _rogue_old_take_pill_complete(self)
        end
        restoreEnduranceForVitamins(self)
        return ok == true
    end
end
