local Logger = require("utils.logger")
require("utils.helpers")

-- Shared first gates: comm range, then ship type
local function battlefieldEntryGate(pPlayer, pNpc, convoTemplate)
	local pShip = SceneObject(pPlayer):getRootParent()

	if (pShip == nil or not SceneObject(pShip):isShipObject()) then
		return nil, true
	end

	if (not SceneObject(pShip):checkInConversationRange(pNpc)) then
		return convoTemplate:getScreen("out_of_range"), false
	end

	if (BattlefieldEntry:isInCivilianShip(pPlayer)) then
		return convoTemplate:getScreen("civilian_ship"), false
	end

	return nil, false
end

local function cloneWithName(pPlayer, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)
	local pScreenClone = screen:cloneScreen()

	LuaConversationScreen(pScreenClone):setDialogTextTU(CreatureObject(pPlayer):getFirstName())

	return screen:getScreenID(), pScreenClone
end

--[[ Dathomir neutral station: Kessel, or Deep Space for the side of the player's choosing ]]

BattlefieldEntryNeutralConvoHandler = conv_handler:new {}

function BattlefieldEntryNeutralConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local pGate, abort = battlefieldEntryGate(pPlayer, pNpc, convoTemplate)

	if (abort) then
		return
	end

	if (pGate ~= nil) then
		return pGate
	end

	return convoTemplate:getScreen("greeting")
end

function BattlefieldEntryNeutralConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pConvoNpc)
	local pConvoScreen = conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pConvoNpc)

	if (pConvoScreen == nil) then
		return nil
	end

	local screenID = LuaConversationScreen(pConvoScreen):getScreenID()
	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	-- Side choice is refused to pilots or members of the other faction
	if (screenID == "deep_space_imperial" and not BattlefieldEntry:canEnterAsImperial(pPlayer)) then
		return convoTemplate:getScreen("rebels_not_welcome")
	elseif (screenID == "deep_space_rebel" and not BattlefieldEntry:canEnterAsRebel(pPlayer)) then
		return convoTemplate:getScreen("imperials_not_welcome")
	end

	return pConvoScreen
end

function BattlefieldEntryNeutralConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screenID, pScreenClone = cloneWithName(pPlayer, pConvScreen)

	if (screenID == "kessel") then
		BattlefieldEntry:scheduleTravel(pPlayer, "kessel")
	elseif (screenID == "deep_space_imperial") then
		BattlefieldEntry:scheduleTravel(pPlayer, "deep_space_imperial")
	elseif (screenID == "deep_space_rebel") then
		BattlefieldEntry:scheduleTravel(pPlayer, "deep_space_rebel")
	end

	return pScreenClone
end

--[[ Faction entry stations (Dantooine Rebel, Endor Imperial): Deep Space for their own side, or Kessel ]]

local function factionEntryHandler(faction)
	local handler = conv_handler:new {}

	function handler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
		if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
			return
		end

		local convoTemplate = LuaConversationTemplate(pConvTemplate)
		local pGate, abort = battlefieldEntryGate(pPlayer, pNpc, convoTemplate)

		if (abort) then
			return
		end

		if (pGate ~= nil) then
			return pGate
		end

		local isOwnFaction, isEnemyFaction, isEnemyPilot

		if (faction == "imperial") then
			isOwnFaction = TangibleObject(pPlayer):isImperial()
			isEnemyFaction = TangibleObject(pPlayer):isRebel()
			isEnemyPilot = CreatureObject(pPlayer):isRebelPilot()
		else
			isOwnFaction = TangibleObject(pPlayer):isRebel()
			isEnemyFaction = TangibleObject(pPlayer):isImperial()
			isEnemyPilot = CreatureObject(pPlayer):isImperialPilot()
		end

		if (isEnemyFaction) then
			return convoTemplate:getScreen("enemy_greeting")
		end

		if (not isOwnFaction) then
			return convoTemplate:getScreen("neutral_greeting")
		end

		if (isEnemyPilot) then
			return convoTemplate:getScreen("wrong_faction")
		end

		return convoTemplate:getScreen("greeting")
	end

	function handler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
		if (pPlayer == nil or pConvScreen == nil) then
			return
		end

		local screenID, pScreenClone = cloneWithName(pPlayer, pConvScreen)

		if (screenID == "kessel") then
			BattlefieldEntry:scheduleTravel(pPlayer, "kessel")
		elseif (screenID == "deep_space") then
			BattlefieldEntry:scheduleTravel(pPlayer, "deep_space_" .. faction)
		end

		return pScreenClone
	end

	return handler
end

BattlefieldEntryImperialConvoHandler = factionEntryHandler("imperial")
BattlefieldEntryRebelConvoHandler = factionEntryHandler("rebel")
