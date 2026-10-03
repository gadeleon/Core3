-- Shared builders and snapshots for the progress migration tests (rsf-tier3-renames; not a test file).
--
--   M.state(player, type, name)              -- "active" | "complete" | "none" (journal)
--   M.missions(player, type, name)           -- datapad missions of that quest
--   M.startRun(player, type, name, opts)     -- an active run the way a started quest leaves it: journal entry + datapad mission
--                                               + persistent ZONESWITCHED observer + <id>:<class>:waypointID key and waypoint
--                                               (opts.inspect also adds the INSPECTEDSHIP and SHIPDOCKED observers)
--   M.finish(player, type, name)             -- a completed journal entry, written as activate then complete (as the server must)
--   M.leftovers(player, type, name)          -- everything a quest class leaves behind, for "is it clean" checks
--   M.clean()                                -- what M.leftovers returns for a quest with no trace
--   M.snapshot(player)                       -- journal, quest status, observers, waypoints, datapad, shared memory
--   M.sideEffects(player)                    -- counters of messages, music and createEvent calls
--
-- Everything is read from the fakes the harness exposes (ghost.journalActive / journalComplete, player.datapad.items,
-- Engine.observers, ghost.waypoints, Fakes.questStatus), never from the production code under test.

local H = require("harness")
local Fakes = require("harness.fakes")

local M = {}

function M.className(questType, questName) return questType .. "_" .. questName end

function M.crc(questType, questName) return H.questCrc(questType, questName) end

function M.state(player, questType, questName)
	local crc = M.crc(questType, questName)

	if player.ghost.journalActive[crc] then
		return "active"
	elseif player.ghost.journalComplete[crc] then
		return "complete"
	end

	return "none"
end

function M.missions(player, questType, questName)
	local crc, n = M.crc(questType, questName), 0

	for _, item in ipairs(player.datapad.items) do
		if item.getQuestCRC and item:getQuestCRC() == crc then
			n = n + 1
		end
	end

	return n
end

local OBSERVERS = {
	{ "ZONESWITCHED", "enteredZone" },
	{ "INSPECTEDSHIP", "inspectedShip" },
	{ "SHIPDOCKED", "dockedShip" },
}

function M.startRun(player, questType, questName, opts)
	opts = opts or {}

	local className = M.className(questType, questName)

	assert(SpaceHelpers:activateSpaceQuest(player, nil, questType, questName, false), "setup: " .. className .. " activates")
	createObserver(ZONESWITCHED, className, "enteredZone", player, 1)

	if opts.inspect then
		createObserver(INSPECTEDSHIP, className, "inspectedShip", player, 1)
		createObserver(SHIPDOCKED, className, "dockedShip", player, 1)
	end

	if opts.waypoint ~= false then
		local id = player.ghost:addWaypoint("space_lok", className, "", 1, 2, 3, 0, true, true, 0)

		H.setQuestStatus(player, ":" .. className .. ":waypointID", id)
	end
end

function M.finish(player, questType, questName)
	local crc = M.crc(questType, questName)

	player.ghost:activateJournalQuest(crc, false)
	player.ghost:completeJournalQuest(crc, false)
end

function M.leftovers(player, questType, questName)
	local className = M.className(questType, questName)
	local out = {
		journal = M.state(player, questType, questName),
		missions = M.missions(player, questType, questName),
		observers = {},
		waypointKey = H.getQuestStatus(player, ":" .. className .. ":waypointID"),
		waypoint = false,
	}

	for _, o in ipairs(OBSERVERS) do
		if hasObserver(_G[o[1]], className, o[2], player) then
			out.observers[#out.observers + 1] = o[1]
		end
	end

	local id = tonumber(H.getQuestStatus(player, ":" .. className .. ":waypointID"))

	for _, wp in ipairs(player.ghost.waypoints) do
		if wp.name == className or wp.objectID == id then
			out.waypoint = true
		end
	end

	return out
end

function M.clean()
	return { journal = "none", missions = 0, observers = {}, waypointKey = nil, waypoint = false }
end

local function copy(t)
	local out = {}

	for k, v in pairs(t) do
		out[k] = v
	end

	return out
end

local function observerList(player)
	local out = {}

	for _, o in ipairs(H.Engine.observersOn(player)) do
		out[#out + 1] = tostring(o.type) .. "|" .. tostring(o.sp) .. "|" .. tostring(o.method)
	end

	table.sort(out)
	return out
end

local function datapadList(player)
	local out = {}

	for _, item in ipairs(player.datapad.items) do
		out[#out + 1] = tostring(item.getQuestCRC and item:getQuestCRC() or item.objectID)
	end

	table.sort(out)
	return out
end

local function waypointList(player)
	local out = {}

	for _, wp in ipairs(player.ghost.waypoints) do
		out[#out + 1] = tostring(wp.objectID)
	end

	table.sort(out)
	return out
end

-- Datapad, journal, status keys, observers, waypoints and shared memory of the player. failedMissions is a log, not
-- state, and is left out on purpose (a second purge fails the datapad mission again).
function M.snapshot(player)
	return {
		active = copy(player.ghost.journalActive),
		complete = copy(player.ghost.journalComplete),
		status = copy(Fakes.questStatus),
		observers = observerList(player),
		waypoints = waypointList(player),
		datapad = datapadList(player),
		memory = H.Engine.sharedMemoryKeys(),
	}
end

-- Everything the migration must never do (spec I-7): messages, music, events.
function M.sideEffects(player)
	return { messages = #player.messageLog, music = #player.music, events = #H.Engine.callsTo("createEvent") }
end

return M
