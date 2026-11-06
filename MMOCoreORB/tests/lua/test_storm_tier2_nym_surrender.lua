-- Storm tier 2, the Nym technicians: surrendering the pilot profession removes the tip key together with everything Oberhaur's reset removes, and leaves all
-- three technicians ambient (stage none).
-- Spec: .claude/work/storm-tier2-nym-technicians/01-spec.md (AC-10; Content contract 1 (resetOberhaurQuests); D-3; I-8 (SH unchanged)).
--
-- SpaceHelpers:surrenderPilot picks the resets by the pilot's squadron (the Storm branch already calls resetOberhaurQuests, so space_helpers.lua does not
-- change). The fake creature derives its pilot status from the `pilot` field; the test re-enlists the pilot by hand, as test_storm_tier2_surrender.lua does.

local lu = require("luaunit")
local H = require("harness")
local T = require("storm_tier2_data")
local N = require("storm_tier2_nym_data")

N.load()

TestStormNymSurrender = {}

function TestStormNymSurrender:setUp()
	H.reset()
	N.load()
end

-- The keys Oberhaur's reset removes (OS AC-13) plus the tip key
local function keys()
	local out = T.statusKeys()

	for _, suffix in ipairs(T.FLAG_SUFFIXES) do
		out[#out + 1] = suffix
	end

	out[#out + 1] = N.TIP_SUFFIX

	return out
end

-- Re-enlists the pilot as a fresh Storm pilot (what Colzet's sign-up leaves), no promotion yet
local function reEnlist(player)
	player.pilot = "imperial"
	player.ghost.squadronType = STORM_SQUADRON
	player.ghost.factionStanding.imperial = 0
	player.faction = FACTIONIMPERIAL
	player.skills[T.NOVICE] = true
end

for _, stage in ipairs({ "briefed", "tipped", "active", "failed", "won" }) do
	-- AC-10: the tip key and every Oberhaur key are gone, the Claw's journal entry too
	TestStormNymSurrender["test_surrendering_at_stage_" .. stage .. "_removes_the_tip_key_and_every_oberhaur_key"] = function()
		local player = N.pilot({ stage = stage })

		lu.assertEquals(N.tip(player), stage ~= "briefed" and "1" or nil, "precondition: the tip key at stage " .. stage)

		SpaceHelpers:surrenderPilot(player)

		for _, key in ipairs(keys()) do
			lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender at stage " .. stage)
		end

		lu.assertEquals(N.claw(player), "none", "the Claw's journal entry after the surrender at stage " .. stage)
	end

	-- AC-10: all three technicians are then stage none (ambient) for the re-enlisted pilot
	TestStormNymSurrender["test_after_a_surrender_at_stage_" .. stage .. "_all_three_technicians_are_ambient_again"] = function()
		N.requireAll(lu)

		local player = N.pilot({ stage = stage })

		SpaceHelpers:surrenderPilot(player)
		reEnlist(player)
		lu.assertEquals(N.squadron(lu):getClawStage(player), "none", "getClawStage after the surrender at stage " .. stage)

		for n = 1, 3 do
			lu.assertEquals(N.firstScreen(n, player), "greeting", N.CONVOS[n].role .. " after the surrender at stage " .. stage)
		end
	end
end

-- AC-10: the tip key is the one new removal; a paid Claw's pilot loses it too
function TestStormNymSurrender:test_surrendering_after_the_claw_is_paid_removes_the_tip_key()
	local player = N.pilot({ stage = "paid" })

	lu.assertEquals(N.tip(player), "1", "precondition: the tip key is left by claw_pay")
	SpaceHelpers:surrenderPilot(player)
	lu.assertNil(N.tip(player), "the tip key after the surrender")
end

-- AC-10: the reset calls stay Colzet, Oberhaur, Declann (SH is unchanged), and the surrender with no technician state raises nothing
function TestStormNymSurrender:test_surrendering_with_no_technician_state_raises_no_error()
	local player = N.pilot({ stage = "none" })
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertNil(N.tip(player), "no tip key")
end

-- AC-10: the tip key is only removed by a Storm pilot's reset; resetOberhaurQuests is the one place (calling it directly removes it)
function TestStormNymSurrender:test_resetOberhaurQuests_removes_the_tip_key_and_leaves_tier_1_alone()
	local SS = T.squadron()
	local player = N.pilot({ stage = "tipped" })

	H.setQuestStatus(player, T.SERIES_SUFFIX, "1")
	SS:resetOberhaurQuests(player)
	lu.assertNil(N.tip(player), "the tip key after the reset")
	lu.assertEquals(H.getQuestStatus(player, T.SERIES_SUFFIX), "1", "Colzet's promotion flag is not Oberhaur's business")
end
