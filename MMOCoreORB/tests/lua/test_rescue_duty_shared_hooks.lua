-- The two shared changes of space-quest-rescue-duty: SpaceAttackWaves.notifyAttackShipKilled and
-- SpaceRescueScreenplay.shouldSendInProgress. Both default to behavior that keeps survival, delivery and
-- rescue unchanged. Spec: .claude/work/space-quest-rescue-duty/01-spec.md (AC-9, Shared code changes 1 and 2).
-- The existing survival, delivery and rescue test files are not modified; they prove the no-regression half.

local lu = require("luaunit")
local H = require("harness")
local R = require("rescue_scenario")
local DR = require("rescue_duty_scenario")

DR.load()

local function secs(n) return n * 1000 end

local function mixin()
	return H.expectGlobal("SpaceAttackWaves", "screenplays/space/SpaceAttackWaves.lua")
end

local function countMessages(player, id)
	local n = 0

	for _, e in ipairs(H.messageLog(player)) do
		if e.id == id then
			n = n + 1
		end
	end

	return n
end

TestKillHook = {}

function TestKillHook:setUp() H.reset() end

-- AC-9
function TestKillHook:test_the_mixin_provides_the_kill_hook()
	lu.assertEquals(type(mixin().notifyAttackShipKilled), "function", "SpaceAttackWaves.notifyAttackShipKilled")
end

-- AC-9
function TestKillHook:test_survival_delivery_and_rescue_keep_the_default_and_the_duty_has_its_override()
	for _, host in ipairs({ "SpaceSurvivalScreenplay", "SpaceDeliveryScreenplay", "SpaceRescueScreenplay" }) do
		lu.assertEquals(type(rawget(_G[host], "notifyAttackShipKilled")), "function", host .. " has the hook as a raw field (mixed in)")
		lu.assertEquals(rawget(_G[host], "notifyAttackShipKilled"), mixin().notifyAttackShipKilled, host .. " uses the mixin's default")
	end

	local own = rawget(SpaceDutyRescueScreenplay, "notifyAttackShipKilled")

	lu.assertEquals(type(own), "function", "SpaceDutyRescueScreenplay overrides notifyAttackShipKilled")
	lu.assertNotEquals(own, mixin().notifyAttackShipKilled, "and it is not the default")
end

