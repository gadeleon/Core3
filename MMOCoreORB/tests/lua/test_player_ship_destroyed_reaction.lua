-- What a destroyed player ship does to a space quest: Mission Failed, the fail music and the type's silent teardown; and what it
-- leaves alone (an idle or an inactive quest).
-- Spec: .claude/work/space-quest-player-ship-destroyed/01-spec.md (AC-3, I-2, I-3, I-4, I-6)
--
-- Every test drives H.playerShipDestroyed (the fake of DestroyShipTask case 0): <questType>_<questName>:playerShipDestroyed(player)
-- for each space mission on the datapad.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local PSD = require("psd_scenario")

PSD.load()

local SETTLE = 30 * 1000 -- I-3: pump 30 s of events

local function needHook()
	lu.assertEquals(type(rawget(SpaceQuestLogic, "playerShipDestroyed")), "function",
		"expected SpaceQuestLogic:playerShipDestroyed (screenplays/space/SpaceQuestLogic.lua, Basic Quest Logic Functions)")
end

local function active(player, q) return SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) end

local function complete(player, q)
	return PlayerObject(CreatureObject(player):getPlayerObject()):isJournalQuestComplete(H.questCrc(q.questType, q.questName))
end

-- Counts of everything a death of an idle or inactive quest must not touch
local function quiet(player)
	return { messages = #H.messageLog(player), music = #player.music, events = #H.Engine.callsTo("createEvent"),
		missions = #player.datapad.items, observers = #H.Engine.observersOn(player), keys = #H.Engine.sharedMemoryKeys(),
		spawned = #H.spawnedShips(), areas = #H.spawnedAreas(), waypoints = #player.ghost.waypoints, bank = player.bankCredits }
end

---------------------------------------------------------------------------------------------
-- AC-3, I-3: a quest in progress fails once, one test per quest type, every registered quest of it
---------------------------------------------------------------------------------------------

TestShipDeathFailsQuest = {}

function TestShipDeathFailsQuest:setUp() H.reset() end

local function failProblem(entry)
	local q = entry.quest
	local player = PSD.accepted(q)

	PSD.inProgress(q, player)

	local spies = PSD.isolateRelated(q)
	local bank = player.bankCredits
	local mark = #H.messageLog(player)
	local music = #player.music

	local called = H.playerShipDestroyed(player)

	if #called ~= 1 or called[1] ~= entry.global then
		return "the dispatch called " .. table.concat(called, ",") .. " instead of " .. entry.global
	end

	H.advance(SETTLE)

	local fails = PSD.failMessages(player, mark)

	if #fails ~= 1 then return #fails .. " quest_failed messages, expected 1" end
	if fails[1] ~= PSD.title(q) then return "quest_failed TO is " .. tostring(fails[1]) .. ", expected " .. PSD.title(q) end

	local leaks = PSD.leaks(player, mark)

	if #leaks > 0 then return "messages that a ship death never sends: " .. table.concat(leaks, ", ") end
	if PSD.musicCount(player) ~= 1 then return PSD.musicCount(player) .. " plays of the fail music, expected 1" end
	if #player.music ~= music + 1 then return "other music was played too" end
	if active(player, q) then return "the journal entry is still active" end
	if complete(player, q) then return "the journal entry is complete" end
	if PSD.hasMission(player, q) then return "the mission is still on the datapad" end
	if player.bankCredits ~= bank then return "the bank changed by " .. tostring(player.bankCredits - bank) end

	-- the parent fails silently, as failQuest does today (AC-5)
	if q.parentQuestType ~= "" then
		local calls = spies.fail[q.parentQuestType .. "_" .. q.parentQuestName]

		if calls == nil or #calls ~= 1 or calls[1].args[2] ~= "false" then
			return "the parent was not failed once with \"false\""
		end
	end

	return nil
end

local bases = {}

for base, row in pairs(PSD.CLASSES) do
	if row.expect then
		bases[#bases + 1] = base
	end
end

table.sort(bases)

for _, base in ipairs(bases) do
	-- AC-3, I-3
	TestShipDeathFailsQuest["test_a_ship_death_fails_every_" .. base .. "_in_progress_once_with_mission_failed_and_the_fail_music"] = function()
		needHook()

		local problems = {}

		for _, entry in ipairs(PSD.byClass()[base]) do
			local ok, result = pcall(failProblem, entry)

			if not ok then
				problems[#problems + 1] = entry.global .. ": raised " .. tostring(result)
			elseif result ~= nil then
				problems[#problems + 1] = entry.global .. ": " .. result
			end
		end

		lu.assertEquals(PSD.summary(problems), {}, base .. ": quests that do not fail the SWG way on a ship death")
	end
end

---------------------------------------------------------------------------------------------
-- AC-3, I-2: nothing happens before the run is in progress, for an inactive quest, or twice
---------------------------------------------------------------------------------------------

TestShipDeathLeavesQuestAlone = {}

function TestShipDeathLeavesQuestAlone:setUp() H.reset() end

-- AC-3, I-2: accepted, not in the quest zone (and the type's own pre-progress states)
function TestShipDeathLeavesQuestAlone:test_a_quest_that_is_not_in_progress_stays_active_and_sends_nothing()
	needHook()

	local problems = {}

	for _, entry in ipairs(PSD.quests()) do
		local q = entry.quest
		local row = PSD.CLASSES[PSD.baseOf(q)]
		local states = { ["accepted, not in the quest zone"] = function() end }

		for name, fn in pairs(row.before) do
			states[name] = fn
		end

		for name, fn in pairs(states) do
			local ok, err = pcall(function()
				local player = PSD.accepted(q)

				fn(q, player)

				local before = quiet(player)

				H.playerShipDestroyed(player)
				H.advance(SETTLE)

				if not active(player, q) then problems[#problems + 1] = entry.global .. " [" .. name .. "]: no longer active" end
				if not PSD.hasMission(player, q) then problems[#problems + 1] = entry.global .. " [" .. name .. "]: the mission is gone" end

				local after = quiet(player)

				for k, v in pairs(before) do
					if after[k] ~= v then
						problems[#problems + 1] = entry.global .. " [" .. name .. "]: " .. k .. " changed from " .. tostring(v) .. " to " .. tostring(after[k])
					end
				end
			end)

			if not ok then
				problems[#problems + 1] = entry.global .. " [" .. name .. "]: raised " .. tostring(err)
			end
		end
	end

	lu.assertEquals(PSD.summary(problems), {}, "quests that react to a ship death before their run is in progress")
end

-- AC-3: a pilot who never took the quest, and one whose entry is complete: no message, no music, no event
function TestShipDeathLeavesQuestAlone:test_a_quest_the_pilot_does_not_hold_or_has_completed_does_nothing()
	needHook()

	local problems = {}

	for _, entry in ipairs(PSD.quests()) do
		local q = entry.quest

		if PSD.CLASSES[PSD.baseOf(q)].expect then
			local ok, err = pcall(function()
				-- never taken
				H.reset()

				local player = H.newPlayer({ zone = q.questZone })
				local before = quiet(player)

				PSD.inProgress(q, player) -- keys and tasks of a run that was never started on the journal
				q:playerShipDestroyed(player)
				H.advance(SETTLE)

				local after = quiet(player)

				after.keys, before.keys = nil, nil

				for k, v in pairs(before) do
					if after[k] ~= v then
						problems[#problems + 1] = entry.global .. " [never taken]: " .. k .. " changed"
					end
				end

				-- completed
				player = PSD.accepted(q)
				PSD.inProgress(q, player)
				SpaceHelpers:completeSpaceQuest(player, q.questType, q.questName, false)
				H.advance(SETTLE)

				before = quiet(player)
				q:playerShipDestroyed(player)
				H.advance(SETTLE)
				after = quiet(player)

				for k, v in pairs(before) do
					if after[k] ~= v then
						problems[#problems + 1] = entry.global .. " [completed]: " .. k .. " changed"
					end
				end
			end)

			if not ok then
				problems[#problems + 1] = entry.global .. ": raised " .. tostring(err)
			end
		end
	end

	lu.assertEquals(PSD.summary(problems), {}, "quests that react to a ship death without an active entry")
end

-- AC-3: a second death while nothing is left changes nothing (the first one ended the run)
function TestShipDeathLeavesQuestAlone:test_a_second_ship_death_after_the_fail_sends_nothing_more()
	needHook()

	for _, global in ipairs({ "destroy_duty_corellia_rebel_6", "patrol_corellia_privateer_1", "survival_corellia_rebel_tier4_1" }) do
		local q = H.expectGlobal(global, "quest table")
		local player = PSD.accepted(q)

		PSD.inProgress(q, player)
		PSD.isolateRelated(q)
		H.playerShipDestroyed(player)
		H.advance(SETTLE)

		lu.assertEquals(#PSD.failMessages(player), 1, global .. ": one quest_failed after the first death")
		H.playerShipDestroyed(player)
		H.advance(SETTLE)
		lu.assertEquals(#PSD.failMessages(player), 1, global .. ": still one quest_failed after the second death")
		lu.assertEquals(PSD.musicCount(player), 1, global .. ": the fail music once")
	end
end

-- AC-3 (the dispatch): a pilot holding two space missions at once: only the one in progress fails
function TestShipDeathLeavesQuestAlone:test_only_the_quest_in_progress_fails_when_the_datapad_holds_several()
	needHook()

	local running = H.expectGlobal("patrol_corellia_privateer_1", "patrol quest table")
	local idle = H.expectGlobal("inspect_corellia_rebel_tier3_2", "inspect quest table")
	local player = PSD.accepted(running)

	-- a second quest on the same pilot: taken but not started in its zone
	idle:startQuest(player, "")
	H.advance(0)
	PSD.inProgress(running, player)
	PSD.isolateRelated(running)

	local called = H.playerShipDestroyed(player)

	table.sort(called)
	lu.assertEquals(called, { "inspect_corellia_rebel_tier3_2", "patrol_corellia_privateer_1" }, "both missions were told")
	H.advance(SETTLE)
	lu.assertFalse(active(player, running), "the patrol in progress failed")
	lu.assertTrue(active(player, idle), "the inspection that was not in progress is still active")
	lu.assertEquals(PSD.failMessages(player), { PSD.title(running) }, "one Mission Failed, for the patrol")
end

---------------------------------------------------------------------------------------------
-- I-4: the teardown is the one failQuest(player, "false") does, for the 16 quest types' real runs
---------------------------------------------------------------------------------------------

TestShipDeathTeardownParity = {}

function TestShipDeathTeardownParity:setUp() H.reset() end
function TestShipDeathTeardownParity:tearDown() AC.tearDown() end

-- What a run leaves behind after `end` was called and every delayed teardown event ran
local function aftermath(run, endRun)
	local p = run.player
	local events = #H.Engine.callsTo("createEvent")
	local drops = #H.Engine.callsTo("dropObserver")
	local mark = #H.messageLog(p)

	endRun()
	H.advance(SETTLE)

	local ships = {}

	for i, ship in ipairs(H.spawnedShips()) do
		ships[i] = (ship.destroyed and "destroyed" or "alive") .. (ship.hyperspacing and "+hyperspacing" or "")
	end

	local areas = {}

	for i, area in ipairs(H.spawnedAreas()) do
		areas[i] = area.destroyed and "destroyed" or "alive"
	end

	local eventShape = {}

	for _, e in ipairs(AC.eventsSince(events)) do
		eventShape[#eventShape + 1] = tostring(e.screenplay) .. ":" .. tostring(e.method)
	end

	local messages = {}

	for _, m in ipairs(AC.messagesSince(p, mark)) do
		if m.id ~= PSD.MSG_FAILED then
			messages[#messages + 1] = m.id
		end
	end

	return {
		keys = AC.ownKeys(p, run.className),
		observers = AC.classObservers(p, run.className),
		waypoints = #p.ghost.waypoints,
		waypointVector = readStringVectorSharedMemory(p.objectID .. ":" .. run.className .. ":waypointVector"),
		ships = ships, areas = areas, events = eventShape, messages = messages,
		dropObserver = #H.Engine.callsTo("dropObserver") - drops,
		missionObjects = #p.missionObjects,
		active = SpaceHelpers:isSpaceQuestActive(p, run.questType, run.questName),
		complete = PlayerObject(p.ghost):isJournalQuestComplete(AC.crc(run)),
	}
end

for _, entry in ipairs(AC.TYPES) do
	-- I-4 (escorts are compared with failQuest(player, "false", true): no failure split)
	TestShipDeathTeardownParity["test_the_ship_death_of_a_running_" .. entry.type .. "_tears_down_like_fail_quest"] = function()
		needHook()

		local death = AC.build(entry.type)
		local a = aftermath(death, function() H.playerShipDestroyed(death.player) end)

		AC.tearDown() -- the recovery builders write resolved points into the quest tables
		H.reset() -- and do not reset the fake world themselves

		local fail = AC.build(entry.type)
		local isEscort = entry.type == "escort" or entry.type == "escort_duty"
		local b = aftermath(fail, function()
			if isEscort then
				fail.q:failQuest(fail.player, "false", true)
			else
				fail.q:failQuest(fail.player, "false")
			end
		end)

		for _, field in ipairs({ "keys", "observers", "waypoints", "waypointVector", "ships", "areas", "dropObserver", "missionObjects", "active", "complete", "events", "messages" }) do
			lu.assertEquals(a[field], b[field], entry.name .. ": " .. field .. " after the ship death differs from failQuest(player, \"false\")")
		end

		lu.assertFalse(a.active, entry.name .. ": not active")
		lu.assertFalse(a.complete, entry.name .. ": not complete")
	end
end

---------------------------------------------------------------------------------------------
-- I-6: the respawn after the death adds nothing for the failed quest
---------------------------------------------------------------------------------------------

TestShipDeathThenRespawn = {}

function TestShipDeathThenRespawn:setUp() H.reset() end
function TestShipDeathThenRespawn:tearDown() AC.tearDown() end

for _, entry in ipairs(AC.TYPES) do
	-- I-6 (timeline of the engine: death at t = 0, the respawn switch to the same zone at 12 s)
	TestShipDeathThenRespawn["test_the_respawn_after_the_ship_death_of_a_running_" .. entry.type .. "_adds_nothing"] = function()
		needHook()

		local run = AC.build(entry.type)
		local p = run.player

		H.playerShipDestroyed(p)
		H.advance(12 * 1000)

		local mark = #H.messageLog(p)
		local fails = #H.Engine.callsTo("failQuest")
		local events = #H.Engine.callsTo("createEvent")
		local pay = p.bankCredits

		H.zoneSwitch(p, p.zone)
		H.advance(SETTLE)

		lu.assertEquals(#AC.messagesSince(p, mark), 0, entry.name .. ": no message after the respawn switch")
		lu.assertEquals(#AC.eventsSince(events, "failQuest"), 0, entry.name .. ": no second failQuest after the respawn switch")
		lu.assertEquals(#AC.eventsSince(events, "startQuest"), 0, entry.name .. ": no second split after the respawn switch")
		lu.assertEquals(p.bankCredits, pay, entry.name .. ": no pay")
		lu.assertEquals(#PSD.failMessages(p), 1, entry.name .. ": still exactly one Mission Failed")
		lu.assertEquals(PSD.musicCount(p), 1, entry.name .. ": still exactly one fail music")
	end
end
