-- Color Kit (/object colorkit): reusable, recolor your items within the in-game palette limits.
-- See ColorCustomizerMenuComponent / ColorCustomizerSuiCallback.h.
object_tangible_item_color_kit = object_tangible_loot_collectible_collectible_parts_shared_blue_rug_dye:new {
	customName = "Color Kit",
	objectMenuComponent = "ColorCustomizerMenuComponent",
}

ObjectTemplates:addTemplate(object_tangible_item_color_kit, "object/tangible/item/color_kit.iff")
