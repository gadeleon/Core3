-- Shared test data and builders for Crimson Phoenix Squadron tier 3, Part A (Arnecio Ulvaw'op's missions), not a test file.
-- Spec: .claude/work/crimson-phoenix-tier3-ulvawop-missions/01-spec.md (Content contract, Data mapping, Appendix B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of agreeing with itself
-- (test_crimson_tier3_missions_data.lua proves the literals equal the SWG .tab fixtures):
--   T.GLOBALS / T.IDENTITY     the 17 quest globals and their class, type, name and zone (Content contract 1)
--   T.M1 .. T.M4 / T.CHAINS    the four chains, members in chain order (= letter order)
--   T.QUEST_STRINGS            the 17 TIER3_* constants of CrimsonPhoenixSquadronScreenplay (Content contract 3)
--   T.statusKeys()             the 8 ":attempted" / ":reward" keys
--   T.POINTS / T.SPAWNERS      Data mapping 2: the 45 nav points and the 2 inspect spawners, per zone, Core3 x, z, y
--   T.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   T.load() / T.quest / T.squadron   the server's load (crimson_tier2_data.lua's); a missing production file is recorded, not raised
--   T.pilot{...}               a Crimson Phoenix pilot who finished tier 2, with optional tier 3 state (see the option list at T.pilot)
--   T.flyer(zone)              a Rebel pilot in a Rebel ship in `zone`, for the runtime tests
-- Part B (crimson-phoenix-tier3-ulvawop, Arnecio Ulvaw'op's conversation) extends this file below "Part B".

local H = require("harness")
local C = require("crimson_tier1_data")
local E = require("crimson_tier2_data")

local T = {}

T.SQUADRON_FILE = C.SQUADRON_FILE
T.SHIP_DIR = "ship_mobile/ships/"

local DT, DA, EN, LK = "space_dathomir", "space_dantooine", "space_endor", "space_lok"

T.M1 = { "recovery_tatooine_rebel_tier3_1", "delivery_tatooine_rebel_tier3_1_a", "survival_tatooine_rebel_tier3_1_b", "escort_tatooine_rebel_tier3_1_c" }
T.M2 = {
	"inspect_tatooine_rebel_tier3_2", "destroy_surpriseattack_tatooine_rebel_tier3_2_a", "assassinate_tatooine_rebel_tier3_2_b", "space_battle_tatooine_rebel_tier3_2_c",
}
T.M3 = { "delivery_tatooine_rebel_tier3_3", "space_battle_tatooine_rebel_tier3_3_a", "escort_tatooine_rebel_tier3_3_b", "survival_tatooine_rebel_tier3_3_c" }
T.M4 = {
	"assassinate_tatooine_rebel_tier3_4", "patrol_tatooine_rebel_tier3_4_a", "destroy_surpriseattack_tatooine_rebel_tier3_4_b",
	"delivery_no_pickup_tatooine_rebel_tier3_4_c", "space_battle_tatooine_rebel_tier3_4_d",
}

T.CHAINS = { T.M1, T.M2, T.M3, T.M4 }

T.GLOBALS = {}

