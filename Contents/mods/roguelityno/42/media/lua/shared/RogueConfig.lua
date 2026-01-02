Rogue = Rogue or {}
Rogue.Config = Rogue.Config or {}

local Config = Rogue.Config

Config.MOD_ID = "roguelityno"

-- Set to false after inserting real coordinates.
Config.ZONE_SETUP_REQUIRED = false

Config.ZONES = {
    SAFE = nil,
    ARENA = nil,
    SPAWN = nil,
}

-- Optional fixed spawn points (unused when TierZonyne provides zones).
Config.SPAWN_POINTS = {}

-- Optional teleport points (defaults to zone centers when nil).
Config.teleportInPoint = nil
Config.teleportOutPoint = nil
Config.beaconPoint = nil
Config.PRISON_SPAWN_POINT = nil

Config.TELEPORT_COOLDOWN_MS = 2000

Config.LOBBY_TIERZONE_NAME = "ROGUESPAWN"

Config.PREP_SECONDS = 15
Config.WAVE_SOFT_SECONDS = 180
Config.WAVE_SOFT_MIN_SECONDS = 180
Config.waveSoftPerKill = 0.5
Config.POST_SECONDS = 12
Config.TIER_ESCALATE_EVERY_SECONDS = 30

Config.baseKillsPerPlayer = 30
Config.killsPerRoundSlope = 0.25
Config.spawnBudgetBuffer = 1.0
Config.DIFFICULTY_LEVEL = 2
Config.DIFFICULTY_PRESETS = {
    {
        id = 1,
        labelKey = "UI_rogue_difficulty_easy",
        baseKillsPerPlayer = 15,
        killsPerRoundSlope = 0.10,
        waveSoftPerKill = 1.0,
        runnerPctByTier = { 0, 3, 5, 10, 15, 30 },
    },
    {
        id = 2,
        labelKey = "UI_rogue_difficulty_balanced",
        baseKillsPerPlayer = 20,
        killsPerRoundSlope = 0.15,
        waveSoftPerKill = 0.8,
        runnerPctByTier = { 3, 5, 10, 15, 20, 40 },
    },
    {
        id = 3,
        labelKey = "UI_rogue_difficulty_hard",
        baseKillsPerPlayer = 30,
        killsPerRoundSlope = 0.20,
        waveSoftPerKill = 0.6,
        runnerPctByTier = { 5, 10, 15, 20, 25, 50 },
    },
    {
        id = 4,
        labelKey = "UI_rogue_difficulty_extreme",
        baseKillsPerPlayer = 40,
        killsPerRoundSlope = 0.25,
        waveSoftPerKill = 0.4,
        runnerPctByTier = { 5, 10, 15, 20, 25, 50 },
    },
    {
        id = 5,
        labelKey = "UI_rogue_difficulty_executioner",
        baseKillsPerPlayer = 50,
        killsPerRoundSlope = 0.50,
        waveSoftPerKill = 0.3,
        runnerPctByTier = { 10, 20, 30, 40, 50, 100 },
    },
}

Config.OUTSIDE_WARN_SECONDS = 0
Config.OUTSIDE_DAMAGE_AFTER_SECONDS = 5
Config.OUTSIDE_KILL_AFTER_SECONDS = 10
Config.OUTSIDE_ARENA_BUFFER = 2
Config.OUTSIDE_ARENA_MAX_BUFFER = 20
Config.OUTSIDE_IGNORE_TIERZONE = "ROGUESPAWN"

Config.SPRINTER_ADJUST_INTERVAL_SECONDS = 10
Config.SPRINTER_ADJUST_DIVISOR = 3

Config.SPAWN_INTERVAL_SECONDS = 8
Config.SPAWN_GROUP_BASE = 4
Config.SPAWN_GROUP_PER_PLAYER = 2
Config.SPAWN_GROUP_TIER_BONUS = 1
Config.SPAWN_GROUP_MAX = 40
Config.SPAWN_FIXED_POINT_COUNT = 16
Config.SPAWN_MAX_PER_POINT_PER_MINUTE = 6
Config.SPAWN_MAX_PER_MIN_BASE = 60
Config.SPAWN_MAX_PER_MIN_PER_PLAYER_SQRT = 30
Config.SPAWN_ARENA_BUFFER = 5
Config.ARENA_ALIVE_BUFFER = 12
Config.ARENA_KILL_BUFFER = 12
Config.ARENA_FAIL_GRACE_SECONDS = 3
Config.READY_TO_PREP_DELAY_MS = 3000

-- Arena beacon (server-side zombie attraction).
Config.BEACON_ENABLED = true
Config.BEACON_INTERVAL_SECONDS = 10
Config.BEACON_EXTRA_RADIUS = 10
Config.BEACON_TIER_STEP = 0
Config.BEACON_VOLUME = 50

Config.MAX_TIER = 6
Config.REWARD_CAP_TIER = 4

Config.TIER_RUNNER_PCT = {
    [1] = 5,
    [2] = 10,
    [3] = 15,
    [4] = 20,
    [5] = 25,
    [6] = 50,
}

