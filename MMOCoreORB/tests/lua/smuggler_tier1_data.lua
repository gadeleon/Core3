-- Shared test data and builders for Smuggler tier 1 (Dravis, Mos Eisley), not a test file.
-- Spec: .claude/work/smuggler-tier1-dravis/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B; Q1 = A).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself. test_smuggler_tier1_data.lua also derives the table values from the SWG-Source fixtures and requires them to equal
-- these literals, so a wrong spec literal fails too.
--   S.GLOBALS / S.IDENTITY     the 10 quest globals and their class, type and name (Content contract 1)
--   S.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   S.POINTS / S.SPAWNERS      Data mapping 2: the 19 nav points and 4 spawners, Core3 x, z, y
--   S.SCREENS                  Appendix A (smuggler_tier1_screens_data.lua, generated from the spec table)
--   S.TRAIN                    TRAIN_CHOICES (Content contract 3, Conversation flow 3.4)
--   S.load()                   the server's load of the squadron, the template and the handler, collecting load errors
--   S.pilot{...}               a pilot standing in front of Dravis (see the option list at S.pilot)
--   S.talk / S.drive           H.converse from the first screen / from a given screen
--
-- Dravis' conversation lives in the template "dravis_convo_template", its handler is the global "dravisConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")

local S = {}

S.TEMPLATE = "dravis_convo_template"
S.HANDLER = "dravisConvoHandler"
S.PREFIX = "@conversation/tatooine_privateer_trainer_1:"
S.STF = "conversation/tatooine_privateer_trainer_1"

S.TEMPLATE_FILE = "mobile/conversations/space/neutral/smuggler_squadron/dravis_convo.lua"
S.HANDLER_FILE = "screenplays/space/conversations/neutral/smuggler_squadron/dravisConvoHandler.lua"
S.SQUADRON_FILE = "screenplays/space/squadrons/SmugglerSquadronScreenplay.lua"
S.NPC_FILE = "mobile/space/dravis.lua"

S.P1 = "patrol_tatooine_privateer_1"
S.S1 = "destroy_surpriseattack_tatooine_privateer_1"
S.M2 = "destroy_tatooine_privateer_2"
S.P3 = "patrol_tatooine_privateer_3"
S.E3 = "escort_tatooine_privateer_3"
S.A4 = "assassinate_tatooine_privateer_tier1_4a"
S.DUTY6 = "destroy_duty_tatooine_privateer_6"
S.DUTY5 = "recovery_duty_tatooine_privateer_5"
S.DUTY8 = "destroy_duty_tatooine_privateer_8"
S.DUTY7 = "escort_duty_tatooine_privateer_7"

S.GLOBALS = { S.P1, S.S1, S.M2, S.P3, S.E3, S.A4, S.DUTY6, S.DUTY5, S.DUTY8, S.DUTY7 }
S.DUTIES = { S.DUTY6, S.DUTY5, S.DUTY8, S.DUTY7 }

-- global -> { class, type, name }
S.IDENTITY = {
	[S.P1] = { class = "SpacePatrolScreenplay", type = "patrol", name = "tatooine_privateer_1" },
	[S.S1] = { class = "SpaceSurpriseAttackScreenplay", type = "destroy_surpriseattack", name = "tatooine_privateer_1" },
	[S.M2] = { class = "SpaceDestroyScreenplay", type = "destroy", name = "tatooine_privateer_2" },
	[S.P3] = { class = "SpacePatrolScreenplay", type = "patrol", name = "tatooine_privateer_3" },
	[S.E3] = { class = "SpaceEscortScreenplay", type = "escort", name = "tatooine_privateer_3" },
	[S.A4] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "tatooine_privateer_tier1_4a" },
	[S.DUTY6] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "tatooine_privateer_6" },
	[S.DUTY5] = { class = "SpaceDutyRecoveryScreenplay", type = "recovery_duty", name = "tatooine_privateer_5" },
	[S.DUTY8] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "tatooine_privateer_8" },
	[S.DUTY7] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "tatooine_privateer_7" },
}

