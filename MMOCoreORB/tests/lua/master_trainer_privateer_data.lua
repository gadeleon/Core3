-- Shared test data and builders for the privateer branches of the two master trainers (Grand Admiral Declann, Admiral Burke), not a test file.
-- Spec: .claude/work/space-master-trainer-privateer/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix P-D, P-B and D).
--
-- It builds on the data modules of the Imperial and Rebel master trainer features (master_trainer_imperial_data / master_trainer_rebel_data), which
-- already know how to load both admirals, build a pilot and talk to him. The spec literals here are copied from the spec, not read from production.
--   P.ADMIRALS            { declann = {...}, burke = {...} }: the module (M), the faction, the side key fields, the privateer tables the spec lists
--   P.pilot(adm, o)       M.pilot with kind = "neutral" by default (a CorSec pilot with the four neutral _04 skills); o as for M.pilot
--   P.talk / P.drive      H.converse from the first screen / from a given screen at the admiral
--   P.rows(adm)           every screen row (Appendix A of the earlier feature plus Appendix P-D / P-B), by id
--   P.swaps(adm, squadron)  the screen swaps the handler applies to that squadron's pilot (Conversation flow 3)
--   P.paths(adm, from, swaps)  every option path from a screen down to an ending, applying the swaps (what a privateer is shown)
--   P.jacket / P.helmet   the privateer reward templates
--   P.load()              the server's load of both admirals (load errors collected)

local H = require("harness")
local I = require("master_trainer_imperial_data")
local R = require("master_trainer_rebel_data")
local SCREENS = require("master_trainer_privateer_screens_data")

local P = {}

P.SCREENS = SCREENS

P.jacket = "object/tangible/wearables/jacket/jacket_ace_privateer.iff"
P.helmet = "object/tangible/wearables/helmet/helmet_fighter_privateer_ace.iff"
P.ITEMS = { P.jacket, P.helmet }
P.MASTER_SKILL = "pilot_neutral_master"
P.CREDITS = { 25000, 50000 }
P.STANDING = { 200, 400 }

-- Content contract 2 and 3: the tables the handlers gain, with exactly these values
P.DECLANN_TABLES = {
	PRIVATEER_START_SCREENS = { priv_m1_accept = 1, priv_m2_accept_a = 2, priv_m2_accept_b = 2 },
	PRIVATEER_REWARD_SCREENS = { priv_m1_reward = 1, priv_master_grant = 2 },
	SIDE_KEY_SCREENS = { priv_m1_accept = "MASTER_MISSION_IMPERIAL_KEY" },
	PRIVATEER_MASTER_SCREEN = "priv_master_grant",
	PRIVATEER_SWAPS = { m1_reward = "priv_m1_reward", master_grant = "priv_master_grant" },
	RSF_SWAPS = { priv_m1_dismissed_corsec = "priv_m1_dismissed_rsf" },
}

P.BURKE_TABLES = {
	PRIVATEER_START_SCREENS = { priv_m1_accept_smuggler = 1, priv_m1_accept_corsec = 1 },
	PRIVATEER_REWARD_SCREENS = { priv_m1_reward = 1, priv_master_grant = 2 },
	SIDE_KEY_SCREENS = { priv_m1_accept_corsec = "MASTER_MISSION_REBEL_KEY" },
	PRIVATEER_MASTER_SCREEN = "priv_master_grant",
	PRIVATEER_SWAPS = { m1_reward = "priv_m1_reward", m2_disappointed = "priv_m2_disappointed" },
}

-- The existing handler tables of the earlier features, which the privateer feature must leave as they are (value equality, I-9)
P.EXISTING_TABLES = {
	declann = {
		MISSIONS = { { head = "destroy_master_imperial_1", questString = "QUEST_STRING_IMPERIAL_1" }, { head = "destroy_master_imperial_2", questString = "QUEST_STRING_IMPERIAL_2" } },
		START_SCREENS = { m1_accept = 1, m1_retry_a = 1, m1_retry_b = 1, m2_accept = 2, m2_retry_a = 2, m2_retry_b = 2 },
		REWARD_SCREENS = { m1_reward = 1, master_grant = 2 },
		STANDING = { 200, 400 },
		MASTER_SKILL = "pilot_imperial_navy_master",
		MASTER_SCREEN = "master_grant",
	},
	burke = {
		MISSIONS = { { head = "destroy_master_rebel_1", questString = "QUEST_STRING_REBEL_1" }, { head = "destroy_master_rebel_2", questString = "QUEST_STRING_REBEL_2" } },
		START_SCREENS = { m1_accept = 1, m1_retry_a = 1, m1_retry_b = 1, m2_accept = 2, m2_retry_a = 2, m2_retry_b = 2 },
		REWARD_SCREENS = { m1_reward = 1, master_grant = 2 },
		STANDING = { 200, 400 },
		MASTER_SKILL = "pilot_rebel_navy_master",
		MASTER_SCREEN = "master_grant",
	},
}

