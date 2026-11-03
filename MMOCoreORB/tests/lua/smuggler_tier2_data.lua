-- Shared test data and builders for Smuggler tier 2 (Shamdon Kree, Lucky Despot, Mos Eisley), not a test file.
-- Spec: .claude/work/smuggler-tier2-shamdon/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A, B and C; Q1 = A).
--
-- The quest values are DERIVED from the SWG-Source files in fixtures/ (M.expected): the seven spacequest .tab files, the four buildout excerpts
-- space_zones/buildout/space_<zone>.smuggler_tier2_points.tab (truncated toward zero, as Core3's patrol point files hold them) and the Shamdon script
-- (credits and reward items). Only what no SWG file decides (radius 250, failTimer 20, the class names) is a spec literal.
--   M.expected()               the whole table of each quest global (Appendix B: a key not listed must not be set)
--   M.SCREENS / M.TEXT         Appendix A (smuggler_tier2_screens_data.lua) / the client text of the 100 lines (smuggler_tier2_client_text.lua)
--   M.TRAIN                    TRAIN_CHOICES (Content contract 3): starships, weapons, procedures, droid, each with its mission n and briefing
--   M.load()                   the server's load: squadrons, Dravis, Karrde, then Shamdon's template and handler, collecting load errors
--   M.pilot{...}               a pilot standing in front of Shamdon (see the option list at M.pilot)
--   M.talk / M.drive           H.converse from the first screen / from a given screen (Shamdon); Karrde: M.karrdeTalk
--   M.snapshot(player)         everything a pure gate must not change (I-9)
--
-- Shamdon's conversation lives in the template "shamdon_kree_convo_template", its handler is the global "shamdonKreeConvoHandler".

local H = require("harness")
local S = require("smuggler_tier1_data")
local T = require("smuggler_transition_data")

local M = {}

M.TEMPLATE = "shamdon_kree_convo_template"
M.HANDLER = "shamdonKreeConvoHandler"
M.PREFIX = "@conversation/tatooine_privateer_trainer_shamdon:"
M.STF = "conversation/tatooine_privateer_trainer_shamdon"
M.KARRDE_STF = "conversation/tatooine_privateer_trainer_2"

M.TEMPLATE_FILE = "mobile/conversations/space/neutral/smuggler_squadron/shamdon_kree_convo.lua"
M.HANDLER_FILE = "screenplays/space/conversations/neutral/smuggler_squadron/shamdonKreeConvoHandler.lua"
M.SQUADRON_FILE = S.SQUADRON_FILE
M.NPC_FILE = "mobile/space/shamdon_kree.lua"
M.INCLUDE_TEMPLATE = 'includeFile("conversations/space/neutral/smuggler_squadron/shamdon_kree_convo.lua")'
M.INCLUDE_HANDLER = 'includeFile("space/conversations/neutral/smuggler_squadron/shamdonKreeConvoHandler.lua")'
M.KARRDE_INCLUDE_TEMPLATE = T.INCLUDE_TEMPLATE
M.KARRDE_INCLUDE_HANDLER = T.INCLUDE_HANDLER

M.SHJ = H.FIXTURES .. "script/conversation/tatooine_privateer_trainer_shamdon.java"
M.SWG_DIR = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"

-- Content contract 1: the seven globals in section order
M.A1 = "assassinate_tatooine_privateer_tier2_1a"
M.A2 = "assassinate_tatooine_privateer_tier2_2a"
M.A3 = "assassinate_tatooine_privateer_tier2_3a"
M.E4 = "escort_tatooine_privateer_tier2_4a"
M.DUTY_ESCORT = "escort_duty_tatooine_privateer_tier2_1"
M.DUTY_RECOVERY = "recovery_duty_tatooine_privateer_tier2_1"
M.DUTY_DESTROY = "destroy_duty_tatooine_privateer_tier2_1"

M.GLOBALS = { M.A1, M.A2, M.A3, M.E4, M.DUTY_ESCORT, M.DUTY_RECOVERY, M.DUTY_DESTROY }
M.HEADS = { M.A1, M.A2, M.A3, M.E4 } -- MISSIONS[n].head
M.DUTIES = { M.DUTY_ESCORT, M.DUTY_RECOVERY, M.DUTY_DESTROY }

-- global -> { class, type, name, zone }
M.IDENTITY = {
	[M.A1] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "tatooine_privateer_tier2_1a", zone = "space_lok" },
	[M.A2] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "tatooine_privateer_tier2_2a", zone = "space_dantooine" },
	[M.A3] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "tatooine_privateer_tier2_3a", zone = "space_yavin4" },
	[M.E4] = { class = "SpaceEscortScreenplay", type = "escort", name = "tatooine_privateer_tier2_4a", zone = "space_tatooine" },
	[M.DUTY_ESCORT] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "tatooine_privateer_tier2_1", zone = "space_lok" },
	[M.DUTY_RECOVERY] = { class = "SpaceDutyRecoveryScreenplay", type = "recovery_duty", name = "tatooine_privateer_tier2_1", zone = "space_dantooine" },
	[M.DUTY_DESTROY] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "tatooine_privateer_tier2_1", zone = "space_yavin4" },
}

