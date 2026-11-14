-- A ship death in progress: the failure split starts once (not for escorts), the completion split never, the parent fails silently,
-- and the respawn switch that follows does not abandon the child the death started.
-- Spec: .claude/work/space-quest-player-ship-destroyed/01-spec.md (AC-5, AC-7, C5, D-13)

local lu = require("luaunit")
local H = require("harness")
local DRS = require("duty_rules_scenario")
local PSD = require("psd_scenario")

PSD.load()

local RSF_IMLER_ESCORT = "escort_naboo_privateer_tier4_4b"
local FAILURE, BIDIRECTIONAL = 2, 3

local function needHook()
	lu.assertEquals(type(rawget(SpaceQuestLogic, "playerShipDestroyed")), "function",
		"expected SpaceQuestLogic:playerShipDestroyed (screenplays/space/SpaceQuestLogic.lua, Basic Quest Logic Functions)")
end

local function failureChild(q)
	if q.sideQuest and (q.sideQuestSplitType == FAILURE or q.sideQuestSplitType == BIDIRECTIONAL) then
		return q.sideFailQuestType .. "_" .. q.sideFailQuestName
	end
end

-- The quests that split on a failure (Content counts: Havoc 4, CorSec 1, Smuggler 1, Crimson 4, Vortex 4, RSF 1, Tatooine palace 1)
local function failureSplitQuests()
	local out = {}

	for _, entry in ipairs(PSD.quests()) do
		if failureChild(entry.quest) then
			out[#out + 1] = entry
		end
	end

	return out
end

-- startQuest events of `child` that the quest has scheduled since `from` createEvent calls
local function startEvents(from, child)
	local out = {}
	local all = H.Engine.callsTo("createEvent")

	for i = from + 1, #all do
		local c = all[i]

		if c[2] == child and c[3] == "startQuest" then
			out[#out + 1] = { delay = c[1] }
		end
	end

	return out
end

TestShipDeathSplits = {}

function TestShipDeathSplits:setUp() H.reset() end

-- AC-5: the 16 quests of the Content counts, among them the escort that does not split
function TestShipDeathSplits:test_sixteen_quests_split_on_a_failure()
	local list = failureSplitQuests()
	local names = {}

	for _, entry in ipairs(list) do names[#names + 1] = entry.global end

	lu.assertEquals(#list, 16, "quests with a FAILURE or BIDIRECTIONAL split: " .. table.concat(names, ", "))
	lu.assertNotNil(rawget(_G, RSF_IMLER_ESCORT), "RSF Imler's " .. RSF_IMLER_ESCORT .. " is registered")
	lu.assertNotNil(failureChild(_G[RSF_IMLER_ESCORT]), RSF_IMLER_ESCORT .. " has a failure split on a failure that is not a ship death")
end

-- AC-5: failure split once (16 quests); none for the escort; no split for any other quest, whatever its completion split
function TestShipDeathSplits:test_the_failure_split_starts_once_and_only_for_the_quests_that_have_one()
	needHook()

	local problems = {}

	for _, entry in ipairs(PSD.quests()) do
		local q = entry.quest

		if PSD.CLASSES[PSD.baseOf(q)].expect then
			local ok, err = pcall(function()
				local player = PSD.accepted(q)

				PSD.inProgress(q, player)

				local spies = PSD.isolateRelated(q)
				local from = #H.Engine.callsTo("createEvent")
				local child = failureChild(q)

				H.playerShipDestroyed(player)
				H.advance(30 * 1000)

				local wantChild = child
				local isEscort = PSD.baseOf(q) == "SpaceEscortScreenplay" or PSD.baseOf(q) == "SpaceDutyEscortScreenplay"

				if isEscort then
					wantChild = nil -- D-13: SWG QL/escort_duty:741, questFailed(self, false)
				end

				for name, calls in pairs(spies.start) do
					local want = (name == wantChild) and 1 or 0

					if #calls ~= want then
						problems[#problems + 1] = entry.global .. ": startQuest of " .. name .. " ran " .. #calls .. " times, expected " .. want
					end
				end

				if wantChild then
					local events = startEvents(from, wantChild)

					if #events ~= 1 then
						problems[#problems + 1] = entry.global .. ": " .. #events .. " startQuest events for " .. wantChild .. ", expected exactly 1"
					elseif events[1].delay ~= q.sideQuestDelay * 1050 then
						problems[#problems + 1] = entry.global .. ": the split starts after " .. events[1].delay .. " ms, expected sideQuestDelay * 1050"
					end
				elseif child then
					if #startEvents(from, child) ~= 0 then
						problems[#problems + 1] = entry.global .. ": an escort scheduled its failure split on a ship death"
					end
				end
			end)

			if not ok then
				problems[#problems + 1] = entry.global .. ": raised " .. tostring(err)
			end
		end
	end

	lu.assertEquals(PSD.summary(problems), {}, "quests whose splits on a ship death are not SWG's")
end

-- AC-5, D-13: RSF Imler's escort ends the run without starting space_battle_naboo_privateer_tier4_4c_lose
function TestShipDeathSplits:test_the_escort_of_the_imler_battle_chain_ends_without_its_failure_split()
	needHook()

	local q = H.expectGlobal(RSF_IMLER_ESCORT, "escort quest table")
	local player = PSD.accepted(q)

	PSD.inProgress(q, player)

	local spies = PSD.isolateRelated(q)

	H.playerShipDestroyed(player)
	H.advance(30 * 1000)

	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), "the escort failed")
	lu.assertEquals(#spies.start["space_battle_naboo_privateer_tier4_4c_lose"], 0, "no failure split")
	lu.assertEquals(#spies.start["space_battle_naboo_privateer_tier4_4c_win"], 0, "no completion split")
	lu.assertEquals(#PSD.failMessages(player), 1, "Mission Failed once")
end

-- C5: the third parameter of SpaceEscortScreenplay:failQuest skips the split; two arguments (every existing caller) still split
function TestShipDeathSplits:test_escort_fail_quest_skips_the_failure_split_only_with_the_third_argument()
	local q = H.expectGlobal(RSF_IMLER_ESCORT, "escort quest table")

	for _, skip in ipairs({ false, true }) do
		local player = PSD.accepted(q)

		PSD.inProgress(q, player)

		local from = #H.Engine.callsTo("createEvent")
		local child = failureChild(q)

		if skip then
			q:failQuest(player, "false", true)
		else
			q:failQuest(player, "false")
		end

		lu.assertEquals(#startEvents(from, child), skip and 0 or 1, "failure split events with skipFailureSplit = " .. tostring(skip))
	end
end

-- AC-5 (Assassinate): keeps its failure split on a ship death
function TestShipDeathSplits:test_an_assassinate_keeps_its_failure_split()
	needHook()

	local q = H.expectGlobal("assassinate_corellia_rebel_tier4_2", "assassinate quest table")
	local player = PSD.accepted(q)

	PSD.inProgress(q, player)

	local spies = PSD.isolateRelated(q)

	H.playerShipDestroyed(player)
	H.advance(30 * 1000)

	lu.assertEquals(#spies.start["rescue_corellia_rebel_tier4_2_b"], 1, "the failure split (rescue ...2_b) started once")
	lu.assertEquals(#spies.start["delivery_no_pickup_corellia_rebel_tier4_2_a"], 0, "the completion child never starts")
end

---------------------------------------------------------------------------------------------
-- AC-7: the child that the death started survives the respawn switch (12 s after the death)
---------------------------------------------------------------------------------------------

TestShipDeathRespawnKeepsChild = {}

function TestShipDeathRespawnKeepsChild:setUp() H.reset() end

local CHILD_BASES = { SpaceBattleScreenplay = true, SpaceRescueScreenplay = true, SpaceDeliveryNoPickupScreenplay = true }

for _, entry in ipairs(failureSplitQuests()) do
	local child = failureChild(entry.quest)
	local childQuest = rawget(_G, child)

	if childQuest ~= nil and CHILD_BASES[PSD.baseOf(childQuest)] and entry.global ~= RSF_IMLER_ESCORT then
		-- AC-7: death at t = 0, the child's startQuest at sideQuestDelay * 1050 ms, the respawn switch at 12 s
		TestShipDeathRespawnKeepsChild["test_" .. entry.global .. "_death_starts_" .. child .. "_and_the_respawn_does_not_abandon_it"] = function()
			needHook()

			H.reset()
			H.Engine.nextRandom = 0

			local q = entry.quest
			local player = DRS.player(childQuest, { zone = childQuest.questZone })

			q:startQuest(player, "")
			H.advance(0)
			PSD.inProgress(q, player)
			H.playerShipDestroyed(player)

			-- the child is set up well before the respawn
			H.advance(12 * 1000)
			lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, childQuest.questType, childQuest.questName),
				child .. ": precondition: started by the failure split within 12 s")

			local mark = #H.messageLog(player)
			local fails = #PSD.failMessages(player)

			H.zoneSwitch(player, player.zone)
			H.advance(10 * 1000)

			lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, childQuest.questType, childQuest.questName), child .. ": still active after the respawn switch")
			lu.assertEquals(#PSD.failMessages(player), fails, child .. ": no Mission Failed for the child")

			for i = mark + 1, #H.messageLog(player) do
				local m = H.messageLog(player)[i]

				lu.assertNil((m.id or ""):find("_abandoned", 1, true), child .. ": " .. tostring(m.id) .. " after the respawn switch")
			end
		end
	end
end

-- The three child types of the AC-7 list exist among the 15 failure splits (the loop above must not be empty)
function TestShipDeathRespawnKeepsChild:test_the_failure_splits_start_battle_rescue_and_delivery_no_pickup_children()
	local seen = {}

	for _, entry in ipairs(failureSplitQuests()) do
		local childQuest = rawget(_G, failureChild(entry.quest))

		if childQuest ~= nil and CHILD_BASES[PSD.baseOf(childQuest)] then
			seen[PSD.baseOf(childQuest)] = true
		end
	end

	lu.assertEquals(seen, { SpaceBattleScreenplay = true, SpaceRescueScreenplay = true, SpaceDeliveryNoPickupScreenplay = true },
		"child types of the failure splits")
end
