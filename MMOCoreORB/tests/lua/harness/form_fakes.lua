-- Fakes for item radial menus, SUI pages and item string data (storm-tier2-oberhaur: the transfer form's Read / Sign menu).
-- Opt-in: a test file calls `require("harness.form_fakes").install()` once; nothing else loads this file, so no existing test sees a change.
--
-- What is simulated, and from which C++:
--   LuaObjectMenuResponse(p)         the menu response fake `M.newMenuResponse()` records addRadialMenuItem(id, callback, text)
--                                    (LuaObjectMenuResponse.cpp:33)
--   SceneObject/Container methods    getParentID (0 without a parent), getTemplateObjectPath, destroyObjectFromWorld (leaves the parent container, as
--                                    ContainerComponent does), destroyObjectFromDatabase (recorded)       (LuaSceneObject.cpp:35, 62, 79)
--   TangibleObject string data       setLuaStringData / getLuaStringData ("" when unset) / deleteLuaStringData        (LuaTangibleObject.cpp:46-48)
--   getContainerObjectByTemplate(c, template, checkChildren)  the first item whose template equals `template`; top level only unless checkChildren;
--                                    exactly 3 arguments, nil for a nil container                                        (DirectorManager.cpp:2214)
--   getStringId(id)                  "<en:" .. id .. ">", so a test sees whether the script resolved the id on the server side (DirectorManager.cpp:3613)
--   LuaSuiPageData(template | page)  the page the real screenplays/sui/SuiTemplate.lua builds: properties, default callback, target network id, stored
--                                    data (LuaSuiPageData.cpp:15-38)
--   LuaSuiManager():sendSuiPage(player, page, play, callback, windowType)   records one "sendSuiPage" call { player, sui } and returns a page id
--   the sui box the callback gets    FAITHFUL TO THE ENGINE: getUsingObject() is nil (SuiBoxPage never sets a using object; only the old-style
--                                    SuiManager boxes do, SuiManager.cpp:806, 868, 916). The page is reachable through LuaSuiBoxPage(pSui):getSuiPageData()
--                                    and its target id through LuaSuiPageData(page):getTargetNetworkId() (village_gm_sui.lua:65-72 does the same).
--
-- The real SuiTemplate / SuiMessageBox / SuiInputBox tables are loaded from bin/scripts/screenplays/sui/ by install().

local Engine = require("harness.engine")
local Fakes = require("harness.fakes")

local M = {}

local installed = false

local function ownMethods(class)
	return setmetatable(class, {
		__index = function(_, key)
			error("harness: fake " .. tostring(rawget(class, "__kind")) .. " has no method '" .. tostring(key) .. "'; add it in tests/lua/harness/form_fakes.lua", 2)
		end
	})
end

---------------------------------------------------------------------------------------------
-- Menu response
---------------------------------------------------------------------------------------------

local MenuResponse = { __kind = "ObjectMenuResponse" }
MenuResponse.__index = MenuResponse

function M.newMenuResponse()
	return setmetatable({ items = {} }, MenuResponse)
end

function MenuResponse:addRadialMenuItem(id, callback, text)
	if select("#", id, callback, text) ~= 3 or type(id) ~= "number" or type(callback) ~= "number" or type(text) ~= "string" then
		error("harness: addRadialMenuItem(id, callback, text) got bad arguments", 2)
	end

	self.items[#self.items + 1] = { id = id, callback = callback, text = text }
end

---------------------------------------------------------------------------------------------
-- SUI pages
---------------------------------------------------------------------------------------------

local Page = ownMethods({ __kind = "SuiPageData" })
Page.__index = Page

local function newPage(template)
	return setmetatable({ template = template, props = {}, storedData = {}, subscriptions = {}, targetNetworkId = 0, forceCloseDistance = 0 }, Page)
end

function Page:_getObject() return self end
function Page:setProperty(widget, property, value) self.props[widget .. "." .. property] = value end
function Page:getPropertyValue(widget, property) return self.props[widget .. "." .. property] or "" end
function Page:setDefaultCallback(callback) self.defaultCallback = callback end
function Page:setTargetNetworkId(id) self.targetNetworkId = id end
function Page:getTargetNetworkId() return self.targetNetworkId end
function Page:setForceCloseDistance(d) self.forceCloseDistance = d end
function Page:subscribeToPropertyForEvent(eventType, widget, property) self.subscriptions[#self.subscriptions + 1] = { eventType, widget, property } end
function Page:subscribeToEvent(eventType, parent, callback) self.subscriptions[#self.subscriptions + 1] = { eventType, parent, callback } end
function Page:setStoredData(key, value) self.storedData[key] = value end
function Page:getStoredData(key) return self.storedData[key] or "" end
function Page:deleteStoredData(key) self.storedData[key] = nil end

local Box = ownMethods({ __kind = "SuiBoxPage" })
Box.__index = Box

-- SuiBox::getUsingObject: null for a SuiBoxPage
function Box:getUsingObject() return nil end
function Box:getSuiPageData() return self.page end
function Box:getBoxID() return self.boxId end

local nextBoxId = 0

local SuiManager = {}

function SuiManager:sendSuiPage(pPlayer, pPage, play, callback, windowType)
	if select("#", pPlayer, pPage, play, callback, windowType) ~= 5 then
		error("harness: sendSuiPage(player, page, play, callback, windowType) takes 5 arguments", 2)
	end

	nextBoxId = nextBoxId + 1

	local box = setmetatable({ page = pPage, player = pPlayer, play = play, callback = callback, windowType = windowType, boxId = nextBoxId }, Box)

	Engine.record("sendSuiPage", pPlayer, box)

	return nextBoxId
end

-- The fields a test wants from a sent box: the template, title, prompt, button texts and target
function M.describe(box)
	local p = box.page

	return {
		template = p.template,
		title = p.props["bg.caption.lblTitle.Text"],
		prompt = p.props["Prompt.lblPrompt.Text"],
		ok = p.props["btnOk.Text"],
		cancel = p.props["btnCancel.Text"],
		target = p.targetNetworkId,
		play = box.play,
		callback = box.callback,
	}
end

-- The boxes sent to `player` (all players when nil), oldest first
function M.sent(player)
	local out = {}

	for _, call in ipairs(Engine.callsTo("sendSuiPage")) do
		if player == nil or call[1] == player then
			out[#out + 1] = call[2]
		end
	end

	return out
end

-- Fires the callback of a sent box like LuaSuiCallback::run: (creature, sui, eventIndex, args...)
function M.press(box, eventIndex, ...)
	local sp = rawget(_G, box.play)

	if sp == nil or type(sp[box.callback]) ~= "function" then
		error("harness: the sui callback " .. tostring(box.play) .. ":" .. tostring(box.callback) .. " is not defined", 2)
	end

	return sp[box.callback](sp, box.player, box, eventIndex, ...)
end

---------------------------------------------------------------------------------------------
-- Items
---------------------------------------------------------------------------------------------

local function patchItemClass(class, isContainer)
	function class:getTemplateObjectPath() return self.template or self.objectName or "" end

	function class:getParentID()
		return self.parent and self.parent.objectID or 0
	end

	function class:destroyObjectFromWorld()
		local parent = self.parent

		if parent ~= nil then
			for i, item in ipairs(parent.items) do
				if item == self then
					table.remove(parent.items, i)
					break
				end
			end

			self.parent = nil
		end

		Fakes.destroy(self)
	end

	function class:destroyObjectFromDatabase()
		self.removedFromDatabase = true
		Engine.record("destroyObjectFromDatabase", self)
	end

	function class:setLuaStringData(key, value)
		self.luaStrings = self.luaStrings or {}
		self.luaStrings[key] = value
	end

	function class:getLuaStringData(key)
		return (self.luaStrings or {})[key] or ""
	end

	function class:deleteLuaStringData(key)
		if self.luaStrings then
			self.luaStrings[key] = nil
		end
	end
end

-- A transfer form (or any item) put straight into `container`. opts.signature stores the string data the Sign menu writes.
function M.addItem(container, template, opts)
	local item = Fakes.giveItem(container, template, -1, true)

	if opts and opts.signature then
		item:setLuaStringData(opts.signatureKey or "signature", opts.signature)
	end

	return item
end

---------------------------------------------------------------------------------------------
-- install
---------------------------------------------------------------------------------------------

function M.install()
	if installed then
		return M
	end

	installed = true

	local Container = getmetatable(Fakes.newContainer({}))
	local Mission = getmetatable(Fakes.newMission())

	patchItemClass(Container, true)
	patchItemClass(Mission, false)

	-- the item knows where giveItem put it
	local plainGiveItem = Fakes.giveItem

	Fakes.giveItem = function(container, template, slot, overload)
		local item = plainGiveItem(container, template, slot, overload)

		if item ~= nil then
			item.parent = container
		end

		return item
	end

	rawset(_G, "LuaObjectMenuResponse", function(p) return p end)
	rawset(_G, "LuaSuiBoxPage", function(p) return p end)

	rawset(_G, "LuaSuiPageData", function(arg)
		if type(arg) == "string" then
			return newPage(arg)
		end

		return arg
	end)

	rawset(_G, "LuaSuiManager", function() return SuiManager end)

	rawset(_G, "getContainerObjectByTemplate", function(...)
		if select("#", ...) ~= 3 then
			error("harness: getContainerObjectByTemplate(container, template, checkChildren) takes 3 arguments", 2)
		end

		local container, template, checkChildren = ...

		if container == nil then
			return nil
		end

		local function search(c)
			for _, item in ipairs(c.items or {}) do
				if item.template == template then
					return item
				end

				if checkChildren and item.items then
					local found = search(item)

					if found ~= nil then
						return found
					end
				end
			end
		end

		return search(container)
	end)

	rawset(_G, "getStringId", function(id)
		if type(id) ~= "string" then
			error("harness: getStringId(id) takes a string", 2)
		end

		return "<en:" .. id .. ">"
	end)

	-- the real SUI templates (screenplays/sui/*.lua), over the fake page
	local scripts = Engine.SCRIPTS .. "screenplays/sui/"

	for _, name in ipairs({ "SuiTemplate", "SuiMessageBox", "SuiInputBox" }) do
		dofile(scripts .. name .. ".lua")
	end

	return M
end

M.MenuResponse = MenuResponse

return M