-- Content contract 2: the squadron object's constants
M.QUEST_STRINGS = {
	TIER2_QUEST_STRING_1 = { type = "assassinate", name = "tatooine_privateer_tier2_1a" },
	TIER2_QUEST_STRING_2 = { type = "assassinate", name = "tatooine_privateer_tier2_2a" },
	TIER2_QUEST_STRING_3 = { type = "assassinate", name = "tatooine_privateer_tier2_3a" },
	TIER2_QUEST_STRING_4 = { type = "escort", name = "tatooine_privateer_tier2_4a" },
	TIER2_QUEST_STRING_DUTY_1 = { type = "escort_duty", name = "tatooine_privateer_tier2_1" },
	TIER2_QUEST_STRING_DUTY_2 = { type = "recovery_duty", name = "tatooine_privateer_tier2_1" },
	TIER2_QUEST_STRING_DUTY_3 = { type = "destroy_duty", name = "tatooine_privateer_tier2_1" },
}

-- the quest-name part of the :attempted / :reward status keys (TIER2_QUEST_STRING_n.name), mission n = 1..4
M.STATUS_NAMES = { "tatooine_privateer_tier2_1a", "tatooine_privateer_tier2_2a", "tatooine_privateer_tier2_3a", "tatooine_privateer_tier2_4a" }

