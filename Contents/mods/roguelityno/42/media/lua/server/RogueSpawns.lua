if not isServer() then return end

Rogue = Rogue or {}
Rogue.Spawns = Rogue.Spawns or {}

local Spawns = Rogue.Spawns
if not Rogue.Config then require "RogueConfig" end
local Config = Rogue.Config

local function debugLog(msg)
    if Rogue.Server and Rogue.Server.state and Rogue.Server.state.debug then
        print("[Roguelityno][Spawns] " .. tostring(msg))
    end
end

local function warnLog(msg)
    if Rogue.Server and Rogue.Server.state and Rogue.Server.state.debug then
        print("[Roguelityno][Spawns][WARN] " .. tostring(msg))
    end
end

local function getArenaBounds()
    if not Config.isRectValid(Config.ZONES.ARENA) then
        return nil
    end
    local rect = Config.ZONES.ARENA
    local x1 = math.min(rect.x1, rect.x2)
    local x2 = math.max(rect.x1, rect.x2)
    local y1 = math.min(rect.y1, rect.y2)
    local y2 = math.max(rect.y1, rect.y2)
    return x1, y1, x2, y2, rect.z or 0
end

local function generateFixedPoints()
    local x1, y1, x2, y2, z = getArenaBounds()
    if not x1 then return nil end

    local buffer = Config.SPAWN_ARENA_BUFFER or 5
    local count = Config.SPAWN_FIXED_POINT_COUNT or 16
    if count < 4 then count = 4 end

    local points = {}
    local perSide = math.floor(count / 4)
    local extra = count - (perSide * 4)
    local function addPointsOnSide(sx1, sy1, sx2, sy2, n)
        if n <= 0 then return end
        for i = 1, n do
            local t = (i - 0.5) / n
            local px = sx1 + (sx2 - sx1) * t
            local py = sy1 + (sy2 - sy1) * t
            table.insert(points, { x = math.floor(px), y = math.floor(py), z = z })
        end
    end

    local topN = perSide + (extra > 0 and 1 or 0)
    local rightN = perSide + (extra > 1 and 1 or 0)
    local bottomN = perSide + (extra > 2 and 1 or 0)
    local leftN = perSide

    addPointsOnSide(x1, y1 - buffer, x2, y1 - buffer, topN)
    addPointsOnSide(x2 + buffer, y1, x2 + buffer, y2, rightN)
    addPointsOnSide(x2, y2 + buffer, x1, y2 + buffer, bottomN)
    addPointsOnSide(x1 - buffer, y2, x1 - buffer, y1, leftN)

    return points
end

local function safeAddZombiesInOutfit(x, y, z, count)
    if not addZombiesInOutfit then
        return nil, "missing addZombiesInOutfit"
    end
    local ok, res = pcall(addZombiesInOutfit, x, y, z, count, nil, nil)
    if not ok then
        return nil, res
    end
    if res and res.size then
        return res:size(), nil
    end
    if type(res) == "number" then
        return res, nil
    end
    return count, nil
end

local function safeSpawnHorde(x, y, z, count)
    if not spawnHorde then
        return nil, "missing spawnHorde"
    end
    local x1 = x - 3
    local y1 = y - 3
    local x2 = x + 3
    local y2 = y + 3
    local ok, err = pcall(spawnHorde, x1, y1, x2, y2, z, count)
    if not ok then
        return nil, err
    end
    return count, nil
end

local function safeCreateHordeFromTo(x, y, targetX, targetY, count)
    if not createHordeFromTo then
        return nil, "missing createHordeFromTo"
    end
    local ok, err = pcall(createHordeFromTo, x, y, targetX, targetY, count)
    if not ok then
        return nil, err
    end
    return count, nil
end

function Spawns.init(state, nowMs)
    if not state then return false end
    state.spawnIntervalMs = (Config.SPAWN_INTERVAL_SECONDS or 8) * 1000
    state.spawnNextAtMs = nowMs or getTimestampMs()
    state.spawnMinuteStartMs = nowMs or getTimestampMs()
    state.spawnMinuteCount = 0
    state.spawnPointCounts = {}
    state.spawnPointsFixed = generateFixedPoints()
    return true
end

