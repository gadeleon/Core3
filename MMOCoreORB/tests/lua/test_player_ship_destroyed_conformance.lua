-- Conformance of the ship-death hook with the SWG-Source answer key: which quest types fail on a ship death, how, and what the fail sends.
-- Spec: .claude/work/space-quest-player-ship-destroyed/01-spec.md (Test strategy hints "Conformance", Source inventory, C3 to C5, D-7, D-8, D-13)
-- Fixtures (copied byte for byte from SWG-Source, see the test plan): fixtures/script/space/quest_logic/*.java and fixtures/script/library/space_quest.java

local lu = require("luaunit")
local H = require("harness")
local PSD = require("psd_scenario")

PSD.load()

local DIR = H.FIXTURES .. "script/space/quest_logic/"
local SQ = H.FIXTURES .. "script/library/space_quest.java"

local function read(path)
	local f = assert(io.open(path, "r"), "missing SWG-Source fixture " .. path)
	local text = f:read("a")

	f:close()

	return (text:gsub("\r\n", "\n"))
end

local function logic(name) return read(DIR .. name .. ".java") end

-- The parent a fixture extends inside script.space.quest_logic (nil when it extends base_script)
local function parentOf(name)
	return logic(name):match("public class [%w_]+ extends script%.space%.quest_logic%.([%w_]+)")
end

-- The text of `public int playerShipDestroyed`, found in the quest type or the first parent that has one
local function handlerOf(name)
	local cursor = name

	while cursor do
		local text = logic(cursor)
		local from = text:find("public int playerShipDestroyed", 1, true)

		if from then
			local body = text:sub(from)
			local close = body:find("\n    }\n", 1, true)

			return body:sub(1, close + 5), cursor
		end

		cursor = parentOf(cursor)
	end
end

-- SWG type of each Core3 quest type table (C4 table, "SWG handler" column)
local SWG = {
	SpaceDestroyScreenplay = "destroy", SpaceSurpriseAttackScreenplay = "destroy_surpriseattack", SpaceDutyDestroyScreenplay = "destroy_duty",
	SpacePatrolScreenplay = "patrol", SpaceDutyPatrolScreenplay = "patrol_duty", SpaceInspectScreenplay = "inspect",
	SpaceDeliveryScreenplay = "delivery", SpaceDeliveryNoPickupScreenplay = "delivery_no_pickup", SpaceSurvivalScreenplay = "survival",
	SpaceBattleScreenplay = "space_battle", SpaceRecoveryScreenplay = "recovery", SpaceDutyRecoveryScreenplay = "recovery_duty",
	SpaceAssassinateScreenplay = "assassinate", SpaceRescueScreenplay = "rescue", SpaceDutyRescueScreenplay = "rescue_duty",
	SpaceEscortScreenplay = "escort", SpaceDutyEscortScreenplay = "escort_duty",
}

local function failsInSwg(swgType)
	local body = handlerOf(swgType)

	lu.assertNotNil(body, swgType .. ": SWG-Source has a playerShipDestroyed handler for the type or a parent")

	if body:find("SCRIPT_OVERRIDE", 1, true) and not body:find("in_progress", 1, true) then
		return false
	end

	return body:find('hasObjVar(self, "in_progress")', 1, true) ~= nil and body:find("uestFailed%(") ~= nil
end

TestShipDeathConformance = {}

function TestShipDeathConformance:setUp() H.reset() end

-- Every SWG type with a handler (directly or by inheritance) maps to a Core3 type whose isRunInProgress can be true
function TestShipDeathConformance:test_each_swg_type_that_fails_on_a_ship_death_maps_to_a_core3_type_that_can_be_in_progress()
	local problems = {}

	for base, swgType in pairs(SWG) do
		local row = PSD.CLASSES[base]

		if row == nil then
			problems[#problems + 1] = base .. ": no C4 row"
		elseif failsInSwg(swgType) ~= row.expect then
			problems[#problems + 1] = string.format("%s: SWG %s %s on a ship death, the C4 row says the opposite", base, swgType, failsInSwg(swgType) and "fails" or "ignores")
		end
	end

	table.sort(problems)
	lu.assertEquals(problems, {}, "quest types that differ from SWG-Source")

	-- and Core3's type really can be in progress exactly where SWG's can fail (the master missions differ on purpose [user])
	local core3 = {}

	for base, swgType in pairs(SWG) do
		local list = PSD.byClass()[base]

		if list and list[1] then
			local q = list[1].quest
			local player = PSD.accepted(q)

			lu.assertEquals(type(q.isRunInProgress), "function", base .. ": expected isRunInProgress on " .. list[1].global)
			PSD.inProgress(q, player)

			if (q:isRunInProgress(player) and true or false) ~= failsInSwg(swgType) then
				core3[#core3 + 1] = base .. ": isRunInProgress can" .. (failsInSwg(swgType) and "not" or "") .. " be true, SWG " .. (failsInSwg(swgType) and "fails" or "ignores")
			end
		end
	end

	table.sort(core3)
	lu.assertEquals(core3, {}, "Core3 quest types whose run state differs from SWG-Source")
end

-- The inheritance the spec relies on (recovery family, escort, delivery no pickup)
function TestShipDeathConformance:test_the_swg_inheritance_of_the_spec_table_holds()
	lu.assertEquals(parentOf("recovery_duty"), "recovery", "recovery_duty extends recovery")
	lu.assertEquals(parentOf("assassinate"), "recovery", "assassinate extends recovery")
	lu.assertEquals(parentOf("rescue"), "recovery", "rescue extends recovery")
	lu.assertEquals(parentOf("rescue_duty"), "rescue", "rescue_duty extends rescue")
	lu.assertEquals(parentOf("delivery_no_pickup"), "delivery", "delivery_no_pickup extends delivery")
	lu.assertEquals(parentOf("escort"), "escort_duty", "escort extends escort_duty")

	local _, owner = handlerOf("rescue_duty")

	lu.assertEquals(owner, "recovery", "rescue_duty gets recovery's handler")
	_, owner = handlerOf("escort")
	lu.assertEquals(owner, "escort_duty", "escort gets escort_duty's handler")
end

-- Core3 inherits too: the subtypes have no handler of their own (C4: "inherits")
function TestShipDeathConformance:test_the_core3_subtypes_inherit_the_way_the_swg_ones_do()
	for _, pair in ipairs({
		{ "SpaceDutyRecoveryScreenplay", "SpaceRecoveryScreenplay" }, { "SpaceAssassinateScreenplay", nil },
		{ "SpaceDutyRescueScreenplay", "SpaceRescueScreenplay" }, { "SpaceDeliveryNoPickupScreenplay", "SpaceDeliveryScreenplay" },
		{ "SpaceDutyEscortScreenplay", "SpaceEscortScreenplay" },
	}) do
		lu.assertNil(rawget(_G[pair[1]], "failShipDestroyed"), pair[1] .. " has no failShipDestroyed of its own")

		if pair[2] then
			lu.assertEquals(rawget(_G[pair[1]], "isRunInProgress") == nil, true, pair[1] .. " inherits isRunInProgress from " .. pair[2])
		end
	end
end

-- patrol_duty's handler returns SCRIPT_OVERRIDE and fails nothing (D-8)
function TestShipDeathConformance:test_the_swg_patrol_duty_handler_returns_script_override_and_fails_nothing()
	local body = handlerOf("patrol_duty")

	lu.assertNotNil(body, "patrol_duty has its own handler")
	lu.assertNotNil(body:find("return SCRIPT_OVERRIDE;", 1, true), "patrol_duty:playerShipDestroyed returns SCRIPT_OVERRIDE")
	lu.assertNil(body:find("questFailed", 1, true), "and fails nothing")
	lu.assertNil(body:find("in_progress", 1, true), "and does not look at in_progress")
	lu.assertEquals(PSD.CLASSES.SpaceDutyPatrolScreenplay.expect, false, "SpaceDutyPatrolScreenplay is never in progress")
end

-- D-13: escort_duty passes false to questFailed (no split); every other failing handler lets the split happen
function TestShipDeathConformance:test_only_the_escort_handler_fails_without_the_split()
	lu.assertNotNil(handlerOf("escort_duty"):find("questFailed(self, false)", 1, true), "escort_duty:playerShipDestroyed calls questFailed(self, false)")

	local text = logic("escort_duty")
	local from = text:find("public void questFailed(obj_id self, boolean split)", 1, true)

	lu.assertNotNil(from, "escort_duty:questFailed(self, split)")
	lu.assertNotNil(text:sub(from, from + 400):find("setQuestFailed(player, self, split)", 1, true), "questFailed passes the flag on to setQuestFailed(canSplit)")

	for _, swgType in ipairs({ "destroy", "destroy_duty", "destroy_surpriseattack", "patrol", "inspect", "delivery", "survival", "space_battle", "recovery" }) do
		local body = handlerOf(swgType)

		lu.assertNil(body:find("(self, false)", 1, true), swgType .. ": the handler does not suppress the split")
	end
end

-- C3: the SWG fail sends quest_failed with the quest title, plays the fail music, removes the journal entry, and may split
function TestShipDeathConformance:test_the_swg_set_quest_failed_sends_mission_failed_and_the_fail_music()
	local text = read(SQ)

	lu.assertNotNil(text:find('SID_QUEST_FAILED = new string_id("space/quest", "quest_failed")', 1, true), "SID_QUEST_FAILED")
	lu.assertNotNil(text:find('MUSIC_QUEST_FAILED = "sound/music_themequest_fail_criminal.snd"', 1, true), "MUSIC_QUEST_FAILED")

	local from = text:find("public static boolean setQuestFailed(obj_id player, obj_id missionObj, boolean canSplit)", 1, true)

	lu.assertNotNil(from, "setQuestFailed(player, missionObj, canSplit)")

	local body = text:sub(from, from + 2600)

	lu.assertNotNil(body:find('new string_id("spacequest/" + questType + "/" + questName, "title")', 1, true), "the message names the quest title")
	lu.assertNotNil(body:find("prose.getPackage(SID_QUEST_FAILED, title)", 1, true), "quest_failed with the title as TO")
	lu.assertNotNil(body:find("play2dNonLoopingMusic(player, MUSIC_QUEST_FAILED)", 1, true), "the fail music")
	lu.assertNotNil(body:find("_removeQuestJournalEntry", 1, true), "the journal entry is removed")
	lu.assertNotNil(body:find("&& canSplit", 1, true), "the split needs canSplit")
	lu.assertNil(body:find("abandoned", 1, true), "SWG sends no 'abandoned' line on a fail")

	-- Core3 sends the same message and music (C3)
	lu.assertEquals(PSD.MSG_FAILED, "@space/quest:quest_failed", "message id")
	lu.assertEquals(PSD.FAIL_MUSIC, "sound/music_themequest_fail_criminal.snd", "music")
end

-- The notifier chain: player_spacequest.playerShipDestroyed -> notifyMissions -> every datapad object with QUEST_NAME
function TestShipDeathConformance:test_the_swg_notifier_tells_every_datapad_mission()
	local player = read(DIR .. "player_spacequest.java")
	local from = player:find("public int playerShipDestroyed", 1, true)

	lu.assertNotNil(from, "player_spacequest:playerShipDestroyed")
	lu.assertNotNil(player:sub(from, from + 400):find('space_quest.notifyMissions(self, "playerShipDestroyed", outparams)', 1, true), "calls notifyMissions")

	local sq = read(SQ)
	local n = sq:find("public static void notifyMissions(obj_id player, String msg, dictionary params)", 1, true)

	lu.assertNotNil(n, "space_quest.notifyMissions")

	local body = sq:sub(n, n + 600)

	lu.assertNotNil(body:find("getContents(datapad)", 1, true), "walks the datapad")
	lu.assertNotNil(body:find("hasObjVar(dpobj, space_quest.QUEST_NAME)", 1, true), "every object that has a quest name")
end

-- D-4: every SWG type that fails sets in_progress somewhere (the C4 conditions are Core3's twins of these points)
function TestShipDeathConformance:test_every_swg_type_that_fails_on_a_ship_death_sets_in_progress_itself()
	for _, swgType in ipairs({ "destroy", "destroy_surpriseattack", "destroy_duty", "patrol", "inspect", "delivery", "survival", "space_battle", "recovery", "escort_duty" }) do
		lu.assertNotNil(logic(swgType):find("_setQuestInProgress", 1, true), swgType .. ": sets in_progress (space_quest._setQuestInProgress)")
	end
end

-- The pre-CU client holds the Mission Failed string the hook sends (fixtures/string/en/space/quest.sids, generated read-only from /tre
-- by tools/gen_client_sids.py: `python3 -I tests/lua/tools/gen_client_sids.py --check space/quest` reports no difference)
function TestShipDeathConformance:test_the_client_has_the_mission_failed_string()
	local CS = require("harness.client_strings")
	local sids = CS.sids("space/quest")

	lu.assertNotNil(sids, "fixtures/string/en/space/quest.sids")
	lu.assertTrue(sids["quest_failed"] == true, "@space/quest:quest_failed is a string the client resolves")
	lu.assertEquals(CS.unresolved({ H.SCRIPTS .. "screenplays/space/SpaceQuestLogic.lua" }), {}, "SpaceQuestLogic.lua references only ids the client has")
end
