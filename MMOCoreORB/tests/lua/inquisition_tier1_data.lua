-- Shared test data and builders for Inquisition tier 1 (Lt. Barn Sinkko), not a test file.
-- Spec: .claude/work/inquisition-tier1-barn-sinkko/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself:
--   I.GLOBALS / I.IDENTITY     the 8 quest globals and their class, type and name (Content contract 1)
--   I.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   I.POINTS / I.SPAWNERS      Data mapping 2: the 15 nav points and 5 spawners, Core3 x, z, y
--   I.SCREENS                  Appendix A (inquisition_tier1_screens_data.lua, generated from the spec table by a scratch script)
--   I.TRAIN                    TRAIN_CHOICES (Content contract 3, Conversation flow 3.4)
--   I.load()                   the server's load of the squadron files, the template and the handler, collecting load errors
--   I.pilot{...}               a pilot standing in front of Barn (see the option list at I.pilot)
--   I.talk / I.drive           H.converse from the first screen / from a given screen
--
-- Barn's conversation lives in the template "barn_sinkko_convo_template", its handler is the global "barnSinkkoConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")

local I = {}

I.TEMPLATE = "barn_sinkko_convo_template"
I.HANDLER = "barnSinkkoConvoHandler"
I.PREFIX = "@conversation/naboo_imperial_trainer_1:"
I.STF = "conversation/naboo_imperial_trainer_1"

I.TEMPLATE_FILE = "mobile/conversations/space/imperial/inquisition_squadron/barn_sinkko_convo.lua"
I.HANDLER_FILE = "screenplays/space/conversations/imperial/inquisition_squadron/barnSinkkoConvoHandler.lua"
I.SQUADRON_FILE = "screenplays/space/squadrons/InquisitionSquadronScreenplay.lua"
I.NPC_FILE = "mobile/space/barn_sinkko.lua"

I.P1 = "patrol_naboo_imperial_1"
I.S1 = "destroy_surpriseattack_naboo_imperial_1"
I.M2 = "destroy_naboo_imperial_2"
I.P3 = "patrol_naboo_imperial_3"
I.E3 = "escort_naboo_imperial_3"
I.A4 = "assassinate_naboo_imperial_4"
I.DUTY6 = "destroy_duty_naboo_imperial_6"
I.DUTY7 = "escort_duty_naboo_imperial_7"

I.GLOBALS = { I.P1, I.S1, I.M2, I.P3, I.E3, I.A4, I.DUTY6, I.DUTY7 }

-- global -> { class, type, name }
I.IDENTITY = {
	[I.P1] = { class = "SpacePatrolScreenplay", type = "patrol", name = "naboo_imperial_1" },
	[I.S1] = { class = "SpaceSurpriseAttackScreenplay", type = "destroy_surpriseattack", name = "naboo_imperial_1" },
	[I.M2] = { class = "SpaceDestroyScreenplay", type = "destroy", name = "naboo_imperial_2" },
	[I.P3] = { class = "SpacePatrolScreenplay", type = "patrol", name = "naboo_imperial_3" },
	[I.E3] = { class = "SpaceEscortScreenplay", type = "escort", name = "naboo_imperial_3" },
	[I.A4] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "naboo_imperial_4" },
	[I.DUTY6] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "naboo_imperial_6" },
	[I.DUTY7] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "naboo_imperial_7" },
}

-- The mission chains (head first); the story missions of the trainer
I.CHAINS = {
	{ I.P1, I.S1 },
	{ I.M2 },
	{ I.P3, I.E3 },
	{ I.A4 },
}

