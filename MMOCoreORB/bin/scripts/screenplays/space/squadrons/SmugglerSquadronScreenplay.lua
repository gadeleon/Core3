local SpaceHelpers = require("utils.space_helpers")

--[[

	Smuggler Squadron Quests

	Tier 1 (trainer Dravis, Mos Eisley) is ported from SWG-Source datatables/spacequest tatooine_privateer_1..8
	and tatooine_privateer_tier1_4a (feature smuggler-tier1-dravis). The transition quest tat_priv_quest_trans
	(trainer Talon Karrde, tatooine_privateer_trainer_2) is ported by feature smuggler-transition-karrde.
	Tier 2 (trainer Shamdon Kree, tatooine_privateer_trainer_shamdon) is ported by feature smuggler-tier2-shamdon. Tier 3 (trainer Beissa, tatooine_privateer_tier3) is ported by feature smuggler-tier3-beissa. Tier 4 is not ported yet.

]]

--[[
	Tier 1 -- Dravis Main Missions
]]

-- Mission 1: Patrol

patrol_tatooine_privateer_1 = SpacePatrolScreenplay:new {
	className = "patrol_tatooine_privateer_1",

	questName = "tatooine_privateer_1",
	questType = "patrol",

	questZone = "space_tatooine",

	creditReward = 100,

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "tatooine_privateer_1",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 20,

	-- Screenplay Specific Variables
	patrolPoints = {
		{patrolPointName = "blacksun_patrol_1", x = -31, z = 275, y = -2950, patrolNumber = 1, radius = 150},
		{patrolPointName = "blacksun_patrol_2", x = 2886, z = -3000, y = -1801, patrolNumber = 2, radius = 150},
		{patrolPointName = "blacksun_patrol_3", x = 2370, z = 669, y = 1089, patrolNumber = 3, radius = 150},
	},
}

registerScreenPlay("patrol_tatooine_privateer_1", true)

destroy_surpriseattack_tatooine_privateer_1 = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_tatooine_privateer_1",

	questName = "tatooine_privateer_1",
	questType = "destroy_surpriseattack",

	questZone = "space_tatooine",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_tatooine_privateer_1",
	parentQuestType = "patrol",
	parentQuestName = "tatooine_privateer_1",

	-- Screenplay Specific Variables
	surpriseAttackShips = {
		zone = "space_tatooine",
		spawns = {{count = 3, shipName = "blacksun_fighter_s01_tier1"}},
	},
}

registerScreenPlay("destroy_surpriseattack_tatooine_privateer_1", true)

-- Mission 2: Destroy

destroy_tatooine_privateer_2 = SpaceDestroyScreenplay:new {
	className = "destroy_tatooine_privateer_2",

	questName = "tatooine_privateer_2",
	questType = "destroy",

	questZone = "space_tatooine",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	killsRequired = 4,

	-- blacksun_guards_2 (SWG validSpawns) does not exist in the buildout or the spawner, so it is left out
	shipLocations = {
		{spawnName = "blacksun_threat_2", x = 1098, z = 767, y = -2978},
		{spawnName = "blacksun_pirates", x = -2024, z = 1619, y = -2219},
		{spawnName = "blacksun_n_stuff_1", x = 5588, z = 1002, y = 6147},
		{spawnName = "blacksun_threat_3", x = 2816, z = 336, y = -1908},
	},

	shipTypes = {
		"blacksun_ace_s04_tier1", "blacksun_ace_s04_tier2", "blacksun_aggressor_tier1", "blacksun_aggressor_tier2",
		"blacksun_bomber_ace_s04_tier1", "blacksun_bomber_ace_s04_tier2",
		"blacksun_bomber_s01_tier1", "blacksun_bomber_s01_tier2", "blacksun_bomber_s01_tier2_tatooine",
		"blacksun_bomber_s02_tier1", "blacksun_bomber_s02_tier2", "blacksun_bomber_s03_tier1", "blacksun_bomber_s03_tier2",
		"blacksun_fighter_s01_tier1", "blacksun_fighter_s01_tier2", "blacksun_fighter_s01_tier2_tatooine",
		"blacksun_fighter_s02_tier1", "blacksun_fighter_s02_tier2", "blacksun_fighter_s03_tier1", "blacksun_fighter_s03_tier2",
		"blacksun_gunship_tier1", "blacksun_gunship_tier2", "blacksun_marauder_tier1", "blacksun_marauder_tier2",
		"blacksun_vehement_tier1", "blacksun_vehement_tier2", "blacksun_yt1300_tier1", "blacksun_yt1300_tier2",
		"blacksun_bomber_ace_tier3_dantooine", "blacksun_bomber_s02_tier3_dantooine",
		"blacksun_fighter_s01_tier2_tatooine", "blacksun_fighter_s02_tier3_dantooine",
	},
}

registerScreenPlay("destroy_tatooine_privateer_2", true)

-- Mission 3: Patrol with Escort side quest

patrol_tatooine_privateer_3 = SpacePatrolScreenplay:new {
	className = "patrol_tatooine_privateer_3",

	questName = "tatooine_privateer_3",
	questType = "patrol",

	questZone = "space_tatooine",

	creditReward = 500,
	itemReward = {
		{species = {SPECIES_ITHORIAN}, item = "object/tangible/wearables/bandolier/ith_mercenary_bandolier.iff"},
		{species = {-1}, item = "object/tangible/wearables/bandolier/mercenary_bandolier.iff"},
	},

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "tatooine_privateer_3",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 20,

	-- Screenplay Specific Variables
	patrolPoints = {
		{patrolPointName = "privateer_security_patrol_1", x = -2479, z = -2475, y = 613, patrolNumber = 1, radius = 150},
		{patrolPointName = "privateer_security_patrol_2", x = 469, z = -550, y = 2173, patrolNumber = 2, radius = 150},
		{patrolPointName = "privateer_security_patrol_3", x = 2528, z = 2101, y = -316, patrolNumber = 3, radius = 150},
		{patrolPointName = "privateer_security_patrol_4", x = 1035, z = 1254, y = -2829, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_tatooine_privateer_3", true)

escort_tatooine_privateer_3 = SpaceEscortScreenplay:new {
	className = "escort_tatooine_privateer_3",

	questName = "tatooine_privateer_3",
	questType = "escort",

	questZone = "space_tatooine",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_tatooine_privateer_3",
	parentQuestType = "patrol",
	parentQuestName = "tatooine_privateer_3",

	-- Screenplay Specific Variables
	escortShips = {"hutt_freighterlight_tier1"},

	escortPoints = {
		{patrolPointName = "privateer_security_escort_1", zoneName = "space_tatooine", x = 2625, z = 1624, y = 2461, escortNumber = 1, radius = 250},
		{patrolPointName = "privateer_security_escort_2", zoneName = "space_tatooine", x = 368, z = 805, y = 2098, escortNumber = 2, radius = 250},
		{patrolPointName = "privateer_security_escort_3", zoneName = "space_tatooine", x = -1065, z = 822, y = 418, escortNumber = 3, radius = 250},
		{patrolPointName = "privateer_security_escort_4", zoneName = "space_tatooine", x = -2096, z = -1446, y = -2635, escortNumber = 4, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"blacksun_fighter_s01_tier1", "blacksun_fighter_s02_tier1"},
		{"blacksun_vehement_tier1", "blacksun_marauder_tier1", "blacksun_marauder_tier1"},
	},

	tauntData = {goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2},
}

registerScreenPlay("escort_tatooine_privateer_3", true)

-- Mission 4: Assassinate

assassinate_tatooine_privateer_tier1_4a = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_privateer_tier1_4a",

	questType = "assassinate",
	questName = "tatooine_privateer_tier1_4a",

	questZone = "space_tatooine",

	creditReward = 1000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon/wpn_mission_reward_neutral_mandal_light_blaster.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	arrivalDelay = 12,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "blacksun_ace_s04_tier1",
		escorts = {"blacksun_fighter_s03_tier1", "blacksun_fighter_s02_tier1"},
	},

	targetPatrols = {
		{patrolPointName = "anchorhead_supply_patrol_1", x = 2634, z = -5262, y = 1718},
		{patrolPointName = "bestine_commerce_patrol_3", x = -304, z = -4571, y = 4419},
		{patrolPointName = "bestine_security_patrol_2", x = 1923, z = -3956, y = 3964},
		{patrolPointName = "privateer_security_patrol_1", x = -2479, z = -2475, y = 613},
		{patrolPointName = "imperial_escortduty_2", x = 2356, z = -3868, y = 4288},
		{patrolPointName = "blacksun_patrol_1", x = -31, z = 275, y = -2950},
		{patrolPointName = "anchorhead_armed_recon_1", x = -1387, z = -1962, y = 1725},
	},
}

registerScreenPlay("assassinate_tatooine_privateer_tier1_4a", true)

-- Tier 1 Duty Missions

destroy_duty_tatooine_privateer_6 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_tatooine_privateer_6",

	questName = "tatooine_privateer_6",
	questType = "destroy_duty",

	questZone = "space_tatooine",

	creditReward = 100,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	totalLevels = 2,
	totalRounds = 2,
	totalWaves = 2,

	bossShip = "blacksun_marauder_tier2",

	shipTypes = {
		{"blacksun_bomber_s01_tier1", "blacksun_bomber_s03_tier1"},
		{"blacksun_aggressor_tier1", "blacksun_aggressor_tier1"},
		{"blacksun_fighter_s02_tier1", "blacksun_fighter_s01_tier1"},
	},
}

