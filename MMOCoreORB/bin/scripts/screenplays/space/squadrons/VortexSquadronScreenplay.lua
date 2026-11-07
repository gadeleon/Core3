local SpaceHelpers = require("utils.space_helpers")

--[[

	Vortex Squadron Quests

]]

--[[
	Tier 1 -- V3-FX (Naboo, Moenia)
	Trainer: V3-FX (conversation v3fxConvoHandler), Moenia gazebo (screenplays/cities/naboo_moenia.lua:108). 8 quest tables for 6 SWG-Source names: naboo_rebel_1..4, 6, 7 (patrol, destroy_surpriseattack, destroy, escort, assassinate, destroy_duty, escort_duty), from datatables/spacequest and naboo_rebel_trainer_1.java; feature vortex-tier1-v3-fx
	Tiers 2-4 (Brother Vrovel, Brother Ezkiel, Brother Extok Evin) are below
]]

-- Mission 1: Patrol with surprise attack
patrol_naboo_rebel_1 = SpacePatrolScreenplay:new {
	className = "patrol_naboo_rebel_1",

	questName = "naboo_rebel_1",
	questType = "patrol",

	questZone = "space_naboo",

	creditReward = 100,

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_rebel_1",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 13,

	patrolPoints = {
		{patrolPointName = "rebel_patrol_1", x = -3153, z = 302, y = -6442, patrolNumber = 1, radius = 150},
		{patrolPointName = "rebel_patrol_2", x = -3971, z = -471, y = -6364, patrolNumber = 2, radius = 150},
		{patrolPointName = "rebel_patrol_3", x = -5771, z = -1066, y = -5197, patrolNumber = 3, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_rebel_1", true)

destroy_surpriseattack_naboo_rebel_1 = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_rebel_1",

	questName = "naboo_rebel_1",
	questType = "destroy_surpriseattack",

	questZone = "space_naboo",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_naboo_rebel_1",
	parentQuestType = "patrol",
	parentQuestName = "naboo_rebel_1",

	surpriseAttackShips = {
		zone = "space_naboo",
		spawns = {{count = 3, shipName = "imp_tie_fighter_tier1"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_rebel_1", true)

-- Mission 2: Destroy
destroy_naboo_rebel_2 = SpaceDestroyScreenplay:new {
	className = "destroy_naboo_rebel_2",

	questName = "naboo_rebel_2",
	questType = "destroy",

	questZone = "space_naboo",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	killsRequired = 4,

	shipLocations = {
		{spawnName = "imperial_fluff_spawns_1", x = 386, z = 3917, y = 3129},
		{spawnName = "imperial_fluff_spawns_3", x = -2024, z = -3820, y = -3131},
		{spawnName = "imperial_fluff_spawns_5", x = -5968, z = -1847, y = 386},
		{spawnName = "naboo_imperial_2", x = -1915, z = -2006, y = -1455},
		{spawnName = "imperial_patrol_1", x = 263, z = 2203, y = 1703},
	},

	shipTypes = {
		"imp_tie_fighter_tier1",
		"imp_tie_fighter_tier2",
		"imp_tie_fighter_tier3",
		"imp_tie_fighter_tier4",
		"imp_tie_fighter_tier2_naboo",
	},
}

registerScreenPlay("destroy_naboo_rebel_2", true)

-- Mission 3: Patrol with escort side quest
patrol_naboo_rebel_3 = SpacePatrolScreenplay:new {
	className = "patrol_naboo_rebel_3",

	questName = "naboo_rebel_3",
	questType = "patrol",

	questZone = "space_naboo",

	creditReward = 500,
	-- SWG's rebel_bodysuit_s14.iff has no pre-NGE template; bodysuit_s14 as for Kreezo (space-trainer-rewards D-11)
	itemReward = {
		{species = {SPECIES_WOOKIEE}, item = "object/tangible/wearables/bandolier/multipocket_bandolier.iff"},
		{species = {SPECIES_ITHORIAN}, item = "object/tangible/wearables/bandolier/ith_multipocket_bandolier.iff"},
		{species = {-1}, item = "object/tangible/wearables/bodysuit/bodysuit_s14.iff"},
	},

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "naboo_rebel_3",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 15,

	patrolPoints = {
		{patrolPointName = "rebel_security_patrol_1", x = -2448, z = 879, y = -1221, patrolNumber = 1, radius = 150},
		{patrolPointName = "rebel_security_patrol_2", x = -1792, z = 1559, y = -1193, patrolNumber = 2, radius = 150},
		{patrolPointName = "rebel_security_patrol_3", x = -288, z = 1479, y = -1395, patrolNumber = 3, radius = 150},
		{patrolPointName = "rebel_security_patrol_4", x = 39, z = 1753, y = 294, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_rebel_3", true)

escort_naboo_rebel_3 = SpaceEscortScreenplay:new {
	className = "escort_naboo_rebel_3",

	questName = "naboo_rebel_3",
	questType = "escort",

	questZone = "space_naboo",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_naboo_rebel_3",
	parentQuestType = "patrol",
	parentQuestName = "naboo_rebel_3",

	escortShips = {"reb_freightermedium_tier1"},

	escortPoints = {
		{patrolPointName = "rebel_escort_1", zoneName = "space_naboo", x = -168, z = 1747, y = -258, escortNumber = 1, radius = 250},
		{patrolPointName = "rebel_escort_2", zoneName = "space_naboo", x = -1077, z = 1502, y = 59, escortNumber = 2, radius = 250},
		{patrolPointName = "rebel_escort_3", zoneName = "space_naboo", x = -1645, z = 1097, y = 854, escortNumber = 3, radius = 250},
		{patrolPointName = "rebel_escort_4", zoneName = "space_naboo", x = -2734, z = 791, y = 1760, escortNumber = 4, radius = 250},
	},

	attackDelay = 80,

	attackShips = {
		{"imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"},
	},

	tauntData = {goodbyeCount = 3, reasonCount = 3, tauntCount = 3, thanksCount = 3},
}

registerScreenPlay("escort_naboo_rebel_3", true)

-- Mission 4: Assassinate
assassinate_naboo_rebel_4 = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_rebel_4",

	questType = "assassinate",
	questName = "naboo_rebel_4",

	questZone = "space_naboo",

	creditReward = 1000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/armor/arm_mission_reward_rebel_incom_ultralight.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	arrivalDelay = 10,
	failTimer = 20,
	mustDestroyEscort = false,

	assassinateSpawns = {
		target = "imp_tie_fighter_veteran_tier2",
		escorts = {"imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_8", x = 3875, z = -3872, y = -3934},
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_6", x = 417, z = -839, y = -2617},
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_4", x = -1492, z = 746, y = -2021},
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_2", x = 1333, z = -1855, y = -3915},
		{patrolPointName = "naboo_imperial_tier2_recovery1_3", x = 262, z = -3151, y = 332},
	},
}

registerScreenPlay("assassinate_naboo_rebel_4", true)

-- V3-FX Duty Missions
destroy_duty_naboo_rebel_6 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_naboo_rebel_6",

	questName = "naboo_rebel_6",
	questType = "destroy_duty",

	questZone = "space_naboo",

	creditReward = 100,

	sideQuest = false,
	sideQuestType = "",

	totalLevels = 5,
	totalRounds = 2,
	totalWaves = 3,

	bossShip = "imp_tie_fighter_tier2",
	shipTypes = {
		{"imp_tie_fighter_tier1"},
	},
}

registerScreenPlay("destroy_duty_naboo_rebel_6", true)

escort_duty_naboo_rebel_7 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_naboo_rebel_7",

	questName = "naboo_rebel_7",
	questType = "escort_duty",

	questZone = "space_naboo",

	creditReward = 1000,
	creditKillBonus = 100,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {
		"reb_transport_tier1", "reb_freightermedium_tier1", "reb_freighterlight_tier1", "reb_freighterheavy_tier1",
	},

	escortPoints = {
		{patrolPointName = "rebel_patrol_1", zoneName = "space_naboo", x = -3153, z = 302, y = -6442, escortNumber = 1, radius = 250},
		{patrolPointName = "rebel_patrol_2", zoneName = "space_naboo", x = -3971, z = -471, y = -6364, escortNumber = 2, radius = 250},
		{patrolPointName = "rebel_patrol_3", zoneName = "space_naboo", x = -5771, z = -1066, y = -5197, escortNumber = 3, radius = 250},
		{patrolPointName = "rebel_escort_1", zoneName = "space_naboo", x = -168, z = 1747, y = -258, escortNumber = 4, radius = 250},
		{patrolPointName = "rebel_escort_2", zoneName = "space_naboo", x = -1077, z = 1502, y = 59, escortNumber = 5, radius = 250},
		{patrolPointName = "rebel_escort_3", zoneName = "space_naboo", x = -1645, z = 1097, y = 854, escortNumber = 6, radius = 250},
		{patrolPointName = "rebel_escort_4", zoneName = "space_naboo", x = -2734, z = 791, y = 1760, escortNumber = 7, radius = 250},
	},

	attackDelay = 100,

	attackShips = {
		{"imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_naboo_rebel_7", true)

--[[
	Tier 2 -- Brother Vrovel (Dantooine, abandoned Rebel base; Lok, Yavin 4 and Dantooine systems)
	Ported from SWG-Source vortex_mission_1..7 (escort, inspect, destroy_surpriseattack, recovery, escort_duty, destroy_duty, recovery_duty); feature vortex-tier2-vrovel-missions
]]

-- Mission 1: Escort with inspect and surprise attack side quests
escort_vortex_mission_1 = SpaceEscortScreenplay:new {
	className = "escort_vortex_mission_1",

	questName = "vortex_mission_1",
	questType = "escort",

	questZone = "space_lok",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/shield_generator/shd_mission_reward_rebel_incom_k77.iff"},
	},

	sideQuest = true,
	sideQuestType = "inspect",
	sideQuestName = "vortex_mission_1",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 8,

	escortShips = {"vortex_mission_1_finn_darktrin"},

	escortPoints = {
		{patrolPointName = "vortex_mission_1_1", zoneName = "space_lok", x = 2241, z = -1210, y = -2943, escortNumber = 1, radius = 250},
		{patrolPointName = "vortex_mission_1_2", zoneName = "space_lok", x = 694, z = -1147, y = -2899, escortNumber = 2, radius = 250},
		{patrolPointName = "vortex_mission_1_3", zoneName = "space_lok", x = -145, z = -1077, y = -2900, escortNumber = 3, radius = 250},
		{patrolPointName = "vortex_mission_1_4", zoneName = "space_lok", x = -1009, z = -1075, y = -2900, escortNumber = 4, radius = 250},
		{patrolPointName = "vortex_mission_1_5", zoneName = "space_lok", x = -2464, z = -1051, y = -2900, escortNumber = 5, radius = 250},
	},

	attackDelay = 100,

	attackShips = {
		{"corsair_raider_tier2", "corsair_raider_tier2"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_vortex_mission_1", true)

inspect_vortex_mission_1 = SpaceInspectScreenplay:new {
	className = "inspect_vortex_mission_1",

	questName = "vortex_mission_1",
	questType = "inspect",

	questZone = "space_lok",

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "vortex_mission_1",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.INSPECTION,

	sideQuestInspectCount = 1,
	sideQuestDelay = 2,

	parentQuest = "escort_vortex_mission_1",
	parentQuestType = "escort",
	parentQuestName = "vortex_mission_1",

	shipList = {"vortex_mission_1_shuttle"},

	validSpawns = {
		{spawnName = "vortex_mission_1_shuttle", x = -3745, z = -3124, y = -658},
	},

	giveSpawnWaypoint = 1,

	-- SWG's literal: no ship carries it, the first inspection splits the quest
	cargo = "placeholder",
}

registerScreenPlay("inspect_vortex_mission_1", true)

destroy_surpriseattack_vortex_mission_1 = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_vortex_mission_1",

	questName = "vortex_mission_1",
	questType = "destroy_surpriseattack",

	questZone = "space_lok",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "inspect_vortex_mission_1",
	parentQuestType = "inspect",
	parentQuestName = "vortex_mission_1",

	surpriseAttackShips = {
		zone = "space_lok",
		spawns = {{count = 2, shipName = "imp_tie_interceptor_tier2"}},
	},
}

registerScreenPlay("destroy_surpriseattack_vortex_mission_1", true)

-- Mission 2: Escort
escort_vortex_mission_2 = SpaceEscortScreenplay:new {
	className = "escort_vortex_mission_2",

	questName = "vortex_mission_2",
	questType = "escort",

	questZone = "space_yavin4",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/droid_interface/ddi_mission_reward_rebel_moncal_d22.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"vortex_mission_2_scientist"},

	escortPoints = {
		{patrolPointName = "naboo_escort_tier2_1", zoneName = "space_yavin4", x = 2302, z = 2604, y = -3458, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_escort_tier2_2", zoneName = "space_yavin4", x = 1630, z = 2722, y = -3773, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_escort_tier2_3", zoneName = "space_yavin4", x = 240, z = 1911, y = -3160, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_escort_tier2_4", zoneName = "space_yavin4", x = -969, z = -905, y = -814, escortNumber = 4, radius = 250},
		{patrolPointName = "naboo_escort_tier2_5", zoneName = "space_yavin4", x = -3007, z = -5718, y = 4617, escortNumber = 5, radius = 250},
	},

	attackDelay = 60,

	attackShips = {
		{"imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
		{"imp_tie_interceptor_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
		{"tieinterceptor_inquisitor_tier3", "imp_tie_interceptor_tier2", "imp_tie_interceptor_tier2"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_vortex_mission_2", true)

-- Mission 3: Recovery
recovery_vortex_mission_3 = SpaceRecoveryScreenplay:new {
	className = "recovery_vortex_mission_3",

	questName = "vortex_mission_3",
	questType = "recovery",

	questZone = "space_yavin4",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/booster/bst_mission_reward_rebel_novaldex_hypernova.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	arrivalDelay = 15,
	recoveryDelay = 30,

	recoverShip = "prison_transport_imperial",
	recoveryConversationMobile = "object/mobile/shared_dressed_dathomir_prisoner_03.iff",

	escortShips = {"vortex_mission_4_guard"},

	preRecoveryPoints = {
		{patrolPointName = "vortex_mission_3_1", x = -3100, z = -1800, y = 600, escortNumber = 1, radius = 250},
		{patrolPointName = "vortex_mission_3_2", x = -2596, z = 126, y = 3005, escortNumber = 2, radius = 250},
		{patrolPointName = "vortex_mission_3_3", x = -990, z = 331, y = 3100, escortNumber = 3, radius = 250},
		{patrolPointName = "vortex_mission_3_4", x = 323, z = 348, y = 3303, escortNumber = 4, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "vortex_mission_3_recovery_1", x = 2437, z = -873, y = 2907, escortNumber = 1, radius = 250},
		{patrolPointName = "vortex_mission_3_recovery_2", x = 1893, z = -808, y = -39, escortNumber = 2, radius = 250},
		{patrolPointName = "vortex_mission_3_recovery_3", x = 2101, z = 2448, y = -2498, escortNumber = 3, radius = 250},
	},

	attackDelay = 100,

	attackShips = {
		{"imp_tie_interceptor_tier2", "imp_tie_interceptor_tier2", "imp_tie_interceptor_tier2"},
		{"imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
		{"imp_tie_bomber_tier2", "imp_tie_bomber_tier2", "imp_tie_bomber_tier2"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_vortex_mission_3", true)

-- Mission 4: Inspect
inspect_vortex_mission_4 = SpaceInspectScreenplay:new {
	className = "inspect_vortex_mission_4",

	questName = "vortex_mission_4",
	questType = "inspect",

	questZone = "space_dantooine",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon/wpn_mission_reward_rebel_taim_ion_driver.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	shipList = {"vortex_mission_4_shuttle"},

	validSpawns = {
		{spawnName = "vortex_mission_4_shuttle", x = -3273, z = -3335, y = -3027},
	},

	giveSpawnWaypoint = 1,

	cargo = "ship_starting_coordinates",
}

registerScreenPlay("inspect_vortex_mission_4", true)

-- Vrovel Duty Missions
escort_duty_vortex_mission_5 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_vortex_mission_5",

	questName = "vortex_mission_5",
	questType = "escort_duty",

	questZone = "space_dantooine",

	creditReward = 2500,
	creditKillBonus = 200,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"reb_smuggler_ykl37r_tier2", "reb_smuggler_yt1300_tier2"},

	escortPoints = {
		{patrolPointName = "random_mission_point_6", zoneName = "space_dantooine", x = 2415, z = -11, y = -150, escortNumber = 1, radius = 250},
		{patrolPointName = "random_mission_point_7", zoneName = "space_dantooine", x = -1101, z = 3285, y = 2375, escortNumber = 2, radius = 250},
		{patrolPointName = "random_mission_point_2", zoneName = "space_dantooine", x = -1197, z = 2058, y = -595, escortNumber = 3, radius = 250},
		{patrolPointName = "random_mission_point_3", zoneName = "space_dantooine", x = -1977, z = 2596, y = 985, escortNumber = 4, radius = 250},
	},

	attackDelay = 80,

	attackShips = {
		{"imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
		{"imp_tie_bomber_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
		{"imp_tie_interceptor_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_vortex_mission_5", true)

destroy_duty_vortex_mission_6 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_vortex_mission_6",

	questName = "vortex_mission_6",
	questType = "destroy_duty",

	questZone = "space_dantooine",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	totalLevels = 5,
	totalRounds = 2,
	totalWaves = 3,

	bossShip = "imp_tie_interceptor_tier3",
	shipTypes = {
		{"imp_tie_fighter_tier2", "imp_tie_interceptor_tier2"},
		{"imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
		{"imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
	},
}

registerScreenPlay("destroy_duty_vortex_mission_6", true)

recovery_duty_vortex_mission_7 = SpaceDutyRecoveryScreenplay:new {
	className = "recovery_duty_vortex_mission_7",

	questName = "vortex_mission_7",
	questType = "recovery_duty",

	questZone = "space_dantooine",

	creditReward = 2500,
	creditKillBonus = 200,

	sideQuest = false,
	sideQuestType = "",

	numResponses = 5,

	arrivalDelay = 15,
	recoveryDelay = 30,

	recoverShips = {"imp_lambda_shuttle_tier2", "imp_tie_bomber_tier2", "imp_tie_interceptor_tier2"},
	recoveryConversationMobile = "object/mobile/shared_ig_assassin_droid.iff",

	escortShips = {"imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},

	preRecoveryPoints = {
		{patrolPointName = "tier3_privateer_escort_path_04", x = -1587, z = -3210, y = -2825, escortNumber = 1, radius = 250},
		{patrolPointName = "corellia_privateer_tier4_recovery_duty_egress_3", x = -491, z = -6021, y = -3466, escortNumber = 2, radius = 250},
		{patrolPointName = "corellia_imperial_tier4_escortduty_2", x = 2450, z = 2475, y = -4817, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_survival1", x = 4000, z = -2500, y = -5600, escortNumber = 4, radius = 250},
		{patrolPointName = "corellia_privateer_assassinate_42a_4", x = -337, z = -3780, y = -7480, escortNumber = 5, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "naboo_rebel_tier4_1_rescue_duty_2", x = 2490, z = 5986, y = -6356, escortNumber = 1, radius = 250},
		{patrolPointName = "corellia_privateer_tier3_pickup", x = 4170, z = -4074, y = -4613, escortNumber = 2, radius = 250},
		{patrolPointName = "corellia_imperial_tier4_recovery1_5", x = 6068, z = -1909, y = -6308, escortNumber = 3, radius = 250},
	},

	attackDelay = 100,

	attackShips = {
		{"imp_tie_interceptor_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
		{"imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_duty_vortex_mission_7", true)

--[[
	Tier 3 -- Brother Ezkiel (Dantooine, abandoned Rebel base; Dantooine, Endor and Dathomir systems)
	Ported from SWG-Source naboo_rebel_tier3_1..4 and their splits (assassinate, escort, survival, inspect, delivery_no_pickup, space_battle, rescue, patrol, destroy_surpriseattack, recovery, delivery); feature vortex-tier3-ezkiel-missions
]]

-- Mission 1: Assassinate > Escort > Survival > Inspect > Delivery (no pickup)
assassinate_naboo_rebel_tier3_1 = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_rebel_tier3_1",

	questName = "naboo_rebel_tier3_1",
	questType = "assassinate",

	questZone = "space_dantooine",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/armor/arm_mission_reward_rebel_corellian_triplate.iff"},
	},

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "naboo_rebel_tier3_1_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	arrivalDelay = 10,
	failTimer = 20,
	mustDestroyEscort = false,

	assassinateSpawns = {
		target = "tieadvanced_inquisitor_tier3",
		escorts = {"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "corellia_imperial_tier4_recovery1_2", x = 1014, z = -431, y = 1398},
		{patrolPointName = "corellia_imperial_tier4_recovery1_4", x = 6538, z = -1692, y = -3169},
		{patrolPointName = "corellia_imperial_tier4_recovery1_6", x = 6312, z = -1058, y = -6910},
		{patrolPointName = "corellia_imperial_tier4_rescueduty_2", x = 294, z = 509, y = 3594},
	},
}

registerScreenPlay("assassinate_naboo_rebel_tier3_1", true)

escort_naboo_rebel_tier3_1_a = SpaceEscortScreenplay:new {
	className = "escort_naboo_rebel_tier3_1_a",

	questName = "naboo_rebel_tier3_1_a",
	questType = "escort",

	questZone = "space_dantooine",

	sideQuest = true,
	sideQuestType = "survival",
	sideQuestName = "naboo_rebel_tier3_1_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 15,

	parentQuest = "assassinate_naboo_rebel_tier3_1",
	parentQuestType = "assassinate",
	parentQuestName = "naboo_rebel_tier3_1",

	escortShips = {"naboo_tier3_imperial_spy"},

	escortPoints = {
		{patrolPointName = "naboo_rebel_tier3_point_1", x = 4957, z = 3250, y = 4698, zoneName = "space_dantooine", escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_rebel_tier3_point_2", x = 2568, z = 3857, y = 2000, zoneName = "space_dantooine", escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_rebel_tier3_point_3", x = -15, z = 4452, y = -618, zoneName = "space_dantooine", escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_rebel_tier3_point_4", x = -2585, z = 5075, y = -3250, zoneName = "space_dantooine", escortNumber = 4, radius = 250},
	},

	attackDelay = 80,

	attackShips = {
		{"imp_tie_advanced_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"imp_tie_bomber_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"imp_tie_interceptor_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
	},

	tauntData = {goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2},
}

registerScreenPlay("escort_naboo_rebel_tier3_1_a", true)

survival_naboo_rebel_tier3_1_b = SpaceSurvivalScreenplay:new {
	className = "survival_naboo_rebel_tier3_1_b",

	questName = "naboo_rebel_tier3_1_b",
	questType = "survival",

	questZone = "space_dantooine",

	sideQuest = true,
	sideQuestType = "inspect",
	sideQuestName = "naboo_rebel_tier3_1_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	parentQuest = "escort_naboo_rebel_tier3_1_a",
	parentQuestType = "escort",
	parentQuestName = "naboo_rebel_tier3_1_a",

	transmissionPoint = {patrolPointName = "naboo_rebel_tier3_survival_point", x = -2327, z = 5908, y = -2768},
	totalTransmissionTime = 360,
	timesToUpdateProgress = 4,
	transmissionStartDelay = 10,
	delayToFirstAttack = 10,

	attackShipLists = {
		{"imp_tie_interceptor_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"tieinterceptor_inquisitor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
		{"imp_tie_bomber_tier3", "imp_tie_bomber_tier3", "imp_tie_bomber_tier3"},
	},

	attackPeriod = 80,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("survival_naboo_rebel_tier3_1_b", true)

inspect_naboo_rebel_tier3_1_c = SpaceInspectScreenplay:new {
	className = "inspect_naboo_rebel_tier3_1_c",

	questName = "naboo_rebel_tier3_1_c",
	questType = "inspect",

	questZone = "space_dantooine",

	sideQuest = true,
	sideQuestType = "delivery_no_pickup",
	sideQuestName = "naboo_rebel_tier3_1_d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 15,

	parentQuest = "survival_naboo_rebel_tier3_1_b",
	parentQuestType = "survival",
	parentQuestName = "naboo_rebel_tier3_1_b",

	shipList = {"naboo_tier3_imperial_spy"},

	validSpawns = {
		{spawnName = "naboo_rebel_tier3_inspect_target", x = -3838, z = 5840, y = -3806},
	},

	giveSpawnWaypoint = 1,

	cargo = "experiment_information",
}

registerScreenPlay("inspect_naboo_rebel_tier3_1_c", true)

delivery_no_pickup_naboo_rebel_tier3_1_d = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_naboo_rebel_tier3_1_d",

	questName = "naboo_rebel_tier3_1_d",
	questType = "delivery_no_pickup",

	questZone = "space_dantooine",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "inspect_naboo_rebel_tier3_1_c",
	parentQuestType = "inspect",
	parentQuestName = "naboo_rebel_tier3_1_c",

	deliveryShip = "freighterheavy_rebel_tier3",

	deliveryPoint = {patrolPointName = "naboo_rebel_tier3_delivery_point_1", x = -2431, z = 7301, y = -707},

	attackShipLists = {
		{"imp_tie_bomber_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"tieinterceptor_inquisitor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
	},

	attackPeriod = 80,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_no_pickup_naboo_rebel_tier3_1_d", true)

-- Mission 2: Space battle > Rescue > Patrol > Surprise attack > Inspect
space_battle_naboo_rebel_tier3_2 = SpaceBattleScreenplay:new {
	className = "space_battle_naboo_rebel_tier3_2",

	questName = "naboo_rebel_tier3_2",
	questType = "space_battle",

	questZone = "space_dantooine",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon_capacitor/cap_mission_reward_rebel_qualdex_battery_array.iff"},
	},

	sideQuest = true,
	sideQuestType = "rescue",
	sideQuestName = "naboo_rebel_tier3_2_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	battlePoint = {patrolPointName = "naboo_rebel_tier3_battle_point", x = -179, z = -1167, y = 4938, forward = {x = 0.335610, z = -0.349005, y = 0.874964}},

	damageMultiplier = 6,
	allyArrivalDelay = 80,
	enemyArrivalDelay = 110,
	allyOriginDist = 700,
	enemyOriginDist = -700,
	allyArrivalDist = 200,
	enemyArrivalDist = -100,

	allyForce = {"spynet_assassin_tier3", "spynet_special_ops_tier3", "spynet_special_ops_tier3", "spynet_bomber_tier3"},

	enemyForce = {"blacklight_assassin_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3", "blacklight_bomber_tier3", "blacklight_bomber_tier3", "blacklight_bomber_tier3"},
}

registerScreenPlay("space_battle_naboo_rebel_tier3_2", true)

rescue_naboo_rebel_tier3_2_a = SpaceRescueScreenplay:new {
	className = "rescue_naboo_rebel_tier3_2_a",

	questName = "naboo_rebel_tier3_2_a",
	questType = "rescue",

	questZone = "space_dantooine",

	sideQuest = true,
	sideQuestType = "patrol",
	sideQuestName = "naboo_rebel_tier3_2_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	parentQuest = "space_battle_naboo_rebel_tier3_2",
	parentQuestType = "space_battle",
	parentQuestName = "naboo_rebel_tier3_2",

	recoveryPath = {
		{patrolPointName = "naboo_rebel_tier3_rescue_1", x = -2257, z = -3938, y = -1441},
		{patrolPointName = "naboo_rebel_tier3_rescue_2", x = -1722, z = -2498, y = 1940},
		{patrolPointName = "naboo_rebel_tier3_rescue_3", x = -996, z = -2105, y = 4791},
		{patrolPointName = "naboo_rebel_tier3_rescue_4", x = 378, z = -1904, y = 6544},
	},

	targetShipType = "spynet_fighter_tier3",
	targetArrivalDelay = 0,

	attackShipLists = {
		{"blacklight_assassin_tier3", "blacklight_assassin_tier3", "blacklight_assassin_tier3"},
		{"blacklight_bomber_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3"},
	},

	attackPeriod = 80,
	attackListType = SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
	numResponses = 3,
}

registerScreenPlay("rescue_naboo_rebel_tier3_2_a", true)

patrol_naboo_rebel_tier3_2_b = SpacePatrolScreenplay:new {
	className = "patrol_naboo_rebel_tier3_2_b",

	questName = "naboo_rebel_tier3_2_b",
	questType = "patrol",

	questZone = "space_dantooine",

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_rebel_tier3_2_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 3,
	sideQuestDelay = 10,

	parentQuest = "rescue_naboo_rebel_tier3_2_a",
	parentQuestType = "rescue",
	parentQuestName = "naboo_rebel_tier3_2_a",

	patrolPoints = {
		{patrolPointName = "naboo_rebel_tier3_patrol_1", x = 367, z = -1902, y = 6515, patrolNumber = 1, radius = 150},
		{patrolPointName = "naboo_rebel_tier3_patrol_2", x = 21, z = -5166, y = 3573, patrolNumber = 2, radius = 150},
		{patrolPointName = "naboo_rebel_tier3_patrol_3", x = -20, z = -6038, y = 2818, patrolNumber = 3, radius = 150},
		{patrolPointName = "naboo_rebel_tier3_patrol_4", x = -73, z = -6814, y = 1855, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_rebel_tier3_2_b", true)

destroy_surpriseattack_naboo_rebel_tier3_2_c = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_rebel_tier3_2_c",

	questName = "naboo_rebel_tier3_2_c",
	questType = "destroy_surpriseattack",

	questZone = "space_dantooine",

	sideQuest = true,
	sideQuestType = "inspect",
	sideQuestName = "naboo_rebel_tier3_2_d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 12,

	parentQuest = "patrol_naboo_rebel_tier3_2_b",
	parentQuestType = "patrol",
	parentQuestName = "naboo_rebel_tier3_2_b",

	surpriseAttackShips = {
		zone = "space_dantooine",
		spawns = {{count = 4, shipName = "blacklight_fighter_tier3"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_rebel_tier3_2_c", true)

inspect_naboo_rebel_tier3_2_d = SpaceInspectScreenplay:new {
	className = "inspect_naboo_rebel_tier3_2_d",

	questName = "naboo_rebel_tier3_2_d",
	questType = "inspect",

	questZone = "space_dantooine",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "destroy_surpriseattack_naboo_rebel_tier3_2_c",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "naboo_rebel_tier3_2_c",

	shipList = {"blacklight_pirate_fighter_quest"},

	validSpawns = {
		{spawnName = "naboo_rebel_tier3_pirate_leader_inspect", x = -711, z = -5678, y = 1064},
	},

	giveSpawnWaypoint = 1,

	cargo = "leader_location",
}

registerScreenPlay("inspect_naboo_rebel_tier3_2_d", true)

-- Mission 3: Patrol > Surprise attack > Survival > Patrol > Assassinate
patrol_naboo_rebel_tier3_3 = SpacePatrolScreenplay:new {
	className = "patrol_naboo_rebel_tier3_3",

	questName = "naboo_rebel_tier3_3",
	questType = "patrol",

	questZone = "space_endor",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/engine/eng_mission_reward_rebel_incom_military.iff"},
	},

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_rebel_tier3_3_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 3,
	sideQuestDelay = 8,

	patrolPoints = {
		{patrolPointName = "naboo_rebel_tier3_patrol3_1", x = 2432, z = -1174, y = 175, patrolNumber = 1, radius = 150},
		{patrolPointName = "naboo_rebel_tier3_patrol3_2", x = 4402, z = -2116, y = 329, patrolNumber = 2, radius = 150},
		{patrolPointName = "naboo_rebel_tier3_patrol3_3", x = 5662, z = -2940, y = 656, patrolNumber = 3, radius = 150},
		{patrolPointName = "naboo_rebel_tier3_patrol3_4", x = 6031, z = -3567, y = 1431, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_rebel_tier3_3", true)

destroy_surpriseattack_naboo_rebel_tier3_3_a = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_rebel_tier3_3_a",

	questName = "naboo_rebel_tier3_3_a",
	questType = "destroy_surpriseattack",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "survival",
	sideQuestName = "naboo_rebel_tier3_3_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	parentQuest = "patrol_naboo_rebel_tier3_3",
	parentQuestType = "patrol",
	parentQuestName = "naboo_rebel_tier3_3",

	surpriseAttackShips = {
		zone = "space_endor",
		spawns = {{count = 4, shipName = "blacklight_assassin_tier3"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_rebel_tier3_3_a", true)

survival_naboo_rebel_tier3_3_b = SpaceSurvivalScreenplay:new {
	className = "survival_naboo_rebel_tier3_3_b",

	questName = "naboo_rebel_tier3_3_b",
	questType = "survival",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "patrol",
	sideQuestName = "naboo_rebel_tier3_3_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	parentQuest = "destroy_surpriseattack_naboo_rebel_tier3_3_a",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "naboo_rebel_tier3_3_a",

	transmissionPoint = {patrolPointName = "naboo_rebel_tier3_blacklight_point", x = 6712, z = -4486, y = 437},
	totalTransmissionTime = 600,
	timesToUpdateProgress = 6,
	transmissionStartDelay = 10,
	delayToFirstAttack = 10,

	attackShipLists = {
		{"blacklight_assassin_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3"},
		{"blacklight_fighter_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3"},
		{"blacklight_bomber_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3"},
		{"blacklight_leader_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3"},
	},

	attackPeriod = 90,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("survival_naboo_rebel_tier3_3_b", true)

patrol_naboo_rebel_tier3_3_c = SpacePatrolScreenplay:new {
	className = "patrol_naboo_rebel_tier3_3_c",

	questName = "naboo_rebel_tier3_3_c",
	questType = "patrol",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "naboo_rebel_tier3_3_d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 10,

	parentQuest = "survival_naboo_rebel_tier3_3_b",
	parentQuestType = "survival",
	parentQuestName = "naboo_rebel_tier3_3_b",

	patrolPoints = {
		{patrolPointName = "naboo_rebel_tier3_leader_patrol_1", x = 6497, z = -3437, y = 562, patrolNumber = 1, radius = 150},
		{patrolPointName = "naboo_rebel_tier3_leader_patrol_2", x = 6580, z = -3261, y = 1630, patrolNumber = 2, radius = 150},
		{patrolPointName = "naboo_rebel_tier3_leader_patrol_3", x = 5505, z = -3025, y = 2988, patrolNumber = 3, radius = 150},
		{patrolPointName = "naboo_rebel_tier3_leader_patrol_4", x = 4966, z = -2686, y = 4562, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_rebel_tier3_3_c", true)

assassinate_naboo_rebel_tier3_3_d = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_rebel_tier3_3_d",

	questName = "naboo_rebel_tier3_3_d",
	questType = "assassinate",

	questZone = "space_endor",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_naboo_rebel_tier3_3_c",
	parentQuestType = "patrol",
	parentQuestName = "naboo_rebel_tier3_3_c",

	arrivalDelay = 10,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "blacklight_pirate_leader",
		escorts = {"blacklight_assassin_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3", "blacklight_bomber_tier3", "blacklight_fighter_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_rebel_tier3_assassin_path_1", x = 1437, z = -2473, y = 7305},
		{patrolPointName = "naboo_rebel_tier3_assassin_path_2", x = 3964, z = -2520, y = 5227},
		{patrolPointName = "naboo_rebel_tier3_assassin_path_3", x = 5643, z = -2616, y = 3102},
		{patrolPointName = "naboo_rebel_tier3_assassin_path_4", x = 6447, z = -2505, y = 1042},
	},
}

registerScreenPlay("assassinate_naboo_rebel_tier3_3_d", true)

-- Mission 4: Space battle > Patrol > Survival > Recovery > Delivery
space_battle_naboo_rebel_tier3_4 = SpaceBattleScreenplay:new {
	className = "space_battle_naboo_rebel_tier3_4",

	questName = "naboo_rebel_tier3_4",
	questType = "space_battle",

	questZone = "space_dathomir",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/reactor/rct_mission_reward_rebel_slayn_hypervortex.iff"},
	},

	sideQuest = true,
	sideQuestType = "patrol",
	sideQuestName = "naboo_rebel_tier3_4_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	battlePoint = {patrolPointName = "naboo_rebel_tier3_rebel_vs_imperial", x = 5627, z = -441, y = -4388, forward = {x = 0.786536, z = -0.011715, y = -0.617434}},

	damageMultiplier = 6,
	allyArrivalDelay = 60,
	enemyArrivalDelay = 30,
	allyOriginDist = 600,
	enemyOriginDist = -800,
	allyArrivalDist = 100,
	enemyArrivalDist = -100,

	allyForce = {"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},

	enemyForce = {"imp_tie_bomber_tier3", "imp_tie_bomber_tier3", "imp_tie_bomber_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "tieinterceptor_inquisitor_tier3", "imp_tie_fighter_tier3"},
}

registerScreenPlay("space_battle_naboo_rebel_tier3_4", true)

patrol_naboo_rebel_tier3_4_a = SpacePatrolScreenplay:new {
	className = "patrol_naboo_rebel_tier3_4_a",

	questName = "naboo_rebel_tier3_4_a",
	questType = "patrol",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "survival",
	sideQuestName = "naboo_rebel_tier3_4_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 3,
	sideQuestDelay = 9,

	parentQuest = "space_battle_naboo_rebel_tier3_4",
	parentQuestType = "space_battle",
	parentQuestName = "naboo_rebel_tier3_4",

	patrolPoints = {
		{patrolPointName = "naboo_rebel_tier3_4_patrol_1", x = 5786, z = -477, y = -4415, patrolNumber = 1, radius = 150},
		{patrolPointName = "naboo_rebel_tier3_4_patrol_2", x = 4008, z = -2803, y = -5284, patrolNumber = 2, radius = 150},
		{patrolPointName = "naboo_rebel_tier3_4_patrol_3", x = 2254, z = -4146, y = -6242, patrolNumber = 3, radius = 150},
		{patrolPointName = "naboo_rebel_tier3_4_patrol_4", x = 397, z = -5568, y = -7256, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_rebel_tier3_4_a", true)

survival_naboo_rebel_tier3_4_b = SpaceSurvivalScreenplay:new {
	className = "survival_naboo_rebel_tier3_4_b",

	questName = "naboo_rebel_tier3_4_b",
	questType = "survival",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "recovery",
	sideQuestName = "naboo_rebel_tier3_4_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	parentQuest = "patrol_naboo_rebel_tier3_4_a",
	parentQuestType = "patrol",
	parentQuestName = "naboo_rebel_tier3_4_a",

	transmissionPoint = {patrolPointName = "naboo_rebel_tier3_inquisition_point", x = 609, z = -5349, y = -7366},
	totalTransmissionTime = 240,
	timesToUpdateProgress = 3,
	transmissionStartDelay = 60,
	delayToFirstAttack = 30,

	attackShipLists = {
		{"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"tieinterceptor_inquisitor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
		{"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_advanced_tier3"},
	},

	attackPeriod = 80,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("survival_naboo_rebel_tier3_4_b", true)

recovery_naboo_rebel_tier3_4_c = SpaceRecoveryScreenplay:new {
	className = "recovery_naboo_rebel_tier3_4_c",

	questName = "naboo_rebel_tier3_4_c",
	questType = "recovery",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "delivery",
	sideQuestName = "naboo_rebel_tier3_4_d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	parentQuest = "survival_naboo_rebel_tier3_4_b",
	parentQuestType = "survival",
	parentQuestName = "naboo_rebel_tier3_4_b",

	arrivalDelay = 15,
	recoveryDelay = 30,

	recoverShip = "imp_tie_experimental_fighter_tier3",
	recoveryConversationMobile = "object/mobile/shared_ig_assassin_droid.iff",

	escortShips = {"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},

	preRecoveryPoints = {
		{patrolPointName = "naboo_rebel_tier3_recover_imperial_1", x = 4749, z = 109, y = -464, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_rebel_tier3_recover_imperial_2", x = 5198, z = -16, y = -1992, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_rebel_tier3_recover_imperial_3", x = 5514, z = -172, y = -3083, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_rebel_tier3_recover_imperial_4", x = 6221, z = -447, y = -4806, escortNumber = 4, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "naboo_rebel_tier3_recover_imperial_5", x = 4807, z = -1349, y = -3781, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_rebel_tier3_recover_imperial_6", x = 2150, z = -3082, y = -1761, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_rebel_tier3_recover_imperial_7", x = 111, z = -4412, y = -211, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_rebel_tier3_recover_imperial_8", x = -2691, z = -6240, y = 1919, escortNumber = 4, radius = 250},
	},

	attackDelay = 70,

	attackShips = {
		{"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
		{"imp_tie_advanced_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
	},

	tauntData = {panicCount = 2, thanksCount = 2},
}

registerScreenPlay("recovery_naboo_rebel_tier3_4_c", true)

delivery_naboo_rebel_tier3_4_d = SpaceDeliveryScreenplay:new {
	className = "delivery_naboo_rebel_tier3_4_d",

	questName = "naboo_rebel_tier3_4_d",
	questType = "delivery",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "recovery_naboo_rebel_tier3_4_c",
	parentQuestType = "recovery",
	parentQuestName = "naboo_rebel_tier3_4_c",

	pickupShip = "reb_freighterheavy_tier3",
	deliveryShip = "reb_gunboat_tier3",

	pickupPoint = {patrolPointName = "naboo_rebel_tier3_pickup", x = -2596, z = -2751, y = 1595},
	deliveryPoint = {patrolPointName = "naboo_rebel_tier3_delivery", x = -2671, z = -6097, y = 1923},

	attackShipLists = {
		{"imp_tie_bomber_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
		{"imp_tie_advanced_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
	},

	attackPeriod = 60,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_naboo_rebel_tier3_4_d", true)

--[[
	Tier 4 -- Brother Extok Evin (Talus, Dearic theater; Endor, Yavin, Dathomir and Dantooine systems)
	Ported from SWG-Source naboo_rebel_tier4_1..4, their success and failure splits and the four tier 4 duties (survival, assassinate, escort, space_battle, destroy_surpriseattack, rescue, delivery_no_pickup, destroy_duty, escort_duty, recovery_duty, rescue_duty); feature vortex-tier4-extok-evin
]]

-- Mission 1: Survival > Assassinate (won) or Escort (lost)
survival_naboo_rebel_tier4_1 = SpaceSurvivalScreenplay:new {
	className = "survival_naboo_rebel_tier4_1",

	questName = "naboo_rebel_tier4_1",
	questType = "survival",

	questZone = "space_endor",

	creditReward = 10000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/shield_generator/shd_mission_reward_rebel_taim_military_grade.iff"},
	},

	sideQuest = true,
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL,
	sideQuestType = "assassinate",
	sideQuestName = "naboo_rebel_tier4_1_a",
	sideFailQuestType = "escort",
	sideFailQuestName = "naboo_rebel_tier4_1_b",

	sideQuestDelay = 5,

	-- Screenplay Specific Variables
	transmissionPoint = {patrolPointName = "naboo_rebel_tier4_1_survival", x = -4407, z = 1109, y = -1180},
	totalTransmissionTime = 360,
	timesToUpdateProgress = 6,
	transmissionStartDelay = 10,
	delayToFirstAttack = 10,

	attackShipLists = {
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_bomber_tier4", "imp_tie_bomber_tier4", "imp_tie_bomber_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_advanced_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
	},

	attackPeriod = 55,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.RANDOM,
}

registerScreenPlay("survival_naboo_rebel_tier4_1", true)

assassinate_naboo_rebel_tier4_1_a = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_rebel_tier4_1_a",

	questName = "naboo_rebel_tier4_1_a",
	questType = "assassinate",

	questZone = "space_endor",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "survival_naboo_rebel_tier4_1",
	parentQuestType = "survival",
	parentQuestName = "naboo_rebel_tier4_1",

	arrivalDelay = 5,
	failTimer = 20,
	mustDestroyEscort = false,

	assassinateSpawns = {
		target = "tieadvanced_inquisitor_tier4",
		escorts = {"imp_tie_advanced_tier4", "imp_tie_advanced_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_rebel_tier4_1_a_assassin_1", x = -4168, z = 520, y = -2148},
		{patrolPointName = "naboo_rebel_tier4_1_a_assassin_2", x = -4981, z = 745, y = -1652},
		{patrolPointName = "naboo_rebel_tier4_1_a_assassin_3", x = -5612, z = 919, y = -1266},
		{patrolPointName = "naboo_rebel_tier4_1_a_assassin_4", x = -6259, z = 1098, y = -871},
		{patrolPointName = "naboo_rebel_tier4_1_a_assassin_5", x = -7155, z = 1345, y = -324},
		{patrolPointName = "naboo_rebel_tier4_1_a_assassin_6", x = -7584, z = 1596, y = 263},
	},
}

registerScreenPlay("assassinate_naboo_rebel_tier4_1_a", true)

escort_naboo_rebel_tier4_1_b = SpaceEscortScreenplay:new {
	className = "escort_naboo_rebel_tier4_1_b",

	questName = "naboo_rebel_tier4_1_b",
	questType = "escort",

	questZone = "space_endor",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "survival_naboo_rebel_tier4_1",
	parentQuestType = "survival",
	parentQuestName = "naboo_rebel_tier4_1",

	escortShips = {"reb_freightermedium_tier4"},

	escortPoints = {
		{patrolPointName = "naboo_rebel_tier4_1_b_escort_1", x = -2189, z = 336, y = -2467, zoneName = "space_endor", escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_b_escort_2", x = -1044, z = 316, y = -2733, zoneName = "space_endor", escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_b_escort_3", x = -132, z = 297, y = -2943, zoneName = "space_endor", escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_b_escort_4", x = 1357, z = 265, y = -3286, zoneName = "space_endor", escortNumber = 4, radius = 250},
	},

	attackDelay = 45,

	attackShips = {
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_bomber_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_bomber_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_advanced_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_naboo_rebel_tier4_1_b", true)

-- Mission 2: Assassinate > Space battle (won) or Surprise attack > Assassinate in Dathomir (lost)
assassinate_naboo_rebel_tier4_2 = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_rebel_tier4_2",

	questName = "naboo_rebel_tier4_2",
	questType = "assassinate",

	questZone = "space_yavin4",

	creditReward = 10000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/droid_interface/ddi_mission_reward_rebel_novaldex_low_latency.iff"},
	},

	sideQuest = true,
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL,
	sideQuestType = "space_battle",
	sideQuestName = "naboo_rebel_tier4_2_a",
	sideFailQuestType = "destroy_surpriseattack",
	sideFailQuestName = "naboo_rebel_tier4_2_b",

	sideQuestDelay = 5,

	arrivalDelay = 10,
	failTimer = 20,
	mustDestroyEscort = false,

	assassinateSpawns = {
		target = "tieaggressor_uvqolo",
		escorts = {"imp_tie_advanced_tier4", "imp_tie_advanced_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_rebel_tier4_2_assassin_1", x = 3918, z = 4348, y = -3225},
		{patrolPointName = "naboo_rebel_tier4_2_assassin_2", x = 2563, z = 4412, y = -3307},
		{patrolPointName = "naboo_rebel_tier4_2_assassin_3", x = 1131, z = 4477, y = -2086},
		{patrolPointName = "naboo_rebel_tier4_2_assassin_4", x = -48, z = 4539, y = -344},
		{patrolPointName = "naboo_rebel_tier4_2_assassin_5", x = -1519, z = 4604, y = 2034},
		{patrolPointName = "naboo_rebel_tier4_2_assassin_6", x = -6830, z = 4677, y = 3510},
	},
}

registerScreenPlay("assassinate_naboo_rebel_tier4_2", true)

space_battle_naboo_rebel_tier4_2_a = SpaceBattleScreenplay:new {
	className = "space_battle_naboo_rebel_tier4_2_a",

	questName = "naboo_rebel_tier4_2_a",
	questType = "space_battle",

	questZone = "space_yavin4",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "assassinate_naboo_rebel_tier4_2",
	parentQuestType = "assassinate",
	parentQuestName = "naboo_rebel_tier4_2",

	battlePoint = {patrolPointName = "naboo_rebel_tier4_2_a_battle_point", x = 2234, z = 4412, y = -2915, forward = {x = 0.742974, z = 0.623137, y = -0.244313}},

	damageMultiplier = 7,
	allyArrivalDelay = 30,
	enemyArrivalDelay = 45,
	allyOriginDist = -850,
	enemyOriginDist = 850,
	allyArrivalDist = -150,
	enemyArrivalDist = 200,

	allyForce = {"reb_xwing_tier4", "reb_xwing_tier4", "reb_xwing_tier4", "reb_xwing_tier4"},

	enemyForce = {"imp_tie_oppressor_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
}

registerScreenPlay("space_battle_naboo_rebel_tier4_2_a", true)

destroy_surpriseattack_naboo_rebel_tier4_2_b = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_rebel_tier4_2_b",

	questName = "naboo_rebel_tier4_2_b",
	questType = "destroy_surpriseattack",

	questZone = "space_yavin4",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "naboo_rebel_tier4_2_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 10,

	parentQuest = "assassinate_naboo_rebel_tier4_2",
	parentQuestType = "assassinate",
	parentQuestName = "naboo_rebel_tier4_2",

	surpriseAttackShips = {
		zone = "space_yavin4",
		spawns = {{count = 9, shipName = "tieinterceptor_inquisitor_guard"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_rebel_tier4_2_b", true)

assassinate_naboo_rebel_tier4_2_c = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_rebel_tier4_2_c",

	questName = "naboo_rebel_tier4_2_c",
	questType = "assassinate",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "destroy_surpriseattack_naboo_rebel_tier4_2_b",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "naboo_rebel_tier4_2_b",

	arrivalDelay = 10,
	failTimer = 20,
	mustDestroyEscort = false,

	assassinateSpawns = {
		target = "tieaggressor_uvqolo",
		escorts = {"imp_tie_advanced_tier4", "imp_tie_advanced_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_rebel_tier4_2_c_assassin_1", x = 5935, z = -4229, y = 6447},
		{patrolPointName = "naboo_rebel_tier4_2_c_assassin_2", x = 4649, z = -3485, y = 5120},
		{patrolPointName = "naboo_rebel_tier4_2_c_assassin_3", x = 3833, z = -3015, y = 4226},
		{patrolPointName = "naboo_rebel_tier4_2_c_assassin_4", x = 1810, z = -1822, y = 2258},
		{patrolPointName = "naboo_rebel_tier4_2_c_assassin_5", x = 834, z = -1249, y = 1313},
	},
}

registerScreenPlay("assassinate_naboo_rebel_tier4_2_c", true)

-- Mission 3: Rescue > Assassinate (won) or Delivery (no pickup) (lost)
rescue_naboo_rebel_tier4_3 = SpaceRescueScreenplay:new {
	className = "rescue_naboo_rebel_tier4_3",

	questName = "naboo_rebel_tier4_3",
	questType = "rescue",

	questZone = "space_dathomir",

	creditReward = 10000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/booster/bst_mission_reward_rebel_qualdex_halcyon.iff"},
	},

	sideQuest = true,
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL,
	sideQuestType = "assassinate",
	sideQuestName = "naboo_rebel_tier4_3_a",
	sideFailQuestType = "delivery_no_pickup",
	sideFailQuestName = "naboo_rebel_tier4_3_b",

	sideQuestDelay = 5,

	recoveryPath = {
		{patrolPointName = "naboo_rebel_tier4_3_rescue_1", x = -3747, z = 6334, y = 4875},
		{patrolPointName = "naboo_rebel_tier4_3_rescue_2", x = -2601, z = 4856, y = 4692},
		{patrolPointName = "naboo_rebel_tier4_3_rescue_3", x = -2093, z = 4201, y = 4610},
		{patrolPointName = "naboo_rebel_tier4_3_rescue_4", x = -636, z = 2507, y = 4629},
	},

	targetShipType = "tie_vortex_spy",
	targetArrivalDelay = 5,

	attackShipLists = {
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "tieaggressor_inquisitor", "imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4"},
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4"},
		{"imp_tie_advanced_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
	},

	attackPeriod = 45,
	attackListType = SpaceRescueScreenplay.ATTACK_LIST_TYPES.RANDOM,
	numResponses = 5,
}

registerScreenPlay("rescue_naboo_rebel_tier4_3", true)

assassinate_naboo_rebel_tier4_3_a = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_rebel_tier4_3_a",

	questName = "naboo_rebel_tier4_3_a",
	questType = "assassinate",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "rescue_naboo_rebel_tier4_3",
	parentQuestType = "rescue",
	parentQuestName = "naboo_rebel_tier4_3",

	arrivalDelay = 10,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "tiedecimator_inquisitor",
		escorts = {"imp_tie_advanced_tier4", "imp_tie_advanced_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_rebel_tier4_3_a_assassin_1", x = 1567, z = -1644, y = 1303},
		{patrolPointName = "naboo_rebel_tier4_3_a_assassin_2", x = 870, z = -374, y = 2393},
		{patrolPointName = "naboo_rebel_tier4_3_a_assassin_3", x = 506, z = 287, y = 2962},
		{patrolPointName = "naboo_rebel_tier4_3_a_assassin_4", x = 130, z = 975, y = 3552},
		{patrolPointName = "naboo_rebel_tier4_3_a_assassin_5", x = -433, z = 2277, y = 4639},
	},
}

registerScreenPlay("assassinate_naboo_rebel_tier4_3_a", true)

delivery_no_pickup_naboo_rebel_tier4_3_b = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_naboo_rebel_tier4_3_b",

	questName = "naboo_rebel_tier4_3_b",
	questType = "delivery_no_pickup",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "rescue_naboo_rebel_tier4_3",
	parentQuestType = "rescue",
	parentQuestName = "naboo_rebel_tier4_3",

	deliveryShip = "rebel_smuggler_tier3",

	deliveryPoint = {patrolPointName = "naboo_rebel_tier4_3_b_delivery", x = -1832, z = -709, y = -4430},

	attackShipLists = {
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "tieaggressor_inquisitor_tier4", "imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4"},
		{"imp_tie_advanced_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_advanced_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
	},

	attackPeriod = 60,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM,
}

registerScreenPlay("delivery_no_pickup_naboo_rebel_tier4_3_b", true)

-- Mission 4: Space battle > Space battle (won) or Survival (lost)
space_battle_naboo_rebel_tier4_4 = SpaceBattleScreenplay:new {
	className = "space_battle_naboo_rebel_tier4_4",

	questName = "naboo_rebel_tier4_4",
	questType = "space_battle",

	questZone = "space_dathomir",

	creditReward = 10000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon/wpn_mission_reward_rebel_incom_tricannon.iff"},
	},

	sideQuest = true,
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL,
	sideQuestType = "space_battle",
	sideQuestName = "naboo_rebel_tier4_4_a",
	sideFailQuestType = "survival",
	sideFailQuestName = "naboo_rebel_tier4_4_b",

	sideQuestDelay = 5,

	battlePoint = {patrolPointName = "naboo_rebel_tier4_4_battle_point", x = 6902, z = 3546, y = -3489, forward = {x = 0.828605, z = -0.453660, y = -0.328033}},

	damageMultiplier = 7,
	allyArrivalDelay = 150,
	enemyArrivalDelay = 120,
	allyOriginDist = 800,
	enemyOriginDist = -800,
	allyArrivalDist = 150,
	enemyArrivalDist = -200,

	allyForce = {"reb_awing_tier4", "reb_awing_tier4", "reb_xwing_tier4", "reb_xwing_tier4", "reb_xwing_tier4"},

	enemyForce = {"tiedecimator_inquisitor", "tieinterceptor_inquisitor_guard", "tieinterceptor_inquisitor_guard", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_aggressor_tier4"},
}

registerScreenPlay("space_battle_naboo_rebel_tier4_4", true)

space_battle_naboo_rebel_tier4_4_a = SpaceBattleScreenplay:new {
	className = "space_battle_naboo_rebel_tier4_4_a",

	questName = "naboo_rebel_tier4_4_a",
	questType = "space_battle",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "space_battle_naboo_rebel_tier4_4",
	parentQuestType = "space_battle",
	parentQuestName = "naboo_rebel_tier4_4",

	battlePoint = {patrolPointName = "naboo_rebel_tier4_4_a_battle_point", x = 5171, z = 2634, y = -6196, forward = {x = -0.212466, z = -0.977154, y = 0.005260}},

	damageMultiplier = 7,
	allyArrivalDelay = 30,
	enemyArrivalDelay = 45,
	allyOriginDist = 650,
	enemyOriginDist = -750,
	allyArrivalDist = 100,
	enemyArrivalDist = -50,

	allyForce = {"reb_bwing_tier4", "reb_bwing_tier4", "reb_bwing_tier4", "reb_bwing_tier4"},

	enemyForce = {"imp_tie_advanced_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "tieaggressor_inquisitor_tier4", "tieinterceptor_inquisitor_guard", "tieinterceptor_inquisitor_guard", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
}

registerScreenPlay("space_battle_naboo_rebel_tier4_4_a", true)

survival_naboo_rebel_tier4_4_b = SpaceSurvivalScreenplay:new {
	className = "survival_naboo_rebel_tier4_4_b",

	questName = "naboo_rebel_tier4_4_b",
	questType = "survival",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "space_battle_naboo_rebel_tier4_4",
	parentQuestType = "space_battle",
	parentQuestName = "naboo_rebel_tier4_4",

	-- Screenplay Specific Variables
	transmissionPoint = {patrolPointName = "naboo_rebel_tier4_4_b_survival", x = 2743, z = 6727, y = -6701},
	totalTransmissionTime = 240,
	timesToUpdateProgress = 4,
	transmissionStartDelay = 5,
	delayToFirstAttack = 5,

	attackShipLists = {
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_oppressor_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4"},
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "tieaggressor_inquisitor", "tieinterceptor_inquisitor_guard", "tieinterceptor_inquisitor_guard", "imp_tie_fighter_tier4"},
		{"imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
	},

	attackPeriod = 45,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.RANDOM,
}

registerScreenPlay("survival_naboo_rebel_tier4_4_b", true)

-- Duties
destroy_duty_naboo_rebel_tier4_1 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_naboo_rebel_tier4_1",

	questName = "naboo_rebel_tier4_1",
	questType = "destroy_duty",

	questZone = "space_dantooine",

	creditReward = 300,

	sideQuest = false,
	sideQuestType = "",

	totalLevels = 5,
	totalRounds = 3,
	totalWaves = 4,

	bossShip = "tieadvanced_inquisitor_tier4",
	shipTypes = {
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_interceptor_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_bomber_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
	},
}

registerScreenPlay("destroy_duty_naboo_rebel_tier4_1", true)

escort_duty_naboo_rebel_tier4_1 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_naboo_rebel_tier4_1",

	questName = "naboo_rebel_tier4_1",
	questType = "escort_duty",

	questZone = "space_yavin4",

	creditReward = 5000,
	creditKillBonus = 300,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"reb_ykl37r_tier4", "reb_transport_tier4", "reb_freightermedium_tier4", "reb_freighterheavy_tier4", "reb_freighterlight_tier4"},

	escortPoints = {
		{patrolPointName = "naboo_rebel_tier4_1_escort_duty_1", x = 2096, z = 3236, y = -6065, zoneName = "space_yavin4", escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_escort_duty_2", x = 2494, z = 3767, y = -5614, zoneName = "space_yavin4", escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_escort_duty_3", x = 3491, z = 4797, y = -4904, zoneName = "space_yavin4", escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_escort_duty_4", x = 4619, z = 5351, y = -4806, zoneName = "space_yavin4", escortNumber = 4, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_escort_duty_5", x = 5626, z = 6460, y = -4707, zoneName = "space_yavin4", escortNumber = 5, radius = 250},
	},

	attackDelay = 50,

	attackShips = {
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_interceptor_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_bomber_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_naboo_rebel_tier4_1", true)

recovery_duty_naboo_rebel_tier4_1 = SpaceDutyRecoveryScreenplay:new {
	className = "recovery_duty_naboo_rebel_tier4_1",

	questName = "naboo_rebel_tier4_1",
	questType = "recovery_duty",

	questZone = "space_endor",

	creditReward = 5000,
	creditKillBonus = 300,

	sideQuest = false,
	sideQuestType = "",

	numResponses = 5,

	arrivalDelay = 10,
	recoveryDelay = 30,

	recoverShips = {"lambdashuttle_inquisition_data_vessel"},
	recoveryConversationMobile = "object/mobile/shared_ig_assassin_droid.iff",

	escortShips = {"imp_tie_advanced_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},

	preRecoveryPoints = {
		{patrolPointName = "naboo_rebel_tier4_1_recovery_1", x = -242, z = 237, y = -2454, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_recovery_2", x = -222, z = 392, y = -3760, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_recovery_3", x = -160, z = 535, y = -5022, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_recovery_4", x = -112, z = 608, y = -5705, escortNumber = 4, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_recovery_5", x = -1362, z = 677, y = -6811, escortNumber = 5, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_recovery_6", x = -3357, z = 757, y = -7033, escortNumber = 6, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "naboo_rebel_tier4_1_recovery_7", x = -813, z = 568, y = -5794, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_recovery_8", x = -1677, z = 471, y = -4636, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_recovery_9", x = -2068, z = 365, y = -3800, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_1_recovery_10", x = -3517, z = 274, y = -2248, escortNumber = 4, radius = 250},
	},

	attackDelay = 45,

	attackShips = {
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4"},
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_bomber_tier4"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_duty_naboo_rebel_tier4_1", true)

rescue_duty_naboo_rebel_tier4_1 = SpaceDutyRescueScreenplay:new {
	className = "rescue_duty_naboo_rebel_tier4_1",

	questName = "naboo_rebel_tier4_1",
	questType = "rescue_duty",

	questZone = "space_dantooine",

	creditReward = 5000,
	creditKillBonus = 300,

	sideQuest = false,
	sideQuestType = "",

	recoveryPath = {
		{patrolPointName = "naboo_rebel_tier4_1_rescue_duty_1", x = 2685, z = 6536, y = -6727},
		{patrolPointName = "naboo_rebel_tier4_1_rescue_duty_2", x = 2490, z = 5986, y = -6356},
		{patrolPointName = "naboo_rebel_tier4_1_rescue_duty_3", x = 2160, z = 5246, y = -5746},
		{patrolPointName = "naboo_rebel_tier4_1_rescue_duty_4", x = 1936, z = 4693, y = -5265},
		{patrolPointName = "naboo_rebel_tier4_1_rescue_duty_5", x = 1513, z = 3657, y = -4302},
		{patrolPointName = "naboo_rebel_tier3_rescue_3", x = -996, z = -2105, y = 4791},
	},

	targetShipTypes = {"freighterheavy_tier4", "freighterlight_tier4", "freightermedium_tier4"},
	targetArrivalDelay = 10,

	attackShipLists = {
		{"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
		{"imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4"},
		{"imp_tie_bomber_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"},
	},

	attackPeriod = 50,
	attackListType = 1, -- random
	numResponses = 5,
}

registerScreenPlay("rescue_duty_naboo_rebel_tier4_1", true)

--[[

	VortexSquadronScreenplay

]]

VortexSquadronScreenplay = ScreenPlay:new {
	screenplayName = "VortexSquadronScreenplay",

	-- Tier 1 (V3-FX)
	QUEST_STRING_1 = {type = "patrol", name = "naboo_rebel_1"},
	QUEST_STRING_1_SIDE = {type = "destroy_surpriseattack", name = "naboo_rebel_1"},
	QUEST_STRING_2 = {type = "destroy", name = "naboo_rebel_2"},
	QUEST_STRING_3 = {type = "patrol", name = "naboo_rebel_3"},
	QUEST_STRING_3_SIDE = {type = "escort", name = "naboo_rebel_3"},
	QUEST_STRING_4 = {type = "assassinate", name = "naboo_rebel_4"},
	QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "naboo_rebel_6"},
	QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "naboo_rebel_7"},

	-- Tier 2 (Vrovel)
	TIER2_QUEST_STRING_1 = {type = "escort", name = "vortex_mission_1"},
	TIER2_QUEST_STRING_1_SIDE1 = {type = "inspect", name = "vortex_mission_1"},
	TIER2_QUEST_STRING_1_SIDE2 = {type = "destroy_surpriseattack", name = "vortex_mission_1"},
	TIER2_QUEST_STRING_2 = {type = "escort", name = "vortex_mission_2"},
	TIER2_QUEST_STRING_3 = {type = "recovery", name = "vortex_mission_3"},
	TIER2_QUEST_STRING_4 = {type = "inspect", name = "vortex_mission_4"},
	TIER2_QUEST_STRING_DUTY_1 = {type = "escort_duty", name = "vortex_mission_5"},
	TIER2_QUEST_STRING_DUTY_2 = {type = "recovery_duty", name = "vortex_mission_7"},
	TIER2_QUEST_STRING_DUTY_3 = {type = "destroy_duty", name = "vortex_mission_6"},

	-- Tier 3 (Ezkiel)
	TIER3_QUEST_STRING_1 = {type = "assassinate", name = "naboo_rebel_tier3_1"},
	TIER3_QUEST_STRING_1_SIDE1 = {type = "escort", name = "naboo_rebel_tier3_1_a"},
	TIER3_QUEST_STRING_1_SIDE2 = {type = "survival", name = "naboo_rebel_tier3_1_b"},
	TIER3_QUEST_STRING_1_SIDE3 = {type = "inspect", name = "naboo_rebel_tier3_1_c"},
	TIER3_QUEST_STRING_1_SIDE4 = {type = "delivery_no_pickup", name = "naboo_rebel_tier3_1_d"},
	TIER3_QUEST_STRING_2 = {type = "space_battle", name = "naboo_rebel_tier3_2"},
	TIER3_QUEST_STRING_2_SIDE1 = {type = "rescue", name = "naboo_rebel_tier3_2_a"},
	TIER3_QUEST_STRING_2_SIDE2 = {type = "patrol", name = "naboo_rebel_tier3_2_b"},
	TIER3_QUEST_STRING_2_SIDE3 = {type = "destroy_surpriseattack", name = "naboo_rebel_tier3_2_c"},
	TIER3_QUEST_STRING_2_SIDE4 = {type = "inspect", name = "naboo_rebel_tier3_2_d"},
	TIER3_QUEST_STRING_3 = {type = "patrol", name = "naboo_rebel_tier3_3"},
	TIER3_QUEST_STRING_3_SIDE1 = {type = "destroy_surpriseattack", name = "naboo_rebel_tier3_3_a"},
	TIER3_QUEST_STRING_3_SIDE2 = {type = "survival", name = "naboo_rebel_tier3_3_b"},
	TIER3_QUEST_STRING_3_SIDE3 = {type = "patrol", name = "naboo_rebel_tier3_3_c"},
	TIER3_QUEST_STRING_3_SIDE4 = {type = "assassinate", name = "naboo_rebel_tier3_3_d"},
	TIER3_QUEST_STRING_4 = {type = "space_battle", name = "naboo_rebel_tier3_4"},
	TIER3_QUEST_STRING_4_SIDE1 = {type = "patrol", name = "naboo_rebel_tier3_4_a"},
	TIER3_QUEST_STRING_4_SIDE2 = {type = "survival", name = "naboo_rebel_tier3_4_b"},
	TIER3_QUEST_STRING_4_SIDE3 = {type = "recovery", name = "naboo_rebel_tier3_4_c"},
	TIER3_QUEST_STRING_4_SIDE4 = {type = "delivery", name = "naboo_rebel_tier3_4_d"},

	-- Tier 4 (Extok Evin); SIDE1 = the success split, SIDE2 = the failure split, SIDE3 = the failure split's own split (mission 2)
	TIER4_QUEST_STRING_1 = {type = "survival", name = "naboo_rebel_tier4_1"},
	TIER4_QUEST_STRING_1_SIDE1 = {type = "assassinate", name = "naboo_rebel_tier4_1_a"},
	TIER4_QUEST_STRING_1_SIDE2 = {type = "escort", name = "naboo_rebel_tier4_1_b"},
	TIER4_QUEST_STRING_2 = {type = "assassinate", name = "naboo_rebel_tier4_2"},
	TIER4_QUEST_STRING_2_SIDE1 = {type = "space_battle", name = "naboo_rebel_tier4_2_a"},
	TIER4_QUEST_STRING_2_SIDE2 = {type = "destroy_surpriseattack", name = "naboo_rebel_tier4_2_b"},
	TIER4_QUEST_STRING_2_SIDE3 = {type = "assassinate", name = "naboo_rebel_tier4_2_c"},
	TIER4_QUEST_STRING_3 = {type = "rescue", name = "naboo_rebel_tier4_3"},
	TIER4_QUEST_STRING_3_SIDE1 = {type = "assassinate", name = "naboo_rebel_tier4_3_a"},
	TIER4_QUEST_STRING_3_SIDE2 = {type = "delivery_no_pickup", name = "naboo_rebel_tier4_3_b"},
	TIER4_QUEST_STRING_4 = {type = "space_battle", name = "naboo_rebel_tier4_4"},
	TIER4_QUEST_STRING_4_SIDE1 = {type = "space_battle", name = "naboo_rebel_tier4_4_a"},
	TIER4_QUEST_STRING_4_SIDE2 = {type = "survival", name = "naboo_rebel_tier4_4_b"},
	TIER4_QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "naboo_rebel_tier4_1"},
	TIER4_QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "naboo_rebel_tier4_1"},
	TIER4_QUEST_STRING_DUTY_3 = {type = "recovery_duty", name = "naboo_rebel_tier4_1"},
	TIER4_QUEST_STRING_DUTY_4 = {type = "rescue_duty", name = "naboo_rebel_tier4_1"},

	-- Set by Evin's first-meeting reply (SWG setMetMe / space flag metTier4, J4:418-421; vortex-tier4-extok-evin Part B); cleared by resetEvinQuests
	TIER4_MET_KEY = "VortexSquadronScreenplay:metTier4",

	-- SWG's vortexPilot space flag ("1" from V3-FX; tier 2 moves it to "2" and "3")
	VORTEX_PILOT_KEY = "VortexSquadronScreenplay:vortexPilot",

	-- Kiizete (naboo_rebel_tier1_kiizete.java): SWG utils.setScriptVar flags, kept in server memory and cleared at logout (feature vortex-tier1-kiizete)
	KIIZETE_IMP_ASKING_KEY = "VortexSquadronScreenplay:kiizeteImpIsAsking",
	KIIZETE_Q1_DISCUSSED_KEY = "VortexSquadronScreenplay:kiizeteQ1Discussed",
}

registerScreenPlay("VortexSquadronScreenplay", false)

function VortexSquadronScreenplay:start()
end

-- Clears V3-FX's quests, journal entries and keys (surrender)
function VortexSquadronScreenplay:resetV3fxQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	local tables = {
		patrol_naboo_rebel_1, destroy_surpriseattack_naboo_rebel_1, destroy_naboo_rebel_2, patrol_naboo_rebel_3,
		escort_naboo_rebel_3, assassinate_naboo_rebel_4, destroy_duty_naboo_rebel_6, escort_duty_naboo_rebel_7
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.QUEST_STRING_1, self.QUEST_STRING_1_SIDE, self.QUEST_STRING_2, self.QUEST_STRING_3, self.QUEST_STRING_3_SIDE,
		self.QUEST_STRING_4, self.QUEST_STRING_DUTY_1, self.QUEST_STRING_DUTY_2
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	for _, questString in ipairs({self.QUEST_STRING_1, self.QUEST_STRING_2, self.QUEST_STRING_3, self.QUEST_STRING_4}) do
		removeQuestStatus(playerID .. questString.name .. ":attempted")
		removeQuestStatus(playerID .. questString.name .. ":reward")
	end

	removeQuestStatus(playerID .. self.VORTEX_PILOT_KEY)
end

-- Clears Brother Vrovel's quests, journal entries and keys (surrender)
function VortexSquadronScreenplay:resetVrovelQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	local tables = {
		escort_vortex_mission_1, inspect_vortex_mission_1, destroy_surpriseattack_vortex_mission_1, escort_vortex_mission_2,
		recovery_vortex_mission_3, inspect_vortex_mission_4, escort_duty_vortex_mission_5, destroy_duty_vortex_mission_6,
		recovery_duty_vortex_mission_7
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.TIER2_QUEST_STRING_1, self.TIER2_QUEST_STRING_1_SIDE1, self.TIER2_QUEST_STRING_1_SIDE2, self.TIER2_QUEST_STRING_2,
		self.TIER2_QUEST_STRING_3, self.TIER2_QUEST_STRING_4, self.TIER2_QUEST_STRING_DUTY_1, self.TIER2_QUEST_STRING_DUTY_2,
		self.TIER2_QUEST_STRING_DUTY_3
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	for _, questString in ipairs({self.TIER2_QUEST_STRING_1, self.TIER2_QUEST_STRING_2, self.TIER2_QUEST_STRING_3, self.TIER2_QUEST_STRING_4}) do
		removeQuestStatus(playerID .. questString.name .. ":attempted")
		removeQuestStatus(playerID .. questString.name .. ":reward")
	end
end

-- Clears Brother Ezkiel's quests, journal entries and keys (surrender)
function VortexSquadronScreenplay:resetEzkielQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	local tables = {
		assassinate_naboo_rebel_tier3_1, escort_naboo_rebel_tier3_1_a,
		survival_naboo_rebel_tier3_1_b, inspect_naboo_rebel_tier3_1_c,
		delivery_no_pickup_naboo_rebel_tier3_1_d, space_battle_naboo_rebel_tier3_2,
		rescue_naboo_rebel_tier3_2_a, patrol_naboo_rebel_tier3_2_b,
		destroy_surpriseattack_naboo_rebel_tier3_2_c, inspect_naboo_rebel_tier3_2_d,
		patrol_naboo_rebel_tier3_3, destroy_surpriseattack_naboo_rebel_tier3_3_a,
		survival_naboo_rebel_tier3_3_b, patrol_naboo_rebel_tier3_3_c,
		assassinate_naboo_rebel_tier3_3_d, space_battle_naboo_rebel_tier3_4,
		patrol_naboo_rebel_tier3_4_a, survival_naboo_rebel_tier3_4_b,
		recovery_naboo_rebel_tier3_4_c, delivery_naboo_rebel_tier3_4_d
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.TIER3_QUEST_STRING_1, self.TIER3_QUEST_STRING_1_SIDE1, self.TIER3_QUEST_STRING_1_SIDE2,
		self.TIER3_QUEST_STRING_1_SIDE3, self.TIER3_QUEST_STRING_1_SIDE4, self.TIER3_QUEST_STRING_2,
		self.TIER3_QUEST_STRING_2_SIDE1, self.TIER3_QUEST_STRING_2_SIDE2, self.TIER3_QUEST_STRING_2_SIDE3,
		self.TIER3_QUEST_STRING_2_SIDE4, self.TIER3_QUEST_STRING_3, self.TIER3_QUEST_STRING_3_SIDE1,
		self.TIER3_QUEST_STRING_3_SIDE2, self.TIER3_QUEST_STRING_3_SIDE3, self.TIER3_QUEST_STRING_3_SIDE4,
		self.TIER3_QUEST_STRING_4, self.TIER3_QUEST_STRING_4_SIDE1, self.TIER3_QUEST_STRING_4_SIDE2,
		self.TIER3_QUEST_STRING_4_SIDE3, self.TIER3_QUEST_STRING_4_SIDE4
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	for _, questString in ipairs({self.TIER3_QUEST_STRING_1, self.TIER3_QUEST_STRING_2, self.TIER3_QUEST_STRING_3, self.TIER3_QUEST_STRING_4}) do
		removeQuestStatus(playerID .. questString.name .. ":attempted")
		removeQuestStatus(playerID .. questString.name .. ":reward")
	end
end

-- Clears Brother Extok Evin's quests, journal entries and keys (surrender)
function VortexSquadronScreenplay:resetEvinQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	local tables = {
		survival_naboo_rebel_tier4_1, assassinate_naboo_rebel_tier4_1_a,
		escort_naboo_rebel_tier4_1_b, assassinate_naboo_rebel_tier4_2,
		space_battle_naboo_rebel_tier4_2_a, destroy_surpriseattack_naboo_rebel_tier4_2_b,
		assassinate_naboo_rebel_tier4_2_c, rescue_naboo_rebel_tier4_3,
		assassinate_naboo_rebel_tier4_3_a, delivery_no_pickup_naboo_rebel_tier4_3_b,
		space_battle_naboo_rebel_tier4_4, space_battle_naboo_rebel_tier4_4_a,
		survival_naboo_rebel_tier4_4_b, destroy_duty_naboo_rebel_tier4_1,
		escort_duty_naboo_rebel_tier4_1, recovery_duty_naboo_rebel_tier4_1,
		rescue_duty_naboo_rebel_tier4_1
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.TIER4_QUEST_STRING_1, self.TIER4_QUEST_STRING_1_SIDE1, self.TIER4_QUEST_STRING_1_SIDE2,
		self.TIER4_QUEST_STRING_2, self.TIER4_QUEST_STRING_2_SIDE1, self.TIER4_QUEST_STRING_2_SIDE2,
		self.TIER4_QUEST_STRING_2_SIDE3, self.TIER4_QUEST_STRING_3, self.TIER4_QUEST_STRING_3_SIDE1,
		self.TIER4_QUEST_STRING_3_SIDE2, self.TIER4_QUEST_STRING_4, self.TIER4_QUEST_STRING_4_SIDE1,
		self.TIER4_QUEST_STRING_4_SIDE2, self.TIER4_QUEST_STRING_DUTY_1, self.TIER4_QUEST_STRING_DUTY_2,
		self.TIER4_QUEST_STRING_DUTY_3, self.TIER4_QUEST_STRING_DUTY_4
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	for _, questString in ipairs({self.TIER4_QUEST_STRING_1, self.TIER4_QUEST_STRING_2, self.TIER4_QUEST_STRING_3, self.TIER4_QUEST_STRING_4}) do
		removeQuestStatus(playerID .. questString.name .. ":attempted")
		removeQuestStatus(playerID .. questString.name .. ":reward")
	end

	removeQuestStatus(playerID .. self.TIER4_MET_KEY)
end

-- Kiizete's session flags (SWG scriptVars imp_isasking and q1_discussed): server memory, dropped at logout (feature vortex-tier1-kiizete)
function VortexSquadronScreenplay:hasKiizeteFlag(pPlayer, key)
	if (pPlayer == nil) then
		return false
	end

	return readData(CreatureObject(pPlayer):getObjectID() .. key) == 1
end

function VortexSquadronScreenplay:setKiizeteFlag(pPlayer, key)
	if (pPlayer == nil) then
		return
	end

	writeData(CreatureObject(pPlayer):getObjectID() .. key, 1)

	if (not hasObserver(LOGGEDOUT, "VortexSquadronScreenplay", "onKiizeteLoggedOut", pPlayer)) then
		createObserver(LOGGEDOUT, "VortexSquadronScreenplay", "onKiizeteLoggedOut", pPlayer)
	end
end

function VortexSquadronScreenplay:onKiizeteLoggedOut(pPlayer)
	if (pPlayer == nil) then
		return 1
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	deleteData(playerID .. self.KIIZETE_IMP_ASKING_KEY)
	deleteData(playerID .. self.KIIZETE_Q1_DISCUSSED_KEY)

	return 1
end
