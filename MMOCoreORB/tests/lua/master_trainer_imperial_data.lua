-- Shared test data and builders for the Imperial master trainer (Grand Admiral Nial Declann), not a test file.
-- Spec: .claude/work/space-master-trainer-imperial/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and D).
--
-- Scalars and screen rows are copied from the spec, not read from the production scripts, so a wrong production value fails a test instead
-- of agreeing with itself. The ship list of mission 1 is derived from the SWG .tab fixture by the Data mapping rule (shipList, top to bottom).
--   M.QUESTS / M.GLOBALS    the two quest globals and their literals (Content contract 1, Data mapping)
--   M.expected()            the whole table of each global, every key (a key not listed must not be set)
--   M.SCREENS               Appendix A (master_trainer_imperial_screens_data.lua, generated from the spec table)
--   M.paths(from)           every option path (reply sids) from a screen of Appendix A to an ending screen
--   M.load()                the server's load: the squadron files, MTS, the template, the handler (load errors collected)
--   M.pilot{...}            a pilot standing in front of Declann (see the option list at M.pilot)
--   M.talk / M.drive        H.converse from the first screen / from a given screen
--
-- Declann's conversation lives in the template "nial_declann_convo_template", its handler is the global "nialDeclannConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")
local BE = require("black_epsilon_tier4_data")

local M = {}

M.TEMPLATE = "nial_declann_convo_template"
M.HANDLER = "nialDeclannConvoHandler"
M.PREFIX = "@conversation/imperial_master_trainer:"
M.STF = "conversation/imperial_master_trainer"

M.TEMPLATE_FILE = "mobile/conversations/space/imperial/nial_declann_convo.lua"
M.HANDLER_FILE = "screenplays/space/conversations/imperial/nialDeclannConvoHandler.lua"
M.MTS_FILE = "screenplays/space/squadrons/MasterTrainerScreenplay.lua"
M.NPC_FILE = "mobile/space/nial_declann.lua"

M.ZONE = "space_light1"

M.GLOBALS = { "destroy_master_imperial_1", "destroy_master_imperial_2" }

-- global -> { type, name, credits, item, kills }
M.QUESTS = {
	destroy_master_imperial_1 = {
		n = 1, type = "destroy", name = "master_imperial_1", credits = 25000, standing = 200,
		item = "object/tangible/wearables/jacket/jacket_ace_imperial.iff", kills = 30,
	},
	destroy_master_imperial_2 = {
		n = 2, type = "destroy", name = "master_imperial_2", credits = 50000, standing = 400,
		item = "object/tangible/wearables/helmet/helmet_fighter_imperial_ace.iff", kills = 1,
	},
}

-- Content contract 1: MasterTrainerScreenplay
M.MTS_CONSTANTS = {
	screenplayName = "MasterTrainerScreenplay",
	QUEST_STRING_IMPERIAL_1 = { type = "destroy", name = "master_imperial_1" },
	QUEST_STRING_IMPERIAL_2 = { type = "destroy", name = "master_imperial_2" },
	MASTER_MISSION_IMPERIAL_KEY = "MasterTrainerScreenplay:master_mission_imperial",
	MASTER_MISSION_REBEL_KEY = "MasterTrainerScreenplay:master_mission_rebel",
}

M.IMPERIAL_KEY = M.MTS_CONSTANTS.MASTER_MISSION_IMPERIAL_KEY
M.REBEL_KEY = M.MTS_CONSTANTS.MASTER_MISSION_REBEL_KEY

-- the 5 keys resetDeclannQuests removes (without the player id)
M.KEYS = {
	"master_imperial_1:attempted", "master_imperial_1:reward",
	"master_imperial_2:attempted", "master_imperial_2:reward",
	M.IMPERIAL_KEY,
}

M.MASTER = "pilot_imperial_navy_master"
M.NEUTRAL_MASTER = "pilot_neutral_master"
M.REBEL_MASTER = "pilot_rebel_navy_master"
M.NIN_KEY = BE.DECLANN_SUFFIX