-- Content contract 2: the squadron object's constants
I.QUEST_STRINGS = {
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
I.ABORTED_SUFFIX = "naboo_imperial_2:aborted"

-- Data mapping 2: name -> { x, z, y }
I.POINTS = {
	imperial_1 = { -3233, -12, -6147 },
	imperial_2 = { -4446, -731, -4772 },
	imperial_3 = { -4460, -1755, -2721 },
	naboo_imperial_patrol_1 = { -2455, 2645, -3905 },
	naboo_imperial_patrol_2 = { -2946, 2568, -2486 },
	naboo_imperial_patrol_3 = { -4439, 2882, -2263 },
	naboo_imperial_patrol_4 = { -5399, 2837, -2966 },
	naboo_imperial_escort_1 = { -4917, 2794, -2026 },
	naboo_imperial_escort_2 = { -2934, 3049, -3022 },
	naboo_imperial_escort_3 = { -930, 3507, -5308 },
	naboo_imperial_escort_4 = { -5176, 3297, -6476 },
	corellia_imperial_tier3_leg_4_assassinate_one_4 = { 10, -6423, -6953 },
	corellia_imperial_tier3_leg_4_assassinate_one_3 = { -990, -4783, -4961 },
	corellia_imperial_tier3_leg_4_assassinate_one_2 = { -1972, -1677, -2951 },
	corellia_imperial_tier3_leg_4_assassinate_one_1 = { -3939, 1474, -1521 },
}

I.SPAWNERS = {
	rebel_defense_3 = { -5233, 6658, 6405 },
	rebel_generic_1 = { -172, -2813, -425 },
	rebel_cadet_1 = { -6416, -2568, -4512 },
	rebel_cadet_2 = { 4480, -4132, -6180 },
	rebel_cadet_3 = { 5492, 64, 2804 },
}

I.WOOKIEE_BANDOLIER = "object/tangible/wearables/bandolier/double_bandolier.iff"
I.ITHORIAN_BANDOLIER = "object/tangible/wearables/bandolier/ith_double_bandolier.iff"
I.TIE_SUIT = "object/tangible/wearables/bodysuit/bodysuit_tie_fighter.iff"
I.TIE_HELMET = "object/tangible/wearables/helmet/helmet_tie_fighter.iff"

local function point(name, extra)
	local p = I.POINTS[name]
	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra) do
		t[k] = v
	end

	return t
end

local function patrolPoint(name, i) return point(name, { patrolNumber = i, radius = 150 }) end
local function escortPoint(name, i) return point(name, { zoneName = "space_naboo", escortNumber = i, radius = 250 }) end

local function spawner(name)
	local s = I.SPAWNERS[name]

	return { spawnName = name, x = s[1], z = s[2], y = s[3] }
end

local TAUNTS = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }

-- global -> the whole table (Appendix B keys, Data mapping 1 values). sideQuestSplitType is SpaceQuestLogic's PATROL_POINT constant.
-- The abort override of destroy_naboo_imperial_2 is a function, not a key (see I.functionKeys).
function I.expected()
	local PATROL_POINT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT

	return {
		[I.P1] = {
			className = I.P1, questName = "naboo_imperial_1", questType = "patrol", questZone = "space_naboo",
			creditReward = 100,
			sideQuest = true, sideQuestType = "destroy_surpriseattack", sideQuestName = "naboo_imperial_1",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 2, sideQuestDelay = 10,
			patrolPoints = { patrolPoint("imperial_1", 1), patrolPoint("imperial_2", 2), patrolPoint("imperial_3", 3) },
		},
		[I.S1] = {
			className = I.S1, questName = "naboo_imperial_1", questType = "destroy_surpriseattack", questZone = "space_naboo",
			sideQuest = false, sideQuestType = "",
			parentQuest = I.P1, parentQuestType = "patrol", parentQuestName = "naboo_imperial_1",
			surpriseAttackShips = { zone = "space_naboo", spawns = { { count = 2, shipName = "reb_xwing_tier1" } } },
		},
		[I.M2] = {
			className = I.M2, questName = "naboo_imperial_2", questType = "destroy", questZone = "space_naboo",
			creditReward = 200,
			sideQuest = false, sideQuestType = "",
			killsRequired = 4,
			shipLocations = {
				spawner("rebel_defense_3"), spawner("rebel_generic_1"), spawner("rebel_cadet_1"), spawner("rebel_cadet_2"), spawner("rebel_cadet_3"),
			},
			shipTypes = { "reb_xwing_cadet_tier1" },
		},
		[I.P3] = {
			className = I.P3, questName = "naboo_imperial_3", questType = "patrol", questZone = "space_naboo",
			creditReward = 500,
			itemReward = {
				{ species = { SPECIES_WOOKIEE }, item = I.WOOKIEE_BANDOLIER },
				{ species = { SPECIES_ITHORIAN }, item = I.ITHORIAN_BANDOLIER },
				{ species = { -1 }, item = I.TIE_SUIT },
			},
			sideQuest = true, sideQuestType = "escort", sideQuestName = "naboo_imperial_3",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 3, sideQuestDelay = 20,
			patrolPoints = {
				patrolPoint("naboo_imperial_patrol_1", 1), patrolPoint("naboo_imperial_patrol_2", 2),
				patrolPoint("naboo_imperial_patrol_3", 3), patrolPoint("naboo_imperial_patrol_4", 4),
			},
		},
		[I.E3] = {
			className = I.E3, questName = "naboo_imperial_3", questType = "escort", questZone = "space_naboo",
			sideQuest = false, sideQuestType = "",
			parentQuest = I.P3, parentQuestType = "patrol", parentQuestName = "naboo_imperial_3",
			escortShips = { "imp_freighterheavy_e62_tier1" },
			escortPoints = {
				escortPoint("naboo_imperial_escort_1", 1), escortPoint("naboo_imperial_escort_2", 2),
				escortPoint("naboo_imperial_escort_3", 3), escortPoint("naboo_imperial_escort_4", 4),
			},
			attackDelay = 90,
			attackShips = { { "reb_z95_tier1", "reb_z95_tier1" }, { "reb_xwing_tier1" } },
			tauntData = TAUNTS,
		},
		[I.A4] = {
			className = I.A4, questName = "naboo_imperial_4", questType = "assassinate", questZone = "space_naboo",
			creditReward = 1000,
			itemReward = { { species = { -1 }, item = I.TIE_HELMET } },
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 15, failTimer = 20, mustDestroyEscort = false,
			assassinateSpawns = { target = "reb_xwing_leader_tier2", escorts = { "reb_xwing_tier1" } },
			targetPatrols = {
				point("corellia_imperial_tier3_leg_4_assassinate_one_4", {}),
				point("corellia_imperial_tier3_leg_4_assassinate_one_3", {}),
				point("corellia_imperial_tier3_leg_4_assassinate_one_2", {}),
				point("corellia_imperial_tier3_leg_4_assassinate_one_1", {}),
			},
		},
		[I.DUTY6] = {
			className = I.DUTY6, questName = "naboo_imperial_6", questType = "destroy_duty", questZone = "space_naboo",
			creditReward = 100,
			sideQuest = false, sideQuestType = "",
			totalLevels = 5, totalRounds = 2, totalWaves = 3,
			bossShip = "reb_xwing_tier2",
			shipTypes = { { "reb_xwing_tier1", "reb_xwing_tier1" }, { "reb_ywing_tier1", "reb_ywing_tier1" } },
		},
		[I.DUTY7] = {
			className = I.DUTY7, questName = "naboo_imperial_7", questType = "escort_duty", questZone = "space_naboo",
			creditReward = 1000, creditKillBonus = 100,
			sideQuest = false, sideQuestType = "",
			escortShips = { "freighterheavy_tier1", "freighterlight_tier1", "freightermedium_tier1", "imp_freightermedium_tier1", "imp_freighterlight_tier1", "imp_freighterheavy_tier1" },
			escortPoints = { escortPoint("imperial_1", 1), escortPoint("imperial_2", 2), escortPoint("imperial_3", 3) },
			attackDelay = 90,
			attackShips = { { "reb_z95_tier1", "reb_ywing_tier1" }, { "reb_ywing_tier1", "reb_ywing_tier1" } },
			tauntData = TAUNTS,
		},
	}
