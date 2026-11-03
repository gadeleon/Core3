-- Shared test data and builders for Smuggler tier 3 (Beissa, Jabba's Palace), not a test file.
-- Spec: .claude/work/smuggler-tier3-beissa/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A, B and C).
--
-- The quest values are DERIVED from the SWG-Source files in fixtures/ (B.expected): the 17 spacequest .tab files, the two buildout excerpts
-- space_zones/buildout/space_{yavin4,dathomir}.smuggler_tier3_points.tab (truncated toward zero, as Core3's patrol point files hold them) and Beissa's
-- script (credits and reward items). Only what no SWG file decides (radius 150/250, failTimer 20, the class names, the 5 s split bonus) is a spec literal.
--   B.expected()               the whole table of each of the 17 quest globals (Appendix B: a key not listed must not be set)
--   B.SCREENS / B.TEXT         Appendix A (smuggler_tier3_screens_data.lua) / the client text of the 249 entries (smuggler_tier3_client_text.lua)
--   B.TRAIN / B.MISSIONS       TRAIN_CHOICES and MISSIONS of the handler (Content contract 3)
--   B.TWIN_REPLY / TWIN_NPC / REJOIN   Data mapping 3, as literal tables
--   B.load()                   the server's load: squadrons, Dravis, Karrde, Shamdon, then Beissa's template and handler, collecting load errors
--   B.pilot{...}               a pilot standing in front of Beissa (see the option list at B.pilot)
--   B.talk / B.drive           H.converse from the first screen / from a given screen (Beissa); Karrde: B.karrdeTalk
--
-- Beissa's conversation lives in the template "beissa_convo_template", its handler is the global "beissaConvoHandler".

local H = require("harness")
local S = require("smuggler_tier1_data")
local T = require("smuggler_transition_data")
local M = require("smuggler_tier2_data")

local B = {}

B.TEMPLATE = "beissa_convo_template"
B.HANDLER = "beissaConvoHandler"
B.PREFIX = "@conversation/tatooine_privateer_tier3:"
B.STF = "conversation/tatooine_privateer_tier3"

B.TEMPLATE_FILE = "mobile/conversations/space/neutral/smuggler_squadron/beissa_convo.lua"
B.HANDLER_FILE = "screenplays/space/conversations/neutral/smuggler_squadron/beissaConvoHandler.lua"
B.SQUADRON_FILE = S.SQUADRON_FILE
B.NPC_FILE = "mobile/space/beissa.lua"
B.INCLUDE_TEMPLATE = 'includeFile("conversations/space/neutral/smuggler_squadron/beissa_convo.lua")'
B.INCLUDE_HANDLER = 'includeFile("space/conversations/neutral/smuggler_squadron/beissaConvoHandler.lua")'
B.SHAMDON_INCLUDE_TEMPLATE = M.INCLUDE_TEMPLATE
B.SHAMDON_INCLUDE_HANDLER = M.INCLUDE_HANDLER

B.BJ = H.FIXTURES .. "script/conversation/tatooine_privateer_tier3.java"
B.SWG_DIR = M.SWG_DIR
B.SHIP_FILES = {
	soldier = "ship_mobile/ships/dath_witchblood_clan_soldier_tier3.lua",
	punisher = "ship_mobile/ships/dath_witchblood_clan_punisher_tier3.lua",
}

-- Content contract 1: the 17 globals, in registration order
B.GLOBALS = {
	"recovery_tatooine_privateer_tier3_1", "assassinate_tatooine_privateer_tier3_1_a", "assassinate_tatooine_privateer_tier3_1_b",
	"assassinate_tatooine_privateer_tier3_1_c", "destroy_surpriseattack_tatooine_privateer_tier3_1_d",
	"inspect_tatooine_privateer_tier3_2", "inspect_tatooine_privateer_tier3_2_a", "survival_tatooine_privateer_tier3_2_b",
	"delivery_no_pickup_tatooine_privateer_tier3_3", "delivery_no_pickup_tatooine_privateer_tier3_3_a", "delivery_no_pickup_tatooine_privateer_tier3_3_b",
	"escort_tatooine_privateer_tier3_3_c",
	"patrol_tatooine_privateer_tier3_4", "space_battle_tatooine_privateer_tier3_4_a", "space_battle_tatooine_privateer_tier3_4_b",
	"patrol_tatooine_privateer_tier3_4_c", "rescue_tatooine_privateer_tier3_4_d",
}

-- mission n -> chain (global names, in chain order)
B.CHAINS = {
	{ B.GLOBALS[1], B.GLOBALS[2], B.GLOBALS[3], B.GLOBALS[4], B.GLOBALS[5] },
	{ B.GLOBALS[6], B.GLOBALS[7], B.GLOBALS[8] },
	{ B.GLOBALS[9], B.GLOBALS[10], B.GLOBALS[11], B.GLOBALS[12] },
	{ B.GLOBALS[13], B.GLOBALS[14], B.GLOBALS[15], B.GLOBALS[16], B.GLOBALS[17] },
}

B.HEADS = { B.GLOBALS[1], B.GLOBALS[6], B.GLOBALS[9], B.GLOBALS[13] }

local Y, D = "space_yavin4", "space_dathomir"

-- global -> { class, type, name, zone }
B.IDENTITY = {}

do
	local rows = {
		{ 1, "SpaceRecoveryScreenplay", "recovery", "tatooine_privateer_tier3_1", Y },
		{ 2, "SpaceAssassinateScreenplay", "assassinate", "tatooine_privateer_tier3_1_a", Y },
		{ 3, "SpaceAssassinateScreenplay", "assassinate", "tatooine_privateer_tier3_1_b", Y },
		{ 4, "SpaceAssassinateScreenplay", "assassinate", "tatooine_privateer_tier3_1_c", Y },
		{ 5, "SpaceSurpriseAttackScreenplay", "destroy_surpriseattack", "tatooine_privateer_tier3_1_d", Y },
		{ 6, "SpaceInspectScreenplay", "inspect", "tatooine_privateer_tier3_2", D },
		{ 7, "SpaceInspectScreenplay", "inspect", "tatooine_privateer_tier3_2_a", D },
		{ 8, "SpaceSurvivalScreenplay", "survival", "tatooine_privateer_tier3_2_b", D },
		{ 9, "SpaceDeliveryNoPickupScreenplay", "delivery_no_pickup", "tatooine_privateer_tier3_3", D },
		{ 10, "SpaceDeliveryNoPickupScreenplay", "delivery_no_pickup", "tatooine_privateer_tier3_3_a", D },
		{ 11, "SpaceDeliveryNoPickupScreenplay", "delivery_no_pickup", "tatooine_privateer_tier3_3_b", D },
		{ 12, "SpaceEscortScreenplay", "escort", "tatooine_privateer_tier3_3_c", D },
		{ 13, "SpacePatrolScreenplay", "patrol", "tatooine_privateer_tier3_4", D },
		{ 14, "SpaceBattleScreenplay", "space_battle", "tatooine_privateer_tier3_4_a", D },
		{ 15, "SpaceBattleScreenplay", "space_battle", "tatooine_privateer_tier3_4_b", D },
		{ 16, "SpacePatrolScreenplay", "patrol", "tatooine_privateer_tier3_4_c", D },
		{ 17, "SpaceRescueScreenplay", "rescue", "tatooine_privateer_tier3_4_d", D },
	}

	for _, r in ipairs(rows) do
		B.IDENTITY[B.GLOBALS[r[1]]] = { class = r[2], type = r[3], name = r[4], zone = r[5] }
	end
end

-- Content contract 2: the squadron object's constants
B.QUEST_STRINGS = {
	TIER3_QUEST_STRING_1 = { type = "recovery", name = "tatooine_privateer_tier3_1" },
	TIER3_QUEST_STRING_1_SIDE1 = { type = "assassinate", name = "tatooine_privateer_tier3_1_a" },
	TIER3_QUEST_STRING_1_SIDE2 = { type = "assassinate", name = "tatooine_privateer_tier3_1_b" },
	TIER3_QUEST_STRING_1_SIDE3 = { type = "assassinate", name = "tatooine_privateer_tier3_1_c" },
	TIER3_QUEST_STRING_1_SIDE4 = { type = "destroy_surpriseattack", name = "tatooine_privateer_tier3_1_d" },
	TIER3_QUEST_STRING_2 = { type = "inspect", name = "tatooine_privateer_tier3_2" },
	TIER3_QUEST_STRING_2_SIDE1 = { type = "inspect", name = "tatooine_privateer_tier3_2_a" },
	TIER3_QUEST_STRING_2_SIDE2 = { type = "survival", name = "tatooine_privateer_tier3_2_b" },
	TIER3_QUEST_STRING_3 = { type = "delivery_no_pickup", name = "tatooine_privateer_tier3_3" },
	TIER3_QUEST_STRING_3_SIDE1 = { type = "delivery_no_pickup", name = "tatooine_privateer_tier3_3_a" },
	TIER3_QUEST_STRING_3_SIDE2 = { type = "delivery_no_pickup", name = "tatooine_privateer_tier3_3_b" },
	TIER3_QUEST_STRING_3_SIDE3 = { type = "escort", name = "tatooine_privateer_tier3_3_c" },
	TIER3_QUEST_STRING_4 = { type = "patrol", name = "tatooine_privateer_tier3_4" },
	TIER3_QUEST_STRING_4_SIDE1 = { type = "space_battle", name = "tatooine_privateer_tier3_4_a" },
	TIER3_QUEST_STRING_4_SIDE2 = { type = "space_battle", name = "tatooine_privateer_tier3_4_b" },
	TIER3_QUEST_STRING_4_SIDE3 = { type = "patrol", name = "tatooine_privateer_tier3_4_c" },
	TIER3_QUEST_STRING_4_SIDE4 = { type = "rescue", name = "tatooine_privateer_tier3_4_d" },
}

-- the quest-name part of the :attempted / :reward keys (head names), mission n = 1..4
B.STATUS_NAMES = { "tatooine_privateer_tier3_1", "tatooine_privateer_tier3_2", "tatooine_privateer_tier3_3", "tatooine_privateer_tier3_4" }

function B.statusKeys()
	local out = {}

	for n = 1, 4 do
		out[#out + 1] = B.STATUS_NAMES[n] .. ":attempted"
		out[#out + 1] = B.STATUS_NAMES[n] .. ":reward"
	end

	return out
end

-- Content contract 3: MISSIONS (head, questString, endString)
B.MISSIONS = {
	{ n = 1, head = B.GLOBALS[1], questString = "TIER3_QUEST_STRING_1", endString = "TIER3_QUEST_STRING_1_SIDE4", chain = B.CHAINS[1], status = B.STATUS_NAMES[1],
		offer = "m1_offer", failed = "m1_failed", reward = "m1_reward", trained = "m1_trained", zone = Y },
	{ n = 2, head = B.GLOBALS[6], questString = "TIER3_QUEST_STRING_2", endString = "TIER3_QUEST_STRING_2_SIDE2", chain = B.CHAINS[2], status = B.STATUS_NAMES[2],
		offer = "m2_offer", failed = "m2_failed", reward = "m2_reward", trained = "m2_trained", zone = D },
	{ n = 3, head = B.GLOBALS[9], questString = "TIER3_QUEST_STRING_3", endString = "TIER3_QUEST_STRING_3_SIDE3", chain = B.CHAINS[3], status = B.STATUS_NAMES[3],
		offer = "m3_offer", failed = "m3_failed", reward = "m3_reward", trained = "m3_trained", zone = D },
	{ n = 4, head = B.GLOBALS[13], questString = "TIER3_QUEST_STRING_4", endString = "TIER3_QUEST_STRING_4_SIDE4", chain = B.CHAINS[4], status = B.STATUS_NAMES[4],
		offer = "m4_offer", failed = "m4_failed", reward = "m4_reward", trained = "m4_trained", zone = D },
}

-- the screens that grant a mission (START_SCREENS) -> mission
B.START_SCREENS = {
	m1_retry_run_over = 1, m1_retry_shut_up = 1, m1_accept = 1, m1b_accept = 1,
	m2_retry_blast = 2, m2_retry_guess = 2, m2_accept = 2,
	m3_retry_angry_jabba = 3, m3_retry_hurry = 3, m3_accept = 3,
	m4_retry_why = 4, m4_retry_do_it = 4, m4_accept = 4,
}

-- the retry screens of mission n (both routes of mN_failed end on one)
B.RETRIES = {
	[1] = { "m1_retry_run_over", "m1_retry_shut_up" }, [2] = { "m2_retry_blast", "m2_retry_guess" },
	[3] = { "m3_retry_hurry", "m3_retry_angry_jabba" }, [4] = { "m4_retry_why", "m4_retry_do_it" },
}

-- TRAIN_CHOICES in menu order (BJ branch 32): skill, topic reply
B.TRAIN = {
	{ x = "starships", skill = "pilot_neutral_starships_03", reply = "s_c634ffcd" },
	{ x = "weapons", skill = "pilot_neutral_weapons_03", reply = "s_a9aeb386" },
	{ x = "procedures", skill = "pilot_neutral_procedures_03", reply = "s_523a54d5" },
	{ x = "droid", skill = "pilot_neutral_droid_03", reply = "s_473d09d8" },
}

-- the answer line of the trained screen of mission n (Data mapping 3, [P])
B.TRAINED_SID = { [1] = "s_e413d452", [2] = "s_999144d9", [3] = "s_32376199", [4] = "s_f2593c16" }

B.TIER2_SKILLS = {
	"pilot_neutral_starships_02", "pilot_neutral_weapons_02", "pilot_neutral_procedures_02", "pilot_neutral_droid_02",
}

B.CREDITS = 25000

-- Data mapping 3 (literal tables of the spec)
B.TWIN_REPLY = {
	s_74 = "s_4c695dbd", s_109 = "s_4d69a104", s_143 = "s_4d69a104", s_147 = "s_719a036e", s_153 = "s_bc375f79", s_157 = "s_31960979", s_161 = "s_ad7db4d",
	s_232 = "s_4f4e1c4e", s_262 = "s_edd73236", s_298 = "s_2675f275", s_338 = "s_5a8556d4", s_342 = "s_731189e6", s_380 = "s_2675f275", s_444 = "s_b55e3f14",
	s_447 = "s_72318c63", s_450 = "s_841d27db", s_457 = "s_80bfc2af", s_482 = "s_bc375f79", s_491 = "s_dd19988e", s_495 = "s_800d8ca1", s_501 = "s_98b1ccd4",
	s_513 = "s_bc375f79",
}

-- NGE NPC node -> { client dialog, screen }
B.TWIN_NPC = {
	s_145 = { "s_505c7932", "m1b_clear_system" }, s_151 = { "s_f3d30738", "m1b_perfect_person" }, s_155 = { "s_acbfc0cc", "m1b_ripe" },
	s_159 = { "s_c6e0e27", "m1b_get_shipment" }, s_340 = { "s_bcad400e", "m2b_juicy_deal" }, s_442 = { "s_509249db", "m3b_imperials" },
	s_452 = { "s_38c86018", "m3b_enemies_closer" }, s_493 = { "s_83c2b64", "m4b_bad_news" }, s_497 = { "s_f0fbdf16", "m4b_rancor_clan" },
}

-- Rejoins: the BJ successor (an NGE node) of an entry reply -> the existing screen the Core3 link goes to
-- { from screen, reply sid (client), java reply (NGE or client), java successor, target screen }
B.REJOIN = {
	{ "m1_todo_list", "s_4d69a104", "s_109", "s_111", "m1_clear_system" },
	{ "m1_my_problem", "s_9532fb5c", "s_9532fb5c", "s_169", "m1_shipment_nerve" },
	{ "m2_idea", "s_4f4e1c4e", "s_232", "s_234", "m2_soldiers" },
	{ "m2_under_control", "s_edd73236", "s_262", "s_264", "m2_witchblood_who" },
	{ "m2_under_control", "s_2675f275", "s_298", "s_300", "m2_force" },
	{ "m2b_later_imperials", "s_bf01df79", "s_bf01df79", "s_346", "m2_witchblood_who" },
	{ "m2b_later_imperials", "s_2675f275", "s_380", "s_382", "m2_force" },
	{ "m3b_enemies_closer", "s_5494c458", "s_5494c458", "s_455", "m3_uploaded" },
	{ "m4b_very", "s_98b1ccd4", "s_501", "s_503", "m4_talking" },
}

B.SCREENS = require("smuggler_tier3_screens_data")
B.TEXT = require("smuggler_tier3_client_text")

function B.screenRow(id)
	for _, row in ipairs(B.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (142), sorted
function B.screenIds()
	local out = {}

	for i, row in ipairs(B.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- The client ids this feature uses: the dialog of every screen, every static reply of Appendix A and the four topic replies (247 = the STF lines)
function B.usedIds()
	local set = {}

	for _, row in ipairs(B.SCREENS) do
		set[row.sid] = true

		for _, o in ipairs(row.options) do
			set[o[1]] = true
		end
	end

	for _, t in ipairs(B.TRAIN) do
		set[t.reply] = true
	end

	local out = {}

	for id in pairs(set) do
		out[#out + 1] = id
	end

	table.sort(out)
	return out
end

-- Appendix C: Karrde's six K2 screens, in K order
B.KARRDE_K2 = {
	{ id = "tier3_done", sid = "s_74bf2381", animation = "", stop = false, options = { { "s_1c8bddbb", "dathomir_contact", "" } } },
	{ id = "dathomir_contact", sid = "s_9fcfc09a", animation = "point_accusingly", stop = false, options = { { "s_800d8ca1", "nirame_who", "" } } },
	{ id = "nirame_who", sid = "s_de0bf763", animation = "snap_finger2", stop = false, options = { { "s_a89cdefd", "nym_hyperspace", "" } } },
	{ id = "nym_hyperspace", sid = "s_238f162d", animation = "pound_fist_palm", stop = false, options = { { "s_415dfb0e", "branching_out", "" } } },
	{ id = "branching_out", sid = "s_a134e447", animation = "shrug_shoulders", stop = false, options = { { "s_e8ed6f9a", "see_nirame", "" } } },
	{ id = "see_nirame", sid = "s_aa257bf2", animation = "point_to_self", stop = true, options = {} },
}

---------------------------------------------------------------------------------------------
-- The oracle: values from the SWG-Source fixtures
---------------------------------------------------------------------------------------------

local trunc = M.trunc
local readFile = M.readFile

B.trunc = trunc
B.readFile = readFile

B.ZONES = { "yavin4", "dathomir" }

local buildoutCache = {}

-- { nav = name -> { x, z, y, forward = {x, z, y} }, spawners = list of { name, x, z, y } (file order) } of the zone's excerpt
function B.buildout(zone)
	if buildoutCache[zone] == nil then
		local tab = H.fixture("space_zones/buildout/space_" .. zone .. ".smuggler_tier3_points.tab")
		local nav, spawners = {}, {}

		for _, rec in ipairs(tab.records) do
			local vars = rec:get("strObjVars") or ""
			local name = vars:match("nav_name|4|([^|]+)|")
			local x, z, y = trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ"))

			if name ~= nil then
				nav[name] = { x, z, y, forward = { x = rec:num("fltKX"), z = rec:num("fltKY"), y = rec:num("fltKZ") } }
			end

			local spawner = vars:match("strSpawnerName|4|([^|]+)|")

			if spawner ~= nil then
				spawners[#spawners + 1] = { name = spawner, x, z, y }
			end
		end

		buildoutCache[zone] = { nav = nav, spawners = spawners }
	end

	return buildoutCache[zone]
end

-- The rewards of the four missions, parsed from BJ: giveReward(player, "<type>", "<name>", <credits>, "<item>"). Returns "type/name" -> { credits, item }
function B.rewards()
	local java = readFile(B.BJ)
	local out = {}

	if java == nil then
		return out
	end

	for questType, name, credits, item in java:gmatch('giveReward%(player, "([%w_]+)", "([%w_]+)", (%d+), "([^"]+)"%)') do
		out[questType .. "/" .. name] = { credits = tonumber(credits), item = item }
	end

	return out
end

function B.fixtureOf(global)
	local id = B.IDENTITY[global]

	return H.questFixture(id.type, id.name)
end

-- Points of a .tab column: { name, zone, x, z, y, forward } from the buildout excerpts
function B.pointsOf(rec, column)
	local out = {}

	for i, value in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(value)
		local xyz = B.buildout(zone:gsub("^space_", "")).nav[name]

		assert(xyz ~= nil, "the buildout excerpt of " .. tostring(zone) .. " has no nav point " .. tostring(name))
		out[i] = { name = name, zone = zone, x = xyz[1], z = xyz[2], y = xyz[3], forward = xyz.forward }
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

local function plain(p) return { patrolPointName = p.name, x = p.x, z = p.z, y = p.y } end

local function numbered(points, extra, key)
	local out = {}

	for i, p in ipairs(points) do
		local t = plain(p)

		for k, v in pairs(extra or {}) do
			t[k] = v
		end

		if key then
			t[key] = i
		end

		out[i] = t
	end

	return out
end

local function listType(rec, class)
	local v = rec:get("attackListType")

	if v == "sequential" then
		return class.ATTACK_LIST_TYPES.SEQUENTIAL
	elseif v == "random" then
		return class.ATTACK_LIST_TYPES.RANDOM
	end

	error("unknown attackListType " .. tostring(v))
end

-- the global (of the 17) that the triggerArg of `global` names, or nil
local function childOf(global)
	local rec = B.fixtureOf(global)

	if rec:get("triggerEvent") ~= "splitquest" then
		return nil
	end

	local t, n = H.Tab.splitQuestRef(rec:get("triggerArg"))

	return t .. "_" .. n
end

B.childOf = childOf

-- Data mapping 1, derived from the fixtures. Returns { [global] = whole table (Appendix B) }.
function B.expected()
	local rewards = B.rewards()
	local COMPLETION = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION
	local PATROL_POINT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT
	local out = {}
	local parentOf = {}

	for _, global in ipairs(B.GLOBALS) do
		local c = childOf(global)

		if c ~= nil then
			parentOf[c] = global
		end
	end

	for _, global in ipairs(B.GLOBALS) do
		local id = B.IDENTITY[global]
		local rec = B.fixtureOf(global)
		local t = { className = global, questType = id.type, questName = id.name, questZone = rec:get("questZone") }
		local isHead = parentOf[global] == nil

		if isHead then
			local rw = rewards[id.type .. "/" .. id.name]

			assert(rw ~= nil, "BJ has no giveReward for " .. id.type .. "/" .. id.name)
			t.creditReward = rw.credits
			t.itemReward = { { species = { -1 }, item = rw.item } }
		else
			local pid = B.IDENTITY[parentOf[global]]

			t.parentQuest, t.parentQuestType, t.parentQuestName = parentOf[global], pid.type, pid.name
		end

		local child = childOf(global)

		if child ~= nil then
			local cid = B.IDENTITY[child]

			t.sideQuest, t.sideQuestType, t.sideQuestName = true, cid.type, cid.name

			if id.type == "patrol" then
				t.sideQuestSplitType, t.sideQuestPatrolStart, t.sideQuestDelay = PATROL_POINT, rec:num("triggerOn"), rec:num("triggerDelay")
			else
				t.sideQuestSplitType, t.sideQuestDelay = COMPLETION, (rec:num("triggerDelay") or 0) + 5
			end
		else
			t.sideQuest, t.sideQuestType = false, ""
		end

		local ty = id.type

		if ty == "recovery" then
			local m = rec:num("numResponses")
			local conv = rec:get("recoveryAppearance"):gsub("([^/]+)$", "shared_%1")

			t.arrivalDelay, t.recoveryDelay, t.recoverShip = rec:num("targetArrivalDelay"), rec:num("targetRecoverTime"), rec:get("targetShipType")
			t.recoveryConversationMobile = conv
			t.escortShips = rec:list("targetEscort")
			t.preRecoveryPoints = numbered(B.pointsOf(rec, "escortPath"), { radius = 250 }, "escortNumber")
			t.recoveryPoints = numbered(B.pointsOf(rec, "recoveryPath"), { radius = 250 }, "escortNumber")
			t.attackDelay, t.attackShips = rec:num("attackPeriod"), attackLists(rec)
			t.tauntData = { panicCount = m, thanksCount = m }
		elseif ty == "assassinate" then
			t.arrivalDelay, t.failTimer, t.mustDestroyEscort = rec:num("targetArrivalDelay"), 20, rec:num("mustDestroyEscort") == 1
			t.assassinateSpawns = { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }
			t.targetPatrols = numbered(B.pointsOf(rec, "escortPath"))
		elseif ty == "destroy_surpriseattack" then
			t.surpriseAttackShips = { zone = rec:get("questZone"), spawns = { { count = rec:num("shipCount"), shipName = rec:get("shipType") } } }
		elseif ty == "inspect" then
			local want = {}

			for _, value in ipairs(rec:list("validSpawns")) do
				local zone, name = H.Tab.splitNavPoint(value)

				for _, sp in ipairs(B.buildout(zone:gsub("^space_", "")).spawners) do
					if sp.name == name then
						want[#want + 1] = { spawnName = name, x = sp[1], z = sp[2], y = sp[3] }
					end
				end
			end

			t.shipList, t.validSpawns, t.giveSpawnWaypoint, t.cargo = rec:list("shipList"), want, rec:num("giveSpawnWaypoint"), rec:get("cargo")
		elseif ty == "survival" then
			local p = B.pointsOf(rec, "transmissionPoint")[1]

			t.transmissionPoint = plain(p)
			t.totalTransmissionTime, t.timesToUpdateProgress = rec:num("totalTransmissionTime"), rec:num("timesToUpdateProgress")
			t.transmissionStartDelay, t.delayToFirstAttack = rec:num("transmissionStartDelay"), rec:num("delayToFirstAttack")
			t.attackShipLists, t.attackPeriod, t.attackListType = attackLists(rec), rec:num("attackPeriod"), listType(rec, SpaceSurvivalScreenplay)
		elseif ty == "delivery_no_pickup" then
			t.deliveryShip, t.deliveryPoint = rec:get("deliveryShip"), plain(B.pointsOf(rec, "deliveryPoint")[1])
			t.attackShipLists, t.attackPeriod, t.attackListType = attackLists(rec), rec:num("attackPeriod"), listType(rec, SpaceDeliveryScreenplay)
		elseif ty == "escort" then
			local m = rec:num("numResponses")

			t.escortShips = { rec:get("escortShipType") }
			t.escortPoints = numbered(B.pointsOf(rec, "escortPath"), { zoneName = rec:get("questZone"), radius = 250 }, "escortNumber")
			t.attackDelay, t.attackShips = rec:num("attackPeriod"), attackLists(rec)
			t.tauntData = { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m }
		elseif ty == "patrol" then
			t.patrolPoints = numbered(B.pointsOf(rec, "navPoints"), { radius = 150 }, "patrolNumber")
		elseif ty == "space_battle" then
			local p = B.pointsOf(rec, "battlePoint")[1]
			local bp = plain(p)

			bp.forward = p.forward
			t.battlePoint = bp
			t.damageMultiplier, t.allyArrivalDelay, t.enemyArrivalDelay = rec:num("damageMultiplier"), rec:num("allyArrivalDelay"), rec:num("enemyArrivalDelay")
			t.allyOriginDist, t.enemyOriginDist = rec:num("allyOriginDist"), rec:num("enemyOriginDist")
			t.allyArrivalDist, t.enemyArrivalDist = rec:num("allyArrivalDist"), rec:num("enemyArrivalDist")
			t.allyForce, t.enemyForce = rec:list("allyForce"), rec:list("enemyForce")
		elseif ty == "rescue" then
			t.recoveryPath = numbered(B.pointsOf(rec, "recoveryPath"))
			t.targetShipType, t.targetArrivalDelay = rec:get("targetShipType"), rec:num("targetArrivalDelay")
			t.attackShipLists, t.attackPeriod, t.attackListType = attackLists(rec), rec:num("attackPeriod"), listType(rec, SpaceRescueScreenplay)
			t.numResponses = rec:num("numResponses")
		end

		out[global] = t
	end

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

-- The server's load: everything the tier 2 feature loads (squadrons, Dravis, Karrde, Shamdon), then Beissa's template and handler. A missing production
-- file is recorded in B.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function B.load()
	if loaded then
		return
	end

	loaded = true
	M.load()

	for _, e in ipairs(M.loadErrors) do
		B.loadErrors[#B.loadErrors + 1] = e
	end

	try("beissa_convo.lua", function() H.loadMobile("conversations/space/neutral/smuggler_squadron/beissa_convo.lua") end)
	try("beissaConvoHandler.lua", function() H.loadScreenplay("space/conversations/neutral/smuggler_squadron/beissaConvoHandler.lua") end)
end

function B.problems() return table.concat(B.loadErrors, " | ") end

-- Fails with the load problems when the template or handler could not be loaded
function B.requireConversation(lu)
	B.load()
	lu.assertNotNil(H.conversationTemplateTable(B.TEMPLATE), B.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. B.problems())
	lu.assertNotNil(rawget(_G, B.HANDLER), B.HANDLER .. " is not defined. Load problems: " .. B.problems())
end

function B.quest(global)
	B.load()

	return H.expectGlobal(global, "Smuggler tier 3 quest table (smuggler-tier3-beissa). Load problems: " .. B.problems())
end

-- the squadron object (SmugglerSquadronScreenplay), with the load problems in the failure message
function B.squadron()
	B.load()

	return H.expectGlobal("SmugglerSquadronScreenplay", "Smuggler squadron screenplay object. Load problems: " .. B.problems())
end

function B.handler() return rawget(_G, B.HANDLER) end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = B.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

B.crc = crc

-- state: "complete" | "active" | "none"
function B.setState(player, global, state)
	local key = crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function B.state(player, global)
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
--   won       :attempted, the whole chain complete, :reward unset (the reward is waiting)
--   paid      won, :reward set
--   endonly   only the chain end complete (no :attempted)
--   partial   :attempted, the head complete and the end not (a run that stopped inside a split window)
function B.setMission(player, n, state)
	local m = B.MISSIONS[n]
	local chain = m.chain

	for _, g in ipairs(chain) do
		B.setState(player, g, "none")
	end

	if state == "fresh" or state == "endonly" then
		removeQuestStatus(player.objectID .. m.status .. ":attempted")
	else
		H.setQuestStatus(player, m.status .. ":attempted", 1)
	end

	if state == "paid" then
		H.setQuestStatus(player, m.status .. ":reward", 1)
	else
		removeQuestStatus(player.objectID .. m.status .. ":reward")
	end

	if state == "won" or state == "paid" then
		for _, g in ipairs(chain) do
			B.setState(player, g, "complete")
		end
	elseif state == "endonly" then
		B.setState(player, chain[#chain], "complete")
	elseif state == "partial" then
		B.setState(player, chain[1], "complete")
	elseif state == "active" then
		B.setState(player, chain[1], "active")
	end
end

-- Options (all optional; the default is a Smuggler tier 2 graduate: the four tier 2 skills, the four tier 2 missions paid, the transition won and paid,
-- pilot tier 3, no tier 3 skill, no tier 3 mission state, no XP, a man, a ship, an inventory):
--   t2         false: no tier 2 graduate (nothing of tier 2); a number n: the first n tier 2 skills, the tier 2 missions all won (so only the skills fail the gate)
--   missions2  { [n] = state } tier 2 mission n (M.setMission states) applied to the graduate
--   t3         list of B.TRAIN indexes (1 starships, 2 weapons, 3 procedures, 4 droid) of the tier 3 skills held
--   mission    { [n] = state } tier 3 mission n (see B.setMission)
--   paid       list of n whose mission is "paid"
--   xp, pilotTier (default 3), and every other S.pilot / T.pilot / M.pilot option (pilot, faction, squadron, ship, datapad, duty, zone, inShip, species,
--   inventory, gender, trans, rewarded)
function B.pilot(o)
	o = o or {}
	B.load()

	local mo = {}

	for k, v in pairs(o) do
		if k ~= "t2" and k ~= "missions2" and k ~= "t3" and k ~= "mission" and k ~= "paid" then
			mo[k] = v
		end
	end

	if mo.pilotTier == nil then
		mo.pilotTier = 3
	end

	if o.t2 == nil then
		mo.all4 = true
	elseif type(o.t2) == "number" then
		mo.tier2 = o.t2
		mo.missions = { [1] = "paid", [2] = "paid", [3] = "paid", [4] = "paid" }
	end

	if o.missions2 ~= nil then
		mo.missions = mo.missions or {}

		for n, state in pairs(o.missions2) do
			mo.missions[n] = state
		end
	end

	local skills = {}

	for _, x in ipairs(mo.skills or {}) do
		skills[#skills + 1] = x
	end

	for _, i in ipairs(o.t3 or {}) do
		skills[#skills + 1] = B.TRAIN[i].skill
	end

	mo.skills = skills

	local player = M.pilot(mo)
	local states = {}

	for _, n in ipairs(o.paid or {}) do
		states[n] = "paid"
	end

	for n, state in pairs(o.mission or {}) do
		states[n] = state
	end

	for n, state in pairs(states) do
		B.setMission(player, n, state)
	end

	return player
end

function B.npc() return H.newNpc({ name = "Beissa" }) end

function B.requireConversationLoaded()
	B.load()

	if H.conversationTemplateTable(B.TEMPLATE) == nil or rawget(_G, B.HANDLER) == nil then
		error("Beissa's conversation is not loaded. Load problems: " .. B.problems(), 3)
	end
end

-- Talks to Beissa from the first screen. choices as for H.converse.
function B.talk(player, choices)
	B.requireConversationLoaded()

	return H.converse({ template = B.TEMPLATE, player = player, npc = B.npc(), choices = choices })
end

-- The id of the first screen of a fresh talk
function B.firstScreen(player) return B.talk(player)[1].id end

-- Karrde's talk (his template and handler are loaded by B.load)
function B.karrdeTalk(player, choices)
	B.load()

	return T.talk(player, choices)
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

B.ids = S.ids
B.optionSids = S.optionSids
B.linksOf = S.linksOf
B.snapshot = M.snapshot

-- Tier 3 skills (of the four) the player holds, in B.TRAIN order
function B.held(player)
	local out = {}

	for _, t in ipairs(B.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

-- Spies on the startQuest of the listed globals (H.spyOn does not call the original)
function B.spyStarts(globals)
	local spies = {}

	for _, g in ipairs(globals or B.GLOBALS) do
		spies[g] = H.spyOn(B.quest(g), "startQuest")
	end

	return spies
end

-- the sorted list of globals whose startQuest was called, one entry per call
function B.started(spies)
	local out = {}

	for g, calls in pairs(spies) do
		for _ = 1, #calls do
			out[#out + 1] = g
		end
	end

	table.sort(out)
	return out
end

return B