-- The mission chains (head first): the story missions of the trainer. The split children are listed after their head.
S.CHAINS = {
	{ S.P1, S.S1 },
	{ S.M2 },
	{ S.P3, S.E3 },
	{ S.A4 },
}

-- the head of each mission (the global Dravis starts)
S.HEADS = { S.P1, S.M2, S.P3, S.A4 }

-- Content contract 2: the squadron object's constants
S.QUEST_STRINGS = {
	QUEST_STRING_1 = { type = "patrol", name = "tatooine_privateer_1" },
	QUEST_STRING_1_SIDE = { type = "destroy_surpriseattack", name = "tatooine_privateer_1" },
	QUEST_STRING_2 = { type = "destroy", name = "tatooine_privateer_2" },
	QUEST_STRING_3 = { type = "patrol", name = "tatooine_privateer_3" },
	QUEST_STRING_3_SIDE = { type = "escort", name = "tatooine_privateer_3" },
	QUEST_STRING_4 = { type = "assassinate", name = "tatooine_privateer_tier1_4a" },
	QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "tatooine_privateer_6" },
	QUEST_STRING_DUTY_2 = { type = "recovery_duty", name = "tatooine_privateer_5" },
	QUEST_STRING_DUTY_3 = { type = "destroy_duty", name = "tatooine_privateer_8" },
	QUEST_STRING_DUTY_4 = { type = "escort_duty", name = "tatooine_privateer_7" },
}

-- Q1: the met-Dravis key is server memory (writeData), key = player id .. this string
S.MET_DRAVIS_KEY = "SmugglerSquadronScreenplay:metDravis"

-- Data mapping 2: name -> { x, z, y }
S.POINTS = {
	blacksun_patrol_1 = { -31, 275, -2950 },
	blacksun_patrol_2 = { 2886, -3000, -1801 },
	blacksun_patrol_3 = { 2370, 669, 1089 },
	privateer_security_patrol_1 = { -2479, -2475, 613 },
	privateer_security_patrol_2 = { 469, -550, 2173 },
	privateer_security_patrol_3 = { 2528, 2101, -316 },
	privateer_security_patrol_4 = { 1035, 1254, -2829 },
	privateer_security_escort_1 = { 2625, 1624, 2461 },
	privateer_security_escort_2 = { 368, 805, 2098 },
	privateer_security_escort_3 = { -1065, 822, 418 },
	privateer_security_escort_4 = { -2096, -1446, -2635 },
	anchorhead_supply_patrol_1 = { 2634, -5262, 1718 },
	bestine_commerce_patrol_3 = { -304, -4571, 4419 },
	bestine_security_patrol_2 = { 1923, -3956, 3964 },
	imperial_escortduty_2 = { 2356, -3868, 4288 },
	anchorhead_armed_recon_1 = { -1387, -1962, 1725 },
	anchorhead_armed_recon_2 = { -589, -2389, 1587 },
	bestine_security_escort_1 = { -687, -4985, 5979 },
	corellia_imperial_tier3_leg_4_assasinate_two_3 = { 2956, -4696, 5535 },
}

S.SPAWNERS = {
	blacksun_threat_2 = { 1098, 767, -2978 },
	blacksun_pirates = { -2024, 1619, -2219 },
	blacksun_n_stuff_1 = { 5588, 1002, 6147 },
	blacksun_threat_3 = { 2816, 336, -1908 },
}

S.HUMAN_BANDOLIER = "object/tangible/wearables/bandolier/mercenary_bandolier.iff"
S.ITHORIAN_BANDOLIER = "object/tangible/wearables/bandolier/ith_mercenary_bandolier.iff"
S.BLASTER = "object/tangible/ship/components/weapon/wpn_mission_reward_neutral_mandal_light_blaster.iff"

