-- Test harness entry point. Usage in a test file:
--
--   local H = require("harness")
--   local lu = require("luaunit")
--   H.loadSquadron("CorsecSquadronScreenplay")
--
-- Loads the real Core3 Lua base layer (Object/ObjectManager, ScreenPlay, ConvoTemplate,
-- conv_handler, SpaceHelpers) on top of the engine fakes in engine.lua / fakes.lua.

local Engine = require("harness.engine")
local Fakes = require("harness.fakes")
local Tab = require("harness.tab")

local H = {
	Engine = Engine,
	Fakes = Fakes,
	Tab = Tab,
	ROOT = Engine.MMOCORE_ROOT,
	SCRIPTS = Engine.SCRIPTS,
	FIXTURES = Engine.MMOCORE_ROOT .. "/tests/lua/fixtures/",
}

-- Re-export fake constructors
H.newPlayer = Fakes.newPlayer
H.newNpc = Fakes.newNpc
H.questCrc = Fakes.questCrc

local function fileExists(path)
	local f = io.open(path, "r")

	if f then
		f:close()
		return true
	end

	return false
end

H.fileExists = fileExists

---------------------------------------------------------------------------------------------
-- Boot: real base layer, loaded once per process (each test file runs in its own process).
---------------------------------------------------------------------------------------------

local booted = false

function H.boot()
	if booted then
		return
	end

	booted = true

	Engine.loadConstants()

	-- managers.object.object_manager defines Object and the CreatureObject()/PlayerObject()/...
	-- wrapper functions on top of the faked LuaCreatureObject etc.
	require("managers.object.object_manager")
	require("screenplays.screenplay")
	package.loaded["screenplay"] = package.loaded["screenplays.screenplay"]

	Engine.runScript(H.SCRIPTS .. "mobile/conversation.lua", Engine.MOBILE_INCLUDE)
	Engine.runScript(H.SCRIPTS .. "screenplays/conv_handler.lua", Engine.SCREENPLAY_INCLUDE)
	package.loaded["conv_handler"] = true

	SpaceHelpers = require("utils.space_helpers")
end

-- Clears engine recorders and fake objects (not loaded scripts). Call from setUp().
function H.reset()
	H.restoreSpies()
	Engine.reset()
end

---------------------------------------------------------------------------------------------
-- Spies: replace a method on a (global) table with a recorder. Restored by H.reset(), so call
-- H.reset() from setUp (and tearDown if a test leaves spies behind).
---------------------------------------------------------------------------------------------

local spies = {}