for _, chain in ipairs(T.CHAINS) do
	for _, g in ipairs(chain) do
		T.GLOBALS[#T.GLOBALS + 1] = g
	end
end

T.HEADS = { T.M1[1], T.M2[1], T.M3[1], T.M4[1] }
T.ENDS = { T.M1[4], T.M2[4], T.M3[4], T.M4[5] }

-- the tier 1-2 globals, which the 17 follow in the registration order
T.EARLIER_GLOBALS = {}

for _, g in ipairs(E.TIER1_GLOBALS) do
	T.EARLIER_GLOBALS[#T.EARLIER_GLOBALS + 1] = g
end

for _, g in ipairs(E.GLOBALS) do
	T.EARLIER_GLOBALS[#T.EARLIER_GLOBALS + 1] = g
end

-- Content contract 1
T.IDENTITY = {}

local function id(global, class, type_, name, zone) T.IDENTITY[global] = { class = class, type = type_, name = name, zone = zone } end

id(T.M1[1], "SpaceRecoveryScreenplay", "recovery", "tatooine_rebel_tier3_1", DT)
id(T.M1[2], "SpaceDeliveryScreenplay", "delivery", "tatooine_rebel_tier3_1_a", DT)
id(T.M1[3], "SpaceSurvivalScreenplay", "survival", "tatooine_rebel_tier3_1_b", DT)
id(T.M1[4], "SpaceEscortScreenplay", "escort", "tatooine_rebel_tier3_1_c", DT)
id(T.M2[1], "SpaceInspectScreenplay", "inspect", "tatooine_rebel_tier3_2", DT)
id(T.M2[2], "SpaceSurpriseAttackScreenplay", "destroy_surpriseattack", "tatooine_rebel_tier3_2_a", DT)
id(T.M2[3], "SpaceAssassinateScreenplay", "assassinate", "tatooine_rebel_tier3_2_b", DA)
id(T.M2[4], "SpaceBattleScreenplay", "space_battle", "tatooine_rebel_tier3_2_c", DA)
id(T.M3[1], "SpaceDeliveryScreenplay", "delivery", "tatooine_rebel_tier3_3", LK)
id(T.M3[2], "SpaceBattleScreenplay", "space_battle", "tatooine_rebel_tier3_3_a", DT)
id(T.M3[3], "SpaceEscortScreenplay", "escort", "tatooine_rebel_tier3_3_b", DT)
id(T.M3[4], "SpaceSurvivalScreenplay", "survival", "tatooine_rebel_tier3_3_c", DT)
id(T.M4[1], "SpaceAssassinateScreenplay", "assassinate", "tatooine_rebel_tier3_4", EN)
id(T.M4[2], "SpacePatrolScreenplay", "patrol", "tatooine_rebel_tier3_4_a", EN)
id(T.M4[3], "SpaceSurpriseAttackScreenplay", "destroy_surpriseattack", "tatooine_rebel_tier3_4_b", EN)
id(T.M4[4], "SpaceDeliveryNoPickupScreenplay", "delivery_no_pickup", "tatooine_rebel_tier3_4_c", EN)
id(T.M4[5], "SpaceBattleScreenplay", "space_battle", "tatooine_rebel_tier3_4_d", EN)

-- Content contract 3
T.QUEST_STRINGS = {
	TIER3_QUEST_STRING_1 = { type = "recovery", name = "tatooine_rebel_tier3_1" },
	TIER3_QUEST_STRING_1_SIDE1 = { type = "delivery", name = "tatooine_rebel_tier3_1_a" },
	TIER3_QUEST_STRING_1_SIDE2 = { type = "survival", name = "tatooine_rebel_tier3_1_b" },
	TIER3_QUEST_STRING_1_SIDE3 = { type = "escort", name = "tatooine_rebel_tier3_1_c" },
	TIER3_QUEST_STRING_2 = { type = "inspect", name = "tatooine_rebel_tier3_2" },
	TIER3_QUEST_STRING_2_SIDE1 = { type = "destroy_surpriseattack", name = "tatooine_rebel_tier3_2_a" },
	TIER3_QUEST_STRING_2_SIDE2 = { type = "assassinate", name = "tatooine_rebel_tier3_2_b" },
	TIER3_QUEST_STRING_2_SIDE3 = { type = "space_battle", name = "tatooine_rebel_tier3_2_c" },
	TIER3_QUEST_STRING_3 = { type = "delivery", name = "tatooine_rebel_tier3_3" },
	TIER3_QUEST_STRING_3_SIDE1 = { type = "space_battle", name = "tatooine_rebel_tier3_3_a" },
	TIER3_QUEST_STRING_3_SIDE2 = { type = "escort", name = "tatooine_rebel_tier3_3_b" },
	TIER3_QUEST_STRING_3_SIDE3 = { type = "survival", name = "tatooine_rebel_tier3_3_c" },
	TIER3_QUEST_STRING_4 = { type = "assassinate", name = "tatooine_rebel_tier3_4" },
	TIER3_QUEST_STRING_4_SIDE1 = { type = "patrol", name = "tatooine_rebel_tier3_4_a" },
	TIER3_QUEST_STRING_4_SIDE2 = { type = "destroy_surpriseattack", name = "tatooine_rebel_tier3_4_b" },
	TIER3_QUEST_STRING_4_SIDE3 = { type = "delivery_no_pickup", name = "tatooine_rebel_tier3_4_c" },
	TIER3_QUEST_STRING_4_SIDE4 = { type = "space_battle", name = "tatooine_rebel_tier3_4_d" },
}

-- the constants in contract order (chain order)
T.QUEST_STRING_FIELDS = {
	"TIER3_QUEST_STRING_1", "TIER3_QUEST_STRING_1_SIDE1", "TIER3_QUEST_STRING_1_SIDE2", "TIER3_QUEST_STRING_1_SIDE3",
	"TIER3_QUEST_STRING_2", "TIER3_QUEST_STRING_2_SIDE1", "TIER3_QUEST_STRING_2_SIDE2", "TIER3_QUEST_STRING_2_SIDE3",
	"TIER3_QUEST_STRING_3", "TIER3_QUEST_STRING_3_SIDE1", "TIER3_QUEST_STRING_3_SIDE2", "TIER3_QUEST_STRING_3_SIDE3",
	"TIER3_QUEST_STRING_4", "TIER3_QUEST_STRING_4_SIDE1", "TIER3_QUEST_STRING_4_SIDE2", "TIER3_QUEST_STRING_4_SIDE3", "TIER3_QUEST_STRING_4_SIDE4",
}

-- Status keys (set by Part B's handler): <name>:attempted and <name>:reward for the four mission heads
T.STATUS = { "tatooine_rebel_tier3_1", "tatooine_rebel_tier3_2", "tatooine_rebel_tier3_3", "tatooine_rebel_tier3_4" }

function T.statusKeys()
	local out = {}

	for _, name in ipairs(T.STATUS) do
		out[#out + 1] = name .. ":attempted"
		out[#out + 1] = name .. ":reward"
	end

	return out
end

T.EKER_PILOT_KEY = C.EKER_PILOT_KEY

-- Data mapping 2: zone -> name -> { x, z, y } (Core3 x, z, y = buildout PX, PY, PZ truncated toward zero)
T.POINTS = {
	space_dathomir = {
		tatooine_rebel_tier3_1_escort_1 = { -2600, 1250, 3950 },
		tatooine_rebel_tier3_1_escort_2 = { -3385, 992, 3576 },
		tatooine_rebel_tier3_1_escort_3 = { -4153, 742, 3237 },
		tatooine_rebel_tier3_1_escort_4 = { -4907, 592, 2027 },
		tatooine_rebel_tier3_1_escort_5 = { -5134, 384, 788 },
		tatooine_rebel_tier3_1_escort_6 = { -6083, 222, -852 },
		tatooine_rebel_tier3_1_recovery_1 = { -4428, 525, 2549 },
		tatooine_rebel_tier3_1_recovery_2 = { -3736, 462, 2153 },
		tatooine_rebel_tier3_1_recovery_3 = { -2477, 314, 1389 },
		tatooine_rebel_tier3_1_recovery_4 = { -739, 135, 411 },
		tatooine_rebel_tier3_1_a_pickup = { 45, -750, -2563 },
		tatooine_rebel_tier3_1_a_delivery = { 3523, -789, -3670 },
		tatooine_rebel_tier3_1_b_survival = { 1411, -444, -1499 },
		tatooine_rebel_tier3_1_c_escort_1 = { -2300, 3250, 2950 },
		tatooine_rebel_tier3_1_c_escort_2 = { -1740, 2006, 1861 },
		tatooine_rebel_tier3_1_c_escort_3 = { -697, 1383, 2052 },
		tatooine_rebel_tier3_1_c_escort_4 = { -281, 843, 893 },
		tatooine_rebel_tier3_3_delivery = { 400, -5100, 800 },
		tatooine_rebel_tier3_3_a_battlepoint = { -2904, 2100, -1200 },
		tatooine_tier3_3_b_escort_1 = { -3641, 2261, -2029 },
		tatooine_tier3_3_b_escort_2 = { -2298, 1181, -2833 },
		tatooine_tier3_3_b_escort_3 = { -1589, 894, -3630 },
		tatooine_tier3_3_b_escort_4 = { 895, -2, -5996 },
	},
	space_dantooine = {
		tatooine_tier3_2_b_escape_1 = { 2850, -4260, 3800 },
		tatooine_tier3_2_b_escape_2 = { 3723, -3570, 2929 },
		tatooine_tier3_2_b_escape_3 = { 4217, -2877, 2337 },
		tatooine_tier3_2_b_escape_4 = { 4768, -2089, 1703 },
		tatooine_tier3_2_b_escape_5 = { 5546, -1155, 820 },
		tatooine_tier3_2_b_escape_6 = { 6572, -120, -68 },
		tatooine_rebel_tier3_2_c_battlepoint = { -2871, -5018, 4524 },
	},
	space_lok = {
		tatooine_rebel_tier3_3_pickup = { -3950, -1000, 3800 },
	},
	space_endor = {
		tatooine_rebel_tier3_4_escort_1 = { -2000, -4256, 3250 },
		tatooine_rebel_tier3_4_escort_2 = { -1798, -3966, 3935 },
		tatooine_rebel_tier3_4_escort_3 = { -1562, -3260, 4734 },
		tatooine_rebel_tier3_4_escort_4 = { -1156, -2480, 5935 },
		tatooine_rebel_tier3_4_escort_5 = { 4, -1362, 6827 },
		tatooine_rebel_tier3_4_escort_6 = { 1485, 488, 5203 },
		tatooine_rebel_tier3_4_a_patrol_1 = { -4200, -4000, -5000 },
		tatooine_rebel_tier3_4_a_patrol_2 = { -4648, -4197, -5804 },
		tatooine_rebel_tier3_4_a_patrol_3 = { -5046, -4899, -6558 },
		tatooine_rebel_tier3_4_a_patrol_4 = { -5851, -4452, -6545 },
		tatooine_rebel_tier3_4_c_delivery = { -2344, -1799, -1343 },
		tatooine_rebel_tier3_4_d_battlepoint = { -73, 584, -1550 },
	},
}

T.SPAWNERS = {
	space_dathomir = {
		tatooine_rebel_tier3_2_suspect_1 = { 5585, 4809, -2403 },
		tatooine_rebel_tier3_2_suspect_2 = { 4719, 5053, -3111 },
	},
}

T.ITEM_ROOT = "object/tangible/ship/components/"
T.CREDITS = 25000

-- Source inventory 1 (JU:240-271): one item per head
T.ITEMS = {
	"armor/arm_mission_reward_rebel_corellian_triplate.iff",
	"weapon_capacitor/cap_mission_reward_rebel_qualdex_battery_array.iff",
	"engine/eng_mission_reward_rebel_incom_military.iff",
	"reactor/rct_mission_reward_rebel_slayn_hypervortex.iff",
}

-- Data mapping 1: battle forwards (excerpt fltKX, fltKY, fltKZ -> x, z, y)
T.FORWARD_2C = { x = -0.223158, z = -0.900013, y = 0.374402 }
T.FORWARD_3A = { x = 0.937720, z = -0.026811, y = 0.346356 }
T.FORWARD_4D = { x = 0.476736, z = 0.720442, y = -0.503672 }

T.DROID_MOBILE = "object/mobile/shared_ig_assassin_droid.iff"

-- FU-7: the 23 distinct ships
T.SHIPS = {
	"imp_lambda_shuttle_tier3", "imp_tie_advanced_tier3", "imp_tie_advanced_tier4", "imp_tie_aggressor_tier3", "imp_tie_bomber_tier3", "imp_tie_fighter_tier3",
	"imp_tie_interceptor_tier3", "lambdashuttle_advanced_recon", "lambdashuttle_rebel_tier3_1_a_spies", "lambdashuttle_rebel_tier3_1_officer", "nym_smuggler",
	"reb_bwing_tier3", "reb_gunboat_tier3", "reb_xwing_tier3", "rebel_smuggler_tier3", "smuggler_yt1300_tier2", "tatooine_rebel_3_3_b_smuggler_yt1300_tier3",
	"tatooine_tier3_2_b_guard", "tatooine_tier3_2_b_inquisitor", "tatooine_tier3_2_inspect_awing", "tatooine_tier3_2_inspect_bwing", "tatooine_tier3_2_inspect_xwing",
	"tatooine_tier3_2_inspect_ywing",
}

-- I-5, FU-3: the four suspect templates: SWG space_mobile row, the cargo they all carry (a canTransfer-1 row of inspect_cargo/tatooine_tier3_2_inspect)
T.SUSPECTS = {
	tatooine_tier3_2_inspect_awing = { smt = 1755 },
	tatooine_tier3_2_inspect_bwing = { smt = 1756 },
	tatooine_tier3_2_inspect_xwing = { smt = 1757 },
	tatooine_tier3_2_inspect_ywing = { smt = 1758 },
}
T.SUSPECT_ORDER = { "tatooine_tier3_2_inspect_awing", "tatooine_tier3_2_inspect_bwing", "tatooine_tier3_2_inspect_xwing", "tatooine_tier3_2_inspect_ywing" }
T.CARGO = "thermal_bomb"
T.CARGO_TABLE = "tatooine_tier3_2_inspect"

T.SPLIT_COMPLETION = 1
T.SPLIT_PATROL_POINT = 4

local function point(zone, name, extra)
	local p = T.POINTS[zone][name]

	assert(p ~= nil, "no spec point " .. tostring(name) .. " in " .. zone)

	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra or {}) do
		t[k] = v
	end

	return t
end

-- names with a numeric suffix: prefix .. from .. to
local function numbered(prefix, from, to)
	local out = {}

	for i = from, to do
		out[#out + 1] = prefix .. i
	end

	return out
end

local function pts(zone, names, extra, number)
	local out = {}

	for i, n in ipairs(names) do
		local e = {}

		for k, v in pairs(extra or {}) do
			e[k] = v
		end

		if number then
			e[number] = i
		end

		out[i] = point(zone, n, e)
	end

	return out
end

local function spawner(zone, name)
	local s = T.SPAWNERS[zone][name]

	return { spawnName = name, x = s[1], z = s[2], y = s[3] }
end

local function rep(value, count)
	local out = {}

	for i = 1, count do
		out[i] = value
	end

	return out
end

local function cat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

local function item(n) return { { species = { -1 }, item = T.ITEM_ROOT .. T.ITEMS[n] } } end

local function taunts4(n) return { goodbyeCount = n, reasonCount = n, tauntCount = n, thanksCount = n } end

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function T.expected()
	local P = "tatooine_rebel_tier3_"
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES
	local rndDelivery = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM
	local seqSurvival = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local END = { sideQuest = false, sideQuestType = "" }

	local function base(global, more)
		local ident = T.IDENTITY[global]
		local t = { className = global, questType = ident.type, questName = ident.name, questZone = ident.zone }

		for k, v in pairs(more) do
			t[k] = v
		end

		return t
	end

	local function child(parent, more)
		local pid = T.IDENTITY[parent]

		more.parentQuest, more.parentQuestType, more.parentQuestName = parent, pid.type, pid.name

		return more
	end

	local function split(nextGlobal, delay, splitType, extra)
		local nid = T.IDENTITY[nextGlobal]
		local t = { sideQuest = true, sideQuestType = nid.type, sideQuestName = nid.name, sideQuestSplitType = splitType or ST.COMPLETION, sideQuestDelay = delay }

		for k, v in pairs(extra or {}) do
			t[k] = v
		end

		return t
	end

	local function merge(...)
		local out = {}

		for _, t in ipairs({ ... }) do
			for k, v in pairs(t) do
				out[k] = v
			end
		end

		return out
	end

	local F, I, B, A = "imp_tie_fighter_tier3", "imp_tie_interceptor_tier3", "imp_tie_bomber_tier3", "imp_tie_advanced_tier3"
	local SPIES = "lambdashuttle_rebel_tier3_1_a_spies"
	local out = {}

	-- Mission 1: recovery > delivery (10 s) > survival > escort
	out[T.M1[1]] = base(T.M1[1], merge({ creditReward = T.CREDITS, itemReward = item(1) }, split(T.M1[2], 5), {
		arrivalDelay = 10, recoveryDelay = 30,
		recoverShip = "lambdashuttle_rebel_tier3_1_officer",
		recoveryConversationMobile = T.DROID_MOBILE,
		escortShips = { I, I },
		preRecoveryPoints = pts(DT, numbered(P .. "1_escort_", 1, 6), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(DT, numbered(P .. "1_recovery_", 1, 4), { radius = 250 }, "escortNumber"),
		attackDelay = 60,
		attackShips = { { F, F, F }, { F, F, I } },
		tauntData = { panicCount = 5, thanksCount = 5 },
	}))
	out[T.M1[2]] = base(T.M1[2], merge(child(T.M1[1], {}), split(T.M1[3], 10), {
		pickupPoint = point(DT, P .. "1_a_pickup"),
		deliveryPoint = point(DT, P .. "1_a_delivery"),
		pickupShip = SPIES, deliveryShip = "reb_gunboat_tier3",
		attackShipLists = { { I, I, I }, { F, F, F } },
		attackPeriod = 60, attackListType = rndDelivery,
	}))
	out[T.M1[3]] = base(T.M1[3], merge(child(T.M1[2], {}), split(T.M1[4], 5), {
		transmissionPoint = point(DT, P .. "1_b_survival"),
		totalTransmissionTime = 200, timesToUpdateProgress = 3, transmissionStartDelay = 5, delayToFirstAttack = 10,
		attackShipLists = { { F, F, F }, { I, I, I }, { B, I, I } },
		attackPeriod = 60, attackListType = seqSurvival,
	}))
	out[T.M1[4]] = base(T.M1[4], merge(child(T.M1[3], {}), END, {
		escortShips = { SPIES },
		escortPoints = pts(DT, numbered(P .. "1_c_escort_", 1, 4), { zoneName = DT, radius = 250 }, "escortNumber"),
		attackDelay = 45,
		attackShips = { { F, F, F }, { I, I, I }, { A, I, I } },
		tauntData = taunts4(5),
	}))

	-- Mission 2: inspect (8 s) > surprise attack (8 s) > assassinate (Dantooine) > space battle
	out[T.M2[1]] = base(T.M2[1], merge({ creditReward = T.CREDITS, itemReward = item(2) }, split(T.M2[2], 8), {
		shipList = { "tatooine_tier3_2_inspect_awing", "tatooine_tier3_2_inspect_bwing", "tatooine_tier3_2_inspect_xwing", "tatooine_tier3_2_inspect_ywing" },
		validSpawns = { spawner(DT, P .. "2_suspect_1"), spawner(DT, P .. "2_suspect_2") },
		giveSpawnWaypoint = 1, cargo = T.CARGO,
	}))
	out[T.M2[2]] = base(T.M2[2], merge(child(T.M2[1], {}), split(T.M2[3], 8), {
		surpriseAttackShips = { zone = DT, spawns = { { count = 3, shipName = I } } },
	}))
	out[T.M2[3]] = base(T.M2[3], merge(child(T.M2[2], {}), split(T.M2[4], 5), {
		arrivalDelay = 10, failTimer = 20, mustDestroyEscort = false,
		assassinateSpawns = { target = "tatooine_tier3_2_b_inquisitor", escorts = rep("tatooine_tier3_2_b_guard", 3) },
		targetPatrols = pts(DA, numbered("tatooine_tier3_2_b_escape_", 1, 6)),
	}))
	out[T.M2[4]] = base(T.M2[4], merge(child(T.M2[3], {}), END, {
		battlePoint = point(DA, P .. "2_c_battlepoint", { forward = T.FORWARD_2C }),
		damageMultiplier = 6, allyArrivalDelay = 60, enemyArrivalDelay = 75, allyOriginDist = 600, enemyOriginDist = -800, allyArrivalDist = 20, enemyArrivalDist = -200,
		allyForce = rep("reb_bwing_tier3", 3),
		enemyForce = { I, I, F, F, F, F },
	}))

	-- Mission 3: delivery (Lok to Dathomir, 8 s) > space battle > escort (8 s) > survival
	out[T.M3[1]] = base(T.M3[1], merge({ creditReward = T.CREDITS, itemReward = item(3) }, split(T.M3[2], 8), {
		deliveryZone = DT,
		pickupPoint = point(LK, P .. "3_pickup"),
		deliveryPoint = point(DT, P .. "3_delivery"),
		pickupShip = "nym_smuggler", deliveryShip = "smuggler_yt1300_tier2",
		attackShipLists = { { F, F, F }, { F, F, I }, { I, I, I } },
		attackPeriod = 110, attackListType = rndDelivery,
	}))
	out[T.M3[2]] = base(T.M3[2], merge(child(T.M3[1], {}), split(T.M3[3], 5), {
		battlePoint = point(DT, P .. "3_a_battlepoint", { forward = T.FORWARD_3A }),
		damageMultiplier = 6, allyArrivalDelay = 110, enemyArrivalDelay = 140, allyOriginDist = 800, enemyOriginDist = -750, allyArrivalDist = 100, enemyArrivalDist = -100,
		allyForce = rep("reb_xwing_tier3", 3),
		enemyForce = cat({ "lambdashuttle_advanced_recon", "imp_lambda_shuttle_tier3" }, rep(F, 6)),
	}))
	out[T.M3[3]] = base(T.M3[3], merge(child(T.M3[2], {}), split(T.M3[4], 8), {
		escortShips = { "tatooine_rebel_3_3_b_smuggler_yt1300_tier3" },
		escortPoints = pts(DT, numbered("tatooine_tier3_3_b_escort_", 1, 4), { zoneName = DT, radius = 250 }, "escortNumber"),
		attackDelay = 50,
		attackShips = { { F, F, F }, { B, F, F }, { I, I, I } },
		tauntData = taunts4(5),
	}))
	out[T.M3[4]] = base(T.M3[4], merge(child(T.M3[3], {}), END, {
		transmissionPoint = point(DT, "tatooine_tier3_3_b_escort_4"),
		totalTransmissionTime = 200, timesToUpdateProgress = 4, transmissionStartDelay = 5, delayToFirstAttack = 10,
		attackShipLists = { { F, F, F }, { I, F, F }, { B, F, F } },
		attackPeriod = 60, attackListType = seqSurvival,
	}))

	-- Mission 4: assassinate > patrol (PATROL_POINT 3 / 4 s) > surprise attack (8 s) > delivery_no_pickup (8 s) > space battle
	out[T.M4[1]] = base(T.M4[1], merge({ creditReward = T.CREDITS, itemReward = item(4) }, split(T.M4[2], 5), {
		arrivalDelay = 10, failTimer = 20, mustDestroyEscort = false,
		assassinateSpawns = { target = "imp_tie_advanced_tier4", escorts = { F, F, F, F, I, I } },
		targetPatrols = pts(EN, numbered(P .. "4_escort_", 1, 6)),
	}))
	out[T.M4[2]] = base(T.M4[2], merge(child(T.M4[1], {}), split(T.M4[3], 4, ST.PATROL_POINT, { sideQuestPatrolStart = 3 }), {
		patrolPoints = pts(EN, numbered(P .. "4_a_patrol_", 1, 4), { radius = 150 }, "patrolNumber"),
	}))
	out[T.M4[3]] = base(T.M4[3], merge(child(T.M4[2], {}), split(T.M4[4], 8), {
		surpriseAttackShips = { zone = EN, spawns = { { count = 3, shipName = A } } },
	}))
	out[T.M4[4]] = base(T.M4[4], merge(child(T.M4[3], {}), split(T.M4[5], 8), {
		deliveryShip = "rebel_smuggler_tier3",
		deliveryPoint = point(EN, P .. "4_c_delivery"),
		attackShipLists = { { F, F, F }, { I, F, F } },
		attackPeriod = 90, attackListType = rndDelivery,
	}))
	out[T.M4[5]] = base(T.M4[5], merge(child(T.M4[4], {}), END, {
		battlePoint = point(EN, P .. "4_d_battlepoint", { forward = T.FORWARD_4D }),
		damageMultiplier = 6, allyArrivalDelay = 45, enemyArrivalDelay = 65, allyOriginDist = 600, enemyOriginDist = -650, allyArrivalDist = 150, enemyArrivalDist = -150,
		allyForce = rep("reb_xwing_tier3", 5),
		enemyForce = cat({ "imp_tie_aggressor_tier3" }, rep(F, 6)),
	}))

	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

T.loadErrors = C.loadErrors

-- The server's load: every squadron file (crimson_tier1_data.lua's load); a missing production file is recorded, not raised
function T.load() C.load() end

function T.problems() return table.concat(C.loadErrors, " | ") end

function T.quest(global)
	C.load()

	return H.expectGlobal(global, "Crimson Phoenix tier 3 quest table (crimson-phoenix-tier3-ulvawop-missions). Load problems: " .. T.problems())
end

function T.squadron()
	C.load()

	return H.expectGlobal("CrimsonPhoenixSquadronScreenplay", "squadron screenplay object. Load problems: " .. T.problems())
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

function T.crc(global)
	local ident = T.IDENTITY[global]

	return H.questCrc(ident.type, ident.name)
end

-- Quest state helper on a built pilot. state: "complete" | "active" | "none"
function T.setState(player, global, state)
	local key = T.crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function T.state(player, global)
	local key = T.crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- A Crimson Phoenix pilot who finished tier 2 (the four tier 1 and four tier 2 skills, EKER_PILOT_KEY "3", Eker's four missions paid, his fourth reward
-- yavin_rebel_16:reward set, pilot tier 3). Options:
--   missions   k: Ulvaw'op's missions 1..k won (every chain member complete), :attempted and :reward set (default 0)
--   t3         number of tier 3 skills held (default 0; the _03 skills in the tier 1 training order)
--   active     global of a tier 3 member left active in the journal
--   state      the state of mission missions+1: "won" | "failed" | "active" | "attempted" (as crimson_tier2_data.lua's E.pilot)
--   pilotTier  ghost pilot tier (default 3, or 4 with four tier 3 skills)
--   graduated  EKER_PILOT_KEY value (default "3"; false leaves it unset)
--   every other option is crimson_tier2_data.lua's E.pilot (t1, inShip, zone, standing, inventory, ...)
function T.pilot(o)
	o = o or {}
	C.load()

	local base = {}

	for k, v in pairs(o) do
		base[k] = v
	end

	base.missions, base.t3, base.active, base.state = nil, nil, nil, nil
	base.t2 = o.t2 or 4
	base.t3 = o.t3
	base.graduated = o.graduated == nil and "3" or o.graduated
	base.pilotTier = o.pilotTier or ((o.t3 or 0) >= 4 and 4 or 3)
	base.missions = 4 -- Eker's missions paid (E.STATUS, yavin_rebel_16:reward)

	local player = E.pilot(base)

	for n = 1, o.missions or 0 do
		for _, global in ipairs(T.CHAINS[n]) do
			T.setState(player, global, "complete")
		end

		H.setQuestStatus(player, T.STATUS[n] .. ":attempted", "1")
		H.setQuestStatus(player, T.STATUS[n] .. ":reward", "1")
	end

	local n = (o.missions or 0) + 1

	if o.state ~= nil and T.CHAINS[n] ~= nil then
		H.setQuestStatus(player, T.STATUS[n] .. ":attempted", "1")

		if o.state == "won" then
			for _, global in ipairs(T.CHAINS[n]) do
				T.setState(player, global, "complete")
			end
		elseif o.state == "active" then
			T.setState(player, T.CHAINS[n][1], "active")
		end
	end

	if o.active then
		T.setState(player, o.active, "active")
	end

	return player
end

-- A Rebel pilot in a Rebel-faction ship in `zone` (default space_dathomir), the way the runtime tests start a quest
function T.flyer(zone)
	C.load()

	return H.newPlayer({
		zone = zone or DT,
		pilot = "rebel",
		ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") },
	})
end

return T
