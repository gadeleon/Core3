-- Shared test data and builders for Black Epsilon tier 2 (Prisk Kith'Vys), not a test file.
-- Spec: .claude/work/black-epsilon-tier2-prisk/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself:
--   P.GLOBALS / P.IDENTITY     the 12 quest globals and their class, type and name (Content contract 1)
--   P.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   P.POINTS / P.SPAWNERS      Data mapping 2: the 37 points and the 1 spawner, Core3 x, z, y
--   P.SCREENS                  Appendix A (black_epsilon_tier2_screens_data.lua, generated from the spec table)
--   P.MISSIONS / P.TRAIN       MISSIONS and TRAIN_CHOICES of the handler (Content contract 3)
--   P.load()                   the server's load of the squadron, the template and the handler, collecting load errors
--   P.pilot{...}               a pilot standing in front of Prisk (see the option list at P.pilot)
--   P.talk / P.drive           H.converse from the first screen / from a given screen
--
-- Prisk's conversation lives in the template "prisk_convo_template", its handler is the global "priskConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")

local P = {}

P.TEMPLATE = "prisk_convo_template"
P.HANDLER = "priskConvoHandler"
P.PREFIX = "@conversation/corellia_imperial_trainer_2:"
P.STF = "conversation/corellia_imperial_trainer_2"

P.TEMPLATE_FILE = "mobile/conversations/space/imperial/black_epsilon_squadron/prisk_convo.lua"
P.HANDLER_FILE = "screenplays/space/conversations/imperial/black_epsilon_squadron/priskConvoHandler.lua"
P.SQUADRON_FILE = "screenplays/space/squadrons/BlackEpsilonSquadronScreenplay.lua"
P.NPC_FILE = "mobile/space/prisk_kith_vys.lua"

P.OPENING = "recovery_corellia_imperial_16"
P.A12 = "assassinate_corellia_imperial_12"
P.I13 = "inspect_corellia_imperial_13"
P.A14 = "assassinate_corellia_imperial_14"
P.P15 = "patrol_corellia_imperial_15"
P.S15 = "destroy_surpriseattack_corellia_imperial_15_split"
P.A17 = "assassinate_corellia_imperial_17"
P.FINAL = "survival_corellia_tier2_final"
P.DUTY8 = "destroy_duty_corellia_imperial_8"
P.DUTY9 = "escort_duty_corellia_imperial_9"
P.DUTY10 = "destroy_duty_corellia_imperial_10"
P.DUTY11 = "escort_duty_corellia_imperial_11"

P.GLOBALS = { P.OPENING, P.A12, P.I13, P.A14, P.P15, P.S15, P.A17, P.FINAL, P.DUTY8, P.DUTY9, P.DUTY10, P.DUTY11 }

-- The tier 1 globals (kept by the squadron file)
P.TIER1_GLOBALS = {
	"patrol_corellia_imperial_1", "destroy_surpriseattack_corellia_imperial_1", "destroy_corellia_imperial_2", "escort_corellia_imperial_3",
	"assassinate_corellia_imperial_4", "destroy_duty_corellia_imperial_6", "escort_duty_corellia_imperial_7",
}

-- global -> { class, type, name }
P.IDENTITY = {
	[P.OPENING] = { class = "SpaceRecoveryScreenplay", type = "recovery", name = "corellia_imperial_16" },
	[P.A12] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "corellia_imperial_12" },
	[P.I13] = { class = "SpaceInspectScreenplay", type = "inspect", name = "corellia_imperial_13" },
	[P.A14] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "corellia_imperial_14" },
	[P.P15] = { class = "SpacePatrolScreenplay", type = "patrol", name = "corellia_imperial_15" },
	[P.S15] = { class = "SpaceSurpriseAttackScreenplay", type = "destroy_surpriseattack", name = "corellia_imperial_15_split" },
	[P.A17] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "corellia_imperial_17" },
	[P.FINAL] = { class = "SpaceSurvivalScreenplay", type = "survival", name = "corellia_tier2_final" },
	[P.DUTY8] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "corellia_imperial_8" },
	[P.DUTY9] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "corellia_imperial_9" },
	[P.DUTY10] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "corellia_imperial_10" },
	[P.DUTY11] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "corellia_imperial_11" },
}

