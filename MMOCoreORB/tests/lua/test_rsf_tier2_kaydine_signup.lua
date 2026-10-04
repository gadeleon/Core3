-- Captain Kaydine (RSF tier 2): the first-meeting sign-up dialog (SWG naboo_privateer_trainer_2.java:195-199, 401-744, 3965-4000).
-- Spec: .claude/work/rsf-tier2-kaydine-signup/01-spec.md (AC-1 .. AC-9; invariants I-1 .. I-4; D-2, D-5, D-8, D-9).
--
-- Answer key: rsf_tier2_kaydine_signup_data.lua (the spec's Appendix A), the SWG java fixture parsed by harness/swgjava.lua and the client string
-- id fixture fixtures/string/en/conversation/naboo_privateer_trainer_2.sids (generated read-only from /tre/patch_12_00.tre, spec Appendix B).
-- The pilots come from S.pilot: an RSF tier 2 pilot with the four tier 1 skills, no tier 2 progress and NO StartedKaydine key (the shared
-- trainer-fixes data seeds the key for every Kaydine test pilot, spec R-3; S.pilot removes it).
-- Quest starts, rewards and skill grants are observed through recorders (G.spies); the harness never runs a mission here.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local G = require("rsf_gate_screens_data")
local S = require("rsf_tier2_kaydine_signup_data")
local P = require("pilot_training_free_choice_data")
local Swgjava = require("harness.swgjava")

T.load()

local tr = T.TRAINERS.kaydine
local KJAVA = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_trainer_2.java")

local function npc() return H.newNpc({ name = "Kaydine" }) end

-- A reply the screen does not offer (the sign-up is missing) is a clean failure, not an error of the test
local function converse(player, choices)
	local ok, result = pcall(H.converse, { template = S.TEMPLATE, player = player, npc = npc(), choices = choices })

	if not ok then
		lu.fail("the conversation could not follow the replies " .. table.concat(choices or {}, ", ") .. ": " .. tostring(result))
	end

	return result
end

local function ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

local function sidOf(text) return text and text:match(":(s_[%w_]+)$") end

local function handler()
	local kh = H.expectGlobal("kaydineConvoHandler", "Kaydine conversation handler")

	lu.assertEquals(type(kh.isSignedUp), "function", "kaydineConvoHandler:isSignedUp must be defined (rsf-tier2-kaydine-signup, Content contract KH 2)")

	return kh
end

-- The first screen; it is never `fallthrough` unless `allowed` says so (AC-8: no other routing state reaches it)
local function first(player, allowed)
	local transcript = converse(player)

	lu.assertNotNil(transcript[1], "Kaydine shows a first screen")

	if allowed ~= "fallthrough" then
		lu.assertNotEquals(transcript[1].id, "fallthrough", "fallthrough is only for the ghost-less returns")
	end

	return transcript[1].id
end

local function template()
	local t = H.conversationTemplateTable(S.TEMPLATE)

	lu.assertNotNil(t, S.TEMPLATE .. " is not registered via addConversationTemplate")

	return t
end

local function screensById()
	local byId = {}

	for _, s in ipairs(template().screens) do
		byId[s.id] = s
	end

	return byId
end

local function shape(screen)
	local options = {}

	for i, o in ipairs(screen.options or {}) do
		options[i] = { o[1], o[2] }
	end

	return { leftDialog = screen.leftDialog, stopConversation = screen.stopConversation, animation = screen.animation, options = options }
end

local function expectedShape(row)
	local options = {}

	for i, o in ipairs(row.options) do
		options[i] = { S.PREFIX .. o[1], o[2] }
	end

	return {
		leftDialog = S.PREFIX .. row.sid,
		stopConversation = row.stop and "true" or "false",
		animation = row.animation ~= "" and row.animation or nil,
		options = options,
	}
end

local function readLines(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local lines = {}

	for line in f:lines() do
		lines[#lines + 1] = line
	end

	f:close()

	return lines
end

local function readFile(rel)
	local f = assert(io.open(H.SCRIPTS .. rel, "r"), "cannot open " .. rel)
	local text = f:read("a")

	f:close()

	return text
end

local function contains(list, value)
	for _, v in ipairs(list or {}) do
		if v == value then return true end
	end

	return false
end

local function keyOf(player) return player.objectID .. S.FLAG end

local function sidSet(list)
	local set = {}

	for _, sid in ipairs(list) do set[sid] = true end

	return set
end

---------------------------------------------------------------------------------------------
-- AC-1: the template
---------------------------------------------------------------------------------------------

TestSignupTemplate = {}

function TestSignupTemplate:setUp() H.reset() end

-- AC-1
function TestSignupTemplate:test_the_template_keeps_its_name_and_handler_and_has_89_screens()
	local t = template()

	lu.assertEquals(t.luaClassHandler, "kaydineConvoHandler", "kaydine_convo_template: luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "kaydine_convo_template: templateType")
	lu.assertEquals(#t.screens, S.SCREEN_COUNT, "kaydine_convo_template: number of screens (91 + the nine sign-up screens - the 11 deleted by space-convo-client-strings-kaydine)")
end

-- AC-1
function TestSignupTemplate:test_the_nine_screens_equal_appendix_a()
	local byId = screensById()

	for _, row in ipairs(S.ROWS) do
		lu.assertNotNil(byId[row.id], "kaydine_convo_template: missing screen '" .. row.id .. "'")
		lu.assertEquals(shape(byId[row.id]), expectedShape(row), "kaydine_convo_template: screen '" .. row.id .. "' (leftDialog, stopConversation, animation, options in order)")
	end
end

-- AC-1, I-2
function TestSignupTemplate:test_the_template_has_no_dead_links_or_duplicate_ids()
	template()
	lu.assertEquals(H.conversationProblems(S.TEMPLATE), {})
end

-- AC-1, I-2: one screen per distinct NPC line (D-6): the nine screens show nine different lines
function TestSignupTemplate:test_the_nine_screens_show_nine_different_lines()
	local byId, seen = screensById(), {}

	for _, row in ipairs(S.ROWS) do
		lu.assertNotNil(byId[row.id], "kaydine_convo_template: missing screen '" .. row.id .. "'")
		lu.assertNil(seen[byId[row.id].leftDialog], "screens '" .. tostring(seen[byId[row.id].leftDialog]) .. "' and '" .. row.id .. "' show the same line")
		seen[byId[row.id].leftDialog] = row.id
	end
end

---------------------------------------------------------------------------------------------
-- AC-9: conformance with the java and the client strings
---------------------------------------------------------------------------------------------

TestSignupConformance = {}

function TestSignupConformance:setUp() H.reset() end

-- AC-9 (fixture sanity: generated from /tre/patch_12_00.tre, 123 sids, sorted, Appendix B)
function TestSignupConformance:test_the_client_string_fixture_is_the_123_sorted_sids_of_the_stf()
	local lines = readLines(H.FIXTURES .. S.STF_SIDS)
	local sorted = {}

	for i, l in ipairs(lines) do sorted[i] = l end

	table.sort(sorted)

	lu.assertEquals(#lines, 123, S.STF_SIDS .. ": number of sids")
	lu.assertEquals(lines, sorted, S.STF_SIDS .. ": sorted (LC_ALL=C order of the generating command)")
	lu.assertTrue(contains(lines, "do_not_edit") and contains(lines, "s_0"), S.STF_SIDS .. ": holds do_not_edit and s_0")
end

-- AC-9, I-3: every string id the nine new screens use (lines and replies) is in the client string table
function TestSignupConformance:test_every_string_id_on_the_nine_screens_is_in_the_client_string_table()
	local inStf = sidSet(readLines(H.FIXTURES .. S.STF_SIDS))
	local byId = screensById()

	for _, row in ipairs(S.ROWS) do
		local screen = byId[row.id]

		lu.assertNotNil(screen, "kaydine_convo_template: missing screen '" .. row.id .. "'")

		local line = sidOf(screen.leftDialog)

		lu.assertTrue(line ~= nil and inStf[line] == true, "screen '" .. row.id .. "': NPC line " .. tostring(screen.leftDialog) .. " is not in the STF fixture")

		for _, o in ipairs(screen.options or {}) do
			local reply = sidOf(o[1])

			lu.assertTrue(reply ~= nil and inStf[reply] == true, "screen '" .. row.id .. "': reply " .. tostring(o[1]) .. " is not in the STF fixture")
		end
	end
end

-- AC-9, I-3: the answer key itself only uses sids the fixture holds (guards the spec table against a typo)
function TestSignupConformance:test_the_answer_key_sids_are_in_the_client_string_table_and_not_the_nge_only_ones()
	local inStf = sidSet(readLines(H.FIXTURES .. S.STF_SIDS))
	local nge = sidSet(S.NGE_ONLY)

	for _, row in ipairs(S.ROWS) do
		lu.assertTrue(inStf[row.sid], row.id .. ": " .. row.sid .. " in STF")

		for _, o in ipairs(row.options) do
			lu.assertTrue(inStf[o[1]], row.id .. ": " .. o[1] .. " in STF")
			lu.assertNil(nge[o[1]], row.id .. ": " .. o[1] .. " is NGE-only")
		end

		lu.assertNil(nge[row.sid], row.id .. ": " .. row.sid .. " is NGE-only")
	end

	for sid in pairs(nge) do
		lu.assertNil(inStf[sid], sid .. " must not be in the pre-NGE STF (D-8)")
	end
end

-- AC-9, I-3: every screen is an NPC line of the java with its end flag, animation and reply sids (I-4 except E-1)
function TestSignupConformance:test_the_nine_screens_are_java_lines_with_the_java_end_flag_animation_and_replies()
	local byId = screensById()

	for _, row in ipairs(S.ROWS) do
		local node = KJAVA.nodes[row.sid]

		lu.assertNotNil(byId[row.id], "kaydine_convo_template: missing screen '" .. row.id .. "'")
		lu.assertNotNil(node, row.id .. ": " .. row.sid .. " is an NPC line of the java")
		lu.assertEquals(sidOf(byId[row.id].leftDialog), row.sid, row.id .. ": line")
		lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd, row.id .. ": end flag")
		lu.assertEquals(byId[row.id].animation or "", node.animation or "", row.id .. ": animation")

		local replies = {}

		for i, o in ipairs(byId[row.id].options or {}) do
			replies[i] = sidOf(o[1])
		end

		if row.id == "signup_security_welcome" then
			-- E-1 (D-8): the java reply here is the NGE-only s_29; Core3 offers "What's the job?" instead
			lu.assertEquals(node.options, { "s_29" }, row.id .. ": java reply (NGE-only)")
			lu.assertEquals(replies, { "s_f6ae3b07" }, row.id .. ": replies (E-1)")
		else
			lu.assertEquals(replies, node.options, row.id .. ": reply sids in the java order")
		end
	end
end

-- AC-9, I-4: every link of the sign-up graph is an edge of the java, with E-1 the only exception
function TestSignupConformance:test_every_link_is_a_java_edge_except_e_1()
	local byId = screensById()
	local exceptions = {}

	for _, row in ipairs(S.ROWS) do
		lu.assertNotNil(byId[row.id], "kaydine_convo_template: missing screen '" .. row.id .. "'")

		for _, o in ipairs(byId[row.id].options or {}) do
			local target = byId[o[2]]

			lu.assertNotNil(target, row.id .. ": link '" .. tostring(o[2]) .. "' exists")

			local successors = KJAVA.successorsOf(sidOf(byId[row.id].leftDialog), sidOf(o[1]))

			if not contains(successors, sidOf(target.leftDialog)) then
				exceptions[#exceptions + 1] = row.id .. " -(" .. sidOf(o[1]) .. ")-> " .. o[2]
			end
		end
	end

	lu.assertEquals(exceptions, { "signup_security_welcome -(s_f6ae3b07)-> signup_job" }, "links that are not an edge of the java (E-1 only)")
end

-- AC-9, I-3, D-8: none of the NGE-only ids appears in KC or KH
function TestSignupConformance:test_no_nge_only_string_id_is_used_by_the_template_or_the_handler()
	for _, rel in ipairs({ "mobile/conversations/space/neutral/rsf_squadron/kaydine_convo.lua", "screenplays/space/conversations/neutral/rsf_squadron/kaydineConvoHandler.lua" }) do
		local text = readFile(rel)

		for _, sid in ipairs(S.NGE_ONLY) do
			-- the NGE-only ids are the whole id: ":s_29" followed by a quote ("s_29" must not match "s_290")
			lu.assertNil(text:find(":" .. sid .. '"', 1, true), rel .. ": uses the NGE-only id " .. sid)
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: the first meeting
---------------------------------------------------------------------------------------------

TestSignupFirstMeeting = {}

function TestSignupFirstMeeting:setUp() H.reset() end

-- AC-2
function TestSignupFirstMeeting:test_a_new_rsf_tier_2_pilot_opens_on_signup_with_their_name_and_the_one_reply()
	local player = S.pilot()
	local transcript = converse(player)

	lu.assertEquals(transcript[1].id, "signup", "first screen")
	lu.assertEquals(transcript[1].text, S.PREFIX .. "s_464cfc61", "signup line")
	lu.assertEquals(transcript[1].params.TU, player.name, "%TU is the pilot's first name")
	lu.assertEquals(#transcript[1].options, 1, "number of options")
	lu.assertEquals(transcript[1].options[1].text, S.PREFIX .. "s_9560d48e", "the reply")
	lu.assertEquals(transcript[1].options[1].link, "signup_palace", "its link")
	lu.assertFalse(transcript[1].stop, "signup does not end the conversation")
end

-- AC-2, D-5, I-1: showing the opening screen writes nothing
function TestSignupFirstMeeting:test_showing_the_opening_screen_writes_no_key_and_plays_no_music()
	local player = S.pilot()
	local rec = G.spies(player)
	local before = G.statusSnapshot()

	converse(player)

	lu.assertNil(S.flag(player), "StartedKaydine after the opening screen")
	lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), {}, "quest status keys written")
	lu.assertEquals(player.music, {}, "music")
	lu.assertEquals(rec.starts, {}, "startQuest calls")
end

-- AC-2, D-1: the sign-up comes after on_mission
function TestSignupFirstMeeting:test_a_pilot_with_a_kaydine_mission_or_duty_running_gets_on_mission_not_the_signup()
	local running = {}

	for _, g in ipairs(G.KAYDINE_CHAINS) do running[#running + 1] = g end
	for _, g in pairs(G.KAYDINE_DUTIES) do running[#running + 1] = g end

	table.sort(running)
	lu.assertEquals(#running, 7, "setup: four chain heads and three duties")

	for _, g in ipairs(running) do
		H.reset()

		local player = S.pilot({ active = { g } })

		lu.assertEquals(first(player), "on_mission", g .. " active: first screen")
		lu.assertNil(S.flag(player), g .. " active: StartedKaydine")
	end
end

---------------------------------------------------------------------------------------------
-- AC-3 / AC-4: both branches sign up, leaving early, coming back
---------------------------------------------------------------------------------------------

TestSignupWalks = {}

function TestSignupWalks:setUp() H.reset() end

local WALKS = { { "a", S.WALK_A }, { "b", S.WALK_B } }

for _, w in ipairs(WALKS) do
	local name, walk = w[1], w[2]

	-- AC-3
	TestSignupWalks["test_branch_" .. name .. "_visits_the_screens_of_the_spec_ends_on_signup_accept_and_signs_the_pilot_up"] = function()
		local player = S.pilot()
		local transcript = converse(player, walk.replies)

		lu.assertEquals(ids(transcript), walk.screens, "branch " .. name .. ": screens")
		lu.assertTrue(transcript[#transcript].stop, "signup_accept stops the conversation")
		lu.assertEquals(S.flag(player), "1", "StartedKaydine")
		lu.assertEquals(player.music, { S.MUSIC }, "music played")
	end

	-- AC-3: nothing else happens
	TestSignupWalks["test_branch_" .. name .. "_starts_no_quest_grants_no_skill_and_writes_only_the_flag"] = function()
		local player = S.pilot({ experience = { space_combat_general = S.XP } })
		local rec = G.spies(player)
		local before = G.statusSnapshot()
		local skillsBefore = {}

		for k, v in pairs(player.skills) do skillsBefore[k] = v end

		converse(player, walk.replies)

		lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), { keyOf(player) }, "quest status keys written")
		lu.assertEquals(rec.starts, {}, "startQuest calls")
		lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
		lu.assertEquals(#rec.chains, 0, "startSpaceQuestChain calls")
		lu.assertEquals(#rec.skills, 0, "grantSpaceSkill calls")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "awardSkill calls")
		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "skillManagerAwardSkill calls")
		lu.assertEquals(player.skills, skillsBefore, "skills held")
		lu.assertEquals(player.ghost.experience.space_combat_general, S.XP, "XP")
		lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier")
	end

	-- AC-4, D-5: the flag is set on the display of signup_accept, not before
	TestSignupWalks["test_branch_" .. name .. "_sets_nothing_until_signup_accept_is_shown"] = function()
		local player = S.pilot()
		local early = {}

		for i = 1, #walk.replies - 1 do early[i] = walk.replies[i] end

		local transcript = converse(player, early)

		lu.assertEquals(ids(transcript), { table.unpack(walk.screens, 1, #walk.screens - 1) }, "screens up to signup_duty")
		lu.assertNil(S.flag(player), "StartedKaydine on signup_duty")
		lu.assertEquals(player.music, {}, "music on signup_duty")
	end

	-- AC-4: stopping after any number of replies sets nothing and the next visit starts on signup
	TestSignupWalks["test_leaving_branch_" .. name .. "_at_any_screen_before_signup_accept_sets_nothing_and_the_next_visit_opens_on_signup"] = function()
		for k = 0, #walk.replies - 1 do
			H.reset()

			local player = S.pilot()
			local choices = {}

			for i = 1, k do choices[i] = walk.replies[i] end

			local transcript = converse(player, choices)

			lu.assertEquals(#transcript, k + 1, "left after " .. k .. " replies: screens shown")
			lu.assertNil(S.flag(player), "left after " .. k .. " replies: StartedKaydine")
			lu.assertEquals(player.music, {}, "left after " .. k .. " replies: music")
			lu.assertEquals(first(player), "signup", "left after " .. k .. " replies: next visit")
		end
	end

	-- AC-4: after the sign-up the next visit routes as for any signed-up pilot
	TestSignupWalks["test_after_branch_" .. name .. "_the_next_visit_with_60000_xp_offers_training_of_all_four_skills"] = function()
		local player = S.pilot({ experience = { space_combat_general = S.XP } })

		converse(player, walk.replies)

		local transcript = converse(player)

		lu.assertEquals(transcript[1].id, "ready_train_pilot", "first screen of the next visit")
		lu.assertEquals(P.pairsOf(transcript[1]), P.expected(P.KAYDINE, {}), "options (reply, link): the choice of all four skills")
		lu.assertEquals(S.flag(player), "1", "StartedKaydine still set")
	end

	-- AC-4
	TestSignupWalks["test_after_branch_" .. name .. "_the_next_visit_with_too_little_xp_is_here_for_work"] = function()
		local player = S.pilot({ experience = { space_combat_general = S.XP - 1 } })

		converse(player, walk.replies)
		lu.assertEquals(first(player), "here_for_work", "first screen of the next visit")
	end
end

-- AC-3: the two branches differ only between signup_palace and signup_job
function TestSignupWalks:test_the_two_branches_rejoin_at_signup_job_and_the_replies_there_are_the_same()
	local a, b = S.pilot(), S.pilot()
	local ta, tb = converse(a, S.WALK_A.replies), converse(b, S.WALK_B.replies)

	lu.assertEquals(ta[4].id, "signup_job", "branch A, 4th screen")
	lu.assertEquals(tb[5].id, "signup_job", "branch B, 5th screen")
	lu.assertEquals(ta[4].options, tb[5].options, "options of signup_job")
	lu.assertEquals(ta[6].text, tb[7].text, "the closing line")
end

-- AC-3, AC-4: the dialog is repeatable once the flag is gone, and signing up twice stays signed up
function TestSignupWalks:test_signing_up_again_after_the_flag_was_removed_works_the_same()
	local player = S.pilot()

	converse(player, S.WALK_A.replies)
	removeQuestStatus(keyOf(player))
	player.music = {}

	lu.assertEquals(ids(converse(player, S.WALK_B.replies)), S.WALK_B.screens, "second sign-up screens")
	lu.assertEquals(S.flag(player), "1", "StartedKaydine")
	lu.assertEquals(player.music, { S.MUSIC }, "music played once more")
end

---------------------------------------------------------------------------------------------
-- AC-5: pilots who already have tier 2 progress skip the dialog
---------------------------------------------------------------------------------------------

TestSignupLivePilots = {}

function TestSignupLivePilots:setUp() H.reset() end

-- AC-5, D-2: the AC-2 pilot is not signed up; asking writes nothing
function TestSignupLivePilots:test_the_new_pilot_is_not_signed_up_and_asking_writes_nothing()
	local player = S.pilot()
	local before = G.statusSnapshot()

	lu.assertFalse(handler():isSignedUp(player), "isSignedUp of the AC-2 pilot")
	lu.assertFalse(handler():isSignedUp(player), "isSignedUp, asked twice")
	lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), {}, "quest status keys written by isSignedUp")
end

-- AC-5, D-2: the flag itself
function TestSignupLivePilots:test_the_flag_alone_makes_the_pilot_signed_up()
	local player = S.pilot({ signedUp = true })

	H.setQuestStatus(player, S.FLAG, 1)
	lu.assertTrue(handler():isSignedUp(player), "isSignedUp with the flag")
	lu.assertNotEquals(first(player), "signup", "first screen with the flag")
end

-- AC-5
for i, skill in ipairs(S.TIER2_SKILLS) do
	TestSignupLivePilots["test_one_tier_2_skill_" .. skill .. "_alone_counts_as_signed_up"] = function()
		local skills = {}

		for j, s in ipairs(S.TIER1_SKILLS) do skills[j] = s end

		skills[#skills + 1] = skill

		local player = S.pilot({ baseSkills = skills })

		lu.assertTrue(handler():isSignedUp(player), "isSignedUp with " .. skill)
		lu.assertNotEquals(first(player), "signup", "first screen with " .. skill)
		lu.assertNil(S.flag(player), "StartedKaydine written (I-1)")
	end
end

-- AC-5
function TestSignupLivePilots:test_pilot_tier_3_alone_counts_as_signed_up()
	local player = S.pilot()

	player.ghost.pilotTier = 3

	lu.assertTrue(handler():isSignedUp(player), "isSignedUp at pilot tier 3")
	lu.assertNotEquals(first(player), "signup", "first screen at pilot tier 3")
	lu.assertNil(S.flag(player), "StartedKaydine written (I-1)")
end

-- AC-5: each of the eight keys, alone
for _, key in ipairs(S.TIER2_KEYS) do
	TestSignupLivePilots["test_the_key_" .. key:gsub(":", "_") .. "_alone_counts_as_signed_up"] = function()
		local player = S.pilot({ questStatus = { [key] = "1" } })

		lu.assertTrue(handler():isSignedUp(player), "isSignedUp with " .. key)
		lu.assertNotEquals(first(player), "signup", "first screen with " .. key)
		lu.assertNil(S.flag(player), "StartedKaydine written with " .. key .. " (I-1)")
	end
end

-- AC-5: mission 1's chain complete (the win of mission 1), nothing else
function TestSignupLivePilots:test_a_won_mission_1_alone_counts_as_signed_up()
	local player = S.pilot({ complete = { "assassinate_naboo_privateer_tier2_1c" } })

	lu.assertEquals(handler():getNextMission(player), 2, "setup: mission 1 is won")
	lu.assertTrue(handler():isSignedUp(player), "isSignedUp with mission 1 won")
	lu.assertNotEquals(first(player), "signup", "first screen with mission 1 won")
	lu.assertNil(S.flag(player), "StartedKaydine written (I-1)")
end

-- AC-5: the first link of the chain alone is not the win of mission 1
function TestSignupLivePilots:test_a_completed_first_link_of_mission_1_is_not_progress()
	local player = S.pilot({ complete = { "assassinate_naboo_privateer_tier2_1a" } })

	lu.assertFalse(handler():isSignedUp(player), "isSignedUp with only 1a complete")
end

-- AC-5, Data mapping (lossy row): a finished duty alone is not tier 2 progress, so the pilot sees the sign-up once
function TestSignupLivePilots:test_a_pilot_whose_only_history_is_a_finished_duty_still_sees_the_signup()
	local player = S.pilot({ complete = { "escort_duty_naboo_privateer_9" } })

	lu.assertFalse(handler():isSignedUp(player), "isSignedUp with a finished duty only")
	lu.assertEquals(first(player), "signup", "first screen")
end

-- AC-5: keys of other quests are not tier 2 progress
function TestSignupLivePilots:test_a_reward_key_of_tier_1_is_not_tier_2_progress()
	local player = S.pilot({ questStatus = { ["patrol_naboo_privateer_1:reward"] = "1", ["patrol_naboo_privateer_1:attempted"] = "1" } })

	lu.assertFalse(handler():isSignedUp(player), "isSignedUp with tier 1 keys")
	lu.assertEquals(first(player), "signup", "first screen")
end

-- AC-5: a chain or duty running gives on_mission, tier 4 gives finished_tier3, both without a flag
function TestSignupLivePilots:test_pilot_tier_4_gets_finished_tier3_and_writes_no_flag()
	local player = S.pilot()

	player.ghost.pilotTier = 4

	lu.assertEquals(first(player), "finished_tier3", "first screen at pilot tier 4")
	lu.assertNil(S.flag(player), "StartedKaydine written (I-1)")
end

-- AC-5, D-2: no migration step
function TestSignupLivePilots:test_the_legacy_migration_steps_are_still_the_three_of_before()
	local rs = H.expectGlobal("RsfSquadronScreenplay", "RSF screenplay")

	lu.assertEquals(#rs.LEGACY_MIGRATION_STEPS, 3, "RsfSquadronScreenplay.LEGACY_MIGRATION_STEPS entries")
end

-- AC-5, I-1: no routing path writes the flag
function TestSignupLivePilots:test_no_visit_of_a_pilot_with_progress_writes_the_flag()
	local cases = {
		{ "tier 2 skill", S.pilot({ baseSkills = { S.TIER1_SKILLS[1], S.TIER2_SKILLS[1] } }) },
		{ "reward key", S.pilot({ questStatus = { ["naboo_privateer_13:reward"] = "1" } }) },
		{ "mission 1 won", S.pilot({ complete = { "assassinate_naboo_privateer_tier2_1c" } }) },
		{ "chain active", S.pilot({ active = { "destroy_naboo_privateer_13" } }) },
	}

	for _, c in ipairs(cases) do
		converse(c[2])
		lu.assertNil(S.flag(c[2]), c[1] .. ": StartedKaydine written by a visit (I-1)")
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: the gates come first
---------------------------------------------------------------------------------------------

TestSignupGates = {}

function TestSignupGates:setUp() H.reset() end

local GATES = {
	{ "a_player_without_pilot_skills", function() return G.pilot({ kind = "none" }) end, { "not_pilot" } },
	{ "a_rebel_pilot", function() return G.pilot({ kind = "rebel" }) end, { "rebel_pilot" } },
	{ "an_imperial_pilot", function() return G.pilot({ kind = "imperial" }) end, { "imperial_pilot" } },
	{ "a_corsec_pilot_without_tier_1", function() return G.offTrack({}) end, { "pilot_not_rsf", "non_rsf_missions" } },
	{ "a_corsec_pilot_with_all_tier_1_skills", function() return G.offTrack({ tier1 = 4 }) end, { "pilot_not_rsf", "non_rsf_duty_options", "accept_duty_escort" } },
	{ "an_rsf_pilot_of_tier_1", function() return G.rsfPilot({ pilotTier = 1 }) end, { "not_ready_tier2", "not_ready_tier2_end" } },
	{ "an_rsf_pilot_of_tier_0", function() return G.rsfPilot({ pilotTier = 0, tier1 = 0 }) end, { "not_ready_tier2", "not_ready_tier2_end" } },
}

for _, gate in ipairs(GATES) do
	-- AC-6: no sign-up key exists, yet the gate screen is unchanged and no flag is written along the way
	TestSignupGates["test_" .. gate[1] .. "_gets_the_gate_screens_not_the_signup"] = function()
		local player = gate[2]()
		local before = G.statusSnapshot()
		local transcript = G.converse("kaydine", player, { 0, 0, 0 })

		lu.assertEquals(ids(transcript), gate[3], gate[1] .. ": screens choosing option 1")
		lu.assertNil(S.flag(player), gate[1] .. ": StartedKaydine")
		lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), {}, gate[1] .. ": quest status keys written")
		lu.assertFalse(contains(player.music, S.MUSIC), gate[1] .. ": the sign-up music")
	end
end

-- AC-6: the same for the rebel and imperial pilots of the RSF track and with the unsigned tier 2 builder
function TestSignupGates:test_the_unsigned_builder_pilot_with_jtl_off_gets_not_pilot()
	H.Engine.config.jtlEnabled = false

	local player = S.pilot()

	lu.assertEquals(first(player), "not_pilot", "first screen with JTL disabled")
	lu.assertNil(S.flag(player), "StartedKaydine")
end

-- AC-6: a tier 1 RSF pilot built like the AC-2 pilot
function TestSignupGates:test_the_unsigned_builder_pilot_at_pilot_tier_1_gets_not_ready_tier2()
	local player = S.pilot()

	player.ghost.pilotTier = 1

	lu.assertEquals(first(player), "not_ready_tier2", "first screen at pilot tier 1")
end

-- AC-6: the off-track duty offer and accept never write the key
function TestSignupGates:test_the_off_track_duty_accept_screens_never_write_the_flag()
	for _, accept in ipairs({ "escort", "recovery", "destroy" }) do
		H.reset()

		local player = G.offTrack({ tier1 = 4 })
		local option = ({ escort = "s_9b73da8", recovery = "s_30297e22", destroy = "s_c892e540" })[accept]
		local rec = G.spies(player)
		local transcript = G.converse("kaydine", player, { 0, option })

		lu.assertEquals(transcript[#transcript].id, "accept_duty_" .. accept, accept .. ": last screen")
		lu.assertNil(S.flag(player), accept .. ": StartedKaydine")
		lu.assertEquals(#rec.starts, 1, accept .. ": startQuest calls")
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: surrender
---------------------------------------------------------------------------------------------

TestSignupSurrender = {}

function TestSignupSurrender:setUp() H.reset() end

-- AC-7, D-7
function TestSignupSurrender:test_reset_kaydine_quests_removes_the_flag_and_the_next_visit_of_a_pilot_without_progress_opens_on_signup()
	local player = S.pilot()

	converse(player, S.WALK_A.replies)
	lu.assertEquals(S.flag(player), "1", "setup: signed up")

	RsfSquadronScreenplay:resetKaydineQuests(player)

	lu.assertNil(S.flag(player), "StartedKaydine after resetKaydineQuests")
	lu.assertEquals(first(player), "signup", "first screen after the reset (tier 2, no progress)")
end

-- AC-7, D-7
function TestSignupSurrender:test_surrender_pilot_removes_the_flag_and_a_requalified_pilot_opens_on_signup()
	local player = S.pilot()

	converse(player, S.WALK_B.replies)
	lu.assertEquals(S.flag(player), "1", "setup: signed up")

	player.ghost:setSquadronType(RSF_SQUADRON)
	SpaceHelpers:surrenderPilot(player)

	lu.assertNil(S.flag(player), "StartedKaydine after surrenderPilot")

	-- the pilot trains again up to tier 2 (no tier 2 progress)
	player.skills.pilot_neutral_novice = true

	for _, skill in ipairs(S.TIER1_SKILLS) do player.skills[skill] = true end

	player.ghost.pilotTier = 2
	player.ghost:setSquadronType(RSF_SQUADRON)

	lu.assertEquals(first(player), "signup", "first screen after re-qualifying")
end

-- AC-7: another pilot's flag is untouched
function TestSignupSurrender:test_the_reset_leaves_the_flag_of_another_pilot_alone()
	local one, other = S.pilot(), S.pilot()

	converse(one, S.WALK_A.replies)
	converse(other, S.WALK_A.replies)
	RsfSquadronScreenplay:resetKaydineQuests(one)

	lu.assertNil(S.flag(one), "StartedKaydine of the pilot who reset")
	lu.assertEquals(S.flag(other), "1", "StartedKaydine of the other pilot")
end

-- AC-7: the reset of a pilot who never signed up is harmless
function TestSignupSurrender:test_the_reset_without_a_flag_is_harmless()
	local player = S.pilot()

	RsfSquadronScreenplay:resetKaydineQuests(player)
	lu.assertNil(S.flag(player), "StartedKaydine")
end

---------------------------------------------------------------------------------------------
-- AC-8: fallthrough
---------------------------------------------------------------------------------------------

TestSignupFallthrough = {}

local realIsRSF, realLuaPlayerObject

function TestSignupFallthrough:setUp()
	H.reset()
	realIsRSF, realLuaPlayerObject = SpaceHelpers.isRSFSquadron, LuaPlayerObject
end

function TestSignupFallthrough:tearDown()
	SpaceHelpers.isRSFSquadron = realIsRSF
	LuaPlayerObject = realLuaPlayerObject
end

-- AC-8, D-9: KH:53, the player has no ghost although the squadron test said RSF
function TestSignupFallthrough:test_an_rsf_pilot_without_a_ghost_gets_fallthrough()
	local player = S.pilot()

	SpaceHelpers.isRSFSquadron = function() return true end
	player.ghost = nil

	local transcript = converse(player)

	lu.assertEquals(ids(transcript), { "fallthrough" }, "screens")
	lu.assertEquals(transcript[1].text, S.PREFIX .. "s_837686a5", "line")
	lu.assertTrue(transcript[1].stop, "stopConversation")
	lu.assertEquals(#transcript[1].options, 0, "options")
end

-- AC-8, D-9: KH:59, the ghost wrapper is nil
function TestSignupFallthrough:test_an_rsf_pilot_whose_ghost_wrapper_is_nil_gets_fallthrough()
	local player = S.pilot()

	LuaPlayerObject = function() return nil end

	local transcript = converse(player)

	lu.assertEquals(ids(transcript), { "fallthrough" }, "screens")
	lu.assertEquals(transcript[1].text, S.PREFIX .. "s_837686a5", "line")
	lu.assertTrue(transcript[1].stop, "stopConversation")
end

-- AC-8: the screen has no animation and no static options
function TestSignupFallthrough:test_the_fallthrough_screen_has_no_animation_and_no_options()
	local screen = screensById().fallthrough

	lu.assertNotNil(screen, "kaydine_convo_template: missing screen 'fallthrough'")
	lu.assertNil(screen.animation, "animation")
	lu.assertEquals(screen.options or {}, {}, "options")
	lu.assertEquals(screen.stopConversation, "true", "stopConversation")
end

-- AC-8: JTL disabled stays not_pilot even without a ghost
function TestSignupFallthrough:test_jtl_disabled_still_gets_not_pilot_for_a_pilot_without_a_ghost()
	local player = S.pilot()

	H.Engine.config.jtlEnabled = false
	SpaceHelpers.isRSFSquadron = function() return true end
	player.ghost = nil

	lu.assertEquals(ids(converse(player)), { "not_pilot" }, "screens with JTL disabled")
end

-- AC-8: a non-pilot is still not_pilot (the civilian greeting is not replaced by fallthrough)
function TestSignupFallthrough:test_a_player_without_pilot_skills_still_gets_not_pilot()
	lu.assertEquals(first(G.pilot({ kind = "none" })), "not_pilot", "first screen")
end

-- AC-8: no other routing state reaches fallthrough
function TestSignupFallthrough:test_no_ordinary_routing_state_reaches_fallthrough()
	local cases = {
		{ "new pilot", S.pilot() },
		{ "signed up", S.pilot({ signedUp = true }) },
		{ "xp", S.pilot({ experience = { space_combat_general = S.XP } }) },
		{ "chain active", S.pilot({ active = { "recovery_naboo_privateer_14" } }) },
		{ "tier 3", (function() local p = S.pilot(); p.ghost.pilotTier = 3; return p end)() },
		{ "tier 4", (function() local p = S.pilot(); p.ghost.pilotTier = 4; return p end)() },
		{ "rebel", G.pilot({ kind = "rebel" }) },
		{ "corsec", G.offTrack({}) },
	}

	for _, c in ipairs(cases) do
		lu.assertNotEquals(first(c[2]), "fallthrough", c[1] .. ": first screen")
	end
end
