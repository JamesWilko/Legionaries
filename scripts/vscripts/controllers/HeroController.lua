
if CHeroController == nil then
	CHeroController = class({})
end

function CLegionDefence:SetupHeroController()
	self.hero_controller = CHeroController()
	self.hero_controller:Setup()
end

function CLegionDefence:GetHeroController()
	return self.hero_controller
end

function CHeroController:Setup()

	ListenToGameEvent("legion_wave_start", Dynamic_Wrap(CHeroController, "HandleOnWaveStart"), self)
	ListenToGameEvent("legion_wave_complete", Dynamic_Wrap(CHeroController, "HandleOnWaveComplete"), self)

end

function CHeroController:HandleOnWaveStart( event )
	for k, v in pairs( HeroList:GetAllHeroes() ) do
		v:AddNewModifier( v, nil, "modifier_invulnerable", nil )
	end
end

function CHeroController:HandleOnWaveComplete( event )
	for k, v in pairs( HeroList:GetAllHeroes() ) do
		v:RemoveModifierByName("modifier_invulnerable")
	end
end
