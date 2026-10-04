-- Warvog Arkon's off-track duty offer takes SWG's "already has a quest" rule (D-8 of havoc-tier4-arkon-free-choice, D-9 of rsf-gate-screens):
-- any space quest in the datapad refuses it. Modeled on test_rsf_gate_screens_imler.lua.
-- Spec: .claude/work/havoc-tier4-arkon-duty-gate/01-spec.md (AC-1 .. AC-4, invariants I-1 .. I-3).
-- The five TestArkonNonTrackDuty tests (test_havoc_tier4_arkon_behavior.lua) must pass unchanged; this file adds the datapad cases.

local lu = require("luaunit")
local H = require("harness")
local D = require("havoc_tier4_data")
local DR = require("duty_rules_scenario")

local loadErrors = {}

local function tryLoad(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		loadErrors[#loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

tryLoad("HavocSquadronScreenplay", function() H.loadSquadron("HavocSquadronScreenplay") end)
tryLoad("arkon_convo.lua", function() H.loadMobile("conversations/space/rebel/havoc_squadron/arkon_convo.lua") end)
tryLoad("arkonConvoHandler.lua", function() H.loadScreenplay("space/conversations/rebel/havoc_squadron/arkonConvoHandler.lua") end)

local BASE = "f637c689a0" -- space-convo-client-strings-arkon (AC-9, Appendix C): re-based from c52928b270
local AC_PATH = "mobile/conversations/space/rebel/havoc_squadron/arkon_convo.lua"
local AH_PATH = "screenplays/space/conversations/rebel/havoc_squadron/arkonConvoHandler.lua"
local OLD_RETURN = "\treturn SpaceHelpers:hasCompletedPilotTier(pPlayer, \"rebel_navy\", 3) and not self:isOnMission(pPlayer)"
local NEW_RETURN = OLD_RETURN .. " and not SpaceHelpers:hasSpaceQuest(pPlayer)"

local function converse(player, choices)
	lu.assertNotNil(H.conversationTemplateTable("arkon_convo"), "arkon_convo is not registered via addConversationTemplate. Load problems: " .. table.concat(loadErrors, " | "))

	return H.converse({ template = "arkon_convo", player = player, npc = H.newNpc({ name = "Warvog Arkon" }), choices = choices })
end

local function ids(transcript)
	local out = {}

	for i, t in ipairs(transcript) do
		out[i] = t.id
	end

	return out
end

-- Copy of corsecPilot() in test_havoc_tier4_arkon_behavior.lua: a rebel tier 3 graduate of another squadron, empty datapad
local function corsecPilot()
	local skills = {}

	for _, s in ipairs(D.SKILLS) do
		for tier = 1, 3 do
			skills[#skills + 1] = "pilot_rebel_navy_" .. s .. "_0" .. tier
		end
	end

	return H.newPlayer({ pilot = "rebel", squadronType = rawget(_G, "CORSEC_SQUADRON"), skills = skills, pilotTier = 4 })
end

local function spyAllQuests()
	local rec = { starts = {} }

	for _, name in ipairs(H.questGlobals()) do
		H.spyOn(rawget(_G, name), "startQuest", function() rec.starts[#rec.starts + 1] = name end)
	end

	return rec
end

local function readFile(rel)
	local f = assert(io.open(H.SCRIPTS .. rel, "r"), "cannot open " .. rel)
	local text = f:read("a")

	f:close()
	return text
end

local function baseFile(rel)
	local pipe = io.popen("git show " .. BASE .. ":MMOCoreORB/bin/scripts/" .. rel .. " 2>&1")
	local text = pipe:read("a")

	pipe:close()
	lu.assertTrue(#text > 500 and text:find("^fatal") == nil, "git show " .. BASE .. ":MMOCoreORB/bin/scripts/" .. rel .. " did not return the file: " .. text:sub(1, 120))

	return text
end

local function code(text)
	local out = {}

	for line in (text .. "\n"):gmatch("(.-)\n") do
		if not line:match("^%s*%-%-") and not line:match("^%s*$") then
			out[#out + 1] = line
		end
	end

	return table.concat(out, "\n")
end

local function replaceOnce(text, a, b, what)
	local s, e = text:find(a, 1, true)

	lu.assertNotNil(s, what .. ": '" .. a .. "' not found")
	lu.assertNil(text:find(a, e + 1, true), what .. ": '" .. a .. "' found more than once")

	return text:sub(1, s - 1) .. b .. text:sub(e + 1)
end

---------------------------------------------------------------------------------------------
-- AC-1, AC-2: the off-track duty offer
---------------------------------------------------------------------------------------------

TestArkonDutyGate = {}

function TestArkonDutyGate:setUp() H.reset() end

local HOLDS = {
	{ "a_held_duty", function(p) DR.holdDuty(p) end },
	{ "a_held_story_mission", function(p) DR.holdStory(p) end },
	{ "a_held_duty_of_another_squadron", function(p) DR.holdDuty(p, "corellia_privateer_6") end },
	{ "a_held_story_mission_of_another_squadron", function(p) DR.holdStory(p, "corellia_privateer_1") end },
}

for _, hold in ipairs(HOLDS) do
	-- AC-1
	TestArkonDutyGate["test_an_off_track_tier_3_graduate_with_" .. hold[1] .. "_gets_not_my_track_then_nontrack_no_duty"] = function()
		local rec = spyAllQuests()
		local player = corsecPilot()

		hold[2](player)

		local transcript = converse(player, { "s_6222b64d" })

		lu.assertEquals(ids(transcript), { "not_my_track", "nontrack_no_duty" }, hold[1] .. ": transcript")
		lu.assertTrue(transcript[2].stop, hold[1] .. ": nontrack_no_duty ends the conversation")
		lu.assertEquals(rec.starts, {}, hold[1] .. ": quests started")
	end
end

-- AC-2 (regression): nothing in the datapad, the offer stays
function TestArkonDutyGate:test_an_off_track_tier_3_graduate_with_an_empty_datapad_still_gets_nontrack_duty()
	local transcript = converse(corsecPilot(), { "s_6222b64d" })

	lu.assertEquals(ids(transcript), { "not_my_track", "nontrack_duty" })
end

-- AC-2
function TestArkonDutyGate:test_can_fly_non_track_duty_is_false_with_a_datapad_quest_and_true_without()
	local handler = H.expectGlobal("arkonConvoHandler", "Arkon conversation handler")
	local free = corsecPilot()
	local held = corsecPilot()

	DR.holdStory(held)

	lu.assertTrue(handler:canFlyNonTrackDuty(free), "no quest")
	lu.assertFalse(handler:canFlyNonTrackDuty(held), "a story mission in the datapad")
end

---------------------------------------------------------------------------------------------
-- AC-3: on-track pilots are unaffected
---------------------------------------------------------------------------------------------

-- AC-3
function TestArkonDutyGate:test_a_havoc_pilot_holding_a_story_mission_still_gets_mission1_offer()
	local player = D.havoc({ tier4 = { D.SKILLS[1] }, rewards = {}, attempted = {}, completed = {} })

	DR.holdStory(player)

	lu.assertEquals(converse(player)[1].id, "mission1_offer")
end

-- AC-3, I-2: one call site, inside the not_my_track branch
function TestArkonDutyGate:test_can_fly_non_track_duty_is_called_only_inside_the_not_my_track_branch()
	local text = readFile(AH_PATH)
	local calls, pos = {}, 1

	while true do
		local s = text:find(":canFlyNonTrackDuty(", pos, true)

		if not s then break end

		calls[#calls + 1] = s
		pos = s + 1
	end

	local def = text:find("function arkonConvoHandler:canFlyNonTrackDuty(", 1, true)

	lu.assertNotNil(def, "definition of canFlyNonTrackDuty")

	local outside = {}

	for _, s in ipairs(calls) do
		if s ~= def + #"function arkonConvoHandler" then
			outside[#outside + 1] = s
		end
	end

	lu.assertEquals(#outside, 1, "call sites of :canFlyNonTrackDuty( outside the definition")

	local from = text:find('screenID == "not_my_track"', 1, true)

	lu.assertNotNil(from, 'branch screenID == "not_my_track"')

	local to = text:find("elseif (screenID ==", from, true)

	lu.assertNotNil(to, "next elseif after the not_my_track branch")
	lu.assertTrue(outside[1] > from and outside[1] < to, "the call site lies inside the not_my_track branch")
end

---------------------------------------------------------------------------------------------
-- AC-4, I-3: nothing this feature owns moves. Re-based from c52928b270 to f637c689a0 by space-convo-client-strings-arkon (Appendix C): the template and the
-- handler changed since (client strings, one-click training); what the duty gate owns is the canFlyNonTrackDuty function and the not_my_track / nontrack_* screens.
-- The rest of both files is pinned by test_space_convo_client_strings_arkon.lua (AC-7).
---------------------------------------------------------------------------------------------

TestArkonDutyGateNothingElseMoves = {}

function TestArkonDutyGateNothingElseMoves:setUp() H.reset() end

-- the addScreen block of `id` (from its `arkon_convo:addScreen(` line to the closing `})` line)
local function screenBlock(text, id, what)
	local at = text:find('id = "' .. id .. '"', 1, true)

	lu.assertNotNil(at, what .. ": screen " .. id)

	local s = at

	while s > 1 and text:sub(s, s + #"arkon_convo:addScreen(" - 1) ~= "arkon_convo:addScreen(" do
		s = s - 1
	end

	local e = text:find("\n})\n", at, true)

	lu.assertNotNil(e, what .. ": end of screen " .. id)

	return text:sub(s, e + 3)
end

-- AC-4 (re-based by space-convo-client-strings-arkon)
function TestArkonDutyGateNothingElseMoves:test_the_not_my_track_and_nontrack_screens_are_byte_identical_to_commit_f637c689a0()
	local now, base = readFile(AC_PATH), baseFile(AC_PATH)

	for _, id in ipairs({ "not_my_track", "nontrack_duty", "nontrack_no_duty" }) do
		lu.assertTrue(screenBlock(now, id, "now") == screenBlock(base, id, BASE), "screen " .. id .. " differs from " .. BASE)
	end
end

-- AC-4, I-3 (re-based by space-convo-client-strings-arkon)
function TestArkonDutyGateNothingElseMoves:test_can_fly_non_track_duty_is_byte_identical_to_commit_f637c689a0_and_keeps_the_datapad_clause()
	local function block(text, what)
		local s = text:find("function arkonConvoHandler:canFlyNonTrackDuty", 1, true)

		lu.assertNotNil(s, what .. ": canFlyNonTrackDuty")

		local e = text:find("\nend\n", s, true)

		lu.assertNotNil(e, what .. ": end of canFlyNonTrackDuty")

		return text:sub(s, e + 4)
	end

	local now, base = block(readFile(AH_PATH), "now"), block(baseFile(AH_PATH), BASE)

	lu.assertNotNil(base:find(NEW_RETURN, 1, true), "the base function already carries the datapad clause")
	lu.assertTrue(now == base, "canFlyNonTrackDuty differs from " .. BASE)
end
