-- Shared test data and builders for Storm Squadron tier 2 part 3 (Field Commander Alozen, Yavin 4), not a test file.
-- Spec: .claude/work/storm-tier2-alozen/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of agreeing with itself:
--   A.GLOBALS / A.IDENTITY     the 6 quest globals and their class, type, name and zone (Content contract 1)
--   A.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   A.POINTS                   Data mapping 2: the 27 nav points, Core3 x, z, y
--   A.SCREENS                  Appendix A (storm_tier2_alozen_screens_data.lua, generated from the spec table by a scratch script)
--   A.TRAIN                    TRAIN_CHOICES (Conversation flow 3.4)
--   A.load()                   the server's load of the squadron files, Oberhaur's pieces (storm_tier2_data.lua) and Alozen's template and handler,
--                              collecting load errors
--   A.pilot{...}               a pilot standing in front of Alozen (see the option list at A.pilot), built on T.pilot of storm_tier2_data.lua
--   A.talk / A.drive           H.converse from the first screen / from a given screen
--
-- Alozen's conversation lives in the template "alozen_convo_template", its handler is the global "alozenConvoHandler".

local H = require("harness")
local T = require("storm_tier2_data")

local A = {}

A.TEMPLATE = "alozen_convo_template"
A.HANDLER = "alozenConvoHandler"
A.PREFIX = "@conversation/tatooine_imperial_trainer_2b:"
A.STF = "conversation/tatooine_imperial_trainer_2b"

A.TEMPLATE_FILE = "mobile/conversations/space/imperial/storm_squadron/alozen_convo.lua"
A.HANDLER_FILE = "screenplays/space/conversations/imperial/storm_squadron/alozenConvoHandler.lua"
A.NPC_FILE = "mobile/space/alozen.lua"
A.SPAWN_FILE = "screenplays/poi/yavin4_imperial_base.lua"

A.M1 = "inspect_imperial_ss_4"
A.M2 = "escort_imperial_ss_5"
A.M3 = "recovery_imperial_ss_6"
A.DUTY1 = "destroy_duty_lok_imperial_ss_2a"
A.DUTY2 = "recovery_duty_lok_imperial_ss_2b"
A.DUTY3 = "escort_duty_lok_imperial_ss_2c"

A.GLOBALS = { A.M1, A.M2, A.M3, A.DUTY1, A.DUTY2, A.DUTY3 }
A.MISSIONS = { A.M1, A.M2, A.M3 }
A.DUTIES = { A.DUTY1, A.DUTY2, A.DUTY3 }

-- global -> { class, type, name, zone }
A.IDENTITY = {
	[A.M1] = { class = "SpaceInspectScreenplay", type = "inspect", name = "imperial_ss_4", zone = "space_yavin4" },
	[A.M2] = { class = "SpaceEscortScreenplay", type = "escort", name = "imperial_ss_5", zone = "space_yavin4" },
	[A.M3] = { class = "SpaceRecoveryScreenplay", type = "recovery", name = "imperial_ss_6", zone = "space_yavin4" },
	[A.DUTY1] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "lok_imperial_ss_2a", zone = "space_yavin4" },
	[A.DUTY2] = { class = "SpaceDutyRecoveryScreenplay", type = "recovery_duty", name = "lok_imperial_ss_2b", zone = "space_yavin4" },
	[A.DUTY3] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "lok_imperial_ss_2c", zone = "space_yavin4" },
}

-- Content contract 2: the squadron object's constants
A.QUEST_STRINGS = {
	TIER2_QUEST_STRING_4 = { type = "inspect", name = "imperial_ss_4" },
	TIER2_QUEST_STRING_5 = { type = "escort", name = "imperial_ss_5" },
	TIER2_QUEST_STRING_6 = { type = "recovery", name = "imperial_ss_6" },
	TIER2_QUEST_STRING_DUTY_4 = { type = "destroy_duty", name = "lok_imperial_ss_2a" },
	TIER2_QUEST_STRING_DUTY_5 = { type = "recovery_duty", name = "lok_imperial_ss_2b" },
	TIER2_QUEST_STRING_DUTY_6 = { type = "escort_duty", name = "lok_imperial_ss_2c" },
}