-- Destroy 2 shipTypes, in .tab order (Appendix B; 32 entries, blacksun_fighter_s01_tier2_tatooine twice)
S.DESTROY2_SHIPS = {
	"blacksun_ace_s04_tier1", "blacksun_ace_s04_tier2", "blacksun_aggressor_tier1", "blacksun_aggressor_tier2", "blacksun_bomber_ace_s04_tier1",
	"blacksun_bomber_ace_s04_tier2", "blacksun_bomber_s01_tier1", "blacksun_bomber_s01_tier2", "blacksun_bomber_s01_tier2_tatooine", "blacksun_bomber_s02_tier1",
	"blacksun_bomber_s02_tier2", "blacksun_bomber_s03_tier1", "blacksun_bomber_s03_tier2", "blacksun_fighter_s01_tier1", "blacksun_fighter_s01_tier2",
	"blacksun_fighter_s01_tier2_tatooine", "blacksun_fighter_s02_tier1", "blacksun_fighter_s02_tier2", "blacksun_fighter_s03_tier1", "blacksun_fighter_s03_tier2",
	"blacksun_gunship_tier1", "blacksun_gunship_tier2", "blacksun_marauder_tier1", "blacksun_marauder_tier2", "blacksun_vehement_tier1", "blacksun_vehement_tier2",
	"blacksun_yt1300_tier1", "blacksun_yt1300_tier2", "blacksun_bomber_ace_tier3_dantooine", "blacksun_bomber_s02_tier3_dantooine",
	"blacksun_fighter_s01_tier2_tatooine", "blacksun_fighter_s02_tier3_dantooine",
}

local function point(name, extra)
	local p = S.POINTS[name]

	assert(p ~= nil, "no spec point " .. tostring(name))

	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra or {}) do
		t[k] = v
	end

	return t
end

local function patrolPoint(name, i) return point(name, { patrolNumber = i, radius = 150 }) end
local function escortPoint(name, i) return point(name, { zoneName = "space_tatooine", escortNumber = i, radius = 250 }) end
local function numbered(name, i) return point(name, { escortNumber = i, radius = 250 }) end

local function spawner(name)
	local s = S.SPAWNERS[name]

	return { spawnName = name, x = s[1], z = s[2], y = s[3] }
end

local function copy(list)
	local out = {}

	for i, v in ipairs(list) do
		out[i] = v
	end

	return out
end

