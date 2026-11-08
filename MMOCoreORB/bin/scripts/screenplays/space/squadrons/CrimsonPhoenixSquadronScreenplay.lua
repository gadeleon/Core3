local SpaceHelpers = require("utils.space_helpers")

--[[

	Crimson Phoenix Squadron Quests

]]

--[[
	Tier 1 -- Da'la Socuna (Tatooine, Mos Espa)
	Trainer: Commander Da'la Socuna (conversation socunaConvoHandler), Mos Espa cantina (screenplays/cities/tatooine_mos_espa.lua:187). 8 quest tables for 6 SWG-Source names: tatooine_rebel_1..4, 6, 7 (patrol, destroy_surpriseattack, destroy, escort, assassinate, destroy_duty, escort_duty), from datatables/spacequest and tatooine_rebel_trainer_1.java; feature crimson-phoenix-tier1-da-la-socuna
	Mission numbers follow the trainer script: mission 2 is destroy/tatooine_rebel_3 and mission 3 is patrol/tatooine_rebel_2
]]

-- Mission 1: Patrol with surprise attack
patrol_tatooine_rebel_1 = SpacePatrolScreenplay:new {
	className = "patrol_tatooine_rebel_1",

	questName = "tatooine_rebel_1",
	questType = "patrol",

	questZone = "space_tatooine",

	creditReward = 100,

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "tatooine_rebel_1",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 12,

	patrolPoints = {
		{patrolPointName = "anchorhead_supply_patrol_1", x = 2634, z = -5262, y = 1718, patrolNumber = 1, radius = 150},
		{patrolPointName = "anchorhead_supply_patrol_2", x = 3931, z = -4960, y = 1438, patrolNumber = 2, radius = 150},
		{patrolPointName = "anchorhead_supply_patrol_3", x = 5843, z = -4271, y = -94, patrolNumber = 3, radius = 150},
	},
}

registerScreenPlay("patrol_tatooine_rebel_1", true)

destroy_surpriseattack_tatooine_rebel_1 = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_tatooine_rebel_1",

	questName = "tatooine_rebel_1",
	questType = "destroy_surpriseattack",

	questZone = "space_tatooine",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_tatooine_rebel_1",
	parentQuestType = "patrol",
	parentQuestName = "tatooine_rebel_1",

	surpriseAttackShips = {
		zone = "space_tatooine",
		spawns = {{count = 3, shipName = "imp_tie_fighter_tier1"}},
	},
}

registerScreenPlay("destroy_surpriseattack_tatooine_rebel_1", true)

-- Mission 2: Destroy
destroy_tatooine_rebel_3 = SpaceDestroyScreenplay:new {
	className = "destroy_tatooine_rebel_3",

	questName = "tatooine_rebel_3",
	questType = "destroy",

	questZone = "space_tatooine",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	killsRequired = 4,

	shipLocations = {
		{spawnName = "anchorhead_tie_rally_alpha", x = 1948, z = -366, y = 2316},
		{spawnName = "imp_base_defense_03", x = -3826, z = 380, y = 2983},
		{spawnName = "imperial_base_guard_1", x = -6388, z = 4911, y = -1055},
		{spawnName = "imperial_squad_1", x = -4099, z = -602, y = 4240},
	},

	shipTypes = {
		"imp_tie_fighter_tier1",
		"imp_tie_fighter_tier2",
		"imp_tie_fighter_tier3",
		"imp_tie_fighter_tier4",
		"imp_tie_fighter_tier2_tatooine",
	},
}

registerScreenPlay("destroy_tatooine_rebel_3", true)

-- Mission 3: Patrol with escort side quest
patrol_tatooine_rebel_2 = SpacePatrolScreenplay:new {
	className = "patrol_tatooine_rebel_2",

	questName = "tatooine_rebel_2",
	questType = "patrol",

	questZone = "space_tatooine",

	creditReward = 500,
	-- SWG's rebel_bodysuit_s14.iff has no pre-NGE template; bodysuit_s14 as for Kreezo (space-trainer-rewards D-11)
	itemReward = {
		{species = {SPECIES_WOOKIEE}, item = "object/tangible/wearables/bandolier/multipocket_bandolier.iff"},
		{species = {SPECIES_ITHORIAN}, item = "object/tangible/wearables/bandolier/ith_multipocket_bandolier.iff"},
		{species = {-1}, item = "object/tangible/wearables/bodysuit/bodysuit_s14.iff"},
	},

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "tatooine_rebel_2",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 10,

	patrolPoints = {
		{patrolPointName = "anchorhead_armed_recon_1", x = -1387, z = -1962, y = 1725, patrolNumber = 1, radius = 150},
		{patrolPointName = "anchorhead_armed_recon_2", x = -589, z = -2389, y = 1587, patrolNumber = 2, radius = 150},
		{patrolPointName = "anchorhead_armed_recon_3", x = 770, z = -1644, y = 1372, patrolNumber = 3, radius = 150},
	},
}

registerScreenPlay("patrol_tatooine_rebel_2", true)

