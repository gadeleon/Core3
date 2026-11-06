-- Lt. Colonel Barlow: walking the interview, the five end screens and the two Barlow keys.
-- Spec: .claude/work/inquisition-tier3-barlow/01-spec.md (AC-6, AC-7, invariant I-5; Conversation flow 2 and 3; D-6; R-3).
--
-- Walks are driven through H.converse with reply sids. The shortest walks to the five ends are the test strategy hints (B.WALKS); the table-driven walk
-- takes every screen of Appendix A and the shortest path to it, computed over Appendix A (B.paths).

local lu = require("luaunit")
local H = require("harness")
local B = require("inquisition_tier3_barlow_data")
local CS = require("harness.client_strings")

B.load()

TestBarlowInterview = {}

function TestBarlowInterview:setUp()
	H.reset()
	B.requireConversation(lu)
end

local function endsIn(walk) return B.talk(B.pilot({ question = true }), walk) end

-- AC-6: the five shortest walks end on their screens, the keys flip there
function TestBarlowInterview:test_each_end_screen_is_reached_by_its_shortest_walk_and_ends_the_conversation()
	for _, endId in ipairs(B.END_SCREENS) do
		H.reset()

		local walk = B.WALKS[endId]
		local player = B.pilot({ question = true })
		local t = B.talk(player, walk)
		local row = B.screenRow(endId)

		lu.assertEquals(#t, #walk + 1, endId .. ": screens shown (the interview plus one per reply)")
		lu.assertEquals(t[1].id, "interview", endId .. ": first screen")
		lu.assertEquals(t[#t].id, endId, endId .. ": last screen")
		lu.assertTrue(t[#t].stop, endId .. " ends the conversation")
		lu.assertEquals(#t[#t].options, 0, endId .. " offers no reply")
		lu.assertEquals(t[#t].text, B.PREFIX .. row.sid, endId .. ": the line")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, endId .. ": client strings")
		lu.assertEquals(B.keys(player), { question = nil, spoke = "1" }, endId .. ": the question key is cleared and the spoke key set")
	end
end

-- AC-6, I-5: no earlier screen of a walk changed either key; both keys flip together on the end screen
function TestBarlowInterview:test_no_screen_before_the_end_changes_either_key()
	for _, endId in ipairs(B.END_SCREENS) do
		H.reset()

		local walk = B.WALKS[endId]
		local player = B.pilot({ question = true })
		local seen = {}

		-- hooks run between screens, so each one sees the state after the screen just shown
		local choices = {}

		for i, reply in ipairs(walk) do
			choices[#choices + 1] = function(p) seen[#seen + 1] = B.keys(p) end
			choices[#choices + 1] = reply
		end

		B.talk(player, choices)
		lu.assertEquals(#seen, #walk, endId .. ": one observation per non-end screen")

		for i, keys in ipairs(seen) do
			lu.assertEquals(keys, { question = "1", spoke = nil }, endId .. ": keys after screen " .. i)
		end
	end
end

-- AC-6, I-5, D-6: the end action removes first, then sets, in J3B order, and nothing else is written
function TestBarlowInterview:test_the_end_screen_removes_the_question_key_then_sets_the_spoke_key_and_writes_nothing_else()
	for _, endId in ipairs(B.END_SCREENS) do
		H.reset()

		local player = B.pilot({ question = true })
		local log, restore = B.spyWrites()
		local ok, err = pcall(B.talk, player, B.WALKS[endId])

		restore()
		lu.assertTrue(ok, tostring(err))
		lu.assertEquals(log, {
			{ "remove", player.objectID .. B.QUESTION_SUFFIX },
			{ "set", player.objectID .. B.SPOKE_SUFFIX, "1" },
		}, endId .. ": quest status writes during the whole walk")
	end
end

-- AC-6: the next talk opens already_spoke
function TestBarlowInterview:test_after_the_interview_the_next_talk_opens_already_spoke()
	for _, endId in ipairs(B.END_SCREENS) do
		H.reset()

		local player = B.pilot({ question = true })

		B.talk(player, B.WALKS[endId])
		lu.assertEquals(B.ids(B.talk(player)), { "already_spoke" }, endId .. ": the next talk")
	end
end

-- AC-6: ending is unconditional, so a pilot who somehow lost the question key mid-walk still ends with the spoke key set
function TestBarlowInterview:test_the_end_screens_set_the_spoke_key_even_if_the_question_key_is_already_gone()
	local player = B.pilot({ question = true })
	local t = B.talk(player, {
		"s_40f102e4", "s_28a49383", "s_15fccf52", "s_6f94037e", "s_35f73adf", "s_c3185891", "s_45ebf891",
		function(p) removeQuestStatus(p.objectID .. B.QUESTION_SUFFIX) end,
		"s_ea32ea5a",
	})

	lu.assertEquals(t[#t].id, "end_2b71207d", "last screen")
	lu.assertEquals(B.keys(player), { question = nil, spoke = "1" }, "keys")
end

-- AC-7: stopping after any non-end interview screen leaves both keys, and the next talk restarts the interview
function TestBarlowInterview:test_walking_away_from_any_interview_screen_keeps_both_keys_and_the_next_talk_reopens_the_interview()
	local paths, order = B.paths()
	local checked = 0

	for _, id in ipairs(order) do
		if not B.isEnd(id) then
			H.reset()

			local player = B.pilot({ question = true })
			local t = B.talk(player, paths[id])

			lu.assertEquals(t[#t].id, id, id .. ": the walk's last screen")
			lu.assertEquals(B.keys(player), { question = "1", spoke = nil }, id .. ": keys after walking away")
			lu.assertEquals(B.ids(B.talk(player)), { "interview" }, id .. ": the next talk reopens the interview")
			checked = checked + 1
		end
	end

	lu.assertEquals(checked, 74, "interview screens that do not end (79 reachable from the interview less the five ends)")
end

-- AC-6, I-5: every screen reachable from the interview is reached by its shortest walk, stays inside the template and writes only on the end screens
function TestBarlowInterview:test_every_screen_of_appendix_a_is_reached_by_its_shortest_walk_and_only_the_ends_write()
	local paths, order = B.paths()

	lu.assertEquals(#order, 79, "screens reachable from the interview in Appendix A")

	for _, id in ipairs(order) do
		H.reset()

		local player = B.pilot({ question = true })
		local log, restore = B.spyWrites()
		local ok, t = pcall(B.talk, player, paths[id])

		restore()
		lu.assertTrue(ok, id .. ": " .. tostring(t))
		lu.assertEquals(t[#t].id, id, id .. ": the walk's last screen")
		lu.assertEquals(t[#t].text, B.PREFIX .. B.screenRow(id).sid, id .. ": the line")
		lu.assertEquals(t[#t].stop, B.screenRow(id).stop, id .. ": stop")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, id .. ": client strings")
		lu.assertEquals(#log, B.isEnd(id) and 2 or 0, id .. ": quest status writes")
	end
end

-- AC-6: each screen shows exactly the replies of its row
function TestBarlowInterview:test_each_interview_screen_offers_the_replies_of_its_row_in_order()
	local paths, order = B.paths()

	for _, id in ipairs(order) do
		H.reset()

		local t = B.talk(B.pilot({ question = true }), paths[id])
		local got, want = {}, {}

		for i, o in ipairs(t[#t].options) do
			got[i] = { o.text, o.link }
		end

		for i, o in ipairs(B.screenRow(id).options) do
			want[i] = { B.PREFIX .. o[1], o[2] }
		end

		lu.assertEquals(got, want, id .. ": replies shown")
	end
end

-- AC-6 (walk length): the shortest walks have 8, 9, 11, 11 and 11 replies
function TestBarlowInterview:test_the_shortest_walks_have_the_lengths_the_spec_names()
	local paths = B.paths()

	lu.assertEquals(#paths.end_2b71207d, 8, "end_2b71207d")
	lu.assertEquals(#paths.end_7ebbd888, 9, "end_7ebbd888")
	lu.assertEquals(#paths.end_65ec117a, 11, "end_65ec117a")
	lu.assertEquals(#paths.end_3be36a24, 11, "end_3be36a24")
	lu.assertEquals(#paths.end_4ccd5b75, 11, "end_4ccd5b75")
	lu.assertEquals(paths.end_2b71207d, B.WALKS.end_2b71207d, "the hint walk to end_2b71207d is the BFS walk")
	lu.assertEquals(paths.end_7ebbd888, B.WALKS.end_7ebbd888, "the hint walk to end_7ebbd888 is the BFS walk")
end

-- AC-7: the handler hands a nil player or screen straight back
function TestBarlowInterview:test_run_screen_handlers_returns_nil_without_a_player_or_a_screen()
	local handler = rawget(_G, B.HANDLER)
	local tmpl = H.conversationTemplate(B.TEMPLATE)
	local screen = LuaConversationTemplate(tmpl):getScreen("end_65ec117a")

	lu.assertNotNil(screen, "the end_65ec117a screen")
	lu.assertNil(handler:runScreenHandlers(tmpl, nil, B.npc(), 0, screen), "no player")
	lu.assertNil(handler:runScreenHandlers(tmpl, B.pilot({ question = true }), B.npc(), 0, nil), "no screen")
end

-- Content contract 2: runScreenHandlers on a non-end screen returns the screen and changes nothing
function TestBarlowInterview:test_run_screen_handlers_on_a_non_end_screen_changes_nothing()
	local handler = rawget(_G, B.HANDLER)
	local tmpl = H.conversationTemplate(B.TEMPLATE)
	local player = B.pilot({ question = true })
	local screen = LuaConversationTemplate(tmpl):getScreen("interview_d8cce866")
	local log, restore = B.spyWrites()
	local out = handler:runScreenHandlers(tmpl, player, B.npc(), 0, screen)

	restore()
	lu.assertNotNil(out, "a screen comes back")
	lu.assertEquals(out.id, "interview_d8cce866", "the same screen")
	lu.assertEquals(log, {}, "quest status writes")
	lu.assertEquals(B.keys(player), { question = "1", spoke = nil }, "keys")
end

return nil
