-- Client string ids of Imler (RSF tier 4), part 2 (F6b): the four mission briefings. The last feature of the space conversation client-string work (gap report item CS-1).
-- Spec: .claude/work/space-convo-client-strings-imler-b/01-spec.md (AC-1 .. AC-9; I-1 .. I-6; D-1 .. D-16; FB-1 .. FB-10; Content contract 1 .. 4; Appendix A .. D, G, P).
--
-- The 196 NGE-numbered ids under the four mission<k>_brief screens (s_453 .. s_849) are replaced as a whole by the pre-NGE briefing dialogue that the client still holds: 62 screens built from the
-- 126 pool lines (Appendix G), 7 of them grant screens (mission<k>_accept_<x>). Nothing in the NGE subtrees can be matched by text (FB-1), so inside them Appendix G is the answer key (E-IM2);
-- the I4 java graph stays the key for every screen outside them (F6a D-9).
--
-- Everything the tests compare with is copied from the spec (rsf_tier4_imler_b_client_strings_data.lua: D.BRIEF_OPTIONS, D.SCREENS, D.TEXT, D.PATHS, D.REMOVED), not read from imler_convo.lua, so a wrong
-- line fails here instead of agreeing with itself. Each quoted text is also checked against its id: the client's ids are the SWG CRC-32 of the text (F6a FI-1).
-- Behavior (AC-5, AC-6) is driven through H.converse from both entries to a brief (ready_mission and one-click training); the superseded tests of Appendix C are updated in their own files.

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local D = require("rsf_tier4_data") -- player builder, mission table, status suffixes (D.SCREENS: the 7 kept grant sids since F6b)
local DS = require("rsf_tier4_imler_client_strings_data") -- F6a: D.TRAINING, D.REMAINING (the 196 NGE ids)
local FB = require("rsf_tier4_imler_b_client_strings_data") -- Appendix A, B, D, G, P
local KD = require("space_convo_client_strings_data")

H.loadSquadron("RsfSquadronScreenplay")
H.loadMobile("conversations/space/neutral/rsf_squadron/imler_convo.lua")
H.loadScreenplay("space/conversations/neutral/rsf_squadron/imlerConvoHandler.lua")

local P = FB.PREFIX
local BASE = FB.BASE
local FILE = FB.FILE
local TEMPLATE = "imler_convo_template"

local IC = "mobile/conversations/space/neutral/rsf_squadron/imler_convo.lua"
local IH = "screenplays/space/conversations/neutral/rsf_squadron/imlerConvoHandler.lua"
local SOURCES = { IC, IH }

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

-- the untrimmed STF text of an id: 20 of them end in exactly one space (Appendix B)
local function stfText(sid)
	local text = FB.textOf(sid)

	return FB.TRAILING[sid] and (text .. " ") or text
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

local function costs()
	local out = {}

	for _, row in ipairs(DS.TRAINING) do out[row.skill] = COST end

	H.Engine.config.skillXpCosts = out
end

