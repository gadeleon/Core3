-- Shared test data and builders for Black Epsilon tier 3 (Haymir Rendundi), not a test file.
-- Spec: .claude/work/black-epsilon-tier3-haymir/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself:
--   T.GLOBALS / T.IDENTITY     the 14 quest globals and their class, type and name (Content contract 1)
--   T.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   T.POINTS / T.SPAWNER       Data mapping 2: the points per zone and the 1 spawner, Core3 x, z, y
--   T.SCREENS                  Appendix A (black_epsilon_tier3_screens_data.lua, generated from the spec table)
--   T.MISSIONS / T.TRAIN       MISSIONS and TRAIN_CHOICES of the handler (Content contract 3)
--   T.load()                   the server's load of the squadron, the template and the handler, collecting load errors
--   T.pilot{...}               a pilot standing in front of Haymir (see the option list at T.pilot)
--   T.talk / T.drive           H.converse from the first screen / from a given screen
--
-- Haymir's conversation lives in the template "haymir_convo_template", its handler is the global "haymirConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")

local T = {}

T.TEMPLATE = "haymir_convo_template"
T.HANDLER = "haymirConvoHandler"
T.PREFIX = "@conversation/corellia_imperial_tier3:"
T.STF = "conversation/corellia_imperial_tier3"

T.TEMPLATE_FILE = "mobile/conversations/space/imperial/black_epsilon_squadron/haymir_convo.lua"
T.HANDLER_FILE = "screenplays/space/conversations/imperial/black_epsilon_squadron/haymirConvoHandler.lua"
T.SQUADRON_FILE = "screenplays/space/squadrons/BlackEpsilonSquadronScreenplay.lua"
T.NPC_FILE = "mobile/space/haymir_rendundi.lua"
T.SHIP_FILE = "ship_mobile/ships/reb_yavinspy_tier4.lua"

local Y, L = "space_yavin4", "space_lok"

-- the 14 globals
T.M1 = {
	"patrol_corellia_imperial_tier3_1", "inspect_corellia_imperial_tier3_1_a", "delivery_no_pickup_corellia_imperial_tier3_1_b", "recovery_corellia_imperial_tier3_1_c",
}
T.M2 = {
	"recovery_corellia_imperial_tier3_2", "survival_corellia_imperial_tier3_2_a", "escort_corellia_imperial_tier3_2_b", "space_battle_corellia_imperial_tier3_2_c",
}
T.M3 = { "rescue_corellia_imperial_tier3_3", "assassinate_corellia_imperial_tier3_3_a" }
T.M4 = {
	"recovery_corellia_imperial_tier3_4", "assassinate_corellia_imperial_tier3_4_a", "survival_corellia_imperial_tier3_4_b", "assassinate_corellia_imperial_tier3_4_c",
}

T.CHAINS = { T.M1, T.M2, T.M3, T.M4 }

T.GLOBALS = {}

