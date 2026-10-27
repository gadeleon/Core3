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