end

-- Conversation flow 3.4: TRAIN_CHOICES in table order
I.TRAIN = {
	{ x = "starships", skill = "pilot_imperial_navy_starships_01", reply = "s_5e3cf461", desc = "train_starships", trained = "trained_starships", descSid = "s_438b2349" },
	{ x = "weapons", skill = "pilot_imperial_navy_weapons_01", reply = "s_527c6359", desc = "train_weapons", trained = "trained_weapons", descSid = "s_754edf1d" },
	{ x = "procedures", skill = "pilot_imperial_navy_procedures_01", reply = "s_40f3848e", desc = "train_procedures", trained = "trained_procedures", descSid = "s_2e48b5f1" },
	{ x = "droid", skill = "pilot_imperial_navy_droid_01", reply = "s_a57e647c", desc = "train_droid", trained = "trained_droid", descSid = "s_df76b2e8" },
}

I.CONFIRM = "s_c6d9f61"       -- "I'd like to study that in detail."
I.BACK = "s_786f3cf7"         -- "I want to study something else."
I.NEVER_MIND = "s_dc63dc1a"   -- "Never mind"
I.MENU_LINE = "s_366e0c62"
I.TRAINING_COST = 7500

I.NOVICE = "pilot_imperial_navy_novice"

function I.tierSkills(count)
	local out = {}

	for i = 1, count do
		out[i] = I.TRAIN[i].skill
	end

	return out
end

-- Appendix A
I.SCREENS = require("inquisition_tier1_screens_data")