escort_tatooine_rebel_2 = SpaceEscortScreenplay:new {
	className = "escort_tatooine_rebel_2",

	questName = "tatooine_rebel_2",
	questType = "escort",

	questZone = "space_tatooine",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_tatooine_rebel_2",
	parentQuestType = "patrol",
	parentQuestName = "tatooine_rebel_2",

	escortShips = {"reb_freightermedium_tier1"},

	escortPoints = {
		{patrolPointName = "anchorhead_escort_1", zoneName = "space_tatooine", x = 1163, z = -2422, y = 1950, escortNumber = 1, radius = 250},
		{patrolPointName = "anchorhead_escort_2", zoneName = "space_tatooine", x = -1574, z = -2952, y = 1649, escortNumber = 2, radius = 250},
		{patrolPointName = "anchorhead_escort_3", zoneName = "space_tatooine", x = -2714, z = -2199, y = 1263, escortNumber = 3, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_tatooine_rebel_2", true)

-- Mission 4: Assassinate
assassinate_tatooine_rebel_4 = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_rebel_4",

	questType = "assassinate",
	questName = "tatooine_rebel_4",

	questZone = "space_tatooine",

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
		{patrolPointName = "bestine_security_escort_1", x = -687, z = -4985, y = 5979},
		{patrolPointName = "bestine_security_escort_3", x = 3957, z = -4516, y = 4717},
		{patrolPointName = "bestine_security_escort_5", x = 3521, z = 463, y = 2010},
		{patrolPointName = "bestine_security_patrol_2", x = 1923, z = -3956, y = 3964},
	},
}

registerScreenPlay("assassinate_tatooine_rebel_4", true)

-- Da'la Socuna Duty Missions
destroy_duty_tatooine_rebel_6 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_tatooine_rebel_6",

	questName = "tatooine_rebel_6",
	questType = "destroy_duty",

	questZone = "space_tatooine",

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

registerScreenPlay("destroy_duty_tatooine_rebel_6", true)

escort_duty_tatooine_rebel_7 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_tatooine_rebel_7",

	questName = "tatooine_rebel_7",
	questType = "escort_duty",

	questZone = "space_tatooine",

	creditReward = 1000,
	creditKillBonus = 100,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {
		"reb_freighterheavy_tier1", "reb_freighterlight_tier1", "reb_freightermedium_tier1",
	},

	escortPoints = {
		{patrolPointName = "anchorhead_escort_1", zoneName = "space_tatooine", x = 1163, z = -2422, y = 1950, escortNumber = 1, radius = 250},
		{patrolPointName = "anchorhead_escort_3", zoneName = "space_tatooine", x = -2714, z = -2199, y = 1263, escortNumber = 2, radius = 250},
		{patrolPointName = "anchorhead_supply_patrol_1", zoneName = "space_tatooine", x = 2634, z = -5262, y = 1718, escortNumber = 3, radius = 250},
		{patrolPointName = "anchorhead_supply_patrol_3", zoneName = "space_tatooine", x = 5843, z = -4271, y = -94, escortNumber = 4, radius = 250},
	},

	attackDelay = 100,

	attackShips = {
		{"imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_tatooine_rebel_7", true)

--[[
	Tier 2 -- Major Eker (Yavin 4, labor outpost; Yavin 4 and Lok systems)
	Trainer: Major Eker (conversation ekerConvoHandler), Yavin 4 labor outpost (screenplays/cities/yavin4_labor_outpost.lua:18). 8 quest tables for 7 SWG-Source names: yavin_rebel_9, 10, 12..16 (escort, inspect, destroy_surpriseattack, recovery_duty, escort_duty, destroy_duty), from datatables/spacequest and yavin_rebel_trainer_2.java; feature crimson-phoenix-tier2-eker
	Mission 3 hands off to its surprise attack after the first cargo inspection (INSPECTION split, as vortex_mission_1)
]]

-- Mission 1: Escort
escort_yavin_rebel_13 = SpaceEscortScreenplay:new {
	className = "escort_yavin_rebel_13",

	questName = "yavin_rebel_13",
	questType = "escort",

	questZone = "space_yavin4",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/shield_generator/shd_mission_reward_rebel_incom_k77.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"yavin_mission_1_freighter"},

	escortPoints = {
		{patrolPointName = "rebel_security_escort_1", zoneName = "space_yavin4", x = -3200, z = -1600, y = 100, escortNumber = 1, radius = 250},
		{patrolPointName = "rebel_security_escort_2", zoneName = "space_yavin4", x = -2834, z = -993, y = -2072, escortNumber = 2, radius = 250},
		{patrolPointName = "rebel_security_escort_3", zoneName = "space_yavin4", x = -1415, z = -632, y = -1029, escortNumber = 3, radius = 250},
		{patrolPointName = "rebel_security_escort_4", zoneName = "space_yavin4", x = 1346, z = -711, y = -436, escortNumber = 4, radius = 250},
	},

	attackDelay = 80,

	attackShips = {
		{"imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
		{"imp_tie_interceptor_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_yavin_rebel_13", true)

-- Mission 2: Inspect
inspect_yavin_rebel_14 = SpaceInspectScreenplay:new {
	className = "inspect_yavin_rebel_14",

	questName = "yavin_rebel_14",
	questType = "inspect",

	questZone = "space_yavin4",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/droid_interface/ddi_mission_reward_rebel_moncal_d22.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	shipList = {"yavin_mission_2_shuttle"},

	validSpawns = {
		{spawnName = "yavin_rebel_2_shuttle", x = 1405, z = 2111, y = 4328},
	},

	giveSpawnWaypoint = 1,

	cargo = "patrol_routes",
}

registerScreenPlay("inspect_yavin_rebel_14", true)

-- Mission 3: Inspect with surprise attack
inspect_yavin_rebel_15 = SpaceInspectScreenplay:new {
	className = "inspect_yavin_rebel_15",

	questName = "yavin_rebel_15",
	questType = "inspect",

	questZone = "space_lok",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/booster/bst_mission_reward_rebel_novaldex_hypernova.iff"},
	},

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "yavin_rebel_15",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.INSPECTION,

	sideQuestInspectCount = 1,
	sideQuestDelay = 5,

	shipList = {"yavin_mission_3_shuttle"},

	validSpawns = {
		{spawnName = "yavin_rebel_mission_3", x = -5150, z = 2430, y = 586},
	},

	giveSpawnWaypoint = 1,

	-- SWG's literal: no ship carries it, the first inspection splits the quest (deliberate; do not change it to bomb_trigger)
	cargo = "placeholder",
}

registerScreenPlay("inspect_yavin_rebel_15", true)

destroy_surpriseattack_yavin_rebel_15 = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_yavin_rebel_15",

	questName = "yavin_rebel_15",
	questType = "destroy_surpriseattack",

	questZone = "space_lok",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "inspect_yavin_rebel_15",
	parentQuestType = "inspect",
	parentQuestName = "yavin_rebel_15",

	surpriseAttackShips = {
		zone = "space_lok",
		spawns = {{count = 3, shipName = "imp_tie_interceptor_tier2"}},
	},
}

registerScreenPlay("destroy_surpriseattack_yavin_rebel_15", true)

-- Mission 4: Escort
escort_yavin_rebel_16 = SpaceEscortScreenplay:new {
	className = "escort_yavin_rebel_16",

	questName = "yavin_rebel_16",
	questType = "escort",

	questZone = "space_lok",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon/wpn_mission_reward_rebel_taim_ion_driver.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"nym_smuggler"},

	escortPoints = {
		{patrolPointName = "rebel_station_escort_1", zoneName = "space_lok", x = -3200, z = -1000, y = 2800, escortNumber = 1, radius = 250},
		{patrolPointName = "rebel_station_escort_2", zoneName = "space_lok", x = -3065, z = -1116, y = 1459, escortNumber = 2, radius = 250},
		{patrolPointName = "rebel_station_escort_3", zoneName = "space_lok", x = -2831, z = -1251, y = -120, escortNumber = 3, radius = 250},
		{patrolPointName = "rebel_station_escort_4", zoneName = "space_lok", x = -2069, z = -1687, y = -881, escortNumber = 4, radius = 250},
	},

	attackDelay = 70,

	attackShips = {
		{"imp_tie_interceptor_tier2", "imp_tie_interceptor_tier2", "imp_tie_interceptor_tier2"},
		{"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier2", "imp_tie_interceptor_tier2"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_yavin_rebel_16", true)

-- Major Eker Duty Missions
recovery_duty_yavin_rebel_12 = SpaceDutyRecoveryScreenplay:new {
	className = "recovery_duty_yavin_rebel_12",

	questName = "yavin_rebel_12",
	questType = "recovery_duty",

	questZone = "space_yavin4",

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
		{patrolPointName = "rebel_recovery_duty_1", x = -1016, z = -448, y = -48, escortNumber = 1, radius = 250},
		{patrolPointName = "rebel_recovery_duty_2", x = -1583, z = 1682, y = 1378, escortNumber = 2, radius = 250},
		{patrolPointName = "rebel_recovery_duty_3", x = -3793, z = 3683, y = 2507, escortNumber = 3, radius = 250},
		{patrolPointName = "rebel_recovery_duty_4", x = -5529, z = 4928, y = 6105, escortNumber = 4, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "rebel_recovery_duty_5", x = -1695, z = 3416, y = 3329, escortNumber = 1, radius = 250},
		{patrolPointName = "rebel_recovery_duty_6", x = -1140, z = 2792, y = 3235, escortNumber = 2, radius = 250},
		{patrolPointName = "rebel_recovery_duty_7", x = -594, z = 2177, y = 3143, escortNumber = 3, radius = 250},
		{patrolPointName = "rebel_recovery_duty_8", x = 76, z = 1421, y = 3029, escortNumber = 4, radius = 250},
	},

	attackDelay = 100,

	attackShips = {
		{"imp_tie_interceptor_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
		{"imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_duty_yavin_rebel_12", true)

escort_duty_yavin_rebel_10 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_yavin_rebel_10",

	questName = "yavin_rebel_10",
	questType = "escort_duty",

	questZone = "space_yavin4",

	creditReward = 2500,
	creditKillBonus = 200,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {
		"reb_freighterheavy_tier2", "reb_freighterlight_tier2", "reb_freightermedium_tier2", "reb_ykl37r_tier2", "reb_ykl37r_tier2",
	},

	escortPoints = {
		{patrolPointName = "rebel_escort_duty_1", zoneName = "space_yavin4", x = 2160, z = 2400, y = -4650, escortNumber = 1, radius = 250},
		{patrolPointName = "rebel_escort_duty_2", zoneName = "space_yavin4", x = 3217, z = 1698, y = -3192, escortNumber = 2, radius = 250},
		{patrolPointName = "rebel_escort_duty_3", zoneName = "space_yavin4", x = 4272, z = 754, y = -1584, escortNumber = 3, radius = 250},
		{patrolPointName = "rebel_escort_duty_4", zoneName = "space_yavin4", x = 4952, z = 206, y = -635, escortNumber = 4, radius = 250},
		{patrolPointName = "rebel_escort_duty_5", zoneName = "space_yavin4", x = 6448, z = -112, y = -441, escortNumber = 5, radius = 250},
	},

	attackDelay = 80,

	attackShips = {
		{"imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
		{"imp_tie_interceptor_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
		{"imp_tie_bomber_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_yavin_rebel_10", true)

destroy_duty_yavin_rebel_9 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_yavin_rebel_9",

	questName = "yavin_rebel_9",
	questType = "destroy_duty",

	questZone = "space_yavin4",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	totalLevels = 5,
	totalRounds = 4,
	totalWaves = 1,

	bossShip = "hutt_pirate_s02_tier3",
	shipTypes = {
		{"hutt_fighter_s01_tier2", "hutt_fighter_s01_tier2", "hutt_pirate_s01_tier2"},
	},
}

registerScreenPlay("destroy_duty_yavin_rebel_9", true)

--[[
	Tier 3 -- Arnecio Ulvaw'op (Dathomir, science outpost; Dathomir, Dantooine, Lok and Endor systems)
	Trainer: Arnecio Ulvaw'op (conversation ulvawopConvoHandler), Dathomir science outpost (screenplays/cities/dathomir_science_outpost.lua:64). 17 quest tables for the 17 SWG-Source names tatooine_rebel_tier3_1..4 and their splits (recovery, delivery, survival, escort, inspect, destroy_surpriseattack, assassinate, space_battle, patrol, delivery_no_pickup), from datatables/spacequest and tatooine_rebel_tier3.java; feature crimson-phoenix-tier3-ulvawop-missions
	Mission 2 hands off from Dathomir to Dantooine (assassinate tatooine_rebel_tier3_2_b); mission 3's delivery picks up in Lok and delivers in Dathomir (deliveryZone)
]]

-- Mission 1: Recovery > Delivery > Survival > Escort
recovery_tatooine_rebel_tier3_1 = SpaceRecoveryScreenplay:new {
	className = "recovery_tatooine_rebel_tier3_1",

	questName = "tatooine_rebel_tier3_1",
	questType = "recovery",

	questZone = "space_dathomir",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/armor/arm_mission_reward_rebel_corellian_triplate.iff"},
	},

	sideQuest = true,
	sideQuestType = "delivery",
	sideQuestName = "tatooine_rebel_tier3_1_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	arrivalDelay = 10,
	recoveryDelay = 30,
	recoverShip = "lambdashuttle_rebel_tier3_1_officer",
	recoveryConversationMobile = "object/mobile/shared_ig_assassin_droid.iff",
	escortShips = {"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
	preRecoveryPoints = {
		{patrolPointName = "tatooine_rebel_tier3_1_escort_1", x = -2600, z = 1250, y = 3950, escortNumber = 1, radius = 250},
		{patrolPointName = "tatooine_rebel_tier3_1_escort_2", x = -3385, z = 992, y = 3576, escortNumber = 2, radius = 250},
		{patrolPointName = "tatooine_rebel_tier3_1_escort_3", x = -4153, z = 742, y = 3237, escortNumber = 3, radius = 250},
		{patrolPointName = "tatooine_rebel_tier3_1_escort_4", x = -4907, z = 592, y = 2027, escortNumber = 4, radius = 250},
		{patrolPointName = "tatooine_rebel_tier3_1_escort_5", x = -5134, z = 384, y = 788, escortNumber = 5, radius = 250},
		{patrolPointName = "tatooine_rebel_tier3_1_escort_6", x = -6083, z = 222, y = -852, escortNumber = 6, radius = 250},
	},
	recoveryPoints = {
		{patrolPointName = "tatooine_rebel_tier3_1_recovery_1", x = -4428, z = 525, y = 2549, escortNumber = 1, radius = 250},
		{patrolPointName = "tatooine_rebel_tier3_1_recovery_2", x = -3736, z = 462, y = 2153, escortNumber = 2, radius = 250},
		{patrolPointName = "tatooine_rebel_tier3_1_recovery_3", x = -2477, z = 314, y = 1389, escortNumber = 3, radius = 250},
		{patrolPointName = "tatooine_rebel_tier3_1_recovery_4", x = -739, z = 135, y = 411, escortNumber = 4, radius = 250},
	},
	attackDelay = 60,
	attackShips = {
		{"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_interceptor_tier3"},
	},
	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_tatooine_rebel_tier3_1", true)

delivery_tatooine_rebel_tier3_1_a = SpaceDeliveryScreenplay:new {
	className = "delivery_tatooine_rebel_tier3_1_a",

	questName = "tatooine_rebel_tier3_1_a",
	questType = "delivery",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "survival",
	sideQuestName = "tatooine_rebel_tier3_1_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 10,

	parentQuest = "recovery_tatooine_rebel_tier3_1",
	parentQuestType = "recovery",
	parentQuestName = "tatooine_rebel_tier3_1",

	pickupShip = "lambdashuttle_rebel_tier3_1_a_spies",
	deliveryShip = "reb_gunboat_tier3",
	pickupPoint = {patrolPointName = "tatooine_rebel_tier3_1_a_pickup", x = 45, z = -750, y = -2563},
	deliveryPoint = {patrolPointName = "tatooine_rebel_tier3_1_a_delivery", x = 3523, z = -789, y = -3670},
	attackShipLists = {
		{"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
		{"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
	},
	attackPeriod = 60,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM,
}

registerScreenPlay("delivery_tatooine_rebel_tier3_1_a", true)

survival_tatooine_rebel_tier3_1_b = SpaceSurvivalScreenplay:new {
	className = "survival_tatooine_rebel_tier3_1_b",

	questName = "tatooine_rebel_tier3_1_b",
	questType = "survival",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "tatooine_rebel_tier3_1_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	parentQuest = "delivery_tatooine_rebel_tier3_1_a",
	parentQuestType = "delivery",
	parentQuestName = "tatooine_rebel_tier3_1_a",

	transmissionPoint = {patrolPointName = "tatooine_rebel_tier3_1_b_survival", x = 1411, z = -444, y = -1499},
	totalTransmissionTime = 200,
	timesToUpdateProgress = 3,
	transmissionStartDelay = 5,
	delayToFirstAttack = 10,
	attackShipLists = {
		{"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
		{"imp_tie_bomber_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
	},
	attackPeriod = 60,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("survival_tatooine_rebel_tier3_1_b", true)

escort_tatooine_rebel_tier3_1_c = SpaceEscortScreenplay:new {
	className = "escort_tatooine_rebel_tier3_1_c",

	questName = "tatooine_rebel_tier3_1_c",
	questType = "escort",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "survival_tatooine_rebel_tier3_1_b",
	parentQuestType = "survival",
	parentQuestName = "tatooine_rebel_tier3_1_b",

	escortShips = {"lambdashuttle_rebel_tier3_1_a_spies"},
	escortPoints = {
		{patrolPointName = "tatooine_rebel_tier3_1_c_escort_1", x = -2300, z = 3250, y = 2950, zoneName = "space_dathomir", escortNumber = 1, radius = 250},
		{patrolPointName = "tatooine_rebel_tier3_1_c_escort_2", x = -1740, z = 2006, y = 1861, zoneName = "space_dathomir", escortNumber = 2, radius = 250},
		{patrolPointName = "tatooine_rebel_tier3_1_c_escort_3", x = -697, z = 1383, y = 2052, zoneName = "space_dathomir", escortNumber = 3, radius = 250},
		{patrolPointName = "tatooine_rebel_tier3_1_c_escort_4", x = -281, z = 843, y = 893, zoneName = "space_dathomir", escortNumber = 4, radius = 250},
	},
	attackDelay = 45,
	attackShips = {
		{"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
		{"imp_tie_advanced_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
	},
	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_tatooine_rebel_tier3_1_c", true)

-- Mission 2: Inspect > Surprise attack > Assassinate (Dantooine) > Space battle (Dantooine)
inspect_tatooine_rebel_tier3_2 = SpaceInspectScreenplay:new {
	className = "inspect_tatooine_rebel_tier3_2",

	questName = "tatooine_rebel_tier3_2",
	questType = "inspect",

	questZone = "space_dathomir",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon_capacitor/cap_mission_reward_rebel_qualdex_battery_array.iff"},
	},

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "tatooine_rebel_tier3_2_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 8,

	shipList = {"tatooine_tier3_2_inspect_awing", "tatooine_tier3_2_inspect_bwing", "tatooine_tier3_2_inspect_xwing", "tatooine_tier3_2_inspect_ywing"},
	validSpawns = {
		{spawnName = "tatooine_rebel_tier3_2_suspect_1", x = 5585, z = 4809, y = -2403},
		{spawnName = "tatooine_rebel_tier3_2_suspect_2", x = 4719, z = 5053, y = -3111},
	},
	giveSpawnWaypoint = 1,
	cargo = "thermal_bomb",
}

registerScreenPlay("inspect_tatooine_rebel_tier3_2", true)

destroy_surpriseattack_tatooine_rebel_tier3_2_a = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_tatooine_rebel_tier3_2_a",

	questName = "tatooine_rebel_tier3_2_a",
	questType = "destroy_surpriseattack",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "tatooine_rebel_tier3_2_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 8,

	parentQuest = "inspect_tatooine_rebel_tier3_2",
	parentQuestType = "inspect",
	parentQuestName = "tatooine_rebel_tier3_2",

	surpriseAttackShips = {
		zone = "space_dathomir",
		spawns = {{count = 3, shipName = "imp_tie_interceptor_tier3"}},
	},
}

registerScreenPlay("destroy_surpriseattack_tatooine_rebel_tier3_2_a", true)

assassinate_tatooine_rebel_tier3_2_b = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_rebel_tier3_2_b",

	questName = "tatooine_rebel_tier3_2_b",
	questType = "assassinate",

	questZone = "space_dantooine",

	sideQuest = true,
	sideQuestType = "space_battle",
	sideQuestName = "tatooine_rebel_tier3_2_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	parentQuest = "destroy_surpriseattack_tatooine_rebel_tier3_2_a",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "tatooine_rebel_tier3_2_a",

	arrivalDelay = 10,
	failTimer = 20,
	mustDestroyEscort = false,
	assassinateSpawns = {
		target = "tatooine_tier3_2_b_inquisitor",
		escorts = {"tatooine_tier3_2_b_guard", "tatooine_tier3_2_b_guard", "tatooine_tier3_2_b_guard"},
	},
	targetPatrols = {
		{patrolPointName = "tatooine_tier3_2_b_escape_1", x = 2850, z = -4260, y = 3800},
		{patrolPointName = "tatooine_tier3_2_b_escape_2", x = 3723, z = -3570, y = 2929},
		{patrolPointName = "tatooine_tier3_2_b_escape_3", x = 4217, z = -2877, y = 2337},
		{patrolPointName = "tatooine_tier3_2_b_escape_4", x = 4768, z = -2089, y = 1703},
		{patrolPointName = "tatooine_tier3_2_b_escape_5", x = 5546, z = -1155, y = 820},
		{patrolPointName = "tatooine_tier3_2_b_escape_6", x = 6572, z = -120, y = -68},
	},
}

registerScreenPlay("assassinate_tatooine_rebel_tier3_2_b", true)

space_battle_tatooine_rebel_tier3_2_c = SpaceBattleScreenplay:new {
	className = "space_battle_tatooine_rebel_tier3_2_c",

	questName = "tatooine_rebel_tier3_2_c",
	questType = "space_battle",

	questZone = "space_dantooine",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "assassinate_tatooine_rebel_tier3_2_b",
	parentQuestType = "assassinate",
	parentQuestName = "tatooine_rebel_tier3_2_b",

	battlePoint = {patrolPointName = "tatooine_rebel_tier3_2_c_battlepoint", x = -2871, z = -5018, y = 4524, forward = {x = -0.223158, z = -0.900013, y = 0.374402}},
	damageMultiplier = 6,
	allyArrivalDelay = 60,
	enemyArrivalDelay = 75,
	allyOriginDist = 600,
	enemyOriginDist = -800,
	allyArrivalDist = 20,
	enemyArrivalDist = -200,
	allyForce = {"reb_bwing_tier3", "reb_bwing_tier3", "reb_bwing_tier3"},
	enemyForce = {"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
}

registerScreenPlay("space_battle_tatooine_rebel_tier3_2_c", true)

-- Mission 3: Delivery (Lok to Dathomir) > Space battle > Escort > Survival
delivery_tatooine_rebel_tier3_3 = SpaceDeliveryScreenplay:new {
	className = "delivery_tatooine_rebel_tier3_3",

	questName = "tatooine_rebel_tier3_3",
	questType = "delivery",

	questZone = "space_lok",
	deliveryZone = "space_dathomir",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/engine/eng_mission_reward_rebel_incom_military.iff"},
	},

	sideQuest = true,
	sideQuestType = "space_battle",
	sideQuestName = "tatooine_rebel_tier3_3_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 8,

	pickupShip = "nym_smuggler",
	deliveryShip = "smuggler_yt1300_tier2",
	pickupPoint = {patrolPointName = "tatooine_rebel_tier3_3_pickup", x = -3950, z = -1000, y = 3800},
	deliveryPoint = {patrolPointName = "tatooine_rebel_tier3_3_delivery", x = 400, z = -5100, y = 800},
	attackShipLists = {
		{"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_interceptor_tier3"},
		{"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
	},
	attackPeriod = 110,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM,
}

registerScreenPlay("delivery_tatooine_rebel_tier3_3", true)

space_battle_tatooine_rebel_tier3_3_a = SpaceBattleScreenplay:new {
	className = "space_battle_tatooine_rebel_tier3_3_a",

	questName = "tatooine_rebel_tier3_3_a",
	questType = "space_battle",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "tatooine_rebel_tier3_3_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	parentQuest = "delivery_tatooine_rebel_tier3_3",
	parentQuestType = "delivery",
	parentQuestName = "tatooine_rebel_tier3_3",

	battlePoint = {patrolPointName = "tatooine_rebel_tier3_3_a_battlepoint", x = -2904, z = 2100, y = -1200, forward = {x = 0.937720, z = -0.026811, y = 0.346356}},
	damageMultiplier = 6,
	allyArrivalDelay = 110,
	enemyArrivalDelay = 140,
	allyOriginDist = 800,
	enemyOriginDist = -750,
	allyArrivalDist = 100,
	enemyArrivalDist = -100,
	allyForce = {"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
	enemyForce = {"lambdashuttle_advanced_recon", "imp_lambda_shuttle_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
}

registerScreenPlay("space_battle_tatooine_rebel_tier3_3_a", true)

escort_tatooine_rebel_tier3_3_b = SpaceEscortScreenplay:new {
	className = "escort_tatooine_rebel_tier3_3_b",

	questName = "tatooine_rebel_tier3_3_b",
	questType = "escort",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "survival",
	sideQuestName = "tatooine_rebel_tier3_3_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 8,

	parentQuest = "space_battle_tatooine_rebel_tier3_3_a",
	parentQuestType = "space_battle",
	parentQuestName = "tatooine_rebel_tier3_3_a",

	escortShips = {"tatooine_rebel_3_3_b_smuggler_yt1300_tier3"},
	escortPoints = {
		{patrolPointName = "tatooine_tier3_3_b_escort_1", x = -3641, z = 2261, y = -2029, zoneName = "space_dathomir", escortNumber = 1, radius = 250},
		{patrolPointName = "tatooine_tier3_3_b_escort_2", x = -2298, z = 1181, y = -2833, zoneName = "space_dathomir", escortNumber = 2, radius = 250},
		{patrolPointName = "tatooine_tier3_3_b_escort_3", x = -1589, z = 894, y = -3630, zoneName = "space_dathomir", escortNumber = 3, radius = 250},
		{patrolPointName = "tatooine_tier3_3_b_escort_4", x = 895, z = -2, y = -5996, zoneName = "space_dathomir", escortNumber = 4, radius = 250},
	},
	attackDelay = 50,
	attackShips = {
		{"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"imp_tie_bomber_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
	},
	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_tatooine_rebel_tier3_3_b", true)

survival_tatooine_rebel_tier3_3_c = SpaceSurvivalScreenplay:new {
	className = "survival_tatooine_rebel_tier3_3_c",

	questName = "tatooine_rebel_tier3_3_c",
	questType = "survival",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "escort_tatooine_rebel_tier3_3_b",
	parentQuestType = "escort",
	parentQuestName = "tatooine_rebel_tier3_3_b",

	transmissionPoint = {patrolPointName = "tatooine_tier3_3_b_escort_4", x = 895, z = -2, y = -5996},
	totalTransmissionTime = 200,
	timesToUpdateProgress = 4,
	transmissionStartDelay = 5,
	delayToFirstAttack = 10,
	attackShipLists = {
		{"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"imp_tie_interceptor_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"imp_tie_bomber_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
	},
	attackPeriod = 60,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("survival_tatooine_rebel_tier3_3_c", true)

-- Mission 4: Assassinate > Patrol > Surprise attack > Delivery (no pickup) > Space battle
assassinate_tatooine_rebel_tier3_4 = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_rebel_tier3_4",

	questName = "tatooine_rebel_tier3_4",
	questType = "assassinate",

	questZone = "space_endor",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/reactor/rct_mission_reward_rebel_slayn_hypervortex.iff"},
	},

	sideQuest = true,
	sideQuestType = "patrol",
	sideQuestName = "tatooine_rebel_tier3_4_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5,

	arrivalDelay = 10,
	failTimer = 20,
	mustDestroyEscort = false,
	assassinateSpawns = {
		target = "imp_tie_advanced_tier4",
		escorts = {"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"},
	},
	targetPatrols = {
		{patrolPointName = "tatooine_rebel_tier3_4_escort_1", x = -2000, z = -4256, y = 3250},
		{patrolPointName = "tatooine_rebel_tier3_4_escort_2", x = -1798, z = -3966, y = 3935},
		{patrolPointName = "tatooine_rebel_tier3_4_escort_3", x = -1562, z = -3260, y = 4734},
		{patrolPointName = "tatooine_rebel_tier3_4_escort_4", x = -1156, z = -2480, y = 5935},
		{patrolPointName = "tatooine_rebel_tier3_4_escort_5", x = 4, z = -1362, y = 6827},
		{patrolPointName = "tatooine_rebel_tier3_4_escort_6", x = 1485, z = 488, y = 5203},
	},
}

registerScreenPlay("assassinate_tatooine_rebel_tier3_4", true)

patrol_tatooine_rebel_tier3_4_a = SpacePatrolScreenplay:new {
	className = "patrol_tatooine_rebel_tier3_4_a",

	questName = "tatooine_rebel_tier3_4_a",
	questType = "patrol",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "tatooine_rebel_tier3_4_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 3,
	sideQuestDelay = 4,

	parentQuest = "assassinate_tatooine_rebel_tier3_4",
	parentQuestType = "assassinate",
	parentQuestName = "tatooine_rebel_tier3_4",

	patrolPoints = {
		{patrolPointName = "tatooine_rebel_tier3_4_a_patrol_1", x = -4200, z = -4000, y = -5000, patrolNumber = 1, radius = 150},
		{patrolPointName = "tatooine_rebel_tier3_4_a_patrol_2", x = -4648, z = -4197, y = -5804, patrolNumber = 2, radius = 150},
		{patrolPointName = "tatooine_rebel_tier3_4_a_patrol_3", x = -5046, z = -4899, y = -6558, patrolNumber = 3, radius = 150},
		{patrolPointName = "tatooine_rebel_tier3_4_a_patrol_4", x = -5851, z = -4452, y = -6545, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_tatooine_rebel_tier3_4_a", true)

destroy_surpriseattack_tatooine_rebel_tier3_4_b = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_tatooine_rebel_tier3_4_b",

	questName = "tatooine_rebel_tier3_4_b",
	questType = "destroy_surpriseattack",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "delivery_no_pickup",
	sideQuestName = "tatooine_rebel_tier3_4_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 8,

	parentQuest = "patrol_tatooine_rebel_tier3_4_a",
	parentQuestType = "patrol",
	parentQuestName = "tatooine_rebel_tier3_4_a",

	surpriseAttackShips = {
		zone = "space_endor",
		spawns = {{count = 3, shipName = "imp_tie_advanced_tier3"}},
	},
}

registerScreenPlay("destroy_surpriseattack_tatooine_rebel_tier3_4_b", true)

delivery_no_pickup_tatooine_rebel_tier3_4_c = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_tatooine_rebel_tier3_4_c",

	questName = "tatooine_rebel_tier3_4_c",
	questType = "delivery_no_pickup",

	questZone = "space_endor",

	sideQuest = true,
	sideQuestType = "space_battle",
	sideQuestName = "tatooine_rebel_tier3_4_d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 8,

	parentQuest = "destroy_surpriseattack_tatooine_rebel_tier3_4_b",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "tatooine_rebel_tier3_4_b",

	deliveryShip = "rebel_smuggler_tier3",
	deliveryPoint = {patrolPointName = "tatooine_rebel_tier3_4_c_delivery", x = -2344, z = -1799, y = -1343},
	attackShipLists = {
		{"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"imp_tie_interceptor_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
	},
	attackPeriod = 90,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM,
}

registerScreenPlay("delivery_no_pickup_tatooine_rebel_tier3_4_c", true)

space_battle_tatooine_rebel_tier3_4_d = SpaceBattleScreenplay:new {
	className = "space_battle_tatooine_rebel_tier3_4_d",

	questName = "tatooine_rebel_tier3_4_d",
	questType = "space_battle",

	questZone = "space_endor",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "delivery_no_pickup_tatooine_rebel_tier3_4_c",
	parentQuestType = "delivery_no_pickup",
	parentQuestName = "tatooine_rebel_tier3_4_c",

	battlePoint = {patrolPointName = "tatooine_rebel_tier3_4_d_battlepoint", x = -73, z = 584, y = -1550, forward = {x = 0.476736, z = 0.720442, y = -0.503672}},
	damageMultiplier = 6,
	allyArrivalDelay = 45,
	enemyArrivalDelay = 65,
	allyOriginDist = 600,
	enemyOriginDist = -650,
	allyArrivalDist = 150,
	enemyArrivalDist = -150,
	allyForce = {"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
	enemyForce = {"imp_tie_aggressor_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
}

registerScreenPlay("space_battle_tatooine_rebel_tier3_4_d", true)

--[[

	CrimsonPhoenixSquadronScreenplay

]]

CrimsonPhoenixSquadronScreenplay = ScreenPlay:new {
	screenplayName = "CrimsonPhoenixSquadronScreenplay",

	-- Tier 1 (Da'la Socuna); N is the trainer script's mission number
	QUEST_STRING_1 = {type = "patrol", name = "tatooine_rebel_1"},
	QUEST_STRING_1_SIDE = {type = "destroy_surpriseattack", name = "tatooine_rebel_1"},
	QUEST_STRING_2 = {type = "destroy", name = "tatooine_rebel_3"},
	QUEST_STRING_3 = {type = "patrol", name = "tatooine_rebel_2"},
	QUEST_STRING_3_SIDE = {type = "escort", name = "tatooine_rebel_2"},
	QUEST_STRING_4 = {type = "assassinate", name = "tatooine_rebel_4"},
	QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "tatooine_rebel_6"},
	QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "tatooine_rebel_7"},

	-- Tier 2 (Eker); N is the trainer script's mission number
	TIER2_QUEST_STRING_1 = {type = "escort", name = "yavin_rebel_13"},
	TIER2_QUEST_STRING_2 = {type = "inspect", name = "yavin_rebel_14"},
	TIER2_QUEST_STRING_3 = {type = "inspect", name = "yavin_rebel_15"},
	TIER2_QUEST_STRING_3_SIDE = {type = "destroy_surpriseattack", name = "yavin_rebel_15"},
	TIER2_QUEST_STRING_4 = {type = "escort", name = "yavin_rebel_16"},
	TIER2_QUEST_STRING_DUTY_1 = {type = "recovery_duty", name = "yavin_rebel_12"},
	TIER2_QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "yavin_rebel_10"},
	TIER2_QUEST_STRING_DUTY_3 = {type = "destroy_duty", name = "yavin_rebel_9"},

	-- Tier 3 (Ulvaw'op); N is the trainer script's mission number
	TIER3_QUEST_STRING_1 = {type = "recovery", name = "tatooine_rebel_tier3_1"},
	TIER3_QUEST_STRING_1_SIDE1 = {type = "delivery", name = "tatooine_rebel_tier3_1_a"},
	TIER3_QUEST_STRING_1_SIDE2 = {type = "survival", name = "tatooine_rebel_tier3_1_b"},
	TIER3_QUEST_STRING_1_SIDE3 = {type = "escort", name = "tatooine_rebel_tier3_1_c"},
	TIER3_QUEST_STRING_2 = {type = "inspect", name = "tatooine_rebel_tier3_2"},
	TIER3_QUEST_STRING_2_SIDE1 = {type = "destroy_surpriseattack", name = "tatooine_rebel_tier3_2_a"},
	TIER3_QUEST_STRING_2_SIDE2 = {type = "assassinate", name = "tatooine_rebel_tier3_2_b"},
	TIER3_QUEST_STRING_2_SIDE3 = {type = "space_battle", name = "tatooine_rebel_tier3_2_c"},
	TIER3_QUEST_STRING_3 = {type = "delivery", name = "tatooine_rebel_tier3_3"},
	TIER3_QUEST_STRING_3_SIDE1 = {type = "space_battle", name = "tatooine_rebel_tier3_3_a"},
	TIER3_QUEST_STRING_3_SIDE2 = {type = "escort", name = "tatooine_rebel_tier3_3_b"},
	TIER3_QUEST_STRING_3_SIDE3 = {type = "survival", name = "tatooine_rebel_tier3_3_c"},
	TIER3_QUEST_STRING_4 = {type = "assassinate", name = "tatooine_rebel_tier3_4"},
	TIER3_QUEST_STRING_4_SIDE1 = {type = "patrol", name = "tatooine_rebel_tier3_4_a"},
	TIER3_QUEST_STRING_4_SIDE2 = {type = "destroy_surpriseattack", name = "tatooine_rebel_tier3_4_b"},
	TIER3_QUEST_STRING_4_SIDE3 = {type = "delivery_no_pickup", name = "tatooine_rebel_tier3_4_c"},
	TIER3_QUEST_STRING_4_SIDE4 = {type = "space_battle", name = "tatooine_rebel_tier3_4_d"},

	-- SWG's ekerPilot space flag ("1" from Da'la Socuna; Major Eker reads it as set and writes "2" on the hand-in and "3" with mission 4's reward; tier 3 reads it as set)
	EKER_PILOT_KEY = "CrimsonPhoenixSquadronScreenplay:ekerPilot",
}

registerScreenPlay("CrimsonPhoenixSquadronScreenplay", false)

function CrimsonPhoenixSquadronScreenplay:start()
end

-- Clears Da'la Socuna's quests, journal entries and keys (surrender)
function CrimsonPhoenixSquadronScreenplay:resetSocunaQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	local tables = {
		patrol_tatooine_rebel_1, destroy_surpriseattack_tatooine_rebel_1, destroy_tatooine_rebel_3, patrol_tatooine_rebel_2,
		escort_tatooine_rebel_2, assassinate_tatooine_rebel_4, destroy_duty_tatooine_rebel_6, escort_duty_tatooine_rebel_7
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

	removeQuestStatus(playerID .. self.EKER_PILOT_KEY)
end

-- Clears Major Eker's quests, journal entries and keys (surrender)
function CrimsonPhoenixSquadronScreenplay:resetEkerQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	local tables = {
		escort_yavin_rebel_13, inspect_yavin_rebel_14, inspect_yavin_rebel_15, destroy_surpriseattack_yavin_rebel_15,
		escort_yavin_rebel_16, recovery_duty_yavin_rebel_12, escort_duty_yavin_rebel_10, destroy_duty_yavin_rebel_9
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.TIER2_QUEST_STRING_1, self.TIER2_QUEST_STRING_2, self.TIER2_QUEST_STRING_3, self.TIER2_QUEST_STRING_3_SIDE,
		self.TIER2_QUEST_STRING_4, self.TIER2_QUEST_STRING_DUTY_1, self.TIER2_QUEST_STRING_DUTY_2, self.TIER2_QUEST_STRING_DUTY_3
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	for _, questString in ipairs({self.TIER2_QUEST_STRING_1, self.TIER2_QUEST_STRING_2, self.TIER2_QUEST_STRING_3, self.TIER2_QUEST_STRING_4}) do
		removeQuestStatus(playerID .. questString.name .. ":attempted")
		removeQuestStatus(playerID .. questString.name .. ":reward")
	end
end

-- Clears Arnecio Ulvaw'op's quests, journal entries and keys (surrender)
function CrimsonPhoenixSquadronScreenplay:resetUlvawopQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	local tables = {
		recovery_tatooine_rebel_tier3_1, delivery_tatooine_rebel_tier3_1_a, survival_tatooine_rebel_tier3_1_b, escort_tatooine_rebel_tier3_1_c,
		inspect_tatooine_rebel_tier3_2, destroy_surpriseattack_tatooine_rebel_tier3_2_a, assassinate_tatooine_rebel_tier3_2_b, space_battle_tatooine_rebel_tier3_2_c,
		delivery_tatooine_rebel_tier3_3, space_battle_tatooine_rebel_tier3_3_a, escort_tatooine_rebel_tier3_3_b, survival_tatooine_rebel_tier3_3_c,
		assassinate_tatooine_rebel_tier3_4, patrol_tatooine_rebel_tier3_4_a, destroy_surpriseattack_tatooine_rebel_tier3_4_b,
		delivery_no_pickup_tatooine_rebel_tier3_4_c, space_battle_tatooine_rebel_tier3_4_d
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.TIER3_QUEST_STRING_1, self.TIER3_QUEST_STRING_1_SIDE1, self.TIER3_QUEST_STRING_1_SIDE2, self.TIER3_QUEST_STRING_1_SIDE3,
		self.TIER3_QUEST_STRING_2, self.TIER3_QUEST_STRING_2_SIDE1, self.TIER3_QUEST_STRING_2_SIDE2, self.TIER3_QUEST_STRING_2_SIDE3,
		self.TIER3_QUEST_STRING_3, self.TIER3_QUEST_STRING_3_SIDE1, self.TIER3_QUEST_STRING_3_SIDE2, self.TIER3_QUEST_STRING_3_SIDE3,
		self.TIER3_QUEST_STRING_4, self.TIER3_QUEST_STRING_4_SIDE1, self.TIER3_QUEST_STRING_4_SIDE2, self.TIER3_QUEST_STRING_4_SIDE3,
		self.TIER3_QUEST_STRING_4_SIDE4
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	for _, questString in ipairs({self.TIER3_QUEST_STRING_1, self.TIER3_QUEST_STRING_2, self.TIER3_QUEST_STRING_3, self.TIER3_QUEST_STRING_4}) do
		removeQuestStatus(playerID .. questString.name .. ":attempted")
		removeQuestStatus(playerID .. questString.name .. ":reward")
	end
end
