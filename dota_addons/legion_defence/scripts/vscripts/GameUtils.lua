
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

function PlayCurrencyLostParticles( sCurrency, lPrice, eUnit )

	local data = CurrencyParticles[sCurrency] and CurrencyParticles[sCurrency].lost
	if data then

		eUnit:EmitSound( lPrice < data.amountLarge and data.sound or data.soundLarge )

		local particle = ParticleManager:CreateParticle(data.particle, PATTACH_POINT_FOLLOW, eUnit)
		ParticleManager:SetParticleControl( particle, 1, eUnit:GetCenter() )
		ParticleManager:SetParticleControl( particle, 2, Vector(data.numParticles(lPrice), 0, 0) )
		ParticleManager:SetParticleControl( particle, 3, Vector(0.2, 0.2, 0.2) )

		ParticleManager:SetParticleControlEnt( particle, 4, eUnit, PATTACH_POINT_FOLLOW, "attach_hitloc", eUnit:GetCenter(), true )

		ParticleManager:ReleaseParticleIndex( particle )

	end

end

function PlayCurrencyGainedParticles( sCurrency, lPrice, eUnit )

	local data = CurrencyParticles[sCurrency] and CurrencyParticles[sCurrency].gained
	if data then

		eUnit:EmitSound( lPrice < data.amountLarge and data.sound or data.soundLarge )

		local particle = ParticleManager:CreateParticle(data.particle, PATTACH_POINT_FOLLOW, eUnit)
		ParticleManager:SetParticleControl( particle, 1, eUnit:GetCenter() )
		ParticleManager:SetParticleControl( particle, 2, Vector(data.numParticles(lPrice), 0, 0) )
		ParticleManager:SetParticleControl( particle, 3, Vector(0.2, 0.2, 0.2) )
		ParticleManager:SetParticleControl( particle, 4, eUnit:GetCenter() + Vector(0, 0, 100) )

		ParticleManager:SetParticleControlEnt( particle, 4, eUnit, PATTACH_POINT_FOLLOW, "attach_hitloc", eUnit:GetCenter(), true )

		ParticleManager:ReleaseParticleIndex( particle )

	end

end
