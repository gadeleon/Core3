-- Shared test data and builders for Storm Squadron tier 4, Part A (Admiral Kilnstrider's missions), not a test file.
-- Spec: .claude/work/storm-tier4-kilnstrider-missions/01-spec.md (Content contract 1 and 2, Data mapping 1 and 2, Appendix B).
-- Part B (storm-tier4-kilnstrider: the conversation) extends this file (the section at the end) and keeps every export below; D.pilot is wrapped there.
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

---------------------------------------------------------------------------------------------
-- Part B: Admiral Kilnstrider's conversation (storm-tier4-kilnstrider)
-- Spec: .claude/work/storm-tier4-kilnstrider/01-spec.md (Content contract 2 to 4, Conversation flow, Appendix A and D).
--   D.TEMPLATE / D.HANDLER / D.PREFIX / D.STF and the file and include constants
--   D.MISSIONS / D.TRAIN / D.TRAINED_BRIEFS / D.DUTY_MENU / D.MENUS   the handler tables of Content contract 2
--   D.SCREENS (storm_tier4_screens_data.lua: Appendix A, generated from the spec table), D.STARTS / D.PAYS, D.PATHS (Appendix D)
--   D.javaRewards()                    the four rewardForMissionN bodies of the J fixture (credits, item, standing, guard, head)
--   D.loadConversation() / D.requireConversation(lu)   the server's load of Kilnstrider's template and handler
--   D.pilot{...}                       wraps Part A's builder with the Part B options (see the list at D.pilot)
--   D.talk / D.firstScreen / D.drive   H.converse from the first screen / from a given screen
--   D.spyStarts / D.recordGrants / D.recordChainStarts ...   observers for the table-H actions
---------------------------------------------------------------------------------------------

D.TEMPLATE = "kilnstrider_convo_template"
D.HANDLER = "kilnstriderConvoHandler"
D.PREFIX = "@conversation/tatooine_imperial_tier4:"
D.STF = "conversation/tatooine_imperial_tier4"

D.TEMPLATE_FILE = "mobile/conversations/space/imperial/storm_squadron/kilnstrider_convo.lua"
D.HANDLER_FILE = "screenplays/space/conversations/imperial/storm_squadron/kilnstriderConvoHandler.lua"
D.NPC_FILE = "mobile/space/kilnstrider.lua"
D.SPAWN_FILE = "screenplays/cities/endor_research_outpost.lua"
D.CONVOS_FILE = "mobile/conversations/space/space_conversations.lua"
D.SCREENPLAYS_FILE = "screenplays/space/screenplays.lua"
D.JAVA = "script/conversation/tatooine_imperial_tier4.java"

D.TEMPLATE_INCLUDE = 'includeFile("conversations/space/imperial/storm_squadron/kilnstrider_convo.lua")'
D.HANDLER_INCLUDE = 'includeFile("space/conversations/imperial/storm_squadron/kilnstriderConvoHandler.lua")'
D.SPAWN_LINE = 'pNpc = spawnMobile("endor", "kilnstrider",60,-3.44448,0.624999,-6.82681,331.362,9925367)'

D.STANDING = 150
D.TRAIN_COST = 1000000
D.NOVICE = "pilot_imperial_navy_novice"
D.MASTER = "pilot_imperial_navy_master"

-- Content contract 2: MISSIONS (head, constants of the head and the chain end); brief = the head screen reached from `ready`, trained = the screen after the purchase
D.MISSIONS = {
	{ n = 1, head = D.M1[1], questString = "TIER4_QUEST_STRING_1", endString = "TIER4_QUEST_STRING_1_SIDE4", chain = D.M1, status = D.STATUS[1],
	  failed = "m1_failed", reward = "m1_reward", brief = "m1_brief", trained = "m1_brief" },
	{ n = 2, head = D.M2[1], questString = "TIER4_QUEST_STRING_2", endString = "TIER4_QUEST_STRING_2_SIDE3", chain = D.M2, status = D.STATUS[2],
	  failed = "m2_failed", reward = "m2_reward", brief = "m2_brief", trained = "m2_brief_trained" },
	{ n = 3, head = D.M3[1], questString = "TIER4_QUEST_STRING_3", endString = "TIER4_QUEST_STRING_3_SIDE2", chain = D.M3, status = D.STATUS[3],
	  failed = "m3_failed", reward = "m3_reward", brief = "m3_brief", trained = "m3_brief" },
	{ n = 4, head = D.M4[1], questString = "TIER4_QUEST_STRING_4", endString = "TIER4_QUEST_STRING_4_SIDE3", chain = D.M4, status = D.STATUS[4],
	  failed = "m4_failed", reward = "m4_reward", brief = "m4_brief", trained = "m4_brief" },
}

D.TRAINED_BRIEFS = { "m1_brief", "m2_brief_trained", "m3_brief", "m4_brief" }

-- Content contract 2: TRAIN_CHOICES in menu order (topic = the reply sid on ready_train)
D.TRAIN = {
	{ x = "starships", skill = "pilot_imperial_navy_starships_04", reply = "s_a50d5eb4" },
	{ x = "weapons", skill = "pilot_imperial_navy_weapons_04", reply = "s_2c2ce09e" },
	{ x = "procedures", skill = "pilot_imperial_navy_procedures_04", reply = "s_a5d7d28d" },
	{ x = "droid", skill = "pilot_imperial_navy_droid_04", reply = "s_97682588" },
}

D.TIER3_SKILLS = {
	"pilot_imperial_navy_starships_03", "pilot_imperial_navy_weapons_03", "pilot_imperial_navy_procedures_03", "pilot_imperial_navy_droid_03",
}

-- Content contract 2: DUTY_SCREENS in menu order with the menu reply of Appendix A
D.DUTY_MENU = {
	{ screen = "duty_destroy", global = D.DUTIES[1], reply = "s_cec1f447" },
	{ screen = "duty_escort", global = D.DUTIES[2], reply = "s_7b2d0234" },
	{ screen = "duty_recovery", global = D.DUTIES[3], reply = "s_d115dd42" },
	{ screen = "duty_rescue", global = D.DUTIES[4], reply = "s_5208f382" },
}

D.BRIEFING_AGAIN_REPLY = "s_49805f81"
D.READY_REPLY = "s_52917b0d"
D.OFF_TRACK_REPLY = "s_4854758d"
D.MENUS = { "duty_menu", "tier4_incomplete", "here_for_work" }
D.MENU_REPLIES = { "s_cec1f447", "s_7b2d0234", "s_d115dd42", "s_5208f382", "s_49805f81" }
D.MENU_LINKS = { "duty_destroy", "duty_escort", "duty_recovery", "duty_rescue", "duty_briefing" }
D.NAME_SCREENS = { "wanted", "wanted_c8003afd", "m2_failed", "m1_reward", "m2_reward", "m3_reward", "ready", "duty_recovery", "m2_brief", "m2_brief_trained" }

-- Appendix A
D.SCREENS = require("storm_tier4_screens_data")

-- Conversation flow 3, table H, derived from the Notes column of Appendix A: screen -> mission
D.STARTS, D.PAYS = {}, {}

for _, row in ipairs(D.SCREENS) do
	if row.start then
		D.STARTS[row.id] = row.start
	end

	if row.pay then
		D.PAYS[row.id] = row.pay
	end
end

function D.screenRow(id)
	for _, row in ipairs(D.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (98), sorted
function D.screenIds()
	local out = {}

	for i, row in ipairs(D.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- Appendix D: one reply path per grant screen { grant, kind, from, replies } (the replies after the `from` screen is shown)
D.PATHS = {
	{ grant = "m1_accept_busy", mission = 1, from = "ready", replies = { "s_52917b0d", "s_469b88eb", "s_555b7ab7", "s_951d1b06" } },
	{ grant = "m1_accept_hope", mission = 1, from = "m1_brief", replies = { "s_9cc5ad7c", "s_ebe5a831", "s_e604f53", "s_adfa15d1", "s_4621ec24" } },
	{ grant = "m2_accept_fire", mission = 2, from = "m2_brief", replies = { "s_c782ced7", "s_c28a04da", "s_52bae760" } },
	{ grant = "m2_accept_good", mission = 2, from = "m2_brief", replies = { "s_dd2ae025", "s_b7879974", "s_6a85372e", "s_5ec3bab9" } },
	{ grant = "m2_accept_dismissed", mission = 2, from = "m2_brief_trained", replies = { "s_dd2ae025", "s_b2da1ce2", "s_6a85372e", "s_2c4789b" } },
	{ grant = "m3_accept_escort", mission = 3, from = "m3_brief", replies = { "s_643d24c8", "s_21b67b7a", "s_ad56e0fd", "s_9b43a7ee" } },
	{ grant = "m3_accept_bottom", mission = 3, from = "m3_brief", replies = { "s_ad56e0fd", "s_d88c15de" } },
	{ grant = "m4_accept_prejudice", mission = 4, from = "m4_brief", replies = { "s_a1586753", "s_96443422", "s_b885dd25" } },
	{ grant = "m4_accept_search", mission = 4, from = "m4_brief", replies = { "s_2f748550", "s_9e02d014", "s_fcc7875e", "s_6a85372e", "s_8eb7d0ee", "s_2c4789b" } },
	{ grant = "m4_accept_expect", mission = 4, from = "m4_brief", replies = { "s_a1586753", "s_fcc7875e", "s_535d53b3", "s_5ec3bab9" } },
}

-- The failure walks of the retry screens: mN_failed starts the mission on display, the replies lead to closing lines that start nothing more
D.FAILED_WALKS = {
	{ mission = 1, replies = { "s_8f4d001d" }, ends = "m1_failed_898e32ed" },
	{ mission = 1, replies = { "s_abddb145" }, ends = "m1_failed_9da5d80d" },
	{ mission = 2, replies = { "s_77e48d5b", "s_49237f95", "s_87d4bfc2" }, ends = "m2_failed_a9fb7454" },
	{ mission = 2, replies = { "s_b3d150e3", "s_60db9426" }, ends = "m2_failed_661f1464" },
	{ mission = 3, replies = { "s_c1ce722e", "s_6ebb13d3" }, ends = "m3_failed_8bcb23a1" },
	{ mission = 3, replies = { "s_e26ff616" }, ends = "m3_failed_ee7cbdbe" },
	{ mission = 4, replies = { "s_ef420789" }, ends = "m4_failed_ee15b61" },
	{ mission = 4, replies = { "s_4c695dbd" }, ends = "m4_failed_175d585" },
}

-- The J fixture: rewardForMissionN bodies -> { type, name, credits, item, standing, guarded } by mission number (oracle for B-6, D-20)
local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

D.readFile = readFile

function D.javaRewards()
	local java = readFile(H.FIXTURES .. D.JAVA)
	local out = {}
	local words = { One = 1, Two = 2, Three = 3, Four = 4 }

	for word, body in java:gmatch("tatooine_imperial_tier4_action_rewardForMission(%a+)%(obj_id player, obj_id npc%) throws InterruptedException%s*(%b{})") do
		local questType, questName, credits, item = body:match('giveReward%(player, "([^"]+)", "([^"]+)", (%d+), "([^"]+)"%)')
		local standing = body:match("addFactionStanding%(player, factions%.FACTION_IMPERIAL, ([%d%.]+)f%)")
		local guard = body:match('!space_quest%.hasReceivedReward%(player, "([^"]+)", "([^"]+)"%)')

		out[words[word]] = { type = questType, name = questName, credits = tonumber(credits), item = item, standing = tonumber(standing), guarded = guard ~= nil }
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

D.loadErrors = {}

local convoLoaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		D.loadErrors[#D.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load of Kilnstrider's template and handler (after the squadron files). A missing production file is recorded in D.loadErrors, not raised,
-- so the tests of a red run fail on an assertion with the reason.
function D.loadConversation()
	if convoLoaded then
		return
	end

	convoLoaded = true
	D.load()
	try("kilnstrider_convo.lua", function() H.loadMobile("conversations/space/imperial/storm_squadron/kilnstrider_convo.lua") end)
	try("kilnstriderConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/storm_squadron/kilnstriderConvoHandler.lua") end)
end

function D.conversationProblems()
	return D.problems() .. " | " .. table.concat(D.loadErrors, " | ")
end

-- Fails with the load problems when the template or handler could not be loaded
function D.requireConversation(lu)
	D.loadConversation()
	lu.assertNotNil(H.conversationTemplateTable(D.TEMPLATE), D.TEMPLATE .. " is not registered by addConversationTemplate (expected " .. D.TEMPLATE_FILE .. "). Load problems: " .. D.conversationProblems())
	lu.assertNotNil(rawget(_G, D.HANDLER), D.HANDLER .. " is not defined (expected " .. D.HANDLER_FILE .. "). Load problems: " .. D.conversationProblems())
end

function D.handler()
	D.loadConversation()

	return H.expectGlobal(D.HANDLER, "Kilnstrider's conversation handler (storm-tier4-kilnstrider). Load problems: " .. D.conversationProblems())
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local pilotPartA = D.pilot

-- Options on top of Part A's (missions, attempted, met, active) and storm_tier3_data.lua's (every other option reaches storm_tier2_data.lua's T.pilot):
--   pilot      "imperial" (default) | "neutral" | "rebel" | false (not a pilot: no skills at all)
--   squadron   true (default: STORM_SQUADRON) | false (none) | "black_epsilon" | "inquisition" | a squadron constant
--   t3         list of indexes (D.TRAIN order) of the _03 skills held (default all four)
--   t4         list of D.TRAIN indexes of the _04 skills held
--   master     the master skill is held
--   mission    { [n] = state } for n = 1..4. "won": the whole chain is complete and :attempted is set; "failed" / "attempted": :attempted only;
--              "active": :attempted and the head active; "endonly": only the chain end complete (no :attempted); "partial": the head complete,
--              the end not (:attempted set)
--   paid       list of n (1..4) whose reward is paid: the chain is complete, :attempted and :reward are set
--   duty       global of a quest held active in the journal (alias of Part A's `active`)
--   pilotTier  ghost pilot tier (default 4 with the four _03 skills and 3 without; 5 when the four _04 skills are held)
--   xp, standing, faction, datapad, species, inventory, inventoryFull, inShip, zone: as in T.pilot
function D.pilot(o)
	o = o or {}

	local base = {}

	for k, v in pairs(o) do
		base[k] = v
	end

	base.t4, base.mission, base.paid, base.master, base.duty = nil, nil, nil, nil, nil

	if o.pilot == false then
		base.t1, base.t2, base.t3 = false, {}, {}
	end

	if o.squadron == "black_epsilon" then
		base.squadron = rawget(_G, "BLACK_EPSILON_SQUADRON")
	elseif o.squadron == "inquisition" then
		base.squadron = rawget(_G, "INQUISITION_SQUADRON")
	end

	if o.duty then
		base.active = o.duty
	end

	base.skills = {}

	for _, skill in ipairs(o.skills or {}) do
		base.skills[#base.skills + 1] = skill
	end

	if o.pilot ~= false then
		for _, i in ipairs(o.t4 or {}) do
			base.skills[#base.skills + 1] = D.TRAIN[i].skill
		end

		if o.master then
			base.skills[#base.skills + 1] = D.MASTER
		end
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
		local chain = D.CHAINS[n]

		if state ~= "endonly" then
			H.setQuestStatus(player, D.STATUS[n] .. ":attempted", 1)
		end

		if state == "paid" then
			H.setQuestStatus(player, D.STATUS[n] .. ":reward", 1)
		end

		if state == "won" or state == "paid" then
			for _, g in ipairs(chain) do
				D.setState(player, g, "complete")
			end
		elseif state == "endonly" then
			D.setState(player, chain[#chain], "complete")
		elseif state == "partial" then
			D.setState(player, chain[1], "complete")
		elseif state == "active" then
			D.setState(player, chain[1], "active")
		end
	end

	return player
end

function D.npc() return H.newNpc({ name = "Admiral Kilnstrider" }) end

-- Charges the XP of the _04 skills from the fixture (1,000,000 each); without it the fake charges nothing
function D.useSkillCosts()
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

local function requireLoaded()
	D.loadConversation()

	if H.conversationTemplateTable(D.TEMPLATE) == nil or rawget(_G, D.HANDLER) == nil then
		error("Kilnstrider's conversation is not loaded. Load problems: " .. D.conversationProblems(), 3)
	end
end

-- Talks to Kilnstrider from the first screen. choices as for H.converse (0-based indexes, option sids, hooks).
function D.talk(player, choices)
	requireLoaded()

	return H.converse({ template = D.TEMPLATE, player = player, npc = D.npc(), choices = choices })
end

function D.firstScreen(player) return D.talk(player)[1].id end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or hooks).
-- Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session.
function D.drive(player, startId, choices)
	requireLoaded()

	local tmpl = H.conversationTemplate(D.TEMPLATE)
	local handler = rawget(_G, D.HANDLER)
	local npc = D.npc()
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
		error("screen '" .. startId .. "' is not in " .. D.TEMPLATE, 2)
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
function D.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- the option sids ("s_xxx") of a transcript step, in order
function D.optionSids(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = tostring(o.text):match(":(s_[%w_]+)$") or tostring(o.text)
	end

	return out
end

function D.linksOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = o.link
	end

	return out
end

-- _04 skills (of the four) the player holds, in D.TRAIN order
function D.held4(player)
	local out = {}

	for _, t in ipairs(D.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

-- Spies on the startQuest of the listed globals (default: the 20 Kilnstrider quests); H.spyOn does not call the original
function D.spyStarts(globals)
	local spies = {}

	for _, g in ipairs(globals or D.GLOBALS) do
		spies[g] = H.spyOn(D.quest(g), "startQuest")
	end

	return spies
end

-- the sorted list of globals whose startQuest was called, one entry per call
function D.started(spies)
	local out = {}

	for g, calls in pairs(spies) do
		for _ = 1, #calls do
			out[#out + 1] = g
		end
	end

	table.sort(out)
	return out
end

local restoreFns = {}

-- Records the calls of SpaceHelpers:grantSpaceSkill and runs the original. Call D.restore() in tearDown.
function D.recordGrants()
	local calls = {}
	local orig = SpaceHelpers.grantSpaceSkill

	SpaceHelpers.grantSpaceSkill = function(self, pPlayer, skill, deduct)
		calls[#calls + 1] = { skill = skill, deduct = deduct }

		return orig(self, pPlayer, skill, deduct)
	end

	restoreFns[#restoreFns + 1] = function() SpaceHelpers.grantSpaceSkill = orig end

	return calls
end

-- Records the calls of SpaceHelpers:startSpaceQuestChain (head global names) and runs the original. Call D.restore() in tearDown.
function D.recordChainStarts()
	local calls = {}
	local orig = SpaceHelpers.startSpaceQuestChain

	SpaceHelpers.startSpaceQuestChain = function(self, pPlayer, pNpc, headGlobal)
		calls[#calls + 1] = headGlobal

		return orig(self, pPlayer, pNpc, headGlobal)
	end

	restoreFns[#restoreFns + 1] = function() SpaceHelpers.startSpaceQuestChain = orig end

	return calls
end

function D.restore()
	for _, fn in ipairs(restoreFns) do
		fn()
	end

	restoreFns = {}
end

-- The item giveItem calls on the pilot's inventory received
function D.items(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory then
			out[#out + 1] = call[2]
		end
	end

	return out
end

function D.hasKey(player, suffix) return H.getQuestStatus(player, suffix) == "1" end

function D.standingOf(player) return player.ghost.factionStanding.imperial end

-- The shape of a pilot's state a gate must not change (I-9)
function D.snapshot(player)
	return {
		credits = player.bankCredits, standing = player.ghost and player.ghost.factionStanding.imperial, pilotTier = player.ghost and player.ghost.pilotTier,
		xp = player.ghost and player.ghost.experience.space_combat_general, skills = D.held4(player), inventory = #(player.inventory and player.inventory.items or {}),
		keys = H.Engine.sharedMemoryKeys(), met = D.hasKey(player, D.MET_KEY), engineCalls = #H.Engine.calls,
	}
end


return D
