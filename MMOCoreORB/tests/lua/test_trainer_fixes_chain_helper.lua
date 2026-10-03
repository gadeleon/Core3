-- The shared split-chain helper in SpaceHelpers: walk, "any member active" and clear-then-start.
-- Spec: .claude/work/space-trainer-fixes/01-spec.md (AC-1, AC-2)

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")

T.load()
H.loadScreenplay("space/conversations/rebel/havoc_squadron/arkonConvoHandler.lua")
H.loadScreenplay("space/conversations/neutral/rsf_squadron/imlerConvoHandler.lua")

local function helperFn(name)
	local fn = SpaceHelpers[name]

	lu.assertEquals(type(fn), "function", "SpaceHelpers:" .. name .. " is not defined (utils/space_helpers.lua)")

	return fn
end

-- Every mission of the ten legacy trainers: { trainer label, mission number, expected chain }
local function allChains()
	local rows = {}

	for _, key in ipairs(T.ORDER) do
		local tr = T.TRAINERS[key]

		for n = 1, 4 do
			rows[#rows + 1] = { tr = tr, n = n, chain = tr.chains[n], name = tr.label .. " mission " .. n }
		end
	end

	return rows
end

local function sorted(list)
	local copy = {}

	for i, v in ipairs(list) do
		copy[i] = v
	end

	table.sort(copy)
	return copy
end

local function globalsOf(entries)
	local out = {}

	for i, e in ipairs(entries) do
		out[i] = e.global
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-1: the chain walk
---------------------------------------------------------------------------------------------

TestSpaceQuestChainWalk = {}

function TestSpaceQuestChainWalk:setUp()
	H.reset()
end

-- AC-1
function TestSpaceQuestChainWalk:test_every_trainer_mission_walks_to_exactly_the_listed_chain_in_order()
	local walk = helperFn("getSpaceQuestChain")

	for _, row in ipairs(allChains()) do
		local entries = walk(SpaceHelpers, row.chain[1])

		lu.assertEquals(globalsOf(entries), row.chain, row.name .. ": chain globals")
	end
end

-- AC-1
function TestSpaceQuestChainWalk:test_each_chain_entry_carries_the_type_and_name_of_its_global()
	local walk = helperFn("getSpaceQuestChain")

	for _, row in ipairs(allChains()) do
		for i, entry in ipairs(walk(SpaceHelpers, row.chain[1])) do
			local q = T.quest(entry.global)

			lu.assertEquals(entry.type, q.questType, row.name .. ": " .. entry.global .. " type")
			lu.assertEquals(entry.name, q.questName, row.name .. ": " .. entry.global .. " name")
		end
	end
end

-- AC-1
function TestSpaceQuestChainWalk:test_a_head_that_is_not_a_global_has_an_empty_chain()
	local walk = helperFn("getSpaceQuestChain")

	lu.assertEquals(walk(SpaceHelpers, "no_such_quest"), {}, "getSpaceQuestChain('no_such_quest')")
end

local function questGlobalOf(constant)
	return constant.type .. "_" .. constant.name
end

-- AC-1
function TestSpaceQuestChainWalk:test_arkon_missions_walk_to_the_set_of_the_handler_missions()
	local walk = helperFn("getSpaceQuestChain")

	for n = 1, 4 do
		local mission = arkonConvoHandler.MISSIONS[n]
		local expected = { questGlobalOf(HavocSquadronScreenplay[mission.main]) }

		for _, child in ipairs(mission.children) do
			expected[#expected + 1] = questGlobalOf(HavocSquadronScreenplay[child])
		end

		local actual = globalsOf(walk(SpaceHelpers, expected[1]))

		lu.assertEquals(sorted(actual), sorted(expected), "Arkon mission " .. n .. ": chain set")
		lu.assertEquals(actual[1], expected[1], "Arkon mission " .. n .. ": the head comes first")
	end
end

-- AC-1
function TestSpaceQuestChainWalk:test_imler_missions_walk_to_the_set_of_the_handler_chains()
	local walk = helperFn("getSpaceQuestChain")

	for n = 1, 4 do
		local mission = imlerConvoHandler.MISSIONS[n]
		local expected = {}

		for _, constant in ipairs(mission.chain) do
			expected[#expected + 1] = questGlobalOf(RsfSquadronScreenplay[constant])
		end

		local actual = globalsOf(walk(SpaceHelpers, expected[1]))

		lu.assertEquals(sorted(actual), sorted(expected), "Imler mission " .. n .. ": chain set")
		lu.assertEquals(actual[1], expected[1], "Imler mission " .. n .. ": the head comes first")
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: the walk rule on synthetic quests (the rule mirrors the runtime split triggers)
---------------------------------------------------------------------------------------------

TestSpaceQuestChainWalkRule = {}

local SYNTHETIC = {}

-- Defines patrol_zz_<name> as a quest table. Fields override the defaults of SpaceQuestLogic.
local function synth(name, fields)
	fields = fields or {}
	fields.className = "patrol_zz_" .. name
	fields.questType = "patrol"
	fields.questName = "zz_" .. name

	local q = SpaceQuestLogic:new(fields)

	_G["patrol_zz_" .. name] = q
	SYNTHETIC[#SYNTHETIC + 1] = "patrol_zz_" .. name

	return q
end

local SPLIT = { COMPLETION = 1, FAILURE = 2, BIDIRECTIONAL = 3, PATROL_POINT = 4 }

local function child(name, splitType, failName)
	local fields = { sideQuest = true, sideQuestType = "patrol", sideQuestName = "zz_" .. name, sideQuestSplitType = splitType }

	if failName then
		fields.sideFailQuestType = "patrol"
		fields.sideFailQuestName = "zz_" .. failName
	end

	return fields
end

function TestSpaceQuestChainWalkRule:setUp()
	H.reset()
end

function TestSpaceQuestChainWalkRule:tearDown()
	for _, g in ipairs(SYNTHETIC) do
		_G[g] = nil
	end

	SYNTHETIC = {}
end

-- AC-1
function TestSpaceQuestChainWalkRule:test_a_single_quest_without_a_side_quest_is_its_own_chain()
	synth("a")

	lu.assertEquals(globalsOf(helperFn("getSpaceQuestChain")(SpaceHelpers, "patrol_zz_a")), { "patrol_zz_a" })
end

-- AC-1
function TestSpaceQuestChainWalkRule:test_the_side_quest_of_a_completion_split_follows_the_head()
	synth("a", child("b", SPLIT.COMPLETION))
	synth("b")

	lu.assertEquals(globalsOf(helperFn("getSpaceQuestChain")(SpaceHelpers, "patrol_zz_a")), { "patrol_zz_a", "patrol_zz_b" })
end

-- AC-1
function TestSpaceQuestChainWalkRule:test_the_side_quest_of_a_patrol_point_split_follows_the_head()
	synth("a", child("b", SPLIT.PATROL_POINT))
	synth("b")

	lu.assertEquals(globalsOf(helperFn("getSpaceQuestChain")(SpaceHelpers, "patrol_zz_a")), { "patrol_zz_a", "patrol_zz_b" })
end

-- AC-1
function TestSpaceQuestChainWalkRule:test_the_walk_is_depth_first_with_the_side_quest_before_the_failure_quest()
	local a = child("b", SPLIT.BIDIRECTIONAL, "c")

	synth("a", a)
	synth("b", child("d", SPLIT.COMPLETION))
	synth("c")
	synth("d")

	lu.assertEquals(globalsOf(helperFn("getSpaceQuestChain")(SpaceHelpers, "patrol_zz_a")), { "patrol_zz_a", "patrol_zz_b", "patrol_zz_d", "patrol_zz_c" })
end

-- AC-1
function TestSpaceQuestChainWalkRule:test_a_failure_split_adds_the_failure_quest_too()
	synth("a", child("b", SPLIT.FAILURE, "c"))
	synth("b")
	synth("c")

	lu.assertEquals(globalsOf(helperFn("getSpaceQuestChain")(SpaceHelpers, "patrol_zz_a")), { "patrol_zz_a", "patrol_zz_b", "patrol_zz_c" })
end

-- AC-1
function TestSpaceQuestChainWalkRule:test_a_completion_split_does_not_follow_a_stale_failure_quest()
	synth("a", child("b", SPLIT.COMPLETION, "c"))
	synth("b")
	synth("c")

	lu.assertEquals(globalsOf(helperFn("getSpaceQuestChain")(SpaceHelpers, "patrol_zz_a")), { "patrol_zz_a", "patrol_zz_b" })
end

-- AC-1
function TestSpaceQuestChainWalkRule:test_a_quest_with_side_quest_false_ends_the_chain_even_with_stale_side_strings()
	local fields = child("b", SPLIT.BIDIRECTIONAL, "c")

	fields.sideQuest = false

	synth("a", fields)
	synth("b")
	synth("c")

	lu.assertEquals(globalsOf(helperFn("getSpaceQuestChain")(SpaceHelpers, "patrol_zz_a")), { "patrol_zz_a" })
end

-- AC-1
function TestSpaceQuestChainWalkRule:test_a_side_quest_whose_global_does_not_exist_is_skipped()
	synth("a", child("missing", SPLIT.BIDIRECTIONAL, "c"))
	synth("c")

	lu.assertEquals(globalsOf(helperFn("getSpaceQuestChain")(SpaceHelpers, "patrol_zz_a")), { "patrol_zz_a", "patrol_zz_c" })
end

-- AC-1
function TestSpaceQuestChainWalkRule:test_empty_side_quest_strings_are_skipped()
	synth("a", { sideQuest = true, sideQuestType = "", sideQuestName = "", sideQuestSplitType = SPLIT.COMPLETION })

	lu.assertEquals(globalsOf(helperFn("getSpaceQuestChain")(SpaceHelpers, "patrol_zz_a")), { "patrol_zz_a" })
end

-- AC-1
function TestSpaceQuestChainWalkRule:test_a_cycle_and_a_shared_child_list_each_quest_once()
	synth("a", child("b", SPLIT.BIDIRECTIONAL, "c"))
	synth("b", child("a", SPLIT.COMPLETION))
	synth("c", child("b", SPLIT.COMPLETION))

	lu.assertEquals(globalsOf(helperFn("getSpaceQuestChain")(SpaceHelpers, "patrol_zz_a")), { "patrol_zz_a", "patrol_zz_b", "patrol_zz_c" })
end

---------------------------------------------------------------------------------------------
-- AC-2: any member active, clear-then-start and the refusal
---------------------------------------------------------------------------------------------

TestSpaceQuestChainStart = {}

function TestSpaceQuestChainStart:setUp()
	H.reset()
end

local function playerWith(chain, complete, active)
	local player = H.newPlayer({ pilot = "neutral" })

	for _, g in ipairs(complete or {}) do
		T.setState(player, g, "complete")
	end

	for _, g in ipairs(active or {}) do
		T.setState(player, g, "active")
	end

	return player
end

-- AC-2
function TestSpaceQuestChainStart:test_is_chain_active_is_true_when_any_member_is_active()
	local isActive = helperFn("isSpaceQuestChainActive")

	for _, row in ipairs(allChains()) do
		lu.assertFalse(isActive(SpaceHelpers, playerWith(row.chain), row.chain[1]), row.name .. ": nothing active")
		lu.assertFalse(isActive(SpaceHelpers, playerWith(row.chain, row.chain), row.chain[1]), row.name .. ": everything complete")

		for i, g in ipairs(row.chain) do
			lu.assertTrue(isActive(SpaceHelpers, playerWith(row.chain, nil, { g }), row.chain[1]), row.name .. ": member " .. i .. " (" .. g .. ") active")
		end
	end
end

-- AC-2
function TestSpaceQuestChainStart:test_a_chain_of_an_unknown_head_is_never_active()
	local isActive = helperFn("isSpaceQuestChainActive")

	lu.assertFalse(isActive(SpaceHelpers, H.newPlayer({}), "no_such_quest"), "isSpaceQuestChainActive('no_such_quest')")
end

-- AC-2
function TestSpaceQuestChainStart:test_every_member_is_cleared_before_the_head_starts_and_the_head_starts_once()
	local start = helperFn("startSpaceQuestChain")

	for _, row in ipairs(allChains()) do
		H.reset()

		local head = T.quest(row.chain[1])
		local player = playerWith(row.chain, row.chain)
		local calls = H.spyOn(head, "startQuest", function(_, pPlayer)
			local seen = {}

			for _, g in ipairs(row.chain) do
				seen[g] = T.state(pPlayer, g)
			end

			return seen
		end)

		start(SpaceHelpers, player, H.newNpc({}), row.chain[1])

		lu.assertEquals(#calls, 1, row.name .. ": startQuest calls")

		for _, g in ipairs(row.chain) do
			lu.assertEquals(calls[1].snapshot[g], "none", row.name .. ": " .. g .. " when startQuest ran")
		end
	end
end

-- AC-2
function TestSpaceQuestChainStart:test_the_head_is_started_with_the_player_and_the_npc()
	local start = helperFn("startSpaceQuestChain")
	local chain = T.TRAINERS.turoldine.chains[4]
	local head = T.quest(chain[1])
	local calls = H.spyOn(head, "startQuest")
	local player, npc = playerWith(chain, chain), H.newNpc({})

	start(SpaceHelpers, player, npc, chain[1])

	lu.assertTrue(calls[1].args[1] == player, "startQuest got the player")
	lu.assertTrue(calls[1].args[2] == npc, "startQuest got the npc")
end

-- AC-2
function TestSpaceQuestChainStart:test_the_clear_does_not_notify_the_client()
	local start = helperFn("startSpaceQuestChain")
	local chain = T.TRAINERS.ramna.chains[1]
	local player = playerWith(chain, chain)
	local clears = H.spyOn(player.ghost, "clearJournalQuest")

	H.spyOn(T.quest(chain[1]), "startQuest")
	start(SpaceHelpers, player, H.newNpc({}), chain[1])

	lu.assertEquals(#clears, #chain, "clearJournalQuest calls (one per member)")

	for i, call in ipairs(clears) do
		lu.assertEquals(call.args[2], false, "clearJournalQuest notify flag, call " .. i)
	end
end

-- AC-2
function TestSpaceQuestChainStart:test_unspied_every_mission_restarts_with_the_head_active_and_the_rest_absent()
	local start = helperFn("startSpaceQuestChain")

	for _, row in ipairs(allChains()) do
		H.reset()

		local player = playerWith(row.chain, row.chain)
		local result = start(SpaceHelpers, player, H.newNpc({}), row.chain[1])

		lu.assertTrue(result, row.name .. ": result")
		lu.assertEquals(T.state(player, row.chain[1]), "active", row.name .. ": head " .. row.chain[1])
		lu.assertEquals(#player.datapad.items, 1, row.name .. ": datapad missions")

		for i = 2, #row.chain do
			lu.assertEquals(T.state(player, row.chain[i]), "none", row.name .. ": " .. row.chain[i])
		end
	end
end

-- AC-2
function TestSpaceQuestChainStart:test_a_player_with_no_journal_state_gets_the_head_started()
	local start = helperFn("startSpaceQuestChain")
	local chain = T.TRAINERS.rhea.chains[1]
	local player = playerWith(chain)

	lu.assertTrue(start(SpaceHelpers, player, H.newNpc({}), chain[1]), "result")
	lu.assertEquals(T.state(player, chain[1]), "active", "head")
end

-- AC-2
function TestSpaceQuestChainStart:test_it_refuses_when_any_member_is_active_and_changes_nothing()
	local start = helperFn("startSpaceQuestChain")

	for _, row in ipairs(allChains()) do
		for i, activeGlobal in ipairs(row.chain) do
			H.reset()

			local complete = {}

			for k, g in ipairs(row.chain) do
				if k ~= i then
					complete[#complete + 1] = g
				end
			end

			local player = playerWith(row.chain, complete, { activeGlobal })
			local clears = H.spyOn(player.ghost, "clearJournalQuest")
			local starts = H.spyOn(T.quest(row.chain[1]), "startQuest")
			local before = T.journalSnapshot(player)
			local missions = #player.datapad.items
			local messages = #player.messageLog
			local result = start(SpaceHelpers, player, H.newNpc({}), row.chain[1])

			local label = row.name .. " with " .. activeGlobal .. " active: "

			lu.assertFalse(result, label .. "result")
			lu.assertEquals(#clears, 0, label .. "clearJournalQuest calls")
			lu.assertEquals(#starts, 0, label .. "startQuest calls")
			lu.assertEquals(T.journalSnapshot(player), before, label .. "journal")
			lu.assertEquals(#player.datapad.items, missions, label .. "datapad missions")
			lu.assertEquals(#player.messageLog, messages, label .. "messages")
		end
	end
end
