local SpaceHelpers = require("utils.space_helpers")

--[[
	Tatooine Station -- Lady Valarian's bounty, Jabba's Palace landing access and the Hutt freighter duty
	Ported from SWG-Source tatooine_station_hutt_palace_access_quest_1..4 and tatooine_station_hutt_recovery_duty_tier1_1;
	feature tatooine-station-palace-access
	Also here: quest 4's 10,000 credit auto reward and mail (completeQuest override), the access flag and station eligibility helpers (TatooineStationPalaceAccessScreenplay),
	and the Read/Sign menu of the Palace Access Document (PalaceAccessDocMenuComponent, from SWG-Source palace_access_doc.java).
	The station dialogue that offers these quests is reconstructed (SWG's station script is lost); see spacestation_tatooine_conv_handler.lua.
]]

-- Quest 1: Rescue (space_tatooine) > Quest 2: Delivery (space_yavin4) > Quest 3: Battle (space_yavin4) > Quest 4: Assassinate Hortrix Steelarm (space_yavin4)

rescue_tatooine_station_hutt_palace_access_quest_1 = SpaceRescueScreenplay:new {
	className = "rescue_tatooine_station_hutt_palace_access_quest_1",

	questName = "tatooine_station_hutt_palace_access_quest_1",
	questType = "rescue",

	questZone = "space_tatooine",

	creditReward = 0,
	itemReward = {},

	sideQuest = true,
	sideQuestType = "delivery_no_pickup",
	sideQuestName = "tatooine_station_hutt_palace_access_quest_2",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	-- Screenplay Specific Variables
	recoveryPath = {
		{patrolPointName = "tatooine_station_hutt_palace_access_rescue_1", x = 4527, z = -1839, y = 2143},
		{patrolPointName = "tatooine_station_hutt_palace_access_rescue_2", x = 2576, z = -2002, y = 1586},
		{patrolPointName = "tatooine_station_hutt_palace_access_rescue_3", x = 1128, z = -2914, y = 1754},
		{patrolPointName = "tatooine_station_hutt_palace_access_rescue_4", x = -686, z = -3396, y = 1450},
	},

	targetShipType = "huttsmuggler_tier3",
	targetArrivalDelay = 10,

	attackShipLists = {
		{"imp_tie_bomber_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
		{"imp_tie_interceptor_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"},
	},

	attackPeriod = 90,
	attackListType = SpaceRescueScreenplay.ATTACK_LIST_TYPES.RANDOM,
	numResponses = 5,
}

registerScreenPlay("rescue_tatooine_station_hutt_palace_access_quest_1", true)

delivery_no_pickup_tatooine_station_hutt_palace_access_quest_2 = SpaceDeliveryNoPickupScreenplay:new {
	className = "delivery_no_pickup_tatooine_station_hutt_palace_access_quest_2",

	questName = "tatooine_station_hutt_palace_access_quest_2",
	questType = "delivery_no_pickup",

	questZone = "space_yavin4",

	creditReward = 0,
	itemReward = {},

	sideQuest = true,
	sideQuestType = "space_battle",
	sideQuestName = "tatooine_station_hutt_palace_access_quest_3",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "rescue_tatooine_station_hutt_palace_access_quest_1",
	parentQuestType = "rescue",
	parentQuestName = "tatooine_station_hutt_palace_access_quest_1",

	-- Screenplay Specific Variables
	deliveryShip = "smuggler_yt1300_tier3",

	deliveryPoint = {patrolPointName = "tatooine_station_hutt_palace_access_quest_delivery_point", x = -1267, z = 6104, y = 5748},

	attackShipLists = {
		{"vylukh_clan_soldier_tier3", "vylukh_clan_soldier_tier3"},
		{"vylukh_clan_elite_tier3", "vylukh_clan_elite_tier3"},
	},

	attackPeriod = 120,
	attackListType = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM,
}

registerScreenPlay("delivery_no_pickup_tatooine_station_hutt_palace_access_quest_2", true)

space_battle_tatooine_station_hutt_palace_access_quest_3 = SpaceBattleScreenplay:new {
	className = "space_battle_tatooine_station_hutt_palace_access_quest_3",

	questName = "tatooine_station_hutt_palace_access_quest_3",
	questType = "space_battle",

	questZone = "space_yavin4",

	sideQuest = true,
	sideQuestType = "assassinate",
	sideQuestName = "tatooine_station_hutt_palace_access_quest_4",
	sideFailQuestType = "assassinate",
	sideFailQuestName = "tatooine_station_hutt_palace_access_quest_4",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	parentQuest = "delivery_no_pickup_tatooine_station_hutt_palace_access_quest_2",
	parentQuestType = "delivery_no_pickup",
	parentQuestName = "tatooine_station_hutt_palace_access_quest_2",

	-- Screenplay Specific Variables
	battlePoint = {patrolPointName = "tatooine_station_hutt_palace_access_battle_point", x = 801, z = 6389, y = 2157, forward = {x = 0.396131, z = -0.018721, y = -0.918003}},

	damageMultiplier = 6,
	allyArrivalDelay = 30,
	enemyArrivalDelay = 40,
	allyOriginDist = 100,
	enemyOriginDist = -500,
	allyArrivalDist = 800,
	enemyArrivalDist = 500,

	allyForce = {
		"valarian_smuggler_tier2", "valarian_smuggler_tier2",
	},

	enemyForce = {
		"hutt_fighter_s02_tier3", "hutt_heavy_s02_tier3", "hutt_fighter_s02_tier2", "hutt_fighter_s02_tier2", "hutt_fighter_s02_tier2",
	},
}

registerScreenPlay("space_battle_tatooine_station_hutt_palace_access_quest_3", true)

assassinate_tatooine_station_hutt_palace_access_quest_4 = SpaceAssassinateScreenplay:new {
	className = "assassinate_tatooine_station_hutt_palace_access_quest_4",

	questName = "tatooine_station_hutt_palace_access_quest_4",
	questType = "assassinate",

	questZone = "space_yavin4",

	creditReward = 0,
	itemReward = {},

	-- SWG autoReward: paid to the bank on success, with a bank statement mail (space_quest.java:565-578)
	autoRewardCredits = 10000,

	sideQuest = false,
	sideQuestType = "",

	parentQuest = "space_battle_tatooine_station_hutt_palace_access_quest_3",
	parentQuestType = "space_battle",
	parentQuestName = "tatooine_station_hutt_palace_access_quest_3",

	-- Screenplay Specific Variables
	arrivalDelay = 5,
	failTimer = 20,
	mustDestroyEscort = false,

	assassinateSpawns = {
		target = "hutt_quest_hortrix_steelarm_tier3",
		escorts = {"hutt_pirate_s02_tier2", "hutt_pirate_s02_tier2"},
	},

	targetPatrols = {
		{patrolPointName = "tatooine_station_hutt_access_assassinate_1", x = 992, z = 6370, y = 909},
		{patrolPointName = "tatooine_station_hutt_access_assassinate_2", x = 966, z = 6111, y = -478},
		{patrolPointName = "tatooine_station_hutt_access_assassinate_3", x = 921, z = 5801, y = -1918},
		{patrolPointName = "tatooine_station_hutt_access_assassinate_4", x = 169, z = 6390, y = -939},
	},
}

function assassinate_tatooine_station_hutt_palace_access_quest_4:completeQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		return
	end

	-- Only a running quest pays: a failed, aborted or already completed entry must not
	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	SpaceAssassinateScreenplay.completeQuest(self, pPlayer, notifyClient)

	SpaceHelpers:spaceCreditReward(pPlayer, self.autoRewardCredits)

	local base = "@spacequest/" .. self.questType .. "/" .. self.questName

	sendMail(base .. ":autorewardfrom", base .. ":autorewardsubject", base .. ":autorewardbody", CreatureObject(pPlayer):getFirstName())
end

registerScreenPlay("assassinate_tatooine_station_hutt_palace_access_quest_4", true)

-- Hutt freighter duty (offered by the station's "Do you have any work for me?")

recovery_duty_tatooine_station_hutt_recovery_duty_tier1_1 = SpaceDutyRecoveryScreenplay:new {
	className = "recovery_duty_tatooine_station_hutt_recovery_duty_tier1_1",

	questName = "tatooine_station_hutt_recovery_duty_tier1_1",
	questType = "recovery_duty",

	questZone = "space_tatooine",

	creditReward = 1000,
	creditKillBonus = 100,
	numResponses = 5,

	sideQuest = false,
	sideQuestType = "",

	-- Screenplay Specific Variables
	recoverShips = {"freighterheavy_tier2", "freighterlight_tier2", "freightermedium_tier2"},
	arrivalDelay = 10,
	recoveryDelay = 30,

	recoveryConversationMobile = "object/mobile/shared_dressed_hutt_expedition_force_member.iff",

	escortShips = {"mercenary_guard_tier2", "mercenary_guard_tier1", "mercenary_guard_tier1"},

	preRecoveryPoints = {
		{patrolPointName = "tatooine_station_hutt_recovery_duty_1", x = 3796, z = -5228, y = 490, escortNumber = 1, radius = 250},
		{patrolPointName = "tatooine_station_hutt_recovery_duty_2", x = 2853, z = -5640, y = -623, escortNumber = 2, radius = 250},
		{patrolPointName = "tatooine_station_hutt_recovery_duty_3", x = 2667, z = -6221, y = -1908, escortNumber = 3, radius = 250},
		{patrolPointName = "tatooine_station_hutt_recovery_duty_4", x = 1212, z = -5888, y = -2603, escortNumber = 4, radius = 250},
	},

	recoveryPoints = {
		{patrolPointName = "tatooine_station_hutt_recovery_duty_5", x = 3485, z = -5917, y = -4160, escortNumber = 1, radius = 250},
		{patrolPointName = "tatooine_station_hutt_recovery_duty_6", x = 5688, z = -5517, y = -3706, escortNumber = 2, radius = 250},
		{patrolPointName = "tatooine_station_hutt_recovery_duty_7", x = 6935, z = -5165, y = -1852, escortNumber = 3, radius = 250},
	},

	attackDelay = 70,

	attackShips = {
		{"valarian_bomber_tier1_tatooine", "valarian_bomber_tier2"},
		{"mercenary_guard_tier2", "mercenary_guard_tier1", "mercenary_guard_tier1"},
		{"mos_eisley_police", "mos_eisley_police", "mos_eisley_police", "mos_eisley_police"},
	},

	tauntData = {panicCount = 5, thanksCount = 5},
}

registerScreenPlay("recovery_duty_tatooine_station_hutt_recovery_duty_tier1_1", true)

--[[
	Station side: eligibility, the palace access flag and the access document
]]

TatooineStationPalaceAccessScreenplay = ScreenPlay:new {
	QUEST_HEAD = "rescue_tatooine_station_hutt_palace_access_quest_1",

	QUEST_STRINGS = {
		{type = "rescue", name = "tatooine_station_hutt_palace_access_quest_1"},
		{type = "delivery_no_pickup", name = "tatooine_station_hutt_palace_access_quest_2"},
		{type = "space_battle", name = "tatooine_station_hutt_palace_access_quest_3"},
		{type = "assassinate", name = "tatooine_station_hutt_palace_access_quest_4"},
	},

	-- Persistent quest status under <playerID> .. ACCESS_KEY, "1" = Jabba's Palace landing unlocked (SWG objvar space_access_jabba)
	ACCESS_KEY = "TatooineStationPalaceAccessScreenplay:space_access_jabba",

	ACCESS_DOC = "object/tangible/space/mission_objects/palace_access_doc.iff",

	SIGNATURE_KEY = "signature",

	TRAVEL_POINT = "jabbas_palace",

	HUTT_DUTY = "recovery_duty_tatooine_station_hutt_recovery_duty_tier1_1",

	HUTT_DUTY_STRING = {type = "recovery_duty", name = "tatooine_station_hutt_recovery_duty_tier1_1"},
}

registerScreenPlay("TatooineStationPalaceAccessScreenplay", false)

function TatooineStationPalaceAccessScreenplay:hasPalaceAccess(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	return getQuestStatus(CreatureObject(pPlayer):getObjectID() .. self.ACCESS_KEY) == "1"
end

function TatooineStationPalaceAccessScreenplay:grantPalaceAccess(pPlayer)
	if (pPlayer == nil) then
		return
	end

	setQuestStatus(CreatureObject(pPlayer):getObjectID() .. self.ACCESS_KEY, "1")
end

-- The first access document directly in the inventory, or nil
function TatooineStationPalaceAccessScreenplay:getAccessDoc(pPlayer)
	if (pPlayer == nil) then
		return nil
	end

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if (pInventory == nil) then
		return nil
	end

	return getContainerObjectByTemplate(pInventory, self.ACCESS_DOC, false)
end

-- The signature stored by the Read/Sign menu, "" when unsigned
function TatooineStationPalaceAccessScreenplay:getDocSignature(pDoc)
	if (pDoc == nil) then
		return ""
	end

	local signature = TangibleObject(pDoc):getLuaStringData(self.SIGNATURE_KEY)

	if (signature == nil) then
		return ""
	end

	return signature
end

-- Destroys every access document directly in the inventory (SWG removeAccessDocuments), returns how many
function TatooineStationPalaceAccessScreenplay:removeAccessDocs(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if (pInventory == nil) then
		return 0
	end

	local docs = {}

	for i = 1, SceneObject(pInventory):getContainerObjectsSize(), 1 do
		local pObject = SceneObject(pInventory):getContainerObject(i - 1)

		if (pObject ~= nil and SceneObject(pObject):getTemplateObjectPath() == self.ACCESS_DOC) then
			docs[#docs + 1] = pObject
		end
	end

	for _, pDoc in ipairs(docs) do
		SceneObject(pDoc):destroyObjectFromWorld()
		SceneObject(pDoc):destroyObjectFromDatabase()
	end

	return #docs
end

-- The station offers the bounty to Smuggler squadron pilots without palace access whose chain is not running
function TatooineStationPalaceAccessScreenplay:isOfferEligible(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	return SpaceHelpers:isSmugglerSquadron(pPlayer) and not self:hasPalaceAccess(pPlayer) and not SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.QUEST_HEAD)
end

function TatooineStationPalaceAccessScreenplay:startBounty(pPlayer, pNpc)
	return SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.QUEST_HEAD)
end

function TatooineStationPalaceAccessScreenplay:isHuttWorkEligible(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	return SpaceHelpers:isSmugglerSquadron(pPlayer)
end

function TatooineStationPalaceAccessScreenplay:startHuttDuty(pPlayer, pNpc)
	return _G[self.HUTT_DUTY]:startQuest(pPlayer, pNpc)
end

-- The palace access document's Read / Sign menu (SWG script/space/special_loot/palace_access_doc.java)
PalaceAccessDocMenuComponent = {}

function PalaceAccessDocMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)

	menuResponse:addRadialMenuItem(20, 3, "@space/quest:read")
end

function PalaceAccessDocMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
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

	self:showDoc(pSceneObject, pPlayer)

	return 0
end

function PalaceAccessDocMenuComponent:showDoc(pDoc, pPlayer)
	local signature = TatooineStationPalaceAccessScreenplay:getDocSignature(pDoc)
	local sui = SuiMessageBox.new("PalaceAccessDocMenuComponent", "readCallback")

	sui.setTitle("@space/quest:palace_access_title")

	if (signature == "") then
		sui.setPrompt("@space/quest:palace_access_text")
	else
		sui.setPrompt(getStringId("@space/quest:palace_access_text") .. "\n Signed: " .. signature .. "\n")
	end

	sui.setOkButtonText("@space/quest:close")
	sui.setCancelButtonText("@space/quest:sign")
	sui.setTargetNetworkId(SceneObject(pDoc):getObjectID())
	sui.sendTo(pPlayer)
end

-- The document a box was opened for: the engine gives the callback no using object for page boxes, so it is read from the page target
function PalaceAccessDocMenuComponent:getBoxDoc(pSui)
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

function PalaceAccessDocMenuComponent:readCallback(pPlayer, pSui, eventIndex)
	if (pPlayer == nil or eventIndex ~= 1) then
		return
	end

	local pDoc = self:getBoxDoc(pSui)

	if (pDoc == nil) then
		return
	end

	local sui = SuiInputBox.new("PalaceAccessDocMenuComponent", "signCallback")

	sui.setTitle("@space/quest:palace_access_sign_title")
	sui.setPrompt("@space/quest:palace_access_sign")
	sui.setTargetNetworkId(SceneObject(pDoc):getObjectID())
	sui.sendTo(pPlayer)
end

function PalaceAccessDocMenuComponent:signCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex ~= 0 or args == nil or string.match(args, "^%s*$") ~= nil) then
		return
	end

	local pDoc = self:getBoxDoc(pSui)

	if (pDoc == nil) then
		return
	end

	TangibleObject(pDoc):setLuaStringData(TatooineStationPalaceAccessScreenplay.SIGNATURE_KEY, args)
	CreatureObject(pPlayer):sendSystemMessage("@space/quest:signed_palace_access")
end