local function spyAllQuests()
	local rec = { starts = {}, rewards = {}, completeAtStart = {} }

	for _, name in ipairs(H.questGlobals()) do
		local quest = rawget(_G, name)

		H.spyOn(quest, "startQuest", function(_, pPlayer)
			rec.starts[#rec.starts + 1] = name

			local complete = {}

			for _, key in ipairs(D.QUEST_KEYS) do
				if SpaceHelpers:isSpaceQuestComplete(pPlayer, D.QUEST[key][1], D.QUEST[key][2]) then complete[#complete + 1] = D.global(key) end
			end

			rec.completeAtStart[#rec.starts] = complete
		end)

		H.spyOn(quest, "rewardPlayer", function() rec.rewards[#rec.rewards + 1] = name end)
	end

	return rec
end

local function contains(list, value)
	for _, v in ipairs(list) do
		if v == value then return true end
	end

	return false
end

local function setComplete(player, keys)
	for _, key in ipairs(keys) do
		player.ghost.journalComplete[H.questCrc(D.QUEST[key][1], D.QUEST[key][2])] = true
	end
end

-- A pilot with the first k tier 4 skills who won and was paid missions 1..k-1
local function missionPilot(k, extra)
	local held, hist, completed = {}, {}, {}

	for i = 1, k do held[i] = D.SKILLS[i] end

	for i = 1, k - 1 do
		hist[i] = i
		completed[i] = D.MISSION[i].wins[1]
	end

	local opts = { tier4 = held, rewards = hist, attempted = hist, completed = completed, met = true }

	for key, v in pairs(extra or {}) do opts[key] = v end

	return D.rsf(opts)
end

-- the pilot of the training entry: k-1 skills held, ready_train is the first screen, XP for one more
local function trainee(k)
	local player = missionPilot(k - 1, { xp = 2 * COST })

	return player
end

local function noUnresolved(transcript, label)
	lu.assertEquals(CS.transcriptUnresolved(transcript), {}, label .. ": ids the pre-NGE client cannot resolve")
end

-- Every option path of one mission, depth first from its brief (Appendix G): { replies = { sid, ... }, screens = { id, ... }, grant = id }
local function pathsOf(k)
	local out = {}
	local brief = "mission" .. k .. "_brief"

	local function walk(options, replies, seen)
		for _, option in ipairs(options) do
			local reply, link = option[1], option[2]

			lu.assertNil(seen[link], brief .. ": the link " .. link .. " repeats on a path (cycle)")

			local nextReplies, nextSeen = {}, {}

			for i, v in ipairs(replies) do nextReplies[i] = v end
			for key in pairs(seen) do nextSeen[key] = true end

			nextReplies[#nextReplies + 1] = reply
			nextSeen[link] = true

			local row = FB.BY_ID[link]

			lu.assertNotNil(row, brief .. ": link " .. link .. " is a screen of Appendix G")

			if FB.GRANTS[link] then
				local screensOnPath = {}

				for key in pairs(nextSeen) do screensOnPath[#screensOnPath + 1] = key end

				out[#out + 1] = { replies = nextReplies, grant = link }
			else
				walk(row.options, nextReplies, nextSeen)
			end
		end
	end

	walk(FB.BRIEF_OPTIONS[brief], {}, {})

	return out
end

-- Option paths from the brief to every non-grant screen (the shortest, by breadth first): screen id -> replies
local function reachPaths(k)
	local brief = "mission" .. k .. "_brief"
	local found = {}
	local queue = { { options = FB.BRIEF_OPTIONS[brief], replies = {} } }
	local head = 1

	while head <= #queue do
		local node = queue[head]

		head = head + 1

		for _, option in ipairs(node.options) do
			local link = option[2]
			local replies = {}

			for i, v in ipairs(node.replies) do replies[i] = v end

			replies[#replies + 1] = option[1]

			if not found[link] and not FB.GRANTS[link] then
				found[link] = replies
				queue[#queue + 1] = { options = FB.BY_ID[link].options, replies = replies }
			end
		end
	end

	return found
end

---------------------------------------------------------------------------------------------
-- sanity of the copied answer key
---------------------------------------------------------------------------------------------

TestF6bAnswerKey = {}

function TestF6bAnswerKey:setUp() H.reset() end

-- AC-2, AC-3 (sanity of the data copied from the spec): the sizes of Appendix G, B, D and P
function TestF6bAnswerKey:test_appendix_g_has_62_screens_9_brief_options_7_grants_and_a_pool_of_126_texts()
	local perMission, grants, briefOptions = { 0, 0, 0, 0 }, 0, 0

	for _, row in ipairs(FB.SCREENS) do
		perMission[row.mission] = perMission[row.mission] + 1

		if FB.GRANTS[row.id] then
			grants = grants + 1
			lu.assertNotNil(row.anim, row.id .. ": a grant screen has an animation")
			lu.assertEquals(#row.options, 0, row.id .. ": a grant screen has no option")
		else
			lu.assertNil(row.anim, row.id .. ": a non-grant screen has no animation")
			lu.assertTrue(#row.options >= 1, row.id .. ": a non-grant screen offers an option")
		end
	end

	for _, brief in ipairs(FB.BRIEF_ORDER) do briefOptions = briefOptions + #FB.BRIEF_OPTIONS[brief] end

	lu.assertEquals(#FB.SCREENS, 62, "Appendix G screens")
	lu.assertEquals(perMission, { 16, 18, 19, 9 }, "screens per mission")
	lu.assertEquals(grants, 7, "grant screens")
	lu.assertEquals(count(FB.GRANTS), 7, "D.GRANTS entries")
	lu.assertEquals(briefOptions, 9, "brief options (M4 2, M3 3, M2 2, M1 2)")
	lu.assertEquals(count(FB.TEXT), 126, "pool texts")
	lu.assertEquals(#FB.CLIENT_ONLY, 130, "client-only ids (the pool and the 4 training replies)")
	lu.assertEquals(#FB.REMOVED, 91, "Appendix D ids")
	lu.assertEquals(count(FB.PATHS), 7, "Appendix P paths")
end

-- AC-2 (I-6): every quoted text is the text whose SWG CRC-32 is its id (the untrimmed STF text, with the trailing space of Appendix B)
function TestF6bAnswerKey:test_every_pool_text_and_brief_line_is_the_text_whose_crc32_is_its_id()
	for sid, text in pairs(FB.TEXT) do
		lu.assertEquals(crcId(stfText(sid)), sid, "Appendix B/G: the client id of \"" .. text .. "\"")
	end

	for sid, text in pairs(FB.BRIEF_TEXT) do
		lu.assertEquals(crcId(text), sid, "Appendix G: the client id of the unchanged brief line \"" .. text .. "\"")
	end

	local n = 0

	for sid in pairs(FB.TRAILING) do
		lu.assertNotNil(FB.TEXT[sid], "Appendix B: trailing-space id " .. sid .. " is a pool id")
		n = n + 1
	end

	lu.assertEquals(n, 20, "ids with a trailing space")
end

-- AC-2, AC-3 (sanity): every id of Appendix G is in the client file, no NPC line or reply of the rows is NGE-numbered, every pool id is placed, every link is a screen
function TestF6bAnswerKey:test_appendix_g_uses_only_client_ids_places_every_pool_id_and_links_only_to_its_own_screens()
	local client = assert(CS.sids(FILE))
	local placed = {}

	local function use(sid, label)
		lu.assertTrue(client[sid] == true, label .. ": " .. sid .. " is in the client file")
		lu.assertNil(sid:find("^s_%d%d?%d?$"), label .. ": " .. sid .. " is NGE-shaped")

		placed[sid] = true
	end

	for _, brief in ipairs(FB.BRIEF_ORDER) do
		use(FB.BRIEF_NPC[brief], brief)

		for i, o in ipairs(FB.BRIEF_OPTIONS[brief]) do
			use(o[1], brief .. " option " .. i)
			lu.assertNotNil(FB.BY_ID[o[2]], brief .. " option " .. i .. ": link " .. o[2] .. " is an Appendix G screen")
		end
	end

	for _, row in ipairs(FB.SCREENS) do
		use(row.sid, row.id)

		for i, o in ipairs(row.options) do
			use(o[1], row.id .. " option " .. i)
			lu.assertNotNil(FB.BY_ID[o[2]], row.id .. " option " .. i .. ": link " .. o[2] .. " is an Appendix G screen")
		end
	end

	-- the training replies are the handler's; the duty reply s_3f68df7d is placed in M1 as well (D-2)
	for sid in pairs(FB.TEXT) do lu.assertTrue(placed[sid] == true, "pool id " .. sid .. " is placed by Appendix G") end
end

-- AC-6 (sanity): the depth-first search finds the 87 option paths of the spec (5 / 8 / 72 / 2), and Appendix P lists one of them for each grant screen
function TestF6bAnswerKey:test_the_option_paths_are_87_in_total_5_8_72_and_2_per_mission_and_appendix_p_lists_one_per_grant_screen()
	local perMission = {}

	for k = 1, 4 do
		local paths = pathsOf(k)
		local byGrant = {}

		perMission[k] = #paths

		for _, p in ipairs(paths) do byGrant[p.grant] = (byGrant[p.grant] or 0) + 1 end

		for grant, mission in pairs(FB.GRANTS) do
			if mission == k then
				lu.assertTrue((byGrant[grant] or 0) >= 1, grant .. ": at least one option path ends on it")

				local listed = false

				for _, p in ipairs(paths) do
					if p.grant == grant and table.concat(p.replies, ",") == table.concat(FB.PATHS[grant], ",") then listed = true end
				end

				lu.assertTrue(listed, grant .. ": the Appendix P path is one of the option paths")
			end
		end
	end

	lu.assertEquals(perMission, { 5, 8, 72, 2 }, "option paths per mission")
end

---------------------------------------------------------------------------------------------
-- AC-1: the ratchet is empty
---------------------------------------------------------------------------------------------

TestF6bStaticUnresolved = {}

function TestF6bStaticUnresolved:setUp() H.reset() end

-- AC-1 (I-1)
function TestF6bStaticUnresolved:test_known_gaps_is_empty()
	lu.assertEquals(KD.KNOWN_GAPS, {}, "KNOWN_GAPS")
	lu.assertEquals(sortedKeys(KD.KNOWN_GAPS), {}, "KNOWN_GAPS files")
end

-- AC-1 (I-1)
function TestF6bStaticUnresolved:test_imlers_files_show_no_id_that_the_client_cannot_resolve()
	lu.assertEquals(CS.unresolved(SOURCES), {}, "Imler: ids the pre-NGE client cannot resolve")
end

-- AC-1 (I-1)
function TestF6bStaticUnresolved:test_no_space_conversation_source_shows_an_id_that_the_client_cannot_resolve()
	lu.assertEquals(CS.unresolvedByFile(CS.spaceConversationSources()), {}, "unresolvedByFile")
end

-- AC-1: FIXTURE_COUNTS keeps its entries (44 since black-epsilon-tier1-hakassha, 45 since black-epsilon-tier2-prisk, 46 since black-epsilon-tier3-haymir, 47 since black-epsilon-tier4-nin-gursawe), equal to the string files the sources reference
function TestF6bStaticUnresolved:test_fixture_counts_still_hold_the_47_referenced_files()
	local referenced = CS.referencedFiles(CS.spaceConversationSources())

	lu.assertEquals(count(KD.FIXTURE_COUNTS), 47, "FIXTURE_COUNTS entries")
	lu.assertEquals(referenced, sortedKeys(KD.FIXTURE_COUNTS), "string files referenced by the space conversation sources")
end

---------------------------------------------------------------------------------------------
-- AC-2: pre-NGE ids only
---------------------------------------------------------------------------------------------

TestF6bPreNgeOnly = {}

function TestF6bPreNgeOnly:setUp() H.reset() end

-- AC-2 (I-2): the distinct ids of the file in IC and IH are exactly the 258 ids of the client file but s_0 and do_not_edit
function TestF6bPreNgeOnly:test_the_files_use_exactly_the_258_real_ids_of_the_client_file()
	local used = {}

	for _, lit in ipairs(CS.literals(SOURCES)) do
		if lit.file == FILE then used[lit.id] = true end
	end

	local client = {}

	for id in pairs(assert(CS.sids(FILE))) do client[id] = true end

	lu.assertEquals(count(client), 260, "ids of the client file")

	client.s_0, client.do_not_edit = nil, nil
	lu.assertEquals(sortedKeys(used), sortedKeys(client), "distinct ids of the file used by imler_convo.lua and imlerConvoHandler.lua")
	lu.assertEquals(count(used), 258, "distinct ids used")
end

-- AC-2 (I-2): none of the 196 NGE ids is named in either file and no id is NGE-numbered
function TestF6bPreNgeOnly:test_none_of_the_196_f6b_ids_and_no_nge_numbered_id_is_left_in_either_file()
	lu.assertEquals(#DS.REMAINING, 196, "the F6b ids")

	for _, rel in ipairs(SOURCES) do
		local text = readFile(rel)

		for _, id in ipairs(DS.REMAINING) do
			lu.assertNil(text:find(P .. id .. '"', 1, true), rel .. " still carries " .. id)
		end
	end

	for _, lit in ipairs(CS.literals(SOURCES)) do
		if lit.file == FILE then lu.assertNil(lit.id:find("^s_%d%d?%d?$"), lit.path .. ":" .. lit.line .. " names the NGE-numbered id " .. lit.id) end
	end
end

-- AC-2: every one of the 126 pool ids occurs in the files
function TestF6bPreNgeOnly:test_every_one_of_the_126_pool_ids_occurs_in_the_files()
	local used = {}

	for _, lit in ipairs(CS.literals(SOURCES)) do
		if lit.file == FILE then used[lit.id] = true end
	end

	for sid, text in pairs(FB.TEXT) do
		lu.assertTrue(used[sid] == true, "pool id " .. sid .. " (" .. text .. ") is not used by imler_convo.lua or imlerConvoHandler.lua")
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: the template, screen by screen (Appendix G)
---------------------------------------------------------------------------------------------

TestF6bTemplate = {}

function TestF6bTemplate:setUp() H.reset() end

-- AC-3: 138 screens, no dead link or duplicate id
function TestF6bTemplate:test_the_template_has_138_screens_and_no_dead_links_or_duplicate_ids()
	local _, t = screens()

	lu.assertEquals(#t.screens, FB.SCREEN_COUNT, "imler_convo_template: number of screens (174 - 98 + 62)")
	lu.assertEquals(H.conversationProblems(TEMPLATE), {})
end

-- AC-3 (Appendix D): none of the 91 removed ids is a screen, and none is named in the source
function TestF6bTemplate:test_the_91_removed_screens_of_appendix_d_are_gone()
	local byId = screens()
	local text = readFile(IC)

	for _, id in ipairs(FB.REMOVED) do
		lu.assertNil(byId[id], "screen '" .. id .. "' must be removed")
		lu.assertNil(text:find('id = "' .. id .. '"', 1, true), "imler_convo.lua still defines screen " .. id)
		lu.assertNil(text:find('"' .. id .. '"', 1, true), "imler_convo.lua still names " .. id)
	end
end

-- AC-3: the briefs keep their id, line and no animation; their options are the 9 of Appendix A / G in order
for _, brief in ipairs(FB.BRIEF_ORDER) do
	TestF6bTemplate["test_" .. brief .. "_keeps_its_line_and_offers_the_pre_nge_replies_of_appendix_g_in_order"] = function()
		local screen = screens()[brief]
		local wanted = FB.BRIEF_OPTIONS[brief]

		lu.assertNotNil(screen, "screen " .. brief)
		lu.assertEquals(screen.leftDialog, P .. FB.BRIEF_NPC[brief], brief .. ": leftDialog (" .. FB.BRIEF_TEXT[FB.BRIEF_NPC[brief]] .. ")")
		lu.assertNil(screen.animation, brief .. ": animation")
		lu.assertNotEquals(screen.stopConversation, "true", brief .. ": does not end the conversation")
		lu.assertEquals(#screen.options, #wanted, brief .. ": number of options")

		for i, o in ipairs(wanted) do
			lu.assertEquals(screen.options[i][1], P .. o[1], brief .. " option " .. i .. ": reply (" .. FB.TEXT[o[1]] .. ")")
			lu.assertEquals(screen.options[i][2], o[2], brief .. " option " .. i .. " (" .. FB.TEXT[o[1]] .. "): link")
		end
	end
end

-- AC-3: each of the 62 screens has exactly its row's line, options (in order, with links), animation and stop flag
for _, row in ipairs(FB.SCREENS) do
	local name = "test_mission" .. row.mission .. "_row_" .. row.row .. "_screen_" .. sanitize(row.id) .. "_shows_" .. sanitize(row.text):sub(1, 40)

	TestF6bTemplate[name] = function()
		local screen = screens()[row.id]
		local label = "mission " .. row.mission .. " row " .. row.row .. " screen '" .. row.id .. "'"

		lu.assertNotNil(screen, label .. ": the screen exists")
		lu.assertEquals(screen.leftDialog, P .. row.sid, label .. ": leftDialog (" .. row.text .. ")")
		lu.assertEquals(screen.animation, row.anim, label .. ": animation")
		lu.assertEquals(screen.stopConversation, FB.GRANTS[row.id] and "true" or nil, label .. ": stopConversation (only the 7 grant screens end the conversation)")
		lu.assertEquals(#(screen.options or {}), #row.options, label .. ": number of options")

		for i, o in ipairs(row.options) do
			lu.assertEquals(screen.options[i][1], P .. o[1], label .. " option " .. i .. ": reply (" .. FB.TEXT[o[1]] .. ")")
			lu.assertEquals(screen.options[i][2], o[2], label .. " option " .. i .. " (" .. FB.TEXT[o[1]] .. "): link")
		end
	end
end

-- AC-3 (I-3): in the subtrees only the 7 grant screens stop the conversation, and exactly those carry an animation
function TestF6bTemplate:test_only_the_7_grant_screens_of_the_subtrees_stop_the_conversation_and_carry_an_animation()
	local byId = screens()
	local stopping, animated = {}, {}

	for _, row in ipairs(FB.SCREENS) do
		local screen = byId[row.id]

		lu.assertNotNil(screen, "screen " .. row.id)

		if screen.stopConversation == "true" then stopping[#stopping + 1] = row.id end
		if screen.animation ~= nil then animated[#animated + 1] = row.id end
	end

	table.sort(stopping)
	table.sort(animated)
	lu.assertEquals(stopping, FB.GRANT_IDS, "Appendix G screens that stop the conversation")
	lu.assertEquals(animated, FB.GRANT_IDS, "Appendix G screens with an animation")
end

-- AC-3 (D-3): the animations of the grant screens are the slots' own (M1/M2 dismiss, M3 wave_on_dismissing, M4 salute1)
function TestF6bTemplate:test_the_grant_screens_keep_the_animation_of_their_slot()
	local byId = screens()
	local want = {
		mission1_accept_a = "dismiss", mission2_accept_a = "dismiss", mission2_accept_b = "dismiss",
		mission3_accept_a = "wave_on_dismissing", mission3_accept_b = "wave_on_dismissing",
		mission4_accept_a = "salute1", mission4_accept_b = "salute1",
	}

	for id, anim in pairs(want) do
		lu.assertNotNil(byId[id], "grant screen " .. id)
		lu.assertEquals(byId[id].animation, anim, id .. ": animation")
	end
end

-- AC-3 (D-5): every screen of Appendix G is named by its sid except the 7 grant screens
function TestF6bTemplate:test_the_55_non_grant_screens_are_named_by_their_sid_and_the_7_grant_screens_keep_their_names()
	local n = 0

	for _, row in ipairs(FB.SCREENS) do
		if FB.GRANTS[row.id] then
			lu.assertNotNil(row.id:find("^mission%d_accept_%a$"), row.id .. ": a grant screen name")
		else
			lu.assertEquals(row.id, row.sid, "the screen of NPC line " .. row.sid)
			n = n + 1
		end
	end

	lu.assertEquals(n, 55, "non-grant screens")
	lu.assertNotNil(screens().s_841d27db, "Imler's \"Why?\" is the screen s_841d27db (D-5)")
end

-- AC-3 (D-2): the mapping table of rsf_tier4_data.lua names the 7 grant sids and the screens show them
function TestF6bTemplate:test_the_mandatory_grant_screens_of_the_shared_data_show_the_pre_nge_send_offs()
	local byId = screens()
	local wanted = {
		mission1_accept_a = "s_42d6c3ee", mission2_accept_a = "s_e7515ed5", mission2_accept_b = "s_90422eb5",
		mission3_accept_a = "s_ff66ed8b", mission3_accept_b = "s_48621561", mission4_accept_a = "s_9281abbb", mission4_accept_b = "s_8a0c5ce7",
	}

	for id, sid in pairs(wanted) do
		lu.assertEquals(D.SCREENS[id], sid, "rsf_tier4_data.lua D.SCREENS[" .. id .. "]")
		lu.assertNotNil(byId[id], "screen " .. id)
		lu.assertEquals(byId[id].leftDialog, P .. sid, id .. ": leftDialog")
	end

	for _, id in ipairs({ "mission1_accept_b", "mission1_accept_c", "mission2_accept_c", "mission3_accept_c", "mission3_accept_d", "mission3_accept_e" }) do
		lu.assertNil(D.SCREENS[id], "rsf_tier4_data.lua still maps the removed grant screen " .. id)
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: the source lines
---------------------------------------------------------------------------------------------

TestF6bSourceLines = {}

function TestF6bSourceLines:setUp() H.reset() end

-- AC-4: 1035 lines
function TestF6bSourceLines:test_imler_convo_has_1035_lines()
	lu.assertEquals(#linesOf(readFile(IC)), FB.AC_LINES, "number of lines of imler_convo.lua")
end

-- AC-4 (Content contract 1): the 9 brief option lines are the format applied to Appendix A, with the trailing client text
function TestF6bSourceLines:test_the_9_brief_option_lines_are_the_format_with_a_trailing_client_text_comment()
	local lines = linesOf(readFile(IC))

	for _, entry in ipairs(FB.BRIEF_LINES) do
		local line, brief, index = entry[1], entry[2], entry[3]
		local o = FB.BRIEF_OPTIONS[brief][index]

		lu.assertEquals(lines[line], FB.optionLine(o[1], o[2], FB.TEXT[o[1]]), "imler_convo.lua line " .. line .. " (" .. brief .. " option " .. index .. ")")
	end
end

-- AC-4: the 62 blocks in file order from line 325, one test per screen so a wrong line names itself
do
	local at = FB.REPLACED.blockFrom

	for _, row in ipairs(FB.SCREENS) do
		local block = FB.blockLines(row)
		local from = at

		TestF6bSourceLines["test_mission" .. row.mission .. "_row_" .. row.row .. "_block_of_screen_" .. sanitize(row.id) .. "_is_at_line_" .. from .. "_with_its_client_text_comments"] = function()
			local lines = linesOf(readFile(IC))

			for i, want in ipairs(block) do
				lu.assertEquals(lines[from + i - 1], want, "imler_convo.lua line " .. (from + i - 1) .. " (screen " .. row.id .. ", block line " .. i .. ")")
			end
		end

		at = at + #block
	end

	-- the blocks fill exactly lines 325-770, the block after them is the first screen after the old range
	TestF6bSourceLines.test_the_blocks_end_at_line_770_and_the_duty_destroy_screen_follows = function()
		local lines = linesOf(readFile(IC))

		lu.assertEquals(at - 1, FB.REPLACED.blockFrom + 446 - 1, "the last line of the blocks")
		lu.assertEquals(lines[at], "imler_convo_template:addScreen(ConvoScreen:new {", "line " .. at)
		lu.assertEquals(lines[at + 1], '\tid = "duty_destroy",', "the screen after the blocks")
	end
end

-- AC-4 (I-6): every changed or new line that holds a P literal ends with ` -- <text>` of the last P id on the line, and the CRC-32 of that text is the id
function TestF6bSourceLines:test_every_line_of_the_replaced_ranges_with_a_client_id_ends_with_its_client_text_and_the_text_hashes_to_the_id()
	local lines = linesOf(readFile(IC))
	local checked = 0
	local function inRange(n)
		for _, b in ipairs(FB.REPLACED.briefLines) do
			if b == n then return true end
		end

		return n >= FB.REPLACED.blockFrom and n <= FB.REPLACED.blockFrom + 446 - 1
	end

	for n, line in ipairs(lines) do
		if inRange(n) then
			local last
			for sid in line:gmatch("naboo_privateer_tier4:(s_[%w_]+)") do last = sid end

			if last then
				local comment = line:match(" %-%- (.*)$")

				lu.assertNotNil(comment, "imler_convo.lua line " .. n .. ": a trailing ` -- <client text>` comment")
				lu.assertEquals(comment, FB.textOf(last), "imler_convo.lua line " .. n .. ": the comment is the text of " .. last)
				lu.assertEquals(crcId(stfText(last)), last, "imler_convo.lua line " .. n .. ": the client id of the quoted text")
				checked = checked + 1
			end
		end
	end

	local optionLines = 0

	for _, row in ipairs(FB.SCREENS) do optionLines = optionLines + #row.options end

	lu.assertEquals(checked, 9 + 62 + optionLines, "client-id lines checked (9 brief options, 62 leftDialogs and the options of the 55 non-grant screens)")
end

---------------------------------------------------------------------------------------------
-- AC-5: the 7 grant screens, from both entries
---------------------------------------------------------------------------------------------

TestF6bGrants = {}

function TestF6bGrants:setUp() H.reset() end
function TestF6bGrants:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- the choices of a walk from ready_mission / from the click that trains skill k to the end of Appendix P's path; a hook before the last choice records the state and sets stale journal entries
local function grantWalk(entry, grant, probe)
	local k = FB.GRANTS[grant]
	local path = FB.PATHS[grant]
	local player, choices

	if entry == "ready_mission" then
		player = missionPilot(k, { ready = true })
		choices = { "s_39e697de" }
	else
		costs()

		player = trainee(k)
		choices = { DS.TRAINING[k].sid }
	end

	for i, reply in ipairs(path) do
		if i == #path then
			choices[#choices + 1] = function(p)
				local stale = {}

				for _, key in ipairs(D.MISSION[k].chain) do stale[#stale + 1] = key end

				stale[#stale + 1] = D.MISSION[k % 4 + 1].main
				setComplete(p, stale)
				probe(p)
			end
		end

		choices[#choices + 1] = reply
	end

	return player, choices
end

for _, grant in ipairs(FB.GRANT_IDS) do
	local k = FB.GRANTS[grant]

	for _, entry in ipairs({ "ready_mission", "training" }) do
		-- AC-5: the walk ends on the grant screen, which starts mission k's main quest exactly once; nothing starts or pays before it
		TestF6bGrants["test_" .. grant .. "_via_" .. entry .. "_ends_on_it_and_starts_only_mission_" .. k .. "_main_quest_once_with_nothing_started_or_paid_before"] = function()
			local rec = spyAllQuests()
			local before
			local player, choices = grantWalk(entry, grant, function() before = { #rec.starts, #rec.rewards } end)
			local transcript = converse(player, choices)

			lu.assertEquals(transcript[1].id, entry == "ready_mission" and "ready_mission" or "ready_train", grant .. ": first screen")
			lu.assertEquals(transcript[2].id, "mission" .. k .. "_brief", grant .. ": the brief of " .. k .. " skills")
			lu.assertEquals(transcript[#transcript].id, grant, grant .. ": last screen; got " .. table.concat(ids(transcript), ","))
			lu.assertEquals(#transcript, #FB.PATHS[grant] + 2, grant .. ": number of screens (entry, brief and one per reply)")
			lu.assertEquals(before, { 0, 0 }, grant .. ": quests started and rewards paid before the grant screen")
			lu.assertEquals(rec.starts, { D.global(D.MISSION[k].main) }, grant .. ": quests started")
			lu.assertEquals(rec.rewards, {}, grant .. ": rewards paid")
			noUnresolved(transcript, grant .. " via " .. entry)
		end

		-- AC-5: the old journal entries of the mission are cleared before the start, :attempted is set, the ready flag is cleared and the next talk does not start on ready_mission
		TestF6bGrants["test_" .. grant .. "_via_" .. entry .. "_clears_the_old_journal_entries_sets_attempted_and_clears_the_ready_flag"] = function()
			local rec = spyAllQuests()
			local player, choices = grantWalk(entry, grant, function() end)

			converse(player, choices)
			lu.assertEquals(#rec.starts, 1, grant .. ": number of quest starts")

			for _, key in ipairs(D.MISSION[k].chain) do
				lu.assertFalse(contains(rec.completeAtStart[1], D.global(key)), grant .. ": " .. D.global(key) .. " was still journal-complete when the mission started")
			end

			local otherKey = D.MISSION[k % 4 + 1].main

			lu.assertTrue(SpaceHelpers:isSpaceQuestComplete(player, D.QUEST[otherKey][1], D.QUEST[otherKey][2]), grant .. ": " .. D.global(otherKey) .. " (another mission) must not be cleared")
			lu.assertEquals(H.getQuestStatus(player, D.MISSION[k].statusName .. ":attempted"), "1", grant .. ": :attempted status")
			lu.assertNil(H.getQuestStatus(player, D.READY_SUFFIX), grant .. ": readyForTier4Mission removed")
			lu.assertNotEquals(converse(player)[1].id, "ready_mission", grant .. ": the next talk must not start on ready_mission")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: every option path
---------------------------------------------------------------------------------------------

TestF6bEveryRoute = {}

function TestF6bEveryRoute:setUp() H.reset() end

-- AC-6 (I-3, I-4): each of the 87 paths (5 / 8 / 72 / 2) from ready_mission reads through without a repeated screen, ends on a grant screen of its mission, starts exactly that mission once, pays nothing
for k = 1, 4 do
	TestF6bEveryRoute["test_every_option_path_of_mission_" .. k .. "_ends_on_a_grant_screen_of_mission_" .. k .. "_and_starts_only_its_main_quest_once"] = function()
		local paths = pathsOf(k)

		lu.assertEquals(#paths, ({ 5, 8, 72, 2 })[k], "option paths of mission " .. k)

		for n, p in ipairs(paths) do
			H.reset()

			local rec = spyAllQuests()
			local player = missionPilot(k, { ready = true })
			local choices = { "s_39e697de" }
			local label = "mission " .. k .. " path " .. n .. " [" .. table.concat(p.replies, ",") .. "]"

			for _, reply in ipairs(p.replies) do choices[#choices + 1] = reply end

			local transcript = converse(player, choices)
			local seen = {}

			for _, step in ipairs(transcript) do
				lu.assertNil(seen[step.id], label .. ": screen " .. step.id .. " repeats")
				seen[step.id] = true
			end

			lu.assertEquals(transcript[2].id, "mission" .. k .. "_brief", label .. ": the brief")
			lu.assertEquals(transcript[#transcript].id, p.grant, label .. ": last screen; got " .. table.concat(ids(transcript), ","))
			lu.assertEquals(FB.GRANTS[transcript[#transcript].id], k, label .. ": the grant screen belongs to mission " .. k)
			lu.assertTrue(transcript[#transcript].stop, label .. ": the grant screen ends the conversation")
			lu.assertEquals(rec.starts, { D.global(D.MISSION[k].main) }, label .. ": quests started")
			lu.assertEquals(rec.rewards, {}, label .. ": rewards paid")
			lu.assertNil(H.getQuestStatus(player, D.READY_SUFFIX), label .. ": ready flag after the mission started")
			noUnresolved(transcript, label)
		end
	end

	-- AC-6: the same from the click of one-click training (the brief is the screen the click lands on), for the first path of each grant screen of the mission
	TestF6bEveryRoute["test_the_training_entry_reaches_every_grant_screen_of_mission_" .. k .. "_by_its_first_option_path"] = function()
		local seenGrant = {}

		for _, p in ipairs(pathsOf(k)) do
			if not seenGrant[p.grant] then
				seenGrant[p.grant] = true
				H.reset()
				costs()

				local rec = spyAllQuests()
				local player = trainee(k)
				local choices = { DS.TRAINING[k].sid }

				for _, reply in ipairs(p.replies) do choices[#choices + 1] = reply end

				local transcript = converse(player, choices)

				lu.assertEquals(ids(transcript)[1], "ready_train", p.grant .. ": first screen")
				lu.assertEquals(ids(transcript)[2], "mission" .. k .. "_brief", p.grant .. ": the screen after the click")
				lu.assertEquals(transcript[#transcript].id, p.grant, p.grant .. ": last screen; got " .. table.concat(ids(transcript), ","))
				lu.assertEquals(rec.starts, { D.global(D.MISSION[k].main) }, p.grant .. ": quests started")
				lu.assertEquals(rec.rewards, {}, p.grant .. ": rewards paid")
			end
		end
	end

	-- AC-6: a pilot who stops at any non-grant screen of the subtree keeps the ready flag, nothing is started, paid or marked attempted, and the next talk starts on ready_mission and leads to the same brief
	TestF6bEveryRoute["test_stopping_at_any_non_grant_screen_of_mission_" .. k .. "_keeps_the_ready_flag_and_the_next_talk_starts_on_ready_mission_with_the_same_brief"] = function()
		local reach = reachPaths(k)
		local n = 0

		for _, id in ipairs(sortedKeys(reach)) do
			H.reset()

			local rec = spyAllQuests()
			local player = missionPilot(k, { ready = true })
			local choices = { "s_39e697de" }

			for _, reply in ipairs(reach[id]) do choices[#choices + 1] = reply end

			local transcript = converse(player, choices)

			lu.assertEquals(transcript[#transcript].id, id, "mission " .. k .. " walk to " .. id .. "; got " .. table.concat(ids(transcript), ","))
			lu.assertEquals(rec.starts, {}, id .. ": quests started while only reading")
			lu.assertEquals(rec.rewards, {}, id .. ": rewards paid while only reading")
			lu.assertEquals(H.getQuestStatus(player, D.READY_SUFFIX), "1", id .. ": the ready flag stays set")
			lu.assertNil(H.getQuestStatus(player, D.MISSION[k].statusName .. ":attempted"), id .. ": :attempted before a grant screen")

			local again = converse(player, { "s_39e697de" })

			lu.assertEquals(ids(again), { "ready_mission", "mission" .. k .. "_brief" }, id .. ": the next talk")
			n = n + 1
		end

		lu.assertEquals(n, ({ 15, 16, 17, 7 })[k], "non-grant screens reached in mission " .. k)
	end

	-- AC-6: the transcripts of every screen of the subtree resolve in the client (the texts of the screens shown on the first path to each)
	TestF6bEveryRoute["test_every_non_grant_screen_of_mission_" .. k .. "_is_shown_with_options_the_client_can_resolve"] = function()
		local reach = reachPaths(k)

		for _, id in ipairs(sortedKeys(reach)) do
			H.reset()

			local player = missionPilot(k, { ready = true })
			local choices = { "s_39e697de" }

			for _, reply in ipairs(reach[id]) do choices[#choices + 1] = reply end

			local transcript = converse(player, choices)

			lu.assertEquals(transcript[#transcript].id, id, "walk to " .. id)
			lu.assertTrue(#transcript[#transcript].options >= 1, id .. ": options offered")
			noUnresolved(transcript, "walk to " .. id)
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: nothing else moves, LF
---------------------------------------------------------------------------------------------

TestF6bNothingElseMoves = {}

function TestF6bNothingElseMoves:setUp() H.reset() end

-- AC-7: IC equals the base with exactly the two ranges replaced: the 9 brief option lines in place and base lines 325-1072 by the 446 lines of the 62 blocks
function TestF6bNothingElseMoves:test_imler_convo_equals_the_base_with_exactly_the_two_ranges_replaced()
	local now, old = linesOf(readFile(IC)), linesOf(baseFile(IC))
	local want = {}
	local brief = {}

	for _, entry in ipairs(FB.BRIEF_LINES) do
		local o = FB.BRIEF_OPTIONS[entry[2]][entry[3]]

		brief[entry[1]] = FB.optionLine(o[1], o[2], FB.TEXT[o[1]])
	end

	lu.assertEquals(#old, FB.BASE_LINES, "number of lines of imler_convo.lua at the base " .. BASE)

	for i = 1, FB.REPLACED.blockFrom - 1 do want[#want + 1] = brief[i] or old[i] end

	for _, row in ipairs(FB.SCREENS) do
		for _, line in ipairs(FB.blockLines(row)) do want[#want + 1] = line end
	end

	for i = FB.REPLACED.blockTo + 1, #old do want[#want + 1] = old[i] end

	lu.assertEquals(#want, FB.AC_LINES, "number of lines of the expected imler_convo.lua")
	lu.assertEquals(#now, FB.AC_LINES, "number of lines of imler_convo.lua")

	for i = 1, math.max(#now, #want) do
		lu.assertEquals(now[i], want[i], "imler_convo.lua line " .. i .. " (base " .. BASE .. " with the 9 brief option lines and lines 325-1072 replaced)")
	end
end

-- AC-7: the base ranges are what the spec says (the brief option lines and the block of 98 screens from s_455 to mission1_accept_c)
function TestF6bNothingElseMoves:test_the_replaced_base_ranges_are_the_9_nge_brief_options_and_the_98_subtree_blocks()
	local old = linesOf(baseFile(IC))

	for _, entry in ipairs(FB.BRIEF_LINES) do
		lu.assertNotNil(old[entry[1]]:find('^\t\t{"' .. P:gsub("%p", "%%%0") .. 's_%d+", "s_%d+"},$'), "base line " .. entry[1] .. " is an NGE brief option: " .. old[entry[1]])
	end

	lu.assertEquals(old[FB.REPLACED.blockFrom], "imler_convo_template:addScreen(ConvoScreen:new {", "base line 325")
	lu.assertEquals(old[FB.REPLACED.blockFrom + 1], '\tid = "s_455",', "base line 326")
	lu.assertEquals(old[FB.REPLACED.blockTo], "})", "base line 1072")
	lu.assertEquals(old[FB.REPLACED.blockTo - 5], '\tid = "mission1_accept_c",', "the last replaced block")
	lu.assertEquals(old[FB.REPLACED.blockTo + 2], '\tid = "duty_destroy",', "the block after the replaced range")
end

-- AC-7: IH is byte-identical to the base (the F6a training code, canFlyNonTrackDuty with hasSpaceQuest, the ready-flag branch, startMission, payReward and routing)
function TestF6bNothingElseMoves:test_the_handler_is_byte_identical_to_the_base()
	local now, old = readFile(IH), baseFile(IH)

	lu.assertEquals(#linesOf(old), FB.IH_LINES, "number of lines of imlerConvoHandler.lua at the base")
	lu.assertEquals(#now, #old, "byte length of imlerConvoHandler.lua")

	local a, b = linesOf(now), linesOf(old)

	for i = 1, math.max(#a, #b) do
		lu.assertEquals(a[i], b[i], "imlerConvoHandler.lua line " .. i)
	end

	lu.assertTrue(now == old, "imlerConvoHandler.lua is the very text of " .. BASE)
end

-- AC-7: the pieces the spec names are there and untouched
function TestF6bNothingElseMoves:test_the_handler_keeps_can_fly_non_track_duty_train_choices_and_the_ready_flag_branch()
	local text = readFile(IH)

	local function block(source)
		local from = source:find("function imlerConvoHandler:canFlyNonTrackDuty(pPlayer)", 1, true)

		lu.assertNotNil(from, "canFlyNonTrackDuty is defined")

		return source:sub(from, select(2, source:find("\nend\n", from, true)))
	end

	lu.assertEquals(block(text), block(baseFile(IH)), "canFlyNonTrackDuty")
	lu.assertNotNil(block(text):find("not SpaceHelpers:hasSpaceQuest(pPlayer)", 1, true), "canFlyNonTrackDuty keeps the hasSpaceQuest term")
	lu.assertNotNil(text:find("imlerConvoHandler.TRAIN_CHOICES = {", 1, true), "TRAIN_CHOICES")
	lu.assertNotNil(text:find("function imlerConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)", 1, true), "getNextConversationScreen")
	lu.assertNotNil(text:find('string.match(screenID, "^mission%d_brief$")', 1, true), "the ready-flag branch on the briefs")
	lu.assertNotNil(text:find('"^mission(%d)_accept_"', 1, true), "the grant branch on mission<k>_accept_* screens")
	lu.assertEquals(handler().TRAIN_SCREENS, nil, "TRAIN_SCREENS stays gone")
end

-- AC-7: both files are LF on every line, including the last
function TestF6bNothingElseMoves:test_both_files_are_lf_on_every_line_including_the_last()
	for _, rel in ipairs(SOURCES) do
		local text = readFile(rel)

		lu.assertNil(text:find("\r", 1, true), rel .. ": contains a CR byte")
		lu.assertEquals(text:sub(-1), "\n", rel .. ": the final line keeps its LF")
		lu.assertEquals(baseFile(rel):sub(-1), "\n", rel .. ": the base ends with LF too")
	end
end

-- AC-7: the template name, handler, initial screen and type are unchanged
function TestF6bNothingElseMoves:test_the_template_keeps_its_name_handler_initial_screen_and_type()
	local _, t = screens()

	lu.assertEquals(t.luaClassHandler, "imlerConvoHandler", "luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.initialScreen, "", "initialScreen")
	lu.assertNotNil(readFile(IC):find('addConversationTemplate("imler_convo_template", imler_convo_template)', 1, true), "the addConversationTemplate line")
end

---------------------------------------------------------------------------------------------
-- AC-8: conformance outside the subtrees (the I4 graph stays the key there; the updated F6a tests compare it screen by screen)
---------------------------------------------------------------------------------------------

TestF6bConformance = {}

function TestF6bConformance:setUp() H.reset() end

-- AC-8 (E-IM2): no screen outside Appendix G and the briefs follows a link into the removed subtrees, and every brief link and grant path is an Appendix G screen
function TestF6bConformance:test_no_screen_links_to_a_removed_subtree_screen_and_every_link_of_appendix_g_is_a_screen()
	local byId, t = screens()
	local removed = {}

	for _, id in ipairs(FB.REMOVED) do removed[id] = true end

	for _, s in ipairs(t.screens) do
		for i, o in ipairs(s.options or {}) do
			lu.assertNil(removed[o[2]], "screen '" .. s.id .. "' option " .. i .. " links to the removed screen " .. o[2])
			lu.assertNotNil(byId[o[2]], "screen '" .. s.id .. "' option " .. i .. ": link " .. tostring(o[2]) .. " is a screen")
		end
	end
end

-- AC-8: the screens outside the subtrees keep their base ids; the subtree ids of the java have no screen
function TestF6bConformance:test_the_ids_of_the_java_that_are_not_in_the_subtrees_keep_a_screen_and_the_196_have_none()
	local byId = screens()

	for _, id in ipairs(DS.REMAINING) do
		lu.assertNil(byId[id], "the NGE id " .. id .. " must not be a screen id")
	end

	for _, id in ipairs({ "intro", "duty_info", "duty_info_end", "ready_mission", "ready_train", "mission1_reward", "mission4_failed", "mission3_retry_b", "no_master", "here_for_work" }) do
		lu.assertNotNil(byId[id], "screen " .. id .. " outside the subtrees")
	end
end
