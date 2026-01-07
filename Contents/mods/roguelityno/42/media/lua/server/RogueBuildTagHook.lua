if not isServer() then return end

Rogue = Rogue or {}
Rogue.Server = Rogue.Server or {}
if not Rogue.Config then require "RogueConfig" end

local Server = Rogue.Server
local Config = Rogue.Config

local function isRectSquare(rect, x, y, z)
    if not Config or not Config.isRectValid or not Config.isRectValid(rect) then return false end
    local rz = rect.z or 0
    if (z or 0) ~= rz then return false end
    return x >= rect.x1 and x <= rect.x2 and y >= rect.y1 and y <= rect.y2
end

local function isTrackedSquare(x, y, z)
    if isRectSquare(Config.ZONES.ARENA, x, y, z) then return true end
    if isRectSquare(Config.ZONES.SAFE, x, y, z) then return true end
    return false
end

local function isRunTrackingStatus(status)
    return status == Server.STATE_LOBBY
        or status == Server.STATE_PREP
        or status == Server.STATE_WAVE
        or status == Server.STATE_POST
end

local function collectSpriteNames(face, spriteName)
    local spriteSet = {}
    local hasAny = false
    if spriteName then
        spriteSet[spriteName] = true
        hasAny = true
    end
    if face and face.getWidth then
        for zz = 0, face:getzLayers() - 1 do
            for xx = 0, face:getWidth() - 1 do
                for yy = 0, face:getHeight() - 1 do
                    local tileInfo = face:getTileInfo(xx, yy, zz)
                    if tileInfo and tileInfo.getSpriteName then
                        local okName, name = pcall(tileInfo.getSpriteName, tileInfo)
                        if okName and name then
                            spriteSet[name] = true
                            hasAny = true
                        end
                    end
                end
            end
        end
    end
    return spriteSet, hasAny
end

local function tagPlacedObjectsFromBuild(self, x, y, z, spriteName)
    if not Server or not Server.state then return end
    if not isRunTrackingStatus(Server.state.status) then return end
    if not isTrackedSquare(x, y, z) then return end

    local square = getCell():getGridSquare(x, y, z)
    if not square then return end

    local face = self and self.getFace and self:getFace() or nil
    local spriteSet, hasAny = collectSpriteNames(face, spriteName)
    if not hasAny then return end

    local tiles = self and self.getOccupiedTiles and self:getOccupiedTiles(square) or nil
    if not tiles or #tiles == 0 then
        tiles = { square }
    end

    Server.state.placedObjects = Server.state.placedObjects or {}
    for _, sq in ipairs(tiles) do
        if sq and isTrackedSquare(sq:getX(), sq:getY(), sq:getZ()) then
            local objects = sq:getObjects()
            if objects then
                for i = objects:size() - 1, 0, -1 do
                    local obj = objects:get(i)
                    if obj and obj.getModData then
                        local md = obj:getModData()
                        if md and not md.RoguePlacedRun then
                            local objSpriteName = nil
                            if obj.getSprite then
                                local okSprite, sprite = pcall(obj.getSprite, obj)
                                if okSprite and sprite and sprite.getName then
                                    local okName, name = pcall(sprite.getName, sprite)
                                    if okName then
                                        objSpriteName = name
                                    end
                                end
                            end
                            if objSpriteName and spriteSet[objSpriteName] then
                                md.RoguePlacedRun = Server.state.runId or "preRun"
                                if obj.transmitModData then
                                    pcall(obj.transmitModData, obj)
                                end
                                table.insert(Server.state.placedObjects, obj)
                            end
                        end
                    end
                end
            end
        end
    end
end

pcall(require, "BuildingObjects/ISBuildIsoEntity")
if not ISBuildIsoEntity or ISBuildIsoEntity._rogueTagHook then return end

local _rogue_old_create = ISBuildIsoEntity.create
function ISBuildIsoEntity:create(x, y, z, north, sprite)
    local result = _rogue_old_create(self, x, y, z, north, sprite)
    if isServer() then
        tagPlacedObjectsFromBuild(self, x, y, z, sprite)
    end
    return result
end
ISBuildIsoEntity._rogueTagHook = true
