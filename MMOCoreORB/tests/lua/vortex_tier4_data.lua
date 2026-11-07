-- Shared test data and builders for Vortex Squadron tier 4, Part A (Brother Extok Evin's missions), not a test file.
-- Spec: .claude/work/vortex-tier4-extok-evin/01-spec.md (Content contract, Data mapping, Appendix B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of agreeing with itself
-- (test_vortex_tier4_missions_data.lua proves the literals equal the SWG .tab fixtures):
--   E.GLOBALS / E.IDENTITY     the 17 quest globals and their class, type, name and zone (Content contract 1)
--   E.M1 .. E.M4 / E.CHAINS    the four missions, members in getSpaceQuestChain order (head, success branch, failure branch)
--   E.BRANCHES                 per mission: head, the success child, the failure child (and the failure child's own split)
--   E.DUTIES / E.HEADS / E.CHILDREN
--   E.QUEST_STRINGS            the 17 TIER4_* constants of VortexSquadronScreenplay (Content contract 2)
--   E.MET_KEY / E.statusKeys() the met key and the 9 keys the reset removes (the ":attempted" / ":reward" of the four heads and the met key)
--   E.POINTS                   Data mapping 2: the 57 nav points, per zone, Core3 x, z, y
--   E.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   E.REWARDS                  Source inventory 3 (D-6): credits and one item per head
--   E.load() / E.quest / E.squadron   the server's load (vortex_tier1_data.lua's); a missing production file is recorded, not raised
--   E.flyer(zone)              a Rebel pilot in a Rebel ship in `zone`, for the runtime tests
--   E.pilot{...}               a Vortex graduate of tier 3 with optional tier 4 journal state and keys (see the option list at E.pilot)
-- Part B (the conversation) extends this file below the "Part B" marker.

local H = require("harness")
local V1 = require("vortex_tier1_data")
local V2 = require("vortex_tier2_data")
local W = require("vortex_tier3_data")

local E = {}

E.SQUADRON_FILE = V1.SQUADRON_FILE
E.SHIP_DIR = "ship_mobile/ships/"

local DA, EN, DT, YV = "space_dantooine", "space_endor", "space_dathomir", "space_yavin4"

E.M1 = { "survival_naboo_rebel_tier4_1", "assassinate_naboo_rebel_tier4_1_a", "escort_naboo_rebel_tier4_1_b" }
E.M2 = {
	"assassinate_naboo_rebel_tier4_2", "space_battle_naboo_rebel_tier4_2_a", "destroy_surpriseattack_naboo_rebel_tier4_2_b", "assassinate_naboo_rebel_tier4_2_c",
}
E.M3 = { "rescue_naboo_rebel_tier4_3", "assassinate_naboo_rebel_tier4_3_a", "delivery_no_pickup_naboo_rebel_tier4_3_b" }
E.M4 = { "space_battle_naboo_rebel_tier4_4", "space_battle_naboo_rebel_tier4_4_a", "survival_naboo_rebel_tier4_4_b" }

E.CHAINS = { E.M1, E.M2, E.M3, E.M4 }

E.DUTIES = {
	"destroy_duty_naboo_rebel_tier4_1", "escort_duty_naboo_rebel_tier4_1", "recovery_duty_naboo_rebel_tier4_1", "rescue_duty_naboo_rebel_tier4_1",
}

-- the 17 globals in Content contract 1 order
E.GLOBALS = {}

for _, chain in ipairs(E.CHAINS) do
	for _, g in ipairs(chain) do
		E.GLOBALS[#E.GLOBALS + 1] = g
	end
end

for _, g in ipairs(E.DUTIES) do
	E.GLOBALS[#E.GLOBALS + 1] = g
end

E.HEADS = { E.M1[1], E.M2[1], E.M3[1], E.M4[1] }

-- per mission: success child, failure child, and the child the failure child splits to (mission 2 only)
E.BRANCHES = {
	{ head = E.M1[1], success = E.M1[2], failure = E.M1[3] },
	{ head = E.M2[1], success = E.M2[2], failure = E.M2[3], failureNext = E.M2[4] },
	{ head = E.M3[1], success = E.M3[2], failure = E.M3[3] },
	{ head = E.M4[1], success = E.M4[2], failure = E.M4[3] },
}

E.CHILDREN = {}

for _, chain in ipairs(E.CHAINS) do
	for i = 2, #chain do
		E.CHILDREN[#E.CHILDREN + 1] = chain[i]
	end
end

-- the 37 earlier globals (tiers 1-3), which the 17 follow in the registration order
E.TIER3_GLOBALS = {}

for _, g in ipairs(W.EARLIER_GLOBALS) do
	E.TIER3_GLOBALS[#E.TIER3_GLOBALS + 1] = g
end

for _, g in ipairs(W.GLOBALS) do
	E.TIER3_GLOBALS[#E.TIER3_GLOBALS + 1] = g
end

-- Content contract 1
E.IDENTITY = {}

local function id(global, class, type_, name, zone) E.IDENTITY[global] = { class = class, type = type_, name = name, zone = zone } end

id(E.M1[1], "SpaceSurvivalScreenplay", "survival", "naboo_rebel_tier4_1", EN)
id(E.M1[2], "SpaceAssassinateScreenplay", "assassinate", "naboo_rebel_tier4_1_a", EN)
id(E.M1[3], "SpaceEscortScreenplay", "escort", "naboo_rebel_tier4_1_b", EN)
id(E.M2[1], "SpaceAssassinateScreenplay", "assassinate", "naboo_rebel_tier4_2", YV)
id(E.M2[2], "SpaceBattleScreenplay", "space_battle", "naboo_rebel_tier4_2_a", YV)
id(E.M2[3], "SpaceSurpriseAttackScreenplay", "destroy_surpriseattack", "naboo_rebel_tier4_2_b", YV)
id(E.M2[4], "SpaceAssassinateScreenplay", "assassinate", "naboo_rebel_tier4_2_c", DT)
id(E.M3[1], "SpaceRescueScreenplay", "rescue", "naboo_rebel_tier4_3", DT)
id(E.M3[2], "SpaceAssassinateScreenplay", "assassinate", "naboo_rebel_tier4_3_a", DT)
id(E.M3[3], "SpaceDeliveryNoPickupScreenplay", "delivery_no_pickup", "naboo_rebel_tier4_3_b", DT)
id(E.M4[1], "SpaceBattleScreenplay", "space_battle", "naboo_rebel_tier4_4", DT)
id(E.M4[2], "SpaceBattleScreenplay", "space_battle", "naboo_rebel_tier4_4_a", DT)
id(E.M4[3], "SpaceSurvivalScreenplay", "survival", "naboo_rebel_tier4_4_b", DT)
id(E.DUTIES[1], "SpaceDutyDestroyScreenplay", "destroy_duty", "naboo_rebel_tier4_1", DA)
id(E.DUTIES[2], "SpaceDutyEscortScreenplay", "escort_duty", "naboo_rebel_tier4_1", YV)
id(E.DUTIES[3], "SpaceDutyRecoveryScreenplay", "recovery_duty", "naboo_rebel_tier4_1", EN)
id(E.DUTIES[4], "SpaceDutyRescueScreenplay", "rescue_duty", "naboo_rebel_tier4_1", DA)

-- Content contract 2 (SIDE1 = the success split, SIDE2 = the failure split, SIDE3 = the failure split's own split)
E.QUEST_STRINGS = {
	TIER4_QUEST_STRING_1 = { type = "survival", name = "naboo_rebel_tier4_1" },
	TIER4_QUEST_STRING_1_SIDE1 = { type = "assassinate", name = "naboo_rebel_tier4_1_a" },
	TIER4_QUEST_STRING_1_SIDE2 = { type = "escort", name = "naboo_rebel_tier4_1_b" },
	TIER4_QUEST_STRING_2 = { type = "assassinate", name = "naboo_rebel_tier4_2" },
	TIER4_QUEST_STRING_2_SIDE1 = { type = "space_battle", name = "naboo_rebel_tier4_2_a" },
	TIER4_QUEST_STRING_2_SIDE2 = { type = "destroy_surpriseattack", name = "naboo_rebel_tier4_2_b" },
	TIER4_QUEST_STRING_2_SIDE3 = { type = "assassinate", name = "naboo_rebel_tier4_2_c" },
	TIER4_QUEST_STRING_3 = { type = "rescue", name = "naboo_rebel_tier4_3" },
	TIER4_QUEST_STRING_3_SIDE1 = { type = "assassinate", name = "naboo_rebel_tier4_3_a" },
	TIER4_QUEST_STRING_3_SIDE2 = { type = "delivery_no_pickup", name = "naboo_rebel_tier4_3_b" },
	TIER4_QUEST_STRING_4 = { type = "space_battle", name = "naboo_rebel_tier4_4" },
	TIER4_QUEST_STRING_4_SIDE1 = { type = "space_battle", name = "naboo_rebel_tier4_4_a" },
	TIER4_QUEST_STRING_4_SIDE2 = { type = "survival", name = "naboo_rebel_tier4_4_b" },
	TIER4_QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "naboo_rebel_tier4_1" },
	TIER4_QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "naboo_rebel_tier4_1" },
	TIER4_QUEST_STRING_DUTY_3 = { type = "recovery_duty", name = "naboo_rebel_tier4_1" },
	TIER4_QUEST_STRING_DUTY_4 = { type = "rescue_duty", name = "naboo_rebel_tier4_1" },
}

-- the constants in contract order (= E.GLOBALS order)
E.QUEST_STRING_FIELDS = {
	"TIER4_QUEST_STRING_1", "TIER4_QUEST_STRING_1_SIDE1", "TIER4_QUEST_STRING_1_SIDE2",
	"TIER4_QUEST_STRING_2", "TIER4_QUEST_STRING_2_SIDE1", "TIER4_QUEST_STRING_2_SIDE2", "TIER4_QUEST_STRING_2_SIDE3",
	"TIER4_QUEST_STRING_3", "TIER4_QUEST_STRING_3_SIDE1", "TIER4_QUEST_STRING_3_SIDE2",
	"TIER4_QUEST_STRING_4", "TIER4_QUEST_STRING_4_SIDE1", "TIER4_QUEST_STRING_4_SIDE2",
	"TIER4_QUEST_STRING_DUTY_1", "TIER4_QUEST_STRING_DUTY_2", "TIER4_QUEST_STRING_DUTY_3", "TIER4_QUEST_STRING_DUTY_4",
}

-- set by Part B's first-meeting reply, cleared by resetEvinQuests (Content contract 2)
E.MET_KEY = "VortexSquadronScreenplay:metTier4"
E.VORTEX_PILOT_KEY = V1.VORTEX_PILOT_KEY

-- Status keys (set by Part B's handler): <name>:attempted and <name>:reward for the four mission heads
E.STATUS = { "naboo_rebel_tier4_1", "naboo_rebel_tier4_2", "naboo_rebel_tier4_3", "naboo_rebel_tier4_4" }

-- the 9 keys (suffixes after the player id) the reset removes: 8 head keys and the met key. `player` is accepted and ignored (the keys are suffixes).
function E.statusKeys(_)
	local out = {}

	for _, name in ipairs(E.STATUS) do
		out[#out + 1] = name .. ":attempted"
		out[#out + 1] = name .. ":reward"
	end

	out[#out + 1] = E.MET_KEY

	return out
end

-- Data mapping 2: zone -> name -> { x, z, y } (Core3 x, z, y = buildout PX, PY, PZ truncated toward zero)
E.POINTS = {
	space_endor = {
		naboo_rebel_tier4_1_survival = { -4407, 1109, -1180 },
		naboo_rebel_tier4_1_a_assassin_1 = { -4168, 520, -2148 },
		naboo_rebel_tier4_1_a_assassin_2 = { -4981, 745, -1652 },
		naboo_rebel_tier4_1_a_assassin_3 = { -5612, 919, -1266 },
		naboo_rebel_tier4_1_a_assassin_4 = { -6259, 1098, -871 },
		naboo_rebel_tier4_1_a_assassin_5 = { -7155, 1345, -324 },
		naboo_rebel_tier4_1_a_assassin_6 = { -7584, 1596, 263 },
		naboo_rebel_tier4_1_b_escort_1 = { -2189, 336, -2467 },
		naboo_rebel_tier4_1_b_escort_2 = { -1044, 316, -2733 },
		naboo_rebel_tier4_1_b_escort_3 = { -132, 297, -2943 },
		naboo_rebel_tier4_1_b_escort_4 = { 1357, 265, -3286 },
		naboo_rebel_tier4_1_recovery_1 = { -242, 237, -2454 },
		naboo_rebel_tier4_1_recovery_2 = { -222, 392, -3760 },
		naboo_rebel_tier4_1_recovery_3 = { -160, 535, -5022 },
		naboo_rebel_tier4_1_recovery_4 = { -112, 608, -5705 },
		naboo_rebel_tier4_1_recovery_5 = { -1362, 677, -6811 },
		naboo_rebel_tier4_1_recovery_6 = { -3357, 757, -7033 },
		naboo_rebel_tier4_1_recovery_7 = { -813, 568, -5794 },
		naboo_rebel_tier4_1_recovery_8 = { -1677, 471, -4636 },
		naboo_rebel_tier4_1_recovery_9 = { -2068, 365, -3800 },
		naboo_rebel_tier4_1_recovery_10 = { -3517, 274, -2248 },
	},
	space_yavin4 = {
		naboo_rebel_tier4_2_assassin_1 = { 3918, 4348, -3225 },
		naboo_rebel_tier4_2_assassin_2 = { 2563, 4412, -3307 },
		naboo_rebel_tier4_2_assassin_3 = { 1131, 4477, -2086 },
		naboo_rebel_tier4_2_assassin_4 = { -48, 4539, -344 },
		naboo_rebel_tier4_2_assassin_5 = { -1519, 4604, 2034 },
		naboo_rebel_tier4_2_assassin_6 = { -6830, 4677, 3510 },
		naboo_rebel_tier4_2_a_battle_point = { 2234, 4412, -2915 },
		naboo_rebel_tier4_1_escort_duty_1 = { 2096, 3236, -6065 },
		naboo_rebel_tier4_1_escort_duty_2 = { 2494, 3767, -5614 },
		naboo_rebel_tier4_1_escort_duty_3 = { 3491, 4797, -4904 },
		naboo_rebel_tier4_1_escort_duty_4 = { 4619, 5351, -4806 },
		naboo_rebel_tier4_1_escort_duty_5 = { 5626, 6460, -4707 },
	},
	space_dathomir = {
		naboo_rebel_tier4_2_c_assassin_1 = { 5935, -4229, 6447 },
		naboo_rebel_tier4_2_c_assassin_2 = { 4649, -3485, 5120 },
		naboo_rebel_tier4_2_c_assassin_3 = { 3833, -3015, 4226 },
		naboo_rebel_tier4_2_c_assassin_4 = { 1810, -1822, 2258 },
		naboo_rebel_tier4_2_c_assassin_5 = { 834, -1249, 1313 },
		naboo_rebel_tier4_3_rescue_1 = { -3747, 6334, 4875 },
		naboo_rebel_tier4_3_rescue_2 = { -2601, 4856, 4692 },
		naboo_rebel_tier4_3_rescue_3 = { -2093, 4201, 4610 },
		naboo_rebel_tier4_3_rescue_4 = { -636, 2507, 4629 },
		naboo_rebel_tier4_3_a_assassin_1 = { 1567, -1644, 1303 },
		naboo_rebel_tier4_3_a_assassin_2 = { 870, -374, 2393 },
		naboo_rebel_tier4_3_a_assassin_3 = { 506, 287, 2962 },
		naboo_rebel_tier4_3_a_assassin_4 = { 130, 975, 3552 },
		naboo_rebel_tier4_3_a_assassin_5 = { -433, 2277, 4639 },
		naboo_rebel_tier4_3_b_delivery = { -1832, -709, -4430 },
		naboo_rebel_tier4_4_battle_point = { 6902, 3546, -3489 },
		naboo_rebel_tier4_4_a_battle_point = { 5171, 2634, -6196 },
		naboo_rebel_tier4_4_b_survival = { 2743, 6727, -6701 },
	},
	space_dantooine = {
		naboo_rebel_tier4_1_rescue_duty_1 = { 2685, 6536, -6727 },
		naboo_rebel_tier4_1_rescue_duty_2 = { 2490, 5986, -6356 },
		naboo_rebel_tier4_1_rescue_duty_3 = { 2160, 5246, -5746 },
		naboo_rebel_tier4_1_rescue_duty_4 = { 1936, 4693, -5265 },
		naboo_rebel_tier4_1_rescue_duty_5 = { 1513, 3657, -4302 },
		naboo_rebel_tier3_rescue_3 = { -996, -2105, 4791 },
	},
}

E.ITEM_ROOT = "object/tangible/ship/components/"
E.CREDITS = 10000

-- Source inventory 3 (J4:358-389), D-6: one item per head
E.ITEMS = {
	"shield_generator/shd_mission_reward_rebel_taim_military_grade.iff",
	"droid_interface/ddi_mission_reward_rebel_novaldex_low_latency.iff",
	"booster/bst_mission_reward_rebel_qualdex_halcyon.iff",
	"weapon/wpn_mission_reward_rebel_incom_tricannon.iff",
}

E.REWARDS = {}

for n, head in ipairs(E.HEADS) do
	E.REWARDS[head] = { credits = E.CREDITS, item = E.ITEM_ROOT .. E.ITEMS[n] }
end

-- Data mapping 1: battle forwards (excerpt fltKX, fltKY, fltKZ -> x, z, y)
E.FORWARD_2A = { x = 0.742974, z = 0.623137, y = -0.244313 }
E.FORWARD_4 = { x = 0.828605, z = -0.453660, y = -0.328033 }
E.FORWARD_4A = { x = -0.212466, z = -0.977154, y = 0.005260 }

E.DROID_MOBILE = "object/mobile/shared_ig_assassin_droid.iff"

-- FE-8: the 26 distinct ships
E.SHIPS = {
	"freighterheavy_tier4", "freighterlight_tier4", "freightermedium_tier4", "imp_tie_advanced_tier4", "imp_tie_aggressor_tier4", "imp_tie_bomber_tier4",
	"imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_oppressor_tier4", "lambdashuttle_inquisition_data_vessel", "reb_awing_tier4", "reb_bwing_tier4",
	"reb_freighterheavy_tier4", "reb_freighterlight_tier4", "reb_freightermedium_tier4", "reb_transport_tier4", "reb_xwing_tier4", "reb_ykl37r_tier4",
	"rebel_smuggler_tier3", "tie_vortex_spy", "tieadvanced_inquisitor_tier4", "tieaggressor_inquisitor", "tieaggressor_inquisitor_tier4", "tieaggressor_uvqolo",
	"tiedecimator_inquisitor", "tieinterceptor_inquisitor_guard",
}

local function point(zone, name, extra)
	local p = E.POINTS[zone][name]

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

local function item(n) return { { species = { -1 }, item = E.ITEM_ROOT .. E.ITEMS[n] } } end

local function taunts5(...)
	local out = {}

	for _, key in ipairs({ ... }) do
		out[key] = 5
	end

	return out
end

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function E.expected()
	local P = "naboo_rebel_tier4_"
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES
	local randSurvival = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.RANDOM
	local randDelivery = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM
	local randRescue = SpaceRescueScreenplay.ATTACK_LIST_TYPES.RANDOM
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
		local ident = E.IDENTITY[global]

		return merge({ className = global, questType = ident.type, questName = ident.name, questZone = ident.zone }, more)
	end

	local function child(parent, more)
		local pid = E.IDENTITY[parent]

		return merge({ parentQuest = parent, parentQuestType = pid.type, parentQuestName = pid.name }, more)
	end

	-- a head: BIDIRECTIONAL, 5 s, the success child and the failure child
	local function bidirectional(success, failure)
		local s, f = E.IDENTITY[success], E.IDENTITY[failure]

		return {
			sideQuest = true, sideQuestType = s.type, sideQuestName = s.name, sideQuestSplitType = ST.BIDIRECTIONAL, sideQuestDelay = 5,
			sideFailQuestType = f.type, sideFailQuestName = f.name,
		}
	end

	local function completion(nextGlobal, delay)
		local n = E.IDENTITY[nextGlobal]

		return { sideQuest = true, sideQuestType = n.type, sideQuestName = n.name, sideQuestSplitType = ST.COMPLETION, sideQuestDelay = delay }
	end

	local function headRewards(n) return { creditReward = E.CREDITS, itemReward = item(n) } end

	local F, I, B, A, G = "imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_bomber_tier4", "imp_tie_advanced_tier4", "tieinterceptor_inquisitor_guard"
	local out = {}

	-- Mission 1: survival > assassinate (won) or escort (lost)
	out[E.M1[1]] = base(E.M1[1], merge(headRewards(1), bidirectional(E.M1[2], E.M1[3]), {
		transmissionPoint = point(EN, P .. "1_survival"),
		totalTransmissionTime = 360, timesToUpdateProgress = 6, transmissionStartDelay = 10, delayToFirstAttack = 10,
		attackShipLists = { rep(F, 6), { I, I, I, F, F, F }, { B, B, B, F, F, F }, cat({ A }, rep(F, 5)) },
		attackPeriod = 55, attackListType = randSurvival,
	}))
	out[E.M1[2]] = base(E.M1[2], merge(child(E.M1[1], {}), END, {
		arrivalDelay = 5, failTimer = 20, mustDestroyEscort = false,
		assassinateSpawns = { target = "tieadvanced_inquisitor_tier4", escorts = cat({ A, A }, rep(F, 6)) },
		targetPatrols = pts(EN, numbered(P .. "1_a_assassin_", 1, 6)),
	}))
	out[E.M1[3]] = base(E.M1[3], merge(child(E.M1[1], {}), END, {
		escortShips = { "reb_freightermedium_tier4" },
		escortPoints = pts(EN, numbered(P .. "1_b_escort_", 1, 4), { zoneName = EN, radius = 250 }, "escortNumber"),
		attackDelay = 45,
		attackShips = { rep(F, 6), { I, I, I, F, F, F }, { B, F, F, B, F, F }, cat({ A }, rep(F, 5)) },
		tauntData = taunts5("goodbyeCount", "reasonCount", "tauntCount", "thanksCount"),
	}))

	-- Mission 2: assassinate > space battle (won) or surprise attack (lost) > assassinate in Dathomir
	out[E.M2[1]] = base(E.M2[1], merge(headRewards(2), bidirectional(E.M2[2], E.M2[3]), {
		arrivalDelay = 10, failTimer = 20, mustDestroyEscort = false,
		assassinateSpawns = { target = "tieaggressor_uvqolo", escorts = cat({ A, A }, rep(I, 4)) },
		targetPatrols = pts(YV, numbered(P .. "2_assassin_", 1, 6)),
	}))
	out[E.M2[2]] = base(E.M2[2], merge(child(E.M2[1], {}), END, {
		battlePoint = point(YV, P .. "2_a_battle_point", { forward = E.FORWARD_2A }),
		damageMultiplier = 7, allyArrivalDelay = 30, enemyArrivalDelay = 45, allyOriginDist = -850, enemyOriginDist = 850, allyArrivalDist = -150, enemyArrivalDist = 200,
		allyForce = rep("reb_xwing_tier4", 4),
		enemyForce = cat({ "imp_tie_oppressor_tier4" }, rep(F, 9)),
	}))
	out[E.M2[3]] = base(E.M2[3], merge(child(E.M2[1], {}), completion(E.M2[4], 10), {
		surpriseAttackShips = { zone = YV, spawns = { { count = 9, shipName = G } } },
	}))
	out[E.M2[4]] = base(E.M2[4], merge(child(E.M2[3], {}), END, {
		arrivalDelay = 10, failTimer = 20, mustDestroyEscort = false,
		assassinateSpawns = { target = "tieaggressor_uvqolo", escorts = cat({ A, A }, rep(I, 4)) },
		targetPatrols = pts(DT, numbered(P .. "2_c_assassin_", 1, 5)),
	}))

	-- Mission 3: rescue > assassinate (won) or delivery, no pickup (lost)
	out[E.M3[1]] = base(E.M3[1], merge(headRewards(3), bidirectional(E.M3[2], E.M3[3]), {
		recoveryPath = pts(DT, numbered(P .. "3_rescue_", 1, 4)),
		targetShipType = "tie_vortex_spy", targetArrivalDelay = 5,
		attackShipLists = { rep(F, 6), { F, F, "tieaggressor_inquisitor", F, I, I }, { F, F, F, I, I, I }, cat({ A }, rep(F, 5)) },
		attackPeriod = 45, attackListType = randRescue, numResponses = 5,
	}))
	out[E.M3[2]] = base(E.M3[2], merge(child(E.M3[1], {}), END, {
		arrivalDelay = 10, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = "tiedecimator_inquisitor", escorts = cat({ A, A }, rep(I, 4)) },
		targetPatrols = pts(DT, numbered(P .. "3_a_assassin_", 1, 5)),
	}))
	out[E.M3[3]] = base(E.M3[3], merge(child(E.M3[1], {}), END, {
		deliveryShip = "rebel_smuggler_tier3",
		deliveryPoint = point(DT, P .. "3_b_delivery"),
		attackShipLists = { rep(F, 6), { F, F, "tieaggressor_inquisitor_tier4", F, I, I }, { A, F, F, A, F, F }, { I, I, I, F, F, F } },
		attackPeriod = 60, attackListType = randDelivery,
	}))

	-- Mission 4: space battle > space battle (won) or survival (lost)
	out[E.M4[1]] = base(E.M4[1], merge(headRewards(4), bidirectional(E.M4[2], E.M4[3]), {
		battlePoint = point(DT, P .. "4_battle_point", { forward = E.FORWARD_4 }),
		damageMultiplier = 7, allyArrivalDelay = 150, enemyArrivalDelay = 120, allyOriginDist = 800, enemyOriginDist = -800, allyArrivalDist = 150, enemyArrivalDist = -200,
		allyForce = cat(rep("reb_awing_tier4", 2), rep("reb_xwing_tier4", 3)),
		enemyForce = cat({ "tiedecimator_inquisitor", G, G }, rep(F, 5), { "imp_tie_aggressor_tier4" }),
	}))
	out[E.M4[2]] = base(E.M4[2], merge(child(E.M4[1], {}), END, {
		battlePoint = point(DT, P .. "4_a_battle_point", { forward = E.FORWARD_4A }),
		damageMultiplier = 7, allyArrivalDelay = 30, enemyArrivalDelay = 45, allyOriginDist = 650, enemyOriginDist = -750, allyArrivalDist = 100, enemyArrivalDist = -50,
		allyForce = rep("reb_bwing_tier4", 4),
		enemyForce = cat({ A, I, I, "tieaggressor_inquisitor_tier4", G, G }, rep(F, 3)),
	}))
	out[E.M4[3]] = base(E.M4[3], merge(child(E.M4[1], {}), END, {
		transmissionPoint = point(DT, P .. "4_b_survival"),
		totalTransmissionTime = 240, timesToUpdateProgress = 4, transmissionStartDelay = 5, delayToFirstAttack = 5,
		attackShipLists = { rep(F, 6), { "imp_tie_oppressor_tier4", F, F, F, I, I }, { F, F, "tieaggressor_inquisitor", G, G, F }, { I, I, I, F, F, F } },
		attackPeriod = 45, attackListType = randSurvival,
	}))

	-- Duties
	out[E.DUTIES[1]] = base(E.DUTIES[1], merge(END, {
		creditReward = 300,
		totalLevels = 5, totalRounds = 3, totalWaves = 4,
		bossShip = "tieadvanced_inquisitor_tier4",
		shipTypes = { { F, F, F }, { I, F, F }, { B, F, F } },
	}))
	out[E.DUTIES[2]] = base(E.DUTIES[2], merge(END, {
		creditReward = 5000, creditKillBonus = 300,
		escortShips = { "reb_ykl37r_tier4", "reb_transport_tier4", "reb_freightermedium_tier4", "reb_freighterheavy_tier4", "reb_freighterlight_tier4" },
		escortPoints = pts(YV, numbered(P .. "1_escort_duty_", 1, 5), { zoneName = YV, radius = 250 }, "escortNumber"),
		attackDelay = 50,
		attackShips = { { F, F, F }, { I, F, F }, { B, F, F } },
		tauntData = taunts5("goodbyeCount", "reasonCount", "tauntCount", "thanksCount"),
	}))
	out[E.DUTIES[3]] = base(E.DUTIES[3], merge(END, {
		creditReward = 5000, creditKillBonus = 300,
		numResponses = 5, arrivalDelay = 10, recoveryDelay = 30,
		recoverShips = { "lambdashuttle_inquisition_data_vessel" },
		recoveryConversationMobile = E.DROID_MOBILE,
		escortShips = { A, F, F },
		preRecoveryPoints = pts(EN, numbered(P .. "1_recovery_", 1, 6), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(EN, numbered(P .. "1_recovery_", 7, 10), { radius = 250 }, "escortNumber"),
		attackDelay = 45,
		attackShips = { { F, F, F }, { I, I, I }, { F, F, B } },
		tauntData = taunts5("panicCount", "thanksCount"),
	}))
	out[E.DUTIES[4]] = base(E.DUTIES[4], merge(END, {
		creditReward = 5000, creditKillBonus = 300,
		recoveryPath = pts(DA, cat(numbered(P .. "1_rescue_duty_", 1, 5), { "naboo_rebel_tier3_rescue_3" })),
		targetShipTypes = { "freighterheavy_tier4", "freighterlight_tier4", "freightermedium_tier4" },
		targetArrivalDelay = 10,
		attackShipLists = { { F, F, F }, { I, I, I }, { B, F, F } },
		attackPeriod = 50, attackListType = 1, numResponses = 5,
	}))

	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

E.loadErrors = V1.loadErrors

-- The server's load: every squadron file (vortex_tier1_data.lua's load); a missing production file is recorded, not raised
function E.load() V1.load() end

function E.problems() return table.concat(V1.loadErrors, " | ") end

function E.quest(global)
	V1.load()

	return H.expectGlobal(global, "Vortex tier 4 quest table (vortex-tier4-extok-evin). Load problems: " .. E.problems())
end

function E.squadron()
	V1.load()

	return H.expectGlobal("VortexSquadronScreenplay", "squadron screenplay object. Load problems: " .. E.problems())
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

function E.crc(global)
	local ident = E.IDENTITY[global]

	return H.questCrc(ident.type, ident.name)
end

-- Journal state of one of the 17 tables (type AND name, so the five naboo_rebel_tier4_1 tables are separate). state: "complete" | "active" | "none"
function E.setState(player, global, state)
	local key = E.crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function E.state(player, global)
	local key = E.crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- the status keys of the pilot whose name starts with `name` .. ":" (the scan the duty tests use: a duty must set no <name>:* key)
function E.keysNamed(player, name)
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

-- A Vortex graduate of tier 3 (the four tier 1 skills, the four tier 2 skills, the four tier 3 skills, VORTEX_PILOT_KEY "3", Ezkiel's and Vrovel's missions paid,
-- pilot tier 4) with optional tier 4 state. Options:
--   evin        k: Evin's missions 1..k won (every member of the chain complete), :attempted and :reward set (default 0)
--   evinKeys    true: the 8 head keys set whatever the journal says
--   met         true: TIER4_MET_KEY set
--   evinActive  global of a tier 4 member left active in the journal
--   duty        global of a tier 4 duty left active in the journal
--   missions    Ezkiel's missions won (default 4), t3 the tier 3 skills held (default 4): vortex_tier3_data.lua's W.pilot options; the rest is that file's
function E.pilot(o)
	o = o or {}
	V1.load()

	local base = {}

	for k, v in pairs(o) do
		base[k] = v
	end

	base.evin, base.evinKeys, base.met, base.evinActive, base.duty = nil, nil, nil, nil, nil
	base.missions = o.missions == nil and 4 or o.missions
	base.t3 = o.t3 == nil and 4 or o.t3

	local player = W.pilot(base)

	for n = 1, o.evin or 0 do
		for _, global in ipairs(E.CHAINS[n]) do
			E.setState(player, global, "complete")
		end

		H.setQuestStatus(player, E.STATUS[n] .. ":attempted", "1")
		H.setQuestStatus(player, E.STATUS[n] .. ":reward", "1")
	end

	if o.evinKeys then
		for _, name in ipairs(E.STATUS) do
			H.setQuestStatus(player, name .. ":attempted", "1")
			H.setQuestStatus(player, name .. ":reward", "1")
		end
	end

	if o.met then
		H.setQuestStatus(player, E.MET_KEY, "1")
	end

	if o.evinActive then
		E.setState(player, o.evinActive, "active")
	end

	if o.duty then
		E.setState(player, o.duty, "active")
	end

	return player
end

-- A Rebel pilot in a Rebel-faction ship in `zone` (default space_endor), the way the runtime tests start a quest
function E.flyer(zone)
	V1.load()

	return H.newPlayer({
		zone = zone or EN,
		pilot = "rebel",
		ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") },
	})
end

---------------------------------------------------------------------------------------------
-- Part B: Brother Extok Evin's conversation (vortex-tier4-extok-evin-convo) extends this file below this marker.
---------------------------------------------------------------------------------------------

return E
