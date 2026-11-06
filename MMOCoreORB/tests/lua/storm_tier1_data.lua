-- Shared test data and builders for Storm Squadron tier 1 (Lt. Akal Colzet), not a test file.
-- Spec: .claude/work/storm-tier1-akal-colzet/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself:
--   S.GLOBALS / S.IDENTITY     the 8 quest globals and their class, type and name (Content contract 1)
--   S.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   S.POINTS / S.SPAWNERS      Data mapping 2: the 18 nav points and 4 spawners, Core3 x, z, y
--   S.SCREENS                  Appendix A (storm_tier1_screens_data.lua, generated from the spec table by a scratch script)
--   S.TRAIN                    TRAIN_CHOICES (Content contract 3, Conversation flow 3.4)
--   S.load()                   the server's load of the squadron files, the template and the handler, collecting load errors
--   S.pilot{...}               a pilot standing in front of Colzet (see the option list at S.pilot)
--   S.talk / S.drive           H.converse from the first screen / from a given screen
--
-- Colzet's conversation lives in the template "akal_colzet_convo_template", its handler is the global "akalColzetConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")

local S = {}

S.TEMPLATE = "akal_colzet_convo_template"
S.HANDLER = "akalColzetConvoHandler"
S.PREFIX = "@conversation/tatooine_imperial_trainer_1:"
S.STF = "conversation/tatooine_imperial_trainer_1"

S.TEMPLATE_FILE = "mobile/conversations/space/imperial/storm_squadron/akal_colzet_convo.lua"
S.HANDLER_FILE = "screenplays/space/conversations/imperial/storm_squadron/akalColzetConvoHandler.lua"
S.SQUADRON_FILE = "screenplays/space/squadrons/StormSquadronScreenplay.lua"
S.NPC_FILE = "mobile/space/akal_colzet.lua"

S.P1 = "patrol_tatooine_imperial_1"
S.S1 = "destroy_surpriseattack_tatooine_imperial_1"
S.M2 = "destroy_tatooine_imperial_2"
S.P3 = "patrol_tatooine_imperial_3"
S.E3 = "escort_tatooine_imperial_3"
S.A4 = "assassinate_tatooine_imperial_4"
S.DUTY6 = "destroy_duty_tatooine_imperial_6"
S.DUTY7 = "escort_duty_tatooine_imperial_7"

S.GLOBALS = { S.P1, S.S1, S.M2, S.P3, S.E3, S.A4, S.DUTY6, S.DUTY7 }

-- global -> { class, type, name }
S.IDENTITY = {
	[S.P1] = { class = "SpacePatrolScreenplay", type = "patrol", name = "tatooine_imperial_1" },
	[S.S1] = { class = "SpaceSurpriseAttackScreenplay", type = "destroy_surpriseattack", name = "tatooine_imperial_1" },
	[S.M2] = { class = "SpaceDestroyScreenplay", type = "destroy", name = "tatooine_imperial_2" },
	[S.P3] = { class = "SpacePatrolScreenplay", type = "patrol", name = "tatooine_imperial_3" },
	[S.E3] = { class = "SpaceEscortScreenplay", type = "escort", name = "tatooine_imperial_3" },
	[S.A4] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "tatooine_imperial_4" },
	[S.DUTY6] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "tatooine_imperial_6" },
	[S.DUTY7] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "tatooine_imperial_7" },
}

-- The mission chains (head first); the story missions of the trainer
S.CHAINS = {
	{ S.P1, S.S1 },
	{ S.M2 },
	{ S.P3, S.E3 },
	{ S.A4 },
}

-- Content contract 2: the squadron object's constants
S.QUEST_STRINGS = {
	QUEST_STRING_1 = { type = "patrol", name = "tatooine_imperial_1" },
	QUEST_STRING_1_SIDE = { type = "destroy_surpriseattack", name = "tatooine_imperial_1" },
	QUEST_STRING_2 = { type = "destroy", name = "tatooine_imperial_2" },
	QUEST_STRING_3 = { type = "patrol", name = "tatooine_imperial_3" },
	QUEST_STRING_3_SIDE = { type = "escort", name = "tatooine_imperial_3" },
	QUEST_STRING_4 = { type = "assassinate", name = "tatooine_imperial_4" },
	QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "tatooine_imperial_6" },
	QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "tatooine_imperial_7" },
}

