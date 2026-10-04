-- Shared builders for the space-recovery-duty-fixes tests (not a test file).
-- Spec: .claude/work/space-recovery-duty-fixes/01-spec.md
--
--   RF.load()                    -- boot, quest types and the three squadrons (call once at the top of a test file)
--   RF.recoveryGlobals()         -- sorted globals whose class chain reaches SpaceRecoveryScreenplay (12 today)
--   RF.dutyGlobals()             -- sorted globals whose class chain reaches SpaceDutyRecoveryScreenplay (6 today)
--   RF.start(global[, opts])     -- DR.startRecoveryRun with the strict ship-name model switched on
--   RF.capture(run)              -- disable the recovery ship and run the capture events (startRecovery, continueRecovery, assignRecoveryPoints)
--   RF.finish(run)               -- the captured ship enters every recovery area in order, then the completeQuest event runs
--   RF.wave(run)                 -- the next attack wave spawns; returns the new agents (spawn order)
--   RF.attackIds(run)            -- ids in the player's :attackShips: list (numbers)
--   RF.kill(run, agent)          -- the agent is destroyed like the server does (SHIPDESTROYED observers, then it leaves the world)
--   RF.taunts(run)               -- strings the player was taunted with, in order
--   RF.pay(run)                  -- { credits = <bankCreditLog>, messages = <recovery_reward messages> }
--   RF.keys(run)                 -- shared-memory keys that belong to the run's player and quest class

local lu = require("luaunit")
local H = require("harness")
local DR = require("duty_rules_scenario")

local RF = {}

RF.MSG_REWARD = "@space/quest:recovery_reward"

-- The twelve recovery quests of the three squadrons (spec "Source inventory"), global -> kind
RF.EXPECTED = {
	recovery_corellia_privateer_tier3_1 = "story",
	recovery_duty_corellia_privateer_12 = "duty",
	recovery_duty_corellia_privateer_tier4_1 = "duty",
	recovery_viopa_rebel_3 = "story",
	recovery_duty_viopa_rebel_7 = "duty",
	recovery_corellia_rebel_tier3_1 = "story",
	recovery_corellia_rebel_tier4_4 = "story",
	recovery_duty_corellia_rebel_tier4_1 = "duty",
	recovery_naboo_privateer_14 = "story",
	recovery_duty_naboo_privateer_10 = "duty",
	recovery_naboo_privateer_tier3_1a = "story",
	recovery_duty_naboo_privateer_tier4_1 = "duty",
}

function RF.load()
	H.boot()
	H.loadSpaceQuestTypes()
	DR.loadSquadrons()
end

local function reaches(q, class)
	local mt = getmetatable(q)

	for _ = 1, 10 do
		if mt == nil then
			return false
		end

		if mt == class then
			return true
		end

		mt = getmetatable(mt)
	end

	return false
end

