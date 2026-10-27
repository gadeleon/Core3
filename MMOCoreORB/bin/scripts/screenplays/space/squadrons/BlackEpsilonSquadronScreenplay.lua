local SpaceHelpers = require("utils.space_helpers")

--[[

	Black Epsilon Squadron Quests

]]

--[[
	Tier 1 -- Hakassha Sireen (Corellia)
	Ported from SWG-Source corellia_imperial_1..7 (patrol, destroy_surpriseattack, destroy, escort, assassinate, destroy_duty, escort_duty); feature black-epsilon-tier1-hakassha
]]

-- Mission 1: Patrol with surprise attack
patrol_corellia_imperial_1 = SpacePatrolScreenplay:new {
	className = "patrol_corellia_imperial_1",

	questName = "corellia_imperial_1",
	questType = "patrol",

	questZone = "space_corellia",

	creditReward = 100,

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "corellia_imperial_1",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 10,

	patrolPoints = {
		{patrolPointName = "imperial_1", x = -5118, z = -4117, y = -3503, patrolNumber = 1, radius = 150},
		{patrolPointName = "imperial_2", x = -4092, z = -3236, y = -2990, patrolNumber = 2, radius = 150},
		{patrolPointName = "imperial_3", x = -2643, z = -1615, y = -4452, patrolNumber = 3, radius = 150},
	},
}

registerScreenPlay("patrol_corellia_imperial_1", true)

destroy_surpriseattack_corellia_imperial_1 = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_corellia_imperial_1",

	questName = "corellia_imperial_1",
	questType = "destroy_surpriseattack",

	questZone = "space_corellia",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_corellia_imperial_1",
	parentQuestType = "patrol",
	parentQuestName = "corellia_imperial_1",

	surpriseAttackShips = {
		zone = "space_corellia",
		spawns = {{count = 2, shipName = "reb_xwing_tier1"}},
	},
}

registerScreenPlay("destroy_surpriseattack_corellia_imperial_1", true)

-- Mission 2: Destroy
destroy_corellia_imperial_2 = SpaceDestroyScreenplay:new {
	className = "destroy_corellia_imperial_2",

	questName = "corellia_imperial_2",
	questType = "destroy",

	questZone = "space_corellia",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	killsRequired = 4,

	shipLocations = {
		{spawnName = "rebel_corellia_deep_two_spawner", x = -6118, z = -3233, y = -2733},
		{spawnName = "rebel_fighter_four_spawner", x = 3475, z = -7014, y = -6208},
		{spawnName = "rebel_fighter_two_spawner", x = -3936, z = 2704, y = 2172},
		{spawnName = "rebel_spacestation_spawner", x = -959, z = -5, y = -1328},
	},

	shipTypes = {
		"reb_xwing_cadet_tier1",
	},
}

registerScreenPlay("destroy_corellia_imperial_2", true)