S.SERIES_SUFFIX = "StormSquadronScreenplay:imperial_tatooine_1"
S.TRANSFER_FORM = "object/tangible/space/mission_objects/transfer_auth.iff"

-- Data mapping 2: name -> { x, z, y }
S.POINTS = {
	bestine_commerce_patrol_1 = { 2217, -4387, 2967 },
	bestine_commerce_patrol_2 = { 1500, -3750, 4460 },
	bestine_commerce_patrol_3 = { -304, -4571, 4419 },
	bestine_security_patrol_1 = { 2458, -3985, 2511 },
	bestine_security_patrol_2 = { 1923, -3956, 3964 },
	bestine_security_patrol_3 = { 507, -2183, 4492 },
	bestine_security_patrol_4 = { -610, -3462, 5448 },
	bestine_security_escort_1 = { -687, -4985, 5979 },
	bestine_security_escort_2 = { 1560, -4462, 5550 },
	bestine_security_escort_3 = { 3957, -4516, 4717 },
	bestine_security_escort_4 = { 5463, -3570, 2317 },
	bestine_security_escort_5 = { 3521, 463, 2010 },
	corellia_imperial_tier3_leg_4_assasinate_two_1 = { -1994, -5029, 4770 },
	corellia_imperial_tier3_leg_4_assasinate_two_3 = { 2956, -4696, 5535 },
	imperial_escortduty_1 = { 5392, -3840, 620 },
	imperial_escortduty_2 = { 2356, -3868, 4288 },
	imperial_escortduty_3 = { -1136, -3592, 4100 },
	imperial_escortduty_4 = { -5188, -3188, 4736 },
}

S.SPAWNERS = {
	bestine_escort_threat_1 = { 2525, 933, 851 },
	bestine_pirate_leader_guards = { -1599, -3076, 3432 },
	bestine_pirates = { 896, 1268, -2850 },
	bestine_security_threat_1 = { -3461, 775, -1259 },
}

S.WOOKIEE_BANDOLIER = "object/tangible/wearables/bandolier/double_bandolier.iff"
S.ITHORIAN_BANDOLIER = "object/tangible/wearables/bandolier/ith_double_bandolier.iff"
S.TIE_SUIT = "object/tangible/wearables/bodysuit/bodysuit_tie_fighter.iff"
S.TIE_HELMET = "object/tangible/wearables/helmet/helmet_tie_fighter.iff"

local function point(name, extra)
	local p = S.POINTS[name]
	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra) do
		t[k] = v
	end

	return t
end

local function patrolPoint(name, i) return point(name, { patrolNumber = i, radius = 150 }) end
local function escortPoint(name, i) return point(name, { zoneName = "space_tatooine", escortNumber = i, radius = 250 }) end

local function spawner(name)
	local s = S.SPAWNERS[name]

	return { spawnName = name, x = s[1], z = s[2], y = s[3] }
end

local TAUNTS = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }

