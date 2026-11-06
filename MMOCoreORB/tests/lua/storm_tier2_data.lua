-- Shared test data and builders for Storm Squadron tier 2 part 1 (Commander Jhon Oberhaur), not a test file.
-- Spec: .claude/work/storm-tier2-oberhaur/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself:
--   T.GLOBALS / T.IDENTITY     the 6 quest globals and their class, type and name (Content contract 1)
--   T.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   T.POINTS                   Data mapping 2: the 28 nav points, Core3 x, z, y
--   T.SCREENS                  Appendix A (storm_tier2_screens_data.lua, generated from the spec table by a scratch script)
--   T.TRAIN                    TRAIN_CHOICES (Conversation flow 3.4)
--   T.load()                   the server's load of the squadron files, the template and the handler, collecting load errors, and the
--                              harness fakes of the form menu (harness/form_fakes.lua)
--   T.pilot{...}               a pilot standing in front of Oberhaur (see the option list at T.pilot)
--   T.talk / T.drive           H.converse from the first screen / from a given screen
--
-- Oberhaur's conversation lives in the template "oberhaur_convo_template", its handler is the global "oberhaurConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")
local FF = require("harness.form_fakes")

local T = {}

T.TEMPLATE = "oberhaur_convo_template"
T.HANDLER = "oberhaurConvoHandler"
T.PREFIX = "@conversation/tatooine_imperial_trainer_2:"
T.STF = "conversation/tatooine_imperial_trainer_2"

T.TEMPLATE_FILE = "mobile/conversations/space/imperial/storm_squadron/oberhaur_convo.lua"
T.HANDLER_FILE = "screenplays/space/conversations/imperial/storm_squadron/oberhaurConvoHandler.lua"
T.SQUADRON_FILE = "screenplays/space/squadrons/StormSquadronScreenplay.lua"
T.NPC_FILE = "mobile/space/oberhaur.lua"
T.FORM_OBJECT_FILE = "object/tangible/space/mission_objects/transfer_auth.lua"

T.M1 = "inspect_imperial_ss_1"
T.M2 = "recovery_imperial_ss_2"
T.M3 = "assassinate_imperial_ss_3"
T.DUTY1 = "destroy_duty_lok_imperial_ss_1a"
T.DUTY2 = "recovery_duty_lok_imperial_ss_1b"
T.DUTY3 = "escort_duty_lok_imperial_ss_1c"

T.GLOBALS = { T.M1, T.M2, T.M3, T.DUTY1, T.DUTY2, T.DUTY3 }
T.MISSIONS = { T.M1, T.M2, T.M3 }
T.DUTIES = { T.DUTY1, T.DUTY2, T.DUTY3 }

-- The tier 1 globals (they register before the tier 2 globals)
T.TIER1_GLOBALS = {
	"patrol_tatooine_imperial_1", "destroy_surpriseattack_tatooine_imperial_1", "destroy_tatooine_imperial_2", "patrol_tatooine_imperial_3",
	"escort_tatooine_imperial_3", "assassinate_tatooine_imperial_4", "destroy_duty_tatooine_imperial_6", "escort_duty_tatooine_imperial_7",
}

-- global -> { class, type, name, zone }
T.IDENTITY = {
	[T.M1] = { class = "SpaceInspectScreenplay", type = "inspect", name = "imperial_ss_1", zone = "space_lok" },
	[T.M2] = { class = "SpaceRecoveryScreenplay", type = "recovery", name = "imperial_ss_2", zone = "space_lok" },
	[T.M3] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "imperial_ss_3", zone = "space_lok" },
	[T.DUTY1] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "lok_imperial_ss_1a", zone = "space_lok" },
	[T.DUTY2] = { class = "SpaceDutyRecoveryScreenplay", type = "recovery_duty", name = "lok_imperial_ss_1b", zone = "space_lok" },
	[T.DUTY3] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "lok_imperial_ss_1c", zone = "space_lok" },
}

