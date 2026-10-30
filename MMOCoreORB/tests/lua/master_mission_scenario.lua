-- Shared builders for the persistent master mission quest type (feature space-master-mission-quest-type), not a test file.
-- Spec: .claude/work/space-master-mission-quest-type/01-spec.md (Content contract, AC-3 to AC-9, Test strategy hints).
--
-- One case per admiral (Imperial: Declann, Rebel: Burke). Ship lists come from the SWG .tab fixtures through the trainer data modules
-- (M.shipList), never from this file. The scenario drives the real startQuest, the observers (H.fireObservers) and the event clock.
--   S.CASES                 { imperial, rebel }: faction, M (trainer data module), ONE, TWO (quest globals), other (the opposite case)
--   S.started(case, global[, o])   fresh harness, a pilot in a ship who started `global` (o.zone: where the pilot stands, default a ground zone)
--   S.pilot(case, o)        a pilot in a ship (no quest started)
--   S.enter(player)         switch to Kessel and let the 5 s reminder run
--   S.fire / S.kill         DESTROYEDSHIP on the pilot for a ship name (kill also pumps the clock)
--   S.count(player, global) the saved kill count as a number (0 for empty)
--   S.updates(player[, from])  the "Mission Update" texts the pilot got
--   S.observerProblems(player, global)  what is wrong with the three persistent observers ({} = exactly one each, persistence integer 1)

local H = require("harness")
local DRS = require("duty_rules_scenario")
local MI = require("master_trainer_imperial_data")
local MR = require("master_trainer_rebel_data")

local S = {}

S.ZONE = "space_light1"
S.GROUND = "corellia"
S.UPDATE = "@space/quest:quest_update_s"

S.CASES = {
	{ faction = "imperial", M = MI, ONE = "destroy_master_imperial_1", TWO = "destroy_master_imperial_2",
		type = "destroy", names = { "master_imperial_1", "master_imperial_2" } },
	{ faction = "rebel", M = MR, ONE = "destroy_master_rebel_1", TWO = "destroy_master_rebel_2",
		type = "destroy", names = { "master_rebel_1", "master_rebel_2" } },
}

S.CASES[1].other, S.CASES[2].other = S.CASES[2], S.CASES[1]

S.GLOBALS = { MI.GLOBALS[1], MI.GLOBALS[2], MR.GLOBALS[1], MR.GLOBALS[2] }

function S.load()
	MI.load()
	MR.load()
end

function S.quest(case, global)
	S.load()

	return case.M.quest(global)
end

-- (event, method) of the three observers the quest keeps; the globals exist once the harness booted
function S.observers()
	return { { ZONESWITCHED, "enteredZone" }, { LOGGEDIN, "onLoggedIn" }, { DESTROYEDSHIP, "notifyDestroyedShip" } }
end

function S.pump(ms, label)
	local ok, err = pcall(H.advance, ms)

	require("luaunit").assertTrue(ok, (label or "pump") .. ": a Lua error inside an event: " .. tostring(err))
end

local function shipOpts() return { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y } end

-- o: M.pilot options (zone default S.GROUND, a pilot in a ship so that the real startQuest runs)
function S.pilot(case, o)
	S.load()

	local opts = { inShip = shipOpts(), zone = S.GROUND, inventory = true }

	for k, v in pairs(o or {}) do
		opts[k] = v
	end

	return case.M.pilot(opts)
end

-- A fresh harness and a pilot who ran the quest's own startQuest (as the trainer does)
function S.started(case, global, o)
	local q = S.quest(case, global)

	H.reset()

	local player = S.pilot(case, o)

	q:startQuest(player, "")
	H.advance(0)

	return q, player
end

function S.isActive(player, q) return SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) end
function S.isComplete(player, q) return SpaceHelpers:isSpaceQuestComplete(player, q.questType, q.questName) end

function S.count(player, global) return tonumber(readScreenPlayData(player, global, "killCount")) or 0 end

function S.taskDone(player, q, task)
	local crc = H.questCrc(q.questType, q.questName)
	local done = player.ghost.taskComplete[crc]

	return done ~= nil and done[task] == true
end

function S.taskActive(player, q, task)
	local crc = H.questCrc(q.questType, q.questName)
	local on = player.ghost.taskActive[crc]

	return on ~= nil and on[task] == true
end

