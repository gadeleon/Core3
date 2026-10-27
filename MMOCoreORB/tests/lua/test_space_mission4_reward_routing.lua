-- Mission 4 rewards reach every pilot (space-mission4-reward-fixes): Kaydine, Rikkh, Turoldine and Viopa route an unpaid, won mission 4 to its reward screen
-- before any tier-done screen; Rikkh and Kaydine also let it through their "tier > 3" gate; Imler and Arkon already do and stay as they are.
-- Spec: .claude/work/space-mission4-reward-fixes/01-spec.md (C-1 .. C-3, I-1 .. I-3, AC-1 .. AC-5, D-8 .. D-10).
--
-- Pilots come from trainer_fixes_data.lua (T.player: missions 1..3 won and rewarded, the head chain of mission 4 complete) with an inventory, so the pay
-- route runs the real rewardPlayer. Imler and Arkon use the tier 4 builders. Expected credits and items are read from the head globals (spec Data mapping).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local RD = require("rsf_tier4_data")
local HD = require("havoc_tier4_data")
local D = require("space_trainer_rewards_data")

T.load()
H.loadMobile("conversations/space/neutral/rsf_squadron/imler_convo.lua")
H.loadScreenplay("space/conversations/neutral/rsf_squadron/imlerConvoHandler.lua")
H.loadMobile("conversations/space/rebel/havoc_squadron/arkon_convo.lua")
H.loadScreenplay("space/conversations/rebel/havoc_squadron/arkonConvoHandler.lua")

local E15 = "escort_naboo_privateer_15"
local HEAD = { -- trainer -> M4 head global (spec Data mapping)
	kaydine = "escort_naboo_privateer_15",
	rikkh = "assassinate_corellia_privateer_tier2_4a",
	turoldine = "assassinate_corellia_privateer_tier4_4a",
	viopa = "assassinate_viopa_rebel_4",
}
local PAY_SCREENS = { -- the screens that pay (kaydine: handler line 244-246; the rest D.PAY_SCREENS)
	kaydine = { "mission4_reward" },
	rikkh = D.PAY_SCREENS.rikkh[4],
	turoldine = D.PAY_SCREENS.turoldine[4],
	viopa = D.PAY_SCREENS.viopa[4],
}

