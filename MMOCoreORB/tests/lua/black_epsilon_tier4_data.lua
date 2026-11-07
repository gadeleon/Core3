-- Shared test data and builders for Black Epsilon tier 4 (Nin Gursawe, "Insurgent"), not a test file.
-- Spec: .claude/work/black-epsilon-tier4-nin-gursawe/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A, B and D).
--
-- Scalars, point names and coordinates are copied from the spec, not read from the production scripts, so a wrong production value fails a
-- test instead of agreeing with itself. The long ship lists (attack waves, escorts, forces) are derived from the SWG .tab fixtures by the
-- same column rules the spec's Data mapping 1 states; their sizes are anchored separately (T.LIST_SIZES, Appendix B).
--   T.GLOBALS / T.IDENTITY     the 19 quest globals and their class, type, name and zone (Content contract 1)
--   T.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   T.POINTS / T.SPAWNERS      Data mapping 2: the points per zone and the 3 spawners, Core3 x, z, y
--   T.SCREENS                  Appendix A (black_epsilon_tier4_screens_data.lua, generated from the spec table)
--   T.PATHS                    Appendix D: one reply path per grant screen
--   T.MISSIONS / T.TRAIN       MISSIONS and TRAIN_CHOICES of the handler (Content contract 3)
--   T.load()                   the server's load of the squadron, the template and the handler, collecting load errors
--   T.pilot{...}               a pilot standing in front of the Insurgent (see the option list at T.pilot)
--   T.talk / T.drive           H.converse from the first screen / from a given screen
--
-- Nin Gursawe's conversation lives in the template "nin_gursawe_convo_template", its handler is the global "ninGursaweConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")

local T = {}

T.TEMPLATE = "nin_gursawe_convo_template"
T.HANDLER = "ninGursaweConvoHandler"
T.PREFIX = "@conversation/corellia_imperial_tier4:"
T.STF = "conversation/corellia_imperial_tier4"

T.TEMPLATE_FILE = "mobile/conversations/space/imperial/black_epsilon_squadron/nin_gursawe_convo.lua"
T.HANDLER_FILE = "screenplays/space/conversations/imperial/black_epsilon_squadron/ninGursaweConvoHandler.lua"
T.SQUADRON_FILE = "screenplays/space/squadrons/BlackEpsilonSquadronScreenplay.lua"
T.NPC_FILE = "mobile/space/insurgent.lua"

local D, H4 = "space_dantooine", "space_dathomir"

-- the 15 story globals, per mission chain
T.M1 = { "patrol_corellia_imperial_tier4_1", "inspect_corellia_imperial_tier4_1_a", "survival_corellia_imperial_tier4_1_b" }
T.M2 = { "recovery_corellia_imperial_tier4_2", "inspect_corellia_imperial_tier4_2_a", "delivery_no_pickup_corellia_imperial_tier4_2_b" }
T.M3 = { "escort_corellia_imperial_tier4_3", "rescue_corellia_imperial_tier4_3_a", "patrol_corellia_imperial_tier4_3_b", "inspect_corellia_imperial_tier4_3_c" }
T.M4 = {
	"assassinate_corellia_imperial_tier4_4", "recovery_corellia_imperial_tier4_4_a", "destroy_surpriseattack_corellia_imperial_tier4_4_b",
	"space_battle_corellia_imperial_tier4_4_c", "assassinate_corellia_imperial_tier4_4_d",
}

T.CHAINS = { T.M1, T.M2, T.M3, T.M4 }

T.DUTIES = {
	"destroy_duty_corellia_imperial_tier4_1", "escort_duty_corellia_imperial_tier4_2", "recovery_duty_corellia_imperial_tier4_3", "rescue_duty_corellia_imperial_tier4_4",
}

T.STORY = {}
T.GLOBALS = {}

