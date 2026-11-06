-- Shared test data and builders for Storm tier 2 part 2 (the Nym fuel technicians on Lok), not a test file.
-- Spec: .claude/work/storm-tier2-nym-technicians/01-spec.md (Content contract, Conversation flow, Appendix A, Invariants).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of agreeing
-- with itself:
--   N.CONVOS[n]       the three conversations: 1 = Morv (nym_fuel_tech), 2 = the decoy (nym_fuel_tech_2), 3 = the Zabrak (nym_fuel_tech_3)
--   N.SCREENS[n]      Appendix A (storm_tier2_nym_screens_data.lua, generated from the spec tables by a scratch script)
--   N.TEXT[file]      the client text of the 76 lines (storm_tier2_nym_client_text.lua, a read-only /tre dump)
--   N.load()          the server's load of the Storm files plus the three templates and handlers, collecting load errors
--   N.pilot{...}      a Storm pilot in the requested Claw stage (see N.pilot)
--   N.talk / N.drive  H.converse from the first screen / from a given screen of conversation n
--   N.snapshot(p)     everything a conversation could change (journal, datapad, keys, credits, items, standing, skills, events)
--
-- The three conversations live in the templates "nym_technician_<n>_convo_template", their handlers are the globals "nymTechnician<n>ConvoHandler".

local H = require("harness")
local T = require("storm_tier2_data")
local M = require("migration_scenario")

local N = {}

N.TEXT = require("storm_tier2_nym_client_text")
N.SCREENS = require("storm_tier2_nym_screens_data")

N.TIP_SUFFIX = "StormSquadronScreenplay:spokeToMorv"
N.TIP_KEY_VALUE = "StormSquadronScreenplay:spokeToMorv"

-- Phrases (client sids), the same in all three files
N.CODEPHRASE = "s_67a590c3" -- "I'm here to clean the antimatter condenser."
N.PLASMA = "s_62f865dd" -- "I'm here to scrub the plasma injector."
N.INFUSER = "s_35de4fcc" -- Morv's file: "I'm here to wax the matter infuser."
N.INDUCER = "s_f49a789f" -- the decoy's and the Zabrak's files: "I'm here to wax the matter inducer."

N.CONVOS = {
	[1] = {
		n = 1, role = "Morv", npcName = "nym_fuel_tech", mobileFile = "space/nym_fuel_tech.lua",
		template = "nym_technician_1_convo_template", handler = "nymTechnician1ConvoHandler",
		templateFile = "mobile/conversations/space/imperial/storm_squadron/nym_technician_1_convo.lua",
		templateRel = "conversations/space/imperial/storm_squadron/nym_technician_1_convo.lua",
		handlerFile = "screenplays/space/conversations/imperial/storm_squadron/nymTechnician1ConvoHandler.lua",
		handlerRel = "space/conversations/imperial/storm_squadron/nymTechnician1ConvoHandler.lua",
		stf = "conversation/nym_technician_1", client = "object/mobile/dressed_nym_technician_1.iff", lines = 36, ids = 38,
		ambient = { first = "greeting", reply = "s_ced0fec8", ends = "in_your_way" },
	},
	[2] = {
		n = 2, role = "the decoy", npcName = "nym_fuel_tech_2", mobileFile = "space/nym_fuel_tech_2.lua",
		template = "nym_technician_2_convo_template", handler = "nymTechnician2ConvoHandler",
		templateFile = "mobile/conversations/space/imperial/storm_squadron/nym_technician_2_convo.lua",
		templateRel = "conversations/space/imperial/storm_squadron/nym_technician_2_convo.lua",
		handlerFile = "screenplays/space/conversations/imperial/storm_squadron/nymTechnician2ConvoHandler.lua",
		handlerRel = "space/conversations/imperial/storm_squadron/nymTechnician2ConvoHandler.lua",
		stf = "conversation/nym_technician_2", client = "object/mobile/dressed_nym_technician_2.iff", lines = 14, ids = 16,
		ambient = { first = "greeting", reply = "s_8358e7c8", ends = "sob_story" },
	},
	[3] = {
		n = 3, role = "the Zabrak", npcName = "nym_fuel_tech_3", mobileFile = "space/nym_fuel_tech_3.lua",
		template = "nym_technician_3_convo_template", handler = "nymTechnician3ConvoHandler",
		templateFile = "mobile/conversations/space/imperial/storm_squadron/nym_technician_3_convo.lua",
		templateRel = "conversations/space/imperial/storm_squadron/nym_technician_3_convo.lua",
		handlerFile = "screenplays/space/conversations/imperial/storm_squadron/nymTechnician3ConvoHandler.lua",
		handlerRel = "space/conversations/imperial/storm_squadron/nymTechnician3ConvoHandler.lua",
		stf = "conversation/nym_technician_3", client = "object/mobile/dressed_nym_technician_3.iff", lines = 26, ids = 28,
		ambient = { first = "greeting", reply = "s_88d98675", ends = "pilot_ship" },
	},
}