-- The quest chains of the story (head first), by key: "opening", 1 .. 4, "final"
P.CHAINS = {
	opening = { P.OPENING },
	[1] = { P.A12 },
	[2] = { P.I13 },
	[3] = { P.A14 },
	[4] = { P.P15, P.S15 },
	final = { P.A17, P.FINAL },
}

P.DUTIES = { P.DUTY8, P.DUTY9, P.DUTY10, P.DUTY11 }

-- The 8 story tables that resetPriskQuests resets (all except the duties)
P.STORY = { P.OPENING, P.A12, P.I13, P.A14, P.P15, P.S15, P.A17, P.FINAL }

-- Content contract 2: the squadron object's constants
P.QUEST_STRINGS = {
	TIER2_QUEST_STRING_OPENING = { type = "recovery", name = "corellia_imperial_16" },
	TIER2_QUEST_STRING_1 = { type = "assassinate", name = "corellia_imperial_12" },
	TIER2_QUEST_STRING_2 = { type = "inspect", name = "corellia_imperial_13" },
	TIER2_QUEST_STRING_3 = { type = "assassinate", name = "corellia_imperial_14" },
	TIER2_QUEST_STRING_4 = { type = "patrol", name = "corellia_imperial_15" },
	TIER2_QUEST_STRING_4_SIDE = { type = "destroy_surpriseattack", name = "corellia_imperial_15_split" },
	TIER2_QUEST_STRING_FINAL = { type = "assassinate", name = "corellia_imperial_17" },
	TIER2_QUEST_STRING_FINAL_SIDE = { type = "survival", name = "corellia_tier2_final" },
	TIER2_QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "corellia_imperial_8" },
	TIER2_QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "corellia_imperial_9" },
	TIER2_QUEST_STRING_DUTY_3 = { type = "destroy_duty", name = "corellia_imperial_10" },
	TIER2_QUEST_STRING_DUTY_4 = { type = "escort_duty", name = "corellia_imperial_11" },
}

P.SERIES_SUFFIX = "BlackEpsilonSquadronScreenplay:imperial_corellia_1"
P.PRISK_SUFFIX = "BlackEpsilonSquadronScreenplay:workingForPrisk"

-- The 10 status keys resetPriskQuests removes (without the player id)
P.KEYS = {
	"corellia_imperial_16:attempted",
	"corellia_imperial_12:attempted", "corellia_imperial_12:reward",
	"corellia_imperial_13:attempted", "corellia_imperial_13:reward",
	"corellia_imperial_14:attempted", "corellia_imperial_14:reward",
	"corellia_imperial_15:attempted", "corellia_imperial_15:reward",
	"corellia_imperial_17:attempted",
}

-- Data mapping 2: name -> { x, z, y }
P.POINTS = {
	corellia_imperial_patrol_1 = { -2137, -2099, -3565 },
	corellia_imperial_patrol_2 = { -6321, -1417, -3345 },
	corellia_imperial_patrol_3 = { -6662, -2384, -2625 },
	corellia_imperial_patrol_4 = { -7252, -3694, -574 },
	corellia_imperial_patrol_5 = { -4770, -5632, 148 },
	corellia_imperial_recovery_1 = { -6589, -1759, 116 },
	corellia_imperial_recovery_2 = { -2975, -3650, -2734 },
	corellia_imperial_recovery_3 = { 1359, -5188, -4383 },
	corellia_imperial_recovery_4 = { 5853, -6408, -4885 },
	rebel_ambush_point = { -3830, 3601, 3458 },
	corellia_imperial_tier2_assassinate_1 = { -6932, -1364, -644 },
	corellia_imperial_tier2_assassinate_2 = { -5275, -1116, -6269 },
	corellia_imperial_tier2_assassinate_3 = { -2854, -236, -6778 },
	corellia_imperial_tier2_assassinate_4 = { 15, 877, -7202 },
	corellia_imperial_tier2_assassinate_5 = { 3102, 2928, -6841 },
	imperial_nebula_patrol_1 = { -5200, 4000, 2112 },
	imperial_nebula_patrol_2 = { -3533, 2525, 3951 },
	imperial_nebula_patrol_3 = { -33, 3789, 2144 },
	imperial_nebula_patrol_4 = { 1324, 3496, 1564 },
	imperial_nebula_patrol_5 = { 2739, 3730, 705 },
	corellia_imperial_tier3_leg_1_recovery_recover_2 = { -410, -3742, -2454 },
	corellia_imperial_tier3_leg_1_recovery_recover_3 = { -1184, -2297, -4821 },
	corellia_imperial_tier3_leg_1_recovery_recover_4 = { -5768, -2993, -6612 },
	trade_escort_1 = { -5777, 5956, -5286 },
	trade_escort_2 = { -3830, 4317, -2982 },
	trade_escort_3 = { -1924, 2666, -1102 },
	trade_escort_4 = { 895, 210, 695 },
	trade_escort_5 = { 3065, -1029, 2144 },
	trade_escort_6 = { 4333, -2700, 3283 },
	trade_escort_7 = { 5229, -3991, 4253 },
	trade_escort_8 = { 5705, -5049, 5164 },
	trade_escort_9 = { 6053, -5934, 5872 },
	military_escort_5 = { -3887, -27, 6573 },
	military_escort_6 = { -5250, -819, 2910 },
	military_escort_7 = { -4275, -1067, -1961 },
	military_escort_8 = { -3822, -1188, -4321 },
	military_escort_9 = { -485, -1212, -5825 },
}