-- Content contract 2: the squadron object's constants
T.QUEST_STRINGS = {
	TIER2_QUEST_STRING_1 = { type = "inspect", name = "imperial_ss_1" },
	TIER2_QUEST_STRING_2 = { type = "recovery", name = "imperial_ss_2" },
	TIER2_QUEST_STRING_3 = { type = "assassinate", name = "imperial_ss_3" },
	TIER2_QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "lok_imperial_ss_1a" },
	TIER2_QUEST_STRING_DUTY_2 = { type = "recovery_duty", name = "lok_imperial_ss_1b" },
	TIER2_QUEST_STRING_DUTY_3 = { type = "escort_duty", name = "lok_imperial_ss_1c" },
}

-- The tier 1 fields must stay as they are (AC-1)
T.TIER1_QUEST_STRINGS = {
	QUEST_STRING_1 = { type = "patrol", name = "tatooine_imperial_1" },
	QUEST_STRING_1_SIDE = { type = "destroy_surpriseattack", name = "tatooine_imperial_1" },
	QUEST_STRING_2 = { type = "destroy", name = "tatooine_imperial_2" },
	QUEST_STRING_3 = { type = "patrol", name = "tatooine_imperial_3" },
	QUEST_STRING_3_SIDE = { type = "escort", name = "tatooine_imperial_3" },
	QUEST_STRING_4 = { type = "assassinate", name = "tatooine_imperial_4" },
	QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "tatooine_imperial_6" },
	QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "tatooine_imperial_7" },
}

T.SERIES_SUFFIX = "StormSquadronScreenplay:imperial_tatooine_1"
T.INITIATE_SUFFIX = "StormSquadronScreenplay:stormSquadronInitiate"
T.FINDING_SUFFIX = "StormSquadronScreenplay:findingAgent"
T.ALOZEN_SUFFIX = "StormSquadronScreenplay:workingWithAlozen"
T.FLAG_SUFFIXES = { T.INITIATE_SUFFIX, T.FINDING_SUFFIX, T.ALOZEN_SUFFIX }
T.TRANSFER_FORM = "object/tangible/space/mission_objects/transfer_auth.iff"
T.SIGNATURE_KEY = "signature"

-- Status names of the three missions: "<playerID>imperial_ss_<n>:attempted" / ":reward"
local function statusName(n) return "imperial_ss_" .. n end

T.STATUS = { statusName(1), statusName(2), statusName(3) }

