-- Shared builders for the space-quest-player-ship-destroyed tests (not a test file).
-- Spec: .claude/work/space-quest-player-ship-destroyed/01-spec.md
--
--   PSD.load()                    -- quest types, the CorSec/RSF/Havoc tables, every squadron table and the master missions
--   PSD.quests()                  -- every registered quest { global, quest }, sorted by global name
--   PSD.baseOf(q)                 -- the quest type table (key of PSD.CLASSES) q's class chain reaches first
--   PSD.byClass()                 -- base name -> sorted list of { global, quest }
--   PSD.CLASSES                   -- the C4 table: base name -> { before = {...states}, progress = fn, expect = true|false }
--   PSD.accepted(q)               -- H.reset(); a pilot in a ship, NOT in the quest zone, who started q (state "accepted")
--   PSD.inProgress(q, player)     -- puts the player's state of q just after the C4 condition (task or data key)
--   PSD.title(q)                  -- the quest title string id
--   PSD.failMessages(player)      -- the quest_failed messages: { TO, ... }
--   PSD.leaks(player, from)       -- ids of the messages after index `from` that a ship death must never send
--
-- The in-progress states are written straight into the journal tasks and the shared-memory keys the C4 table names, so a test
-- can build every one of the ~500 quests; the full runs of the 16 quest types are in abort_cleanup_scenario.lua.

local lu = require("luaunit")
local H = require("harness")
local DRS = require("duty_rules_scenario")
local AC = require("abort_cleanup_scenario")

local PSD = {}

PSD.GROUND = "corellia"
PSD.FAIL_MUSIC = "sound/music_themequest_fail_criminal.snd"
PSD.MSG_FAILED = "@space/quest:quest_failed"

local SQUADRONS = {
	"CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay",
	"VortexSquadronScreenplay", "SmugglerSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "InquisitionSquadronScreenplay",
	"StormSquadronScreenplay", "MasterTrainerScreenplay",
}

local loaded = false

function PSD.load()
	AC.load()

	if not loaded then
		for _, name in ipairs(SQUADRONS) do
			H.loadSquadron(name)
		end

		-- the Tatooine station palace access quests (1 of the 16 failure splits)
		H.loadScreenplay("space/spacestations/spacestation.lua")
		H.loadScreenplay("space/spacestations/TatooineStationPalaceAccessScreenplay.lua")

		loaded = true
	end
end

function PSD.quests()
	return DRS.quests()
end

-- The most derived quest type table (a key of PSD.CLASSES) in the class chain of a quest, e.g. SpaceDutyRecoveryScreenplay
function PSD.baseOf(q)
	local mt = getmetatable(q)

	for _ = 1, 10 do
		if mt == nil then
			return nil
		end

		for name in pairs(PSD.CLASSES) do
			if rawget(_G, name) == mt then
				return name
			end
		end

		mt = getmetatable(mt)
	end

	return nil
end