P.SPAWNERS = {
	corellia_imperial_tier2_inspect_freighter = { -2466, 1971, 6320 },
}

P.ITEMS = {
	[1] = "object/tangible/ship/components/weapon/wpn_mission_reward_imperial_cygnus_starblaster.iff",
	[2] = "object/tangible/ship/components/armor/arm_mission_reward_imperial_sfs_light_military.iff",
	[3] = "object/tangible/ship/components/booster/bst_mission_reward_imperial_rss_ion_booster.iff",
	[4] = "object/tangible/ship/components/shield_generator/shd_mission_reward_imperial_rendili_dual_projector.iff",
}

local function point(name, extra)
	local p = P.POINTS[name]
	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra or {}) do
		t[k] = v
	end

	return t
end

local function patrolPoints(names) -- patrolNumber, radius 150
	local out = {}

	for i, n in ipairs(names) do
		out[i] = point(n, { patrolNumber = i, radius = 150 })
	end

	return out
end

local function recoveryPoints(names) -- escortNumber, radius 250, no zoneName
	local out = {}

	for i, n in ipairs(names) do
		out[i] = point(n, { escortNumber = i, radius = 250 })
	end

	return out
end

local function escortPoints(names) -- zoneName, escortNumber, radius 250
	local out = {}

	for i, n in ipairs(names) do
		out[i] = point(n, { zoneName = "space_corellia", escortNumber = i, radius = 250 })
	end

	return out
end

local function plainPoints(names)
	local out = {}

	for i, n in ipairs(names) do
		out[i] = point(n)
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

local function item(n) return { { species = { -1 }, item = P.ITEMS[n] } } end

local function rep(value, count)
	local out = {}

	for i = 1, count do
		out[i] = value
	end

	return out
end

local function spawner(name)
	local s = P.SPAWNERS[name]

	return { spawnName = name, x = s[1], z = s[2], y = s[3] }
end

