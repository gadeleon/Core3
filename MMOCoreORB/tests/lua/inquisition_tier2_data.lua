-- Shared test data and builders for Inquisition tier 2 (Inquisitor Fa'Zoll), not a test file.
-- Spec: .claude/work/inquisition-tier2-fa-zoll/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself:
--   I.GLOBALS / I.IDENTITY     the 7 quest globals and their class, type and name (Content contract 1)
--   I.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   I.POINTS / I.SPAWNERS      Data mapping 2: the naboo and dantooine nav points and the inspect spawner, Core3 x, z, y
--   I.SCREENS                  Appendix A (inquisition_tier2_screens_data.lua, generated from the spec table by a scratch script)
--   I.TRAIN                    TRAIN_CHOICES (Conversation flow 3.4)
--   I.load()                   the server's load of the squadron files, both templates and both handlers, collecting load errors
--   I.pilot{...}               a pilot standing in front of Fa'Zoll (see the option list at I.pilot)
--   I.talk / I.drive           H.converse from the first screen / from a given screen
--
-- Fa'Zoll's conversation lives in the template "fa_zoll_convo_template", its handler is the global "faZollConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")

local I = {}

I.TEMPLATE = "fa_zoll_convo_template"
I.HANDLER = "faZollConvoHandler"
I.PREFIX = "@conversation/naboo_imperial_trainer_2:"
I.STF = "conversation/naboo_imperial_trainer_2"

I.TEMPLATE_FILE = "mobile/conversations/space/imperial/inquisition_squadron/fa_zoll_convo.lua"
I.HANDLER_FILE = "screenplays/space/conversations/imperial/inquisition_squadron/faZollConvoHandler.lua"
I.SQUADRON_FILE = "screenplays/space/squadrons/InquisitionSquadronScreenplay.lua"
I.NPC_FILE = "mobile/space/fa_zoll.lua"
I.BARN_TEMPLATE = "barn_sinkko_convo_template"
I.BARN_HANDLER = "barnSinkkoConvoHandler"

I.M1 = "inspect_naboo_imperial_tier2_1"
I.M2 = "survival_naboo_imperial_tier2_2"
I.M3 = "recovery_naboo_imperial_tier2_3"
I.M4 = "assassinate_naboo_imperial_tier2_4"
I.DUTY1 = "recovery_duty_naboo_imperial_tier2_recoveryduty"
I.DUTY2 = "escort_duty_naboo_imperial_tier2_escortduty"
I.DUTY3 = "destroy_duty_naboo_imperial_tier2_destroyduty"

I.GLOBALS = { I.M1, I.M2, I.M3, I.M4, I.DUTY1, I.DUTY2, I.DUTY3 }
I.MISSIONS = { I.M1, I.M2, I.M3, I.M4 }
I.DUTIES = { I.DUTY1, I.DUTY2, I.DUTY3 }

-- The tier 1 globals (they register before the tier 2 globals)
I.TIER1_GLOBALS = {
	"patrol_naboo_imperial_1", "destroy_surpriseattack_naboo_imperial_1", "destroy_naboo_imperial_2", "patrol_naboo_imperial_3",
	"escort_naboo_imperial_3", "assassinate_naboo_imperial_4", "destroy_duty_naboo_imperial_6", "escort_duty_naboo_imperial_7",
}

-- global -> { class, type, name, zone }
I.IDENTITY = {
	[I.M1] = { class = "SpaceInspectScreenplay", type = "inspect", name = "naboo_imperial_tier2_1", zone = "space_naboo" },
	[I.M2] = { class = "SpaceSurvivalScreenplay", type = "survival", name = "naboo_imperial_tier2_2", zone = "space_dantooine" },
	[I.M3] = { class = "SpaceRecoveryScreenplay", type = "recovery", name = "naboo_imperial_tier2_3", zone = "space_naboo" },
	[I.M4] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "naboo_imperial_tier2_4", zone = "space_dantooine" },
	[I.DUTY1] = { class = "SpaceDutyRecoveryScreenplay", type = "recovery_duty", name = "naboo_imperial_tier2_recoveryduty", zone = "space_naboo" },
	[I.DUTY2] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "naboo_imperial_tier2_escortduty", zone = "space_naboo" },
	[I.DUTY3] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "naboo_imperial_tier2_destroyduty", zone = "space_dantooine" },
}

