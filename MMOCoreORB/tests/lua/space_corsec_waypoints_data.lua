-- Shared data and machinery of the space-corsec-waypoints tests (not a test file).
-- Spec: .claude/work/space-corsec-waypoints/01-spec.md (W-1 to W-8, R, I-1 to I-6, AC-1 to AC-9).
--
--   W.globals()          the non-assassinate quest tables of CorSec, RSF and Havoc that carry quest points (name -> table)
--   W.fields(q)          the mapped point fields of a table (spec "Data mapping")
--   W.points(q, f)       the point tables of a field in order (a single-point field gives one entry or none)
--   W.swg(q)             the SWG .tab record of a table (fixtures/spacequest/<type>/<lower name>.tab) or nil
--   W.extract(zone)      the quest_points extract of a zone: { nav = name -> {x,z,y}, spawner = name -> {x,z,y}, rows = n }
--   W.W1 ... W.W6, W.R_*  the spec's literal values (AC-1, AC-2); the expected values never come from the Core3 tables under test
--   W.baseText(path)     `git show 97a8c4aed7:MMOCoreORB/<path>` (nil, why when git or the commit is missing)

local H = require("harness")

local W = {}

W.SWG_GAME = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"
W.SWG_BUILDOUT = W.SWG_GAME .. "datatables/space_zones/buildout/"
W.SWG_SPACEQUEST = W.SWG_GAME .. "datatables/spacequest/"
W.FEATURE_COMMIT = "97a8c4aed7"

W.SQUADRON_DIR = "bin/scripts/screenplays/space/squadrons/"
W.CSP = W.SQUADRON_DIR .. "CorsecSquadronScreenplay.lua"
W.RSP = W.SQUADRON_DIR .. "RsfSquadronScreenplay.lua"
W.HSP = W.SQUADRON_DIR .. "HavocSquadronScreenplay.lua"
W.PP_DIR = "bin/scripts/ship_mobile/patrol_points/"
W.SPACE_DIR = "bin/scripts/screenplays/space/"

-- the seven zones with a quest_points extract (spec "Extract recipe"): nav points, spawners, data rows
W.EXTRACTS = {
	space_corellia = { nav = 27, spawner = 9, rows = 38 },
	space_dantooine = { nav = 54, spawner = 0, rows = 54 },
	space_dathomir = { nav = 27, spawner = 1, rows = 28 },
	space_endor = { nav = 62, spawner = 5, rows = 67 },
	space_lok = { nav = 40, spawner = 2, rows = 42 },
	space_naboo = { nav = 32, spawner = 8, rows = 40 },
	space_yavin4 = { nav = 54, spawner = 0, rows = 54 },
}

W.EXTRACT_ZONES = { "space_corellia", "space_dantooine", "space_dathomir", "space_endor", "space_lok", "space_naboo", "space_yavin4" }

-- the ten zones with a ship_mobile/patrol_points file
W.PP_ZONES = {
	"space_corellia", "space_dantooine", "space_dathomir", "space_endor", "space_heavy1",
	"space_light1", "space_lok", "space_naboo", "space_tatooine", "space_yavin4",
}

-- the 25 new SWG-Source fixtures (spec Content contract), "<type>/<name>"
W.NEW_FIXTURES = {
	"destroy/corellia_privateer_13a", "destroy/corellia_privateer_2", "destroy/corellia_rebel_2",
	"escort/corellia_privateer_14", "escort/corellia_privateer_3", "escort/corellia_privateer_tier3_1_b",
	"escort/corellia_privateer_tier3_3_pre_a", "escort/corellia_privateer_tier4_2b", "escort/corellia_rebel_3",
	"escort/corellia_rebel_tier3_2_c", "escort/corellia_rebel_tier3_3_c", "escort/viopa_rebel_2",
	"escort_duty/corellia_privateer_10", "escort_duty/corellia_privateer_7", "escort_duty/corellia_privateer_tier4_1",
	"escort_duty/corellia_rebel_7", "escort_duty/viopa_rebel_5",
	"patrol/corellia_privateer_3", "patrol/corellia_privateer_tier3_1_a", "patrol/corellia_privateer_tier3_3_a",
	"patrol/corellia_privateer_tier4_1a", "patrol/corellia_rebel_1", "patrol/corellia_rebel_3",
	"patrol/corellia_rebel_tier3_1_a", "patrol/corellia_rebel_tier3_4_a",
}