Config.KILL_CURRENCY_BASE = 1
Config.KILL_CURRENCY_BY_TIER = {
    [1] = { min = 0.5, max = 1 },
    [2] = { min = 0.6, max = 1.1 },
    [3] = { min = 0.7, max = 1.2 },
    [4] = { min = 1, max = 2 },
    [5] = { min = 1.2, max = 2.5 },
    [6] = { min = 2, max = 5 },
}

Config.WAVE_CLEAR_BONUS_BASE = 10
Config.WAVE_CLEAR_BONUS_PER_ROUND = 5
Config.SPEED_CLEAR_MULTIPLIER = 1.25
Config.SLOW_CLEAR_MULTIPLIER = 0.75
Config.TIER_CLEAR_BONUS_MULT = 0.1
Config.WAVE_CLEAR_EARLY_BONUS_PCT = 0.15
Config.WAVE_CLEAR_ALIVE_BONUS_PCT = 0.15
Config.DEATH_CURRENCY_LOSS_PCT = 0.5

Config.STATS_SNAPSHOT_MINUTES = 5

Config.SHOP_CATEGORY_LABELS = {
    medical = "UI_rogue_shop_medical",
    weapons = "UI_rogue_shop_weapons",
    food = "UI_rogue_shop_food",
    drugs = "UI_rogue_shop_drugs",
    perks = "UI_rogue_shop_perks",
    firearms = "UI_rogue_shop_firearms",
    builds = "UI_rogue_shop_builds",
}

Config.SOUNDS = {
    shop_open = { "rogue_shop_open_1", "rogue_shop_open_2" },
    shop_buy_ok = { "rogue_shop_buy_ok_1", "rogue_shop_buy_ok_2" },
    shop_buy_fail = { "rogue_shop_buy_fail_1", "rogue_shop_buy_fail_2" },
    build_open = { "rogue_build_open_1" },
    build_buy_ok = { "rogue_build_buy_ok_1" },
    build_buy_fail = { "rogue_build_buy_fail_1" },
    round_prep = { "rogue_round_prep_1", "rogue_round_prep_2" },
    round_start = { "rogue_round_start_1", "rogue_round_start_2" },
    round_clear = { "rogue_round_clear_1" },
    round_overtime_soon = { "rogue_round_overtime_soon_1" },
    round_overtime = { "rogue_round_overtime_1" },
    round_overtime_announce = { "rogue_round_overtime_announce_1" },
    bogdano_drink = { "BogdanoDrinkBurp" },
    serum_use = { "FullRestoreSerumSound" },
}

Config.ROUND_OVERTIME_LOOP_MS = 29567
Config.ROUND_OVERTIME_SOON_SECONDS = 16

Config.SOUNDS_BY_CATEGORY = {
    -- medical = {
    --     shop_open = { "rogue_shop_open_medical_1" },
    --     shop_buy_ok = { "rogue_shop_buy_ok_medical_1" },
    -- },
    -- weapons = {
    --     shop_open = { "rogue_shop_open_weapons_1" },
    --     shop_buy_ok = { "rogue_shop_buy_ok_weapons_1" },
    -- },
    -- food = {
    --     shop_open = { "rogue_shop_open_food_1" },
    --     shop_buy_ok = { "rogue_shop_buy_ok_food_1" },
    -- },
    -- drugs = {
    --     shop_open = { "rogue_shop_open_drugs_1" },
    --     shop_buy_ok = { "rogue_shop_buy_ok_drugs_1" },
    -- },
    -- perks = {
    --     shop_open = { "rogue_shop_open_perks_1" },
    --     shop_buy_ok = { "rogue_shop_buy_ok_perks_1" },
    -- },
    -- firearms = {
    --     shop_open = { "rogue_shop_open_firearms_1" },
    --     shop_buy_ok = { "rogue_shop_buy_ok_firearms_1" },
    -- },
}

-- UI theme colors (RGB 0..1).
Config.UI_COLOR_BG = { r = 0, g = 0, b = 0, a = 0.75 }
Config.UI_COLOR_BORDER = { r = 0.95, g = 0.83, b = 0.15, a = 0.9 }
Config.UI_COLOR_ACCENT = { r = 0.95, g = 0.83, b = 0.15, a = 1.0 }
Config.UI_COLOR_TEXT = { r = 0.95, g = 0.83, b = 0.15, a = 1.0 }

-- UI fonts (use UIFont enum names). You can point to a custom font once added.
Config.UI_FONT_SMALL = "roguefont12"
Config.UI_FONT_MEDIUM = "roguefont16"
Config.UI_FONT_LARGE = "roguefont18"
Config.UI_FONT_CUSTOM_PATH = "common/media/fonts/roguefont12.fnt"

-- Item icons used in shop panels (set to valid item IDs).
Config.SHOP_CATEGORY_ICON_ITEM = {
    medical = "Base.Bandage",
    weapons = "Base.BaseballBat",
    food = "Base.Apple",
    drugs = "Base.Pills",
    perks = "Base.SheetPaper2",
    firearms = "Base.Pistol",
    builds = nil,
}

-- Wallet icon item (used in wallet panel and shop panels).
Config.WALLET_ICON_ITEM = "Base.GoldCoin"
Config.UI_WALLET_ICON_TEX = "media/textures/ui/wallet_icon.png"