function PSD.byClass()
	local out = {}

	for _, entry in ipairs(PSD.quests()) do
		local base = PSD.baseOf(entry.quest)

		assert(base ~= nil, entry.global .. ": no known quest type in its class chain")

		local list = out[base]

		if list == nil then
			list = {}
			out[base] = list
		end

		list[#list + 1] = entry
	end

	return out
end

local function task(q, player, n, how)
	SpaceHelpers[how](SpaceHelpers, player, q.questType, q.questName, n, false)
end

local function id(player) return SceneObject(player):getObjectID() end

-- completes task n; the journal only completes a task that is active, so it is activated first (a no-op when it already is)
local function complete(n)
	return function(q, player)
		task(q, player, n, "activateSpaceQuestTask")
		task(q, player, n, "completeSpaceQuestTask")
	end
end

local function activate(n)
	return function(q, player) task(q, player, n, "activateSpaceQuestTask") end
end

local function setData(q, player, name, value)
	writeData(q:dataKey(id(player), name), value)
end

-- C4: the state just AFTER the listed condition (`progress`) and the states just BEFORE it (`before`: name -> function)
PSD.CLASSES = {
	SpaceDestroyScreenplay = {
		expect = true,
		progress = function(q, p) complete(0)(q, p); activate(1)(q, p) end,
		before = { ["task 0 complete, task 1 not active (no kill yet)"] = function(q, p) complete(0)(q, p) end } },
	SpaceSurpriseAttackScreenplay = {
		expect = true,
		progress = function(q, p) complete(0)(q, p); writeData(id(p) .. q.className .. ":spawned", 1) end,
		before = {
			["attack spawned, task 0 not complete"] = function(q, p) writeData(id(p) .. q.className .. ":spawned", 1) end,
			["task 0 complete, no attack spawned"] = function(q, p) complete(0)(q, p) end } },
	SpaceDutyDestroyScreenplay = { expect = true, progress = complete(0), before = {} },
	SpacePatrolScreenplay = {
		expect = true,
		progress = complete(2),
		before = { ["tasks 0 and 1 complete, no point reached"] = function(q, p) complete(0)(q, p); complete(1)(q, p) end } },
	SpaceDutyPatrolScreenplay = { expect = false, progress = complete(2), before = {} },
	SpaceInspectScreenplay = { expect = true, progress = complete(0), before = {} },
	SpaceDeliveryScreenplay = { expect = true, progress = function(q, p) setData(q, p, "runID", 1) end, before = {} },
	SpaceDeliveryNoPickupScreenplay = { expect = true, progress = function(q, p) setData(q, p, "runID", 1) end, before = {} },
	SpaceSurvivalScreenplay = { expect = true, progress = function(q, p) setData(q, p, "arrived", 1) end, before = {} },
	SpaceBattleScreenplay = { expect = true, progress = function(q, p) setData(q, p, "runID", 1) end, before = {} },
	SpaceRecoveryScreenplay = { expect = true, progress = complete(0), before = {} },
	SpaceDutyRecoveryScreenplay = { expect = true, progress = complete(0), before = {} },
	SpaceAssassinateScreenplay = { expect = true, progress = complete(0), before = {} },
	SpaceRescueScreenplay = { expect = true, progress = function(q, p) setData(q, p, "runID", 1) end, before = {} },
	SpaceDutyRescueScreenplay = { expect = true, progress = function(q, p) setData(q, p, "runID", 1) end, before = {} },
	SpaceEscortScreenplay = { expect = true, progress = complete(0), before = {} },
	SpaceDutyEscortScreenplay = { expect = true, progress = complete(0), before = {} },
	SpaceMasterDestroyScreenplay = { expect = false, progress = complete(0), before = {} },
}

function PSD.zoneOtherThan(q)
	if q.questZone == "space_naboo" then
		return "space_tatooine"
	end

	return "space_naboo"
end

-- A fresh harness and a pilot in a flyable ship in a zone that is not the quest zone, who started q ("accepted")
function PSD.accepted(q, zone)
	H.reset()

	local player = DRS.player(q, { zone = zone or PSD.zoneOtherThan(q) })

	q:startQuest(player, "")
	H.advance(0)

	return player
end

-- SWG's patrol_duty has no quest in any squadron table (0 of them): a test instance of SpaceDutyPatrolScreenplay under its
-- <questType>_<questName> global, so that the datapad dispatch finds it. Call PSD.dropDutyPatrol() from tearDown.
PSD.DUTY_PATROL_GLOBAL = "patrol_duty_psd_probe"

function PSD.dutyPatrol()
	local q = SpaceDutyPatrolScreenplay:new({
		className = PSD.DUTY_PATROL_GLOBAL, questType = "patrol_duty", questName = "psd_probe", questZone = "space_naboo", patrolPoints = {},
	})

	rawset(_G, PSD.DUTY_PATROL_GLOBAL, q)

	return q
end

function PSD.dropDutyPatrol()
	rawset(_G, PSD.DUTY_PATROL_GLOBAL, nil)
end

-- H.reset(); a pilot in a flyable ship who holds q's journal entry and datapad mission (no startQuest: for an instance that is not a
-- registered quest)
function PSD.acceptedDirect(q, zone)
	H.reset()

	local player = DRS.player(q, { zone = zone or PSD.zoneOtherThan(q) })

	lu.assertTrue(SpaceHelpers:activateSpaceQuest(player, nil, q.questType, q.questName, false), q.className .. ": precondition: the quest was taken")

	return player
