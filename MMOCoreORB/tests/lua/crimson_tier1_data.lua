-- Shared test data and builders for Crimson Phoenix Squadron tier 1 (Commander Da'la Socuna, Mos Espa), not a test file.
-- Spec: .claude/work/crimson-phoenix-tier1-da-la-socuna/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself:
--   C.GLOBALS / C.IDENTITY     the 8 quest globals and their class, type and name (Content contract 1)
--   C.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   C.POINTS / C.SPAWNERS      Data mapping 2: the 13 nav points and 4 spawners, Core3 x, z, y
--   C.SCREENS                  Appendix A (crimson_tier1_screens_data.lua, generated from the spec table by a scratch script)
--   C.TRAIN                    TRAIN_CHOICES (Content contract 3, Conversation flow 3.4)
--   C.load()                   the server's load of the squadron files, the template and the handler, collecting load errors
--   C.pilot{...}               a pilot standing in front of Da'la Socuna (see the option list at C.pilot)
--   C.talk / C.drive           H.converse from the first screen / from a given screen
--
-- Mission numbers are J's (SWG trainer script): mission 2 is destroy/tatooine_rebel_3 and mission 3 is patrol/tatooine_rebel_2 (D-14), so the
-- status keys of mission 2 are "tatooine_rebel_3:..." and of mission 3 "tatooine_rebel_2:...".
-- Her conversation lives in the template "socuna_convo_template", its handler is the global "socunaConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")

local C = {}

C.TEMPLATE = "socuna_convo_template"
C.HANDLER = "socunaConvoHandler"
C.PREFIX = "@conversation/tatooine_rebel_trainer_1:"
C.STF = "conversation/tatooine_rebel_trainer_1"

C.TEMPLATE_FILE = "mobile/conversations/space/rebel/crimson_phoenix_squadron/socuna_convo.lua"
C.HANDLER_FILE = "screenplays/space/conversations/rebel/crimson_phoenix_squadron/socunaConvoHandler.lua"
C.SQUADRON_FILE = "screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua"
C.NPC_FILE = "mobile/space/da_la_socuna.lua"

C.P1 = "patrol_tatooine_rebel_1"
C.S1 = "destroy_surpriseattack_tatooine_rebel_1"
C.M2 = "destroy_tatooine_rebel_3"
C.P3 = "patrol_tatooine_rebel_2"
C.E3 = "escort_tatooine_rebel_2"
C.A4 = "assassinate_tatooine_rebel_4"
C.DUTY6 = "destroy_duty_tatooine_rebel_6"
C.DUTY7 = "escort_duty_tatooine_rebel_7"

C.GLOBALS = { C.P1, C.S1, C.M2, C.P3, C.E3, C.A4, C.DUTY6, C.DUTY7 }

-- global -> { class, type, name }
C.IDENTITY = {
	[C.P1] = { class = "SpacePatrolScreenplay", type = "patrol", name = "tatooine_rebel_1" },
	[C.S1] = { class = "SpaceSurpriseAttackScreenplay", type = "destroy_surpriseattack", name = "tatooine_rebel_1" },
	[C.M2] = { class = "SpaceDestroyScreenplay", type = "destroy", name = "tatooine_rebel_3" },
	[C.P3] = { class = "SpacePatrolScreenplay", type = "patrol", name = "tatooine_rebel_2" },
	[C.E3] = { class = "SpaceEscortScreenplay", type = "escort", name = "tatooine_rebel_2" },
	[C.A4] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "tatooine_rebel_4" },
	[C.DUTY6] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "tatooine_rebel_6" },
	[C.DUTY7] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "tatooine_rebel_7" },
}

-- The mission chains (head first); the story missions of the trainer, in J's mission order
C.CHAINS = {
	{ C.P1, C.S1 },
	{ C.M2 },
	{ C.P3, C.E3 },
	{ C.A4 },
}

-- Content contract 2: the squadron object's constants
C.QUEST_STRINGS = {
	QUEST_STRING_1 = { type = "patrol", name = "tatooine_rebel_1" },
	QUEST_STRING_1_SIDE = { type = "destroy_surpriseattack", name = "tatooine_rebel_1" },
	QUEST_STRING_2 = { type = "destroy", name = "tatooine_rebel_3" },
	QUEST_STRING_3 = { type = "patrol", name = "tatooine_rebel_2" },
	QUEST_STRING_3_SIDE = { type = "escort", name = "tatooine_rebel_2" },
	QUEST_STRING_4 = { type = "assassinate", name = "tatooine_rebel_4" },
	QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "tatooine_rebel_6" },
	QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "tatooine_rebel_7" },
}

