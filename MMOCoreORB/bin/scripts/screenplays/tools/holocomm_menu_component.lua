-- Holocomm (/object holocomm): 'Dial Trainer' lists the profession trainers. The chosen trainer's hologram
-- appears in front of the player and opens the normal trainer conversation, so skills cost the same as in person.
-- Force Sensitive and Jedi trainers can't be dialed. The hologram leaves when the conversation ends or after HOLOCOMM_TIMEOUT.
HolocommMenuComponent = {}

local HOLOCOMM_TIMEOUT = 120 * 1000
local HOLOCOMM_DISTANCE = 2
local HOLOCOMM_EFFECT = "clienteffect/holoemote_hologlitter.cef"

local holocommTrainers = {
	{ "Architect", "trainer_architect" },
	{ "Armorsmith", "trainer_armorsmith" },
	{ "Artisan", "trainer_artisan" },
	{ "Bio-Engineer", "trainer_bioengineer" },
	{ "Bounty Hunter", "trainer_bountyhunter" },
	{ "Brawler", "trainer_brawler" },
	{ "Carbineer", "trainer_carbine" },
	{ "Chef", "trainer_chef" },
	{ "Combat Medic", "trainer_combatmedic" },
	{ "Commando", "trainer_commando" },
	{ "Creature Handler", "trainer_creaturehandler" },
	{ "Dancer", "trainer_dancer" },
	{ "Doctor", "trainer_doctor" },
	{ "Droid Engineer", "trainer_droidengineer" },
	{ "Entertainer", "trainer_entertainer" },
	{ "Fencer", "trainer_1hsword" },
	{ "Image Designer", "trainer_imagedesigner" },
	{ "Marksman", "trainer_marksman" },
	{ "Medic", "trainer_medic" },
	{ "Merchant", "trainer_merchant" },
	{ "Musician", "trainer_musician" },
	{ "Pikeman", "trainer_polearm" },
	{ "Pistoleer", "trainer_pistol" },
	{ "Politician", "trainer_politician" },
	{ "Ranger", "trainer_ranger" },
	{ "Rifleman", "trainer_rifleman" },
	{ "Scout", "trainer_scout" },
	{ "Shipwright", "trainer_shipwright" },
	{ "Smuggler", "trainer_smuggler" },
	{ "Squad Leader", "trainer_squadleader" },
	{ "Swordsman", "trainer_2hsword" },
	{ "Tailor", "trainer_tailor" },
	{ "Teras Kasi Artist", "trainer_unarmed" },
	{ "Weaponsmith", "trainer_weaponsmith" },
}

function HolocommMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local response = LuaObjectMenuResponse(pMenuResponse)
	response:addRadialMenuItem(20, 3, "Dial Trainer")
end

function HolocommMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pPlayer == nil or pSceneObject == nil or selectedID ~= 20) then
		return 0
	end

	if (not SceneObject(pSceneObject):isASubChildOf(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("The holocomm must be in your inventory to use it.")
		return 0
	end

	if (not HolocommMenuComponent:canDial(pPlayer)) then
		return 0
	end

	local sui = SuiListBox.new("HolocommMenuComponent", "dialTrainerCallback")

	sui.setTargetNetworkId(SceneObject(pSceneObject):getObjectID())
	sui.setTitle("Holocomm")
	sui.setPrompt("Select a trainer to dial.")

	for i = 1, #holocommTrainers, 1 do
		sui.add(holocommTrainers[i][1], "")
	end

	sui.sendTo(pPlayer)

	return 0
end

function HolocommMenuComponent:canDial(pPlayer)
	local player = CreatureObject(pPlayer)

	if (player:isInCombat() or player:isDead() or player:isIncapacitated()) then
		player:sendSystemMessage("You can't use the holocomm right now.")
		return false
	end

	local zoneName = SceneObject(pPlayer):getZoneName()

	if (zoneName == "" or string.find(zoneName, "space") ~= nil) then
		player:sendSystemMessage("The holocomm can't reach a trainer from here.")
		return false
	end

	return true
end

function HolocommMenuComponent:dialTrainerCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1) then
		return
	end

	local trainer = holocommTrainers[tonumber(args) + 1]

	if (trainer == nil or not self:canDial(pPlayer)) then
		return
	end

	self:dismissHologram(pPlayer)

	local player = SceneObject(pPlayer)
	local angle = player:getDirectionAngle()
	local radians = math.rad(angle)
	local x = player:getPositionX() + HOLOCOMM_DISTANCE * math.sin(radians)
	local y = player:getPositionY() + HOLOCOMM_DISTANCE * math.cos(radians)

	local pHologram = spawnMobile(player:getZoneName(), trainer[2], 0, x, player:getPositionZ(), y, (angle + 180) % 360, player:getParentID())

	if (pHologram == nil) then
		CreatureObject(pPlayer):sendSystemMessage("The holocomm couldn't reach the " .. trainer[1] .. " trainer.")
		return
	end

	local hologramID = SceneObject(pHologram):getObjectID()
	writeData(player:getObjectID() .. ":holocomm:hologram", hologramID)

	SceneObject(pHologram):setCustomObjectName(SceneObject(pHologram):getDisplayedName() .. " (hologram)")
	CreatureObject(pHologram):playEffect(HOLOCOMM_EFFECT, "")

	createObserver(STOPCONVERSATION, "HolocommMenuComponent", "onConversationStopped", pHologram)
	createEvent(HOLOCOMM_TIMEOUT, "HolocommMenuComponent", "despawnHologram", pHologram, "")

	AiAgent(pHologram):startConversationWith(pPlayer)
end

-- One hologram per player: dialing again replaces the last one
function HolocommMenuComponent:dismissHologram(pPlayer)
	local key = SceneObject(pPlayer):getObjectID() .. ":holocomm:hologram"
	local hologramID = readData(key)

	deleteData(key)

	if (hologramID == nil or hologramID == 0) then
		return
	end

	local pHologram = getSceneObject(hologramID)

	if (pHologram ~= nil) then
		self:despawnHologram(pHologram)
	end
end

function HolocommMenuComponent:onConversationStopped(pHologram, pPlayer)
	if (pHologram ~= nil) then
		createEvent(1000, "HolocommMenuComponent", "despawnHologram", pHologram, "")
	end

	return 1
end

function HolocommMenuComponent:despawnHologram(pHologram)
	if (pHologram == nil or SceneObject(pHologram):getZoneName() == "") then
		return
	end

	CreatureObject(pHologram):playEffect(HOLOCOMM_EFFECT, "")
	SceneObject(pHologram):destroyObjectFromWorld()
end
