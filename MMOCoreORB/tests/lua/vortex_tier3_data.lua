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
function W.skillsOf(indexes)
	local out = {}

	for i, idx in ipairs(indexes) do
		out[i] = (V1.TRAIN[idx].skill:gsub("_01$", "_03"))
	end

	return out
end

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
--   t3         number of tier 3 skills held (default 0), or a list of W.TRAIN indexes (any subset, Part B)
--   active     global of a tier 3 member left active in the journal
--   partial    k: the first k quests of mission missions+1 are complete, :attempted set, nothing active (a middle member failed; Part B)
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
	-- t3 is a count (the first k skills in the tier 1 training order) or, since Part B, a list of indexes into W.TRAIN (any subset)
	local t3skills, t3count

	if type(o.t3) == "table" then
		t3skills, t3count = W.skillsOf(o.t3), #o.t3
	else
		t3skills, t3count = W.tier3Skills(o.t3 or 0), o.t3 or 0
	end

	base.pilotTier = o.pilotTier or (t3count >= 4 and 4 or 3)
	base.skills = {}

	for _, skill in ipairs(o.skills or {}) do
		base.skills[#base.skills + 1] = skill
	end

	for _, skill in ipairs(t3skills) do
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

	-- Part B: partial = k: the first k quests of mission missions+1 are complete and nothing is active (the chain broke after them: a member failed)
	if o.partial ~= nil and W.CHAINS[n] ~= nil then
		H.setQuestStatus(player, W.STATUS[n] .. ":attempted", "1")

		for k = 1, o.partial do
			W.setState(player, W.CHAINS[n][k], "complete")
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

---------------------------------------------------------------------------------------------
-- Part B: Brother Ezkiel's conversation (vortex-tier3-ezkiel)
-- Spec: .claude/work/vortex-tier3-ezkiel/01-spec.md (Content contract 2-4, Data mapping 1-2, Conversation flow 1-4, Appendix A).
-- Everything here is copied from the spec; the screens table comes from the spec's Appendix A by a scratch script (vortex_tier3_ezkiel_screens_data.lua).
--   W.TEMPLATE / W.HANDLER / W.STF / W.PREFIX and the file names of the template, handler, NPC, SC and SPL
--   W.SCREENS / W.screenRow / W.screenIds / W.reach / W.walkTo   Appendix A (the static links)
--   W.MISSIONS / W.TRAIN / W.START_SCREENS / W.REWARD_SCREENS / W.NAME_SCREENS   the handler's tables (Content contract 2)
--   W.NGE_IDS                  the 45 NGE editor numbers J3 uses (Source inventory 7)
--   W.loadConversation() / W.requireConversation(lu) / W.handler()   the server's load of Ezkiel's template and handler (load errors are recorded)
--   W.npc / W.talk / W.firstScreen / W.drive   H.converse from the first screen / from a given screen (the reward and start screens run their display actions)
--   W.spyStarts / W.startedList / W.attempted / W.standing / W.items / W.flag / W.held3 / W.statusDiff / W.rewardPilot   observation helpers
---------------------------------------------------------------------------------------------

W.TEMPLATE = "ezkiel_convo_template"
W.HANDLER = "ezkielConvoHandler"
W.STF = "conversation/naboo_rebel_tier3"
W.PREFIX = "@conversation/naboo_rebel_tier3:"

W.TEMPLATE_FILE = "mobile/conversations/space/rebel/vortex_squadron/ezkiel_convo.lua"
W.HANDLER_FILE = "screenplays/space/conversations/rebel/vortex_squadron/ezkielConvoHandler.lua"
W.NPC_FILE = "mobile/space/ezkiel.lua"
W.SPACE_CONVERSATIONS = "mobile/conversations/space/space_conversations.lua"
W.SCREENPLAYS = "screenplays/space/screenplays.lua"

W.TEMPLATE_INCLUDE = 'includeFile("conversations/space/rebel/vortex_squadron/ezkiel_convo.lua")'
W.HANDLER_INCLUDE = 'includeFile("space/conversations/rebel/vortex_squadron/ezkielConvoHandler.lua")'

W.STANDING = 100
W.TIER2_M4_REWARD = "vortex_mission_4:reward"
W.TRAINED_SID = "s_5a7254ca"

W.SCREENS = require("vortex_tier3_ezkiel_screens_data")

function W.screenRow(id)
	for _, row in ipairs(W.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (131), sorted
function W.screenIds()
	local out = {}

	for i, row in ipairs(W.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- Content contract 2: MISSIONS (head, chain end constant, status key name, screens, J3 reward item)
W.MISSIONS = {}

for n = 1, 4 do
	W.MISSIONS[n] = {
		n = n, head = W.HEADS[n], questString = "TIER3_QUEST_STRING_" .. n, endString = "TIER3_QUEST_STRING_" .. n .. "_SIDE4", status = W.STATUS[n],
		offer = "m" .. n .. "_offer", failed = "m" .. n .. "_failed", reward = "m" .. n .. "_reward", item = W.ITEMS[n], zone = ({ DA, DA, EN, DT })[n],
	}
end

-- Content contract 2: TRAIN_CHOICES in menu order. skl = the client skill name (skl_n) that maps the topic reply to the skill (Source inventory FV-1);
-- words = what the reply text must say
W.TRAIN = {
	{ x = "starships", skill = "pilot_rebel_navy_starships_03", reply = "s_879249ea", trained = "trained_starships", skl = "Space Superiority Fighters", words = "space superiority fighters" },
	{ x = "weapons", skill = "pilot_rebel_navy_weapons_03", reply = "s_a436613b", trained = "trained_weapons", skl = "Equipment C: Advanced Alliance Starship Component Use", words = "advanced starship component use" },
	{ x = "procedures", skill = "pilot_rebel_navy_procedures_03", reply = "s_e6be1367", trained = "trained_procedures", skl = "Advanced Space Combat", words = "advanced space combat" },
	{ x = "droid", skill = "pilot_rebel_navy_droid_03", reply = "s_ccecab6a", trained = "trained_droid", skl = "System Balance Programming", words = "system balance programming" },
}

-- Content contract 2: START_SCREENS (17), screen -> mission
W.START_SCREENS = {
	m1_failed = 1, m1_accept_d683dc69 = 1, m1_accept_401aa65c = 1, m1_accept_c872184 = 1, m1_accept_fb1d4add = 1, m1_accept_21aa6c60 = 1,
	m2_retry_turn = 2, m2_retry_shot = 2, m2_accept_cb3876f5 = 2, m2_accept_f8a22f8 = 2,
	m3_retry_defeated = 3, m3_retry_blowtorch = 3, m3_accept_68355d90 = 3, m3_accept_18c308e1 = 3,
	m4_failed = 4, m4_accept_aa7a038e = 4, m4_accept_b24e355f = 4,
}

-- Content contract 2: REWARD_SCREENS (they are also the training screens), screen -> mission
W.REWARD_SCREENS = { m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4 }

-- Content contract 2: NAME_SCREENS (8)
W.NAME_SCREENS = { "tier_done", "grounded", "m1_failed", "m4_failed", "m1_reward", "m1_offer", "m1_840cb413", "m2_offer" }

-- Source inventory 7: the 45 NGE editor numbers J3 uses
W.NGE_IDS = {
	"s_13", "s_78", "s_80", "s_83", "s_85", "s_87", "s_89", "s_94", "s_96", "s_98", "s_100", "s_102", "s_115", "s_121", "s_124", "s_126", "s_154", "s_156", "s_158",
	"s_160", "s_166", "s_168", "s_170", "s_172", "s_182", "s_184", "s_186", "s_188", "s_209", "s_220", "s_223", "s_225", "s_227", "s_229", "s_237", "s_250", "s_252",
	"s_254", "s_256", "s_267", "s_312", "s_313", "s_314", "s_315", "s_316",
}

-- The Appendix A screens that open an offer's walks: the accept screens of mission n (Content contract 2 START_SCREENS without the failure/retry screens)
function W.acceptScreens(n)
	local out = {}

	for id, mission in pairs(W.START_SCREENS) do
		if mission == n and id:find("_accept_", 1, true) then
			out[#out + 1] = id
		end
	end

	table.sort(out)
	return out
end

-- Breadth-first search over the static links of Appendix A from `start`: id -> { ids = {screen ids from start}, replies = {reply sids} }.
-- `avoid` (set of screen ids) are never entered.
function W.reach(start, avoid)
	local found = { [start] = { ids = { start }, replies = {} } }
	local queue = { start }

	while #queue > 0 do
		local id = table.remove(queue, 1)
		local cur = found[id]

		for _, o in ipairs(W.screenRow(id).options) do
			if found[o[2]] == nil and not (avoid and avoid[o[2]]) then
				local ids, replies = { table.unpack(cur.ids) }, { table.unpack(cur.replies) }

				ids[#ids + 1] = o[2]
				replies[#replies + 1] = o[1]
				found[o[2]] = { ids = ids, replies = replies }
				queue[#queue + 1] = o[2]
			end
		end
	end

	return found
end

-- The shortest reply path (and the screens shown) from `from` to `to`; nil when there is none
function W.walkTo(from, to, avoid)
	local hit = W.reach(from, avoid)[to]

	if hit == nil then
		return nil
	end

	return hit.replies, hit.ids
end

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		V1.loadErrors[#V1.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

local loadedB = false

-- The server's load of Ezkiel's template and handler (after the squadron files). A missing production file is recorded in the load problems, not raised.
function W.loadConversation()
	W.load()

	if loadedB then
		return
	end

	loadedB = true
	try("ezkiel_convo.lua", function() H.loadMobile("conversations/space/rebel/vortex_squadron/ezkiel_convo.lua") end)
	try("ezkielConvoHandler.lua", function() H.loadScreenplay("space/conversations/rebel/vortex_squadron/ezkielConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded (a readable red phase)
function W.requireConversation(lu)
	W.loadConversation()
	lu.assertNotNil(H.conversationTemplateTable(W.TEMPLATE), W.TEMPLATE .. " is not registered by addConversationTemplate (vortex-tier3-ezkiel). Load problems: " .. W.problems())
	lu.assertNotNil(rawget(_G, W.HANDLER), W.HANDLER .. " is not defined (vortex-tier3-ezkiel). Load problems: " .. W.problems())
end

function W.handler()
	W.loadConversation()

	return H.expectGlobal(W.HANDLER, "Ezkiel's conversation handler (vortex-tier3-ezkiel). Load problems: " .. W.problems())
end

-- Brother Ezkiel in Vrovel's room (screenplays/poi/dantooine_abandoned_rebel_base.lua:19)
function W.npc() return H.newNpc({ name = "Brother Ezkiel", zone = "dantooine", x = -3.2, z = 1.0, y = 7.9 }) end

local function requireLoaded()
	W.loadConversation()

	if H.conversationTemplateTable(W.TEMPLATE) == nil or rawget(_G, W.HANDLER) == nil then
		error("Ezkiel's conversation is not loaded (vortex-tier3-ezkiel). Load problems: " .. W.problems(), 3)
	end
end

-- Talks to Ezkiel from the first screen. choices as for H.converse (0-based indexes, option sids, hooks).
function W.talk(player, choices)
	requireLoaded()

	return H.converse({ template = W.TEMPLATE, player = player, npc = W.npc(), choices = choices })
end

function W.firstScreen(player) return W.talk(player)[1].id end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (vortex_tier2_data.lua's drive on Ezkiel's template)
function W.drive(player, startId, choices)
	requireLoaded()

	local template, handler, npc = V2.TEMPLATE, V2.HANDLER, V2.npc

	V2.TEMPLATE, V2.HANDLER, V2.npc = W.TEMPLATE, W.HANDLER, W.npc

	local results = table.pack(pcall(V2.drive, player, startId, choices))

	V2.TEMPLATE, V2.HANDLER, V2.npc = template, handler, npc

	if not results[1] then
		error(results[2], 0)
	end

	return table.unpack(results, 2, results.n)
end

W.ids = V1.ids
W.optionSids = V1.optionSids
W.linksOf = V1.linksOf

-- Spies startQuest on all 20 tables (H.spyOn does not call the original); returns { global -> calls }
function W.spyStarts()
	local spies = {}

	for _, global in ipairs(W.GLOBALS) do
		spies[global] = H.spyOn(W.quest(global), "startQuest")
	end

	return spies
end

-- "global xN" strings of the quests whose startQuest was called, in W.GLOBALS order
function W.startedList(spies)
	local out = {}

	for _, global in ipairs(W.GLOBALS) do
		if spies[global] ~= nil and #spies[global] > 0 then
			out[#out + 1] = global .. " x" .. #spies[global]
		end
	end

	return out
end

function W.attempted(player, n) return H.getQuestStatus(player, W.STATUS[n] .. ":attempted") end

function W.paid(player, n) return H.getQuestStatus(player, W.STATUS[n] .. ":reward") end

-- the Rebel standing of the pilot
function W.standing(player) return player.ghost.factionStanding.rebel or 0 end

-- giveItem templates received by the pilot, in order
function W.items(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory then
			out[#out + 1] = call[2]
		end
	end

	return out
end

-- The VORTEX_PILOT_KEY value of the pilot ("1", "2", "3") or nil
function W.flag(player) return H.getQuestStatus(player, W.VORTEX_PILOT_KEY) end

-- The tier 3 skills (of the four) the pilot holds, in W.TRAIN order
function W.held3(player)
	local out = {}

	for _, t in ipairs(W.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

function W.free() return H.Engine.callsTo("awardSkill") end
function W.bought() return H.Engine.callsTo("skillManagerAwardSkill") end

-- The status keys (suffixes after the player id) whose value differs between two snapshots of Fakes.questStatus (M.snapshot(player).status)
function W.statusDiff(player, before, after)
	local id, out = tostring(player.objectID), {}

	for key, value in pairs(after) do
		if before[key] ~= value then
			out[#out + 1] = (key:sub(1, #id) == id) and key:sub(#id + 1) or key
		end
	end

	for key in pairs(before) do
		if after[key] == nil then
			out[#out + 1] = (key:sub(1, #id) == id) and key:sub(#id + 1) or key
		end
	end

	table.sort(out)
	return out
end

-- "mission n is won and unpaid, missions 1..n-1 are paid with their skills chosen (count n - 1)": the pilot a reward screen opens for
function W.rewardPilot(n, extra)
	local o = { missions = n - 1, t3 = n - 1, state = "won" }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return W.pilot(o)
end

-- "missions 1..n-1 won and paid with their skills chosen": the pilot mission n is offered to
function W.readyFor(n, extra)
	local o = { missions = n - 1, t3 = n - 1 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return W.pilot(o)
end

-- A pilot who is not a pilot at all (no pilot skill, no squadron)
function W.nonPilot(extra)
	local o = { pilot = false, squadron = false, t1 = 0, t2 = 0, vrovelMissions = 0, graduated = false }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return W.pilot(o)
end

-- Starts all 20 quest tables (registers them, the way the runtime tests do) so a real startQuest can run
function W.startAll()
	for _, global in ipairs(W.GLOBALS) do
		W.quest(global):start()
	end
end

return W
