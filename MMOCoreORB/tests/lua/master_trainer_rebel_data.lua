-- Shared test data and builders for the Rebel master trainer (Admiral Willham Burke), not a test file.
-- Spec: .claude/work/space-master-trainer-rebel/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and D).
--
-- Scalars and screen rows are copied from the spec, not read from the production scripts, so a wrong production value fails a test instead
-- of agreeing with itself. The ship list of mission 1 is derived from the SWG .tab fixture by the Data mapping rule (shipList, top to bottom).
--   M.QUESTS / M.GLOBALS    the two quest globals and their literals (Content contract 1, Data mapping)
--   M.expected()            the whole table of each global, every key (a key not listed must not be set)
--   M.SCREENS               Appendix A (master_trainer_rebel_screens_data.lua, generated from the spec table)
--   M.paths(from)           every option path (reply sids) from a screen of Appendix A to an ending screen
--   M.load()                the server's load: the squadron files, MTS, the template, the handler (load errors collected)
--   M.pilot{...}            a pilot standing in front of Burke (see the option list at M.pilot)
--   M.talk / M.drive        H.converse from the first screen / from a given screen
--
-- Burke's conversation lives in the template "willham_burke_convo_template", its handler is the global "willhamBurkeConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")
local BE = require("black_epsilon_tier4_data")

local M = {}

M.TEMPLATE = "willham_burke_convo_template"
M.HANDLER = "willhamBurkeConvoHandler"
M.PREFIX = "@conversation/rebel_master_trainer:"
M.STF = "conversation/rebel_master_trainer"

M.TEMPLATE_FILE = "mobile/conversations/space/rebel/willham_burke_convo.lua"
M.HANDLER_FILE = "screenplays/space/conversations/rebel/willhamBurkeConvoHandler.lua"
M.MTS_FILE = "screenplays/space/squadrons/MasterTrainerScreenplay.lua"
M.NPC_FILE = "mobile/space/willham_burke.lua"

M.ZONE = "space_light1"

M.GLOBALS = { "destroy_master_rebel_1", "destroy_master_rebel_2" }

-- global -> { type, name, credits, item, kills }
M.QUESTS = {
	destroy_master_rebel_1 = {
		n = 1, type = "destroy", name = "master_rebel_1", credits = 25000, standing = 200,
		item = "object/tangible/wearables/jacket/jacket_ace_rebel.iff", kills = 30,
	},
	destroy_master_rebel_2 = {
		n = 2, type = "destroy", name = "master_rebel_2", credits = 50000, standing = 400,
		item = "object/tangible/wearables/helmet/helmet_fighter_rebel_ace.iff", kills = 1,
	},
}

-- Content contract 1: MasterTrainerScreenplay
M.MTS_CONSTANTS = {
	screenplayName = "MasterTrainerScreenplay",
	QUEST_STRING_IMPERIAL_1 = { type = "destroy", name = "master_imperial_1" },
	QUEST_STRING_IMPERIAL_2 = { type = "destroy", name = "master_imperial_2" },
	QUEST_STRING_REBEL_1 = { type = "destroy", name = "master_rebel_1" },
	QUEST_STRING_REBEL_2 = { type = "destroy", name = "master_rebel_2" },
	MASTER_MISSION_IMPERIAL_KEY = "MasterTrainerScreenplay:master_mission_imperial",
	MASTER_MISSION_REBEL_KEY = "MasterTrainerScreenplay:master_mission_rebel",
}

M.IMPERIAL_KEY = M.MTS_CONSTANTS.MASTER_MISSION_IMPERIAL_KEY
M.REBEL_KEY = M.MTS_CONSTANTS.MASTER_MISSION_REBEL_KEY

-- the 5 keys resetBurkeQuests removes (without the player id)
M.KEYS = {
	"master_rebel_1:attempted", "master_rebel_1:reward",
	"master_rebel_2:attempted", "master_rebel_2:reward",
	M.REBEL_KEY,
}

-- Declann's keys, which resetBurkeQuests must leave alone
M.IMPERIAL_KEYS = { "master_imperial_1:attempted", "master_imperial_1:reward", "master_imperial_2:attempted", "master_imperial_2:reward", M.IMPERIAL_KEY }

M.MASTER = "pilot_rebel_navy_master"
M.IMPERIAL_MASTER = "pilot_imperial_navy_master"
M.NEUTRAL_MASTER = "pilot_neutral_master"
M.REBEL_MASTER = "pilot_rebel_navy_master"

