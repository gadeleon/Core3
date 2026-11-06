-- Shared test data and builders for Storm Squadron tier 4, Part A (Admiral Kilnstrider's missions), not a test file.
-- Spec: .claude/work/storm-tier4-kilnstrider-missions/01-spec.md (Content contract 1 and 2, Data mapping 1 and 2, Appendix B).
-- Part B (storm-tier4-kilnstrider: the conversation) extends this file and keeps every export below.
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of agreeing with itself:
--   D.GLOBALS / D.IDENTITY / D.CLASS   the 20 quest globals in registration order, and their class, type, name and zone (Content contract 1)
--   D.M1 .. D.M4 / D.CHAINS / D.DUTIES the four story chains (chain order) and the four duties
--   D.QUEST_STRINGS / D.QUEST_STRING_FIELDS   the 20 TIER4_QUEST_STRING_* constants (Content contract 2) and the met key
--   D.statusKeys(player)               the 9 status keys (8 head :attempted / :reward keys and the met key)
--   D.POINTS / D.SPAWNERS / D.POINT_ZONE   Data mapping 2: the 71 nav points and the inspect spawner, Core3 x, z, y, and their zone
--   D.expected()                       Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   D.REWARDS                          Content contract 3 (spec literals, D-A2: the SWG trainer script tatooine_imperial_tier4.java is Part B's fixture)
--   D.load() / D.quest(global)         the server's load; one quest table
--   D.flyer(zone)                      an Imperial pilot in an Imperial ship in `zone` (pilot tier 4), for the runtime tests
--   D.pilot{...}                       a Storm graduate of tier 3 (pilot tier 4) with optional tier 4 state, see the option list at D.pilot

local H = require("harness")
local D3 = require("storm_tier3_data")
local A = require("storm_tier2_alozen_data")
local T = require("storm_tier2_data")

local D = {}

D.SQUADRON_FILE = "screenplays/space/squadrons/StormSquadronScreenplay.lua"
D.ZONE = "space_endor"
D.ZONE_M4 = "space_dantooine"
D.P = "tatooine_imperial_tier4_"

D.M1 = {
	"patrol_tatooine_imperial_tier4_1", "destroy_surpriseattack_tatooine_imperial_tier4_1_a", "space_battle_tatooine_imperial_tier4_1_b",
	"inspect_tatooine_imperial_tier4_1_c", "delivery_no_pickup_tatooine_imperial_tier4_1_d",
}
D.M2 = {
	"recovery_tatooine_imperial_tier4_2", "recovery_tatooine_imperial_tier4_2_a", "delivery_tatooine_imperial_tier4_2_b", "delivery_no_pickup_tatooine_imperial_tier4_2_c",
}
D.M3 = { "escort_tatooine_imperial_tier4_3", "rescue_tatooine_imperial_tier4_3_a", "space_battle_tatooine_imperial_tier4_3_b" }
D.M4 = {
	"assassinate_tatooine_imperial_tier4_4", "assassinate_tatooine_imperial_tier4_4_a", "recovery_tatooine_imperial_tier4_4_b", "assassinate_tatooine_imperial_tier4_4_c",
}
D.DUTIES = {
	"destroy_duty_tatooine_imperial_tier4_destroyduty_1", "escort_duty_tatooine_imperial_tier4_escortduty_1",
	"recovery_duty_tatooine_imperial_tier4_recoveryduty_1", "rescue_duty_tatooine_imperial_tier4_rescueduty_1",
}

D.CHAINS = { D.M1, D.M2, D.M3, D.M4 }
D.HEADS = { D.M1[1], D.M2[1], D.M3[1], D.M4[1] }

-- the 20 globals in registration order (the 16 story tables in chain order, then the duties)
D.GLOBALS = {}

for _, chain in ipairs(D.CHAINS) do
	for _, g in ipairs(chain) do
		D.GLOBALS[#D.GLOBALS + 1] = g
	end
end

for _, g in ipairs(D.DUTIES) do
	D.GLOBALS[#D.GLOBALS + 1] = g
end

D.STORY = {}

for i = 1, 16 do
	D.STORY[i] = D.GLOBALS[i]
end

-- the 40 earlier Storm globals: Colzet's six, Oberhaur's six, the Nym-free Alozen six, Denner's twenty (registered before the tier 4 globals)
D.TIER3_GLOBALS = D3.GLOBALS
D.ALOZEN_GLOBALS = A.GLOBALS

D.CLASS = {
	patrol = "SpacePatrolScreenplay", destroy_surpriseattack = "SpaceSurpriseAttackScreenplay", space_battle = "SpaceBattleScreenplay", inspect = "SpaceInspectScreenplay",
	delivery_no_pickup = "SpaceDeliveryNoPickupScreenplay", recovery = "SpaceRecoveryScreenplay", delivery = "SpaceDeliveryScreenplay", escort = "SpaceEscortScreenplay",
	rescue = "SpaceRescueScreenplay", assassinate = "SpaceAssassinateScreenplay", destroy_duty = "SpaceDutyDestroyScreenplay", escort_duty = "SpaceDutyEscortScreenplay",
	recovery_duty = "SpaceDutyRecoveryScreenplay", rescue_duty = "SpaceDutyRescueScreenplay",
}

-- global -> { class, type, name, zone }
D.IDENTITY = {}

do
	-- the longest type prefix wins (delivery_no_pickup before delivery, escort_duty before escort, ...)
	local types = {
		"delivery_no_pickup", "destroy_surpriseattack", "destroy_duty", "escort_duty", "recovery_duty", "rescue_duty", "space_battle", "assassinate", "delivery",
		"inspect", "recovery", "rescue", "patrol", "escort",
	}

	for _, g in ipairs(D.GLOBALS) do
		for _, t in ipairs(types) do
			if g:sub(1, #t + 1) == t .. "_" then
				D.IDENTITY[g] = { class = D.CLASS[t], type = t, name = g:sub(#t + 2), zone = D.ZONE }

				break
			end
		end
	end

	for _, g in ipairs(D.M4) do
		D.IDENTITY[g].zone = D.ZONE_M4
	end
end

-- Content contract 2: the squadron object's constants
D.QUEST_STRINGS = {
	TIER4_QUEST_STRING_1 = { type = "patrol", name = "tatooine_imperial_tier4_1" },
	TIER4_QUEST_STRING_1_SIDE1 = { type = "destroy_surpriseattack", name = "tatooine_imperial_tier4_1_a" },
	TIER4_QUEST_STRING_1_SIDE2 = { type = "space_battle", name = "tatooine_imperial_tier4_1_b" },
	TIER4_QUEST_STRING_1_SIDE3 = { type = "inspect", name = "tatooine_imperial_tier4_1_c" },
	TIER4_QUEST_STRING_1_SIDE4 = { type = "delivery_no_pickup", name = "tatooine_imperial_tier4_1_d" },
	TIER4_QUEST_STRING_2 = { type = "recovery", name = "tatooine_imperial_tier4_2" },
	TIER4_QUEST_STRING_2_SIDE1 = { type = "recovery", name = "tatooine_imperial_tier4_2_a" },
	TIER4_QUEST_STRING_2_SIDE2 = { type = "delivery", name = "tatooine_imperial_tier4_2_b" },
	TIER4_QUEST_STRING_2_SIDE3 = { type = "delivery_no_pickup", name = "tatooine_imperial_tier4_2_c" },
	TIER4_QUEST_STRING_3 = { type = "escort", name = "tatooine_imperial_tier4_3" },
	TIER4_QUEST_STRING_3_SIDE1 = { type = "rescue", name = "tatooine_imperial_tier4_3_a" },
	TIER4_QUEST_STRING_3_SIDE2 = { type = "space_battle", name = "tatooine_imperial_tier4_3_b" },
	TIER4_QUEST_STRING_4 = { type = "assassinate", name = "tatooine_imperial_tier4_4" },
	TIER4_QUEST_STRING_4_SIDE1 = { type = "assassinate", name = "tatooine_imperial_tier4_4_a" },
	TIER4_QUEST_STRING_4_SIDE2 = { type = "recovery", name = "tatooine_imperial_tier4_4_b" },
	TIER4_QUEST_STRING_4_SIDE3 = { type = "assassinate", name = "tatooine_imperial_tier4_4_c" },
	TIER4_QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "tatooine_imperial_tier4_destroyduty_1" },
	TIER4_QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "tatooine_imperial_tier4_escortduty_1" },
	TIER4_QUEST_STRING_DUTY_3 = { type = "recovery_duty", name = "tatooine_imperial_tier4_recoveryduty_1" },
	TIER4_QUEST_STRING_DUTY_4 = { type = "rescue_duty", name = "tatooine_imperial_tier4_rescueduty_1" },
}

-- the constants in the order of D.GLOBALS
D.QUEST_STRING_FIELDS = {
	"TIER4_QUEST_STRING_1", "TIER4_QUEST_STRING_1_SIDE1", "TIER4_QUEST_STRING_1_SIDE2", "TIER4_QUEST_STRING_1_SIDE3", "TIER4_QUEST_STRING_1_SIDE4",
	"TIER4_QUEST_STRING_2", "TIER4_QUEST_STRING_2_SIDE1", "TIER4_QUEST_STRING_2_SIDE2", "TIER4_QUEST_STRING_2_SIDE3",
	"TIER4_QUEST_STRING_3", "TIER4_QUEST_STRING_3_SIDE1", "TIER4_QUEST_STRING_3_SIDE2",
	"TIER4_QUEST_STRING_4", "TIER4_QUEST_STRING_4_SIDE1", "TIER4_QUEST_STRING_4_SIDE2", "TIER4_QUEST_STRING_4_SIDE3",
	"TIER4_QUEST_STRING_DUTY_1", "TIER4_QUEST_STRING_DUTY_2", "TIER4_QUEST_STRING_DUTY_3", "TIER4_QUEST_STRING_DUTY_4",
}

D.MET_KEY = "StormSquadronScreenplay:metTier4"

-- Status names of the four missions: "<playerID>tatooine_imperial_tier4_<n>:attempted" / ":reward" (head names)
D.STATUS = { "tatooine_imperial_tier4_1", "tatooine_imperial_tier4_2", "tatooine_imperial_tier4_3", "tatooine_imperial_tier4_4" }

-- The 9 status-key suffixes (Content contract 2); the player's object id is prepended by H.setQuestStatus / H.getQuestStatus
function D.statusKeys()
	local out = {}

	for _, name in ipairs(D.STATUS) do
		out[#out + 1] = name .. ":attempted"
		out[#out + 1] = name .. ":reward"
	end

	out[#out + 1] = D.MET_KEY

	return out
end

-- Data mapping 2: name -> { x, z, y } (Core3 x, z, y = patrol point file = buildout fltPX, fltPY, fltPZ truncated toward zero)
D.POINTS = {
	tatooine_imperial_tier4_patrol1_1 = { -5749, -224, -4615 },
	tatooine_imperial_tier4_patrol1_2 = { -7378, -1977, -4819 },
	tatooine_imperial_tier4_patrol1_3 = { -6853, -4068, -7641 },
	tatooine_imperial_tier4_patrol1_4 = { -3362, -3184, -3464 },
	tatooine_imperial_tier4_spacebattle1 = { -3291, -3042, -3060 },
	tatooine_imperial_tier4_delivery1 = { -5404, -2088, -5153 },
	tatooine_imperial_tier4_recovery1_1 = { 4943, -2102, 5342 },
	tatooine_imperial_tier4_recovery1_2 = { -1020, -2352, 3977 },
	tatooine_imperial_tier4_recovery1_3 = { -6409, -1895, 930 },
	tatooine_imperial_tier4_recovery1_4 = { -6883, 2582, -4552 },
	tatooine_imperial_tier4_recovery1_5 = { -3404, -2039, -3974 },
	tatooine_imperial_tier4_recovery1_6 = { -45, -2070, -534 },
	tatooine_imperial_tier4_recovery1_7 = { 3055, -2194, 3450 },
	tatooine_imperial_tier4_recovery2_1 = { 6484, 566, -4504 },
	tatooine_imperial_tier4_recovery2_2 = { 3570, 2552, 1242 },
	tatooine_imperial_tier4_recovery2_3 = { -480, 4414, 4424 },
	tatooine_imperial_tier4_recovery2_4 = { -2996, 6312, -34 },
	tatooine_imperial_tier4_recovery2_5 = { -965, -20, 970 },
	tatooine_imperial_tier4_recovery2_6 = { 2498, -942, 3428 },
	tatooine_imperial_tier4_recovery2_7 = { 5008, -1982, 5994 },
	tatooine_imperial_tier4_pickup1 = { -5329, -1922, -5037 },
	tatooine_imperial_tier4_deliver1 = { -551, -2040, -145 },
	tatooine_imperial_tier4_deliver2 = { -884, -2120, -290 },
	tatooine_imperial_tier4_escort1_1 = { -5348, -1967, -5055 },
	tatooine_imperial_tier4_escort1_2 = { -927, -1526, -5451 },
	tatooine_imperial_tier4_escort1_3 = { 1789, -1285, -5497 },
	tatooine_imperial_tier4_escort1_4 = { 4366, -1130, -5212 },
	tatooine_imperial_tier4_escort1_5 = { 6356, -1088, -4928 },
	tatooine_imperial_tier4_rescue1_1 = { 6480, -1213, -4966 },
	tatooine_imperial_tier4_rescue1_2 = { 379, -1769, -5254 },
	tatooine_imperial_tier4_rescue1_3 = { -2016, -1895, -5391 },
	tatooine_imperial_tier4_spacebattle2 = { -1804, -578, -1659 },
	tatooine_imperial_tier4_escortduty_1 = { 6016, 6811, -6039 },
	tatooine_imperial_tier4_escortduty_2 = { 4793, 5977, -6393 },
	tatooine_imperial_tier4_escortduty_3 = { 3202, 4875, -6867 },
	tatooine_imperial_tier4_escortduty_4 = { 1797, 3779, -6762 },
	tatooine_imperial_tier4_escortduty_5 = { 131, 2466, -6593 },
	tatooine_imperial_tier4_escortduty_6 = { -1611, 1162, -6352 },
	tatooine_imperial_tier4_escortduty_7 = { -3268, -61, -6124 },
	tatooine_imperial_tier4_escortduty_8 = { -4423, -914, -5950 },
	tatooine_imperial_tier4_escortduty_9 = { -5380, -2054, -5157 },
	tatooine_imperial_tier4_recoveryduty_1 = { -778, 1426, -905 },
	tatooine_imperial_tier4_recoveryduty_2 = { -1454, 3074, -1580 },
	tatooine_imperial_tier4_recoveryduty_3 = { -2232, 4616, -2283 },
	tatooine_imperial_tier4_recoveryduty_4 = { -2849, 6172, -2900 },
	tatooine_imperial_tier4_recoveryduty_5 = { 70, 3633, -2133 },
	tatooine_imperial_tier4_recoveryduty_6 = { 2045, 4717, -3428 },
	tatooine_imperial_tier4_recoveryduty_7 = { 3980, 5779, -4704 },
	tatooine_imperial_tier4_recoveryduty_8 = { 6111, 7006, -6049 },
	tatooine_imperial_tier4_rescueduty_1 = { -631, -2331, -4019 },
	tatooine_imperial_tier4_rescueduty_2 = { -2251, -2058, -6515 },
	tatooine_imperial_tier4_rescueduty_3 = { -3195, 2390, -5645 },
	tatooine_imperial_tier4_assassinate1_1 = { 2690, 2543, -2188 },
	tatooine_imperial_tier4_assassinate1_2 = { 3516, 3858, -2776 },
	tatooine_imperial_tier4_assassinate1_3 = { 3954, 5306, -3320 },
	tatooine_imperial_tier4_assassinate1_4 = { 4246, 7195, -4046 },
	tatooine_imperial_tier4_assassinate2_1 = { 4949, 6749, -2654 },
	tatooine_imperial_tier4_assassinate2_3 = { 4748, 5533, -186 },
	tatooine_imperial_tier4_assassinate2_4 = { 2523, 5429, 764 },
	tatooine_imperial_tier4_recovery3_1 = { 5928, 5349, -4448 },
	tatooine_imperial_tier4_recovery3_2 = { -1856, 5251, 2377 },
	tatooine_imperial_tier4_recovery3_3 = { -6393, 4381, 4443 },
	tatooine_imperial_tier4_recovery3_4 = { -5678, 3471, 7284 },
	tatooine_imperial_tier4_recovery3_5 = { -3399, 2785, 7662 },
	tatooine_imperial_tier4_recovery3_6 = { -5494, 2785, 2820 },
	tatooine_imperial_tier4_recovery3_7 = { -2758, 3137, 1630 },
	tatooine_imperial_tier4_recovery3_8 = { -1368, 3851, -1723 },
	tatooine_imperial_tier4_assassinate3_1 = { -564, 4538, -1545 },
	tatooine_imperial_tier4_assassinate3_2 = { 2413, 4362, -291 },
	tatooine_imperial_tier4_assassinate3_3 = { 4353, 4266, 525 },
	tatooine_imperial_tier4_assassinate3_4 = { 6500, 4160, 1429 },
}

-- the inspect spawner (SPE:220; also a strSpawnerName row, BOE 312)
D.SPAWNERS = {
	tatooine_imperial_tier4_endscout1 = { -3606, -2695, -3771 },
}

-- zone of each point: the assassinate1..3 and recovery3 points are Dantooine, every other point Endor (Data mapping 2)
function D.POINT_ZONE(name)
	if name:match("^tatooine_imperial_tier4_assassinate%d_") or name:match("^tatooine_imperial_tier4_recovery3_") then
		return D.ZONE_M4
	end

	return D.ZONE
end

D.ITEM_ROOT = "object/tangible/ship/components/"

-- Content contract 3 (spec literals)
D.CREDITS = 10000
D.REWARDS = {
	[1] = { credits = 10000, item = D.ITEM_ROOT .. "weapon/wpn_mission_reward_imperial_sds_boltdriver.iff" },
	[2] = { credits = 10000, item = D.ITEM_ROOT .. "shield_generator/shd_mission_reward_imperial_cygnus_holoscreen.iff" },
	[3] = { credits = 10000, item = D.ITEM_ROOT .. "armor/arm_mission_reward_imperial_rss_special_durasteel.iff" },
	[4] = { credits = 10000, item = D.ITEM_ROOT .. "reactor/rct_mission_reward_imperial_rss_advanced_military.iff" },
}

D.FORWARD_1B = { x = -0.162564, z = -0.321512, y = -0.932847 }
D.FORWARD_3B = { x = -0.699074, z = -0.273777, y = -0.660562 }
D.OFFICER_MOBILE = "object/mobile/shared_space_comm_imperial_officer_02.iff"

-- the 26 distinct ships of the Data mapping (all have a ship_mobile/ships file)
D.SHIPS = {
	"bothan_spynet_fighter_tier4", "bothan_spynet_shuttle_tier4", "imp_decimator_tier4", "imp_freighterheavy_tier4", "imp_freighterlight_tier4",
	"imp_freightermedium_tier4", "imp_imperial_gunboat_tier4", "imp_lambda_inquisitor_shuttle_tier4", "imp_lambda_shuttle_tier4", "imp_tie_bomber_tier4",
	"imp_tie_interceptor_tier4", "reb_awing_tier4", "reb_bwing_tier3", "reb_bwing_tier4", "reb_gunboat_tier4", "reb_xwing_tier4", "reb_ykl37r_tier4",
	"reb_ywing_tier4", "rebel_command_vessel_tier4", "rebel_command_vessel_weak_tier2", "rebel_endscout_tier4", "red_skull_freighter_tier4",
	"red_skull_pirate_heavy_tier4", "red_skull_pirate_heavy_tier5", "red_skull_pirate_light_tier4", "red_skull_pirate_medium_tier4",
}

-- the inspect ship (FA-4): ship -> cargo
D.CARGO_SHIP = { ship = "rebel_endscout_tier4", cargo = "rebel_battle_plans", smt = 1442 }

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

-- prefix .. from .. to (names of a numbered point run)
local function numbered(prefix, from, to)
	local out = {}

	for i = from, to do
		out[#out + 1] = prefix .. tostring(i)
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

local function item(n) return { { species = { -1 }, item = D.REWARDS[n].item } } end

local function spawnerEntry(name)
	local s = D.SPAWNERS[name]

	return { spawnName = name, x = s[1], z = s[2], y = s[3] }
end

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function D.expected()
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES
	local P = D.P

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
	local seqRescue = SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local a, b, x, y = "reb_awing_tier4", "reb_bwing_tier4", "reb_xwing_tier4", "reb_ywing_tier4"
	local fighter, shuttle = "bothan_spynet_fighter_tier4", "bothan_spynet_shuttle_tier4"
	local L, M, H4 = "red_skull_pirate_light_tier4", "red_skull_pirate_medium_tier4", "red_skull_pirate_heavy_tier4"
	local E = D.ZONE
	local out = {}

	local function recoveryPoints(pre, post, number)
		return pts(pre, { radius = 250 }, "escortNumber"), pts(post, { radius = 250 }, "escortNumber")
	end

	-- Mission 1: patrol (PATROL_POINT at 3, 20 s), surprise attack, space battle, inspect, delivery (no pickup)
	out[D.M1[1]] = base(D.M1[1], merge({ creditReward = D.CREDITS, itemReward = item(1) }, split(D.M1[2], 20, ST.PATROL_POINT, { sideQuestPatrolStart = 3 }), {
		patrolPoints = pts(numbered(P .. "patrol1_", 1, 4), { radius = 150 }, "patrolNumber"),
	}))
	out[D.M1[2]] = base(D.M1[2], merge(child(D.M1[1], {}), split(D.M1[3]), {
		surpriseAttackShips = { zone = E, spawns = { { count = 5, shipName = a } } },
	}))
	out[D.M1[3]] = base(D.M1[3], merge(child(D.M1[2], {}), split(D.M1[4]), {
		battlePoint = point(P .. "spacebattle1", { forward = D.FORWARD_1B }),
		damageMultiplier = 3, allyArrivalDelay = 15, enemyArrivalDelay = 45,
		allyOriginDist = 400, enemyOriginDist = -400, allyArrivalDist = 300, enemyArrivalDist = 300,
		allyForce = cat({ "imp_decimator_tier4" }, rep("imp_tie_interceptor_tier4", 5)),
		enemyForce = cat(rep(x, 4), rep("reb_ykl37r_tier4", 2), rep(y, 4)),
	}))
	out[D.M1[4]] = base(D.M1[4], merge(child(D.M1[3], {}), split(D.M1[5]), {
		shipList = { "rebel_endscout_tier4" },
		validSpawns = { spawnerEntry(P .. "endscout1") },
		giveSpawnWaypoint = 1, cargo = "rebel_battle_plans",
	}))
	out[D.M1[5]] = base(D.M1[5], merge(child(D.M1[4], {}), END, {
		deliveryShip = "imp_lambda_shuttle_tier4",
		deliveryPoint = point(P .. "delivery1"),
		attackShipLists = { rep(x, 4), cat({ b }, rep(a, 3)) },
		attackPeriod = 90, attackListType = seqDelivery,
	}))

	-- Mission 2: recovery, recovery, delivery, delivery (no pickup)
	local pre1, post1 = recoveryPoints(numbered(P .. "recovery1_", 1, 4), numbered(P .. "recovery1_", 5, 7))
	local pre2, post2 = recoveryPoints(numbered(P .. "recovery2_", 1, 4), numbered(P .. "recovery2_", 5, 7))

	out[D.M2[1]] = base(D.M2[1], merge({ creditReward = D.CREDITS, itemReward = item(2) }, split(D.M2[2]), {
		arrivalDelay = 30, recoveryDelay = 30, recoverShip = shuttle,
		recoveryConversationMobile = D.OFFICER_MOBILE,
		escortShips = rep(fighter, 5),
		preRecoveryPoints = pre1, recoveryPoints = post1,
		attackDelay = 90,
		attackShips = { rep(x, 4), rep(a, 5), cat({ b }, rep(x, 3), { y }) },
		tauntData = { panicCount = 5, thanksCount = 5 },
	}))
	out[D.M2[2]] = base(D.M2[2], merge(child(D.M2[1], {}), split(D.M2[3]), {
		arrivalDelay = 30, recoveryDelay = 30, recoverShip = shuttle,
		recoveryConversationMobile = D.OFFICER_MOBILE,
		escortShips = rep(fighter, 6),
		preRecoveryPoints = pre2, recoveryPoints = post2,
		attackDelay = 90,
		attackShips = { cat(rep(a, 3), rep(b, 2), { a }), cat(rep(x, 3), rep(y, 2), { x }) },
		tauntData = { panicCount = 5, thanksCount = 5 },
	}))
	out[D.M2[3]] = base(D.M2[3], merge(child(D.M2[2], {}), split(D.M2[4]), {
		pickupPoint = point(P .. "pickup1"),
		deliveryPoint = point(P .. "deliver1"),
		pickupShip = "imp_freightermedium_tier4", deliveryShip = "imp_freighterlight_tier4",
		attackShipLists = { cat(rep(x, 3), rep(y, 2)), rep(x, 4), cat(rep(x, 3), rep(b, 2)) },
		attackPeriod = 90, attackListType = seqDelivery,
	}))
	out[D.M2[4]] = base(D.M2[4], merge(child(D.M2[3], {}), END, {
		deliveryShip = "imp_freighterlight_tier4",
		deliveryPoint = point(P .. "deliver2"),
		attackShipLists = { cat(rep(y, 2), rep(x, 3)), rep(a, 5), cat(rep(b, 2), rep(a, 3)) },
		attackPeriod = 90, attackListType = seqDelivery,
	}))

	-- Mission 3: escort, rescue, space battle
	out[D.M3[1]] = base(D.M3[1], merge({ creditReward = D.CREDITS, itemReward = item(3) }, split(D.M3[2]), {
		escortShips = { "imp_lambda_inquisitor_shuttle_tier4" },
		escortPoints = pts(numbered(P .. "escort1_", 1, 5), { zoneName = E, radius = 250 }, "escortNumber"),
		attackDelay = 90,
		attackShips = { rep(a, 5), cat(rep(x, 3), rep(y, 2)), cat(rep(a, 2), rep(x, 2), { y }), cat(rep(b, 2), rep(x, 3)) },
		tauntData = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 },
	}))
	out[D.M3[2]] = base(D.M3[2], merge(child(D.M3[1], {}), split(D.M3[3]), {
		recoveryPath = pts(numbered(P .. "rescue1_", 1, 3)),
		targetShipType = "imp_lambda_shuttle_tier4", targetArrivalDelay = 30,
		attackShipLists = { rep(x, 4), cat(rep(x, 3), { y }), rep(a, 4), cat(rep(a, 2), rep(b, 2)) },
		attackPeriod = 120, attackListType = seqRescue, numResponses = 5,
	}))
	out[D.M3[3]] = base(D.M3[3], merge(child(D.M3[2], {}), END, {
		battlePoint = point(P .. "spacebattle2", { forward = D.FORWARD_3B }),
		damageMultiplier = 2, allyArrivalDelay = 30, enemyArrivalDelay = 60,
		allyOriginDist = 400, enemyOriginDist = -400, allyArrivalDist = 200, enemyArrivalDist = 200,
		allyForce = cat({ "imp_imperial_gunboat_tier4" }, rep("imp_tie_interceptor_tier4", 3), rep("imp_tie_bomber_tier4", 2)),
		enemyForce = cat(rep(a, 3), rep(b, 3), rep(x, 3), rep("reb_gunboat_tier4", 2)),
	}))

	-- Mission 4 (Dantooine): assassinate, assassinate, recovery, assassinate
	local pre3, post3 = recoveryPoints(numbered(P .. "recovery3_", 1, 5), numbered(P .. "recovery3_", 6, 8))

	out[D.M4[1]] = base(D.M4[1], merge({ creditReward = D.CREDITS, itemReward = item(4) }, split(D.M4[2]), {
		arrivalDelay = 30, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = shuttle, escorts = rep(fighter, 6) },
		targetPatrols = pts(numbered(P .. "assassinate1_", 1, 4)),
	}))
	out[D.M4[2]] = base(D.M4[2], merge(child(D.M4[1], {}), split(D.M4[3]), {
		arrivalDelay = 30, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = shuttle, escorts = rep(fighter, 6) },
		-- SWG's own list skips assassinate2_2
		targetPatrols = pts({ P .. "assassinate2_1", P .. "assassinate2_3", P .. "assassinate2_4" }),
	}))
	out[D.M4[3]] = base(D.M4[3], merge(child(D.M4[2], {}), split(D.M4[4]), {
		arrivalDelay = 30, recoveryDelay = 30, recoverShip = shuttle,
		escortShips = rep(fighter, 7),
		preRecoveryPoints = pre3, recoveryPoints = post3,
		attackDelay = 120,
		attackShips = { rep(x, 5), cat({ a }, rep(b, 2), rep(a, 2)) },
		tauntData = { panicCount = 5, thanksCount = 5 },
	}))
	out[D.M4[4]] = base(D.M4[4], merge(child(D.M4[3], {}), END, {
		arrivalDelay = 30, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = {
			target = "rebel_command_vessel_tier4",
			escorts = cat(rep(x, 3), rep("reb_bwing_tier3", 3), rep(y, 3), rep("rebel_command_vessel_weak_tier2", 2)),
		},
		targetPatrols = pts(numbered(P .. "assassinate3_", 1, 4)),
	}))

	-- Duties
	out[D.DUTIES[1]] = base(D.DUTIES[1], merge(END, {
		creditReward = 300, totalLevels = 5, totalRounds = 5, totalWaves = 3,
		bossShip = "red_skull_pirate_heavy_tier5",
		shipTypes = {
			rep(L, 3), cat(rep(L, 3), { M }), rep(M, 4), rep(M, 3), cat(rep(L, 3), rep(M, 2)), cat(rep(M, 3), rep(L, 2)), cat(rep(M, 3), rep(L, 3)), cat(rep(M, 4), rep(L, 2)),
		},
	}))
	out[D.DUTIES[2]] = base(D.DUTIES[2], merge(END, {
		creditReward = 5000, creditKillBonus = 300,
		escortShips = { "imp_lambda_shuttle_tier4", "imp_freightermedium_tier4", "imp_freighterlight_tier4", "imp_freighterheavy_tier4" },
		escortPoints = pts(numbered(P .. "escortduty_", 1, 9), { zoneName = E, radius = 250 }, "escortNumber"),
		attackDelay = 120,
		attackShips = { rep(L, 3), rep(M, 4), cat(rep(M, 2), rep(L, 2)) },
		tauntData = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 },
	}))

	local preD, postD = recoveryPoints(numbered(P .. "recoveryduty_", 1, 4), numbered(P .. "recoveryduty_", 5, 8))

	out[D.DUTIES[3]] = base(D.DUTIES[3], merge(END, {
		creditReward = 5000, creditKillBonus = 300, numResponses = 5,
		arrivalDelay = 30, recoveryDelay = 30,
		recoverShips = { "red_skull_freighter_tier4" },
		escortShips = cat(rep(M, 2), rep(L, 2)),
		preRecoveryPoints = preD, recoveryPoints = postD,
		attackDelay = 120,
		attackShips = { cat(rep(M, 3), rep(L, 2)), rep(H4, 5) },
		tauntData = { panicCount = 5, thanksCount = 5 },
	}))
	out[D.DUTIES[4]] = base(D.DUTIES[4], merge(END, {
		creditReward = 5000, creditKillBonus = 300,
		recoveryPath = pts(numbered(P .. "rescueduty_", 1, 3)),
		targetShipTypes = { "imp_freightermedium_tier4", "imp_freighterlight_tier4", "imp_freighterheavy_tier4", "imp_lambda_shuttle_tier4" },
		targetArrivalDelay = 30,
		attackShipLists = { cat(rep(M, 2), rep(L, 3)), cat(rep(L, 3), rep(H4, 2)) },
		attackPeriod = 120, attackListType = 0, numResponses = 5,
	}))

	return out
end

---------------------------------------------------------------------------------------------
-- Loading and state
---------------------------------------------------------------------------------------------

-- The server's load: every squadron file (storm_tier2_alozen_data.lua loads Oberhaur's and Alozen's pieces too)
function D.load() D3.load() end

function D.problems() return D3.problems() end

function D.quest(global)
	D3.load()

	return H.expectGlobal(global, "Storm tier 4 quest table (storm-tier4-kilnstrider-missions). Load problems: " .. D3.problems())
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

-- A Storm graduate of tier 3 (all four tier 3 skills, Denner's four missions paid, pilot tier 4, Oberhaur's, Alozen's and Colzet's state) with optional tier 4
-- state. Options:
--   missions   k: Kilnstrider's missions 1..k won (every chain member complete), :attempted and :reward set (default 0)
--   attempted  n: just the :attempted key of mission n
--   met        true: the met key is set
--   active     global of a tier 4 member or duty left active in the journal
--   every other option is storm_tier3_data.lua's D.pilot (Denner's missions are always the four, the tier 3 skills always the four)
function D.pilot(o)
	o = o or {}

	local base = {}

	for k, v in pairs(o) do
		base[k] = v
	end

	base.missions, base.attempted, base.met, base.active = 4, nil, nil, nil
	base.t3 = o.t3 or { 1, 2, 3, 4 }

	local player = D3.pilot(base)

	for n = 1, o.missions or 0 do
		for _, global in ipairs(D.CHAINS[n]) do
			D.setState(player, global, "complete")
		end

		H.setQuestStatus(player, D.STATUS[n] .. ":attempted", 1)
		H.setQuestStatus(player, D.STATUS[n] .. ":reward", 1)
	end

	if o.attempted then
		H.setQuestStatus(player, D.STATUS[o.attempted] .. ":attempted", 1)
	end

	if o.met then
		H.setQuestStatus(player, D.MET_KEY, 1)
	end

	if o.active then
		D.setState(player, o.active, "active")
	end

	return player
end

-- An Imperial pilot at pilot tier 4 in an Imperial-faction ship in `zone` (default space_endor), the way the runtime tests start a quest
function D.flyer(zone)
	D3.load()

	return H.newPlayer({
		zone = zone or D.ZONE,
		pilot = "imperial",
		pilotTier = 4,
		ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("imperial") },
	})
end

return D
