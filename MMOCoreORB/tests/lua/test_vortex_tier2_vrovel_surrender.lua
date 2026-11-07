-- Brother Vrovel: surrendering the pilot profession and the talk that follows; the other parts of the feature leave the surrender untouched.
-- Spec: .claude/work/vortex-tier2-vrovel/01-spec.md (AC-10 first bullet; Scope Out "Any quest-table, split or surrender change"; Migration (player data: none)).
--
-- Part A's resetVrovelQuests (called by SpaceHelpers:surrenderPilot between V3-FX's reset and Burke's) clears the nine journal entries and the eight status
-- keys; V3-FX's reset removes VORTEX_PILOT_KEY. Part B adds no key of its own, so nothing new is left behind: after a surrender the pilot is no pilot.

local lu = require("luaunit")
local H = require("harness")
local V = require("vortex_tier2_data")

V.loadConversation()

local function surrender(player)
	SpaceHelpers:surrenderPilot(player)

	-- the engine derives pilot status from the novice box the surrender removes; the fake keeps the field, so the test says what the engine would
	if not CreatureObject(player):hasSkill(V.NOVICE) then
		player.pilot = nil
	end

	return player
end

TestVrovelConvoSurrender = {}

function TestVrovelConvoSurrender:setUp()
	H.reset()
	V.requireConversation(lu)
end

-- AC-10: after the surrender the next talk with Vrovel opens not_pilot, for a pilot who was mid-tier 2, a flag-1 graduate and a tier 2 graduate
function TestVrovelConvoSurrender:test_the_next_talk_after_a_surrender_opens_not_pilot()
	local builders = {
		{ name = "mid tier 2", build = function() return V.pilot({ missions = 2, t2 = 2, state = "won" }) end },
		{ name = "flag 1 graduate", build = function() return V.pilot({ graduated = "1" }) end },
		{ name = "tier 2 graduate", build = function() return V.pilot({ missions = 4, t2 = 4, graduated = "3" }) end },
		{ name = "mission 3 running", build = function() return V.pilot({ missions = 2, t2 = 3, state = "active" }) end },
	}

	for _, b in ipairs(builders) do
		H.reset()

		local player = b.build()

		surrender(player)
		lu.assertFalse(CreatureObject(player):hasSkill(V.NOVICE), b.name .. ": the pilot box is gone")
		lu.assertEquals(V.firstScreen(player), "not_pilot", b.name .. ": the next talk")
	end
end

-- AC-10: Vrovel's conversation writes nothing the surrender leaves behind: a pilot who walked the hand-in, bought skills, started and won missions is clean after it
function TestVrovelConvoSurrender:test_a_pilot_who_used_the_conversation_leaves_no_vrovel_state_after_a_surrender()
	local player = V.pilot({ graduated = "1", xp = 5 * V.XP_COST })

	V.useSkillCosts()
	V.spyStarts()

	-- hand-in, a skill, mission 1 accepted and won, paid, a duty
	V.talk(player, { "s_45236b6c", "s_e788dfef" })
	V.talk(player, { "s_9b8d2abd", V.TRAIN[1].reply, V.TRAIN[1].yes[1] })
	V.talk(player, { "s_77213dae", "s_92aee067" })

	for _, global in ipairs(V.CHAINS[1]) do
		V.setState(player, global, "complete")
	end

	V.talk(player)
	V.talk(player, { "s_9b8d2abd" })
	lu.assertEquals(H.getQuestStatus(player, V.STATUS[1] .. ":reward"), "1", "precondition: mission 1 is paid")

	surrender(player)

	for _, key in ipairs(V.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, V.VORTEX_PILOT_KEY), "VORTEX_PILOT_KEY after the surrender")

	for _, global in ipairs(V.GLOBALS) do
		lu.assertEquals(V.state(player, global), "none", global .. ": journal state after the surrender")
	end
end