-- global -> the whole table (Appendix B keys, Data mapping 1 values). sideQuestSplitType is SpaceQuestLogic's PATROL_POINT constant.
function S.expected()
	local PATROL_POINT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT

	return {
		[S.P1] = {
			className = S.P1, questName = "tatooine_privateer_1", questType = "patrol", questZone = "space_tatooine",
			creditReward = 100,
			sideQuest = true, sideQuestType = "destroy_surpriseattack", sideQuestName = "tatooine_privateer_1",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 2, sideQuestDelay = 20,
			patrolPoints = { patrolPoint("blacksun_patrol_1", 1), patrolPoint("blacksun_patrol_2", 2), patrolPoint("blacksun_patrol_3", 3) },
		},
		[S.S1] = {
			className = S.S1, questName = "tatooine_privateer_1", questType = "destroy_surpriseattack", questZone = "space_tatooine",
			sideQuest = false, sideQuestType = "",
			parentQuest = S.P1, parentQuestType = "patrol", parentQuestName = "tatooine_privateer_1",
			surpriseAttackShips = { zone = "space_tatooine", spawns = { { count = 3, shipName = "blacksun_fighter_s01_tier1" } } },
		},
		[S.M2] = {
			className = S.M2, questName = "tatooine_privateer_2", questType = "destroy", questZone = "space_tatooine",
			creditReward = 200,
			sideQuest = false, sideQuestType = "",
			killsRequired = 4,
			shipLocations = { spawner("blacksun_threat_2"), spawner("blacksun_pirates"), spawner("blacksun_n_stuff_1"), spawner("blacksun_threat_3") },
			shipTypes = copy(S.DESTROY2_SHIPS),
		},
		[S.P3] = {
			className = S.P3, questName = "tatooine_privateer_3", questType = "patrol", questZone = "space_tatooine",
			creditReward = 500,
			itemReward = {
				{ species = { SPECIES_ITHORIAN }, item = S.ITHORIAN_BANDOLIER },
				{ species = { -1 }, item = S.HUMAN_BANDOLIER },
			},
			sideQuest = true, sideQuestType = "escort", sideQuestName = "tatooine_privateer_3",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 2, sideQuestDelay = 20,
			patrolPoints = {
				patrolPoint("privateer_security_patrol_1", 1), patrolPoint("privateer_security_patrol_2", 2),
				patrolPoint("privateer_security_patrol_3", 3), patrolPoint("privateer_security_patrol_4", 4),
			},
		},
		[S.E3] = {
			className = S.E3, questName = "tatooine_privateer_3", questType = "escort", questZone = "space_tatooine",
			sideQuest = false, sideQuestType = "",
			parentQuest = S.P3, parentQuestType = "patrol", parentQuestName = "tatooine_privateer_3",
			escortShips = { "hutt_freighterlight_tier1" },
			escortPoints = {
				escortPoint("privateer_security_escort_1", 1), escortPoint("privateer_security_escort_2", 2),
				escortPoint("privateer_security_escort_3", 3), escortPoint("privateer_security_escort_4", 4),
			},
			attackDelay = 90,
			attackShips = {
				{ "blacksun_fighter_s01_tier1", "blacksun_fighter_s02_tier1" },
				{ "blacksun_vehement_tier1", "blacksun_marauder_tier1", "blacksun_marauder_tier1" },
			},
			tauntData = { goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2 },
		},
		[S.A4] = {
			className = S.A4, questName = "tatooine_privateer_tier1_4a", questType = "assassinate", questZone = "space_tatooine",
			creditReward = 1000,
			itemReward = { { species = { -1 }, item = S.BLASTER } },
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 12, failTimer = 20, mustDestroyEscort = true,
			assassinateSpawns = { target = "blacksun_ace_s04_tier1", escorts = { "blacksun_fighter_s03_tier1", "blacksun_fighter_s02_tier1" } },
			targetPatrols = {
				point("anchorhead_supply_patrol_1"), point("bestine_commerce_patrol_3"), point("bestine_security_patrol_2"), point("privateer_security_patrol_1"),
				point("imperial_escortduty_2"), point("blacksun_patrol_1"), point("anchorhead_armed_recon_1"),
			},
		},
		[S.DUTY6] = {
			className = S.DUTY6, questName = "tatooine_privateer_6", questType = "destroy_duty", questZone = "space_tatooine",
			creditReward = 100,
			sideQuest = false, sideQuestType = "",
			totalLevels = 2, totalRounds = 2, totalWaves = 2,
			bossShip = "blacksun_marauder_tier2",
			shipTypes = {
				{ "blacksun_bomber_s01_tier1", "blacksun_bomber_s03_tier1" },
				{ "blacksun_aggressor_tier1", "blacksun_aggressor_tier1" },
				{ "blacksun_fighter_s02_tier1", "blacksun_fighter_s01_tier1" },
			},
		},
		[S.DUTY5] = {
			className = S.DUTY5, questName = "tatooine_privateer_5", questType = "recovery_duty", questZone = "space_tatooine",
			creditReward = 1000, creditKillBonus = 100, numResponses = 2,
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 35, recoveryDelay = 18,
			recoverShip = "valarian_freighterlight_mining_tier1",
			escortShips = { "valarian_gunship_tier1", "valarian_gunship_tier1" },
			preRecoveryPoints = {
				numbered("anchorhead_supply_patrol_1", 1), numbered("bestine_security_escort_1", 2), numbered("bestine_security_patrol_2", 3),
				numbered("blacksun_patrol_3", 4), numbered("corellia_imperial_tier3_leg_4_assasinate_two_3", 5),
			},
			recoveryPoints = {
				numbered("anchorhead_armed_recon_2", 1), numbered("privateer_security_patrol_3", 2), numbered("corellia_imperial_tier3_leg_4_assasinate_two_3", 3),
			},
			attackDelay = 100,
			attackShips = {
				{ "valarian_bomber_tier1", "valarian_bomber_tier1" },
				{ "valarian_gunship_tier1", "valarian_gunship_tier1" },
				{ "valarian_gunship_tier2" },
			},
			tauntData = { panicCount = 2, thanksCount = 2 },
		},
		[S.DUTY8] = {
			className = S.DUTY8, questName = "tatooine_privateer_8", questType = "destroy_duty", questZone = "space_tatooine",
			creditReward = 100,
			sideQuest = false, sideQuestType = "",
			totalLevels = 2, totalRounds = 2, totalWaves = 2,
			bossShip = "blacksun_ace_s04_tier1",
			shipTypes = {
				{ "blacksun_fighter_s03_tier1", "blacksun_fighter_s03_tier1" },
				{ "blacksun_bomber_s01_tier1", "blacksun_bomber_s01_tier1" },
				{ "blacksun_bomber_s01_tier1", "blacksun_fighter_s02_tier1" },
				{ "blacksun_fighter_s03_tier1", "blacksun_fighter_s02_tier1" },
			},
		},
		[S.DUTY7] = {
			className = S.DUTY7, questName = "tatooine_privateer_7", questType = "escort_duty", questZone = "space_tatooine",
			creditReward = 1000, creditKillBonus = 100,
			sideQuest = false, sideQuestType = "",
			escortShips = { "hutt_freightermedium_tier1", "hutt_freighterheavy_tier1" },
			escortPoints = { escortPoint("blacksun_patrol_1", 1), escortPoint("privateer_security_escort_1", 2), escortPoint("privateer_security_escort_4", 3) },
			attackDelay = 90,
			attackShips = {
				{ "blacksun_fighter_s03_tier1", "blacksun_fighter_s02_tier1" },
				{ "blacksun_aggressor_tier1", "blacksun_aggressor_tier1" },
			},
			tauntData = { goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2 },
		},
	}
