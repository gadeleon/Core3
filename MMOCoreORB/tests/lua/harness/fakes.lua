-- Fake game objects and fake C++ Lua wrapper types (LuaCreatureObject, LuaPlayerObject,
-- LuaConversationTemplate, ...).
--
-- In the server, a "pointer" (pPlayer, pNpc, pConvTemplate) is light userdata, and wrappers such
-- as CreatureObject(pPlayer) (defined in Lua by managers/object/object_manager.lua) call
-- LuaCreatureObject:_setObject(p) and then forward methods to C++. Here a pointer is a fake
-- object table, and every wrapper forwards method calls to that table. A missing method fails
-- loudly with a message saying where to add it.

local Fakes = {}

local registry = {} -- objectID -> fake
local nextObjectID = 1000

-- Backing store for the engine's getQuestStatus/setQuestStatus/removeQuestStatus (key -> string).
Fakes.questStatus = {}

function Fakes.reset()
	registry = {}
	nextObjectID = 1000
	Fakes.questStatus = {}
end

function Fakes.lookup(objectID)
	return registry[objectID]
end

local function register(obj)
	nextObjectID = nextObjectID + 1
	obj.objectID = obj.objectID or nextObjectID
	registry[obj.objectID] = obj
	return obj
end

-- Journal quest key exactly as SpaceHelpers builds it: getHashCode("spacequest/<type>/<name>").
function Fakes.questCrc(questType, questName)
	return getHashCode("spacequest/" .. questType .. "/" .. questName)
end

local function set(list)
	local s = {}

	for _, v in ipairs(list or {}) do
		s[v] = true
	end

	return s
end

---------------------------------------------------------------------------------------------
-- Fake player ghost (PlayerObject)
---------------------------------------------------------------------------------------------

local FakeGhost = { __kind = "PlayerObject" }
FakeGhost.__index = FakeGhost

-- opts.activeQuests / opts.completedQuests: lists of journal quest CRCs. Build them with
-- Fakes.questCrc(type, name), which mirrors SpaceHelpers' "spacequest/<type>/<name>" key.
function Fakes.newGhost(opts)
	opts = opts or {}

	local g = setmetatable({
		journalActive = set(opts.activeQuests),
		journalComplete = set(opts.completedQuests),
		squadronType = opts.squadronType or 0,
		experience = opts.experience or {},
		pilotTier = opts.pilotTier or 0,
		factionStanding = {},
		waypoints = {},
	}, FakeGhost)

	for faction, standing in pairs(opts.factionStanding or {}) do
		g.factionStanding[faction] = standing
	end

	return register(g)
end

function FakeGhost:getObjectID() return self.objectID end
function FakeGhost:isJournalQuestActive(crc) return self.journalActive[crc] == true end
function FakeGhost:isJournalQuestComplete(crc) return self.journalComplete[crc] == true end
function FakeGhost:activateJournalQuest(crc, notify) self.journalActive[crc] = true end
function FakeGhost:completeJournalQuest(crc, notify) self.journalActive[crc] = nil; self.journalComplete[crc] = true end
function FakeGhost:clearJournalQuest(crc, notify) self.journalActive[crc] = nil; self.journalComplete[crc] = nil end
function FakeGhost:isSquadronType(t) return self.squadronType == t end
function FakeGhost:setSquadronType(t) self.squadronType = t end
function FakeGhost:getSquadronType() return self.squadronType end
function FakeGhost:getExperience(xpType) return self.experience[xpType] or 0 end
function FakeGhost:getPilotTier() return self.pilotTier end
function FakeGhost:incrementPilotTier() self.pilotTier = self.pilotTier + 1 end
function FakeGhost:getFactionStanding(faction) return self.factionStanding[faction] or 0 end
function FakeGhost:increaseFactionStanding(faction, amount) self.factionStanding[faction] = (self.factionStanding[faction] or 0) + amount end
function FakeGhost:decreaseFactionStanding(faction, amount) self.factionStanding[faction] = (self.factionStanding[faction] or 0) - amount end
function FakeGhost:setFactionStanding(faction, amount) self.factionStanding[faction] = amount end

