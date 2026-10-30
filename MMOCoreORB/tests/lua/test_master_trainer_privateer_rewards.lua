-- Privateers at the admirals: the Mission 1 reward (AC-7) and the Mission 2 reward with the free neutral master skill (AC-9).
-- Spec: .claude/work/space-master-trainer-privateer/01-spec.md (AC-7, AC-9; Content contract 1 and 2; Conversation flow 2 to 4; invariants I-4, I-5, I-6; D-5, D-6, D-7).
--
-- priv_m1_reward pays 25000 credits, the privateer jacket (4-argument giveItem) and +200 standing in the admiral's faction.
-- priv_master_grant pays 50000, the privateer helmet and +400, then grants pilot_neutral_master through SpaceHelpers:grantSpaceSkill(p, skill, false).
-- Both are shown instead of the faction screens by the handler's swaps; an Imperial or Rebel pilot on the same routes still gets the faction items.
-- SpaceHelpers.grantSpaceSkill is wrapped (the original runs) to see the deduct flag.

local lu = require("luaunit")
local H = require("harness")
local P = require("master_trainer_privateer_data")
local I = require("master_trainer_imperial_data")
local R = require("master_trainer_rebel_data")
local CS = require("harness.client_strings")

P.load()

local MASTER_COST = 7500000

local function setUp()
	H.reset()
	P.requireConversations(lu)
end

local function xp(player) return player.ghost.experience.space_combat_general end

local function hasMaster(player) return P.hasSkill(player, P.MASTER_SKILL) end

local FACTION_ITEM = {
	declann = { jacket = "object/tangible/wearables/jacket/jacket_ace_imperial.iff", helmet = "object/tangible/wearables/helmet/helmet_fighter_imperial_ace.iff" },
	burke = { jacket = "object/tangible/wearables/jacket/jacket_ace_rebel.iff", helmet = "object/tangible/wearables/helmet/helmet_fighter_rebel_ace.iff" },
}

local SQUADRONS = { declann = { "corsec", "rsf" }, burke = { "corsec", "smuggler" } }

-- the gate screen after the reward and the reply sids of the routes the spec names
local M1_ROUTES = {
	declann = { { "s_b8ead210", "s_3ffe1ded", "s_a8ea09e9" }, { "s_3876be4f", "s_a8ea09e9" } },
	burke = { { "s_d02bfc3b", "s_f00f629f", "s_7cbd5de5" } },
}

