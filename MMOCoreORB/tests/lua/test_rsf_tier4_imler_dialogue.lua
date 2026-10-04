-- Admiral Diness Imler (RSF Squadron tier 4 trainer): wiring and dialogue conformance.
-- Spec: .claude/work/rsf-tier4/01-spec.md (AC-1, AC-2, invariant I-1).
-- Answer key: fixtures/script/conversation/naboo_privateer_tier4.java (SWG-Source), parsed by
-- harness/swgjava.lua. Every NPC line, option, successor, animation and end flag is compared with it.
-- Dialogue actions are NOT taken from the parser (it misattributes the skill purchases and the
-- setMetMe); they are tested as behavior in test_rsf_tier4_imler_behavior.lua from spec Appendix A.
--
-- space-convo-client-strings-imler-a (.claude/work/space-convo-client-strings-imler-a/01-spec.md, Appendix C): the 7 tests listed there compare through the twin table
-- (rsf_tier4_imler_client_strings_data.lua D.TWIN: Core3 shows the pre-NGE twin of s_4, s_9 and s_416) and treat training as the one exception E-IM1: the NPC lines s_439-s_442,
-- s_451, s_489, s_623 and s_737 have no screen, and ready_train's reply s_438 is replaced by the choice the handler adds. Screens are found by id (a pre-NGE line can be shown by
-- two screens), not by their line.

local lu = require("luaunit")
local H = require("harness")
local D = require("rsf_tier4_data")
local DS = require("rsf_tier4_imler_client_strings_data")
local FB = require("rsf_tier4_imler_b_client_strings_data") -- space-convo-client-strings-imler-b: Appendix G, the pool and the removed ids
local Swgjava = require("harness.swgjava")

local loadErrors = {}

