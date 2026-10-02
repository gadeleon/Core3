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
function FakeGhost:activateJournalQuest(crc, notify) self.journalActive[crc] = true end
function FakeGhost:completeJournalQuest(crc, notify) self.journalActive[crc] = nil; self.journalComplete[crc] = true end
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

function FakeGhost:completeJournalQuestTask(crc, task, notify)
	if self.taskActive[crc] then
		self.taskActive[crc][task] = nil
	end

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
		certifiedShip = opts.certifiedShip ~= false,
		screenPlayStates = opts.screenPlayStates or {},
		messages = {},
		music = {},
		isNpc = opts.isNpc or false,
		conversationSession = nil,
		zone = opts.zone or "",
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
	}, FakeCreature)

	if not c.isNpc then
		c.ghost = opts.ghost or Fakes.newGhost(opts)
		c.datapad = Fakes.newContainer({ objectName = "datapad" })
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
function FakeCreature:getPlayerObject() return self.ghost end
function FakeCreature:isPlayerCreature() return not self.isNpc end
function FakeCreature:hasSkill(skill) return self.skills[skill] == true end
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
function FakeCreature:getSlottedObject(slot) if slot == "datapad" then return self.datapad end end

-- A player inside a ship reports the ship's position, like the server's world position.
function FakeCreature:getWorldPositionX() return self.rootParent and self.rootParent.x or 0 end
function FakeCreature:getWorldPositionZ() return self.rootParent and self.rootParent.z or 0 end
function FakeCreature:getWorldPositionY() return self.rootParent and self.rootParent.y or 0 end

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
function FakeCreature:removeQuestMission(crc) end
function FakeCreature:failQuestMission(crc)
	self.failedMissions[#self.failedMissions + 1] = crc
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
function FakeShip:setPosition(x, z, y) self.x, self.z, self.y = x, z, y end

function FakeShip:getSpawnPointInFrontOfShip(min, max)
	self.spawnPointCalls[#self.spawnPointCalls + 1] = { min, max }
	return { self.x + min, self.z + 7, self.y + max }
end

function FakeShip:getSpawnPointBehindShip(min, max)
	self.spawnPointCalls[#self.spawnPointCalls + 1] = { -min, -max }
	return { self.x - min, self.z + 7, self.y - max }
end

-- AI ship agent returned by spawnShipAgent. Extra opts: shipName, zone, x, z, y.
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
	}, FakeAgent)

	return register(a)
end

function FakeAgent:setMissionOwner(pPlayer) self.missionOwner = pPlayer end
function FakeAgent:getMissionOwnerID() return self.missionOwner and self.missionOwner.objectID or 0 end
function FakeAgent:addSpaceFactionEnemy(hash) self.factionEnemies[#self.factionEnemies + 1] = hash end
function FakeAgent:engageShipTarget(pShip) self.engaged[#self.engaged + 1] = pShip end
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

local FakeMission = { __kind = "MissionObject" }
FakeMission.__index = FakeMission
sceneMethods(FakeMission)

function Fakes.newMission()
	return register(setmetatable({ spaceDuty = false }, FakeMission))
end

function FakeMission:isMissionObject() return true end
function FakeMission:isSpaceDutyMission() return self.spaceDuty end
function FakeMission:setTypeCRC(crc) self.typeCRC = crc end
function FakeMission:setQuestType(t) self.questType = t end
function FakeMission:setQuestName(n) self.questName = n end
function FakeMission:setMissionTitle(file, key) self.title = { file, key } end
function FakeMission:setMissionDescription(file, key) self.description = { file, key } end
function FakeMission:setCreatorName(n) self.creatorName = n end
function FakeMission:setSpaceDutyMission() self.spaceDuty = true end
function FakeMission:sendTo(pPlayer) self.sentTo = pPlayer end

-- giveItem(pContainer, template, slot): mission objects get a FakeMission, anything else a plain
-- container. The item is appended to the container's items.
function Fakes.giveItem(pContainer, template, slot)
	local item

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
