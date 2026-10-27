-- Trainer mission rewards match SWG: data and conformance sweep (space-trainer-rewards).
-- Spec: .claude/work/space-trainer-rewards/01-spec.md (I-1 to I-4, AC-1 to AC-4, D-1, D-4, D-5, D-8, D-11).
--
-- SWG: the 12 trainer scripts script/conversation/*.java (fixtures/script/conversation, byte copies). The expected values come from the java
-- fixtures and the spec's R-row table, never from the Core3 tables under test. Reachability of a reward action = at least one
-- `<java>_action_<a>(player, npc);` call site in the java.

local lu = require("luaunit")
local H = require("harness")
local D = require("space_trainer_rewards_data")
local KD = require("space_convo_client_strings_data")
local CS = require("harness.client_strings")

D.load()

local SCRIPTS = "bin/scripts/"

local function sortedKeys(t)
	local out = {}

	for k in pairs(t) do
		out[#out + 1] = k
	end

	table.sort(out)

	return out
end

local function entriesOf(quest)
	local out = {}

	for i, e in ipairs(quest.itemReward or {}) do
		out[i] = { species = e.species, item = e.item }
	end

	return out
end

---------------------------------------------------------------------------------------------
-- I-1: pay site coverage
---------------------------------------------------------------------------------------------

TestTrainerRewardsPaySites = {}

function TestTrainerRewardsPaySites:setUp() H.reset() end

for _, key in ipairs(D.ORDER) do
	local trainer = D.TRAINERS[key]

	-- I-1
	TestTrainerRewardsPaySites["test_" .. key .. "_handler_has_exactly_" .. trainer.count .. "_rewardPlayer_calls"] = function()
		local shapes = D.payCallShapes(trainer)

		lu.assertEquals(shapes.total, trainer.count, trainer.handler .. ": occurrences of :rewardPlayer(")

		if trainer.form == "dulios" then
			lu.assertEquals(shapes.dulios, 1, trainer.handler .. ": the _G[MISSION_HEADS[rewardMission]] pay site")
		elseif trainer.form == "questGlobal" then
			lu.assertEquals(shapes.questGlobal, 1, trainer.handler .. ": the self:questGlobal(self.MISSIONS[n].main) pay site")
		end
	end

	-- I-1
	TestTrainerRewardsPaySites["test_" .. key .. "_handler_resolves_to_4_distinct_pay_heads_that_are_quest_tables"] = function()
		local heads = D.heads(trainer)
		local seen = {}

		lu.assertEquals(#heads, 4, trainer.label .. ": resolved pay heads")

		for _, head in ipairs(heads) do
			lu.assertNotNil(head.quest, trainer.label .. ": " .. head.global .. " is a quest table")
			lu.assertEquals(type(head.quest.rewardPlayer), "function", head.global .. ": rewardPlayer")
			lu.assertNil(seen[head.global], trainer.label .. ": " .. head.global .. " is paid at two sites")

			seen[head.global] = true
		end
	end
end

-- I-1
function TestTrainerRewardsPaySites:test_every_trainer_handler_file_is_in_the_map_or_pays_nothing()
	local mapped = {}

	for _, trainer in pairs(D.TRAINERS) do
		mapped[trainer.handler] = true
	end

	local found = 0

	for _, dir in ipairs(D.HANDLER_DIRS) do
		local rc, out = D.shell("ls " .. D.HANDLER_DIR .. dir)

		lu.assertEquals(rc, 0, "ls " .. dir .. ": " .. out)

		for file in out:gmatch("([%w_]+ConvoHandler%.lua)") do
			found = found + 1

			if not mapped[dir .. file] then
				lu.assertNotNil(D.NO_PAY_HANDLERS[file], dir .. file .. ": a trainer handler outside the trainer map")
				lu.assertEquals(D.count(D.readFile(D.HANDLER_DIR .. dir .. file), ":rewardPlayer("), 0, dir .. file .. ": :rewardPlayer( calls")
			end
		end
	end

	lu.assertEquals(found, 13, "ConvoHandler files in the three squadron directories (12 mapped + Vrak)")
end

-- I-1 (spec: the total is 48 = 12 handlers x 4 heads)
function TestTrainerRewardsPaySites:test_the_12_handlers_have_48_heads_in_all()
	local total = 0

	for _, key in ipairs(D.ORDER) do
		total = total + #D.heads(D.TRAINERS[key])
	end

	lu.assertEquals(total, 48, "pay heads over the 12 handlers")
end

---------------------------------------------------------------------------------------------
-- AC-1 and AC-2: the 16 R-rows (spec sweep table) on the Core3 tables
---------------------------------------------------------------------------------------------

TestTrainerRewardsRRows = {}

function TestTrainerRewardsRRows:setUp() H.reset() end

for _, r in ipairs(D.R_ROWS) do
	local id = r.id:gsub("%-", "") -- R-13 .. R-16 are the item-only heads (AC-2), R-1 .. R-12 the core ones (AC-1)

	-- AC-1 / AC-2
	TestTrainerRewardsRRows["test_" .. r.global .. "_pays_" .. r.credits .. "_credits_" .. id] = function()
		local q = H.expectGlobal(r.global, "quest table")

		lu.assertEquals(q.creditReward, r.credits, r.global .. " (" .. r.id .. "): creditReward")
	end

	-- AC-1 / AC-2
	TestTrainerRewardsRRows["test_" .. r.global .. "_has_the_single_swg_item_" .. id] = function()
		local q = H.expectGlobal(r.global, "quest table")

		lu.assertEquals(entriesOf(q), { { species = { -1 }, item = r.item } }, r.global .. " (" .. r.id .. "): itemReward")
	end

	-- AC-1 / AC-2: the spec's literal equals the java fixture at the cited line (guards the test's own table)
	TestTrainerRewardsRRows["test_" .. r.global .. "_row_equals_the_java_fixture_" .. id] = function()
		local trainer = D.TRAINERS[r.trainer]
		local java = D.java(trainer.java)
		local q = H.expectGlobal(r.global, "quest table")
		local found

		for _, g in ipairs(java.rewards) do
			if g.name == q.questName and g.calls > 0 then
				found = g
			end
		end

		lu.assertNotNil(found, r.global .. ": reachable giveReward for " .. tostring(q.questName) .. " in " .. trainer.java .. ".java")
		lu.assertEquals(found.line, r.javaLine, r.id .. ": java line")
		lu.assertEquals({ found.credits, found.item }, { r.credits, r.item }, r.id .. ": credits and item of the java call")
	end
end

-- AC-2: the item-only heads keep their 5000
function TestTrainerRewardsRRows:test_there_are_16_rows_12_core_and_4_item_only()
	lu.assertEquals(#D.R_ROWS, 16, "R-rows")
end

---------------------------------------------------------------------------------------------
-- AC-3: the two-way conformance sweep (I-2, I-3)
---------------------------------------------------------------------------------------------

TestTrainerRewardsConformance = {}

function TestTrainerRewardsConformance:setUp() H.reset() end

local sweepNow

local function sweep()
	if sweepNow == nil then
		sweepNow = D.sweep()
	end

	return sweepNow
end

for _, key in ipairs(D.ORDER) do
	local trainer = D.TRAINERS[key]

	for _, head in ipairs(D.heads(trainer)) do
		-- AC-3 (I-2)
		TestTrainerRewardsConformance["test_" .. key .. "_" .. head.global .. "_pays_what_swg_gives"] = function()
			local failures = sweep().failures[head.global]

			lu.assertNil(failures, key .. " " .. head.global .. ": " .. table.concat(failures or {}, " | "))
		end
	end
end

-- AC-3 (I-2): all 48 heads were swept and nothing was left unresolved
function TestTrainerRewardsConformance:test_the_sweep_covers_48_heads_without_unresolved_ones()
	lu.assertEquals(#sweep().heads, 48, "swept heads")
	lu.assertEquals(sweep().problems, {}, "unresolved heads")
end

-- AC-3 (I-3): every reachable giveReward quest name of the 12 java fixtures is matched by exactly one head
function TestTrainerRewardsConformance:test_every_reachable_swg_giveReward_is_matched_by_exactly_one_head()
	local total = 0

	for _, key in ipairs(D.ORDER) do
		local trainer = D.TRAINERS[key]
		local byName, order = D.reachableByName(D.java(trainer.java))

		for _, name in ipairs(order) do
			total = total + 1

			lu.assertEquals(sweep().matched[key .. "|" .. name], 1, key .. ": heads for the reachable SWG reward " .. name .. " (" .. trainer.java .. ".java)")
		end

		lu.assertEquals(#order, 4, trainer.java .. ".java: reachable reward quest names")
	end

	lu.assertEquals(total, 48, "reachable SWG reward quest names over the 12 java fixtures")
end

-- AC-3 (I-3): the four never-called reward actions are the only unreachable ones, each with 0 call sites
function TestTrainerRewardsConformance:test_exactly_the_four_named_swg_reward_actions_have_no_call_site()
	local seen = {}

	for _, key in ipairs(D.ORDER) do
		local java = D.java(D.TRAINERS[key].java)

		for _, r in ipairs(java.rewards) do
			if r.calls == 0 then
				lu.assertEquals(D.UNREACHABLE[r.name], D.TRAINERS[key].java, "unexpected unreachable giveReward " .. r.name .. " in " .. D.TRAINERS[key].java .. ".java:" .. r.line)
				lu.assertEquals(java.calls[r.action] or 0, 0, r.name .. ": call sites of " .. r.action)

				seen[#seen + 1] = r.name
			end
		end
	end

	table.sort(seen)
	lu.assertEquals(seen, sortedKeys(D.UNREACHABLE), "unreachable SWG rewards")
end

-- AC-3 (D-5): Rikkh M4's action is spelled with a lowercase f, so the call-site match is by exact name
function TestTrainerRewardsConformance:test_rikkh_m4_swg_action_is_found_by_its_exact_spelling()
	local java = D.java("corellia_privateer_trainer_2")

	lu.assertTrue((java.calls["rewardforMissionFourAssassinate"] or 0) >= 1, "call sites of rewardforMissionFourAssassinate")
end

-- AC-3 (D-11): the one named exception is used exactly once
function TestTrainerRewardsConformance:test_the_kreezo_m3_bodysuit_is_the_only_exception_and_is_used_once()
	lu.assertEquals(sweep().exceptions, 1, "uses of the D-11 substitution")

	local q = H.expectGlobal("patrol_corellia_rebel_3", "Kreezo M3")
	local items = {}

	for _, e in ipairs(q.itemReward) do
		items[#items + 1] = e.item
	end

	lu.assertTrue(table.concat(items, " "):find(D.EXCEPTION.core3, 1, true) ~= nil, "Kreezo M3 keeps " .. D.EXCEPTION.core3 .. " (" .. D.EXCEPTION.reason .. ")")
	lu.assertNil(table.concat(items, " "):find(D.EXCEPTION.swg, 1, true), "Kreezo M3 does not name the NGE-only template")
end

-- AC-3 (data mapping): the species-branched tier 1 M3 heads list their specific species first and {-1} last
for _, global in ipairs({ "patrol_corellia_privateer_3", "patrol_naboo_privateer_3", "patrol_corellia_rebel_3" }) do
	-- AC-3, AC-7
	TestTrainerRewardsConformance["test_" .. global .. "_lists_specific_species_first_and_minus_one_last"] = function()
		local entries = H.expectGlobal(global, "quest table").itemReward

		lu.assertTrue(#entries >= 2, global .. ": entries")

		for i, e in ipairs(entries) do
			if i < #entries then
				lu.assertEquals(#e.species, 1, global .. ": entry " .. i .. " species count")
				lu.assertNotEquals(e.species[1], -1, global .. ": entry " .. i .. " is species specific")
			else
				lu.assertEquals(e.species, { -1 }, global .. ": last entry")
			end
		end
	end
end

-- AC-3: reverting any one R-row's creditReward or itemReward makes I-2 fail and name that global
for _, r in ipairs(D.R_ROWS) do
	-- AC-3
	TestTrainerRewardsConformance["test_reverting_the_credit_of_" .. r.global .. "_fails_the_sweep_naming_it"] = function()
		local q = H.expectGlobal(r.global, "quest table")
		local saved = rawget(q, "creditReward")

		lu.assertNil(sweep().failures[r.global], r.global .. ": conforms before the revert (a revert of data that already differs proves nothing)")

		q.creditReward = 0

		local ok, result = pcall(D.sweep)

		q.creditReward = saved
		assert(ok, result)

		lu.assertNotNil(result.failures[r.global], r.global .. ": a zero creditReward is reported by the sweep")
	end

	-- AC-3
	TestTrainerRewardsConformance["test_reverting_the_item_of_" .. r.global .. "_fails_the_sweep_naming_it"] = function()
		local q = H.expectGlobal(r.global, "quest table")
		local saved = rawget(q, "itemReward")

		lu.assertNil(sweep().failures[r.global], r.global .. ": conforms before the revert (a revert of data that already differs proves nothing)")

		q.itemReward = {}

		local ok, result = pcall(D.sweep)

		q.itemReward = saved
		assert(ok, result)

		lu.assertNotNil(result.failures[r.global], r.global .. ": an empty itemReward is reported by the sweep")
	end
end

-- AC-3: on the data of 1d980a2452 the sweep fails on exactly the 16 R-row globals
function TestTrainerRewardsConformance:test_on_the_base_commit_data_the_sweep_fails_on_exactly_the_16_r_row_globals()
	local lookup, why = D.baseLookup()

	if lookup == nil then
		lu.skip("git show " .. D.BASE_COMMIT .. " is unavailable: " .. tostring(why))
	end

	local result = D.sweep(lookup)
	local failed = sortedKeys(result.failures)
	local expected = {}

	for _, r in ipairs(D.R_ROWS) do
		expected[#expected + 1] = r.global
	end

	table.sort(expected)

	lu.assertEquals(failed, expected, "heads failing I-2 on " .. D.BASE_COMMIT)
end

---------------------------------------------------------------------------------------------
-- AC-4: item resolution (I-4) and the space_item string fixture
---------------------------------------------------------------------------------------------

TestTrainerRewardsItems = {}

function TestTrainerRewardsItems:setUp() H.reset() end

local function isComponent(item) return item:find("^object/tangible/ship/components/") ~= nil end

-- every distinct item a head pays plus every ship component any of the 12 java fixtures names, in sorted order
local function allItems()
	local set = {}

	for _, key in ipairs(D.ORDER) do
		local trainer = D.TRAINERS[key]

		for _, head in ipairs(D.heads(trainer)) do
			for _, e in ipairs((head.quest and head.quest.itemReward) or {}) do
				set[e.item] = true
			end
		end

		for _, r in ipairs(D.java(trainer.java).rewards) do
			if r.item and isComponent(r.item) then
				set[r.item] = true
			end
		end
	end

	return sortedKeys(set)
end

local ITEMS = allItems()

local SIDS = CS.sids("space/space_item")

local function dirAndFile(item)
	local dir, file = item:match("^object/(.+)/([%w_]+)%.iff$")

	return dir, file
end

for _, item in ipairs(ITEMS) do
	local dir, file = dirAndFile(item)

	-- AC-4 (I-4)
	TestTrainerRewardsItems["test_" .. file .. "_has_a_server_template_with_its_path"] = function()
		local text = D.readFile(SCRIPTS .. "object/" .. dir .. "/" .. file .. ".lua")

		lu.assertNotNil(text, item .. ": bin/scripts/object/" .. dir .. "/" .. file .. ".lua")
		lu.assertNotNil(text:find('ObjectTemplates:addTemplate(', 1, true), item .. ": addTemplate call")
		lu.assertNotNil(text:find('"' .. item .. '")', 1, true), item .. ": addTemplate path")
	end

	-- AC-4 (I-4)
	TestTrainerRewardsItems["test_" .. file .. "_is_included_exactly_once_by_serverobjects"] = function()
		local text = D.readFile(SCRIPTS .. "object/" .. dir .. "/serverobjects.lua")

		lu.assertNotNil(text, "serverobjects.lua of " .. dir)
		lu.assertEquals(D.count(text, 'includeFile("' .. dir .. "/" .. file .. '.lua")'), 1, item .. ": includeFile count in " .. dir .. "/serverobjects.lua")
	end

	-- AC-4 (I-4)
	TestTrainerRewardsItems["test_" .. file .. "_has_a_shared_client_template_registered"] = function()
		local text = D.readFile(SCRIPTS .. "object/" .. dir .. "/objects.lua")

		lu.assertNotNil(text, "objects.lua of " .. dir)
		lu.assertEquals(D.count(text, 'addClientTemplate(object_' .. dir:gsub("/", "_") .. "_shared_" .. file .. ', "object/' .. dir .. "/shared_" .. file .. '.iff")'), 1,
			item .. ": addClientTemplate of shared_" .. file .. " in " .. dir .. "/objects.lua")
	end

	if isComponent(item) then
		-- AC-4 (I-4)
		TestTrainerRewardsItems["test_" .. file .. "_names_its_ship_component_data_row"] = function()
			local text = D.readFile(SCRIPTS .. "object/" .. dir .. "/" .. file .. ".lua")

			lu.assertNotNil(text, item .. ": template file")
			lu.assertNotNil(text:find('componentDataName = "' .. file .. '",', 1, true), item .. ": componentDataName")
		end

		-- AC-4 (I-4)
		TestTrainerRewardsItems["test_" .. file .. "_has_its_name_string_in_space_item"] = function()
			lu.assertNotNil(SIDS, "space/space_item.sids fixture")
			lu.assertTrue(SIDS[file .. "_n"] == true, item .. ": " .. file .. "_n in string/en/space/space_item.sids")
		end
	end
end

-- AC-4: 26 ship components are named by the 12 java fixtures
function TestTrainerRewardsItems:test_the_swg_java_fixtures_name_26_distinct_ship_components()
	local set = {}

	for _, key in ipairs(D.ORDER) do
		for _, r in ipairs(D.java(D.TRAINERS[key].java).rewards) do
			if r.item and isComponent(r.item) then
				set[r.item] = true
			end
		end
	end

	lu.assertEquals(#sortedKeys(set), 26, "distinct ship components in the 12 java fixtures")
end

-- AC-4: every item a head pays is one of the checked items (nothing escapes the sweep above)
function TestTrainerRewardsItems:test_every_item_of_the_48_heads_is_in_the_checked_set()
	local checked = {}

	for _, item in ipairs(ITEMS) do
		checked[item] = true
	end

	for _, key in ipairs(D.ORDER) do
		for _, head in ipairs(D.heads(D.TRAINERS[key])) do
			for _, e in ipairs(head.quest.itemReward or {}) do
				lu.assertTrue(checked[e.item] == true, head.global .. ": " .. e.item)
			end
		end
	end
end

-- AC-4
function TestTrainerRewardsItems:test_the_space_item_fixture_exists_with_1127_unique_byte_sorted_lf_ids()
	local path = CS.FIXTURE_DIR .. "space/space_item.sids"
	local text = D.readFile(path)

	lu.assertNotNil(text, "missing fixture " .. path .. " (run tools/gen_client_sids.py space/space_item)")
	lu.assertEquals(D.count(text, "\r"), 0, "space_item.sids: stays LF")
	lu.assertEquals(text:sub(-1), "\n", "space_item.sids: ends with a newline")

	local ids = D.linesOf(text)

	lu.assertEquals(#ids, 1127, "space_item.sids: ids")

	for i = 2, #ids do
		lu.assertTrue(ids[i - 1] < ids[i], "space_item.sids: line " .. i .. " `" .. ids[i] .. "` follows `" .. ids[i - 1] .. "` in byte order without a repeat")
	end
end

-- AC-4: the generator check covers the new fixture
function TestTrainerRewardsItems:test_the_generator_check_passes_on_the_space_item_fixture()
	if not H.fileExists("/tre/patch_12_00.tre") then
		lu.skip("generator check needs /tre/patch_12_00.tre")
	end

	local rc, out = D.shell("command -v python3 >/dev/null")

	if rc ~= 0 then
		lu.skip("python3 is not on PATH")
	end

	rc, out = D.shell("PYTHONDONTWRITEBYTECODE=1 python3 tests/lua/tools/gen_client_sids.py --check space/space_item")

	lu.assertEquals(rc, 0, "gen_client_sids.py --check space/space_item; output: " .. out)
end

-- AC-4: it is a generated fixture no conversation source references, so FIXTURE_COUNTS and KNOWN_GAPS do not move
function TestTrainerRewardsItems:test_the_ratchet_data_is_unchanged()
	lu.assertEquals(#sortedKeys(KD.FIXTURE_COUNTS), 45, "FIXTURE_COUNTS entries") -- 44 since black-epsilon-tier1-hakassha, 45 since black-epsilon-tier2-prisk
	lu.assertNil(KD.FIXTURE_COUNTS["space/space_item"], "space/space_item is outside FIXTURE_COUNTS")
	lu.assertEquals(KD.KNOWN_GAPS, {}, "KNOWN_GAPS")
	lu.assertNotNil(SIDS, "CS.sids(space/space_item)")
end