local function globalsReaching(className)
	local out = {}

	for _, name in ipairs(H.questGlobals()) do
		local class = rawget(_G, className)

		if class ~= nil and reaches(rawget(_G, name), class) then
			out[#out + 1] = name
		end
	end

	return out
end

function RF.recoveryGlobals()
	return globalsReaching("SpaceRecoveryScreenplay")
end

function RF.dutyGlobals()
	return globalsReaching("SpaceDutyRecoveryScreenplay")
end

function RF.storyGlobals()
	local out = {}

	for _, name in ipairs(RF.recoveryGlobals()) do
		if RF.EXPECTED[name] == "story" then
			out[#out + 1] = name
		end
	end

	return out
end

-- The SWG fixture of a quest (type and name from the quest table itself)
function RF.fixtureOf(q)
	return H.questFixture(q.questType, q.questName)
end

-- The target ship types of a fixture: duties name the column targetShipTypes, story recoveries targetShipType
function RF.targetTypes(rec)
	local list = rec:list("targetShipTypes")

	if #list == 0 then
		list = rec:list("targetShipType")
	end

	return list
end

-- Switches the harness model that rejects an empty ship template name on (see harness/engine.lua spawnShipAgent), then starts the run.
function RF.start(global, player)
	local q = H.expectGlobal(global, "recovery quest table")

	lu.assertTrue(q.arrivalDelay ~= nil and q.recoveryPoints ~= nil and q.preRecoveryPoints ~= nil and q.recoveryDelay ~= nil,
		global .. ": is a recovery quest table (arrivalDelay, recoveryDelay, preRecoveryPoints and recoveryPoints are defined)")

	H.Engine.config.rejectEmptyShipName = true

	local run = DR.startRecoveryRun(q, player)

	run.global = global
	run.pid = run.player.objectID
	return run
end

function RF.capture(run)
	local q = run.quest

	q:notifyRecoveryShipDisabled(run.ship, run.player)
	H.advance(q.recoveryDelay * 1000) -- startRecovery
	H.advance(q.recoveryDelay * 1000) -- continueRecovery
	H.advance(2000) -- assignRecoveryPoints
end

function RF.finish(run)
	for _, area in ipairs(run.areas) do
		H.enterArea(area, run.ship)
	end

	H.advance(1000)
end

function RF.key(run, suffix)
	return run.pid .. run.quest.className .. suffix
end

function RF.attackIds(run)
	local out = {}

	for i, id in ipairs(readStringVectorSharedMemory(RF.key(run, ":attackShips:"))) do
		out[i] = tonumber(id)
	end

	return out
end

function RF.escortIds(run)
	local out = {}

	for i, id in ipairs(readStringVectorSharedMemory(RF.key(run, ":spawnedShips:"))) do
		out[i] = tonumber(id)
	end

	return out
end

-- Advances to the next attack wave; returns the agents spawned by it, in spawn order
function RF.wave(run)
	local before = #H.spawnedShips()

	H.advance(run.quest.attackDelay * 1000)

	local out = {}

	for i = before + 1, #H.spawnedShips() do
		out[#out + 1] = H.spawnedShips()[i]
	end

	return out
end

function RF.kill(run, agent)
	lu.assertTrue(H.destroyShip(agent, nil), run.global .. ": ship " .. tostring(agent.objectID) .. " was destroyed now")
end

function RF.killAll(run, agents)
	for _, agent in ipairs(agents) do
		RF.kill(run, agent)
	end
end

function RF.taunts(run)
	local out = {}

	for _, t in ipairs(H.tauntLog(run.player)) do
		out[#out + 1] = t.msg
	end

	return out
end

-- Taunts of one kind ("capture_phase", "thanks", ...) with the quest prefix removed: the key only
function RF.keysOf(run, prefix)
	local out = {}
	local base = "@spacequest/" .. run.quest.questType .. "/" .. run.quest.questName .. ":"

	for _, msg in ipairs(RF.taunts(run)) do
		if msg:sub(1, #base) == base and msg:sub(#base + 1, #base + #prefix) == prefix then
			out[#out + 1] = msg:sub(#base + 1)
		end
	end

	return out
end

function RF.pay(run)
	return { credits = run.player.bankCreditLog, messages = DR.messages(run.player, RF.MSG_REWARD) }
end

-- Plain-string system messages of the form "@<stringfile>:<id>" of the quest, with the quest prefix removed
function RF.plainMessageKeys(run, prefix)
	local out = {}
	local base = "@spacequest/" .. run.quest.questType .. "/" .. run.quest.questName .. ":"

	for _, m in ipairs(H.messageLog(run.player)) do
		if m.plain and m.id:sub(1, #base) == base and m.id:sub(#base + 1, #base + #prefix) == prefix then
			out[#out + 1] = m.id:sub(#base + 1)
		end
	end

	return out
end

-- Shared-memory keys of the run's player and quest class that contain the given text
function RF.keys(run, text)
	local out = {}

	for _, k in ipairs(H.Engine.sharedMemoryKeys()) do
		if k:find(tostring(run.pid) .. run.quest.className, 1, true) and k:find(text, 1, true) then
			out[#out + 1] = k
		end
	end

	return out
end

function RF.count(list, value)
	local n = 0

	for _, v in ipairs(list) do
		if v == value then
			n = n + 1
		end
	end

	return n
end

return RF
