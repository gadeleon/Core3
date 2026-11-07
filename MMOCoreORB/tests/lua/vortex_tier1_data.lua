-- Shared test data and builders for Vortex Squadron tier 1 (V3-FX, Moenia), not a test file.
-- Spec: .claude/work/vortex-tier1-v3-fx/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself:
--   V.GLOBALS / V.IDENTITY     the 8 quest globals and their class, type and name (Content contract 1)
--   V.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   V.POINTS / V.SPAWNERS      Data mapping 2: the 16 nav points and 5 spawners, Core3 x, z, y
--   V.SCREENS                  Appendix A (vortex_tier1_screens_data.lua, generated from the spec table by a scratch script)
--   V.TRAIN                    TRAIN_CHOICES (Content contract 3, Conversation flow 3.4)
--   V.load()                   the server's load of the squadron files, the template and the handler, collecting load errors
--   V.pilot{...}               a pilot standing in front of V3-FX (see the option list at V.pilot)
--   V.talk / V.drive           H.converse from the first screen / from a given screen
--
-- V3-FX's conversation lives in the template "v3fx_convo_template", its handler is the global "v3fxConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")

local V = {}

V.TEMPLATE = "v3fx_convo_template"
V.HANDLER = "v3fxConvoHandler"
V.PREFIX = "@conversation/naboo_rebel_trainer_1:"
V.STF = "conversation/naboo_rebel_trainer_1"

V.TEMPLATE_FILE = "mobile/conversations/space/rebel/vortex_squadron/v3fx_convo.lua"
V.HANDLER_FILE = "screenplays/space/conversations/rebel/vortex_squadron/v3fxConvoHandler.lua"
V.SQUADRON_FILE = "screenplays/space/squadrons/VortexSquadronScreenplay.lua"
V.NPC_FILE = "mobile/space/v3_fx.lua"

V.P1 = "patrol_naboo_rebel_1"
V.S1 = "destroy_surpriseattack_naboo_rebel_1"
V.M2 = "destroy_naboo_rebel_2"
V.P3 = "patrol_naboo_rebel_3"
V.E3 = "escort_naboo_rebel_3"
V.A4 = "assassinate_naboo_rebel_4"
V.DUTY6 = "destroy_duty_naboo_rebel_6"
V.DUTY7 = "escort_duty_naboo_rebel_7"

V.GLOBALS = { V.P1, V.S1, V.M2, V.P3, V.E3, V.A4, V.DUTY6, V.DUTY7 }

-- global -> { class, type, name }
V.IDENTITY = {
	[V.P1] = { class = "SpacePatrolScreenplay", type = "patrol", name = "naboo_rebel_1" },
	[V.S1] = { class = "SpaceSurpriseAttackScreenplay", type = "destroy_surpriseattack", name = "naboo_rebel_1" },
	[V.M2] = { class = "SpaceDestroyScreenplay", type = "destroy", name = "naboo_rebel_2" },
	[V.P3] = { class = "SpacePatrolScreenplay", type = "patrol", name = "naboo_rebel_3" },
	[V.E3] = { class = "SpaceEscortScreenplay", type = "escort", name = "naboo_rebel_3" },
	[V.A4] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "naboo_rebel_4" },
	[V.DUTY6] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "naboo_rebel_6" },
	[V.DUTY7] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "naboo_rebel_7" },
}

-- The mission chains (head first); the story missions of the trainer
V.CHAINS = {
	{ V.P1, V.S1 },
	{ V.M2 },
	{ V.P3, V.E3 },
	{ V.A4 },
}

-- Content contract 2: the squadron object's constants
V.QUEST_STRINGS = {
	QUEST_STRING_1 = { type = "patrol", name = "naboo_rebel_1" },
	QUEST_STRING_1_SIDE = { type = "destroy_surpriseattack", name = "naboo_rebel_1" },
	QUEST_STRING_2 = { type = "destroy", name = "naboo_rebel_2" },
	QUEST_STRING_3 = { type = "patrol", name = "naboo_rebel_3" },
	QUEST_STRING_3_SIDE = { type = "escort", name = "naboo_rebel_3" },
	QUEST_STRING_4 = { type = "assassinate", name = "naboo_rebel_4" },
	QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "naboo_rebel_6" },
	QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "naboo_rebel_7" },
}

-- The hand-off constant (Content contract 2, D-11): stored under <playerID> .. VORTEX_PILOT_KEY, value "1" from V3-FX
V.VORTEX_PILOT_KEY = "VortexSquadronScreenplay:vortexPilot"