-- global -> the whole table (Appendix B keys, Data mapping 1 values). sideQuestSplitType is SpaceQuestLogic's PATROL_POINT constant.
-- No table defines a function (Content contract 1: "No table overrides a function").
function S.expected()
	local PATROL_POINT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT
	local TWO_1 = "corellia_imperial_tier3_leg_4_assasinate_two_1"
	local TWO_3 = "corellia_imperial_tier3_leg_4_assasinate_two_3"

	return {
		[S.P1] = {
			className = S.P1, questName = "tatooine_imperial_1", questType = "patrol", questZone = "space_tatooine",
			creditReward = 100,
			sideQuest = true, sideQuestType = "destroy_surpriseattack", sideQuestName = "tatooine_imperial_1",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 2, sideQuestDelay = 10,
			patrolPoints = { patrolPoint("bestine_commerce_patrol_1", 1), patrolPoint("bestine_commerce_patrol_2", 2), patrolPoint("bestine_commerce_patrol_3", 3) },
		},
		[S.S1] = {
			className = S.S1, questName = "tatooine_imperial_1", questType = "destroy_surpriseattack", questZone = "space_tatooine",
			sideQuest = false, sideQuestType = "",
			parentQuest = S.P1, parentQuestType = "patrol", parentQuestName = "tatooine_imperial_1",
			surpriseAttackShips = { zone = "space_tatooine", spawns = { { count = 3, shipName = "bestine_pirate_tier1" } } },
		},
		[S.M2] = {
			className = S.M2, questName = "tatooine_imperial_2", questType = "destroy", questZone = "space_tatooine",
			creditReward = 200,
			sideQuest = false, sideQuestType = "",
			killsRequired = 4,
			shipLocations = {
				spawner("bestine_escort_threat_1"), spawner("bestine_pirate_leader_guards"), spawner("bestine_pirates"), spawner("bestine_security_threat_1"),
			},
			shipTypes = { "bestine_pirate_tier1" },
		},
		[S.P3] = {
			className = S.P3, questName = "tatooine_imperial_3", questType = "patrol", questZone = "space_tatooine",
			creditReward = 500,
			itemReward = {
				{ species = { SPECIES_WOOKIEE }, item = S.WOOKIEE_BANDOLIER },
				{ species = { SPECIES_ITHORIAN }, item = S.ITHORIAN_BANDOLIER },
				{ species = { -1 }, item = S.TIE_SUIT },
			},
			sideQuest = true, sideQuestType = "escort", sideQuestName = "tatooine_imperial_3",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 3, sideQuestDelay = 20,
			patrolPoints = {
				patrolPoint("bestine_security_patrol_1", 1), patrolPoint("bestine_security_patrol_2", 2),
				patrolPoint("bestine_security_patrol_3", 3), patrolPoint("bestine_security_patrol_4", 4),
			},
		},
		[S.E3] = {
			className = S.E3, questName = "tatooine_imperial_3", questType = "escort", questZone = "space_tatooine",
			sideQuest = false, sideQuestType = "",
			parentQuest = S.P3, parentQuestType = "patrol", parentQuestName = "tatooine_imperial_3",
			escortShips = { "imp_freighterheavy_tatooine_tier1" },
			escortPoints = {
				escortPoint("bestine_security_escort_1", 1), escortPoint("bestine_security_escort_2", 2), escortPoint("bestine_security_escort_3", 3),
				escortPoint("bestine_security_escort_4", 4), escortPoint("bestine_security_escort_5", 5),
			},
			attackDelay = 90,
			attackShips = { { "bestine_pirate_tier1", "bestine_pirate_tier1" }, { "bestine_pirate_leader_tier1" } },
			tauntData = TAUNTS,
		},
		[S.A4] = {
			className = S.A4, questName = "tatooine_imperial_4", questType = "assassinate", questZone = "space_tatooine",
			creditReward = 1000,
			itemReward = { { species = { -1 }, item = S.TIE_HELMET } },
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 15, failTimer = 20, mustDestroyEscort = false,
			assassinateSpawns = { target = "bestine_pirate_leader_tier1", escorts = { "bestine_pirate_tier1" } },
			targetPatrols = { point(TWO_1, {}), point(TWO_1, {}), point(TWO_3, {}) },
		},
		[S.DUTY6] = {
			className = S.DUTY6, questName = "tatooine_imperial_6", questType = "destroy_duty", questZone = "space_tatooine",
			creditReward = 100,
			sideQuest = false, sideQuestType = "",
			totalLevels = 5, totalRounds = 2, totalWaves = 3,
			bossShip = "bestine_pirate_leader_tier1",
			shipTypes = { { "bestine_pirate_tier1" } },
		},
		[S.DUTY7] = {
			className = S.DUTY7, questName = "tatooine_imperial_7", questType = "escort_duty", questZone = "space_tatooine",
			creditReward = 1000, creditKillBonus = 100,
			sideQuest = false, sideQuestType = "",
			escortShips = { "freighterheavy_tier1", "freighterlight_tier1", "freightermedium_tier1", "imp_freightermedium_tier1", "imp_freighterlight_tier1", "imp_freighterheavy_tier1" },
			escortPoints = { escortPoint("imperial_escortduty_1", 1), escortPoint("imperial_escortduty_2", 2), escortPoint("imperial_escortduty_3", 3), escortPoint("imperial_escortduty_4", 4) },
			attackDelay = 100,
			attackShips = { { "reb_xwing_tier1", "reb_ywing_tier1" }, { "bestine_pirate_tier1", "bestine_pirate_tier1" } },
			tauntData = TAUNTS,
		},
	}
