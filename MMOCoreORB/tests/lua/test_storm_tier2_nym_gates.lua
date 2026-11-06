-- Storm tier 2, the Nym technicians: which screen each technician opens on (Conversation flow 1), the ambient talk of everyone else (Q-1 = A)
-- and the side-effect-free gate (I-3).
-- Spec: .claude/work/storm-tier2-nym-technicians/01-spec.md (AC-4; Conversation flow 1; I-3, I-6; Q-1 = A).

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local T = require("storm_tier2_data")
local N = require("storm_tier2_nym_data")

N.load()

local function setUp()
	H.reset()
	N.load()
end

---------------------------------------------------------------------------------------------
-- Conversation flow 1: the gate table
---------------------------------------------------------------------------------------------

TestStormNymGates = {}

TestStormNymGates.setUp = setUp

-- n -> stage -> first screen
local GATES = {
	[1] = { none = "greeting", briefed = "greeting_agent", tipped = "back_again", active = "back_again", failed = "back_again", won = "back_again", paid = "greeting" },
	[2] = { none = "greeting", briefed = "greeting_agent", tipped = "greeting_agent", active = "greeting_agent", failed = "greeting_agent", won = "greeting_agent", paid = "greeting" },
	[3] = { none = "greeting", briefed = "greeting_agent", tipped = "greeting_agent", active = "you_again", failed = "you_again", won = "you_again", paid = "greeting" },
}

for n = 1, 3 do
	for _, stage in ipairs({ "none", "briefed", "tipped", "active", "failed", "won", "paid" }) do
		-- AC-4, AC-5, AC-6, AC-7, AC-8: the gate table
		TestStormNymGates["test_" .. N.CONVOS[n].npcName .. "_opens_on_" .. GATES[n][stage] .. "_at_stage_" .. stage] = function()
			N.requireConversation(lu, n)
			lu.assertEquals(N.firstScreen(n, N.pilot({ stage = stage })), GATES[n][stage], N.CONVOS[n].role .. " at stage " .. stage)
		end
	end
end

-- AC-4: each cause of "none" opens the busy greeting
local NONE_CAUSES = {
	{ name = "jtl_disabled", build = function()
		H.Engine.config.jtlEnabled = false

		return N.pilot({ stage = "briefed" })
	end },
	{ name = "no_ghost", build = function() return N.ghostless(N.pilot({ stage = "briefed" })) end },
	{ name = "a_rebel_pilot", build = function() return N.pilot({ stage = "briefed", pilot = "rebel", faction = "rebel", squadron = HAVOC_SQUADRON }) end },
	{ name = "a_privateer", build = function() return N.pilot({ stage = "briefed", pilot = "neutral", faction = "neutral", squadron = SMUGGLER_SQUADRON }) end },
	{ name = "a_black_epsilon_pilot_with_the_key", build = function() return N.pilot({ stage = "briefed", squadron = BLACK_EPSILON_SQUADRON }) end },
	{ name = "an_inquisition_pilot_with_the_key", build = function() return N.pilot({ stage = "briefed", squadron = INQUISITION_SQUADRON }) end },
	{ name = "a_non_pilot", build = function() return N.pilot({ stage = "briefed", pilot = false, squadron = false }) end },
	{ name = "a_storm_pilot_before_the_briefing", build = function() return N.pilot({ stage = "none" }) end },
	{ name = "a_storm_pilot_after_claw_pay", build = function() return N.pilot({ stage = "paid" }) end },
}

for n = 1, 3 do
	for _, cause in ipairs(NONE_CAUSES) do
		-- AC-4, Q-1 = A
		TestStormNymGates["test_" .. N.CONVOS[n].npcName .. "_opens_on_the_busy_greeting_for_" .. cause.name] = function()
			N.requireConversation(lu, n)

			local t = N.talk(n, cause.build())

			lu.assertEquals(t[1].id, "greeting", N.CONVOS[n].role .. " for " .. cause.name)
			lu.assertEquals(N.optionSids(t[1]), { N.CONVOS[n].ambient.reply }, N.CONVOS[n].role .. ": exactly the one small-talk reply")
			lu.assertEquals(N.linksOf(t[1]), { N.CONVOS[n].ambient.ends }, N.CONVOS[n].role .. ": it leads to the ambient end screen")
		end
	end
end