end

-- Conversation flow 3.4: TRAIN_CHOICES in table order (J branch-71 order). reply = the topic reply, closing = the trained_<x> line.
S.TRAIN = {
	{ x = "starships", skill = "pilot_neutral_starships_01", reply = "s_3818dc2a", trained = "trained_starships", closing = "s_2b94498c" },
	{ x = "weapons", skill = "pilot_neutral_weapons_01", reply = "s_3fa70900", trained = "trained_weapons", closing = "s_9690c2f9" },
	{ x = "procedures", skill = "pilot_neutral_procedures_01", reply = "s_7d57477f", trained = "trained_procedures", closing = "s_4a441e77" },
	{ x = "droid", skill = "pilot_neutral_droid_01", reply = "s_9480f430", trained = "trained_droid", closing = "s_35a591ea" },
}

S.TRAINING_COST = 7500
S.NOVICE = "pilot_neutral_novice"

function S.tierSkills(count)
	local out = {}

	for i = 1, count do
		out[i] = S.TRAIN[i].skill
	end

	return out
end

-- Appendix A
S.SCREENS = require("smuggler_tier1_screens_data")

function S.screenRow(id)
	for _, row in ipairs(S.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (81), sorted
function S.screenIds()
	local out = {}

	for i, row in ipairs(S.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

S.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		S.loadErrors[#S.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: the squadron files, the Dravis template, the Dravis handler. A missing production file is recorded in S.loadErrors,
-- not raised, so the tests of a red run fail on an assertion with the reason.
function S.load()
	if loaded then
		return
	end

	loaded = true
	H.boot()

	-- Factions::FACTIONIMPERIAL / FACTIONREBEL come from C++ values the harness cannot resolve; the fake ships use the same crc
	if rawget(_G, "FACTIONIMPERIAL") == nil then
		rawset(_G, "FACTIONIMPERIAL", getHashCode("imperial"))
	end

	if rawget(_G, "FACTIONREBEL") == nil then
		rawset(_G, "FACTIONREBEL", getHashCode("rebel"))
	end

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay" }) do
		try(name, function() H.loadSquadron(name) end)
	end

	try("dravis_convo.lua", function() H.loadMobile("conversations/space/neutral/smuggler_squadron/dravis_convo.lua") end)
	try("dravisConvoHandler.lua", function() H.loadScreenplay("space/conversations/neutral/smuggler_squadron/dravisConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function S.requireConversation(lu)
	S.load()
	lu.assertNotNil(H.conversationTemplateTable(S.TEMPLATE), S.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. table.concat(S.loadErrors, " | "))
	lu.assertNotNil(rawget(_G, S.HANDLER), S.HANDLER .. " is not defined. Load problems: " .. table.concat(S.loadErrors, " | "))
end

function S.quest(global)
	S.load()

	return H.expectGlobal(global, "Smuggler tier 1 quest table (smuggler-tier1-dravis). Load problems: " .. table.concat(S.loadErrors, " | "))
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = S.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

S.crc = crc

-- Quest state helpers on a built pilot. state: "complete" | "active" | "none"
function S.setState(player, global, state)
	local key = crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function S.state(player, global)
	local key = crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- the quest-name part of the :attempted / :reward status keys (QUEST_STRING_N.name)
S.STATUS_NAMES = { "tatooine_privateer_1", "tatooine_privateer_2", "tatooine_privateer_3", "tatooine_privateer_tier1_4a" }

function S.statusKeys()
	local out = {}

	for n = 1, 4 do
		out[#out + 1] = S.STATUS_NAMES[n] .. ":attempted"
		out[#out + 1] = S.STATUS_NAMES[n] .. ":reward"
	end

	return out
end

local NOVICE_OF = { neutral = S.NOVICE, rebel = "pilot_rebel_navy_novice", imperial = "pilot_imperial_navy_novice" }

-- Options (all optional; the default is a signed-up Smuggler with a ship, no mission done, no skill, no XP):
--   pilot      "neutral" (default) | "rebel" | "imperial" | false (not a pilot)
--   faction    "neutral" (default, no faction) | "rebel" | "imperial": the GCW faction (Dravis has no faction gate, FS-6)
--   squadron   true (default: SMUGGLER_SQUADRON) | false (none) | a squadron constant (CORSEC_SQUADRON, RSF_SQUADRON, ...)
--   ship       certified ship (default true)
--   paid       k: missions 1..k won, :attempted and :reward set (default 0)
--   state      the state of mission paid+1: "won" (complete, :attempted, reward unpaid) | "failed" (:attempted, nothing complete) |
--              "active" (:attempted, head chain member active) | "attempted" (just :attempted)
--   skills     list of skill names held besides the novice box; or tier = n for the first n tier 1 skills of S.TRAIN
--   tier       number of tier 1 skills (see above)
--   xp         space_combat_general experience (default 0)
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   duty       global of a duty held active in the journal
--   species    SPECIES_* (default SPECIES_HUMAN: the fake's default 0 is not a species constant)
--   pilotTier  ghost pilot tier (default 1)
--   inventory  (default true)
--   met        true: the met-Dravis key is set (Q1)
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
function S.pilot(o)
	o = o or {}
	S.load()

	local pilotKind = o.pilot

	if pilotKind == nil then
		pilotKind = "neutral"
	elseif pilotKind == false then
		pilotKind = nil
	end

	local faction = ({ imperial = FACTIONIMPERIAL, rebel = FACTIONREBEL })[o.faction or "neutral"] or 0
	local squadron = o.squadron

	if squadron == nil or squadron == true then
		squadron = SMUGGLER_SQUADRON
	elseif squadron == false then
		squadron = 0
	end

	local skills = {}

	if pilotKind ~= nil then
		skills[1] = NOVICE_OF[pilotKind]
	end

	for _, skill in ipairs(o.skills or {}) do
		skills[#skills + 1] = skill
	end

	for _, skill in ipairs(S.tierSkills(o.tier or 0)) do
		skills[#skills + 1] = skill
	end

	local paid = o.paid or 0
	local completed, active, status = {}, {}, {}

	for n = 1, paid do
		for _, g in ipairs(S.CHAINS[n]) do
			completed[#completed + 1] = crc(g)
		end

		status[S.STATUS_NAMES[n] .. ":attempted"] = "1"
		status[S.STATUS_NAMES[n] .. ":reward"] = "1"
	end

	local n = paid + 1

	if o.state ~= nil and S.CHAINS[n] ~= nil then
		status[S.STATUS_NAMES[n] .. ":attempted"] = "1"

		if o.state == "won" then
			for _, g in ipairs(S.CHAINS[n]) do
				completed[#completed + 1] = crc(g)
			end
		elseif o.state == "active" then
			active[#active + 1] = crc(S.CHAINS[n][1])
		end
	end

	if o.duty then
		active[#active + 1] = crc(o.duty)
	end

	local player = H.newPlayer({
		name = "Ace",
		pilot = pilotKind,
		faction = faction,
		squadronType = squadron,
		pilotTier = o.pilotTier or 1,
		certifiedShip = o.ship ~= false,
		skills = skills,
		experience = { space_combat_general = o.xp or 0 },
		factionStanding = { imperial = 0, rebel = 0 },
		completedQuests = completed,
		activeQuests = active,
		questStatus = status,
		species = o.species or SPECIES_HUMAN,
		inventory = o.inventory ~= false and (o.inventory or true) or nil,
		zone = o.zone,
		ship = o.inShip and (type(o.inShip) == "table" and o.inShip or true) or nil,
	})

	if o.met then
		writeData(player.objectID .. S.MET_DRAVIS_KEY, 1)
	end

	if o.datapad == "duty" then
		DRS.holdDuty(player, "held_by_test")
	elseif o.datapad == "story" then
		DRS.holdStory(player, "story_held_by_test")
	end

	return player
end

-- Engine XP prices of the four tier 1 skills, from the SWG skills.tab excerpt (fixtures/skill/skills.pilot_neutral_01.tab)
function S.useSkillCosts()
	local costs = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_neutral_01.tab").records) do
		local name = rec:get("NAME")

		if name ~= nil and name:match("^pilot_neutral_%a+_01$") then
			costs[name] = rec:num("XP_COST")
		end
	end

	H.Engine.config.skillXpCosts = costs

	return costs
end

-- true when the met-Dravis key is set for the player (readData answers 0 for an absent key)
function S.met(player) return readData(player.objectID .. S.MET_DRAVIS_KEY) == 1 end

function S.npc() return H.newNpc({ name = "Dravis" }) end

function S.requireConversationLoaded()
	S.load()

	if H.conversationTemplateTable(S.TEMPLATE) == nil or rawget(_G, S.HANDLER) == nil then
		error("Dravis' conversation is not loaded. Load problems: " .. table.concat(S.loadErrors, " | "), 3)
	end
end

-- Talks to Dravis from the first screen. choices as for H.converse.
function S.talk(player, choices)
	S.requireConversationLoaded()

	return H.converse({ template = S.TEMPLATE, player = player, npc = S.npc(), choices = choices })
end

-- The id of the first screen of a fresh talk
function S.firstScreen(player)
	return S.talk(player)[1].id
end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session.
function S.drive(player, startId, choices)
	S.requireConversationLoaded()

	local tmpl = H.conversationTemplate(S.TEMPLATE)
	local handler = rawget(_G, S.HANDLER)
	local npc = S.npc()
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
		error("screen '" .. startId .. "' is not in " .. S.TEMPLATE, 2)
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
function S.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- the option sids ("s_xxx") of a transcript step, in order
function S.optionSids(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = tostring(o.text):match(":(s_[%w_]+)$") or tostring(o.text)
	end

	return out
end

function S.linksOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = o.link
	end

	return out
end

function S.free() return H.Engine.callsTo("awardSkill") end
function S.bought() return H.Engine.callsTo("skillManagerAwardSkill") end

-- Skills (of the four) the player holds, in S.TRAIN order
function S.held(player)
	local out = {}

	for _, t in ipairs(S.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

return S
