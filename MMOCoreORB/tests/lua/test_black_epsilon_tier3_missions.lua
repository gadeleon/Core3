-- Haymir Rendundi: the four mission offers and the failure retries (table H starts).
-- Spec: .claude/work/black-epsilon-tier3-haymir/01-spec.md (AC-7, AC-5; Conversation flow 3 (table H) and 4; Appendix A; D-6).
--
-- A start screen sets `corellia_imperial_tier3_<n>:attempted` and calls SpaceHelpers:startSpaceQuestChain on the mission's head. The head's
-- startQuest is spied (H.spyOn does not call the original) except in the "real start" tests, which run it in a ship.

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier3_data")
local CS = require("harness.client_strings")

T.load()

local function setUp()
	H.reset()
	T.requireConversation(lu)
end

local function concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

local function attempted(player, n) return H.getQuestStatus(player, T.MISSIONS[n].status .. ":attempted") end

-- the pilot ready for mission n (the earlier missions done, their skills chosen)
local function readyFor(n, extra)
	local t3, paid = {}, {}

	for i = 1, n - 1 do
		t3[i] = i
		paid[i] = i
	end

	local o = { t3 = t3, paid = paid }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return T.pilot(o)
end

-- Talks through `choices` and checks: screens shown, which heads started, the :attempted keys
local function walk(w)
	local spies = T.spyStarts()
	local player = readyFor(w.n, w.pilot)
	local before = {}

	for n = 1, 4 do
		before[n] = attempted(player, n)
	end

	local t = T.talk(player, w.choices)

	lu.assertEquals(T.ids(t), w.ids, w.name .. ": screens shown")
	lu.assertEquals(T.started(spies), w.starts or {}, w.name .. ": quests started")

	for n = 1, 4 do
		local want = before[n]

		if w.starts and #w.starts > 0 and n == w.n then
			want = "1"
		end

		lu.assertEquals(attempted(player, n), want, w.name .. ": corellia_imperial_tier3_" .. n .. ":attempted")
	end

	lu.assertEquals(CS.transcriptUnresolved(t), {}, w.name .. ": client strings (AC-5)")

	return t, player
end

---------------------------------------------------------------------------------------------
-- Offers
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Offers = {}

TestBlackEpsilonT3Offers.setUp = setUp

local M1_COMMON = { "s_7af5dab4", "s_1969477d", "s_f2993921", "s_12c769cf", "s_b6b25f13" }

local OFFERS = {
	{ name = "m1 direct", n = 1, ids = { "m1_offer", "m1_who_sent", "m1_salvage", "m1_storm_squadron", "m1_questions", "m1_nym", "m1_split", "m1_accept" },
		choices = concat({ "s_fd236a42", "s_d547e29b" }, M1_COMMON) },
	{ name = "m1 via the fine soldier line", n = 1,
		ids = { "m1_offer", "m1_who_sent", "m1_fine_soldier", "m1_salvage", "m1_storm_squadron", "m1_questions", "m1_nym", "m1_split", "m1_accept" },
		choices = concat({ "s_fd236a42", "s_19be2c59", "s_b93b0c31" }, M1_COMMON) },
	{ name = "m2", n = 2, ids = { "m2_offer", "m2_other_pirates", "m2_simple", "m2_smuggler", "m2_broadcasts", "m2_accept" },
		choices = { "s_5eb7a1e3", "s_2ef3848a", "s_7c05dd60", "s_44750833", "s_24f21f71" } },
	{ name = "m3", n = 3, ids = { "m3_offer", "m3_cracks", "m3_emissary", "m3_freighter", "m3_accept" }, choices = { "s_ecd826ee", "s_d0f9703", "s_af020de3", "s_d1e44f54" } },
	{ name = "m4", n = 4, ids = { "m4_offer", "m4_lok", "m4_punish", "m4_accept" }, choices = { "s_fc27931b", "s_c9015929", "s_cd445db2" } },
}

