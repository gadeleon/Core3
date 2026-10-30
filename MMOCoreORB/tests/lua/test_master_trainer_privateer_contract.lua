-- Privateer master pilots at the admirals: the contract of MasterTrainerScreenplay and the two handlers, the item templates, the skill row.
-- Spec: .claude/work/space-master-trainer-privateer/01-spec.md (AC-1; Content contract 1 to 3; finding 4 and 5).
--
-- The values are the spec's, not read from production, so a wrong production value fails instead of agreeing with itself.

local lu = require("luaunit")
local H = require("harness")
local P = require("master_trainer_privateer_data")
local I = require("master_trainer_imperial_data")
local R = require("master_trainer_rebel_data")
local Swgjava = require("harness.swgjava")

P.load()

local function readFile(path)
	local f = io.open(path, "r")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()
	return text
end

local function ownKeys(t)
	local out = {}

	for k in pairs(t) do
		out[#out + 1] = tostring(k)
	end

	table.sort(out)
	return out
end

TestMasterTrainerPrivateerContract = {}

function TestMasterTrainerPrivateerContract:setUp() H.reset() end

-- AC-1
function TestMasterTrainerPrivateerContract:test_mts_lists_the_two_privateer_items_in_mission_order()
	local mts = I.mts()

	lu.assertEquals(rawget(mts, "PRIVATEER_ITEM_REWARD"), {
		"object/tangible/wearables/jacket/jacket_ace_privateer.iff",
		"object/tangible/wearables/helmet/helmet_fighter_privateer_ace.iff",
	}, "MasterTrainerScreenplay.PRIVATEER_ITEM_REWARD (mission 1 jacket, mission 2 helmet)")
end

-- AC-1, D-7
function TestMasterTrainerPrivateerContract:test_mts_names_the_neutral_master_skill()
	lu.assertEquals(rawget(I.mts(), "PRIVATEER_MASTER_SKILL"), "pilot_neutral_master", "MasterTrainerScreenplay.PRIVATEER_MASTER_SKILL")
end

-- AC-1
function TestMasterTrainerPrivateerContract:test_mts_defines_reward_privateer()
	lu.assertEquals(type(I.mts().rewardPrivateer), "function", "MasterTrainerScreenplay:rewardPrivateer(pPlayer, headGlobal, n)")
end

-- AC-1: the four quest tables are unchanged
function TestMasterTrainerPrivateerContract:test_the_four_master_quest_tables_are_unchanged()
	for _, M in ipairs({ I, R }) do
		local want = M.expected()

		for _, global in ipairs(M.GLOBALS) do
			local q = M.quest(global)

			lu.assertEquals(ownKeys(q), ownKeys(want[global]), global .. ": own keys")

			for key, value in pairs(want[global]) do
				lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
			end
		end
	end
end

-- AC-1: Content contract 2 and 3, exact values
function TestMasterTrainerPrivateerContract:test_each_handler_carries_the_privateer_tables_with_exactly_the_spec_values()
	for _, adm in ipairs(P.ORDER) do
		local a = P.ADMIRALS[adm]
		local h = H.expectGlobal(a.handler, "the " .. adm .. " handler (space-master-trainer-privateer). Load problems: " .. P.problems())

		for field, want in pairs(a.tables) do
			lu.assertEquals(rawget(h, field), want, a.handler .. "." .. field)
		end
	end
end

-- AC-1, I-9: the earlier tables are unchanged
function TestMasterTrainerPrivateerContract:test_the_existing_handler_tables_are_unchanged()
	for _, adm in ipairs(P.ORDER) do
		local a = P.ADMIRALS[adm]
		local h = H.expectGlobal(a.handler, "the " .. adm .. " handler. Load problems: " .. P.problems())

		for field, want in pairs(P.EXISTING_TABLES[adm]) do
			lu.assertEquals(rawget(h, field), want, a.handler .. "." .. field .. " (existing table)")
		end
	end
end

-- AC-1: each handler defines its own getNextConversationScreen (the swaps)
function TestMasterTrainerPrivateerContract:test_each_handler_defines_get_next_conversation_screen_itself()
	for _, adm in ipairs(P.ORDER) do
		local a = P.ADMIRALS[adm]
		local h = H.expectGlobal(a.handler, "the " .. adm .. " handler. Load problems: " .. P.problems())

		lu.assertEquals(type(rawget(h, "getNextConversationScreen")), "function", a.handler .. ":getNextConversationScreen must be defined on the handler")
	end
end

-- AC-1: both item templates exist and are included by their serverobjects.lua
function TestMasterTrainerPrivateerContract:test_both_privateer_item_templates_exist_and_are_included()
	local cases = {
		{ item = P.jacket, serverobjects = "object/tangible/wearables/jacket/serverobjects.lua", include = 'includeFile("tangible/wearables/jacket/jacket_ace_privateer.lua")' },
		{ item = P.helmet, serverobjects = "object/tangible/wearables/helmet/serverobjects.lua", include = 'includeFile("tangible/wearables/helmet/helmet_fighter_privateer_ace.lua")' },
	}

	for _, c in ipairs(cases) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. c.item:gsub("%.iff$", ".lua")), c.item .. ": no object template under bin/scripts")

		local text = readFile(H.SCRIPTS .. c.serverobjects)

		lu.assertNotNil(text, c.serverobjects)
		lu.assertNotNil(text:find(c.include, 1, true), c.serverobjects .. " must include " .. c.include)
	end