-- UI background textures (optional). Place files under media/textures/ui/.
Config.UI_WALLET_BG_TEX = "media/textures/ui/wallet_bg_rogue.png"
Config.UI_SHOP_BG_TEX = "media/textures/ui/scoreboardbg.png"
Config.UI_SCORE_BG_TEX = "media/textures/ui/background_vertical_rogue.png"
Config.UI_HUD_BG_TEX = "media/textures/ui/banner_thin_rogue.png"
Config.UI_BANNER_BG_TEX = "media/textures/ui/banner_wide_rogue.png"
Config.UI_BANNER_DURATION_MS = 7000
Config.UI_SHOP_BG_TEX_BY_CATEGORY = {
    medical = "media/textures/ui/medicshopbg.png",
    weapons = "media/textures/ui/weaponshopbg.png",
    food = "media/textures/ui/supplyshopbg.png",
    drugs = "media/textures/ui/secretshopbg.png",
    perks = "media/textures/ui/secretshopbg.png",
    firearms = "media/textures/ui/gunshopbg.png",
    builds = "media/textures/ui/secretshopbg.png",
}
Config.UI_SHOP_PAD = 12
Config.SHOP_UI_MIN_ROWS = 10

Config.SHOP_MARKER_SIZE = 0.65
Config.SHOP_MARKER_TEX_BY_CATEGORY = {}
Config.SHOP_MARKER_COLOR_BY_CATEGORY = {
    medical = { r = 0.2, g = 1.0, b = 0.6 },
    weapons = { r = 1.0, g = 0.2, b = 0.2 },
    food = { r = 1.0, g = 0.8, b = 0.2 },
    drugs = { r = 0.7, g = 0.3, b = 1.0 },
    perks = { r = 0.8, g = 0.4, b = 0.1 },
    firearms = { r = 1.0, g = 0.5, b = 0.3 },
    builds = { r = 1.0, g = 0.8, b = 0.2 },
}

Config.SHOP_SPRITES = {
    medical = { "placeholder_medical_sprite" },
    weapons = { "placeholder_weapons_sprite" },
    food = { "placeholder_food_sprite" },
    drugs = { "placeholder_drugs_sprite" },
    perks = { "placeholder_perks_sprite" },
    firearms = { "placeholder_firearms_sprite" },
    builds = { "placeholder_builds_sprite" },
}

Config.BOGDANO_BOTTLES = {
    "Base.Brandy",
    "Base.Champagne",
    "Base.Cider",
    "Base.CoffeeLiquer",
    "Base.Curacao",
    "Base.Gin",
    "Base.Port",
    "Base.Rum",
    "Base.Scotch",
    "Base.Sherry",
    "Base.Tequila",
    "Base.Vermouth",
    "Base.Vodka",
    "Base.Whiskey",
    "Base.Wine",
    "Base.Wine2",
    "Base.Wine2Open",
    "Base.WineAged",
    "Base.WineOpen",
}
Config.BOGDANO_DRUNK_SECONDS = 30
Config.BOGDANO_INTOX = 35.0
Config.BOGDANO_ALCOHOL = 0.8
Config.BOGDANO_RESULT = "Base.SmashedBottle"
Config.BOGDANO_SOUND = "BogdanoDrinkBurp"

Config.REWARD_CHOICE_COUNT = 3
Config.REWARD_PANEL_TEX = {
    common = "media/textures/ui/reward_panel_common.png",
    uncommon = "media/textures/ui/reward_panel_uncommon.png",
    rare = "media/textures/ui/reward_panel_rare.png",
    epic = "media/textures/ui/reward_panel_epic.png",
    legendary = "media/textures/ui/reward_panel_legendary.png",
}

Config.REWARD_RARITY_WEIGHTS = {
    early = { common = 70, uncommon = 25, rare = 5, epic = 0, legendary = 0 },
    late = { common = 20, uncommon = 30, rare = 30, epic = 15, legendary = 5 },
    clamp = { commonMin = 10, epicMax = 25, legendaryMax = 8 },
    tierBump = {
        tier5 = { rare = 2, epic = 2, common = -4 },
        tier6 = { epic = 3, legendary = 2, common = -5 },
    },
}

