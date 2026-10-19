-- Holocomm (/object holocomm): reusable, no-trade. Dials a profession trainer, whose hologram teaches skills
-- at the normal cost. See screenplays/tools/holocomm_menu_component.lua.
object_tangible_item_holocomm = object_tangible_loot_tool_shared_comlink_naboo_broken:new {
	customName = "Holocomm",
	objectMenuComponent = "HolocommMenuComponent",
	noTrade = 1
}

ObjectTemplates:addTemplate(object_tangible_item_holocomm, "object/tangible/item/holocomm.iff")
