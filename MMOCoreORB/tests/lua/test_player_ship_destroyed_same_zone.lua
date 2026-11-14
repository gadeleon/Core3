-- A ZONESWITCHED to the zone the pilot is in (the respawn at a station after a ship death) is inert for Battle, Inspect, Rescue
-- (and rescue duty), Delivery (and no pickup) and Survival; a switch to another zone still produces today's outcome.
-- Spec: .claude/work/space-quest-player-ship-destroyed/01-spec.md (AC-8, C6, D-14)

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local PSD = require("psd_scenario")

PSD.load()

-- The seven quest types of C6 (rescue duty reaches the guard through SpaceRescueScreenplay.enteredZone)
local TYPES = { "space_battle", "inspect", "rescue", "rescue_duty", "delivery", "delivery_no_pickup", "survival" }

-- Methods of the events a leave-zone abandon queues (createEvent), none of which a same-zone switch may queue
local ABANDON_METHODS = { failQuest = true, abandonRun = true, abandonInspection = true, abandonDuty = true, failLeftZone = true }

local function abandonEvents(from)
	local out = {}

	for _, e in ipairs(AC.eventsSince(from)) do
		if ABANDON_METHODS[e.method] then
			out[#out + 1] = e.screenplay .. ":" .. e.method
		end
	end

	return out
end

TestSameZoneSwitchIsInert = {}

function TestSameZoneSwitchIsInert:setUp() H.reset() end
function TestSameZoneSwitchIsInert:tearDown() AC.tearDown() end

for _, questType in ipairs(TYPES) do
	-- AC-8: in the set-up state of the type's real run
	TestSameZoneSwitchIsInert["test_a_switch_to_the_zone_the_pilot_is_in_leaves_a_running_" .. questType .. "_alone"] = function()
		local run = AC.build(questType)
		local p = run.player
		local mark = #H.messageLog(p)
		local events = #H.Engine.callsTo("createEvent")
		local observers = AC.classObservers(p, run.className)
		local waypoints = #p.ghost.waypoints
		local keys = AC.ownKeys(p, run.className)

		H.zoneSwitch(p, p.zone)

		lu.assertEquals(abandonEvents(events), {}, run.className .. ": no abandon or fail event queued by the switch")

		-- right after the switch (a run keeps working afterwards: waypoints and keys move with it)
		lu.assertEquals(AC.classObservers(p, run.className), observers, run.className .. ": the quest's observers are untouched")
		lu.assertEquals(#p.ghost.waypoints, waypoints, run.className .. ": waypoints")
		lu.assertEquals(AC.ownKeys(p, run.className), keys, run.className .. ": the run's keys")
		lu.assertEquals(#H.messageLog(p), mark, run.className .. ": the switch itself sends nothing")

		H.advance(10 * 1000)

		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(p, run.questType, run.questName), run.className .. ": still active")
		lu.assertFalse(PlayerObject(p.ghost):isJournalQuestComplete(AC.crc(run)), run.className .. ": not complete")
		lu.assertEquals(PSD.leaks(p, mark), {}, run.className .. ": no abandoned/ended/won message")
		lu.assertEquals(PSD.failMessages(p, mark), {}, run.className .. ": no Mission Failed")
		lu.assertEquals(abandonEvents(events), {}, run.className .. ": no abandon or fail event queued afterwards")
	end

	-- AC-8: a switch to another zone is today's outcome: the run ends
	TestSameZoneSwitchIsInert["test_a_switch_to_another_zone_still_ends_a_running_" .. questType] = function()
		local run = AC.build(questType)
		local p = run.player
		local other = PSD.zoneOtherThan(run.q)

		if p.zone == other then other = "space_nowhere" end

		H.zoneSwitch(p, other)
		H.advance(10 * 1000)

		lu.assertFalse(SpaceHelpers:isSpaceQuestActive(p, run.questType, run.questName), run.className .. ": the run ended when the pilot left the zone")
	end
end

-- AC-8: every registered quest of the seven types: a same-zone switch in the in-progress state changes nothing
local GUARDED = { SpaceBattleScreenplay = true, SpaceInspectScreenplay = true, SpaceRescueScreenplay = true, SpaceDutyRescueScreenplay = true,
	SpaceDeliveryScreenplay = true, SpaceDeliveryNoPickupScreenplay = true, SpaceSurvivalScreenplay = true }

function TestSameZoneSwitchIsInert:test_the_zone_observer_of_every_registered_quest_of_the_seven_types_ignores_a_switch_to_the_pilots_zone()
	local problems, checked = {}, 0

	for _, entry in ipairs(PSD.quests()) do
		local q = entry.quest

		if GUARDED[PSD.baseOf(q)] then
			checked = checked + 1

			local ok, err = pcall(function()
				local player = PSD.accepted(q, q.questZone) -- in the quest zone

				PSD.inProgress(q, player)

				local before = #H.Engine.callsTo("createEvent")
				local mark = #H.messageLog(player)
				local result = q:enteredZone(player, nil, getHashCode(player.zone))

				if result ~= 0 then
					problems[#problems + 1] = entry.global .. ": enteredZone returned " .. tostring(result) .. " for the pilot's own zone, expected 0 (keep the observer)"
				end

				if #H.Engine.callsTo("createEvent") ~= before then
					problems[#problems + 1] = entry.global .. ": the same-zone switch scheduled an event"
				end

				if #H.messageLog(player) ~= mark then
					problems[#problems + 1] = entry.global .. ": the same-zone switch sent a message"
				end

				if not SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) then
					problems[#problems + 1] = entry.global .. ": no longer active"
				end
			end)

			if not ok then
				problems[#problems + 1] = entry.global .. ": raised " .. tostring(err)
			end
		end
	end

	lu.assertEquals(checked, 37 + 14 + 14 + 9 + 21 + 27 + 34, "Battle 37, Rescue 14, Delivery 14, Duty rescue 9, No pickup 21, Survival 27, Inspect 34")
	lu.assertEquals(PSD.summary(problems), {}, "quests whose zone observer reacts to a switch to the pilot's own zone")
end

-- AC-8: the other types keep their zone observers as they are (the guard is C6's five types only): a destroy duty still ends as won
-- when the pilot leaves for another zone
function TestSameZoneSwitchIsInert:test_the_unguarded_types_are_unchanged_and_a_destroy_duty_still_ends_as_won_on_leaving()
	local run = AC.build("destroy_duty")
	local p = run.player

	H.zoneSwitch(p, PSD.zoneOtherThan(run.q))
	H.advance(10 * 1000)

	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(p, run.questType, run.questName), "the duty ended")
	lu.assertTrue(PlayerObject(p.ghost):isJournalQuestComplete(AC.crc(run)), "as won (leaving the zone is a win without pay)")
end
