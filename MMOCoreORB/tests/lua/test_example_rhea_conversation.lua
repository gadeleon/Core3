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

-- New conversations must assert H.conversationProblems(...) == {}. Rhea's existing template has
-- known dead links (found when this harness was added), pinned here so the gate stays green
-- until a CorSec feature fixes them:
--   * rhea_convo.lua defines `maybe_great` with id "maybe__42" and calls addScreen(maybe__42),
--     an undefined global, so the "Maybe." option has no screen and restarts the conversation.
--   * `i_need_to` is never defined.
-- When they are fixed, replace KNOWN_ISSUES with {}.
local KNOWN_ISSUES = {
	"screen 'ridiculous' option 1 links to missing screen 'maybe_great'",
	"screen 'ridiculous_great' option 1 links to missing screen 'maybe_great'",
	"screen 'thank_you' option 2 links to missing screen 'i_need_to'",
	"screen 'yes_ship' option 2 links to missing screen 'i_need_to'",
}

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
