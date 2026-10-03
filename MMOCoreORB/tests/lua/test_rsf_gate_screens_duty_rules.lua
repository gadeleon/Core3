-- Off-track pilots and the duty rules: one duty at a time, the same duty quests and the same pay as RSF pilots.
-- Spec: .claude/work/rsf-gate-screens/01-spec.md (AC-8, "Duty rules for off-track pilots", R-5).
--
-- The sequence tests run the real startQuest of the duty (the pilot stands in a ship in the quest zone, as DR.player places one); the
-- identity tests replace startQuest with a recorder.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local DR = require("duty_rules_scenario")
local G = require("rsf_gate_screens_data")

T.load()
H.loadSpaceQuestTypes()

local D6, D7 = G.DINGE_DUTIES.destroy, G.DINGE_DUTIES.escort
local K = G.KAYDINE_DUTIES

-- A CorSec pilot with all four tier 1 skills, standing in a ship in the naboo space zone (where the RSF duties run)
local function flyer(zone)
	return G.offTrack({ tier1 = 4, zone = zone or "space_naboo", ship = { x = DR.CORNER.x, z = DR.CORNER.z, y = DR.CORNER.y } })
end

local function dutyOffer(_, choices)
	return G.concat({ "s_c1ff5062" }, choices)
end

local function heldDuties(player)
	return #DR.flaggedMissions(player)
end

---------------------------------------------------------------------------------------------
-- AC-8: one duty at a time
---------------------------------------------------------------------------------------------

TestOffTrackOneDuty = {}

function TestOffTrackOneDuty:setUp() H.reset() end