-- a privateer with mission 1 won and unpaid
local function winner1(adm, squadron, extra)
	local o = { mission = { [1] = "won" }, squadron = squadron, keys = { [adm == "declann" and "imperial" or "rebel"] = true } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return P.pilot(adm, o)
end

-- a privateer with mission 2 won and unpaid, mission 1 paid, XP for the skill's listed cost (so a charge would show)
local function winner2(adm, squadron, extra)
	local o = { paid = { 1 }, mission = { [2] = "won" }, xp = MASTER_COST + 500000, squadron = squadron, keys = { [adm == "declann" and "imperial" or "rebel"] = true } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return P.pilot(adm, o)
end

TestMasterTrainerPrivateerMission1Reward = {}

TestMasterTrainerPrivateerMission1Reward.setUp = setUp

function TestMasterTrainerPrivateerMission1Reward:tearDown() P.restore() end

-- AC-7: Declann's m1_won routes show priv_m1_reward (never m1_reward), pay once, then continue
function TestMasterTrainerPrivateerMission1Reward:test_declanns_m1_won_routes_show_priv_m1_reward_and_pay_the_privateer_jacket_once()
	for _, squadron in ipairs(SQUADRONS.declann) do
		for i, replies in ipairs(M1_ROUTES.declann) do
			H.reset()

			local player = winner1("declann", squadron)
			local t = P.talk("declann", player, replies)
			local label = squadron .. " route " .. i

			lu.assertEquals(P.ids(t)[1], "m1_won", label .. ": first screen")
			lu.assertEquals(P.count(P.ids(t), "priv_m1_reward"), 1, label .. ": priv_m1_reward is shown")
			lu.assertEquals(P.count(P.ids(t), "m1_reward"), 0, label .. ": m1_reward is not shown")
			lu.assertEquals(P.ids(t)[#t], "priv_m1_reward", label .. ": the walk ends on the reward screen after the last reply")
			lu.assertEquals(player.bankCredits, 25000, label .. ": credits")
			lu.assertEquals(#player.bankCreditLog, 1, label .. ": addBankCredits calls")
			lu.assertEquals(P.itemsGiven(player), { P.jacket }, label .. ": the privateer jacket and nothing else")
			lu.assertEquals(P.standing("declann", player), 200, label .. ": Imperial standing")
			lu.assertEquals(H.getQuestStatus(player, "master_imperial_1:reward"), "1", label .. ": master_imperial_1:reward")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")
		end
	end
end

-- AC-7: the walk continues through m1_kind to m1_dismissed
function TestMasterTrainerPrivateerMission1Reward:test_declanns_walk_continues_from_priv_m1_reward_to_m1_kind_and_m1_dismissed()
	local replies = { "s_3876be4f", "s_a8ea09e9", "s_1affba73", "s_cc0857f4" }
	local player = winner1("declann", "corsec")
	local t = P.talk("declann", player, replies)

	lu.assertEquals(P.ids(t), { "m1_won", "m1_improvise", "priv_m1_reward", "m1_kind", "m1_dismissed" }, "screens shown")
	lu.assertTrue(t[#t].stop, "m1_dismissed ends the conversation")
	lu.assertEquals(player.bankCredits, 25000, "paid once over the whole walk")
	lu.assertEquals(#P.itemsGiven(player), 1, "one item")
end

-- AC-7: every m1_won route (computed from the rows with the swap) pays the privateer reward once
function TestMasterTrainerPrivateerMission1Reward:test_every_m1_won_route_at_both_admirals_pays_the_privateer_reward_exactly_once()
	for _, adm in ipairs(P.ORDER) do
		for _, squadron in ipairs(SQUADRONS[adm]) do
			for _, r in ipairs(P.paths(adm, "m1_won", P.swaps(adm, squadron))) do
				H.reset()

				local player = winner1(adm, squadron)
				local t = P.talk(adm, player, r.replies)
				local label = adm .. " " .. squadron .. " route " .. table.concat(r.ids, " > ")

				lu.assertEquals(P.ids(t), r.ids, label .. ": screens shown")
				lu.assertEquals(P.count(r.ids, "priv_m1_reward"), 1, label .. ": passes priv_m1_reward once")
				lu.assertEquals(player.bankCredits, 25000, label .. ": credits")
				lu.assertEquals(P.itemsGiven(player), { P.jacket }, label .. ": items")
				lu.assertEquals(P.standing(adm, player), 200, label .. ": standing")
			end
		end
	end
end

-- AC-7: the next talk opens the mission 2 briefing and pays nothing
function TestMasterTrainerPrivateerMission1Reward:test_after_the_reward_the_next_talk_opens_the_mission_2_briefing_and_pays_nothing()
	local want = { declann = "priv_m2_brief", burke = "m2_brief" }

	for _, adm in ipairs(P.ORDER) do
		for _, squadron in ipairs(SQUADRONS[adm]) do
			H.reset()

			local player = winner1(adm, squadron)

			P.talk(adm, player, M1_ROUTES[adm][1])
			lu.assertEquals(player.bankCredits, 25000, adm .. " " .. squadron .. ": paid on display of the reward screen")

			local again = P.talk(adm, player)

			lu.assertEquals(again[1].id, want[adm], adm .. " " .. squadron .. ": the next talk")
			lu.assertEquals(player.bankCredits, 25000, adm .. " " .. squadron .. ": credits after the second talk")
			lu.assertEquals(#P.itemsGiven(player), 1, adm .. " " .. squadron .. ": items after the second talk")
			lu.assertEquals(P.standing(adm, player), 200, adm .. " " .. squadron .. ": standing after the second talk")
		end
	end
end

-- AC-7: Burke's reward screen ends the conversation
function TestMasterTrainerPrivateerMission1Reward:test_burkes_priv_m1_reward_ends_the_conversation_and_pays_the_rebel_standing()
	for _, squadron in ipairs(SQUADRONS.burke) do
		H.reset()

		local player = winner1("burke", squadron)
		local t = P.talk("burke", player, M1_ROUTES.burke[1])

		lu.assertEquals(P.ids(t), { "m1_won", "m1_corvette", "m1_outer_rim", "priv_m1_reward" }, squadron .. ": the route")
		lu.assertTrue(t[#t].stop, squadron .. ": priv_m1_reward ends the conversation")
		lu.assertEquals(player.bankCredits, 25000, squadron .. ": credits")
		lu.assertEquals(P.itemsGiven(player), { P.jacket }, squadron .. ": the privateer jacket")
		lu.assertEquals(P.standing("burke", player), 200, squadron .. ": Rebel standing")
		lu.assertEquals(I.standing(player), 0, squadron .. ": no Imperial standing")
	end
end

-- AC-7, I-4: no faction jacket for a privateer, and the faction pilot still gets his
function TestMasterTrainerPrivateerMission1Reward:test_an_imperial_or_rebel_pilot_on_the_same_routes_still_gets_m1_reward_and_the_faction_jacket()
	local cases = {
		{ adm = "declann", M = I, kind = "imperial", jacket = FACTION_ITEM.declann.jacket },
		{ adm = "burke", M = R, kind = "rebel", jacket = FACTION_ITEM.burke.jacket },
	}

	for _, c in ipairs(cases) do
		for i, replies in ipairs(M1_ROUTES[c.adm]) do
			H.reset()

			local player = c.M.pilot({ mission = { [1] = "won" } })
			local t = c.M.talk(player, replies)
			local label = c.kind .. " route " .. i

			lu.assertEquals(P.count(P.ids(t), "m1_reward"), 1, label .. ": m1_reward is shown")
			lu.assertEquals(P.count(P.ids(t), "priv_m1_reward"), 0, label .. ": priv_m1_reward is not shown")
			lu.assertEquals(P.itemsGiven(player), { c.jacket }, label .. ": the faction jacket")
			lu.assertEquals(player.bankCredits, 25000, label .. ": credits")
			lu.assertEquals(c.M.standing(player), 200, label .. ": standing")
		end
	end
end

-- AC-7, I-4: a privateer is never given the faction jacket, whatever the species
function TestMasterTrainerPrivateerMission1Reward:test_a_privateer_never_gets_the_faction_jacket_whatever_the_species()
	for _, adm in ipairs(P.ORDER) do
		for _, sp in ipairs({ SPECIES_HUMAN, SPECIES_ZABRAK, SPECIES_WOOKIEE, SPECIES_ITHORIAN }) do
			H.reset()

			local player = winner1(adm, "corsec", { species = sp })

			P.drive(adm, player, "priv_m1_reward")
			lu.assertEquals(player.bankCredits, 25000, adm .. " species " .. sp .. ": credits")
			lu.assertEquals(#player.bankCreditLog, 1, adm .. " species " .. sp .. ": addBankCredits calls")
			lu.assertEquals(P.itemsGiven(player), { P.jacket }, adm .. " species " .. sp .. ": the privateer jacket")
		end
	end
end

-- AC-7, I-5: a full inventory still receives the jacket through the 4-argument overload
function TestMasterTrainerPrivateerMission1Reward:test_a_full_inventory_still_receives_the_privateer_jacket_through_the_overload()
	for _, adm in ipairs(P.ORDER) do
		H.reset()

		local player = winner1(adm, "corsec", { inventory = { limit = 0 } })

		P.drive(adm, player, "priv_m1_reward")
		lu.assertEquals(#player.inventory.items, 1, adm .. ": the jacket lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, adm .. ": nothing is destroyed")

		local calls = H.Engine.callsTo("giveItem")

		lu.assertEquals(#calls, 1, adm .. ": giveItem calls")
		lu.assertEquals(calls[1].n, 4, adm .. ": giveItem argument count (the overload form)")
		lu.assertIs(calls[1][4], true, adm .. ": the overload flag")
		lu.assertEquals(calls[1][2], P.jacket, adm .. ": the template")
	end
end

-- AC-7, I-5: the reward is paid once, whatever the number of visits, and not at all when the key is set
function TestMasterTrainerPrivateerMission1Reward:test_priv_m1_reward_shown_three_times_pays_once_and_a_paid_mission_pays_nothing()
	for _, adm in ipairs(P.ORDER) do
		H.reset()

		local player = winner1(adm, "corsec")

		for _ = 1, 3 do
			P.drive(adm, player, "priv_m1_reward")
		end

		lu.assertEquals(player.bankCredits, 25000, adm .. ": credits after three visits")
		lu.assertEquals(#P.itemsGiven(player), 1, adm .. ": items after three visits")
		lu.assertEquals(P.standing(adm, player), 200, adm .. ": standing after three visits")

		H.reset()

		local paid = winner1(adm, "corsec")

		H.setQuestStatus(paid, P.key(adm, 1, "reward"), 1)
		P.drive(adm, paid, "priv_m1_reward")
		lu.assertEquals(paid.bankCredits or 0, 0, adm .. ": credits with the key set")
		lu.assertEquals(#P.itemsGiven(paid), 0, adm .. ": items with the key set")
		lu.assertEquals(P.standing(adm, paid), 0, adm .. ": standing with the key set")
	end
end

-- AC-7, I-5, Content contract 1: the payment goes through MasterTrainerScreenplay:rewardPrivateer, not through the head's rewardPlayer
function TestMasterTrainerPrivateerMission1Reward:test_the_payment_goes_through_reward_privateer_once_and_not_through_the_heads_reward_player()
	for _, adm in ipairs(P.ORDER) do
		H.reset()

		local a = P.ADMIRALS[adm]
		local head = a.M.quest(a.heads[1])
		local headSpy = H.spyOn(head, "rewardPlayer")
		local calls = H.spyOn(a.M.mts(), "rewardPrivateer")

		P.drive(adm, winner1(adm, "corsec"), "priv_m1_reward")
		lu.assertEquals(#headSpy, 0, adm .. ": " .. a.heads[1] .. ":rewardPlayer calls")
		lu.assertEquals(#calls, 1, adm .. ": MasterTrainerScreenplay:rewardPrivateer calls")
		lu.assertEquals(calls[1].args[2], a.heads[1], adm .. ": the head global")
		lu.assertEquals(calls[1].args[3], 1, adm .. ": the mission number")
	end
end

-- Content contract 1: rewardPrivateer pays the table's credits and the privateer item, and sets no key and pays no standing
function TestMasterTrainerPrivateerMission1Reward:test_reward_privateer_pays_the_credits_of_the_quest_table_and_the_privateer_item_only()
	for _, adm in ipairs(P.ORDER) do
		local a = P.ADMIRALS[adm]

		for n = 1, 2 do
			H.reset()

			local player = P.pilot(adm, {})

			a.M.mts():rewardPrivateer(player, a.heads[n], n)
			lu.assertEquals(player.bankCredits, P.CREDITS[n], adm .. " mission " .. n .. ": credits")
			lu.assertEquals(P.itemsGiven(player), { P.ITEMS[n] }, adm .. " mission " .. n .. ": the privateer item")
			lu.assertEquals(P.standing(adm, player), 0, adm .. " mission " .. n .. ": no standing (the handler pays it)")
			lu.assertNil(H.getQuestStatus(player, P.key(adm, n, "reward")), adm .. " mission " .. n .. ": no :reward key (the handler sets it)")
		end
	end
end

-- Content contract 1: it returns early without a player or without the quest global
function TestMasterTrainerPrivateerMission1Reward:test_reward_privateer_returns_early_without_a_player_or_a_quest_global()
	local mts = I.mts()
	local player = P.pilot("declann", {})

	mts:rewardPrivateer(nil, "destroy_master_imperial_1", 1)
	mts:rewardPrivateer(player, "no_such_quest_global", 1)
	lu.assertEquals(player.bankCredits or 0, 0, "credits")
	lu.assertEquals(#P.itemsGiven(player), 0, "items")
end

-- Content contract 1: a full inventory, 4-argument giveItem, directly through rewardPrivateer
function TestMasterTrainerPrivateerMission1Reward:test_reward_privateer_gives_the_item_to_a_full_inventory()
	local player = P.pilot("declann", { inventory = { limit = 0 } })

	I.mts():rewardPrivateer(player, "destroy_master_imperial_2", 2)

	local calls = H.Engine.callsTo("giveItem")

	lu.assertEquals(#calls, 1, "giveItem calls")
	lu.assertEquals(calls[1].n, 4, "giveItem argument count (the overload form)")
	lu.assertEquals(calls[1][2], P.helmet, "the template")
end

-- AC-7: the other screens pay nothing
function TestMasterTrainerPrivateerMission1Reward:test_no_other_privateer_screen_pays_credits_items_or_standing()
	for _, adm in ipairs(P.ORDER) do
		local a = P.ADMIRALS[adm]

		for _, row in ipairs(a.screens) do
			if a.tables.PRIVATEER_REWARD_SCREENS[row.id] == nil then
				H.reset()
				P.restore()
				P.spyAllStarts()

				local player = P.pilot(adm, { paid = { 1 }, mission = { [2] = "won" } })

				P.drive(adm, player, row.id)
				lu.assertEquals(player.bankCredits or 0, 0, adm .. " " .. row.id .. ": bank credits")
				lu.assertEquals(#P.itemsGiven(player), 0, adm .. " " .. row.id .. ": items")
				lu.assertEquals(P.standing(adm, player), 0, adm .. " " .. row.id .. ": standing")
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- Mission 2 and the master skill (AC-9)
---------------------------------------------------------------------------------------------

TestMasterTrainerPrivateerMaster = {}

TestMasterTrainerPrivateerMaster.setUp = setUp

function TestMasterTrainerPrivateerMaster:tearDown() P.restore() end

-- AC-9: both Declann routes reach priv_master_grant then priv_master_end
function TestMasterTrainerPrivateerMaster:test_both_declann_m2_won_routes_reach_priv_master_grant_then_priv_master_end()
	local routes = {
		{ "s_f010d9ab", "s_2f52e0af", "s_beb9353a", "s_377d1a96" },
		{ "s_f010d9ab", "s_6aa8adaf", "s_6a66a025", "s_377d1a96", "s_377d1a96" },
	}

	local want = {
		{ "m2_won", "m2_report", "m2_not_dismissed", "priv_master_grant", "priv_master_end" },
		{ "m2_won", "m2_report", "m2_hoping", "m2_rewarded", "priv_master_grant", "priv_master_end" },
	}

	for _, squadron in ipairs(SQUADRONS.declann) do
		for i, replies in ipairs(routes) do
			H.reset()

			local player = winner2("declann", squadron)
			local t = P.talk("declann", player, replies)
			local label = squadron .. " route " .. i

			lu.assertEquals(P.ids(t), want[i], label .. ": screens shown")
			lu.assertTrue(t[#t].stop, label .. ": priv_master_end ends the conversation")
			lu.assertEquals(P.count(P.ids(t), "master_grant"), 0, label .. ": master_grant is not shown")
			lu.assertTrue(hasMaster(player), label .. ": pilot_neutral_master granted")
			lu.assertEquals(player.bankCredits, 50000, label .. ": credits")
			lu.assertEquals(P.itemsGiven(player), { P.helmet }, label .. ": the privateer helmet")
			lu.assertEquals(P.standing("declann", player), 400, label .. ": Imperial standing")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")
		end
	end
end

-- AC-9: Burke's route m2_won > m2_report > m2_modesty > priv_m2_disappointed > priv_master_grant > priv_master_end
function TestMasterTrainerPrivateerMaster:test_burkes_m2_won_route_passes_priv_m2_disappointed_then_priv_master_grant_and_priv_master_end()
	for _, squadron in ipairs(SQUADRONS.burke) do
		H.reset()

		local player = winner2("burke", squadron)
		local t = P.talk("burke", player, { "s_1da9fe53", "s_3f6a8711", "s_8d7967cc", "s_5869e64b", "s_377d1a96" })

		lu.assertEquals(P.ids(t), { "m2_won", "m2_report", "m2_modesty", "priv_m2_disappointed", "priv_master_grant", "priv_master_end" }, squadron .. ": screens shown")
		lu.assertTrue(t[#t].stop, squadron .. ": priv_master_end ends the conversation")
		lu.assertTrue(hasMaster(player), squadron .. ": pilot_neutral_master granted")
		lu.assertEquals(player.bankCredits, 50000, squadron .. ": credits")
		lu.assertEquals(P.itemsGiven(player), { P.helmet }, squadron .. ": the privateer helmet")
		lu.assertEquals(P.standing("burke", player), 400, squadron .. ": Rebel standing")
		lu.assertEquals(I.standing(player), 0, squadron .. ": no Imperial standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, squadron .. ": client strings")
	end
end

-- AC-9: every m2_won route at both admirals (rows with the swaps) pays and grants once
function TestMasterTrainerPrivateerMaster:test_every_m2_won_route_pays_mission_2_and_grants_the_neutral_master_skill_exactly_once()
	for _, adm in ipairs(P.ORDER) do
		for _, squadron in ipairs(SQUADRONS[adm]) do
			for _, r in ipairs(P.paths(adm, "m2_won", P.swaps(adm, squadron))) do
				H.reset()

				local calls = I.recordGrants()
				local player = winner2(adm, squadron)
				local t = P.talk(adm, player, r.replies)
				local label = adm .. " " .. squadron .. " route " .. table.concat(r.ids, " > ")

				lu.assertEquals(P.ids(t), r.ids, label .. ": screens shown")
				lu.assertEquals(P.count(r.ids, "priv_master_grant"), 1, label .. ": passes priv_master_grant once")
				lu.assertEquals(P.count(r.ids, "master_grant"), 0, label .. ": never shows master_grant")
				lu.assertEquals(calls, { { skill = P.MASTER_SKILL, deduct = false } }, label .. ": grantSpaceSkill calls (skill, deduct flag)")
				lu.assertEquals(player.bankCredits, 50000, label .. ": credits")
				lu.assertEquals(P.itemsGiven(player), { P.helmet }, label .. ": items")
				lu.assertEquals(P.standing(adm, player), 400, label .. ": standing")
				I.restore()
			end
		end
	end
end

-- AC-9, D-7: the grant is free: grantSpaceSkill(p, "pilot_neutral_master", false), XP unchanged
function TestMasterTrainerPrivateerMaster:test_priv_master_grant_grants_the_neutral_master_skill_free_and_xp_is_unchanged()
	for _, adm in ipairs(P.ORDER) do
		H.reset()

		local calls = I.recordGrants()
		local player = winner2(adm, "corsec")
		local before = xp(player)

		lu.assertFalse(hasMaster(player), adm .. ": precondition: no master skill")
		H.Engine.config.skillXpCosts = { [P.MASTER_SKILL] = MASTER_COST }
		P.drive(adm, player, "priv_master_grant")

		lu.assertEquals(calls, { { skill = P.MASTER_SKILL, deduct = false } }, adm .. ": grantSpaceSkill calls (skill, deduct flag)")
		lu.assertTrue(hasMaster(player), adm .. ": the master skill is held")
		lu.assertEquals(xp(player), before, adm .. ": space_combat_general experience is unchanged (the 7,500,000 XP_COST is never charged)")
		lu.assertEquals(P.learned(player), 1, adm .. ": one 'skill learned' message (the grant case differs from the guard case only by the held skill)")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 1, adm .. ": free grants (awardSkill)")
		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, adm .. ": XP-charging grants")
		I.restore()
	end
end

-- D-7: a pilot who could not pay the listed cost still gets the skill
function TestMasterTrainerPrivateerMaster:test_a_privateer_with_no_xp_still_gets_the_master_skill()
	for _, adm in ipairs(P.ORDER) do
		H.reset()

		local player = winner2(adm, "corsec", { xp = 0 })

		H.Engine.config.skillXpCosts = { [P.MASTER_SKILL] = MASTER_COST }
		P.drive(adm, player, "priv_master_grant")
		lu.assertTrue(hasMaster(player), adm .. ": the master skill is granted without XP")
		lu.assertEquals(xp(player), 0, adm .. ": XP stays 0")
	end
end

-- AC-9, I-6: no privateer path grants the Imperial or Rebel master skill, and no faction helmet is given
function TestMasterTrainerPrivateerMaster:test_a_privateer_gets_neither_the_faction_master_skill_nor_the_faction_helmet()
	for _, adm in ipairs(P.ORDER) do
		H.reset()

		local player = winner2(adm, "corsec")

		P.drive(adm, player, "priv_master_grant")
		lu.assertFalse(P.hasSkill(player, "pilot_imperial_navy_master"), adm .. ": pilot_imperial_navy_master")
		lu.assertFalse(P.hasSkill(player, "pilot_rebel_navy_master"), adm .. ": pilot_rebel_navy_master")

		for _, item in ipairs(P.itemsGiven(player)) do
			lu.assertNotEquals(item, FACTION_ITEM[adm].helmet, adm .. ": the faction helmet")
			lu.assertNotEquals(item, FACTION_ITEM[adm].jacket, adm .. ": the faction jacket")
		end
	end
end

-- AC-9: the faction pilot on the same screens still gets his master skill and his helmet
function TestMasterTrainerPrivateerMaster:test_an_imperial_or_rebel_pilot_on_the_m2_won_routes_still_gets_master_grant_and_the_faction_master_skill()
	local cases = {
		{ adm = "declann", M = I, skill = "pilot_imperial_navy_master", routes = { { "s_f010d9ab", "s_2f52e0af", "s_beb9353a", "s_a1669dff" } } },
		{ adm = "burke", M = R, skill = "pilot_rebel_navy_master", routes = { { "s_1da9fe53", "s_3f6a8711", "s_8d7967cc", "s_5869e64b" } } },
	}

	for _, c in ipairs(cases) do
		for _, replies in ipairs(c.routes) do
			H.reset()

			local player = c.M.pilot({ paid = { 1 }, mission = { [2] = "won" }, xp = MASTER_COST + 500000 })
			local t = c.M.talk(player, replies)

			lu.assertEquals(P.count(P.ids(t), "master_grant"), 1, c.adm .. ": master_grant is shown")
			lu.assertEquals(P.count(P.ids(t), "priv_master_grant"), 0, c.adm .. ": priv_master_grant is not shown")
			lu.assertTrue(P.hasSkill(player, c.skill), c.adm .. ": the faction master skill")
			lu.assertFalse(P.hasSkill(player, P.MASTER_SKILL), c.adm .. ": not the neutral master skill")
			lu.assertEquals(P.itemsGiven(player), { FACTION_ITEM[c.adm].helmet }, c.adm .. ": the faction helmet")
		end
	end
end

-- AC-9: closing on priv_master_grant leaves the payment and the skill done; the next talk is other_master and pays nothing
function TestMasterTrainerPrivateerMaster:test_closing_on_priv_master_grant_leaves_both_done_and_the_next_talk_opens_other_master()
	local routes = {
		declann = { "s_f010d9ab", "s_2f52e0af", "s_beb9353a" },
		burke = { "s_1da9fe53", "s_3f6a8711", "s_8d7967cc", "s_5869e64b" },
	}

	for _, adm in ipairs(P.ORDER) do
		H.reset()

		local calls = I.recordGrants()
		local player = winner2(adm, "corsec")
		local t = P.talk(adm, player, routes[adm])

		lu.assertEquals(P.ids(t)[#t], "priv_master_grant", adm .. ": the talk stops on priv_master_grant")
		lu.assertEquals(player.bankCredits, 50000, adm .. ": paid on display of priv_master_grant")
		lu.assertEquals(P.itemsGiven(player), { P.helmet }, adm .. ": the helmet")
		lu.assertEquals(P.standing(adm, player), 400, adm .. ": standing")
		lu.assertTrue(hasMaster(player), adm .. ": the skill")

		for _ = 1, 2 do
			local again = P.talk(adm, player)

			lu.assertEquals(P.ids(again), { "other_master" }, adm .. ": the next talk opens other_master")
			lu.assertTrue(again[1].stop, adm .. ": other_master ends the conversation")
		end

		lu.assertEquals(player.bankCredits, 50000, adm .. ": credits after the next talks")
		lu.assertEquals(#P.itemsGiven(player), 1, adm .. ": items after the next talks")
		lu.assertEquals(P.standing(adm, player), 400, adm .. ": standing after the next talks")
		lu.assertEquals(#calls, 1, adm .. ": grantSpaceSkill calls")
		I.restore()
	end
end

-- AC-9, D-6: priv_master_end pays and grants nothing
function TestMasterTrainerPrivateerMaster:test_priv_master_end_pays_and_grants_nothing()
	for _, adm in ipairs(P.ORDER) do
		H.reset()

		local calls = I.recordGrants()
		local player = P.pilot(adm, { paid = { 1, 2 }, master = true })

		P.drive(adm, player, "priv_master_end")
		lu.assertEquals(player.bankCredits or 0, 0, adm .. ": credits")
		lu.assertEquals(#P.itemsGiven(player), 0, adm .. ": items")
		lu.assertEquals(P.standing(adm, player), 0, adm .. ": standing")
		lu.assertEquals(calls, {}, adm .. ": grantSpaceSkill calls")
		I.restore()
	end
end

-- AC-9, I-5: priv_master_grant shown three times pays once and grants once
function TestMasterTrainerPrivateerMaster:test_priv_master_grant_shown_three_times_pays_once_and_grants_once()
	for _, adm in ipairs(P.ORDER) do
		H.reset()

		local calls = I.recordGrants()
		local player = winner2(adm, "corsec")

		for _ = 1, 3 do
			P.drive(adm, player, "priv_master_grant")
		end

		lu.assertEquals(player.bankCredits, 50000, adm .. ": credits after three visits")
		lu.assertEquals(#P.itemsGiven(player), 1, adm .. ": items after three visits")
		lu.assertEquals(P.standing(adm, player), 400, adm .. ": standing after three visits")
		lu.assertEquals(#calls, 1, adm .. ": grantSpaceSkill calls after three visits")
		I.restore()
	end
end

-- AC-9: ISOLATED GUARD 1. M2 won and unpaid, the master skill ALREADY HELD, every other condition as in the grant case
-- (test_priv_master_grant_grants_the_neutral_master_skill_free_and_xp_is_unchanged): priv_master_grant pays mission 2 once and grants nothing.
function TestMasterTrainerPrivateerMaster:test_priv_master_grant_with_the_master_skill_already_held_pays_once_and_does_not_grant_again()
	for _, adm in ipairs(P.ORDER) do
		H.reset()

		local calls = I.recordGrants()
		local player = winner2(adm, "corsec", { master = true })
		local handler = H.expectGlobal(P.ADMIRALS[adm].handler, "the handler. Load problems: " .. P.problems())

		lu.assertTrue(hasMaster(player), adm .. ": precondition: the master skill is already held")
		lu.assertFalse(handler:isPaid(player, 2), adm .. ": precondition: mission 2 unpaid")
		lu.assertTrue(handler:isWon(player, 2), adm .. ": precondition: mission 2 won")

		P.drive(adm, player, "priv_master_grant")

		lu.assertEquals(player.bankCredits, 50000, adm .. ": mission 2 is paid")
		lu.assertEquals(P.itemsGiven(player), { P.helmet }, adm .. ": the helmet")
		lu.assertEquals(P.standing(adm, player), 400, adm .. ": standing")
		lu.assertEquals(calls, {}, adm .. ": grantSpaceSkill is not called when the skill is already held")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, adm .. ": free grants")
		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, adm .. ": XP-charging grants")
		lu.assertEquals(P.learned(player), 0, adm .. ": no 'skill learned' message")
		I.restore()
	end
end

-- AC-9: ISOLATED GUARD 2. M2 already PAID, the skill not held, every other condition as in the grant case: nothing more is paid, and the skill is granted
function TestMasterTrainerPrivateerMaster:test_priv_master_grant_with_mission_2_already_paid_pays_nothing_more()
	for _, adm in ipairs(P.ORDER) do
		H.reset()

		local player = winner2(adm, "corsec")

		H.setQuestStatus(player, P.key(adm, 2, "reward"), 1)
		lu.assertFalse(hasMaster(player), adm .. ": precondition: no master skill")

		P.drive(adm, player, "priv_master_grant")
		lu.assertEquals(player.bankCredits or 0, 0, adm .. ": credits")
		lu.assertEquals(#P.itemsGiven(player), 0, adm .. ": items")
		lu.assertEquals(P.standing(adm, player), 0, adm .. ": standing")
	end
end

-- AC-9, I-6: the skill is granted on priv_master_grant and nowhere else
function TestMasterTrainerPrivateerMaster:test_no_other_privateer_screen_grants_a_skill()
	for _, adm in ipairs(P.ORDER) do
		local a = P.ADMIRALS[adm]

		for _, row in ipairs(a.screens) do
			if row.id ~= a.tables.PRIVATEER_MASTER_SCREEN then
				H.reset()
				P.restore()
				P.spyAllStarts()

				local calls = I.recordGrants()
				local player = P.pilot(adm, { paid = { 1 }, mission = { [2] = "won" } })

				P.drive(adm, player, row.id)
				lu.assertEquals(calls, {}, adm .. " " .. row.id .. ": grantSpaceSkill calls")
				lu.assertFalse(hasMaster(player), adm .. " " .. row.id .. ": the master skill")
				I.restore()
			end
		end
	end
end

-- AC-9: the pilot's other skills and pilot tier are unchanged by the master grant
function TestMasterTrainerPrivateerMaster:test_the_master_grant_changes_no_other_skill_and_not_the_pilot_tier()
	for _, adm in ipairs(P.ORDER) do
		H.reset()

		local player = winner2(adm, "corsec")
		local before = {}

		for skill in pairs(player.skills) do
			before[skill] = true
		end

		P.drive(adm, player, "priv_master_grant")

		local after = {}

		for skill in pairs(player.skills) do
			after[skill] = true
		end

		after[P.MASTER_SKILL] = nil
		lu.assertEquals(after, before, adm .. ": skills other than the master skill")
		lu.assertEquals(player.ghost.pilotTier, 5, adm .. ": pilot tier (the C++ cap is 5)")
	end
end
