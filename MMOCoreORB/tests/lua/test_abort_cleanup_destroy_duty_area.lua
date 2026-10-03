-- The destroy duty target area is destroyed by every ending of a duty, not only by an abort.
-- Spec: .claude/work/space-quest-abort-cleanup/01-spec.md (AC-5, contract 4)

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")

AC.load()

local SOURCE = H.SCRIPTS .. "screenplays/space/SpaceDutyDestroyScreenplay.lua"
local GLOBAL = "destroy_duty_corellia_rebel_6"

local function quest()
	return H.expectGlobal(GLOBAL, "destroy duty quest table (Havoc)")
end

-- A running duty with its first target area spawned by getTargetLocation (the player starts in the quest zone)
local function duty()
	local q = quest()
	local p = AC.started(q)
	local key = p.objectID .. ":" .. q.className .. ":targetArea:"
	local area = getSceneObject(readData(key))

	lu.assertNotNil(area, GLOBAL .. ": precondition: startQuest in the quest zone spawns a target area")
	lu.assertTrue(area:isActiveArea(), "precondition: it is an active area")
	lu.assertTrue(H.hasObserver(ENTEREDAREA, q.className, "notifyEnteredQuestArea", area), "precondition: the ENTEREDAREA observer")

	return q, p, area, key
end

-- The five endings leave the area out of the world, without its observer, and the key deleted
local function assertAreaGone(area, p, q, key, label)
	lu.assertTrue(area.destroyed == true, label .. ": the target area is still in the world")
	lu.assertTrue(getSceneObject(area.objectID) == nil, label .. ": getSceneObject still finds the area")
	lu.assertEquals(H.Engine.observersOn(area, ENTEREDAREA), {}, label .. ": ENTEREDAREA observers on the area")
	lu.assertFalse(H.hasObserver(ENTEREDAREA, q.className, "notifyEnteredQuestArea", area), label .. ": notifyEnteredQuestArea observer")
	lu.assertEquals(readData(key), 0, label .. ": " .. key)

	-- The fake destroy drops an object's observers by itself, which can hide a missing dropObserver. The server's
	-- destroyObjectFromWorld does not do that synchronously (SceneObjectImplementation.cpp has no observer teardown there),
	-- so the production code has to drop the observer explicitly, before it destroys the area.
	local dropAt, destroyAt

	for i, c in ipairs(H.Engine.calls) do
		if c.fn == "dropObserver" and c.args[1] == ENTEREDAREA and c.args[2] == q.className and c.args[3] == "notifyEnteredQuestArea" and c.args[4] == area then
			dropAt = dropAt or i
		elseif c.fn == "destroyObjectFromWorld" and c.args[1] == area then
			destroyAt = destroyAt or i
		end
	end

	lu.assertNotNil(dropAt, label .. ": dropObserver(ENTEREDAREA, className, \"notifyEnteredQuestArea\", area) was never called")
	lu.assertNotNil(destroyAt, label .. ": the area was never destroyed through destroyObjectFromWorld")
	lu.assertTrue(dropAt < destroyAt, label .. ": the observer is dropped after the area is destroyed")

	for _, k in ipairs(H.Engine.sharedMemoryKeys()) do
		lu.assertNotEquals(k:match("^[^|]*|(.*)$"), key, label .. ": the targetArea key is still set")
	end
end

TestDestroyDutyAreaTeardown = {}

function TestDestroyDutyAreaTeardown:setUp() H.reset() end

-- AC-5
function TestDestroyDutyAreaTeardown:test_fail_quest_destroys_the_target_area()
	local q, p, area, key = duty()

	q:failQuest(p, "true")

	assertAreaGone(area, p, q, key, "failQuest")
end

-- AC-5
function TestDestroyDutyAreaTeardown:test_reset_quest_destroys_the_target_area()
	local q, p, area, key = duty()

	q:resetQuest(p)

	assertAreaGone(area, p, q, key, "resetQuest")
end

-- AC-5
function TestDestroyDutyAreaTeardown:test_complete_quest_destroys_the_target_area()
	local q, p, area, key = duty()

	q:completeQuest(p, true)

	assertAreaGone(area, p, q, key, "completeQuest")
end

-- AC-5: a boss kill that does not end the duty (level 1 of 5) destroys the area of that level
function TestDestroyDutyAreaTeardown:test_a_boss_kill_destroys_the_target_area()
	local q, p, area, key = duty()

	lu.assertTrue(q.totalLevels > 1, "precondition: the duty has more than one level, so the boss kill does not reach completeQuest")

	writeData(p.objectID .. ":" .. q.className .. ":bossLevel:", 1)
	H.enterArea(area, p.rootParent)
	H.advance(4500) -- spawnAttackWave: the boss wave

	local boss = H.spawnedShips()[1]

	lu.assertNotNil(boss, "precondition: the boss ship spawned")
	lu.assertEquals(#H.spawnedShips(), 1, "precondition: a single boss at level 1")
	lu.assertFalse(area.destroyed == true, "precondition: the area is still there before the kill")

	H.destroyShip(boss, p.rootParent)

	assertAreaGone(area, p, q, key, "boss kill")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(p, q.questType, q.questName), "the duty goes on to the next level")
