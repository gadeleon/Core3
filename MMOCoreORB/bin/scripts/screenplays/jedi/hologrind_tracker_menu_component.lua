-- Hologrind Tracker item: "Check Progress" shows the character's hologrind professions.
-- Follows the holocron rules: once only MAXIMUMNUMBEROFPROFESSIONSTOSHOWWITHHOLOCRON professions could be
-- revealed, the remaining unmastered ones stay hidden, with a hint at the category of each hidden one.
-- MAXIMUMNUMBEROFPROFESSIONSTOSHOWWITHHOLOCRON = 0 shows everything, like holocrons.
-- With PREPUB9JEDISLOT, holocrons only hint the first MAXIMUMNUMBEROFPROFESSIONSTOSHOWWITHHOLOCRON professions,
-- so those are always listed and the later ones stay hidden until mastered.

HologrindTrackerMenuComponent = { }

local professionNames = {
	crafting_architect_master = "Architect",
	crafting_armorsmith_master = "Armorsmith",
	crafting_artisan_master = "Artisan",
	outdoors_bio_engineer_master = "Bio-Engineer",
	combat_bountyhunter_master = "Bounty Hunter",
	combat_brawler_master = "Brawler",
	combat_carbine_master = "Carbineer",
	crafting_chef_master = "Chef",
	science_combatmedic_master = "Combat Medic",
	combat_commando_master = "Commando",
	outdoors_creaturehandler_master = "Creature Handler",
	social_dancer_master = "Dancer",
	science_doctor_master = "Doctor",
	crafting_droidengineer_master = "Droid Engineer",
	social_entertainer_master = "Entertainer",
	combat_1hsword_master = "Fencer",
	social_imagedesigner_master = "Image Designer",
	combat_marksman_master = "Marksman",
	science_medic_master = "Medic",
	crafting_merchant_master = "Merchant",
	social_musician_master = "Musician",
	combat_polearm_master = "Pikeman",
	combat_pistol_master = "Pistoleer",
	social_politician_master = "Politician",
	outdoors_ranger_master = "Ranger",
	combat_rifleman_master = "Rifleman",
	outdoors_scout_master = "Scout",
	crafting_shipwright = "Shipwright",
	combat_smuggler_master = "Smuggler",
	outdoors_squadleader_master = "Squad Leader",
	combat_2hsword_master = "Swordsman",
	crafting_tailor_master = "Tailor",
	crafting_weaponsmith_master = "Weaponsmith",
	combat_unarmed_master = "Teras Kasi Artist",
}

local categoryHints = {
	combat = "The last path lies in combat.",
	crafting = "The last path lies in crafting.",
	outdoors = "The last path lies in the wilderness.",
	science = "The last path lies in the healing sciences.",
	social = "The last path lies in the social arts.",
	pilot = "The last path lies among the stars.",
}

function HologrindTrackerMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local response = LuaObjectMenuResponse(pMenuResponse)
	response:addRadialMenuItem(20, 3, "Check Progress")
end

function HologrindTrackerMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pPlayer == nil or pSceneObject == nil or selectedID ~= 20) then
		return 0
	end

	if (not SceneObject(pSceneObject):isASubChildOf(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("The tracker must be in your inventory to use it.")
		return 0
	end

	self:showProgress(pSceneObject, pPlayer)

	return 0
end

function HologrindTrackerMenuComponent:showProgress(pSceneObject, pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	if (jediProgressionType ~= HOLOGRINDJEDIPROGRESSION) then
		CreatureObject(pPlayer):sendSystemMessage("The tracker is silent. Hologrind Jedi progression is not active on this galaxy.")
		return
	end

	local professions = PlayerObject(pGhost):getHologrindProfessions()
	local total = #professions
	local mastered = 0

	for i = 1, total, 1 do
		if PlayerObject(pGhost):hasBadge(professions[i]) then
			mastered = mastered + 1
		end
	end

	-- Same limit as holocrons: at most this many professions can ever be revealed.
	local maxShown = MAXIMUMNUMBEROFPROFESSIONSTOSHOWWITHHOLOCRON

	if (maxShown == nil or maxShown <= 0 or maxShown > total) then
		maxShown = total
	end

	local hiddenCount = total - maxShown

	local hidden = {}
	local needed = total

	if PREPUB9JEDISLOT then
		-- Holocrons only hint the first professions in the list; the later ones stay hidden until mastered.
		needed = math.min(NUMBEROFPROFESSIONSTOMASTER, total)

		for i = maxShown + 1, total, 1 do
			if not PlayerObject(pGhost):hasBadge(professions[i]) then
				hidden[i] = true
			end
		end
	else
		-- The last unmastered professions in the list are the hidden ones, so the same ones stay hidden every time.
		local remaining = hiddenCount

		for i = total, 1, -1 do
			if (remaining <= 0) then
				break
			end

			if not PlayerObject(pGhost):hasBadge(professions[i]) then
				hidden[i] = true
				remaining = remaining - 1
			end
		end
	end

	local text = "Hologrind professions mastered: " .. mastered .. " of " .. needed .. "\n\n"

	for i = 1, total, 1 do
		local skill = HologrindJediManager:getProfessionStringIdFromBadgeNumber(professions[i])

		if hidden[i] then
			local category = string.match(skill, "^([^_]+)_") or ""
			local hint = categoryHints[category] or "The last path is hidden from you."

			text = text .. "[ ? ] Hidden - " .. hint .. "\n"
		else
			local name = professionNames[skill] or skill
			local status = PlayerObject(pGhost):hasBadge(professions[i]) and "[ X ] " or "[    ] "

			text = text .. status .. name .. "\n"
		end
	end

	if PREPUB9JEDISLOT then
		local key = HologrindJediManager:getJediSlotKey(pPlayer)

		if (key ~= nil and getQuestStatus(key) ~= nil) then
			text = text .. "\nYou are attuned with the power of the Force. Your Force Sensitive character slot has been unlocked."
		end
	elseif (PlayerObject(pGhost):isJedi()) then
		text = text .. "\nThe Force is with you. Your path to the Jedi has been revealed."
	elseif (mastered >= total) then
		text = text .. "\nAll paths are mastered. Perhaps you should meditate somewhere alone..."
	end

	local suiManager = LuaSuiManager()
	suiManager:sendMessageBox(pSceneObject, pPlayer, "Hologrind Tracker", text, "@ok", "HologrindTrackerMenuComponent", "noCallback")
end

function HologrindTrackerMenuComponent:noCallback(pPlayer, pSui, eventIndex, ...)
end
