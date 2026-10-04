-- Warvog Arkon (Havoc tier 4): the pilot chooses which missing tier 4 skill to train (pre-NGE free choice).
-- Spec: .claude/work/havoc-tier4-arkon-free-choice/01-spec.md (AC-1 .. AC-5; Content contract 1-2; invariants I-1 .. I-7; D-2, D-4, D-7, D-8).
--
-- The choice replies are Arkon's pre-NGE lines "I would like <skill>, please." (space-convo-client-strings-arkon D-10, which supersedes D-7 here), copied from that spec into
-- havoc_tier4_arkon_free_choice_data.lua. The training is one click (that spec's D-2): the reply leads straight to trained_<x>, which grants the skill on display.
-- The mission table and the pilot builder come from havoc_tier4_data.lua. The fake charges XP only with H.Engine.config.skillXpCosts set (see costs());
-- the tier 4 threshold of SpaceHelpers:hasExperienceForTraining (1000000) is the cost.
-- AC-4 reads the answer key (the SWG java fixture) and git a93da5f969 (the base of this feature) the way test_pilot_training_free_choice_conformance.lua does.

local lu = require("luaunit")
local H = require("harness")
local D = require("havoc_tier4_data")
local C = require("havoc_tier4_arkon_free_choice_data")
local DS = require("havoc_tier4_arkon_client_strings_data") -- space-convo-client-strings-arkon: twin table, training ids, base commit
local Swgjava = require("harness.swgjava")

H.loadSquadron("HavocSquadronScreenplay")
H.loadMobile("conversations/space/rebel/havoc_squadron/arkon_convo.lua")
H.loadScreenplay("space/conversations/rebel/havoc_squadron/arkonConvoHandler.lua")

local COST = 1000000
local BASE = "a93da5f969"
local REAL_SKILL_MANAGER = LuaSkillManager
local AC_PATH = "mobile/conversations/space/rebel/havoc_squadron/arkon_convo.lua"
local AH_PATH = "screenplays/space/conversations/rebel/havoc_squadron/arkonConvoHandler.lua"

local function costs()
	local out = {}

	for _, c in ipairs(C.CHOICES) do
		out[c.skill] = COST
	end

	H.Engine.config.skillXpCosts = out
end

local function exp(player) return player.ghost.experience.space_combat_general end

local function ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

local function converse(player, choices)
	return H.converse({ template = "arkon_convo", player = player, npc = H.newNpc({ name = "Warvog Arkon" }), choices = choices })
end

-- Missions 1..n won, attempted and paid
local function history(n)
	local h = { rewards = {}, attempted = {}, completed = {} }

	for i = 1, n do
		h.rewards[i] = i
		h.attempted[i] = i
		h.completed[#h.completed + 1] = D.MISSION[i].wins[1]
	end

	return h
end

-- A met Havoc pilot holding the tier 4 skills `held` (short names) with missions 1..#held paid and `amount` space XP: ready_train is the first screen
local function trainee(held, amount)
	local h = history(#held)

	return D.havoc({ tier4 = held, rewards = h.rewards, attempted = h.attempted, completed = h.completed, xp = amount or COST, met = true })
end

-- Mission n won and paid (state a real run of the mission leaves behind)
local function finishMission(player, n)
	H.setQuestStatus(player, D.MISSION[n].statusName .. ":attempted", 1)
	H.setQuestStatus(player, D.MISSION[n].statusName .. ":reward", 1)

	local key = D.MISSION[n].wins[1]

	player.ghost.journalComplete[H.questCrc(D.QUEST[key][1], D.QUEST[key][2])] = true
end

local function spyAllQuests()
	local rec = { starts = {}, rewards = {} }

	for _, name in ipairs(H.questGlobals()) do
		local quest = rawget(_G, name)

		H.spyOn(quest, "startQuest", function() rec.starts[#rec.starts + 1] = name end)
		H.spyOn(quest, "rewardPlayer", function() rec.rewards[#rec.rewards + 1] = name end)
	end

	return rec
end

local function readFile(rel)
	local f = assert(io.open(H.SCRIPTS .. rel, "r"), "cannot open " .. rel)
	local text = f:read("a")

	f:close()
	return text
end

local function baseFile(rel, commit)
	commit = commit or BASE

	local pipe = io.popen("git show " .. commit .. ":MMOCoreORB/bin/scripts/" .. rel .. " 2>&1")
	local text = pipe:read("a")

	pipe:close()
	lu.assertTrue(#text > 500 and text:find("^fatal") == nil, "git show " .. commit .. ":MMOCoreORB/bin/scripts/" .. rel .. " did not return the file: " .. text:sub(1, 120))

	return text
end

---------------------------------------------------------------------------------------------
-- AC-1: the choice screen
---------------------------------------------------------------------------------------------

TestArkonFreeChoice = {}

function TestArkonFreeChoice:setUp() H.reset() end
function TestArkonFreeChoice:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- AC-1, AC-4: the template carries no static option and keeps its id, line and animation
function TestArkonFreeChoice:test_the_static_ready_train_screen_has_no_options_and_keeps_its_line_and_animation()
	local screen

	for _, s in ipairs(H.conversationTemplateTable("arkon_convo").screens) do
		if s.id == "ready_train" then
			screen = s
		end
	end

	lu.assertNotNil(screen, "arkon_convo: screen ready_train")
	lu.assertEquals(screen.options, {}, "ready_train: static options")
	lu.assertEquals(screen.leftDialog, D.PREFIX .. D.SCREENS.ready_train, "ready_train: leftDialog")
	lu.assertEquals(screen.animation, "beckon", "ready_train: animation")
	lu.assertNotEquals(screen.stopConversation, "true", "ready_train: does not end the conversation")
end

-- AC-1, I-2, I-5: each proper subset
for _, held in ipairs(C.properSubsets()) do
	TestArkonFreeChoice["test_ready_train_offers_exactly_the_choice_replies_of_the_missing_skills_in_order_when_holding_" .. C.label(held):gsub("[^%w]+", "_")] = function()
		costs()
		local spy = spyAllQuests()

		local player = trainee(held)
		local transcript = converse(player)

		lu.assertEquals(transcript[1].id, "ready_train", C.label(held) .. ": first screen")
		lu.assertEquals(transcript[1].text, D.PREFIX .. D.SCREENS.ready_train, C.label(held) .. ": NPC line")
		lu.assertEquals(transcript[1].params.TU, player.name, C.label(held) .. ": %TU")
		lu.assertFalse(transcript[1].stop, C.label(held) .. ": ready_train does not end the conversation")
		lu.assertEquals(C.pairsOf(transcript[1]), C.expected(C.set(C.skillsOf(held))), C.label(held) .. ": options (reply, link)")
		lu.assertEquals(#transcript[1].options, 4 - #held, C.label(held) .. ": number of options")

		-- I-5: nothing is granted, paid, started or written while it is shown
		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, C.label(held) .. ": skillManagerAwardSkill calls")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, C.label(held) .. ": awardSkill calls")
		lu.assertEquals(exp(player), COST, C.label(held) .. ": space_combat_general")
		lu.assertEquals(spy.starts, {}, C.label(held) .. ": quests started")
		lu.assertEquals(spy.rewards, {}, C.label(held) .. ": rewards paid")
	end
end

-- AC-1, I-2, I-6: the retired reply is never offered
function TestArkonFreeChoice:test_the_retired_single_reply_s_421_is_never_offered()
	for _, held in ipairs(C.properSubsets()) do
		H.reset()

		local transcript = converse(trainee(held))

		lu.assertEquals(transcript[1].id, "ready_train", C.label(held) .. ": first screen")

		for _, o in ipairs(transcript[1].options) do
			lu.assertNil(o.text:find(C.RETIRED, 1, true), C.label(held) .. ": the fixed-order reply " .. o.text)
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: any-order purchase
---------------------------------------------------------------------------------------------

-- AC-2, AC-5 (space-convo-client-strings-arkon): every reply leads to the acknowledgment of its skill and grants that skill once, on display
function TestArkonFreeChoice:test_every_reply_leads_to_the_acknowledgment_of_its_skill_and_grants_that_skill_once()
	for _, c in ipairs(C.CHOICES) do
		H.reset()
		costs()

		local player = trainee({})
		local transcript = converse(player, { c.reply })

		lu.assertEquals(ids(transcript), { "ready_train", c.screen }, c.x .. ": screens (no prompt and no buy step)")
		lu.assertEquals(transcript[2].text, D.PREFIX .. D.SCREENS[c.screen], c.x .. ": the acknowledgment")

		local paid = H.Engine.callsTo("skillManagerAwardSkill")

		lu.assertEquals(#paid, 1, c.x .. ": skillManagerAwardSkill calls when the acknowledgment is shown")
		lu.assertEquals(paid[1][2], c.skill, c.x .. ": skill granted")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, c.x .. ": awardSkill (free grant) calls")
		lu.assertEquals(exp(player), 0, c.x .. ": XP after the grant (deducted once)")
	end
end

-- AC-2, I-3, I-4: for every skill and every subset of the others (32 rows) the pick buys that skill once
for _, c in ipairs(C.CHOICES) do
	TestArkonFreeChoice["test_picking_" .. c.x .. "_04_buys_it_once_through_the_xp_deducting_grant_and_shows_the_acknowledgment_whatever_else_is_held"] = function()
		local rows = 0

		for mask = 0, 7 do
			H.reset()
			costs()

			local held = {}
			local others = {}

			for _, other in ipairs(C.CHOICES) do
				if other.x ~= c.x then
					others[#others + 1] = other.x
				end
			end

			for i, x in ipairs(others) do
				if mask & (1 << (i - 1)) ~= 0 then
					held[#held + 1] = x
				end
			end

			rows = rows + 1

			local player = trainee(held, 2 * COST)
			local label = c.x .. " holding " .. C.label(held)
			local transcript = converse(player, { c.reply })

			lu.assertEquals(ids(transcript), { "ready_train", c.screen }, label .. ": screens")
			lu.assertEquals(transcript[2].text, D.PREFIX .. D.SCREENS[c.screen], label .. ": the acknowledgment")

			local paid = H.Engine.callsTo("skillManagerAwardSkill")

			lu.assertEquals(#paid, 1, label .. ": skillManagerAwardSkill calls")
			lu.assertTrue(paid[1][1] == player, label .. ": skillManagerAwardSkill player")
			lu.assertEquals(paid[1][2], c.skill, label .. ": skill bought")
			lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, label .. ": awardSkill (free grant) calls")
			lu.assertEquals(exp(player), COST, label .. ": space_combat_general after one purchase (deducted once)")
			lu.assertTrue(CreatureObject(player):hasSkill(c.skill), label .. ": " .. c.skill .. " held")

			for _, other in ipairs(C.CHOICES) do
				lu.assertEquals(CreatureObject(player):hasSkill(other.skill), other.x == c.x or C.set(C.skillsOf(held))[other.skill] == true, label .. ": " .. other.skill .. " held (one skill per visit)")
			end
		end

		lu.assertEquals(rows, 8, c.x .. ": rows")
	end
end

-- AC-2: the guards hold for every skill picked first and picked last
for _, c in ipairs(C.CHOICES) do
	for _, setup in ipairs({ { "none", {} }, { "all_others", "others" } }) do
		local function held()
			if setup[2] ~= "others" then
				return {}
			end

			local out = {}

			for _, o in ipairs(C.CHOICES) do
				if o.x ~= c.x then
					out[#out + 1] = o.x
				end
			end

			return out
		end

		-- AC-2
		TestArkonFreeChoice["test_picking_" .. c.x .. "_grants_nothing_if_the_skill_arrives_before_the_acknowledgment_is_shown_holding_" .. setup[1]] = function()
			costs()

			local player = trainee(held(), 2 * COST)
			local before = exp(player)

			converse(player, { function(p) p.skills[c.skill] = true end, c.reply })

			lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, c.x .. ": skillManagerAwardSkill calls")
			lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, c.x .. ": awardSkill calls")
			lu.assertEquals(exp(player), before, c.x .. ": XP")
		end

		-- AC-2
		TestArkonFreeChoice["test_picking_" .. c.x .. "_grants_nothing_if_the_xp_is_gone_before_the_acknowledgment_is_shown_holding_" .. setup[1]] = function()
			costs()

			local player = trainee(held(), COST)

			converse(player, { function(p) p.ghost.experience.space_combat_general = COST - 1 end, c.reply })

			lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, c.x .. ": skillManagerAwardSkill calls")
			lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, c.x .. ": awardSkill calls")
			lu.assertFalse(CreatureObject(player):hasSkill(c.skill), c.x .. ": skill held")
		end
	end
end

-- AC-2: the fourth skill raises the pilot tier 4 -> 5, whichever skill it is; the third never does
function TestArkonFreeChoice:test_the_fourth_skill_raises_the_pilot_tier_to_5_whichever_skill_it_is()
	for _, last in ipairs(C.CHOICES) do
		H.reset()
		costs()

		local held = {}

		for _, c in ipairs(C.CHOICES) do
			if c.x ~= last.x then
				held[#held + 1] = c.x
			end
		end

		local player = trainee(held)

		lu.assertEquals(player.ghost:getPilotTier(), 4, last.x .. ": setup, pilot tier")
		converse(player, { last.reply })
		lu.assertEquals(player.ghost:getPilotTier(), 5, last.x .. ": pilot tier after the fourth tier 4 skill")
	end
end

function TestArkonFreeChoice:test_a_third_skill_in_any_order_leaves_the_pilot_tier_at_4()
	for _, c in ipairs(C.CHOICES) do
		H.reset()
		costs()

		local held = {}

		for _, o in ipairs(C.CHOICES) do
			if o.x ~= c.x and #held < 2 then
				held[#held + 1] = o.x
			end
		end

		local player = trainee(held)

		converse(player, { c.reply })
		lu.assertEquals(player.ghost:getPilotTier(), 4, c.x .. ": pilot tier after the third tier 4 skill")
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: an out-of-order career
---------------------------------------------------------------------------------------------

TestArkonFreeChoiceCareer = {}

function TestArkonFreeChoiceCareer:setUp() H.reset() end
function TestArkonFreeChoiceCareer:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- AC-3
function TestArkonFreeChoiceCareer:test_picking_the_last_reply_every_visit_trains_droid_procedures_weapons_starships_one_per_visit_and_raises_the_tier_with_the_fourth()
	costs()

	local player = trainee({}, 4 * COST)
	local order = { 4, 3, 2, 1 } -- droid, procedures, weapons, starships

	for k, idx in ipairs(order) do
		local pick = C.CHOICES[idx]
		local greeting = converse(player)

		lu.assertEquals(greeting[1].id, "ready_train", "visit " .. k .. ": first screen")
		lu.assertEquals(#greeting[1].options, 5 - k, "visit " .. k .. ": number of replies offered")
		lu.assertEquals(greeting[1].options[#greeting[1].options].text, pick.reply, "visit " .. k .. ": the last reply offered")

		local before = #H.Engine.callsTo("skillManagerAwardSkill")
		local transcript = converse(player, { pick.reply })

		lu.assertEquals(ids(transcript), { "ready_train", pick.screen }, "visit " .. k .. ": screens")
		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill") - before, 1, "visit " .. k .. ": skills bought")
		lu.assertEquals(H.Engine.callsTo("skillManagerAwardSkill")[before + 1][2], pick.skill, "visit " .. k .. ": skill bought")
		lu.assertEquals(exp(player), (4 - k) * COST, "visit " .. k .. ": space_combat_general")
		lu.assertEquals(player.ghost:getPilotTier(), k == 4 and 5 or 4, "visit " .. k .. ": pilot tier")
		lu.assertEquals(converse(player)[1].id, "mission" .. k .. "_offer", "visit " .. k .. ": the next talk starts on the offer of mission " .. k)

		finishMission(player, k)
	end

	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 4, "total skillManagerAwardSkill calls")
	lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "total awardSkill calls")

	for _, c in ipairs(C.CHOICES) do
		lu.assertTrue(CreatureObject(player):hasSkill(c.skill), c.skill .. " held")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: conformance and strings
---------------------------------------------------------------------------------------------

TestArkonFreeChoiceTable = {}

function TestArkonFreeChoiceTable:setUp() H.reset() end

local function handler() return H.expectGlobal("arkonConvoHandler", "Arkon conversation handler") end

-- AC-4: TRAIN_CHOICES equals the answer key
function TestArkonFreeChoiceTable:test_train_choices_equals_the_answer_key()
	local h = handler()

	lu.assertEquals(type(h.TRAIN_CHOICES), "table", "arkonConvoHandler.TRAIN_CHOICES must be defined (havoc-tier4-arkon-free-choice)")

	local got, want = {}, {}

	for i, entry in ipairs(h.TRAIN_CHOICES) do
		got[i] = { entry[1], entry[2], entry[3] }
	end

	for i, c in ipairs(C.CHOICES) do
		want[i] = { c.skill, c.reply, c.screen }
	end

	lu.assertEquals(got, want, "arkonConvoHandler.TRAIN_CHOICES ({ skill, reply, screen } in order starships, weapons, procedures, droid)")
end

-- AC-4 (space-convo-client-strings-arkon, Content contract 2): every link is a template screen, the acknowledgment that grants the entry's skill on display
function TestArkonFreeChoiceTable:test_every_train_choices_link_is_a_template_screen()
	local h = handler()
	local byId = {}

	for _, s in ipairs(H.conversationTemplateTable("arkon_convo").screens) do
		byId[s.id] = s
	end

	lu.assertEquals(type(h.TRAIN_CHOICES), "table", "arkonConvoHandler.TRAIN_CHOICES must be defined")

	for i, entry in ipairs(h.TRAIN_CHOICES) do
		lu.assertNotNil(byId[entry[3]], "TRAIN_CHOICES[" .. i .. "]: screen '" .. tostring(entry[3]) .. "' is not in arkon_convo")
		lu.assertEquals(h.TRAINED_SCREENS[entry[3]], entry[1], "TRAIN_CHOICES[" .. i .. "]: the acknowledgment screen '" .. tostring(entry[3]) .. "' grants the skill of the entry")
	end
end

-- AC-4, Content contract: every id is a complete string literal
function TestArkonFreeChoiceTable:test_train_choices_ids_are_complete_string_literals()
	local text = readFile(AH_PATH)
	local open = text:find("TRAIN_CHOICES%s*=%s*{")

	lu.assertNotNil(open, AH_PATH .. ": a 'TRAIN_CHOICES = {' table")

	local depth, i, start = 0, text:find("{", open, true), nil
	local stop

	start = i

	while i <= #text do
		local ch = text:sub(i, i)

		if ch == "{" then
			depth = depth + 1
		elseif ch == "}" then
			depth = depth - 1

			if depth == 0 then
				stop = i
				break
			end
		end

		i = i + 1
	end

	lu.assertNotNil(stop, "the TRAIN_CHOICES table is closed")

	local body = text:sub(start, stop)

	lu.assertNil(body:find("..", 1, true), "TRAIN_CHOICES contains a string concatenation; every id must be a complete literal")

	for _, row in ipairs(C.CHOICES) do
		for _, field in ipairs({ "skill", "reply", "screen" }) do
			lu.assertNotNil(body:find('"' .. row[field] .. '"', 1, true), "TRAIN_CHOICES: literal \"" .. row[field] .. "\"")
		end
	end
end

TestArkonFreeChoiceStrings = {}

function TestArkonFreeChoiceStrings:setUp() H.reset() end

-- AC-4, I-6: s_421 is in neither file
function TestArkonFreeChoiceStrings:test_the_retired_reply_s_421_is_in_neither_file()
	for _, rel in ipairs({ AC_PATH, AH_PATH }) do
		lu.assertNil(readFile(rel):find(C.RETIRED .. '"', 1, true), rel .. " still carries " .. C.RETIRED)
	end
end

-- AC-4, I-6; space-convo-client-strings-arkon (D-10): no string file other than corellia_rebel_tier4 is named, and the only ids of it outside the SWG java are
-- the 12 pre-NGE training lines (the four skill replies are Arkon's own now, not @skl_n)
function TestArkonFreeChoiceStrings:test_the_arkon_files_name_no_foreign_string_file_and_the_only_ids_outside_the_swg_java_are_the_12_pre_nge_training_lines()
	local java = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_rebel_tier4.java")
	local foreignFile, outside = {}, {}

	for _, rel in ipairs({ AC_PATH, AH_PATH }) do
		for ref in readFile(rel):gmatch("\"(@[%w_/]+:[%w_]+)\"") do
			local sid = ref:match("^@conversation/corellia_rebel_tier4:(s_[%w_]+)$")

			if sid == nil then
				foreignFile[ref] = true
			elseif java.nodes[sid] == nil and java.responses[sid] == nil then
				outside[sid] = true
			end
		end
	end

	local got, want, other = {}, {}, {}

	for sid in pairs(outside) do got[#got + 1] = sid end
	for sid in pairs(foreignFile) do other[#other + 1] = sid end
	for sid in pairs(DS.TRAINING_TEXT) do want[#want + 1] = sid end

	table.sort(got)
	table.sort(want)
	table.sort(other)
	lu.assertEquals(other, {}, "string ids of other files in arkon_convo.lua + arkonConvoHandler.lua")
	lu.assertEquals(got, want, "corellia_rebel_tier4 ids outside the SWG java in arkon_convo.lua + arkonConvoHandler.lua")
end

-- AC-4, AC-8 (space-convo-client-strings-arkon): AC+AH use 251 of 346 A4 sids; the 95 unused are the 78 NGE-numbered keys of the twin table and the 17 training ids s_421-s_437
function TestArkonFreeChoiceStrings:test_arkon_files_use_251_of_346_swg_sids_and_the_unused_ones_are_the_78_twin_keys_and_the_17_training_ids()
	local java = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_rebel_tier4.java")
	local used, all = {}, {}

	for sid in pairs(java.nodes) do all[sid] = true end
	for sid in pairs(java.responses) do all[sid] = true end

	for _, rel in ipairs({ AC_PATH, AH_PATH }) do
		for sid in readFile(rel):gmatch("@conversation/corellia_rebel_tier4:(s_[%w_]+)") do
			if all[sid] then used[sid] = true end
		end
	end

	local unused, nUsed = {}, 0

	for sid in pairs(all) do
		if used[sid] then nUsed = nUsed + 1 else unused[#unused + 1] = sid end
	end

	local want = {}

	for nge in pairs(DS.TWIN) do want[#want + 1] = nge end
	for n = 421, 437 do want[#want + 1] = "s_" .. n end

	table.sort(unused)
	table.sort(want)
	lu.assertEquals(#want, 95, "78 twin keys + 17 training ids")
	lu.assertEquals(unused, want, "SWG sids unused by arkon_convo.lua + arkonConvoHandler.lua")
	lu.assertEquals(nUsed, 251, "SWG sids used")
end

-- AC-4, I-1: graph
function TestArkonFreeChoiceStrings:test_the_arkon_template_has_182_screens_and_no_dead_links_or_duplicate_ids()
	local t = H.conversationTemplateTable("arkon_convo")

	lu.assertNotNil(t, "arkon_convo is registered")
	lu.assertEquals(#t.screens, 182, "arkon_convo screens (186 - 6 deleted training screens + 2 added, space-convo-client-strings-arkon)")
	lu.assertEquals(t.luaClassHandler, "arkonConvoHandler", "luaClassHandler")
	lu.assertEquals(H.conversationProblems("arkon_convo"), {})
end

---------------------------------------------------------------------------------------------
-- AC-5, I-7: nothing else moves (against commit a93da5f969)
---------------------------------------------------------------------------------------------

TestArkonFreeChoiceNothingElseMoves = {}

-- comment-only and blank lines are not compared
local function code(text)
	local out = {}

	for line in (text .. "\n"):gmatch("(.-)\n") do
		if not line:match("^%s*%-%-") and not line:match("^%s*$") then
			out[#out + 1] = line
		end
	end

	return table.concat(out, "\n")
end

-- the text from `a` (plain, first occurrence) up to but excluding `b` found after it
local function cut(text, a, b, what)
	local s = text:find(a, 1, true)

	lu.assertNotNil(s, what .. ": '" .. a .. "'")

	local e = text:find(b, s + #a, true)

	lu.assertNotNil(e, what .. ": '" .. b .. "' after '" .. a .. "'")

	return text:sub(1, s - 1) .. text:sub(e)
end

-- I-7, AC-5; retargeted by havoc-tier4-arkon-duty-gate (AC-4): the block gains the datapad clause and nothing else
function TestArkonFreeChoiceNothingElseMoves:test_can_fly_non_track_duty_is_commit_a93da5f969_plus_the_datapad_clause()
	local function block(text, what)
		local s = text:find("function arkonConvoHandler:canFlyNonTrackDuty", 1, true)

		lu.assertNotNil(s, what .. ": canFlyNonTrackDuty")

		local e = text:find("\nend\n", s, true)

		return text:sub(s, e + 4)
	end

	local old = block(baseFile(AH_PATH), BASE)
	local ret = "\n\treturn SpaceHelpers:hasCompletedPilotTier(pPlayer, \"rebel_navy\", 3) and not self:isOnMission(pPlayer)\n"
	local at, stop = old:find(ret, 1, true)

	lu.assertNotNil(at, "base canFlyNonTrackDuty return line")
	old = old:sub(1, stop - 1) .. " and not SpaceHelpers:hasSpaceQuest(pPlayer)" .. old:sub(stop)

	lu.assertEquals(block(readFile(AH_PATH), "now"), old, "canFlyNonTrackDuty (D-8 done by havoc-tier4-arkon-duty-gate: only the datapad clause is added)")
end

-- I-7, AC-5: the handler outside the ready_train branch and the TRAIN_CHOICES table is unchanged
function TestArkonFreeChoiceNothingElseMoves:test_the_handler_outside_the_ready_train_branch_and_the_choice_table_equals_commit_a93da5f969()
	local old = cut(baseFile(AH_PATH), 'elseif (screenID == "ready_train") then', "elseif (self.TRAINED_SCREENS[screenID] ~= nil) then", "base handler")
	local new = readFile(AH_PATH)

	-- drop the TRAIN_CHOICES table (everything from its line to the matching close at line start or its first line-start brace)
	local s = new:find("[^\n]*TRAIN_CHOICES%s*=%s*{")

	lu.assertNotNil(s, "now: TRAIN_CHOICES table")

	local depth, i, stop = 0, new:find("{", s, true), nil

	while i <= #new do
		local ch = new:sub(i, i)

		if ch == "{" then depth = depth + 1 elseif ch == "}" then depth = depth - 1 if depth == 0 then stop = i break end end

		i = i + 1
	end

	new = new:sub(1, s - 1) .. new:sub(stop + 1)
	new = cut(new, 'elseif (screenID == "ready_train") then', "elseif (self.TRAINED_SCREENS[screenID] ~= nil) then", "handler")

	-- havoc-tier4-arkon-duty-gate: the one superseded line is the canFlyNonTrackDuty return, which gains the datapad clause
	local ret = '\treturn SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3) and not self:isOnMission(pPlayer)'
	local s1, e1 = old:find(ret, 1, true)

	lu.assertNotNil(s1, "base canFlyNonTrackDuty return line")
	lu.assertNil(old:find(ret, e1 + 1, true), "base canFlyNonTrackDuty return line occurs once")
	old = old:sub(1, e1) .. " and not SpaceHelpers:hasSpaceQuest(pPlayer)" .. old:sub(e1 + 1)

	lu.assertEquals(code(new), code(old), "arkonConvoHandler.lua outside the ready_train branch and TRAIN_CHOICES")
end

-- I-7, AC-5; re-based by space-convo-client-strings-arkon (AC-7, Appendix C): every screen other than ready_train and the training screens is the screen of commit f637c689a0
-- once the 78 NGE ids are put on their twins in the base and the trailing `-- <client text>` comments are taken off the new text (the base has none)
function TestArkonFreeChoiceNothingElseMoves:test_every_template_screen_other_than_ready_train_and_the_training_screens_equals_commit_f637c689a0_modulo_the_twin_swaps()
	local function without(text, ids)
		for _, id in ipairs(ids) do
			local a = text:find('id = "' .. id .. '"', 1, true)

			lu.assertNotNil(a, "screen " .. id)

			local s = a
			while s > 1 and text:sub(s, s + #"arkon_convo:addScreen(" - 1) ~= "arkon_convo:addScreen(" do
				s = s - 1
			end

			local e = text:find("\n})\n", a, true)

			text = text:sub(1, s - 1) .. text:sub(e + 4)
		end

		return text
	end

	local nowIds = { "ready_train", "trained_starships", "trained_starships_end", "trained_weapons", "trained_weapons_end", "trained_procedures", "trained_droid" }
	local baseIds = { "ready_train", "train_starships", "train_weapons", "train_procedures", "train_droid", "trained_starships", "trained_weapons", "s_431", "trained_procedures", "trained_droid", "s_437" }
	local base = baseFile(AC_PATH, DS.BASE)

	for nge, twin in pairs(DS.TWIN) do
		base = base:gsub(DS.PREFIX .. nge .. '"', function() return DS.PREFIX .. twin .. '"' end)
	end

	local now = readFile(AC_PATH):gsub("[ \t]+%-%-[^\n]*", "")

	base, now = without(base, baseIds), without(now, nowIds)

	-- the remainder must be the whole template minus the training screens, not a stub (guards the backward scan)
	lu.assertTrue(#base > 40000, "arkon_convo.lua without the training screens is the rest of the template (" .. #base .. " bytes)")
	lu.assertEquals(code(now), code(base), "arkon_convo.lua without ready_train and the training screens, modulo the twin swaps")
end
