local Logger = require("utils.logger")

--[[

	RSF Squadron Missions

]]

--[[
	Tier 1 -- Dinge Main Missions
]]

-- Mission 1: Patrol

patrol_naboo_privateer_1 = SpacePatrolScreenplay:new {
	className = "patrol_naboo_privateer_1",

	questName = "naboo_privateer_1",
	questType = "patrol",

	questZone = "space_naboo",

	creditReward = 100,

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_privateer_1",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 20,

	-- Screenplay Specific Variables
	patrolPoints = {
		{patrolPointName = "privateer_patrol_1", x = 752, z = 659, y = -2444, patrolNumber = 1, radius = 150},
		{patrolPointName = "privateer_patrol_2", x = 2031, z = 887, y = -1759, patrolNumber = 2, radius = 150},
		{patrolPointName = "privateer_patrol_3", x = 2466, z = 854, y = -505, patrolNumber = 3, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_privateer_1", true)

destroy_surpriseattack_naboo_privateer_1 = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_privateer_1",

	questName = "naboo_privateer_1",
	questType = "destroy_surpriseattack",

	questZone = "space_naboo",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_naboo_privateer_1",
	parentQuestType = "patrol",
	parentQuestName = "naboo_privateer_1",

	-- Screenplay Specific Variables
	surpriseAttackShips = {
		zone = "space_naboo",
		spawns = {{count = 1, shipName = "blacksun_fighter_s02_tier1"}, {count = 3, shipName = "blacksun_fighter_s01_tier1"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_privateer_1", true)

-- Mission 2: Destroy

destroy_naboo_privateer_2 = SpaceDestroyScreenplay:new {
	className = "destroy_naboo_privateer_2",

	questName = "naboo_privateer_2",
	questType = "destroy",

	questZone = "space_naboo",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	killsRequired = 4,

	shipLocations = {
		{patrolPointName = "privateer_patrol_1", x = 752, z = 659, y = -2444},
		{patrolPointName = "privateer_patrol_2", x = 2031, z = 887, y = -1759},
		{patrolPointName = "privateer_patrol_3", x = 2466, z = 854, y = -505},
	},

	shipTypes = {
		"blacksun_ace_s04_tier1", "blacksun_ace_s04_tier2", "blacksun_aggressor_tier1", "blacksun_aggressor_tier2",
		"blacksun_bomber_s01_tier1", "blacksun_bomber_s01_tier2", "blacksun_bomber_s02_tier1", "blacksun_bomber_s02_tier2",
		"blacksun_fighter_s01_tier1", "blacksun_fighter_s01_tier2", "blacksun_fighter_s02_tier1", "blacksun_fighter_s02_tier2",
		"blacksun_fighter_s03_tier1", "blacksun_fighter_s03_tier2", "blacksun_gunship_tier1", "blacksun_gunship_tier2",
	},
}

registerScreenPlay("destroy_naboo_privateer_2", true)

-- Mission 3: Patrol with Escort side quest

patrol_naboo_privateer_3 = SpacePatrolScreenplay:new {
	className = "patrol_naboo_privateer_3",

	questName = "naboo_privateer_3",
	questType = "patrol",

	questZone = "space_naboo",

	creditReward = 500,
	itemReward = {
		{species = {SPECIES_ITHORIAN}, item = "object/tangible/wearables/bandolier/ith_mercenary_bandolier.iff"},
		{species = {-1}, item = "object/tangible/wearables/bandolier/mercenary_bandolier.iff"},
	},

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "naboo_privateer_3",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 20,

	-- Screenplay Specific Variables
	patrolPoints = {
		{patrolPointName = "privateer_security_patrol_1", x = 2479, z = -500, y = 1187, patrolNumber = 1, radius = 150},
		{patrolPointName = "privateer_security_patrol_2", x = 3251, z = -414, y = 2349, patrolNumber = 2, radius = 150},
		{patrolPointName = "privateer_security_patrol_3", x = 3039, z = -499, y = 3761, patrolNumber = 3, radius = 150},
		{patrolPointName = "privateer_security_patrol_4", x = 2500, z = -400, y = 4500, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_privateer_3", true)

escort_naboo_privateer_3 = SpaceEscortScreenplay:new {
	className = "escort_naboo_privateer_3",

	questName = "naboo_privateer_3",
	questType = "escort",

	questZone = "space_naboo",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_naboo_privateer_3",
	parentQuestType = "patrol",
	parentQuestName = "naboo_privateer_3",

	-- Screenplay Specific Variables
	escortShips = {"freighterheavy_tier1"},

	escortPoints = {
		{patrolPointName = "privateer_escort_1", zoneName = "space_naboo", x = 3200, z = -400, y = 2600, escortNumber = 1, radius = 250},
		{patrolPointName = "privateer_escort_2", zoneName = "space_naboo", x = 2800, z = -450, y = 3200, escortNumber = 2, radius = 250},
		{patrolPointName = "privateer_escort_3", zoneName = "space_naboo", x = 2400, z = -400, y = 4000, escortNumber = 3, radius = 250},
		{patrolPointName = "privateer_escort_4", zoneName = "space_naboo", x = 2000, z = -350, y = 4800, escortNumber = 4, radius = 250},
	},

	attackDelay = 90,

	attackShips = {
		{"blacksun_fighter_s02_tier1", "blacksun_fighter_s03_tier1", "blacksun_fighter_s02_tier1"},
	}
}

registerScreenPlay("escort_naboo_privateer_3", true)

-- Mission 4: Assassinate

assassinate_naboo_privateer_tier1_4a = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_privateer_tier1_4a",

	questType = "assassinate",
	questName = "naboo_privateer_tier1_4a",

	questZone = "space_naboo",

	creditReward = 1000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon/wpn_mission_reward_neutral_mandal_light_blaster.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	arrivalDelay = 6,
	failTimer = 20,

	assassinateTarget = {
		zone = "space_naboo",
		ship = "blacksun_ace_s04_tier1",
		x = 1500, z = 500, y = -1000,
	},

	assassinateWingmen = {
		zone = "space_naboo",
		spawns = {{count = 2, shipName = "blacksun_fighter_s02_tier1"}},
	},
}

registerScreenPlay("assassinate_naboo_privateer_tier1_4a", true)

-- Tier 1 Duty Missions

destroy_duty_naboo_privateer_6 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_naboo_privateer_6",

	questName = "naboo_privateer_6",
	questType = "destroy_duty",

	questZone = "space_naboo",

	creditReward = 50,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	dutyMissionLevel = 1,

	shipLocations = {
		{patrolPointName = "privateer_patrol_1", x = 752, z = 659, y = -2444},
		{patrolPointName = "privateer_patrol_2", x = 2031, z = 887, y = -1759},
		{patrolPointName = "privateer_patrol_3", x = 2466, z = 854, y = -505},
	},

	shipTypes = {
		"blacksun_fighter_s01_tier1", "blacksun_fighter_s02_tier1", "blacksun_fighter_s03_tier1",
		"blacksun_bomber_s01_tier1", "blacksun_bomber_s02_tier1",
	},
}

registerScreenPlay("destroy_duty_naboo_privateer_6", true)

escort_duty_naboo_privateer_7 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_naboo_privateer_7",

	questName = "naboo_privateer_7",
	questType = "escort_duty",

	questZone = "space_naboo",

	creditReward = 75,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	dutyMissionLevel = 1,

	escortShips = {"freighterheavy_tier1", "freighterlight_tier1"},

	escortPoints = {
		{patrolPointName = "stn_rori_rsf_escort_duty_1", zoneName = "space_naboo", x = 832, z = 2355, y = -6460, escortNumber = 1, radius = 250},
		{patrolPointName = "stn_rori_rsf_escort_duty_2", zoneName = "space_naboo", x = 5504, z = 1267, y = -4332, escortNumber = 2, radius = 250},
		{patrolPointName = "stn_rori_rsf_escort_duty_3", zoneName = "space_naboo", x = 6352, z = -220, y = 1363, escortNumber = 3, radius = 250},
	},

	attackShips = {
		{"blacksun_fighter_s01_tier1", "blacksun_fighter_s02_tier1"},
		{"blacksun_fighter_s01_tier1", "blacksun_fighter_s02_tier1", "blacksun_fighter_s03_tier1"},
	}
}

registerScreenPlay("escort_duty_naboo_privateer_7", true)

--[[
	Tier 2 -- Captain Kaydine Main Missions
]]

-- Mission 1: Destroy (5 kills)

destroy_naboo_privateer_13a = SpaceDestroyScreenplay:new {
	className = "destroy_naboo_privateer_13a",

	questName = "naboo_privateer_13a",
	questType = "destroy",

	questZone = "space_naboo",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/booster/bst_mission_reward_neutral_mandal_m_series.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	killsRequired = 5,

	shipLocations = {},

	shipTypes = {
		"blacksun_ace_s04_tier2", "blacksun_ace_s04_tier3", "blacksun_aggressor_tier2", "blacksun_aggressor_tier3",
		"blacksun_bomber_s01_tier2", "blacksun_bomber_s01_tier3", "blacksun_bomber_s02_tier2", "blacksun_bomber_s02_tier3",
		"blacksun_fighter_s01_tier2", "blacksun_fighter_s01_tier3", "blacksun_fighter_s02_tier2", "blacksun_fighter_s02_tier3",
		"blacksun_fighter_s03_tier2", "blacksun_fighter_s03_tier3", "blacksun_gunship_tier2", "blacksun_gunship_tier3",
	},
}

registerScreenPlay("destroy_naboo_privateer_13a", true)

-- Mission 2: Escort

escort_naboo_privateer_14 = SpaceEscortScreenplay:new {
	className = "escort_naboo_privateer_14",

	questName = "naboo_privateer_14",
	questType = "escort",

	questZone = "space_naboo",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon/wpn_mission_reward_neutral_hk_military_blaster.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	escortShips = {"freighterheavy_tier3"},

	escortPoints = {
		{patrolPointName = "rsf_tier2_escort_1", zoneName = "space_naboo", x = 3500, z = 500, y = -2000, escortNumber = 1, radius = 250},
		{patrolPointName = "rsf_tier2_escort_2", zoneName = "space_naboo", x = 4200, z = 300, y = -500, escortNumber = 2, radius = 250},
		{patrolPointName = "rsf_tier2_escort_3", zoneName = "space_naboo", x = 5000, z = 100, y = 1000, escortNumber = 3, radius = 250},
		{patrolPointName = "rsf_tier2_escort_4", zoneName = "space_naboo", x = 5500, z = -200, y = 2500, escortNumber = 4, radius = 250},
	},

	attackDelay = 180,

	attackShips = {
		{"blacksun_fighter_s02_tier2", "blacksun_fighter_s02_tier2", "blacksun_fighter_s03_tier2", "blacksun_bomber_s01_tier2"},
	}
}

registerScreenPlay("escort_naboo_privateer_14", true)

-- Mission 3: Inspect

inspect_naboo_privateer_15 = SpaceInspectScreenplay:new {
	className = "inspect_naboo_privateer_15",

	questName = "naboo_privateer_15",
	questType = "inspect",

	questZone = "space_naboo",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/shield_generator/shd_mission_reward_neutral_koensayr_ds23.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	inspectTargets = {"blacksun_gunship_tier2"},
	inspectCargo = "shipment_orders",

	targetLocation = {x = 2500, z = 400, y = -3000},
}

registerScreenPlay("inspect_naboo_privateer_15", true)

-- Mission 4: Assassinate

assassinate_naboo_privateer_tier2_4a = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_privateer_tier2_4a",

	questType = "assassinate",
	questName = "naboo_privateer_tier2_4a",

	questZone = "space_naboo",

	creditReward = 5000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/droid_interface/ddi_mission_reward_neutral_sorosuub_w19.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	arrivalDelay = 7,
	failTimer = 20,

	assassinateSpawns = {
		target = "blacksun_ace_s04_tier3",
		escorts = {"blacksun_fighter_s02_tier2", "blacksun_fighter_s02_tier2", "blacksun_bomber_s01_tier2", "blacksun_bomber_s01_tier2", "blacksun_fighter_s03_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "rsf_tier2_assassinate_1", x = 1500, z = 600, y = -1500},
		{patrolPointName = "rsf_tier2_assassinate_2", x = 2000, z = 400, y = -2000},
	},
}

registerScreenPlay("assassinate_naboo_privateer_tier2_4a", true)

-- Tier 2 Duty Missions

destroy_duty_naboo_privateer_9 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_naboo_privateer_9",

	questName = "naboo_privateer_9",
	questType = "destroy_duty",

	questZone = "space_naboo",

	creditReward = 100,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	dutyMissionLevel = 2,

	shipLocations = {
		{patrolPointName = "rsf_duty_patrol_1", x = 752, z = 659, y = -2444},
		{patrolPointName = "rsf_duty_patrol_2", x = 2031, z = 887, y = -1759},
		{patrolPointName = "rsf_duty_patrol_3", x = 2466, z = 854, y = -505},
	},

	shipTypes = {
		"blacksun_fighter_s01_tier2", "blacksun_fighter_s02_tier2", "blacksun_fighter_s03_tier2",
		"blacksun_bomber_s01_tier2", "blacksun_bomber_s02_tier2",
	},
}

registerScreenPlay("destroy_duty_naboo_privateer_9", true)

escort_duty_naboo_privateer_10 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_naboo_privateer_10",

	questName = "naboo_privateer_10",
	questType = "escort_duty",

	questZone = "space_naboo",

	creditReward = 150,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	dutyMissionLevel = 2,

	escortShips = {"freighterheavy_tier2", "freighterlight_tier2"},

	escortPoints = {
		{patrolPointName = "rsf_tier2_duty_escort_1", zoneName = "space_naboo", x = 1000, z = 500, y = -3000, escortNumber = 1, radius = 250},
		{patrolPointName = "rsf_tier2_duty_escort_2", zoneName = "space_naboo", x = 2500, z = 300, y = -1500, escortNumber = 2, radius = 250},
		{patrolPointName = "rsf_tier2_duty_escort_3", zoneName = "space_naboo", x = 4000, z = 100, y = 500, escortNumber = 3, radius = 250},
	},

	attackShips = {
		{"blacksun_fighter_s01_tier2", "blacksun_fighter_s02_tier2"},
		{"blacksun_fighter_s01_tier2", "blacksun_fighter_s02_tier2", "blacksun_fighter_s03_tier2"},
	}
}

registerScreenPlay("escort_duty_naboo_privateer_10", true)

destroy_duty_naboo_privateer_11 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_naboo_privateer_11",

	questName = "naboo_privateer_11",
	questType = "destroy_duty",

	questZone = "space_naboo",

	creditReward = 125,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	dutyMissionLevel = 2,

	shipLocations = {
		{patrolPointName = "rsf_duty_patrol_4", x = 3500, z = 400, y = -1000},
		{patrolPointName = "rsf_duty_patrol_5", x = 4000, z = 200, y = 500},
		{patrolPointName = "rsf_duty_patrol_6", x = 4500, z = -100, y = 2000},
	},

	shipTypes = {
		"blacksun_fighter_s02_tier2", "blacksun_fighter_s03_tier2",
		"blacksun_bomber_s01_tier2", "blacksun_aggressor_tier2",
	},
}

registerScreenPlay("destroy_duty_naboo_privateer_11", true)

-- Note: Recovery duty not fully implemented in base code
recovery_duty_naboo_privateer_12 = SpaceDutyDestroyScreenplay:new {
	className = "recovery_duty_naboo_privateer_12",

	questName = "naboo_privateer_12",
	questType = "recovery_duty",

	questZone = "space_naboo",

	creditReward = 175,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	dutyMissionLevel = 2,

	shipLocations = {
		{patrolPointName = "rsf_recovery_1", x = 2000, z = 300, y = -2500},
		{patrolPointName = "rsf_recovery_2", x = 3000, z = 500, y = -1500},
	},

	shipTypes = {
		"blacksun_fighter_s01_tier2", "blacksun_fighter_s02_tier2",
	},
}

registerScreenPlay("recovery_duty_naboo_privateer_12", true)

--[[
	Tier 3 -- Commander Dulios Main Missions

	Feature rsf-tier3-data: rewards sit on the mission heads (1a/2a/3a/4a, naboo_privateer_tier3.java:224-251);
	split wiring, the 3c -> 3e ambush and the 4a/4f assassination payloads follow the SWG-Source spacequest .tab files.
]]

-- Mission 1: Recovery -> Patrol -> Destroy_Surpriseattack -> Assassinate

recovery_naboo_privateer_tier3_1a = SpaceRecoveryScreenplay:new {
	className = "recovery_naboo_privateer_tier3_1a",

	questName = "naboo_privateer_tier3_1a",
	questType = "recovery",

	questZone = "space_dantooine",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/reactor/rct_mission_reward_neutral_subpro_military.iff"},
	},

	sideQuest = true,
	sideQuestType = "patrol",
	sideQuestName = "naboo_privateer_tier3_1b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	-- Screenplay Specific Variables
	arrivalDelay = 13,
	recoveryDelay = 15,

	-- Target: Saymonz Varg's ship Dru'Mdar (Black Sun Assassin)
	recoverShip = "dru_mdar_tier3",
	recoveryConversationMobile = "object/mobile/shared_dressed_noble_human_male.iff",

	-- Black Sun escorts protecting the Dru'Mdar
	escortShips = {"blacksun_fighter_s02_tier3_dantooine", "blacksun_fighter_s02_tier3_dantooine"},

	-- Pre-recovery patrol points in Dantooine space (friendly controlled area per STF)
	preRecoveryPoints = {
		{patrolPointName = "dantooine_privateer_tier3_recovery_point_1", zoneName = "space_dantooine", x = -1500, z = 800, y = 2000, escortNumber = 1, radius = 250},
		{patrolPointName = "dantooine_privateer_tier3_recovery_point_2", zoneName = "space_dantooine", x = -1200, z = 600, y = 2500, escortNumber = 2, radius = 250},
		{patrolPointName = "dantooine_privateer_tier3_recovery_point_3", zoneName = "space_dantooine", x = -800, z = 400, y = 3000, escortNumber = 3, radius = 250},
		{patrolPointName = "dantooine_privateer_tier3_recovery_point_4", zoneName = "space_dantooine", x = -400, z = 200, y = 3500, escortNumber = 4, radius = 250},
	},

	-- Escort points after capture - route to hyperspace jump point
	recoveryPoints = {
		{patrolPointName = "dantooine_privateer_tier3_recovery_point_5", zoneName = "space_dantooine", x = 0, z = 0, y = 3800, escortNumber = 1, radius = 250},
		{patrolPointName = "dantooine_privateer_tier3_recovery_point_6", zoneName = "space_dantooine", x = 500, z = -200, y = 4200, escortNumber = 2, radius = 250},
		{patrolPointName = "dantooine_privateer_tier3_recovery_point_7", zoneName = "space_dantooine", x = 1000, z = -400, y = 4600, escortNumber = 3, radius = 250},
		{patrolPointName = "dantooine_privateer_tier3_recovery_point_8", zoneName = "space_dantooine", x = 1500, z = -600, y = 5000, escortNumber = 4, radius = 250},
	},

	attackDelay = 110,

	-- Black Sun reinforcements attacking during escort
	attackShips = {
		{"blacksun_fighter_s01_tier3", "blacksun_fighter_s02_tier3", "blacksun_bomber_s01_tier3"},
	},
}

registerScreenPlay("recovery_naboo_privateer_tier3_1a", true)

patrol_naboo_privateer_tier3_1b = SpacePatrolScreenplay:new {
	className = "patrol_naboo_privateer_tier3_1b",

	questName = "naboo_privateer_tier3_1b",
	questType = "patrol",

	questZone = "space_dantooine",

	creditReward = 0,

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_privateer_tier3_1c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 1,
	sideQuestDelay = 44,

	parentQuest = "recovery_naboo_privateer_tier3_1a",
	parentQuestType = "recovery",
	parentQuestName = "naboo_privateer_tier3_1a",

	-- Patrol route in Dantooine space (awaiting orders after Varg escaped)
	patrolPoints = {
		{patrolPointName = "dantooine_privateer_tier3_patrol_1", x = 2000, z = -500, y = 5500, patrolNumber = 1, radius = 150},
		{patrolPointName = "dantooine_privateer_tier3_patrol_2", x = 2500, z = -700, y = 6000, patrolNumber = 2, radius = 150},
		{patrolPointName = "dantooine_privateer_tier3_patrol_3", x = 3000, z = -900, y = 6500, patrolNumber = 3, radius = 150},
		{patrolPointName = "dantooine_privateer_tier3_patrol_4", x = 3500, z = -1100, y = 7000, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_privateer_tier3_1b", true)

destroy_surpriseattack_naboo_privateer_tier3_1c = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_privateer_tier3_1c",

	questName = "naboo_privateer_tier3_1c",
	questType = "destroy_surpriseattack",

	questZone = "space_dantooine",

	parentQuest = "patrol_naboo_privateer_tier3_1b",
	parentQuestType = "patrol",
	parentQuestName = "naboo_privateer_tier3_1b",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "naboo_privateer_tier3_1d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	-- Black Sun ambush during patrol in Dantooine
	surpriseAttackShips = {
		zone = "space_dantooine",
		spawns = {{count = 4, shipName = "blacksun_fighter_s02_tier3_dantooine"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_privateer_tier3_1c", true)

assassinate_naboo_privateer_tier3_1d = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_privateer_tier3_1d",

	questType = "assassinate",
	questName = "naboo_privateer_tier3_1d",

	-- Saymonz Varg has fled to Naboo space after evading capture in Dantooine
	questZone = "space_naboo",

	creditReward = 0,
	itemReward = {},

	parentQuest = "destroy_surpriseattack_naboo_privateer_tier3_1c",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "naboo_privateer_tier3_1c",

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	arrivalDelay = 7,
	failTimer = 20,

	-- Target: Saymonz Varg (Black Sun Assassin) - destroy since capture failed
	assassinateSpawns = {
		target = "blacksun_ace_s04_tier3",
		escorts = {"blacksun_fighter_s01_tier3", "blacksun_fighter_s02_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_privateer_tier3_assassinate_1", x = 3500, z = -3000, y = -2000},
		{patrolPointName = "naboo_privateer_tier3_assassinate_2", x = 4000, z = -2500, y = -1500},
	},
}

registerScreenPlay("assassinate_naboo_privateer_tier3_1d", true)

-- Mission 2: Escort -> Destroy_Surpriseattack -> Space_Battle -> Rescue

escort_naboo_privateer_tier3_2a = SpaceEscortScreenplay:new {
	className = "escort_naboo_privateer_tier3_2a",

	questName = "naboo_privateer_tier3_2a",
	questType = "escort",

	questZone = "space_naboo",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/engine/eng_mission_reward_neutral_mandal_inferno.iff"},
	},

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_privateer_tier3_2c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	-- Escort the Cadamo Sun (decoy ship) to draw Ay'Nat pirate attack
	escortShips = {"freighterlight_tier3"},

	escortPoints = {
		{patrolPointName = "naboo_privateer_tier3_escort_1", zoneName = "space_naboo", x = 2799, z = -362, y = -19, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_privateer_tier3_escort_2", zoneName = "space_naboo", x = 3281, z = 295, y = -818, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_privateer_tier3_escort_3", zoneName = "space_naboo", x = 3775, z = 743, y = -925, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_privateer_tier3_escort_4", zoneName = "space_naboo", x = 3895, z = 1220, y = -1913, escortNumber = 4, radius = 250},
	},

	attackDelay = 110,

	-- Ay'Nat pirates attacking the decoy
	attackShips = {
		{"aynat_outlaw_tier3", "aynat_outlaw_tier3"},
		{"aynat_outlaw_tier3", "aynat_enforcer_tier3", "aynat_intimidator_tier3"},
	}
}

registerScreenPlay("escort_naboo_privateer_tier3_2a", true)

rescue_naboo_privateer_tier3_2e = SpaceRescueScreenplay:new {
	className = "rescue_naboo_privateer_tier3_2e",

	questName = "naboo_privateer_tier3_2e",
	questType = "rescue",

	questZone = "space_corellia",  -- STF: Corellia System

	creditReward = 0,
	itemReward = {},

	parentQuest = "space_battle_naboo_privateer_tier3_2d",
	parentQuestType = "space_battle",
	parentQuestName = "naboo_privateer_tier3_2d",

	sideQuest = false,
	sideQuestType = "",
	sideQuestName = "",

	-- Screenplay Specific Variables (SWG rescue/naboo_privateer_tier3_2e.tab)
	recoveryPath = {
		{patrolPointName = "naboo_privateer_tier3_leg_2_rescue_egress_1", x = 3286, z = -1563, y = -5979},
		{patrolPointName = "naboo_privateer_tier3_leg_2_rescue_egress_2", x = 5139, z = -2619, y = -6917},
		{patrolPointName = "naboo_privateer_tier3_leg_2_rescue_egress_3", x = 1924, z = -4732, y = -4708},
		{patrolPointName = "naboo_privateer_tier3_leg_2_rescue_egress_4", x = 1156, z = -7106, y = -2482},
	},

	targetShipType = "madersim_tier3",
	targetArrivalDelay = 0,

	attackShipLists = {
		{"aynat_vaporizer_tier3", "aynat_vaporizer_tier3", "aynat_vaporizer_tier3"},
		{"aynat_outlaw_tier3", "aynat_outlaw_tier3", "aynat_outlaw_tier3"},
		{"aynat_vaporizer_tier3", "aynat_vaporizer_tier3", "aynat_vaporizer_tier3"},
		{"aynat_vaporizer_tier3", "aynat_vaporizer_tier3", "aynat_viggo_tier2"},
	},

	attackPeriod = 110,
	attackListType = 0,
	numResponses = 3,
}

registerScreenPlay("rescue_naboo_privateer_tier3_2e", true)

space_battle_naboo_privateer_tier3_2d = SpaceBattleScreenplay:new {
	className = "space_battle_naboo_privateer_tier3_2d",

	questType = "space_battle",
	questName = "naboo_privateer_tier3_2d",

	questZone = "space_corellia",  -- STF: Corellia System

	creditReward = 0,
	itemReward = {},

	parentQuest = "destroy_surpriseattack_naboo_privateer_tier3_2c",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "naboo_privateer_tier3_2c",

	sideQuest = true,
	sideQuestType = "rescue",
	sideQuestName = "naboo_privateer_tier3_2e",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	-- Screenplay Specific Variables (copied from spacequest/space_battle/naboo_privateer_tier3_2d.tab)

	battlePoint = {patrolPointName = "naboo_privateer_tier3_leg_2_space_battle", x = 6772, z = -2400, y = -6760, forward = {x = 0.041479, z = 0.877722, y = 0.477371}},

	damageMultiplier = 4,
	allyArrivalDelay = 68,
	enemyArrivalDelay = 104,
	allyOriginDist = -500,
	enemyOriginDist = 500,
	allyArrivalDist = -250,
	enemyArrivalDist = 250,

	allyForce = {
		"rsf_hunter_tier3", "rsf_stinger_tier3", "rsf_stinger_tier3",
	},

	enemyForce = {
		"aynat_intimidator_tier3", "aynat_outlaw_tier3", "aynat_outlaw_tier3", "aynat_vaporizer_tier3",
		"aynat_vaporizer_tier3", "aynat_vaporizer_tier3", "aynat_viggo_tier3", "aynat_outlaw_tier3",
	},
}

registerScreenPlay("space_battle_naboo_privateer_tier3_2d", true)

destroy_surpriseattack_naboo_privateer_tier3_2c = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_privateer_tier3_2c",

	questName = "naboo_privateer_tier3_2c",
	questType = "destroy_surpriseattack",

	questZone = "space_naboo",

	parentQuest = "escort_naboo_privateer_tier3_2a",
	parentQuestType = "escort",
	parentQuestName = "naboo_privateer_tier3_2a",

	sideQuest = true,
	sideQuestType = "space_battle",
	sideQuestName = "naboo_privateer_tier3_2d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	-- Ay'Nat pirate reinforcements
	surpriseAttackShips = {
		zone = "space_naboo",
		spawns = {{count = 5, shipName = "aynat_outlaw_tier3"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_privateer_tier3_2c", true)

-- Mission 3: Inspect -> Delivery_No_Pickup -> Survival -> Destroy_Surpriseattack

inspect_naboo_privateer_tier3_3a = SpaceInspectScreenplay:new {
	className = "inspect_naboo_privateer_tier3_3a",

	questName = "naboo_privateer_tier3_3a",
	questType = "inspect",

	questZone = "space_naboo",  -- STF: Naboo System

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon_capacitor/cap_mission_reward_neutral_sorosuub_v1.iff"},
	},

	parentQuest = "",
	parentQuestType = "",
	parentQuestName = "",

	sideQuest = true,
	sideQuestType = "delivery_no_pickup",
	sideQuestName = "naboo_privateer_tier3_3b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 10,

	-- Screenplay Specific Variables
	shipList = {"naboo_diplomatic_corps_bad_tier3"},
	validSpawns = {
		{spawnName = "naboo_privateer_tier3_leg_3_inspect", x = 3151, z = 3183, y = 4026},
	},
	giveSpawnWaypoint = 1,
	cargo = "encrypted_documents",
}

registerScreenPlay("inspect_naboo_privateer_tier3_3a", true)

-- RSF Tier 3 Mission 3b: Delivery without pickup (Lok)
-- Ported from SWG-Source: datatables/spacequest/delivery_no_pickup/naboo_privateer_tier3_3b.tab
-- Trainer: Dulios (tier 3)  SWG-Source series: naboo_privateer
delivery_no_pickup_naboo_privateer_tier3_3b = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_naboo_privateer_tier3_3b",

	questName = "naboo_privateer_tier3_3b",
	questType = "delivery_no_pickup",

	questZone = "space_lok",

	creditReward = 0,
	itemReward = {},

	parentQuest = "inspect_naboo_privateer_tier3_3a",
	parentQuestType = "inspect",
	parentQuestName = "naboo_privateer_tier3_3a",

	sideQuest = true,
	sideQuestType = "survival",
	sideQuestName = "naboo_privateer_tier3_3c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	-- Screenplay Specific Variables (delivery_no_pickup/naboo_privateer_tier3_3b.tab)
	deliveryShip = "rsf_rawl_tier3",
	deliveryPoint = {patrolPointName = "hostage_recovery_3", x = -6832, z = 2296, y = -3612},

	attackShipLists = {
		{"blacksun_aggressor_tier3", "blacksun_aggressor_tier3"},
		{"blacksun_fighter_s01_tier3", "blacksun_fighter_s01_tier3"},
	},

	attackPeriod = 50,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
}

registerScreenPlay("delivery_no_pickup_naboo_privateer_tier3_3b", true)

-- RSF Tier 3 Mission 3c: Survival (Lok)
-- Ported from SWG-Source: datatables/spacequest/survival/naboo_privateer_tier3_3c.tab
-- Trainer: Dulios (tier 3)  SWG-Source series: naboo_privateer  Slice: space-quest-stub-survival
survival_naboo_privateer_tier3_3c = SpaceSurvivalScreenplay:new {
	className = "survival_naboo_privateer_tier3_3c",

	questName = "naboo_privateer_tier3_3c",
	questType = "survival",

	questZone = "space_lok",  -- STF: Lok System

	creditReward = 0,
	itemReward = {},

	parentQuest = "delivery_no_pickup_naboo_privateer_tier3_3b",
	parentQuestType = "delivery_no_pickup",
	parentQuestName = "naboo_privateer_tier3_3b",

	-- Ambush on the way back (survival/naboo_privateer_tier3_3c.tab triggerArg); the mission 3 win quest stays 3c
	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_privateer_tier3_3e",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	-- Screenplay Specific Variables (survival/naboo_privateer_tier3_3c.tab)
	transmissionPoint = {patrolPointName = "naboo_privateer_tier3_leg_3_survival", x = -991, z = 1118, y = -1713},
	totalTransmissionTime = 450,
	timesToUpdateProgress = 9,
	transmissionStartDelay = 10,
	delayToFirstAttack = 25,

	attackShipLists = {
		{"blacksun_vehement_tier3", "blacksun_vehement_tier3", "blacksun_vehement_tier3"},
		{"blacksun_fighter_s01_tier3", "blacksun_fighter_s01_tier3", "blacksun_fighter_s03_tier3", "blacksun_fighter_s03_tier3"},
		{"blacksun_marauder_tier3", "blacksun_marauder_tier3", "blacksun_marauder_tier3"},
		{"blacksun_bomber_s03_tier3", "blacksun_bomber_s03_tier3", "blacksun_fighter_s02_tier3", "blacksun_fighter_s02_tier3"},
		{"blacksun_ace_s04_tier3", "blacksun_bomber_s03_tier3", "blacksun_bomber_s01_tier3"},
	},

	attackPeriod = 70,
	attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.RANDOM,
}

registerScreenPlay("survival_naboo_privateer_tier3_3c", true)

destroy_surpriseattack_naboo_privateer_tier3_3e = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_privateer_tier3_3e",

	questName = "naboo_privateer_tier3_3e",
	questType = "destroy_surpriseattack",

	questZone = "space_naboo",  -- STF: Naboo System

	parentQuest = "survival_naboo_privateer_tier3_3c",
	parentQuestType = "survival",
	parentQuestName = "naboo_privateer_tier3_3c",

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables (destroy_surpriseattack/naboo_privateer_tier3_3e.tab)
	surpriseAttackShips = {
		zone = "space_naboo",
		spawns = {{count = 5, shipName = "blacksun_marauder_tier3"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_privateer_tier3_3e", true)

-- Mission 4: Assassinate (Dantooine) -> Space_Battle (Lok) -> Destroy_Surpriseattack x3 (Lok) -> Assassinate (Lok)

-- Dantooine assassinate - destroy Beldini and escorts
assassinate_naboo_privateer_tier3_4a = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_privateer_tier3_4a",

	questType = "assassinate",
	questName = "naboo_privateer_tier3_4a",

	questZone = "space_dantooine",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/armor/arm_mission_reward_neutral_kse_handcrafted.iff"},
	},

	parentQuest = "",
	parentQuestType = "",
	parentQuestName = "",

	sideQuest = true,
	sideQuestType = "space_battle",
	sideQuestName = "naboo_privateer_tier3_4b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	-- Screenplay Specific Variables (assassinate/naboo_privateer_tier3_4a.tab)
	arrivalDelay = 45,
	failTimer = 20,

	assassinateSpawns = {
		target = "blacksun_beldini_tier3",
		escorts = {"blacksun_vehement_tier3", "blacksun_vehement_tier3", "blacksun_bomber_s03_tier3", "blacksun_bomber_s03_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "naboo_privateer_tier3_leg_4_assassinate_1", x = 1595, z = 2985, y = 2864},
		{patrolPointName = "naboo_privateer_tier3_leg_4_assassinate_2", x = 1500, z = 4139, y = 1708},
		{patrolPointName = "naboo_privateer_tier3_leg_4_assassinate_3", x = 1420, z = 3841, y = -954},
		{patrolPointName = "naboo_privateer_tier3_leg_4_assassinate_4", x = 558, z = 2111, y = -569},
	},
}

registerScreenPlay("assassinate_naboo_privateer_tier3_4a", true)

-- Lok space battle - Crystal Snake at Voria's Ember
space_battle_naboo_privateer_tier3_4b = SpaceBattleScreenplay:new {
	className = "space_battle_naboo_privateer_tier3_4b",

	questType = "space_battle",
	questName = "naboo_privateer_tier3_4b",

	questZone = "space_lok",

	creditReward = 0,
	itemReward = {},

	parentQuest = "assassinate_naboo_privateer_tier3_4a",
	parentQuestType = "assassinate",
	parentQuestName = "naboo_privateer_tier3_4a",

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_privateer_tier3_4c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	-- Screenplay Specific Variables (copied from spacequest/space_battle/naboo_privateer_tier3_4b.tab)

	battlePoint = {patrolPointName = "naboo_privateer_tier3_leg_4_space_battle", x = 4415, z = -572, y = 2266, forward = {x = 0.785999, z = -0.228293, y = 0.574532}},

	damageMultiplier = 4,
	allyArrivalDelay = 104,
	enemyArrivalDelay = 155,
	allyOriginDist = 550,
	enemyOriginDist = -550,
	allyArrivalDist = 250,
	enemyArrivalDist = -250,

	allyForce = {
		"rsf_hunter_tier3", "rsf_hunter_tier3", "rsf_hunter_tier3",
	},

	enemyForce = {
		"blacksun_crystal_snake_tier3", "blacksun_fighter_s01_tier3", "blacksun_fighter_s01_tier3", "blacksun_fighter_s02_tier3",
		"blacksun_marauder_tier3",
	},
}

registerScreenPlay("space_battle_naboo_privateer_tier3_4b", true)

-- RSF Tier 3 Mission 4c: Surprise attack (marauders), feature rsf-tier3-renames
-- Ported from SWG-Source: datatables/spacequest/destroy_surpriseattack/naboo_privateer_tier3_4c.tab

destroy_surpriseattack_naboo_privateer_tier3_4c = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_privateer_tier3_4c",

	questName = "naboo_privateer_tier3_4c",
	questType = "destroy_surpriseattack",

	questZone = "space_lok",

	creditReward = 0,
	itemReward = {},

	parentQuest = "space_battle_naboo_privateer_tier3_4b",
	parentQuestType = "space_battle",
	parentQuestName = "naboo_privateer_tier3_4b",

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_privateer_tier3_4d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	-- Screenplay Specific Variables (destroy_surpriseattack/naboo_privateer_tier3_4c.tab)
	surpriseAttackShips = {
		zone = "space_lok",
		spawns = {{count = 3, shipName = "blacksun_marauder_tier3"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_privateer_tier3_4c", true)

-- RSF Tier 3 Mission 4d: Surprise attack (vehement fighters), feature rsf-tier3-renames
-- Ported from SWG-Source: datatables/spacequest/destroy_surpriseattack/naboo_privateer_tier3_4d.tab

destroy_surpriseattack_naboo_privateer_tier3_4d = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_privateer_tier3_4d",

	questName = "naboo_privateer_tier3_4d",
	questType = "destroy_surpriseattack",

	questZone = "space_lok",

	creditReward = 0,
	itemReward = {},

	parentQuest = "destroy_surpriseattack_naboo_privateer_tier3_4c",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "naboo_privateer_tier3_4c",

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_privateer_tier3_4e",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	-- Screenplay Specific Variables (destroy_surpriseattack/naboo_privateer_tier3_4d.tab)
	surpriseAttackShips = {
		zone = "space_lok",
		spawns = {{count = 4, shipName = "blacksun_vehement_tier3"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_privateer_tier3_4d", true)

-- RSF Tier 3 Mission 4e: Surprise attack (gunship), feature rsf-tier3-renames
-- Ported from SWG-Source: datatables/spacequest/destroy_surpriseattack/naboo_privateer_tier3_4e.tab

destroy_surpriseattack_naboo_privateer_tier3_4e = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_privateer_tier3_4e",

	questName = "naboo_privateer_tier3_4e",
	questType = "destroy_surpriseattack",

	questZone = "space_lok",

	creditReward = 0,
	itemReward = {},

	parentQuest = "destroy_surpriseattack_naboo_privateer_tier3_4d",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "naboo_privateer_tier3_4d",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "naboo_privateer_tier3_4f",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	-- Screenplay Specific Variables (destroy_surpriseattack/naboo_privateer_tier3_4e.tab)
	surpriseAttackShips = {
		zone = "space_lok",
		spawns = {{count = 1, shipName = "blacksun_gunship_tier2"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_privateer_tier3_4e", true)

-- Lok final assassinate - destroy Black Sun operative (Krayt's Bane)
assassinate_naboo_privateer_tier3_4f = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_privateer_tier3_4f",

	questType = "assassinate",
	questName = "naboo_privateer_tier3_4f",

	questZone = "space_lok",

	creditReward = 0,
	itemReward = {},

	parentQuest = "destroy_surpriseattack_naboo_privateer_tier3_4e",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "naboo_privateer_tier3_4e",

	sideQuest = false,
	sideQuestType = "",
	sideQuestName = "",

	-- Screenplay Specific Variables (assassinate/naboo_privateer_tier3_4f.tab)
	arrivalDelay = 25,
	failTimer = 20,

	assassinateSpawns = {
		target = "blacksun_krayt_bane_tier3",
		escorts = {"blacksun_ace_s04_tier3", "blacksun_ace_s04_tier3"},
	},

	targetPatrols = {
		{patrolPointName = "hostage_escort_5", x = -3467, z = 2588, y = -6633},
		{patrolPointName = "hostage_recovery_1", x = -2930, z = 2690, y = -4742},
		{patrolPointName = "hostage_recovery_5", x = -5082, z = 2428, y = -476},
	},
}

registerScreenPlay("assassinate_naboo_privateer_tier3_4f", true)

--[[
	Tier 4 -- Admiral Diness Imler
	SWG-Source: naboo_privateer_tier4.java and datatables/spacequest/*/naboo_privateer_tier4_*.tab
	Feature: rsf-tier4
]]

-- RSF Tier 4 Mission 1a: Escort (Endor) (spacequest/escort/naboo_privateer_tier4_1a.tab)
escort_naboo_privateer_tier4_1a = SpaceEscortScreenplay:new {
	className = "escort_naboo_privateer_tier4_1a",

	questName = "naboo_privateer_tier4_1a",
	questType = "escort",

	questZone = "space_endor",

	creditReward = 10000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/booster/bst_mission_reward_neutral_mandal_q_series.iff"},
	},

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "naboo_privateer_tier4_1b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 15,

	parentQuest = "",
	parentQuestType = "",
	parentQuestName = "",

	-- Screenplay Specific Variables
	escortShips = {"rsf_scanner_tier4"},

	escortPoints = {
		{patrolPointName = "naboo_privateer_tier4_leg_1_escort_one_1", zoneName = "space_endor", x = 4394, z = -1173, y = -2050, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_leg_1_escort_one_2", zoneName = "space_endor", x = 5476, z = -2006, y = -1551, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_leg_1_escort_one_3", zoneName = "space_endor", x = 7420, z = -3437, y = -800, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_leg_1_escort_one_4", zoneName = "space_endor", x = 6917, z = -5196, y = 1246, escortNumber = 4, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_leg_1_escort_one_5", zoneName = "space_endor", x = 5612, z = -7066, y = 3607, escortNumber = 5, radius = 250},
	},

	attackDelay = 120, -- In Seconds

	attackShips = {
		{"blacksun_aggressor_tier4", "blacksun_aggressor_tier4", "blacksun_aggressor_tier4"},
		{"blacksun_bomber_s01_tier4", "blacksun_bomber_s01_tier4", "blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4"},
		{"blacksun_vehement_tier4", "blacksun_vehement_tier4", "blacksun_vehement_tier4"},
	},

	tauntData = {goodbyeCount = 1, reasonCount = 1, tauntCount = 1, thanksCount = 1},
}

registerScreenPlay("escort_naboo_privateer_tier4_1a", true)

-- RSF Tier 4 Mission 1b: Escort (Endor) (spacequest/escort/naboo_privateer_tier4_1b.tab)
escort_naboo_privateer_tier4_1b = SpaceEscortScreenplay:new {
	className = "escort_naboo_privateer_tier4_1b",

	questName = "naboo_privateer_tier4_1b",
	questType = "escort",

	questZone = "space_endor",

	creditReward = 0,

	sideQuest = false,
	sideQuestType = "",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.NONE,

	parentQuest = "escort_naboo_privateer_tier4_1a",
	parentQuestType = "escort",
	parentQuestName = "naboo_privateer_tier4_1a",

	-- Screenplay Specific Variables
	escortShips = {"imp_lambda_shuttle_tier4"},

	escortPoints = {
		{patrolPointName = "naboo_privateer_tier4_leg_1_escort_two_1", zoneName = "space_endor", x = 5815, z = -6701, y = 2035, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_leg_1_escort_two_2", zoneName = "space_endor", x = 4663, z = -5802, y = -1128, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_leg_1_escort_two_3", zoneName = "space_endor", x = 3522, z = -4905, y = -4248, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_leg_1_escort_two_4", zoneName = "space_endor", x = 2920, z = -4431, y = -5893, escortNumber = 4, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_leg_1_escort_two_5", zoneName = "space_endor", x = 2190, z = -3832, y = -7527, escortNumber = 5, radius = 250},
	},

	attackDelay = 120, -- In Seconds

	attackShips = {
		{"reb_xwing_tier4", "reb_xwing_tier4", "reb_xwing_tier4"},
		{"reb_ywing_tier4", "reb_ywing_tier4", "reb_ywing_tier4"},
		{"reb_awing_tier4", "reb_awing_tier4", "reb_awing_tier4", "reb_awing_tier4"},
		{"reb_bwing_tier4", "reb_bwing_tier4", "reb_bwing_tier4", "reb_xwing_tier4", "reb_xwing_tier4"},
	},

	tauntData = {goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2},
}

registerScreenPlay("escort_naboo_privateer_tier4_1b", true)

-- RSF Tier 4 Mission 2a: Inspect (Endor) (spacequest/inspect/naboo_privateer_tier4_2a.tab)
inspect_naboo_privateer_tier4_2a = SpaceInspectScreenplay:new {
	className = "inspect_naboo_privateer_tier4_2a",

	questName = "naboo_privateer_tier4_2a",
	questType = "inspect",

	questZone = "space_endor",

	creditReward = 10000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/weapon/wpn_mission_reward_neutral_borstel_disruptor.iff"},
	},

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_privateer_tier4_2b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 16,

	parentQuest = "",
	parentQuestType = "",
	parentQuestName = "",

	-- Screenplay Specific Variables
	shipList = {"freighterheavy_tier4_inspect"},
	validSpawns = {
		{spawnName = "freighter_mission_dudes_1_inspect", x = 3571, z = -480, y = -2419},
	},
	giveSpawnWaypoint = 1,
	cargo = "industrial_cargo",
}

registerScreenPlay("inspect_naboo_privateer_tier4_2a", true)

-- RSF Tier 4 Mission 2b: Surprise Attack (Endor) (spacequest/destroy_surpriseattack/naboo_privateer_tier4_2b.tab)
destroy_surpriseattack_naboo_privateer_tier4_2b = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_privateer_tier4_2b",

	questName = "naboo_privateer_tier4_2b",
	questType = "destroy_surpriseattack",

	questZone = "space_endor",

	creditReward = 0,

	sideQuest = true,
	sideQuestType = "patrol",
	sideQuestName = "naboo_privateer_tier4_2c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	parentQuest = "inspect_naboo_privateer_tier4_2a",
	parentQuestType = "inspect",
	parentQuestName = "naboo_privateer_tier4_2a",

	-- Screenplay Specific Variables (SWG spawn loop: only the first ship type spawns)
	surpriseAttackShips = {
		zone = "space_endor",
		spawns = {{count = 5, shipName = "blacksun_vehement_tier4"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_privateer_tier4_2b", true)

-- RSF Tier 4 Mission 2c: Patrol (Endor) (spacequest/patrol/naboo_privateer_tier4_2c.tab)
patrol_naboo_privateer_tier4_2c = SpacePatrolScreenplay:new {
	className = "patrol_naboo_privateer_tier4_2c",

	questName = "naboo_privateer_tier4_2c",
	questType = "patrol",

	questZone = "space_endor",

	creditReward = 0,

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_privateer_tier4_2d",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,
	sideQuestPatrolStart = 3,
	sideQuestDelay = 13,

	parentQuest = "destroy_surpriseattack_naboo_privateer_tier4_2b",
	parentQuestType = "destroy_surpriseattack",
	parentQuestName = "naboo_privateer_tier4_2b",

	patrolPoints = {
		{patrolPointName = "naboo_privateer_tier4_leg_2_patrol_1", x = 3482, z = -3131, y = -7486, patrolNumber = 1, radius = 150},
		{patrolPointName = "naboo_privateer_tier4_leg_2_patrol_2", x = 5371, z = -1785, y = -7223, patrolNumber = 2, radius = 150},
		{patrolPointName = "naboo_privateer_tier4_leg_2_patrol_3", x = 7304, z = -654, y = -7255, patrolNumber = 3, radius = 150},
		{patrolPointName = "naboo_privateer_tier4_leg_2_patrol_4", x = 6834, z = 3140, y = -7143, patrolNumber = 4, radius = 150},
		{patrolPointName = "naboo_privateer_tier4_leg_2_patrol_5", x = 6349, z = 6605, y = -7132, patrolNumber = 5, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_privateer_tier4_2c", true)

-- RSF Tier 4 unreachable surprise attack 2c (nothing triggers it; copy of 2b) (spacequest/destroy_surpriseattack/naboo_privateer_tier4_2c.tab)
destroy_surpriseattack_naboo_privateer_tier4_2c = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_privateer_tier4_2c",

	questName = "naboo_privateer_tier4_2c",
	questType = "destroy_surpriseattack",

	questZone = "space_endor",

	creditReward = 0,

	sideQuest = true,
	sideQuestType = "patrol",
	sideQuestName = "naboo_privateer_tier4_2c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	parentQuest = "",
	parentQuestType = "",
	parentQuestName = "",

	-- Screenplay Specific Variables (SWG spawn loop: only the first ship type spawns)
	surpriseAttackShips = {
		zone = "space_endor",
		spawns = {{count = 5, shipName = "blacksun_vehement_tier4"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_privateer_tier4_2c", true)

-- RSF Tier 4 Mission 2d: Surprise Attack (Endor) (spacequest/destroy_surpriseattack/naboo_privateer_tier4_2d.tab)
destroy_surpriseattack_naboo_privateer_tier4_2d = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_privateer_tier4_2d",

	questName = "naboo_privateer_tier4_2d",
	questType = "destroy_surpriseattack",

	questZone = "space_endor",

	creditReward = 0,

	sideQuest = false,
	sideQuestType = "",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.NONE,

	parentQuest = "patrol_naboo_privateer_tier4_2c",
	parentQuestType = "patrol",
	parentQuestName = "naboo_privateer_tier4_2c",

	-- Screenplay Specific Variables (SWG spawn loop: only the first ship type spawns)
	surpriseAttackShips = {
		zone = "space_endor",
		spawns = {{count = 7, shipName = "blacksun_fighter_s01_tier4"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_privateer_tier4_2d", true)

-- RSF Tier 4 Mission 3a: Delivery (Yavin 4) (spacequest/delivery/naboo_privateer_tier4_3a.tab)
delivery_naboo_privateer_tier4_3a = SpaceDeliveryScreenplay:new {
	className = "delivery_naboo_privateer_tier4_3a",

	questName = "naboo_privateer_tier4_3a",
	questType = "delivery",

	questZone = "space_yavin4",

	creditReward = 10000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/shield_generator/shd_mission_reward_neutral_armek_plasma_web.iff"},
	},

	sideQuest = true,
	sideQuestType = "patrol",
	sideQuestName = "naboo_privateer_tier4_3b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 14,

	parentQuest = "",
	parentQuestType = "",
	parentQuestName = "",

	-- Screenplay Specific Variables
	pickupPoint = {patrolPointName = "naboo_privateer_tier4_leg_3_delivery_one_pickup", x = -1306, z = -5141, y = -3812},
	deliveryPoint = {patrolPointName = "naboo_privateer_tier4_leg_3_delivery_one_deliver", x = -3500, z = 0, y = -3500},

	pickupShip = "imp_freighterheavy_tier4",
	deliveryShip = "imp_transport_tier4",

	attackShipLists = {
		{"reb_awing_tier4", "reb_awing_tier4", "reb_awing_tier4"},
		{"reb_bwing_tier4", "reb_bwing_tier4", "reb_awing_tier5"},
	},

	attackPeriod = 45,
	attackListType = 1, -- random
}

registerScreenPlay("delivery_naboo_privateer_tier4_3a", true)

-- RSF Tier 4 Mission 3b: Patrol (Yavin 4) (spacequest/patrol/naboo_privateer_tier4_3b.tab)
patrol_naboo_privateer_tier4_3b = SpacePatrolScreenplay:new {
	className = "patrol_naboo_privateer_tier4_3b",

	questName = "naboo_privateer_tier4_3b",
	questType = "patrol",

	questZone = "space_yavin4",

	creditReward = 0,

	sideQuest = true,
	sideQuestType = "survival",
	sideQuestName = "naboo_privateer_tier4_3c",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,
	sideQuestPatrolStart = 3,
	sideQuestDelay = 13,

	parentQuest = "delivery_naboo_privateer_tier4_3a",
	parentQuestType = "delivery",
	parentQuestName = "naboo_privateer_tier4_3a",

	patrolPoints = {
		{patrolPointName = "naboo_privateer_tier4_leg_3_patrol_1", x = 5163, z = 2236, y = -4059, patrolNumber = 1, radius = 150},
		{patrolPointName = "naboo_privateer_tier4_leg_3_patrol_2", x = 2287, z = 2964, y = -2659, patrolNumber = 2, radius = 150},
		{patrolPointName = "naboo_privateer_tier4_leg_3_patrol_3", x = 419, z = 3437, y = -1750, patrolNumber = 3, radius = 150},
		{patrolPointName = "naboo_privateer_tier4_leg_3_patrol_4", x = -1507, z = 3925, y = -812, patrolNumber = 4, radius = 150},
		{patrolPointName = "naboo_privateer_tier4_leg_3_patrol_5", x = -3815, z = 4509, y = 310, patrolNumber = 5, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_privateer_tier4_3b", true)

-- RSF Tier 4 Mission 3c: Survival (Yavin 4) (spacequest/survival/naboo_privateer_tier4_3c.tab)
survival_naboo_privateer_tier4_3c = SpaceSurvivalScreenplay:new {
	className = "survival_naboo_privateer_tier4_3c",

	questName = "naboo_privateer_tier4_3c",
	questType = "survival",

	questZone = "space_yavin4",

	creditReward = 0,

	sideQuest = false,
	sideQuestType = "",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.NONE,

	parentQuest = "patrol_naboo_privateer_tier4_3b",
	parentQuestType = "patrol",
	parentQuestName = "naboo_privateer_tier4_3b",

	-- Screenplay Specific Variables
	transmissionPoint = {patrolPointName = "naboo_privateer_tier4_leg_3_survival", x = -5249, z = 3585, y = -1619},
	totalTransmissionTime = 720,
	timesToUpdateProgress = 10,
	transmissionStartDelay = 15,
	delayToFirstAttack = 35,

	attackShipLists = {
		{"blacksun_marauder_tier4", "blacksun_marauder_tier4", "blacksun_marauder_tier4"},
		{"blacksun_vehement_tier4", "blacksun_vehement_tier4", "blacksun_vehement_tier4"},
		{"blacksun_marauder_tier4", "blacksun_marauder_tier4", "blacksun_marauder_tier4"},
		{"blacksun_fighter_s03_tier4", "blacksun_fighter_s03_tier4", "blacksun_fighter_s03_tier5"},
	},

	attackPeriod = 90,
	attackListType = 1, -- random
}

registerScreenPlay("survival_naboo_privateer_tier4_3c", true)

-- RSF Tier 4 Mission 4a: Space Battle (Yavin 4) (spacequest/space_battle/naboo_privateer_tier4_4a.tab)
space_battle_naboo_privateer_tier4_4a = SpaceBattleScreenplay:new {
	className = "space_battle_naboo_privateer_tier4_4a",

	questName = "naboo_privateer_tier4_4a",
	questType = "space_battle",

	questZone = "space_yavin4",

	creditReward = 10000,
	itemReward = {
		{species = {-1}, item = "object/tangible/ship/components/engine/eng_mission_reward_neutral_haor_chall_military.iff"},
	},

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "naboo_privateer_tier4_4b",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5,

	parentQuest = "",
	parentQuestType = "",
	parentQuestName = "",

	-- Screenplay Specific Variables (spacequest/space_battle/naboo_privateer_tier4_4a.tab, forward from the buildout)
	battlePoint = {patrolPointName = "naboo_privateer_tier4_leg_4_space_battle_one", x = 5926, z = 1988, y = -4590, forward = {x = 0.999064, z = 0.042300, y = -0.009016}},

	damageMultiplier = 4,
	allyArrivalDelay = 65,
	enemyArrivalDelay = 85,
	allyOriginDist = -400,
	enemyOriginDist = 400,
	allyArrivalDist = -250,
	enemyArrivalDist = 250,

	allyForce = {"rsf_hunter_tier4", "rsf_hunter_tier4", "rsf_rawl_tier4", "rsf_rawl_tier4", "rsf_stinger_tier4"},

	enemyForce = {"blacksun_aggressor_tier4", "blacksun_aggressor_tier4", "blacksun_marauder_tier4", "blacksun_marauder_tier4", "blacksun_marauder_tier4", "blacksun_vehement_tier4", "blacksun_vehement_tier4"},
}

registerScreenPlay("space_battle_naboo_privateer_tier4_4a", true)

-- RSF Tier 4 Mission 4b: Escort (Yavin 4) (spacequest/escort/naboo_privateer_tier4_4b.tab)
escort_naboo_privateer_tier4_4b = SpaceEscortScreenplay:new {
	className = "escort_naboo_privateer_tier4_4b",

	questName = "naboo_privateer_tier4_4b",
	questType = "escort",

	questZone = "space_yavin4",

	creditReward = 0,

	sideQuest = true,
	sideQuestType = "space_battle",
	sideQuestName = "naboo_privateer_tier4_4c_win",
	sideFailQuestType = "space_battle",
	sideFailQuestName = "naboo_privateer_tier4_4c_lose",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL,
	sideQuestDelay = 5,

	parentQuest = "space_battle_naboo_privateer_tier4_4a",
	parentQuestType = "space_battle",
	parentQuestName = "naboo_privateer_tier4_4a",

	-- Screenplay Specific Variables
	escortShips = {"rsf_scanner_tier4"},

	escortPoints = {
		{patrolPointName = "naboo_privateer_tier4_leg_4_escort_1", zoneName = "space_yavin4", x = -4970, z = 4802, y = 873, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_leg_4_escort_2", zoneName = "space_yavin4", x = -6367, z = 5156, y = 1553, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_leg_4_escort_3", zoneName = "space_yavin4", x = -7440, z = 5038, y = 1840, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_leg_4_escort_4", zoneName = "space_yavin4", x = -5975, z = 3099, y = -130, escortNumber = 4, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_leg_4_escort_5", zoneName = "space_yavin4", x = -4967, z = 651, y = -1573, escortNumber = 5, radius = 250},
	},

	attackDelay = 90, -- In Seconds

	attackShips = {
		{"blacksun_vehement_tier4", "blacksun_vehement_tier4", "blacksun_vehement_tier4", "blacksun_vehement_tier4", "blacksun_vehement_tier5"},
		{"blacksun_fighter_s03_tier4", "blacksun_fighter_s03_tier4", "blacksun_fighter_s03_tier4", "blacksun_fighter_s03_tier4", "blacksun_fighter_s03_tier5"},
		{"blacksun_ace_s04_tier4", "blacksun_bomber_ace_s04_tier4", "blacksun_bomber_ace_s04_tier4", "blacksun_fighter_s02_tier4", "blacksun_fighter_s02_tier4"},
		{"blacksun_aggressor_tier5", "blacksun_marauder_tier5", "blacksun_vehement_tier5"},
	},

	tauntData = {goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2},
}

registerScreenPlay("escort_naboo_privateer_tier4_4b", true)

-- RSF Tier 4 Mission 4c: Space Battle, escort won (Yavin 4) (spacequest/space_battle/naboo_privateer_tier4_4c_win.tab)
space_battle_naboo_privateer_tier4_4c_win = SpaceBattleScreenplay:new {
	className = "space_battle_naboo_privateer_tier4_4c_win",

	questName = "naboo_privateer_tier4_4c_win",
	questType = "space_battle",

	questZone = "space_yavin4",

	creditReward = 0,

	sideQuest = false,
	sideQuestType = "",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.NONE,

	parentQuest = "escort_naboo_privateer_tier4_4b",
	parentQuestType = "escort",
	parentQuestName = "naboo_privateer_tier4_4b",

	-- Screenplay Specific Variables (spacequest/space_battle/naboo_privateer_tier4_4c_win.tab, forward from the buildout)
	battlePoint = {patrolPointName = "naboo_privateer_tier4_leg_4_space_battle_two", x = -4578, z = 1604, y = -3839, forward = {x = 0.301881, z = -0.595319, y = -0.744622}},

	damageMultiplier = 3,
	allyArrivalDelay = 69,
	enemyArrivalDelay = 120,
	allyOriginDist = -400,
	enemyOriginDist = 400,
	allyArrivalDist = -250,
	enemyArrivalDist = 250,

	allyForce = {"rsf_ace_tier4", "rsf_ace_tier4", "rsf_ace_tier4", "rsf_hunter_tier4", "rsf_hunter_tier4", "rsf_rawl_tier4", "rsf_rawl_tier4", "rsf_stinger_tier4", "rsf_stinger_tier4", "rsf_stinger_tier4"},

	enemyForce = {"blacksun_aggressor_tier4", "blacksun_aggressor_tier4", "blacksun_bomber_s03_tier4", "blacksun_bomber_s03_tier4", "blacksun_gunship_tier4", "blacksun_gunship_tier4", "blacksun_marauder_tier4", "blacksun_marauder_tier4", "blacksun_marauder_tier4", "blacksun_vehement_tier4", "blacksun_vehement_tier4", "blacksun_vehement_tier4"},
}

registerScreenPlay("space_battle_naboo_privateer_tier4_4c_win", true)

-- RSF Tier 4 Mission 4c: Space Battle, escort lost (Yavin 4) (spacequest/space_battle/naboo_privateer_tier4_4c_lose.tab)
space_battle_naboo_privateer_tier4_4c_lose = SpaceBattleScreenplay:new {
	className = "space_battle_naboo_privateer_tier4_4c_lose",

	questName = "naboo_privateer_tier4_4c_lose",
	questType = "space_battle",

	questZone = "space_yavin4",

	creditReward = 0,

	sideQuest = false,
	sideQuestType = "",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.NONE,

	parentQuest = "escort_naboo_privateer_tier4_4b",
	parentQuestType = "escort",
	parentQuestName = "naboo_privateer_tier4_4b",

	-- Screenplay Specific Variables (spacequest/space_battle/naboo_privateer_tier4_4c_lose.tab, forward from the buildout)
	battlePoint = {patrolPointName = "naboo_privateer_tier4_leg_4_space_battle_two", x = -4578, z = 1604, y = -3839, forward = {x = 0.301881, z = -0.595319, y = -0.744622}},

	damageMultiplier = 3,
	allyArrivalDelay = 69,
	enemyArrivalDelay = 120,
	allyOriginDist = -400,
	enemyOriginDist = 400,
	allyArrivalDist = -250,
	enemyArrivalDist = 250,

	allyForce = {"rsf_ace_tier4", "rsf_ace_tier4", "rsf_hunter_tier4", "rsf_rawl_tier4", "rsf_rawl_tier4", "rsf_stinger_tier4"},

	enemyForce = {"blacksun_aggressor_tier4", "blacksun_aggressor_tier4", "blacksun_bomber_s03_tier4", "blacksun_bomber_s03_tier4", "blacksun_gunship_tier4", "blacksun_gunship_tier4", "blacksun_marauder_tier4", "blacksun_marauder_tier4", "blacksun_marauder_tier4", "blacksun_vehement_tier4", "blacksun_vehement_tier4", "blacksun_vehement_tier4"},
}

registerScreenPlay("space_battle_naboo_privateer_tier4_4c_lose", true)

-- RSF Tier 4 Duty: Destroy (Endor) (spacequest/destroy_duty/naboo_privateer_tier4_1.tab)
destroy_duty_naboo_privateer_tier4_1 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_naboo_privateer_tier4_1",

	questName = "naboo_privateer_tier4_1",
	questType = "destroy_duty",

	questZone = "space_endor",

	creditReward = 300,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	totalLevels = 4, -- Amount of levels a player has to complete to finish mission
	totalRounds = 2, -- Total Rounds for each of the levels
	totalWaves = 2, -- Total waves at each location that is not the boss ship

	bossShip = "blacksun_ace_s04_tier4",
	shipTypes = {
		{"blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4"},
		{"blacksun_bomber_s01_tier4", "blacksun_bomber_s01_tier4", "blacksun_bomber_s01_tier4", "blacksun_bomber_s01_tier4"},
	},
}

registerScreenPlay("destroy_duty_naboo_privateer_tier4_1", true)

-- RSF Tier 4 Duty: Escort (Endor) (spacequest/escort_duty/naboo_privateer_tier4_1.tab)
escort_duty_naboo_privateer_tier4_1 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_naboo_privateer_tier4_1",

	questName = "naboo_privateer_tier4_1",
	questType = "escort_duty",

	questZone = "space_endor",

	creditReward = 5000,
	creditKillBonus = 400,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	escortShips = {"freighterheavy_tier4"},

	escortPoints = {
		{patrolPointName = "naboo_privateer_tier4_escortduty_1", zoneName = "space_endor", x = 2767, z = -2375, y = 1667, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_escortduty_3", zoneName = "space_endor", x = 6198, z = -4677, y = 1901, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_escortduty_5", zoneName = "space_endor", x = 4748, z = -5538, y = -2685, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_escortduty_7", zoneName = "space_endor", x = -1237, z = -4971, y = -7380, escortNumber = 4, radius = 250},
	},

	attackDelay = 90, -- In Seconds

	attackShips = {
		{"borvo_bomber_tier4", "borvo_bomber_tier4", "borvo_bomber_tier4", "borvo_bomber_tier4"},
		{"borvo_defender_tier4", "borvo_defender_tier4", "borvo_defender_tier4", "borvo_defender_tier4"},
		{"borvo_fighter_tier4", "borvo_fighter_tier4", "borvo_fighter_tier4", "borvo_fighter_tier4"},
		{"borvo_boss_tier4", "borvo_defender_tier4", "borvo_defender_tier4"},
	},

	tauntData = {goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2},
}

registerScreenPlay("escort_duty_naboo_privateer_tier4_1", true)

-- RSF Tier 4 Duty: Recovery (Yavin 4) (spacequest/recovery_duty/naboo_privateer_tier4_1.tab)
recovery_duty_naboo_privateer_tier4_1 = SpaceDutyRecoveryScreenplay:new {
	className = "recovery_duty_naboo_privateer_tier4_1",

	questName = "naboo_privateer_tier4_1",
	questType = "recovery_duty",

	questZone = "space_yavin4",

	creditReward = 5000,
	killReward = 300,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	recoverShip = "aynat_viggo_tier4",
	arrivalDelay = 12,
	recoveryDelay = 16,
	recoveryConversationMobile = "",

	escortShips = {"aynat_vaporizer_tier4", "aynat_vaporizer_tier4"},

	preRecoveryPoints = {
		{patrolPointName = "naboo_privateer_tier4_recovery_duty_escort_1", x = -2104, z = 5669, y = -3583, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_recovery_duty_escort_2", x = -3790, z = 4893, y = -4029, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_recovery_duty_escort_3", x = -6721, z = 4609, y = -3299, escortNumber = 3, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_recovery_duty_escort_4", x = -7376, z = 4462, y = -2880, escortNumber = 4, radius = 250},
		{patrolPointName = "naboo_rebel_tier4_2_assassin_3", x = 1131, z = 4477, y = -2086, escortNumber = 5, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "naboo_privateer_tier4_recovery_duty_egress_1", x = -6350, z = 2219, y = -3448, escortNumber = 1, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_recovery_duty_egress_3", x = -3696, z = -1619, y = -3667, escortNumber = 2, radius = 250},
		{patrolPointName = "naboo_privateer_tier4_recovery_duty_egress_4", x = -2365, z = -3545, y = -3776, escortNumber = 3, radius = 250},
	},

	attackDelay = 90, -- In Seconds

	attackShips = {
		{"aynat_outlaw_tier4", "aynat_outlaw_tier4", "aynat_outlaw_tier4", "aynat_outlaw_tier4"},
		{"aynat_vaporizer_tier4", "aynat_vaporizer_tier4", "aynat_vaporizer_tier4", "aynat_vaporizer_tier4"},
		{"aynat_enforcer_tier4", "aynat_enforcer_tier4", "aynat_enforcer_tier4", "aynat_enforcer_tier4"},
	},

	tauntData = {panicCount = 2, thanksCount = 2},
}

registerScreenPlay("recovery_duty_naboo_privateer_tier4_1", true)

-- RSF Tier 4 Duty: Rescue (Yavin 4) (spacequest/rescue_duty/naboo_privateer_tier4_1.tab)
rescue_duty_naboo_privateer_tier4_1 = SpaceDutyRescueScreenplay:new {
	className = "rescue_duty_naboo_privateer_tier4_1",

	questName = "naboo_privateer_tier4_1",
	questType = "rescue_duty",

	questZone = "space_yavin4",

	creditReward = 5000,
	creditKillBonus = 300,

	sideQuest = false,
	sideQuestType = "",

	-- SWG rescue_duty/naboo_privateer_tier4_1.tab (unrotated order, rotated at run time)
	recoveryPath = {
		{patrolPointName = "naboo_privateer_tier4_rescue_duty_1", x = 2654, z = 3066, y = -1100},
		{patrolPointName = "naboo_privateer_tier4_rescue_duty_2", x = 2867, z = 5132, y = -2350},
		{patrolPointName = "naboo_privateer_tier4_rescue_duty_3", x = 2914, z = 6666, y = -4711},
		{patrolPointName = "naboo_privateer_tier4_rescue_duty_4", x = 2512, z = 5626, y = -6352},
		{patrolPointName = "naboo_privateer_tier4_rescue_duty_5", x = 528, z = 5393, y = -6464},
		{patrolPointName = "naboo_privateer_tier4_rescue_duty_6", x = -2108, z = 6155, y = -2772},
	},

	targetShipTypes = {"freighterheavy_tier4", "freighterlight_tier4", "freightermedium_tier4"},
	targetArrivalDelay = 10,

	attackShipLists = {
		{"aynat_intimidator_tier4", "aynat_intimidator_tier4", "aynat_intimidator_tier4", "aynat_intimidator_tier4"},
		{"aynat_outlaw_tier4", "aynat_outlaw_tier4", "aynat_outlaw_tier4", "aynat_outlaw_tier4"},
	},
	attackPeriod = 90,
	attackListType = 1, -- random
	numResponses = 2,
}

registerScreenPlay("rescue_duty_naboo_privateer_tier4_1", true)

--[[
	RSF Squadron Screenplay
]]

RsfSquadronScreenplay = ScreenPlay:new {
	screenplayName = "RsfSquadronScreenplay",

	-- Tier 1 Quest Strings
	QUEST_STRING_1 = {type = "patrol", name = "naboo_privateer_1"},
	QUEST_STRING_1_SIDE = {type = "destroy_surpriseattack", name = "naboo_privateer_1"},
	QUEST_STRING_2 = {type = "destroy", name = "naboo_privateer_2"},
	QUEST_STRING_3 = {type = "patrol", name = "naboo_privateer_3"},
	QUEST_STRING_3_SIDE = {type = "escort", name = "naboo_privateer_3"},
	QUEST_STRING_4 = {type = "assassinate", name = "naboo_privateer_tier1_4a"},

	-- Tier 1 Duty Quest Strings
	QUEST_STRING_DUTY_4_1 = {type = "destroy_duty", name = "naboo_privateer_6"},
	QUEST_STRING_DUTY_4_2 = {type = "escort_duty", name = "naboo_privateer_7"},

	-- Tier 2 Quest Strings
	TIER2_QUEST_STRING_1 = {type = "destroy", name = "naboo_privateer_13a"},
	TIER2_QUEST_STRING_2 = {type = "escort", name = "naboo_privateer_14"},
	TIER2_QUEST_STRING_3 = {type = "inspect", name = "naboo_privateer_15"},
	TIER2_QUEST_STRING_4 = {type = "assassinate", name = "naboo_privateer_tier2_4a"},

	-- Tier 2 Duty Quest Strings
	TIER2_QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "naboo_privateer_9"},
	TIER2_QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "naboo_privateer_10"},
	TIER2_QUEST_STRING_DUTY_3 = {type = "destroy_duty", name = "naboo_privateer_11"},
	TIER2_QUEST_STRING_DUTY_4 = {type = "recovery_duty", name = "naboo_privateer_12"},

	-- Tier 3 Quest Strings
	TIER3_QUEST_STRING_1 = {type = "recovery", name = "naboo_privateer_tier3_1a"},
	TIER3_QUEST_STRING_1_SIDE1 = {type = "patrol", name = "naboo_privateer_tier3_1b"},
	TIER3_QUEST_STRING_1_SIDE2 = {type = "destroy_surpriseattack", name = "naboo_privateer_tier3_1c"},
	TIER3_QUEST_STRING_1_SIDE3 = {type = "assassinate", name = "naboo_privateer_tier3_1d"},
	TIER3_QUEST_STRING_2 = {type = "escort", name = "naboo_privateer_tier3_2a"},
	TIER3_QUEST_STRING_2_SIDE1 = {type = "rescue", name = "naboo_privateer_tier3_2e"},
	TIER3_QUEST_STRING_2_SIDE2 = {type = "space_battle", name = "naboo_privateer_tier3_2d"},
	TIER3_QUEST_STRING_2_SIDE3 = {type = "destroy_surpriseattack", name = "naboo_privateer_tier3_2c"},
	TIER3_QUEST_STRING_3 = {type = "inspect", name = "naboo_privateer_tier3_3a"},
	TIER3_QUEST_STRING_3_SIDE1 = {type = "delivery_no_pickup", name = "naboo_privateer_tier3_3b"},
	TIER3_QUEST_STRING_3_SIDE2 = {type = "survival", name = "naboo_privateer_tier3_3c"},
	TIER3_QUEST_STRING_3_SIDE3 = {type = "destroy_surpriseattack", name = "naboo_privateer_tier3_3e"},
	TIER3_QUEST_STRING_4 = {type = "assassinate", name = "naboo_privateer_tier3_4a"},
	TIER3_QUEST_STRING_4_SIDE1 = {type = "space_battle", name = "naboo_privateer_tier3_4b"},
	TIER3_QUEST_STRING_4_SIDE2 = {type = "destroy_surpriseattack", name = "naboo_privateer_tier3_4c"},
	TIER3_QUEST_STRING_4_SIDE3 = {type = "destroy_surpriseattack", name = "naboo_privateer_tier3_4d"},
	TIER3_QUEST_STRING_4_SIDE4 = {type = "destroy_surpriseattack", name = "naboo_privateer_tier3_4e"},
	TIER3_QUEST_STRING_4_SIDE5 = {type = "assassinate", name = "naboo_privateer_tier3_4f"},

	-- Tier 3 names used before rsf-tier3-renames (F2)
	LEGACY_TIER3_QUESTS = {
		{type = "delivery", name = "naboo_privateer_tier3_3b", moveTo = {{type = "delivery_no_pickup", name = "naboo_privateer_tier3_3b"}}},
		{type = "survival", name = "naboo_privateer_tier3_4c", moveTo = {
			{type = "destroy_surpriseattack", name = "naboo_privateer_tier3_4c"},
			{type = "destroy_surpriseattack", name = "naboo_privateer_tier3_4d"},
			{type = "destroy_surpriseattack", name = "naboo_privateer_tier3_4e"},
		}},
		{type = "destroy_surpriseattack", name = "naboo_privateer_tier3_4_initial", moveTo = {}},
	},
	LEGACY_TIER3_STATUS = {
		{old = "naboo_privateer_tier3_4_initial:attempted", new = "naboo_privateer_tier3_4a:attempted"},
		{old = "naboo_privateer_tier3_4_initial:reward", new = "naboo_privateer_tier3_4a:reward"},
	},
	-- Ordered migration steps; step k runs once per character (marker <id>RsfSquadronScreenplay:legacyVersion)
	LEGACY_MIGRATION_STEPS = {"migrateLegacyTier3"},

	-- Tier 4 Quest Strings
	TIER4_QUEST_STRING_1 = {type = "escort", name = "naboo_privateer_tier4_1a"},
	TIER4_QUEST_STRING_1_SIDE1 = {type = "escort", name = "naboo_privateer_tier4_1b"},
	TIER4_QUEST_STRING_2 = {type = "inspect", name = "naboo_privateer_tier4_2a"},
	TIER4_QUEST_STRING_2_SIDE1 = {type = "destroy_surpriseattack", name = "naboo_privateer_tier4_2b"},
	TIER4_QUEST_STRING_2_SIDE2 = {type = "patrol", name = "naboo_privateer_tier4_2c"},
	TIER4_QUEST_STRING_2_SIDE3 = {type = "destroy_surpriseattack", name = "naboo_privateer_tier4_2d"},
	TIER4_QUEST_STRING_3 = {type = "delivery", name = "naboo_privateer_tier4_3a"},
	TIER4_QUEST_STRING_3_SIDE1 = {type = "patrol", name = "naboo_privateer_tier4_3b"},
	TIER4_QUEST_STRING_3_SIDE2 = {type = "survival", name = "naboo_privateer_tier4_3c"},
	TIER4_QUEST_STRING_4 = {type = "space_battle", name = "naboo_privateer_tier4_4a"},
	TIER4_QUEST_STRING_4_SIDE1 = {type = "escort", name = "naboo_privateer_tier4_4b"},
	TIER4_QUEST_STRING_4_SIDE2A = {type = "space_battle", name = "naboo_privateer_tier4_4c_win"},
	TIER4_QUEST_STRING_4_SIDE2B = {type = "space_battle", name = "naboo_privateer_tier4_4c_lose"},

	-- Tier 4 Duty Quest Strings
	TIER4_QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "naboo_privateer_tier4_1"},
	TIER4_QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "naboo_privateer_tier4_1"},
	TIER4_QUEST_STRING_DUTY_3 = {type = "recovery_duty", name = "naboo_privateer_tier4_1"},
	TIER4_QUEST_STRING_DUTY_4 = {type = "rescue_duty", name = "naboo_privateer_tier4_1"},
}

registerScreenPlay("RsfSquadronScreenplay", false)

function RsfSquadronScreenplay:start()
end

function RsfSquadronScreenplay:resetDingeQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	PlayerObject(pGhost):setPilotTier(1)

	-- Mission 1
	patrol_naboo_privateer_1:resetQuest(pPlayer)
	destroy_surpriseattack_naboo_privateer_1:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_1.type, self.QUEST_STRING_1.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_1_SIDE.type, self.QUEST_STRING_1_SIDE.name, false)

	-- Mission 2
	destroy_naboo_privateer_2:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_2.type, self.QUEST_STRING_2.name, false)

	-- Mission 3
	patrol_naboo_privateer_3:resetQuest(pPlayer)
	escort_naboo_privateer_3:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_3.type, self.QUEST_STRING_3.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_3_SIDE.type, self.QUEST_STRING_3_SIDE.name, false)

	-- Mission 4
	assassinate_naboo_privateer_tier1_4a:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_4.type, self.QUEST_STRING_4.name, false)

	-- Duty Missions
	destroy_duty_naboo_privateer_6:resetQuest(pPlayer)
	escort_duty_naboo_privateer_7:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_DUTY_4_1.type, self.QUEST_STRING_DUTY_4_1.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_DUTY_4_2.type, self.QUEST_STRING_DUTY_4_2.name, false)
end

function RsfSquadronScreenplay:resetKaydineQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	PlayerObject(pGhost):setPilotTier(2)

	-- Mission 1
	destroy_naboo_privateer_13a:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER2_QUEST_STRING_1.type, self.TIER2_QUEST_STRING_1.name, false)

	-- Mission 2
	escort_naboo_privateer_14:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER2_QUEST_STRING_2.type, self.TIER2_QUEST_STRING_2.name, false)

	-- Mission 3
	inspect_naboo_privateer_15:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER2_QUEST_STRING_3.type, self.TIER2_QUEST_STRING_3.name, false)

	-- Mission 4
	assassinate_naboo_privateer_tier2_4a:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER2_QUEST_STRING_4.type, self.TIER2_QUEST_STRING_4.name, false)

	-- Duty Missions
	destroy_duty_naboo_privateer_9:resetQuest(pPlayer)
	escort_duty_naboo_privateer_10:resetQuest(pPlayer)
	destroy_duty_naboo_privateer_11:resetQuest(pPlayer)
	recovery_duty_naboo_privateer_12:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER2_QUEST_STRING_DUTY_1.type, self.TIER2_QUEST_STRING_DUTY_1.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER2_QUEST_STRING_DUTY_2.type, self.TIER2_QUEST_STRING_DUTY_2.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER2_QUEST_STRING_DUTY_3.type, self.TIER2_QUEST_STRING_DUTY_3.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER2_QUEST_STRING_DUTY_4.type, self.TIER2_QUEST_STRING_DUTY_4.name, false)

	-- Clear quest status tracking
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_1.name .. ":attempted")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_2.name .. ":attempted")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_3.name .. ":attempted")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_4.name .. ":attempted")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_1.name .. ":reward")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_2.name .. ":reward")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_3.name .. ":reward")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_4.name .. ":reward")
end

-- Runs the ordered legacy progress migrations once per character
function RsfSquadronScreenplay:migrateLegacyProgress(pPlayer)
	return SpaceHelpers:runProgressMigrations(pPlayer, "RsfSquadronScreenplay", self.LEGACY_MIGRATION_STEPS)
end

-- Step 1: tier 3 renames (delivery_no_pickup 3b, surprise attacks 4c-4e, 4_initial removed)
function RsfSquadronScreenplay:migrateLegacyTier3(pPlayer)
	for _, legacy in ipairs(self.LEGACY_TIER3_QUESTS) do
		SpaceHelpers:migrateSpaceQuestEntry(pPlayer, legacy.type, legacy.name, legacy.moveTo)
	end

	SpaceHelpers:moveQuestStatuses(pPlayer, self.LEGACY_TIER3_STATUS)
end

function RsfSquadronScreenplay:resetDuliosQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	PlayerObject(pGhost):setPilotTier(3)

	-- Mission 1
	recovery_naboo_privateer_tier3_1a:resetQuest(pPlayer)
	patrol_naboo_privateer_tier3_1b:resetQuest(pPlayer)
	destroy_surpriseattack_naboo_privateer_tier3_1c:resetQuest(pPlayer)
	assassinate_naboo_privateer_tier3_1d:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_1.type, self.TIER3_QUEST_STRING_1.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_1_SIDE1.type, self.TIER3_QUEST_STRING_1_SIDE1.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_1_SIDE2.type, self.TIER3_QUEST_STRING_1_SIDE2.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_1_SIDE3.type, self.TIER3_QUEST_STRING_1_SIDE3.name, false)

	-- Mission 2
	escort_naboo_privateer_tier3_2a:resetQuest(pPlayer)
	rescue_naboo_privateer_tier3_2e:resetQuest(pPlayer)
	space_battle_naboo_privateer_tier3_2d:resetQuest(pPlayer)
	destroy_surpriseattack_naboo_privateer_tier3_2c:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_2.type, self.TIER3_QUEST_STRING_2.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_2_SIDE1.type, self.TIER3_QUEST_STRING_2_SIDE1.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_2_SIDE2.type, self.TIER3_QUEST_STRING_2_SIDE2.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_2_SIDE3.type, self.TIER3_QUEST_STRING_2_SIDE3.name, false)

	-- Mission 3
	inspect_naboo_privateer_tier3_3a:resetQuest(pPlayer)
	delivery_no_pickup_naboo_privateer_tier3_3b:resetQuest(pPlayer)
	survival_naboo_privateer_tier3_3c:resetQuest(pPlayer)
	destroy_surpriseattack_naboo_privateer_tier3_3e:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_3.type, self.TIER3_QUEST_STRING_3.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_3_SIDE1.type, self.TIER3_QUEST_STRING_3_SIDE1.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_3_SIDE2.type, self.TIER3_QUEST_STRING_3_SIDE2.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_3_SIDE3.type, self.TIER3_QUEST_STRING_3_SIDE3.name, false)

	-- Mission 4
	assassinate_naboo_privateer_tier3_4a:resetQuest(pPlayer)
	space_battle_naboo_privateer_tier3_4b:resetQuest(pPlayer)
	destroy_surpriseattack_naboo_privateer_tier3_4c:resetQuest(pPlayer)
	destroy_surpriseattack_naboo_privateer_tier3_4d:resetQuest(pPlayer)
	destroy_surpriseattack_naboo_privateer_tier3_4e:resetQuest(pPlayer)
	assassinate_naboo_privateer_tier3_4f:resetQuest(pPlayer)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_4.type, self.TIER3_QUEST_STRING_4.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_4_SIDE1.type, self.TIER3_QUEST_STRING_4_SIDE1.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_4_SIDE2.type, self.TIER3_QUEST_STRING_4_SIDE2.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_4_SIDE3.type, self.TIER3_QUEST_STRING_4_SIDE3.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_4_SIDE4.type, self.TIER3_QUEST_STRING_4_SIDE4.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.TIER3_QUEST_STRING_4_SIDE5.type, self.TIER3_QUEST_STRING_4_SIDE5.name, false)

	-- Names used before rsf-tier3-renames: their globals are gone, so clear them directly
	for _, legacy in ipairs(self.LEGACY_TIER3_QUESTS) do
		SpaceHelpers:purgeSpaceQuest(pPlayer, legacy.type, legacy.name)
	end

	for _, move in ipairs(self.LEGACY_TIER3_STATUS) do
		removeQuestStatus(playerID .. move.old)
	end

	-- Clear quest status tracking
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER3_QUEST_STRING_1.name .. ":attempted")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER3_QUEST_STRING_2.name .. ":attempted")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER3_QUEST_STRING_3.name .. ":attempted")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER3_QUEST_STRING_4.name .. ":attempted")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER3_QUEST_STRING_1.name .. ":reward")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER3_QUEST_STRING_2.name .. ":reward")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER3_QUEST_STRING_3.name .. ":reward")
	removeQuestStatus(playerID .. RsfSquadronScreenplay.TIER3_QUEST_STRING_4.name .. ":reward")
end

function RsfSquadronScreenplay:resetImlerQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	-- Mission 1
	escort_naboo_privateer_tier4_1a:resetQuest(pPlayer)
	escort_naboo_privateer_tier4_1b:resetQuest(pPlayer)

	-- Mission 2
	inspect_naboo_privateer_tier4_2a:resetQuest(pPlayer)
	destroy_surpriseattack_naboo_privateer_tier4_2b:resetQuest(pPlayer)
	patrol_naboo_privateer_tier4_2c:resetQuest(pPlayer)
	destroy_surpriseattack_naboo_privateer_tier4_2d:resetQuest(pPlayer)

	-- Mission 3
	delivery_naboo_privateer_tier4_3a:resetQuest(pPlayer)
	patrol_naboo_privateer_tier4_3b:resetQuest(pPlayer)
	survival_naboo_privateer_tier4_3c:resetQuest(pPlayer)

	-- Mission 4
	space_battle_naboo_privateer_tier4_4a:resetQuest(pPlayer)
	escort_naboo_privateer_tier4_4b:resetQuest(pPlayer)
	space_battle_naboo_privateer_tier4_4c_win:resetQuest(pPlayer)
	space_battle_naboo_privateer_tier4_4c_lose:resetQuest(pPlayer)

	-- Journal entries of every story and duty quest
	local constants = {
		"TIER4_QUEST_STRING_1", "TIER4_QUEST_STRING_1_SIDE1",
		"TIER4_QUEST_STRING_2", "TIER4_QUEST_STRING_2_SIDE1", "TIER4_QUEST_STRING_2_SIDE2", "TIER4_QUEST_STRING_2_SIDE3",
		"TIER4_QUEST_STRING_3", "TIER4_QUEST_STRING_3_SIDE1", "TIER4_QUEST_STRING_3_SIDE2",
		"TIER4_QUEST_STRING_4", "TIER4_QUEST_STRING_4_SIDE1", "TIER4_QUEST_STRING_4_SIDE2A", "TIER4_QUEST_STRING_4_SIDE2B",
		"TIER4_QUEST_STRING_DUTY_1", "TIER4_QUEST_STRING_DUTY_2", "TIER4_QUEST_STRING_DUTY_3", "TIER4_QUEST_STRING_DUTY_4",
	}

	for _, constant in ipairs(constants) do
		local quest = self[constant]

		SpaceHelpers:clearSpaceQuest(pPlayer, quest.type, quest.name, false)
	end

	-- Clear quest status tracking
	local missions = {
		self.TIER4_QUEST_STRING_1.name, self.TIER4_QUEST_STRING_2.name,
		self.TIER4_QUEST_STRING_3.name, self.TIER4_QUEST_STRING_4.name,
	}

	for _, name in ipairs(missions) do
		removeQuestStatus(playerID .. name .. ":attempted")
		removeQuestStatus(playerID .. name .. ":reward")
	end

	removeQuestStatus(playerID .. "RsfSquadronScreenplay:StartedImler")
	removeQuestStatus(playerID .. "RsfSquadronScreenplay:readyForTier4Mission")
end
