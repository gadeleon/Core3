-- Hologrind Tracker (/object hologrindtracker): reusable, no-trade. Shows hologrind progress following
-- the holocron rules. See screenplays/jedi/hologrind_tracker_menu_component.lua.
object_tangible_jedi_hologrind_tracker = object_tangible_jedi_shared_jedi_holocron_dark:new {
	customName = "Hologrind Tracker",
	objectMenuComponent = "HologrindTrackerMenuComponent",
	noTrade = 1
}

ObjectTemplates:addTemplate(object_tangible_jedi_hologrind_tracker, "object/tangible/jedi/hologrind_tracker.iff")
