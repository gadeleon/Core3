local SpaceHelpers = require("utils.space_helpers")

--[[

	Vortex Squadron Quests

]]

--[[
	Tier 1 -- V3-FX (Naboo, Moenia)
	Trainer: V3-FX (conversation v3fxConvoHandler), Moenia gazebo (screenplays/cities/naboo_moenia.lua:108). 8 quest tables for 6 SWG-Source names: naboo_rebel_1..4, 6, 7 (patrol, destroy_surpriseattack, destroy, escort, assassinate, destroy_duty, escort_duty), from datatables/spacequest and naboo_rebel_trainer_1.java; feature vortex-tier1-v3-fx
	Tier 2 (Brother Vrovel) is below; tiers 3-4 (Brother Ezkiel, Brother Extok Evin) are not ported yet
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
