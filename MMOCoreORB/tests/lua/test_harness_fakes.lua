-- Self-tests for the engine fakes and loader (harness/engine.lua, harness/fakes.lua).

local lu = require("luaunit")
local H = require("harness")

H.boot()

TestHarnessFakes = {}

function TestHarnessFakes:setUp()
	H.reset()
end

function TestHarnessFakes:test_engine_constants_are_loaded_from_director_manager()
	lu.assertNotNil(rawget(_G, "CONVERSE"), "observer event constant from DirectorManager.cpp")
	lu.assertNotNil(rawget(_G, "SHIP_SPAWN_SINGLE"), "space spawn constant from DirectorManager.cpp")
end

function TestHarnessFakes:test_quest_crc_matches_what_space_helpers_looks_up()
	local player = H.newPlayer({ activeQuests = { H.questCrc("patrol", "corellia_privateer_1") } })

	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, "patrol", "corellia_privateer_1"))
	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, "patrol", "corellia_privateer_2"))
end

function TestHarnessFakes:test_completing_a_journal_quest_moves_it_from_active_to_complete()
	local player = H.newPlayer({ activeQuests = { H.questCrc("patrol", "q") } })

	PlayerObject(player.ghost):completeJournalQuest(H.questCrc("patrol", "q"), true)

	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, "patrol", "q"))
	lu.assertTrue(SpaceHelpers:isSpaceQuestComplete(player, "patrol", "q"))
end

function TestHarnessFakes:test_missing_fake_method_says_where_to_add_it()
	local player = H.newPlayer({})

	lu.assertErrorMsgContains("has no method 'definitelyNotAMethod'", function()
		CreatureObject(player):definitelyNotAMethod()
	end)
	lu.assertErrorMsgContains("tests/lua/harness/fakes.lua", function()
		CreatureObject(player):definitelyNotAMethod()
	end)
end

function TestHarnessFakes:test_missing_production_script_is_a_readable_red()
	lu.assertErrorMsgContains("expected screenplay script to exist: bin/scripts/screenplays/space/squadrons/NoSuchSquadronScreenplay.lua", function()
		H.loadSquadron("NoSuchSquadronScreenplay")
	end)
end

function TestHarnessFakes:test_grant_space_skill_awards_and_messages()
	local player = H.newPlayer({})

	SpaceHelpers:grantSpaceSkill(player, "pilot_neutral_novice", false)

	lu.assertTrue(CreatureObject(player):hasSkill("pilot_neutral_novice"))
	lu.assertEquals(#H.Engine.callsTo("awardSkill"), 1)
	lu.assertEquals(player.messages[1].stringId, "@skill_teacher:prose_skill_learned")
	lu.assertEquals(player.messages[1].params.TO, "@skl_n:pilot_neutral_novice")
end

function TestHarnessFakes:test_pilot_tier_and_faction_standing_fakes()
	local player = H.newPlayer({ pilotTier = 3, factionStanding = { rebel = -5 } })
	local ghost = PlayerObject(player.ghost)

	lu.assertEquals(ghost:getPilotTier(), 3)
	ghost:incrementPilotTier()
	lu.assertEquals(ghost:getPilotTier(), 4)

	lu.assertEquals(ghost:getFactionStanding("rebel"), -5)
	lu.assertEquals(ghost:getFactionStanding("imperial"), 0, "unset standing reads 0")
	ghost:increaseFactionStanding("rebel", 150)
	lu.assertEquals(ghost:getFactionStanding("rebel"), 145)
end

function TestHarnessFakes:test_quest_status_is_string_valued_per_player_and_cleared_by_reset()
	local player = H.newPlayer({ questStatus = { ["quest_a:attempted"] = 1 } })

	lu.assertEquals(getQuestStatus(player.objectID .. "quest_a:attempted"), "1")
	lu.assertNil(getQuestStatus(player.objectID .. "quest_a:reward"))

	setQuestStatus(player.objectID .. "quest_a:reward", 1)
	lu.assertEquals(H.getQuestStatus(player, "quest_a:reward"), "1", "setQuestStatus(key, 1) reads back as the string '1'")

	removeQuestStatus(player.objectID .. "quest_a:reward")
	lu.assertNil(H.getQuestStatus(player, "quest_a:reward"))

	H.reset()
	lu.assertNil(getQuestStatus(player.objectID .. "quest_a:attempted"), "reset clears quest status")
end

function TestHarnessFakes:test_xp_deducting_skill_grant_is_recorded_apart_from_the_free_grant()
	local player = H.newPlayer({})

	SpaceHelpers:grantSpaceSkill(player, "pilot_rebel_navy_droid_04", true)

	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1)
	lu.assertEquals(H.Engine.callsTo("skillManagerAwardSkill")[1][2], "pilot_rebel_navy_droid_04")
	lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0)
	lu.assertTrue(CreatureObject(player):hasSkill("pilot_rebel_navy_droid_04"))
