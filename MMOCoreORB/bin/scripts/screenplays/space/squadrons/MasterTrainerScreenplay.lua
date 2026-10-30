--[[

	Master Trainer Quests

	Grand Admiral Declann's quests, ported from SWG-Source destroy/master_imperial_1 and master_imperial_2
	(feature space-master-trainer-imperial). The Rebel master trainer adds its quests to this file.
	Admiral Burke's quests, ported from SWG-Source destroy/master_rebel_1 and master_rebel_2 (feature space-master-trainer-rebel).
	The four master missions use SpaceMasterDestroyScreenplay (feature space-master-mission-quest-type), so their progress persists.

]]

local SpaceHelpers = require("utils.space_helpers")

MasterTrainerScreenplay = ScreenPlay:new {
	screenplayName = "MasterTrainerScreenplay",

	-- Grand Admiral Nial Declann (imperial_master_trainer.java)
	QUEST_STRING_IMPERIAL_1 = {type = "destroy", name = "master_imperial_1"},
	QUEST_STRING_IMPERIAL_2 = {type = "destroy", name = "master_imperial_2"},

	-- Admiral Willham Burke (rebel_master_trainer.java)
	QUEST_STRING_REBEL_1 = {type = "destroy", name = "master_rebel_1"},
	QUEST_STRING_REBEL_2 = {type = "destroy", name = "master_rebel_2"},

	-- SWG space flags shared by the two master trainers (privateers choose one side)
	MASTER_MISSION_IMPERIAL_KEY = "MasterTrainerScreenplay:master_mission_imperial",
	MASTER_MISSION_REBEL_KEY = "MasterTrainerScreenplay:master_mission_rebel",
}

registerScreenPlay("MasterTrainerScreenplay", false)

-- Mission 1: destroy 30 Rebel ships over Kessel
destroy_master_imperial_1 = SpaceMasterDestroyScreenplay:new {
	className = "destroy_master_imperial_1",

	questName = "master_imperial_1",
	questType = "destroy",

	questZone = "space_light1",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/wearables/jacket/jacket_ace_imperial.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	killsRequired = 30,

	shipLocations = {},

	shipTypes = {
		"reb_awing_tier5", "reb_bwing_tier5", "reb_gunboat_tier5", "reb_kessel_lootboat_tier5",
		"reb_xwing_tier5", "reb_ywing_tier5", "reb_z95_tier5", "rebel_smuggler_tier5",
	},
}

registerScreenPlay("destroy_master_imperial_1", true)

-- Mission 2: destroy the Rebel corvette over Kessel
destroy_master_imperial_2 = SpaceMasterDestroyScreenplay:new {
	className = "destroy_master_imperial_2",

	questName = "master_imperial_2",
	questType = "destroy",

	questZone = "space_light1",

	creditReward = 50000,
	itemReward = {
		{species = {-1}, item = "object/tangible/wearables/helmet/helmet_fighter_imperial_ace.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	killsRequired = 1,

	shipLocations = {},

	shipTypes = {
		"reb_corellian_corvette_tier4",
	},
}

registerScreenPlay("destroy_master_imperial_2", true)

-- Mission 1: destroy 30 Imperial ships over Kessel
destroy_master_rebel_1 = SpaceMasterDestroyScreenplay:new {
	className = "destroy_master_rebel_1",

	questName = "master_rebel_1",
	questType = "destroy",

	questZone = "space_light1",

	creditReward = 25000,
	itemReward = {
		{species = {-1}, item = "object/tangible/wearables/jacket/jacket_ace_rebel.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	killsRequired = 30,

	shipLocations = {},

	shipTypes = {
		"imp_imperial_gunboat_tier5", "imp_imperial_kessel_lootboat_tier5", "imp_tie_advanced_tier5", "imp_tie_aggressor_tier5",
		"imp_tie_fighter_tier5", "imp_tie_interceptor_tier5", "imp_tie_oppressor_tier5", "imp_tie_bomber_tier5",
		"imp_lambda_shuttle_tier5",
	},
}

registerScreenPlay("destroy_master_rebel_1", true)

-- Mission 2: destroy the Imperial corvette over Kessel
destroy_master_rebel_2 = SpaceMasterDestroyScreenplay:new {
	className = "destroy_master_rebel_2",

	questName = "master_rebel_2",
	questType = "destroy",

	questZone = "space_light1",

	creditReward = 50000,
	itemReward = {
		{species = {-1}, item = "object/tangible/wearables/helmet/helmet_fighter_rebel_ace.iff"},
	},

	sideQuest = false,
	sideQuestType = "",

	killsRequired = 1,

	shipLocations = {},

	shipTypes = {
		"imp_corellian_corvette_tier4",
	},
}

registerScreenPlay("destroy_master_rebel_2", true)

-- Clears Declann's quests, journal entries and keys (surrender). The Rebel key belongs to Burke's reset.
function MasterTrainerScreenplay:resetDeclannQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	destroy_master_imperial_1:resetQuest(pPlayer)
	destroy_master_imperial_2:resetQuest(pPlayer)

	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_IMPERIAL_1.type, self.QUEST_STRING_IMPERIAL_1.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_IMPERIAL_2.type, self.QUEST_STRING_IMPERIAL_2.name, false)

	local playerID = SceneObject(pPlayer):getObjectID()

	for n = 1, 2 do
		removeQuestStatus(playerID .. self["QUEST_STRING_IMPERIAL_" .. n].name .. ":attempted")
		removeQuestStatus(playerID .. self["QUEST_STRING_IMPERIAL_" .. n].name .. ":reward")
	end

	removeQuestStatus(playerID .. self.MASTER_MISSION_IMPERIAL_KEY)
end

-- Clears Burke's quests, journal entries and keys (surrender). The Imperial key belongs to Declann's reset.
function MasterTrainerScreenplay:resetBurkeQuests(pPlayer)
	if (pPlayer == nil) then
		return
	end

	destroy_master_rebel_1:resetQuest(pPlayer)
	destroy_master_rebel_2:resetQuest(pPlayer)

	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_REBEL_1.type, self.QUEST_STRING_REBEL_1.name, false)
	SpaceHelpers:clearSpaceQuest(pPlayer, self.QUEST_STRING_REBEL_2.type, self.QUEST_STRING_REBEL_2.name, false)

	local playerID = SceneObject(pPlayer):getObjectID()

	for n = 1, 2 do
		removeQuestStatus(playerID .. self["QUEST_STRING_REBEL_" .. n].name .. ":attempted")
		removeQuestStatus(playerID .. self["QUEST_STRING_REBEL_" .. n].name .. ":reward")
	end

	removeQuestStatus(playerID .. self.MASTER_MISSION_REBEL_KEY)
end