-- global -> the whole table (Appendix B keys, Data mapping 1 values). sideQuestSplitType is SpaceQuestLogic's constant.
function P.expected()
	local PATROL_POINT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT
	local COMPLETION = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION
	local taunts5 = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }
	local common = function(global) -- className, questType, questName, questZone
		local id = P.IDENTITY[global]

		return { className = global, questType = id.type, questName = id.name, questZone = "space_corellia" }
	end

	local function with(global, more)
		local t = common(global)

		for k, v in pairs(more) do
			t[k] = v
		end

		return t
	end

	return {
		[P.OPENING] = with(P.OPENING, {
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 20, recoveryDelay = 30, recoverShip = "freighterheavy_black_epsilon_tier2",
			escortShips = { "hidden_daggers_enforcer_tier2", "hidden_daggers_enforcer_tier2" },
			preRecoveryPoints = recoveryPoints(numbered("corellia_imperial_patrol_", 1, 5)),
			recoveryPoints = recoveryPoints(numbered("corellia_imperial_recovery_", 1, 4)),
			attackDelay = 120,
			attackShips = { rep("hidden_daggers_enforcer_tier2", 2), rep("hidden_daggers_nebula_stalker_tier2", 2) },
			tauntData = { panicCount = 5, thanksCount = 5 },
		}),
		[P.A12] = with(P.A12, {
			creditReward = 5000, itemReward = item(1),
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 30, failTimer = 20, mustDestroyEscort = true,
			assassinateSpawns = { target = "rebel_diplomat_tier2", escorts = rep("reb_xwing_tier2", 4) },
			targetPatrols = plainPoints(numbered("corellia_imperial_tier2_assassinate_", 1, 5)),
		}),
		[P.I13] = with(P.I13, {
			creditReward = 5000, itemReward = item(2),
			sideQuest = false, sideQuestType = "",
			shipList = { "rebel_spysmuggler_tier2" },
			validSpawns = { spawner("corellia_imperial_tier2_inspect_freighter") },
			giveSpawnWaypoint = 1, cargo = "personnel_dossier",
		}),
		[P.A14] = with(P.A14, {
			creditReward = 5000, itemReward = item(3),
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 15, failTimer = 20, mustDestroyEscort = true,
			assassinateSpawns = { target = "reb_bomber_leader_tier3", escorts = rep("reb_ywing_tier2", 5) },
			targetPatrols = plainPoints({ "trade_escort_4", "trade_escort_5", "trade_escort_6", "trade_escort_7" }),
		}),
		[P.P15] = with(P.P15, {
			creditReward = 5000, itemReward = item(4),
			sideQuest = true, sideQuestType = "destroy_surpriseattack", sideQuestName = "corellia_imperial_15_split",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 4, sideQuestDelay = 20,
			patrolPoints = patrolPoints(numbered("imperial_nebula_patrol_", 1, 5)),
		}),
		[P.S15] = with(P.S15, {
			sideQuest = false, sideQuestType = "",
			parentQuest = P.P15, parentQuestType = "patrol", parentQuestName = "corellia_imperial_15",
			surpriseAttackShips = { zone = "space_corellia", spawns = { { count = 2, shipName = "reb_xwing_tier2" } } },
		}),
		[P.A17] = with(P.A17, {
			sideQuest = true, sideQuestType = "survival", sideQuestName = "corellia_tier2_final",
			sideQuestSplitType = COMPLETION, sideQuestDelay = 5,
			arrivalDelay = 20, failTimer = 20, mustDestroyEscort = false,
			assassinateSpawns = { target = "reb_unmaned_xwing_tier2", escorts = {} },
			targetPatrols = plainPoints(numbered("corellia_imperial_tier3_leg_1_recovery_recover_", 2, 4)),
		}),
		[P.FINAL] = with(P.FINAL, {
			sideQuest = false, sideQuestType = "",
			parentQuest = P.A17, parentQuestType = "assassinate", parentQuestName = "corellia_imperial_17",
			transmissionPoint = point("rebel_ambush_point"),
			totalTransmissionTime = 350, timesToUpdateProgress = 6, transmissionStartDelay = 10, delayToFirstAttack = 20,
			attackShipLists = {
				{ "xwing_rookie", "xwing_rookie", "bwing", "awing" },
				{ "ywing_rookie", "ywing_ace", "xwing_average", "awing" },
				{ "xwing_average", "ywing_rookie", "xwing_average", "bwing" },
			},
			attackPeriod = 90, attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
		}),
		[P.DUTY8] = with(P.DUTY8, {
			creditReward = 200, sideQuest = false, sideQuestType = "",
			totalLevels = 3, totalRounds = 2, totalWaves = 3,
			bossShip = "hidden_daggers_executioner_tier3",
			shipTypes = { rep("hidden_daggers_eliminator_tier2", 2), rep("hidden_daggers_killer_tier2", 2) },
		}),
		[P.DUTY9] = with(P.DUTY9, {
			creditReward = 2500, creditKillBonus = 200, sideQuest = false, sideQuestType = "",
			escortShips = { "freighterheavy_tier2", "freighterlight_tier2", "freightermedium_tier2" },
			escortPoints = escortPoints(numbered("trade_escort_", 1, 9)),
			attackDelay = 120,
			attackShips = { rep("hutt_pirate_s01_tier2", 2), { "hutt_fighter_s02_tier2", "hutt_pirate_s02_tier2" } },
			tauntData = taunts5,
		}),
		[P.DUTY10] = with(P.DUTY10, {
			creditReward = 200, sideQuest = false, sideQuestType = "",
			totalLevels = 4, totalRounds = 3, totalWaves = 4,
			bossShip = "reb_xwing_tier3",
			shipTypes = { rep("reb_xwing_tier2", 2), rep("reb_z95_tier2", 2) },
		}),
		[P.DUTY11] = with(P.DUTY11, {
			creditReward = 2500, creditKillBonus = 200, sideQuest = false, sideQuestType = "",
			escortShips = { "imp_freighterheavy_tier2", "imp_freightermedium_tier2", "imp_freighterlight_tier2" },
			escortPoints = escortPoints(numbered("military_escort_", 5, 9)),
			attackDelay = 120,
			attackShips = { { "reb_xwing_tier2", "reb_ywing_tier2" }, rep("reb_z95_tier2", 2), { "reb_xwing_tier2", "reb_z95_tier2" } },
			tauntData = taunts5,
		}),
	}
