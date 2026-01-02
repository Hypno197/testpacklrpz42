if not isServer() then return end

Rogue = Rogue or {}
Rogue.Economy = Rogue.Economy or {}

local Economy = Rogue.Economy
if not Rogue.Config then require "RogueConfig" end
local Config = Rogue.Config

local function getKey(player)
    if not player then return "unknown" end
    local name = player:getUsername()
    if name and name ~= "" then
        return tostring(name)
    end
    local id = player.getOnlineID and player:getOnlineID() or nil
    if id and id >= 0 then
        return "id:" .. tostring(id)
    end
    return "unknown"
end

function Economy.getWallet(player)
    if not player then return 0 end
    local all = ModData.getOrCreate("RoguelitynoWallet")
    local key = getKey(player)
    all[key] = all[key] or 0
    return all[key]
end

function Economy.setWallet(player, amount)
    if not player then return end
    local all = ModData.getOrCreate("RoguelitynoWallet")
    local key = getKey(player)
    all[key] = math.max(0, tonumber(amount) or 0)
    ModData.transmit("RoguelitynoWallet")
end

function Economy.addCurrency(player, amount)
    if not player then return end
    local current = Economy.getWallet(player)
    Economy.setWallet(player, current + (tonumber(amount) or 0))
end

function Economy.canAfford(player, amount)
    return Economy.getWallet(player) >= (tonumber(amount) or 0)
end

function Economy.spendCurrency(player, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return true end
    if not Economy.canAfford(player, amount) then return false end
    Economy.setWallet(player, Economy.getWallet(player) - amount)
    return true
end

function Economy.getTierRewardMultiplier(tier)
    return Config.getTierRewardMultiplier(tier)
end

function Economy.resetWallets()
    ModData.add("RoguelitynoWallet", {})
    ModData.transmit("RoguelitynoWallet")
end

function Economy.getKillReward(tier)
    local rewardTier = math.min(Config.REWARD_CAP_TIER or 4, math.max(1, tonumber(tier) or 1))
    local byTier = Config.KILL_CURRENCY_BY_TIER or {}
    local entry = byTier[rewardTier]
    if entry and entry.min and entry.max then
        local minv = tonumber(entry.min) or 0
        local maxv = tonumber(entry.max) or minv
        if maxv < minv then maxv = minv end
        if maxv == minv then return minv end
        if ZombRandFloat then
            local val = ZombRandFloat(minv, maxv)
            return math.floor(val * 100 + 0.5) / 100
        end
        return ZombRand(minv, maxv + 1)
    end
    local base = Config.KILL_CURRENCY_BASE or 1
    local bonus = (rewardTier - 1) * (Config.KILL_CURRENCY_TIER_BONUS or 0)
    local cap = Config.KILL_CURRENCY_TIER_BONUS_CAP or 0
    bonus = math.min(bonus, cap)
    return base + bonus
end

function Economy.getWaveClearReward(tier, durationSec, alive, roundIndex, softSeconds)
    local rewardTier = math.min(Config.REWARD_CAP_TIER or 4, math.max(1, tonumber(tier) or 1))
    local base = (Config.WAVE_CLEAR_BONUS_BASE or 0)
        + (Config.WAVE_CLEAR_BONUS_PER_ROUND or 0) * math.max(1, tonumber(roundIndex) or 1)
    local soft = tonumber(softSeconds) or Config.WAVE_SOFT_SECONDS or 180
    local speedMult = Config.SPEED_CLEAR_MULTIPLIER or 1.0
    local slowMult = Config.SLOW_CLEAR_MULTIPLIER or 1.0
    local tierMult = 1.0 + (Config.TIER_CLEAR_BONUS_MULT or 0) * math.max(0, rewardTier - 1)
    local earlyBonusPct = Config.WAVE_CLEAR_EARLY_BONUS_PCT or 0
    local aliveBonusPct = Config.WAVE_CLEAR_ALIVE_BONUS_PCT or 0

    local mult = (durationSec <= soft) and speedMult or slowMult
    if durationSec <= soft then
        mult = mult * (1 + earlyBonusPct)
    end
    if alive then
        mult = mult * (1 + aliveBonusPct)
    end

    local val = base * mult * tierMult
    return math.floor(val * 100 + 0.5) / 100
end

function Economy.applyDeathPenalty(player)
    if not player then return end
    local lossPct = Config.DEATH_CURRENCY_LOSS_PCT or 0.5
    local wallet = Economy.getWallet(player)
    local lost = math.floor(wallet * lossPct * 100 + 0.5) / 100
    Economy.setWallet(player, wallet - lost)
    return lost
end
