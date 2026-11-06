-- Shared test data and builders for Inquisition tier 3 (Inquisitor Vrke), not a test file.
-- Spec: .claude/work/inquisition-tier3-vrke/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself:
--   V.GLOBALS / V.IDENTITY     the 16 quest globals and their class, type and name (Content contract 1)
--   V.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   V.POINTS / V.SPAWNERS      Data mapping 2: the points per zone and the 3 inspect spawners, Core3 x, z, y
--   V.SCREENS                  Appendix A (inquisition_tier3_screens_data.lua, generated from the spec table by a scratch script)
--   V.MISSIONS / V.TRAIN       MISSIONS and TRAIN_CHOICES of the handler (Content contract 3)
--   V.load()                   the server's load of the squadron files, the Barn / Fa'Zoll / Vrke templates and handlers, collecting load errors
--   V.pilot{...}               a pilot standing in front of Vrke (see the option list at V.pilot)
--   V.talk / V.drive           H.converse from the first screen / from a given screen
--
-- Vrke's conversation lives in the template "vrke_convo_template", its handler is the global "vrkeConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")

local V = {}

V.TEMPLATE = "vrke_convo_template"
V.HANDLER = "vrkeConvoHandler"
V.PREFIX = "@conversation/naboo_imperial_tier3:"
V.STF = "conversation/naboo_imperial_tier3"

V.TEMPLATE_FILE = "mobile/conversations/space/imperial/inquisition_squadron/vrke_convo.lua"
V.HANDLER_FILE = "screenplays/space/conversations/imperial/inquisition_squadron/vrkeConvoHandler.lua"
V.SQUADRON_FILE = "screenplays/space/squadrons/InquisitionSquadronScreenplay.lua"
V.NPC_FILE = "mobile/space/vrke.lua"

local N, Y, D = "space_naboo", "space_yavin4", "space_dathomir"

-- the 16 globals, by mission chain
V.M1 = { "recovery_naboo_imperial_tier3_1", "inspect_naboo_imperial_tier3_1_a", "delivery_no_pickup_naboo_imperial_tier3_1_b" }
V.M2 = { "inspect_naboo_imperial_tier3_2", "survival_naboo_imperial_tier3_2_a", "delivery_naboo_imperial_tier3_2_b", "recovery_naboo_imperial_tier3_2_c" }
V.M3 = {
	"delivery_naboo_imperial_tier3_3", "destroy_surpriseattack_naboo_imperial_tier3_3_a", "rescue_naboo_imperial_tier3_3_b",
	"inspect_naboo_imperial_tier3_3_c", "delivery_no_pickup_naboo_imperial_tier3_3_d",
}
V.M4 = { "assassinate_naboo_imperial_tier3_4", "escort_naboo_imperial_tier3_4_a", "space_battle_naboo_imperial_tier3_4_b", "assassinate_naboo_imperial_tier3_4_c" }

V.CHAINS = { V.M1, V.M2, V.M3, V.M4 }

V.GLOBALS = {}