-- Status names of the three missions: "<playerID>imperial_ss_<n>:attempted" / ":reward", n = 4..6
A.STATUS = { "imperial_ss_4", "imperial_ss_5", "imperial_ss_6" }

function A.statusKeys()
	local out = {}

	for _, name in ipairs(A.STATUS) do
		out[#out + 1] = name .. ":attempted"
		out[#out + 1] = name .. ":reward"
	end

	return out
end

-- Data mapping 2: name -> { x, z, y } (Core3 x, z, y = patrol point file = buildout fltPX, fltPY, fltPZ truncated)
A.POINTS = {
	yavin_rebel_region_scan_1 = { 5000, -1220, 4300 },
	yavin_rebel_region_scan_2 = { 6563, -605, 4839 },
	yavin_rebel_region_scan_3 = { 5498, -1466, 2835 },
	tatooine_imperial_twilight_1 = { -5464, 3200, -6088 },
	tatooine_imperial_twilight_2 = { -1316, 2300, -5012 },
	tatooine_imperial_twilight_3 = { 4784, 1400, -5136 },
	tatooine_imperial_twilight_4 = { 3876, 900, -4400 },
	tatooine_imperial_twilight_5 = { 4608, 200, -2712 },
	tatooine_imperial_twilight_6 = { 5568, -800, -148 },
	yavin_imp_scavenger_1 = { -2200, 600, -2800 },
	yavin_imp_scavenger_2 = { -1907, 827, -2147 },
	yavin_imp_scavenger_3 = { -1688, 632, -1695 },
	yavin_imp_scavenger_4 = { -1460, 635, -1050 },
	yavin_imp_scavenger_5 = { -1026, 738, -552 },
	yavin_imp_scavenger_6 = { 1877, 501, -1617 },
	yavin_imp_recovery_1 = { 2223, 898, -1548 },
	yavin_imp_recovery_2 = { 1474, 1207, -883 },
	yavin_imp_recovery_3 = { 1261, 935, 2 },
	yavin_imp_recovery_4 = { 514, 1018, 1163 },
	yavin_imp_recovery_5 = { -382, 1165, -674 },
	yavin_imp_recovery_6 = { -791, 1241, -1688 },
	yavin_imp_escort_duty_1 = { -4792, 1000, -1048 },
	yavin_imp_escort_duty_2 = { -2820, 1500, 1340 },
	yavin_imp_escort_duty_3 = { -2896, 2000, 3760 },
	yavin_imp_escort_duty_4 = { 36, 2500, 5188 },
	yavin_imp_escort_duty_5 = { 3016, 3000, 6392 },
	yavin_imp_escort_duty_6 = { 6476, 3500, 6428 },
}

A.SPAWNER = { spawnName = "tatooine_imperial_tier2_inspect_rebagent", x = -3200, z = -3000, y = 6000 }

A.ITEM = "object/tangible/ship/components/shield_generator/shd_mission_reward_imperial_rendili_dual_projector.iff"
A.CREDITS = 5000
A.STANDING = { 75, 50, 50 }

local function point(name, extra)
	local p = A.POINTS[name]
	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra or {}) do
		t[k] = v
	end

	return t
end

local function path(prefix, first, last, extra)
	local out = {}

	for i = first, last do
		out[#out + 1] = point(prefix .. i, extra and extra(#out + 1) or nil)
	end

	return out
end

-- recovery path: escortNumber = i (renumbered from 1), radius 250, no zoneName
local function recoveryPath(prefix, first, last)
	return path(prefix, first, last, function(i) return { escortNumber = i, radius = 250 } end)
end

local function escortPath(prefix, first, last)
	return path(prefix, first, last, function(i) return { zoneName = "space_yavin4", escortNumber = i, radius = 250 } end)
end

local function repeated(name, count)
	local out = {}

	for i = 1, count do
		out[i] = name
	end

	return out
end

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function A.expected()
	return {
		[A.M1] = {
			className = A.M1, questName = "imperial_ss_4", questType = "inspect", questZone = "space_yavin4",
			creditReward = 5000, itemReward = { { species = { -1 }, item = A.ITEM } },
			sideQuest = false, sideQuestType = "",
			shipList = { "rebel_agent_tier3" },
			validSpawns = { A.SPAWNER },
			giveSpawnWaypoint = 1,
			cargo = "yavin_activity_log",
		},
		[A.M2] = {
			className = A.M2, questName = "imperial_ss_5", questType = "escort", questZone = "space_yavin4",
			creditReward = 5000,
			sideQuest = false, sideQuestType = "",
			escortShips = { "imperial_scan_freighter_tier2" },
			escortPoints = escortPath("yavin_rebel_region_scan_", 1, 3),
			attackDelay = 120,
			attackShips = { { "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier3" }, { "reb_ywing_tier3", "reb_z95_tier2", "reb_z95_tier2" } },
			tauntData = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 },
		},
		[A.M3] = {
			className = A.M3, questName = "imperial_ss_6", questType = "recovery", questZone = "space_yavin4",
			creditReward = 5000,
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 20, recoveryDelay = 30,
			recoverShip = "twilight_sun_tier1",
			recoveryConversationMobile = "object/mobile/shared_space_comm_imperial_ace_01.iff",
			escortShips = repeated("reb_z95_tier2", 4),
			preRecoveryPoints = recoveryPath("tatooine_imperial_twilight_", 1, 3),
			recoveryPoints = recoveryPath("tatooine_imperial_twilight_", 4, 6),
			attackDelay = 120,
			attackShips = { repeated("reb_xwing_tier2", 3), { "reb_xwing_tier2", "reb_xwing_tier2", "reb_ywing_tier2" } },
			tauntData = { panicCount = 5, thanksCount = 5 },
		},
		[A.DUTY1] = {
			className = A.DUTY1, questName = "lok_imperial_ss_2a", questType = "destroy_duty", questZone = "space_yavin4",
			creditReward = 200,
			sideQuest = false, sideQuestType = "",
			totalLevels = 5, totalRounds = 2, totalWaves = 3,
			bossShip = "deathstar_debris_priest_tier3",
			shipTypes = { repeated("deathstar_debris_guardian_tier2", 2), repeated("deathstar_debris_fanatic_tier2", 2) },
		},
		[A.DUTY2] = {
			className = A.DUTY2, questName = "lok_imperial_ss_2b", questType = "recovery_duty", questZone = "space_yavin4",
			creditReward = 2500, creditKillBonus = 200, numResponses = 5,
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 30, recoveryDelay = 60,
			recoverShip = "deathstar_debris_freighter_tier2",
			escortShips = repeated("deathstar_debris_guardian_tier2", 4),
			preRecoveryPoints = recoveryPath("yavin_imp_scavenger_", 1, 6),
			recoveryPoints = recoveryPath("yavin_imp_recovery_", 1, 6),
			attackDelay = 90,
			attackShips = { repeated("deathstar_debris_scavenger_tier2", 2), repeated("deathstar_debris_fanatic_tier2", 2) },
			tauntData = { panicCount = 5, thanksCount = 5 },
		},
		[A.DUTY3] = {
			className = A.DUTY3, questName = "lok_imperial_ss_2c", questType = "escort_duty", questZone = "space_yavin4",
			creditReward = 2500, creditKillBonus = 200,
			sideQuest = false, sideQuestType = "",
			escortShips = { "imp_freightermedium_tier2", "imp_freighterlight_tier2", "imp_freighterheavy_tier2" },
			escortPoints = escortPath("yavin_imp_escort_duty_", 1, 6),
			attackDelay = 120,
			attackShips = { repeated("deathstar_debris_fanatic_tier2", 2), repeated("deathstar_debris_guardian_tier2", 2) },
			tauntData = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 },
		},
	}