end

function PSD.inProgress(q, player)
	local entry = PSD.CLASSES[PSD.baseOf(q)]

	assert(entry ~= nil, "psd_scenario: no C4 row for " .. tostring(q.className))
	entry.progress(q, player)
end

-- The quests that q's fail starts or fails (parent, side, failure split child, second side): recorders on their startQuest and
-- failQuest so that nothing else runs for real. Returns { start = {global -> calls}, fail = {global -> calls} }.
function PSD.isolateRelated(q)
	local spies = { start = {}, fail = {} }
	local names = {}

	if q.parentQuestType ~= "" then names[#names + 1] = q.parentQuestType .. "_" .. q.parentQuestName end

	for _, pair in ipairs({ { q.sideQuestType, q.sideQuestName }, { q.sideFailQuestType, q.sideFailQuestName },
		{ q.sideQuestType2, q.sideQuestName2 } }) do
		if pair[1] ~= nil and pair[1] ~= "" and pair[2] ~= nil and pair[2] ~= "" then
			names[#names + 1] = pair[1] .. "_" .. pair[2]
		end
	end

	for _, n in ipairs(names) do
		local other = rawget(_G, n)

		if other ~= nil and other ~= q and spies.start[n] == nil then
			spies.start[n] = H.spyOn(other, "startQuest")
			spies.fail[n] = H.spyOn(other, "failQuest")
		end
	end

	return spies
end

function PSD.hasMission(player, q)
	local crc = H.questCrc(q.questType, q.questName)

	for _, item in ipairs(player.datapad.items) do
		if item.getQuestCRC and item:getQuestCRC() == crc then
			return true
		end
	end

	return false
end

function PSD.title(q)
	return "@spacequest/" .. q.questType .. "/" .. q.questName .. ":title"
end

function PSD.failMessages(player, from)
	local out = {}

	for i, m in ipairs(H.messageLog(player)) do
		if i > (from or 0) and m.id == PSD.MSG_FAILED then
			out[#out + 1] = m.TO
		end
	end

	return out
end

-- Message ids (and TOs) of messages after index `from` that a ship death never sends: ended, won, abandoned, aborted, reward lines
local FORBIDDEN = { "quest_ended", "quest_won", "_abandoned", "mission_abandoned", "_aborted", "quest_aborted", "reward" }

function PSD.leaks(player, from)
	local out = {}

	for i, m in ipairs(H.messageLog(player)) do
		if i > (from or 0) then
			for _, text in ipairs({ m.id or "", m.TO or "" }) do
				for _, bad in ipairs(FORBIDDEN) do
					if text:find(bad, 1, true) then
						out[#out + 1] = m.id .. (m.TO and (" / " .. m.TO) or "")
					end
				end
			end
		end
	end

	return out
end

function PSD.musicCount(player)
	local n = 0

	for _, m in ipairs(player.music) do
		if m == PSD.FAIL_MUSIC then
			n = n + 1
		end
	end

	return n
end

-- A table-driven failure over ~500 quests prints the first few and the count
function PSD.summary(problems)
	if #problems <= 6 then
		return problems
	end

	local out = {}

	for i = 1, 6 do
		out[i] = problems[i]
	end

	out[#out + 1] = string.format("... %d problems in all", #problems)

	return out
end

-- Run fn in a protected call; a Lua error becomes a problem string (a missing hook fails every quest the same way)
function PSD.try(label, fn, ...)
	local ok, err = pcall(fn, ...)

	if not ok then
		return label .. ": " .. tostring(err)
	end

	return nil
end

PSD.lu = lu

return PSD
