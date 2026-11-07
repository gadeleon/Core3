-- Shared test data and builders for Kiizete (Vortex Squadron tier 1 side NPC, Moenia gazebo), not a test file.
-- Spec: .claude/work/vortex-tier1-kiizete/01-spec.md (Content contract, Conversation flow, Appendix A).
--
-- Everything below is copied from the spec, not read from the production scripts:
--   K.SCREENS        Appendix A (vortex_tier1_kiizete_screens_data.lua, generated from the spec table by a scratch script), 61 rows
--   K.IMP_KEY / K.Q1_KEY   the two session-flag keys (Content contract 1)
--   K.load()         the server's load: the squadron files, V3-FX's template and handler (they come first), Kiizete's template and handler
--   K.player{...}    a player in front of Kiizete, built by vortex_tier1_data.lua V.pilot (same options)
--   K.talk / K.drive H.converse from the first screen / from a given screen, with Kiizete as the NPC
--   K.gate           the screen id the handler's getInitialScreen picks (side-effect free, I-3)
--   K.snapshot       a deep copy of everything a walk could change (I-3, I-4)
--
-- Kiizete's conversation lives in the template "kiizete_convo_template"; its handler is the global "kiizeteConvoHandler".
-- Handler helpers are colon methods, like every other handler of the repo (kiizeteConvoHandler:isImperial(p)).

local H = require("harness")
local I = require("vortex_tier1_data")

local K = {}

K.TEMPLATE = "kiizete_convo_template"
K.HANDLER = "kiizeteConvoHandler"
K.PREFIX = "@conversation/naboo_rebel_tier1_kiizete:"
K.STF = "conversation/naboo_rebel_tier1_kiizete"

K.TEMPLATE_FILE = "mobile/conversations/space/rebel/vortex_squadron/kiizete_convo.lua"
K.HANDLER_FILE = "screenplays/space/conversations/rebel/vortex_squadron/kiizeteConvoHandler.lua"
K.NPC_FILE = "mobile/space/kiizete.lua"
K.JAVA = "script/conversation/naboo_rebel_tier1_kiizete.java"

K.IMP_KEY = "VortexSquadronScreenplay:kiizeteImpIsAsking"
K.Q1_KEY = "VortexSquadronScreenplay:kiizeteQ1Discussed"
K.OBSERVER = { "VortexSquadronScreenplay", "onKiizeteLoggedOut" }

-- Appendix A
K.SCREENS = require("vortex_tier1_kiizete_screens_data")

