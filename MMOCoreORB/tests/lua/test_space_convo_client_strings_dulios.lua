-- Client string ids of Dulios (RSF tier 3), F4 of the space conversation client-string work.
-- Spec: .claude/work/space-convo-client-strings-dulios/01-spec.md (AC-1 .. AC-8; I-1 .. I-5; D-1 .. D-10; FD-1 .. FD-10; Content contract 1 .. 4; Appendix A .. D).
--
-- Dulios shows 76 NGE-numbered ids (Appendix A) that the pre-NGE client cannot resolve. All 76 are copies of earlier pre-NGE lines (FD-4): the client's string ids are CRCs of the
-- line text, so a copy has the id of the line it repeats. Every one is rewritten in place onto that line (its twin): screens, links, stops and animations do not move (D-1, D-4),
-- and each changed line gains a trailing `-- <client text>` comment. Training needs no rebuild (FD-8); the only handler change is that TRAIN_CHOICES holds complete string
-- literals, so the static scan sees every id (Content contract 2).
--
-- The twin of every NGE id and the client text of every twin are copied from the spec (rsf_tier3_dulios_client_strings_data.lua), not read from dulios_convo.lua, so a wrong
-- twin fails here instead of agreeing with itself. The T3 answer key (rsf_tier3_dulios_convo_data.lua) stays the T3 graph; conformance runs through the twin table (I-4).
-- The behavior tests (offers, failures, rewards, training, the sweep, migration) of test_rsf_tier3_dulios_convo_*.lua stay as they are; AC-7 here adds the transcript scans
-- and re-asserts the headline behavior on the new ids.

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local T = require("trainer_fixes_data")
local G = require("rsf_gate_screens_data")
local KD = require("space_convo_client_strings_data")
local D = require("rsf_tier3_dulios_convo_data") -- the T3 answer key, unchanged
local DS = require("rsf_tier3_dulios_client_strings_data") -- Appendix A, B, D
local Swgjava = require("harness.swgjava")

T.load()

local tr = T.TRAINERS.dulios
local P = DS.PREFIX
local BASE = DS.BASE

local DC = "mobile/conversations/space/neutral/rsf_squadron/dulios_convo.lua"
local DH = "screenplays/space/conversations/neutral/rsf_squadron/duliosConvoHandler.lua"
local SOURCES = { DC, DH }
local FILE = "conversation/naboo_privateer_tier3"

local JAVA = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_tier3.java")

local ORIGINAL_CHAIN = SpaceHelpers.startSpaceQuestChain

---------------------------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------------------------

local function readFile(rel)
	local f = assert(io.open(H.SCRIPTS .. rel, "rb"), "cannot open " .. rel)
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