-- Data mapping 2: name -> { x, z, y }
V.POINTS = {
	rebel_patrol_1 = { -3153, 302, -6442 },
	rebel_patrol_2 = { -3971, -471, -6364 },
	rebel_patrol_3 = { -5771, -1066, -5197 },
	rebel_security_patrol_1 = { -2448, 879, -1221 },
	rebel_security_patrol_2 = { -1792, 1559, -1193 },
	rebel_security_patrol_3 = { -288, 1479, -1395 },
	rebel_security_patrol_4 = { 39, 1753, 294 },
	rebel_escort_1 = { -168, 1747, -258 },
	rebel_escort_2 = { -1077, 1502, 59 },
	rebel_escort_3 = { -1645, 1097, 854 },
	rebel_escort_4 = { -2734, 791, 1760 },
	naboo_imperial_tier2_recoveryduty_8 = { 3875, -3872, -3934 },
	naboo_imperial_tier2_recoveryduty_6 = { 417, -839, -2617 },
	naboo_imperial_tier2_recoveryduty_4 = { -1492, 746, -2021 },
	naboo_imperial_tier2_recoveryduty_2 = { 1333, -1855, -3915 },
	naboo_imperial_tier2_recovery1_3 = { 262, -3151, 332 },
}

V.SPAWNERS = {
	imperial_fluff_spawns_1 = { 386, 3917, 3129 },
	imperial_fluff_spawns_3 = { -2024, -3820, -3131 },
	imperial_fluff_spawns_5 = { -5968, -1847, 386 },
	naboo_imperial_2 = { -1915, -2006, -1455 },
	imperial_patrol_1 = { 263, 2203, 1703 },
}

V.WOOKIEE_BANDOLIER = "object/tangible/wearables/bandolier/multipocket_bandolier.iff"
V.ITHORIAN_BANDOLIER = "object/tangible/wearables/bandolier/ith_multipocket_bandolier.iff"
V.FLIGHT_SUIT = "object/tangible/wearables/bodysuit/bodysuit_s14.iff" -- D-9: SWG's rebel_bodysuit_s14.iff has no pre-NGE template
V.SWG_FLIGHT_SUIT = "object/tangible/wearables/bodysuit/rebel_bodysuit_s14.iff"
V.ARMOR = "object/tangible/ship/components/armor/arm_mission_reward_rebel_incom_ultralight.iff"

local function point(name, extra)
	local p = V.POINTS[name]
	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra) do
		t[k] = v
	end

	return t
end

local function patrolPoint(name, i) return point(name, { patrolNumber = i, radius = 150 }) end
local function escortPoint(name, i) return point(name, { zoneName = "space_naboo", escortNumber = i, radius = 250 }) end

local function spawner(name)
	local s = V.SPAWNERS[name]

	return { spawnName = name, x = s[1], z = s[2], y = s[3] }
end

local function taunts(n) return { goodbyeCount = n, reasonCount = n, tauntCount = n, thanksCount = n } end

local THREE_TIES = { "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1" }

