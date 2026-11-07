-- Shared test data and builders for Vortex Squadron tier 3, Part A (Brother Ezkiel's missions), not a test file.
-- Spec: .claude/work/vortex-tier3-ezkiel-missions/01-spec.md (Content contract, Data mapping, Appendix B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of agreeing with itself
-- (test_vortex_tier3_missions_data.lua proves the literals equal the SWG .tab fixtures):
--   W.GLOBALS / W.IDENTITY     the 20 quest globals and their class, type, name and zone (Content contract 1)
--   W.M1 .. W.M4 / W.CHAINS    the four chains, members in chain order (= letter order)
--   W.QUEST_STRINGS            the 20 TIER3_* constants of VortexSquadronScreenplay (Content contract 2)
--   W.statusKeys()             the 8 ":attempted" / ":reward" keys
--   W.POINTS / W.SPAWNERS      Data mapping 2: the 48 nav points and the 2 inspect spawners, per zone, Core3 x, z, y
--   W.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   W.load() / W.quest / W.squadron   the server's load (vortex_tier2_data.lua's); a missing production file is recorded, not raised
--   W.pilot{...}               a Vortex pilot who finished tier 2, with optional tier 3 state (see the option list at W.pilot)
--   W.flyer(zone)              a Rebel pilot in a Rebel ship in `zone`, for the runtime tests
-- Part B (vortex-tier3-ezkiel, Brother Ezkiel's conversation) extends this file below "Part B".

local H = require("harness")
local V1 = require("vortex_tier1_data")
local V2 = require("vortex_tier2_data")

local W = {}

W.SQUADRON_FILE = V1.SQUADRON_FILE
W.SHIP_DIR = "ship_mobile/ships/"

local DA, EN, DT = "space_dantooine", "space_endor", "space_dathomir"

W.M1 = {
	"assassinate_naboo_rebel_tier3_1", "escort_naboo_rebel_tier3_1_a", "survival_naboo_rebel_tier3_1_b", "inspect_naboo_rebel_tier3_1_c",
	"delivery_no_pickup_naboo_rebel_tier3_1_d",
}
W.M2 = {
	"space_battle_naboo_rebel_tier3_2", "rescue_naboo_rebel_tier3_2_a", "patrol_naboo_rebel_tier3_2_b", "destroy_surpriseattack_naboo_rebel_tier3_2_c",
	"inspect_naboo_rebel_tier3_2_d",
}
W.M3 = {
	"patrol_naboo_rebel_tier3_3", "destroy_surpriseattack_naboo_rebel_tier3_3_a", "survival_naboo_rebel_tier3_3_b", "patrol_naboo_rebel_tier3_3_c",
	"assassinate_naboo_rebel_tier3_3_d",
}
W.M4 = {
	"space_battle_naboo_rebel_tier3_4", "patrol_naboo_rebel_tier3_4_a", "survival_naboo_rebel_tier3_4_b", "recovery_naboo_rebel_tier3_4_c",
	"delivery_naboo_rebel_tier3_4_d",
}

W.CHAINS = { W.M1, W.M2, W.M3, W.M4 }

W.GLOBALS = {}

for _, chain in ipairs(W.CHAINS) do
	for _, g in ipairs(chain) do
		W.GLOBALS[#W.GLOBALS + 1] = g
	end
end

W.HEADS = { W.M1[1], W.M2[1], W.M3[1], W.M4[1] }
W.ENDS = { W.M1[5], W.M2[5], W.M3[5], W.M4[5] }

-- the tier 1-2 globals, which the 20 follow in the registration order
W.EARLIER_GLOBALS = {}

for _, g in ipairs(V2.TIER1_GLOBALS) do
	W.EARLIER_GLOBALS[#W.EARLIER_GLOBALS + 1] = g
end

for _, g in ipairs(V2.GLOBALS) do
	W.EARLIER_GLOBALS[#W.EARLIER_GLOBALS + 1] = g
end

-- Content contract 1
W.IDENTITY = {}

local function id(global, class, type_, name, zone) W.IDENTITY[global] = { class = class, type = type_, name = name, zone = zone } end

id(W.M1[1], "SpaceAssassinateScreenplay", "assassinate", "naboo_rebel_tier3_1", DA)
id(W.M1[2], "SpaceEscortScreenplay", "escort", "naboo_rebel_tier3_1_a", DA)
id(W.M1[3], "SpaceSurvivalScreenplay", "survival", "naboo_rebel_tier3_1_b", DA)
id(W.M1[4], "SpaceInspectScreenplay", "inspect", "naboo_rebel_tier3_1_c", DA)
id(W.M1[5], "SpaceDeliveryNoPickupScreenplay", "delivery_no_pickup", "naboo_rebel_tier3_1_d", DA)
id(W.M2[1], "SpaceBattleScreenplay", "space_battle", "naboo_rebel_tier3_2", DA)
id(W.M2[2], "SpaceRescueScreenplay", "rescue", "naboo_rebel_tier3_2_a", DA)
id(W.M2[3], "SpacePatrolScreenplay", "patrol", "naboo_rebel_tier3_2_b", DA)
id(W.M2[4], "SpaceSurpriseAttackScreenplay", "destroy_surpriseattack", "naboo_rebel_tier3_2_c", DA)
id(W.M2[5], "SpaceInspectScreenplay", "inspect", "naboo_rebel_tier3_2_d", DA)
id(W.M3[1], "SpacePatrolScreenplay", "patrol", "naboo_rebel_tier3_3", EN)
id(W.M3[2], "SpaceSurpriseAttackScreenplay", "destroy_surpriseattack", "naboo_rebel_tier3_3_a", EN)
id(W.M3[3], "SpaceSurvivalScreenplay", "survival", "naboo_rebel_tier3_3_b", EN)
id(W.M3[4], "SpacePatrolScreenplay", "patrol", "naboo_rebel_tier3_3_c", EN)
id(W.M3[5], "SpaceAssassinateScreenplay", "assassinate", "naboo_rebel_tier3_3_d", EN)
id(W.M4[1], "SpaceBattleScreenplay", "space_battle", "naboo_rebel_tier3_4", DT)
id(W.M4[2], "SpacePatrolScreenplay", "patrol", "naboo_rebel_tier3_4_a", DT)
id(W.M4[3], "SpaceSurvivalScreenplay", "survival", "naboo_rebel_tier3_4_b", DT)
id(W.M4[4], "SpaceRecoveryScreenplay", "recovery", "naboo_rebel_tier3_4_c", DT)
id(W.M4[5], "SpaceDeliveryScreenplay", "delivery", "naboo_rebel_tier3_4_d", DT)

-- Content contract 2
W.QUEST_STRINGS = {
	TIER3_QUEST_STRING_1 = { type = "assassinate", name = "naboo_rebel_tier3_1" },
	TIER3_QUEST_STRING_1_SIDE1 = { type = "escort", name = "naboo_rebel_tier3_1_a" },
	TIER3_QUEST_STRING_1_SIDE2 = { type = "survival", name = "naboo_rebel_tier3_1_b" },
	TIER3_QUEST_STRING_1_SIDE3 = { type = "inspect", name = "naboo_rebel_tier3_1_c" },
	TIER3_QUEST_STRING_1_SIDE4 = { type = "delivery_no_pickup", name = "naboo_rebel_tier3_1_d" },
	TIER3_QUEST_STRING_2 = { type = "space_battle", name = "naboo_rebel_tier3_2" },
	TIER3_QUEST_STRING_2_SIDE1 = { type = "rescue", name = "naboo_rebel_tier3_2_a" },
	TIER3_QUEST_STRING_2_SIDE2 = { type = "patrol", name = "naboo_rebel_tier3_2_b" },
	TIER3_QUEST_STRING_2_SIDE3 = { type = "destroy_surpriseattack", name = "naboo_rebel_tier3_2_c" },
	TIER3_QUEST_STRING_2_SIDE4 = { type = "inspect", name = "naboo_rebel_tier3_2_d" },
	TIER3_QUEST_STRING_3 = { type = "patrol", name = "naboo_rebel_tier3_3" },
	TIER3_QUEST_STRING_3_SIDE1 = { type = "destroy_surpriseattack", name = "naboo_rebel_tier3_3_a" },
	TIER3_QUEST_STRING_3_SIDE2 = { type = "survival", name = "naboo_rebel_tier3_3_b" },
	TIER3_QUEST_STRING_3_SIDE3 = { type = "patrol", name = "naboo_rebel_tier3_3_c" },
	TIER3_QUEST_STRING_3_SIDE4 = { type = "assassinate", name = "naboo_rebel_tier3_3_d" },
	TIER3_QUEST_STRING_4 = { type = "space_battle", name = "naboo_rebel_tier3_4" },
	TIER3_QUEST_STRING_4_SIDE1 = { type = "patrol", name = "naboo_rebel_tier3_4_a" },
	TIER3_QUEST_STRING_4_SIDE2 = { type = "survival", name = "naboo_rebel_tier3_4_b" },
	TIER3_QUEST_STRING_4_SIDE3 = { type = "recovery", name = "naboo_rebel_tier3_4_c" },
	TIER3_QUEST_STRING_4_SIDE4 = { type = "delivery", name = "naboo_rebel_tier3_4_d" },
}

-- the constants in contract order (chain order)
W.QUEST_STRING_FIELDS = {
	"TIER3_QUEST_STRING_1", "TIER3_QUEST_STRING_1_SIDE1", "TIER3_QUEST_STRING_1_SIDE2", "TIER3_QUEST_STRING_1_SIDE3", "TIER3_QUEST_STRING_1_SIDE4",
	"TIER3_QUEST_STRING_2", "TIER3_QUEST_STRING_2_SIDE1", "TIER3_QUEST_STRING_2_SIDE2", "TIER3_QUEST_STRING_2_SIDE3", "TIER3_QUEST_STRING_2_SIDE4",
	"TIER3_QUEST_STRING_3", "TIER3_QUEST_STRING_3_SIDE1", "TIER3_QUEST_STRING_3_SIDE2", "TIER3_QUEST_STRING_3_SIDE3", "TIER3_QUEST_STRING_3_SIDE4",
	"TIER3_QUEST_STRING_4", "TIER3_QUEST_STRING_4_SIDE1", "TIER3_QUEST_STRING_4_SIDE2", "TIER3_QUEST_STRING_4_SIDE3", "TIER3_QUEST_STRING_4_SIDE4",
}

-- Status keys (set by Part B's handler): <name>:attempted and <name>:reward for the four mission heads
W.STATUS = { "naboo_rebel_tier3_1", "naboo_rebel_tier3_2", "naboo_rebel_tier3_3", "naboo_rebel_tier3_4" }

function W.statusKeys()
	local out = {}

	for _, name in ipairs(W.STATUS) do
		out[#out + 1] = name .. ":attempted"
		out[#out + 1] = name .. ":reward"
	end

	return out
end

W.VORTEX_PILOT_KEY = V1.VORTEX_PILOT_KEY

-- Data mapping 2: zone -> name -> { x, z, y } (Core3 x, z, y = buildout PX, PY, PZ truncated toward zero)
W.POINTS = {
	space_dantooine = {
		corellia_imperial_tier4_recovery1_2 = { 1014, -431, 1398 },
		corellia_imperial_tier4_recovery1_4 = { 6538, -1692, -3169 },
		corellia_imperial_tier4_recovery1_6 = { 6312, -1058, -6910 },
		corellia_imperial_tier4_rescueduty_2 = { 294, 509, 3594 },
		naboo_rebel_tier3_point_1 = { 4957, 3250, 4698 },
		naboo_rebel_tier3_point_2 = { 2568, 3857, 2000 },
		naboo_rebel_tier3_point_3 = { -15, 4452, -618 },
		naboo_rebel_tier3_point_4 = { -2585, 5075, -3250 },
		naboo_rebel_tier3_survival_point = { -2327, 5908, -2768 },
		naboo_rebel_tier3_delivery_point_1 = { -2431, 7301, -707 },
		naboo_rebel_tier3_battle_point = { -179, -1167, 4938 },
		naboo_rebel_tier3_rescue_1 = { -2257, -3938, -1441 },
		naboo_rebel_tier3_rescue_2 = { -1722, -2498, 1940 },
		naboo_rebel_tier3_rescue_3 = { -996, -2105, 4791 },
		naboo_rebel_tier3_rescue_4 = { 378, -1904, 6544 },
		naboo_rebel_tier3_patrol_1 = { 367, -1902, 6515 },
		naboo_rebel_tier3_patrol_2 = { 21, -5166, 3573 },
		naboo_rebel_tier3_patrol_3 = { -20, -6038, 2818 },
		naboo_rebel_tier3_patrol_4 = { -73, -6814, 1855 },
	},
	space_endor = {
		naboo_rebel_tier3_patrol3_1 = { 2432, -1174, 175 },
		naboo_rebel_tier3_patrol3_2 = { 4402, -2116, 329 },
		naboo_rebel_tier3_patrol3_3 = { 5662, -2940, 656 },
		naboo_rebel_tier3_patrol3_4 = { 6031, -3567, 1431 },
		naboo_rebel_tier3_blacklight_point = { 6712, -4486, 437 },
		naboo_rebel_tier3_leader_patrol_1 = { 6497, -3437, 562 },
		naboo_rebel_tier3_leader_patrol_2 = { 6580, -3261, 1630 },
		naboo_rebel_tier3_leader_patrol_3 = { 5505, -3025, 2988 },
		naboo_rebel_tier3_leader_patrol_4 = { 4966, -2686, 4562 },
		naboo_rebel_tier3_assassin_path_1 = { 1437, -2473, 7305 },
		naboo_rebel_tier3_assassin_path_2 = { 3964, -2520, 5227 },
		naboo_rebel_tier3_assassin_path_3 = { 5643, -2616, 3102 },
		naboo_rebel_tier3_assassin_path_4 = { 6447, -2505, 1042 },
	},
	space_dathomir = {
		naboo_rebel_tier3_rebel_vs_imperial = { 5627, -441, -4388 },
		naboo_rebel_tier3_4_patrol_1 = { 5786, -477, -4415 },
		naboo_rebel_tier3_4_patrol_2 = { 4008, -2803, -5284 },
		naboo_rebel_tier3_4_patrol_3 = { 2254, -4146, -6242 },
		naboo_rebel_tier3_4_patrol_4 = { 397, -5568, -7256 },
		naboo_rebel_tier3_inquisition_point = { 609, -5349, -7366 },
		naboo_rebel_tier3_recover_imperial_1 = { 4749, 109, -464 },
		naboo_rebel_tier3_recover_imperial_2 = { 5198, -16, -1992 },
		naboo_rebel_tier3_recover_imperial_3 = { 5514, -172, -3083 },
		naboo_rebel_tier3_recover_imperial_4 = { 6221, -447, -4806 },
		naboo_rebel_tier3_recover_imperial_5 = { 4807, -1349, -3781 },
		naboo_rebel_tier3_recover_imperial_6 = { 2150, -3082, -1761 },
		naboo_rebel_tier3_recover_imperial_7 = { 111, -4412, -211 },
		naboo_rebel_tier3_recover_imperial_8 = { -2691, -6240, 1919 },
		naboo_rebel_tier3_pickup = { -2596, -2751, 1595 },
		naboo_rebel_tier3_delivery = { -2671, -6097, 1923 },
	},
}

W.SPAWNERS = {
	space_dantooine = {
		naboo_rebel_tier3_inspect_target = { -3838, 5840, -3806 },
		naboo_rebel_tier3_pirate_leader_inspect = { -711, -5678, 1064 },
	},
}

W.ITEM_ROOT = "object/tangible/ship/components/"
W.CREDITS = 25000

-- Source inventory 1 (J3:232-263): one item per head
W.ITEMS = {
	"armor/arm_mission_reward_rebel_corellian_triplate.iff",
	"weapon_capacitor/cap_mission_reward_rebel_qualdex_battery_array.iff",
	"engine/eng_mission_reward_rebel_incom_military.iff",
	"reactor/rct_mission_reward_rebel_slayn_hypervortex.iff",
}

-- Data mapping 1: battle forwards (excerpt fltKX, fltKY, fltKZ -> x, z, y)
W.FORWARD2 = { x = 0.335610, z = -0.349005, y = 0.874964 }
W.FORWARD4 = { x = 0.786536, z = -0.011715, y = -0.617434 }

W.DROID_MOBILE = "object/mobile/shared_ig_assassin_droid.iff"

-- FV-6: the 22 distinct ships
W.SHIPS = {
	"blacklight_assassin_tier3", "blacklight_bomber_tier3", "blacklight_fighter_tier3", "blacklight_leader_tier3", "blacklight_pirate_fighter_quest",
	"blacklight_pirate_leader", "freighterheavy_rebel_tier3", "imp_tie_advanced_tier3", "imp_tie_bomber_tier3", "imp_tie_experimental_fighter_tier3",
	"imp_tie_fighter_tier3", "imp_tie_interceptor_tier3", "naboo_tier3_imperial_spy", "reb_freighterheavy_tier3", "reb_gunboat_tier3", "reb_xwing_tier3",
	"spynet_assassin_tier3", "spynet_bomber_tier3", "spynet_fighter_tier3", "spynet_special_ops_tier3", "tieadvanced_inquisitor_tier3",
	"tieinterceptor_inquisitor_tier3",
}

-- I-5: the two inspect targets: the SWG space_mobile row, the SWG cargo (inspect_cargo table) the template carries, the quest that names the ship
W.CARGO_SHIPS = {
	naboo_tier3_imperial_spy = { smt = 1146, cargo = "experiment_information", quest = W.M1[4] },
	blacklight_pirate_fighter_quest = { smt = 98, cargo = "leader_location", quest = W.M2[5] },
}

W.SPLIT_COMPLETION = 1
W.SPLIT_PATROL_POINT = 4

local function point(zone, name, extra)
	local p = W.POINTS[zone][name]

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
	local s = W.SPAWNERS[zone][name]

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

local function item(n) return { { species = { -1 }, item = W.ITEM_ROOT .. W.ITEMS[n] } } end

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function W.expected()
	local P = "naboo_rebel_tier3_"
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES
	local seqDelivery = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local seqSurvival = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local seqRescue = SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local END = { sideQuest = false, sideQuestType = "" }

	local function base(global, more)
		local ident = W.IDENTITY[global]
		local t = { className = global, questType = ident.type, questName = ident.name, questZone = ident.zone }

		for k, v in pairs(more) do
			t[k] = v
		end

		return t
	end

	local function child(parent, more)
		local pid = W.IDENTITY[parent]

		more.parentQuest, more.parentQuestType, more.parentQuestName = parent, pid.type, pid.name

		return more
	end

	local function split(nextGlobal, delay, splitType, extra)
		local nid = W.IDENTITY[nextGlobal]
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

	local ADV, FT, BMB, INT, INQ = "imp_tie_advanced_tier3", "imp_tie_fighter_tier3", "imp_tie_bomber_tier3", "imp_tie_interceptor_tier3", "tieinterceptor_inquisitor_tier3"
	local BA, BF, BB, BL = "blacklight_assassin_tier3", "blacklight_fighter_tier3", "blacklight_bomber_tier3", "blacklight_leader_tier3"
	local out = {}

	-- Mission 1: assassinate > escort (15 s) > survival > inspect (15 s) > delivery_no_pickup
	out[W.M1[1]] = base(W.M1[1], merge({ creditReward = W.CREDITS, itemReward = item(1) }, split(W.M1[2], 5), {
		arrivalDelay = 10, failTimer = 20, mustDestroyEscort = false,
		assassinateSpawns = { target = "tieadvanced_inquisitor_tier3", escorts = { INT, INT } },
		targetPatrols = pts(DA, { "corellia_imperial_tier4_recovery1_2", "corellia_imperial_tier4_recovery1_4", "corellia_imperial_tier4_recovery1_6", "corellia_imperial_tier4_rescueduty_2" }),
	}))
	out[W.M1[2]] = base(W.M1[2], merge(child(W.M1[1], {}), split(W.M1[3], 15), {
		escortShips = { "naboo_tier3_imperial_spy" },
		escortPoints = pts(DA, numbered(P .. "point_", 1, 4), { zoneName = DA, radius = 250 }, "escortNumber"),
		attackDelay = 80,
		attackShips = { { ADV, FT, FT }, { BMB, FT, FT }, { INT, FT, FT } },
		tauntData = { goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2 },
	}))
	out[W.M1[3]] = base(W.M1[3], merge(child(W.M1[2], {}), split(W.M1[4], 5), {
		transmissionPoint = point(DA, P .. "survival_point"),
		totalTransmissionTime = 360, timesToUpdateProgress = 4, transmissionStartDelay = 10, delayToFirstAttack = 10,
		attackShipLists = { { INT, FT, FT }, { FT, FT, FT }, { INQ, INT, INT }, { BMB, BMB, BMB } },
		attackPeriod = 80, attackListType = seqSurvival,
	}))
	out[W.M1[4]] = base(W.M1[4], merge(child(W.M1[3], {}), split(W.M1[5], 15), {
		shipList = { "naboo_tier3_imperial_spy" },
		validSpawns = { spawner(DA, P .. "inspect_target") },
		giveSpawnWaypoint = 1, cargo = "experiment_information",
	}))
	out[W.M1[5]] = base(W.M1[5], merge(child(W.M1[4], {}), END, {
		deliveryShip = "freighterheavy_rebel_tier3",
		deliveryPoint = point(DA, P .. "delivery_point_1"),
		attackShipLists = { { BMB, FT, FT, FT }, { INQ, INT, INT } },
		attackPeriod = 80, attackListType = seqDelivery,
	}))

	-- Mission 2: space battle > rescue > patrol (PATROL_POINT 3 / 10 s) > surprise attack (12 s) > inspect
	out[W.M2[1]] = base(W.M2[1], merge({ creditReward = W.CREDITS, itemReward = item(2) }, split(W.M2[2], 5), {
		battlePoint = point(DA, P .. "battle_point", { forward = W.FORWARD2 }),
		damageMultiplier = 6, allyArrivalDelay = 80, enemyArrivalDelay = 110, allyOriginDist = 700, enemyOriginDist = -700, allyArrivalDist = 200, enemyArrivalDist = -100,
		allyForce = { "spynet_assassin_tier3", "spynet_special_ops_tier3", "spynet_special_ops_tier3", "spynet_bomber_tier3" },
		enemyForce = cat({ BA }, rep(BF, 3), rep(BB, 3)),
	}))
	out[W.M2[2]] = base(W.M2[2], merge(child(W.M2[1], {}), split(W.M2[3], 5), {
		recoveryPath = pts(DA, numbered(P .. "rescue_", 1, 4)),
		targetShipType = "spynet_fighter_tier3", targetArrivalDelay = 0,
		attackShipLists = { rep(BA, 3), { BB, BF, BF } },
		attackPeriod = 80, attackListType = seqRescue, numResponses = 3,
	}))
	out[W.M2[3]] = base(W.M2[3], merge(child(W.M2[2], {}), split(W.M2[4], 10, ST.PATROL_POINT, { sideQuestPatrolStart = 3 }), {
		patrolPoints = pts(DA, numbered(P .. "patrol_", 1, 4), { radius = 150 }, "patrolNumber"),
	}))
	out[W.M2[4]] = base(W.M2[4], merge(child(W.M2[3], {}), split(W.M2[5], 12), {
		surpriseAttackShips = { zone = DA, spawns = { { count = 4, shipName = BF } } },
	}))
	out[W.M2[5]] = base(W.M2[5], merge(child(W.M2[4], {}), END, {
		shipList = { "blacklight_pirate_fighter_quest" },
		validSpawns = { spawner(DA, P .. "pirate_leader_inspect") },
		giveSpawnWaypoint = 1, cargo = "leader_location",
	}))

	-- Mission 3: patrol (PATROL_POINT 3 / 8 s) > surprise attack > survival > patrol (PATROL_POINT 2 / 10 s) > assassinate
	out[W.M3[1]] = base(W.M3[1], merge({ creditReward = W.CREDITS, itemReward = item(3) }, split(W.M3[2], 8, ST.PATROL_POINT, { sideQuestPatrolStart = 3 }), {
		patrolPoints = pts(EN, numbered(P .. "patrol3_", 1, 4), { radius = 150 }, "patrolNumber"),
	}))
	out[W.M3[2]] = base(W.M3[2], merge(child(W.M3[1], {}), split(W.M3[3], 5), {
		surpriseAttackShips = { zone = EN, spawns = { { count = 4, shipName = BA } } },
	}))
	out[W.M3[3]] = base(W.M3[3], merge(child(W.M3[2], {}), split(W.M3[4], 5), {
		transmissionPoint = point(EN, P .. "blacklight_point"),
		totalTransmissionTime = 600, timesToUpdateProgress = 6, transmissionStartDelay = 10, delayToFirstAttack = 10,
		attackShipLists = { { BA, BF, BF }, { BF, BF, BF }, { BB, BF, BF }, { BL, BF, BF } },
		attackPeriod = 90, attackListType = seqSurvival,
	}))
	out[W.M3[4]] = base(W.M3[4], merge(child(W.M3[3], {}), split(W.M3[5], 10, ST.PATROL_POINT, { sideQuestPatrolStart = 2 }), {
		patrolPoints = pts(EN, numbered(P .. "leader_patrol_", 1, 4), { radius = 150 }, "patrolNumber"),
	}))
	out[W.M3[5]] = base(W.M3[5], merge(child(W.M3[4], {}), END, {
		arrivalDelay = 10, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = "blacklight_pirate_leader", escorts = { BA, BF, BF, BB, BF } },
		targetPatrols = pts(EN, numbered(P .. "assassin_path_", 1, 4)),
	}))

	-- Mission 4: space battle > patrol (PATROL_POINT 3 / 9 s) > survival > recovery > delivery
	out[W.M4[1]] = base(W.M4[1], merge({ creditReward = W.CREDITS, itemReward = item(4) }, split(W.M4[2], 5), {
		battlePoint = point(DT, P .. "rebel_vs_imperial", { forward = W.FORWARD4 }),
		damageMultiplier = 6, allyArrivalDelay = 60, enemyArrivalDelay = 30, allyOriginDist = 600, enemyOriginDist = -800, allyArrivalDist = 100, enemyArrivalDist = -100,
		allyForce = rep("reb_xwing_tier3", 4),
		enemyForce = cat(rep(BMB, 3), rep(FT, 2), { INQ, FT }),
	}))
	out[W.M4[2]] = base(W.M4[2], merge(child(W.M4[1], {}), split(W.M4[3], 9, ST.PATROL_POINT, { sideQuestPatrolStart = 3 }), {
		patrolPoints = pts(DT, numbered(P .. "4_patrol_", 1, 4), { radius = 150 }, "patrolNumber"),
	}))
	out[W.M4[3]] = base(W.M4[3], merge(child(W.M4[2], {}), split(W.M4[4], 5), {
		transmissionPoint = point(DT, P .. "inquisition_point"),
		totalTransmissionTime = 240, timesToUpdateProgress = 3, transmissionStartDelay = 60, delayToFirstAttack = 30,
		attackShipLists = { { FT, FT, FT }, { INQ, INT, INT }, { INT, INT, ADV } },
		attackPeriod = 80, attackListType = seqSurvival,
	}))
	out[W.M4[4]] = base(W.M4[4], merge(child(W.M4[3], {}), split(W.M4[5], 5), {
		arrivalDelay = 15, recoveryDelay = 30,
		recoverShip = "imp_tie_experimental_fighter_tier3",
		recoveryConversationMobile = W.DROID_MOBILE,
		escortShips = { INT, INT, INT },
		preRecoveryPoints = pts(DT, numbered(P .. "recover_imperial_", 1, 4), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(DT, numbered(P .. "recover_imperial_", 5, 8), { radius = 250 }, "escortNumber"),
		attackDelay = 70,
		attackShips = { { INT, INT, INT }, { ADV, FT, FT } },
		tauntData = { panicCount = 2, thanksCount = 2 },
	}))
	out[W.M4[5]] = base(W.M4[5], merge(child(W.M4[4], {}), END, {
		pickupPoint = point(DT, P .. "pickup"),
		deliveryPoint = point(DT, P .. "delivery"),
		pickupShip = "reb_freighterheavy_tier3", deliveryShip = "reb_gunboat_tier3",
		attackShipLists = { { BMB, INT, INT }, { ADV, INT, INT } },
		attackPeriod = 60, attackListType = seqDelivery,
	}))

	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

W.loadErrors = V1.loadErrors

-- The server's load: every squadron file (vortex_tier1_data.lua's load); a missing production file is recorded, not raised
function W.load() V1.load() end

function W.problems() return table.concat(V1.loadErrors, " | ") end

function W.quest(global)
	V1.load()

	return H.expectGlobal(global, "Vortex tier 3 quest table (vortex-tier3-ezkiel-missions). Load problems: " .. W.problems())
end

function W.squadron()
	V1.load()

	return H.expectGlobal("VortexSquadronScreenplay", "squadron screenplay object. Load problems: " .. W.problems())
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

function W.crc(global)
	local ident = W.IDENTITY[global]

	return H.questCrc(ident.type, ident.name)
end

-- Quest state helper on a built pilot. state: "complete" | "active" | "none"
function W.setState(player, global, state)
	local key = W.crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function W.state(player, global)
	local key = W.crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- The tier 3 skills (the four tier 1 skills with the _03 suffix), in the tier 1 training order
function W.tier3Skills(count)
	local out = {}

	for i = 1, count do
		out[i] = (V1.TRAIN[i].skill:gsub("_01$", "_03"))
	end

	return out
end

-- A Vortex pilot who finished tier 2 (the four tier 1 skills, the four tier 2 skills, VORTEX_PILOT_KEY "3", Vrovel's four missions paid, pilot tier 3).
-- Options:
--   missions   k: Ezkiel's missions 1..k won (every chain member complete), :attempted and :reward set (default 0)
--   t3         number of tier 3 skills held (default 0)
--   active     global of a tier 3 member left active in the journal
--   state      the state of mission missions+1: "won" | "failed" | "active" | "attempted" (as vortex_tier2_data.lua's V.pilot)
--   pilotTier  ghost pilot tier (default 3, or 4 with four tier 3 skills)
--   graduated  VORTEX_PILOT_KEY value (default "3"; false leaves it unset)
--   every other option is vortex_tier2_data.lua's V.pilot (t2, v1, t1, inShip, zone, standing, inventory, ...)
function W.pilot(o)
	o = o or {}
	V1.load()

	local base = {}

	for k, v in pairs(o) do
		base[k] = v
	end

	base.missions, base.t3, base.active, base.state = nil, nil, nil, nil
	base.t2 = o.t2 or 4
	base.graduated = o.graduated == nil and "3" or o.graduated
	base.pilotTier = o.pilotTier or ((o.t3 or 0) >= 4 and 4 or 3)
	base.skills = {}

	for _, skill in ipairs(o.skills or {}) do
		base.skills[#base.skills + 1] = skill
	end

	for _, skill in ipairs(W.tier3Skills(o.t3 or 0)) do
		base.skills[#base.skills + 1] = skill
	end

	-- Vrovel's four missions paid (his :reward for mission 4 is the hand-off's third condition), unless the caller overrides
	base.missions = o.vrovelMissions == nil and 4 or o.vrovelMissions
	base.vrovelMissions = nil

	local player = V2.pilot(base)

	for n = 1, o.missions or 0 do
		for _, global in ipairs(W.CHAINS[n]) do
			W.setState(player, global, "complete")
		end

		H.setQuestStatus(player, W.STATUS[n] .. ":attempted", "1")
		H.setQuestStatus(player, W.STATUS[n] .. ":reward", "1")
	end

	local n = (o.missions or 0) + 1

	if o.state ~= nil and W.CHAINS[n] ~= nil then
		H.setQuestStatus(player, W.STATUS[n] .. ":attempted", "1")

		if o.state == "won" then
			for _, global in ipairs(W.CHAINS[n]) do
				W.setState(player, global, "complete")
			end
		elseif o.state == "active" then
			W.setState(player, W.CHAINS[n][1], "active")
		end
	end

	if o.active then
		W.setState(player, o.active, "active")
	end

	return player
end

-- A Rebel pilot in a Rebel-faction ship in `zone` (default space_dantooine), the way the runtime tests start a quest
function W.flyer(zone)
	V1.load()

	return H.newPlayer({
		zone = zone or DA,
		pilot = "rebel",
		ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") },
	})
end

return W
