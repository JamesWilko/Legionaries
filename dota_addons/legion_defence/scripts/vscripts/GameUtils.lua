
local CurrencyParticles = {
	[CURRENCY_GOLD] = {
		lost = {
			particle = "particles/currencies/spent_coins.vpcf",
			sound = "General.Coins",
			soundLarge = "General.CoinsBig",
			amountLarge = 200,
			numParticles = function(lPrice) return math.ceil(lPrice / 4) end,
		},
		gained = {
			particle = "particles/currencies/returned_coins.vpcf",
			sound = "General.Coins",
			soundLarge = "General.CoinsBig",
			amountLarge = 200,
			numParticles = function(lPrice) return math.ceil(lPrice / 4) end,
		}
	},
	[CURRENCY_GEMS] = {
		lost = {
			particle = "particles/currencies/spent_gems.vpcf",
			sound = "General.Coins",
			soundLarge = "General.CoinsBig",
			amountLarge = 250,
			numParticles = function(lPrice) return math.ceil(lPrice / 2) end,
		},
		gained = {
			particle = "particles/currencies/returned_gems.vpcf",
			sound = "General.Coins",
			soundLarge = "General.CoinsBig",
			amountLarge = 250,
			numParticles = function(lPrice) return math.ceil(lPrice / 2) end,
		}
	}
}

function PlayCurrencyLostParticles( sCurrency, lPrice, eUnit, bSupressSound )

	local data = CurrencyParticles[sCurrency] and CurrencyParticles[sCurrency].lost
	if data then

		if not bSupressSound then
			eUnit:EmitSound( lPrice < data.amountLarge and data.sound or data.soundLarge )
		end

		local particle = ParticleManager:CreateParticle(data.particle, PATTACH_POINT_FOLLOW, eUnit)
		ParticleManager:SetParticleControl( particle, 1, eUnit:GetCenter() )
		ParticleManager:SetParticleControl( particle, 2, Vector(data.numParticles(lPrice), 0, 0) )
		ParticleManager:SetParticleControl( particle, 3, Vector(0.2, 0.2, 0.2) )
		ParticleManager:SetParticleControlEnt( particle, 4, eUnit, PATTACH_POINT_FOLLOW, "attach_hitloc", eUnit:GetCenter(), true )

		ParticleManager:ReleaseParticleIndex( particle )

	end

end

function PlayCurrencyGainedParticles( sCurrency, lPrice, eUnit, vSpawnPosition, bSupressSound )

	local data = CurrencyParticles[sCurrency] and CurrencyParticles[sCurrency].gained
	if data then

		vSpawnPosition = vSpawnPosition or (eUnit:GetCenter() + Vector(0, 0, 200))

		if not bSupressSound then
			eUnit:EmitSound( lPrice < data.amountLarge and data.sound or data.soundLarge )
		end

		local particle = ParticleManager:CreateParticle(data.particle, PATTACH_POINT_FOLLOW, eUnit)
		ParticleManager:SetParticleControl( particle, 1, vSpawnPosition )
		ParticleManager:SetParticleControl( particle, 2, Vector(data.numParticles(lPrice), 0, 0) )
		ParticleManager:SetParticleControl( particle, 3, Vector(0.2, 0.2, 0.2) )

		ParticleManager:SetParticleControlEnt( particle, 4, eUnit, PATTACH_POINT_FOLLOW, "attach_hitloc", eUnit:GetCenter(), true )

		ParticleManager:ReleaseParticleIndex( particle )

	end

end

-- Returns the abilities that are unique to a unit
-- ie. No upgrade or sell ability
function GetUnitUniqueAbilities( hUnit )

	-- 4 abilities as 2 may always be upgrade or sell, units should have a max of 6 including upgrade and sell
	local MAX_ABILITIES = 4
	local ABILITY_SELL = "sell_unit"
	local ABILITY_UPGRADE = "upgrade_unit"

	local abilities = {}

	-- Note: for-loop doesn't work here for some reason, use a while loop to get around it
	local i = 0
	while i < MAX_ABILITIES do

		local ability = hUnit:GetAbilityByIndex(i)
		if ability then

			-- Check ability isn't a sell ability
			local sell_index = string.find(ability:GetName(), ABILITY_SELL)
			if sell_index == nil then

				-- Check ability isn't an upgrade ability
				local upgrade_index = string.find(ability:GetName(), ABILITY_UPGRADE)
				if upgrade_index == nil then

					-- Add ability
					table.insert( abilities, ability )

				end

			end

		end

		i = i + 1

	end

	return abilities

end

function ShowGoldPopup( target, amount, lifetime, color )

	local particle_path = "particles/msg_fx/msg_gold.vpcf"
	local particle = ParticleManager:CreateParticle(particle_path, PATTACH_ABSORIGIN_FOLLOW, target)
	local digits = number ~= nil and #tostring(number) or 0

	ParticleManager:SetParticleControl(particle, 1, Vector(0, tonumber(number), 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(lifetime or 1, digits, 0))
	ParticleManager:SetParticleControl(particle, 3, color or Vector(255, 200, 33))
	ParticleManager:ReleaseParticleIndex(particle)

end