end

-- AC-5: the end of a round (the last ship of the last wave) destroys the area
function TestDestroyDutyAreaTeardown:test_the_end_of_a_round_destroys_the_target_area()
	local q, p, area, key = duty()
	local prefix = p.objectID .. ":" .. q.className .. ":"

	H.enterArea(area, p.rootParent)
	H.advance(4500) -- spawnAttackWave: wave 1

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 1, "precondition: one attacker in wave 1 of level 1")
	lu.assertFalse(area.destroyed == true, "precondition: the area is still there before the kill")

	writeData(prefix .. "CurrentWave:", q.totalWaves)
	writeData(prefix .. "CurrentRound:", q.totalRounds - 1)

	H.destroyShip(ships[1], p.rootParent)

	assertAreaGone(area, p, q, key, "round end")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(p, q.questType, q.questName), "the duty goes on")
end

---------------------------------------------------------------------------------------------
-- The source of SpaceDutyDestroyScreenplay.lua no longer has the broken reads
---------------------------------------------------------------------------------------------

TestDestroyDutyAreaSource = {}

local function source()
	local f = io.open(SOURCE, "r")

	lu.assertNotNil(f, "cannot read " .. SOURCE)

	local text = f:read("a")
	f:close()

	return text
end

-- Splits the file into its functions: { { name, body } } (the text before the first function is dropped)
local function functions(text)
	local out = {}
	local starts = {}

	for at in text:gmatch("()\nfunction ") do
		starts[#starts + 1] = at + 1
	end

	for i, at in ipairs(starts) do
		local stop = (starts[i + 1] or #text + 2) - 1
		local body = text:sub(at, stop)

		out[#out + 1] = { name = body:match("^function%s+([%w_:.]+)") or "?", body = body }
	end

	return out
end

-- AC-5: `local areaID = writeData(...)` read the area id from a function that returns nothing
function TestDestroyDutyAreaSource:test_no_area_id_is_read_through_write_data()
	local bad = {}

	for _, fn in ipairs(functions(source())) do
		for line in fn.body:gmatch("[^\n]+") do
			if line:find("=%s*writeData%(") then
				bad[#bad + 1] = fn.name .. ": " .. line:gsub("^%s+", "")
			end
		end
	end

	lu.assertEquals(bad, {}, "assignments from writeData")
end

-- AC-5: destroyObjectFromWorld exists only as a SceneObject method (LuaSceneObject.cpp:61)
function TestDestroyDutyAreaSource:test_destroy_object_from_world_is_only_called_as_a_method()
	local bad = {}
	local text = source()

	for at in text:gmatch("()destroyObjectFromWorld%(") do
		if text:sub(at - 1, at - 1) ~= ":" then
			local line = select(2, text:sub(1, at):gsub("\n", "")) + 1

			bad[#bad + 1] = "line " .. line
		end
	end

	lu.assertEquals(bad, {}, "bare destroyObjectFromWorld( calls")
end

-- AC-5: questAreaID was read in functions that never declared it (an undefined global, always nil)
function TestDestroyDutyAreaSource:test_every_function_that_uses_quest_area_id_declares_it_local()
	local bad = {}

	for _, fn in ipairs(functions(source())) do
		if fn.body:find("questAreaID", 1, true) and not fn.body:find("local questAreaID", 1, true) then
			bad[#bad + 1] = fn.name
		end
	end

	lu.assertEquals(bad, {}, "functions using the undefined global questAreaID")
end

-- AC-5: deleteData takes one argument
function TestDestroyDutyAreaSource:test_delete_data_is_never_called_with_a_second_argument()
	local bad = {}
	local text = source()

	for at in text:gmatch("()deleteData%(") do
		local depth, i = 1, at + #"deleteData("
		local comma = false

		while depth > 0 and i <= #text do
			local c = text:sub(i, i)

			if c == "(" then
				depth = depth + 1
			elseif c == ")" then
				depth = depth - 1
			elseif c == "," and depth == 1 then
				comma = true
			end

			i = i + 1
		end

		if comma then
			bad[#bad + 1] = "line " .. (select(2, text:sub(1, at):gsub("\n", "")) + 1)
		end
	end

	lu.assertEquals(bad, {}, "deleteData calls with two arguments")
end