-- AC-9
function TestKillHook:test_the_default_hook_does_nothing()
	local player = H.newPlayer({ zone = "space_dantooine", ship = {} })
	local before = H.Engine.sharedMemoryKeys()

	lu.assertEquals(type(mixin().notifyAttackShipKilled), "function", "SpaceAttackWaves.notifyAttackShipKilled")
	lu.assertNil(mixin().notifyAttackShipKilled({}, player, 3), "returns nothing")
	lu.assertEquals(H.Engine.sharedMemoryKeys(), before, "writes nothing")
	lu.assertEquals(#H.Engine.callsTo("createEvent"), 0, "schedules nothing")
	lu.assertEquals(#player.messageLog, 0, "sends nothing")
end

-- AC-9: a 3-ship wave, called with 2, 1, 0 before the remaining / stopped messages
function TestKillHook:test_a_three_ship_wave_calls_the_hook_with_2_1_0_after_the_wave_count_is_written_and_before_the_messages()
	local sc = DR.fresh(DR.REP)
	local ships3 = sc.o.lists[3]

	lu.assertEquals(#ships3, 3, "sanity: Havoc list 3 has 3 ships")
	H.Engine.setRandom(1, sc.o.listCount, 3)

	local remainingId = "@space/quest:destroy_duty_targets_remaining"
	local stoppedId = "@spacequest/rescue_duty/" .. sc.name .. ":attack_stopped"
	local calls = H.spyOn(sc.quest, "notifyAttackShipKilled", function(self, pPlayer, remaining)
		return {
			remainingMessages = countMessages(pPlayer, remainingId),
			stopped = countMessages(pPlayer, stoppedId),
			waveLive = readData(self:dataKey(pPlayer.objectID, "waveLive:1")),
		}
	end)

	sc:toEscort()
	sc:atEscort(secs(sc.o.period))

	local wave = sc:wave(1)

	lu.assertEquals(DR.names(wave), ships3, "the wave is list 3")
	DR.killWave(sc, wave)

	lu.assertEquals(#calls, 3, "once per kill")

	for i, remaining in ipairs({ 2, 1, 0 }) do
		lu.assertEquals(calls[i].args[2], remaining, "kill " .. i .. ": remaining")
		lu.assertEquals(calls[i].self, sc.quest, "kill " .. i .. ": called on the host")
		lu.assertEquals(calls[i].args[1], sc.player, "kill " .. i .. ": for the player")
		lu.assertEquals(calls[i].snapshot.waveLive, remaining, "kill " .. i .. ": the wave's live count was already written")
		lu.assertEquals(calls[i].snapshot.remainingMessages, i - 1, "kill " .. i .. ": destroy_duty_targets_remaining not yet sent for this kill")
		lu.assertEquals(calls[i].snapshot.stopped, 0, "kill " .. i .. ": attack_stopped not yet sent")
	end

	lu.assertEquals(countMessages(sc.player, remainingId), 2, "targets_remaining sent for the first two kills")
	lu.assertEquals(countMessages(sc.player, stoppedId), 1, "attack_stopped after the last kill")
end

-- AC-9: a plain rescue (default hook) keeps its wave behavior; a spy proves the hook fires per kill there too
function TestKillHook:test_a_plain_rescue_wave_fires_the_hook_per_kill_and_keeps_its_messages()
	local sc = R.fresh(R.REP)
	local calls = H.spyOn(sc.quest, "notifyAttackShipKilled")

	sc:toEscort()
	sc:atEscort(sc.o.period * 1000)

	local wave = R.wave(sc, 1)

	R.killWave(sc, wave)

	local remaining = {}

	for i, c in ipairs(calls) do
		remaining[i] = c.args[2]
	end

	lu.assertEquals(remaining, { 5, 4, 3, 2, 1, 0 }, "remaining after each kill of the 6-ship wave")
	lu.assertEquals(R.count(sc:events(), "targets_remaining", "message"), 5, "targets_remaining for kills 1 to 5")
end

TestInProgressHook = {}

function TestInProgressHook:setUp() H.reset() end

-- AC-9
function TestInProgressHook:test_the_base_class_answers_true()
	local c = H.expectGlobal("SpaceRescueScreenplay", "screenplays/space/SpaceRescueScreenplay.lua")

	lu.assertEquals(type(c.shouldSendInProgress), "function", "SpaceRescueScreenplay.shouldSendInProgress")
	lu.assertEquals(c:shouldSendInProgress(1234), true, "returns true")
end

-- AC-9
function TestInProgressHook:test_every_plain_rescue_quest_inherits_it_and_answers_true()
	R.load()

	for _, name in ipairs(R.NAMES) do
		local q = H.expectGlobal(R.global(name))

		lu.assertEquals(type(q.shouldSendInProgress), "function", name .. ": shouldSendInProgress exists (SpaceRescueScreenplay)")
		lu.assertEquals(q:shouldSendInProgress(77), true, name .. ": true")
		lu.assertNil(rawget(q, "shouldSendInProgress"), name .. ": inherited, not overridden")
	end
end

-- AC-9
function TestInProgressHook:test_setup_asks_the_hook_with_the_player_id_and_sends_the_in_progress_message_only_when_it_says_yes()
	R.load()

	local sc = R.fresh(R.REP)
	local calls = H.spyOn(sc.quest, "shouldSendInProgress")

	sc:start()
	lu.assertEquals(#calls, 1, "asked once per setup")
	lu.assertEquals(calls[1].args[1], sc.player.objectID, "with the player's id")
	lu.assertEquals(R.count(sc:events(), "title", "progress"), 0, "the spy answers nothing (false): no quest_in_progress")
	lu.assertEquals(R.count(sc:events(), "arrival_phase_1", "update"), 1, "arrival_phase_1 is sent regardless")

	H.reset()

	local sc2 = R.fresh(R.REP)

	sc2:start()
	lu.assertEquals(R.count(sc2:events(), "title", "progress"), 1, "the real hook says yes: quest_in_progress sent")
end

-- AC-9: a rescue's second and later runs still send the in-progress message
function TestInProgressHook:test_a_plain_rescue_sends_the_in_progress_message_on_every_run()
	R.load()

	local sc = R.fresh(R.REP)

	sc:start()
	lu.assertEquals(R.count(sc:events(), "title", "progress"), 1, "first run")
	sc.quest:failQuest(sc.player, "false")
	lu.assertFalse(sc:active(), "failed")
	sc:start()
	lu.assertEquals(R.count(sc:events(), "title", "progress"), 2, "second run sends it again")
	sc.quest:failQuest(sc.player, "false")
	sc:start()
	lu.assertEquals(R.count(sc:events(), "title", "progress"), 3, "third run too")
end

-- AC-9: the duty answers true only for its first rescue
function TestInProgressHook:test_the_duty_answers_true_only_while_cycle_is_zero()
	local sc = DR.fresh(DR.REP)

	lu.assertEquals(sc.quest:shouldSendInProgress(sc.player.objectID), true, "no state: cycle 0")
	writeData(sc:key("cycle"), 1)
	lu.assertEquals(sc.quest:shouldSendInProgress(sc.player.objectID), false, "cycle 1")
	writeData(sc:key("cycle"), 5)
	lu.assertEquals(sc.quest:shouldSendInProgress(sc.player.objectID), false, "cycle 5")
	deleteData(sc:key("cycle"))
	lu.assertEquals(sc.quest:shouldSendInProgress(sc.player.objectID), true, "cycle deleted: true again")
end
