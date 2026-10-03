-- Admiral Imler's off-track duty gate takes SWG's "already has a quest" rule too (D-9): any space quest in the datapad refuses it.
-- Spec: .claude/work/rsf-gate-screens/01-spec.md (AC-9, Content contract 6). The existing TestImlerNonTrackDuty tests
-- (test_rsf_tier4_imler_behavior.lua) must pass unchanged; this file adds the datapad cases.

local lu = require("luaunit")
local H = require("harness")
local D = require("rsf_tier4_data")
local DR = require("duty_rules_scenario")
local G = require("rsf_gate_screens_data")

local loadErrors = {}

local function tryLoad(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		loadErrors[#loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

tryLoad("RsfSquadronScreenplay", function() H.loadSquadron("RsfSquadronScreenplay") end)
tryLoad("imler_convo.lua", function() H.loadMobile("conversations/space/neutral/rsf_squadron/imler_convo.lua") end)
tryLoad("imlerConvoHandler.lua", function() H.loadScreenplay("space/conversations/neutral/rsf_squadron/imlerConvoHandler.lua") end)

local function converse(player, choices)
	lu.assertNotNil(H.conversationTemplateTable("imler_convo_template"), "imler_convo_template is not registered. Load problems: " .. table.concat(loadErrors, " | "))

	return H.converse({ template = "imler_convo_template", player = player, npc = H.newNpc({ name = "Admiral Diness Imler" }), choices = choices })
end

TestImlerNonTrackDatapad = {}

function TestImlerNonTrackDatapad:setUp() H.reset() end

-- AC-9 (regression): nothing in the datapad, the tier 3 graduate of another squadron is still offered the duty menu
function TestImlerNonTrackDatapad:test_an_off_track_tier_3_graduate_with_an_empty_datapad_still_gets_nontrack_duty()
	local transcript = converse(D.corsec({}), { "s_c1ff5062" })

	lu.assertEquals(G.ids(transcript), { "not_my_track", "nontrack_duty" })
end

local HOLDS = {
	{ "a_held_duty", function(p) DR.holdDuty(p) end },
	{ "a_held_story_mission", function(p) DR.holdStory(p) end },
	{ "a_held_duty_of_another_squadron", function(p) DR.holdDuty(p, "corellia_privateer_6") end },
	{ "a_held_story_mission_of_another_squadron", function(p) DR.holdStory(p, "corellia_rebel_1") end },
}

for _, hold in ipairs(HOLDS) do
	-- AC-9
	TestImlerNonTrackDatapad["test_an_off_track_tier_3_graduate_with_" .. hold[1] .. "_gets_not_my_track_then_nontrack_no_duty"] = function()
		local player = D.corsec({})

		hold[2](player)

		local transcript = converse(player, { "s_c1ff5062" })

		lu.assertEquals(G.ids(transcript), { "not_my_track", "nontrack_no_duty" })
		lu.assertTrue(transcript[2].stop, "nontrack_no_duty ends the conversation")
	end
end

-- AC-9: the new rule only adds a refusal; the journal-only refusals of the existing tests stay
function TestImlerNonTrackDatapad:test_can_fly_non_track_duty_is_false_with_a_datapad_quest_and_true_without()
	local handler = H.expectGlobal("imlerConvoHandler", "Imler conversation handler")
	local free = D.corsec({})
	local held = D.corsec({})

	DR.holdStory(held)

	lu.assertTrue(handler:canFlyNonTrackDuty(free), "no quest")
	lu.assertFalse(handler:canFlyNonTrackDuty(held), "a story mission in the datapad")
end