-- Every status key (suffix after the player id) the reset removes: :attempted and :reward for the three missions
function T.statusKeys()
	local out = {}

	for n = 1, 3 do
		out[#out + 1] = statusName(n) .. ":attempted"
		out[#out + 1] = statusName(n) .. ":reward"
	end

	return out
end

-- Data mapping 2: name -> { x, z, y } (Core3 x, z, y = patrol point file = buildout fltPX, fltPY, fltPZ truncated)
T.POINTS = {
	hostage_escort_1 = { -5448, 800, 2992 },
	hostage_escort_2 = { -5951, 1295, 1027 },
	hostage_escort_3 = { -4948, 1612, -1763 },
	hostage_escort_4 = { -3993, 2074, -3667 },
	hostage_escort_5 = { -3467, 2588, -6633 },
	hostage_recovery_1 = { -2930, 2690, -4742 },
	hostage_recovery_2 = { -5561, 2135, -4973 },
	hostage_recovery_3 = { -6832, 2296, -3612 },
	hostage_recovery_4 = { -6637, 2449, -2060 },
	hostage_recovery_5 = { -5082, 2428, -476 },
	lok_imp_pirate_1 = { -3200, -400, 3000 },
	lok_imp_pirate_2 = { -2167, -767, 2211 },
	lok_imp_pirate_3 = { -1493, -978, 1680 },
	lok_imp_pirate_4 = { -759, -1583, 1233 },
	lok_imp_pirate_5 = { 419, -2240, 594 },
	lok_imp_pirate_6 = { 738, -1579, -310 },
	lok_imp_recovery_1 = { 1779, 289, -1042 },
	lok_imp_recovery_2 = { 2371, 588, -251 },
	lok_imp_recovery_3 = { 2037, -71, 478 },
	lok_imp_recovery_4 = { 1411, -1579, 134 },
	lok_imp_recovery_5 = { 385, -843, 254 },
	lok_imp_recovery_6 = { -477, -150, 421 },
	lok_imp_escort_duty_1 = { 2700, 200, 2700 },
	lok_imp_escort_duty_2 = { 1927, 285, 1901 },
	lok_imp_escort_duty_3 = { 1564, 970, 1211 },
	lok_imp_escort_duty_4 = { 814, 429, 1053 },
	lok_imp_escort_duty_5 = { 122, -365, -407 },
	lok_imp_escort_duty_6 = { -571, -1090, -1672 },
}

-- Core3 patrol point row numbers of the spec (PPL), for the "points resolve" test
T.ITEM_ROOT = "object/tangible/ship/components/"

T.ITEMS = {
	[T.M1] = T.ITEM_ROOT .. "weapon/wpn_mission_reward_imperial_cygnus_starblaster.iff",
	[T.M2] = T.ITEM_ROOT .. "armor/arm_mission_reward_imperial_sfs_light_military.iff",
	[T.M3] = T.ITEM_ROOT .. "booster/bst_mission_reward_imperial_rss_ion_booster.iff",
}

T.CREDITS = 5000
T.STANDING = 75

local function point(name, extra)
	local p = T.POINTS[name]
	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra or {}) do
		t[k] = v
	end

	return t
end

-- recovery path: escortNumber = i (renumbered from 1), radius 250, no zoneName
local function recoveryPath(prefix, count)
	local out = {}

	for i = 1, count do
		out[i] = point(prefix .. i, { escortNumber = i, radius = 250 })
	end

	return out
end

local function escortDutyPath(prefix, count)
	local out = {}

	for i = 1, count do
		out[i] = point(prefix .. i, { zoneName = "space_lok", escortNumber = i, radius = 250 })
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

local function reward(global) return { { species = { -1 }, item = T.ITEMS[global] } } end

local TAUNTS_RECOVERY = { panicCount = 5, thanksCount = 5 }
local TAUNTS_ESCORT = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function T.expected()
	return {
		[T.M1] = {
			className = T.M1, questName = "imperial_ss_1", questType = "inspect", questZone = "space_lok",
			creditReward = T.CREDITS, itemReward = reward(T.M1),
			sideQuest = false, sideQuestType = "",
			shipList = { "nym_lieutenant_tier2" },
			validSpawns = {},
			giveSpawnWaypoint = 0,
			cargo = "hostage_orders",
		},
		[T.M2] = {
			className = T.M2, questName = "imperial_ss_2", questType = "recovery", questZone = "space_lok",
			creditReward = T.CREDITS, itemReward = reward(T.M2),
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 15, recoveryDelay = 30,
			recoverShip = "nym_prison_ship_tier2",
			recoveryConversationMobile = "object/mobile/shared_space_comm_imperial_officer_01.iff",
			escortShips = repeated("nym_enforcer_tier2", 3),
			preRecoveryPoints = recoveryPath("hostage_escort_", 5),
			recoveryPoints = recoveryPath("hostage_recovery_", 5),
			attackDelay = 120,
			attackShips = { { "nym_fighter_tier2", "nym_fighter_tier2" }, { "nym_bomber_tier2", "nym_enforcer_tier2" } },
			tauntData = TAUNTS_RECOVERY,
		},
		[T.M3] = {
			className = T.M3, questName = "imperial_ss_3", questType = "assassinate", questZone = "space_lok",
			creditReward = T.CREDITS, itemReward = reward(T.M3),
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 30, failTimer = 20, mustDestroyEscort = true,
			assassinateSpawns = { target = "nym_capo_ship_tier2", escorts = repeated("nym_enforcer_tier2", 3) },
			targetPatrols = {
				point("hostage_escort_1"), point("hostage_escort_2"), point("hostage_escort_3"), point("hostage_escort_4"), point("hostage_escort_5"),
			},
		},
		[T.DUTY1] = {
			className = T.DUTY1, questName = "lok_imperial_ss_1a", questType = "destroy_duty", questZone = "space_lok",
			creditReward = 200,
			sideQuest = false, sideQuestType = "",
			totalLevels = 5, totalRounds = 2, totalWaves = 3,
			bossShip = "nym_fighter_tier3",
			shipTypes = { repeated("nym_fighter_tier2", 2), repeated("nym_enforcer_tier2", 2), repeated("nym_blastboat_tier2", 2) },
		},
		[T.DUTY2] = {
			className = T.DUTY2, questName = "lok_imperial_ss_1b", questType = "recovery_duty", questZone = "space_lok",
			creditReward = 2500, creditKillBonus = 200, numResponses = 5,
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 30, recoveryDelay = 30,
			recoverShips = { "nym_freighterheavy_tier2", "nym_freighterlight_tier2", "nym_freightermedium_tier2" },
			escortShips = repeated("nym_enforcer_tier2", 3),
			preRecoveryPoints = recoveryPath("lok_imp_pirate_", 6),
			recoveryPoints = recoveryPath("lok_imp_recovery_", 6),
			attackDelay = 90,
			attackShips = { { "nym_fighter_tier2", "nym_fighter_tier2" }, { "nym_bomber_tier2", "nym_blastboat_tier2" } },
			tauntData = TAUNTS_RECOVERY,
		},
		[T.DUTY3] = {
			className = T.DUTY3, questName = "lok_imperial_ss_1c", questType = "escort_duty", questZone = "space_lok",
			creditReward = 2500, creditKillBonus = 200,
			sideQuest = false, sideQuestType = "",
			escortShips = { "imp_freightermedium_tier2", "imp_freighterlight_tier2", "imp_freighterheavy_tier2" },
			escortPoints = escortDutyPath("lok_imp_escort_duty_", 6),
			attackDelay = 120,
			attackShips = { { "nym_fighter_tier2", "nym_fighter_tier2" }, { "nym_enforcer_tier2", "nym_enforcer_tier2" } },
			tauntData = TAUNTS_ESCORT,
		},
	}
end

-- Conversation flow 3.4: TRAIN_CHOICES in table order (skill order of J2 canBuySkill1A..1D)
T.TRAIN = {
	{ x = "starships", skill = "pilot_imperial_navy_starships_02", reply = "s_594a07fa", trained = "trained_starships", trainedSid = "s_486da900" },
	{ x = "weapons", skill = "pilot_imperial_navy_weapons_02", reply = "s_dbb5bf46", trained = "trained_weapons", trainedSid = "s_8bd72bb5" },
	{ x = "procedures", skill = "pilot_imperial_navy_procedures_02", reply = "s_e73e5d21", trained = "trained_procedures", trainedSid = "s_c4880407" },
	{ x = "droid", skill = "pilot_imperial_navy_droid_02", reply = "s_c76594d7", trained = "trained_droid", trainedSid = "s_31804e15" },
}

T.TIER1_SKILLS = {
	"pilot_imperial_navy_starships_01", "pilot_imperial_navy_weapons_01", "pilot_imperial_navy_procedures_01", "pilot_imperial_navy_droid_01",
}

T.NOVICE = "pilot_imperial_navy_novice"
T.TRAINING_COST = 60000
T.LATER = "s_ae26c22"            -- "Let me think about this for a bit."
T.THANK_YOU = "s_987445c9"       -- "Thank you, sir."
T.READY_FOR_TRAINING = "s_b0d3b474"  -- "I'm ready for training." (duty menu)
T.DUTY_MENU_REPLY = "s_ac71da57"     -- "I'm ready to take an assignment."
T.FULL_NAME = "Ace Starfire"
T.FIRST_NAME = "Ace"

-- Appendix A
T.SCREENS = require("storm_tier2_screens_data")

function T.screenRow(id)
	for _, row in ipairs(T.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (113), sorted
function T.screenIds()
	local out = {}

	for i, row in ipairs(T.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- The reply sids from `from` to `to` over the static options of Appendix A (breadth-first, in option order); nil when there is none.
-- `avoid` (set of screen ids) are never entered. Returns replies, ids (the screens shown, `from` first).
function T.walkTo(from, to, avoid)
	local queue, seen = { { id = from, replies = {}, ids = { from } } }, { [from] = true }

	while #queue > 0 do
		local cur = table.remove(queue, 1)

		if cur.id == to then
			return cur.replies, cur.ids
		end

		for _, o in ipairs(T.screenRow(cur.id).options) do
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

T.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		T.loadErrors[#T.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: every squadron file, Oberhaur's template and handler, the harness fakes of the form menu. A missing production file is recorded
-- in T.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function T.load()
	if loaded then
		return
	end

	loaded = true
	H.boot()
	FF.install()

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

	try("oberhaur_convo.lua", function() H.loadMobile("conversations/space/imperial/storm_squadron/oberhaur_convo.lua") end)
	try("oberhaurConvoHandler.lua", function() H.loadScreenplay("space/conversations/imperial/storm_squadron/oberhaurConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function T.requireConversation(lu)
	T.load()
	lu.assertNotNil(H.conversationTemplateTable(T.TEMPLATE), T.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. table.concat(T.loadErrors, " | "))
	lu.assertNotNil(rawget(_G, T.HANDLER), T.HANDLER .. " is not defined. Load problems: " .. table.concat(T.loadErrors, " | "))
end

function T.quest(global)
	T.load()

	return H.expectGlobal(global, "Storm tier 2 quest table (storm-tier2-oberhaur). Load problems: " .. table.concat(T.loadErrors, " | "))
end

-- The squadron object, with a readable red when the file does not define it
function T.squadron()
	T.load()

	return H.expectGlobal("StormSquadronScreenplay", "squadron screenplay object. Load problems: " .. table.concat(T.loadErrors, " | "))
end

-- The form menu component, with a readable red when SSP does not define it
function T.menuComponent()
	T.load()

	return H.expectGlobal("StormTransferFormMenuComponent", "the transfer form's menu component in StormSquadronScreenplay.lua (storm-tier2-oberhaur Content contract 3). Load problems: " .. table.concat(T.loadErrors, " | "))
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = T.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

T.crc = crc

-- Quest state helpers on a built pilot. state: "complete" | "active" | "none"
function T.setState(player, global, state)
	local key = crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function T.state(player, global)
	local key = crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- Options (all optional; the default is a Storm pilot at tier 2 who has handed in the form: a ship, standing 0, the four tier 1 skills, Colzet's
-- promotion flag and the initiate flag set, no tier 2 mission done):
--   pilot      "imperial" (default) | "neutral" | "rebel" | false (not a pilot)
--   faction    "imperial" (default) | "rebel" | "neutral" (no faction)
--   squadron   true (default: STORM_SQUADRON) | false (none) | a squadron constant
--   standing   Imperial faction standing (default 0)
--   paid       k: missions 1..k won, :attempted (1, 2) and :reward set; mission 3 is the Claw (default 0)
--   state      the state of mission paid+1: "won" (complete, :attempted, reward unpaid) | "failed" (:attempted, nothing complete) |
--              "active" (:attempted, the head active) | "attempted" (just :attempted)
--   t1         false: no tier 1 skills (default: all four)
--   t2         list of TRAIN indexes of the tier 2 skills held
--   xp         space_combat_general experience (default 0)
--   series     Colzet's promotion flag SERIES_COMPLETE_KEY (default true)
--   initiate   TIER2_INITIATE_KEY (default true); finding: TIER2_FINDING_AGENT_KEY (default false); alozen: TIER2_ALOZEN_KEY (default false)
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   ships      list of ship device templates held in the datapad
--   duty       global of a duty held active in the journal
--   forms      list of transfer forms put in the inventory: true (unsigned) or the signature string
--   species    SPECIES_* (default SPECIES_HUMAN)
--   pilotTier  ghost pilot tier (default 2)
--   inventory  (default true)
--   ship       certified ship (default true)
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
-- The player's full name is T.FULL_NAME ("Ace Starfire"), the first name "Ace".
function T.pilot(o)
	o = o or {}
	T.load()

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

	local skills = { T.NOVICE }

	if pilotKind == nil then
		skills = {}
	end

	if o.t1 ~= false then
		for _, skill in ipairs(T.TIER1_SKILLS) do
			skills[#skills + 1] = skill
		end
	end

	for _, i in ipairs(o.t2 or {}) do
		skills[#skills + 1] = T.TRAIN[i].skill
	end

	for _, skill in ipairs(o.skills or {}) do
		skills[#skills + 1] = skill
	end

	local paid = o.paid or 0
	local completed, active, status = {}, {}, {}

	for n = 1, paid do
		completed[#completed + 1] = crc(T.MISSIONS[n])
		status[statusName(n) .. ":reward"] = "1"

		if n <= 2 then
			status[statusName(n) .. ":attempted"] = "1"
		end
	end

	local n = paid + 1

	if o.state ~= nil and T.MISSIONS[n] ~= nil then
		if n <= 2 then
			status[statusName(n) .. ":attempted"] = "1"
		end

		if o.state == "won" then
			completed[#completed + 1] = crc(T.MISSIONS[n])
		elseif o.state == "active" then
			active[#active + 1] = crc(T.MISSIONS[n])
		end
	end

	if o.series ~= false then
		status[T.SERIES_SUFFIX] = "1"
	end

	if o.initiate ~= false then
		status[T.INITIATE_SUFFIX] = "1"
	end

	if o.finding then
		status[T.FINDING_SUFFIX] = "1"
	end

	if o.alozen then
		status[T.ALOZEN_SUFFIX] = "1"
	end

	if o.duty then
		active[#active + 1] = crc(o.duty)
	end

	local player = H.newPlayer({
		name = T.FULL_NAME,
		pilot = pilotKind,
		faction = faction,
		squadronType = squadron,
		pilotTier = o.pilotTier or 2,
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

	-- the first name the %TU / %NU lines use
	player.getFirstName = function() return T.FIRST_NAME end

	if o.datapad == "duty" then
		DRS.holdDuty(player, "held_by_test")
	elseif o.datapad == "story" then
		DRS.holdStory(player, "story_held_by_test")
	end

	for _, template in ipairs(o.ships or {}) do
		FF.addItem(player.datapad, template)
	end

	for _, signature in ipairs(o.forms or {}) do
		T.addForm(player, signature)
	end

	return player
end

-- Puts a transfer form into the inventory: true / nil = unsigned, a string = signed with that name. Returns the form.
function T.addForm(player, signature)
	return FF.addItem(player.inventory, T.TRANSFER_FORM, { signature = type(signature) == "string" and signature or nil, signatureKey = T.SIGNATURE_KEY })
end

-- The transfer forms in the top level of the inventory
function T.formsOf(player)
	local out = {}

	for _, item in ipairs(player.inventory.items) do
		if item.template == T.TRANSFER_FORM then
			out[#out + 1] = item
		end
	end

	return out
end

-- Engine XP prices of the four tier 2 skills, from the SWG skills.tab excerpt (fixtures/skill/skills.pilot_imperial_navy_02.tab, 60000 each)
function T.useSkillCosts()
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

function T.npc() return H.newNpc({ name = "Oberhaur" }) end

function T.requireConversationLoaded()
	T.load()

	if H.conversationTemplateTable(T.TEMPLATE) == nil or rawget(_G, T.HANDLER) == nil then
		error("Oberhaur's conversation is not loaded. Load problems: " .. table.concat(T.loadErrors, " | "), 3)
	end
end

-- Talks to Oberhaur from the first screen. choices as for H.converse.
function T.talk(player, choices)
	T.requireConversationLoaded()

	return H.converse({ template = T.TEMPLATE, player = player, npc = T.npc(), choices = choices })
end

-- The id of the first screen of a fresh talk
function T.firstScreen(player)
	return T.talk(player)[1].id
end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session.
function T.drive(player, startId, choices)
	T.requireConversationLoaded()

	local tmpl = H.conversationTemplate(T.TEMPLATE)
	local handler = rawget(_G, T.HANDLER)
	local npc = T.npc()
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
		error("screen '" .. startId .. "' is not in " .. T.TEMPLATE, 2)
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
function T.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- the option sids ("s_xxx") of a transcript step, in order
function T.optionSids(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = tostring(o.text):match(":(s_[%w_]+)$") or tostring(o.text)
	end

	return out
end

function T.linksOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = o.link
	end

	return out
end

function T.free() return H.Engine.callsTo("awardSkill") end
function T.bought() return H.Engine.callsTo("skillManagerAwardSkill") end

-- Tier 2 skills (of the four) the player holds, in T.TRAIN order
function T.held(player)
	local out = {}

	for _, t in ipairs(T.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

-- The item giveItem calls on the pilot's inventory received
function T.items(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory then
			out[#out + 1] = call[2]
		end
	end

	return out
end

return T
