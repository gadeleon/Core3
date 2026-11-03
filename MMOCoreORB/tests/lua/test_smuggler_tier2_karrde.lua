-- Talon Karrde after Shamdon's tier 2: the K3 hub (series done -> Beissa in Jabba's Palace).
-- Spec: .claude/work/smuggler-tier2-shamdon/01-spec.md (AC-10 Karrde half, AC-7 low_profile; Content contract 5; Conversation flow 7; Appendix C; D-12; KS F-1).
--
-- Karrde's gate order (smuggler-transition-karrde K) is unchanged except for K3: `SmugglerSquadronScreenplay:hasCompletedTier2Series` (the four tier 2 skills and
-- the four missions won, paid or not) sits directly after the not-member gate (K1) and before the failed-transition gate (K4). The builder is
-- smuggler_tier2_data.lua M.pilot (all4 = true: the four skills, missions 1-4 paid; missions = { [n] = "won" } leaves one unpaid).

local lu = require("luaunit")
local H = require("harness")
local M = require("smuggler_tier2_data")
local T = require("smuggler_transition_data")
local CS = require("harness.client_strings")
local TEXT = require("smuggler_transition_client_text")
local Swgjava = require("harness.swgjava")

M.load()

local function setUp()
	H.reset()
	T.requireConversationLoaded()
end

local function karrde(player) return M.karrdeTalk(player)[1].id end

local function template() return H.conversationTemplateTable(T.TEMPLATE) end

