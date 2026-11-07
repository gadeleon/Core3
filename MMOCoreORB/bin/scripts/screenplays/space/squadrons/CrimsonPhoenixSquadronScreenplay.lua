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

	-- SWG's ekerPilot space flag ("1" from Da'la Socuna; tier 2 reads it as set and writes "2")
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