-- The admirals. `squadrons` are the squadrons the admiral serves as privateers; `startKey` is the screen -> mission map of the privateer starts.
P.ADMIRALS = {
	declann = {
		name = "declann", M = I, faction = "imperial", handler = "nialDeclannConvoHandler", tables = P.DECLANN_TABLES,
		screens = SCREENS.declann, squadrons = { "rsf", "corsec" }, sideKey = I.IMPERIAL_KEY, otherKey = I.REBEL_KEY,
		sideKeyField = "MASTER_MISSION_IMPERIAL_KEY", otherKeyField = "MASTER_MISSION_REBEL_KEY",
		statusStem = { "master_imperial_1", "master_imperial_2" }, heads = { "destroy_master_imperial_1", "destroy_master_imperial_2" },
		-- the gate screen of each served squadron, the screen that starts mission 1 for it and mission 2's privateer screens
		gate = { rsf = "privateer_ready_rsf", corsec = "privateer_ready_corsec" },
		gateReply = { rsf = "s_308a9ab1", corsec = "s_8409f60e" },
		m1Start = { rsf = "priv_m1_accept", corsec = "priv_m1_accept" },
		refuses = "working_for_rebellion", refusesSquadron = { smuggler = "smuggler" },
		m2Gate = "priv_m2_brief", m2Starts = { "priv_m2_accept_a", "priv_m2_accept_b" },
		master = "imperial_navy",
	},
	burke = {
		name = "burke", M = R, faction = "rebel", handler = "willhamBurkeConvoHandler", tables = P.BURKE_TABLES,
		screens = SCREENS.burke, squadrons = { "smuggler", "corsec" }, sideKey = R.REBEL_KEY, otherKey = R.IMPERIAL_KEY,
		sideKeyField = "MASTER_MISSION_REBEL_KEY", otherKeyField = "MASTER_MISSION_IMPERIAL_KEY",
		statusStem = { "master_rebel_1", "master_rebel_2" }, heads = { "destroy_master_rebel_1", "destroy_master_rebel_2" },
		gate = { smuggler = "privateer_ready_smuggler", corsec = "privateer_ready_corsec" },
		gateReply = { smuggler = "s_2acaca5d", corsec = "s_dc2fa6d8" },
		m1Start = { smuggler = "priv_m1_accept_smuggler", corsec = "priv_m1_accept_corsec" },
		refuses = "working_for_empire", refusesSquadron = { rsf = "rsf_pilot" },
		m2Gate = "m2_brief", m2Starts = { "m2_accept" },
		master = "rebel_navy",
	},
}

P.ORDER = { "declann", "burke" }

for _, a in pairs(P.ADMIRALS) do
	a.rowsP = {}

	for _, row in ipairs(a.screens) do
		a.rowsP[row.id] = row
	end

	-- every screen of the template: Appendix A of the earlier feature plus the privateer rows
	a.rowsAll = {}

	for _, row in ipairs(a.M.SCREENS) do
		a.rowsAll[row.id] = row
	end

	for _, row in ipairs(a.screens) do
		a.rowsAll[row.id] = row
	end
end