for _, o in ipairs(OFFERS) do
	-- AC-7: the accept screen sets :attempted and starts the head; it ends the conversation
	TestBlackEpsilonT3Offers["test_the_" .. o.name:gsub("[^%w]+", "_") .. "_walk_ends_on_its_accept_screen_which_starts_the_mission"] = function()
		local head = T.MISSIONS[o.n].head
		local t = walk({ name = o.name, n = o.n, ids = o.ids, choices = o.choices, starts = { head } })

		lu.assertTrue(t[#t].stop, o.name .. ": the accept screen ends the conversation")
	end

	-- AC-7: no earlier screen of the walk grants anything
	TestBlackEpsilonT3Offers["test_no_screen_before_the_accept_of_the_" .. o.name:gsub("[^%w]+", "_") .. "_walk_starts_anything"] = function()
		local ids, choices = {}, {}

		for i = 1, #o.ids - 1 do
			ids[i] = o.ids[i]
		end

		for i = 1, #o.choices - 1 do
			choices[i] = o.choices[i]
		end

		walk({ name = o.name .. " (without the last reply)", n = o.n, ids = ids, choices = choices, starts = {} })
	end
end

-- AC-7: the offer alone starts nothing
function TestBlackEpsilonT3Offers:test_each_offer_shown_alone_starts_nothing()
	for n = 1, 4 do
		H.reset()
		walk({ name = "offer " .. n, n = n, ids = { T.MISSIONS[n].offer }, choices = {}, starts = {} })
	end
end

-- AC-7: the accept screen displayed directly (the engine's runScreenHandlers) starts the mission once
function TestBlackEpsilonT3Offers:test_displaying_an_accept_screen_starts_its_mission_exactly_once()
	for n, m in ipairs(T.MISSIONS) do
		H.reset()

		local spies = T.spyStarts()
		local player = readyFor(n)

		T.drive(player, m.accept)
		lu.assertEquals(T.started(spies), { m.head }, m.accept .. ": quests started")
		lu.assertEquals(attempted(player, n), "1", m.accept .. ": the :attempted key")
	end
end

-- AC-7: only the mission's own key is set
function TestBlackEpsilonT3Offers:test_an_accept_screen_sets_only_its_own_attempted_key()
	for n, m in ipairs(T.MISSIONS) do
		H.reset()
		T.spyStarts()

		local player = readyFor(n)
		local before = {}

		for other = 1, 4 do
			before[other] = attempted(player, other)
		end

		T.drive(player, m.accept)

		for other = 1, 4 do
			if other ~= n then
				lu.assertEquals(attempted(player, other), before[other], m.accept .. ": mission " .. other .. " :attempted is unchanged")
			end
		end
	end
end

-- AC-7: the next mission is not offered while the previous one's skill is unchosen
function TestBlackEpsilonT3Offers:test_mission_n_plus_1_is_not_offered_while_the_skill_of_mission_n_is_unchosen()
	for n = 1, 3 do
		H.reset()

		local t3, paid = {}, {}

		for i = 1, n - 1 do
			t3[i] = i
			paid[i] = i
		end

		local first = T.firstScreen(T.pilot({ t3 = t3, paid = paid, mission = { [n] = "won" } }))

		lu.assertEquals(first, T.MISSIONS[n].reward, "mission " .. n .. " won, its skill unchosen: the reward comes before the next offer")
	end
end

-- AC-7: the real start in a ship makes the head active (a rescue head, R-1, included)
function TestBlackEpsilonT3Offers:test_the_real_start_makes_each_mission_head_active()
	for n, m in ipairs(T.MISSIONS) do
		H.reset()

		local id = T.IDENTITY[m.head]
		local player = readyFor(n, { inShip = true, zone = id.zone })

		T.quest(m.head):start()

		local ok, err = pcall(T.drive, player, m.accept)

		lu.assertTrue(ok, m.accept .. ": talking raised a Lua error: " .. tostring(err))
		H.advance(0)
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, id.type, id.name), id.type .. "/" .. id.name .. " is active after " .. m.accept)
	end
end

---------------------------------------------------------------------------------------------
-- Failures and retries
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Retries = {}

TestBlackEpsilonT3Retries.setUp = setUp

-- reply sid -> retry paths, per mission (Appendix A)
local FAILS = {
	{ n = 1, failed = "m1_failed", paths = {
		{ name = "excuse", choices = { "s_a5d90aff" }, ids = { "m1_failed", "m1_retry_excuse" } },
		{ name = "second shot", choices = { "s_9c5ae9a", "s_883481e3" }, ids = { "m1_failed", "m1_second_shot", "m1_retry" } },
	} },
	{ n = 2, failed = "m2_failed", paths = {
		{ name = "sarcastic", choices = { "s_b713f64f" }, ids = { "m2_failed", "m2_retry_sarcastic" } },
		{ name = "plain", choices = { "s_e6e69be4" }, ids = { "m2_failed", "m2_retry" } },
	} },
	{ n = 3, failed = "m3_failed", paths = {
		{ name = "plain", choices = { "s_dbb3a834" }, ids = { "m3_failed", "m3_retry" } },
		{ name = "rebels", choices = { "s_d8a7505" }, ids = { "m3_failed", "m3_retry_rebels" } },
	} },
	{ n = 4, failed = "m4_failed", paths = {
		{ name = "plain", choices = { "s_d8db54f6" }, ids = { "m4_failed", "m4_retry" } },
		{ name = "promise", choices = { "s_31dd2d63" }, ids = { "m4_failed", "m4_retry_promise" } },
	} },
}

for _, f in ipairs(FAILS) do
	-- AC-7: the failure line alone starts nothing
	TestBlackEpsilonT3Retries["test_" .. f.failed .. "_shown_alone_starts_nothing"] = function()
		walk({ name = f.failed .. " alone", n = f.n, pilot = { mission = { [f.n] = "failed" } }, ids = { f.failed }, choices = {}, starts = {} })
	end

	for _, p in ipairs(f.paths) do
		-- AC-7: both replies reach a re-grant line that restarts the head; the line ends the conversation
		TestBlackEpsilonT3Retries["test_" .. f.failed .. "_" .. p.name:gsub("%s", "_") .. "_restarts_mission_" .. f.n] = function()
			local t = walk({ name = f.failed .. " " .. p.name, n = f.n, pilot = { mission = { [f.n] = "failed" } }, ids = p.ids, choices = p.choices, starts = { T.MISSIONS[f.n].head } })

			lu.assertTrue(t[#t].stop, f.failed .. " " .. p.name .. ": the re-grant line ends the conversation")
		end
	end
end

-- AC-7: the intermediate line of the second-shot path grants nothing
function TestBlackEpsilonT3Retries:test_the_second_shot_line_alone_does_not_restart_mission_1()
	walk({ name = "m1_second_shot", n = 1, pilot = { mission = { [1] = "failed" } }, ids = { "m1_failed", "m1_second_shot" }, choices = { "s_9c5ae9a" }, starts = {} })
end

-- AC-7: a retry clears the stale members of the chain first
function TestBlackEpsilonT3Retries:test_a_retry_clears_a_stale_chain_member_before_the_start()
	for n, m in ipairs(T.MISSIONS) do
		H.reset()
		T.spyStarts()

		local player = readyFor(n, { mission = { [n] = "partial" } })

		lu.assertEquals(T.state(player, m.head), "complete", "precondition: the head is a stale complete entry")
		T.drive(player, m.retries[#m.retries])
		lu.assertEquals(T.state(player, m.head), "none", "mission " .. n .. ": the stale head entry is cleared by the restart")
	end
end

-- AC-7: the real restart of a failed mission makes the head active again
function TestBlackEpsilonT3Retries:test_the_real_retry_makes_each_mission_head_active()
	for n, m in ipairs(T.MISSIONS) do
		H.reset()

		local id = T.IDENTITY[m.head]
		local player = readyFor(n, { mission = { [n] = "partial" }, inShip = true, zone = id.zone })

		T.quest(m.head):start()

		local ok, err = pcall(T.drive, player, m.retries[#m.retries])

		lu.assertTrue(ok, m.retries[#m.retries] .. ": talking raised a Lua error: " .. tostring(err))
		H.advance(0)
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, id.type, id.name), id.type .. "/" .. id.name .. " is active after the retry")
	end
end

-- AC-7: a running chain is not restarted (startSpaceQuestChain refuses)
function TestBlackEpsilonT3Retries:test_a_retry_does_not_restart_a_chain_that_is_running()
	local spies = T.spyStarts()
	local player = readyFor(1, { mission = { [1] = "active" } })

	T.drive(player, "m1_retry")
	lu.assertEquals(T.started(spies), {}, "no start while a chain member is active")
end
