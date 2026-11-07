-- Client string ids of Imler (RSF tier 4), part 1 (F6a) of the space conversation client-string work: gates, duty briefing and training.
-- Spec: .claude/work/space-convo-client-strings-imler-a/01-spec.md (AC-1 .. AC-9; I-1 .. I-6; D-1 .. D-14; FI-1 .. FI-8; Content contract 1 .. 4; Appendix A .. F).
--
-- Imler shows 211 NGE-numbered ids that the pre-NGE client cannot resolve. This feature fixes 15 of them (the other 196, the four mission briefings, are F6b):
--   * s_4, s_9, s_416 are copies of earlier pre-NGE lines (FI-3): each is rewritten in place onto its twin (the client's ids are CRCs of the text, so a copy has the id of the
--     line it repeats), with a trailing `-- <client text>` comment (D-12, D-13);
--   * the NGE training dialogue (s_439-s_449) and the four post-training intros (s_451, s_489, s_623, s_737) are removed: training is one click on Imler's own "Teach me about ..."
--     replies, the click buys the skill when leaving ready_train and lands on mission<k>_brief, which sets the ready flag (D-3 .. D-6, D-14).
--
-- The twin of every NGE id and the client text of every twin are copied from the spec (rsf_tier4_imler_client_strings_data.lua), not read from imler_convo.lua, so a wrong twin
-- fails here instead of agreeing with itself. Each quoted text is also checked against its id: the client's ids are the SWG CRC-32 of the text.
-- The I4 answer key (rsf_tier4_data.lua, the java graph) stays the SWG graph; conformance runs through the twin table (I-3, D-9) with training as the one exception (E-IM1).
-- The behavior tests (routing, offers, rewards, training, duties) are the superseded tests of Appendix C, updated in test_rsf_tier4_imler_*.lua and
-- test_pilot_training_free_choice_*.lua; this file adds the 32-row training table, the transcript scans and the journeys through the changed chains.

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local D = require("rsf_tier4_data") -- the I4 answer key (screen ids -> SWG sid), pilot builder
local C = require("pilot_training_free_choice_data")
local KD = require("space_convo_client_strings_data")
local DS = require("rsf_tier4_imler_client_strings_data") -- Appendix A, B, D, E, F
local FB = require("rsf_tier4_imler_b_client_strings_data") -- space-convo-client-strings-imler-b (F6b): Appendix G, the 126 pool lines, Appendix P
local Swgjava = require("harness.swgjava")

H.loadSquadron("RsfSquadronScreenplay")
H.loadMobile("conversations/space/neutral/rsf_squadron/imler_convo.lua")
H.loadScreenplay("space/conversations/neutral/rsf_squadron/imlerConvoHandler.lua")

local P = DS.PREFIX
local BASE = DS.BASE

local IC = "mobile/conversations/space/neutral/rsf_squadron/imler_convo.lua"
local IH = "screenplays/space/conversations/neutral/rsf_squadron/imlerConvoHandler.lua"
local SOURCES = { IC, IH }
local FILE = DS.FILE
local TEMPLATE = "imler_convo_template"

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_tier4.java")
local COST = 1000000
local REAL_SKILL_MANAGER = LuaSkillManager

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

-- Lines of a text split on "\n"; each keeps any "\r" (so the line endings can be checked)
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

local function copy(list)
	local out = {}

	for i, v in ipairs(list) do out[i] = v end

	return out
end

local function twin(sid) return DS.TWIN[sid] or sid end

-- space-convo-client-strings-imler-b (E-IM2, Appendix C): the 196 NGE ids of the four subtrees are not mirrored by Core3 any more, and the briefs' options are Appendix G's
local SUBTREE = {}

for _, id in ipairs(DS.REMAINING) do SUBTREE[id] = true end

local BRIEF_SCREENS = { mission1_brief = true, mission2_brief = true, mission3_brief = true, mission4_brief = true }

local function sanitize(s) return (s:gsub("[^%w]+", "_"):gsub("_+$", "")) end

-- The SWG string CRC-32 (polynomial 0x04C11DB7, MSB first, init and final XOR 0xFFFFFFFF) of a line; the client's id of the line is "s_" .. hex
local function crcId(text)
	local crc = 0xFFFFFFFF

	for i = 1, #text do
		crc = crc ~ (text:byte(i) << 24)

		for _ = 1, 8 do
			if crc & 0x80000000 ~= 0 then
				crc = ((crc << 1) ~ 0x04C11DB7) & 0xFFFFFFFF
			else
				crc = (crc << 1) & 0xFFFFFFFF
			end
		end
	end

	return string.format("s_%x", (~crc) & 0xFFFFFFFF)
end

local function screens()
	local byId = {}
	local t = H.conversationTemplateTable(TEMPLATE)

	lu.assertNotNil(t, TEMPLATE .. " is registered")

	for _, s in ipairs(t.screens) do
		byId[s.id] = s
	end

	return byId, t
end

local function handler() return H.expectGlobal("imlerConvoHandler", "Imler conversation handler (imlerConvoHandler.lua)") end

local function converse(player, choices)
	return H.converse({ template = TEMPLATE, player = player, npc = H.newNpc({ name = "Admiral Diness Imler" }), choices = choices })
end

local function ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do out[i] = step.id end

	return out
end

local function noUnresolved(transcript, label)
	lu.assertEquals(CS.transcriptUnresolved(transcript), {}, label .. ": ids the pre-NGE client cannot resolve")
end