local function tierSkills(faction, tier)
	local out = {}

	for _, s in ipairs({ "droid", "procedures", "starships", "weapons" }) do
		out[#out + 1] = string.format("pilot_%s_%s_0%d", faction, s, tier)
	end

	return out
end

local function ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- Builds the pilot of a trainer: all four skills of the trainer's tier, mission 4 won, `:reward` set only when opts.paid. opts: tier (pilot tier),
-- paid, skills (false: no tier skills), active (quest globals), inventory (true|nil), wonNothing (mission 4 not won)
local function pilot(key, opts)
	opts = opts or {}

	local tr = T.TRAINERS[key]
	local status = {}

	if opts.paid then
		status[T.statusName(tr, 4) .. ":reward"] = "1"
	end

	local skills = {}

	if opts.skills ~= false then
		if key == "kaydine" or key == "rikkh" then
			skills = tierSkills("neutral", 2)
		elseif key == "turoldine" then
			skills = tierSkills("neutral", 4)
		elseif key == "viopa" then
			skills = tierSkills("rebel_navy", 2)
		end
	end

	local complete

	if opts.wonNothing then
		complete = {}
	elseif key == "kaydine" then
		complete = { E15 }
	else
		complete = T.chain(tr, 4)
	end

	local player = T.player(tr, 4, { complete = complete, active = opts.active, skills = skills, questStatus = status, inventory = opts.inventory ~= false })

	if opts.tier then
		player.ghost:setPilotTier(opts.tier)
	end

	return player
end

local function imler(tier, paid)
	local p = RD.rsf({ tier4 = RD.SKILLS, completed = { "m4cw" }, rewards = paid and { 1, 2, 3, 4 } or { 1, 2, 3 }, met = true, pilotTier = tier })

	return p
end

local function arkon(tier, paid)
	return HD.havoc({ tier4 = HD.SKILLS, completed = { "m4c" }, rewards = paid and { 1, 2, 3, 4 } or { 1, 2, 3 }, met = true, pilotTier = tier })
end

local function converse(key, player, choices)
	if key == "imler" then
		return H.converse({ template = "imler_convo_template", player = player, npc = H.newNpc({ name = "Imler" }), choices = choices })
	elseif key == "arkon" then
		return H.converse({ template = "arkon_convo", player = player, npc = H.newNpc({ name = "Arkon" }), choices = choices })
	end

	return T.converse(T.TRAINERS[key], player, choices)
end

local function statusKey(key) return T.statusName(T.TRAINERS[key], 4) .. ":reward" end

local function head(key) return H.expectGlobal(HEAD[key], "M4 head of " .. key) end

-- giveItem calls into this pilot's inventory
local function itemsGiven(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory then
			out[#out + 1] = call[2]
		end
	end

	return out
end

-- the first entry of the head's itemReward that fits a human pilot (what SpaceQuestLogic:rewardPlayer gives)
local function expectedItem(quest)
	for _, entry in ipairs(quest.itemReward) do
		for _, species in ipairs(entry.species) do
			if species == 0 or species == -1 then
				return entry.item
			end
		end
	end
end

-- A fresh visit that follows the path to the pay screen. `build` returns a fresh pilot each call.
local function walkToPay(key, build)
	local tr = T.TRAINERS[key]
	local probe = T.converse(tr, build())
	local set = {}

	for _, id in ipairs(PAY_SCREENS[key]) do
		set[id] = true
	end

	local path = T.optionPath(tr.template, probe[1].id, set)

	lu.assertNotNil(path, key .. ": no pay screen (" .. table.concat(PAY_SCREENS[key], "/") .. ") reachable from the first screen '" .. tostring(probe[1].id) .. "'")

	local player = build()
	local transcript = T.converse(tr, player, path)

	return transcript, player
end

-- Asserts the first screen first (a readable failure), then talks again with a fresh pilot and picks `sid` on it. Returns transcript, player.
local function viaSid(key, build, firstId, sid)
	local first = converse(key, build())[1]

	lu.assertEquals(first and first.id, firstId, key .. ": first screen")

	local player = build()

	return converse(key, player, { sid }), player
end

local function assertPaidOnce(key, player, label)
	local quest = head(key)

	lu.assertEquals(player.bankCredits, quest.creditReward, label .. ": bank credits")
	lu.assertEquals(#player.bankCreditLog, 1, label .. ": addBankCredits calls")
	lu.assertEquals(itemsGiven(player), { expectedItem(quest) }, label .. ": giveItem(inventory, item) calls")
	lu.assertEquals(H.getQuestStatus(player, statusKey(key)), "1", label .. ": " .. statusKey(key))
end

local function assertNothingPaid(player, label)
	lu.assertEquals(player.bankCredits, 0, label .. ": bank credits")
	lu.assertEquals(itemsGiven(player), {}, label .. ": giveItem calls")
end

---------------------------------------------------------------------------------------------
-- AC-1: Kaydine pays mission 4 at pilot tier 3, 4 and 5
---------------------------------------------------------------------------------------------

TestMission4KaydinePays = {}

function TestMission4KaydinePays:setUp() H.reset() end

for _, tier in ipairs({ 3, 4, 5 }) do
	-- AC-1, I-1
	TestMission4KaydinePays["test_kaydine_offers_the_mission_4_reward_to_a_tier_" .. tier .. "_pilot_who_won_it"] = function()
		local transcript = viaSid("kaydine", function() return pilot("kaydine", { tier = tier }) end, "mission4_complete", "s_588f56b2")

		lu.assertEquals(ids(transcript), { "mission4_complete", "mission4_reward" }, "kaydine tier " .. tier .. ": screens")
	end

	-- AC-1, I-2
	TestMission4KaydinePays["test_kaydine_pays_5000_credits_and_the_w19_droid_interface_once_to_a_tier_" .. tier .. "_pilot"] = function()
		local _, player = viaSid("kaydine", function() return pilot("kaydine", { tier = tier }) end, "mission4_complete", "s_588f56b2")
		local quest = head("kaydine")

		lu.assertEquals(quest.creditReward, 5000, "escort_naboo_privateer_15: creditReward")
		lu.assertEquals(expectedItem(quest), "object/tangible/ship/components/droid_interface/ddi_mission_reward_neutral_sorosuub_w19.iff", "escort_naboo_privateer_15: item")
		assertPaidOnce("kaydine", player, "kaydine tier " .. tier)
	end

	-- AC-1: the pilot tier is unchanged
	TestMission4KaydinePays["test_kaydine_leaves_the_pilot_tier_" .. tier .. "_alone_while_paying"] = function()
		local _, player = viaSid("kaydine", function() return pilot("kaydine", { tier = tier }) end, "mission4_complete", "s_588f56b2")

		lu.assertEquals(player.ghost:getPilotTier(), tier, "kaydine pilot tier after the pay visit")
	end

	-- AC-1, AC-2, I-2: after the pay, the next visit is finished_tier3 (tier >= 4) or completed_kaydine (tier 3) and pays nothing more
	TestMission4KaydinePays["test_kaydine_pays_nothing_on_the_visits_after_the_pay_at_tier_" .. tier] = function()
		local _, player = viaSid("kaydine", function() return pilot("kaydine", { tier = tier }) end, "mission4_complete", "s_588f56b2")

		local second = converse("kaydine", player)
		local third = converse("kaydine", player)

		lu.assertEquals(second[1].id, tier >= 4 and "finished_tier3" or "completed_kaydine", "kaydine tier " .. tier .. ": second visit")
		lu.assertEquals(third[1].id, tier >= 4 and "finished_tier3" or "completed_kaydine", "kaydine tier " .. tier .. ": third visit")
		assertPaidOnce("kaydine", player, "kaydine tier " .. tier .. " after three visits")
	end
end

-- AC-1 (R-1): the pay screen's follow-up is the existing one (SWG shows the same lines to a tier 4 pilot)
function TestMission4KaydinePays:test_kaydine_mission4_reward_at_tier_4_keeps_its_two_follow_up_options()
	local reward = viaSid("kaydine", function() return pilot("kaydine", { tier = 4 }) end, "mission4_complete", "s_588f56b2")[2]
	local options = {}

	for i, o in ipairs(reward.options) do
		options[i] = { o.text, o.link }
	end

	lu.assertEquals(options, {
		{ "@conversation/naboo_privateer_trainer_2:s_c261cfae", "mission4_reward_dulios" },
		{ "@conversation/naboo_privateer_trainer_2:s_725573da", "completed_kaydine_end" },
	}, "mission4_reward: options")
end

---------------------------------------------------------------------------------------------
-- AC-2: Kaydine at tier >= 4 is otherwise unchanged
---------------------------------------------------------------------------------------------

TestMission4KaydineUnchanged = {}

function TestMission4KaydineUnchanged:setUp() H.reset() end

for _, tier in ipairs({ 4, 5 }) do
	-- AC-2, I-3
	TestMission4KaydineUnchanged["test_kaydine_sends_a_tier_" .. tier .. "_pilot_with_mission_4_paid_to_finished_tier3"] = function()
		local player = pilot("kaydine", { tier = tier, paid = true })
		local transcript = converse("kaydine", player, { 0 })

		lu.assertEquals(ids(transcript), { "finished_tier3", "completed_kaydine_end" }, "kaydine tier " .. tier .. " paid: screens")
		lu.assertEquals(player.ghost:getPilotTier(), tier, "pilot tier")
		assertNothingPaid(player, "kaydine tier " .. tier .. " paid")
	end

	-- AC-2
	TestMission4KaydineUnchanged["test_kaydine_sends_a_tier_" .. tier .. "_pilot_who_never_won_mission_4_to_finished_tier3"] = function()
		local player = pilot("kaydine", { tier = tier, wonNothing = true })
		local transcript = converse("kaydine", player, { 0 })

		lu.assertEquals(transcript[1].id, "finished_tier3", "kaydine tier " .. tier .. " never won: first screen")
		assertNothingPaid(player, "kaydine tier " .. tier .. " never won")
	end

	-- AC-2, D-5: mission 4 still running
	TestMission4KaydineUnchanged["test_kaydine_sends_a_tier_" .. tier .. "_pilot_with_mission_4_still_running_to_finished_tier3"] = function()
		local player = pilot("kaydine", { tier = tier, wonNothing = true, active = { E15 } })

		lu.assertEquals(converse("kaydine", player)[1].id, "finished_tier3", "kaydine tier " .. tier .. " running: first screen")
	end

	-- AC-2: an unpaid win of an earlier mission cannot exist at tier >= 4 (D-3); the gate keeps its text for them
	TestMission4KaydineUnchanged["test_kaydine_gate_at_tier_" .. tier .. "_still_hides_the_signup_and_the_other_screens"] = function()
		local player = pilot("kaydine", { tier = tier, paid = true, skills = false })

		lu.assertEquals(converse("kaydine", player)[1].id, "finished_tier3", "kaydine tier " .. tier .. " paid, no skills: first screen")
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: Rikkh, Turoldine and Viopa pay before the tier-done screen
---------------------------------------------------------------------------------------------

local TIER_DONE = {
	rikkh = { first = "complete_fourth_mission", done = "completed_rikkh", tierStart = 2, tierAfter = 3 },
	turoldine = { first = "fourth_mission_success", done = "master_mission", tierStart = 4, tierAfter = 5 },
	viopa = { first = "missions_complete", done = "completed_viopa", tierStart = 2, tierAfter = 3 },
}

TestMission4PayBeforeTierDone = {}

function TestMission4PayBeforeTierDone:setUp() H.reset() end

for _, key in ipairs({ "rikkh", "turoldine", "viopa" }) do
	local info = TIER_DONE[key]

	-- AC-3, I-1
	TestMission4PayBeforeTierDone["test_" .. key .. "_shows_the_mission_4_reward_screen_to_a_pilot_with_all_tier_skills_and_an_unpaid_win"] = function()
		local player = pilot(key, { tier = info.tierStart })

		lu.assertEquals(converse(key, player)[1].id, info.first, key .. ": first screen")
	end

	-- AC-3, I-2
	TestMission4PayBeforeTierDone["test_" .. key .. "_pays_the_head_credits_and_item_once_on_that_visit"] = function()
		local _, player = walkToPay(key, function() return pilot(key, { tier = info.tierStart }) end)

		assertPaidOnce(key, player, key)
	end

	-- AC-3: the pilot tier is not incremented on the pay visit
	TestMission4PayBeforeTierDone["test_" .. key .. "_does_not_raise_the_pilot_tier_on_the_pay_visit"] = function()
		local _, player = walkToPay(key, function() return pilot(key, { tier = info.tierStart }) end)

		lu.assertEquals(player.ghost:getPilotTier(), info.tierStart, key .. ": pilot tier after the pay visit")
	end

	-- AC-3: the next visit is the tier-done screen and raises the tier as before
	TestMission4PayBeforeTierDone["test_" .. key .. "_sends_the_paid_pilot_on_with_the_tier_done_screen_on_the_next_visit"] = function()
		local _, player = walkToPay(key, function() return pilot(key, { tier = info.tierStart }) end)
		local next = converse(key, player)

		lu.assertEquals(next[1].id, info.done, key .. ": second visit first screen")
		lu.assertEquals(player.ghost:getPilotTier(), info.tierAfter, key .. ": pilot tier after the second visit")
		assertPaidOnce(key, player, key .. " after two visits")
	end

	-- AC-3, I-2: a third visit pays nothing
	TestMission4PayBeforeTierDone["test_" .. key .. "_pays_nothing_on_later_visits"] = function()
		local _, player = walkToPay(key, function() return pilot(key, { tier = info.tierStart }) end)

		converse(key, player)
		converse(key, player)
		converse(key, player)

		assertPaidOnce(key, player, key .. " after four visits")
	end
end

-- AC-3: Turoldine's "won" is TIER4_QUEST_STRING_4_SIDE3 (assassinate corellia_privateer_tier4_4d), the last quest of the chain
function TestMission4PayBeforeTierDone:test_turoldine_does_not_show_the_reward_before_the_last_quest_of_the_chain_is_complete()
	local player = pilot("turoldine", { tier = 4 })

	T.setState(player, "assassinate_corellia_privateer_tier4_4d", "none")

	local first = converse("turoldine", player)[1].id

	lu.assertNotEquals(first, "fourth_mission_success", "turoldine with 4d not complete: first screen")
end

---------------------------------------------------------------------------------------------
-- AC-3 edges: the order of the other checks is unchanged
---------------------------------------------------------------------------------------------

TestMission4NeighboursUnchanged = {}

function TestMission4NeighboursUnchanged:setUp() H.reset() end

for _, key in ipairs({ "rikkh", "turoldine", "viopa" }) do
	local info = TIER_DONE[key]

	-- AC-3, I-3: with the reward paid, the tier-done branch is what it was
	TestMission4NeighboursUnchanged["test_" .. key .. "_still_shows_the_tier_done_screen_to_a_paid_pilot"] = function()
		local player = pilot(key, { tier = info.tierStart, paid = true })

		lu.assertEquals(converse(key, player)[1].id, info.done, key .. " paid: first screen")
		lu.assertEquals(player.ghost:getPilotTier(), info.tierAfter, key .. " paid: pilot tier after the visit")
		assertNothingPaid(player, key .. " paid")
	end

	-- AC-3: a pilot who is missing a tier skill reached the reward branch before and still does
	TestMission4NeighboursUnchanged["test_" .. key .. "_still_pays_a_pilot_who_lacks_tier_skills"] = function()
		local player = pilot(key, { tier = info.tierStart, skills = false })

		lu.assertEquals(converse(key, player)[1].id, info.first, key .. " no skills: first screen")
	end

	-- AC-3: a running quest of the trainer still comes first
	TestMission4NeighboursUnchanged["test_" .. key .. "_still_says_on_mission_to_a_pilot_with_a_running_duty"] = function()
		local squadron = key == "viopa" and HavocSquadronScreenplay or CorsecSquadronScreenplay
		local duty = key == "turoldine" and squadron.TIER4_QUEST_STRING_DUTY_1 or squadron.TIER2_QUEST_STRING_DUTY_1
		local player = pilot(key, { tier = info.tierStart, active = { duty.type .. "_" .. duty.name } })
		local expected = key == "viopa" and "has_mission" or "on_mission"

		lu.assertEquals(converse(key, player)[1].id, expected, key .. " duty running: first screen")
		assertNothingPaid(player, key .. " duty running")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: Rikkh's tier gate
---------------------------------------------------------------------------------------------

TestMission4RikkhTierGate = {}

function TestMission4RikkhTierGate:setUp() H.reset() end

for _, tier in ipairs({ 4, 5 }) do
	-- AC-4, D-10
	TestMission4RikkhTierGate["test_rikkh_offers_the_mission_4_reward_to_a_tier_" .. tier .. "_pilot_who_won_it"] = function()
		local player = pilot("rikkh", { tier = tier })

		lu.assertEquals(converse("rikkh", player)[1].id, "complete_fourth_mission", "rikkh tier " .. tier .. ": first screen")
	end

	-- AC-4, I-2
	TestMission4RikkhTierGate["test_rikkh_pays_the_tier_" .. tier .. "_pilot_once_on_s_6f9a9967"] = function()
		local transcript, player = viaSid("rikkh", function() return pilot("rikkh", { tier = tier }) end, "complete_fourth_mission", "s_6f9a9967")

		lu.assertEquals(ids(transcript), { "complete_fourth_mission", "fourth_mission_success" }, "rikkh tier " .. tier .. ": screens")
		lu.assertEquals(player.ghost:getPilotTier(), tier, "rikkh tier " .. tier .. ": pilot tier after the pay")
		assertPaidOnce("rikkh", player, "rikkh tier " .. tier)

		converse("rikkh", player)
		converse("rikkh", player)

		assertPaidOnce("rikkh", player, "rikkh tier " .. tier .. " after three visits")
	end

	-- AC-4
	TestMission4RikkhTierGate["test_rikkh_shows_finished_tier3_to_a_tier_" .. tier .. "_pilot_after_the_pay"] = function()
		local _, player = viaSid("rikkh", function() return pilot("rikkh", { tier = tier }) end, "complete_fourth_mission", "s_6f9a9967")

		lu.assertEquals(converse("rikkh", player)[1].id, "finished_tier3", "rikkh tier " .. tier .. ": visit after the pay")
	end

	-- AC-4
	TestMission4RikkhTierGate["test_rikkh_shows_finished_tier3_to_a_tier_" .. tier .. "_pilot_with_mission_4_paid"] = function()
		local player = pilot("rikkh", { tier = tier, paid = true })

		lu.assertEquals(converse("rikkh", player)[1].id, "finished_tier3", "rikkh tier " .. tier .. " paid: first screen")
		assertNothingPaid(player, "rikkh tier " .. tier .. " paid")
	end

	-- AC-4
	TestMission4RikkhTierGate["test_rikkh_shows_finished_tier3_to_a_tier_" .. tier .. "_pilot_who_never_won_mission_4"] = function()
		local player = pilot("rikkh", { tier = tier, wonNothing = true })

		lu.assertEquals(converse("rikkh", player)[1].id, "finished_tier3", "rikkh tier " .. tier .. " never won: first screen")
		assertNothingPaid(player, "rikkh tier " .. tier .. " never won")
	end

	-- AC-4: the carve-out does not need the tier skills
	TestMission4RikkhTierGate["test_rikkh_pays_a_tier_" .. tier .. "_pilot_who_won_mission_4_without_the_tier_skills"] = function()
		local player = pilot("rikkh", { tier = tier, skills = false })

		lu.assertEquals(converse("rikkh", player)[1].id, "complete_fourth_mission", "rikkh tier " .. tier .. " no skills: first screen")
	end

	-- AC-4 (spec C-3): a duty that is still running wins over the reward, as in the existing chain order
	TestMission4RikkhTierGate["test_rikkh_says_on_mission_to_a_tier_" .. tier .. "_pilot_with_an_unpaid_win_and_a_running_duty"] = function()
		local duty = CorsecSquadronScreenplay.TIER2_QUEST_STRING_DUTY_1
		local player = pilot("rikkh", { tier = tier, active = { duty.type .. "_" .. duty.name } })

		lu.assertEquals(converse("rikkh", player)[1].id, "on_mission", "rikkh tier " .. tier .. " duty running: first screen")
		assertNothingPaid(player, "rikkh tier " .. tier .. " duty running")
	end
end

-- AC-4: the tier 4 pilot with mission 4 running (not won) keeps finished_tier3
function TestMission4RikkhTierGate:test_rikkh_shows_finished_tier3_to_a_tier_4_pilot_with_mission_4_running()
	local player = pilot("rikkh", { tier = 4, wonNothing = true, active = { HEAD.rikkh } })

	lu.assertEquals(converse("rikkh", player)[1].id, "finished_tier3", "rikkh tier 4, mission 4 running: first screen")
end

---------------------------------------------------------------------------------------------
-- AC-5: the sweep, trainer x pilot tier
---------------------------------------------------------------------------------------------

-- { trainer, pilot tier, first screen when unpaid, first screen when paid, pilot tier after a visit when paid }
local CELLS = {
	{ "kaydine", 3, "mission4_complete", "completed_kaydine", 3 },
	{ "kaydine", 4, "mission4_complete", "finished_tier3", 4 },
	{ "kaydine", 5, "mission4_complete", "finished_tier3", 5 },
	{ "rikkh", 3, "complete_fourth_mission", "completed_rikkh", 3 },
	{ "rikkh", 4, "complete_fourth_mission", "finished_tier3", 4 },
	{ "rikkh", 5, "complete_fourth_mission", "finished_tier3", 5 },
	{ "turoldine", 4, "fourth_mission_success", "master_mission", 5 },
	{ "turoldine", 5, "fourth_mission_success", "master_mission", 5 },
	{ "viopa", 3, "missions_complete", "completed_viopa", 3 },
	{ "viopa", 4, "missions_complete", "completed_viopa", 4 },
	{ "viopa", 5, "missions_complete", "completed_viopa", 5 },
	{ "imler", 4, "mission4_reward", "no_master", 5 },
	{ "imler", 5, "mission4_reward", "no_master", 5 },
	{ "arkon", 4, "mission4_reward", "no_master", 5 },
	{ "arkon", 5, "mission4_reward", "no_master", 5 },
}

local function cellPilot(key, tier, paid)
	if key == "imler" then
		return imler(tier, paid)
	elseif key == "arkon" then
		return arkon(tier, paid)
	end

	return pilot(key, { tier = tier, paid = paid })
end

TestMission4Sweep = {}

function TestMission4Sweep:setUp() H.reset() end

for _, cell in ipairs(CELLS) do
	local key, tier, unpaid, paid, tierAfter = cell[1], cell[2], cell[3], cell[4], cell[5]

	-- AC-5, I-1
	TestMission4Sweep["test_" .. key .. "_tier_" .. tier .. "_shows_" .. unpaid .. "_to_a_pilot_with_an_unpaid_mission_4_win"] = function()
		lu.assertEquals(converse(key, cellPilot(key, tier, false))[1].id, unpaid, key .. " tier " .. tier .. " unpaid: first screen")
	end

	-- AC-5, I-3
	TestMission4Sweep["test_" .. key .. "_tier_" .. tier .. "_shows_" .. paid .. "_to_a_pilot_with_mission_4_paid"] = function()
		local player = cellPilot(key, tier, true)

		lu.assertEquals(converse(key, player)[1].id, paid, key .. " tier " .. tier .. " paid: first screen")
		lu.assertEquals(player.ghost:getPilotTier(), tierAfter, key .. " tier " .. tier .. " paid: pilot tier after the visit")
	end
end

-- AC-5: Imler and Arkon need no code change; their unpaid and paid cells above are regression guards
function TestMission4Sweep:test_the_sweep_covers_every_trainer_tier_cell_of_the_spec()
	local seen = {}

	for _, cell in ipairs(CELLS) do
		seen[cell[1]] = (seen[cell[1]] or 0) + 1
	end

	lu.assertEquals(seen, { kaydine = 3, rikkh = 3, turoldine = 2, viopa = 3, imler = 2, arkon = 2 }, "cells per trainer (spec I-1)")
end

-- AC-5, spec Conversation flow: the pay routes of the four changed trainers end on the head's pay screens at every tier of the sweep
for _, cell in ipairs(CELLS) do
	local key, tier = cell[1], cell[2]

	if HEAD[key] then
		-- AC-5, I-2
		TestMission4Sweep["test_" .. key .. "_tier_" .. tier .. "_pays_the_head_once_along_the_pay_route"] = function()
			local transcript, player = walkToPay(key, function() return pilot(key, { tier = tier }) end)
			local shown = {}

			for _, step in ipairs(transcript) do
				shown[step.id] = true
			end

			local reached = false

			for _, id in ipairs(PAY_SCREENS[key]) do
				reached = reached or shown[id]
			end

			lu.assertTrue(reached, key .. " tier " .. tier .. ": a pay screen (" .. table.concat(PAY_SCREENS[key], "/") .. ") was shown; saw " .. table.concat(ids(transcript), ", "))
			assertPaidOnce(key, player, key .. " tier " .. tier)
		end
	end
end
