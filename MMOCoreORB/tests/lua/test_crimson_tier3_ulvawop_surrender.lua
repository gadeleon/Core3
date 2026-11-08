-- Arnecio Ulvaw'op: surrendering the pilot profession and the talk that follows; the conversation leaves the surrender untouched.
-- Spec: .claude/work/crimson-phoenix-tier3-ulvawop/01-spec.md (AC-9 first bullet; Migration (player data: none); I-7).
--
-- Part A's resetUlvawopQuests (called by SpaceHelpers:surrenderPilot after Eker's reset and before Burke's) clears the seventeen journal entries and the eight status keys;
-- Socuna's reset removes EKER_PILOT_KEY. Part B adds no key, so nothing new is left behind: after a surrender the pilot is no pilot.

local lu = require("luaunit")
local H = require("harness")
local T = require("crimson_tier3_data")

T.loadConversation()

local function surrender(player)
	SpaceHelpers:surrenderPilot(player)

	-- the engine derives pilot status from the novice box the surrender removes; the fake keeps the field, so the test says what the engine would
	if not CreatureObject(player):hasSkill("pilot_rebel_navy_novice") then
		player.pilot = nil
	end

	return player
end

TestUlvawopConvoSurrender = {}

function TestUlvawopConvoSurrender:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-9: after the surrender the next talk with Ulvaw'op opens not_pilot, whatever tier 3 state the pilot had
function TestUlvawopConvoSurrender:test_the_next_talk_after_a_surrender_opens_not_pilot()
	local builders = {
		{ name = "ready for mission 1", build = function() return T.pilot({}) end },
		{ name = "mission 2 won, reward owed", build = function() return T.pilot({ missions = 1, t3 = 1, state = "won" }) end },
		{ name = "mission 3 running", build = function() return T.pilot({ missions = 2, t3 = 2, state = "active" }) end },
		{ name = "tier 3 graduate", build = function() return T.pilot({ missions = 4, t3 = 4 }) end },
	}

	for _, b in ipairs(builders) do
		H.reset()

		local player = b.build()

		surrender(player)
		lu.assertFalse(CreatureObject(player):hasSkill("pilot_rebel_navy_novice"), b.name .. ": the pilot box is gone")
		lu.assertEquals(T.firstScreen(player), "not_pilot", b.name .. ": the next talk")
	end
end

-- AC-9, I-7: a pilot who used the conversation (offer accepted, mission won, paid, a skill chosen) leaves no Ulvaw'op state after a surrender
function TestUlvawopConvoSurrender:test_a_pilot_who_used_the_conversation_leaves_no_ulvawop_state_after_a_surrender()
	local player = T.pilot({})

	T.spyStarts()
	T.talk(player, (T.walkTo("m1_offer", "m1_accept_d5bf212f")))

	for _, global in ipairs(T.CHAINS[1]) do
		T.setState(player, global, "complete")
	end

	T.talk(player, { T.TRAIN[1].reply })
	lu.assertEquals(T.paid(player, 1), "1", "precondition: mission 1 is paid")
	surrender(player)

	for _, key in ipairs(T.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, T.EKER_PILOT_KEY), "EKER_PILOT_KEY after the surrender")

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "none", global .. ": journal state after the surrender")
	end
end
