-- Talon Karrde after Beissa's tier 3: the K2 hub (tier 3 done -> the Trade Outpost on Dathomir).
-- Spec: .claude/work/smuggler-tier3-beissa/01-spec.md (AC-10 Karrde half; Content contract 5; Conversation flow 6; Appendix C; D-14; KS F-2).
--
-- Karrde's gate order (smuggler-transition-karrde K) gains K2: the four tier 3 skills (SWG doneWithTier3, `SpaceHelpers:hasCompletedPilotTier(p, "neutral", 3)`)
-- sit directly after the not-member gate (K1) and before the tier 2 series gate (K3). No action, no option editing. K9 (tier 4 done) stays deferred.
-- The builder is smuggler_tier3_data.lua B.pilot (t3 = the tier 3 skills held, as TRAIN indexes).

local lu = require("luaunit")
local H = require("harness")
local B = require("smuggler_tier3_data")
local T = require("smuggler_transition_data")
local CS = require("harness.client_strings")
local TEXT = require("smuggler_transition_client_text")
local Swgjava = require("harness.swgjava")

B.load()

local ALL = { 1, 2, 3, 4 }

local function setUp()
	H.reset()
	T.requireConversationLoaded()
end

local function karrde(player) return B.karrdeTalk(player)[1].id end

local function template() return H.conversationTemplateTable(T.TEMPLATE) end