-- global -> the whole table (Appendix B keys, Data mapping 1 values). sideQuestSplitType is SpaceQuestLogic's PATROL_POINT constant.
-- No table defines a function (Content contract 1: "No table overrides a function").
function V.expected()
	local PATROL_POINT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT

	return {
		[V.P1] = {
			className = V.P1, questName = "naboo_rebel_1", questType = "patrol", questZone = "space_naboo",
			creditReward = 100,
			sideQuest = true, sideQuestType = "destroy_surpriseattack", sideQuestName = "naboo_rebel_1",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 2, sideQuestDelay = 13,
			patrolPoints = { patrolPoint("rebel_patrol_1", 1), patrolPoint("rebel_patrol_2", 2), patrolPoint("rebel_patrol_3", 3) },
		},
		[V.S1] = {
			className = V.S1, questName = "naboo_rebel_1", questType = "destroy_surpriseattack", questZone = "space_naboo",
			sideQuest = false, sideQuestType = "",
			parentQuest = V.P1, parentQuestType = "patrol", parentQuestName = "naboo_rebel_1",
			surpriseAttackShips = { zone = "space_naboo", spawns = { { count = 3, shipName = "imp_tie_fighter_tier1" } } },
		},
		[V.M2] = {
			className = V.M2, questName = "naboo_rebel_2", questType = "destroy", questZone = "space_naboo",
			creditReward = 200,
			sideQuest = false, sideQuestType = "",
			killsRequired = 4,
			shipLocations = {
				spawner("imperial_fluff_spawns_1"), spawner("imperial_fluff_spawns_3"), spawner("imperial_fluff_spawns_5"), spawner("naboo_imperial_2"), spawner("imperial_patrol_1"),
			},
			shipTypes = { "imp_tie_fighter_tier1", "imp_tie_fighter_tier2", "imp_tie_fighter_tier3", "imp_tie_fighter_tier4", "imp_tie_fighter_tier2_naboo" },
		},
		[V.P3] = {
			className = V.P3, questName = "naboo_rebel_3", questType = "patrol", questZone = "space_naboo",
			creditReward = 500,
			itemReward = {
				{ species = { SPECIES_WOOKIEE }, item = V.WOOKIEE_BANDOLIER },
				{ species = { SPECIES_ITHORIAN }, item = V.ITHORIAN_BANDOLIER },
				{ species = { -1 }, item = V.FLIGHT_SUIT },
			},
			sideQuest = true, sideQuestType = "escort", sideQuestName = "naboo_rebel_3",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 2, sideQuestDelay = 15,
			patrolPoints = {
				patrolPoint("rebel_security_patrol_1", 1), patrolPoint("rebel_security_patrol_2", 2),
				patrolPoint("rebel_security_patrol_3", 3), patrolPoint("rebel_security_patrol_4", 4),
			},
		},
		[V.E3] = {
			className = V.E3, questName = "naboo_rebel_3", questType = "escort", questZone = "space_naboo",
			sideQuest = false, sideQuestType = "",
			parentQuest = V.P3, parentQuestType = "patrol", parentQuestName = "naboo_rebel_3",
			escortShips = { "reb_freightermedium_tier1" },
			escortPoints = { escortPoint("rebel_escort_1", 1), escortPoint("rebel_escort_2", 2), escortPoint("rebel_escort_3", 3), escortPoint("rebel_escort_4", 4) },
			attackDelay = 80,
			attackShips = { { "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1" } },
			tauntData = taunts(3),
		},
		[V.A4] = {
			className = V.A4, questName = "naboo_rebel_4", questType = "assassinate", questZone = "space_naboo",
			creditReward = 1000,
			itemReward = { { species = { -1 }, item = V.ARMOR } },
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 10, failTimer = 20, mustDestroyEscort = false,
			assassinateSpawns = { target = "imp_tie_fighter_veteran_tier2", escorts = { "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1" } },
			targetPatrols = {
				point("naboo_imperial_tier2_recoveryduty_8", {}), point("naboo_imperial_tier2_recoveryduty_6", {}), point("naboo_imperial_tier2_recoveryduty_4", {}),
				point("naboo_imperial_tier2_recoveryduty_2", {}), point("naboo_imperial_tier2_recovery1_3", {}),
			},
		},
		[V.DUTY6] = {
			className = V.DUTY6, questName = "naboo_rebel_6", questType = "destroy_duty", questZone = "space_naboo",
			creditReward = 100,
			sideQuest = false, sideQuestType = "",
			totalLevels = 5, totalRounds = 2, totalWaves = 3,
			bossShip = "imp_tie_fighter_tier2",
			shipTypes = { { "imp_tie_fighter_tier1" } },
		},
		[V.DUTY7] = {
			className = V.DUTY7, questName = "naboo_rebel_7", questType = "escort_duty", questZone = "space_naboo",
			creditReward = 1000, creditKillBonus = 100,
			sideQuest = false, sideQuestType = "",
			escortShips = { "reb_transport_tier1", "reb_freightermedium_tier1", "reb_freighterlight_tier1", "reb_freighterheavy_tier1" },
			escortPoints = {
				escortPoint("rebel_patrol_1", 1), escortPoint("rebel_patrol_2", 2), escortPoint("rebel_patrol_3", 3),
				escortPoint("rebel_escort_1", 4), escortPoint("rebel_escort_2", 5), escortPoint("rebel_escort_3", 6), escortPoint("rebel_escort_4", 7),
			},
			attackDelay = 100,
			attackShips = { { "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1" } },
			tauntData = taunts(5),
		},
	}
end