function FakeGhost:addWaypoint(planet, name, desc, x, y, color, active, notify, special, persistent)
	self.waypoints[#self.waypoints + 1] = { planet = planet, name = name, x = x, y = y }
	return #self.waypoints
end

---------------------------------------------------------------------------------------------
-- Fake creature (player character or NPC)
---------------------------------------------------------------------------------------------

local FakeCreature = { __kind = "CreatureObject" }
FakeCreature.__index = FakeCreature

-- opts: name, skills (list), faction (crc/int), pilot ("neutral"|"rebel"|"imperial"|nil),
-- certifiedShip (bool), screenPlayStates (table name->state), ghost (fake ghost; created if nil
-- unless isNpc), isNpc (bool).
-- Ghost opts (passed through): squadronType, experience ({space_combat_general = n}), activeQuests,
-- completedQuests, pilotTier (number, default 0), factionStanding ({rebel = n}).
-- questStatus: { ["<suffix>"] = value } stored as getQuestStatus("<objectID><suffix>"), the key
-- shape the Havoc/CorSec handlers use (player object id first).
function Fakes.newCreature(opts)
	opts = opts or {}

	local c = setmetatable({
		name = opts.name or "Tester",
		skills = set(opts.skills),
		faction = opts.faction or 0,
		pilot = opts.pilot,
		certifiedShip = opts.certifiedShip ~= false,
		screenPlayStates = opts.screenPlayStates or {},
		messages = {},
		music = {},
		isNpc = opts.isNpc or false,
		conversationSession = nil,
	}, FakeCreature)

	if not c.isNpc then
		c.ghost = opts.ghost or Fakes.newGhost(opts)
	end

	register(c)

	for suffix, value in pairs(opts.questStatus or {}) do
		Fakes.questStatus[c.objectID .. suffix] = tostring(value)
	end

	return c
end

function Fakes.newPlayer(opts) return Fakes.newCreature(opts) end

function Fakes.newNpc(opts)
	opts = opts or {}
	opts.isNpc = true
	return Fakes.newCreature(opts)
end

function FakeCreature:getObjectID() return self.objectID end
function FakeCreature:getFirstName() return self.name end
function FakeCreature:getDisplayedName() return self.name end
function FakeCreature:getPlayerObject() return self.ghost end
function FakeCreature:isPlayerCreature() return not self.isNpc end
function FakeCreature:hasSkill(skill) return self.skills[skill] == true end
function FakeCreature:getFaction() return self.faction end
function FakeCreature:getSpecies() return self.species or 0 end
function FakeCreature:isNeutralPilot() return self.pilot == "neutral" end
function FakeCreature:isRebelPilot() return self.pilot == "rebel" end
function FakeCreature:isImperialPilot() return self.pilot == "imperial" end
function FakeCreature:hasCertifiedShip(...) return self.certifiedShip end
function FakeCreature:playMusicMessage(file) self.music[#self.music + 1] = file end
function FakeCreature:getConversationSession() return self.conversationSession end
function FakeCreature:getScreenPlayState(screenplay) return self.screenPlayStates[screenplay] or 0 end

function FakeCreature:setScreenPlayState(state, screenplay)
	self.screenPlayStates[screenplay] = (self.screenPlayStates[screenplay] or 0) | state
end

function FakeCreature:removeScreenPlayState(state, screenplay)
	self.screenPlayStates[screenplay] = (self.screenPlayStates[screenplay] or 0) & ~state
end

-- Accepts a plain string or a fake StringIdChatParameter (from LuaStringIdChatParameter:_getObject()).
function FakeCreature:sendSystemMessage(msg)
	self.messages[#self.messages + 1] = msg
end

---------------------------------------------------------------------------------------------
-- Fake conversation template / screens, built from the real ConvoTemplate/ConvoScreen tables
-- that mobile/conversations/*.lua create (ConvoScreen fields: id, leftDialog, customDialogText,
-- stopConversation, options = {{text, link}, ...}).
---------------------------------------------------------------------------------------------

local FakeScreen = { __kind = "ConversationScreen" }
FakeScreen.__index = FakeScreen

local function newScreen(src)
	local options = {}

	for _, o in ipairs(src.options or {}) do
		options[#options + 1] = { text = o[1], link = o[2] }
	end

	return setmetatable({
		id = src.id,
		dialogText = src.leftDialog or src.customDialogText,
		stopConversation = src.stopConversation == "true" or src.stopConversation == true,
		options = options,
		params = {},
	}, FakeScreen)
end

function FakeScreen:getScreenID() return self.id end
function FakeScreen:getOptionCount() return #self.options end
function FakeScreen:getOptionText(i) return self.options[i + 1] and self.options[i + 1].text end
function FakeScreen:getOptionLink(i) return self.options[i + 1] and self.options[i + 1].link end
function FakeScreen:addOption(text, link) self.options[#self.options + 1] = { text = text, link = link } end
function FakeScreen:removeAllOptions() self.options = {} end
function FakeScreen:setDialogTextStringId(s) self.dialogText = s end
function FakeScreen:setCustomDialogText(s) self.dialogText = s end
function FakeScreen:setStopConversation(b) self.stopConversation = b end
function FakeScreen:setAnimationName(a) self.animation = a end
for _, p in ipairs({ "TT", "TO", "TU", "DF", "DI" }) do
	FakeScreen["setDialogText" .. p] = function(self, v) self.params[p] = v end
end

function FakeScreen:cloneScreen()
	local copy = setmetatable({}, FakeScreen)

	for k, v in pairs(self) do
		copy[k] = v
	end

	copy.options = {}

	for i, o in ipairs(self.options) do
		copy.options[i] = { text = o.text, link = o.link }
	end

	copy.params = {}

	for k, v in pairs(self.params) do
		copy.params[k] = v
	end

	return copy
end

local FakeTemplate = { __kind = "ConversationTemplate" }
FakeTemplate.__index = FakeTemplate

-- Wraps a real ConvoTemplate table so it can be passed as pConvTemplate.
function Fakes.newConversationTemplate(convoTemplate, name)
	-- ConvoTemplate.screens is a list; the C++ ConversationTemplate indexes screens by id.
	local screens = {}

	for _, s in ipairs(convoTemplate.screens or {}) do
		screens[s.id] = newScreen(s)
	end

	return setmetatable({ name = name, source = convoTemplate, screens = screens, initialScreen = convoTemplate.initialScreen }, FakeTemplate)
end

function FakeTemplate:getScreen(id) return self.screens[id] end
function FakeTemplate:getInitialScreen() return self.screens[self.initialScreen] end

local FakeSession = { __kind = "ConversationSession" }
FakeSession.__index = FakeSession

function Fakes.newConversationSession(npc)
	return setmetatable({ npc = npc, lastScreen = nil }, FakeSession)
end

function FakeSession:getLastConversationScreen() return self.lastScreen end

---------------------------------------------------------------------------------------------
-- Fake StringIdChatParameter and SkillManager
---------------------------------------------------------------------------------------------

local FakeStringId = { __kind = "StringIdChatParameter" }
FakeStringId.__index = FakeStringId

for _, p in ipairs({ "TT", "TO", "TU", "DF", "DI" }) do
	FakeStringId["set" .. p] = function(self, v) self.params[p] = v end
end

function FakeStringId:_getObject() return self end

local FakeSkillManager = { __kind = "SkillManager" }
FakeSkillManager.__index = FakeSkillManager

-- The XP-deducting path (SpaceHelpers:grantSpaceSkill(..., true)). Recorded separately from the
-- free path: H.Engine.callsTo("skillManagerAwardSkill") vs H.Engine.callsTo("awardSkill").
function FakeSkillManager:awardSkill(pPlayer, skill)
	skillManagerAwardSkill(pPlayer, skill)
end

---------------------------------------------------------------------------------------------
-- Wrapper types
---------------------------------------------------------------------------------------------

local function wrapperType(typeName)
	local mt = {}

	mt.__index = function(self, key)
		if key == "_setObject" then
			return function(w, p) rawset(w, "_target", p) end
		elseif key == "_getObject" then
			return function(w) return rawget(w, "_target") end
		end

		local target = rawget(self, "_target")

		if target == nil then
			error(string.format("harness: %s:%s called on a nil object", typeName, key), 2)
		end

		local fn = target[key]

		if type(fn) ~= "function" then
			error(string.format("harness: fake %s (wrapping %s) has no method '%s'; add it in tests/lua/harness/fakes.lua",
				typeName, tostring(target.__kind), key), 2)
		end

		return function(_, ...) return fn(target, ...) end
	end

	return function(p)
		return setmetatable({ _target = p }, mt)
	end
end

local WRAPPED_TYPES = {
	"LuaSceneObject", "LuaCreatureObject", "LuaPlayerObject", "LuaTangibleObject", "LuaAiAgent",
	"LuaBuildingObject", "LuaCityRegion", "LuaActiveArea", "LuaMissionObject", "LuaWaypointObject",
	"LuaShipObject", "LuaShipAiAgent", "LuaPobShipObject", "LuaShipComponent", "LuaIntangibleObject",
	"LuaControlDevice", "LuaConversationTemplate", "LuaConversationScreen", "LuaConversationSession",
	"LuaSuiBox", "LuaSuiListBox",
}

function Fakes.installWrappers(env)
	for _, name in ipairs(WRAPPED_TYPES) do
		env[name] = wrapperType(name)
	end

	env.LuaStringIdChatParameter = function(stringId)
		return setmetatable({ stringId = stringId, params = {} }, FakeStringId)
	end

	env.LuaSkillManager = function()
		return setmetatable({}, FakeSkillManager)
	end
end

return Fakes
