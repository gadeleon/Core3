local SpaceHelpers = require("utils.space_helpers")

--[[

	Storm Squadron Quests

]]

--[[
	Tier 1 -- Lt. Akal Colzet (Tatooine, Bestine)
	Ported from SWG-Source tatooine_imperial_1..7 (patrol, destroy_surpriseattack, destroy, escort, assassinate, destroy_duty, escort_duty); feature storm-tier1-akal-colzet
]]

-- Mission 1: Patrol with surprise attack
patrol_tatooine_imperial_1 = SpacePatrolScreenplay:new {
	className = "patrol_tatooine_imperial_1",

	questName = "tatooine_imperial_1",
	questType = "patrol",

	questZone = "space_tatooine",

	creditReward = 100,

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "tatooine_imperial_1",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 10,

	patrolPoints = {
		{patrolPointName = "bestine_commerce_patrol_1", x = 2217, z = -4387, y = 2967, patrolNumber = 1, radius = 150},
		{patrolPointName = "bestine_commerce_patrol_2", x = 1500, z = -3750, y = 4460, patrolNumber = 2, radius = 150},
		{patrolPointName = "bestine_commerce_patrol_3", x = -304, z = -4571, y = 4419, patrolNumber = 3, radius = 150},
	},
}

registerScreenPlay("patrol_tatooine_imperial_1", true)

destroy_surpriseattack_tatooine_imperial_1 = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_tatooine_imperial_1",

	questName = "tatooine_imperial_1",
	questType = "destroy_surpriseattack",

	questZone = "space_tatooine",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_tatooine_imperial_1",
	parentQuestType = "patrol",
	parentQuestName = "tatooine_imperial_1",

	surpriseAttackShips = {
		zone = "space_tatooine",
		spawns = {{count = 3, shipName = "bestine_pirate_tier1"}},
	},
}

registerScreenPlay("destroy_surpriseattack_tatooine_imperial_1", true)

-- Mission 2: Destroy
destroy_tatooine_imperial_2 = SpaceDestroyScreenplay:new {
	className = "destroy_tatooine_imperial_2",

	questName = "tatooine_imperial_2",
	questType = "destroy",

	questZone = "space_tatooine",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	killsRequired = 4,

	shipLocations = {
		{spawnName = "bestine_escort_threat_1", x = 2525, z = 933, y = 851},
		{spawnName = "bestine_pirate_leader_guards", x = -1599, z = -3076, y = 3432},
		{spawnName = "bestine_pirates", x = 896, z = 1268, y = -2850},
		{spawnName = "bestine_security_threat_1", x = -3461, z = 775, y = -1259},
	},

	shipTypes = {
		"bestine_pirate_tier1",
	},
}

registerScreenPlay("destroy_tatooine_imperial_2", true)