-- the missions as the handler sees them: n, head, status stem, the screens
M.MISSIONS = {
	{ n = 1, head = "destroy_master_imperial_1", status = "master_imperial_1", questString = "QUEST_STRING_IMPERIAL_1", standing = 200, credits = 25000,
		item = M.QUESTS.destroy_master_imperial_1.item, failed = "m1_failed", reward = "m1_reward", starts = { "m1_accept", "m1_retry_a", "m1_retry_b" } },
	{ n = 2, head = "destroy_master_imperial_2", status = "master_imperial_2", questString = "QUEST_STRING_IMPERIAL_2", standing = 400, credits = 50000,
		item = M.QUESTS.destroy_master_imperial_2.item, failed = "m2_failed", reward = "master_grant", starts = { "m2_accept", "m2_retry_a", "m2_retry_b" } },
}

-- the screens that start a mission (table H), screen -> n
M.STARTS = {
	m1_accept = 1, m1_retry_a = 1, m1_retry_b = 1,
	m2_accept = 2, m2_retry_a = 2, m2_retry_b = 2,
}

-- Appendix A
M.SCREENS = require("master_trainer_imperial_screens_data")

M.ROWS = {}

for _, row in ipairs(M.SCREENS) do
	M.ROWS[row.id] = row
end

-- Appendix B: the 81 STF lines this feature does not use (the privateer branch of Q-1 plus s_85b8ffbd), sorted byte-wise
M.UNUSED = {
	"s_110667a0", "s_15f15e84", "s_16374fa8", "s_1837e4aa", "s_19aeaf5e", "s_1ae97099", "s_1aff8b69", "s_1be63a5a", "s_1df5b492", "s_22dd5c33",
	"s_24077de7", "s_26e02f1d", "s_2bd3a43c", "s_308a9ab1", "s_30f24d", "s_33d1d488", "s_36e64ebe", "s_3d30040d", "s_4041b73c", "s_47cf08a2",
	"s_4fb6fb91", "s_50e3a94f", "s_52c03f61", "s_58a058a9", "s_5ac61a82", "s_5d0b4f6b", "s_5fca12da", "s_60d3f4f8", "s_63462bcc", "s_63f7aad9",
	"s_65031818", "s_65d9bf6c", "s_6844241f", "s_6c92dab", "s_732a67f3", "s_78dfc859", "s_794642f2", "s_7964ad2d", "s_7b3a873", "s_7cc631fe",
	"s_7eeb4f8c", "s_8409f60e", "s_85b8ffbd", "s_87ccb642", "s_88eb64f3", "s_8c202f75", "s_8db79f00", "s_8efde2ae", "s_8f760eed", "s_913ac8c9",
	"s_92172df0", "s_9bbd1090", "s_9e28d2b0", "s_a15a9037", "s_a2bd8a18", "s_a340005a", "s_a622496d", "s_ace4b0c3", "s_af2fc12f", "s_ba2453bc",
	"s_baca5aeb", "s_bb9e4a63", "s_bc9b4055", "s_bcb643d", "s_bd095033", "s_c38038fe", "s_c5aa2921", "s_c92b41e9", "s_ca9b9b68", "s_cf1c32cf",
	"s_e685629c", "s_e9aec8d7", "s_eb171ae9", "s_ebd84e91", "s_ecdec8ad", "s_ef6b4924", "s_f352e00f", "s_f85f5c9d", "s_f9df4c83", "s_fd386cda",
	"s_fd661a34",
}

