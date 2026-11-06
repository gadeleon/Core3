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