end

-- MISSIONS of the handler, n = 1..4 in the SWG flag order (Content contract 3). status = the :attempted / :reward key stem.
P.MISSIONS = {
	{ n = 1, x = "starships", skill = "pilot_imperial_navy_starships_02", head = P.A12, questString = "TIER2_QUEST_STRING_1", brief = "m12_brief",
		status = "corellia_imperial_12", won = "m12_won", reward = "m12_reward", retry = "m12_retry", accept = "m12_accept" },
	{ n = 2, x = "droid", skill = "pilot_imperial_navy_droid_02", head = P.I13, questString = "TIER2_QUEST_STRING_2", brief = "m13_brief",
		status = "corellia_imperial_13", won = "m13_won", reward = "m13_reward", retry = "m13_retry", accept = "m13_accept" },
	{ n = 3, x = "weapons", skill = "pilot_imperial_navy_weapons_02", head = P.A14, questString = "TIER2_QUEST_STRING_3", brief = "m14_brief",
		status = "corellia_imperial_14", won = "m14_won", reward = "m14_reward", retry = "m14_retry", accept = "m14_accept" },
	{ n = 4, x = "procedures", skill = "pilot_imperial_navy_procedures_02", head = P.P15, questString = "TIER2_QUEST_STRING_4", brief = "m15_brief",
		status = "corellia_imperial_15", won = "m15_won", reward = "m15_reward", retry = "m15_retry", accept = "m15_accept" },
}

P.CREDITS = 5000
P.STANDING = 75
P.OPENING_STATUS = "corellia_imperial_16"
P.FINAL_STATUS = "corellia_imperial_17"

-- TRAIN_CHOICES in menu order (Content contract 3, Conversation flow 3.3): the topic reply is the purchase
P.TRAIN = {
	{ x = "starships", skill = "pilot_imperial_navy_starships_02", reply = "s_be505897", trained = "trained_starships", trainedSid = "s_3f764ef1", afterReply = "s_116d8b3b", brief = "m12_brief_trained", mission = 1 },
	{ x = "weapons", skill = "pilot_imperial_navy_weapons_02", reply = "s_82fd8660", trained = "trained_weapons", trainedSid = "s_cc4d7ea", afterReply = "s_ceafaf0b", brief = "m14_brief_trained", mission = 3 },
	{ x = "procedures", skill = "pilot_imperial_navy_procedures_02", reply = "s_a872e9f9", trained = "trained_procedures", trainedSid = "s_f3d4db20", afterReply = "s_116d8b3b", brief = "m15_brief", mission = 4 },
	{ x = "droid", skill = "pilot_imperial_navy_droid_02", reply = "s_9b4e084a", trained = "trained_droid", trainedSid = "s_c914798f", afterReply = "s_b51a649", brief = "m13_brief", mission = 2 },
}

-- the tier 1 skills (the four _01), in the order of the tier 1 TRAIN
P.TIER1_SKILLS = {
	"pilot_imperial_navy_starships_01", "pilot_imperial_navy_weapons_01", "pilot_imperial_navy_procedures_01", "pilot_imperial_navy_droid_01",
}

