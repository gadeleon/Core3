-- Black Epsilon tier 2 mission 13 cargo (feature black-epsilon-tier2-inspect-cargo).
-- inspect_corellia_imperial_13 completes only when the inspected ship's template cargoString equals the quest cargo
-- (ShipInspectTask.cpp reads getCargoString). SWG space_mobile.tab gives rebel_spysmuggler_tier2 the cargo
-- personnel_dossier, a canTransfer row of inspect_cargo/personnel_dossier.tab. The tier 2 runtime test set the cargo
-- on its fake ship, so this reads the real template file.

local lu = require("luaunit")
local H = require("harness")
local P = require("black_epsilon_tier2_data")

P.load()

-- The template file without comments
local function templateSource(shipName)
	local path = H.SCRIPTS .. "ship_mobile/ships/" .. shipName .. ".lua"

	lu.assertTrue(H.fileExists(path), "expected ship template bin/scripts/ship_mobile/ships/" .. shipName .. ".lua to exist")

	local f = io.open(path, "r")
	local src = f:read("a")
	f:close()

	return (src:gsub("%-%-[^\n]*", ""))
end

local function cargoIsTransferable(tableName, cargo)
	for _, rec in ipairs(H.fixture("spacequest/inspect_cargo/" .. tableName .. ".tab").records) do
		if rec:get("name") == cargo and rec:num("canTransfer") == 1 then
			return true
		end
	end

	return false
end

TestBlackEpsilonT2InspectCargo = {}

function TestBlackEpsilonT2InspectCargo:setUp() H.reset() end

function TestBlackEpsilonT2InspectCargo:test_every_mission_13_ship_carries_the_quest_cargo_as_a_transferable_cargo_string()
	local q = H.expectGlobal("inspect_corellia_imperial_13", "inspect quest table for corellia_imperial_13")

	lu.assertEquals(q.cargo, "personnel_dossier", "inspect_corellia_imperial_13 cargo")
	lu.assertEquals(q.shipList, { "rebel_spysmuggler_tier2" }, "inspect_corellia_imperial_13 shipList")

	for _, ship in ipairs(q.shipList) do
		local src = templateSource(ship)
		local cargoString = src:match('cargoString%s*=%s*"(.-)"')
		local questLoot = src:match('questLoot%s*=%s*"(.-)"')

		lu.assertEquals(cargoString, q.cargo, ship .. ".lua cargoString must equal the quest cargo")
		lu.assertEquals(questLoot, "personnel_dossier", ship .. ".lua questLoot")
		lu.assertTrue(cargoIsTransferable(questLoot, q.cargo), ship .. ": cargo '" .. q.cargo .. "' is a canTransfer = 1 row of inspect_cargo/" .. questLoot .. ".tab")
	end
end
