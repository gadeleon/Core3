-- Turoldine (CorSec tier 4): the screen shown after a skill box is trained runs through the handler.
-- Spec: .claude/work/corsec-tier4-turoldine-redirect-fix/01-spec.md (AC-1 .. AC-6; AC-7 is the run.sh + engine gate).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")

T.load()

local TR = T.TRAINERS.turoldine

local SID = {
	fighters = "s_2794eddd",
	components = "s_e16cb1fa",
	techniques = "s_291ab969",
	algorithms = "s_bc944dc4",
}

local BOX = {
	starships = "pilot_neutral_starships_04",
	weapons = "pilot_neutral_weapons_04",
	procedures = "pilot_neutral_procedures_04",
	droid = "pilot_neutral_droid_04",
}

local TIER123 = {}

for tier = 1, 3 do
	for _, s in ipairs({ "droid", "procedures", "starships", "weapons" }) do
		TIER123[#TIER123 + 1] = string.format("pilot_neutral_%s_0%d", s, tier)
	end
end

local function skillsWith(...)
	local list = {}

	for _, s in ipairs(TIER123) do
		list[#list + 1] = s
	end

	for _, s in ipairs({ ... }) do
		list[#list + 1] = s
	end

	return list
end

local function pilot(n, opts)
	opts = opts or {}
	opts.baseSkills = opts.baseSkills or skillsWith()
	opts.experience = opts.experience or { space_combat_general = 3000000 }

	if opts.attempted == nil then
		opts.attempted = false
	end

	return T.player(TR, n, opts)
end

local function talk(player, choices)
	return T.converse(TR, player, choices)
end

local function linksOf(entry)
	local links = {}

	for i, o in ipairs(entry.options or {}) do
		links[i] = o.link
	end

	return links
end

local function countOf(list, value)
	local n = 0

	for _, v in ipairs(list) do
		if v == value then
			n = n + 1
		end
	end

	return n
end

TestTuroldineTrainRedirect = {}

function TestTuroldineTrainRedirect:setUp()
	H.reset()
end

-- AC-1
function TestTuroldineTrainRedirect:test_redirect_after_first_box_is_a_filled_ready_train_pilot_with_three_options()
	local player = pilot(1)
	local t = talk(player, { SID.fighters })

	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1, "one box granted")
	lu.assertEquals(H.Engine.callsTo("skillManagerAwardSkill")[1][2], BOX.starships, "box granted")
	lu.assertEquals(t[2].id, "ready_train_pilot", "screen after the training")
	lu.assertEquals(t[2].params and t[2].params.TU, "Ace", "ready_train_pilot: params.TU")
	lu.assertEquals(linksOf(t[2]), { "initial_train_components", "initial_train_techniques", "initial_train_algorithms" },
		"ready_train_pilot: option links after training starships")
end

-- AC-1
function TestTuroldineTrainRedirect:test_pilot_can_train_every_box_in_one_visit()
	local player = pilot(1)
	local ok, t = pcall(talk, player, { SID.fighters, SID.components, SID.techniques })

	lu.assertTrue(ok, "a pilot with xp left for all boxes hit a dead end after the first box: " .. tostring(t))
	lu.assertEquals(#t, 4, "screens in a three-box visit")
	lu.assertEquals(t[3].id, "ready_train_pilot", "after the second box")
	lu.assertEquals(linksOf(t[3]), { "initial_train_techniques", "initial_train_algorithms" }, "after the second box: links")
	lu.assertEquals(t[4].id, "ready_train_pilot", "after the third box")
	lu.assertEquals(linksOf(t[4]), { "initial_train_algorithms" }, "after the third box: links")
end

-- AC-2
function TestTuroldineTrainRedirect:test_template_ready_train_pilot_is_not_modified()
	local player = pilot(1)

	talk(player, { SID.fighters })

	local screens = H.conversationTemplateTable(TR.template).screens
	local found

	for _, s in ipairs(screens) do
		if s.id == "ready_train_pilot" then
			found = s
		end
	end

	lu.assertNotNil(found, "ready_train_pilot in the template")

	local tmpl = H.conversationTemplate(TR.template)
	local fake = tmpl:getScreen("ready_train_pilot")

	lu.assertEquals(#fake.options, 0, "template ready_train_pilot: options")
	lu.assertEquals(next(fake.params or {}), nil, "template ready_train_pilot: params")
end

-- AC-3
function TestTuroldineTrainRedirect:test_training_that_spends_the_xp_shows_the_briefing_as_before()
	H.Engine.config.skillXpCosts = { [BOX.starships] = 2500000 }

	local player = pilot(1)
	local t = talk(player, { SID.fighters })

	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1, "box granted")
	lu.assertEquals(player.ghost.experience.space_combat_general, 500000, "xp left")
	lu.assertEquals(t[2].id, "initial_train_fighters", "briefing screen")
	lu.assertEquals(t[2].params and t[2].params.TU, "Ace", "initial_train_fighters: params.TU")
	lu.assertEquals(linksOf(t[2]), { "ramna_distinguished", "neither_do_i" }, "initial_train_fighters: links")
end

-- AC-4
function TestTuroldineTrainRedirect:test_last_box_with_mission_four_not_tried_shows_fourth_mission_with_the_name()
	local player = pilot(4, { baseSkills = skillsWith(BOX.starships, BOX.weapons, BOX.procedures) })
	local t = talk(player, { SID.algorithms })
	local screen = t[2]

	lu.assertEquals(t[1].id, "ready_train_pilot", "first screen")
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1, "last box granted")
	lu.assertEquals(screen and screen.id, "fourth_mission", "screen after the last box")
	lu.assertEquals(screen and screen.params and screen.params.TU, "Ace", "fourth_mission: params.TU")
end

-- AC-4
function TestTuroldineTrainRedirect:test_last_box_after_a_failed_mission_four_shows_failed_fourth_mission_and_grants_it_once()
	-- startQuest only: the real grantSpaceSkill must run, or the pilot never completes tier 4
	local rec = { starts = {} }

	for _, name in ipairs(H.questGlobals()) do
		H.spyOn(rawget(_G, name), "startQuest", function() rec.starts[#rec.starts + 1] = name end)
	end

	local player = pilot(4, { baseSkills = skillsWith(BOX.starships, BOX.weapons, BOX.procedures), attempted = true })
	local t = talk(player, { SID.algorithms })
	local screen = t[2]

	lu.assertEquals(t[1].id, "ready_train_pilot", "first screen")
	lu.assertEquals(screen and screen.id, "failed_fourth_mission", "screen after the last box")
	lu.assertEquals(screen and screen.params and screen.params.TU, "Ace", "failed_fourth_mission: params.TU")
	lu.assertEquals(countOf(rec.starts, "assassinate_corellia_privateer_tier4_4a"), 1, "assassinate_corellia_privateer_tier4_4a:startQuest calls")
end

-- AC-5
function TestTuroldineTrainRedirect:test_last_box_after_mission_four_side_three_shows_master_mission_and_pays_nothing()
	local rec = T.spyRewards()
	local player = pilot(4, {
		baseSkills = skillsWith(BOX.starships, BOX.weapons, BOX.procedures),
		win = { 1, 2, 3, 4 },
		attempted = true,
	})
	local t = talk(player, { SID.algorithms })
	local screen = t[2]

	lu.assertEquals(t[1].id, "ready_train_pilot", "first screen")
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1, "last box granted")
	lu.assertEquals(screen and screen.id, "master_mission", "screen after the last box")
	lu.assertEquals(screen and screen.params and screen.params.TU, "Ace", "master_mission: params.TU")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

-- AC-6
function TestTuroldineTrainRedirect:test_third_mission_success_through_the_redirect_pays_once()
	local rec = T.spyRewards()
	local player = pilot(1)
	local markWon = function(p)
		T.setState(p, "space_battle_corellia_privateer_tier4_3c_win", "complete")
	end

	local t = talk(player, { markWon, SID.fighters })

	lu.assertEquals(t[1].id, "ready_train_pilot", "first screen")
	lu.assertEquals(t[2].id, "third_mission_success", "screen after the training")
	lu.assertEquals(t[2].params and t[2].params.TU, "Ace", "third_mission_success: params.TU")
	lu.assertEquals(countOf(rec.rewards, "space_battle_corellia_privateer_tier4_3a"), 1, "space_battle_corellia_privateer_tier4_3a:rewardPlayer calls, first visit")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_tier4_3a:reward"), "1", "corellia_privateer_tier4_3a:reward")

	local again = talk(player, {})

	lu.assertNotEquals(again[1].id, "third_mission_success", "second visit first screen")
	lu.assertEquals(countOf(rec.rewards, "space_battle_corellia_privateer_tier4_3a"), 1, "rewardPlayer calls across both visits")
	lu.assertEquals(#rec.rewards, 1, "rewardPlayer calls of any quest across both visits")
end


---------------------------------------------------------------------------------------------
-- Amendment A-1: the training options after mission 3 link to screens that exist
---------------------------------------------------------------------------------------------

local THREE_BOXES = function() return skillsWith(BOX.starships, BOX.weapons, BOX.procedures) end

local function templateIds()
	local ids = {}

	for _, s in ipairs(H.conversationTemplateTable(TR.template).screens) do
		ids[s.id] = true
	end

	return ids
end

local function spyStarts()
	local rec = { starts = {} }

	for _, name in ipairs(H.questGlobals()) do
		H.spyOn(rawget(_G, name), "startQuest", function() rec.starts[#rec.starts + 1] = name end)
	end

	return rec
end

-- AC-8
function TestTuroldineTrainRedirect:test_pilot_who_won_mission_three_is_offered_final_train_algorithms()
	local player = pilot(4, { baseSkills = THREE_BOXES() })
	local t = talk(player, {})

	lu.assertEquals(t[1].id, "ready_train_pilot", "first screen")
	lu.assertEquals(linksOf(t[1]), { "final_train_algorithms" }, "ready_train_pilot: option links after mission 3")
end

-- AC-8
function TestTuroldineTrainRedirect:test_no_ready_train_pilot_option_links_to_a_missing_screen_in_any_mission_state()
	local ids = templateIds()
	-- mission state -> number of missions won (M4 side 3 is the 4th)
	local states = {
		none = { n = 1 },
		m1 = { n = 2 },
		m2 = { n = 3 },
		m3 = { n = 4 },
		m4 = { n = 4, win = { 1, 2, 3, 4 }, attempted = true },
	}

	for name, st in pairs(states) do
		H.reset()

		local player = pilot(st.n, { win = st.win, attempted = st.attempted })
		local t = talk(player, {})

		lu.assertEquals(t[1].id, "ready_train_pilot", name .. ": first screen")
		lu.assertEquals(#t[1].options, 4, name .. ": ready_train_pilot options")

		for _, link in ipairs(linksOf(t[1])) do
			lu.assertTrue(ids[link] == true, name .. ": ready_train_pilot links to '" .. tostring(link) .. "', which turoldine_convo_template does not define")
		end
	end
end

-- AC-8
function TestTuroldineTrainRedirect:test_handler_source_has_no_mission4_prefix()
	local path = "bin/scripts/screenplays/space/conversations/neutral/corsec_squadron/turoldineConvoHandler.lua"
	local f = io.open(path, "r")

	lu.assertNotNil(f, "cannot open " .. path .. " (run from MMOCoreORB/)")

	local src = f:read("a")

	f:close()
	lu.assertNil(src:find('"mission4_"', 1, true), 'turoldineConvoHandler.lua still contains "mission4_"')
end

-- AC-9
function TestTuroldineTrainRedirect:test_fourth_box_that_spends_the_xp_shows_final_train_screen_and_leads_to_mission_four()
	H.Engine.config.skillXpCosts = { [BOX.droid] = 2500000 }

	local rec = spyStarts()
	local player = pilot(4, { baseSkills = THREE_BOXES() })
	local path = T.optionPath(TR.template, "final_train_algorithms", { accept_fourth_mission = true })

	lu.assertNotNil(path, "final_train_algorithms leads to accept_fourth_mission")

	local choices = { SID.algorithms }

	for _, i in ipairs(path) do
		choices[#choices + 1] = i
	end

	local t = talk(player, choices)

	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1, "fourth box granted")
	lu.assertEquals(H.Engine.callsTo("skillManagerAwardSkill")[1][2], BOX.droid, "box granted")
	lu.assertEquals(player.ghost.experience.space_combat_general, 500000, "xp left")
	lu.assertEquals(t[2] and t[2].id, "final_train_algorithms", "screen after the pick")
	lu.assertEquals(t[2] and t[2].params and t[2].params.TU, "Ace", "final_train_algorithms: params.TU")
	lu.assertEquals(linksOf(t[2] or {}), { "isnt_so_crazy", "another_assassination" }, "final_train_algorithms: links")
	lu.assertEquals(t[#t].id, "accept_fourth_mission", "last screen of the walk")
	lu.assertEquals(countOf(rec.starts, "assassinate_corellia_privateer_tier4_4a"), 1, "assassinate_corellia_privateer_tier4_4a:startQuest calls")
end
