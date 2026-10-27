-- Shared test data and builders for Black Epsilon tier 1 (Hakassha Sireen), not a test file.
-- Spec: .claude/work/black-epsilon-tier1-hakassha/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself:
--   B.GLOBALS / B.IDENTITY     the 7 quest globals and their class, type and name (Content contract 1)
--   B.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   B.POINTS / B.SPAWNERS      Data mapping 2: the 15 nav points and 4 spawners, Core3 x, z, y
--   B.SCREENS                  Appendix A (black_epsilon_tier1_screens_data.lua, generated from the spec table)
--   B.TRAIN                    TRAIN_CHOICES (Content contract 3, Conversation flow 3.4)
--   B.load()                   the server's load of the squadron, the template and the handler, collecting load errors
--   B.pilot{...}               a pilot standing in front of Hakassha (see the option list at B.pilot)
--   B.talk / B.drive           H.converse from the first screen / from a given screen
--
-- Hakassha's conversation lives in the template "hakassha_convo_template", its handler is the global "hakasshaConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")

local B = {}

B.TEMPLATE = "hakassha_convo_template"
B.HANDLER = "hakasshaConvoHandler"
B.PREFIX = "@conversation/corellia_imperial_trainer_1:"
B.STF = "conversation/corellia_imperial_trainer_1"

B.TEMPLATE_FILE = "mobile/conversations/space/imperial/black_epsilon_squadron/hakassha_convo.lua"
B.HANDLER_FILE = "screenplays/space/conversations/imperial/black_epsilon_squadron/hakasshaConvoHandler.lua"
B.SQUADRON_FILE = "screenplays/space/squadrons/BlackEpsilonSquadronScreenplay.lua"
B.NPC_FILE = "mobile/space/hakassha_sireen.lua"

B.P1 = "patrol_corellia_imperial_1"
B.S1 = "destroy_surpriseattack_corellia_imperial_1"
B.M2 = "destroy_corellia_imperial_2"
B.E3 = "escort_corellia_imperial_3"
B.A4 = "assassinate_corellia_imperial_4"
B.DUTY6 = "destroy_duty_corellia_imperial_6"
B.DUTY7 = "escort_duty_corellia_imperial_7"

B.GLOBALS = { B.P1, B.S1, B.M2, B.E3, B.A4, B.DUTY6, B.DUTY7 }

-- global -> { class, type, name }
B.IDENTITY = {
	[B.P1] = { class = "SpacePatrolScreenplay", type = "patrol", name = "corellia_imperial_1" },
	[B.S1] = { class = "SpaceSurpriseAttackScreenplay", type = "destroy_surpriseattack", name = "corellia_imperial_1" },
	[B.M2] = { class = "SpaceDestroyScreenplay", type = "destroy", name = "corellia_imperial_2" },
	[B.E3] = { class = "SpaceEscortScreenplay", type = "escort", name = "corellia_imperial_3" },
	[B.A4] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "corellia_imperial_4" },
	[B.DUTY6] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "corellia_imperial_6" },
	[B.DUTY7] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "corellia_imperial_7" },
}

-- The mission chains (head first); the story missions of the trainer
B.CHAINS = {
	{ B.P1, B.S1 },
	{ B.M2 },
	{ B.E3 },
	{ B.A4 },
}

-- Content contract 2: the squadron object's constants
B.QUEST_STRINGS = {
	QUEST_STRING_1 = { type = "patrol", name = "corellia_imperial_1" },
	QUEST_STRING_1_SIDE = { type = "destroy_surpriseattack", name = "corellia_imperial_1" },
	QUEST_STRING_2 = { type = "destroy", name = "corellia_imperial_2" },
	QUEST_STRING_3 = { type = "escort", name = "corellia_imperial_3" },
	QUEST_STRING_4 = { type = "assassinate", name = "corellia_imperial_4" },
	QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "corellia_imperial_6" },
	QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "corellia_imperial_7" },
}

B.SERIES_SUFFIX = "BlackEpsilonSquadronScreenplay:imperial_corellia_1"
B.PRISK_SUFFIX = "BlackEpsilonSquadronScreenplay:workingForPrisk"

-- Data mapping 2: name -> { x, z, y }
B.POINTS = {
	imperial_1 = { -5118, -4117, -3503 },
	imperial_2 = { -4092, -3236, -2990 },
	imperial_3 = { -2643, -1615, -4452 },
	corellia_imperial_escort_1 = { -6694, -2683, -1033 },
	corellia_imperial_escort_2 = { -4477, -2449, -2489 },
	corellia_imperial_escort_3 = { -3439, -2699, -4986 },
	corellia_imperial_escort_4 = { -6967, -2534, -7084 },
	corellia_imperial_tier2_assassinate_5 = { 3102, 2928, -6841 },
	corellia_imperial_tier2_assassinate_4 = { 15, 877, -7202 },
	corellia_imperial_tier2_assassinate_3 = { -2854, -236, -6778 },
	corellia_imperial_tier2_assassinate_2 = { -5275, -1116, -6269 },
	military_escort_1 = { 5287, 5844, 5700 },
	military_escort_2 = { 2915, 3828, 2887 },
	military_escort_3 = { 4405, 2619, -1971 },
	military_escort_4 = { 4860, 407, -4843 },
}

