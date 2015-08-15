
-- Play gold particles and sounds based on price
function PlayGoldParticlesForCost( lPrice, eUnit )

	-- Play coin sounds
	eUnit:EmitSound( lPrice < 200 and "General.Coins" or "General.CoinsBig" )

	local nCoins = ParticleManager:CreateParticle("particles/generic_gameplay/lasthit_coins.vpcf", PATTACH_POINT, eUnit)
	ParticleManager:SetParticleControl( nCoins, 1, eUnit:GetCenter() )
	ParticleManager:ReleaseParticleIndex( nCoins )

	if lPrice > 200 then
		local big_particles = math.floor(lPrice / 200)
		for i = 0, big_particles - 1 do
			local nCoins = ParticleManager:CreateParticle("particles/units/heroes/hero_alchemist/alchemist_lasthit_coins.vpcf", PATTACH_POINT, eUnit)
			ParticleManager:SetParticleControl( nCoins, 1, eUnit:GetCenter() )
			ParticleManager:ReleaseParticleIndex( nCoins )
		end
	end

end