-- Conversation flow 3.4: TRAIN_CHOICES in table order. male / female = the screen for the pilot's gender, sid = that screen's dialog line.
V.TRAIN = {
	{ x = "starships", skill = "pilot_rebel_navy_starships_01", reply = "s_26970ef", male = "trained_starships_male", female = "trained_starships_female", maleSid = "s_d671116a", femaleSid = "s_593caccf" },
	{ x = "weapons", skill = "pilot_rebel_navy_weapons_01", reply = "s_3fa70900", male = "trained_weapons", female = "trained_weapons", maleSid = "s_c5dca41d", femaleSid = "s_c5dca41d" },
	{ x = "procedures", skill = "pilot_rebel_navy_procedures_01", reply = "s_8c272224", male = "trained_procedures", female = "trained_procedures", maleSid = "s_145a9b15", femaleSid = "s_145a9b15" },
	{ x = "droid", skill = "pilot_rebel_navy_droid_01", reply = "s_9480f430", male = "trained_droid_male", female = "trained_droid_female", maleSid = "s_8062b983", femaleSid = "s_b0d2b96b" },
}

V.MENU_FIRST = "s_6f3e9d4b"
V.MENU_MORE = "s_838cca30"
V.TRAINING_COST = 7500

V.NOVICE = "pilot_rebel_navy_novice"
V.SPARKS_EFFECT = "clienteffect/lair_damage_light.cef"

-- The droid in the Moenia gazebo (naboo_moenia.lua:108): zone, position and cell the sparks are played at
V.NPC_AT = { zone = "naboo", x = 4764.2, z = 6.1, y = -4795.2, parentID = 0 }

function V.tierSkills(count)
	local out = {}

	for i = 1, count do
		out[i] = V.TRAIN[i].skill
	end

	return out
end

-- Appendix A
V.SCREENS = require("vortex_tier1_screens_data")

