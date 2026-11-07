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
-- Part B: Brother Extok Evin's conversation (vortex-tier4-extok-evin-convo)
-- Spec: .claude/work/vortex-tier4-extok-evin-convo/01-spec.md (Content contract 2-4, Data mapping 1-2, Conversation flow 1-4, Appendix A and D).
-- Everything here is copied from the spec; the screens table comes from the spec's Appendix A by a scratch script (vortex_tier4_evin_screens_data.lua).
--   E.TEMPLATE / E.HANDLER / E.STF / E.PREFIX and the file names of the template, handler, NPC, SC and SPL
--   E.SCREENS / E.screenRow / E.screenIds / E.reach / E.walkTo / E.follow   Appendix A (the static links)
--   E.MISSIONS / E.TRAIN / E.DUTY_SCREENS / E.START_SCREENS / E.REWARD_SCREENS / E.NAME_SCREENS / E.TIER_SCREENS   the handler's tables (Content contract 2)
--   E.NGE_MAP                    the 52 NGE editor numbers J4 uses, each with its Data mapping 2 class and where it landed
--   E.OFFER_PATHS                Appendix D: one reply path per accept screen
--   E.javaRewards()              the four rewardForMissionN bodies of the J4 fixture (the oracle of AC-7)
--   E.loadConversation() / E.requireConversation(lu) / E.handler()   the server's load of Evin's template and handler (load errors are recorded)
--   E.npc / E.talk / E.firstScreen / E.drive   H.converse from the first screen / from a given screen (start, reward and duty screens run their display actions)
--   E.pilot{...}                 extended below (flag, ezkielM4Paid, t4, mission, paid, master, squadron, otherQuest)
--   E.spyDuties / E.startedDuties / E.recordGrants / E.recordChainStarts / E.restore / E.startAll / E.useSkillCosts / E.snapshot   observation helpers
---------------------------------------------------------------------------------------------

E.TEMPLATE = "evin_convo_template"
E.HANDLER = "evinConvoHandler"
E.STF = "conversation/naboo_rebel_tier4"
E.PREFIX = "@conversation/naboo_rebel_tier4:"
E.JAVA = "script/conversation/naboo_rebel_tier4.java"

E.TEMPLATE_FILE = "mobile/conversations/space/rebel/vortex_squadron/evin_convo.lua"
E.HANDLER_FILE = "screenplays/space/conversations/rebel/vortex_squadron/evinConvoHandler.lua"
E.NPC_FILE = "mobile/space/extok_evin.lua"
E.SPAWN_FILE = "screenplays/cities/talus_dearic.lua"
E.SPACE_CONVERSATIONS = "mobile/conversations/space/space_conversations.lua"
E.SCREENPLAYS = "screenplays/space/screenplays.lua"

E.TEMPLATE_INCLUDE = 'includeFile("conversations/space/rebel/vortex_squadron/evin_convo.lua")'
E.HANDLER_INCLUDE = 'includeFile("space/conversations/rebel/vortex_squadron/evinConvoHandler.lua")'

E.STANDING = 150
E.TRAIN_COST = 1000000
E.MASTER = "pilot_rebel_navy_master"
E.MET_SCREEN = "met_b5eac7c2"

E.SCREENS = require("vortex_tier4_evin_screens_data")

function E.screenRow(rowId)
	for _, row in ipairs(E.SCREENS) do
		if row.id == rowId then
			return row
		end
	end
end

