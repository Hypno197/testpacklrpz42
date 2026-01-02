if not isServer() then return end

Rogue = Rogue or {}
Rogue.Zones = Rogue.Zones or {}

local Zones = Rogue.Zones
if not Rogue.Config then require "RogueConfig" end
pcall(require, "WL_Utils")
local Config = Rogue.Config

Zones.cooldowns = Zones.cooldowns or {}

local function getPlayerKey(player)
    if not player then return nil end
    local id = player.getOnlineID and player:getOnlineID() or nil
    if id and id >= 0 then
        return tostring(id)
    end
    return tostring(player:getUsername() or "unknown")
end

function Zones.getRectBounds(rect)
    if not rect then return nil end
    local x1 = math.min(rect.x1, rect.x2)
    local x2 = math.max(rect.x1, rect.x2)
    local y1 = math.min(rect.y1, rect.y2)
    local y2 = math.max(rect.y1, rect.y2)
    return x1, y1, x2, y2, rect.z
end

function Zones.isPointInRect(x, y, z, rect)
    if not rect then return false end
    local x1, y1, x2, y2, rz = Zones.getRectBounds(rect)
    if rz ~= nil and z ~= rz then
        return false
    end
    return x >= x1 and x <= x2 and y >= y1 and y <= y2
end

function Zones.isPlayerInRect(player, rect)
    if not player or not rect then return false end
    return Zones.isPointInRect(player:getX(), player:getY(), player:getZ(), rect)
end

function Zones.getSafePoint()
    if Config.teleportInPoint then
        return Config.teleportInPoint
    end
    return Config.getRectCenter(Config.ZONES.SAFE)
end

function Zones.getOutPoint()
    if Config.teleportOutPoint then
        return Config.teleportOutPoint
    end
    return Config.getRectCenter(Config.ZONES.ARENA)
end

function Zones.getSpawnPoint()
    if Config.ZONES.SPAWN then
        return Config.getRectCenter(Config.ZONES.SPAWN)
    end
    if Config.PRISON_SPAWN_POINT then
        return Config.PRISON_SPAWN_POINT
    end
    return Config.teleportInPoint
end

function Zones.teleportPlayer(player, point, nowMs, reason)
    if not player or not point then return false end
    nowMs = nowMs or getTimestampMs()

    local key = getPlayerKey(player)
    if not key then return false end

    local nextOk = Zones.cooldowns[key] or 0
    if nowMs < nextOk then return false end

    local x = tonumber(point.x) or 0
    local y = tonumber(point.y) or 0
    local z = tonumber(point.z) or 0

    local vehicle = player:getVehicle()
    if vehicle then
        if vehicle:getDriver() == player and vehicle:getSpeed2D() > 0 then
            return false
        end
        vehicle:exit(player)
    end

    if x - math.ceil(x) == 0 and y - math.ceil(y) == 0 then
        x = x + 0.5
        y = y + 0.5
    end

    if player.teleportTo then
        local ok, res = pcall(player.teleportTo, player, x, y, z)
        if ok and res ~= false then
            Zones.cooldowns[key] = nowMs + (Config.TELEPORT_COOLDOWN_MS or 2000)
            sendServerCommand(player, "Rogue", "clientTeleport", { x = x, y = y, z = z, reason = reason })
            return true
        end
    end

    if WL_Utils and WL_Utils.teleportPlayerToCoords then
        local ok = WL_Utils.teleportPlayerToCoords(player, x, y, z)
        if ok then
            Zones.cooldowns[key] = nowMs + (Config.TELEPORT_COOLDOWN_MS or 2000)
            sendServerCommand(player, "Rogue", "clientTeleport", { x = x, y = y, z = z, reason = reason })
            return true
        end
        return false
    end

    player:setX(x)
    player:setY(y)
    if player.setLx then player:setLx(x) end
    if player.setLy then player:setLy(y) end
    if player.setLastX then player:setLastX(x) end
    if player.setLastY then player:setLastY(y) end
    player:setZ(z)
    if player.setLastZ then player:setLastZ(z) end

    Zones.cooldowns[key] = nowMs + (Config.TELEPORT_COOLDOWN_MS or 2000)
    sendServerCommand(player, "Rogue", "clientTeleport", { x = x, y = y, z = z, reason = reason })
    return true
end

function Zones.enforceForState(state, nowMs)
    if not state or state.status == "IDLE" then return end
    if not Config.hasValidSetup() then return end

    local safeRect = Config.ZONES.SAFE
    local arenaRect = Config.ZONES.ARENA
    local safePoint = Zones.getSafePoint()
    local outPoint = Zones.getOutPoint()

    local players = getOnlinePlayers()
    if not players then
        players = IsoPlayer.getPlayers()
    end
    if not players then return end

    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player and not player:isDead() and not player:isInvisible() then
            local inSafe = Zones.isPlayerInRect(player, safeRect)
            local md = player:getModData()

            if state.status == "WAVE" then
                if md.RogueRespawnLock then
                    if not inSafe then
                        Zones.teleportPlayer(player, safePoint, nowMs, "respawn-lock")
                    end
                else
                    -- Temporarily ignore safe-lock expulsion during WAVE.
                end
            else
                if md.RogueRespawnLock then
                    md.RogueRespawnLock = nil
                end
            end
        end
    end
end
