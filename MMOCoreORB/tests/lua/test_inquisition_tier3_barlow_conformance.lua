-- Lt. Colonel Barlow: the conversation template against the SWG java script, state by state.
-- Spec: .claude/work/inquisition-tier3-barlow/01-spec.md (AC-3, invariant I-3; FB-3, FB-4; D-2, D-9).
--
-- harness/swgjava.lua cannot be the answer key here: it matches only the setScriptVar branch and keeps a line's first instance (D-9). J3B stores the
-- branch with setObjVar(..branchId, N), and one NPC line can lead somewhere else in another branch state (s_c3c8f385, s_3cdbed0b). So this file parses
-- naboo_imperial_tier3_barlow.java itself, per message instance, on the pattern of test_smuggler_transition_template.lua:
--   handleBranch<N>, reply R   ->   instance { line, NPC animation, removeTalktoBarlow?, replies, branch of the replies = M }
--   the replies of an instance at branch M lead to the instances (M, reply)
-- The reachable instances are minimised by partition refinement into states; each state is one screen (82 with the four OnStartNpcConversation lines).
-- TestBarlowOracle needs no production code and is green from the start; it also holds Appendix A to the same check.

local lu = require("luaunit")
local H = require("harness")
local B = require("inquisition_tier3_barlow_data")

B.load()

---------------------------------------------------------------------------------------------
-- The parser
---------------------------------------------------------------------------------------------

local BRANCH = 'conversation%.naboo_imperial_tier3_barlow%.branchId", (%d+)%)'

