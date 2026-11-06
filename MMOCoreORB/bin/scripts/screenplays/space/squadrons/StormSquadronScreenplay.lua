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
