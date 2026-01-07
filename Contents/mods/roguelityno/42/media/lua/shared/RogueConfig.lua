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

Config.PREP_SECONDS = 180
Config.PREP_COUNTDOWN_SECONDS = 20.6
Config.WAVE_SOFT_SECONDS = 180
Config.WAVE_SOFT_MIN_SECONDS = 300
Config.waveSoftPerKill = 0.5
Config.POST_SECONDS = 5
Config.TIER_ESCALATE_EVERY_SECONDS = 30
--NUMERO DI ZOPPI BASE PER PLAYER 
Config.baseKillsPerPlayer = 1
Config.killsPerRoundSlope = 0.25
Config.spawnBudgetBuffer = 1.0
Config.SPAWN_GROUP_MULT = 1.0
Config.DIFFICULTY_LEVEL = 2
Config.DIFFICULTY_PRESETS = {
    {
        id = 1,
        labelKey = "UI_rogue_difficulty_easy",
        baseKillsPerPlayer = 10,
        killsPerRoundSlope = 0.10,
        waveSoftPerKill = 2.5,
        spawnIntervalSeconds = 7,
        spawnGroupMult = 0.7,
        runnerPctByTier = { 0, 0, 1, 2, 3, 4 },
    },
    {
        id = 2,
        labelKey = "UI_rogue_difficulty_balanced",
        baseKillsPerPlayer = 15,
        killsPerRoundSlope = 0.15,
        waveSoftPerKill = 2.5,
        spawnIntervalSeconds = 5.5,
        spawnGroupMult = 0.8,
        runnerPctByTier = { 0, 3, 5, 10, 15, 20 },
    },

    {
        id = 3,
        labelKey = "UI_rogue_difficulty_hard",
        baseKillsPerPlayer = 20,
        killsPerRoundSlope = 0.25,
        waveSoftPerKill = 2.2,
        spawnIntervalSeconds = 5,
        spawnGroupMult = 1,
        runnerPctByTier = { 5, 10, 15, 20, 25, 40 },
    },
    
    {
        id = 4,
        labelKey = "UI_rogue_difficulty_extreme",
        baseKillsPerPlayer = 25,
        killsPerRoundSlope = 0.30,
        waveSoftPerKill = 2,
        spawnIntervalSeconds = 4.5,
        spawnGroupMult = 1.3,
        runnerPctByTier = { 5, 10, 15, 20, 25, 50 },
    },
    
    {
        id = 5,
        labelKey = "UI_rogue_difficulty_executioner",
        baseKillsPerPlayer = 15,
        killsPerRoundSlope = 0.50,
        waveSoftPerKill = 1.5,
        spawnIntervalSeconds = 4,
        spawnGroupMult = 1.7,
        runnerPctByTier = { 10, 20, 30, 40, 50, 100 },
    },

}

Config.OUTSIDE_WARN_SECONDS = 0
Config.OUTSIDE_DAMAGE_AFTER_SECONDS = 2
Config.OUTSIDE_KILL_AFTER_SECONDS = 4
Config.OUTSIDE_ARENA_BUFFER = 2
Config.OUTSIDE_ARENA_MAX_BUFFER = 20
Config.OUTSIDE_IGNORE_TIERZONE = "ROGUESPAWN"
Config.OUTSIDE_SOUND_LOOP_MS = 3000

Config.SPRINTER_ADJUST_INTERVAL_SECONDS = 10
Config.SPRINTER_ADJUST_DIVISOR = 3

Config.SPAWN_INTERVAL_SECONDS = 8
Config.SPAWN_GROUP_BASE = 1
Config.SPAWN_GROUP_PER_PLAYER = 1
Config.SPAWN_GROUP_TIER_BONUS = 1
Config.SPAWN_GROUP_MAX = 40
Config.SPAWN_GROUP_DIVISOR = 2
Config.SPAWN_FIXED_POINT_COUNT = 32
Config.SPAWN_MAX_PER_POINT_PER_MINUTE = 0
Config.SPAWN_MAX_PER_MIN_BASE = 0
Config.SPAWN_MAX_PER_MIN_PER_PLAYER_SQRT = 0
Config.SPAWN_ARENA_BUFFER = 5
Config.ARENA_ALIVE_BUFFER = 12
Config.ARENA_KILL_BUFFER = 12
Config.ARENA_FAIL_GRACE_SECONDS = 3
Config.READY_TO_PREP_DELAY_MS = 3000

-- Arena beacon (server-side zombie attraction).
Config.BEACON_ENABLED = true
Config.BEACON_INTERVAL_SECONDS = 3
Config.BEACON_EXTRA_RADIUS = 15
Config.BEACON_TIER_STEP = 0
Config.BEACON_VOLUME = 70

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
    [3] = { min = 0.7, max = 1.3 },
    [4] = { min = 1, max = 1.5 },
    [5] = { min = 1.2, max = 1.7 },
    [6] = { min = 2, max = 3 },
}

Config.WAVE_CLEAR_BONUS_BASE = 10
Config.WAVE_CLEAR_BONUS_PER_ROUND = 5
Config.SPEED_CLEAR_MULTIPLIER = 1.25
Config.SLOW_CLEAR_MULTIPLIER = 0.75
Config.TIER_CLEAR_BONUS_MULT = 0.1
Config.WAVE_CLEAR_EARLY_BONUS_PCT = 0.15
Config.WAVE_CLEAR_ALIVE_BONUS_PCT = 0.15
Config.DEATH_CURRENCY_LOSS_PCT = 0.2

Config.STATS_SNAPSHOT_MINUTES = 5

Config.SHOP_CATEGORY_LABELS = {
    medical = "UI_rogue_shop_medical",
    weapons = "UI_rogue_shop_weapons",
    food = "UI_rogue_shop_food",
    supplies = "UI_rogue_shop_supplies",
    drugs = "UI_rogue_shop_drugs",
    perks = "UI_rogue_shop_perks",
    firearms = "UI_rogue_shop_firearms",
    builds = "UI_rogue_shop_builds",
}

Config.SHOP_SUBCATEGORIES = {
    weapons = {
        { id = "all", labelKey = "UI_rogue_shop_sub_all" },
        { id = "axes", labelKey = "UI_rogue_shop_sub_axes" },
        { id = "blunt", labelKey = "UI_rogue_shop_sub_blunt" },
        { id = "blades", labelKey = "UI_rogue_shop_sub_blades" },
        { id = "spears", labelKey = "UI_rogue_shop_sub_spears" },
    },
    firearms = {
        { id = "all", labelKey = "UI_rogue_shop_sub_all" },
        { id = "guns", labelKey = "UI_rogue_shop_sub_guns" },
        { id = "ammo", labelKey = "UI_rogue_shop_sub_ammo" },
        { id = "attachments", labelKey = "UI_rogue_shop_sub_attachments" },
    },
    supplies = {
        { id = "all", labelKey = "UI_rogue_shop_sub_all" },
        { id = "misc", labelKey = "UI_rogue_shop_sub_misc" },
        { id = "lighting", labelKey = "UI_rogue_shop_sub_lighting" },
        { id = "container", labelKey = "UI_rogue_shop_sub_container" },
        { id = "building", labelKey = "UI_rogue_shop_sub_building" },
    },
}

