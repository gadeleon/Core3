-- Brother Ezkiel: surrendering the pilot profession and the talk that follows; the other parts of the feature leave the surrender untouched.
-- Spec: .claude/work/vortex-tier3-ezkiel/01-spec.md (AC-9 first bullet; Migration (player data: none); I-7).
--
-- Part A's resetEzkielQuests (called by SpaceHelpers:surrenderPilot after Vrovel's reset and before Burke's) clears the twenty journal entries and the eight status keys;
-- V3-FX's reset removes VORTEX_PILOT_KEY. Part B adds no key, so nothing new is left behind: after a surrender the pilot is no pilot.

local lu = require("luaunit")
local H = require("harness")
local W = require("vortex_tier3_data")

W.loadConversation()

local function surrender(player)
	SpaceHelpers:surrenderPilot(player)

	-- the engine derives pilot status from the novice box the surrender removes; the fake keeps the field, so the test says what the engine would
	if not CreatureObject(player):hasSkill("pilot_rebel_navy_novice") then
		player.pilot = nil
	end

	return player
end

TestEzkielConvoSurrender = {}

function TestEzkielConvoSurrender:setUp()
	H.reset()
	W.requireConversation(lu)
end

-- AC-9: after the surrender the next talk with Ezkiel opens not_pilot, whatever tier 3 state the pilot had
function TestEzkielConvoSurrender:test_the_next_talk_after_a_surrender_opens_not_pilot()
	local builders = {
		{ name = "ready for mission 1", build = function() return W.pilot({}) end },
		{ name = "mission 2 won, reward owed", build = function() return W.pilot({ missions = 1, t3 = 1, state = "won" }) end },
		{ name = "mission 3 running", build = function() return W.pilot({ missions = 2, t3 = 2, state = "active" }) end },
		{ name = "tier 3 graduate", build = function() return W.pilot({ missions = 4, t3 = 4 }) end },
	}

	for _, b in ipairs(builders) do
		H.reset()

		local player = b.build()

		surrender(player)
		lu.assertFalse(CreatureObject(player):hasSkill("pilot_rebel_navy_novice"), b.name .. ": the pilot box is gone")
		lu.assertEquals(W.firstScreen(player), "not_pilot", b.name .. ": the next talk")
	end
end

-- AC-9, I-7: a pilot who used the conversation (offer accepted, mission won, paid, a skill chosen) leaves no Ezkiel state after a surrender
function TestEzkielConvoSurrender:test_a_pilot_who_used_the_conversation_leaves_no_ezkiel_state_after_a_surrender()
	local player = W.pilot({})

	W.spyStarts()
	W.talk(player, (W.walkTo("m1_offer", "m1_accept_401aa65c")))

	for _, global in ipairs(W.CHAINS[1]) do
		W.setState(player, global, "complete")
	end

	W.talk(player, { W.TRAIN[1].reply })
	lu.assertEquals(W.paid(player, 1), "1", "precondition: mission 1 is paid")
	surrender(player)

	for _, key in ipairs(W.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, W.VORTEX_PILOT_KEY), "VORTEX_PILOT_KEY after the surrender")

	for _, global in ipairs(W.GLOBALS) do
		lu.assertEquals(W.state(player, global), "none", global .. ": journal state after the surrender")
	end
end
