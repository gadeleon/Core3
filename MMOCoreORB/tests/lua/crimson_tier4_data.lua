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
-- Part B: General Ufwol's conversation (crimson-phoenix-tier4-ufwol)
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol/01-spec.md (Content contract 2-4, Data mapping 1-2, Conversation flow 1-5, Appendix A and D).
-- Everything here is copied from the spec; the screens table comes from the spec's Appendix A by a scratch script (crimson_tier4_ufwol_screens_data.lua).
-- The API mirrors vortex_tier4_data.lua's Part B (Evin) so the two sets of tests read alike:
--   U.TEMPLATE / U.HANDLER / U.STF / U.PREFIX / U.JAVA and the file names of the template, handler, NPC, SC and SPL
--   U.SCREENS / U.screenRow / U.screenIds / U.reach / U.walkTo / U.follow   Appendix A (the static links)
--   U.MISSIONS / U.TRAIN / U.DUTY_SCREENS / U.START_SCREENS / U.REWARD_SCREENS / U.NAME_SCREENS / U.TIER_SCREENS   the handler's tables (Content contract 2)
--   U.NGE_MAP                    the 108 NGE editor numbers JF uses, each with its Data mapping 2 class and where it landed
--   U.OFFER_PATHS                Appendix D: one reply path per accept screen route
--   U.javaRewards()              the four rewardForMissionN bodies of the JF fixture (the oracle of AC-7)
--   U.loadConversation() / U.requireConversation(lu) / U.handler()   the server's load of Ufwol's template and handler (load errors are recorded)
--   U.npc / U.talk / U.firstScreen / U.drive   H.converse from the first screen / from a given screen (start, reward and duty screens run their display actions)
--   U.pilot{...}                 extended below (flag, ulvawopM4Paid, t4, mission, paid, master, squadron, otherQuest, ...)
--   U.spyDuties / U.startedDuties / U.recordGrants / U.recordChainStarts / U.stubChainStarts / U.restore / U.startAll / U.useSkillCosts / U.snapshot   observation helpers
---------------------------------------------------------------------------------------------

U.TEMPLATE = "ufwol_convo_template"
U.HANDLER = "ufwolConvoHandler"
U.STF = "conversation/tatooine_rebel_tier4"
U.PREFIX = "@conversation/tatooine_rebel_tier4:"
U.JAVA = "script/conversation/tatooine_rebel_tier4.java"

U.TEMPLATE_FILE = "mobile/conversations/space/rebel/crimson_phoenix_squadron/ufwol_convo.lua"
U.HANDLER_FILE = "screenplays/space/conversations/rebel/crimson_phoenix_squadron/ufwolConvoHandler.lua"
U.NPC_FILE = "mobile/space/ufwol.lua"
U.SPAWN_FILE = "screenplays/cities/rori_rebel_outpost.lua"
U.SPACE_CONVERSATIONS = "mobile/conversations/space/space_conversations.lua"
U.SCREENPLAYS = "screenplays/space/screenplays.lua"
U.ULVAWOP_HANDLER_FILE = "screenplays/space/conversations/rebel/crimson_phoenix_squadron/ulvawopConvoHandler.lua"
U.SOCUNA_HANDLER_FILE = "screenplays/space/conversations/rebel/crimson_phoenix_squadron/socunaConvoHandler.lua"

U.TEMPLATE_INCLUDE = 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/ufwol_convo.lua")'
U.HANDLER_INCLUDE = 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/ufwolConvoHandler.lua")'

U.STANDING = 150
U.TRAIN_COST = 1000000
U.MASTER = "pilot_rebel_navy_master"
U.MET_SCREEN = "met_258d2f1e"
U.TIER3_M4_REWARD = "tatooine_rebel_tier3_4:reward" -- Ulvaw'op's mission 4 reward key (Q-B1 = A)

U.SCREENS = require("crimson_tier4_ufwol_screens_data")

function U.screenRow(rowId)
	for _, row in ipairs(U.SCREENS) do
		if row.id == rowId then
			return row
		end
	end
end

