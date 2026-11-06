-- Shared test data and builders for Storm Squadron tier 3 (Captain Denner), not a test file.
-- Spec: .claude/work/storm-tier3-denner-missions/01-spec.md (Part A: Content contract, Data mapping, Appendix B).
-- Part B (storm-tier3-denner: the conversation) extends this file.
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself:
--   D.GLOBALS / D.IDENTITY     the 20 quest globals and their class, type, name and zone (Content contract 1)
--   D.M1 .. D.M4 / D.CHAINS    the four chains, members in chain order (Source inventory 2; M3 runs 3, 3_b, 3_a, 3_d, 3_c)
--   D.QUEST_STRINGS            the 20 TIER3_* constants of StormSquadronScreenplay (Content contract 2)
--   D.statusKeys()             the 8 ":attempted" / ":reward" keys (Content contract 2)
--   D.POINTS / D.SPAWNER_NAMES Data mapping 2: the 33 nav points and the 4 inspect spawners, Core3 x, z, y
--   D.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   D.load()                   the server's load: the squadron files (storm_tier2_alozen_data.lua loads Oberhaur's and Alozen's pieces too)
--   D.pilot{...}               a Storm pilot who finished tier 2, with optional tier 3 state (see the option list at D.pilot)
--   D.flyer(zone)              an Imperial pilot in an Imperial ship in `zone`, for the runtime tests
--
-- Rewards are spec literals (D-A1): the SWG trainer script tatooine_imperial_tier3.java is Part B's fixture.

local H = require("harness")
local A = require("storm_tier2_alozen_data")
local T = require("storm_tier2_data")

local D = {}

D.SQUADRON_FILE = "screenplays/space/squadrons/StormSquadronScreenplay.lua"
D.ZONE = "space_endor"

-- the 20 globals, by mission chain (chain order, not suffix order: M3 is 3, 3_b, 3_a, 3_d, 3_c)
D.M1 = {
	"escort_tatooine_imperial_tier3_1", "recovery_tatooine_imperial_tier3_1_a", "inspect_tatooine_imperial_tier3_1_b",
	"rescue_tatooine_imperial_tier3_1_c", "delivery_no_pickup_tatooine_imperial_tier3_1_d",
}
D.M2 = {
	"inspect_tatooine_imperial_tier3_2", "destroy_surpriseattack_tatooine_imperial_tier3_2_a", "inspect_tatooine_imperial_tier3_2_b",
	"delivery_no_pickup_tatooine_imperial_tier3_2_c", "patrol_tatooine_imperial_tier3_2_d", "space_battle_tatooine_imperial_tier3_2_e",
}
D.M3 = {
	"delivery_tatooine_imperial_tier3_3", "destroy_tatooine_imperial_tier3_3_b", "escort_tatooine_imperial_tier3_3_a",
	"destroy_surpriseattack_tatooine_imperial_tier3_3_d", "survival_tatooine_imperial_tier3_3_c",
}
D.M4 = {
	"assassinate_tatooine_imperial_tier3_4", "rescue_tatooine_imperial_tier3_4_a", "inspect_tatooine_imperial_tier3_4_b",
	"assassinate_tatooine_imperial_tier3_4_c",
}

D.CHAINS = { D.M1, D.M2, D.M3, D.M4 }

D.GLOBALS = {}

