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

local function record(fn, ...)
	Engine.calls[#Engine.calls + 1] = { fn = fn, args = table.pack(...) }
end

function Engine.callsTo(fn)
	local out = {}

	for _, c in ipairs(Engine.calls) do
		if c.fn == fn then
			out[#out + 1] = c.args
		end
	end

	return out
end

function Engine.reset()
	Engine.sharedMemory = {}
	Engine.calls = {}
	Engine.config = { jtlEnabled = true }
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

function isJtlEnabled()
	return Engine.config.jtlEnabled
end

function isZoneEnabled(zoneName)
	return true
end

-- Deterministic: tests that care set Engine.nextRandom.
Engine.nextRandom = nil

function getRandomNumber(a, b)
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
function skillManagerAwardSkill(pPlayer, skillName)
	record("skillManagerAwardSkill", pPlayer, skillName)

	if pPlayer ~= nil and pPlayer.skills ~= nil then
		pPlayer.skills[skillName] = true
	end
end

function createEvent(delay, screenplay, method, pObject, args)
	record("createEvent", delay, screenplay, method, pObject, args)
end

function createObserver(eventType, screenplay, method, pObject, persistent)
	record("createObserver", eventType, screenplay, method, pObject, persistent)
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
