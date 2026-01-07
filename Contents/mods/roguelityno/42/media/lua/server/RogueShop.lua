if not isServer() then return end

Rogue = Rogue or {}
Rogue.Shop = Rogue.Shop or {}

local Shop = Rogue.Shop
if not Rogue.Config then require "RogueConfig" end
local Config = Rogue.Config

local function getState()
    return Rogue.Server and Rogue.Server.state or nil
end

local function parseNumber(value, default)
    if value == nil then return default end
    if type(value) == "string" then
        value = value:gsub(",", ".")
    end
    local n = tonumber(value)
    if n == nil then return default end
    return n
end

local function ceilScaled(value, players)
    local v = parseNumber(value, 0) or 0
    local p = math.max(1, tonumber(players) or 1)
    if v <= 0 then return 0 end
    return math.ceil(v * p)
end

Shop._stock = Shop._stock or {}

function Shop.resetStock()
    Shop._stock = {}
end

function Shop.getStock(category, itemId)
    if not category or not itemId then return nil end
    local cat = Shop._stock[category]
    if not cat then return nil end
    return cat[itemId]
end

function Shop.setStock(category, itemId, amount)
    if not category or not itemId then return end
    Shop._stock[category] = Shop._stock[category] or {}
    if amount == nil then
        Shop._stock[category][itemId] = nil
        return
    end
    Shop._stock[category][itemId] = math.max(0, math.floor(tonumber(amount) or 0))
end

function Shop.getStockSnapshot(category)
    if not category then return {} end
    local lists = Config.SHOP_ITEMS or {}
    local items = lists[category]
    if not items then return {} end
    local snapshot = {}
    for i = 1, #items do
        local entry = items[i]
        local itemId = entry and entry.id or nil
        if itemId then
            local stock = Shop.getStock(category, itemId)
            if stock ~= nil then
                snapshot[itemId] = stock
            end
        end
    end
    return snapshot
end

function Shop.applyRoundStock(roundIndex, playersLive, isInitial)
    local lists = Config.SHOP_ITEMS or {}
    local round = math.max(1, tonumber(roundIndex) or 1)
    local players = math.max(1, tonumber(playersLive) or 1)
    local globalPer = tonumber(Config.SHOP_MAX_STOCK_PER_PLAYER) or 0
    local globalMin = tonumber(Config.SHOP_MAX_STOCK_MIN) or 0
    local globalCap = nil
    if globalPer > 0 or globalMin > 0 then
        globalCap = math.max(globalMin, math.floor(globalPer * players + 0.5))
    end
    for category, items in pairs(lists) do
        if type(items) == "table" then
            for i = 1, #items do
                local entry = items[i]
                local itemId = entry and entry.id or nil
                if itemId then
                    local startRaw = entry.startStockPerPlayer
                    local startPer = parseNumber(startRaw, 0) or 0
                    local restockPer = parseNumber(entry.restockPerPlayer, 0) or 0
                    local restockEvery = math.max(0, math.floor(parseNumber(entry.restockEveryNrounds, 0) or 0))
                    local maxStockRaw = entry.maxStock
                    local maxStock = nil
                    if maxStockRaw ~= nil then
                        maxStock = math.max(0, math.floor(parseNumber(maxStockRaw, 0) or 0))
                    end
                    if isInitial then
                        if startRaw == nil or startPer < 0 then
                            if maxStock ~= nil then
                                Shop.setStock(category, itemId, maxStock)
                            else
                                Shop.setStock(category, itemId, nil)
                            end
                        elseif startPer == 0 then
                            Shop.setStock(category, itemId, 0)
                        elseif startPer > 0 then
                            local startQty = ceilScaled(startPer, players)
                            if maxStock ~= nil then
                                startQty = math.min(startQty, maxStock)
                            end
                            if globalCap ~= nil then
                                startQty = math.min(startQty, globalCap)
                            end
                            Shop.setStock(category, itemId, startQty)
                        end
                    elseif restockEvery > 0 and (round % restockEvery == 0) then
                        local current = Shop.getStock(category, itemId)
                        if current ~= nil and restockPer > 0 then
                            local addQty = ceilScaled(restockPer, players)
                            local newQty = current + addQty
                            if maxStock ~= nil then
                                newQty = math.min(newQty, maxStock)
                            end
                            if globalCap ~= nil then
                                newQty = math.min(newQty, globalCap)
                            end
                            Shop.setStock(category, itemId, newQty)
                        end
                    end
                end
            end
        end
    end
end

function Shop.canUse(player)
    local state = getState()
    if not player or not state then return false end
    return state.status == Rogue.Server.STATE_PREP
end

function Shop.getItem(category, itemId)
    local lists = Config.SHOP_ITEMS or {}
    local items = lists[category]
    if not items then return nil end
    for i = 1, #items do
        local entry = items[i]
        if entry and entry.id == itemId then
            return entry
        end
    end
    return nil
end

function Shop.canBuy(player, category, itemId)
    if not Shop.canUse(player) then return false, "Shop only in PREP." end
    if not itemId or itemId == "" then return false, "Invalid item." end
    local entry = Shop.getItem(category, itemId)
    if not entry then return false, "Item not found." end
    local stock = Shop.getStock(category, itemId)
    if stock ~= nil and stock <= 0 then
        return false, "Out of stock."
    end
    return true, entry
end

function Shop.buy(player, category, itemId, qty)
    if not player then return false, "Invalid player." end
    if not (Rogue.Zones and Rogue.Zones.isPlayerInRect) then return false, "Zone system missing." end
    if not Rogue.Zones.isPlayerInRect(player, Config.ZONES.SAFE) then
        return false, "Shop only in SAFE."
    end
    local ok, entryOrMsg = Shop.canBuy(player, category, itemId)
    if not ok then
        return false, entryOrMsg
    end
    if ScriptManager and ScriptManager.instance then
        local item = ScriptManager.instance:FindItem(itemId)
        if not item then
            return false, "Item not found: " .. tostring(itemId)
        end
    end
    local entry = entryOrMsg
    local buyQty = math.max(1, math.floor(tonumber(qty) or (entry.qty or 1)))
    local stock = Shop.getStock(category, itemId)
    if stock ~= nil and buyQty > stock then
        return false, "Not enough stock."
    end
    local price = tonumber(entry.price) or 0
    local totalPrice = price * buyQty
    if Rogue.Economy and Rogue.Economy.canAfford and not Rogue.Economy.canAfford(player, totalPrice) then
        return false, "Not enough currency."
    end
    if Rogue.Economy and Rogue.Economy.spendCurrency then
        Rogue.Economy.spendCurrency(player, totalPrice)
    end

    local inv = player:getInventory()
    if not inv then return false, "Inventory missing." end
    for i = 1, buyQty do
        local item = inv:AddItem(itemId)
        if item then
            if sendAddItemToContainer then
                sendAddItemToContainer(inv, item)
            end
        end
    end
    if stock ~= nil then
        Shop.setStock(category, itemId, stock - buyQty)
    end
    return true, string.format("Bought %dx %s for %.2f", buyQty, itemId, totalPrice)
end