-- AC-8
function TestOffTrackOneDuty:test_after_taking_dinge_duty_6_the_next_visit_to_dinge_and_a_visit_to_kaydine_end_on_the_refusal_line()
	local player = flyer()
	local q = H.expectGlobal(D6, "duty quest")

	local first = G.converse("dinge", player, dutyOffer("dinge", { "s_e814cf37", "s_40759c25" }))

	H.advance(0)
	lu.assertEquals(G.ids(first), { "non_rsf_pilot", "non_rsf_duty_offer", "duty_options", "destroy_duty" }, "first visit to Dinge")
	lu.assertTrue(DR.active(player, q), "setup: the duty is running")
	lu.assertEquals(#player.datapad.items, 1, "datapad missions after taking the duty")
	lu.assertEquals(heldDuties(player), 1, "duties in the datapad after taking the duty")

	local dinge = G.converse("dinge", player, dutyOffer("dinge", { 0 }))
	local kaydine = G.converse("kaydine", player, dutyOffer("kaydine", { 0 }))

	H.advance(0)
	lu.assertEquals(G.ids(dinge), { "non_rsf_pilot", "non_rsf_duty_missions" }, "next visit to Dinge")
	lu.assertTrue(dinge[2].stop, "Dinge's refusal ends the conversation")
	lu.assertEquals(G.sidOfStep(dinge[2]), "s_38d8b2c4", "Dinge's refusal line")
	lu.assertEquals(G.ids(kaydine), { "pilot_not_rsf", "non_rsf_missions" }, "visit to Kaydine with tier 1 complete")
	lu.assertTrue(kaydine[2].stop, "Kaydine's refusal ends the conversation")
	lu.assertEquals(G.sidOfStep(kaydine[2]), "s_7458c693", "Kaydine's refusal line")
	lu.assertEquals(#player.datapad.items, 1, "datapad missions after the later visits")
	lu.assertEquals(heldDuties(player), 1, "duties in the datapad after the later visits")
	lu.assertEquals(#DR.messages(player, DR.MSG_DUTY_ALREADY), 0, "duty_already was not needed: the gate refused first")
end

-- AC-8
function TestOffTrackOneDuty:test_after_taking_kaydine_destroy_duty_11_both_trainers_refuse_on_the_next_visit()
	local player = flyer()
	local q = H.expectGlobal(K.destroy, "duty quest")

	local first = G.converse("kaydine", player, dutyOffer("kaydine", { "s_c892e540" }))

	H.advance(0)
	lu.assertEquals(G.ids(first), { "pilot_not_rsf", "non_rsf_duty_options", "accept_duty_destroy" }, "first visit to Kaydine")
	lu.assertTrue(DR.active(player, q), "setup: the duty is running")
	lu.assertEquals(heldDuties(player), 1, "duties in the datapad after taking the duty")

	lu.assertEquals(G.ids(G.converse("kaydine", player, dutyOffer("kaydine", { 0 }))), { "pilot_not_rsf", "non_rsf_missions" }, "next visit to Kaydine")
	lu.assertEquals(G.ids(G.converse("dinge", player, dutyOffer("dinge", { 0 }))), { "non_rsf_pilot", "non_rsf_duty_missions" }, "visit to Dinge")
	lu.assertEquals(heldDuties(player), 1, "duties in the datapad after the later visits")
end

-- AC-8: once the duty is over (failed) the pilot is offered duties again
function TestOffTrackOneDuty:test_once_the_duty_has_ended_the_offer_comes_back()
	local player = flyer()
	local q = H.expectGlobal(D6, "duty quest")

	local first = G.converse("dinge", player, dutyOffer("dinge", { "s_e814cf37", "s_40759c25" }))

	H.advance(0)
	lu.assertEquals(G.ids(first), { "non_rsf_pilot", "non_rsf_duty_offer", "duty_options", "destroy_duty" }, "first visit to Dinge")
	lu.assertTrue(DR.active(player, q), "setup: the duty is running")

	q:failQuest(player, "true")
	H.advance(0)
	lu.assertEquals(#player.datapad.items, 0, "setup: failQuest removed the datapad mission")

	lu.assertEquals(G.ids(G.converse("dinge", player, dutyOffer("dinge", {}))), { "non_rsf_pilot", "non_rsf_duty_offer" }, "visit to Dinge after the duty ended")
	lu.assertEquals(G.ids(G.converse("kaydine", player, dutyOffer("kaydine", {}))), { "pilot_not_rsf", "non_rsf_duty_options" }, "visit to Kaydine after the duty ended")
end

-- AC-8: a story mission of another squadron blocks the offer the same way
function TestOffTrackOneDuty:test_a_running_story_mission_of_the_pilots_own_squadron_blocks_both_offers()
	local story = H.expectGlobal(G.CORSEC_STORY, "story quest")
	local player = flyer(story.questZone)

	story:startQuest(player, "")
	H.advance(0)
	lu.assertTrue(DR.active(player, story), "setup: the story mission is running")

	lu.assertEquals(G.ids(G.converse("dinge", player, dutyOffer("dinge", {}))), { "non_rsf_pilot", "non_rsf_duty_missions" }, "Dinge")
	lu.assertEquals(G.ids(G.converse("kaydine", player, dutyOffer("kaydine", {}))), { "pilot_not_rsf", "non_rsf_missions" }, "Kaydine")
end

-- AC-8 / R-5: if a duty lands in the datapad between the offer and the choice, activateSpaceQuest still refuses the second one
function TestOffTrackOneDuty:test_a_duty_taken_between_the_offer_and_the_choice_is_refused_by_activate_space_quest()
	local player = flyer()
	local hold = function(p) DR.holdDuty(p) end
	local transcript = G.converse("dinge", player, dutyOffer("dinge", { "s_e814cf37", hold, "s_40759c25" }))

	H.advance(0)
	lu.assertEquals(transcript[#transcript].id, "destroy_duty", "the acceptance line is still shown (R-5)")
	lu.assertEquals(heldDuties(player), 1, "duties in the datapad")
	lu.assertEquals(#DR.messages(player, DR.MSG_DUTY_ALREADY), 1, "duty_already messages")
	lu.assertFalse(DR.active(player, H.expectGlobal(D6, "duty quest")), "the second duty did not start")
end

-- AC-8: the rule itself is unchanged
function TestOffTrackOneDuty:test_activate_space_quest_still_refuses_a_second_duty_with_duty_already()
	local player = flyer()

	DR.holdDuty(player)

	local ok = SpaceHelpers:activateSpaceQuest(player, nil, "destroy_duty", "naboo_privateer_6", false)

	lu.assertEquals(ok, false, "activateSpaceQuest result")
	lu.assertEquals(#DR.messages(player, DR.MSG_DUTY_ALREADY), 1, "duty_already messages")
	lu.assertEquals(#player.datapad.items, 1, "datapad missions")
end

---------------------------------------------------------------------------------------------
-- AC-8: same quests, same pay
---------------------------------------------------------------------------------------------

TestOffTrackSamePay = {}

function TestOffTrackSamePay:setUp() H.reset() end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()

	return text
end

local function listFiles(dir, pattern)
	local out = {}
	local pipe = io.popen("ls " .. dir .. " 2>/dev/null")

	for name in pipe:lines() do
		if name:match(pattern) then
			out[#out + 1] = dir .. name
		end
	end

	pipe:close()

	return out
end

-- AC-8: the quest-type code has no predicate on the player's squadron, so pay cannot depend on it
function TestOffTrackSamePay:test_no_quest_type_file_asks_which_squadron_the_player_belongs_to()
	local dir = H.SCRIPTS .. "screenplays/space/"
	local files = listFiles(dir, "^Space[%w]*Screenplay%.lua$")

	files[#files + 1] = dir .. "SpaceQuestLogic.lua"
	lu.assertTrue(#files >= 15, "quest-type files found: " .. #files)

	local found = {}

	for _, path in ipairs(files) do
		local text = readFile(path)

		for _, predicate in ipairs({ "isRSFSquadron", "isCorsecSquadron", "isHavocSquadron", "isSquadronType", "getSquadronType" }) do
			if text:find(predicate, 1, true) then
				found[#found + 1] = path:match("[^/]+$") .. ": " .. predicate
			end
		end
	end

	table.sort(found)
	lu.assertEquals(found, {}, "squadron predicates in the quest-type code")
end

local DUTIES = {
	{ "dinge", D6, "destroy_duty", { "s_c1ff5062", "s_e814cf37", "s_40759c25" }, "destroy_duty" },
	{ "dinge", D7, "escort_duty", { "s_c1ff5062", "s_e814cf37", "s_629c7d23" }, "escort_duty" },
	{ "kaydine", K.escort, "accept_duty_escort", { "s_c1ff5062", "s_9b73da8" }, "accept_duty_escort" },
	{ "kaydine", K.recovery, "accept_duty_recovery", { "s_c1ff5062", "s_30297e22" }, "accept_duty_recovery" },
	{ "kaydine", K.destroy, "accept_duty_destroy", { "s_c1ff5062", "s_c892e540" }, "accept_duty_destroy" },
}

for _, duty in ipairs(DUTIES) do
	local trainer, global, screen, choices = duty[1], duty[2], duty[3], duty[4]

	-- AC-8: the off-track path and the RSF path start the same quest table
	TestOffTrackSamePay["test_" .. trainer .. "_off_track_path_to_" .. global .. "_starts_the_same_table_the_rsf_path_starts"] = function()
		local handlerName = trainer == "dinge" and "dingeConvoHandler" or "kaydineConvoHandler"
		local templateName = G.TEMPLATES[trainer]
		local expected = rawget(_G, global)

		lu.assertNotNil(expected, global .. " is a global quest table")

		-- RSF pilot: the handler's own start on the duty screen
		local rsf = G.rsfPilot({ pilotTier = 2 })
		local rsfSpies = G.spies(rsf)
		local tmpl = H.conversationTemplate(templateName)

		_G[handlerName]:runScreenHandlers(tmpl, rsf, H.newNpc({}), 0, LuaConversationTemplate(tmpl):getScreen(screen))
		lu.assertEquals(rsfSpies.starts, { global }, "RSF path: quests started on " .. screen)
		lu.assertTrue(rsfSpies.startSelf[1] == expected, "RSF path: startQuest called on the table of " .. global)

		-- off-track pilot: the whole conversation
		H.reset()

		local off = G.offTrack({ tier1 = 4 })
		local offSpies = G.spies(off)

		G.converse(trainer, off, choices)
		lu.assertEquals(offSpies.starts, { global }, "off-track path: quests started")
		lu.assertTrue(offSpies.startSelf[1] == expected, "off-track path: startQuest called on the table of " .. global)
		lu.assertEquals(offSpies.rewards, {}, "off-track path: rewardPlayer calls (the pay comes with the duty)")
	end
end
