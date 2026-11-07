local SpaceHelpers = require("utils.space_helpers")

--[[

	Vortex Squadron Quests

]]

--[[
	Tier 1 -- V3-FX (Naboo, Moenia)
	Trainer: V3-FX (conversation v3fxConvoHandler), Moenia gazebo (screenplays/cities/naboo_moenia.lua:108). 8 quest tables for 6 SWG-Source names: naboo_rebel_1..4, 6, 7 (patrol, destroy_surpriseattack, destroy, escort, assassinate, destroy_duty, escort_duty), from datatables/spacequest and naboo_rebel_trainer_1.java; feature vortex-tier1-v3-fx
	Tiers 2-4 (Brother Vrovel, Brother Ezkiel, Brother Extok Evin) are not ported yet
]]

-- Mission 1: Patrol with surprise attack
patrol_naboo_rebel_1 = SpacePatrolScreenplay:new {
	className = "patrol_naboo_rebel_1",

	questName = "naboo_rebel_1",
	questType = "patrol",

	questZone = "space_naboo",

	creditReward = 100,

	sideQuest = true,
	sideQuestType = "destroy_surpriseattack",
	sideQuestName = "naboo_rebel_1",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 13,

	patrolPoints = {
		{patrolPointName = "rebel_patrol_1", x = -3153, z = 302, y = -6442, patrolNumber = 1, radius = 150},
		{patrolPointName = "rebel_patrol_2", x = -3971, z = -471, y = -6364, patrolNumber = 2, radius = 150},
		{patrolPointName = "rebel_patrol_3", x = -5771, z = -1066, y = -5197, patrolNumber = 3, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_rebel_1", true)

destroy_surpriseattack_naboo_rebel_1 = SpaceSurpriseAttackScreenplay:new {
	className = "destroy_surpriseattack_naboo_rebel_1",

	questName = "naboo_rebel_1",
	questType = "destroy_surpriseattack",

	questZone = "space_naboo",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_naboo_rebel_1",
	parentQuestType = "patrol",
	parentQuestName = "naboo_rebel_1",

	surpriseAttackShips = {
		zone = "space_naboo",
		spawns = {{count = 3, shipName = "imp_tie_fighter_tier1"}},
	},
}

registerScreenPlay("destroy_surpriseattack_naboo_rebel_1", true)

-- Mission 2: Destroy
destroy_naboo_rebel_2 = SpaceDestroyScreenplay:new {
	className = "destroy_naboo_rebel_2",

	questName = "naboo_rebel_2",
	questType = "destroy",

	questZone = "space_naboo",

	creditReward = 200,

	sideQuest = false,
	sideQuestType = "",

	killsRequired = 4,

	shipLocations = {
		{spawnName = "imperial_fluff_spawns_1", x = 386, z = 3917, y = 3129},
		{spawnName = "imperial_fluff_spawns_3", x = -2024, z = -3820, y = -3131},
		{spawnName = "imperial_fluff_spawns_5", x = -5968, z = -1847, y = 386},
		{spawnName = "naboo_imperial_2", x = -1915, z = -2006, y = -1455},
		{spawnName = "imperial_patrol_1", x = 263, z = 2203, y = 1703},
	},

	shipTypes = {
		"imp_tie_fighter_tier1",
		"imp_tie_fighter_tier2",
		"imp_tie_fighter_tier3",
		"imp_tie_fighter_tier4",
		"imp_tie_fighter_tier2_naboo",
	},
}

registerScreenPlay("destroy_naboo_rebel_2", true)

-- Mission 3: Patrol with escort side quest
patrol_naboo_rebel_3 = SpacePatrolScreenplay:new {
	className = "patrol_naboo_rebel_3",

	questName = "naboo_rebel_3",
	questType = "patrol",

	questZone = "space_naboo",

	creditReward = 500,
	-- SWG's rebel_bodysuit_s14.iff has no pre-NGE template; bodysuit_s14 as for Kreezo (space-trainer-rewards D-11)
	itemReward = {
		{species = {SPECIES_WOOKIEE}, item = "object/tangible/wearables/bandolier/multipocket_bandolier.iff"},
		{species = {SPECIES_ITHORIAN}, item = "object/tangible/wearables/bandolier/ith_multipocket_bandolier.iff"},
		{species = {-1}, item = "object/tangible/wearables/bodysuit/bodysuit_s14.iff"},
	},

	sideQuest = true,
	sideQuestType = "escort",
	sideQuestName = "naboo_rebel_3",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT,

	sideQuestPatrolStart = 2,
	sideQuestDelay = 15,

	patrolPoints = {
		{patrolPointName = "rebel_security_patrol_1", x = -2448, z = 879, y = -1221, patrolNumber = 1, radius = 150},
		{patrolPointName = "rebel_security_patrol_2", x = -1792, z = 1559, y = -1193, patrolNumber = 2, radius = 150},
		{patrolPointName = "rebel_security_patrol_3", x = -288, z = 1479, y = -1395, patrolNumber = 3, radius = 150},
		{patrolPointName = "rebel_security_patrol_4", x = 39, z = 1753, y = 294, patrolNumber = 4, radius = 150},
	},
}

registerScreenPlay("patrol_naboo_rebel_3", true)

escort_naboo_rebel_3 = SpaceEscortScreenplay:new {
	className = "escort_naboo_rebel_3",

	questName = "naboo_rebel_3",
	questType = "escort",

	questZone = "space_naboo",

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "patrol_naboo_rebel_3",
	parentQuestType = "patrol",
	parentQuestName = "naboo_rebel_3",

	escortShips = {"reb_freightermedium_tier1"},

	escortPoints = {
		{patrolPointName = "rebel_escort_1", zoneName = "space_naboo", x = -168, z = 1747, y = -258, escortNumber = 1, radius = 250},
		{patrolPointName = "rebel_escort_2", zoneName = "space_naboo", x = -1077, z = 1502, y = 59, escortNumber = 2, radius = 250},
		{patrolPointName = "rebel_escort_3", zoneName = "space_naboo", x = -1645, z = 1097, y = 854, escortNumber = 3, radius = 250},
		{patrolPointName = "rebel_escort_4", zoneName = "space_naboo", x = -2734, z = 791, y = 1760, escortNumber = 4, radius = 250},
	},

	attackDelay = 80,

	attackShips = {
		{"imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"},
	},

	tauntData = {goodbyeCount = 3, reasonCount = 3, tauntCount = 3, thanksCount = 3},
}

registerScreenPlay("escort_naboo_rebel_3", true)

-- Mission 4: Assassinate
assassinate_naboo_rebel_4 = SpaceAssassinateScreenplay:new {
	className = "assassinate_naboo_rebel_4",

	questType = "assassinate",
	questName = "naboo_rebel_4",

	questZone = "space_naboo",

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
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_8", x = 3875, z = -3872, y = -3934},
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_6", x = 417, z = -839, y = -2617},
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_4", x = -1492, z = 746, y = -2021},
		{patrolPointName = "naboo_imperial_tier2_recoveryduty_2", x = 1333, z = -1855, y = -3915},
		{patrolPointName = "naboo_imperial_tier2_recovery1_3", x = 262, z = -3151, y = 332},
	},
}

registerScreenPlay("assassinate_naboo_rebel_4", true)

-- V3-FX Duty Missions
destroy_duty_naboo_rebel_6 = SpaceDutyDestroyScreenplay:new {
	className = "destroy_duty_naboo_rebel_6",

	questName = "naboo_rebel_6",
	questType = "destroy_duty",

	questZone = "space_naboo",

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

registerScreenPlay("destroy_duty_naboo_rebel_6", true)

escort_duty_naboo_rebel_7 = SpaceDutyEscortScreenplay:new {
	className = "escort_duty_naboo_rebel_7",

	questName = "naboo_rebel_7",
	questType = "escort_duty",

	questZone = "space_naboo",

	creditReward = 1000,
	creditKillBonus = 100,

	sideQuest = false,
	sideQuestType = "",

	escortShips = {
		"reb_transport_tier1", "reb_freightermedium_tier1", "reb_freighterlight_tier1", "reb_freighterheavy_tier1",
	},

	escortPoints = {
		{patrolPointName = "rebel_patrol_1", zoneName = "space_naboo", x = -3153, z = 302, y = -6442, escortNumber = 1, radius = 250},
		{patrolPointName = "rebel_patrol_2", zoneName = "space_naboo", x = -3971, z = -471, y = -6364, escortNumber = 2, radius = 250},
		{patrolPointName = "rebel_patrol_3", zoneName = "space_naboo", x = -5771, z = -1066, y = -5197, escortNumber = 3, radius = 250},
		{patrolPointName = "rebel_escort_1", zoneName = "space_naboo", x = -168, z = 1747, y = -258, escortNumber = 4, radius = 250},
		{patrolPointName = "rebel_escort_2", zoneName = "space_naboo", x = -1077, z = 1502, y = 59, escortNumber = 5, radius = 250},
		{patrolPointName = "rebel_escort_3", zoneName = "space_naboo", x = -1645, z = 1097, y = 854, escortNumber = 6, radius = 250},
		{patrolPointName = "rebel_escort_4", zoneName = "space_naboo", x = -2734, z = 791, y = 1760, escortNumber = 7, radius = 250},
	},

	attackDelay = 100,

	attackShips = {
		{"imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"},
	},

	tauntData = {goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5},
}

registerScreenPlay("escort_duty_naboo_rebel_7", true)

--[[

	VortexSquadronScreenplay

]]

VortexSquadronScreenplay = ScreenPlay:new {
	screenplayName = "VortexSquadronScreenplay",

	-- Tier 1 (V3-FX)
	QUEST_STRING_1 = {type = "patrol", name = "naboo_rebel_1"},
	QUEST_STRING_1_SIDE = {type = "destroy_surpriseattack", name = "naboo_rebel_1"},
	QUEST_STRING_2 = {type = "destroy", name = "naboo_rebel_2"},
	QUEST_STRING_3 = {type = "patrol", name = "naboo_rebel_3"},
	QUEST_STRING_3_SIDE = {type = "escort", name = "naboo_rebel_3"},
	QUEST_STRING_4 = {type = "assassinate", name = "naboo_rebel_4"},
	QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "naboo_rebel_6"},
	QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "naboo_rebel_7"},

	-- SWG's vortexPilot space flag ("1" from V3-FX; tier 2 moves it to "2" and "3")
	VORTEX_PILOT_KEY = "VortexSquadronScreenplay:vortexPilot",
}

registerScreenPlay("VortexSquadronScreenplay", false)

function VortexSquadronScreenplay:start()
end

-- Clears V3-FX's quests, journal entries and keys (surrender)
function VortexSquadronScreenplay:resetV3fxQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	local tables = {
		patrol_naboo_rebel_1, destroy_surpriseattack_naboo_rebel_1, destroy_naboo_rebel_2, patrol_naboo_rebel_3,
		escort_naboo_rebel_3, assassinate_naboo_rebel_4, destroy_duty_naboo_rebel_6, escort_duty_naboo_rebel_7
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

	removeQuestStatus(playerID .. self.VORTEX_PILOT_KEY)
end
