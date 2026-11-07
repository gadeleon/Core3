-- Fake game objects and fake C++ Lua wrapper types (LuaCreatureObject, LuaPlayerObject,
-- LuaConversationTemplate, ...).
--
-- In the server, a "pointer" (pPlayer, pNpc, pConvTemplate) is light userdata, and wrappers such
-- as CreatureObject(pPlayer) (defined in Lua by managers/object/object_manager.lua) call
-- LuaCreatureObject:_setObject(p) and then forward methods to C++. Here a pointer is a fake
-- object table, and every wrapper forwards method calls to that table. A missing method fails
-- loudly with a message saying where to add it.

local Fakes = {}

local registry = {} -- objectID -> fake
local nextObjectID = 1000

-- Backing store for the engine's getQuestStatus/setQuestStatus/removeQuestStatus (key -> string).
Fakes.questStatus = {}

-- Current fake time in ms; engine.lua replaces this with its event clock.
Fakes.now = function() return 0 end

-- Called by Fakes.destroy so the engine can drop observers registered on the object.
Fakes.destroyHook = function(obj) end

function Fakes.reset()
	registry = {}
	nextObjectID = 1000
	Fakes.questStatus = {}
end

-- destroyObjectFromWorld: the object leaves the registry (getSceneObject(id) returns nil afterwards)
-- and is flagged `destroyed` so tests can assert on it. Idempotent.
function Fakes.destroy(obj)
	if obj.destroyed then
		return
	end

	obj.destroyed = true
	registry[obj.objectID] = nil
	Fakes.destroyHook(obj)
end

function Fakes.lookup(objectID)
	return registry[objectID]
end

local function register(obj)
	nextObjectID = nextObjectID + 1
	obj.objectID = obj.objectID or nextObjectID
	registry[obj.objectID] = obj
	return obj
end

-- Journal quest key exactly as SpaceHelpers builds it: getHashCode("spacequest/<type>/<name>").
function Fakes.questCrc(questType, questName)
	return getHashCode("spacequest/" .. questType .. "/" .. questName)
end

local function set(list)
	local s = {}

	for _, v in ipairs(list or {}) do
		s[v] = true
	end

	return s
end

---------------------------------------------------------------------------------------------
-- Fake player ghost (PlayerObject)
---------------------------------------------------------------------------------------------

local FakeGhost = { __kind = "PlayerObject" }
FakeGhost.__index = FakeGhost

-- opts.activeQuests / opts.completedQuests: lists of journal quest CRCs. Build them with
-- Fakes.questCrc(type, name), which mirrors SpaceHelpers' "spacequest/<type>/<name>" key.
function Fakes.newGhost(opts)
	opts = opts or {}

	local g = setmetatable({
		journalActive = set(opts.activeQuests),
		journalComplete = set(opts.completedQuests),
		squadronType = opts.squadronType or 0,
		experience = opts.experience or {},
		pilotTier = opts.pilotTier or 0,
		factionStanding = {},
		waypoints = {},         -- live waypoints (fake waypoint objects), oldest first
		removedWaypoints = {},  -- waypoints removed through removeWaypoint
		taskActive = {},        -- quest crc -> { [taskNumber] = true }
		taskComplete = {},
	}, FakeGhost)

	for faction, standing in pairs(opts.factionStanding or {}) do
		g.factionStanding[faction] = standing
	end

	return register(g)
end

function FakeGhost:getObjectID() return self.objectID end
function FakeGhost:isJournalQuestActive(crc) return self.journalActive[crc] == true end
function FakeGhost:isJournalQuestComplete(crc) return self.journalComplete[crc] == true end
-- Like PlayerObjectImplementation::activateJournalQuest: an entry that already has an owner
-- (active or completed) is left alone, so a completed entry stays completed until cleared.
-- A new entry also makes task 0 active with no completed tasks (PlayerObjectImplementation.cpp:3202-3209).
function FakeGhost:activateJournalQuest(crc, notify)
	if self.journalComplete[crc] then
		return
	end

	if not self.journalActive[crc] then
		self.taskActive[crc] = { [0] = true }
		self.taskComplete[crc] = {}
	end

	self.journalActive[crc] = true
end
-- Like PlayerObjectImplementation::completeJournalQuest (PlayerObjectImplementation.cpp:3212-3217): an entry that
-- was never activated has no owner, so completing it does nothing. A completed entry can only be written as
-- activate, then complete.
function FakeGhost:completeJournalQuest(crc, notify)
	if not self.journalActive[crc] and not self.journalComplete[crc] then
		return
	end

	self.journalActive[crc] = nil
	self.journalComplete[crc] = true
end
function FakeGhost:clearJournalQuest(crc, notify)
	self.journalActive[crc] = nil
	self.journalComplete[crc] = nil
	self.taskActive[crc] = nil
	self.taskComplete[crc] = nil
end

-- Journal tasks. Completing a task moves it from active to complete, like the server.
function FakeGhost:activateJournalQuestTask(crc, task, notify)
	self.taskActive[crc] = self.taskActive[crc] or {}
	self.taskActive[crc][task] = true
end

-- Like PlayerObjectImplementation::completeJournalQuestTask (:3299-3301): only an entry with an owner and an active task
-- is completed; anything else does nothing.
function FakeGhost:completeJournalQuestTask(crc, task, notify)
	if not self.journalActive[crc] and not self.journalComplete[crc] then
		return
	end

	if not (self.taskActive[crc] and self.taskActive[crc][task]) then
		return
	end

	self.taskActive[crc][task] = nil

	self.taskComplete[crc] = self.taskComplete[crc] or {}
	self.taskComplete[crc][task] = true
end

