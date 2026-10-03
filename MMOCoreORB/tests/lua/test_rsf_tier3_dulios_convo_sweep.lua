-- Dulios (RSF tier 3): the handler/template agreement, dynamic part. Every one of the 158 template screens is entered through
-- runScreenHandlers with spies on every quest's rewardPlayer / startQuest, on startSpaceQuestChain, grantSpaceSkill and the ghost's
-- incrementPilotTier. Calls may happen only on the screens Content contract 2 lists.
-- Spec: .claude/work/rsf-tier3-dulios-convo/01-spec.md (AC-9, invariants I-4, I-5, I-6, Content contract 2 runScreenHandlers).
-- Pilot: RSF tier 3, missions 1-3 won and rewarded, mission 4 complete, three tier 3 skills, mission 4 :reward unset.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local G = require("rsf_gate_screens_data")
local D = require("rsf_tier3_dulios_convo_data")

T.load()

local tr = T.TRAINERS.dulios

local TRAIN_SKILL = {}

for _, entry in ipairs(D.TRAIN_CHOICES) do
	TRAIN_SKILL[entry[3]] = entry[1]
	TRAIN_SKILL[entry[3] .. "_final"] = entry[1]
end

-- T.player marks missions 1-3 as attempted and rewarded; the sweep wants every :reward and :attempted key unset
local function sweepPilot()
	local player = T.player(tr, 4, { complete = tr.chains[4], attempted = false })

	for n = 1, 4 do
		removeQuestStatus(player.objectID .. D.KEYS[n] .. ":reward")
		removeQuestStatus(player.objectID .. D.KEYS[n] .. ":attempted")
	end

	return player
end

-- Enters screen `id` as the conversation observer does and returns what happened
local function enter(id, install)
	local player = sweepPilot()
	local spies = G.spies(player)

	if install then
		install(player)
	end

	local before = G.statusSnapshot()
	local tmpl = H.conversationTemplate(tr.template)
	local pScreen = LuaConversationTemplate(tmpl):getScreen(id)

	lu.assertNotNil(pScreen, "screen '" .. id .. "' is in " .. tr.template)

	local handler = H.expectGlobal(H.conversationTemplateTable(tr.template).luaClassHandler, "Dulios conversation handler")

	handler:runScreenHandlers(tmpl, player, H.newNpc({}), 0, pScreen)

	return { player = player, spies = spies, status = G.statusDiff(before, G.statusSnapshot()) }
end

local function heads(calls)
	local out = {}

	for i, c in ipairs(calls) do out[i] = c.args[3] end

	return out
end