B.SPAWNERS = {
	rebel_corellia_deep_two_spawner = { -6118, -3233, -2733 },
	rebel_fighter_four_spawner = { 3475, -7014, -6208 },
	rebel_fighter_two_spawner = { -3936, 2704, 2172 },
	rebel_spacestation_spawner = { -959, -5, -1328 },
}

B.WOOKIEE_BANDOLIER = "object/tangible/wearables/bandolier/double_bandolier.iff"
B.ITHORIAN_BANDOLIER = "object/tangible/wearables/bandolier/ith_double_bandolier.iff"
B.TIE_SUIT = "object/tangible/wearables/bodysuit/bodysuit_tie_fighter.iff"
B.TIE_HELMET = "object/tangible/wearables/helmet/helmet_tie_fighter.iff"

local function point(name, number, extra)
	local p = B.POINTS[name]
	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra) do
		t[k] = v
	end

	return t
end

local function patrolPoint(name, i) return point(name, i, { patrolNumber = i, radius = 150 }) end
local function escortPoint(name, i) return point(name, i, { zoneName = "space_corellia", escortNumber = i, radius = 250 }) end

local function spawner(name)
	local s = B.SPAWNERS[name]

	return { spawnName = name, x = s[1], z = s[2], y = s[3] }
end

-- global -> the whole table (Appendix B keys, Data mapping 1 values). sideQuestSplitType is SpaceQuestLogic's PATROL_POINT constant.
function B.expected()
	local PATROL_POINT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT

	return {
		[B.P1] = {
			className = B.P1, questName = "corellia_imperial_1", questType = "patrol", questZone = "space_corellia",
			creditReward = 100,
			sideQuest = true, sideQuestType = "destroy_surpriseattack", sideQuestName = "corellia_imperial_1",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 2, sideQuestDelay = 10,
			patrolPoints = { patrolPoint("imperial_1", 1), patrolPoint("imperial_2", 2), patrolPoint("imperial_3", 3) },
		},
		[B.S1] = {
			className = B.S1, questName = "corellia_imperial_1", questType = "destroy_surpriseattack", questZone = "space_corellia",
			sideQuest = false, sideQuestType = "",
			parentQuest = B.P1, parentQuestType = "patrol", parentQuestName = "corellia_imperial_1",
			surpriseAttackShips = { zone = "space_corellia", spawns = { { count = 2, shipName = "reb_xwing_tier1" } } },
		},
		[B.M2] = {
			className = B.M2, questName = "corellia_imperial_2", questType = "destroy", questZone = "space_corellia",
			creditReward = 200,
			sideQuest = false, sideQuestType = "",
			killsRequired = 4,
			shipLocations = {
				spawner("rebel_corellia_deep_two_spawner"), spawner("rebel_fighter_four_spawner"),
				spawner("rebel_fighter_two_spawner"), spawner("rebel_spacestation_spawner"),
			},
			shipTypes = { "reb_xwing_cadet_tier1" },
		},
		[B.E3] = {
			className = B.E3, questName = "corellia_imperial_3", questType = "escort", questZone = "space_corellia",
			creditReward = 500,
			itemReward = {
				{ species = { SPECIES_WOOKIEE }, item = B.WOOKIEE_BANDOLIER },
				{ species = { SPECIES_ITHORIAN }, item = B.ITHORIAN_BANDOLIER },
				{ species = { -1 }, item = B.TIE_SUIT },
			},
			sideQuest = false, sideQuestType = "",
			escortShips = { "imp_freightermedium_explosives_tier1" },
			escortPoints = {
				escortPoint("corellia_imperial_escort_1", 1), escortPoint("corellia_imperial_escort_2", 2),
				escortPoint("corellia_imperial_escort_3", 3), escortPoint("corellia_imperial_escort_4", 4),
			},
			attackDelay = 90,
			attackShips = { { "reb_corsec_fighter_tier1", "reb_corsec_fighter_tier1" }, { "reb_corsec_fighter_tier1" } },
			tauntData = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 },
		},
		[B.A4] = {
			className = B.A4, questName = "corellia_imperial_4", questType = "assassinate", questZone = "space_corellia",
			creditReward = 1000,
			itemReward = { { species = { -1 }, item = B.TIE_HELMET } },
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 15, failTimer = 20, mustDestroyEscort = false,
			assassinateSpawns = { target = "reb_bwing_prototype_tier2", escorts = { "reb_xwing_tier1" } },
			targetPatrols = {
				{ patrolPointName = "corellia_imperial_tier2_assassinate_5", x = 3102, z = 2928, y = -6841 },
				{ patrolPointName = "corellia_imperial_tier2_assassinate_4", x = 15, z = 877, y = -7202 },
				{ patrolPointName = "corellia_imperial_tier2_assassinate_3", x = -2854, z = -236, y = -6778 },
				{ patrolPointName = "corellia_imperial_tier2_assassinate_2", x = -5275, z = -1116, y = -6269 },
			},
		},
		[B.DUTY6] = {
			className = B.DUTY6, questName = "corellia_imperial_6", questType = "destroy_duty", questZone = "space_corellia",
			creditReward = 100,
			sideQuest = false, sideQuestType = "",
			totalLevels = 5, totalRounds = 2, totalWaves = 3,
			bossShip = "reb_bwing_prototype_tier2",
			shipTypes = { { "reb_bwing_tier1" } },
		},
		[B.DUTY7] = {
			className = B.DUTY7, questName = "corellia_imperial_7", questType = "escort_duty", questZone = "space_corellia",
			creditReward = 1000, creditKillBonus = 100,
			sideQuest = false, sideQuestType = "",
			escortShips = { "imp_freighterheavy_tier1", "imp_freightermedium_tier1", "imp_freighterlight_tier1" },
			escortPoints = {
				escortPoint("military_escort_1", 1), escortPoint("military_escort_2", 2),
				escortPoint("military_escort_3", 3), escortPoint("military_escort_4", 4),
			},
			attackDelay = 120,
			attackShips = { { "reb_xwing_tier1", "reb_ywing_tier1" } },
			tauntData = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 },
		},
	}