-- The hand-off constant (Content contract 2, D-11): stored under <playerID> .. EKER_PILOT_KEY, value "1" from Socuna
C.EKER_PILOT_KEY = "CrimsonPhoenixSquadronScreenplay:ekerPilot"

-- Data mapping 2: name -> { x, z, y }
C.POINTS = {
	anchorhead_supply_patrol_1 = { 2634, -5262, 1718 },
	anchorhead_supply_patrol_2 = { 3931, -4960, 1438 },
	anchorhead_supply_patrol_3 = { 5843, -4271, -94 },
	anchorhead_armed_recon_1 = { -1387, -1962, 1725 },
	anchorhead_armed_recon_2 = { -589, -2389, 1587 },
	anchorhead_armed_recon_3 = { 770, -1644, 1372 },
	anchorhead_escort_1 = { 1163, -2422, 1950 },
	anchorhead_escort_2 = { -1574, -2952, 1649 },
	anchorhead_escort_3 = { -2714, -2199, 1263 },
	bestine_security_escort_1 = { -687, -4985, 5979 },
	bestine_security_escort_3 = { 3957, -4516, 4717 },
	bestine_security_escort_5 = { 3521, 463, 2010 },
	bestine_security_patrol_2 = { 1923, -3956, 3964 },
}

C.SPAWNERS = {
	anchorhead_tie_rally_alpha = { 1948, -366, 2316 },
	imp_base_defense_03 = { -3826, 380, 2983 },
	imperial_base_guard_1 = { -6388, 4911, -1055 },
	imperial_squad_1 = { -4099, -602, 4240 },
}

C.WOOKIEE_BANDOLIER = "object/tangible/wearables/bandolier/multipocket_bandolier.iff"
C.ITHORIAN_BANDOLIER = "object/tangible/wearables/bandolier/ith_multipocket_bandolier.iff"
C.FLIGHT_SUIT = "object/tangible/wearables/bodysuit/bodysuit_s14.iff" -- D-9: SWG's rebel_bodysuit_s14.iff has no pre-NGE template
C.SWG_FLIGHT_SUIT = "object/tangible/wearables/bodysuit/rebel_bodysuit_s14.iff"
C.ARMOR = "object/tangible/ship/components/armor/arm_mission_reward_rebel_incom_ultralight.iff"

local function point(name, extra)
	local p = C.POINTS[name]
	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra) do
		t[k] = v
	end

	return t
end

local function patrolPoint(name, i) return point(name, { patrolNumber = i, radius = 150 }) end
local function escortPoint(name, i) return point(name, { zoneName = "space_tatooine", escortNumber = i, radius = 250 }) end

local function spawner(name)
	local s = C.SPAWNERS[name]

	return { spawnName = name, x = s[1], z = s[2], y = s[3] }
end

local function taunts(n) return { goodbyeCount = n, reasonCount = n, tauntCount = n, thanksCount = n } end

local THREE_TIES = { "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1" }

