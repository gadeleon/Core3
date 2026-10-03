-- Fakes for the C++ side of Core3's Lua environment (DirectorManager / CreatureTemplateManager /
-- ShipAgentTemplateManager bindings). Real Lua from bin/scripts is loaded on top of these.
--
-- Rule: fake only what C++ provides. If production Lua calls an engine function or C++ wrapper
-- method that isn't faked yet, add it here or in fakes.lua rather than special-casing the test.

local Fakes = require("harness.fakes")

local Engine = {}

Engine.MMOCORE_ROOT = os.getenv("MMOCORE_ROOT") or "."
Engine.SCRIPTS = Engine.MMOCORE_ROOT .. "/bin/scripts/"

-- Recorders, cleared by Engine.reset()
Engine.registeredScreenPlays = {} -- name -> { start = bool, order = n }
Engine.conversationTemplates = {} -- name -> ConvoTemplate table
Engine.patrolPoints = {}          -- zone file name -> patrol point table
Engine.sharedMemory = {}          -- key -> value (readData/writeData etc.)
Engine.calls = {}                 -- list of { fn = name, args = {...} } for engine side effects
Engine.config = { jtlEnabled = true }
Engine.creatureTemplates = {}     -- name -> creature template table (CreatureTemplates:addCreatureTemplate)
Engine.clock = { now = 0, seq = 0, queue = {} } -- event clock, ms (see Engine.advance)
Engine.observers = {}             -- registered observers (createObserver), see Engine.fireObservers
Engine.spawnedShips = {}          -- fake agents returned by spawnShipAgent, in spawn order
Engine.spawnedAreas = {}          -- fake areas returned by spawnSpaceActiveArea, in spawn order

