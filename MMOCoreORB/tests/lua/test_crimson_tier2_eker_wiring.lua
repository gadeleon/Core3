-- Major Eker: wiring (AC-1) and the handler helpers the spec names (Content contract 3).
-- Spec: .claude/work/crimson-phoenix-tier2-eker-convo/01-spec.md (AC-1; Content contract 1 and 3; Source inventory 1; I-8).
--
-- The template and the handler load through the server's include order, his mobile template names the conversation and is conversable and invulnerable,
-- the two include lines sit at lines 79 and 124 uncommented (once each) while Ulvaw'op's and Ufwol's stay commented, and the handler has the helpers the spec names.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier2_data")

E.loadConversation()

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function linesOf(text)
	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	return lines
end

local function countMatches(text, pattern)
	local n = 0

	for _ in text:gmatch(pattern) do
		n = n + 1
	end

	return n
end

local function truthy(v) return not not v end

TestEkerWiring = {}

function TestEkerWiring:setUp() H.reset() end

-- AC-1
function TestEkerWiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	E.requireConversation(lu)

	local t = H.conversationTemplateTable(E.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, E.HANDLER, E.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", E.TEMPLATE .. ": templateType")
	lu.assertEquals(t.initialScreen, "", E.TEMPLATE .. ": initialScreen (the handler picks the first screen)")

	local h = rawget(_G, E.HANDLER)

	for _, name in ipairs({ "getInitialScreen", "runScreenHandlers", "getNextConversationScreen", "isOnMission", "canFlyNonTrackDuty", "tier2Count", "getPilotFlag", "isReadyForTraining", "isTester" }) do
		lu.assertEquals(type(h[name]), "function", E.HANDLER .. ":" .. name)
	end
end

-- AC-1: his mobile template names the conversation and gets the Socuna / Vrovel mask
function TestEkerWiring:test_eker_uses_the_template_and_is_conversable_and_invulnerable()
	local npc = H.loadCreatureTemplate("space/eker.lua", "eker")

	lu.assertNotNil(npc, "mobile/space/eker.lua registers eker")
	lu.assertEquals(npc.conversationTemplate, "eker_convo_template", "eker: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "eker: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask & INVULNERABLE, INVULNERABLE, "eker: optionsBitmask lacks INVULNERABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "eker: optionsBitmask")
end

-- AC-1: only the two fields change; his identity stays
function TestEkerWiring:test_eker_keeps_his_identity_fields()
	local npc = H.loadCreatureTemplate("space/eker.lua", "eker")

	lu.assertNotNil(npc, "mobile/space/eker.lua registers eker")
	lu.assertEquals(npc.objectName, "@npc_spawner_n:eker", "eker: objectName")
	lu.assertEquals(npc.faction, "rebel", "eker: faction")
	lu.assertEquals(npc.pvpBitmask, NONE, "eker: pvpBitmask")
	lu.assertEquals(npc.templates, { "object/mobile/space_rebel_tier2_eker.iff" }, "eker: templates")
end

-- AC-1, Content contract 1: the template include sits uncommented at line 80; Socuna's stays at 81; Ulvaw'op's and Ufwol's stay commented
function TestEkerWiring:test_the_template_include_is_uncommented_once_at_line_80_and_ulvawop_and_ufwol_stay_commented()
	local text = readFile(H.SCRIPTS .. E.SPACE_CONVERSATIONS)
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("conversations/space/rebel/crimson_phoenix_squadron/eker_convo%.lua"%)'), 1, "space_conversations.lua: eker_convo include occurrences (commented or not)")
	lu.assertEquals(lines[80], 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/eker_convo.lua")', "space_conversations.lua line 80")
	lu.assertEquals(lines[79], "-- Crimson Phoenix Squadron", "space_conversations.lua line 79")
	lu.assertEquals(lines[81], 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/socuna_convo.lua")', "space_conversations.lua line 81 (Socuna unchanged)")
	lu.assertEquals(lines[82], 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/ulvawop_convo.lua")', "space_conversations.lua line 82 uncommented by crimson-phoenix-tier3-ulvawop")
	lu.assertEquals(lines[83], 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/ufwol_convo.lua")', "space_conversations.lua line 83 uncommented by crimson-phoenix-tier4-ufwol")
end

-- AC-1, Content contract 1: the handler include sits uncommented at line 126, after the squadron include; Socuna's stays at 127; the other two stay commented
function TestEkerWiring:test_the_handler_include_is_uncommented_once_at_line_126_and_ulvawop_and_ufwol_stay_commented()
	local text = readFile(H.SCRIPTS .. E.SCREENPLAYS)
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("space/conversations/rebel/crimson_phoenix_squadron/ekerConvoHandler%.lua"%)'), 1, "screenplays.lua: ekerConvoHandler include occurrences (commented or not)")
	lu.assertEquals(lines[124], 'includeFile("space/squadrons/CrimsonPhoenixSquadronScreenplay.lua")', "screenplays.lua line 124 (the squadron include loads first)")
	lu.assertEquals(lines[126], 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/ekerConvoHandler.lua")', "screenplays.lua line 126")
	lu.assertEquals(lines[127], 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/socunaConvoHandler.lua")', "screenplays.lua line 127 (Socuna unchanged)")
	lu.assertEquals(lines[128], 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/ulvawopConvoHandler.lua")', "screenplays.lua line 128 uncommented by crimson-phoenix-tier3-ulvawop")
	lu.assertEquals(lines[129], 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/ufwolConvoHandler.lua")', "screenplays.lua line 129 uncommented by crimson-phoenix-tier4-ufwol")
end

-- AC-1: Part B adds no status key and does not touch the squadron object's flag key
function TestEkerWiring:test_the_squadron_object_keeps_the_eker_pilot_key()
	lu.assertEquals(E.squadron().EKER_PILOT_KEY, "CrimsonPhoenixSquadronScreenplay:ekerPilot", "EKER_PILOT_KEY is untouched")
end

---------------------------------------------------------------------------------------------
-- The helpers (Content contract 3): isOnMission, canFlyNonTrackDuty, tier2Count, getPilotFlag, isReadyForTraining, isTester
---------------------------------------------------------------------------------------------

TestEkerHelpers = {}

function TestEkerHelpers:setUp()
	H.reset()
	E.requireConversation(lu)
end

-- getPilotFlag: the EKER_PILOT_KEY value, or nil when unset or ""
function TestEkerHelpers:test_get_pilot_flag_reads_the_key_and_treats_unset_and_empty_as_nil()
	local h = E.handler()

	for _, flag in ipairs({ "1", "2", "3" }) do
		lu.assertEquals(h:getPilotFlag(E.pilot({ graduated = flag })), flag, "flag " .. flag)
	end

	lu.assertNil(h:getPilotFlag(E.pilot({ graduated = false })), "unset")

	local blank = E.pilot({ graduated = "1" })

	H.setQuestStatus(blank, E.EKER_PILOT_KEY, "")
	lu.assertNil(h:getPilotFlag(blank), "empty string")
end

-- tier2Count: the number of tier 2 skills held
function TestEkerHelpers:test_tier2_count_counts_the_tier_2_skills()
	for n = 0, 4 do
		lu.assertEquals(E.handler():tier2Count(E.pilot({ t2 = n })), n, n .. " tier 2 skills")
	end
end

-- isOnMission: any of the four heads (or a chain member), or any of the three duties, active in the journal
function TestEkerHelpers:test_is_on_mission_is_true_for_every_eker_chain_member_and_duty()
	local h = E.handler()

	for _, global in ipairs(E.GLOBALS) do
		lu.assertTrue(truthy(h:isOnMission(E.pilot({ active = global }))), global .. " active")
	end

	lu.assertFalse(truthy(h:isOnMission(E.pilot())), "nothing active")
	lu.assertFalse(truthy(h:isOnMission(E.pilot({ missions = 2, t2 = 2 }))), "completed missions only")
end

-- isOnMission: another squadron's quest is not Eker's mission
function TestEkerHelpers:test_is_on_mission_ignores_other_quests()
	local player = E.pilot()

	player.ghost.journalActive[H.questCrc("patrol", "tatooine_rebel_1")] = true
	lu.assertFalse(truthy(E.handler():isOnMission(player)), "a tier 1 quest active")
end

-- canFlyNonTrackDuty: tier 1 complete, not on an Eker mission, no space quest at all
function TestEkerHelpers:test_can_fly_non_track_duty_needs_tier_1_done_and_no_quest()
	local h = E.handler()

	lu.assertTrue(truthy(h:canFlyNonTrackDuty(E.pilot({ squadron = HAVOC_SQUADRON }))), "tier 1 done, nothing flying")
	lu.assertFalse(truthy(h:canFlyNonTrackDuty(E.pilot({ squadron = HAVOC_SQUADRON, t1 = 3 }))), "three _01 skills")
	lu.assertFalse(truthy(h:canFlyNonTrackDuty(E.pilot({ squadron = HAVOC_SQUADRON, t1 = 0 }))), "no _01 skill")
	lu.assertFalse(truthy(h:canFlyNonTrackDuty(E.pilot({ squadron = HAVOC_SQUADRON, datapad = "story" }))), "a story mission in the datapad")
	lu.assertFalse(truthy(h:canFlyNonTrackDuty(E.pilot({ squadron = HAVOC_SQUADRON, datapad = "duty" }))), "a duty mission in the datapad")
	lu.assertFalse(truthy(h:canFlyNonTrackDuty(E.pilot({ squadron = HAVOC_SQUADRON, active = E.DUTY9 }))), "an Eker duty active")
end

-- isReadyForTraining (Q-4 = A): flag set, tier 1 done, tier 2 not done, 60,000 XP
function TestEkerHelpers:test_is_ready_for_training_needs_the_flag_tier_1_done_tier_2_open_and_60000_experience()
	local h = E.handler()

	for _, flag in ipairs({ "1", "2", "3" }) do
		lu.assertTrue(truthy(h:isReadyForTraining(E.pilot({ graduated = flag, xp = E.XP_COST }))), "flag " .. flag .. ", 60,000 XP")
	end

	lu.assertTrue(truthy(h:isReadyForTraining(E.pilot({ t2 = 3, xp = E.XP_COST }))), "three _02 skills")
	lu.assertFalse(truthy(h:isReadyForTraining(E.pilot({ xp = E.XP_COST - 1 }))), "59,999 XP")
	lu.assertFalse(truthy(h:isReadyForTraining(E.pilot({ graduated = false, xp = E.XP_COST }))), "no flag (the intended form of canBuySkill)")
	lu.assertFalse(truthy(h:isReadyForTraining(E.pilot({ t1 = 3, xp = E.XP_COST }))), "tier 1 incomplete")
	lu.assertFalse(truthy(h:isReadyForTraining(E.pilot({ t2 = 4, xp = E.XP_COST }))), "tier 2 complete: no menu without topics")
end

-- isTester (D-5): the ghost's privileged flag; no ghost, no tester
function TestEkerHelpers:test_is_tester_follows_the_privileged_flag()
	local h = E.handler()

	lu.assertTrue(truthy(h:isTester(E.pilot({ privileged = true }))), "privileged pilot")
	lu.assertFalse(truthy(h:isTester(E.pilot())), "ordinary pilot")

	local noGhost = E.pilot({ privileged = true })

	noGhost.ghost = nil
	lu.assertFalse(truthy(h:isTester(noGhost)), "a player without a player object")
end