Config.REWARD_CATEGORY_RULES = {
    { slot = 1, types = { "currency", "heal", "item" }, maxRarity = "uncommon" },
    { slot = 2, types = { "trait", "skill", "xpBoost" }, minRarity = "uncommon", maxRarity = "rare" },
    { slot = 3, types = { "blessing", "armor", "drug", "item", "currency" }, minRarity = "rare" },
}
Config.REWARD_POOLS = {
    common = {
        -- { type = "currency", amount = 10 },
        -- { type = "xpBoost", skill = "Axe", amount = 1.2, durationRounds = 2 },
        { type = "xpBoost", skill = "SmallBlunt", amount = 1.2, durationRounds = 2 },
        { type = "xpBoost", skill = "Blunt", amount = 1.2, durationRounds = 2 },
        { type = "skill", skill = "Maintenance", levels = 1 },
        { type = "skill", skill = "Nimble", levels = 1 },
        { type = "skill", skill = "Axe", levels = 2 },        
        -- { type = "item", id = "Base.Bandage", qty = 2 },
        -- { type = "heal", id = "Rogue.FullRestoreSerum", qty = 1 },
    },
    uncommon = {
        { type = "skills", skills = { { id = "Sprinting", levels = 2 }, { id = "Nimble", levels = 1 } } },
        { type = "currency", amount = 18 },
        { type = "item", id = "Base.WaterBottle", qty = 1 },
        { type = "skill", skill = "Maintenance", levels = 1 },
    },
    rare = {
        { type = "currency", amount = 28 },
        { type = "item", id = "Base.HuntingKnife", qty = 1 },
        { type = "xpBoost", skill = "Axe", amount = 1.2, durationRounds = 2 },
    },
    epic = {
        { type = "currency", amount = 40 },
        { type = "item", id = "Base.Axe", qty = 1 },
        { type = "trait", id = "NightVision" },
    },
    legendary = {
        { type = "currency", amount = 60 },
        { type = "item", id = "Base.AssaultRifle", qty = 1 },
        { type = "blessing", id = "rogue:blessing_damage", cap = 3 },
    },
}

Config.TRAIT_ICON_MAP = Config.TRAIT_ICON_MAP or {}
Config.SKILL_ICON_MAP = Config.SKILL_ICON_MAP or {}

