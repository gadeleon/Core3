-- Shared test data and builders for Smuggler tier 4 (Nirame Sakute, Dathomir Trade Outpost), not a test file.
-- Spec: .claude/work/smuggler-tier4-nirame/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A-E).
--
-- The quest values are DERIVED from the SWG-Source files in fixtures/ (N.expected): the 16 spacequest .tab files, the four buildout excerpts
-- space_zones/buildout/space_{lok,dantooine,tatooine,endor}.smuggler_tier4_points.tab (truncated toward zero, as Core3's patrol point files hold them) and
-- Nirame's script (credits and reward items). Only what no SWG file decides (radius 250, failTimer 20, the class names, the 5 s split bonus, the rescue duty's
-- 5 responses) is a spec literal.
--   N.expected()               the whole table of each of the 16 quest globals (Appendix B: a key not listed must not be set)
--   N.SCREENS / N.TEXT         Appendix A (smuggler_tier4_screens_data.lua) / the client text of the 247 entries (smuggler_tier4_client_text.lua)
--   N.TRAIN / N.MISSIONS       TRAIN_CHOICES and MISSIONS of the handler (Content contract 3)
--   N.load()                   the server's load: squadrons, Dravis, Karrde, Shamdon, Beissa, then Nirame's template and handler, collecting load errors
--   N.pilot{...}               a pilot standing in front of Nirame (see the option list at N.pilot)
--   N.talk / N.drive           H.converse from the first screen / from a given screen (Nirame); Karrde: N.karrdeTalk
--
-- Nirame's conversation lives in the template "nirame_sakute_convo_template", its handler is the global "nirameSakuteConvoHandler".

local H = require("harness")
local S = require("smuggler_tier1_data")
local T = require("smuggler_transition_data")
local M = require("smuggler_tier2_data")
local B = require("smuggler_tier3_data")

local N = {}

N.TEMPLATE = "nirame_sakute_convo_template"
N.HANDLER = "nirameSakuteConvoHandler"
N.PREFIX = "@conversation/tatooine_privateer_tier4:"
N.STF = "conversation/tatooine_privateer_tier4"

N.TEMPLATE_FILE = "mobile/conversations/space/neutral/smuggler_squadron/nirame_sakute_convo.lua"
N.HANDLER_FILE = "screenplays/space/conversations/neutral/smuggler_squadron/nirameSakuteConvoHandler.lua"
N.SQUADRON_FILE = S.SQUADRON_FILE
N.NPC_FILE = "mobile/space/nirame_sakute.lua"
N.INCLUDE_TEMPLATE = 'includeFile("conversations/space/neutral/smuggler_squadron/nirame_sakute_convo.lua")'
N.INCLUDE_HANDLER = 'includeFile("space/conversations/neutral/smuggler_squadron/nirameSakuteConvoHandler.lua")'
N.BEISSA_INCLUDE_TEMPLATE = B.INCLUDE_TEMPLATE
N.BEISSA_INCLUDE_HANDLER = B.INCLUDE_HANDLER

N.NJ = H.FIXTURES .. "script/conversation/tatooine_privateer_tier4.java"
N.SWG_DIR = M.SWG_DIR
N.SHIP_FILES = {
	tier4 = "ship_mobile/ships/valarian_gunship_inspect_tier4.lua",
	plain = "ship_mobile/ships/valarian_gunship_inspect.lua",
}

-- Content contract 1: the 16 globals, in registration order
N.GLOBALS = {
	"delivery_tatooine_privateer_tier4_1a", "delivery_no_pickup_tatooine_privateer_tier4_1b",
	"recovery_tatooine_privateer_tier4_2a", "recovery_tatooine_privateer_tier4_2b", "survival_tatooine_privateer_tier4_2c",
	"inspect_tatooine_privateer_tier4_3a", "assassinate_tatooine_privateer_tier4_3b", "destroy_surpriseattack_tatooine_privateer_tier4_3c_sa",
	"recovery_tatooine_privateer_tier4_3c",
	"assassinate_tatooine_privateer_tier4_4a", "assassinate_tatooine_privateer_tier4_4b", "assassinate_tatooine_privateer_tier4_4c",
	"escort_duty_tatooine_privateer_tier4_1", "rescue_duty_tatooine_privateer_tier4_1", "recovery_duty_tatooine_privateer_tier4_1", "destroy_duty_tatooine_privateer_tier4_1",
}

local G = N.GLOBALS

N.STORY = { G[1], G[2], G[3], G[4], G[5], G[6], G[7], G[8], G[9], G[10], G[11], G[12] }
N.DUTIES = { G[13], G[14], G[15], G[16] }
N.HEADS = { G[1], G[3], G[6], G[10] }

