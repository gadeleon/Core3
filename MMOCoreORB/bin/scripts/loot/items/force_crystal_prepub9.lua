-- Pre-Pub9 Crystal: one of the 12 blade colors plus stats, for pre-Pub9 lightsabers
force_crystal_prepub9 = {
	minimumLevel = 0,
	maximumLevel = -1,
	customObjectName = "Ancient Crystal",
	directObjectTemplate = "object/tangible/component/weapon/lightsaber/lightsaber_module_force_crystal_prepub9.iff",
	craftingValues = {
		{"color",0,11,0},
	},
	customizationStringNames = {},
	customizationValues = {}
}

addLootItemTemplate("force_crystal_prepub9", force_crystal_prepub9)