registerScreenPlay("destroy_duty_tatooine_privateer_6", true)

recovery_duty_tatooine_privateer_5 = SpaceDutyRecoveryScreenplay:new {
	className = "recovery_duty_tatooine_privateer_5",

	questName = "tatooine_privateer_5",
	questType = "recovery_duty",

	questZone = "space_tatooine",

	creditReward = 1000,
	creditKillBonus = 100,
	numResponses = 2,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	recoverShip = "valarian_freighterlight_mining_tier1",
	arrivalDelay = 35,
	recoveryDelay = 18,

	escortShips = {"valarian_gunship_tier1", "valarian_gunship_tier1"},

	preRecoveryPoints = {
		{patrolPointName = "anchorhead_supply_patrol_1", x = 2634, z = -5262, y = 1718, escortNumber = 1, radius = 250},
		{patrolPointName = "bestine_security_escort_1", x = -687, z = -4985, y = 5979, escortNumber = 2, radius = 250},
		{patrolPointName = "bestine_security_patrol_2", x = 1923, z = -3956, y = 3964, escortNumber = 3, radius = 250},
		{patrolPointName = "blacksun_patrol_3", x = 2370, z = 669, y = 1089, escortNumber = 4, radius = 250},
		{patrolPointName = "corellia_imperial_tier3_leg_4_assasinate_two_3", x = 2956, z = -4696, y = 5535, escortNumber = 5, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "anchorhead_armed_recon_2", x = -589, z = -2389, y = 1587, escortNumber = 1, radius = 250},
		{patrolPointName = "privateer_security_patrol_3", x = 2528, z = 2101, y = -316, escortNumber = 2, radius = 250},
		{patrolPointName = "corellia_imperial_tier3_leg_4_assasinate_two_3", x = 2956, z = -4696, y = 5535, escortNumber = 3, radius = 250},
	},

	attackDelay = 100,

	attackShips = {
		{"valarian_bomber_tier1", "valarian_bomber_tier1"},
		{"valarian_gunship_tier1", "valarian_gunship_tier1"},
		{"valarian_gunship_tier2"},
	},

	tauntData = {panicCount = 2, thanksCount = 2},
}

registerScreenPlay("recovery_duty_tatooine_privateer_5", true)

destroy_duty_tatooine_privateer_8 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_tatooine_privateer_8",

	questName = "tatooine_privateer_8",
	questType = "destroy_duty",

	questZone = "space_tatooine",

	creditReward = 100,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	totalLevels = 2,
	totalRounds = 2,
	totalWaves = 2,

	bossShip = "blacksun_ace_s04_tier1",

	shipTypes = {
		{"blacksun_fighter_s03_tier1", "blacksun_fighter_s03_tier1"},
		{"blacksun_bomber_s01_tier1", "blacksun_bomber_s01_tier1"},
		{"blacksun_bomber_s01_tier1", "blacksun_fighter_s02_tier1"},
		{"blacksun_fighter_s03_tier1", "blacksun_fighter_s02_tier1"},
	},
}

registerScreenPlay("destroy_duty_tatooine_privateer_8", true)

escort_duty_tatooine_privateer_7 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_tatooine_privateer_7",

	questName = "tatooine_privateer_7",
	questType = "escort_duty",

	questZone = "space_tatooine",

	creditReward = 1000,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	creditKillBonus = 100,

	escortShips = {"hutt_freightermedium_tier1", "hutt_freighterheavy_tier1"},

	escortPoints = {
		{patrolPointName = "blacksun_patrol_1", zoneName = "space_tatooine", x = -31, z = 275, y = -2950, escortNumber = 1, radius = 250},
		{patrolPointName = "privateer_security_escort_1", zoneName = "space_tatooine", x = 2625, z = 1624, y = 2461, escortNumber = 2, radius = 250},
		{patrolPointName = "privateer_security_escort_4", zoneName = "space_tatooine", x = -2096, z = -1446, y = -2635, escortNumber = 3, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"blacksun_fighter_s03_tier1", "blacksun_fighter_s02_tier1"},
		{"blacksun_aggressor_tier1", "blacksun_aggressor_tier1"},
	},

	tauntData = {goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2},
}

registerScreenPlay("escort_duty_tatooine_privateer_7", true)

--[[
	Transition -- Talon Karrde (Lok)
]]

patrol_tat_priv_quest_trans = SpacePatrolScreenplay:new {
	className = "patrol_tat_priv_quest_trans",

	questName = "tat_priv_quest_trans",
	questType = "patrol",

	questZone = "space_lok",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "tat_priv_quest_trans",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 2,

	-- Screenplay Specific Variables
	patrolPoints = {
		{patrolPointName = "corellia_privateer_tier3_recovery_point_5", x = 4692, z = -604, y = 3823, patrolNumber = 1, radius = 150},
	},
}

registerScreenPlay("patrol_tat_priv_quest_trans", true)

assassinate_tat_priv_quest_trans = SpaceAssassinateScreenplay:new {
	className = "assassinate_tat_priv_quest_trans",

	questType = "assassinate",
	questName = "tat_priv_quest_trans",

	questZone = "space_lok",

	-- Paid by Shamdon Kree on delivery (SWG tatooine_privateer_trainer_shamdon.java:237), not by Karrde
	creditReward = 5000,

	parentQuest = "patrol_tat_priv_quest_trans",
	parentQuestType = "patrol",
	parentQuestName = "tat_priv_quest_trans",

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	arrivalDelay = 5,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "corsair_behemoth_tier2",
		escorts = {"corsair_manowar_tier1", "corsair_manowar_tier1", "corsair_manowar_tier1"},
	},

	targetPatrols = {
		{patrolPointName = "corellia_privateer_tier3_recovery_point_7", x = 5133, z = -1919, y = 2853},
		{patrolPointName = "hostage_recovery_4", x = -6637, z = 2449, y = -2060},
		{patrolPointName = "lok_imp_escort_duty_7", x = 4763, z = -1727, y = 3174},
		{patrolPointName = "lok_imp_recovery_4", x = 1411, z = -1579, y = 134},
	},
}