for _, chain in ipairs(D.CHAINS) do
	for _, g in ipairs(chain) do
		D.GLOBALS[#D.GLOBALS + 1] = g
	end
end

D.HEADS = { D.M1[1], D.M2[1], D.M3[1], D.M4[1] }

-- the six Alozen globals (they register before the tier 3 globals)
D.ALOZEN_GLOBALS = A.GLOBALS

-- global -> { class, type, name, zone }
D.IDENTITY = {}

do
	local classes = {
		escort = "SpaceEscortScreenplay", recovery = "SpaceRecoveryScreenplay", inspect = "SpaceInspectScreenplay", rescue = "SpaceRescueScreenplay",
		delivery_no_pickup = "SpaceDeliveryNoPickupScreenplay", destroy_surpriseattack = "SpaceSurpriseAttackScreenplay", patrol = "SpacePatrolScreenplay",
		space_battle = "SpaceBattleScreenplay", delivery = "SpaceDeliveryScreenplay", destroy = "SpaceDestroyScreenplay", survival = "SpaceSurvivalScreenplay",
		assassinate = "SpaceAssassinateScreenplay",
	}

	local types = { "delivery_no_pickup", "destroy_surpriseattack", "space_battle", "assassinate", "delivery", "destroy", "survival", "inspect", "recovery", "rescue", "patrol", "escort" }

	for _, g in ipairs(D.GLOBALS) do
		for _, t in ipairs(types) do
			-- the longest type prefix wins (delivery_no_pickup before delivery, destroy_surpriseattack before destroy)
			if g:sub(1, #t + 1) == t .. "_" then
				D.IDENTITY[g] = { class = classes[t], type = t, name = g:sub(#t + 2), zone = D.ZONE }

				break
			end
		end
	end
end

-- Content contract 2: the squadron object's constants
D.QUEST_STRINGS = {
	TIER3_QUEST_STRING_1 = { type = "escort", name = "tatooine_imperial_tier3_1" },
	TIER3_QUEST_STRING_1_SIDE1 = { type = "recovery", name = "tatooine_imperial_tier3_1_a" },
	TIER3_QUEST_STRING_1_SIDE2 = { type = "inspect", name = "tatooine_imperial_tier3_1_b" },
	TIER3_QUEST_STRING_1_SIDE3 = { type = "rescue", name = "tatooine_imperial_tier3_1_c" },
	TIER3_QUEST_STRING_1_SIDE4 = { type = "delivery_no_pickup", name = "tatooine_imperial_tier3_1_d" },
	TIER3_QUEST_STRING_2 = { type = "inspect", name = "tatooine_imperial_tier3_2" },
	TIER3_QUEST_STRING_2_SIDE1 = { type = "destroy_surpriseattack", name = "tatooine_imperial_tier3_2_a" },
	TIER3_QUEST_STRING_2_SIDE2 = { type = "inspect", name = "tatooine_imperial_tier3_2_b" },
	TIER3_QUEST_STRING_2_SIDE3 = { type = "delivery_no_pickup", name = "tatooine_imperial_tier3_2_c" },
	TIER3_QUEST_STRING_2_SIDE4 = { type = "patrol", name = "tatooine_imperial_tier3_2_d" },
	TIER3_QUEST_STRING_2_SIDE5 = { type = "space_battle", name = "tatooine_imperial_tier3_2_e" },
	TIER3_QUEST_STRING_3 = { type = "delivery", name = "tatooine_imperial_tier3_3" },
	TIER3_QUEST_STRING_3_SIDE1 = { type = "destroy", name = "tatooine_imperial_tier3_3_b" },
	TIER3_QUEST_STRING_3_SIDE2 = { type = "escort", name = "tatooine_imperial_tier3_3_a" },
	TIER3_QUEST_STRING_3_SIDE3 = { type = "destroy_surpriseattack", name = "tatooine_imperial_tier3_3_d" },
	TIER3_QUEST_STRING_3_SIDE4 = { type = "survival", name = "tatooine_imperial_tier3_3_c" },
	TIER3_QUEST_STRING_4 = { type = "assassinate", name = "tatooine_imperial_tier3_4" },
	TIER3_QUEST_STRING_4_SIDE1 = { type = "rescue", name = "tatooine_imperial_tier3_4_a" },
	TIER3_QUEST_STRING_4_SIDE2 = { type = "inspect", name = "tatooine_imperial_tier3_4_b" },
	TIER3_QUEST_STRING_4_SIDE3 = { type = "assassinate", name = "tatooine_imperial_tier3_4_c" },
}

-- the constants in chain order (the order of D.GLOBALS)
D.QUEST_STRING_FIELDS = {
	"TIER3_QUEST_STRING_1", "TIER3_QUEST_STRING_1_SIDE1", "TIER3_QUEST_STRING_1_SIDE2", "TIER3_QUEST_STRING_1_SIDE3", "TIER3_QUEST_STRING_1_SIDE4",
	"TIER3_QUEST_STRING_2", "TIER3_QUEST_STRING_2_SIDE1", "TIER3_QUEST_STRING_2_SIDE2", "TIER3_QUEST_STRING_2_SIDE3", "TIER3_QUEST_STRING_2_SIDE4", "TIER3_QUEST_STRING_2_SIDE5",
	"TIER3_QUEST_STRING_3", "TIER3_QUEST_STRING_3_SIDE1", "TIER3_QUEST_STRING_3_SIDE2", "TIER3_QUEST_STRING_3_SIDE3", "TIER3_QUEST_STRING_3_SIDE4",
	"TIER3_QUEST_STRING_4", "TIER3_QUEST_STRING_4_SIDE1", "TIER3_QUEST_STRING_4_SIDE2", "TIER3_QUEST_STRING_4_SIDE3",
}

-- Status names of the four missions: "<playerID>tatooine_imperial_tier3_<n>:attempted" / ":reward" (head names)
D.STATUS = {
	"tatooine_imperial_tier3_1", "tatooine_imperial_tier3_2", "tatooine_imperial_tier3_3", "tatooine_imperial_tier3_4",
}

function D.statusKeys()
	local out = {}

	for _, name in ipairs(D.STATUS) do
		out[#out + 1] = name .. ":attempted"
		out[#out + 1] = name .. ":reward"
	end

	return out
end

-- Data mapping 2: name -> { x, z, y } (Core3 x, z, y = patrol point file = buildout fltPX, fltPY, fltPZ truncated)
D.POINTS = {
	tatooine_imperial_tier3_escort1_1 = { 2340, -4531, 7123 },
	tatooine_imperial_tier3_escort1_2 = { -3468, -4500, 3945 },
	tatooine_imperial_tier3_escort1_3 = { -3809, -1542, -558 },
	tatooine_imperial_tier3_escort1_4 = { 2909, 774, -4383 },
	tatooine_imperial_tier3_recovery1_1 = { -6736, 1000, 5728 },
	tatooine_imperial_tier3_recovery1_2 = { -485, -3573, -4328 },
	tatooine_imperial_tier3_recovery1_3 = { -3234, -4013, -919 },
	tatooine_imperial_tier3_recovery1_4 = { -4015, -4056, -1966 },
	tatooine_imperial_tier3_recovery1_5 = { -4384, -3809, -3174 },
	tatooine_imperial_tier3_rescue1_1 = { 1000, -4000, -1500 },
	tatooine_imperial_tier3_rescue1_2 = { 4054, -6049, -3682 },
	tatooine_imperial_tier3_rescue1_3 = { 3070, -6422, -6716 },
	tatooine_imperial_tier3_delivery1_hq_spawner = { 4300, 2948, -5400 },
	tatooine_imperial_tier3_delivery2 = { -1000, -100, -500 },
	tatooine_imperial_tier3_patrol1_1 = { 554, -706, 2191 },
	tatooine_imperial_tier3_patrol1_2 = { 659, -2035, 3506 },
	tatooine_imperial_tier3_patrol1_3 = { -385, -2351, 5481 },
	tatooine_imperial_tier3_patrol1_4 = { -1032, -1624, 7179 },
	tatooine_imperial_tier3_battle1_spawner = { 1477, -2315, 5545 },
	tatooine_imperial_tier3_delivery3_pickup = { -5657, -3287, -6482 },
	tatooine_imperial_tier3_delivery_dropoff = { 90, -69, -1106 },
	tatooine_imperial_tier3_survival1 = { 2090, 514, 306 },
	tatooine_imperial_tier3_assassinate4_01 = { 552, 5144, -4984 },
	tatooine_imperial_tier3_assassinate4_02 = { 3996, 500, -1498 },
	tatooine_imperial_tier3_assassinate4_03 = { 3984, -3744, 4468 },
	tatooine_imperial_tier3_assassinate4_04 = { -2988, -4004, 6386 },
	tatooine_imperial_tier3_rescue2_1 = { 4764, -4609, -104 },
	tatooine_imperial_tier3_rescue2_2 = { 825, -3312, 2052 },
	tatooine_imperial_tier3_rescue2_3 = { -3703, -374, 144 },
	tatooine_imperial_tier3_assassinate1_1 = { -2000, 4300, 3000 },
	tatooine_imperial_tier3_assassinate1_2 = { -2206, 2385, 3982 },
	tatooine_imperial_tier3_assassinate1_3 = { -2017, -532, 5368 },
	tatooine_imperial_tier3_assassinate1_4 = { -153, -3292, 5758 },
}

-- the four inspect spawners (Data mapping 2; each also a row of the buildout excerpt with strSpawnerName)
D.SPAWNERS = {
	tatooine_imperial_tier3_rebscout_spawner = { -2450, -3052, 1234 },
	tatooine_imperial_tier3_inspect2_spawner = { -5009, 4104, 6001 },
	tatooine_imperial_tier3_inspect3_spawner = { 6009, -7001, -1095 },
	tatooine_imperial_tier3_inspect4_spawner = { 2000, 6500, 1200 },
}

D.ITEM_ROOT = "object/tangible/ship/components/"

-- Source inventory 1 (J3:228-259), one item per head
D.ITEMS = {
	[1] = D.ITEM_ROOT .. "weapon_capacitor/cap_mission_reward_imperial_rendili_k_class.iff",
	[2] = D.ITEM_ROOT .. "droid_interface/ddi_mission_reward_imperial_sfs_military_grade.iff",
	[3] = D.ITEM_ROOT .. "reactor/rct_mission_reward_imperial_sds_high_output.iff",
	[4] = D.ITEM_ROOT .. "engine/eng_mission_reward_imperial_cygnus_megadrive.iff",
}

D.CREDITS = 25000
D.FORWARD = { x = -0.004857, z = 0.167584, y = 0.985846 }
D.OFFICER_MOBILE = "object/mobile/shared_dressed_imperial_officer_m.iff"

-- the 20 distinct ships of FD-12
D.SHIPS = {
	"imp_engineer_shuttle_tier3", "imp_freighterlight_tier3", "imp_lambda_decoy_shuttle_tier3", "imp_lambda_shuttle_tier3", "imp_tie_interceptor_tier3",
	"reb_awing_tier3", "reb_awing_tier4", "reb_bwing_tier3", "reb_bwing_tier4", "reb_xwing_tier3", "reb_xwing_tier4", "reb_ykl37r_tier3", "reb_ywing_tier3",
	"reb_ywing_tier4", "reb_z95_tier3", "reb_z95_tier4", "rebel_command_shuttle_tier4", "rebel_controlled_shuttle_tier3", "rebel_scout_fighter_tier3",
	"rebel_scout_shuttle_tier3",
}

-- the three inspect ships FD-9 gives a cargoString: ship -> { cargo, quests that inspect it }
D.CARGO_SHIPS = {
	rebel_scout_fighter_tier3 = { cargo = "encrypted_rebel_data", smt = 1462, quests = { D.M1[3], D.M2[1] } },
	rebel_scout_shuttle_tier3 = { cargo = "rebel_plans", smt = 1464, quests = { D.M2[3] } },
	rebel_command_shuttle_tier4 = { cargo = "stolen_data", smt = 1434, quests = { D.M4[3] } },
}

local function point(name, extra)
	local p = D.POINTS[name] or D.SPAWNERS[name]

	assert(p ~= nil, "no spec point " .. tostring(name))

	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra or {}) do
		t[k] = v
	end

	return t
end

local function pts(names, extra, number)
	local out = {}

	for i, n in ipairs(names) do
		local e = {}

		for k, v in pairs(extra or {}) do
			e[k] = v
		end

		if number then
			e[number] = i
		end

		out[i] = point(n, e)
	end

	return out
end

local function numbered(prefix, from, to, width)
	local out = {}

	for i = from, to do
		out[#out + 1] = prefix .. (width and string.format("%02d", i) or tostring(i))
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

local function item(n) return { { species = { -1 }, item = D.ITEMS[n] } } end

local function spawnerEntry(name)
	local s = D.SPAWNERS[name]

	return { spawnName = name, x = s[1], z = s[2], y = s[3] }
end

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function D.expected()
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES
	local P = "tatooine_imperial_tier3_"

	local function base(global, more)
		local id = D.IDENTITY[global]
		local t = { className = global, questType = id.type, questName = id.name, questZone = id.zone }

		for k, v in pairs(more) do
			t[k] = v
		end

		return t
	end

	local function child(parent, more)
		local pid = D.IDENTITY[parent]

		more.parentQuest, more.parentQuestType, more.parentQuestName = parent, pid.type, pid.name

		return more
	end

	local function split(nextGlobal, delay, splitType, extra)
		local nid = D.IDENTITY[nextGlobal]
		local t = { sideQuest = true, sideQuestType = nid.type, sideQuestName = nid.name, sideQuestSplitType = splitType or ST.COMPLETION, sideQuestDelay = delay or 5 }

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

	local END = { sideQuest = false, sideQuestType = "" }
	local seqDelivery = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local seqSurvival = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local seqRescue = SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local a3, a4, b3, x3, x4, y3, z3, z4 = "reb_awing_tier3", "reb_awing_tier4", "reb_bwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4", "reb_ywing_tier3", "reb_z95_tier3", "reb_z95_tier4"
	local lambda = "imp_lambda_shuttle_tier3"
	local out = {}

	-- Mission 1: escort, recovery, inspect, rescue, delivery_no_pickup (escort 1 splits after 20 s, A-2 amendment)
	out[D.M1[1]] = base(D.M1[1], merge({ creditReward = D.CREDITS, itemReward = item(1) }, split(D.M1[2], 20), {
		escortShips = { "imp_engineer_shuttle_tier3" },
		escortPoints = pts(numbered(P .. "escort1_", 1, 4), { zoneName = D.ZONE, radius = 250 }, "escortNumber"),
		attackDelay = 120,
		attackShips = { { x3, x3, y3 }, { y3, z3, z3 } },
		tauntData = { goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2 },
	}))
	out[D.M1[2]] = base(D.M1[2], merge(child(D.M1[1], {}), split(D.M1[3]), {
		arrivalDelay = 30, recoveryDelay = 30, recoverShip = "rebel_controlled_shuttle_tier3",
		recoveryConversationMobile = D.OFFICER_MOBILE,
		escortShips = { a3, a3, a3, a3, b3 },
		preRecoveryPoints = pts({ P .. "recovery1_1", P .. "recovery1_2" }, { radius = 250 }, "escortNumber"),
		recoveryPoints = pts({ P .. "recovery1_3", P .. "recovery1_4", P .. "recovery1_5" }, { radius = 250 }, "escortNumber"),
		attackDelay = 120,
		attackShips = { { a3, a3, a3 } },
		tauntData = { panicCount = 5, thanksCount = 5 },
	}))
	out[D.M1[3]] = base(D.M1[3], merge(child(D.M1[2], {}), split(D.M1[4]), {
		shipList = { "rebel_scout_fighter_tier3" },
		validSpawns = { spawnerEntry(P .. "rebscout_spawner") },
		giveSpawnWaypoint = 1, cargo = "encrypted_rebel_data",
	}))
	out[D.M1[4]] = base(D.M1[4], merge(child(D.M1[3], {}), split(D.M1[5]), {
		recoveryPath = pts(numbered(P .. "rescue1_", 1, 3)),
		targetShipType = "imp_freighterlight_tier3", targetArrivalDelay = 30,
		attackShipLists = { { b3, x3, x3 }, { a3, a3, b3 } },
		attackPeriod = 120, attackListType = seqRescue, numResponses = 5,
	}))
	out[D.M1[5]] = base(D.M1[5], merge(child(D.M1[4], {}), END, {
		deliveryShip = lambda,
		deliveryPoint = point(P .. "delivery1_hq_spawner"),
		attackShipLists = { rep(a3, 4) },
		attackPeriod = 90, attackListType = seqDelivery,
	}))

	-- Mission 2: inspect, surprise attack, inspect, delivery_no_pickup, patrol (PATROL_POINT at 3), space battle
	out[D.M2[1]] = base(D.M2[1], merge({ creditReward = D.CREDITS, itemReward = item(2) }, split(D.M2[2], 10), {
		shipList = { "rebel_scout_fighter_tier3" },
		validSpawns = { spawnerEntry(P .. "inspect2_spawner") },
		giveSpawnWaypoint = 1, cargo = "encrypted_rebel_data",
	}))
	out[D.M2[2]] = base(D.M2[2], merge(child(D.M2[1], {}), split(D.M2[3]), {
		surpriseAttackShips = { zone = D.ZONE, spawns = { { count = 5, shipName = a3 } } },
	}))
	out[D.M2[3]] = base(D.M2[3], merge(child(D.M2[2], {}), split(D.M2[4], 10), {
		shipList = { "rebel_scout_shuttle_tier3" },
		validSpawns = { spawnerEntry(P .. "inspect3_spawner") },
		giveSpawnWaypoint = 1, cargo = "rebel_plans",
	}))
	out[D.M2[4]] = base(D.M2[4], merge(child(D.M2[3], {}), split(D.M2[5]), {
		deliveryShip = lambda,
		deliveryPoint = point(P .. "delivery2"),
		attackShipLists = { { x3, x3, x4 } },
		attackPeriod = 90, attackListType = seqDelivery,
	}))
	out[D.M2[5]] = base(D.M2[5], merge(child(D.M2[4], {}), split(D.M2[6], 20, ST.PATROL_POINT, { sideQuestPatrolStart = 3 }), {
		patrolPoints = pts(numbered(P .. "patrol1_", 1, 4), { radius = 150 }, "patrolNumber"),
	}))
	out[D.M2[6]] = base(D.M2[6], merge(child(D.M2[5], {}), END, {
		battlePoint = point(P .. "battle1_spawner", { forward = D.FORWARD }),
		damageMultiplier = 3, allyArrivalDelay = 10, enemyArrivalDelay = 120,
		allyOriginDist = 400, enemyOriginDist = -400, allyArrivalDist = 200, enemyArrivalDist = 200,
		allyForce = rep("imp_tie_interceptor_tier3", 6),
		enemyForce = cat(rep(a3, 4), rep(x3, 4), { x4, "reb_ykl37r_tier3" }),
	}))

	-- Mission 3: delivery, destroy, escort (ATTACK_WAVE after 3 cleared waves, delay 10), surprise attack, survival
	out[D.M3[1]] = base(D.M3[1], merge({ creditReward = D.CREDITS, itemReward = item(3) }, split(D.M3[2]), {
		pickupPoint = point(P .. "delivery3_pickup"),
		deliveryPoint = point(P .. "delivery_dropoff"),
		pickupShip = lambda, deliveryShip = lambda,
		attackShipLists = { { x3, x3, x4 }, { x3, x3, x3, x4 }, { a3, a3, a3, a3, a4 } },
		attackPeriod = 90, attackListType = seqDelivery,
	}))
	out[D.M3[2]] = base(D.M3[2], merge(child(D.M3[1], {}), split(D.M3[3]), {
		killsRequired = 5,
		shipLocations = {},
		shipTypes = { a3, a4, b3, "reb_bwing_tier4", x3, x4, y3, "reb_ywing_tier4", z3, z4 },
	}))
	out[D.M3[3]] = base(D.M3[3], merge(child(D.M3[2], {}), split(D.M3[4], 10, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.ATTACK_WAVE, { sideQuestAttackWave = 3 }), {
		escortShips = { "imp_lambda_decoy_shuttle_tier3" },
		escortPoints = pts(numbered(P .. "escort1_", 1, 4), { zoneName = D.ZONE, radius = 250 }, "escortNumber"),
		attackDelay = 70,
		attackShips = { { b3, x3, x3 } },
		tauntData = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 },
	}))
	out[D.M3[4]] = base(D.M3[4], merge(child(D.M3[3], {}), split(D.M3[5]), {
		surpriseAttackShips = { zone = D.ZONE, spawns = { { count = 6, shipName = a3 } } },
	}))
	out[D.M3[5]] = base(D.M3[5], merge(child(D.M3[4], {}), END, {
		transmissionPoint = point(P .. "survival1"),
		totalTransmissionTime = 600, timesToUpdateProgress = 10, transmissionStartDelay = 60, delayToFirstAttack = 5,
		attackShipLists = {
			{ x3, x3, x3, x3, x4 }, { z3, z3, z3, z4, z3 }, { a3, a3, a3, a3, a4 }, { b3, b3, x3, x3, x3 }, { x3, x3, "reb_ykl37r_tier3", a3, a3 },
		},
		attackPeriod = 120, attackListType = seqSurvival,
	}))

	-- Mission 4: assassinate, rescue, inspect, assassinate
	out[D.M4[1]] = base(D.M4[1], merge({ creditReward = D.CREDITS, itemReward = item(4) }, split(D.M4[2]), {
		arrivalDelay = 15, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = x3, escorts = rep(x3, 5) },
		targetPatrols = pts(numbered(P .. "assassinate4_", 1, 4, true)),
	}))
	out[D.M4[2]] = base(D.M4[2], merge(child(D.M4[1], {}), split(D.M4[3]), {
		recoveryPath = pts(numbered(P .. "rescue2_", 1, 3)),
		targetShipType = lambda, targetArrivalDelay = 0,
		attackShipLists = { { x3, x3, x3, x4 }, { b3, z3, z3, z3 }, rep(a3, 5) },
		attackPeriod = 90, attackListType = seqRescue, numResponses = 5,
	}))
	out[D.M4[3]] = base(D.M4[3], merge(child(D.M4[2], {}), split(D.M4[4]), {
		shipList = { "rebel_command_shuttle_tier4" },
		validSpawns = { spawnerEntry(P .. "inspect4_spawner") },
		giveSpawnWaypoint = 1, cargo = "stolen_data",
	}))
	out[D.M4[4]] = base(D.M4[4], merge(child(D.M4[3], {}), END, {
		arrivalDelay = 30, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = "rebel_command_shuttle_tier4", escorts = rep(x3, 6) },
		targetPatrols = pts(numbered(P .. "assassinate1_", 1, 4)),
	}))

	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

-- The server's load: every squadron file (and Oberhaur's and Alozen's pieces, through storm_tier2_alozen_data.lua)
function D.load()
	A.load()
end

function D.problems() return A.problems() end

function D.quest(global)
	A.load()

	return H.expectGlobal(global, "Storm tier 3 quest table (storm-tier3-denner-missions). Load problems: " .. A.problems())
end

function D.squadron() return T.squadron() end

local function crc(global)
	local id = D.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

D.crc = crc

-- Quest state helpers on a built pilot. state: "complete" | "active" | "none"
function D.setState(player, global, state)
	local key = crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function D.state(player, global)
	local key = crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- A Storm pilot who finished tier 2 (all four tier 1 skills, all four tier 2 skills, pilot tier 3, Alozen's three missions paid), standing in a
-- ship in space_endor. Options:
--   missions   k: Denner's missions 1..k won (every chain member complete), :attempted and :reward set (default 0)
--   t3         list of TRAIN indexes (storm_tier2_data.lua T.TRAIN order) of the tier 3 skills held (default none)
--   pilotTier  ghost pilot tier (default 3, or 4 when all four tier 3 skills are held)
--   active     global of a tier 3 member left active in the journal
--   every other option is storm_tier2_alozen_data.lua's A.pilot (m, t2, standing, squadron, inventory, ...)
function D.pilot(o)
	o = o or {}
	D.load()

	local base = {}

	for k, v in pairs(o) do
		base[k] = v
	end

	base.missions, base.t3, base.active = nil, nil, nil
	base.m = o.m or 3
	base.t2 = o.t2 or { 1, 2, 3, 4 }
	base.pilotTier = o.pilotTier or ((#(o.t3 or {}) >= 4) and 4 or 3)
	base.skills = {}

	for k, v in pairs(o.skills or {}) do
		base.skills[k] = v
	end

	for _, i in ipairs(o.t3 or {}) do
		base.skills[#base.skills + 1] = (T.TRAIN[i].skill:gsub("_02$", "_03"))
	end

	local player = A.pilot(base)

	for n = 1, o.missions or 0 do
		for _, global in ipairs(D.CHAINS[n]) do
			D.setState(player, global, "complete")
		end

		H.setQuestStatus(player, D.STATUS[n] .. ":attempted", 1)
		H.setQuestStatus(player, D.STATUS[n] .. ":reward", 1)
	end

	if o.active then
		D.setState(player, o.active, "active")
	end

	return player
end

-- An Imperial pilot in an Imperial-faction ship in `zone` (default space_endor), the way the runtime tests start a quest
function D.flyer(zone)
	A.load()

	return H.newPlayer({
		zone = zone or D.ZONE,
		pilot = "imperial",
		ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("imperial") },
	})
end

return D