local loadErrors = {}

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		loadErrors[#loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- smuggler-tier1-dravis: surrenderPilot calls SmugglerSquadronScreenplay:resetDravisQuests for a Smuggler, so the server's load must include it
function P.load()
	I.load()
	R.load()
	try("SmugglerSquadronScreenplay", function() H.loadSquadron("SmugglerSquadronScreenplay") end)
end

function P.problems() return I.problems() .. R.problems() .. table.concat(loadErrors, " | ") end

function P.requireConversations(lu)
	I.requireConversation(lu)
	R.requireConversation(lu)
end

function P.rows(adm) return P.ADMIRALS[adm].rowsAll end

-- A privateer in front of the admiral. Defaults: a CorSec pilot with the four neutral _04 skills. o as for M.pilot.
function P.pilot(adm, o)
	local opts = {}

	for k, v in pairs(o or {}) do
		opts[k] = v
	end

	if opts.kind == nil then
		opts.kind = "neutral"
	end

	return P.ADMIRALS[adm].M.pilot(opts)
end

function P.talk(adm, player, choices) return P.ADMIRALS[adm].M.talk(player, choices) end

function P.drive(adm, player, screen, choices) return P.ADMIRALS[adm].M.drive(player, screen, choices) end

function P.firstScreen(adm, player) return P.ADMIRALS[adm].M.firstScreen(player) end

function P.ids(t) return I.ids(t) end

-- Conversation flow 3: the swaps the handler applies, by the pilot's squadron ("corsec", "rsf", "smuggler", false for none)
function P.swaps(adm, squadron)
	local out = {}
	local t = P.ADMIRALS[adm].tables

	for from, to in pairs(t.PRIVATEER_SWAPS) do
		out[from] = to
	end

	if adm == "declann" and squadron == "rsf" then
		for from, to in pairs(t.RSF_SWAPS) do
			out[from] = to
		end
	end

	return out
end

-- Every option path from screen `from` down to a screen with no option, over Appendix A plus the privateer rows, following `swaps` (link target ->
-- screen shown instead) like the handler does. Returns { { replies = {...}, ids = {...} } ... }; ids start with `from`.
function P.paths(adm, from, swaps)
	swaps = swaps or {}

	local rows = P.rows(adm)
	local out = {}

	local function visit(id, replies, ids)
		local row = rows[id]

		assert(row ~= nil, "no row for screen '" .. tostring(id) .. "'")

		if #row.options == 0 then
			out[#out + 1] = { replies = replies, ids = ids }
			return
		end

		for _, o in ipairs(row.options) do
			local r, i = { table.unpack(replies) }, { table.unpack(ids) }
			local target = swaps[o[2]] or o[2]

			r[#r + 1] = o[1]
			i[#i + 1] = target
			visit(target, r, i)
		end
	end

	visit(from, {}, { from })

	return out
end

-- number of times `id` occurs in the list
function P.count(list, id)
	local n = 0

	for _, x in ipairs(list) do
		if x == id then
			n = n + 1
		end
	end

	return n
end

-- Spec Appendix D: one reply path per privateer action screen (`from` is the screen the path starts on: a gate screen or the screen a talk opens on)
P.PATHS = {}

do
	local function add(adm, screen, from, replies, squadron)
		local out = {}

		for i, r in ipairs(replies) do
			out[i] = "s_" .. r
		end

		P.PATHS[#P.PATHS + 1] = { adm = adm, screen = screen, from = from, replies = out, squadron = squadron }
	end

	add("declann", "priv_m1_accept", "privateer_ready_rsf", { "308a9ab1", "7964ad2d", "bc9b4055", "85b8ffbd", "fd661a34", "78dfc859", "92172df0", "60d3f4f8", "2bd3a43c" }, "rsf")
	add("declann", "priv_m1_accept", "privateer_ready_corsec", { "8409f60e", "c5aa2921", "87ccb642", "7b3a873", "85b8ffbd", "fd661a34", "15f15e84", "af2fc12f", "33d1d488", "bcb643d", "63f7aad9", "2bd3a43c" }, "corsec")
	add("declann", "priv_m1_reward", "m1_won", { "b8ead210", "3ffe1ded", "a8ea09e9" }, "corsec")
	add("declann", "priv_m2_accept_a", "priv_m2_brief", { "a2bd8a18", "6844241f", "af2fc12f", "9e28d2b0", "ef6b4924", "5ac61a82", "fd386cda" }, "corsec")
	add("declann", "priv_m2_accept_b", "priv_m2_brief", { "8f760eed", "9e28d2b0", "7cc631fe", "9bbd1090" }, "corsec")
	add("declann", "priv_master_grant", "m2_won", { "f010d9ab", "2f52e0af", "beb9353a" }, "corsec")
	add("declann", "priv_master_grant", "m2_won", { "f010d9ab", "6aa8adaf", "6a66a025", "377d1a96" }, "corsec")
	add("burke", "priv_m1_accept_smuggler", "privateer_ready_smuggler", { "2acaca5d", "24a07bd4", "78ce5241", "e7f9b26f", "8f3f7918", "8964c03a", "174c76a5", "c10e0254" }, "smuggler")
	add("burke", "priv_decline", "privateer_ready_smuggler", { "2acaca5d", "24a07bd4", "78ce5241", "e7f9b26f", "8f3f7918", "8964c03a", "174c76a5", "35c0388d" }, "smuggler")
	add("burke", "priv_m1_accept_corsec", "privateer_ready_corsec", { "dc2fa6d8", "e8d6a9e7", "ee795f66", "3d93239d", "92ad6ffe", "8964c03a", "174c76a5", "647683fc" }, "corsec")
	add("burke", "priv_corsec_decline", "privateer_ready_corsec", { "dc2fa6d8", "e8d6a9e7", "ee795f66", "3d93239d", "92ad6ffe", "8964c03a", "174c76a5", "d646c11" }, "corsec")
	add("burke", "priv_m1_reward", "m1_won", { "d02bfc3b", "f00f629f", "7cbd5de5" }, "corsec")
	add("burke", "m2_accept", "m2_brief", { "c68b1dd3", "ca1a4aa4", "a6fb8def", "7a052bd2", "cba67818", "5bd6bf77" }, "corsec")
	add("burke", "priv_master_grant", "m2_won", { "1da9fe53", "3f6a8711", "8d7967cc", "5869e64b" }, "corsec")
end

-- The privateer states a talk can open on, as pilot options (the gate each one satisfies). m = mission map, paid = paid list.
P.STATE = {
	m1_won = { mission = { [1] = "won" } },
	m1_failed = { mission = { [1] = "failed" } },
	m2_brief = { paid = { 1 } },
	m2_failed = { paid = { 1 }, mission = { [2] = "failed" } },
	m2_won = { paid = { 1 }, mission = { [2] = "won" } },
}

P.STATE.priv_m2_brief = P.STATE.m2_brief

-- the pilot options for a path that starts on `from` (screens that no gate opens on need no state)
function P.optionsFor(from, squadron)
	local o = {}

	for k, v in pairs(P.STATE[from] or {}) do
		o[k] = v
	end

	o.squadron = squadron

	return o
end

-- Records the calls of SpaceHelpers.startSpaceQuestChain and runs the original; restore with P.restore()
local origChain

function P.recordChains()
	local calls = {}

	origChain = origChain or SpaceHelpers.startSpaceQuestChain

	SpaceHelpers.startSpaceQuestChain = function(self, pPlayer, pNpc, head)
		calls[#calls + 1] = head

		return origChain(self, pPlayer, pNpc, head)
	end

	return calls
end

function P.restore()
	if origChain ~= nil then
		SpaceHelpers.startSpaceQuestChain = origChain
	end

	I.restore()
	R.restore()
end

-- Spies on the startQuest of all four master quests (H.spyOn does not call the original); returns { [global] = calls }
function P.spyAllStarts()
	local spies = {}

	for _, adm in ipairs(P.ORDER) do
		for _, g in ipairs(P.ADMIRALS[adm].M.GLOBALS) do
			spies[g] = H.spyOn(P.ADMIRALS[adm].M.quest(g), "startQuest")
		end
	end

	return spies
end

-- the items given to the player's inventory (templates) and the argument counts
function P.itemsGiven(player) return I.itemsGiven(player) end

function P.standing(adm, player) return P.ADMIRALS[adm].M.standing(player) end

-- the state of mission n's journal entry at the admiral ("none" | "active" | "complete")
function P.state(adm, player, n)
	return P.ADMIRALS[adm].M.state(player, P.ADMIRALS[adm].heads[n])
end

function P.setState(adm, player, n, state)
	return P.ADMIRALS[adm].M.setState(player, P.ADMIRALS[adm].heads[n], state)
end

function P.hasSkill(player, skill) return CreatureObject(player):hasSkill(skill) end

-- the "skill learned" system messages the pilot got
function P.learned(player)
	local n = 0

	for _, m in ipairs(H.messageLog(player)) do
		if tostring(m.id):find("prose_skill_learned", 1, true) then
			n = n + 1
		end
	end

	return n
end

-- the status key of an admiral's mission (without the player id)
function P.key(adm, n, suffix) return P.ADMIRALS[adm].statusStem[n] .. ":" .. suffix end

return P