for _, chain in ipairs(T.CHAINS) do
	for _, g in ipairs(chain) do
		T.STORY[#T.STORY + 1] = g
		T.GLOBALS[#T.GLOBALS + 1] = g
	end
end

for _, g in ipairs(T.DUTIES) do
	T.GLOBALS[#T.GLOBALS + 1] = g
end

-- the 33 tier 1-3 globals (kept by the squadron file)
T.OLDER_GLOBALS = {
	"patrol_corellia_imperial_1", "destroy_surpriseattack_corellia_imperial_1", "destroy_corellia_imperial_2", "escort_corellia_imperial_3",
	"assassinate_corellia_imperial_4", "destroy_duty_corellia_imperial_6", "escort_duty_corellia_imperial_7",
	"recovery_corellia_imperial_16", "assassinate_corellia_imperial_12", "inspect_corellia_imperial_13", "assassinate_corellia_imperial_14",
	"patrol_corellia_imperial_15", "destroy_surpriseattack_corellia_imperial_15_split", "assassinate_corellia_imperial_17", "survival_corellia_tier2_final",
	"destroy_duty_corellia_imperial_8", "escort_duty_corellia_imperial_9", "destroy_duty_corellia_imperial_10", "escort_duty_corellia_imperial_11",
	"patrol_corellia_imperial_tier3_1", "inspect_corellia_imperial_tier3_1_a", "delivery_no_pickup_corellia_imperial_tier3_1_b", "recovery_corellia_imperial_tier3_1_c",
	"recovery_corellia_imperial_tier3_2", "survival_corellia_imperial_tier3_2_a", "escort_corellia_imperial_tier3_2_b", "space_battle_corellia_imperial_tier3_2_c",
	"rescue_corellia_imperial_tier3_3", "assassinate_corellia_imperial_tier3_3_a",
	"recovery_corellia_imperial_tier3_4", "assassinate_corellia_imperial_tier3_4_a", "survival_corellia_imperial_tier3_4_b", "assassinate_corellia_imperial_tier3_4_c",
}

-- global -> { class, type, name, zone }
T.IDENTITY = {}

do
	local rows = {
		{ T.M1[1], "SpacePatrolScreenplay", "patrol", "corellia_imperial_tier4_1", D },
		{ T.M1[2], "SpaceInspectScreenplay", "inspect", "corellia_imperial_tier4_1_a", D },
		{ T.M1[3], "SpaceSurvivalScreenplay", "survival", "corellia_imperial_tier4_1_b", D },
		{ T.M2[1], "SpaceRecoveryScreenplay", "recovery", "corellia_imperial_tier4_2", D },
		{ T.M2[2], "SpaceInspectScreenplay", "inspect", "corellia_imperial_tier4_2_a", D },
		{ T.M2[3], "SpaceDeliveryNoPickupScreenplay", "delivery_no_pickup", "corellia_imperial_tier4_2_b", D },
		{ T.M3[1], "SpaceEscortScreenplay", "escort", "corellia_imperial_tier4_3", H4 },
		{ T.M3[2], "SpaceRescueScreenplay", "rescue", "corellia_imperial_tier4_3_a", H4 },
		{ T.M3[3], "SpacePatrolScreenplay", "patrol", "corellia_imperial_tier4_3_b", H4 },
		{ T.M3[4], "SpaceInspectScreenplay", "inspect", "corellia_imperial_tier4_3_c", H4 },
		{ T.M4[1], "SpaceAssassinateScreenplay", "assassinate", "corellia_imperial_tier4_4", H4 },
		{ T.M4[2], "SpaceRecoveryScreenplay", "recovery", "corellia_imperial_tier4_4_a", H4 },
		{ T.M4[3], "SpaceSurpriseAttackScreenplay", "destroy_surpriseattack", "corellia_imperial_tier4_4_b", H4 },
		{ T.M4[4], "SpaceBattleScreenplay", "space_battle", "corellia_imperial_tier4_4_c", H4 },
		{ T.M4[5], "SpaceAssassinateScreenplay", "assassinate", "corellia_imperial_tier4_4_d", H4 },
		{ T.DUTIES[1], "SpaceDutyDestroyScreenplay", "destroy_duty", "corellia_imperial_tier4_1", D },
		{ T.DUTIES[2], "SpaceDutyEscortScreenplay", "escort_duty", "corellia_imperial_tier4_2", D },
		{ T.DUTIES[3], "SpaceDutyRecoveryScreenplay", "recovery_duty", "corellia_imperial_tier4_3", D },
		{ T.DUTIES[4], "SpaceDutyRescueScreenplay", "rescue_duty", "corellia_imperial_tier4_4", D },
	}

	for _, r in ipairs(rows) do
		T.IDENTITY[r[1]] = { class = r[2], type = r[3], name = r[4], zone = r[5] }
	end
end

-- Content contract 2: the squadron object's constants
T.QUEST_STRINGS = {
	TIER4_QUEST_STRING_1 = { type = "patrol", name = "corellia_imperial_tier4_1" },
	TIER4_QUEST_STRING_1_SIDE1 = { type = "inspect", name = "corellia_imperial_tier4_1_a" },
	TIER4_QUEST_STRING_1_SIDE2 = { type = "survival", name = "corellia_imperial_tier4_1_b" },
	TIER4_QUEST_STRING_2 = { type = "recovery", name = "corellia_imperial_tier4_2" },
	TIER4_QUEST_STRING_2_SIDE1 = { type = "inspect", name = "corellia_imperial_tier4_2_a" },
	TIER4_QUEST_STRING_2_SIDE2 = { type = "delivery_no_pickup", name = "corellia_imperial_tier4_2_b" },
	TIER4_QUEST_STRING_3 = { type = "escort", name = "corellia_imperial_tier4_3" },
	TIER4_QUEST_STRING_3_SIDE1 = { type = "rescue", name = "corellia_imperial_tier4_3_a" },
	TIER4_QUEST_STRING_3_SIDE2 = { type = "patrol", name = "corellia_imperial_tier4_3_b" },
	TIER4_QUEST_STRING_3_SIDE3 = { type = "inspect", name = "corellia_imperial_tier4_3_c" },
	TIER4_QUEST_STRING_4 = { type = "assassinate", name = "corellia_imperial_tier4_4" },
	TIER4_QUEST_STRING_4_SIDE1 = { type = "recovery", name = "corellia_imperial_tier4_4_a" },
	TIER4_QUEST_STRING_4_SIDE2 = { type = "destroy_surpriseattack", name = "corellia_imperial_tier4_4_b" },
	TIER4_QUEST_STRING_4_SIDE3 = { type = "space_battle", name = "corellia_imperial_tier4_4_c" },
	TIER4_QUEST_STRING_4_SIDE4 = { type = "assassinate", name = "corellia_imperial_tier4_4_d" },
	TIER4_QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "corellia_imperial_tier4_1" },
	TIER4_QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "corellia_imperial_tier4_2" },
	TIER4_QUEST_STRING_DUTY_3 = { type = "recovery_duty", name = "corellia_imperial_tier4_3" },
	TIER4_QUEST_STRING_DUTY_4 = { type = "rescue_duty", name = "corellia_imperial_tier4_4" },
	TIER4_INTRO_KEY = "BlackEpsilonSquadronScreenplay:meetInsurgent",
	TIER4_MET_KEY = "BlackEpsilonSquadronScreenplay:metTier4",
	TIER4_DECLANN_KEY = "BlackEpsilonSquadronScreenplay:workingForAdmiralDeclann",
}

T.INTRO_SUFFIX = T.QUEST_STRINGS.TIER4_INTRO_KEY
T.MET_SUFFIX = T.QUEST_STRINGS.TIER4_MET_KEY
T.DECLANN_SUFFIX = T.QUEST_STRINGS.TIER4_DECLANN_KEY

-- The 11 status keys resetNinGursaweQuests removes (without the player id)
T.KEYS = {}

for n = 1, 4 do
	T.KEYS[#T.KEYS + 1] = "corellia_imperial_tier4_" .. n .. ":attempted"
	T.KEYS[#T.KEYS + 1] = "corellia_imperial_tier4_" .. n .. ":reward"
end

T.KEYS[#T.KEYS + 1] = T.INTRO_SUFFIX
T.KEYS[#T.KEYS + 1] = T.MET_SUFFIX
T.KEYS[#T.KEYS + 1] = T.DECLANN_SUFFIX

-- Data mapping 2: zone -> name -> { x, z, y } (all names carry the prefix corellia_imperial_tier4_)
local P = "corellia_imperial_tier4_"

T.POINTS = {
	[D] = {
		[P .. "patrol1_1"] = { 286, 4652, -2476 }, [P .. "patrol1_2"] = { 1604, 6571, -2128 }, [P .. "patrol1_3"] = { 2515, 7401, -1887 },
		[P .. "patrol1_4"] = { 1332, 6277, -3342 }, [P .. "survival1"] = { 6539, 6763, -1866 },
		[P .. "recovery1_1"] = { -6362, -477, 3393 }, [P .. "recovery1_2"] = { 1014, -431, 1398 }, [P .. "recovery1_3"] = { 4953, -1996, -3978 },
		[P .. "recovery1_4"] = { 6538, -1692, -3169 }, [P .. "recovery1_5"] = { 6068, -1909, -6308 }, [P .. "recovery1_6"] = { 6312, -1058, -6910 },
		[P .. "delivery1"] = { 2761, -325, 7265 },
		[P .. "escortduty_1"] = { 1919, 1533, -3439 }, [P .. "escortduty_2"] = { 2450, 2475, -4817 }, [P .. "escortduty_3"] = { 3378, 4066, -6793 },
		[P .. "escortduty_4"] = { 4175, 4817, -7440 },
		[P .. "recoveryduty1_1"] = { 912, -2978, 5685 }, [P .. "recoveryduty1_2"] = { -503, -4395, 4666 }, [P .. "recoveryduty1_3"] = { -2288, -6182, 3382 },
		[P .. "recoveryduty1_4"] = { -4084, -7307, 2090 }, [P .. "recoveryduty1_5"] = { -1914, -7056, 1779 }, [P .. "recoveryduty1_6"] = { -1286, -5145, 130 },
		[P .. "recoveryduty1_7"] = { -3406, -1143, -3309 },
		[P .. "rescueduty_1"] = { -471, -1739, 1798 }, [P .. "rescueduty_2"] = { 294, 509, 3594 }, [P .. "rescueduty_3"] = { 1562, 97, 5577 },
		[P .. "rescueduty_4"] = { 2910, -386, 7314 },
	},
	[H4] = {
		[P .. "escort1_1"] = { -6011, -147, -3735 }, [P .. "escort1_2"] = { -7504, -313, -4018 }, [P .. "escort1_3"] = { -6767, -456, -2553 },
		[P .. "escort1_4"] = { -4795, -1638, -4 }, [P .. "escort1_5"] = { -2888, -3209, 2593 },
		[P .. "rescue1_1"] = { -2721, -3343, 2806 }, [P .. "rescue1_2"] = { -1537, -4296, 4316 }, [P .. "rescue1_3"] = { -362, -5324, 5829 },
		[P .. "rescue1_4"] = { 1272, -6755, 7134 },
		[P .. "patrol2_1"] = { -3927, -410, -4523 }, [P .. "patrol2_2"] = { -4370, -844, -5579 }, [P .. "patrol2_3"] = { -4978, -1440, -7029 },
		[P .. "patrol2_4"] = { -3465, -823, -6823 },
		[P .. "assassinate1_1"] = { -1685, -224, -6240 }, [P .. "assassinate1_2"] = { 514, 1172, -5948 }, [P .. "assassinate1_3"] = { 809, 2122, -3746 },
		[P .. "assassinate1_4"] = { 1195, 3360, -877 },
		[P .. "recovery2_1"] = { -5207, 2117, -3438 }, [P .. "recovery2_2"] = { -6148, -309, -2006 }, [P .. "recovery2_3"] = { -4775, -2667, 3284 },
		[P .. "recovery2_4"] = { 8, -4809, 5248 }, [P .. "recovery2_5"] = { 5269, -4515, 3965 }, [P .. "recovery2_6"] = { 5637, -4506, 1444 },
		[P .. "recovery2_7"] = { 5904, -3381, -2643 }, [P .. "recovery2_8"] = { 6251, -1966, -7476 },
		[P .. "battle1"] = { 6724, -6022, -7606 },
	},
}

T.SPAWNERS = {
	{ name = P .. "inspect1", zone = D, x = 3133, z = 6113, y = -3618 },
	{ name = P .. "inspect2", zone = D, x = -3934, z = -6968, y = 2011 },
	{ name = P .. "inspect3", zone = H4, x = -1184, z = -670, y = -4776 },
}

-- Appendix B list sizes (an anchor for the lists the tests derive from the fixtures)
T.LIST_SIZES = {
	[T.M1[3]] = { 4, 5, 5, 5, 5, 6 },
	[T.M2[1]] = { 4, 5 },
	[T.M2[3]] = { 4, 4, 4, 5 },
	[T.M3[1]] = { 4, 6, 6, 6 },
	[T.M3[2]] = { 4, 6, 6 },
	[T.M4[2]] = { 5, 5, 5 },
	[T.DUTIES[1]] = { 5, 5, 5, 5 },
	[T.DUTIES[2]] = { 5, 5, 5, 5 },
	[T.DUTIES[3]] = { 5, 5, 5, 5 },
	[T.DUTIES[4]] = { 5, 5, 5, 6 },
}

T.ITEMS = {
	[1] = "object/tangible/ship/components/weapon/wpn_mission_reward_imperial_sds_boltdriver.iff",
	[2] = "object/tangible/ship/components/shield_generator/shd_mission_reward_imperial_cygnus_holoscreen.iff",
	[3] = "object/tangible/ship/components/armor/arm_mission_reward_imperial_rss_special_durasteel.iff",
	[4] = "object/tangible/ship/components/reactor/rct_mission_reward_imperial_rss_advanced_military.iff",
}

T.CREDITS = 10000
T.STANDING = 150
T.TRAIN_COST = 1000000
T.FORWARD = { x = 0.122813, z = -0.992281, y = 0.017169 }

-- the three inspect ships: ship template, the spawner and the cargo (quest global -> ...)
T.INSPECTS = {
	{ global = T.M1[2], ship = "velocity_merc_captain_tier4", cargo = P .. "inspect1", spawner = T.SPAWNERS[1] },
	{ global = T.M2[2], ship = "velocity_merc_group_leader_tier5", cargo = P .. "inspect2", spawner = T.SPAWNERS[2] },
	{ global = T.M3[4], ship = "velocity_commander_tier4", cargo = P .. "inspect3", spawner = T.SPAWNERS[3] },
}

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
		out[#out + 1] = P .. prefix .. i
	end

	return out
end

-- The fixture column lists attackShips1..numAttackShipLists (column-wise, Data mapping 1)
local function attackLists(rec, count, column)
	local lists = {}

	for i = 1, count or rec:num("numAttackShipLists") do
		lists[i] = rec:list((column or "attackShips") .. i)
	end

	return lists
end

local function fixtureOf(global)
	local id = T.IDENTITY[global]

	return (H.questFixture(id.type, id.name))
end

T.fixtureOf = fixtureOf
T.attackLists = attackLists

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
	local taunt4 = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }
	local out = {}
	local function fx(global) return fixtureOf(global) end

	-- Mission 1
	out[T.M1[1]] = base(T.M1[1], {
		creditReward = T.CREDITS, itemReward = item(1),
		sideQuest = true, sideQuestType = "inspect", sideQuestName = "corellia_imperial_tier4_1_a",
		sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 3, sideQuestDelay = 25,
		patrolPoints = pts(D, numbered("patrol1_", 1, 4), { radius = 150 }, "patrolNumber"),
	})
	out[T.M1[2]] = base(T.M1[2], merge(child(T.M1[1], {}), split(T.M1[3]), {
		shipList = { "velocity_merc_captain_tier4" },
		validSpawns = { { spawnName = T.SPAWNERS[1].name, x = T.SPAWNERS[1].x, z = T.SPAWNERS[1].z, y = T.SPAWNERS[1].y } },
		giveSpawnWaypoint = 1, cargo = T.SPAWNERS[1].name,
	}))
	out[T.M1[3]] = base(T.M1[3], merge(child(T.M1[2], {}), END, {
		transmissionPoint = point(D, P .. "survival1"),
		totalTransmissionTime = 600, timesToUpdateProgress = 20, transmissionStartDelay = 30, delayToFirstAttack = 45,
		attackShipLists = attackLists(fx(T.M1[3])), attackPeriod = 100, attackListType = seq,
	}))

	-- Mission 2
	out[T.M2[1]] = base(T.M2[1], merge({ creditReward = T.CREDITS, itemReward = item(2) }, split(T.M2[2]), {
		arrivalDelay = 15, recoveryDelay = 30, recoverShip = "deserted_freighter_tier4", escortShips = {},
		preRecoveryPoints = pts(D, numbered("recovery1_", 1, 3), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(D, numbered("recovery1_", 4, 6), { radius = 250 }, "escortNumber"),
		attackDelay = 120, attackShips = attackLists(fx(T.M2[1])), tauntData = taunt2,
	}))
	out[T.M2[2]] = base(T.M2[2], merge(child(T.M2[1], {}), split(T.M2[3]), {
		shipList = { "velocity_merc_group_leader_tier5" },
		validSpawns = { { spawnName = T.SPAWNERS[2].name, x = T.SPAWNERS[2].x, z = T.SPAWNERS[2].z, y = T.SPAWNERS[2].y } },
		giveSpawnWaypoint = 1, cargo = T.SPAWNERS[2].name,
	}))
	out[T.M2[3]] = base(T.M2[3], merge(child(T.M2[2], {}), END, {
		deliveryShip = "imp_lambda_shuttle_tier4", deliveryPoint = point(D, P .. "delivery1"),
		attackShipLists = attackLists(fx(T.M2[3])), attackPeriod = 90, attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
	}))

	-- Mission 3
	out[T.M3[1]] = base(T.M3[1], merge({ creditReward = T.CREDITS, itemReward = item(3) }, split(T.M3[2]), {
		escortShips = { "imperial_drop_ship_tier4" },
		escortPoints = pts(H4, numbered("escort1_", 1, 5), { zoneName = H4, radius = 250 }, "escortNumber"),
		attackDelay = 120, attackShips = attackLists(fx(T.M3[1])), tauntData = taunt4,
	}))
	out[T.M3[2]] = base(T.M3[2], merge(child(T.M3[1], {}), split(T.M3[3]), {
		recoveryPath = pts(H4, numbered("rescue1_", 1, 4)),
		targetShipType = "imperial_drop_ship_tier4", targetArrivalDelay = 0,
		attackShipLists = attackLists(fx(T.M3[2])), attackPeriod = 120, attackListType = SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, numResponses = 5,
	}))
	out[T.M3[3]] = base(T.M3[3], merge(child(T.M3[2], {}), {
		sideQuest = true, sideQuestType = "inspect", sideQuestName = "corellia_imperial_tier4_3_c",
		sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 3, sideQuestDelay = 20,
		patrolPoints = pts(H4, numbered("patrol2_", 1, 4), { radius = 150 }, "patrolNumber"),
	}))
	out[T.M3[4]] = base(T.M3[4], merge(child(T.M3[3], {}), END, {
		shipList = { "velocity_commander_tier4" },
		validSpawns = { { spawnName = T.SPAWNERS[3].name, x = T.SPAWNERS[3].x, z = T.SPAWNERS[3].z, y = T.SPAWNERS[3].y } },
		giveSpawnWaypoint = 1, cargo = T.SPAWNERS[3].name,
	}))

	-- Mission 4
	out[T.M4[1]] = base(T.M4[1], merge({ creditReward = T.CREDITS, itemReward = item(4) }, split(T.M4[2]), {
		arrivalDelay = 30, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = "neja_bertolo_tier5", escorts = fx(T.M4[1]):list("targetEscort") },
		targetPatrols = pts(H4, numbered("assassinate1_", 1, 4)),
	}))
	out[T.M4[2]] = base(T.M4[2], merge(child(T.M4[1], {}), split(T.M4[3]), {
		arrivalDelay = 10, recoveryDelay = 30, recoverShip = "velocity_smuggler_tier4", escortShips = fx(T.M4[2]):list("targetEscort"),
		preRecoveryPoints = pts(H4, numbered("recovery2_", 1, 4), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(H4, numbered("recovery2_", 5, 8), { radius = 250 }, "escortNumber"),
		attackDelay = 120, attackShips = attackLists(fx(T.M4[2])), tauntData = taunt2,
	}))
	out[T.M4[3]] = base(T.M4[3], merge(child(T.M4[2], {}), split(T.M4[4], 10), {
		surpriseAttackShips = { zone = H4, spawns = { { count = 8, shipName = "velocity_merc_heavy_fighter_tier4" } } },
	}))
	out[T.M4[4]] = base(T.M4[4], merge(child(T.M4[3], {}), split(T.M4[5]), {
		battlePoint = point(H4, P .. "battle1", { forward = T.FORWARD }),
		damageMultiplier = 4, allyArrivalDelay = 30, enemyArrivalDelay = 90,
		allyOriginDist = 400, enemyOriginDist = -400, allyArrivalDist = 300, enemyArrivalDist = 300,
		allyForce = fx(T.M4[4]):list("allyForce"), enemyForce = fx(T.M4[4]):list("enemyForce"),
	}))
	out[T.M4[5]] = base(T.M4[5], merge(child(T.M4[4], {}), END, {
		arrivalDelay = 15, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = "onli_shien_tier5", escorts = fx(T.M4[5]):list("targetEscort") },
		targetPatrols = pts(H4, numbered("recovery2_", 5, 7)),
	}))

	-- Duties
	out[T.DUTIES[1]] = base(T.DUTIES[1], merge(END, {
		creditReward = 300, totalLevels = 8, totalRounds = 5, totalWaves = 3, bossShip = "velocity_merc_captain_tier5",
		shipTypes = attackLists(fx(T.DUTIES[1]), 4, "shipType"),
	}))
	out[T.DUTIES[2]] = base(T.DUTIES[2], merge(END, {
		creditReward = 5000, creditKillBonus = 300,
		escortShips = fx(T.DUTIES[2]):list("escortShipTypes"),
		escortPoints = pts(D, numbered("escortduty_", 1, 4), { zoneName = D, radius = 250 }, "escortNumber"),
		attackDelay = 120, attackShips = attackLists(fx(T.DUTIES[2])), tauntData = taunt4,
	}))
	out[T.DUTIES[3]] = base(T.DUTIES[3], merge(END, {
		creditReward = 5000, creditKillBonus = 300, numResponses = 5,
		recoverShip = "velocity_smuggler_tier4", arrivalDelay = 30, recoveryDelay = 30, escortShips = fx(T.DUTIES[3]):list("targetEscort"),
		preRecoveryPoints = pts(D, numbered("recoveryduty1_", 1, 4), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(D, numbered("recoveryduty1_", 5, 7), { radius = 250 }, "escortNumber"),
		attackDelay = 120, attackShips = attackLists(fx(T.DUTIES[3])), tauntData = taunt2,
	}))
	out[T.DUTIES[4]] = base(T.DUTIES[4], merge(END, {
		creditReward = 5000, creditKillBonus = 300,
		recoveryPath = pts(D, numbered("rescueduty_", 1, 4)),
		targetShipTypes = fx(T.DUTIES[4]):list("targetShipTypes"), targetArrivalDelay = 30,
		attackShipLists = attackLists(fx(T.DUTIES[4])), attackPeriod = 120, attackListType = 0, numResponses = 5,
	}))

	return out
end

-- MISSIONS of the handler (Content contract 3). status = the :attempted / :reward key stem.
T.MISSIONS = {
	{ n = 1, head = T.M1[1], questString = "TIER4_QUEST_STRING_1", endString = "TIER4_QUEST_STRING_1_SIDE2", chain = T.M1, status = "corellia_imperial_tier4_1",
		failed = "m1_failed", reward = "m1_reward", brief = "m1_brief", briefTrained = "m1_brief_trained", retries = { "m1_retry_a", "m1_retry_b" }, zone = D },
	{ n = 2, head = T.M2[1], questString = "TIER4_QUEST_STRING_2", endString = "TIER4_QUEST_STRING_2_SIDE2", chain = T.M2, status = "corellia_imperial_tier4_2",
		failed = "m2_failed", reward = "m2_reward", brief = "m2_brief", briefTrained = "m2_brief_trained", retries = { "m2_retry_a", "m2_retry_b" }, zone = D },
	{ n = 3, head = T.M3[1], questString = "TIER4_QUEST_STRING_3", endString = "TIER4_QUEST_STRING_3_SIDE3", chain = T.M3, status = "corellia_imperial_tier4_3",
		failed = "m3_failed", reward = "m3_reward", brief = "m3_brief", briefTrained = "m3_brief", retries = { "m3_retry_a", "m3_retry_b" }, zone = H4 },
	{ n = 4, head = T.M4[1], questString = "TIER4_QUEST_STRING_4", endString = "TIER4_QUEST_STRING_4_SIDE4", chain = T.M4, status = "corellia_imperial_tier4_4",
		failed = "m4_failed", reward = "m4_reward", brief = "m4_brief", briefTrained = "m4_brief_trained", retries = { "m4_retry" }, zone = H4 },
}

-- DUTY_SCREENS (Content contract 3): screen -> global, in menu order, with the menu reply of Appendix A
T.DUTY_MENU = {
	{ screen = "duty_destroy", global = T.DUTIES[1], reply = "s_99bb69ca" },
	{ screen = "duty_escort", global = T.DUTIES[2], reply = "s_4349156c" },
	{ screen = "duty_recovery", global = T.DUTIES[3], reply = "s_b881db2e" },
	{ screen = "duty_rescue", global = T.DUTIES[4], reply = "s_98338b18" },
}

T.BRIEFING_AGAIN_REPLY = "s_49805f81"

-- TRAIN_CHOICES in menu order (Content contract 3): the topic reply buys the skill
T.TRAIN = {
	{ x = "starships", skill = "pilot_imperial_navy_starships_04", reply = "s_c17d1a82" },
	{ x = "weapons", skill = "pilot_imperial_navy_weapons_04", reply = "s_6560cc1a" },
	{ x = "procedures", skill = "pilot_imperial_navy_procedures_04", reply = "s_bfe54df0" },
	{ x = "droid", skill = "pilot_imperial_navy_droid_04", reply = "s_588da3c3" },
}

-- the four _03 skills in TRAIN order, the _02 and _01 skills
T.TIER3_SKILLS = {
	"pilot_imperial_navy_starships_03", "pilot_imperial_navy_weapons_03", "pilot_imperial_navy_procedures_03", "pilot_imperial_navy_droid_03",
}

T.TIER2_SKILLS = {
	"pilot_imperial_navy_starships_02", "pilot_imperial_navy_weapons_02", "pilot_imperial_navy_procedures_02", "pilot_imperial_navy_droid_02",
}

T.TIER1_SKILLS = {
	"pilot_imperial_navy_starships_01", "pilot_imperial_navy_weapons_01", "pilot_imperial_navy_procedures_01", "pilot_imperial_navy_droid_01",
}

T.NOVICE = "pilot_imperial_navy_novice"
T.MASTER = "pilot_imperial_navy_master"

-- Appendix A
T.SCREENS = require("black_epsilon_tier4_screens_data")

function T.screenRow(id)
	for _, row in ipairs(T.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (158), sorted
function T.screenIds()
	local out = {}

	for i, row in ipairs(T.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- screens whose Appendix A action is `start n` -> n (24)
T.STARTS = {}

for _, row in ipairs(T.SCREENS) do
	local n = row.action:match("^start (%d)$")

	if n then
		T.STARTS[row.id] = tonumber(n)
	end
end

-- Appendix D: one reply path per grant screen { grant, from, mission, replies }; replies are sids with the s_ prefix
T.PATHS = {}

do
	local function add(grant, from, n, replies)
		local out = {}

		for i, r in ipairs(replies) do
			out[i] = "s_" .. r
		end

		T.PATHS[#T.PATHS + 1] = { grant = grant, from = from, n = n, replies = out }
	end

	add("m1_accept_a", "m1_brief", 1, { "a476ea3d", "7423a2e5", "4d7b8699", "9205783d" })
	add("m1_accept_b", "m1_brief", 1, { "f1d64636", "5e2181b5", "95dd869a", "929e4e42", "229e4f7a" })
	add("m1_accept_c", "m1_brief", 1, { "f1d64636", "bb26b12d", "f8b02865", "229e4f7a" })
	add("m1_accept_d", "m1_brief", 1, { "993596a8", "1d8537b", "4d7b8699", "af6c1480" })
	add("m1_accept_e", "m1_brief", 1, { "b2f1386a", "ae99b26e", "ccefd6f4", "83a5b2ca", "596bf3ab" })
	add("m1_accept_f", "m1_brief", 1, { "f1d64636", "ca2b4f36", "9e9b2154" })
	add("m2_accept_a", "m2_brief", 2, { "5a23ab6f", "64a73278" })
	add("m2_accept_b", "m2_brief", 2, { "3bdff7cb", "ed88b4e2" })
	add("m2_accept_c", "m2_brief", 2, { "596bf3ab", "6af70645", "e244a0f9" })
	add("m2_accept_d", "m2_brief", 2, { "596bf3ab", "2d7994ed", "8fe70af3" })
	add("m2_accept_e", "m2_brief", 2, { "596bf3ab", "2d7994ed", "5bea5f9", "2fa1f209" })
	add("m2_accept_f", "m2_brief", 2, { "5a23ab6f", "a67cea0d", "7ef4aae8" })
	add("m2_accept_g", "m2_brief", 2, { "3bdff7cb", "6af70645", "64a73278" })
	add("m3_accept", "m3_brief", 3, { "b4876691", "e477225c", "f74915b8", "ebbe675b", "5babb29c", "6b6c3181", "b8088c9b", "929e4e42", "ae99b26e" })
	add("m4_accept_a", "m4_brief", 4, { "fc7e0cf7" })
	add("m4_accept_b", "m4_brief", 4, { "630c41d4", "37e2608d" })
	add("m4_accept_c", "m4_brief", 4, { "ea248fbf" })
end

-- Appendix D, retries: { grant, mission, replies from the m<n>_failed screen }
T.RETRY_PATHS = {
	{ grant = "m1_retry_a", n = 1, replies = { "s_b4712f35", "s_9d071495" } },
	{ grant = "m1_retry_b", n = 1, replies = { "s_828cdbfa", "s_bbed80fc" } },
	{ grant = "m2_retry_a", n = 2, replies = { "s_87d7e908", "s_7017e938" } },
	{ grant = "m2_retry_b", n = 2, replies = { "s_40d40fc4", "s_e76b9ab1" } },
	{ grant = "m3_retry_a", n = 3, replies = { "s_c4c33621", "s_96219092", "s_2313ac9e" } },
	{ grant = "m3_retry_b", n = 3, replies = { "s_50b309d4", "s_cd02ac28", "s_9301eff1" } },
	{ grant = "m4_retry", n = 4, replies = { "s_83502a2", "s_c1ece7d0" } },
	{ grant = "m4_retry", n = 4, replies = { "s_4af031d3", "s_d70dba34", "s_37e2608d" } },
}

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

-- The server's load: the four squadron files, the Nin Gursawe template, the handler. A missing production file is recorded in T.loadErrors,
-- not raised, so the tests of a red run fail on an assertion with the reason.
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

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "InquisitionSquadronScreenplay", "StormSquadronScreenplay", "VortexSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		try(name, function() H.loadSquadron(name) end)
	end

	try("nin_gursawe_convo.lua", function() H.loadMobile("conversations/space/imperial/black_epsilon_squadron/nin_gursawe_convo.lua") end)
	try("ninGursaweConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/black_epsilon_squadron/ninGursaweConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function T.requireConversation(lu)
	T.load()
	lu.assertNotNil(H.conversationTemplateTable(T.TEMPLATE), T.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. table.concat(T.loadErrors, " | "))
	lu.assertNotNil(rawget(_G, T.HANDLER), T.HANDLER .. " is not defined. Load problems: " .. table.concat(T.loadErrors, " | "))
end

function T.quest(global)
	T.load()

	return H.expectGlobal(global, "Black Epsilon tier 4 quest table (black-epsilon-tier4-nin-gursawe). Load problems: " .. table.concat(T.loadErrors, " | "))
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

-- Options (all optional; the default is a Black Epsilon pilot with a ship, standing 0, the four tier 1-3 skills, pilot tier 4, no keys,
-- nothing of tier 4 done):
--   pilot      "imperial" (default) | "neutral" | "rebel" | false (not a pilot)
--   faction    "imperial" (default) | "rebel" | "neutral" (no faction)
--   squadron   true (default: BLACK_EPSILON_SQUADRON) | false (none) | a squadron constant
--   standing   Imperial faction standing (default 0)
--   ship       certified ship (default true)
--   tier1, t2, t3   number of tier 1 / 2 / 3 skills held, in TRAIN order (default 4)
--   t4         list of TRAIN indexes (1 starships, 2 weapons, 3 procedures, 4 droid) of the _04 skills held
--   master     the master skill is held
--   mission    { [n] = state } for n = 1..4. "won": the whole chain is complete and :attempted is set; "failed" / "attempted": :attempted only;
--              "active": :attempted and the head active; "endonly": only the chain end complete (no :attempted); "partial": the head complete,
--              the end not
--   paid       list of n (1..4) whose reward is paid: the chain is complete, :attempted and :reward are set
--   keys       { intro = true, met = true, declann = true }: the three status keys
--   xp         space_combat_general experience (default 0)
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   duty       global of a quest held active in the journal (any global)
--   species    SPECIES_* (default SPECIES_HUMAN)
--   pilotTier  ghost pilot tier (default 4)
--   inventory  (default true)
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
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

		for i = 1, (o.t3 == nil and 4 or o.t3) do
			skills[#skills + 1] = T.TIER3_SKILLS[i]
		end

		for _, i in ipairs(o.t4 or {}) do
			skills[#skills + 1] = T.TRAIN[i].skill
		end

		if o.master then
			skills[#skills + 1] = T.MASTER
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

	local keys = o.keys or {}

	if keys.intro then
		status[T.INTRO_SUFFIX] = "1"
	end

	if keys.met then
		status[T.MET_SUFFIX] = "1"
	end

	if keys.declann then
		status[T.DECLANN_SUFFIX] = "1"
	end

	if o.duty then
		active[#active + 1] = crc(o.duty)
	end

	local player = H.newPlayer({
		name = "Ace",
		pilot = pilotKind,
		faction = faction,
		squadronType = squadron,
		pilotTier = o.pilotTier or 4,
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

function T.npc() return H.newNpc({ name = "Insurgent" }) end

-- Charges the XP of the _04 skills from the fixture (1,000,000 each); without it the fake charges nothing
function T.useSkillCosts()
	local costs = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_imperial_navy_04.tab").records) do
		local name = rec:get("NAME")

		if name ~= nil and name:match("^pilot_imperial_navy_%a+_04$") then
			costs[name] = rec:num("XP_COST")
		end
	end

	H.Engine.config.skillXpCosts = costs

	return costs
end

function T.requireConversationLoaded()
	T.load()

	if H.conversationTemplateTable(T.TEMPLATE) == nil or rawget(_G, T.HANDLER) == nil then
		error("Nin Gursawe conversation is not loaded. Load problems: " .. table.concat(T.loadErrors, " | "), 3)
	end
end

-- Talks to the Insurgent from the first screen. choices as for H.converse.
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

-- _04 skills (of the four) the player holds, in T.TRAIN order
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

-- Records the calls of SpaceHelpers:grantSpaceSkill and runs the original. Call T.restore() in tearDown.
local restoreFns = {}

function T.recordGrants()
	local calls = {}
	local orig = SpaceHelpers.grantSpaceSkill

	SpaceHelpers.grantSpaceSkill = function(self, pPlayer, skill, deduct)
		calls[#calls + 1] = { skill = skill, deduct = deduct }

		return orig(self, pPlayer, skill, deduct)
	end

	restoreFns[#restoreFns + 1] = function() SpaceHelpers.grantSpaceSkill = orig end

	return calls
end

function T.restore()
	for _, fn in ipairs(restoreFns) do
		fn()
	end

	restoreFns = {}
end

return T
