local SpaceHelpers = require("utils.space_helpers")

--[[

	Imperial Inquisition Squadron Quests

]]

--[[
	Tier 1 -- Lt. Barn Sinkko (Naboo)
	Ported from SWG-Source naboo_imperial_1..7 (patrol, destroy_surpriseattack, destroy, escort, assassinate, destroy_duty, escort_duty); feature inquisition-tier1-barn-sinkko
]]

-- Mission 1: Patrol with surprise attack
patrol_naboo_imperial_1 = SpacePatrolScreenplay:new {
	className = "patrol_naboo_imperial_1",

	questName = "naboo_imperial_1",
	questType = "patrol",

	questZone = "space_naboo",

	creditReward = 100,

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_imperial_1",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 10,

	patrolPoints = {
		{patrolPointName = "imperial_1", x = -3233, z = -12, y = -6147, patrolNumber = 1, radius = 150},
		{patrolPointName = "imperial_2", x = -4446, z = -731, y = -4772, patrolNumber = 2, radius = 150},
		{patrolPointName = "imperial_3", x = -4460, z = -1755, y = -2721, patrolNumber = 3, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_imperial_1", true)

destroy_surpriseattack_naboo_imperial_1 = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_imperial_1",

	questName = "naboo_imperial_1",
	questType = "destroy_surpriseattack",

	questZone = "space_naboo",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_naboo_imperial_1",
	parentQuestType = "patrol",
	parentQuestName = "naboo_imperial_1",

	surpriseAttackShips = {
		zone = "space_naboo",
		spawns = {{count = 2, shipName = "reb_xwing_tier1"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_imperial_1", true)

-- Mission 2: Destroy
destroy_naboo_imperial_2 = SpaceDestroyScreenplay:new {
	className = "destroy_naboo_imperial_2",

	questName = "naboo_imperial_2",
	questType = "destroy",

	questZone = "space_naboo",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	killsRequired = 4,

	shipLocations = {
		{spawnName = "rebel_defense_3", x = -5233, z = 6658, y = 6405},
		{spawnName = "rebel_generic_1", x = -172, z = -2813, y = -425},
		{spawnName = "rebel_cadet_1", x = -6416, z = -2568, y = -4512},
		{spawnName = "rebel_cadet_2", x = 4480, z = -4132, y = -6180},
		{spawnName = "rebel_cadet_3", x = 5492, z = 64, y = 2804},
	},

	shipTypes = {
		"reb_xwing_cadet_tier1",
	},
}

-- SWG tells an aborted mission 2 from a failed one (naboo_imperial_trainer_1.java hasAbortedMission2): the abort leaves a marker
function destroy_naboo_imperial_2:abortQuest(pPlayer)
	if (pPlayer ~= nil and SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		setQuestStatus(CreatureObject(pPlayer):getObjectID() .. self.questName .. ":aborted", 1)
	end

	SpaceDestroyScreenplay.abortQuest(self, pPlayer)
end

registerScreenPlay("destroy_naboo_imperial_2", true)

-- Mission 3: Patrol with escort side quest
patrol_naboo_imperial_3 = SpacePatrolScreenplay:new {
	className = "patrol_naboo_imperial_3",

	questName = "naboo_imperial_3",
	questType = "patrol",

	questZone = "space_naboo",

	creditReward = 500,
	itemReward = {
		{species = {SPECIES_WOOKIEE}, item = "object/tangible/wearables/bandolier/double_bandolier.iff"},
		{species = {SPECIES_ITHORIAN}, item = "object/tangible/wearables/bandolier/ith_double_bandolier.iff"},
		{species = {-1}, item = "object/tangible/wearables/bodysuit/bodysuit_tie_fighter.iff"},
	},

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "naboo_imperial_3",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 3,
	sideQuestDelay = 20,

	patrolPoints = {
		{patrolPointName = "naboo_imperial_patrol_1", x = -2455, z = 2645, y = -3905, patrolNumber = 1, radius = 150},
		{patrolPointName = "naboo_imperial_patrol_2", x = -2946, z = 2568, y = -2486, patrolNumber = 2, radius = 150},
		{patrolPointName = "naboo_imperial_patrol_3", x = -4439, z = 2882, y = -2263, patrolNumber = 3, radius = 150},
		{patrolPointName = "naboo_imperial_patrol_4", x = -5399, z = 2837, y = -2966, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_imperial_3", true)

escort_naboo_imperial_3 = SpaceEscortScreenplay:new {
	className = "escort_naboo_imperial_3",

	questName = "naboo_imperial_3",
	questType = "escort",

	questZone = "space_naboo",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_naboo_imperial_3",
	parentQuestType = "patrol",
	parentQuestName = "naboo_imperial_3",

	escortShips = {"imp_freighterheavy_e62_tier1"},

	escortPoints = {
		{patrolPointName = "naboo_imperial_escort_1", zoneName = "space_naboo", x = -4917, z = 2794, y = -2026, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_escort_2", zoneName = "space_naboo", x = -2934, z = 3049, y = -3022, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_escort_3", zoneName = "space_naboo", x = -930, z = 3507, y = -5308, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_escort_4", zoneName = "space_naboo", x = -5176, z = 3297, y = -6476, escortNumber = 4, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"reb_z95_tier1", "reb_z95_tier1"},
		{"reb_xwing_tier1"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_naboo_imperial_3", true)

-- Mission 4: Assassinate
assassinate_naboo_imperial_4 = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_imperial_4",

	questType = "assassinate",
	questName = "naboo_imperial_4",

	questZone = "space_naboo",

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
		target = "reb_xwing_leader_tier2",
		escorts = {"reb_xwing_tier1"},
	},

	targetPatrols = {
		{patrolPointName = "corellia_imperial_tier3_leg_4_assassinate_one_4", x = 10, z = -6423, y = -6953},
		{patrolPointName = "corellia_imperial_tier3_leg_4_assassinate_one_3", x = -990, z = -4783, y = -4961},
		{patrolPointName = "corellia_imperial_tier3_leg_4_assassinate_one_2", x = -1972, z = -1677, y = -2951},
		{patrolPointName = "corellia_imperial_tier3_leg_4_assassinate_one_1", x = -3939, z = 1474, y = -1521},
	},
}

registerScreenPlay("assassinate_naboo_imperial_4", true)

-- Barn Sinkko Duty Missions
destroy_duty_naboo_imperial_6 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_naboo_imperial_6",

	questName = "naboo_imperial_6",
	questType = "destroy_duty",

	questZone = "space_naboo",

	creditReward = 100,

	sideQuest = false,
	sideQuestType = "",

	totalLevels = 5,
	totalRounds = 2,
	totalWaves = 3,

	bossShip = "reb_xwing_tier2",
	shipTypes = {
		{"reb_xwing_tier1", "reb_xwing_tier1"},
		{"reb_ywing_tier1", "reb_ywing_tier1"},
	},
}

registerScreenPlay("destroy_duty_naboo_imperial_6", true)

escort_duty_naboo_imperial_7 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_naboo_imperial_7",

	questName = "naboo_imperial_7",
	questType = "escort_duty",

	questZone = "space_naboo",

	creditReward = 1000,
	creditKillBonus = 100,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {
		"freighterheavy_tier1", "freighterlight_tier1", "freightermedium_tier1",
		"imp_freightermedium_tier1", "imp_freighterlight_tier1", "imp_freighterheavy_tier1",
	},

	escortPoints = {
		{patrolPointName = "imperial_1", zoneName = "space_naboo", x = -3233, z = -12, y = -6147, escortNumber = 1, radius = 250},
		{patrolPointName = "imperial_2", zoneName = "space_naboo", x = -4446, z = -731, y = -4772, escortNumber = 2, radius = 250},
		{patrolPointName = "imperial_3", zoneName = "space_naboo", x = -4460, z = -1755, y = -2721, escortNumber = 3, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"reb_z95_tier1", "reb_ywing_tier1"},
		{"reb_ywing_tier1", "reb_ywing_tier1"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_naboo_imperial_7", true)

--[[
	Tier 2 -- Inquisitor Fa'Zoll (Naboo, Emperor's Retreat; Naboo and Dantooine)
	Ported from SWG-Source naboo_imperial_tier2_1..4 and the three tier 2 duties; feature inquisition-tier2-fa-zoll
]]

-- Mission 1: Inspect
inspect_naboo_imperial_tier2_1 = SpaceInspectScreenplay:new {
	className = "inspect_naboo_imperial_tier2_1",

	questName = "naboo_imperial_tier2_1",
	questType = "inspect",

	questZone = "space_naboo",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon/wpn_mission_reward_imperial_cygnus_starblaster.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	shipList = {"mercenary_courier_tier2"},
	validSpawns = {
		{spawnName = "naboo_imperial_tier2_inspect1_spawner", x = -1500, z = 1000, y = 3200},
	},
	giveSpawnWaypoint = 1,
	cargo = "encrypted_documents",
}

registerScreenPlay("inspect_naboo_imperial_tier2_1", true)

-- Mission 2: Survival (Dantooine)
survival_naboo_imperial_tier2_2 = SpaceSurvivalScreenplay:new {
	className = "survival_naboo_imperial_tier2_2",

	questName = "naboo_imperial_tier2_2",
	questType = "survival",

	questZone = "space_dantooine",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/armor/arm_mission_reward_imperial_sfs_light_military.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	transmissionPoint = {patrolPointName = "naboo_imperial_tier2_survival1", x = 4000, z = -2500, y = -5600},
	totalTransmissionTime = 300,
	timesToUpdateProgress = 10,
	transmissionStartDelay = 60,
	delayToFirstAttack = 10,

	attackShipLists = {
		{"reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2"},
		{"reb_z95_tier2", "reb_z95_tier2", "reb_z95_tier2"},
		{"reb_ywing_tier2", "reb_ywing_tier2", "reb_ywing_tier2"},
	},

	attackPeriod = 60,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("survival_naboo_imperial_tier2_2", true)

-- Mission 3: Recovery
recovery_naboo_imperial_tier2_3 = SpaceRecoveryScreenplay:new {
	className = "recovery_naboo_imperial_tier2_3",

	questName = "naboo_imperial_tier2_3",
	questType = "recovery",

	questZone = "space_naboo",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/booster/bst_mission_reward_imperial_rss_ion_booster.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	arrivalDelay = 25,
	recoveryDelay = 30,

	recoverShip = "colonel_hend_shuttle_tier3",

	escortShips = {"reb_z95_tier2", "reb_z95_tier2", "reb_z95_tier2", "reb_z95_tier2"},

	preRecoveryPoints = {
		{patrolPointName = "naboo_imperial_tier2_recovery1_1", x = -999, z = 0, y = 2999, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_recovery1_2", x = -1406, z = -2515, y = 2245, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_recovery1_3", x = 262, z = -3151, y = 332, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_recovery1_4", x = 3200, z = -3283, y = -4180, escortNumber = 4, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "naboo_imperial_tier2_recovery1_5", x = 3001, z = -1795, y = -3659, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_recovery1_6", x = 1813, z = 752, y = -2740, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_recovery1_7", x = 1416, z = 3650, y = -2137, escortNumber = 3, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2"},
		{"reb_xwing_tier2", "reb_xwing_tier2", "reb_ywing_tier2", "reb_ywing_tier2"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_naboo_imperial_tier2_3", true)

-- Mission 4: Assassinate (Dantooine)
assassinate_naboo_imperial_tier2_4 = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_imperial_tier2_4",

	questType = "assassinate",
	questName = "naboo_imperial_tier2_4",

	questZone = "space_dantooine",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/shield_generator/shd_mission_reward_imperial_rendili_dual_projector.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	arrivalDelay = 45,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "colonel_hend_shuttle_tier3",
		escorts = {"reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_imperial_tier2_assassinate1_1", x = -5000, z = 1000, y = -4500},
		{patrolPointName = "naboo_imperial_tier2_assassinate1_2", x = -3384, z = 2570, y = -1024},
		{patrolPointName = "naboo_imperial_tier2_assassinate1_3", x = -2204, z = 3766, y = 1598},
		{patrolPointName = "naboo_imperial_tier2_assassinate1_4", x = -1274, z = 2051, y = 3666},
		{patrolPointName = "naboo_imperial_tier2_assassinate1_5", x = -1474, z = 597, y = 5612},
	},
}

registerScreenPlay("assassinate_naboo_imperial_tier2_4", true)

-- Fa'Zoll Duty Missions
recovery_duty_naboo_imperial_tier2_recoveryduty = SpaceDutyRecoveryScreenplay:new {
	className = "recovery_duty_naboo_imperial_tier2_recoveryduty",

	questName = "naboo_imperial_tier2_recoveryduty",
	questType = "recovery_duty",

	questZone = "space_naboo",

	creditReward = 2500,
	creditKillBonus = 200,
	numResponses = 5,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	arrivalDelay = 20,
	recoveryDelay = 30,
	recoverShip = "naboo_miner_transport_tier2",
	recoveryConversationMobile = "object/mobile/shared_space_comm_imperial_tiefighter_01.iff",

	escortShips = {"naboo_miner_fighter_tier2", "naboo_miner_fighter_tier2", "naboo_miner_fighter_tier2"},

	preRecoveryPoints = {
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_1", x = 3331, z = -3465, y = -3994, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_2", x = 1333, z = -1855, y = -3915, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_3", x = -976, z = -14, y = -3990, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_4", x = -1492, z = 746, y = -2021, escortNumber = 4, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_5", x = -1376, z = 650, y = -2028, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_6", x = 417, z = -839, y = -2617, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_7", x = 2197, z = -2348, y = -3252, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_8", x = 3875, z = -3872, y = -3934, escortNumber = 4, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"reb_xwing_tier2", "reb_xwing_tier2"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_duty_naboo_imperial_tier2_recoveryduty", true)

escort_duty_naboo_imperial_tier2_escortduty = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_naboo_imperial_tier2_escortduty",

	questName = "naboo_imperial_tier2_escortduty",
	questType = "escort_duty",

	questZone = "space_naboo",

	creditReward = 2500,
	creditKillBonus = 200,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"imp_freightermedium_tier2", "imp_freighterlight_tier2", "imp_freighterheavy_tier2"},

	escortPoints = {
		{patrolPointName = "naboo_imperial_tier2_escortduty_1", zoneName = "space_naboo", x = 3190, z = -3175, y = 3169, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_escortduty_2", zoneName = "space_naboo", x = 856, z = -803, y = 781, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_escortduty_3", zoneName = "space_naboo", x = -244, z = 234, y = -206, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_escortduty_4", zoneName = "space_naboo", x = -1352, z = 1269, y = -1205, escortNumber = 4, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_escortduty_5", zoneName = "space_naboo", x = -2169, z = 2068, y = -2002, escortNumber = 5, radius = 250},
		{patrolPointName = "naboo_imperial_tier2_escortduty_6", zoneName = "space_naboo", x = -3203, z = 3201, y = -3078, escortNumber = 6, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"reb_xwing_tier2", "reb_ywing_tier2"},
		{"reb_xwing_tier2", "reb_xwing_tier2"},
		{"reb_z95_tier2", "reb_z95_tier2"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_naboo_imperial_tier2_escortduty", true)

destroy_duty_naboo_imperial_tier2_destroyduty = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_naboo_imperial_tier2_destroyduty",

	questName = "naboo_imperial_tier2_destroyduty",
	questType = "destroy_duty",

	questZone = "space_dantooine",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	totalLevels = 5,
	totalRounds = 2,
	totalWaves = 3,

	bossShip = "reb_xwing_tier3",
	shipTypes = {
		{"reb_xwing_tier2", "reb_xwing_tier2"},
	},
}

registerScreenPlay("destroy_duty_naboo_imperial_tier2_destroyduty", true)

--[[
	Tier 3 -- Inquisitor Vrke (Naboo, Emperor's Retreat; Naboo, Yavin 4 and Dathomir)
	Ported from SWG-Source naboo_imperial_tier3_1..4 and their splits (recovery, inspect, delivery_no_pickup, survival, delivery, destroy_surpriseattack, rescue, escort, space_battle, assassinate); feature inquisition-tier3-vrke
]]

-- Mission 1: Recovery > Inspect > Delivery (no pickup)
recovery_naboo_imperial_tier3_1 = SpaceRecoveryScreenplay:new {
	className = "recovery_naboo_imperial_tier3_1",

	questName = "naboo_imperial_tier3_1",
	questType = "recovery",

	questZone = "space_naboo",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon_capacitor/cap_mission_reward_imperial_rendili_k_class.iff"},
	},

	sideQuest = true,
	sideQuestType = "inspect",
	sideQuestName = "naboo_imperial_tier3_1_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	arrivalDelay = 30,
	recoveryDelay = 30,

	recoverShip = "colonel_hend_yacht_tier3",

	recoveryConversationMobile = "object/mobile/shared_space_comm_imperial_officer_01.iff",

	escortShips = {},

	preRecoveryPoints = {
		{patrolPointName = "naboo_imperial_tier3_recovery1_1", x = 3200, z = -2300, y = 1000, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier3_recovery1_2", x = 606, z = -1811, y = 2677, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier3_recovery1_3", x = -1560, z = -4222, y = 2922, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier3_recovery1_4", x = -2264, z = -4270, y = 4044, escortNumber = 4, radius = 250},
		{patrolPointName = "corellia_imperial_tier3_leg_4_assassinate_one_1", x = -3939, z = 1474, y = -1521, escortNumber = 5, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "naboo_imperial_tier3_recovery1_5", x = -3035, z = -4019, y = 3262, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier3_recovery1_6", x = -3564, z = -3047, y = -620, escortNumber = 2, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_ywing_tier3", "reb_ywing_tier3"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_naboo_imperial_tier3_1", true)

inspect_naboo_imperial_tier3_1_a = SpaceInspectScreenplay:new {
	className = "inspect_naboo_imperial_tier3_1_a",

	questName = "naboo_imperial_tier3_1_a",
	questType = "inspect",

	questZone = "space_yavin4",

	sideQuest = true,
	sideQuestType = "delivery_no_pickup",
	sideQuestName = "naboo_imperial_tier3_1_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "recovery_naboo_imperial_tier3_1",
	parentQuestType = "recovery",
	parentQuestName = "naboo_imperial_tier3_1",

	-- Screenplay Specific Variables
	shipList = {"mercenary_spy_fighter_tier4"},
	validSpawns = {
		{spawnName = "naboo_imperial_tier3_inspect1_spawner", x = 5000, z = -2300, y = 1020},
	},
	giveSpawnWaypoint = 1,
	cargo = "pirate_data",
}

registerScreenPlay("inspect_naboo_imperial_tier3_1_a", true)

delivery_no_pickup_naboo_imperial_tier3_1_b = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_naboo_imperial_tier3_1_b",

	questName = "naboo_imperial_tier3_1_b",
	questType = "delivery_no_pickup",

	questZone = "space_yavin4",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "inspect_naboo_imperial_tier3_1_a",
	parentQuestType = "inspect",
	parentQuestName = "naboo_imperial_tier3_1_a",

	-- Screenplay Specific Variables
	deliveryShip = "imp_freightermedium_tier3",
	deliveryPoint = {patrolPointName = "naboo_imperial_tier3_delivery1_dropoff", x = 1092, z = 842, y = 598},

	attackShipLists = {
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4"},
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4"},
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_ywing_tier3", "reb_ywing_tier3"},
		{"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3"},
	},

	attackPeriod = 90,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_no_pickup_naboo_imperial_tier3_1_b", true)

-- Mission 2: Inspect > Survival > Delivery > Recovery
inspect_naboo_imperial_tier3_2 = SpaceInspectScreenplay:new {
	className = "inspect_naboo_imperial_tier3_2",

	questName = "naboo_imperial_tier3_2",
	questType = "inspect",

	questZone = "space_yavin4",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/droid_interface/ddi_mission_reward_imperial_sfs_military_grade.iff"},
	},

	sideQuest = true,
	sideQuestType = "survival",
	sideQuestName = "naboo_imperial_tier3_2_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 15, -- Time in seconds to wait to trigger side quest

	-- Screenplay Specific Variables
	shipList = {"shinss_yacht_tier3"},
	validSpawns = {
		{spawnName = "naboo_imperial_tier3_shinssyacht_spawner", x = 3196, z = -6203, y = -5010},
	},
	giveSpawnWaypoint = 1,
	cargo = "shinss_personal_logs",
}

registerScreenPlay("inspect_naboo_imperial_tier3_2", true)

survival_naboo_imperial_tier3_2_a = SpaceSurvivalScreenplay:new {
	className = "survival_naboo_imperial_tier3_2_a",

	questName = "naboo_imperial_tier3_2_a",
	questType = "survival",

	questZone = "space_yavin4",

	sideQuest = true,
	sideQuestType = "delivery",
	sideQuestName = "naboo_imperial_tier3_2_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "inspect_naboo_imperial_tier3_2",
	parentQuestType = "inspect",
	parentQuestName = "naboo_imperial_tier3_2",

	-- Screenplay Specific Variables
	transmissionPoint = {patrolPointName = "naboo_imperial_tier3_survival1", x = 2016, z = -4500, y = 6816},
	totalTransmissionTime = 600,
	timesToUpdateProgress = 20,
	transmissionStartDelay = 45,
	delayToFirstAttack = 45,

	attackShipLists = {
		{"reb_ywing_tier3", "reb_ywing_tier3", "reb_ywing_tier3", "reb_ywing_tier3"},
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
		{"reb_z95_tier3", "reb_z95_tier3", "reb_z95_tier3", "reb_z95_tier3"},
		{"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3"},
		{"reb_bwing_tier3", "reb_bwing_tier3", "reb_bwing_tier3", "reb_bwing_tier3"},
	},

	attackPeriod = 90,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("survival_naboo_imperial_tier3_2_a", true)

delivery_naboo_imperial_tier3_2_b = SpaceDeliveryScreenplay:new {
	className = "delivery_naboo_imperial_tier3_2_b",

	questName = "naboo_imperial_tier3_2_b",
	questType = "delivery",

	questZone = "space_yavin4",

	sideQuest = true,
	sideQuestType = "recovery",
	sideQuestName = "naboo_imperial_tier3_2_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "survival_naboo_imperial_tier3_2_a",
	parentQuestType = "survival",
	parentQuestName = "naboo_imperial_tier3_2_a",

	-- SWG's own point name for the pickup is corellis_imperial_tier3_leg_2_rescue_3
	-- Screenplay Specific Variables
	pickupPoint = {patrolPointName = "corellis_imperial_tier3_leg_2_rescue_3", x = 1463, z = -2058, y = -568},
	deliveryPoint = {patrolPointName = "naboo_imperial_tier3_delivery1_dropoff", x = 1092, z = 842, y = 598},
	pickupShip = "imp_lambda_shuttle_tier3",
	deliveryShip = "imp_lambda_shuttle_tier3",

	attackShipLists = {
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
		{"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3"},
		{"reb_ywing_tier3", "reb_ywing_tier3", "reb_ywing_tier3", "reb_ywing_tier3"},
		{"reb_bwing_tier3", "reb_bwing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3"},
	},

	attackPeriod = 60,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_naboo_imperial_tier3_2_b", true)

recovery_naboo_imperial_tier3_2_c = SpaceRecoveryScreenplay:new {
	className = "recovery_naboo_imperial_tier3_2_c",

	questName = "naboo_imperial_tier3_2_c",
	questType = "recovery",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "delivery_naboo_imperial_tier3_2_b",
	parentQuestType = "delivery",
	parentQuestName = "naboo_imperial_tier3_2_b",

	arrivalDelay = 15,
	recoveryDelay = 30,

	recoverShip = "shinss_escape_shuttle_tier3",

	escortShips = {"shinss_escort_fighters_tier3", "shinss_escort_fighters_tier3", "shinss_escort_fighters_tier3", "shinss_escort_fighters_tier3", "shinss_escort_fighters_tier3"},

	preRecoveryPoints = {
		{patrolPointName = "naboo_imperial_tier3_recovery2_1", x = 1936, z = 2300, y = 4704, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier3_recovery2_2", x = -2361, z = 5226, y = 1662, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier3_recovery2_3", x = -3357, z = 741, y = -1890, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier3_recovery2_4", x = -440, z = -2779, y = -5776, escortNumber = 4, radius = 250},
		{patrolPointName = "naboo_imperial_tier3_recovery2_5", x = 4297, z = -3650, y = -6721, escortNumber = 5, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "naboo_imperial_tier3_recovery2_6", x = -3383, z = -3342, y = -3625, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier3_recovery2_7", x = -2154, z = -2127, y = -2311, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier3_recovery2_8", x = -459, z = -452, y = -498, escortNumber = 3, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_naboo_imperial_tier3_2_c", true)

-- Mission 3: Delivery > Surprise attack > Rescue > Inspect > Delivery (no pickup)
delivery_naboo_imperial_tier3_3 = SpaceDeliveryScreenplay:new {
	className = "delivery_naboo_imperial_tier3_3",

	questName = "naboo_imperial_tier3_3",
	questType = "delivery",

	questZone = "space_dathomir",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/reactor/rct_mission_reward_imperial_sds_high_output.iff"},
	},

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_imperial_tier3_3_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	-- Screenplay Specific Variables
	pickupPoint = {patrolPointName = "naboo_imperial_tier3_delivery3_pickup", x = 4824, z = -1000, y = 264},
	deliveryPoint = {patrolPointName = "naboo_imperial_tier3_delivery3_dropoff", x = -3608, z = 5628, y = 5256},
	pickupShip = "imp_lambda_shuttle_tier3",
	deliveryShip = "imp_lambda_shuttle_tier3",

	attackShipLists = {
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4"},
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4"},
		{"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier4"},
	},

	attackPeriod = 60,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_naboo_imperial_tier3_3", true)

destroy_surpriseattack_naboo_imperial_tier3_3_a = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_imperial_tier3_3_a",

	questName = "naboo_imperial_tier3_3_a",
	questType = "destroy_surpriseattack",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "rescue",
	sideQuestName = "naboo_imperial_tier3_3_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "delivery_naboo_imperial_tier3_3",
	parentQuestType = "delivery",
	parentQuestName = "naboo_imperial_tier3_3",

	-- Screenplay Specific Variables
	surpriseAttackShips = {
		zone = "space_dathomir",
		spawns = {
			{count = 7, shipName = "reb_xwing_tier3"},
		},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_imperial_tier3_3_a", true)

rescue_naboo_imperial_tier3_3_b = SpaceRescueScreenplay:new {
	className = "rescue_naboo_imperial_tier3_3_b",

	questName = "naboo_imperial_tier3_3_b",
	questType = "rescue",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "inspect",
	sideQuestName = "naboo_imperial_tier3_3_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "destroy_surpriseattack_naboo_imperial_tier3_3_a",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "naboo_imperial_tier3_3_a",

	-- Screenplay Specific Variables
	recoveryPath = {
		{patrolPointName = "naboo_imperial_tier3_rescue1_1", x = 4300, z = 6400, y = -4900},
		{patrolPointName = "naboo_imperial_tier3_rescue1_2", x = 222, z = 6250, y = -4778},
		{patrolPointName = "naboo_imperial_tier3_rescue1_3", x = -1638, z = 3789, y = -6552},
		{patrolPointName = "naboo_imperial_tier3_rescue1_4", x = -3555, z = 3445, y = -6578},
	},

	targetShipType = "imp_lambda_shuttle_tier3",
	targetArrivalDelay = 15,

	attackShipLists = {
		{"reb_ywing_tier3", "reb_ywing_tier3", "reb_ywing_tier3", "reb_ywing_tier3"},
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
		{"reb_ywing_tier4", "reb_ywing_tier4", "reb_xwing_tier3", "reb_xwing_tier3"},
	},

	attackPeriod = 90,
	attackListType = SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,

	numResponses = 5,
}

registerScreenPlay("rescue_naboo_imperial_tier3_3_b", true)

inspect_naboo_imperial_tier3_3_c = SpaceInspectScreenplay:new {
	className = "inspect_naboo_imperial_tier3_3_c",

	questName = "naboo_imperial_tier3_3_c",
	questType = "inspect",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "delivery_no_pickup",
	sideQuestName = "naboo_imperial_tier3_3_d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "rescue_naboo_imperial_tier3_3_b",
	parentQuestType = "rescue",
	parentQuestName = "naboo_imperial_tier3_3_b",

	-- Screenplay Specific Variables
	shipList = {"rebel_spyfreighter_tier3"},
	validSpawns = {
		{spawnName = "naboo_imperial_tier3_inspect3_spawner", x = 2005, z = 4299, y = -3566},
	},
	giveSpawnWaypoint = 1,
	cargo = "rebel_plans",
}

registerScreenPlay("inspect_naboo_imperial_tier3_3_c", true)

delivery_no_pickup_naboo_imperial_tier3_3_d = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_naboo_imperial_tier3_3_d",

	questName = "naboo_imperial_tier3_3_d",
	questType = "delivery_no_pickup",

	questZone = "space_naboo",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "inspect_naboo_imperial_tier3_3_c",
	parentQuestType = "inspect",
	parentQuestName = "naboo_imperial_tier3_3_c",

	-- Screenplay Specific Variables
	deliveryShip = "imp_lambda_shuttle_tier3",
	deliveryPoint = {patrolPointName = "naboo_imperial_tier3_delivery4", x = 1069, z = 1110, y = 263},

	attackShipLists = {
		{"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3"},
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier4"},
		{"reb_bwing_tier3", "reb_bwing_tier3", "reb_bwing_tier3", "reb_bwing_tier3"},
	},

	attackPeriod = 60,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_no_pickup_naboo_imperial_tier3_3_d", true)

-- Mission 4: Assassinate > Escort > Space battle > Assassinate
assassinate_naboo_imperial_tier3_4 = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_imperial_tier3_4",

	questType = "assassinate",
	questName = "naboo_imperial_tier3_4",

	questZone = "space_dathomir",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/engine/eng_mission_reward_imperial_cygnus_megadrive.iff"},
	},

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "naboo_imperial_tier3_4_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	arrivalDelay = 30,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "general_breckon_shuttle_tier4",
		escorts = {"breckon_escort_fighter_tier3", "breckon_escort_fighter_tier3", "breckon_escort_fighter_tier3", "breckon_escort_fighter_tier3", "breckon_escort_fighter_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_imperial_tier3_assassinate1_1", x = -1879, z = -110, y = -1881},
		{patrolPointName = "naboo_imperial_tier3_assassinate1_2", x = 19, z = -2029, y = -411},
		{patrolPointName = "naboo_imperial_tier3_assassinate1_3", x = 2767, z = -3788, y = 1500},
		{patrolPointName = "naboo_imperial_tier3_assassinate1_4", x = 4998, z = -4963, y = 2982},
	},
}

registerScreenPlay("assassinate_naboo_imperial_tier3_4", true)

escort_naboo_imperial_tier3_4_a = SpaceEscortScreenplay:new {
	className = "escort_naboo_imperial_tier3_4_a",

	questName = "naboo_imperial_tier3_4_a",
	questType = "escort",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "space_battle",
	sideQuestName = "naboo_imperial_tier3_4_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 15, -- Time in seconds to wait to trigger side quest

	parentQuest = "assassinate_naboo_imperial_tier3_4",
	parentQuestType = "assassinate",
	parentQuestName = "naboo_imperial_tier3_4",

	-- Screenplay Specific Variables
	escortShips = {"dathomir_prison_shuttle_tier4"},

	escortPoints = {
		{patrolPointName = "naboo_imperial_tier3_escort1_1", x = 7340, z = 2102, y = -3234, zoneName = "space_dathomir", escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier3_escort1_2", x = 5193, z = 2105, y = -998, zoneName = "space_dathomir", escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier3_escort1_3", x = 2192, z = 1097, y = -995, zoneName = "space_dathomir", escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier3_escort1_4", x = 1019, z = 509, y = -505, zoneName = "space_dathomir", escortNumber = 4, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
		{"reb_bwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
		{"reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3"},
		{"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_naboo_imperial_tier3_4_a", true)

space_battle_naboo_imperial_tier3_4_b = SpaceBattleScreenplay:new {
	className = "space_battle_naboo_imperial_tier3_4_b",

	questName = "naboo_imperial_tier3_4_b",
	questType = "space_battle",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "naboo_imperial_tier3_4_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "escort_naboo_imperial_tier3_4_a",
	parentQuestType = "escort",
	parentQuestName = "naboo_imperial_tier3_4_a",

	-- Screenplay Specific Variables
	battlePoint = {patrolPointName = "naboo_imperial_tier3_spacebattle1", x = 1303, z = 2316, y = 4521, forward = {x = -0.3808, z = -0.866842, y = -0.321834}},

	damageMultiplier = 5,

	allyArrivalDelay = 30,
	enemyArrivalDelay = 90,
	allyOriginDist = 400,
	enemyOriginDist = -400,
	allyArrivalDist = 300,
	enemyArrivalDist = 300,

	allyForce = {"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},

	enemyForce = {"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_awing_tier3", "reb_ywing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_awing_tier3", "reb_xwing_tier3"},
}

registerScreenPlay("space_battle_naboo_imperial_tier3_4_b", true)

assassinate_naboo_imperial_tier3_4_c = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_imperial_tier3_4_c",

	questType = "assassinate",
	questName = "naboo_imperial_tier3_4_c",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "space_battle_naboo_imperial_tier3_4_b",
	parentQuestType = "space_battle",
	parentQuestName = "naboo_imperial_tier3_4_b",

	-- SWG's own point names are naboo_imperial_tier4_recoveryduty1_4..7
	arrivalDelay = 30,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "reb_priceofliberty_tier3",
		escorts = {"reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_imperial_tier4_recoveryduty1_4", x = 3989, z = -1251, y = -6960},
		{patrolPointName = "naboo_imperial_tier4_recoveryduty1_5", x = 1495, z = -1773, y = -6461},
		{patrolPointName = "naboo_imperial_tier4_recoveryduty1_6", x = -1458, z = -2983, y = -5981},
		{patrolPointName = "naboo_imperial_tier4_recoveryduty1_7", x = -3969, z = -4072, y = -3508},
	},
}

registerScreenPlay("assassinate_naboo_imperial_tier3_4_c", true)

--[[
	Tier 4 -- Grand Inquisitor Ja'ce Yiaso (Naboo, Emperor's Retreat; Dathomir)
	Ported from SWG-Source naboo_imperial_tier4_1..4, their splits and the four tier 4 duties; feature inquisition-tier4-jace-yiaso
]]

-- Mission 1: Patrol > Inspect > Surprise attack > Delivery (no pickup)
patrol_naboo_imperial_tier4_1 = SpacePatrolScreenplay:new {
	className = "patrol_naboo_imperial_tier4_1",

	questName = "naboo_imperial_tier4_1",
	questType = "patrol",

	questZone = "space_dathomir",

	creditReward = 10000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon/wpn_mission_reward_imperial_sds_boltdriver.iff"},
	},

	sideQuest = true,
	sideQuestType = "inspect",
	sideQuestName = "naboo_imperial_tier4_1_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 25,

	patrolPoints = {
		{patrolPointName = "naboo_imperial_tier4_patrol1_1", x = 4262, z = 1755, y = -2347, patrolNumber = 1, radius = 150},
		{patrolPointName = "naboo_imperial_tier4_patrol1_2", x = 5506, z = 2853, y = -2063, patrolNumber = 2, radius = 150},
		{patrolPointName = "naboo_imperial_tier4_patrol1_3", x = 7049, z = 4215, y = -1712, patrolNumber = 3, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_imperial_tier4_1", true)

inspect_naboo_imperial_tier4_1_a = SpaceInspectScreenplay:new {
	className = "inspect_naboo_imperial_tier4_1_a",

	questName = "naboo_imperial_tier4_1_a",
	questType = "inspect",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_imperial_tier4_1_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 15, -- Time in seconds to wait to trigger side quest

	parentQuest = "patrol_naboo_imperial_tier4_1",
	parentQuestType = "patrol",
	parentQuestName = "naboo_imperial_tier4_1",

	-- Screenplay Specific Variables
	shipList = {"crystal_smuggler_yt1300_tier4"},
	validSpawns = {
		{spawnName = "naboo_imperial_tier4_inspect1_spawner", x = 7606, z = 4673, y = -1681},
	},
	giveSpawnWaypoint = 1,
	cargo = "glowing_crystals",
}

registerScreenPlay("inspect_naboo_imperial_tier4_1_a", true)

destroy_surpriseattack_naboo_imperial_tier4_1_b = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_imperial_tier4_1_b",

	questName = "naboo_imperial_tier4_1_b",
	questType = "destroy_surpriseattack",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "delivery_no_pickup",
	sideQuestName = "naboo_imperial_tier4_1_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "inspect_naboo_imperial_tier4_1_a",
	parentQuestType = "inspect",
	parentQuestName = "naboo_imperial_tier4_1_a",

	surpriseAttackShips = {
		zone = "space_dathomir",
		spawns = {{count = 6, shipName = "coynite_merc_pulsar_tier4"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_imperial_tier4_1_b", true)

delivery_no_pickup_naboo_imperial_tier4_1_c = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_naboo_imperial_tier4_1_c",

	questName = "naboo_imperial_tier4_1_c",
	questType = "delivery_no_pickup",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "destroy_surpriseattack_naboo_imperial_tier4_1_b",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "naboo_imperial_tier4_1_b",

	-- Screenplay Specific Variables
	deliveryShip = "imp_lambda_shuttle_tier4",
	deliveryPoint = {patrolPointName = "naboo_imperial_tier3_delivery3_pickup", x = 4824, z = -1000, y = 264},

	attackShipLists = {
			{"coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4"},
			{"coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},
		},

	attackPeriod = 90,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_no_pickup_naboo_imperial_tier4_1_c", true)

-- Mission 2: Recovery > Rescue > Surprise attack > Recovery
recovery_naboo_imperial_tier4_2 = SpaceRecoveryScreenplay:new {
	className = "recovery_naboo_imperial_tier4_2",

	questName = "naboo_imperial_tier4_2",
	questType = "recovery",

	questZone = "space_dathomir",

	creditReward = 10000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/shield_generator/shd_mission_reward_imperial_cygnus_holoscreen.iff"},
	},

	sideQuest = true,
	sideQuestType = "rescue",
	sideQuestName = "naboo_imperial_tier4_2_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	-- Screenplay Specific Variables
	arrivalDelay = 30,
	recoveryDelay = 30,
	recoverShip = "crystal_smuggler_heavy_tier4",

	escortShips = {},

	preRecoveryPoints = {
		{patrolPointName = "naboo_imperial_tier4_recovery1_1", x = 6480, z = -506, y = -2013, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery1_2", x = 5932, z = -978, y = 2960, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery1_3", x = 2864, z = -1390, y = 4050, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery1_4", x = -2176, z = -1720, y = 5470, escortNumber = 4, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery1_5", x = -28, z = -1930, y = 6578, escortNumber = 5, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "naboo_imperial_tier4_recovery1_6", x = 975, z = 225, y = 3781, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery1_7", x = -2095, z = 2334, y = 3374, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery1_8", x = -4455, z = 2935, y = 4075, escortNumber = 3, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
			{"coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4"},
			{"coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},
			{"coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4"},
		},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_naboo_imperial_tier4_2", true)

rescue_naboo_imperial_tier4_2_a = SpaceRescueScreenplay:new {
	className = "rescue_naboo_imperial_tier4_2_a",

	questName = "naboo_imperial_tier4_2_a",
	questType = "rescue",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_imperial_tier4_2_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "recovery_naboo_imperial_tier4_2",
	parentQuestType = "recovery",
	parentQuestName = "naboo_imperial_tier4_2",

	-- Screenplay Specific Variables
	recoveryPath = {
		{patrolPointName = "naboo_imperial_tier4_rescue1_1", x = -5889, z = 2454, y = 5119},
		{patrolPointName = "naboo_imperial_tier4_rescue1_2", x = -6996, z = 1990, y = 1981},
		{patrolPointName = "naboo_imperial_tier4_rescue1_3", x = -7528, z = 2452, y = -685},
		{patrolPointName = "naboo_imperial_tier4_rescue1_4", x = -7505, z = 2904, y = -2924},
	},

	targetShipType = "imp_lambda_recon_tier4",
	targetArrivalDelay = 30,

	attackShipLists = {
			{"coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},
			{"coynite_merc_neutron_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_quasar_tier4"},
			{"coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4"},
		},

	attackPeriod = 120,
	attackListType = SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
	numResponses = 5,
}

registerScreenPlay("rescue_naboo_imperial_tier4_2_a", true)

destroy_surpriseattack_naboo_imperial_tier4_2_b = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_imperial_tier4_2_b",

	questName = "naboo_imperial_tier4_2_b",
	questType = "destroy_surpriseattack",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "recovery",
	sideQuestName = "naboo_imperial_tier4_2_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "rescue_naboo_imperial_tier4_2_a",
	parentQuestType = "rescue",
	parentQuestName = "naboo_imperial_tier4_2_a",

	surpriseAttackShips = {
		zone = "space_dathomir",
		spawns = {{count = 6, shipName = "coynite_merc_pulsar_tier4"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_imperial_tier4_2_b", true)

recovery_naboo_imperial_tier4_2_c = SpaceRecoveryScreenplay:new {
	className = "recovery_naboo_imperial_tier4_2_c",

	questName = "naboo_imperial_tier4_2_c",
	questType = "recovery",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "destroy_surpriseattack_naboo_imperial_tier4_2_b",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "naboo_imperial_tier4_2_b",

	-- Screenplay Specific Variables
	arrivalDelay = 30,
	recoveryDelay = 30,
	recoverShip = "coynite_merc_neutron_tier5",

	escortShips = {"coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},

	preRecoveryPoints = {
		{patrolPointName = "naboo_imperial_tier4_recovery1_6", x = 975, z = 225, y = 3781, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery1_7", x = -2095, z = 2334, y = 3374, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery1_8", x = -4455, z = 2935, y = 4075, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery2_1", x = -7238, z = 2332, y = -1848, escortNumber = 4, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "naboo_imperial_tier4_recovery2_5", x = -6263, z = 3140, y = 1529, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery2_6", x = -4648, z = 2991, y = 4029, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery2_7", x = -3618, z = 2711, y = 7068, escortNumber = 3, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
			{"coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4"},
			{"coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4"},
			{"coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4"},
		},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_naboo_imperial_tier4_2_c", true)

-- Mission 3: Survival > Delivery (no pickup) > Assassinate
survival_naboo_imperial_tier4_3 = SpaceSurvivalScreenplay:new {
	className = "survival_naboo_imperial_tier4_3",

	questName = "naboo_imperial_tier4_3",
	questType = "survival",

	questZone = "space_dathomir",

	creditReward = 10000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/armor/arm_mission_reward_imperial_rss_special_durasteel.iff"},
	},

	sideQuest = true,
	sideQuestType = "delivery_no_pickup",
	sideQuestName = "naboo_imperial_tier4_3_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	-- Screenplay Specific Variables
	transmissionPoint = {patrolPointName = "naboo_imperial_tier4_survival1", x = -5152, z = -498, y = 6589},
	totalTransmissionTime = 600,
	timesToUpdateProgress = 20,
	transmissionStartDelay = 15,
	delayToFirstAttack = 30,

	attackShipLists = {
			{"coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},
			{"coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_quasar_tier4"},
			{"coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},
			{"coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},
			{"coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_neutron_tier4"},
			{"coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4"},
		},

	attackPeriod = 90,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("survival_naboo_imperial_tier4_3", true)

delivery_no_pickup_naboo_imperial_tier4_3_a = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_naboo_imperial_tier4_3_a",

	questName = "naboo_imperial_tier4_3_a",
	questType = "delivery_no_pickup",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "naboo_imperial_tier4_3_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "survival_naboo_imperial_tier4_3",
	parentQuestType = "survival",
	parentQuestName = "naboo_imperial_tier4_3",

	-- Screenplay Specific Variables
	deliveryShip = "imp_lambda_shuttle_tier4",
	deliveryPoint = {patrolPointName = "naboo_imperial_tier4_delivery2", x = -2651, z = -334, y = -4012},

	attackShipLists = {
			{"coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},
			{"coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},
			{"coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_quasar_tier4"},
			{"coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4"},
		},

	attackPeriod = 60,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_no_pickup_naboo_imperial_tier4_3_a", true)

assassinate_naboo_imperial_tier4_3_b = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_imperial_tier4_3_b",

	questName = "naboo_imperial_tier4_3_b",
	questType = "assassinate",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "delivery_no_pickup_naboo_imperial_tier4_3_a",
	parentQuestType = "delivery_no_pickup",
	parentQuestName = "naboo_imperial_tier4_3_a",

	arrivalDelay = 30,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "coynite_mothership_tier4",
		escorts = {"coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_imperial_tier4_assassinate1_1", x = -141, z = -3283, y = -3310},
		{patrolPointName = "naboo_imperial_tier4_assassinate1_2", x = 1392, z = -5247, y = -2647},
		{patrolPointName = "naboo_imperial_tier4_assassinate1_3", x = 2124, z = -6185, y = -2330},
		{patrolPointName = "naboo_imperial_tier4_assassinate1_4", x = 4735, z = -7420, y = -1572},
	},
}

registerScreenPlay("assassinate_naboo_imperial_tier4_3_b", true)

-- Mission 4: Escort > Recovery > Assassinate > Assassinate > Space battle
escort_naboo_imperial_tier4_4 = SpaceEscortScreenplay:new {
	className = "escort_naboo_imperial_tier4_4",

	questName = "naboo_imperial_tier4_4",
	questType = "escort",

	questZone = "space_dathomir",

	creditReward = 10000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/reactor/rct_mission_reward_imperial_rss_advanced_military.iff"},
	},

	sideQuest = true,
	sideQuestType = "recovery",
	sideQuestName = "naboo_imperial_tier4_4_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	-- Screenplay Specific Variables
	escortShips = {"dathomir_prison_shuttle_tier4"},

	-- SWG numResponses is 0 but the client file has _1.._5 of each key (spec FJ-7)
	escortPoints = {
		{patrolPointName = "naboo_imperial_tier4_escort1_1", x = 3787, z = -6425, y = 49, zoneName = "space_dathomir", escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_escort1_2", x = 3065, z = -5248, y = 1760, zoneName = "space_dathomir", escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_escort1_3", x = 2200, z = -4231, y = 2864, zoneName = "space_dathomir", escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_escort1_4", x = 1502, z = -3172, y = 4240, zoneName = "space_dathomir", escortNumber = 4, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_escort1_5", x = 336, z = -1027, y = 7007, zoneName = "space_dathomir", escortNumber = 5, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
			{"coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4"},
			{"coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},
			{"coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4"},
			{"coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},
		},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_naboo_imperial_tier4_4", true)

recovery_naboo_imperial_tier4_4_a = SpaceRecoveryScreenplay:new {
	className = "recovery_naboo_imperial_tier4_4_a",

	questName = "naboo_imperial_tier4_4_a",
	questType = "recovery",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "naboo_imperial_tier4_4_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "escort_naboo_imperial_tier4_4",
	parentQuestType = "escort",
	parentQuestName = "naboo_imperial_tier4_4",

	-- Screenplay Specific Variables
	arrivalDelay = 30,
	recoveryDelay = 30,
	recoverShip = "dathomir_prison_break_shuttle_tier4",

	escortShips = {"coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},

	preRecoveryPoints = {
		{patrolPointName = "naboo_imperial_tier4_recovery3_1", x = 2520, z = 1785, y = 4899, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery3_2", x = 4471, z = 351, y = -482, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery3_3", x = 1534, z = -2167, y = -3967, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery3_4", x = -5949, z = -3151, y = -4944, escortNumber = 4, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "naboo_imperial_tier4_recovery3_5", x = 2072, z = -835, y = 2749, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery3_6", x = 2193, z = -1002, y = 5820, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recovery3_7", x = 2243, z = -944, y = 7076, escortNumber = 3, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
			{"coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4"},
			{"coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4"},
		},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_naboo_imperial_tier4_4_a", true)

assassinate_naboo_imperial_tier4_4_b = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_imperial_tier4_4_b",

	questName = "naboo_imperial_tier4_4_b",
	questType = "assassinate",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "naboo_imperial_tier4_4_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "recovery_naboo_imperial_tier4_4_a",
	parentQuestType = "recovery",
	parentQuestName = "naboo_imperial_tier4_4_a",

	arrivalDelay = 30,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "dathomir_prison_break_shuttle_tier4",
		escorts = {"coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_imperial_tier4_assassinate2_1", x = 2795, z = -5791, y = 6336},
		{patrolPointName = "naboo_imperial_tier4_assassinate2_2", x = 2631, z = -7584, y = 4070},
		{patrolPointName = "naboo_imperial_tier4_assassinate2_3", x = 3072, z = -6658, y = 5858},
		{patrolPointName = "naboo_imperial_tier4_assassinate2_4", x = 3613, z = -5613, y = 7149},
	},
}

registerScreenPlay("assassinate_naboo_imperial_tier4_4_b", true)

assassinate_naboo_imperial_tier4_4_c = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_imperial_tier4_4_c",

	questName = "naboo_imperial_tier4_4_c",
	questType = "assassinate",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "space_battle",
	sideQuestName = "naboo_imperial_tier4_4_d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "assassinate_naboo_imperial_tier4_4_b",
	parentQuestType = "assassinate",
	parentQuestName = "naboo_imperial_tier4_4_b",

	arrivalDelay = 30,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "dathomir_prison_break_shuttle_tier4",
		escorts = {"coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4", "coynite_merc_neutron_tier4"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_imperial_tier4_assassinate3_1", x = 4423, z = -5952, y = 4998},
		{patrolPointName = "naboo_imperial_tier4_assassinate3_2", x = 4497, z = -4930, y = 2766},
		{patrolPointName = "naboo_imperial_tier4_assassinate3_3", x = 4424, z = -3818, y = 943},
		{patrolPointName = "naboo_imperial_tier4_assassinate3_4", x = 4351, z = -2709, y = -874},
	},
}

registerScreenPlay("assassinate_naboo_imperial_tier4_4_c", true)

space_battle_naboo_imperial_tier4_4_d = SpaceBattleScreenplay:new {
	className = "space_battle_naboo_imperial_tier4_4_d",

	questName = "naboo_imperial_tier4_4_d",
	questType = "space_battle",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "assassinate_naboo_imperial_tier4_4_c",
	parentQuestType = "assassinate",
	parentQuestName = "naboo_imperial_tier4_4_c",

	-- Screenplay Specific Variables (spacequest/space_battle/naboo_imperial_tier4_4_d.tab)
	battlePoint = {patrolPointName = "naboo_imperial_tier4_spacebattle1", x = -160, z = 2428, y = -2525, forward = {x = -0.657288, z = 0.753625, y = 0.004683}},

	damageMultiplier = 2,

	allyArrivalDelay = 30,
	enemyArrivalDelay = 90,
	allyOriginDist = 400,
	enemyOriginDist = -400,
	allyArrivalDist = 300,
	enemyArrivalDist = 300,

	allyForce = {"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4"},

	enemyForce = {"coynite_coynfury_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4"},
}

registerScreenPlay("space_battle_naboo_imperial_tier4_4_d", true)

-- Ja'ce Yiaso Duty Missions (Dathomir)
destroy_duty_naboo_imperial_tier4_1 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_naboo_imperial_tier4_1",

	questName = "naboo_imperial_tier4_1",
	questType = "destroy_duty",

	questZone = "space_dathomir",

	creditReward = 300,

	sideQuest = false,
	sideQuestType = "",

	totalLevels = 8,
	totalRounds = 5,
	totalWaves = 3,

	bossShip = "coynite_merc_captain_tier5",
	shipTypes = {
			{"coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},
			{"coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4"},
			{"coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4"},
			{"coynite_merc_neutron_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4"},
		},
}

registerScreenPlay("destroy_duty_naboo_imperial_tier4_1", true)

escort_duty_naboo_imperial_tier4_2 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_naboo_imperial_tier4_2",

	questName = "naboo_imperial_tier4_2",
	questType = "escort_duty",

	questZone = "space_dathomir",

	creditReward = 5000,
	creditKillBonus = 300,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {"dathomir_prison_shuttle_tier4"},

	escortPoints = {
		{patrolPointName = "naboo_imperial_tier4_escortduty1_1", x = -2579, z = 3780, y = -2522, zoneName = "space_dathomir", escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_escortduty1_2", x = -4477, z = 5219, y = -2369, zoneName = "space_dathomir", escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_escortduty1_3", x = -5687, z = 6430, y = -2361, zoneName = "space_dathomir", escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_escortduty1_4", x = -7061, z = 7306, y = -2391, zoneName = "space_dathomir", escortNumber = 4, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
			{"coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4", "coynite_merc_pulsar_tier4"},
			{"coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_quasar_tier4"},
		},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_naboo_imperial_tier4_2", true)

recovery_duty_naboo_imperial_tier4_3 = SpaceDutyRecoveryScreenplay:new {
	className = "recovery_duty_naboo_imperial_tier4_3",

	questName = "naboo_imperial_tier4_3",
	questType = "recovery_duty",

	questZone = "space_dathomir",

	creditReward = 5000,
	creditKillBonus = 300,
	numResponses = 5,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	arrivalDelay = 30,
	recoveryDelay = 30,
	recoverShips = {"rogue_imperial_shuttle_tier4", "rogue_imperial_tiebomber_tier4"},

	escortShips = {},

	-- SWG skips recoveryduty1_3
	preRecoveryPoints = {
		{patrolPointName = "naboo_imperial_tier4_recoveryduty1_1", x = 818, z = -81, y = -4097, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recoveryduty1_2", x = 1345, z = -437, y = -5196, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recoveryduty1_4", x = 3989, z = -1251, y = -6960, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recoveryduty1_5", x = 1495, z = -1773, y = -6461, escortNumber = 4, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "naboo_imperial_tier4_recoveryduty1_6", x = -1458, z = -2983, y = -5981, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_imperial_tier4_recoveryduty1_7", x = -3969, z = -4072, y = -3508, escortNumber = 2, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
			{"reb_xwing_tier4", "reb_xwing_tier4", "reb_xwing_tier4", "reb_xwing_tier4"},
			{"reb_bwing_tier4", "reb_bwing_tier4", "reb_bwing_tier4", "reb_bwing_tier4"},
		},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_duty_naboo_imperial_tier4_3", true)

rescue_duty_naboo_imperial_tier4_4 = SpaceDutyRescueScreenplay:new {
	className = "rescue_duty_naboo_imperial_tier4_4",

	questName = "naboo_imperial_tier4_4",
	questType = "rescue_duty",

	questZone = "space_dathomir",

	creditReward = 5000,
	creditKillBonus = 300,

	sideQuest = false,
	sideQuestType = "",

	-- SWG attackListType sequential = 0
	recoveryPath = {
		{patrolPointName = "naboo_imperial_tier4_rescueduty1_1", x = -2387, z = 5980, y = -2544},
		{patrolPointName = "naboo_imperial_tier4_rescueduty1_2", x = -445, z = 5042, y = -2927},
		{patrolPointName = "naboo_imperial_tier4_rescueduty1_3", x = 237, z = 2972, y = -2982},
		{patrolPointName = "naboo_imperial_tier4_rescueduty1_4", x = 19, z = 459, y = -2427},
	},

	targetShipTypes = {"dathomir_prison_shuttle_tier4", "imp_freightermedium_tier4", "imp_freighterlight_tier4", "imp_freighterheavy_tier4"},
	targetArrivalDelay = 30,

	attackShipLists = {
			{"reb_xwing_tier4", "reb_xwing_tier4", "reb_xwing_tier4", "reb_xwing_tier4"},
			{"reb_awing_tier4", "reb_awing_tier4", "reb_awing_tier4", "reb_awing_tier4"},
			{"reb_bwing_tier4", "reb_bwing_tier4", "reb_awing_tier4", "reb_awing_tier4"},
		},

	attackPeriod = 120,
	attackListType = 0,
	numResponses = 5,
}

registerScreenPlay("rescue_duty_naboo_imperial_tier4_4", true)

--[[

	InquisitionSquadronScreenplay

]]

InquisitionSquadronScreenplay = ScreenPlay:new {
	screenplayName = "InquisitionSquadronScreenplay",

	-- Tier 1 (Barn Sinkko)
	QUEST_STRING_1 = {type = "patrol", name = "naboo_imperial_1"},
	QUEST_STRING_1_SIDE = {type = "destroy_surpriseattack", name = "naboo_imperial_1"},
	QUEST_STRING_2 = {type = "destroy", name = "naboo_imperial_2"},
	QUEST_STRING_3 = {type = "patrol", name = "naboo_imperial_3"},
	QUEST_STRING_3_SIDE = {type = "escort", name = "naboo_imperial_3"},
	QUEST_STRING_4 = {type = "assassinate", name = "naboo_imperial_4"},
	QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "naboo_imperial_6"},
	QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "naboo_imperial_7"},

	-- Tier 2 (Fa'Zoll)
	TIER2_QUEST_STRING_1 = {type = "inspect", name = "naboo_imperial_tier2_1"},
	TIER2_QUEST_STRING_2 = {type = "survival", name = "naboo_imperial_tier2_2"},
	TIER2_QUEST_STRING_3 = {type = "recovery", name = "naboo_imperial_tier2_3"},
	TIER2_QUEST_STRING_4 = {type = "assassinate", name = "naboo_imperial_tier2_4"},
	TIER2_QUEST_STRING_DUTY_1 = {type = "recovery_duty", name = "naboo_imperial_tier2_recoveryduty"},
	TIER2_QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "naboo_imperial_tier2_escortduty"},
	TIER2_QUEST_STRING_DUTY_3 = {type = "destroy_duty", name = "naboo_imperial_tier2_destroyduty"},

	-- Tier 3 (Vrke)
	TIER3_QUEST_STRING_1 = {type = "recovery", name = "naboo_imperial_tier3_1"},
	TIER3_QUEST_STRING_1_SIDE1 = {type = "inspect", name = "naboo_imperial_tier3_1_a"},
	TIER3_QUEST_STRING_1_SIDE2 = {type = "delivery_no_pickup", name = "naboo_imperial_tier3_1_b"},
	TIER3_QUEST_STRING_2 = {type = "inspect", name = "naboo_imperial_tier3_2"},
	TIER3_QUEST_STRING_2_SIDE1 = {type = "survival", name = "naboo_imperial_tier3_2_a"},
	TIER3_QUEST_STRING_2_SIDE2 = {type = "delivery", name = "naboo_imperial_tier3_2_b"},
	TIER3_QUEST_STRING_2_SIDE3 = {type = "recovery", name = "naboo_imperial_tier3_2_c"},
	TIER3_QUEST_STRING_3 = {type = "delivery", name = "naboo_imperial_tier3_3"},
	TIER3_QUEST_STRING_3_SIDE1 = {type = "destroy_surpriseattack", name = "naboo_imperial_tier3_3_a"},
	TIER3_QUEST_STRING_3_SIDE2 = {type = "rescue", name = "naboo_imperial_tier3_3_b"},
	TIER3_QUEST_STRING_3_SIDE3 = {type = "inspect", name = "naboo_imperial_tier3_3_c"},
	TIER3_QUEST_STRING_3_SIDE4 = {type = "delivery_no_pickup", name = "naboo_imperial_tier3_3_d"},
	TIER3_QUEST_STRING_4 = {type = "assassinate", name = "naboo_imperial_tier3_4"},
	TIER3_QUEST_STRING_4_SIDE1 = {type = "escort", name = "naboo_imperial_tier3_4_a"},
	TIER3_QUEST_STRING_4_SIDE2 = {type = "space_battle", name = "naboo_imperial_tier3_4_b"},
	TIER3_QUEST_STRING_4_SIDE3 = {type = "assassinate", name = "naboo_imperial_tier3_4_c"},

	-- Tier 4 (Ja'ce Yiaso); SIDEk = the k-th split child
	TIER4_QUEST_STRING_1 = {type = "patrol", name = "naboo_imperial_tier4_1"},
	TIER4_QUEST_STRING_1_SIDE1 = {type = "inspect", name = "naboo_imperial_tier4_1_a"},
	TIER4_QUEST_STRING_1_SIDE2 = {type = "destroy_surpriseattack", name = "naboo_imperial_tier4_1_b"},
	TIER4_QUEST_STRING_1_SIDE3 = {type = "delivery_no_pickup", name = "naboo_imperial_tier4_1_c"},
	TIER4_QUEST_STRING_2 = {type = "recovery", name = "naboo_imperial_tier4_2"},
	TIER4_QUEST_STRING_2_SIDE1 = {type = "rescue", name = "naboo_imperial_tier4_2_a"},
	TIER4_QUEST_STRING_2_SIDE2 = {type = "destroy_surpriseattack", name = "naboo_imperial_tier4_2_b"},
	TIER4_QUEST_STRING_2_SIDE3 = {type = "recovery", name = "naboo_imperial_tier4_2_c"},
	TIER4_QUEST_STRING_3 = {type = "survival", name = "naboo_imperial_tier4_3"},
	TIER4_QUEST_STRING_3_SIDE1 = {type = "delivery_no_pickup", name = "naboo_imperial_tier4_3_a"},
	TIER4_QUEST_STRING_3_SIDE2 = {type = "assassinate", name = "naboo_imperial_tier4_3_b"},
	TIER4_QUEST_STRING_4 = {type = "escort", name = "naboo_imperial_tier4_4"},
	TIER4_QUEST_STRING_4_SIDE1 = {type = "recovery", name = "naboo_imperial_tier4_4_a"},
	TIER4_QUEST_STRING_4_SIDE2 = {type = "assassinate", name = "naboo_imperial_tier4_4_b"},
	TIER4_QUEST_STRING_4_SIDE3 = {type = "assassinate", name = "naboo_imperial_tier4_4_c"},
	TIER4_QUEST_STRING_4_SIDE4 = {type = "space_battle", name = "naboo_imperial_tier4_4_d"},

	-- Tier 4 Duty Quest Strings (SWG grantDutyMission order)
	TIER4_QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "naboo_imperial_tier4_1"},
	TIER4_QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "naboo_imperial_tier4_2"},
	TIER4_QUEST_STRING_DUTY_3 = {type = "recovery_duty", name = "naboo_imperial_tier4_3"},
	TIER4_QUEST_STRING_DUTY_4 = {type = "rescue_duty", name = "naboo_imperial_tier4_4"},

	-- Flags (stored as <playerID><suffix>, value "1")
	-- Set by Barn's promotion; tier 2 (Fa'Zoll) reads it as the SWG series flag naboo_imperial_1
	SERIES_COMPLETE_KEY = "InquisitionSquadronScreenplay:naboo_imperial_1",
	-- Set by Fa'Zoll's sign-up (sign_up_agent, SWG makeInquisitorialAgent); read by Barn (G9, G11) and Fa'Zoll (F23); cleared by resetFaZollQuests
	INQUISITORIAL_AGENT_KEY = "InquisitionSquadronScreenplay:inquisitorialAgent",
	-- Set by Vrke's mission 1 training lines (SWG sentToBarlow); read by Vrke (V17) and Barlow (inquisition-tier3-barlow); cleared by Barlow's interview and by resetVrkeQuests
	QUESTION_BARLOW_KEY = "InquisitionSquadronScreenplay:questionBarlow",
	-- Set by Barlow's interview (SWG spokeToBarlow); cleared by Vrke's tour_complete (SWG removeTalkedToBarlow) and by resetVrkeQuests
	SPOKE_TO_BARLOW_KEY = "InquisitionSquadronScreenplay:spokeToBarlow",
	-- Set by Ja'ce's first-meeting briefing (intro_briefing, SWG setMetMe / space flag metTier4); read by Ja'ce (G18); cleared by resetJaceYiasoQuests
	TIER4_MET_KEY = "InquisitionSquadronScreenplay:metTier4",
}

registerScreenPlay("InquisitionSquadronScreenplay", false)

function InquisitionSquadronScreenplay:start()
end

-- Reset functions for quest clearing

function InquisitionSquadronScreenplay:resetBarnQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local tables = {
		patrol_naboo_imperial_1, destroy_surpriseattack_naboo_imperial_1, destroy_naboo_imperial_2,
		patrol_naboo_imperial_3, escort_naboo_imperial_3, assassinate_naboo_imperial_4,
		destroy_duty_naboo_imperial_6, escort_duty_naboo_imperial_7
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
	removeQuestStatus(playerID .. self.QUEST_STRING_2.name .. ":aborted")

	for _, questString in ipairs({ self.QUEST_STRING_1, self.QUEST_STRING_2, self.QUEST_STRING_3, self.QUEST_STRING_4 }) do
		removeQuestStatus(playerID .. questString.name .. ":attempted")
		removeQuestStatus(playerID .. questString.name .. ":reward")
	end
end

function InquisitionSquadronScreenplay:resetFaZollQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local tables = {
		inspect_naboo_imperial_tier2_1, survival_naboo_imperial_tier2_2, recovery_naboo_imperial_tier2_3,
		assassinate_naboo_imperial_tier2_4, recovery_duty_naboo_imperial_tier2_recoveryduty,
		escort_duty_naboo_imperial_tier2_escortduty, destroy_duty_naboo_imperial_tier2_destroyduty
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.TIER2_QUEST_STRING_1, self.TIER2_QUEST_STRING_2, self.TIER2_QUEST_STRING_3, self.TIER2_QUEST_STRING_4,
		self.TIER2_QUEST_STRING_DUTY_1, self.TIER2_QUEST_STRING_DUTY_2, self.TIER2_QUEST_STRING_DUTY_3
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	removeQuestStatus(playerID .. self.INQUISITORIAL_AGENT_KEY)

	for _, questString in ipairs({ self.TIER2_QUEST_STRING_1, self.TIER2_QUEST_STRING_2, self.TIER2_QUEST_STRING_3, self.TIER2_QUEST_STRING_4 }) do
		removeQuestStatus(playerID .. questString.name .. ":attempted")
		removeQuestStatus(playerID .. questString.name .. ":reward")
	end
end

function InquisitionSquadronScreenplay:resetVrkeQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local tables = {
		recovery_naboo_imperial_tier3_1, inspect_naboo_imperial_tier3_1_a, delivery_no_pickup_naboo_imperial_tier3_1_b,
		inspect_naboo_imperial_tier3_2, survival_naboo_imperial_tier3_2_a, delivery_naboo_imperial_tier3_2_b, recovery_naboo_imperial_tier3_2_c,
		delivery_naboo_imperial_tier3_3, destroy_surpriseattack_naboo_imperial_tier3_3_a, rescue_naboo_imperial_tier3_3_b,
		inspect_naboo_imperial_tier3_3_c, delivery_no_pickup_naboo_imperial_tier3_3_d,
		assassinate_naboo_imperial_tier3_4, escort_naboo_imperial_tier3_4_a, space_battle_naboo_imperial_tier3_4_b, assassinate_naboo_imperial_tier3_4_c
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.TIER3_QUEST_STRING_1, self.TIER3_QUEST_STRING_1_SIDE1, self.TIER3_QUEST_STRING_1_SIDE2,
		self.TIER3_QUEST_STRING_2, self.TIER3_QUEST_STRING_2_SIDE1, self.TIER3_QUEST_STRING_2_SIDE2, self.TIER3_QUEST_STRING_2_SIDE3,
		self.TIER3_QUEST_STRING_3, self.TIER3_QUEST_STRING_3_SIDE1, self.TIER3_QUEST_STRING_3_SIDE2, self.TIER3_QUEST_STRING_3_SIDE3, self.TIER3_QUEST_STRING_3_SIDE4,
		self.TIER3_QUEST_STRING_4, self.TIER3_QUEST_STRING_4_SIDE1, self.TIER3_QUEST_STRING_4_SIDE2, self.TIER3_QUEST_STRING_4_SIDE3
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	removeQuestStatus(playerID .. self.QUESTION_BARLOW_KEY)
	removeQuestStatus(playerID .. self.SPOKE_TO_BARLOW_KEY)

	for _, questString in ipairs({ self.TIER3_QUEST_STRING_1, self.TIER3_QUEST_STRING_2, self.TIER3_QUEST_STRING_3, self.TIER3_QUEST_STRING_4 }) do
		removeQuestStatus(playerID .. questString.name .. ":attempted")
		removeQuestStatus(playerID .. questString.name .. ":reward")
	end
end

-- Tier 4 -- Ja'ce Yiaso
function InquisitionSquadronScreenplay:resetJaceYiasoQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local tables = {
		patrol_naboo_imperial_tier4_1, inspect_naboo_imperial_tier4_1_a, destroy_surpriseattack_naboo_imperial_tier4_1_b, delivery_no_pickup_naboo_imperial_tier4_1_c,
		recovery_naboo_imperial_tier4_2, rescue_naboo_imperial_tier4_2_a, destroy_surpriseattack_naboo_imperial_tier4_2_b, recovery_naboo_imperial_tier4_2_c,
		survival_naboo_imperial_tier4_3, delivery_no_pickup_naboo_imperial_tier4_3_a, assassinate_naboo_imperial_tier4_3_b,
		escort_naboo_imperial_tier4_4, recovery_naboo_imperial_tier4_4_a, assassinate_naboo_imperial_tier4_4_b, assassinate_naboo_imperial_tier4_4_c, space_battle_naboo_imperial_tier4_4_d,
		destroy_duty_naboo_imperial_tier4_1, escort_duty_naboo_imperial_tier4_2, recovery_duty_naboo_imperial_tier4_3, rescue_duty_naboo_imperial_tier4_4
	}

	for _, questTable in ipairs(tables) do
		questTable:resetQuest(pPlayer)
	end

	local questStrings = {
		self.TIER4_QUEST_STRING_1, self.TIER4_QUEST_STRING_1_SIDE1, self.TIER4_QUEST_STRING_1_SIDE2, self.TIER4_QUEST_STRING_1_SIDE3,
		self.TIER4_QUEST_STRING_2, self.TIER4_QUEST_STRING_2_SIDE1, self.TIER4_QUEST_STRING_2_SIDE2, self.TIER4_QUEST_STRING_2_SIDE3,
		self.TIER4_QUEST_STRING_3, self.TIER4_QUEST_STRING_3_SIDE1, self.TIER4_QUEST_STRING_3_SIDE2,
		self.TIER4_QUEST_STRING_4, self.TIER4_QUEST_STRING_4_SIDE1, self.TIER4_QUEST_STRING_4_SIDE2, self.TIER4_QUEST_STRING_4_SIDE3, self.TIER4_QUEST_STRING_4_SIDE4,
		self.TIER4_QUEST_STRING_DUTY_1, self.TIER4_QUEST_STRING_DUTY_2, self.TIER4_QUEST_STRING_DUTY_3, self.TIER4_QUEST_STRING_DUTY_4
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	removeQuestStatus(playerID .. self.TIER4_MET_KEY)

	for _, questString in ipairs({ self.TIER4_QUEST_STRING_1, self.TIER4_QUEST_STRING_2, self.TIER4_QUEST_STRING_3, self.TIER4_QUEST_STRING_4 }) do
		removeQuestStatus(playerID .. questString.name .. ":attempted")
		removeQuestStatus(playerID .. questString.name .. ":reward")
	end
end