function Spawns.tick(state, nowMs, playersLive)
    if not state or state.status ~= Rogue.Server.STATE_WAVE then return end
    if not Config.hasValidSetup() then return end
    if (state.spawnBudgetRemaining or 0) <= 0 then return end

    local nextAt = state.spawnNextAtMs or nowMs
    if nowMs < nextAt then return end

    local minuteStart = state.spawnMinuteStartMs or nowMs
    if nowMs - minuteStart >= 60000 then
        state.spawnMinuteStartMs = nowMs
        state.spawnMinuteCount = 0
        state.spawnPointCounts = {}
    end

    local points = state.spawnPointsFixed or Config.SPAWN_POINTS or {}
    local staticPerPointCap = Config.SPAWN_MAX_PER_POINT_PER_MINUTE or 6
    local sqrtCap = (Config.SPAWN_MAX_PER_MIN_BASE or 0)
        + (Config.SPAWN_MAX_PER_MIN_PER_PLAYER_SQRT or 0) * math.sqrt(math.max(1, tonumber(playersLive) or 1))
    local totalCap = math.floor(sqrtCap)
    local perPointCap = math.max(staticPerPointCap, math.ceil(totalCap / math.max(1, #points)))
    state.spawnTotalCap = totalCap
    state.spawnPerPointCap = perPointCap
    if (state.spawnMinuteCount or 0) >= totalCap then
        return
    end

    local spawned = Spawns.spawnWaveBatch(state, playersLive or 1)
    state.spawnBudgetRemaining = math.max(0, (state.spawnBudgetRemaining or 0) - spawned)
    state.spawnMinuteCount = (state.spawnMinuteCount or 0) + spawned

    state.spawnNextAtMs = nowMs + (state.spawnIntervalMs or 8000)
end

local function isOutsideArenaWithBuffer(point)
    if not Config.isRectValid(Config.ZONES.ARENA) then
        return true
    end
    local rect = Config.ZONES.ARENA
    local x1 = math.min(rect.x1, rect.x2)
    local x2 = math.max(rect.x1, rect.x2)
    local y1 = math.min(rect.y1, rect.y2)
    local y2 = math.max(rect.y1, rect.y2)
    local buffer = Config.SPAWN_ARENA_BUFFER or 6
    local x = point.x
    local y = point.y
    return (x <= (x1 - buffer)) or (x >= (x2 + buffer)) or (y <= (y1 - buffer)) or (y >= (y2 + buffer))
end

function Spawns.spawnWaveBatch(state, playersLive)
    if not state then return 0 end
    local budget = state.spawnBudgetRemaining or 0
    if budget <= 0 then return 0 end

    local live = math.max(1, tonumber(playersLive) or 1)
    local tier = math.max(1, tonumber(state.currentTier) or 1)

    local size = (Config.SPAWN_GROUP_BASE or 4)
        + live * (Config.SPAWN_GROUP_PER_PLAYER or 2)
        + math.max(0, tier - 1) * (Config.SPAWN_GROUP_TIER_BONUS or 1)

    size = math.min(size, Config.SPAWN_GROUP_MAX or size, budget)
    local points = state.spawnPointsFixed or Config.SPAWN_POINTS or {}
    local perPointCap = state.spawnPerPointCap or (Config.SPAWN_MAX_PER_POINT_PER_MINUTE or 6)
    local totalCap = state.spawnTotalCap or math.huge
    local remainingTotal = math.max(0, totalCap - (state.spawnMinuteCount or 0))
    size = math.min(size, remainingTotal)
    if size <= 0 then return 0 end

    if #points < 1 then return 0 end
    local point = nil
    local pointIndex = nil
    for i = 1, #points do
        local idx = ZombRand(#points) + 1
        local candidate = points[idx]
        local countAt = state.spawnPointCounts[idx] or 0
        if candidate and countAt < perPointCap and isOutsideArenaWithBuffer(candidate) then
            point = candidate
            pointIndex = idx
            size = math.min(size, perPointCap - countAt)
            break
        end
    end
    if not point then
        warnLog("No spawn points outside arena buffer; skipped batch size=" .. tostring(size))
        return 0
    end
    if not point then return 0 end

    local x = math.floor(tonumber(point.x) or 0)
    local y = math.floor(tonumber(point.y) or 0)
    local z = math.floor(tonumber(point.z) or 0)

    local spawned, err = safeAddZombiesInOutfit(x, y, z, size)
    if not spawned then
        warnLog("addZombiesInOutfit failed: " .. tostring(err))
        spawned, err = safeSpawnHorde(x, y, z, size)
        if not spawned then
            local beacon = Config.beaconPoint or point
            local tx = math.floor(tonumber(beacon.x) or x)
            local ty = math.floor(tonumber(beacon.y) or y)
            spawned, err = safeCreateHordeFromTo(x, y, tx, ty, size)
        end
    end

    if not spawned then
        warnLog("No spawn API available; skipped batch size=" .. tostring(size))
        spawned = 0
    end

    if spawned > 0 then
        if pointIndex then
            state.spawnPointCounts[pointIndex] = (state.spawnPointCounts[pointIndex] or 0) + spawned
        end
        debugLog("Spawned " .. tostring(spawned) .. " at (" .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z) .. ")")
    end

    return spawned
end