-- mission n -> chain (global names, in getSpaceQuestChain order: the failure child of 3b comes after the success children, I-6)
N.CHAINS = {
	{ G[1], G[2] },
	{ G[3], G[4], G[5] },
	{ G[6], G[7], G[9], G[8] },
	{ G[10], G[11], G[12] },
}

-- mission n -> the members a winning run completes (3c_sa is the failure detour)
N.WON = {
	{ G[1], G[2] },
	{ G[3], G[4], G[5] },
	{ G[6], G[7], G[9] },
	{ G[10], G[11], G[12] },
}

local L, D, T4, E = "space_lok", "space_dantooine", "space_tatooine", "space_endor"

-- global -> { class, type, name, zone }
N.IDENTITY = {}

do
	local rows = {
		{ 1, "SpaceDeliveryScreenplay", "delivery", "tatooine_privateer_tier4_1a", L },
		{ 2, "SpaceDeliveryNoPickupScreenplay", "delivery_no_pickup", "tatooine_privateer_tier4_1b", D },
		{ 3, "SpaceRecoveryScreenplay", "recovery", "tatooine_privateer_tier4_2a", D },
		{ 4, "SpaceRecoveryScreenplay", "recovery", "tatooine_privateer_tier4_2b", D },
		{ 5, "SpaceSurvivalScreenplay", "survival", "tatooine_privateer_tier4_2c", D },
		{ 6, "SpaceInspectScreenplay", "inspect", "tatooine_privateer_tier4_3a", D },
		{ 7, "SpaceAssassinateScreenplay", "assassinate", "tatooine_privateer_tier4_3b", T4 },
		{ 8, "SpaceSurpriseAttackScreenplay", "destroy_surpriseattack", "tatooine_privateer_tier4_3c_sa", T4 },
		{ 9, "SpaceRecoveryScreenplay", "recovery", "tatooine_privateer_tier4_3c", E },
		{ 10, "SpaceAssassinateScreenplay", "assassinate", "tatooine_privateer_tier4_4a", L },
		{ 11, "SpaceAssassinateScreenplay", "assassinate", "tatooine_privateer_tier4_4b", L },
		{ 12, "SpaceAssassinateScreenplay", "assassinate", "tatooine_privateer_tier4_4c", D },
		{ 13, "SpaceDutyEscortScreenplay", "escort_duty", "tatooine_privateer_tier4_1", L },
		{ 14, "SpaceDutyRescueScreenplay", "rescue_duty", "tatooine_privateer_tier4_1", L },
		{ 15, "SpaceDutyRecoveryScreenplay", "recovery_duty", "tatooine_privateer_tier4_1", D },
		{ 16, "SpaceDutyDestroyScreenplay", "destroy_duty", "tatooine_privateer_tier4_1", D },
	}

	-- the order of N.GLOBALS and of these rows is the Content contract 1 order
	for _, r in ipairs(rows) do
		N.IDENTITY[G[r[1]]] = { class = r[2], type = r[3], name = r[4], zone = r[5] }
	end
end

-- Content contract 2: the squadron object's constants
N.QUEST_STRINGS = {
	TIER4_QUEST_STRING_1 = { type = "delivery", name = "tatooine_privateer_tier4_1a" },
	TIER4_QUEST_STRING_1_SIDE1 = { type = "delivery_no_pickup", name = "tatooine_privateer_tier4_1b" },
	TIER4_QUEST_STRING_2 = { type = "recovery", name = "tatooine_privateer_tier4_2a" },
	TIER4_QUEST_STRING_2_SIDE1 = { type = "recovery", name = "tatooine_privateer_tier4_2b" },
	TIER4_QUEST_STRING_2_SIDE2 = { type = "survival", name = "tatooine_privateer_tier4_2c" },
	TIER4_QUEST_STRING_3 = { type = "inspect", name = "tatooine_privateer_tier4_3a" },
	TIER4_QUEST_STRING_3_SIDE1 = { type = "assassinate", name = "tatooine_privateer_tier4_3b" },
	TIER4_QUEST_STRING_3_SIDE2 = { type = "recovery", name = "tatooine_privateer_tier4_3c" },
	TIER4_QUEST_STRING_3_FAIL1 = { type = "destroy_surpriseattack", name = "tatooine_privateer_tier4_3c_sa" },
	TIER4_QUEST_STRING_4 = { type = "assassinate", name = "tatooine_privateer_tier4_4a" },
	TIER4_QUEST_STRING_4_SIDE1 = { type = "assassinate", name = "tatooine_privateer_tier4_4b" },
	TIER4_QUEST_STRING_4_SIDE2 = { type = "assassinate", name = "tatooine_privateer_tier4_4c" },
	TIER4_QUEST_STRING_DUTY_1 = { type = "escort_duty", name = "tatooine_privateer_tier4_1" },
	TIER4_QUEST_STRING_DUTY_2 = { type = "rescue_duty", name = "tatooine_privateer_tier4_1" },
	TIER4_QUEST_STRING_DUTY_3 = { type = "recovery_duty", name = "tatooine_privateer_tier4_1" },
	TIER4_QUEST_STRING_DUTY_4 = { type = "destroy_duty", name = "tatooine_privateer_tier4_1" },
	TIER4_MET_KEY = "SmugglerSquadronScreenplay:metTier4",
}