for _, chain in ipairs(V.CHAINS) do
	for _, g in ipairs(chain) do
		V.GLOBALS[#V.GLOBALS + 1] = g
	end
end

-- the 15 tier 1-2 globals (kept by the squadron file; they register before the tier 3 globals)
V.OLDER_GLOBALS = {
	"patrol_naboo_imperial_1", "destroy_surpriseattack_naboo_imperial_1", "destroy_naboo_imperial_2", "patrol_naboo_imperial_3",
	"escort_naboo_imperial_3", "assassinate_naboo_imperial_4", "destroy_duty_naboo_imperial_6", "escort_duty_naboo_imperial_7",
	"inspect_naboo_imperial_tier2_1", "survival_naboo_imperial_tier2_2", "recovery_naboo_imperial_tier2_3", "assassinate_naboo_imperial_tier2_4",
	"recovery_duty_naboo_imperial_tier2_recoveryduty", "escort_duty_naboo_imperial_tier2_escortduty", "destroy_duty_naboo_imperial_tier2_destroyduty",
}

-- global -> { class, type, name, zone }
V.IDENTITY = {}

do
	local rows = {
		{ V.M1[1], "SpaceRecoveryScreenplay", "recovery", "naboo_imperial_tier3_1", N },
		{ V.M1[2], "SpaceInspectScreenplay", "inspect", "naboo_imperial_tier3_1_a", Y },
		{ V.M1[3], "SpaceDeliveryNoPickupScreenplay", "delivery_no_pickup", "naboo_imperial_tier3_1_b", Y },
		{ V.M2[1], "SpaceInspectScreenplay", "inspect", "naboo_imperial_tier3_2", Y },
		{ V.M2[2], "SpaceSurvivalScreenplay", "survival", "naboo_imperial_tier3_2_a", Y },
		{ V.M2[3], "SpaceDeliveryScreenplay", "delivery", "naboo_imperial_tier3_2_b", Y },
		{ V.M2[4], "SpaceRecoveryScreenplay", "recovery", "naboo_imperial_tier3_2_c", D },
		{ V.M3[1], "SpaceDeliveryScreenplay", "delivery", "naboo_imperial_tier3_3", D },
		{ V.M3[2], "SpaceSurpriseAttackScreenplay", "destroy_surpriseattack", "naboo_imperial_tier3_3_a", D },
		{ V.M3[3], "SpaceRescueScreenplay", "rescue", "naboo_imperial_tier3_3_b", D },
		{ V.M3[4], "SpaceInspectScreenplay", "inspect", "naboo_imperial_tier3_3_c", D },
		{ V.M3[5], "SpaceDeliveryNoPickupScreenplay", "delivery_no_pickup", "naboo_imperial_tier3_3_d", N },
		{ V.M4[1], "SpaceAssassinateScreenplay", "assassinate", "naboo_imperial_tier3_4", D },
		{ V.M4[2], "SpaceEscortScreenplay", "escort", "naboo_imperial_tier3_4_a", D },
		{ V.M4[3], "SpaceBattleScreenplay", "space_battle", "naboo_imperial_tier3_4_b", D },
		{ V.M4[4], "SpaceAssassinateScreenplay", "assassinate", "naboo_imperial_tier3_4_c", D },
	}

	for _, r in ipairs(rows) do
		V.IDENTITY[r[1]] = { class = r[2], type = r[3], name = r[4], zone = r[5] }
	end
end

-- Content contract 2: the squadron object's constants
V.QUEST_STRINGS = {
	TIER3_QUEST_STRING_1 = { type = "recovery", name = "naboo_imperial_tier3_1" },
	TIER3_QUEST_STRING_1_SIDE1 = { type = "inspect", name = "naboo_imperial_tier3_1_a" },
	TIER3_QUEST_STRING_1_SIDE2 = { type = "delivery_no_pickup", name = "naboo_imperial_tier3_1_b" },
	TIER3_QUEST_STRING_2 = { type = "inspect", name = "naboo_imperial_tier3_2" },
	TIER3_QUEST_STRING_2_SIDE1 = { type = "survival", name = "naboo_imperial_tier3_2_a" },
	TIER3_QUEST_STRING_2_SIDE2 = { type = "delivery", name = "naboo_imperial_tier3_2_b" },
	TIER3_QUEST_STRING_2_SIDE3 = { type = "recovery", name = "naboo_imperial_tier3_2_c" },
	TIER3_QUEST_STRING_3 = { type = "delivery", name = "naboo_imperial_tier3_3" },
	TIER3_QUEST_STRING_3_SIDE1 = { type = "destroy_surpriseattack", name = "naboo_imperial_tier3_3_a" },
	TIER3_QUEST_STRING_3_SIDE2 = { type = "rescue", name = "naboo_imperial_tier3_3_b" },
	TIER3_QUEST_STRING_3_SIDE3 = { type = "inspect", name = "naboo_imperial_tier3_3_c" },
	TIER3_QUEST_STRING_3_SIDE4 = { type = "delivery_no_pickup", name = "naboo_imperial_tier3_3_d" },
	TIER3_QUEST_STRING_4 = { type = "assassinate", name = "naboo_imperial_tier3_4" },
	TIER3_QUEST_STRING_4_SIDE1 = { type = "escort", name = "naboo_imperial_tier3_4_a" },
	TIER3_QUEST_STRING_4_SIDE2 = { type = "space_battle", name = "naboo_imperial_tier3_4_b" },
	TIER3_QUEST_STRING_4_SIDE3 = { type = "assassinate", name = "naboo_imperial_tier3_4_c" },
}

-- Content contract 2: the Barlow hand-shake keys (stored as <playerID><suffix>, value "1")
V.QUESTION_SUFFIX = "InquisitionSquadronScreenplay:questionBarlow"
V.SPOKE_SUFFIX = "InquisitionSquadronScreenplay:spokeToBarlow"

-- The 8 status keys resetVrkeQuests removes (without the player id)
V.KEYS = {}

for n = 1, 4 do
	V.KEYS[#V.KEYS + 1] = "naboo_imperial_tier3_" .. n .. ":attempted"
	V.KEYS[#V.KEYS + 1] = "naboo_imperial_tier3_" .. n .. ":reward"
end

V.SERIES_SUFFIX = "InquisitionSquadronScreenplay:naboo_imperial_1"
V.AGENT_SUFFIX = "InquisitionSquadronScreenplay:inquisitorialAgent"
V.TIER2_M4_REWARD = "naboo_imperial_tier2_4:reward"

-- Data mapping 2: zone -> name -> { x, z, y }
V.POINTS = {
	[N] = {
		naboo_imperial_tier3_recovery1_1 = { 3200, -2300, 1000 },
		naboo_imperial_tier3_recovery1_2 = { 606, -1811, 2677 },
		naboo_imperial_tier3_recovery1_3 = { -1560, -4222, 2922 },
		naboo_imperial_tier3_recovery1_4 = { -2264, -4270, 4044 },
		corellia_imperial_tier3_leg_4_assassinate_one_1 = { -3939, 1474, -1521 },
		naboo_imperial_tier3_recovery1_5 = { -3035, -4019, 3262 },
		naboo_imperial_tier3_recovery1_6 = { -3564, -3047, -620 },
		naboo_imperial_tier3_delivery4 = { 1069, 1110, 263 },
	},
	[Y] = {
		naboo_imperial_tier3_survival1 = { 2016, -4500, 6816 },
		corellis_imperial_tier3_leg_2_rescue_3 = { 1463, -2058, -568 },
		naboo_imperial_tier3_delivery1_dropoff = { 1092, 842, 598 },
	},
	[D] = {
		naboo_imperial_tier3_recovery2_1 = { 1936, 2300, 4704 },
		naboo_imperial_tier3_recovery2_2 = { -2361, 5226, 1662 },
		naboo_imperial_tier3_recovery2_3 = { -3357, 741, -1890 },
		naboo_imperial_tier3_recovery2_4 = { -440, -2779, -5776 },
		naboo_imperial_tier3_recovery2_5 = { 4297, -3650, -6721 },
		naboo_imperial_tier3_recovery2_6 = { -3383, -3342, -3625 },
		naboo_imperial_tier3_recovery2_7 = { -2154, -2127, -2311 },
		naboo_imperial_tier3_recovery2_8 = { -459, -452, -498 },
		naboo_imperial_tier3_delivery3_pickup = { 4824, -1000, 264 },
		naboo_imperial_tier3_delivery3_dropoff = { -3608, 5628, 5256 },
		naboo_imperial_tier3_rescue1_1 = { 4300, 6400, -4900 },
		naboo_imperial_tier3_rescue1_2 = { 222, 6250, -4778 },
		naboo_imperial_tier3_rescue1_3 = { -1638, 3789, -6552 },
		naboo_imperial_tier3_rescue1_4 = { -3555, 3445, -6578 },
		naboo_imperial_tier3_assassinate1_1 = { -1879, -110, -1881 },
		naboo_imperial_tier3_assassinate1_2 = { 19, -2029, -411 },
		naboo_imperial_tier3_assassinate1_3 = { 2767, -3788, 1500 },
		naboo_imperial_tier3_assassinate1_4 = { 4998, -4963, 2982 },
		naboo_imperial_tier3_escort1_1 = { 7340, 2102, -3234 },
		naboo_imperial_tier3_escort1_2 = { 5193, 2105, -998 },
		naboo_imperial_tier3_escort1_3 = { 2192, 1097, -995 },
		naboo_imperial_tier3_escort1_4 = { 1019, 509, -505 },
		naboo_imperial_tier3_spacebattle1 = { 1303, 2316, 4521 },
		naboo_imperial_tier4_recoveryduty1_4 = { 3989, -1251, -6960 },
		naboo_imperial_tier4_recoveryduty1_5 = { 1495, -1773, -6461 },
		naboo_imperial_tier4_recoveryduty1_6 = { -1458, -2983, -5981 },
		naboo_imperial_tier4_recoveryduty1_7 = { -3969, -4072, -3508 },
	},
}

V.SPAWNERS = {
	[Y] = {
		naboo_imperial_tier3_inspect1_spawner = { 5000, -2300, 1020 },
		naboo_imperial_tier3_shinssyacht_spawner = { 3196, -6203, -5010 },
	},
	[D] = {
		naboo_imperial_tier3_inspect3_spawner = { 2005, 4299, -3566 },
	},
}

V.ITEM_ROOT = "object/tangible/ship/components/"

V.ITEMS = {
	[1] = V.ITEM_ROOT .. "weapon_capacitor/cap_mission_reward_imperial_rendili_k_class.iff",
	[2] = V.ITEM_ROOT .. "droid_interface/ddi_mission_reward_imperial_sfs_military_grade.iff",
	[3] = V.ITEM_ROOT .. "reactor/rct_mission_reward_imperial_sds_high_output.iff",
	[4] = V.ITEM_ROOT .. "engine/eng_mission_reward_imperial_cygnus_megadrive.iff",
}

V.CREDITS = 25000
V.STANDING = 100
V.FORWARD = { x = -0.3808, z = -0.866842, y = -0.321834 }
V.OFFICER_MOBILE = "object/mobile/shared_space_comm_imperial_officer_01.iff"

local function point(zone, name, extra)
	local p = V.POINTS[zone][name]

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

local function item(n) return { { species = { -1 }, item = V.ITEMS[n] } } end

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function V.expected()
	local COMPLETION = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION

	local function base(global, more)
		local id = V.IDENTITY[global]
		local t = { className = global, questType = id.type, questName = id.name, questZone = id.zone }

		for k, v in pairs(more) do
			t[k] = v
		end

		return t
	end

	local function child(parent, more)
		local pid = V.IDENTITY[parent]

		more.parentQuest, more.parentQuestType, more.parentQuestName = parent, pid.type, pid.name

		return more
	end

	local function split(nextGlobal, delay)
		local nid = V.IDENTITY[nextGlobal]

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
	local seqSurvival = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local seqDelivery = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local seqRescue = SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local taunt2 = { panicCount = 5, thanksCount = 5 }
	local x3, x4, y3, a3, b3, z3 = "reb_xwing_tier3", "reb_xwing_tier4", "reb_ywing_tier3", "reb_awing_tier3", "reb_bwing_tier3", "reb_z95_tier3"
	local lambda = "imp_lambda_shuttle_tier3"
	local out = {}

	-- Mission 1
	out[V.M1[1]] = base(V.M1[1], merge({ creditReward = V.CREDITS, itemReward = item(1) }, split(V.M1[2]), {
		arrivalDelay = 30, recoveryDelay = 30, recoverShip = "colonel_hend_yacht_tier3",
		recoveryConversationMobile = V.OFFICER_MOBILE,
		escortShips = {},
		preRecoveryPoints = pts(N, { "naboo_imperial_tier3_recovery1_1", "naboo_imperial_tier3_recovery1_2", "naboo_imperial_tier3_recovery1_3",
			"naboo_imperial_tier3_recovery1_4", "corellia_imperial_tier3_leg_4_assassinate_one_1" }, { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(N, { "naboo_imperial_tier3_recovery1_5", "naboo_imperial_tier3_recovery1_6" }, { radius = 250 }, "escortNumber"),
		attackDelay = 90,
		attackShips = { rep(x3, 4), { x3, x3, y3, y3 } },
		tauntData = taunt2,
	}))
	out[V.M1[2]] = base(V.M1[2], merge(child(V.M1[1], {}), split(V.M1[3]), {
		shipList = { "mercenary_spy_fighter_tier4" },
		validSpawns = { { spawnName = "naboo_imperial_tier3_inspect1_spawner", x = 5000, z = -2300, y = 1020 } },
		giveSpawnWaypoint = 1, cargo = "pirate_data",
	}))
	out[V.M1[3]] = base(V.M1[3], merge(child(V.M1[2], {}), END, {
		deliveryShip = "imp_freightermedium_tier3",
		deliveryPoint = point(Y, "naboo_imperial_tier3_delivery1_dropoff"),
		attackShipLists = { { x3, x3, x4 }, { x3, x3, x3, x4 }, { x3, x3, y3, y3 }, rep(a3, 5) },
		attackPeriod = 90, attackListType = seqDelivery,
	}))

	-- Mission 2
	out[V.M2[1]] = base(V.M2[1], merge({ creditReward = V.CREDITS, itemReward = item(2) }, split(V.M2[2], 15), {
		shipList = { "shinss_yacht_tier3" },
		validSpawns = { { spawnName = "naboo_imperial_tier3_shinssyacht_spawner", x = 3196, z = -6203, y = -5010 } },
		giveSpawnWaypoint = 1, cargo = "shinss_personal_logs",
	}))
	out[V.M2[2]] = base(V.M2[2], merge(child(V.M2[1], {}), split(V.M2[3]), {
		transmissionPoint = point(Y, "naboo_imperial_tier3_survival1"),
		totalTransmissionTime = 600, timesToUpdateProgress = 20, transmissionStartDelay = 45, delayToFirstAttack = 45,
		attackShipLists = { rep(y3, 4), rep(x3, 4), rep(z3, 4), rep(a3, 4), rep(b3, 4) },
		attackPeriod = 90, attackListType = seqSurvival,
	}))
	out[V.M2[3]] = base(V.M2[3], merge(child(V.M2[2], {}), split(V.M2[4]), {
		pickupPoint = point(Y, "corellis_imperial_tier3_leg_2_rescue_3"),
		deliveryPoint = point(Y, "naboo_imperial_tier3_delivery1_dropoff"),
		pickupShip = lambda, deliveryShip = lambda,
		attackShipLists = { rep(x3, 4), rep(a3, 5), rep(y3, 4), { b3, b3, a3, a3, a3 } },
		attackPeriod = 60, attackListType = seqDelivery,
	}))
	out[V.M2[4]] = base(V.M2[4], merge(child(V.M2[3], {}), END, {
		arrivalDelay = 15, recoveryDelay = 30, recoverShip = "shinss_escape_shuttle_tier3",
		escortShips = rep("shinss_escort_fighters_tier3", 5),
		preRecoveryPoints = pts(D, numbered("naboo_imperial_tier3_recovery2_", 1, 5), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(D, numbered("naboo_imperial_tier3_recovery2_", 6, 8), { radius = 250 }, "escortNumber"),
		attackDelay = 90,
		attackShips = { rep(x3, 4), { x3, x3, x3, x4 } },
		tauntData = taunt2,
	}))

	-- Mission 3
	out[V.M3[1]] = base(V.M3[1], merge({ creditReward = V.CREDITS, itemReward = item(3) }, split(V.M3[2]), {
		pickupPoint = point(D, "naboo_imperial_tier3_delivery3_pickup"),
		deliveryPoint = point(D, "naboo_imperial_tier3_delivery3_dropoff"),
		pickupShip = lambda, deliveryShip = lambda,
		attackShipLists = { { x3, x3, x4 }, { x3, x3, x3, x4 }, { a3, a3, a3, a3, "reb_awing_tier4" } },
		attackPeriod = 60, attackListType = seqDelivery,
	}))
	out[V.M3[2]] = base(V.M3[2], merge(child(V.M3[1], {}), split(V.M3[3]), {
		surpriseAttackShips = { zone = D, spawns = { { count = 7, shipName = x3 } } },
	}))
	out[V.M3[3]] = base(V.M3[3], merge(child(V.M3[2], {}), split(V.M3[4]), {
		recoveryPath = pts(D, numbered("naboo_imperial_tier3_rescue1_", 1, 4)),
		targetShipType = lambda, targetArrivalDelay = 15,
		attackShipLists = { rep(y3, 4), rep(x3, 4), { "reb_ywing_tier4", "reb_ywing_tier4", x3, x3 } },
		attackPeriod = 90, attackListType = seqRescue, numResponses = 5,
	}))
	out[V.M3[4]] = base(V.M3[4], merge(child(V.M3[3], {}), split(V.M3[5]), {
		shipList = { "rebel_spyfreighter_tier3" },
		validSpawns = { { spawnName = "naboo_imperial_tier3_inspect3_spawner", x = 2005, z = 4299, y = -3566 } },
		giveSpawnWaypoint = 1, cargo = "rebel_plans",
	}))
	out[V.M3[5]] = base(V.M3[5], merge(child(V.M3[4], {}), END, {
		deliveryShip = lambda,
		deliveryPoint = point(N, "naboo_imperial_tier3_delivery4"),
		attackShipLists = { rep(a3, 5), { x3, x3, x3, x3, x4 }, rep(b3, 4) },
		attackPeriod = 60, attackListType = seqDelivery,
	}))

	-- Mission 4
	out[V.M4[1]] = base(V.M4[1], merge({ creditReward = V.CREDITS, itemReward = item(4) }, split(V.M4[2]), {
		arrivalDelay = 30, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = "general_breckon_shuttle_tier4", escorts = rep("breckon_escort_fighter_tier3", 5) },
		targetPatrols = pts(D, numbered("naboo_imperial_tier3_assassinate1_", 1, 4)),
	}))
	out[V.M4[2]] = base(V.M4[2], merge(child(V.M4[1], {}), split(V.M4[3], 15), {
		escortShips = { "dathomir_prison_shuttle_tier4" },
		escortPoints = pts(D, numbered("naboo_imperial_tier3_escort1_", 1, 4), { zoneName = D, radius = 250 }, "escortNumber"),
		attackDelay = 120,
		attackShips = { rep(x3, 4), { b3, x3, x3, x3 }, rep(a3, 5), rep(x3, 5) },
		tauntData = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 },
	}))
	out[V.M4[3]] = base(V.M4[3], merge(child(V.M4[2], {}), split(V.M4[4]), {
		battlePoint = point(D, "naboo_imperial_tier3_spacebattle1", { forward = V.FORWARD }),
		damageMultiplier = 5, allyArrivalDelay = 30, enemyArrivalDelay = 90,
		allyOriginDist = 400, enemyOriginDist = -400, allyArrivalDist = 300, enemyArrivalDist = 300,
		allyForce = cat(rep("imp_tie_interceptor_tier3", 3), rep("imp_tie_fighter_tier3", 2)),
		enemyForce = cat(rep(x3, 3), { a3, y3 }, rep(a3, 4), { x3 }),
	}))
	out[V.M4[4]] = base(V.M4[4], merge(child(V.M4[3], {}), END, {
		arrivalDelay = 30, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = "reb_priceofliberty_tier3", escorts = rep(x3, 6) },
		targetPatrols = pts(D, numbered("naboo_imperial_tier4_recoveryduty1_", 4, 7)),
	}))

	return out
end

-- MISSIONS of the handler (Content contract 3). status = the :attempted / :reward key stem.
V.MISSIONS = {
	{ n = 1, head = V.M1[1], questString = "TIER3_QUEST_STRING_1", endString = "TIER3_QUEST_STRING_1_SIDE2", chain = V.M1, status = "naboo_imperial_tier3_1",
		offer = "m1_offer", failed = "m1_failed", reward = "m1_reward", training = "m1_training",
		accepts = { "m1_accept" }, retries = { "m1_retry_searching", "m1_retry_promise", "m1_retry_sooner" } },
	{ n = 2, head = V.M2[1], questString = "TIER3_QUEST_STRING_2", endString = "TIER3_QUEST_STRING_2_SIDE3", chain = V.M2, status = "naboo_imperial_tier3_2",
		offer = "m2_offer", failed = "m2_failed", reward = "m2_reward", training = "m2_training",
		accepts = { "m2_accept", "m2_accept_simple" }, retries = { "m2_retry_loyal", "m2_retry_actions" } },
	{ n = 3, head = V.M3[1], questString = "TIER3_QUEST_STRING_3", endString = "TIER3_QUEST_STRING_3_SIDE4", chain = V.M3, status = "naboo_imperial_tier3_3",
		offer = "m3_offer", failed = "m3_failed", reward = "m3_reward", training = "m3_training",
		accepts = { "m3_accept_dathomir", "m3_accept_bait", "m3_accept_die", "m3_accept_leave" }, retries = { "m3_retry" } },
	{ n = 4, head = V.M4[1], questString = "TIER3_QUEST_STRING_4", endString = "TIER3_QUEST_STRING_4_SIDE3", chain = V.M4, status = "naboo_imperial_tier3_4",
		offer = "m4_offer", failed = "m4_failed", reward = "m4_reward", training = "m4_training",
		accepts = { "m4_accept_accident", "m4_accept_accident_2", "m4_accept_casualty" }, retries = { "m4_retry_again", "m4_retry_excuses" } },
}

-- the screen that starts mission n (Conversation flow 3 table H): screen -> n
V.START_SCREENS = {
	m1_accept = 1, m1_retry_searching = 1, m1_retry_promise = 1, m1_retry_sooner = 1,
	m2_accept = 2, m2_accept_simple = 2, m2_retry_loyal = 2, m2_retry_actions = 2,
	m3_accept_dathomir = 3, m3_accept_bait = 3, m3_accept_die = 3, m3_accept_leave = 3, m3_retry = 3,
	m4_accept_accident = 4, m4_accept_accident_2 = 4, m4_accept_casualty = 4, m4_retry_again = 4, m4_retry_excuses = 4,
}

-- TRAIN_CHOICES in menu order (Content contract 3): the topic reply grants. trained[n] = the screen of mission n, trainedSid[n] its dialog.
V.TRAIN = {
	{ x = "starships", skill = "pilot_imperial_navy_starships_03", reply = "s_40cda759",
		trainedSid = { "s_5a27cd7a", "s_231aa1cb", "s_a112be1b", "s_d05c3a79" } },
	{ x = "weapons", skill = "pilot_imperial_navy_weapons_03", reply = "s_a9aeb386",
		trainedSid = { "s_a3dbeea3", "s_adf8c646", "s_590440bf", "s_bfcce26a" } },
	{ x = "procedures", skill = "pilot_imperial_navy_procedures_03", reply = "s_ef7a2df5",
		trainedSid = { "s_96871003", "s_e73bd99d", "s_8fbd0301", "s_4c42a50e" } },
	{ x = "droid", skill = "pilot_imperial_navy_droid_03", reply = "s_473d09d8",
		trainedSid = { "s_eb077a31", "s_d61b10cc", "s_cb94834e", "s_9016869" } },
}

function V.trained(n, i) return "m" .. n .. "_trained_" .. V.TRAIN[i].x end

-- the six training screens (C-1), screen -> mission
V.TRAINING_SCREENS = { m1_training = 1, m1_training_best = 1, m2_training = 2, m3_training = 3, m4_training = 4, m4_training_bah = 4 }

-- the four _02 skills in TRAIN order, the four _01 skills
V.TIER2_SKILLS = {
	"pilot_imperial_navy_starships_02", "pilot_imperial_navy_weapons_02", "pilot_imperial_navy_procedures_02", "pilot_imperial_navy_droid_02",
}

V.TIER1_SKILLS = {
	"pilot_imperial_navy_starships_01", "pilot_imperial_navy_weapons_01", "pilot_imperial_navy_procedures_01", "pilot_imperial_navy_droid_01",
}

V.NOVICE = "pilot_imperial_navy_novice"

-- Appendix A
V.SCREENS = require("inquisition_tier3_screens_data")

function V.screenRow(id)
	for _, row in ipairs(V.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (173), sorted
function V.screenIds()
	local out = {}

	for i, row in ipairs(V.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

V.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		V.loadErrors[#V.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: the squadron files, Barn's, Fa'Zoll's and Vrke's templates and handlers. A missing production file is recorded in
-- V.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function V.load()
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

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "InquisitionSquadronScreenplay", "StormSquadronScreenplay" }) do
		if rawget(_G, name) == nil then
			try(name, function() H.loadSquadron(name) end)
		end
	end

	try("barn_sinkko_convo.lua", function() H.loadMobile("conversations/space/imperial/inquisition_squadron/barn_sinkko_convo.lua") end)
	try("barnSinkkoConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/inquisition_squadron/barnSinkkoConvoHandler.lua") end)
	try("fa_zoll_convo.lua", function() H.loadMobile("conversations/space/imperial/inquisition_squadron/fa_zoll_convo.lua") end)
	try("faZollConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/inquisition_squadron/faZollConvoHandler.lua") end)
	try("vrke_convo.lua", function() H.loadMobile("conversations/space/imperial/inquisition_squadron/vrke_convo.lua") end)
	try("vrkeConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/inquisition_squadron/vrkeConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function V.requireConversation(lu)
	V.load()
	lu.assertNotNil(H.conversationTemplateTable(V.TEMPLATE), V.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. table.concat(V.loadErrors, " | "))
	lu.assertNotNil(rawget(_G, V.HANDLER), V.HANDLER .. " is not defined. Load problems: " .. table.concat(V.loadErrors, " | "))
end

function V.quest(global)
	V.load()

	return H.expectGlobal(global, "Inquisition tier 3 quest table (inquisition-tier3-vrke). Load problems: " .. table.concat(V.loadErrors, " | "))
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = V.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

V.crc = crc

-- Quest state helpers on a built pilot. state: "complete" | "active" | "none"
function V.setState(player, global, state)
	local key = crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function V.state(player, global)
	local key = crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- Options (all optional; the default is an Inquisition pilot with a ship, standing 0, the four tier 1 and four tier 2 skills, pilot tier 3,
-- Barn's series flag and Fa'Zoll's agent flag set, Fa'Zoll's mission 4 paid, nothing of tier 3 done):
--   pilot      "imperial" (default) | "neutral" | "rebel" | false (not a pilot)
--   faction    "imperial" (default) | "rebel" | "neutral" (no faction)
--   squadron   true (default: INQUISITION_SQUADRON) | false (none) | a squadron constant
--   standing   Imperial faction standing (default 0)
--   ship       certified ship (default true)
--   tier1      number of tier 1 skills held (default 4)
--   t2         number of tier 2 skills held, in TIER2_SKILLS order (default 4)
--   t2paid4    Fa'Zoll's mission 4 reward key (naboo_imperial_tier2_4:reward) is set (default true)
--   t3         list of TRAIN indexes (1 starships, 2 weapons, 3 procedures, 4 droid) of the tier 3 skills held
--   mission    { [n] = state } for n = 1..4. "won": the whole chain is complete and :attempted is set; "failed" / "attempted": :attempted only;
--              "active": :attempted and the head active; "endonly": only the chain end complete (no :attempted); "partial": the head complete,
--              the end not
--   paid       list of n (1..4) whose reward is paid: the chain is complete, :attempted and :reward are set
--   question   QUESTION_BARLOW_KEY is set; spoke: SPOKE_TO_BARLOW_KEY is set
--   xp         space_combat_general experience (default 0)
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   duty       global of a quest held active in the journal (any global)
--   species    SPECIES_* (default SPECIES_HUMAN)
--   pilotTier  ghost pilot tier (default 3)
--   inventory  (default true)
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
--   series     Barn's series-complete flag (default true); agent: Fa'Zoll's agent flag (default true)
function V.pilot(o)
	o = o or {}
	V.load()

	local pilotKind = o.pilot

	if pilotKind == nil then
		pilotKind = "imperial"
	elseif pilotKind == false then
		pilotKind = nil
	end

	local faction = ({ imperial = FACTIONIMPERIAL, rebel = FACTIONREBEL })[o.faction or "imperial"] or 0
	local squadron = o.squadron

	if squadron == nil or squadron == true then
		squadron = INQUISITION_SQUADRON
	elseif squadron == false then
		squadron = 0
	end

	local skills = {}

	if pilotKind ~= nil then
		skills[1] = V.NOVICE

		for i = 1, (o.tier1 == nil and 4 or o.tier1) do
			skills[#skills + 1] = V.TIER1_SKILLS[i]
		end

		for i = 1, (o.t2 == nil and 4 or o.t2) do
			skills[#skills + 1] = V.TIER2_SKILLS[i]
		end

		for _, i in ipairs(o.t3 or {}) do
			skills[#skills + 1] = V.TRAIN[i].skill
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
		local m = V.MISSIONS[n]
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
		status[V.SERIES_SUFFIX] = "1"
	end

	if o.agent ~= false then
		status[V.AGENT_SUFFIX] = "1"
	end

	if o.t2paid4 ~= false then
		status[V.TIER2_M4_REWARD] = "1"
	end

	if o.question then
		status[V.QUESTION_SUFFIX] = "1"
	end

	if o.spoke then
		status[V.SPOKE_SUFFIX] = "1"
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

function V.npc() return H.newNpc({ name = "Vrke" }) end

function V.requireConversationLoaded()
	V.load()

	if H.conversationTemplateTable(V.TEMPLATE) == nil or rawget(_G, V.HANDLER) == nil then
		error("Vrke's conversation is not loaded. Load problems: " .. table.concat(V.loadErrors, " | "), 3)
	end
end

-- Talks to Vrke from the first screen. choices as for H.converse.
function V.talk(player, choices)
	V.requireConversationLoaded()

	return H.converse({ template = V.TEMPLATE, player = player, npc = V.npc(), choices = choices })
end

-- The id of the first screen of a fresh talk
function V.firstScreen(player)
	return V.talk(player)[1].id
end
-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session.
function V.drive(player, startId, choices)
	V.requireConversationLoaded()

	local tmpl = H.conversationTemplate(V.TEMPLATE)
	local handler = rawget(_G, V.HANDLER)
	local npc = V.npc()
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
		error("screen '" .. startId .. "' is not in " .. V.TEMPLATE, 2)
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
function V.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- the option sids ("s_xxx") of a transcript step, in order
function V.optionSids(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = tostring(o.text):match(":(s_[%w_]+)$") or tostring(o.text)
	end

	return out
end

function V.linksOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = o.link
	end

	return out
end

-- Tier 3 skills (of the four) the player holds, in V.TRAIN order
function V.held(player)
	local out = {}

	for _, t in ipairs(V.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

-- Spies on the startQuest of the listed globals (H.spyOn does not call the original)
function V.spyStarts(globals)
	local spies = {}

	for _, g in ipairs(globals or V.GLOBALS) do
		spies[g] = H.spyOn(V.quest(g), "startQuest")
	end

	return spies
end

-- the sorted list of globals whose startQuest was called, one entry per call
function V.started(spies)
	local out = {}

	for g, calls in pairs(spies) do
		for _ = 1, #calls do
			out[#out + 1] = g
		end
	end

	table.sort(out)
	return out
end

-- The free grant (SpaceHelpers:grantSpaceSkill(p, skill, false) -> awardSkill) and the XP-deducting grant (skillManagerAwardSkill) calls
function V.free() return H.Engine.callsTo("awardSkill") end
function V.bought() return H.Engine.callsTo("skillManagerAwardSkill") end

-- The item giveItem calls on the pilot's inventory received
function V.items(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory then
			out[#out + 1] = call[2]
		end
	end

	return out
end

-- The quest status "1" test as the handler reads it: <playerID><suffix>
function V.hasKey(player, suffix) return H.getQuestStatus(player, suffix) == "1" end

-- The sorted list of status keys (suffixes) the player holds with the given prefixes
function V.keysOf(player, prefixes)
	local out = {}

	for _, suffix in ipairs(prefixes) do
		if H.getQuestStatus(player, suffix) ~= nil then
			out[#out + 1] = suffix
		end
	end

	table.sort(out)
	return out
end

return V