-- global -> the whole table (Appendix B keys, Data mapping 1 values). sideQuestSplitType is SpaceQuestLogic's PATROL_POINT constant.
-- No table defines a function (Content contract 1: "No table overrides a function").
function C.expected()
	local PATROL_POINT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT

	return {
		[C.P1] = {
			className = C.P1, questName = "tatooine_rebel_1", questType = "patrol", questZone = "space_tatooine",
			creditReward = 100,
			sideQuest = true, sideQuestType = "destroy_surpriseattack", sideQuestName = "tatooine_rebel_1",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 2, sideQuestDelay = 12,
			patrolPoints = { patrolPoint("anchorhead_supply_patrol_1", 1), patrolPoint("anchorhead_supply_patrol_2", 2), patrolPoint("anchorhead_supply_patrol_3", 3) },
		},
		[C.S1] = {
			className = C.S1, questName = "tatooine_rebel_1", questType = "destroy_surpriseattack", questZone = "space_tatooine",
			sideQuest = false, sideQuestType = "",
			parentQuest = C.P1, parentQuestType = "patrol", parentQuestName = "tatooine_rebel_1",
			surpriseAttackShips = { zone = "space_tatooine", spawns = { { count = 3, shipName = "imp_tie_fighter_tier1" } } },
		},
		[C.M2] = {
			className = C.M2, questName = "tatooine_rebel_3", questType = "destroy", questZone = "space_tatooine",
			creditReward = 200,
			sideQuest = false, sideQuestType = "",
			killsRequired = 4,
			shipLocations = { spawner("anchorhead_tie_rally_alpha"), spawner("imp_base_defense_03"), spawner("imperial_base_guard_1"), spawner("imperial_squad_1") },
			shipTypes = { "imp_tie_fighter_tier1", "imp_tie_fighter_tier2", "imp_tie_fighter_tier3", "imp_tie_fighter_tier4", "imp_tie_fighter_tier2_tatooine" },
		},
		[C.P3] = {
			className = C.P3, questName = "tatooine_rebel_2", questType = "patrol", questZone = "space_tatooine",
			creditReward = 500,
			itemReward = {
				{ species = { SPECIES_WOOKIEE }, item = C.WOOKIEE_BANDOLIER },
				{ species = { SPECIES_ITHORIAN }, item = C.ITHORIAN_BANDOLIER },
				{ species = { -1 }, item = C.FLIGHT_SUIT },
			},
			sideQuest = true, sideQuestType = "escort", sideQuestName = "tatooine_rebel_2",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 2, sideQuestDelay = 10,
			patrolPoints = { patrolPoint("anchorhead_armed_recon_1", 1), patrolPoint("anchorhead_armed_recon_2", 2), patrolPoint("anchorhead_armed_recon_3", 3) },
		},
		[C.E3] = {
			className = C.E3, questName = "tatooine_rebel_2", questType = "escort", questZone = "space_tatooine",
			sideQuest = false, sideQuestType = "",
			parentQuest = C.P3, parentQuestType = "patrol", parentQuestName = "tatooine_rebel_2",
			escortShips = { "reb_freightermedium_tier1" },
			escortPoints = { escortPoint("anchorhead_escort_1", 1), escortPoint("anchorhead_escort_2", 2), escortPoint("anchorhead_escort_3", 3) },
			attackDelay = 90,
			attackShips = { { "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1" } },
			tauntData = taunts(5),
		},
		[C.A4] = {
			className = C.A4, questName = "tatooine_rebel_4", questType = "assassinate", questZone = "space_tatooine",
			creditReward = 1000,
			itemReward = { { species = { -1 }, item = C.ARMOR } },
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 10, failTimer = 20, mustDestroyEscort = false,
			assassinateSpawns = { target = "imp_tie_fighter_veteran_tier2", escorts = { "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1" } },
			targetPatrols = {
				point("bestine_security_escort_1", {}), point("bestine_security_escort_3", {}), point("bestine_security_escort_5", {}), point("bestine_security_patrol_2", {}),
			},
		},
		[C.DUTY6] = {
			className = C.DUTY6, questName = "tatooine_rebel_6", questType = "destroy_duty", questZone = "space_tatooine",
			creditReward = 100,
			sideQuest = false, sideQuestType = "",
			totalLevels = 5, totalRounds = 2, totalWaves = 3,
			bossShip = "imp_tie_fighter_tier2",
			shipTypes = { { "imp_tie_fighter_tier1" } },
		},
		[C.DUTY7] = {
			className = C.DUTY7, questName = "tatooine_rebel_7", questType = "escort_duty", questZone = "space_tatooine",
			creditReward = 1000, creditKillBonus = 100,
			sideQuest = false, sideQuestType = "",
			escortShips = { "reb_freighterheavy_tier1", "reb_freighterlight_tier1", "reb_freightermedium_tier1" },
			escortPoints = {
				escortPoint("anchorhead_escort_1", 1), escortPoint("anchorhead_escort_3", 2), escortPoint("anchorhead_supply_patrol_1", 3), escortPoint("anchorhead_supply_patrol_3", 4),
			},
			attackDelay = 100,
			attackShips = { { "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1" } },
			tauntData = taunts(5),
		},
	}
end

-- Conversation flow 3.4: TRAIN_CHOICES in table order. One click, no gender split (FI-2).
C.TRAIN = {
	{ x = "starships", skill = "pilot_rebel_navy_starships_01", reply = "s_26970ef", screen = "trained_starships", sid = "s_c7afc225" },
	{ x = "weapons", skill = "pilot_rebel_navy_weapons_01", reply = "s_d912490", screen = "trained_weapons", sid = "s_d5bc59d9" },
	{ x = "procedures", skill = "pilot_rebel_navy_procedures_01", reply = "s_8c272224", screen = "trained_procedures", sid = "s_96e50d8" },
	{ x = "droid", skill = "pilot_rebel_navy_droid_01", reply = "s_9480f430", screen = "trained_droid", sid = "s_c93f1cdc" },
}

C.MENU_FIRST = "s_6221bd32"
C.MENU_MORE = "s_2c8ee9d"
C.TRAINING_COST = 7500