-- Content contract 2: the squadron object's constants
I.QUEST_STRINGS = {
	TIER2_QUEST_STRING_1 = { type = "inspect", name = "naboo_imperial_tier2_1" },
	TIER2_QUEST_STRING_2 = { type = "survival", name = "naboo_imperial_tier2_2" },
	TIER2_QUEST_STRING_3 = { type = "recovery", name = "naboo_imperial_tier2_3" },
	TIER2_QUEST_STRING_4 = { type = "assassinate", name = "naboo_imperial_tier2_4" },
	TIER2_QUEST_STRING_DUTY_1 = { type = "recovery_duty", name = "naboo_imperial_tier2_recoveryduty" },
	TIER2_QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "naboo_imperial_tier2_escortduty" },
	TIER2_QUEST_STRING_DUTY_3 = { type = "destroy_duty", name = "naboo_imperial_tier2_destroyduty" },
}

-- The tier 1 constants must stay as they are (AC-1)
I.TIER1_QUEST_STRINGS = {
	QUEST_STRING_1 = { type = "patrol", name = "naboo_imperial_1" },
	QUEST_STRING_1_SIDE = { type = "destroy_surpriseattack", name = "naboo_imperial_1" },
	QUEST_STRING_2 = { type = "destroy", name = "naboo_imperial_2" },
	QUEST_STRING_3 = { type = "patrol", name = "naboo_imperial_3" },
	QUEST_STRING_3_SIDE = { type = "escort", name = "naboo_imperial_3" },
	QUEST_STRING_4 = { type = "assassinate", name = "naboo_imperial_4" },
	QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "naboo_imperial_6" },
	QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "naboo_imperial_7" },
}

I.SERIES_SUFFIX = "InquisitionSquadronScreenplay:naboo_imperial_1"
I.AGENT_SUFFIX = "InquisitionSquadronScreenplay:inquisitorialAgent"
I.TIER1_ABORTED_SUFFIX = "naboo_imperial_2:aborted"

-- Status names of the four story missions: "<playerID>naboo_imperial_tier2_<n>:attempted" / ":reward"
local function statusName(n) return "naboo_imperial_tier2_" .. n end

I.STATUS = { statusName(1), statusName(2), statusName(3), statusName(4) }

-- Data mapping 2: name -> { x, z, y }
I.POINTS = {
	space_naboo = {
		naboo_imperial_tier2_recovery1_1 = { -999, 0, 2999 },
		naboo_imperial_tier2_recovery1_2 = { -1406, -2515, 2245 },
		naboo_imperial_tier2_recovery1_3 = { 262, -3151, 332 },
		naboo_imperial_tier2_recovery1_4 = { 3200, -3283, -4180 },
		naboo_imperial_tier2_recovery1_5 = { 3001, -1795, -3659 },
		naboo_imperial_tier2_recovery1_6 = { 1813, 752, -2740 },
		naboo_imperial_tier2_recovery1_7 = { 1416, 3650, -2137 },
		naboo_imperial_tier2_recoveryduty_1 = { 3331, -3465, -3994 },
		naboo_imperial_tier2_recoveryduty_2 = { 1333, -1855, -3915 },
		naboo_imperial_tier2_recoveryduty_3 = { -976, -14, -3990 },
		naboo_imperial_tier2_recoveryduty_4 = { -1492, 746, -2021 },
		naboo_imperial_tier2_recoveryduty_5 = { -1376, 650, -2028 },
		naboo_imperial_tier2_recoveryduty_6 = { 417, -839, -2617 },
		naboo_imperial_tier2_recoveryduty_7 = { 2197, -2348, -3252 },
		naboo_imperial_tier2_recoveryduty_8 = { 3875, -3872, -3934 },
		naboo_imperial_tier2_escortduty_1 = { 3190, -3175, 3169 },
		naboo_imperial_tier2_escortduty_2 = { 856, -803, 781 },
		naboo_imperial_tier2_escortduty_3 = { -244, 234, -206 },
		naboo_imperial_tier2_escortduty_4 = { -1352, 1269, -1205 },
		naboo_imperial_tier2_escortduty_5 = { -2169, 2068, -2002 },
		naboo_imperial_tier2_escortduty_6 = { -3203, 3201, -3078 },
	},
	space_dantooine = {
		naboo_imperial_tier2_survival1 = { 4000, -2500, -5600 },
		naboo_imperial_tier2_assassinate1_1 = { -5000, 1000, -4500 },
		naboo_imperial_tier2_assassinate1_2 = { -3384, 2570, -1024 },
		naboo_imperial_tier2_assassinate1_3 = { -2204, 3766, 1598 },
		naboo_imperial_tier2_assassinate1_4 = { -1274, 2051, 3666 },
		naboo_imperial_tier2_assassinate1_5 = { -1474, 597, 5612 },
	},
}