registerScreenPlay("assassinate_tat_priv_quest_trans", true)

--[[ Tier 2 -- Shamdon Kree (Mos Eisley) ]]

-- Mission 1: Assassinate (Lok)

assassinate_tatooine_privateer_tier2_1a = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_privateer_tier2_1a",

	questType = "assassinate",
	questName = "tatooine_privateer_tier2_1a",

	questZone = "space_lok",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/booster/bst_mission_reward_neutral_mandal_m_series.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	arrivalDelay = 24,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "corsair_behemoth_tier3",
		escorts = {"corsair_raider_tier2", "corsair_raider_tier2"},
	},

	targetPatrols = {
		{patrolPointName = "corellia_privateer_tier3_recovery_point_5", x = 4692, z = -604, y = 3823},
		{patrolPointName = "hostage_escort_2", x = -5951, z = 1295, y = 1027},
		{patrolPointName = "hostage_recovery_5", x = -5082, z = 2428, y = -476},
		{patrolPointName = "lok_imp_escort_duty_7", x = 4763, z = -1727, y = 3174},
	},
}

registerScreenPlay("assassinate_tatooine_privateer_tier2_1a", true)

-- Mission 2: Assassinate (Dantooine)

assassinate_tatooine_privateer_tier2_2a = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_privateer_tier2_2a",

	questType = "assassinate",
	questName = "tatooine_privateer_tier2_2a",

	questZone = "space_dantooine",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon/wpn_mission_reward_neutral_hk_military_blaster.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	arrivalDelay = 0,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "imp_tie_interceptor_tier3",
		escorts = {"imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
	},

	targetPatrols = {
		{patrolPointName = "bh_path_alpha_02", x = 2232, z = -500, y = -100},
		{patrolPointName = "corellia_imperial_tier3_leg_4_assassinate_three_1", x = -136, z = 1280, y = 2628},
		{patrolPointName = "corellia_privateer_tier4_leg_3_space_battle_two", x = 7512, z = -5651, y = 1803},
		{patrolPointName = "tier3_privateer_patrol_01", x = 3576, z = -3193, y = -232},
		{patrolPointName = "tier3_privateer_patrol_02", x = 3501, z = -3467, y = -122},
		{patrolPointName = "tier3_privateer_patrol_03", x = 2615, z = -1486, y = -77},
	},
}

registerScreenPlay("assassinate_tatooine_privateer_tier2_2a", true)

-- Mission 3: Assassinate (Yavin 4)

assassinate_tatooine_privateer_tier2_3a = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_privateer_tier2_3a",

	questType = "assassinate",
	questName = "tatooine_privateer_tier2_3a",

	questZone = "space_yavin4",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/shield_generator/shd_mission_reward_neutral_koensayr_ds23.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	arrivalDelay = 0,
	failTimer = 20,
	mustDestroyEscort = false,

	assassinateSpawns = {
		target = "blacksun_ace_s04_tier2",
		escorts = {"blacksun_fighter_s01_tier2", "blacksun_fighter_s02_tier2", "blacksun_fighter_s03_tier2"},
	},

	targetPatrols = {
		{patrolPointName = "imperial_scout_flight_path_1", x = 3593, z = -1050, y = -3060},
		{patrolPointName = "naboo_privateer_tier4_leg_3_patrol_5", x = -3815, z = 4509, y = 310},
		{patrolPointName = "naboo_privateer_tier4_recovery_duty_egress_4", x = -2365, z = -3545, y = -3776},
		{patrolPointName = "naboo_privateer_tier4_rescue_duty_5", x = 528, z = 5393, y = -6464},
	},
}

registerScreenPlay("assassinate_tatooine_privateer_tier2_3a", true)

-- Mission 4: Escort

escort_tatooine_privateer_tier2_4a = SpaceEscortScreenplay:new {
	className = "escort_tatooine_privateer_tier2_4a",

	questName = "tatooine_privateer_tier2_4a",
	questType = "escort",

	questZone = "space_tatooine",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/droid_interface/ddi_mission_reward_neutral_sorosuub_w19.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	escortShips = {"valarian_freighterlight_mining_tier3"},

	escortPoints = {
		{patrolPointName = "anchorhead_escort_1", zoneName = "space_tatooine", x = 1163, z = -2422, y = 1950, escortNumber = 1, radius = 250},
		{patrolPointName = "anchorhead_supply_patrol_1", zoneName = "space_tatooine", x = 2634, z = -5262, y = 1718, escortNumber = 2, radius = 250},
		{patrolPointName = "anchorhead_supply_patrol_2", zoneName = "space_tatooine", x = 3931, z = -4960, y = 1438, escortNumber = 3, radius = 250},
		{patrolPointName = "anchorhead_supply_patrol_3", zoneName = "space_tatooine", x = 5843, z = -4271, y = -94, escortNumber = 4, radius = 250},
		{patrolPointName = "bestine_commerce_patrol_1", zoneName = "space_tatooine", x = 2217, z = -4387, y = 2967, escortNumber = 5, radius = 250},
		{patrolPointName = "bestine_commerce_patrol_2", zoneName = "space_tatooine", x = 1500, z = -3750, y = 4460, escortNumber = 6, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"hutt_fighter_s02_tier2", "hutt_fighter_s02_tier2"},
		{"hutt_bomber_s02_tier2", "hutt_bomber_s02_tier2", "hutt_fighter_s02_tier2"},
		{"hutt_pirate_s01_tier2", "hutt_pirate_s01_tier2"},
		{"hutt_fighter_s01_tier2", "hutt_fighter_s01_tier2", "hutt_fighter_s01_tier2"},
		{"hutt_pirate_s01_tier2", "hutt_pirate_s01_tier2", "hutt_bomber_s01_tier2", "hutt_bomber_s01_tier2"},
	},

	tauntData = {goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2},
}

registerScreenPlay("escort_tatooine_privateer_tier2_4a", true)

-- Tier 2 Duty Missions

