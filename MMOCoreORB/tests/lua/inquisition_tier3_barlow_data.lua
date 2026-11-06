-- Shared test data and builders for Inquisition tier 3, Lt. Colonel Barlow's interrogation, not a test file.
-- Spec: .claude/work/inquisition-tier3-barlow/01-spec.md (Content contract, Conversation flow, Appendix A).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of agreeing with itself:
--   B.SCREENS            Appendix A (inquisition_tier3_barlow_screens_data.lua, generated from the spec table by a scratch script)
--   B.WALKS              the shortest walks of the test strategy hints, one per end screen (reply sids, "s_" included)
--   B.END_SCREENS        the five screens whose display runs J3B's removeTalktoBarlow
--   B.load()             the server's load: the Vrke test data's load (squadron files, Barn, Fa'Zoll and Vrke) plus Barlow's template and handler, collecting load errors
--   B.pilot{...}         a pilot standing in front of Barlow: inquisition_tier3_data.lua's V.pilot (options: question, spoke, standing, pilot, faction, squadron, ...)
--   B.talk / B.firstScreen   H.converse with Barlow from the first screen
--   B.spyWrites()        records every setQuestStatus / removeQuestStatus call (I-5)
--
-- Barlow's conversation lives in the template "barlow_convo_template", its handler is the global "barlowConvoHandler".

local H = require("harness")
local V = require("inquisition_tier3_data")

local B = {}

B.TEMPLATE = "barlow_convo_template"
B.HANDLER = "barlowConvoHandler"
B.STF = "conversation/naboo_imperial_tier3_barlow"
B.PREFIX = "@conversation/naboo_imperial_tier3_barlow:"

B.TEMPLATE_FILE = "mobile/conversations/space/imperial/inquisition_squadron/barlow_convo.lua"
B.HANDLER_FILE = "screenplays/space/conversations/imperial/inquisition_squadron/barlowConvoHandler.lua"
B.NPC_FILE = "mobile/space/barlow.lua"
B.J3B_FILE = H.FIXTURES .. "script/conversation/naboo_imperial_tier3_barlow.java"

B.QUESTION_SUFFIX = V.QUESTION_SUFFIX
B.SPOKE_SUFFIX = V.SPOKE_SUFFIX

B.SCREENS = require("inquisition_tier3_barlow_screens_data")

B.GATES = { "restricted", "interview", "already_spoke", "not_requested" }
B.END_SCREENS = { "end_65ec117a", "end_3be36a24", "end_4ccd5b75", "end_7ebbd888", "end_2b71207d" }

-- Test strategy hints: the shortest walks from `interview` (reply sids) to each end screen
B.WALKS = {
	end_2b71207d = { "s_40f102e4", "s_28a49383", "s_15fccf52", "s_6f94037e", "s_35f73adf", "s_c3185891", "s_45ebf891", "s_ea32ea5a" },
	end_7ebbd888 = { "s_40f102e4", "s_28a49383", "s_15fccf52", "s_6f94037e", "s_35f73adf", "s_14c38c33", "s_797cf757", "s_62adf222", "s_1b131a47" },
	end_65ec117a = { "s_ca59425a", "s_f9e3a71b", "s_3700f6", "s_fa3924b4", "s_d5ad0fe2", "s_8fa4c7bd", "s_85c0a145", "s_c37cc43f", "s_cd0207ad", "s_749aece", "s_2e851dd5" },
	end_3be36a24 = { "s_ca59425a", "s_f9e3a71b", "s_3700f6", "s_fa3924b4", "s_d5ad0fe2", "s_8fa4c7bd", "s_85c0a145", "s_c37cc43f", "s_cd0207ad", "s_749aece", "s_c346ae59" },
	end_4ccd5b75 = { "s_ca59425a", "s_f9e3a71b", "s_3700f6", "s_fa3924b4", "s_d5ad0fe2", "s_8fa4c7bd", "s_85c0a145", "s_c37cc43f", "s_cd0207ad", "s_749aece", "s_110ac144" },
}

local byId = {}

for i, row in ipairs(B.SCREENS) do
	byId[row.id] = row
	row.index = i
end

function B.screenRow(id) return byId[id] end

-- the ids in Appendix A order
function B.orderedIds()
	local out = {}

	for i, row in ipairs(B.SCREENS) do
		out[i] = row.id
	end

	return out
end

function B.isEnd(id)
	for _, e in ipairs(B.END_SCREENS) do
		if e == id then
			return true
		end
	end

	return false
end

-- Shortest reply paths from `interview` to every screen reachable from it, over Appendix A: { [id] = { reply sids } }, and the ids in discovery order
function B.paths()
	local paths, order = { interview = {} }, { "interview" }
	local queue, head = { "interview" }, 1

	while head <= #queue do
		local id = queue[head]

		head = head + 1

		for _, o in ipairs(byId[id].options) do
			if paths[o[2]] == nil then
				local p = { table.unpack(paths[id]) }

				p[#p + 1] = o[1]
				paths[o[2]] = p
				order[#order + 1] = o[2]
				queue[#queue + 1] = o[2]
			end
		end
	end

	return paths, order
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

B.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		B.loadErrors[#B.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: everything V.load() loads, then Barlow's template and handler. A missing production file is recorded in B.loadErrors, not
-- raised, so the tests of a red run fail on an assertion with the reason.
function B.load()
	V.load()

	if loaded then
		return
	end

	loaded = true
	try("barlow_convo.lua", function() H.loadMobile("conversations/space/imperial/inquisition_squadron/barlow_convo.lua") end)
	try("barlowConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/inquisition_squadron/barlowConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function B.requireConversation(lu)
	B.load()
	lu.assertNotNil(H.conversationTemplateTable(B.TEMPLATE), B.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. table.concat(B.loadErrors, " | "))
	lu.assertNotNil(rawget(_G, B.HANDLER), B.HANDLER .. " is not defined. Load problems: " .. table.concat(B.loadErrors, " | "))
end

---------------------------------------------------------------------------------------------
-- Pilots and talking
---------------------------------------------------------------------------------------------

function B.pilot(o) return V.pilot(o) end

function B.npc() return H.newNpc({ name = "Barlow" }) end

-- Talks to Barlow from the first screen. choices as for H.converse (reply sids, 0-based indexes, hooks).
function B.talk(player, choices)
	return H.converse({ template = B.TEMPLATE, player = player, npc = B.npc(), choices = choices })
end

function B.firstScreen(player) return B.talk(player)[1].id end

function B.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

function B.keys(player)
	return { question = H.getQuestStatus(player, B.QUESTION_SUFFIX), spoke = H.getQuestStatus(player, B.SPOKE_SUFFIX) }
end

-- Wraps setQuestStatus / removeQuestStatus; returns the log ({ { op, key, value } ... }) and a restore function.
function B.spyWrites()
	local log = {}
	local set, remove = setQuestStatus, removeQuestStatus

	setQuestStatus = function(key, value)
		log[#log + 1] = { "set", key, tostring(value) }

		return set(key, value)
	end

	removeQuestStatus = function(key)
		log[#log + 1] = { "remove", key }

		return remove(key)
	end

	return log, function()
		setQuestStatus, removeQuestStatus = set, remove
	end
end

return B