local function readFile(path)
	local f = assert(io.open(H.SCRIPTS .. path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

TestSmugglerT3Karrde = {}

TestSmugglerT3Karrde.setUp = setUp

-- AC-10, K2
function TestSmugglerT3Karrde:test_a_tier_3_graduate_opens_tier3_done()
	lu.assertEquals(karrde(B.pilot({ t3 = ALL, paid = ALL, pilotTier = 4 })), "tier3_done", "four tier 3 skills, four missions paid, pilot tier 4")
	lu.assertEquals(karrde(B.pilot({ t3 = ALL, paid = ALL })), "tier3_done", "the same at pilot tier 3")
end

-- AC-10, D-14: the condition is the four skills alone (SWG doneWithTier3), whatever else the pilot holds
function TestSmugglerT3Karrde:test_the_four_skills_alone_open_tier3_done()
	lu.assertEquals(karrde(B.pilot({ t2 = false, t3 = ALL })), "tier3_done", "four tier 3 skills and nothing of tier 2")
	lu.assertEquals(karrde(B.pilot({ t3 = ALL })), "tier3_done", "four tier 3 skills, no tier 3 mission state")
	lu.assertEquals(karrde(B.pilot({ t3 = ALL, trans = "attempted" })), "tier3_done", "a failed transition does not matter (K2 before K4)")
	lu.assertEquals(karrde(B.pilot({ t3 = ALL, trans = "won", rewarded = false })), "tier3_done", "an unpaid transition does not matter (K2 before K6)")
end

-- AC-10: three tier 3 skills do not open K2; a tier 2 graduate still sees K3
function TestSmugglerT3Karrde:test_three_tier_3_skills_do_not_open_tier3_done()
	for i = 1, 4 do
		local have = {}

		for k = 1, 4 do
			if k ~= i then
				have[#have + 1] = k
			end
		end

		H.reset()
		lu.assertEquals(karrde(B.pilot({ t3 = have })), "series_done", "skill " .. B.TRAIN[i].x .. " missing: a tier 2 graduate gets K3")
	end

	H.reset()
	lu.assertEquals(karrde(B.pilot({ t3 = {} })), "series_done", "no tier 3 skill")
end

-- AC-10: K2 is above K3 (a tier 3 graduate does not get series_done)
function TestSmugglerT3Karrde:test_k2_is_above_the_tier_2_series_gate()
	local player = B.pilot({ t3 = ALL, paid = ALL })

	lu.assertTrue(SmugglerSquadronScreenplay:hasCompletedTier2Series(player), "precondition: the tier 2 series is complete too")
	lu.assertEquals(karrde(player), "tier3_done", "K2 before K3")
end

-- AC-10: K2 is below K1 (membership, JTL)
function TestSmugglerT3Karrde:test_k2_is_below_the_membership_gate()
	lu.assertEquals(karrde(B.pilot({ t3 = ALL, squadron = CORSEC_SQUADRON })), "not_member", "a CorSec pilot with the skills: K1 before K2")
	lu.assertEquals(karrde(B.pilot({ t3 = ALL, squadron = RSF_SQUADRON })), "not_member", "an RSF pilot with the skills")
	lu.assertEquals(karrde(B.pilot({ t3 = ALL, squadron = false })), "not_member", "a squadronless pilot with the skills")

	H.Engine.config.jtlEnabled = false
	lu.assertEquals(karrde(B.pilot({ t3 = ALL })), "not_member", "JTL disabled: K1 before K2")
end

-- AC-10: the old gates stand for a pilot below tier 3
function TestSmugglerT3Karrde:test_below_tier_3_the_old_gates_stand()
	lu.assertEquals(karrde(B.pilot({ t3 = { 1 } })), "series_done", "one tier 3 skill: K3")
	lu.assertEquals(karrde(B.pilot({ t2 = false, trans = "won", rewarded = true })), "low_profile", "a pilot between the tiers: K10")
end

-- AC-10: the whole K2 walk ends on see_nirame, and K2 changes nothing
function TestSmugglerT3Karrde:test_the_walk_ends_on_see_nirame_and_changes_nothing()
	local player = B.pilot({ t3 = ALL, paid = ALL, pilotTier = 4 })
	local before = B.snapshot(player)
	local t = B.karrdeTalk(player, { "s_1c8bddbb", "s_800d8ca1", "s_a89cdefd", "s_415dfb0e", "s_e8ed6f9a" })

	lu.assertEquals(B.ids(t), { "tier3_done", "dathomir_contact", "nirame_who", "nym_hyperspace", "branching_out", "see_nirame" }, "walk")
	lu.assertTrue(t[6].stop, "see_nirame ends the conversation")

	for i, row in ipairs(B.KARRDE_K2) do
		local want = {}

		for k, o in ipairs(row.options) do
			want[k] = o[1]
		end

		lu.assertEquals(B.optionSids(t[i]), want, row.id .. " replies")
		lu.assertEquals(t[i].text, T.PREFIX .. row.sid, row.id .. " line")
	end

	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(B.snapshot(player), before, "Karrde's K2 changes nothing: no action, no tier change, no quest")
end

-- AC-10, I-9: the K2 gate is pure
function TestSmugglerT3Karrde:test_the_first_screen_is_pure()
	local player = B.pilot({ t3 = ALL, paid = ALL })
	local before = B.snapshot(player)
	local screen = rawget(_G, T.HANDLER):getInitialScreen(player, T.npc(), H.conversationTemplate(T.TEMPLATE))

	lu.assertEquals(LuaConversationScreen(screen):getScreenID(), "tier3_done", "first screen")
	lu.assertEquals(B.snapshot(player), before, "state after getInitialScreen")
end

---------------------------------------------------------------------------------------------
-- The six screens (Appendix C)
---------------------------------------------------------------------------------------------

TestSmugglerT3KarrdeTemplate = {}

TestSmugglerT3KarrdeTemplate.setUp = setUp

-- AC-10: Karrde's six new screens match Appendix C, in order between not_member_work and series_done
function TestSmugglerT3KarrdeTemplate:test_the_six_k2_screens_match_appendix_c()
	local byId, order = {}, {}

	for i, s in ipairs(template().screens) do
		byId[s.id] = byId[s.id] or s
		order[s.id] = i
	end

	for _, row in ipairs(B.KARRDE_K2) do
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

	lu.assertEquals(order.tier3_done, order.not_member_work + 1, "tier3_done follows not_member_work")
	lu.assertEquals(order.dathomir_contact, order.tier3_done + 1, "dathomir_contact follows tier3_done")
	lu.assertEquals(order.nirame_who, order.dathomir_contact + 1, "nirame_who follows dathomir_contact")
	lu.assertEquals(order.nym_hyperspace, order.nirame_who + 1, "nym_hyperspace follows nirame_who")
	lu.assertEquals(order.branching_out, order.nym_hyperspace + 1, "branching_out follows nym_hyperspace")
	lu.assertEquals(order.see_nirame, order.branching_out + 1, "see_nirame follows branching_out")
	lu.assertTrue(order.series_done > order.see_nirame, "series_done comes after the K2 screens")
	lu.assertEquals(#template().screens, 31, T.TEMPLATE .. ": screens (25 + 6)")
	lu.assertEquals(H.conversationProblems(T.TEMPLATE), {}, T.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- AC-10: K2 agrees with K (K:178-200, 435-597): the lines and replies of the SWG script
function TestSmugglerT3KarrdeTemplate:test_the_k2_screens_agree_with_the_swg_script()
	local graph = Swgjava.read(H.FIXTURES .. "script/conversation/tatooine_privateer_trainer_2.java")

	for _, row in ipairs(B.KARRDE_K2) do
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

-- AC-10: the client text of the six lines and their replies (the trailing comments)
function TestSmugglerT3KarrdeTemplate:test_the_k2_lines_carry_the_client_text_as_trailing_comments()
	local source = readFile(T.TEMPLATE_FILE)

	for _, row in ipairs(B.KARRDE_K2) do
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

-- AC-10: the handler gate sits directly after the not-member gate and before the tier 2 series gate
function TestSmugglerT3KarrdeTemplate:test_the_gate_sits_between_the_not_member_gate_and_the_tier_2_series_gate()
	local text = readFile(T.HANDLER_FILE)
	local notMember = text:find('getScreen("not_member")', 1, true)
	local gate = text:find('hasCompletedPilotTier(pPlayer, "neutral", 3)', 1, true)
	local series = text:find("hasCompletedTier2Series", 1, true)

	lu.assertTrue(notMember ~= nil and gate ~= nil and series ~= nil, "the three markers are in talonKarrdeConvoHandler.lua")
	lu.assertTrue(notMember < gate and gate < series, "K2 between K1 and K3")
	lu.assertNotNil(text:find('getScreen("tier3_done")', 1, true), "the gate returns tier3_done")
	lu.assertNotNil(text:find("-- Tier 3 complete (the four tier 3 skills; SWG doneWithTier3)", 1, true), "the gate comment")
end

-- AC-10: K9 stays deferred: Karrde's sources do not use s_2d0c7400 (tier 4)
function TestSmugglerT3KarrdeTemplate:test_the_tier_4_line_stays_deferred()
	lu.assertNil(readFile(T.TEMPLATE_FILE):find("s_2d0c7400", 1, true), "talon_karrde_convo.lua must not use s_2d0c7400 (K9)")
	lu.assertNil(readFile(T.HANDLER_FILE):find("s_2d0c7400", 1, true), "talonKarrdeConvoHandler.lua must not use s_2d0c7400 (K9)")
end