-- Conversation flow 1: any nil argument gives nil
function TestStormNymGates:test_getInitialScreen_returns_nil_when_any_argument_is_nil()
	for n = 1, 3 do
		N.requireConversation(lu, n)

		local c = N.CONVOS[n]
		local handler = rawget(_G, c.handler)
		local tmpl = H.conversationTemplate(c.template)
		local player, npc = N.pilot({ stage = "tipped" }), N.npc(n)

		lu.assertNil(handler:getInitialScreen(nil, npc, tmpl), c.handler .. ": nil player")
		lu.assertNil(handler:getInitialScreen(player, nil, tmpl), c.handler .. ": nil npc")
		lu.assertNil(handler:getInitialScreen(player, npc, nil), c.handler .. ": nil template")
	end
end

-- I-3: the gate changes no state, for every stage
function TestStormNymGates:test_getInitialScreen_changes_no_state_for_any_stage()
	for n = 1, 3 do
		N.requireConversation(lu, n)

		local c = N.CONVOS[n]
		local handler = rawget(_G, c.handler)

		for _, stage in ipairs({ "none", "briefed", "tipped", "active", "failed", "won", "paid" }) do
			H.reset()

			local player, npc = N.pilot({ stage = stage }), N.npc(n)
			local tmpl = H.conversationTemplate(c.template)
			local before = N.snapshot(player)
			local screen = handler:getInitialScreen(player, npc, tmpl)

			lu.assertNotNil(screen, c.handler .. " at stage " .. stage .. ": a screen")
			lu.assertEquals(screen.id, GATES[n][stage], c.handler .. " at stage " .. stage)
			lu.assertEquals(N.snapshot(player), before, c.handler .. " at stage " .. stage .. ": state after getInitialScreen")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: the ambient talk
---------------------------------------------------------------------------------------------

TestStormNymAmbient = {}

TestStormNymAmbient.setUp = setUp

for n = 1, 3 do
	local c = N.CONVOS[n]

	for _, cause in ipairs(NONE_CAUSES) do
		-- AC-4: the walk ends on the ambient end screen with no state change
		TestStormNymAmbient["test_" .. c.npcName .. "_small_talk_with_" .. cause.name .. "_ends_with_no_state_change"] = function()
			N.requireConversation(lu, n)

			local player = cause.build()
			local starts = {}

			for _, g in ipairs(T.GLOBALS) do
				starts[g] = H.spyOn(T.quest(g), "startQuest")
			end

			local before = N.snapshot(player)
			local t = N.talk(n, player, { c.ambient.reply })

			lu.assertEquals(N.ids(t), { "greeting", c.ambient.ends }, c.role .. ": screens shown")
			lu.assertTrue(t[2].stop, c.role .. ": " .. c.ambient.ends .. " ends the talk")
			lu.assertEquals(#t[2].options, 0, c.role .. ": " .. c.ambient.ends .. " has no options")
			lu.assertEquals(N.snapshot(player), before, c.role .. ": state after the talk")

			for _, g in ipairs(T.GLOBALS) do
				lu.assertEquals(#starts[g], 0, g .. " must not start")
			end

			lu.assertEquals(CS.transcriptUnresolved(t), {}, c.role .. ": client strings")
		end
	end

	-- I-6: for a stage-none pilot every reachable screen is in the ambient set (explored with the live handler)
	TestStormNymAmbient["test_" .. c.npcName .. "_shows_only_ambient_screens_to_a_stage_none_pilot"] = function()
		N.requireConversation(lu, n)

		local shown = N.exploreLive(n, function() return N.pilot({ stage = "none" }) end)
		local ids = {}

		for id in pairs(shown) do
			ids[#ids + 1] = id
		end

		table.sort(ids)

		local want = { c.ambient.first, c.ambient.ends }

		table.sort(want)
		lu.assertEquals(ids, want, c.role .. ": screens a stage-none pilot can reach")
	end
end

-- AC-4: the greeting's dialog is the busy line of the matching client file, the same text the briefed pilot sees on greeting_agent
function TestStormNymAmbient:test_the_busy_greeting_and_the_briefed_greeting_share_the_npc_line()
	local lines = { [1] = "s_ccc723ff", [2] = "s_6aa58622", [3] = "s_76b02ea3" }

	for n = 1, 3 do
		N.requireConversation(lu, n)

		local ambient = N.talk(n, N.pilot({ stage = "none" }))[1]
		local briefed = N.talk(n, N.pilot({ stage = "briefed" }))[1]

		lu.assertEquals(ambient.text, N.CONVOS[n].prefix .. lines[n], N.CONVOS[n].role .. ": greeting")
		lu.assertEquals(briefed.text, N.CONVOS[n].prefix .. lines[n], N.CONVOS[n].role .. ": greeting_agent")
	end
end