Config.SOUNDS = {
    shop_open = { "rogue_shop_open_1", "rogue_shop_open_2" },
    shop_buy_ok = { "rogue_shop_buy_ok_1", "rogue_shop_buy_ok_2" },
    shop_buy_fail = { "rogue_shop_buy_fail_1", "rogue_shop_buy_fail_2" },
    build_open = { "rogue_build_open_1" },
    build_buy_ok = { "rogue_build_buy_ok_1" },
    build_buy_fail = { "rogue_build_buy_fail_1" },
    round_prep = { "rogue_round_prep_1", "rogue_round_prep_2" },
    prep_countdown = { "rogue_prep_countdown" },
    round_start = { "rogue_round_start_1", "rogue_round_start_2" },
    round_clear = { "rogue_round_clear_1" },
    round_overtime_soon = { "rogue_round_overtime_soon_1" },
    round_overtime = { "rogue_round_overtime_1" },
    round_overtime_announce = { "rogue_round_overtime_announce_1" },
    bogdano_drink = { "BogdanoDrinkBurp" },
    serum_use = { "FullRestoreSerumSound" },
    out_of_bounds = { "out_of_bounds_geiger" },
    reward_reroll = { "reroll1", "reroll2" },
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

-- Item icons used in shop panels.
Config.SHOP_CATEGORY_ICON_ITEM = {
    medical = "Base.Bandage",
    weapons = "Base.BaseballBat",
    food = "Base.Apple",
    supplies = "Base.Battery",
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
    supplies = "media/textures/ui/supplyshopbg.png",
    drugs = "media/textures/ui/secretshopbg.png",
    perks = "media/textures/ui/secretshopbg.png",
    firearms = "media/textures/ui/gunshopbg.png",
    builds = "media/textures/ui/secretshopbg.png",
}
Config.UI_SHOP_PAD = 12
Config.SHOP_UI_MIN_ROWS = 10

Config.SHOP_MARKER_SIZE = 1.3
Config.SHOP_INTERACT_RADIUS = 1
Config.SHOP_MARKER_TEX_BY_CATEGORY = {}
Config.SHOP_MARKER_COLOR_BY_CATEGORY = {
    medical = { r = 0.2, g = 1.0, b = 0.6 },
    weapons = { r = 1.0, g = 0.2, b = 0.2 },
    food = { r = 1.0, g = 0.8, b = 0.2 },
    supplies = { r = 0.95, g = 0.9, b = 0.3 },
    drugs = { r = 0.7, g = 0.3, b = 1.0 },
    perks = { r = 0.8, g = 0.4, b = 0.1 },
    firearms = { r = 1.0, g = 0.5, b = 0.3 },
    builds = { r = 1.0, g = 0.8, b = 0.2 },
}
Config.SHOP_TILE_GLOW = {
    enabled = true,
    radius = 6,
    colorBoost = 0.25,
}
Config.ARENA_BORDER_MARKER_SIZE = 0.28
Config.ARENA_BORDER_MARKER_ALPHA = 0.65
Config.ARENA_BORDER_MARKER_COLOR = { r = 0.9, g = 0.05, b = 0.05 }

Config.SHOP_SPRITES = {
    medical = { "location_community_medical_01_89" },
    weapons = { "location_military_generic_01_1" },
    food = { "location_shop_zippee_01_56" },
    supplies = { "industry_02_50" },
    drugs = { "location_entertainment_gallery_02_56" },
    perks = {},
    firearms = { "location_military_generic_01_22" },
    builds = { "location_community_cemetary_01_11" },
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
Config.REWARD_REROLL_BASE_COST = 5
Config.REWARD_REROLL_STEP_COST = 5
Config.REWARD_REROLL_MAX = 0
Config.REWARD_REROLL_LEGENDA_DISCOUNT = 5
Config.BUILD_ID_LEGENDA = Config.BUILD_ID_LEGENDA or "roguelityno:la_leggenda"
Config.REWARD_LEGENDA_RARITY_BONUS = {
    common = -16,
    rare = 10,
    epic = 5,
    legendary = 1,
}
Config.MINIMAP_LAST_ZOMBIE_THRESHOLD = 10
Config.MINIMAP_LAST_ZOMBIE_INTERVAL_MS = 1000
Config.BUILD_ID_BOGDANO = Config.BUILD_ID_BOGDANO or "roguelityno:igor"
Config.VITAMINS_ENDURANCE_CHANGE_RANGE = { min = 0.05, max = 0.1 }
Config.BOGDANO_ENDURANCE_CHANGE_RANGE = { min = 0.5, max = 1.0 }
Config.SHOP_MAX_STOCK_PER_PLAYER = 2
Config.SHOP_MAX_STOCK_MIN = 10
Config.REWARD_PANEL_TEX = {
    common = "media/textures/ui/reward_panel_common.png",
    uncommon = "media/textures/ui/reward_panel_uncommon.png",
    rare = "media/textures/ui/reward_panel_rare.png",
    epic = "media/textures/ui/reward_panel_epic.png",
    legendary = "media/textures/ui/reward_panel_legendary.png",
}
Config.REWARD_RARITY_ICON_TEX = {
    common = "media/textures/ui/common_symbol.png",
    uncommon = "media/textures/ui/uncommon_symbol.png",
    rare = "media/textures/ui/rare_symbol.png",
    epic = "media/textures/ui/epic_symbol.png",
    legendary = "media/textures/ui/legendary_symbol.png",
}
Config.REWARD_TYPE_ICON_TEX = {
    currency = "media/textures/ui/wallet_icon.png",
    armor = "media/textures/ui/skills/blacksmith.png",
    weapon_longblade = "media/textures/ui/skills/longblade.png",
    weapon_blunt = "media/textures/ui/skills/blunt.png",
    weapon_smallblade = "media/textures/ui/skills/smallblade.png",
    weapon_smallblunt = "media/textures/ui/skills/smallblunt.png",
    weapon_axe = "media/textures/ui/skills/axe.png",
    weapon_spear = "media/textures/ui/skills/spear.png",
    firearm = "media/textures/ui/skills/aiming.png",
    ammo = "media/textures/ui/skills/reloading.png",
    misc = "media/textures/ui/Trait_lucky.png",
    drug = "media/textures/ui/Item_Droga5.png",
    heal = "media/textures/ui/Item_FullRestoreSerum_icon.png",
    skill = "media/textures/ui/skills/maintenance.png",
    skills = "media/textures/ui/skills/strength.png",
    xpBoost = "media/textures/ui/skills/fitness.png",
    trait = "media/textures/ui/Trait_fastlearner.png",
    blessing = "media/textures/ui/Trait_lucky.png",
}

Config.REWARD_RARITY_WEIGHTS = {
    early = { common = 60, uncommon = 25, rare = 12, epic = 2.75, legendary = 0.25 },
    late = { common = 30, uncommon = 35, rare = 25, epic = 8, legendary = 2 },
    clamp = { commonMin = 10, epicMax = 20, legendaryMax = 5 },
    tierBump = {
        tier5 = { rare = 2, epic = 2, common = -4 },
        tier6 = { epic = 3, legendary = 2, common = -5 },
    },
}


--da configurare per slot specifici
Config.REWARD_CATEGORY_RULES = {
}

-- Reward entries (server authoritative).
-- Shared fields:
--   type = "currency"|"item"|"heal"|"drug"|"trait"|"skill"|"skills"|"xpBoost"
--   buildIds = { "mod:buildId", ... }  -- optional allowlist; reward only for these builds
--   allBuilds = true                  -- optional; bypass build filtering and auto-mapping
-- type="currency": amount
-- type="item"/"heal"/"drug": id (Module.Item), qty
-- type="trait": id (TraitId without "base:"), toggles add/remove
-- type="skill": skill (PerkId string), levels (int)
-- type="skills": skills = { { id="PerkId", levels=int }, ... }
-- type="xpBoost": skill (PerkId string), amount (mult), durationRounds (int)
Config.REWARD_POOLS = {

common = {
    -- currency
    { type="currency", amount=10 },
    { type="currency", amount=15 },

    -- single skill (micro progress)
    { type="skill", skill="Nimble", levels=1 },
    { type="skill", skill="Sprinting", levels=1 },
    -- { type="skill", skill="Maintenance", levels=1 },
    { type="skill", skill="Blunt", levels=1 },
    { type="skill", skill="SmallBlunt", levels=1 },
    { type="skill", skill="LongBlade", levels=1 },
    { type="skill", skill="SmallBlade", levels=1 },
    { type="skill", skill="Axe", levels=1 },

    -- small xp boost (short)
    -- { type="xpBoost", skill="Maintenance", amount=1.25, durationRounds=2 },
    -- { type="xpBoost", skill="Nimble", amount=1.25, durationRounds=2 },
    -- { type="xpBoost", skill="Sprinting", amount=1.25, durationRounds=2 },
    -- { type="xpBoost", skill="Blunt", amount=1.25, durationRounds=2 },
    -- { type="xpBoost", skill="SmallBlade", amount=1.25, durationRounds=2 },

    -- utility items
    { type="item", id="Base.Bandage", qty=2 },
    { type="item", id="Base.AlcoholWipes", qty=1 },
    { type="item", id="Base.Pills", qty=1 },
    { type="item", id="Base.PillsBeta", qty=1 },
    { type="item", id="Base.Battery", qty=2 },

    { type="item", id="Base.Codpiece_Metal", qty=1 },


    { type="item", id="Base.TableLeg_Sawblade", qty=1 },
    { type="item", id="Base.TennisRacket", qty=1 },
    { type="item", id="Base.MetalPipe", qty=1 },
    { type="item", id="Base.SmallKnife", qty=2 },

    -- melee starter goodies

    -- build specific small flavor
    { type="item", id="Base.KnifeButterfly", qty=2, buildIds={ "roguelityno:bimbolama" } },
    
    { type="item", id="Base.AxeStone", qty=1, buildIds={ "roguelityno:uomo_ascia" } },
    
    { type="item", id="Base.Plank", qty=5, buildIds={ "roguelityno:uomo_sasso" } },
    
    { type="item", id="Base.Bullets38Box", qty=1, buildIds={ "roguelityno:americano" } },
    
    { type="item", id="Base.Cigar", qty=1, buildIds={ "roguelityno:igor" } },

    -- drugs (common: low tiers)
    { type="drug", id="Drogatyno.Droga1", qty=1 },

    --     { type="skills", skills={ {id="Sprinting",levels=1},{id="Nimble",levels=1} } },
    -- { type="skills", skills={ {id="SmallBlade",levels=1},{id="Maintenance",levels=1} } },
    -- { type="skills", skills={ {id="SmallBlunt",levels=1},{id="Maintenance",levels=1} } },
    -- { type="skills", skills={ {id="Axe",levels=1},{id="Maintenance",levels=1} } },
    --     { type="trait", id="Brave" },

},

uncommon = {
    -- currency
    { type="currency", amount=25 },
    { type="currency", amount=30 },

    -- multi-skill combos (uncommon feel good)
    { type="skills", skills={ {id="Sprinting",levels=1},{id="Nimble",levels=1} } },
    { type="skills", skills={ {id="SmallBlade",levels=1},{id="Maintenance",levels=1} } },
    { type="skills", skills={ {id="SmallBlunt",levels=1},{id="Maintenance",levels=1} } },
    { type="skills", skills={ {id="Axe",levels=1},{id="Maintenance",levels=1} } },

    -- stronger single skill
    { type="skill", skill="Maintenance", levels=1 },
    { type="skill", skill="Nimble", levels=2 },

    -- boosts (stable)
    -- { type="xpBoost", skill="Maintenance", amount=2, durationRounds=2 },
    -- { type="xpBoost", skill="Axe", amount=2, durationRounds=2 },
    -- { type="xpBoost", skill="Blunt", amount=2, durationRounds=2 },
    -- { type="xpBoost", skill="SmallBlade", amount=2, durationRounds=2 },

    -- items: weapons/utility step up
    { type="item", id="Base.Ratchet", qty=1 },
    { type="item", id="Base.Machete_Crude", qty=1 },
    { type="item", id="Base.MeatCleaver_Scrap", qty=1 },
    { type="item", id="Base.Screwdriver", qty=2 },
    { type="item", id="Base.IceHockeyStick_BarbedWire", qty=1 },
    { type="item", id="Base.Torch", qty=1 },

    { type="item", id="Base.ShinKneeGuard_R_Metal", qty=2 },
    { type="item", id="Base.Vambrace_FullMetal_Left", qty=2 },
    { type="item", id="Base.Hat_MetalHelmet", qty=1 },
    { type="item", id="Base.Thigh_ArticMetal_L", qty=2 },
    -- { type="item", id="Base.Shoulderpad_Articulated_L_Metal", qty=2 },

    -- heal (uncommon: low chance)
    -- drugs (mid)
    { type="drug", id="Drogatyno.Droga1", qty=2 },
    { type="drug", id="Drogatyno.Droga2", qty=1 },

    -- build specific: theme packs
    { type="skills", skills={ {id="SmallBlade",levels=1},{id="Nimble",levels=1} }, buildIds={ "roguelityno:bimbolama" } },
    
    { type="skills", skills={ {id="Axe",levels=1},{id="Woodwork",levels=1} }, buildIds={ "roguelityno:uomo_ascia" } },
    
    { type="skills", skills={ {id="Blacksmith",levels=1},{id="Masonry",levels=1} }, buildIds={ "roguelityno:uomo_sasso" } },
    
    { type="skills", skills={ {id="Aiming",levels=1},{id="Reloading",levels=1} }, buildIds={ "roguelityno:americano" } },
    
    { type="item", id="Base.Whistle", qty=1, buildIds={ "roguelityno:mr_rumble" } },
    
    { type="item", id="Base.Gin", qty=1, buildIds={ "roguelityno:igor" } },
    
    { type="currency", amount=28, buildIds={ "roguelityno:la_leggenda" } },
},

rare = {
    -- currency
    { type="currency", amount=40 },
    { type="currency", amount=45 },

    -- skills (rare: meaningful)
    { type="skill", skill="Axe", levels=2 , buildIds={ "roguelityno:uomo_ascia" }},
    { type="skill", skill="Blunt", levels=2 , buildIds={ "roguelityno:igor",  "roguelityno:uomo_sasso"}},
    { type="skill", skill="SmallBlunt", levels=2 , buildIds={  "roguelityno:igor",  "roguelityno:uomo_sasso"}},
    { type="skill", skill="SmallBlade", levels=2 , buildIds={ "roguelityno:bimbolama" }},
    { type="skill", skill="LongBlade", levels=2 , anyClass = true},
    { type="skill", skill="Sprinting", levels=2 },
    { type="skill", skill="Nimble", levels=2 },

    -- combo “role”
    { type="skills", skills={ {id="Sprinting",levels=2},{id="Nimble",levels=1} } },
    { type="skills", skills={ {id="Maintenance",levels=2} } },

    -- boosts (rare stable)
    -- { type="xpBoost", skill="Aiming", amount=2, durationRounds=2 },
    -- { type="xpBoost", skill="Axe", amount=1.5, durationRounds=2 },
    -- { type="xpBoost", skill="Blunt", amount=1.5, durationRounds=2 },
    -- { type="xpBoost", skill="Blunt", amount=1.5, durationRounds=2 },
    -- { type="xpBoost", skill="Blunt", amount=1.5, durationRounds=2 },
    -- { type="xpBoost", skill="Maintenance", amount=1.5, durationRounds=2 },

    -- items (rare weapons/ammos)
    { type="item", id="Base.Hatchet_Bone", qty=1 },

    { type="item", id="Base.BaseballBat_Metal_Sawblade", qty=1 },
    
    { type="item", id="Base.HandguardDagger", qty=2 },

    { type="item", id="Base.CanoePadelX2", qty=1 },
    
    { type="item", id="Base.Sword", qty=1 },
    
    { type="item", id="Base.Revolver", qty=1 },
    
    { type="item", id="Base.Bullets9mmBox", qty=1 },
    
    { type="item", id="Base.Bullets45Box", qty=1 },
    { type="item", id="Base.9mmClip", qty=1 },
    { type="item", id="Base.45Clip", qty=1 },
    { type="item", id="Rogue.ModKit_Special", qty=1 },
    
    { type="item", id="Base.Cuirass_Metal", qty=1 },

    -- drugs (rare)
        -- drugs (mid)
    { type="drug", id="Drogatyno.Droga2", qty=2 },
    { type="drug", id="Drogatyno.Droga3", qty=1 },

    -- traits (rare spicy but not game-breaking)
    { type="trait", id="Brave" },

    -- build specific rare spice
    { type="skills", skills={ {id="Aiming",levels=2},{id="Reloading",levels=2} }, buildIds={ "roguelityno:americano" } },
    
    { type="skills", skills={ {id="SmallBlade",levels=2},{id="Nimble",levels=2} }, buildIds={ "roguelityno:bimbolama" } },
    
    { type="skills", skills={ {id="Axe",levels=2},{id="Strength",levels=1} }, buildIds={ "roguelityno:uomo_ascia", "roguelityno:la_leggenda" } },
    
    { type="skills", skills={ {id="Blacksmith",levels=2},{id="MetalWelding",levels=1} }, buildIds={ "roguelityno:uomo_sasso", "roguelityno:igor" } },
    
    { type="item", id="Base.AlarmClock", qty=2, buildIds={ "roguelityno:mr_rumble" } },
    
    { type="item", id="Base.Whiskey", qty=2, buildIds={ "roguelityno:igor" } },
    
    { type="currency", amount=40, buildIds={ "roguelityno:la_leggenda" } },
},

epic = {
    -- currency
    { type="currency", amount=60 },
    { type="currency", amount=65 },

    -- big skill combos
    { type="skills", skills={ {id="Aiming",levels=3},{id="Reloading",levels=2} } },
    { type="skills", skills={ {id="Axe",levels=3},{id="Maintenance",levels=2} } },
    { type="skills", skills={ {id="Blunt",levels=3},{id="Maintenance",levels=2} } },
    { type="skills", skills={ {id="Nimble",levels=3},{id="Sprinting",levels=2} } },
    { type="skills", skills={ {id="SmallBlade",levels=3},{id="Nimble",levels=2} } },

    -- CATCH-UP BOOSTS: 1 ROUND ONLY
    { type="xpBoost", skill="Axe", amount=4.0, durationRounds=1 },
    { type="xpBoost", skill="Blunt", amount=4.0, durationRounds=1 },
    { type="xpBoost", skill="SmallBlunt", amount=4.0, durationRounds=1 },
    { type="xpBoost", skill="SmallBlade", amount=4.0, durationRounds=1 },
    { type="xpBoost", skill="LongBlade", amount=4.0, durationRounds=1 },
    { type="xpBoost", skill="Aiming", amount=4.0, durationRounds=1 },
    -- { type="xpBoost", skill="Reloading", amount=4.0, durationRounds=1 },
    { type="xpBoost", skill="Maintenance", amount=4.0, durationRounds=1 },

    -- -- stable epic boosts (alternativa)
    -- { type="xpBoost", skill="Maintenance", amount=3, durationRounds=3 },
    -- { type="xpBoost", skill="Aiming", amount=3, durationRounds=3 },

    -- items (epic)
    { type="item", id="Base.BaseballBat_Metal_Bolts", qty=1 },
    { type="item", id="Base.Revolver_Long", qty=1 },
    { type="item", id="Base.JawboneBovide_Axe", qty=1 },
    { type="item", id="Base.LongMace_Stone", qty=1 },
    { type="item", id="Base.Morningstar_Scrap_Short", qty=1 },
    { type="item", id="Base.Sword", qty=1 },
    { type="item", id="Base.FightingKnife", qty=2 },
    { type="item", id="Base.ShotgunShellsBox", qty=3 },
    { type="item", id="Base.556Box", qty=3 },
    { type="heal", id="Rogue.FullRestoreSerum", qty=1 },
    { type="item", id="Rogue.ModKit_Special", qty=1 },

    -- drugs (epic)
    { type="drug", id="Drogatyno.Droga3", qty=2 },
    { type="drug", id="Drogatyno.Droga4", qty=1 },

    -- traits (epic)
    { type="trait", id="EagleEyed" },


    -- -- build specific epic signature
    -- { type="xpBoost", skill="SmallBlade", amount=4.0, durationRounds=1, buildIds={ "roguelityno:bimbolama" } },
    
    -- { type="xpBoost", skill="Axe", amount=4.0, durationRounds=1, buildIds={ "roguelityno:uomo_ascia" } },
    
    -- { type="xpBoost", skill="Aiming", amount=4.0, durationRounds=1, buildIds={ "roguelityno:americano" } },
    
    -- { type="xpBoost", skill="SmallBlunt", amount=4.0, durationRounds=1, buildIds={ "roguelityno:igor" } },
    
    -- { type="xpBoost", skill="Blunt", amount=4.0, durationRounds=1, buildIds={ "roguelityno:uomo_sasso" } },
    
    { type="item", id="Base.Katana", qty=1, buildIds={ "roguelityno:mr_rumble" } },
    
    { type="currency", amount=55, buildIds={ "roguelityno:la_leggenda" } },
},

legendary = {
    -- currency
    { type="currency", amount=100 },

    -- stat spikes (cap a 10 server-side)
    { type="skill", skill="Strength", levels=3 },
    { type="skill", skill="Fitness", levels=2 },

    -- huge combos
    { type="skills", skills={ {id="Axe",levels=3},{id="Maintenance",levels=3} } },
    { type="skills", skills={ {id="Blunt",levels=3},{id="Maintenance",levels=3} } },
    { type="skills", skills={ {id="LongBlade",levels=3},{id="Maintenance",levels=3} } },
    { type="skills", skills={ {id="SmallBlunt",levels=3},{id="Maintenance",levels=3} } },
    { type="skills", skills={ {id="SmallBlade",levels=3},{id="Maintenance",levels=3} } },
    { type="skills", skills={ {id="Aiming",levels=3},{id="Reloading",levels=3} } },

    -- CATCH-UP BOOSTS: 1 ROUND ONLY (più forti)
    { type="xpBoost", skill="Axe", amount=6.0, durationRounds=1 },
    { type="xpBoost", skill="SmallBlade", amount=6.0, durationRounds=1 },
    { type="xpBoost", skill="LongBlade", amount=6.0, durationRounds=1 },
    { type="xpBoost", skill="Blunt", amount=6.0, durationRounds=1 },
    { type="xpBoost", skill="SmallBlunt", amount=6.0, durationRounds=1 },
    { type="xpBoost", skill="Aiming", amount=6.0, durationRounds=1 },
    { type="xpBoost", skill="Maintenance", amount=6.0, durationRounds=1 },

    -- -- “carry tecnico” (non catch-up): opzionale
    -- { type="xpBoost", skill="Aiming", amount=2.0, durationRounds=4 },
    -- { type="xpBoost", skill="Maintenance", amount=2.0, durationRounds=4 },

    -- items top
    { type="item", id="Base.AssaultRifle", qty=1 },
    { type="item", id="Base.AssaultRifle2", qty=1 },
    { type="item", id="Base.556Carton", qty=1 },
    { type="heal", id="Rogue.FullRestoreSerum", qty=3 },
    
    -- drugs top
    { type="drug", id="Drogatyno.Droga5", qty=1 },
    
    -- traits leggendari
    { type="trait", id="Desensitized" },
    { type="trait", id="Marksman" },
    
    -- build specific legendary identity
    { type="skills", skills={ {id="SmallBlade",levels=3},{id="Nimble",levels=3} }, buildIds={ "roguelityno:bimbolama" } },
    
    { type="skills", skills={ {id="Axe",levels=3},{id="Strength",levels=2} }, buildIds={ "roguelityno:uomo_ascia" } },
    { type="item", id="Base.WoodAxe", qty=1, buildIds={ "roguelityno:uomo_ascia" }},
    
    { type="skills", skills={ {id="Blunt",levels=3},{id="SmallBlunt",levels=3} }, buildIds={ "roguelityno:uomo_sasso" } },
    
    { type="skills", skills={ {id="Aiming",levels=3},{id="Reloading",levels=3} }, buildIds={ "roguelityno:americano" } },
    
    { type="skills", skills={ {id="Mechanics",levels=3},{id="MetalWelding",levels=3} }, buildIds={ "roguelityno:igor" } },
    
    -- { type="trait", id="Organized", buildIds={ "roguelityno:mr_rumble" } },
    
    { type="currency", amount=150, buildIds={ "roguelityno:la_leggenda" } },
}
}

Config.TRAIT_ICON_MAP = Config.TRAIT_ICON_MAP or {}
Config.SKILL_ICON_MAP = Config.SKILL_ICON_MAP or {}
Config.SKILL_ICON_MAP.Fitness = "media/textures/ui/skills/fitness.png"
Config.SKILL_ICON_MAP.Strength = "media/textures/ui/skills/strength.png"
Config.SKILL_ICON_MAP.Spear = "media/textures/ui/skills/spear.png"


--START 0 NON SPAWNA ALL INIIZO,START -1 INFINITO
Config.SHOP_ITEMS = {

    medical = {
        { id = "Rogue.FullRestoreSerum", price = 50.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 3, maxStock = 5 },
        { id = "Base.PillsBeta", price = 10.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.Gin", price = 30.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.PillsVitamins", price = 20.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.AlcoholWipes", price = 5.0, qty = 1, startStockPerPlayer = 1, restockPerPlayer = 0.6, restockEveryNrounds = 2 },
        { id = "Base.PillsAntiDep", price = 10.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.Pills", price = 10.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.Bandage", price = 10.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.8, restockEveryNrounds = 2 },
        { id = "Base.BandageBox", price = 50.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Bandaid", price = 2.0, qty = 1, startStockPerPlayer = 1.0, restockPerPlayer = 0.8, restockEveryNrounds = 1 },
        { id = "Base.AdhesiveBandageBox", price = 24.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
    },

    weapons = {
        { id = "Base.SwitchKnife", subcat = "blades", price = 20.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.KnifeButterfly", subcat = "blades", price = 20.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.KnifeSushi", subcat = "blades", price = 60.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.KnifeSushi", subcat = "blades", price = 60.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.HuntingKnife", subcat = "blades", price = 100.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.HandguardDagger", subcat = "blades", price = 100.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.Multitool", subcat = "blades", price = 100.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },

        { id = "Base.Machete_Crude", subcat = "blades", price = 30.0, qty = 1, startStockPerPlayer = 0.2, restockPerPlayer = 0.2, restockEveryNrounds = 4 },
        { id = "Base.ShortSword_Scrap", subcat = "blades", price = 60.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 4 },
        { id = "Base.Machete", subcat = "blades", price = 250.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 4 },
        
        { id = "Base.ShortBat", subcat = "blunt", price = 30.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.6, restockEveryNrounds = 2 },
        { id = "Base.ClubHammer", subcat = "blunt", price = 50.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.FireplacePoker", subcat = "blunt", price = 100.0, qty = 1, startStockPerPlayer = 0.9, restockPerPlayer = 0.7, restockEveryNrounds = 1 },
        { id = "Base.Hammer", subcat = "blunt", price = 250, qty = 1, startStockPerPlayer = 1.0, restockPerPlayer = 0.8, restockEveryNrounds = 1 },        
        { id = "Base.Mace_Stone", subcat = "blunt", price = 250.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },

        { id = "Base.LaCrosseStick", subcat = "blunt", price = 30.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.Golfclub", subcat = "blunt", price = 30.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.CanoePadelX2", subcat = "blunt", price = 60.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.BaseballBat_Nails", subcat = "blunt", price = 100.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.BoltCutters", subcat = "blunt", price = 250.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },


        { id = "Base.BaseballBat_RailSpike", subcat = "axes", price = 50.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.EntrenchingTool", subcat = "axes", price = 50.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Axe_Sawblade_Hatchet", subcat = "axes", price = 100.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.ScrapWeapon_Brake", subcat = "axes", price = 100.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Cudgel_Brake", subcat = "axes", price = 100.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.IceAxe", subcat = "axes", price = 150.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Axe_Old", subcat = "axes", price = 250.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 3 },

            },

    food = {
        { id = "Base.WaterBottle", price = 10.0, qty = 1, startStockPerPlayer = 1.2, restockPerPlayer = 0.8, restockEveryNrounds = 1 },
        { id = "Base.PopBottle", price = 10.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.6, restockEveryNrounds = 2 , maxStock = 10 },
        { id = "Base.Crisps2", price = 10.0, qty = 1, startStockPerPlayer = 0.9, restockPerPlayer = 0.2, restockEveryNrounds = 1 },
        { id = "Base.TortillaChips", price = 10.0, qty = 1, startStockPerPlayer = 0.9, restockPerPlayer = 0.2, restockEveryNrounds = 2 },
        { id = "Base.BeefJerky", price = 12.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.2, restockEveryNrounds = 2 },
        { id = "Base.DentedCan", price = 8.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 3, maxStock = 10 },
        { id = "Base.MysteryCan", price = 10.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 3 , maxStock = 10 },
        { id = "Base.CannedBolognese", price = 12.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 3 , maxStock = 10 },
        { id = "Base.Dogfood", price = 8.0, qty = 1, startStockPerPlayer = 1, restockPerPlayer = 1, restockEveryNrounds = 1 , maxStock = 10 },
        { id = "Base.CatTreats", price = 8.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.P38", price = 10.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
    },


    supplies = {
        { id = "Rogue.ModKit_Improvised", subcat = "misc", price = 20.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.5, restockEveryNrounds = 1 , maxStock = 10},
        { id = "Base.LighterDisposable", subcat = "misc", price = 5.0, qty = 0, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.Paperback", subcat = "misc", price = 20.0, qty = 0, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 , maxStock = 5 },
        { id = "Base.TobaccoLoose", subcat = "misc", price = 20.0, qty = 0, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 , maxStock = 5 },
        { id = "Base.CigaretteRollingPapers", subcat = "misc", price = 5.0, qty = 0, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 , maxStock = 5},
        { id = "Base.Battery", subcat = "misc", price = 10.0, qty = 1, startStockPerPlayer = 2.0, restockPerPlayer = 1.5, restockEveryNrounds = 1 },
        { id = "Base.DuctTape", subcat = "misc", price = 10.0, qty = 1, startStockPerPlayer = 0.1, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.Whetstone", subcat = "misc", price = 40.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.BatteryBox", subcat = "misc", price = 60.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.DuctTapeBox", subcat = "misc", price = 100.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.Hat_ArmyHelmet", subcat = "misc", price = 14.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.PetrolCan", subcat = "misc", price = 40.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.Bag_ALICE_BeltSus_Camo", subcat = "container", price = 40.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Base.Flashlight", subcat = "lighting", price = 50.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.FlashLight_AngleHead_Army", subcat = "lighting", price = 100.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Lantern_Propane", subcat = "lighting", price = 100.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Propane_Refill", subcat = "lighting", price = 20.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.2, restockEveryNrounds = 4 },
        { id = "Base.Bag_Schoolbag_Patches", subcat = "container", price = 30.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Bag_HydrationBackpack_Camo", subcat = "container", price = 60.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Bag_ALICEpack", subcat = "container", price = 80.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.Plank", subcat = "building", price = 10.0, qty = 2, startStockPerPlayer = -1, restockPerPlayer = 2, restockEveryNrounds = 1 },
        { id = "Base.NailsBox", subcat = "building", price = 20.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.6, restockEveryNrounds = 2 },
        { id = "Base.Saw", subcat = "building", price = 20.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.4, restockEveryNrounds = 3 },
        { id = "Base.SheetMetal", subcat = "building", price = 15.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.Needle", subcat = "building", price = 30.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.Thread", subcat = "building", price = 5.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
    },

    drugs = {
        { id = "Drogatyno.Droga1", price = 20.0, qty = 1, startStockPerPlayer = -1 , restockPerPlayer = 0.4, restockEveryNrounds = 1 },
        { id = "Drogatyno.Droga2", price = 50.0, qty = 1, startStockPerPlayer = 1 , restockPerPlayer = 0.4, restockEveryNrounds = 1 },
        { id = "Drogatyno.Droga3", price = 125.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Drogatyno.Droga4", price = 250.0, qty = 1, startStockPerPlayer = 0.5 , restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Drogatyno.Droga5", price = 350.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
    },

    perks = {
    },

    firearms = {
        { id = "Base.HolsterSimple_Black", subcat = "attachments", price = 15.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Base.HolsterShoulder", subcat = "attachments", price = 40.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Base.Pistol2", subcat = "guns", price = 40.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Base.Revolver", subcat = "guns", price = 50.0, qty = 1, startStockPerPlayer = 0.4, restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Base.Revolver_Long", subcat = "guns", price = 70.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 3, maxStock = 2},
        { id = "Base.Pistol3", subcat = "guns", price = 70.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.2, restockEveryNrounds = 3 },
        { id = "Base.Pistol", subcat = "guns", price = 100.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.3, restockEveryNrounds = 2 },
        { id = "Base.AssaultRifle", subcat = "guns", price = 100.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.15, restockEveryNrounds = 4, maxStock = 1 },
        { id = "Base.AssaultRifle2", subcat = "guns", price = 250.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.15, restockEveryNrounds = 4 , maxStock = 2},
        { id = "Base.HuntingRifle", subcat = "guns", price = 60.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 2 , maxStock = 3},
        { id = "Base.Shotgun", subcat = "guns", price = 80.0, qty = 1, startStockPerPlayer = 0.3, restockPerPlayer = 0.2, restockEveryNrounds = 3 , maxStock = 2},
        { id = "Base.Bullets9mmBox", subcat = "ammo", price = 20.0, qty = 1, startStockPerPlayer = 0.9, restockPerPlayer = 0.7, restockEveryNrounds = 1 },
        { id = "Base.Bullets45Box", subcat = "ammo", price = 20.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.3, restockEveryNrounds = 1, maxStock = 5 },
        { id = "Base.Bullets38Box", subcat = "ammo", price = 20.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 1, maxStock = 5 },
        { id = "Base.308Box", subcat = "ammo", price = 20.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.3, restockEveryNrounds = 1, maxStock = 5 },
        { id = "Base.Bullets44Box", subcat = "ammo", price = 20.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.4, restockEveryNrounds = 2 },
        { id = "Base.223Box", subcat = "ammo", price = 30.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.4, restockEveryNrounds = 1, maxStock = 5 },
        { id = "Base.ShotgunShellsBox", subcat = "ammo", price = 30.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.5, restockEveryNrounds = 2, maxStock = 5 },
        { id = "Base.556Box", subcat = "ammo", price = 50.0, qty = 1, startStockPerPlayer = 0.9, restockPerPlayer = 0.7, restockEveryNrounds = 1, maxStock = 5 },
        { id = "Base.45Clip", subcat = "ammo", price = 10.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.9mmClip", subcat = "ammo", price = 15.0, qty = 1, startStockPerPlayer = 0.8, restockPerPlayer = 0.6, restockEveryNrounds = 3 },
        { id = "Base.44Clip", subcat = "ammo", price = 15.0, qty = 1, startStockPerPlayer = 0.7, restockPerPlayer = 0.5, restockEveryNrounds = 2 },
        { id = "Base.M14Clip", subcat = "ammo", price = 20.0, qty = 1, startStockPerPlayer = 0.5, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.556Clip", subcat = "ammo", price = 30.0, qty = 1, startStockPerPlayer = 0.6, restockPerPlayer = 0.4, restockEveryNrounds = 3 },
        { id = "Base.Laser", subcat = "attachments", price = 20.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.RedDot", subcat = "attachments", price = 40.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
        { id = "Base.GunLight", subcat = "attachments", price = 50.0, qty = 1, startStockPerPlayer = 0, restockPerPlayer = 0.3, restockEveryNrounds = 3 },
    },
}

Config.STARTING_CURRENCY = 70
Config.STARTING_CURRENCY_BY_DIFFICULTY = {
    [1] = 70,
    [2] = 70,
    [3] = 85,
    [4] = 100,
    [5] = 120,
}

Config.BUILD_REBUY_COST = 30

Config.GLOBAL_XP_BOOST_MULT = 0
Config.GLOBAL_XP_BOOSTS = {}

Config.BUILD_SHOP = {
    -- { id = "roguelityno:test_build", price = 0 },
    { id = "roguelityno:bimbolama", price = 50 },
    { id = "roguelityno:uomo_ascia", price = 70 },
    { id = "roguelityno:uomo_sasso", price = 40 },
    { id = "roguelityno:americano", price = 40 },
    { id = "roguelityno:la_leggenda", price = 30 },
    { id = "roguelityno:igor", price = 50 },
    { id = "roguelityno:mr_rumble", price = 30 },
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
        skills = { Axe = 3 },
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
        desc = "Assassino mobile: velocita' alta e critico con lame corte. Glass cannon, non perdona ma letale se giocato bene.\nABILITA SPECIALE: Colpire con le lame accumula un bonus alla probabilita' di critico, decade rapidamente fuori dal combattimento",
        icon = "profession_burglar",
        iconItem = "Base.KnifeButterfly",
        skills = { SmallBlade = 4, Nimble = 3, Sprinting = 3, Maintenance = 1, LightFoot = 4, Doctor = 4},
        xpBoosts = {
            LongBlade = 2,
            SmallBlade = 2,
        },
        startingStats = { Strength = 3, Fitness = 10 },
        traits = {
            -- Positiv
            "base:nightvision",       
            "base:dextrous",          
            "base:adrenalinejunkie",
            "base:graceful",          
            "base:gymnast",           
            "base:fasthealer",        
            -- Negativi
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
        desc = "Brutalita' primitiva: camicia a quadri, analfabeta, ascia, spacca!\nABILITA SPECIALE: Entra nella mischia con statistiche aumentate, ma la sua etica di ferro gli impedisce di usare droghe.",
        icon = "profession_lumberjack",
        iconItem = "Base.Axe",
        skills = { Axe = 4, Maintenance = 1, Woodwork = 4 , Nimble = 2},
        xpBoosts = {
            Axe = 2,
        },
        startingStats = { Strength = 8, Fitness = 8 },
        traits = {
            "base:nightvision",
            "base:resilient",
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
        desc = "Artigiano anti-tecnologia: controlla l'area con le costruzioni e picchia duro persino con le sue assi.\nABILITA SPECIALE: Costruttore provetto, costruisce barricate e staccionate potenziate a ritmo folle!",
        icon = "profession_constructionworker",
        iconItem = "Base.LargeStone",
        skills = {Blunt = 4, Maintenance = 2, Woodwork = 10, Nimble = 1, Sprinting = 2, Carving = 10},
        xpBoosts = {
            Blunt = 2,
            Maintenance = 1,
        },
        startingStats = { Strength = 10, Fitness = 7 },
        traits = {
            "base:graceful",
            "base:nightvision",
            "base:dextrous",
            "base:handy",
            "base:crafty",
            -- "base:fastlearner",       -- Allievo modello
            "base:outdoorsman",       -- uomo natura
            "base:organized",
            "base:motionsickness"
        },
        loadout = {
            { id = "Base.HammerStone", qty = 1 },
            { id = "Base.Saw", qty = 1 },
            { id = "Base.NailsBox", qty = 1 },
            { id = "Base.Plank", qty = 4 },
            -- arma primitiva base
            { id = "Base.Bag_TarpFramepack_Large", qty = 1 },
            { id = "Base.BaseballBat_GardenForkHead", qty = 1 },
            { id = "Base.AlcoholRippedSheets", qty = 2 },
            { id = "Base.WaterBottle", qty = 1 },
        },
    },

    {
        id = "roguelityno:americano",
        name = "AMERICANO",
        desc = "Goblin del loot: arraffa tutto, preferisce armi da fuoco. Codardo ed emofobico: forte in gruppo, crolla da solo.\nABILITA SPECIALE: Riceve un proiettile per la sua preziosa 38 alla fine del round per ogni testa spaccata.",
        icon = "profession_veteran",
        iconItem = "Base.Pistol",
        skills = { Aiming = 4, Reloading = 4, LongBlade = 3, Nimble = 3, Sprinting = 2, Doctor = 4},
        xpBoosts = {
            LongBlade = 1,
            Reloading = 2,
            Aiming = 2,
        },
        startingStats = { Strength = 6, Fitness = 7 },
        traits = {
            "base:nightvision",
            "base:cowardly",
            -- "base:claustrophobic",    --anti camper
            "base:hemophobic",
            "base:keenhearing",
            "base:eagleeyed",
            "base:dextrous",
            "base:marksman",
        },
        loadout = {
            { id = "Base.Bag_RifleCaseClothCamo", qty = 1 },
            { id = "Base.Revolver_Short", qty = 1 },             
            { id = "Base.Bullets38Box", qty = 2 },
            { id = "Base.Holster_DuctTape", qty = 1 },
            { id = "Base.WaterBottle", qty = 1 },
            { id = "Base.Bandaid", qty = 1 },
            { id = "Base.Lighter", qty = 1 },
        },
    },

    {
        id = "roguelityno:la_leggenda",
        name = "LA LEGGENDA",
        desc = "Allrounder leggendario e versatile. Inizia con due Droghe2, impara in fretta e ricompense aumentate.\nABILITA SPECIALE: Paga di meno i reroll, ha boost fissi su tutte le armi e accede da subito a delle ricompense piu forti",
        icon = "profession_fireofficer",
        iconItem = "Base.Hat_Beany",
        skills = {Nimble = 1, Sprinting = 2, Reloading = 4},
        xpBoosts = {
            Axe = 2,
            SmallBlunt = 2,
            Blunt = 2,
            LongBlade = 2,
            SmallBlade = 2,
            Aiming = 1,
        },
        startingStats = { Strength = 7, Fitness = 8 },
        traits = {
            "base:nightvision",      
            "base:fastlearner",      
            "base:brave",       
            -- "base:brawler",
            --to be tratto che paga meno le droghe?
        },
    loadout = {
            { id = "Base.Jacket_LeatherBlack", qty = 1 },  
            { id = "Base.Hat_Beany", qty = 1 },
            { id = "Drogatyno.Droga2", qty = 2 },
            { id = "Base.WaterBottle", qty = 1 },
            { id = "Base.MetalPipe", qty = 1 },
            { id = "Base.Bandage", qty = 2 },
        },
    },

    {
        id = "roguelityno:igor",
        name = "BOGDANO",
        desc = "Forza bruta, contundenti corti, mira ubriaca, polmoni bucati.\nABILITA SPECIALE:Fuma per recuperare un po' di fiato o fagli SCOLARE una bella bottiglia piena col tasto destro e torna come nuovo, proprio come la vecchia Betty!",
        icon = "profession_mechanic",
        iconItem = "Base.BlowTorch",
        skills = { Maintenance = 2, SmallBlunt = 4, Nimble = 2, Aiming = 2, Reloading = 4, MetalWelding = 6},
        xpBoosts = {
            SmallBlunt = 2,
            Blunt = 2,
            Maintenance = 2,
        },
        startingStats = { Strength = 8, Fitness = 5 },
        traits = {
            "base:nightvision",       -- Cat's Eyes
            "base:smoker",
            "base:allthumbs",
            "base:mechanics",
        },
        loadout = {
            { id = "Base.Ratchet", qty = 1 },            
            { id = "Base.Whiskey", qty = 1 },       
            { id = "Base.Cigar", qty = 2 },        
            { id = "Base.Lighter", qty = 1 },           
            { id = "Base.WaterBottle", qty = 1 },
            { id = "Base.CanPipe", qty = 1 },
            { id = "Base.EngineMaul", qty = 1 },
        },
    },

    {
        id = "roguelityno:mr_rumble",
        name = "MR RUMBLE",
        desc = "Il tuttofare dell'apocalisse, ingengoso e incosciente. Riesce ad arrangiarsi come nessun altro.\nABILITA SPECIALE: Smantella le armi rotte o con poca durabilita', a volte recupera anche oggetti preziosi!",
        icon = "profession_engineer",
        iconItem = "Base.AlarmClock",
        skills = { Maintenance = 4, Nimble = 3, Sprinting = 3, Doctor = 6},
        xpBoosts = {Maintenance = 4},
        startingStats = { Strength = 7, Fitness = 7 },
        traits = {
            "base:conspicuous",   
            "base:organized",     
        },
        loadout = {
            { id = "Base.DuctTape", qty = 1 },
            { id = "Base.ZipTie", qty = 3 },
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
    if preset.spawnIntervalSeconds then
        Config.SPAWN_INTERVAL_SECONDS = preset.spawnIntervalSeconds
    end
    if preset.spawnGroupMult then
        Config.SPAWN_GROUP_MULT = preset.spawnGroupMult
    end
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

function Config.getStartingCurrency(difficultyId)
    local idx = tonumber(difficultyId) or tonumber(Config.DIFFICULTY_LEVEL) or 1
    local map = Config.STARTING_CURRENCY_BY_DIFFICULTY or {}
    local value = map[idx]
    if value == nil then
        return tonumber(Config.STARTING_CURRENCY) or 0
    end
    return tonumber(value) or 0
end

function Config.getRectCenter(rect)
    if not rect or rect.x1 == nil or rect.x2 == nil or rect.y1 == nil or rect.y2 == nil then
        return nil
    end
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


