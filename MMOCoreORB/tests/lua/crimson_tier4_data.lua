-- Shared test data and builders for Crimson Phoenix Squadron tier 4, Part A (General Ufwol's missions), not a test file.
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol-missions/01-spec.md (Content contract, Data mapping, Appendix B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of agreeing with itself
-- (test_crimson_tier4_missions_data.lua proves the literals equal the SWG .tab fixtures):
--   U.GLOBALS / U.IDENTITY     the 17 quest globals and their class, type, name and zone (Content contract 1)
--   U.M1 .. U.M4 / U.CHAINS    the four missions, members in getSpaceQuestChain order (head, success branch, failure branch)
--   U.BRANCHES                 per mission: head, the success child, the failure child (and the failure child's own split, mission 1)
--   U.DUTIES / U.HEADS / U.CHILDREN
--   U.QUEST_STRINGS            the 17 TIER4_* constants of CrimsonPhoenixSquadronScreenplay (Content contract 2)
--   U.MET_KEY / U.statusKeys() the met key and the 9 keys the reset removes (the ":attempted" / ":reward" of the four heads and the met key)
--   U.POINTS                   Data mapping 2: the 62 nav points, per zone, Core3 x, z, y
--   U.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   U.REWARDS                  Source inventory 3 (D-6): credits and one item per head
--   U.load() / U.quest / U.squadron   the server's load (crimson_tier1_data.lua's); a missing production file is recorded, not raised
--   U.flyer(zone)              a Rebel pilot in a Rebel ship in `zone`, for the runtime tests
--   U.pilot{...}               a Crimson graduate of tier 3 with optional tier 4 journal state and keys (see the option list at U.pilot)
-- Part B (crimson-phoenix-tier4-ufwol, the conversation) extends this file below a "Part B" marker.

local H = require("harness")
local C = require("crimson_tier1_data")
local T = require("crimson_tier3_data")

local U = {}

U.SQUADRON_FILE = C.SQUADRON_FILE
U.SHIP_DIR = "ship_mobile/ships/"

local DT, DA, EN, YV = "space_dathomir", "space_dantooine", "space_endor", "space_yavin4"

U.M1 = { "space_battle_tatooine_rebel_tier4_1", "assassinate_tatooine_rebel_tier4_1_a", "patrol_tatooine_rebel_tier4_1_b", "destroy_surpriseattack_tatooine_rebel_tier4_1_c" }
U.M2 = { "recovery_tatooine_rebel_tier4_2", "delivery_tatooine_rebel_tier4_2_a", "survival_tatooine_rebel_tier4_2_b" }
U.M3 = { "space_battle_tatooine_rebel_tier4_3", "assassinate_tatooine_rebel_tier4_3_a", "assassinate_tatooine_rebel_tier4_3_b" }
U.M4 = { "assassinate_tatooine_rebel_tier4_4", "survival_tatooine_rebel_tier4_4_a", "space_battle_tatooine_rebel_tier4_4_b" }

U.CHAINS = { U.M1, U.M2, U.M3, U.M4 }

U.DUTIES = {
	"destroy_duty_tatooine_rebel_tier4_1", "escort_duty_tatooine_rebel_tier4_1", "recovery_duty_tatooine_rebel_tier4_1", "rescue_duty_tatooine_rebel_tier4_1",
}

-- the 17 globals in Content contract 1 order
U.GLOBALS = {}

for _, chain in ipairs(U.CHAINS) do
	for _, g in ipairs(chain) do
		U.GLOBALS[#U.GLOBALS + 1] = g
	end
end

for _, g in ipairs(U.DUTIES) do
	U.GLOBALS[#U.GLOBALS + 1] = g
end

U.HEADS = { U.M1[1], U.M2[1], U.M3[1], U.M4[1] }

-- per mission: success child, failure child, and the child the failure child splits to (mission 1 only)
U.BRANCHES = {
	{ head = U.M1[1], success = U.M1[2], failure = U.M1[3], failureNext = U.M1[4] },
	{ head = U.M2[1], success = U.M2[2], failure = U.M2[3] },
	{ head = U.M3[1], success = U.M3[2], failure = U.M3[3] },
	{ head = U.M4[1], success = U.M4[2], failure = U.M4[3] },
}

U.CHILDREN = {}

for _, chain in ipairs(U.CHAINS) do
	for i = 2, #chain do
		U.CHILDREN[#U.CHILDREN + 1] = chain[i]
	end
end

-- the 33 earlier globals (tiers 1-3), which the 17 follow in the registration order
U.TIER3_GLOBALS = {}

for _, g in ipairs(T.EARLIER_GLOBALS) do
	U.TIER3_GLOBALS[#U.TIER3_GLOBALS + 1] = g
end

for _, g in ipairs(T.GLOBALS) do
	U.TIER3_GLOBALS[#U.TIER3_GLOBALS + 1] = g
end

-- Content contract 1
U.IDENTITY = {}

local function id(global, class, type_, name, zone) U.IDENTITY[global] = { class = class, type = type_, name = name, zone = zone } end

id(U.M1[1], "SpaceBattleScreenplay", "space_battle", "tatooine_rebel_tier4_1", DT)
id(U.M1[2], "SpaceAssassinateScreenplay", "assassinate", "tatooine_rebel_tier4_1_a", DT)
id(U.M1[3], "SpacePatrolScreenplay", "patrol", "tatooine_rebel_tier4_1_b", DT)
id(U.M1[4], "SpaceSurpriseAttackScreenplay", "destroy_surpriseattack", "tatooine_rebel_tier4_1_c", DT)
id(U.M2[1], "SpaceRecoveryScreenplay", "recovery", "tatooine_rebel_tier4_2", DT)
id(U.M2[2], "SpaceDeliveryScreenplay", "delivery", "tatooine_rebel_tier4_2_a", DT)
id(U.M2[3], "SpaceSurvivalScreenplay", "survival", "tatooine_rebel_tier4_2_b", DT)
id(U.M3[1], "SpaceBattleScreenplay", "space_battle", "tatooine_rebel_tier4_3", EN)
id(U.M3[2], "SpaceAssassinateScreenplay", "assassinate", "tatooine_rebel_tier4_3_a", EN)
id(U.M3[3], "SpaceAssassinateScreenplay", "assassinate", "tatooine_rebel_tier4_3_b", EN)
id(U.M4[1], "SpaceAssassinateScreenplay", "assassinate", "tatooine_rebel_tier4_4", EN)
id(U.M4[2], "SpaceSurvivalScreenplay", "survival", "tatooine_rebel_tier4_4_a", EN)
id(U.M4[3], "SpaceBattleScreenplay", "space_battle", "tatooine_rebel_tier4_4_b", DT)
id(U.DUTIES[1], "SpaceDutyDestroyScreenplay", "destroy_duty", "tatooine_rebel_tier4_1", YV)
id(U.DUTIES[2], "SpaceDutyEscortScreenplay", "escort_duty", "tatooine_rebel_tier4_1", EN)
id(U.DUTIES[3], "SpaceDutyRecoveryScreenplay", "recovery_duty", "tatooine_rebel_tier4_1", DT)
id(U.DUTIES[4], "SpaceDutyRescueScreenplay", "rescue_duty", "tatooine_rebel_tier4_1", DA)

-- Content contract 2 (SIDE1 = the success split, SIDE2 = the failure split, SIDE3 = the failure split's own split)
U.QUEST_STRINGS = {
	TIER4_QUEST_STRING_1 = { type = "space_battle", name = "tatooine_rebel_tier4_1" },
	TIER4_QUEST_STRING_1_SIDE1 = { type = "assassinate", name = "tatooine_rebel_tier4_1_a" },
	TIER4_QUEST_STRING_1_SIDE2 = { type = "patrol", name = "tatooine_rebel_tier4_1_b" },
	TIER4_QUEST_STRING_1_SIDE3 = { type = "destroy_surpriseattack", name = "tatooine_rebel_tier4_1_c" },
	TIER4_QUEST_STRING_2 = { type = "recovery", name = "tatooine_rebel_tier4_2" },
	TIER4_QUEST_STRING_2_SIDE1 = { type = "delivery", name = "tatooine_rebel_tier4_2_a" },
	TIER4_QUEST_STRING_2_SIDE2 = { type = "survival", name = "tatooine_rebel_tier4_2_b" },
	TIER4_QUEST_STRING_3 = { type = "space_battle", name = "tatooine_rebel_tier4_3" },
	TIER4_QUEST_STRING_3_SIDE1 = { type = "assassinate", name = "tatooine_rebel_tier4_3_a" },
	TIER4_QUEST_STRING_3_SIDE2 = { type = "assassinate", name = "tatooine_rebel_tier4_3_b" },
	TIER4_QUEST_STRING_4 = { type = "assassinate", name = "tatooine_rebel_tier4_4" },
	TIER4_QUEST_STRING_4_SIDE1 = { type = "survival", name = "tatooine_rebel_tier4_4_a" },
	TIER4_QUEST_STRING_4_SIDE2 = { type = "space_battle", name = "tatooine_rebel_tier4_4_b" },
	TIER4_QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "tatooine_rebel_tier4_1" },
	TIER4_QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "tatooine_rebel_tier4_1" },
	TIER4_QUEST_STRING_DUTY_3 = { type = "recovery_duty", name = "tatooine_rebel_tier4_1" },
	TIER4_QUEST_STRING_DUTY_4 = { type = "rescue_duty", name = "tatooine_rebel_tier4_1" },
}

-- the constants in contract order (= U.GLOBALS order)
U.QUEST_STRING_FIELDS = {
	"TIER4_QUEST_STRING_1", "TIER4_QUEST_STRING_1_SIDE1", "TIER4_QUEST_STRING_1_SIDE2", "TIER4_QUEST_STRING_1_SIDE3",
	"TIER4_QUEST_STRING_2", "TIER4_QUEST_STRING_2_SIDE1", "TIER4_QUEST_STRING_2_SIDE2",
	"TIER4_QUEST_STRING_3", "TIER4_QUEST_STRING_3_SIDE1", "TIER4_QUEST_STRING_3_SIDE2",
	"TIER4_QUEST_STRING_4", "TIER4_QUEST_STRING_4_SIDE1", "TIER4_QUEST_STRING_4_SIDE2",
	"TIER4_QUEST_STRING_DUTY_1", "TIER4_QUEST_STRING_DUTY_2", "TIER4_QUEST_STRING_DUTY_3", "TIER4_QUEST_STRING_DUTY_4",
}

-- set by Part B's first-meeting reply, cleared by resetUfwolQuests (Content contract 2)
U.MET_KEY = "CrimsonPhoenixSquadronScreenplay:metTier4"
U.EKER_PILOT_KEY = C.EKER_PILOT_KEY

-- Status keys (set by Part B's handler): <name>:attempted and <name>:reward for the four mission heads
U.STATUS = { "tatooine_rebel_tier4_1", "tatooine_rebel_tier4_2", "tatooine_rebel_tier4_3", "tatooine_rebel_tier4_4" }

-- the 9 keys (suffixes after the player id) the reset removes: 8 head keys and the met key. `player` is accepted and ignored (the keys are suffixes).
function U.statusKeys(_)
	local out = {}

	for _, name in ipairs(U.STATUS) do
		out[#out + 1] = name .. ":attempted"
		out[#out + 1] = name .. ":reward"
	end

	out[#out + 1] = U.MET_KEY

	return out
end

-- Data mapping 2: zone -> name -> { x, z, y } (Core3 x, z, y = buildout PX, PY, PZ truncated toward zero); generated from the spec's table (62 rows)
U.POINTS = {
	space_dathomir = {
		tatooine_rebel_tier4_1_battle_point = { -3982, 3996, -3969 },
		tatooine_rebel_tier4_1_a_assassin_1 = { -4073, 3792, -3738 },
		tatooine_rebel_tier4_1_a_assassin_2 = { -4413, 3301, -3149 },
		tatooine_rebel_tier4_1_a_assassin_3 = { -4677, 2920, -2693 },
		tatooine_rebel_tier4_1_a_assassin_4 = { -5047, 2385, -2050 },
		tatooine_rebel_tier4_1_a_assassin_5 = { -5331, 1975, -1560 },
		tatooine_rebel_tier4_1_b_patrol_1 = { -3763, 4229, -4272 },
		tatooine_rebel_tier4_1_b_patrol_2 = { -3365, 4704, -4849 },
		tatooine_rebel_tier4_1_b_patrol_3 = { -3014, 5121, -5355 },
		tatooine_rebel_tier4_1_b_patrol_4 = { -2681, 5518, -5837 },
		tatooine_rebel_tier4_1_b_patrol_5 = { -2291, 5983, -6401 },
		tatooine_rebel_tier4_1_b_patrol_6 = { -1928, 6415, -6925 },
		tatooine_rebel_tier4_2_recovery_1 = { -5061, 4300, -799 },
		tatooine_rebel_tier4_2_recovery_2 = { -5301, 4879, 222 },
		tatooine_rebel_tier4_2_recovery_3 = { -5429, 5190, 770 },
		tatooine_rebel_tier4_2_recovery_4 = { -5539, 5457, 1240 },
		tatooine_rebel_tier4_2_recovery_5 = { -5725, 5906, 2032 },
		tatooine_rebel_tier4_2_recovery_6 = { -5875, 6269, 2671 },
		tatooine_rebel_tier4_2_recovery_7 = { -5790, 5133, 2104 },
		tatooine_rebel_tier4_2_recovery_8 = { -6092, 4667, 3908 },
		tatooine_rebel_tier4_2_recovery_9 = { -6115, 3799, 5154 },
		tatooine_rebel_tier4_2_recovery_10 = { -5907, 2695, 6881 },
		tatooine_rebel_tier4_2_a_delivery_1 = { -7413, 2757, 3359 },
		tatooine_rebel_tier4_2_b_survival = { -6698, 793, 3082 },
		tatooine_rebel_tier4_4_b_battle_point = { -6225, 536, 5366 },
		tatooine_rebel_tier4_1_recovery_duty_1 = { -4112, -660, 6128 },
		tatooine_rebel_tier4_1_recovery_duty_2 = { -5064, -335, 5600 },
		tatooine_rebel_tier4_1_recovery_duty_3 = { -5624, -10, 4721 },
		tatooine_rebel_tier4_1_recovery_duty_4 = { -6025, 468, 3625 },
		tatooine_rebel_tier4_1_recovery_duty_5 = { -5332, -44, 3978 },
		tatooine_rebel_tier4_1_recovery_duty_6 = { -5072, -429, 4719 },
		tatooine_rebel_tier4_1_recovery_duty_7 = { -4328, -938, 4625 },
		tatooine_rebel_tier4_1_recovery_duty_8 = { -3661, -1468, 4180 },
	},
	space_endor = {
		tatooine_rebel_tier4_3_battle_point = { 4724, -4083, 4337 },
		tatooine_rebel_tier4_3_a_assassin_1 = { 5642, -5571, 6420 },
		tatooine_rebel_tier4_3_a_assassin_2 = { 4958, -4865, 6356 },
		tatooine_rebel_tier4_3_a_assassin_3 = { 4261, -4146, 6290 },
		tatooine_rebel_tier4_3_a_assassin_4 = { 3678, -3545, 6235 },
		tatooine_rebel_tier4_3_a_assassin_5 = { 2919, -2762, 6164 },
		tatooine_rebel_tier4_3_b_assassin_1 = { 4657, -5185, 6658 },
		tatooine_rebel_tier4_3_b_assassin_2 = { 2492, -5574, 5239 },
		tatooine_rebel_tier4_3_b_assassin_3 = { 516, -6190, 3724 },
		tatooine_rebel_tier4_3_b_assassin_4 = { 452, -6758, 2306 },
		tatooine_rebel_tier4_3_b_assassin_5 = { 518, -7514, 6 },
		tatooine_rebel_tier4_3_b_assassin_6 = { -1819, -6799, -1968 },
		tatooine_rebel_tier4_4_assassin_1 = { 2085, -5467, 3978 },
		tatooine_rebel_tier4_4_assassin_2 = { 2030, -4974, 3623 },
		tatooine_rebel_tier4_4_assassin_3 = { 1964, -4397, 3208 },
		tatooine_rebel_tier4_4_assassin_4 = { 1900, -3832, 2802 },
		tatooine_rebel_tier4_4_assassin_5 = { 1796, -2913, 2141 },
		tatooine_rebel_tier4_4_assassin_6 = { 1685, -1923, 1429 },
		tatooine_rebel_tier4_4_a_survival = { 3601, -1355, 1623 },
		tatooine_rebel_tier4_1_escort_duty_1 = { 718, 763, -2985 },
		tatooine_rebel_tier4_1_escort_duty_2 = { 400, 1766, -1686 },
		tatooine_rebel_tier4_1_escort_duty_3 = { 1977, 2776, -1514 },
		tatooine_rebel_tier4_1_escort_duty_4 = { 3723, 3514, -1530 },
		tatooine_rebel_tier4_1_escort_duty_5 = { 6199, 4606, -2378 },
	},
	space_yavin4 = {
		tatooine_rebel_tier4_2_a_delivery_2 = { 3300, 4570, 5000 },
	},
	space_dantooine = {
		tatooine_rebel_tier4_1_rescue_duty_1 = { 3489, 4963, 6327 },
		tatooine_rebel_tier4_1_rescue_duty_2 = { 3374, 4305, 5044 },
		tatooine_rebel_tier4_1_rescue_duty_3 = { 3309, 3932, 4319 },
		tatooine_rebel_tier4_1_rescue_duty_4 = { 4016, 2618, 3838 },
	},
}

U.ITEM_ROOT = "object/tangible/ship/components/"
U.CREDITS = 10000

-- Source inventory 3 (JF:359-390), D-6: one item per head
U.ITEMS = {
	"shield_generator/shd_mission_reward_rebel_taim_military_grade.iff",
	"droid_interface/ddi_mission_reward_rebel_novaldex_low_latency.iff",
	"booster/bst_mission_reward_rebel_qualdex_halcyon.iff",
	"weapon/wpn_mission_reward_rebel_incom_tricannon.iff",
}

U.REWARDS = {}

for n, head in ipairs(U.HEADS) do
	U.REWARDS[head] = { credits = U.CREDITS, item = U.ITEM_ROOT .. U.ITEMS[n] }
end

-- Data mapping 1: battle forwards (excerpt fltKX, fltKY, fltKZ -> x, z, y)
U.FORWARD_1 = { x = 0.552836, z = -0.611592, y = 0.565974 }
U.FORWARD_3 = { x = -0.210324, z = 0.608905, y = -0.764852 }
U.FORWARD_4B = { x = -0.007078, z = 0.040126, y = 0.999170 }

U.DROID_MOBILE = "object/mobile/shared_ig_assassin_droid.iff"
U.PRISONER_MOBILE = "object/mobile/shared_dressed_dathomir_prisoner_05.iff"

-- FF-7: the 18 distinct ships
U.SHIPS = {
	"freighterheavy_imperial_prison_transport", "imp_decimator_tier4", "imp_tie_advanced_tier4", "imp_tie_aggressor_tier4", "imp_tie_bomber_tier4",
	"imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_oppressor_tier4", "lambdashuttle_station_commander", "reb_awing_tier4", "reb_bwing_tier4",
	"reb_fugitive_transport_ykl37r_tier4", "reb_fugitive_transport_yt1300_tier4", "reb_spy_yt1300_tier4", "reb_xwing_tier4", "rebel_agent_vortex",
	"tieadvanced_inquisitor_tier4", "yt1300_rebel_spy",
}

local function point(zone, name, extra)
	local p = U.POINTS[zone][name]

	assert(p ~= nil, "no spec point " .. tostring(name) .. " in " .. zone)

	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra or {}) do
		t[k] = v
	end

	return t
end

local function numbered(prefix, from, to)
	local out = {}

	for i = from, to do
		out[#out + 1] = prefix .. i
	end

	return out
end

-- points of a name list; `number` names the field that gets the 1-based index (escortNumber, patrolNumber)
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

local function item(n) return { { species = { -1 }, item = U.ITEM_ROOT .. U.ITEMS[n] } } end

local function taunts5(...)
	local out = {}

	for _, key in ipairs({ ... }) do
		out[key] = 5
	end

	return out
end

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function U.expected()
	local P = "tatooine_rebel_tier4_"
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES
	local randSurvival = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.RANDOM
	local randDelivery = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM
	local END = { sideQuest = false, sideQuestType = "" }

	local function merge(...)
		local out = {}

		for _, t in ipairs({ ... }) do
			for k, v in pairs(t) do
				out[k] = v
			end
		end

		return out
	end

	local function base(global, more)
		local ident = U.IDENTITY[global]

		return merge({ className = global, questType = ident.type, questName = ident.name, questZone = ident.zone }, more)
	end

	local function child(parent, more)
		local pid = U.IDENTITY[parent]

		return merge({ parentQuest = parent, parentQuestType = pid.type, parentQuestName = pid.name }, more)
	end

	-- a head: BIDIRECTIONAL, 5 s, the success child and the failure child
	local function bidirectional(success, failure)
		local s, f = U.IDENTITY[success], U.IDENTITY[failure]

		return {
			sideQuest = true, sideQuestType = s.type, sideQuestName = s.name, sideQuestSplitType = ST.BIDIRECTIONAL, sideQuestDelay = 5,
			sideFailQuestType = f.type, sideFailQuestName = f.name,
		}
	end

	local function headRewards(n) return { creditReward = U.CREDITS, itemReward = item(n) } end

	local F, I, B, A, G = "imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_bomber_tier4", "imp_tie_advanced_tier4", "imp_tie_aggressor_tier4"
	local OPP = "imp_tie_oppressor_tier4"
	local out = {}

	-- Mission 1: battle > assassinate (won) or patrol > surprise attack (lost)
	out[U.M1[1]] = base(U.M1[1], merge(headRewards(1), bidirectional(U.M1[2], U.M1[3]), {
		battlePoint = point(DT, P .. "1_battle_point", { forward = U.FORWARD_1 }),
		damageMultiplier = 7, allyArrivalDelay = 150, enemyArrivalDelay = 130, allyOriginDist = 950, enemyOriginDist = -750, allyArrivalDist = 300, enemyArrivalDist = -200,
		allyForce = cat(rep("reb_awing_tier4", 2), rep("reb_xwing_tier4", 3)),
		enemyForce = cat({ A, G }, rep(I, 7)),
	}))
	out[U.M1[2]] = base(U.M1[2], merge(child(U.M1[1], {}), END, {
		arrivalDelay = 5, failTimer = 20, mustDestroyEscort = false,
		assassinateSpawns = { target = G, escorts = { I, I, I, F, F, F } },
		targetPatrols = pts(DT, numbered(P .. "1_a_assassin_", 1, 5)),
	}))
	out[U.M1[3]] = base(U.M1[3], merge(child(U.M1[1], {}), {
		sideQuest = true, sideQuestType = "destroy_surpriseattack", sideQuestName = "tatooine_rebel_tier4_1_c", sideQuestSplitType = ST.PATROL_POINT,
		sideQuestPatrolStart = 5, sideQuestDelay = 5,
		patrolPoints = pts(DT, numbered(P .. "1_b_patrol_", 1, 6), { radius = 150 }, "patrolNumber"),
	}))
	out[U.M1[4]] = base(U.M1[4], merge(child(U.M1[3], {}), END, {
		surpriseAttackShips = { zone = DT, spawns = { { count = 6, shipName = I } } },
	}))

	-- Mission 2: recovery > delivery (Dathomir to Yavin 4) (won) or survival (lost)
	out[U.M2[1]] = base(U.M2[1], merge(headRewards(2), bidirectional(U.M2[2], U.M2[3]), {
		arrivalDelay = 10, recoveryDelay = 30,
		recoverShip = OPP,
		recoveryConversationMobile = U.DROID_MOBILE,
		escortShips = cat(rep(F, 6), rep(I, 3)),
		preRecoveryPoints = pts(DT, numbered(P .. "2_recovery_", 1, 6), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(DT, numbered(P .. "2_recovery_", 7, 10), { radius = 250 }, "escortNumber"),
		attackDelay = 45,
		attackShips = { { I, I, I, F, F, F }, cat({ A }, rep(F, 5)) },
		tauntData = taunts5("panicCount", "thanksCount"),
	}))
	out[U.M2[2]] = base(U.M2[2], merge(child(U.M2[1], {}), END, {
		deliveryZone = YV,
		pickupPoint = point(DT, P .. "2_a_delivery_1"),
		deliveryPoint = point(YV, P .. "2_a_delivery_2"),
		pickupShip = "yt1300_rebel_spy", deliveryShip = "rebel_agent_vortex",
		attackShipLists = { rep(F, 6), { F, F, "tieadvanced_inquisitor_tier4", F, F, F }, { I, I, I, F, F, F } },
		attackPeriod = 45, attackListType = randDelivery,
	}))
	out[U.M2[3]] = base(U.M2[3], merge(child(U.M2[1], {}), END, {
		transmissionPoint = point(DT, P .. "2_b_survival"),
		totalTransmissionTime = 240, timesToUpdateProgress = 4, transmissionStartDelay = 5, delayToFirstAttack = 10,
		attackShipLists = { rep(F, 6), cat({ A }, rep(F, 5)), { I, I, I, F, F, F }, cat({ G }, rep(F, 5)) },
		attackPeriod = 50, attackListType = randSurvival,
	}))

	-- Mission 3: battle > assassinate (won) or assassinate (lost)
	out[U.M3[1]] = base(U.M3[1], merge(headRewards(3), bidirectional(U.M3[2], U.M3[3]), {
		battlePoint = point(EN, P .. "3_battle_point", { forward = U.FORWARD_3 }),
		damageMultiplier = 7, allyArrivalDelay = 140, enemyArrivalDelay = 120, allyOriginDist = 800, enemyOriginDist = -900, allyArrivalDist = 250, enemyArrivalDist = -150,
		allyForce = rep("reb_xwing_tier4", 4),
		enemyForce = cat(rep(I, 6), { F, F, A }),
	}))
	out[U.M3[2]] = base(U.M3[2], merge(child(U.M3[1], {}), END, {
		arrivalDelay = 5, failTimer = 20, mustDestroyEscort = false,
		assassinateSpawns = { target = "lambdashuttle_station_commander", escorts = cat({ A, A }, rep(F, 6)) },
		targetPatrols = pts(EN, numbered(P .. "3_a_assassin_", 1, 5)),
	}))
	out[U.M3[3]] = base(U.M3[3], merge(child(U.M3[1], {}), END, {
		arrivalDelay = 5, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = OPP, escorts = rep(B, 5) },
		targetPatrols = pts(EN, numbered(P .. "3_b_assassin_", 1, 6)),
	}))

	-- Mission 4: assassinate > survival (won) or space battle in Dathomir (lost)
	out[U.M4[1]] = base(U.M4[1], merge(headRewards(4), bidirectional(U.M4[2], U.M4[3]), {
		arrivalDelay = 10, failTimer = 20, mustDestroyEscort = false,
		assassinateSpawns = { target = "imp_decimator_tier4", escorts = rep(F, 6) },
		targetPatrols = pts(EN, numbered(P .. "4_assassin_", 1, 6)),
	}))
	out[U.M4[2]] = base(U.M4[2], merge(child(U.M4[1], {}), END, {
		transmissionPoint = point(EN, P .. "4_a_survival"),
		totalTransmissionTime = 360, timesToUpdateProgress = 6, transmissionStartDelay = 10, delayToFirstAttack = 5,
		attackShipLists = { { F, F, F, A, I, I }, { B, B, B, F, F, F }, { G, I, I, F, F, F }, { I, I, OPP, F, F, F } },
		attackPeriod = 55, attackListType = randSurvival,
	}))
	out[U.M4[3]] = base(U.M4[3], merge(child(U.M4[1], {}), END, {
		battlePoint = point(DT, P .. "4_b_battle_point", { forward = U.FORWARD_4B }),
		damageMultiplier = 7, allyArrivalDelay = 140, enemyArrivalDelay = 120, allyOriginDist = 600, enemyOriginDist = -750, allyArrivalDist = 100, enemyArrivalDist = -100,
		allyForce = { "reb_awing_tier4", "reb_xwing_tier4", "reb_xwing_tier4", "reb_bwing_tier4" },
		enemyForce = cat({ "imp_decimator_tier4", G, F, F, F, I, I, F, F, F }),
	}))

	-- Duties
	out[U.DUTIES[1]] = base(U.DUTIES[1], merge(END, {
		creditReward = 300,
		totalLevels = 5, totalRounds = 3, totalWaves = 4,
		bossShip = A,
		shipTypes = { { F, F, F }, { I, F, F }, { B, F, F } },
	}))
	out[U.DUTIES[2]] = base(U.DUTIES[2], merge(END, {
		creditReward = 5000, creditKillBonus = 300,
		escortShips = { "reb_spy_yt1300_tier4" },
		escortPoints = pts(EN, numbered(P .. "1_escort_duty_", 1, 5), { zoneName = EN, radius = 250 }, "escortNumber"),
		attackDelay = 45,
		attackShips = { { F, F, F }, { I, F, F }, { B, F, F } },
		tauntData = taunts5("goodbyeCount", "reasonCount", "tauntCount", "thanksCount"),
	}))
	out[U.DUTIES[3]] = base(U.DUTIES[3], merge(END, {
		creditReward = 5000, creditKillBonus = 300,
		numResponses = 5, arrivalDelay = 10, recoveryDelay = 30,
		recoverShips = { "freighterheavy_imperial_prison_transport" },
		recoveryConversationMobile = U.PRISONER_MOBILE,
		escortShips = { F, F, F },
		preRecoveryPoints = pts(DT, numbered(P .. "1_recovery_duty_", 1, 4), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(DT, numbered(P .. "1_recovery_duty_", 5, 8), { radius = 250 }, "escortNumber"),
		attackDelay = 45,
		attackShips = { { F, F, F }, { I, F, F }, { B, F, F } },
		tauntData = taunts5("panicCount", "thanksCount"),
	}))
	out[U.DUTIES[4]] = base(U.DUTIES[4], merge(END, {
		creditReward = 5000, creditKillBonus = 300,
		recoveryPath = pts(DA, numbered(P .. "1_rescue_duty_", 1, 4)),
		targetShipTypes = { "reb_fugitive_transport_ykl37r_tier4", "reb_fugitive_transport_yt1300_tier4" },
		targetArrivalDelay = 5,
		attackShipLists = { { F, F, F }, { I, F, F }, { B, F, F } },
		attackPeriod = 45, attackListType = 1, numResponses = 5,
	}))

	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

U.loadErrors = C.loadErrors

-- The server's load: every squadron file (crimson_tier1_data.lua's load); a missing production file is recorded, not raised
function U.load() C.load() end

function U.problems() return table.concat(C.loadErrors, " | ") end

function U.quest(global)
	C.load()

	return H.expectGlobal(global, "Crimson Phoenix tier 4 quest table (crimson-phoenix-tier4-ufwol-missions). Load problems: " .. U.problems())
end

function U.squadron()
	C.load()

	return H.expectGlobal("CrimsonPhoenixSquadronScreenplay", "squadron screenplay object. Load problems: " .. U.problems())
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

function U.crc(global)
	local ident = U.IDENTITY[global]

	return H.questCrc(ident.type, ident.name)
end

-- Journal state of one of the 17 tables (type AND name, so the five tatooine_rebel_tier4_1 tables are separate). state: "complete" | "active" | "none"
function U.setState(player, global, state)
	local key = U.crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function U.state(player, global)
	local key = U.crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- the status keys of the pilot whose name starts with `name` .. ":" (the scan the duty tests use: a duty must set no <name>:* key)
function U.keysNamed(player, name)
	local prefix = tostring(player.objectID) .. name .. ":"
	local out = {}

	for key, value in pairs(H.Fakes.questStatus) do
		if key:sub(1, #prefix) == prefix then
			out[#out + 1] = key:sub(#tostring(player.objectID) + 1) .. "=" .. tostring(value)
		end
	end

	table.sort(out)
	return out
end

-- A Crimson Phoenix graduate of tier 3 (crimson_tier3_data.lua's T.pilot: tiers 1-3 skills, EKER_PILOT_KEY "3", Eker's and Ulvaw'op's missions paid, pilot tier 4)
-- with optional tier 4 state. Options:
--   ufwol       k: Ufwol's missions 1..k won (every member of the chain complete), :attempted and :reward set (default 0)
--   ufwolKeys   true: the 8 head keys set whatever the journal says
--   met         true: TIER4_MET_KEY set
--   ufwolActive global of a tier 4 member left active in the journal
--   duty        global of a tier 4 duty left active in the journal
--   missions    Ulvaw'op's missions won (default 4), t3 the tier 3 skills held (default 4): crimson_tier3_data.lua's T.pilot options; the rest is that file's
function U.pilot(o)
	o = o or {}
	C.load()

	local base = {}

	for k, v in pairs(o) do
		base[k] = v
	end

	base.ufwol, base.ufwolKeys, base.met, base.ufwolActive, base.duty = nil, nil, nil, nil, nil
	base.missions = o.missions == nil and 4 or o.missions
	base.t3 = o.t3 == nil and 4 or o.t3

	local player = T.pilot(base)

	for n = 1, o.ufwol or 0 do
		for _, global in ipairs(U.CHAINS[n]) do
			U.setState(player, global, "complete")
		end

		H.setQuestStatus(player, U.STATUS[n] .. ":attempted", "1")
		H.setQuestStatus(player, U.STATUS[n] .. ":reward", "1")
	end

	if o.ufwolKeys then
		for _, name in ipairs(U.STATUS) do
			H.setQuestStatus(player, name .. ":attempted", "1")
			H.setQuestStatus(player, name .. ":reward", "1")
		end
	end

	if o.met then
		H.setQuestStatus(player, U.MET_KEY, "1")
	end

	if o.ufwolActive then
		U.setState(player, o.ufwolActive, "active")
	end

	if o.duty then
		U.setState(player, o.duty, "active")
	end

	return player
end

-- A Rebel pilot in a Rebel-faction ship in `zone` (default space_dathomir), the way the runtime tests start a quest
function U.flyer(zone)
	C.load()

	return H.newPlayer({
		zone = zone or DT,
		pilot = "rebel",
		ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") },
	})
end

---------------------------------------------------------------------------------------------
-- Part B: General Ufwol's conversation (crimson-phoenix-tier4-ufwol) extends this file below this marker.
---------------------------------------------------------------------------------------------

return U
