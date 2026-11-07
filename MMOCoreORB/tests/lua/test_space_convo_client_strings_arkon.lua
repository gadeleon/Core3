-- Client string ids of Arkon (Havoc tier 4), F5 of the space conversation client-string work.
-- Spec: .claude/work/space-convo-client-strings-arkon/01-spec.md (AC-1 .. AC-9; I-1 .. I-6; D-1 .. D-17; FA-1 .. FA-8; Content contract 1a .. 4; Appendix A .. E).
--
-- Arkon shows 94 NGE-numbered ids that the pre-NGE client cannot resolve. 78 of them (the missions and the duty explanation) are copies of earlier pre-NGE lines (FA-2):
-- the client's string ids are CRCs of the line text, so a copy has the id of the line it repeats. Each is rewritten in place onto that line (its twin): screens, links, stops
-- and animations do not move (D-1, D-4), and each changed line gains a trailing `-- <client text>` comment. The other 16 are the NGE training dialogue (FA-4): it is rebuilt on
-- Arkon's own pre-NGE lines as one click, the reply of the missing skill leads straight to trained_<x>, which grants on display (D-2, D-3, D-10, D-11).
--
-- The twin of every NGE id and the client text of every twin are copied from the spec (havoc_tier4_arkon_client_strings_data.lua), not read from arkon_convo.lua, so a wrong
-- twin fails here instead of agreeing with itself. The A4 answer key (havoc_tier4_data.lua, the java graph) stays the SWG graph; conformance runs through the twin table
-- (I-3, D-7) with the training block as the one exception (E-AK2).
-- The behavior tests (routing, offers, rewards, training, duties) are test_havoc_tier4_arkon_*.lua, updated to the new ids (Appendix C); AC-5/AC-6 here add what they do not
-- pin: the acknowledgment texts and the second line of starships and weapons, the transcript scans and the journeys through the swapped chains.

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local D = require("havoc_tier4_data") -- the A4 answer key (screen ids -> SWG sid), unchanged
local FC = require("havoc_tier4_arkon_free_choice_data")
local KD = require("space_convo_client_strings_data")
local DS = require("havoc_tier4_arkon_client_strings_data") -- Appendix A, B, D, E
local Swgjava = require("harness.swgjava")

H.loadSquadron("HavocSquadronScreenplay")
H.loadMobile("conversations/space/rebel/havoc_squadron/arkon_convo.lua")
H.loadScreenplay("space/conversations/rebel/havoc_squadron/arkonConvoHandler.lua")

local P = DS.PREFIX
local BASE = DS.BASE

local AC = "mobile/conversations/space/rebel/havoc_squadron/arkon_convo.lua"
local AH = "screenplays/space/conversations/rebel/havoc_squadron/arkonConvoHandler.lua"
local SOURCES = { AC, AH }
local FILE = "conversation/corellia_rebel_tier4"
local TEMPLATE = "arkon_convo"

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_rebel_tier4.java")
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

local function sidOf(text)
	return type(text) == "string" and text:match("^@conversation/corellia_rebel_tier4:(s_[%w_]+)$") or nil
end

local function twin(sid) return DS.TWIN[sid] or sid end

local function sanitize(s) return (s:gsub("[^%w]+", "_"):gsub("_+$", "")) end

local function screens()
	local byId = {}
	local t = H.conversationTemplateTable(TEMPLATE)

	lu.assertNotNil(t, TEMPLATE .. " is registered")

	for _, s in ipairs(t.screens) do
		byId[s.id] = s
	end

	return byId, t
end

local function handler() return H.expectGlobal("arkonConvoHandler", "Arkon conversation handler (arkonConvoHandler.lua)") end

local function converse(player, choices)
	return H.converse({ template = TEMPLATE, player = player, npc = H.newNpc({ name = "Warvog Arkon" }), choices = choices })
end

local function ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do out[i] = step.id end

	return out
end

local function noUnresolved(transcript, label)
	lu.assertEquals(CS.transcriptUnresolved(transcript), {}, label .. ": ids the pre-NGE client cannot resolve")
end

local function exp(player) return player.ghost.experience.space_combat_general end

