--[[
	Battlefield entry stations: SWG's three gates to Kessel (space_light1) and Deep Space (space_heavy1)
		Dathomir neutral station (4000, 200, -4700)  -> battlefield_entry_station_neutral
		Dantooine Rebel station (-4200, -3000, -6000) -> battlefield_entry_station_rebel
		Endor Imperial station (6200, 5000, 6000)     -> battlefield_entry_station_imperial

	SWG-Source lost the conversation scripts and datatables/space_content/battlefields/entry_stations.iff
	(arrival points and Prestige cost); only the client strings survive. Reconstructed per user decisions
	(2026-11-12): entry is free (the Prestige screens are not used), arrivals are near each side's capital
	ship in Deep Space (Freedom station -6000,0,0 / Star Destroyer 6000,0,0) and at the center of Kessel,
	randomized +-200 m on each axis as SWG's doBattleFieldCommandTransition.

	The trip is an immediate warp once the station says "Good luck" (LuaShipObject::warpToLocation), not a
	hyperspace route. Pre-CU behaviour per the user (2026-11-12): SWG-Source's combat_ship_player zoneToCommand
	(NGE) runs a 20 s "Hyperspace calculations" countdown first; that is not used. The ship's position beside the
	station is stored first (LuaShipObject::setBattlefieldReturnPoint): a ship destroyed in Kessel or Deep Space
	returns there (DestroyShipTask), as SWG's battlefield.locRespawnLocation. SWG's spaceFaction.FactionOverride on
	Deep Space entry is not ported (space battlefields are out of scope).
]]

BattlefieldEntry = ScreenPlay:new {
	screenplayName = "BattlefieldEntry",

	ARRIVAL_SPREAD = 200,
	TRAVEL_DELAY = 2000, -- ms after the "good luck" line, so the conversation window closes first

	-- {zone, x, z, y}
	destinations = {
		kessel = {"space_light1", 0, 0, 0},
		deep_space_rebel = {"space_heavy1", -5000, 0, 0},
		deep_space_imperial = {"space_heavy1", 5000, 0, 0},
	},
}

-- A ship that cannot make the jump: starter (basic) chassis and yachts
function BattlefieldEntry:isInCivilianShip(pPlayer)
	local pShip = SceneObject(pPlayer):getRootParent()

	if (pShip == nil or not SceneObject(pShip):isShipObject()) then
		return true
	end

	local chassis = string.lower(SceneObject(pShip):getObjectName() or "")

	return string.find(chassis, "basic", 1, true) ~= nil or string.find(chassis, "yacht", 1, true) ~= nil
end

-- SWG zoneToImperialDeepSpace: refused to Rebel pilots and Rebel faction
function BattlefieldEntry:canEnterAsImperial(pPlayer)
	return not (CreatureObject(pPlayer):isRebelPilot() or TangibleObject(pPlayer):isRebel())
end

-- SWG zoneToRebelDeepSpace: refused to Imperial pilots and Imperial faction
function BattlefieldEntry:canEnterAsRebel(pPlayer)
	return not (CreatureObject(pPlayer):isImperialPilot() or TangibleObject(pPlayer):isImperial())
end

function BattlefieldEntry:scheduleTravel(pPlayer, destination)
	createEvent(self.TRAVEL_DELAY, "BattlefieldEntry", "travel", pPlayer, destination)
end

function BattlefieldEntry:travel(pPlayer, destination)
	if (pPlayer == nil) then
		return
	end

	local dest = self.destinations[destination]

	if (dest == nil) then
		return
	end

	local pShip = SceneObject(pPlayer):getRootParent()

	if (pShip == nil or not SceneObject(pShip):isShipObject()) then
		return
	end

	local spread = self.ARRIVAL_SPREAD

	local x = dest[2] + getRandomNumber(-spread, spread)
	local z = dest[3] + getRandomNumber(-spread, spread)
	local y = dest[4] + getRandomNumber(-spread, spread)

	-- Where the ship returns if it is destroyed in Kessel or Deep Space (DestroyShipTask)
	ShipObject(pShip):setBattlefieldReturnPoint()

	ShipObject(pShip):warpToLocation(pPlayer, dest[1], x, z, y)
end