escort_duty_tatooine_privateer_tier2_1 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_tatooine_privateer_tier2_1",

	questName = "tatooine_privateer_tier2_1",
	questType = "escort_duty",

	questZone = "space_lok",

	creditReward = 2500,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	creditKillBonus = 200,

	escortShips = {"valarian_freighterlight_mining_tier2"},

	escortPoints = {
		{patrolPointName = "corellia_privateer_tier3_recovery_point_5", zoneName = "space_lok", x = 4692, z = -604, y = 3823, escortNumber = 1, radius = 250},
		{patrolPointName = "imp_ss_3_navpoint_2", zoneName = "space_lok", x = 7109, z = 1499, y = 1556, escortNumber = 2, radius = 250},
		{patrolPointName = "lok_imp_pirate_3", zoneName = "space_lok", x = -1493, z = -978, y = 1680, escortNumber = 3, radius = 250},
		{patrolPointName = "lok_imp_recovery_1", zoneName = "space_lok", x = 1779, z = 289, y = -1042, escortNumber = 4, radius = 250},
	},

	attackDelay = 120,

	attackShips = {
		{"corsair_raider_tier2", "corsair_raider_tier2"},
		{"corsair_sloop_tier2", "corsair_sloop_tier2"},
		{"corsair_raider_tier2", "corsair_raider_tier2", "corsair_sloop_tier2", "corsair_sloop_tier2"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_tatooine_privateer_tier2_1", true)

recovery_duty_tatooine_privateer_tier2_1 = SpaceDutyRecoveryScreenplay:new {
	className = "recovery_duty_tatooine_privateer_tier2_1",

	questName = "tatooine_privateer_tier2_1",
	questType = "recovery_duty",

	questZone = "space_dantooine",

	creditReward = 2500,
	creditKillBonus = 200,
	numResponses = 2,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	recoverShips = {"freighterheavy_tier3", "freighterlight_tier3", "freightermedium_tier3"},
	arrivalDelay = 12,
	recoveryDelay = 18,

	escortShips = {"imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},

	preRecoveryPoints = {
		{patrolPointName = "bh_path_alpha_01", x = 3913, z = 343, y = 1818, escortNumber = 1, radius = 250},
		{patrolPointName = "bh_path_bravo_03", x = 338, z = 682, y = 954, escortNumber = 2, radius = 250},
		{patrolPointName = "bh_path_bravo_04", x = 2228, z = 596, y = 1534, escortNumber = 3, radius = 250},
		{patrolPointName = "bh_path_bravo_05", x = 4681, z = -250, y = 1515, escortNumber = 4, radius = 250},
		{patrolPointName = "corellia_imperial_tier3_leg_4_assassinate_three_4", x = -1309, z = -2202, y = 2220, escortNumber = 5, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "corellia_imperial_tier3_leg_4_assassinate_three_1", x = -136, z = 1280, y = 2628, escortNumber = 1, radius = 250},
		{patrolPointName = "corellia_imperial_tier4_recoveryduty1_6", x = -1286, z = -5145, y = 130, escortNumber = 2, radius = 250},
		{patrolPointName = "corellia_privateer_tier3_pickup", x = 4170, z = -4074, y = -4613, escortNumber = 3, radius = 250},
	},

	attackDelay = 110,

	attackShips = {
		{"imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
		{"imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_interceptor_tier2"},
		{"imp_tie_bomber_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},
	},

	tauntData = {panicCount = 2, thanksCount = 2},
}

registerScreenPlay("recovery_duty_tatooine_privateer_tier2_1", true)

destroy_duty_tatooine_privateer_tier2_1 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_tatooine_privateer_tier2_1",

	questName = "tatooine_privateer_tier2_1",
	questType = "destroy_duty",

	questZone = "space_yavin4",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	totalLevels = 2,
	totalRounds = 2,
	totalWaves = 2,

	bossShip = "blacksun_marauder_tier3",

	shipTypes = {
		{"blacksun_vehement_tier2", "blacksun_vehement_tier2"},
		{"blacksun_fighter_s01_tier2", "blacksun_fighter_s02_tier2"},
	},
}

registerScreenPlay("destroy_duty_tatooine_privateer_tier2_1", true)

--[[
	Tier 3 -- Beissa (Jabba's Palace; Yavin 4, Dathomir)
	Ported from SWG-Source tatooine_privateer_tier3_1..4 and their splits (recovery, assassinate, destroy_surpriseattack, inspect, survival, delivery_no_pickup, escort, patrol, space_battle, rescue); feature smuggler-tier3-beissa
]]

-- Mission 1: Recovery > Assassinate x3 > Surprise attack (Yavin 4)

recovery_tatooine_privateer_tier3_1 = SpaceRecoveryScreenplay:new {
	className = "recovery_tatooine_privateer_tier3_1",

	questName = "tatooine_privateer_tier3_1",
	questType = "recovery",

	questZone = "space_yavin4",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/reactor/rct_mission_reward_neutral_subpro_military.iff"},
	},

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "tatooine_privateer_tier3_1_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	-- Screenplay Specific Variables
	arrivalDelay = 12,
	recoveryDelay = 32,

	recoverShip = "smuggler_freighterheavy_tier3",
	recoveryConversationMobile = "object/mobile/shared_dressed_criminal_smuggler_human_female_01.iff",

	escortShips = {"valarian_gunship_tier3", "valarian_gunship_tier3", "valarian_bomber_tier3"},

	preRecoveryPoints = {
		{patrolPointName = "tier3_privateer_recover_04", x = 178, z = -2047, y = -3034, escortNumber = 1, radius = 250},
		{patrolPointName = "tier3_privateer_recover_05", x = 2058, z = -2629, y = -3194, escortNumber = 2, radius = 250},
		{patrolPointName = "tier3_privateer_recover_06", x = 3754, z = -2923, y = -2325, escortNumber = 3, radius = 250},
		{patrolPointName = "vortex_mission_3_recovery_3", x = 2101, z = 2448, y = -2498, escortNumber = 4, radius = 250},
		{patrolPointName = "yavin_imp_recovery_5", x = -382, z = 1165, y = -674, escortNumber = 5, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "tier3_privateer_recover_01", x = -2993, z = -3011, y = -3000, escortNumber = 1, radius = 250},
		{patrolPointName = "tier3_privateer_recover_02", x = -268, z = -1795, y = -3050, escortNumber = 2, radius = 250},
		{patrolPointName = "tier3_privateer_recover_03", x = 1481, z = -1414, y = -2051, escortNumber = 3, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"valarian_bomber_tier3", "valarian_bomber_tier3", "valarian_bomber_tier3"},
		{"valarian_gunship_tier3", "valarian_gunship_tier3", "valarian_gunship_tier3"},
	},

	tauntData = {panicCount = 2, thanksCount = 2},
}

registerScreenPlay("recovery_tatooine_privateer_tier3_1", true)

assassinate_tatooine_privateer_tier3_1_a = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_privateer_tier3_1_a",

	questName = "tatooine_privateer_tier3_1_a",
	questType = "assassinate",

	questZone = "space_yavin4",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "tatooine_privateer_tier3_1_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "recovery_tatooine_privateer_tier3_1",
	parentQuestType = "recovery",
	parentQuestName = "tatooine_privateer_tier3_1",

	-- Screenplay Specific Variables
	arrivalDelay = 16,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "valarian_replacement_1_tier3",
		escorts = {"valarian_bomber_tier3", "valarian_bomber_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "tier3_privateer_target_path_01", x = 3658, z = -1769, y = -657},
		{patrolPointName = "tier3_privateer_target_path_02", x = 3261, z = -1501, y = 580},
		{patrolPointName = "tier3_privateer_target_path_03", x = 2328, z = -1146, y = 2498},
		{patrolPointName = "tier3_privateer_target_path_04", x = 570, z = -1145, y = 3582},
	},
}

registerScreenPlay("assassinate_tatooine_privateer_tier3_1_a", true)

assassinate_tatooine_privateer_tier3_1_b = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_privateer_tier3_1_b",

	questName = "tatooine_privateer_tier3_1_b",
	questType = "assassinate",

	questZone = "space_yavin4",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "tatooine_privateer_tier3_1_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "assassinate_tatooine_privateer_tier3_1_a",
	parentQuestType = "assassinate",
	parentQuestName = "tatooine_privateer_tier3_1_a",

	-- Screenplay Specific Variables
	arrivalDelay = 16,
	failTimer = 20,
	mustDestroyEscort = true,

	assassinateSpawns = {
		target = "valarian_replacement_2_tier3",
		escorts = {"valarian_gunship_tier3", "valarian_gunship_tier3", "valarian_gunship_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "tier3_privateer_target_path_01", x = 3658, z = -1769, y = -657},
		{patrolPointName = "tier3_privateer_target_path_02", x = 3261, z = -1501, y = 580},
		{patrolPointName = "tier3_privateer_target_path_03", x = 2328, z = -1146, y = 2498},
		{patrolPointName = "tier3_privateer_target_path_04", x = 570, z = -1145, y = 3582},
	},
}

registerScreenPlay("assassinate_tatooine_privateer_tier3_1_b", true)

assassinate_tatooine_privateer_tier3_1_c = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_privateer_tier3_1_c",

	questName = "tatooine_privateer_tier3_1_c",
	questType = "assassinate",

	questZone = "space_yavin4",

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "tatooine_privateer_tier3_1_d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "assassinate_tatooine_privateer_tier3_1_b",
	parentQuestType = "assassinate",
	parentQuestName = "tatooine_privateer_tier3_1_b",

	-- Screenplay Specific Variables
	arrivalDelay = 16,
	failTimer = 20,
	mustDestroyEscort = false,

	assassinateSpawns = {
		target = "valarian_fighter_replacement",
		escorts = {"valarian_bomber_tier3", "valarian_bomber_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "tier3_privateer_target_path_01", x = 3658, z = -1769, y = -657},
		{patrolPointName = "tier3_privateer_target_path_02", x = 3261, z = -1501, y = 580},
		{patrolPointName = "tier3_privateer_target_path_03", x = 2328, z = -1146, y = 2498},
		{patrolPointName = "tier3_privateer_target_path_04", x = 570, z = -1145, y = 3582},
	},
}

registerScreenPlay("assassinate_tatooine_privateer_tier3_1_c", true)

destroy_surpriseattack_tatooine_privateer_tier3_1_d = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_tatooine_privateer_tier3_1_d",

	questName = "tatooine_privateer_tier3_1_d",
	questType = "destroy_surpriseattack",

	questZone = "space_yavin4",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "assassinate_tatooine_privateer_tier3_1_c",
	parentQuestType = "assassinate",
	parentQuestName = "tatooine_privateer_tier3_1_c",

	-- Screenplay Specific Variables
	surpriseAttackShips = {
		zone = "space_yavin4",
		spawns = {{count = 1, shipName = "valarian_replacement_3_tier3"}},
	},
}

registerScreenPlay("destroy_surpriseattack_tatooine_privateer_tier3_1_d", true)

-- Mission 2: Inspect > Inspect > Survival (Dathomir)

inspect_tatooine_privateer_tier3_2 = SpaceInspectScreenplay:new {
	className = "inspect_tatooine_privateer_tier3_2",

	questName = "tatooine_privateer_tier3_2",
	questType = "inspect",

	questZone = "space_dathomir",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/engine/eng_mission_reward_neutral_mandal_inferno.iff"},
	},

	sideQuest = true,
	sideQuestType = "inspect",
	sideQuestName = "tatooine_privateer_tier3_2_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	-- Screenplay Specific Variables
	shipList = {"dath_witchblood_clan_soldier_tier3"},
	validSpawns = {
		{spawnName = "tier3_privateer_witchblood_inspect_01", x = 6228, z = -6411, y = -5797},
		{spawnName = "tier3_privateer_witchblood_inspect_01", x = -1662, z = 721, y = -313},
	},
	giveSpawnWaypoint = 1,
	cargo = "rally_point_info",
}

registerScreenPlay("inspect_tatooine_privateer_tier3_2", true)

inspect_tatooine_privateer_tier3_2_a = SpaceInspectScreenplay:new {
	className = "inspect_tatooine_privateer_tier3_2_a",

	questName = "tatooine_privateer_tier3_2_a",
	questType = "inspect",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "survival",
	sideQuestName = "tatooine_privateer_tier3_2_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "inspect_tatooine_privateer_tier3_2",
	parentQuestType = "inspect",
	parentQuestName = "tatooine_privateer_tier3_2",

	-- Screenplay Specific Variables
	shipList = {"dath_witchblood_clan_punisher_tier3"},
	validSpawns = {
		{spawnName = "tier3_privateer_witchblood_inspect_02", x = -808, z = -379, y = 1892},
	},
	giveSpawnWaypoint = 1,
	cargo = "hidden_base_info",
}

registerScreenPlay("inspect_tatooine_privateer_tier3_2_a", true)

survival_tatooine_privateer_tier3_2_b = SpaceSurvivalScreenplay:new {
	className = "survival_tatooine_privateer_tier3_2_b",

	questName = "tatooine_privateer_tier3_2_b",
	questType = "survival",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "inspect_tatooine_privateer_tier3_2_a",
	parentQuestType = "inspect",
	parentQuestName = "tatooine_privateer_tier3_2_a",

	-- Screenplay Specific Variables
	transmissionPoint = {patrolPointName = "tier3_privateer_battle_01", x = 2311, z = -1341, y = -2779},
	totalTransmissionTime = 310,
	timesToUpdateProgress = 4,
	transmissionStartDelay = 13,
	delayToFirstAttack = 35,

	attackShipLists = {
		{"dath_witchblood_clan_soldier_tier3", "dath_witchblood_clan_soldier_tier3", "dath_witchblood_clan_soldier_tier3"},
		{"dath_witchblood_clan_punisher_tier3", "dath_witchblood_clan_punisher_tier3", "dath_witchblood_clan_punisher_tier3"},
		{"dath_witchblood_clan_punisher_tier4", "dath_witchblood_clan_punisher_tier4"},
	},

	attackPeriod = 80,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("survival_tatooine_privateer_tier3_2_b", true)

-- Mission 3: Delivery > Delivery > Delivery > Escort (Dathomir)

delivery_no_pickup_tatooine_privateer_tier3_3 = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_tatooine_privateer_tier3_3",

	questName = "tatooine_privateer_tier3_3",
	questType = "delivery_no_pickup",

	questZone = "space_dathomir",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon_capacitor/cap_mission_reward_neutral_sorosuub_v1.iff"},
	},

	sideQuest = true,
	sideQuestType = "delivery_no_pickup",
	sideQuestName = "tatooine_privateer_tier3_3_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	-- Screenplay Specific Variables
	deliveryShip = "imp_vip_shuttle_tier3",

	deliveryPoint = {patrolPointName = "tier3_privateer_deliver_dropoff_01", x = -1510, z = -2732, y = -3171},

	attackShipLists = {
		{"death_watch_eradicator_tier3", "death_watch_eradicator_tier3", "death_watch_eradicator_tier3"},
		{"death_watch_prowler_tier3", "death_watch_prowler_tier3", "death_watch_prowler_tier3", "death_watch_prowler_tier3"},
		{"death_watch_assassin_tier3", "death_watch_assassin_tier3", "death_watch_assassin_tier3", "death_watch_assassin_tier3"},
	},

	attackPeriod = 60,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_no_pickup_tatooine_privateer_tier3_3", true)

delivery_no_pickup_tatooine_privateer_tier3_3_a = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_tatooine_privateer_tier3_3_a",

	questName = "tatooine_privateer_tier3_3_a",
	questType = "delivery_no_pickup",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "delivery_no_pickup",
	sideQuestName = "tatooine_privateer_tier3_3_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "delivery_no_pickup_tatooine_privateer_tier3_3",
	parentQuestType = "delivery_no_pickup",
	parentQuestName = "tatooine_privateer_tier3_3",

	-- Screenplay Specific Variables
	deliveryShip = "imp_vip_shuttle_tier3",

	deliveryPoint = {patrolPointName = "tier3_privateer_deliver_dropoff_02", x = -841, z = -2922, y = -2993},

	attackShipLists = {
		{"dath_freelance_killer_tier3", "dath_freelance_killer_tier3", "dath_freelance_killer_tier3"},
		{"dath_witchblood_clan_punisher_tier3", "dath_witchblood_clan_punisher_tier3", "dath_witchblood_clan_punisher_tier3", "dath_witchblood_clan_punisher_tier3"},
	},

	attackPeriod = 55,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_no_pickup_tatooine_privateer_tier3_3_a", true)

delivery_no_pickup_tatooine_privateer_tier3_3_b = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_tatooine_privateer_tier3_3_b",

	questName = "tatooine_privateer_tier3_3_b",
	questType = "delivery_no_pickup",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "tatooine_privateer_tier3_3_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "delivery_no_pickup_tatooine_privateer_tier3_3_a",
	parentQuestType = "delivery_no_pickup",
	parentQuestName = "tatooine_privateer_tier3_3_a",

	-- Screenplay Specific Variables
	deliveryShip = "lambdashuttle_inquisition_data_vessel",

	deliveryPoint = {patrolPointName = "tier3_privateer_deliver_dropoff_03", x = -1113, z = -2088, y = -3144},

	attackShipLists = {
		{"death_watch_eradicator_tier3", "death_watch_assassin_tier3", "death_watch_assassin_tier3", "death_watch_prowler_tier3", "death_watch_prowler_tier3"},
	},

	attackPeriod = 65,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_no_pickup_tatooine_privateer_tier3_3_b", true)

escort_tatooine_privateer_tier3_3_c = SpaceEscortScreenplay:new {
	className = "escort_tatooine_privateer_tier3_3_c",

	questName = "tatooine_privateer_tier3_3_c",
	questType = "escort",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "delivery_no_pickup_tatooine_privateer_tier3_3_b",
	parentQuestType = "delivery_no_pickup",
	parentQuestName = "tatooine_privateer_tier3_3_b",

	-- Screenplay Specific Variables
	escortShips = {"imp_vip_shuttle_tier3"},

	escortPoints = {
		{patrolPointName = "tier3_privateer_escort_path_01", zoneName = "space_dathomir", x = 3520, z = -1695, y = -229, escortNumber = 1, radius = 250},
		{patrolPointName = "tier3_privateer_escort_path_02", zoneName = "space_dathomir", x = 856, z = -1291, y = -993, escortNumber = 2, radius = 250},
		{patrolPointName = "tier3_privateer_escort_path_03", zoneName = "space_dathomir", x = -253, z = -3197, y = -1661, escortNumber = 3, radius = 250},
		{patrolPointName = "tier3_privateer_escort_path_04", zoneName = "space_dathomir", x = -1587, z = -3210, y = -2825, escortNumber = 4, radius = 250},
		{patrolPointName = "tier3_privateer_escort_path_05", zoneName = "space_dathomir", x = -3011, z = -2871, y = -3354, escortNumber = 5, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"dath_freelance_killer_tier3", "dath_freelance_killer_tier3", "dath_freelance_killer_tier3"},
		{"dath_freelance_killer_tier3", "dath_freelance_killer_tier3"},
	},

	tauntData = {goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2},
}

registerScreenPlay("escort_tatooine_privateer_tier3_3_c", true)

-- Mission 4: Patrol > Space battle x2 > Patrol > Rescue (Dathomir)

patrol_tatooine_privateer_tier3_4 = SpacePatrolScreenplay:new {
	className = "patrol_tatooine_privateer_tier3_4",

	questName = "tatooine_privateer_tier3_4",
	questType = "patrol",

	questZone = "space_dathomir",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/armor/arm_mission_reward_neutral_kse_handcrafted.iff"},
	},

	sideQuest = true,
	sideQuestType = "space_battle",
	sideQuestName = "tatooine_privateer_tier3_4_a",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 8,

	-- Screenplay Specific Variables
	patrolPoints = {
		{patrolPointName = "tier3_privateer_patrol_01", x = 3576, z = -3193, y = -232, patrolNumber = 1, radius = 150},
		{patrolPointName = "tier3_privateer_patrol_02", x = 3501, z = -3467, y = -122, patrolNumber = 2, radius = 150},
		{patrolPointName = "tier3_privateer_patrol_03", x = 2615, z = -1486, y = -77, patrolNumber = 3, radius = 150},
	},
}