-- Mission 3: Escort
escort_corellia_imperial_3 = SpaceEscortScreenplay:new {
	className = "escort_corellia_imperial_3",

	questName = "corellia_imperial_3",
	questType = "escort",

	questZone = "space_corellia",

	creditReward = 500,
	itemReward = {
		{species = {SPECIES_WOOKIEE}, item = "object/tangible/wearables/bandolier/double_bandolier.iff"},
		{species = {SPECIES_ITHORIAN}, item = "object/tangible/wearables/bandolier/ith_double_bandolier.iff"},
		{species = {-1}, item = "object/tangible/wearables/bodysuit/bodysuit_tie_fighter.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"imp_freightermedium_explosives_tier1"},

	escortPoints = {
		{patrolPointName = "corellia_imperial_escort_1", zoneName = "space_corellia", x = -6694, z = -2683, y = -1033, escortNumber = 1, radius = 250},
		{patrolPointName = "corellia_imperial_escort_2", zoneName = "space_corellia", x = -4477, z = -2449, y = -2489, escortNumber = 2, radius = 250},
		{patrolPointName = "corellia_imperial_escort_3", zoneName = "space_corellia", x = -3439, z = -2699, y = -4986, escortNumber = 3, radius = 250},
		{patrolPointName = "corellia_imperial_escort_4", zoneName = "space_corellia", x = -6967, z = -2534, y = -7084, escortNumber = 4, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"reb_corsec_fighter_tier1", "reb_corsec_fighter_tier1"},
		{"reb_corsec_fighter_tier1"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_corellia_imperial_3", true)

-- Mission 4: Assassinate
assassinate_corellia_imperial_4 = SpaceAssassinateScreenplay:new {
	className = "assassinate_corellia_imperial_4",

	questType = "assassinate",
	questName = "corellia_imperial_4",

	questZone = "space_corellia",

	creditReward = 1000,
	itemReward = {
		{species = {-1}, item = "object/tangible/wearables/helmet/helmet_tie_fighter.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	arrivalDelay = 15,
	failTimer = 20,
	mustDestroyEscort = false,

	assassinateSpawns = {
		target = "reb_bwing_prototype_tier2",
		escorts = {"reb_xwing_tier1"},
	},

	targetPatrols = {
		{patrolPointName = "corellia_imperial_tier2_assassinate_5", x = 3102, z = 2928, y = -6841},
		{patrolPointName = "corellia_imperial_tier2_assassinate_4", x = 15, z = 877, y = -7202},
		{patrolPointName = "corellia_imperial_tier2_assassinate_3", x = -2854, z = -236, y = -6778},
		{patrolPointName = "corellia_imperial_tier2_assassinate_2", x = -5275, z = -1116, y = -6269},
	},
}

registerScreenPlay("assassinate_corellia_imperial_4", true)

-- Hakassha Duty Missions
destroy_duty_corellia_imperial_6 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_corellia_imperial_6",

	questName = "corellia_imperial_6",
	questType = "destroy_duty",

	questZone = "space_corellia",

	creditReward = 100,

	sideQuest = false,
	sideQuestType = "",

	totalLevels = 5,
	totalRounds = 2,
	totalWaves = 3,

	bossShip = "reb_bwing_prototype_tier2",
	shipTypes = {
		{"reb_bwing_tier1"},
	},
}

registerScreenPlay("destroy_duty_corellia_imperial_6", true)

escort_duty_corellia_imperial_7 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_corellia_imperial_7",

	questName = "corellia_imperial_7",
	questType = "escort_duty",

	questZone = "space_corellia",

	creditReward = 1000,
	creditKillBonus = 100,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"imp_freighterheavy_tier1", "imp_freightermedium_tier1", "imp_freighterlight_tier1"},

	escortPoints = {
		{patrolPointName = "military_escort_1", zoneName = "space_corellia", x = 5287, z = 5844, y = 5700, escortNumber = 1, radius = 250},
		{patrolPointName = "military_escort_2", zoneName = "space_corellia", x = 2915, z = 3828, y = 2887, escortNumber = 2, radius = 250},
		{patrolPointName = "military_escort_3", zoneName = "space_corellia", x = 4405, z = 2619, y = -1971, escortNumber = 3, radius = 250},
		{patrolPointName = "military_escort_4", zoneName = "space_corellia", x = 4860, z = 407, y = -4843, escortNumber = 4, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"reb_xwing_tier1", "reb_ywing_tier1"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_corellia_imperial_7", true)

--[[
	Tier 2 -- Prisk Kith'Vys (Corellia)
	Ported from SWG-Source corellia_imperial_8..17 and corellia_tier2_final (recovery, assassinate, inspect, patrol, destroy_surpriseattack, survival, destroy_duty, escort_duty); feature black-epsilon-tier2-prisk
]]

-- Opening mission: Recovery
recovery_corellia_imperial_16 = SpaceRecoveryScreenplay:new {
	className = "recovery_corellia_imperial_16",

	questName = "corellia_imperial_16",
	questType = "recovery",

	questZone = "space_corellia",

	sideQuest = false,
	sideQuestType = "",

	arrivalDelay = 20,
	recoveryDelay = 30,

	recoverShip = "freighterheavy_black_epsilon_tier2",

	escortShips = {"hidden_daggers_enforcer_tier2", "hidden_daggers_enforcer_tier2"},

	preRecoveryPoints = {
		{patrolPointName = "corellia_imperial_patrol_1", x = -2137, z = -2099, y = -3565, escortNumber = 1, radius = 250},
		{patrolPointName = "corellia_imperial_patrol_2", x = -6321, z = -1417, y = -3345, escortNumber = 2, radius = 250},
		{patrolPointName = "corellia_imperial_patrol_3", x = -6662, z = -2384, y = -2625, escortNumber = 3, radius = 250},
		{patrolPointName = "corellia_imperial_patrol_4", x = -7252, z = -3694, y = -574, escortNumber = 4, radius = 250},
		{patrolPointName = "corellia_imperial_patrol_5", x = -4770, z = -5632, y = 148, escortNumber = 5, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "corellia_imperial_recovery_1", x = -6589, z = -1759, y = 116, escortNumber = 1, radius = 250},
		{patrolPointName = "corellia_imperial_recovery_2", x = -2975, z = -3650, y = -2734, escortNumber = 2, radius = 250},
		{patrolPointName = "corellia_imperial_recovery_3", x = 1359, z = -5188, y = -4383, escortNumber = 3, radius = 250},
		{patrolPointName = "corellia_imperial_recovery_4", x = 5853, z = -6408, y = -4885, escortNumber = 4, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"hidden_daggers_enforcer_tier2", "hidden_daggers_enforcer_tier2"},
		{"hidden_daggers_nebula_stalker_tier2", "hidden_daggers_nebula_stalker_tier2"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_corellia_imperial_16", true)

-- Mission 1 (starships): Assassinate
assassinate_corellia_imperial_12 = SpaceAssassinateScreenplay:new {
	className = "assassinate_corellia_imperial_12",

	questType = "assassinate",
	questName = "corellia_imperial_12",

	questZone = "space_corellia",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon/wpn_mission_reward_imperial_cygnus_starblaster.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	arrivalDelay = 30,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "rebel_diplomat_tier2",
		escorts = {"reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2"},
	},

	targetPatrols = {
		{patrolPointName = "corellia_imperial_tier2_assassinate_1", x = -6932, z = -1364, y = -644},
		{patrolPointName = "corellia_imperial_tier2_assassinate_2", x = -5275, z = -1116, y = -6269},
		{patrolPointName = "corellia_imperial_tier2_assassinate_3", x = -2854, z = -236, y = -6778},
		{patrolPointName = "corellia_imperial_tier2_assassinate_4", x = 15, z = 877, y = -7202},
		{patrolPointName = "corellia_imperial_tier2_assassinate_5", x = 3102, z = 2928, y = -6841},
	},
}

registerScreenPlay("assassinate_corellia_imperial_12", true)

-- Mission 2 (droid): Inspect
inspect_corellia_imperial_13 = SpaceInspectScreenplay:new {
	className = "inspect_corellia_imperial_13",

	questName = "corellia_imperial_13",
	questType = "inspect",

	questZone = "space_corellia",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/armor/arm_mission_reward_imperial_sfs_light_military.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	shipList = {"rebel_spysmuggler_tier2"},
	validSpawns = {
		{spawnName = "corellia_imperial_tier2_inspect_freighter", x = -2466, z = 1971, y = 6320},
	},
	giveSpawnWaypoint = 1,
	cargo = "personnel_dossier",
}

registerScreenPlay("inspect_corellia_imperial_13", true)

-- Mission 3 (weapons): Assassinate
assassinate_corellia_imperial_14 = SpaceAssassinateScreenplay:new {
	className = "assassinate_corellia_imperial_14",

	questType = "assassinate",
	questName = "corellia_imperial_14",

	questZone = "space_corellia",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/booster/bst_mission_reward_imperial_rss_ion_booster.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	arrivalDelay = 15,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "reb_bomber_leader_tier3",
		escorts = {"reb_ywing_tier2", "reb_ywing_tier2", "reb_ywing_tier2", "reb_ywing_tier2", "reb_ywing_tier2"},
	},

	targetPatrols = {
		{patrolPointName = "trade_escort_4", x = 895, z = 210, y = 695},
		{patrolPointName = "trade_escort_5", x = 3065, z = -1029, y = 2144},
		{patrolPointName = "trade_escort_6", x = 4333, z = -2700, y = 3283},
		{patrolPointName = "trade_escort_7", x = 5229, z = -3991, y = 4253},
	},
}

registerScreenPlay("assassinate_corellia_imperial_14", true)

-- Mission 4 (procedures): Patrol with surprise attack
patrol_corellia_imperial_15 = SpacePatrolScreenplay:new {
	className = "patrol_corellia_imperial_15",

	questName = "corellia_imperial_15",
	questType = "patrol",

	questZone = "space_corellia",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/shield_generator/shd_mission_reward_imperial_rendili_dual_projector.iff"},
	},

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "corellia_imperial_15_split",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 4,
	sideQuestDelay = 20,

	patrolPoints = {
		{patrolPointName = "imperial_nebula_patrol_1", x = -5200, z = 4000, y = 2112, patrolNumber = 1, radius = 150},
		{patrolPointName = "imperial_nebula_patrol_2", x = -3533, z = 2525, y = 3951, patrolNumber = 2, radius = 150},
		{patrolPointName = "imperial_nebula_patrol_3", x = -33, z = 3789, y = 2144, patrolNumber = 3, radius = 150},
		{patrolPointName = "imperial_nebula_patrol_4", x = 1324, z = 3496, y = 1564, patrolNumber = 4, radius = 150},
		{patrolPointName = "imperial_nebula_patrol_5", x = 2739, z = 3730, y = 705, patrolNumber = 5, radius = 150},
	},
}

registerScreenPlay("patrol_corellia_imperial_15", true)

destroy_surpriseattack_corellia_imperial_15_split = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_corellia_imperial_15_split",

	questName = "corellia_imperial_15_split",
	questType = "destroy_surpriseattack",

	questZone = "space_corellia",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_corellia_imperial_15",
	parentQuestType = "patrol",
	parentQuestName = "corellia_imperial_15",

	surpriseAttackShips = {
		zone = "space_corellia",
		spawns = {{count = 2, shipName = "reb_xwing_tier2"}},
	},
}

registerScreenPlay("destroy_surpriseattack_corellia_imperial_15_split", true)

-- Final mission: Assassinate, then Survival
assassinate_corellia_imperial_17 = SpaceAssassinateScreenplay:new {
	className = "assassinate_corellia_imperial_17",

	questType = "assassinate",
	questName = "corellia_imperial_17",

	questZone = "space_corellia",

	sideQuest = true,
	sideQuestType = "survival",
	sideQuestName = "corellia_tier2_final",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	arrivalDelay = 20,
	failTimer = 20,
	mustDestroyEscort = false,

	assassinateSpawns = {
		target = "reb_unmaned_xwing_tier2",
		escorts = {},
	},

	targetPatrols = {
		{patrolPointName = "corellia_imperial_tier3_leg_1_recovery_recover_2", x = -410, z = -3742, y = -2454},
		{patrolPointName = "corellia_imperial_tier3_leg_1_recovery_recover_3", x = -1184, z = -2297, y = -4821},
		{patrolPointName = "corellia_imperial_tier3_leg_1_recovery_recover_4", x = -5768, z = -2993, y = -6612},
	},
}

registerScreenPlay("assassinate_corellia_imperial_17", true)

survival_corellia_tier2_final = SpaceSurvivalScreenplay:new {
	className = "survival_corellia_tier2_final",

	questName = "corellia_tier2_final",
	questType = "survival",

	questZone = "space_corellia",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "assassinate_corellia_imperial_17",
	parentQuestType = "assassinate",
	parentQuestName = "corellia_imperial_17",

	-- Screenplay Specific Variables (survival/corellia_tier2_final.tab)
	transmissionPoint = {patrolPointName = "rebel_ambush_point", x = -3830, z = 3601, y = 3458},
	totalTransmissionTime = 350,
	timesToUpdateProgress = 6,
	transmissionStartDelay = 10,
	delayToFirstAttack = 20,

	attackShipLists = {
		{"xwing_rookie", "xwing_rookie", "bwing", "awing"},
		{"ywing_rookie", "ywing_ace", "xwing_average", "awing"},
		{"xwing_average", "ywing_rookie", "xwing_average", "bwing"},
	},

	attackPeriod = 90,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("survival_corellia_tier2_final", true)

-- Prisk Duty Missions
destroy_duty_corellia_imperial_8 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_corellia_imperial_8",

	questName = "corellia_imperial_8",
	questType = "destroy_duty",

	questZone = "space_corellia",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	totalLevels = 3,
	totalRounds = 2,
	totalWaves = 3,

	bossShip = "hidden_daggers_executioner_tier3",
	shipTypes = {
		{"hidden_daggers_eliminator_tier2", "hidden_daggers_eliminator_tier2"},
		{"hidden_daggers_killer_tier2", "hidden_daggers_killer_tier2"},
	},
}

registerScreenPlay("destroy_duty_corellia_imperial_8", true)

escort_duty_corellia_imperial_9 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_corellia_imperial_9",

	questName = "corellia_imperial_9",
	questType = "escort_duty",

	questZone = "space_corellia",

	creditReward = 2500,
	creditKillBonus = 200,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"freighterheavy_tier2", "freighterlight_tier2", "freightermedium_tier2"},

	escortPoints = {
		{patrolPointName = "trade_escort_1", zoneName = "space_corellia", x = -5777, z = 5956, y = -5286, escortNumber = 1, radius = 250},
		{patrolPointName = "trade_escort_2", zoneName = "space_corellia", x = -3830, z = 4317, y = -2982, escortNumber = 2, radius = 250},
		{patrolPointName = "trade_escort_3", zoneName = "space_corellia", x = -1924, z = 2666, y = -1102, escortNumber = 3, radius = 250},
		{patrolPointName = "trade_escort_4", zoneName = "space_corellia", x = 895, z = 210, y = 695, escortNumber = 4, radius = 250},
		{patrolPointName = "trade_escort_5", zoneName = "space_corellia", x = 3065, z = -1029, y = 2144, escortNumber = 5, radius = 250},
		{patrolPointName = "trade_escort_6", zoneName = "space_corellia", x = 4333, z = -2700, y = 3283, escortNumber = 6, radius = 250},
		{patrolPointName = "trade_escort_7", zoneName = "space_corellia", x = 5229, z = -3991, y = 4253, escortNumber = 7, radius = 250},
		{patrolPointName = "trade_escort_8", zoneName = "space_corellia", x = 5705, z = -5049, y = 5164, escortNumber = 8, radius = 250},
		{patrolPointName = "trade_escort_9", zoneName = "space_corellia", x = 6053, z = -5934, y = 5872, escortNumber = 9, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"hutt_pirate_s01_tier2", "hutt_pirate_s01_tier2"},
		{"hutt_fighter_s02_tier2", "hutt_pirate_s02_tier2"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_corellia_imperial_9", true)

destroy_duty_corellia_imperial_10 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_corellia_imperial_10",

	questName = "corellia_imperial_10",
	questType = "destroy_duty",

	questZone = "space_corellia",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	totalLevels = 4,
	totalRounds = 3,
	totalWaves = 4,

	bossShip = "reb_xwing_tier3",
	shipTypes = {
		{"reb_xwing_tier2", "reb_xwing_tier2"},
		{"reb_z95_tier2", "reb_z95_tier2"},
	},
}

registerScreenPlay("destroy_duty_corellia_imperial_10", true)

escort_duty_corellia_imperial_11 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_corellia_imperial_11",

	questName = "corellia_imperial_11",
	questType = "escort_duty",

	questZone = "space_corellia",

	creditReward = 2500,
	creditKillBonus = 200,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"imp_freighterheavy_tier2", "imp_freightermedium_tier2", "imp_freighterlight_tier2"},

	escortPoints = {
		{patrolPointName = "military_escort_5", zoneName = "space_corellia", x = -3887, z = -27, y = 6573, escortNumber = 1, radius = 250},
		{patrolPointName = "military_escort_6", zoneName = "space_corellia", x = -5250, z = -819, y = 2910, escortNumber = 2, radius = 250},
		{patrolPointName = "military_escort_7", zoneName = "space_corellia", x = -4275, z = -1067, y = -1961, escortNumber = 3, radius = 250},
		{patrolPointName = "military_escort_8", zoneName = "space_corellia", x = -3822, z = -1188, y = -4321, escortNumber = 4, radius = 250},
		{patrolPointName = "military_escort_9", zoneName = "space_corellia", x = -485, z = -1212, y = -5825, escortNumber = 5, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"reb_xwing_tier2", "reb_ywing_tier2"},
		{"reb_z95_tier2", "reb_z95_tier2"},
		{"reb_xwing_tier2", "reb_z95_tier2"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_corellia_imperial_11", true)

--[[
	Tier 3 -- Haymir Rendundi (Yavin 4, Lok)
	Ported from SWG-Source corellia_imperial_tier3_1..4 and their splits (patrol, inspect, delivery_no_pickup, recovery, survival, escort, space_battle, rescue, assassinate); feature black-epsilon-tier3-haymir
]]

-- Mission 1: Patrol > Inspect > Delivery (no pickup) > Recovery
patrol_corellia_imperial_tier3_1 = SpacePatrolScreenplay:new {
	className = "patrol_corellia_imperial_tier3_1",

	questName = "corellia_imperial_tier3_1",
	questType = "patrol",

	questZone = "space_yavin4",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon_capacitor/cap_mission_reward_imperial_rendili_k_class.iff"},
	},

	sideQuest = true,
	sideQuestType = "inspect",
	sideQuestName = "corellia_imperial_tier3_1_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 3,
	sideQuestDelay = 20,

	patrolPoints = {
		{patrolPointName = "corellia_imperial_tier3_leg_2_escort_1", x = -1823, z = -2113, y = -3292, patrolNumber = 1, radius = 150},
		{patrolPointName = "corellia_imperial_tier3_leg_2_escort_2", x = -361, z = -3496, y = -2017, patrolNumber = 2, radius = 150},
		{patrolPointName = "corellia_imperial_tier3_leg_2_escort_3", x = 63, z = -5425, y = -4321, patrolNumber = 3, radius = 150},
		{patrolPointName = "corellia_imperial_tier3_leg_2_escort_4", x = 2722, z = -5288, y = -2434, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_corellia_imperial_tier3_1", true)

inspect_corellia_imperial_tier3_1_a = SpaceInspectScreenplay:new {
	className = "inspect_corellia_imperial_tier3_1_a",

	questName = "corellia_imperial_tier3_1_a",
	questType = "inspect",

	questZone = "space_yavin4",

	sideQuest = true,
	sideQuestType = "delivery_no_pickup",
	sideQuestName = "corellia_imperial_tier3_1_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "patrol_corellia_imperial_tier3_1",
	parentQuestType = "patrol",
	parentQuestName = "corellia_imperial_tier3_1",

	-- Screenplay Specific Variables
	shipList = {"reb_yavinspy_tier4"},
	validSpawns = {
		{spawnName = "corellia_imperial_tier3_officerinspect", x = -2000, z = -4500, y = 3000},
	},
	giveSpawnWaypoint = 1,
	cargo = "joint_operations_plans",
}

registerScreenPlay("inspect_corellia_imperial_tier3_1_a", true)

delivery_no_pickup_corellia_imperial_tier3_1_b = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_corellia_imperial_tier3_1_b",

	questName = "corellia_imperial_tier3_1_b",
	questType = "delivery_no_pickup",

	questZone = "space_yavin4",

	sideQuest = true,
	sideQuestType = "recovery",
	sideQuestName = "corellia_imperial_tier3_1_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "inspect_corellia_imperial_tier3_1_a",
	parentQuestType = "inspect",
	parentQuestName = "corellia_imperial_tier3_1_a",

	deliveryShip = "imp_lambda_shuttle_tier3",

	deliveryPoint = {patrolPointName = "naboo_imperial_tier3_delivery1_dropoff", x = 1092, z = 842, y = 598},

	attackShipLists = {
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4"},
		{"reb_ywing_tier3", "reb_ywing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
	},

	attackPeriod = 90,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_no_pickup_corellia_imperial_tier3_1_b", true)

recovery_corellia_imperial_tier3_1_c = SpaceRecoveryScreenplay:new {
	className = "recovery_corellia_imperial_tier3_1_c",

	questName = "corellia_imperial_tier3_1_c",
	questType = "recovery",

	questZone = "space_yavin4",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "delivery_no_pickup_corellia_imperial_tier3_1_b",
	parentQuestType = "delivery_no_pickup",
	parentQuestName = "corellia_imperial_tier3_1_b",

	arrivalDelay = 20,
	recoveryDelay = 15,

	recoverShip = "reb_ywingleader_tier4",

	escortShips = {"reb_xwing_tier3", "reb_xwing_tier3", "reb_ywing_tier3", "reb_ywing_tier3"},

	preRecoveryPoints = {
		{patrolPointName = "corellia_imperial_tier3_rebofficer_1", x = -3922, z = -1205, y = 474, escortNumber = 1, radius = 250},
		{patrolPointName = "corellia_imperial_tier3_rebofficer_2", x = 1010, z = -2208, y = -2998, escortNumber = 2, radius = 250},
		{patrolPointName = "corellia_imperial_tier3_rebofficer_3", x = 6465, z = -2208, y = -5989, escortNumber = 3, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "corellia_imperial_tier3_rebofficer_4", x = 946, z = -189, y = -2000, escortNumber = 1, radius = 250},
		{patrolPointName = "corellia_imperial_tier3_rebofficer_5", x = -7536, z = 1004, y = -2160, escortNumber = 2, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"reb_awing_tier3", "reb_awing_tier3"},
		{"reb_xwing_tier3", "reb_xwing_tier3"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_corellia_imperial_tier3_1_c", true)

-- Mission 2: Recovery > Survival > Escort > Space battle
recovery_corellia_imperial_tier3_2 = SpaceRecoveryScreenplay:new {
	className = "recovery_corellia_imperial_tier3_2",

	questName = "corellia_imperial_tier3_2",
	questType = "recovery",

	questZone = "space_yavin4",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/droid_interface/ddi_mission_reward_imperial_sfs_military_grade.iff"},
	},

	sideQuest = true,
	sideQuestType = "survival",
	sideQuestName = "corellia_imperial_tier3_2_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	arrivalDelay = 15,
	recoveryDelay = 30,

	recoverShip = "huttsmuggler_tier3",

	escortShips = {"huttskiff_tier3", "huttskiff_tier3", "huttskiff_tier3", "huttskiff_tier3"},

	preRecoveryPoints = {
		{patrolPointName = "corellia_imperial_tier3_huttcapture_1", x = 5510, z = 2491, y = 5897, escortNumber = 1, radius = 250},
		{patrolPointName = "corellia_imperial_tier3_huttcapture_2", x = 5920, z = 6064, y = 983, escortNumber = 2, radius = 250},
		{patrolPointName = "corellia_imperial_tier3_huttcapture_3", x = 6, z = 3639, y = -4482, escortNumber = 3, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "corellia_imperial_tier3_huttcapture_4", x = 5240, z = 30, y = -5035, escortNumber = 1, radius = 250},
		{patrolPointName = "corellia_imperial_tier3_huttcapture_5", x = 5920, z = -4095, y = -6400, escortNumber = 2, radius = 250},
		{patrolPointName = "corellia_imperial_tier3_huttcapture_6", x = 5213, z = -3312, y = -5283, escortNumber = 3, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"huttgunship_tier3", "huttgunship_tier3", "huttgunship_tier3"},
		{"huttskiff_tier3", "huttskiff_tier3", "huttgunship_tier3", "huttgunship_tier3"},
		{"huttfighter_tier3", "huttfighter_tier3", "huttfighter_tier3", "huttfighter_tier3"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_corellia_imperial_tier3_2", true)

survival_corellia_imperial_tier3_2_a = SpaceSurvivalScreenplay:new {
	className = "survival_corellia_imperial_tier3_2_a",

	questName = "corellia_imperial_tier3_2_a",
	questType = "survival",

	questZone = "space_yavin4",

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "corellia_imperial_tier3_2_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "recovery_corellia_imperial_tier3_2",
	parentQuestType = "recovery",
	parentQuestName = "corellia_imperial_tier3_2",

	-- Screenplay Specific Variables
	transmissionPoint = {patrolPointName = "corellia_imperial_tier3_survival1", x = 5841, z = -1592, y = 3406},
	totalTransmissionTime = 300,
	timesToUpdateProgress = 10,
	transmissionStartDelay = 25,
	delayToFirstAttack = 45,

	attackShipLists = {
		{"nym_blastboat_tier3", "nym_blastboat_tier3", "nym_enforcer_tier3", "nym_enforcer_tier3"},
		{"nym_fighter_tier3", "nym_fighter_tier3", "nym_fighter_tier3", "nym_fighter_tier4"},
	},

	attackPeriod = 90,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("survival_corellia_imperial_tier3_2_a", true)

escort_corellia_imperial_tier3_2_b = SpaceEscortScreenplay:new {
	className = "escort_corellia_imperial_tier3_2_b",

	questName = "corellia_imperial_tier3_2_b",
	questType = "escort",

	questZone = "space_yavin4",

	sideQuest = true,
	sideQuestType = "space_battle",
	sideQuestName = "corellia_imperial_tier3_2_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "survival_corellia_imperial_tier3_2_a",
	parentQuestType = "survival",
	parentQuestName = "corellia_imperial_tier3_2_a",

	-- Screenplay Specific Variables
	escortShips = {"imp_huttsmuggler_tier3"},

	-- SWG's own point name for escort point 3 is corellis_imperial_tier3_leg_2_rescue_3
	escortPoints = {
		{patrolPointName = "corellia_imperial_tier3_leg_2_rescue_1", zoneName = "space_yavin4", x = -2338, z = -1448, y = -1092, escortNumber = 1, radius = 250},
		{patrolPointName = "corellia_imperial_tier3_leg_2_rescue_2", zoneName = "space_yavin4", x = -3882, z = -3866, y = -1432, escortNumber = 2, radius = 250},
		{patrolPointName = "corellis_imperial_tier3_leg_2_rescue_3", zoneName = "space_yavin4", x = 1463, z = -2058, y = -568, escortNumber = 3, radius = 250},
		{patrolPointName = "corellia_imperial_tier3_leg_2_rescue_4", zoneName = "space_yavin4", x = 3230, z = -310, y = 2173, escortNumber = 4, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"nym_enforcer_tier3", "nym_enforcer_tier3", "nym_enforcer_tier3", "nym_enforcer_captain_tier4"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_corellia_imperial_tier3_2_b", true)

space_battle_corellia_imperial_tier3_2_c = SpaceBattleScreenplay:new {
	className = "space_battle_corellia_imperial_tier3_2_c",

	questName = "corellia_imperial_tier3_2_c",
	questType = "space_battle",

	questZone = "space_yavin4",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "escort_corellia_imperial_tier3_2_b",
	parentQuestType = "escort",
	parentQuestName = "corellia_imperial_tier3_2_b",

	-- Screenplay Specific Variables (copied from spacequest/space_battle/corellia_imperial_tier3_2_c.tab)
	battlePoint = {patrolPointName = "corellia_imperial_tier3_leg_2_space_battle", x = -3042, z = 929, y = 2254, forward = {x = 0.020425, z = -0.111783, y = -0.993523}},

	damageMultiplier = 5,
	allyArrivalDelay = 30,
	enemyArrivalDelay = 90,
	allyOriginDist = 400,
	enemyOriginDist = -400,
	allyArrivalDist = 200,
	enemyArrivalDist = 300,

	allyForce = {
		"hutt_fighter_s02_tier4", "hutt_fighter_s02_tier4", "hutt_fighter_s02_tier4", "hutt_fighter_s02_tier4",
	},

	enemyForce = {
		"nym_enforcer_tier4", "nym_enforcer_tier4", "nym_enforcer_tier4", "nym_enforcer_tier4",
		"nym_enforcer_tier4", "nym_enforcer_tier4", "nym_enforcer_tier4", "nym_enforcer_captain_tier4",
	},
}

registerScreenPlay("space_battle_corellia_imperial_tier3_2_c", true)

-- Mission 3: Rescue > Assassinate
rescue_corellia_imperial_tier3_3 = SpaceRescueScreenplay:new {
	className = "rescue_corellia_imperial_tier3_3",

	questName = "corellia_imperial_tier3_3",
	questType = "rescue",

	questZone = "space_yavin4",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/reactor/rct_mission_reward_imperial_sds_high_output.iff"},
	},

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "corellia_imperial_tier3_3_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	-- Screenplay Specific Variables (SWG rescue/corellia_imperial_tier3_3.tab)
	recoveryPath = {
		{patrolPointName = "corellia_imperial_tier3_rescue_1", x = -1199, z = 3999, y = 2199},
		{patrolPointName = "corellia_imperial_tier3_rescue_2", x = -1011, z = 6173, y = 3600},
		{patrolPointName = "corellia_imperial_tier3_rescue_3", x = -2525, z = 5980, y = 3574},
		{patrolPointName = "corellia_imperial_tier3_rescue_4", x = -6994, z = 3814, y = 709},
	},

	targetShipType = "imp_freightermedium_tier3",
	targetArrivalDelay = 15,

	attackShipLists = {
		{"nym_bomber_tier3", "nym_enforcer_tier3", "nym_enforcer_captain_tier4", "nym_enforcer_tier3", "nym_enforcer_tier3"},
		{"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_bwing_tier3"},
	},

	attackPeriod = 90,
	attackListType = SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
	numResponses = 5,
}

registerScreenPlay("rescue_corellia_imperial_tier3_3", true)

assassinate_corellia_imperial_tier3_3_a = SpaceAssassinateScreenplay:new {
	className = "assassinate_corellia_imperial_tier3_3_a",

	questType = "assassinate",
	questName = "corellia_imperial_tier3_3_a",

	questZone = "space_yavin4",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "rescue_corellia_imperial_tier3_3",
	parentQuestType = "rescue",
	parentQuestName = "corellia_imperial_tier3_3",

	arrivalDelay = 20,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "reb_emissary_tier4",
		escorts = {"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_bwing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "corellia_imperial_tier3_assassinate_1", x = 1368, z = 4871, y = -2247},
		{patrolPointName = "corellia_imperial_tier3_assassinate_2", x = 2000, z = 6784, y = -3488},
		{patrolPointName = "corellia_imperial_tier3_assassinate_3", x = 3697, z = 6816, y = -3821},
		{patrolPointName = "corellia_imperial_tier3_assassinate_4", x = 7488, z = 6640, y = -2192},
	},
}

registerScreenPlay("assassinate_corellia_imperial_tier3_3_a", true)

-- Mission 4 (Lok): Recovery > Assassinate > Survival > Assassinate
recovery_corellia_imperial_tier3_4 = SpaceRecoveryScreenplay:new {
	className = "recovery_corellia_imperial_tier3_4",

	questName = "corellia_imperial_tier3_4",
	questType = "recovery",

	questZone = "space_lok",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/engine/eng_mission_reward_imperial_cygnus_megadrive.iff"},
	},

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "corellia_imperial_tier3_4_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	arrivalDelay = 20,
	recoveryDelay = 30,

	recoverShip = "nym_smuggle_transport_capture_tier4",

	escortShips = {
		"nym_fighter_tier3", "nym_fighter_tier3", "nym_fighter_tier3", "nym_fighter_tier3",
		"nym_fighter_tier3", "nym_fighter_tier3", "nym_fighter_tier3",
	},

	preRecoveryPoints = {
		{patrolPointName = "lok_imp_escort_duty_7", x = 4763, z = -1727, y = 3174, escortNumber = 1, radius = 250},
		{patrolPointName = "lok_imp_escort_duty_8", x = -4979, z = -2229, y = 1961, escortNumber = 2, radius = 250},
		{patrolPointName = "lok_imp_escort_duty_9", x = -5439, z = -2664, y = -5525, escortNumber = 3, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "lok_imp_recovery_1", x = 1779, z = 289, y = -1042, escortNumber = 1, radius = 250},
		{patrolPointName = "lok_imp_recovery_2", x = 2371, z = 588, y = -251, escortNumber = 2, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"nym_fighter_tier3", "nym_fighter_tier3", "nym_fighter_tier3", "nym_fighter_tier3"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_corellia_imperial_tier3_4", true)

assassinate_corellia_imperial_tier3_4_a = SpaceAssassinateScreenplay:new {
	className = "assassinate_corellia_imperial_tier3_4_a",

	questType = "assassinate",
	questName = "corellia_imperial_tier3_4_a",

	questZone = "space_lok",

	sideQuest = true,
	sideQuestType = "survival",
	sideQuestName = "corellia_imperial_tier3_4_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "recovery_corellia_imperial_tier3_4",
	parentQuestType = "recovery",
	parentQuestName = "corellia_imperial_tier3_4",

	arrivalDelay = 20,
	failTimer = 20,
	mustDestroyEscort = false,

	assassinateSpawns = {
		target = "nym_patrol_craft_tier4",
		escorts = {"nym_enforcer_tier3", "nym_enforcer_tier3", "nym_enforcer_tier3", "nym_enforcer_tier3", "nym_enforcer_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "lok_imp_recovery_7", x = -997, z = 669, y = 653},
		{patrolPointName = "lok_imp_recovery_8", x = 104, z = -139, y = 864},
		{patrolPointName = "lok_imp_recovery_9", x = 944, z = -1189, y = 856},
	},
}

registerScreenPlay("assassinate_corellia_imperial_tier3_4_a", true)

survival_corellia_imperial_tier3_4_b = SpaceSurvivalScreenplay:new {
	className = "survival_corellia_imperial_tier3_4_b",

	questName = "corellia_imperial_tier3_4_b",
	questType = "survival",

	questZone = "space_lok",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "corellia_imperial_tier3_4_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "assassinate_corellia_imperial_tier3_4_a",
	parentQuestType = "assassinate",
	parentQuestName = "corellia_imperial_tier3_4_a",

	-- Screenplay Specific Variables
	transmissionPoint = {patrolPointName = "corellia_imperial_tier3_survival1", x = -4511, z = 3086, y = -2187},
	totalTransmissionTime = 600,
	timesToUpdateProgress = 20,
	transmissionStartDelay = 25,
	delayToFirstAttack = 45,

	attackShipLists = {
		{"nym_fighter_tier3", "nym_fighter_tier3", "nym_fighter_tier3", "nym_fighter_tier3", "nym_fighter_tier4"},
		{"nym_enforcer_tier3", "nym_enforcer_tier3", "nym_enforcer_tier3", "nym_enforcer_tier3", "nym_enforcer_captain_tier4"},
	},

	attackPeriod = 120,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("survival_corellia_imperial_tier3_4_b", true)

assassinate_corellia_imperial_tier3_4_c = SpaceAssassinateScreenplay:new {
	className = "assassinate_corellia_imperial_tier3_4_c",

	questType = "assassinate",
	questName = "corellia_imperial_tier3_4_c",

	questZone = "space_lok",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "survival_corellia_imperial_tier3_4_b",
	parentQuestType = "survival",
	parentQuestName = "corellia_imperial_tier3_4_b",

	arrivalDelay = 20,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "nym_karthakk_queen_tier4",
		escorts = {"nym_fighter_tier3", "nym_fighter_tier3", "nym_fighter_tier3", "nym_enforcer_tier3", "nym_enforcer_tier3"},
	},

	-- SWG's own point name for the first point is corellia_tier3_assassinate2_1
	targetPatrols = {
		{patrolPointName = "corellia_tier3_assassinate2_1", x = 2767, z = 5195, y = -2260},
		{patrolPointName = "corellia_imperial_tier3_assassinate2_2", x = 5567, z = -1556, y = -7266},
		{patrolPointName = "corellia_imperial_tier3_assassinate2_3", x = 4172, z = 4062, y = -4134},
	},
}

registerScreenPlay("assassinate_corellia_imperial_tier3_4_c", true)

--[[

	BlackEpsilonSquadronScreenplay

]]

BlackEpsilonSquadronScreenplay = ScreenPlay:new {
	screenplayName = "BlackEpsilonSquadronScreenplay",

	-- Tier 1 (Hakassha)
	QUEST_STRING_1 = {type = "patrol", name = "corellia_imperial_1"},
	QUEST_STRING_1_SIDE = {type = "destroy_surpriseattack", name = "corellia_imperial_1"},
	QUEST_STRING_2 = {type = "destroy", name = "corellia_imperial_2"},
	QUEST_STRING_3 = {type = "escort", name = "corellia_imperial_3"},
	QUEST_STRING_4 = {type = "assassinate", name = "corellia_imperial_4"},
	QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "corellia_imperial_6"},
	QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "corellia_imperial_7"},

	-- Flags (stored as <playerID><suffix>, value "1")
	SERIES_COMPLETE_KEY = "BlackEpsilonSquadronScreenplay:imperial_corellia_1",
	WORKING_FOR_PRISK_KEY = "BlackEpsilonSquadronScreenplay:workingForPrisk",

	-- Tier 2 (Prisk)
	TIER2_QUEST_STRING_OPENING = {type = "recovery", name = "corellia_imperial_16"},
	TIER2_QUEST_STRING_1 = {type = "assassinate", name = "corellia_imperial_12"},
	TIER2_QUEST_STRING_2 = {type = "inspect", name = "corellia_imperial_13"},
	TIER2_QUEST_STRING_3 = {type = "assassinate", name = "corellia_imperial_14"},
	TIER2_QUEST_STRING_4 = {type = "patrol", name = "corellia_imperial_15"},
	TIER2_QUEST_STRING_4_SIDE = {type = "destroy_surpriseattack", name = "corellia_imperial_15_split"},
	TIER2_QUEST_STRING_FINAL = {type = "assassinate", name = "corellia_imperial_17"},
	TIER2_QUEST_STRING_FINAL_SIDE = {type = "survival", name = "corellia_tier2_final"},
	TIER2_QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "corellia_imperial_8"},
	TIER2_QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "corellia_imperial_9"},
	TIER2_QUEST_STRING_DUTY_3 = {type = "destroy_duty", name = "corellia_imperial_10"},
	TIER2_QUEST_STRING_DUTY_4 = {type = "escort_duty", name = "corellia_imperial_11"},

	-- Tier 3 (Haymir)
	TIER3_QUEST_STRING_1 = {type = "patrol", name = "corellia_imperial_tier3_1"},
	TIER3_QUEST_STRING_1_SIDE1 = {type = "inspect", name = "corellia_imperial_tier3_1_a"},
	TIER3_QUEST_STRING_1_SIDE2 = {type = "delivery_no_pickup", name = "corellia_imperial_tier3_1_b"},
	TIER3_QUEST_STRING_1_SIDE3 = {type = "recovery", name = "corellia_imperial_tier3_1_c"},
	TIER3_QUEST_STRING_2 = {type = "recovery", name = "corellia_imperial_tier3_2"},
	TIER3_QUEST_STRING_2_SIDE1 = {type = "survival", name = "corellia_imperial_tier3_2_a"},
	TIER3_QUEST_STRING_2_SIDE2 = {type = "escort", name = "corellia_imperial_tier3_2_b"},
	TIER3_QUEST_STRING_2_SIDE3 = {type = "space_battle", name = "corellia_imperial_tier3_2_c"},
	TIER3_QUEST_STRING_3 = {type = "rescue", name = "corellia_imperial_tier3_3"},
	TIER3_QUEST_STRING_3_SIDE1 = {type = "assassinate", name = "corellia_imperial_tier3_3_a"},
	TIER3_QUEST_STRING_4 = {type = "recovery", name = "corellia_imperial_tier3_4"},
	TIER3_QUEST_STRING_4_SIDE1 = {type = "assassinate", name = "corellia_imperial_tier3_4_a"},
	TIER3_QUEST_STRING_4_SIDE2 = {type = "survival", name = "corellia_imperial_tier3_4_b"},
	TIER3_QUEST_STRING_4_SIDE3 = {type = "assassinate", name = "corellia_imperial_tier3_4_c"},
}

registerScreenPlay("BlackEpsilonSquadronScreenplay", false)

function BlackEpsilonSquadronScreenplay:start()
end

-- Reset functions for quest clearing

function BlackEpsilonSquadronScreenplay:resetHakasshaQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	-- Mission 1
	patrol_corellia_imperial_1:resetQuest(pPlayer)
	destroy_surpriseattack_corellia_imperial_1:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_1.type, self.QUEST_STRING_1.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_1_SIDE.type, self.QUEST_STRING_1_SIDE.name, false)

	-- Mission 2
	destroy_corellia_imperial_2:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_2.type, self.QUEST_STRING_2.name, false)

	-- Mission 3
	escort_corellia_imperial_3:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_3.type, self.QUEST_STRING_3.name, false)

	-- Mission 4
	assassinate_corellia_imperial_4:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_4.type, self.QUEST_STRING_4.name, false)

	local playerID = SceneObject(pPlayer):getObjectID()

	removeQuestStatus(playerID .. self.SERIES_COMPLETE_KEY)
	removeQuestStatus(playerID .. self.WORKING_FOR_PRISK_KEY)
	removeQuestStatus(playerID .. self.QUEST_STRING_1.name .. ":attempted")
	removeQuestStatus(playerID .. self.QUEST_STRING_2.name .. ":attempted")
	removeQuestStatus(playerID .. self.QUEST_STRING_3.name .. ":attempted")
	removeQuestStatus(playerID .. self.QUEST_STRING_4.name .. ":attempted")
	removeQuestStatus(playerID .. self.QUEST_STRING_1.name .. ":reward")
	removeQuestStatus(playerID .. self.QUEST_STRING_2.name .. ":reward")
	removeQuestStatus(playerID .. self.QUEST_STRING_3.name .. ":reward")
	removeQuestStatus(playerID .. self.QUEST_STRING_4.name .. ":reward")
end

function BlackEpsilonSquadronScreenplay:resetPriskQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	-- Opening, missions 1-4 (with the patrol split) and the final (with the survival)
	recovery_corellia_imperial_16:resetQuest(pPlayer)
	assassinate_corellia_imperial_12:resetQuest(pPlayer)
	inspect_corellia_imperial_13:resetQuest(pPlayer)
	assassinate_corellia_imperial_14:resetQuest(pPlayer)
	patrol_corellia_imperial_15:resetQuest(pPlayer)
	destroy_surpriseattack_corellia_imperial_15_split:resetQuest(pPlayer)
	assassinate_corellia_imperial_17:resetQuest(pPlayer)
	survival_corellia_tier2_final:resetQuest(pPlayer)

	local questStrings = {
		self.TIER2_QUEST_STRING_OPENING, self.TIER2_QUEST_STRING_1, self.TIER2_QUEST_STRING_2, self.TIER2_QUEST_STRING_3,
		self.TIER2_QUEST_STRING_4, self.TIER2_QUEST_STRING_4_SIDE, self.TIER2_QUEST_STRING_FINAL, self.TIER2_QUEST_STRING_FINAL_SIDE
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	removeQuestStatus(playerID .. self.TIER2_QUEST_STRING_OPENING.name .. ":attempted")
	removeQuestStatus(playerID .. self.TIER2_QUEST_STRING_FINAL.name .. ":attempted")

	for n = 1, 4 do
		removeQuestStatus(playerID .. self["TIER2_QUEST_STRING_" .. n].name .. ":attempted")
		removeQuestStatus(playerID .. self["TIER2_QUEST_STRING_" .. n].name .. ":reward")
	end
end

function BlackEpsilonSquadronScreenplay:resetHaymirQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	-- Missions 1-4 with all of their split children
	local tables = {
		patrol_corellia_imperial_tier3_1,
		inspect_corellia_imperial_tier3_1_a,
		delivery_no_pickup_corellia_imperial_tier3_1_b,
		recovery_corellia_imperial_tier3_1_c,
		recovery_corellia_imperial_tier3_2,
		survival_corellia_imperial_tier3_2_a,
		escort_corellia_imperial_tier3_2_b,
		space_battle_corellia_imperial_tier3_2_c,
		rescue_corellia_imperial_tier3_3,
		assassinate_corellia_imperial_tier3_3_a,
		recovery_corellia_imperial_tier3_4,
		assassinate_corellia_imperial_tier3_4_a,
		survival_corellia_imperial_tier3_4_b,
		assassinate_corellia_imperial_tier3_4_c,
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.TIER3_QUEST_STRING_1,
		self.TIER3_QUEST_STRING_1_SIDE1,
		self.TIER3_QUEST_STRING_1_SIDE2,
		self.TIER3_QUEST_STRING_1_SIDE3,
		self.TIER3_QUEST_STRING_2,
		self.TIER3_QUEST_STRING_2_SIDE1,
		self.TIER3_QUEST_STRING_2_SIDE2,
		self.TIER3_QUEST_STRING_2_SIDE3,
		self.TIER3_QUEST_STRING_3,
		self.TIER3_QUEST_STRING_3_SIDE1,
		self.TIER3_QUEST_STRING_4,
		self.TIER3_QUEST_STRING_4_SIDE1,
		self.TIER3_QUEST_STRING_4_SIDE2,
		self.TIER3_QUEST_STRING_4_SIDE3,
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	for n = 1, 4 do
		removeQuestStatus(playerID .. self["TIER3_QUEST_STRING_" .. n].name .. ":attempted")
		removeQuestStatus(playerID .. self["TIER3_QUEST_STRING_" .. n].name .. ":reward")
	end
end
