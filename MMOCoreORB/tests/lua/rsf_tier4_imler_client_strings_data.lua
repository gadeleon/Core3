-- Shared data of the Imler part 1 client-string work (space-convo-client-strings-imler-a, .claude/work/space-convo-client-strings-imler-a/01-spec.md).
-- Copied from the spec (Appendix A, B, D, E, F and Content contract 1 .. 3), not read from imler_convo.lua or imlerConvoHandler.lua, so a wrong production value fails a
-- test instead of agreeing with itself.
--   D.BASE          the commit the "nothing else moves" checks compare with
--   D.SITES         Appendix A: the 3 lines of imler_convo.lua that change, as { line (at base 57664ade04), screen, field ("leftDialog" or the 1-based option index),
--                   link (option rows: the screen the option leads to, unchanged), nge, twin }
--   D.TWIN          nge id -> pre-NGE id (derived from D.SITES)
--   D.TEXT          Appendix B: the client text of the 3 twin ids and of the 4 training replies, as the trailing `-- <text>` comments quote it. Each text is the
--                   text whose SWG CRC-32 is the id (the client's ids are content hashes), which test_space_convo_client_strings_imler_a.lua checks
--   D.BRIEF         Appendix B: the unchanged lines of ready_train and of the four mission briefs
--   D.DELETED       Content contract 1: the 8 deleted screens, with their base line ranges (396-460)
--   D.TRAIN_CHOICES Content contract 2 item 2: the handler table, complete string literals
--   D.TRAINING      the four choices as rows { x, skill, sid, reply, text }
--   D.F6A_IDS       the 15 NGE ids this feature removes from the ratchet; D.REMAINING: Appendix F (the 196 ids F6b keeps)
--   D.LEFT_COUNTS   Appendix D: the leftDialog ids that appear on more than one screen after the feature
--   D.BLOCK1..3     Appendix E: the new handler text, line by line

local D = {}

D.BASE = "57664ade04"
D.PREFIX = "@conversation/naboo_privateer_tier4:"
D.FILE = "conversation/naboo_privateer_tier4"
D.AC_BASE_LINES = 1402
D.AC_LINES = 1337
D.AH_BASE_LINES = 374
D.AH_LINES = 391

D.SITES = {
	{ line = 23, screen = "s_9", field = "leftDialog", link = nil, nge = "s_9", twin = "s_35a5b893" },
	{ line = 46, screen = "duty_info", field = 1, link = "s_1993702c", nge = "s_416", twin = "s_3f68df7d" },
	{ line = 1250, screen = "wrong_faction", field = "leftDialog", link = nil, nge = "s_4", twin = "s_aa1834ec" },
}

D.TWIN = {}

for _, site in ipairs(D.SITES) do
	D.TWIN[site.nge] = site.twin
end

D.TEXT = {
	s_aa1834ec = "I don't think I've seen you before. Maybe you took a wrong turn somewhere.",
	s_35a5b893 = "Won't find any here. See ya.",
	s_3f68df7d = "Sounds easy enough.",
	s_ada4db16 = "Teach me about exotic vessels.",
	s_25506b23 = "Teach me about heavy starship component use.",
	s_fd7e4ac8 = "Teach me about expert techniques.",
	s_1813de4d = "Teach me about droid intelligence theory.",
}

D.BRIEF = {
	ready_train = { sid = "s_d91c04b2", text = "I'm supposed to give you a skill. Hurry up. Let's get this over with." },
	mission1_brief = { sid = "s_9312a850", text = "So. How was life with Commander Delios?" },
	mission2_brief = { sid = "s_bdc28bb4", text = "You did a nice job protecting that scan vessel. We took a look at the tapes." },
	mission3_brief = { sid = "s_ff6e1247", text = "Those Black Suns didn't like the fact you found their secret cargo." },
	mission4_brief = { sid = "s_e4bbe441", text = "I think the Black Suns have declared war on the RSF." },
}

-- The four training choices in SWG order (D-6)
D.TRAINING = {
	{ x = "starships", skill = "pilot_neutral_starships_04", sid = "s_ada4db16" },
	{ x = "weapons", skill = "pilot_neutral_weapons_04", sid = "s_25506b23" },
	{ x = "procedures", skill = "pilot_neutral_procedures_04", sid = "s_fd7e4ac8" },
	{ x = "droid", skill = "pilot_neutral_droid_04", sid = "s_1813de4d" },
}

for _, row in ipairs(D.TRAINING) do
	row.reply = D.PREFIX .. row.sid
	row.text = D.TEXT[row.sid]
	row.screen = "mission1_brief" -- the static default link, never followed (D-4)
end

-- Content contract 2 item 2
D.TRAIN_CHOICES = {
	{ "pilot_neutral_starships_04", "@conversation/naboo_privateer_tier4:s_ada4db16", "mission1_brief" },
	{ "pilot_neutral_weapons_04", "@conversation/naboo_privateer_tier4:s_25506b23", "mission1_brief" },
	{ "pilot_neutral_procedures_04", "@conversation/naboo_privateer_tier4:s_fd7e4ac8", "mission1_brief" },
	{ "pilot_neutral_droid_04", "@conversation/naboo_privateer_tier4:s_1813de4d", "mission1_brief" },
}

-- Content contract 1 / Appendix A: the eight deleted screens (base lines 396-460), in order
D.DELETED_FROM = 396
D.DELETED_TO = 460
D.DELETED = {
	{ id = "train_starships", from = 396, to = 402 },
	{ id = "train_weapons", from = 403, to = 409 },
	{ id = "train_procedures", from = 410, to = 416 },
	{ id = "train_droid", from = 417, to = 423 },
	{ id = "trained_mission4", from = 424, to = 432 },
	{ id = "trained_mission3", from = 433, to = 442 },
	{ id = "trained_mission2", from = 443, to = 451 },
	{ id = "trained_mission1", from = 452, to = 460 },
}

-- The NGE ids of the 8 deleted screens: s_439-s_442 (prompts), s_443/445/447/449 (buy replies), s_451 s_489 s_623 s_737 (intros)
D.TRAINING_NGE_IDS = { "s_439", "s_440", "s_441", "s_442", "s_443", "s_445", "s_447", "s_449", "s_451", "s_489", "s_623", "s_737" }

-- The 15 ids this feature removes from KNOWN_GAPS (Source inventory)
D.F6A_IDS = { "s_4", "s_9", "s_416", "s_439", "s_440", "s_441", "s_442", "s_443", "s_445", "s_447", "s_449", "s_451", "s_489", "s_623", "s_737" }

-- Appendix F: the odd numbers s_453-s_487, s_491-s_621, s_625-s_735 and s_739-s_849
D.REMAINING = {}

for _, range in ipairs({ { 453, 487 }, { 491, 621 }, { 625, 735 }, { 739, 849 } }) do
	for n = range[1], range[2], 2 do
		D.REMAINING[#D.REMAINING + 1] = "s_" .. n
	end
end

-- Source inventory / Data mapping: unused I4 sids after the feature (10 NPC lines, 6 replies) and the client-only ids the files add
D.UNUSED_NPC = { "s_4", "s_9", "s_439", "s_440", "s_441", "s_442", "s_451", "s_489", "s_623", "s_737" }
D.UNUSED_REPLIES = { "s_416", "s_438", "s_443", "s_445", "s_447", "s_449" }
D.CLIENT_ONLY = { "s_1813de4d", "s_25506b23", "s_3f68df7d", "s_ada4db16", "s_fd7e4ac8" }

-- Appendix D
D.LEFT_COUNTS = { s_aa1834ec = 2, s_35a5b893 = 2 }

local function lines(text)
	local out = {}

	for line in text:gmatch("(.-)\n") do
		out[#out + 1] = line
	end

	return out
end

D.BLOCK1 = lines([==[
-- Pre-NGE free choice of the next skill: { skill, reply, static link }, in SWG order.
-- The replies are Imler's pre-NGE client lines (space-convo-client-strings-imler-a). getNextConversationScreen
-- identifies the choice by its reply, buys the skill and picks the mission brief; the link is only the static default.
imlerConvoHandler.TRAIN_CHOICES = {
	{ "pilot_neutral_starships_04", "@conversation/naboo_privateer_tier4:s_ada4db16", "mission1_brief" }, -- Teach me about exotic vessels.
	{ "pilot_neutral_weapons_04", "@conversation/naboo_privateer_tier4:s_25506b23", "mission1_brief" }, -- Teach me about heavy starship component use.
	{ "pilot_neutral_procedures_04", "@conversation/naboo_privateer_tier4:s_fd7e4ac8", "mission1_brief" }, -- Teach me about expert techniques.
	{ "pilot_neutral_droid_04", "@conversation/naboo_privateer_tier4:s_1813de4d", "mission1_brief" } -- Teach me about droid intelligence theory.
}
]==])

D.BLOCK2 = lines([==[
-- Choosing a skill's reply on ready_train buys the skill (once), then the pilot is briefed on the mission the
-- new skill count unlocks (pre-NGE one click: the choice reply, then the mission brief)
function imlerConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	if (self:getLastScreenID(pPlayer) ~= "ready_train") then
		return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
	end

	-- The skill is the one whose reply the pilot picked on the live (cloned) screen
	local chosen = nil
	local convSession = CreatureObject(pPlayer):getConversationSession()

	if (convSession ~= nil) then
		local pLastScreen = LuaConversationSession(convSession):getLastConversationScreen()

		if (pLastScreen ~= nil) then
			chosen = LuaConversationScreen(pLastScreen):getOptionText(selectedOption)
		end
	end

	local skill = nil

	for _, choice in ipairs(self.TRAIN_CHOICES) do
		if (choice[2] == chosen) then
			skill = choice[1]
			break
		end
	end

	if (skill == nil) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	if (not CreatureObject(pPlayer):hasSkill(skill) and SpaceHelpers:hasExperienceForTraining(pPlayer, 4)) then
		SpaceHelpers:grantSpaceSkill(pPlayer, skill, true)
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		local ghost = LuaPlayerObject(pGhost)

		if (ghost ~= nil and ghost:getPilotTier() <= 4 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 4)) then
			ghost:incrementPilotTier()
		end
	end

	local skillCount = SpaceHelpers:getPilotTierSkillCount(pPlayer, "neutral", 4)
	local nextScreen = "mission1_brief"

	if (skillCount >= 2 and skillCount <= 4) then
		nextScreen = "mission" .. skillCount .. "_brief"
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(nextScreen)
end
]==])

D.BLOCK3 = lines([==[
	-- A mission brief (after training or from ready_mission): the pilot is ready for that mission
	elseif (string.match(screenID, "^mission%d_brief$") ~= nil) then
]==])

-- Content contract 2: the four hunks, as { from, to (base lines replaced; to = from - 1 inserts), lines }. Hunk 1 deletes base lines 45-52 (the comment, TRAIN_SCREENS and
-- the blank line after it)
D.HUNKS = {
	{ from = 45, to = 52, lines = {} },
	{ from = 60, to = 67, lines = D.BLOCK1 },
	{ from = 241, to = 272, lines = D.BLOCK2 },
	{ from = 347, to = 347, lines = D.BLOCK3 },
}

return D