registerScreenPlay("patrol_tatooine_privateer_tier3_4", true)

space_battle_tatooine_privateer_tier3_4_a = SpaceBattleScreenplay:new {
	className = "space_battle_tatooine_privateer_tier3_4_a",

	questName = "tatooine_privateer_tier3_4_a",
	questType = "space_battle",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "space_battle",
	sideQuestName = "tatooine_privateer_tier3_4_b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "patrol_tatooine_privateer_tier3_4",
	parentQuestType = "patrol",
	parentQuestName = "tatooine_privateer_tier3_4",

	-- Screenplay Specific Variables
	battlePoint = {patrolPointName = "tier3_privateer_battle_01", x = 2311, z = -1341, y = -2779, forward = {x = 0.092084, z = 0.173348, y = -0.980546}},

	damageMultiplier = 4,
	allyArrivalDelay = 4,
	enemyArrivalDelay = 5,
	allyOriginDist = 300,
	enemyOriginDist = -300,
	allyArrivalDist = 100,
	enemyArrivalDist = -100,

	allyForce = {
		"hutt_bomber_s02_tier3", "hutt_bomber_s02_tier3", "hutt_fighter_s02_tier3", "hutt_fighter_s02_tier3",
	},

	enemyForce = {
		"rancor_clan_ace_tier3", "rancor_clan_ace_tier3", "rancor_clan_elite_tier3", "rancor_clan_elite_tier3",
		"rancor_clan_gunship_tier3", "rancor_clan_gunship_tier3",
	},
}

