-- Warvog Arkon (Havoc Squadron tier 4 trainer): wiring and dialogue conformance.
-- Spec: .claude/work/havoc-tier4-arkon/01-spec.md (AC-1, AC-2, invariant I-1).
-- Answer key: fixtures/script/conversation/corellia_rebel_tier4.java (SWG-Source), parsed by
-- harness/swgjava.lua. Every NPC line, option, successor, animation and end flag is compared with it.

local lu = require("luaunit")
local H = require("harness")
local D = require("havoc_tier4_data")
local FC = require("havoc_tier4_arkon_free_choice_data")
local DS = require("havoc_tier4_arkon_client_strings_data") -- space-convo-client-strings-arkon: twin table (Appendix A), training ids (Appendix B)
local Swgjava = require("harness.swgjava")

local loadErrors = {}

local function tryLoad(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		loadErrors[#loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

tryLoad("HavocSquadronScreenplay", function() H.loadSquadron("HavocSquadronScreenplay") end)
tryLoad("arkon_convo.lua", function() H.loadMobile("conversations/space/rebel/havoc_squadron/arkon_convo.lua") end)
tryLoad("arkonConvoHandler.lua", function() H.loadScreenplay("space/conversations/rebel/havoc_squadron/arkonConvoHandler.lua") end)

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_rebel_tier4.java")

local function template()
	local t = H.conversationTemplateTable("arkon_convo")
	lu.assertNotNil(t, "arkon_convo is not registered via addConversationTemplate. Load problems: " .. table.concat(loadErrors, " | "))
	return t
end

local function screensById(t)
	local byId = {}

	for _, s in ipairs(t.screens) do
		byId[s.id] = s
	end

	return byId
end

local function screensByDialog(t)
	local byDialog = {}

	for _, s in ipairs(t.screens) do
		byDialog[s.leftDialog] = s
	end

	return byDialog
end

local function sidOf(text)
	return type(text) == "string" and text:match("^@conversation/corellia_rebel_tier4:(s_[%w_]+)$") or nil
end

-- space-convo-client-strings-arkon: Core3 shows the pre-NGE twin of each of the 78 NGE-numbered SWG ids, and the training block is E-AK2 (Content contract 1b)
local function twin(sid)
	return DS.TWIN[sid] or sid
end

-- the SWG ids of the training dialogue, s_421 .. s_437: not mirrored by Core3 (E-AK2)
local function isTraining(sid)
	local n = tonumber(sid:match("^s_(%d+)$"))

	return n ~= nil and n >= 421 and n <= 437
end

-- the template screen that shows SWG NPC line `sid`: the screen with that id, or the descriptive id the mandatory-screen table names for it
local REVERSE = {}

for id, sid in pairs(D.SCREENS) do
	REVERSE[sid] = id
end

local function screenFor(t, sid)
	return screensById(t)[REVERSE[sid] or sid]
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")
	f:close()
	return text
end

local function countMatches(text, pattern)
	local n = 0

	for _ in text:gmatch(pattern) do
		n = n + 1
	end

	return n
end

TestArkonWiring = {}

function TestArkonWiring:setUp()
	H.reset()
end

-- AC-1
function TestArkonWiring:test_arkon_convo_is_registered_with_the_arkon_handler()
	local t = template()

	lu.assertEquals(t.luaClassHandler, "arkonConvoHandler", "arkon_convo: luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "arkon_convo: templateType")
end

-- AC-1
function TestArkonWiring:test_arkon_convo_handler_global_exists_with_both_entry_points()
	local handler = rawget(_G, "arkonConvoHandler")

	lu.assertNotNil(handler, "global arkonConvoHandler is not defined. Load problems: " .. table.concat(loadErrors, " | "))

	lu.assertEquals(type(handler.getInitialScreen), "function", "arkonConvoHandler:getInitialScreen")
	lu.assertEquals(type(handler.runScreenHandlers), "function", "arkonConvoHandler:runScreenHandlers")
end

-- AC-1
function TestArkonWiring:test_arkon_convo_has_no_dead_links_or_duplicate_ids()
	template()
	lu.assertEquals(H.conversationProblems("arkon_convo"), {})
end

-- AC-1
function TestArkonWiring:test_warvog_arkon_uses_arkon_convo()
	local arkon = H.loadCreatureTemplate("space/warvog_arkon.lua", "warvog_arkon")

	lu.assertNotNil(arkon, "mobile/space/warvog_arkon.lua registers warvog_arkon")
	lu.assertEquals(arkon.conversationTemplate, "arkon_convo", "warvog_arkon: conversationTemplate")
end

-- AC-1 (R-2): a trainer needs the CONVERSABLE option bit or the client offers no Converse radial.
-- The engine gate cannot catch this (LuaMobileTest.cpp has the CONVERSE check commented out).
function TestArkonWiring:test_warvog_arkon_options_include_conversable_aienabled_and_jtlinteresting()
	local arkon = H.loadCreatureTemplate("space/warvog_arkon.lua", "warvog_arkon")

	lu.assertNotNil(arkon, "mobile/space/warvog_arkon.lua registers warvog_arkon")

	local bits = arkon.optionsBitmask

	lu.assertEquals(bits & CONVERSABLE, CONVERSABLE, "warvog_arkon: optionsBitmask lacks CONVERSABLE (" .. tostring(bits) .. ")")
	lu.assertEquals(bits & AIENABLED, AIENABLED, "warvog_arkon: optionsBitmask lacks AIENABLED")
	lu.assertEquals(bits & JTLINTERESTING, JTLINTERESTING, "warvog_arkon: optionsBitmask lacks JTLINTERESTING")
end

-- AC-1
function TestArkonWiring:test_conversation_include_line_is_uncommented_exactly_once()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/rebel/havoc_squadron/arkon_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented arkon_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented arkon_convo include")
end

-- AC-1
function TestArkonWiring:test_handler_include_line_is_uncommented_exactly_once()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/rebel/havoc_squadron/arkonConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented arkonConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented arkonConvoHandler include")
end

-- AC-1
function TestArkonWiring:test_every_mandatory_screen_id_exists_with_its_sid()
	local byId = screensById(template())
	local ids = {}

	for id in pairs(D.SCREENS) do
		ids[#ids + 1] = id
	end

	table.sort(ids)

	for _, id in ipairs(ids) do
		local screen = byId[id]

		lu.assertNotNil(screen, "arkon_convo: missing mandatory screen '" .. id .. "'")
		-- through the twin table (the 78 NGE-numbered lines show their pre-NGE twins); the trained_<x> sids are the Content contract 1b lines
		lu.assertEquals(screen.leftDialog, D.PREFIX .. twin(D.SCREENS[id]), "arkon_convo: leftDialog of screen '" .. id .. "'")
	end
end

TestArkonDialogue = {}

function TestArkonDialogue:setUp()
	H.reset()
end

-- AC-2 (sanity of the answer key itself; risk "the graph parser may misread the generated java")
function TestArkonDialogue:test_answer_key_has_186_npc_lines_and_346_distinct_sids()
	lu.assertEquals(#GRAPH.order, 186, "NPC lines parsed from corellia_rebel_tier4.java")

	local all = {}

	for sid in pairs(GRAPH.nodes) do
		all[sid] = true
	end

	for sid in pairs(GRAPH.responses) do
		all[sid] = true
	end

	local count = 0

	for _ in pairs(all) do
		count = count + 1
	end

	lu.assertEquals(count, 346, "distinct string ids in corellia_rebel_tier4.java")
end

-- AC-2, I-1; space-convo-client-strings-arkon (E-AK2): the only ids outside the SWG java are the 12 pre-NGE training lines
function TestArkonDialogue:test_every_string_is_a_tier4_sid_that_exists_in_the_swg_java_or_is_one_of_the_12_training_lines()
	local t = template()

	for _, screen in ipairs(t.screens) do
		local sid = sidOf(screen.leftDialog)

		lu.assertNotNil(sid, "screen '" .. screen.id .. "': leftDialog '" .. tostring(screen.leftDialog) .. "' is not @conversation/corellia_rebel_tier4:<sid>")
		lu.assertTrue(GRAPH.nodes[sid] ~= nil or DS.TRAINING_TEXT[sid] ~= nil, "screen '" .. screen.id .. "': leftDialog sid " .. sid .. " is neither an NPC line in the SWG java nor one of the 12 training lines")

		for i, option in ipairs(screen.options or {}) do
			local osid = sidOf(option[1])

			lu.assertNotNil(osid, "screen '" .. screen.id .. "' option " .. i .. ": text '" .. tostring(option[1]) .. "' is not @conversation/corellia_rebel_tier4:<sid>")
			lu.assertTrue(GRAPH.responses[osid] == true or DS.TRAINING_TEXT[osid] ~= nil, "screen '" .. screen.id .. "' option " .. i .. ": sid " .. osid .. " is neither a response in the SWG java nor one of the 12 training lines")
		end
	end
end

-- AC-2; space-convo-client-strings-arkon (Appendix D): every shown SWG NPC line has exactly one screen by id, and a pre-NGE line is shown on as many screens as it has copies
function TestArkonDialogue:test_every_shown_swg_npc_line_has_exactly_one_screen_and_the_left_dialog_multiplicities_are_those_of_appendix_d()
	local t = template()
	local byId = screensById(t)
	local count = {}

	for _, screen in ipairs(t.screens) do
		count[screen.leftDialog] = (count[screen.leftDialog] or 0) + 1
	end

	local shown = 0

	for _, sid in ipairs(GRAPH.order) do
		if not isTraining(sid) then
			shown = shown + 1

			local id = REVERSE[sid] or sid

			lu.assertNotNil(byId[id], "SWG NPC line " .. sid .. ": a screen with id '" .. id .. "'")
			lu.assertEquals(count[D.PREFIX .. twin(sid)], DS.LEFT_COUNTS[twin(sid)] or 1, "number of screens whose leftDialog is " .. twin(sid) .. " (SWG " .. sid .. ")")
		end
	end

	lu.assertEquals(shown, 186 - 10, "SWG NPC lines other than the training dialogue")
end

-- AC-2; compared through the twin table (space-convo-client-strings-arkon, I-3); the training block is E-AK2
function TestArkonDialogue:test_options_are_the_swg_responses_in_order_and_link_to_the_swg_successor()
	local t = template()
	local byId = screensById(t)

	for _, sid in ipairs(GRAPH.order) do
		if not isTraining(sid) then
			local node = GRAPH.nodes[sid]
			local screen = screenFor(t, sid)

			lu.assertNotNil(screen, "NPC line " .. sid .. " has a screen")

			-- havoc-tier4-arkon-free-choice, E-AK1: ready_train's single SWG reply s_421 is replaced by handler-added choice replies
			local exceptions = FC.EXCEPTIONS[screen.id] or {}
			local wanted = {}

			for _, optionSid in ipairs(node.options) do
				if not exceptions[optionSid] then
					wanted[#wanted + 1] = twin(optionSid)
				end
			end

			local got = {}

			for i, option in ipairs(screen.options or {}) do
				got[i] = sidOf(option[1])
			end

			lu.assertEquals(got, wanted, "screen '" .. screen.id .. "' (" .. sid .. "): option sids in order (twins of the SWG replies)")

			local i = 0

			for _, optionSid in ipairs(node.options) do
				if not exceptions[optionSid] then
					i = i + 1

					local successors = GRAPH.successorsOf(sid, optionSid)

					lu.assertNotNil(successors, "answer key: no successor for " .. sid .. " -> " .. optionSid)

					-- Conditional successors (s_6222b64d): the static link is the unconditional default,
					-- which is the last successor in the java.
					local expected = successors[#successors]
					local target = byId[screen.options[i][2]]

					lu.assertNotNil(target, "screen '" .. screen.id .. "' option " .. optionSid .. ": link '" .. tostring(screen.options[i][2]) .. "' is a screen")
					lu.assertEquals(target.leftDialog, D.PREFIX .. twin(expected), "screen '" .. screen.id .. "' option " .. optionSid .. " -> successor NPC line (twin of " .. expected .. ")")
				end
			end
		end
	end
end

-- AC-2
function TestArkonDialogue:test_the_two_conditional_options_default_to_the_spec_links()
	local byId = screensById(template())

	lu.assertEquals(byId.not_my_track.options[1][2], "nontrack_no_duty", "not_my_track: default link of s_6222b64d")
	-- havoc-tier4-arkon-free-choice AC-1/AC-4, E-AK1: the handler adds the choice replies
	lu.assertEquals(byId.ready_train.options, {}, "ready_train: static options")
end

-- AC-2; screens are found by id, not by their line, because copies share a line (space-convo-client-strings-arkon); the training block is E-AK2
function TestArkonDialogue:test_stop_conversation_is_true_exactly_on_swg_end_lines()
	local t = template()

	for _, sid in ipairs(GRAPH.order) do
		if not isTraining(sid) then
			local screen = screenFor(t, sid)

			lu.assertNotNil(screen, "NPC line " .. sid .. " has a screen")
			lu.assertEquals(screen.stopConversation == "true", GRAPH.nodes[sid].isEnd, "screen '" .. screen.id .. "' (" .. sid .. "): stopConversation == \"true\" iff the line ends the conversation")
		end
	end
end

-- AC-2
function TestArkonDialogue:test_animation_matches_the_swg_doAnimationAction()
	local t = template()

	for _, sid in ipairs(GRAPH.order) do
		if not isTraining(sid) then
			local screen = screenFor(t, sid)

			lu.assertNotNil(screen, "NPC line " .. sid .. " has a screen")
			lu.assertEquals(screen.animation or "", GRAPH.nodes[sid].animation, "screen '" .. screen.id .. "' (" .. sid .. "): animation")
		end
	end
end

-- AC-2
function TestArkonDialogue:test_duty_menu_has_the_five_swg_options_on_all_five_screens()
	local byId = screensById(template())
	local menuScreens = { "tier4_incomplete", "here_for_work" }

	-- the end of both intro chains and of the duty-info chain also carry the menu
	-- (space-convo-client-strings-arkon: the three menus share one line, so they are found by screen id)
	for _, sid in ipairs({ "s_9bbb9999", "s_371", "s_406" }) do
		local screen = screenFor(template(), sid)
		lu.assertNotNil(screen, "NPC line " .. sid .. " has a screen")
		menuScreens[#menuScreens + 1] = screen.id
	end

	for _, id in ipairs(menuScreens) do
		local screen = byId[id]
		lu.assertNotNil(screen, "duty menu screen '" .. id .. "'")
		lu.assertEquals(#screen.options, 5, "duty menu '" .. id .. "': option count")

		for i, entry in ipairs(D.DUTY_MENU) do
			lu.assertEquals(sidOf(screen.options[i][1]), entry.option, "duty menu '" .. id .. "' option " .. i .. ": sid")
			lu.assertEquals(screen.options[i][2], entry.screen, "duty menu '" .. id .. "' option " .. i .. ": link")
		end
	end
end
