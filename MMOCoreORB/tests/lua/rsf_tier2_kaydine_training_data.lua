-- Shared test data for the RSF tier 2 Kaydine training (not a test file).
-- Spec: .claude/work/rsf-tier2-kaydine-training/01-spec.md (Source inventory, Content contract, Data mapping, Appendix A).
--
-- Everything below is copied from the spec, not read from kaydine_convo.lua / kaydineConvoHandler.lua, so a wrong production value
-- makes a test fail instead of agreeing with itself:
--   D.ROWS      Appendix A, 35 rows: 1 changed (ready_train_pilot), 30 new, 4 convo screens that exist already (status "conv")
--   D.EXCEPT    the (screen id, option sid) pairs of E-T1, E-T2, E-T3 (static links that differ from the java default)
--   D.TRAINING  the four skills in SWG's purchase order with their prompt screens
--   D.INTRO     the 16 intro screens (skill x mission) and the screen each one leads to
--   D.GRANT     per (skill, mission): the screens option 1 walks through to the grant screen (Conversation flow "Training walk")
--   D.drive     a driver that starts a conversation on a given screen, as if the pilot had just chosen an option there

local lu = require("luaunit")
local H = require("harness")

local D = {}

D.PREFIX = "@conversation/naboo_privateer_trainer_2:"
D.TEMPLATE = "kaydine_convo_template"
D.SCREEN_COUNT = 100 -- 87 + the 4 gate screens of rsf-gate-screens + the 9 sign-up screens of rsf-tier2-kaydine-signup