-- the missions as the handler sees them: n, head, status stem, the screens
M.MISSIONS = {
	{ n = 1, head = "destroy_master_rebel_1", status = "master_rebel_1", questString = "QUEST_STRING_REBEL_1", standing = 200, credits = 25000,
		item = M.QUESTS.destroy_master_rebel_1.item, failed = "m1_failed", reward = "m1_reward", starts = { "m1_accept", "m1_retry_a", "m1_retry_b" } },
	{ n = 2, head = "destroy_master_rebel_2", status = "master_rebel_2", questString = "QUEST_STRING_REBEL_2", standing = 400, credits = 50000,
		item = M.QUESTS.destroy_master_rebel_2.item, failed = "m2_failed", reward = "master_grant", starts = { "m2_accept", "m2_retry_a", "m2_retry_b" } },
}

-- the screens that start a mission (table H), screen -> n
M.STARTS = {
	m1_accept = 1, m1_retry_a = 1, m1_retry_b = 1,
	m2_accept = 2, m2_retry_a = 2, m2_retry_b = 2,
}

-- Appendix A
M.SCREENS = require("master_trainer_rebel_screens_data")

M.ROWS = {}

for _, row in ipairs(M.SCREENS) do
	M.ROWS[row.id] = row
end

-- Appendix B: the 46 STF lines this feature does not use (the privateer branch), sorted byte-wise
M.UNUSED = {
	"s_133c89f7", "s_16531693", "s_174c76a5", "s_24a07bd4", "s_26bd9f23", "s_2acaca5d", "s_35c0388d", "s_377d1a96", "s_3d93239d", "s_3f7dd52e",
	"s_4bdfa49b", "s_4ebc69dd", "s_52917b0d", "s_583fa6fb", "s_647683fc", "s_65a12a87", "s_684ff0a", "s_6be5ab4e", "s_6c42736d", "s_6daab4e1",
	"s_6ff4c6e1", "s_76d5f218", "s_77cd7306", "s_78ce5241", "s_84b47be3", "s_8964c03a", "s_8f3f7918", "s_92ad6ffe", "s_a7be18a9", "s_aa01a084",
	"s_be631237", "s_c10e0254", "s_c5b25047", "s_cd70bed3", "s_d1111dc8", "s_d41a131", "s_d646c11", "s_d7e71a00", "s_d8da45e7", "s_da2cf079",
	"s_dc2fa6d8", "s_e7f9b26f", "s_e8d6a9e7", "s_ecd272f1", "s_ee795f66", "s_efc8c4f5",
}