function V.screenRow(id)
	for _, row in ipairs(V.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (137), sorted
function V.screenIds()
	local out = {}

	for i, row in ipairs(V.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

V.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		V.loadErrors[#V.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: the squadron files, the V3-FX template, the V3-FX handler. A missing production file is recorded in
-- V.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function V.load()
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

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "InquisitionSquadronScreenplay", "StormSquadronScreenplay", "VortexSquadronScreenplay" }) do
		-- a squadron another loader already ran stays as it is: loading twice would register it twice
		if rawget(_G, name) == nil then
			try(name, function() H.loadSquadron(name) end)
		end
	end

	try("v3fx_convo.lua", function() H.loadMobile("conversations/space/rebel/vortex_squadron/v3fx_convo.lua") end)
	try("v3fxConvoHandler.lua", function() H.loadScreenplay("space/conversations/rebel/vortex_squadron/v3fxConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function V.requireConversation(lu)
	V.load()
	lu.assertNotNil(H.conversationTemplateTable(V.TEMPLATE), V.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. table.concat(V.loadErrors, " | "))
	lu.assertNotNil(rawget(_G, V.HANDLER), V.HANDLER .. " is not defined. Load problems: " .. table.concat(V.loadErrors, " | "))
end

function V.quest(global)
	V.load()

	return H.expectGlobal(global, "Vortex tier 1 quest table (vortex-tier1-v3-fx). Load problems: " .. table.concat(V.loadErrors, " | "))
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = V.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

V.crc = crc

-- Quest state helpers on a built pilot. state: "complete" | "active" | "none"
function V.setState(player, global, state)
	local id = V.IDENTITY[global]
	local key = H.questCrc(id.type, id.name)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function V.state(player, global)
	local id = V.IDENTITY[global]
	local key = H.questCrc(id.type, id.name)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

local function statusName(n) return "naboo_rebel_" .. n end

V.STATUS_NAMES = { statusName(1), statusName(2), statusName(3), statusName(4) }

-- Options (all optional; the default is a Vortex pilot with a ship, standing 0, no mission done, Rebel faction):
--   pilot      "rebel" (default) | "neutral" | "imperial" | false (not a pilot)
--   faction    "rebel" (default) | "imperial" | "neutral" (no faction)
--   squadron   true (default: VORTEX_SQUADRON) | false (none) | a squadron constant
--   standing   Rebel faction standing (default 0)
--   ship       certified ship (default true)
--   paid       k: missions 1..k won, :attempted and :reward set (default 0)
--   state      the state of mission paid+1: "won" (every chain member complete, :attempted, reward unpaid) | "failed" (:attempted, nothing complete) |
--              "active" (:attempted, head chain member active) | "attempted" (just :attempted)
--   tier       number of tier 1 skills (the first n of V.TRAIN); skills = a list of skill names held besides the novice box
--   xp         space_combat_general experience (default 0)
--   graduated  VORTEX_PILOT_KEY set: true -> "1", or the given string (e.g. "2", "3")
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   duty       global of a duty held active in the journal
--   species    SPECIES_* (default SPECIES_HUMAN: the fake's default 0 is not a species constant)
--   gender     0 male (default) | 1 female
--   pilotTier  ghost pilot tier (default 1)
--   inventory  (default true); see H.newPlayer
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
function V.pilot(o)
	o = o or {}
	V.load()

	local pilotKind = o.pilot

	if pilotKind == nil then
		pilotKind = "rebel"
	elseif pilotKind == false then
		pilotKind = nil
	end

	local faction = ({ imperial = FACTIONIMPERIAL, rebel = FACTIONREBEL })[o.faction or "rebel"] or 0
	local squadron = o.squadron

	if squadron == nil or squadron == true then
		squadron = VORTEX_SQUADRON
	elseif squadron == false then
		squadron = 0
	end

	-- a non-pilot has no pilot skill, so the novice box can still be granted
	local skills = { V.NOVICE }

	if pilotKind == nil then
		skills = {}
	end

	for _, skill in ipairs(o.skills or {}) do
		skills[#skills + 1] = skill
	end

	for _, skill in ipairs(V.tierSkills(o.tier or 0)) do
		skills[#skills + 1] = skill
	end

	local paid = o.paid or 0
	local completed, active, status = {}, {}, {}

	for n = 1, paid do
		for _, g in ipairs(V.CHAINS[n]) do
			completed[#completed + 1] = crc(g)
		end

		status[statusName(n) .. ":attempted"] = "1"
		status[statusName(n) .. ":reward"] = "1"
	end

	local n = paid + 1

	if o.state ~= nil and V.CHAINS[n] ~= nil then
		status[statusName(n) .. ":attempted"] = "1"

		if o.state == "won" then
			for _, g in ipairs(V.CHAINS[n]) do
				completed[#completed + 1] = crc(g)
			end
		elseif o.state == "active" then
			active[#active + 1] = crc(V.CHAINS[n][1])
		end
	end

	if o.graduated then
		-- graduated = true writes "1" (V3-FX's own hand-off); a string writes that value ("2", "3": what tier 2 writes, D-11)
		status[V.VORTEX_PILOT_KEY] = type(o.graduated) == "string" and o.graduated or "1"
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
function V.useSkillCosts()
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

-- V3-FX in the Moenia gazebo (V.NPC_AT): the sparks are played at his zone, position and cell
function V.npc(at)
	at = at or V.NPC_AT

	return H.newNpc({ name = "V3-FX", zone = at.zone, x = at.x, z = at.z, y = at.y, parentID = at.parentID })
end

function V.requireConversationLoaded()
	V.load()

	if H.conversationTemplateTable(V.TEMPLATE) == nil or rawget(_G, V.HANDLER) == nil then
		error("V3-FX's conversation is not loaded. Load problems: " .. table.concat(V.loadErrors, " | "), 3)
	end
end

-- Talks to V3-FX from the first screen. choices as for H.converse; `at` (optional) places the droid elsewhere, as V.NPC_AT.
function V.talk(player, choices, at)
	V.requireConversationLoaded()

	return H.converse({ template = V.TEMPLATE, player = player, npc = V.npc(at), choices = choices })
end

-- The id of the first screen of a fresh talk
function V.firstScreen(player)
	return V.talk(player)[1].id
end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session.
function V.drive(player, startId, choices)
	V.requireConversationLoaded()

	local tmpl = H.conversationTemplate(V.TEMPLATE)
	local handler = rawget(_G, V.HANDLER)
	local npc = V.npc()
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
		error("screen '" .. startId .. "' is not in " .. V.TEMPLATE, 2)
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
function V.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- the option sids ("s_xxx") of a transcript step, in order
function V.optionSids(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = tostring(o.text):match(":(s_[%w_]+)$") or tostring(o.text)
	end

	return out
end

function V.linksOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = o.link
	end

	return out
end

function V.free() return H.Engine.callsTo("awardSkill") end
function V.bought() return H.Engine.callsTo("skillManagerAwardSkill") end

-- Skills (of the four) the player holds, in V.TRAIN order
function V.held(player)
	local out = {}

	for _, t in ipairs(V.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

-- The sparks V3-FX played: the recorded playClientEffectLoc calls
function V.sparks() return H.Engine.callsTo("playClientEffectLoc") end

return V