-- The Appendix A screen ids (130), sorted
function E.screenIds()
	local out = {}

	for i, row in ipairs(E.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- Content contract 2: MISSIONS (head, quest string, the "won" constants, status key name, screens, J4 reward item, zone)
E.MISSIONS = {}

local MISSION_ZONES = { EN, YV, DT, DT }

local MISSION_SCREENS = {
	{ retries = { "m1_retry_c8592539", "m1_retry_4a835de4" }, accepts = { "m1_accept_df1c8925" } },
	{ retries = { "m2_retry_80803e51", "m2_retry_13010c2d" }, accepts = { "m2_accept_4eaf90e6" } },
	{ retries = { "m3_retry_34a99b58", "m3_retry_84f5730a" }, accepts = { "m3_accept_4e0bf82f", "m3_accept_dd76100c" } },
	{ retries = { "m4_retry_3de94b24", "m4_retry_be8a1d81" }, accepts = { "m4_accept_122f0ea4" } },
}

for n = 1, 4 do
	E.MISSIONS[n] = {
		n = n, head = E.HEADS[n], questString = "TIER4_QUEST_STRING_" .. n, wins = { "TIER4_QUEST_STRING_" .. n .. "_SIDE1", "TIER4_QUEST_STRING_" .. n .. "_SIDE2" },
		standing = 150, status = E.STATUS[n], offer = "m" .. n .. "_offer", failed = "m" .. n .. "_failed", reward = "m" .. n .. "_reward", retries = MISSION_SCREENS[n].retries,
		accepts = MISSION_SCREENS[n].accepts, zone = MISSION_ZONES[n], item = E.ITEMS[n],
	}
end

-- Content contract 2: DUTY_SCREENS (screen -> global, quest string), in the reply order of the duty menus
E.DUTY_SCREENS = {
	duty_destroy = { global = E.DUTIES[1], questString = "TIER4_QUEST_STRING_DUTY_1" },
	duty_escort = { global = E.DUTIES[2], questString = "TIER4_QUEST_STRING_DUTY_2" },
	duty_recovery = { global = E.DUTIES[3], questString = "TIER4_QUEST_STRING_DUTY_3" },
	duty_rescue = { global = E.DUTIES[4], questString = "TIER4_QUEST_STRING_DUTY_4" },
}

E.DUTY_ORDER = { "duty_destroy", "duty_escort", "duty_recovery", "duty_rescue" }

-- the four duty replies of a menu, then "briefing again" (s_49805f81), and the links they carry
E.MENU_REPLIES = { "s_1b9c5097", "s_e01d95b6", "s_df069f76", "s_2477938c", "s_49805f81" }
E.MENU_LINKS = { "duty_destroy", "duty_escort", "duty_recovery", "duty_rescue", "duty_brief_1" }
E.MENUS = { "met_b5815881", "duty_brief_4", "tier4_incomplete", "here_for_work" }

-- Content contract 2: TRAIN_CHOICES in menu order. skl = the client skill name (skl_n) that maps the topic reply to the skill (FE-1); words = what the reply must say
E.TRAIN = {
	{ x = "starships", skill = "pilot_rebel_navy_starships_04", reply = "s_f4d84e3", trained = "trained_starships", trainedSid = "s_788df6ff", skl = "Hyper-Maneuverable Starfighters", words = "hyper-maneuverable starfighters" },
	{ x = "weapons", skill = "pilot_rebel_navy_weapons_04", reply = "s_dbb3b0b0", trained = "trained_weapons", trainedSid = "s_4ef111c8", skl = "Equipment D: Heavy Alliance Starship Component Use", words = "heavy starship component use" },
	{ x = "procedures", skill = "pilot_rebel_navy_procedures_04", reply = "s_d0f87f24", trained = "trained_procedures", trainedSid = "s_b322ae4b", skl = "Special Weapons and Tactics", words = "special weapons and tactics" },
	{ x = "droid", skill = "pilot_rebel_navy_droid_04", reply = "s_71d852f5", trained = "trained_droid", trainedSid = "s_e5886662", skl = "Droid Intelligence Theory", words = "droid intelligence theory" },
}

-- Content contract 2: START_SCREENS (13), screen -> mission
E.START_SCREENS = {
	m1_retry_c8592539 = 1, m1_retry_4a835de4 = 1, m1_accept_df1c8925 = 1,
	m2_retry_80803e51 = 2, m2_retry_13010c2d = 2, m2_accept_4eaf90e6 = 2,
	m3_retry_34a99b58 = 3, m3_retry_84f5730a = 3, m3_accept_4e0bf82f = 3, m3_accept_dd76100c = 3,
	m4_retry_3de94b24 = 4, m4_retry_be8a1d81 = 4, m4_accept_122f0ea4 = 4,
}

-- Content contract 2: REWARD_SCREENS, screen -> mission
E.REWARD_SCREENS = { m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4 }

-- Content contract 2: TIER_SCREENS (raise the pilot tier only)
E.TIER_SCREENS = { "transfer", "here_for_work" }

-- Content contract 2: NAME_SCREENS (11), the screens whose line has a %TU or %NU token
E.NAME_SCREENS = {
	"grounded", "m4_retry_3de94b24", "met_b5815881", "duty_brief_4", "duty_recovery", "duty_rescue", "m1_reward", "m4_reward_cc6fef40", "m4_reward_ac8b75ef", "m1_offer", "m2_d8a1ee7e",
}

-- Data mapping 2: the 52 NGE editor numbers J4 uses, each with its class (T twin, R rejoin, b reuse of a client reply, P pool line) and where it landed.
--   screen  the Appendix A screen that fills or follows the slot; npc = true: the screen fills an NGE NPC slot (it carries the slot's J4 animation and end flag)
--   reply, link  the replacement reply (a client line) on `screen` and the screen it links to
--   like    the screen whose animation and end flag the NGE NPC line has in J4 (the rejoined refusal endings)
E.NGE_MAP = {
	s_7 = { class = "R", screen = "not_pilot", reply = "s_4c695dbd", link = "off_limits", like = "off_limits" },
	s_9 = { class = "T", screen = "wrong_faction", npc = true },
	s_11 = { class = "T", screen = "wrong_faction", reply = "s_b3218dae", link = "off_limits" },
	s_13 = { class = "R", screen = "wrong_faction", reply = "s_b3218dae", link = "off_limits", like = "off_limits" },
	s_15 = { class = "T", screen = "wrong_faction", reply = "s_4c695dbd", link = "off_limits" },
	s_17 = { class = "R", screen = "wrong_faction", reply = "s_4c695dbd", link = "off_limits", like = "off_limits" },
	s_272 = { class = "T", screen = "duty_brief_1", npc = true },
	s_274 = { class = "T", screen = "duty_brief_1", reply = "s_5e2a2bb1", link = "duty_brief_2" },
	s_276 = { class = "T", screen = "duty_brief_2", npc = true },
	s_278 = { class = "T", screen = "duty_brief_2", reply = "s_61657d0f", link = "duty_brief_3" },
	s_280 = { class = "T", screen = "duty_brief_3", npc = true },
	s_282 = { class = "T", screen = "duty_brief_3", reply = "s_6598178f", link = "duty_brief_4" },
	s_88 = { class = "b", screen = "m4_5d9fd0db", reply = "s_d1be90a9", link = "m4_80ecabfc" },
	s_101 = { class = "b", screen = "m4_2c5be3f2", reply = "s_6798dc03", link = "m4_18da605a" },
	s_104 = { class = "R", screen = "m4_18da605a", reply = "s_b76c91c2", link = "m4_9b0c24f5" },
	s_106 = { class = "R", screen = "m4_18da605a", reply = "s_b76c91c2", link = "m4_9b0c24f5" },
	s_108 = { class = "R", screen = "m4_18da605a", reply = "s_b76c91c2", link = "m4_9b0c24f5" },
	s_110 = { class = "R", screen = "m4_18da605a", reply = "s_b76c91c2", link = "m4_9b0c24f5" },
	s_112 = { class = "R", screen = "m4_18da605a", reply = "s_b76c91c2", link = "m4_9b0c24f5" },
	s_114 = { class = "R", screen = "m4_18da605a", reply = "s_b76c91c2", link = "m4_9b0c24f5" },
	s_137 = { class = "b", screen = "m3_a753d65f", reply = "s_db140dbf", link = "m3_ef2200e9" },
	s_171 = { class = "b", screen = "m2_7294f771", reply = "s_b3e9c738", link = "m2_accept_4eaf90e6" },
	s_175 = { class = "T", screen = "m2_s175", npc = true },
	s_177 = { class = "T", screen = "m2_s175", reply = "s_1c8bddbb", link = "m2_s179" },
	s_179 = { class = "T", screen = "m2_s179", npc = true },
	s_181 = { class = "T", screen = "m2_s179", reply = "s_d91a074", link = "m2_s183" },
	s_183 = { class = "T", screen = "m2_s183", npc = true },
	s_185 = { class = "T", screen = "m2_s183", reply = "s_3069ecae", link = "m2_3ff3b52b" },
	s_189 = { class = "R", screen = "m2_3ff3b52b", reply = "s_2592b2f2", link = "m2_7294f771" },
	s_191 = { class = "R", screen = "m2_3ff3b52b", reply = "s_2592b2f2", link = "m2_7294f771" },
	s_193 = { class = "R", screen = "m2_3ff3b52b", reply = "s_2592b2f2", link = "m2_7294f771" },
	s_214 = { class = "T", screen = "m1_d082018b", reply = "s_cc335afa", link = "m1_a7a9e2a7" },
	s_217 = { class = "R", screen = "m1_a7a9e2a7", reply = "s_d1be90a9", link = "m1_c49d2b1" },
	s_219 = { class = "R", screen = "m1_a7a9e2a7", reply = "s_d1be90a9", link = "m1_c49d2b1" },
	s_221 = { class = "R", screen = "m1_a7a9e2a7", reply = "s_d1be90a9", link = "m1_c49d2b1" },
	s_223 = { class = "R", screen = "m1_a7a9e2a7", reply = "s_d1be90a9", link = "m1_c49d2b1" },
	s_225 = { class = "R", screen = "m1_a7a9e2a7", reply = "s_d1be90a9", link = "m1_c49d2b1" },
	s_227 = { class = "R", screen = "m1_a7a9e2a7", reply = "s_d1be90a9", link = "m1_c49d2b1" },
	s_300 = { class = "P", screen = "training" },
	s_301 = { class = "P", screen = "training" },
	s_302 = { class = "P", screen = "training" },
	s_303 = { class = "P", screen = "training" },
	s_304 = { class = "P", screen = "training" },
	s_305 = { class = "P", screen = "training" },
	s_307 = { class = "P", screen = "training" },
	s_309 = { class = "P", screen = "training" },
	s_311 = { class = "P", screen = "training" },
	s_315 = { class = "P", screen = "trained_starships", npc = true },
	s_317 = { class = "P", screen = "trained_weapons", npc = true },
	s_319 = { class = "P", screen = "trained_procedures", npc = true },
	s_321 = { class = "P", screen = "trained_droid", npc = true },
	s_310 = { class = "b", screen = "transfer_20ace535", reply = "s_8efde2ae", link = "transfer_2808ade7" },
}

-- Appendix D: one reply path (sids) per accept screen route
E.OFFER_PATHS = {
	{ mission = 1, accept = "m1_accept_df1c8925", replies = { "s_a399c876", "s_23048e75", "s_d284d072", "s_bfc53dde", "s_cc335afa", "s_d1be90a9", "s_14ff5df8", "s_80d8485c" } },
	{ mission = 1, accept = "m1_accept_df1c8925", replies = { "s_426e2f6c", "s_cc335afa", "s_d1be90a9", "s_14ff5df8", "s_80d8485c" } },
	{ mission = 2, accept = "m2_accept_4eaf90e6", replies = {
		"s_d3c79ae3", "s_f4640a5b", "s_422deda3", "s_15e6446", "s_45387989", "s_a13b304c", "s_8a212117", "s_290b6cd5", "s_1c8bddbb", "s_d91a074", "s_3069ecae", "s_2896ca81", "s_b3e9c738" } },
	{ mission = 2, accept = "m2_accept_4eaf90e6", replies = { "s_61dcb099", "s_1c8bddbb", "s_d91a074", "s_3069ecae", "s_2592b2f2", "s_b3e9c738" } },
	{ mission = 3, accept = "m3_accept_4e0bf82f", replies = { "s_d17adb67", "s_db140dbf", "s_d0b9a993", "s_25dc6fac", "s_113f3fb6", "s_46787375", "s_711e6727", "s_2c4789b", "s_c8b9717d" } },
	{ mission = 3, accept = "m3_accept_dd76100c", replies = { "s_3b45e8ed", "s_db140dbf", "s_897a43f2", "s_23c4339a", "s_89488f10" } },
	{ mission = 4, accept = "m4_accept_122f0ea4", replies = { "s_5d4e24a2", "s_38f1d025", "s_841d27db", "s_d1be90a9", "s_6798dc03", "s_b76c91c2", "s_52917b0d", "s_16d870fe" } },
	{ mission = 4, accept = "m4_accept_122f0ea4", replies = { "s_9f4dbe82", "s_6798dc03", "s_b76c91c2", "s_52917b0d", "s_16d870fe" } },
}

-- The screens shown by following static links of Appendix A from `start` with the reply sids (nil when a reply is not on the screen)
function E.follow(start, replies)
	local ids, cur = { start }, start

	for _, reply in ipairs(replies) do
		local nextId

		for _, o in ipairs(E.screenRow(cur).options) do
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
function E.reach(start, avoid)
	local found = { [start] = { ids = { start }, replies = {} } }
	local queue = { start }

	while #queue > 0 do
		local cur = found[table.remove(queue, 1)]

		for _, o in ipairs(E.screenRow(cur.ids[#cur.ids]).options) do
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

function E.walkTo(from, to, avoid)
	local hit = E.reach(from, avoid)[to]

	if hit == nil then
		return nil
	end

	return hit.replies, hit.ids
end

-- The J4 fixture: rewardForMissionN bodies -> { type, name, credits, item, standing, guarded } by mission number (the oracle of AC-7, D-11)
function E.javaRewards()
	local f = assert(io.open(H.FIXTURES .. E.JAVA, "r"), "cannot open the J4 fixture")
	local java = f:read("a")

	f:close()

	local out = {}
	local words = { One = 1, Two = 2, Three = 3, Four = 4 }

	for word, body in java:gmatch("naboo_rebel_tier4_action_rewardForMission(%a+)%(obj_id player, obj_id npc%) throws InterruptedException%s*(%b{})") do
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
		V1.loadErrors[#V1.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

local loadedB = false

-- The server's load of Evin's template and handler (after the squadron files). A missing production file is recorded in the load problems, not raised.
function E.loadConversation()
	E.load()

	if loadedB then
		return
	end

	loadedB = true
	try("evin_convo.lua", function() H.loadMobile("conversations/space/rebel/vortex_squadron/evin_convo.lua") end)
	try("evinConvoHandler.lua", function() H.loadScreenplay("space/conversations/rebel/vortex_squadron/evinConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded (a readable red phase)
function E.requireConversation(lu)
	E.loadConversation()
	lu.assertNotNil(H.conversationTemplateTable(E.TEMPLATE), E.TEMPLATE .. " is not registered by addConversationTemplate (expected " .. E.TEMPLATE_FILE .. ", vortex-tier4-extok-evin-convo). Load problems: " .. E.problems())
	lu.assertNotNil(rawget(_G, E.HANDLER), E.HANDLER .. " is not defined (expected " .. E.HANDLER_FILE .. ", vortex-tier4-extok-evin-convo). Load problems: " .. E.problems())
end

function E.handler()
	E.loadConversation()

	return H.expectGlobal(E.HANDLER, "Evin's conversation handler (vortex-tier4-extok-evin-convo). Load problems: " .. E.problems())
end

-- Brother Extok Evin in the Dearic theater's back room (screenplays/cities/talus_dearic.lua:179)
function E.npc() return H.newNpc({ name = "Brother Extok Evin", zone = "talus", x = -24.0, z = 2.1, y = 73.8 }) end

local function requireLoaded()
	E.loadConversation()

	if H.conversationTemplateTable(E.TEMPLATE) == nil or rawget(_G, E.HANDLER) == nil then
		error("Evin's conversation is not loaded (vortex-tier4-extok-evin-convo). Load problems: " .. E.problems(), 3)
	end
end

-- Talks to Evin from the first screen. choices as for H.converse (0-based indexes, option sids, hooks).
function E.talk(player, choices)
	requireLoaded()

	return H.converse({ template = E.TEMPLATE, player = player, npc = E.npc(), choices = choices })
end

function E.firstScreen(player) return E.talk(player)[1].id end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (vortex_tier2_data.lua's drive on Evin's template)
function E.drive(player, startId, choices)
	requireLoaded()

	local template, handler, npc = V2.TEMPLATE, V2.HANDLER, V2.npc

	V2.TEMPLATE, V2.HANDLER, V2.npc = E.TEMPLATE, E.HANDLER, E.npc

	local results = table.pack(pcall(V2.drive, player, startId, choices))

	V2.TEMPLATE, V2.HANDLER, V2.npc = template, handler, npc

	if not results[1] then
		error(results[2], 0)
	end

	return table.unpack(results, 2, results.n)
end

E.ids = V1.ids
E.optionSids = V1.optionSids
E.linksOf = V1.linksOf

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local pilotPartA = E.pilot

-- how each mission state of E.pilot's `mission` / `paid` options reads in the journal: which chain members (index into E.CHAINS[n]) are complete and which one is active.
-- The head is chain[1], the success child chain[2], the failure child chain[3], mission 2's Uvqolo in Dathomir chain[4]. A failed quest is not complete and not active.
local MISSION_STATES = {
	won_a = { complete = { 1, 2 } },
	won_b = { complete = { 3 } },
	won_b_c_failed = { complete = { 3 } },
	won_b_c_won = { complete = { 3, 4 } },
	c_active = { complete = { 3 }, active = 4 },
	failed_head = {},
	aborted = {},
	failed_a = { complete = { 1 } },
	failed_b = {},
	a_active = { complete = { 1 }, active = 2 },
	b_active = { active = 3 },
	active = { active = 1 },
	attempted = {},
}

E.MISSION_STATES = MISSION_STATES

-- A Vortex pilot of tier 3 or 4. The Part A options (evin, evinKeys, met, evinActive, duty, missions, t3) stay as they were; the Part B options:
--   flag          VORTEX_PILOT_KEY value (alias of the earlier `graduated`; false leaves it unset; default "3")
--   ezkielM4Paid  false: Ezkiel's mission 4 is not paid (missions = 3 unless given)
--   t3            number of _03 skills held (default 4), or a list of E.TRAIN indexes
--   t4            list of E.TRAIN indexes of the _04 skills held
--   master        the master skill is held
--   mission       { [n] = state } for Evin's mission n: "won_a" (head and success child complete) | "won_b" (the failure child complete) | "failed_head" | "aborted" |
--                 "failed_a" (head complete, the success child failed) | "failed_b" (the failure child failed) | "active" | "a_active" | "b_active" | "attempted"; mission 2 also
--                 "won_b_c_failed" | "won_b_c_won" | "c_active". Every state but none sets :attempted
--   paid          list of n: mission n won (won_a), :attempted and :reward set
--   squadron      "vortex" (default) | "havoc" | "none" | a squadron constant | true | false
--   otherQuest    "story" | "duty": a space mission of another trainer in the datapad (alias of `datapad`)
--   pilotTier     ghost pilot tier (default 4 with four _03 skills, 3 with fewer, 5 with four _04 skills)
--   xp, standing, faction, pilot, species, inventory, inShip, zone, t1, t2, vrovelMissions: as W.pilot / V.pilot
function E.pilot(o)
	o = o or {}

	local base = {}

	for k, v in pairs(o) do
		base[k] = v
	end

	base.flag, base.ezkielM4Paid, base.t4, base.master, base.mission, base.paid, base.otherQuest = nil, nil, nil, nil, nil, nil, nil

	if o.flag ~= nil then
		base.graduated = o.flag
	end

	if o.ezkielM4Paid == false and o.missions == nil then
		base.missions = 3
	end

	if o.squadron == "vortex" then
		base.squadron = nil
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
		base.skills[#base.skills + 1] = E.TRAIN[i].skill
	end

	if o.master then
		base.skills[#base.skills + 1] = E.MASTER
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
		local chain = E.CHAINS[n]

		H.setQuestStatus(player, E.STATUS[n] .. ":attempted", "1")

		if state == "paid" then
			H.setQuestStatus(player, E.STATUS[n] .. ":reward", "1")

			for _, global in ipairs(chain) do
				E.setState(player, global, "complete")
			end
		else
			local spec = MISSION_STATES[state]

			if spec == nil then
				error("E.pilot: unknown mission state '" .. tostring(state) .. "'", 2)
			end

			for _, i in ipairs(spec.complete or {}) do
				E.setState(player, chain[i], "complete")
			end

			if spec.active then
				E.setState(player, chain[spec.active], "active")
			end
		end
	end

	return player
end

-- A pilot who is not a pilot at all (no pilot skill, no squadron, no state)
function E.nonPilot(extra)
	local o = { pilot = false, squadron = "none", t1 = 0, t2 = 0, t3 = {}, vrovelMissions = 0, missions = 0, flag = false }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return E.pilot(o)
end

-- the pilot of the training menu / offers: the first meeting heard, `have` the _04 skills held (E.TRAIN indexes), their missions won and paid, `xp` experience
function E.trainee(have, xp, extra)
	local paid = {}

	for i = 1, #have do
		paid[i] = i
	end

	local o = { t4 = have, paid = paid, xp = xp or E.TRAIN_COST, met = true }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return E.pilot(o)
end

-- "mission n is won (through child `via`, default won_a) and unpaid, missions 1..n-1 paid, n skills held, the first meeting heard": the pilot a reward screen opens for
function E.rewardPilot(n, via, extra)
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

	return E.pilot(o)
end

-- "missions 1..n-1 paid, n skills held, the first meeting heard": the pilot mission n is offered to
function E.offerPilot(n, extra)
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

	return E.pilot(o)
end

-- the graduate: four _04 skills, four missions paid, the first meeting heard, pilot tier 5
function E.graduate(extra)
	local o = { t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, met = true }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return E.pilot(o)
end

---------------------------------------------------------------------------------------------
-- Observation
---------------------------------------------------------------------------------------------

function E.attempted(player, n) return H.getQuestStatus(player, E.STATUS[n] .. ":attempted") end

function E.paid(player, n) return H.getQuestStatus(player, E.STATUS[n] .. ":reward") end

function E.hasMet(player) return H.getQuestStatus(player, E.MET_KEY) == "1" end

-- the Rebel standing of the pilot
function E.standing(player) return player.ghost.factionStanding.rebel or 0 end

-- The VORTEX_PILOT_KEY value of the pilot ("1", "2", "3") or nil
function E.flag(player) return H.getQuestStatus(player, E.VORTEX_PILOT_KEY) end

function E.exp(player) return player.ghost.experience.space_combat_general end

-- giveItem templates received by the pilot, in order
function E.items(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory then
			out[#out + 1] = call[2]
		end
	end

	return out
end

-- the _04 skills (of the four) the pilot holds, in E.TRAIN order
function E.held4(player)
	local out = {}

	for _, t in ipairs(E.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

-- Registers the 17 quest tables (the way the runtime tests do) so a real startQuest can run
function E.startAll()
	for _, global in ipairs(E.GLOBALS) do
		E.quest(global):start()
	end
end

-- Spies the startQuest of the four duty globals (H.spyOn does not call the original); returns { global -> calls }
function E.spyDuties()
	local spies = {}

	for _, global in ipairs(E.DUTIES) do
		spies[global] = H.spyOn(E.quest(global), "startQuest")
	end

	return spies
end

-- "global xN" strings of the spied duties that started, in E.DUTIES order
function E.startedDuties(spies)
	local out = {}

	for _, global in ipairs(E.DUTIES) do
		if spies[global] ~= nil and #spies[global] > 0 then
			out[#out + 1] = global .. " x" .. #spies[global]
		end
	end

	return out
end

local restoreFns = {}

-- Records the calls of SpaceHelpers:grantSpaceSkill ({ skill, deduct }) and runs the original. Call E.restore() in tearDown.
function E.recordGrants()
	local calls = {}
	local orig = SpaceHelpers.grantSpaceSkill

	SpaceHelpers.grantSpaceSkill = function(self, pPlayer, skill, deduct)
		calls[#calls + 1] = { skill = skill, deduct = deduct }

		return orig(self, pPlayer, skill, deduct)
	end

	restoreFns[#restoreFns + 1] = function() SpaceHelpers.grantSpaceSkill = orig end

	return calls
end

-- Records the calls of SpaceHelpers:startSpaceQuestChain (head global names) and runs the original. Call E.restore() in tearDown.
function E.recordChainStarts()
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
function E.stubChainStarts()
	local calls = {}
	local orig = SpaceHelpers.startSpaceQuestChain

	SpaceHelpers.startSpaceQuestChain = function(self, pPlayer, pNpc, headGlobal)
		calls[#calls + 1] = headGlobal
	end

	restoreFns[#restoreFns + 1] = function() SpaceHelpers.startSpaceQuestChain = orig end

	return calls
end

function E.restore()
	for _, fn in ipairs(restoreFns) do
		fn()
	end

	restoreFns = {}
end

-- Charges the XP of the _04 skills from the fixture (1,000,000 each); without it the fake charges nothing
function E.useSkillCosts()
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
function E.snapshot(player)
	local ghost = player.ghost

	return {
		keys = H.Engine.sharedMemoryKeys(), status = (function()
			local copy = {}

			for k, v in pairs(H.Fakes.questStatus) do
				copy[k] = v
			end

			return copy
		end)(), flag = E.flag(player), met = E.hasMet(player),
		journalActive = ghost and (function() local c = {} for k, v in pairs(ghost.journalActive) do c[k] = v end return c end)() or nil,
		journalComplete = ghost and (function() local c = {} for k, v in pairs(ghost.journalComplete) do c[k] = v end return c end)() or nil,
		skills = (function() local c = {} for k, v in pairs(player.skills or {}) do c[k] = v end return c end)(), xp = ghost and E.exp(player) or nil,
		pilotTier = ghost and ghost.pilotTier or nil, standing = ghost and E.standing(player) or nil, credits = player.bankCredits,
		inventory = #(player.inventory and player.inventory.items or {}), engineCalls = #H.Engine.calls,
	}
end

return E