function FakeGhost:clearJournalQuestTask(crc, task, notify)
	if self.taskActive[crc] then
		self.taskActive[crc][task] = nil
	end

	if self.taskComplete[crc] then
		self.taskComplete[crc][task] = nil
	end
end

function FakeGhost:isJournalQuestTaskActive(crc, task) return self.taskActive[crc] ~= nil and self.taskActive[crc][task] == true end
function FakeGhost:isJournalQuestTaskComplete(crc, task) return self.taskComplete[crc] ~= nil and self.taskComplete[crc][task] == true end
function FakeGhost:isSquadronType(t) return self.squadronType == t end
function FakeGhost:setSquadronType(t) self.squadronType = t end
function FakeGhost:getSquadronType() return self.squadronType end
function FakeGhost:getExperience(xpType) return self.experience[xpType] or 0 end
function FakeGhost:getPilotTier() return self.pilotTier end
function FakeGhost:incrementPilotTier() self.pilotTier = self.pilotTier + 1 end
-- LuaPlayerObject::setPilotTier / resetPilotTier (the trainer reset functions call them; space-quest-inspect-cargo).
function FakeGhost:setPilotTier(tier) self.pilotTier = tier end
function FakeGhost:resetPilotTier() self.pilotTier = 0 end
function FakeGhost:getFactionStanding(faction) return self.factionStanding[faction] or 0 end
function FakeGhost:increaseFactionStanding(faction, amount) self.factionStanding[faction] = (self.factionStanding[faction] or 0) + amount end
function FakeGhost:decreaseFactionStanding(faction, amount) self.factionStanding[faction] = (self.factionStanding[faction] or 0) - amount end
function FakeGhost:setFactionStanding(faction, amount) self.factionStanding[faction] = amount end

