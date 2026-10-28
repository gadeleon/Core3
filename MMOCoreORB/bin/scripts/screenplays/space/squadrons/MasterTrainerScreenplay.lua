--[[

	Master Trainer Quests

	Grand Admiral Declann's quests, ported from SWG-Source destroy/master_imperial_1 and master_imperial_2
	(feature space-master-trainer-imperial). The Rebel master trainer adds its quests to this file.

]]

local SpaceHelpers = require("utils.space_helpers")

MasterTrainerScreenplay = ScreenPlay:new {
	screenplayName = "MasterTrainerScreenplay",

	-- Grand Admiral Nial Declann (imperial_master_trainer.java)
	QUEST_STRING_IMPERIAL_1 = {type = "destroy", name = "master_imperial_1"},
	QUEST_STRING_IMPERIAL_2 = {type = "destroy", name = "master_imperial_2"},

	-- SWG space flags shared by the two master trainers (privateers choose one side)
	MASTER_MISSION_IMPERIAL_KEY = "MasterTrainerScreenplay:master_mission_imperial",
	MASTER_MISSION_REBEL_KEY = "MasterTrainerScreenplay:master_mission_rebel",
}

registerScreenPlay("MasterTrainerScreenplay", false)

-- Mission 1: destroy 30 Rebel ships over Kessel
destroy_master_imperial_1 = SpaceDestroyScreenplay:new {
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

	-- Pre-NGE: leaving Kessel keeps the progress
	failOnLeaveZone = false,

	shipLocations = {},

	shipTypes = {
		"reb_awing_tier5", "reb_bwing_tier5", "reb_gunboat_tier5", "reb_kessel_lootboat_tier5",
		"reb_xwing_tier5", "reb_ywing_tier5", "reb_z95_tier5", "rebel_smuggler_tier5",
	},
}

registerScreenPlay("destroy_master_imperial_1", true)

-- Mission 2: destroy the Rebel corvette over Kessel
destroy_master_imperial_2 = SpaceDestroyScreenplay:new {
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

	-- Pre-NGE: leaving Kessel keeps the progress
	failOnLeaveZone = false,

	shipLocations = {},

	shipTypes = {
		"reb_corellian_corvette_tier4",
	},
}

registerScreenPlay("destroy_master_imperial_2", true)

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