-- The Appendix A screen ids (136), sorted
function U.screenIds()
	local out = {}

	for i, row in ipairs(U.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- Content contract 2: MISSIONS (head, quest string, the "won" constants, status key name, screens, JF reward item, zone of the first quest)
U.MISSIONS = {}

local MISSION_ZONES = { DT, DT, EN, EN }

local MISSION_SCREENS = {
	{ failedReplies = { "m1_failed_b0933679", "m1_failed_afcb06fc" }, accepts = { "m1_accept_d68a9f0a" }, wins = { "TIER4_QUEST_STRING_1_SIDE1", "TIER4_QUEST_STRING_1_SIDE3" } },
	{ failedReplies = { "m2_failed_e2a4b15e", "m2_failed_18e57f03" }, accepts = { "m2_accept_9fcfe841" }, wins = { "TIER4_QUEST_STRING_2_SIDE1", "TIER4_QUEST_STRING_2_SIDE2" } },
	{ failedReplies = { "m3_failed_45ae8603", "m3_failed_f3bbd7e7" }, accepts = { "m3_accept_fed525e5" }, wins = { "TIER4_QUEST_STRING_3_SIDE1", "TIER4_QUEST_STRING_3_SIDE2" } },
	{ failedReplies = { "m4_failed_71854a18", "m4_failed_bbd20f83" }, accepts = { "m4_accept_cc7b5947" }, wins = { "TIER4_QUEST_STRING_4_SIDE1", "TIER4_QUEST_STRING_4_SIDE2" } },
}

for n = 1, 4 do
	U.MISSIONS[n] = {
		n = n, head = U.HEADS[n], questString = "TIER4_QUEST_STRING_" .. n, wins = MISSION_SCREENS[n].wins,
		standing = 150, status = U.STATUS[n], offer = "m" .. n .. "_offer", failed = "m" .. n .. "_failed", reward = "m" .. n .. "_reward",
		failedReplies = MISSION_SCREENS[n].failedReplies, accepts = MISSION_SCREENS[n].accepts, zone = MISSION_ZONES[n], item = U.ITEMS[n],
	}
end

-- Content contract 2: DUTY_SCREENS (screen -> global, quest string), in the reply order of the duty menus
U.DUTY_SCREENS = {
	duty_destroy = { global = U.DUTIES[1], questString = "TIER4_QUEST_STRING_DUTY_1" },
	duty_escort = { global = U.DUTIES[2], questString = "TIER4_QUEST_STRING_DUTY_2" },
	duty_recovery = { global = U.DUTIES[3], questString = "TIER4_QUEST_STRING_DUTY_3" },
	duty_rescue = { global = U.DUTIES[4], questString = "TIER4_QUEST_STRING_DUTY_4" },
}

U.DUTY_ORDER = { "duty_destroy", "duty_escort", "duty_recovery", "duty_rescue" }

-- the four duty replies of a menu, then "briefing again" (s_49805f81), and the links they carry
U.MENU_REPLIES = { "s_89951606", "s_91502216", "s_67ee2a0", "s_c1c9b365", "s_49805f81" }
U.MENU_LINKS = { "duty_destroy", "duty_escort", "duty_recovery", "duty_rescue", "duty_brief" }
U.MENUS = { "brief_6231dba", "tier4_incomplete", "here_for_work" }

-- Content contract 2: TRAIN_CHOICES in menu order. skl = the client skill name (skl_n) that maps the topic reply to the skill (finding 3); words = what the reply must say
U.TRAIN = {
	{ x = "starships", skill = "pilot_rebel_navy_starships_04", reply = "s_efdacfde", trained = "trained_starships", trainedSid = "s_7dae4367", skl = "Hyper-Maneuverable Starfighters", words = "hyper-maneuverable starfighters" },
	{ x = "weapons", skill = "pilot_rebel_navy_weapons_04", reply = "s_daa1d4f4", trained = "trained_weapons", trainedSid = "s_2eebfe4c", skl = "Equipment D: Heavy Alliance Starship Component Use", words = "heavy alliance component use" },
	{ x = "procedures", skill = "pilot_rebel_navy_procedures_04", reply = "s_270a2a57", trained = "trained_procedures", trainedSid = "s_7dae4367", skl = "Special Weapons and Tactics", words = "special weapons and tactics" },
	{ x = "droid", skill = "pilot_rebel_navy_droid_04", reply = "s_1e8289a2", trained = "trained_droid", trainedSid = "s_cee1914e", skl = "Droid Intelligence Theory", words = "droid intelligence theory" },
}

-- Content contract 2: START_SCREENS (8), screen -> mission
U.START_SCREENS = {
	m1_failed = 1, m1_accept_d68a9f0a = 1, m2_failed = 2, m2_accept_9fcfe841 = 2, m3_failed = 3, m3_accept_fed525e5 = 3, m4_failed = 4, m4_accept_cc7b5947 = 4,
}

-- Content contract 2: REWARD_SCREENS, screen -> mission
U.REWARD_SCREENS = { m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4 }

-- Content contract 2: TIER_SCREENS (raise the pilot tier only)
U.TIER_SCREENS = { "transfer", "here_for_work" }

-- Content contract 2: NAME_SCREENS (7), the screens whose line has a %TU or %NU token
U.NAME_SCREENS = { "m2_reward", "trained_starships", "trained_procedures", "m1_79e6aa32", "m2_c946f118", "m2_s239", "m3_accept_fed525e5" }

-- Data mapping 2: the 108 NGE editor numbers JF uses, each with its class (T twin, R rejoin, b reuse of a client reply, P pool line) and where it landed.
--   screen  the Appendix A screen that fills or follows the slot; npc = true: the screen fills an NGE NPC slot (it carries the slot's JF animation and end flag)
--   reply, link  the replacement reply (a client line) on `screen` and the screen it links to
--   like    the screen whose animation and end flag the NGE NPC line has in JF (the rejoined closing lines)
U.NGE_MAP = {}

local function nge(first, last, step, m)
	for i = first, last, step do
		local entry = {}

		for k, v in pairs(m) do
			entry[k] = v
		end

		U.NGE_MAP["s_" .. i] = entry
	end
end

-- a reply placement: the class, the screen, the client reply that replaces the NGE reply and the screen it leads to
local function place(class, screen, reply, link, extra)
	local m = { class = class, screen = screen, reply = reply, link = link }

	for k, v in pairs(extra or {}) do
		m[k] = v
	end

	return m
end

nge(4, 4, 1, { class = "T", screen = "wrong_faction", npc = true })
nge(37, 37, 1, place("R", "m1_reward", "s_f69a2921", "m1_reward_a871501f", { like = "m1_reward_a871501f" }))
nge(42, 42, 1, place("b", "m2_reward", "s_d0fd857b", "m3_reward_76e9b54b"))
nge(44, 44, 1, place("R", "m2_reward", "s_d0fd857b", "m3_reward_76e9b54b", { like = "m3_reward_76e9b54b" }))
nge(54, 54, 1, place("b", "m4_reward", "s_987445c9", "m4_reward_fb3d31a9"))
nge(90, 90, 1, place("b", "m4_offer", "s_987445c9", "m4_f60ad3e3"))
nge(95, 95, 1, place("b", "m4_2f190cf", "s_2c10011d", "m4_fb05125c"))
nge(100, 100, 1, place("b", "m4_2d4185b", "s_1131a10a", "m4_7aa5d0f7"))
nge(103, 121, 2, place("R", "m4_7aa5d0f7", "s_71a53f8b", "m4_ba8b09ff"))
nge(126, 126, 1, place("b", "m3_6dea357d", "s_5bb47d59", "m3_f3eda860"))
nge(149, 149, 1, place("b", "m3_e2aefddd", "s_5bb47d59", "m3_3a640dfa"))
nge(156, 156, 1, place("R", "m3_7f14ac3a", "s_63e0ab42", "m3_1eed1024"))
nge(158, 170, 2, place("R", "m3_7f14ac3a", "s_63e0ab42", "m3_1eed1024"))
nge(175, 175, 1, place("b", "m2_83b2f3f1", "s_5bb47d59", "m2_ea7b0fb2"))
nge(178, 178, 1, place("b", "m2_ea7b0fb2", "s_61657d0f", "m2_4ca48b38"))
nge(199, 199, 1, place("b", "m2_4c56b685", "s_bb9e4a63", "m2_s201"))
nge(201, 201, 1, { class = "T", screen = "m2_s201", npc = true })
nge(204, 224, 2, place("R", "m2_s201", "s_18d61e21", "m2_c946f118"))
nge(230, 230, 1, place("b", "m2_5e35901c", "s_8ddbf95b", "m2_d3234c01"))
nge(237, 237, 1, place("T", "m2_a582cadc", "s_5bb47d59", "m2_s239"))
nge(239, 239, 1, { class = "T", screen = "m2_s239", npc = true })
nge(241, 241, 1, place("T", "m2_s239", "s_790d22d6", "m2_s243"))
nge(243, 243, 1, { class = "T", screen = "m2_s243", npc = true })
nge(245, 245, 1, place("T", "m2_s243", "s_a33056f4", "m2_s247"))
nge(247, 247, 1, { class = "T", screen = "m2_s247", npc = true })
nge(249, 249, 1, place("T", "m2_s247", "s_d82b46ba", "m2_c5512cb2"))
nge(252, 252, 1, place("T", "m2_c5512cb2", "s_8e9d0848", "m2_92a98982"))
nge(254, 258, 2, place("R", "m2_c5512cb2", "s_8e9d0848", "m2_92a98982"))
nge(289, 319, 2, place("R", "m1_f3c74323", "s_9b43a7ee", "m1_5471712d"))
nge(321, 321, 1, place("b", "m1_offer", "s_b3e9c738", "m1_e9ad7c02"))
nge(323, 323, 1, { class = "P", screen = "m1_e9ad7c02", npc = true })
nge(331, 337, 2, place("R", "m1_a71cdd82", "s_8ddbf95b", "m1_f689a56f"))
nge(340, 340, 1, place("b", "intro", "s_9b43a7ee", "met_258d2f1e"))
nge(345, 345, 1, place("b", "met_36085c51", "s_bb9e4a63", "met_db77876d"))
nge(348, 348, 1, place("b", "met_db77876d", "s_d9cced1f", "met_917742b8"))
nge(353, 353, 1, place("b", "met_ab288b4d", "s_61657d0f", "brief_7e962bfb"))
nge(356, 356, 1, place("b", "brief_7e962bfb", "s_2c4789b", "brief_73c9f8b3"))
nge(359, 359, 1, place("b", "brief_73c9f8b3", "s_bc57b086", "brief_ac30ef3"))
nge(362, 362, 1, place("b", "brief_ac30ef3", "s_8ddbf95b", "brief_6231dba"))
nge(369, 369, 1, { class = "T", screen = "duty_escort", npc = true })
nge(372, 372, 1, { class = "T", screen = "duty_recovery", npc = true })
nge(375, 375, 1, { class = "T", screen = "duty_rescue", npc = true })
nge(379, 393, 2, place("R", "duty_brief", "s_61657d0f", "brief_7e962bfb"))
nge(411, 416, 1, { class = "P", screen = "training" })
nge(418, 422, 2, { class = "P", screen = "training" })
nge(423, 423, 1, { class = "P", screen = "trained_starships", npc = true })
nge(425, 425, 1, { class = "P", screen = "trained_weapons", npc = true })
nge(427, 427, 1, { class = "P", screen = "trained_procedures", npc = true })
nge(429, 429, 1, { class = "P", screen = "trained_droid", npc = true })

-- the screens that stand for an NGE NPC slot but do not carry the slot's id in NGE_MAP's npc entries: the second pool line of the M1 exchange (also unanimated, not ending)
U.EXTRA_SLOTS = { m1_7ba8daf7 = "s_323" }

-- Appendix D: one reply path (sids) per accept screen route, "s_" prefixed
local function sids(text)
	local out = {}

	for word in text:gmatch("%S+") do
		out[#out + 1] = "s_" .. word
	end

	return out
end

U.OFFER_PATHS = {
	{ mission = 1, accept = "m1_accept_d68a9f0a", replies = sids("5bc07030 221bd4ce 6c38055e 856aca7d 521e8b09 d9cced1f 43fcfbca 8ddbf95b c127c173 914a4095 61657d0f d55f2579") },
	{ mission = 1, accept = "m1_accept_d68a9f0a", replies = sids("5bc07030 221bd4ce 48b7214b 9b43a7ee 43fcfbca 8ddbf95b c127c173 914a4095 61657d0f d55f2579") },
	{ mission = 1, accept = "m1_accept_d68a9f0a", replies = sids("b3e9c738 c8fa77b8 2c4789b 314f0ae4 907e88bd 8ddbf95b d55f2579") },
	{ mission = 2, accept = "m2_accept_9fcfe841", replies = sids("d059f8aa 5bb47d59 61657d0f e816c4f3 5bb47d59 790d22d6 a33056f4 d82b46ba 8e9d0848 6425e854") },
	{ mission = 2, accept = "m2_accept_9fcfe841", replies = sids("24f29c02 958c1289 bb9e4a63 18d61e21 790d22d6 a33056f4 d82b46ba 8e9d0848 6425e854") },
	{ mission = 2, accept = "m2_accept_9fcfe841", replies = sids("24f29c02 9288900f 2acccb89 8ddbf95b 58a20c33 bb9e4a63 5bb47d59 790d22d6 a33056f4 d82b46ba 8e9d0848 6425e854") },
	{ mission = 3, accept = "m3_accept_fed525e5", replies = sids("c8a0830d 5bb47d59 2c10011d 89e27dc9 63e0ab42 8009422e bc57b086 e42b260e") },
	{ mission = 3, accept = "m3_accept_fed525e5", replies = sids("c01ad90e cbcd1643 f00c2726 68772323 5bb47d59 15bf89c7 719a036e 63e0ab42 8009422e bc57b086 e42b260e") },
	{ mission = 4, accept = "m4_accept_cc7b5947", replies = sids("87f091b9 742d8c68 b3e9c738 1131a10a 71a53f8b fa396956 32b5bee1 fbb318e5 fb9f7cd6") },
	{ mission = 4, accept = "m4_accept_cc7b5947", replies = sids("987445c9 85660b3d 2c10011d 9b43a7ee 1131a10a 71a53f8b fa396956 32b5bee1 fbb318e5 fb9f7cd6") },
}

-- The met walk of Appendix D: from `intro` to the duty menu
U.MET_WALK = sids("9b43a7ee 86137261 bb9e4a63 d9cced1f 6db5d6ce 61657d0f 2c4789b bc57b086 8ddbf95b")

-- The screens shown by following static links of Appendix A from `start` with the reply sids (nil when a reply is not on the screen)
function U.follow(start, replies)
	local ids, cur = { start }, start

	for _, reply in ipairs(replies) do
		local nextId

		for _, o in ipairs(U.screenRow(cur).options) do
			if o[1] == reply then
				nextId = o[2]
			end
		end

		if nextId == nil then
			return nil, ids
		end

		cur = nextId
		ids[#ids + 1] = cur
	end

	return ids
end

-- Breadth-first search over the static links of Appendix A from `start`: id -> { ids = {screen ids from start}, replies = {reply sids} }. `avoid` (set of ids) are never entered.
function U.reach(start, avoid)
	local found = { [start] = { ids = { start }, replies = {} } }
	local queue = { start }

	while #queue > 0 do
		local cur = found[table.remove(queue, 1)]

		for _, o in ipairs(U.screenRow(cur.ids[#cur.ids]).options) do
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

function U.walkTo(from, to, avoid)
	local hit = U.reach(from, avoid)[to]

	if hit == nil then
		return nil
	end

	return hit.replies, hit.ids
end

-- The JF fixture: rewardForMissionN bodies -> { type, name, credits, item, standing, guarded } by mission number (the oracle of AC-7, D-11)
function U.javaRewards()
	local f = assert(io.open(H.FIXTURES .. U.JAVA, "r"), "cannot open the JF fixture")
	local java = f:read("a")

	f:close()

	local out = {}
	local words = { One = 1, Two = 2, Three = 3, Four = 4 }

	for word, body in java:gmatch("tatooine_rebel_tier4_action_rewardForMission(%a+)%(obj_id player, obj_id npc%) throws InterruptedException%s*(%b{})") do
		local questType, questName, credits, item = body:match('giveReward%(player, "([^"]+)", "([^"]+)", (%d+), "([^"]+)"%)')
		local standing = body:match("addFactionStanding%(player, factions%.FACTION_REBEL, ([%d%.]+)f%)")
		local guard = body:match('!space_quest%.hasReceivedReward%(player, "([^"]+)", "([^"]+)"%)')

		if words[word] ~= nil then
			out[words[word]] = { type = questType, name = questName, credits = tonumber(credits), item = item, standing = tonumber(standing), guarded = guard ~= nil }
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		C.loadErrors[#C.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

local loadedB = false

-- The server's load of Ufwol's template and handler (after the squadron files). A missing production file is recorded in the load problems, not raised.
function U.loadConversation()
	U.load()

	if loadedB then
		return
	end

	loadedB = true
	try("ufwol_convo.lua", function() H.loadMobile("conversations/space/rebel/crimson_phoenix_squadron/ufwol_convo.lua") end)
	try("ufwolConvoHandler.lua", function() H.loadScreenplay("space/conversations/rebel/crimson_phoenix_squadron/ufwolConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded (a readable red phase)
function U.requireConversation(lu)
	U.loadConversation()
	lu.assertNotNil(H.conversationTemplateTable(U.TEMPLATE), U.TEMPLATE .. " is not registered by addConversationTemplate (expected " .. U.TEMPLATE_FILE .. ", crimson-phoenix-tier4-ufwol). Load problems: " .. U.problems())
	lu.assertNotNil(rawget(_G, U.HANDLER), U.HANDLER .. " is not defined (expected " .. U.HANDLER_FILE .. ", crimson-phoenix-tier4-ufwol). Load problems: " .. U.problems())
end

function U.handler()
	U.loadConversation()

	return H.expectGlobal(U.HANDLER, "Ufwol's conversation handler (crimson-phoenix-tier4-ufwol). Load problems: " .. U.problems())
end

-- General Ufwol in the Rori Rebel outpost tavern (screenplays/cities/rori_rebel_outpost.lua:49)
function U.npc() return H.newNpc({ name = "General Ufwol", zone = "rori", x = -8.4, z = 0.6, y = 3.5, parentID = 4505635 }) end

local function requireLoaded()
	U.loadConversation()

	if H.conversationTemplateTable(U.TEMPLATE) == nil or rawget(_G, U.HANDLER) == nil then
		error("Ufwol's conversation is not loaded (crimson-phoenix-tier4-ufwol). Load problems: " .. U.problems(), 3)
	end
end

-- Talks to Ufwol from the first screen. choices as for H.converse (0-based indexes, option sids, hooks).
function U.talk(player, choices)
	requireLoaded()

	return H.converse({ template = U.TEMPLATE, player = player, npc = U.npc(), choices = choices })
end

function U.firstScreen(player) return U.talk(player)[1].id end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or hooks).
-- Reaches screens no first screen leads to; runScreenHandlers runs for every screen shown, the way the real session does.
function U.drive(player, startId, choices)
	requireLoaded()

	local tmpl = H.conversationTemplate(U.TEMPLATE)
	local handler = rawget(_G, U.HANDLER)
	local npc = U.npc()
	local session = H.Fakes.newConversationSession(npc)
	local transcript = {}

	player.conversationSession = session

	local function show(screen)
		local options = {}

		for i, o in ipairs(screen.options) do
			options[i] = { text = o.text, link = o.link }
		end

		transcript[#transcript + 1] = { id = screen.id, text = screen.dialogText, options = options, params = screen.params, stop = screen.stopConversation }
	end

	local screen = LuaConversationTemplate(tmpl):getScreen(startId)

	if screen == nil then
		error("screen '" .. startId .. "' is not in " .. U.TEMPLATE, 2)
	end

	screen = handler:runScreenHandlers(tmpl, player, npc, 0, screen)

	if screen == nil then
		error("runScreenHandlers returned no screen for '" .. startId .. "'", 2)
	end

	session.lastScreen = screen
	show(screen)

	local i = 1

	while i <= #(choices or {}) and not screen.stopConversation do
		local choice = choices[i]

		i = i + 1

		if type(choice) == "function" then
			choice(player)
		else
			if type(choice) == "string" then
				local found

				for k, o in ipairs(screen.options) do
					if o.text == choice or o.text:sub(-#choice - 1) == ":" .. choice then
						found = k - 1
						break
					end
				end

				if found == nil then
					local have = {}

					for k, o in ipairs(screen.options) do
						have[k] = tostring(o.text)
					end

					error("screen '" .. screen.id .. "' has no option '" .. choice .. "'; options are: " .. table.concat(have, ", "), 2)
				end

				choice = found
			end

			screen = handler:getNextConversationScreen(tmpl, player, choice, npc)

			if screen ~= nil then
				screen = handler:runScreenHandlers(tmpl, player, npc, choice, screen)
			end

			session.lastScreen = screen

			if screen == nil then
				break
			end

			show(screen)
		end
	end

	return transcript
end

U.ids = C.ids
U.optionSids = C.optionSids
U.linksOf = C.linksOf

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local pilotPartA = U.pilot

-- how each mission state of U.pilot's `mission` option reads in the journal: which chain members (index into U.CHAINS[n]) are complete and which one is active.
-- The head is chain[1], the success child chain[2], the failure child chain[3], mission 1's surprise attack chain[4]. A failed quest is not complete and not active.
local MISSION_STATES = {
	won_a = { complete = { 1, 2 } },
	won_b = { complete = { 3 } }, -- mission 2-4: the failure child is complete; mission 1: the patrol is complete (not won: only its surprise attack, 1_c, wins)
	won_c = { complete = { 3, 4 } },
	failed_c = { complete = { 3 } },
	b_complete_c_active = { complete = { 3 }, active = 4 },
	failed_head = {},
	aborted = {},
	failed_a = { complete = { 1 } },
	failed_b = {},
	a_active = { complete = { 1 }, active = 2 },
	b_active = { active = 3 },
	active = { active = 1 },
	attempted = {},
}

U.MISSION_STATES = MISSION_STATES

-- A Crimson Phoenix pilot of tier 3 or 4. The Part A options (ufwol, ufwolKeys, met, ufwolActive, duty, missions, t3) stay as they were; the Part B options:
--   flag          EKER_PILOT_KEY value (alias of the earlier `graduated`; false leaves it unset; default "3")
--   ulvawopM4Paid false: Ulvaw'op's mission 4 is not paid (missions = 3 unless given)
--   t3            number of _03 skills held (default 4), or a list of U.TRAIN indexes
--   t4            list of U.TRAIN indexes of the _04 skills held
--   master        the master skill is held
--   mission       { [n] = state } for Ufwol's mission n, a key of U.MISSION_STATES: "won_a" (head and success child complete) | "won_b" (the failure child complete; mission 1: the
--                 patrol only) | "won_c" (mission 1: patrol and surprise attack complete) | "failed_c" (mission 1: patrol complete, surprise attack failed) |
--                 "b_complete_c_active" | "failed_head" | "aborted" | "failed_a" | "failed_b" | "active" | "a_active" | "b_active" | "attempted". Every state sets :attempted
--   paid          list of n: mission n won (every member complete), :attempted and :reward set
--   squadron      "crimson" (default) | "vortex" | "havoc" | "none" | a squadron constant | true | false
--   otherQuest    "story" | "duty": a space mission of another trainer in the datapad (alias of `datapad`)
--   pilotTier     ghost pilot tier (default 4 with four _03 skills, 3 with fewer, 5 with four _04 skills)
--   xp, standing, faction, pilot, species, inventory, inShip, zone, t1, t2, ekerMissions: as T.pilot / E.pilot / C.pilot
function U.pilot(o)
	o = o or {}

	local base = {}

	for k, v in pairs(o) do
		base[k] = v
	end

	base.flag, base.ulvawopM4Paid, base.t4, base.master, base.mission, base.paid, base.otherQuest = nil, nil, nil, nil, nil, nil, nil

	if o.flag ~= nil then
		base.graduated = o.flag
	end

	if o.ulvawopM4Paid == false and o.missions == nil then
		base.missions = 3
	end

	if o.squadron == "crimson" then
		base.squadron = nil
	elseif o.squadron == "vortex" then
		base.squadron = VORTEX_SQUADRON
	elseif o.squadron == "havoc" then
		base.squadron = HAVOC_SQUADRON
	elseif o.squadron == "none" then
		base.squadron = false
	end

	if o.otherQuest then
		base.datapad = o.otherQuest
	end

	base.skills = {}

	for _, skill in ipairs(o.skills or {}) do
		base.skills[#base.skills + 1] = skill
	end

	for _, i in ipairs(o.t4 or {}) do
		base.skills[#base.skills + 1] = U.TRAIN[i].skill
	end

	if o.master then
		base.skills[#base.skills + 1] = U.MASTER
	end

	base.pilotTier = o.pilotTier or ((#(o.t4 or {}) >= 4) and 5 or nil)

	local player = pilotPartA(base)
	local states = {}

	for _, n in ipairs(o.paid or {}) do
		states[n] = "paid"
	end

	for n, state in pairs(o.mission or {}) do
		states[n] = state
	end

	for n, state in pairs(states) do
		local chain = U.CHAINS[n]

		H.setQuestStatus(player, U.STATUS[n] .. ":attempted", "1")

		if state == "paid" then
			H.setQuestStatus(player, U.STATUS[n] .. ":reward", "1")

			for _, global in ipairs(chain) do
				U.setState(player, global, "complete")
			end
		else
			local spec = MISSION_STATES[state]

			if spec == nil then
				error("U.pilot: unknown mission state '" .. tostring(state) .. "'", 2)
			end

			for _, i in ipairs(spec.complete or {}) do
				U.setState(player, chain[i], "complete")
			end

			if spec.active then
				U.setState(player, chain[spec.active], "active")
			end
		end
	end

	return player
end

-- A pilot who is not a pilot at all (no pilot skill, no squadron, no state)
function U.nonPilot(extra)
	local o = { pilot = false, squadron = "none", t1 = 0, t2 = 0, t3 = {}, missions = 0, ekerMissions = 0, flag = false }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return U.pilot(o)
end

-- the pilot of the training menu / offers: the first meeting heard, `have` the _04 skills held (U.TRAIN indexes), their missions won and paid, `xp` experience
function U.trainee(have, xp, extra)
	local paid = {}

	for i = 1, #have do
		paid[i] = i
	end

	local o = { t4 = have, paid = paid, xp = xp or U.TRAIN_COST, met = true }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return U.pilot(o)
end

-- "mission n is won (through child `via`, default won_a) and unpaid, missions 1..n-1 paid, n skills held, the first meeting heard": the pilot a reward screen opens for
function U.rewardPilot(n, via, extra)
	local t4, paid = {}, {}

	for i = 1, math.min(n, 4) do
		t4[i] = i
	end

	for i = 1, n - 1 do
		paid[i] = i
	end

	local o = { t4 = t4, paid = paid, met = true, mission = { [n] = via or "won_a" } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return U.pilot(o)
end

-- "missions 1..n-1 paid, n skills held, the first meeting heard": the pilot mission n is offered to
function U.offerPilot(n, extra)
	local t4, paid = {}, {}

	for i = 1, n do
		t4[i] = i
	end

	for i = 1, n - 1 do
		paid[i] = i
	end

	local o = { t4 = t4, paid = paid, met = true }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return U.pilot(o)
end

-- the graduate: four _04 skills, four missions paid, the first meeting heard, pilot tier 5
function U.graduate(extra)
	local o = { t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, met = true }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return U.pilot(o)
end

---------------------------------------------------------------------------------------------
-- Observation
---------------------------------------------------------------------------------------------

function U.attempted(player, n) return H.getQuestStatus(player, U.STATUS[n] .. ":attempted") end

function U.paid(player, n) return H.getQuestStatus(player, U.STATUS[n] .. ":reward") end

function U.hasMet(player) return H.getQuestStatus(player, U.MET_KEY) == "1" end

-- the Rebel standing of the pilot
function U.standing(player) return player.ghost.factionStanding.rebel or 0 end

-- The EKER_PILOT_KEY value of the pilot ("1", "2", "3") or nil
function U.flag(player) return H.getQuestStatus(player, U.EKER_PILOT_KEY) end

function U.exp(player) return player.ghost.experience.space_combat_general end

-- giveItem templates received by the pilot, in order
function U.items(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory then
			out[#out + 1] = call[2]
		end
	end

	return out
end

-- the _04 skills (of the four) the pilot holds, in U.TRAIN order
function U.held4(player)
	local out = {}

	for _, t in ipairs(U.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

-- Registers the 17 quest tables (the way the runtime tests do) so a real startQuest can run
function U.startAll()
	for _, global in ipairs(U.GLOBALS) do
		U.quest(global):start()
	end
end

-- Spies the startQuest of the four duty globals (H.spyOn does not call the original); returns { global -> calls }
function U.spyDuties()
	local spies = {}

	for _, global in ipairs(U.DUTIES) do
		spies[global] = H.spyOn(U.quest(global), "startQuest")
	end

	return spies
end

-- "global xN" strings of the spied duties that started, in U.DUTIES order
function U.startedDuties(spies)
	local out = {}

	for _, global in ipairs(U.DUTIES) do
		if spies[global] ~= nil and #spies[global] > 0 then
			out[#out + 1] = global .. " x" .. #spies[global]
		end
	end

	return out
end

local restoreFns = {}

-- Records the calls of SpaceHelpers:grantSpaceSkill ({ skill, deduct }) and runs the original. Call U.restore() in tearDown.
function U.recordGrants()
	local calls = {}
	local orig = SpaceHelpers.grantSpaceSkill

	SpaceHelpers.grantSpaceSkill = function(self, pPlayer, skill, deduct)
		calls[#calls + 1] = { skill = skill, deduct = deduct }

		return orig(self, pPlayer, skill, deduct)
	end

	restoreFns[#restoreFns + 1] = function() SpaceHelpers.grantSpaceSkill = orig end

	return calls
end

-- Records the calls of SpaceHelpers:startSpaceQuestChain (head global names) and runs the original. Call U.restore() in tearDown.
function U.recordChainStarts()
	local calls = {}
	local orig = SpaceHelpers.startSpaceQuestChain

	SpaceHelpers.startSpaceQuestChain = function(self, pPlayer, pNpc, headGlobal)
		calls[#calls + 1] = headGlobal

		return orig(self, pPlayer, pNpc, headGlobal)
	end

	restoreFns[#restoreFns + 1] = function() SpaceHelpers.startSpaceQuestChain = orig end

	return calls
end

-- Replaces SpaceHelpers:startSpaceQuestChain by a recorder that does not start anything (the head names called)
function U.stubChainStarts()
	local calls = {}
	local orig = SpaceHelpers.startSpaceQuestChain

	SpaceHelpers.startSpaceQuestChain = function(self, pPlayer, pNpc, headGlobal)
		calls[#calls + 1] = headGlobal
	end

	restoreFns[#restoreFns + 1] = function() SpaceHelpers.startSpaceQuestChain = orig end

	return calls
end

-- undoes the recorders and stubs in reverse order (a recorder installed twice restores the original, not the first recorder)
function U.restore()
	for i = #restoreFns, 1, -1 do
		restoreFns[i]()
	end

	restoreFns = {}
end

-- Charges the XP of the _04 skills from the fixture (1,000,000 each); without it the fake charges nothing
function U.useSkillCosts()
	local costs = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_rebel_navy_04.tab").records) do
		local name = rec:get("NAME")

		if name ~= nil and name:match("^pilot_rebel_navy_%a+_04$") then
			costs[name] = rec:num("XP_COST")
		end
	end

	H.Engine.config.skillXpCosts = costs

	return costs
end

-- The shape of a pilot's state a gate must not change (I-3): status keys, flag, met key, journal, skills, XP, pilot tier, standing, credits, inventory, engine calls
function U.snapshot(player)
	local ghost = player.ghost

	local function copy(t)
		local c = {}

		for k, v in pairs(t or {}) do
			c[k] = v
		end

		return c
	end

	return {
		keys = H.Engine.sharedMemoryKeys(), status = copy(H.Fakes.questStatus), flag = U.flag(player), met = U.hasMet(player),
		journalActive = ghost and copy(ghost.journalActive) or nil, journalComplete = ghost and copy(ghost.journalComplete) or nil,
		skills = copy(player.skills), xp = ghost and U.exp(player) or nil, pilotTier = ghost and ghost.pilotTier or nil,
		standing = ghost and U.standing(player) or nil, credits = player.bankCredits,
		inventory = #(player.inventory and player.inventory.items or {}), engineCalls = #H.Engine.calls,
	}
end

return U