for n, c in ipairs(N.CONVOS) do
	c.prefix = "@" .. c.stf .. ":"
	c.screens = N.SCREENS[n]
	c.text = N.TEXT["nym_technician_" .. n]
end

-- Appendix A row of conversation n
function N.row(n, id)
	for _, row in ipairs(N.SCREENS[n]) do
		if row.id == id then
			return row
		end
	end

	error("Appendix A." .. n .. " has no row '" .. tostring(id) .. "'", 2)
end

-- Every id (reply or dialog) Appendix A uses for conversation n, plus the replies the handler adds (C-1 .. C-3)
N.CONDITIONAL_REPLIES = {
	[1] = { "s_fdee07ad", "s_7d114e8" },
	[2] = {},
	[3] = { "s_7002e5c4" },
}

-- The stages getClawStage returns
N.STAGES = { "none", "briefed", "tipped", "active", "failed", "won" }

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

N.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		N.loadErrors[#N.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

-- The server's load: the Storm files (T.load), then the three templates and the three handlers. A missing production file is recorded in
-- N.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function N.load()
	T.load()

	if loaded then
		return
	end

	loaded = true

	for _, c in ipairs(N.CONVOS) do
		try(c.templateRel, function() H.loadMobile(c.templateRel) end)
		try(c.handlerRel, function() H.loadScreenplay(c.handlerRel) end)
	end
end

-- The load problems, only those of conversation n when given (the squadron files' problems always)
function N.errors(n)
	local out = {}

	for _, e in ipairs(T.loadErrors) do
		out[#out + 1] = e
	end

	for _, e in ipairs(N.loadErrors) do
		local c = n and N.CONVOS[n]

		if c == nil or e:find(c.templateRel, 1, true) or e:find(c.handlerRel, 1, true) then
			out[#out + 1] = (e:gsub("tests/lua/harness/init.lua:%d+: ", ""))
		end
	end

	return table.concat(out, " | ")
end

-- Fails with the load problems when conversation n's template or handler could not be loaded
function N.requireConversation(lu, n)
	N.load()

	local c = N.CONVOS[n]

	lu.assertNotNil(H.conversationTemplateTable(c.template), c.template .. " is not registered by addConversationTemplate (" .. c.templateFile .. "). Load problems: " .. N.errors(n))
	lu.assertNotNil(rawget(_G, c.handler), c.handler .. " is not defined (" .. c.handlerFile .. "). Load problems: " .. N.errors(n))
end

function N.requireAll(lu)
	for n = 1, 3 do
		N.requireConversation(lu, n)
	end

	N.squadron(lu)
end

-- The squadron object with the three functions of Content contract 1, with a readable red when they are missing
function N.squadron(lu)
	local SS = T.squadron()

	lu.assertEquals(type(SS.getClawStage), "function", "StormSquadronScreenplay:getClawStage (storm-tier2-nym-technicians Content contract 1)")
	lu.assertEquals(type(SS.canStartClaw), "function", "StormSquadronScreenplay:canStartClaw (Content contract 1)")
	lu.assertEquals(type(SS.startClaw), "function", "StormSquadronScreenplay:startClaw (Content contract 1)")

	return SS
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function statusSuffix(n) return T.STATUS[n] end

-- A pilot standing in front of a technician. Options (all optional):
--   stage      one of the stages below (default "briefed"); the rest of the options override what the stage sets
--     none       Oberhaur's missions 1 and 2 paid, one tier 2 skill, NO finding key (before the Morv briefing)
--     briefed    none + the finding key (Oberhaur's m3_codephrase was shown)
--     tipped     briefed + the tip key (Morv's find_zabrak was shown)
--     active     tipped + imperial_ss_3:attempted + the Claw's head active in the journal
--     failed     tipped + imperial_ss_3:attempted, journal entry cleared (a failed run, as Oberhaur's failed[3])
--     won        tipped + attempted + the Claw's journal entry complete, unpaid
--     paid       the Claw paid: :reward set, finding key cleared (what claw_pay leaves), tip key and attempted left as they are
--   tip        true | false: override the tip key
--   attempted  true | false: override imperial_ss_3:attempted
--   plus every T.pilot option: pilot, faction, squadron, finding, datapad ("duty" | "story"), duty (a duty global held active), inShip, zone, standing ...
local STAGES = {
	none = {},
	briefed = { finding = true },
	tipped = { finding = true, tip = true },
	active = { finding = true, tip = true, attempted = true, state = "active" },
	failed = { finding = true, tip = true, attempted = true },
	won = { finding = true, tip = true, attempted = true, state = "won" },
	paid = { tip = true, attempted = true, state = "paid" },
}

function N.pilot(o)
	o = o or {}
	T.load()

	local stage = o.stage or "briefed"
	local preset = STAGES[stage]

	if preset == nil then
		error("unknown stage '" .. tostring(stage) .. "'", 2)
	end

	local opts = { paid = 2, t2 = { 1 } }

	for k, v in pairs(preset) do
		opts[k] = v
	end

	for k, v in pairs(o) do
		if k ~= "stage" and k ~= "tip" and k ~= "attempted" then
			opts[k] = v
		end
	end

	local tip, attempted = opts.tip, opts.attempted

	if o.tip ~= nil then
		tip = o.tip
	end

	if o.attempted ~= nil then
		attempted = o.attempted
	end

	opts.tip, opts.attempted = nil, nil

	local state = opts.state

	if state == "paid" then
		opts.state = nil
		opts.paid = 3
	end

	local player = T.pilot(opts)

	if tip then
		H.setQuestStatus(player, N.TIP_SUFFIX, 1)
	end

	if attempted then
		H.setQuestStatus(player, statusSuffix(3) .. ":attempted", 1)
	end

	return player
end

-- The Claw's journal state: "complete" | "active" | "none"
function N.setClaw(player, state) T.setState(player, T.M3, state) end
function N.claw(player) return T.state(player, T.M3) end

function N.tip(player) return H.getQuestStatus(player, N.TIP_SUFFIX) end
function N.attempted(player) return H.getQuestStatus(player, statusSuffix(3) .. ":attempted") end

-- A player with no ghost (the engine refuses nothing, the stage must be "none")
function N.ghostless(player)
	player.ghost = nil

	return player
end

---------------------------------------------------------------------------------------------
-- Conversations
---------------------------------------------------------------------------------------------

function N.npc(n) return H.newNpc({ name = N.CONVOS[n].npcName }) end

-- Talks to technician n from the first screen. choices as for H.converse.
function N.talk(n, player, choices)
	local c = N.CONVOS[n]

	return H.converse({ template = c.template, player = player, npc = N.npc(n), choices = choices })
end

-- The id of the first screen of a fresh talk
function N.firstScreen(n, player) return N.talk(n, player)[1].id end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or hooks).
-- Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session. Same as T.drive.
function N.drive(n, player, startId, choices)
	local c = N.CONVOS[n]
	local tmpl = H.conversationTemplate(c.template)
	local handler = rawget(_G, c.handler)

	if tmpl == nil or handler == nil then
		error(c.template .. " / " .. c.handler .. " are not loaded. Load problems: " .. N.errors(n), 2)
	end

	local npc = N.npc(n)
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

	if screen == nil then
		error("screen '" .. startId .. "' is not in " .. c.template, 2)
	end

	screen = handler:runScreenHandlers(tmpl, player, npc, 0, screen)

	if screen == nil then
		error("runScreenHandlers returned no screen for '" .. startId .. "'", 2)
	end

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

				if found == nil then
					local have = {}

					for k, o in ipairs(screen.options) do
						have[k] = tostring(o.text)
					end

					error("screen '" .. screen.id .. "' has no option '" .. choice .. "'; options are: " .. table.concat(have, ", "), 2)
				end

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

-- ids of a transcript
function N.ids(transcript) return T.ids(transcript) end

-- the option sids ("s_xxx") of a transcript step, in order
function N.optionSids(step) return T.optionSids(step) end
function N.linksOf(step) return T.linksOf(step) end

-- The reply sids of Appendix A's static options of a row
function N.staticReplies(n, id)
	local out = {}

	for i, o in ipairs(N.row(n, id).options) do
		out[i] = o[1]
	end

	return out
end

-- The last screen of a transcript
function N.last(transcript) return transcript[#transcript] end

---------------------------------------------------------------------------------------------
-- Snapshots
---------------------------------------------------------------------------------------------

local function copyList(list)
	local out = {}

	for i, v in ipairs(list or {}) do
		out[i] = v
	end

	return out
end

local function skillList(player)
	local out = {}

	for skill, held in pairs(player.skills or {}) do
		if held then
			out[#out + 1] = tostring(skill)
		end
	end

	table.sort(out)

	return out
end

-- Everything a conversation could change: the migration snapshot (journal, quest-status store, observers, waypoints, datapad, shared memory), credits,
-- Imperial standing, inventory items, skills, events and messages
function N.snapshot(player)
	local ghost = player.ghost
	local snap

	if ghost == nil then
		-- a pilot built without a ghost: borrow an empty one for the migration snapshot, then put the nil back
		player.ghost = { journalActive = {}, journalComplete = {}, waypoints = {}, factionStanding = {} }
		snap = M.snapshot(player)
		player.ghost = nil
	else
		snap = M.snapshot(player)
	end

	snap.bank = player.bankCredits
	snap.standing = ghost ~= nil and ghost.factionStanding and ghost.factionStanding.imperial or nil
	snap.items = player.inventory ~= nil and copyList(player.inventory.items) or nil
	snap.itemCount = player.inventory ~= nil and #player.inventory.items or 0
	snap.skills = skillList(player)
	snap.events = #H.Engine.callsTo("createEvent")
	snap.awards = #H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill")
	snap.messages = #player.messageLog
	snap.music = #player.music

	return snap
end

-- The keys of the quest-status store that differ between two snapshots (value changed, added or removed)
function N.keyDiff(before, after)
	local out = {}

	for k, v in pairs(after.status) do
		if before.status[k] ~= v then
			out[#out + 1] = k
		end
	end

	for k in pairs(before.status) do
		if after.status[k] == nil then
			out[#out + 1] = k
		end
	end

	table.sort(out)

	return out
end

---------------------------------------------------------------------------------------------
-- Graph walks
---------------------------------------------------------------------------------------------

-- All screens of conversation n reachable from `start` through Appendix A's static options plus the conditional links `extra` (screen id -> list of link ids)
function N.reachable(n, starts, extra)
	local seen, queue = {}, {}

	for _, s in ipairs(starts) do
		seen[s] = true
		queue[#queue + 1] = s
	end

	while #queue > 0 do
		local id = table.remove(queue, 1)
		local row = N.row(n, id)

		for _, o in ipairs(row.options) do
			if not seen[o[2]] then
				seen[o[2]] = true
				queue[#queue + 1] = o[2]
			end
		end

		for _, link in ipairs(extra and extra[id] or {}) do
			if not seen[link] then
				seen[link] = true
				queue[#queue + 1] = link
			end
		end
	end

	return seen
end

-- The conditional links (C-1 .. C-3) of conversation n: screen -> links the handler can add
N.CONDITIONAL_LINKS = {
	[1] = { back_again = { "claw_destroyed", "keep_trying" } },
	[2] = {},
	[3] = { greeting_agent = { "balance_perfect" }, you_again = { "long_gone" } },
}

-- The screens a talk can open on (the gate screens, Conversation flow 1)
N.GATE_SCREENS = {
	[1] = { "greeting", "greeting_agent", "back_again" },
	[2] = { "greeting", "greeting_agent" },
	[3] = { "greeting", "greeting_agent", "you_again" },
}

-- Explores conversation n with the live handler: every screen reachable by choosing each option in turn. `build` makes a fresh pilot per path (a
-- walk can change state). Returns the set of screen ids shown and the list of paths ("a>b>c") for diagnostics.
function N.exploreLive(n, build)
	local shown, paths = {}, {}
	local seenPath = {}

	local function visit(choices)
		local player = build()
		local t = N.talk(n, player, choices)
		local last = t[#t]

		for _, step in ipairs(t) do
			shown[step.id] = true
		end

		local key = table.concat(N.ids(t), ">")

		if seenPath[key] then
			return
		end

		seenPath[key] = true
		paths[#paths + 1] = key

		if last.stop or #last.options == 0 then
			return
		end

		for i = 0, #last.options - 1 do
			local nextChoices = {}

			for k, c in ipairs(choices) do
				nextChoices[k] = c
			end

			nextChoices[#nextChoices + 1] = i

			-- do not explore a screen we already left through every option (the graphs are small and acyclic, the shown set bounds the work)
			if #nextChoices <= 14 then
				visit(nextChoices)
			end
		end
	end

	visit({})

	return shown, paths
end

return N