-- A transcript that ends on a mission<k>_brief screen: the brief's own line is pre-NGE, its options are F6b's (I-2), so the last step is scanned without them
local function noUnresolvedUpToBrief(transcript, label)
	local scan = {}

	for i, step in ipairs(transcript) do scan[i] = step end

	local last = transcript[#transcript]

	scan[#scan] = { id = last.id, text = last.text, options = {}, params = last.params, stop = last.stop }
	noUnresolved(scan, label)
end

local function exp(player) return player.ghost.experience.space_combat_general end

local function costs()
	local out = {}

	for _, row in ipairs(DS.TRAINING) do out[row.skill] = COST end

	H.Engine.config.skillXpCosts = out
end

local function names(held)
	local out = {}

	for i, skill in ipairs(held) do out[i] = skill:match("^pilot_neutral_(%a+)_04$") end

	return out
end

-- A met pilot who won and was paid missions 1..#held, holds `held` (skill ids) and has `amount` space XP: ready_train is the first screen
local function trainee(held, amount)
	local rewards, attempted, completed = {}, {}, {}

	for i = 1, #held do
		rewards[i] = i
		attempted[i] = i
		completed[i] = D.MISSION[i].wins[1]
	end

	return D.rsf({ tier4 = names(held), rewards = rewards, attempted = attempted, completed = completed, xp = amount or 2 * COST, met = true })
end

local function spyAllQuests()
	local rec = { starts = {}, rewards = {} }

	for _, name in ipairs(H.questGlobals()) do
		local quest = rawget(_G, name)

		H.spyOn(quest, "startQuest", function() rec.starts[#rec.starts + 1] = name end)
		H.spyOn(quest, "rewardPlayer", function() rec.rewards[#rec.rewards + 1] = name end)
	end

	return rec
end

-- I4 option sids from NPC line `from` to `to` (screen names of D.SCREENS or I4 sids)
local function i4Path(from, to)
	local path = GRAPH.pathTo(D.SCREENS[from] or from, D.SCREENS[to] or to)

	lu.assertNotNil(path, "answer key: no option path from " .. from .. " to " .. to)

	return path
end

-- the NPC sids the java shows along an option path (no conditional option on these paths)
local function i4Lines(from, path)
	local cur = D.SCREENS[from] or from
	local out = { cur }

	for _, opt in ipairs(path) do
		local successors = GRAPH.successorsOf(cur, opt)

		lu.assertNotNil(successors, "answer key: no successor for " .. cur .. " -> " .. opt)
		cur = successors[#successors]
		out[#out + 1] = cur
	end

	return out
end

local function concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do out[#out + 1] = v end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- sanity of the copied answer key
---------------------------------------------------------------------------------------------

TestF6aImlerAnswerKey = {}

function TestF6aImlerAnswerKey:setUp() H.reset() end

-- AC-2, AC-3 (sanity of the data copied from the spec)
function TestF6aImlerAnswerKey:test_appendix_a_has_3_lines_and_appendix_b_7_texts_that_are_the_content_hashes_of_their_ids()
	lu.assertEquals(#DS.SITES, 3, "Appendix A rows")
	lu.assertEquals(count(DS.TWIN), 3, "distinct NGE ids")
	lu.assertEquals(count(DS.TEXT), 7, "Appendix B texts (3 twins + 4 training replies)")

	for id, text in pairs(DS.TEXT) do
		lu.assertEquals(crcId(text), id, "Appendix B: the client id of \"" .. text .. "\"")
	end

	for key, row in pairs(DS.BRIEF) do
		lu.assertEquals(crcId(row.text), row.sid, "Appendix B: the client id of the unchanged line of " .. key .. " \"" .. row.text .. "\"")
	end
end

-- AC-1, AC-2 (sanity): the lists agree with each other
function TestF6aImlerAnswerKey:test_the_15_removed_ids_and_the_196_remaining_ids_partition_the_211_of_the_base()
	local removed, remaining = {}, {}

	for _, id in ipairs(DS.F6A_IDS) do removed[id] = true end
	for _, id in ipairs(DS.REMAINING) do remaining[id] = true end

	lu.assertEquals(#DS.F6A_IDS, 15, "F6a ids")
	lu.assertEquals(count(removed), 15, "distinct F6a ids")
	lu.assertEquals(#DS.REMAINING, 196, "Appendix F ids")
	lu.assertEquals(count(remaining), 196, "distinct Appendix F ids")

	for id in pairs(removed) do lu.assertNil(remaining[id], id .. " is in both lists") end

	-- the F6a ids are the 3 copies plus the 12 ids of the 8 deleted screens
	local expected = { s_4 = true, s_9 = true, s_416 = true }

	for _, id in ipairs(DS.TRAINING_NGE_IDS) do expected[id] = true end

	lu.assertEquals(sortedKeys(removed), sortedKeys(expected), "F6a ids = the 3 copies + the 12 training ids")

	for id in pairs(removed) do lu.assertNotNil(GRAPH.nodes[id] or GRAPH.responses[id], id .. " is an id of the java") end
	for id in pairs(remaining) do lu.assertNotNil(GRAPH.nodes[id] or GRAPH.responses[id], id .. " is an id of the java") end
end

---------------------------------------------------------------------------------------------
-- AC-1: the ratchet
---------------------------------------------------------------------------------------------

TestF6aImlerStaticUnresolved = {}

function TestF6aImlerStaticUnresolved:setUp() H.reset() end

-- AC-1 (I-1): 211 before F6a, 196 after it; none after space-convo-client-strings-imler-b (F6b, 01-spec.md Appendix C). Renamed from
-- test_imlers_files_show_exactly_the_196_ids_of_appendix_f_that_the_client_cannot_resolve.
function TestF6aImlerStaticUnresolved:test_imlers_files_show_no_id_that_the_client_cannot_resolve()
	lu.assertEquals(CS.unresolved(SOURCES), {}, "Imler: ids the pre-NGE client cannot resolve")
end

-- AC-1: KNOWN_GAPS is empty (space-convo-client-strings-imler-b, Appendix C). Renamed from
-- test_known_gaps_hold_the_one_file_with_the_196_f6b_ids_and_none_of_the_15_f6a_ids.
function TestF6aImlerStaticUnresolved:test_known_gaps_is_empty_and_lists_none_of_the_211_ids_of_imlers_file()
	lu.assertEquals(KD.KNOWN_GAPS, {}, "KNOWN_GAPS")
	lu.assertEquals(sortedKeys(KD.KNOWN_GAPS), {}, "KNOWN_GAPS files")
	lu.assertNil(KD.KNOWN_GAPS[FILE], "KNOWN_GAPS entry of Imler's file")
end

-- AC-1: the scan of every space conversation source equals the ratchet exactly
function TestF6aImlerStaticUnresolved:test_the_unresolved_ids_of_all_space_conversations_equal_known_gaps()
	lu.assertEquals(CS.unresolvedByFile(CS.spaceConversationSources()), KD.KNOWN_GAPS, "unresolvedByFile versus KNOWN_GAPS")
end

-- AC-1: FIXTURE_COUNTS keeps its entries (44 since black-epsilon-tier1-hakassha, 45 since black-epsilon-tier2-prisk, 46 since black-epsilon-tier3-haymir, 47 since black-epsilon-tier4-nin-gursawe, 48 since space-master-trainer-imperial, 49 since space-master-trainer-rebel, 50 since smuggler-tier1-dravis, 51 since smuggler-transition-karrde, 52 since smuggler-tier2-shamdon, 53 since smuggler-tier3-beissa, 54 since smuggler-tier4-nirame, 55 since inquisition-tier1-barn-sinkko, 56 since inquisition-tier2-fa-zoll, 57 since inquisition-tier3-vrke, 58 since inquisition-tier3-barlow, 59 since inquisition-tier4-jace-yiaso, 60 since storm-tier1-akal-colzet, 61 since storm-tier2-oberhaur, 64 since storm-tier2-nym-technicians, 65 since storm-tier2-alozen, 66 since storm-tier3-denner, 67 since storm-tier4-kilnstrider) (corellia_privateer_tier4 stays: Turoldine still references it)
function TestF6aImlerStaticUnresolved:test_fixture_counts_still_hold_the_60_referenced_files_including_corellia_privateer_tier4()
	local referenced = CS.referencedFiles(CS.spaceConversationSources())

	lu.assertEquals(count(KD.FIXTURE_COUNTS), 72, "FIXTURE_COUNTS entries") -- 61 since storm-tier2-oberhaur, 64 since storm-tier2-nym-technicians, 65 since storm-tier2-alozen, 66 since storm-tier3-denner, 67 since storm-tier4-kilnstrider, 68 since vortex-tier1-kiizete, 69 since vortex-tier2-vrovel, 70 since vortex-tier3-ezkiel, 71 since vortex-tier4-extok-evin-convo, 72 since crimson-phoenix-tier1-da-la-socuna
	lu.assertEquals(referenced, sortedKeys(KD.FIXTURE_COUNTS), "string files referenced by the space conversation sources")
	lu.assertNotNil(KD.FIXTURE_COUNTS["conversation/corellia_privateer_tier4"], "FIXTURE_COUNTS entry of Turoldine's file")
end

-- AC-1, AC-2: none of the 15 F6a ids is named in either file
function TestF6aImlerStaticUnresolved:test_none_of_the_15_f6a_ids_is_named_in_either_file()
	for _, rel in ipairs(SOURCES) do
		local text = readFile(rel)

		for _, id in ipairs(DS.F6A_IDS) do
			lu.assertNil(text:find(P .. id .. '"', 1, true), rel .. " still carries " .. id)
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: pre-NGE ids only for the changed slots
---------------------------------------------------------------------------------------------

TestF6aImlerPreNgeOnly = {}

function TestF6aImlerPreNgeOnly:setUp() H.reset() end

-- AC-2: every twin is a hash id present in the fixture; s_aa1834ec and s_35a5b893 are I4 NPC lines, s_3f68df7d is a reply that is not in the java
function TestF6aImlerPreNgeOnly:test_every_twin_is_a_client_hash_id_of_the_same_kind_as_its_nge_key()
	local client = assert(CS.sids(FILE))

	for _, site in ipairs(DS.SITES) do
		local label = "line " .. site.line .. " " .. site.nge .. " -> " .. site.twin

		lu.assertNotNil(site.nge:find("^s_%d%d?%d?$"), label .. ": the key is NGE-numbered")
		lu.assertNil(site.twin:find("^s_%d%d?%d?$"), label .. ": the twin is NGE-numbered")
		lu.assertTrue(client[site.twin] == true, label .. ": the twin is in the client fixture")
		lu.assertNil(client[site.nge], label .. ": the NGE key is not in the client fixture")
	end

	lu.assertNotNil(GRAPH.nodes.s_aa1834ec, "s_aa1834ec is an NPC line of I4")
	lu.assertNotNil(GRAPH.nodes.s_35a5b893, "s_35a5b893 is an NPC line of I4")
	lu.assertNil(GRAPH.nodes.s_3f68df7d, "s_3f68df7d is not an NPC line of I4")
	lu.assertNil(GRAPH.responses.s_3f68df7d, "s_3f68df7d is client-only (not a reply of the java)")
	lu.assertNotNil(GRAPH.nodes.s_9, "the key s_9 is an NPC line")
	lu.assertNotNil(GRAPH.nodes.s_4, "the key s_4 is an NPC line")
	lu.assertTrue(GRAPH.responses.s_416 == true, "the key s_416 is a reply")
end

-- AC-2: the four training replies are in the client fixture and not in I4
function TestF6aImlerPreNgeOnly:test_the_4_training_replies_are_in_the_client_fixture_and_not_in_i4()
	local client = assert(CS.sids(FILE))

	for _, row in ipairs(DS.TRAINING) do
		lu.assertTrue(client[row.sid] == true, row.sid .. ": in the client fixture")
		lu.assertNil(GRAPH.nodes[row.sid], row.sid .. ": is not an NPC line of I4")
		lu.assertNil(GRAPH.responses[row.sid], row.sid .. ": is not a reply of I4")
	end
end

-- AC-2: Imler's files reference no corellia_privateer_tier4 id any more (the borrowed replies are gone)
function TestF6aImlerPreNgeOnly:test_imlers_files_reference_no_corellia_privateer_tier4_id_any_more()
	for _, lit in ipairs(CS.literals(SOURCES)) do
		lu.assertNotEquals(lit.file, "conversation/corellia_privateer_tier4", lit.path .. ":" .. lit.line .. " still names Turoldine's string file (" .. lit.id .. ")")
	end

	for _, rel in ipairs(SOURCES) do
		lu.assertNil(readFile(rel):find("corellia_privateer_tier4", 1, true), rel .. " still names corellia_privateer_tier4")
	end
end

-- AC-2, AC-8: IC and IH use 258 distinct ids of their own file (the whole client file but s_0 and do_not_edit): 74 NPC lines, 54 replies and 130 client-only lines
-- (space-convo-client-strings-imler-b, Appendix C). Renamed from test_the_files_use_329_distinct_ids_172_npc_lines_152_replies_and_5_client_only_lines.
function TestF6aImlerPreNgeOnly:test_the_files_use_258_distinct_ids_74_npc_lines_54_replies_and_130_client_only_lines()
	local used, npc, resp, other = {}, 0, 0, {}

	for _, lit in ipairs(CS.literals(SOURCES)) do
		if lit.file == FILE and not used[lit.id] then
			used[lit.id] = true

			if GRAPH.nodes[lit.id] then
				npc = npc + 1
			elseif GRAPH.responses[lit.id] then
				resp = resp + 1
			else
				other[#other + 1] = lit.id
			end
		end
	end

	table.sort(other)
	lu.assertEquals({ npc, resp, #other }, { 74, 54, 130 }, "distinct ids used (NPC lines, replies, client-only)")
	lu.assertEquals(count(used), 258, "distinct ids used")
	lu.assertEquals(other, FB.CLIENT_ONLY, "the ids that are not in the java")

	local client = {}

	for id in pairs(assert(CS.sids(FILE))) do client[id] = true end

	client.s_0, client.do_not_edit = nil, nil
	lu.assertEquals(sortedKeys(used), sortedKeys(client), "the ids used are the ids of the client file but s_0 and do_not_edit")
end

---------------------------------------------------------------------------------------------
-- AC-3: the 3 template lines (one test per Appendix A row, so a wrong twin names itself)
---------------------------------------------------------------------------------------------

TestF6aImlerTemplateLines = {}

function TestF6aImlerTemplateLines:setUp() H.reset() end

for _, site in ipairs(DS.SITES) do
	local field = site.field == "leftDialog" and "leftDialog" or ("option_" .. site.field)

	-- AC-3: the named field of the named screen is P .. twin (an option keeps its link), and the source line ends with `-- <exact client text>`
	TestF6aImlerTemplateLines["test_line_" .. site.line .. "_" .. site.screen .. "_" .. field .. "_shows_" .. site.twin .. "_" .. sanitize(DS.TEXT[site.twin]):sub(1, 40)] = function()
		local label = "imler_convo.lua:" .. site.line .. " screen '" .. site.screen .. "' " .. field .. " (" .. site.nge .. " -> " .. site.twin .. ")"
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

		-- the source line of a swap that sits before the deleted block keeps its number; after it the lines move up
		-- space-convo-client-strings-imler-b (Appendix C): the replaced subtree block (base 8c4e07808b lines 325-1072) also sits before wrong_faction, so it moves up by 302 more lines
		local shift = site.line > DS.DELETED_TO and (FB.AC_LINES - DS.AC_BASE_LINES) or 0
		local line = linesOf(readFile(IC))[site.line + shift]

		lu.assertNotNil(line, label .. ": source line")
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

-- AC-3 (D-7): the swapped screens keep their animation, stop flag and options
function TestF6aImlerTemplateLines:test_the_swapped_screens_keep_their_animation_stop_flag_and_options()
	local byId = screens()

	lu.assertEquals(byId.s_9.animation, "wave_on_dismissing", "s_9: animation")
	lu.assertEquals(byId.s_9.stopConversation, "true", "s_9: stopConversation")
	lu.assertEquals(byId.s_9.options, {}, "s_9: options")
	lu.assertEquals(byId.wrong_faction.animation, "rub_chin_thoughtful", "wrong_faction: animation")
	lu.assertEquals(#byId.wrong_faction.options, 2, "wrong_faction: number of options")
	lu.assertEquals(#byId.duty_info.options, 1, "duty_info: number of options")
	lu.assertEquals(byId.duty_info.options[1][2], "s_1993702c", "duty_info: link of option 1")
end

-- AC-3 (Appendix D): the leftDialog multiplicities
function TestF6aImlerTemplateLines:test_the_left_dialog_multiplicities_are_exactly_those_of_appendix_d()
	local owners = {}
	local _, template = screens()

	for _, s in ipairs(template.screens) do
		owners[s.leftDialog] = owners[s.leftDialog] or {}
		table.insert(owners[s.leftDialog], s.id)
	end

	local repeated = {}

	for dialog, list in pairs(owners) do
		if #list > 1 then
			repeated[dialog:match(":(s_[%w_]+)$")] = #list
		end
	end

	lu.assertEquals(repeated, DS.LEFT_COUNTS, "leftDialog ids shown on more than one screen, with their screen counts")
	lu.assertEquals(#owners[P .. "s_aa1834ec"], 2, "screens showing s_aa1834ec")
	table.sort(owners[P .. "s_aa1834ec"])
	lu.assertEquals(owners[P .. "s_aa1834ec"], { "not_pilot", "wrong_faction" }, "screens showing s_aa1834ec")
	table.sort(owners[P .. "s_35a5b893"])
	lu.assertEquals(owners[P .. "s_35a5b893"], { "s_35a5b893", "s_9" }, "screens showing s_35a5b893")
end

-- AC-3: a rebel or imperial pilot gets the wrong-faction line, and either reply ends on "Won't find any here. See ya."
for _, faction in ipairs({ "rebel", "imperial" }) do
	for idx = 0, 1 do
		TestF6aImlerTemplateLines["test_a_" .. faction .. "_pilot_choosing_reply_" .. (idx + 1) .. "_of_the_wrong_faction_gate_ends_on_wont_find_any_here"] = function()
			local transcript = converse(H.newPlayer({ pilot = faction }), { idx })
			local label = faction .. " reply " .. (idx + 1)

			lu.assertEquals(transcript[1].id, "wrong_faction", label .. ": first screen")
			lu.assertEquals(transcript[1].text, P .. "s_aa1834ec", label .. ": the gate line")
			lu.assertEquals(#transcript[1].options, 2, label .. ": replies")
			lu.assertEquals(#transcript, 2, label .. ": screens; got " .. table.concat(ids(transcript), ","))
			lu.assertEquals(transcript[2].text, P .. "s_35a5b893", label .. ": the answer")
			lu.assertTrue(transcript[2].stop, label .. ": the answer ends the conversation")
			noUnresolved(transcript, label)
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: the training template and table
---------------------------------------------------------------------------------------------

TestF6aImlerTrainingTemplate = {}

function TestF6aImlerTrainingTemplate:setUp() H.reset() end

-- AC-4: the 8 screens are gone (one test each, so a leftover names itself)
for _, row in ipairs(DS.DELETED) do
	TestF6aImlerTrainingTemplate["test_screen_" .. row.id .. "_is_deleted"] = function()
		lu.assertNil(screens()[row.id], "screen '" .. row.id .. "' must be deleted")
	end
end

-- AC-4: 174 screens, no dead link or duplicate id
-- space-convo-client-strings-imler-b (Appendix C): 138 screens (174 - 98 + 62). Renamed from test_the_template_has_174_screens_and_no_dead_links_or_duplicate_ids.
function TestF6aImlerTrainingTemplate:test_the_template_has_138_screens_and_no_dead_links_or_duplicate_ids()
	local _, t = screens()

	lu.assertEquals(#t.screens, FB.SCREEN_COUNT, "imler_convo_template: number of screens (182 - 8 - 98 + 62)")
	lu.assertEquals(H.conversationProblems(TEMPLATE), {})
end

-- AC-4: ready_train is unchanged
function TestF6aImlerTrainingTemplate:test_ready_train_is_unchanged_s_d91c04b2_with_check_wrist_device_and_no_static_option()
	local screen = screens().ready_train

	lu.assertNotNil(screen, "screen ready_train")
	lu.assertEquals(screen.leftDialog, P .. DS.BRIEF.ready_train.sid, "ready_train: leftDialog")
	lu.assertEquals(screen.animation, "check_wrist_device", "ready_train: animation")
	lu.assertEquals(screen.options, {}, "ready_train: static options")
	lu.assertNotEquals(screen.stopConversation, "true", "ready_train: does not end the conversation")
end

-- AC-4 (Content contract 1): the four briefs keep their lines and their option lists (the options are the I4 ones, F6b's)
function TestF6aImlerTrainingTemplate:test_the_four_mission_briefs_keep_their_lines_and_the_option_lists_of_the_swg_brief()
	local byId = screens()

	for k = 1, 4 do
		local id = "mission" .. k .. "_brief"
		local screen = byId[id]

		lu.assertNotNil(screen, "screen " .. id)
		lu.assertEquals(screen.leftDialog, P .. DS.BRIEF[id].sid, id .. ": leftDialog (" .. DS.BRIEF[id].text .. ")")
		lu.assertEquals(#screen.options, #GRAPH.nodes[DS.BRIEF[id].sid].options, id .. ": number of options")
	end
end

-- AC-4: TRAIN_CHOICES deep-equals Content contract 2, in order
function TestF6aImlerTrainingTemplate:test_train_choices_equals_content_contract_2_in_order()
	local got = {}

	for i, entry in ipairs(handler().TRAIN_CHOICES) do
		got[i] = { entry[1], entry[2], entry[3] }
		lu.assertNil(entry[4], "TRAIN_CHOICES[" .. i .. "]: no fourth field")
	end

	lu.assertEquals(got, DS.TRAIN_CHOICES, "imlerConvoHandler.TRAIN_CHOICES")
end

-- AC-4: each reply is a complete literal that resolves in the fixture; each link is a template screen
function TestF6aImlerTrainingTemplate:test_each_choice_reply_resolves_in_the_client_file_and_each_link_is_a_template_screen()
	local byId = screens()
	local client = assert(CS.sids(FILE))

	for i, entry in ipairs(handler().TRAIN_CHOICES) do
		lu.assertNotNil(byId[entry[3]], "TRAIN_CHOICES[" .. i .. "]: screen '" .. tostring(entry[3]) .. "' is in imler_convo_template")
		lu.assertEquals(entry[2]:sub(1, #P), P, "TRAIN_CHOICES[" .. i .. "]: complete string id " .. tostring(entry[2]))
		lu.assertTrue(client[entry[2]:sub(#P + 1)] == true, "TRAIN_CHOICES[" .. i .. "]: " .. tostring(entry[2]) .. " is not in the client file")
	end
end

-- AC-4: TRAIN_SCREENS is gone from the handler, its text and the template (no purchase screen is left to buy on)
function TestF6aImlerTrainingTemplate:test_train_screens_is_gone()
	lu.assertNil(handler().TRAIN_SCREENS, "imlerConvoHandler.TRAIN_SCREENS")
	lu.assertNil(readFile(IH):find("TRAIN_SCREENS", 1, true), "imlerConvoHandler.lua still names TRAIN_SCREENS")

	for _, row in ipairs(DS.DELETED) do
		lu.assertNil(readFile(IH):find('"' .. row.id .. '"', 1, true), "imlerConvoHandler.lua still names the deleted screen " .. row.id)
		lu.assertNil(readFile(IC):find('"' .. row.id .. '"', 1, true), "imler_convo.lua still names the deleted screen " .. row.id)
	end
end

-- AC-4 (D-8): the four TRAIN_CHOICES rows carry their reply text as a trailing comment
function TestF6aImlerTrainingTemplate:test_the_train_choices_rows_carry_their_client_text_as_trailing_comments()
	local checked = 0

	for _, line in ipairs(linesOf(readFile(IH))) do
		local sid = line:match('^\t{ "pilot_neutral_%a+_04", "' .. P:gsub("%p", "%%%0") .. '(s_[%w_]+)"')

		if sid then
			lu.assertEquals(line:match("%-%-%s*(.-)%s*$"), DS.TEXT[sid], "trailing client-text comment of " .. sid)
			checked = checked + 1
		end
	end

	lu.assertEquals(checked, 4, "TRAIN_CHOICES rows checked")
end

---------------------------------------------------------------------------------------------
-- AC-5: one-click training, the 32-row table (every skill, every held subset lacking it)
---------------------------------------------------------------------------------------------

TestF6aImlerTraining = {}

function TestF6aImlerTraining:setUp() H.reset() end
function TestF6aImlerTraining:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

for _, row in ipairs(DS.TRAINING) do
	for mask = 0, 7 do
		local held = {}
		local bit = 0

		for _, other in ipairs(DS.TRAINING) do
			if other.x ~= row.x then
				if mask & (1 << bit) ~= 0 then held[#held + 1] = other.skill end

				bit = bit + 1
			end
		end

		local label = C.label(held)
		local k = #held + 1

		-- AC-5: one click on the reply buys the skill once (XP-deducting), shows the brief of the new skill count, sets the ready flag and raises the tier on the 4th skill
		TestF6aImlerTraining["test_choosing_" .. row.x .. "_holding_" .. sanitize(label) .. "_buys_it_once_and_lands_on_mission" .. k .. "_brief_with_the_ready_flag_set"] = function()
			costs()

			local player = trainee(held)
			local brief = "mission" .. k .. "_brief"
			local transcript = converse(player, { row.sid })
			local what = row.x .. " holding " .. label

			lu.assertEquals(ids(transcript), { "ready_train", brief }, what .. ": screens (k = skills held after the grant)")
			lu.assertEquals(transcript[2].text, P .. DS.BRIEF[brief].sid, what .. ": the brief line (" .. DS.BRIEF[brief].text .. ")")

			local paid = H.Engine.callsTo("skillManagerAwardSkill")

			lu.assertEquals(#paid, 1, what .. ": skillManagerAwardSkill calls")
			lu.assertTrue(paid[1][1] == player, what .. ": skillManagerAwardSkill player")
			lu.assertEquals(paid[1][2], row.skill, what .. ": skill granted")
			lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, what .. ": awardSkill (free grant) calls")
			lu.assertEquals(exp(player), COST, what .. ": space_combat_general after one purchase")
			lu.assertTrue(CreatureObject(player):hasSkill(row.skill), what .. ": " .. row.skill .. " held")
			lu.assertEquals(H.getQuestStatus(player, D.READY_SUFFIX), "1", what .. ": readyForTier4Mission set on the brief")
			lu.assertEquals(player.ghost:getPilotTier(), k == 4 and 5 or 4, what .. ": pilot tier")
			lu.assertEquals(converse(player)[1].id, "ready_mission", what .. ": the next talk starts on ready_mission")
		end
	end
end

-- AC-5: ready_train shows Imler's line and "Teach me about ..." replies, in SWG order, with no raw id; nothing is granted on display
function TestF6aImlerTraining:test_ready_train_offers_the_four_teach_me_about_replies_in_swg_order_and_grants_nothing()
	costs()

	local player = trainee({})
	local transcript = converse(player)

	lu.assertEquals(transcript[1].id, "ready_train", "first screen")
	lu.assertEquals(transcript[1].text, P .. "s_d91c04b2", "Imler's line: " .. DS.BRIEF.ready_train.text)

	local got = {}

	for i, o in ipairs(transcript[1].options) do got[i] = o.text end

	lu.assertEquals(got, {
		P .. "s_ada4db16", -- Teach me about exotic vessels.
		P .. "s_25506b23", -- Teach me about heavy starship component use.
		P .. "s_fd7e4ac8", -- Teach me about expert techniques.
		P .. "s_1813de4d", -- Teach me about droid intelligence theory.
	}, "ready_train replies")

	for _, o in ipairs(transcript[1].options) do lu.assertEquals(o.link, "mission1_brief", "static link of " .. o.text) end

	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "grants while ready_train is shown")
	lu.assertEquals(exp(player), 2 * COST, "XP while ready_train is shown")
	lu.assertNil(H.getQuestStatus(player, D.READY_SUFFIX), "ready flag while ready_train is shown")
	noUnresolved(transcript, "ready_train")
end

-- AC-5 (D-4): the choice is told by its reply, not by the link: the same link "mission1_brief" lands on mission4_brief for the fourth skill
function TestF6aImlerTraining:test_the_landing_follows_the_skill_count_and_never_the_static_link()
	costs()

	local player = trainee({ "pilot_neutral_starships_04", "pilot_neutral_weapons_04", "pilot_neutral_procedures_04" })
	local transcript = converse(player, { "s_1813de4d" })

	lu.assertEquals(transcript[1].options[1].link, "mission1_brief", "the static link of the only reply")
	lu.assertEquals(transcript[#transcript].id, "mission4_brief", "the screen after the fourth skill")
end

-- AC-5: the guards. The skill arrives, or the XP goes, while ready_train is shown: nothing is granted, and the brief follows the unchanged count
for _, row in ipairs(DS.TRAINING) do
	TestF6aImlerTraining["test_choosing_" .. row.x .. "_when_the_skill_arrived_meanwhile_grants_nothing_and_the_brief_follows_the_count"] = function()
		costs()

		local player = trainee({})
		local transcript = converse(player, { function(p) p.skills[row.skill] = true end, row.sid })

		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, row.x .. ": skillManagerAwardSkill calls")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, row.x .. ": awardSkill calls")
		lu.assertEquals(transcript[#transcript].id, "mission1_brief", row.x .. ": the screen with one skill held")
		lu.assertEquals(exp(player), 2 * COST, row.x .. ": XP")
	end

	TestF6aImlerTraining["test_choosing_" .. row.x .. "_when_the_xp_is_gone_meanwhile_grants_nothing_and_the_brief_follows_the_unchanged_count"] = function()
		costs()

		local player = trainee({}, COST)
		local transcript = converse(player, { function(p) p.ghost.experience.space_combat_general = COST - 1 end, row.sid })

		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, row.x .. ": skillManagerAwardSkill calls")
		lu.assertFalse(CreatureObject(player):hasSkill(row.skill), row.x .. ": skill held")
		lu.assertEquals(transcript[#transcript].id, "mission1_brief", row.x .. ": the screen with no skill held")
	end
end

-- AC-5: the guard leaves the ready flag on the brief all the same (as the old trained_mission<k>)
function TestF6aImlerTraining:test_a_refused_grant_still_lands_on_the_brief_which_sets_the_ready_flag()
	costs()

	local player = trainee({}, COST)

	converse(player, { function(p) p.ghost.experience.space_combat_general = COST - 1 end, "s_ada4db16" })
	lu.assertEquals(H.getQuestStatus(player, D.READY_SUFFIX), "1", "ready flag after a refused grant that landed on mission1_brief")
end

-- AC-5: a droid-first career: one skill per visit, the last offered reply each time, missions won and paid between visits
function TestF6aImlerTraining:test_picking_the_last_offered_reply_every_visit_trains_droid_procedures_weapons_starships_and_lands_on_the_briefs_1_to_4()
	costs()

	local player = trainee({}, 4 * COST)
	local order = { 4, 3, 2, 1 }

	for visit, idx in ipairs(order) do
		local pick = DS.TRAINING[idx]
		local greeting = converse(player)

		lu.assertEquals(greeting[1].id, "ready_train", "visit " .. visit .. ": first screen")
		lu.assertEquals(greeting[1].options[#greeting[1].options].text, pick.reply, "visit " .. visit .. ": the last reply offered")
		lu.assertEquals(#greeting[1].options, 5 - visit, "visit " .. visit .. ": replies offered")

		local before = #H.Engine.callsTo("skillManagerAwardSkill")
		local transcript = converse(player, { pick.sid })

		lu.assertEquals(ids(transcript), { "ready_train", "mission" .. visit .. "_brief" }, "visit " .. visit .. ": screens")
		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill") - before, 1, "visit " .. visit .. ": skills bought")
		lu.assertEquals(H.Engine.callsTo("skillManagerAwardSkill")[before + 1][2], pick.skill, "visit " .. visit .. ": skill bought")
		lu.assertEquals(exp(player), (4 - visit) * COST, "visit " .. visit .. ": space_combat_general")
		lu.assertEquals(converse(player)[1].id, "ready_mission", "visit " .. visit .. ": the next talk starts on ready_mission")

		-- the mission is won and paid before the next visit
		removeQuestStatus(player.objectID .. D.READY_SUFFIX)
		H.setQuestStatus(player, D.MISSION[visit].statusName .. ":attempted", 1)
		H.setQuestStatus(player, D.MISSION[visit].statusName .. ":reward", 1)

		local key = D.MISSION[visit].wins[1]

		player.ghost.journalComplete[H.questCrc(D.QUEST[key][1], D.QUEST[key][2])] = true
	end

	lu.assertEquals(player.ghost:getPilotTier(), 5, "pilot tier after the fourth skill")
	lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "total awardSkill calls")
end

---------------------------------------------------------------------------------------------
-- AC-6: journeys through the changed chains (twin texts along the SWG path) and transcript scans
---------------------------------------------------------------------------------------------

TestF6aImlerJourneys = {}

function TestF6aImlerJourneys:setUp() H.reset() end

-- name, builder, first choices (before the I4 path), I4 from screen, to screen
local DUTY_CHAINS = {
	{ "intro_through_the_duty_briefing_to_the_duty_menu", function() return D.rsf({}) end, { "s_52917b0d" } },
	{ "tier4_incomplete_through_the_duty_briefing_again_to_the_duty_menu", function() return D.rsf({ met = true }) end, { "s_70d61202" } },
}

for _, j in ipairs(DUTY_CHAINS) do
	local name, build, first = j[1], j[2], j[3]

	-- AC-6: along the SWG path every NPC line and every reply shown is the twin of the SWG one, nothing starts or pays, and nothing is unresolved
	TestF6aImlerJourneys["test_journey_" .. name .. "_shows_the_twins_of_the_swg_lines_and_resolves_in_the_client"] = function()
		local rec = spyAllQuests()
		local player = build()
		local path = i4Path("duty_info", "duty_info_end")
		local lines = i4Lines("duty_info", path)
		local choices = copy(first)

		for _, opt in ipairs(path) do choices[#choices + 1] = twin(opt) end

		local transcript = converse(player, choices)
		local at = #first + 1 -- the index of the duty_info step

		lu.assertEquals(transcript[at].id, "duty_info", name .. ": the briefing screen")
		lu.assertEquals(transcript[#transcript].id, "duty_info_end", name .. ": the last screen; got " .. table.concat(ids(transcript), ","))

		for i, sid in ipairs(lines) do
			lu.assertEquals(transcript[at + i - 1].text, P .. twin(sid), name .. ": NPC line " .. i .. " (SWG " .. sid .. ")")

			if path[i] then
				local shown = {}

				for k, o in ipairs(transcript[at + i - 1].options) do shown[k] = o.text end

				lu.assertNotNil(table.concat(shown, "|"):find(P .. twin(path[i]), 1, true), name .. ": step " .. i .. " offers the twin of reply " .. path[i])
			end
		end

		lu.assertEquals(transcript[at].options[1].text, P .. "s_3f68df7d", name .. ": the first reply of the briefing (Sounds easy enough.)")
		lu.assertEquals(#transcript[#transcript].options, 5, name .. ": duty menu options")
		lu.assertEquals(rec.starts, {}, name .. ": quests started while only reading")
		lu.assertEquals(rec.rewards, {}, name .. ": rewards paid")
		noUnresolved(transcript, name)
	end
end

-- AC-6: the intro still sets the met flag only through the intro
function TestF6aImlerJourneys:test_the_met_flag_is_set_only_through_the_intro_and_the_briefing_again_sets_nothing()
	local player = D.rsf({})
	local transcript = converse(player, { "s_52917b0d" })

	lu.assertEquals(ids(transcript), { "intro", "duty_info" })
	lu.assertEquals(H.getQuestStatus(player, D.MET_SUFFIX), "1", "StartedImler after duty_info")

	local again = D.rsf({ met = true })

	converse(again, { "s_70d61202", "s_3f68df7d" })
	lu.assertEquals(H.getQuestStatus(again, D.MET_SUFFIX), "1", "StartedImler of a pilot who had met Imler")
	noUnresolved(transcript, "intro")
end

-- AC-6: the off-track chain not_my_track -> nontrack_duty -> duty_info -> ... -> duty_info_end starts nothing, sets no met flag and resolves
function TestF6aImlerJourneys:test_the_off_track_chain_to_the_duty_menu_starts_nothing_and_resolves_in_the_client()
	local rec = spyAllQuests()
	local player = D.corsec({})
	local choices = { "s_c1ff5062", "s_c82e9a2f" }

	for _, opt in ipairs(i4Path("duty_info", "duty_info_end")) do choices[#choices + 1] = twin(opt) end

	local transcript = converse(player, choices)

	lu.assertEquals(ids(transcript)[1], "not_my_track", "first screen")
	lu.assertEquals(ids(transcript)[2], "nontrack_duty", "second screen")
	lu.assertEquals(ids(transcript)[3], "duty_info", "third screen")
	lu.assertEquals(transcript[#transcript].id, "duty_info_end", "the chain ends on the duty menu")
	lu.assertEquals(#transcript[#transcript].options, 5, "duty menu options")
	lu.assertEquals(rec.starts, {}, "quests started while only reading")
	lu.assertNil(H.getQuestStatus(player, D.MET_SUFFIX), "StartedImler after the off-track chain")
	noUnresolved(transcript, "off-track chain")
end

-- AC-6: the off-track gate is unchanged: a datapad quest refuses it, an empty datapad offers it
function TestF6aImlerJourneys:test_the_off_track_duty_gate_still_asks_for_an_empty_space_quest_datapad()
	local handlerTable = handler()
	local free = D.corsec({})

	lu.assertTrue(handlerTable:canFlyNonTrackDuty(free), "canFlyNonTrackDuty with an empty datapad")
	lu.assertEquals(ids(converse(free, { "s_c1ff5062" })), { "not_my_track", "nontrack_duty" }, "off-track tier 3 graduate")

	H.reset()

	local busy = D.corsec({ active = { "m3b" } })

	lu.assertFalse(handlerTable:canFlyNonTrackDuty(busy), "canFlyNonTrackDuty with a story quest active")
	lu.assertEquals(ids(converse(busy, { "s_c1ff5062" })), { "not_my_track", "nontrack_no_duty" }, "off-track pilot on a quest")
end

-- AC-6, I-2: the gate, reward and failure screens resolve in the client
function TestF6aImlerJourneys:test_gate_transcripts_resolve_in_the_client()
	for _, gate in ipairs({
		{ "not_pilot", function() return H.newPlayer({}) end },
		{ "wrong_faction", function() return H.newPlayer({ pilot = "rebel" }) end },
		{ "not_my_track", function() return D.corsec({}) end },
		{ "not_ready", function() return D.rsf({ noTier3 = true, pilotTier = 3 }) end },
		{ "on_mission", function() return D.rsf({ tier4 = { "starships" }, active = { "m1" } }) end },
		{ "no_master", function() return D.rsf({ tier4 = D.SKILLS, rewards = { 1, 2, 3, 4 }, attempted = { 1, 2, 3, 4 }, completed = { "m1b", "m2d", "m3c", "m4cw" }, met = true }) end },
	}) do
		H.reset()
		spyAllQuests()

		local transcript = converse(gate[2]())

		lu.assertEquals(transcript[1].id, gate[1], gate[1] .. ": first screen")
		noUnresolved(transcript, gate[1])
	end
end

-- AC-5, AC-6, I-2: training, then each brief: the transcript up to the brief's own line resolves, and the first mission path of each brief starts its mission once
for k = 1, 4 do
	local grant = "mission" .. k .. "_accept_a"

	TestF6aImlerJourneys["test_training_the_skill_number_" .. k .. "_then_the_first_path_of_mission_" .. k .. "_reaches_" .. grant .. "_and_starts_the_mission_once"] = function()
		costs()

		local rec = spyAllQuests()
		local held = {}

		for i = 1, k - 1 do held[i] = DS.TRAINING[i].skill end

		local player = trainee(held)
		local pick = DS.TRAINING[k]
		-- space-convo-client-strings-imler-b (E-IM2, Appendix C): the path inside the subtree is Appendix P's, not I4's
		local path = FB.PATHS[grant]
		local choices = { pick.sid }

		for _, opt in ipairs(path) do choices[#choices + 1] = opt end

		local transcript = converse(player, choices)

		lu.assertEquals(transcript[1].id, "ready_train", "first screen")
		lu.assertEquals(transcript[2].id, "mission" .. k .. "_brief", "screen after the click")
		lu.assertEquals(transcript[#transcript].id, grant, "last screen; got " .. table.concat(ids(transcript), ","))
		lu.assertEquals(#rec.starts, 1, "quests started")
		lu.assertEquals(rec.rewards, {}, "rewards paid")
		lu.assertNil(H.getQuestStatus(player, D.READY_SUFFIX), "ready flag after the mission started")
		lu.assertEquals(H.getQuestStatus(player, D.MISSION[k].statusName .. ":attempted"), "1", ":attempted status")

		local upToBrief = {}

		for i = 1, 2 do upToBrief[i] = transcript[i] end

		noUnresolvedUpToBrief(upToBrief, "training " .. k)
	end
end

-- AC-6: ready_mission still leads to the same briefs, and the brief writes the same flag
function TestF6aImlerJourneys:test_ready_mission_leads_to_the_brief_of_the_skill_count_and_keeps_the_ready_flag()
	for k = 1, 4 do
		H.reset()

		local held = {}

		for i = 1, k do held[i] = DS.TRAINING[i].x end

		local hist, completed = {}, {}

		for i = 1, k - 1 do
			hist[i] = i
			completed[i] = D.MISSION[i].wins[1]
		end

		local player = D.rsf({ tier4 = held, rewards = hist, attempted = hist, completed = completed, ready = true, met = true })
		local transcript = converse(player, { "s_39e697de" })

		lu.assertEquals(ids(transcript), { "ready_mission", "mission" .. k .. "_brief" }, "skills held " .. k)
		lu.assertEquals(H.getQuestStatus(player, D.READY_SUFFIX), "1", "ready flag after the brief of " .. k .. " skills")
		noUnresolvedUpToBrief(transcript, "ready_mission " .. k)
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: nothing else moves, LF
---------------------------------------------------------------------------------------------

TestF6aImlerNothingElseMoves = {}

function TestF6aImlerNothingElseMoves:setUp() H.reset() end

-- AC-7: IC is the base minus lines 396-460, with exactly the 3 Appendix A lines changed (the NGE id on the twin and ` -- <client text>` appended).
-- space-convo-client-strings-imler-b (Appendix C): this base stays 57664ade04, and the F6b ranges (the 9 brief option lines and the subtree block, 8c4e07808b lines 296-297, 304-306,
-- 313-314, 321-322 and 325-1072, which become 446 lines) are excepted here; test_space_convo_client_strings_imler_b.lua AC-7 pins them against 8c4e07808b.
function TestF6aImlerNothingElseMoves:test_imler_convo_equals_the_base_without_lines_396_to_460_and_with_the_3_swaps()
	local now, old = linesOf(readFile(IC)), linesOf(baseFile(IC))
	local bySite = {}

	for _, site in ipairs(DS.SITES) do bySite[site.line] = site end

	local want = {}

	for i = 1, #old do
		if i < DS.DELETED_FROM or i > DS.DELETED_TO then
			local site = bySite[i]
			local line = old[i]

			if site then
				local from, to = line:find(P .. site.nge .. '"', 1, true)

				lu.assertNotNil(from, "base line " .. i .. " names " .. site.nge)
				line = line:sub(1, from - 1) .. P .. site.twin .. '"' .. line:sub(to + 1) .. " -- " .. DS.TEXT[site.twin]
			end

			want[#want + 1] = line
		end
	end

	lu.assertEquals(#old, DS.AC_BASE_LINES, "number of lines of imler_convo.lua at the base " .. BASE)
	lu.assertEquals(#want, DS.AC_LINES, "number of lines of the expected imler_convo.lua (the state of 8c4e07808b)")
	lu.assertEquals(#now, FB.AC_LINES, "number of lines of imler_convo.lua (the state of 8c4e07808b with the F6b ranges replaced)")

	-- drop the F6b ranges from both sides: lines 1-324 keep their numbers, the block 325-1072 of `want` is the 446 lines 325-770 of `now`
	local function outside(list, blockTo)
		local out, brief = {}, {}

		for _, n in ipairs(FB.REPLACED.briefLines) do brief[n] = true end

		for i, line in ipairs(list) do
			if not brief[i] and not (i >= FB.REPLACED.blockFrom and i <= blockTo) then out[#out + 1] = line end
		end

		return out
	end

	local nowRest = outside(now, FB.REPLACED.blockFrom + 446 - 1)
	local wantRest = outside(want, FB.REPLACED.blockTo)

	lu.assertEquals(#nowRest, #wantRest, "lines outside the F6b ranges")

	for i = 1, math.max(#nowRest, #wantRest) do
		lu.assertEquals(nowRest[i], wantRest[i], "imler_convo.lua line " .. i .. " outside the F6b ranges (base " .. BASE .. " minus the 8 screens plus the 3 swaps)")
	end
end

-- AC-7: the deleted block is exactly the eight addScreen blocks at base lines 396-460, in order
function TestF6aImlerNothingElseMoves:test_the_deleted_lines_are_exactly_the_eight_training_screens_of_the_base()
	local old = linesOf(baseFile(IC))

	for _, row in ipairs(DS.DELETED) do
		lu.assertEquals(old[row.from], "imler_convo_template:addScreen(ConvoScreen:new {", row.id .. ": base line " .. row.from)
		lu.assertEquals(old[row.from + 1], '\tid = "' .. row.id .. '",', row.id .. ": base line " .. (row.from + 1))
		lu.assertEquals(old[row.to], "})", row.id .. ": base line " .. row.to)
	end

	lu.assertEquals(old[DS.DELETED_TO + 1], "imler_convo_template:addScreen(ConvoScreen:new {", "the block after the deleted lines")
	lu.assertEquals(old[DS.DELETED_FROM - 1], "})", "the line before the deleted lines")
end

-- AC-7: IH differs from the base only in the four hunks of Content contract 2, whose new text is Appendix E
function TestF6aImlerNothingElseMoves:test_the_handler_differs_from_the_base_only_in_the_four_hunks_of_content_contract_2()
	local now, old = linesOf(readFile(IH)), linesOf(baseFile(IH))
	local want = {}
	local hunkAt = {}

	for _, h in ipairs(DS.HUNKS) do hunkAt[h.from] = h end

	local i = 1

	while i <= #old do
		local h = hunkAt[i]

		if h then
			for _, line in ipairs(h.lines) do want[#want + 1] = line end

			i = h.to + 1
		else
			want[#want + 1] = old[i]
			i = i + 1
		end
	end

	lu.assertEquals(#old, DS.AH_BASE_LINES, "number of lines of imlerConvoHandler.lua at the base")
	lu.assertEquals(#want, DS.AH_LINES, "number of lines of the expected imlerConvoHandler.lua")
	lu.assertEquals(#now, DS.AH_LINES, "number of lines of imlerConvoHandler.lua")

	for n = 1, math.max(#now, #want) do
		lu.assertEquals(now[n], want[n], "imlerConvoHandler.lua line " .. n .. " (base " .. BASE .. " plus Content contract 2)")
	end
end

-- AC-7: canFlyNonTrackDuty (and its hasSpaceQuest term) is byte-identical to the base
function TestF6aImlerNothingElseMoves:test_can_fly_non_track_duty_is_byte_identical_to_the_base()
	local function block(text)
		local from = text:find("function imlerConvoHandler:canFlyNonTrackDuty(pPlayer)", 1, true)

		lu.assertNotNil(from, "canFlyNonTrackDuty is defined")

		local to = select(2, text:find("\nend\n", from, true))

		return text:sub(from, to)
	end

	local now, old = block(readFile(IH)), block(baseFile(IH))

	lu.assertEquals(now, old, "canFlyNonTrackDuty")
	lu.assertNotNil(now:find("not SpaceHelpers:hasSpaceQuest(pPlayer)", 1, true), "canFlyNonTrackDuty keeps the hasSpaceQuest term")
end

-- AC-7: both files are LF on every line, including the last, as at the base
function TestF6aImlerNothingElseMoves:test_both_files_are_lf_on_every_line_including_the_last()
	for _, rel in ipairs(SOURCES) do
		local text = readFile(rel)

		lu.assertNil(text:find("\r", 1, true), rel .. ": contains a CR byte")
		lu.assertEquals(text:sub(-1), "\n", rel .. ": the final line keeps its LF")
		lu.assertEquals(baseFile(rel):sub(-1), "\n", rel .. ": the base ends with LF too")
	end
end

-- AC-7: the template name, handler, initial screen and type are unchanged
function TestF6aImlerNothingElseMoves:test_the_template_keeps_its_name_handler_initial_screen_and_type()
	local _, t = screens()

	lu.assertEquals(t.luaClassHandler, "imlerConvoHandler", "luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.initialScreen, "", "initialScreen")
	lu.assertNotNil(readFile(IC):find('addConversationTemplate("imler_convo_template", imler_convo_template)', 1, true), "the addConversationTemplate line")
end

---------------------------------------------------------------------------------------------
-- AC-8: SWG conformance through the twin table
---------------------------------------------------------------------------------------------

TestF6aImlerConformance = {}

function TestF6aImlerConformance:setUp() H.reset() end

local REVERSE = {}

for id, sid in pairs(D.SCREENS) do REVERSE[sid] = id end

local TRAINING_NPC = {}

for _, id in ipairs({ "s_439", "s_440", "s_441", "s_442", "s_451", "s_489", "s_623", "s_737" }) do TRAINING_NPC[id] = true end

-- AC-8 (I-3): every I4 NPC line Core3 shows is on the screen of that id with the twin as its line, I4's stop flag and animation (the training dialogue is E-IM1)
-- space-convo-client-strings-imler-b (E-IM2, Appendix C): the 98 NPC lines of the subtrees are Appendix G's now, so 76 I4 lines are checked
function TestF6aImlerConformance:test_every_shown_i4_npc_line_is_on_its_screen_as_its_twin_with_the_i4_stop_and_animation()
	local byId = screens()
	local seen = 0

	for _, sid in ipairs(GRAPH.order) do
		if not TRAINING_NPC[sid] and not SUBTREE[sid] then
			local id = REVERSE[sid] or sid
			local screen = byId[id]

			lu.assertNotNil(screen, "I4 line " .. sid .. ": screen '" .. id .. "'")
			seen = seen + 1
			lu.assertEquals(screen.leftDialog, P .. twin(sid), "screen '" .. id .. "' (" .. sid .. "): leftDialog")
			lu.assertEquals(screen.stopConversation == "true", GRAPH.nodes[sid].isEnd, "screen '" .. id .. "' (" .. sid .. "): stopConversation")
			lu.assertEquals(screen.animation or "", GRAPH.nodes[sid].animation, "screen '" .. id .. "' (" .. sid .. "): animation")
		end
	end

	lu.assertEquals(seen, 76, "I4 NPC lines checked (182 - the 8 of the training dialogue - the 98 of the subtrees)")
end

-- AC-8: every screen's options are the twins of the I4 replies, with the same links (ready_train's reply s_438 is E-IM1)
-- space-convo-client-strings-imler-b (E-IM2, Appendix C): the 98 subtree lines are Appendix G's; the briefs keep their lines but their options are Appendix G's (only the count is compared)
function TestF6aImlerConformance:test_every_shown_i4_npc_line_has_the_twins_of_its_replies_in_order_with_the_i4_successor_as_link()
	local byId, t = screens()
	local shown = 0

	for _, sid in ipairs(GRAPH.order) do
		if not TRAINING_NPC[sid] and not SUBTREE[sid] then
			local id = REVERSE[sid] or sid
			local screen = byId[id]
			local node = GRAPH.nodes[sid]
			local wanted = {}
			local got = {}

			for i, option in ipairs(screen.options or {}) do got[i] = option[1]:match("^@conversation/naboo_privateer_tier4:(s_[%w_]+)$") end

			if BRIEF_SCREENS[id] then
				lu.assertEquals(#got, #node.options, "screen '" .. id .. "': number of options (E-IM2: the options are Appendix G's)")
			else
				if id ~= "ready_train" then
					for _, optionSid in ipairs(node.options) do wanted[#wanted + 1] = twin(optionSid) end
				end

				lu.assertEquals(got, wanted, "screen '" .. id .. "' (" .. sid .. "): option sids in order (twins of the I4 replies)")

				if id ~= "ready_train" then
					for i, optionSid in ipairs(node.options) do
						local successors = GRAPH.successorsOf(sid, optionSid)

						lu.assertNotNil(successors, "answer key: no successor for " .. sid .. " -> " .. optionSid)

						-- Conditional successors: the static link is the unconditional default, the last successor in the java
						local target = byId[screen.options[i][2]]

						lu.assertNotNil(target, "screen '" .. id .. "' option " .. optionSid .. ": link '" .. tostring(screen.options[i][2]) .. "' is a screen")
						lu.assertEquals(target.leftDialog, P .. twin(successors[#successors]), "screen '" .. id .. "' option " .. optionSid .. " -> successor NPC line")
					end
				end
			end

			shown = shown + 1
		end
	end

	lu.assertEquals(shown, 76, "screens compared")
	lu.assertEquals(#t.screens, FB.SCREEN_COUNT, "screens in the template")
end

-- AC-8: usage is 74 of 182 NPC lines and 54 of 158 replies; the unused sids are exactly the twin keys plus s_438-s_449, s_451, s_489, s_623, s_737 and the 196 of the subtrees
-- (space-convo-client-strings-imler-b, Appendix C). Renamed from test_the_files_use_172_of_182_npc_lines_and_152_of_158_replies_and_the_unused_are_the_twin_keys_plus_the_training_ids.
function TestF6aImlerConformance:test_the_files_use_74_of_182_npc_lines_and_54_of_158_replies_and_the_unused_are_the_twin_keys_the_training_ids_and_the_196_subtree_ids()
	local usedNpc, usedResp = {}, {}

	for _, lit in ipairs(CS.literals(SOURCES)) do
		if lit.file == FILE then
			if GRAPH.nodes[lit.id] then usedNpc[lit.id] = true end
			if GRAPH.responses[lit.id] then usedResp[lit.id] = true end
		end
	end

	local unusedNpc, unusedResp = {}, {}

	for _, sid in ipairs(GRAPH.order) do
		if not usedNpc[sid] then unusedNpc[#unusedNpc + 1] = sid end
	end

	for sid in pairs(GRAPH.responses) do
		if not usedResp[sid] then unusedResp[#unusedResp + 1] = sid end
	end

	local wantNpc, wantResp = copy(DS.UNUSED_NPC), copy(DS.UNUSED_REPLIES)

	for _, id in ipairs(DS.REMAINING) do
		if GRAPH.nodes[id] then wantNpc[#wantNpc + 1] = id else wantResp[#wantResp + 1] = id end
	end

	table.sort(unusedNpc)
	table.sort(unusedResp)
	table.sort(wantNpc)
	table.sort(wantResp)
	lu.assertEquals(#GRAPH.order, 182, "I4 NPC lines")
	lu.assertEquals(count(GRAPH.responses), 158, "I4 replies")
	lu.assertEquals(count(usedNpc), 74, "I4 NPC lines used")
	lu.assertEquals(count(usedResp), 54, "I4 replies used")
	lu.assertEquals(#unusedNpc, 108, "unused NPC lines")
	lu.assertEquals(#unusedResp, 104, "unused replies")
	lu.assertEquals(unusedNpc, wantNpc, "unused NPC lines (s_4, s_9, the 8 training lines and the 98 of the subtrees)")
	lu.assertEquals(unusedResp, wantResp, "unused replies (s_416, s_438, the 4 buy replies and the 98 of the subtrees)")
end
