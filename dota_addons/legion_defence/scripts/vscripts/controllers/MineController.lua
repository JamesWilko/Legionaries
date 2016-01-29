
if CMineController == nil then
	CMineController = class({})
end

function CLegionDefence:SetupMineController()
	self.mine_controller = CMineController()
	self.mine_controller:Setup()
end

function CLegionDefence:GetMineController()
	return self.mine_controller
end

---------------------------------------
-- Mine Controller
---------------------------------------
CMineController.CURRENCY = CURRENCY_GEMS
CMineController.DEFAULT = {
	miners = 1,
	income_per_miner = 20,
}

CMineController.UPGRADE_MINERS = 1
CMineController.UPGRADE_MINING_SPEED = 5

CMineController.MAXIMUM_MINERS = 10
CMineController.MAXIMUM_MINING_SPEED = 200

function CMineController:Setup()

	self.mines = {}
	self.miners = {}

	-- Game events
	ListenToGameEvent("legion_player_assigned_lane", Dynamic_Wrap(CMineController, "OnPlayerAssignedLane"), self)

end

function CMineController:OnPlayerAssignedLane( data )

	local playerId = data["lPlayer"]
	
	-- Give player default mines
	self.mines[playerId] = table.copy( CMineController.DEFAULT )
	self:UpdatePlayerIncome( playerId )

	-- Spawn miner units
	self.miners[playerId] = {}
	self:SpawnMiners( playerId, laneId )

end

function CMineController:OnPurchasedMinerUpgrade( iPlayerId, iUpgradeLevel, iLevelsAdded )
	self.mines[iPlayerId].miners = CMineController.DEFAULT.miners + ((iUpgradeLevel - 1) * CMineController.UPGRADE_MINERS)
	self:UpdatePlayerIncome( iPlayerId )
	self:SpawnMiners( iPlayerId )
end

function CMineController:OnPurchasedMiningSpeedUpgrade( iPlayerId, iUpgradeLevel, iLevelsAdded )

	self.mines[iPlayerId].income_per_miner = CMineController.DEFAULT.income_per_miner + ((iUpgradeLevel - 1) * CMineController.UPGRADE_MINING_SPEED)
	self:UpdatePlayerIncome( iPlayerId )
	self:SpawnMiners( iPlayerId )

	-- Show upgrade particles on all miners
	if self.miners[iPlayerId] then
		for k, v in pairs(self.miners[iPlayerId]) do

			local particle = "particles/econ/items/puck/puck_alliance_set/puck_illusory_orb_launch_aproset.vpcf"
			local upgrade_particle = ParticleManager:CreateParticle( particle, PATTACH_POINT, v.unit )
			ParticleManager:SetParticleControl( upgrade_particle, 3, v.unit:GetCenter() )
			ParticleManager:ReleaseParticleIndex( upgrade_particle )

		end
	end

end

function CMineController:UpdatePlayerIncome( iPlayerId )

	-- Calculate income
	local income = self.mines[iPlayerId].income_per_miner
	income = income * self.mines[iPlayerId].miners

	-- Set income
	local currencyController = GameRules.LegionDefence:GetCurrencyController()
	currencyController:SetCurrencyIncome( CMineController.CURRENCY, iPlayerId, income )

	-- Update particles
	if self.miners[iPlayerId] then

		local particles_amount = Vector( self:GetCrystalParticleSpawnRate( iPlayerId ), 0, 0 )
		for k, v in pairs(self.miners[iPlayerId]) do
			if v.particles then
				ParticleManager:SetParticleControl( v.particles, 5, particles_amount )
			end
		end

	end

end

function CMineController:SpawnMiners( iPlayerId, laneId, teamId )

	-- Find player lane and team
	local hPlayer = PlayerResource:GetPlayer( iPlayerId )
	if laneId == nil then
		laneId = GameRules.LegionDefence:GetLaneController():GetLaneForPlayer( iPlayerId )
	end
	if teamId == nil then
		teamId = PlayerResource:GetPlayer( iPlayerId ):GetTeam()
	end

	-- Spawn units
	local numMiners = #self.miners[iPlayerId] + 1
	local mapController = GameRules.LegionDefence:GetMapController()
	for i = numMiners, self.mines[iPlayerId].miners do

		local spawns = mapController:GetMinerSpawnPointsForLane( laneId )
		local spawn_point = spawns[i].entity
		local target_point = mapController:GetMinerTargetPointForLane( laneId ).entity

		if spawn_point then

			local hUnit = CreateUnitByName( "npc_legion_miner", spawn_point:GetOrigin(), false, nil, hPlayer, teamId )
			if hUnit ~= nil then

				hUnit:SetOwner( hPlayer )
				hUnit:SetControllableByPlayer( iPlayerId, true )
				hUnit:SetMoveCapability( DOTA_UNIT_CAP_MOVE_NONE )
				hUnit:SetAttackCapability( DOTA_UNIT_CAP_NO_ATTACK )
				hUnit:StartGesture( ACT_DOTA_TELEPORT )
				hUnit:AddNewModifier( v, nil, "modifier_invulnerable", nil )

				local angles = spawn_point:GetAngles()
				hUnit:SetAngles( angles.x, angles.y, angles.z )

			end

			-- Create summon particle
			local summon_particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_chen/chen_teleport_flash.vpcf", PATTACH_POINT, hUnit )
			ParticleManager:SetParticleControl( summon_particle, 0, hUnit:GetOrigin() )
			ParticleManager:ReleaseParticleIndex( summon_particle )

			-- Create mining particle
			local crystal_scale = 0.02
			local particle_name = "particles/crystal/crystal_link_beam_blade.vpcf"
			local mining_particle = ParticleManager:CreateParticle(particle_name, PATTACH_POINT_FOLLOW, hUnit)
			ParticleManager:SetParticleControlEnt( mining_particle, 0, hUnit, PATTACH_POINT_FOLLOW, "attach_attack1", hUnit:GetCenter(), true )
			ParticleManager:SetParticleControl( mining_particle, 1, target_point:GetOrigin() )
			ParticleManager:SetParticleControl( mining_particle, 3, Vector(crystal_scale, crystal_scale, crystal_scale) )
			ParticleManager:SetParticleControl( mining_particle, 4, hUnit:GetCenter() )
			ParticleManager:SetParticleControl( mining_particle, 5, Vector( self:GetCrystalParticleSpawnRate( iPlayerId ), 0, 0 ) )

			local data = {
				unit = hUnit,
				particle = mining_particle,
				point = spawn_point
			}
			table.insert(self.miners[iPlayerId], data)

		end

	end

end

function CMineController:GetCrystalParticleSpawnRate( iPlayerId )
	local rate = self.mines[iPlayerId].income_per_miner / 60
	return math.ceil(rate)
end