-- H.spyOn(obj, "startQuest", snapshotFn?) -> calls. Each call appends
-- { self = obj, args = table.pack(...), snapshot = snapshotFn(obj, ...) } to `calls`.
-- snapshotFn runs at call time (use it to capture state "before" the call). The original method
-- is NOT called.
function H.spyOn(obj, method, snapshotFn)
	local calls = {}
	local original = rawget(obj, method)

	spies[#spies + 1] = { obj = obj, method = method, original = original }

	obj[method] = function(self, ...)
		local snapshot

		if snapshotFn ~= nil then
			snapshot = snapshotFn(self, ...)
		end

		calls[#calls + 1] = { self = self, args = table.pack(...), snapshot = snapshot }
	end

	return calls
end

function H.restoreSpies()
	for i = #spies, 1, -1 do
		local spy = spies[i]
		spy.obj[spy.method] = spy.original
	end

	spies = {}
end

-- Names of every global that is a space quest (a table with questType, questName and a startQuest
-- method), sorted. Handy for "no other quest was started" checks.
function H.questGlobals()
	local names = {}

	for name, value in pairs(_G) do
		if type(name) == "string" and type(value) == "table" and rawget(value, "questType") ~= nil and rawget(value, "questName") ~= nil
			and type(value.startQuest) == "function" then
			names[#names + 1] = name
		end
	end

	table.sort(names)
	return names
end

-- Quest status helpers, keyed the way handlers do: <player object id><suffix>.
function H.getQuestStatus(player, suffix)
	return getQuestStatus(player.objectID .. suffix)
end

function H.setQuestStatus(player, suffix, value)
	setQuestStatus(player.objectID .. suffix, value)
end

---------------------------------------------------------------------------------------------
-- Loading production scripts
---------------------------------------------------------------------------------------------

-- Runs bin/scripts/screenplays/<rel>, with includeFile relative to scripts/screenplays/ like
-- DirectorManager. Fails with a clear message if the file doesn't exist (a clean red phase).
function H.loadScreenplay(rel)
	H.boot()

	local path = H.SCRIPTS .. "screenplays/" .. rel
	assert(fileExists(path), "expected screenplay script to exist: bin/scripts/screenplays/" .. rel)
	Engine.runScript(path, Engine.SCREENPLAY_INCLUDE)
end

-- Runs bin/scripts/mobile/<rel>, with includeFile relative to scripts/mobile/ like
-- CreatureTemplateManager (conversation templates, NPC templates).
function H.loadMobile(rel)
	H.boot()

	local path = H.SCRIPTS .. "mobile/" .. rel
	assert(fileExists(path), "expected mobile script to exist: bin/scripts/mobile/" .. rel)
	Engine.runScript(path, Engine.MOBILE_INCLUDE)
end

-- Runs bin/scripts/mobile/<rel> as a creature template (mobile/space/warvog_arkon.lua): loads the
-- CreatureTemplateManager constants and a minimal `Creature:new` base first (the real
-- mobile/creatures.lua pulls in every creature template in the game, so it is not loaded). Returns
-- the template table registered via CreatureTemplates:addCreatureTemplate, or nil.
local creatureBaseLoaded = false

function H.loadCreatureTemplate(rel, name)
	H.boot()

	if not creatureBaseLoaded then
		creatureBaseLoaded = true
		Engine.loadConstants("src/server/zone/managers/creature/CreatureTemplateManager.cpp")

		if rawget(_G, "Creature") == nil then
			Creature = {}

			function Creature:new(o)
				o = o or {}
				setmetatable(o, self)
				self.__index = self
				return o
			end
		end
	end

	H.loadMobile(rel)

	return Engine.creatureTemplates[name]
end

-- Quest-type base screenplays, in the same order as screenplays/space/screenplays.lua.
local SPACE_QUEST_TYPES = {
	"SpaceQuestLogic", "SpaceAssassinateScreenplay", "SpaceBattleScreenplay", "SpaceDeliveryScreenplay",
	"SpaceDeliveryNoPickupScreenplay", "SpaceDestroyScreenplay", "SpaceEscortScreenplay", "SpaceInspectScreenplay",
	"SpacePatrolScreenplay", "SpaceRecoveryScreenplay", "SpaceRescueScreenplay", "SpaceSurpriseAttackScreenplay",
	"SpaceSurvivalScreenplay", "SpaceDutyDestroyScreenplay", "SpaceDutyEscortScreenplay", "SpaceDutyPatrolScreenplay",
	"SpaceDutyRecoveryScreenplay", "SpaceDutyRescueScreenplay",
}

local questTypesLoaded = false

function H.loadSpaceQuestTypes()
	if questTypesLoaded then
		return
	end

	questTypesLoaded = true

	for _, name in ipairs(SPACE_QUEST_TYPES) do
		H.loadScreenplay("space/" .. name .. ".lua")
	end
end

-- Loads screenplays/space/squadrons/<name>.lua (and the quest types it builds on).
function H.loadSquadron(name)
	H.loadSpaceQuestTypes()
	H.loadScreenplay("space/squadrons/" .. name .. ".lua")
end

---------------------------------------------------------------------------------------------
-- Inspecting what scripts registered
---------------------------------------------------------------------------------------------

-- Asserts a global exists and returns it, with a message that makes a red phase readable.
function H.expectGlobal(name, hint)
	local v = rawget(_G, name)
	assert(v ~= nil, "expected global '" .. name .. "' to be defined" .. (hint and (" (" .. hint .. ")") or ""))
	return v
end

-- Registration info for a screenplay: { start = bool, order = n } or nil.
function H.registered(name)
	return Engine.registeredScreenPlays[name]
end

-- Real ConvoTemplate table registered under <name> via addConversationTemplate, or nil.
function H.conversationTemplateTable(name)
	return Engine.conversationTemplates[name]
end

-- Fake C++ conversation template (pConvTemplate) for a registered template.
function H.conversationTemplate(name)
	local t = Engine.conversationTemplates[name]
	assert(t ~= nil, "expected conversation template '" .. name .. "' to be registered via addConversationTemplate")
	return Fakes.newConversationTemplate(t, name)
end

-- Structural problems in a registered template: duplicate or missing screen ids, options linking
-- to missing screens, a non-empty initialScreen that doesn't exist (Lua-handled templates use
-- initialScreen = "" and pick the first screen in their handler). Returns a list of strings
-- (empty = OK). ConvoTemplate.screens is a list; the C++ side indexes screens by their id.
function H.conversationProblems(name)
	local t = Engine.conversationTemplates[name]
	assert(t ~= nil, "expected conversation template '" .. name .. "' to be registered")

	local problems = {}
	local byId = {}

	for i, screen in ipairs(t.screens) do
		if screen.id == nil or screen.id == "" then
			problems[#problems + 1] = string.format("screen #%d has no id", i)
		elseif byId[screen.id] then
			problems[#problems + 1] = string.format("duplicate screen id '%s'", screen.id)
		end

		byId[screen.id] = screen
	end

	if t.initialScreen ~= nil and t.initialScreen ~= "" and byId[t.initialScreen] == nil then
		problems[#problems + 1] = "initialScreen '" .. tostring(t.initialScreen) .. "' is not a screen"
	end

	for _, screen in ipairs(t.screens) do
		for i, option in ipairs(screen.options or {}) do
			if byId[option[2]] == nil then
				problems[#problems + 1] = string.format("screen '%s' option %d links to missing screen '%s'", tostring(screen.id), i, tostring(option[2]))
			end
		end
	end

	table.sort(problems)
	return problems
end

---------------------------------------------------------------------------------------------
-- Driving a conversation the way ConversationObserverImplementation does:
--   screen = handler:getNextConversationScreen(tmpl, player, selectedOption, npc)
--   screen = handler:runScreenHandlers(tmpl, player, npc, selectedOption, screen)
--   session.lastScreen = screen (nil ends the conversation)
--
-- args: template (name), player, npc, choices (list of 0-based option indexes, option sids or hook
-- functions, see below), handler (optional
-- handler table; defaults to the template's luaClassHandler global).
-- Returns a transcript: list of { id, text, options = {{text, link}}, params, stop }.
---------------------------------------------------------------------------------------------

function H.converse(args)
	local tmpl = H.conversationTemplate(args.template)
	local handlerName = H.conversationTemplateTable(args.template).luaClassHandler
	local handler = args.handler or H.expectGlobal(handlerName, "luaClassHandler of " .. args.template)
	local player, npc = args.player, args.npc or Fakes.newNpc({ name = "npc" })

	local session = Fakes.newConversationSession(npc)
	player.conversationSession = session

	local transcript = {}
	local choices = args.choices or {}
	local selected = 0
	local nextChoice = 1

	while true do
		local screen = handler:getNextConversationScreen(tmpl, player, selected, npc)

		if screen ~= nil then
			screen = handler:runScreenHandlers(tmpl, player, npc, selected, screen)
		end

		session.lastScreen = screen

		if screen == nil then
			break
		end

		local options = {}

		for i, o in ipairs(screen.options) do
			options[i] = { text = o.text, link = o.link }
		end

		transcript[#transcript + 1] = { id = screen.id, text = screen.dialogText, options = options, params = screen.params, stop = screen.stopConversation }

		if screen.stopConversation then
			break
		end

		-- A choice is a 0-based option index, an option sid ("s_6222b64d" or the full
		-- "@conversation/x:s_6222b64d" text) resolved against the screen just shown, or a function
		-- hook(player) that runs between screens without consuming a step.
		local choice

		repeat
			choice = choices[nextChoice]
			nextChoice = nextChoice + 1

			if type(choice) == "function" then
				choice(player)
			end
		until type(choice) ~= "function"

		if choice == nil then
			break
		end

		if type(choice) == "string" then
			local found

			for i, o in ipairs(options) do
				if o.text == choice or o.text:sub(-#choice - 1) == ":" .. choice then
					found = i - 1
					break
				end
			end

			if found == nil then
				local have = {}

				for i, o in ipairs(options) do
					have[i] = tostring(o.text)
				end

				error(string.format("H.converse: screen '%s' has no option '%s'; options are: %s", tostring(screen.id), choice, table.concat(have, ", ")), 2)
			end

			choice = found
		end

		selected = choice
	end

	return transcript
end

---------------------------------------------------------------------------------------------
-- Space data
---------------------------------------------------------------------------------------------

local patrolPointsLoaded = false

-- Map of patrolPointName -> {x, z, y} for a space zone, from ship_mobile/patrol_points.
function H.patrolPoints(zone)
	H.boot()

	if not patrolPointsLoaded then
		patrolPointsLoaded = true
		Engine.runScript(H.SCRIPTS .. "ship_mobile/space_patrol_points.lua", Engine.SHIP_INCLUDE)
	end

	local list = Engine.patrolPoints[zone]
	assert(list ~= nil, "no patrol points registered for zone " .. tostring(zone))

	local byName = {}

	for _, p in ipairs(list) do
		byName[p.patrolPointName] = p
	end

	return byName
end

-- Reads tests/lua/fixtures/<rel> (an SWG-Source .tab copied byte for byte).
function H.fixture(rel)
	local path = H.FIXTURES .. rel
	assert(fileExists(path), "missing fixture tests/lua/fixtures/" .. rel .. " (copy it from the SWG-Source clone with cp)")
	return Tab.read(path)
end

-- Convenience: the single record of a spacequest fixture, e.g. H.questFixture("patrol", "corellia_privateer_1").
function H.questFixture(questType, questName)
	local t = H.fixture("spacequest/" .. questType .. "/" .. questName .. ".tab")
	assert(#t.records == 1, "expected exactly one record in " .. t.path .. ", found " .. #t.records)
	return t.records[1], t
end

return H