-- Appendix A. options are { option sid, static link }.
D.ROWS = {
	-- pilot-training-free-choice E-PN1: the static options are empty, the handler adds the choice (replaces the single reply s_187 -> train_droid)
	{ id = "ready_train_pilot", status = "chg", sid = "s_76e6f264", animation = "salute1", stop = false, options = {} },
	{ id = "train_starships", status = "new", sid = "s_188", animation = "", stop = false, options = { {"s_192", "trained_starships_mission4"} } },
	{ id = "train_weapons", status = "new", sid = "s_189", animation = "", stop = false, options = { {"s_194", "trained_weapons_mission4"} } },
	{ id = "train_procedures", status = "new", sid = "s_190", animation = "", stop = false, options = { {"s_196", "trained_procedures_mission4"} } },
	{ id = "train_droid", status = "new", sid = "s_191", animation = "", stop = false, options = { {"s_198", "trained_droid_mission4"} } },
	{ id = "trained_starships_mission1", status = "new", sid = "s_224", animation = "applause_polite", stop = false, options = { {"s_226", "mission1_intro_a1"}, {"s_248", "mission1_intro_b1"} } },
	{ id = "trained_starships_mission2", status = "new", sid = "s_270", animation = "", stop = false, options = { {"s_272", "mission2_brief"} } },
	{ id = "trained_starships_mission3", status = "new", sid = "s_284", animation = "shake_head_disgust", stop = false, options = { {"s_286", "mission3_intro"} } },
	{ id = "trained_starships_mission4", status = "new", sid = "s_294", animation = "", stop = false, options = { {"s_296", "mission4_brief"} } },
	{ id = "trained_weapons_mission1", status = "new", sid = "s_216", animation = "", stop = false, options = { {"s_238", "mission1_brief"} } },
	{ id = "trained_weapons_mission2", status = "new", sid = "s_218", animation = "", stop = false, options = { {"s_272", "mission2_brief"} } },
	{ id = "trained_weapons_mission3", status = "new", sid = "s_220", animation = "", stop = false, options = { {"s_290", "mission3_accept"} } },
	{ id = "trained_weapons_mission4", status = "new", sid = "s_222", animation = "", stop = false, options = { {"s_296", "mission4_brief"} } },
	{ id = "trained_procedures_mission1", status = "new", sid = "s_208", animation = "", stop = false, options = { {"s_238", "mission1_brief"} } },
	{ id = "trained_procedures_mission2", status = "new", sid = "s_210", animation = "", stop = false, options = { {"s_272", "mission2_brief"} } },
	{ id = "trained_procedures_mission3", status = "new", sid = "s_212", animation = "", stop = false, options = { {"s_290", "mission3_accept"} } },
	{ id = "trained_procedures_mission4", status = "new", sid = "s_214", animation = "", stop = false, options = { {"s_296", "mission4_brief"} } },
	{ id = "trained_droid_mission1", status = "new", sid = "s_200", animation = "", stop = false, options = { {"s_238", "mission1_brief"} } },
	{ id = "trained_droid_mission2", status = "new", sid = "s_202", animation = "", stop = false, options = { {"s_272", "mission2_brief"} } },
	{ id = "trained_droid_mission3", status = "new", sid = "s_204", animation = "", stop = false, options = { {"s_290", "mission3_accept"} } },
	{ id = "trained_droid_mission4", status = "new", sid = "s_206", animation = "", stop = false, options = { {"s_296", "mission4_brief"} } },
	{ id = "mission1_intro_a1", status = "new", sid = "s_228", animation = "nod_head_once", stop = false, options = { {"s_230", "mission1_intro_a2"} } },
	{ id = "mission1_intro_a2", status = "new", sid = "s_232", animation = "shrug_shoulders", stop = false, options = { {"s_234", "mission1_intro_a3"} } },
	{ id = "mission1_intro_a3", status = "new", sid = "s_236", animation = "", stop = false, options = { {"s_238", "mission1_brief"} } },
	{ id = "mission1_intro_b1", status = "new", sid = "s_250", animation = "shake_head_disgust", stop = false, options = { {"s_252", "mission1_intro_b2"} } },
	{ id = "mission1_intro_b2", status = "new", sid = "s_254", animation = "shrug_shoulders", stop = false, options = { {"s_256", "mission1_intro_b3"} } },
	{ id = "mission1_intro_b3", status = "new", sid = "s_258", animation = "", stop = false, options = { {"s_260", "mission1_intro_b4"} } },
	{ id = "mission1_intro_b4", status = "new", sid = "s_262", animation = "", stop = false, options = { {"s_264", "mission1_intro_accept"} } },
	{ id = "mission1_intro_accept_male", status = "new", sid = "s_266", animation = "", stop = true, options = {} },
	{ id = "mission1_intro_accept", status = "new", sid = "s_268", animation = "", stop = true, options = {} },
	{ id = "mission3_intro", status = "new", sid = "s_288", animation = "", stop = false, options = { {"s_290", "mission3_accept"} } },
	{ id = "mission1_brief", status = "conv", sid = "s_240", animation = "", stop = false, options = { {"s_242", "mission1_accept"} } },
	{ id = "mission2_brief", status = "conv", sid = "s_274", animation = "", stop = false, options = { {"s_276", "mission2_details"} } },
	{ id = "mission3_accept", status = "conv", sid = "s_292", animation = "", stop = true, options = {} },
	{ id = "mission4_brief", status = "conv", sid = "s_298", animation = "", stop = false, options = { {"s_300", "mission4_accept"} } },
}

-- Exceptions E-T1, E-T2, E-T3: "<screen id>|<option sid>" -> exception name. Their static link is the java's last (unconditional) successor
-- or an adapted one, and the handler re-points it at run time.
D.EXCEPT = {
	["ready_train_pilot|s_187"] = "E-T1",
	["train_starships|s_192"] = "E-T2",
	["train_weapons|s_194"] = "E-T2",
	["train_procedures|s_196"] = "E-T2",
	["train_droid|s_198"] = "E-T2",
	["mission1_intro_b4|s_264"] = "E-T3",
}