---------------------------------------------------------------------------------------------
-- Small helpers
---------------------------------------------------------------------------------------------

function W.trunc(v) return v < 0 and math.ceil(v) or math.floor(v) end

function W.readFile(path)
	local f = io.open(path, "rb")

	if f == nil then
		return nil
	end

	local text = f:read("a")
	f:close()

	return text
end

function W.shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

-- lines of a text, without the empty element a final "\n" leaves (so counts equal `wc -l`)
function W.linesOf(text)
	local lines = {}

	for line in (text .. "\n"):gmatch("(.-)\n") do
		lines[#lines + 1] = line
	end

	if lines[#lines] == "" then
		lines[#lines] = nil
	end

	return lines
end

function W.count(text, plain)
	local n, init = 0, 1

	while true do
		local s, e = text:find(plain, init, true)

		if s == nil then
			return n
		end

		n = n + 1
		init = e + 1
	end
end

function W.baseText(path, commit)
	local rc, out = W.shell("git show " .. (commit or W.FEATURE_COMMIT) .. ":MMOCoreORB/" .. path)

	if rc ~= 0 then
		return nil, out
	end

	return out
end

function W.xzy(p) return { x = p.x, z = p.z, y = p.y } end

---------------------------------------------------------------------------------------------
-- The mapped fields (spec "Data mapping")
---------------------------------------------------------------------------------------------
-- kind "nav": a quest nav point (buildout row `nav_name|4|<name>|`, patrol point file entry); "spawner": a spawner name
-- (buildout row `strSpawnerName|4|<name>|`). number = the Core3 field that must equal the list index.

local MAP = {
	patrol = { { field = "patrolPoints", col = "navPoints", kind = "nav", number = "patrolNumber" } },
	escort = { { field = "escortPoints", col = "escortPath", kind = "nav", number = "escortNumber", zoneRequired = true } },
	escort_duty = { { field = "escortPoints", col = "escortPoints", kind = "nav", number = "escortNumber", zoneRequired = true } },
	recovery = {
		{ field = "preRecoveryPoints", col = "escortPath", kind = "nav" },
		{ field = "recoveryPoints", col = "recoveryPath", kind = "nav", number = "escortNumber" },
	},
	recovery_duty = {
		{ field = "preRecoveryPoints", col = "escortPath", kind = "nav" },
		{ field = "recoveryPoints", col = "recoveryPath", kind = "nav", number = "escortNumber" },
	},
	rescue = { { field = "recoveryPath", col = "recoveryPath", kind = "nav" } },
	rescue_duty = { { field = "recoveryPath", col = "recoveryPath", kind = "nav" } },
	delivery = {
		{ field = "pickupPoint", col = "pickupPoint", kind = "nav", single = true },
		{ field = "deliveryPoint", col = "deliveryPoint", kind = "nav", single = true },
	},
	delivery_no_pickup = { { field = "deliveryPoint", col = "deliveryPoint", kind = "nav", single = true } },
	space_battle = { { field = "battlePoint", col = "battlePoint", kind = "nav", single = true } },
	survival = { { field = "transmissionPoint", col = "transmissionPoint", kind = "nav", single = true } },
	destroy = { { field = "shipLocations", col = "validSpawns", kind = "spawner" } },
	inspect = { { field = "validSpawns", col = "validSpawns", kind = "spawner" } },
}

function W.fields(q) return MAP[q.questType] or {} end

function W.pointName(p) return p.patrolPointName or p.spawnName end

function W.points(q, f)
	local value = rawget(q, f.field)

	if type(value) ~= "table" then
		return {}
	end

	if f.single then
		if W.pointName(value) ~= nil then
			return { value }
		end

		return {}
	end

	return value
end

local loaded = false

function W.loadSquadrons()
	if not loaded then
		loaded = true

		for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay" }) do
			H.loadSquadron(name)
		end
	end
end

-- every quest global whose type has mapped fields, except assassinate (done by space-assassinate-payload-fixes): name -> table
function W.globals()
	W.loadSquadrons()

	local out, names = {}, {}

	for _, name in ipairs(H.questGlobals()) do
		local q = rawget(_G, name)

		if q.questName ~= "" and q.questType ~= "" and MAP[q.questType] ~= nil then
			out[name] = q
			names[#names + 1] = name
		end
	end

	table.sort(names)

	return out, names
end

function W.fixturePath(questType, questName)
	return H.FIXTURES .. "spacequest/" .. questType .. "/" .. questName:lower() .. ".tab"
end

-- the SWG record of a table, or nil when the table has no .tab
function W.swg(q)
	if W.readFile(W.fixturePath(q.questType, q.questName)) == nil then
		return nil
	end

	return (H.questFixture(q.questType, q.questName:lower()))
end

-- the names and zone prefixes of a .tab column ("space_zone:name" values)
function W.swgNames(rec, col)
	local names, zones = {}, {}

	for i, ref in ipairs(rec:list(col)) do
		zones[i], names[i] = H.Tab.splitNavPoint(ref)
	end

	return names, zones
end

---------------------------------------------------------------------------------------------
-- The buildout extracts
---------------------------------------------------------------------------------------------

function W.extractPath(zone) return H.FIXTURES .. "space_zones/buildout/" .. zone .. ".quest_points.tab" end

local extractCache = {}

-- { nav = name -> {x,z,y} (first row, truncated toward zero), spawner = name -> {x,z,y}, navRows = n, spawnerRows = n, rows = n }
function W.extract(zone)
	if extractCache[zone] == nil then
		local tab = H.Tab.read(W.extractPath(zone))
		local out = { nav = {}, spawner = {}, navRows = 0, spawnerRows = 0, rows = #tab.records }

		for _, rec in ipairs(tab.records) do
			local vars = rec:get("strObjVars") or ""
			local pos = { x = W.trunc(rec:num("fltPX")), z = W.trunc(rec:num("fltPY")), y = W.trunc(rec:num("fltPZ")) }
			local nav = vars:match("nav_name|4|([^|]+)|")
			local spawner = vars:match("strSpawnerName|4|([^|]+)|")

			if nav ~= nil then
				out.navRows = out.navRows + 1
				out.nav[nav] = out.nav[nav] or pos
			end

			if spawner ~= nil then
				out.spawnerRows = out.spawnerRows + 1
				out.spawner[spawner] = out.spawner[spawner] or pos
			end
		end

		extractCache[zone] = out
	end

	return extractCache[zone]
end

---------------------------------------------------------------------------------------------
-- The spec's literal values (AC-1, AC-2): { name, x, z, y, number }
---------------------------------------------------------------------------------------------

-- W-1, W-7: Turoldine's escort duty (CorSec tier 4 mission 1 duty)
W.TUROLDINE_DUTY = "escort_duty_corellia_privateer_tier4_1"
W.TUROLDINE_DUTY_POINTS = {
	{ "corellia_privateer_tier4_escort_duty_1", 3523, 399, -4024, 1 },
	{ "corellia_privateer_tier4_escort_duty_3", 1395, 5751, -3946, 2 },
	{ "corellia_privateer_tier4_escort_duty_4", 817, 7126, -3851, 3 },
	{ "corellia_privateer_tier4_escort_duty_5", 2372, 7391, -1995, 4 },
}

-- W-4: Rikkh mission 2
W.RIKKH_M2 = "escort_corellia_privateer_14"
W.RIKKH_M2_POINTS = {
	{ "yavin4_privateer_escort_1", -2162, 956, 4990, 1 },
	{ "yavin4_privateer_escort_2", -636, -294, 4769, 2 },
	{ "yavin4_privateer_escort_3", 2042, -1229, 5413, 3 },
	{ "yavin4_privateer_escort_4", -2064, -928, -3183, 4 },
}

-- W-5: Rikkh's escort duty
W.RIKKH_DUTY = "escort_duty_corellia_privateer_10"
W.RIKKH_DUTY_POINTS = {
	{ "lok_privateer_escort_1", 2674, 3425, 5460, 1 },
	{ "lok_privateer_escort_2", 4217, 3326, 5246, 2 },
	{ "lok_privateer_escort_3", 5908, 4911, 5012, 3 },
	{ "lok_privateer_escort_4", 7095, 7369, 4847, 4 },
}

-- W-3: Ramna mission 3, patrol leg
W.RAMNA_M3_PATROL = "patrol_corellia_privateer_tier3_3_a"
W.RAMNA_M3_PATROL_POINTS = {
	{ "corellia_privateer_tier3_patrol_1", -4204, -3241, 3652, 1 },
	{ "corellia_privateer_tier3_patrol_2", -4773, -3338, 2891, 2 },
	{ "corellia_privateer_tier3_patrol_3", -4809, -3162, 1449, 3 },
	{ "corellia_privateer_tier3_patrol_4", -4468, -3583, 624, 4 },
}

-- W-2 and R: Ramna mission 1 recovery (lok). Every point of the table, wherever the table keeps it
W.RAMNA_M1_RECOVERY = "recovery_corellia_privateer_tier3_1"
W.RAMNA_M1_RECOVERY_POINTS = {
	corellia_privateer_tier3_recovery_point_2 = { 4317, 462, 3867 },
	corellia_privateer_tier3_recovery_point_3 = { 4378, -203, 4414 },
	corellia_privateer_tier3_recovery_point_4 = { 4440, -876, 4966 },
	imperial_ss_interception_1 = { 3230, -3912, 7336 },
	corellia_privateer_tier3_recovery_point_5 = { 4692, -604, 3823 },
	corellia_privateer_tier3_recovery_point_6 = { 5053, -1136, 3170 },
	corellia_privateer_tier3_recovery_point_7 = { 5133, -1919, 2853 },
	corellia_privateer_tier3_recovery_point_8 = { 5187, -2757, 2563 },
}

-- R: Ramna mission 1, supply escort leg
W.SUPPLY_ESCORT = "escort_corellia_privateer_tier3_1_b"
W.SUPPLY_ESCORT_POINTS = {
	corellia_privateer_tier3_supply_escort_1 = { 3798, -361, -3018 },
	corellia_privateer_tier3_supply_escort_2 = { 4280, 295, -2817 },
}

-- W-8: Turoldine mission 2 escort
W.TUROLDINE_M2_ESCORT = "escort_corellia_privateer_tier4_2b"

-- W-6: Kreezo mission 2 (Havoc), in SWG order
W.KREEZO_M2 = "destroy_corellia_rebel_2"
W.KREEZO_M2_LOCATIONS = {
	{ patrolPointName = "imperial_fighter_five_spawner", x = -6064, z = 218, y = -2678 },
	{ patrolPointName = "imperial_fighter_one_spawner", x = -3611, z = -3225, y = -2999 },
	{ patrolPointName = "imperial_fighter_seven_spawner", x = -6458, z = -2137, y = -1846 },
	{ patrolPointName = "imperial_fighter_three_spawner", x = -6902, z = -240, y = 174 },
}

---------------------------------------------------------------------------------------------
-- Line texts of the Data edits (spec "Data edits"), for the AC-9 file pins. The shapes are the file's own.
---------------------------------------------------------------------------------------------

local T = "\t"

function W.escortLine(name, zone, x, z, y, n)
	return string.format('%s%s{patrolPointName = "%s", zoneName = "%s", x = %d, z = %d, y = %d, escortNumber = %d, radius = 250},', T, T, name, zone, x, z, y, n)
end

function W.patrolLine(name, zone, x, z, y, n)
	return string.format('%s%s{patrolPointName = "%s", zoneName = "%s", x = %d, z = %d, y = %d, patrolNumber = %d, radius = 150},', T, T, name, zone, x, z, y, n)
end

function W.spawnerLine(name, x, z, y)
	return string.format('%s%s{patrolPointName = "%s", x = %d, z = %d, y = %d},', T, T, name, x, z, y)
end

-- CSP base line number -> the new text; a `false` value deletes the line (W-7)
function W.corsecEdits()
	local e = {}
	local D, L, EN, DA = "space_dathomir", "space_lok", "space_endor", "space_dantooine"

	for i, p in ipairs(W.RIKKH_M2_POINTS) do
		e[353 + i] = W.escortLine(p[1], "space_yavin4", p[2], p[3], p[4], p[5])
	end

	for i, p in ipairs(W.RIKKH_DUTY_POINTS) do
		e[491 + i] = W.escortLine(p[1], L, p[2], p[3], p[4], p[5])
	end

	-- recovery_corellia_privateer_tier3_1: preRecoveryPoints (627 + k) and recoveryPoints (635 + k)
	local R = W.RAMNA_M1_RECOVERY_POINTS
	local pre = { { "corellia_privateer_tier3_recovery_point_2", 2 }, { "corellia_privateer_tier3_recovery_point_3", 3 },
		{ "corellia_privateer_tier3_recovery_point_4", 4 }, { "imperial_ss_interception_1", 3 } }

	for k, row in ipairs(pre) do
		local c = R[row[1]]
		e[627 + k] = W.escortLine(row[1], L, c[1], c[2], c[3], row[2])
	end

	for k = 1, 4 do
		local name = "corellia_privateer_tier3_recovery_point_" .. (k + 4)
		local c = R[name]
		e[635 + k] = W.escortLine(name, L, c[1], c[2], c[3], k)
	end

	for k = 1, 2 do
		local name = "corellia_privateer_tier3_supply_escort_" .. k
		local c = W.SUPPLY_ESCORT_POINTS[name]
		e[708 + k] = W.escortLine(name, EN, c[1], c[2], c[3], k)
	end

	for i, p in ipairs(W.RAMNA_M3_PATROL_POINTS) do
		e[992 + i] = W.patrolLine(p[1], DA, p[2], p[3], p[4], p[5])
	end

	e[1373] = W.escortLine("corellia_privateer_tier4_leg_2_escort_5", D, -2682, 7408, 2855, 5)

	local d = W.TUROLDINE_DUTY_POINTS

	e[1879] = W.escortLine(d[1][1], D, d[1][2], d[1][3], d[1][4], d[1][5])
	e[1880] = false
	e[1881] = W.escortLine(d[2][1], D, d[2][2], d[2][3], d[2][4], d[2][5])
	e[1882] = W.escortLine(d[3][1], D, d[3][2], d[3][3], d[3][4], d[3][5])
	e[1883] = W.escortLine(d[4][1], D, d[4][2], d[4][3], d[4][4], d[4][5])

	return e
end

-- HSP base lines 82-84 are replaced by these four lines (W-6)
function W.havocReplacement()
	local out = {}

	for i, p in ipairs(W.KREEZO_M2_LOCATIONS) do
		out[i] = W.spawnerLine(p.patrolPointName, p.x, p.z, p.y)
	end

	return out
end

return W