C.NOVICE = "pilot_rebel_navy_novice"

-- Waypoint of J's giveMajorEkerWaypoint (J:190-196), D-12
C.EKER_WAYPOINT = { planet = "yavin4", name = "@npc_spawner_n:eker", x = -6969, z = 0, y = -5667 }

-- Da'la Socuna in the Mos Espa cantina (tatooine_mos_espa.lua:187): zone and the spawn cell position
C.NPC_AT = { zone = "tatooine", x = -29.7, z = -0.5, y = 7.8, parentID = 1256068 }

function C.tierSkills(count)
	local out = {}

	for i = 1, count do
		out[i] = C.TRAIN[i].skill
	end

	return out
end

-- Appendix A
C.SCREENS = require("crimson_tier1_screens_data")

function C.screenRow(id)
	for _, row in ipairs(C.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (181), sorted
function C.screenIds()
	local out = {}

	for i, row in ipairs(C.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

C.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		C.loadErrors[#C.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: the squadron files, the Socuna template, the Socuna handler. A missing production file is recorded in
-- C.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function C.load()
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

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "InquisitionSquadronScreenplay", "StormSquadronScreenplay", "VortexSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		-- a squadron another loader already ran stays as it is: loading twice would register it twice
		if rawget(_G, name) == nil then
			try(name, function() H.loadSquadron(name) end)
		end
	end

	try("socuna_convo.lua", function() H.loadMobile("conversations/space/rebel/crimson_phoenix_squadron/socuna_convo.lua") end)
	try("socunaConvoHandler.lua", function() H.loadScreenplay("space/conversations/rebel/crimson_phoenix_squadron/socunaConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function C.requireConversation(lu)
	C.load()
	lu.assertNotNil(H.conversationTemplateTable(C.TEMPLATE), C.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. table.concat(C.loadErrors, " | "))
	lu.assertNotNil(rawget(_G, C.HANDLER), C.HANDLER .. " is not defined. Load problems: " .. table.concat(C.loadErrors, " | "))
end

function C.quest(global)
	C.load()

	return H.expectGlobal(global, "Crimson Phoenix tier 1 quest table (crimson-phoenix-tier1-da-la-socuna). Load problems: " .. table.concat(C.loadErrors, " | "))
end

function C.squadron()
	C.load()

	return H.expectGlobal("CrimsonPhoenixSquadronScreenplay", "squadron screenplay object. Load problems: " .. table.concat(C.loadErrors, " | "))
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = C.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

C.crc = crc

-- Quest state helpers on a built pilot. state: "complete" | "active" | "none"
function C.setState(player, global, state)
	local id = C.IDENTITY[global]
	local key = H.questCrc(id.type, id.name)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function C.state(player, global)
	local id = C.IDENTITY[global]
	local key = H.questCrc(id.type, id.name)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- the quest name of mission n's status keys (J's mission order: 1 = rebel_1, 2 = rebel_3, 3 = rebel_2, 4 = rebel_4)
C.STATUS_NAMES = { "tatooine_rebel_1", "tatooine_rebel_3", "tatooine_rebel_2", "tatooine_rebel_4" }

local function statusName(n) return C.STATUS_NAMES[n] end

C.statusName = statusName

-- Options (all optional; the default is a Crimson Phoenix pilot with a ship, standing 0, no mission done, Rebel faction):
--   pilot      "rebel" (default) | "neutral" | "imperial" | false (not a pilot)
--   faction    "rebel" (default) | "imperial" | "neutral" (no faction)
--   squadron   true (default: CRIMSON_PHOENIX_SQUADRON) | false (none) | a squadron constant
--   standing   Rebel faction standing (default 0)
--   ship       certified ship (default true)
--   paid       k: missions 1..k won, :attempted and :reward set (default 0)
--   state      the state of mission paid+1: "won" (every chain member complete, :attempted, reward unpaid) | "failed" (:attempted, nothing complete) |
--              "active" (:attempted, head chain member active) | "attempted" (just :attempted)
--   tier       number of tier 1 skills (the first n of C.TRAIN); skills = a list of skill names held besides the novice box
--   xp         space_combat_general experience (default 0)
--   graduated  EKER_PILOT_KEY set: true -> "1", or the given string (e.g. "2")
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   duty       global of a duty held active in the journal
--   species    SPECIES_* (default SPECIES_HUMAN: the fake's default 0 is not a species constant)
--   gender     0 male (default) | 1 female
--   pilotTier  ghost pilot tier (default 1)
--   inventory  (default true); see H.newPlayer
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
function C.pilot(o)
	o = o or {}
	C.load()

	local pilotKind = o.pilot

	if pilotKind == nil then
		pilotKind = "rebel"
	elseif pilotKind == false then
		pilotKind = nil
	end

	local faction = ({ imperial = FACTIONIMPERIAL, rebel = FACTIONREBEL })[o.faction or "rebel"] or 0
	local squadron = o.squadron

	if squadron == nil or squadron == true then
		squadron = CRIMSON_PHOENIX_SQUADRON
	elseif squadron == false then
		squadron = 0
	end

	-- a non-pilot has no pilot skill, so the novice box can still be granted
	local skills = { C.NOVICE }

	if pilotKind == nil then
		skills = {}
	end

	for _, skill in ipairs(o.skills or {}) do
		skills[#skills + 1] = skill
	end

	for _, skill in ipairs(C.tierSkills(o.tier or 0)) do
		skills[#skills + 1] = skill
	end

	local paid = o.paid or 0
	local completed, active, status = {}, {}, {}

	for n = 1, paid do
		for _, g in ipairs(C.CHAINS[n]) do
			completed[#completed + 1] = crc(g)
		end

		status[statusName(n) .. ":attempted"] = "1"
		status[statusName(n) .. ":reward"] = "1"
	end

	local n = paid + 1

	if o.state ~= nil and C.CHAINS[n] ~= nil then
		status[statusName(n) .. ":attempted"] = "1"

		if o.state == "won" then
			for _, g in ipairs(C.CHAINS[n]) do
				completed[#completed + 1] = crc(g)
			end
		elseif o.state == "active" then
			active[#active + 1] = crc(C.CHAINS[n][1])
		end
	end

	if o.graduated then
		status[C.EKER_PILOT_KEY] = type(o.graduated) == "string" and o.graduated or "1"
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
		factionStanding = { rebel = o.standing or 0, imperial = 0 },
		completedQuests = completed,
		activeQuests = active,
		questStatus = status,
		species = o.species or SPECIES_HUMAN,
		gender = o.gender,
		inventory = o.inventory ~= false and (o.inventory or true) or nil,
		inventoryFull = o.inventoryFull,
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

-- Engine XP prices of the four tier 1 skills, from the SWG skills.tab excerpt (fixtures/skill/skills.pilot_rebel_navy_01.tab)
function C.useSkillCosts()
	local costs = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_rebel_navy_01.tab").records) do
		local name = rec:get("NAME")

		if name ~= nil and name:match("^pilot_rebel_navy_%a+_01$") then
			costs[name] = rec:num("XP_COST")
		end
	end

	H.Engine.config.skillXpCosts = costs

	return costs
end

-- Da'la Socuna in the Mos Espa cantina (C.NPC_AT)
function C.npc(at)
	at = at or C.NPC_AT

	return H.newNpc({ name = "Da'la Socuna", zone = at.zone, x = at.x, z = at.z, y = at.y, parentID = at.parentID })
end

function C.requireConversationLoaded()
	C.load()

	if H.conversationTemplateTable(C.TEMPLATE) == nil or rawget(_G, C.HANDLER) == nil then
		error("Da'la Socuna's conversation is not loaded. Load problems: " .. table.concat(C.loadErrors, " | "), 3)
	end
end

-- Talks to Da'la Socuna from the first screen. choices as for H.converse.
function C.talk(player, choices, at)
	C.requireConversationLoaded()

	return H.converse({ template = C.TEMPLATE, player = player, npc = C.npc(at), choices = choices })
end

-- The id of the first screen of a fresh talk
function C.firstScreen(player)
	return C.talk(player)[1].id
end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session.
function C.drive(player, startId, choices)
	C.requireConversationLoaded()

	local tmpl = H.conversationTemplate(C.TEMPLATE)
	local handler = rawget(_G, C.HANDLER)
	local npc = C.npc()
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
		error("screen '" .. startId .. "' is not in " .. C.TEMPLATE, 2)
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
function C.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- the option sids ("s_xxx") of a transcript step, in order
function C.optionSids(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = tostring(o.text):match(":(s_[%w_]+)$") or tostring(o.text)
	end

	return out
end

function C.linksOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = o.link
	end

	return out
end

function C.free() return H.Engine.callsTo("awardSkill") end
function C.bought() return H.Engine.callsTo("skillManagerAwardSkill") end

-- Skills (of the four) the player holds, in C.TRAIN order
function C.held(player)
	local out = {}

	for _, t in ipairs(C.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end


return C
