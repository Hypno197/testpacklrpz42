require "TimedActions/ISBaseTimedAction"

Rogue = Rogue or {}
Rogue.Bogdano = Rogue.Bogdano or {}

local Bogdano = Rogue.Bogdano

local function safeCall(obj, fn, ...)
    if not obj then return end
    local f = obj[fn]
    if not f then return end
    pcall(f, obj, ...)
end

local function getConfig()
    return Rogue.Config or {}
end

function Bogdano.isBottle(item)
    if not item or not item.getFullType then return false end
    local fullType = item:getFullType()
    local list = getConfig().BOGDANO_BOTTLES or {}
    for i = 1, #list do
        if list[i] == fullType then return true end
    end
    return false
end

function Bogdano.isBottleFull(item)
    if not item then return false end
    if not item.getFluidContainer then return false end
    local okC, cont = pcall(item.getFluidContainer, item)
    if not okC or not cont then return false end
    if not cont.getAmount or not cont.getProperties then return false end
    local okA, amt = pcall(cont.getAmount, cont)
    if not okA or not amt then return false end
    local okP, props = pcall(cont.getProperties, cont)
    if not okP or not props or not props.getAlcohol then return false end
    local okAlc, alc = pcall(props.getAlcohol, props)
    if not okAlc or not alc then return false end
    local mlAlcohol = amt * alc * 1000
    local fullType = item.getFullType and item:getFullType() or "?"
    print(string.format("[Roguelityno][BogdanoDrink] check item=%s amt=%.3f alc=%.3f ml=%.1f",
        tostring(fullType),
        tonumber(amt) or 0,
        tonumber(alc) or 0,
        tonumber(mlAlcohol) or 0
    ))
    return mlAlcohol >= 350
end

RogueBogdanoDrinkAction = ISBaseTimedAction:derive("RogueBogdanoDrinkAction")

function RogueBogdanoDrinkAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.stopOnWalk = false
    o.stopOnRun = false
    o.maxTime = o:getDuration()
    o.useProgressBar = true
    o._bogdanoLoggedInvalid = false
    return o
end

function RogueBogdanoDrinkAction:isValid()
    if not self.character or not self.item then
        if not self._bogdanoLoggedInvalid then
            print(string.format("[Roguelityno][BogdanoDrink] invalid missing character=%s item=%s",
                tostring(self.character ~= nil),
                tostring(self.item ~= nil)
            ))
            self._bogdanoLoggedInvalid = true
        end
        return false
    end
    local container = self.item.getContainer and self.item:getContainer() or nil
    local full = Bogdano.isBottleFull(self.item)
    if not container or not full then
        if not self._bogdanoLoggedInvalid then
            print(string.format("[Roguelityno][BogdanoDrink] invalid container=%s full=%s",
                tostring(container ~= nil),
                tostring(full)
            ))
            self._bogdanoLoggedInvalid = true
        end
        return false
    end
    return true
end

function RogueBogdanoDrinkAction:getDuration()
    return 5 * 50
end

function RogueBogdanoDrinkAction:start()
    if isServer() then return end
    local cfg = getConfig()
    local soundId = cfg.BOGDANO_SOUND
    print("[Roguelityno][BogdanoDrink] start client")
    if self.setActionAnim then
        self:setActionAnim("Drink")
    end
    if self.setOverrideHandModels then
        self:setOverrideHandModels(nil, self.item)
    end
    if Rogue and Rogue.Client and Rogue.Client.playUISound then
        Rogue.Client.playUISound("bogdano_drink")
    elseif soundId and soundId ~= "" then
        local sm = getSoundManager()
        if sm and sm.playUISound then
            sm:playUISound(soundId)
        end
    end
    print("[Roguelityno][BogdanoDrink] start sound=" .. tostring(soundId or "nil"))
end

function RogueBogdanoDrinkAction:perform()
    print(string.format("[Roguelityno][BogdanoDrink] perform isServer=%s",
        tostring(isServer())
    ))
    if not isServer() then
        local cfg = getConfig()
        local alcohol = tonumber(cfg.BOGDANO_ALCOHOL) or 0
        local seconds = tonumber(cfg.BOGDANO_DRUNK_SECONDS) or 30
        local target = tonumber(cfg.BOGDANO_DRUNK_TARGET) or 100
        local player = self.character
        if player and player.getStats then
            local stats = player:getStats()
            if stats and stats.set then
                pcall(stats.set, stats, CharacterStat.INTOXICATION, target)
                local okV, val = pcall(stats.get, stats, CharacterStat.INTOXICATION)
                print(string.format("[Roguelityno][BogdanoDrink] client set intox=%s target=%s",
                    tostring(okV and val or "nil"),
                    tostring(target)
                ))
            end
        end
        if player and player.getBodyDamage and alcohol > 0 then
            local bd = player:getBodyDamage()
            if bd and bd.JustDrankBoozeFluid then
                safeCall(bd, "JustDrankBoozeFluid", alcohol)
            end
        end
        if Rogue and Rogue.Client then
            Rogue.Client._bogdanoLocalUntilMs = getTimestampMs() + (math.max(1, seconds) * 1000)
        end
    end
    ISBaseTimedAction.perform(self)
end

function RogueBogdanoDrinkAction:complete()
    if not isServer() then return true end
    print("[Roguelityno][BogdanoDrink] complete server")
    local cfg = getConfig()
    local alcohol = tonumber(cfg.BOGDANO_ALCOHOL) or 0
    local seconds = tonumber(cfg.BOGDANO_DRUNK_SECONDS) or 30
    local target = tonumber(cfg.BOGDANO_DRUNK_TARGET) or 100
    if Rogue.FullRestore and Rogue.FullRestore.apply then
        Rogue.FullRestore.apply(self.character)
    end
    local bd = self.character and self.character.getBodyDamage and self.character:getBodyDamage() or nil
    if bd and bd.JustDrankBoozeFluid and alcohol > 0 then
        safeCall(bd, "JustDrankBoozeFluid", alcohol)
    end
    local stats = self.character and self.character.getStats and self.character:getStats() or nil
    if stats and stats.set then
        pcall(stats.set, stats, CharacterStat.INTOXICATION, target)
        local okV, val = pcall(stats.get, stats, CharacterStat.INTOXICATION)
        print(string.format("[Roguelityno][BogdanoDrink] server set intox=%s target=%s",
            tostring(okV and val or "nil"),
            tostring(target)
        ))
    end
    local md = self.character and self.character.getModData and self.character:getModData() or nil
    if md then
        md.RogueBogdanoUntilMs = getTimestampMs() + (math.max(1, seconds) * 1000)
        md.RogueBogdanoTarget = target
    end
    sendServerCommand(self.character, "Rogue", "bogdanoEffect", {
        target = target,
        seconds = seconds,
        alcohol = alcohol,
    })
    local item = self.item
    local container = item and item.getContainer and item:getContainer() or nil
    if container then
        container:Remove(item)
        if sendRemoveItemFromContainer then
            sendRemoveItemFromContainer(container, item)
        end
        local smashed = container:AddItem("Base.SmashedBottle")
        if smashed and sendAddItemToContainer then
            sendAddItemToContainer(container, smashed)
        end
    end
    return true
end