local function parseJ3B()
	local f = assert(io.open(B.J3B_FILE, "r"), "cannot open " .. B.J3B_FILE)
	local instances, byEdge, starts = {}, {}, {}
	local fn, reply, cur, anim, action
	local no = 0

	for line in f:lines() do
		no = no + 1

		local n = line:match("_handleBranch(%d+)%(obj_id")

		if n ~= nil then
			fn, reply, cur, anim, action = tonumber(n), nil, nil, nil, nil
		elseif line:find("public int OnStartNpcConversation", 1, true) then
			fn, reply, cur, anim, action = "start", nil, nil, nil, nil
		elseif line:find("public int OnNpcConversationResponse", 1, true) then
			fn, cur = nil, nil
		end

		local r = line:match('if %(response%.equals%("(s_[%w]+)"%)%)')

		if r ~= nil and fn ~= nil then
			reply, cur, anim, action = r, nil, nil, nil
		elseif fn ~= nil and line:find("_condition_", 1, true) and line:find("if (", 1, true) then
			anim, action = nil, nil
		end

		local a = line:match('doAnimationAction%(npc, "([%w_]+)"%)')

		if a ~= nil then
			anim = a
		end

		if line:find("_action_removeTalktoBarlow(player, npc);", 1, true) then
			action = true
		end

		local s = line:match('string_id message = new string_id%(c_stringFile, "(s_[%w]+)"%)')

		if s ~= nil and fn ~= nil then
			cur = { fn = fn, reply = reply, line = s, anim = anim or "", action = action == true, replies = {}, java = no }
			instances[#instances + 1] = cur
			anim, action = nil, nil

			if fn == "start" then
				starts[#starts + 1] = cur
			else
				local key = fn .. "|" .. tostring(reply)

				byEdge[key] = byEdge[key] or {}
				byEdge[key][#byEdge[key] + 1] = cur
			end
		end

		local rr = line:match('responses%[responseIndex%+%+%] = new string_id%(c_stringFile, "(s_[%w]+)"%)')

		if rr ~= nil and cur ~= nil then
			cur.replies[#cur.replies + 1] = rr
		end

		local nb = line:match(BRANCH)

		if nb ~= nil and cur ~= nil then
			cur.next = tonumber(nb)
		end
	end

	f:close()

	return { instances = instances, byEdge = byEdge, starts = starts }
end

local J = parseJ3B()

-- the instance an instance's reply i leads to
local function successor(inst, i)
	local list = J.byEdge[tostring(inst.next) .. "|" .. inst.replies[i]]

	return list and list[1]
end

-- Reachable instances from the interview root and their minimised states: { states = { [class] = { inst..., rep = inst } }, classOf = { [inst] = class }, reachable = n }
local function minimise()
	local root = J.starts[2]
	local seen, order = { [root] = true }, { root }
	local head = 1

	while head <= #order do
		local inst = order[head]

		head = head + 1

		for i in ipairs(inst.replies) do
			local nxt = successor(inst, i)

			if nxt ~= nil and not seen[nxt] then
				seen[nxt] = true
				order[#order + 1] = nxt
			end
		end
	end

	local classOf, count = {}, 0
	local ids = {}

	for _, inst in ipairs(order) do
		local sig = table.concat({ inst.line, inst.anim, inst.action and "A" or "-", table.concat(inst.replies, ",") }, "|")

		if ids[sig] == nil then
			count = count + 1
			ids[sig] = count
		end

		classOf[inst] = ids[sig]
	end

	while true do
		local nextIds, nextCount, nextClass = {}, 0, {}

		for _, inst in ipairs(order) do
			local parts = { classOf[inst] }

			for i in ipairs(inst.replies) do
				local nxt = successor(inst, i)

				parts[#parts + 1] = nxt and classOf[nxt] or "?"
			end

			local sig = table.concat(parts, ",")

			if nextIds[sig] == nil then
				nextCount = nextCount + 1
				nextIds[sig] = nextCount
			end

			nextClass[inst] = nextIds[sig]
		end

		local stable = nextCount == count

		classOf, count = nextClass, nextCount

		if stable then
			break
		end
	end

	local states = {}

	for _, inst in ipairs(order) do
		local c = classOf[inst]

		states[c] = states[c] or { rep = inst, count = 0 }
		states[c].count = states[c].count + 1
	end

	return { states = states, classOf = classOf, reachable = #order, count = count }
end

local M = minimise()

---------------------------------------------------------------------------------------------
-- The check: a screens table against the states, by walking both from the four OnStartNpcConversation lines
---------------------------------------------------------------------------------------------

local function sidList(options)
	local out = {}

	for i, o in ipairs(options) do
		out[i] = o[1]
	end

	return out
end

-- screens: { [id] = { dialog = sid, animation = "", stop = bool, options = { { reply sid, link } }, ends = bool (runs removeTalktoBarlow) } }
-- gates: { [screen id] = start instance index (1 restricted, 2 interview, 3 already_spoke, 4 not_requested) }
-- Returns the list of problems (empty = the screens are exactly J3B's states, one to one).
local function conformance(screens, gates)
	local problems = {}
	local stateOf, screenOf = {}, {}
	local queue, head = {}, 1

	local function visit(id, inst, from)
		local s = screens[id]

		if s == nil then
			problems[#problems + 1] = from .. ": links to missing screen '" .. id .. "'"

			return
		end

		local state = inst.gate and ("gate" .. inst.gate) or M.classOf[inst]

		if stateOf[id] ~= nil then
			if stateOf[id] ~= state then
				problems[#problems + 1] = "screen '" .. id .. "' is reached as two different J3B states (via " .. from .. ", " .. inst.line .. ")"
			end

			return
		end

		if screenOf[state] ~= nil and screenOf[state] ~= id then
			problems[#problems + 1] = "J3B state of " .. inst.line .. " (J3B:" .. inst.java .. ") is two screens: '" .. screenOf[state] .. "' and '" .. id .. "'"

			return
		end

		stateOf[id], screenOf[state] = state, id
		queue[#queue + 1] = { id = id, inst = inst }
	end

	for index, inst in ipairs(J.starts) do
		inst.gate = index
	end

	for id, index in pairs(gates) do
		visit(id, J.starts[index], "OnStartNpcConversation")
	end

	while head <= #queue do
		local item = queue[head]
		local id, inst, s = item.id, item.inst, screens[item.id]

		head = head + 1

		if s.dialog ~= inst.line then
			problems[#problems + 1] = "screen '" .. id .. "': dialog " .. tostring(s.dialog) .. ", J3B says " .. inst.line .. " (J3B:" .. inst.java .. ")"
		end

		if (s.animation or "") ~= inst.anim then
			problems[#problems + 1] = "screen '" .. id .. "': NPC animation '" .. tostring(s.animation) .. "', J3B says '" .. inst.anim .. "'"
		end

		if s.stop ~= (#inst.replies == 0) then
			problems[#problems + 1] = "screen '" .. id .. "': stop " .. tostring(s.stop) .. ", J3B has " .. #inst.replies .. " replies"
		end

		if s.ends ~= inst.action then
			problems[#problems + 1] = "screen '" .. id .. "': removeTalktoBarlow on display " .. tostring(s.ends) .. ", J3B " .. tostring(inst.action)
		end

		if table.concat(sidList(s.options), ",") ~= table.concat(inst.replies, ",") then
			problems[#problems + 1] = "screen '" .. id .. "': replies " .. table.concat(sidList(s.options), ",") .. ", J3B has " .. table.concat(inst.replies, ",")
		else
			for i, o in ipairs(s.options) do
				local nxt = successor(inst, i)

				if nxt == nil then
					problems[#problems + 1] = "J3B has no state after reply " .. o[1] .. " of " .. inst.line
				else
					visit(o[2], nxt, id .. " reply " .. o[1])
				end
			end
		end
	end

	local total = 0

	for _ in pairs(screens) do
		total = total + 1
	end

	if #queue ~= total then
		for id in pairs(screens) do
			if stateOf[id] == nil then
				problems[#problems + 1] = "screen '" .. id .. "' is not reachable from OnStartNpcConversation"
			end
		end
	end

	local n = 0

	for _ in pairs(screenOf) do
		n = n + 1
	end

	if n ~= M.count + 3 then
		problems[#problems + 1] = "screens map to " .. n .. " J3B states, J3B has " .. (M.count + 3)
	end

	table.sort(problems)

	return problems
end

local GATES = { restricted = 1, interview = 2, already_spoke = 3, not_requested = 4 }

---------------------------------------------------------------------------------------------
-- The oracle itself (green without production code)
---------------------------------------------------------------------------------------------

TestBarlowOracle = {}

function TestBarlowOracle:setUp() H.reset() end

-- AC-3 (the oracle itself): the fixture is the 5,010-line J3B and the parser finds the four start lines
function TestBarlowOracle:test_the_parser_finds_the_four_start_lines_in_order()
	local lines = {}

	for i, inst in ipairs(J.starts) do
		lines[i] = inst.line
	end

	lu.assertEquals(lines, { "s_127f71ad", "s_a72db7d9", "s_f813490a", "s_4355764f" }, "OnStartNpcConversation lines (restricted, interview, already_spoke, not_requested)")
	lu.assertEquals(J.starts[1].anim, "wave_on_dismissing", "restricted animation")
	lu.assertEquals(J.starts[2].next, 2, "the interview opens branch 2")
	lu.assertEquals(#J.starts[2].replies, 2, "the interview opens with two replies")
end

-- AC-3 (the oracle itself): every reply of every instance has exactly one instance in J3B (no reply has two successors)
function TestBarlowOracle:test_every_reply_has_exactly_one_successor_in_j3b()
	local bad = {}

	for _, inst in ipairs(J.instances) do
		if inst.fn ~= "start" or inst.line == "s_a72db7d9" then
			for i, r in ipairs(inst.replies) do
				local list = J.byEdge[tostring(inst.next) .. "|" .. r]

				if list == nil or #list ~= 1 then
					bad[#bad + 1] = inst.line .. " (J3B:" .. inst.java .. ") reply " .. r .. ": " .. (list and #list or 0) .. " successors"
				end
			end
		end
	end

	lu.assertEquals(bad, {}, "replies without exactly one successor")
end

-- AC-3 (the oracle itself): 82 states (79 interview states and the 3 chat gates), seven dead instances (FB-3, FB-4)
function TestBarlowOracle:test_j3b_has_79_interview_states_and_seven_dead_instances()
	lu.assertEquals(M.count, 79, "reachable interview states after partition refinement")

	local dead = 0

	for _, inst in ipairs(J.instances) do
		if inst.fn ~= "start" and M.classOf[inst] == nil then
			dead = dead + 1
		end
	end

	lu.assertEquals(dead, 7, "instances in branches nobody reaches (FB-4)")
	lu.assertEquals(M.reachable + 3 + dead, #J.instances, "reachable + the three chat gates + dead = all message instances")
end

-- AC-3 (the oracle itself): the FB-3 splits
function TestBarlowOracle:test_the_silence_and_wrist_device_lines_have_the_states_the_spec_names()
	local silence, wrist = {}, {}

	for class, state in pairs(M.states) do
		if state.rep.line == "s_c3c8f385" then
			silence[#silence + 1] = state.rep.replies[1] .. ">" .. successor(state.rep, 1).line
		elseif state.rep.line == "s_3cdbed0b" then
			wrist[#wrist + 1] = state.rep.anim
		end
	end

	table.sort(silence)
	table.sort(wrist)
	lu.assertEquals(silence, { "s_d5ad0fe2>s_22cf270c", "s_d5ad0fe2>s_6bd0e9b", "s_d5ad0fe2>s_bf9b99b9" }, "the three [silence] states and what each leads to")
	lu.assertEquals(wrist, { "", "check_wrist_device" }, "s_3cdbed0b: no NPC animation on branch 19 (the player's is dropped), check_wrist_device on 41/43")
end

-- AC-3 (the oracle itself): the five removeTalktoBarlow lines
function TestBarlowOracle:test_five_lines_run_remove_talk_to_barlow()
	local lines = {}

	for _, state in pairs(M.states) do
		if state.rep.action then
			lines[#lines + 1] = state.rep.line
		end
	end

	table.sort(lines)
	lu.assertEquals(lines, { "s_2b71207d", "s_3be36a24", "s_4ccd5b75", "s_65ec117a", "s_7ebbd888" }, "interview states that clear the question key")
end

local function appendixScreens()
	local screens = {}

	for _, row in ipairs(B.SCREENS) do
		local options = {}

		for i, o in ipairs(row.options) do
			options[i] = { o[1], o[2] }
		end

		screens[row.id] = { dialog = row.sid, animation = row.animation, stop = row.stop, options = options, ends = row.notes:find("H", 1, true) == 1 }
	end

	return screens
end

-- AC-3 (the oracle itself): Appendix A is J3B's state graph, one to one
function TestBarlowOracle:test_appendix_a_is_the_j3b_state_graph_one_to_one()
	lu.assertEquals(#B.SCREENS, 82, "Appendix A rows")
	lu.assertEquals(conformance(appendixScreens(), GATES), {}, "Appendix A against J3B")
end

-- AC-3 (the oracle itself): the check is not vacuous (a mislinked screen and a dropped split are caught)
function TestBarlowOracle:test_the_check_catches_a_mislinked_and_a_merged_screen()
	local screens = appendixScreens()

	screens.interview_c3c8f385_b.options[1][2] = "interview_22cf270c"

	local problems = conformance(screens, GATES)

	lu.assertTrue(#problems > 0, "a mislinked [silence] screen must be reported")

	screens = appendixScreens()
	screens.interview_45d046d5.options[2][2] = "interview_c3c8f385"
	problems = conformance(screens, GATES)
	lu.assertTrue(#problems > 0, "two replies leading to the same [silence] screen must be reported")
end

---------------------------------------------------------------------------------------------
-- The template (red until barlow_convo.lua exists)
---------------------------------------------------------------------------------------------

TestBarlowConformance = {}

function TestBarlowConformance:setUp()
	H.reset()
	B.requireConversation(lu)
end

local function templateScreens()
	local out = {}
	local handler = rawget(_G, B.HANDLER)
	local ends = (handler and handler.END_SCREENS) or {}

	for _, s in ipairs(H.conversationTemplateTable(B.TEMPLATE).screens) do
		local options = {}

		for i, o in ipairs(s.options or {}) do
			options[i] = { (o[1]:gsub("^@conversation/naboo_imperial_tier3_barlow:", "")), o[2] }
		end

		out[s.id] = {
			dialog = (s.leftDialog or ""):gsub("^@conversation/naboo_imperial_tier3_barlow:", ""),
			animation = s.animation or "",
			stop = s.stopConversation == "true",
			options = options,
			ends = ends[s.id] == true,
		}
	end

	return out
end

-- AC-3, I-3: every screen of the template is a J3B state and every J3B state is one screen, with its line, animation, replies, links, end flag and removeTalktoBarlow
function TestBarlowConformance:test_every_screen_is_a_j3b_state_and_every_state_is_one_screen()
	lu.assertEquals(conformance(templateScreens(), GATES), {}, B.TEMPLATE .. " against naboo_imperial_tier3_barlow.java")
end

-- AC-3: the three [silence] screens lead to three different follow-ups
function TestBarlowConformance:test_the_three_silence_screens_link_to_their_three_follow_up_lines()
	local screens = templateScreens()

	lu.assertEquals(screens.interview_c3c8f385 and screens.interview_c3c8f385.options, { { "s_d5ad0fe2", "interview_22cf270c" } }, "interview_c3c8f385")
	lu.assertEquals(screens.interview_c3c8f385_b and screens.interview_c3c8f385_b.options, { { "s_d5ad0fe2", "interview_6bd0e9b" } }, "interview_c3c8f385_b")
	lu.assertEquals(screens.interview_c3c8f385_c and screens.interview_c3c8f385_c.options, { { "s_d5ad0fe2", "interview_bf9b99b9" } }, "interview_c3c8f385_c")
	lu.assertEquals(screens.interview_45d046d5 and screens.interview_45d046d5.options, {
		{ "s_7ef5613c", "interview_c3c8f385" }, { "s_1fa017ef", "interview_c3c8f385_b" }, { "s_fa3924b4", "interview_c3c8f385_c" },
	}, "interview_45d046d5: which reply leads to which [silence] screen")
end

-- AC-3: the player's animation is dropped, the NPC's kept
function TestBarlowConformance:test_the_wrist_device_line_has_no_animation_on_branch_19_and_one_on_branches_41_43()
	local screens = templateScreens()

	lu.assertEquals(screens.interview_3cdbed0b and screens.interview_3cdbed0b.animation, "", "interview_3cdbed0b: the animation there is the player's")
	lu.assertEquals(screens.interview_3cdbed0b_b and screens.interview_3cdbed0b_b.animation, "check_wrist_device", "interview_3cdbed0b_b")
end

return nil
