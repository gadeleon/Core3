-- Trainer mission rewards at runtime: Rikkh, Turoldine, Aqzow and Viopa pay SWG's credits and component once (space-trainer-rewards).
-- Spec: .claude/work/space-trainer-rewards/01-spec.md (AC-5, AC-6, AC-8, I-5, D-3, D-10, D-12).
--
-- A pilot who won mission N and has no `:reward` key talks to the trainer, follows the options to the pay screen and is paid. The pilot gets an
-- inventory (H.newPlayer{inventory = true}), so SpaceHelpers:spaceItemReward really calls giveItem. Players come from trainer_fixes_data.lua.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("space_trainer_rewards_data")

T.load()

local TRAINERS = { "rikkh", "turoldine", "aqzow", "viopa" }

local ROWS = {}

for _, r in ipairs(D.R_ROWS) do
	ROWS[r.trainer] = ROWS[r.trainer] or {}
	ROWS[r.trainer][r.mission] = r
end

local function rowsOf(key)
	local out = {}

	for n = 1, 4 do
		out[#out + 1] = ROWS[key][n]
	end

	return out
end

-- a pilot who won mission n (the whole chain complete) and has no :reward key for it
local function winner(key, n, opts)
	opts = opts or {}

	local tr = T.TRAINERS[key]
	local status = {}

	if opts.rewarded then
		status[T.statusName(tr, n) .. ":reward"] = "1"
	end

	local player = T.player(tr, n, { complete = T.chain(tr, n), inventory = true, species = opts.species, questStatus = status })

	if opts.standing then
		player.ghost.factionStanding.rebel = opts.standing
	end

	return player
end

local function payScreenSet(key, n)
	local set = {}

	for _, id in ipairs(D.PAY_SCREENS[key][n]) do
		set[id] = true
	end

	return set
end

-- Talks to the trainer: a probe pilot finds the first screen, the static option links lead from it to a pay screen of mission n, then the
-- real pilot walks that path. Returns transcript, player, reachedPayScreen. `afterProbe` runs between the two (install spies there).
local function visit(key, n, build, afterProbe)
	local tr = T.TRAINERS[key]
	local probe = T.converse(tr, build())

	lu.assertNotNil(probe[1], tr.label .. ": the trainer shows a first screen")

	local path = T.optionPath(tr.template, probe[1].id, payScreenSet(key, n))

	if afterProbe then
		afterProbe()
	end

	local player = build()
	local transcript = T.converse(tr, player, path or {})
	local reached = false

	for _, shown in ipairs(transcript) do
		if payScreenSet(key, n)[shown.id] then
			reached = true
		end
	end

	return transcript, player, reached, probe[1].id
end

-- giveItem calls whose container is this pilot's inventory
local function itemsGiven(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function copy(t)
	local out = {}

	for k, v in pairs(t) do
		out[k] = v
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-5: a won mission pays SWG's credits and component once
---------------------------------------------------------------------------------------------

TestTrainerRewardsPayOnce = {}

function TestTrainerRewardsPayOnce:setUp() H.reset() end

for _, key in ipairs(TRAINERS) do
	for _, r in ipairs(rowsOf(key)) do
		local label = key .. "_mission" .. r.mission .. "_" .. r.global

		-- AC-5
		TestTrainerRewardsPayOnce["test_" .. label .. "_pays_the_swg_credits_once"] = function()
			local transcript, player, reached = visit(key, r.mission, function() return winner(key, r.mission) end)

			lu.assertTrue(reached, r.id .. " " .. r.global .. ": the pilot reaches a pay screen (" .. table.concat(D.PAY_SCREENS[key][r.mission], "/") .. "); saw " ..
				#transcript .. " screens, last '" .. tostring(transcript[#transcript] and transcript[#transcript].id) .. "'")
			lu.assertEquals(player.bankCredits, r.credits, r.id .. " " .. r.global .. ": bank credits")
			lu.assertEquals(#player.bankCreditLog, 1, r.id .. " " .. r.global .. ": addBankCredits calls")
		end

		-- AC-5
		TestTrainerRewardsPayOnce["test_" .. label .. "_gives_the_swg_component_to_the_inventory_once"] = function()
			local _, player = visit(key, r.mission, function() return winner(key, r.mission) end)

			lu.assertEquals(itemsGiven(player), { r.item }, r.id .. " " .. r.global .. ": giveItem(inventory, item) calls")
		end

		-- AC-5, I-5
		TestTrainerRewardsPayOnce["test_" .. label .. "_has_reward_status_1_when_rewardPlayer_runs"] = function()
			local calls
			local statusKey = T.statusName(T.TRAINERS[key], r.mission) .. ":reward"
			local _, player = visit(key, r.mission, function() return winner(key, r.mission) end, function()
				calls = H.spyOn(_G[r.global], "rewardPlayer", function(_, pPlayer) return H.getQuestStatus(pPlayer, statusKey) end)
			end)

			lu.assertEquals(#calls, 1, r.id .. " " .. r.global .. ": rewardPlayer calls")
			lu.assertEquals(calls[1].snapshot, "1", r.id .. " " .. r.global .. ": " .. statusKey .. " when rewardPlayer ran")
			lu.assertEquals(H.getQuestStatus(player, statusKey), "1", r.id .. " " .. r.global .. ": " .. statusKey .. " after the visit")
		end

		-- AC-5, I-5: a second visit pays nothing more
		TestTrainerRewardsPayOnce["test_" .. label .. "_pays_nothing_on_a_second_visit"] = function()
			local _, player = visit(key, r.mission, function() return winner(key, r.mission) end)
			local tr = T.TRAINERS[key]

			T.converse(tr, player)
			T.converse(tr, player)

			lu.assertEquals(player.bankCredits, r.credits, r.id .. " " .. r.global .. ": bank credits after three visits")
			lu.assertEquals(#itemsGiven(player), 1, r.id .. " " .. r.global .. ": components after three visits")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-5: species do not change a {-1} payout (Ithorian, Wookiee and human all get the component)
---------------------------------------------------------------------------------------------

TestTrainerRewardsPaySpecies = {}

function TestTrainerRewardsPaySpecies:setUp() H.reset() end

for _, key in ipairs(TRAINERS) do
	local r = rowsOf(key)[1]

	for name, species in pairs({ ithorian = SPECIES_ITHORIAN, wookiee = SPECIES_WOOKIEE }) do
		-- AC-5, AC-7
		TestTrainerRewardsPaySpecies["test_" .. key .. "_mission1_pays_the_same_component_to_" .. name] = function()
			local _, player = visit(key, r.mission, function() return winner(key, r.mission, { species = species }) end)

			lu.assertEquals(itemsGiven(player), { r.item }, r.id .. " " .. r.global .. " (" .. name .. "): giveItem")
			lu.assertEquals(player.bankCredits, r.credits, r.id .. " " .. r.global .. " (" .. name .. "): bank credits")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: no retroactive pay
---------------------------------------------------------------------------------------------

TestTrainerRewardsNoRetroactivePay = {}

function TestTrainerRewardsNoRetroactivePay:setUp() H.reset() end

for _, key in ipairs(TRAINERS) do
	for _, r in ipairs(rowsOf(key)) do
		local label = key .. "_mission" .. r.mission .. "_" .. r.global

		-- AC-6
		TestTrainerRewardsNoRetroactivePay["test_" .. label .. "_pays_nothing_to_a_pilot_whose_reward_is_already_1"] = function()
			local standing
			local statusKey = T.statusName(T.TRAINERS[key], r.mission) .. ":reward"
			local _, player = visit(key, r.mission, function()
				local p = winner(key, r.mission, { rewarded = true, standing = 250 })

				standing = copy(p.ghost.factionStanding)

				return p
			end)

			lu.assertEquals(player.bankCredits, 0, r.id .. " " .. r.global .. ": bank credits")
			lu.assertEquals(#player.bankCreditLog, 0, r.id .. " " .. r.global .. ": addBankCredits calls")
			lu.assertEquals(itemsGiven(player), {}, r.id .. " " .. r.global .. ": giveItem calls")
			lu.assertEquals(player.ghost.factionStanding.rebel, 250, r.id .. " " .. r.global .. ": rebel standing")
			lu.assertEquals(H.getQuestStatus(player, statusKey), "1", r.id .. " " .. r.global .. ": " .. statusKey)
			lu.assertNotNil(standing, "standing snapshot")
		end
	end
end

-- AC-6: Viopa guards each pay screen itself, so a pilot who is already paid is not paid even when a pay screen is shown
for _, r in ipairs(rowsOf("viopa")) do
	for _, screenId in ipairs(D.PAY_SCREENS.viopa[r.mission]) do
		-- AC-6
		TestTrainerRewardsNoRetroactivePay["test_viopa_pay_screen_" .. screenId .. "_pays_nothing_when_reward_is_already_1"] = function()
			local tr = T.TRAINERS.viopa
			local player = winner("viopa", r.mission, { rewarded = true, standing = 250 })
			local tmpl = H.conversationTemplate(tr.template)
			local handler = H.expectGlobal("viopaConvoHandler", "Viopa handler")
			local screen = LuaConversationTemplate(tmpl):getScreen(screenId)

			lu.assertNotNil(screen, screenId .. " is in the Viopa template")
			handler:runScreenHandlers(tmpl, player, H.newNpc({ name = "Viopa" }), 0, screen)

			lu.assertEquals(player.bankCredits, 0, r.global .. ": bank credits on " .. screenId)
			lu.assertEquals(itemsGiven(player), {}, r.global .. ": giveItem calls on " .. screenId)
			lu.assertEquals(player.ghost.factionStanding.rebel, 250, r.global .. ": rebel standing on " .. screenId)
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-8 (D-10): Aqzow adds 100 rebel faction per mission reward, after the pay
---------------------------------------------------------------------------------------------

TestTrainerRewardsAqzowFaction = {}

function TestTrainerRewardsAqzowFaction:setUp() H.reset() end

for _, r in ipairs(rowsOf("aqzow")) do
	-- AC-8
	TestTrainerRewardsAqzowFaction["test_aqzow_mission" .. r.mission .. "_reward_raises_rebel_standing_by_100_after_rewardPlayer"] = function()
		local calls
		local _, player = visit("aqzow", r.mission, function() return winner("aqzow", r.mission, { standing = 250 }) end, function()
			calls = H.spyOn(_G[r.global], "rewardPlayer", function(_, pPlayer) return pPlayer.ghost.factionStanding.rebel end)
		end)

		lu.assertEquals(#calls, 1, r.global .. ": rewardPlayer calls")
		lu.assertEquals(calls[1].snapshot, 250, r.global .. ": rebel standing when rewardPlayer ran (faction comes after the pay)")
		lu.assertEquals(player.ghost.factionStanding.rebel, 350, r.global .. ": rebel standing after the reward")
	end

	-- AC-8
	TestTrainerRewardsAqzowFaction["test_aqzow_mission" .. r.mission .. "_second_visit_adds_no_more_faction"] = function()
		local _, player = visit("aqzow", r.mission, function() return winner("aqzow", r.mission, { standing = 250 }) end)

		T.converse(T.TRAINERS.aqzow, player)
		T.converse(T.TRAINERS.aqzow, player)

		lu.assertEquals(player.ghost.factionStanding.rebel, 350, r.global .. ": rebel standing after three visits")
	end

	-- AC-8: the faction line sits inside the :reward guard, so a pilot whose :reward is already "1" gets none
	TestTrainerRewardsAqzowFaction["test_aqzow_mission" .. r.mission .. "_reward_with_the_status_already_set_adds_no_faction"] = function()
		local _, player = visit("aqzow", r.mission, function() return winner("aqzow", r.mission, { rewarded = true, standing = 250 }) end)

		lu.assertEquals(player.ghost.factionStanding.rebel, 250, r.global .. ": rebel standing")
	end
end

-- the neutral trainers grant no faction (SWG), and Viopa keeps its +75 (java 402/425/440/456)
for _, key in ipairs({ "rikkh", "turoldine" }) do
	for _, r in ipairs(rowsOf(key)) do
		-- AC-8 (unchanged behavior)
		TestTrainerRewardsAqzowFaction["test_" .. key .. "_mission" .. r.mission .. "_reward_changes_no_faction_standing"] = function()
			local before
			local _, player = visit(key, r.mission, function()
				local p = winner(key, r.mission, { standing = 250 })

				before = copy(p.ghost.factionStanding)

				return p
			end)

			lu.assertEquals(player.ghost.factionStanding, before, r.global .. ": faction standings")
		end
	end
end

for _, r in ipairs(rowsOf("viopa")) do
	-- AC-8 (unchanged behavior)
	TestTrainerRewardsAqzowFaction["test_viopa_mission" .. r.mission .. "_reward_still_adds_75_rebel_standing"] = function()
		local _, player = visit("viopa", r.mission, function() return winner("viopa", r.mission, { standing = 250 }) end)

		lu.assertEquals(player.ghost.factionStanding.rebel, 325, r.global .. ": rebel standing after the reward")
	end
end
