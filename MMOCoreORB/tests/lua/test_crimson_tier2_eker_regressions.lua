-- Major Eker: what the conversation must not do (no viopaSmuggler write, no foreign status key) and the surrender that follows (AC-10).
-- Spec: .claude/work/crimson-phoenix-tier2-eker-convo/01-spec.md (AC-10; FE-9; I-3, I-7; Migration (player data: none); Q-1 = A).
--
-- JE copies Havoc's Viopa script: its smuggler flag (viopaSmuggler = 3 on "At this point, we can't afford NOT to buy it...") is Havoc's HavocSquadron:viopaSmuggler
-- in Core3 and would open Vrak's confrontation for a Crimson Phoenix pilot. Q-1 = A: no screen writes it.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier2_data")
local M = require("migration_scenario")

E.loadConversation()

local function setUp()
	H.reset()
	E.requireConversation(lu)
end

local function surrender(player)
	SpaceHelpers:surrenderPilot(player)

	-- the engine derives pilot status from the novice box the surrender removes; the fake keeps the field, so the test says what the engine would
	if not CreatureObject(player):hasSkill(E.NOVICE or "pilot_rebel_navy_novice") then
		player.pilot = nil
	end

	return player
end

local function statusCopy(player)
	local out = {}

	for k, v in pairs(M.snapshot(player).status) do
		out[k] = v
	end

	return out
end

TestEkerNoViopa = {}

TestEkerNoViopa.setUp = setUp

-- AC-10, Q-1 = A: the M4 "buy it" walk shows m4_buy_it and writes no viopaSmuggler key
function TestEkerNoViopa:test_the_m4_buy_it_walk_writes_no_viopa_smuggler_key()
	local player = E.pilot({ graduated = "2", missions = 3, t2 = 4 })

	E.spyStarts()

	local t = E.talk(player, { "s_4431cbae", "s_f930a587", "s_39acc227", "s_6c251948" })

	lu.assertEquals(E.ids(t), { "m4_offer", "m4_never_better", "m4_price", "m4_buy_it", "m4_accept_smuggle" }, "the walk through m4_buy_it")
	lu.assertNil(H.getQuestStatus(player, E.VIOPA_KEY), "HavocSquadron:viopaSmuggler")
	lu.assertEquals(H.getQuestStatus(player, E.STATUS[4] .. ":attempted"), "1", "the walk still starts mission 4")
end

-- AC-10: m4_buy_it itself has no action: shown alone it changes nothing at all
function TestEkerNoViopa:test_m4_buy_it_alone_changes_no_state()
	local player = E.pilot({ graduated = "2", missions = 3, t2 = 4 })
	local before = M.snapshot(player)

	E.spyStarts()
	E.drive(player, "m4_buy_it")
	lu.assertEquals(M.snapshot(player).status, before.status, "status keys after m4_buy_it")
end

-- AC-10, I-7: no screen writes the viopaSmuggler key, for any kind of pilot
function TestEkerNoViopa:test_no_screen_writes_the_viopa_smuggler_key()
	for _, row in ipairs(E.SCREENS) do
		for _, flag in ipairs({ "1", "2", "3" }) do
			H.reset()
			E.spyStarts()

			local player = E.pilot({ graduated = flag, missions = 3, t2 = 4, state = "won", xp = 999999, privileged = true })

			E.drive(player, row.id)
			lu.assertNil(H.getQuestStatus(player, E.VIOPA_KEY), "screen '" .. row.id .. "' (flag " .. flag .. "): HavocSquadron:viopaSmuggler")
		end
	end
end

-- I-7: every status key a screen sets is one of the 8 Part A keys or EKER_PILOT_KEY: nothing else is written and nothing is removed
function TestEkerNoViopa:test_every_status_key_a_screen_sets_is_a_part_a_key_or_the_eker_pilot_key()
	for _, row in ipairs(E.SCREENS) do
		H.reset()
		E.spyStarts()

		local player = E.pilot({ graduated = "1", missions = 0, t2 = 1, state = "won", xp = 999999, privileged = true })
		local allowed = { [player.objectID .. E.EKER_PILOT_KEY] = true }

		for _, suffix in ipairs(E.statusKeys()) do
			allowed[player.objectID .. suffix] = true
		end

		local before = statusCopy(player)

		E.drive(player, row.id)

		local after = statusCopy(player)

		for k, v in pairs(after) do
			if before[k] ~= v then
				lu.assertTrue(allowed[k] == true, "screen '" .. row.id .. "': wrote an unexpected key " .. tostring(k) .. " = " .. tostring(v))
			end
		end

		for k in pairs(before) do
			lu.assertNotNil(after[k], "screen '" .. row.id .. "': removed the key " .. tostring(k))
		end
	end
end

---------------------------------------------------------------------------------------------
-- Surrender (AC-10 second bullet)
---------------------------------------------------------------------------------------------

TestEkerConvoSurrender = {}

TestEkerConvoSurrender.setUp = setUp

-- AC-10: after the surrender the next talk with Eker opens not_pilot, for a pilot who was mid-tier 2, a flag-1 graduate, a tier 2 graduate and a mission runner
function TestEkerConvoSurrender:test_the_next_talk_after_a_surrender_opens_not_pilot()
	local builders = {
		{ name = "mid tier 2", build = function() return E.pilot({ graduated = "2", missions = 2, t2 = 2, state = "won" }) end },
		{ name = "flag 1 graduate", build = function() return E.pilot({ graduated = "1" }) end },
		{ name = "tier 2 graduate", build = function() return E.pilot({ missions = 4, t2 = 4, graduated = "3" }) end },
		{ name = "mission 3 running", build = function() return E.pilot({ graduated = "2", missions = 2, t2 = 3, state = "active" }) end },
	}

	for _, b in ipairs(builders) do
		H.reset()

		local player = b.build()

		surrender(player)
		lu.assertFalse(CreatureObject(player):hasSkill("pilot_rebel_navy_novice"), b.name .. ": the pilot box is gone")
		lu.assertEquals(E.firstScreen(player), "not_pilot", b.name .. ": the next talk")
	end
end

-- AC-10: a pilot who used the conversation (hand-in, a skill, a mission started, won and paid) leaves no Eker state after a surrender
function TestEkerConvoSurrender:test_a_pilot_who_used_the_conversation_leaves_no_eker_state_after_a_surrender()
	local player = E.pilot({ graduated = "1", xp = 5 * E.XP_COST })

	E.useSkillCosts()
	E.spyStarts()

	-- hand-in, a skill, mission 1 accepted and won, paid
	E.talk(player, { "s_6a1c47d9" })
	E.talk(player, { "s_dd2fd70", E.TRAIN[1].reply, E.TRAIN[1].yes[1] })
	E.talk(player, { "s_468ab4d3", "s_313aff7d", "s_f685a04e" })

	for _, global in ipairs(E.CHAINS[1]) do
		E.setState(player, global, "complete")
	end

	E.talk(player)
	lu.assertEquals(H.getQuestStatus(player, E.STATUS[1] .. ":reward"), "1", "precondition: mission 1 is paid")
	lu.assertEquals(E.flag(player), "2", "precondition: the hand-in is done")

	surrender(player)

	for _, key in ipairs(E.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, E.EKER_PILOT_KEY), "EKER_PILOT_KEY after the surrender")

	for _, global in ipairs(E.GLOBALS) do
		lu.assertEquals(E.state(player, global), "none", global .. ": journal state after the surrender")
	end
end
