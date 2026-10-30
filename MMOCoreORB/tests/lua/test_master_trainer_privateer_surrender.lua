-- Privateers: surrendering the neutral pilot profession clears both admirals' progress (resetDeclannQuests and resetBurkeQuests), whatever the squadron.
-- Spec: .claude/work/space-master-trainer-privateer/01-spec.md (AC-10; Shared code changes; D-9; Q-2).
--
-- SpaceHelpers:surrenderPilot picks the profession by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to the admirals again.

local lu = require("luaunit")
local H = require("harness")
local P = require("master_trainer_privateer_data")
local I = require("master_trainer_imperial_data")
local R = require("master_trainer_rebel_data")
local CS = require("harness.client_strings")

P.load()

local NEUTRAL_SQUADRONS = { "corsec", "rsf", "smuggler" }

-- every kind of state of both admirals: both journals complete, the eight status keys, both side keys, the master skill
local function privateer(squadron, extra)
	local o = { kind = "neutral", squadron = squadron, paid = { 1, 2 }, master = true, keys = { imperial = true, rebel = true } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	local player = I.pilot(o)

	I.setState(player, "destroy_master_imperial_1", "complete")
	I.setState(player, "destroy_master_imperial_2", "complete")
	R.setState(player, "destroy_master_rebel_1", "complete")
	R.setState(player, "destroy_master_rebel_2", "complete")

	for _, key in ipairs({ "master_rebel_1:attempted", "master_rebel_1:reward", "master_rebel_2:attempted", "master_rebel_2:reward" }) do
		H.setQuestStatus(player, key, "1")
	end

	return player
end

TestMasterTrainerPrivateerSurrender = {}

function TestMasterTrainerPrivateerSurrender:setUp()
	H.reset()
	P.load()
end

-- AC-10 (the setup itself)
function TestMasterTrainerPrivateerSurrender:test_the_setup_carries_every_kind_of_state_of_both_admirals()
	local player = privateer("corsec")

	lu.assertEquals(I.state(player, "destroy_master_imperial_1"), "complete", "Declann mission 1 journal")
	lu.assertEquals(I.state(player, "destroy_master_imperial_2"), "complete", "Declann mission 2 journal")
	lu.assertEquals(R.state(player, "destroy_master_rebel_1"), "complete", "Burke mission 1 journal")
	lu.assertEquals(R.state(player, "destroy_master_rebel_2"), "complete", "Burke mission 2 journal")

	for _, key in ipairs(I.KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	for _, key in ipairs(R.KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertTrue(P.hasSkill(player, P.MASTER_SKILL), "pilot_neutral_master")
end

-- AC-10: both resets are called once for a CorSec, an RSF and a Smuggler pilot
function TestMasterTrainerPrivateerSurrender:test_a_neutral_surrender_calls_both_admirals_resets_once_for_every_neutral_squadron()
	for _, squadron in ipairs(NEUTRAL_SQUADRONS) do
		H.reset()

		local declann = H.spyOn(I.mts(), "resetDeclannQuests")
		local burke = H.spyOn(I.mts(), "resetBurkeQuests")
		local player = privateer(squadron)

		SpaceHelpers:surrenderPilot(player)
		lu.assertEquals(#declann, 1, squadron .. ": resetDeclannQuests calls")
		lu.assertEquals(#burke, 1, squadron .. ": resetBurkeQuests calls")
		lu.assertIs(declann[1].args[1], player, squadron .. ": resetDeclannQuests gets the player")
		lu.assertIs(burke[1].args[1], player, squadron .. ": resetBurkeQuests gets the player")
		lu.assertEquals(player.ghost.pilotTier, 0, squadron .. ": the surrender still resets the pilot tier")
	end
end

-- AC-10: after the squadron's own resets and before the skills are surrendered
function TestMasterTrainerPrivateerSurrender:test_both_resets_run_after_the_squadrons_own_resets_and_before_the_skills_go()
	local owners = {
		corsec = { global = "CorsecSquadronScreenplay", method = "resetTuroldineQuests" },
		rsf = { global = "RsfSquadronScreenplay", method = "resetImlerQuests" },
	}

	for _, squadron in ipairs(NEUTRAL_SQUADRONS) do
		H.reset()

		local order, heldDuring = {}, {}

		local function note(name)
			return function(_, p)
				order[#order + 1] = name
				heldDuring[name] = CreatureObject(p):hasSkill(P.MASTER_SKILL)
			end
		end

		local owner = owners[squadron]

		if owner ~= nil then
			H.spyOn(H.expectGlobal(owner.global, "the squadron screenplay"), owner.method, note("own"))
		end

		H.spyOn(I.mts(), "resetDeclannQuests", note("declann"))
		H.spyOn(I.mts(), "resetBurkeQuests", note("burke"))

		local player = privateer(squadron)

		SpaceHelpers:surrenderPilot(player)

		lu.assertEquals(#order, owner and 3 or 2, squadron .. ": reset calls in order: " .. table.concat(order, ", "))

		if owner then
			lu.assertEquals(order[1], "own", squadron .. ": the squadron's own tier 4 reset comes first")
			heldDuring.own = nil
		end

		local rest = { table.unpack(order, owner and 2 or 1) }

		table.sort(rest)
		lu.assertEquals(rest, { "burke", "declann" }, squadron .. ": both admirals' resets run once each after it")
		lu.assertTrue(heldDuring.declann, squadron .. ": the master skill is still held when resetDeclannQuests runs")
		lu.assertTrue(heldDuring.burke, squadron .. ": the master skill is still held when resetBurkeQuests runs")
		lu.assertFalse(CreatureObject(player):hasSkill(P.MASTER_SKILL), squadron .. ": and gone afterwards")
	end
end

-- AC-10: both side keys, all eight status keys, all four journal entries
function TestMasterTrainerPrivateerSurrender:test_a_neutral_surrender_clears_both_side_keys_all_eight_status_keys_and_all_four_journal_entries()
	for _, squadron in ipairs(NEUTRAL_SQUADRONS) do
		H.reset()

		local player = privateer(squadron)

		SpaceHelpers:surrenderPilot(player)

		for _, key in ipairs(I.KEYS) do
			lu.assertNil(H.getQuestStatus(player, key), squadron .. ": " .. key)
		end

		for _, key in ipairs(R.KEYS) do
			lu.assertNil(H.getQuestStatus(player, key), squadron .. ": " .. key)
		end

		for _, global in ipairs(I.GLOBALS) do
			lu.assertEquals(I.state(player, global), "none", squadron .. ": " .. global .. " journal")
		end

		for _, global in ipairs(R.GLOBALS) do
			lu.assertEquals(R.state(player, global), "none", squadron .. ": " .. global .. " journal")
		end
	end
end

-- AC-10: running missions go too
function TestMasterTrainerPrivateerSurrender:test_a_neutral_surrender_clears_a_running_master_mission_of_either_admiral()
	for _, squadron in ipairs(NEUTRAL_SQUADRONS) do
		H.reset()

		local player = I.pilot({ kind = "neutral", squadron = squadron, mission = { [1] = "active" }, keys = { imperial = true } })

		lu.assertEquals(I.state(player, "destroy_master_imperial_1"), "active", squadron .. ": precondition")
		SpaceHelpers:surrenderPilot(player)
		lu.assertEquals(I.state(player, "destroy_master_imperial_1"), "none", squadron .. ": Declann mission 1 journal after the surrender")

		local rebel = R.pilot({ kind = "neutral", squadron = squadron, mission = { [1] = "active" }, keys = { rebel = true } })

		lu.assertEquals(R.state(rebel, "destroy_master_rebel_1"), "active", squadron .. ": precondition")
		SpaceHelpers:surrenderPilot(rebel)
		lu.assertEquals(R.state(rebel, "destroy_master_rebel_1"), "none", squadron .. ": Burke mission 1 journal after the surrender")
	end
end

-- AC-10: pilot_neutral_master and the rest of the neutral skills are surrendered
function TestMasterTrainerPrivateerSurrender:test_a_neutral_surrender_removes_the_master_skill_and_every_neutral_pilot_skill()
	for _, squadron in ipairs(NEUTRAL_SQUADRONS) do
		H.reset()

		local player = privateer(squadron)

		SpaceHelpers:surrenderPilot(player)
		lu.assertFalse(P.hasSkill(player, P.MASTER_SKILL), squadron .. ": pilot_neutral_master after the surrender")

		for _, skill in ipairs(SpaceHelpers.pilotSkills.neutralPilot) do
			lu.assertFalse(P.hasSkill(player, skill), squadron .. ": " .. skill .. " after the surrender")
		end
	end
end

-- AC-10: the next talk at either admiral. The surrender keeps the squadron type (PlayerObject::resetPilotTier only zeroes the tier), so the squadron
-- refusals that are not state (P4: RSF at Burke, Smuggler at Declann) still apply; every state-driven screen is gone.
function TestMasterTrainerPrivateerSurrender:test_the_next_talk_at_either_admiral_opens_default_except_for_the_squadron_refusals()
	P.requireConversations(lu)

	local want = {
		corsec = { declann = "default", burke = "default" },
		rsf = { declann = "default", burke = "rsf_pilot" },
		smuggler = { declann = "smuggler", burke = "default" },
	}

	for _, squadron in ipairs(NEUTRAL_SQUADRONS) do
		for _, adm in ipairs(P.ORDER) do
			H.reset()

			local player = privateer(squadron)

			SpaceHelpers:surrenderPilot(player)
			player.pilot = nil -- the server derives the pilot kind from the skills that are gone

			local t = P.talk(adm, player)

			lu.assertEquals(P.ids(t), { want[squadron][adm] }, squadron .. " at " .. adm .. ": first screen after the surrender")
			lu.assertTrue(t[1].stop, "the screen ends the conversation")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-10, Q-2: the surrender is the only way out of the lock
function TestMasterTrainerPrivateerSurrender:test_a_locked_corsec_pilot_is_free_to_choose_again_after_the_surrender()
	P.requireConversations(lu)

	local player = privateer("corsec", { master = false, paid = {}, mission = {} })

	SpaceHelpers:surrenderPilot(player)

	-- the pilot trains again (the tier 4 skills come back) and the lock is gone
	for _, skill in ipairs(I.skillsOf("neutral", 4)) do
		player.skills[skill] = true
	end

	player.pilot = "neutral"
	player.ghost.squadronType = rawget(_G, "CORSEC_SQUADRON")
	lu.assertEquals(P.firstScreen("declann", player), "privateer_ready_corsec", "Declann")
	lu.assertEquals(P.firstScreen("burke", player), "privateer_ready_corsec", "Burke")
end

-- AC-10: Imperial pilots still call only the Declann reset, Rebel pilots only the Burke reset
function TestMasterTrainerPrivateerSurrender:test_imperial_pilots_call_only_the_declann_reset_and_rebel_pilots_only_the_burke_reset()
	local declann = H.spyOn(I.mts(), "resetDeclannQuests")
	local burke = H.spyOn(I.mts(), "resetBurkeQuests")

	for _, squadron in ipairs({ "black_epsilon", "storm", "inquisition" }) do
		local before = { #declann, #burke }

		SpaceHelpers:surrenderPilot(I.pilot({ squadron = squadron }))
		lu.assertEquals(#declann - before[1], 1, squadron .. ": resetDeclannQuests calls")
		lu.assertEquals(#burke - before[2], 0, squadron .. ": resetBurkeQuests calls")
	end

	for _, squadron in ipairs({ "havoc", "vortex", "crimson" }) do
		local before = { #declann, #burke }

		SpaceHelpers:surrenderPilot(R.pilot({ squadron = squadron }))
		lu.assertEquals(#declann - before[1], 0, squadron .. ": resetDeclannQuests calls")
		lu.assertEquals(#burke - before[2], 1, squadron .. ": resetBurkeQuests calls")
	end
end

-- AC-10: with MasterTrainerScreenplay absent a CorSec surrender works as before (the nil guard)
function TestMasterTrainerPrivateerSurrender:test_without_the_master_trainer_screenplay_a_neutral_surrender_still_works()
	for _, squadron in ipairs(NEUTRAL_SQUADRONS) do
		H.reset()

		local player = privateer(squadron)
		local saved = rawget(_G, "MasterTrainerScreenplay")

		_G.MasterTrainerScreenplay = nil

		local ok, err = pcall(function() SpaceHelpers:surrenderPilot(player) end)

		_G.MasterTrainerScreenplay = saved
		lu.assertTrue(ok, squadron .. ": surrenderPilot must not error without MasterTrainerScreenplay: " .. tostring(err))
		lu.assertEquals(player.ghost.pilotTier, 0, squadron .. ": the pilot tier is reset")
		lu.assertFalse(P.hasSkill(player, P.MASTER_SKILL), squadron .. ": the skills are surrendered")
	end
end