-- A met Havoc pilot holding the tier 4 skills `held` (short names), missions 1..#held won, attempted and paid, with `amount` space XP: ready_train is the first screen
local function trainee(held, amount)
	local rewards, attempted, completed = {}, {}, {}

	for i = 1, #held do
		rewards[i] = i
		attempted[i] = i
		completed[#completed + 1] = D.MISSION[i].wins[1]
	end

	return D.havoc({ tier4 = held, rewards = rewards, attempted = attempted, completed = completed, xp = amount or COST, met = true })
end

-- Havoc pilot with `skills` tier 4 skills and the missions before `skills` won and paid (the state in front of mission `skills`), plus D.havoc opts
local function pilot(skills, opts)
	local args = { tier4 = {}, rewards = {}, attempted = {}, completed = {} }

	for i = 1, skills do
		args.tier4[i] = D.SKILLS[i]
	end

	for i = 1, skills - 1 do
		args.rewards[i] = i
		args.attempted[i] = i
		args.completed[#args.completed + 1] = D.MISSION[i].wins[1]
	end

	for k, v in pairs(opts or {}) do args[k] = v end

	return D.havoc(args)
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

local function costs()
	local out = {}

	for _, c in ipairs(FC.CHOICES) do out[c.skill] = COST end

	H.Engine.config.skillXpCosts = out
end

---------------------------------------------------------------------------------------------
-- sanity of the copied answer key
---------------------------------------------------------------------------------------------

TestF5ArkonAnswerKey = {}

function TestF5ArkonAnswerKey:setUp() H.reset() end

-- AC-2, AC-3 (sanity of the data copied from the spec)
function TestF5ArkonAnswerKey:test_appendix_a_has_78_distinct_lines_41_npc_lines_and_37_replies_and_appendix_b_54_twin_texts_and_12_training_texts()
	local lines, npc, resp, twins = {}, 0, 0, {}

	for _, site in ipairs(DS.SITES) do
		lu.assertNil(lines[site.line], "Appendix A: line " .. site.line .. " listed twice")
		lines[site.line] = true
		twins[site.twin] = true

		if site.field == "leftDialog" then
			npc = npc + 1
			lu.assertTrue(GRAPH.nodes[site.nge] ~= nil, "Appendix A line " .. site.line .. ": " .. site.nge .. " is an NPC line of the java")
		else
			resp = resp + 1
			lu.assertTrue(GRAPH.responses[site.nge] == true, "Appendix A line " .. site.line .. ": " .. site.nge .. " is a reply of the java")
		end

		lu.assertNotNil(DS.TEXT[site.twin], "Appendix B has no text for " .. site.twin)
	end

	lu.assertEquals(#DS.SITES, 78, "Appendix A rows")
	lu.assertEquals(npc + resp, 78, "rows")
	lu.assertEquals(count(DS.TWIN), 78, "distinct NGE ids")
	lu.assertEquals(count(DS.TEXT), 54, "Appendix B twin texts")
	lu.assertEquals(count(DS.TRAINING_TEXT), 12, "Appendix B training texts")
	lu.assertEquals(sortedKeys(twins), sortedKeys(DS.TEXT), "the twins of Appendix A are exactly the twin ids of Appendix B")
end

-- AC-4 (sanity): the training rows, the table and the block agree with each other
function TestF5ArkonAnswerKey:test_the_training_rows_the_choice_table_and_the_block_name_exactly_the_12_training_ids()
	local named = {}

	for _, row in ipairs(DS.TRAINING) do
		named[row.sid] = true

		for _, o in ipairs(row.options) do named[o[1]] = true end
	end

	for _, c in ipairs(DS.TRAIN_CHOICES) do named[c[2]:match(":(s_[%w_]+)$")] = true end

	lu.assertEquals(sortedKeys(named), sortedKeys(DS.TRAINING_TEXT), "ids of the training rows and TRAIN_CHOICES versus Appendix B")
	lu.assertEquals(#DS.BLOCK, 39, "Appendix E lines")
	lu.assertEquals(DS.AC_LINES, 1414 - (DS.BLOCK_TO - DS.BLOCK_FROM + 1) + #DS.BLOCK, "arkon_convo.lua line count after the feature")
end

---------------------------------------------------------------------------------------------
-- AC-1: no unresolved id left in Arkon's two files; the ratchet no longer lists his file; skl_n is gone
---------------------------------------------------------------------------------------------

TestF5ArkonStaticUnresolved = {}

function TestF5ArkonStaticUnresolved:setUp() H.reset() end

-- AC-1 (I-1): 94 unresolved entries before this feature
function TestF5ArkonStaticUnresolved:test_arkon_template_and_handler_show_only_client_string_ids()
	lu.assertEquals(CS.unresolved(SOURCES), {}, "Arkon: ids the pre-NGE client cannot resolve")
end

-- AC-1: his file left KNOWN_GAPS (305 -> 211); one file remains (space-convo-client-strings-imler-a then took 15 ids out of it, 211 -> 196, Appendix C)
-- space-convo-client-strings-imler-b (F6b, 01-spec.md Appendix C, AC-1): Imler's file left the ratchet too (196 -> 0), so KNOWN_GAPS is empty. Renamed from test_arkon_file_is_not_in_the_ratchet_and_only_imlers_file_is_with_196_ids.
function TestF5ArkonStaticUnresolved:test_arkon_file_is_not_in_the_ratchet_and_known_gaps_is_empty()
	lu.assertNil(KD.KNOWN_GAPS[FILE], "KNOWN_GAPS entry of Arkon's file")
	lu.assertEquals(KD.KNOWN_GAPS, {}, "KNOWN_GAPS")
	lu.assertEquals(CS.unresolvedByFile(CS.spaceConversationSources()), {}, "live scan: unresolved ids of all space conversation sources")
	lu.assertNil(CS.unresolvedByFile(SOURCES)[FILE], "unresolved ids of Arkon's file")
end

-- AC-1: the scan of every space conversation source equals the ratchet exactly
function TestF5ArkonStaticUnresolved:test_the_unresolved_ids_of_all_space_conversations_equal_known_gaps()
	lu.assertEquals(CS.unresolvedByFile(CS.spaceConversationSources()), KD.KNOWN_GAPS, "unresolvedByFile versus KNOWN_GAPS")
end

-- AC-1 (D-10): FIXTURE_COUNTS has 64 entries (storm-tier2-nym-technicians added conversation/nym_technician_1, _2 and _3; storm-tier2-oberhaur added conversation/tatooine_imperial_trainer_2; storm-tier1-akal-colzet added conversation/tatooine_imperial_trainer_1; inquisition-tier4-jace-yiaso added conversation/naboo_imperial_tier4; inquisition-tier3-barlow added conversation/naboo_imperial_tier3_barlow; inquisition-tier3-vrke added conversation/naboo_imperial_tier3; inquisition-tier2-fa-zoll added conversation/naboo_imperial_trainer_2; inquisition-tier1-barn-sinkko added conversation/naboo_imperial_trainer_1; smuggler-tier4-nirame added conversation/tatooine_privateer_tier4; smuggler-tier3-beissa added conversation/tatooine_privateer_tier3; smuggler-tier2-shamdon added conversation/tatooine_privateer_trainer_shamdon; smuggler-transition-karrde added conversation/tatooine_privateer_trainer_2; smuggler-tier1-dravis added conversation/tatooine_privateer_trainer_1; space-master-trainer-rebel added conversation/rebel_master_trainer; space-master-trainer-imperial added conversation/imperial_master_trainer; black-epsilon-tier1-hakassha added conversation/corellia_imperial_trainer_1, black-epsilon-tier2-prisk added conversation/corellia_imperial_trainer_2, black-epsilon-tier3-haymir added conversation/corellia_imperial_tier3, black-epsilon-tier4-nin-gursawe added conversation/corellia_imperial_tier4), equal to the referenced files, without skl_n, and skl_n.sids is deleted
function TestF5ArkonStaticUnresolved:test_fixture_counts_hold_the_64_referenced_files_without_skl_n_and_its_fixture_is_deleted()
	local referenced = CS.referencedFiles(CS.spaceConversationSources())

	lu.assertEquals(count(KD.FIXTURE_COUNTS), 71, "FIXTURE_COUNTS entries") -- 61 since storm-tier2-oberhaur, 64 since storm-tier2-nym-technicians, 65 since storm-tier2-alozen, 66 since storm-tier3-denner, 67 since storm-tier4-kilnstrider, 68 since vortex-tier1-kiizete, 69 since vortex-tier2-vrovel, 70 since vortex-tier3-ezkiel, 71 since vortex-tier4-extok-evin-convo
	lu.assertNil(KD.FIXTURE_COUNTS["skl_n"], "FIXTURE_COUNTS entry of skl_n")
	lu.assertEquals(referenced, sortedKeys(KD.FIXTURE_COUNTS), "string files referenced by the space conversation sources")

	for _, file in ipairs(referenced) do
		lu.assertNotEquals(file, "skl_n", "a space conversation source still references skl_n")
	end

	local f = io.open(CS.FIXTURE_DIR .. "skl_n.sids", "r")

	if f then f:close() end

	lu.assertNil(f, "the fixture skl_n.sids must be deleted")
end

-- AC-1: none of the 94 NGE ids (78 swapped, s_421 .. s_437 training) is named in either file
function TestF5ArkonStaticUnresolved:test_none_of_the_78_swapped_nge_ids_nor_the_training_nge_ids_is_named_in_either_file()
	for _, rel in ipairs(SOURCES) do
		local text = readFile(rel)

		for nge in pairs(DS.TWIN) do
			lu.assertNil(text:find(P .. nge .. '"', 1, true), rel .. " still carries " .. nge)
		end

		for n = 421, 437 do
			lu.assertNil(text:find(P .. "s_" .. n .. '"', 1, true), rel .. " still carries the training id s_" .. n)
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: pre-NGE ids only; no dynamic site
---------------------------------------------------------------------------------------------

TestF5ArkonPreNgeOnly = {}

function TestF5ArkonPreNgeOnly:setUp() H.reset() end

-- AC-2 (I-2): the 263 ids of the two files are the fixture minus s_0 and do_not_edit; none is NGE-shaped; every literal is of Arkon's file
function TestF5ArkonPreNgeOnly:test_the_ids_of_the_two_files_are_the_263_client_ids_and_none_is_nge_numbered()
	local client = assert(CS.sids(FILE))
	local used, want = {}, {}

	for _, lit in ipairs(CS.literals(SOURCES)) do
		lu.assertEquals(lit.file, FILE, lit.path .. ":" .. lit.line .. " names a string file other than " .. FILE .. " (" .. lit.id .. ")")
		used[lit.id] = true
		lu.assertNil(lit.id:find("^s_%d%d?%d?$"), lit.path .. ":" .. lit.line .. " carries the NGE-numbered id " .. lit.id)
	end

	for id in pairs(client) do
		if id ~= "s_0" and id ~= "do_not_edit" then
			want[id] = true
		end
	end

	lu.assertEquals(count(want), 263, "client ids minus s_0 and do_not_edit")
	lu.assertEquals(sortedKeys(used), sortedKeys(want), "ids of arkon_convo.lua and arkonConvoHandler.lua versus the client file")
end

-- AC-2: every twin is a hash id present in the fixture and in A4, of the same kind as its key
function TestF5ArkonPreNgeOnly:test_every_twin_is_a_client_hash_id_of_the_same_kind_as_its_nge_key()
	local client = assert(CS.sids(FILE))

	for _, site in ipairs(DS.SITES) do
		local label = "line " .. site.line .. " " .. site.nge .. " -> " .. site.twin

		lu.assertNotNil(site.nge:find("^s_%d%d?%d?$"), label .. ": the key is NGE-numbered")
		lu.assertNil(site.twin:find("^s_%d%d?%d?$"), label .. ": the twin is NGE-numbered")
		lu.assertTrue(client[site.twin] == true, label .. ": the twin is in the client fixture")
		lu.assertNil(client[site.nge], label .. ": the NGE key is not in the client fixture")

		if site.field == "leftDialog" then
			lu.assertNotNil(GRAPH.nodes[site.nge], label .. ": the key is an NPC line")
			lu.assertNotNil(GRAPH.nodes[site.twin], label .. ": the twin is an NPC line of A4 (same kind)")
			lu.assertNil(GRAPH.responses[site.twin], label .. ": the twin is not a reply")
		else
			lu.assertTrue(GRAPH.responses[site.nge] == true, label .. ": the key is a reply")
			lu.assertTrue(GRAPH.responses[site.twin] == true, label .. ": the twin is a reply of A4 (same kind)")
			lu.assertNil(GRAPH.nodes[site.twin], label .. ": the twin is not an NPC line")
		end
	end
end

-- AC-2: the 12 training ids are in the client fixture and not in A4
function TestF5ArkonPreNgeOnly:test_the_12_training_ids_are_in_the_client_fixture_and_not_in_a4()
	local client = assert(CS.sids(FILE))

	for _, id in ipairs(sortedKeys(DS.TRAINING_TEXT)) do
		lu.assertTrue(client[id] == true, id .. ": in the client fixture")
		lu.assertNil(GRAPH.nodes[id], id .. ": is not an NPC line of A4")
		lu.assertNil(GRAPH.responses[id], id .. ": is not a reply of A4")
	end
end

-- AC-1/AC-2: the stored-prefix sites are the 14 listed ones and none is Arkon's; no line uses a stored prefix (Arkon has none)
function TestF5ArkonPreNgeOnly:test_the_dynamic_sites_are_the_14_listed_lines_and_none_is_in_arkons_files()
	local src = CS.spaceConversationSources()
	local sites = CS.dynamicSites(src)

	lu.assertEquals(sites, KD.KNOWN_DYNAMIC, "lines that hold a string-file prefix instead of a complete id")

	for _, site in ipairs(sites) do
		lu.assertNil(site:find("arkon", 1, true), "dynamic site in Arkon's files: " .. site)
	end

	lu.assertEquals(CS.prefixUses(src), {}, "lines that use a stored string-file prefix")
	lu.assertEquals(CS.unusedPrefixes(src), KD.KNOWN_UNUSED_PREFIXES, "stored string-file prefixes nothing uses")
end

---------------------------------------------------------------------------------------------
-- AC-3: the 78 template lines (one test per Appendix A row, so a wrong twin names itself)
---------------------------------------------------------------------------------------------

TestF5ArkonTemplateLines = {}

function TestF5ArkonTemplateLines:setUp() H.reset() end

for _, site in ipairs(DS.SITES) do
	local field = site.field == "leftDialog" and "leftDialog" or ("option_" .. site.field)

	-- AC-3: the named field of the named screen is P .. twin (an option keeps its link), and the source line ends with `-- <exact client text>`
	TestF5ArkonTemplateLines["test_line_" .. site.line .. "_" .. site.screen .. "_" .. field .. "_shows_" .. site.twin .. "_" .. sanitize(DS.TEXT[site.twin]):sub(1, 40)] = function()
		local label = "arkon_convo.lua:" .. site.line .. " screen '" .. site.screen .. "' " .. field .. " (" .. site.nge .. " -> " .. site.twin .. ")"
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

		-- the source line of a swap that sits before the training block keeps its number; after it the lines move up
		local shift = site.line > DS.BLOCK_TO and (DS.AC_LINES - 1414) or 0
		local line = linesOf(readFile(AC))[site.line + shift]

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

-- AC-3, AC-4: 182 screens (186 - 6 + 2), no dead link or duplicate id
function TestF5ArkonTemplateLines:test_the_template_has_182_screens_and_no_dead_links_or_duplicate_ids()
	local _, t = screens()

	lu.assertEquals(#t.screens, 182, "arkon_convo: number of screens")
	lu.assertEquals(H.conversationProblems(TEMPLATE), {})
end

-- AC-3 (Appendix D): the leftDialog multiplicities
function TestF5ArkonTemplateLines:test_the_left_dialog_multiplicities_are_exactly_those_of_appendix_d()
	local owners = {}
	local _, template = screens()

	for _, s in ipairs(template.screens) do
		owners[s.leftDialog] = owners[s.leftDialog] or {}
		table.insert(owners[s.leftDialog], s.id)
	end

	local repeated = {}

	for dialog, list in pairs(owners) do
		if #list > 1 then
			repeated[sidOf(dialog)] = #list
		end
	end

	lu.assertEquals(repeated, DS.LEFT_COUNTS, "leftDialog ids shown on more than one screen, with their screen counts")

	local owner = owners[P .. "s_dc241019"]

	table.sort(owner)
	lu.assertEquals(owner, DS.DC241019_SCREENS, "screens showing \"What'd you say?\" (D-17)")
end

-- AC-3 (D-12 .. D-17): the slots without a parallel chain show the users' choices
function TestF5ArkonTemplateLines:test_the_inferred_slots_show_the_users_choices()
	local byId = screens()

	lu.assertEquals(byId.s_115.leftDialog, P .. "s_d98a6441", "s_115 (D-12)")
	lu.assertEquals(byId.s_220.leftDialog, P .. "s_ff9fae78", "s_220 (D-13)")
	lu.assertEquals(byId.s_229.leftDialog, P .. "s_882e7ab9", "s_229 (D-14)")
	lu.assertEquals(byId.s_229.options[1][1], P .. "s_d06c9b96", "s_229 reply (D-14)")
	lu.assertEquals(byId.s_233.leftDialog, P .. "s_a6e1a5f4", "s_233 (D-14)")
	lu.assertEquals(byId.s_233.options[1][1], P .. "s_bed0dfe7", "s_233 reply (D-14)")
	lu.assertEquals(byId.s_8762aa6e.options[1][1], P .. "s_77e48d5b", "s_8762aa6e reply (D-15)")
	lu.assertEquals(byId.s_fc6dfba9.options[1][1], P .. "s_d9cced1f", "s_fc6dfba9 reply 1 (D-16)")

	for _, id in ipairs({ "s_337", "s_359", "s_394" }) do
		lu.assertEquals(byId[id].leftDialog, P .. "s_dc241019", id .. " (D-17)")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: the training template and table
---------------------------------------------------------------------------------------------

TestF5ArkonTrainingTemplate = {}

function TestF5ArkonTrainingTemplate:setUp() H.reset() end

for _, row in ipairs(DS.TRAINING) do
	-- AC-4: the screen exists exactly as Content contract 1b says
	TestF5ArkonTrainingTemplate["test_screen_" .. row.id .. "_shows_" .. row.sid .. "_" .. sanitize(DS.TRAINING_TEXT[row.sid]):sub(1, 40)] = function()
		local screen = screens()[row.id]
		local label = "screen '" .. row.id .. "'"

		lu.assertNotNil(screen, label .. " exists")
		lu.assertEquals(screen.leftDialog, P .. row.sid, label .. ": leftDialog")
		lu.assertEquals(screen.animation or "", row.animation, label .. ": animation")
		lu.assertEquals(screen.stopConversation == "true", row.stop, label .. ": stopConversation")

		local got, want = {}, {}

		for i, o in ipairs(screen.options or {}) do got[i] = { o[1], o[2] } end
		for i, o in ipairs(row.options) do want[i] = { P .. o[1], o[2] } end

		lu.assertEquals(got, want, label .. ": options (reply, link)")
	end
end

-- AC-4: the six deleted screen ids are gone, the two added ones exist
function TestF5ArkonTrainingTemplate:test_the_six_old_training_screens_are_gone_and_the_two_closing_screens_exist()
	local byId = screens()

	for _, id in ipairs(DS.DELETED) do
		lu.assertNil(byId[id], "screen '" .. id .. "' must be deleted")
	end

	for _, id in ipairs(DS.ADDED) do
		lu.assertNotNil(byId[id], "screen '" .. id .. "' must exist")
	end
end

-- AC-4: ready_train is unchanged
function TestF5ArkonTrainingTemplate:test_ready_train_is_unchanged_s_8907c99_with_beckon_and_no_static_option()
	local screen = screens().ready_train

	lu.assertNotNil(screen, "screen ready_train")
	lu.assertEquals(screen.leftDialog, P .. "s_8907c99", "ready_train: leftDialog")
	lu.assertEquals(screen.animation, "beckon", "ready_train: animation")
	lu.assertEquals(screen.options, {}, "ready_train: static options")
	lu.assertNotEquals(screen.stopConversation, "true", "ready_train: does not end the conversation")
end

-- AC-4: every leftDialog and option of the six screens carries its client text as a trailing comment
function TestF5ArkonTrainingTemplate:test_the_training_lines_carry_their_client_text_as_trailing_comments()
	local lines = linesOf(readFile(AC))
	local checked = 0

	for _, row in ipairs(DS.TRAINING) do
		local at

		for i, line in ipairs(lines) do
			if line == '\tid = "' .. row.id .. '",' then at = i end
		end

		lu.assertNotNil(at, "screen " .. row.id .. " in the source")

		local want = { { P .. row.sid, DS.TRAINING_TEXT[row.sid] } }

		for _, o in ipairs(row.options) do want[#want + 1] = { P .. o[1], DS.TRAINING_TEXT[o[1]] } end

		for _, w in ipairs(want) do
			local found

			for i = at, math.min(at + 8, #lines) do
				if lines[i]:find(w[1] .. '"', 1, true) then
					found = lines[i]
					break
				end
			end

			lu.assertNotNil(found, row.id .. ": a source line naming " .. w[1])
			lu.assertEquals(found:match("%-%-%s*(.-)%s*$"), w[2], row.id .. ": trailing client-text comment of " .. w[1])
			checked = checked + 1
		end
	end

	lu.assertEquals(checked, 8, "training lines checked (6 NPC lines + 2 replies; the other 4 training ids are the handler's choice replies)")
end

TestF5ArkonTrainChoices = {}

function TestF5ArkonTrainChoices:setUp() H.reset() end

-- AC-4: TRAIN_CHOICES deep-equals Content contract 2, in order
function TestF5ArkonTrainChoices:test_train_choices_equals_content_contract_2_in_order()
	local got = {}

	for i, entry in ipairs(handler().TRAIN_CHOICES) do got[i] = { entry[1], entry[2], entry[3] } end

	lu.assertEquals(got, DS.TRAIN_CHOICES, "arkonConvoHandler.TRAIN_CHOICES")
end

-- AC-4: each acknowledgment is a template screen and a TRAINED_SCREENS key of the entry's skill; each reply is a complete literal that resolves
function TestF5ArkonTrainChoices:test_each_choice_leads_to_a_template_screen_that_grants_its_skill_and_each_reply_resolves_in_the_client_file()
	local h = handler()
	local byId = screens()
	local client = assert(CS.sids(FILE))

	for i, entry in ipairs(h.TRAIN_CHOICES) do
		lu.assertNotNil(byId[entry[3]], "TRAIN_CHOICES[" .. i .. "]: screen '" .. tostring(entry[3]) .. "' is in arkon_convo")
		lu.assertEquals(h.TRAINED_SCREENS[entry[3]], entry[1], "TRAIN_CHOICES[" .. i .. "]: TRAINED_SCREENS['" .. tostring(entry[3]) .. "']")
		lu.assertEquals(entry[2]:sub(1, #P), P, "TRAIN_CHOICES[" .. i .. "]: complete string id " .. tostring(entry[2]))
		lu.assertTrue(client[entry[2]:sub(#P + 1)] == true, "TRAIN_CHOICES[" .. i .. "]: " .. tostring(entry[2]) .. " is not in the client file")
	end
end

---------------------------------------------------------------------------------------------
-- AC-5: one-click training, what the updated test_havoc_tier4_arkon_*.lua do not pin
---------------------------------------------------------------------------------------------

TestF5ArkonTrainingFlow = {}

function TestF5ArkonTrainingFlow:setUp() H.reset() end
function TestF5ArkonTrainingFlow:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

local SECOND_LINE = { starships = "trained_starships_end", weapons = "trained_weapons_end" }

for _, c in ipairs(FC.CHOICES) do
	-- AC-5: the pick shows the acknowledgment of Content contract 1b and grants once; the second line of starships and weapons (option 0) grants nothing more
	TestF5ArkonTrainingFlow["test_picking_" .. c.x .. "_shows_the_pre_nge_acknowledgment_grants_once_and_ends_where_the_contract_says"] = function()
		costs()

		local player = trainee({}, 2 * COST)
		local row
		local last = SECOND_LINE[c.x]

		for _, r in ipairs(DS.TRAINING) do
			if r.id == c.screen then row = r end
		end

		local transcript = converse(player, last and { c.reply, 0 } or { c.reply })

		lu.assertEquals(ids(transcript), last and { "ready_train", c.screen, last } or { "ready_train", c.screen }, c.x .. ": screens")
		lu.assertEquals(transcript[2].text, P .. row.sid, c.x .. ": acknowledgment")
		lu.assertEquals(D.optionSids(transcript[2].options), last and { row.options[1][1] } or {}, c.x .. ": options of the acknowledgment")
		lu.assertEquals(transcript[2].stop, last == nil, c.x .. ": the acknowledgment ends the conversation iff it has no second line")

		if last then
			local closing
			local want = c.x == "starships" and "s_ecfe38f9" or "s_650af8ec"

			closing = transcript[3]
			lu.assertEquals(closing.text, P .. want, c.x .. ": second line")
			lu.assertTrue(closing.stop, c.x .. ": the second line ends the conversation")
			lu.assertEquals(#closing.options, 0, c.x .. ": the second line has no option")
		end

		local paid = H.Engine.callsTo("skillManagerAwardSkill")

		lu.assertEquals(#paid, 1, c.x .. ": skillManagerAwardSkill calls (once, also after the second line)")
		lu.assertEquals(paid[1][2], c.skill, c.x .. ": skill granted")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, c.x .. ": awardSkill (free grant) calls")
		lu.assertEquals(exp(player), COST, c.x .. ": XP (deducted once)")
		noUnresolved(transcript, c.x)
	end

	-- AC-5: nothing is granted on ready_train; the grant is reached by the one click on the reply
	TestF5ArkonTrainingFlow["test_picking_" .. c.x .. "_grants_on_display_of_the_acknowledgment_and_not_before"] = function()
		costs()

		local player = trainee({}, COST)
		local seen

		local transcript = converse(player, {
			function() seen = #H.Engine.callsTo("skillManagerAwardSkill") end,
			c.reply,
		})

		lu.assertEquals(seen, 0, c.x .. ": grants while ready_train is shown")
		lu.assertEquals(transcript[#transcript].id, c.screen, c.x .. ": the conversation reached the acknowledgment")
		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1, c.x .. ": grants after the click")
	end
end

-- AC-5: with one skill missing the greeting offers its one reply, which links straight to the acknowledgment; the fourth skill raises the tier
function TestF5ArkonTrainingFlow:test_a_pilot_with_one_skill_missing_gets_one_reply_which_ends_on_its_acknowledgment_and_raises_the_tier()
	for _, c in ipairs(FC.CHOICES) do
		H.reset()
		costs()

		local held = {}

		for _, o in ipairs(FC.CHOICES) do
			if o.x ~= c.x then held[#held + 1] = o.x end
		end

		local player = trainee(held)
		local transcript = converse(player, { c.reply })

		lu.assertEquals(#transcript[1].options, 1, c.x .. ": replies offered with three skills held")
		lu.assertEquals(transcript[1].options[1].text, c.reply, c.x .. ": the reply")
		lu.assertEquals(transcript[1].options[1].link, c.screen, c.x .. ": the link of the reply")
		lu.assertEquals(player.ghost:getPilotTier(), 5, c.x .. ": pilot tier after the fourth skill")
		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1, c.x .. ": grants")
	end
end

-- AC-5 (routing unchanged): a pilot with 999999 XP does not reach ready_train, so nothing is offered and nothing is granted
function TestF5ArkonTrainingFlow:test_with_less_than_one_million_xp_the_training_route_is_not_taken_at_all()
	costs()

	local player = trainee({}, COST - 1)
	local first = converse(player)[1]

	lu.assertNotEquals(first.id, "ready_train", "first screen of a pilot with 999999 XP")
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "grants")
end

---------------------------------------------------------------------------------------------
-- AC-6: journeys through the swapped chains (twin texts along the SWG path) and transcript scans
---------------------------------------------------------------------------------------------

TestF5ArkonJourneys = {}

function TestF5ArkonJourneys:setUp() H.reset() end

local function zeros(n)
	local out = {}

	for i = 1, n do out[i] = 0 end

	return out
end

-- A4 option sids from screen `from` to screen `to` (names of D.SCREENS or A4 sids)
local function a4Path(from, to)
	local path = GRAPH.pathTo(D.SCREENS[from] or from, D.SCREENS[to] or to)

	lu.assertNotNil(path, "answer key: no option path from " .. from .. " to " .. to)

	return path
end

-- the NPC sids the SWG java shows along an option path (no conditional option on these paths)
local function a4Lines(from, path)
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

-- name, builder, from screen, to screen
local JOURNEYS = {
	{ "mission1_offer_to_accept_a", function() return pilot(1) end, "mission1_offer", "mission1_accept_a" },
	{ "mission1_offer_mining_interests_to_accept_b", function() return pilot(1) end, "mission1_offer", "mission1_accept_b" },
	{ "mission1_offer_here_to_help_to_accept_c", function() return pilot(1) end, "mission1_offer", "mission1_accept_c" },
	{ "mission1_failed_to_retry_a", function() return pilot(1, { attempted = { 1 }, completed = {}, rewards = {} }) end, "mission1_failed", "mission1_retry_a" },
	{ "mission2_offer_to_accept_a", function() return pilot(2) end, "mission2_offer", "mission2_accept_a" },
	{ "mission2_offer_errand_for_nym_to_accept_b", function() return pilot(2) end, "mission2_offer", "mission2_accept_b" },
	{ "mission3_offer_to_accept_a", function() return pilot(3) end, "mission3_offer", "mission3_accept_a" },
	{ "mission3_offer_something_good_to_accept_b", function() return pilot(3) end, "mission3_offer", "mission3_accept_b" },
	{ "mission3_offer_not_another_inquisitor_to_accept_c", function() return pilot(3) end, "mission3_offer", "mission3_accept_c" },
	{ "mission4_offer_to_accept_a", function() return pilot(4) end, "mission4_offer", "mission4_accept_a" },
	{ "mission4_offer_youre_joking_to_accept_b", function() return pilot(4) end, "mission4_offer", "mission4_accept_b" },
	{ "mission1_offer_to_decline", function() return pilot(1) end, "mission1_offer", "mission1_decline" },
	{ "mission4_offer_to_decline", function() return pilot(4) end, "mission4_offer", "mission4_decline" },
	{ "intro_to_the_first_duty_menu", function() return D.havoc({}) end, "intro", "s_9bbb9999" },
	{ "intro_to_the_second_duty_menu", function() return D.havoc({}) end, "intro", "s_371" },
	{ "duty_info_to_its_duty_menu", function() return D.havoc({ met = true }) end, "tier4_incomplete", "s_406" },
}

for _, j in ipairs(JOURNEYS) do
	local name, build, from, to = j[1], j[2], j[3], j[4]

	-- AC-6: along the SWG path every NPC line and every reply shown is the twin of the SWG one, the mission starts only on its grant screen, and nothing is unresolved
	TestF5ArkonJourneys["test_journey_" .. name .. "_shows_the_twins_of_the_swg_lines_and_resolves_in_the_client"] = function()
		local rec = spyAllQuests()
		local player = build()
		local path = a4Path(from, to)
		local lines = a4Lines(from, path)
		local choices = {}

		for i, opt in ipairs(path) do choices[i] = twin(opt) end

		-- a mission grant is followed to the end of its chain; a duty menu is not chosen from (option 0 would start a duty)
		if to:find("^mission%d_accept_") or to:find("^mission%d_retry_") then
			for _, v in ipairs(zeros(12)) do choices[#choices + 1] = v end
		end

		local transcript = converse(player, choices)

		lu.assertEquals(transcript[1].id, from, name .. ": first screen")
		lu.assertTrue(#transcript >= #lines, name .. ": the conversation reached the end of the path (" .. #transcript .. " screens for " .. #lines .. " lines)")

		for i, sid in ipairs(lines) do
			lu.assertEquals(transcript[i].text, P .. twin(sid), name .. ": NPC line " .. i .. " (SWG " .. sid .. ")")

			if path[i] then
				local shown = {}

				for k, o in ipairs(transcript[i].options) do shown[k] = o.text end

				lu.assertTrue(#shown > 0, name .. ": step " .. i .. " has options")
				lu.assertNotNil(table.concat(shown, "|"):find(P .. twin(path[i]), 1, true), name .. ": step " .. i .. " offers the twin of reply " .. path[i])
			end
		end

		-- the quest starts only on the grant screens (the mission head, once) and nothing is paid
		local grant = to:match("^mission%d_(accept_%a)$") or to:match("^mission%d_(retry_%a)$")

		lu.assertEquals(#rec.starts, grant and 1 or 0, name .. ": quests started")
		lu.assertEquals(rec.rewards, {}, name .. ": rewards paid")
		noUnresolved(transcript, name)
	end
end

-- AC-6: the off-track chain not_my_track -> nontrack_duty -> duty_info -> ... -> s_406 starts nothing and resolves
function TestF5ArkonJourneys:test_the_off_track_chain_to_the_duty_menu_starts_nothing_and_resolves_in_the_client()
	local rec = spyAllQuests()
	local skills = {}

	for _, s in ipairs(D.SKILLS) do
		for tier = 1, 3 do skills[#skills + 1] = "pilot_rebel_navy_" .. s .. "_0" .. tier end
	end

	local player = H.newPlayer({ pilot = "rebel", squadronType = rawget(_G, "CORSEC_SQUADRON"), skills = skills, pilotTier = 4 })
	local choices = { "s_6222b64d", "s_c82e9a2f" }

	for _, opt in ipairs(a4Path("duty_info", "s_406")) do choices[#choices + 1] = twin(opt) end

	local transcript = converse(player, choices)

	lu.assertEquals(ids(transcript)[1], "not_my_track", "first screen")
	lu.assertEquals(ids(transcript)[2], "nontrack_duty", "second screen")
	lu.assertEquals(ids(transcript)[3], "duty_info", "third screen")
	lu.assertEquals(transcript[#transcript].text, P .. "s_9bbb9999", "the chain ends on the duty menu line")
	lu.assertEquals(#transcript[#transcript].options, 5, "duty menu options")
	lu.assertEquals(rec.starts, {}, "quests started while only reading")
	noUnresolved(transcript, "off-track chain")
end

-- AC-6: the reward, failure and gate screens resolve and keep their behavior (pay once with the reward first, +150 faction)
function TestF5ArkonJourneys:test_reward_and_gate_transcripts_resolve_in_the_client()
	for n = 1, 4 do
		H.reset()

		local rec = spyAllQuests()
		local player = pilot(n, { completed = {} })

		H.setQuestStatus(player, D.MISSION[n].statusName .. ":attempted", 1)
		player.ghost.journalComplete[H.questCrc(D.QUEST[D.MISSION[n].wins[1]][1], D.QUEST[D.MISSION[n].wins[1]][2])] = true

		for i = 1, n - 1 do
			player.ghost.journalComplete[H.questCrc(D.QUEST[D.MISSION[i].wins[1]][1], D.QUEST[D.MISSION[i].wins[1]][2])] = true
		end

		local before = player.ghost:getFactionStanding("rebel")
		local transcript = converse(player)

		lu.assertEquals(transcript[1].id, "mission" .. n .. "_reward", "mission " .. n .. ": first screen")
		lu.assertEquals(#rec.rewards, 1, "mission " .. n .. ": rewards paid")
		lu.assertEquals(player.ghost:getFactionStanding("rebel") - before, 150, "mission " .. n .. ": Rebel faction gained")
		noUnresolved(transcript, "mission " .. n .. " reward")
	end

	for _, gate in ipairs({
		{ "not_pilot", function() return H.newPlayer({}) end },
		{ "wrong_faction", function() return H.newPlayer({ pilot = "neutral" }) end },
		{ "negative_faction", function() return pilot(1, { standing = -1 }) end },
		{ "on_mission", function() return pilot(1, { active = { "m1" } }) end },
		{ "no_master", function() return D.havoc({ tier4 = D.SKILLS, rewards = { 1, 2, 3, 4 }, attempted = { 1, 2, 3, 4 }, completed = { "m1a", "m2a", "m3a", "m4c" }, met = true }) end },
	}) do
		H.reset()
		spyAllQuests()

		local transcript = converse(gate[2]())

		lu.assertEquals(transcript[1].id, gate[1], gate[1] .. ": first screen")
		noUnresolved(transcript, gate[1])
	end
end

-- AC-6: the first meeting sets the met flag
function TestF5ArkonJourneys:test_the_intro_still_sets_the_met_flag_on_intro_met()
	local player = D.havoc({})
	local transcript = converse(player, { "s_34d61fa3" })

	lu.assertEquals(ids(transcript), { "intro", "intro_met" })
	lu.assertEquals(H.getQuestStatus(player, D.MET_SUFFIX), "1", "StartedArkon after intro_met")
	noUnresolved(transcript, "intro")
end

---------------------------------------------------------------------------------------------
-- AC-7: nothing else moves, LF
---------------------------------------------------------------------------------------------

TestF5ArkonNothingElseMoves = {}

function TestF5ArkonNothingElseMoves:setUp() H.reset() end

-- AC-7: lines outside the training block are the base lines in order, except exactly the 78 Appendix A line numbers; those equal the base line with the NGE id on the
-- twin and ` -- <client text>` appended; base lines 859-925 are replaced by Appendix E
function TestF5ArkonNothingElseMoves:test_arkon_convo_equals_the_base_with_the_78_swaps_and_the_training_block_replaced_by_appendix_e()
	local now, old = linesOf(readFile(AC)), linesOf(baseFile(AC))
	local bySite = {}

	for _, site in ipairs(DS.SITES) do bySite[site.line] = site end

	local want = {}

	for i = 1, #old do
		if i == DS.BLOCK_FROM then
			for _, line in ipairs(DS.BLOCK) do want[#want + 1] = line end
		elseif i < DS.BLOCK_FROM or i > DS.BLOCK_TO then
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

	lu.assertEquals(#old, 1414, "number of lines of arkon_convo.lua at the base " .. BASE)
	lu.assertEquals(#now, DS.AC_LINES, "number of lines of arkon_convo.lua")
	lu.assertEquals(#want, DS.AC_LINES, "number of lines of the expected arkon_convo.lua")

	for i = 1, math.max(#now, #want) do
		lu.assertEquals(now[i], want[i], "arkon_convo.lua line " .. i .. " (base " .. BASE .. " plus the 78 swaps and the Appendix E block)")
	end
end

-- AC-7: AH differs from the base only in lines 52-59, which are Content contract 2
function TestF5ArkonNothingElseMoves:test_the_handler_differs_from_the_base_only_in_lines_52_to_59_which_are_content_contract_2()
	local now, old = linesOf(readFile(AH)), linesOf(baseFile(AH))
	local want = {}

	for i = 1, #old do
		if i == DS.HANDLER_FROM then
			for _, line in ipairs(DS.HANDLER_LINES) do want[#want + 1] = line end
		elseif i < DS.HANDLER_FROM or i > DS.HANDLER_TO then
			want[#want + 1] = old[i]
		end
	end

	lu.assertEquals(#old, DS.AH_LINES, "number of lines of arkonConvoHandler.lua at the base")
	lu.assertEquals(#now, DS.AH_LINES, "number of lines of arkonConvoHandler.lua")

	for i = 1, math.max(#now, #want) do
		lu.assertEquals(now[i], want[i], "arkonConvoHandler.lua line " .. i .. " (base " .. BASE .. " plus Content contract 2)")
	end
end

-- AC-7: both files are LF on every line, including the last, as at the base
function TestF5ArkonNothingElseMoves:test_both_files_are_lf_on_every_line_including_the_last()
	for _, rel in ipairs(SOURCES) do
		local text = readFile(rel)

		lu.assertNil(text:find("\r", 1, true), rel .. ": contains a CR byte")
		lu.assertEquals(text:sub(-1), "\n", rel .. ": the final line keeps its LF")
		lu.assertEquals(baseFile(rel):sub(-1), "\n", rel .. ": the base ends with LF too")
	end
end

-- AC-7: the template name, handler, initial screen and type are unchanged
function TestF5ArkonNothingElseMoves:test_the_template_keeps_its_name_handler_initial_screen_and_type()
	local _, t = screens()

	lu.assertEquals(t.luaClassHandler, "arkonConvoHandler", "luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.initialScreen, "", "initialScreen")
	lu.assertNotNil(readFile(AC):find('addConversationTemplate("arkon_convo", arkon_convo)', 1, true), "the addConversationTemplate line")
end

---------------------------------------------------------------------------------------------
-- AC-8: SWG conformance through the twin table
---------------------------------------------------------------------------------------------

TestF5ArkonConformance = {}

function TestF5ArkonConformance:setUp() H.reset() end

local REVERSE = {}

for id, sid in pairs(D.SCREENS) do REVERSE[sid] = id end

local function isTraining(sid)
	local n = tonumber(sid:match("^s_(%d+)$"))

	return n ~= nil and n >= 421 and n <= 437
end

-- AC-8 (I-3): every A4 NPC line Core3 shows is on the screen of that id with the twin as its line, A4's stop flag and animation (the training dialogue is E-AK2)
function TestF5ArkonConformance:test_every_shown_a4_npc_line_is_on_its_screen_as_its_twin_with_the_a4_stop_and_animation()
	local byId = screens()
	local seen = 0

	for _, sid in ipairs(GRAPH.order) do
		if not isTraining(sid) then
			local id = REVERSE[sid] or sid
			local screen = byId[id]

			lu.assertNotNil(screen, "A4 line " .. sid .. ": screen '" .. id .. "'")
			seen = seen + 1
			lu.assertEquals(screen.leftDialog, P .. twin(sid), "screen '" .. id .. "' (" .. sid .. "): leftDialog")
			lu.assertEquals(screen.stopConversation == "true", GRAPH.nodes[sid].isEnd, "screen '" .. id .. "' (" .. sid .. "): stopConversation")
			lu.assertEquals(screen.animation or "", GRAPH.nodes[sid].animation, "screen '" .. id .. "' (" .. sid .. "): animation")
		end
	end

	lu.assertEquals(seen, 176, "A4 NPC lines checked (186 - the 10 of the training dialogue)")
end

-- AC-8: usage is 135 of 186 NPC lines and 116 of 160 replies; the unused sids are exactly the twin keys plus s_421-s_437
function TestF5ArkonConformance:test_the_files_use_135_of_186_npc_lines_and_116_of_160_replies_and_the_unused_are_the_twin_keys_plus_the_training_ids()
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

	local wantNpc, wantResp = {}, {}

	for nge in pairs(DS.TWIN) do
		if GRAPH.nodes[nge] then wantNpc[#wantNpc + 1] = nge else wantResp[#wantResp + 1] = nge end
	end

	for n = 421, 437 do
		local sid = "s_" .. n

		if GRAPH.nodes[sid] then wantNpc[#wantNpc + 1] = sid else wantResp[#wantResp + 1] = sid end
	end

	table.sort(unusedNpc)
	table.sort(unusedResp)
	table.sort(wantNpc)
	table.sort(wantResp)
	lu.assertEquals(#GRAPH.order, 186, "A4 NPC lines")
	lu.assertEquals(count(usedNpc), 135, "A4 NPC lines used")
	lu.assertEquals(count(usedResp), 116, "A4 replies used")
	lu.assertEquals(count(GRAPH.responses), 160, "A4 replies")
	lu.assertEquals(unusedNpc, wantNpc, "unused NPC lines (41 twin keys + 10 training lines)")
	lu.assertEquals(unusedResp, wantResp, "unused replies (37 twin keys + 7 training replies)")
end