registerScreenPlay("space_battle_tatooine_privateer_tier3_4_a", true)

space_battle_tatooine_privateer_tier3_4_b = SpaceBattleScreenplay:new {
	className = "space_battle_tatooine_privateer_tier3_4_b",

	questName = "tatooine_privateer_tier3_4_b",
	questType = "space_battle",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "patrol",
	sideQuestName = "tatooine_privateer_tier3_4_c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,

	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "space_battle_tatooine_privateer_tier3_4_a",
	parentQuestType = "space_battle",
	parentQuestName = "tatooine_privateer_tier3_4_a",

	-- Screenplay Specific Variables
	battlePoint = {patrolPointName = "tier3_privateer_battle_02", x = 3140, z = -2524, y = -3464, forward = {x = 0.474276, z = -0.799720, y = 0.368118}},

	damageMultiplier = 4,
	allyArrivalDelay = 4,
	enemyArrivalDelay = 5,
	allyOriginDist = 300,
	enemyOriginDist = -300,
	allyArrivalDist = 100,
	enemyArrivalDist = -100,

	allyForce = {
		"hutt_fighter_s01_tier3", "hutt_pirate_s02_tier3", "hutt_pirate_s02_tier3", "hutt_yt1300_tier3",
	},

	enemyForce = {
		"rancor_clan_ace_tier3", "rancor_clan_gunship_tier4", "rancor_clan_gunship_tier4", "rancor_clan_gunship_tier4",
		"rancor_clan_soldier_tier3", "rancor_clan_soldier_tier3", "rancor_clan_soldier_tier3",
	},
}

registerScreenPlay("space_battle_tatooine_privateer_tier3_4_b", true)

patrol_tatooine_privateer_tier3_4_c = SpacePatrolScreenplay:new {
	className = "patrol_tatooine_privateer_tier3_4_c",

	questName = "tatooine_privateer_tier3_4_c",
	questType = "patrol",

	questZone = "space_dathomir",

	sideQuest = true,
	sideQuestType = "rescue",
	sideQuestName = "tatooine_privateer_tier3_4_d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 7,

	parentQuest = "space_battle_tatooine_privateer_tier3_4_b",
	parentQuestType = "space_battle",
	parentQuestName = "tatooine_privateer_tier3_4_b",

	-- Screenplay Specific Variables
	patrolPoints = {
		{patrolPointName = "tier3_privateer_ally_patrol_01", x = 3427, z = -2819, y = -2499, patrolNumber = 1, radius = 150},
		{patrolPointName = "tier3_privateer_ally_patrol_02", x = 3218, z = -1947, y = -970, patrolNumber = 2, radius = 150},
		{patrolPointName = "tier3_privateer_ally_patrol_03", x = 3355, z = -567, y = -115, patrolNumber = 3, radius = 150},
	},
}