local function readFile(path)
	local f = assert(io.open(H.SCRIPTS .. path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

TestSmugglerT2Karrde = {}

TestSmugglerT2Karrde.setUp = setUp

-- AC-10, K3
function TestSmugglerT2Karrde:test_a_tier_2_graduate_opens_series_done()
	lu.assertEquals(karrde(M.pilot({ all4 = true })), "series_done", "four skills, four missions paid")
end

-- AC-10, D-12: won is enough (the series is complete before Shamdon pays the last reward)
function TestSmugglerT2Karrde:test_the_missions_need_to_be_won_not_paid()
	lu.assertEquals(karrde(M.pilot({ all4 = true, missions = { [1] = "won", [2] = "won", [3] = "won", [4] = "won" } })), "series_done", "four missions won and unpaid")
	lu.assertEquals(karrde(M.pilot({ all4 = true, missions = { [4] = "won" } })), "series_done", "mission 4 won and unpaid")
end

-- AC-10: the pilot tier is not read
function TestSmugglerT2Karrde:test_the_pilot_tier_is_not_read()
	for _, tier in ipairs({ 2, 3 }) do
		lu.assertEquals(karrde(M.pilot({ all4 = true, pilotTier = tier })), "series_done", "pilot tier " .. tier)
	end
end

-- AC-10: a pilot with the four skills but one mission not won does not see K3
function TestSmugglerT2Karrde:test_four_skills_with_one_mission_not_won_do_not_open_series_done()
	for n = 1, 4 do
		for _, state in ipairs({ "fresh", "attempted", "active" }) do
			lu.assertEquals(karrde(M.pilot({ all4 = true, missions = { [n] = state } })), "low_profile", "mission " .. n .. " " .. state)
		end
	end
end

-- AC-10: all four missions won but only three skills held
function TestSmugglerT2Karrde:test_four_missions_won_with_three_skills_do_not_open_series_done()
	for i = 1, 4 do
		local names = {}

		for k, t in ipairs(M.TRAIN) do
			if k ~= i then
				names[#names + 1] = t.x
			end
		end

		lu.assertEquals(karrde(M.pilot({ skills2 = names, missions = { [1] = "paid", [2] = "paid", [3] = "paid", [4] = "paid" } })), "low_profile", "skill " .. M.TRAIN[i].x .. " missing")
	end
end

-- AC-10: K3 is above K4 (a failed transition) and below K1 (membership)
function TestSmugglerT2Karrde:test_k3_is_above_the_failed_transition_gate_and_below_the_membership_gate()
	lu.assertEquals(karrde(M.pilot({ all4 = true, trans = "attempted" })), "series_done", "a graduate whose transition chain is not won: K3 before K4")
	lu.assertEquals(karrde(M.pilot({ all4 = true, trans = "won", rewarded = false })), "series_done", "a graduate whose transition reward is unpaid: K3 before K6")

	H.Engine.config.jtlEnabled = false
	lu.assertEquals(karrde(M.pilot({ all4 = true })), "not_member", "JTL disabled: K1 before K3")
	H.Engine.config.jtlEnabled = true
	lu.assertEquals(karrde(M.pilot({ all4 = true, squadron = CORSEC_SQUADRON })), "not_member", "CorSec pilot with the state: K1 before K3")
	lu.assertEquals(karrde(M.pilot({ all4 = true, squadron = false })), "not_member", "a squadronless pilot with the state: K1 before K3")
end

-- AC-7, Conversation flow 7: before the series is complete the old gates stand
function TestSmugglerT2Karrde:test_before_the_series_the_old_gates_stand()
	lu.assertEquals(karrde(M.pilot({ trans = "won", rewarded = false })), "trans_won", "won, undelivered: K6")
	lu.assertEquals(karrde(M.pilot({ trans = "won", rewarded = true })), "low_profile", "delivered: K10")
	lu.assertEquals(karrde(M.pilot({ trans = "attempted" })), "trans_failed", "failed: K4")
	lu.assertEquals(karrde(M.pilot({ trans = "none" })), "summons", "never asked: K8")
	lu.assertEquals(karrde(M.pilot({ trans = "active" })), "on_trans", "running: K7")
	lu.assertEquals(karrde(M.pilot({ tier = 3, trans = "none", rewarded = false })), "dravis_employee", "three tier 1 skills: K5")
end

-- AC-10: the whole walk
function TestSmugglerT2Karrde:test_the_walk_ends_on_see_beissa()
	local player = M.pilot({ all4 = true })
	local before = M.snapshot(player)
	local t = M.karrdeTalk(player, { "s_98893f74", "s_de9b68cd", "s_805cb6f3" })

	lu.assertEquals(M.ids(t), { "series_done", "jabba_wants_you", "jabba_respects", "see_beissa" }, "walk")
	lu.assertTrue(t[4].stop, "see_beissa ends the conversation")
	lu.assertEquals(M.optionSids(t[1]), { "s_98893f74" }, "series_done replies")
	lu.assertEquals(M.optionSids(t[2]), { "s_de9b68cd" }, "jabba_wants_you replies")
	lu.assertEquals(M.optionSids(t[3]), { "s_805cb6f3" }, "jabba_respects replies")
	lu.assertEquals(t[1].params.TU, "Ace", "the name token of series_done... is filled by the handler")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(M.snapshot(player), before, "Karrde's K3 changes nothing: no action, no tier change, no quest")
end

-- AC-10, I-9: the K3 gate is pure
function TestSmugglerT2Karrde:test_the_first_screen_is_pure()
	local player = M.pilot({ all4 = true })
	local before = M.snapshot(player)
	local screen = rawget(_G, T.HANDLER):getInitialScreen(player, T.npc(), H.conversationTemplate(T.TEMPLATE))

	lu.assertEquals(LuaConversationScreen(screen):getScreenID(), "series_done", "first screen")
	lu.assertEquals(M.snapshot(player), before, "state after getInitialScreen")
end

---------------------------------------------------------------------------------------------
-- The helper
---------------------------------------------------------------------------------------------

-- AC-1, AC-10: hasCompletedTier2Series is K's hasCompletedSeries (K:73-80): the tier 2 skills and the four quests complete
function TestSmugglerT2Karrde:test_hasCompletedTier2Series()
	local sq = M.squadron()

	lu.assertFalse(sq:hasCompletedTier2Series(nil), "nil player")
	lu.assertFalse(sq:hasCompletedTier2Series(M.pilot({})), "no tier 2 state")
	lu.assertTrue(sq:hasCompletedTier2Series(M.pilot({ all4 = true })), "complete")
	lu.assertTrue(sq:hasCompletedTier2Series(M.pilot({ all4 = true, missions = { [3] = "won" } })), "complete, unpaid")
	lu.assertFalse(sq:hasCompletedTier2Series(M.pilot({ tier2 = 3, missions = { [1] = "paid", [2] = "paid", [3] = "paid", [4] = "paid" } })), "three skills")

	for n = 1, 4 do
		lu.assertFalse(sq:hasCompletedTier2Series(M.pilot({ all4 = true, missions = { [n] = "attempted" } })), "mission " .. n .. " not won")
	end

	-- the journal decides, not the :attempted key: a won head without a key still counts
	local noKeys = M.pilot({ all4 = true })

	for n = 1, 4 do
		removeQuestStatus(noKeys.objectID .. M.STATUS_NAMES[n] .. ":attempted")
		removeQuestStatus(noKeys.objectID .. M.STATUS_NAMES[n] .. ":reward")
	end

	lu.assertTrue(sq:hasCompletedTier2Series(noKeys), "journal entries complete, no status keys")
end

---------------------------------------------------------------------------------------------
-- The four screens (Appendix C)
---------------------------------------------------------------------------------------------

TestSmugglerT2KarrdeTemplate = {}

TestSmugglerT2KarrdeTemplate.setUp = setUp

-- AC-10: Karrde's four new screens match Appendix C, in order after not_member_work
function TestSmugglerT2KarrdeTemplate:test_the_four_k3_screens_match_appendix_c()
	local byId = {}

	for _, s in ipairs(template().screens) do
		byId[s.id] = byId[s.id] or s
	end

	for _, row in ipairs(M.KARRDE_K3) do
		local s = byId[row.id]

		lu.assertNotNil(s, T.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, T.PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation, row.stop and "true" or "false", "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation")

		local got, want = {}, {}

		for i, o in ipairs(s.options) do
			got[i] = { o[1], o[2] }
		end

		for i, o in ipairs(row.options) do
			want[i] = { T.PREFIX .. o[1], o[2] }
		end

		lu.assertEquals(got, want, "screen '" .. row.id .. "': options")
	end

	local order = {}

	for i, s in ipairs(template().screens) do
		order[s.id] = i
	end

	lu.assertEquals(order.series_done, order.not_member_work + 1, "series_done follows not_member_work")
	lu.assertEquals(order.jabba_wants_you, order.series_done + 1, "jabba_wants_you follows series_done")
	lu.assertEquals(order.jabba_respects, order.jabba_wants_you + 1, "jabba_respects follows jabba_wants_you")
	lu.assertEquals(order.see_beissa, order.jabba_respects + 1, "see_beissa follows jabba_respects")
	lu.assertEquals(#template().screens, 25, T.TEMPLATE .. ": screens (21 + 4)")
	lu.assertEquals(H.conversationProblems(T.TEMPLATE), {}, T.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- AC-10: K3 agrees with K (K:205-236, 601-691): the lines, animations and links of the SWG script
function TestSmugglerT2KarrdeTemplate:test_the_k3_screens_agree_with_the_swg_script()
	local graph = Swgjava.read(H.FIXTURES .. "script/conversation/tatooine_privateer_trainer_2.java")

	-- K is generated with objvar branches; the node table still holds the lines and their replies
	for _, row in ipairs(M.KARRDE_K3) do
		local node = graph.nodes[row.sid]

		lu.assertNotNil(node, "the script has no NPC line " .. row.sid)

		local want = {}

		for i, o in ipairs(row.options) do
			want[i] = o[1]
		end

		lu.assertEquals(node.options, want, "screen '" .. row.id .. "': the replies of " .. row.sid)
		lu.assertEquals(node.isEnd, row.stop, "screen '" .. row.id .. "': ends iff the script does")
	end
end

-- AC-10: the client text of the four lines (the trailing comments)
function TestSmugglerT2KarrdeTemplate:test_the_k3_lines_carry_the_client_text_as_trailing_comments()
	local source = readFile(T.TEMPLATE_FILE)

	for _, row in ipairs(M.KARRDE_K3) do
		local found = false

		for line in (source .. "\n"):gmatch("([^\n]*)\n") do
			local comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_privateer_trainer_2:' .. row.sid .. '"%s*,?%s*%-%-%s*(.-)%s*$')

			if comment ~= nil then
				found = true
				lu.assertEquals(comment, (TEXT[row.sid]:gsub("%s+$", "")), "trailing comment of " .. row.sid)
			end
		end

		lu.assertTrue(found, "leftDialog line of " .. row.sid)

		for _, o in ipairs(row.options) do
			local ok = false

			for line in (source .. "\n"):gmatch("([^\n]*)\n") do
				local comment = line:match('{%s*"@conversation/tatooine_privateer_trainer_2:' .. o[1] .. '"%s*,%s*"[%w_]+"%s*}%s*,?%s*%-%-%s*(.-)%s*$')

				if comment ~= nil then
					ok = true
					lu.assertEquals(comment, (TEXT[o[1]]:gsub("%s+$", "")), "trailing comment of " .. o[1])
				end
			end

			lu.assertTrue(ok, "option line of " .. o[1])
		end
	end
end

-- AC-10: the handler gate sits directly after the not-member gate and before the failed-transition gate
function TestSmugglerT2KarrdeTemplate:test_the_gate_sits_between_the_not_member_gate_and_the_failed_transition_gate()
	local text = readFile(T.HANDLER_FILE)
	local notMember = text:find('getScreen("not_member")', 1, true)
	local gate = text:find("hasCompletedTier2Series", 1, true)
	local failed = text:find('getScreen("trans_failed")', 1, true)

	lu.assertTrue(notMember ~= nil and gate ~= nil and failed ~= nil, "the three markers are in talonKarrdeConvoHandler.lua")
	lu.assertTrue(notMember < gate and gate < failed, "K3 between K1 and K4")
	lu.assertNotNil(text:find('getScreen("series_done")', 1, true), "the gate returns series_done")
	lu.assertNotNil(text:find("-- Tier 2 series complete", 1, true), "the gate comment")
end