function M.screenIds()
	local out = {}

	for i, row in ipairs(M.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- Appendix D: one reply path per action screen (and the decline route) { screen, from, replies }; replies are sids with the s_ prefix
M.PATHS = {}

do
	local function add(screen, from, replies)
		local out = {}

		for i, r in ipairs(replies) do
			out[i] = "s_" .. r
		end

		M.PATHS[#M.PATHS + 1] = { screen = screen, from = from, replies = out }
	end

	add("m1_accept", "intro", { "81f189ef", "ad709e77", "32062da9", "85b8ffbd", "22d87576", "c97cb0b8", "6d976791", "1fd64638", "2cbd4ffa" })
	add("m1_retry_a", "m1_failed", { "4c9055c9", "e228ef89", "46ecd1ec" })
	add("m1_retry_b", "m1_failed", { "ed30fff8", "c788dadf" })
	add("m1_reward", "m1_won", { "d02bfc3b", "f00f629f", "7cbd5de5" })
	add("m2_accept", "m2_brief", { "c68b1dd3", "ca1a4aa4", "a6fb8def", "7a052bd2", "cba67818", "5bd6bf77" })
	add("m2_retry_a", "m2_failed", { "d4d47c04", "ce45643c" })
	add("m2_retry_b", "m2_failed", { "eb02d65", "c13f9a11" })
	add("master_grant", "m2_won", { "1da9fe53", "3f6a8711", "8d7967cc", "5869e64b" })
	add("decline", "intro", { "9a0798b3", "89f9ea03", "44bd3318", "4c9d51f4" })
end

-- Every option path (list of reply sids) from screen `from` of Appendix A down to a screen with no option; returns { { replies = {...}, ids = {...} } ... }
-- ids are the screens shown after `from`'s own, in order.
function M.paths(from)
	local out = {}

	local function visit(id, replies, ids)
		local row = M.ROWS[id]

		if #row.options == 0 then
			out[#out + 1] = { replies = replies, ids = ids }
			return
		end

		for _, o in ipairs(row.options) do
			local r, i = { table.unpack(replies) }, { table.unpack(ids) }

			r[#r + 1] = o[1]
			i[#i + 1] = o[2]
			visit(o[2], r, i)
		end
	end

	visit(from, {}, { from })

	return out
end

-- The fixture of a quest and the Data mapping rule (shipList: the non-empty cells, top to bottom)
function M.fixtureOf(global)
	local q = M.QUESTS[global]

	return (H.questFixture(q.type, q.name))
end

function M.shipList(global)
	return M.fixtureOf(global):list("shipList")
end

function M.expected()
	local out = {}

	for _, global in ipairs(M.GLOBALS) do
		local q = M.QUESTS[global]

		out[global] = {
			className = global, questType = q.type, questName = q.name, questZone = M.ZONE,
			creditReward = q.credits, itemReward = { { species = { -1 }, item = q.item } },
			sideQuest = false, sideQuestType = "", -- space-master-mission-quest-type: failOnLeaveZone is gone (SpaceMasterDestroyScreenplay never fails)
			killsRequired = q.kills, shipLocations = {},
			shipTypes = M.shipList(global),
		}
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

M.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		M.loadErrors[#M.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: the four squadron files (the Black Epsilon loader, which also loads Havoc), then MTS, Burke's template and handler. A missing
-- production file is recorded in M.loadErrors, not raised, so a red run reads "expected global X" with the reason. MTS loads after the squadron
-- files, as in screenplays.lua (it follows Storm's include).
function M.load()
	if loaded then
		return
	end

	loaded = true
	BE.load()

	try("MasterTrainerScreenplay.lua", function() H.loadSquadron("MasterTrainerScreenplay") end)
	try("willham_burke_convo.lua", function() H.loadMobile("conversations/space/rebel/willham_burke_convo.lua") end)
	try("willhamBurkeConvoHandler.lua", function() H.loadScreenplay("space/conversations/rebel/willhamBurkeConvoHandler.lua") end)
end

function M.problems() return table.concat(M.loadErrors, " | ") end

-- Fails with the load problems when the template or handler could not be loaded
function M.requireConversation(lu)
	M.load()
	lu.assertNotNil(H.conversationTemplateTable(M.TEMPLATE), M.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. M.problems())
	lu.assertNotNil(rawget(_G, M.HANDLER), M.HANDLER .. " is not defined. Load problems: " .. M.problems())
end

function M.quest(global)
	M.load()

	return H.expectGlobal(global, "master trainer quest table (space-master-trainer-rebel). Load problems: " .. M.problems())
end

function M.mts()
	M.load()

	return H.expectGlobal("MasterTrainerScreenplay", "MasterTrainerScreenplay (space-master-trainer-rebel). Load problems: " .. M.problems())
end

function M.handler()
	M.load()

	return H.expectGlobal(M.HANDLER, "handler (space-master-trainer-rebel). Load problems: " .. M.problems())
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local q = M.QUESTS[global]

	return H.questCrc(q.type, q.name)
end

M.crc = crc

-- Quest state helpers on a built pilot. state: "complete" | "active" | "none"
function M.setState(player, global, state)
	local key = crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function M.state(player, global)
	local key = crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

local TRAIN_ORDER = { "starships", "weapons", "procedures", "droid" }

local SQUADRONS = {
	black_epsilon = "BLACK_EPSILON_SQUADRON", storm = "STORM_SQUADRON", inquisition = "INQUISITION_SQUADRON",
	corsec = "CORSEC_SQUADRON", rsf = "RSF_SQUADRON", smuggler = "SMUGGLER_SQUADRON", havoc = "HAVOC_SQUADRON",
	vortex = "VORTEX_SQUADRON", crimson = "CRIMSON_PHOENIX_SQUADRON",
}

local DEFAULT_SQUADRON = { imperial = "black_epsilon", neutral = "corsec", rebel = "havoc" }

M.REBEL_SQUADRONS = { "havoc", "vortex", "crimson" }

-- The skills of a pilot of `kind` ("imperial" -> pilot_imperial_navy_*, "neutral" -> pilot_neutral_*, "rebel" -> pilot_rebel_navy_*): the novice box,
-- all of tiers 1 to 3, and the first `t4` of the four tier 4 skills (starships, weapons, procedures, droid)
function M.skillsOf(kind, t4)
	local stem = ({ imperial = "pilot_imperial_navy_", neutral = "pilot_neutral_", rebel = "pilot_rebel_navy_" })[kind]
	local skills = { stem .. "novice" }

	for tier = 1, 3 do
		for _, x in ipairs(TRAIN_ORDER) do
			skills[#skills + 1] = stem .. x .. "_0" .. tier
		end
	end

	for i = 1, t4 do
		skills[#skills + 1] = stem .. TRAIN_ORDER[i] .. "_04"
	end

	return skills
end

-- Options (all optional; the default is a Havoc pilot with the four _04 skills, Rebel standing 0, nothing of Burke's done):
--   kind       "rebel" (default) | "neutral" | "imperial" | false (not a pilot)
--   squadron   "havoc" | "vortex" | "crimson" | "black_epsilon" | "storm" | "inquisition" | "corsec" | "rsf" | "smuggler" | false (none); default by kind
--   t4         how many _04 skills of the kind the pilot holds, 0..4 (default 4)
--   master     the master skill of the kind is held
--   otherMaster  "neutral" | "imperial": a master skill of another kind is held as well
--   mission    { [n] = state } for n = 1, 2. "won": the head is complete and :attempted is set; "failed" / "attempted": :attempted only;
--              "active": :attempted and the head active; "paid": won and :reward set
--   paid       list of n whose reward is paid (won, :attempted and :reward)
--   keys       { rebel = true, imperial = true }: MASTER_MISSION_REBEL_KEY, MASTER_MISSION_IMPERIAL_KEY
--   standing   Rebel faction standing (default 0)
--   xp         space_combat_general experience (default 0)
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   other      true | { type, name }: a quest of another trainer (default Arkon's survival/corellia_rebel_tier4_1) active in the journal and held in the datapad
--   species    SPECIES_* (default SPECIES_HUMAN)
--   inventory  (default true) | false | { limit = n }; inventoryFull = true models a full inventory
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
--   zone       the zone name of a pilot in a ship
function M.pilot(o)
	o = o or {}
	M.load()

	local kind = o.kind

	if kind == nil then
		kind = "rebel"
	end

	local skills = {}

	if kind then
		skills = M.skillsOf(kind, o.t4 == nil and 4 or o.t4)
	end

	if o.master and kind then
		skills[#skills + 1] = ({ imperial = M.MASTER, neutral = M.NEUTRAL_MASTER, rebel = M.REBEL_MASTER })[kind]
	end

	if o.otherMaster then
		skills[#skills + 1] = ({ imperial = M.MASTER, neutral = M.NEUTRAL_MASTER, rebel = M.REBEL_MASTER })[o.otherMaster]
	end

	local squadron = o.squadron

	if squadron == nil then
		squadron = kind and DEFAULT_SQUADRON[kind] or false
	end

	local squadronType = squadron and rawget(_G, SQUADRONS[squadron]) or 0

	local completed, active, status = {}, {}, {}
	local states = {}

	for _, n in ipairs(o.paid or {}) do
		states[n] = "paid"
	end

	for n, state in pairs(o.mission or {}) do
		states[n] = state
	end

	for n, state in pairs(states) do
		local m = M.MISSIONS[n]

		status[m.status .. ":attempted"] = "1"

		if state == "paid" then
			status[m.status .. ":reward"] = "1"
		end

		if state == "won" or state == "paid" then
			completed[#completed + 1] = crc(m.head)
		elseif state == "active" then
			active[#active + 1] = crc(m.head)
		end
	end

	local keys = o.keys or {}

	if keys.rebel then
		status[M.REBEL_KEY] = "1"
	end

	if keys.imperial then
		status[M.IMPERIAL_KEY] = "1"
	end

	local player = H.newPlayer({
		name = "Ace",
		pilot = kind or nil,
		faction = (kind == "imperial") and FACTIONIMPERIAL or ((kind == "rebel" or o.rebelFaction) and FACTIONREBEL or 0),
		squadronType = squadronType,
		pilotTier = o.pilotTier or 5,
		certifiedShip = true,
		skills = skills,
		experience = { space_combat_general = o.xp or 0 },
		factionStanding = { imperial = 0, rebel = o.standing or 0 },
		completedQuests = completed,
		activeQuests = active,
		questStatus = status,
		species = o.species or SPECIES_HUMAN,
		gender = 0,
		inventory = (o.inventory ~= false) and (o.inventory or true) or nil,
		inventoryFull = o.inventoryFull,
		zone = o.zone,
		ship = o.inShip and (type(o.inShip) == "table" and o.inShip or true) or nil,
	})

	if o.datapad == "duty" then
		DRS.holdDuty(player, "held_by_test")
	elseif o.datapad == "story" then
		DRS.holdStory(player, "story_held_by_test")
	end

	if o.other then
		-- any quest of another trainer: active in the journal and held in the datapad
		local oq = type(o.other) == "table" and o.other or { "survival", "corellia_rebel_tier4_1" }

		player.ghost.journalActive[H.questCrc(oq[1], oq[2])] = true
		DRS.holdStory(player, "story_held_by_test")
	end

	return player
end

function M.npc() return H.newNpc({ name = "Admiral Willham Burke" }) end

function M.requireConversationLoaded()
	M.load()

	if H.conversationTemplateTable(M.TEMPLATE) == nil or rawget(_G, M.HANDLER) == nil then
		error("Burke's conversation is not loaded. Load problems: " .. M.problems(), 3)
	end
end

-- Talks to Burke from the first screen. choices as for H.converse.
function M.talk(player, choices)
	M.requireConversationLoaded()

	return H.converse({ template = M.TEMPLATE, player = player, npc = M.npc(), choices = choices })
end

-- The id of the first screen of a fresh talk
function M.firstScreen(player)
	return M.talk(player)[1].id
end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). The last screen of the session is the one shown, like the real session. runScreenHandlers runs on every screen shown.
function M.drive(player, startId, choices)
	M.requireConversationLoaded()

	local tmpl = H.conversationTemplate(M.TEMPLATE)
	local handler = rawget(_G, M.HANDLER)
	local npc = M.npc()
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
		error("screen '" .. startId .. "' is not in " .. M.TEMPLATE, 2)
	end

	screen = handler:runScreenHandlers(tmpl, player, npc, 0, screen)

	if screen == nil then
		error("runScreenHandlers returned no screen for '" .. startId .. "'", 2)
	end

	session.lastScreen = screen
	show(screen)

	local i = 1

	while i <= #(choices or {}) and not screen.stopConversation do
		local choice = choices[i]

		i = i + 1

		if type(choice) == "function" then
			choice(player)
		else
			if type(choice) == "string" then
				local found

				for k, opt in ipairs(screen.options) do
					if opt.text == choice or opt.text:sub(-#choice - 1) == ":" .. choice then
						found = k - 1
						break
					end
				end

				if found == nil then
					local have = {}

					for k, opt in ipairs(screen.options) do
						have[k] = tostring(opt.text)
					end

					error("screen '" .. screen.id .. "' has no option '" .. choice .. "'; options are: " .. table.concat(have, ", "), 2)
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

-- ids of a transcript
function M.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- Spies on the startQuest of the two quests (H.spyOn does not call the original); returns { [global] = calls }
function M.spyStarts()
	local spies = {}

	for _, g in ipairs(M.GLOBALS) do
		spies[g] = H.spyOn(M.quest(g), "startQuest")
	end

	return spies
end

-- the sorted list of globals whose startQuest was called, one entry per call
function M.started(spies)
	local out = {}

	for g, calls in pairs(spies) do
		for _ = 1, #calls do
			out[#out + 1] = g
		end
	end

	table.sort(out)
	return out
end

-- Records the calls of SpaceHelpers:grantSpaceSkill and runs the original. Call M.restore() in tearDown.
local restoreFns = {}

function M.recordGrants()
	local calls = {}
	local orig = SpaceHelpers.grantSpaceSkill

	SpaceHelpers.grantSpaceSkill = function(self, pPlayer, skill, deduct)
		calls[#calls + 1] = { skill = skill, deduct = deduct }

		return orig(self, pPlayer, skill, deduct)
	end

	restoreFns[#restoreFns + 1] = function() SpaceHelpers.grantSpaceSkill = orig end

	return calls
end

function M.restore()
	for _, fn in ipairs(restoreFns) do
		fn()
	end

	restoreFns = {}
end

-- giveItem calls on the player's inventory: the list of templates, and the argument counts
function M.itemsGiven(player)
	local out, argc = {}, {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory then
			out[#out + 1] = call[2]
			argc[#argc + 1] = call.n or #call
		end
	end

	return out, argc
end

function M.standing(player) return player.ghost.factionStanding.rebel end

return M