registerScreenPlay("patrol_tatooine_privateer_tier3_4_c", true)

rescue_tatooine_privateer_tier3_4_d = SpaceRescueScreenplay:new {
	className = "rescue_tatooine_privateer_tier3_4_d",

	questName = "tatooine_privateer_tier3_4_d",
	questType = "rescue",

	questZone = "space_dathomir",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_tatooine_privateer_tier3_4_c",
	parentQuestType = "patrol",
	parentQuestName = "tatooine_privateer_tier3_4_c",

	-- Screenplay Specific Variables
	recoveryPath = {
		{patrolPointName = "tier3_privateer_ally_escort_01", x = 3335, z = 553, y = 423},
		{patrolPointName = "tier3_privateer_ally_escort_02", x = 3352, z = 930, y = 1697},
		{patrolPointName = "tier3_privateer_ally_escort_03", x = 2950, z = -691, y = 2728},
	},

	targetShipType = "hutt_vip_transport_tier3",
	targetArrivalDelay = 8,

	attackShipLists = {
		{"rancor_clan_gunship_tier3", "rancor_clan_gunship_tier3", "rancor_clan_gunship_tier3", "rancor_clan_gunship_tier3"},
		{"rancor_clan_ace_tier3", "rancor_clan_ace_tier3"},
	},

	attackPeriod = 100,
	attackListType = SpaceRescueScreenplay.ATTACK_LIST_TYPES.RANDOM,
	numResponses = 2,
}

registerScreenPlay("rescue_tatooine_privateer_tier3_4_d", true)

--[[
	Smuggler Squadron Screenplay
]]

SmugglerSquadronScreenplay = ScreenPlay:new {
	screenplayName = "SmugglerSquadronScreenplay",

	-- Tier 1 (Dravis) Quest Strings
	QUEST_STRING_1 = {type = "patrol", name = "tatooine_privateer_1"},
	QUEST_STRING_1_SIDE = {type = "destroy_surpriseattack", name = "tatooine_privateer_1"},
	QUEST_STRING_2 = {type = "destroy", name = "tatooine_privateer_2"},
	QUEST_STRING_3 = {type = "patrol", name = "tatooine_privateer_3"},
	QUEST_STRING_3_SIDE = {type = "escort", name = "tatooine_privateer_3"},
	QUEST_STRING_4 = {type = "assassinate", name = "tatooine_privateer_tier1_4a"},

	-- Tier 1 Duty Quest Strings (SWG duty menu order)
	QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "tatooine_privateer_6"},
	QUEST_STRING_DUTY_2 = {type = "recovery_duty", name = "tatooine_privateer_5"},
	QUEST_STRING_DUTY_3 = {type = "destroy_duty", name = "tatooine_privateer_8"},
	QUEST_STRING_DUTY_4 = {type = "escort_duty", name = "tatooine_privateer_7"},

	-- Transition (Talon Karrde) Quest Strings
	QUEST_STRING_TRANS = {type = "patrol", name = "tat_priv_quest_trans"},
	QUEST_STRING_TRANS_SIDE = {type = "assassinate", name = "tat_priv_quest_trans"},

	-- Tier 2 (Shamdon Kree) Quest Strings, SWG flag order (mission n)
	TIER2_QUEST_STRING_1 = {type = "assassinate", name = "tatooine_privateer_tier2_1a"},
	TIER2_QUEST_STRING_2 = {type = "assassinate", name = "tatooine_privateer_tier2_2a"},
	TIER2_QUEST_STRING_3 = {type = "assassinate", name = "tatooine_privateer_tier2_3a"},
	TIER2_QUEST_STRING_4 = {type = "escort", name = "tatooine_privateer_tier2_4a"},

	-- Tier 2 Duty Quest Strings (SWG duty menu order)
	TIER2_QUEST_STRING_DUTY_1 = {type = "escort_duty", name = "tatooine_privateer_tier2_1"},
	TIER2_QUEST_STRING_DUTY_2 = {type = "recovery_duty", name = "tatooine_privateer_tier2_1"},
	TIER2_QUEST_STRING_DUTY_3 = {type = "destroy_duty", name = "tatooine_privateer_tier2_1"},

	-- Tier 3 (Beissa) Quest Strings, SWG mission order; SIDEk = the k-th split child
	TIER3_QUEST_STRING_1 = {type = "recovery", name = "tatooine_privateer_tier3_1"},
	TIER3_QUEST_STRING_1_SIDE1 = {type = "assassinate", name = "tatooine_privateer_tier3_1_a"},
	TIER3_QUEST_STRING_1_SIDE2 = {type = "assassinate", name = "tatooine_privateer_tier3_1_b"},
	TIER3_QUEST_STRING_1_SIDE3 = {type = "assassinate", name = "tatooine_privateer_tier3_1_c"},
	TIER3_QUEST_STRING_1_SIDE4 = {type = "destroy_surpriseattack", name = "tatooine_privateer_tier3_1_d"},
	TIER3_QUEST_STRING_2 = {type = "inspect", name = "tatooine_privateer_tier3_2"},
	TIER3_QUEST_STRING_2_SIDE1 = {type = "inspect", name = "tatooine_privateer_tier3_2_a"},
	TIER3_QUEST_STRING_2_SIDE2 = {type = "survival", name = "tatooine_privateer_tier3_2_b"},
	TIER3_QUEST_STRING_3 = {type = "delivery_no_pickup", name = "tatooine_privateer_tier3_3"},
	TIER3_QUEST_STRING_3_SIDE1 = {type = "delivery_no_pickup", name = "tatooine_privateer_tier3_3_a"},
	TIER3_QUEST_STRING_3_SIDE2 = {type = "delivery_no_pickup", name = "tatooine_privateer_tier3_3_b"},
	TIER3_QUEST_STRING_3_SIDE3 = {type = "escort", name = "tatooine_privateer_tier3_3_c"},
	TIER3_QUEST_STRING_4 = {type = "patrol", name = "tatooine_privateer_tier3_4"},
	TIER3_QUEST_STRING_4_SIDE1 = {type = "space_battle", name = "tatooine_privateer_tier3_4_a"},
	TIER3_QUEST_STRING_4_SIDE2 = {type = "space_battle", name = "tatooine_privateer_tier3_4_b"},
	TIER3_QUEST_STRING_4_SIDE3 = {type = "patrol", name = "tatooine_privateer_tier3_4_c"},
	TIER3_QUEST_STRING_4_SIDE4 = {type = "rescue", name = "tatooine_privateer_tier3_4_d"},

	-- Dravis has told the player to come back with a ship (server memory, as SWG's scriptVar)
	MET_DRAVIS_KEY = "SmugglerSquadronScreenplay:metDravis",
}

registerScreenPlay("SmugglerSquadronScreenplay", false)

function SmugglerSquadronScreenplay:start()
end

--[[
	Tier 1 -- Dravis
]]