function I.screenRow(id)
	for _, row in ipairs(I.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (190), sorted
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

-- The server's load: the squadron files, the Barn template, the Barn handler. A missing production file is recorded in
-- I.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function I.load()
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

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "InquisitionSquadronScreenplay" }) do
		-- a squadron another loader (master_trainer_imperial_data) already ran stays as it is: loading twice would register it twice
		if rawget(_G, name) == nil then
			try(name, function() H.loadSquadron(name) end)
		end
	end

	try("barn_sinkko_convo.lua", function() H.loadMobile("conversations/space/imperial/inquisition_squadron/barn_sinkko_convo.lua") end)
	try("barnSinkkoConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/inquisition_squadron/barnSinkkoConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function I.requireConversation(lu)
	I.load()
	lu.assertNotNil(H.conversationTemplateTable(I.TEMPLATE), I.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. table.concat(I.loadErrors, " | "))
	lu.assertNotNil(rawget(_G, I.HANDLER), I.HANDLER .. " is not defined. Load problems: " .. table.concat(I.loadErrors, " | "))
end

function I.quest(global)
	I.load()

	return H.expectGlobal(global, "Inquisition tier 1 quest table (inquisition-tier1-barn-sinkko). Load problems: " .. table.concat(I.loadErrors, " | "))
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

local function statusName(n) return "naboo_imperial_" .. n end

I.STATUS_NAMES = { statusName(1), statusName(2), statusName(3), statusName(4) }

-- Options (all optional; the default is an Inquisition pilot with a ship, standing 0, no mission done):
--   pilot      "imperial" (default) | "neutral" | "rebel" | false (not a pilot)
--   faction    "imperial" (default) | "rebel" | "neutral" (no faction)
--   squadron   true (default: INQUISITION_SQUADRON) | false (none) | a squadron constant
--   standing   Imperial faction standing (default 0)
--   ship       certified ship (default true)
--   paid       k: missions 1..k won, :attempted and :reward set (default 0)
--   state      the state of mission paid+1: "won" (every chain member complete, :attempted, reward unpaid) | "failed" (:attempted, nothing complete) |
--              "active" (:attempted, head chain member active) | "attempted" (just :attempted) | "aborted" (mission 2 only: failed plus the :aborted key)
--   skills     list of skill names held besides the novice box; or tier = n for the first n tier 1 skills of I.TRAIN
--   tier       number of tier 1 skills (see above)
--   xp         space_combat_general experience (default 0)
--   series     the series-complete flag; agent the inquisitorial-agent flag (set by the tier 2 feature)
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   duty       global of a duty held active in the journal
--   species    SPECIES_* (default SPECIES_HUMAN: the fake's default 0 is not a species constant)
--   pilotTier  ghost pilot tier (default 1)
--   inventory  (default true)
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

	-- a non-pilot has no pilot skill, so the novice box can still be granted
	local skills = { I.NOVICE }

	if pilotKind == nil then
		skills = {}
	end

	for _, skill in ipairs(o.skills or {}) do
		skills[#skills + 1] = skill
	end

	for _, skill in ipairs(I.tierSkills(o.tier or 0)) do
		skills[#skills + 1] = skill
	end

	local paid = o.paid or 0
	local completed, active, status = {}, {}, {}

	for n = 1, paid do
		for _, g in ipairs(I.CHAINS[n]) do
			completed[#completed + 1] = crc(g)
		end

		status[statusName(n) .. ":attempted"] = "1"
		status[statusName(n) .. ":reward"] = "1"
	end

	local n = paid + 1

	if o.state ~= nil and I.CHAINS[n] ~= nil then
		status[statusName(n) .. ":attempted"] = "1"

		if o.state == "won" then
			for _, g in ipairs(I.CHAINS[n]) do
				completed[#completed + 1] = crc(g)
			end
		elseif o.state == "active" then
			active[#active + 1] = crc(I.CHAINS[n][1])
		elseif o.state == "aborted" then
			status[I.ABORTED_SUFFIX] = "1"
		end
	end

	if o.aborted then
		status[I.ABORTED_SUFFIX] = "1"
	end

	if o.series then
		status[I.SERIES_SUFFIX] = "1"
	end

	if o.agent then
		status[I.AGENT_SUFFIX] = "1"
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
function I.useSkillCosts()
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

function I.npc() return H.newNpc({ name = "Barn" }) end

function I.requireConversationLoaded()
	I.load()

	if H.conversationTemplateTable(I.TEMPLATE) == nil or rawget(_G, I.HANDLER) == nil then
		error("Barn's conversation is not loaded. Load problems: " .. table.concat(I.loadErrors, " | "), 3)
	end
end

-- Talks to Barn from the first screen. choices as for H.converse.
function I.talk(player, choices)
	I.requireConversationLoaded()

	return H.converse({ template = I.TEMPLATE, player = player, npc = I.npc(), choices = choices })
end

-- The id of the first screen of a fresh talk
function I.firstScreen(player)
	return I.talk(player)[1].id
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

-- Skills (of the four) the player holds, in I.TRAIN order
function I.held(player)
	local out = {}

	for _, t in ipairs(I.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

return I
