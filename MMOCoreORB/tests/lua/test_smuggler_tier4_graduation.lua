-- Smuggler tier 4: the graduation, end to end (Nirame's transfer, Admiral Burke's Smuggler branch, Grand Admiral Declann's refusal) and Karrde's last hub line K9.
-- Spec: .claude/work/smuggler-tier4-nirame/01-spec.md (AC-11; Conversation flow 5; Content contract 5; Appendix C; D-2, D-17, D-19; PS findings 2-3).
--
-- A Nirame graduate (Smuggler squadron, neutral pilot, the four _04 skills, pilot tier 5, no key) is driven through the REAL handlers of the master trainers
-- (master_trainer_privateer_data.lua loads both admirals and their templates). Nirame sets no key for Burke: the Smuggler branch of Burke reads skills only.
-- Karrde's K9 (SWG doneWithTier4, K:379) sits directly after the not-member gate and above K2.

local lu = require("luaunit")
local H = require("harness")
local P = require("master_trainer_privateer_data")
local N = require("smuggler_tier4_data")
local T = require("smuggler_transition_data")
local CS = require("harness.client_strings")
local TEXT = require("smuggler_transition_client_text")
local Swgjava = require("harness.swgjava")

P.load()
N.load()

local ALL = { 1, 2, 3, 4 }

local function graduate(extra)
	local o = { t4 = ALL, paid = ALL, met = true }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return N.pilot(o)
end

local function readFile(path)
	local f = assert(io.open(H.SCRIPTS .. path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function lines(text)
	local out = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		out[#out + 1] = l
	end

	return out
end

local function setUp()
	H.reset()
	N.requireConversation(lu)
	P.requireConversations(lu)
end

---------------------------------------------------------------------------------------------
-- Nirame's hand-off
---------------------------------------------------------------------------------------------

TestSmugglerT4Transfer = {}

TestSmugglerT4Transfer.setUp = setUp

-- AC-11, D-19: with all four missions paid, four _04 skills and no master skill every talk opens transfer, and both routes end on transfer_where
function TestSmugglerT4Transfer:test_every_talk_opens_transfer_and_both_routes_end_on_transfer_where()
	local player = graduate()
	local before = N.snapshot(player)

	for i = 1, 3 do
		lu.assertEquals(N.firstScreen(player), "transfer", "talk " .. i)
	end

	local who = N.talk(player, { "s_2313ac9e", "s_bbe3529b", "s_71d95498", "s_ac1da756", "s_f8674c23" })

	lu.assertEquals(N.ids(who), { "transfer", "transfer_news", "transfer_who", "transfer_join", "transfer_plans", "transfer_where" }, "route 1 (Who is he?)")
	lu.assertTrue(who[#who].stop, "transfer_where ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(who), {}, "client strings")
	lu.assertEquals(who[#who].params.TU, "Ace", "transfer_where carries the pilot's first name")

	local why = N.talk(player, { "s_2313ac9e", "s_8c39d757", "s_71d95498", "s_ac1da756", "s_f8674c23" })

	lu.assertEquals(N.ids(why), { "transfer", "transfer_news", "transfer_why", "transfer_join", "transfer_plans", "transfer_where" }, "route 2 (Why not?)")
	lu.assertEquals(CS.transcriptUnresolved(why), {}, "client strings")
	lu.assertEquals(N.snapshot(player), before, "the transfer dialogue sets nothing (no key, no skill, no quest)")
	lu.assertEquals(N.firstScreen(player), "transfer", "and the next talk is transfer again")
end

-- AC-11: the transfer screen names no key; Nirame's file holds no Burke or Declann key
function TestSmugglerT4Transfer:test_nirame_sets_no_key_for_burke_or_declann()
	local text = readFile(N.HANDLER_FILE)

	for _, word in ipairs({ "MASTER_MISSION", "DECLANN", "BURKE", "master_rebel", "master_imperial" }) do
		lu.assertNil(text:find(word, 1, true), "nirameSakuteConvoHandler.lua does not mention " .. word)
	end
end

-- AC-11: the master skill switches Nirame to here_for_work, and the duty menu there works
function TestSmugglerT4Transfer:test_with_the_master_skill_nirame_opens_here_for_work()
	local player = graduate({ master = true })

	for i = 1, 2 do
		lu.assertEquals(N.firstScreen(player), "here_for_work", "talk " .. i)
	end
end

---------------------------------------------------------------------------------------------
-- Burke and Declann
---------------------------------------------------------------------------------------------

TestSmugglerT4MasterTrainers = {}

TestSmugglerT4MasterTrainers.setUp = setUp

local function burke(player, choices) return P.talk("burke", player, choices) end
local function declann(player, choices) return P.talk("declann", player, choices) end

-- AC-11: the graduate opens Burke's Smuggler branch
function TestSmugglerT4MasterTrainers:test_a_nirame_graduate_opens_burkes_privateer_ready_smuggler()
	local t = burke(graduate())

	lu.assertEquals(P.ids(t), { "privateer_ready_smuggler" }, "screens shown")
	lu.assertFalse(t[1].stop, "waits for the reply")
	lu.assertEquals(#t[1].options, 1, "exactly one reply")
	lu.assertEquals(t[1].options[1].text, "@conversation/rebel_master_trainer:s_2acaca5d", "the Smuggler reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: the graduate needs nothing else: no key, any mission state, pilot tier 4 or 5
function TestSmugglerT4MasterTrainers:test_the_graduate_needs_no_key_and_burke_reads_no_pilot_tier()
	for _, o in ipairs({ { pilotTier = 4 }, { met = false }, { mission = { [4] = "paid" } }, { xp = 5000000 } }) do
		H.reset()
		lu.assertEquals(P.ids(burke(graduate(o)))[1], "privateer_ready_smuggler", "graduate with " .. tostring(next(o)))
	end
end

-- AC-11: with a Nirame duty active Burke opens on_quest
function TestSmugglerT4MasterTrainers:test_with_a_nirame_duty_active_burke_opens_on_quest()
	for _, duty in ipairs(N.DUTIES) do
		H.reset()

		-- a real start in a ship: the duty puts its mission into the datapad (Burke's gate reads the datapad, J space_quest.hasQuest)
		local q = N.quest(duty)

		q:start()

		local player = graduate({ zone = q.questZone, inShip = true })

		q:startQuest(player, "")
		H.advance(0)
		lu.assertTrue(SpaceHelpers:hasSpaceQuest(player), duty .. ": the running duty is a datapad quest")

		local t = burke(player)

		lu.assertEquals(P.ids(t), { "on_quest" }, duty .. " running")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	H.reset()
	lu.assertEquals(P.ids(burke(graduate({ datapad = "duty" })))[1], "on_quest", "a duty in the datapad")
end

-- AC-11: with three _04 skills Burke opens privateer_not_ready
function TestSmugglerT4MasterTrainers:test_with_three_tier_4_skills_burke_opens_privateer_not_ready()
	for i = 1, 4 do
		H.reset()

		local have = {}

		for k = 1, 4 do
			if k ~= i then
				have[#have + 1] = k
			end
		end

		local t = burke(N.pilot({ t4 = have, paid = { 1, 2, 3 }, met = true }))

		lu.assertEquals(P.ids(t), { "privateer_not_ready" }, "skill " .. N.TRAIN[i].x .. " missing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-11: Declann refuses the Smuggler in every case
function TestSmugglerT4MasterTrainers:test_declann_opens_smuggler_in_every_case()
	local cases = {
		{ "the graduate", graduate() },
		{ "a duty running", graduate({ duty4 = N.GLOBALS[13] }) },
		{ "three _04 skills", N.pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2, 3 }, met = true }) },
		{ "no _04 skill", N.pilot({ met = true }) },
		{ "the master skill", graduate({ master = true }) },
		{ "a datapad duty", graduate({ datapad = "duty" }) },
	}

	for _, c in ipairs(cases) do
		H.reset()

		local t = declann(c[2])

		lu.assertEquals(P.ids(t), { "smuggler" }, c[1])
		lu.assertTrue(t[1].stop, c[1] .. ": the refusal ends the conversation")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, c[1] .. ": client strings")
	end
end

-- AC-11 (end to end): Nirame's transfer, Burke's Smuggler walk to the first master mission, no key anywhere
function TestSmugglerT4MasterTrainers:test_the_whole_hand_off_walks_from_nirame_to_the_first_master_mission()
	local player = graduate()
	local spy = H.spyOn(H.expectGlobal("destroy_master_rebel_1", "the master mission 1 table (space-master-trainer-privateer)"), "startQuest")

	lu.assertEquals(N.firstScreen(player), "transfer", "Nirame sends the graduate away")

	local path
	for _, x in ipairs(P.PATHS) do
		if x.screen == "priv_m1_accept_smuggler" then
			path = x
		end
	end

	lu.assertNotNil(path, "Burke's Smuggler accept path")

	local t = burke(player, path.replies)

	lu.assertEquals(P.ids(t)[1], "privateer_ready_smuggler", "Burke's first screen")
	lu.assertEquals(P.ids(t)[#t], "priv_m1_accept_smuggler", "the Smuggler accepts the first master mission")
	lu.assertEquals(#spy, 1, "destroy_master_rebel_1:startQuest calls")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(H.getQuestStatus(player, "master_rebel_1:attempted"), "1", "master_rebel_1:attempted")
	lu.assertEquals(H.getQuestStatus(player, N.MET_SUFFIX), "1", "Nirame's met key is untouched")
end

---------------------------------------------------------------------------------------------
-- Karrde K9
---------------------------------------------------------------------------------------------

TestSmugglerT4Karrde = {}

function TestSmugglerT4Karrde:setUp()
	H.reset()
	T.requireConversationLoaded()
end

local function karrde(player, choices) return N.karrdeTalk(player, choices) end

-- AC-11, K9: a Smuggler with the four _04 skills opens tier4_done, which ends
function TestSmugglerT4Karrde:test_a_tier_4_graduate_opens_tier4_done_which_ends()
	local player = graduate()
	local before = N.snapshot(player)
	local t = karrde(player)

	lu.assertEquals(N.ids(t), { "tier4_done" }, "screens shown")
	lu.assertTrue(t[1].stop, "tier4_done ends the conversation")
	lu.assertEquals(#t[1].options, 0, "no reply")
	lu.assertEquals(t[1].text, T.PREFIX .. "s_2d0c7400", "the K9 line")
	lu.assertEquals(t[1].params.TU, "Ace", "%NU is filled with the first name")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(N.snapshot(player), before, "K9 changes nothing")
end

-- AC-11: the condition is the four _04 skills (SWG doneWithTier4), whatever else the pilot holds
function TestSmugglerT4Karrde:test_the_four_tier_4_skills_alone_open_tier4_done()
	lu.assertEquals(karrde(N.pilot({ t4 = ALL, t2 = false, t3 = {} }))[1].id, "tier4_done", "four _04 skills and nothing below")
	H.reset()
	lu.assertEquals(karrde(N.pilot({ t4 = ALL, master = true }))[1].id, "tier4_done", "with the master skill too")
	H.reset()
	lu.assertEquals(karrde(N.pilot({ t4 = ALL, pilotTier = 4 }))[1].id, "tier4_done", "at pilot tier 4")
end

-- AC-11: the _03 skills without all _04 ones keep tier3_done (K2 below K9)
function TestSmugglerT4Karrde:test_a_tier_3_graduate_without_all_tier_4_skills_opens_tier3_done()
	lu.assertEquals(karrde(N.pilot({}))[1].id, "tier3_done", "the four _03 skills")

	for _, have in ipairs({ { 1 }, { 1, 2 }, { 1, 2, 3 }, { 2, 3, 4 } }) do
		H.reset()
		lu.assertEquals(karrde(N.pilot({ t4 = have }))[1].id, "tier3_done", #have .. " _04 skills")
	end
end

-- AC-11: K1 (membership, JTL) is above K9
function TestSmugglerT4Karrde:test_a_pilot_who_is_not_a_smuggler_opens_not_member_whatever_he_holds()
	lu.assertEquals(karrde(graduate({ squadron = CORSEC_SQUADRON }))[1].id, "not_member", "a CorSec pilot with the _04 skills")
	H.reset()
	lu.assertEquals(karrde(graduate({ squadron = RSF_SQUADRON }))[1].id, "not_member", "an RSF pilot with the _04 skills")
	H.reset()
	lu.assertEquals(karrde(graduate({ squadron = false }))[1].id, "not_member", "a squadron-less pilot with the _04 skills")
	H.reset()
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(karrde(graduate())[1].id, "not_member", "JTL disabled")
end

-- AC-11: the gate is pure
function TestSmugglerT4Karrde:test_the_first_screen_is_pure()
	local player = graduate()
	local before = N.snapshot(player)
	local screen = rawget(_G, T.HANDLER):getInitialScreen(player, T.npc(), H.conversationTemplate(T.TEMPLATE))

	lu.assertEquals(LuaConversationScreen(screen):getScreenID(), "tier4_done", "first screen")
	lu.assertEquals(N.snapshot(player), before, "state after getInitialScreen")
end

-- AC-11, Appendix C: the screen row, its place in the template, its comment and the SWG script
function TestSmugglerT4Karrde:test_tier4_done_matches_appendix_c_and_sits_directly_before_tier3_done()
	local row = N.KARRDE_K9
	local order, byId = {}, {}

	for i, s in ipairs(H.conversationTemplateTable(T.TEMPLATE).screens) do
		byId[s.id] = byId[s.id] or s
		order[s.id] = i
	end

	local s = byId[row.id]

	lu.assertNotNil(s, T.TEMPLATE .. ": missing screen 'tier4_done'")
	lu.assertEquals(s.leftDialog, T.PREFIX .. row.sid, "leftDialog")
	lu.assertEquals(s.stopConversation, "true", "stopConversation")
	lu.assertEquals(s.animation or "", row.animation, "animation")
	lu.assertEquals(#s.options, 0, "options")
	lu.assertEquals(order.tier4_done, order.tier3_done - 1, "tier4_done is directly before tier3_done")
	lu.assertEquals(#H.conversationTemplateTable(T.TEMPLATE).screens, 32, T.TEMPLATE .. ": screens")
	lu.assertEquals(H.conversationProblems(T.TEMPLATE), {}, T.TEMPLATE .. ": dead links, duplicate or missing ids")

	local graph = Swgjava.read(H.FIXTURES .. "script/conversation/tatooine_privateer_trainer_2.java")
	local node = graph.nodes[row.sid]

	lu.assertNotNil(node, "the script has the NPC line " .. row.sid)
	lu.assertEquals(node.options, {}, "the script's replies")
	lu.assertTrue(node.isEnd, "the script ends on it")

	local java = N.readFile(H.FIXTURES .. "script/conversation/tatooine_privateer_trainer_2.java"):gsub("\r", "")

	lu.assertNotNil(java:find('doAnimationAction(self, "slow_down");\n            string_id message = new string_id(c_stringFile, "s_2d0c7400");', 1, true), "the script plays slow_down on that line (K:381)")

	local found = false

	for _, line in ipairs(lines(readFile(T.TEMPLATE_FILE))) do
		local comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_privateer_trainer_2:s_2d0c7400"%s*,?%s*%-%-%s*(.-)%s*$')

		if comment ~= nil then
			found = true
			lu.assertEquals(comment, (TEXT.s_2d0c7400:gsub("%s+$", "")), "trailing comment of s_2d0c7400")
		end
	end

	lu.assertTrue(found, "the leftDialog line of s_2d0c7400")
end

-- AC-11, Content contract 5: the gate sits directly after the not-member gate and above K2; the comment and the two header lines
function TestSmugglerT4Karrde:test_the_gate_the_comment_and_the_header_lines_equal_the_contract()
	local handler = readFile(T.HANDLER_FILE)
	local template = readFile(T.TEMPLATE_FILE)
	local notMember = handler:find('getScreen("not_member")', 1, true)
	local k9 = handler:find('hasCompletedPilotTier(pPlayer, "neutral", 4)', 1, true)
	local k2 = handler:find('hasCompletedPilotTier(pPlayer, "neutral", 3)', 1, true)
	local series = handler:find("hasCompletedTier2Series", 1, true)

	lu.assertTrue(notMember ~= nil and k9 ~= nil and k2 ~= nil and series ~= nil, "the four markers are in talonKarrdeConvoHandler.lua")
	lu.assertTrue(notMember < k9 and k9 < k2 and k2 < series, "K1 < K9 < K2 < K3")
	lu.assertNotNil(handler:find("-- Tier 4 complete (the four tier 4 skills; SWG doneWithTier4, K:379)", 1, true), "the gate comment")
	lu.assertNotNil(handler:find('if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 4)) then return convoTemplate:getScreen("tier4_done") end', 1, true), "the gate line")
	lu.assertNotNil(handler:find("-- Side-effect free; gates in SWG order, except tier 4 done, which sits above tier 3 done so that it can show (feature smuggler-tier4-nirame)", 1, true),
		"the gate-order comment")
	lu.assertNil(handler:find("the tier 2, 3 and 4 hub branches are ported with their tiers", 1, true), "the old gate-order comment is gone")

	lu.assertEquals(lines(template)[1], "-- Talon Karrde (Smuggler transition quest, tier 1 -> 2, and the tier 2/3/4 done hub) conversation screens; ported from SWG-Source tatooine_privateer_trainer_2 "
		.. "(STF conversation/tatooine_privateer_trainer_2). Handler: talonKarrdeConvoHandler.lua (features smuggler-transition-karrde, smuggler-tier2-shamdon, smuggler-tier3-beissa, "
		.. "smuggler-tier4-nirame).", "talon_karrde_convo.lua line 1")
	lu.assertEquals(lines(handler)[1], "-- Talon Karrde (Smuggler transition quest, tier 1 -> 2, and the tier 2/3/4 done hub) conversation handler; ported from SWG-Source tatooine_privateer_trainer_2.java "
		.. "(features smuggler-transition-karrde, smuggler-tier2-shamdon, smuggler-tier3-beissa, smuggler-tier4-nirame).", "talonKarrdeConvoHandler.lua line 1")
end

-- AC-11: Karrde uses all 53 client lines now; nothing is deferred
function TestSmugglerT4Karrde:test_karrde_uses_all_53_client_lines()
	local used = {}

	for _, lit in ipairs(CS.literals({ T.TEMPLATE_FILE, T.HANDLER_FILE })) do
		if lit.file == T.STF then
			used[lit.id] = true
		end
	end

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 53, "distinct tatooine_privateer_trainer_2 ids Karrde's sources use")
	lu.assertEquals(CS.unresolved({ T.TEMPLATE_FILE, T.HANDLER_FILE }), {}, "unresolved ids")
end
