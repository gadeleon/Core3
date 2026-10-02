-- Parser for SWG-Source generated conversation scripts (script/conversation/*.java), used as the
-- answer key for dialogue conformance tests.
--
-- The generated code has a fixed shape (tools/conversation editor output):
--
--   string_id message = new string_id(c_stringFile, "<npc sid>");     -- an NPC line
--   doAnimationAction(npc, "<anim>");                                   -- precedes the line
--   <prefix>_action_<name>(player, npc);                                -- precedes the line
--   responses[responseIndex++] = new string_id(c_stringFile, "<sid>"); -- an option, in order
--   utils.setScriptVar(player, "conversation.<x>.branchId", <N>);       -- options' successors live in handleBranch<N>
--   npcEndConversationWithMessage(player, message);                     -- no options: the line ends the conversation
--
-- and successor lines are produced inside `<prefix>_handleBranch<N>` under `response.equals("<sid>")`.
--
-- Swgjava.parse(text) returns:
--   nodes: map npcSid -> { sid, animation (string or ""), actions = {name, ...}, options = {sid, ...}, branch (number or nil),
--          isEnd (bool: no options) }
--   order: list of npc sids in first-appearance order
--   edges: map branch -> map responseSid -> list of successor npc sids (source order; the last one is the
--          unconditional default when the successor is conditional)
--   responses: set of every option sid
--   successorsOf(nodeSid, optionSid) -> list of successor sids (nil if none)
--   pathTo(startSid, targetSid) -> list of option sids leading from start to target (BFS over all
--          successors), or nil

local Swgjava = {}

function Swgjava.parse(text)
	local nodes, order, edges, responses = {}, {}, {}, {}
	local currentFn -- nil (OnStartNpcConversation or elsewhere) or branch number
	local currentResponse
	local pendingAnim, pendingActions = "", {}
	local currentNode -- node whose options are being collected
	local firstSeen = {}

	for line in (text .. "\n"):gmatch("(.-)\r?\n") do
		local fn = line:match("public int [%w_]+_handleBranch(%d+)%(")

		if fn then
			currentFn = tonumber(fn)
			currentResponse = nil
			currentNode = nil
			pendingAnim, pendingActions = "", {}
		elseif line:match("public int [%w_]*OnStartNpcConversation%(") then
			currentFn = nil
			currentResponse = nil
			currentNode = nil
			pendingAnim, pendingActions = "", {}
		end

		local resp = line:match('response%.equals%("([%w_]+)"%)')

		if resp then
			currentResponse = resp
			currentNode = nil
			pendingAnim, pendingActions = "", {}
		end

		local anim = line:match('doAnimationAction%(npc, "([%w_]+)"%)')

		if anim then
			pendingAnim = anim
		end

		local action = line:match("_action_([%w_]+)%(player, npc%)")

		if action then
			pendingActions[#pendingActions + 1] = action
		end

		local sid = line:match('string_id message = new string_id%(c_stringFile, "([%w_]+)"%)')

		if sid then
			if currentFn ~= nil and currentResponse ~= nil then
				edges[currentFn] = edges[currentFn] or {}
				edges[currentFn][currentResponse] = edges[currentFn][currentResponse] or {}

				local list = edges[currentFn][currentResponse]
				local dup = false

				for _, v in ipairs(list) do
					dup = dup or v == sid
				end

				if not dup then
					list[#list + 1] = sid
				end
			end

			if not firstSeen[sid] then
				firstSeen[sid] = true
				nodes[sid] = { sid = sid, animation = pendingAnim, actions = pendingActions, options = {}, isEnd = true, collect = true }
				order[#order + 1] = sid
				currentNode = nodes[sid]
			else
				currentNode = nil -- already known (shared duty menus etc.); do not collect twice
			end

			pendingAnim, pendingActions = "", {}
		end

		local opt = line:match('responses%[responseIndex%+%+%] = new string_id%(c_stringFile, "([%w_]+)"%)')

		if opt then
			responses[opt] = true

			if currentNode ~= nil then
				currentNode.options[#currentNode.options + 1] = opt
				currentNode.isEnd = false
			end
		end

		local branch = line:match('setScriptVar%(player, "conversation%.[%w_]+%.branchId", (%d+)%)')

		if branch and currentNode ~= nil then
			currentNode.branch = tonumber(branch)
		end
	end

	local result = { nodes = nodes, order = order, edges = edges, responses = responses }

	function result.successorsOf(nodeSid, optionSid)
		local node = nodes[nodeSid]

		if node == nil or node.branch == nil then
			return nil
		end

		return edges[node.branch] and edges[node.branch][optionSid]
	end

	function result.pathTo(startSid, targetSid)
		local queue, head = { { sid = startSid, path = {} } }, 1
		local seen = { [startSid] = true }

		while head <= #queue do
			local item = queue[head]
			head = head + 1

			if item.sid == targetSid then
				return item.path
			end

			local node = nodes[item.sid]

			for _, o in ipairs(node and node.options or {}) do
				for _, next in ipairs(result.successorsOf(item.sid, o) or {}) do
					if not seen[next] then
						seen[next] = true

						local path = { table.unpack(item.path) }
						path[#path + 1] = o
						queue[#queue + 1] = { sid = next, path = path }
					end
				end
			end
		end

		return nil
	end

	return result
end

function Swgjava.read(path)
	local f = assert(io.open(path, "r"), "swgjava: cannot open " .. path)
	local text = f:read("a")
	f:close()
	return Swgjava.parse(text)
end

return Swgjava
