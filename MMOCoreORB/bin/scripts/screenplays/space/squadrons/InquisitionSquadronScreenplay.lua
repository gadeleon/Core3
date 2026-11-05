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

	-- Flags (stored as <playerID><suffix>, value "1")
	-- Set by Barn's promotion; tier 2 (Fa'Zoll) reads it as the SWG series flag naboo_imperial_1
	SERIES_COMPLETE_KEY = "InquisitionSquadronScreenplay:naboo_imperial_1",
	-- Set by the tier 2 feature when Fa'Zoll signs the pilot up (SWG makeInquisitorialAgent); only read here
	INQUISITORIAL_AGENT_KEY = "InquisitionSquadronScreenplay:inquisitorialAgent",
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