Config.SHOP_ITEMS = {
    medical = {
        { id = "Rogue.FullRestoreSerum", price = 30.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 3 },
        { id = "Base.AlcoholWipes", price = 3.0, qty = 1, startStockPerPlayer = 1, restockPerPlayer = 0.6, restockEveryNrounds = 2 },
        { id = "Base.Antibiotics", price = 10.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.PillsAntiDep", price = 8.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.Bandage", price = 2.0, qty = 1, startStockPerPlayer = 1.2, restockPerPlayer = 0.8, restockEveryNrounds = 2 },
        { id = "Base.AlcoholBandage", price = 4.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.6, restockEveryNrounds = 2 },
        { id = "Base.Bandaid", price = 2.0, qty = 1, startStockPerPlayer = 1.0, restockPerPlayer = 0.8, restockEveryNrounds = 1 },
        { id = "Base.PillsBeta", price = 7.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.BlackSage", price = 6.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        --nuovo shop equip
        { id = "Base.Disinfectant", price = 6.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.AdhesiveBandageBox", price = 8.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.AntibioticsBox", price = 14.0, qty = 1, startStockPerPlayer = 0.2, restockPerPlayer = 0.2, restockEveryNrounds = 4 },
        { id = "Base.BandageBox", price = 6.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.ColdpackBox", price = 8.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
    },
    weapons = {
        { id = "Base.HuntingKnife", price = 10.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.KnifeButterfly", price = 12.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.HuntingKnifeForged", price = 16.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.HandguardDagger", price = 14.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.ShortBat", price = 10.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.6, restockEveryNrounds = 2 },
        { id = "Base.Mace_Stone", price = 14.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.LongMace_Stone", price = 18.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.SwitchKnife", price = 12.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.CrudeShortSword", price = 20.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 4 },
        { id = "Base.Sword", price = 28.0, qty = 1, startStockPerPlayer = 0.2, restockPerPlayer = 0.2, restockEveryNrounds = 4 },
        { id = "Base.Crowbar", price = 14.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.ClubHammer", price = 12.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.Hammer", price = 8.0, qty = 1, startStockPerPlayer = 1.0, restockPerPlayer = 0.8, restockEveryNrounds = 1 },
        { id = "Base.Axe", price = 22.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Axe_Old", price = 18.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.FireplacePoker", price = 8.0, qty = 1, startStockPerPlayer = 0.9, restockPerPlayer = 0.7, restockEveryNrounds = 1 },
        { id = "Base.BaseballBat", price = 14.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.6, restockEveryNrounds = 2 },
        { id = "Base.BaseballBat_Nails", price = 18.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Golfclub", price = 12.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.LaCrosseStick", price = 14.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
    },
    food = {
        { id = "Base.WaterBottle", price = 4.0, qty = 1, startStockPerPlayer = 1.2, restockPerPlayer = 0.8, restockEveryNrounds = 1 },
        { id = "Base.PopBottle", price = 6.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.6, restockEveryNrounds = 2 },
        { id = "Base.Chips", price = 4.0, qty = 1, startStockPerPlayer = 0.9, restockPerPlayer = 0.6, restockEveryNrounds = 1 },
        { id = "Base.TortillaChips", price = 3.0, qty = 1, startStockPerPlayer = 0.9, restockPerPlayer = 0.6, restockEveryNrounds = 2 },
        { id = "Base.BeefJerky", price = 6.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.CannedBolognese", price = 7.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 3 },
        { id = "Base.Dogfood", price = 3.0, qty = 1, startStockPerPlayer = 1, restockPerPlayer = 1, restockEveryNrounds = 1 },
        { id = "Base.CatTreats", price = 4.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.Battery", price = 2.0, qty = 1, startStockPerPlayer = 2.0, restockPerPlayer = 1.5, restockEveryNrounds = 1 },
        { id = "Base.BatteryBox", price = 12.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.Flashlight", price = 10.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.FlashLight_AngleHead_Army", price = 30.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Lantern", price = 30.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Propane_Refill", price = 10.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.2, restockEveryNrounds = 4 },
        { id = "Base.Bag_Schoolbag_Patches", price = 30.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Bag_HikingBag_Travel", price = 60.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Bag_HydrationBackpack_Camo", price = 80.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Bag_ALICEpack", price = 120.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },        
        { id = "Base.Plank", price = 3.0, qty = 2, startStockPerPlayer = 3, restockPerPlayer = 2, restockEveryNrounds = 1 },
        { id = "Base.NailsBox", price = 8.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.6, restockEveryNrounds = 2 },
        { id = "Base.Saw", price = 20.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.4, restockEveryNrounds = 3 },
        { id = "Base.SheetMetal", price = 6.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.Needle", price = 30.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.Thread", price = 5.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
    },
    drugs = {
        { id = "Drogatyno.Droga1", price = 10.0, qty = 1, startStockPerPlayer = 5 , restockPerPlayer = 0.4, restockEveryNrounds = 1 },
        { id = "Drogatyno.Droga2", price = 20.0, qty = 1, startStockPerPlayer = 4 , restockPerPlayer = 0.4, restockEveryNrounds = 1 },
        { id = "Drogatyno.Droga3", price = 40.0, qty = 1, startStockPerPlayer = 3 , restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Drogatyno.Droga4", price = 100.0, qty = 1, startStockPerPlayer = 2 , restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Drogatyno.Droga5", price = 250.0, qty = 1, startStockPerPlayer = 1 , restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.PillsVitamins", price = 6.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.PillsBeta", price = 7.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.PillsAntiDep", price = 8.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.Pills", price = 6.0, qty = 1, startStockPerPlayer = 0.9, restockPerPlayer = 0.6, restockEveryNrounds = 1 },
        { id = "Base.AlcoholWipes", price = 3.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.6, restockEveryNrounds = 1 },
    },
    perks = {
        { id = "Base.BookFarming1", price = 10.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.BookFarming2", price = 12.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 3 },
        { id = "Base.BookFarming3", price = 14.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.BookFarming4", price = 16.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 4 },
        { id = "Base.BookFarming5", price = 18.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 4 },
        { id = "Base.BookAiming1", price = 12.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.BookAiming2", price = 14.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 3 },
        { id = "Base.BookAiming3", price = 16.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.BookAiming4", price = 18.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 4 },
        { id = "Base.BookAiming5", price = 20.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 4 },
        { id = "Base.BookHusbandry1", price = 10.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.BookHusbandry2", price = 12.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 3 },
        { id = "Base.BookHusbandry3", price = 14.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.BookHusbandry4", price = 16.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 4 },
        { id = "Base.BookHusbandry5", price = 18.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 4 },
    },
    firearms = {
        { id = "Base.HolsterSimple_Black", price = 20.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Base.HolsterShoulder", price = 30.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Base.Bag_ALICE_BeltSus_Camo", price = 40.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Base.Pistol2", price = 40.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Base.Pistol3", price = 70.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.2, restockEveryNrounds = 3 },
        { id = "Base.Revolver", price = 35.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Base.Pistol", price = 60.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Base.Revolver_Long", price = 45.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 3 },
        { id = "Base.AssaultRifle", price = 70.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.15, restockEveryNrounds = 4 },
        { id = "Base.AssaultRifle2", price = 150.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.15, restockEveryNrounds = 4 },
        { id = "Base.HuntingRifle", price = 40.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 2 },
        { id = "Base.DoubleBarrelShotgunSawnoff", price = 80.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 3 },
        { id = "Base.Bullets9mmBox", price = 10.0, qty = 1, startStockPerPlayer = 0.9, restockPerPlayer = 0.7, restockEveryNrounds = 1 },
        { id = "Base.Bullets45Box", price = 12.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.6, restockEveryNrounds = 1 },
        { id = "Base.223Box", price = 14.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.4, restockEveryNrounds = 1 },
        { id = "Base.308Box", price = 16.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.3, restockEveryNrounds = 1 },
        { id = "Base.ShotgunShellsBox", price = 12.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.Bullets44", price = 10.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.9mmClip", price = 8.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.6, restockEveryNrounds = 3 },
        { id = "Base.45Clip", price = 9.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.44Clip", price = 9.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.556Clip", price = 12.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 3 },
        { id = "Base.M14Clip", price = 14.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Laser", price = 18.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.RedDot", price = 18.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.GunLight", price = 16.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
    },
}

Config.STARTING_CURRENCY = 70
Config.BUILD_REBUY_COST = 30

Config.GLOBAL_XP_BOOST_MULT = 0
Config.GLOBAL_XP_BOOSTS = {}

Config.BUILD_SHOP = {
    -- { id = "roguelityno:test_build", price = 0 },
    { id = "roguelityno:bimbolama", price = 50 },
    { id = "roguelityno:uomo_ascia", price = 50 },
    { id = "roguelityno:uomo_sasso", price = 50 },
    { id = "roguelityno:americano", price = 50 },
    { id = "roguelityno:la_leggenda", price = 50 },
    { id = "roguelityno:igor", price = 50 },
    { id = "roguelityno:mr_rumble", price = 50 },
}

-- Sounds that should follow the player instead of being fixed at a point.
Config.SOUNDS_FOLLOW_PLAYER = {
    round_prep = true,
    round_start = true,
    round_clear = true,
    round_overtime_soon = true,
    round_overtime = true,
    round_overtime_announce = true,
}

Config.BUILD_TEXT_SHADOW_BY_ID = {
    ["roguelityno:test_build"] = { r = 0.4, g = 0.6, b = 1.0, a = 1.0 },
    ["roguelityno:bimbolama"] = { r = 1.0, g = 0.45, b = 0.85, a = 1.0 },
    ["roguelityno:uomo_ascia"] = { r = 1.0, g = 0.5, b = 0.2, a = 1.0 },
    ["roguelityno:uomo_sasso"] = { r = 0.6, g = 0.8, b = 0.45, a = 1.0 },
    ["roguelityno:americano"] = { r = 0.35, g = 0.8, b = 1.0, a = 1.0 },
    ["roguelityno:la_leggenda"] = { r = 1.0, g = 0.95, b = 0.35, a = 1.0 },
    ["roguelityno:igor"] = { r = 0.55, g = 0.65, b = 1.0, a = 1.0 },
    ["roguelityno:mr_rumble"] = { r = 1.0, g = 0.35, b = 0.35, a = 1.0 },
}

Config.BUILDS = {
    {
        id = "roguelityno:test_build",
        name = "TEST BUILD",
        desc = "Test semplice: Forza 8, Fitness 6, Axe 3, Maintenance 2.",
        icon = "profession_unemployed",
        iconItem = "Base.SheetPaper2",
        skills = { Axe = 3, Maintenance = 2 },
        xpBoosts = {},
        startingStats = { Strength = 8, Fitness = 6 },
        traits = {
            "base:nightvision",
        },
        loadout = {
            { id = "Base.KnifeButterfly", qty = 1 },
            { id = "Base.Bandage", qty = 2 },
            { id = "Base.WaterBottle", qty = 1 },
        },
    },
    {
        id = "roguelityno:bimbolama",
        name = "BIMBOLAMA",
        desc = "Assassino mobile: velocita' alta e critico con lame corte. Glass cannon, non perdona ma letale se giocato bene.",
        icon = "profession_burglar",
        iconItem = "Base.KnifeButterfly",
        skills = { SmallBlade = 4, Maintenance = 4, Nimble = 3, Sprinting = 3, LightFoot = 4, Sneak = 4, Doctor = 4},
        xpBoosts = {},
        startingStats = { Strength = 5, Fitness = 8 },
        traits = {
            -- Positiv
            "base:nightvision",       
            "base:dextrous",          
            "base:adrenalinejunkie",  
            "base:graceful",          
            "base:gymnast",           
            "base:fasthealer",        
            -- Negativi
            "base:sundaydriver",      
            "base:pronetoillness",    
            "base:pacifist",
            "base:thinskinned",       
        },
        loadout = {
            { id = "Base.HuntingKnife", qty = 1 },
            { id = "Base.KnifeButterfly", qty = 2 },
            { id = "Base.Satchel", qty = 1 },
            { id = "Base.Belt2", qty = 1 },
            { id = "Base.Bandage", qty = 3 },
            { id = "Base.WaterBottle", qty = 1 },
            { id = "Base.Cigarettes", qty = 1 },
        },
    },

    {
        id = "roguelityno:uomo_ascia",
        name = "UOMO ASCIA",
        desc = "Brutalita' primitiva: camicia a quadri, analfabeta, ascia, spacca!",
        icon = "profession_lumberjack",
        iconItem = "Base.Axe",
        skills = { Axe = 4, Maintenance = 4, Woodwork = 4 },
        xpBoosts = {},
        startingStats = { Strength = 8, Fitness = 8 },
        traits = {
            "base:nightvision",
            "base:resilient",
            "base:fit",
            "base:stout",
            "base:axeman",
            "base:clumsy",  
            "base:allthumbs", 
            "base:illiterate",  
            "base:slowhealer",
        },
        loadout = {
            { id = "Base.AxeStone", qty = 3 },
            { id = "Base.Bandage", qty = 2 },
            { id = "Base.WaterBottle", qty = 1 },

        },
    },

    {
        id = "roguelityno:uomo_sasso",
        name = "UOMO SASSO",
        desc = "Artigiano anti-tecnologia: costruisce difese e forgia roba primitiva. Niente armi da fuoco, domina il setup.",
        icon = "profession_constructionworker",
        iconItem = "Base.StoneChisel",
        skills = { Axe = 3, Maintenance = 4, SmallBlunt = 4, Blunt = 4, Masonry = 10, Blacksmith = 10, Woodwork = 10, Carving = 10, Fishing = 10, FlintKnapping = 10, Nimble = 2, Sprinting = 3},
        xpBoosts = {},
        startingStats = { Strength = 10, Fitness = 8 },
        traits = {
            "base:nightvision",
            "base:dextrous",
            "base:resilient",
            "base:handy",
            "base:whittler",
            "base:crafty",
            "base:fastlearner",       -- Allievo modello
            "base:outdoorsman",       -- uomo natura
            "base:organized",
        },
        loadout = {
            { id = "Base.Hammer", qty = 1 },
            { id = "Base.Saw", qty = 1 },
            { id = "Base.NailsBox", qty = 1 },
            { id = "Base.Plank", qty = 3 },
            -- arma primitiva base
            { id = "Base.Bag_TarpFramepack_Large", qty = 1 },
            { id = "Base.JawboneBovide_Club", qty = 1 },
            { id = "Base.AlcoholRippedSheets", qty = 2 },
            { id = "Base.WaterBottle", qty = 1 },
        },
    },

    {
        id = "roguelityno:americano",
        name = "AMERICANO",
        desc = "Goblin del loot: arraffa tutto, preferisce armi da fuoco. Codardo e claustrofobico: forte se gira, crolla se bloccato.",
        icon = "profession_veteran",
        iconItem = "Base.Pistol",
        skills = { Maintenance = 3, SmallBlunt = 2, LongBlade = 3, Nimble = 4, Sprinting = 3, Aiming = 4, Reloading = 6, Doctor = 4},
        xpBoosts = {},
        startingStats = { Strength = 6, Fitness = 7 },
        traits = {
            "base:nightvision",
            "base:cowardly",
            "base:claustrophobic",    --anti camper
            --"base:hemophobic",
            "base:keenhearing",
            "base:eagleeyed",
            "base:dextrous",
            "base:marksman",
        },
        loadout = {
            { id = "Base.Bag_RifleCaseClothCamo", qty = 1 },
            { id = "Base.Revolver", qty = 1 },             
            { id = "Base.Bullets45Box", qty = 2 },
            { id = "Base.Holster_DuctTape", qty = 1 },
            { id = "Base.WaterBottle", qty = 1 },
            { id = "Base.Bandaid", qty = 1 },
            { id = "Base.Lighter", qty = 1 },
        },
    },

    {
        id = "roguelityno:la_leggenda",
        name = "LA LEGGENDA",
        desc = "Allrounder leggendario. Impara in fretta, manutenzione alta, nessun debuff di respawn nella modalita' Rumble.",
        icon = "profession_fireofficer",
        iconItem = "Base.Hat_Beany",
        skills = { Axe = 3, Maintenance = 4, SmallBlunt = 3, Blunt = 3, LongBlade = 3, Spear = 3, Nimble = 2, Sprinting = 3, Aiming = 2, Reloading = 4, Doctor = 4},
        xpBoosts = {
            Axe = 2,
            SmallBlunt = 2,
            Blunt = 2,
            LongBlade = 2,
            SmallBlade = 2,
            Spear = 2,
            Aiming = 1,
        },
        startingStats = { Strength = 8, Fitness = 8 },
        traits = {
            "base:nightvision",      
            "base:fastlearner",      
            "base:brave",       
            "base:brawler",
            --to be tratto che paga meno le droghe?
        },
    loadout = {
            { id = "Base.Jacket_LeatherBlack", qty = 1 },  
            { id = "Base.Hat_Beany", qty = 1 },
            { id = "Base.Crowbar", qty = 1 },
            { id = "Base.WaterBottle", qty = 1 },
            { id = "Base.Bandage", qty = 2 },
        },
    },

    {
        id = "roguelityno:igor",
        name = "BOGDANO",
        desc = "Meccanico dell'est europa. Forza massima, contundenti forti, polmoni bucati. Nel weekend va a sparare col cugino in campagna. Fagli scolare una bella bottiglia piena col tasto destro e torna come nuovo, proprio come la vecchia Betty!",
        icon = "profession_mechanic",
        iconItem = "Base.BlowTorch",
        skills = { Maintenance = 4, SmallBlunt = 4, Blunt = 4, SmallBlade = 3, Nimble = 2, Aiming = 2, Reloading = 4, MetalWelding = 6, Mechanics = 10, Electrical = 4},
        xpBoosts = {
            MetalWelding = 8,
            SmallBlunt = 2,
            Blunt = 2,
            Maintenance = 2,
        },
        startingStats = { Strength = 10, Fitness = 5 },
        traits = {
            "base:nightvision",       -- Cat's Eyes
            "base:smoker",
            "base:allthumbs", 
            "base:mechanics",
        },
        loadout = {
            { id = "Base.Ratchet", qty = 1 },            
            { id = "Base.Whiskey", qty = 3 },       
            { id = "Base.Cigar", qty = 2 },        
            { id = "Base.Lighter", qty = 1 },           
            { id = "Base.WaterBottle", qty = 1 },
            { id = "Base.Wrench", qty = 1 },
            { id = "Base.CanPipe", qty = 1 },
            { id = "Base.PipeWrench", qty = 1 },
        },
    },

    {
        id = "roguelityno:mr_rumble",
        name = "MR RUMBLE",
        desc = "Il regista. Evidente e allergico, attira orde con strumenti rumorosi.",
        icon = "profession_engineer",
        iconItem = "Base.AlarmClock",
        skills = { SmallBlade = 3, Maintenance = 4, SmallBlunt = 3, Blunt = 3, LongBlade = 3, Spear = 3, Nimble = 2, Sprinting = 3, Aiming = 2, Reloading = 4},
        xpBoosts = {},
        startingStats = { Strength = 8, Fitness = 8 },
        traits = {
            "base:conspicuous",   
            "base:pronetoillness",
            "base:organized",     
        },
        loadout = {
            { id = "Base.AlarmClock", qty = 2 },
            { id = "Base.BanjoNeck_Broken", qty = 1 }, 
            { id = "Base.Whistle", qty = 1 },
            { id = "Base.Hat_Cowboy_White", qty = 1 },            
            { id = "Base.CanteenCowboy", qty = 1 }, 
            { id = "Base.Bag_FannyPackFront", qty = 1 }, 
            { id = "Base.GuitarAcoustic", qty = 1 },
            { id = "Base.Bandage", qty = 2 },
        },
    },
}

Config.PROFESSIONS = Config.BUILDS


function Config.killsRoundMultiplier(roundIndex)
    local idx = math.max(1, tonumber(roundIndex) or 1)
    return 1 + (idx - 1) * Config.killsPerRoundSlope
end

function Config.getKillTarget(playersLive, roundIndex)
    local count = math.max(1, tonumber(playersLive) or 1)
    local target = count * Config.baseKillsPerPlayer * Config.killsRoundMultiplier(roundIndex)
    return math.ceil(target)
end

function Config.getWaveSoftSeconds(killTarget)
    local minSeconds = tonumber(Config.WAVE_SOFT_MIN_SECONDS) or tonumber(Config.WAVE_SOFT_SECONDS) or 180
    local perKill = tonumber(Config.waveSoftPerKill) or 0
    local target = tonumber(killTarget or 0) or 0
    if target <= 0 or perKill <= 0 then
        return math.max(1, math.floor(minSeconds))
    end
    local scaled = math.ceil(target * perKill)
    return math.max(minSeconds, scaled)
end

function Config.applyDifficulty(level)
    local idx = tonumber(level)
    if not idx then return false end
    local preset = nil
    for i = 1, #Config.DIFFICULTY_PRESETS do
        if Config.DIFFICULTY_PRESETS[i].id == idx then
            preset = Config.DIFFICULTY_PRESETS[i]
            break
        end
    end
    if not preset then return false end
    Config.DIFFICULTY_LEVEL = preset.id
    Config.baseKillsPerPlayer = preset.baseKillsPerPlayer
    Config.killsPerRoundSlope = preset.killsPerRoundSlope
    Config.waveSoftPerKill = preset.waveSoftPerKill or Config.waveSoftPerKill
    Config.TIER_RUNNER_PCT = {}
    for i = 1, 6 do
        Config.TIER_RUNNER_PCT[i] = preset.runnerPctByTier[i] or 0
    end
    return true
end

function Config.getSpawnBudget(killTarget)
    return math.max(1, math.floor(tonumber(killTarget) or 1))
end

function Config.tierFromProgress(progress)
    local p = tonumber(progress) or 0
    if p <= 0 then
        return 1
    end
    if p >= 1 then
        return Config.MAX_TIER
    end
    return math.min(Config.MAX_TIER, math.max(1, math.ceil(p * Config.MAX_TIER)))
end

function Config.getBaseTier(roundIndex, maxRounds)
    local r = tonumber(roundIndex) or 1
    local maxR = tonumber(maxRounds) or 1
    if r > maxR then
        return Config.MAX_TIER
    end
    return Config.tierFromProgress(r / maxR)
end

function Config.getTierRewardMultiplier(tier)
    local t = math.min(Config.REWARD_CAP_TIER, math.max(1, tonumber(tier) or 1))
    return Config.XP_TIER_MULT[t] or 1.0
end

function Config.getRectCenter(rect)
    local x1 = math.min(rect.x1, rect.x2)
    local x2 = math.max(rect.x1, rect.x2)
    local y1 = math.min(rect.y1, rect.y2)
    local y2 = math.max(rect.y1, rect.y2)
    return { x = (x1 + x2) / 2, y = (y1 + y2) / 2, z = rect.z }
end

function Config.isRectValid(rect)
    if Config.ZONE_SETUP_REQUIRED then
        return false
    end
    if not rect then
        return false
    end
    if rect.x1 == rect.x2 or rect.y1 == rect.y2 then
        return false
    end
    return true
end

function Config.hasValidSetup()
    if Config.ZONE_SETUP_REQUIRED then
        return false
    end
    if not Config.isRectValid(Config.ZONES.SAFE) then
        return false
    end
    if not Config.isRectValid(Config.ZONES.ARENA) then
        return false
    end
    if Config.SPAWN_POINTS and #Config.SPAWN_POINTS >= 6 then
        for i = 1, #Config.SPAWN_POINTS do
            local p = Config.SPAWN_POINTS[i]
            if not p or p.x == nil or p.y == nil or p.z == nil then
                return false
            end
        end
    else
        if not Config.SPAWN_FIXED_POINT_COUNT or Config.SPAWN_FIXED_POINT_COUNT < 4 then
            return false
        end
    end
    return true
end


