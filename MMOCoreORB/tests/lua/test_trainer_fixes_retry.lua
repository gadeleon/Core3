-- Story-mission starts in the ten legacy trainer handlers: retry after a failed child, every start
-- screen goes through the chain helper, flags unchanged.
-- Spec: .claude/work/space-trainer-fixes/01-spec.md (AC-3, AC-4, AC-7 second bullet, I-3, I-4)

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")

T.load()

local MSG_RECEIVED = "@space/quest:quest_received"

local function handlerOf(tr)
	return H.expectGlobal(H.conversationTemplateTable(tr.template).luaClassHandler, tr.label .. " conversation handler")
end

local function count(list, id)
	local n = 0

	for _, m in ipairs(list) do
		if m.id == id then
			n = n + 1
		end
	end

	return n
end

local function ids(transcript)
	local out = {}

	for i, t in ipairs(transcript) do
		out[i] = t.id
	end

	return table.concat(out, " > ")
end

local function describeChain(player, chain)
	return T.describe(player, chain)
end

local function chainedMissions()
	local rows = {}

	for _, key in ipairs(T.ORDER) do
		local tr = T.TRAINERS[key]

		for n = 1, 4 do
			if #tr.chains[n] > 1 then
				rows[#rows + 1] = { tr = tr, n = n }
			end
		end
	end

	return rows
end

---------------------------------------------------------------------------------------------
-- AC-3: retry after a failed child
---------------------------------------------------------------------------------------------

TestTrainerRetryAfterFailedChild = {}

function TestTrainerRetryAfterFailedChild:setUp()
	H.reset()
end

-- The player's chain state before talking: head complete, member `pos` failed (no entry), the members between
-- complete and the ones after it absent. Then talk to the trainer and take the start screen.
local function retryAfterFailure(tr, n, pos)
	local chain = tr.chains[n]
	local complete = T.before(tr, n, pos)
	local label = tr.label .. " mission " .. n .. ", " .. chain[pos] .. " failed: "

	local function build()
		return T.player(tr, n, { complete = complete })
	end

	lu.assertEquals(complete[1], chain[1], label .. "setup: the head is complete")

	local rec

	local transcript, err, player, first = T.driveToStart(tr, n, build, function() rec = T.spyRewards() end)

	lu.assertNotNil(transcript, label .. tostring(err))

	local ended = T.endedOnStart(tr, n, transcript)

	lu.assertNotNil(ended, label .. "the conversation ended on '" .. tostring(transcript[#transcript] and transcript[#transcript].id) .. "', not on a start screen of mission " .. n .. " (" .. ids(transcript) .. ")")

	lu.assertEquals(T.state(player, chain[1]), "active", label .. "head " .. chain[1] .. " after '" .. ended .. "' (" .. describeChain(player, chain) .. ")")

	for i = 2, #chain do
		lu.assertEquals(T.state(player, chain[i]), "none", label .. chain[i] .. " has no journal entry after '" .. ended .. "'")
	end

	lu.assertEquals(#player.datapad.items, 1, label .. "datapad missions")
	lu.assertEquals(player.datapad.items[1]:getQuestCRC(), T.crc(chain[1]), label .. "the datapad mission is the head's")
	lu.assertEquals(count(H.messageLog(player), MSG_RECEIVED), 1, label .. MSG_RECEIVED .. " messages")
	lu.assertEquals(rec.rewards, {}, label .. "rewardPlayer calls")
end

-- One test per chained mission and failed position
for _, row in ipairs(chainedMissions()) do
	for _, pos in ipairs(T.failPositions(row.tr, row.n)) do
		-- AC-3
		TestTrainerRetryAfterFailedChild[string.format("test_%s_mission_%d_restarts_from_the_head_after_chain_member_%d_failed", row.tr.label:lower(), row.n, pos)] = function()
			retryAfterFailure(row.tr, row.n, pos)
		end
	end
end

-- AC-3, AC-7
function TestTrainerRetryAfterFailedChild:test_turoldine_mission_4_shows_failed_fourth_mission_and_restarts_the_chain()
	local tr = T.TRAINERS.turoldine
	local chain = tr.chains[4]

	local transcript = T.converse(tr, T.player(tr, 4, { complete = { chain[1] } }))

	lu.assertNotNil(transcript[1], "Turoldine mission 4 failed-child state: no first screen")
	lu.assertEquals(transcript[1].id, "failed_fourth_mission", "Turoldine mission 4 failed-child state: first screen")
end

-- AC-3, AC-7
function TestTrainerRetryAfterFailedChild:test_turoldine_mission_4_activates_the_first_assassination_after_failed_fourth_mission()
	local tr = T.TRAINERS.turoldine
	local chain = tr.chains[4]
	local player = T.player(tr, 4, { complete = { chain[1] } })

	T.converse(tr, player)

	lu.assertEquals(T.state(player, "assassinate_corellia_privateer_tier4_4a"), "active", "assassinate_corellia_privateer_tier4_4a after the failed_fourth_mission screen")
end

-- AC-3 (a player whose earlier run completed the whole chain, e.g. after winning once and abandoning later)
function TestTrainerRetryAfterFailedChild:test_a_chain_with_every_member_complete_but_not_rewarded_is_not_a_retry()
	-- Rhea mission 1: head and surprise attack both complete is the win, so the reward is paid and no mission starts
	local tr = T.TRAINERS.rhea
	local rec = T.spyAllQuests()
	local player = T.player(tr, 1, { complete = tr.chains[1] })
	local transcript = T.converse(tr, player)

	lu.assertEquals(transcript[1].id, "excellent_work", "Rhea mission 1 won: first screen")
	lu.assertEquals(rec.rewards, { "patrol_corellia_privateer_1" }, "rewardPlayer calls")
	lu.assertEquals(rec.starts, {}, "startQuest calls")
end

---------------------------------------------------------------------------------------------
-- AC-4: every story start goes through the chain helper; flags unchanged
---------------------------------------------------------------------------------------------

TestTrainerStartScreens = {}

local originalStartChain

function TestTrainerStartScreens:setUp()
	H.reset()
	originalStartChain = SpaceHelpers.startSpaceQuestChain
end

function TestTrainerStartScreens:tearDown()
	SpaceHelpers.startSpaceQuestChain = originalStartChain
end

local function runStartScreen(tr, id, player, npc)
	local handler = handlerOf(tr)
	local tmpl = H.conversationTemplate(tr.template)
	local pScreen = LuaConversationTemplate(tmpl):getScreen(id)

	lu.assertNotNil(pScreen, tr.label .. ": screen '" .. id .. "' is not in " .. tr.template)

	handler:runScreenHandlers(tmpl, player, npc, 0, pScreen)
end

local function rewardFlags(tr, player)
	local out = {}

	for m = 1, 4 do
		out[m] = H.getQuestStatus(player, T.statusName(tr, m) .. ":reward")
	end

	return out
end

local function attemptedFlags(tr, player)
	local out = {}

	for m = 1, 4 do
		out[m] = H.getQuestStatus(player, T.statusName(tr, m) .. ":attempted")
	end

	return out
end

for _, key in ipairs(T.ORDER) do
	local tr = T.TRAINERS[key]

	for n = 1, 4 do
		local ids, sets = T.startScreens(tr, n)
		local chain = tr.chains[n]
		local name = string.format("%s_mission_%d", tr.label:lower(), n)

		-- AC-4
		TestTrainerStartScreens["test_" .. name .. "_start_screens_restart_a_finished_chain_with_the_head_active"] = function()
			for _, id in ipairs(ids) do
				H.reset()

				local player = T.player(tr, n, { complete = chain, attempted = false })
				local rewardsBefore = rewardFlags(tr, player)
				local label = tr.label .. " mission " .. n .. " screen '" .. id .. "': "

				runStartScreen(tr, id, player, H.newNpc({}))

				lu.assertEquals(T.state(player, chain[1]), "active", label .. "head " .. chain[1])

				for i = 2, #chain do
					lu.assertEquals(T.state(player, chain[i]), "none", label .. chain[i])
				end

				lu.assertEquals(rewardFlags(tr, player), rewardsBefore, label .. ":reward flags")

				-- missions before n carry :attempted = 1 from the player builder (when the handler uses the flag);
				-- mission n's flag is set by exactly the screens the spec marks
				local expected = {}

				for m = 1, 4 do
					if tr.usesAttempted and (m < n or (m == n and sets[id])) then
						expected[m] = "1"
					end
				end

				lu.assertEquals(attemptedFlags(tr, player), expected, label .. ":attempted flags")
			end
		end

		-- AC-4
		TestTrainerStartScreens["test_" .. name .. "_start_screens_start_nothing_while_a_chain_member_is_running"] = function()
			for _, id in ipairs(ids) do
				H.reset()

				local last = chain[#chain]
				local complete = {}

				for i = 1, #chain - 1 do
					complete[#complete + 1] = chain[i]
				end

				local player = T.player(tr, n, { complete = complete, active = { last }, attempted = false })
				local starts = H.spyOn(T.quest(chain[1]), "startQuest")
				local clears = H.spyOn(player.ghost, "clearJournalQuest")
				local journalBefore = T.journalSnapshot(player)
				local rewardsBefore = rewardFlags(tr, player)
				local missions = #player.datapad.items
				local label = tr.label .. " mission " .. n .. " screen '" .. id .. "' with " .. last .. " running: "

				runStartScreen(tr, id, player, H.newNpc({}))

				lu.assertEquals(#starts, 0, label .. "startQuest calls on the head")
				lu.assertEquals(#clears, 0, label .. "clearJournalQuest calls")
				lu.assertEquals(T.journalSnapshot(player), journalBefore, label .. "journal")
				lu.assertEquals(#player.datapad.items, missions, label .. "datapad missions")
				lu.assertEquals(rewardFlags(tr, player), rewardsBefore, label .. ":reward flags")
			end
		end

		-- AC-4, I-3
		TestTrainerStartScreens["test_" .. name .. "_start_screens_call_the_chain_helper_with_the_head"] = function()
			lu.assertEquals(type(SpaceHelpers.startSpaceQuestChain), "function", "SpaceHelpers:startSpaceQuestChain is not defined")

			for _, id in ipairs(ids) do
				H.reset()

				local calls = {}
				local real = originalStartChain

				SpaceHelpers.startSpaceQuestChain = function(self, ...)
					calls[#calls + 1] = table.pack(...)
					return real(self, ...)
				end

				local player = T.player(tr, n, { complete = chain, attempted = false })
				local npc = H.newNpc({})
				local label = tr.label .. " mission " .. n .. " screen '" .. id .. "': "

				runStartScreen(tr, id, player, npc)

				lu.assertEquals(#calls, 1, label .. "startSpaceQuestChain calls")
				lu.assertTrue(calls[1][1] == player, label .. "player argument")
				lu.assertTrue(calls[1][2] == npc, label .. "npc argument")
				lu.assertEquals(calls[1][3], chain[1], label .. "head argument")
			end
		end
	end
end
