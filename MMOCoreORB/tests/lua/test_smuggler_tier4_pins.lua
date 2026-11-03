-- Smuggler tier 4 (Nirame): nothing else moves (I-13) and the shared edits (surrenderPilot, the two ship cargo strings, Karrde's K9, the delivery and wave hooks).
-- Spec: .claude/work/smuggler-tier4-nirame/01-spec.md (I-13, AC-13; Shared code changes SC-1, SC-2, SC-3; Content contract 4 and 5).
--
-- The base is `git show ca59e4bb24` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the base,
-- and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do. Edited files come from
-- `git diff --diff-filter=M`, new ones from `--diff-filter=A` plus the untracked files.

local lu = require("luaunit")

local BASE = "ca59e4bb24"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local SSP = ROOT .. "screenplays/space/squadrons/SmugglerSquadronScreenplay.lua"
local SDS = ROOT .. "screenplays/space/SpaceDeliveryScreenplay.lua"
local SAW = ROOT .. "screenplays/space/SpaceAttackWaves.lua"
local CONVERSATIONS = ROOT .. "mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = ROOT .. "screenplays/space/screenplays.lua"
local NIRAME = ROOT .. "mobile/space/nirame_sakute.lua"
local SHIP_TIER4 = ROOT .. "ship_mobile/ships/valarian_gunship_inspect_tier4.lua"
local SHIP_PLAIN = ROOT .. "ship_mobile/ships/valarian_gunship_inspect.lua"
local KARRDE_TEMPLATE = ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/talon_karrde_convo.lua"
local KARRDE_HANDLER = ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/talonKarrdeConvoHandler.lua"

local EXPECTED_MODIFIED = {
	KARRDE_TEMPLATE,
	CONVERSATIONS,
	NIRAME,
	SAW,
	SDS,
	KARRDE_HANDLER,
	SCREENPLAYS,
	SSP,
	SHIP_PLAIN,
	SHIP_TIER4,
	SH,
}

local EXPECTED_ADDED = {
	ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/nirame_sakute_convo.lua",
	ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/nirameSakuteConvoHandler.lua",
}

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

-- a repo-root pathspec, valid from any working directory
local function spec(path) return "':/" .. path .. "'" end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- Skips unless git can show the base commit and HEAD is still on it
local function requireBase()
	local rc, out = shell("git cat-file -e " .. BASE .. "^{commit}")

	if rc ~= 0 then
		lu.skip("git cannot show " .. BASE .. ": " .. trim(out))
	end

	local _, head = shell("git rev-parse HEAD")

	if head:sub(1, #BASE) ~= BASE then
		lu.skip("HEAD is not " .. BASE .. " (" .. trim(head) .. "): the pin only applies before the feature is committed")
	end
end

-- Removed and added lines of the working-tree file against the base ({ text... }, { text... }, hunks)
local function changedLines(path)
	local rc, out = shell("git diff -U0 " .. BASE .. " -- " .. spec(path))

	lu.assertEquals(rc, 0, "git diff failed: " .. out)

	local removed, added, hunks = {}, {}, 0

	for line in (out .. "\n"):gmatch("(.-)\n") do
		if line:sub(1, 2) == "@@" then
			hunks = hunks + 1
		elseif hunks > 0 then -- before the first hunk are the file headers (a removed Lua comment line also starts with "---")
			if line:sub(1, 1) == "-" then
				removed[#removed + 1] = line:sub(2)
			elseif line:sub(1, 1) == "+" then
				added[#added + 1] = line:sub(2)
			end
		end
	end

	return removed, added, hunks
end

local function lines(text)
	local out = {}

	for line in text:gmatch("[^\n]+") do
		out[#out + 1] = line
	end

	return out
end

local function trimmed(list)
	local out = {}

	for i, l in ipairs(list) do
		out[i] = trim(l)
	end

	return out
end

local function nonBlank(list)
	local out = {}

	for _, l in ipairs(list) do
		if trim(l) ~= "" then
			out[#out + 1] = trim(l)
		end
	end

	return out
end

local function identical(path)
	local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

	return rc == 0, out
end

local function fileLines(path)
	local f = assert(io.open(path, "r"))
	local all = {}

	for l in f:lines() do
		all[#all + 1] = trim(l)
	end

	f:close()
	return all
end

local function fileText(path)
	local f = assert(io.open(path, "r"))
	local text = f:read("a")

	f:close()
	return text
end

-- the working-tree path of a repo-root path (the tests run in MMOCoreORB/)
local function local_(path) return (path:gsub("^MMOCoreORB/", "")) end

TestSmugglerT4Pins = {}

-- I-13: exactly the eleven edited files under bin/ and src/ (no C++ change) and the two new production files
function TestSmugglerT4Pins:test_only_the_spec_files_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, modified = shell("git diff --diff-filter=M --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, added = shell("git diff --diff-filter=A --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, deleted = shell("git diff --diff-filter=D --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local mod, new = lines(modified), lines(added .. "\n" .. untracked)
	local want = {}

	for i, p in ipairs(EXPECTED_MODIFIED) do
		want[i] = p
	end

	table.sort(want)
	table.sort(mod)
	table.sort(new)
	lu.assertEquals(mod, want, "files under bin/ and src/ edited since " .. BASE)
	lu.assertEquals(new, EXPECTED_ADDED, "files under bin/ and src/ added since " .. BASE)
	lu.assertEquals(lines(deleted), {}, "files under bin/ and src/ deleted since " .. BASE)
end

-- SC-3: space_helpers.lua differs only by the Nirame reset lines, directly after the Beissa reset
function TestSmugglerT4Pins:test_space_helpers_differs_from_the_base_only_in_the_nirame_reset_lines()
	requireBase()

	local removed, added, hunks = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(trimmed(added), { "-- Tier 4", "SmugglerSquadronScreenplay:resetNirameQuests(pPlayer)" }, SH .. ": added lines")
	lu.assertEquals(hunks, 1, SH .. ": one hunk (the Smuggler branch)")

	local all = fileLines(local_(SH))
	local at

	for i, l in ipairs(all) do
		if l == "SmugglerSquadronScreenplay:resetBeissaQuests(pPlayer)" then
			at = i
		end
	end

	lu.assertNotNil(at, SH .. ": the resetBeissaQuests call")
	lu.assertEquals({ all[at + 1], all[at + 2] }, { "-- Tier 4", "SmugglerSquadronScreenplay:resetNirameQuests(pPlayer)" }, SH .. ": the Nirame reset directly after the Beissa reset")
end

-- I-13: SmugglerSquadronScreenplay.lua differs only by additions, apart from the one header sentence
function TestSmugglerT4Pins:test_the_smuggler_squadron_file_only_gains_lines_except_the_header_sentence()
	requireBase()

	local removed, added = changedLines(SSP)

	lu.assertEquals(#removed, 1, SSP .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertNotNil(removed[1]:find("Tier 4 is not ported yet.", 1, true), SSP .. ": the removed line is the header sentence line")

	local joined = table.concat(added, "\n")

	lu.assertNotNil(joined:find("Tier 4 (trainer Nirame Sakute, tatooine_privateer_tier4) is ported by feature smuggler-tier4-nirame.", 1, true), SSP .. ": the new header sentence")
	lu.assertNil(joined:find("Tier 4 is not ported yet.", 1, true), SSP .. ": the old sentence is gone")
end

-- I-13: space_conversations.lua gains the template include line and nothing else
function TestSmugglerT4Pins:test_space_conversations_gains_only_the_nirame_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("conversations/space/neutral/smuggler_squadron/nirame_sakute_convo.lua")' }, CONVERSATIONS .. ": added lines")
end

-- I-13: screenplays.lua gains the handler include and nothing else
function TestSmugglerT4Pins:test_screenplays_gains_only_the_nirame_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/neutral/smuggler_squadron/nirameSakuteConvoHandler.lua")' }, SCREENPLAYS .. ": added lines")
end

-- I-13: nirame_sakute.lua differs only by its two fields
function TestSmugglerT4Pins:test_nirame_differs_from_the_base_only_in_the_conversation_template_and_the_options_mask()
	requireBase()

	local removed, added = changedLines(NIRAME)

	lu.assertEquals(trimmed(removed), { "optionsBitmask = AIENABLED + JTLINTERESTING,", 'conversationTemplate = "",' }, NIRAME .. ": removed lines")

	local ad = trimmed(added)

	table.sort(ad)
	lu.assertEquals(#ad, 2, NIRAME .. ": added lines: " .. table.concat(ad, " | "))
	lu.assertNotNil(ad[1]:match('^conversationTemplate = "nirame_sakute_convo_template",%s*%-%-%s*Smuggler tier 4 trainer, SWG tatooine_privateer_tier4$'),
		NIRAME .. ": the new template line, got: " .. ad[1])
	lu.assertEquals(ad[2], "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", NIRAME .. ": the new mask line")
end

-- I-13, FN-6: each Valarian inspect ship file gains exactly the cargoString line, directly after questLoot
function TestSmugglerT4Pins:test_the_valarian_ship_files_gain_only_their_cargo_string_line()
	requireBase()

	local line = 'cargoString = "freight_plans", -- SWG space_mobile cargo valarian_freight_plans; inspect quest tatooine_privateer_tier4_3a (feature smuggler-tier4-nirame)'

	for _, path in ipairs({ SHIP_TIER4, SHIP_PLAIN }) do
		local removed, added, hunks = changedLines(path)

		lu.assertEquals(removed, {}, path .. ": removed lines")
		lu.assertEquals(trimmed(added), { line }, path .. ": added lines")
		lu.assertEquals(hunks, 1, path .. ": one hunk")

		local all = fileLines(local_(path))
		local at

		for i, l in ipairs(all) do
			if l == 'questLoot = "valarian_freight_plans",' then
				at = i
			end
		end

		lu.assertNotNil(at, path .. ": the questLoot line")
		lu.assertEquals(all[at + 1], line, path .. ": the cargoString line directly after questLoot")
	end
end

-- I-13: Karrde's template changes its first line and gains the tier4_done screen in one block
function TestSmugglerT4Pins:test_karrdes_template_changes_line_1_and_gains_only_tier4_done()
	requireBase()

	local removed, added, hunks = changedLines(KARRDE_TEMPLATE)
	local text = table.concat(added, "\n")

	lu.assertEquals(#removed, 1, KARRDE_TEMPLATE .. ": removed lines (the header comment)")
	lu.assertNotNil(removed[1]:find("^%-%- Talon Karrde %(Smuggler transition, tier 1 %-> 2%) conversation screens"), KARRDE_TEMPLATE .. ": the removed line is line 1")
	lu.assertEquals(hunks, 2, KARRDE_TEMPLATE .. ": two hunks (line 1 and the screen)")
	lu.assertNotNil(text:find('id = "tier4_done"', 1, true), KARRDE_TEMPLATE .. ": added screen tier4_done")

	local count = 0

	for _ in text:gmatch("ConvoScreen:new") do
		count = count + 1
	end

	lu.assertEquals(count, 1, KARRDE_TEMPLATE .. ": added screens")
	lu.assertNil(text:find("addConversationTemplate", 1, true), KARRDE_TEMPLATE .. ": the registration line is not touched")
end

-- I-13: Karrde's handler changes line 1 and the gate-order comment and gains the K9 gate
function TestSmugglerT4Pins:test_karrdes_handler_changes_two_comment_lines_and_gains_only_the_k9_gate()
	requireBase()

	local removed, added, hunks = changedLines(KARRDE_HANDLER)

	lu.assertEquals(#removed, 2, KARRDE_HANDLER .. ": removed lines (line 1 and the gate-order comment): " .. table.concat(removed, " | "))
	lu.assertEquals(hunks, 3, KARRDE_HANDLER .. ": three hunks (line 1, the comment, the gate)")

	local flat = table.concat(nonBlank(added), " "):gsub("%s+", " ")

	lu.assertNotNil(flat:find('-- Tier 4 complete (the four tier 4 skills; SWG doneWithTier4, K:379) if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 4)) then return convoTemplate:getScreen("tier4_done") end', 1, true),
		KARRDE_HANDLER .. ": the added gate (comment and line), whitespace aside")
end

-- SC-2: SpaceAttackWaves gains the getWaveZone hook and spawnWave uses it, nothing else
function TestSmugglerT4Pins:test_space_attack_waves_gains_only_the_wave_zone_hook()
	requireBase()

	local removed, added = changedLines(SAW)

	lu.assertEquals(#removed, 1, SAW .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertNotNil(removed[1]:find("spawnShipAgent(shipList[i], self.questZone, x, spawnPoint[2], y, pAnchorShip)", 1, true), SAW .. ": the removed line is the wave spawn")

	local joined = table.concat(added, "\n")

	lu.assertNotNil(joined:find("function SpaceAttackWaves:getWaveZone(pPlayer)", 1, true), SAW .. ": the hook")
	lu.assertNotNil(joined:find("return self.questZone", 1, true), SAW .. ": the default is the quest zone")
	lu.assertNotNil(joined:find("spawnShipAgent(shipList[i], self:getWaveZone(pPlayer), x, spawnPoint[2], y, pAnchorShip)", 1, true), SAW .. ": the wave spawn uses the hook")
end

-- SC-1: SpaceDeliveryScreenplay gains the zone fields and helpers; every changed line was a questZone use; the override comes after the mixin
function TestSmugglerT4Pins:test_space_delivery_only_gains_the_leg_zones_and_changes_only_questzone_uses()
	requireBase()

	local removed, added = changedLines(SDS)

	for _, l in ipairs(removed) do
		lu.assertTrue(l:find("questZone", 1, true) ~= nil or l:find("setupLeg(", 1, true) ~= nil,
			SDS .. ": removed line that is neither a questZone use nor a setupLeg signature or call: " .. l)
	end

	local joined = table.concat(added, "\n")

	lu.assertNotNil(joined:find('pickupZone = ""', 1, true), SDS .. ": the pickupZone field")
	lu.assertNotNil(joined:find('deliveryZone = ""', 1, true), SDS .. ": the deliveryZone field")
	lu.assertNotNil(joined:find("function SpaceDeliveryScreenplay:getLegZone(", 1, true), SDS .. ": getLegZone")
	lu.assertNotNil(joined:find("function SpaceDeliveryScreenplay:getWaveZone(pPlayer)", 1, true), SDS .. ": the getWaveZone override")

	local text = fileText(local_(SDS))
	local mixin = text:find("SpaceAttackWaves:mixInto(SpaceDeliveryScreenplay)", 1, true)
	local override = text:find("function SpaceDeliveryScreenplay:getWaveZone(pPlayer)", 1, true)

	lu.assertTrue(mixin ~= nil and override ~= nil and override > mixin, SDS .. ": getWaveZone is defined after the mixin (else the mixin's copy replaces it)")

	for _, fn in ipairs({ "completeQuest", "failQuest", "resetQuest", "cleanUpQuestData", "notifyDocked", "dockComplete", "finishQuest", "transportLost", "arrive" }) do
		lu.assertEquals(select(2, text:gsub("function SpaceDeliveryScreenplay:" .. fn .. "%(", "")), 1, SDS .. ": " .. fn .. " is still defined once")
	end
end

-- I-13: Dravis', Shamdon's, Beissa's, Burke's and Declann's files and the spawn data are byte-identical
function TestSmugglerT4Pins:test_the_other_trainers_the_master_trainers_and_the_spawn_files_are_byte_identical_to_the_base()
	requireBase()

	for _, path in ipairs({
		ROOT .. "mobile/space/dravis.lua",
		ROOT .. "mobile/space/shamdon_kree.lua",
		ROOT .. "mobile/space/beissa.lua",
		ROOT .. "mobile/space/talon_karrde.lua",
		ROOT .. "mobile/space/willham_burke.lua",
		ROOT .. "mobile/space/nial_declann.lua",
		ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/dravis_convo.lua",
		ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/shamdon_kree_convo.lua",
		ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/beissa_convo.lua",
		ROOT .. "mobile/conversations/space/rebel/willham_burke_convo.lua",
		ROOT .. "mobile/conversations/space/imperial/nial_declann_convo.lua",
		ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/dravisConvoHandler.lua",
		ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/shamdonKreeConvoHandler.lua",
		ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/beissaConvoHandler.lua",
		ROOT .. "screenplays/space/conversations/rebel/willhamBurkeConvoHandler.lua",
		ROOT .. "screenplays/space/conversations/imperial/nialDeclannConvoHandler.lua",
		ROOT .. "screenplays/space/squadrons/MasterTrainerScreenplay.lua",
		ROOT .. "screenplays/cities/dathomir_trade_outpost.lua",
	}) do
		local same, out = identical(path)

		lu.assertTrue(same, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-13: the other squadron files and every other quest type are byte-identical
function TestSmugglerT4Pins:test_the_other_squadron_files_and_the_quest_types_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay" }) do
		local path = ROOT .. "screenplays/space/squadrons/" .. name .. ".lua"
		local same, out = identical(path)

		lu.assertTrue(same, path .. " differs from " .. BASE .. ": " .. out)
	end

	for _, name in ipairs({ "SpaceQuestLogic", "SpaceAssassinateScreenplay", "SpaceBattleScreenplay", "SpaceDeliveryNoPickupScreenplay", "SpaceEscortScreenplay",
		"SpaceInspectScreenplay", "SpacePatrolScreenplay", "SpaceRecoveryScreenplay", "SpaceRescueScreenplay", "SpaceSurpriseAttackScreenplay", "SpaceSurvivalScreenplay",
		"SpaceDutyEscortScreenplay", "SpaceDutyRescueScreenplay", "SpaceDutyRecoveryScreenplay", "SpaceDutyDestroyScreenplay" }) do
		local path = ROOT .. "screenplays/space/" .. name .. ".lua"
		local same, out = identical(path)

		lu.assertTrue(same, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-13: no C++ change
function TestSmugglerT4Pins:test_no_cpp_file_differs_from_the_base()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/src'")

	lu.assertEquals(lines(changed .. "\n" .. untracked), {}, "files under src/ that differ from " .. BASE)
end