-- Texts of the "Mission Update: < %TO >" messages, oldest first, from message index `from` (default 1)
function S.updates(player, from)
	local out = {}

	for i, m in ipairs(H.messageLog(player)) do
		if i >= (from or 1) and m.id == S.UPDATE then
			out[#out + 1] = m.TO
		end
	end

	return out
end

function S.messageMark(player) return #H.messageLog(player) + 1 end

function S.messageIds(player)
	local out = {}

	for i, m in ipairs(H.messageLog(player)) do
		out[i] = m.id
	end

	return out
end

-- Switch to Kessel (a launch) and let the reminder run
function S.enter(player, label)
	H.zoneSwitch(player, S.ZONE, { ship = true })
	S.pump(6000, label or "Kessel entry")
end

function S.goTo(player, zone, label)
	H.zoneSwitch(player, zone)
	S.pump(5000, label or ("going to " .. zone))
end

function S.agent(shipName, zone) return H.worldAgent({ shipName = shipName, zone = zone or S.ZONE }) end

-- One DESTROYEDSHIP for `player` (no clock pump)
function S.fire(player, shipName, agent)
	agent = agent or S.agent(shipName)
	H.fireObservers(DESTROYEDSHIP, player, agent)

	return agent
end

-- A kill; the 200 ms completion event runs
function S.kill(player, shipName, label)
	local agent = S.fire(player, shipName)

	S.pump(300, label or ("kill of " .. shipName))

	return agent
end

-- The i-th ship name of a list, cycling
function S.cycle(list, i) return list[(i - 1) % #list + 1] end

-- A ship name of the opposite admiral's mission 1 that this case does not list, and the opposite corvette
function S.unlistedFighter(case)
	local mine = {}

	for _, n in ipairs(case.M.shipList(case.ONE)) do mine[n] = true end
	for _, n in ipairs(case.M.shipList(case.TWO)) do mine[n] = true end

	for _, n in ipairs(case.other.M.shipList(case.other.ONE)) do
		if not mine[n] then return n end
	end
end

function S.unlistedCorvette(case)
	local mine = {}

	for _, n in ipairs(case.M.shipList(case.ONE)) do mine[n] = true end
	for _, n in ipairs(case.M.shipList(case.TWO)) do mine[n] = true end

	for _, n in ipairs(case.other.M.shipList(case.other.TWO)) do
		if not mine[n] then return n end
	end
end

-- Problems with the quest's observers on the player: each (event, method) must be registered exactly once, with the integer 1
function S.observerProblems(player, global)
	local out = {}

	for _, o in ipairs(S.observers()) do
		local n = H.Engine.observerCount(o[1], global, o[2], player)

		if n ~= 1 then
			out[#out + 1] = o[2] .. ": registered " .. n .. " times"
		else
			local p = H.Engine.observerPersistence(o[1], global, o[2], player)

			if math.type(p) ~= "integer" or p ~= 1 then
				out[#out + 1] = o[2] .. ": persistence argument is " .. tostring(p) .. " (" .. tostring(math.type(p)) .. "), want the integer 1"
			end
		end
	end

	return out
end

function S.observerCounts(player, global)
	local out = {}

	for _, o in ipairs(S.observers()) do
		out[o[2]] = H.Engine.observerCount(o[1], global, o[2], player)
	end

	return out
end

-- Every createObserver call made for the class `global` (any player): the list of persistence arguments
function S.createObserverArgs(global)
	local out = {}

	for _, c in ipairs(H.Engine.callsTo("createObserver")) do
		if c[2] == global then
			out[#out + 1] = c[5]
		end
	end

	return out
end

-- Counts SpaceHelpers:completeSpaceQuest calls (the original still runs); call S.unwrap() from tearDown
local wrapped

function S.countCompletions()
	local calls = {}
	local orig = SpaceHelpers.completeSpaceQuest

	SpaceHelpers.completeSpaceQuest = function(self, pPlayer, questType, questName, notify)
		calls[#calls + 1] = { player = pPlayer, type = questType, name = questName, notify = notify }

		return orig(self, pPlayer, questType, questName, notify)
	end

	wrapped = orig

	return calls
end

function S.unwrap()
	if wrapped then
		SpaceHelpers.completeSpaceQuest = wrapped
		wrapped = nil
	end
end

-- Texts of the createEvent calls aimed at a method: list of delays (ms)
function S.eventDelays(method)
	local out = {}

	for _, c in ipairs(H.Engine.callsTo("createEvent")) do
		if c[3] == method then
			out[#out + 1] = c[1]
		end
	end

	return out
end

function S.effects(player, file)
	local n = 0

	for _, e in ipairs(player.effects) do
		if e.file == file then n = n + 1 end
	end

	return n
end

-- The pilot's journal entry via the trainer's data module
function S.state(case, player, global) return case.M.state(player, global) end

return S