end

-- AC-1, finding 4: the SWG scripts pay these amounts and items to privateers
function TestMasterTrainerPrivateerContract:test_the_swg_scripts_pay_the_privateer_amounts_and_items()
	local cases = {
		{ file = "imperial_master_trainer", prefix = "imperial_master_trainer", faction = "FACTION_IMPERIAL", quest = "master_imperial" },
		{ file = "rebel_master_trainer", prefix = "rebel_master_trainer", faction = "FACTION_REBEL", quest = "master_rebel" },
	}

	for _, c in ipairs(cases) do
		local java = readFile(H.FIXTURES .. "script/conversation/" .. c.file .. ".java")

		lu.assertNotNil(java, "fixtures/script/conversation/" .. c.file .. ".java")

		local function body(name)
			return java:match("void " .. c.prefix .. "_action_" .. name .. "%b()[^{]*(%b{})")
		end

		local one, two = body("giveRewardOnePriv"), body("giveRewardTwoPriv")

		lu.assertNotNil(one, c.file .. ": giveRewardOnePriv")
		lu.assertNotNil(two, c.file .. ": giveRewardTwoPriv")
		lu.assertNotNil(one:find('"' .. c.quest .. '_1", 25000, "' .. P.jacket .. '"', 1, true), c.file .. ": mission 1 pays 25000 and the privateer jacket")
		lu.assertNotNil(one:find(c.faction .. ", 200.0f", 1, true), c.file .. ": mission 1 adds 200 standing")
		lu.assertNotNil(two:find('"' .. c.quest .. '_2", 50000, "' .. P.helmet .. '"', 1, true), c.file .. ": mission 2 pays 50000 and the privateer helmet")
		lu.assertNotNil(two:find(c.faction .. ", 400.0f", 1, true), c.file .. ": mission 2 adds 400 standing")
	end
end

-- AC-1, finding 5: free grant in both scripts
function TestMasterTrainerPrivateerContract:test_the_swg_scripts_grant_the_neutral_master_skill_without_xp()
	for _, file in ipairs({ "imperial_master_trainer", "rebel_master_trainer" }) do
		local java = readFile(H.FIXTURES .. "script/conversation/" .. file .. ".java")
		local body = java:match("void " .. file .. "_action_grantMasterSkillBoxNeutral%b()[^{]*(%b{})")

		lu.assertNotNil(body, file .. ": grantMasterSkillBoxNeutral")
		lu.assertNotNil(body:find('skill.noisyGrantSkill(player, "pilot_neutral_master")', 1, true), file .. ": noisyGrantSkill pilot_neutral_master (no XP)")
	end
end

-- AC-1: the skills excerpt
function TestMasterTrainerPrivateerContract:test_the_skills_excerpt_lists_the_four_neutral_04_skills_as_required_for_the_master_box()
	local rec

	for _, r in ipairs(H.fixture("skill/skills.pilot_neutral_master.tab").records) do
		if r:get("NAME") == "pilot_neutral_master" then
			rec = r
		end
	end

	lu.assertNotNil(rec, "skills.pilot_neutral_master.tab: the master row")
	lu.assertEquals(rec:get("SKILLS_REQUIRED"), "pilot_neutral_starships_04,pilot_neutral_weapons_04,pilot_neutral_procedures_04,pilot_neutral_droid_04",
		"skills.tab: SKILLS_REQUIRED of pilot_neutral_master")
	lu.assertEquals(rec:num("XP_COST"), 7500000, "skills.tab: XP_COST (listed, never charged)")
end

-- AC-1: hasCompletedPilotTier(p, "neutral", 4) checks the same four skills, so the gate and the skill row agree
function TestMasterTrainerPrivateerContract:test_the_tier_4_check_requires_exactly_the_four_skills_of_the_skill_row()
	local required = {}

	for _, r in ipairs(H.fixture("skill/skills.pilot_neutral_master.tab").records) do
		if r:get("NAME") == "pilot_neutral_master" then
			for skill in r:get("SKILLS_REQUIRED"):gmatch("[^,]+") do
				required[#required + 1] = skill
			end
		end
	end

	lu.assertEquals(#required, 4, "four required skills in the row")

	local all = H.newPlayer({ pilot = "neutral", skills = required })

	lu.assertTrue(SpaceHelpers:hasCompletedPilotTier(all, "neutral", 4), "all four skills of the row complete tier 4")

	for i, missing in ipairs(required) do
		local some = {}

		for j, s in ipairs(required) do
			if j ~= i then
				some[#some + 1] = s
			end
		end

		local p = H.newPlayer({ pilot = "neutral", skills = some })

		lu.assertFalse(SpaceHelpers:hasCompletedPilotTier(p, "neutral", 4), "tier 4 without " .. missing)
	end
end

-- AC-1: the new data files do not shadow anything the swg graph knows
function TestMasterTrainerPrivateerContract:test_the_java_answer_keys_load()
	local j = Swgjava.read(H.FIXTURES .. "script/conversation/imperial_master_trainer.java")
	local rj = Swgjava.read(H.FIXTURES .. "script/conversation/rebel_master_trainer.java")

	lu.assertNotNil(j.nodes["s_10009b23"], "J: privateer_ready line s_10009b23")
	lu.assertNotNil(rj.nodes["s_41910783"], "RJ: privateer_ready line s_41910783")
end
