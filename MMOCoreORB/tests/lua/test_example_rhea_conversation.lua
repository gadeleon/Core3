-- Worked example of a conversation behavior test, written against content that already exists
-- (CorSec tier 1 trainer Sgt. Rhea). Shows: loading a conversation template + handler, the
-- structural check, and driving H.converse with fake players in different states.

local lu = require("luaunit")
local H = require("harness")

H.loadSquadron("CorsecSquadronScreenplay")
H.loadMobile("conversations/space/neutral/corsec_squadron/rhea_convo.lua")
H.loadScreenplay("space/conversations/neutral/corsec_squadron/rheaConvoHandler.lua")

TestRheaConversation = {}

function TestRheaConversation:setUp()
	H.reset()
end

function TestRheaConversation:test_template_is_registered_with_its_handler()
	local t = H.conversationTemplateTable("rhea_convo_template")
	lu.assertNotNil(t, "rhea_convo_template registered")
	lu.assertEquals(t.luaClassHandler, "rheaConvoHandler")
end

-- New conversations must assert H.conversationProblems(...) == {}. Rhea's template had two dead links, both `i_need_to` ("I need to take care of
-- some things first." on thank_you and yes_ship); space-trainer-dead-ends added that screen, so the template has no known issues left.
-- (The `maybe_great` screen was registered by the space-trainer-fixes feature, which also pins it in test_trainer_fixes_templates.lua.)
local KNOWN_ISSUES = {}

function TestRheaConversation:test_option_links_match_known_issues_only()
	lu.assertEquals(H.conversationProblems("rhea_convo_template"), KNOWN_ISSUES)
end

function TestRheaConversation:test_jtl_disabled_gets_no_jtl_screen()
	H.Engine.config.jtlEnabled = false

	local transcript = H.converse({ template = "rhea_convo_template", player = H.newPlayer({ pilot = "neutral" }) })

	lu.assertEquals(transcript[1].id, "no_jtl")
end

function TestRheaConversation:test_rebel_pilot_is_turned_away()
	local transcript = H.converse({ template = "rhea_convo_template", player = H.newPlayer({ pilot = "rebel" }) })

	lu.assertEquals(transcript[1].id, "rebel_pilot")
end

function TestRheaConversation:test_non_pilot_is_offered_recruitment()
	local transcript = H.converse({ template = "rhea_convo_template", player = H.newPlayer({}) })

	lu.assertEquals(transcript[1].id, "recruitment")
end

function TestRheaConversation:test_neutral_pilot_from_another_squadron_is_recognized()
	local transcript = H.converse({ template = "rhea_convo_template", player = H.newPlayer({ pilot = "neutral", squadronType = 99 }) })

	lu.assertEquals(transcript[1].id, "non_corsec_pilot")
end