-- Mission 3: Patrol with escort side quest
patrol_tatooine_imperial_3 = SpacePatrolScreenplay:new {
	className = "patrol_tatooine_imperial_3",

	questName = "tatooine_imperial_3",
	questType = "patrol",

	questZone = "space_tatooine",

	creditReward = 500,
	itemReward = {
		{species = {SPECIES_WOOKIEE}, item = "object/tangible/wearables/bandolier/double_bandolier.iff"},
		{species = {SPECIES_ITHORIAN}, item = "object/tangible/wearables/bandolier/ith_double_bandolier.iff"},
		{species = {-1}, item = "object/tangible/wearables/bodysuit/bodysuit_tie_fighter.iff"},
	},

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "tatooine_imperial_3",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 3,
	sideQuestDelay = 20,

	patrolPoints = {
		{patrolPointName = "bestine_security_patrol_1", x = 2458, z = -3985, y = 2511, patrolNumber = 1, radius = 150},
		{patrolPointName = "bestine_security_patrol_2", x = 1923, z = -3956, y = 3964, patrolNumber = 2, radius = 150},
		{patrolPointName = "bestine_security_patrol_3", x = 507, z = -2183, y = 4492, patrolNumber = 3, radius = 150},
		{patrolPointName = "bestine_security_patrol_4", x = -610, z = -3462, y = 5448, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_tatooine_imperial_3", true)

escort_tatooine_imperial_3 = SpaceEscortScreenplay:new {
	className = "escort_tatooine_imperial_3",

	questName = "tatooine_imperial_3",
	questType = "escort",

	questZone = "space_tatooine",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_tatooine_imperial_3",
	parentQuestType = "patrol",
	parentQuestName = "tatooine_imperial_3",

	escortShips = {"imp_freighterheavy_tatooine_tier1"},

	escortPoints = {
		{patrolPointName = "bestine_security_escort_1", zoneName = "space_tatooine", x = -687, z = -4985, y = 5979, escortNumber = 1, radius = 250},
		{patrolPointName = "bestine_security_escort_2", zoneName = "space_tatooine", x = 1560, z = -4462, y = 5550, escortNumber = 2, radius = 250},
		{patrolPointName = "bestine_security_escort_3", zoneName = "space_tatooine", x = 3957, z = -4516, y = 4717, escortNumber = 3, radius = 250},
		{patrolPointName = "bestine_security_escort_4", zoneName = "space_tatooine", x = 5463, z = -3570, y = 2317, escortNumber = 4, radius = 250},
		{patrolPointName = "bestine_security_escort_5", zoneName = "space_tatooine", x = 3521, z = 463, y = 2010, escortNumber = 5, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"bestine_pirate_tier1", "bestine_pirate_tier1"},
		{"bestine_pirate_leader_tier1"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_tatooine_imperial_3", true)

-- Mission 4: Assassinate
assassinate_tatooine_imperial_4 = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_imperial_4",

	questType = "assassinate",
	questName = "tatooine_imperial_4",

	questZone = "space_tatooine",

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
		target = "bestine_pirate_leader_tier1",
		escorts = {"bestine_pirate_tier1"},
	},

	-- SWG's list verbatim: the first point twice, and SWG's spelling "assasinate"
	targetPatrols = {
		{patrolPointName = "corellia_imperial_tier3_leg_4_assasinate_two_1", x = -1994, z = -5029, y = 4770},
		{patrolPointName = "corellia_imperial_tier3_leg_4_assasinate_two_1", x = -1994, z = -5029, y = 4770},
		{patrolPointName = "corellia_imperial_tier3_leg_4_assasinate_two_3", x = 2956, z = -4696, y = 5535},
	},
}

registerScreenPlay("assassinate_tatooine_imperial_4", true)

-- Akal Colzet Duty Missions
destroy_duty_tatooine_imperial_6 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_tatooine_imperial_6",

	questName = "tatooine_imperial_6",
	questType = "destroy_duty",

	questZone = "space_tatooine",

	creditReward = 100,

	sideQuest = false,
	sideQuestType = "",

	totalLevels = 5,
	totalRounds = 2,
	totalWaves = 3,

	bossShip = "bestine_pirate_leader_tier1",
	shipTypes = {
		{"bestine_pirate_tier1"},
	},
}

registerScreenPlay("destroy_duty_tatooine_imperial_6", true)

escort_duty_tatooine_imperial_7 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_tatooine_imperial_7",

	questName = "tatooine_imperial_7",
	questType = "escort_duty",

	questZone = "space_tatooine",

	creditReward = 1000,
	creditKillBonus = 100,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {
		"freighterheavy_tier1", "freighterlight_tier1", "freightermedium_tier1",
		"imp_freightermedium_tier1", "imp_freighterlight_tier1", "imp_freighterheavy_tier1",
	},

	escortPoints = {
		{patrolPointName = "imperial_escortduty_1", zoneName = "space_tatooine", x = 5392, z = -3840, y = 620, escortNumber = 1, radius = 250},
		{patrolPointName = "imperial_escortduty_2", zoneName = "space_tatooine", x = 2356, z = -3868, y = 4288, escortNumber = 2, radius = 250},
		{patrolPointName = "imperial_escortduty_3", zoneName = "space_tatooine", x = -1136, z = -3592, y = 4100, escortNumber = 3, radius = 250},
		{patrolPointName = "imperial_escortduty_4", zoneName = "space_tatooine", x = -5188, z = -3188, y = 4736, escortNumber = 4, radius = 250},
	},

	attackDelay = 100,

	attackShips = {
		{"reb_xwing_tier1", "reb_ywing_tier1"},
		{"bestine_pirate_tier1", "bestine_pirate_tier1"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_tatooine_imperial_7", true)

--[[
	Tier 2 -- Commander Jhon Oberhaur (Tatooine, Bestine; Lok)
	Ported from SWG-Source imperial_ss_1..3 (inspect, recovery, assassinate) and lok_imperial_ss_1a..1c (destroy_duty, recovery_duty, escort_duty); feature storm-tier2-oberhaur
]]

-- Mission 1: Inspect (any Nym Lieutenant: SWG has no spawner list and no waypoint for this quest)
inspect_imperial_ss_1 = SpaceInspectScreenplay:new {
	className = "inspect_imperial_ss_1",

	questName = "imperial_ss_1",
	questType = "inspect",

	questZone = "space_lok",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon/wpn_mission_reward_imperial_cygnus_starblaster.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	shipList = {"nym_lieutenant_tier2"},
	validSpawns = {},
	giveSpawnWaypoint = 0,
	cargo = "hostage_orders",
}

registerScreenPlay("inspect_imperial_ss_1", true)

-- Mission 2: Recovery (the hostage transport)
recovery_imperial_ss_2 = SpaceRecoveryScreenplay:new {
	className = "recovery_imperial_ss_2",

	questName = "imperial_ss_2",
	questType = "recovery",

	questZone = "space_lok",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/armor/arm_mission_reward_imperial_sfs_light_military.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	arrivalDelay = 15,
	recoveryDelay = 30,

	recoverShip = "nym_prison_ship_tier2",
	recoveryConversationMobile = "object/mobile/shared_space_comm_imperial_officer_01.iff",

	escortShips = {"nym_enforcer_tier2", "nym_enforcer_tier2", "nym_enforcer_tier2"},

	preRecoveryPoints = {
		{patrolPointName = "hostage_escort_1", x = -5448, z = 800, y = 2992, escortNumber = 1, radius = 250},
		{patrolPointName = "hostage_escort_2", x = -5951, z = 1295, y = 1027, escortNumber = 2, radius = 250},
		{patrolPointName = "hostage_escort_3", x = -4948, z = 1612, y = -1763, escortNumber = 3, radius = 250},
		{patrolPointName = "hostage_escort_4", x = -3993, z = 2074, y = -3667, escortNumber = 4, radius = 250},
		{patrolPointName = "hostage_escort_5", x = -3467, z = 2588, y = -6633, escortNumber = 5, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "hostage_recovery_1", x = -2930, z = 2690, y = -4742, escortNumber = 1, radius = 250},
		{patrolPointName = "hostage_recovery_2", x = -5561, z = 2135, y = -4973, escortNumber = 2, radius = 250},
		{patrolPointName = "hostage_recovery_3", x = -6832, z = 2296, y = -3612, escortNumber = 3, radius = 250},
		{patrolPointName = "hostage_recovery_4", x = -6637, z = 2449, y = -2060, escortNumber = 4, radius = 250},
		{patrolPointName = "hostage_recovery_5", x = -5082, z = 2428, y = -476, escortNumber = 5, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"nym_fighter_tier2", "nym_fighter_tier2"},
		{"nym_bomber_tier2", "nym_enforcer_tier2"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_imperial_ss_2", true)

-- Mission 3: Assassinate the Kimogila's Claw. Not granted by Oberhaur (SWG never grants it): the Nym technicians feature does
assassinate_imperial_ss_3 = SpaceAssassinateScreenplay:new {
	className = "assassinate_imperial_ss_3",

	questType = "assassinate",
	questName = "imperial_ss_3",

	questZone = "space_lok",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/booster/bst_mission_reward_imperial_rss_ion_booster.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	arrivalDelay = 30,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "nym_capo_ship_tier2",
		escorts = {"nym_enforcer_tier2", "nym_enforcer_tier2", "nym_enforcer_tier2"},
	},

	targetPatrols = {
		{patrolPointName = "hostage_escort_1", x = -5448, z = 800, y = 2992},
		{patrolPointName = "hostage_escort_2", x = -5951, z = 1295, y = 1027},
		{patrolPointName = "hostage_escort_3", x = -4948, z = 1612, y = -1763},
		{patrolPointName = "hostage_escort_4", x = -3993, z = 2074, y = -3667},
		{patrolPointName = "hostage_escort_5", x = -3467, z = 2588, y = -6633},
	},
}

registerScreenPlay("assassinate_imperial_ss_3", true)

-- Oberhaur Duty Missions
destroy_duty_lok_imperial_ss_1a = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_lok_imperial_ss_1a",

	questName = "lok_imperial_ss_1a",
	questType = "destroy_duty",

	questZone = "space_lok",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	totalLevels = 5,
	totalRounds = 2,
	totalWaves = 3,

	bossShip = "nym_fighter_tier3",
	shipTypes = {
		{"nym_fighter_tier2", "nym_fighter_tier2"},
		{"nym_enforcer_tier2", "nym_enforcer_tier2"},
		{"nym_blastboat_tier2", "nym_blastboat_tier2"},
	},
}

registerScreenPlay("destroy_duty_lok_imperial_ss_1a", true)

recovery_duty_lok_imperial_ss_1b = SpaceDutyRecoveryScreenplay:new {
	className = "recovery_duty_lok_imperial_ss_1b",

	questName = "lok_imperial_ss_1b",
	questType = "recovery_duty",

	questZone = "space_lok",

	creditReward = 2500,
	creditKillBonus = 200,
	numResponses = 5,

	sideQuest = false,
	sideQuestType = "",

	arrivalDelay = 30,
	recoveryDelay = 30,
	recoverShips = {"nym_freighterheavy_tier2", "nym_freighterlight_tier2", "nym_freightermedium_tier2"},

	escortShips = {"nym_enforcer_tier2", "nym_enforcer_tier2", "nym_enforcer_tier2"},

	preRecoveryPoints = {
		{patrolPointName = "lok_imp_pirate_1", x = -3200, z = -400, y = 3000, escortNumber = 1, radius = 250},
		{patrolPointName = "lok_imp_pirate_2", x = -2167, z = -767, y = 2211, escortNumber = 2, radius = 250},
		{patrolPointName = "lok_imp_pirate_3", x = -1493, z = -978, y = 1680, escortNumber = 3, radius = 250},
		{patrolPointName = "lok_imp_pirate_4", x = -759, z = -1583, y = 1233, escortNumber = 4, radius = 250},
		{patrolPointName = "lok_imp_pirate_5", x = 419, z = -2240, y = 594, escortNumber = 5, radius = 250},
		{patrolPointName = "lok_imp_pirate_6", x = 738, z = -1579, y = -310, escortNumber = 6, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "lok_imp_recovery_1", x = 1779, z = 289, y = -1042, escortNumber = 1, radius = 250},
		{patrolPointName = "lok_imp_recovery_2", x = 2371, z = 588, y = -251, escortNumber = 2, radius = 250},
		{patrolPointName = "lok_imp_recovery_3", x = 2037, z = -71, y = 478, escortNumber = 3, radius = 250},
		{patrolPointName = "lok_imp_recovery_4", x = 1411, z = -1579, y = 134, escortNumber = 4, radius = 250},
		{patrolPointName = "lok_imp_recovery_5", x = 385, z = -843, y = 254, escortNumber = 5, radius = 250},
		{patrolPointName = "lok_imp_recovery_6", x = -477, z = -150, y = 421, escortNumber = 6, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"nym_fighter_tier2", "nym_fighter_tier2"},
		{"nym_bomber_tier2", "nym_blastboat_tier2"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_duty_lok_imperial_ss_1b", true)

escort_duty_lok_imperial_ss_1c = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_lok_imperial_ss_1c",

	questName = "lok_imperial_ss_1c",
	questType = "escort_duty",

	questZone = "space_lok",

	creditReward = 2500,
	creditKillBonus = 200,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"imp_freightermedium_tier2", "imp_freighterlight_tier2", "imp_freighterheavy_tier2"},

	escortPoints = {
		{patrolPointName = "lok_imp_escort_duty_1", zoneName = "space_lok", x = 2700, z = 200, y = 2700, escortNumber = 1, radius = 250},
		{patrolPointName = "lok_imp_escort_duty_2", zoneName = "space_lok", x = 1927, z = 285, y = 1901, escortNumber = 2, radius = 250},
		{patrolPointName = "lok_imp_escort_duty_3", zoneName = "space_lok", x = 1564, z = 970, y = 1211, escortNumber = 3, radius = 250},
		{patrolPointName = "lok_imp_escort_duty_4", zoneName = "space_lok", x = 814, z = 429, y = 1053, escortNumber = 4, radius = 250},
		{patrolPointName = "lok_imp_escort_duty_5", zoneName = "space_lok", x = 122, z = -365, y = -407, escortNumber = 5, radius = 250},
		{patrolPointName = "lok_imp_escort_duty_6", zoneName = "space_lok", x = -571, z = -1090, y = -1672, escortNumber = 6, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"nym_fighter_tier2", "nym_fighter_tier2"},
		{"nym_enforcer_tier2", "nym_enforcer_tier2"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_lok_imperial_ss_1c", true)

--[[
	Tier 2 -- Field Commander Alozen (Yavin 4, Imperial outpost; Yavin system)
	Ported from SWG-Source imperial_ss_4..6 (inspect, escort, recovery) and lok_imperial_ss_2a..2c (destroy_duty, recovery_duty, escort_duty); feature storm-tier2-alozen
]]

-- Mission 1: Inspect (the Rebel agent; SWG rolls one of three cargo rows per spawn, Core3 always carries the activity log)
inspect_imperial_ss_4 = SpaceInspectScreenplay:new {
	className = "inspect_imperial_ss_4",

	questName = "imperial_ss_4",
	questType = "inspect",

	questZone = "space_yavin4",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/shield_generator/shd_mission_reward_imperial_rendili_dual_projector.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	shipList = {"rebel_agent_tier3"},
	validSpawns = {
		{spawnName = "tatooine_imperial_tier2_inspect_rebagent", x = -3200, z = -3000, y = 6000},
	},
	giveSpawnWaypoint = 1,
	cargo = "yavin_activity_log",
}

registerScreenPlay("inspect_imperial_ss_4", true)

-- Mission 2: Escort (the scan freighter)
escort_imperial_ss_5 = SpaceEscortScreenplay:new {
	className = "escort_imperial_ss_5",

	questName = "imperial_ss_5",
	questType = "escort",

	questZone = "space_yavin4",

	creditReward = 5000,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"imperial_scan_freighter_tier2"},

	escortPoints = {
		{patrolPointName = "yavin_rebel_region_scan_1", zoneName = "space_yavin4", x = 5000, z = -1220, y = 4300, escortNumber = 1, radius = 250},
		{patrolPointName = "yavin_rebel_region_scan_2", zoneName = "space_yavin4", x = 6563, z = -605, y = 4839, escortNumber = 2, radius = 250},
		{patrolPointName = "yavin_rebel_region_scan_3", zoneName = "space_yavin4", x = 5498, z = -1466, y = 2835, escortNumber = 3, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier3"},
		{"reb_ywing_tier3", "reb_z95_tier2", "reb_z95_tier2"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_imperial_ss_5", true)

-- Mission 3: Recovery (the Twilight Sun)
recovery_imperial_ss_6 = SpaceRecoveryScreenplay:new {
	className = "recovery_imperial_ss_6",

	questName = "imperial_ss_6",
	questType = "recovery",

	questZone = "space_yavin4",

	creditReward = 5000,

	sideQuest = false,
	sideQuestType = "",

	arrivalDelay = 20,
	recoveryDelay = 30,

	recoverShip = "twilight_sun_tier1",
	recoveryConversationMobile = "object/mobile/shared_space_comm_imperial_ace_01.iff",

	escortShips = {"reb_z95_tier2", "reb_z95_tier2", "reb_z95_tier2", "reb_z95_tier2"},

	preRecoveryPoints = {
		{patrolPointName = "tatooine_imperial_twilight_1", x = -5464, z = 3200, y = -6088, escortNumber = 1, radius = 250},
		{patrolPointName = "tatooine_imperial_twilight_2", x = -1316, z = 2300, y = -5012, escortNumber = 2, radius = 250},
		{patrolPointName = "tatooine_imperial_twilight_3", x = 4784, z = 1400, y = -5136, escortNumber = 3, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "tatooine_imperial_twilight_4", x = 3876, z = 900, y = -4400, escortNumber = 1, radius = 250},
		{patrolPointName = "tatooine_imperial_twilight_5", x = 4608, z = 200, y = -2712, escortNumber = 2, radius = 250},
		{patrolPointName = "tatooine_imperial_twilight_6", x = 5568, z = -800, y = -148, escortNumber = 3, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2"},
		{"reb_xwing_tier2", "reb_xwing_tier2", "reb_ywing_tier2"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_imperial_ss_6", true)

-- Alozen Duty Missions (SWG names carry the lok_ prefix; all three fly in Yavin)
destroy_duty_lok_imperial_ss_2a = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_lok_imperial_ss_2a",

	questName = "lok_imperial_ss_2a",
	questType = "destroy_duty",

	questZone = "space_yavin4",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	totalLevels = 5,
	totalRounds = 2,
	totalWaves = 3,

	bossShip = "deathstar_debris_priest_tier3",
	shipTypes = {
		{"deathstar_debris_guardian_tier2", "deathstar_debris_guardian_tier2"},
		{"deathstar_debris_fanatic_tier2", "deathstar_debris_fanatic_tier2"},
	},
}

registerScreenPlay("destroy_duty_lok_imperial_ss_2a", true)

recovery_duty_lok_imperial_ss_2b = SpaceDutyRecoveryScreenplay:new {
	className = "recovery_duty_lok_imperial_ss_2b",

	questName = "lok_imperial_ss_2b",
	questType = "recovery_duty",

	questZone = "space_yavin4",

	creditReward = 2500,
	creditKillBonus = 200,
	numResponses = 5,

	sideQuest = false,
	sideQuestType = "",

	arrivalDelay = 30,
	recoveryDelay = 60,
	recoverShip = "deathstar_debris_freighter_tier2",

	escortShips = {"deathstar_debris_guardian_tier2", "deathstar_debris_guardian_tier2", "deathstar_debris_guardian_tier2", "deathstar_debris_guardian_tier2"},

	preRecoveryPoints = {
		{patrolPointName = "yavin_imp_scavenger_1", x = -2200, z = 600, y = -2800, escortNumber = 1, radius = 250},
		{patrolPointName = "yavin_imp_scavenger_2", x = -1907, z = 827, y = -2147, escortNumber = 2, radius = 250},
		{patrolPointName = "yavin_imp_scavenger_3", x = -1688, z = 632, y = -1695, escortNumber = 3, radius = 250},
		{patrolPointName = "yavin_imp_scavenger_4", x = -1460, z = 635, y = -1050, escortNumber = 4, radius = 250},
		{patrolPointName = "yavin_imp_scavenger_5", x = -1026, z = 738, y = -552, escortNumber = 5, radius = 250},
		{patrolPointName = "yavin_imp_scavenger_6", x = 1877, z = 501, y = -1617, escortNumber = 6, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "yavin_imp_recovery_1", x = 2223, z = 898, y = -1548, escortNumber = 1, radius = 250},
		{patrolPointName = "yavin_imp_recovery_2", x = 1474, z = 1207, y = -883, escortNumber = 2, radius = 250},
		{patrolPointName = "yavin_imp_recovery_3", x = 1261, z = 935, y = 2, escortNumber = 3, radius = 250},
		{patrolPointName = "yavin_imp_recovery_4", x = 514, z = 1018, y = 1163, escortNumber = 4, radius = 250},
		{patrolPointName = "yavin_imp_recovery_5", x = -382, z = 1165, y = -674, escortNumber = 5, radius = 250},
		{patrolPointName = "yavin_imp_recovery_6", x = -791, z = 1241, y = -1688, escortNumber = 6, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"deathstar_debris_scavenger_tier2", "deathstar_debris_scavenger_tier2"},
		{"deathstar_debris_fanatic_tier2", "deathstar_debris_fanatic_tier2"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_duty_lok_imperial_ss_2b", true)

escort_duty_lok_imperial_ss_2c = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_lok_imperial_ss_2c",

	questName = "lok_imperial_ss_2c",
	questType = "escort_duty",

	questZone = "space_yavin4",

	creditReward = 2500,
	creditKillBonus = 200,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"imp_freightermedium_tier2", "imp_freighterlight_tier2", "imp_freighterheavy_tier2"},

	escortPoints = {
		{patrolPointName = "yavin_imp_escort_duty_1", zoneName = "space_yavin4", x = -4792, z = 1000, y = -1048, escortNumber = 1, radius = 250},
		{patrolPointName = "yavin_imp_escort_duty_2", zoneName = "space_yavin4", x = -2820, z = 1500, y = 1340, escortNumber = 2, radius = 250},
		{patrolPointName = "yavin_imp_escort_duty_3", zoneName = "space_yavin4", x = -2896, z = 2000, y = 3760, escortNumber = 3, radius = 250},
		{patrolPointName = "yavin_imp_escort_duty_4", zoneName = "space_yavin4", x = 36, z = 2500, y = 5188, escortNumber = 4, radius = 250},
		{patrolPointName = "yavin_imp_escort_duty_5", zoneName = "space_yavin4", x = 3016, z = 3000, y = 6392, escortNumber = 5, radius = 250},
		{patrolPointName = "yavin_imp_escort_duty_6", zoneName = "space_yavin4", x = 6476, z = 3500, y = 6428, escortNumber = 6, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"deathstar_debris_fanatic_tier2", "deathstar_debris_fanatic_tier2"},
		{"deathstar_debris_guardian_tier2", "deathstar_debris_guardian_tier2"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_lok_imperial_ss_2c", true)

--[[
	Tier 3 -- Captain Denner (Yavin 4, Imperial outpost; Endor system)
	Ported from SWG-Source tatooine_imperial_tier3_1..4 and their splits (escort, recovery, inspect, rescue, delivery_no_pickup, destroy_surpriseattack, patrol, space_battle, delivery, destroy, survival, assassinate); feature storm-tier3-denner-missions
]]

-- Mission 1: Escort > Recovery > Inspect > Rescue > Delivery (no pickup)
escort_tatooine_imperial_tier3_1 = SpaceEscortScreenplay:new {
	className = "escort_tatooine_imperial_tier3_1",

	questName = "tatooine_imperial_tier3_1",
	questType = "escort",

	questZone = "space_endor",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon_capacitor/cap_mission_reward_imperial_rendili_k_class.iff"},
	},

	sideQuest = true,
	sideQuestType = "recovery",
	sideQuestName = "tatooine_imperial_tier3_1_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 20, -- Time in seconds to wait to trigger side quest

	escortShips = {"imp_engineer_shuttle_tier3"},

	escortPoints = {
		{patrolPointName = "tatooine_imperial_tier3_escort1_1", x = 2340, z = -4531, y = 7123, zoneName = "space_endor", escortNumber = 1, radius = 250},
		{patrolPointName = "tatooine_imperial_tier3_escort1_2", x = -3468, z = -4500, y = 3945, zoneName = "space_endor", escortNumber = 2, radius = 250},
		{patrolPointName = "tatooine_imperial_tier3_escort1_3", x = -3809, z = -1542, y = -558, zoneName = "space_endor", escortNumber = 3, radius = 250},
		{patrolPointName = "tatooine_imperial_tier3_escort1_4", x = 2909, z = 774, y = -4383, zoneName = "space_endor", escortNumber = 4, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_ywing_tier3"},
		{"reb_ywing_tier3", "reb_z95_tier3", "reb_z95_tier3"},
	},

	tauntData = {goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2},
}

registerScreenPlay("escort_tatooine_imperial_tier3_1", true)

recovery_tatooine_imperial_tier3_1_a = SpaceRecoveryScreenplay:new {
	className = "recovery_tatooine_imperial_tier3_1_a",

	questName = "tatooine_imperial_tier3_1_a",
	questType = "recovery",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "inspect",
	sideQuestName = "tatooine_imperial_tier3_1_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "escort_tatooine_imperial_tier3_1",
	parentQuestType = "escort",
	parentQuestName = "tatooine_imperial_tier3_1",

	arrivalDelay = 30,
	recoveryDelay = 30,

	recoverShip = "rebel_controlled_shuttle_tier3",
	recoveryConversationMobile = "object/mobile/shared_dressed_imperial_officer_m.iff",

	escortShips = {"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_bwing_tier3"},

	preRecoveryPoints = {
		{patrolPointName = "tatooine_imperial_tier3_recovery1_1", x = -6736, z = 1000, y = 5728, escortNumber = 1, radius = 250},
		{patrolPointName = "tatooine_imperial_tier3_recovery1_2", x = -485, z = -3573, y = -4328, escortNumber = 2, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "tatooine_imperial_tier3_recovery1_3", x = -3234, z = -4013, y = -919, escortNumber = 1, radius = 250},
		{patrolPointName = "tatooine_imperial_tier3_recovery1_4", x = -4015, z = -4056, y = -1966, escortNumber = 2, radius = 250},
		{patrolPointName = "tatooine_imperial_tier3_recovery1_5", x = -4384, z = -3809, y = -3174, escortNumber = 3, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_tatooine_imperial_tier3_1_a", true)

inspect_tatooine_imperial_tier3_1_b = SpaceInspectScreenplay:new {
	className = "inspect_tatooine_imperial_tier3_1_b",

	questName = "tatooine_imperial_tier3_1_b",
	questType = "inspect",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "rescue",
	sideQuestName = "tatooine_imperial_tier3_1_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "recovery_tatooine_imperial_tier3_1_a",
	parentQuestType = "recovery",
	parentQuestName = "tatooine_imperial_tier3_1_a",

	-- Screenplay Specific Variables
	shipList = {"rebel_scout_fighter_tier3"},
	validSpawns = {
		{spawnName = "tatooine_imperial_tier3_rebscout_spawner", x = -2450, z = -3052, y = 1234},
	},
	giveSpawnWaypoint = 1,
	cargo = "encrypted_rebel_data",
}

registerScreenPlay("inspect_tatooine_imperial_tier3_1_b", true)

rescue_tatooine_imperial_tier3_1_c = SpaceRescueScreenplay:new {
	className = "rescue_tatooine_imperial_tier3_1_c",

	questName = "tatooine_imperial_tier3_1_c",
	questType = "rescue",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "delivery_no_pickup",
	sideQuestName = "tatooine_imperial_tier3_1_d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "inspect_tatooine_imperial_tier3_1_b",
	parentQuestType = "inspect",
	parentQuestName = "tatooine_imperial_tier3_1_b",

	-- Screenplay Specific Variables
	recoveryPath = {
		{patrolPointName = "tatooine_imperial_tier3_rescue1_1", x = 1000, z = -4000, y = -1500},
		{patrolPointName = "tatooine_imperial_tier3_rescue1_2", x = 4054, z = -6049, y = -3682},
		{patrolPointName = "tatooine_imperial_tier3_rescue1_3", x = 3070, z = -6422, y = -6716},
	},

	targetShipType = "imp_freighterlight_tier3",
	targetArrivalDelay = 30,

	attackShipLists = {
		{"reb_bwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
		{"reb_awing_tier3", "reb_awing_tier3", "reb_bwing_tier3"},
	},

	attackPeriod = 120,
	attackListType = SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
	numResponses = 5,
}

registerScreenPlay("rescue_tatooine_imperial_tier3_1_c", true)

delivery_no_pickup_tatooine_imperial_tier3_1_d = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_tatooine_imperial_tier3_1_d",

	questName = "tatooine_imperial_tier3_1_d",
	questType = "delivery_no_pickup",

	questZone = "space_endor",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "rescue_tatooine_imperial_tier3_1_c",
	parentQuestType = "rescue",
	parentQuestName = "tatooine_imperial_tier3_1_c",

	-- Screenplay Specific Variables
	deliveryShip = "imp_lambda_shuttle_tier3",
	deliveryPoint = {patrolPointName = "tatooine_imperial_tier3_delivery1_hq_spawner", x = 4300, z = 2948, y = -5400},

	attackShipLists = {
		{"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3"},
	},

	attackPeriod = 90,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_no_pickup_tatooine_imperial_tier3_1_d", true)

-- Mission 2: Inspect > Surprise attack > Inspect > Delivery (no pickup) > Patrol > Space battle
inspect_tatooine_imperial_tier3_2 = SpaceInspectScreenplay:new {
	className = "inspect_tatooine_imperial_tier3_2",

	questName = "tatooine_imperial_tier3_2",
	questType = "inspect",

	questZone = "space_endor",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/droid_interface/ddi_mission_reward_imperial_sfs_military_grade.iff"},
	},

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "tatooine_imperial_tier3_2_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 10, -- Time in seconds to wait to trigger side quest

	-- Screenplay Specific Variables
	shipList = {"rebel_scout_fighter_tier3"},
	validSpawns = {
		{spawnName = "tatooine_imperial_tier3_inspect2_spawner", x = -5009, z = 4104, y = 6001},
	},
	giveSpawnWaypoint = 1,
	cargo = "encrypted_rebel_data",
}

registerScreenPlay("inspect_tatooine_imperial_tier3_2", true)

destroy_surpriseattack_tatooine_imperial_tier3_2_a = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_tatooine_imperial_tier3_2_a",

	questName = "tatooine_imperial_tier3_2_a",
	questType = "destroy_surpriseattack",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "inspect",
	sideQuestName = "tatooine_imperial_tier3_2_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "inspect_tatooine_imperial_tier3_2",
	parentQuestType = "inspect",
	parentQuestName = "tatooine_imperial_tier3_2",

	-- Screenplay Specific Variables
	surpriseAttackShips = {
		zone = "space_endor",
		spawns = {
			{count = 5, shipName = "reb_awing_tier3"},
		},
	},
}

registerScreenPlay("destroy_surpriseattack_tatooine_imperial_tier3_2_a", true)

inspect_tatooine_imperial_tier3_2_b = SpaceInspectScreenplay:new {
	className = "inspect_tatooine_imperial_tier3_2_b",

	questName = "tatooine_imperial_tier3_2_b",
	questType = "inspect",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "delivery_no_pickup",
	sideQuestName = "tatooine_imperial_tier3_2_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 10, -- Time in seconds to wait to trigger side quest

	parentQuest = "destroy_surpriseattack_tatooine_imperial_tier3_2_a",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "tatooine_imperial_tier3_2_a",

	-- Screenplay Specific Variables
	shipList = {"rebel_scout_shuttle_tier3"},
	validSpawns = {
		{spawnName = "tatooine_imperial_tier3_inspect3_spawner", x = 6009, z = -7001, y = -1095},
	},
	giveSpawnWaypoint = 1,
	cargo = "rebel_plans",
}

registerScreenPlay("inspect_tatooine_imperial_tier3_2_b", true)

delivery_no_pickup_tatooine_imperial_tier3_2_c = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_tatooine_imperial_tier3_2_c",

	questName = "tatooine_imperial_tier3_2_c",
	questType = "delivery_no_pickup",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "patrol",
	sideQuestName = "tatooine_imperial_tier3_2_d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "inspect_tatooine_imperial_tier3_2_b",
	parentQuestType = "inspect",
	parentQuestName = "tatooine_imperial_tier3_2_b",

	-- Screenplay Specific Variables
	deliveryShip = "imp_lambda_shuttle_tier3",
	deliveryPoint = {patrolPointName = "tatooine_imperial_tier3_delivery2", x = -1000, z = -100, y = -500},

	attackShipLists = {
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4"},
	},

	attackPeriod = 90,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_no_pickup_tatooine_imperial_tier3_2_c", true)

patrol_tatooine_imperial_tier3_2_d = SpacePatrolScreenplay:new {
	className = "patrol_tatooine_imperial_tier3_2_d",

	questName = "tatooine_imperial_tier3_2_d",
	questType = "patrol",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "space_battle",
	sideQuestName = "tatooine_imperial_tier3_2_e",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,
	sideQuestPatrolStart = 3,
	sideQuestDelay = 20, -- Time in seconds to wait to trigger side quest

	parentQuest = "delivery_no_pickup_tatooine_imperial_tier3_2_c",
	parentQuestType = "delivery_no_pickup",
	parentQuestName = "tatooine_imperial_tier3_2_c",

	patrolPoints = {
		{patrolPointName = "tatooine_imperial_tier3_patrol1_1", x = 554, z = -706, y = 2191, patrolNumber = 1, radius = 150},
		{patrolPointName = "tatooine_imperial_tier3_patrol1_2", x = 659, z = -2035, y = 3506, patrolNumber = 2, radius = 150},
		{patrolPointName = "tatooine_imperial_tier3_patrol1_3", x = -385, z = -2351, y = 5481, patrolNumber = 3, radius = 150},
		{patrolPointName = "tatooine_imperial_tier3_patrol1_4", x = -1032, z = -1624, y = 7179, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_tatooine_imperial_tier3_2_d", true)

space_battle_tatooine_imperial_tier3_2_e = SpaceBattleScreenplay:new {
	className = "space_battle_tatooine_imperial_tier3_2_e",

	questName = "tatooine_imperial_tier3_2_e",
	questType = "space_battle",

	questZone = "space_endor",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_tatooine_imperial_tier3_2_d",
	parentQuestType = "patrol",
	parentQuestName = "tatooine_imperial_tier3_2_d",

	-- Screenplay Specific Variables
	battlePoint = {patrolPointName = "tatooine_imperial_tier3_battle1_spawner", x = 1477, z = -2315, y = 5545, forward = {x = -0.004857, z = 0.167584, y = 0.985846}},
	damageMultiplier = 3,
	allyArrivalDelay = 10,
	enemyArrivalDelay = 120,
	allyOriginDist = 400,
	enemyOriginDist = -400,
	allyArrivalDist = 200,
	enemyArrivalDist = 200,
	allyForce = {"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
	enemyForce = {"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4", "reb_ykl37r_tier3"},
}

registerScreenPlay("space_battle_tatooine_imperial_tier3_2_e", true)

-- Mission 3: Delivery > Destroy > Escort (3 attack waves) > Surprise attack > Survival
delivery_tatooine_imperial_tier3_3 = SpaceDeliveryScreenplay:new {
	className = "delivery_tatooine_imperial_tier3_3",

	questName = "tatooine_imperial_tier3_3",
	questType = "delivery",

	questZone = "space_endor",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/reactor/rct_mission_reward_imperial_sds_high_output.iff"},
	},

	sideQuest = true,
	sideQuestType = "destroy",
	sideQuestName = "tatooine_imperial_tier3_3_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	-- Screenplay Specific Variables
	pickupPoint = {patrolPointName = "tatooine_imperial_tier3_delivery3_pickup", x = -5657, z = -3287, y = -6482},
	deliveryPoint = {patrolPointName = "tatooine_imperial_tier3_delivery_dropoff", x = 90, z = -69, y = -1106},
	pickupShip = "imp_lambda_shuttle_tier3",
	deliveryShip = "imp_lambda_shuttle_tier3",

	attackShipLists = {
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4"},
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4"},
		{"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier4"},
	},

	attackPeriod = 90,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_tatooine_imperial_tier3_3", true)

destroy_tatooine_imperial_tier3_3_b = SpaceDestroyScreenplay:new {
	className = "destroy_tatooine_imperial_tier3_3_b",

	questName = "tatooine_imperial_tier3_3_b",
	questType = "destroy",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "tatooine_imperial_tier3_3_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "delivery_tatooine_imperial_tier3_3",
	parentQuestType = "delivery",
	parentQuestName = "tatooine_imperial_tier3_3",

	-- Screenplay Specific Variables
	killsRequired = 5,

	shipLocations = {},

	shipTypes = {
		"reb_awing_tier3", "reb_awing_tier4", "reb_bwing_tier3", "reb_bwing_tier4", "reb_xwing_tier3",
		"reb_xwing_tier4", "reb_ywing_tier3", "reb_ywing_tier4", "reb_z95_tier3", "reb_z95_tier4",
	},
}

registerScreenPlay("destroy_tatooine_imperial_tier3_3_b", true)

escort_tatooine_imperial_tier3_3_a = SpaceEscortScreenplay:new {
	className = "escort_tatooine_imperial_tier3_3_a",

	questName = "tatooine_imperial_tier3_3_a",
	questType = "escort",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "tatooine_imperial_tier3_3_d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.ATTACK_WAVE,
	sideQuestDelay = 10, -- Time in seconds to wait to trigger side quest

	parentQuest = "destroy_tatooine_imperial_tier3_3_b",
	parentQuestType = "destroy",
	parentQuestName = "tatooine_imperial_tier3_3_b",

	sideQuestAttackWave = 3, -- Attack waves to destroy before the hand-off (SWG triggerOn 3)

	escortShips = {"imp_lambda_decoy_shuttle_tier3"},

	escortPoints = {
		{patrolPointName = "tatooine_imperial_tier3_escort1_1", x = 2340, z = -4531, y = 7123, zoneName = "space_endor", escortNumber = 1, radius = 250},
		{patrolPointName = "tatooine_imperial_tier3_escort1_2", x = -3468, z = -4500, y = 3945, zoneName = "space_endor", escortNumber = 2, radius = 250},
		{patrolPointName = "tatooine_imperial_tier3_escort1_3", x = -3809, z = -1542, y = -558, zoneName = "space_endor", escortNumber = 3, radius = 250},
		{patrolPointName = "tatooine_imperial_tier3_escort1_4", x = 2909, z = 774, y = -4383, zoneName = "space_endor", escortNumber = 4, radius = 250},
	},

	attackDelay = 70,

	attackShips = {
		{"reb_bwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_tatooine_imperial_tier3_3_a", true)

destroy_surpriseattack_tatooine_imperial_tier3_3_d = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_tatooine_imperial_tier3_3_d",

	questName = "tatooine_imperial_tier3_3_d",
	questType = "destroy_surpriseattack",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "survival",
	sideQuestName = "tatooine_imperial_tier3_3_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "escort_tatooine_imperial_tier3_3_a",
	parentQuestType = "escort",
	parentQuestName = "tatooine_imperial_tier3_3_a",

	-- Screenplay Specific Variables
	surpriseAttackShips = {
		zone = "space_endor",
		spawns = {
			{count = 6, shipName = "reb_awing_tier3"},
		},
	},
}

registerScreenPlay("destroy_surpriseattack_tatooine_imperial_tier3_3_d", true)

survival_tatooine_imperial_tier3_3_c = SpaceSurvivalScreenplay:new {
	className = "survival_tatooine_imperial_tier3_3_c",

	questName = "tatooine_imperial_tier3_3_c",
	questType = "survival",

	questZone = "space_endor",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "destroy_surpriseattack_tatooine_imperial_tier3_3_d",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "tatooine_imperial_tier3_3_d",

	-- Screenplay Specific Variables
	transmissionPoint = {patrolPointName = "tatooine_imperial_tier3_survival1", x = 2090, z = 514, y = 306},
	totalTransmissionTime = 600,
	timesToUpdateProgress = 10,
	transmissionStartDelay = 60,
	delayToFirstAttack = 5,

	attackShipLists = {
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4"},
		{"reb_z95_tier3", "reb_z95_tier3", "reb_z95_tier3", "reb_z95_tier4", "reb_z95_tier3"},
		{"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier4"},
		{"reb_bwing_tier3", "reb_bwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_ykl37r_tier3", "reb_awing_tier3", "reb_awing_tier3"},
	},

	attackPeriod = 120,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("survival_tatooine_imperial_tier3_3_c", true)

-- Mission 4: Assassinate > Rescue > Inspect > Assassinate
assassinate_tatooine_imperial_tier3_4 = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_imperial_tier3_4",

	questName = "tatooine_imperial_tier3_4",
	questType = "assassinate",

	questZone = "space_endor",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/engine/eng_mission_reward_imperial_cygnus_megadrive.iff"},
	},

	sideQuest = true,
	sideQuestType = "rescue",
	sideQuestName = "tatooine_imperial_tier3_4_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	arrivalDelay = 15,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "reb_xwing_tier3",
		escorts = {"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "tatooine_imperial_tier3_assassinate4_01", x = 552, z = 5144, y = -4984},
		{patrolPointName = "tatooine_imperial_tier3_assassinate4_02", x = 3996, z = 500, y = -1498},
		{patrolPointName = "tatooine_imperial_tier3_assassinate4_03", x = 3984, z = -3744, y = 4468},
		{patrolPointName = "tatooine_imperial_tier3_assassinate4_04", x = -2988, z = -4004, y = 6386},
	},
}

registerScreenPlay("assassinate_tatooine_imperial_tier3_4", true)

rescue_tatooine_imperial_tier3_4_a = SpaceRescueScreenplay:new {
	className = "rescue_tatooine_imperial_tier3_4_a",

	questName = "tatooine_imperial_tier3_4_a",
	questType = "rescue",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "inspect",
	sideQuestName = "tatooine_imperial_tier3_4_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "assassinate_tatooine_imperial_tier3_4",
	parentQuestType = "assassinate",
	parentQuestName = "tatooine_imperial_tier3_4",

	-- Screenplay Specific Variables
	recoveryPath = {
		{patrolPointName = "tatooine_imperial_tier3_rescue2_1", x = 4764, z = -4609, y = -104},
		{patrolPointName = "tatooine_imperial_tier3_rescue2_2", x = 825, z = -3312, y = 2052},
		{patrolPointName = "tatooine_imperial_tier3_rescue2_3", x = -3703, z = -374, y = 144},
	},

	targetShipType = "imp_lambda_shuttle_tier3",
	targetArrivalDelay = 0,

	attackShipLists = {
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4"},
		{"reb_bwing_tier3", "reb_z95_tier3", "reb_z95_tier3", "reb_z95_tier3"},
		{"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3"},
	},

	attackPeriod = 90,
	attackListType = SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
	numResponses = 5,
}

registerScreenPlay("rescue_tatooine_imperial_tier3_4_a", true)

inspect_tatooine_imperial_tier3_4_b = SpaceInspectScreenplay:new {
	className = "inspect_tatooine_imperial_tier3_4_b",

	questName = "tatooine_imperial_tier3_4_b",
	questType = "inspect",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "tatooine_imperial_tier3_4_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "rescue_tatooine_imperial_tier3_4_a",
	parentQuestType = "rescue",
	parentQuestName = "tatooine_imperial_tier3_4_a",

	-- Screenplay Specific Variables
	shipList = {"rebel_command_shuttle_tier4"},
	validSpawns = {
		{spawnName = "tatooine_imperial_tier3_inspect4_spawner", x = 2000, z = 6500, y = 1200},
	},
	giveSpawnWaypoint = 1,
	cargo = "stolen_data",
}

registerScreenPlay("inspect_tatooine_imperial_tier3_4_b", true)

assassinate_tatooine_imperial_tier3_4_c = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_imperial_tier3_4_c",

	questName = "tatooine_imperial_tier3_4_c",
	questType = "assassinate",

	questZone = "space_endor",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "inspect_tatooine_imperial_tier3_4_b",
	parentQuestType = "inspect",
	parentQuestName = "tatooine_imperial_tier3_4_b",

	arrivalDelay = 30,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "rebel_command_shuttle_tier4",
		escorts = {"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "tatooine_imperial_tier3_assassinate1_1", x = -2000, z = 4300, y = 3000},
		{patrolPointName = "tatooine_imperial_tier3_assassinate1_2", x = -2206, z = 2385, y = 3982},
		{patrolPointName = "tatooine_imperial_tier3_assassinate1_3", x = -2017, z = -532, y = 5368},
		{patrolPointName = "tatooine_imperial_tier3_assassinate1_4", x = -153, z = -3292, y = 5758},
	},
}

registerScreenPlay("assassinate_tatooine_imperial_tier3_4_c", true)

--[[

	StormSquadronScreenplay

]]

StormSquadronScreenplay = ScreenPlay:new {
	screenplayName = "StormSquadronScreenplay",

	-- Tier 1 (Akal Colzet)
	QUEST_STRING_1 = {type = "patrol", name = "tatooine_imperial_1"},
	QUEST_STRING_1_SIDE = {type = "destroy_surpriseattack", name = "tatooine_imperial_1"},
	QUEST_STRING_2 = {type = "destroy", name = "tatooine_imperial_2"},
	QUEST_STRING_3 = {type = "patrol", name = "tatooine_imperial_3"},
	QUEST_STRING_3_SIDE = {type = "escort", name = "tatooine_imperial_3"},
	QUEST_STRING_4 = {type = "assassinate", name = "tatooine_imperial_4"},

	-- Duties
	QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "tatooine_imperial_6"},
	QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "tatooine_imperial_7"},

	-- Set by Colzet's promotion (SWG series imperial_tatooine_1); read by Colzet
	SERIES_COMPLETE_KEY = "StormSquadronScreenplay:imperial_tatooine_1",

	-- The Authorization of Transfer Colzet gives on the promotion; tier 2 reads it
	TRANSFER_FORM = "object/tangible/space/mission_objects/transfer_auth.iff",

	-- Tier 2 (Oberhaur)
	TIER2_QUEST_STRING_1 = {type = "inspect", name = "imperial_ss_1"},
	TIER2_QUEST_STRING_2 = {type = "recovery", name = "imperial_ss_2"},
	TIER2_QUEST_STRING_3 = {type = "assassinate", name = "imperial_ss_3"},
	TIER2_QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "lok_imperial_ss_1a"},
	TIER2_QUEST_STRING_DUTY_2 = {type = "recovery_duty", name = "lok_imperial_ss_1b"},
	TIER2_QUEST_STRING_DUTY_3 = {type = "escort_duty", name = "lok_imperial_ss_1c"},

	-- Set when Oberhaur accepts the signed transfer form (SWG stormSquadronInitiate); read by Oberhaur (O22)
	TIER2_INITIATE_KEY = "StormSquadronScreenplay:stormSquadronInitiate",
	-- Set by the Morv briefing (SWG ss.findingAgent), cleared by the Claw reward; read by Oberhaur (O13) and the Nym technicians feature
	TIER2_FINDING_AGENT_KEY = "StormSquadronScreenplay:findingAgent",
	-- Set when Morv points the pilot to the Zabrak technician (nym_technician_1 s_3b4b03fd); read by the Nym technicians (feature storm-tier2-nym-technicians)
	TIER2_MORV_TIP_KEY = "StormSquadronScreenplay:spokeToMorv",
	-- Set by the Alozen orders (SWG workingWithAlozen); read by Oberhaur (O8) and Alozen (storm-tier2-alozen)
	TIER2_ALOZEN_KEY = "StormSquadronScreenplay:workingWithAlozen",

	-- The item key the Read/Sign menu writes on the transfer form (SWG objvar "signature")
	TRANSFER_FORM_SIGNATURE = "signature",

	-- Tier 2 (Alozen)
	TIER2_QUEST_STRING_4 = {type = "inspect", name = "imperial_ss_4"},
	TIER2_QUEST_STRING_5 = {type = "escort", name = "imperial_ss_5"},
	TIER2_QUEST_STRING_6 = {type = "recovery", name = "imperial_ss_6"},
	TIER2_QUEST_STRING_DUTY_4 = {type = "destroy_duty", name = "lok_imperial_ss_2a"},
	TIER2_QUEST_STRING_DUTY_5 = {type = "recovery_duty", name = "lok_imperial_ss_2b"},
	TIER2_QUEST_STRING_DUTY_6 = {type = "escort_duty", name = "lok_imperial_ss_2c"},

	-- Tier 3 (Denner)
	TIER3_QUEST_STRING_1 = {type = "escort", name = "tatooine_imperial_tier3_1"},
	TIER3_QUEST_STRING_1_SIDE1 = {type = "recovery", name = "tatooine_imperial_tier3_1_a"},
	TIER3_QUEST_STRING_1_SIDE2 = {type = "inspect", name = "tatooine_imperial_tier3_1_b"},
	TIER3_QUEST_STRING_1_SIDE3 = {type = "rescue", name = "tatooine_imperial_tier3_1_c"},
	TIER3_QUEST_STRING_1_SIDE4 = {type = "delivery_no_pickup", name = "tatooine_imperial_tier3_1_d"},
	TIER3_QUEST_STRING_2 = {type = "inspect", name = "tatooine_imperial_tier3_2"},
	TIER3_QUEST_STRING_2_SIDE1 = {type = "destroy_surpriseattack", name = "tatooine_imperial_tier3_2_a"},
	TIER3_QUEST_STRING_2_SIDE2 = {type = "inspect", name = "tatooine_imperial_tier3_2_b"},
	TIER3_QUEST_STRING_2_SIDE3 = {type = "delivery_no_pickup", name = "tatooine_imperial_tier3_2_c"},
	TIER3_QUEST_STRING_2_SIDE4 = {type = "patrol", name = "tatooine_imperial_tier3_2_d"},
	TIER3_QUEST_STRING_2_SIDE5 = {type = "space_battle", name = "tatooine_imperial_tier3_2_e"},
	TIER3_QUEST_STRING_3 = {type = "delivery", name = "tatooine_imperial_tier3_3"},
	TIER3_QUEST_STRING_3_SIDE1 = {type = "destroy", name = "tatooine_imperial_tier3_3_b"},
	TIER3_QUEST_STRING_3_SIDE2 = {type = "escort", name = "tatooine_imperial_tier3_3_a"},
	TIER3_QUEST_STRING_3_SIDE3 = {type = "destroy_surpriseattack", name = "tatooine_imperial_tier3_3_d"},
	TIER3_QUEST_STRING_3_SIDE4 = {type = "survival", name = "tatooine_imperial_tier3_3_c"},
	TIER3_QUEST_STRING_4 = {type = "assassinate", name = "tatooine_imperial_tier3_4"},
	TIER3_QUEST_STRING_4_SIDE1 = {type = "rescue", name = "tatooine_imperial_tier3_4_a"},
	TIER3_QUEST_STRING_4_SIDE2 = {type = "inspect", name = "tatooine_imperial_tier3_4_b"},
	TIER3_QUEST_STRING_4_SIDE3 = {type = "assassinate", name = "tatooine_imperial_tier3_4_c"},
}

registerScreenPlay("StormSquadronScreenplay", false)

function StormSquadronScreenplay:start()
end

-- Reset functions for quest clearing

function StormSquadronScreenplay:resetColzetQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local tables = {
		patrol_tatooine_imperial_1, destroy_surpriseattack_tatooine_imperial_1, destroy_tatooine_imperial_2,
		patrol_tatooine_imperial_3, escort_tatooine_imperial_3, assassinate_tatooine_imperial_4,
		destroy_duty_tatooine_imperial_6, escort_duty_tatooine_imperial_7
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.QUEST_STRING_1, self.QUEST_STRING_1_SIDE, self.QUEST_STRING_2, self.QUEST_STRING_3,
		self.QUEST_STRING_3_SIDE, self.QUEST_STRING_4, self.QUEST_STRING_DUTY_1, self.QUEST_STRING_DUTY_2
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	removeQuestStatus(playerID .. self.SERIES_COMPLETE_KEY)

	for _, questString in ipairs({ self.QUEST_STRING_1, self.QUEST_STRING_2, self.QUEST_STRING_3, self.QUEST_STRING_4 }) do
		removeQuestStatus(playerID .. questString.name .. ":attempted")
		removeQuestStatus(playerID .. questString.name .. ":reward")
	end
end


function StormSquadronScreenplay:resetOberhaurQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local tables = {
		inspect_imperial_ss_1, recovery_imperial_ss_2, assassinate_imperial_ss_3,
		destroy_duty_lok_imperial_ss_1a, recovery_duty_lok_imperial_ss_1b, escort_duty_lok_imperial_ss_1c
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.TIER2_QUEST_STRING_1, self.TIER2_QUEST_STRING_2, self.TIER2_QUEST_STRING_3,
		self.TIER2_QUEST_STRING_DUTY_1, self.TIER2_QUEST_STRING_DUTY_2, self.TIER2_QUEST_STRING_DUTY_3
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	for n = 1, 3 do
		local name = self["TIER2_QUEST_STRING_" .. n].name

		removeQuestStatus(playerID .. name .. ":attempted")
		removeQuestStatus(playerID .. name .. ":reward")
	end

	removeQuestStatus(playerID .. self.TIER2_INITIATE_KEY)
	removeQuestStatus(playerID .. self.TIER2_FINDING_AGENT_KEY)
	removeQuestStatus(playerID .. self.TIER2_MORV_TIP_KEY)
	removeQuestStatus(playerID .. self.TIER2_ALOZEN_KEY)
end

function StormSquadronScreenplay:resetAlozenQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local tables = {
		inspect_imperial_ss_4, escort_imperial_ss_5, recovery_imperial_ss_6,
		destroy_duty_lok_imperial_ss_2a, recovery_duty_lok_imperial_ss_2b, escort_duty_lok_imperial_ss_2c
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.TIER2_QUEST_STRING_4, self.TIER2_QUEST_STRING_5, self.TIER2_QUEST_STRING_6,
		self.TIER2_QUEST_STRING_DUTY_4, self.TIER2_QUEST_STRING_DUTY_5, self.TIER2_QUEST_STRING_DUTY_6
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	for n = 4, 6 do
		local name = self["TIER2_QUEST_STRING_" .. n].name

		removeQuestStatus(playerID .. name .. ":attempted")
		removeQuestStatus(playerID .. name .. ":reward")
	end
end

function StormSquadronScreenplay:resetDennerQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local tables = {
		escort_tatooine_imperial_tier3_1, recovery_tatooine_imperial_tier3_1_a, inspect_tatooine_imperial_tier3_1_b,
		rescue_tatooine_imperial_tier3_1_c, delivery_no_pickup_tatooine_imperial_tier3_1_d,
		inspect_tatooine_imperial_tier3_2, destroy_surpriseattack_tatooine_imperial_tier3_2_a, inspect_tatooine_imperial_tier3_2_b,
		delivery_no_pickup_tatooine_imperial_tier3_2_c, patrol_tatooine_imperial_tier3_2_d, space_battle_tatooine_imperial_tier3_2_e,
		delivery_tatooine_imperial_tier3_3, destroy_tatooine_imperial_tier3_3_b, escort_tatooine_imperial_tier3_3_a,
		destroy_surpriseattack_tatooine_imperial_tier3_3_d, survival_tatooine_imperial_tier3_3_c,
		assassinate_tatooine_imperial_tier3_4, rescue_tatooine_imperial_tier3_4_a, inspect_tatooine_imperial_tier3_4_b,
		assassinate_tatooine_imperial_tier3_4_c
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.TIER3_QUEST_STRING_1, self.TIER3_QUEST_STRING_1_SIDE1, self.TIER3_QUEST_STRING_1_SIDE2, self.TIER3_QUEST_STRING_1_SIDE3, self.TIER3_QUEST_STRING_1_SIDE4,
		self.TIER3_QUEST_STRING_2, self.TIER3_QUEST_STRING_2_SIDE1, self.TIER3_QUEST_STRING_2_SIDE2, self.TIER3_QUEST_STRING_2_SIDE3, self.TIER3_QUEST_STRING_2_SIDE4, self.TIER3_QUEST_STRING_2_SIDE5,
		self.TIER3_QUEST_STRING_3, self.TIER3_QUEST_STRING_3_SIDE1, self.TIER3_QUEST_STRING_3_SIDE2, self.TIER3_QUEST_STRING_3_SIDE3, self.TIER3_QUEST_STRING_3_SIDE4,
		self.TIER3_QUEST_STRING_4, self.TIER3_QUEST_STRING_4_SIDE1, self.TIER3_QUEST_STRING_4_SIDE2, self.TIER3_QUEST_STRING_4_SIDE3
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	for n = 1, 4 do
		local name = self["TIER3_QUEST_STRING_" .. n].name

		removeQuestStatus(playerID .. name .. ":attempted")
		removeQuestStatus(playerID .. name .. ":reward")
	end
end

-- The Nym fuel technicians on Lok (Morv and two decoys) grant the Kimogila's Claw (feature storm-tier2-nym-technicians)
-- Stage of the Claw for a pilot: none, briefed, tipped, active, failed or won (side-effect free)
function StormSquadronScreenplay:getClawStage(pPlayer)
	if (pPlayer == nil or not isJtlEnabled()) then
		return "none"
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil or not SpaceHelpers:isStormSquadron(pPlayer)) then
		return "none"
	end

	local playerID = CreatureObject(pPlayer):getObjectID()
	local questString = self.TIER2_QUEST_STRING_3

	if (getQuestStatus(playerID .. self.TIER2_FINDING_AGENT_KEY) ~= "1" or getQuestStatus(playerID .. questString.name .. ":reward") == "1") then
		return "none"
	end

	if (SpaceHelpers:isSpaceQuestComplete(pPlayer, questString.type, questString.name)) then
		return "won"
	elseif (SpaceHelpers:isSpaceQuestChainActive(pPlayer, questString.type .. "_" .. questString.name)) then
		return "active"
	elseif (getQuestStatus(playerID .. questString.name .. ":attempted") == "1") then
		return "failed"
	elseif (getQuestStatus(playerID .. self.TIER2_MORV_TIP_KEY) == "1") then
		return "tipped"
	end

	return "briefed"
end

-- The Claw may be (re)started: tipped or failed, and no other space quest or Oberhaur mission
function StormSquadronScreenplay:canStartClaw(pPlayer)
	local stage = self:getClawStage(pPlayer)

	if (stage ~= "tipped" and stage ~= "failed") then
		return false
	end

	return not SpaceHelpers:hasSpaceQuest(pPlayer) and not oberhaurConvoHandler:isOnMission(pPlayer)
end

-- Grants the Claw (guarded by canStartClaw); a retry starts clean
function StormSquadronScreenplay:startClaw(pPlayer, pNpc)
	if (not self:canStartClaw(pPlayer)) then
		return false
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. self.TIER2_QUEST_STRING_3.name .. ":attempted", 1)

	return SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, "assassinate_imperial_ss_3")
end

-- The first Authorization of Transfer directly in the inventory (SWG tatooine_imperial_trainer_2.java:16-27), or nil
function StormSquadronScreenplay:getTransferForm(pPlayer)
	if (pPlayer == nil) then
		return nil
	end

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if (pInventory == nil) then
		return nil
	end

	return getContainerObjectByTemplate(pInventory, self.TRANSFER_FORM, false)
end

-- The signature stored by the Read/Sign menu, "" when unsigned
function StormSquadronScreenplay:getTransferFormSignature(pForm)
	if (pForm == nil) then
		return ""
	end

	local signature = TangibleObject(pForm):getLuaStringData(self.TRANSFER_FORM_SIGNATURE)

	if (signature == nil) then
		return ""
	end

	return signature
end

-- The Authorization of Transfer's Read / Sign menu (SWG script/space/characters/transfer_auth.java)
StormTransferFormMenuComponent = {}

function StormTransferFormMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)

	menuResponse:addRadialMenuItem(20, 3, "@space/quest:read")
end

function StormTransferFormMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pPlayer == nil or pSceneObject == nil) then
		return 0
	end

	if (selectedID ~= 20) then
		return 0
	end

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if (pInventory == nil or SceneObject(pSceneObject):getParentID() ~= SceneObject(pInventory):getObjectID()) then
		CreatureObject(pPlayer):sendSystemMessage("@space/quest:not_in_inv")
		return 0
	end

	self:showForm(pSceneObject, pPlayer)

	return 0
end

function StormTransferFormMenuComponent:showForm(pForm, pPlayer)
	local signature = StormSquadronScreenplay:getTransferFormSignature(pForm)
	local sui = SuiMessageBox.new("StormTransferFormMenuComponent", "readCallback")

	sui.setTitle("@space/quest:ta_title")

	if (signature == "") then
		sui.setPrompt("@space/quest:ta_text")
	else
		sui.setPrompt(getStringId("@space/quest:ta_text") .. "\n Signed: " .. signature .. "\n")
	end

	sui.setOkButtonText("@space/quest:close")
	sui.setCancelButtonText("@space/quest:sign")
	sui.setTargetNetworkId(SceneObject(pForm):getObjectID())
	sui.sendTo(pPlayer)
end

-- The form a box was opened for: the engine gives the callback no using object for page boxes, so it is read from the page target
function StormTransferFormMenuComponent:getBoxForm(pSui)
	if (pSui == nil) then
		return nil
	end

	local pPage = LuaSuiBoxPage(pSui):getSuiPageData()

	if (pPage == nil) then
		return nil
	end

	local id = LuaSuiPageData(pPage):getTargetNetworkId()

	if (id == nil or id == 0) then
		return nil
	end

	return getSceneObject(id)
end

function StormTransferFormMenuComponent:readCallback(pPlayer, pSui, eventIndex)
	if (pPlayer == nil or eventIndex ~= 1) then
		return
	end

	local pForm = self:getBoxForm(pSui)

	if (pForm == nil) then
		return
	end

	local sui = SuiInputBox.new("StormTransferFormMenuComponent", "signCallback")

	sui.setTitle("@space/quest:ta_sign_title")
	sui.setPrompt("@space/quest:ta_sign")
	sui.setTargetNetworkId(SceneObject(pForm):getObjectID())
	sui.sendTo(pPlayer)
end

function StormTransferFormMenuComponent:signCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex ~= 0 or args == nil or string.match(args, "^%s*$") ~= nil) then
		return
	end

	local pForm = self:getBoxForm(pSui)

	if (pForm == nil) then
		return
	end

	TangibleObject(pForm):setLuaStringData(StormSquadronScreenplay.TRANSFER_FORM_SIGNATURE, args)
	CreatureObject(pPlayer):sendSystemMessage("@space/quest:signed")
end