function M.screenIds()
	local out = {}

	for i, row in ipairs(M.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- Appendix D: one reply path per action screen { screen, from, replies }; replies are sids with the s_ prefix
M.PATHS = {}

do
	local function add(screen, from, replies)
		local out = {}

		for i, r in ipairs(replies) do
			out[i] = "s_" .. r
		end

		M.PATHS[#M.PATHS + 1] = { screen = screen, from = from, replies = out }
	end

	add("m1_accept", "intro", { "6b18cf1e", "26c66fd1", "5bed3d33", "78edd4f", "98790879", "19377f3b", "78d92576", "cbf5f6bc" })
	add("m1_retry_a", "m1_failed", { "fc42e227", "862d3332" })
	add("m1_retry_b", "m1_failed", { "a460d610", "c788dadf" })
	add("m1_reward", "m1_won", { "3876be4f", "a8ea09e9" })
	add("m2_accept", "m2_brief", { "5d519e4c", "77e59fd7", "6b581019", "f2ba71dd" })
	add("m2_retry_a", "m2_failed", { "21a81b0b", "bb68f6ed" })
	add("m2_retry_b", "m2_failed", { "eb02d65", "c13f9a11" })
	add("master_grant", "m2_won", { "f010d9ab", "2f52e0af", "beb9353a" })
	add("master_grant", "m2_won", { "f010d9ab", "6aa8adaf", "6a66a025", "377d1a96" })
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

-- The server's load: the four squadron files and Nin Gursawe (the Black Epsilon loader), then MTS, Declann's template and handler. A missing
-- production file is recorded in M.loadErrors, not raised, so a red run reads "expected global X" with the reason. MTS loads after the squadron
-- files, as in screenplays.lua (it follows Storm's include).
function M.load()
	if loaded then
		return
	end

	loaded = true
	BE.load()

	try("MasterTrainerScreenplay.lua", function() H.loadSquadron("MasterTrainerScreenplay") end)
	try("nial_declann_convo.lua", function() H.loadMobile("conversations/space/imperial/nial_declann_convo.lua") end)
	try("nialDeclannConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/nialDeclannConvoHandler.lua") end)
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

	return H.expectGlobal(global, "master trainer quest table (space-master-trainer-imperial). Load problems: " .. M.problems())
end

function M.mts()
	M.load()

	return H.expectGlobal("MasterTrainerScreenplay", "MasterTrainerScreenplay (space-master-trainer-imperial). Load problems: " .. M.problems())
end

function M.handler()
	M.load()

	return H.expectGlobal(M.HANDLER, "handler (space-master-trainer-imperial). Load problems: " .. M.problems())
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
}

local DEFAULT_SQUADRON = { imperial = "black_epsilon", neutral = "corsec", rebel = "havoc" }

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

-- Options (all optional; the default is a Black Epsilon pilot with the four _04 skills, standing 0, in a ship, nothing of Declann's done):
--   kind       "imperial" (default) | "neutral" | "rebel" | false (not a pilot)
--   squadron   "black_epsilon" | "storm" | "inquisition" | "corsec" | "rsf" | "smuggler" | "havoc" | false (none); default by kind
--   t4         how many _04 skills of the kind the pilot holds, 0..4 (default 4)
--   master     the master skill of the kind is held
--   otherMaster  "neutral" | "imperial" | "rebel": a master skill of another kind is held as well
--   mission    { [n] = state } for n = 1, 2. "won": the head is complete and :attempted is set; "failed" / "attempted": :attempted only;
--              "active": :attempted and the head active; "paid": won and :reward set
--   paid       list of n whose reward is paid (won, :attempted and :reward)
--   keys       { rebel = true, imperial = true, nin = true }: MASTER_MISSION_REBEL_KEY, MASTER_MISSION_IMPERIAL_KEY, Nin's Declann key
--   standing   Imperial faction standing (default 0)
--   xp         space_combat_general experience (default 0)
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   other      global of a quest of another trainer active in the journal and held in the datapad (a duty of another trainer)
--   species    SPECIES_* (default SPECIES_HUMAN)
--   inventory  (default true) | false | { limit = n }; inventoryFull = true models a full inventory
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
--   zone       the zone name of a pilot in a ship
function M.pilot(o)
	o = o or {}
	M.load()

	local kind = o.kind

	if kind == nil then
		kind = "imperial"
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

	if keys.nin then
		status[M.NIN_KEY] = "1"
	end

	local player = H.newPlayer({
		name = "Ace",
		pilot = kind or nil,
		faction = (kind == "imperial" or o.imperialFaction) and FACTIONIMPERIAL or ((kind == "rebel") and FACTIONREBEL or 0),
		squadronType = squadronType,
		pilotTier = o.pilotTier or 5,
		certifiedShip = true,
		skills = skills,
		experience = { space_combat_general = o.xp or 0 },
		factionStanding = { imperial = o.standing or 0, rebel = 0 },
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
		player.ghost.journalActive[BE.crc(o.other)] = true
		DRS.holdStory(player, "story_held_by_test")
	end

	return player
end

function M.npc() return H.newNpc({ name = "Grand Admiral Nial Declann" }) end

function M.requireConversationLoaded()
	M.load()

	if H.conversationTemplateTable(M.TEMPLATE) == nil or rawget(_G, M.HANDLER) == nil then
		error("Declann's conversation is not loaded. Load problems: " .. M.problems(), 3)
	end
end

-- Talks to Declann from the first screen. choices as for H.converse.
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

function M.standing(player) return player.ghost.factionStanding.imperial end

return M