I.SPAWNERS = {
	space_naboo = {
		naboo_imperial_tier2_inspect1_spawner = { -1500, 1000, 3200 },
	},
}

I.ITEM_ROOT = "object/tangible/ship/components/"

I.ITEMS = {
	[I.M1] = I.ITEM_ROOT .. "weapon/wpn_mission_reward_imperial_cygnus_starblaster.iff",
	[I.M2] = I.ITEM_ROOT .. "armor/arm_mission_reward_imperial_sfs_light_military.iff",
	[I.M3] = I.ITEM_ROOT .. "booster/bst_mission_reward_imperial_rss_ion_booster.iff",
	[I.M4] = I.ITEM_ROOT .. "shield_generator/shd_mission_reward_imperial_rendili_dual_projector.iff",
}

I.CREDITS = 5000
I.STANDING = 75

local function point(zone, name, extra)
	local p = I.POINTS[zone][name]
	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra or {}) do
		t[k] = v
	end

	return t
end

local function recoveryPath(prefix, from, to)
	local out = {}

	for i = from, to do
		out[#out + 1] = point("space_naboo", prefix .. i, { escortNumber = i - from + 1, radius = 250 })
	end

	return out
end

local function escortPath(prefix, count)
	local out = {}

	for i = 1, count do
		out[i] = point("space_naboo", prefix .. i, { zoneName = "space_naboo", escortNumber = i, radius = 250 })
	end

	return out
end

local function repeated(name, count)
	local out = {}

	for i = 1, count do
		out[i] = name
	end

	return out
end

local function reward(global) return { { species = { -1 }, item = I.ITEMS[global] } } end

local TAUNTS_RECOVERY = { panicCount = 5, thanksCount = 5 }
local TAUNTS_ESCORT = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function I.expected()
	local spawnerPos = I.SPAWNERS.space_naboo.naboo_imperial_tier2_inspect1_spawner

	return {
		[I.M1] = {
			className = I.M1, questName = "naboo_imperial_tier2_1", questType = "inspect", questZone = "space_naboo",
			creditReward = I.CREDITS, itemReward = reward(I.M1),
			sideQuest = false, sideQuestType = "",
			shipList = { "mercenary_courier_tier2" },
			validSpawns = { { spawnName = "naboo_imperial_tier2_inspect1_spawner", x = spawnerPos[1], z = spawnerPos[2], y = spawnerPos[3] } },
			giveSpawnWaypoint = 1,
			cargo = "encrypted_documents",
		},
		[I.M2] = {
			className = I.M2, questName = "naboo_imperial_tier2_2", questType = "survival", questZone = "space_dantooine",
			creditReward = I.CREDITS, itemReward = reward(I.M2),
			sideQuest = false, sideQuestType = "",
			transmissionPoint = point("space_dantooine", "naboo_imperial_tier2_survival1"),
			totalTransmissionTime = 300, timesToUpdateProgress = 10, transmissionStartDelay = 60, delayToFirstAttack = 10,
			attackShipLists = { repeated("reb_xwing_tier2", 3), repeated("reb_z95_tier2", 3), repeated("reb_ywing_tier2", 3) },
			attackPeriod = 60,
			attackListType = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL,
		},
		[I.M3] = {
			className = I.M3, questName = "naboo_imperial_tier2_3", questType = "recovery", questZone = "space_naboo",
			creditReward = I.CREDITS, itemReward = reward(I.M3),
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 25, recoveryDelay = 30,
			recoverShip = "colonel_hend_shuttle_tier3",
			escortShips = repeated("reb_z95_tier2", 4),
			preRecoveryPoints = recoveryPath("naboo_imperial_tier2_recovery1_", 1, 4),
			recoveryPoints = recoveryPath("naboo_imperial_tier2_recovery1_", 5, 7),
			attackDelay = 120,
			attackShips = { repeated("reb_xwing_tier2", 3), { "reb_xwing_tier2", "reb_xwing_tier2", "reb_ywing_tier2", "reb_ywing_tier2" } },
			tauntData = TAUNTS_RECOVERY,
		},
		[I.M4] = {
			className = I.M4, questName = "naboo_imperial_tier2_4", questType = "assassinate", questZone = "space_dantooine",
			creditReward = I.CREDITS, itemReward = reward(I.M4),
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 45, failTimer = 20, mustDestroyEscort = true,
			assassinateSpawns = { target = "colonel_hend_shuttle_tier3", escorts = { "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier3" } },
			targetPatrols = {
				point("space_dantooine", "naboo_imperial_tier2_assassinate1_1"), point("space_dantooine", "naboo_imperial_tier2_assassinate1_2"),
				point("space_dantooine", "naboo_imperial_tier2_assassinate1_3"), point("space_dantooine", "naboo_imperial_tier2_assassinate1_4"),
				point("space_dantooine", "naboo_imperial_tier2_assassinate1_5"),
			},
		},
		[I.DUTY1] = {
			className = I.DUTY1, questName = "naboo_imperial_tier2_recoveryduty", questType = "recovery_duty", questZone = "space_naboo",
			creditReward = 2500, creditKillBonus = 200, numResponses = 5,
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 20, recoveryDelay = 30,
			recoverShip = "naboo_miner_transport_tier2",
			recoveryConversationMobile = "object/mobile/shared_space_comm_imperial_tiefighter_01.iff",
			escortShips = repeated("naboo_miner_fighter_tier2", 3),
			preRecoveryPoints = recoveryPath("naboo_imperial_tier2_recoveryduty_", 1, 4),
			recoveryPoints = recoveryPath("naboo_imperial_tier2_recoveryduty_", 5, 8),
			attackDelay = 120,
			attackShips = { { "reb_xwing_tier2", "reb_xwing_tier2" } },
			tauntData = TAUNTS_RECOVERY,
		},
		[I.DUTY2] = {
			className = I.DUTY2, questName = "naboo_imperial_tier2_escortduty", questType = "escort_duty", questZone = "space_naboo",
			creditReward = 2500, creditKillBonus = 200,
			sideQuest = false, sideQuestType = "",
			escortShips = { "imp_freightermedium_tier2", "imp_freighterlight_tier2", "imp_freighterheavy_tier2" },
			escortPoints = escortPath("naboo_imperial_tier2_escortduty_", 6),
			attackDelay = 120,
			attackShips = { { "reb_xwing_tier2", "reb_ywing_tier2" }, { "reb_xwing_tier2", "reb_xwing_tier2" }, { "reb_z95_tier2", "reb_z95_tier2" } },
			tauntData = TAUNTS_ESCORT,
		},
		[I.DUTY3] = {
			className = I.DUTY3, questName = "naboo_imperial_tier2_destroyduty", questType = "destroy_duty", questZone = "space_dantooine",
			creditReward = 200,
			sideQuest = false, sideQuestType = "",
			totalLevels = 5, totalRounds = 2, totalWaves = 3,
			bossShip = "reb_xwing_tier3",
			shipTypes = { { "reb_xwing_tier2", "reb_xwing_tier2" } },
		},
	}
end

-- Conversation flow 3.4: TRAIN_CHOICES in table order
I.TRAIN = {
	{ x = "starships", skill = "pilot_imperial_navy_starships_02", reply = "s_594a07fa", trained = "trained_starships", trainedSid = "s_486da900" },
	{ x = "weapons", skill = "pilot_imperial_navy_weapons_02", reply = "s_be30f309", trained = "trained_weapons", trainedSid = "s_241a34a1" },
	{ x = "procedures", skill = "pilot_imperial_navy_procedures_02", reply = "s_e73e5d21", trained = "trained_procedures", trainedSid = "s_c4880407" },
	{ x = "droid", skill = "pilot_imperial_navy_droid_02", reply = "s_c76594d7", trained = "trained_droid", trainedSid = "s_31804e15" },
}

I.TIER1_SKILLS = {
	"pilot_imperial_navy_starships_01", "pilot_imperial_navy_weapons_01", "pilot_imperial_navy_procedures_01", "pilot_imperial_navy_droid_01",
}

I.LATER = "s_ae26c22"          -- "Let me think about this for a bit."
I.MENU_LINE = "s_9ac35c60"
I.READY_FOR_TRAINING = "s_b0d3b474"  -- "I'm ready for training." (duty menu)
I.THANK_YOU = "s_987445c9"     -- "Thank you, sir."
I.M4_MORE_TRAINING_REPLY = "s_c104d444" -- "Yes, sir. I think I need more training though." (C-3, handler-set on m4_won)
I.TRAINING_COST = 60000
I.NOVICE = "pilot_imperial_navy_novice"

-- Appendix A
I.SCREENS = require("inquisition_tier2_screens_data")

function I.screenRow(id)
	for _, row in ipairs(I.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (103), sorted
function I.screenIds()
	local out = {}

	for i, row in ipairs(I.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

I.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		I.loadErrors[#I.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: the squadron files, Barn's and Fa'Zoll's templates and handlers. A missing production file is recorded in I.loadErrors, not
-- raised, so the tests of a red run fail on an assertion with the reason.
function I.load()
	if loaded then
		return
	end

	loaded = true
	H.boot()

	if rawget(_G, "FACTIONIMPERIAL") == nil then
		rawset(_G, "FACTIONIMPERIAL", getHashCode("imperial"))
	end

	if rawget(_G, "FACTIONREBEL") == nil then
		rawset(_G, "FACTIONREBEL", getHashCode("rebel"))
	end

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "InquisitionSquadronScreenplay", "StormSquadronScreenplay" }) do
		if rawget(_G, name) == nil then
			try(name, function() H.loadSquadron(name) end)
		end
	end

	try("barn_sinkko_convo.lua", function() H.loadMobile("conversations/space/imperial/inquisition_squadron/barn_sinkko_convo.lua") end)
	try("barnSinkkoConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/inquisition_squadron/barnSinkkoConvoHandler.lua") end)
	try("fa_zoll_convo.lua", function() H.loadMobile("conversations/space/imperial/inquisition_squadron/fa_zoll_convo.lua") end)
	try("faZollConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/inquisition_squadron/faZollConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function I.requireConversation(lu)
	I.load()
	lu.assertNotNil(H.conversationTemplateTable(I.TEMPLATE), I.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. table.concat(I.loadErrors, " | "))
	lu.assertNotNil(rawget(_G, I.HANDLER), I.HANDLER .. " is not defined. Load problems: " .. table.concat(I.loadErrors, " | "))
end

function I.quest(global)
	I.load()

	return H.expectGlobal(global, "Inquisition tier 2 quest table (inquisition-tier2-fa-zoll). Load problems: " .. table.concat(I.loadErrors, " | "))
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = I.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

I.crc = crc

-- Quest state helpers on a built pilot. state: "complete" | "active" | "none"
function I.setState(player, global, state)
	local id = I.IDENTITY[global]
	local key = H.questCrc(id.type, id.name)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function I.state(player, global)
	local id = I.IDENTITY[global]
	local key = H.questCrc(id.type, id.name)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- Options (all optional; the default is an Inquisition pilot with a ship, standing 0, the four tier 1 skills, pilot tier 2, Barn's series flag and
-- Fa'Zoll's agent flag set, no tier 2 mission done):
--   pilot      "imperial" (default) | "neutral" | "rebel" | false (not a pilot)
--   faction    "imperial" (default) | "rebel" | "neutral" (no faction)
--   squadron   true (default: INQUISITION_SQUADRON) | false (none) | a squadron constant
--   standing   Imperial faction standing (default 0)
--   paid       k: missions 1..k won, :attempted and :reward set (default 0)
--   state      the state of mission paid+1: "won" (complete, :attempted, reward unpaid) | "failed" (:attempted, nothing complete) |
--              "active" (:attempted, the head active) | "attempted" (just :attempted)
--   t1         false: no tier 1 skills (default: all four)
--   t2         list of TRAIN indexes of the tier 2 skills held
--   xp         space_combat_general experience (default 0)
--   series     Barn's series-complete flag (default true); agent Fa'Zoll's inquisitorialAgent flag (default true)
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   duty       global of a duty held active in the journal
--   species    SPECIES_* (default SPECIES_HUMAN)
--   pilotTier  ghost pilot tier (default 2; 3 with all four tier 2 skills)
--   inventory  (default true)
--   ship       certified ship (default true)
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
function I.pilot(o)
	o = o or {}
	I.load()

	local pilotKind = o.pilot

	if pilotKind == nil then
		pilotKind = "imperial"
	elseif pilotKind == false then
		pilotKind = nil
	end

	local faction = ({ imperial = FACTIONIMPERIAL, rebel = FACTIONREBEL })[o.faction or "imperial"] or 0
	local squadron = o.squadron

	if squadron == nil or squadron == true then
		squadron = INQUISITION_SQUADRON
	elseif squadron == false then
		squadron = 0
	end

	local skills = { I.NOVICE }

	if pilotKind == nil then
		skills = {}
	end

	if o.t1 ~= false then
		for _, skill in ipairs(I.TIER1_SKILLS) do
			skills[#skills + 1] = skill
		end
	end

	for _, i in ipairs(o.t2 or {}) do
		skills[#skills + 1] = I.TRAIN[i].skill
	end

	for _, skill in ipairs(o.skills or {}) do
		skills[#skills + 1] = skill
	end

	local paid = o.paid or 0
	local completed, active, status = {}, {}, {}

	for n = 1, paid do
		completed[#completed + 1] = crc(I.MISSIONS[n])
		status[statusName(n) .. ":attempted"] = "1"
		status[statusName(n) .. ":reward"] = "1"
	end

	local n = paid + 1

	if o.state ~= nil and I.MISSIONS[n] ~= nil then
		status[statusName(n) .. ":attempted"] = "1"

		if o.state == "won" then
			completed[#completed + 1] = crc(I.MISSIONS[n])
		elseif o.state == "active" then
			active[#active + 1] = crc(I.MISSIONS[n])
		end
	end

	if o.series ~= false then
		status[I.SERIES_SUFFIX] = "1"
	end

	if o.agent ~= false then
		status[I.AGENT_SUFFIX] = "1"
	end

	if o.duty then
		active[#active + 1] = crc(o.duty)
	end

	local pilotTier = o.pilotTier

	if pilotTier == nil then
		pilotTier = (#(o.t2 or {}) == 4) and 3 or 2
	end

	local player = H.newPlayer({
		name = "Ace",
		pilot = pilotKind,
		faction = faction,
		squadronType = squadron,
		pilotTier = pilotTier,
		certifiedShip = o.ship ~= false,
		skills = skills,
		experience = { space_combat_general = o.xp or 0 },
		factionStanding = { imperial = o.standing or 0, rebel = 0 },
		completedQuests = completed,
		activeQuests = active,
		questStatus = status,
		species = o.species or SPECIES_HUMAN,
		inventory = o.inventory ~= false and (o.inventory or true) or nil,
		zone = o.zone,
		ship = o.inShip and (type(o.inShip) == "table" and o.inShip or true) or nil,
	})

	if o.datapad == "duty" then
		DRS.holdDuty(player, "held_by_test")
	elseif o.datapad == "story" then
		DRS.holdStory(player, "story_held_by_test")
	end

	return player
end

-- Engine XP prices of the four tier 2 skills, from the SWG skills.tab excerpt (fixtures/skill/skills.pilot_imperial_navy_02.tab, 60000 each)
function I.useSkillCosts()
	local costs = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_imperial_navy_02.tab").records) do
		local name = rec:get("NAME")

		if name ~= nil and name:match("^pilot_imperial_navy_%a+_02$") then
			costs[name] = rec:num("XP_COST")
		end
	end

	H.Engine.config.skillXpCosts = costs

	return costs
end

function I.npc() return H.newNpc({ name = "Fa'Zoll" }) end

function I.requireConversationLoaded()
	I.load()

	if H.conversationTemplateTable(I.TEMPLATE) == nil or rawget(_G, I.HANDLER) == nil then
		error("Fa'Zoll's conversation is not loaded. Load problems: " .. table.concat(I.loadErrors, " | "), 3)
	end
end

-- Talks to Fa'Zoll from the first screen. choices as for H.converse.
function I.talk(player, choices)
	I.requireConversationLoaded()

	return H.converse({ template = I.TEMPLATE, player = player, npc = I.npc(), choices = choices })
end

-- The id of the first screen of a fresh talk
function I.firstScreen(player)
	return I.talk(player)[1].id
end

-- Talks to Barn from the first screen (the hand-off tests)
function I.talkToBarn(player, choices)
	I.load()

	if H.conversationTemplateTable(I.BARN_TEMPLATE) == nil or rawget(_G, I.BARN_HANDLER) == nil then
		error("Barn's conversation is not loaded. Load problems: " .. table.concat(I.loadErrors, " | "), 2)
	end

	return H.converse({ template = I.BARN_TEMPLATE, player = player, npc = H.newNpc({ name = "Barn" }), choices = choices })
end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session.
function I.drive(player, startId, choices)
	I.requireConversationLoaded()

	local tmpl = H.conversationTemplate(I.TEMPLATE)
	local handler = rawget(_G, I.HANDLER)
	local npc = I.npc()
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
		error("screen '" .. startId .. "' is not in " .. I.TEMPLATE, 2)
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

-- ids of a transcript
function I.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- the option sids ("s_xxx") of a transcript step, in order
function I.optionSids(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = tostring(o.text):match(":(s_[%w_]+)$") or tostring(o.text)
	end

	return out
end

function I.linksOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = o.link
	end

	return out
end

function I.free() return H.Engine.callsTo("awardSkill") end
function I.bought() return H.Engine.callsTo("skillManagerAwardSkill") end

-- Tier 2 skills (of the four) the player holds, in I.TRAIN order
function I.held(player)
	local out = {}

	for _, t in ipairs(I.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

-- Every status key (suffix after the player id) the tier 2 reset removes
function I.statusKeys()
	local out = {}

	for n = 1, 4 do
		out[#out + 1] = statusName(n) .. ":attempted"
		out[#out + 1] = statusName(n) .. ":reward"
	end

	return out
end

-- The item giveItem calls on the pilot's inventory received
function I.items(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory then
			out[#out + 1] = call[2]
		end
	end

	return out
end

return I
