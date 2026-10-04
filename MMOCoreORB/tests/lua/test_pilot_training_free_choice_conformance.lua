-- Pre-NGE free choice (Dinge, Kaydine, Imler): the TRAIN_CHOICES tables against the spec's answer key, the strings, and "nothing else moves".
-- Spec: .claude/work/pilot-training-free-choice/01-spec.md (AC-9, AC-10; Content contract 1-4; invariants I-1, I-6, I-7).
--
-- The per-screen comparison with the SWG java (options, order, successors, end flag, animation, with E-PN1 .. E-PN4 as the only exceptions) lives
-- in the superseded conformance tests of the three trainers (test_rsf_tier2_kaydine_training_template.lua, test_rsf_tier1_dinge_training_template.lua,
-- test_rsf_tier4_imler_dialogue.lua, test_rsf_gate_screens_templates.lua). This file pins the tables, the literal shape of their ids, the retired strings
-- and the "untouched since 1092dfb3fd" part (I-7), which reads that commit through `git show` like test_rsf_gate_screens_templates.lua does.
--
-- space-convo-client-strings-dinge (.claude/work/space-convo-client-strings-dinge/01-spec.md, D-4, D-5, D-9, I-6, Content contract 1-2) re-pins Dinge only:
-- TRAIN_CHOICES entries are { skill, reply, trained_<x> } (one click, no purchase screens, no TRAIN_SCREENS), the foreign ids are the four replies plus
-- s_cd72f93, Dinge has 64 screens, and the screens F2 rewrites or deletes are listed in CHANGED_SCREENS.dinge.
--
-- space-convo-client-strings-kaydine (.claude/work/space-convo-client-strings-kaydine/01-spec.md, D-1, D-3, Content contract 1-2, Appendix A) re-pins Kaydine:
-- TRAIN_CHOICES entries are { skill, reply, trained_<x>_mission4 } (one click, no purchase screens, no TRAIN_SCREENS), the foreign ids are the four
-- replies plus the 35 pre-NGE-only lines, Kaydine has 89 screens, and the screens F3 rewrites or deletes are listed in CHANGED_SCREENS.kaydine. Imler is untouched.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local C = require("pilot_training_free_choice_data")
local Swgjava = require("harness.swgjava")
local SU = require("rsf_tier2_kaydine_signup_data") -- rsf-tier2-kaydine-signup: the nine new Kaydine screens
local KS = require("rsf_tier2_kaydine_client_strings_data") -- space-convo-client-strings-kaydine: the 35 pre-NGE-only ids

T.load()
H.loadMobile("conversations/space/neutral/rsf_squadron/imler_convo.lua") -- T.load() does not load Imler
H.loadScreenplay("space/conversations/neutral/rsf_squadron/imlerConvoHandler.lua")

local BASE = "1092dfb3fd"

local DIR_C = "mobile/conversations/space/neutral/rsf_squadron/"
local DIR_H = "screenplays/space/conversations/neutral/rsf_squadron/"

local TRAINERS = {
	kaydine = { convo = DIR_C .. "kaydine_convo.lua", handler = DIR_H .. "kaydineConvoHandler.lua", global = "kaydineConvoHandler", template = "kaydine_convo_template",
		prefix = "naboo_privateer_trainer_2", java = "naboo_privateer_trainer_2.java", rows = C.KAYDINE, retired = { "s_187" } },
	dinge = { convo = DIR_C .. "dinge_convo.lua", handler = DIR_H .. "dingeConvoHandler.lua", global = "dingeConvoHandler", template = "dinge_convo_template",
		prefix = "naboo_privateer_trainer_1", java = "naboo_privateer_trainer_1.java", rows = C.DINGE, retired = { "s_143", "s_141" } },
	imler = { convo = DIR_C .. "imler_convo.lua", handler = DIR_H .. "imlerConvoHandler.lua", global = "imlerConvoHandler", template = "imler_convo_template",
		prefix = "naboo_privateer_tier4", java = "naboo_privateer_tier4.java", rows = C.IMLER, retired = { "s_438" } },
}

local ORDER = { "kaydine", "dinge", "imler" }

local function readFile(rel)
	local f = assert(io.open(H.SCRIPTS .. rel, "r"), "cannot open " .. rel)
	local text = f:read("a")

	f:close()
	return text
end