local function screenIds()
	local ids = {}

	for _, s in ipairs(H.conversationTemplateTable(tr.template).screens) do
		ids[#ids + 1] = s.id
	end

	table.sort(ids)

	return ids
end

TestDuliosScreenSweep = {}

function TestDuliosScreenSweep:setUp() H.reset() end

-- AC-9 precondition: the sweep covers all 158 screens
function TestDuliosScreenSweep:test_the_sweep_enters_158_screens()
	lu.assertEquals(#screenIds(), 158, "screens in dulios_convo_template")
end

-- AC-9, I-4: payments only on the four reward screens, once, M_n's head, with the :reward key set first
function TestDuliosScreenSweep:test_only_the_four_reward_screens_pay_and_each_pays_its_own_head_once()
	for _, id in ipairs(screenIds()) do
		H.reset()

		local n = D.REWARD_SCREENS[id]
		local keyWhenPaid = {}

		-- Order: wraps the head's recorder and notes the :reward key at the moment rewardPlayer is called
		local r = enter(id, function(player)
			for m = 1, 4 do
				local head = rawget(_G, D.HEADS[m])
				local recorder = head.rewardPlayer

				head.rewardPlayer = function(self, pPlayer, ...)
					keyWhenPaid[#keyWhenPaid + 1] = tostring(H.getQuestStatus(pPlayer, D.KEYS[m] .. ":reward"))
					return recorder(self, pPlayer, ...)
				end
			end
		end)

		if n then
			lu.assertEquals(keyWhenPaid, { "1" }, id .. ": the :reward key when rewardPlayer was called (set first)")
			lu.assertEquals(r.spies.rewards, { D.HEADS[n] }, id .. ": rewardPlayer calls")
			lu.assertEquals(H.getQuestStatus(r.player, D.KEYS[n] .. ":reward"), "1", id .. ": :reward key")
		else
			lu.assertEquals(r.spies.rewards, {}, id .. ": rewardPlayer calls")
		end
	end
end

-- AC-9, I-5: only the 26 start screens start a chain, each with its mission's head, after setting that mission's :attempted
function TestDuliosScreenSweep:test_only_the_26_start_screens_start_a_chain_with_their_own_head_and_set_attempted()
	local started = 0

	for _, id in ipairs(screenIds()) do
		H.reset()

		local r = enter(id)
		local n = D.START_SCREENS[id]

		if n then
			started = started + 1
			lu.assertEquals(heads(r.spies.chains), { D.HEADS[n] }, id .. ": startSpaceQuestChain heads")
			lu.assertEquals(H.getQuestStatus(r.player, D.KEYS[n] .. ":attempted"), "1", id .. ": :attempted of mission " .. n)
		else
			lu.assertEquals(#r.spies.chains, 0, id .. ": startSpaceQuestChain calls")
		end

		lu.assertEquals(r.spies.starts, {}, id .. ": direct startQuest calls")
	end

	lu.assertEquals(started, 26, "start screens found in the template")
end

-- AC-9, I-6: only the 8 train_* screens grant a skill, each its own, free; no screen anywhere else touches skills or the tier
function TestDuliosScreenSweep:test_only_the_8_training_screens_grant_a_skill_each_its_own_and_free()
	local trained = 0

	for _, id in ipairs(screenIds()) do
		H.reset()

		local r = enter(id)
		local skill = TRAIN_SKILL[id]

		if skill then
			trained = trained + 1
			lu.assertEquals(#r.spies.skills, 1, id .. ": grantSpaceSkill calls")
			lu.assertEquals(r.spies.skills[1].args[2], skill, id .. ": granted skill")
			lu.assertEquals(r.spies.skills[1].args[3], false, id .. ": deductExperience")
		else
			lu.assertEquals(#r.spies.skills, 0, id .. ": grantSpaceSkill calls")
			lu.assertEquals(#r.spies.tiers, 0, id .. ": incrementPilotTier calls")
		end

		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, id .. ": XP-deducting grants")
		lu.assertEquals(#r.spies.squadron, 0, id .. ": setSquadronType calls")
	end

	lu.assertEquals(trained, 8, "training screens found in the template")
end

-- AC-9, I-4..I-6: no other status key is written anywhere, and the keys written are the ones above
function TestDuliosScreenSweep:test_the_only_quest_status_keys_written_are_reward_on_reward_screens_and_attempted_on_start_screens()
	for _, id in ipairs(screenIds()) do
		H.reset()

		local r = enter(id)
		local expected = {}
		local n = D.REWARD_SCREENS[id]
		local m = D.START_SCREENS[id]

		if n then
			expected[1] = tostring(r.player.objectID) .. D.KEYS[n] .. ":reward"
		elseif m then
			expected[1] = tostring(r.player.objectID) .. D.KEYS[m] .. ":attempted"
		end

		-- the mission 1-3 keys the pilot already has are unchanged, so a write of the same value is not a diff
		lu.assertEquals(r.status, expected, id .. ": quest status keys written")
	end
end

-- AC-9: the screen ids are matched exactly: a made-up id that merely contains a handler word does nothing
function TestDuliosScreenSweep:test_a_screen_id_that_only_contains_a_handler_word_does_nothing()
	local tmpl = H.conversationTemplate(tr.template)
	local handler = H.expectGlobal("duliosConvoHandler", "Dulios conversation handler")

	for _, id in ipairs({ "xcomplete_mission1", "complete_mission5", "xtrain_warships", "train_warships2", "m1_e1e07205x", "xm1_70" }) do
		local player = sweepPilot()
		local spies = G.spies(player)
		local before = G.statusSnapshot()
		-- A screen object with another id: a clone of on_mission, renamed (the fake screen carries its id in `id`)
		local fake = LuaConversationScreen(LuaConversationTemplate(tmpl):getScreen("on_mission")):cloneScreen()

		fake.id = id

		handler:runScreenHandlers(tmpl, player, H.newNpc({}), 0, fake)
		lu.assertEquals(spies.rewards, {}, id .. ": rewardPlayer calls")
		lu.assertEquals(#spies.chains, 0, id .. ": startSpaceQuestChain calls")
		lu.assertEquals(#spies.skills, 0, id .. ": grantSpaceSkill calls")
		lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), {}, id .. ": quest status keys written")
	end
end
