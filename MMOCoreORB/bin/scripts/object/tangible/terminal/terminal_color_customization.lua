-- Color Terminal (/object colorterminal): recolor your items within the in-game palette limits.
-- See ColorCustomizerMenuComponent / ColorCustomizerSuiCallback.h.
object_tangible_terminal_terminal_color_customization = object_tangible_terminal_shared_terminal_skill:new {
	customName = "Color Terminal",
	objectMenuComponent = "ColorCustomizerMenuComponent",
}

ObjectTemplates:addTemplate(object_tangible_terminal_terminal_color_customization, "object/tangible/terminal/terminal_color_customization.iff")
