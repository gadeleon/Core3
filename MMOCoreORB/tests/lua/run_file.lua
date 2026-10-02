-- Runs one test file in a fresh Lua state: lua5.3 tests/lua/run_file.lua <test file> [luaunit args]
-- Must be started from MMOCoreORB/ (run.sh does this).

package.path = table.concat({
	"bin/scripts/?.lua",
	"tests/lua/?.lua",
	"tests/lua/?/init.lua",
	"tests/lua/vendor/?.lua",
	package.path,
}, ";")

math.randomseed(1)

local testFile = assert(arg[1], "usage: run_file.lua <test file> [luaunit args]")
local lu = require("luaunit")

dofile(testFile)

local luArgs = { "--output", "text" }

for i = 2, #arg do
	luArgs[#luArgs + 1] = arg[i]
end

os.exit(lu.LuaUnit.run(table.unpack(luArgs)))
