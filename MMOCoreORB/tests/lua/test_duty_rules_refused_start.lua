-- A refused activation stops startQuest: no observer, event, ship, area or waypoint is created.
-- Spec: .claude/work/space-quest-duty-rules/01-spec.md (AC-4, I-4)

local lu = require("luaunit")
local H = require("harness")
local DR = require("duty_rules_scenario")

H.boot()
H.loadSpaceQuestTypes()
DR.loadSquadrons()

-- Returns "" when the start did nothing it should not, else a description
local function startMadeNoSetup(q, p, before)
	local made = {}

	for _, fn in ipairs(DR.SPAWN_CALLS) do
		local count = #H.Engine.callsTo(fn) - before[fn]

		if count ~= 0 then
			made[#made + 1] = fn .. " x" .. count
		end
	end

	if #p.datapad.items ~= before.missions then
		made[#made + 1] = "datapad missions " .. before.missions .. " -> " .. #p.datapad.items
	end

	if #made > 0 then
		return "refused startQuest still did: " .. table.concat(made, ", ")
	end
end

TestRefusedStart = {}

function TestRefusedStart:setUp() H.reset() end

-- AC-4 (I-4)
function TestRefusedStart:test_every_duty_start_does_nothing_while_another_duty_is_held()
	local problems = DR.collect(DR.dutyQuests(), function(entry)
		local q = entry.quest
		local p = DR.player(q)

		DR.holdDuty(p)

		local before = DR.snapshot(p)

		q:startQuest(p, "")
		H.advance(0)

		if DR.active(p, q) then
			return "journal entry was activated"
		end

		return startMadeNoSetup(q, p, before)
	end)

	lu.assertEquals(problems, {}, "duty quests that started although another duty was held")
end

-- AC-4 (I-4)
function TestRefusedStart:test_every_story_start_does_nothing_while_its_own_entry_is_active()
	local problems = DR.collect(DR.storyQuests(), function(entry)
		local q = entry.quest
		local p = DR.player(q)

		p.ghost:activateJournalQuest(DR.crc(q), false)

		local before = DR.snapshot(p)

		q:startQuest(p, "")
		H.advance(0)

		return startMadeNoSetup(q, p, before)
	end)

	lu.assertEquals(problems, {}, "story quests that started although their entry was active")
end

-- AC-4 (I-4): a completed story entry cannot be re-activated by the server either
function TestRefusedStart:test_every_story_start_does_nothing_while_its_own_entry_is_complete()
	local problems = DR.collect(DR.storyQuests(), function(entry)
		local q = entry.quest
		local p = DR.player(q)
		local crc = DR.crc(q)

		p.ghost:activateJournalQuest(crc, false)
		p.ghost:completeJournalQuest(crc, false)

		local before = DR.snapshot(p)

		q:startQuest(p, "")
		H.advance(0)

		if DR.active(p, q) then
			return "journal entry was re-activated"
		end

		return startMadeNoSetup(q, p, before)
	end)

	lu.assertEquals(problems, {}, "story quests that started although their entry was complete")
end

-- AC-4: the refusal keeps the held duty and the journal untouched
function TestRefusedStart:test_a_refused_duty_start_keeps_the_held_duty_and_says_duty_already()
	local q = recovery_duty_corellia_rebel_tier4_1
	local p = DR.player(q)
	local held = DR.holdDuty(p)

	q:startQuest(p, "")
	H.advance(0)

	lu.assertEquals(#DR.messages(p, DR.MSG_DUTY_ALREADY), 1, "duty_already")
	lu.assertEquals(#p.datapad.items, 1, "datapad size")
	lu.assertIs(p.datapad.items[1], held, "the held duty is still the only mission")
	lu.assertFalse(DR.active(p, q), "journal entry")
end

-- AC-4: the same start with no duty held still sets the quest up (guards against a start that never works)
function TestRefusedStart:test_the_same_duty_start_sets_up_when_no_duty_is_held()
	local q = recovery_duty_corellia_rebel_tier4_1
	local p = DR.player(q)

	q:startQuest(p, "")
	H.advance(0)

	lu.assertTrue(DR.active(p, q), "journal entry")
	lu.assertEquals(#p.datapad.items, 1, "datapad size")
	lu.assertTrue(#H.Engine.callsTo("createObserver") > 0, "an observer is created")
end
