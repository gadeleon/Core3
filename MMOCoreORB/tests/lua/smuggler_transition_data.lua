-- Shared test data and builders for the Smuggler transition (Talon Karrde, Mos Eisley), not a test file.
-- Spec: .claude/work/smuggler-transition-karrde/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B).
--
-- The quest values are DERIVED from the SWG-Source files in fixtures/ (T.expected): the two spacequest .tab files, the buildout excerpt
-- space_zones/buildout/space_lok.smuggler_transition_points.tab (truncated toward zero, as Core3's patrol point file holds them) and the Shamdon
-- script (the 5000 credits). Only what no SWG file decides (radius 150, failTimer 20, the class names) is a spec literal.
--   T.expected()               the whole table of each quest global (Appendix B: a key not listed must not be set)
--   T.SCREENS                  Appendix A (smuggler_transition_screens_data.lua)
--   T.load()                   the server's load of the squadrons, Dravis, Karrde's template and handler, collecting load errors
--   T.pilot{...}               a pilot standing in front of Karrde (see the option list at T.pilot)
--   T.talk / T.drive           H.converse from the first screen / from a given screen
--
-- Karrde's conversation lives in the template "talon_karrde_convo_template", its handler is the global "talonKarrdeConvoHandler".

local H = require("harness")
local S = require("smuggler_tier1_data")

local T = {}

T.TEMPLATE = "talon_karrde_convo_template"
T.HANDLER = "talonKarrdeConvoHandler"
T.PREFIX = "@conversation/tatooine_privateer_trainer_2:"
T.STF = "conversation/tatooine_privateer_trainer_2"

T.TEMPLATE_FILE = "mobile/conversations/space/neutral/smuggler_squadron/talon_karrde_convo.lua"
T.HANDLER_FILE = "screenplays/space/conversations/neutral/smuggler_squadron/talonKarrdeConvoHandler.lua"
T.SQUADRON_FILE = S.SQUADRON_FILE
T.NPC_FILE = "mobile/space/talon_karrde.lua"
T.INCLUDE_TEMPLATE = 'includeFile("conversations/space/neutral/smuggler_squadron/talon_karrde_convo.lua")'
T.INCLUDE_HANDLER = 'includeFile("space/conversations/neutral/smuggler_squadron/talonKarrdeConvoHandler.lua")'

T.PATROL = "patrol_tat_priv_quest_trans"
T.ASSASSINATE = "assassinate_tat_priv_quest_trans"
T.GLOBALS = { T.PATROL, T.ASSASSINATE }
T.NAME = "tat_priv_quest_trans"
T.ZONE = "space_lok"

-- global -> { class, type, name }
T.IDENTITY = {
	[T.PATROL] = { class = "SpacePatrolScreenplay", type = "patrol", name = T.NAME },
	[T.ASSASSINATE] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = T.NAME },
}

-- Content contract 2
T.QUEST_STRINGS = {
	QUEST_STRING_TRANS = { type = "patrol", name = T.NAME },
	QUEST_STRING_TRANS_SIDE = { type = "assassinate", name = T.NAME },
}

-- the two persisted status keys (suffixes of <objectID>); only Shamdon (next feature) writes :reward
T.ATTEMPTED = T.NAME .. ":attempted"
T.REWARD = T.NAME .. ":reward"
T.STATUS_KEYS = { T.ATTEMPTED, T.REWARD }

-- the quest globals of Karrde's lines, by the K row that reads them
T.SHAMDON_PAYS = 5000

T.SCREENS = require("smuggler_transition_screens_data")