end

-- Conversation flow 3.4: TRAIN_CHOICES in table order
S.TRAIN = {
	{ x = "starships", skill = "pilot_imperial_navy_starships_01", reply = "s_5e3cf461", desc = "train_starships", trained = "trained_starships", descSid = "s_438b2349" },
	{ x = "weapons", skill = "pilot_imperial_navy_weapons_01", reply = "s_577aca95", desc = "train_weapons", trained = "trained_weapons", descSid = "s_a4c65e0b" },
	{ x = "procedures", skill = "pilot_imperial_navy_procedures_01", reply = "s_40f3848e", desc = "train_procedures", trained = "trained_procedures", descSid = "s_2e48b5f1" },
	{ x = "droid", skill = "pilot_imperial_navy_droid_01", reply = "s_a57e647c", desc = "train_droid", trained = "trained_droid", descSid = "s_df76b2e8" },
}

S.CONFIRM = "s_c6d9f61"       -- "I'd like to study that in detail."
S.BACK = "s_786f3cf7"         -- "I want to study something else."
S.NEVER_MIND = "s_dc63dc1a"   -- "Never mind"
S.MENU_LINE = "s_bb6caa54"
S.TRAINING_COST = 7500

S.NOVICE = "pilot_imperial_navy_novice"

function S.tierSkills(count)
	local out = {}

	for i = 1, count do
		out[i] = S.TRAIN[i].skill
	end

	return out
end

-- Appendix A
S.SCREENS = require("storm_tier1_screens_data")