local function tryLoad(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		loadErrors[#loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

tryLoad("RsfSquadronScreenplay", function() H.loadSquadron("RsfSquadronScreenplay") end)
tryLoad("imler_convo.lua", function() H.loadMobile("conversations/space/neutral/rsf_squadron/imler_convo.lua") end)
tryLoad("imlerConvoHandler.lua", function() H.loadScreenplay("space/conversations/neutral/rsf_squadron/imlerConvoHandler.lua") end)

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_tier4.java")

local function template()
	local t = H.conversationTemplateTable("imler_convo_template")
	lu.assertNotNil(t, "imler_convo_template is not registered via addConversationTemplate. Load problems: " .. table.concat(loadErrors, " | "))
	return t
end

local function screensById(t)
	local byId = {}

	for _, s in ipairs(t.screens) do
		byId[s.id] = s
	end

	return byId
end

-- Core3 shows the pre-NGE twin of each of the 3 NGE-numbered ids (space-convo-client-strings-imler-a)
local function twin(sid)
	return DS.TWIN[sid] or sid
end

-- space-convo-client-strings-imler-b (E-IM2, Appendix C): the subtrees under the four briefs follow Appendix G, not I4. The 196 NGE ids (s_453 .. s_849) of the java are not mirrored
-- by Core3 any more; the briefs keep their lines, ids and animations, but their options are Appendix G's (test_space_convo_client_strings_imler_b.lua pins them)
local SUBTREE = {}

for _, id in ipairs(DS.REMAINING) do
	SUBTREE[id] = true
end

local BRIEF_NPC = { s_9312a850 = true, s_bdc28bb4 = true, s_ff6e1247 = true, s_e4bbe441 = true }

-- the NGE training NPC lines (E-IM1): not mirrored by Core3
local TRAINING_NPC = {}

for _, id in ipairs({ "s_439", "s_440", "s_441", "s_442", "s_451", "s_489", "s_623", "s_737" }) do
	TRAINING_NPC[id] = true
end

-- the template screen that shows SWG NPC line `sid`: the screen with that id, or the descriptive id the mandatory-screen table names for it
local REVERSE = {}

for id, sid in pairs(D.SCREENS) do
	REVERSE[sid] = id
end

local function screenFor(t, sid)
	return screensById(t)[REVERSE[sid] or sid]
end

local function sidOf(text)
	return type(text) == "string" and text:match("^@conversation/naboo_privateer_tier4:(s_[%w_]+)$") or nil
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

TestImlerWiring = {}

function TestImlerWiring:setUp()
	H.reset()
end

-- AC-1
function TestImlerWiring:test_imler_convo_template_is_registered_with_the_imler_handler()
	local t = template()

	lu.assertEquals(t.luaClassHandler, "imlerConvoHandler", "imler_convo_template: luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "imler_convo_template: templateType")
end

-- AC-1
function TestImlerWiring:test_imler_handler_global_exists_with_both_entry_points()
	local handler = rawget(_G, "imlerConvoHandler")

	lu.assertNotNil(handler, "global imlerConvoHandler is not defined. Load problems: " .. table.concat(loadErrors, " | "))

	lu.assertEquals(type(handler.getInitialScreen), "function", "imlerConvoHandler:getInitialScreen")
	lu.assertEquals(type(handler.runScreenHandlers), "function", "imlerConvoHandler:runScreenHandlers")
end

-- AC-1
function TestImlerWiring:test_imler_convo_has_no_dead_links_or_duplicate_ids()
	template()
	lu.assertEquals(H.conversationProblems("imler_convo_template"), {})
end

-- AC-1
function TestImlerWiring:test_diness_imler_uses_imler_convo_template()
	local imler = H.loadCreatureTemplate("space/diness_imler.lua", "diness_imler")

	lu.assertNotNil(imler, "mobile/space/diness_imler.lua registers diness_imler")
	lu.assertEquals(imler.conversationTemplate, "imler_convo_template", "diness_imler: conversationTemplate")
end

-- AC-1: a trainer needs the CONVERSABLE option bit or the client offers no Converse radial. The
-- engine gate cannot catch this (LuaMobileTest.cpp has the CONVERSE check commented out).
function TestImlerWiring:test_diness_imler_options_include_conversable_aienabled_jtlinteresting_and_invulnerable()
	local imler = H.loadCreatureTemplate("space/diness_imler.lua", "diness_imler")

	lu.assertNotNil(imler, "mobile/space/diness_imler.lua registers diness_imler")

	local bits = imler.optionsBitmask

	lu.assertEquals(bits & CONVERSABLE, CONVERSABLE, "diness_imler: optionsBitmask lacks CONVERSABLE (" .. tostring(bits) .. ")")
	lu.assertEquals(bits & AIENABLED, AIENABLED, "diness_imler: optionsBitmask lacks AIENABLED")
	lu.assertEquals(bits & JTLINTERESTING, JTLINTERESTING, "diness_imler: optionsBitmask lacks JTLINTERESTING")
	lu.assertEquals(bits & INVULNERABLE, INVULNERABLE, "diness_imler: optionsBitmask lacks INVULNERABLE")
end

-- AC-1
function TestImlerWiring:test_conversation_include_line_is_uncommented_exactly_once()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/neutral/rsf_squadron/imler_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented imler_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented imler_convo include")
end

-- AC-1
function TestImlerWiring:test_handler_include_line_is_uncommented_exactly_once()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/neutral/rsf_squadron/imlerConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented imlerConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented imlerConvoHandler include")
end

-- AC-1
function TestImlerWiring:test_every_mandatory_screen_id_exists_with_its_sid()
	local byId = screensById(template())
	local ids = {}

	for id in pairs(D.SCREENS) do
		ids[#ids + 1] = id
	end

	table.sort(ids)

	for _, id in ipairs(ids) do
		local screen = byId[id]

		lu.assertNotNil(screen, "imler_convo_template: missing mandatory screen '" .. id .. "'")
		lu.assertEquals(screen.leftDialog, D.PREFIX .. twin(D.SCREENS[id]), "imler_convo_template: leftDialog of screen '" .. id .. "'")
	end
end

TestImlerDialogue = {}

function TestImlerDialogue:setUp()
	H.reset()
end

-- AC-2 (sanity of the answer key itself; risk "the graph parser may misread the generated java")
function TestImlerDialogue:test_answer_key_has_182_npc_lines_and_158_distinct_response_sids()
	lu.assertEquals(#GRAPH.order, 182, "NPC lines parsed from naboo_privateer_tier4.java")

	local count = 0

	for _ in pairs(GRAPH.responses) do
		count = count + 1
	end

	lu.assertEquals(count, 158, "distinct response sids in naboo_privateer_tier4.java")
end

-- AC-2, I-1; space-convo-client-strings-imler-a AC-8 [D-13]: the only ids outside the SWG java are the client-only lines (the twin s_3f68df7d is on a screen; the four
-- training replies are the handler's)
local CLIENT_ONLY = {}

-- space-convo-client-strings-imler-b (Appendix C): the client-only set is all 130 ids (the 126 pool lines of Appendix G and the 4 training replies)
for _, id in ipairs(FB.CLIENT_ONLY) do
	CLIENT_ONLY[id] = true
end

-- AC-2, I-1
function TestImlerDialogue:test_every_string_is_a_tier4_sid_that_exists_in_the_swg_java_or_is_one_of_the_client_only_lines()
	local t = template()
	local foreign = {}

	for _, screen in ipairs(t.screens) do
		local sid = sidOf(screen.leftDialog)

		lu.assertNotNil(sid, "screen '" .. screen.id .. "': leftDialog '" .. tostring(screen.leftDialog) .. "' is not @conversation/naboo_privateer_tier4:<sid>")
		lu.assertTrue(GRAPH.nodes[sid] ~= nil or CLIENT_ONLY[sid] == true, "screen '" .. screen.id .. "': leftDialog sid " .. sid .. " is neither an NPC line in the SWG java nor a client-only line")

		if GRAPH.nodes[sid] == nil then
			foreign[sid] = true
		end

		for i, option in ipairs(screen.options or {}) do
			local osid = sidOf(option[1])

			lu.assertNotNil(osid, "screen '" .. screen.id .. "' option " .. i .. ": text '" .. tostring(option[1]) .. "' is not @conversation/naboo_privateer_tier4:<sid>")
			lu.assertTrue(GRAPH.responses[osid] == true or CLIENT_ONLY[osid] == true, "screen '" .. screen.id .. "' option " .. i .. ": sid " .. osid .. " is neither a response in the SWG java nor a client-only line")

			if GRAPH.responses[osid] ~= true then
				foreign[osid] = true
			end
		end
	end

	-- the template's lines that are not in the java are exactly the 126 pool lines (Appendix G, with the twin s_3f68df7d); the four training replies are the handler's
	local got, want = {}, {}

	for sid in pairs(foreign) do got[#got + 1] = sid end
	for sid in pairs(FB.TEXT) do want[#want + 1] = sid end

	table.sort(got)
	table.sort(want)
	lu.assertEquals(#want, 126, "Appendix B: the pool")
	lu.assertEquals(got, want, "ids of imler_convo_template that are not in the SWG java")
end

-- AC-2; space-convo-client-strings-imler-a (Appendix D): every shown SWG NPC line has exactly one screen by id, a pre-NGE line is shown on as many screens as it has copies, and
-- the 8 training NPC lines have none
function TestImlerDialogue:test_every_swg_npc_line_has_exactly_one_screen()
	local t = template()
	local byId = screensById(t)
	local count = {}

	for _, screen in ipairs(t.screens) do
		count[screen.leftDialog] = (count[screen.leftDialog] or 0) + 1
	end

	local shown = 0

	for _, sid in ipairs(GRAPH.order) do
		if TRAINING_NPC[sid] then
			lu.assertNil(count[D.PREFIX .. sid], "number of screens whose leftDialog is the training NPC line " .. sid)
		elseif SUBTREE[sid] then
			lu.assertNil(count[D.PREFIX .. sid], "number of screens whose leftDialog is the NGE subtree line " .. sid .. " (E-IM2: removed)")
		else
			shown = shown + 1

			local id = REVERSE[sid] or sid

			lu.assertNotNil(byId[id], "SWG NPC line " .. sid .. ": a screen with id '" .. id .. "'")
			lu.assertEquals(count[D.PREFIX .. twin(sid)], DS.LEFT_COUNTS[twin(sid)] or 1, "number of screens whose leftDialog is " .. twin(sid) .. " (SWG " .. sid .. ")")
		end
	end

	lu.assertEquals(shown, 76, "SWG NPC lines other than the training dialogue and the 98 of the subtrees")
	lu.assertEquals(#t.screens, FB.SCREEN_COUNT, "number of screens in imler_convo_template (76 SWG lines + the 62 screens of Appendix G)")
end

-- AC-2, E-IM1 (replaces pilot-training-free-choice E-PN4): ready_train's one reply s_438 (conditional successor = first missing skill) is replaced by the choice the
-- handler adds (Imler's own "Teach me about ..." replies; spec: .claude/work/space-convo-client-strings-imler-a/01-spec.md); its static options are empty. Nothing else may differ.
local E_PN4 = { ready_train = "s_438" }

-- AC-2; compared through the twin table (space-convo-client-strings-imler-a, I-3); the training block is E-IM1
function TestImlerDialogue:test_options_are_the_swg_responses_in_order_and_link_to_the_swg_successor()
	local t = template()
	local byId = screensById(t)

	for _, sid in ipairs(GRAPH.order) do
		if not TRAINING_NPC[sid] and not SUBTREE[sid] and not BRIEF_NPC[sid] then
			local node = GRAPH.nodes[sid]
			local screen = screenFor(t, sid)

			lu.assertNotNil(screen, "NPC line " .. sid .. " has a screen")

			local got = {}

			for i, option in ipairs(screen.options or {}) do
				got[i] = sidOf(option[1])
			end

			local exceptional = E_PN4[screen.id]

			if exceptional ~= nil then
				lu.assertEquals(node.options, { exceptional }, "answer key: " .. screen.id .. " has the one reply " .. exceptional)
				lu.assertEquals(got, {}, "screen '" .. screen.id .. "' (" .. sid .. "): static options (E-IM1: the handler adds the choice)")
			else
				local wanted = {}

				for i, optionSid in ipairs(node.options) do
					wanted[i] = twin(optionSid)
				end

				lu.assertEquals(got, wanted, "screen '" .. screen.id .. "' (" .. sid .. "): option sids in order (twins of the SWG replies)")
			end

			for i, optionSid in ipairs(exceptional ~= nil and {} or node.options) do
				local successors = GRAPH.successorsOf(sid, optionSid)

				lu.assertNotNil(successors, "answer key: no successor for " .. sid .. " -> " .. optionSid)

				-- Conditional successors: the static link is the unconditional default, the last successor in the java.
				local expected = successors[#successors]
				local target = byId[screen.options[i][2]]

				lu.assertNotNil(target, "screen '" .. screen.id .. "' option " .. optionSid .. ": link '" .. tostring(screen.options[i][2]) .. "' is a screen")
				lu.assertEquals(target.leftDialog, D.PREFIX .. twin(expected), "screen '" .. screen.id .. "' option " .. optionSid .. " -> successor NPC line (twin of " .. expected .. ")")
			end
		end
	end
end

-- AC-2
function TestImlerDialogue:test_the_conditional_options_default_to_the_spec_links()
	local byId = screensById(template())

	lu.assertEquals(byId.not_my_track.options[1][2], "nontrack_no_duty", "not_my_track: default link of s_c1ff5062")
	lu.assertEquals(byId.ready_mission.options[1][2], "mission1_brief", "ready_mission: default link of s_39e697de")
	lu.assertEquals(byId.ready_train.options, {}, "ready_train: static options (E-IM1: no fixed-order default; the handler adds the choice)")

	-- space-convo-client-strings-imler-a (E-IM1): the train_<x> prompts and trained_mission<k> intros are deleted, so there is no default link to pin for them
	for _, skill in ipairs(D.SKILLS) do
		lu.assertNil(byId["train_" .. skill], "train_" .. skill .. " is deleted")
	end
end

-- AC-2; screens are found by id, not by their line, because copies share a line (space-convo-client-strings-imler-a); the training block is E-IM1
function TestImlerDialogue:test_stop_conversation_is_true_exactly_on_swg_end_lines()
	local t = template()

	for _, sid in ipairs(GRAPH.order) do
		if not TRAINING_NPC[sid] and not SUBTREE[sid] then
			local screen = screenFor(t, sid)

			lu.assertNotNil(screen, "NPC line " .. sid .. " has a screen")
			lu.assertEquals(screen.leftDialog, D.PREFIX .. twin(sid), "screen '" .. screen.id .. "' (" .. sid .. "): leftDialog (the twin of the SWG line)")
			lu.assertEquals(screen.stopConversation == "true", GRAPH.nodes[sid].isEnd, "screen '" .. screen.id .. "' (" .. sid .. "): stopConversation == \"true\" iff the line ends the conversation")
		end
	end
end

-- AC-2
function TestImlerDialogue:test_animation_matches_the_swg_doAnimationAction()
	local t = template()

	for _, sid in ipairs(GRAPH.order) do
		if not TRAINING_NPC[sid] and not SUBTREE[sid] then
			local screen = screenFor(t, sid)

			lu.assertNotNil(screen, "NPC line " .. sid .. " has a screen")
			lu.assertEquals(screen.leftDialog, D.PREFIX .. twin(sid), "screen '" .. screen.id .. "' (" .. sid .. "): leftDialog (the twin of the SWG line)")
			lu.assertEquals(screen.animation or "", GRAPH.nodes[sid].animation, "screen '" .. screen.id .. "' (" .. sid .. "): animation")
		end
	end
end

-- AC-2
function TestImlerDialogue:test_duty_menu_has_the_five_swg_options_on_all_three_menu_screens()
	local byId = screensById(template())

	for _, id in ipairs({ "tier4_incomplete", "here_for_work", "duty_info_end" }) do
		local screen = byId[id]

		lu.assertNotNil(screen, "duty menu screen '" .. id .. "'")
		lu.assertEquals(#screen.options, 5, "duty menu '" .. id .. "': option count")

		for i, entry in ipairs(D.DUTY_MENU) do
			lu.assertEquals(sidOf(screen.options[i][1]), entry.option, "duty menu '" .. id .. "' option " .. i .. ": sid")
			lu.assertEquals(screen.options[i][2], entry.screen, "duty menu '" .. id .. "' option " .. i .. ": link")
		end
	end
end