for _, chain in ipairs(T.CHAINS) do
	for _, g in ipairs(chain) do
		T.GLOBALS[#T.GLOBALS + 1] = g
	end
end

-- the 19 tier 1-2 globals (kept by the squadron file)
T.OLDER_GLOBALS = {
	"patrol_corellia_imperial_1", "destroy_surpriseattack_corellia_imperial_1", "destroy_corellia_imperial_2", "escort_corellia_imperial_3",
	"assassinate_corellia_imperial_4", "destroy_duty_corellia_imperial_6", "escort_duty_corellia_imperial_7",
	"recovery_corellia_imperial_16", "assassinate_corellia_imperial_12", "inspect_corellia_imperial_13", "assassinate_corellia_imperial_14",
	"patrol_corellia_imperial_15", "destroy_surpriseattack_corellia_imperial_15_split", "assassinate_corellia_imperial_17", "survival_corellia_tier2_final",
	"destroy_duty_corellia_imperial_8", "escort_duty_corellia_imperial_9", "destroy_duty_corellia_imperial_10", "escort_duty_corellia_imperial_11",
}

-- global -> { class, type, name, zone }
T.IDENTITY = {}

do
	local rows = {
		{ T.M1[1], "SpacePatrolScreenplay", "patrol", "corellia_imperial_tier3_1", Y },
		{ T.M1[2], "SpaceInspectScreenplay", "inspect", "corellia_imperial_tier3_1_a", Y },
		{ T.M1[3], "SpaceDeliveryNoPickupScreenplay", "delivery_no_pickup", "corellia_imperial_tier3_1_b", Y },
		{ T.M1[4], "SpaceRecoveryScreenplay", "recovery", "corellia_imperial_tier3_1_c", Y },
		{ T.M2[1], "SpaceRecoveryScreenplay", "recovery", "corellia_imperial_tier3_2", Y },
		{ T.M2[2], "SpaceSurvivalScreenplay", "survival", "corellia_imperial_tier3_2_a", Y },
		{ T.M2[3], "SpaceEscortScreenplay", "escort", "corellia_imperial_tier3_2_b", Y },
		{ T.M2[4], "SpaceBattleScreenplay", "space_battle", "corellia_imperial_tier3_2_c", Y },
		{ T.M3[1], "SpaceRescueScreenplay", "rescue", "corellia_imperial_tier3_3", Y },
		{ T.M3[2], "SpaceAssassinateScreenplay", "assassinate", "corellia_imperial_tier3_3_a", Y },
		{ T.M4[1], "SpaceRecoveryScreenplay", "recovery", "corellia_imperial_tier3_4", L },
		{ T.M4[2], "SpaceAssassinateScreenplay", "assassinate", "corellia_imperial_tier3_4_a", L },
		{ T.M4[3], "SpaceSurvivalScreenplay", "survival", "corellia_imperial_tier3_4_b", L },
		{ T.M4[4], "SpaceAssassinateScreenplay", "assassinate", "corellia_imperial_tier3_4_c", L },
	}

	for _, r in ipairs(rows) do
		T.IDENTITY[r[1]] = { class = r[2], type = r[3], name = r[4], zone = r[5] }
	end
end

-- Content contract 2: the squadron object's constants
T.QUEST_STRINGS = {
	TIER3_QUEST_STRING_1 = { type = "patrol", name = "corellia_imperial_tier3_1" },
	TIER3_QUEST_STRING_1_SIDE1 = { type = "inspect", name = "corellia_imperial_tier3_1_a" },
	TIER3_QUEST_STRING_1_SIDE2 = { type = "delivery_no_pickup", name = "corellia_imperial_tier3_1_b" },
	TIER3_QUEST_STRING_1_SIDE3 = { type = "recovery", name = "corellia_imperial_tier3_1_c" },
	TIER3_QUEST_STRING_2 = { type = "recovery", name = "corellia_imperial_tier3_2" },
	TIER3_QUEST_STRING_2_SIDE1 = { type = "survival", name = "corellia_imperial_tier3_2_a" },
	TIER3_QUEST_STRING_2_SIDE2 = { type = "escort", name = "corellia_imperial_tier3_2_b" },
	TIER3_QUEST_STRING_2_SIDE3 = { type = "space_battle", name = "corellia_imperial_tier3_2_c" },
	TIER3_QUEST_STRING_3 = { type = "rescue", name = "corellia_imperial_tier3_3" },
	TIER3_QUEST_STRING_3_SIDE1 = { type = "assassinate", name = "corellia_imperial_tier3_3_a" },
	TIER3_QUEST_STRING_4 = { type = "recovery", name = "corellia_imperial_tier3_4" },
	TIER3_QUEST_STRING_4_SIDE1 = { type = "assassinate", name = "corellia_imperial_tier3_4_a" },
	TIER3_QUEST_STRING_4_SIDE2 = { type = "survival", name = "corellia_imperial_tier3_4_b" },
	TIER3_QUEST_STRING_4_SIDE3 = { type = "assassinate", name = "corellia_imperial_tier3_4_c" },
}

-- The 8 status keys resetHaymirQuests removes (without the player id)
T.KEYS = {}

for n = 1, 4 do
	T.KEYS[#T.KEYS + 1] = "corellia_imperial_tier3_" .. n .. ":attempted"
	T.KEYS[#T.KEYS + 1] = "corellia_imperial_tier3_" .. n .. ":reward"
end

T.SERIES_SUFFIX = "BlackEpsilonSquadronScreenplay:imperial_corellia_1"
T.PRISK_SUFFIX = "BlackEpsilonSquadronScreenplay:workingForPrisk"

-- Data mapping 2: zone -> name -> { x, z, y }
T.POINTS = {
	[Y] = {
		corellia_imperial_tier3_leg_2_escort_1 = { -1823, -2113, -3292 },
		corellia_imperial_tier3_leg_2_escort_2 = { -361, -3496, -2017 },
		corellia_imperial_tier3_leg_2_escort_3 = { 63, -5425, -4321 },
		corellia_imperial_tier3_leg_2_escort_4 = { 2722, -5288, -2434 },
		naboo_imperial_tier3_delivery1_dropoff = { 1092, 842, 598 },
		corellia_imperial_tier3_rebofficer_1 = { -3922, -1205, 474 },
		corellia_imperial_tier3_rebofficer_2 = { 1010, -2208, -2998 },
		corellia_imperial_tier3_rebofficer_3 = { 6465, -2208, -5989 },
		corellia_imperial_tier3_rebofficer_4 = { 946, -189, -2000 },
		corellia_imperial_tier3_rebofficer_5 = { -7536, 1004, -2160 },
		corellia_imperial_tier3_huttcapture_1 = { 5510, 2491, 5897 },
		corellia_imperial_tier3_huttcapture_2 = { 5920, 6064, 983 },
		corellia_imperial_tier3_huttcapture_3 = { 6, 3639, -4482 },
		corellia_imperial_tier3_huttcapture_4 = { 5240, 30, -5035 },
		corellia_imperial_tier3_huttcapture_5 = { 5920, -4095, -6400 },
		corellia_imperial_tier3_huttcapture_6 = { 5213, -3312, -5283 },
		corellia_imperial_tier3_survival1 = { 5841, -1592, 3406 },
		corellia_imperial_tier3_leg_2_rescue_1 = { -2338, -1448, -1092 },
		corellia_imperial_tier3_leg_2_rescue_2 = { -3882, -3866, -1432 },
		corellis_imperial_tier3_leg_2_rescue_3 = { 1463, -2058, -568 },
		corellia_imperial_tier3_leg_2_rescue_4 = { 3230, -310, 2173 },
		corellia_imperial_tier3_leg_2_space_battle = { -3042, 929, 2254 },
		corellia_imperial_tier3_rescue_1 = { -1199, 3999, 2199 },
		corellia_imperial_tier3_rescue_2 = { -1011, 6173, 3600 },
		corellia_imperial_tier3_rescue_3 = { -2525, 5980, 3574 },
		corellia_imperial_tier3_rescue_4 = { -6994, 3814, 709 },
		corellia_imperial_tier3_assassinate_1 = { 1368, 4871, -2247 },
		corellia_imperial_tier3_assassinate_2 = { 2000, 6784, -3488 },
		corellia_imperial_tier3_assassinate_3 = { 3697, 6816, -3821 },
		corellia_imperial_tier3_assassinate_4 = { 7488, 6640, -2192 },
	},
	[L] = {
		lok_imp_escort_duty_7 = { 4763, -1727, 3174 },
		lok_imp_escort_duty_8 = { -4979, -2229, 1961 },
		lok_imp_escort_duty_9 = { -5439, -2664, -5525 },
		lok_imp_recovery_1 = { 1779, 289, -1042 },
		lok_imp_recovery_2 = { 2371, 588, -251 },
		lok_imp_recovery_7 = { -997, 669, 653 },
		lok_imp_recovery_8 = { 104, -139, 864 },
		lok_imp_recovery_9 = { 944, -1189, 856 },
		corellia_imperial_tier3_survival1 = { -4511, 3086, -2187 },
		corellia_tier3_assassinate2_1 = { 2767, 5195, -2260 },
		corellia_imperial_tier3_assassinate2_2 = { 5567, -1556, -7266 },
		corellia_imperial_tier3_assassinate2_3 = { 4172, 4062, -4134 },
	},
}

T.SPAWNER = { name = "corellia_imperial_tier3_officerinspect", x = -2000, z = -4500, y = 3000 }

T.ITEMS = {
	[1] = "object/tangible/ship/components/weapon_capacitor/cap_mission_reward_imperial_rendili_k_class.iff",
	[2] = "object/tangible/ship/components/droid_interface/ddi_mission_reward_imperial_sfs_military_grade.iff",
	[3] = "object/tangible/ship/components/reactor/rct_mission_reward_imperial_sds_high_output.iff",
	[4] = "object/tangible/ship/components/engine/eng_mission_reward_imperial_cygnus_megadrive.iff",
}

T.CREDITS = 25000
T.STANDING = 100
T.FORWARD = { x = 0.020425, z = -0.111783, y = -0.993523 }

local function point(zone, name, extra)
	local p = T.POINTS[zone][name]

	assert(p ~= nil, "no spec point " .. zone .. ":" .. name)

	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra or {}) do
		t[k] = v
	end

	return t
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

local function numbered(prefix, from, to)
	local out = {}

	for i = from, to do
		out[#out + 1] = prefix .. i
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

local function item(n) return { { species = { -1 }, item = T.ITEMS[n] } } end

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function T.expected()
	local PATROL_POINT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT
	local COMPLETION = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION

	local function base(global, more)
		local id = T.IDENTITY[global]
		local t = { className = global, questType = id.type, questName = id.name, questZone = id.zone }

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

	local function split(nextGlobal, delay)
		local nid = T.IDENTITY[nextGlobal]

		return { sideQuest = true, sideQuestType = nid.type, sideQuestName = nid.name, sideQuestSplitType = COMPLETION, sideQuestDelay = delay or 5 }
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

	local END = { sideQuest = false, sideQuestType = "" }
	local seq = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local taunt2 = { panicCount = 5, thanksCount = 5 }
	local out = {}

	-- Mission 1
	out[T.M1[1]] = base(T.M1[1], {
		creditReward = T.CREDITS, itemReward = item(1),
		sideQuest = true, sideQuestType = "inspect", sideQuestName = "corellia_imperial_tier3_1_a",
		sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 3, sideQuestDelay = 20,
		patrolPoints = pts(Y, numbered("corellia_imperial_tier3_leg_2_escort_", 1, 4), { radius = 150 }, "patrolNumber"),
	})
	out[T.M1[2]] = base(T.M1[2], merge(child(T.M1[1], {}), split(T.M1[3]), {
		shipList = { "reb_yavinspy_tier4" },
		validSpawns = { { spawnName = T.SPAWNER.name, x = T.SPAWNER.x, z = T.SPAWNER.z, y = T.SPAWNER.y } },
		giveSpawnWaypoint = 1, cargo = "joint_operations_plans",
	}))
	out[T.M1[3]] = base(T.M1[3], merge(child(T.M1[2], {}), split(T.M1[4]), {
		deliveryShip = "imp_lambda_shuttle_tier3",
		deliveryPoint = point(Y, "naboo_imperial_tier3_delivery1_dropoff"),
		attackShipLists = {
			{ "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4" },
			{ "reb_ywing_tier3", "reb_ywing_tier3", "reb_xwing_tier3", "reb_xwing_tier3" },
		},
		attackPeriod = 90, attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
	}))
	out[T.M1[4]] = base(T.M1[4], merge(child(T.M1[3], {}), END, {
		arrivalDelay = 20, recoveryDelay = 15, recoverShip = "reb_ywingleader_tier4",
		escortShips = { "reb_xwing_tier3", "reb_xwing_tier3", "reb_ywing_tier3", "reb_ywing_tier3" },
		preRecoveryPoints = pts(Y, numbered("corellia_imperial_tier3_rebofficer_", 1, 3), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(Y, { "corellia_imperial_tier3_rebofficer_4", "corellia_imperial_tier3_rebofficer_5" }, { radius = 250 }, "escortNumber"),
		attackDelay = 90,
		attackShips = { { "reb_awing_tier3", "reb_awing_tier3" }, { "reb_xwing_tier3", "reb_xwing_tier3" } },
		tauntData = taunt2,
	}))

	-- Mission 2
	out[T.M2[1]] = base(T.M2[1], merge({ creditReward = T.CREDITS, itemReward = item(2) }, split(T.M2[2]), {
		arrivalDelay = 15, recoveryDelay = 30, recoverShip = "huttsmuggler_tier3",
		escortShips = rep("huttskiff_tier3", 4),
		preRecoveryPoints = pts(Y, numbered("corellia_imperial_tier3_huttcapture_", 1, 3), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(Y, numbered("corellia_imperial_tier3_huttcapture_", 4, 6), { radius = 250 }, "escortNumber"),
		attackDelay = 90,
		attackShips = {
			rep("huttgunship_tier3", 3),
			{ "huttskiff_tier3", "huttskiff_tier3", "huttgunship_tier3", "huttgunship_tier3" },
			rep("huttfighter_tier3", 4),
		},
		tauntData = taunt2,
	}))
	out[T.M2[2]] = base(T.M2[2], merge(child(T.M2[1], {}), split(T.M2[3]), {
		transmissionPoint = point(Y, "corellia_imperial_tier3_survival1"),
		totalTransmissionTime = 300, timesToUpdateProgress = 10, transmissionStartDelay = 25, delayToFirstAttack = 45,
		attackShipLists = {
			{ "nym_blastboat_tier3", "nym_blastboat_tier3", "nym_enforcer_tier3", "nym_enforcer_tier3" },
			{ "nym_fighter_tier3", "nym_fighter_tier3", "nym_fighter_tier3", "nym_fighter_tier4" },
		},
		attackPeriod = 90, attackListType = seq,
	}))
	out[T.M2[3]] = base(T.M2[3], merge(child(T.M2[2], {}), split(T.M2[4]), {
		escortShips = { "imp_huttsmuggler_tier3" },
		escortPoints = pts(Y, { "corellia_imperial_tier3_leg_2_rescue_1", "corellia_imperial_tier3_leg_2_rescue_2", "corellis_imperial_tier3_leg_2_rescue_3",
			"corellia_imperial_tier3_leg_2_rescue_4" }, { zoneName = Y, radius = 250 }, "escortNumber"),
		attackDelay = 90,
		attackShips = { { "nym_enforcer_tier3", "nym_enforcer_tier3", "nym_enforcer_tier3", "nym_enforcer_captain_tier4" } },
		tauntData = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 },
	}))
	out[T.M2[4]] = base(T.M2[4], merge(child(T.M2[3], {}), END, {
		battlePoint = point(Y, "corellia_imperial_tier3_leg_2_space_battle", { forward = T.FORWARD }),
		damageMultiplier = 5, allyArrivalDelay = 30, enemyArrivalDelay = 90,
		allyOriginDist = 400, enemyOriginDist = -400, allyArrivalDist = 200, enemyArrivalDist = 300,
		allyForce = rep("hutt_fighter_s02_tier4", 4),
		enemyForce = cat(rep("nym_enforcer_tier4", 7), { "nym_enforcer_captain_tier4" }),
	}))

	-- Mission 3
	out[T.M3[1]] = base(T.M3[1], merge({ creditReward = T.CREDITS, itemReward = item(3) }, split(T.M3[2]), {
		recoveryPath = pts(Y, numbered("corellia_imperial_tier3_rescue_", 1, 4)),
		targetShipType = "imp_freightermedium_tier3", targetArrivalDelay = 15,
		attackShipLists = {
			{ "nym_bomber_tier3", "nym_enforcer_tier3", "nym_enforcer_captain_tier4", "nym_enforcer_tier3", "nym_enforcer_tier3" },
			{ "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_bwing_tier3" },
		},
		attackPeriod = 90, attackListType = SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, numResponses = 5,
	}))
	out[T.M3[2]] = base(T.M3[2], merge(child(T.M3[1], {}), END, {
		arrivalDelay = 20, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = "reb_emissary_tier4", escorts = { "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_bwing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3" } },
		targetPatrols = pts(Y, numbered("corellia_imperial_tier3_assassinate_", 1, 4)),
	}))

	-- Mission 4
	out[T.M4[1]] = base(T.M4[1], merge({ creditReward = T.CREDITS, itemReward = item(4) }, split(T.M4[2]), {
		arrivalDelay = 20, recoveryDelay = 30, recoverShip = "nym_smuggle_transport_capture_tier4",
		escortShips = rep("nym_fighter_tier3", 7),
		preRecoveryPoints = pts(L, numbered("lok_imp_escort_duty_", 7, 9), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(L, { "lok_imp_recovery_1", "lok_imp_recovery_2" }, { radius = 250 }, "escortNumber"),
		attackDelay = 120, attackShips = { rep("nym_fighter_tier3", 4) },
		tauntData = taunt2,
	}))
	out[T.M4[2]] = base(T.M4[2], merge(child(T.M4[1], {}), split(T.M4[3]), {
		arrivalDelay = 20, failTimer = 20, mustDestroyEscort = false,
		assassinateSpawns = { target = "nym_patrol_craft_tier4", escorts = rep("nym_enforcer_tier3", 5) },
		targetPatrols = pts(L, numbered("lok_imp_recovery_", 7, 9)),
	}))
	out[T.M4[3]] = base(T.M4[3], merge(child(T.M4[2], {}), split(T.M4[4]), {
		transmissionPoint = point(L, "corellia_imperial_tier3_survival1"),
		totalTransmissionTime = 600, timesToUpdateProgress = 20, transmissionStartDelay = 25, delayToFirstAttack = 45,
		attackShipLists = {
			cat(rep("nym_fighter_tier3", 4), { "nym_fighter_tier4" }),
			cat(rep("nym_enforcer_tier3", 4), { "nym_enforcer_captain_tier4" }),
		},
		attackPeriod = 120, attackListType = seq,
	}))
	out[T.M4[4]] = base(T.M4[4], merge(child(T.M4[3], {}), END, {
		arrivalDelay = 20, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = "nym_karthakk_queen_tier4", escorts = cat(rep("nym_fighter_tier3", 3), rep("nym_enforcer_tier3", 2)) },
		targetPatrols = pts(L, { "corellia_tier3_assassinate2_1", "corellia_imperial_tier3_assassinate2_2", "corellia_imperial_tier3_assassinate2_3" }),
	}))

	return out
end

-- MISSIONS of the handler (Content contract 3). status = the :attempted / :reward key stem.
T.MISSIONS = {
	{ n = 1, head = T.M1[1], questString = "TIER3_QUEST_STRING_1", endString = "TIER3_QUEST_STRING_1_SIDE3", chain = T.M1, status = "corellia_imperial_tier3_1",
		offer = "m1_offer", accept = "m1_accept", failed = "m1_failed", reward = "m1_reward", retries = { "m1_retry_excuse", "m1_retry" }, zone = Y },
	{ n = 2, head = T.M2[1], questString = "TIER3_QUEST_STRING_2", endString = "TIER3_QUEST_STRING_2_SIDE3", chain = T.M2, status = "corellia_imperial_tier3_2",
		offer = "m2_offer", accept = "m2_accept", failed = "m2_failed", reward = "m2_reward", retries = { "m2_retry_sarcastic", "m2_retry" }, zone = Y },
	{ n = 3, head = T.M3[1], questString = "TIER3_QUEST_STRING_3", endString = "TIER3_QUEST_STRING_3_SIDE1", chain = T.M3, status = "corellia_imperial_tier3_3",
		offer = "m3_offer", accept = "m3_accept", failed = "m3_failed", reward = "m3_reward", retries = { "m3_retry", "m3_retry_rebels" }, zone = Y },
	{ n = 4, head = T.M4[1], questString = "TIER3_QUEST_STRING_4", endString = "TIER3_QUEST_STRING_4_SIDE3", chain = T.M4, status = "corellia_imperial_tier3_4",
		offer = "m4_offer", accept = "m4_accept", failed = "m4_failed", reward = "m4_reward", retries = { "m4_retry", "m4_retry_promise" }, zone = L },
}

-- TRAIN_CHOICES in menu order (Content contract 3): the topic reply grants
T.TRAIN = {
	{ x = "starships", skill = "pilot_imperial_navy_starships_03", reply = "s_adc23ed9", trained = "trained_starships", trainedSid = "s_7fe8c9bb" },
	{ x = "weapons", skill = "pilot_imperial_navy_weapons_03", reply = "s_77f35957", trained = "trained_weapons", trainedSid = "s_84ce496b" },
	{ x = "procedures", skill = "pilot_imperial_navy_procedures_03", reply = "s_3f4fdcbd", trained = "trained_procedures", trainedSid = "s_9d2d47d4" },
	{ x = "droid", skill = "pilot_imperial_navy_droid_03", reply = "s_2dd8b42", trained = "trained_droid", trainedSid = "s_f00894a4" },
}

-- the training screens (C-1) and the reward screens that lead to them
T.TRAINING_SCREENS = { "m1_training", "m2_training", "m3_training", "m4_training", "m4_training_philosophy" }

-- the four _02 skills in TRAIN order, the four _01 skills
T.TIER2_SKILLS = {
	"pilot_imperial_navy_starships_02", "pilot_imperial_navy_weapons_02", "pilot_imperial_navy_procedures_02", "pilot_imperial_navy_droid_02",
}

T.TIER1_SKILLS = {
	"pilot_imperial_navy_starships_01", "pilot_imperial_navy_weapons_01", "pilot_imperial_navy_procedures_01", "pilot_imperial_navy_droid_01",
}

T.NOVICE = "pilot_imperial_navy_novice"

-- Appendix A
T.SCREENS = require("black_epsilon_tier3_screens_data")

function T.screenRow(id)
	for _, row in ipairs(T.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (74), sorted
function T.screenIds()
	local out = {}

	for i, row in ipairs(T.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

T.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		T.loadErrors[#T.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: the four squadron files, the Haymir template, the Haymir handler. A missing production file is recorded in
-- T.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function T.load()
	if loaded then
		return
	end

	loaded = true
	H.boot()

	-- Factions::FACTIONIMPERIAL / FACTIONREBEL come from C++ values the harness cannot resolve; the fake ships use the same crc
	if rawget(_G, "FACTIONIMPERIAL") == nil then
		rawset(_G, "FACTIONIMPERIAL", getHashCode("imperial"))
	end

	if rawget(_G, "FACTIONREBEL") == nil then
		rawset(_G, "FACTIONREBEL", getHashCode("rebel"))
	end

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay" }) do
		try(name, function() H.loadSquadron(name) end)
	end

	try("haymir_convo.lua", function() H.loadMobile("conversations/space/imperial/black_epsilon_squadron/haymir_convo.lua") end)
	try("haymirConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/black_epsilon_squadron/haymirConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function T.requireConversation(lu)
	T.load()
	lu.assertNotNil(H.conversationTemplateTable(T.TEMPLATE), T.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. table.concat(T.loadErrors, " | "))
	lu.assertNotNil(rawget(_G, T.HANDLER), T.HANDLER .. " is not defined. Load problems: " .. table.concat(T.loadErrors, " | "))
end

function T.quest(global)
	T.load()

	return H.expectGlobal(global, "Black Epsilon tier 3 quest table (black-epsilon-tier3-haymir). Load problems: " .. table.concat(T.loadErrors, " | "))
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = T.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

T.crc = crc

-- Quest state helpers on a built pilot. state: "complete" | "active" | "none"
function T.setState(player, global, state)
	local key = crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function T.state(player, global)
	local key = crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- Options (all optional; the default is a Black Epsilon pilot with a ship, standing 0, the four tier 1 and four tier 2 skills, pilot tier 3,
-- nothing of tier 3 done):
--   pilot      "imperial" (default) | "neutral" | "rebel" | false (not a pilot)
--   faction    "imperial" (default) | "rebel" | "neutral" (no faction)
--   squadron   true (default: BLACK_EPSILON_SQUADRON) | false (none) | a squadron constant
--   standing   Imperial faction standing (default 0)
--   ship       certified ship (default true)
--   tier1      number of tier 1 skills held (default 4)
--   t2         number of tier 2 skills held, in TRAIN order (default 4)
--   t3         list of TRAIN indexes (1 starships, 2 weapons, 3 procedures, 4 droid) of the tier 3 skills held
--   mission    { [n] = state } for n = 1..4. "won": the whole chain is complete and :attempted is set; "failed" / "attempted": :attempted only;
--              "active": :attempted and the head active; "endonly": only the chain end complete (no :attempted); "partial": the head complete,
--              the end not
--   paid       list of n (1..4) whose reward is paid: the chain is complete, :attempted and :reward are set
--   xp         space_combat_general experience (default 0)
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   duty       global of a quest held active in the journal (any global)
--   species    SPECIES_* (default SPECIES_HUMAN)
--   pilotTier  ghost pilot tier (default 3)
--   inventory  (default true)
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
--   series     the tier 1 series-complete flag (default true)
function T.pilot(o)
	o = o or {}
	T.load()

	local pilotKind = o.pilot

	if pilotKind == nil then
		pilotKind = "imperial"
	elseif pilotKind == false then
		pilotKind = nil
	end

	local faction = ({ imperial = FACTIONIMPERIAL, rebel = FACTIONREBEL })[o.faction or "imperial"] or 0
	local squadron = o.squadron

	if squadron == nil or squadron == true then
		squadron = BLACK_EPSILON_SQUADRON
	elseif squadron == false then
		squadron = 0
	end

	local skills = {}

	if pilotKind ~= nil then
		skills[1] = T.NOVICE

		for i = 1, (o.tier1 == nil and 4 or o.tier1) do
			skills[#skills + 1] = T.TIER1_SKILLS[i]
		end

		for i = 1, (o.t2 == nil and 4 or o.t2) do
			skills[#skills + 1] = T.TIER2_SKILLS[i]
		end

		for _, i in ipairs(o.t3 or {}) do
			skills[#skills + 1] = T.TRAIN[i].skill
		end
	end

	local completed, active, status = {}, {}, {}
	local states = {}

	for _, n in ipairs(o.paid or {}) do
		states[n] = "paid"
	end

	for n, state in pairs(o.mission or {}) do
		states[n] = state
	end

	for n, state in pairs(states) do
		local m = T.MISSIONS[n]
		local chain = m.chain

		if state ~= "endonly" then
			status[m.status .. ":attempted"] = "1"
		end

		if state == "paid" then
			status[m.status .. ":reward"] = "1"
		end

		if state == "won" or state == "paid" then
			for _, g in ipairs(chain) do
				completed[#completed + 1] = crc(g)
			end
		elseif state == "endonly" then
			completed[#completed + 1] = crc(chain[#chain])
		elseif state == "partial" then
			completed[#completed + 1] = crc(chain[1])
		elseif state == "active" then
			active[#active + 1] = crc(chain[1])
		end
	end

	if o.series ~= false then
		status[T.SERIES_SUFFIX] = "1"
	end

	if o.duty then
		active[#active + 1] = crc(o.duty)
	end

	local player = H.newPlayer({
		name = "Ace",
		pilot = pilotKind,
		faction = faction,
		squadronType = squadron,
		pilotTier = o.pilotTier or 3,
		certifiedShip = o.ship ~= false,
		skills = skills,
		experience = { space_combat_general = o.xp or 0 },
		factionStanding = { imperial = o.standing or 0, rebel = 0 },
		completedQuests = completed,
		activeQuests = active,
		questStatus = status,
		species = o.species or SPECIES_HUMAN,
		gender = 0,
		inventory = o.inventory ~= false and (o.inventory or true) or nil,
		zone = o.zone,
		ship = o.inShip and (type(o.inShip) == "table" and o.inShip or true) or nil,
	})

	if o.datapad == "duty" then
		DRS.holdDuty(player, "held_by_test")
	elseif o.datapad == "story" then
		DRS.holdStory(player, "story_held_by_test")
	end

	return player
end

function T.npc() return H.newNpc({ name = "Haymir" }) end

function T.requireConversationLoaded()
	T.load()

	if H.conversationTemplateTable(T.TEMPLATE) == nil or rawget(_G, T.HANDLER) == nil then
		error("Haymir conversation is not loaded. Load problems: " .. table.concat(T.loadErrors, " | "), 3)
	end
end

-- Talks to Haymir from the first screen. choices as for H.converse.
function T.talk(player, choices)
	T.requireConversationLoaded()

	return H.converse({ template = T.TEMPLATE, player = player, npc = T.npc(), choices = choices })
end

-- The id of the first screen of a fresh talk
function T.firstScreen(player)
	return T.talk(player)[1].id
end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session.
function T.drive(player, startId, choices)
	T.requireConversationLoaded()

	local tmpl = H.conversationTemplate(T.TEMPLATE)
	local handler = rawget(_G, T.HANDLER)
	local npc = T.npc()
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
		error("screen '" .. startId .. "' is not in " .. T.TEMPLATE, 2)
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

				for k, opt in ipairs(screen.options) do
					if opt.text == choice or opt.text:sub(-#choice - 1) == ":" .. choice then
						found = k - 1
						break
					end
				end

				if found == nil then
					local have = {}

					for k, opt in ipairs(screen.options) do
						have[k] = tostring(opt.text)
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

-- ids of a transcript
function T.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- the option sids ("s_xxx") of a transcript step, in order
function T.optionSids(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = tostring(o.text):match(":(s_[%w_]+)$") or tostring(o.text)
	end

	return out
end

function T.linksOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = o.link
	end

	return out
end

-- Tier 3 skills (of the four) the player holds, in T.TRAIN order
function T.held(player)
	local out = {}

	for _, t in ipairs(T.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

-- Spies on the startQuest of the listed globals (H.spyOn does not call the original)
function T.spyStarts(globals)
	local spies = {}

	for _, g in ipairs(globals or T.GLOBALS) do
		spies[g] = H.spyOn(T.quest(g), "startQuest")
	end

	return spies
end

-- the sorted list of globals whose startQuest was called, one entry per call
function T.started(spies)
	local out = {}

	for g, calls in pairs(spies) do
		for _ = 1, #calls do
			out[#out + 1] = g
		end
	end

	table.sort(out)
	return out
end

return T