-- the 16 quest strings resetNirameQuests clears, in the order of the contract
N.RESET_STRINGS = {
	"TIER4_QUEST_STRING_1", "TIER4_QUEST_STRING_1_SIDE1", "TIER4_QUEST_STRING_2", "TIER4_QUEST_STRING_2_SIDE1", "TIER4_QUEST_STRING_2_SIDE2",
	"TIER4_QUEST_STRING_3", "TIER4_QUEST_STRING_3_SIDE1", "TIER4_QUEST_STRING_3_SIDE2", "TIER4_QUEST_STRING_3_FAIL1",
	"TIER4_QUEST_STRING_4", "TIER4_QUEST_STRING_4_SIDE1", "TIER4_QUEST_STRING_4_SIDE2",
	"TIER4_QUEST_STRING_DUTY_1", "TIER4_QUEST_STRING_DUTY_2", "TIER4_QUEST_STRING_DUTY_3", "TIER4_QUEST_STRING_DUTY_4",
}

-- the quest-name part of the :attempted / :reward keys (head names), mission n = 1..4
N.STATUS_NAMES = { "tatooine_privateer_tier4_1a", "tatooine_privateer_tier4_2a", "tatooine_privateer_tier4_3a", "tatooine_privateer_tier4_4a" }
N.MET_SUFFIX = "SmugglerSquadronScreenplay:metTier4"