-- The four tier 2 skills in SWG's purchase order (K:2204-2330)
D.TRAINING = {
	{ x = "starships", skill = "pilot_neutral_starships_02", screen = "train_starships", optionSid = "s_192", promptSid = "s_188" },
	{ x = "weapons", skill = "pilot_neutral_weapons_02", screen = "train_weapons", optionSid = "s_194", promptSid = "s_189" },
	{ x = "procedures", skill = "pilot_neutral_procedures_02", screen = "train_procedures", optionSid = "s_196", promptSid = "s_190" },
	{ x = "droid", skill = "pilot_neutral_droid_02", screen = "train_droid", optionSid = "s_198", promptSid = "s_191" },
}

D.SKILLS = { "pilot_neutral_starships_02", "pilot_neutral_weapons_02", "pilot_neutral_procedures_02", "pilot_neutral_droid_02" }

D.TRAIN_SCREENS = {
	train_starships = "pilot_neutral_starships_02",
	train_weapons = "pilot_neutral_weapons_02",
	train_procedures = "pilot_neutral_procedures_02",
	train_droid = "pilot_neutral_droid_02",
}

-- The 30 screens that are new (Appendix A status "new") and the one that changed
function D.newIds()
	local out = {}

	for _, r in ipairs(D.ROWS) do
		if r.status == "new" then
			out[#out + 1] = r.id
		end
	end

	return out
end

-- Mission head and the key base of :attempted / :reward per mission (the convo feature's table)
D.HEADS = {
	"assassinate_naboo_privateer_tier2_1a", "destroy_naboo_privateer_13", "recovery_naboo_privateer_14", "escort_naboo_privateer_15",
}
D.KEYS = { "naboo_privateer_tier2_1a", "naboo_privateer_13", "naboo_privateer_14", "naboo_privateer_15" }
-- the quests that make mission n won
D.WON = {
	{ "assassinate_naboo_privateer_tier2_1a", "assassinate_naboo_privateer_tier2_1b", "assassinate_naboo_privateer_tier2_1c" },
	{ "destroy_naboo_privateer_13" }, { "recovery_naboo_privateer_14" }, { "escort_naboo_privateer_15" },
}

-- Conversation flow "Training walk": for (x, N) the screens that follow trained_<x>_mission<N> when option 1 is chosen each time,
-- ending on the grant screen. Mission 1 as a male pilot (the fake's default gender): the brief re-points to mission1_accept_male.
-- Starships mission 1 has a second route (option 2 on the intro) through the b-screens.
local function walk(x, n)
	local first = "trained_" .. x .. "_mission" .. n

	if n == 1 then
		if x == "starships" then
			return { first, "mission1_intro_a1", "mission1_intro_a2", "mission1_intro_a3", "mission1_brief", "mission1_accept_male" }
		end

		return { first, "mission1_brief", "mission1_accept_male" }
	elseif n == 2 then
		return { first, "mission2_brief", "mission2_details", "mission2_accept" }
	elseif n == 3 then
		if x == "starships" then
			return { first, "mission3_intro", "mission3_accept" }
		end

		return { first, "mission3_accept" }
	end

	return { first, "mission4_brief", "mission4_accept" }
end

-- D.INTRO: 16 rows { x, n, id, walk (option 1 each step), grant (the screen that starts the head) }
D.INTRO = {}

for _, t in ipairs(D.TRAINING) do
	for n = 1, 4 do
		local w = walk(t.x, n)

		D.INTRO[#D.INTRO + 1] = { x = t.x, n = n, skill = t.skill, id = "trained_" .. t.x .. "_mission" .. n, walk = w, grant = w[#w] }
	end
end

-- The second route of trained_starships_mission1 (option 2): male and female end screens
D.ROUTE_B = { "trained_starships_mission1", "mission1_intro_b1", "mission1_intro_b2", "mission1_intro_b3", "mission1_intro_b4" }

-- The screens that start a story chain (I-5): the convo feature's start screens plus the two new ones
D.STARTS = {
	mission1_accept = 1, mission1_accept_male = 1, mission1_failed = 1, mission1_intro_accept = 1, mission1_intro_accept_male = 1,
	mission2_accept = 2, mission2_failed = 2,
	mission3_accept = 3, mission3_failed = 3,
	mission4_accept = 4, mission4_failed = 4,
}

-- The 20 screens of the old free-choice training (deleted)
D.OLD_TRAIN_SCREENS = {}

for _, p in ipairs({ "initial", "mission2", "mission3", "mission4", "final" }) do
	for _, w in ipairs({ "fighters", "components", "techniques", "algorithms" }) do
		D.OLD_TRAIN_SCREENS[#D.OLD_TRAIN_SCREENS + 1] = p .. "_train_" .. w
	end
end

-- The 4 NPC-line sids of the old training that are not in the java (convo spec I-3). The old greeting s_8a84109d left this list with rsf-gate-screens:
-- it is the java's off-track duty line now (Kaydine non_rsf_duty_options). The 4 old reply sids (s_45b71b4d, s_197f4f94, s_8f5942fa, s_eff66f4d) left this
-- list with pilot-training-free-choice: they are the choice replies again (D-4), see pilot_training_free_choice_data.lua.
D.OLD_SIDS = { "s_4aa3066e", "s_8ad6a62e", "s_f32117e", "s_fd75abb" }

-- pilot-training-free-choice E-PN1: screen id -> the single java reply the choice replaces
D.E_PN = { ready_train_pilot = "s_187" }

---------------------------------------------------------------------------------------------
-- Driver
---------------------------------------------------------------------------------------------

-- Starts a conversation as if the pilot had just chosen an option on screen `startId`: the screen counts as displayed (its handlers have run and
-- the session holds it), then `choices` (0-based option indexes, option sids or hooks as in H.converse) are followed. The transcript starts with
-- the start screen. This reaches screens that no first screen leads to (for example train_droid for a pilot who also lacks starships).
function D.drive(tr, player, startId, choices)
	local tmpl = H.conversationTemplate(tr.template)
	local handler = H.expectGlobal(H.conversationTemplateTable(tr.template).luaClassHandler, "luaClassHandler of " .. tr.template)
	local npc = H.newNpc({ name = "Trainer" })
	local session = H.Fakes.newConversationSession(npc)
	local transcript = {}

	player.conversationSession = session

	local function show(screen)
		local options = {}

		for i, o in ipairs(screen.options) do
			options[i] = { text = o.text, link = o.link }
		end

		transcript[#transcript + 1] = { id = screen.id, text = screen.dialogText, options = options, params = screen.params, stop = screen.stopConversation }
	end

	local screen = LuaConversationTemplate(tmpl):getScreen(startId)

	lu.assertNotNil(screen, "screen '" .. startId .. "' is not in " .. tr.template)
	screen = handler:runScreenHandlers(tmpl, player, npc, 0, screen)
	lu.assertNotNil(screen, "runScreenHandlers returned no screen for '" .. startId .. "'")
	session.lastScreen = screen
	show(screen)

	local i = 1

	while i <= #(choices or {}) and not screen.stopConversation do
		local choice = choices[i]

		i = i + 1

		if type(choice) == "function" then
			choice(player)
		else
			if type(choice) == "string" then
				local found

				for k, o in ipairs(screen.options) do
					if o.text == choice or o.text:sub(-#choice - 1) == ":" .. choice then
						found = k - 1
						break
					end
				end

				lu.assertNotNil(found, "screen '" .. screen.id .. "' has no option '" .. choice .. "'")
				choice = found
			end

			screen = handler:getNextConversationScreen(tmpl, player, choice, npc)

			if screen ~= nil then
				screen = handler:runScreenHandlers(tmpl, player, npc, choice, screen)
			end

			session.lastScreen = screen

			if screen == nil then
				break
			end

			show(screen)
		end
	end

	return transcript
end

return D