local function record(fn, ...)
	Engine.calls[#Engine.calls + 1] = { fn = fn, args = table.pack(...), t = Engine.clock.now }
end

Fakes.now = function() return Engine.clock.now end

function Engine.callsTo(fn)
	local out = {}

	for _, c in ipairs(Engine.calls) do
		if c.fn == fn then
			out[#out + 1] = c.args
		end
	end

	return out
end

-- Like callsTo, but each entry is { t = ms at the call, args = {...} }.
function Engine.timedCallsTo(fn)
	local out = {}

	for _, c in ipairs(Engine.calls) do
		if c.fn == fn then
			out[#out + 1] = { t = c.t, args = c.args }
		end
	end

	return out
end

function Engine.reset()
	Engine.sharedMemory = {}
	Engine.calls = {}
	Engine.config = { jtlEnabled = true }
	Engine.nextRandom = nil
	Engine.randomQueues = {}
	Engine.randomFixed = {}
	Engine.clock = { now = 0, seq = 0, queue = {} }
	Engine.observers = {}
	Engine.spawnedShips = {}
	Engine.spawnedAreas = {}
	Fakes.reset()
end

---------------------------------------------------------------------------------------------
-- Global constants: read from DirectorManager.cpp so the names stay in sync with the server.
-- Numeric literals keep their value; enum expressions get a unique stable integer, which is
-- enough for equality checks but not for arithmetic on the real enum values.
---------------------------------------------------------------------------------------------

local nextConstantId = 0x40000000

-- OptionBitmask::X values are real bit flags (templates/params/OptionBitmask.h), so tests can
-- check bits in optionsBitmask. Other enum expressions only get unique integers.
local optionBits

local function optionBitmask(name)
	if optionBits == nil then
		optionBits = {}

		local f = io.open(Engine.MMOCORE_ROOT .. "/src/templates/params/OptionBitmask.h", "r")

		if f then
			for n, v in f:read("a"):gmatch("(%u[%u%d_]*)%s*=%s*(0x%x+)") do
				optionBits[n] = tonumber(v)
			end

			f:close()
		end
	end

	return optionBits[name]
end

function Engine.loadConstants(relPath)
	local path = Engine.MMOCORE_ROOT .. "/" .. (relPath or "src/server/zone/managers/director/DirectorManager.cpp")
	local f = assert(io.open(path, "r"), "harness: cannot read " .. path)
	local src = f:read("a")
	f:close()

	local count = 0

	for kind, name, value in src:gmatch('setGlobal(%a+)%("([%w_]+)",%s*([^%)]-)%)') do
		local v

		if kind == "Int" or kind == "Float" then
			v = tonumber(value)

			if v == nil then
				v = optionBitmask(value:match("^%s*OptionBitmask::(%u[%u%d_]*)%s*$") or "")
			end

			if v == nil then
				nextConstantId = nextConstantId + 1
				v = nextConstantId
			end
		elseif kind == "Boolean" then
			v = (value == "true")
		elseif kind == "String" then
			v = value:match('^"(.*)"$') or name
		end

		if v ~= nil and rawget(_G, name) == nil then
			rawset(_G, name, v)
			count = count + 1
		end
	end

	return count
end

---------------------------------------------------------------------------------------------
-- Script loading. Each server Lua state resolves includeFile its own way; the resolvers below
-- copy the C++ rules:
--   DirectorManager::includeFile          -> scripts/screenplays/<file>
--   CreatureTemplateManager::includeFile  -> scripts/mobile/<file>
--   ShipAgentTemplateManager::includeFile -> by prefix (see Engine.SHIP_INCLUDE)
---------------------------------------------------------------------------------------------

function Engine.baseResolver(base)
	return function(filename) return base .. filename end
end

Engine.SCREENPLAY_INCLUDE = Engine.baseResolver(Engine.SCRIPTS .. "screenplays/")
Engine.MOBILE_INCLUDE = Engine.baseResolver(Engine.SCRIPTS .. "mobile/")

function Engine.SHIP_INCLUDE(filename)
	if filename:sub(1, #"patrol_points") == "patrol_points" then
		return Engine.SCRIPTS .. "ship_mobile/" .. filename
	elseif filename:sub(1, #"space_") == "space_" then
		return Engine.SCRIPTS .. "ship_mobile/patrol_points/" .. filename
	end

	return Engine.SCRIPTS .. "ship_mobile/ships/" .. filename
end

local includeResolver = Engine.SCREENPLAY_INCLUDE

-- Runs a script with includeFile resolved by `resolver` (default: the current one).
function Engine.runScript(path, resolver)
	local previous = includeResolver
	includeResolver = resolver or includeResolver

	local chunk, err = loadfile(path)

	if chunk == nil then
		includeResolver = previous
		error("harness: cannot load script " .. path .. ": " .. tostring(err), 2)
	end

	local ok, runErr = pcall(chunk)
	includeResolver = previous

	if not ok then
		error("harness: error running " .. path .. ": " .. tostring(runErr), 2)
	end
end

function includeFile(filename)
	Engine.runScript(includeResolver(filename))
end

function registerScreenPlay(name, start)
	local order = 0

	for _ in pairs(Engine.registeredScreenPlays) do
		order = order + 1
	end

	Engine.registeredScreenPlays[name] = { start = start, order = order + 1 }
end

function addConversationTemplate(name, template)
	if Engine.conversationTemplates[name] ~= nil then
		error("harness: duplicate conversation template " .. name, 2)
	end

	Engine.conversationTemplates[name] = template
end

function addSpacePatrolPoints(file, obj)
	Engine.patrolPoints[file] = obj
end

---------------------------------------------------------------------------------------------
-- Shared memory (backs readData/writeData/... in screenplays/screenplay.lua)
---------------------------------------------------------------------------------------------

local function memFns(suffix)
	_G["readSharedMemory" .. suffix] = function(key)
		local v = Engine.sharedMemory[suffix .. ":" .. key]

		if v == nil and suffix == "" then
			return 0
		elseif v == nil and suffix == "String" then
			return ""
		end

		return v
	end

	_G["writeSharedMemory" .. suffix] = function(key, value)
		Engine.sharedMemory[suffix .. ":" .. key] = value
	end

	_G["deleteSharedMemory" .. suffix] = function(key)
		Engine.sharedMemory[suffix .. ":" .. key] = nil
	end
end

memFns("")
memFns("String")

-- The server registers the string variants as read/write/deleteStringSharedMemory (DirectorManager.cpp),
-- which is what screenplay.lua's readStringData/writeStringData/deleteStringData call. The first harness
-- names them read/write/deleteSharedMemoryString; both spellings work and share one store.
readStringSharedMemory = readSharedMemoryString
writeStringSharedMemory = writeSharedMemoryString
deleteStringSharedMemory = deleteSharedMemoryString

-- String vectors. The server stores strings, so numbers (object ids) come back as strings: callers
-- must tonumber() them. read returns a copy ({} when absent).
function writeStringVectorSharedMemory(key, tbl)
	local copy = {}

	for i, v in ipairs(tbl) do
		copy[i] = tostring(v)
	end

	Engine.sharedMemory["StringVector:" .. key] = copy
end

function readStringVectorSharedMemory(key)
	local copy = {}

	for i, v in ipairs(Engine.sharedMemory["StringVector:" .. key] or {}) do
		copy[i] = v
	end

	return copy
end

function deleteStringVectorSharedMemory(key)
	Engine.sharedMemory["StringVector:" .. key] = nil
end

-- Every shared-memory key currently set, as a sorted list of "<kind>|<key>" (kind is "", "String",
-- "Vector3" or "StringVector"), so tests can compare before/after snapshots and check key prefixes.
function Engine.sharedMemoryKeys()
	local keys = {}

	for k in pairs(Engine.sharedMemory) do
		local kind, key = k:match("^(%a*):(.*)$")
		keys[#keys + 1] = kind .. "|" .. key
	end

	table.sort(keys)
	return keys
end

function writeVector3SharedMemory(key, x, z, y)
	Engine.sharedMemory["Vector3:" .. key] = { x, z, y }
end

function readVector3SharedMemory(key)
	return Engine.sharedMemory["Vector3:" .. key]
end

function deleteVector3SharedMemory(key)
	Engine.sharedMemory["Vector3:" .. key] = nil
end

---------------------------------------------------------------------------------------------
-- Misc engine functions
---------------------------------------------------------------------------------------------

-- Deterministic string hash (FNV-1a, 32 bit). NOT equal to the server's String::hashCode; it only
-- needs to be consistent inside the harness (journal quest keys, template ids).
function getHashCode(s)
	local h = 2166136261

	for i = 1, #s do
		h = ((h ~ s:byte(i)) * 16777619) & 0xFFFFFFFF
	end

	return h
end

-- logLua(level, message): the engine log used by utils/logger.lua. Recorded, not printed
-- (H.Engine.callsTo("logLua") -> { level, message }).
function logLua(level, message)
	record("logLua", level, message)
end

function isJtlEnabled()
	return Engine.config.jtlEnabled
end

function isZoneEnabled(zoneName)
	return true
end

-- Deterministic: tests that care set Engine.nextRandom.
Engine.nextRandom = nil

-- Per-range draws: Engine.queueRandom(a, b, v1, v2, ...) makes the next calls of getRandomNumber(a, b)
-- return v1, v2, ... in order (then the usual behavior); Engine.setRandom(a, b, v) makes every call
-- of getRandomNumber(a, b) return v. Ranges win over Engine.nextRandom. Cleared by Engine.reset().
Engine.randomQueues = {}
Engine.randomFixed = {}

local function rangeKey(a, b)
	return tostring(a) .. "," .. tostring(b)
end

function Engine.queueRandom(a, b, ...)
	local key = rangeKey(a, b)
	local queue = Engine.randomQueues[key] or {}

	for _, v in ipairs({ ... }) do
		queue[#queue + 1] = v
	end

	Engine.randomQueues[key] = queue
end

function Engine.setRandom(a, b, value)
	Engine.randomFixed[rangeKey(a, b)] = value
end

function getRandomNumber(a, b)
	local key = rangeKey(a, b)
	local queue = Engine.randomQueues[key]

	if queue ~= nil and #queue > 0 then
		return table.remove(queue, 1)
	end

	if Engine.randomFixed[key] ~= nil then
		return Engine.randomFixed[key]
	end

	if Engine.nextRandom ~= nil then
		return Engine.nextRandom
	end

	if b == nil then
		return 1
	end

	return a
end

function getSceneObject(objectID)
	return Fakes.lookup(objectID)
end

function getCreatureObject(objectID)
	return Fakes.lookup(objectID)
end

-- Quest status strings (DirectorManager::getQuestStatus & co). Values are stored as strings, like
-- the server (setQuestStatus(key, 1) reads back "1"); an empty value reads back as nil.
function getQuestStatus(key)
	local v = Fakes.questStatus[key]

	if v == nil or v == "" then
		return nil
	end

	return v
end

function setQuestStatus(key, value)
	Fakes.questStatus[key] = tostring(value)
end

function removeQuestStatus(key)
	Fakes.questStatus[key] = nil
end

-- Free skill grant (awardSkill) as used by SpaceHelpers:grantSpaceSkill(p, skill, false).
function awardSkill(pPlayer, skillName)
	record("awardSkill", pPlayer, skillName)

	if pPlayer ~= nil and pPlayer.skills ~= nil then
		pPlayer.skills[skillName] = true
	end
end

-- XP-deducting grant (SkillManager:awardSkill) as used by SpaceHelpers:grantSpaceSkill(p, skill, true).
-- The fake does not model the XP cost; production code gates on hasExperienceForTraining first.
-- Opt-in XP model (rsf-tier2-kaydine-training): H.Engine.config.skillXpCosts = { [skill] = cost } charges `cost`
-- space_combat_general from the player's ghost and refuses the skill (nothing granted, nothing charged) when the
-- pilot has less, like SkillManager::awardSkill. Without the table nothing is charged. H.reset() clears the config.
function skillManagerAwardSkill(pPlayer, skillName)
	record("skillManagerAwardSkill", pPlayer, skillName)

	local costs = Engine.config.skillXpCosts
	local cost = costs and costs[skillName]

	if cost ~= nil and pPlayer ~= nil and pPlayer.ghost ~= nil then
		local have = pPlayer.ghost.experience.space_combat_general or 0

		if have < cost then
			return
		end

		pPlayer.ghost.experience.space_combat_general = have - cost
	end

	if pPlayer ~= nil and pPlayer.skills ~= nil then
		pPlayer.skills[skillName] = true
	end
end

---------------------------------------------------------------------------------------------
-- Event clock. createEvent records the call (as before) and queues it; nothing runs until a test
-- calls H.advance(ms). Time starts at 0 on every H.reset().
---------------------------------------------------------------------------------------------

function createEvent(delay, screenplay, method, pObject, args)
	if type(delay) ~= "number" or type(screenplay) ~= "string" or type(method) ~= "string" then
		error(string.format("harness: createEvent(delay:number, screenplay:string, method:string, pObject, args) got (%s, %s, %s)",
			type(delay), type(screenplay), type(method)), 2)
	end

	record("createEvent", delay, screenplay, method, pObject, args)

	local c = Engine.clock
	c.seq = c.seq + 1
	c.queue[#c.queue + 1] = { due = c.now + delay, seq = c.seq, screenplay = screenplay, method = method, pObject = pObject, args = args }
end

-- cancelEvent(screenplay, method, pObject): DirectorManager::cancelEvent drops the pending events of that
-- screenplay function on that object (exactly 3 arguments, a nil object cancels nothing).
function cancelEvent(...)
	local n = select("#", ...)

	if n ~= 3 then
		error("harness: cancelEvent(screenplay, method, pObject) takes exactly 3 arguments; got " .. n, 2)
	end

	local screenplay, method, pObject = ...

	record("cancelEvent", screenplay, method, pObject)

	if pObject == nil then
		return
	end

	local queue = Engine.clock.queue

	for i = #queue, 1, -1 do
		local e = queue[i]

		if e.screenplay == screenplay and e.method == method and e.pObject == pObject then
			table.remove(queue, i)
		end
	end
end

local function runEvent(e)
	local sp = rawget(_G, e.screenplay)

	if sp == nil then
		error(string.format("harness: event targets unknown screenplay global '%s' (method %s) at t=%dms", e.screenplay, e.method, Engine.clock.now), 0)
	end

	local fn = sp[e.method]

	if type(fn) ~= "function" then
		error(string.format("harness: event targets undefined method %s:%s at t=%dms", e.screenplay, e.method, Engine.clock.now), 0)
	end

	local ok, err = pcall(fn, sp, e.pObject, e.args)

	if not ok then
		error(string.format("harness: event %s:%s (created for t=%dms) failed: %s", e.screenplay, e.method, e.due, tostring(err)), 0)
	end
end

-- Runs every event due within the next `ms` milliseconds, in due order (ties in creation order).
-- While an event runs, Engine.clock.now is its due time, so events it creates are relative to it.
-- Afterwards now = start + ms.
function Engine.advance(ms)
	local c = Engine.clock
	local target = c.now + ms
	local ran = 0

	while true do
		local best, bestIndex

		for i, e in ipairs(c.queue) do
			if e.due <= target and (best == nil or e.due < best.due or (e.due == best.due and e.seq < best.seq)) then
				best, bestIndex = e, i
			end
		end

		if best == nil then
			break
		end

		table.remove(c.queue, bestIndex)

		if best.due > c.now then
			c.now = best.due
		end

		ran = ran + 1

		if ran > 100000 then
			error("harness: more than 100000 events in one advance; a timer is probably rescheduling itself with delay 0", 0)
		end

		runEvent(best)
	end

	c.now = target
	return ran
end

-- Events still waiting: list of { due, screenplay, method, pObject, args }, soonest first.
function Engine.pendingEvents()
	local out = {}

	for _, e in ipairs(Engine.clock.queue) do
		out[#out + 1] = e
	end

	table.sort(out, function(a, b) if a.due ~= b.due then return a.due < b.due end return a.seq < b.seq end)
	return out
end

---------------------------------------------------------------------------------------------
-- Observers. createObserver registers (and still records the call); H.fireObservers runs the
-- registered handlers like ObserverEventMap::notifyObservers: handler(screenplay, pObject, ...),
-- a handler returning 1 is removed, any other number keeps it, and a non-number return is an
-- error (the server logs "didnt return a valid value for a observer handler").
---------------------------------------------------------------------------------------------

function createObserver(eventType, screenplay, method, pObject, persistent)
	record("createObserver", eventType, screenplay, method, pObject, persistent)

	if pObject == nil then
		return
	end

	Engine.observers[#Engine.observers + 1] = { type = eventType, sp = screenplay, method = method, obj = pObject }
end

local function matches(o, eventType, screenplay, method, pObject)
	return o.type == eventType and o.sp == screenplay and o.method == method and o.obj == pObject
end

function hasObserver(eventType, screenplay, method, pObject)
	for _, o in ipairs(Engine.observers) do
		if matches(o, eventType, screenplay, method, pObject) then
			return true
		end
	end

	return false
end

function dropObserver(eventType, screenplay, method, pObject)
	record("dropObserver", eventType, screenplay, method, pObject)

	for i = #Engine.observers, 1, -1 do
		if matches(Engine.observers[i], eventType, screenplay, method, pObject) then
			table.remove(Engine.observers, i)
		end
	end
end

-- Number of registrations matching (eventType, screenplay, method, pObject); use it to assert that
-- an observer was registered exactly once.
function Engine.observerCount(eventType, screenplay, method, pObject)
	local n = 0

	for _, o in ipairs(Engine.observers) do
		if matches(o, eventType, screenplay, method, pObject) then
			n = n + 1
		end
	end

	return n
end

-- Registered observers on pObject, optionally of one event type: list of { type, sp, method }.
function Engine.observersOn(pObject, eventType)
	local out = {}

	for _, o in ipairs(Engine.observers) do
		if o.obj == pObject and (eventType == nil or o.type == eventType) then
			out[#out + 1] = { type = o.type, sp = o.sp, method = o.method }
		end
	end

	return out
end

function Engine.fireObservers(eventType, pObject, ...)
	local args = table.pack(...)
	local snapshot = {}

	for _, o in ipairs(Engine.observers) do
		if o.obj == pObject and o.type == eventType then
			snapshot[#snapshot + 1] = o
		end
	end

	for _, o in ipairs(snapshot) do
		local stillThere = false

		for _, live in ipairs(Engine.observers) do
			if live == o then
				stillThere = true
				break
			end
		end

		if stillThere then
			local sp = rawget(_G, o.sp)

			if sp == nil or type(sp[o.method]) ~= "function" then
				error(string.format("harness: observer %s:%s is not defined", o.sp, o.method), 0)
			end

			local ret = sp[o.method](sp, pObject, table.unpack(args, 1, args.n))

			if type(ret) ~= "number" then
				error(string.format("harness: observer handler %s:%s returned %s; the server requires a number (1 removes the observer, 0 keeps it)", o.sp, o.method, type(ret)), 0)
			end

			if ret == 1 then
				for i = #Engine.observers, 1, -1 do
					if Engine.observers[i] == o then
						table.remove(Engine.observers, i)
					end
				end
			end
		end
	end
end

-- Destroying an object drops every observer registered on it.
Fakes.destroyHook = function(obj)
	record("destroyObjectFromWorld", obj)

	for i = #Engine.observers, 1, -1 do
		if Engine.observers[i].obj == obj then
			table.remove(Engine.observers, i)
		end
	end
end

---------------------------------------------------------------------------------------------
-- Space spawns and items
---------------------------------------------------------------------------------------------

-- spawnShipAgent(shipName, zone, x, z, y[, pTargetShip]) -> fake agent (nil if
-- Engine.config.spawnFails is set, like the server when the ship can't be created).
function spawnShipAgent(shipName, zone, x, z, y, pTarget)
	if type(shipName) ~= "string" or type(zone) ~= "string" or type(x) ~= "number" or type(z) ~= "number" or type(y) ~= "number" then
		error("harness: spawnShipAgent(shipName, zone, x, z, y[, pTargetShip]) got bad argument types", 2)
	end

	record("spawnShipAgent", shipName, zone, x, z, y, pTarget)

	if Engine.config.spawnFails then
		return nil
	end

	local agent = Fakes.newShipAgent({ shipName = shipName, zone = zone, x = x, z = z, y = y })
	Engine.spawnedShips[#Engine.spawnedShips + 1] = agent
	return agent
end

-- spawnSpaceActiveArea(zone, template, x, z, y, radius) -> fake area (nil if Engine.config.areaFails is set).
function spawnSpaceActiveArea(zone, template, x, z, y, radius)
	if type(zone) ~= "string" or type(template) ~= "string" or type(x) ~= "number" or type(z) ~= "number" or type(y) ~= "number" or type(radius) ~= "number" then
		error("harness: spawnSpaceActiveArea(zone, template, x, z, y, radius) got bad argument types", 2)
	end

	record("spawnSpaceActiveArea", zone, template, x, z, y, radius)

	-- Engine.config.areaFails = true: the server could not create the area (space-quest-rescue-docking).
	if Engine.config.areaFails then
		return nil
	end

	local area = Fakes.newActiveArea({ zone = zone, template = template, x = x, z = z, y = y, radius = radius })
	Engine.spawnedAreas[#Engine.spawnedAreas + 1] = area
	return area
end

function giveItem(pContainer, template, slot)
	record("giveItem", pContainer, template, slot)
	return Fakes.giveItem(pContainer, template, slot)
end

function grantStarterShip(pPlayer, faction)
	record("grantStarterShip", pPlayer, faction)
end

-- Creature templates (mobile/*.lua): Creature:new { ... } then CreatureTemplates:addCreatureTemplate(t, name).
CreatureTemplates = {
	addCreatureTemplate = function(_, template, name)
		Engine.creatureTemplates[name] = template
	end,
}

-- C++ wrapper constructors (LuaCreatureObject(p), LuaConversationScreen(p), ...) live in fakes.lua.
Fakes.installWrappers(_G)

Engine.record = record

return Engine
