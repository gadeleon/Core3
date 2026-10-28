-- Declann: the report, the Mission 2 payment and the master skill (free), and what happens after.
-- Spec: .claude/work/space-master-trainer-imperial/01-spec.md (AC-9; invariants I-7 and I-8; D-5, D-9; Conversation flow 2).
--
-- master_grant pays Mission 2 (50000 credits, the helmet, +400 Imperial) and then grants pilot_imperial_navy_master with
-- SpaceHelpers:grantSpaceSkill(p, skill, false): free. SpaceHelpers.grantSpaceSkill is wrapped (the original runs) to see the deduct flag.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_imperial_data")
local CS = require("harness.client_strings")

M.load()

local MASTER_COST = 7500000

local function setUp()
	H.reset()
	M.requireConversation(lu)
end

local function tearDown() M.restore() end

local HELMET = "object/tangible/wearables/helmet/helmet_fighter_imperial_ace.iff"

-- M2 won and unpaid, M1 paid, four _04 skills, XP for the skill's listed cost (so a charge would show)
local function winner(extra)
	local o = { paid = { 1 }, mission = { [2] = "won" }, xp = 8000000 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return M.pilot(o)
end

local function xp(player) return player.ghost.experience.space_combat_general end

local function hasMaster(player) return CreatureObject(player):hasSkill(M.MASTER) end

-- the "skill learned" system messages the pilot got (SpaceHelpers:grantSpaceSkill sends @skill_teacher:prose_skill_learned)
local function learned(player)
	local n = 0

	for _, m in ipairs(H.messageLog(player)) do
		if tostring(m.id):find("prose_skill_learned", 1, true) then
			n = n + 1
		end
	end

	return n
end

TestMasterTrainerImperialMaster = {}

TestMasterTrainerImperialMaster.setUp = setUp
TestMasterTrainerImperialMaster.tearDown = tearDown

-- AC-9: both routes reach master_grant
function TestMasterTrainerImperialMaster:test_both_m2_won_routes_reach_master_grant_then_master_end()
	local routes = {
		{ "s_f010d9ab", "s_2f52e0af", "s_beb9353a", "s_a1669dff" },
		{ "s_f010d9ab", "s_6aa8adaf", "s_6a66a025", "s_377d1a96", "s_a1669dff" },
	}

	local want = {
		{ "m2_won", "m2_report", "m2_not_dismissed", "master_grant", "master_end" },
		{ "m2_won", "m2_report", "m2_hoping", "m2_rewarded", "master_grant", "master_end" },
	}

	for i, replies in ipairs(routes) do
		H.reset()

		local player = winner()
		local t = M.talk(player, replies)

		lu.assertEquals(M.ids(t), want[i], "route " .. i .. ": screens shown")
		lu.assertTrue(t[#t].stop, "master_end ends the conversation")
		lu.assertTrue(hasMaster(player), "route " .. i .. ": pilot_imperial_navy_master granted")
		lu.assertEquals(player.bankCredits, 50000, "route " .. i .. ": credits")
		lu.assertEquals(M.itemsGiven(player), { HELMET }, "route " .. i .. ": the helmet")
		lu.assertEquals(M.standing(player), 400, "route " .. i .. ": Imperial standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "route " .. i .. ": client strings")
	end
end

-- AC-9, I-8, D-5: the grant is free: grantSpaceSkill(p, "pilot_imperial_navy_master", false), XP unchanged
function TestMasterTrainerImperialMaster:test_master_grant_grants_the_master_skill_free_and_xp_is_unchanged()
	local calls = M.recordGrants()
	local player = winner()
	local before = xp(player)

	lu.assertFalse(hasMaster(player), "precondition: no master skill")
	H.Engine.config.skillXpCosts = { [M.MASTER] = MASTER_COST }
	M.drive(player, "master_grant")

	lu.assertEquals(calls, { { skill = M.MASTER, deduct = false } }, "grantSpaceSkill calls (skill, deduct flag)")
	lu.assertTrue(hasMaster(player), "the master skill is held")
	lu.assertEquals(xp(player), before, "space_combat_general experience is unchanged (the 7,500,000 XP_COST is never charged)")
	lu.assertEquals(learned(player), 1, "one 'skill learned' message (the grant case differs from the guard case only by the held skill)")
	lu.assertEquals(#H.Engine.callsTo("awardSkill"), 1, "free grants (awardSkill)")
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "XP-charging grants")
end

-- D-5: a pilot who could not pay the listed cost still gets the skill
function TestMasterTrainerImperialMaster:test_a_pilot_with_no_xp_still_gets_the_master_skill()
	local player = winner({ xp = 0 })

	H.Engine.config.skillXpCosts = { [M.MASTER] = MASTER_COST }
	M.drive(player, "master_grant")
	lu.assertTrue(hasMaster(player), "the master skill is granted without XP")
	lu.assertEquals(xp(player), 0, "XP stays 0")
end

-- AC-9, I-7, D-9: master_grant pays mission 2: 50000, the helmet (any species), +400
function TestMasterTrainerImperialMaster:test_master_grant_pays_mission_2_to_every_species()
	for _, sp in ipairs({ SPECIES_HUMAN, SPECIES_ZABRAK, SPECIES_WOOKIEE, SPECIES_ITHORIAN }) do
		H.reset()

		local player = winner({ species = sp })

		M.drive(player, "master_grant")
		lu.assertEquals(player.bankCredits, 50000, "species " .. sp .. ": credits")
		lu.assertEquals(#player.bankCreditLog, 1, "species " .. sp .. ": addBankCredits calls")
		lu.assertEquals(M.itemsGiven(player), { HELMET }, "species " .. sp .. ": the helmet")
		lu.assertEquals(M.standing(player), 400, "species " .. sp .. ": standing")
		lu.assertEquals(H.getQuestStatus(player, "master_imperial_2:reward"), "1", "species " .. sp .. ": master_imperial_2:reward")
	end
end

-- AC-9, I-7: a full inventory still receives the helmet
function TestMasterTrainerImperialMaster:test_a_full_inventory_still_receives_the_helmet_through_the_overload()
	local player = winner({ inventory = { limit = 0 } })

	M.drive(player, "master_grant")
	lu.assertEquals(#player.inventory.items, 1, "the helmet lands in the full inventory")

	local calls = H.Engine.callsTo("giveItem")

	lu.assertEquals(#calls, 1, "giveItem calls")
	lu.assertEquals(calls[1].n, 4, "giveItem argument count (the overload form)")
	lu.assertIs(calls[1][4], true, "the overload flag")
end

-- AC-9, D-9: the payment is on master_grant, not on master_end: closing the window on master_grant leaves both done
function TestMasterTrainerImperialMaster:test_closing_the_conversation_on_master_grant_leaves_the_payment_and_the_skill_done()
	local player = winner()
	local t = M.talk(player, { "s_f010d9ab", "s_2f52e0af", "s_beb9353a" })

	lu.assertEquals(M.ids(t)[#t], "master_grant", "the talk stops on master_grant")
	lu.assertEquals(player.bankCredits, 50000, "paid on display of master_grant")
	lu.assertEquals(M.itemsGiven(player), { HELMET }, "the helmet")
	lu.assertEquals(M.standing(player), 400, "standing")
	lu.assertTrue(hasMaster(player), "the skill")

	local again = M.talk(player)

	lu.assertEquals(again[1].id, "master_done", "the next talk opens master_done")
	lu.assertEquals(player.bankCredits, 50000, "credits after the next talk")
	lu.assertEquals(#M.itemsGiven(player), 1, "items after the next talk")
	lu.assertEquals(M.standing(player), 400, "standing after the next talk")
end

-- AC-9, D-9: master_end pays and grants nothing
function TestMasterTrainerImperialMaster:test_master_end_pays_and_grants_nothing()
	local calls = M.recordGrants()
	local player = M.pilot({ paid = { 1, 2 }, master = true })

	M.drive(player, "master_end")
	lu.assertEquals(player.bankCredits or 0, 0, "credits")
	lu.assertEquals(#M.itemsGiven(player), 0, "items")
	lu.assertEquals(M.standing(player), 0, "standing")
	lu.assertEquals(calls, {}, "grantSpaceSkill calls")
end

-- AC-9, I-7: master_grant shown three times pays once
function TestMasterTrainerImperialMaster:test_master_grant_shown_three_times_pays_once_and_grants_once()
	local calls = M.recordGrants()
	local player = winner()

	for _ = 1, 3 do
		M.drive(player, "master_grant")
	end

	lu.assertEquals(player.bankCredits, 50000, "credits after three visits")
	lu.assertEquals(#M.itemsGiven(player), 1, "items after three visits")
	lu.assertEquals(M.standing(player), 400, "standing after three visits")
	lu.assertEquals(#calls, 1, "grantSpaceSkill calls after three visits")
end

-- AC-9, I-7: a paid mission 2 pays nothing again, but the pilot who lacks the skill still gets it
function TestMasterTrainerImperialMaster:test_a_paid_mission_2_pays_nothing_on_master_grant()
	local player = winner()

	H.setQuestStatus(player, "master_imperial_2:reward", 1)
	M.drive(player, "master_grant")
	lu.assertEquals(player.bankCredits or 0, 0, "credits")
	lu.assertEquals(#M.itemsGiven(player), 0, "items")
	lu.assertEquals(M.standing(player), 0, "standing")
end

-- AC-9, I-8: ISOLATED GUARD. M2 won and unpaid, the master skill ALREADY HELD, every other condition as in the grant case
-- (test_master_grant_grants_the_master_skill_free_and_xp_is_unchanged): master_grant pays mission 2 once and grants nothing.
function TestMasterTrainerImperialMaster:test_master_grant_with_the_master_skill_already_held_pays_once_and_does_not_grant_again()
	local calls = M.recordGrants()
	local player = winner({ master = true })

	lu.assertTrue(hasMaster(player), "precondition: the master skill is already held")
	lu.assertFalse(M.handler():isPaid(player, 2), "precondition: mission 2 unpaid")
	lu.assertTrue(M.handler():isWon(player, 2), "precondition: mission 2 won")

	M.drive(player, "master_grant")

	lu.assertEquals(player.bankCredits, 50000, "mission 2 is paid")
	lu.assertEquals(M.itemsGiven(player), { HELMET }, "the helmet")
	lu.assertEquals(M.standing(player), 400, "standing")
	lu.assertEquals(calls, {}, "grantSpaceSkill is not called when the skill is already held")
	lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "free grants")
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "XP-charging grants")
	lu.assertEquals(learned(player), 0, "no 'skill learned' message")
end

-- AC-9: the handler's grantMaster has the same guard when called directly
function TestMasterTrainerImperialMaster:test_grant_master_does_nothing_for_a_pilot_who_holds_the_skill()
	local calls = M.recordGrants()
	local held = winner({ master = true })

	M.handler():grantMaster(held)
	lu.assertEquals(calls, {}, "grantSpaceSkill calls for a holder")

	local fresh = winner()

	M.handler():grantMaster(fresh)
	lu.assertEquals(calls, { { skill = M.MASTER, deduct = false } }, "grantSpaceSkill calls for a pilot without the skill (free)")
end

-- I-8: the skill is granted on master_grant and nowhere else
function TestMasterTrainerImperialMaster:test_no_other_screen_grants_a_skill()
	for _, row in ipairs(M.SCREENS) do
		if row.id ~= "master_grant" then
			H.reset()
			M.spyStarts()

			local calls = M.recordGrants()
			local player = M.pilot({ paid = { 1 }, mission = { [2] = "won" } })

			M.drive(player, row.id)
			lu.assertEquals(calls, {}, row.id .. ": grantSpaceSkill calls")
			lu.assertFalse(hasMaster(player), row.id .. ": the master skill")
			M.restore()
		end
	end
end

-- AC-9: the pilot's other skills and pilot tier are unchanged by the master grant
function TestMasterTrainerImperialMaster:test_the_master_grant_changes_no_other_skill_and_not_the_pilot_tier()
	local player = winner()
	local before = {}

	for skill in pairs(player.skills) do
		before[skill] = true
	end

	M.drive(player, "master_grant")

	local after = {}

	for skill in pairs(player.skills) do
		after[skill] = true
	end

	after[M.MASTER] = nil
	lu.assertEquals(after, before, "skills other than the master skill")
	lu.assertEquals(player.ghost.pilotTier, 5, "pilot tier (the C++ cap is 5)")
end

-- AC-9: after master_done nothing else starts or pays
function TestMasterTrainerImperialMaster:test_a_master_who_talks_again_gets_master_done_and_nothing_else()
	local spies = M.spyStarts()
	local calls = M.recordGrants()
	local player = M.pilot({ paid = { 1, 2 }, master = true })

	for _ = 1, 2 do
		local t = M.talk(player)

		lu.assertEquals(M.ids(t), { "master_done" }, "screens shown")
		lu.assertTrue(t[1].stop, "master_done ends the conversation")
	end

	lu.assertEquals(M.started(spies), {}, "quests started")
	lu.assertEquals(calls, {}, "grantSpaceSkill calls")
	lu.assertEquals(player.bankCredits or 0, 0, "credits")
end

-- AC-9, D-9: m2_won opens first for a winner, pays on master_grant, and the next talk is master_done even with the key chain complete
function TestMasterTrainerImperialMaster:test_a_winner_who_walks_the_whole_report_ends_a_master_with_both_missions_paid()
	local player = winner()
	local t = M.talk(player, { "s_f010d9ab", "s_6aa8adaf", "s_6a66a025", "s_377d1a96", "s_a1669dff" })

	lu.assertTrue(t[#t].stop, "the report ends")
	lu.assertTrue(M.handler():isPaid(player, 1), "mission 1 paid")
	lu.assertTrue(M.handler():isPaid(player, 2), "mission 2 paid")
	lu.assertTrue(hasMaster(player), "master")
	lu.assertEquals(M.talk(player)[1].id, "master_done", "later visits")
end
