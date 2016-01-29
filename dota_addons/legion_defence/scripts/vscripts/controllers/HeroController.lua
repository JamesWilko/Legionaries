
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

	ListenToGameEvent("dota_player_pick_hero", Dynamic_Wrap(CHeroController, "OnPlayerPickedHero"), self)
	ListenToGameEvent("legion_wave_start", Dynamic_Wrap(CHeroController, "HandleOnWaveStart"), self)
	ListenToGameEvent("legion_wave_complete", Dynamic_Wrap(CHeroController, "HandleOnWaveComplete"), self)

end


function CHeroController:OnPlayerPickedHero( event )
	local player = PlayerResource:GetPlayer( event.player )
	if player then
		local hero = player:GetAssignedHero()
		if hero then
			hero:AddNewModifier( hero, nil, "modifier_invulnerable", nil )
		end
	end
end

function CHeroController:HandleOnWaveStart( event )

end

function CHeroController:HandleOnWaveComplete( event )

end