end

-- Conversation flow 3.4: TRAIN_CHOICES in table order (skill order of J2b canBuySkill1A..1D); same topics as Oberhaur's
A.TRAIN = T.TRAIN
A.TRAINED_REPLY = "s_8efde2ae"   -- "Yes, sir." on every trained screen
A.LATER = "s_ae26c22"
A.TRAINING_COST = 60000

-- Appendix A
A.SCREENS = require("storm_tier2_alozen_screens_data")

function A.screenRow(id)
	for _, row in ipairs(A.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

function A.screenIds()
	local out = {}

	for i, row in ipairs(A.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- The reply sids from `from` to `to` over the static options of Appendix A (breadth-first, in option order); nil when there is none.
-- `avoid` (set of screen ids) are never entered. Returns replies, ids (the screens shown, `from` first).
function A.walkTo(from, to, avoid)
	local queue, seen = { { id = from, replies = {}, ids = { from } } }, { [from] = true }

	while #queue > 0 do
		local cur = table.remove(queue, 1)

		if cur.id == to then
			return cur.replies, cur.ids
		end

		for _, o in ipairs(A.screenRow(cur.id).options) do
			if not seen[o[2]] and not (avoid and avoid[o[2]]) then
				seen[o[2]] = true

				local replies, ids = { table.unpack(cur.replies) }, { table.unpack(cur.ids) }

				replies[#replies + 1] = o[1]
				ids[#ids + 1] = o[2]
				queue[#queue + 1] = { id = o[2], replies = replies, ids = ids }
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

A.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		A.loadErrors[#A.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: every squadron file, Oberhaur's template and handler (storm_tier2_data.lua), Alozen's template and handler. A missing production
-- file is recorded in A.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function A.load()
	if loaded then
		return
	end

	loaded = true
	T.load()
	try("alozen_convo.lua", function() H.loadMobile("conversations/space/imperial/storm_squadron/alozen_convo.lua") end)
	try("alozenConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/storm_squadron/alozenConvoHandler.lua") end)
end

local function problems()
	return table.concat(T.loadErrors, " | ") .. table.concat(A.loadErrors, " | ")
end

A.problems = problems

-- Fails with the load problems when the template or handler could not be loaded
function A.requireConversation(lu)
	A.load()
	lu.assertNotNil(H.conversationTemplateTable(A.TEMPLATE), A.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. problems())
	lu.assertNotNil(rawget(_G, A.HANDLER), A.HANDLER .. " is not defined. Load problems: " .. problems())
end

function A.quest(global)
	A.load()

	return H.expectGlobal(global, "Storm tier 2 Alozen quest table (storm-tier2-alozen). Load problems: " .. problems())
end

function A.squadron() return T.squadron() end

function A.handler()
	A.load()

	return H.expectGlobal(A.HANDLER, "Alozen's conversation handler (storm-tier2-alozen). Load problems: " .. problems())
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = A.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

A.crc = crc

-- Quest state helpers on a built pilot. state: "complete" | "active" | "none"
function A.setState(player, global, state)
	local key = crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function A.state(player, global)
	local key = crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- Options (all optional; the default is a Storm pilot as Oberhaur sends him: all four tier 1 skills, two tier 2 skills (starships, weapons), Oberhaur's
-- three missions paid, the Alozen key and the initiate key set, pilot tier 2, standing 0, a ship, an inventory):
--   m          Alozen's missions 1..m won, :attempted and :reward set (default 0)
--   state      the state of mission m+1: "won" (complete, :attempted, unpaid) | "failed" (:attempted only) | "active" (:attempted, the head active)
--   alozen     TIER2_ALOZEN_KEY (default true); initiate: TIER2_INITIATE_KEY (default true)
--   t2         list of T.TRAIN indexes of the tier 2 skills held (default { 1, 2 })
--   pilotTier  ghost pilot tier (default 2, or 3 when all four tier 2 skills are held)
--   every other option is T.pilot's: pilot, faction, squadron, standing, t1, xp, series, datapad, ships, duty, species, inventory, inventoryFull, ship, inShip, zone
function A.pilot(o)
	o = o or {}
	A.load()

	local base = {}

	for k, v in pairs(o) do
		base[k] = v
	end

	base.m, base.state = nil, nil
	base.paid = 3
	base.t2 = o.t2 or { 1, 2 }
	base.alozen = o.alozen ~= false
	base.initiate = o.initiate ~= false
	base.pilotTier = o.pilotTier or (#base.t2 >= 4 and 3 or 2)

	local player = T.pilot(base)
	local paid = o.m or 0

	for n = 1, paid do
		A.setState(player, A.MISSIONS[n], "complete")
		H.setQuestStatus(player, A.STATUS[n] .. ":attempted", 1)
		H.setQuestStatus(player, A.STATUS[n] .. ":reward", 1)
	end

	local n = paid + 1

	if o.state ~= nil and A.MISSIONS[n] ~= nil then
		H.setQuestStatus(player, A.STATUS[n] .. ":attempted", 1)

		if o.state == "won" then
			A.setState(player, A.MISSIONS[n], "complete")
		elseif o.state == "active" then
			A.setState(player, A.MISSIONS[n], "active")
		end
	end

	return player
end

function A.npc() return H.newNpc({ name = "Alozen" }) end

-- runs fn with storm_tier2_data's drive/talk helpers pointed at Alozen's template and handler
local function asAlozen(fn, ...)
	local template, handler, npc = T.TEMPLATE, T.HANDLER, T.npc

	T.TEMPLATE, T.HANDLER, T.npc = A.TEMPLATE, A.HANDLER, A.npc

	local results = table.pack(pcall(fn, ...))

	T.TEMPLATE, T.HANDLER, T.npc = template, handler, npc

	if not results[1] then
		error(results[2], 0)
	end

	return table.unpack(results, 2, results.n)
end

local function requireLoaded()
	A.load()

	if H.conversationTemplateTable(A.TEMPLATE) == nil or rawget(_G, A.HANDLER) == nil then
		error("Alozen's conversation is not loaded. Load problems: " .. problems(), 3)
	end
end

-- Talks to Alozen from the first screen. choices as for H.converse (0-based indexes, option sids, hooks).
function A.talk(player, choices)
	requireLoaded()

	return H.converse({ template = A.TEMPLATE, player = player, npc = A.npc(), choices = choices })
end

function A.firstScreen(player) return A.talk(player)[1].id end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices`
function A.drive(player, startId, choices)
	requireLoaded()

	return asAlozen(T.drive, player, startId, choices)
end

A.ids = T.ids
A.optionSids = T.optionSids
A.linksOf = T.linksOf
A.useSkillCosts = T.useSkillCosts
A.bought = T.bought
A.free = T.free
A.held = T.held
A.items = T.items

-- Spies startQuest on every Alozen quest table; returns the call lists by global
function A.spyStarts()
	local starts = {}

	for _, g in ipairs(A.GLOBALS) do
		starts[g] = H.spyOn(A.quest(g), "startQuest")
	end

	return starts
end

-- "global xN" strings of the quests whose startQuest was called
function A.startedGlobals(starts)
	local out = {}

	for _, g in ipairs(A.GLOBALS) do
		if #starts[g] > 0 then
			out[#out + 1] = g .. " x" .. #starts[g]
		end
	end

	return out
end

return A