end

function TestHarnessFakes:test_spy_on_replaces_a_method_records_calls_and_is_restored_by_reset()
	local target = { go = function() return "real" end }
	local calls = H.spyOn(target, "go", function(self, a) return a * 2 end)

	target:go(21)

	lu.assertEquals(#calls, 1)
	lu.assertEquals(calls[1].args[1], 21)
	lu.assertEquals(calls[1].snapshot, 42)

	H.reset()
	lu.assertEquals(target:go(), "real", "H.reset restores spied methods")
end

function TestHarnessFakes:test_havoc_squadron_constant_comes_from_director_manager()
	lu.assertNotNil(rawget(_G, "HAVOC_SQUADRON"), "HAVOC_SQUADRON from DirectorManager.cpp")

	local player = H.newPlayer({ squadronType = HAVOC_SQUADRON })
	lu.assertTrue(SpaceHelpers:isHavocSquadron(player))
	lu.assertFalse(SpaceHelpers:isHavocSquadron(H.newPlayer({ squadronType = CORSEC_SQUADRON })))
end

function TestHarnessFakes:test_creature_template_loader_registers_the_template()
	local t = H.loadCreatureTemplate("space/warvog_arkon.lua", "warvog_arkon")

	lu.assertNotNil(t, "warvog_arkon template registered")
	lu.assertEquals(t.objectName, "@npc_spawner_n:warvog_arkon")
end

function TestHarnessFakes:test_option_bitmask_globals_are_real_bit_flags()
	lu.assertEquals(CONVERSABLE, 0x8)
	lu.assertEquals(AIENABLED, 0x80)
	lu.assertEquals(JTLINTERESTING, 0x8000)
end

function TestHarnessFakes:test_swgjava_keeps_start_node_lines_out_of_the_last_branch_successors()
	local Swgjava = require("harness.swgjava")
	local graph = Swgjava.parse([[
    public int OnStartNpcConversation(obj_id self, obj_id player) throws InterruptedException
    {
        if (cond(player, npc))
        {
            string_id message = new string_id(c_stringFile, "s_start");
            responses[responseIndex++] = new string_id(c_stringFile, "s_r1");
            utils.setScriptVar(player, "conversation.x.branchId", 1);
        }
    }
    public int x_handleBranch1(obj_id player, obj_id npc, string_id response) throws InterruptedException
    {
        if (response.equals("s_r1"))
        {
            string_id message = new string_id(c_stringFile, "s_next");
            npcEndConversationWithMessage(player, message);
        }
    }
]])
	lu.assertEquals(graph.edges[1].s_r1, { "s_next" })

	-- start function placed after a branch function must not extend that branch's edges
	local after = Swgjava.parse([[
    public int x_handleBranch1(obj_id player, obj_id npc, string_id response) throws InterruptedException
    {
        if (response.equals("s_r1"))
        {
            string_id message = new string_id(c_stringFile, "s_next");
        }
    }
    public int OnStartNpcConversation(obj_id self, obj_id player) throws InterruptedException
    {
        string_id message = new string_id(c_stringFile, "s_start");
    }
]])
	lu.assertEquals(after.edges[1].s_r1, { "s_next" })
	lu.assertNotNil(after.nodes.s_start)
end

function TestHarnessFakes:test_swgjava_tier4_answer_key_has_no_start_lines_as_successors()
	local Swgjava = require("harness.swgjava")
	local graph = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_rebel_tier4.java")

	for branch, byResponse in pairs(graph.edges) do
		for response, successors in pairs(byResponse) do
			for _, sid in ipairs(successors) do
				lu.assertNotEquals(sid, "s_92c6d3dd", "branch " .. branch .. " response " .. response .. " must not list the first start-node line")
			end
		end
	end

	local last = graph.edges[186] and graph.edges[186].s_9775f996

	lu.assertTrue(last == nil or #last == 1, "branch 186 (the last branch) must have at most its own successor, got " .. tostring(last and table.concat(last, ",")))
end
