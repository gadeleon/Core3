--This setting determines if apprenticeship points are awarded for a player teaching another player a skill.
apprenticeshipEnabled = 1
-- Skill point costs. /server playermanager skillpoints changes these live until the next restart.
-- Free skill points are recalculated from these whenever a character logs in or learns/drops a skill.
skillPointPool = 250 -- total skill points per character
skillPointCostMultiplier = 1.0 -- every skill's cost is scaled by this (rounded), 0 makes skills free
skillPointCostOverrides = { -- { "skill_name", points }, takes priority over the multiplier
	-- { "combat_carbine_master", 0 },
}