function M.statusKeys()
	local out = {}

	for n = 1, 4 do
		out[#out + 1] = M.STATUS_NAMES[n] .. ":attempted"
		out[#out + 1] = M.STATUS_NAMES[n] .. ":reward"
	end

	return out
end

-- Content contract 3, TRAIN_CHOICES (table order = SWG canonical: starships, weapons, procedures, droid). mission = the SHJ skill -> mission link ("Mn").
M.TRAIN = {
	{ x = "starships", skill = "pilot_neutral_starships_02", reply = "s_45b71b4d", trained = "trained_starships", closing = "s_dfd3392c", mission = 1, brief = "m1_brief" },
	{ x = "weapons", skill = "pilot_neutral_weapons_02", reply = "s_197f4f94", trained = "trained_weapons", closing = "s_2fef6afd", mission = 3, brief = "m3_brief" },
	{ x = "procedures", skill = "pilot_neutral_procedures_02", reply = "s_8f5942fa", trained = "trained_procedures", closing = "s_d5a42663", mission = 4, brief = "m4_brief" },
	{ x = "droid", skill = "pilot_neutral_droid_02", reply = "s_eff66f4d", trained = "trained_droid", closing = "s_d5a42663", mission = 2, brief = "m2_brief" },
}

M.YES, M.NO = "s_36a4e374", "s_da9a29e9" -- "Yes, I am." / "No, not yet."

-- mission n -> the TRAIN entry whose skill grants it
function M.trainFor(n)
	for _, t in ipairs(M.TRAIN) do
		if t.mission == n then
			return t
		end
	end
end

M.TRANS_PAY = 5000
M.MISSION_CREDITS = 5000

M.SCREENS = require("smuggler_tier2_screens_data")
M.TEXT = require("smuggler_tier2_client_text")

function M.screenRow(id)
	for _, row in ipairs(M.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (59), sorted
function M.screenIds()
	local out = {}

	for i, row in ipairs(M.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- The ids this feature uses: the dialog of every screen and every reply of Appendix A (100 = the STF lines)
function M.usedIds()
	local set = {}

	for _, row in ipairs(M.SCREENS) do
		set[row.sid] = true

		for _, o in ipairs(row.options) do
			set[o[1]] = true
		end
	end

	local out = {}

	for id in pairs(set) do
		out[#out + 1] = id
	end

	table.sort(out)
	return out
end

-- Appendix C: Karrde's four K3 screens, in K order
M.KARRDE_K3 = {
	{ id = "series_done", sid = "s_697e04cf", animation = "tap_foot", stop = false, options = { { "s_98893f74", "jabba_wants_you", "" } } },
	{ id = "jabba_wants_you", sid = "s_fa31c92f", animation = "applause_polite", stop = false, options = { { "s_de9b68cd", "jabba_respects", "" } } },
	{ id = "jabba_respects", sid = "s_7642f4a4", animation = "point_accusingly", stop = false, options = { { "s_805cb6f3", "see_beissa", "" } } },
	{ id = "see_beissa", sid = "s_9504aca1", animation = "nod_head_once", stop = true, options = {} },
}

---------------------------------------------------------------------------------------------
-- The oracle: values from the SWG-Source fixtures
---------------------------------------------------------------------------------------------

local function trunc(v) return v >= 0 and math.floor(v) or -math.floor(-v) end

M.trunc = trunc

local function readFile(path)
	local f = io.open(path, "r")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()
	return text
end

M.readFile = readFile

M.ZONES = { "lok", "dantooine", "yavin4", "tatooine" }

local buildoutCache = {}

-- nav point name -> { x, z, y } of the zone's excerpt (fltPX, fltPY, fltPZ truncated toward zero: the Core3 point files' values)
function M.buildout(zone)
	if buildoutCache[zone] == nil then
		local tab = H.fixture("space_zones/buildout/" .. zone .. ".smuggler_tier2_points.tab")
		local out = {}

		for _, rec in ipairs(tab.records) do
			local nav = (rec:get("strObjVars") or ""):match("nav_name|4|([^|]+)|")

			if nav ~= nil then
				out[nav] = { trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ")) }
			end
		end

		buildoutCache[zone] = out
	end

	return buildoutCache[zone]
end

-- The rewards of the four missions, parsed from SHJ: giveReward(player, "<type>", "<name>", <credits>, "<item>"). Returns name -> { credits, item }
function M.shamdonRewards()
	local java = readFile(M.SHJ)
	local out = {}

	if java == nil then
		return out
	end

	for questType, name, credits, item in java:gmatch('giveReward%(player, "(%w+)", "([%w_]+)", (%d+), "([^"]+)"%)') do
		out[questType .. "/" .. name] = { credits = tonumber(credits), item = item }
	end

	return out
end

-- the credits Shamdon pays for the transition: SHJ giveReward(player, "assassinate", "tat_priv_quest_trans", N)
function M.shamdonTransReward() return T.shamdonReward() end

function M.fixtureOf(global)
	local id = M.IDENTITY[global]

	return H.questFixture(id.type, id.name)
end

-- Points of a .tab column: { name, zone, x, z, y } from the buildout excerpts
function M.pointsOf(rec, column)
	local out = {}

	for i, value in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(value)
		local xyz = M.buildout(zone)[name]

		assert(xyz ~= nil, "the buildout excerpt of " .. tostring(zone) .. " has no nav point " .. tostring(name))
		out[i] = { name = name, zone = zone, x = xyz[1], z = xyz[2], y = xyz[3] }
	end

	return out
end

local function attackLists(rec)
	local lists = {}

	for i = 1, rec:num("numAttackShipLists") do
		lists[i] = rec:list("attackShips" .. i)
	end

	return lists
end

-- Data mapping 1, derived from the fixtures. Returns { [global] = whole table (Appendix B) }.
function M.expected()
	local rewards = M.shamdonRewards()
	local out = {}

	local function story(global)
		local id = M.IDENTITY[global]
		local rw = rewards[id.type .. "/" .. id.name]

		assert(rw ~= nil, "SHJ has no giveReward for " .. id.type .. "/" .. id.name)
		return rw
	end

	for _, global in ipairs({ M.A1, M.A2, M.A3 }) do
		local id = M.IDENTITY[global]
		local rec = M.fixtureOf(global)
		local rw = story(global)
		local targetPatrols = {}

		for i, p in ipairs(M.pointsOf(rec, "escortPath")) do
			targetPatrols[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y }
		end

		out[global] = {
			className = global, questType = id.type, questName = id.name, questZone = rec:get("questZone"),
			creditReward = rw.credits, itemReward = { { species = { -1 }, item = rw.item } },
			sideQuest = false, sideQuestType = "",
			arrivalDelay = rec:num("targetArrivalDelay"), failTimer = 20, mustDestroyEscort = rec:num("mustDestroyEscort") == 1,
			assassinateSpawns = { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") },
			targetPatrols = targetPatrols,
		}
	end

	do
		local rec = M.fixtureOf(M.E4)
		local id = M.IDENTITY[M.E4]
		local rw = story(M.E4)
		local m = math.max(rec:num("numResponses") or 0, 1)
		local points = {}

		for i, p in ipairs(M.pointsOf(rec, "escortPath")) do
			points[i] = { patrolPointName = p.name, zoneName = p.zone, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		out[M.E4] = {
			className = M.E4, questType = id.type, questName = id.name, questZone = rec:get("questZone"),
			creditReward = rw.credits, itemReward = { { species = { -1 }, item = rw.item } },
			sideQuest = false, sideQuestType = "",
			escortShips = { rec:get("escortShipType") }, escortPoints = points,
			attackDelay = rec:num("attackPeriod"), attackShips = attackLists(rec),
			tauntData = { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m },
		}
	end

	do
		local rec = M.fixtureOf(M.DUTY_ESCORT)
		local id = M.IDENTITY[M.DUTY_ESCORT]
		local m = math.max(rec:num("numResponses") or 0, 1)
		local points = {}

		for i, p in ipairs(M.pointsOf(rec, "escortPoints")) do
			points[i] = { patrolPointName = p.name, zoneName = p.zone, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		out[M.DUTY_ESCORT] = {
			className = M.DUTY_ESCORT, questType = id.type, questName = id.name, questZone = rec:get("questZone"),
			creditReward = rec:num("reward"), creditKillBonus = rec:num("killReward"),
			sideQuest = false, sideQuestType = "",
			escortShips = rec:list("escortShipTypes"), escortPoints = points,
			attackDelay = rec:num("attackPeriod"), attackShips = attackLists(rec),
			tauntData = { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m },
		}
	end

	do
		local rec = M.fixtureOf(M.DUTY_RECOVERY)
		local id = M.IDENTITY[M.DUTY_RECOVERY]
		local pre, rec2 = {}, {}

		for i, p in ipairs(M.pointsOf(rec, "escortPath")) do
			pre[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		for i, p in ipairs(M.pointsOf(rec, "recoveryPath")) do
			rec2[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		out[M.DUTY_RECOVERY] = {
			className = M.DUTY_RECOVERY, questType = id.type, questName = id.name, questZone = rec:get("questZone"),
			creditReward = rec:num("reward"), creditKillBonus = rec:num("killReward"), numResponses = rec:num("numResponses"),
			sideQuest = false, sideQuestType = "",
			arrivalDelay = rec:num("targetArrivalDelay"), recoveryDelay = rec:num("targetRecoverTime"),
			recoverShips = rec:list("targetShipTypes"), escortShips = rec:list("targetEscort"),
			preRecoveryPoints = pre, recoveryPoints = rec2,
			attackDelay = rec:num("attackPeriod"), attackShips = attackLists(rec),
			tauntData = { panicCount = rec:num("numResponses"), thanksCount = rec:num("numResponses") },
		}
	end

	do
		local rec = M.fixtureOf(M.DUTY_DESTROY)
		local id = M.IDENTITY[M.DUTY_DESTROY]
		local lists = {}

		for i = 1, rec:num("shipTypes") do
			lists[i] = rec:list("shipType" .. i)
		end

		out[M.DUTY_DESTROY] = {
			className = M.DUTY_DESTROY, questType = id.type, questName = id.name, questZone = rec:get("questZone"),
			creditReward = rec:num("reward"),
			sideQuest = false, sideQuestType = "",
			totalLevels = rec:num("levelsPerDuty"), totalRounds = rec:num("roundsPerLevel"), totalWaves = rec:num("wavesPerRound"),
			bossShip = rec:get("bossType"), shipTypes = lists,
		}
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

M.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		M.loadErrors[#M.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: everything the transition and tier 1 features load (squadrons, Dravis, Karrde), then Shamdon's template and handler. A missing
-- production file is recorded in M.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function M.load()
	if loaded then
		return
	end

	loaded = true
	T.load()

	for _, e in ipairs(T.loadErrors) do
		M.loadErrors[#M.loadErrors + 1] = e
	end

	try("shamdon_kree_convo.lua", function() H.loadMobile("conversations/space/neutral/smuggler_squadron/shamdon_kree_convo.lua") end)
	try("shamdonKreeConvoHandler.lua", function() H.loadScreenplay("space/conversations/neutral/smuggler_squadron/shamdonKreeConvoHandler.lua") end)
end

function M.problems() return table.concat(M.loadErrors, " | ") end

-- Sorted names of the loaded quest tables (a global whose className is its own name and whose questName is set; SpaceQuestLogic itself is a class): the quest classes (SpaceQuestLogic, ...) share their methods with every
-- table, so a spy on a class would replace the method for all of them
function M.questTables()
	local out = {}

	for _, name in ipairs(H.questGlobals()) do
		local q = rawget(_G, name)

		if type(q) == "table" and rawget(q, "className") == name and rawget(q, "questName") ~= "" then
			out[#out + 1] = name
		end
	end

	return out
end

-- Fails with the load problems when the template or handler could not be loaded
function M.requireConversation(lu)
	M.load()
	lu.assertNotNil(H.conversationTemplateTable(M.TEMPLATE), M.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. M.problems())
	lu.assertNotNil(rawget(_G, M.HANDLER), M.HANDLER .. " is not defined. Load problems: " .. M.problems())
end

function M.quest(global)
	M.load()

	return H.expectGlobal(global, "Smuggler tier 2 quest table (smuggler-tier2-shamdon). Load problems: " .. M.problems())
end

-- the squadron object (SmugglerSquadronScreenplay), with the load problems in the failure message
function M.squadron()
	M.load()

	return H.expectGlobal("SmugglerSquadronScreenplay", "Smuggler squadron screenplay object. Load problems: " .. M.problems())
end

function M.handler() return rawget(_G, M.HANDLER) end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = M.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

M.crc = crc

-- state: "complete" | "active" | "none"
function M.setState(player, global, state)
	local key = crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function M.state(player, global)
	local key = crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- A mission's state on a pilot, by name (n = 1..4):
--   fresh     nothing
--   attempted :attempted only (a failed or aborted mission)
--   active    :attempted, the head active in the journal
--   won       :attempted, the head complete, :reward unset (the reward is waiting)
--   paid      :attempted, the head complete, :reward set
function M.setMission(player, n, state)
	local head = M.HEADS[n]
	local name = M.STATUS_NAMES[n]

	M.setState(player, head, "none")
	player.ghost.journalComplete[crc(head)] = nil

	if state == "fresh" then
		removeQuestStatus(player.objectID .. name .. ":attempted")
	else
		H.setQuestStatus(player, name .. ":attempted", 1)
	end

	if state == "paid" then
		H.setQuestStatus(player, name .. ":reward", 1)
	else
		removeQuestStatus(player.objectID .. name .. ":reward")
	end

	if state == "active" then
		M.setState(player, head, "active")
	elseif state == "won" or state == "paid" then
		M.setState(player, head, "complete")
	end
end

-- Options (all optional; the default is a Smuggler with all four tier 1 skills, pilot tier 2, the transition won AND paid by Shamdon, no tier 2 skill,
-- no tier 2 mission state, no XP, a man):
--   trans      one of T.STATE_NAMES (default "won")
--   rewarded   false: Shamdon has not paid the transition yet (default true)
--   skills2    list of tier 2 skill x names held ("starships", "weapons", "procedures", "droid"); tier2 = n holds the first n of M.TRAIN
--   missions   { [n] = state } (see M.setMission), n = 1..4
--   all4       true: the four tier 2 skills held and missions 1..4 paid (a tier 2 graduate)
--   duty2      global of a Shamdon duty active in the journal
--   gender     0 (default, male) | 1 (female)
--   xp         space_combat_general experience (default 0)
--   and every S.pilot / T.pilot option (squadron, pilot, faction, tier, datapad, duty, zone, inShip, species, pilotTier, ...)
function M.pilot(o)
	o = o or {}
	M.load()

	local to = {}

	for k, v in pairs(o) do
		if k ~= "skills2" and k ~= "tier2" and k ~= "missions" and k ~= "all4" and k ~= "duty2" and k ~= "gender" and k ~= "rewarded" and k ~= "trans" then
			to[k] = v
		end
	end

	to.trans = o.trans or "won"
	to.rewarded = o.rewarded ~= false

	local skills = {}

	for _, x in ipairs(to.skills or {}) do
		skills[#skills + 1] = x
	end

	local held = {}

	for _, x in ipairs(o.skills2 or {}) do
		held[x] = true
	end

	for i = 1, (o.tier2 or (o.all4 and 4) or 0) do
		held[M.TRAIN[i].x] = true
	end

	for _, t in ipairs(M.TRAIN) do
		if held[t.x] then
			skills[#skills + 1] = t.skill
		end
	end

	to.skills = skills

	local player = T.pilot(to)

	player.gender = o.gender

	for n = 1, 4 do
		local state = (o.missions or {})[n]

		if state == nil and o.all4 then
			state = "paid"
		end

		if state ~= nil then
			M.setMission(player, n, state)
		end
	end

	if o.duty2 then
		M.setState(player, o.duty2, "active")
	end

	return player
end

-- true when the transition reward key is set
function M.transPaid(player) return H.getQuestStatus(player, T.REWARD) == "1" end

function M.npc() return H.newNpc({ name = "Shamdon Kree" }) end

function M.requireConversationLoaded()
	M.load()

	if H.conversationTemplateTable(M.TEMPLATE) == nil or rawget(_G, M.HANDLER) == nil then
		error("Shamdon's conversation is not loaded. Load problems: " .. M.problems(), 3)
	end
end

-- Talks to Shamdon from the first screen. choices as for H.converse.
function M.talk(player, choices)
	M.requireConversationLoaded()

	return H.converse({ template = M.TEMPLATE, player = player, npc = M.npc(), choices = choices })
end

-- The id of the first screen of a fresh talk
function M.firstScreen(player) return M.talk(player)[1].id end

-- Karrde's first screen / talk (his template and handler are loaded by M.load)
function M.karrdeTalk(player, choices)
	M.load()

	return T.talk(player, choices)
end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session.
function M.drive(player, startId, choices)
	M.requireConversationLoaded()

	local tmpl = H.conversationTemplate(M.TEMPLATE)
	local handler = rawget(_G, M.HANDLER)
	local npc = M.npc()
	local session = H.Fakes.newConversationSession(npc)
	local transcript = {}

	player.conversationSession = session

	local function show(screen)
		local options = {}

		for i, o in ipairs(screen.options) do
			options[i] = { text = o.text, link = o.link }
		end

		transcript[#transcript + 1] = { id = screen.id, text = screen.dialogText, options = options, params = screen.params, stop = screen.stopConversation }
	end

	local screen = LuaConversationTemplate(tmpl):getScreen(startId)

	if screen == nil then
		error("screen '" .. startId .. "' is not in " .. M.TEMPLATE, 2)
	end

	screen = handler:runScreenHandlers(tmpl, player, npc, 0, screen)

	if screen == nil then
		error("runScreenHandlers returned no screen for '" .. startId .. "'", 2)
	end

	session.lastScreen = screen
	show(screen)

	local i = 1

	while i <= #(choices or {}) and not screen.stopConversation do
		local choice = choices[i]

		i = i + 1

		if type(choice) == "function" then
			choice(player)
		else
			if type(choice) == "string" then
				local found

				for k, o in ipairs(screen.options) do
					if o.text == choice or o.text:sub(-#choice - 1) == ":" .. choice then
						found = k - 1
						break
					end
				end

				if found == nil then
					local have = {}

					for k, o in ipairs(screen.options) do
						have[k] = tostring(o.text)
					end

					error("screen '" .. screen.id .. "' has no option '" .. choice .. "'; options are: " .. table.concat(have, ", "), 2)
				end

				choice = found
			end

			screen = handler:getNextConversationScreen(tmpl, player, choice, npc)

			if screen ~= nil then
				screen = handler:runScreenHandlers(tmpl, player, npc, choice, screen)
			end

			session.lastScreen = screen

			if screen == nil then
				break
			end

			show(screen)
		end
	end

	return transcript
end

M.ids = S.ids
M.optionSids = S.optionSids
M.linksOf = S.linksOf

-- Engine XP prices of the four tier 2 skills, from the SWG skills.tab excerpt (fixtures/skill/skills.pilot_neutral_02.tab, 60000 each)
function M.useSkillCosts()
	local costs = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_neutral_02.tab").records) do
		local name = rec:get("NAME")

		if name ~= nil and name:match("^pilot_neutral_%a+_02$") then
			costs[name] = rec:num("XP_COST")
		end
	end

	H.Engine.config.skillXpCosts = costs

	return costs
end

M.TRAINING_COST = 60000

function M.bought() return H.Engine.callsTo("skillManagerAwardSkill") end
function M.free() return H.Engine.callsTo("awardSkill") end

-- Tier 2 skills the pilot holds, in M.TRAIN order
function M.held2(player)
	local out = {}

	for _, t in ipairs(M.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

local function copy(t)
	local out = {}

	for k, v in pairs(t) do
		out[k] = v
	end

	return out
end

local function itemList(player)
	local out = {}

	if player.inventory ~= nil then
		for i, item in ipairs(player.inventory.items or {}) do
			out[i] = item
		end
	end

	return out
end

-- Everything a pure gate must not change (I-9): journal, quest status keys, skills, credits, pilot tier, items, shared memory, and the number of
-- events, ships and waypoints created. Compare with lu.assertEquals(M.snapshot(p), before, label).
function M.snapshot(player)
	return {
		active = copy(player.ghost.journalActive),
		complete = copy(player.ghost.journalComplete),
		status = copy(H.Fakes.questStatus),
		skills = copy(player.skills),
		bank = player.bankCredits,
		bankLog = #(player.bankCreditLog or {}),
		pilotTier = player.ghost.pilotTier,
		items = itemList(player),
		memory = H.Engine.sharedMemoryKeys(),
		events = #H.Engine.callsTo("createEvent"),
		ships = #H.spawnedShips(),
		waypoints = #player.ghost.waypoints,
		missions = #(player.datapad and player.datapad.items or {}),
		grants = #H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"),
	}
end

return M
