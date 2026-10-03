-- Shared builders for the space-quest-duty-rules tests (not a test file).
-- Spec: .claude/work/space-quest-duty-rules/01-spec.md
--
--   DR.loadSquadrons()          -- CorSec, RSF and Havoc quest tables
--   DR.quests()                 -- every quest global that has a quest name, sorted by global name
--   DR.dutyQuests()             -- those whose questType contains "_duty"
--   DR.storyQuests()            -- the others
--   DR.player(q)                -- player in q's zone, in a flyable ship near a corner of the zone cube
--   DR.holdDuty(player[, name]) -- puts a flagged duty mission (not tied to a journal entry) on the datapad
--   DR.snapshot(player)         -- counts of the calls a refused start must not make
--   DR.messages(player, id)     -- system messages with that string id, in order

local lu = require("luaunit")
local H = require("harness")
local Fakes = require("harness.fakes")

local DR = {}

DR.SQUADRONS = { "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay" }

DR.MSG_DUTY_ALREADY = "@space/quest:duty_already"
DR.MSG_RECEIVED = "@space/quest:quest_received"
DR.MSG_ENDED = "@space/quest:quest_ended"
DR.MSG_WON = "@space/quest:quest_won"

-- Calls a refused startQuest must not make (spec AC-4)
DR.SPAWN_CALLS = { "createObserver", "createEvent", "spawnShipAgent", "spawnSpaceActiveArea", "addWaypoint" }

-- Far from the centre, so the destroy duty's 12500+ target distance has room inside the +-7500 cube
DR.CORNER = { x = -7000, z = -7000, y = -7000 }

function DR.loadSquadrons()
	for _, name in ipairs(DR.SQUADRONS) do
		H.loadSquadron(name)
	end
end

function DR.isDutyType(questType)
	return string.find(questType, "_duty", 1, true) ~= nil
end

function DR.quests()
	local out = {}

	for _, name in ipairs(H.questGlobals()) do
		local q = rawget(_G, name)

		if q.questName ~= "" and q.questType ~= "" then
			out[#out + 1] = { global = name, quest = q }
		end
	end

	return out
end

function DR.dutyQuests()
	local out = {}

	for _, entry in ipairs(DR.quests()) do
		if DR.isDutyType(entry.quest.questType) then
			out[#out + 1] = entry
		end
	end

	return out
end

function DR.storyQuests()
	local out = {}

	for _, entry in ipairs(DR.quests()) do
		if not DR.isDutyType(entry.quest.questType) then
			out[#out + 1] = entry
		end
	end

	return out
end

function DR.crc(q)
	return H.questCrc(q.questType, q.questName)
end

-- opts: zone (default q's zone), ship (default a ship near the corner), pilot
function DR.player(q, opts)
	opts = opts or {}

	return H.newPlayer({
		zone = opts.zone or q.questZone,
		ship = opts.ship or { x = DR.CORNER.x, z = DR.CORNER.z, y = DR.CORNER.y },
		pilot = opts.pilot or "rebel",
	})
end

function DR.holdDuty(player, name)
	local mission = Fakes.giveItem(player.datapad, "object/mission/mission_object.iff", -1)

	mission:setQuestType("destroy_duty")
	mission:setQuestName(name or "held_by_test")
	mission:setSpaceDutyMission()

	return mission
end

function DR.holdStory(player, name)
	local mission = Fakes.giveItem(player.datapad, "object/mission/mission_object.iff", -1)

	mission:setQuestType("patrol")
	mission:setQuestName(name or "story_held_by_test")

	return mission
end

function DR.snapshot(player)
	local s = { missions = #player.datapad.items, messages = #player.messageLog, music = #player.music }

	for _, fn in ipairs(DR.SPAWN_CALLS) do
		s[fn] = #H.Engine.callsTo(fn)
	end

	s.giveItem = #H.Engine.callsTo("giveItem")

	return s
end

function DR.messages(player, id)
	local out = {}

	for _, m in ipairs(H.messageLog(player)) do
		if m.id == id then
			out[#out + 1] = m
		end
	end

	return out
end

function DR.flaggedMissions(player)
	local out = {}

	for _, item in ipairs(player.datapad.items) do
		if item:isSpaceDutyMission() then
			out[#out + 1] = item
		end
	end

	return out
end

function DR.active(player, q)
	return player.ghost:isJournalQuestActive(DR.crc(q))
end

function DR.complete(player, q)
	return player.ghost:isJournalQuestComplete(DR.crc(q))
end

function DR.label(entry)
	return entry.global
end

-- Runs fn(entry) for every entry; returns the list of "<global>: <problem>" strings fn returned
-- (fn returns nil or a string). A Lua error inside fn is reported as a problem too.
function DR.collect(entries, fn)
	local problems = {}

	for _, entry in ipairs(entries) do
		H.reset()

		local ok, result = pcall(fn, entry)

		if not ok then
			problems[#problems + 1] = entry.global .. ": raised " .. tostring(result)
		elseif result ~= nil then
			problems[#problems + 1] = entry.global .. ": " .. result
		end
	end

	return problems
end

---------------------------------------------------------------------------------------------
-- Recovery duty run (SpaceRecoveryScreenplay flow, patrol points resolved like the server does)
---------------------------------------------------------------------------------------------

-- The squadron tables name their recovery points by patrol point and the server resolves the
-- coordinates; the harness does not, so the run writes them into the quest table and puts them back.
local resolved = {}

local function resolvePoints(q)
	local points = H.patrolPoints(q.questZone)

	for _, set in ipairs({ q.preRecoveryPoints, q.recoveryPoints }) do
		for _, point in ipairs(set) do
			local c = points[point.patrolPointName]

			assert(c ~= nil, q.className .. ": patrol point " .. tostring(point.patrolPointName) .. " not found in " .. q.questZone)

			resolved[#resolved + 1] = { point = point, x = point.x, z = point.z, y = point.y }
			point.x, point.z, point.y = c.x, c.z, c.y
		end
	end

	resolved[#resolved + 1] = { quest = q, conversation = q.recoveryConversationMobile }
	-- the fake ship agent has no setConversationMobile (not part of this feature's harness changes)
	q.recoveryConversationMobile = ""
end

-- Call from tearDown
function DR.restoreRecoveryTables()
	for i = #resolved, 1, -1 do
		local r = resolved[i]

		if r.point then
			r.point.x, r.point.z, r.point.y = r.x, r.z, r.y
		else
			r.quest.recoveryConversationMobile = r.conversation
		end
	end

	resolved = {}
end

-- startQuest in the quest zone, then events until the recovery ship has arrived.
-- Returns { quest, player, ship (the recovery ship), areas, last (the last recovery area) }.
function DR.startRecoveryRun(q, player)
	resolvePoints(q)

	q:start()

	player = player or DR.player(q)

	q:startQuest(player, "")
	H.advance(0)
	H.advance((q.arrivalDelay + 20) * 1000)

	local shipID = readData(player.objectID .. q.className .. ":recoveryShip:")
	local ship = getSceneObject(shipID)

	lu.assertNotNil(ship, q.className .. ": the recovery ship was spawned")

	local areas = H.spawnedAreas()

	return { quest = q, player = player, ship = ship, areas = areas, last = areas[#areas] }
end

-- The recovery ship reaches its last recovery point (one point left), then the completeQuest event runs.
function DR.finishRecovery(run)
	local q = run.quest

	writeData(run.ship.objectID .. ":" .. q.className .. ":recoveryShipProgress:", 1)
	H.enterArea(run.last, run.ship)
	H.advance(1000)
end

DR.lu = lu

return DR
