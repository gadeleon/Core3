-- The shared SpaceAttackWaves mixin and its two hosts (space-quest-stub-delivery).
-- Spec: .claude/work/space-quest-stub-delivery/01-spec.md (I-6, I-7, Content contract: SpaceAttackWaves,
-- SpaceSurvivalScreenplay refactor, screenplays.lua). Behavior of the waves themselves is covered by the
-- survival tests (unchanged) and test_delivery_waves.lua.

local lu = require("luaunit")
local H = require("harness")

H.loadSpaceQuestTypes()

local WAVE_FUNCTIONS = { "launchWave", "pickList", "spawnWave", "getLiveWaveCount", "notifyAttackShipDestroyed",
	"removeAttackShips", "cleanUpWaveData", "notifyTargetsRemaining" }

local function mixin()
	return H.expectGlobal("SpaceAttackWaves", "screenplays/space/SpaceAttackWaves.lua defines the global SpaceAttackWaves")
end

TestSpaceAttackWavesMixin = {}

function TestSpaceAttackWavesMixin:setUp() H.reset() end

-- I-7
function TestSpaceAttackWavesMixin:test_the_script_exists_and_defines_the_global_with_mix_into()
	lu.assertTrue(H.fileExists(H.SCRIPTS .. "screenplays/space/SpaceAttackWaves.lua"), "bin/scripts/screenplays/space/SpaceAttackWaves.lua must exist")
	lu.assertEquals(type(mixin().mixInto), "function", "SpaceAttackWaves.mixInto")
end

-- I-7
function TestSpaceAttackWavesMixin:test_it_provides_the_eight_wave_functions()
	for _, f in ipairs(WAVE_FUNCTIONS) do
		lu.assertEquals(type(mixin()[f]), "function", "SpaceAttackWaves." .. f)
	end
end

-- Content contract: not a screenplay
function TestSpaceAttackWavesMixin:test_it_is_a_plain_table_and_not_a_registered_screenplay()
	local m = mixin()

	lu.assertNil(H.registered("SpaceAttackWaves"), "SpaceAttackWaves must not call registerScreenPlay")
	lu.assertNil(m.className, "SpaceAttackWaves has no className")
	lu.assertNil(getmetatable(m), "SpaceAttackWaves is a plain table (no :new base class)")
end

-- Content contract: mixInto copies raw function fields, overwrites, and does not copy itself
function TestSpaceAttackWavesMixin:test_mix_into_copies_every_function_as_a_raw_field_except_mix_into()
	local m = mixin()
	local host = {}

	m:mixInto(host)

	for k, v in pairs(m) do
		if type(v) == "function" and k ~= "mixInto" then
			lu.assertEquals(rawget(host, k), v, "host." .. k .. " is the mixin function, copied as a raw field")
		end
	end

	lu.assertNil(rawget(host, "mixInto"), "mixInto itself is not copied")
end

-- Content contract: mixInto overwrites, so it works even when the host's parent defines the same names
function TestSpaceAttackWavesMixin:test_mix_into_overwrites_existing_fields_and_uses_raw_set()
	local m = mixin()
	local base = { launchWave = function() return "base" end }
	local host = setmetatable({ pickList = function() return "host" end }, { __index = base, __newindex = function() error("mixInto must use rawset") end })

	m:mixInto(host)

	lu.assertEquals(rawget(host, "launchWave"), m.launchWave, "launchWave raw on the host, not inherited")
	lu.assertEquals(rawget(host, "pickList"), m.pickList, "an existing field is overwritten")
end

-- Content contract: the default hook is a no-op
function TestSpaceAttackWavesMixin:test_the_default_targets_remaining_hook_sends_nothing()
	H.reset()

	local player = H.newPlayer({ zone = "space_lok", ship = {} })

	mixin().notifyTargetsRemaining({}, player, 3)

	lu.assertEquals(H.messageLog(player), {}, "no message from the default hook")
end

TestSpaceAttackWavesHosts = {}

function TestSpaceAttackWavesHosts:setUp() H.reset() end

-- I-7
function TestSpaceAttackWavesHosts:test_survival_and_delivery_have_the_wave_functions_as_raw_fields()
	for _, host in ipairs({ "SpaceSurvivalScreenplay", "SpaceDeliveryScreenplay" }) do
		local class = H.expectGlobal(host)

		for _, f in ipairs(WAVE_FUNCTIONS) do
			lu.assertEquals(type(rawget(class, f)), "function", host .. "." .. f .. " must be a raw function field (copied by mixInto)")
		end
	end
end

-- I-7
function TestSpaceAttackWavesHosts:test_the_hosts_share_the_mixin_functions_not_copies_of_the_source()
	local m = mixin()

	for _, host in ipairs({ "SpaceSurvivalScreenplay", "SpaceDeliveryScreenplay" }) do
		local class = H.expectGlobal(host)

		for _, f in ipairs({ "launchWave", "pickList", "spawnWave", "getLiveWaveCount", "notifyAttackShipDestroyed", "removeAttackShips", "cleanUpWaveData" }) do
			lu.assertEquals(rawget(class, f), m[f], host .. "." .. f .. " is the SpaceAttackWaves function")
		end
	end