-- the 9 keys resetNirameQuests removes
function N.statusKeys()
	local out = {}

	for n = 1, 4 do
		out[#out + 1] = N.STATUS_NAMES[n] .. ":attempted"
		out[#out + 1] = N.STATUS_NAMES[n] .. ":reward"
	end

	out[#out + 1] = N.MET_SUFFIX

	return out
end

-- Content contract 3: MISSIONS (head, questString, endString)
N.MISSIONS = {
	{ n = 1, head = G[1], questString = "TIER4_QUEST_STRING_1", endString = "TIER4_QUEST_STRING_1_SIDE1", chain = N.CHAINS[1], won = N.WON[1], status = N.STATUS_NAMES[1],
		failed = "m1_failed", reward = "m1_reward", brief = "m1_brief" },
	{ n = 2, head = G[3], questString = "TIER4_QUEST_STRING_2", endString = "TIER4_QUEST_STRING_2_SIDE2", chain = N.CHAINS[2], won = N.WON[2], status = N.STATUS_NAMES[2],
		failed = "m2_failed", reward = "m2_reward", brief = "m2_brief" },
	{ n = 3, head = G[6], questString = "TIER4_QUEST_STRING_3", endString = "TIER4_QUEST_STRING_3_SIDE2", chain = N.CHAINS[3], won = N.WON[3], status = N.STATUS_NAMES[3],
		failed = "m3_failed", reward = "m3_reward", brief = "m3_brief" },
	{ n = 4, head = G[10], questString = "TIER4_QUEST_STRING_4", endString = "TIER4_QUEST_STRING_4_SIDE2", chain = N.CHAINS[4], won = N.WON[4], status = N.STATUS_NAMES[4],
		failed = "m4_failed", reward = "m4_reward", brief = "m4_brief" },
}

N.DUTY_SCREENS = {
	duty_escort = G[13], duty_rescue = G[14], duty_recovery = G[15], duty_destroy = G[16],
}

-- the screens that show the duty menu and the reply sid of each duty (menu order)
N.DUTY_MENUS = { "duty_menu", "tier4_incomplete", "here_for_work" }
N.DUTY_REPLIES = {
	{ sid = "s_412dc22e", screen = "duty_escort" }, { sid = "s_4bb3bd9d", screen = "duty_rescue" },
	{ sid = "s_aa6112c9", screen = "duty_recovery" }, { sid = "s_fcb2db97", screen = "duty_destroy" },
	{ sid = "s_694ce3f1", screen = "duty_explain" },
}

-- the screens that grant a mission (START_SCREENS) -> mission (14)
N.START_SCREENS = {
	m1_retry_a = 1, m1_retry_b = 1, m1_accept_a = 1, m1_accept_b = 1,
	m2_retry_a = 2, m2_retry_b = 2, m2_accept = 2,
	m3_retry_a = 3, m3_retry_b = 3, m3_accept = 3,
	m4_retry_a = 4, m4_retry_b = 4, m4_accept_a = 4, m4_accept_b = 4,
}

N.REWARD_SCREENS = { m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4 }
N.MET_SCREENS = { intro_busy = true }
N.TIER_SCREENS = { transfer = true, here_for_work = true }

-- TRAIN_CHOICES in menu order (J:1885-1980): skill, topic reply (C-1), the answer screen of mission 1 and its dialog line
N.TRAIN = {
	{ x = "starships", skill = "pilot_neutral_starships_04", reply = "s_842279cd", trained = "m1_trained_starships", answer = "s_bdae1e2f" },
	{ x = "weapons", skill = "pilot_neutral_weapons_04", reply = "s_dbb3b0b0", trained = "m1_trained_weapons", answer = "s_c40a86d2" },
	{ x = "procedures", skill = "pilot_neutral_procedures_04", reply = "s_ee28691a", trained = "m1_trained_procedures", answer = "s_e3cee4d9" },
	{ x = "droid", skill = "pilot_neutral_droid_04", reply = "s_71d852f5", trained = "m1_trained_droid", answer = "s_b00344d" },
}

N.TRAINED_BRIEFS = { [2] = "m2_brief_trained", [3] = "m3_brief", [4] = "m4_brief_trained" }

N.TIER3_SKILLS = {}

for i, t in ipairs(B.TRAIN) do
	N.TIER3_SKILLS[i] = t.skill
end

N.MASTER = "pilot_neutral_master"
N.CREDITS = 10000
N.XP_COST = 1000000

-- Appendix D: one path per grant screen (from, replies)
N.GRANT_PATHS = {
	m1_retry_a = { "m1_failed", { "s_3ff5bba1", "s_559912" } },
	m1_retry_b = { "m1_failed", { "s_3c7012a7", "s_190e0e72", "s_900f01d1" } },
	m1_accept_a = { "m1_brief", { "s_5c05ecff", "s_b8dd8b3d", "s_59209e57", "s_6c251948", "s_fc7d0eed", "s_741df7ed", "s_3f68df7d", "s_fc7d0eed" } },
	m1_accept_b = { "m1_brief", { "s_5c05ecff", "s_b8dd8b3d", "s_59209e57", "s_6c251948", "s_fc7d0eed", "s_741df7ed", "s_3f68df7d", "s_6c251948" } },
	m2_retry_a = { "m2_failed", { "s_58362a8d", "s_7e0dff76" } },
	m2_retry_b = { "m2_failed", { "s_db089cf0", "s_df1485b", "s_f2648004" } },
	m2_accept = { "m2_brief", { "s_4d999afa", "s_6598178f", "s_908cfde5", "s_85c8a240", "s_4bef9ff9" } },
	m3_retry_a = { "m3_failed", { "s_3d6e04e6", "s_c3363bcd", "s_a587c342", "s_a38a9e82", "s_851d7ea3" } },
	m3_retry_b = { "m3_failed", { "s_351c69aa", "s_b7e5af8c", "s_36a61f55" } },
	m3_accept = { "m3_brief", { "s_a87f150c", "s_c758f78a", "s_658f174d", "s_e79eddec" } },
	m4_retry_a = { "m4_failed", { "s_87d7e908" } },
	m4_retry_b = { "m4_failed", { "s_b857b065" } },
	m4_accept_a = { "m4_brief", { "s_17dede1", "s_ad973bd9", "s_da3439a6", "s_e61fa67b", "s_4bef9ff9" } },
	m4_accept_b = { "m4_brief", { "s_17dede1", "s_ad973bd9", "s_da3439a6", "s_4ca03ddb", "s_30860224" } },
}

-- Data mapping 3: the NGE slots and what fills them
N.SLOT_REPLY = { s_69 = "s_fc27931b", s_364 = "s_5866c569", s_403 = "s_71d95498", s_378 = "s_67e6df55" }
N.SLOT_NPC = { s_350 = { "s_593a67cd", "intro" } }

N.SCREENS = require("smuggler_tier4_screens_data")
N.TEXT = require("smuggler_tier4_client_text")

function N.screenRow(id)
	for _, row in ipairs(N.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (135), sorted
function N.screenIds()
	local out = {}

	for i, row in ipairs(N.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- The client ids this feature uses: the dialog of every screen, every static reply of Appendix A and the four topic replies (245 = the STF lines)
function N.usedIds()
	local set = {}

	for _, row in ipairs(N.SCREENS) do
		set[row.sid] = true

		for _, o in ipairs(row.options) do
			set[o[1]] = true
		end
	end

	for _, t in ipairs(N.TRAIN) do
		set[t.reply] = true
	end

	local out = {}

	for id in pairs(set) do
		out[#out + 1] = id
	end

	table.sort(out)
	return out
end

-- Appendix C: Karrde's K9 screen
N.KARRDE_K9 = { id = "tier4_done", sid = "s_2d0c7400", animation = "slow_down", stop = true, options = {} }

---------------------------------------------------------------------------------------------
-- The oracle: values from the SWG-Source fixtures
---------------------------------------------------------------------------------------------

local trunc = M.trunc
local readFile = M.readFile

N.trunc = trunc
N.readFile = readFile

N.ZONES = { "lok", "dantooine", "tatooine", "endor" }

local buildoutCache = {}

-- { nav = name -> { x, z, y }, spawners = list of { name, x, z, y } (file order) } of the zone's excerpt
function N.buildout(zone)
	zone = zone:gsub("^space_", "")

	if buildoutCache[zone] == nil then
		local tab = H.fixture("space_zones/buildout/space_" .. zone .. ".smuggler_tier4_points.tab")
		local nav, spawners = {}, {}

		for _, rec in ipairs(tab.records) do
			local vars = rec:get("strObjVars") or ""
			local name = vars:match("nav_name|4|([^|]+)|")
			local x, z, y = trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ"))

			if name ~= nil then
				nav[name] = { x, z, y }
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

-- The rewards of the four missions, parsed from NJ: giveReward(player, "<type>", "<name>", <credits>, "<item>"). Returns "type/name" -> { credits, item }
function N.rewards()
	local java = readFile(N.NJ)
	local out = {}

	if java == nil then
		return out
	end

	for questType, name, credits, item in java:gmatch('giveReward%(player, "([%w_]+)", "([%w_]+)", (%d+), "([^"]+)"%)') do
		out[questType .. "/" .. name] = { credits = tonumber(credits), item = item }
	end

	return out
end

function N.fixtureOf(global)
	local id = N.IDENTITY[global]

	return H.questFixture(id.type, id.name)
end

-- Points of a .tab column: { name, zone, x, z, y } from the buildout excerpts
function N.pointsOf(rec, column)
	local out = {}

	for i, value in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(value)
		local xyz = N.buildout(zone).nav[name]

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

-- the global (of the 16) that the `column` ("triggerArg" / "triggerArg2") of `global` names, or nil
local function childOf(global, column)
	local rec = N.fixtureOf(global)

	if rec:get("triggerEvent") ~= "splitquest" then
		return nil
	end

	local ref = rec:get(column or "triggerArg")

	if ref == nil or ref == "" then
		return nil
	end

	local t, n = H.Tab.splitQuestRef(ref)

	return t .. "_" .. n
end

N.childOf = childOf

-- Data mapping 1, derived from the fixtures. Returns { [global] = whole table (Appendix B) }.
function N.expected()
	local rewards = N.rewards()
	local COMPLETION = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION
	local BIDIRECTIONAL = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL
	local out = {}
	local parentOf = {}

	for _, global in ipairs(N.STORY) do
		for _, column in ipairs({ "triggerArg", "triggerArg2" }) do
			local c = childOf(global, column)

			if c ~= nil and parentOf[c] == nil then
				parentOf[c] = global
			end
		end
	end

	for _, global in ipairs(N.GLOBALS) do
		local id = N.IDENTITY[global]
		local rec = N.fixtureOf(global)
		local t = { className = global, questType = id.type, questName = id.name, questZone = rec:get("questZone") }
		local isDuty = id.type:match("_duty$") ~= nil
		local isHead = not isDuty and parentOf[global] == nil

		if isHead then
			local rw = rewards[id.type .. "/" .. id.name]

			assert(rw ~= nil, "NJ has no giveReward for " .. id.type .. "/" .. id.name)
			t.creditReward = rw.credits
			t.itemReward = { { species = { -1 }, item = rw.item } }
		elseif not isDuty then
			local pid = N.IDENTITY[parentOf[global]]

			t.parentQuest, t.parentQuestType, t.parentQuestName = parentOf[global], pid.type, pid.name
		end

		local child = childOf(global)

		if child ~= nil then
			local cid = N.IDENTITY[child]

			t.sideQuest, t.sideQuestType, t.sideQuestName = true, cid.type, cid.name
			t.sideQuestDelay = (rec:num("triggerDelay") or 0) + 5

			if rec:get("triggerSplitCondition") == "both" then
				local fail = N.IDENTITY[childOf(global, "triggerArg2")]

				t.sideQuestSplitType = BIDIRECTIONAL
				t.sideFailQuestType, t.sideFailQuestName = fail.type, fail.name
			else
				t.sideQuestSplitType = COMPLETION
			end
		else
			t.sideQuest, t.sideQuestType = false, ""
		end

		local ty = id.type

		if ty == "delivery" then
			t.pickupPoint = plain(N.pointsOf(rec, "pickupPoint")[1])

			local dp = N.pointsOf(rec, "deliveryPoint")[1]

			t.deliveryPoint = plain(dp)
			t.deliveryZone = dp.zone
			t.pickupShip, t.deliveryShip = rec:get("pickupShip"), rec:get("deliveryShip")
			t.attackShipLists, t.attackPeriod, t.attackListType = attackLists(rec), rec:num("attackPeriod"), listType(rec, SpaceDeliveryScreenplay)
		elseif ty == "delivery_no_pickup" then
			t.deliveryShip, t.deliveryPoint = rec:get("deliveryShip"), plain(N.pointsOf(rec, "deliveryPoint")[1])
			t.attackShipLists, t.attackPeriod, t.attackListType = attackLists(rec), rec:num("attackPeriod"), listType(rec, SpaceDeliveryScreenplay)
		elseif ty == "recovery" then
			local m = rec:num("numResponses")
			local conv = rec:get("recoveryAppearance"):gsub("([^/]+)$", "shared_%1")

			t.arrivalDelay, t.recoveryDelay, t.recoverShip = rec:num("targetArrivalDelay"), rec:num("targetRecoverTime"), rec:get("targetShipType")
			t.recoveryConversationMobile = conv
			t.escortShips = rec:list("targetEscort")
			t.preRecoveryPoints = numbered(N.pointsOf(rec, "escortPath"), { radius = 250 }, "escortNumber")
			t.recoveryPoints = numbered(N.pointsOf(rec, "recoveryPath"), { radius = 250 }, "escortNumber")
			t.attackDelay, t.attackShips = rec:num("attackPeriod"), attackLists(rec)
			t.tauntData = { panicCount = m, thanksCount = m }
		elseif ty == "assassinate" then
			t.arrivalDelay, t.failTimer, t.mustDestroyEscort = rec:num("targetArrivalDelay"), 20, rec:num("mustDestroyEscort") == 1
			t.assassinateSpawns = { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }
			t.targetPatrols = numbered(N.pointsOf(rec, "escortPath"))
		elseif ty == "destroy_surpriseattack" then
			-- FN-7: SWG spawns the summed count (5) of the first type only
			local count = 0

			for _, n in ipairs(rec:list("shipCount")) do
				count = count + tonumber(n)
			end

			t.surpriseAttackShips = { zone = rec:get("questZone"), spawns = { { count = count, shipName = rec:list("shipType")[1] } } }
		elseif ty == "inspect" then
			local want = {}

			for _, value in ipairs(rec:list("validSpawns")) do
				local zone, name = H.Tab.splitNavPoint(value)

				for _, sp in ipairs(N.buildout(zone).spawners) do
					if sp.name == name then
						want[#want + 1] = { spawnName = name, x = sp[1], z = sp[2], y = sp[3] }
					end
				end
			end

			t.shipList, t.validSpawns, t.giveSpawnWaypoint, t.cargo = rec:list("shipList"), want, rec:num("giveSpawnWaypoint"), rec:get("cargo")
		elseif ty == "survival" then
			local p = N.pointsOf(rec, "transmissionPoint")[1]

			t.transmissionPoint = plain(p)
			t.totalTransmissionTime, t.timesToUpdateProgress = rec:num("totalTransmissionTime"), rec:num("timesToUpdateProgress")
			t.transmissionStartDelay, t.delayToFirstAttack = rec:num("transmissionStartDelay"), rec:num("delayToFirstAttack")
			t.attackShipLists, t.attackPeriod, t.attackListType = attackLists(rec), rec:num("attackPeriod"), listType(rec, SpaceSurvivalScreenplay)
		elseif ty == "escort_duty" then
			local m = rec:num("numResponses")

			t.creditReward, t.creditKillBonus = rec:num("reward"), rec:num("killReward")
			t.escortShips = rec:list("escortShipTypes")
			t.escortPoints = numbered(N.pointsOf(rec, "escortPoints"), { zoneName = rec:get("questZone"), radius = 250 }, "escortNumber")
			t.attackDelay, t.attackShips = rec:num("attackPeriod"), attackLists(rec)
			t.tauntData = { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m }
		elseif ty == "rescue_duty" then
			t.creditReward, t.creditKillBonus = rec:num("reward"), rec:num("killReward")
			t.recoveryPath = numbered(N.pointsOf(rec, "recoveryPath"))
			t.targetShipTypes, t.targetArrivalDelay = rec:list("targetShipTypes"), rec:num("targetArrivalDelay")
			t.attackShipLists, t.attackPeriod, t.attackListType = attackLists(rec), rec:num("attackPeriod"), listType(rec, SpaceDutyRescueScreenplay)
			-- FN-8 / D-16: SWG has 0 and no client key for 0; Core3 maps it to the five client variants
			t.numResponses = 5
		elseif ty == "recovery_duty" then
			local m = rec:num("numResponses")

			t.creditReward, t.creditKillBonus, t.numResponses = rec:num("reward"), rec:num("killReward"), m
			t.recoverShips, t.escortShips = rec:list("targetShipTypes"), rec:list("targetEscort")
			t.arrivalDelay, t.recoveryDelay = rec:num("targetArrivalDelay"), rec:num("targetRecoverTime")
			t.preRecoveryPoints = numbered(N.pointsOf(rec, "escortPath"), { radius = 250 }, "escortNumber")
			t.recoveryPoints = numbered(N.pointsOf(rec, "recoveryPath"), { radius = 250 }, "escortNumber")
			t.attackDelay, t.attackShips = rec:num("attackPeriod"), attackLists(rec)
			t.tauntData = { panicCount = m, thanksCount = m }
		elseif ty == "destroy_duty" then
			local lists = {}

			for i = 1, rec:num("shipTypes") do
				lists[i] = rec:list("shipType" .. i)
			end

			t.creditReward = rec:num("reward")
			t.totalLevels, t.totalRounds, t.totalWaves = rec:num("levelsPerDuty"), rec:num("roundsPerLevel"), rec:num("wavesPerRound")
			t.bossShip, t.shipTypes = rec:get("bossType"), lists
		end

		out[global] = t
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

N.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		N.loadErrors[#N.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: everything the tier 3 feature loads (squadrons, Dravis, Karrde, Shamdon, Beissa), then Nirame's template and handler. A missing
-- production file is recorded in N.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function N.load()
	if loaded then
		return
	end

	loaded = true
	B.load()

	for _, e in ipairs(B.loadErrors) do
		N.loadErrors[#N.loadErrors + 1] = e
	end

	try("nirame_sakute_convo.lua", function() H.loadMobile("conversations/space/neutral/smuggler_squadron/nirame_sakute_convo.lua") end)
	try("nirameSakuteConvoHandler.lua", function() H.loadScreenplay("space/conversations/neutral/smuggler_squadron/nirameSakuteConvoHandler.lua") end)
end

function N.problems() return table.concat(N.loadErrors, " | ") end

-- Fails with the load problems when the template or handler could not be loaded
function N.requireConversation(lu)
	N.load()
	lu.assertNotNil(H.conversationTemplateTable(N.TEMPLATE), N.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. N.problems())
	lu.assertNotNil(rawget(_G, N.HANDLER), N.HANDLER .. " is not defined. Load problems: " .. N.problems())
end

function N.quest(global)
	N.load()

	return H.expectGlobal(global, "Smuggler tier 4 quest table (smuggler-tier4-nirame). Load problems: " .. N.problems())
end

-- the squadron object (SmugglerSquadronScreenplay), with the load problems in the failure message
function N.squadron()
	N.load()

	return H.expectGlobal("SmugglerSquadronScreenplay", "Smuggler squadron screenplay object. Load problems: " .. N.problems())
end

function N.handler() return rawget(_G, N.HANDLER) end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = N.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

N.crc = crc

-- state: "complete" | "active" | "none"
function N.setState(player, global, state)
	local key = crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function N.state(player, global)
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
--   won       :attempted, the winning members complete, :reward unset (the reward is waiting)
--   paid      won, :reward set
--   endonly   only the chain end complete (no :attempted)
--   partial   :attempted, the head complete and the end not (a run that stopped inside a split window)
function N.setMission(player, n, state)
	local m = N.MISSIONS[n]

	for _, g in ipairs(m.chain) do
		N.setState(player, g, "none")
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
		for _, g in ipairs(m.won) do
			N.setState(player, g, "complete")
		end
	elseif state == "endonly" then
		N.setState(player, m.won[#m.won], "complete")
	elseif state == "partial" then
		N.setState(player, m.chain[1], "complete")
	elseif state == "active" then
		N.setState(player, m.chain[1], "active")
	end
end

-- Options (all optional; the default is a Smuggler tier 3 graduate: the four tier 2 and tier 3 skills, pilot tier 4 (5 with the four tier 4 skills), no tier 4
-- skill, nothing of tier 4, no XP, a man, a ship, an inventory):
--   t3         list of B.TRAIN indexes of the tier 3 skills held (default all four)
--   t4         list of N.TRAIN indexes (1 starships, 2 weapons, 3 procedures, 4 droid) of the tier 4 skills held
--   mission    { [n] = state } tier 4 mission n (see N.setMission)
--   paid       list of n whose mission is "paid"
--   met        true: the met key (TIER4_MET_KEY) is set
--   master     true: pilot_neutral_master is held
--   duty4      global of a Nirame duty active in the journal
--   xp, pilotTier, and every B.pilot / M.pilot / T.pilot / S.pilot option (pilot, faction, squadron, ship, datapad, duty, zone, inShip, species, inventory,
--   gender, t2, trans, rewarded, ...)
function N.pilot(o)
	o = o or {}
	N.load()

	local bo = {}

	for k, v in pairs(o) do
		if k ~= "t3" and k ~= "t4" and k ~= "mission" and k ~= "paid" and k ~= "met" and k ~= "master" and k ~= "duty4" then
			bo[k] = v
		end
	end

	bo.t3 = o.t3 == nil and { 1, 2, 3, 4 } or o.t3

	local skills = {}

	for _, x in ipairs(bo.skills or {}) do
		skills[#skills + 1] = x
	end

	for _, i in ipairs(o.t4 or {}) do
		skills[#skills + 1] = N.TRAIN[i].skill
	end

	if o.master then
		skills[#skills + 1] = N.MASTER
	end

	bo.skills = skills

	if bo.pilotTier == nil then
		bo.pilotTier = #(o.t4 or {}) == 4 and 5 or 4
	end

	local player = B.pilot(bo)
	local states = {}

	for _, n in ipairs(o.paid or {}) do
		states[n] = "paid"
	end

	for n, state in pairs(o.mission or {}) do
		states[n] = state
	end

	for n, state in pairs(states) do
		N.setMission(player, n, state)
	end

	if o.met then
		H.setQuestStatus(player, N.MET_SUFFIX, 1)
	end

	if o.duty4 then
		N.setState(player, o.duty4, "active")
	end

	return player
end

function N.npc() return H.newNpc({ name = "Nirame Sakute" }) end

function N.requireConversationLoaded()
	N.load()

	if H.conversationTemplateTable(N.TEMPLATE) == nil or rawget(_G, N.HANDLER) == nil then
		error("Nirame's conversation is not loaded. Load problems: " .. N.problems(), 3)
	end
end

-- Talks to Nirame from the first screen. choices as for H.converse.
function N.talk(player, choices)
	N.requireConversationLoaded()

	return H.converse({ template = N.TEMPLATE, player = player, npc = N.npc(), choices = choices })
end

-- The id of the first screen of a fresh talk
function N.firstScreen(player) return N.talk(player)[1].id end

-- Karrde's talk (his template and handler are loaded by N.load)
function N.karrdeTalk(player, choices)
	N.load()

	return T.talk(player, choices)
end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session.
function N.drive(player, startId, choices)
	N.requireConversationLoaded()

	local tmpl = H.conversationTemplate(N.TEMPLATE)
	local handler = rawget(_G, N.HANDLER)
	local npc = N.npc()
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
		error("screen '" .. startId .. "' is not in " .. N.TEMPLATE, 2)
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

N.ids = S.ids
N.optionSids = S.optionSids
N.linksOf = S.linksOf
N.snapshot = M.snapshot

-- Tier 4 skills (of the four) the player holds, in N.TRAIN order
function N.held(player)
	local out = {}

	for _, t in ipairs(N.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

-- Charges the XP of the _04 skills from the fixture (1,000,000 each); without it the fake charges nothing
function N.useSkillCosts()
	local costs = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_neutral_04.tab").records) do
		local name = rec:get("NAME")

		if name ~= nil and name:match("^pilot_neutral_%a+_04$") then
			costs[name] = rec:num("XP_COST")
		end
	end

	H.Engine.config.skillXpCosts = costs

	return costs
end

-- Records the calls of SpaceHelpers:grantSpaceSkill and runs the original. Call N.restore() in tearDown.
local restoreFns = {}

function N.recordGrants()
	local calls = {}
	local orig = SpaceHelpers.grantSpaceSkill

	SpaceHelpers.grantSpaceSkill = function(self, pPlayer, skill, deduct)
		calls[#calls + 1] = { skill = skill, deduct = deduct }

		return orig(self, pPlayer, skill, deduct)
	end

	restoreFns[#restoreFns + 1] = function() SpaceHelpers.grantSpaceSkill = orig end

	return calls
end

function N.restore()
	for _, fn in ipairs(restoreFns) do
		fn()
	end

	restoreFns = {}
end

-- Spies on the startQuest of the listed globals (H.spyOn does not call the original)
function N.spyStarts(globals)
	local spies = {}

	for _, g in ipairs(globals or N.GLOBALS) do
		spies[g] = H.spyOn(N.quest(g), "startQuest")
	end

	return spies
end

-- the sorted list of globals whose startQuest was called, one entry per call
function N.started(spies)
	local out = {}

	for g, calls in pairs(spies) do
		for _ = 1, #calls do
			out[#out + 1] = g
		end
	end

	table.sort(out)
	return out
end

return N
