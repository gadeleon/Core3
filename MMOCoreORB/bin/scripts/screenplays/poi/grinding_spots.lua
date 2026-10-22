-- Grinding spots: dense static spawns on adventure planets, every creature paying the 7500 per kill combat xp cap
-- (baseXp >= 7500, about 12-13k HAM, no faction). Each spot is a ring of clusters around its center;
-- move a spot by changing its x and y, the height comes from the terrain.
GrindingSpotsScreenPlay = ScreenPlay:new {
	numberOfActs = 1,

	screenplayName = "GrindingSpotsScreenPlay",

	respawnTime = 30,
	clusters = 10,
	ringRadius = 100,
	clusterRadius = 8,

	spots = {
		{ -- Rancor pit, in the hard rancor forest
			planet = "dathomir", x = -3600, y = 3800,
			mobiles = { "enraged_rancor", "enraged_rancor", "enraged_rancor", "monstrous_brute", "monstrous_brute", "enraged_bull_rancor" }
		},
		{ -- Vesp canyon, in the vesp hills
			planet = "lok", x = 4100, y = 3500,
			mobiles = { "deadly_vesp", "deadly_vesp", "deadly_vesp", "deadly_vesp", "deadly_vesp", "deadly_vesp" }
		},
		{ -- Wayward Jungle, in the northwestern angler grounds
			planet = "yavin4", x = -4300, y = 5400,
			mobiles = { "stintaril_prowler", "stintaril_prowler", "stintaril_prowler", "mad_angler", "mad_angler", "mad_angler" }
		},
	},
}

registerScreenPlay("GrindingSpotsScreenPlay", true)

function GrindingSpotsScreenPlay:start()
	for i = 1, #self.spots, 1 do
		local spot = self.spots[i]

		if (isZoneEnabled(spot.planet)) then
			self:spawnMobiles(spot)
		end
	end
end

function GrindingSpotsScreenPlay:spawnMobiles(spot)
	for c = 0, self.clusters - 1, 1 do
		local angle = c * 2 * math.pi / self.clusters
		local clusterX = spot.x + self.ringRadius * math.cos(angle)
		local clusterY = spot.y + self.ringRadius * math.sin(angle)

		for m = 1, #spot.mobiles, 1 do
			local mobAngle = m * 2 * math.pi / #spot.mobiles
			local x = clusterX + self.clusterRadius * math.cos(mobAngle)
			local y = clusterY + self.clusterRadius * math.sin(mobAngle)

			spawnMobile(spot.planet, spot.mobiles[m], self.respawnTime, x, getWorldFloor(x, y, spot.planet), y, math.random(360) - 180, 0)
		end
	end
end