end

-- I-7
function TestSpaceAttackWavesHosts:test_survival_keeps_the_no_op_hook_so_it_sends_no_targets_remaining_message()
	local player = H.newPlayer({ zone = "space_lok", ship = {} })

	H.expectGlobal("SpaceSurvivalScreenplay"):notifyTargetsRemaining(player, 4)

	lu.assertEquals(H.messageLog(player), {}, "survival's notifyTargetsRemaining sends nothing")
end

-- I-7, Content contract: delivery overrides the hook (the override is not overwritten by mixInto)
function TestSpaceAttackWavesHosts:test_delivery_overrides_the_hook_with_the_destroy_duty_targets_remaining_message()
	local class = H.expectGlobal("SpaceDeliveryScreenplay")
	local player = H.newPlayer({ zone = "space_lok", ship = {} })

	lu.assertNotEquals(rawget(class, "notifyTargetsRemaining"), mixin().notifyTargetsRemaining, "delivery defines its own notifyTargetsRemaining after mixInto")

	class:notifyTargetsRemaining(player, 4)

	local log = H.messageLog(player)

	lu.assertEquals(#log, 1, "one message")
	lu.assertEquals(log[1].id, "@space/quest:destroy_duty_targets_remaining", "string id")
	lu.assertEquals(log[1].DI, 4, "DI = the number of attack ships alive")
end

-- Content contract: the include goes right after SpaceQuestLogic in screenplays.lua
function TestSpaceAttackWavesHosts:test_screenplays_lua_includes_the_mixin_directly_after_space_quest_logic()
	local f = io.open(H.SCRIPTS .. "screenplays/space/screenplays.lua", "r")

	lu.assertNotNil(f, "screenplays/space/screenplays.lua is readable")

	local lines = {}

	for line in f:lines() do
		lines[#lines + 1] = line
	end

	f:close()

	local at

	for i, line in ipairs(lines) do
		if line:find('includeFile("space/SpaceQuestLogic.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "includeFile of SpaceQuestLogic.lua found")
	lu.assertEquals(lines[at + 1], 'includeFile("space/SpaceAttackWaves.lua")', "the line after SpaceQuestLogic.lua")
end

-- Content contract: the hosts call mixInto before registerScreenPlay (source order)
function TestSpaceAttackWavesHosts:test_hosts_mix_in_right_after_their_class_table()
	for _, file in ipairs({ "SpaceSurvivalScreenplay.lua", "SpaceDeliveryScreenplay.lua" }) do
		local f = io.open(H.SCRIPTS .. "screenplays/space/" .. file, "r")

		lu.assertNotNil(f, file .. " readable")

		local src = f:read("a")
		f:close()

		local mixAt = src:find("SpaceAttackWaves:mixInto(", 1, true)
		local regAt = src:find("registerScreenPlay(", 1, true)

		lu.assertNotNil(mixAt, file .. ": calls SpaceAttackWaves:mixInto(...)")
		lu.assertTrue(mixAt < regAt, file .. ": mixInto is called before registerScreenPlay")
	end
end

-- Content contract: survival no longer carries its own copies (the functions moved, not duplicated)
function TestSpaceAttackWavesHosts:test_survival_source_no_longer_defines_the_moved_functions()
	local f = io.open(H.SCRIPTS .. "screenplays/space/SpaceSurvivalScreenplay.lua", "r")
	local src = f:read("a")
	f:close()

	for _, name in ipairs({ "launchWave", "pickList", "spawnWave", "getLiveWaveCount", "notifyAttackShipDestroyed", "removeAttackShips" }) do
		lu.assertNil(src:find("function SpaceSurvivalScreenplay:" .. name .. "(", 1, true), "SpaceSurvivalScreenplay.lua must not define " .. name .. " any more")
	end
end

-- Content contract: cleanUpWaveData deletes exactly the wave keys survival used to delete
function TestSpaceAttackWavesHosts:test_clean_up_wave_data_deletes_the_wave_keys_and_nothing_else()
	local class = H.expectGlobal("SpaceSurvivalScreenplay")
	local host = { className = "SpaceSurvivalScreenplay" }

	function host:dataKey(playerID, name) return playerID .. ":" .. self.className .. ":" .. name end

	local player = H.newPlayer({ zone = "space_lok", ship = {} })
	local id = player.objectID
	local function key(name) return host:dataKey(id, name) end

	writeData(key("wavePending"), 1)
	writeData(key("nextList"), 2)
	writeData(key("waveCount"), 2)
	writeData(key("waveLive:1"), 3)
	writeData(key("waveLive:2"), 1)
	writeData(key("runID"), 77)
	writeData(key("arrived"), 1)

	mixin().cleanUpWaveData(host, player)

	lu.assertEquals(H.Engine.sharedMemoryKeys(), { "|" .. key("arrived"), "|" .. key("runID") }, "only the non-wave keys remain")
	lu.assertNotNil(class, "survival host exists")
end