function S.screenRow(id)
	for _, row in ipairs(S.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (199), sorted
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

-- The server's load: the squadron files, the Colzet template, the Colzet handler. A missing production file is recorded in
-- S.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
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

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "InquisitionSquadronScreenplay", "StormSquadronScreenplay" }) do
		-- a squadron another loader (master_trainer_imperial_data) already ran stays as it is: loading twice would register it twice
		if rawget(_G, name) == nil then
			try(name, function() H.loadSquadron(name) end)
		end
	end

	try("akal_colzet_convo.lua", function() H.loadMobile("conversations/space/imperial/storm_squadron/akal_colzet_convo.lua") end)
	try("akalColzetConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/storm_squadron/akalColzetConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function S.requireConversation(lu)
	S.load()
	lu.assertNotNil(H.conversationTemplateTable(S.TEMPLATE), S.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. table.concat(S.loadErrors, " | "))
	lu.assertNotNil(rawget(_G, S.HANDLER), S.HANDLER .. " is not defined. Load problems: " .. table.concat(S.loadErrors, " | "))
end

function S.quest(global)
	S.load()

	return H.expectGlobal(global, "Storm tier 1 quest table (storm-tier1-akal-colzet). Load problems: " .. table.concat(S.loadErrors, " | "))
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
	local id = S.IDENTITY[global]
	local key = H.questCrc(id.type, id.name)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function S.state(player, global)
	local id = S.IDENTITY[global]
	local key = H.questCrc(id.type, id.name)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

local function statusName(n) return "tatooine_imperial_" .. n end

S.STATUS_NAMES = { statusName(1), statusName(2), statusName(3), statusName(4) }

-- Options (all optional; the default is a Storm pilot with a ship, standing 0, no mission done):
--   pilot      "imperial" (default) | "neutral" | "rebel" | false (not a pilot)
--   faction    "imperial" (default) | "rebel" | "neutral" (no faction)
--   squadron   true (default: STORM_SQUADRON) | false (none) | a squadron constant
--   standing   Imperial faction standing (default 0)
--   ship       certified ship (default true)
--   paid       k: missions 1..k won, :attempted and :reward set (default 0)
--   state      the state of mission paid+1: "won" (every chain member complete, :attempted, reward unpaid) | "failed" (:attempted, nothing complete) |
--              "active" (:attempted, head chain member active) | "attempted" (just :attempted)
--   skills     list of skill names held besides the novice box; or tier = n for the first n tier 1 skills of S.TRAIN
--   tier       number of tier 1 skills (see above)
--   xp         space_combat_general experience (default 0)
--   series     the series-complete flag (SERIES_COMPLETE_KEY)
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   duty       global of a duty held active in the journal
--   species    SPECIES_* (default SPECIES_HUMAN: the fake's default 0 is not a species constant)
--   pilotTier  ghost pilot tier (default 1)
--   inventory  (default true); see H.newPlayer
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
function S.pilot(o)
	o = o or {}
	S.load()

	local pilotKind = o.pilot

	if pilotKind == nil then
		pilotKind = "imperial"
	elseif pilotKind == false then
		pilotKind = nil
	end

	local faction = ({ imperial = FACTIONIMPERIAL, rebel = FACTIONREBEL })[o.faction or "imperial"] or 0
	local squadron = o.squadron

	if squadron == nil or squadron == true then
		squadron = STORM_SQUADRON
	elseif squadron == false then
		squadron = 0
	end

	-- a non-pilot has no pilot skill, so the novice box can still be granted
	local skills = { S.NOVICE }

	if pilotKind == nil then
		skills = {}
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

		status[statusName(n) .. ":attempted"] = "1"
		status[statusName(n) .. ":reward"] = "1"
	end

	local n = paid + 1

	if o.state ~= nil and S.CHAINS[n] ~= nil then
		status[statusName(n) .. ":attempted"] = "1"

		if o.state == "won" then
			for _, g in ipairs(S.CHAINS[n]) do
				completed[#completed + 1] = crc(g)
			end
		elseif o.state == "active" then
			active[#active + 1] = crc(S.CHAINS[n][1])
		end
	end

	if o.series then
		status[S.SERIES_SUFFIX] = "1"
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
		factionStanding = { imperial = o.standing or 0, rebel = 0 },
		completedQuests = completed,
		activeQuests = active,
		questStatus = status,
		species = o.species or SPECIES_HUMAN,
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

-- Engine XP prices of the four tier 1 skills, from the SWG skills.tab excerpt (fixtures/skill/skills.pilot_imperial_navy_01.tab)
function S.useSkillCosts()
	local costs = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_imperial_navy_01.tab").records) do
		local name = rec:get("NAME")

		if name ~= nil and name:match("^pilot_imperial_navy_%a+_01$") then
			costs[name] = rec:num("XP_COST")
		end
	end

	H.Engine.config.skillXpCosts = costs

	return costs
end

function S.npc() return H.newNpc({ name = "Colzet" }) end

function S.requireConversationLoaded()
	S.load()

	if H.conversationTemplateTable(S.TEMPLATE) == nil or rawget(_G, S.HANDLER) == nil then
		error("Colzet's conversation is not loaded. Load problems: " .. table.concat(S.loadErrors, " | "), 3)
	end
end

-- Talks to Colzet from the first screen. choices as for H.converse.
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

-- Transfer forms (giveItem templates) the player's inventory got
function S.forms(player)
	local n = 0

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory and call[2] == S.TRANSFER_FORM then
			n = n + 1
		end
	end

	return n
end

return S