end

-- Conversation flow 3.4: TRAIN_CHOICES in table order
B.TRAIN = {
	{ x = "starships", skill = "pilot_imperial_navy_starships_01", reply = "s_5e3cf461", desc = "train_starships", trained = "trained_starships", descSid = "s_438b2349" },
	{ x = "weapons", skill = "pilot_imperial_navy_weapons_01", reply = "s_577aca95", desc = "train_weapons", trained = "trained_weapons", descSid = "s_a4c65e0b" },
	{ x = "procedures", skill = "pilot_imperial_navy_procedures_01", reply = "s_fb13007f", desc = "train_procedures", trained = "trained_procedures", descSid = "s_2e48b5f1" },
	{ x = "droid", skill = "pilot_imperial_navy_droid_01", reply = "s_a57e647c", desc = "train_droid", trained = "trained_droid", descSid = "s_df76b2e8" },
}

B.CONFIRM = "s_c6d9f61"       -- "I'd like to study that in detail."
B.BACK = "s_786f3cf7"         -- "I want to study something else."
B.NEVER_MIND = "s_dc63dc1a"   -- "Never mind"
B.TRAINING_COST = 7500

B.NOVICE = "pilot_imperial_navy_novice"

function B.tierSkills(count)
	local out = {}

	for i = 1, count do
		out[i] = B.TRAIN[i].skill
	end

	return out
end

-- Appendix A
B.SCREENS = require("black_epsilon_tier1_screens_data")

