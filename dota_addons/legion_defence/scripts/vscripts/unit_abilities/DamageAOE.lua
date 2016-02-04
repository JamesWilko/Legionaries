
-- We need to play our particles for our aoe on death ability here,
-- because Dota won't run the FireEffect and FireSound events for some reason

function DamageAOEPerformParticles( keys )

	local particle_name = "particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf"
	local sound_name = "Hero_Clinkz.Death"
	local caster = keys.caster

	local particle = ParticleManager:CreateParticle(particle_name, PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl( particle, 0, caster:GetOrigin() )
	ParticleManager:SetParticleControl( particle, 3, Vector(0, 0, 0) )

	EmitSoundOn( sound_name, caster )

end
