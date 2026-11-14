--[[
	Admin completion of a space quest: /object spacequest complete <questType> <questName> (ObjectCommand.h), on the
	targeted player or on the admin. The quest's own screenplay (global <questType>_<questName>) completes it, so its
	observers and saved progress are cleaned up and the trainer pays the reward as after a normal completion.
	A quest with no screenplay is completed in the journal only.
]]

local SpaceHelpers = require("utils.space_helpers")

SpaceQuestAdmin = {}

function SpaceQuestAdmin:complete(pAdmin, pTarget, questType, questName)
	if (pAdmin == nil) then
		return
	end

	if (pTarget == nil or not SceneObject(pTarget):isPlayerCreature()) then
		pTarget = pAdmin
	end

	local who = CreatureObject(pTarget):getFirstName()
	local label = questType .. "/" .. questName
	local msg

	if (not SpaceHelpers:isSpaceQuestActive(pTarget, questType, questName)) then
		msg = who .. " does not have the space quest " .. label .. " active."
	else
		local quest = _G[questType .. "_" .. questName]

		if (type(quest) == "table" and quest.questType == questType and quest.questName == questName and quest.completeQuest ~= nil) then
			quest:completeQuest(pTarget, "true")
		else
			SpaceHelpers:completeSpaceQuest(pTarget, questType, questName, true)
		end

		if (SpaceHelpers:isSpaceQuestComplete(pTarget, questType, questName)) then
			msg = "Completed space quest " .. label .. " for " .. who .. "."
		else
			msg = "Space quest " .. label .. " for " .. who .. " did not complete."
		end
	end

	CreatureObject(pAdmin):sendSystemMessage(msg)
end