function T.screenRow(id)
	for _, row in ipairs(T.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (21), sorted
function T.screenIds()
	local out = {}

	for i, row in ipairs(T.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- Appendix A, "Deferred ids (18)": the hub branches no pilot can reach yet; none may appear in this feature's files
T.DEFERRED_IDS = {
	"s_697e04cf", "s_98893f74", "s_fa31c92f", "s_de9b68cd", "s_7642f4a4", "s_805cb6f3", "s_9504aca1",
	"s_74bf2381", "s_9fcfc09a", "s_800d8ca1", "s_de0bf763", "s_a89cdefd", "s_238f162d", "s_415dfb0e", "s_a134e447", "s_e8ed6f9a", "s_aa257bf2",
	"s_2d0c7400",
}

-- the ids this feature uses: the dialog of every screen and every reply of Appendix A (35)
function T.usedIds()
	local set = {}

	for _, row in ipairs(T.SCREENS) do
		set[row.sid] = true

		for _, o in ipairs(row.options) do
			set[o[1]] = true
		end
	end

	local out = {}

	for id in pairs(set) do
		out[#out + 1] = id
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- The oracle: values from the SWG-Source fixtures
---------------------------------------------------------------------------------------------

local function trunc(v) return v >= 0 and math.floor(v) or -math.floor(-v) end

local function readFile(path)
	local f = io.open(path, "r")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()
	return text
end

T.readFile = readFile

-- nav point name -> { x, z, y } of the buildout excerpt (fltPX, fltPY, fltPZ truncated toward zero: the Core3 point files' values)
function T.buildout()
	local tab = H.fixture("space_zones/buildout/space_lok.smuggler_transition_points.tab")
	local out = {}

	for _, rec in ipairs(tab.records) do
		local nav = (rec:get("strObjVars") or ""):match("nav_name|4|([^|]+)|")

		if nav ~= nil then
			out[nav] = { trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ")) }
		end
	end

	return out
end

-- the credits Shamdon pays for the transition: SHJ giveReward(player, "assassinate", "tat_priv_quest_trans", N)
function T.shamdonReward()
	local java = readFile(H.FIXTURES .. "script/conversation/tatooine_privateer_trainer_shamdon.java")

	if java == nil then
		return nil
	end

	return tonumber(java:match('giveReward%(player, "assassinate", "' .. T.NAME .. '", (%d+)%)'))
end

function T.patrolFixture() return H.questFixture("patrol", T.NAME) end
function T.assassinateFixture() return H.questFixture("assassinate", T.NAME) end

-- Points of a .tab column: { name, zone, x, z, y } from the buildout excerpt
function T.pointsOf(rec, column)
	local nav = T.buildout()
	local out = {}

	for i, value in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(value)
		local xyz = nav[name]

		assert(xyz ~= nil, "the buildout excerpt has no nav point " .. tostring(name))
		out[i] = { name = name, zone = zone, x = xyz[1], z = xyz[2], y = xyz[3] }
	end

	return out
end

-- Data mapping 1, derived from the fixtures. Returns { [global] = whole table }.
function T.expected()
	local SPLIT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES
	local pat, asn = T.patrolFixture(), T.assassinateFixture()
	local splitType, splitName = H.Tab.splitQuestRef(pat:get("triggerArg"))
	local condition = ({ success = SPLIT.COMPLETION, failure = SPLIT.FAILURE, both = SPLIT.BIDIRECTIONAL })[pat:get("triggerSplitCondition")]

	local patrolPoints = {}

	for i, p in ipairs(T.pointsOf(pat, "navPoints")) do
		patrolPoints[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, patrolNumber = i, radius = 150 }
	end

	local targetPatrols = {}

	for i, p in ipairs(T.pointsOf(asn, "escortPath")) do
		targetPatrols[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y }
	end

	return {
		[T.PATROL] = {
			className = T.PATROL, questName = T.NAME, questType = "patrol", questZone = pat:get("questZone"),
			sideQuest = pat:get("triggerEvent") == "splitquest", sideQuestType = splitType, sideQuestName = splitName,
			sideQuestSplitType = condition, sideQuestDelay = pat:num("triggerDelay"),
			patrolPoints = patrolPoints,
		},
		[T.ASSASSINATE] = {
			className = T.ASSASSINATE, questName = T.NAME, questType = "assassinate", questZone = asn:get("questZone"),
			creditReward = T.shamdonReward(),
			parentQuest = T.PATROL, parentQuestType = "patrol", parentQuestName = T.NAME,
			sideQuest = false, sideQuestType = "",
			arrivalDelay = asn:num("targetArrivalDelay"), failTimer = 20, mustDestroyEscort = asn:num("mustDestroyEscort") == 1,
			assassinateSpawns = { target = asn:get("targetShipType"), escorts = asn:list("targetEscort") },
			targetPatrols = targetPatrols,
		},
	}
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

T.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		T.loadErrors[#T.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: the squadron files and Dravis (smuggler_tier1_data.lua), then Karrde's template and handler. A missing production file is
-- recorded in T.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function T.load()
	if loaded then
		return
	end

	loaded = true
	S.load()

	for _, e in ipairs(S.loadErrors) do
		T.loadErrors[#T.loadErrors + 1] = e
	end

	try("talon_karrde_convo.lua", function() H.loadMobile("conversations/space/neutral/smuggler_squadron/talon_karrde_convo.lua") end)
	try("talonKarrdeConvoHandler.lua", function() H.loadScreenplay("space/conversations/neutral/smuggler_squadron/talonKarrdeConvoHandler.lua") end)
end

function T.problems() return table.concat(T.loadErrors, " | ") end

-- Fails with the load problems when the template or handler could not be loaded
function T.requireConversation(lu)
	T.load()
	lu.assertNotNil(H.conversationTemplateTable(T.TEMPLATE), T.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. T.problems())
	lu.assertNotNil(rawget(_G, T.HANDLER), T.HANDLER .. " is not defined. Load problems: " .. T.problems())
end

function T.quest(global)
	T.load()

	return H.expectGlobal(global, "Smuggler transition quest table (smuggler-transition-karrde). Load problems: " .. T.problems())
end

-- the squadron object (SmugglerSquadronScreenplay), with the load problems in the failure message
function T.squadron()
	T.load()

	return H.expectGlobal("SmugglerSquadronScreenplay", "Smuggler squadron screenplay object. Load problems: " .. T.problems())
end

function T.handler() return rawget(_G, T.HANDLER) end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = T.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

T.crc = crc

-- state: "complete" | "active" | "none"
function T.setState(player, global, state)
	local key = crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function T.state(player, global)
	local key = crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- The transition states of a pilot (journal + :attempted), by name:
--   none           nothing (Karrde has never been asked)
--   attempted      :attempted only (nothing in the journal): a failed or aborted chain
--   active         :attempted, the patrol active
--   child_active   :attempted, the patrol complete, the assassinate active
--   patrol_only    :attempted, the patrol complete, the assassinate never started (a stop inside the 2.1 s split window)
--   won            :attempted, both complete
local STATES = {
	none = {},
	attempted = { attempted = true },
	active = { attempted = true, patrol = "active" },
	child_active = { attempted = true, patrol = "complete", assassinate = "active" },
	patrol_only = { attempted = true, patrol = "complete" },
	won = { attempted = true, patrol = "complete", assassinate = "complete" },
}

T.STATE_NAMES = { "none", "attempted", "active", "child_active", "patrol_only", "won" }

-- Options (all optional; the default is a Smuggler with all four tier 1 skills, pilot tier 2, Dravis' missions paid, no transition state):
--   trans      one of T.STATE_NAMES (default "none")
--   rewarded   true: the :reward key is set (Shamdon paid)
--   and every S.pilot option (squadron, pilot, faction, tier, paid, ship, datapad, duty, zone, inShip, ...); tier = n sets the tier 1 skills held
function T.pilot(o)
	o = o or {}
	T.load()

	local so = {}

	for k, v in pairs(o) do
		if k ~= "trans" and k ~= "rewarded" then
			so[k] = v
		end
	end

	if so.tier == nil then
		so.tier = 4
	end

	if so.paid == nil then
		so.paid = 4
	end

	if so.pilotTier == nil then
		so.pilotTier = 2
	end

	local player = S.pilot(so)
	local st = STATES[o.trans or "none"]

	assert(st ~= nil, "unknown transition state " .. tostring(o.trans))

	if st.attempted then
		H.setQuestStatus(player, T.ATTEMPTED, 1)
	end

	if st.patrol then
		T.setState(player, T.PATROL, st.patrol)
	end

	if st.assassinate then
		T.setState(player, T.ASSASSINATE, st.assassinate)
	end

	if o.rewarded then
		H.setQuestStatus(player, T.REWARD, 1)
	end

	return player
end

function T.npc() return H.newNpc({ name = "Talon Karrde" }) end

function T.requireConversationLoaded()
	T.load()

	if H.conversationTemplateTable(T.TEMPLATE) == nil or rawget(_G, T.HANDLER) == nil then
		error("Karrde's conversation is not loaded. Load problems: " .. T.problems(), 3)
	end
end

-- Talks to Karrde from the first screen. choices as for H.converse.
function T.talk(player, choices)
	T.requireConversationLoaded()

	return H.converse({ template = T.TEMPLATE, player = player, npc = T.npc(), choices = choices })
end

-- The id of the first screen of a fresh talk
function T.firstScreen(player)
	return T.talk(player)[1].id
end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). Reaches screens no first screen leads to.
function T.drive(player, startId, choices)
	T.requireConversationLoaded()

	local tmpl = H.conversationTemplate(T.TEMPLATE)
	local handler = rawget(_G, T.HANDLER)
	local npc = T.npc()
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
		error("screen '" .. startId .. "' is not in " .. T.TEMPLATE, 2)
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

				for k, o in ipairs(screen.options) do
					if o.text == choice or o.text:sub(-#choice - 1) == ":" .. choice then
						found = k - 1
						break
					end
				end

				if found == nil then
					local have = {}

					for k, o in ipairs(screen.options) do
						have[k] = tostring(o.text)
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

T.ids = S.ids
T.optionSids = S.optionSids
T.linksOf = S.linksOf

-- the walks from `summons` to `job_details`: 2 openings x 4 Nym routes (Conversation flow 4). Each: { name, replies, ids }
T.ROUTES = {}

local OPENINGS = {
	{ "busy", "s_c3c2195b", "summons_busy" },
	{ "fast", "s_3f10da9d", "summons_fast" },
}

local NYM = {
	{ "never_heard_feeorin", { "s_e70a45c9", "s_25e48bc1", "s_db4bd0fd" }, { "nym_unknown", "nym_feeorin", "job_details" } },
	{ "never_heard_say_no_more", { "s_e70a45c9", "s_9cf1e4c3", "s_db4bd0fd" }, { "nym_unknown", "nym_say_no_more", "job_details" } },
	{ "knows_him", { "s_365a729a", "s_db4bd0fd" }, { "nym_known", "job_details" } },
	{ "he_hates_me", { "s_ba9fbfb1", "s_db4bd0fd" }, { "nym_hates", "job_details" } },
}

for _, opening in ipairs(OPENINGS) do
	for _, nym in ipairs(NYM) do
		local replies = { opening[2], "s_1c8bddbb" }
		local ids = { "summons", opening[3], "job_lok" }

		for _, r in ipairs(nym[2]) do
			replies[#replies + 1] = r
		end

		for _, id in ipairs(nym[3]) do
			ids[#ids + 1] = id
		end

		T.ROUTES[#T.ROUTES + 1] = { name = opening[1] .. "_" .. nym[1], replies = replies, ids = ids }
	end
end

return T