P.NOVICE = "pilot_imperial_navy_novice"
P.TRAINING_COST = 60000

-- the skill name of a TRAIN index
function P.skill(i) return P.TRAIN[i].skill end

-- Appendix A
P.SCREENS = require("black_epsilon_tier2_screens_data")

function P.screenRow(id)
	for _, row in ipairs(P.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (85), sorted
function P.screenIds()
	local out = {}

	for i, row in ipairs(P.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

P.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		P.loadErrors[#P.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: the four squadron files, the Prisk template, the Prisk handler. A missing production file is recorded in
-- P.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function P.load()
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

	try("prisk_convo.lua", function() H.loadMobile("conversations/space/imperial/black_epsilon_squadron/prisk_convo.lua") end)
	try("priskConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/black_epsilon_squadron/priskConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function P.requireConversation(lu)
	P.load()
	lu.assertNotNil(H.conversationTemplateTable(P.TEMPLATE), P.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. table.concat(P.loadErrors, " | "))
	lu.assertNotNil(rawget(_G, P.HANDLER), P.HANDLER .. " is not defined. Load problems: " .. table.concat(P.loadErrors, " | "))
end

function P.quest(global)
	P.load()

	return H.expectGlobal(global, "Black Epsilon tier 2 quest table (black-epsilon-tier2-prisk). Load problems: " .. table.concat(P.loadErrors, " | "))
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = P.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

P.crc = crc

-- Quest state helpers on a built pilot. state: "complete" | "active" | "none"
function P.setState(player, global, state)
	local key = crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function P.state(player, global)
	local key = crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- the :attempted / :reward status key stems of the chain keys
local STATUS = { opening = "corellia_imperial_16", [1] = "corellia_imperial_12", [2] = "corellia_imperial_13", [3] = "corellia_imperial_14", [4] = "corellia_imperial_15", final = "corellia_imperial_17" }

P.STATUS = STATUS

-- Options (all optional; the default is a Black Epsilon pilot with a ship, standing 0, male, the four tier 1 skills, pilot tier 2, the tier 1
-- series flag set, nothing of tier 2 done):
--   pilot      "imperial" (default) | "neutral" | "rebel" | false (not a pilot)
--   faction    "imperial" (default) | "rebel" | "neutral" (no faction)
--   squadron   true (default: BLACK_EPSILON_SQUADRON) | false (none) | a squadron constant
--   standing   Imperial faction standing (default 0)
--   gender     0 = male (default), 1 = female
--   ship       certified ship (default true)
--   tier1      number of tier 1 skills held (default 4)
--   t2         list of TRAIN indexes (1 starships, 2 weapons, 3 procedures, 4 droid) of the tier 2 skills held
--   series     the tier 1 series-complete flag (default true); prisk the Prisk flag (default false)
--   opening    state of recovery 16: "won" | "failed" | "active" | "attempted"
--   mission    { [n] = state } for the missions n = 1..4, final = state for the final. "won": the chain is complete and :attempted is set;
--              "failed": :attempted only; "active": :attempted and the chain head active; "attempted": just the key. For n = 4 "won" completes
--              patrol and split; "won4patrol" completes the patrol only. For the final "won" completes assassinate 17 and the survival.
--   paid       list of n (1..4) whose reward is paid: the chain is complete, :attempted and :reward are set (unless `mission` overrides the state)
--   xp         space_combat_general experience (default 0)
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   duty       global of a duty held active in the journal
--   species    SPECIES_* (default SPECIES_HUMAN)
--   pilotTier  ghost pilot tier (default 2)
--   inventory  (default true)
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
function P.pilot(o)
	o = o or {}
	P.load()

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

	local skills = { P.NOVICE }

	if pilotKind == nil then
		skills = {}
	end

	if pilotKind ~= nil then
		for i = 1, (o.tier1 == nil and 4 or o.tier1) do
			skills[#skills + 1] = P.TIER1_SKILLS[i]
		end

		for _, i in ipairs(o.t2 or {}) do
			skills[#skills + 1] = P.TRAIN[i].skill
		end
	end

	local completed, active, status = {}, {}, {}
	local states = {}

	local function setChain(key, state)
		states[key] = state
	end

	if o.opening then
		setChain("opening", o.opening)
	end

	for _, n in ipairs(o.paid or {}) do
		setChain(n, "paid")
	end

	for key, state in pairs(o.mission or {}) do
		setChain(key, state)
	end

	for key, state in pairs(states) do
		local chain = P.CHAINS[key]
		local stem = STATUS[key]

		status[stem .. ":attempted"] = "1"

		if state == "paid" then
			status[stem .. ":reward"] = "1"
		end

		if state == "won" or state == "paid" then
			for _, g in ipairs(chain) do
				completed[#completed + 1] = crc(g)
			end
		elseif state == "won4patrol" then
			completed[#completed + 1] = crc(P.P15)
		elseif state == "active" then
			active[#active + 1] = crc(chain[1])
		end
	end

	if o.series ~= false then
		status[P.SERIES_SUFFIX] = "1"
	end

	if o.prisk then
		status[P.PRISK_SUFFIX] = "1"
	end

	if o.duty then
		active[#active + 1] = crc(o.duty)
	end

	local player = H.newPlayer({
		name = "Ace",
		pilot = pilotKind,
		faction = faction,
		squadronType = squadron,
		pilotTier = o.pilotTier or 2,
		certifiedShip = o.ship ~= false,
		skills = skills,
		experience = { space_combat_general = o.xp or 0 },
		factionStanding = { imperial = o.standing or 0, rebel = 0 },
		completedQuests = completed,
		activeQuests = active,
		questStatus = status,
		species = o.species or SPECIES_HUMAN,
		gender = o.gender or 0,
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

-- Engine XP prices of the four tier 2 skills, from the SWG skills.tab excerpt (fixtures/skill/skills.pilot_imperial_navy_02.tab)
function P.useSkillCosts()
	local costs = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_imperial_navy_02.tab").records) do
		local name = rec:get("NAME")

		if name ~= nil and name:match("^pilot_imperial_navy_%a+_02$") then
			costs[name] = rec:num("XP_COST")
		end
	end

	H.Engine.config.skillXpCosts = costs

	return costs
end

function P.npc() return H.newNpc({ name = "Prisk" }) end

function P.requireConversationLoaded()
	P.load()

	if H.conversationTemplateTable(P.TEMPLATE) == nil or rawget(_G, P.HANDLER) == nil then
		error("Prisk conversation is not loaded. Load problems: " .. table.concat(P.loadErrors, " | "), 3)
	end
end

-- Talks to Prisk from the first screen. choices as for H.converse.
function P.talk(player, choices)
	P.requireConversationLoaded()

	return H.converse({ template = P.TEMPLATE, player = player, npc = P.npc(), choices = choices })
end

-- The id of the first screen of a fresh talk
function P.firstScreen(player)
	return P.talk(player)[1].id
end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session.
function P.drive(player, startId, choices)
	P.requireConversationLoaded()

	local tmpl = H.conversationTemplate(P.TEMPLATE)
	local handler = rawget(_G, P.HANDLER)
	local npc = P.npc()
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
		error("screen '" .. startId .. "' is not in " .. P.TEMPLATE, 2)
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

-- ids of a transcript
function P.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- the option sids ("s_xxx") of a transcript step, in order
function P.optionSids(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = tostring(o.text):match(":(s_[%w_]+)$") or tostring(o.text)
	end

	return out
end

function P.linksOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = o.link
	end

	return out
end

function P.free() return H.Engine.callsTo("awardSkill") end
function P.bought() return H.Engine.callsTo("skillManagerAwardSkill") end

-- Tier 2 skills (of the four) the player holds, in P.TRAIN order
function P.held(player)
	local out = {}

	for _, t in ipairs(P.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

-- Spies on the startQuest of the listed globals (H.spyOn does not call the original)
function P.spyStarts(globals)
	local spies = {}

	for _, g in ipairs(globals or P.GLOBALS) do
		spies[g] = H.spyOn(P.quest(g), "startQuest")
	end

	return spies
end

-- the sorted list of globals whose startQuest was called, one entry per call
function P.started(spies)
	local out = {}

	for g, calls in pairs(spies) do
		for _ = 1, #calls do
			out[#out + 1] = g
		end
	end

	table.sort(out)
	return out
end

return P