local function baseFile(rel)
	local pipe = io.popen("git show " .. BASE .. ":MMOCoreORB/bin/scripts/" .. rel .. " 2>&1")
	local text = pipe:read("a")

	pipe:close()
	lu.assertTrue(#text > 500 and text:find("^fatal") == nil, "git show " .. BASE .. ":MMOCoreORB/bin/scripts/" .. rel .. " did not return the file: " .. text:sub(1, 120))

	return text
end

local function handlerGlobal(name)
	local h = H.expectGlobal(TRAINERS[name].global, name .. " conversation handler")

	return h
end

local function screenIds(name)
	local ids = {}

	for _, s in ipairs(H.conversationTemplateTable(TRAINERS[name].template).screens) do
		ids[s.id] = s
	end

	return ids
end

---------------------------------------------------------------------------------------------
-- AC-9: the TRAIN_CHOICES tables equal the answer key
---------------------------------------------------------------------------------------------

TestFreeChoiceTables = {}

function TestFreeChoiceTables:setUp() H.reset() end

-- AC-9: entries { skill, reply, screen } for all three trainers (Dinge's screen is trained_<x>: one click, F2 D-4), in the order starships, weapons, procedures, droid
for _, name in ipairs(ORDER) do
	TestFreeChoiceTables["test_" .. name .. "_train_choices_equal_the_answer_key_in_skill_reply_link_and_order"] = function()
		local h = handlerGlobal(name)

		lu.assertEquals(type(h.TRAIN_CHOICES), "table", TRAINERS[name].global .. ".TRAIN_CHOICES must be defined (pilot-training-free-choice)")

		local want = {}

		for i, row in ipairs(TRAINERS[name].rows) do
			want[i] = { row.skill, row.reply, row.screen or row.closing }
		end

		local got = {}

		for i, entry in ipairs(h.TRAIN_CHOICES) do
			got[i] = { entry[1], entry[2], entry[3] }
			lu.assertNil(entry[4], TRAINERS[name].global .. ".TRAIN_CHOICES[" .. i .. "]: no fourth field (Dinge's purchase screens are gone)")
		end

		lu.assertEquals(got, want, TRAINERS[name].global .. ".TRAIN_CHOICES ({ skill, reply, screen } in order starships, weapons, procedures, droid)")
	end

	-- AC-9: every link a table names is a screen of the trainer's template; Kaydine's and Imler's purchase screens are the ones TRAIN_SCREENS buys,
	-- Dinge has no purchase screens and no TRAIN_SCREENS (F2 D-7) and links to trained_<x>
	TestFreeChoiceTables["test_every_link_of_the_" .. name .. "_train_choices_is_a_template_screen_and_the_purchase_screens_agree_with_train_screens"] = function()
		local h = handlerGlobal(name)
		local ids = screenIds(name)

		lu.assertEquals(type(h.TRAIN_CHOICES), "table", TRAINERS[name].global .. ".TRAIN_CHOICES must be defined")

		for i, entry in ipairs(h.TRAIN_CHOICES) do
			lu.assertNotNil(ids[entry[3]], name .. " TRAIN_CHOICES[" .. i .. "]: screen '" .. tostring(entry[3]) .. "' is not in " .. TRAINERS[name].template)

			if name == "dinge" then
				lu.assertEquals(entry[3], "trained_" .. entry[1]:match("^pilot_neutral_(%a+)_01$"), name .. " TRAIN_CHOICES[" .. i .. "]: the closing screen of the skill")
			elseif name == "kaydine" then
				-- space-convo-client-strings-kaydine D-3: the link is the static default intro, trained_<x>_mission4
				lu.assertEquals(entry[3], "trained_" .. entry[1]:match("^pilot_neutral_(%a+)_02$") .. "_mission4", name .. " TRAIN_CHOICES[" .. i .. "]: the default intro of the skill")
			else
				lu.assertEquals(h.TRAIN_SCREENS[entry[3]], entry[1], name .. " TRAIN_CHOICES[" .. i .. "]: TRAIN_SCREENS['" .. tostring(entry[3]) .. "'] buys the skill of the entry")
			end
		end

		if name == "dinge" or name == "kaydine" then
			lu.assertNil(h.TRAIN_SCREENS, TRAINERS[name].global .. ".TRAIN_SCREENS must be removed (its purchase screens no longer exist)")
		end
	end

	-- AC-9, Content contract: every reply and screen id in a TRAIN_CHOICES table is a complete string literal (the static checks parse handler literals)
	TestFreeChoiceTables["test_the_" .. name .. "_train_choices_ids_are_complete_string_literals"] = function()
		local text = readFile(TRAINERS[name].handler)
		local open = text:find("TRAIN_CHOICES%s*=%s*{")

		lu.assertNotNil(open, TRAINERS[name].handler .. ": a 'TRAIN_CHOICES = {' table")

		-- the table body: from the first brace to its matching brace
		local depth, i, start = 0, text:find("{", open, true), nil

		start = i

		local stop

		while i <= #text do
			local ch = text:sub(i, i)

			if ch == "{" then
				depth = depth + 1
			elseif ch == "}" then
				depth = depth - 1

				if depth == 0 then
					stop = i
					break
				end
			end

			i = i + 1
		end

		lu.assertNotNil(stop, TRAINERS[name].handler .. ": the TRAIN_CHOICES table is closed")

		local body = text:sub(start, stop)

		lu.assertNil(body:find("..", 1, true), name .. " TRAIN_CHOICES contains a string concatenation; every id must be a complete literal")

		for _, row in ipairs(TRAINERS[name].rows) do
			lu.assertNotNil(body:find('"' .. row.skill .. '"', 1, true), name .. " TRAIN_CHOICES: literal \"" .. row.skill .. "\"")
			lu.assertNotNil(body:find('"' .. row.reply .. '"', 1, true), name .. " TRAIN_CHOICES: literal \"" .. row.reply .. "\"")
			lu.assertNotNil(body:find('"' .. (row.screen or row.closing) .. '"', 1, true), name .. " TRAIN_CHOICES: literal \"" .. (row.screen or row.closing) .. "\"")

			if name == "dinge" or name == "kaydine" then
				lu.assertNil(body:find('"train_' .. row.x .. '"', 1, true), name .. " TRAIN_CHOICES still names the deleted purchase screen train_" .. row.x)
			end
		end
	end
end

-- AC-9: the answer key itself is the spec's (sanity of the copy: 4 distinct replies per trainer, none of them a java string of its trainer)
function TestFreeChoiceTables:test_the_answer_key_has_12_distinct_replies_and_none_is_a_response_of_the_swg_java()
	local seen = {}

	for _, name in ipairs(ORDER) do
		local java = Swgjava.read(H.FIXTURES .. "script/conversation/" .. TRAINERS[name].java)

		lu.assertEquals(#TRAINERS[name].rows, 4, name .. ": choice rows")

		for _, row in ipairs(TRAINERS[name].rows) do
			lu.assertNil(seen[row.reply], row.reply .. " appears twice in the answer key")
			seen[row.reply] = true

			if name ~= "imler" then
				lu.assertNil(java.responses[row.sid], name .. ": " .. row.sid .. " is a response of the java; the spec lists it as foreign")
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-9, I-6: strings
---------------------------------------------------------------------------------------------

TestFreeChoiceStrings = {}

function TestFreeChoiceStrings:setUp() H.reset() end

-- I-6: s_187, s_143, s_141 and s_438 appear in neither the template nor the handler of their trainer
for _, name in ipairs(ORDER) do
	TestFreeChoiceStrings["test_the_retired_replies_of_" .. name .. "_are_in_neither_file"] = function()
		for _, kind in ipairs({ "convo", "handler" }) do
			local text = readFile(TRAINERS[name][kind])

			for _, sid in ipairs(TRAINERS[name].retired) do
				lu.assertNil(text:find(TRAINERS[name].prefix .. ":" .. sid, 1, true), TRAINERS[name][kind] .. " still carries " .. sid)
			end
		end
	end
end

-- I-6: the foreign string ids of a trainer's template + handler are exactly its four choice replies (Dinge: plus "Good choice.", s_cd72f93, F2 D-9)
for _, name in ipairs({ "kaydine", "dinge" }) do
	TestFreeChoiceStrings["test_the_only_foreign_string_ids_in_the_" .. name .. "_files_are_the_four_choice_replies"] = function()
		local java = Swgjava.read(H.FIXTURES .. "script/conversation/" .. TRAINERS[name].java)
		local foreign = {}

		for _, kind in ipairs({ "convo", "handler" }) do
			for sid in readFile(TRAINERS[name][kind]):gmatch(TRAINERS[name].prefix .. ":(s_[%w_]+)") do
				if java.nodes[sid] == nil and java.responses[sid] == nil then
					foreign[sid] = true
				end
			end
		end

		local got, want = {}, {}

		for sid in pairs(foreign) do got[#got + 1] = sid end
		for _, row in ipairs(TRAINERS[name].rows) do want[#want + 1] = row.sid end

		if name == "dinge" then
			want[#want + 1] = "s_cd72f93"
		end

		-- space-convo-client-strings-kaydine I-4: Kaydine's foreign ids are exactly the 35 pre-NGE-only lines (the four choice replies are among them)
		if name == "kaydine" then
			want = {}

			for _, sid in ipairs(KS.PRE_NGE_ONLY) do want[#want + 1] = sid end
		end

		table.sort(got)
		table.sort(want)
		lu.assertEquals(got, want, name .. ": foreign string ids")
	end
end

-- I-6, AC-9: Imler's own string file keeps every id in the java; the foreign ones are exactly Turoldine's four replies, carried by the handler only
function TestFreeChoiceStrings:test_imler_files_carry_only_naboo_privateer_tier4_ids_of_the_java_plus_the_four_corellia_privateer_tier4_replies()
	local java = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_tier4.java")
	local foreignOwn = {}

	for _, kind in ipairs({ "convo", "handler" }) do
		for sid in readFile(TRAINERS.imler[kind]):gmatch("naboo_privateer_tier4:(s_[%w_]+)") do
			if java.nodes[sid] == nil and java.responses[sid] == nil then
				foreignOwn[#foreignOwn + 1] = kind .. ":" .. sid
			end
		end
	end

	lu.assertEquals(foreignOwn, {}, "naboo_privateer_tier4 ids that are not in the java")

	local other = {}

	for sid in readFile(TRAINERS.imler.convo):gmatch("corellia_privateer_tier4:(s_[%w_]+)") do
		other[#other + 1] = "convo:" .. sid
	end

	lu.assertEquals(other, {}, "imler_convo.lua carries no corellia_privateer_tier4 id (the handler adds them)")

	local seen = {}

	for sid in readFile(TRAINERS.imler.handler):gmatch("corellia_privateer_tier4:(s_[%w_]+)") do
		seen[#seen + 1] = sid
	end

	table.sort(seen)

	local want = {}

	for _, row in ipairs(C.IMLER) do want[#want + 1] = row.sid end

	table.sort(want)
	lu.assertEquals(seen, want, "corellia_privateer_tier4 ids in imlerConvoHandler.lua (Turoldine's four replies, D-10)")
end

-- AC-9: Imler uses 182 of 182 NPC lines and 157 of 158 replies; s_438 is the only newly unused string
function TestFreeChoiceStrings:test_imler_uses_182_of_182_npc_lines_and_157_of_158_replies_s_438_is_the_only_unused_string()
	local java = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_tier4.java")
	local used = {}
	local function sid(text) return type(text) == "string" and text:match("^@conversation/naboo_privateer_tier4:(s_[%w_]+)$") or nil end

	for _, s in ipairs(H.conversationTemplateTable("imler_convo_template").screens) do
		local x = sid(s.leftDialog)

		if x and java.nodes[x] then used[x] = true end

		for _, o in ipairs(s.options or {}) do
			local y = sid(o[1])

			if y and java.responses[y] then used[y] = true end
		end
	end

	for x in readFile(TRAINERS.imler.handler):gmatch("naboo_privateer_tier4:(s_[%w_]+)") do
		if java.nodes[x] or java.responses[x] then used[x] = true end
	end

	local npc, resp = 0, 0

	for x in pairs(used) do
		if java.nodes[x] then npc = npc + 1 else resp = resp + 1 end
	end

	lu.assertEquals({ npc, resp }, { 182, 157 }, "naboo_privateer_tier4 strings used (NPC lines, replies)")
	lu.assertNil(used.s_438, "s_438 must be unused")
end

-- AC-9: the unused constant is gone with the reply
function TestFreeChoiceStrings:test_imler_handler_has_no_ready_train_option_constant_left()
	lu.assertNil(readFile(TRAINERS.imler.handler):find("READY_TRAIN_OPTION", 1, true), "imlerConvoHandler.lua still defines or uses READY_TRAIN_OPTION")
	lu.assertNil(handlerGlobal("imler").READY_TRAIN_OPTION, "imlerConvoHandler.READY_TRAIN_OPTION")
end

---------------------------------------------------------------------------------------------
-- AC-9, I-1: the graphs
---------------------------------------------------------------------------------------------

TestFreeChoiceGraph = {}

function TestFreeChoiceGraph:setUp() H.reset() end

for _, name in ipairs(ORDER) do
	-- AC-9, I-1
	TestFreeChoiceGraph["test_the_" .. name .. "_template_has_no_dead_links_or_duplicate_ids"] = function()
		lu.assertNotNil(H.conversationTemplateTable(TRAINERS[name].template), TRAINERS[name].template)
		lu.assertEquals(H.conversationProblems(TRAINERS[name].template), {})
	end
end

-- AC-9: the screen counts the specs name (Dinge: 64 since space-convo-client-strings-dinge Content contract 1)
function TestFreeChoiceGraph:test_the_screen_counts_are_89_for_kaydine_64_for_dinge_and_182_for_imler()
	local function count(name) return #H.conversationTemplateTable(TRAINERS[name].template).screens end

	lu.assertEquals(count("kaydine"), 89, "kaydine_convo_template screens (100 - 11 deleted by space-convo-client-strings-kaydine)")
	lu.assertEquals(count("dinge"), 64, "dinge_convo_template screens (72 - 8 deleted by space-convo-client-strings-dinge)")
	lu.assertEquals(count("imler"), 182, "imler_convo_template screens")
end

-- F2 D-6, R-3: none of Dinge's 64 screens shows an NGE lesson or closing line, and the only NPC lines shown by more than one screen are the three
-- the spec names (the engine has no distinct-line rule; Rhea, Kaydine and Imler reuse lines too)
function TestFreeChoiceGraph:test_dinge_shows_none_of_the_deleted_nge_lines_and_repeats_only_the_three_lines_the_spec_names()
	local P = "@conversation/naboo_privateer_trainer_1:"
	local byLine = {}

	for _, s in ipairs(H.conversationTemplateTable("dinge_convo_template").screens) do
		for _, sid in ipairs({ "s_139", "s_140", "s_141", "s_142", "s_143", "s_144", "s_145", "s_146", "s_147", "s_149", "s_153", "s_157", "s_161" }) do
			lu.assertNotEquals(s.leftDialog, P .. sid, "screen '" .. s.id .. "' shows " .. sid)
		end

		byLine[s.leftDialog] = byLine[s.leftDialog] or {}
		table.insert(byLine[s.leftDialog], s.id)
	end

	local repeated = {}

	for line, screens in pairs(byLine) do
		if #screens > 1 then
			table.sort(screens)
			repeated[line:match(":(s_%w+)$")] = screens
		end
	end

	lu.assertEquals(repeated, {
		s_b9c77549 = { "mission1_failed_will_do", "mission3_failed_retry1" },
		s_7af03aab = { "mission1_failed_attacked", "mission3_failed_retry2" },
		s_cd72f93 = { "trained_droid", "trained_procedures", "trained_starships", "trained_weapons" },
	}, "NPC lines shown by more than one Dinge screen")
end

---------------------------------------------------------------------------------------------
-- AC-10, I-7: nothing else moves (against commit 1092dfb3fd)
---------------------------------------------------------------------------------------------

TestFreeChoiceNothingElseMoves = {}

function TestFreeChoiceNothingElseMoves:setUp() H.reset() end

-- screen id -> text of its definition, for the "<var> = ConvoScreen:new {" ... "<template>:addScreen(<var>);" style (Kaydine, Dinge)
local function varBlocks(text)
	local blocks, current = {}, nil

	for line in (text .. "\n"):gmatch("(.-)\n") do
		if current == nil and line:match("^[%w_]+ = ConvoScreen:new {") then
			current = { line }
		elseif current ~= nil then
			current[#current + 1] = line

			if line:match("^[%w_]+:addScreen%(") then
				local body = table.concat(current, "\n")

				blocks[body:match('\n%s*id = "([^"]+)"')] = body
				current = nil
			end
		end
	end

	return blocks
end

-- Imler's style: "imler_convo_template:addScreen(ConvoScreen:new {" ... "})"
local function inlineBlocks(text)
	local blocks, current = {}, nil

	for line in (text .. "\n"):gmatch("(.-)\n") do
		if line:match("^imler_convo_template:addScreen%(ConvoScreen:new {") then
			current = { line }
		elseif current ~= nil then
			current[#current + 1] = line

			if line == "})" then
				local body = table.concat(current, "\n")

				blocks[body:match('\n%s*id = "([^"]+)"')] = body
				current = nil
			end
		end
	end

	return blocks
end

local BLOCKS = { kaydine = varBlocks, dinge = varBlocks, imler = inlineBlocks }
-- space-convo-client-strings-dinge: Dinge's changed or deleted screens (Content contract 1) join the three choice screens of pilot-training-free-choice
local DINGE_F2 = {}

for _, id in ipairs({ "yes_ship", "signup_ready_ship", "signup_ship_later", "mission3_failed", "mission3_failed_retry1", "mission3_failed_retry2", "mission4_offer",
	"first_training", "train_starships", "train_weapons", "train_procedures", "train_droid", "trained_starships", "trained_weapons", "trained_procedures", "trained_droid",
	"non_rsf_duty_offer", "duty_missions", "what_is_duty", "duty_no_training", "duty_not_now" }) do
	DINGE_F2[id] = true
end

local CHANGED_SCREENS = { kaydine = {}, dinge = { more_training = true, first_training_lesson = true, first_training_done = true }, imler = { ready_train = true } }
local CHOICE_SCREENS = { kaydine = { ready_train_pilot = true }, dinge = { more_training = true, first_training_lesson = true, first_training_done = true, first_training = true }, imler = CHANGED_SCREENS.imler }

for id in pairs(DINGE_F2) do
	CHANGED_SCREENS.dinge[id] = true
end

-- space-convo-client-strings-kaydine (Content contract 1): the 11 deleted screens and the changed rows join ready_train_pilot
for id in pairs(KS.CHANGED_SINCE_FREE_CHOICE) do
	CHANGED_SCREENS.kaydine[id] = true
end

-- I-7: every screen not named in the spec is the very text of commit 1092dfb3fd; the named ones differ only in their options
for _, name in ipairs(ORDER) do
	TestFreeChoiceNothingElseMoves["test_every_" .. name .. "_screen_outside_the_choice_screens_equals_commit_" .. BASE] = function()
		local old = BLOCKS[name](baseFile(TRAINERS[name].convo))
		local new = BLOCKS[name](readFile(TRAINERS[name].convo))
		local oldCount, checked = 0, 0

		for _ in pairs(old) do oldCount = oldCount + 1 end

		lu.assertEquals(oldCount, ({ kaydine = 91, dinge = 73, imler = 182 })[name], "screen definitions parsed from " .. TRAINERS[name].convo .. " at " .. BASE)

		for id, body in pairs(old) do
			if not CHANGED_SCREENS[name][id] then
				lu.assertNotNil(new[id], TRAINERS[name].convo .. ": screen '" .. id .. "' of " .. BASE .. " is missing")
				lu.assertEquals(new[id], body, TRAINERS[name].convo .. ": screen '" .. id .. "' changed since " .. BASE)
				checked = checked + 1
			end
		end

		-- rsf-tier2-kaydine-signup (spec AC-10): Kaydine gains the nine Appendix A screens
		local signup = {}

		for _, id in ipairs(name == "kaydine" and SU.IDS or {}) do signup[id] = true end

		for id in pairs(new) do
			lu.assertTrue(old[id] ~= nil or signup[id] == true, TRAINERS[name].convo .. ": unexpected new screen '" .. id .. "'")
		end

		local changed = 0

		for _ in pairs(CHANGED_SCREENS[name]) do changed = changed + 1 end

		lu.assertEquals(checked, oldCount - changed, "screens compared with " .. BASE)

		-- space-convo-client-strings-dinge: the F2 screens really changed (or were deleted) since BASE
		if name == "dinge" then
			for id in pairs(DINGE_F2) do
				lu.assertNotEquals(new[id], old[id], "dinge: screen '" .. id .. "' is still the very text of " .. BASE)
			end
		end
	end

	-- I-7: a choice screen keeps its id, line, end flag and animation; only its options change (here: become empty)
	TestFreeChoiceNothingElseMoves["test_the_" .. name .. "_choice_screens_differ_from_commit_" .. BASE .. "_only_in_their_options"] = function()
		local old = BLOCKS[name](baseFile(TRAINERS[name].convo))
		local new = BLOCKS[name](readFile(TRAINERS[name].convo))
		local function stripOptions(body)
			return (body:gsub("options = {.-\n\t}", "options = {}", 1))
		end

		for id in pairs(CHOICE_SCREENS[name]) do
			if new[id] == nil then
				lu.assertTrue(id == "first_training_done" or id == "first_training_lesson", name .. ": only first_training_done and first_training_lesson may be deleted, not " .. id)
			else
				lu.assertNotNil(old[id], name .. ": screen '" .. id .. "' exists at " .. BASE)
				lu.assertEquals(stripOptions(new[id]), stripOptions(old[id]), name .. ": screen '" .. id .. "' differs from " .. BASE .. " in more than its options")
				lu.assertNotNil(new[id]:find("options = {%s*}"), name .. ": screen '" .. id .. "' static options must be empty")
			end
		end
	end
end

-- Top-level function blocks of a handler file: "<Class>:<name>" -> text
local function functionBlocks(text)
	local blocks, current, name = {}, nil, nil

	for line in (text .. "\n"):gmatch("(.-)\n") do
		if current == nil then
			local n = line:match("^function ([%w_%.:]+)%(")

			if n then
				current, name = { line }, n
			end
		else
			current[#current + 1] = line

			if line == "end" then
				blocks[name] = table.concat(current, "\n")
				current = nil
			end
		end
	end

	return blocks
end

-- the functions each feature rewrites (the rest must be the very text of the base commit)
local REWRITTEN = {
	-- rsf-tier2-kaydine-signup: the sign-up route and fallthrough; space-convo-client-strings-kaydine D-1: the one-click purchase in getNextConversationScreen
	kaydine = { ["kaydineConvoHandler:runScreenHandlers"] = true, ["kaydineConvoHandler:getInitialScreen"] = true, ["kaydineConvoHandler:getNextConversationScreen"] = true },
	dinge = { ["dingeConvoHandler:runScreenHandlers"] = true, ["dingeConvoHandler:getNextConversationScreen"] = true },
	imler = { ["imlerConvoHandler:runScreenHandlers"] = true },
}

-- I-7: handler code outside the branches named in the Content contract is unchanged
for _, name in ipairs(ORDER) do
	TestFreeChoiceNothingElseMoves["test_every_" .. name .. "_handler_function_but_the_rewritten_ones_equals_commit_" .. BASE] = function()
		local old = functionBlocks(baseFile(TRAINERS[name].handler))
		local new = functionBlocks(readFile(TRAINERS[name].handler))
		local checked = 0

		for fn, body in pairs(old) do
			if not REWRITTEN[name][fn] then
				lu.assertNotNil(new[fn], TRAINERS[name].handler .. ": function " .. fn .. " of " .. BASE .. " is missing")
				lu.assertEquals(new[fn], body, TRAINERS[name].handler .. ": function " .. fn .. " changed since " .. BASE)
				checked = checked + 1
			end
		end

		lu.assertTrue(checked >= 4, TRAINERS[name].handler .. ": functions compared with " .. BASE .. ": " .. checked)

		-- rsf-tier2-kaydine-signup (spec Content contract KH 2): Kaydine gains the predicate isSignedUp
		local added = { kaydine = { ["kaydineConvoHandler:isSignedUp"] = true } }

		for fn in pairs(new) do
			lu.assertTrue(old[fn] ~= nil or (added[name] or {})[fn] == true, TRAINERS[name].handler .. ": unexpected new function " .. fn)
		end
	end
end

-- I-7: the branches of runScreenHandlers other than the choice screens are the text of the base commit
local function branchTexts(fnText)
	-- text of each `if/elseif (screenID == "...")` branch up to the next `elseif (screenID` or the final return
	local out, order = {}, {}
	local pos = 1

	while true do
		local s, e, id = fnText:find('screenID == "([%w_]+)"', pos)

		if not s then break end

		-- a branch starts at the beginning of the line that holds its marker
		local lineStart = s

		while lineStart > 1 and fnText:sub(lineStart - 1, lineStart - 1) ~= "\n" do
			lineStart = lineStart - 1
		end

		order[#order + 1] = { id = id, from = lineStart }
		pos = e + 1
	end

	for i, b in ipairs(order) do
		local to = order[i + 1] and order[i + 1].from or #fnText
		local lines = {}

		for line in (fnText:sub(b.from, to - 1) .. "\n"):gmatch("(.-)\n") do
			lines[#lines + 1] = line
		end

		-- comment and blank lines directly above the next branch belong to no branch
		while #lines > 0 and (lines[#lines]:match("^%s*%-%-") or lines[#lines]:match("^%s*$")) do
			lines[#lines] = nil
		end

		local text = table.concat(lines, "\n")

		out[b.id] = out[b.id] and (out[b.id] .. "\n" .. text) or text
	end

	return out
end

local CHOICE_BRANCHES = {
	-- space-convo-client-strings-kaydine (Content contract 2): the male ending of mission1_brief, the mission 3 reward option, the deleted mission1_intro_b4 and
	-- the mission 1 start branch (it no longer names mission1_intro_accept(_male)) change; the new test file pins them and every other branch byte for byte
	kaydine = { ready_train_pilot = true, mission1_brief = true, mission3_reward = true, mission1_intro_b4 = true, mission1_accept = true, mission1_accept_male = true,
		mission1_failed = true, mission1_intro_accept = true, mission1_intro_accept_male = true },
	dinge = { more_training = true, first_training = true, first_training_lesson = true },
	imler = { ready_train = true },
}

for _, name in ipairs(ORDER) do
	TestFreeChoiceNothingElseMoves["test_the_" .. name .. "_run_screen_handlers_branches_outside_the_choice_screen_equal_commit_" .. BASE] = function()
		local fn = TRAINERS[name].global .. ":runScreenHandlers"
		local old = functionBlocks(baseFile(TRAINERS[name].handler))[fn]
		local new = functionBlocks(readFile(TRAINERS[name].handler))[fn]

		lu.assertNotNil(old, fn .. " at " .. BASE)
		lu.assertNotNil(new, fn .. " now")

		local ob, nb = branchTexts(old), branchTexts(new)
		local checked = 0

		for id, text in pairs(ob) do
			if not CHOICE_BRANCHES[name][id] then
				-- the branch that precedes a choice branch ends where the next branch starts; compare after trimming the choice branch header
				lu.assertNotNil(nb[id], fn .. ": branch for screen '" .. id .. "' is missing")
				lu.assertEquals(nb[id], text, fn .. ": branch for screen '" .. id .. "' changed since " .. BASE)
				checked = checked + 1
			end
		end

		lu.assertTrue(checked >= 3, fn .. ": branches compared: " .. checked)
	end
end

-- I-7, F2 AC-8: the paid purchase keeps the guards and calls of commit 1092dfb3fd (XP check, engine check, deducting grant, tier 1 -> 2); their behavior is
-- pinned by test_pilot_training_free_choice_dinge.lua, this only keeps the calls in the handler text
function TestFreeChoiceNothingElseMoves:test_dinge_get_next_conversation_screen_keeps_the_paid_guards_and_calls_of_commit_1092dfb3fd()
	local function guards(text)
		local fn = functionBlocks(text)["dingeConvoHandler:getNextConversationScreen"]

		lu.assertNotNil(fn, "dingeConvoHandler:getNextConversationScreen")

		return fn
	end

	local now = guards(readFile(TRAINERS.dinge.handler))
	local old = guards(baseFile(TRAINERS.dinge.handler))

	lu.assertNil(now:find("TRAIN_SCREENS", 1, true), "getNextConversationScreen still reads TRAIN_SCREENS (removed by space-convo-client-strings-dinge D-7)")
	lu.assertNil(now:find("first_training_lesson", 1, true), "getNextConversationScreen still names first_training_lesson")

	for _, needle in ipairs({
		"hasExperienceForTraining(pPlayer, 1)",
		"LuaSkillManager():fulfillsSkillPrerequisitesAndXp(pPlayer, ",
		"getPilotTier() == 1",
		'hasCompletedPilotTier(pPlayer, "neutral", 1)',
		"incrementPilotTier()",
	}) do
		lu.assertNotNil(old:find(needle, 1, true), "setup: " .. needle .. " is in the handler at " .. BASE)
		lu.assertNotNil(now:find(needle, 1, true), "dingeConvoHandler:getNextConversationScreen no longer contains " .. needle)
	end

	lu.assertNotNil(now:find("grantSpaceSkill(pPlayer, ", 1, true), "the paid and free grants go through SpaceHelpers:grantSpaceSkill")
	lu.assertNotNil(now:find(", true)", 1, true), "the paid grant passes deductExperience true")
	lu.assertNotNil(now:find(", false)", 1, true), "the free grant passes deductExperience false")
end