function B.screenRow(id)
	for _, row in ipairs(B.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (161), sorted
function B.screenIds()
	local out = {}

	for i, row in ipairs(B.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

B.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		B.loadErrors[#B.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: the four squadron files, the Hakassha template, the Hakassha handler. A missing production file is recorded in
-- B.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function B.load()
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

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay" }) do
		try(name, function() H.loadSquadron(name) end)
	end

	try("hakassha_convo.lua", function() H.loadMobile("conversations/space/imperial/black_epsilon_squadron/hakassha_convo.lua") end)
	try("hakasshaConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/black_epsilon_squadron/hakasshaConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function B.requireConversation(lu)
	B.load()
	lu.assertNotNil(H.conversationTemplateTable(B.TEMPLATE), B.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. table.concat(B.loadErrors, " | "))
	lu.assertNotNil(rawget(_G, B.HANDLER), B.HANDLER .. " is not defined. Load problems: " .. table.concat(B.loadErrors, " | "))
end

function B.quest(global)
	B.load()

	return H.expectGlobal(global, "Black Epsilon tier 1 quest table (black-epsilon-tier1-hakassha). Load problems: " .. table.concat(B.loadErrors, " | "))
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = B.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

B.crc = crc

-- Quest state helpers on a built pilot. state: "complete" | "active" | "none"
function B.setState(player, global, state)
	local id = B.IDENTITY[global]
	local key = H.questCrc(id.type, id.name)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function B.state(player, global)
	local id = B.IDENTITY[global]
	local key = H.questCrc(id.type, id.name)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

local function statusName(n) return "corellia_imperial_" .. n end

B.STATUS_NAMES = { statusName(1), statusName(2), statusName(3), statusName(4) }

-- Options (all optional; the default is a Black Epsilon pilot with a ship, standing 0, no mission done):
--   pilot      "imperial" (default) | "neutral" | "rebel" | false (not a pilot)
--   faction    "imperial" (default) | "rebel" | "neutral" (no faction)
--   squadron   true (default: BLACK_EPSILON_SQUADRON) | false (none) | a squadron constant
--   standing   Imperial faction standing (default 0)
--   ship       certified ship (default true)
--   paid       k: missions 1..k won, :attempted and :reward set (default 0)
--   state      the state of mission paid+1: "won" (complete, :attempted, reward unpaid) | "failed" (:attempted, nothing complete) |
--              "active" (:attempted, head chain member active) | "attempted" (just :attempted)
--   skills     list of skill names held besides the novice box; or tier = n for the first n tier 1 skills of B.TRAIN
--   tier       number of tier 1 skills (see above)
--   xp         space_combat_general experience (default 0)
--   series     the series-complete flag; prisk the Prisk flag
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   duty       global of a duty held active in the journal
--   species    SPECIES_* (default SPECIES_HUMAN: the fake's default 0 is not a species constant)
--   pilotTier  ghost pilot tier (default 1)
--   inventory  (default true)
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
function B.pilot(o)
	o = o or {}
	B.load()

	local pilotKind = o.pilot

	if pilotKind == nil then
		pilotKind = "imperial"
	elseif pilotKind == false then
		pilotKind = nil
	end

	local faction = ({ imperial = FACTIONIMPERIAL, rebel = FACTIONREBEL })[o.faction or "imperial"] or 0
	local squadron = o.squadron

	if squadron == nil or squadron == true then
		squadron = BLACK_EPSILON_SQUADRON
	elseif squadron == false then
		squadron = 0
	end

	-- a non-pilot has no pilot skill, so the novice box can still be granted
	local skills = { B.NOVICE }

	if pilotKind == nil then
		skills = {}
	end

	for _, skill in ipairs(o.skills or {}) do
		skills[#skills + 1] = skill
	end

	for _, skill in ipairs(B.tierSkills(o.tier or 0)) do
		skills[#skills + 1] = skill
	end

	local paid = o.paid or 0
	local completed, active, status = {}, {}, {}

	for n = 1, paid do
		for _, g in ipairs(B.CHAINS[n]) do
			completed[#completed + 1] = crc(g)
		end

		status[statusName(n) .. ":attempted"] = "1"
		status[statusName(n) .. ":reward"] = "1"
	end

	local n = paid + 1

	if o.state ~= nil and B.CHAINS[n] ~= nil then
		status[statusName(n) .. ":attempted"] = "1"

		if o.state == "won" then
			for _, g in ipairs(B.CHAINS[n]) do
				completed[#completed + 1] = crc(g)
			end
		elseif o.state == "active" then
			active[#active + 1] = crc(B.CHAINS[n][1])
		end
	end

	if o.series then
		status[B.SERIES_SUFFIX] = "1"
	end

	if o.prisk then
		status[B.PRISK_SUFFIX] = "1"
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
function B.useSkillCosts()
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

function B.npc() return H.newNpc({ name = "Hakassha" }) end

-- Talks to Hakassha from the first screen. choices as for H.converse.
function B.talk(player, choices)
	B.requireConversationLoaded()

	return H.converse({ template = B.TEMPLATE, player = player, npc = B.npc(), choices = choices })
end

function B.requireConversationLoaded()
	B.load()

	if H.conversationTemplateTable(B.TEMPLATE) == nil or rawget(_G, B.HANDLER) == nil then
		error("Hakassha conversation is not loaded. Load problems: " .. table.concat(B.loadErrors, " | "), 3)
	end
end

-- The id of the first screen of a fresh talk
function B.firstScreen(player)
	return B.talk(player)[1].id
end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session.
function B.drive(player, startId, choices)
	B.requireConversationLoaded()

	local tmpl = H.conversationTemplate(B.TEMPLATE)
	local handler = rawget(_G, B.HANDLER)
	local npc = B.npc()
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
		error("screen '" .. startId .. "' is not in " .. B.TEMPLATE, 2)
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
function B.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- the option sids ("s_xxx") of a transcript step, in order
function B.optionSids(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = tostring(o.text):match(":(s_[%w_]+)$") or tostring(o.text)
	end

	return out
end

function B.linksOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = o.link
	end

	return out
end

function B.free() return H.Engine.callsTo("awardSkill") end
function B.bought() return H.Engine.callsTo("skillManagerAwardSkill") end

-- Skills (of the four) the player holds, in B.TRAIN order
function B.held(player)
	local out = {}

	for _, t in ipairs(B.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

return B