function SmugglerSquadronScreenplay:resetDravisQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	-- Mission 1
	patrol_tatooine_privateer_1:resetQuest(pPlayer)
	destroy_surpriseattack_tatooine_privateer_1:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_1.type, self.QUEST_STRING_1.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_1_SIDE.type, self.QUEST_STRING_1_SIDE.name, false)

	-- Mission 2
	destroy_tatooine_privateer_2:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_2.type, self.QUEST_STRING_2.name, false)

	-- Mission 3
	patrol_tatooine_privateer_3:resetQuest(pPlayer)
	escort_tatooine_privateer_3:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_3.type, self.QUEST_STRING_3.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_3_SIDE.type, self.QUEST_STRING_3_SIDE.name, false)

	-- Mission 4
	assassinate_tatooine_privateer_tier1_4a:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_4.type, self.QUEST_STRING_4.name, false)

	-- Duty Missions
	destroy_duty_tatooine_privateer_6:resetQuest(pPlayer)
	recovery_duty_tatooine_privateer_5:resetQuest(pPlayer)
	destroy_duty_tatooine_privateer_8:resetQuest(pPlayer)
	escort_duty_tatooine_privateer_7:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_DUTY_1.type, self.QUEST_STRING_DUTY_1.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_DUTY_2.type, self.QUEST_STRING_DUTY_2.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_DUTY_3.type, self.QUEST_STRING_DUTY_3.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_DUTY_4.type, self.QUEST_STRING_DUTY_4.name, false)

	local playerID = CreatureObject(pPlayer):getObjectID()

	removeQuestStatus(playerID .. self.QUEST_STRING_1.name .. ":attempted")
	removeQuestStatus(playerID .. self.QUEST_STRING_2.name .. ":attempted")
	removeQuestStatus(playerID .. self.QUEST_STRING_3.name .. ":attempted")
	removeQuestStatus(playerID .. self.QUEST_STRING_4.name .. ":attempted")
	removeQuestStatus(playerID .. self.QUEST_STRING_1.name .. ":reward")
	removeQuestStatus(playerID .. self.QUEST_STRING_2.name .. ":reward")
	removeQuestStatus(playerID .. self.QUEST_STRING_3.name .. ":reward")
	removeQuestStatus(playerID .. self.QUEST_STRING_4.name .. ":reward")

	deleteData(playerID .. self.MET_DRAVIS_KEY)
end

--[[
	Transition -- Talon Karrde
]]

-- SWG hasWonQuestRecursive: both halves of the split quest are complete
function SmugglerSquadronScreenplay:hasWonTransQuest(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, self.QUEST_STRING_TRANS.type, self.QUEST_STRING_TRANS.name)
		and SpaceHelpers:isSpaceQuestComplete(pPlayer, self.QUEST_STRING_TRANS_SIDE.type, self.QUEST_STRING_TRANS_SIDE.name)
end

function SmugglerSquadronScreenplay:resetKarrdeQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	patrol_tat_priv_quest_trans:resetQuest(pPlayer)
	assassinate_tat_priv_quest_trans:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_TRANS.type, self.QUEST_STRING_TRANS.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_TRANS_SIDE.type, self.QUEST_STRING_TRANS_SIDE.name, false)

	local playerID = CreatureObject(pPlayer):getObjectID()

	removeQuestStatus(playerID .. self.QUEST_STRING_TRANS.name .. ":attempted")
	removeQuestStatus(playerID .. self.QUEST_STRING_TRANS.name .. ":reward")
end

--[[
	Tier 2 -- Shamdon Kree
]]

-- SWG hasCompletedSeries: the four tier 2 skills and the four missions won (paid or not)
function SmugglerSquadronScreenplay:hasCompletedTier2Series(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 2)) then
		return false
	end

	for n = 1, 4 do
		local questString = self["TIER2_QUEST_STRING_" .. n]

		if (not SpaceHelpers:isSpaceQuestComplete(pPlayer, questString.type, questString.name)) then
			return false
		end
	end

	return true
end

function SmugglerSquadronScreenplay:resetShamdonQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	-- Missions
	assassinate_tatooine_privateer_tier2_1a:resetQuest(pPlayer)
	assassinate_tatooine_privateer_tier2_2a:resetQuest(pPlayer)
	assassinate_tatooine_privateer_tier2_3a:resetQuest(pPlayer)
	escort_tatooine_privateer_tier2_4a:resetQuest(pPlayer)

	-- Duty Missions
	escort_duty_tatooine_privateer_tier2_1:resetQuest(pPlayer)
	recovery_duty_tatooine_privateer_tier2_1:resetQuest(pPlayer)
	destroy_duty_tatooine_privateer_tier2_1:resetQuest(pPlayer)

	for n = 1, 4 do
		local questString = self["TIER2_QUEST_STRING_" .. n]

		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	for n = 1, 3 do
		local questString = self["TIER2_QUEST_STRING_DUTY_" .. n]

		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	for n = 1, 4 do
		local name = self["TIER2_QUEST_STRING_" .. n].name

		removeQuestStatus(playerID .. name .. ":attempted")
		removeQuestStatus(playerID .. name .. ":reward")
	end
end

--[[
	Tier 3 -- Beissa
]]

function SmugglerSquadronScreenplay:resetBeissaQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	recovery_tatooine_privateer_tier3_1:resetQuest(pPlayer)
	assassinate_tatooine_privateer_tier3_1_a:resetQuest(pPlayer)
	assassinate_tatooine_privateer_tier3_1_b:resetQuest(pPlayer)
	assassinate_tatooine_privateer_tier3_1_c:resetQuest(pPlayer)
	destroy_surpriseattack_tatooine_privateer_tier3_1_d:resetQuest(pPlayer)
	inspect_tatooine_privateer_tier3_2:resetQuest(pPlayer)
	inspect_tatooine_privateer_tier3_2_a:resetQuest(pPlayer)
	survival_tatooine_privateer_tier3_2_b:resetQuest(pPlayer)
	delivery_no_pickup_tatooine_privateer_tier3_3:resetQuest(pPlayer)
	delivery_no_pickup_tatooine_privateer_tier3_3_a:resetQuest(pPlayer)
	delivery_no_pickup_tatooine_privateer_tier3_3_b:resetQuest(pPlayer)
	escort_tatooine_privateer_tier3_3_c:resetQuest(pPlayer)
	patrol_tatooine_privateer_tier3_4:resetQuest(pPlayer)
	space_battle_tatooine_privateer_tier3_4_a:resetQuest(pPlayer)
	space_battle_tatooine_privateer_tier3_4_b:resetQuest(pPlayer)
	patrol_tatooine_privateer_tier3_4_c:resetQuest(pPlayer)
	rescue_tatooine_privateer_tier3_4_d:resetQuest(pPlayer)

	local questStrings = {
		self.TIER3_QUEST_STRING_1,
		self.TIER3_QUEST_STRING_1_SIDE1,
		self.TIER3_QUEST_STRING_1_SIDE2,
		self.TIER3_QUEST_STRING_1_SIDE3,
		self.TIER3_QUEST_STRING_1_SIDE4,
		self.TIER3_QUEST_STRING_2,
		self.TIER3_QUEST_STRING_2_SIDE1,
		self.TIER3_QUEST_STRING_2_SIDE2,
		self.TIER3_QUEST_STRING_3,
		self.TIER3_QUEST_STRING_3_SIDE1,
		self.TIER3_QUEST_STRING_3_SIDE2,
		self.TIER3_QUEST_STRING_3_SIDE3,
		self.TIER3_QUEST_STRING_4,
		self.TIER3_QUEST_STRING_4_SIDE1,
		self.TIER3_QUEST_STRING_4_SIDE2,
		self.TIER3_QUEST_STRING_4_SIDE3,
		self.TIER3_QUEST_STRING_4_SIDE4,
	}

	for _, questString in ipairs(questStrings) do
		SpaceHelpers:clearSpaceQuest(pPlayer, questString.type, questString.name, false)
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	for n = 1, 4 do
		local name = "tatooine_privateer_tier3_" .. n

		removeQuestStatus(playerID .. name .. ":attempted")
		removeQuestStatus(playerID .. name .. ":reward")
	end
end
