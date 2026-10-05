-- Shared data and helpers for the space-trainer-rewards tests (not a test file).
-- Spec: .claude/work/space-trainer-rewards/01-spec.md
--
-- The R-rows, the 12-row trainer map, the per-file `:rewardPlayer` counts, the four never-called SWG actions and the one D-11
-- exception are copied from the spec. The expected rewards of the conformance sweep come from the SWG java fixtures
-- (fixtures/script/conversation/*.java, byte copies of SWG-Source), never from the Core3 tables under test.
--
--   D.load()                      -- the three squadrons and the twelve trainer handlers
--   D.TRAINERS / D.ORDER          -- the trainer map (key -> row)
--   D.R_ROWS                      -- the 16 rows R-1..R-16 of the spec's sweep table
--   D.java(name)                  -- { rewards = { {action, type, name, credits, item, line, calls} }, calls = { action -> n } }
--   D.heads(trainer, lookup)      -- the pay heads of one handler: { {global, quest} }, from its source
--   D.check(trainer, head, rewards) -- list of mismatch strings (I-2) for one head
--   D.sweep(lookup)               -- every head of every handler -> { failures = { global -> {messages} }, heads, matched }
--   D.item(suffix)                -- "object/tangible/ship/components/" .. suffix .. ".iff"

local H = require("harness")

local D = {}

D.BASE_COMMIT = "1d980a2452"
D.COMPONENT_PREFIX = "object/tangible/ship/components/"

function D.item(suffix) return D.COMPONENT_PREFIX .. suffix .. ".iff" end

D.SQUADRON_DIR = "bin/scripts/screenplays/space/squadrons/"
D.HANDLER_DIR = "bin/scripts/screenplays/space/conversations/"
D.CSP = D.SQUADRON_DIR .. "CorsecSquadronScreenplay.lua"
D.RSP = D.SQUADRON_DIR .. "RsfSquadronScreenplay.lua"
D.HSP = D.SQUADRON_DIR .. "HavocSquadronScreenplay.lua"
D.SQL = "bin/scripts/screenplays/space/SpaceQuestLogic.lua"
D.SH = "bin/scripts/utils/space_helpers.lua"
D.AQZOW = D.HANDLER_DIR .. "rebel/havoc_squadron/aqzowConvoHandler.lua"

D.SQUADRONS = { "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay" }

---------------------------------------------------------------------------------------------
-- The trainer map (spec "Source inventory"). `count` = occurrences of ":rewardPlayer(" in the handler source (I-1).
-- form: direct (`<global>:rewardPlayer(`), dulios (`_G[MISSION_HEADS[n]]`, file local), questGlobal (`self:questGlobal(self.MISSIONS[n].main)`).
---------------------------------------------------------------------------------------------

D.ORDER = { "rhea", "rikkh", "ramna", "turoldine", "dinge", "kaydine", "dulios", "imler", "kreezo", "viopa", "aqzow", "arkon" }

local C, R, V = "neutral/corsec_squadron/", "neutral/rsf_squadron/", "rebel/havoc_squadron/"

D.TRAINERS = {
	rhea = { label = "Rhea", handler = C .. "rheaConvoHandler.lua", java = "corellia_privateer_trainer", count = 4, form = "direct" },
	rikkh = { label = "Rikkh", handler = C .. "rikkhConvoHandler.lua", java = "corellia_privateer_trainer_2", count = 4, form = "direct" },
	ramna = { label = "Ramna", handler = C .. "ramnaConvoHandler.lua", java = "corellia_privateer_tier3", count = 4, form = "direct" },
	turoldine = { label = "Turoldine", handler = C .. "turoldineConvoHandler.lua", java = "corellia_privateer_tier4", count = 4, form = "direct" },
	dinge = { label = "Dinge", handler = R .. "dingeConvoHandler.lua", java = "naboo_privateer_trainer_1", count = 4, form = "direct" },
	kaydine = { label = "Kaydine", handler = R .. "kaydineConvoHandler.lua", java = "naboo_privateer_trainer_2", count = 4, form = "direct" },
	dulios = { label = "Dulios", handler = R .. "duliosConvoHandler.lua", java = "naboo_privateer_tier3", count = 1, form = "dulios" },
	imler = {
		label = "Imler", handler = R .. "imlerConvoHandler.lua", java = "naboo_privateer_tier4", count = 1, form = "questGlobal",
		handlerGlobal = "imlerConvoHandler", squadron = "RsfSquadronScreenplay",
	},
	kreezo = { label = "Kreezo", handler = V .. "kreezoConvoHandler.lua", java = "corellia_rebel_trainer_1", count = 4, form = "direct" },
	viopa = { label = "Viopa", handler = V .. "viopaConvoHandler.lua", java = "lok_rebel_trainer_2", count = 4, form = "direct" },
	aqzow = { label = "Aqzow", handler = V .. "aqzowConvoHandler.lua", java = "corellia_rebel_tier3", count = 4, form = "direct" },
	arkon = {
		label = "Arkon", handler = V .. "arkonConvoHandler.lua", java = "corellia_rebel_tier4", count = 1, form = "questGlobal",
		handlerGlobal = "arkonConvoHandler", squadron = "HavocSquadronScreenplay",
	},
}

-- The handler directories scanned for "every *ConvoHandler.lua is in the map or has no :rewardPlayer"
D.HANDLER_DIRS = { C, R, V }
D.NO_PAY_HANDLERS = { ["vrakConvoHandler.lua"] = true } -- SWG lok_rebel_trainer_2_smuggler.java has no giveReward

-- SWG reward actions that no conversation branch reaches (0 call sites in their java): excluded by name (I-3)
D.UNREACHABLE = {
	tat_priv_quest_trans = "corellia_privateer_trainer_2",
	corellia_privateer_master = "corellia_privateer_tier4",
	naboo_privateer_master = "naboo_privateer_tier4",
	corellia_rebel_master = "corellia_rebel_tier4",
}

-- D-11: the one named exception of the conformance sweep (Kreezo M3, pre-NGE substitution)
D.EXCEPTION = {
	trainer = "kreezo",
	questName = "corellia_rebel_3",
	swg = "object/tangible/wearables/bodysuit/rebel_bodysuit_s14.iff",
	core3 = "object/tangible/wearables/bodysuit/bodysuit_s14.iff",
	reason = "rebel_bodysuit_s14.iff is in no pre-NGE client archive; bodysuit_s14.iff is (D-11)",
}

---------------------------------------------------------------------------------------------
-- The 16 rows (spec sweep table R-1..R-16). `faction` = rebel standing the trainer adds per mission reward (D-10 for Aqzow).
---------------------------------------------------------------------------------------------

local function row(id, trainer, mission, global, credits, suffix, javaLine)
	return { id = id, trainer = trainer, mission = mission, global = global, credits = credits, item = D.item(suffix), javaLine = javaLine }
end

D.R_ROWS = {
	row("R-1", "rikkh", 2, "escort_corellia_privateer_14", 5000, "weapon/wpn_mission_reward_neutral_hk_military_blaster", 278),
	row("R-2", "rikkh", 3, "inspect_corellia_privateer_15", 5000, "shield_generator/shd_mission_reward_neutral_koensayr_ds23", 285),
	row("R-3", "rikkh", 4, "assassinate_corellia_privateer_tier2_4a", 5000, "droid_interface/ddi_mission_reward_neutral_sorosuub_w19", 292),
	row("R-4", "turoldine", 1, "patrol_corellia_privateer_tier4_1a", 10000, "booster/bst_mission_reward_neutral_mandal_q_series", 340),
	row("R-5", "turoldine", 2, "assassinate_corellia_privateer_tier4_2a", 10000, "weapon/wpn_mission_reward_neutral_borstel_disruptor", 347),
	row("R-6", "turoldine", 3, "space_battle_corellia_privateer_tier4_3a", 10000, "shield_generator/shd_mission_reward_neutral_armek_plasma_web", 354),
	row("R-7", "turoldine", 4, "assassinate_corellia_privateer_tier4_4a", 10000, "engine/eng_mission_reward_neutral_haor_chall_military", 361),
	row("R-8", "aqzow", 1, "recovery_corellia_rebel_tier3_1", 25000, "armor/arm_mission_reward_rebel_corellian_triplate", 264),
	row("R-9", "aqzow", 2, "inspect_corellia_rebel_tier3_2", 25000, "weapon_capacitor/cap_mission_reward_rebel_qualdex_battery_array", 272),
	row("R-10", "aqzow", 3, "delivery_corellia_rebel_tier3_3", 25000, "engine/eng_mission_reward_rebel_incom_military", 280),
	row("R-11", "aqzow", 4, "assassinate_corellia_rebel_tier3_4", 25000, "reactor/rct_mission_reward_rebel_slayn_hypervortex", 288),
	row("R-12", "viopa", 4, "assassinate_viopa_rebel_4", 5000, "weapon/wpn_mission_reward_rebel_taim_ion_driver", 454),
	-- the four item-only heads (D-8): they already pay 5000
	row("R-13", "rikkh", 1, "destroy_corellia_privateer_13a", 5000, "booster/bst_mission_reward_neutral_mandal_m_series", 271),
	row("R-14", "viopa", 1, "inspect_viopa_rebel_1", 5000, "shield_generator/shd_mission_reward_rebel_incom_k77", 401),
	row("R-15", "viopa", 2, "escort_viopa_rebel_2", 5000, "droid_interface/ddi_mission_reward_rebel_moncal_d22", 424),
	row("R-16", "viopa", 3, "recovery_viopa_rebel_3", 5000, "booster/bst_mission_reward_rebel_novaldex_hypernova", 439),
}

D.R_BY_GLOBAL = {}

for _, r in ipairs(D.R_ROWS) do
	D.R_BY_GLOBAL[r.global] = r
end

-- The pay screens of each (trainer, mission) the runtime tests expect to reach (read off the handlers' pay branches)
D.PAY_SCREENS = {
	rikkh = {
		{ "according_to_plan", "first_mission_success" }, { "duty_calls", "here_is_pay" }, { "turnover_intelligence" }, { "fourth_mission_success" },
	},
	turoldine = { { "first_mission_success" }, { "second_mission_success" }, { "third_mission_success" }, { "fourth_mission_success" } },
	aqzow = { { "excellent_work" }, { "excellent_work2" }, { "excellent_work3" }, { "excellent_work4" } },
	viopa = {
		{ "excellent_work" }, { "mission2_rewarded_humble", "mission2_rewarded_payment" }, { "mission3_rewarded_rest", "mission3_rewarded_duties" },
		{ "mission4_rewarded_nothing", "mission4_rewarded_whatnow" },
	},
}

-- Rebel faction standing the trainer adds per mission reward (SWG factions.addFactionStanding, spec F-2)
D.FACTION_PER_REWARD = { aqzow = 100, viopa = 75 }

---------------------------------------------------------------------------------------------
-- Small file helpers
---------------------------------------------------------------------------------------------

function D.readFile(path)
	local f = io.open(path, "rb")

	if f == nil then
		return nil
	end

	local text = f:read("a")
	f:close()

	return text
end

function D.shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

function D.linesOf(text)
	local lines = {}

	for line in (text .. "\n"):gmatch("(.-)\n") do
		lines[#lines + 1] = line
	end

	-- a final "\n" leaves one empty trailing element: drop it so that line counts match `wc -l`
	if lines[#lines] == "" then
		lines[#lines] = nil
	end

	return lines
end

function D.count(text, plain)
	local n, init = 0, 1

	while true do
		local s, e = text:find(plain, init, true)

		if s == nil then
			return n
		end

		n = n + 1
		init = e + 1
	end
end

-- Text of `path` (relative to MMOCoreORB/) at the base commit, or nil, reason when git cannot show it
function D.baseText(path)
	local rc, out = D.shell("git show " .. D.BASE_COMMIT .. ":MMOCoreORB/" .. path)

	if rc ~= 0 then
		return nil, out
	end

	return out
end

---------------------------------------------------------------------------------------------
-- SWG java: giveReward calls and whether any branch reaches their action
---------------------------------------------------------------------------------------------

local javaCache = {}

-- { rewards = { {action, type, name, credits, item|nil, line, calls} }, calls = { action -> number of call sites } }
function D.java(name)
	if javaCache[name] then
		return javaCache[name]
	end

	local path = H.FIXTURES .. "script/conversation/" .. name .. ".java"
	local text = D.readFile(path)

	assert(text ~= nil, "missing java fixture " .. path)

	text = text:gsub("\r", "")

	local out = { rewards = {}, calls = {}, name = name }
	local action
	local lineNo = 0

	for line in (text .. "\n"):gmatch("(.-)\n") do
		lineNo = lineNo + 1

		local def = line:match("^%s*public void [%w_]-_action_([%w_]+)%(obj_id player, obj_id npc%)")

		if def then
			action = def
		elseif line:match("^%s*public ") then
			action = nil
		end

		local site = line:match("_action_([%w_]+)%(player, npc%);")

		if site and not def then
			out.calls[site] = (out.calls[site] or 0) + 1
		end

		if action then
			local kind, quest, credits, rest = line:match('space_quest%.giveReward%(player, "([^"]+)", "([^"]+)", (%d+)(.-)%);')

			if quest then
				out.rewards[#out.rewards + 1] = {
					action = action, type = kind, name = quest, credits = tonumber(credits), item = rest:match(', "([^"]+)"'), line = lineNo,
				}
			end
		end
	end

	for _, r in ipairs(out.rewards) do
		r.calls = out.calls[r.action] or 0
	end

	javaCache[name] = out

	return out
end

-- reachable rewards grouped by quest name: name -> { rewards... } (several = species branches of one action)
function D.reachableByName(java)
	local out, order = {}, {}

	for _, r in ipairs(java.rewards) do
		if r.calls > 0 then
			if out[r.name] == nil then
				out[r.name] = {}
				order[#order + 1] = r.name
			end

			out[r.name][#out[r.name] + 1] = r
		end
	end

	return out, order
end

function D.unreachableNames(java)
	local out = {}

	for _, r in ipairs(java.rewards) do
		if r.calls == 0 then
			out[#out + 1] = r.name
		end
	end

	table.sort(out)

	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

function D.load()
	H.boot()

	for _, name in ipairs(D.SQUADRONS) do
		H.loadSquadron(name)
	end

	for _, key in ipairs(D.ORDER) do
		H.loadScreenplay("space/conversations/" .. D.TRAINERS[key].handler)
	end
end

---------------------------------------------------------------------------------------------
-- Pay heads of one handler (I-1), from its source
---------------------------------------------------------------------------------------------

function D.handlerSource(trainer)
	local text = D.readFile(D.HANDLER_DIR .. trainer.handler)

	assert(text ~= nil, "missing handler " .. trainer.handler)

	return text
end

-- Default lookup: the loaded globals
function D.currentLookup(global) return rawget(_G, global) end

local function questGlobalName(squadronName, constant)
	local squadron = rawget(_G, squadronName)
	local quest = squadron and squadron[constant]

	assert(quest ~= nil, squadronName .. "." .. tostring(constant) .. " is not defined")

	return quest.type .. "_" .. quest.name
end

-- list of { global, quest } for the handler; asserts nothing about the count (the tests do)
function D.heads(trainer, lookup)
	lookup = lookup or D.currentLookup

	local text = D.handlerSource(trainer)
	local names = {}

	if trainer.form == "direct" then
		for name in text:gmatch("([%a_][%w_]*):rewardPlayer%(") do
			names[#names + 1] = name
		end
	elseif trainer.form == "dulios" then
		local block = text:match("local MISSION_HEADS = (%b{})")

		for name in (block or ""):gmatch('"([^"]+)"') do
			names[#names + 1] = name
		end
	elseif trainer.form == "questGlobal" then
		local handler = rawget(_G, trainer.handlerGlobal)

		assert(handler ~= nil and handler.MISSIONS ~= nil, trainer.handlerGlobal .. ".MISSIONS is not defined")

		for n = 1, #handler.MISSIONS do
			names[#names + 1] = questGlobalName(trainer.squadron, handler.MISSIONS[n].main)
		end
	end

	local out = {}

	for _, name in ipairs(names) do
		out[#out + 1] = { global = name, quest = lookup(name) }
	end

	return out
end

-- number of `:rewardPlayer(` occurrences and, for the indirect forms, whether the expected call shape is there
function D.payCallShapes(trainer)
	local text = D.handlerSource(trainer)
	local shapes = {
		total = D.count(text, ":rewardPlayer("),
		dulios = D.count(text, "_G[MISSION_HEADS[rewardMission]]:rewardPlayer("),
		questGlobal = D.count(text, "self:questGlobal(self.MISSIONS[n].main):rewardPlayer("),
	}

	return shapes
end

---------------------------------------------------------------------------------------------
-- I-2: one head against the reachable giveReward(s) of its quest name
---------------------------------------------------------------------------------------------

local function itemList(quest)
	local out = {}

	for _, entry in ipairs(quest.itemReward or {}) do
		out[#out + 1] = entry.item
	end

	return out
end

local function sameSet(a, b)
	local sa, sb = {}, {}

	for _, v in ipairs(a) do sa[v] = true end
	for _, v in ipairs(b) do sb[v] = true end
	for k in pairs(sa) do if not sb[k] then return false end end
	for k in pairs(sb) do if not sa[k] then return false end end

	return true
end

local function show(v)
	if type(v) == "table" then
		local parts = {}

		for _, e in ipairs(v) do
			parts[#parts + 1] = (type(e) == "table" and ("{" .. table.concat(e.species or {}, ",") .. "}=" .. tostring(e.item)) or tostring(e))
		end

		return "[" .. table.concat(parts, "; ") .. "]"
	end

	return tostring(v)
end

-- Returns the list of mismatch messages (empty = conforms) and whether the D-11 exception was used.
-- `rewards` = the reachable rewards of the head's quest name (D.reachableByName)
function D.check(trainerKey, head, rewards)
	local msgs, usedException = {}, false
	local quest = head.quest
	local who = head.global

	if quest == nil then
		return { who .. ": the quest table is not defined" }, false
	end

	if rewards == nil or #rewards == 0 then
		return { who .. ": no reachable SWG giveReward for questName " .. tostring(quest.questName) }, false
	end

	local credits = rewards[1].credits

	for _, r in ipairs(rewards) do
		if r.credits ~= credits then
			msgs[#msgs + 1] = who .. ": the SWG calls of " .. quest.questName .. " disagree on credits"
		end
	end

	if (quest.creditReward or 0) ~= credits then
		msgs[#msgs + 1] = string.format("%s: creditReward is %s, SWG pays %d (java line %d)", who, tostring(quest.creditReward or 0), credits, rewards[1].line)
	end

	if #rewards == 1 then
		local r = rewards[1]
		local want = {}

		if r.item then
			want[1] = { species = { -1 }, item = r.item }
		end

		local have = quest.itemReward or {}
		local ok = #have == #want

		for i = 1, #want do
			ok = ok and have[i] ~= nil and have[i].item == want[i].item and #have[i].species == 1 and have[i].species[1] == -1
		end

		if not ok then
			msgs[#msgs + 1] = string.format("%s: itemReward is %s, SWG gives %s (java line %d)", who, show(have), show(want), r.line)
		end
	else
		local swgItems = {}

		for _, r in ipairs(rewards) do
			local item = r.item

			if trainerKey == D.EXCEPTION.trainer and r.name == D.EXCEPTION.questName and item == D.EXCEPTION.swg then
				item = D.EXCEPTION.core3
				usedException = true
			end

			swgItems[#swgItems + 1] = item
		end

		if not sameSet(itemList(quest), swgItems) then
			msgs[#msgs + 1] = string.format("%s: item set is %s, SWG gives %s", who, show(itemList(quest)), show(swgItems))
		end
	end

	return msgs, usedException
end

-- Runs I-1 resolution and I-2 over every trainer. Returns
--   { failures = { global -> {messages} }, heads = { {trainer, global, quest} }, matched = { questName-key -> number of heads },
--     exceptions = number of D-11 uses, problems = { messages for unresolved heads or names } }
function D.sweep(lookup)
	lookup = lookup or D.currentLookup

	local out = { failures = {}, heads = {}, matched = {}, exceptions = 0, problems = {} }

	for _, key in ipairs(D.ORDER) do
		local trainer = D.TRAINERS[key]
		local java = D.java(trainer.java)
		local byName = D.reachableByName(java)

		for _, head in ipairs(D.heads(trainer, lookup)) do
			out.heads[#out.heads + 1] = { trainer = key, global = head.global, quest = head.quest }

			if head.quest == nil then
				out.problems[#out.problems + 1] = key .. ": " .. head.global .. " is not a defined quest table"
			else
				local rewards = byName[head.quest.questName]
				local k = key .. "|" .. tostring(head.quest.questName)

				if rewards ~= nil then
					out.matched[k] = (out.matched[k] or 0) + 1
				end

				local msgs, used = D.check(key, head, rewards)

				if used then
					out.exceptions = out.exceptions + 1
				end

				if #msgs > 0 then
					out.failures[head.global] = msgs
				end
			end
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- The base commit's CorSec and Havoc quest tables, evaluated in a sandbox (nothing leaks into the real globals)
---------------------------------------------------------------------------------------------

-- Returns lookup(global) -> table: the 1d980a2452 version for the CorSec and Havoc squadron files, the loaded one otherwise.
-- nil, reason when git cannot show the files.
function D.baseLookup()
	local env = setmetatable({}, { __index = _G })

	for _, path in ipairs({ D.CSP, D.HSP }) do
		local text, why = D.baseText(path)

		if text == nil then
			return nil, why
		end

		local chunk, err = load(text, "=" .. D.BASE_COMMIT .. ":" .. path, "t", env)

		assert(chunk ~= nil, tostring(err))
		chunk()
	end

	return function(global)
		local v = rawget(env, global)

		if v == nil then
			v = rawget(_G, global)
		end

		return v
	end
end

return D