-- Lines of a text split on "\n"; each keeps its "\r" (so the line endings can be checked)
local function linesOf(text)
	local out = {}

	for line in (text .. (text:sub(-1) == "\n" and "" or "\n")):gmatch("(.-)\n") do
		out[#out + 1] = line
	end

	return out
end

local function sortedKeys(set)
	local out = {}

	for k in pairs(set) do out[#out + 1] = k end

	table.sort(out)

	return out
end

local function count(set)
	local n = 0

	for _ in pairs(set) do n = n + 1 end

	return n
end

local function sidOf(text)
	return type(text) == "string" and text:match("^@conversation/naboo_privateer_tier3:(s_[%w_]+)$") or nil
end

local function twin(sid) return DS.TWIN[sid] or sid end

local function screens()
	local byId = {}
	local t = H.conversationTemplateTable(D.TEMPLATE)

	lu.assertNotNil(t, D.TEMPLATE .. " is registered")

	for _, s in ipairs(t.screens) do
		byId[s.id] = s
	end

	return byId, t
end

local function handler() return H.expectGlobal("duliosConvoHandler", "Dulios conversation handler (duliosConvoHandler.lua)") end

-- { sid, link } of a transcript step's options
local function optionsOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = { (o.text or ""):match(":(s_[%w_]+)$"), o.link }
	end

	return out
end

local function sidOfStep(step) return (step.text or ""):match(":(s_[%w_]+)$") end

local function attempted(player, n) return H.getQuestStatus(player, D.KEYS[n] .. ":attempted") end
local function rewarded(player, n) return H.getQuestStatus(player, D.KEYS[n] .. ":reward") end

local function tapChains()
	local calls = {}

	SpaceHelpers.startSpaceQuestChain = function(self, ...)
		calls[#calls + 1] = { args = table.pack(...) }
		return ORIGINAL_CHAIN(self, ...)
	end

	return calls
end

local function restore() SpaceHelpers.startSpaceQuestChain = ORIGINAL_CHAIN end

local function headIds(calls)
	local out = {}

	for i, c in ipairs(calls) do out[i] = c.args[3] end

	return out
end

local function noUnresolved(transcript, label)
	lu.assertEquals(CS.transcriptUnresolved(transcript), {}, label .. ": ids the pre-NGE client cannot resolve")
end

local function rowsById()
	local byId = {}

	for _, row in ipairs(D.ROWS) do byId[row.id] = row end

	return byId
end

local ROWS = rowsById()

---------------------------------------------------------------------------------------------
-- sanity of the copied answer key
---------------------------------------------------------------------------------------------

TestF4DuliosAnswerKey = {}

function TestF4DuliosAnswerKey:setUp() H.reset() end

-- AC-3, AC-5 (sanity of the data copied from the spec)
function TestF4DuliosAnswerKey:test_appendix_a_has_76_distinct_lines_39_npc_lines_and_37_replies_and_appendix_b_40_texts()
	local lines, npc, resp, twins = {}, 0, 0, {}

	for _, site in ipairs(DS.SITES) do
		lu.assertNil(lines[site.line], "Appendix A: line " .. site.line .. " listed twice")
		lines[site.line] = true
		twins[site.twin] = true

		if site.field == "leftDialog" then
			npc = npc + 1
			lu.assertTrue(JAVA.nodes[site.nge] ~= nil, "Appendix A line " .. site.line .. ": " .. site.nge .. " is an NPC line of the java")
		else
			resp = resp + 1
			lu.assertTrue(JAVA.responses[site.nge] == true, "Appendix A line " .. site.line .. ": " .. site.nge .. " is a reply of the java")
		end

		lu.assertNotNil(DS.TEXT[site.twin], "Appendix B has no text for " .. site.twin)
	end

	lu.assertEquals(#DS.SITES, 76, "Appendix A rows")
	lu.assertEquals(npc, 39, "NPC lines among the 76 (FD-1)")
	lu.assertEquals(resp, 37, "replies among the 76 (FD-1)")
	lu.assertEquals(count(DS.TWIN), 76, "distinct NGE ids")
	lu.assertEquals(count(DS.TEXT), 40, "Appendix B texts")
	lu.assertEquals(sortedKeys(twins), sortedKeys(DS.TEXT), "the twins of Appendix A are exactly the ids of Appendix B")
end

---------------------------------------------------------------------------------------------
-- AC-1: no unresolved id left in Dulios' two files; the ratchet no longer lists his file
---------------------------------------------------------------------------------------------

TestF4DuliosStaticUnresolved = {}

function TestF4DuliosStaticUnresolved:setUp() H.reset() end

-- AC-1 (I-1): 76 unresolved entries before this feature
function TestF4DuliosStaticUnresolved:test_dulios_template_and_handler_show_only_client_string_ids()
	lu.assertEquals(CS.unresolved(SOURCES), {}, "Dulios: ids the pre-NGE client cannot resolve")
end

-- AC-1: his file left KNOWN_GAPS (381 -> 305); space-convo-client-strings-arkon then took Arkon's file out too (305 -> 211, Appendix C): only Imler's file stays
-- (space-convo-client-strings-imler-a then took 15 ids out of it, 211 -> 196, Appendix C)
function TestF4DuliosStaticUnresolved:test_dulios_file_is_not_in_the_ratchet_and_only_imlers_file_still_is_with_196_ids()
	lu.assertNil(KD.KNOWN_GAPS[FILE], "KNOWN_GAPS entry of Dulios' file")
	lu.assertEquals(sortedKeys(KD.KNOWN_GAPS), { "conversation/naboo_privateer_tier4" }, "KNOWN_GAPS files")

	local counts, total = {}, 0

	for file, list in pairs(KD.KNOWN_GAPS) do
		counts[file] = #list
		total = total + #list
	end

	lu.assertEquals(counts, { ["conversation/naboo_privateer_tier4"] = 196 }, "KNOWN_GAPS counts")
	lu.assertEquals(#(CS.unresolvedByFile(CS.spaceConversationSources())["conversation/naboo_privateer_tier4"] or {}), 196, "live scan: unresolved ids of Imler's file (space-convo-client-strings-imler-a)")
	lu.assertEquals(total, 196, "KNOWN_GAPS total")
	lu.assertNil(CS.unresolvedByFile(SOURCES)[FILE], "unresolved ids of Dulios' file")
end

-- AC-1: the scan of every space conversation source equals the ratchet exactly
function TestF4DuliosStaticUnresolved:test_the_unresolved_ids_of_all_space_conversations_equal_known_gaps()
	lu.assertEquals(CS.unresolvedByFile(CS.spaceConversationSources()), KD.KNOWN_GAPS, "unresolvedByFile versus KNOWN_GAPS")
end

-- AC-1: none of the 76 NGE ids is named in either file
function TestF4DuliosStaticUnresolved:test_none_of_the_76_nge_ids_is_named_in_either_file()
	for _, rel in ipairs(SOURCES) do
		local text = readFile(rel)

		for nge in pairs(DS.TWIN) do
			lu.assertNil(text:find(P .. nge .. '"', 1, true), rel .. " still carries " .. nge)
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: no dynamic site
---------------------------------------------------------------------------------------------

TestF4DuliosNoDynamicSite = {}

function TestF4DuliosNoDynamicSite:setUp() H.reset() end

-- AC-2: the stored prefixes are the 14 unused `stringFile` locals, none of them Dulios'
function TestF4DuliosNoDynamicSite:test_the_dynamic_sites_are_the_14_listed_lines_and_none_is_duliosconvohandler()
	local sites = CS.dynamicSites(CS.spaceConversationSources())

	lu.assertEquals(#KD.KNOWN_DYNAMIC, 14, "KNOWN_DYNAMIC lines")
	lu.assertEquals(sites, KD.KNOWN_DYNAMIC, "lines that hold a string-file prefix instead of a complete id")

	for _, site in ipairs(sites) do
		lu.assertNil(site:find("duliosConvoHandler", 1, true), "dynamic site in Dulios' handler: " .. site)
	end
end

-- AC-2 (I-3): nothing joins a stored prefix with an id any more; the ratchet data says so
function TestF4DuliosNoDynamicSite:test_no_line_uses_a_stored_prefix_and_the_unused_prefixes_are_the_14_listed_ones()
	local src = CS.spaceConversationSources()

	lu.assertEquals(KD.KNOWN_PREFIX_USES, {}, "KNOWN_PREFIX_USES")
	lu.assertEquals(CS.prefixUses(src), {}, "lines that use a stored string-file prefix")
	lu.assertEquals(#KD.KNOWN_UNUSED_PREFIXES, 14, "KNOWN_UNUSED_PREFIXES lines")
	lu.assertEquals(CS.unusedPrefixes(src), KD.KNOWN_UNUSED_PREFIXES, "stored string-file prefixes nothing uses")
end

-- AC-2: TRAIN_CHOICES holds the four complete literals of Content contract 2, in order, and each resolves in the client file
function TestF4DuliosNoDynamicSite:test_train_choices_are_the_four_complete_literals_in_order_and_each_resolves()
	local dh = handler()
	local client = assert(CS.sids(FILE))

	lu.assertEquals(dh.TRAIN_CHOICES, {
		{ "pilot_neutral_starships_03", "@conversation/naboo_privateer_tier3:s_aa766bd6", "train_warships" },
		{ "pilot_neutral_weapons_03", "@conversation/naboo_privateer_tier3:s_a70b470e", "train_components" },
		{ "pilot_neutral_procedures_03", "@conversation/naboo_privateer_tier3:s_da0e8cd0", "train_techniques" },
		{ "pilot_neutral_droid_03", "@conversation/naboo_privateer_tier3:s_c28a300f", "train_programming" },
	}, "duliosConvoHandler.TRAIN_CHOICES")

	for _, c in ipairs(dh.TRAIN_CHOICES) do
		lu.assertEquals(c[2]:sub(1, #P), P, "TRAIN_CHOICES option " .. tostring(c[2]) .. " (" .. c[1] .. "): complete string id")
		lu.assertTrue(client[c[2]:sub(#P + 1)] == true, "TRAIN_CHOICES option " .. tostring(c[2]) .. " (" .. c[1] .. ") is not in the client file naboo_privateer_tier3")
	end
end

-- AC-2: the handler no longer has the PT prefix local (it is deleted, not moved to the unused list)
function TestF4DuliosNoDynamicSite:test_the_handler_text_has_no_pt_identifier_and_no_stored_prefix()
	local text = readFile(DH)

	lu.assertNil(text:find("%f[%w_]PT%f[^%w_]"), "duliosConvoHandler.lua still names the PT prefix local")
	lu.assertNil(text:find('"@conversation/naboo_privateer_tier3:"', 1, true), "duliosConvoHandler.lua still stores the file prefix")
end

---------------------------------------------------------------------------------------------
-- AC-3: the 76 template lines (one test per Appendix A row, so a wrong twin names itself)
---------------------------------------------------------------------------------------------

TestF4DuliosTemplateLines = {}

function TestF4DuliosTemplateLines:setUp() H.reset() end

local function sanitize(s) return (s:gsub("[^%w]+", "_"):gsub("_+$", "")) end

for _, site in ipairs(DS.SITES) do
	local field = site.field == "leftDialog" and "leftDialog" or ("option_" .. site.field)

	-- AC-3: the named field of the named screen is P .. twin (an option keeps its link), and the source line ends with `-- <exact client text>`
	TestF4DuliosTemplateLines["test_line_" .. site.line .. "_" .. site.screen .. "_" .. field .. "_shows_" .. site.twin .. "_" .. sanitize(DS.TEXT[site.twin]):sub(1, 40)] = function()
		local label = "dulios_convo.lua:" .. site.line .. " screen '" .. site.screen .. "' " .. field .. " (" .. site.nge .. " -> " .. site.twin .. ")"
		local screen = screens()[site.screen]

		lu.assertNotNil(screen, label .. ": the screen exists")

		if site.field == "leftDialog" then
			lu.assertEquals(screen.leftDialog, P .. site.twin, label)
		else
			local option = screen.options and screen.options[site.field]

			lu.assertNotNil(option, label .. ": the option exists")
			lu.assertEquals(option[1], P .. site.twin, label .. ": option text")
			lu.assertEquals(option[2], site.link, label .. ": option link")
		end

		local line = linesOf(readFile(DC))[site.line]

		lu.assertNotNil(line, label .. ": source line")
		line = line:gsub("\r$", "")
		lu.assertNotNil(line:find(P .. site.twin .. '"', 1, true), label .. ": the source line names the twin: " .. line)
		lu.assertNil(line:find(P .. site.nge .. '"', 1, true), label .. ": the source line still names the NGE id: " .. line)

		if site.field ~= "leftDialog" then
			lu.assertNotNil(line:find('"' .. site.link .. '"', 1, true), label .. ": the source line keeps the link: " .. line)
		else
			lu.assertNotNil(line:find("leftDialog =", 1, true), label .. ": the source line is the leftDialog line: " .. line)
		end

		lu.assertEquals(line:match("%-%-%s*(.-)%s*$"), DS.TEXT[site.twin], label .. ": trailing client-text comment")
	end
end

-- AC-3: 158 screens, no dead link or duplicate id
function TestF4DuliosTemplateLines:test_the_template_has_158_screens_and_no_dead_links_or_duplicate_ids()
	local _, t = screens()

	lu.assertEquals(#t.screens, 158, "dulios_convo_template: number of screens")
	lu.assertEquals(H.conversationProblems(D.TEMPLATE), {})
end

-- AC-3 (Appendix D): the leftDialog multiplicities
function TestF4DuliosTemplateLines:test_the_left_dialog_multiplicities_are_exactly_those_of_appendix_d()
	local owners = {}
	local _, template = screens()

	for _, s in ipairs(template.screens) do
		owners[s.leftDialog] = owners[s.leftDialog] or {}
		table.insert(owners[s.leftDialog], s.id)
	end

	local repeated = {}

	for dialog, ids in pairs(owners) do
		table.sort(ids)

		if #ids > 1 then
			repeated[sidOf(dialog)] = #ids
		end
	end

	lu.assertEquals(repeated, DS.LEFT_COUNTS, "leftDialog ids shown on more than one screen, with their screen counts")
	local gates = owners["@conversation/naboo_privateer_tier3:s_406e1216"]

	lu.assertEquals(gates, { "not_pilot", "not_tier3" }, "screens showing the D-8 line")
end

-- AC-3 (D-8, D-9, D-10): the three slots without a parallel chain
function TestF4DuliosTemplateLines:test_the_three_inferred_slots_show_the_users_choices()
	local byId = screens()

	lu.assertEquals(byId.not_tier3.leftDialog, P .. "s_406e1216", "not_tier3 (D-8)")
	lu.assertEquals(byId.first_mission.options[1], { P .. "s_c551ea96", "m1_4ad40b9b" }, "first_mission reply 1 (D-9)")
	lu.assertEquals(byId.m1_85.options[2], { P .. "s_841d27db", "m1_d5861157" }, "m1_85 reply 2 (D-10)")
end

---------------------------------------------------------------------------------------------
-- AC-4: nothing else moves, CRLF
---------------------------------------------------------------------------------------------

TestF4DuliosNothingElseMoves = {}

function TestF4DuliosNothingElseMoves:setUp() H.reset() end

-- AC-4: same line count; the lines that differ from the base are exactly the 76 of Appendix A; each equals its base line once the twin is put back and the comment removed
function TestF4DuliosNothingElseMoves:test_dulios_convo_differs_from_the_base_on_exactly_the_76_appendix_a_lines_and_only_by_id_and_comment()
	local now, old = linesOf(readFile(DC)), linesOf(baseFile(DC))
	local bySite = {}

	for _, site in ipairs(DS.SITES) do bySite[site.line] = site end

	lu.assertEquals(#now, #old, "number of lines of dulios_convo.lua (base " .. BASE .. ")")

	local differing = {}

	for i = 1, math.min(#now, #old) do
		if now[i] ~= old[i] then
			differing[#differing + 1] = i
		end
	end

	local want = {}

	for _, site in ipairs(DS.SITES) do want[#want + 1] = site.line end

	table.sort(want)
	lu.assertEquals(differing, want, "line numbers that differ from the base")

	for _, i in ipairs(differing) do
		local site = bySite[i]
		local line = now[i]

		lu.assertEquals(line:sub(-1), "\r", "line " .. i .. ": ends with CR (CRLF kept)")
		line = line:sub(1, -2)

		local suffix = " -- " .. DS.TEXT[site.twin]

		lu.assertEquals(line:sub(-#suffix), suffix, "line " .. i .. ": ends with ` -- <client text of " .. site.twin .. ">`")
		line = line:sub(1, -#suffix - 1)

		local from, to = line:find(P .. site.twin .. '"', 1, true)

		lu.assertNotNil(from, "line " .. i .. ": names " .. site.twin)
		line = line:sub(1, from - 1) .. P .. site.nge .. '"' .. line:sub(to + 1)
		lu.assertEquals(line .. "\r", old[i], "line " .. i .. ": equals the base line (screen " .. site.screen .. ")")
	end
end

-- AC-4: DuH is the base plus the Content contract 2 edits, byte for byte
function TestF4DuliosNothingElseMoves:test_the_handler_differs_from_the_base_only_by_the_contract_2_edits()
	local text = baseFile(DH)

	local function replaceOnce(old, new)
		local from, to = text:find(old, 1, true)

		lu.assertNotNil(from, "base duliosConvoHandler.lua has `" .. old:gsub("\r\n", "<CRLF>") .. "`")
		lu.assertNil(text:find(old, to + 1, true), "base: `" .. old:gsub("\r\n", "<CRLF>") .. "` occurs once")
		text = text:sub(1, from - 1) .. new .. text:sub(to + 1)
	end

	replaceOnce('local PT = "@conversation/naboo_privateer_tier3:"\r\n\r\n', "")
	replaceOnce("-- Skill, choice option sid, training screen id", "-- Skill, choice option string id, training screen id")
	replaceOnce('{ "pilot_neutral_starships_03", "s_aa766bd6", "train_warships" }', '{ "pilot_neutral_starships_03", "@conversation/naboo_privateer_tier3:s_aa766bd6", "train_warships" }')
	replaceOnce('{ "pilot_neutral_weapons_03", "s_a70b470e", "train_components" }', '{ "pilot_neutral_weapons_03", "@conversation/naboo_privateer_tier3:s_a70b470e", "train_components" }')
	replaceOnce('{ "pilot_neutral_procedures_03", "s_da0e8cd0", "train_techniques" }', '{ "pilot_neutral_procedures_03", "@conversation/naboo_privateer_tier3:s_da0e8cd0", "train_techniques" }')
	replaceOnce('{ "pilot_neutral_droid_03", "s_c28a300f", "train_programming" }', '{ "pilot_neutral_droid_03", "@conversation/naboo_privateer_tier3:s_c28a300f", "train_programming" }')
	replaceOnce("clonedConversation:addOption(PT .. choice[2], choice[3] .. screenAppend)", "clonedConversation:addOption(choice[2], choice[3] .. screenAppend)")

	local now = readFile(DH)
	local a, b = linesOf(now), linesOf(text)

	lu.assertEquals(#a, #b, "number of lines of duliosConvoHandler.lua")

	for i = 1, math.min(#a, #b) do
		lu.assertEquals(a[i], b[i], "duliosConvoHandler.lua line " .. i .. " (base plus the contract 2 edits)")
	end

	lu.assertTrue(now == text, "duliosConvoHandler.lua equals the base plus the contract 2 edits")
end

-- AC-4: both files end every line with CRLF, as at the base
function TestF4DuliosNothingElseMoves:test_both_files_end_every_line_with_crlf_including_the_last()
	for _, rel in ipairs(SOURCES) do
		local text = readFile(rel)
		local bare = select(2, text:gsub("[^\r]\n", ""))
		local crlf = select(2, text:gsub("\r\n", ""))
		local lf = select(2, text:gsub("\n", ""))

		lu.assertEquals(bare, 0, rel .. ": lines ending in a bare LF")
		lu.assertEquals(crlf, lf, rel .. ": CRLF line ends versus all line ends")
		lu.assertEquals(text:sub(-2), "\r\n", rel .. ": the final line keeps its CRLF")
		lu.assertEquals(text:sub(-2) == baseFile(rel):sub(-2), true, rel .. ": final line ending as at the base")
	end
end

-- AC-4: the template name, handler, initial screen and type are unchanged
function TestF4DuliosNothingElseMoves:test_the_template_keeps_its_name_handler_initial_screen_and_type()
	local _, t = screens()

	lu.assertEquals(t.luaClassHandler, "duliosConvoHandler", "luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.initialScreen, "", "initialScreen")
end

---------------------------------------------------------------------------------------------
-- AC-5: pre-NGE ids only
---------------------------------------------------------------------------------------------

TestF4DuliosPreNgeOnly = {}

function TestF4DuliosPreNgeOnly:setUp() H.reset() end

-- AC-5 (I-2): the 214 ids of the two files are the fixture minus s_0 and do_not_edit, and none is NGE-shaped
function TestF4DuliosPreNgeOnly:test_the_ids_of_the_two_files_are_the_214_client_ids_and_none_is_nge_numbered()
	local client = assert(CS.sids(FILE))
	local used, want = {}, {}

	for _, lit in ipairs(CS.literals(SOURCES)) do
		if lit.file == FILE then
			used[lit.id] = true
			lu.assertNil(lit.id:find("^s_%d%d?%d?$"), lit.path .. ":" .. lit.line .. " carries the NGE-numbered id " .. lit.id)
		end
	end

	for id in pairs(client) do
		if id ~= "s_0" and id ~= "do_not_edit" then
			want[id] = true
		end
	end

	lu.assertEquals(count(want), 214, "client ids minus s_0 and do_not_edit")
	lu.assertEquals(sortedKeys(used), sortedKeys(want), "ids of dulios_convo.lua and duliosConvoHandler.lua versus the client file")
end

-- AC-5: every twin is a hash id present in the fixture and in T3, of the same kind as its key
function TestF4DuliosPreNgeOnly:test_every_twin_is_a_client_hash_id_of_the_same_kind_as_its_nge_key()
	local client = assert(CS.sids(FILE))

	for _, site in ipairs(DS.SITES) do
		local label = "line " .. site.line .. " " .. site.nge .. " -> " .. site.twin

		lu.assertNotNil(site.nge:find("^s_%d%d?%d?$"), label .. ": the key is NGE-numbered")
		lu.assertNil(site.twin:find("^s_%d%d?%d?$"), label .. ": the twin is NGE-numbered")
		lu.assertTrue(client[site.twin] == true, label .. ": the twin is in the client fixture")
		lu.assertNil(client[site.nge], label .. ": the NGE key is not in the client fixture")

		if site.field == "leftDialog" then
			lu.assertNotNil(JAVA.nodes[site.nge], label .. ": the key is an NPC line")
			lu.assertNotNil(JAVA.nodes[site.twin], label .. ": the twin is an NPC line of T3 (same kind)")
			lu.assertNil(JAVA.responses[site.twin], label .. ": the twin is not a reply")
		else
			lu.assertTrue(JAVA.responses[site.nge] == true, label .. ": the key is a reply")
			lu.assertTrue(JAVA.responses[site.twin] == true, label .. ": the twin is a reply of T3 (same kind)")
			lu.assertNil(JAVA.nodes[site.twin], label .. ": the twin is not an NPC line")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: SWG conformance through the twin table
---------------------------------------------------------------------------------------------

TestF4DuliosConformance = {}

function TestF4DuliosConformance:setUp() H.reset() end

-- AC-6 (I-4): every Key row, with every sid mapped through D.TWIN; E-1 (the four reward rows have no template options) stays the only exception
function TestF4DuliosConformance:test_every_key_row_equals_its_screen_modulo_the_twin_table()
	local byId = screens()
	local seen = 0

	for _, row in ipairs(D.ROWS) do
		local screen = byId[row.id]
		local label = "screen '" .. row.id .. "' (" .. row.sid .. ")"

		lu.assertNotNil(screen, label .. ": exists")
		seen = seen + 1
		lu.assertEquals(screen.leftDialog, P .. twin(row.sid), label .. ": leftDialog")
		lu.assertEquals(screen.stopConversation, row.stop and "true" or "false", label .. ": stopConversation")
		lu.assertEquals(screen.animation or "", row.animation, label .. ": animation")

		local got, want = {}, {}

		for i, o in ipairs(screen.options or {}) do got[i] = { o[1], o[2] } end
		for i, o in ipairs(row.options) do want[i] = { P .. twin(o[1]), o[2] } end

		lu.assertEquals(got, want, label .. ": options (twin sids, same links)" .. (D.EXCEPTIONS[row.id] and " [E-1]" or ""))
	end

	lu.assertEquals(seen, 150, "Key rows checked")
end

-- AC-6: option links and successors agree with the java graph through the twin table (the java successor of the key's reply, mapped)
function TestF4DuliosConformance:test_every_option_leads_to_the_twin_of_its_java_successor()
	local byId = screens()
	local checked = 0

	for _, row in ipairs(D.ROWS) do
		if D.EXCEPTIONS[row.id] == nil then
			local screen = byId[row.id]

			for i, optionSid in ipairs(JAVA.nodes[row.sid].options) do
				local target = byId[screen.options[i][2]]
				local successors = JAVA.successorsOf(row.sid, optionSid)

				lu.assertNotNil(target, row.id .. " option " .. i .. ": link is a screen")
				lu.assertEquals(sidOf(screen.options[i][1]), twin(optionSid), row.id .. " option " .. i .. ": reply (twin of " .. optionSid .. ")")
				lu.assertEquals(sidOf(target.leftDialog), twin(successors[#successors]), row.id .. " option " .. optionSid .. ": NPC line of the target (twin of the java successor)")
				checked = checked + 1
			end
		end
	end

	lu.assertEquals(checked, 132, "options checked (Key rows other than the four E-1 reward rows)")
end

-- AC-6: T3 usage is 111 of 154 NPC lines and 95 of 133 replies; the unused are the twin keys plus s_368-s_372
function TestF4DuliosConformance:test_the_files_use_111_of_154_npc_lines_and_95_of_133_replies_and_the_unused_are_the_twin_keys_plus_s_368_to_s_372()
	local usedNpc, usedResp = {}, {}

	for _, lit in ipairs(CS.literals(SOURCES)) do
		if lit.file == FILE then
			if JAVA.nodes[lit.id] then usedNpc[lit.id] = true end
			if JAVA.responses[lit.id] then usedResp[lit.id] = true end
		end
	end

	local unusedNpc, unusedResp = {}, {}

	for _, sid in ipairs(JAVA.order) do
		if not usedNpc[sid] then unusedNpc[#unusedNpc + 1] = sid end
	end

	for sid in pairs(JAVA.responses) do
		if not usedResp[sid] then unusedResp[#unusedResp + 1] = sid end
	end

	table.sort(unusedNpc)
	table.sort(unusedResp)

	local wantNpc, wantResp = { "s_369", "s_370", "s_371", "s_372" }, { "s_368" }

	for nge in pairs(DS.TWIN) do
		if JAVA.nodes[nge] then wantNpc[#wantNpc + 1] = nge else wantResp[#wantResp + 1] = nge end
	end

	table.sort(wantNpc)
	table.sort(wantResp)
	lu.assertEquals(count(usedNpc), 111, "T3 NPC lines used")
	lu.assertEquals(count(usedResp), 95, "T3 replies used")
	lu.assertEquals(#JAVA.order, 154, "T3 NPC lines")
	lu.assertEquals(unusedNpc, wantNpc, "unused NPC lines (39 twin keys + s_369-s_372)")
	lu.assertEquals(unusedResp, wantResp, "unused replies (37 twin keys + s_368)")
end

---------------------------------------------------------------------------------------------
-- AC-7: behavior unchanged, and every transcript resolves in the client
---------------------------------------------------------------------------------------------

TestF4DuliosBehavior = {}

function TestF4DuliosBehavior:setUp() H.reset() end
function TestF4DuliosBehavior:tearDown() restore() H.Engine.config.jtlEnabled = true end

local function templateScreen(id) return screens()[id] end

-- name, builder, expected screen
local GATES = {
	{ "a_player_without_pilot_skills", function() return G.pilot({ kind = "none" }) end, "not_pilot" },
	{ "a_rebel_pilot", function() return G.pilot({ kind = "rebel" }) end, "wrong_faction" },
	{ "a_corsec_neutral_pilot_of_tier_3", function() return G.offTrack({ pilotTier = 3, tier1 = 4 }) end, "pilot_not_rsf" },
	{ "an_rsf_pilot_of_tier_0", function() return G.rsfPilot({ pilotTier = 0, tier1 = 0 }) end, "not_tier3" },
	{ "an_rsf_pilot_of_tier_1", function() return G.rsfPilot({ pilotTier = 1 }) end, "not_tier3" },
	{ "an_rsf_pilot_of_tier_2", function() return G.rsfPilot({ pilotTier = 2 }) end, "not_tier3" },
}

for n, chain in ipairs(tr.chains) do
	for _, member in ipairs(chain) do
		GATES[#GATES + 1] = { "an_rsf_tier_3_pilot_with_" .. member .. "_active", function() return T.player(tr, n, { active = { member } }) end, "on_mission" }
	end
end

for _, gate in ipairs(GATES) do
	-- AC-7: every gate state shows the same screen id and animation as at the base; not_tier3 shows the D-8 line; the conversation ends; the line resolves
	TestF4DuliosBehavior["test_gate_" .. gate[1] .. "_shows_" .. gate[3] .. "_with_its_base_animation_and_a_resolvable_line"] = function()
		local transcript = T.converse(tr, gate[2]())
		local row = ROWS[gate[3]]

		lu.assertEquals(#transcript, 1, gate[1] .. ": screens shown")
		lu.assertEquals(transcript[1].id, gate[3], gate[1] .. ": screen")
		lu.assertTrue(transcript[1].stop, gate[1] .. ": the conversation ends")
		lu.assertEquals(templateScreen(gate[3]).animation, row.animation, gate[1] .. ": animation of " .. gate[3])
		lu.assertEquals(sidOfStep(transcript[1]), twin(row.sid), gate[1] .. ": line of " .. gate[3])
		noUnresolved(transcript, gate[1])

		if gate[3] == "not_tier3" then
			lu.assertEquals(transcript[1].text, P .. "s_406e1216", gate[1] .. ": the D-8 line (\"Looks like you took a wrong turn somewhere. Scram.\")")
		end
	end
end

-- AC-7: migrateLegacyProgress is the first call of a conversation
function TestF4DuliosBehavior:test_migrate_legacy_progress_runs_before_any_check()
	local log = {}
	local original = RsfSquadronScreenplay.migrateLegacyProgress
	local isPilot = SpaceHelpers.isPilot

	RsfSquadronScreenplay.migrateLegacyProgress = function(...)
		log[#log + 1] = "migrate"
		return original(...)
	end
	SpaceHelpers.isPilot = function(...)
		log[#log + 1] = "isPilot"
		return isPilot(...)
	end

	local ok, err = pcall(T.converse, tr, G.rsfPilot({ pilotTier = 2 }))

	RsfSquadronScreenplay.migrateLegacyProgress = original
	SpaceHelpers.isPilot = isPilot
	lu.assertTrue(ok, tostring(err))
	lu.assertEquals(log[1], "migrate", "first call among the migration and the pilot check (" .. table.concat(log, ",") .. ")")
end

-- A pilot at mission n who never attempted it; every complete path through its offer tree: { choices, transcript }
local function offerPilot(n) return T.player(tr, n, { attempted = false }) end

local function allPaths(n)
	local paths = {}

	local function walk(choices, depth)
		lu.assertTrue(depth < 40, "mission " .. n .. ": the offer tree is deeper than 40 screens (a cycle?)")

		local transcript = T.converse(tr, offerPilot(n), choices)
		local last = transcript[#transcript]

		lu.assertNotNil(last, "mission " .. n .. ": no screen for choices {" .. table.concat(choices, ",") .. "}")

		if last.stop then
			paths[#paths + 1] = { choices = choices, transcript = transcript }
			return
		end

		lu.assertTrue(#last.options > 0, "mission " .. n .. ": screen '" .. last.id .. "' neither ends the conversation nor offers an option")

		for i = 1, #last.options do
			local nextChoices = { table.unpack(choices) }

			nextChoices[#nextChoices + 1] = i - 1
			walk(nextChoices, depth + 1)
		end
	end

	walk({}, 0)

	return paths
end

for n = 1, 4 do
	-- AC-7: 8/4/4/2 paths, each ending on its base start screen, which sets :attempted and starts the head once; nothing earlier starts, pays or grants;
	-- every screen and option of every path resolves in the client
	TestF4DuliosBehavior["test_the_offer_walk_of_mission_" .. n .. "_gives_" .. D.PATH_COUNTS[n] .. "_paths_that_start_it_once_on_the_base_start_screens_and_resolve_in_the_client"] = function()
		local paths = allPaths(n)
		local ends, wanted = {}, {}

		lu.assertEquals(#paths, D.PATH_COUNTS[n], "mission " .. n .. ": number of complete paths")

		for _, id in ipairs(D.OFFER_STARTS[n]) do wanted[#wanted + 1] = id end

		for _, p in ipairs(paths) do
			local last = p.transcript[#p.transcript]
			local label = "mission " .. n .. " path {" .. table.concat(p.choices, ",") .. "} ending on " .. last.id

			ends[#ends + 1] = last.id
			noUnresolved(p.transcript, label)

			if #p.choices > 0 then
				H.reset()

				local player = offerPilot(n)
				local calls = tapChains()
				local rec = T.spyAllQuests()

				T.converse(tr, player, { table.unpack(p.choices, 1, #p.choices - 1) })
				restore()
				lu.assertEquals(#calls, 0, label .. ": startSpaceQuestChain calls before the last screen")
				lu.assertNil(attempted(player, n), label .. ": :attempted before the last screen")
				lu.assertEquals(rec.rewards, {}, label .. ": rewardPlayer calls before the last screen")
				lu.assertEquals(#rec.skills, 0, label .. ": grantSpaceSkill calls before the last screen")
			end

			H.reset()

			local player = offerPilot(n)
			local calls = tapChains()
			local rec = T.spyRewards()

			T.converse(tr, player, p.choices)
			restore()
			lu.assertEquals(headIds(calls), { D.HEADS[n] }, label .. ": startSpaceQuestChain heads")
			lu.assertEquals(attempted(player, n), "1", label .. ": :attempted")
			lu.assertEquals(rec.rewards, {}, label .. ": rewardPlayer calls")
		end

		table.sort(ends)
		table.sort(wanted)
		lu.assertEquals(ends, wanted, "mission " .. n .. ": the screens the paths end on")
	end
end

-- Failed states of mission n: no chain entry, or a later member failed
for n = 1, 4 do
	for reply = 0, 1 do
		-- AC-7: each failure reply re-grants its mission (once, with the head) and every screen resolves; the failure screen itself starts nothing
		TestF4DuliosBehavior["test_mission_" .. n .. "_failure_reply_" .. (reply + 1) .. "_restarts_the_head_and_resolves_in_the_client"] = function()
			local player = T.player(tr, n, { complete = {} })
			local calls = tapChains()
			local rec = T.spyRewards()
			local transcript = T.converse(tr, player, { reply })

			restore()
			lu.assertEquals(transcript[1].id, D.FAILED[n], "mission " .. n .. ": first screen")
			lu.assertEquals(transcript[2].id, D.RETRY_STARTS[n][reply + 1], "mission " .. n .. ": second screen")
			lu.assertEquals(headIds(calls), { D.HEADS[n] }, "mission " .. n .. ": startSpaceQuestChain heads")
			lu.assertEquals(attempted(player, n), "1", "mission " .. n .. ": :attempted")
			lu.assertEquals(rec.rewards, {}, "mission " .. n .. ": rewardPlayer calls")
			noUnresolved(transcript, "mission " .. n .. " failure reply " .. (reply + 1))
		end
	end
end

-- AC-7: the reward screens pay once with :reward written first, and offer exactly the base option strings and links for 0..3 skills held
local SKILLS = {}

for i, c in ipairs(D.TRAIN_CHOICES) do SKILLS[i] = c[1] end

for n = 1, 4 do
	TestF4DuliosBehavior["test_reward_screen_of_mission_" .. n .. "_pays_once_reward_key_first_and_offers_the_base_option_strings_for_" .. (n - 1) .. "_skills"] = function()
		local player = T.player(tr, n, { complete = tr.chains[n], attempted = false })
		local order = H.spyOn(_G[D.HEADS[n]], "rewardPlayer", function() return rewarded(player, n) end)
		local transcript = T.converse(tr, player)
		local again = T.converse(tr, player)

		lu.assertEquals(transcript[1].id, D.COMPLETE[n], "mission " .. n .. ": first screen")
		lu.assertEquals(#order, 1, "mission " .. n .. ": rewardPlayer calls over two visits")
		lu.assertEquals(order[1].snapshot, "1", "mission " .. n .. ": :reward is already set when rewardPlayer runs")
		lu.assertEquals(rewarded(player, n), "1", "mission " .. n .. ": :reward")

		local held = {}

		for _, skill in ipairs(SKILLS) do
			if player:hasSkill(skill) then held[skill] = true end
		end

		local want, missing = {}, {}

		for _, c in ipairs(D.TRAIN_CHOICES) do
			if not held[c[1]] then missing[#missing + 1] = c end
		end

		lu.assertEquals(#missing, 4 - (n - 1), "mission " .. n .. ": missing skills")

		for i, c in ipairs(missing) do
			want[i] = { P .. c[2], c[3] .. ((#missing == 1) and "_final" or "") }
		end

		local got = {}

		for i, o in ipairs(transcript[1].options) do got[i] = { o.text, o.link } end

		lu.assertEquals(got, want, "mission " .. n .. ": option strings and links (complete ids, as at the base)")

		local got2 = {}

		for i, o in ipairs(again[1].options) do got2[i] = { o.text, o.link } end

		lu.assertEquals(got2, want, "mission " .. n .. ": option strings of the second visit")
		noUnresolved(transcript, "mission " .. n .. " reward screen")
	end
end

-- AC-7: every choice grants the skill free, once; the 4th skill gives tier 4, then completed_dulios; every training transcript resolves
for k, choice in ipairs(D.TRAIN_CHOICES) do
	TestF4DuliosBehavior["test_choosing_" .. choice[3] .. "_at_the_mission_1_reward_grants_" .. choice[1] .. "_free_once_and_resolves_in_the_client"] = function()
		local player = T.player(tr, 1, { complete = tr.chains[1], attempted = false })
		local skills = H.spyOn(SpaceHelpers, "grantSpaceSkill")
		local transcript = T.converse(tr, player, { k - 1 })

		lu.assertEquals(transcript[2].id, choice[3], "second screen")
		lu.assertTrue(transcript[2].stop, "the training screen ends the conversation")
		lu.assertEquals(#skills, 1, "grantSpaceSkill calls")
		lu.assertEquals(skills[1].args[2], choice[1], "granted skill")
		lu.assertEquals(skills[1].args[3], false, "deductExperience argument (free)")
		noUnresolved(transcript, "training " .. choice[3])
	end
end

function TestF4DuliosBehavior:test_the_fourth_skill_gives_tier_4_and_the_next_visit_is_completed_dulios()
	local player = T.player(tr, 4, { complete = tr.chains[4], attempted = false })
	local last

	for _, c in ipairs(D.TRAIN_CHOICES) do
		if not player:hasSkill(c[1]) then last = c end
	end

	local transcript = T.converse(tr, player, { 0 })

	lu.assertNotNil(last, "precondition: one tier 3 skill is missing")
	lu.assertEquals(transcript[1].id, "complete_mission4", "first screen")
	lu.assertEquals(transcript[2].id, last[3] .. "_final", "second screen (the last missing skill)")
	lu.assertEquals(player.ghost:getPilotTier(), 4, "pilot tier after the fourth skill")
	noUnresolved(transcript, "fourth skill")

	local again = T.converse(tr, player)

	lu.assertEquals(again[1].id, "completed_dulios", "next visit")
	noUnresolved(again, "completed_dulios")
end

-- AC-7: the D-5 fallthrough is unchanged (a veteran with 4f complete and one skill sees complete_mission4, paid once)
function TestF4DuliosBehavior:test_the_d5_fallthrough_still_shows_complete_mission4_and_pays_once()
	local player = T.player(tr, 2, { win = { 1 }, complete = tr.chains[4], attempted = false, baseSkills = { "pilot_neutral_starships_03" } })
	local rec = T.spyRewards()
	local transcript = T.converse(tr, player)

	lu.assertEquals(transcript[1].id, "complete_mission4", "first screen")
	lu.assertEquals(rec.rewards, { D.HEADS[4] }, "rewardPlayer calls")
	noUnresolved(transcript, "D-5 fallthrough")
	lu.assertEquals(#transcript[1].options, 3, "choices left")
end