function K.screenRow(id)
	for _, row in ipairs(K.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (61), sorted
function K.screenIds()
	local out = {}

	for i, row in ipairs(K.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

K.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		K.loadErrors[#K.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load order: V3-FX's pieces first (I.load), then Kiizete's template and handler. A missing production file is recorded in
-- K.loadErrors, not raised, so a red run fails on an assertion with the reason.
function K.load()
	if loaded then
		return
	end

	loaded = true
	I.load()

	try("kiizete_convo.lua", function() H.loadMobile("conversations/space/rebel/vortex_squadron/kiizete_convo.lua") end)
	try("kiizeteConvoHandler.lua", function() H.loadScreenplay("space/conversations/rebel/vortex_squadron/kiizeteConvoHandler.lua") end)
end

local function problems() return table.concat(K.loadErrors, " | ") end

-- Fails with the load problems when the template or handler could not be loaded
function K.requireConversation(lu)
	K.load()
	lu.assertNotNil(H.conversationTemplateTable(K.TEMPLATE), K.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. problems())
	lu.assertNotNil(rawget(_G, K.HANDLER), K.HANDLER .. " is not defined. Load problems: " .. problems())
end

local function requireLoaded()
	K.load()

	if H.conversationTemplateTable(K.TEMPLATE) == nil or rawget(_G, K.HANDLER) == nil then
		error("Kiizete's conversation is not loaded (feature vortex-tier1-kiizete). Load problems: " .. problems(), 3)
	end
end

function K.handler()
	requireLoaded()

	return rawget(_G, K.HANDLER)
end

function K.squadron() return H.expectGlobal("VortexSquadronScreenplay", "the Vortex squadron screenplay") end

---------------------------------------------------------------------------------------------
-- Players and NPC
---------------------------------------------------------------------------------------------

-- Options as vortex_tier1_data.lua V.pilot (pilot, faction, squadron, ship, paid, state, tier, graduated, inShip, zone ...).
function K.player(o) return I.pilot(o) end

-- Kiizete in the Moenia gazebo (naboo_moenia.lua:109)
function K.npc()
	return H.newNpc({ name = "Kiizete", zone = "naboo", x = 4766.36, z = 6.1, y = -4795.8, parentID = 0 })
end

-- The id of the screen getInitialScreen picks (side-effect free, I-3)
function K.gate(player)
	local screen = K.handler():getInitialScreen(player, K.npc(), H.conversationTemplate(K.TEMPLATE))

	if screen == nil then
		error("getInitialScreen returned no screen", 2)
	end

	return screen.id
end

-- Talks to Kiizete from the first screen; choices as for H.converse (reply sids, 0-based indexes, hooks)
function K.talk(player, choices)
	requireLoaded()

	return H.converse({ template = K.TEMPLATE, player = player, npc = K.npc(), choices = choices })
end

-- The id of the first screen of a talk (the on-display actions run: flags are set)
function K.opens(player) return K.talk(player)[1].id end

-- Starts a conversation as if the player had just chosen a link to screen `startId` (reaches screens no first screen leads to), then follows
-- `choices` like K.talk. The last screen of the session is the one shown, like the real session.
function K.drive(player, startId, choices)
	requireLoaded()

	local tmpl = H.conversationTemplate(K.TEMPLATE)
	local handler = rawget(_G, K.HANDLER)
	local npc = K.npc()
	local session = H.Fakes.newConversationSession(npc)
	local transcript = {}

	player.conversationSession = session

	local function show(screen)
		local options = {}

		for i, o in ipairs(screen.options) do
			options[i] = { text = o.text, link = o.link }
		end

		transcript[#transcript + 1] = { id = screen.id, text = screen.dialogText, options = options, params = screen.params, stop = screen.stopConversation }
	end

	local screen = LuaConversationTemplate(tmpl):getScreen(startId)

	if screen == nil then
		error("screen '" .. startId .. "' is not in " .. K.TEMPLATE, 2)
	end

	screen = handler:runScreenHandlers(tmpl, player, npc, 0, screen)

	if screen == nil then
		error("runScreenHandlers returned no screen for '" .. startId .. "'", 2)
	end

	session.lastScreen = screen
	show(screen)

	for _, choice in ipairs(choices or {}) do
		if screen.stopConversation then
			break
		end

		if type(choice) == "function" then
			choice(player)
		else
			if type(choice) == "string" then
				local found

				for k, o in ipairs(screen.options) do
					if o.text == choice or o.text:sub(-#choice - 1) == ":" .. choice then
						found = k - 1
						break
					end
				end

				if found == nil then
					error("screen '" .. screen.id .. "' has no option '" .. choice .. "'", 2)
				end

				choice = found
			end

			screen = handler:getNextConversationScreen(tmpl, player, choice, npc)

			if screen ~= nil then
				screen = handler:runScreenHandlers(tmpl, player, npc, choice, screen)
			end

			session.lastScreen = screen

			if screen == nil then
				break
			end

			show(screen)
		end
	end

	return transcript
end

function K.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- the reply sids ("s_xxx") of a transcript step, in order
function K.optionSids(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = tostring(o.text):match(":(s_[%w_]+)$") or tostring(o.text)
	end

	return out
end

function K.linksOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = o.link
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Session flags
---------------------------------------------------------------------------------------------

-- the raw shared-memory value of a flag (readData of <playerID> .. key)
function K.flagValue(player, key) return readData(player.objectID .. key) end

function K.observerCount(player)
	return H.Engine.observerCount(LOGGEDOUT, K.OBSERVER[1], K.OBSERVER[2], player)
end

function K.logout(player) return H.fireObservers(LOGGEDOUT, player) end

---------------------------------------------------------------------------------------------
-- Mission 1 states through the real quest tables (as test_vortex_tier1_signup_missions.lua)
---------------------------------------------------------------------------------------------

-- A pilot in a ship in space_naboo whose mission 1 was started by V3-FX's accept screen (the patrol is active, :attempted is set)
function K.runningMission1()
	local player = I.pilot({ inShip = true, zone = "space_naboo" })
	local q = I.quest(I.P1)

	q:start()
	I.drive(player, "m1_frontier")

	if I.state(player, I.P1) ~= "active" then
		error("precondition: V3-FX's accept screen did not start mission 1", 2)
	end

	return q, player
end

---------------------------------------------------------------------------------------------
-- Snapshots
---------------------------------------------------------------------------------------------

local function copy(v)
	if type(v) ~= "table" then
		return v
	end

	local out = {}

	for k, x in pairs(v) do
		out[k] = copy(x)
	end

	return out
end

local function count(t)
	local n = 0

	for _ in pairs(t or {}) do
		n = n + 1
	end

	return n
end

-- Everything a talk could change besides the two flag keys and the observer: the journal, quest status, skills, standing, credits, items,
-- datapad, pilot tier and every recorded engine call other than createObserver (the grants all record: awardSkill, giveItem, ...).
-- Returns { state = {...}, memory = {...}, observers = {...}, createObserverCalls = n }.
function K.snapshot(player)
	local g = player.ghost
	local calls = {}

	for _, c in ipairs(H.Engine.calls) do
		if c.fn ~= "createObserver" then
			calls[#calls + 1] = c.fn
		end
	end

	return {
		state = {
			journalActive = copy(g and g.journalActive),
			journalComplete = copy(g and g.journalComplete),
			taskActive = copy(g and g.taskActive),
			taskComplete = copy(g and g.taskComplete),
			factionStanding = copy(g and g.factionStanding),
			pilotTier = g and g.pilotTier,
			squadronType = g and g.squadronType,
			questStatus = copy(H.Fakes.questStatus),
			skills = copy(player.skills),
			bankCredits = player.bankCredits,
			inventoryItems = player.inventory and count(player.inventory.items) or 0,
			datapadItems = count(player.datapad and player.datapad.items),
			calls = calls,
		},
		memory = copy(H.Engine.sharedMemory),
		observers = H.Engine.observersOn(player),
		createObserverCalls = #H.Engine.callsTo("createObserver"),
	}
end

return K
