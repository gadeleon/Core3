-- The quest type files that older features pin byte for byte change only as space-quest-player-ship-destroyed says; and the comments
-- C6 and C7 reword say what the spec wants.
-- Spec: .claude/work/space-quest-player-ship-destroyed/01-spec.md (C4, C6, C7, Superseded tests)

local lu = require("luaunit")
local H = require("harness")
local Pins = require("psd_pins")

local DIR = "bin/scripts/screenplays/space/"

local function problems(file, allow)
	local list, why = Pins.problems(Pins.BEFORE, DIR .. file, allow)

	if list == nil then
		lu.skip("git cannot show " .. Pins.BEFORE .. ": " .. tostring(why))
	end

	return list
end

local function read(file)
	local f = assert(io.open(DIR .. file, "r"))
	local text = f:read("a")

	f:close()

	return text
end

TestPlayerShipDestroyedPins = {}

-- C4: the files an earlier feature pins (CorSec waypoints, master mission) gain one function and nothing else
function TestPlayerShipDestroyedPins:test_destroy_and_duty_patrol_gain_only_the_run_check()
	lu.assertEquals(problems("SpaceDestroyScreenplay.lua", { runCheck = "SpaceDestroyScreenplay" }), {}, "SpaceDestroyScreenplay.lua")
	lu.assertEquals(problems("SpaceDutyPatrolScreenplay.lua", { runCheck = "SpaceDutyPatrolScreenplay" }), {}, "SpaceDutyPatrolScreenplay.lua")
end

-- C4, C6: the rescue and survival types gain the run check, the same-zone guard and reworded comments
function TestPlayerShipDestroyedPins:test_rescue_and_survival_gain_the_run_check_the_guard_and_reworded_comments_only()
	lu.assertEquals(problems("SpaceRescueScreenplay.lua", { runCheck = "SpaceRescueScreenplay", guard = true, comments = true }), {}, "SpaceRescueScreenplay.lua")
	lu.assertEquals(problems("SpaceSurvivalScreenplay.lua", { runCheck = "SpaceSurvivalScreenplay", guard = true, comments = true }), {}, "SpaceSurvivalScreenplay.lua")
end

-- The guard is where C6 puts it: in the zone observer, once, in each of the five types
function TestPlayerShipDestroyedPins:test_each_of_the_five_zone_observers_has_the_guard_once()
	local guard = "if (zoneNameHash == getHashCode(SceneObject(pPlayer):getZoneName())) then return 0 end"

	for _, file in ipairs({ "SpaceBattleScreenplay.lua", "SpaceInspectScreenplay.lua", "SpaceRescueScreenplay.lua", "SpaceDeliveryScreenplay.lua", "SpaceSurvivalScreenplay.lua" }) do
		local text = read(file)
		local _, count = text:gsub(guard:gsub("%p", "%%%0"), "")

		lu.assertEquals(count, 1, file .. ": the same-zone guard appears once")

		-- inside enteredZone, after the isSpaceQuestActive guard
		local from = text:find(":enteredZone(", 1, true)
		local active = text:find("isSpaceQuestActive(pPlayer, self.questType, self.questName)", from, true)
		local at = text:find(guard, 1, true)

		lu.assertTrue(from ~= nil and active ~= nil and at ~= nil and from < active and active < at, file .. ": the guard comes after the isSpaceQuestActive check of enteredZone")
	end

	-- rescue duty reaches it through the rescue observer
	lu.assertNil(read("SpaceDutyRescueScreenplay.lua"):find("getZoneName())) then return 0 end", 1, true), "SpaceDutyRescueScreenplay:enteredZone is unchanged")
end

-- C6: the five "Any zone change once ..." comments no longer mention the respawn
function TestPlayerShipDestroyedPins:test_the_zone_change_comments_no_longer_mention_the_respawn()
	for _, file in ipairs({ "SpaceBattleScreenplay.lua", "SpaceRescueScreenplay.lua", "SpaceDeliveryScreenplay.lua", "SpaceSurvivalScreenplay.lua" }) do
		local text = read(file)

		for line in text:gmatch("[^\n]+") do
			if line:find("Any zone change once", 1, true) then
				lu.assertNil(line:find("respawn", 1, true), file .. ": " .. line)
				lu.assertNil(line:find("ship is destroyed", 1, true), file .. ": " .. line)
			end
		end

		lu.assertNotNil(text:find("Any zone change once", 1, true), file .. ": the comment is reworded, not deleted")
	end
end

-- C7
function TestPlayerShipDestroyedPins:test_the_destroy_duty_comment_no_longer_says_losing_the_ship()
	local text = read("SpaceDutyDestroyScreenplay.lua")

	lu.assertNil(text:find("losing the ship", 1, true), "SpaceDutyDestroyScreenplay.lua")
	lu.assertNotNil(text:find("-- Leaving the zone ends the duty as won without pay (destroy_duty.java:100-108)", 1, true), "C7 comment text")
end