-- addWaypoint(planet, name, desc, x, z, y, color, active, notify, special[, persistent]), the order
-- of LuaPlayerObject::addWaypoint (z is the height). The C++ binding returns nothing unless it gets
-- 10 or 11 arguments, so the fake errors instead. Returns the new waypoint's object id.
function FakeGhost:addWaypoint(...)
	local n = select("#", ...)

	if n ~= 10 and n ~= 11 then
		error("harness: addWaypoint takes 10 or 11 arguments (planet, name, desc, x, z, y, color, active, notify, special[, persistent]); got " .. n, 2)
	end

	local planet, name, desc, x, z, y, color, active, notify, special, persistent = ...
	local wp = Fakes.newWaypoint({ planet = planet, name = name, desc = desc, x = x, z = z, y = y, color = color,
		active = active, notify = notify, special = special, persistent = persistent })

	self.waypoints[#self.waypoints + 1] = wp
	return wp.objectID
end

function FakeGhost:removeWaypoint(waypointID, notify)
	for i, wp in ipairs(self.waypoints) do
		if wp.objectID == waypointID then
			table.remove(self.waypoints, i)
			self.removedWaypoints[#self.removedWaypoints + 1] = wp
			Fakes.destroy(wp)
			return
		end
	end
end

---------------------------------------------------------------------------------------------
-- Fake creature (player character or NPC)
---------------------------------------------------------------------------------------------

local FakeCreature = { __kind = "CreatureObject" }
FakeCreature.__index = FakeCreature

-- opts: name, skills (list), faction (crc/int), pilot ("neutral"|"rebel"|"imperial"|nil),
-- certifiedShip (bool), screenPlayStates (table name->state), ghost (fake ghost; created if nil
-- unless isNpc), isNpc (bool).
-- Ghost opts (passed through): squadronType, experience ({space_combat_general = n}), activeQuests,
-- completedQuests, pilotTier (number, default 0), factionStanding ({rebel = n}).
-- questStatus: { ["<suffix>"] = value } stored as getQuestStatus("<objectID><suffix>"), the key
-- shape the Havoc/CorSec handlers use (player object id first).
-- species: number returned by getSpecies (default 0 = human; use SPECIES_ITHORIAN, SPECIES_WOOKIEE, ...).
-- inventory: true gives the player an inventory container (getSlottedObject("inventory")); without it `SpaceHelpers:spaceItemReward`
-- returns early and giveItem is never called (space-trainer-rewards). Items given land in `player.inventory.items`.
-- inventory = { limit = n } or inventoryFull = true (limit 0): the inventory is full once it holds `limit` items; giveItem without the overload
-- argument then gives nothing (nil) and lists the template in `player.inventory.destroyed` (space-mission4-reward-fixes).
-- parent: true or a name; the player stands in a fake building (root parent, not a ship).
-- zone: name returned by getZoneName (default ""). ship: true or a Fakes.newShip option table; the
-- player then sits in a fake player ship (getRootParent returns it, the ship's getPilot returns the
-- player). Without a ship the player has no root parent, which SpaceHelpers:isInYacht treats as
-- "not in a flyable ship".
function Fakes.newCreature(opts)
	opts = opts or {}

	local c = setmetatable({
		name = opts.name or "Tester",
		skills = set(opts.skills),
		faction = opts.faction or 0,
		pilot = opts.pilot,
		gender = opts.gender, -- 0 = male (default), 1 = female; read by getGender
		certifiedShip = opts.certifiedShip ~= false,
		screenPlayStates = opts.screenPlayStates or {},
		messages = {},
		music = {},
		isNpc = opts.isNpc or false,
		conversationSession = nil,
		zone = opts.zone or "",
		x = opts.x, z = opts.z, y = opts.y, -- position (getPositionX/Z/Y, getWorldPosition*); a creature in a ship reports the ship's
		parentID = opts.parentID,          -- getParentID (the cell id; nil reads 0)
		messageLog = {},     -- { t = ms, msg = string or fake StringIdChatParameter }
		tauntLog = {},       -- { t = ms, msg, ship } from ShipAiAgent:tauntPlayer
		effects = {},        -- { t = ms, file = string } from playEffect
		missionObjects = {}, -- ids from addSpaceMissionObject, oldest first
		missionObjectLog = {}, -- { id, last } per addSpaceMissionObject call
		removedMissionObjects = {},
		removedMissionObjectLog = {}, -- { id, notify } per removeSpaceMissionObject call
		bankCreditLog = {},  -- { t = ms, amount, notify } per addBankCredits call
		bankCredits = 0,     -- sum of addBankCredits amounts
		failedMissions = {}, -- quest crcs given to failQuestMission, in order
		datapad = nil,
		species = opts.species, -- read by getSpecies (default 0 = human); SPECIES_* values
		inventory = nil,        -- opt-in (opts.inventory): the container getSlottedObject("inventory") returns
	}, FakeCreature)

	if not c.isNpc then
		c.ghost = opts.ghost or Fakes.newGhost(opts)
		c.datapad = Fakes.newContainer({ objectName = "datapad" })

		if opts.inventory or opts.inventoryFull then
			c.inventory = Fakes.newContainer({ objectName = "inventory" })

			if type(opts.inventory) == "table" and opts.inventory.limit ~= nil then
				c.inventory.limit = opts.inventory.limit
			end

			if opts.inventoryFull then
				c.inventory.limit = 0
			end
		end
	end

	register(c)

	if opts.parent then
		-- Standing inside a building (a starport): the root parent is not a ship.
		c.rootParent = Fakes.newContainer({ objectName = type(opts.parent) == "string" and opts.parent or "starport" })
	end

	if opts.ship then
		local shipOpts = type(opts.ship) == "table" and opts.ship or {}
		shipOpts.pilot = c
		shipOpts.zone = shipOpts.zone or c.zone
		c.rootParent = Fakes.newShip(shipOpts)
	end

	for suffix, value in pairs(opts.questStatus or {}) do
		Fakes.questStatus[c.objectID .. suffix] = tostring(value)
	end

	return c
end

function Fakes.newPlayer(opts) return Fakes.newCreature(opts) end

function Fakes.newNpc(opts)
	opts = opts or {}
	opts.isNpc = true
	return Fakes.newCreature(opts)
end

function FakeCreature:getObjectID() return self.objectID end
function FakeCreature:getFirstName() return self.name end
function FakeCreature:getDisplayedName() return self.name end
-- SceneObject::getObjectName on an NPC (SpaceHelpers:activateSpaceQuest reads it for the mission creator name).
function FakeCreature:getObjectName() return self.objectName or self.name end
function FakeCreature:getPlayerObject() return self.ghost end
-- LuaCreatureObject::doAnimation (trainer handlers play emotes); every call is recorded in order.
function FakeCreature:doAnimation(animation)
	self.animations = self.animations or {}
	self.animations[#self.animations + 1] = animation
end
-- LuaCreatureObject::getGender (0 = male); set opts.gender / creature.gender to change it.
function FakeCreature:getGender() return self.gender or 0 end
function FakeCreature:isPlayerCreature() return not self.isNpc end
function FakeCreature:hasSkill(skill) return self.skills[skill] == true end
-- LuaCreatureObject::surrenderSkill (SpaceHelpers:surrenderPilot): the player loses the skill.
function FakeCreature:surrenderSkill(skill) self.skills[skill] = nil end
function FakeCreature:getFaction() return self.faction end
function FakeCreature:getSpecies() return self.species or 0 end
function FakeCreature:isNeutralPilot() return self.pilot == "neutral" end
function FakeCreature:isRebelPilot() return self.pilot == "rebel" end
function FakeCreature:isImperialPilot() return self.pilot == "imperial" end
function FakeCreature:hasCertifiedShip(...) return self.certifiedShip end
function FakeCreature:playMusicMessage(file) self.music[#self.music + 1] = file end
function FakeCreature:getConversationSession() return self.conversationSession end
function FakeCreature:getScreenPlayState(screenplay) return self.screenPlayStates[screenplay] or 0 end

function FakeCreature:setScreenPlayState(state, screenplay)
	self.screenPlayStates[screenplay] = (self.screenPlayStates[screenplay] or 0) | state
end

function FakeCreature:removeScreenPlayState(state, screenplay)
	self.screenPlayStates[screenplay] = (self.screenPlayStates[screenplay] or 0) & ~state
end

-- Accepts a plain string or a fake StringIdChatParameter (from LuaStringIdChatParameter:_getObject()).
function FakeCreature:sendSystemMessage(msg)
	self.messages[#self.messages + 1] = msg
	self.messageLog[#self.messageLog + 1] = { t = Fakes.now(), msg = msg }
end

function FakeCreature:getZoneName() return self.zone end
function FakeCreature:getRootParent() return self.rootParent end
function FakeCreature:isShipObject() return false end
function FakeCreature:isShipAiAgent() return false end
function FakeCreature:isPlayerShip() return false end
function FakeCreature:isActiveArea() return false end
function FakeCreature:isMissionObject() return false end
function FakeCreature:getSlottedObject(slot)
	if slot == "datapad" then
		return self.datapad
	elseif slot == "inventory" then
		return self.inventory -- nil unless the player was built with `inventory = true`
	end
end

-- A player inside a ship reports the ship's position, like the server's world position.
function FakeCreature:getWorldPositionX() return self.rootParent and self.rootParent.x or self.x or 0 end
function FakeCreature:getWorldPositionZ() return self.rootParent and self.rootParent.z or self.z or 0 end
function FakeCreature:getWorldPositionY() return self.rootParent and self.rootParent.y or self.y or 0 end
-- SceneObject::getPositionX/Z/Y and getParentID of an NPC (opts.x, opts.z, opts.y, opts.parentID of H.newNpc; vortex-tier1-v3-fx, the droid's sparks)
function FakeCreature:getPositionX() return self.x or 0 end
function FakeCreature:getPositionZ() return self.z or 0 end
function FakeCreature:getPositionY() return self.y or 0 end
function FakeCreature:getParentID() return self.parentID or 0 end

function FakeCreature:playEffect(file, arg)
	self.effects[#self.effects + 1] = { t = Fakes.now(), file = file, arg = arg }
end

function FakeCreature:addSpaceMissionObject(id, last)
	self.missionObjects[#self.missionObjects + 1] = id
	self.missionObjectLog[#self.missionObjectLog + 1] = { id = id, last = last }
end

function FakeCreature:removeSpaceMissionObject(id, notify)
	for i, v in ipairs(self.missionObjects) do
		if v == id then
			table.remove(self.missionObjects, i)
			break
		end
	end

	self.removedMissionObjects[#self.removedMissionObjects + 1] = id
	self.removedMissionObjectLog[#self.removedMissionObjectLog + 1] = { id = id, notify = notify }
end

-- Datapad mission bookkeeping (SpaceHelpers:completeSpaceQuest / failSpaceQuest).
-- Both remove the first datapad mission whose quest CRC matches (a mission built without a
-- quest type/name has no CRC and never matches).
-- skipAborted: LuaCreatureObject::failQuestMission ignores missions that have isAborted() set
-- (LuaCreatureObject.cpp:1514); removeQuestMission does not (space-quest-abort-cleanup).
local function removeDatapadMission(creature, crc, skipAborted)
	local items = creature.datapad and creature.datapad.items or {}

	for i, item in ipairs(items) do
		if item.getQuestCRC and item:getQuestCRC() == crc and not (skipAborted and item.isAborted and item:isAborted()) then
			table.remove(items, i)
			return true
		end
	end

	return false
end

function FakeCreature:removeQuestMission(crc)
	removeDatapadMission(self, crc)
end

function FakeCreature:failQuestMission(crc)
	self.failedMissions[#self.failedMissions + 1] = crc
	removeDatapadMission(self, crc, true)
end

-- Bank credits (LuaCreatureObject::addBankCredits): every call is recorded in order.
function FakeCreature:addBankCredits(amount, notify)
	self.bankCreditLog[#self.bankCreditLog + 1] = { t = Fakes.now(), amount = amount, notify = notify }
	self.bankCredits = self.bankCredits + amount
end

---------------------------------------------------------------------------------------------
-- Space objects: ships, ship agents (AI ships), active areas, waypoints, datapad and missions.
-- All of them answer the SceneObject methods production Lua may call on any object, because the
-- wrappers forward every method to the fake regardless of wrapper type.
---------------------------------------------------------------------------------------------

local function sceneMethods(class)
	function class:getObjectID() return self.objectID end
	function class:getDisplayedName() return self.name or self.__kind end
	function class:getObjectName() return self.objectName end
	function class:getZoneName() return self.zone or "" end
	function class:getRootParent() return nil end
	function class:isPlayerCreature() return false end
	function class:isShipObject() return false end
	function class:isShipAiAgent() return false end
	function class:isPlayerShip() return false end
	function class:isActiveArea() return false end
	function class:isMissionObject() return false end
	function class:getWorldPositionX() return self.x or 0 end
	function class:getWorldPositionZ() return self.z or 0 end
	function class:getWorldPositionY() return self.y or 0 end
	function class:getPositionX() return self.x or 0 end
	function class:getPositionZ() return self.z or 0 end
	function class:getPositionY() return self.y or 0 end
	function class:destroyObjectFromWorld() Fakes.destroy(self) end

	-- LuaSceneObject::getDistanceTo3d (rsf-tier1-dinge-data: SpaceEscortScreenplay:checkEscort). A creature in a ship counts at its ship's position.
	function class:getDistanceTo3d(other)
		local from, to = self.rootParent or self, other.rootParent or other
		local dx, dz, dy = (from.x or 0) - (to.x or 0), (from.z or 0) - (to.z or 0), (from.y or 0) - (to.y or 0)

		return math.sqrt(dx * dx + dz * dz + dy * dy)
	end
end

-- Ship (player ship or AI ship). opts: pilot (fake creature), objectName (default "player_ship";
-- the yacht is "player_sorosuub_space_yacht"), zone, x, z, y, playerShip (default true),
-- factionHash (default getHashCode("rebel")).
-- Position is plain fields (x, z, y), set with ship:setPosition(x, z, y) or by assignment.
-- getSpawnPointInFrontOfShip(min, max) is deterministic: { x + min, z + 7, y + max }. Each call is
-- recorded in ship.spawnPointCalls as { min, max }.
local FakeShip = { __kind = "ShipObject" }
FakeShip.__index = FakeShip
sceneMethods(FakeShip)

function Fakes.newShip(opts)
	opts = opts or {}

	local s = setmetatable({
		pilot = opts.pilot,
		objectName = opts.objectName or "player_ship",
		zone = opts.zone or "",
		x = opts.x or 0, z = opts.z or 0, y = opts.y or 0,
		playerShip = opts.playerShip ~= false,
		factionHash = opts.factionHash or getHashCode("rebel"),
		hyperspacing = false,
		spawnPointCalls = {},
	}, FakeShip)

	return register(s)
end

function FakeShip:isShipObject() return true end
function FakeShip:isPlayerShip() return self.playerShip end
function FakeShip:getPilot() return self.pilot end
function FakeShip:getPilotID() return self.pilot and self.pilot.objectID or 0 end
function FakeShip:getShipFactionHash() return self.factionHash end
function FakeShip:setHyperspacing(b) self.hyperspacing = b end
-- LuaShipObject::getShipFactionString (SpaceHelpers:getPlayerShipFactionString); defaults to "rebel"
function FakeShip:getShipFactionString() return self.shipFactionString or "rebel" end

function FakeShip:setPosition(x, z, y) self.x, self.z, self.y = x, z, y end

function FakeShip:getSpawnPointInFrontOfShip(min, max)
	self.spawnPointCalls[#self.spawnPointCalls + 1] = { min, max }
	return { self.x + min, self.z + 7, self.y + max }
end

function FakeShip:getSpawnPointBehindShip(min, max)
	self.spawnPointCalls[#self.spawnPointCalls + 1] = { -min, -max }
	return { self.x - min, self.z + 7, self.y - max }
end

-- AI ship agent returned by spawnShipAgent. Extra opts: shipName, zone, x, z, y, cargo (the cargoString).
local FakeAgent = setmetatable({ __kind = "ShipAiAgent" }, { __index = FakeShip })
FakeAgent.__index = FakeAgent

function Fakes.newShipAgent(opts)
	opts = opts or {}

	local a = setmetatable({
		shipName = opts.shipName,
		name = opts.shipName,
		objectName = opts.shipName,
		zone = opts.zone or "",
		x = opts.x or 0, z = opts.z or 0, y = opts.y or 0,
		playerShip = false,
		factionHash = 0,
		hyperspacing = false,
		spawnPointCalls = {},
		factionEnemies = {},   -- hashes from addSpaceFactionEnemy
		engaged = {},          -- ships from engageShipTarget
		engageLog = {},        -- { t, target } per engageShipTarget call (space-quest-stub-space-battle)
		isSquadronLeader = false,
		squadronLeader = nil,  -- pointer given to assignToSquadron
		missionOwner = nil,
		dockable = false,      -- setDockable / isDockable
		dockableCalls = {},    -- every value given to setDockable, in order
		factionAllies = {},    -- hashes from addSpaceFactionAlly
		removedFactionEnemies = {}, -- hashes from removeSpaceFactionEnemy
		taunts = {},           -- { t, player, msg } from tauntPlayer
		callLog = {},          -- ordered { name, args = table.pack(...) } of setDockable, repairShipAgent, setFixedPatrol,
		                       -- setEscort, setEscortSpeed, assignFixedPatrolPointsTable (space-quest-rescue-docking)
		repairs = {},          -- values given to repairShipAgent
		fixedPatrolCalls = 0,  -- setFixedPatrol() calls
		escortCalls = 0,       -- setEscort() calls
		escortSpeeds = {},     -- values given to setEscortSpeed
		patrolPointTables = {},-- copies of the tables given to assignFixedPatrolPointsTable
		cargo = opts.cargo or "", -- the ship's cargoString (setCargoString writes it; space-quest-inspect-cargo)
		cargoStringCalls = {}, -- every string given to setCargoString, in order
	}, FakeAgent)

	return register(a)
end

function FakeAgent:setMissionOwner(pPlayer) self.missionOwner = pPlayer end
function FakeAgent:getMissionOwnerID() return self.missionOwner and self.missionOwner.objectID or 0 end
function FakeAgent:addSpaceFactionEnemy(hash) self.factionEnemies[#self.factionEnemies + 1] = hash end
-- LuaShipAiAgent::engageShipTarget (LuaShipAiAgent.cpp:388-418) needs exactly one argument, a ship object;
-- otherwise the server logs an error and ignores the call, so the fake raises. Every call is appended to
-- `engaged` (ships, oldest first) and to `engageLog` ({ t = ms, target = ship }), space-quest-stub-space-battle.
function FakeAgent:engageShipTarget(...)
	if select("#", ...) ~= 1 then
		error("engageShipTarget: exactly 1 argument (a ship object)", 2)
	end

	local pShip = ...

	if type(pShip) ~= "table" or type(pShip.isShipObject) ~= "function" or not pShip:isShipObject() then
		error("engageShipTarget: exactly 1 argument (a ship object)", 2)
	end

	self.engaged[#self.engaged + 1] = pShip
	self.engageLog[#self.engageLog + 1] = { t = Fakes.now(), target = pShip }
end
function FakeAgent:createSquadron(formation) self.isSquadronLeader = true end
function FakeAgent:assignToSquadron(pLeader) self.squadronLeader = pLeader end
-- LuaShipAiAgent::setDockable / isDockable (space-docking-permission). test_harness_ship_dockable.lua
-- checks that both names exist in LuaShipAiAgent.cpp's Methods table.
function FakeAgent:setDockable(b)
	self.dockable = b and true or false
	self.dockableCalls[#self.dockableCalls + 1] = self.dockable
	self.callLog[#self.callLog + 1] = { name = "setDockable", args = table.pack(b) }
end
function FakeAgent:isShipAiAgent() return true end
-- LuaShipObject::isShipDestroyed / isShipDisabled (rsf-tier3-mission1-2-data: SpaceRecoveryScreenplay:continueRecovery
-- and assignRecoveryPoints ask). A destroyed agent is the harness's `destroyed` flag; `disabled` is set by a test.
function FakeAgent:isShipDestroyed() return self.destroyed == true end
function FakeAgent:isShipDisabled() return self.disabled == true end
-- continueRecovery turns the captured ship friendly: LuaShipAiAgent::swapSpaceFactionAssociations / removeEnemyShip and
-- LuaTangibleObject::clearPvpStatusBit / broadcastPvpStatusBitmask. Recorded as counts / values, nothing else simulated.
function FakeAgent:swapSpaceFactionAssociations() self.factionSwaps = (self.factionSwaps or 0) + 1 end
function FakeAgent:removeEnemyShip(shipID)
	self.removedEnemyShips = self.removedEnemyShips or {}
	self.removedEnemyShips[#self.removedEnemyShips + 1] = shipID
end
function FakeAgent:clearPvpStatusBit(bit)
	self.clearedPvpBits = self.clearedPvpBits or {}
	self.clearedPvpBits[#self.clearedPvpBits + 1] = bit
end
function FakeAgent:broadcastPvpStatusBitmask() self.pvpBroadcasts = (self.pvpBroadcasts or 0) + 1 end

-- LuaShipAiAgent::setFixedPatrol / setEscort / setEscortSpeed / repairShipAgent /
-- assignFixedPatrolPointsTable (space-quest-rescue-docking). Each is recorded in agent.callLog in call
-- order. The C++ bindings refuse a wrong argument count (log an error and do nothing), so the fakes
-- raise instead: setEscortSpeed, repairShipAgent and assignFixedPatrolPointsTable take exactly 1
-- argument (LuaShipAiAgent.cpp: `lua_gettop(L) - 1 != 1`); the last one takes a table of patrol point
-- names, not point tables and not a second argument.
local function exactlyOne(name, ...)
	local n = select("#", ...)

	if n ~= 1 then
		error("harness: LuaShipAiAgent::" .. name .. " takes exactly 1 argument (the binding logs 'Improper number of arguments' and does nothing); got " .. n, 3)
	end
end

function FakeAgent:setFixedPatrol()
	self.fixedPatrolCalls = self.fixedPatrolCalls + 1
	self.callLog[#self.callLog + 1] = { name = "setFixedPatrol", args = table.pack() }
end

function FakeAgent:setEscort()
	self.escortCalls = self.escortCalls + 1
	self.callLog[#self.callLog + 1] = { name = "setEscort", args = table.pack() }
end

function FakeAgent:setEscortSpeed(...)
	exactlyOne("setEscortSpeed", ...)
	local speed = ...
	self.escortSpeeds[#self.escortSpeeds + 1] = speed
	self.callLog[#self.callLog + 1] = { name = "setEscortSpeed", args = table.pack(...) }
end

function FakeAgent:repairShipAgent(...)
	exactlyOne("repairShipAgent", ...)
	local amount = ...
	self.repairs[#self.repairs + 1] = amount
	self.callLog[#self.callLog + 1] = { name = "repairShipAgent", args = table.pack(...) }
end

function FakeAgent:assignFixedPatrolPointsTable(...)
	exactlyOne("assignFixedPatrolPointsTable", ...)
	local names = ...

	if type(names) ~= "table" then
		error("harness: LuaShipAiAgent::assignFixedPatrolPointsTable takes a table of patrol point names; got " .. type(names), 2)
	end

	local copy = {}

	for i, v in ipairs(names) do
		if type(v) ~= "string" then
			error("harness: assignFixedPatrolPointsTable table entry " .. i .. " must be a patrol point name (string); got " .. type(v), 2)
		end

		copy[i] = v
	end

	self.patrolPointTables[#self.patrolPointTables + 1] = copy
	self.callLog[#self.callLog + 1] = { name = "assignFixedPatrolPointsTable", args = table.pack(...) }
end
function FakeAgent:isDockable() return self.dockable end

-- LuaShipAiAgent::getShipAgentTemplateName (space-quest-inspect-cargo): the ship_mobile template name the
-- agent was spawned from (the fake's shipName). Only AI agents have it, a player ship does not.
function FakeAgent:getShipAgentTemplateName() return self.shipName end

-- LuaShipObject::setCargoString (space-quest-inspect-cargo): the binding refuses anything but exactly one
-- argument (it logs 'Improper number of arguments' and does nothing), so the fake raises instead. There is
-- NO getCargoString binding in LuaShipObject.cpp: tests read agent.cargo, production Lua cannot read it.
function FakeAgent:setCargoString(...)
	local n = select("#", ...)

	if n ~= 1 then
		error("harness: LuaShipObject::setCargoString takes exactly 1 argument (the binding logs 'Improper number of arguments' and does nothing); got " .. n, 2)
	end

	local s = ...

	if type(s) ~= "string" then
		error("harness: LuaShipObject::setCargoString takes a string; got " .. type(s), 2)
	end

	self.cargo = s
	self.cargoStringCalls[#self.cargoStringCalls + 1] = s
end
-- LuaShipAiAgent::addSpaceFactionAlly / removeSpaceFactionEnemy / tauntPlayer (space-quest-stub-delivery).
-- tauntPlayer is recorded on the agent and on the taunted player (player.tauntLog, see H.tauntLog).
function FakeAgent:addSpaceFactionAlly(hash) self.factionAllies[#self.factionAllies + 1] = hash end
function FakeAgent:removeSpaceFactionEnemy(hash) self.removedFactionEnemies[#self.removedFactionEnemies + 1] = hash end

function FakeAgent:tauntPlayer(pPlayer, msg)
	local entry = { t = Fakes.now(), player = pPlayer, msg = msg, ship = self }

	self.taunts[#self.taunts + 1] = entry

	if pPlayer ~= nil and pPlayer.tauntLog ~= nil then
		pPlayer.tauntLog[#pPlayer.tauntLog + 1] = entry
	end
end

-- Setters the surprise attack, escort and assassinate spawns call (space-quest-abort-cleanup drives those types
-- for the first time). They only record; test_harness_abort_fakes.lua checks the names against the bindings.
function FakeAgent:setMinimumGuardPatrol(v) self.minimumGuardPatrol = v end
function FakeAgent:setMaximumGuardPatrol(v) self.maximumGuardPatrol = v end
function FakeAgent:setGuardPatrol() self.guardPatrol = true end
function FakeAgent:setDespawnOnNoPlayerInRange(b) self.despawnOnNoPlayerInRange = b end
function FakeAgent:setShipFactionString(s) self.shipFactionString = s end

-- LuaShipAiAgent::setWaveAttack / removeSpaceFactionAlly (rsf-tier1-dinge-data: the escort attack wave runs for the first time).
-- They only record; test_rsf_tier1_dinge_harness_fakes.lua checks the names against the bindings.
function FakeAgent:setWaveAttack() self.waveAttack = true end
function FakeAgent:removeSpaceFactionAlly(hash)
	self.removedFactionAllies = self.removedFactionAllies or {}
	self.removedFactionAllies[#self.removedFactionAllies + 1] = hash
end

function FakeAgent:dropFromSquadron() self.squadronLeader = nil; self.isSquadronLeader = false end

-- Active area returned by spawnSpaceActiveArea.
local FakeArea = { __kind = "ActiveArea" }
FakeArea.__index = FakeArea
sceneMethods(FakeArea)

function Fakes.newActiveArea(opts)
	opts = opts or {}

	return register(setmetatable({
		zone = opts.zone, template = opts.template,
		x = opts.x or 0, z = opts.z or 0, y = opts.y or 0, radius = opts.radius,
	}, FakeArea))
end

function FakeArea:isActiveArea() return true end

-- Waypoint object (fields planet, name, desc, x, z, y, color, active, notify, special, persistent).
local FakeWaypoint = { __kind = "WaypointObject" }
FakeWaypoint.__index = FakeWaypoint
sceneMethods(FakeWaypoint)

function Fakes.newWaypoint(opts)
	return register(setmetatable(opts or {}, FakeWaypoint))
end

function FakeWaypoint:setQuestDetails(details) self.questDetails = details end

-- Container (datapad) and mission objects created by giveItem.
local FakeContainer = { __kind = "Container" }
FakeContainer.__index = FakeContainer
sceneMethods(FakeContainer)

function Fakes.newContainer(opts)
	opts = opts or {}
	return register(setmetatable({ objectName = opts.objectName, items = {} }, FakeContainer))
end

function FakeContainer:getContainerObjectsSize() return #self.items end
function FakeContainer:getContainerObject(i) return self.items[i + 1] end
-- SceneObject::isContainerFullRecursive (storm-tier1-akal-colzet): full once the container holds `limit` items, answering from the same
-- `limit` / `inventoryFull` options giveItem uses; a container without a limit is never full.
function FakeContainer:isContainerFullRecursive() return self.limit ~= nil and #self.items >= self.limit end

local FakeMission = { __kind = "MissionObject" }
FakeMission.__index = FakeMission
sceneMethods(FakeMission)

function Fakes.newMission()
	return register(setmetatable({ spaceDuty = false, aborted = false }, FakeMission))
end

function FakeMission:isMissionObject() return true end
function FakeMission:isSpaceDutyMission() return self.spaceDuty end
-- MissionObject::abort / isAborted (space-quest-abort-cleanup): the datapad abort marks the mission first.
function FakeMission:abort() self.aborted = true end
function FakeMission:isAborted() return self.aborted end
function FakeMission:getQuestCRC()
	if self.questType and self.questName then
		return Fakes.questCrc(self.questType, self.questName)
	end
end
function FakeMission:setTypeCRC(crc) self.typeCRC = crc end
function FakeMission:setQuestType(t) self.questType = t end
function FakeMission:setQuestName(n) self.questName = n end
function FakeMission:setMissionTitle(file, key) self.title = { file, key } end
function FakeMission:setMissionDescription(file, key) self.description = { file, key } end
function FakeMission:setCreatorName(n) self.creatorName = n end
function FakeMission:setSpaceDutyMission() self.spaceDuty = true end
function FakeMission:sendTo(pPlayer) self.sentTo = pPlayer end

-- giveItem(pContainer, template, slot[, overload]): mission objects get a FakeMission, anything else a plain
-- container. The item is appended to the container's items.
-- A container with a `limit` (H.newPlayer{inventory = {limit = n}} or inventoryFull = true) is full once it holds `limit` items: without a truthy
-- `overload` the call adds nothing, returns nil and records the item in `container.destroyed`, like DirectorManager.cpp:2462-2473 (transferObject
-- fails, the item is destroyed). With `overload` the item lands in the container past the limit (ContainerComponent.cpp:304, allowOverflow).
function Fakes.giveItem(pContainer, template, slot, overload)
	local item

	if pContainer.limit ~= nil and #pContainer.items >= pContainer.limit and not overload then
		pContainer.destroyed = pContainer.destroyed or {}
		pContainer.destroyed[#pContainer.destroyed + 1] = template

		return nil
	end

	if template:find("mission_object", 1, true) then
		item = Fakes.newMission()
	else
		item = Fakes.newContainer({ objectName = template })
	end

	item.template = template
	pContainer.items[#pContainer.items + 1] = item

	return item
end

---------------------------------------------------------------------------------------------
-- Fake conversation template / screens, built from the real ConvoTemplate/ConvoScreen tables
-- that mobile/conversations/*.lua create (ConvoScreen fields: id, leftDialog, customDialogText,
-- stopConversation, options = {{text, link}, ...}).
---------------------------------------------------------------------------------------------

local FakeScreen = { __kind = "ConversationScreen" }
FakeScreen.__index = FakeScreen

local function newScreen(src)
	local options = {}

	for _, o in ipairs(src.options or {}) do
		options[#options + 1] = { text = o[1], link = o[2] }
	end

	return setmetatable({
		id = src.id,
		dialogText = src.leftDialog or src.customDialogText,
		stopConversation = src.stopConversation == "true" or src.stopConversation == true,
		options = options,
		params = {},
	}, FakeScreen)
end

function FakeScreen:getScreenID() return self.id end
function FakeScreen:getOptionCount() return #self.options end
function FakeScreen:getOptionText(i) return self.options[i + 1] and self.options[i + 1].text end
function FakeScreen:getOptionLink(i) return self.options[i + 1] and self.options[i + 1].link end
function FakeScreen:addOption(text, link) self.options[#self.options + 1] = { text = text, link = link } end
function FakeScreen:removeAllOptions() self.options = {} end
function FakeScreen:setDialogTextStringId(s) self.dialogText = s end
function FakeScreen:setCustomDialogText(s) self.dialogText = s end
function FakeScreen:setStopConversation(b) self.stopConversation = b end
function FakeScreen:setAnimationName(a) self.animation = a end
for _, p in ipairs({ "TT", "TO", "TU", "DF", "DI" }) do
	FakeScreen["setDialogText" .. p] = function(self, v) self.params[p] = v end
end

function FakeScreen:cloneScreen()
	local copy = setmetatable({}, FakeScreen)

	for k, v in pairs(self) do
		copy[k] = v
	end

	copy.options = {}

	for i, o in ipairs(self.options) do
		copy.options[i] = { text = o.text, link = o.link }
	end

	copy.params = {}

	for k, v in pairs(self.params) do
		copy.params[k] = v
	end

	return copy
end

local FakeTemplate = { __kind = "ConversationTemplate" }
FakeTemplate.__index = FakeTemplate

-- Wraps a real ConvoTemplate table so it can be passed as pConvTemplate.
function Fakes.newConversationTemplate(convoTemplate, name)
	-- ConvoTemplate.screens is a list; the C++ ConversationTemplate indexes screens by id.
	local screens = {}

	for _, s in ipairs(convoTemplate.screens or {}) do
		screens[s.id] = newScreen(s)
	end

	return setmetatable({ name = name, source = convoTemplate, screens = screens, initialScreen = convoTemplate.initialScreen }, FakeTemplate)
end

function FakeTemplate:getScreen(id) return self.screens[id] end
function FakeTemplate:getInitialScreen() return self.screens[self.initialScreen] end

local FakeSession = { __kind = "ConversationSession" }
FakeSession.__index = FakeSession

function Fakes.newConversationSession(npc)
	return setmetatable({ npc = npc, lastScreen = nil }, FakeSession)
end

function FakeSession:getLastConversationScreen() return self.lastScreen end

---------------------------------------------------------------------------------------------
-- Fake StringIdChatParameter and SkillManager
---------------------------------------------------------------------------------------------

local FakeStringId = { __kind = "StringIdChatParameter" }
FakeStringId.__index = FakeStringId

for _, p in ipairs({ "TT", "TO", "TU", "DF", "DI" }) do
	FakeStringId["set" .. p] = function(self, v) self.params[p] = v end
end

function FakeStringId:_getObject() return self end

local FakeSkillManager = { __kind = "SkillManager" }
FakeSkillManager.__index = FakeSkillManager

-- The XP-deducting path (SpaceHelpers:grantSpaceSkill(..., true)). Recorded separately from the
-- free path: H.Engine.callsTo("skillManagerAwardSkill") vs H.Engine.callsTo("awardSkill").
function FakeSkillManager:awardSkill(pPlayer, skill)
	skillManagerAwardSkill(pPlayer, skill)
end

-- SkillManager::fulfillsSkillPrerequisitesAndXp. The fake always says yes: the trainers gate on hasSkill and on
-- SpaceHelpers:hasExperienceForTraining before they offer a skill box (rsf-tier2-kaydine-missions, ready_train_pilot).
function FakeSkillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, skill)
	return true
end

---------------------------------------------------------------------------------------------
-- Wrapper types
---------------------------------------------------------------------------------------------

local function wrapperType(typeName)
	local mt = {}

	mt.__index = function(self, key)
		if key == "_setObject" then
			return function(w, p) rawset(w, "_target", p) end
		elseif key == "_getObject" then
			return function(w) return rawget(w, "_target") end
		end

		local target = rawget(self, "_target")

		if target == nil then
			error(string.format("harness: %s:%s called on a nil object", typeName, key), 2)
		end

		local fn = target[key]

		if type(fn) ~= "function" then
			error(string.format("harness: fake %s (wrapping %s) has no method '%s'; add it in tests/lua/harness/fakes.lua",
				typeName, tostring(target.__kind), key), 2)
		end

		return function(_, ...) return fn(target, ...) end
	end

	return function(p)
		return setmetatable({ _target = p }, mt)
	end
end

local WRAPPED_TYPES = {
	"LuaSceneObject", "LuaCreatureObject", "LuaPlayerObject", "LuaTangibleObject", "LuaAiAgent",
	"LuaBuildingObject", "LuaCityRegion", "LuaActiveArea", "LuaMissionObject", "LuaWaypointObject",
	"LuaShipObject", "LuaShipAiAgent", "LuaPobShipObject", "LuaShipComponent", "LuaIntangibleObject",
	"LuaControlDevice", "LuaConversationTemplate", "LuaConversationScreen", "LuaConversationSession",
	"LuaSuiBox", "LuaSuiListBox",
}

function Fakes.installWrappers(env)
	for _, name in ipairs(WRAPPED_TYPES) do
		env[name] = wrapperType(name)
	end

	env.LuaStringIdChatParameter = function(stringId)
		return setmetatable({ stringId = stringId, params = {} }, FakeStringId)
	end

	env.LuaSkillManager = function()
		return setmetatable({}, FakeSkillManager)
	end
end

return Fakes
